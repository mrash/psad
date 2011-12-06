# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..57\n"; }
END {print "not ok 1\n" unless $loaded;}

use NetAddr::IP::Util qw(
	add128
	sub128
	ipv6_aton
	ipv6_n2x
	comp128
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

my @num = # 	number					plus	      		      carry		exp
qw(
	FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE		::1				0	FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF
	::1				FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE		0	FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF
	::2				FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE		1	0:0:0:0:0:0:0:0
	FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE		::2				1	0:0:0:0:0:0:0:0
	FFFF:FFFF:FFFF:FFFF:FFFF:8FFF:FFFF:FFFE		::7000:0:2			1	0:0:0:0:0:0:0:0
	FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE		::3				1	0:0:0:0:0:0:0:1
	::1						::2				0	0:0:0:0:0:0:0:3
	::FFFF						::FFFF				0	0:0:0:0:0:0:1:FFFE
	::FFFF:FFFF					::FFFF:FFFF			0	0:0:0:0:0:1:FFFF:FFFE
	::FFFF:FFFF:FFFF			::FFFF:FFFF:FFFF			0	0:0:0:0:1:FFFF:FFFF:FFFE
	::FFFF:FFFF:FFFF:FFFF			::FFFF:FFFF:FFFF:FFFF			0	0:0:0:1:FFFF:FFFF:FFFF:FFFE
	::FFFF:FFFF:FFFF:FFFF:FFFF		::FFFF:FFFF:FFFF:FFFF:FFFF		0	0:0:1:FFFF:FFFF:FFFF:FFFF:FFFE
	::FFFF:FFFF:FFFF:FFFF:FFFF:FFFF		::FFFF:FFFF:FFFF:FFFF:FFFF:FFFF		0	0:1:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE
	::FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF	::FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF	0	1:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE
);

## test 2 - 15	check carry
for (my $i=0; $i<@num; $i+=4) {
  my $num = ipv6_aton($num[$i]);
  my $plus = ipv6_aton($num[$i +1]);
  my $rv = add128($num,$plus);
  print "got: $rv, exp: $num[$i +2]\nnot "
	unless $rv == $num[$i +2];
  &ok;
}
## test  16 - 43	check carry + result
for (my $i=0; $i<@num; $i+=4) {
  my $num = ipv6_aton($num[$i]);
  my $plus = ipv6_aton($num[$i +1]);
  my($rv,$result) = add128($num,$plus);
  print "got: $rv, exp: $num[$i +2]\nnot "
	unless $rv == $num[$i +2];
  &ok;
  $result = ipv6_n2x($result);
  print "got: $result\nexp: $num[$i +3]\nnot "
	unless $result eq $num[$i +3];
  &ok;
}

## test 44 - 57	the subtraction of the comp of the 'plus' category
##		should invert the carry and add 1 to 'exp'
##		start test at first 'number' that starts with '::FFFF'
for (my $i=0; $i<@num; $i+=4) {
  next unless $num[$i] =~ /^::FFFF/;
  my $num = ipv6_aton($num[$i]);
  my $plus = ipv6_aton($num[$i +1]);
  my $minus = comp128($plus);
  my($rv,$result) = sub128($num,$minus);
  print "got: $rv, exp: $num[$i +2]\nnot "
	unless $rv == $num[$i +2];
  &ok;
  $num[$i +3] =~ s/FFFE$/FFFF/;
  $result = ipv6_n2x($result);
  print "got: $result\nexp: $num[$i +3]\nnot "
	unless $result eq $num[$i +3];
  &ok;
}
