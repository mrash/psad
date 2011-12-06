use Test::More tests => 12;
use NetAddr::IP::Lite;

my @good = (qw(default any broadcast loopback));
my @bad = map { ("$_.neveranydomainlikethis.in-addr.arpa",
		 "nohostlikethis.${_}.in-addr.arpa") } @good;

my $bad = scalar @bad;

diag <<EOF;

\tThe following $bad tests involve resolving (hopefully)
\tnon-existant names. This may take a while.
EOF

SKIP: {
	skip "defective or missing resolver", 12,
		if defined NetAddr::IP::Lite->new('not.defined.in-addr.arpa');
	ok(!defined NetAddr::IP::Lite->new($_), "not defined ->new($_)")
	    for @bad;
	ok(defined NetAddr::IP::Lite->new($_), "defined ->new($_)")
	    for @good;
};
