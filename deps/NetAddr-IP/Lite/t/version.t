
#use diagnostics;
use NetAddr::IP::Lite;

$| = 1;

print "1..2\n";

my $test = 1;
sub ok() {
  print 'ok ',$test++,"\n";
}

my $loip	= new NetAddr::IP::Lite('1.2.3.4/24');
my $hiip	= new NetAddr::IP::Lite('FF00::1:4/120');

## test	version lo
$exp = 4;
my $version = $loip->version;
print "got: $version, exp: $exp\nnot "
	unless $version == $exp;
&ok;

## test version hi
$exp = 6;
$version = $hiip->version;
print "got: $version, exp: $exp\nnot "
	unless $version == $exp;
&ok;
