use NetAddr::IP;

BEGIN {
@gt = (
       [ '255.255.255.255/32', '0.0.0.0/0' ],
       [ 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff', '::/0' ],
       [ '10.0.1.0/16', '10.0.0.1/24' ],
       [ '10.0.0.1/24', '10.0.0.0/24' ],
       [ 'deaf:beef::1/64', 'dead:beef::/64' ],
       );

@ngt = (
	[ '0.0.0.0/0', '255.255.255.255/32' ],
	[ '::/0', 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff' ],
	[ '10.0.0.0/24', '10.0.0.0/24' ],
	[ 'dead:beef::/60', 'dead:beef::/60' ],
	);

@cmp = (
	[ '0.0.0.0/0', '255.255.255.255/32', -1 ],
	[ '::/0', 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff', -1 ],
	[ '10.0.0.0/16', '10.0.0.0/8', 1 ],
	[ 'dead:beef::/60', 'dead:beef::/40', 1 ],
	[ '10.0.0.0/24', '10.0.0.0/8', 1 ],
	[ '255.255.255.255/32', '0.0.0.0/0', 1 ],
	[ 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff', '::/0', 1 ],
	[ '142.52.5.87', '142.52.2.88', 1 ],
	[ '10.0.0.0/24', '10.0.0.0/24', 0 ],
	[ 'default', 'default', 0 ],
	[ 'broadcast', 'broadcast', 0],
	[ 'loopback', 'loopback', 0],
	);

};

use Test::More tests => @gt + @ngt + (2 * @cmp);

for my $a (@gt) {
    $a_ip = new NetAddr::IP::Lite $a->[0];
    $b_ip = new NetAddr::IP::Lite $a->[1];

    ok($a_ip > $b_ip, "$a_ip > $b_ip");
}

for my $a (@ngt) {
    $a_ip = new NetAddr::IP::Lite $a->[0];
    $b_ip = new NetAddr::IP::Lite $a->[1];

    ok(!($a_ip > $b_ip), "$a_ip !> $b_ip");
}

for $a (@cmp) {
    $a_ip = new NetAddr::IP::Lite $a->[0];
    $b_ip = new NetAddr::IP::Lite $a->[1];

    is($a_ip <=> $b_ip, $a->[2], "$a_ip <=> $b_ip is $a->[2]");
    is($a_ip cmp $b_ip, $a->[2], "$a_ip cmp $b_ip is $a->[2]");
}

