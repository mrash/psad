
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

## test	network dq
$exp = '1.2.3.0/24';
my $net = $dqip->network;
print 'got: ',$net, " exp: $exp\nnot "
	unless $net eq $exp;
&ok;

## test network hi
$exp = 'FF00:0:0:0:0:0:1:0/120';
$net = $hiip->network;
print 'got: ',$net, " exp: $exp\nnot "
	unless $net eq $exp;
&ok;

## test network lo
$exp = '0:0:0:0:0:0:102:300/120';
$net = $loip->network;
print 'got: ',$net, " exp: $exp\nnot "
	unless $net eq $exp;
&ok;
