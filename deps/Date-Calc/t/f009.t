#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc qw( Day_of_Week );

# ======================================================================
#   $weekday = Day_of_Week($year,$mm,$dd);
# ======================================================================

print "1..11\n";

$n = 1;
if (Day_of_Week(1964,1,3)   == 5) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Day_of_Week(1995,11,13) == 1) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Day_of_Week(1995,11,14) == 2) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Day_of_Week(1995,11,15) == 3) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Day_of_Week(1995,11,16) == 4) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Day_of_Week(1995,11,17) == 5) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Day_of_Week(1995,11,18) == 6) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Day_of_Week(1995,11,19) == 7) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Day_of_Week(1995,11,20) == 1) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Day_of_Week(1995,2,28) == 2) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Day_of_Week(1995,2,29); };
if ($@ =~ /not a valid date/)
{print "ok $n\n";} else {print "not ok $n\n";}

__END__

