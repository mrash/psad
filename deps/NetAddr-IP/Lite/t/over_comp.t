
#use diagnostics;
use NetAddr::IP::Lite;

$| = 1;

print "1..21\n";

my $test = 1;
sub ok() {
  print 'ok ',$test++,"\n";
}

my $four = new NetAddr::IP::Lite('::4');
$four->{val} = 4;
my $five = new NetAddr::IP::Lite('::5');
$five->{val} = 5;
my @t = (
# 	arg1	arg2	<	<=	==	>=	>	<=>	cmp
	$four,	$four,	0,	1,	1,	1,	0,	 0,	 0,
	$four,	$five,	1,	1,	0,	0,	0,	-1,	-1,
	$five,	$four,	0,	0,	0,	1,	1,	 1,	 1,
);

for (my $i = 0; $i< @t; $i+=9) {
## test '=' overloaded here
  my $arg1 = $t[$i];
  my $arg2 = $t[$i+1];
  my ($lt,$le,$eq,$ge,$gt,$nc,$cmp) = @t[$i+2,$i+3,$i+4,$i+5,$i+6,$i+7,$i+8];

## test '<'
  print "failed $arg1->{val} < $arg2->{val}, got: $_, exp: $lt\nnot "
	unless ($_ = ($arg1 < $arg2)) == $lt;
  &ok;

## test '<='
  print "failed $arg1->{val} <= $arg2->{val}, got: $_, exp: $le\nnot "
	unless ($_ = ($arg1 <= $arg2)) == $le;
  &ok;

## test '=='
  print "failed $arg1->{val} == $arg2->{val}, got: $_, exp: $eq\nnot "
	unless ($_ = ($arg1 == $arg2)) == $eq;
  &ok;

## test '>='
  print "failed $arg1->{val} >= $arg2->{val}, got: $_, exp: $ge\nnot "
	unless ($_ = ($arg1 >= $arg2)) == $ge;
  &ok;

## test '>'
  print "failed $arg1->{val} > $arg2->{val}, got: $_, exp: $gt\nnot "
	unless ($_ = ($arg1 > $arg2)) == $gt;
  &ok;

## test '<=>'
  print "failed $arg1->{val} <=> $arg2->{val}, got: $_, exp: $nc\nnot "
	unless ($_ = ($arg1 <=> $arg2)) == $nc;
  &ok;

## test 'cmp'
  print "failed $arg1->{val} cmp $arg2->{val}, got: $_, exp: $cmp\nnot "
	unless ($_ = ($arg1 cmp $arg2)) == $cmp;
  &ok;
}

