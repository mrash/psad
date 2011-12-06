# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}

use NetAddr::IP::Util qw(
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

my @num = qw	# input					expected
(  		   ::				FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF
    FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF	0:0:0:0:0:0:0:0
    A1B2:C3D4:E5D6:F7E8:08F9:190A:2A1B:3B4C	5E4D:3C2B:1A29:817:F706:E6F5:D5E4:C4B3
);

my $ff = ipv6_aton($num[1]);
for(my $i=0;$i<@num;$i+=2) {
  my $num = $num[$i];
  my $bstr = ipv6_aton($num);
  my $cnum = comp128($bstr);
  my $rv = ipv6_n2x($cnum);
  my $exp = $num[$i +1];
  print "got: $rv\nexp: $exp\nnot "
	 unless $rv eq $exp;
  &ok;
}
