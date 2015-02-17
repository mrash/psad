
BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}

$loaded = 1;
print "ok 1\n";

#use diagnostics;
use NetAddr::IP::Lite;

$| = 1;

my $test = 2;

sub ok() {
  print 'ok ',$test++,"\n";
}

my $ud = undef;
my @bugtest = (
	0	=> '0.0.0.0/32', '0:0:0:0:0:0:0:0/128',
	$ud	=> '0.0.0.0/0', '0:0:0:0:0:0:0:0/0',
	""	=> 'undef', 'undef',
);
  

for (my $i=0;$i <= $#bugtest;$i+=3) {
  my $ip6 = sprintf("%s", NetAddr::IP::Lite->new6($bugtest[$i]) || 'undef');
  my $ip = sprintf ("%s", NetAddr::IP::Lite->new($bugtest[$i]) || 'undef');
  my $expip = $bugtest[$i+1];
  my $expip6 = $bugtest[$i+2];

  print "got: $ip\nexp: $expip\nnot "
	unless $ip eq $expip;
  &ok;

  print "got: $ip6\nexp: $expip6\nnot "
	unless $ip6 eq $expip6;
  &ok;

}
