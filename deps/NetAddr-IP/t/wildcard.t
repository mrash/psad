use NetAddr::IP;

my @addr = (
	[ 'localhost', '0.0.0.0' ],
	[ '10.0.0.0/24', '0.0.0.255' ],
	[ '192.168.0.0/16', '0.0.255.255' ],
	[ '10.128.0.1/17', '0.0.127.255' ]
);

$| = 1;

print "1..", 2 * scalar @addr, "\n";

my $count = 1;

for my $a (@addr) {
    my $ip = new NetAddr::IP $a->[0];

    if ($ip->wildcard eq $a->[1]) {
	print "ok $count\n";
    }
    else {
	print "not ok $count\n";
    }

    ++$count;


    if (($ip->wildcard)[1] eq $a->[1]) {
	print "ok $count\n";
    }
    else {
	print "not ok $count\n";
    }

    ++$count;
}
