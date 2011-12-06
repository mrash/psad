
#use diagnostics;
use NetAddr::IP::Lite;

$| = 1;

print "1..3\n";

my $test = 1;
sub ok() {
  print 'ok ',$test++,"\n";
}

my $loip	= new NetAddr::IP::Lite('::1.2.3.4/120');		# same as 1.2.3.4/24
my $hiip	= new NetAddr::IP::Lite('FF00::1:4/120');
my $dqip	= new NetAddr::IP::Lite('1.2.3.4/24');

## test	bits lo
$exp = 128;
my $bits = $loip->bits;
print "got: $bits, exp: $exp\nnot "
	unless $bits == $exp;
&ok;

## test bits hi
$exp = 128;
$bits = $hiip->bits;
print "got: $bits, exp: $exp\nnot "
	unless $bits == $exp;
&ok;

## test dotquad bits
$exp = 32;
$bits = $dqip->bits;
print "got: $bits, exp: $exp\nnot "
        unless $bits == $exp;
&ok;
