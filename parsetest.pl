#!/usr/bin/perl -w
#
#####################################################################
#
# File: parsetest.pl
#
# Purpose: To test substr() vs. regex-based packet parser routine
#          in psad.
#
# Execution: perl -d:DProf ./parsetest.pl && dprofpp tmon.out
#
# Author: Michael Rash
#
# Sample output (it seems clear that the regex parser is faster):
#
#    $  perl -d:DProf ./parsetest.pl && dprofpp tmon.out
#    Sat Nov  1 09:16:53 2003 .. generating packet array.
#    Sat Nov  1 09:16:53 2003 .. parse1()
#    Sat Nov  1 09:16:56 2003 .. parse2()
#    icmp: 20002
#    Total Elapsed Time =  3.30997 Seconds
#      User+System Time =  3.30997 Seconds
#    Exclusive Times
#    %Time ExclSec CumulS #Calls sec/call Csec/c  Name
#     82.4   2.730  2.730      1   2.7300 2.7300  main::parse1
#     15.7   0.520  0.520      1   0.5200 0.5200  main::parse2
#     0.30   0.010  0.010      1   0.0100 0.0100  main::BEGIN
#     0.00   0.000 -0.000      1   0.0000      -  strict::import
#     0.00   0.000 -0.000      1   0.0000      -  strict::bits
#
#####################################################################
#

use strict;

my @arr;
my @err_pkts;
my $tcp_ctr;
my $udp_ctr;
my $icmp_ctr;
my $test_pkt = 'Oct 31 13:07:46 orthanc kernel: DROP IN=eth0 ' .
    'OUT= MAC=00:a0:cc:28:42:5a:00:01:5c:22:2e:42:08:00 ' .
    'SRC=208.205.78.126 DST=68.49.82.239 LEN=92 TOS=0x00 ' .
    'PREC=0x00 TTL=112 ID=39829 PROTO=ICMP TYPE=8 CODE=0 ' .
    'ID=59175 SEQ=21559';

print scalar localtime(), " .. generating packet array.\n";
for (my $i=0; $i<=10000; $i++) {
    push @arr, $test_pkt;
}

print scalar localtime(), " .. parse1()\n";
&parse1();
print scalar localtime(), " .. parse2()\n";
&parse2();

if ($tcp_ctr) {
    print "tcp: $tcp_ctr\n";
}
if ($udp_ctr) {
    print "udp: $udp_ctr\n";
}
if ($icmp_ctr) {
    print "icmp: $icmp_ctr\n";
}

exit 0;
#==================================================

