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
###########################################################################
#
# $Id$
#

use POSIX 'setsid';
use Getopt::Long 'GetOptions';
use strict;

### establish the default path to the config file (can be
### over-ridden with the -c <file> command line option.
my $CONFIG_FILE    = '/etc/psad/kmsgsd.conf';
my $fw_search_file = '/etc/psad/fw_search.conf';

### path to default psad library directory for psad perl modules
my $psad_lib_dir = '/usr/lib/psad';

### configuration hash
my %config;

### commands hash
my %cmds;

### specific fw msg search strings
my @fw_search = ();

### flag used for HUP signal
my $hup_flag = 0;

### handle command line arguments
die " ** Specify the path to the psad.conf file with " .
    "\"-c <file>\".\n\n" unless (GetOptions (
    'config=s' => \$CONFIG_FILE
));

### import psad perl modules
&import_psad_perl_modules();

### import config
&import_config();

### make sure there is not another kmsgsd already running
&Psad::unique_pid($config{'KMSGSD_PID_FILE'});

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
    my $service = <FIFO>;
    if (defined $service
        && ($service =~ /Packet\slog/ || $service =~ /IN.+?OUT/)
        && ($service =~ /$config{'FW_MSG_SEARCH'}/
        && (&found_fw_msg($service))
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
        &Psad::psyslog('psad(kmsgsd)', 'received HUP signal, ' .
            're-importing kmsgsd.conf');
    }
}
### These statements don't get executed, but for completeness...
close LOG;
close FIFO;
exit 0;
#==================== end main =====================

sub found_fw_msg() {
    my $str = shift;
    return 1 if $config{'FW_SEARCH_ALL'} eq 'Y';
    for my $pattern (@fw_search) {
        my $pat = qr|$pattern|;
        return 1 if $str =~ m|$pat|;
    }
    return 0;
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
    shift @dirs; shift @dirs;

    push @paths, $psad_lib_dir;

    for my $dir (@dirs) {
        ### get directories like "/usr/lib/psad/x86_64-linux"
        next unless -d "$psad_lib_dir/$dir";
        push @paths, "$psad_lib_dir/$dir"
            if $dir =~ m|linux| or $dir =~ m|thread|;
    }
    return \@paths;
}

sub import_config() {

    ### read in the configuration file
    &Psad::buildconf(\%config, \%cmds, $CONFIG_FILE);

    ### import FW_MSG_SEARCH strings
    &import_fw_search();

    ### expand any embedded vars within config values
    &Psad::expand_vars(\%config, \%cmds);

    ### make sure the configuration is complete
    &required_vars();

    ### Check to make sure the commands specified in the config section
    ### are in the right place, and attempt to correct automatically if not.
    &Psad::check_commands(\%cmds, {});

    return;
}

sub import_fw_search() {
    open F, "< $fw_search_file" or die "[*] Could not open fw search ",
        "string file $fw_search_file: $!";
    my @lines = <F>;
    close F;
    my $found_fw_search = 0;
    for my $line (@lines) {
        next unless $line =~ /\S/;
        next if $line =~ /^\s*#/;
        if ($line =~ /^\s*FW_MSG_SEARCH\s+(.*?);/) {
            push @fw_search, $1;
            $found_fw_search = 1;
        } elsif ($line =~ /^\s*FW_SEARCH_ALL\s+(\w+);/) {
            my $strategy = $1;
            if ($strategy eq 'Y' or $strategy eq 'N') {
                $config{'FW_SEARCH_ALL'} = $strategy;
            }
        }
    }

    $config{'FW_SEARCH_ALL'} = 'Y'
        unless defined $config{'FW_SEARCH_ALL'};

    unless ($config{'FW_SEARCH_ALL'} eq 'Y' or
            $config{'FW_SEARCH_ALL'} eq 'N') {
        $config{'FW_SEARCH_ALL'} = 'Y';
    }

    if ($config{'FW_SEARCH_ALL'} eq 'N' and not $found_fw_search) {
        push @fw_search, 'DROP';
    }
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
