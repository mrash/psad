
#use diagnostics;
use NetAddr::IP::Lite;

$| = 1;

print "1..4\n";

my $test = 1;
sub ok() {
  print 'ok ',$test++,"\n";
}

my $loip	= new NetAddr::IP::Lite('::1.2.3.4/120');		# same as 1.2.3.4/24
my $hiip	= new NetAddr::IP::Lite('FF00::1:4/120');
my $dqip	= new NetAddr::IP::Lite('1.2.3.4/24');

## test '""' just for the heck of it
my $exp = 'FF00:0:0:0:0:0:1:4/120';
my $txt = sprintf("%s",$hiip);
print 'got: ',$txt," exp: $exp\nnot "
	unless $txt eq $exp;
&ok;

## test	lo ip
$exp = 'FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FF00';
my $mask = $loip->mask;
print "got: $mask, exp: $exp\nnot "
	unless $mask eq $exp && ! ref $mask;
&ok;

## test mask hi
$exp = 'FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FF00';
$mask = $hiip->mask;
print "got: $mask, exp: $exp\nnot "
	unless $mask eq $exp && ! ref $mask;
&ok;

## test mask dot quad
$exp = '255.255.255.0';
$mask = $dqip->mask;
print "got: $mask, exp: $exp\nnot "
        unless $mask eq $exp && ! ref $mask;
&ok;
