
use Test::More qw(no_plan); #tests => 28;

use_ok('NetAddr::IP');

my $ip = new NetAddr::IP('ffff:a123:b345:c789::/48');
my $rv;
ok(($rv = sprintf("%s",$ip)) eq 'FFFF:A123:B345:C789:0:0:0:0/48',"$rv eq FFFF:A123:B345:C789:0:0:0:0/48");
my $nets = $ip->splitref(48);
ok($nets,'there is a net');
ok(@$nets == 1,'one item net');
ok(($rv = sprintf("%s",$ip)) eq 'FFFF:A123:B345:C789:0:0:0:0/48',"$rv eq FFFF:A123:B345:C789:0:0:0:0/48");

$nets = $ip->splitref(49,50);
ok($nets,'there are nets');
ok(($rv = @$nets) == 3,"$rv is 3 item net");

my @exp = qw(
	FFFF:A123:B345:0:0:0:0:0/49
	FFFF:A123:B345:8000:0:0:0:0/50
	FFFF:A123:B345:C000:0:0:0:0/50
);

foreach(0..$#{$nets}) {
  ok(($rv = sprintf("%s",$nets->[$_])) eq $exp[$_], "$rv eq $exp[$_]");
}

