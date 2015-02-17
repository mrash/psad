#!perl -w

###############################################################################
##                                                                           ##
##    Copyright (c) 1995 - 2009 by Steffen Beyer.                            ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

use strict;

use ExtUtils::MakeMaker;

BEGIN
{
    eval { require Config_m; }; # ExtUtils::FakeConfig (+ ActivePerl)
    eval { require Config;   }  # Everyone else
    if ($@);
}

print qq{\n};
print qq{*************************************************************\n};
print qq{****** BEWARE: Use "make install UNINST=1" to install! ******\n};
print qq{*************************************************************\n};
print qq{\n};

WriteMakefile(
    'NAME'              => 'Date::Calc',
    'VERSION_FROM'      => 'lib/Date/Calc.pm',
    'ABSTRACT_FROM'     => 'lib/Date/Calc.pod',
    'LICENSE'           => 'perl',
    'AUTHOR'            => 'Steffen Beyer <STBEY@cpan.org>',
    'PREREQ_PM'         => {
                               'Carp::Clan'  => 6.04,
                               'Bit::Vector' => 7.1
                           },
    'META_MERGE'        => {
                               'recommends'  =>
                               {
                                   'Date::Calc::XS' => 6.2
                               }
                           },
    'dist'              => { COMPRESS => "gzip -9", SUFFIX => "gz" },
#   for ActivePerl:
    ($] >= 5.005 && $^O eq 'MSWin32' && $Config::Config{'archname'} =~ /-object\b/i ?
        ('CAPI'         => 'TRUE') : ())
);

__END__

