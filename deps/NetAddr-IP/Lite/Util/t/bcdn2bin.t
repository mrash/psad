# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..25\n"; }
END {print "not ok 1\n" unless $loaded;}

use NetAddr::IP::Util qw(
	ipv6_n2x
	bcdn2bin
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

my @num = # input					    expected
qw(
	0						0:0:0:0:0:0:0:0
	2147483648					0:0:0:0:0:0:8000:0
	4294967296					0:0:0:0:0:1:0:0
	8589934592					0:0:0:0:0:2:0:0
	10000000000					0:0:0:0:0:2:540B:E400
	17179869184					0:0:0:0:0:4:0:0
	34359738368					0:0:0:0:0:8:0:0
	68719476736					0:0:0:0:0:10:0:0
	137438953472					0:0:0:0:0:20:0:0
	274877906944					0:0:0:0:0:40:0:0
	549755813888					0:0:0:0:0:80:0:0
	1099511627776					0:0:0:0:0:100:0:0
	2199023255552					0:0:0:0:0:200:0:0
	4398046511104					0:0:0:0:0:400:0:0
	8796093022208					0:0:0:0:0:800:0:0
	17592186044416					0:0:0:0:0:1000:0:0
	35184372088832					0:0:0:0:0:2000:0:0
	70368744177664					0:0:0:0:0:4000:0:0
	140737488355328					0:0:0:0:0:8000:0:0
	9223372036854775808				0:0:0:0:8000:0:0:0
	604462909807314587353088			0:0:0:8000:0:0:0:0
	39614081257132168796771975168			0:0:8000:0:0:0:0:0
	2596148429267413814265248164610048		0:8000:0:0:0:0:0:0
	170141183460469231731687303715884105728		8000:0:0:0:0:0:0:0
);

## tests 2 - 9	check pack correct

#use Devel::Peek 'Dump';

for (my $i=0;$i<@num;$i+=2) {
print $num[$i],"\n";
  my $pkd = pack("H*",$num[$i]);
  my $len = length($num[$i]);
#Dump($pkd);
  my $bits = bcdn2bin($pkd,$len);
  my $ip = ipv6_n2x($bits);
  print "got: $ip\nexp: $num[$i +1]\nnot "
	unless $ip eq $num[$i +1];
  &ok;
}
