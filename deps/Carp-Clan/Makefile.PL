#!perl

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Carp::Clan',
    AUTHOR        => 'Steffen Beyer <STBEY@cpan.org>',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/Carp/Clan.pm',
    ABSTRACT_FROM => 'lib/Carp/Clan.pod',
    PREREQ_PM     => { 'Test::Exception' => 0 },
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean         => { FILES => 'Carp-Clan-*' }
);

__END__

