# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..20\n"; }
END {print "not ok 1\n" unless $loaded;}

use NetAddr::IP::Util qw(
	ipv6_aton
	ipv6_n2x
	inet_any2n
	addconst
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

my @num = qw	# input				    expected
(
		::				0:0:0:0:0:0:0:0
   		::				0:0:0:0:0:0:0:2
  		::FFFF				0:0:0:0:0:0:1:3
		::FFFF:FFFF			0:0:0:0:0:1:0:5
		::FFFF:FFFF:FFFF		0:0:0:0:1:0:0:7
		::FFFF:FFFF:FFFF:ffff		0:0:0:1:0:0:0:9
		::FFFF:FFFF:FFFF:ffff:ffff	0:0:1:0:0:0:0:B
	::FFFF:FFFF:FFFF:ffff:ffff:ffff		0:1:0:0:0:0:0:D
  0:FFFF:FFFF:FFFF:ffff:ffff:ffff:ffff		1:0:0:0:0:0:0:F
  FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF	0:0:0:0:0:0:0:11
);

for (my $i=0; $i <@num; $i+=2) {
  my $bnum = ipv6_aton($num[$i]);
  my($carry,$rv) = addconst($bnum,$i);
  $rv = ipv6_n2x($rv);
  print "got: $rv\nexp: $num[$i +1]\nnot "
    unless $rv eq $num[$i +1];
  &ok;
}

@num = qw	# input				    expected
(
 FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF	FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF
		::				FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE
		FFFF::				FFFE:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFC
		FFFF:FFFF::			FFFF:FFFE:FFFF:FFFF:FFFF:FFFF:FFFF:FFFA
		FFFF:FFFF:FFFF::		FFFF:FFFF:FFFE:FFFF:FFFF:FFFF:FFFF:FFF8
		ffff:ffff:ffff:ffff::		FFFF:FFFF:FFFF:FFFE:FFFF:FFFF:FFFF:FFF6
		ffff:ffff:ffff:ffff:ffff::	FFFF:FFFF:FFFF:FFFF:FFFE:FFFF:FFFF:FFF4
	ffff:ffff:ffff:ffff:ffff:ffff::		FFFF:FFFF:FFFF:FFFF:FFFF:FFFE:FFFF:FFF2
	FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:0	FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE:FFF0
);

for (my $i=0; $i <@num; $i+=2) {
  my $bnum = ipv6_aton($num[$i]);
  my($carry,$rv) = addconst($bnum,-$i);
  $rv = ipv6_n2x($rv);
  print "got: $rv\nexp: $num[$i +1]\nnot "
    unless $rv eq $num[$i +1];
  &ok;
}

