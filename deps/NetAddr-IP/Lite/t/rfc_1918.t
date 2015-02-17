
#use diagnostics;
use NetAddr::IP::Lite;

$| = 1;

print "1..12\n";

my $test = 1;
sub ok() {
  print 'ok ',$test++,"\n";
}

my @ips = qw(
        9.255.255.255		0
        10.0.0.0		1
        10.255.255.255		1
        11.0.0.0		0
        172.15.255.255		0
        172.16.0.0		1
        172.31.255.255		1
        172.32.0.0		0
        192.167.255.255		0
        192.168.0.0		1
        192.168.255.255		1
        192.169.0.0		0
);


for (my $i=0;$i<=$#ips;$i+=2) {
  my $ip = new NetAddr::IP::Lite($ips[$i]);
  my $got = $ip->is_rfc1918();
  my $exp = $ips[$i+1];
  print $ip," got: $got, exp: $exp\nnot "
	unless $got == $exp;
  &ok;
}

