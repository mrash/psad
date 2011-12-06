
use Test::More tests => 28;

use_ok('NetAddr::IP');

my $ip = new NetAddr::IP('ffff:a123:b345:c789::/48');
my $rv;
ok(($rv = sprintf("%s",$ip)) eq 'FFFF:A123:B345:C789:0:0:0:0/48',"$rv eq FFFF:A123:B345:C789:0:0:0:0/48");

my($plan,$masks) = $ip->_splitplan(48);
ok($plan,'there is a plan');
ok(!$masks,'plan returns the orignal net');
ok(@$plan == 1,'one item plan');
ok(($rv = $plan->[0]) == 48,"plan $rv is original cidr 48");

my $cmask = new NetAddr::IP('ffff:7fff:ffff:ffff::');
ok(($rv = sprintf("%s",$cmask)) eq 'FFFF:7FFF:FFFF:FFFF:0:0:0:0/128',"$rv eq FFFF:7FFF:FFFF:FFFF:0:0:0:0/128");

($plan,$masks) = $ip->_splitplan($cmask);
ok(!$plan,'failing because of bits in mask');

$cmask = new NetAddr::IP('FFFF:fFFF:FFFF::');
ok(($rv = sprintf("%s",$cmask)) eq 'FFFF:FFFF:FFFF:0:0:0:0:0/128',"$rv eq FFFF:fFFF:FFFF:0:0:0:0:0/128");

($plan,$masks) = $ip->_splitplan($cmask);
ok($plan,'there is a plan');
ok(!$masks,'plan returns the orignal net');
ok(@$plan == 1,'one item plan');
ok(($rv = $plan->[0]) == 48,"plan $rv is original cidr 48");

$cmask = 'FFFF:FFFF:FFFF::';			# ipV6 text cmask
($plan,$masks) = $ip->_splitplan($cmask);
ok($plan,'there is a plan');
ok(!$masks,'plan returns the orignal net');
ok(@$plan == 1,'one item plan');
ok(($rv = $plan->[0]) == 48,"plan $rv is original cidr 48");

$cmask = 'FFFF:FFF:FFFF::';                    # ipV6 text cmask
($plan,$masks) = $ip->_splitplan($cmask);
ok(!$plan,'failing because of bits in mask');

$cmask = 'garbage';
($plan,$masks) = $ip->_splitplan($cmask);
ok(!$plan,'failing because of garbage');

$cmask = 47;	# cidr is bigger than requested
($plan,$masks) = $ip->_splitplan($cmask);
ok(!$plan,'failing because of 47 overange');

# cidr makes more nets than 2**16
($plan,$masks) = $ip->_splitplan(65);
ok(!$plan,'failing to many nets 65-48 = 2**17');

($plan,$masks) = $ip->_splitplan(49,49,49);
ok(!$plan,'failing because of 3 * 49 overange');

# test for plan that just fits
($plan,$masks) = $ip->_splitplan(64);
ok($plan,'there is a plan 64');
ok($masks,'plan has masks');
ok(($rv = @{$plan}) == 2 ** 16,"$rv should = 65536");

# set netlimit internal to 4 nets
$NetAddr::IP::_netlimit = 4;
($plan,$masks) = $ip->_splitplan(50);	# should fit
ok($plan,"plan of 4 50's");

($plan,$masks) = $ip->_splitplan(50,50,50,50,51);
ok(!plan,"fail plan of 4 50's + 51");

($plan,$masks) = $ip->_splitplan(51);
ok(!plan,"fail plan of 8 51's");
