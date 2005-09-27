#
##################################################################
#
# File: Psad.pm
#
# Purpose: This is the Psad.pm perl module.  It contains functions
#          that are reused by the various psad daemons.
#
# Author: Michael Rash (mbr@cipherdyne.org)
#
# Version: 1.4.3
#
##################################################################
#
# $Id$
#

package Psad;

use lib '/usr/lib/psad';
use Exporter;
use Unix::Syslog qw(:subs :macros);
use Carp;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(
    buildconf
    defined_vars
    pidrunning
    writepid
    writecmdline
    unique_pid
    check_commands
    sendmail
    psyslog
    print_sys_msg
);

$VERSION = '1.4.3';

### subroutines ###
sub buildconf() {
    my ($config_hr, $cmds_hr, $conf_file) = @_;

    open C, "< $conf_file" or croak "[*] Could not open " .
        "config file $conf_file: $!";
    my @lines = <C>;
    close C;
    for my $line (@lines) {
        chomp $line;
        next if ($line =~ /^\s*#/);
        if ($line =~ /^\s*(\S+)\s+(.*?)\;/) {
            my $varname = $1;
            my $val     = $2;
            if ($val =~ m|/.+| && $varname =~ /^\s*(\S+)Cmd$/) {
                ### found a command
                $cmds_hr->{$1} = $val;
            } else {
                $config_hr->{$varname} = $val;
            }
        }
    }
    return;
}

### check to make sure all required varables are defined in the config
### this subroutine is passed different variables by each script that
### correspond to only those variables needed be each script).
sub defined_vars() {
    my ($config_hr, $conf_file, $varnames_aref) = @_;
    for my $var (@$varnames_aref) {
        unless (defined $config_hr->{$var}) {  ### missing var
            croak "[*] The config file \"$conf_file\" does not " .
                  "contain the\nvariable: \"$var\".  Exiting!";
        }
    }
    return;
}

### check paths to commands and attempt to correct if any are wrong.
sub check_commands() {
    my $cmds_href = shift;
    my $caller = $0;
    my @path = qw(
        /bin
        /sbin
        /usr/bin
        /usr/sbin
        /usr/local/bin
        /usr/local/sbin
    );
    CMD: for my $cmd (keys %$cmds_href) {
        ### syslog is a special case (see SYSLOG_DAEMON var in psad code)
        next if $cmd =~ /syslog/i;

        ### both mail and sendmail are special cases, mail is not required
        ### if "nomail" is set in REPORT_METHOD, and sendmail is only
        ### required if DShield alerting is enabled and a DShield user
        ### email is set.
        next if $cmd =~ /mail/i;
        unless (-x $cmds_href->{$cmd}) {
            my $found = 0;
            PATH: for my $dir (@path) {
                if (-x "${dir}/${cmd}") {
                    $cmds_href->{$cmd} = "${dir}/${cmd}";
                    $found = 1;
                    last PATH;
                }
            }
            unless ($found) {
                croak "[*] ($caller): Could not find $cmd ",
                    "anywhere!!!\n    Please edit the config section ",
                     "to include the path to $cmd.";
            }
        }
        unless (-x $cmds_href->{$cmd}) {
            croak "[*] ($caller): $cmd is located at ",
                "$cmds_href->{$cmd}, but is not executable\n",
                "    by uid: $<";
        }
    }
    return;
}

sub pidrunning() {
    my $pidfile = shift or croak '[*] Must supply a pid file.';
    return 0 unless -e $pidfile;
    open PIDFILE, "< $pidfile" or croak "[*] Could not open $pidfile: $!";
    my $pid = <PIDFILE>;
    close PIDFILE;
    chomp $pid;
    if (kill 0, $pid) {  ### pid is running
        return $pid;
    }
    return 0;
}

### make sure pid is unique
sub unique_pid() {
    my $pidfile = shift;
    croak "[*] $0 process is already running! Exiting.\n"
        if &pidrunning($pidfile);
    return;
}

### write the pid to the pid file
sub writepid() {
    my $pidfile = shift;
    my $caller = $0;
    open PIDFILE, "> $pidfile" or croak "[*] $caller: Could not " .
        "open pidfile $pidfile: $!\n";
    print PIDFILE $$ . "\n";
    close PIDFILE;
    chmod 0600, $pidfile;
    return;
}

### write command line to cmd file
sub writecmdline() {
    my ($args_aref, $cmdline_file) = @_;
    open CMD, "> $cmdline_file";
    print CMD "@$args_aref\n";
    close CMD;
    chmod 0600, $cmdline_file;
    return;
}

### send mail message to all addresses contained in the
### EMAIL_ADDRESSES variable within psad.conf ($addr_str).
### TODO:  Would it be better to use Net::SMTP here?
sub sendmail() {
    my ($subject, $body_file, $addr_str, $mailCmd) = @_;
    open MAIL, "| $mailCmd -s \"$subject\" $addr_str > /dev/null" or croak
        "[*] Could not send mail: $mailCmd -s \"$subject\" $addr_str: $!";
    if ($body_file) {
        open F, "< $body_file" or croak "[*] Could not open mail file: ",
            "$body_file: $!";
        my @lines = <F>;
        close F;
        print MAIL for @lines;
    }
    close MAIL;
    return;
}

### write a message to syslog
sub psyslog() {
    my ($ident, $msg) = @_;
    ### write a message to syslog and return
    openlog $ident, LOG_DAEMON, LOG_LOCAL7;
    syslog LOG_INFO, $msg;
    closelog();
    return;
}

### write a message to a file
sub print_sys_msg() {
    my ($msg, $file) = @_;
    open F, ">> $file" or croak "[*] Could not open $file: $!";
    print F scalar localtime(), " $msg";
    close F;
    return;
}

1;
__END__

=head1 NAME

Psad - Perl extension for psad (the Port Scan Attack Detector) daemons

=head1 SYNOPSIS

  use Psad;
  writepid()
  writecmdline()
  unique_pid()
  psyslog()
  check_commands()

=head1 DESCRIPTION

The Psad.pm module contains several subroutines that are used by Port Scan
Attack Detector (psad) daemons.
writepid()  writes process ids to the pid files (e.g. "/var/run/psad.pid").
writecmdline()  writes the psad command line contained within @ARGV[] to the
file "/var/run/psad.cmd".
unique_pid()  makes sure that no other daemon process is already running in
order to guarantee pid uniqueness.
psyslog() an interface to sending messages via syslog.
check_commands()  check paths to commands and warns if unable to find any 
particular command.

=head1 AUTHOR

Michael Rash, mbr@cipherdyne.org

=head1 SEE ALSO

psad(8).
