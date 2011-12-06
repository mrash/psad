
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

## test '""' just for the heck of it
my $exp = 'FF00:0:0:0:0:0:1:4/120';
my $txt = sprintf("%s",$hiip);
print 'got: ',$txt," exp: $exp\nnot "
	unless $txt eq $exp;
&ok;

## test	addr lo
$exp = '0:0:0:0:0:0:102:304';
my $addr = $loip->addr;
print "got: $addr, exp: $exp\nnot "
	unless $addr eq $exp && ! ref $addr;
&ok;

## test addr hi
$exp = 'FF00:0:0:0:0:0:1:4';
$addr = $hiip->addr;
print "got: $addr, exp: $exp\nnot "
	unless $addr eq $exp && ! ref $addr;
&ok;
