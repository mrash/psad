# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}

use NetAddr::IP::InetBase qw(
	:upper
	ipv6_aton
	inet_any2n
	inet_n2dx
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

my @num = qw	# input					expected
(   a1b2:c3d4:e5d6:f7e8:08f9:190a:2a1b:3b4c	A1B2:C3D4:E5D6:F7E8:8F9:190A:2A1B:3B4C
    		1.2.3.4					1.2.3.4
    A1B2:C3D4:E5D6:F7E8:08F9:190A:1.2.3.4	A1B2:C3D4:E5D6:F7E8:8F9:190A:102:304
		::1.2.3.4				1.2.3.4
	::FFFF:1.2.3.4				1.2.3.4
);

my $ff = ipv6_aton($num[1]);
for(my $i=0;$i<@num;$i+=2) {
  my $num = $num[$i];
  my $bstr = inet_any2n($num);
  my $rv = inet_n2dx($bstr);
  my $exp = $num[$i +1];
  print "got: $rv\nexp: $exp\nnot "
	 unless $rv eq $exp;
  &ok;
}
