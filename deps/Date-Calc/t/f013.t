#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc qw( Week_of_Year );

# ======================================================================
#   ($week,$year) = Week_of_Year($year,$mm,$dd);
# ======================================================================

print "1..8\n";

$n = 1;
if ((($week,$year) = Week_of_Year(1995,1,1)) &&
($week==52)&&($year==1994))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($week,$year) = Week_of_Year(1995,11,18)) &&
($week==46)&&($year==1995))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($week,$year) = Week_of_Year(1995,12,31)) &&
($week==52)&&($year==1995))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($week,$year) = Week_of_Year(1964,1,3)) &&
($week==1)&&($year==1964))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($week,$year) = Week_of_Year(1964,12,31)) &&
($week==53)&&($year==1964))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($week,$year) = Week_of_Year(1965,1,1)) &&
($week==53)&&($year==1964))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { ($week,$year) = Week_of_Year(0,1,1); };
if ($@ =~ /not a valid date/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { ($week,$year) = Week_of_Year(1997,2,29); };
if ($@ =~ /not a valid date/)
{print "ok $n\n";} else {print "not ok $n\n";}

__END__

