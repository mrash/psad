use Test::More;

my %cases =
(
 '127.1'           => '127.0.0.1',
 'DEAD:BEEF::1'	   => 'dead:beef::1',

 '1234:5678:90AB:CDEF:0123:4567:890A:BCDE'
    => '1234:5678:90ab:cdef:123:4567:890a:bcde',
);

my $tests = keys %cases;
plan tests => 1 + $tests;

SKIP: {
    use_ok('NetAddr::IP') or skip "Failed to load NetAddr::IP", $tests;
    for my $c (sort keys %cases)
    {
	my $ip = new NetAddr::IP $c;
	my $rv = $ip->canon;
	is($rv, $cases{$c}, "canon($c ) returns $rv");
    }
}
