# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..20\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use NetAddr::IP::InetBase qw(
	ipv6_ntoa
	inet_pton
	AF_INET6
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

## test 2 - 19	add stuff to buffer
my @num = #	in			    	exphex
qw(
		::				::
		43::				43::
		::21				::21
	::1:2:3:4:5:6:7				0:1:2:3:4:5:6:7
	1:2:3:4:5:6:7::				1:2:3:4:5:6:7:0
		1::8				1::8
	FF00::FFFF				ff00::ffff
	FFFF::FFFF:FFFF				ffff::ffff:ffff
	A1B2:C3D4:E5D6:F7E8:08F9:190A:1.2.3.4	a1b2:c3d4:e5d6:f7e8:8f9:190a:102:304
);

for (my $i=0;$i<@num;$i+=2) {
  my $bits = inet_pton(AF_INET6(),$num[$i]);
  my $len = length($bits);
  print "bad len = $len, exp: 16\nnot "
	unless $len == 16;		# 16 bytes x 8 bits
  &ok;
  my $ipv6x = ipv6_ntoa($bits);
  print "got: $ipv6x\nexp: $num[$i +1]\nnot "
	unless $ipv6x eq $num[$i +1];
  &ok;
}

## test 32	check bad length ntop
my $try = '1234';
my $notempty = eval {
	ipv6_ntoa($try);
};
print "failed bad argument length test for ipv6_ntoa\nnot "
	unless $@ && $@ =~ /Bad arg/;
&ok;
