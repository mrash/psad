use NetAddr::IP;
use Test::More;

my @addr = ( [ '10.0.0.0/24', '10.0.0.1/32' ],
	     [ '192.168.0.0/24', '192.168.0.1/32' ],
	     [ '127.0.0.1/32', '127.0.0.1/32' ] );

$| = 1;

$tests = @addr;

plan tests => $tests;

SKIP: {
  skip "overload dereferencing not supported in version $] of Perl", $tests, unless ($overload::ops{dereferencing} && $overload::ops{dereferencing} =~ /\@\{\}/);
  for my $a (@addr) {
    my $ip = new NetAddr::IP $a->[0];
    ok(@$ip[0]->cidr eq $a->[1],$a->[0]);
  }
};
