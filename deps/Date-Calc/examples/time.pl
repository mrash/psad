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

use Date::Calc::Object qw(:all);

Date::Calc->date_format(2);

$time = time;

$date = Date::Calc->new(Today_and_Now(0));
print "Today_and_Now(0)          = $date\n";

$date = Date::Calc->new(Today_and_Now(1));
print "Today_and_Now(1)          = $date\n";

$date = Date::Calc->new( 0, Add_Delta_DHMS( 1970,1,1, 0,0,0, 0,0,0,$time ) );
print "Add_Delta_DHMS($time) = $date\n";

$date = Date::Calc->gmtime(time);
print "gmtime($time)         = $date\n";

$date->localtime(time);
print "localtime($time)      = $date\n";

__END__

