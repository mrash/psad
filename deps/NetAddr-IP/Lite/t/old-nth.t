
#use diagnostics;
use NetAddr::IP::Lite qw(:old_nth);

$| = 1;

print "1..9\n";

my $test = 1;
sub ok() {
  print 'ok ',$test++,"\n";
}

my $ip4 = NetAddr::IP::Lite->new('1.2.3.11/29');

my @try = qw(
	0	undef
	1	1.2.3.9
	2	1.2.3.10
	3	1.2.3.11
	4	1.2.3.12
	5	1.2.3.13
	6	1.2.3.14
	7	1.2.3.15
	8	undef
);

for (my $i=0;$i<@try;$i+=2) {
  my $rv = $ip4->nth($try[$i]);
  $rv = defined $rv
	? $rv->addr
	: 'undef';
  print "got: $rv, exp: $try[$i+1]\nnot "
	unless $rv eq $try[$i+1];
  &ok;
}
