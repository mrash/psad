#!perl -w

###############################################################################
##                                                                           ##
##    Copyright (c) 1995 - 2002 by Steffen Beyer.                            ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

use strict;

use ExtUtils::MakeMaker;

use Config;

WriteMakefile(
    'NAME'              => 'Bit::Vector',
    'VERSION_FROM'      => 'Vector.pm',
    'OBJECT'            => '$(O_FILES)',
#   ($] >= 5.005 ?
#       ('ABSTRACT'     => 'Efficient base class implementing bit vectors',
#        'AUTHOR'       => 'Steffen Beyer (sb@engelschall.com)') : ()),
#   ($] >= 5.005 && $^O eq 'MSWin32' && $Config{archname} =~ /-object\b/i ?
#       ('CAPI'         => 'TRUE') : ()),
    'dist'              => { COMPRESS => "gzip -9", SUFFIX => "gz" }
);

my $patchlevel = $0;

$patchlevel =~ s![^/\\]*$!patchlevel.h!;

my $PATCHLEVEL = $Config{'PATCHLEVEL'} || $Config{'patchlevel'} || substr($],2,3);
my $SUBVERSION = $Config{'SUBVERSION'} || $Config{'subversion'} || substr($],5) || 0;

if (open(PATCHLEVEL, ">$patchlevel"))
{
    print "Writing $patchlevel for $^X ($])\n";
    printf PATCHLEVEL "#define PATCHLEVEL %d\n", $PATCHLEVEL;
    printf PATCHLEVEL "#define SUBVERSION %d\n", $SUBVERSION;
    close(PATCHLEVEL);
}
else
{
    warn "Oops: Couldn't write file '$patchlevel': $!\n";
    warn "However, you might succeed in building this module anyway;\n";
    warn "Just try it!\n";
}

__END__

