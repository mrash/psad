
#use diagnostics;
use NetAddr::IP::Lite 0.10;
*Ones = \&NetAddr::IP::Lite::Ones;
use NetAddr::IP::Util qw(
	ipv6_aton
	shiftleft
);
$| = 1;

print "1..4\n";

my $test = 1;
sub ok() {
  print 'ok ',$test++,"\n";
}

my $ip24 = '1.2.3.4/24';
my $o = new NetAddr::IP::Lite($ip24);
my $c = $o->copy;

## test 1	validate original
my $txto = sprintf("%s",$o);
my $txtc = sprintf("%s",$c);
print "orig... got: $txto, exp: $ip24\nnot "
	unless $txto eq $ip24;
&ok;

## test 2
print "copy... got: $txtc, exp: $ip24\nnot "
	unless $txtc eq $ip24;
&ok;

my $ip28 = '1.2.3.4/28';
my $mask = shiftleft(Ones(),32 - 28);

$c->{mask} = $mask;
$txto = sprintf("%s",$o);
$txtc = sprintf("%s",$c);

## test 3	validate original
$txto = sprintf("%s",$o);
$txtc = sprintf("%s",$c);
print "orig... got: $txto, exp: $ip24\nnot "
	unless $txto eq $ip24;
&ok;

## test 4
print "copy... got: $txtc, exp: $ip28\nnot "
	unless $txtc eq $ip28;
&ok;

