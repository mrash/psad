#!/usr/bin/perl -w
#
#########################################################################
#
# File: install.pl
#
# Purpose:  install.pl is the installation script for psad.  It is safe
#           to execute install.pl even if psad has already been installed
#           on a system since install.pl will preserve the existing
#           config section.
#
# Credits:  (see the CREDITS file)
#
# Copyright (C) 1999-2017 Michael Rash (mbr@cipherdyne.org)
#
# License (GNU Public License):
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
#    USA
#
# TODO:
#
#########################################################################
#

use Cwd;
use File::Path;
use File::Copy;
use Sys::Hostname;
use IO::Socket;
use Getopt::Long;
use strict;

#============== config ===============
my $USRSBIN_DIR  = '/usr/sbin';  ### consistent with FHS (Filesystem
                                 ### Hierarchy Standard)
my $USRBIN_DIR   = '/usr/bin';   ### consistent with FHS

my $psad_conf_file  = 'psad.conf';

### system binaries ###
my $chkconfigCmd = '/sbin/chkconfig';
my $rcupdateCmd  = '/sbin/rc-update';  ### Gentoo
my $updatercdCmd = '/usr/sbin/update-rc.d';  ### Ubuntu
my $makeCmd      = '/usr/bin/make';
my $perlCmd      = '/usr/bin/perl';
my $wgetCmd      = '/usr/bin/wget';
my $runlevelCmd  = '/sbin/runlevel';
my $systemctlCmd = '/bin/systemctl';

my $install_root = '/';

my $answers_file = 'install.answers';
#============ end config ============

my %file_vars = (
    'signatures'    => 'SIGS_FILE',
    'auto_dl'       => 'AUTO_DL_FILE',
    'icmp_types'    => 'ICMP_TYPES_FILE',
    'icmp6_types'   => 'ICMP6_TYPES_FILE',
    'posf'          => 'POSF_FILE',
    'pf.os'         => 'P0F_FILE',
    'snort_rule_dl' => 'SNORT_RULE_DL_FILE',
    'ip_options'    => 'IP_OPTS_FILE',
    'protocols'     => 'PROTOCOLS_FILE'
);

my %exclude_cmds = (
    'wget'         => '',
    'mail'         => '',
    'sendmail'     => '',
    'uname'        => '',
    'df'           => '',
    'psadwatchd'   => '',
    'kmsgsd'       => '',
    'psad'         => '',
    'whois'        => '',
    'fwcheck_psad' => ''
);

### map perl modules to versions
my %required_perl_modules = (
    'Unix::Syslog' => {
        'force-install' => 0,
        'mod-dir' => 'Unix-Syslog'
    },
    'Bit::Vector' => {
        'force-install' => 0,
        'mod-dir' => 'Bit-Vector'
    },
    'Storable', => {
        'force-install' => 0,
        'mod-dir' => 'Storable'
    },
    'Carp::Clan', => {
        'force-install' => 0,
        'mod-dir' => 'Carp-Clan'
    },
    'Date::Calc', => {
        'force-install' => 0,
        'mod-dir' => 'Date-Calc'
    },
    'NetAddr::IP' => {
        'force-install' => 0,
        'mod-dir' => 'NetAddr-IP'
    },
    'IPTables::Parse' => {
        'force-install' => 1,
        'mod-dir' => 'IPTables-Parse'
    },
    'IPTables::ChainMgr' => {
        'force-install' => 1,
        'mod-dir' => 'IPTables-ChainMgr'
    },
);

my @ordered_modules = (qw/
    Unix::Syslog
    Bit::Vector
    Storable
    Carp::Clan
    Date::Calc
    NetAddr::IP
    IPTables::Parse
    IPTables::ChainMgr
/);

my %config = ();
my %cmds   = ();

my @cmd_search_paths = qw(
    /bin
    /sbin
    /usr/bin
    /usr/sbin
    /usr/local/bin
    /usr/local/sbin
);

### IP regex
my $ip_re = qr|(?:[0-2]?\d{1,2}\.){3}[0-2]?\d{1,2}|;

### get the hostname of the system
my $HOSTNAME = hostname();

my $src_dir = getcwd() or die "[*] Could not get current working directory.";

### for user answers
my $ACCEPT_YES_DEFAULT = 1;
my $ACCEPT_NO_DEFAULT  = 2;
my $NO_ANS_DEFAULT     = 0;

### set the default execution flags and command line args
my $noarchive   = 0;
my $uninstall   = 0;
my $help        = 0;
my $archived_old = 0;
my $skip_syslog_test = 0;
my $use_answers = 0;
my $no_write_answers = 0;
my %answers = ();
my $skip_module_install   = 0;
my $cmdline_force_install = 0;
my $force_path_update = 0;
my $force_mod_re = '';
my $exclude_mod_re = '';
my $install_test_dir = 0;
my $no_rm_old_lib_dir = 0;
my $syslog_conf = '';
my $locale = 'C';  ### default LC_ALL env variable
my $no_locale = 0;
my $deps_dir = 'deps';
my $init_dir = '/etc/init.d';
my $systemd_init_dir = '/lib/systemd/system';
my $init_name = 'psad';
my $systemd_init_name = 'psad.service';
my $install_syslog_fifo = 0;
my $runlevel = -1;
my @installation_lines = ();

### make Getopts case sensitive
Getopt::Long::Configure('no_ignore_case');

&usage(1) unless (GetOptions(
    'config=s'          => \$psad_conf_file,  ### specify path to psad.conf
    'force-mod-install' => \$cmdline_force_install,  ### force install of all modules
    'Force-mod-regex=s' => \$force_mod_re,  ### force specific mod install with regex
    'Exclude-mod-regex=s' => \$exclude_mod_re, ### exclude a particular perl module
    'path-update'       => \$force_path_update, ### update command paths
    'Skip-mod-install'  => \$skip_module_install,
    'Use-answers'       => \$use_answers,
    'answers-file=s'    => \$answers_file,
    'no-write-answers'  => \$no_write_answers,
    'no-rm-lib-dir'     => \$no_rm_old_lib_dir, ### remove any old /usr/lib/psad dir
    'no-preserve'       => \$noarchive,   ### Don't preserve existing configs.
    'syslog-conf=s'     => \$syslog_conf, ### specify path to syslog config file.
    'no-syslog-test'    => \$skip_syslog_test,
    'uninstall'         => \$uninstall,   ### Uninstall psad.
    'init-dir=s'        => \$init_dir,
    'systemd-init-dir=s' => \$systemd_init_dir,
    'init-name=s'       => \$init_name,
    'install-syslog-fifo' => \$install_syslog_fifo,
    'install-root=s'    => \$install_root,
    'install-test-dir'  => \$install_test_dir,
    'runlevel=i'        => \$runlevel,
    'LC_ALL=s'          => \$locale,
    'no-LC_ALL'         => \$no_locale,
    'help'              => \$help         ### Display help.
));
&usage(0) if $help;

### set LC_ALL env variable
$ENV{'LC_ALL'} = $locale unless $no_locale;

### make a copy of the original psad.conf file and restore at the end
copy $psad_conf_file, "${psad_conf_file}.orig" or die "[*] Could not ",
    "copy $psad_conf_file -> $psad_conf_file.orig";

if ($install_test_dir) {
    $install_root = getcwd() . '/test/psad-install';
    $init_dir     = $install_root . '/etc/init.d';
}

&import_answers() if $use_answers;

### import paths from default psad.conf
&import_config();

$force_mod_re   = qr|$force_mod_re|   if $force_mod_re;
$exclude_mod_re = qr|$exclude_mod_re| if $exclude_mod_re;

### see if the deps/ directory exists, and if not then we are installing
### from the -nodeps sources so don't install any perl modules
$skip_module_install = 1 unless -d $deps_dir;

$cmds{'make'}     = $makeCmd;
$cmds{'perl'}     = $perlCmd;
$cmds{'runlevel'} = $runlevelCmd;

my $distro = &get_distro();

### handle systems with systemd
my $is_systemd = &look_for_process(qr|/systemd|);

if ($is_systemd) {
    $init_dir  = $systemd_init_dir;
    $init_name = $systemd_init_name;
    $cmds{'systemctl'} = $systemctlCmd;
    die "[*] systemd init directory $init_dir does not exist, ",
        "use --systemd-init-dir <path>" unless -d $init_dir;
} else {
    if ($distro eq 'redhat' or $distro eq 'fedora') {
        ### add chkconfig only if we are runing on a redhat distro
        $cmds{'chkconfig'} = $chkconfigCmd;
    } elsif ($distro eq 'gentoo') {
        ### add rc-update if we are running on a gentoo distro
        $cmds{'rc-update'} = $rcupdateCmd;
    } elsif ($distro eq 'ubuntu') {
        ### add update-rc.d if we are running on an ubuntu distro
        $cmds{'update-rc.d'} = $updatercdCmd;
    }

    unless (-d $init_dir) {
        if (-d '/etc/rc.d/init.d') {
            $init_dir = '/etc/rc.d/init.d';
        } elsif (-d '/etc/rc.d') {  ### for Slackware
            $init_dir = '/etc/rc.d';
        } else {
            die "[*] Cannot find the init script directory, use ",
                "--init-dir <path>" unless $install_test_dir;
        }
    }
}

### need to make sure this exists before attempting to
### write anything to the install log.
&full_mkdir($config{'PSAD_DIR'}, 0700);

### make sure the system binaries are where we expect
### them to be.
&check_commands();

### occasionally things from old psad installations need to be
### dealt with separately.
&check_old_psad_installation();

if ($uninstall) {
    &uninstall();
} else {
    &install();
    open F, "> $config{'INSTALL_LOG_FILE'}" or die $!;
    print F for @installation_lines;
    close F;
}

### restore the original psad.conf file (this is just the local one in the
### sources directory).
if (-e "${psad_conf_file}.orig") {
    unlink $psad_conf_file if -e $psad_conf_file;
    move "${psad_conf_file}.orig", $psad_conf_file;
}

exit 0;
#================= end main =================

