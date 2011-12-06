# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..49\n"; }
END {print "not ok 1\n" unless $loaded;}

use NetAddr::IP::Util qw(
	inet_any2n
	notcontiguous
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

my @num = #	input				    expected	spur
qw(
	FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF		128	0
	FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE		127	0
	FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFC		126	0
	FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFF8		125	0
	FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFF0		124	0
	FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFE0		123	0
	FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFC0		122	0
	FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FF80		121	0
	FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FF00		120	0
	FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:0		112	0
	FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFF0:0		108	0
	FFeF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF		128	1
	FFFF:FFeF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE		127	1
	FFFF:FFFF:FeFF:FFFF:FFFF:FFFF:FFFF:FFFC		126	1
	FFFF:FFFF:FFFF:eFFF:FFFF:FFFF:FFFF:FFF8		125	1
	FFFF:FFFF:FFFF:FFFF:FFFe:FFFF:FFFF:FFF0		124	1
	FFFF:FFFF:FFF:FFFF:FFFF:FFFF:FFFF:FFE0		123	1
	FFFF:FFFF:FFFF:FFFF:FFFF:FFeF:FFFF:FFC0		122	1
	FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FeFF:FF80		121	1
	FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:eF00		120	1
	eFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:0		112	1
	FFFF:FeFF:FFFF:FFFF:FFFF:FFFF:FFF0:0		108	1
	F000::						4	0
	A000::						3	1
);

for (my $i=0;$i < @num;$i+=3) {
  my $bstr = inet_any2n($num[$i]);
  my $rv;
  my $xcidr = $num[$i+1];
  my $xspur = $num[$i+2];
  my($spur,$cidr) = notcontiguous($bstr);
  print "cidr: $cidr, exp: $xcidr\nnot "
	 unless $cidr == $xcidr;
  &ok;
  $spur = 1 if $spur;
  print "spur: $spur, exp: $xspur\nnot "
	unless $spur == $xspur;
  &ok;
}
