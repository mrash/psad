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
# Version: 1.0.0-pre3
#
# Copyright (C) 1999-2002 Michael B. Rash (mbr@cipherdyne.com)
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
#   - make install.pl preserve psad_signatures and psad_auto_ips
#     with "diff" and "patch" from the old to the new.
#
#########################################################################
#
# $Id$
#

use File::Path;
use File::Copy;
use Text::Wrap;
use Sys::Hostname;
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
my $SBIN_DIR     = '/usr/sbin';  ### consistent with FHS (Filesystem
                                 ### Hierarchy Standard)
my $CONF_ARCHIVE = "${PSAD_CONFDIR}/archive";
my @LOGR_FILES   = (*STDOUT, $INSTALL_LOG);
my $RUNLEVEL;    ### This should only be set if install.pl
                 ### cannot determine the correct runlevel
my $WHOIS_PSAD   = '/usr/bin/whois.psad';

### system binaries ###
my $chkconfigCmd = '/sbin/chkconfig';
my $mknodCmd     = '/bin/mknod';
my $makeCmd      = '/usr/bin/make';
my $findCmd      = '/usr/bin/find';
my $killallCmd   = '/usr/bin/killall';
my $perlCmd      = '/usr/bin/perl';
my $ipchainsCmd  = '/sbin/ipchains';
my $iptablesCmd  = '/sbin/iptables';
my $psadCmd      = "${SBIN_DIR}/psad";
#============ end config ============

### get the hostname of the system
my $HOSTNAME = hostname;

### scope these vars
my $PERL_INSTALL_DIR;  ### This is used to find pre-0.9.2 installations of psad

### set the install directory for the Psad.pm module
my $found = 0;
for my $d (@INC) {
    if ($d =~ /site_perl\/\d\S+/) {
        $PERL_INSTALL_DIR = $d;
        $found = 1;
        last;
    }
}
unless ($found) {
    $PERL_INSTALL_DIR = $INC[0];
}

### set the default execution flags
my $SUB_TAB = '     ';
my $nopreserve   = 0;
my $uninstall    = 0;
my $verbose      = 0;
my $help         = 0;

&usage_and_exit(1) unless (GetOptions (
    'no_preserve' => \$nopreserve,    # don't preserve existing configs
    'uninstall'   => \$uninstall,
    'verbose'     => \$verbose,
    'help'        => \$help           # display help
));
&usage_and_exit(0) if ($help);

my %Cmds = (
    'mknod'    => $mknodCmd,
    'find'     => $findCmd,
    'make'     => $makeCmd,
    'killall'  => $killallCmd,
    'perl'     => $perlCmd,
    'ipchains' => $ipchainsCmd,
    'iptables' => $iptablesCmd,
);

my $distro = &get_distro();

### add chkconfig only if we are runing on a redhat distro
if ($distro =~ /redhat/) {
    $Cmds{'chkconfig'} = $chkconfigCmd;
}

### need to make sure this exists before attempting to
### write anything to the install log.
unless (-d $PSAD_DIR) {
    mkdir $PSAD_DIR, 0400;
}

&check_commands(\%Cmds);
$Cmds{'psad'} = $psadCmd;

### check to make sure we are running as root
$< == 0 && $> == 0 or die "You need to be root (or equivalent UID 0" .
                          " account) to install/uninstall psad!\n";

&check_old_psad_installation();  ### check for a pre-0.9.2 installation of psad.

if ($uninstall) {
    &uninstall();
} else {
    &install();
}
exit 0;
#================= end main =================