sub install() {

    ### make sure install.pl is being called from the source directory
    unless (-e 'psad') {
        die "[*] install.pl can only be executed from the directory\n",
            "    that contains the psad sources!  Exiting.";
    }
    &logr('[+] ' . localtime() . " Installing psad on hostname: $HOSTNAME\n");

    ### make sure another psad process is not running
    if (&ask_to_stop_psad()) {
        &stop_psad();
    }

    unless (-d $config{'PSAD_RUN_DIR'}) {
        &logr("[+] Creating $config{'PSAD_RUN_DIR'}\n");
        &full_mkdir($config{'PSAD_RUN_DIR'}, 0700);
    }
    unless (-d $config{'PSAD_FIFO_DIR'}) {
        &logr("[+] Creating $config{'PSAD_FIFO_DIR'}\n");
        &full_mkdir($config{'PSAD_FIFO_DIR'}, 0700);
    }

    ### change any existing psad module directory to allow anyone to import
    unless ($skip_module_install) {
        my $dir_tmp = $config{'PSAD_LIBS_DIR'};
        $dir_tmp =~ s|lib/|lib64/|;
        for my $dir ($config{'PSAD_LIBS_DIR'}, $dir_tmp) {
            if (-d $dir) {
                chmod 0755, $dir;
                unless ($no_rm_old_lib_dir) {
                    &logr("[+] Removing $dir/ directory from previous " .
                        "psad installation.\n");
                    rmtree $dir;
                }
            }
        }
    }
    unless (-d $config{'PSAD_CONF_DIR'}) {
        &logr("[+] Creating $config{'PSAD_CONF_DIR'}\n");
        &full_mkdir($config{'PSAD_CONF_DIR'}, 0700);
    }
    unless (-d $config{'CONF_ARCHIVE_DIR'}) {
        &logr("[+] Creating $config{'CONF_ARCHIVE_DIR'}\n");
        &full_mkdir($config{'CONF_ARCHIVE_DIR'}, 0700);
    }

    if ($install_syslog_fifo) {
        unless (-e $config{'PSAD_FIFO_FILE'}) {
            &logr("[+] Creating named pipe $config{'PSAD_FIFO_FILE'}\n");
            unless (&run_cmd("$cmds{'mknod'} -m 600 " .
                    "$config{'PSAD_FIFO_FILE'} p") == 0) {
                &logr("[*] Could not create the named pipe " .
                    "\"$config{'PSAD_FIFO_FILE'}\"!\n" .
                    "[*] psad requires this file to exist!  Aborting install.\n");
                die;
            }
            unless (-p $config{'PSAD_FIFO_FILE'}) {
                &logr("[*] Could not create the named pipe " .
                    "\"$config{'PSAD_FIFO_FILE'}\"!\n" .
                    "[*] psad requires this file to exist!  Aborting " .
                    "install.\n");
                die;
            }
        }
    }

    unless (-d $config{'PSAD_DIR'}) {
        &logr("[+] Creating $config{'PSAD_DIR'}\n");
        &full_mkdir($config{'PSAD_DIR'}, 0700);
    }
    unless (-d $config{'PSAD_LIBS_DIR'}) {
        &logr("[+] Creating $config{'PSAD_LIBS_DIR'}\n");
        &full_mkdir($config{'PSAD_LIBS_DIR'}, 0755);
    }

    unless (-e $config{'FW_DATA_FILE'}) {
        &logr("[+] Creating $config{'FW_DATA_FILE'} file\n");
        open F, "> $config{'FW_DATA_FILE'}" or die "[*] Could not open ",
            "$config{'FW_DATA_FILE'}: $!";
        close F;
        chmod 0600, "$config{'FW_DATA_FILE'}";
        &perms_ownership("$config{'FW_DATA_FILE'}", 0600);
    }

    unless (-d $USRSBIN_DIR) {
        &logr("[+] Creating $USRSBIN_DIR\n");
        &full_mkdir($USRSBIN_DIR, 0755);
    }
    if (-d 'deps' and -d 'deps/whois') {
        &logr("[+] Compiling Marco d'Itri's whois client\n");
        &run_cmd("$cmds{'make'} -C deps/whois");
        if (-e 'deps/whois/whois') {
            ### if an old whois process is still around ("text file
            ### busy" error), then it is ok to not be able to copy
            ### the new whois binary into place; the old one should
            ### work fine.
            &logr("[+] Copying whois binary to $cmds{'whois'}\n");
            copy 'deps/whois/whois', $cmds{'whois'};
            die "[*] Could not copy deps/whois/whois -> $cmds{'whois'}: $!"
                unless -e $cmds{'whois'};
        } else {
            die "[*] Could not compile whois";
        }
    }
    &perms_ownership($cmds{'whois'}, 0755);
    print "\n\n";

    ### install perl modules
    unless ($skip_module_install) {
        for my $module (@ordered_modules) {
            &install_perl_module($module);
        }
    }

    if (-d 'deps' and -d 'deps/snort_rules') {

        &logr("[+] Installing Snort-2.3.3 signatures in " .
            "$config{'SNORT_RULES_DIR'}\n");
        unless (-d $config{'SNORT_RULES_DIR'}) {
            &full_mkdir($config{'SNORT_RULES_DIR'}, 0700);
        }

        opendir D, 'deps/snort_rules' or die "[*] Could not open ",
            "the deps/snort_rules directory: $!";
        my @files = readdir D;
        closedir D;

        for my $file (@files) {
            next unless $file =~ /\.rules$/ or $file =~ /\.config$/;
            &logr("[+] Installing deps/snort_rules/${file}\n");
            copy "deps/snort_rules/${file}",
                 "$config{'SNORT_RULES_DIR'}/${file}" or
                die "[*] Could not copy deps/snort_rules/${file} -> ",
                    "$config{'SNORT_RULES_DIR'}/${file}: $!";
            &perms_ownership("$config{'SNORT_RULES_DIR'}/${file}", 0600);
        }
    }
    print "\n\n";

    &logr("[+] Compiling kmsgsd, and psadwatchd:\n");

    ### remove any previously compiled kmsgsd
    unlink 'kmsgsd' if -e 'kmsgsd';

    ### remove any previously compiled psadwatchd
    unlink 'psadwatchd' if -e 'psadwatchd';

    ### compile the C psad daemons
    &run_cmd($cmds{'make'});
    &logr("[-] Could not compile kmsgsd.c.\n") unless (-e 'kmsgsd');
    &logr("[-] Could not compile psadwatchd.c.\n") unless (-e 'psadwatchd');

    ### install fwcheck_psad.pl
    print "\n\n";
    &logr("[+] Verifying compilation of fwcheck_psad.pl script:\n");
    unless (&run_cmd("$cmds{'perl'} -c fwcheck_psad.pl") == 0) {
        die "[*] fwcheck_psad.pl does not compile with \"perl -c\".  Download ",
            "the latest sources from:\n\nhttp://www.cipherdyne.org/"
            unless $skip_module_install;
    }

    ### make sure the psad (perl) daemon compiles.  The other three
    ### daemons have all been re-written in C.
    &logr("[+] Verifying compilation of psad perl daemon:\n");
    unless (&run_cmd("$cmds{'perl'} -c psad") == 0) {
        die "[*] psad does not compile with \"perl -c\".  Download the",
            " latest sources from:\n\nhttp://www.cipherdyne.org/"
            unless $skip_module_install;
    }

    ### install nf2csv
    &logr("[+] Verifying compilation of nf2csv script:\n");
    unless (&run_cmd("$cmds{'perl'} -c nf2csv") == 0) {
        die "[*] nf2csv does not compile with \"perl -c\".  Download ",
            "the latest sources from:\n\nhttp://www.cipherdyne.org/"
            unless $skip_module_install;
    }

    ### put the nf2csv script in place
    unlink '/usr/sbin/nf2csv' if -e '/usr/sbin/nf2csv';  ### old path
    &logr("[+] Copying nf2csv -> ${USRBIN_DIR}/nf2csv\n");
    unlink "${USRBIN_DIR}/nf2csv" if -e "${USRBIN_DIR}/nf2csv";
    copy 'nf2csv', "${USRBIN_DIR}/nf2csv" or die "[*] Could ",
        "not copy nf2csv -> ${USRBIN_DIR}/nf2csv: $!";
    &perms_ownership("${USRBIN_DIR}/nf2csv", 0755);

    ### put the fwcheck_psad.pl script in place
    &logr("[+] Copying fwcheck_psad.pl -> $cmds{'fwcheck_psad'}\n");
    unlink $cmds{'fwcheck_psad'} if -e $cmds{'fwcheck_psad'};
    copy 'fwcheck_psad.pl', $cmds{'fwcheck_psad'} or die "[*] Could ",
        "not copy fwcheck_psad.pl -> $cmds{'fwcheck_psad'}: $!";
    &perms_ownership($cmds{'fwcheck_psad'}, 0500);

    ### put the psad daemons in place
    &logr("[+] Copying psad -> ${USRSBIN_DIR}/psad\n");
    unlink "${USRSBIN_DIR}/psad" if -e "${USRSBIN_DIR}/psad";
    copy 'psad', "${USRSBIN_DIR}/psad" or die "[*] Could not copy ",
        "psad -> ${USRSBIN_DIR}/psad: $!";
    &perms_ownership("${USRSBIN_DIR}/psad", 0500);

    &logr("[+] Copying psadwatchd -> ${USRSBIN_DIR}/psadwatchd\n");
    unlink "${USRSBIN_DIR}/psadwatchd" if -e "${USRSBIN_DIR}/psadwatchd";
    copy 'psadwatchd', "${USRSBIN_DIR}/psadwatchd" or die "[*] Could not ",
        "copy psadwatchd -> ${USRSBIN_DIR}/psadwatchd: $!";
    &perms_ownership("${USRSBIN_DIR}/psadwatchd", 0500);

    &logr("[+] Copying kmsgsd -> ${USRSBIN_DIR}/kmsgsd\n");
    unlink "${USRSBIN_DIR}/kmsgsd" if -e "${USRSBIN_DIR}/kmsgsd";
    copy 'kmsgsd', "${USRSBIN_DIR}/kmsgsd" or die "[*] Could not copy ",
        "kmsgsd -> ${USRSBIN_DIR}/kmsgsd: $!";
    &perms_ownership("${USRSBIN_DIR}/kmsgsd", 0500);

    unless (-d $config{'PSAD_CONF_DIR'}) {
        &logr("[+] Creating $config{'PSAD_CONF_DIR'}\n");
        &full_mkdir($config{'PSAD_CONF_DIR'}, 0700);
    }

    my $syslog_str = '';

    if ($install_syslog_fifo) {
        ### get syslog daemon (e.g. syslog, rsyslog syslog-ng, or metalog)
        $syslog_str = &query_syslog();
    } else {
        print
"[+] psad by default parses iptables log messages from the /var/log/messages\n",
"    file, but you can alter this with the IPT_SYSLOG_FILE variable in the\n",
"    /etc/psad/psad.conf file.\n";
    }

    my $preserve_rv = 0;
    if (-e "$config{'PSAD_CONF_DIR'}/psad.conf") {
        $preserve_rv = &query_preserve_config();
    }

    ### the order of the config files is important (legacy FW_MSG_SEARCH
    ### vars in psad.conf).
    my $prod_file = "$config{'PSAD_CONF_DIR'}/psad.conf";
    if (-e $prod_file) {
        &archive($prod_file) unless $noarchive;
        if ($preserve_rv) {
            &preserve_config('psad.conf', $prod_file);
        } else {
            &logr("[+] Copying psad.conf -> $prod_file\n");
            copy 'psad.conf', $prod_file or die "[*] Could not ",
                "copy psad.conf -> $prod_file: $!";
        }
    } else {
        &logr("[+] Copying psad.conf -> $prod_file\n");
        copy 'psad.conf', $prod_file or die "[*] Could not copy ",
            "psad.conf -> $prod_file: $!";
    }

    if ($force_path_update or not $preserve_rv) {
        &update_command_paths($prod_file);
    }

    &perms_ownership($prod_file, 0600);

    ### install auto_dl, signatures, icmp_types, posf, and pf.os files
    for my $filename (keys %file_vars) {
        my $file = $config{$file_vars{$filename}};
        if (-e $file) {
            &archive($file) unless $noarchive;
            ### FIXME, need a real config preservation routine for these files.
            unless (&query_preserve_sigs_autodl($file)) {
                &logr("[+] Copying $filename -> $file\n");
                copy $filename, $file or die "[*] Could not ",
                    "copy $filename -> $file: $!";
                &perms_ownership($file, 0600);
            }
        } else {
            &logr("[+] Copying $filename -> $file\n");
            copy $filename, $file or die "[*] Could not ",
                "copy $filename -> $file: $!";
            &perms_ownership($file, 0600);
        }
    }

    ### archive and remove legacy config files
    for my $filename (qw(kmsgsd.conf psadwatchd.conf alert.conf
            fw_search.conf)) {
        my $path = "$config{'PSAD_CONF_DIR'}/$filename";
        if (-e $path) {
            &archive($path);
            unlink $path;
        }
    }
    &logr("\n");

    unless ($preserve_rv) {  ### we want to preserve the existing config

        ### get email address(es)
        my $email_str = &query_email();
        if ($email_str) {
            &put_var('EMAIL_ADDRESSES', $email_str,
                "$config{'PSAD_CONF_DIR'}/psad.conf");
        }

        ### Give the admin the opportunity to set the strings that are
        ### parsed out of iptables messages.  This is useful since the
        ### admin may have configured the firewall to use a logging prefix
        ### of "Audit" or something else other than the default string
        ### "DROP".
        my $fw_search_ar = &get_fw_search_strings();
        if ($fw_search_ar) {
            open F, "< $config{'PSAD_CONF_DIR'}/psad.conf"
                or die "[*] Could not open ",
                    "$config{'PSAD_CONF_DIR'}/psad.conf: $!";
            my @lines = <F>;
            close F;
            open T, "> $config{'PSAD_CONF_DIR'}/psad.conf.tmp"
                or die "[*] Could not open ",
                    "$config{'PSAD_CONF_DIR'}/psad.conf.tmp: $!";
            for my $line (@lines) {
                if ($line =~ /^\s*FW_MSG_SEARCH\s/) {
                    for my $fw_str (@$fw_search_ar) {
                        &logr(qq{[+] Setting FW_MSG_SEARCH to "$fw_str" } .
                            "in $config{'PSAD_CONF_DIR'}/psad.conf\n");
                        printf T "%-28s%s;\n", 'FW_MSG_SEARCH', $fw_str;
                    }
                } else {
                    print T $line unless $line =~ /^\s*FW_MSG_SEARCH\s/;
                }
            }
            close T;
            move "$config{'PSAD_CONF_DIR'}/psad.conf.tmp",
                "$config{'PSAD_CONF_DIR'}/psad.conf"
                or die "[*] Could not move ",
                "$config{'PSAD_CONF_DIR'}/psad.conf.tmp -> ",
                "$config{'PSAD_CONF_DIR'}/psad.conf: $!";
        }
        ### Give the admin the opportunity to set the HOME_NET variable.
        &set_home_net("$config{'PSAD_CONF_DIR'}/psad.conf");

        ### see if the admin would like to have psad send info to
        ### DShield
        if (&query_dshield()) {
            &put_var('ENABLE_DSHIELD_ALERTS', 'Y',
                "$config{'PSAD_CONF_DIR'}/psad.conf");
        }

        ### Set the hostname
        my $file = "$config{'PSAD_CONF_DIR'}/psad.conf";
        &logr("[+] Setting hostname to \"$HOSTNAME\" in $file\n");
        &set_hostname($file);
    }

    if ($install_syslog_fifo) {
        &put_var('SYSLOG_DAEMON', $syslog_str,
            "$config{'PSAD_CONF_DIR'}/psad.conf");

        if ($syslog_str ne 'ulogd') {
            my $restarted_syslog = 0;
            if ($syslog_str eq 'syslogd') {
                if (-e $syslog_conf) {
                    &append_fifo_syslog($syslog_conf);
                    if (&run_cmd("$cmds{'killall'} -HUP syslogd 2> /dev/null") == 0) {
                        &logr("[+] HUP signal sent to syslogd.\n");
                        $restarted_syslog = 1;
                    }
                }
            } elsif ($syslog_str eq 'rsyslogd') {
                if (-e $syslog_conf) {
                    &append_fifo_syslog($syslog_conf);
                    if (&run_cmd("$cmds{'killall'} -HUP rsyslogd 2> /dev/null") == 0) {
                        &logr("[+] HUP signal sent to rsyslogd.\n");
                        $restarted_syslog = 1;
                    }
                }

            } elsif ($syslog_str eq 'syslog-ng') {
                if (-e $syslog_conf) {
                    &append_fifo_syslog_ng($syslog_conf);
                    if (&run_cmd("$cmds{'killall'} -HUP syslog-ng 2> /dev/null") == 0) {
                        &logr("[+] HUP signal sent to syslog-ng.\n");
                        $restarted_syslog = 1;
                    }
                }
            } elsif ($syslog_str eq 'metalog') {
                if (-e $syslog_conf) {
                    &config_metalog($syslog_conf);
                    &logr("[-] Metalog support is shaky in psad.  " .
                        "Use at your own risk.\n");
                    ### don't send warning about not restarting metalog daemon
                    $restarted_syslog = 1;
                }
            }

            unless ($restarted_syslog) {
                &logr("[-] Could not restart any syslog daemons.\n");
            }
        }

        if (-x $cmds{'iptables'} and not $skip_syslog_test) {
            &logr("[+] Found iptables. Testing syslog configuration:\n");
            ### make sure we actually see packets being logged by
            ### the firewall.
            if ($syslog_str ne 'ulogd') {
                if (&test_syslog_config($syslog_str)) {
                    &logr("[+] Successful $syslog_str reconfiguration.\n\n");
                } else {
                    if (&query_init_script_restart_syslog()) {

                        my $restarted = 0;
                        if ($syslog_str eq 'syslog-ng') {
                            if (-e "$init_dir/syslog-ng") {
                                &run_cmd("$init_dir/syslog-ng restart");
                                $restarted = 1;
                            }
                        } elsif ($syslog_str eq 'rsyslogd') {
                            if (-e "$init_dir/sysklogd") {
                                &run_cmd("$init_dir/sysklogd restart");
                                $restarted = 1;
                            } elsif (-e "$init_dir/syslog") {
                                &run_cmd("$init_dir/syslog restart");
                                $restarted = 1;
                            }
                        } else {
                            if (-e "$init_dir/rsyslog") {
                                &run_cmd("$init_dir/rsyslog restart");
                                $restarted = 1;
                            }
                        }
                        ### test syslog config again now that we
                        ### have restarted syslog via the init script
                        ### instead of relying on a HUP signal to
                        ### syslog
                        if ($restarted) {
                            if (&test_syslog_config($syslog_str)) {
                                &logr("[+] Successful $syslog_str reconfiguration.\n\n");
                            } else {
                                &logr("[-] Unsuccessful $syslog_str reconfiguration.\n");
                                &logr("    Consult the psad man page for the basic " .
                                    "$syslog_str requirement to get psad to work.\n\n");
                            }
                        }
                    } else {
                        &logr("[-] Ok, hoping that psad can get packet data anyway.\n");
                    }
                }
            }
        }
    }

    ### download signatures?
    &download_signatures() if &query_signatures();

    &install_manpage('psad.8');
    &install_manpage('psadwatchd.8');
    &install_manpage('kmsgsd.8');
    &install_manpage('nf2csv.1');

    my $init_file = '';
    my $installed_init_script = 0;

    if ($is_systemd) {
        $init_file = 'init-scripts/systemd/psad.service';
    } else {
        if ($distro eq 'redhat') {
            $init_file = 'init-scripts/psad-init.redhat';
        } elsif ($distro eq 'fedora') {
            $init_file = 'init-scripts/psad-init.fedora';
        } elsif ($distro eq 'gentoo') {
            $init_file = 'init-scripts/psad-init.gentoo';
        } else {
            $init_file = 'init-scripts/psad-init.generic';
        }
    }

    if ($init_dir and &is_root()) {
        &logr("[+] Copying $init_file -> ${init_dir}/$init_name\n");
        copy $init_file, "${init_dir}/$init_name" or die "[*] Could not copy ",
            "$init_file -> ${init_dir}/$init_name: $!";
        if ($is_systemd) {
            &perms_ownership("${init_dir}/$init_name", 0644);
        } else {
            &perms_ownership("${init_dir}/$init_name", 0744);
        }
        &enable_psad_at_boot($distro);
        $installed_init_script = 1;
    }

    &logr("\n========================================================\n");
    if ($archived_old) {
        &logr("[+] Copies of your original configs have been made " .
            "in: $config{'CONF_ARCHIVE_DIR'}\n");
    }
    if ($preserve_rv) {
        &logr("\n[+] psad has been installed (with your original config merged).\n");
    } else {
        &logr("\n[+] psad has been installed.\n");
    }
    if ($installed_init_script) {
        if ($init_dir) {
            if ($is_systemd) {
                &logr("\n[+] To start psad, run \"$cmds{'systemctl'} start psad\"\n");
            } else {
                &logr("\n[+] To start psad, run \"${init_dir}/psad start\"\n");
            }
        } else {
            &logr("\n[+] To start psad, run ${USRSBIN_DIR}/psad\"\n");
        }
    }

    return;
}

