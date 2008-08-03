#!perl -w

###############################################################################
##                                                                           ##
##    Copyright (c) 2001, 2002 by Steffen Beyer.                             ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This program is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

use Date::Calendar::Profiles qw( $Profiles );
use Date::Calendar;

$cal = Date::Calendar->new( $Profiles->{'DE-NW'} );

$year = $cal->year( 2002 );

$delta = $year->delta_workdays( 2002,1,1, 2002,2,3, 1,1 );

print "$delta\n";

__END__

