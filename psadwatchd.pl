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
# Author: Michael B. Rash (mbr@cipherdyne.com)
#
# Credits:  (see the CREDITS file)
#
# Version: 1.0
#
# Copyright (C) 1999-2001 Michael B. Rash (mbr@cipherdyne.com)
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
use File::stat;
use POSIX qw(setsid);
use Getopt::Long 'GetOptions';
use Sys::Hostname 'hostname';
use strict;

### establish the default path to the config file (can be
### over-ridden with the -c <file> command line option.
my $CONFIG_FILE = '/etc/psad/psad.conf';

### handle command line arguments
die " ** Specify the path to the psad.conf file with " .
    "\"-c <file>\".\n\n" unless (GetOptions (
    'config=s' => \$CONFIG_FILE
));

### read in the configuration file
my ($Config_href, $Cmds_href) = &Psad::buildconf($CONFIG_FILE);

### make sure the configuration is complete
&check_config();

my %Config = %$Config_href;
my %Cmds   = %$Cmds_href;
my $emailaddrs_aref = $Config{'EMAIL_ADDRESSES'};

### Make sure the commands are where the config says they are
&Psad::check_commands(\%Cmds);

### make sure this is the only psadwatchd running on this system
&Psad::unique_pid($Config{'PSADWATCHD_PID_FILE'});

### install WARN and DIE handlers
$SIG{'__WARN__'} = \&Psad::warn_handler;
$SIG{'__DIE__'}  = \&Psad::die_handler;

my $pid = fork;
exit if $pid;
die " ** $0: Couldn't fork: $!" unless defined($pid);
POSIX::setsid() or die " ** $0: Can't start a new session: $!\n";

### write the pid to the pid file
&Psad::writepid($Config{'PSADWATCHD_PID_FILE'});

my $HOSTNAME = hostname;

### get the psad command line args
my $psad_Cmdline = &get_psad_Cmdline($Config{'PSAD_CMDLINE_FILE'});

my ($d_emails, $k_emails, $p_emails) = (0,0,0);

my $config_mtime = stat($CONFIG_FILE)->mtime;
#=================== end main ==================
### main loop
for (;;) {
    ### See if we need to import any changed config variables
    &check_import_config(\$config_mtime, $CONFIG_FILE);

    &check_process('psad', $psad_Cmdline, $Config{'PSAD_PID_FILE'}, \$p_emails);
    &check_process('kmsgsd', '', $Config{'KMSGSD_PID_FILE'}, \$k_emails);
    &check_process('diskmond', '', $Config{'DISKMOND_PID_FILE'}, \$d_emails);

    sleep $Config{'PSADWATCHD_CHECK_INTERVAL'};
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
            if ($$email_count_ref > $Config{'PSADWATCHD_MAX_RETRIES'}) {
                ### this will exit the program
                &give_up($pidname);
            }
            ### should check the rv of this system() call
            system "$Cmds{$pidname} $pidcmdline";
            my $subject = "psadwatchd: restarted $pidname on $HOSTNAME";
            &Psad::sendmail($subject, '', $emailaddrs_aref, $Cmds{'mail'});
            $$email_count_ref++;
            return;
        } else {
            ### the program is running now, so reset the watch count to zero
            $$email_count_ref = 0;
        }
    } else {
        my $subject = "psadwatchd: pid file $pidfile\" does not exist " .
                      "for $pidname.  Starting $pidname daemon.";
        &Psad::sendmail($subject, '', $emailaddrs_aref, $Cmds{'mail'});
        ### start $pidname
        system "$Cmds{$pidname} $pidcmdline";
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
    my $subject = "psadwatchd: psad is not running on $HOSTNAME.  " .
                  "Please start it.";
    &Psad::sendmail($subject, '', $emailaddrs_aref, $Cmds{'mail'});
    exit 0;
}

sub give_up() {
    my $pidname = shift;
    my $subject = "psadwatchd: restart limit reached for $pidname " .
                  "on $HOSTNAME!!!  Exiting.";
    &Psad::sendmail($subject, '', $emailaddrs_aref, $Cmds{'mail'});
    exit 0;
}
sub check_import_config() {
    my ($mtime_ref, $file) = @_;
    my $mtime_tmp = stat($file)->mtime;
    if ($mtime_tmp != $$mtime_ref) {  ### the file was modified, so import

        ($Config_href, $Cmds_href) = &Psad::buildconf($file);

        ### make sure the configuration is complete
        &check_config();

        %Config = %$Config_href;
        %Cmds   = %$Cmds_href;
        $$mtime_ref = $mtime_tmp;
    }
    return;
}
sub check_config() {
    my @required_vars = qw(
        PSAD_PID_FILE PSAD_CMDLINE_FILE
        DISKMOND_PID_FILE KMSGSD_PID_FILE
        PSADWATCHD_PID_FILE EMAIL_ADDRESSES
        PSADWATCHD_CHECK_INTERVAL
        PSADWATCHD_MAX_RETRIES
    );
    &Psad::validate_config($CONFIG_FILE, \@required_vars, $Config_href);
    return;
}