sub import_config() {
    open C, "< $psad_conf_file"
        or die "[*] Could not open $psad_conf_file: $!";
    while (<C>) {
        next if /^\s*#/;
        if (/^\s*(\S+)\s+(.*?)\;/) {
            my $varname = $1;
            my $val     = $2;
            if ($val =~ m|/.+| and $varname =~ /^\s*(\S+)Cmd$/) {
                ### found a command
                $cmds{$1} = $val;
            } else {
                $config{$varname} = $val;
            }
        }
    }
    close C;

    ### see if the install root is the same as the default in psad.conf and
    ### update if not
    if ($install_root ne '/') {
        $install_root = getcwd() . "/$install_root"
            unless $install_root =~ m|^/|;
        $config{'INSTALL_ROOT'} = $install_root;
        $USRSBIN_DIR = $config{'INSTALL_ROOT'} . $USRSBIN_DIR;
        $USRBIN_DIR  = $config{'INSTALL_ROOT'} . $USRBIN_DIR;

        &put_var('INSTALL_ROOT', $install_root, $psad_conf_file);
    }

    for my $dir ($install_root, $USRSBIN_DIR, $USRBIN_DIR) {
        &full_mkdir($dir, 0755) unless -d $dir;
    }

    if ($install_test_dir) {
        &full_mkdir($init_dir, 0755) unless -d $init_dir;
    }

    ### resolve internal vars within variable values
    &expand_vars();

    &required_vars();

    return;
}

