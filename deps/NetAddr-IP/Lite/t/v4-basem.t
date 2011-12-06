use NetAddr::IP::Lite;

my $nets = {
    '10.0.0.16'		=> [ 24, '10.0.0.255', '10.0.0.0' ],
    '127.0.0.1'		=> [ 8, '127.255.255.255', '127.0.0.0' ],
    '192.168.0.10'	=> [ 17, '192.168.127.255', '192.168.0.0' ],
};

$| = 1;
print "1..", (2 * scalar keys %$nets), "\n";

my $count = 1;

for my $a (keys %$nets) {
    my $ip = new NetAddr::IP::Lite $a, $nets->{$a}->[0];
    print '', (($ip->broadcast->addr	ne $nets->{$a}->[1] ?
	    'not ' : ''),
	   "ok ", $count++, "\n");
    print '', (($ip->network->addr		ne $nets->{$a}->[2] ?
	    'not ' : ''),
	   "ok ", $count++, "\n");
}


