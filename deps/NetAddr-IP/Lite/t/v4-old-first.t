use NetAddr::IP::Lite qw(:old_nth);

my $nets = {
    '10.0.0.16'		=> [ 24, '10.0.0.1', '10.0.0.254', '10.0.0.10'],
    '10.0.0.5'		=> [ 30, '10.0.0.5', '10.0.0.6', 'undef' ],
    '10.128.0.1'	=> [ 8, '10.0.0.1', '10.255.255.254', '10.0.0.10'],
    '10.128.0.1'	=> [ 24, '10.128.0.1', '10.128.0.254', '10.128.0.10'],
};

$| = 1;
print "1..", (3 * scalar keys %$nets), "\n";

my $count = 1;

for my $a (keys %$nets) {
    my $ip = new NetAddr::IP::Lite $a, $nets->{$a}->[0];
    print '', (($ip->first->addr	ne $nets->{$a}->[1] ?
	    'not ' : ''),
	   "ok ", $count++, "\n");
    print '', (($ip->last->addr		ne $nets->{$a}->[2] ?
	    'not ' : ''),
	   "ok ", $count++, "\n");

    my $new = $ip->nth(10);
    print '', (((defined $new ? $new->addr : 'undef') ne $nets->{$a}->[3] ?
	    'not ' : ''),
	   "ok ", $count++, "\n");
}


