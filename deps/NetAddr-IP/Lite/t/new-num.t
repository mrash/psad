
#use diagnostics;
use NetAddr::IP::Lite;

$| = 1;

sub ok() {
  print 'ok ',$test++,"\n";
}

my @try = qw(
	10/32		1
	10/31		2
	10/30		2
	::1/128		1
	::1/127		2
	::1/126		2
	1.2.3.11/29	6
	FF::8B/125	6
);

print '1..',(@try/2),"\n";

$test = 1;

foreach(my $i = 0;$i <=$#try;$i+= 2) {
  my $ip = NetAddr::IP::Lite->new($try[$i]);
  my $exp = $try[$i +1];

  print "got: $_, exp: $exp\nnot "
	unless ($_ = $ip->num) == $exp;
  &ok;
}
