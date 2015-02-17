
#use diagnostics;
use NetAddr::IP::Lite;

$| = 1;

print "1..1\n";

my $test = 1;
sub ok() {
  print 'ok ',$test++,"\n";
}

my $ip = new6FFFF NetAddr::IP::Lite('127.0.0.1');
my $exp = '0:0:0:0:0:FFFF:7F00:1/128';
print "got: $ip\nexp: $exp\nnot "
	unless "$ip" eq $exp;
&ok;
