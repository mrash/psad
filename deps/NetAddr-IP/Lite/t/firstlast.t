
#use diagnostics;
use NetAddr::IP::Lite;

$| = 1;

print "1..8\n";

my $test = 1;
sub ok() {
  print 'ok ',$test++,"\n";
}

my $ip4 = NetAddr::IP::Lite->new('1.2.3.11/29');
my $ip6 = NetAddr::IP::Lite->new('FF::8B/125');

my $exp = '1.2.3.9';
my $rv = $ip4->first->addr;
print "got: $rv, exp: $exp\nnot "
	unless $rv eq $exp;
&ok;

$exp = '1.2.3.14';
$rv = $ip4->last->addr;
print "got: $rv, exp: $exp\nnot "
	unless $rv eq $exp;
&ok;

$exp = 'FF:0:0:0:0:0:0:89';
$rv = $ip6->first->addr;
print "got: $rv, exp: $exp\nnot "
	unless $rv eq $exp;
&ok;

$exp = 'FF:0:0:0:0:0:0:8E';
$rv = $ip6->last->addr;
print "got: $rv, exp: $exp\nnot "
	unless $rv eq $exp;
&ok;

$ip4 = NetAddr::IP::Lite->new('1.2.3.11/31');
$ip6 = NetAddr::IP::Lite->new('FF::8B/127');

$exp = '1.2.3.10';
$rv = $ip4->first->addr;
print "got: $rv, exp: $exp\nnot "
	unless $rv eq $exp;
&ok;

$exp = '1.2.3.11';
$rv = $ip4->last->addr;
print "got: $rv, exp: $exp\nnot "
	unless $rv eq $exp;
&ok;

$exp = 'FF:0:0:0:0:0:0:8A';
$rv = $ip6->first->addr;
print "got: $rv, exp: $exp\nnot "
	unless $rv eq $exp;
&ok;

$exp = 'FF:0:0:0:0:0:0:8B';
$rv = $ip6->last->addr;
print "got: $rv, exp: $exp\nnot "
	unless $rv eq $exp;
&ok;
