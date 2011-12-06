
#use diagnostics;
use NetAddr::IP::Lite qw(:old_nth);

$| = 1;

sub ok() {
  print 'ok ',$test++,"\n";
}

my @try = qw(
	10/32		0
	10/31		1
	10/30		3
	::1/128		0
	::1/127		1
	::1/126		3
	1.2.3.11/29	7
	FF::8B/125	7
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
