use Test::More;

# $Id: v4-re.t,v 1.1.1.1 2006/08/14 15:36:06 lem Exp $

my @ips = qw!
    10.11.12.13
    10.11.12/24
    10.11.0/27
    !;

plan tests => 299;

die "# Cannot continue without NetAddr::IP\n"
    unless use_ok('NetAddr::IP');

my @addrs = map { new NetAddr::IP $_ } @ips;

for my $a (@addrs)
{
    isa_ok($a, 'NetAddr::IP');
    my $re = $a->re;
    my $rx;

    eval { $rx = qr/$re/ };
    diag "Compilation of the resulting regular expression failed: $@"
	unless ok(!$@, "Compilation of the resulting regular expression");

    for (my $ip = $a->network;
	 $ip < $a->broadcast && $a->masklen != 32;
	 $ip ++)
    {
	ok($a->addr =~ m/$rx/, "Match of $ip in $a");
    }

    ok($a->broadcast->addr =~ m/$rx/, "Match of broadcast of $a");
    ok(NetAddr::IP->new('default') !~ m/$rx/, "0/0 does not match");
}

