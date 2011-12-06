use NetAddr::IP::Lite;
use Test::More;

my @yes_pairs =
    (
     [ '::/0', '2001:620:0:4:a00:20ff:fe9c:7e4a' ],
     [ '3ffe:2000:0:4::/64', '3ffe:2000:0:4:a00:20ff:fe9c:7e4a' ],
     [ '3ffe:2000:0:4::/64', '3ffe:2000:0:4:a00:20ff:fe9c:7e4a/65' ],
     [ '2001:620:0:4::/64', '2001:620:0:4:a00:20ff:fe9c:7e4a' ],
     [ '2001:620:0:4::/64', '2001:620:0:4:a00:20ff:fe9c:7e4a/65' ],
     [ '2001:620:0:4::/64', '2001:620:0:4::1' ],
     [ '2001:620:0:4::/64', '2001:620:0:4:0:0:0:1' ],
     [ 'deaf:beef::/32', 'deaf:beef::1' ],
     [ 'deaf:beef::/32', 'deaf:beef::1:1' ],
     [ 'deaf:beef::/32', 'deaf:beef::1:0:1' ],
     [ 'deaf:beef::/32', 'deaf:beef::1:0:0:1' ],
     [ 'deaf:beef::/32', 'deaf:beef::1:0:0:0:1' ],
     );

my @no_pairs =
    (
     [ '3ffe:2000:0:4::/64', '3ffe:2000:0:4:a00:20ff:fe9c:7e4a/63' ],
     [ '2001:620:0:4::/64', '2001:620:0:4:a00:20ff:fe9c:7e4a/63' ],
     [ 'deaf:beef::/32', 'dead:cafe::1' ],
     [ 'deaf:beef::/32', 'dead:cafe::1:1' ],
     [ 'deaf:beef::/32', 'dead:cafe::1:0:1' ],
     [ 'deaf:beef::/32', 'dead:cafe::1:0:0:1' ],
     [ 'deaf:beef::/32', 'dead:cafe::1:0:0:0:1' ],
     );

my $tests = 6 * @yes_pairs + 1;
plan tests => $tests;

ok(NetAddr::IP::Lite->new('::')->contains(NetAddr::IP::Lite->new('::')),
   ":: contains itself");

for my $p (@yes_pairs)
{
    my $a = new NetAddr::IP::Lite $p->[0];
    my $b = new NetAddr::IP::Lite $p->[1];

    isa_ok($a, 'NetAddr::IP::Lite', "$p->[0]");
    isa_ok($b, 'NetAddr::IP::Lite', "$p->[1]");

  SKIP: {
      ok($a->contains($b), "->contains $p->[0], $p->[1] is true");
      ok($b->within($a), "->within $p->[1], $p->[0] is true");
      ok(!$b->contains($a), "->contains $p->[1], $p->[0] is false");
      ok(!$a->within($b), "->within $p->[0], $p->[1] is false");
  }
}
