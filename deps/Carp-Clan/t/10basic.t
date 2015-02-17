#!perl -w

BEGIN
{
    eval { require Test::More; Test::More->import(); };
    if ($@) { print "1..0 # skip Test::More is not available on this platform\n"; exit 0; }
    eval { require Test::Exception; Test::Exception->import(); };
    if ($@) { print "1..0 # skip Test::Exception is not available on this platform\n"; exit 0; }
}

use strict;

plan tests => 2;

use_ok( 'Carp::Clan', 'Use Carp::Clan' );

lives_ok(
    sub {
        Carp::Clan->import(qw(^Carp\\b));
        return 1;
    },
    'No errors importing'
);

__END__