sub parse1() {
    for my $pkt (@arr) {
        my $src = '';
        my $dst = '';
        my $len = -1;
        my $tos = '';
        my $ttl = -1;
        my $id  = -1;
        my $proto = '';
        my $sp    = -1;
        my $dp    = -1;
        my $win   = -1;
        my $type  = -1;
        my $code  = -1;
        my $seq   = -1;
        my $flags = '';
        my $sid   = 0;
        my $chain    = '';
        my $intf     = '';
        my $in_intf  = '';
        my $out_intf = '';
        my $dshield_str = '';
        my $index;

        my @pkt_fields = split /\s+/, $pkt;
        for my $arg (@pkt_fields) {
            $index = index($arg, 'SID');
            if ($index == 0) {
                $sid = substr($arg,
                    $index + length('SID'));
            }
            ### find all of the packet fields
            $index = index($arg, 'IN=');
            if ($index == 0) {
                $in_intf = substr($arg, $index+3);
                next;
            }
            $index = index($arg, 'OUT=');
            if ($index == 0) {
                $out_intf = substr($arg, $index+4);
                next;
            }
            $index = index($arg, 'SRC=');
            if ($index == 0) {
                $src = substr($arg, $index+4);
                next;
            }
            $index = index($arg, 'DST=');
            if ($index == 0) {
                $dst = substr($arg, $index+4);
                next;
            }
            $index = index($arg, 'LEN=');
            if ($index == 0) {
                $len = substr($arg, $index+4);
                next;
            }
            $index = index($arg, 'TOS=');
            if ($index == 0) {
                $tos = substr($arg, $index+4);
                next;
            }
            $index = index($arg, 'TTL=');
            if ($index == 0) {
                $ttl = substr($arg, $index+4);
                next;
            }
            $index = index($arg, 'ID=');
            if ($index == 0) {
                $id = substr($arg, $index+3);
                next;
            }
            $index = index($arg, 'PROTO=');
            if ($index == 0) {
                $proto = substr($arg, $index+6);
                next;
            }
            $index = index($arg, 'SPT=');
            if ($index == 0) {
                $sp = substr($arg, $index+4);
                next;
            }
            $index = index($arg, 'DPT=');
            if ($index == 0) {
                $dp = substr($arg, $index+4);
                next;
            }
            $index = index($arg, 'WINDOW=');
            if ($index == 0) {
                $win = substr($arg, $index+7);
                next;
            }
            $index = index($arg, 'TYPE=');
            if ($index == 0) {
                $type = substr($arg, $index+5);
                next;
            }
            $index = index($arg, 'CODE=');
            if ($index == 0) {
                $code = substr($arg, $index+5);
                next;
            }
            $index = index($arg, 'SEQ=');
            if ($index == 0) {
                $seq = substr($arg, $index+4);
                next;
            }
        }

        ### get the in/out interface and iptables chain
        if ($in_intf and not $out_intf) {
            $intf = $in_intf;
            $chain = 'input';
        } elsif ($in_intf and $out_intf) {
            $intf = $in_intf;
            $chain = 'forward';
        } elsif (not $in_intf and $out_intf) {
            $intf = $out_intf;
            $chain = 'output';
        }

        unless ($intf and $chain) {
            push @err_pkts, $pkt;
            next PKT;
        }

        ### May 18 22:21:26 orthanc kernel: DROP IN=eth2 OUT=
        ### MAC=00:60:1d:23:d0:01:00:60:1d:23:d3:0e:08:00 SRC=192.168.20.25
        ### DST=192.168.20.1 LEN=60 TOS=0x10 PREC=0x00 TTL=64 ID=47300 DF
        ### PROTO=TCP SPT=34111 DPT=6345 WINDOW=5840 RES=0x00 SYN URGP=0
        if ($proto eq 'TCP') {
            if ($pkt =~ /\sRES=\S+\s*(.*)\s+URGP=/) {
                    $flags = $1;
            }
            $proto = 'tcp';
            $flags = 'NULL' unless $flags;  ### default to NULL
            if (!$sid and ($flags =~ /ACK/ || $flags =~ /RST/)) {
                push @err_pkts, $pkt;
                next PKT;
            }
            unless ($flags !~ /WIN/ &&
                    $flags =~ /ACK/ ||
                    $flags =~ /SYN/ ||
                    $flags =~ /RST/ ||
                    $flags =~ /URG/ ||
                    $flags =~ /PSH/ ||
                    $flags =~ /FIN/ ||
                    $flags eq 'NULL') {
                push @err_pkts, $pkt;
                next PKT;
            }
            ### make sure we have a "reasonable" packet (note that nmap
            ### can scan port 0 and iptables can report this fact)
            unless ($src and $dst and $len >= 0 and $tos and $ttl >= 0
                    and $id >= 0 and $proto and $sp >= 0 and $dp >= 0
                    and $win >= 0 and $flags) {
                push @err_pkts, $pkt;
                next PKT;
            }
            $tcp_ctr++;
        ### May 18 22:21:26 orthanc kernel: DROP IN=eth2 OUT=
        ### MAC=00:60:1d:23:d0:01:00:60:1d:23:d3:0e:08:00
        ### SRC=192.168.20.25 DST=192.168.20.1 LEN=28 TOS=0x00 PREC=0x00
        ### TTL=40 ID=47523 PROTO=UDP SPT=57339 DPT=305 LEN=8
        } elsif ($proto eq 'UDP') {
            $proto = 'udp';
            ### make sure we have a "reasonable" packet (note that nmap
            ### can scan port 0 and iptables can report this fact)
            unless ($src and $dst and $len >= 0 and $tos and $ttl >= 0
                    and $id >= 0 and $proto and $sp >= 0 and $dp >= 0) {
                push @err_pkts, $pkt;
                next PKT;
            }
            $udp_ctr++;
        } elsif ($proto eq 'ICMP') {
            $proto = 'icmp';
            unless ($src and $dst and $len >= 0 and $ttl >= 0 and $proto
                    and $type >= 0 and $code >= 0 and $id >= 0
                    and $seq >= 0) {
                push @err_pkts, $pkt;
                next PKT;
            }
            $icmp_ctr++;
        } else {
            ### Sometimes the iptables log entry gets messed up due to
            ### buffering issues so we write it to the error log.
            push @err_pkts, $pkt;
            next PKT;
        }
    }
    return;
}

