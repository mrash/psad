# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..13\n"; }
END {print "not ok 1\n" unless $loaded;}

use NetAddr::IP::InetBase qw(
	packzeros
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

my @addr = qw	# input					expected
(  D0:00:0000:0000:000:b00:0000:000		d0::b00:0:0
   0d0:00:0000:0000:000:0b00::			d0::b00:0:0
   ::c3D4:E5d6:0:0:0:0				0:0:c3d4:e5d6::
   0:0000:c3D4:e5d6:0:0:0:0			0:0:c3d4:e5d6::
   0:0:0:0:0:0:0:0				::
   0:0::					::
   ::0:000:0					::
   0:0::1.2.3.4					::1.2.3.4
   ::1.2.3.4					::1.2.3.4
   ::01b2:c3D4:0:0:0:1.2.3.4			0:1b2:c3d4::1.2.3.4
   0:0:0:0:a1B2:c3d4::				::a1b2:c3d4:0:0
   12:0:0:0:34:0:00:000				12::34:0:0:0
);

for(my $i=0;$i<@addr;$i+=2) {
  my $addr = $addr[$i];
  my $rv = packzeros($addr);
  my $exp = $addr[$i +1];
  print "got: $rv\nexp: $exp\nnot "
	 unless $rv eq $exp;
  &ok;
}
