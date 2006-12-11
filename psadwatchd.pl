#!/usr/bin/perl -w
#
#########################################################################
#
# File: psadwatchd
#
# Purpose: psadwatchd checks on an interval of every five seconds to make
#          sure that both kmsgsd and psad are running on the box.  If
#          either daemon has died, psadwatchd will restart it notify each
#          email address in @email_addresses that the daemon has been
#          restarted.
#
# Author: Michael Rash (mbr@cipherdyne.org)
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
#########################################################################
#
# $Id$
#

use POSIX qw(setsid);
use Getopt::Long 'GetOptions';
use Sys::Hostname 'hostname';
use strict;

### path to default psad library directory for psad perl modules
my $psad_lib_dir = '/usr/lib/psad';

### establish the default path to the config file (can be
### over-ridden with the -c <file> command line option.
my $config_file      = '/etc/psad/psadwatchd.conf';
my $psad_config_file = '/etc/psad/psad.conf';  ### for EMAIL_ADDRESSES

### default config file for ALERTING_METHODS keyword, which
#### is referenced by both psad and psadwatchd.  This keyword
#### allows email alerting or syslog alerting (or both) to be
#### disabled.
my $alerting_config_file = '/etc/psad/alert.conf';

my $warn_msg = '';
my $die_msg  = '';

### these vars are controled by the alert.conf file
my $no_email_alerts  = 0;
my $no_syslog_alerts = 0;

### configuration hash
my %config;

### commands hash
my %cmds;

### flag used for HUP signal
my $hup_flag = 0;

### handle command line arguments
die "[*] Specify the path to the psad.conf file with " .
    "\"-c <file>\".\n\n" unless (GetOptions (
    'config=s' => \$config_file
));

### import psad perl modules
&import_psad_perl_modules();

### import config
&import_config();

### make sure this is the only psadwatchd running on this system
&Psad::unique_pid($config{'PSADWATCHD_PID_FILE'});

### install WARN and DIE handlers
$SIG{'__WARN__'} = \&warn_handler;
$SIG{'__DIE__'}  = \&die_handler;

### install HUP handler so config can be re-imported
$SIG{'HUP'}  = \&hup_sig;

my $pid = fork;
exit if $pid;
die "[*] $0: Couldn't fork: $!" unless defined($pid);
POSIX::setsid() or die "[*] $0: Can't start a new session: $!\n";

### write the pid to the pid file
&Psad::writepid($config{'PSADWATCHD_PID_FILE'});

my $HOSTNAME = hostname;

### get the psad command line args
my $psad_Cmdline = &get_psad_Cmdline($config{'PSAD_CMDLINE_FILE'});

my ($d_emails, $k_emails, $p_emails) = (0,0,0);

#=================== end main ==================
### main loop
for (;;) {

    if ($hup_flag) {
        ### clear the HUP flag
        $hup_flag = 0;
        &import_config();
        &Psad::psyslog('psad(psadwatchd)', 'received HUP signal, ' .
            're-importing psadwatchd.conf') unless $no_syslog_alerts;
    }

    &check_process('psad', $psad_Cmdline,
        $config{'PSAD_PID_FILE'}, \$p_emails);
    &check_process('kmsgsd', '',
        $config{'KMSGSD_PID_FILE'}, \$k_emails);

    if ($die_msg) {
        &Psad::print_sys_msg($die_msg, "$config{'PSAD_DIR'}/errs/psadwatchd.die");
        $die_msg = '';
    }

    if ($warn_msg) {
        &Psad::print_sys_msg($warn_msg, "$config{'PSAD_DIR'}/errs/psadwatchd.warn");
        $warn_msg = '';
    }

    sleep $config{'PSADWATCHD_CHECK_INTERVAL'};
}
exit 0;
#=================== end main ==================

sub check_process() {
    my ($pidname, $pidcmdline, $pidfile, $email_count_ref) = @_;
    if (-e $pidfile) {
        unless (&Psad::pidrunning($pidfile)) {
            ### the daemon is not running so start it with $pidcmdline
            ### args (which may be empty)
            if ($$email_count_ref > $config{'PSADWATCHD_MAX_RETRIES'}) {
                ### this will exit the program
                &give_up($pidname);
            }
            ### should check the rv of this system() call
            system "$cmds{$pidname} $pidcmdline";
            my $subject = "[*] psadwatchd: restarted $pidname on $HOSTNAME";
            &Psad::sendmail($subject, '', $config{'EMAIL_ADDRESSES'},
                $cmds{'mail'}) unless $no_email_alerts;
            $$email_count_ref++;
            return;
        } else {
            ### the program is running now, so reset the watch count to zero
            $$email_count_ref = 0;
        }
    } else {
        my $subject = "[*] psadwatchd: pid file $pidfile\" does not exist " .
            "for $pidname.  Starting $pidname daemon.";
        &Psad::sendmail($subject, '', $config{'EMAIL_ADDRESSES'},
            $cmds{'mail'}) unless $no_email_alerts;
        ### start $pidname
        system "$cmds{$pidname} $pidcmdline";
    }
    return;
}

