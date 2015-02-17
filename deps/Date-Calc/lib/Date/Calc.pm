
###############################################################################
##                                                                           ##
##    Copyright (c) 1995 - 2009 by Steffen Beyer.                            ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

package Date::Calc;

use strict;
use vars qw($XS_OK $XS_DISABLE @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

BEGIN # Re-export imports from Date::Calc::XS or Date::Calc::PP:
{
    require Exporter;
    @ISA = qw(Exporter);
    $XS_OK = 0;
    unless ($XS_DISABLE and $XS_DISABLE) # prevent warning "used only once"
    {
        eval
        {
            require Date::Calc::XS;
            @EXPORT      = (@Date::Calc::XS::EXPORT);
            @EXPORT_OK   = (@Date::Calc::XS::EXPORT_OK);
            %EXPORT_TAGS = (all => [@EXPORT_OK]);
            Date::Calc::XS->import(@EXPORT,@EXPORT_OK);
        };
        if ($@) { die $@ unless ($@ =~ /^Can't locate .*? at /); }
        else    { $XS_OK = 1; }
    }
    unless ($XS_OK)
    {
        require Date::Calc::PP;
        @EXPORT      = (@Date::Calc::PP::EXPORT);
        @EXPORT_OK   = (@Date::Calc::PP::EXPORT_OK);
        %EXPORT_TAGS = (all => [@EXPORT_OK]);
        Date::Calc::PP->import(@EXPORT,@EXPORT_OK);
    }
}

##################################################
##                                              ##
##  "Version()" is available but not exported   ##
##  in order to avoid possible name clashes.    ##
##  Call with "Date::Calc::Version()" instead!  ##
##                                              ##
##################################################

$VERSION     = '6.3';

sub Version { return $VERSION; }

1;

__END__

