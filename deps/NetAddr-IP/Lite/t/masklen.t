
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

## test	masklen lo
$exp = 120;
my $masklen = $loip->masklen;
print "got: $masklen, exp: $exp\nnot "
	unless $masklen == $exp;
&ok;

## test masklen hi
$exp = 120;
$masklen = $hiip->masklen;
print "got: $masklen, exp: $exp\nnot "
	unless $masklen == $exp;
&ok;

## test masklen dq
$exp = 24;
$masklen = $dqip->masklen;
print "got: $masklen, exp: $exp\nnot "
	unless $masklen == $exp;
&ok;
