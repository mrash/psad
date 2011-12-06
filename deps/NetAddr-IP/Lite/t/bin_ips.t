
#use diagnostics;
use NetAddr::IP::Lite;

$| = 1;

sub ok() {
  print 'ok ',$test++,"\n";
}

print "1..10\n";

$test = 1;

############## test new6

my $exp = '0:0:0:0:0:0:0:3039/1';

my $ip = NetAddr::IP::Lite->new6(12345,1);
my $got = $ip->cidr();
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

$ip = NetAddr::IP::Lite->new6('12345',1);
$got = $ip->cidr();
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

$ip = NetAddr::IP::Lite->new6('12345/1');
$got = $ip->cidr();
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;


# 2^127	170141183460469231731687303715884105728

$exp = '8000:0:0:0:0:0:0:0/1';

$ip = NetAddr::IP::Lite->new6('170141183460469231731687303715884105728/1');
$got = $ip->cidr();
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# 2^128	340282366920938463463374607431768211456
# minus one

$exp = 'FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF/1';

$ip = NetAddr::IP::Lite->new6('340282366920938463463374607431768211455/1');
$got = $ip->cidr();
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

############# test new

$exp = '0.0.48.57/1';

$ip = NetAddr::IP::Lite->new(12345,1);
$got = $ip->cidr();
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

$ip = NetAddr::IP::Lite->new('12345',1);
$got = $ip->cidr();
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

$ip = NetAddr::IP::Lite->new('12345/1');
$got = $ip->cidr();
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;


# 2^127	170141183460469231731687303715884105728

$exp = '8000:0:0:0:0:0:0:0/1';

$ip = NetAddr::IP::Lite->new('170141183460469231731687303715884105728/1');
$got = $ip->cidr();
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# 2^128	340282366920938463463374607431768211456
# minus one

$exp = 'FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF/1';

$ip = NetAddr::IP::Lite->new('340282366920938463463374607431768211455/1');
$got = $ip->cidr();
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

