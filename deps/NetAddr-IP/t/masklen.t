use NetAddr::IP;

# $Id: masklen.t,v 1.1.1.1 2006/08/14 15:36:06 lem Exp $

my @masks = 0 .. 32;

$| = 1;

print '1..', scalar @masks, "\n";

my $count = 1;

for my $m (@masks) {
    my $ip = new NetAddr::IP '10.0.0.1', $m;
    if ($ip->masklen == $m) {
	print "ok ", $count ++, "\n";
    }
    else {
	print "not ok ", $count ++, "\n";
    }
}