sub expand_vars() {

    my $has_sub_var = 1;
    my $resolve_ctr = 0;

    while ($has_sub_var) {
        $resolve_ctr++;
        $has_sub_var = 0;
        if ($resolve_ctr >= 20) {
            die "[*] Exceeded maximum variable resolution counter.";
        }
        for my $hr (\%config, \%cmds) {
            for my $var (keys %$hr) {
                my $val = $hr->{$var};
                if ($val =~ m|\$(\w+)|) {
                    my $sub_var = $1;
                    die "[*] sub-ver $sub_var not allowed within same ",
                        "variable $var" if $sub_var eq $var;
                    if (defined $config{$sub_var}) {
                        if ($sub_var eq 'INSTALL_ROOT' and $config{$sub_var} eq '/') {
                            $val =~ s|\$$sub_var||;
                        } else {
                            $val =~ s|\$$sub_var|$config{$sub_var}|;
                        }
                        $hr->{$var} = $val;
                    } else {
                        die "[*] sub-var \"$sub_var\" not defined in ",
                            "config for var: $var."
                    }
                    $has_sub_var = 1;
                }
            }
        }
    }
    return;
}

sub required_vars() {
    my @vars = (qw(
        INSTALL_LOG_FILE PSAD_DIR PSAD_RUN_DIR PSAD_LIBS_DIR
        SIG_UPDATE_URL PSAD_FIFO_DIR PSAD_FIFO_FILE SNORT_RULES_DIR
        IP_OPTS_FILE SIGS_FILE AUTO_DL_FILE SNORT_RULE_DL_FILE
        POSF_FILE P0F_FILE IP_OPTS_FILE FW_DATA_FILE
    ));
    for my $var (@vars) {
        die "[*] Missing required var: $var in $psad_conf_file"
            unless defined $config{$var};
    }
    return;
}

sub uninstall() {
    &logr("\n[+] Uninstalling psad from $HOSTNAME: " . localtime() . "\n");

    unless (&query_yes_no('[+] This will completely remove psad ' .
                "from your system.\n    Are you sure (y/n)? ",
                $NO_ANS_DEFAULT)) {
        &logr("[*] User aborted uninstall by answering \"n\" to the remove " .
            "question!  Exiting.\n");
        exit 0;
    }
    ### after this point, psad will really be uninstalled so stop writing stuff
    ### to the install.log file.  Just print everything to STDOUT
    if (-e $config{'PSAD_PID_FILE'}) {
        open PID, "$config{'PSAD_PID_FILE'}" or die "[*] Could not open ",
            "$config{'PSAD_PID_FILE'}: $!";
        my $pid = <PID>;
        close PID;
        chomp $pid;
        if (kill 0, $pid) {
            print "[+] Stopping psad daemons!\n";
            if (-e "${init_dir}/psad") {  ### prefer this for old versions
                &run_cmd("${init_dir}/psad stop");
            } else {
                &run_cmd("${USRSBIN_DIR}/psad --Kill");
            }
        }
    }
    if (-e $cmds{'fwcheck_psad'}) {
        print "[+] Removing $cmds{'fwcheck_psad'}\n";
        unlink $cmds{'fwcheck_psad'};
    }
    if (-e "${USRBIN_DIR}/nf2csv") {
        print "[+] Removing ${USRBIN_DIR}/nf2csv\n";
        unlink "${USRBIN_DIR}/nf2csv";
    }
    if (-e "${USRSBIN_DIR}/psad") {
        print "[+] Removing psad daemons: ${USRSBIN_DIR}/",
            "(psad, psadwatchd, kmsgsd)\n";
        unlink "${USRSBIN_DIR}/psad" or
            warn "[*] Could not remove ${USRSBIN_DIR}/psad!!!\n";
        unlink "${USRSBIN_DIR}/psadwatchd" or
            warn "[*] Could not remove ${USRSBIN_DIR}/psadwatchd!!!\n";
        unlink "${USRSBIN_DIR}/kmsgsd" or
            warn "[*] Could not remove ${USRSBIN_DIR}/kmsgsd!!!\n";
    }
    if (-e "${init_dir}/psad") {
        print "[+] Removing ${init_dir}/$init_name\n";
        unlink "${init_dir}/$init_name";
    }
    if (-d $config{'PSAD_CONF_DIR'}) {
        print "[+] Removing configuration directory: $config{'PSAD_CONF_DIR'}";
        rmtree($config{'PSAD_CONF_DIR'}, 1, 0);
    }
    if (-d $config{'PSAD_DIR'}) {
        print "[+] Removing logging directory: $config{'PSAD_DIR'}\n";
        rmtree($config{'PSAD_DIR'}, 1, 0);
    }
    if (-e $config{'PSAD_FIFO_FILE'}) {
        print "[+] Removing named pipe: $config{'PSAD_FIFO_FILE'}\n";
        unlink $config{'PSAD_FIFO_FILE'};
    }
    if (-e $cmds{'whois'}) {
        print "[+] Removing $cmds{'whois'}\n";
        unlink $cmds{'whois'};
    }
    if (-d $config{'PSAD_FIFO_DIR'}) {
        print "[+] Removing $config{'PSAD_FIFO_DIR'}\n";
        rmtree $config{'PSAD_FIFO_DIR'};
    }
    if (-d $config{'PSAD_RUN_DIR'}) {
        print "[+] Removing $config{'PSAD_RUN_DIR'}\n";
        rmtree $config{'PSAD_RUN_DIR'};
    }

    my $dir_tmp = $config{'PSAD_LIBS_DIR'};
    $dir_tmp =~ s|lib/|lib64/|;
    for my $dir ($config{'PSAD_LIBS_DIR'}, $dir_tmp) {
        if (-d $dir) {
            print "[+] Removing $dir\n";
            rmtree $dir;
        }
    }
    print "\n[+] psad has been uninstalled!\n";
    return;
}

sub ask_to_stop_psad() {
    if (-e $config{'PSAD_PID_FILE'}) {
        open P, "< $config{'PSAD_PID_FILE'}" or die "[*] Could not open ",
            "$config{'PSAD_PID_FILE'}: $!";
        my $pid = <P>;
        close P;
        chomp $pid;
        if (kill 0, $pid) {
            print "[+] An existing psad daemon is running.\n";
            if (&query_yes_no("    Can I stop the existing psad " .
                        "daemon ([y]/n)?  ", $ACCEPT_YES_DEFAULT)) {
                return 1;
            } else {
                die "[*] Aborting install.";
            }
        }
    }
    return 0;
}

sub stop_psad() {
    if (-e $config{'PSAD_PID_FILE'}) {
        open P, "< $config{'PSAD_PID_FILE'}" or die "[*] Could not open ",
            "$config{'PSAD_PID_FILE'}: $!";
        my $pid = <P>;
        close P;
        chomp $pid;
        if (kill 0, $pid) {
            print "[+] Stopping running psad daemons.\n";
            if (-x "$init_dir/$init_name") {
                if ($is_systemd) {
                    &run_cmd("$cmds{'systemctl'} stop psad");
                } else {
                    &run_cmd("$init_dir/$init_name stop");
                }
                ### if psad is still running then use -K
                if (kill 0, $pid) {
                    &run_cmd("$USRSBIN_DIR/psad -K");
                }
            } else {
                ### psad may have been started from the command line
                ### without using the init script, so stop with -K
                &run_cmd("$USRSBIN_DIR/psad -K");
            }
        }
    }
    return;
}

sub install_perl_module() {
    my $mod_name = shift;

    chdir $src_dir or die "[*] Could not chdir $src_dir: $!";
    chdir $deps_dir or die "[*] Could not chdir($deps_dir): $!";

    die '[*] Missing force-install key in required_perl_modules hash.'
        unless defined $required_perl_modules{$mod_name}{'force-install'};
    die '[*] Missing mod-dir key in required_perl_modules hash.'
        unless defined $required_perl_modules{$mod_name}{'mod-dir'};

    if ($exclude_mod_re and $exclude_mod_re =~ /$mod_name/) {
        print "[+] Excluding installation of $mod_name module.\n";
        return;
    }

    my $version = '(NA)';

    my $mod_dir = $required_perl_modules{$mod_name}{'mod-dir'};

    if (-e "$mod_dir/VERSION") {
        open F, "< $mod_dir/VERSION" or
            die "[*] Could not open $mod_dir/VERSION: $!";
        $version = <F>;
        close F;
        chomp $version;
    } else {
        print "[-] Warning: VERSION file does not exist in $mod_dir\n";
    }

    my $install_module = 0;

    if ($required_perl_modules{$mod_name}{'force-install'}
            or $cmdline_force_install) {
        ### install regardless of whether the module may already be
        ### installed
        $install_module = 1;
    } elsif ($force_mod_re and $force_mod_re =~ /$mod_name/) {
        print "[+] Forcing installation of $mod_name module.\n";
        $install_module = 1;
    } else {
        if (has_perl_module($mod_name)) {
            print "[+] Module $mod_name is already installed in the ",
                "system perl tree, skipping.\n";
        } else {
            ### install the module in the /usr/lib/psad directory because
            ### it is not already installed.
            $install_module = 1;
        }
    }

    if ($install_module) {
        &logr("[+] Installing the $mod_name $version perl " .
            "module in $config{'PSAD_LIBS_DIR'}/\n");
        my $mod_dir = $required_perl_modules{$mod_name}{'mod-dir'};
        chdir $mod_dir or die "[*] Could not chdir to ",
            "$mod_dir: $!";
        unless (-e 'Makefile.PL') {
            die "[*] Your $mod_name source directory appears to be incomplete!\n",
                "    Download the latest sources from ",
                "http://www.cipherdyne.org/";
        }

        $ENV{'PERL5LIB'} = $config{'PSAD_LIBS_DIR'};  ### for module dependencies
        &run_cmd("$cmds{'make'} clean")
            if -e 'Makefile' or -e 'makefile' or -e 'GNUmakefile';
        &run_cmd("$cmds{'perl'} Makefile.PL PREFIX=$config{'PSAD_LIBS_DIR'} " .
            "LIB=$config{'PSAD_LIBS_DIR'}");
        &run_cmd("$cmds{'make'}");
#        &run_cmd("$cmds{'make'} test");
        &run_cmd("$cmds{'make'} install");
        chdir $src_dir or die "[*] Could not chdir $src_dir: $!";

        print "\n\n";
    }

    return;
}

sub run_cmd_get_output() {
    my ($cmd_path, $args) = @_;
    my $cmd = $cmd_path;
    $cmd .= " $args" if $args;
    open CMD, "$cmd |" or die "[*] Could not ",
        "execute $cmd: $!";
    my @lines = <CMD>;
    close CMD;
    return \@lines;
}

sub look_for_process() {
    my $process_re = shift;
    for (@{&run_cmd_get_output($cmds{'ps'}, 'auxww')}) {
        return 1 if /$process_re/;
    }
    return 0;
}

sub run_cmd() {
    my $cmd = shift;
    &logr("[+] CMD: '$cmd'\n");
    return (system $cmd) >> 8;
}

