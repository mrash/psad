#!/usr/bin/perl -w
#
##############################################################################
#
# File: snort_compat.pl
#
# Purpose: To generate a listing of snort rules that are compatible with psad
#          according to the following criteria:
#
#   - Most snort rules include a "content:" field to instruct snort to
#     inspect the application portion of packets.  Psad relies strictly on
#     iptables log messages to detect suspect traffic, and hence cannot
#     inspect the application portion of packets (unless the iptables string
#     match extension is being used; see "fwsnort":
#     http://www.cipherdyne.org/fwsnort).  However, iptables log messages do
#     include information on many fields of the transport and network headers
#     so psad just ignores the content field, but only for those tcp and udp
#     signatures that do not involve traffic over IANA assigned ports.  There
#     are many such backdoor and ddos signatures since these programs
#     frequently communicate over custom port numbers.
#
#   - Several additional snort options cannot be matched within iptables
#     log messages, and hence all such snort rules are not compatible with
#     psad.  Such options include:
#
#           dsize
#           ack
#           fragbits
#           content-list
#           rpc
#           byte_test
#           byte_jump
#           distance
#           within
#
##############################################################################
#
# $Id$
#

use Data::Dumper;
use strict;

#=========================== config =============================
my $services_file  = '/etc/services';
my $rules_dir      = 'snort_rules';

my @unsupported_opts = (
    'dsize:',
    'ack:',
    'fragbits:',
#    'content-list:',
    'rpc:',
    'byte_test:',
    'byte_jump:',
    'distance:',
    'within:',
    'seq:',
    'ack:'
);

### ignore all snort rules in these files
my @ignore_files = (
    'attack-responses.rules',
    'deleted.rules',
    'exploit.rules',  ### really need content inspection for these
    'web-misc.rules',
    'chat.rules'
);
#========================= end config ===========================

my %services;
my @files;

open S, "< $services_file" or die " ** Could not open $services_file";
my @lines = <S>;
close S;
for my $line (@lines) {
    chomp $line;
    ### sunrpc          111/tcp
    if ($line =~ m|^\s*(\S+)\s+(\d+)/(\S+)|) {
        my $service = $1;
        my $port    = $2;
        my $proto   = $3;
        $services{$proto}{$port} = $service;
    }
}

if ($ARGV[0]) {
    push @files, $ARGV[0];
} else {
    opendir D, $rules_dir or die " ** Could not open $rules_dir";
    @files = readdir D;
    closedir D;
    shift @files; shift @files;
}

FILE: for my $file (@files) {
    next unless $file =~ /rules/;
    for my $ignore_file (@ignore_files) {
        next FILE if $file eq $ignore_file;
    }
    open R, "< $rules_dir/$file" or die;
    my @rules = <R>;
    close R;

    print "### $file\n";
    RULE: for my $rule (@rules) {
        chomp $rule;
        next RULE unless $rule =~ /^\s*alert/;
        if ($rule =~ m|^alert\s+(\S+)\s+(\S+)\s+(\S+)
                        \s+(\S+)\s+(\S+)\s+(\S+)|x) {
            my $proto = $1;
            my $src_p = $3;
            my $dst_p = $6;
            next RULE if $src_p =~ /\$/;  ### skip things like $HTTP_PORTS
            next RULE if $dst_p =~ /\$/;
            my $found_unsupported = 0;
            for my $opt (@unsupported_opts) {
                $found_unsupported = 1 if $rule =~ /$opt/;
            }
            ### skip rules that contain unsupported options
            next RULE if $found_unsupported;
#            next if $src_p =~ /\D/ and $dst_p =~ /\D/;

            next RULE if ($rule =~ /content:/
                    and $src_p eq 'any' and $dst_p eq 'any');
            if ($rule !~ /content:/) {
                print $rule, "\n";
            } elsif (! defined $services{$proto}) {
                print $rule, "\n";
#            } elsif (!defined $services{$proto}{$src_p}
            } elsif (!defined $services{$proto}{$src_p}
                    and !defined $services{$proto}{$dst_p}) {
                print $rule, "\n";
            } else {
                ### we matched a signature that has a content: field
                ### and depends on a IANA specified port
            }
        }
    }
    print "\n";
}
exit 0;
