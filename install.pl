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
# Version: 1.3.1
#
# Copyright (C) 1999-2002 Michael Rash (mbr@cipherdyne.org)
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
use Text::Wrap;
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

#============== config ===============
my $INSTALL_LOG  = "${PSAD_DIR}/install.log";
my $PSAD_FIFO    = "${VARLIBDIR}/psadfifo";
my $INIT_DIR     = '/etc/rc.d/init.d';
my $USRSBIN_DIR  = '/usr/sbin';  ### consistent with FHS (Filesystem
                                 ### Hierarchy Standard)
my $CONF_ARCHIVE = "${PSAD_CONFDIR}/archive";
my @LOGR_FILES   = (*STDOUT, $INSTALL_LOG);
my $RUNLEVEL;    ### This should only be set if install.pl
                 ### cannot determine the correct runlevel
my $WHOIS_PSAD   = '/usr/bin/whois_psad';

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
my $iptablesCmd  = '/sbin/iptables';
my $psadCmd      = "${USRSBIN_DIR}/psad";
#============ end config ============

### IP regex
my $ip_re = '(?:\d{1,3}\.){3}\d{1,3}';

### used to preserve old FW_MSG_SEARCH vars from previous
### psad installation.  This is only needed when upgrading
### to a newer version of psad that uses the fw_search.conf
### file from a previous version that doesn't.
my @old_fw_msg_search;

### get the hostname of the system
my $HOSTNAME = hostname();

if (-e $INSTALL_LOG) {
    open INSTALL, "> $INSTALL_LOG" or
        die " ** Could not open $INSTALL_LOG: $!";
    close INSTALL;
}

### scope these vars
my $PERL_INSTALL_DIR;  ### This is used to find pre-0.9.2 installations of psad

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

### set the default execution flags
my $SUB_TAB = '    ';
my $noarchive    = 0;
my $uninstall    = 0;
my $help         = 0;

&usage(1) unless (GetOptions(
    'no-preserve' => \$noarchive,   ### Don't preserve existing configs.
    'uninstall'   => \$uninstall,   ### Uninstall psad.
    'help'        => \$help         ### Display help.
));
&usage(0) if $help;

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

if ($distro eq 'redhat') {
    ### add chkconfig only if we are runing on a redhat distro
    $Cmds{'chkconfig'} = $chkconfigCmd;
} elsif ($distro eq 'gentoo') {
    ### add rc-update if we are running on a gentoo distro
    $Cmds{'rc-update'} = $rcupdateCmd;
}

my $init_dir = '';

