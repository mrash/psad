#!perl

BEGIN
{
    unless ($ENV{AUTHOR_TESTS}) { print "1..0 # skip Skipping author tests\n"; exit 0; }
    eval { require Test::More; Test::More->import(); };
    if ($@) { print "1..0 # skip Test::More is not available on this platform\n"; exit 0; }
    eval { require Test::Pod; Test::Pod->import(); };
    if ($@) { print "1..0 # skip Test::Pod is not available on this platform\n"; exit 0; }
}

use strict;

my $version = Test::Pod->VERSION;
if ( $version < 1.14 ) { die "Test::Pod::Coverage version 1.14 required--this is only version $version"; }
all_pod_files_ok();

__END__