sub set_home_net() {
    my $file = shift;

    ### first see if the admin will accept the default 'any' value
    return if &query_use_home_net_default();

### FIXME future
#    my $str =
#"\n    Ok, would you like psad to automatically get the local subnets by\n" .
#"    parsing ifconfig output?  (This is probably best for most situations).\n";
#    &logr($str);
#    if (&query_yes_no('    ([y]/n)?  ', $ACCEPT_YES_DEFAULT)) {
#        return;
#    }
    ### if we make it here, then the admin wants to completely enumerate the
    ### HOME_NET var, so we have to disable ENABLE_INTF_LOCAL_NETS
#    &put_var('ENABLE_INTF_LOCAL_NETS', 'N',
#        "$config{'PSAD_CONF_DIR'}/psad.conf");

    ### get all interfaces; even those that are down since they may
    ### brought up any time.
    my @ifconfig_out = `$cmds{'ifconfig'} -a`;
    my $home_net_str = '';
    my $intf_name = '';
    my $net_ctr = 0;
    my %connected_subnets;
    for my $line (@ifconfig_out) {
        if ($line =~ /^\s*lo\s+Link/) {
            $intf_name = '';
            next;
        }
        if ($line =~ /^\s*dummy.*\s+Link/) {
            $intf_name = '';
            next;
        }
        if ($line =~ /^(\S+)\s+Link/) {
            $intf_name = $1;
            next;
        }
        if ($intf_name and
                $line =~ /^\s+inet\s+.*?:($ip_re).*:($ip_re)/) {
            my $ip = $1;
            my $mask = $2;

            my @ipbytes = split /\./, $ip;
            my @mbytes  = split /\./, $mask;

            my $netaddr = '';
            for (my $i=0; $i < 4; $i++) {
                my $byte1 = $mbytes[$i]+0;
                my $byte2 = $ipbytes[$i]+0;
                my $netaddr_byte = $byte1 & $byte2;
                if ($i != 0) {
                    $netaddr = $netaddr . '.' . $netaddr_byte;
                } else {
                    $netaddr = $netaddr_byte;
                }
            }

            $connected_subnets{$intf_name} = "$netaddr/$mask";
            $net_ctr++;
        }
    }
    ### found two or more subnets, so forwarding traffic becomes
    ### possible through the box.
    &logr("\n    It appears your machine is connected to " .
        "$net_ctr subnets:\n");
    for my $intf (keys %connected_subnets) {
        &logr("      $intf -> $connected_subnets{$intf}\n");
    }
    my $ans_file_str = 'Specify HOME_NET subnets:';
    my $str =
"\n    Specify which subnets are part of your internal network.  Note that\n" .
"    you can correct anything you enter here by editing the \"HOME_NET\"\n" .
"    variable in: $file.\n\n" .
"    Enter each of the subnets (except for the external subnet) on a line by\n" .
"    itself.  Each of the subnets should be in the form <net>/<mask>.  E.g.\n" .
"    in CIDR notation: 192.168.10.0/24 (preferrable), or regular notation:\n" .
"    192.168.10.0/255.255.255.0\n\n    End with a \".\" on a line by itself.\n\n";
    &logr($str);
    if ($use_answers and defined $answers{$ans_file_str}) {
        $home_net_str = $answers{$ans_file_str};
        print "$answers{$ans_file_str}\n";
    } else {
        my $ans = '';
        while ($ans !~ /^\s*\.\s*$/) {
            &logr("    Subnet: ");
            $ans = <STDIN>;
            chomp $ans;
            if ($ans =~ m|^\s*($ip_re/\d+)\s*$|) {
                ### hard to test this directly without ipv4_network()
                ### and this module may not be installed, so just use it.
                $home_net_str .= "$1, ";
            } elsif ($ans =~ m|^\s*($ip_re/$ip_re)\s*$|) {
                $home_net_str .= "$1, ";
            } elsif ($ans !~ /^\s*\.\s*$/) {
                &logr("[-] Invalid subnet \"$ans\"\n");
            }
        }
        $home_net_str =~ s/\,\s*$//;
        &put_answer_file_value($ans_file_str, $home_net_str);
    }
    &put_var('HOME_NET', $home_net_str, $file);
    return;
}

sub query_signatures() {
    &logr("[+] The latest psad signatures can be installed with " .
        qq|"psad --sig-update"\n    or installed now with install.pl.\n\n|);
    &logr("    If you decide to answer 'y' to the next question, install.pl\n" .
        "    will require DNS and network access now.\n\n");
    return &query_yes_no("    Would you like to install the latest " .
            "signatures from\n      $config{'SIG_UPDATE_URL'} " .
            "(y/n)?  ", $NO_ANS_DEFAULT);
}

sub download_signatures() {

    my $curr_pwd = cwd() or die $!;
    chdir '/tmp' or die $!;

    print "[+] Downloading latest signatures from:\n",
        "        $config{'SIG_UPDATE_URL'}\n";

    unlink 'signatures' if -e 'signatures';

    ### download the file
    unless (-x $wgetCmd) {
        &logr("[-] The $wgetCmd var is not a valid path for wget, " .
            "skipping sig install.\n");
    }
    &run_cmd("$wgetCmd $config{'SIG_UPDATE_URL'}");

    unless (-e 'signatures') {
        &logr("[-] Could not download signatures, continuing with install.\n");
    }

    unlink "$config{'PSAD_CONF_DIR'}/signatures"
        if -e "$config{'PSAD_CONF_DIR'}/signatures";
    move 'signatures', "$config{'PSAD_CONF_DIR'}/signatures";
    chdir $curr_pwd or die $!;

    return;
}

sub query_use_home_net_default() {
    my $str =
"\n[+] By default, psad matches Snort rules against any IP addresses, but\n" .
"    psad offers the ability to restrict signature matches to specific\n" .
"    networks with the HOME_NET variable (similar to Snort).  However, psad\n" .
"    also offers the ability to acquire all local subnets on the local system\n" .
"    by parsing the output of \"ifconfig\", or the subnets can be restricted\n" .
"    to a limited set of networks.\n\n";
    &logr($str);
    return &query_yes_no(
"    First, is it ok to leave the HOME_NET setting as \"any\" ([y]/n)?  ",
        $ACCEPT_YES_DEFAULT);
}

sub set_hostname() {
    my $file = shift;
    if (-e $file) {
        open P, "< $file" or die "[*] Could not open $file: $!";
        my @lines = <P>;
        close P;
        ### replace the "HOSTNAME           _CHANGEME_" line
        open PH, "> $file" or die "[*] Could not open $file: $!";
        for my $line (@lines) {
            chomp $line;
            if ($line =~ /^\s*HOSTNAME(\s+)_?CHANGE.?ME_?/) {
                print PH "HOSTNAME${1}$HOSTNAME;\n";
            } else {
                print PH "$line\n";
            }
        }
        close PH;
        &check_hostname($file);
    } else {
        die "[*] Your source directory appears to be incomplete!  $file ",
            "is missing.\n    Download the latest sources from ",
            "http://www.cipherdyne.org/";
    }
    return;
}

### see if there are any "_CHANGEME_" strings left and give the
### admin a chance to correct (this can happen if a new config
### variable is introduced in a new version of psad but the
### admin chose to preserve the old config).
sub check_hostname() {
    my $file = shift;

    open F, "< $file" or die "[*] Could not open $file: $!";
    my @lines = <F>;
    close F;
    for my $line (@lines) {
        next if $line =~ /^\s*#/;
        if ($line =~ /^\s*(\S+)\s+_?CHANGE.?ME_?\;/) {
            my $var = $1;
            ### only the HOSTNAME variable is set to _CHANGEME_ by
            ### default as of psad-1.6.0
            if ($var eq 'HOSTNAME') {
                &logr("[-] set_hostname() failed.  Edit the HOSTNAME " .
                    " variable in $file\n");
            } else {
                &logr("[-] Var $var is set to _CHANGEME_ in " .
                    "$file, edit manually.\n");
            }
        }
    }
    return;
}

sub append_fifo_syslog_ng() {
    my $syslog_conf = shift;
    open RS, "< $syslog_conf" or
        die "[*] Unable to open $syslog_conf: $!";
    my @slines = <RS>;
    close RS;

    my $found_fifo = 0;
    for my $line (@slines) {
        next if $line =~ m/^\s*#/;
        $found_fifo = 1 if ($line =~ /psadfifo/);
    }

    unless ($found_fifo) {
        &logr("[+] Modifying $syslog_conf to write kern.info " .
            "messages to\n    $config{'PSAD_FIFO_FILE'}\n");
        unless (-e "$syslog_conf.orig") {
            copy $syslog_conf, "$syslog_conf.orig" or die "[*] Could not ",
                "copy $syslog_conf -> $syslog_conf.orig: $!";
        }
        &archive($syslog_conf);

        open SYSLOGNG, ">> $syslog_conf" or
            die "[*] Unable to open $syslog_conf: $!";
        print SYSLOGNG "\n",
            qq|source psadsrc { unix-stream("/dev/log"); |,
            qq|internal(); pipe("/proc/kmsg"); };\n|,
            qq|filter f_psad { facility(kern) and match("IN=") |,
            qq|and match("OUT="); };\n|,
            'destination psadpipe { ',
            "pipe(\"$config{'PSAD_FIFO_FILE'}\"); };\n",
            'log { source(psadsrc); filter(f_psad); ',
            "destination(psadpipe); };\n";
        close SYSLOGNG;
    }
    return;
}

sub import_answers() {
    die "[*] $answers_file does not exist" unless -e $answers_file;
    open F, "< $answers_file" or die "[*] Could not open $answers_file: $!";
    while (<F>) {
        if (/^(.*?:)\s+(.*);/) {
            $answers{$1} = $2;
        }
    }
    close F;
    return;
}

sub config_metalog() {
    my $syslog_conf = shift;
    open RS, "< $syslog_conf" or
        die "[*] Unable to open $syslog_conf: $!";
    my @lines = <RS>;
    close RS;

    my $found = 0;
    for my $line (@lines) {
        if ($line =~ m/psadpipe\.sh/) {
            $found = 1;
            last;
        }
    }
    unless ($found) {
        &logr("[+] Modifying $syslog_conf to write kern.info messages " .
            "to\n    $config{'PSAD_FIFO_FILE'} " .
            "(with script /usr/sbin/psadpipe.sh)");
        unless (-e "$syslog_conf.orig") {
            copy $syslog_conf, "$syslog_conf.orig" or die "[*] Could not copy ",
                "$syslog_conf -> $syslog_conf.orig: $!";
        }
        open METALOG, "> $syslog_conf" or
            die "[*] Unable to open $syslog_conf: $!";

        print METALOG "\n",
            "\nPSAD :\n",
            "  facility = \"kern\"\n",
            '  command  = ',
            "\"/usr/sbin/psadpipe.sh\"\n";
        close METALOG;

        open PIPESCRIPT, '> /usr/sbin/psadpipe.sh' or
            die "[*] Unable to open /usr/sbin/psadpipe.sh: $!";
        print PIPESCRIPT "#!/bin/sh\n\n",
            "echo \"\$3\" >> $config{'PSAD_FIFO_FILE'}\n";
        close PIPESCRIPT;
        chmod 0700, '/usr/sbin/psadpipe.sh';
        &logr('[+] Generated /usr/sbin/psadpipe.sh ' .
            "which writes to $config{'PSAD_FIFO_FILE'}");

        ### (Dennis Freise <cat@final-frontier.ath.cx>)
        ### Metalog seems to simply die on SIGHUP and SIGALRM, and I
        ### found no signal or option to reload it's config... :-(
        &logr('[-] All files written. You have to manually restart metalog! ',
            'When done, start psad again.');
    }
    return;
}

