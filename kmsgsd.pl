#!/usr/bin/perl -w
#
###########################################################################
#
# File: kmsgsd
#
# Purpose: kmsgsd separates iptables messages from all other
#          kernel messages.
#
# Strategy: read message from the /var/lib/psad/psadfifo named pipe and 
#           print any firewall related dop/reject/deny messages to
#           the psad data file "/var/log/psad/fwdata".
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
###########################################################################
#
# $Id$
#

use lib '/usr/lib/psad';
use Psad;
use POSIX 'setsid';
use Getopt::Long 'GetOptions';
use strict;

### establish the default path to the config file (can be
### over-ridden with the -c <file> command line option.
my $CONFIG_FILE = '/etc/psad/kmsgsd.conf';

### configuration hash
my %config;

### commands hash
my %cmds;

### flag used for HUP signal
my $hup_flag = 0;

### syslog config file
my $syslog = '/etc/syslog.conf';

### handle command line arguments
die " ** Specify the path to the psad.conf file with " .
    "\"-c <file>\".\n\n" unless (GetOptions (
    'config=s' => \$CONFIG_FILE
));

### import config
&import_config();

### make sure there is not another kmsgsd already running
&Psad::unique_pid($config{'KMSGSD_PID_FILE'});

### install WARN and DIE handlers
$SIG{'__WARN__'} = \&Psad::warn_handler;
$SIG{'__DIE__'}  = \&Psad::die_handler;

### install HUP handler so config can be re-imported
$SIG{'HUP'}  = \&hup_sig;

my $pid = fork;
exit if $pid;
die " ** $0: Couldn't fork: $!" unless defined($pid);
POSIX::setsid() or die " ** $0: Can't start a new session: $!\n";

### write the pid to the pid file
&Psad::writepid($config{'KMSGSD_PID_FILE'});

### open the fwdata file
open LOG, ">> $config{'FW_DATA_FILE'}" or
    die "Could not open $config{'FW_DATA_FILE'}: $!\n";

#===================== main =======================
### main loop
for (;;) {
    open FIFO, "< $config{'PSAD_FIFO'}" or die "Can't open file : $!\n";
    my $service = <FIFO>;  ### don't chomp for better performance
    if (defined $service
        && ($service =~ /Packet\slog/ || $service =~ /IN.+?OUT/)
        && ($service =~ /$config{'FW_MSG_SEARCH'}/
        || $service =~ /$config{'SNORT_SID_STR'}/)) {
        ### log to the fwdata file
        my $old_fh = select LOG;
        $| = 1;
        print $service;
        select $old_fh;
    }
    if ($hup_flag) {
        ### clear the HUP flag and re-import the config
        $hup_flag = 0;
        &import_config();
        close FIFO;
        open FIFO, "< $config{'PSAD_FIFO'}" or
            die "Can't open file : $!\n";
        &Psad::psyslog('psad(kmsgsd)', 'Received HUP signal, ' .
            're-importing kmsgsd.conf');
    }
}
### These statements don't get executed, but for completeness...
close LOG;
close FIFO;
exit 0;
#==================== end main =====================
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
        KMSGSD_PID_FILE PSAD_FIFO FW_DATA_FILE
        FW_MSG_SEARCH SNORT_SID_STR
    );
    &Psad::defined_vars($CONFIG_FILE, \@required_vars, \%config);
    return;
}

sub hup_sig() {
    $hup_flag = 1;
    return;
}
