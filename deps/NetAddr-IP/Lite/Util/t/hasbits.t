# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)
$| = 1;
END {print "1..1\nnot ok 1\n" unless $test;}

use NetAddr::IP::Util qw(
	ipv6_aton
	ipv6_n2x
	hasbits
);

$test = 1;

sub ok {
  print "ok $test\n";
  ++$test;
}

my @num = qw	# input
(
	::
	8000::
	4000::
	2000::
	1000::
	800::
	400::
	200::
	100::
	80::
	40::
	20::
	10::
	1::
	0:8000::
	0:4000::
	0:2000::
	0:1000::
	0:800::
	0:400::
	0:200::
	0:100::
	0:80::
	0:40::
	0:20::
	0:10::
	0:1::
	0:0:8000::
	0:0:4000::
	0:0:2000::
	0:0:1000::
	0:0:800::
	0:0:400::
	0:0:200::
	0:0:100::
	0:0:80::
	0:0:40::
	0:0:20::
	0:0:10::
	0:0:1::
	0:0:0:8000::
	0:0:0:4000::
	0:0:0:2000::
	0:0:0:1000::
	0:0:0:800::
	0:0:0:400::
	0:0:0:200::
	0:0:0:100::
	0:0:0:80::
	0:0:0:40::
	0:0:0:20::
	0:0:0:10::
	0:0:0:1::
	::8000:0:0:0
	::4000:0:0:0
	::2000:0:0:0
	::1000:0:0:0
	::800:0:0:0
	::400:0:0:0
	::200:0:0:0
	::100:0:0:0
	::80:0:0:0
	::40:0:0:0
	::20:0:0:0
	::10:0:0:0
	::1:0:0:0
	::8000:0:0
	::4000:0:0
	::2000:0:0
	::1000:0:0
	::800:0:0
	::400:0:0
	::200:0:0
	::100:0:0
	::80:0:0
	::40:0:0
	::20:0:0
	::10:0:0
	::1:0:0
	::8000:0
	::4000:0
	::2000:0
	::1000:0
	::800:0
	::400:0
	::200:0
	::100:0
	::80:0
	::40:0
	::20:0
	::10:0
	::1:0
	::8000
	::4000
	::2000
	::1000
	::800
	::400
	::200
	::100
	::80
	::40
	::20
	::10
	::1
	::8000:0:0:0:0
	::8000:0:0:0:0:0
	::8000:0:0:0:0:0:0
	8000:0:0:0:0:0:0:0
);
# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
print '1..',(scalar @num), "\n";

foreach (@num) {
  my $bstr = ipv6_aton($_);
  my $rv = hasbits($bstr);
  my $exp = ($_ eq '::') ? 0:1;
  print "got: $rv, exp: $exp for ", ipv6_n2x($bstr), "\nnot "
	 unless $rv eq $exp;
  &ok;
}
