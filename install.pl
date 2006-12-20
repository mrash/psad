#!/usr/bin/perl -w
#
#########################################################################
#
# File: install.pl
#
# Purpose:  install.pl is the installation script for psad.  It is safe
#           to execute install.pl even if psad has already been installed
#           on a system since install.pl will preserve the existing
#           config section within the new script.
#
# Credits:  (see the CREDITS file)
#
# Copyright (C) 1999-2006 Michael Rash (mbr@cipherdyne.org)
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
# $Id$
#

use Cwd;
use File::Path;
use File::Copy;
use Sys::Hostname;
use IO::Socket;
use Getopt::Long;
use strict;

### Note that Psad.pm is not included within the above list (installation
### over existing psad should not make use of an old Psad.pm).

### These three variables should not really be changed unless
### you're really sure.
my $PSAD_DIR     = '/var/log/psad';
my $PSAD_CONFDIR = '/etc/psad';
my $VARLIBDIR    = '/var/lib/psad';
my $RUNDIR       = '/var/run/psad';
my $LIBDIR       = '/usr/lib/psad';
my $LIBDIR64     = '/usr/lib64/psad';

#============== config ===============
my $INSTALL_LOG  = "${PSAD_DIR}/install.log";
my $PSAD_FIFO    = "${VARLIBDIR}/psadfifo";
my $INIT_DIR     = '/etc/init.d';
my $USRSBIN_DIR  = '/usr/sbin';  ### consistent with FHS (Filesystem
                                 ### Hierarchy Standard)
my $USRBIN_DIR   = '/usr/bin';  ### consistent with FHS (Filesystem
my $CONF_ARCHIVE = "${PSAD_CONFDIR}/archive";
my @LOGR_FILES   = (*STDOUT, $INSTALL_LOG);
my $RUNLEVEL;    ### This should only be set if install.pl
                 ### cannot determine the correct runlevel
my $WHOIS_PSAD   = "${USRBIN_DIR}/whois_psad";

my $SIG_UPDATE_URL  = 'http://www.cipherdyne.org/psad/signatures';

### directory in which to install snort rules
my $SNORT_DIR    = "${PSAD_CONFDIR}/snort_rules";

### system binaries ###
my $chkconfigCmd = '/sbin/chkconfig';
my $rcupdateCmd  = '/sbin/rc-update';  ### Gentoo
my $gzipCmd      = '/usr/bin/gzip';
my $psCmd        = '/bin/ps';
my $netstatCmd   = '/bin/netstat';
my $ifconfigCmd  = '/sbin/ifconfig';
my $mknodCmd     = '/bin/mknod';
my $makeCmd      = '/usr/bin/make';
my $killallCmd   = '/usr/bin/killall';
my $perlCmd      = '/usr/bin/perl';
my $wgetCmd      = '/usr/bin/wget';
my $iptablesCmd  = '/sbin/iptables';
my $psadCmd      = "${USRSBIN_DIR}/psad";
#============ end config ============

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
    'Date::Calc', => {
        'force-install' => 0,
        'mod-dir' => 'Date-Calc'
    },
    'Net::IPv4Addr' => {
        'force-install' => 0,
        'mod-dir' => 'Net-IPv4Addr'
    },
    'IPTables::Parse' => {
        'force-install' => 1,
        'mod-dir' => 'IPTables-Parse'
    },
    'IPTables::ChainMgr' => {
        'force-install' => 1,
        'mod-dir' => 'IPTables-ChainMgr'
    },
    'Psad' => {
        'force-install' => 1,
        'mod-dir' => 'Psad'
    }
);

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

### used to preserve old FW_MSG_SEARCH vars from previous
### psad installation.  This is only needed when upgrading
### to a newer version of psad that uses the fw_search.conf
### file from a previous version that doesn't.
my @old_fw_msg_search;

### get the hostname of the system
my $HOSTNAME = hostname();

my $src_dir = getcwd() or die "[*] Could not get current working directory.";

if (-e $INSTALL_LOG) {
    open INSTALL, "> $INSTALL_LOG" or
        die "[*] Could not open $INSTALL_LOG: $!";
    close INSTALL;
}

### scope these vars
my $PERL_INSTALL_DIR;  ### This is used to find pre-0.9.2 installations of psad

### for user answers
my $ACCEPT_YES_DEFAULT = 1;
my $ACCEPT_NO_DEFAULT  = 2;
my $NO_ANS_DEFAULT     = 0;

### set the install directory for the Psad.pm module
my $found = 0;
for my $dir (@INC) {
    if ($dir =~ /site_perl\/\d\S+/) {
        $PERL_INSTALL_DIR = $dir;
        $found = 1;
        last;
    }
}
unless ($found) {
    $PERL_INSTALL_DIR = $INC[0];
}

### set the default execution flags and command line args
my $noarchive   = 0;
my $uninstall   = 0;
my $help        = 0;
my $archived_old = 0;
my $skip_syslog_test = 0;
my $skip_module_install   = 0;
my $cmdline_force_install = 0;
my $force_path_update = 0;
my $force_mod_re = '';
my $exclude_mod_re = '';
my $no_rm_old_lib_dir = 0;
my $syslog_conf = '';

### make Getopts case sensitive
Getopt::Long::Configure('no_ignore_case');

&usage(1) unless (GetOptions(
    'force-mod-install' => \$cmdline_force_install,  ### force install of all modules
    'Force-mod-regex=s' => \$force_mod_re,  ### force specific mod install with regex
    'Exclude-mod-regex=s' => \$exclude_mod_re, ### exclude a particular perl module
    'path-update'       => \$force_path_update, ### update command paths
    'Skip-mod-install'  => \$skip_module_install,
    'no-rm-lib-dir'     => \$no_rm_old_lib_dir, ### remove any old /usr/lib/psad dir
    'no-preserve'       => \$noarchive,   ### Don't preserve existing configs.
    'syslog-conf=s'     => \$syslog_conf, ### specify path to syslog config file.
    'no-syslog-test'    => \$skip_syslog_test,
    'uninstall'         => \$uninstall,   ### Uninstall psad.
    'help'              => \$help         ### Display help.
));
&usage(0) if $help;

$force_mod_re = qr|$force_mod_re| if $force_mod_re;
$exclude_mod_re = qr|$exclude_mod_re| if $exclude_mod_re;

my %Cmds = (
    'gzip'     => $gzipCmd,
    'ps'       => $psCmd,
    'mknod'    => $mknodCmd,
    'netstat'  => $netstatCmd,
    'ifconfig' => $ifconfigCmd,
    'make'     => $makeCmd,
    'killall'  => $killallCmd,
    'perl'     => $perlCmd,
    'iptables' => $iptablesCmd,
);

my $distro = &get_distro();

if ($distro eq 'redhat' or $distro eq 'fedora') {
    ### add chkconfig only if we are runing on a redhat distro
    $Cmds{'chkconfig'} = $chkconfigCmd;
} elsif ($distro eq 'gentoo') {
    ### add rc-update if we are running on a gentoo distro
    $Cmds{'rc-update'} = $rcupdateCmd;
}

my $init_dir = '';

if (-d $INIT_DIR) {
    $init_dir = $INIT_DIR;
} elsif (-d '/etc/rc.d/init.d') {
    $init_dir = '/etc/rc.d/init.d';
} elsif (-d '/etc/rc.d') {  ### for Slackware
    $init_dir = '/etc/rc.d';
} else {
    die "[*] Cannot find the init script directory, edit ",
        "the \$INIT_DIR variable.\n";
}

