#!perl

BEGIN
{
    unless ($ENV{AUTHOR_TESTS}) { print "1..0 # skip Skipping author tests\n"; exit 0; }
    eval { require Test::More; Test::More->import(); };
    if ($@) { print "1..0 # skip Test::More is not available on this platform\n"; exit 0; }
    eval { require YAML; YAML->import('LoadFile'); };
    if ($@) { print "1..0 # skip YAML is not available on this platform\n"; exit 0; }
}

use strict;

plan tests => 1;
ok( LoadFile("META.yml") );

__END__