sub query_yes_no() {
    my ($msg, $style) = @_;

    my $ans_file_str = $msg;
    $ans_file_str =~ s|\n| |g;
    $ans_file_str =~ s|\W| |g;
    $ans_file_str =~ s|\s+| |g;
    $ans_file_str =~ s|^\s+||;
    $ans_file_str =~ s|\s+$||;
    $ans_file_str =~ s|\sy\sn||;
    $ans_file_str .= ':' unless $ans_file_str =~ m|\:$|;

    if ($use_answers and defined $answers{$ans_file_str}) {
        &logr($msg);
        print "$answers{$ans_file_str}\n";
        if (lc($answers{$ans_file_str}) eq 'y') {
            return 1;
        } else {
            return 0;
        }
    } else {
        my $ans = '';
        while ($ans ne 'y' and $ans ne 'n') {
            &logr($msg);
            $ans = lc(<STDIN>);
            if ($style == $ACCEPT_YES_DEFAULT) {
                if ($ans eq "\n") {
                    &put_answer_file_value($ans_file_str, 'y');
                    return 1;
                }
            } elsif ($style == $ACCEPT_NO_DEFAULT) {
                if ($ans eq "\n") {
                    &put_answer_file_value($ans_file_str, 'n');
                    return 0;
                }
            }
            chomp $ans;
        }
        if ($ans eq 'y') {
            &put_answer_file_value($ans_file_str, 'y');
            return 1;
        } else {
            &put_answer_file_value($ans_file_str, 'n');
            return 0;
        }
    }
    return 0;
}

sub query_preserve_config() {
    return &query_yes_no("[+] Would you like to merge the " .
            "config from the existing\n    psad installation ([y]/n)?  ",
            $ACCEPT_YES_DEFAULT);
}

sub query_init_script_restart_syslog() {
    return &query_yes_no("[+] Is it ok to restart the syslog " .
            "daemon ([y]/n)?  ", $ACCEPT_YES_DEFAULT);
}

sub query_preserve_sigs_autodl() {
    my $file = shift;
    return &query_yes_no("[+] Preserve any user modfications " .
            "in $file ([y]/n)?  ", $ACCEPT_YES_DEFAULT);
}

sub preserve_config() {
    my ($local_file, $prod_file) = @_;
    open C, "< $local_file" or die "[*] Could not open $local_file: $!";
    my @new_lines = <C>;
    close C;

    open CO, "< $prod_file" or die "[*] Could not open $prod_file: $!";
    my @orig_lines = <CO>;
    close CO;

    &logr("[+] Preserving existing config: $prod_file\n");
    ### write to a tmp file and then move so any running psad daemon will
    ### re-import a full config file if a HUP signal is received during
    ### the install.
    open CONF, "> $prod_file.new" or die "[*] Could not open ",
        "$prod_file.new: $!";
    for my $new_line (@new_lines) {
        if ($new_line =~ /^\s*#/) {
            print CONF $new_line;  ### take comments from new file.
        } elsif ($new_line =~ /^\s*(\S+)/) {
            my $var = $1;
            my $found = 0;
            for my $orig_line (@orig_lines) {
                if ($orig_line =~ /^\s*$var\s/
                        and $var ne 'PSAD_AUTO_DL_FILE'  ### special case paths
                        and $var ne 'PSAD_ICMP_TYPES_FILE'
                        and $var ne 'PSAD_SIGS_FILE'
                        and $var ne 'PSAD_POSF_FILE') {
                    print CONF $orig_line;
                    $found = 1;
                    last;
                }
            }
            unless ($found) {
                print CONF $new_line;
            }
        } else {
            print CONF $new_line;
        }
    }
    close CONF;
    move "$prod_file.new", $prod_file or die "[*] ",
        "Could not move $prod_file.new -> $prod_file: $!";
    return;
}

sub append_fifo_syslog() {
    my $syslog_conf = shift;
    open RS, "< $syslog_conf" or
        die "[*] Unable to open $syslog_conf: $!\n";
    my @slines = <RS>;
    close RS;

    my $found_fifo = 0;
    for my $line (@slines) {
        $found_fifo = 1 if $line =~ /psadfifo/;
    }

    unless ($found_fifo) {
        &logr("[+] Modifying $syslog_conf to write kern.info " .
            "messages to\n");
        &logr("    $config{'PSAD_FIFO_FILE'}\n");
        unless (-e "$syslog_conf.orig") {
            copy $syslog_conf, "$syslog_conf.orig" or die "[*] Could ",
                "not copy $syslog_conf -> $syslog_conf.orig: $!";
        }
        &archive($syslog_conf);
        open SYSLOG, "> $syslog_conf" or
            die "[*] Unable to open $syslog_conf: $!";
        for my $line (@slines) {
            unless ($line =~ /psadfifo/) {
                print SYSLOG $line;
            }
        }
        print SYSLOG "\n### Send kern.info messages to psadfifo for ",
            "analysis by kmsgsd\n";
        ### reinstate kernel logging to our named pipe
        print SYSLOG "kern.info\t\t|$config{'PSAD_FIFO_FILE'}\n";
        close SYSLOG;
    }
    return;
}

sub test_syslog_config() {
    my $syslog_str = shift;
    my %used_ports;

    ### first find an unused high tcp port to use for testing
    my @netstat_out = `$cmds{'netstat'} -an`;

    for my $line (@netstat_out) {
        chomp $line;
        if ($line =~ m/^\s*tcp\s+\d+\s+\d+\s+\S+:(\d+)\s/) {
            ### $1 == protocol (tcp/udp), $2 == port number
            $used_ports{$1} = '';
        }
    }

    ### get the first unused high tcp port greater than 5000
    my $test_port = 5000;
    $test_port++ while defined $used_ports{$test_port};

    ### make sure the interface is actually up
    unless (&run_cmd("$cmds{'ifconfig'} lo up")) {
        &logr("[-] Could not bring up the loopback interface.\n" .
            "    Hoping the syslog reconfig will work anyway.\n");
        return 0;
    }

    ### make sure we can see the loopback interface with
    ### ifconfig
    my @if_out = `$cmds{'ifconfig'} lo`;

    unless (@if_out) {
        &logr("[-] Could not see the loopback interface with ifconfig.  " .
            "Hoping\n    syslog reconfig will work anyway.\n");
        return 0;
    }

    my $lo_ip = '127.0.0.1';
    my $found_ip = 0;
    for my $line (@if_out) {
        if ($line =~ /inet\s+addr:($ip_re)\s/) {
            $lo_ip = $1;  ### this should always be 127.0.0.1
            &logr("[-] loopback interface IP is not 127.0.0.1.  Continuing ".
                "anyway.\n") unless $lo_ip eq '127.0.0.1';
            $found_ip = 1;
        }
    }

    unless ($found_ip) {
        &logr("[-] The loopback interface does not have an IP.\n" .
            "    Hoping the syslog reconfig will work anyway.\n");
        return 0;
    }

    ### remove any "test_DROP" lines from fwdata file and ipt_prefix_ctr
    ### before seeing if new ones can be written
    &scrub_prefix_ctr();

    my $start_kmsgsd = 1;
    if (-e $config{'KMSGSD_PID_FILE'}) {
        open PID, "< $config{'KMSGSD_PID_FILE'}" or die "[*] Could not open ",
            "$config{'KMSGSD_PID_FILE'}: $!";
        my $pid = <PID>;
        close PID;
        chomp $pid;
        if (kill 0, $pid) {  ### kmsgsd is already running
            $start_kmsgsd = 0;
        }
    }
    if ($start_kmsgsd) {
        ### briefly start kmsgsd just long enough to test syslog
        ### with a packet to port 5000 (or higher).
        unless (&run_cmd("${USRSBIN_DIR}/kmsgsd") == 0) {
            &logr("[-] Could not start kmsgsd to test syslog.\n" .
                "    Send email to Michael Rash (mbr\@cipherdyne.org)\n");
            return 0;
        }
    }

    ### insert a rule to deny traffic to the loopback
    ### interface on $test_port
    &run_cmd("$cmds{'iptables'} -I INPUT 1 -i lo -p tcp --dport " .
        "$test_port -j LOG --log-prefix \"test_DROP \"");

    open FWDATA, "$config{'FW_DATA_FILE'}" or
        die "[*] Could not open $config{'FW_DATA_FILE'}: $!";

    seek FWDATA,0,2;  ### seek to the end of the file

    ### try to connect to $test_port to generate an iptables
    ### drop message.  Note that since nothing is listening on
    ### the port we will immediately receive a tcp reset.
    my $sock = new IO::Socket::INET(
        'PeerAddr' => $lo_ip,
        'PeerPort' => $test_port,
        'Proto'    => 'tcp',
        'Timeout'  => 1
    );
    undef $sock if defined $sock;

    ### sleep to give kmsgsd a chance to pick up the packet
    ### log message from syslog
    sleep 2;

    my $found = 0;

    my @pkts = <FWDATA>;
    close FWDATA;
    for my $pkt (@pkts) {
        $found = 1 if $pkt =~ /test_DROP/;
    }

    ### remove the testing firewall rule
    &run_cmd("$cmds{'iptables'} -D INPUT 1");

    ### remove the any new test_DROP lines we just created
    ### (this probably is not necessary because psad is not
    ### running).
    &scrub_prefix_ctr();

    if ($found) {
    } else {
    }

    if ($start_kmsgsd && -e $config{'KMSGSD_PID_FILE'}) {
        open PID, "$config{'KMSGSD_PID_FILE'}" or return 0;
        my $pid = <PID>;
        close PID;
        chomp $pid;
        kill 9, $pid if kill 0, $pid;
    }
    return $found;
}

sub scrub_prefix_ctr() {
    if (-e $config{'IPT_PREFIX_COUNTER_FILE'}) {
        open SCRUB, "< $config{'IPT_PREFIX_COUNTER_FILE'}" or
            die "[*] Could not open $config{'IPT_PREFIX_COUNTER_FILE'}: $!";
        my @lines = <SCRUB>;
        close SCRUB;

        open SCRUB, "> $config{'IPT_PREFIX_COUNTER_FILE'}" or
            die "[*] Could not open $config{'IPT_PREFIX_COUNTER_FILE'}: $!";
        for my $line (@lines) {
            print SCRUB $line unless $line =~ /test_DROP/;
        }
        close SCRUB;
    }
    return;
}

