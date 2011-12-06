use NetAddr::IP;

# $Id: v4-sprefix.t,v 1.1.1.1 2006/08/14 15:36:06 lem Exp $

my @addr = (
	    [ '10.',		'10.0.0.0/8' ],
	    [ '11.11.',		'11.11.0.0/16' ],
	    [ '12.12.12.',	'12.12.12.0/24' ],
	    [ '13.13.13.13',	'13.13.13.13/32' ],
	    );

$| = 1;
print "1..", (3 * scalar @addr), "\n";

my $count = 1;

for my $a (@addr) {
    my $ip = new NetAddr::IP $a->[0];

    if ($ip->cidr eq $a->[1]) {
	print "ok $count\n";
    }
    else {
	print "not ok $count\n";
    }

    ++ $count;

    my $p = new NetAddr::IP $ip->cidr;

    if ($p->prefix eq $a->[0]) {
	print "ok $count\n";
    }
    else {
	print "not ok $count\n";
    }

    ++ $count;

    if ($p->nprefix eq $a->[0]) {
	print "ok $count\n";
    }
    else {
	print "not ok $count\n";
    }

    ++ $count;

}


