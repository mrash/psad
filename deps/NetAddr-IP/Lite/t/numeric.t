
#use diagnostics;
use NetAddr::IP::Lite;

$| = 1;

print "1..6\n";

my $test = 1;
sub ok() {
  print 'ok ',$test++,"\n";
}

my @tval = qw #	IP				bcd				 mask bcd
(	8000:0:0:0:0:0:0:1/112	170141183460469231731687303715884105729	340282366920938463463374607431768145920
		1.2.3.4/24		     16909060				4294967040
);

for (my $i=0;$i < @tval;$i+=3) {
  my $nip = NetAddr::IP::Lite->new($tval[$i]);
## test scalar return
  my $sclr = $nip->numeric;
  print "got: $sclr\nexp: $tval[$i+1]\nnot "
	unless $sclr .'x' eq $tval[$i+1] .'x';
  &ok;

## test array return
  my($addr,$mask) = $nip->numeric;
  print "got: $addr\nexp: $tval[$i+1]\nnot "
	unless $addr .'x' eq $tval[$i+1] .'x';
  &ok;

  print "got: $mask\nexp: $tval[$i+2]\nnot "
	unless $mask .'x' eq $tval[$i+2] .'x';
  &ok;
}