if (-d $INIT_DIR) {
    $init_dir = $INIT_DIR;
} elsif (-d '/etc/init.d') {
    $init_dir = '/etc/init.d';
} else {
    &logr(" ** Cannot find the init script directory, edit " .
        "the \$INIT_DIR variable.\n");
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

### check for a pre-0.9.2 installation of psad.
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
    unless (-e 'psad' && -e 'Psad/Psad.pm') {
        die " ** install.pl can only be executed from the directory\n",
            "    that contains the psad sources!  Exiting.";
    }
    &logr("\n .. " . localtime() . " Installing psad on hostname: $HOSTNAME\n");
    unless (-d $RUNDIR) {
        &logr(" .. Creating $RUNDIR\n");
        mkdir $RUNDIR, 0500;
    }
    unless (-d $VARLIBDIR) {
        &logr(" .. Creating $VARLIBDIR\n");
        mkdir $VARLIBDIR, 0500;
    }
    unless (-d $LIBDIR) {
        &logr(" .. Creating $LIBDIR\n");
        mkdir $LIBDIR, 0755;
    }
    ### change any existing psad module directory to allow anyone to execute
    chmod 0755, $LIBDIR;
    unless (-d $PSAD_CONFDIR) {
        &logr(" .. Creating $PSAD_CONFDIR\n");
        mkdir $PSAD_CONFDIR, 0500;
    }
    unless (-d $CONF_ARCHIVE) {
        &logr(" .. Creating $CONF_ARCHIVE\n");
        mkdir $CONF_ARCHIVE, 0500;
    }
    unless (-e $PSAD_FIFO) {
        &logr(" .. Creating named pipe $PSAD_FIFO\n");
        unless (((system "$Cmds{'mknod'} -m 600 $PSAD_FIFO p")>>8) == 0) {
            &logr(" ** Could not create the named pipe \"$PSAD_FIFO\"!" .
                " ** psad requires this file to exist!  Aborting install.\n");
            die;
        }
        unless (-p $PSAD_FIFO) {
            &logr(" ** Could not create the named pipe \"$PSAD_FIFO\"!" .
                " ** psad requires this file to exist!  Aborting " .
                "install.\n");
            die;
        }
    }

    my $restarted_syslog = 0;
    if (-e '/etc/syslog.conf') {
        &append_fifo_syslog();
        if (((system "$Cmds{'killall'} -HUP syslogd 2> /dev/null")>>8) == 0) {
            &logr(" .. Restarted syslog.\n");
            $restarted_syslog = 1;
        }
    }
    if (-e '/etc/syslog-ng/syslog-ng.conf') {
        &append_fifo_syslog_ng();
        if (((system "$Cmds{'killall'} -HUP syslog-ng 2> /dev/null")>>8) == 0) {
            &logr(" .. Restarted syslog-ng.\n");
            $restarted_syslog = 1;
        }
    }
    if (-e '/etc/metalog/metalog.conf') {
        &config_metalog();
        &logr(" ** Metalog support is shaky in psad.  " .
            "Use at your own risk.\n");
    }

    unless ($restarted_syslog) {
        &logr(" ** Could not restart any syslog daemons.\n");
    }
    unless (-d $PSAD_DIR) {
        &logr(" .. Creating $PSAD_DIR\n");
        mkdir $PSAD_DIR, 0500;
    }
    unless (-e "${PSAD_DIR}/fwdata") {
        &logr(" .. Creating ${PSAD_DIR}/fwdata file\n");
        open F, "> ${PSAD_DIR}/fwdata" or die " ** Could not open ",
            "${PSAD_DIR}/fwdata: $!";
        close F;
        chmod 0600, "${PSAD_DIR}/fwdata";
        &perms_ownership("${PSAD_DIR}/fwdata", 0600);
    }

    unless (-d $USRSBIN_DIR) {
        &logr(" .. Creating $USRSBIN_DIR\n");
        mkdir $USRSBIN_DIR,0755;
    }
    if (-d 'whois') {
        &logr(" .. Compiling Marco d'Itri's whois client\n");
        system "$Cmds{'make'} -C whois";
        if (-e 'whois/whois') {
            &logr(" .. Copying whois binary to $WHOIS_PSAD\n");
            copy "whois/whois", $WHOIS_PSAD;
        } else {
            die " ** Could not compile whois";
        }
    }
    &perms_ownership($WHOIS_PSAD, 0755);
    print "\n\n";

    ### installing Unix::Syslog
    &logr(" .. Installing the Unix::Syslog (0.100) perl module\n");
    chdir 'Unix-Syslog' or die " ** Could not chdir to ",
        "Unix-Syslog: $!";
    unless (-e 'Makefile.PL' && -e 'Syslog.pm') {
        die " ** Your source directory appears to be incomplete!  Syslog.pm ",
            "is missing.\n    Download the latest sources from ",
            "http://www.cipherdyne.org\n";
    }
    system "$Cmds{'perl'} Makefile.PL PREFIX=$LIBDIR LIB=$LIBDIR";
    system $Cmds{'make'};
#    system "$Cmds{'make'} test";
    system "$Cmds{'make'} install";
    chdir '..';
    print "\n\n";

    ### installing Bit::Vector
    &logr(" .. Installing the Bit::Vector (6.3) perl module\n");
    chdir 'Bit-Vector' or die " ** Could not chdir to ",
        "Bit-Vector: $!";
    unless (-e 'Makefile.PL') {
        die " ** Your source directory appears to be incomplete!  Bit-Vector ",
            "is missing.\n    Download the latest sources from ",
            "http://www.cipherdyne.org\n";
    }
    system "$Cmds{'perl'} Makefile.PL PREFIX=$LIBDIR LIB=$LIBDIR";
    system $Cmds{'make'};
#    system "$Cmds{'make'} test";
    system "$Cmds{'make'} install";
    chdir '..';
    print "\n\n";

    ### installing Date::Calc
    &logr(" .. Installing the Date::Calc (5.3) perl module\n");
    chdir 'Date-Calc' or die " ** Could not chdir to ",
        "Date-Calc: $!";
    unless (-e 'Makefile.PL') {
        die " ** Your source directory appears to be incomplete!  Date::Calc ",
            "is missing.\n    Download the latest sources from ",
            "http://www.cipherdyne.org\n";
    }
    system "$Cmds{'perl'} Makefile.PL PREFIX=$LIBDIR LIB=$LIBDIR";
    system $Cmds{'make'};
#    system "$Cmds{'make'} test";
    system "$Cmds{'make'} install";
    chdir '..';
    print "\n\n";

    ### installing Net::IPv4Addr
    &logr(" .. Installing the Net::IPv4Addr (0.10) perl module\n");
    chdir 'Net-IPv4Addr' or die " ** Could not chdir to ",
        "Net-IPv4Addr: $!";
    unless (-e 'Makefile.PL') {
        die " ** Your source directory appears to be incomplete!  ",
            "Net::IPv4Addr is missing.\n    Download the latest sources " .
            "from http://www.cipherdyne.org\n";
    }
    system "$Cmds{'perl'} Makefile.PL PREFIX=$LIBDIR LIB=$LIBDIR";
    system $Cmds{'make'};
#    system "$Cmds{'make'} test";
    system "$Cmds{'make'} install";
    chdir '..';
    print "\n\n";

    ### installing IPTables::Parse
    &logr(" .. Installing the IPTables::Parse (0.10) perl module\n");
    chdir 'IPTables/Parse' or die " ** Could not chdir to ",
        "IPTables/Parse: $!";
    unless (-e 'Makefile.PL') {
        die " ** Your source directory appears to be incomplete!  ",
            "IPTables::Parse is missing.\n    Download the latest sources " .
            "from http://www.cipherdyne.org\n";
    }
    system "$Cmds{'perl'} Makefile.PL PREFIX=$LIBDIR LIB=$LIBDIR";
    system $Cmds{'make'};
#    system "$Cmds{'make'} test";
    system "$Cmds{'make'} install";
    chdir '../..';
    print "\n\n";

    ### installing Psad.pm
    &logr(" .. Installing the Psad.pm perl module\n");

    chdir 'Psad';
    unless (-e 'Makefile.PL' && -e 'Psad.pm') {
        die " ** Your source distribution appears to be incomplete!  ",
            "Psad.pm is missing.\n    Download the latest sources from ",
            "http://www.cipherdyne.org\n";
    }
    system "$Cmds{'perl'} Makefile.PL PREFIX=$LIBDIR LIB=$LIBDIR";
    system  $Cmds{'make'};
    system "$Cmds{'make'} test";
    system "$Cmds{'make'} install";
    chdir '..';

    &logr(" .. Installing snort-2.0 signatures in $SNORT_DIR\n");
    unless (-d $SNORT_DIR) {
        mkdir $SNORT_DIR, 0500 or die " ** Could not create $SNORT_DIR: $!";
    }
    opendir D, 'snort_rules' or die " ** Could not open ",
        'the snort_rules directory';
    my @rfiles = readdir D;
    closedir D;
    shift @rfiles; shift @rfiles;
    for my $rfile (@rfiles) {
        next unless $rfile =~ /\.rules$/;
        &logr(" .. Installing snort_rules/${rfile}\n");
        copy "snort_rules/${rfile}", "${SNORT_DIR}/${rfile}";
    }
    print "\n\n";

    &logr(" .. Compiling kmsgsd, and psadwatchd:\n");

    ### remove any previously compiled kmsgsd
    unlink 'kmsgsd' if -e 'kmsgsd';

    ### remove any previously compiled psadwatchd
    unlink 'psadwatchd' if -e 'psadwatchd';

    ### compile the C psad daemons
    system $Cmds{'make'};
    if (! -e 'kmsgsd' && -e 'kmsgsd.pl') {
        &logr(" ** Could not compile kmsgsd.c.  Installing perl kmsgsd.\n");
        unless (((system "$Cmds{'perl'} -c kmsgsd.pl")>>8) == 0) {
            die " ** kmsgsd.pl does not compile with \"perl -c\".  ",
                "Download the latest sources " .
                "from:\n\nhttp://www.cipherdyne.org\n";
        }
        copy 'kmsgsd.pl', 'kmsgsd';
    }
    if (! -e 'psadwatchd' && -e 'psadwatchd.pl') {
        &logr(" ** Could not compile psadwatchd.c.  " .
            "Installing perl psadwatchd.\n");
        unless (((system "$Cmds{'perl'} -c psadwatchd.pl")>>8) == 0) {
            die " ** psadwatchd.pl does not compile with \"perl -c\".  ",
                "Download the latest sources " .
                "from:\n\nhttp://www.cipherdyne.org\n";
        }
        copy 'psadwatchd.pl', 'psadwatchd';
    }

    ### install fwcheck_psad.pl
    print "\n\n";
    &logr(" .. Verifying compilation of fwcheck_psad.pl script:\n");
    unless (((system "$Cmds{'perl'} -c fwcheck_psad.pl")>>8) == 0) {
        die " ** fwcheck_psad.pl does not compile with \"perl -c\".  Download ",
            "the latest sources from:\n\nhttp://www.cipherdyne.org\n";
    }

    ### make sure the psad (perl) daemon compiles.  The other three
    ### daemons have all been re-written in C.
    &logr(" .. Verifying compilation of psad perl daemon:\n");
    unless (((system "$Cmds{'perl'} -c psad")>>8) == 0) {
        die " ** psad does not compile with \"perl -c\".  Download the",
            " latest sources from:\n\nhttp://www.cipherdyne.org\n";
    }
    print "\n\n";

    ### put the fwcheck_psad.pl script in place
    &logr(" .. Copying fwcheck_psad.pl -> ${USRSBIN_DIR}/fwcheck_psad\n");
    unlink "${USRSBIN_DIR}/fwcheck_psad" if -e "${USRSBIN_DIR}/fwcheck_psad";
    copy 'fwcheck_psad.pl', "${USRSBIN_DIR}/fwcheck_psad";
    &perms_ownership("${USRSBIN_DIR}/fwcheck_psad", 0500);

    ### put the psad daemons in place
    &logr(" .. Copying psad -> ${USRSBIN_DIR}/psad\n");
    unlink "${USRSBIN_DIR}/psad" if -e "${USRSBIN_DIR}/psad";
    copy 'psad', "${USRSBIN_DIR}/psad";
    &perms_ownership("${USRSBIN_DIR}/psad", 0500);

    &logr(" .. Copying psadwatchd -> ${USRSBIN_DIR}/psadwatchd\n");
    unlink "${USRSBIN_DIR}/psadwatchd" if -e "${USRSBIN_DIR}/psadwatchd";
    copy 'psadwatchd', "${USRSBIN_DIR}/psadwatchd";
    &perms_ownership("${USRSBIN_DIR}/psadwatchd", 0500);

    &logr(" .. Copying kmsgsd -> ${USRSBIN_DIR}/kmsgsd\n");
    unlink "${USRSBIN_DIR}/kmsgsd" if -e "${USRSBIN_DIR}/kmsgsd";
    copy 'kmsgsd', "${USRSBIN_DIR}/kmsgsd";
    &perms_ownership("${USRSBIN_DIR}/kmsgsd", 0500);

    unless (-d $PSAD_CONFDIR) {
        &logr(" .. Creating $PSAD_CONFDIR\n");
        mkdir $PSAD_CONFDIR,0500;
    }
    my $preserve_rv = 0;
    if (-e "${PSAD_CONFDIR}/psad.conf") {
        $preserve_rv = &query_preserve_config();
    }

    ### the order of the config files is important (legacy FW_MSG_SEARCH
    ### vars in psad.conf).
    for my $file qw(psad.conf psadwatchd.conf
            kmsgsd.conf fw_search.conf) {
        if (-e "${PSAD_CONFDIR}/$file") {
            &archive("${PSAD_CONFDIR}/$file") unless $noarchive;
            if ($preserve_rv) {
                &preserve_config($file);
            } else {
                &logr(" .. Copying $file -> ${PSAD_CONFDIR}/$file\n");
                copy $file, "${PSAD_CONFDIR}/$file";
                &perms_ownership("${PSAD_CONFDIR}/$file", 0600);
            }
            if ($file eq 'fw_search.conf' and @old_fw_msg_search) {
                &logr(" ** Warning: psad.conf contains FW_MSG_SEARCH vars, " .
                    "but fw_search.conf also exists!\n");
            }
        } else {
            &logr(" .. Copying $file -> ${PSAD_CONFDIR}/$file\n");
            copy $file, "${PSAD_CONFDIR}/$file";
            &perms_ownership("${PSAD_CONFDIR}/$file", 0600);

            ### Deal with legacy FW_MSG_SEARCH in psad.conf.  Note that
            ### this will only preserve old search strings if 1) they already
            ### existed within psad.conf and 2) the file fw_search.conf does
            ### not already exist in /etc/psad/.
            if ($file eq 'fw_search.conf' and @old_fw_msg_search) {
                &preserve_old_fw_msg_search();
            }
        }
    }

    ### deal with any legacy diskmond.conf file
    if (-e "${PSAD_CONFDIR}/diskmond.conf") {
        &archive("${PSAD_CONFDIR}/diskmond.conf") unless $noarchive;
        unlink "${PSAD_CONFDIR}/diskmond.conf";
    }

    ### deal with psad_auto_ips, psad_signatures,
    ### psad_icmp_types, and psad_posf
    for my $file qw(psad_signatures psad_icmp_types
            psad_posf psad_auto_ips) {
        if (-e "${PSAD_CONFDIR}/$file") {
            &archive("${PSAD_CONFDIR}/$file") unless $noarchive;
            unless (&query_preserve_sigs_autoips("${PSAD_CONFDIR}/$file")) {
                ### keep the installed file intact (the user must have
                ### modified it).
                &logr(" .. Copying $file -> ${PSAD_CONFDIR}/$file\n");
                copy $file, "${PSAD_CONFDIR}/$file";
                &perms_ownership("${PSAD_CONFDIR}/$file", 0600);
            }
        } else {
            &logr(" .. Copying $file -> ${PSAD_CONFDIR}/$file\n");
            copy $file, "${PSAD_CONFDIR}/$file";
            &perms_ownership("${PSAD_CONFDIR}/$file", 0600);
        }
    }
    &logr("\n");

    if (-x $Cmds{'iptables'}) {
        &logr(" .. Found iptables.  Testing syslog configuration:\n");
        ### make sure we actually see packets being logged by
        ### the firewall.
        &test_syslog_config();
    }

    unless ($preserve_rv) {  ### we want to preserve the existing config
        my $email_str = &query_email();
        if ($email_str) {
            for my $file qw(psad.conf psadwatchd.conf
                    kmsgsd.conf) {
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
                or die " ** Could not open ${PSAD_CONFDIR}/fw_search.conf: $!";
            my @lines = <F>;
            close F;
            open T, "> ${PSAD_CONFDIR}/fw_search.conf.tmp"
                or die " ** Could not open ${PSAD_CONFDIR}/fw_search.conf.tmp: $!";
            for my $line (@lines) {
                if ($line =~ /^\s*FW_MSG_SEARCH/) {
                    last;
                } else {
                    print T $line;
                }
            }
            for my $fw_str (@$fw_search_aref) {
                &logr(qq{ .. Setting FW_MSG_SEARCH to "$fw_str" } .
                    "in ${PSAD_CONFDIR}/fw_search.conf\n");
                printf T "%-28s%s;\n", 'FW_MSG_SEARCH', $fw_str;
            }
            close T;
            move "${PSAD_CONFDIR}/fw_search.conf.tmp",
                "${PSAD_CONFDIR}/fw_search.conf";
        }
        ### Give the admin the opportunity to set the HOME_NET variable.
        &set_home_net("${PSAD_CONFDIR}/psad.conf");
    }
    for my $file ("${PSAD_CONFDIR}/psad.conf",
            "${PSAD_CONFDIR}/kmsgsd.conf",
            "${PSAD_CONFDIR}/psadwatchd.conf") {
        &logr(" .. Setting hostname to \"$HOSTNAME\" in $file\n");
        &set_hostname($file);
    }

    ### see if there are any "_CHANGEME_" strings left and give the
    ### admin a chance to correct (this can happen if a new config
    ### variable is introduced in a new version of psad but the
    ### admin chose to preserve the old config).
    for my $file ("${PSAD_CONFDIR}/psad.conf",
            "${PSAD_CONFDIR}/kmsgsd.conf",
            "${PSAD_CONFDIR}/psadwatchd.conf") {
        open F, "< $file" or die " ** Could not open file: $file\n";
        my @lines = <F>;
        close F;
        for my $line (@lines) {
            next if $line =~ /^\s*#/;
            if ($line =~ /^\s*(\S+)\s+_?CHANGE.?ME_?\;/) {
                my $var = $1;
                ### only two possible vars are set to _CHANGEME_ by
                ### default as of psad-1.3
                if ($var eq 'HOME_NET') {
                    &logr(" ** HOME_NET is not defined in $file.\n");
                    &set_home_net("${PSAD_CONFDIR}/psad.conf");
                }
                if ($var eq 'HOSTNAME') {
                    &logr(" ** set_hostname() failed.  Edit the HOSTNAME " .
                        " variable in $file\n");
                }
            }
        }
    }

    ### make sure the PSAD_DIR and PSAD_FIFO variables are correctly defined
    ### in the config file.
    &put_string('PSAD_DIR', $PSAD_DIR, "${PSAD_CONFDIR}/psad.conf");
    &put_string('PSAD_FIFO', $PSAD_FIFO, "${PSAD_CONFDIR}/kmsgsd.conf");

    &install_manpage('psad.8');
    &install_manpage('psadwatchd.8');
    &install_manpage('kmsgsd.8');

    my $init_file = '';
    if ($distro eq 'redhat') {
        $init_file = 'psad-init.redhat';
    } elsif ($distro eq 'gentoo') {
        $init_file = 'psad-init.gentoo';
    } else {
        $init_file = 'psad-init.generic';
    }

    if ($init_dir) {
        &logr(" .. Copying $init_file -> ${init_dir}/psad\n");
        copy $init_file, "${init_dir}/psad";
        &perms_ownership("${init_dir}/psad", 0744);
        &enable_psad_at_boot($distro);
    }

    my $running;
    my $pid;
    if (-e "${RUNDIR}/psad.pid") {
        open PID, "< ${RUNDIR}/psad.pid" or die " ** Could not open ",
            "${RUNDIR}/psad.pid: $!";
        $pid = <PID>;
        close PID;
        chomp $pid;
        $running = kill 0, $pid;
    } else {
        $running = 0;
    }
    &logr("\n========================================================\n");
    if ($preserve_rv) {
        &logr("\n .. Psad has been installed (with your original config).\n");
    } else {
        &logr("\n .. Psad has been installed.\n");
    }
    if ($running) {
        &logr("\n");
        &logr(" .. An older version of psad is already running.  To ".
            "start the new version, run \"${USRSBIN_DIR}/psad --Restart\"\n");
    } else {
        if ($init_dir) {
            &logr("\n .. To execute psad, run \"${init_dir}/psad start.\"\n");
        } else {
            &logr("\n .. To execute psad, run ${USRSBIN_DIR}/psad.\"\n");
        }
    }
    return;
}

sub uninstall() {
    &logr("\n .. Uninstalling psad from $HOSTNAME: " . localtime() . "\n");

    my $ans = '';
    while ($ans ne 'y' && $ans ne 'n') {
        print wrap('', $SUB_TAB, ' .. This will completely remove psad ' .
            "from your system.\n    Are you sure (y/n)? ");
        $ans = <STDIN>;
        chomp $ans;
    }
    if ($ans eq 'n') {
        &logr(" ** User aborted uninstall by answering \"n\" to the remove " .
            "question!  Exiting.\n");
        exit 0;
    }
    ### after this point, psad will really be uninstalled so stop writing stuff
    ### to the install.log file.  Just print everything to STDOUT
    if (-e "${RUNDIR}/psad.pid") {
        open PID, "${RUNDIR}/psad.pid" or die " ** Could not open ",
            "${RUNDIR}/psad.pid: $!";
        my $pid = <PID>;
        close PID;
        chomp $pid;
        if (kill 0, $pid) {
            print " .. Stopping psad daemons!\n";
            if (-e "${init_dir}/psad") {  ### prefer this for old versions
                system "${init_dir}/psad stop";
            } else {
                system "${USRSBIN_DIR}/psad --Kill";
            }
        }
    }
    if (-e "${USRSBIN_DIR}/psad") {
        print wrap('', $SUB_TAB, " .. Removing psad daemons: ${USRSBIN_DIR}/" .
            "(psad, psadwatchd, kmsgsd)\n");
        unlink "${USRSBIN_DIR}/psad" or
            warn " **  Could not remove ${USRSBIN_DIR}/psad!!!\n";
        unlink "${USRSBIN_DIR}/psadwatchd" or
            warn " **  Could not remove ${USRSBIN_DIR}/psadwatchd!!!\n";
        unlink "${USRSBIN_DIR}/kmsgsd" or
            warn " **  Could not remove ${USRSBIN_DIR}/kmsgsd!!!\n";
    }
    if (-e "${init_dir}/psad") {
        print " .. Removing ${init_dir}/psad\n";
        unlink "${init_dir}/psad";
    }
    if (-e "${PERL_INSTALL_DIR}/Psad.pm") {
        print " ----  Removing ${PERL_INSTALL_DIR}/Psad.pm  ----\n";
        unlink "${PERL_INSTALL_DIR}/Psad.pm";
    }
    if (-d $PSAD_CONFDIR) {
        print " .. Removing configuration directory: $PSAD_CONFDIR\n";
        rmtree($PSAD_CONFDIR, 1, 0);
    }
    if (-d $PSAD_DIR) {
        print " .. Removing logging directory: $PSAD_DIR\n";
        rmtree($PSAD_DIR, 1, 0);
    }
    if (-e $PSAD_FIFO) {
        print " .. Removing named pipe: $PSAD_FIFO\n";
        unlink $PSAD_FIFO;
    }
    ### remove old whois binary location
    if (-e '/usr/bin/whois.psad') {
        print " .. Removing $WHOIS_PSAD\n";
        unlink $WHOIS_PSAD;
    }
    if (-e $WHOIS_PSAD) {
        print " .. Removing $WHOIS_PSAD\n";
        unlink $WHOIS_PSAD;
    }
    if (-d $VARLIBDIR) {
        print " .. Removing $VARLIBDIR\n";
        rmtree $VARLIBDIR;
    }
    if (-d $RUNDIR) {
        print " .. Removing $RUNDIR\n";
        rmtree $RUNDIR;
    }
    if (-d $LIBDIR) {
        print " .. Removing $LIBDIR\n";
        rmtree $LIBDIR;
    }
    print " .. Restoring /etc/syslog.conf.orig -> /etc/syslog.conf\n";
    if (-e '/etc/syslog.conf.orig') {
        move('/etc/syslog.conf.orig', '/etc/syslog.conf');
    } else {
        print wrap('', $SUB_TAB, " .. /etc/syslog.conf.orig does not exist. " .
            " Editing /etc/syslog.conf directly.\n");
        open ESYS, '< /etc/syslog.conf' or
            die " **  Unable to open /etc/syslog.conf: $!\n";
        my @sys = <ESYS>;
        close ESYS;
        open CSYS, '> /etc/syslog.conf' or die " ** Could not open ",
            "/etc/syslog.conf: $!";
        for my $line (@sys) {
            chomp $line;
            ### don't print the psadfifo line
            print CSYS "$line\n" if ($line !~ /psadfifo/);
        }
        close CSYS;
    }
    print " .. Restarting syslog.\n";
    system "$Cmds{'killall'} -HUP syslogd";
    print "\n";
    print " .. Psad has been uninstalled!\n";

    return;
}

sub set_home_net() {
    my $file = shift;
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
            $connected_subnets{$intf_name} = "$1/$2";
            $net_ctr++;
        }
    }
    if ($net_ctr > 1) {
        ### found two or more subnets, so forwarding traffic becomes
        ### possible through the box.
        &logr(" .. It appears your machine is connected to " .
            "$net_ctr subnets:\n");
        for my $intf (keys %connected_subnets) {
            &logr("      $intf -> $connected_subnets{$intf}\n");
        }
        &logr("\n");
        &logr("    Specify which subnets are part of your internal network.\n");
        &logr("    Note that you can correct anything you enter here by " .
            "editing\n");
        &logr("    the HOME_NET variable in: $file.\n");
        &logr("    Enter each of the subnets (except for the external " .
            "subnet)\n");
        &logr("    on a line by itself.\n");
        &logr("    Each of the subnets should be in the form <net>/<mask.\n");
        &logr("    E.g. in CIDR notation: 192.168.10.0/24 (preferrable), or\n");
        &logr("    regularly: 192.168.10.0/255.255.255.0\n\n");
        &logr("    End with a \".\" on a line by itself.\n\n");
        my $ans = '';
        while ($ans ne '.') {
            &logr("    Subnet: ");
            $ans = <STDIN>;
            chomp $ans;
            if ($ans =~ m|^\s*($ip_re/\d+)\s*$|) {
                ### hard to test this directly without ipv4_network()
                ### and this module may not be installed, so just use it.
                $home_net_str .= "$1, ";
            } elsif ($ans =~ m|^\s*($ip_re/$ip_re)\s*$|) {
                $home_net_str .= "$1, ";
            } elsif ($ans ne '.') {
                &logr(" ** Invalid subnet \"$ans\"\n");
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

sub set_hostname() {
    my $file = shift;
    if (-e $file) {
        open P, "< $file" or die " ** Could not open $file: $!";
        my @lines = <P>;
        close P;
        ### replace the "HOSTNAME           CHANGE_ME" line
        open PH, "> $file" or die " ** Could not open $file: $!";
        for my $line (@lines) {
            chomp $line;
            if ($line =~ /^\s*HOSTNAME(\s+)_?CHANGE.?ME_?/) {
                print PH "HOSTNAME${1}$HOSTNAME;\n";
            } else {
                print PH "$line\n";
            }
        }
        close PH;
    } else {
        die " ** Your source directory appears to be incomplete!  $file ",
            "is missing.\n    Download the latest sources from ",
            "http://www.cipherdyne.org\n";
    }
    return;
}

sub append_fifo_syslog_ng() {
    &logr(' .. Modifying /etc/syslog-ng/syslog-ng.conf to write kern.info ' .
        "messages to $PSAD_FIFO\n");
    unless (-e '/etc/syslog-ng/syslog-ng.conf.orig') {
        copy '/etc/syslog-ng/syslog-ng.conf',
            '/etc/syslog-ng/syslog-ng.conf.orig';
    }
    &archive('/etc/syslog-ng/syslog-ng.conf');
    open RS, '< /etc/syslog-ng/syslog-ng.conf' or
        die " **  Unable to open /etc/syslog-ng/syslog-ng.conf: $!\n";
    my @slines = <RS>;
    close RS;

    my $found_fifo = 0;
    for my $line (@slines) {
        $found_fifo = 1 if ($line =~ /psadfifo/);
    }

    unless ($found_fifo) {
        open SYSLOGNG, '>> /etc/syslog-ng/syslog-ng.conf' or
            die " ** Unable to open /etc/syslog-ng/syslog-ng.conf: $!\n";
        print SYSLOGNG "\n";
        print SYSLOGNG "destination psadpipe { pipe(\"/var/run/psadfifo\"); };\n";
        print SYSLOGNG "filter f_kerninfo { facility(kern) and level(info); };\n";
        print SYSLOGNG "log { source(src); filter(f_kerninfo); destination(psadpipe); };\n";
        close SYSLOGNG;
    }
    return;
}

sub config_metalog() {
    unless (-e '/etc/metalog/metalog.conf.orig') {
        copy '/etc/metalog/metalog.conf',
            '/etc/metalog/metalog.conf.orig'
    }
    open RS, "< /etc/metalog/metalog.conf" or
        die " ** Unable to open /etc/metalog/metalog.conf: $!\n";
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
        open METALOG, "> /etc/metalog/metalog.conf" or
            die " ** Unable to open /etc/metalog/metalog.conf: $!";

        print METALOG "\n";
        print METALOG "\nPSAD :\n",
            "  facility = \"kern\"\n";
        print METALOG '  command  = ',
            "\"/usr/sbin/psadpipe.sh\"\n";
        close METALOG;
        &Psad::psyslog('psad', '.. reconfiguring metalog to write ' .
                "kern-facility messages to /usr/sbin/psadpipe.sh");

        open PIPESCRIPT, '> /usr/sbin/psadpipe.sh' or
            die " ** Unable to open /usr/sbin/psadpipe.sh: $!";
        print PIPESCRIPT "#!/bin/sh\n\n";
        print PIPESCRIPT "echo \"\$3\" >> $PSAD_FIFO\n";
        close PIPESCRIPT;
        chmod 0700, '/usr/sbin/psadpipe.sh';
        &logr(' .. Generated /usr/sbin/psadpipe.sh ' .
            "which writes to $PSAD_FIFO");

        ### (Dennis Freise <cat@final-frontier.ath.cx>)
        ### Metalog seems to simply die on SIGHUP and SIGALRM, and I
        ### found no signal or option to reload it's config... :-(
        &logr(' ** All files written. You have to manually restart metalog! ',
            'When done, start psad again.');
    }
    return;
}

sub query_preserve_config() {
    my $ans = '';
    while ($ans ne 'y' && $ans ne 'n') {
        &logr(' .. Would you like to preserve the config from the ' .
            'existing psad installation ([y]/n)?  ');
        $ans = <STDIN>;
        $ans = 'y' if $ans eq "\n";
        chomp $ans;
    }
    if ($ans eq 'y') {
        return 1;
    }
    return 0;
}

sub query_preserve_sigs_autoips() {
    my $file = shift;
    my $ans = '';
    while ($ans ne 'y' && $ans ne 'n') {
        &logr("\n");
        &logr(" .. Preserve the existing $file file?\n");
        &logr('    (NOTE: This is only recommended if you have manually ' .
            "edited $file)  (y/[n])?  ");
        $ans = <STDIN>;
        $ans = 'n' if $ans eq "\n";
        chomp $ans;
    }
    if ($ans eq 'y') {
        return 1;
    }
    return 0;
}

sub preserve_old_fw_msg_search() {
    open F, "< ${PSAD_CONFDIR}/fw_search.conf" or die " ** Could not open ",
        "${PSAD_CONFDIR}/fw_search.conf: $!";
    my @orig_lines = <F>;
    close F;

    &logr(" .. Preserving old FW_MSG_SEARCH values: " .
        "${PSAD_CONFDIR}/fw_search.conf\n");

    open CONF, "> ${PSAD_CONFDIR}/fw_search.conf.new" or
        die " ** Could not open ${PSAD_CONFDIR}/fw_search.conf.new: $!";

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
    move "${PSAD_CONFDIR}/fw_search.conf.new", "${PSAD_CONFDIR}/fw_search.conf";
    return;
}

sub preserve_config() {
    my $file = shift;
    open C, "< $file" or die " ** Could not open $file: $!";
    my @new_lines = <C>;
    close C;

    open CO, "< ${PSAD_CONFDIR}/$file" or die " ** Could not open ",
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

    &logr(" .. Preserving existing config: ${PSAD_CONFDIR}/$file\n");
    ### write to a tmp file and then move so any running psad daemon will
    ### re-import a full config file if a HUP signal is received during
    ### the install.
    open CONF, "> ${PSAD_CONFDIR}/${file}.new" or die " ** Could not open ",
        "${PSAD_CONFDIR}/${file}.new: $!";
    for my $new_line (@new_lines) {
        if ($new_line =~ /^\s*#/) {
            print CONF $new_line;
        } elsif ($new_line =~ /^\s*(\S+)/) {
            my $var = $1;
            my $found = 0;
            for my $orig_line (@orig_lines) {
                if ($orig_line =~ /^\s*$var\s/) {
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
    move "${PSAD_CONFDIR}/${file}.new", "${PSAD_CONFDIR}/$file";
    return;
}

sub append_fifo_syslog() {
    &logr(' .. Modifying /etc/syslog.conf to write kern.info ' .
        "messages to $PSAD_FIFO\n");
    unless (-e '/etc/syslog.conf.orig') {
        copy '/etc/syslog.conf', '/etc/syslog.conf.orig';
    }
    &archive('/etc/syslog.conf');
    open RS, '< /etc/syslog.conf' or
        die " **  Unable to open /etc/syslog.conf: $!\n";
    my @slines = <RS>;
    close RS;
    open SYSLOG, '> /etc/syslog.conf' or
        die " **  Unable to open /etc/syslog.conf: $!\n";
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
    return;
}

sub hup_syslog() {
    my @ps_out = `$Cmds{'ps'} -auxww`;
    for my $line (@ps_out) {
        ### root  416  0.0  0.3  1476  624 ?  S  10:11   0:00 syslogd -m 0
        if ($line =~ /^\S+\s+(\d+)(?:\s+\S+){8}\s+syslog/) {
            kill 1, $1;  ### "kill -l" => signal 1 = HUP
        }
    }
    return;
}

sub test_syslog_config() {
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
        &logr(" ** Could not bring up the loopback interface.\n" .
            "    Hoping the syslog reconfig will work anyway.\n");
        return;
    }

    ### make sure we can see the loopback interface with
    ### ifconfig
    my @if_out = `$Cmds{'ifconfig'} lo`;

    unless (@if_out) {
        &logr(" ** Could not see the loopback interface " .
            "with ifconfig.\n         Hoping syslog reconfig " .
            "will work anyway.\n");
        return;
    }

    my $lo_ip = '127.0.0.1';
    my $found_ip = 0;
    for my $line (@if_out) {
        if ($line =~ /inet\s+addr:($ip_re)\s/) {
            $lo_ip = $1;  ### this should always be 127.0.0.1
            &logr(" ** loopback interface ip is not 127.0.0.1.  Continuing ".
                "anyway.\n") unless $lo_ip eq '127.0.0.1';
            $found_ip = 1;
        }
    }

    unless ($found_ip) {
        &logr(" ** The loopback interface does not have an ip.\n" .
            "    Hoping the syslog reconfig will work anyway.\n");
        return;
    }

    ### remove any "test_DROP" lines from fwdata before
    ### seeing if new ones can be written
    &scrub_fwdata();

    my $start_kmsgsd = 1;
    if (-e "${RUNDIR}/kmsgsd.pid") {
        open PID, "< ${RUNDIR}/kmsgsd.pid" or die " ** Could not open ",
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
            &logr(" ** Could not start kmsgsd to test syslog.\n" .
                "    Send email to Michael Rash (mbr\@cipherdyne.org)\n");
            return;
        }
    }

    ### insert a rule to deny traffic to the loopback
    ### interface on $test_port
    system "$Cmds{'iptables'} -I INPUT 1 -i lo -p tcp --dport " .
        "$test_port -j LOG --log-prefix \"test_DROP \"";

    open FWDATA, "${PSAD_DIR}/fwdata" or
        die " ** Could not open ${PSAD_DIR}/fwdata: $!";

    ### try to connect to $test_port to generate an iptables
    ### drop message.  Note that since nothing is listening on
    ### the port we will immediately receive a tcp reset.
    my $sock = new IO::Socket::INET(
        'PeerAddr' => $lo_ip,
        'PeerPort' => $test_port,
        'Proto'    => 'tcp',
        'Timeout'  => 5
    );

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
    &scrub_fwdata();

    if ($found) {
        &logr(" .. Successful syslog reconfiguration.\n");
    } else {
        &logr(" ** unsuccessful syslog reconfiguration.\n");
        &logr("         Consult the psad man page for the basic " .
            "syslog requirement to get psad to work.\n");
    }

    if ($start_kmsgsd && -e "${RUNDIR}/kmsgsd.pid") {
        open PID, "${RUNDIR}/kmsgsd.pid" or return;
        my $pid = <PID>;
        close PID;
        chomp $pid;
        if (kill 0, $pid) {
            kill 9, $pid;
        }
    }
    return;
}

sub scrub_fwdata() {
    open SCRUB, "< ${PSAD_DIR}/fwdata" or
        die " ** Could not open ${PSAD_DIR}/fwdata: $!";
    my @lines = <SCRUB>;
    close SCRUB;

    open SCRUB, "> ${PSAD_DIR}/fwdata" or
        die " ** Could not open ${PSAD_DIR}/fwdata: $!";
    for my $line (@lines) {
        print SCRUB $line unless $line =~ /test_DROP/;
    }
    close SCRUB;
    return;
}

sub check_old_psad_installation() {
    my $old_install_dir = '/usr/local/bin';
    if (-e "${old_install_dir}/psad") {
        move "${old_install_dir}/psad", "${USRSBIN_DIR}/psad";
    }
    if (-e "${old_install_dir}/psadwatchd") {
        move "${old_install_dir}/psadwatchd", "${USRSBIN_DIR}/psadwatchd";
    }
    if (-e "${old_install_dir}/kmsgsd") {
        move "${old_install_dir}/kmsgsd", "${USRSBIN_DIR}/kmsgsd";
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
        if (-e "${USRSBIN_DIR}/psad"
            && system "${USRSBIN_DIR}/psad --Status > /dev/null") {
            ### deal with this later.  The user should be prompted before
            ### the old psadfifo is removed since kmsgsd will have a problem
        } else {
            unlink '/var/log/psadfifo';
        }
    }
    return;
}

sub get_distro() {
    return 'gentoo' if -e '/etc/gentoo-release';
    if (-e '/etc/issue') {
        ### Red Hat Linux release 6.2 (Zoot)
        open ISSUE, '< /etc/issue' or
            die " ** Could not open /etc/issue: $!";
        my @lines = <ISSUE>;
        close ISSUE;
        for my $line (@lines) {
            chomp $line;
            return 'redhat' if $line =~ /red\s*hat/i;
        }
    }
    return 'NA';
}

sub perms_ownership() {
    my ($file, $perm_value) = @_;
    chmod $perm_value, $file or die " ** Could not ",
        "chmod($perm_value, $file): $!";
    ### chown uid, gid, $file  (root :)
    chown 0, 0, $file or die " ** Could not chown 0,0,$file: $!";
    return;
}

sub get_fw_search_strings() {
    my @fw_search_strings = ();

        print
"\n .. By default psad parses all iptables log messages for scan activity.\n",
"    However, psad can be configured to only parse those iptables messages\n",
"    that match particular strings (that are specified in your iptables\n",
"    ruleset with the --log-prefix option).\n";

    my $ans = '';
    while ($ans ne 'y' and $ans ne 'n') {
        print
"\n    Would you like psad to only parse specific strings in iptables\n",
"    messages (y/[n])?  ";
        $ans = <STDIN>;
        if ($ans eq "\n") {  ### allow the default answer to take over
            $ans = 'n';
        }
        chomp $ans;
    }
    print "\n";

    if ($ans eq 'y') {
        print
"\n .. psad checks the firewall configuration on the underlying machine\n",
"    to see if packets will be logged and dropped that have not\n",
"    explicitly allowed through.  By default psad looks for the string\n",
"    \"DROP\". However, if your particular firewall configuration logs\n",
"    blocked packets with the string \"Audit\" for example, psad can be\n",
"    configured here to look for this string.  In addition, psad can also\n",
"    be configured here to look for multiple strings if needed.  Remember,\n",
"    whatever string you configure psad to look for must be logged via the\n",
"    --log-prefix option in iptables.\n\n";
        $ans = '';
        while ($ans ne 'y' and $ans ne 'n') {
            print
"    Would you like to add custom strings that will be used to analyze",
"    firewall log messages?\n",
"    (y/[n])?  ";
            $ans = <STDIN>;
            if ($ans eq "\n") {  ### allow the default answer to take over
                $ans = 'n';
            }
            chomp $ans;
        }
        print "\n";
        if ($ans eq 'y') {
            print "\n";
            &logr(" .. Add as many search strings as you like; " .
                "each on its own line.\n\n");
            &logr("    End with a \".\" on a line by itself.\n\n");
            my $ans = '';
            while ($ans ne '.') {
                &logr("    String (i.e. \"Audit\"):  ");
                $ans = <STDIN>;
                chomp $ans;
                if ($ans =~ /\"/) {
                    &logr(" ** Quotes will be removed from FW search string: $ans\n");
                    $ans =~ s/\"//g;
                }
                if ($ans =~ /\S/) {
                    push @fw_search_strings, $ans;
                } else {
                    &logr(" ** Invalid string **\n");
                }
            }
        }
        &logr("    All firewall search strings used by psad are located " .
            "in the file: $PSAD_CONFDIR/fw_search.conf\n");
    }
    return \@fw_search_strings;
}

sub query_email() {
    my $filename = 'psad.conf';
    my $email_str = '';
    open F, "< ${PSAD_CONFDIR}/psad.conf" or die " ** Could not open ",
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
    &logr(" .. psad alerts will be sent to:\n\n");
    &logr("       $email_addresses\n\n");
    my $ans = '';
    while ($ans ne 'y' and $ans ne 'n') {
        &logr(" .. Would you like alerts sent to a different address ([y]/n)?  ");
        $ans = <STDIN>;
        if ($ans eq "\n") {  ### allow the default of "y" to take over
                             ### when just "Enter" is pressed.
            $ans = 'y';
        }
        chomp $ans;
    }
    print "\n";
    if ($ans eq 'y') {
        print "\n";
        &logr(" .. To which email address(es) would you like " .
            "psad alerts to be sent?\n");
        &logr("    You can enter as many email addresses as you like; " .
            "each on its own line.\n\n");
        &logr("    End with a \".\" on a line by itself.\n\n");
        my $ans = '';
        while ($ans ne '.') {
            &logr("    Email Address: ");
            $ans = <STDIN>;
            chomp $ans;
            if ($ans =~ m|^\s*(\S+\@\S+)$|) {
                $email_str .= "$1, ";
            } elsif ($ans ne '.') {
                &logr(" ** Invalid email address \"$ans\"\n");
            }
        }
        $email_str =~ s/\,\s*$//;
    }
    return $email_str;
}

sub put_string() {
    my ($var, $value, $file) = @_;
    open RF, "< $file" or die " ** Could not open $file: $!";
    my @lines = <RF>;
    close RF;
    open F, "> $file" or die " ** Could not open $file: $!";
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
    my $curr_pwd = cwd();
    chdir $CONF_ARCHIVE or die $!;
    my ($filename) = ($file =~ m|.*/(.*)|);
    my $base = "${filename}.old";
    for (my $i = 5; $i > 1; $i--) {  ### keep five copies of old config files
        my $j = $i - 1;
        unlink "${base}${i}.gz" if -e "${base}${i}.gz";
        move "${base}${j}.gz", "${base}${i}.gz" if -e "${base}${j}.gz";
    }
    &logr(" .. Archiving $file -> ${base}1\n");
    unlink "${base}1.gz" if -e "${base}1.gz";
    copy $file, "${base}1";   ### move $file into the archive directory
    system "$Cmds{'gzip'} ${base}1";
    chdir $curr_pwd or die $!;
    return;
}

sub enable_psad_at_boot() {
    my $distro = shift;
    my $ans = '';
    while ($ans ne 'y' && $ans ne 'n') {
        &logr(" .. Enable psad at boot time ([y]/n)?  ");
        $ans = <STDIN>;
        if ($ans eq "\n") {  ### allow the default of "y" to take over
            $ans = 'y';
        }
        chomp $ans;
    }
    if ($ans eq 'y') {
        if ($distro eq 'redhat') {
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
                open I, '< /etc/inittab' or die " ** Could not open ",
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
                    &logr(" **  Could not determine the runlevel.  Set " .
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
                &logr(" **  /etc/inittab does not exist!  Set the " .
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
    my @path = qw(
        /bin
        /sbin
        /usr/bin
        /usr/sbin
        /usr/local/bin
        /usr/local/sbin
    );
    CMD: for my $cmd (keys %Cmds) {
        unless (-x $Cmds{$cmd}) {
            my $found = 0;
            PATH: for my $dir (@path) {
                if (-x "${dir}/${cmd}") {
                    $Cmds{$cmd} = "${dir}/${cmd}";
                    $found = 1;
                    last PATH;
                }
            }
            unless ($found) {
                die "\n ** Could not find $cmd anywhere!!!  ",
                    "Please edit the config section to include the path to ",
                    "$cmd.\n";
            }
        }
        unless (-x $Cmds{$cmd}) {
            die "\n ** $cmd is located at ",
                "$Cmds{$cmd} but is not executable by uid: $<\n";
        }
    }
    return;
}

sub install_manpage() {
    my $manpage = shift;
    ### remove old man page
    unlink "/usr/local/man/man8/${manpage}" if
        (-e "/usr/local/man/man8/${manpage}");

    ### default location to put the psad man page, but check with
    ### /etc/man.config
    my $mpath = '/usr/share/man/man8';
    if (-e '/etc/man.config') {
        ### prefer to install $manpage in /usr/local/man/man8 if
        ### this directory is configured in /etc/man.config
        open M, '< /etc/man.config' or
            die " ** Could not open /etc/man.config: $!";
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
                    $mpath = '/usr/local/man/man8';
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
    &logr(" .. Installing $manpage man page at $mfile\n");
    copy $manpage, $mfile or die " ** Could not copy $manpage to ",
        "$mfile: $!";
    &perms_ownership($mfile, 0644);
    &logr(" .. Compressing manpage $mfile\n");
    ### remove the old one so gzip doesn't prompt us
    unlink "${mfile}.gz" if -e "${mfile}.gz";
    system "$Cmds{'gzip'} $mfile";
    return;
}

### logging subroutine that handles multiple filehandles
sub logr() {
    my $msg = shift;
    for my $file (@LOGR_FILES) {
        if ($file eq *STDOUT) {
            if (length($msg) > 72) {
                print STDOUT wrap('', $SUB_TAB, $msg);
            } else {
                print STDOUT $msg;
            }
        } elsif ($file eq *STDERR) {
            if (length($msg) > 72) {
                print STDERR wrap('', $SUB_TAB, $msg);
            } else {
                print STDERR $msg;
            }
        } else {
            open F, ">> $file" or die " ** Could not open ",
                "$file: $!";
            if (length($msg) > 72) {
                print F wrap('', $SUB_TAB, $msg);
            } else {
                print F $msg;
            }
            close F;
        }
    }
    return;
}

sub usage() {
        my $exitcode = shift;
        print <<_HELP_;

Usage: install.pl [-n] [-u] [-h]

    -n  --no-preserve   - disable preservation of old configs.
    -u  --uninstall     - uninstall psad.
    -h  --help          - prints this help message.

_HELP_
        exit $exitcode;
}
