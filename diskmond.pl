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
use File::stat;
use File::Copy;
use POSIX 'setsid';
use Getopt::Long 'GetOptions';
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
#my $Archive_files_aref = $Config{'ARCHIVE_FILES'};

### Check to make sure the commands specified in the config section
### are in the right place, and attempt to correct automatically if not.
&Psad::check_commands(\%Cmds);

&Psad::unique_pid($Config{'DISKMOND_PID_FILE'});

### install WARN and DIE handlers
$SIG{'__WARN__'} = \&Psad::warn_handler;
$SIG{'__DIE__'}  = \&Psad::die_handler;

my $pid = fork;
exit if $pid;
die " ** $0: Couldn't fork: $!" unless defined($pid);
POSIX::setsid() or die " ** $0: Can't start a new session: $!\n";

### write the pid to the pid file
&Psad::writepid($Config{'DISKMOND_PID_FILE'});

### initialize partition usage
my $usage     = 0;
my $email_ctr = 0;
my $hostname  = hostname;

my $config_mtime = stat($CONFIG_FILE)->mtime;
#====================== main =======================
### main loop
for (;;) {
    ### See if we need to import any changed config variables
    &check_import_config(\$config_mtime, $CONFIG_FILE);

    $usage = &get_usage();
    ### Check to see if we need to start archiving
    if ($usage >= $Config{'MAX_DISK_PERCENTAGE'}) {
        &rm_data();
        open DW, "> $Config{'PSAD_DIR'}/disk_limit";
        print DW "psad: disk utilization above $Config{'MAX_DISK_PERCENTAGE'}%\n";
        print DW "      on disk partition that holds $Config{'PSAD_DIR'}\n";
        print DW "      diskmond removed all ip directories in " .
            "$Config{'PSAD_DIR'}.\n";
        close DW;
        &Psad::sendmail("psad: disk utilization above $Config{'MAX_DISK_PERCENTAGE'}%",
            "$Config{'PSAD_DIR'}/disk_limit", $Config{'EMAIL_ADDRESSES'},
            $Cmds{'mail'});
        $email_ctr++;
        if ($email_ctr > 50) {
            &Psad::sendmail("psad: diskmond giving up, stopping psad.",
                $Config{'EMAIL_ADDRESSES'}, $Cmds{'mail'});
        }
    } else {
        $email_ctr = 0;
    }
    ### check disk usage every $CHECK_INTERVAL seconds
    sleep $Config{'DISKMOND_CHECK_INTERVAL'};
}
exit 0;
#===================== end main ====================

sub get_usage() {
    my @df_data = `$Cmds{'df'} $Config{'PSAD_DIR'}`;
    my ($prcnt) = ($df_data[$#df_data] =~ /(\d+)%/);
    return $prcnt;
}

sub rm_data() {
    chdir $Config{'PSAD_DIR'} or die
        " ** Could not chdir $Config{'PSAD_DIR'}: $!";

    &rm_scanlog($Config{'PSAD_DIR'});
    &rm_scanlog($Config{'SCAN_DATA_ARCHIVE_DIR'});

    if (-e $Config{'FW_DATA_FILE'}) {
        open F, "> $Config{'FW_DATA_FILE'}";
        close F;
    }
    if (-e "$Config{'SCAN_DATA_ARCHIVE_DIR'}/fwdata_archive") {
        open F, "> $Config{'SCAN_DATA_ARCHIVE_DIR'}/fwdata_archive";
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
        FW_DATA DISKMOND_CHECK_INTERVAL
        MAX_DISK_PERCENTAGE DISKMOND_PID_FILE
        PSAD_DIR SCAN_DATA_ARCHIVE_DIR
    );
    &Psad::defined_vars($CONFIG_FILE, \@required_vars, $Config_href);
    return;
}
