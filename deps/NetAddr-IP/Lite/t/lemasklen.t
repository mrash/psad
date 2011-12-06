use NetAddr::IP::Lite;

my @masks = 0 .. 32;

$| = 1;

print '1..', scalar @masks, "\n";

my $count = 1;

for my $m (@masks) {
    my $ip = new NetAddr::IP::Lite '10.0.0.1', $m;
    if ($ip->masklen == $m) {
	print "ok ", $count ++, "\n";
    }
    else {
	print "not ok ", $count ++, "\n";
    }
}
