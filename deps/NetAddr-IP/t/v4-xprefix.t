use NetAddr::IP;

# $Id: v4-xprefix.t,v 1.1.1.1 2006/08/14 15:36:06 lem Exp $

my @addr = (
	    [ '0.0.0.0/1',		'0-127' ],
	    [ '128.0.0.0/1',		'128-255' ],
	    [ '0.0.0.0/2',		'0-63' ],
	    [ '128.0.0.0/2',		'128-191' ],
	    [ '10.128.0.0/17',		'10.128.0-127.' ]
	    );

$| = 1;
print "1..", (2 * scalar @addr), "\n";

my $count = 1;

for my $a (@addr) {
    my $ip = new NetAddr::IP $a->[0];

#    print "$a->[0] is ", $ip->prefix, "\n";

    if ($ip->prefix eq $a->[1]) {
	print "ok $count\n";
    }
    else {
	print "not ok $count\n";
    }

    ++ $count;

    my $p = new NetAddr::IP $ip->prefix;

#    print $ip->prefix, " is $p\n";


    if ($p->cidr eq $a->[0]) {
	print "ok $count\n";
    }
    else {
	print "not ok $count\n";
    }

    ++ $count;

}


