
#use diagnostics;
use NetAddr::IP::Util qw(
	inet_ntoa
	ipv6_n2x
);
use NetAddr::IP::Lite;

$| = 1;

print "1..2\n";

my $test = 1;
sub ok() {
  print 'ok ',$test++,"\n";
}

my $loip	= new NetAddr::IP::Lite('1.2.3.4/24');
my $hiip	= new NetAddr::IP::Lite('FF00::4/120');

## test range

my $exp = 'FF00:0:0:0:0:0:0:0 - FF00:0:0:0:0:0:0:FF';
my $txt = $hiip->range;
print "got: $txt, exp: $exp\nnot "
	unless $txt eq $exp;
&ok;

$exp = '1.2.3.0 - 1.2.3.255';
$txt = $loip->range;
print "got: $txt, exp: $exp\nnot "
	unless $txt eq $exp;
&ok;

