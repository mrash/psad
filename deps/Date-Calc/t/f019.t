#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc qw( Days_in_Month );

# ======================================================================
#   $days = Days_in_Month($year,$mm);
# ======================================================================

print "1..26\n";

$n = 1;
eval { Days_in_Month(1964,0); };
if ($@ =~ /month out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Days_in_Month(1964,1) == 31)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Days_in_Month(1964,2) == 29)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Days_in_Month(1964,3) == 31)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Days_in_Month(1964,4) == 30)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Days_in_Month(1964,5) == 31)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Days_in_Month(1964,6) == 30)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Days_in_Month(1964,7) == 31)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Days_in_Month(1964,8) == 31)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Days_in_Month(1964,9) == 30)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Days_in_Month(1964,10) == 31)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Days_in_Month(1964,11) == 30)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Days_in_Month(1964,12) == 31)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Days_in_Month(1995,0); };
if ($@ =~ /month out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Days_in_Month(1995,1) == 31)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Days_in_Month(1995,2) == 28)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Days_in_Month(1995,3) == 31)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Days_in_Month(1995,4) == 30)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Days_in_Month(1995,5) == 31)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Days_in_Month(1995,6) == 30)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Days_in_Month(1995,7) == 31)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Days_in_Month(1995,8) == 31)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Days_in_Month(1995,9) == 30)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Days_in_Month(1995,10) == 31)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Days_in_Month(1995,11) == 30)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Days_in_Month(1995,12) == 31)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

