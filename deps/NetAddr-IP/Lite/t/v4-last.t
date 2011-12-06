use NetAddr::IP::Lite;

my %w = ('default'	=> [ '255.255.255.254', '0.0.0.0' ],
	 'loopback'	=> [ '127.255.255.254', '255.0.0.0' ],
	 '127.0.0.1/8'	=> [ '127.255.255.254', '255.0.0.0' ],
	 '10.'		=> [ '10.255.255.254', '255.0.0.0' ],
	 '10.10.10/24'	=> [ '10.10.10.254', '255.255.255.0' ],
	 );

$| = 1;

print '1..', (2 * scalar keys %w), "\n";

my $count = 1;

for my $a (keys %w) {
    my $ip = NetAddr::IP::Lite->new($a)->last;

    if ($ip->addr eq $w{$a}->[0]) {
	print "ok ", $count++, "\n";
    }
    else {
	print "not ok ", $count++, "\n";
    }

    if ($ip->mask eq $w{$a}->[1]) {
	print "ok ", $count++, "\n";
    }
    else {
	print "not ok ", $count++, "\n";
    }
}
