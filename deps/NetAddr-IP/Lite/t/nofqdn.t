

use NetAddr::IP::Lite

$| = 1;

print "1..2\n";

my $test = 1;
sub ok() {
  print 'ok ',$test++,"\n";
}


my $ip = new NetAddr::IP::Lite('arin.net');
if (defined $ip) {
  print "ok $test	# Skipped, resolved $ip\n";
  $test++;
} else {
  print "ok $test	# Skipped, resolver not working\n";
  $test++;
}

import NetAddr::IP::Lite qw(:nofqdn);

$ip = new NetAddr::IP::Lite('arin.net');
print "unexpected response with :nofqdn\nnot "
	if defined $ip;
&ok;
