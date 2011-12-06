
#use diagnostics;
use NetAddr::IP::Lite 0.10;
*Ones = \&NetAddr::IP::Lite::Ones;
use NetAddr::IP::Util qw(
	ipv6_aton
	shiftleft
);
$| = 1;

print "1..8\n";

my $test = 1;
sub ok() {
  print 'ok ',$test++,"\n";
}

my $ip24 = '1.2.3.4/24';
my $o = new NetAddr::IP::Lite($ip24);
my $c = $o;

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

## overload does not unlink originals in this case
## test 3	validate original
$txto = sprintf("%s",$o);
$txtc = sprintf("%s",$c);
print "orig... got: $txto, exp: $ip28\nnot "
	unless $txto eq $ip28;
&ok;

## test 4
print "copy... got: $txtc, exp: $ip28\nnot "
	unless $txtc eq $ip28;
&ok;

my $ip265 = '1.2.3.5/26';
my $ip285 = '1.2.3.5/28';
$mask = shiftleft(Ones(),32 - 26);

## test 5	overload seperates variables
$c++;
##		validate original
$txto = sprintf("%s",$o);
$txtc = sprintf("%s",$c);
print "orig... got: $txto, exp: $ip28\nnot "
	unless $txto eq $ip28;
&ok;

## test 6	check mutated copy
print "copy... got: $txtc, exp: $ip285\nnot "
	unless $txtc eq $ip285;
&ok;

## test 7	check seperation
$c->{mask} = $mask;
##		validate original
$txto = sprintf("%s",$o);
$txtc = sprintf("%s",$c);
print "orig... got: $txto, exp: $ip28\nnot "
	unless $txto eq $ip28;
&ok;

## test 8	check mutated copy
print "copy... got: $txtc, exp: $ip265\nnot "
	unless $txtc eq $ip265;
&ok;