sub check_old_psad_installation() {

    return unless &is_root();

    my $old_install_dir = '/usr/local/bin';
    if (-e "${old_install_dir}/psad") {
        move "${old_install_dir}/psad", "${USRSBIN_DIR}/psad" or die "[*] ",
            "Could not move ${old_install_dir}/psad -> ",
            "${USRSBIN_DIR}/psad: $!";
    }
    if (-e "${old_install_dir}/psadwatchd") {
        move "${old_install_dir}/psadwatchd", "${USRSBIN_DIR}/psadwatchd"
            or die "[*] Could not move ${old_install_dir}/psadwatchd -> ",
            "${USRSBIN_DIR}/psadwatchd: $!";
    }
    if (-e "${old_install_dir}/kmsgsd") {
        move "${old_install_dir}/kmsgsd", "${USRSBIN_DIR}/kmsgsd" or die
            "[*] Could not move ${old_install_dir}/kmsgsd -> ",
            "${USRSBIN_DIR}/kmsgsd: $!";
    }
    if (-e "$config{'PSAD_CONF_DIR'}/psad_signatures.old") {
        unlink "$config{'PSAD_CONF_DIR'}/psad_signatures.old";
    }
    if (-e "$config{'PSAD_CONF_DIR'}/psad_auto_ips.old") {
        unlink "$config{'PSAD_CONF_DIR'}/psad_auto_ips.old";
    }
    if (-e "$config{'PSAD_CONF_DIR'}/psad.conf.old") {
        unlink "$config{'PSAD_CONF_DIR'}/psad.conf.old";
    }
    if (-e '/var/log/psadfifo') {  ### this is the old psadfifo location
        unlink '/var/log/psadfifo';
    }
    return;
}

sub get_distro() {
    return 'gentoo' if -e '/etc/gentoo-release';
    if (-e '/etc/issue') {
        ### Red Hat Linux release 6.2 (Zoot)
        open ISSUE, '< /etc/issue' or
            die "[*] Could not open /etc/issue: $!";
        my @lines = <ISSUE>;
        close ISSUE;
        for my $line (@lines) {
            chomp $line;
            return 'redhat' if $line =~ /red\s*hat/i;
            return 'fedora' if $line =~ /fedora/i;
            return 'ubuntu' if $line =~ /ubuntu/i;
        }
    }
    return 'NA';
}

sub perms_ownership() {
    my ($file, $perm_value) = @_;

    chmod $perm_value, $file or die "[*] Could not ",
        "chmod($perm_value, $file): $!";

    return unless &is_root();

    ### root (maybe should take the group assignment out)
    chown 0, 0, $file or die "[*] Could not chown 0,0,$file: $!";

    return;
}

sub get_fw_search_strings() {
    my @fw_search_strings = ();

        print
"\n[+] By default, psad parses all iptables log messages for scan activity.\n",
"    However, psad can be configured to only parse those iptables messages\n",
"    that match particular strings (that are specified in your iptables\n",
"    ruleset with the --log-prefix option).\n";

    if (&query_yes_no("\n    Would you like psad to only parse " .
            "specific strings in iptables\n    messages (y/[n])?  ",
            $ACCEPT_NO_DEFAULT)) {


        ### we are only searching for specific iptables log prefixes
        &put_var('FW_SEARCH_ALL', 'N',
            "$config{'PSAD_CONF_DIR'}/psad.conf");

    my $str =
"\n    psad checks the firewall configuration on the underlying machine\n" .
"    to see if packets will be logged and dropped that have not\n" .
"    explicitly allowed through.  By default, psad looks for the string\n" .
"    \"DROP\". However, if your particular firewall configuration logs\n" .
"    blocked packets with the string \"Audit\" for example, psad can be\n" .
"    configured here to look for this string.  In addition, psad can also\n" .
"    be configured here to look for multiple strings if needed.  Remember,\n" .
"    whatever string you configure psad to look for must be logged via the\n" .
"    --log-prefix option in iptables.\n\n";
        &logr($str);
        &logr("    Add as many search strings as you like; " .
            "each on its own line.\n\n");
        &logr("    End with a \".\" on a line by itself.\n\n");
        my $ans_file_str = 'FW search strings:';
        if ($use_answers and defined $answers{$ans_file_str}) {
            @fw_search_strings = split /\s*,\s*/, $answers{$ans_file_str};
            print "$answers{$ans_file_str}\n";
        } else {
            my $ans = '';
            my $str = '';
            while ($ans !~ /^\s*\.\s*$/) {
                &logr("    Enter string (i.e. \"Audit\"):  ");
                $ans = <STDIN>;
                chomp $ans;
                if ($ans =~ /\"/) {
                    &logr("[-] Quotes will be removed from FW search string: $ans\n");
                    $ans =~ s/\"//g;
                }
                if ($ans =~ /\S/) {
                    if ($ans !~ /^\s*\.\s*$/) {
                        $str .= "$ans, ";
                        push @fw_search_strings, $ans;
                    }
                } else {
                    &logr("[-] Invalid string\n");
                }
            }
            $str =~ s/\,\s*$//;
            &put_answer_file_value($ans_file_str, $str);
        }
        &logr("\n    All firewall search strings used by psad are located " .
            "in the psad config file:\n    $config{'PSAD_CONF_DIR'}/psad.conf\n");
    }
    return \@fw_search_strings;
}

sub query_dshield() {
    my $str =
"\n[+] psad has the capability of sending scan data via email alerts to the\n" .
"    DShield distributed intrusion detection system (www.dshield.org).  By\n" .
"    default this feature is not enabled since firewall log data is sensitive,\n" .
"    but submitting logs to DShield provides a valuable service and assists\n" .
"    in generally enhancing internet security.  As an optional step, if you\n" .
"    have a DShield user id you can edit the \"DSHIELD_USER_ID\" variable\n" .
"    in $config{'PSAD_CONF_DIR'}/psad.conf\n\n";
    &logr($str);
    return &query_yes_no('    Would you like to enable DShield alerts (y/[n])?  ',
            $ACCEPT_NO_DEFAULT);
}

sub query_email() {
    my $email_str = '';
    open F, "< $config{'PSAD_CONF_DIR'}/psad.conf" or die "[*] Could not open ",
        "$config{'PSAD_CONF_DIR'}/psad.conf: $!";
    my @clines = <F>;
    close F;
    my $email_addresses;
    for my $line (@clines) {
        chomp $line;
        if ($line =~ /^\s*EMAIL_ADDRESSES\s+(.+);/) {
            $email_addresses = $1;
            last;
        }
    }
    unless ($email_addresses) {
        return '';
    }
    &logr("[+] psad alerts will be sent to:\n\n");
    &logr("       $email_addresses\n\n");

    if (&query_yes_no("[+] Would you like alerts sent to a different " .
                "address ([y]/n)?  ", $ACCEPT_YES_DEFAULT)) {
        print "\n";
        &logr("[+] To which email address(es) would you like " .
            "psad alerts to be sent?\n");
        &logr("    You can enter as many email addresses as you like; " .
            "each on its own line.\n\n");
        &logr("    End with a \".\" on a line by itself.\n\n");

        my $ans_file_str = 'Email addresses:';

        if ($use_answers and defined $answers{$ans_file_str}) {
            $email_str = $answers{$ans_file_str};
            print "$answers{$ans_file_str}\n";
        } else {
            my $ans = '';
            while ($ans !~ /^\s*\.\s*$/) {
                &logr("    Email Address: ");
                $ans = <STDIN>;
                chomp $ans;
                if ($ans =~ m|^\s*(\S+\@\S+)$|) {
                    $email_str .= "$1, ";
                } elsif ($ans !~ /^\s*\.\s*$/) {
                    &logr("[-] Invalid email address \"$ans\"\n");
                }
            }
            $email_str =~ s/\,\s*$//;
            &put_answer_file_value($ans_file_str, $email_str);
        }
    }
    return $email_str;
}

sub query_syslog() {
    &logr("\n[+] psad supports the syslogd, rsyslogd, syslog-ng, ulogd, and\n" .
        "    metalog logging daemons.  Which system logger is running?\n\n");

    my $ans = '';
    my $ans_file_str = 'System logger:';

    if ($use_answers and defined $answers{$ans_file_str}) {
        $ans = $answers{$ans_file_str};
        print "$answers{$ans_file_str}\n";
    } else {
        while ($ans ne 'syslogd' and $ans ne 'rsyslogd' and
                $ans ne 'syslog-ng' and $ans ne 'ulogd' and $ans ne 'metalog') {
            &logr("    syslogd / rsyslogd / syslog-ng / ulogd / metalog? [syslogd] ");
            $ans = <STDIN>;
            if ($ans eq "\n") {  ### allow default to take over
                $ans = 'syslogd';
            }
            $ans =~ s/\s*//g;

            if ($ans eq 'syslogd') {
                ### allow command line --syslog-conf arg to take over
                $syslog_conf = '/etc/syslog.conf' unless $syslog_conf;
            } elsif ($ans eq 'rsyslogd') {
                ### allow command line --syslog-conf arg to take over
                $syslog_conf = '/etc/rsyslog.conf' unless $syslog_conf;
            } elsif ($ans eq 'syslog-ng') {
                ### allow command line --syslog-conf arg to take over
                $syslog_conf = '/etc/syslog-ng/syslog-ng.conf' unless $syslog_conf;
            } elsif ($ans eq 'metalog') {
                ### allow command line --syslog-conf arg to take over
                $syslog_conf = '/etc/metalog/metalog.conf' unless $syslog_conf;
            }
            if ($ans ne 'ulogd' and $syslog_conf and not -e $syslog_conf) {
                if (-e '/etc/rsyslog.conf') {
                    warn "[-] It looks like /etc/rsyslog.conf exists, ",
                        "did you mean rsyslog?\n";
                }
                die
    "[*] The config file $syslog_conf does not exist. Re-run install.pl\n",
    "    with the --syslog-conf argument to specify the path to the syslog\n",
    "    daemon config file.";
            }
        }
        die "[-] Invalid syslog daemon \"$ans\""
            unless ($ans and
                ($ans eq 'syslogd'
                or $ans eq 'rsyslogd'
                or $ans eq 'syslog-ng'
                or $ans eq 'ulogd'
                or $ans eq 'metalog'));
        print "\n";
        &put_answer_file_value($ans_file_str, $ans);
    }
    return $ans;
}

sub put_answer_file_value() {
    my ($answer_str, $value) = @_;

    return if $no_write_answers;

    my @lines = ();

    if (-e $answers_file) {
        open F, "< $answers_file" or die "[*] Could not open $answers_file: $!";
        @lines = <F>;
        close F;
    }

    my $found_str = 0;
    open F, "> $answers_file" or die "[*] Could not open $answers_file: $!";
    for my $line (@lines) {
        if ($line =~ /^$answer_str\s+.*;/) {
            print F "$answer_str        $value;\n";
            $found_str = 1;
        } else {
            print F $line;
        }
    }
    unless ($found_str) {
        print F "$answer_str        $value;\n";
    }
    close F;
    return;
}

sub put_var() {
    my ($var, $value, $file) = @_;

    open RF, "< $file" or die "[*] Could not open $file: $!";
    my @lines = <RF>;
    close RF;
    open F, "> $file" or die "[*] Could not open $file: $!";
    for my $line (@lines) {
        if ($line =~ /^\s*$var\s+.*;/) {
            printf F "%-28s%s;\n", $var, $value;
        } else {
            print F $line;
        }
    }
    close F;
    return;
}

