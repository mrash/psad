# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}

use NetAddr::IP::Util qw(
	ipv6_aton
	ipv6_n2x
	shiftleft
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

my @num = # input	shift	expected
qw(
	1::1		 none	1:0:0:0:0:0:0:1
	1::1		  0	1:0:0:0:0:0:0:1
	1::1		  1	2:0:0:0:0:0:0:2
	1::1		  2	4:0:0:0:0:0:0:4
	1::1		  3	8:0:0:0:0:0:0:8
	1::1		  15	8000:0:0:0:0:0:0:8000
	1::1		  16	0:0:0:0:0:0:1:0
	1::1		  128	0:0:0:0:0:0:0:0
);

for (my $i=0;$i < @num;$i+=3) {
  my $bstr = ipv6_aton($num[$i]);
  my $rv;
  if ($num[$i +1] =~ /\D/) {
    $rv = shiftleft($bstr);
  }
  else {
    $rv = shiftleft($bstr,$num[$i +1]);
  }
  my $exp = $num[$i+2];
  my $got = ipv6_n2x($rv);
  print "got: $got, exp: $exp\nnot "
	 unless $got eq $exp;
  &ok;
}
