
#use diagnostics;
use NetAddr::IP::Lite;

$| = 1;

print "1..3\n";

my $test = 1;
sub ok() {
  print 'ok ',$test++,"\n";
}

my $loip	= new NetAddr::IP::Lite('::1.2.3.4/120');		# same as 1.2.3.4/24
my $hiip	= new NetAddr::IP::Lite('FF00::4/120');

## test '""' just for the heck of it
my $exp = 'FF00:0:0:0:0:0:0:4/120';
my $txt = sprintf("%s",$hiip);
print 'got: ',$txt," exp: $exp\nnot "
	unless $txt eq $exp;
&ok;

## test	broadcast lo
$exp = '0:0:0:0:0:0:102:3FF/120';
my $broad = $loip->broadcast;
print 'got: ',$broad, " exp: $exp\nnot "
	unless $broad eq $exp;
&ok;

## test broadcast hi
$exp = 'FF00:0:0:0:0:0:0:FF/120';
$broad = $hiip->broadcast;
print 'got: ',$broad, " exp: $exp\nnot "
	unless $broad eq $exp;
&ok;

