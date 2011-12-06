# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..25\n"; }
END {print "not ok 1\n" unless $loaded;}

use NetAddr::IP::Util qw(
	ipv6_aton
	bin2bcd
	bin2bcdn
	bcdn2txt
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

# input: array ref, value ref, number ref
#
sub val {
  my $bcd = shift;
  my $rv = unpack("H*",$bcd);
  $rv =~ s/^0+(\d)/$1/g;
  return $rv;
}

sub numnum {
  my($ar,$i) = @_;
  return sprintf("%.0f",$ar->[$i +1]);
}

sub numstr {
  my($ar,$i) = @_;
  return $ar->[$i+1];
}

sub dotest {
  my($ar,$vr,$nr) = @_;
  for(my $i=0;$i<@$ar;$i+=2) {
    my $bstr = ipv6_aton($ar->[$i]);
    my $bcd = bin2bcdn($bstr);
    my $val = $vr->($bcd);
    my $exp = $nr->($ar,$i);
    print "\t\t$val\n";
    print "got: $val\nexp: $exp\nnot "
	unless $val eq $exp;
    &ok;
  }
}

# setup only, can't depend on float to do it right on all systems
#my @num1 =    # input			expected
#(
#	'::'			=>	0,
#	'::8000:0'		=>	2**(15+16),
#	'::8000:0:0'		=>	2**(15+(16*2)),
#	'::8000:0:0:0'		=>	2**(15+(16*3)),
#	'::8000:0:0:0:0'	=>	2**(15+(16*4)),
#	'::8000:0:0:0:0:0'	=>	2**(15+(16*5)),
#	'::8000:0:0:0:0:0:0'	=>	2**(15+(16*6)),
#	'8000:0:0:0:0:0:0:0'	=>	2**(15+(16*7)),
#);

my @num2 = qw(
	::				0
	::8000:0			2147483648
	::8000:0:0			140737488355328
	::8000:0:0:0			9223372036854775808
	::8000:0:0:0:0			604462909807314587353088
	::8000:0:0:0:0:0		39614081257132168796771975168
	::8000:0:0:0:0:0:0		2596148429267413814265248164610048
	8000:0:0:0:0:0:0:0		170141183460469231731687303715884105728
);

## tests 2 - 9		bin2bcdn numeric unpack
#dotest(\@num1,\&val,\&numnum);

## tests 10 - 17	bin2bcdn string unpack		TEST 2 - 9
dotest(\@num2,\&val,\&numstr);

## tests 18 - 25	bin2bcdn numeric bcdn2txt
#dotest(\@num1,\&bcdn2txt,\&numnum);

## tests 26 - 33	bin2bcdn string bcdn2txt	TEST 10 - 17
dotest(\@num2,\&bcdn2txt,\&numstr);

## tests 34 - 41	bin2bcd				TEST 18 - 25
for(my $i=0;$i<@num2;$i+=2) {
  my $bstr = ipv6_aton($num2[$i]);
  my $bcd = bin2bcd($bstr);
  my $exp = $num2[$i +1];
  print "\t\t$bcd\n";
  print "got: $bcd\nexp: $exp\nnot "
	unless $bcd eq $exp;
  &ok;
}
