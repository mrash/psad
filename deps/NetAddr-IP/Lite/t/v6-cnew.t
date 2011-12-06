use NetAddr::IP::Lite;

my @subnets = (
	       [ 'dead:beef:1234::/16', 'DEAD:BEEF:1234:0:0:0:0:0/16' ],
	       [ '::1234:BEEF:DEAD/24', '0:0:0:0:0:1234:BEEF:DEAD/24' ],
# include test for cisco syntax using space instead of '/'
	       [ 'dead:beef:1234:: 16', 'DEAD:BEEF:1234:0:0:0:0:0/16' ],
	       [ '::1234:BEEF:DEAD 24', '0:0:0:0:0:1234:BEEF:DEAD/24' ],
	       [ '::1234:BEEF:DEAD FFFF:FF00::', '0:0:0:0:0:1234:BEEF:DEAD/24' ],
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
	print $ip, "\nnot ok $count\n";
    }

    ++ $count;
}
