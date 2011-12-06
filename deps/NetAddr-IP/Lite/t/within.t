
#use diagnostics;
use NetAddr::IP::Lite;

$| = 1;

print "1..12\n";

my $test = 1;
sub ok() {
  print 'ok ',$test++,"\n";
}

my $net4 = NetAddr::IP::Lite->new('1.2.3.5/30');
my $net6 = NetAddr::IP::Lite->new('FF::85/126');
my @try = qw(
	1.2.3.3		0
	1.2.3.4		1
	1.2.3.5		1
	1.2.3.6		1
	1.2.3.7		1
	1.2.3.8		0
	FF::83		0
	FF::84		1
	FF::85		1
	FF::86		1
	FF::87		1
	FF::88		0
);

for (my $i=0;$i<@try;$i+=2) {
  my $ip = NetAddr::IP::Lite->new($try[$i]);
  my $rv = ($try[$i] =~ /:/)
	? $ip->within($net6)
	: $ip->within($net4);
  print "got: $rv, exp: $try[$i+1]\nnot "
	unless $rv  == $try[$i+1];
  &ok;
}

