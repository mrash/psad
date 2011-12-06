# This -*- perl -*- code excercises the basic v6 functionality

sub mypass() {1}
sub myfail() {0}

@addr =
    (
     ['::',  3, '0:0:0:0:0:0:0:0/128',myfail],
     ['::1', 3, '0:0:0:0:0:0:0:1/128',myfail],
     ['F34::123 40', 2, 'F34:0:0:0:0:0:0:3/40',mypass],
     ['DEAD:BEEF::1 40', 2, 'DEAD:BEEF:0:0:0:0:0:3/40',mypass],
     ['1000::2 40', 0, '1000:0:0:0:0:0:0:1/40',mypass],
     ['1000::2000 40', 0, '1000:0:0:0:0:0:0:1/40',mypass],
     ['DEAD::CAFE 40', 0, 'DEAD:0:0:0:0:0:0:1/40',mypass],
     ['DEAD:BEEF::1 40', 3, 'DEAD:BEEF:0:0:0:0:0:4/40',mypass],
     ['DEAD:BEEF::1 40', 4, 'DEAD:BEEF:0:0:0:0:0:5/40',mypass],
     ['DEAD:BEEF::1 40', 5, 'DEAD:BEEF:0:0:0:0:0:6/40',mypass],
     ['DEAD:BEEF::1 40', 6, 'DEAD:BEEF:0:0:0:0:0:7/40',mypass],
     ['DEAD:BEEF::1 40', 7, 'DEAD:BEEF:0:0:0:0:0:8/40',mypass],
     ['DEAD:BEEF::1 40', 8, 'DEAD:BEEF:0:0:0:0:0:9/40',mypass],
     ['DEAD:BEEF::1 40', 254, 'DEAD:BEEF:0:0:0:0:0:FF/40',mypass],
     ['DEAD:BEEF::1 40', 255, 'DEAD:BEEF:0:0:0:0:0:100/40',mypass],
     ['DEAD:BEEF::1 40', 256, 'DEAD:BEEF:0:0:0:0:0:101/40',mypass],
     ['DEAD:BEEF::1 40', 65535, 'DEAD:BEEF:0:0:0:0:1:0/40',mypass],
     ['DEAD:BEEF::1 40', 65536, 'DEAD:BEEF:0:0:0:0:1:1/40',mypass],
     ['2001:620:0:4::/64', 0, '2001:620:0:4:0:0:0:1/64',mypass],
     ['3FFE:2000:0:4::/64', 0, '3FFE:2000:0:4:0:0:0:1/64',mypass],
     ['2001:620:600::1', 0, '2001:620:600:0:0:0:0:1/128',mypass],
     ['2001:620:600:0:1::1', 0,'2001:620:600:0:1:0:0:1/128',mypass],
     );

use NetAddr::IP::Lite;
use Test::More;

my($a, $ip, $test);

$test = 4 * @addr + 4;
plan tests => $test;

$test = 1;

sub tst {
  for $a (@addr) {
	$ip = new_cis NetAddr::IP::Lite $a->[0];
	$a->[0] =~ s,/\d+,,;
	isa_ok($ip, 'NetAddr::IP::Lite', "$a->[0] ");
# requires full NetAddr::IP
#	is(uc $ip->short, $a->[0], "short returns $a->[0]");
	is($ip->bits, 128, "bits == 128");
	is($ip->version, 6, "version == 6");
	my $index = $a->[1];
	if ($a->[3]) {
	  is(uc $ip->nth($index), $a->[2], "nth $a->[0], $index");
	} else {
	  ok(!$ip->nth($index),"nth $a->[0], undef");
	}
 }
}

tst();

$test = new_cis NetAddr::IP::Lite 'f34::1';
isa_ok($test, 'NetAddr::IP::Lite');
ok($test->network->contains($test), "->contains");

$test = new_cis NetAddr::IP::Lite 'f35::1 40';
isa_ok($test, 'NetAddr::IP::Lite');
ok($test->network->contains($test), "->contains");

