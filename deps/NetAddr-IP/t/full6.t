use Test::More;

# $Id: short.t,v 1.1.1.1 2006/08/14 15:36:06 lem Exp $

my %cases =
(
 '127.1'					=> '0000:0000:0000:0000:0000:0000:7f00:0001',
 '123.23.4.210'					=> '0000:0000:0000:0000:0000:0000:7b17:04d2',
 'DEAD:BEEF::1'					=> 'dead:beef:0000:0000:0000:0000:0000:0001',
 '1:2:3:4:5:6:7:8'				=> '0001:0002:0003:0004:0005:0006:0007:0008',
 '1234:5678:90AB:CDEF:0123:4567:890A:BCDE'	=> '1234:5678:90ab:cdef:0123:4567:890a:bcde',
);

my $tests = keys %cases;
plan tests => 1 + $tests;

SKIP: {
    use_ok('NetAddr::IP') or skip "Failed to load NetAddr::IP", $tests;
    for my $c (sort keys %cases)
    {
	my $ip = new NetAddr::IP $c;
	my $rv = lc $ip->full6;
	is($rv, $cases{$c}, "full6($c ) returns $rv");
    }
}
