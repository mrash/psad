#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc qw( Nth_Weekday_of_Month_Year );

# ======================================================================
#   ($year,$mm,$dd) = Nth_Weekday_of_Month_Year($year,$month,$wday,$nth);
# ======================================================================

print "1..5\n";

$n = 1;
if ((($year,$mm,$dd) = Nth_Weekday_of_Month_Year(1996,4,4,2)) &&
($year==1996) && ($mm==4) && ($dd==11))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Nth_Weekday_of_Month_Year(1996,4,1,4)) &&
($year==1996) && ($mm==4) && ($dd==22))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Nth_Weekday_of_Month_Year(1996,4,1,5)) &&
($year==1996) && ($mm==4) && ($dd==29))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

unless (($year,$mm,$dd) = Nth_Weekday_of_Month_Year(1996,4,3,5))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Nth_Weekday_of_Month_Year(1997,2,5,1)) &&
($year==1997) && ($mm==2) && ($dd==7))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

