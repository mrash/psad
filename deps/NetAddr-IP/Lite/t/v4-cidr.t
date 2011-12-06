use NetAddr::IP::Lite;

$| = 1;

my @addr = (qw(
	       0.0.0.0/0
	       1.0.0.0/1
	       2.0.0.0/2
	       10.0.0.0/8
	       10.0.120.0/24
	       161.196.66.0/25
	       255.255.255.255/32
	       ));

print '1..', scalar @addr, "\n";

my $count = 1;

for my $a (@addr) {
    my $ip = new NetAddr::IP::Lite $a;
    if ($ip->cidr eq $a) {
	print "ok ", $count ++, "\n";
    }
    else {
	print "not ok ", $count ++, "\n";
	print "$a -> ", $ip->cidr, " [", $ip->mask, "]\n";
    }
}
