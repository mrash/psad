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
# Version: 1.2.4
#
# Copyright (C) 1999-2001 Michael Rash (mbr@cipherdyne.org)
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

use lib '/usr/lib/psad';
use Psad;
use POSIX qw(setsid);
use Getopt::Long 'GetOptions';
use Sys::Hostname 'hostname';
use strict;

### establish the default path to the config file (can be
### over-ridden with the -c <file> command line option.
my $CONFIG_FILE = '/etc/psad/psadwatchd.conf';

### configuration hash
my %config;

### commands hash
my %cmds;

### flag used for HUP signal
my $hup_flag = 0;

### handle command line arguments
die " ** Specify the path to the psad.conf file with " .
    "\"-c <file>\".\n\n" unless (GetOptions (
    'config=s' => \$CONFIG_FILE
));

### import config
&import_config();

### Make sure the commands are where the config says they are
&Psad::check_commands(\%cmds);

### make sure this is the only psadwatchd running on this system
&Psad::unique_pid($config{'PSADWATCHD_PID_FILE'});

### install WARN and DIE handlers
$SIG{'__WARN__'} = \&Psad::warn_handler;
$SIG{'__DIE__'}  = \&Psad::die_handler;

my $pid = fork;
exit if $pid;
die " ** $0: Couldn't fork: $!" unless defined($pid);
POSIX::setsid() or die " ** $0: Can't start a new session: $!\n";

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
        &Psad::psyslog('psad(psadwatchd)', 'Received HUP signal, ' .
            're-importing psadwatchd.conf');
    }

    &check_process('psad', $psad_Cmdline,
        $config{'PSAD_PID_FILE'}, \$p_emails);
    &check_process('kmsgsd', '',
        $config{'KMSGSD_PID_FILE'}, \$k_emails);

    sleep $config{'PSADWATCHD_CHECK_INTERVAL'};
}
exit 0;
#=================== end main ==================
sub check_process() {
    my ($pidname, $pidcmdline, $pidfile, $email_count_ref) = @_;
    if (-e $pidfile) {
        open PID, "< $pidfile" or
            print "Could not open $pidfile for $pidname\n" and return;
        my $pid = <PID>;
        close PID;
        chomp $pid;
        unless (kill 0, $pid) {
            ### the daemon is not running so start it with $pidcmdline
            ### args (which may be empty)
            if ($$email_count_ref > $config{'PSADWATCHD_MAX_RETRIES'}) {
                ### this will exit the program
                &give_up($pidname);
            }
            ### should check the rv of this system() call
            system "$cmds{$pidname} $pidcmdline";
            my $subject = " ** psadwatchd: restarted $pidname on $HOSTNAME";
            &Psad::sendmail($subject, '', $config{'EMAIL_ADDRESSES'},
                $cmds{'mail'});
            $$email_count_ref++;
            return;
        } else {
            ### the program is running now, so reset the watch count to zero
            $$email_count_ref = 0;
        }
    } else {
        my $subject = " ** psadwatchd: pid file $pidfile\" does not exist " .
            "for $pidname.  Starting $pidname daemon.";
        &Psad::sendmail($subject, '', $config{'EMAIL_ADDRESSES'},
            $cmds{'mail'});
        ### start $pidname
        system "$cmds{$pidname} $pidcmdline";
    }
    return;
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
    my $subject = " ** psadwatchd: psad is not running on $HOSTNAME.  " .
        "Please start it.";
    &Psad::sendmail($subject, '', $config{'EMAIL_ADDRESSES'}, $cmds{'mail'});
    exit 0;
}

sub give_up() {
    my $pidname = shift;
    my $subject = "psadwatchd: restart limit reached for $pidname " .
                  "on $HOSTNAME!!!  Exiting.";
    &Psad::sendmail($subject, '', $config{'EMAIL_ADDRESSES'}, $cmds{'mail'});
    exit 0;
}

sub import_config() {
    ### read in the configuration file
    &Psad::buildconf(\%config, \%cmds, $CONFIG_FILE);

    ### make sure the configuration is complete
    &required_vars();

    ### Check to make sure the commands specified in the config section
    ### are in the right place, and attempt to correct automatically if not.
    &Psad::check_commands(\%cmds);

    return;
}

sub required_vars() {
    my @required_vars = qw(
        PSAD_PID_FILE PSAD_CMDLINE_FILE
        DISKMOND_PID_FILE KMSGSD_PID_FILE
        PSADWATCHD_PID_FILE EMAIL_ADDRESSES
        PSADWATCHD_CHECK_INTERVAL
        PSADWATCHD_MAX_RETRIES
    );
    &Psad::defined_vars($CONFIG_FILE, \@required_vars, \%config);
    return;
}
