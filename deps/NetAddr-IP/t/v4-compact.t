use NetAddr::IP qw(Compact);

# $Id: v4-compact.t,v 1.1.1.1 2006/08/14 15:36:06 lem Exp $

my @r = (
	 [ '10.0.0.0', '255.255.255.0'],
	 [ '11.0.0.0', '255.255.255.0'],
	 [ '12.0.0.0', '255.255.255.0'],
	 [ '20.0.0.0', '255.255.0.0'],
	 [ '30.0.0.0', '255.255.0.0'],
	 [ '40.0.0.0', '255.255.0.0'],
	 );

$| = 1;

if (defined($ENV{LIGHTERIPTESTS}) and $ENV{LIGHTERIPTESTS} =~ /yes/i) {
    print "1..0 # Skipped: LIGHTERIPTESTS = yes\n";
    exit 0;
}

print "1..9\n";

my @ips1;

for my $ip ('10.0.0.0', '11.0.0.0', '12.0.0.0') {
    push @ips1, NetAddr::IP->new($ip, 24)->split(32);
}

for my $ip ('20.0.0.0', '30.0.0.0', '40.0.0.0') {
    push @ips1, NetAddr::IP->new($ip, 16)->split(28);
}

my @ips2;

for my $num (0 .. 255) {
    push @ips2, NetAddr::IP->new("192.168.$num.0", 24);
}
my $ips2_compact = '192.168.0.0/16';

# Compact(@)
#
compact_ips1_check(1, Compact(@ips1));
compact_ips2_check(2, Compact(@ips2));

# ->compact(@)
#
compact_ips1_check(3, $ips1[0]->compact(@ips1[1..$#ips1]));
compact_ips2_check(4, $ips2[0]->compact(@ips2[1..$#ips2]));

# Compact([])
#
compact_ips1_check(5, @{Compact(\@ips1)});
compact_ips2_check(6, @{Compact(\@ips2)});

# ->compactref([])
#
compact_ips1_check(7, @{$ips1[0]->compactref([@ips1[1..$#ips1]])});
compact_ips2_check(8, @{$ips2[0]->compactref([@ips2[1..$#ips2]])});

# duplicate IP
#
@ips1 = ();

for my $ip (qw(1.1.1.1 1.1.1.1 1.1.1.1 1.1.1.1)) {
    push(@ips1, NetAddr::IP->new($ip));
}

@c = NetAddr::IP::compact(@ips1);

if (@c == 1 and $c[0]->cidr() eq '1.1.1.1/32') {
    print "ok 9\n";
}
else {
    print "not ok 9\n";
}


######################################################################
sub compact_ips1_check
{
    my $num = shift;
    my @ips = shift;

    my @mips;
    for my $ip (@ips) {
        push @mips, grep { $ip->addr eq $_->[0] and $ip->mask eq $_->[1] } @r;
    }

    if (@mips == @ips) {
        print "ok $num\n";
    }
    else {
        print "not ok $num\n";
    }
}


######################################################################
sub compact_ips2_check
{
    my $num = shift;
    my @ips = shift;

    if (@ips == 1 and $ips[0] eq $ips2_compact) {
        print "ok $num\n";
    }
    else {
        print "not ok $num\n";
    }
}
