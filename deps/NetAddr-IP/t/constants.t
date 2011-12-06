
#use diagnostics;
use Test::More tests => 15;
use NetAddr::IP qw(Zeros Zero Ones V4mask V4net);

my %const = (
  '0::'						=> Zeros,
  '::'						=> Zero,
  'FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF'	=> Ones,
  'FFFF:FFFF:FFFF:FFFF:FFFF:FFFF::'		=> V4mask,
  '::FFFF:FFFF'					=> V4net,
);

my($ip,$rv);
foreach (sort keys %const) {
  ok(($ip = new NetAddr::IP($_)),"netaddr $_");
  ok($ip->{addr} eq $const{$_},"match $_");
  ok(($rv = length($const{$_})) == 16, "length $_ is $rv");
}