sub parse2() {
    for my $pkt (@arr) {
        my $src = '';
        my $dst = '';
        my $len = -1;
        my $tos = '';
        my $ttl = -1;
        my $id  = -1;
        my $proto = '';
        my $sp    = -1;
        my $dp    = -1;
        my $win   = -1;
        my $type  = -1;
        my $code  = -1;
        my $seq   = -1;
        my $flags = '';
        my $sid   = 0;
        my $chain    = '';
        my $intf     = '';
        my $in_intf  = '';
        my $out_intf = '';
        my $dshield_str = '';
        if ($pkt =~ /SRC=(\S+)\s+DST=(\S+)\s+LEN=(\d+)\s+TOS=(\S+)
                    \s*.*\s+TTL=(\d+)\s+ID=(\d+)\s*.*\s+PROTO=TCP\s+
                    SPT=(\d+)\s+DPT=(\d+)\s+WINDOW=(\d+)\s+
                    RES=\S+\s*(.*)\s+URGP=/x) {
            ($src, $dst, $len, $tos, $ttl, $id, $sp, $dp, $win, $flags) =
                ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10);
            $proto = 'tcp';
            $flags = 'NULL' unless $flags;  ### default to NULL
            if (!$sid and ($flags =~ /ACK/ || $flags =~ /RST/)) {
                next PKT;
            }
            ### per page 595 of the Camel book, "if /blah1|blah2/"
            ### can be slower than "if /blah1/ || /blah2/
            unless ($flags !~ /WIN/ &&
                    $flags =~ /ACK/ ||
                    $flags =~ /SYN/ ||
                    $flags =~ /RST/ ||
                    $flags =~ /URG/ ||
                    $flags =~ /PSH/ ||
                    $flags =~ /FIN/ ||
                    $flags eq 'NULL') {
                push @err_pkts, $pkt;
                next PKT;
            }
            $tcp_ctr++;
        ### May 18 22:21:26 orthanc kernel: DROP IN=eth2 OUT=
        ### MAC=00:60:1d:23:d0:01:00:60:1d:23:d3:0e:08:00
        ### SRC=192.168.20.25 DST=192.168.20.1 LEN=28 TOS=0x00 PREC=0x00
        ### TTL=40 ID=47523 PROTO=UDP SPT=57339 DPT=305 LEN=8
        } elsif ($pkt =~ /SRC=(\S+)\s+DST=(\S+)\s+LEN=(\d+)\s+TOS=(\S+)
                          \s.*TTL=(\d+)\s+ID=(\d+)\s*.*\s+PROTO=UDP\s+
                          SPT=(\d+)\s+DPT=(\d+)/x) {
            ($src, $dst, $len, $tos, $ttl, $id, $sp, $dp) =
                ($1,$2,$3,$4,$5,$6,$7,$8);
            $proto = 'udp';
            $udp_ctr++;
        } elsif ($pkt =~ /SRC=(\S+)\s+DST=(\S+)\s+LEN=(\d+).*
                          TTL=(\d+).*PROTO=ICMP\s+TYPE=(\d+)\s+
                          CODE=(\d+)\s+ID=(\d+)\s+SEQ=(\d+)/x) {
            ($src, $dst, $len, $ttl, $type, $code, $id, $seq) =
                ($1,$2,$3,$4,$5,$6,$7,$8);
            $proto = 'icmp';
            $icmp_ctr++;
        } else {
            ### Sometimes the iptables log entry gets messed up due to
            ### buffering issues so we write it to the error log.
            push @err_pkts, $pkt;
            next PKT;
        }
        if ($pkt =~ /IN=(\S+)\s+OUT=\s/) {
            $intf = $1;
            $chain = 'input';
        } elsif ($pkt =~ /IN=(\S+)\s+OUT=\S/) {
            $intf = $1;
            $chain = 'forward';
        }
    }
    return;
}