sub install() {
    ### make sure install.pl is being called from the source directory
    unless (-e 'psad' && -e 'Psad.pm/Psad.pm') {
        die "\n ... @@@  install.pl can only be executed from the directory" .
                       " that contains the psad sources!  Exiting.\n\n";
    }
    my $t = localtime();
    &logr("\n ... Installing psad on $HOSTNAME\n");
    &logr(" ... $t\n");

    unless (-d $RUNDIR) {
        &logr(" ... Creating $RUNDIR\n");
        mkdir $RUNDIR,0400;
    }
    unless (-d $VARLIBDIR) {
        &logr(" ... Creating $VARLIBDIR\n");
        mkdir $VARLIBDIR,0400;
    }
    unless (-d $LIBDIR) {
        &logr(" ... Creating $LIBDIR\n");
        mkdir $LIBDIR,0400;
    }
    unless (-d $PSAD_CONFDIR) {
        &logr(" ... Creating $PSAD_CONFDIR\n");
        mkdir $PSAD_CONFDIR,0400;
    }
    unless (-d $CONF_ARCHIVE) {
        &logr(" ... Creating $CONF_ARCHIVE\n");
        mkdir $CONF_ARCHIVE, 0400;
    }
    unless (-e $PSAD_FIFO) {
        &logr(" ... Creating named pipe $PSAD_FIFO\n");
        ### create the named pipe (die does not seem to work correctly here...
        ### should use the return value of system()).
        `$Cmds{'mknod'} -m 600 $PSAD_FIFO p`;
        unless (-e $PSAD_FIFO) {
            &logr(" ... @@@  Could not create the named pipe \"$PSAD_FIFO\"!" .
                "\n ... @@@  Psad requires this file to exist!  Aborting " .
                "install.\n");
            die;
        }
    }
    &logr(" ... Modifying /etc/syslog.conf to write kern.info " .
        "messages to $PSAD_FIFO\n");
    unless (-e '/etc/syslog.conf.orig') {
        copy('/etc/syslog.conf', '/etc/syslog.conf.orig');
    }
    &archive('/etc/syslog.conf');
    open RS, '< /etc/syslog.conf' or
        die " ... @@@  Unable to open /etc/syslog.conf: $!\n";
    my @slines = <RS>;
    close RS;
    open SYSLOG, '> /etc/syslog.conf' or
        die " ... @@@  Unable to open /etc/syslog.conf: $!\n";
    for my $line (@slines) {
        chomp $line;
        unless ($line =~ /psadfifo/) {
            print SYSLOG "$line\n";
        }
    }
    print SYSLOG "# Send kern.info messages to psadfifo for " .
        "analysis by kmsgsd\n";
    ### reinstate kernel logging to our named pipe
    print SYSLOG "kern.info		|$PSAD_FIFO\n";
    close SYSLOG;
    print " ... Restarting syslog.\n";
    system "$Cmds{'killall'} -HUP syslogd";

    unless (-d $PSAD_DIR) {
        &logr(" ... Creating $PSAD_DIR\n");
        mkdir $PSAD_DIR, 0400;
    }
    unless (-e "${PSAD_DIR}/fwdata") {
        &logr(" ... Creating ${PSAD_DIR}/fwdata file\n");
        open F, "> ${PSAD_DIR}/fwdata";
        close F;
        chmod 0600, "${PSAD_DIR}/fwdata";
        &perms_ownership("${PSAD_DIR}/fwdata", 0600);
    }
    unless (-d $SBIN_DIR) {
        &logr(" ... Creating $SBIN_DIR\n");
        mkdir $SBIN_DIR,0755;
    }
    if (-d 'whois-4.5.31') {
        &logr(" ... Compiling Marco d'Itri's whois client\n");
        system "$Cmds{'make'} -C whois-4.5.31";
        if (-e 'whois-4.5.31/whois') {
            &logr(" ... Copying whois binary to $WHOIS_PSAD\n");
            copy("whois-4.5.31/whois", $WHOIS_PSAD);
        } else {
            die " ... @@@ Could not compile whois-4.5.31";
        }
    }
    &perms_ownership($WHOIS_PSAD, 0755);

    ### installing Psad.pm
    &logr(" ... Installing the Psad.pm perl module\n");

    chdir 'Psad.pm';
    unless (-e 'Makefile.PL' && -e 'Psad.pm') {
        die " ... @@@  Your source distribution appears to be incomplete!  " .
            "Psad.pm is missing.\n        Download the latest sources from " .
            "http://www.cipherdyne.com\n";
    }
    system "$Cmds{'perl'} Makefile.PL PREFIX=$LIBDIR LIB=$LIBDIR";
    system "$Cmds{'make'}";
    system "$Cmds{'make'} test";
    system "$Cmds{'make'} install";
    chdir '..';

    print "\n\n";

    ### installing Unix::Syslog
    &logr(" ... Installing the Unix::Syslog perl module\n");

    chdir 'Unix-Syslog-0.98';
    unless (-e 'Makefile.PL' && -e 'Syslog.pm') {
        die " ... @@@  Your source kit appears to be incomplete!  Syslog.pm " .
            "is missing.\n       Download the latest sources from " .
            "http://www.cipherdyne.com\n";
    }
    system "$Cmds{'perl'} Makefile.PL PREFIX=$LIBDIR LIB=$LIBDIR";
    system "$Cmds{'make'}";
#    system "$Cmds{'make'} test";
    system "$Cmds{'make'} install";
    chdir '..';

    print "\n\n";

    ### make sure all of the psad daemons compile (validates
    ### the source distribution)
    print " ... Verifying compilation of psad daemons:\n";
    unless ((system "$Cmds{'perl'} -c psad") == 0) {
        die " ... @@@ psad does not compile with \"perl -c\".  Download the" .
            " latest sources from:\n\nhttp://www.cipherdyne.com\n";
    }
    unless ((system "$Cmds{'perl'} -c psadwatchd") == 0) {
        die " ... @@@ psadwatchd does not compile with \"perl -c\".  Download " .
            "the latest sources from:\n\nhttp://www.cipherdyne.com\n";
    }
    unless ((system "$Cmds{'perl'} -c kmsgsd") == 0) {
        die " ... @@@ kmsgsd does not compile with \"perl -c\".  Download the" .
            " latest sources from:\n\nhttp://www.cipherdyne.com\n";
    }
    unless ((system "$Cmds{'perl'} -c diskmond") == 0) {
        die " ... @@@ diskmond does not compile with \"perl -c\".  Download " .
            "the latest sources from:\n\nhttp://www.cipherdyne.com\n";
    }
    print "\n";

    ### put the psad daemons in place
    &logr(" ... Copying psad -> ${SBIN_DIR}/psad\n");
    copy('psad', "${SBIN_DIR}/psad");
    &perms_ownership("${SBIN_DIR}/psad", 0500);

    &logr(" ... Copying psadwatchd -> ${SBIN_DIR}/psadwatchd\n");
    copy('psadwatchd', "${SBIN_DIR}/psadwatchd");
    &perms_ownership("${SBIN_DIR}/psadwatchd", 0500);

    &logr(" ... Copying kmsgsd -> ${SBIN_DIR}/kmsgsd\n");
    copy('kmsgsd', "${SBIN_DIR}/kmsgsd");
    &perms_ownership("${SBIN_DIR}/kmsgsd", 0500);

    &logr(" ... Copying diskmond -> ${SBIN_DIR}/diskmond\n");
    copy('diskmond', "${SBIN_DIR}/diskmond");
    &perms_ownership("${SBIN_DIR}/diskmond", 0500);

    unless (-d $PSAD_CONFDIR) {
        &logr(" ... Creating $PSAD_CONFDIR\n");
        mkdir $PSAD_CONFDIR,0400;
    }
    unless (-d $CONF_ARCHIVE) {
        &logr(" ... Creating $CONF_ARCHIVE\n");
        mkdir $CONF_ARCHIVE, 0400;
    }
    if (-e "${PSAD_CONFDIR}/psad_signatures") {
        &archive("${PSAD_CONFDIR}/psad_signatures") unless $nopreserve;
        &logr(" ... Copying psad_signatures -> " .
            "${PSAD_CONFDIR}/psad_signatures\n");
        copy('psad_signatures', "${PSAD_CONFDIR}/psad_signatures");
        &perms_ownership("${PSAD_CONFDIR}/psad_signatures", 0600);
    } else {
        &logr(" ... Copying psad_signatures -> " .
            "${PSAD_CONFDIR}/psad_signatures\n");
        copy('psad_signatures', "${PSAD_CONFDIR}/psad_signatures");
        &perms_ownership("${PSAD_CONFDIR}/psad_signatures", 0600);
    }
    if (-e "${PSAD_CONFDIR}/psad_auto_ips") {
        &archive("${PSAD_CONFDIR}/psad_auto_ips") unless $nopreserve;
        &logr(" ... Copying psad_auto_ips -> " .
            "${PSAD_CONFDIR}/psad_auto_ips\n");
        copy('psad_auto_ips', "${PSAD_CONFDIR}/psad_auto_ips");
        &perms_ownership("${PSAD_CONFDIR}/psad_auto_ips", 0600);
    } else {
        &logr(" ... Copying psad_auto_ips -> " .
            "${PSAD_CONFDIR}/psad_auto_ips\n");
        copy('psad_auto_ips', "${PSAD_CONFDIR}/psad_auto_ips");
        &perms_ownership("${PSAD_CONFDIR}/psad_auto_ips", 0600);
    }
    if (-e "${PSAD_CONFDIR}/psad.conf") {
        &archive("${PSAD_CONFDIR}/psad.conf") unless $nopreserve;
        &logr(" ... Copying psad.conf -> ${PSAD_CONFDIR}/psad.conf\n");
        copy('psad.conf', "${PSAD_CONFDIR}/psad.conf");
        &perms_ownership("${PSAD_CONFDIR}/psad.conf", 0600);
    } else {
        &logr(" ... Copying psad.conf -> ${PSAD_CONFDIR}/psad.conf\n");
        copy('psad.conf', "${PSAD_CONFDIR}/psad.conf");
        &perms_ownership("${PSAD_CONFDIR}/psad.conf", 0600);
    }
    my $email_str = &query_email();
    if ($email_str) {
        &put_email("${PSAD_CONFDIR}/psad.conf", $email_str);
    }
    ### Give the admin the opportunity to add to the strings that are normally
    ### checked in iptables messages.  This is useful since the admin may have
    ### configured the firewall to use a logging prefix of "Audit" or something
    ### else other than the normal "DROP", "DENY", or "REJECT" strings.
    my $append_fw_search_str = &get_fw_search_string();
    if ($append_fw_search_str) {
        &logr(" ... Appending \"$append_fw_search_str\" to " .
            "\$FW_MSG_SEARCH in ${PSAD_CONFDIR}/psad.conf\n");
        &put_fw_search_str("${PSAD_CONFDIR}/psad.conf", $append_fw_search_str);
    }
    ### make sure the PSAD_DIR and PSAD_FIFO variables are correctly defined
    ### in the config file.
    &put_string("${PSAD_CONFDIR}/psad.conf", 'PSAD_DIR', $PSAD_DIR);
    &put_string("${PSAD_CONFDIR}/psad.conf", 'PSAD_FIFO', $PSAD_FIFO);

    ### remove old man page
    unlink '/usr/local/man/man8/psad.8' if (-e '/usr/local/man/man8/psad.8');

    ### default location to put the psad man page, but check with
    ### /etc/man.config
    my $mpath = '/usr/share/man/man8';
    if (-e '/etc/man.config') {
        ### prefer to install psad.8 in /usr/local/man/man8 if
        ### this directory is configured in /etc/man.config
        open M, '< /etc/man.config' or
            die " ... @@@ Could not open /etc/man.config: $!";
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
    mkdir $mpath unless -d $mpath;
    my $mfile = "${mpath}/psad.8";
    &logr(" ... Installing psad(8) man page as $mfile\n");
    copy('psad.8', $mfile);
    &perms_ownership($mfile, 0644);

    if ($distro =~ /redhat/) {
        if (-d $INIT_DIR) {
            &logr(" ... Copying psad-init -> ${INIT_DIR}/psad\n");
            copy('psad-init', "${INIT_DIR}/psad");
            &perms_ownership("${INIT_DIR}/psad", 0744);
            &enable_psad_at_boot($distro);
        } else {
            &logr(" ... @@@  The init script directory, \"${INIT_DIR}\" " .
                "does not exist!.\n");
            &logr("Edit the \$INIT_DIR variable in the config section to " .
                "point to where the init scripts are.\n");
        }
    } else {  ### psad is being installed on a non-redhat distribution
        if (-d $INIT_DIR) {
            &logr(" ... Copying psad-init.generic -> ${INIT_DIR}/psad\n");
            copy('psad-init.generic', "${INIT_DIR}/psad");
            &perms_ownership("${INIT_DIR}/psad", 0744);
            &enable_psad_at_boot($distro);
        } else {
            &logr(" ... @@@  The init script directory, \"${INIT_DIR}\" does " .
                "not exist!.  Edit the \$INIT_DIR variable in the config " .
                "section.\n");
        }
    }
    my $running;
    my $pid;
    if (-e "${RUNDIR}/psad.pid") {
        open PID, "< ${RUNDIR}/psad.pid";
        $pid = <PID>;
        close PID;
        chomp $pid;
        $running = kill 0, $pid;
    } else {
        $running = 0;
    }
    if ($distro =~ /redhat/) {
        if ($running) {
            &logr(" ... An older version of psad is already running.  To ".
                "execute, run \"${INIT_DIR}/psad restart\"\n");
        } else {
            &logr(" ... To execute psad, run \"${INIT_DIR}/psad start\"\n");
        }
    } else {
        if ($running) {
            &logr(" ... An older version of psad is already running.  kill " .
                "pid $pid, and then execute:\n");
            &logr("${SBIN_DIR}/psad -s ${PSAD_CONFDIR}/psad_signatures -a " .
                "${PSAD_CONFDIR}/psad_auto_ips\n");
        } else {
            &logr("To start psad, execute: ${SBIN_DIR}/psad -s " .
                "${PSAD_CONFDIR}/psad_signatures -a ${PSAD_CONFDIR}/" .
                "psad_auto_ips\n");
        }
    }
    &logr("\n ... Psad has been installed!\n");

    return;
}

sub uninstall() {
    my $t = localtime();
    my $time = " ... Uninstalling psad from $HOSTNAME: $t\n";
    &logr("\n$time\n");

    my $ans = '';
    while ($ans ne 'y' && $ans ne 'n') {
        print wrap('', $SUB_TAB, ' ... This will completely remove psad ' .
            'from your system.  Are you sure (y/n)? ');
        $ans = <STDIN>;
        chomp $ans;
    }
    if ($ans eq 'n') {
        &logr(" @@@ User aborted uninstall by answering \"n\" to the remove " .
            "question!  Exiting.\n");
        exit 0;
    }
    ### after this point, psad will really be uninstalled so stop writing stuff
    ### to the install.log file.  Just print everything to STDOUT
    if (-e "${SBIN_DIR}/psad" && system "${SBIN_DIR}/psad --Status > /dev/null") {
        print " ... Stopping psad daemons!\n";
        if (-e "${INIT_DIR}/psad") {
            system "${INIT_DIR}/psad stop";
        } else {
            system "${SBIN_DIR}/psad --Kill";
        }
    }
    if (-e "${SBIN_DIR}/psad") {
        print wrap('', $SUB_TAB, " ... Removing psad daemons: ${SBIN_DIR}/" .
            "(psad, psadwatchd, kmsgsd, diskmond)\n");
        unlink "${SBIN_DIR}/psad"       or
            warn " ... @@@  Could not remove ${SBIN_DIR}/psad!!!\n";
        unlink "${SBIN_DIR}/psadwatchd" or
            warn " ... @@@  Could not remove ${SBIN_DIR}/psadwatchd!!!\n";
        unlink "${SBIN_DIR}/kmsgsd"     or
            warn " ... @@@  Could not remove ${SBIN_DIR}/kmsgsd!!!\n";
        unlink "${SBIN_DIR}/diskmond"   or
            warn " ... @@@  Could not remove ${SBIN_DIR}/diskmond!!!\n";
    }
    if (-e "${INIT_DIR}/psad") {
        print " ... Removing ${INIT_DIR}/psad\n";
        unlink "${INIT_DIR}/psad";
    }
    if (-e "${PERL_INSTALL_DIR}/Psad.pm") {
        print " ----  Removing ${PERL_INSTALL_DIR}/Psad.pm  ----\n";
        unlink "${PERL_INSTALL_DIR}/Psad.pm";
    }
    if (-d $PSAD_CONFDIR) {
        print " ... Removing configuration directory: $PSAD_CONFDIR\n";
        rmtree($PSAD_CONFDIR, 1, 0);
    }
    if (-d $PSAD_DIR) {
        print " ... Removing logging directory: $PSAD_DIR\n";
        rmtree($PSAD_DIR, 1, 0);
    }
    if (-e $PSAD_FIFO) {
        print " ... Removing named pipe: $PSAD_FIFO\n";
        unlink $PSAD_FIFO;
    }
    if (-e $WHOIS_PSAD) {
        print " ... Removing $WHOIS_PSAD\n";
        unlink $WHOIS_PSAD;
    }
    if (-d $VARLIBDIR) {
        print " ... Removing $VARLIBDIR\n";
        rmtree $VARLIBDIR;
    }
    if (-d $RUNDIR) {
        print " ... Removing $RUNDIR";
        rmtree $RUNDIR;
    }
    if (-d $LIBDIR) {
        print " ... Removing $LIBDIR";
        rmtree $LIBDIR;
    }
    print " ... Restoring /etc/syslog.conf.orig -> /etc/syslog.conf\n";
    if (-e '/etc/syslog.conf.orig') {
        move('/etc/syslog.conf.orig', '/etc/syslog.conf');
    } else {
        print wrap('', $SUB_TAB, " ... /etc/syslog.conf.orig does not exist. " .
            " Editing /etc/syslog.conf directly.\n");
        open ESYS, '< /etc/syslog.conf' or
            die " ... @@@  Unable to open /etc/syslog.conf: $!\n";
        my @sys = <ESYS>;
        close ESYS;
        open CSYS, '> /etc/syslog.conf';
            for my $line (@sys) {
            chomp $line;
            ### don't print the psadfifo line
            print CSYS "$line\n" if ($line !~ /psadfifo/);
        }
        close CSYS;
    }
    print " ... Restarting syslog.\n";
    system("$Cmds{'killall'} -HUP syslogd");
    print "\n";
    print " ... Psad has been uninstalled!\n";

    return;
}

sub check_old_psad_installation() {
    my $old_install_dir = '/usr/local/bin';
    if (-e "${old_install_dir}/psad") {
        move("${old_install_dir}/psad", "${SBIN_DIR}/psad");
    }
    if (-e "${old_install_dir}/psadwatchd") {
        move("${old_install_dir}/psadwatchd", "${SBIN_DIR}/psadwatchd");
    }
    if (-e "${old_install_dir}/diskmond") {
        move("${old_install_dir}/diskmond", "${SBIN_DIR}/diskmond");
    }
    if (-e "${old_install_dir}/kmsgsd") {
        move("${old_install_dir}/kmsgsd", "${SBIN_DIR}/kmsgsd");
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
    unlink "${PERL_INSTALL_DIR}/Psad.pm" if (-e "${PERL_INSTALL_DIR}/Psad.pm");
    if (-e '/var/log/psadfifo') {  ### this is the old psadfifo location
        if (-e "${SBIN_DIR}/psad" && system "${SBIN_DIR}/psad --Status > /dev/null") {
            ### deal with this later.  The user should be prompted before
            ### the old psadfifo is removed since kmsgsd will have a problem
        } else {
            unlink '/var/log/psadfifo';
        }
    }
    return;
}
sub get_distro() {
    if (-e '/etc/issue') {
        ### Red Hat Linux release 6.2 (Zoot)
        open ISSUE, '< /etc/issue';
        while(<ISSUE>) {
            my $line = $_;
            chomp $line;
            return 'redhat' if ($line =~ /Red\s*Hat/i);
        }
        close ISSUE;
        return 'NA';
    } else {
        return 'NA';
    }
}
sub perms_ownership() {
    my ($file, $perm_value) = @_;
    chmod $perm_value, $file;
    chown 0, 0, $file;  ### chown uid, gid, $file  (root :)
    return;
}
sub get_fw_search_string() {
    print " ... psad checks the firewall configuration on the underlying machine\n"
        . "     to see if packets will be logged and dropped that have not\n"
        . "     explicitly allowed through.  By default psad looks for the\n"
        . "     strings \"DENY\", \"DROP\", or \"REJECT\". However, if your\n"
        . "     particular firewall configuration logs blocked packets with the\n"
        . "     string \"Audit\" for example, psad can be configured to look for this\n"
        . "     string.\n\n";
    my $ans = '';
    while ($ans ne 'y' && $ans ne 'n') {
        print "     Would you like to add a new string that will be used to analyze\n"
            . "     firewall log messages?  (Is it usually safe to say \"n\" here).\n"
            . "     (y/[n])? ";
        $ans = <STDIN>;
        if ($ans eq "\n") {  ### allow the default answer to take over
            $ans = 'n';
        }
        chomp $ans;
    }
    print "\n";
    my $fw_string = '';
    if ($ans eq 'y') {
        print "     Enter a string (i.e. \"Audit\"):  ";
        $fw_string = <STDIN>;
        chomp $fw_string;
    }
    return $fw_string;
}
sub query_email() {
    my $filename = 'psad.conf';
    open F, "< ${PSAD_CONFDIR}/psad.conf";
    my @clines = <F>;
    close F;
    my $email_addresses;
    for my $line (@clines) {
        chomp $line;
        if ($line =~ /^\s*EMAIL_ADDRESSES\s+\((.+)\)/) {
            $email_addresses = $1;
            last;
        }
    }
    unless ($email_addresses) {
        return '';
    }
    print " ... psad alerts will be sent to:\n\n";
    print "       $email_addresses\n\n";
    my $ans = '';
    while ($ans ne 'y' && $ans ne 'n') {
        print " ... Would you like alerts sent to a different address ([y]/n)?  ";
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
        print " ... To which email address(es) would you like " .
            "psad alerts to be sent?\n";
        print " ... You can enter as many email addresses as you like " .
            "separated by spaces.\n";
        my $emailstr = '';
        my $correct = 0;
        while (! $correct) {
            print 'Email addresses: ';
            $emailstr = <STDIN>;
            $emailstr =~ s/\,//g;
            chomp $emailstr;
            my @emails = split /\s+/, $emailstr;
            $correct = 1;
            for my $email (@emails) {
                unless ($email =~ /\S+\@\S+/) {
                    $correct = 0;
                }
            }
            $correct = 0 unless @emails;
        }
        return $emailstr;
    } else {
        return '';
    }
    return '';
}
sub put_email() {
    my ($file, $emailstr) = @_;
    open RF, "< $file";
    my @lines = <RF>;
    close RF;
    open F, "> $file";
    for my $line (@lines) {
        if ($line =~ /EMAIL_ADDRESSES\s*\(/) {
            print F "EMAIL_ADDRESSES            ($emailstr);\n";
        } else {
            print F $line;
        }
    }
    close F;
    return;
}
sub put_fw_search_str() {
    my ($file, $append_fw_search) = @_;
    open RF, "< $file";
    my @lines = <RF>;
    close RF;
    open F, "> $file";
    for my $line (@lines) {
        if ($line =~ /^\s*FW_MSG_SEARCH\s*(.*);/) {
            my $fw_string = $1;
            $fw_string .= "|$append_fw_search";
            print F "FW_MSG_SEARCH              $fw_string;\n";
        } else {
            print F $line;
        }
    }
    close F;
    return;
}
sub put_string() {
    my ($file, $key, $value) = @_;
    open RF, "< $file";
    my @lines = <RF>;
    close RF;
    open F, "> $file";
    for my $line (@lines) {
        if ($line =~ /^\s*$key\s*.*;/) {
            print F "$key                    $value;\n";
        } else {
            print F $line;
        }
    }
    close F;
    return;
}
sub archive() {
    my $file = shift;
    my ($filename) = ($file =~ m|.*/(.*)|);
    my $targetbase = "${CONF_ARCHIVE}/${filename}.old";
    for (my $i = 4; $i > 1; $i--) {  ### keep five copies of the old config files
        my $oldfile = $targetbase . $i;
        my $newfile = $targetbase . ($i+1);
        if (-e $oldfile) {
            move $oldfile, $newfile;
        }
    }
    if (-e $targetbase) {
        my $newfile = $targetbase . "2";
        move $targetbase, $newfile;
    }
    &logr(" ... Archiving $file -> $targetbase\n");
    copy($file, $targetbase);   ### move $file into the archive directory
    return;
}
sub enable_psad_at_boot() {
    my $distro = shift;
    my $ans = '';
    while ($ans ne 'y' && $ans ne 'n') {
        print " ... Enable psad at boot time ([y]/n)?  ";
        $ans = <STDIN>;
        if ($ans eq "\n") {  ### allow the default of "y" to take over
            $ans = 'y';
        }
        chomp $ans;
    }
    if ($ans eq 'y') {
        if ($distro =~ /redhat/) {
            system "$Cmds{'chkconfig'} --add psad";
        } else {  ### it is a non-redhat distro, try to
                  ### get the runlevel from /etc/inittab
            if ($RUNLEVEL) {
                ### the link already exists, so don't re-create it
                unless (-e "/etc/rc.d/rc${RUNLEVEL}.d/S99psad") {
                    symlink '/etc/rc.d/init.d/psad',
                        "/etc/rc.d/rc${RUNLEVEL}.d/S99psad";
                }
            } elsif (-e '/etc/inittab') {
                open I, '< /etc/inittab';
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
                    print " ... @@@  Could not determine the runlevel.  Set " .
                        "the runlevel\nmanually in the config section of " .
                        "install.pl\n";
                    return;
                }
                ### the link already exists, so don't re-create it
                unless (-e "/etc/rc.d/rc${RUNLEVEL}.d/S99psad") {
                    symlink '/etc/rc.d/init.d/psad',
                        "/etc/rc.d/rc${RUNLEVEL}.d/S99psad";
                }
            } else {
                print " ... @@@  /etc/inittab does not exist!  Set the " .
                    "runlevel\nmanually in the config section of " .
                    "install.pl.\n";
                return;
            }
        }
    }
    return;
}
### check paths to commands and attempt to correct if any are wrong.
sub check_commands() {
    my $Cmds_href = shift;
    my $caller = $0;
    my @path = qw(/bin /sbin /usr/bin /usr/sbin /usr/local/bin /usr/local/sbin);
    CMD: for my $cmd (keys %$Cmds_href) {
        my $cmd_name = ($Cmds_href->{$cmd} =~ m|.*/(.*)|);
        unless (-x $Cmds_href->{$cmd}) {
            my $found = 0;
            PATH: for my $dir (@path) {
                if (-x "${dir}/${cmd}") {
                    $Cmds_href->{$cmd} = "${dir}/${cmd}";
                    $found = 1;
                    last PATH;
                }
            }
            unless ($found) {
                next CMD if ($cmd eq 'ipchains' || $cmd eq 'iptables');
                die "\n ... @@@  ($caller): Could not find $cmd anywhere!!!  " .
                    "Please edit the config section to include the path to " .
                    "$cmd.\n";
            }
        }
        unless (-x $Cmds_href->{$cmd}) {
            die "\n ... @@@  ($caller):  $cmd_name is located at " .
                "$Cmds_href->{$cmd} but is not executable by uid: $<\n";
        }
    }
    return;
}
### logging subroutine that handles multiple filehandles
sub logr() {
    my $msg = shift;
    for my $f (@LOGR_FILES) {
        if ($f eq *STDOUT) {
            if (length($msg) > 72) {
                print STDOUT wrap('', $SUB_TAB, $msg);
            } else {
                print STDOUT $msg;
            }
        } elsif ($f eq *STDERR) {
            if (length($msg) > 72) {
                print STDERR wrap('', $SUB_TAB, $msg);
            } else {
                print STDERR $msg;
            }
        } else {
            open F, ">> $f";
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
sub usage_and_exit() {
        my $exitcode = shift;
        print <<_HELP_;

Usage: install.pl [-f] [-n] [-u] [-v] [-h]
    
    -n  --no_preserve   - disable preservation of old configs.
    -u  --uninstall     - uninstall psad.
    -v  --verbose       - verbose mode.
    -h  --help          - prints this help message.

_HELP_
        exit $exitcode;
}
