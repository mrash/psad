#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc qw( Day_of_Week_to_Text Language_to_Text Language );

# ======================================================================
#   $day = Day_of_Week_to_Text($weekday);
# ======================================================================

print "1..38\n";

$n = 1;
eval { Day_of_Week_to_Text(0); };
if ($@ =~ /day of week out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (Day_of_Week_to_Text(1) eq "Monday")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Day_of_Week_to_Text(2) eq "Tuesday")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Day_of_Week_to_Text(3) eq "Wednesday")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Day_of_Week_to_Text(4) eq "Thursday")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Day_of_Week_to_Text(5) eq "Friday")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Day_of_Week_to_Text(6) eq "Saturday")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Day_of_Week_to_Text(7) eq "Sunday")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (($t = Day_of_Week_to_Text(1,0)) eq "Monday")
{print "ok $n\n";} else {print "not ok $n ($t)\n";}
$n++;
if (Day_of_Week_to_Text(2,0) eq "Tuesday")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Day_of_Week_to_Text(3,0) eq "Wednesday")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Day_of_Week_to_Text(4,0) eq "Thursday")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Day_of_Week_to_Text(5,0) eq "Friday")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Day_of_Week_to_Text(6,0) eq "Saturday")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Day_of_Week_to_Text(7,0) eq "Sunday")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (Day_of_Week_to_Text(1,1) eq "Monday")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Day_of_Week_to_Text(2,1) eq "Tuesday")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Day_of_Week_to_Text(3,1) eq "Wednesday")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Day_of_Week_to_Text(4,1) eq "Thursday")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Day_of_Week_to_Text(5,1) eq "Friday")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Day_of_Week_to_Text(6,1) eq "Saturday")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Day_of_Week_to_Text(7,1) eq "Sunday")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (Day_of_Week_to_Text(1,3) eq "Montag")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Day_of_Week_to_Text(2,3) eq "Dienstag")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Day_of_Week_to_Text(3,3) eq "Mittwoch")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Day_of_Week_to_Text(4,3) eq "Donnerstag")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Day_of_Week_to_Text(5,3) eq "Freitag")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Day_of_Week_to_Text(6,3) eq "Samstag")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Day_of_Week_to_Text(7,3) eq "Sonntag")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { Day_of_Week_to_Text(8); };
if ($@ =~ /day of week out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Day_of_Week_to_Text(9,0); };
if ($@ =~ /day of week out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Day_of_Week_to_Text(10,1); };
if ($@ =~ /day of week out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Day_of_Week_to_Text(11,()); };
if ($@ =~ /day of week out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Day_of_Week_to_Text(12,()); };
if ($@ =~ /day of week out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Day_of_Week_to_Text(13); };
if ($@ =~ /day of week out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Day_of_Week_to_Text(14); };
if ($@ =~ /day of week out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Day_of_Week_to_Text(15); };
if ($@ =~ /day of week out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Day_of_Week_to_Text(16); };
if ($@ =~ /day of week out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}

__END__

