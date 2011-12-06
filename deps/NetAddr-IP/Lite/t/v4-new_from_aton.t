use NetAddr::IP::Util qw(
	inet_aton
	ipv6_n2x
);
use NetAddr::IP::Lite;
use Test::More;
#use diagnostics;

plan tests => 12 + 3;

ok(! defined NetAddr::IP::Lite->new_from_aton(''), "blank netaddr returns undef");
ok(! defined NetAddr::IP::Lite->new_from_aton(undef), "undefined netaddr returns undef");
ok(! defined NetAddr::IP::Lite->new_from_aton('1.2.3.4'), "Dot Quad IP returns undef");

foreach (qw(
	0.0.0.0
	127.0.0.1
	255.255.255.255
)) {
  my $naddr = inet_aton($_);
  my $ip = new_from_aton NetAddr::IP::Lite($naddr);
	ok(defined $ip, "$_ is defined");
	ok($ip->bits == 32, "$_ is 32 bits wide");
	ok($ip->mask eq '255.255.255.255', "mask is all ones");
	ok($ip->version == 4, "version is IPv4");
}

