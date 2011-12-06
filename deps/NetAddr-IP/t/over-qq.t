use NetAddr::IP;

# $Id: over-qq.t,v 1.1.1.1 2006/08/14 15:36:06 lem Exp $

my @addr = ('10.0.0.0/8', '192.168.0.0/16', '127.0.0.1/32');

$| = 1;

print "1..", 5 * scalar @addr, "\n";

my $count = 1;

for my $a (@addr) {
    my $ip = new NetAddr::IP $a;
    if ($a eq "$ip") {
	print "ok $count\n";
    }
    else {
	print "not ok $count\n";
    }
    ++ $count;

    if ($a eq $ip) {
	print "ok $count\n";
    }
    else {
	print "not ok $count\n";
    }
    ++ $count;

    if ($ip eq $a) {
	print "ok $count\n";
    }
    else {
	print "not ok $count\n";
    }
    ++ $count;

    if ($ip eq $ip) {
	print "ok $count\n";
    }
    else {
	print "not ok $count\n";
    }
    ++ $count;

    if ($ip == $ip) {
	print "ok $count\n";
    }
    else {
	print "not ok $count\n";
    }
    ++ $count;

}
