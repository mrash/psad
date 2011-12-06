# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..34\n"; }
END {print "not ok 1\n" unless $loaded;}

use NetAddr::IP::Util qw(
	sub128
	ipv6_aton
	ipv6_n2x
);

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}
my @num = # 	number			minus	  carry (not borrow)	exp
qw(
	::f712:fff:fffe		::f712:fff:fffc		1	0:0:0:0:0:0:0:2
	::712:fff:fffe		::712:fff:fffc		1	0:0:0:0:0:0:0:2
	::712:ffff:fffe		::712:ffff:fffc		1	0:0:0:0:0:0:0:2
	::f712:ffff:fffa	::f712:ffff:fffc	0	FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE
	::f712:fff:fffa		::f712:fff:fffc		0	FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE
	::712:fff:fffa		::712:fff:fffc		0	FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE
	::712:ffff:fffa		::712:ffff:fffc		0	FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE
	::2			::1			1	0:0:0:0:0:0:0:1
	::f712:ffff:fffe	::f712:ffff:fffc	1	0:0:0:0:0:0:0:2
	::1			::3			0	FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE
	::1234			::1234			1	0:0:0:0:0:0:0:0
);
## test 2	check comp of zero

for (my $i=0; $i<@num; $i+=4) {
  my $num = ipv6_aton($num[$i]);
  my $minus = ipv6_aton($num[$i +1]);
  my $rv = sub128($num,$minus);
  print "got: $rv, exp: $num[$i +2]\nnot "
	unless $rv == $num[$i +2];
  &ok;
}

for (my $i=0; $i<@num; $i+=4) {
  my $num = ipv6_aton($num[$i]);
  my $minus = ipv6_aton($num[$i +1]);
  my($rv,$dif) = sub128($num,$minus);
  print "got: $rv, exp: $num[$i +2]\nnot "
	unless $rv == $num[$i +2];
  &ok;
  $dif = ipv6_n2x($dif);
  print "got: $dif\nexp: $num[$i +3]\nnot "
	unless $dif eq $num[$i +3];
  &ok;
}