sub import_psad_perl_modules() {

    my $mod_paths_ar = &get_psad_mod_paths();

    splice @INC, 0, $#$mod_paths_ar+1, @$mod_paths_ar;

    require Psad;

    return;
}

sub get_psad_mod_paths() {

    my @paths = ();

    unless (-d $psad_lib_dir) {
        my $dir_tmp = $psad_lib_dir;
        $dir_tmp =~ s|lib/|lib64/|;
        if (-d $dir_tmp) {
            $psad_lib_dir = $dir_tmp;
        } else {
            die "[*] psad lib directory: $psad_lib_dir does not exist, ",
                "use --Lib-dir <dir>";
        }
    }

    opendir D, $psad_lib_dir or die "[*] Could not open $psad_lib_dir: $!";
    my @dirs = readdir D;
    closedir D;

    push @paths, $psad_lib_dir;

    for my $dir (@dirs) {
        ### get directories like "/usr/lib/psad/x86_64-linux"
        next unless -d "$psad_lib_dir/$dir";
        push @paths, "$psad_lib_dir/$dir"
            if $dir =~ m|linux| or $dir =~ m|thread|;
    }
    return \@paths;
}

sub get_psad_Cmdline() {
    my $psad_cmd_file = shift;
    my $noexit=0;
    my $psad_Cmdline;
    while ($noexit < 100) {
        if (-e $psad_cmd_file) {
            open CMD, "< $psad_cmd_file";
            $psad_Cmdline = <CMD>;
            close CMD;
            return $psad_Cmdline;  ### there may be _no_ command line args
        } else {
            $noexit++;
        }
        sleep 1;
    }
    my $subject = "[*] psadwatchd: psad is not running on $HOSTNAME.  " .
        "Please start it.";
    &Psad::sendmail($subject, '', $config{'EMAIL_ADDRESSES'}, $cmds{'mail'})
        unless $no_email_alerts;
    exit 0;
}

sub give_up() {
    my $pidname = shift;
    my $subject = "psadwatchd: restart limit reached for $pidname " .
                  "on $HOSTNAME!!!  Exiting.";
    &Psad::sendmail($subject, '', $config{'EMAIL_ADDRESSES'}, $cmds{'mail'})
        unless $no_email_alerts;
    exit 0;
}

sub import_config() {

    ### read in the configuration file
    &Psad::buildconf(\%config, \%cmds, $config_file);

    ### for EMAIL_ADDRESSES
    &Psad::buildconf(\%config, \%cmds, $psad_config_file);

    ### import alerting config (psadwatchd also references this file
    &Psad::buildconf(\%config, \%cmds, $alerting_config_file);

    ### expand any embedded vars within config values
    &Psad::expand_vars(\%config, \%cmds);

    ### make sure the configuration is complete
    &required_vars();

    $no_email_alerts = 1 if $config{'ALERTING_METHODS'} =~ /no.?e?mail/i;
    $no_syslog_alerts = 1 if $config{'ALERTING_METHODS'} =~ /no.?syslog/i;

    ### Check to make sure the commands specified in the config section
    ### are in the right place, and attempt to correct automatically if not.
    &Psad::check_commands(\%cmds, {'mail' => ''});

    return;
}

sub required_vars() {
    my @required_vars = qw(
        PSAD_PID_FILE PSAD_CMDLINE_FILE
        PSADWATCHD_PID_FILE EMAIL_ADDRESSES
        PSADWATCHD_CHECK_INTERVAL
        PSADWATCHD_MAX_RETRIES
        KMSGSD_PID_FILE
    );
    &Psad::defined_vars(\%config, $config_file, \@required_vars);
    return;
}

sub hup_sig() {
    $hup_flag = 1;
    return;
}

sub die_handler() {
    $die_msg = shift;
    return;
}

sub warn_handler() {
    $warn_msg = shift;
    return;
}
