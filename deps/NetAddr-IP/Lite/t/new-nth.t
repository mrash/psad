
#use diagnostics;
use NetAddr::IP::Lite;

$| = 1;

sub ok() {
  print 'ok ',$test++,"\n";
}

my $ip4 = NetAddr::IP::Lite->new('1.2.3.11/29');

my @try = qw(
	0	1.2.3.9
	1	1.2.3.10
	2	1.2.3.11
	3	1.2.3.12
	4	1.2.3.13
	5	1.2.3.14
	6	undef
);

print '1..', (@try/2) +2, "\n";

$test = 1;

for (my $i=0;$i<@try;$i+=2) {
  my $rv = $ip4->nth($try[$i]);
  $rv = defined $rv
	? $rv->addr
	: 'undef';
  print "got: $rv, exp: $try[$i+1]\nnot "
	unless $rv eq $try[$i+1];
  &ok;
}

print "got: $_, exp: 1\nnot "
  unless ($_ = NetAddr::IP::Lite->new('1.2.3.4/32')->num()) && $_ == 1;
&ok;

print "got: $_, exp: 0\nnot "
  unless defined ($_ = NetAddr::IP::Lite->new('1.2.3.4/31')->num()) && $_ == 2;
&ok;

