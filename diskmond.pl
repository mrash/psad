#!/usr/bin/perl -w
#
#########################################################################
#
# File: diskmond
#
# Purpose: diskmond checks every 60 seconds to make sure that the disk
#          utilization for the partition that holds the psad "fwdata"
#          file is not beyond a threshold that the administrator
#          defines.
#
# Author: Michael Rash (mbr@cipherdyne.com)
#
# Credits:  (see the CREDITS file)
#
# Version: 1.1.1
#
# Copyright (C) 1999-2002 Michael Rash (mbr@cipherdyne.com)
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
use Sys::Hostname 'hostname';
use File::Copy;
use POSIX 'setsid';
use Getopt::Long 'GetOptions';
use strict;

### establish the default path to the config file (can be
### over-ridden with the -c <file> command line option.
my $CONFIG_FILE = '/etc/psad/diskmond.conf';

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

&Psad::unique_pid($config{'DISKMOND_PID_FILE'});

### install WARN and DIE handlers
$SIG{'__WARN__'} = \&Psad::warn_handler;
$SIG{'__DIE__'}  = \&Psad::die_handler;

### install HUP handler so config can be re-imported
$SIG{'HUP'}  = \&hup_sig;

my $pid = fork;
exit if $pid;
die " ** $0: Couldn't fork: $!" unless defined $pid;
POSIX::setsid() or die " ** $0: Can't start a new session: $!\n";

### write the pid to the pid file
&Psad::writepid($config{'DISKMOND_PID_FILE'});

### initialize partition usage
my $usage     = 0;
my $email_ctr = 0;
my $hostname  = hostname;

#====================== main =======================
### main loop
for (;;) {

    if ($hup_flag) {
        ### clear the HUP flag and re-import the config
        $hup_flag = 0;
        &import_config();
        &Psad::psyslog('psad(diskmond)', 'Received HUP signal, ' .
            're-importing diskmond.conf');
    }

    $usage = &get_disk_usage();
    ### Check to see if we need to start archiving
    if ($usage >= $config{'MAX_DISK_PERCENTAGE'}) {
        &rm_data();
        open DW, "> $config{'PSAD_DIR'}/disk_limit";
        print DW "psad: disk utilization above ",
            "$config{'MAX_DISK_PERCENTAGE'}%\n";
        print DW "      on disk partition that holds ",
            "$config{'PSAD_DIR'}\n";
        print DW "      diskmond removed all ip directories in " .
            "$config{'PSAD_DIR'}.\n";
        close DW;
        &Psad::sendmail(" ** psad diskmond: disk utilization above " .
            "$config{'MAX_DISK_PERCENTAGE'}%", "$config{'PSAD_DIR'}/disk_limit",
            $config{'EMAIL_ADDRESSES'}, $cmds{'mail'});
        $email_ctr++;
        if ($email_ctr > 50) {
            &Psad::sendmail(" ** psad: diskmond giving up.  Stopping psad.",
                $config{'EMAIL_ADDRESSES'}, $cmds{'mail'});
        }
    } else {
        $email_ctr = 0;
    }
    ### check disk usage every $CHECK_INTERVAL seconds
    sleep $config{'DISKMOND_CHECK_INTERVAL'};
}
exit 0;
#===================== end main ====================

sub get_disk_usage() {
    my @df_data = `$cmds{'df'} $config{'PSAD_DIR'}`;
    my ($prcnt) = ($df_data[$#df_data] =~ /(\d+)%/);
    return $prcnt;
}

sub rm_data() {
    chdir $config{'PSAD_DIR'} or die
        " ** Could not chdir $config{'PSAD_DIR'}: $!";

    &rm_scanlog($config{'PSAD_DIR'});
    &rm_scanlog($config{'SCAN_DATA_ARCHIVE_DIR'});

    if (-e $config{'FW_DATA_FILE'}) {
        open F, "> $config{'FW_DATA_FILE'}";
        close F;
    }
    if (-e "$config{'SCAN_DATA_ARCHIVE_DIR'}/fwdata_archive") {
        open F, "> $config{'SCAN_DATA_ARCHIVE_DIR'}/fwdata_archive";
        close F;
    }
    return;
}

sub rm_scanlog() {
    my $dir = shift;
    chdir $dir or die " ** Could not chdir($dir): $!\n";
    opendir D, $dir or
        die " ** Could not open dir: $dir: $!";
    my @files = readdir D;
    closedir D;
    shift @files; shift @files;
    for my $file (@files) {
        if ($file =~ /(?:\d{1,3}\.){3}\d{1,3}/ && -d $file) {
            ### we found a directory like /var/log/psad/<ip>, which
            ### contains the scanlog file for this ip
            if (-e "${file}/scanlog") {
                open F, "> ${file}/scanlog";
                close F;
            }
        }
    }
    return;
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
        FW_DATA DISKMOND_CHECK_INTERVAL
        MAX_DISK_PERCENTAGE DISKMOND_PID_FILE
        PSAD_DIR SCAN_DATA_ARCHIVE_DIR
    );
    &Psad::defined_vars($CONFIG_FILE, \@required_vars, \%config);
    return;
}

sub hup_sig() {
    $hup_flag = 1;
    return;
}
