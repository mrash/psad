#!/usr/bin/perl -w

use lib '/usr/lib/psad';
use IPTables::ChainMgr;
use IPTables::Parse;
use strict;

my $ipt = new IPTables::ChainMgr(
    'iptables' => '/sbin/iptables'
);

my ($rv, $status_msg) = $ipt->create_chain('filter', 'PSAD');
print "$status_msg: $rv\n";

($rv, $status_msg) = $ipt->add_jump_rule('filter', 'INPUT', 'PSAD');
print "$status_msg: $rv\n";

($rv, $status_msg) = $ipt->add_ip_rule('1.1.1.1', 'filter', 'PSAD', 'DROP');
print "$status_msg: $rv\n";

$rv = $ipt->find_ip_rule('1.1.1.1', '0.0.0.0/0', 'filter', 'PSAD', 'DROP');
print "find ip: $rv\n";

($rv, $status_msg) = $ipt->add_ip_rule('1.1.1.1', 'filter', 'PSAD', 'DROP');
print "$status_msg: $rv\n";

($rv, $status_msg) = $ipt->delete_ip_rule('1.1.1.1', 'filter', 'PSAD', 'DROP');
print "$status_msg: $rv\n";

($rv, $status_msg) = $ipt->delete_chain('filter', 'INPUT', 'PSAD');
print "$status_msg: $rv\n";

exit 0;
