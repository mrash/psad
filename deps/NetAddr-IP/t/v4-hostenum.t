use NetAddr::IP;

# $Id: v4-hostenum.t,v 1.1.1.1 2006/08/14 15:36:06 lem Exp $

my %addr = (
	    '10.0.0.0' => [ '255.255.255.252',
			    [
			     '10.0.0.1', '10.0.0.2',
			     ]],
	    '11.0.0.0' => [ '255.255.255.255',
			    [
			     '11.0.0.0',
			     ]],
	    '12.0.0.0' => [ '255.255.255.0',
			    []],
	    );

for my $o (1..254) {
    push @{$addr{'12.0.0.0'}->[1]}, '12.0.0.' . $o;
}

my $count = $| = 1;
print "1..", (2 * scalar keys %addr), "\n";

for my $a (keys %addr) {
    my $ip = new NetAddr::IP $a, $addr{$a}->[0];
    my @r = $ip->hostenum;
    my @m = ();

    if (scalar @r == @{$addr{$a}->[1]}) {
	print "ok ", $count++, "\n";
    }
    else {
	print "not ok ", $count++, " (number $a)\n";
    }

    for my $r (@r) {
	push @m, grep { $_ eq $r->addr } @{$addr{$a}->[1]};
    }

    if (scalar @m == scalar @r) {
	print "ok ", $count++, "\n";
    }
    else {
	print "not ok ", $count++, " (match $a)\n";
	print "henum=", join(', ', (map { $_->addr } @r)), "\n";
	print "match=", join(', ', @m), "\n";

    }
}
