use NetAddr::IP;

# $Id: v4-split-list.t,v 1.1.1.1 2006/08/14 15:36:06 lem Exp $

my %addr = (
	    '10.0.0.10' => [ '255.255.252.0', 24,
			    [
			     '10.0.0.0', '10.0.1.0',
			     '10.0.2.0', '10.0.3.0'
			     ]],
	    '10.0.0.1' => [ '255.255.255.254', 32,
			    [
			     '10.0.0.0', '10.0.0.1',
			     ]],
	    '10.0.0.2' => [ '255.255.255.255', 32,
			    [
			     '10.0.0.2',
			     ]],
	    '10.0.0.3' => [ '255.255.255.252', 32,
			    [
			     '10.0.0.0', '10.0.0.1',
			     '10.0.0.2', '10.0.0.3',
			     ]],
	    );

my $count = $| = 1;
print "1..", (2 * scalar keys %addr), "\n";

for my $a (keys %addr) {
    my $ip = new NetAddr::IP $a, $addr{$a}->[0];
    my @r = $ip->split($addr{$a}->[1]);
    my @m = ();

    if (scalar @r == @{$addr{$a}->[2]}) {
	print "ok ", $count++, "\n";
    }
    else {
	print "not ok ", $count++, " (number $a)\n";
    }

    for my $r (@r) {
	push @m, grep { $_ eq $r->addr } @{$addr{$a}->[2]};
    }

    if (scalar @m == scalar @r) {
	print "ok ", $count++, "\n";
    }
    else {
	print "not ok ", $count++, " (match $a)\n";
	print "split=", join(', ', (map { $_->addr } @r)), "\n";
	print "match=", join(', ', @m), "\n";

    }
}