sub archive() {
    my $file = shift;
    my $curr_pwd = cwd() or die $!;
    chdir $config{'CONF_ARCHIVE_DIR'} or die $!;
    my ($filename) = ($file =~ m|.*/(.*)|);
    my $base = "${filename}.old";
    for (my $i = 5; $i > 1; $i--) {  ### keep five copies of old config files
        my $j = $i - 1;
        unlink "${base}${i}.gz" if -e "${base}${i}.gz";
        if (-e "${base}${j}.gz") {
            move "${base}${j}.gz", "${base}${i}.gz" or die "[*] Could not ",
                "move ${base}${j}.gz -> ${base}${i}.gz: $!";
        }
    }
    &logr("[+] Archiving $file -> $config{'CONF_ARCHIVE_DIR'}/${base}1.gz\n");
    unlink "${base}1.gz" if -e "${base}1.gz";

    ### move $file into the archive directory
    copy $file, "${base}1" or die "[*] Could not copy ",
        "$file -> ${base}1: $!";
    &run_cmd("$cmds{'gzip'} ${base}1");
    chdir $curr_pwd or die $!;
    $archived_old = 1;
    return;
}

sub enable_psad_at_boot() {
    my $distro = shift;

    return unless &is_root();

    unless (&query_yes_no("[+] Enable psad at boot time ([y]/n)?  ",
                $ACCEPT_YES_DEFAULT)) {
        return;
    }

    if ($is_systemd) {
        &run_cmd("$cmds{'systemctl'} enable psad");
    } else {
        if ($distro eq 'redhat' or $distro eq 'fedora') {
            &run_cmd("$cmds{'chkconfig'} --add $init_name");
        } elsif ($distro eq 'gentoo') {
            &run_cmd("$cmds{'rc-update'} add $init_name default");
        } elsif ($distro eq 'ubuntu') {
            &run_cmd("$cmds{'update-rc.d'} $init_name defaults");
        } else {

            ### get the current run level
            &get_runlevel();

            if ($runlevel) {
                if (-d '/etc/rc.d' and -d "/etc/rc.d/rc${runlevel}.d") {
                    unless (-e "/etc/rc.d/rc${runlevel}.d/S99$init_name") {
                        symlink "$init_dir/$init_name",
                            "/etc/rc.d/rc${runlevel}.d/S99$init_name";
                    }
                } else {
                    print "[-] The /etc/rc.d/rc${runlevel}.d directory does ",
                        "exist, not sure how to enable psad at boot time.";
                }
            }
        }
    }
    return;
}

### check paths to commands and attempt to correct if any are wrong.
sub check_commands() {

    CMD: for my $cmd (keys %cmds) {
        next CMD if defined $exclude_cmds{$cmd};
        unless (-x $cmds{$cmd}) {
            my $found = 0;
            PATH: for my $dir (@cmd_search_paths) {
                if (-x "${dir}/${cmd}") {
                    $cmds{$cmd} = "${dir}/${cmd}";
                    $found = 1;
                    last PATH;
                }
            }
            unless ($found) {
                if ($cmd eq 'runlevel') {
                    if ($runlevel > 0) {
                        next CMD;
                    } else {
                        die "[*] Could not find the $cmd command, ",
                            "use --runlevel <N>";
                    }
                }
                die "\n[*] Could not find $cmd anywhere!!!  ",
                    "Please edit the config section to include the path to ",
                    "$cmd.";
            }
        }
        unless (-x $cmds{$cmd}) {
            return unless &is_root();
            die "\n[*] $cmd is located at ",
                "$cmds{$cmd} but is not executable by uid: $<";
        }
    }
    return;
}

sub is_root() {
    return 1 if $< == 0 and $> == 0;
    return 0;
}

sub install_manpage() {
    my $manpage = shift;

    my $name    = '';
    my $section = '';

    if ($manpage =~ m|(\w+)\.(\d)|) {
        $name = $1;
        $section = $2;
    } else {
        die "[*] Improper man page name, should be \"pagename.section\"";
    }

    ### remove old man page
    if (&is_root()) {
        unlink "/usr/local/man/man$section/${manpage}" if
            -e "/usr/local/man/man$section/${manpage}";
    }

    ### default location to put the psad man page, but check with
    ### /etc/man.config
    my $mpath = "/usr/share/man/man$section";
    if (-e '/etc/man.config') {
        ### prefer to install $manpage in /usr/local/man/man8 if
        ### this directory is configured in /etc/man.config
        open M, '< /etc/man.config' or
            die "[*] Could not open /etc/man.config: $!";
        my @lines = <M>;
        close M;
        ### prefer the path "/usr/share/man"
        my $found = 0;
        for my $line (@lines) {
            chomp $line;
            if ($line =~ m|^MANPATH\s+/usr/share/man|) {
                $found = 1;
                last;
            }
        }
        ### try to find "/usr/local/man" if we didn't find /usr/share/man
        unless ($found) {
            for my $line (@lines) {
                chomp $line;
                if ($line =~ m|^MANPATH\s+/usr/local/man|) {
                    $mpath = "/usr/local/man/man$section";
                    $found = 1;
                    last;
                }
            }
        }
        ### if we still have not found one of the above man paths,
        ### just select the first one out of /etc/man.config
        unless ($found) {
            for my $line (@lines) {
                chomp $line;
                if ($line =~ m|^MANPATH\s+(\S+)|) {
                    $mpath = $1;
                    last;
                }
            }
        }
    }

    if ($install_root ne '/') {
        $mpath = $config{'INSTALL_ROOT'} . $mpath;
    }

    &full_mkdir($mpath, 0755);
    my $mfile = "${mpath}/${manpage}";
    &logr("[+] Installing $manpage man page at $mfile\n");
    copy "doc/$manpage", $mfile or die "[*] Could not copy doc/$manpage to ",
        "$mfile: $!";
    &perms_ownership($mfile, 0644);
    &logr("[+] Compressing manpage $mfile\n");
    ### remove the old one so gzip doesn't prompt us
    unlink "${mfile}.gz" if -e "${mfile}.gz";
    &run_cmd("$cmds{'gzip'} $mfile");
    return;
}

sub full_mkdir() {
    my ($dir, $perms) = @_;

    my @dirs = split /\//, $dir;
    my $path = $dirs[0];
    shift @dirs;
    for my $d (@dirs) {
        next unless $d and $d =~ /\S/;
        $path .= "/$d";
        unless (-d $path) {
            printf "[+] mkdir $path, %o\n", $perms;
            mkdir $path, $perms or die "[*] Could not mkdir($path): $!";
        }
    }
    return;
}

sub has_perl_module() {
    my $module = shift;

    # 5.8.0 has a bug with require Foo::Bar alone in an eval, so an
    # extra statement is a workaround.
    my $file = "$module.pm";
    $file =~ s{::}{/}g;
    eval { require $file };

    return $@ ? 0 : 1;
}

sub update_command_paths() {
    my $file = shift;

    open F, "< $file" or die "[*] Could not open file: $!";
    my @lines = <F>;
    close F;

    my @newlines = ();
    my $new_cmd = 0;
    for my $line (@lines) {
        my $found = 0;
        if ($line =~ /^\s*(\w+)Cmd(\s+)(\S+);/) {
            my $cmd    = $1;
            my $spaces = $2;
            my $path   = $3;
            if ($path =~ /\$INSTALL_ROOT/) {
                $path =~ s|\$INSTALL_ROOT|$install_root|;
            }
            unless (-e $path and -x $path) {
                ### the command is not at this path, try to find it
                my $cmd_minor_name = $cmd;
                if ($path =~ m|.*/(\S+)|) {
                    $cmd_minor_name = $cmd if $cmd ne $1;
                }
                DIR: for my $dir (@cmd_search_paths) {
                    if (-e "$dir/$cmd_minor_name"
                            and -x "$dir/$cmd_minor_name") {
                        ### found the command
                        push @newlines,
                            "${cmd}Cmd${spaces}${dir}/${cmd_minor_name};\n";
                        $found   = 1;
                        $new_cmd = 1;
                        last DIR;
                    }
                }
                unless ($found) {
                    &logr("[-] Could not find the path to the $cmd command, " .
                        "you will need to manually\n    edit the path for " .
                        "the ${cmd}Cmd variable in $file\n");
                }
            }
        }
        unless ($found) {
            push @newlines, $line;
        }
    }
    if ($new_cmd) {
        open C, "> $file" or die "[*] Could not open file: $!";
        print C for @newlines;
        close C;
    }
    return;
}

sub get_runlevel() {
    die "[*] The runlevel cannot be greater than 6"
        if $runlevel > 6;

    return if $runlevel > 0;

    open RUN, "$cmds{'runlevel'} |" or die "[*] Could not execute the runlevel ",
        "command, use --runlevel <N>";
    while (<RUN>) {
        if (/^\s*\S+\s+(\d+)/) {
            $runlevel = $1;
            last;
        }
    }
    close RUN;
    return;
}


### logging subroutine that handles multiple filehandles
sub logr() {
    my $msg = shift;

    print STDOUT $msg;
    push @installation_lines, $msg;

    return;
}

sub usage() {
    my $exitcode = shift;
    print <<_HELP_;

Usage: install.pl [options]

    -u,  --uninstall             - Uninstall psad.
    -f, --force-mod-install      - Force all perl modules to be installed
                                   even if some already exist in the system
                                   /usr/lib/perl5 tree.
    -F, --Force-mod-regex <re>   - Specify a regex to match a module name
                                   and force the installation of such
                                   modules.
    -E, --Exclude-mod-regex <re> - Exclude a perl module that matches this
                                   regular expression.
    -p, --path-update            - Run path update code regardless of whether
                                   a previous config is being merged.
    -S, --Skip-mod-install       - Do not install any perl modules.
    -s, --syslog-conf <file>     - Specify path to syslog.conf file.
    -c, --config <file>          - Specify alternate path to psad.conf from
                                   which default installation paths are
                                   derived.
    --init-dir <path>            - Specify path to the init directory (the
                                   default is $init_dir).
    --systemd-init-dir <path>    - Specify path to the systemd init directory
                                   (the default is $systemd_init_dir).
    --init-name <name>           - Specify the name for the psad init
                                   script (the default is $init_name).
    --systemd-init-name <name>   - Specify the name for the systemd psad init
                                   file (the default is $systemd_init_name).
    --install-syslog-fifo        - Add the installation of the psadfifo
                                   (this is not usually necessary since
                                   the default is to enable
                                   ENABLE_SYSLOG_FILE).
    --install-root <dir>         - Install psad at a custom path (analogous
                                   to './configure --prefix=/dir').
    --install-test-dir           - Install psad in test/psad-install for
                                   test suite.
    -U, --Use-answers            - Apply answers to installation queries
                                   from the file $answers_file.
    -a, --answers-file <file>    - Specify path to the answers file.
    --no-write-answers           - By default the install.pl script
                                   records installation query answers to
                                   the file $answers_file, but this option
                                   disables this behavior.
    -r, --runlevel <N>           - Specify the current system runlevel.
    --no-rm-lib-dir              - Do not remove the /usr/lib/psad/
                                   directory before installing psad.
    --no-syslog-test             - Skip syslog reconfiguration test.
    --no-preserve                - Disable preservation of old configs.
    -L, --LANG <locale>          - Specify LANG env variable (actually the
                                   LC_ALL variable).
    -n, --no-LANG                - Do not export the LANG env variable.
    -h  --help                   - Prints this help message.

_HELP_
    exit $exitcode;
}
