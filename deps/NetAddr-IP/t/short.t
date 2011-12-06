use Test::More;

# $Id: short.t,v 1.1.1.1 2006/08/14 15:36:06 lem Exp $

my %cases = qw(
  127.1			 127.0.0.1
  127.0.1.1		 127.0.1.1
  127.1.0.1		 127.1.0.1
  DEAD:BEEF::1		 dead:beef::1
  ::1			 0:0::1
  2001:620:600::1	 2001:620:600::1
  2001:620:600:0:1::1	 2001:620:600:0:1::1
  2001:620:601:0:1::1	 2001:620:601::1:0:0:1
  0:0:33:44::CC:DD	 0:0:33:44:0:0:CC:DD
  0:0:33:44::DD	   	 0:0:33:44:0:0:0:DD
  0:0:33:44:AA::	 0:0:33:44:AA:0:0:0
  0:0:33::BB:0:0	 0:0:33:0:0:BB:0:0
  0:22:33:44:0:BB:CC:0	 0:22:33:44:0:BB:CC:0
  0:22:33:44:0:BB:CC:DD	 0:22:33:44:0:BB:CC:DD
  0:22:33:44:AA:BB:CC:0	 0:22:33:44:AA:BB:CC:0
  0:22:33:44:AA:BB:CC:DD 0:22:33:44:AA:BB:CC:DD
  110:0:0:44:AA::	 110:0:0:44:AA:0:0:0
  11:0:33:44:0:BB:CC:DD	 11:0:33:44:0:BB:CC:DD
  11:0:33:44:AA:BB:CC:DD 11:0:33:44:AA:BB:CC:DD
  11:22:0:44:AA::DD	 11:22:0:44:AA:0:0:DD
  11:22:33:0:AA:BB:CC:0	 11:22:33:0:AA:BB:CC:0
  11:22:33:44:AA::	 11:22:33:44:AA:0:0:0
  11:22::CC:DD		 11:22:0:0:0:0:CC:DD
  11::44:AA:0:0:DD	 11:0:0:44:AA:0:0:DD
  11::44:AA:BB:0:0	 11:0:0:44:AA:BB:0:0
  11::AA:0:0:DD		 11:0:0:0:AA:0:0:DD
  11::AA:BB:0:0		 11:0:0:0:AA:BB:0:0
  1::			 1:0:0:0:0:0:0:0
  ::			 0:0:0:0:0:0:0:0
  ::33:44:AA:BB:0:0	 0:0:33:44:AA:BB:0:0
  ::44:0:0:CC:DD	 0:0:0:44:0:0:CC:DD
  ::44:AA:BB:0:0	 0:0:0:44:AA:BB:0:0
  ::44:AA:BB:CC:DD	 0:0:0:44:AA:BB:CC:DD
  ::A			 0:0:0:0:0:0:0:A
 );

my $tests = 2 * keys %cases;
plan tests => 1 + $tests;

SKIP: {
    use_ok('NetAddr::IP') or skip "Failed to load NetAddr::IP", $tests;
    for my $c (sort keys %cases)
    {
	my $ip = new NetAddr::IP $cases{$c};
	isa_ok($ip, 'NetAddr::IP', "$cases{$c}");
	my $short = uc $ip->short;
	unless (is($short, $c, "short($cases{$c}) returns $short"))
	{
	    diag "ip=$ip";
	}
    }
}
