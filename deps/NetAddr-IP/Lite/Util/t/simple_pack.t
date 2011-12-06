# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}

use NetAddr::IP::Util qw(
	simple_pack
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

my @num2 = qw(
	0
	2147483648
	140737488355328
	9223372036854775808
	604462909807314587353088
	39614081257132168796771975168
	2596148429267413814265248164610048
	170141183460469231731687303715884105728
);

## tests 2 - 9	check pack correct

for (my $i=0;$i<@num2;$i++) {
  my $len = length($num2[$i]);
  my $pkd = simple_pack($num2[$i]);
  my $rv = unpack("H40",$pkd);
  $rv =~ s/^0+(\d)/$1/g;
  print "got: $rv\nexp: $num2[$i]\nnot "
	unless $rv eq $num2[$i];
  &ok;
}