### need to make sure this exists before attempting to
### write anything to the install log.
mkdir $PSAD_DIR, 0500 unless -d $PSAD_DIR;

### make sure the system binaries are where we expect
### them to be.
&check_commands();

$Cmds{'psad'} = $psadCmd;

### check to make sure we are running as root
$< == 0 && $> == 0 or die "You need to be root (or equivalent UID 0",
    " account) to install/uninstall psad!\n";

### occasionally things from old psad installations need to be
### dealt with separately.
&check_old_psad_installation();

if ($uninstall) {
    &uninstall();
} else {
    &install();
}
exit 0;
#================= end main =================

sub install() {

    ### make sure install.pl is being called from the source directory
    unless (-e 'psad' and -e 'Psad/lib/Psad.pm') {
        die "[*] install.pl can only be executed from the directory\n",
            "    that contains the psad sources!  Exiting.";
    }
    &logr('[+] ' . localtime() . " Installing psad on hostname: $HOSTNAME\n");

    ### make sure another psad process is not running
    if (&ask_to_stop_psad()) {
        &stop_psad();
    }

    unless (-d $RUNDIR) {
        &logr("[+] Creating $RUNDIR\n");
        mkdir $RUNDIR, 0500;
    }
    unless (-d $VARLIBDIR) {
        &logr("[+] Creating $VARLIBDIR\n");
        mkdir $VARLIBDIR, 0500;
    }

    ### deal with old psad_auto_ips path
    if (-e "${PSAD_CONFDIR}/psad_auto_ips") {
        move "${PSAD_CONFDIR}/psad_auto_ips",
            "${PSAD_CONFDIR}/auto_dl" or die "[*] Could not move ",
            "${PSAD_CONFDIR}/psad_auto_ips -> ${PSAD_CONFDIR}/auto_dl: $!";
    }
    ### deal with old psad_signatures path
    if (-e "${PSAD_CONFDIR}/psad_signatures") {
        move "${PSAD_CONFDIR}/psad_signatures",
            "${PSAD_CONFDIR}/signatures" or die "[*] Could not move ",
            "${PSAD_CONFDIR}/psad_signatures -> ${PSAD_CONFDIR}/signatures: $!";
    }
    ### deal with old psad_posf path
    if (-e "${PSAD_CONFDIR}/psad_posf") {
        move "${PSAD_CONFDIR}/psad_posf",
            "${PSAD_CONFDIR}/posf" or die "[*] Could not move ",
            "${PSAD_CONFDIR}/psad_posf -> ${PSAD_CONFDIR}/posf: $!";
    }
    ### deal with old psad_icmp_types path
    if (-e "${PSAD_CONFDIR}/psad_icmp_types") {
        move "${PSAD_CONFDIR}/psad_icmp_types",
            "${PSAD_CONFDIR}/icmp_types" or die "[*] Could not move ",
            "${PSAD_CONFDIR}/psad_icmp_types -> ${PSAD_CONFDIR}/icmp_types: $!";
    }

    ### change any existing psad module directory to allow anyone to import
    for my $dir ($LIBDIR, $LIBDIR64) {
        if (-d $dir) {
            chmod 0755, $dir;
            unless ($no_rm_old_lib_dir) {
                &logr("[+] Removing $dir/ directory from previous " .
                    "psad installation.\n");
                rmtree $dir;
            }
        }
    }
    unless (-d $PSAD_CONFDIR) {
        &logr("[+] Creating $PSAD_CONFDIR\n");
        mkdir $PSAD_CONFDIR, 0500;
    }
    unless (-d $CONF_ARCHIVE) {
        &logr("[+] Creating $CONF_ARCHIVE\n");
        mkdir $CONF_ARCHIVE, 0500;
    }
    unless (-e $PSAD_FIFO) {
        &logr("[+] Creating named pipe $PSAD_FIFO\n");
        unless (((system "$Cmds{'mknod'} -m 600 $PSAD_FIFO p")>>8) == 0) {
            &logr("[*] Could not create the named pipe \"$PSAD_FIFO\"!\n" .
                "[*] psad requires this file to exist!  Aborting install.\n");
            die;
        }
        unless (-p $PSAD_FIFO) {
            &logr("[*] Could not create the named pipe \"$PSAD_FIFO\"!\n" .
                "[*] psad requires this file to exist!  Aborting " .
                "install.\n");
            die;
        }
    }

    unless (-d $PSAD_DIR) {
        &logr("[+] Creating $PSAD_DIR\n");
        mkdir $PSAD_DIR, 0500;
    }
    unless (-e "${PSAD_DIR}/fwdata") {
        &logr("[+] Creating ${PSAD_DIR}/fwdata file\n");
        open F, "> ${PSAD_DIR}/fwdata" or die "[*] Could not open ",
            "${PSAD_DIR}/fwdata: $!";
        close F;
        chmod 0600, "${PSAD_DIR}/fwdata";
        &perms_ownership("${PSAD_DIR}/fwdata", 0600);
    }

    unless (-d $USRSBIN_DIR) {
        &logr("[+] Creating $USRSBIN_DIR\n");
        mkdir $USRSBIN_DIR,0755;
    }
    if (-d 'whois') {
        &logr("[+] Compiling Marco d'Itri's whois client\n");
        system "$Cmds{'make'} -C whois";
        if (-e 'whois/whois') {
            &logr("[+] Copying whois binary to $WHOIS_PSAD\n");
            copy "whois/whois", $WHOIS_PSAD or die "[*] Could not copy ",
                "whois/whois -> $WHOIS_PSAD: $!";
        } else {
            die "[*] Could not compile whois";
        }
    }
    &perms_ownership($WHOIS_PSAD, 0755);
    print "\n\n";

    ### install perl modules
    unless ($skip_module_install) {
        for my $module (keys %required_perl_modules) {
            &install_perl_module($module);
        }
    }

    &logr("[+] Installing Snort-2.3.3 signatures in $SNORT_DIR\n");
    unless (-d $SNORT_DIR) {
        mkdir $SNORT_DIR, 0500 or die "[*] Could not create $SNORT_DIR: $!";
    }
    opendir D, 'snort_rules' or die "[*] Could not open ",
        "the snort_rules directory: $!";
    my @files = readdir D;
    closedir D;

    for my $file (@files) {
        next unless $file =~ /\.rules$/ or $file =~ /\.config$/;
        &logr("[+] Installing snort_rules/${file}\n");
        copy "snort_rules/${file}", "${SNORT_DIR}/${file}" or
            die "[*] Could not copy snort_rules/${file} -> ",
                "${SNORT_DIR}/${file}: $!";
        &perms_ownership("${SNORT_DIR}/${file}", 0600);
    }
    print "\n\n";

    &logr("[+] Compiling kmsgsd, and psadwatchd:\n");

    ### remove any previously compiled kmsgsd
    unlink 'kmsgsd' if -e 'kmsgsd';

    ### remove any previously compiled psadwatchd
    unlink 'psadwatchd' if -e 'psadwatchd';

    ### compile the C psad daemons
    system $Cmds{'make'};
    if (! -e 'kmsgsd' && -e 'kmsgsd.pl') {
        &logr("[-] Could not compile kmsgsd.c.  Installing perl kmsgsd.\n");
        unless (((system "$Cmds{'perl'} -c kmsgsd.pl")>>8) == 0) {
            die "[*] kmsgsd.pl does not compile with \"perl -c\".  ",
                "Download the latest sources " .
                "from:\n\nhttp://www.cipherdyne.org/\n";
        }
        copy 'kmsgsd.pl', 'kmsgsd' or die "[*] Could not copy ",
            "kmsgsd.pl -> kmsgsd: $!";
    }
    if (! -e 'psadwatchd' && -e 'psadwatchd.pl') {
        &logr("[-] Could not compile psadwatchd.c.  " .
            "Installing perl psadwatchd.\n");
        unless (((system "$Cmds{'perl'} -c psadwatchd.pl")>>8) == 0) {
            die "[*] psadwatchd.pl does not compile with \"perl -c\".  ",
                "Download the latest sources " .
                "from:\n\nhttp://www.cipherdyne.org/\n";
        }
        copy 'psadwatchd.pl', 'psadwatchd' or die "[*] Could not copy ",
            "psadwatchd.pl -> psadwatchd: $!";
    }

    ### install fwcheck_psad.pl
    print "\n\n";
    &logr("[+] Verifying compilation of fwcheck_psad.pl script:\n");
    unless (((system "$Cmds{'perl'} -c fwcheck_psad.pl")>>8) == 0) {
        die "[*] fwcheck_psad.pl does not compile with \"perl -c\".  Download ",
            "the latest sources from:\n\nhttp://www.cipherdyne.org/\n";
    }

    ### make sure the psad (perl) daemon compiles.  The other three
    ### daemons have all been re-written in C.
    &logr("[+] Verifying compilation of psad perl daemon:\n");
    unless (((system "$Cmds{'perl'} -c psad")>>8) == 0) {
        die "[*] psad does not compile with \"perl -c\".  Download the",
            " latest sources from:\n\nhttp://www.cipherdyne.org/\n";
    }
    print "\n\n";

    ### install nf2csv
    print "\n\n";
    &logr("[+] Verifying compilation of nf2csv script:\n");
    unless (((system "$Cmds{'perl'} -c nf2csv")>>8) == 0) {
        die "[*] nf2csv does not compile with \"perl -c\".  Download ",
            "the latest sources from:\n\nhttp://www.cipherdyne.org/\n";
    }

    ### put the nf2csv script in place
    unlink '/usr/sbin/nf2csv' if -e '/usr/sbin/nf2csv';  ### old path
    &logr("[+] Copying nf2csv -> ${USRBIN_DIR}/nf2csv\n");
    unlink "${USRBIN_DIR}/nf2csv" if -e "${USRBIN_DIR}/nf2csv";
    copy 'nf2csv', "${USRBIN_DIR}/nf2csv" or die "[*] Could ",
        "not copy nf2csv -> ${USRBIN_DIR}/nf2csv: $!";
    &perms_ownership("${USRBIN_DIR}/nf2csv", 0755);

    ### put the fwcheck_psad.pl script in place
    &logr("[+] Copying fwcheck_psad.pl -> ${USRSBIN_DIR}/fwcheck_psad\n");
    unlink "${USRSBIN_DIR}/fwcheck_psad" if -e "${USRSBIN_DIR}/fwcheck_psad";
    copy 'fwcheck_psad.pl', "${USRSBIN_DIR}/fwcheck_psad" or die "[*] Could ",
        "not copy fwcheck_psad.pl -> ${USRSBIN_DIR}/fwcheck_psad: $!";
    &perms_ownership("${USRSBIN_DIR}/fwcheck_psad", 0500);

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

    unless (-d $PSAD_CONFDIR) {
        &logr("[+] Creating $PSAD_CONFDIR\n");
        mkdir $PSAD_CONFDIR,0500;
    }

    ### get syslog daemon (e.g. syslog, syslog-ng, or metalog)
    my $syslog_str = &query_syslog();

    my $preserve_rv = 0;
    if (-e "${PSAD_CONFDIR}/psad.conf") {
        $preserve_rv = &query_preserve_config();
    }

    ### the order of the config files is important (legacy FW_MSG_SEARCH
    ### vars in psad.conf).
    for my $file qw(psad.conf psadwatchd.conf
            kmsgsd.conf fw_search.conf alert.conf) {
        if (-e "${PSAD_CONFDIR}/$file") {
            &archive("${PSAD_CONFDIR}/$file") unless $noarchive;
            if ($preserve_rv) {
                &preserve_config($file);
            } else {
                &logr("[+] Copying $file -> ${PSAD_CONFDIR}/$file\n");
                copy $file, "${PSAD_CONFDIR}/$file" or die "[*] Could not ",
                    "copy $file -> ${PSAD_CONFDIR}/$file: $!";
            }
            if ($file eq 'fw_search.conf' and @old_fw_msg_search) {
                &logr("[-] Warning: psad.conf contains FW_MSG_SEARCH vars, " .
                    "but fw_search.conf also exists!\n");
            }
        } else {
            &logr("[+] Copying $file -> ${PSAD_CONFDIR}/$file\n");
            copy $file, "${PSAD_CONFDIR}/$file" or die "[*] Could not copy ",
                "$file -> ${PSAD_CONFDIR}/$file: $!";

            ### Deal with legacy FW_MSG_SEARCH in psad.conf.  Note that
            ### this will only preserve old search strings if 1) they already
            ### existed within psad.conf and 2) the file fw_search.conf does
            ### not already exist in /etc/psad/.
            if ($file eq 'fw_search.conf' and @old_fw_msg_search) {
                &preserve_old_fw_msg_search();
            }
        }

        if ($force_path_update or not $preserve_rv) {
            &update_command_paths("$PSAD_CONFDIR/$file")
                if ($file eq 'psad.conf' or $file eq 'psadwatchd.conf');
        }

        &perms_ownership("${PSAD_CONFDIR}/$file", 0600);
    }

    ### deal with any legacy diskmond.conf file
    if (-e "${PSAD_CONFDIR}/diskmond.conf") {
        &archive("${PSAD_CONFDIR}/diskmond.conf") unless $noarchive;
        unlink "${PSAD_CONFDIR}/diskmond.conf";
    }

    ### install auto_dl, signatures, icmp_types, posf, and pf.os files
    for my $file qw(signatures icmp_types
            posf auto_dl snort_rule_dl pf.os ip_options) {
        if (-e "${PSAD_CONFDIR}/$file") {
            &archive("${PSAD_CONFDIR}/$file") unless $noarchive;
### FIXME, need a real config preservation routine for these files.
#            unless (&query_preserve_sigs_autodl("${PSAD_CONFDIR}/$file")) {
        }
        &logr("[+] Copying $file -> ${PSAD_CONFDIR}/$file\n");
        copy $file, "${PSAD_CONFDIR}/$file" or die "[*] Could not ",
            "copy $file -> ${PSAD_CONFDIR}/$file: $!";
        &perms_ownership("${PSAD_CONFDIR}/$file", 0600);
    }
    &logr("\n");

    unless ($preserve_rv) {  ### we want to preserve the existing config

        ### get email address(es)
        my $email_str = &query_email();
        if ($email_str) {
            for my $file qw(psad.conf psadwatchd.conf) {
                &put_string('EMAIL_ADDRESSES', $email_str,
                    "${PSAD_CONFDIR}/$file");
            }
        }

        ### Give the admin the opportunity to set the strings that are
        ### parsed out of iptables messages.  This is useful since the
        ### admin may have configured the firewall to use a logging prefix
        ### of "Audit" or something else other than the default string
        ### "DROP".
        my $fw_search_aref = &get_fw_search_strings();
        if ($fw_search_aref) {
            open F, "< ${PSAD_CONFDIR}/fw_search.conf"
                or die "[*] Could not open ${PSAD_CONFDIR}/fw_search.conf: $!";
            my @lines = <F>;
            close F;
            open T, "> ${PSAD_CONFDIR}/fw_search.conf.tmp"
                or die "[*] Could not open ${PSAD_CONFDIR}/fw_search.conf.tmp: $!";
            for my $line (@lines) {
                if ($line =~ /^\s*FW_MSG_SEARCH/) {
                    last;
                } else {
                    print T $line;
                }
            }
            for my $fw_str (@$fw_search_aref) {
                &logr(qq{[+] Setting FW_MSG_SEARCH to "$fw_str" } .
                    "in ${PSAD_CONFDIR}/fw_search.conf\n");
                printf T "%-28s%s;\n", 'FW_MSG_SEARCH', $fw_str;
            }
            close T;
            move "${PSAD_CONFDIR}/fw_search.conf.tmp",
                "${PSAD_CONFDIR}/fw_search.conf" or die "[*] Could not move ",
                "${PSAD_CONFDIR}/fw_search.conf.tmp -> ",
                "${PSAD_CONFDIR}/fw_search.conf: $!";
        }
        ### Give the admin the opportunity to set the HOME_NET variable.
        &set_home_net("${PSAD_CONFDIR}/psad.conf");

        ### see if the admin would like to have psad send info to
        ### DShield
        if (&query_dshield()) {
            &put_string('ENABLE_DSHIELD_ALERTS', 'Y',
                "${PSAD_CONFDIR}/psad.conf");
        }

        ### Set the hostname
        for my $file ("${PSAD_CONFDIR}/psad.conf",
                "${PSAD_CONFDIR}/kmsgsd.conf",
                "${PSAD_CONFDIR}/psadwatchd.conf") {
            &logr("[+] Setting hostname to \"$HOSTNAME\" in $file\n");
            &set_hostname($file);
        }
    }

    &put_string('SYSLOG_DAEMON', $syslog_str,
        "${PSAD_CONFDIR}/psad.conf");

    if ($syslog_str ne 'ulogd') {
        my $restarted_syslog = 0;
        if ($syslog_str eq 'syslogd') {
            if (-e $syslog_conf) {
                &append_fifo_syslog($syslog_conf);
                if (((system "$Cmds{'killall'} -HUP syslogd 2> /dev/null")>>8) == 0) {
                    &logr("[+] HUP signal sent to syslogd.\n");
                    $restarted_syslog = 1;
                }
            }
        } elsif ($syslog_str eq 'syslog-ng') {
            if (-e $syslog_conf) {
                &append_fifo_syslog_ng($syslog_conf);
                if (((system "$Cmds{'killall'} -HUP syslog-ng 2> /dev/null")>>8) == 0) {
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

    if (-x $Cmds{'iptables'} and not $skip_syslog_test) {
        &logr("[+] Found iptables. Testing syslog configuration:\n");
        ### make sure we actually see packets being logged by
        ### the firewall.
        if ($syslog_str ne 'ulogd') {
            if (&test_syslog_config($syslog_str)) {
                &logr("[+] Successful $syslog_str reconfiguration.\n\n");
            } else {
                if (&query_init_script_restart_syslog()) {

                    my $restarted = 0;
                    if (-e "$INIT_DIR/sysklogd") {
                        system "$INIT_DIR/sysklogd restart";
                        $restarted = 1;
                    } elsif (-e "$INIT_DIR/syslog") {
                        system "$INIT_DIR/syslogd restart";
                        $restarted = 1;
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

    ### download signatures?
    &download_signatures() if &query_signatures();

    ### make sure the PSAD_DIR and PSAD_FIFO variables are correctly defined
    ### in psad.conf and kmsgsd.conf
    &put_string('PSAD_DIR', $PSAD_DIR, "${PSAD_CONFDIR}/psad.conf");
    &put_string('PSAD_FIFO', $PSAD_FIFO, "${PSAD_CONFDIR}/kmsgsd.conf");

    &install_manpage('psad.8');
    &install_manpage('psadwatchd.8');
    &install_manpage('kmsgsd.8');
    &install_manpage('nf2csv.1');

    my $init_file = '';
    if ($distro eq 'redhat') {
        $init_file = 'init-scripts/psad-init.redhat';
    } elsif ($distro eq 'fedora') {
        $init_file = 'init-scripts/psad-init.fedora';
    } elsif ($distro eq 'gentoo') {
        $init_file = 'init-scripts/psad-init.gentoo';
    } else {
        $init_file = 'init-scripts/psad-init.generic';
    }

    if ($init_dir) {
        &logr("[+] Copying $init_file -> ${init_dir}/psad\n");
        copy $init_file, "${init_dir}/psad" or die "[*] Could not copy ",
            "$init_file -> ${init_dir}/psad: $!";
        &perms_ownership("${init_dir}/psad", 0744);
        &enable_psad_at_boot($distro);
    }

    &logr("\n========================================================\n");
    if ($archived_old) {
        &logr("[+] Copies of your original configs have been made " .
            "in: $CONF_ARCHIVE\n");
    }
    if ($preserve_rv) {
        &logr("\n[+] Psad has been installed (with your original config merged).\n");
    } else {
        &logr("\n[+] Psad has been installed.\n");
    }
    if ($init_dir) {
        &logr("\n[+] To start psad, run \"${init_dir}/psad start\"\n");
    } else {
        &logr("\n[+] To start psad, run ${USRSBIN_DIR}/psad\"\n");
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
    if (-e "${RUNDIR}/psad.pid") {
        open PID, "${RUNDIR}/psad.pid" or die "[*] Could not open ",
            "${RUNDIR}/psad.pid: $!";
        my $pid = <PID>;
        close PID;
        chomp $pid;
        if (kill 0, $pid) {
            print "[+] Stopping psad daemons!\n";
            if (-e "${init_dir}/psad") {  ### prefer this for old versions
                system "${init_dir}/psad stop";
            } else {
                system "${USRSBIN_DIR}/psad --Kill";
            }
        }
    }
    if (-e "${USRSBIN_DIR}/fwcheck_psad") {
        print "[+] Removing ${USRSBIN_DIR}/fwcheck_psad\n";
        unlink "${USRSBIN_DIR}/fwcheck_psad";
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
        print "[+] Removing ${init_dir}/psad\n";
        unlink "${init_dir}/psad";
    }
    if (-e "${PERL_INSTALL_DIR}/Psad.pm") {
        print " ----  Removing ${PERL_INSTALL_DIR}/Psad.pm  ----\n";
        unlink "${PERL_INSTALL_DIR}/Psad.pm";
    }
    if (-d $PSAD_CONFDIR) {
        print "[+] Removing configuration directory: $PSAD_CONFDIR\n";
        rmtree($PSAD_CONFDIR, 1, 0);
    }
    if (-d $PSAD_DIR) {
        print "[+] Removing logging directory: $PSAD_DIR\n";
        rmtree($PSAD_DIR, 1, 0);
    }
    if (-e $PSAD_FIFO) {
        print "[+] Removing named pipe: $PSAD_FIFO\n";
        unlink $PSAD_FIFO;
    }
    ### remove old whois binary location
    if (-e '/usr/bin/whois.psad') {
        print "[+] Removing $WHOIS_PSAD\n";
        unlink $WHOIS_PSAD;
    }
    if (-e $WHOIS_PSAD) {
        print "[+] Removing $WHOIS_PSAD\n";
        unlink $WHOIS_PSAD;
    }
    if (-d $VARLIBDIR) {
        print "[+] Removing $VARLIBDIR\n";
        rmtree $VARLIBDIR;
    }
    if (-d $RUNDIR) {
        print "[+] Removing $RUNDIR\n";
        rmtree $RUNDIR;
    }
    for my $dir ($LIBDIR, $LIBDIR64) {
        if (-d $dir) {
            print "[+] Removing $dir\n";
            rmtree $dir;
        }
    }
    my $running_syslogd = 0;
    my $running_syslog_ng = 0;
    print "[+] Restoring /etc/syslog.conf.orig -> /etc/syslog.conf\n";
    if (-e '/etc/syslog.conf.orig') {
        move '/etc/syslog.conf.orig', '/etc/syslog.conf' or die "[*] Could not ",
            "move /etc/syslog.conf.orig -> /etc/syslog.conf: $!";
        $running_syslogd = 1;
    } elsif (-e '/etc/syslog.conf') {
        print "[+] /etc/syslog.conf.orig does not exist. ",
            " Editing /etc/syslog.conf directly.\n";
        open ESYS, '< /etc/syslog.conf' or
            die "[*] Unable to open /etc/syslog.conf: $!\n";
        my @sys = <ESYS>;
        close ESYS;
        open CSYS, '> /etc/syslog.conf' or die "[*] Could not open ",
            "/etc/syslog.conf: $!";
        for my $line (@sys) {
            chomp $line;
            ### don't print the psadfifo line
            print CSYS "$line\n" if ($line !~ /psadfifo/);
        }
        close CSYS;
        $running_syslogd = 1;
    } elsif (-e '/etc/syslog-ng/syslog-ng.conf.orig') {
        move '/etc/syslog-ng/syslog-ng.conf.orig', '/etc/syslog-ng/syslog-ng.conf'
            or die "[*] Could not move /etc/syslog.conf.orig ",
                "-> /etc/syslog.conf: $!";
        $running_syslog_ng = 1;
    }
    if ($running_syslogd) {
        print "[+] Restarting syslog.\n";
        system "$Cmds{'killall'} -HUP syslogd";
    } elsif ($running_syslog_ng) {
        print "[+] Restarting syslog.\n";
        system "$Cmds{'killall'} -HUP syslog-ng";
    }
    print "\n";
    print "[+] Psad has been uninstalled!\n";
    return;
}

sub ask_to_stop_psad() {
    if (-e "$RUNDIR/psad.pid") {
        open P, "< $RUNDIR/psad.pid" or die "[*] Could not open ",
            "$RUNDIR/psad.pid: $!";
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
    if (-e "$RUNDIR/psad.pid") {
        open P, "< $RUNDIR/psad.pid" or die "[*] Could not open ",
            "$RUNDIR/psad.pid: $!";
        my $pid = <P>;
        close P;
        chomp $pid;
        if (kill 0, $pid) {
            print "[+] Stopping running psad daemons.\n";
            if (-x "$init_dir/psad") {
                system "$init_dir/psad stop";
                ### if psad is still running then use -K
                if (kill 0, $pid) {
                    system "$USRSBIN_DIR/psad -K";
                }
            } else {
                ### psad may have been started from the command line
                ### without using the init script, so stop with -K
                system "$USRSBIN_DIR/psad -K";
            }
        }
    }
    return;
}

sub install_perl_module() {
    my $mod_name = shift;

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
            ### install the module in the /usr/lib/fwknop directory because
            ### it is not already installed.
            $install_module = 1;
        }
    }

    if ($install_module) {
        unless (-d $LIBDIR) {
            &logr("[+] Creating $LIBDIR\n");
            mkdir $LIBDIR, 0755 or die "[*] Could not mkdir $LIBDIR: $!";
        }
        &logr("[+] Installing the $mod_name $version perl " .
            "module in $LIBDIR/\n");
        my $mod_dir = $required_perl_modules{$mod_name}{'mod-dir'};
        chdir $mod_dir or die "[*] Could not chdir to ",
            "$mod_dir: $!";
        unless (-e 'Makefile.PL') {
            die "[*] Your $mod_name source directory appears to be incomplete!\n",
                "    Download the latest sources from ",
                "http://www.cipherdyne.org/\n";
        }
        system "$Cmds{'make'} clean"
            if -e 'Makefile' or -e 'makefile' or -e 'GNUmakefile';
        system "$Cmds{'perl'} Makefile.PL PREFIX=$LIBDIR LIB=$LIBDIR";
        system $Cmds{'make'};
#        system "$Cmds{'make'} test";
        system "$Cmds{'make'} install";
        chdir $src_dir or die "[*] Could not chdir $src_dir: $!";

        print "\n\n";
    }
    return;
}

sub set_home_net() {
    my $file = shift;

    ### first see if the admin will accept the default 'any' value
    return if &query_use_home_net_default();

    ### get all interfaces; even those that are down since they may
    ### brought up any time.
    my @ifconfig_out = `$Cmds{'ifconfig'} -a`;
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
        if ($line =~ /^(\w+)\s+Link/) {
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
    if ($net_ctr > 1) {
        ### found two or more subnets, so forwarding traffic becomes
        ### possible through the box.
        &logr("[+] It appears your machine is connected to " .
            "$net_ctr subnets:\n");
        for my $intf (keys %connected_subnets) {
            &logr("      $intf -> $connected_subnets{$intf}\n");
        }
        &logr("\n");
        &logr("    Specify which subnets are part of your internal network.  " .
            "Note that\n");
        &logr("    you can correct anything you enter here by editing the " .
            "\"HOME_NET\"\n");
        &logr("    variable in: $file.\n\n");
        &logr("    Enter each of the subnets (except for the external " .
            "subnet)\n");
        &logr("    on a line by itself.  Each of the subnets should be in the " .
            "form\n");
        &logr("    <net>/<mask>.  E.g. in CIDR notation: 192.168.10.0/24 " .
            "(preferrable),\n");
        &logr("    or regularly: 192.168.10.0/255.255.255.0\n\n");
        &logr("    End with a \".\" on a line by itself.\n\n");
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
    } else {
        ### forwarding is not possible, so set HOME_NET to a dummy
        ### value.
        $home_net_str = 'NOT_USED';
    }
    if ($home_net_str) {
        $home_net_str =~ s/\,\s*$//;
        &put_string('HOME_NET', $home_net_str, $file);
    } else {
        &put_string('HOME_NET', 'NOT_USED', $file);
    }
    return;
}

sub query_signatures() {
    &logr("[+] The latest psad signatures can be installed with " .
        qq|"psad --sig-update"\n    or installed now with install.pl.\n\n|);
    &logr("    If you decide to answer 'y' to the next question, install.pl\n" .
        "    will require DNS and network access.\n\n");
    return &query_yes_no("    Would you like to install the latest " .
            "signatures from\n    $SIG_UPDATE_URL " .
            "(y/n)?  ", $NO_ANS_DEFAULT);
}

sub download_signatures() {

    my $curr_pwd = cwd() or die $!;
    chdir '/tmp' or die $!;

    print "[+] Downloading latest signatures from:\n",
        "        $SIG_UPDATE_URL\n";

    unlink 'signatures' if -e 'signatures';

    ### download the file
    unless (-x $wgetCmd) {
        &logr("[-] The $wgetCmd var is not a valid path for wget, " .
            "skipping sig install.\n");
    }
    system "$wgetCmd $SIG_UPDATE_URL";

    unless (-e 'signatures') {
        &logr("[-] Could not download signatures, continuing with install.\n");
    }

    unlink "${PSAD_CONFDIR}/signatures" if -e "${PSAD_CONFDIR}/signatures";
    move 'signatures', "${PSAD_CONFDIR}/signatures";
    chdir $curr_pwd or die $!;

    return;
}

sub query_use_home_net_default() {
    &logr(
"[+] By default, psad matches Snort rules against any IP addresses, but psad\n");
    &logr(
"    offers the ability to restrict signature matches to specific networks\n");
    &logr(
"    with a similar concept to the HOME_NET variable in Snort.  Would you like\n");
    &logr(
"    limit the networks psad uses to enumerate the home network(s)?\n");

    return &query_yes_no("    (y/[n])?  ", $ACCEPT_NO_DEFAULT);
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
            "http://www.cipherdyne.org/\n";
    }
    return;
}

### see if there are any "_CHANGEME_" strings left and give the
### admin a chance to correct (this can happen if a new config
### variable is introduced in a new version of psad but the
### admin chose to preserve the old config).
sub check_hostname() {
    my $file = shift;

    open F, "< $file" or die "[*] Could not open $file: $!\n";
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
        die "[*] Unable to open $syslog_conf: $!\n";
    my @slines = <RS>;
    close RS;

    my $found_fifo = 0;
    for my $line (@slines) {
        $found_fifo = 1 if ($line =~ /psadfifo/);
    }

    unless ($found_fifo) {
        &logr("[+] Modifying $syslog_conf to write kern.info " .
            "messages to\n    $PSAD_FIFO");
        unless (-e "$syslog_conf.orig") {
            copy $syslog_conf, "$syslog_conf.orig" or die "[*] Could not ",
                "copy $syslog_conf -> $syslog_conf.orig: $!";
        }
        &archive($syslog_conf);

        my $src = 'src';
        ### see if a different source name is defined for /proc/kmsg
        for my $line (@slines) {
            ### source kernsrc { file("/proc/kmsg"); };
            if ($line =~ m|^\s*source\s+(\w+)\s+.*file\(\"/proc/kmsg\"\);|) {
                $src = $1;
            }
        }
        open SYSLOGNG, ">> $syslog_conf" or
            die "[*] Unable to open $syslog_conf: $!\n";
        print SYSLOGNG "\n",
            "destination psadpipe { pipe(\"/var/lib/psad/psadfifo\"); };\n",
#            "filter f_kerninfo { facility(kern) and level(info); };\n",
            "filter f_kerninfo { facility(kern); };\n",
            "log { source($src); filter(f_kerninfo); destination(psadpipe); };\n";
        close SYSLOGNG;
    }
    return;
}

sub config_metalog() {
    my $syslog_conf = shift;
    open RS, "< $syslog_conf" or
        die "[*] Unable to open $syslog_conf: $!\n";
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
            "to\n    $PSAD_FIFO (with script /usr/sbin/psadpipe.sh)");
        unless (-e "$syslog_conf.orig") {
            copy $syslog_conf, "$syslog_conf.orig" or die "[*] Could not copy ",
                "$syslog_conf -> $syslog_conf.orig: $!";
        }
        open METALOG, "> $syslog_conf" or
            die "[*] Unable to open $syslog_conf: $!";

        print METALOG "\n";
        print METALOG "\nPSAD :\n",
            "  facility = \"kern\"\n";
        print METALOG '  command  = ',
            "\"/usr/sbin/psadpipe.sh\"\n";
        close METALOG;

        open PIPESCRIPT, '> /usr/sbin/psadpipe.sh' or
            die "[*] Unable to open /usr/sbin/psadpipe.sh: $!";
        print PIPESCRIPT "#!/bin/sh\n\n";
        print PIPESCRIPT "echo \"\$3\" >> $PSAD_FIFO\n";
        close PIPESCRIPT;
        chmod 0700, '/usr/sbin/psadpipe.sh';
        &logr('[+] Generated /usr/sbin/psadpipe.sh ' .
            "which writes to $PSAD_FIFO");

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
    my $ans = '';
    while ($ans ne 'y' and $ans ne 'n') {
        &logr($msg);
        $ans = lc(<STDIN>);
        if ($style == $ACCEPT_YES_DEFAULT) {
            $ans = 'y' if $ans eq "\n";
        } elsif ($style == $ACCEPT_NO_DEFAULT) {
            $ans = 'n' if $ans eq "\n";
        }
        chomp $ans;
    }
    return 1 if $ans eq 'y';
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
    return &query_yes_no("[+] Merge any user modfications " .
            "in $file ([y]/n)?  ", $ACCEPT_YES_DEFAULT);
}

sub preserve_old_fw_msg_search() {
    open F, "< ${PSAD_CONFDIR}/fw_search.conf" or die "[*] Could not open ",
        "${PSAD_CONFDIR}/fw_search.conf: $!";
    my @orig_lines = <F>;
    close F;

    &logr("[+] Preserving old FW_MSG_SEARCH values: " .
        "${PSAD_CONFDIR}/fw_search.conf\n");

    open CONF, "> ${PSAD_CONFDIR}/fw_search.conf.new" or
        die "[*] Could not open ${PSAD_CONFDIR}/fw_search.conf.new: $!";

    my $found_search_var = 0;
    my $printed_old_strs = 0;
    for my $line (@orig_lines) {
        if ($line =~ /^\s*FW_MSG_SEARCH/) {
            $found_search_var = 1;
        } else {
            print CONF $line;
        }
        if ($found_search_var and not $printed_old_strs) {
            print CONF for @old_fw_msg_search;
            $printed_old_strs = 1;
        }
    }
    close CONF;
    move "${PSAD_CONFDIR}/fw_search.conf.new", "${PSAD_CONFDIR}/fw_search.conf"
        or die "[*] Could not move ${PSAD_CONFDIR}/fw_search.conf.new -> ",
        "${PSAD_CONFDIR}/fw_search.conf: $!";
    return;
}

sub preserve_config() {
    my $file = shift;
    open C, "< $file" or die "[*] Could not open $file: $!";
    my @new_lines = <C>;
    close C;

    open CO, "< ${PSAD_CONFDIR}/$file" or die "[*] Could not open ",
        "${PSAD_CONFDIR}/$file: $!";
    my @orig_lines = <CO>;
    close CO;

    ### deal with legacy FW_MSG_SEARCH lines in psad.conf
    if ($file eq 'psad.conf') {
        for my $line (@orig_lines) {
            next unless $line =~ /\S/;
            next if $line =~ /^\s*#/;
            if ($line =~ /^\s*FW_MSG_SEARCH\s/) {
                push @old_fw_msg_search, $line;
            }
        }
    }

    &logr("[+] Preserving existing config: ${PSAD_CONFDIR}/$file\n");
    ### write to a tmp file and then move so any running psad daemon will
    ### re-import a full config file if a HUP signal is received during
    ### the install.
    open CONF, "> ${PSAD_CONFDIR}/${file}.new" or die "[*] Could not open ",
        "${PSAD_CONFDIR}/${file}.new: $!";
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
    move "${PSAD_CONFDIR}/${file}.new", "${PSAD_CONFDIR}/$file" or die "[*] ",
        "Could not move ${PSAD_CONFDIR}/${file}.new -> ",
        "${PSAD_CONFDIR}/$file: $!";
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
        &logr("    $PSAD_FIFO\n");
        unless (-e "$syslog_conf.orig") {
            copy $syslog_conf, "$syslog_conf.orig" or die "[*] Could ",
                "not copy $syslog_conf -> $syslog_conf.orig: $!";
        }
        &archive($syslog_conf);
        open SYSLOG, "> $syslog_conf" or
            die "[*] Unable to open $syslog_conf: $!\n";
        for my $line (@slines) {
            unless ($line =~ /psadfifo/) {
                print SYSLOG $line;
            }
        }
        print SYSLOG '### Send kern.info messages to psadfifo for ',
            "analysis by kmsgsd\n";
        ### reinstate kernel logging to our named pipe
        print SYSLOG "kern.info\t\t|$PSAD_FIFO\n";
        close SYSLOG;
    }
    return;
}

sub test_syslog_config() {
    my $syslog_str = shift;
    my %used_ports;

    ### first find an unused high tcp port to use for testing
    my @netstat_out = `$Cmds{'netstat'} -an`;

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
    my $uprv = (system "$Cmds{'ifconfig'} lo up") >> 8;

    if ($uprv) {
        &logr("[-] Could not bring up the loopback interface.\n" .
            "    Hoping the syslog reconfig will work anyway.\n");
        return 0;
    }

    ### make sure we can see the loopback interface with
    ### ifconfig
    my @if_out = `$Cmds{'ifconfig'} lo`;

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
    if (-e "${RUNDIR}/kmsgsd.pid") {
        open PID, "< ${RUNDIR}/kmsgsd.pid" or die "[*] Could not open ",
            "${RUNDIR}/kmsgsd.pid: $!";
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
        unless (((system "${USRSBIN_DIR}/kmsgsd")>>8) == 0) {
            &logr("[-] Could not start kmsgsd to test syslog.\n" .
                "    Send email to Michael Rash (mbr\@cipherdyne.org)\n");
            return 0;
        }
    }

    ### insert a rule to deny traffic to the loopback
    ### interface on $test_port
    system "$Cmds{'iptables'} -I INPUT 1 -i lo -p tcp --dport " .
        "$test_port -j LOG --log-prefix \"test_DROP \"";

    open FWDATA, "${PSAD_DIR}/fwdata" or
        die "[*] Could not open ${PSAD_DIR}/fwdata: $!";

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
    system "$Cmds{'iptables'} -D INPUT 1";

    ### remove the any new test_DROP lines we just created
    ### (this probably is not necessary because psad is not
    ### running).
    &scrub_prefix_ctr();

    if ($found) {
    } else {
    }

    if ($start_kmsgsd && -e "${RUNDIR}/kmsgsd.pid") {
        open PID, "${RUNDIR}/kmsgsd.pid" or return 0;
        my $pid = <PID>;
        close PID;
        chomp $pid;
        kill 9, $pid if kill 0, $pid;
    }
    return $found;
}

sub scrub_prefix_ctr() {
    if (-e "${PSAD_DIR}/ipt_prefix_ctr") {
        open SCRUB, "< ${PSAD_DIR}/ipt_prefix_ctr" or
            die "[*] Could not open ${PSAD_DIR}/ipt_prefix_ctr: $!";
        my @lines = <SCRUB>;
        close SCRUB;

        open SCRUB, "> ${PSAD_DIR}/ipt_prefix_ctr" or
            die "[*] Could not open ${PSAD_DIR}/ipt_prefix_ctr: $!";
        for my $line (@lines) {
            print SCRUB $line unless $line =~ /test_DROP/;
        }
        close SCRUB;
    }
    return;
}

sub check_old_psad_installation() {
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
    if (-e "${PSAD_CONFDIR}/psad_signatures.old") {
        unlink "${PSAD_CONFDIR}/psad_signatures.old";
    }
    if (-e "${PSAD_CONFDIR}/psad_auto_ips.old") {
        unlink "${PSAD_CONFDIR}/psad_auto_ips.old";
    }
    if (-e "${PSAD_CONFDIR}/psad.conf.old") {
        unlink "${PSAD_CONFDIR}/psad.conf.old";
    }
    ### Psad.pm will be installed The Right Way using "make"
    unlink "${PERL_INSTALL_DIR}/Psad.pm"
        if (-e "${PERL_INSTALL_DIR}/Psad.pm");
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
        }
    }
    return 'NA';
}

sub perms_ownership() {
    my ($file, $perm_value) = @_;
    chmod $perm_value, $file or die "[*] Could not ",
        "chmod($perm_value, $file): $!";
    ### root (maybe should take the group assignment out)
    chown 0, 0, $file or die "[*] Could not chown 0,0,$file: $!";
    return;
}

sub get_fw_search_strings() {
    my @fw_search_strings = ();

        print
"\n[+] By default psad parses all iptables log messages for scan activity.\n",
"    However, psad can be configured to only parse those iptables messages\n",
"    that match particular strings (that are specified in your iptables\n",
"    ruleset with the --log-prefix option).\n";

    if (&query_yes_no("\n    Would you like psad to only parse " .
            "specific strings in iptables\n    messages (y/[n])?  ",
            $ACCEPT_NO_DEFAULT)) {


        ### we are only searching for specific iptables log prefixes
        &put_string('FW_SEARCH_ALL', 'N', "${PSAD_CONFDIR}/fw_search.conf");

        print
"\n[+] psad checks the firewall configuration on the underlying machine\n",
"    to see if packets will be logged and dropped that have not\n",
"    explicitly allowed through.  By default psad looks for the string\n",
"    \"DROP\". However, if your particular firewall configuration logs\n",
"    blocked packets with the string \"Audit\" for example, psad can be\n",
"    configured here to look for this string.  In addition, psad can also\n",
"    be configured here to look for multiple strings if needed.  Remember,\n",
"    whatever string you configure psad to look for must be logged via the\n",
"    --log-prefix option in iptables.\n\n";
        print "\n";
        &logr("[+] Add as many search strings as you like; " .
            "each on its own line.\n\n");
        &logr("    End with a \".\" on a line by itself.\n\n");
        my $ans = '';
        while ($ans !~ /^\s*\.\s*$/) {
            &logr("    String (i.e. \"Audit\"):  ");
            $ans = <STDIN>;
            chomp $ans;
            if ($ans =~ /\"/) {
                &logr("[-] Quotes will be removed from FW search string: $ans\n");
                $ans =~ s/\"//g;
            }
            if ($ans =~ /\S/) {
                if ($ans !~ /^\s*\.\s*$/) {
                    push @fw_search_strings, $ans;
                }
            } else {
                &logr("[-] Invalid string **\n");
            }
        }
        &logr("    All firewall search strings used by psad are located " .
            "in the file: $PSAD_CONFDIR/fw_search.conf\n");
    }
    return \@fw_search_strings;
}

sub query_dshield() {
    &logr("\n");
    &logr("[+] Psad has the capability of sending scan data via email alerts " .
        "to the\n");
    &logr("    DShield distributed intrusion detection system (www.dshield.org)." .
        "  By\n");
    &logr("    default this feature is not enabled since firewall log data is " .
        "sensitive,\n");
    &logr("    but submitting logs to DShield provides a valuable service and " .
        "assists in\n");
    &logr("    generally enhancing internet security.  As an optional step, if " .
        "you\n");
    &logr("    have a DShield user id you can edit the \"DSHIELD_USER_ID\" " .
        "variable\n");
    &logr("    in $PSAD_CONFDIR/psad.conf\n\n");

    return &query_yes_no('    Would you like to enable DShield alerts (y/[n])?  ',
            $ACCEPT_NO_DEFAULT);
}

sub query_email() {
    my $email_str = '';
    open F, "< ${PSAD_CONFDIR}/psad.conf" or die "[*] Could not open ",
        "${PSAD_CONFDIR}/psad.conf: $!";
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
    }
    return $email_str;
}

sub query_syslog() {
    &logr("\n[+] psad supports the syslogd, syslog-ng, ulogd, and\n" .
        "    metalog logging daemons.  Which system logger is running?\n\n");
    my $ans = '';
    while ($ans ne 'syslogd' and $ans ne 'syslog-ng' and $ans ne 'ulogd'
            and $ans ne 'metalog') {
        &logr("    syslogd / syslog-ng / ulogd / metalog? [syslogd] ");
        $ans = <STDIN>;
        if ($ans eq "\n") {  ### allow default to take over
            $ans = 'syslogd';
        }
        $ans =~ s/\s*//g;

        if ($ans eq 'syslogd') {
            ### allow command line --syslog-conf arg to take over
            $syslog_conf = '/etc/syslog.conf' unless $syslog_conf;
        } elsif ($ans eq 'syslog-ng') {
            ### allow command line --syslog-conf arg to take over
            $syslog_conf = '/etc/syslog-ng/syslog-ng.conf' unless $syslog_conf;
        } elsif ($ans eq 'metalog') {
            ### allow command line --syslog-conf arg to take over
            $syslog_conf = '/etc/metalog/metalog.conf' unless $syslog_conf;
        }
        if ($ans ne 'ulogd' and $syslog_conf and not -e $syslog_conf) {
            die
"[-] The config file $syslog_conf does not exist. Re-run install.pl\n",
"    with the --syslog-conf argument to specify the path to the syslog\n",
"    daemon config file.\n";
        }
    }
    die "[-] Invalid syslog daemon \"$ans\"\n"
        unless ($ans and
            ($ans eq 'syslogd'
            or $ans eq 'syslog-ng'
            or $ans eq 'ulogd'
            or $ans eq 'metalog'));
    print "\n";
    return $ans;
}

sub put_string() {
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
    chdir $CONF_ARCHIVE or die $!;
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
    &logr("[+] Archiving $file -> ${base}1\n");
    unlink "${base}1.gz" if -e "${base}1.gz";
    ### move $file into the archive directory
    copy $file, "${base}1" or die "[*] Could not copy ",
        "$file -> ${base}1: $!";
    system "$Cmds{'gzip'} ${base}1";
    chdir $curr_pwd or die $!;
    $archived_old = 1;
    return;
}

sub enable_psad_at_boot() {
    my $distro = shift;

    if (&query_yes_no("[+] Enable psad at boot time ([y]/n)?  ",
                $ACCEPT_YES_DEFAULT)) {
        if ($distro eq 'redhat' or $distro eq 'fedora') {
            system "$Cmds{'chkconfig'} --add psad";
        } elsif ($distro eq 'gentoo') {
            system "$Cmds{'rc-update'} add psad default";
        } else {  ### it is a non-redhat distro, try to
                  ### get the runlevel from /etc/inittab
            if ($RUNLEVEL) {
                ### the link already exists, so don't re-create it
                unless (-e "/etc/rc.d/rc${RUNLEVEL}.d/S99psad") {
                    symlink '/etc/rc.d/init.d/psad',
                        "/etc/rc.d/rc${RUNLEVEL}.d/S99psad";
                }
            } elsif (-e '/etc/inittab') {
                open I, '< /etc/inittab' or die "[*] Could not open ",
                    "/etc/inittab: $!";
                my @ilines = <I>;
                close I;
                for my $line (@ilines) {
                    chomp $line;
                    if ($line =~ /^id\:(\d)\:initdefault/) {
                        $RUNLEVEL = $1;
                        last;
                    }
                }
                unless ($RUNLEVEL) {
                    &logr("[-] Could not determine the runlevel.  Set " .
                        "the runlevel\nmanually in the config section of " .
                        "install.pl\n");
                    return;
                }
                ### the link already exists, so don't re-create it
                unless (-e "/etc/rc.d/rc${RUNLEVEL}.d/S99psad") {
                    symlink '/etc/rc.d/init.d/psad',
                        "/etc/rc.d/rc${RUNLEVEL}.d/S99psad";
                }
            } else {
                &logr("[-] /etc/inittab does not exist!  Set the " .
                    "runlevel\nmanually in the config section of " .
                    "install.pl.\n");
                return;
            }
        }
    }
    return;
}

### check paths to commands and attempt to correct if any are wrong.
sub check_commands() {
    CMD: for my $cmd (keys %Cmds) {
        unless (-x $Cmds{$cmd}) {
            my $found = 0;
            PATH: for my $dir (@cmd_search_paths) {
                if (-x "${dir}/${cmd}") {
                    $Cmds{$cmd} = "${dir}/${cmd}";
                    $found = 1;
                    last PATH;
                }
            }
            unless ($found) {
                die "\n[*] Could not find $cmd anywhere!!!  ",
                    "Please edit the config section to include the path to ",
                    "$cmd.\n";
            }
        }
        unless (-x $Cmds{$cmd}) {
            die "\n[*] $cmd is located at ",
                "$Cmds{$cmd} but is not executable by uid: $<\n";
        }
    }
    return;
}

sub install_manpage() {
    my $manpage = shift;

    my $name;
    my $section;

    if ($manpage =~ m|(\w+)\.(\d)|) {
        $name = $1;
        $section = $2;
    } else {
        die "[*] Improper man page name, should be \"pagename.section\"";
    }

    ### remove old man page
    unlink "/usr/local/man/man$section/${manpage}" if
        (-e "/usr/local/man/man$section/${manpage}");

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
    mkdir $mpath, 0755 unless -d $mpath;
    my $mfile = "${mpath}/${manpage}";
    &logr("[+] Installing $manpage man page at $mfile\n");
    copy $manpage, $mfile or die "[*] Could not copy $manpage to ",
        "$mfile: $!";
    &perms_ownership($mfile, 0644);
    &logr("[+] Compressing manpage $mfile\n");
    ### remove the old one so gzip doesn't prompt us
    unlink "${mfile}.gz" if -e "${mfile}.gz";
    system "$Cmds{'gzip'} $mfile";
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

### logging subroutine that handles multiple filehandles
sub logr() {
    my $msg = shift;
    for my $file (@LOGR_FILES) {
        if ($file eq *STDOUT) {
            print STDOUT $msg;
        } elsif ($file eq *STDERR) {
            print STDERR $msg;
        } else {
            open F, ">> $file" or die "[*] Could not open ",
                "$file: $!";
            print F $msg;
            close F;
        }
    }
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
    -s  <file>                   - Specify path to syslog.conf file.
    -r, --rm-lib-dir             - Remove any /usr/lib/psad/ directory
                                   before installing psad.
    --no-syslog-test             - Skip syslog reconfiguration test.
    --no-preserve                - Disable preservation of old configs.
    -h  --help                   - Prints this help message.

_HELP_
    exit $exitcode;
}
