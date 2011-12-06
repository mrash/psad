
use Test::More tests => 28;

use_ok('NetAddr::IP');

my $ip = new NetAddr::IP('192.168.21.13/15');
my $rv;
ok(($rv = sprintf("%s",$ip)) eq '192.168.21.13/15',"$rv eq 192.168.21.13/15");

my($plan,$masks) = $ip->_splitplan(15);
ok($plan,'there is a plan');
ok(!$masks,'plan returns the orignal net');
ok(@$plan == 1,'one item plan');
ok(($rv = $plan->[0]) == 15,"plan $rv is original cidr 15");

my $cmask = new NetAddr::IP('255.126.0.0');
ok(($rv = sprintf("%s",$cmask)) eq '255.126.0.0/32',"$rv eq 255.126.0.0/32");

($plan,$masks) = $ip->_splitplan($cmask);
ok(!$plan,'failing because of bits in mask');

$cmask = new NetAddr::IP('255.254.0.0');
ok(($rv = sprintf("%s",$cmask)) eq '255.254.0.0/32',"$rv eq 255.254.0.0/32");

($plan,$masks) = $ip->_splitplan($cmask);
ok($plan,'there is a plan');

ok(!$masks,'plan returns the orignal net');
ok(@$plan == 1,'one item plan');
ok(($rv = $plan->[0]) == 15,"plan $rv is original cidr 15");

$cmask = '255.254.0.0';			# ipV4 text cmask
($plan,$masks) = $ip->_splitplan($cmask);
ok($plan,'there is a plan');
ok(!$masks,'plan returns the orignal net');
ok(@$plan == 1,'one item plan');
ok(($rv = $plan->[0]) == 15,"plan $rv is original cidr 15");

$cmask = '255.126.0.0';                    # ipV4 text cmask
($plan,$masks) = $ip->_splitplan($cmask);
ok(!$plan,'failing because of bits in mask');

$cmask = 'garbage';
($plan,$masks) = $ip->_splitplan($cmask);
ok(!$plan,'failing because of garbage');

$cmask = 14;	# cidr is bigger than requested
($plan,$masks) = $ip->_splitplan($cmask);
ok(!$plan,'failing because of 15 overange');

# cidr makes more nets than 2**16
($plan,$masks) = $ip->_splitplan(32);
ok(!$plan,'failing to many nets 32 - 15 = 2**17');

($plan,$masks) = $ip->_splitplan(16,16,16);
ok(!$plan,'failing because of 3 * 16 overange');

# test for plan that just fits
($plan,$masks) = $ip->_splitplan(31);
ok($plan,'there is a plan 31');
ok($masks,'plan has masks');
ok(($rv = @{$plan}) == 2 ** 16,"$rv should = 65536");

# set netlimit internal to 4 nets
$NetAddr::IP::_netlimit = 4;
($plan,$masks) = $ip->_splitplan(17);	# should fit
ok($plan,"plan of 4 17's");

($plan,$masks) = $ip->_splitplan(17,17,17,17,18);
ok(!plan,"fail plan of 4 17's + 18");

($plan,$masks) = $ip->_splitplan(18);
ok(!plan,"fail plan of 8 18's");
