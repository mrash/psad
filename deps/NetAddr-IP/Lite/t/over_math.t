
#use diagnostics;
use NetAddr::IP::Lite;

$| = 1;

print "1..7\n";

my $test = 1;
sub ok() {
  print 'ok ',$test++,"\n";
}

my $ip	= new NetAddr::IP::Lite('0.0.0.4/24');

## test '+'
my $exp = '0.0.0.132/24';
my $nip = $ip + 128;
print 'got: ',$nip," exp: $exp\nnot "
	unless $nip eq $exp;
&ok;

## test '+' wrap around
$nip = $ip + 257;
$exp = '0.0.0.5/24';
print 'got: ',$nip," exp: $exp\nnot "
	unless $nip eq $exp;
&ok;

## test '-' and wrap
$nip = $ip - 10;
$exp = '0.0.0.250/24';
print 'got: ',$nip," exp: $exp\nnot "
	unless $nip eq $exp;
&ok;

## test '++' post
$nip++;
$exp = '0.0.0.251/24';
print 'got: ',$nip," exp: $exp\nnot "
	unless $nip eq $exp;
&ok;

## test '++' pre
++$nip;
$exp = '0.0.0.252/24';
print 'got: ',$nip," exp: $exp\nnot "
	unless $nip eq $exp;
&ok;

## test '--' post
$ip--;
$exp = '0.0.0.3/24';
print 'got: ',$ip," exp: $exp\nnot "
	unless $ip eq $exp;
&ok;

## test '--' pre
--$ip;
$exp = '0.0.0.2/24';
print 'got: ',$ip," exp: $exp\nnot "
	unless $ip eq $exp;
&ok;

