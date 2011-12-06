use Test::More tests => 19;

my @addr = (
	[ 'localhost', '127.0.0.1' ],
	[ 'broadcast', '255.255.255.255' ],
	[ '254.254.0.1', '254.254.0.1' ],
	[ 'default', '0.0.0.0' ],
	[ '10.0.0.1', '10.0.0.1' ],

);
my %addr = (
        localhost       => pack('N',0x7f000001),
        broadcast       => pack('N',0xffffffff),
        '254.254.0.1'   => pack('N',0xfefe0001),
        default         => pack('N',0),
        '10.0.0.1'      => pack('N',0x0a000001),
	'127.0.0.1'	=> pack('N',0x7f000001),
	'255.255.255.255' => pack('N',0xffffffff),
	'0.0.0.0'	=> pack('N',0),
);

# local inet_aton, don't use perl's Socket

sub l_inet_aton {
  my $rv = (exists $addr{$_[0]}) ? $addr{$_[0]} : undef;
}


# Verify that Accept_Binary_IP works...

my $x;

SKIP:
{
    skip "Failed to load NetAddr::IP::Lite", 17
	unless use_ok('NetAddr::IP::Lite');

    ok(! defined NetAddr::IP::Lite->new("\1\1\1\1"),
       "binary unrecognized by default ". ($x ? $x->addr :''));

    # This mimicks the actual use with :aton
    NetAddr::IP::Lite::import(':aton');

    ok(defined ($x = NetAddr::IP::Lite->new("\1\1\1\1")),
       "...but can be recognized ". $x->addr);

    ok(!defined ($x = NetAddr::IP::Lite->new('bad rfc-952 characters')),
	"bad rfc-952 characters ". ($x ? $x->addr :''));

    is(NetAddr::IP::Lite->new($_->[0])->aton, l_inet_aton($_->[1]), "->aton($_->[0])")
	for @addr;

    ok(defined NetAddr::IP::Lite->new(l_inet_aton($_->[1])), "->new aton($_->[1])")
	for @addr;

    is(NetAddr::IP::Lite->new(l_inet_aton($_->[1]))->addr, $_->[1],
       "->new aton($_->[1])")
	for @addr;
};
