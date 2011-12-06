
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
my $dqip	= new NetAddr::IP::Lite('1.2.3.4/24');

## test cidr

my $exp = 'FF00:0:0:0:0:0:0:4/120';
my $txt = $hiip->cidr;
print "got: $txt, exp: $exp\nnot "
	unless $txt eq $exp;
&ok;

$exp = '0:0:0:0:0:0:102:304/120';
$txt = $loip->cidr;
print "got: $txt, exp: $exp\nnot "
	unless $txt eq $exp;
&ok;

$exp = '1.2.3.4/24';
$txt = $dqip->cidr;
print "got: $txt, exp: $exp\nnot "
	unless $txt eq $exp;
&ok;
