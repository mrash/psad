use NetAddr::IP::Lite;

my @subnets = (
	       [ '127.1', '127.0.0.1/32' ],
	       [ '127.1/16', '127.1.0.0/16' ],
	       [ '10.10.10', '10.10.0.10/32' ],
	       [ '10.10.10/24', '10.10.10.0/24' ],
# include test for cisco syntax using space instead of '/'
	       [ '127.1 16', '127.1.0.0/16' ],
	       [ '10.10.10 24', '10.10.10.0/24' ],
	       [ '10.10.10 255.255.255.0', '10.10.10.0/24' ],
	       );

$| = 1;

print '1..', (scalar @subnets) , "\n";

my $count = 1;

for my $n (@subnets) {
    my $ip = new NetAddr::IP::Lite $n->[0];
    if ($ip eq $n->[1]) {
	print "ok $count\n";
    }
    else {
	print "not ok $count\n";
    }

    ++ $count;
}
