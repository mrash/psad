#!/usr/bin/perl -w
#
###############################################################################
#
# File: snort_compat.pl
#
# Purpose: To assist in the construction of a set of Snort rules that can be
#          made compatible with psad.
#
# Methodology:  Psad exclusively uses Netfilter log messages as its source
#   of intrusion detection data.  This means that psad cannot accurately
#   detect most Snort rules because payload data is not available (the
#   Netfilter string match extension can provide string matching capabilities
#   against application layer data; see "fwsnort" at
#   http://www.cipherdyne.org/fwsnort).  However, there are several backdoor
#   programs, DDoS tools, and other suspect traffic that can be inferred from
#   looking at transport layer data (for tcp and udp) as long as it does not
#   involve a commonly used IANA specified port number.  For example, consider
#   the following three Snort rules, which are designed to detect various
#   communication aspects of the Trin00 DDoS tool:
#
#   alert tcp $EXTERNAL_NET any -> $HOME_NET 27665 (msg:"DDOS Trin00 Attacker to Master default startup password"; flow:established,to_server; content:"betaalmostdone"; reference:arachnids,197; classtype:attempted-dos; sid:233; rev:3;)
#   alert tcp $EXTERNAL_NET any -> $HOME_NET 27665 (msg:"DDOS Trin00 Attacker to Master default password"; flow:established,to_server; content:"gOrave"; classtype:attempted-dos; sid:234; rev:2;)
#   alert tcp $EXTERNAL_NET any -> $HOME_NET 27665 (msg:"DDOS Trin00 Attacker to Master default mdie password"; flow:established,to_server; content:"killme"; classtype:bad-unknown; sid:235; rev:2;)
#
#   Each of the above rules uses the Snort "content" keyword to detect a
#   specific aspect of the Trin00 communication in order to be able to
#   distinguish the "default startup password" from the "default password"
#   for example.  Each of the rules only applies to traffic over an
#   established TCP session (see the "established" argument give to the
#   "flow" keyword).  It is impossible to extract the same level of
#   granularity from Netfilter logs alone.  However, if Netfilter logs a SYN
#   packet directed to TCP port 27665, it is a good bet that a Trin00 DDoS
#   client is attempting to contact a Trin00 master client.  Hence psad will
#   generate the alert "DDOS Trin00 Attacker to Master" upon monitoring such
#   a packet in the Netfilter log.  Even if the Snort rules above are
#   improved by the Snort community to use the more advanced features of the
#   Snort rules language, the basic fact that SYN packets to TCP/27665 may
#   be associated with the Trin00 DDoS remains.  This is the general
#   methodology used to write psad signatures that are derived from Snort
#   rules.  Of course, this type of analysis is not possible for heavily
#   utilized services that run over IANA specified ports (such as web, dns,
#   and stmp servers for example).  Detecting attacks over such services
#   requires application data inspection as provided by the Snort rules
#   language.  The snort_compat.pl script generates a listing of Snort rules
#   that may be compatible with psad.  The resulting rules are then reviewed
#   and altered for inclusion within the psad signatures file.
#
###############################################################################
#
# $Id$
#

use Data::Dumper;
use strict;

#=========================== config =============================
my $services_file  = '/etc/services';
my $rules_dir      = 'snort_rules';

### ignore all snort rules in these files
my @ignore_files = (
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
$services{'tcp'}{'80'} = '' unless defined $services{'tcp'};
$services{'udp'}{'53'} = '' unless defined $services{'udp'};

if ($ARGV[0]) {
    push @files, $ARGV[0];
} else {
    opendir D, $rules_dir or die " ** Could not open $rules_dir";
    @files = readdir D;
    closedir D;
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

            next RULE if ($rule =~ /content:/
                    and $src_p eq 'any' and $dst_p eq 'any');

            if (not defined $services{$proto}) {
                print $rule, "\n";
            } else {
                my @src_p_arr;
                my @dst_p_arr;
                if ($src_p =~ /:/) {
                    @src_p_arr = split /\s*:\s*/, $src_p;
                } else {
                    push @src_p_arr, $src_p;
                }
                if ($dst_p =~ /:/) {
                    @dst_p_arr = split /\s*:\s*/, $dst_p;
                } else {
                    push @dst_p_arr, $dst_p;
                }

                for my $src_p (@src_p_arr) {
                    next RULE if defined $services{$proto}{$src_p};
                }
                for my $dst_p (@dst_p_arr) {
                    next RULE if defined $services{$proto}{$dst_p};
                }

                print $rule, "\n";
            }
        }
    }
    print "\n";
}
exit 0;
