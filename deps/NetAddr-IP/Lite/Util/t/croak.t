# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..31\n"; }
END {print "not ok 1\n" unless $loaded;}

use NetAddr::IP::Util qw(
	bcd2bin
	bin2bcd
	hasbits
	isIPv4
	add128
	sub128
	shiftleft
	comp128
	bcdn2txt
	bin2bcdn
	bcdn2bin
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

## tests 2 - 9	simple_pack

foreach(
	'1234/',
	'1234:',
	'a1234',
	'&1234',
) {
  my $rv;
  eval {	$rv = simple_pack($_) };
  if (defined $rv) {
    $rv = unpack("H40",$rv);
    print "got: $rv, exp: 'die'\nnot ";
  }
  &ok;

  print "expected a die from bad character input\nnot "
	unless $@ && $@ =~ /Bad/;
  &ok;
}

## tests 10 - 17	bcd2bin

foreach(
	'1234/',
	'1234:',
	'a1234',
	'&1234',
) {
  my $rv;
  eval {	$rv = bcd2bin($_) };
  if (defined $rv) {
    $rv = unpack("H40",$rv);
    print "got: $rv, exp: 'die'\nnot ";
  }
  &ok;

  print "expected a die from bad character input\nnot "
	unless $@ && $@ =~ /Bad/;
  &ok;
}

## test 18	bcdn2bin
eval { bcdn2bin('123456789012345678901') };
print "expected a die from bad vector string length\nnot "
	unless $@ && $@ =~ /Bad/;
&ok;

## test 19	bcdn2bin
eval { bcdn2bin('12345678901234567890') };
print "expected a die from missing length specifier\nnot "
	unless $@ && $@ =~ /Bad/;
&ok;

## test 20	bin2bcd
eval { bin2bcd('123') };
print "expected a die from bad vector string length\nnot "
	unless $@ && $@ =~ /Bad/;
&ok;

## test 21	bin2bcdn
eval { bin2bcdn('123') };
print "expected a die from bad vector string length\nnot "
	unless $@ && $@ =~ /Bad/;
&ok;

## test 22	bcdn2txt
eval { bcdn2txt('123456789012345678901') };
print "expected a die from bad vector string length\nnot "
	unless $@ && $@ =~ /Bad/;
&ok;

## test 23	bcdn2txt
my $rv;
my $exp = '3132333435363738393031323334353637383930';
$rv = bcdn2txt('12345678901234567890');
print "got: $rv\nexp: $exp\nnot "
	unless $rv eq $exp;
&ok;

## test 24	hasbits
eval { hasbits('123') };
print "expected a die from bad vector string length\nnot "
	unless $@ && $@ =~ /Bad/;
&ok;

## test 25	isIPv4
eval { isIPv4('12345678901234567') };
print "expected a die from bad vector string length\nnot "
	unless $@ && $@ =~ /Bad/;
&ok;

## test 26	add128
eval { add128('123','1234567890123456') };
print "expected a die from bad vector string length\nnot "
	unless $@ && $@ =~ /Bad/;
&ok;

## test 27	sub128
eval { sub128('1234567890123456','12345678901234567') };
print "expected a die from bad vector string length\nnot "
	unless $@ && $@ =~ /Bad/;
&ok;

## test 28	comp128
eval { comp128('123') };
print "expected a die from bad vector string length\nnot "
	unless $@ && $@ =~ /Bad/;
&ok;

## test 29	shiftleft
eval { shiftleft	('12345678901234567') };
print "expected a die from bad vector string length\nnot "
	unless $@ && $@ =~ /Bad/;
&ok;

## test 30	shiftleft
eval { shiftleft	('1234567890123456',-1) };
print "expected a die from bad shift count specifier\nnot "
	unless $@ && $@ =~ /Bad/;
&ok;

## test 31	shiftleft
eval { shiftleft	('1234567890123456',129) };
print "expected a die from bad shift count specifier\nnot "
	unless $@ && $@ =~ /Bad/;
&ok;

