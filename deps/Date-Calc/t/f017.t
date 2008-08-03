#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

use Date::Calc qw( Day_of_Week_to_Text );

# ======================================================================
#   $day = Day_of_Week_to_Text($weekday);
# ======================================================================

print "1..17\n";

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
eval { Day_of_Week_to_Text(8); };
if ($@ =~ /day of week out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Day_of_Week_to_Text(9); };
if ($@ =~ /day of week out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Day_of_Week_to_Text(10); };
if ($@ =~ /day of week out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Day_of_Week_to_Text(11); };
if ($@ =~ /day of week out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Day_of_Week_to_Text(12); };
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

