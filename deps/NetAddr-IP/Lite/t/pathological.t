
#use diagnostics;
use NetAddr::IP::Lite;

END {print "1..1\nnot ok 1\n" unless $test};

$| = 1;

$test = 1;
sub ok() {
  print 'ok ',$test++,"\n";
}

my @addrs = 	# pathological cases should fail
qw(	::foo
	::f00/129
	::f00/150
);

print '1..',(scalar @addrs),"\n";

my $ip;
foreach(@addrs) {
  print "expected undef, got: $ip\nnot "
	if ($ip = new NetAddr::IP::Lite($_));
  &ok;
}
