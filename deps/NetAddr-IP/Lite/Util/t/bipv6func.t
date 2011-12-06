# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..27\n"; }
END {print "not ok 1\n" unless $loaded;}

use NetAddr::IP::InetBase qw(
	:upper
	ipv6_aton
	ipv6_n2x
	ipv6_n2d
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

my @num = #	in			    exphex			    expd
qw(
		::			0:0:0:0:0:0:0:0			0:0:0:0:0:0:0.0.0.0
		43::			43:0:0:0:0:0:0:0		43:0:0:0:0:0:0.0.0.0
		::21			0:0:0:0:0:0:0:21		0:0:0:0:0:0:0.0.0.33
	::1:2:3:4:5:6:7			0:1:2:3:4:5:6:7			0:1:2:3:4:5:0.6.0.7
	1:2:3:4:5:6:7::			1:2:3:4:5:6:7:0			1:2:3:4:5:6:0.7.0.0
		1::8			1:0:0:0:0:0:0:8			1:0:0:0:0:0:0.0.0.8
	FF00::FFFF			FF00:0:0:0:0:0:0:FFFF		FF00:0:0:0:0:0:0.0.255.255
	FFFF::FFFF:FFFF			FFFF:0:0:0:0:0:FFFF:FFFF	FFFF:0:0:0:0:0:255.255.255.255
);

for (my $i=0;$i<@num;$i+=3) {
  my $bits = ipv6_aton($num[$i]);
  my $len = length($bits);
  print "bad len = $len, exp: 16\nnot "
	unless $len == 16;		# 16 bytes x 8 bits
  &ok;
  my $ipv6x = ipv6_n2x($bits);
  print "got: $ipv6x\nexp: $num[$i +1]\nnot "
	unless $ipv6x eq $num[$i +1];
  &ok;
  my $ipv6d = ipv6_n2d($bits);
  print "got: $ipv6d\nexp: $num[$i +2]\nnot "
	unless $ipv6d eq $num[$i +2];
  &ok;
}

## test 26	check bad length n2x
my $try = '1234';
my $notempty = eval {
	ipv6_n2x($try);
};
print "failed bad argument length test for ipv6_n2x\nnot "
	unless $@ && $@ =~ /Bad arg/;
&ok;

## test 27	check bad length n2d
$notempty = eval {
	ipv6_n2d($try);
};
print "failed bad argument length test for ipv6_n2d\nnot "
	unless $@ && $@ =~ /Bad arg/;
&ok;
