#!/usr/bin/perl -w
#
###########################################################################
#
# File: kmsgsd
#
# Purpose: kmsgsd separates ipchains/iptables messages from all other
#          kernel messages.
#
# Strategy: read message from the /var/lib/psad/psadfifo named pipe and 
#           print any firewall related dop/reject/deny messages to
#           the psad data file "/var/log/psad/fwdata".
#
# Author: Michael B. Rash (mbr@cipherdyne.com)
#
# Credits:  (see the CREDITS file)
#
# Version: 1.0.0-pre3
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
my $CONFIG_FILE = '/etc/psad/psad.conf';

### handle command line arguments
die " @@@ Specify the path to the psad.conf file with " .
    "\"-c <file>\".\n\n" unless (GetOptions (
    'config=s' => \$CONFIG_FILE
));

### read in the configuration file
my ($Config_href, $Cmds_href) = &Psad::buildconf($CONFIG_FILE);

### make sure the configuration is complete
&check_config();

my $FW_DATA       = $Config_href->{'FW_DATA'};
my $FW_MSG_SEARCH = $Config_href->{'FW_MSG_SEARCH'};
my $PSAD_FIFO     = $Config_href->{'PSAD_FIFO'};
my $PIDFILE       = $Config_href->{'KMSGSD_PID_FILE'};
undef $Config_href;

### make sure there is not another kmsgsd already running
&Psad::unique_pid($PIDFILE);

### install WARN and DIE handlers
$SIG{'__WARN__'} = \&Psad::warn_handler;
$SIG{'__DIE__'}  = \&Psad::die_handler;

my $pid = fork;
exit if $pid;
die " ... @@@  $0: Couldn't fork: $!" unless defined($pid);
POSIX::setsid() or die " ... @@@  $0: Can't start a new session: $!\n";

### write the pid to the pid file
&Psad::writepid($PIDFILE);

my $append_other = &check_facility();
if ($append_other) {
    open MESSAGES, '>> /var/log/messages' or die
                    "Could not open /var/log/messages: $!\n";
}

### open the fwdata file
open LOG, ">> $FW_DATA" or die "Could not open $FW_DATA: $!\n";

#===================== main =======================
### main loop
for (;;) {
    open FIFO, "< $PSAD_FIFO" or die "Can't open file : $!\n";
    my $service = <FIFO>;  ### don't chomp for better performance
    if (defined $service
            && ($service =~ /Packet\slog/ || $service =~ /IN.+?OUT.+?MAC/)
            && $service =~ /$FW_MSG_SEARCH/) {
        ### log to the fwdata file
        my $old_fh = select LOG;
        $| = 1;
        print $service;
        select $old_fh;
    } elsif ($append_other) {
        ### it wasn't a packet so write it to /var/log/messages
        my $old_fh2 = select MESSAGES;
        $| = 1;
        print $service;
        select $old_fh2;
    }
}
### These statements don't get executed, but for completeness...
close LOG;
close MESSAGES if ($append_other);
close FIFO;
exit 0;
#==================== end main =====================
sub check_facility() {
    my $syslog = '/etc/syslog.conf';
    open SYS, "< $syslog";
    while(<SYS>) {
        next if (/^#/);
        ### this next line should also include a test for $_ =~ /\*.info/...
        return 0 if ($_ =~ /kern.info/ && $_ =~ /psadfifo/);
        ### syslog is logging kern.info to an additional
        ### place instead of just to psadfifo
    }
    close SYS;
    return 1;
}
sub check_config() {
    my @required_vars = qw(KMSGSD_PID_FILE PSAD_FIFO FW_DATA FW_MSG_SEARCH);
    &Psad::validate_config($CONFIG_FILE, \@required_vars, $Config_href);
    return;
}
