use NetAddr::IP::Lite;

my $nets = {
    '10.0.0.0/20'	=> [ 167772160, 4294963200 ],
    '10.0.15.0/24'	=> [ 167776000, 4294967040 ],
    '192.168.0.0/24'	=> [ 3232235520, 4294967040],
    'broadcast'		=> [ 4294967295, 4294967295],
    'default'		=> [ 0, 0 ],
};

$| = 1;
print "1..", 4 * (scalar keys %$nets), "\n";

my $count = 1;

for my $a (keys %$nets) {
    my $ip = new NetAddr::IP::Lite $a;
    my ($addr, $mask) = $ip->numeric;

    my $nip = new NetAddr::IP::Lite $addr, $mask;

    print '', ($nip ? '' : 'not '), 'ok ', $count++, "\n";

    print '', ($nip and $nip->cidr eq $ip->cidr) ? '' : 'not ',
    'ok ', $count ++, "\n";

    print '', (($addr != $nets->{$a}->[0] ?  'not ' : ''),
	   "ok ", $count++, "\n");

    print '', (($mask != $nets->{$a}->[1] ?  'not ' : ''),
	   "ok ", $count++, "\n");


}


