#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

use Date::Calc qw( Month_to_Text );

# ======================================================================
#   $month = Month_to_Text($mm);
# ======================================================================

print "1..27\n";

$n = 1;
eval { Month_to_Text(0); };
if ($@ =~ /month out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(1) eq "January")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(2) eq "February")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(3) eq "March")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(4) eq "April")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(5) eq "May")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(6) eq "June")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(7) eq "July")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(8) eq "August")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(9) eq "September")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(10) eq "October")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(11) eq "November")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(12) eq "December")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Month_to_Text(13); };
if ($@ =~ /month out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Month_to_Text(14); };
if ($@ =~ /month out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Month_to_Text(15); };
if ($@ =~ /month out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Month_to_Text(16); };
if ($@ =~ /month out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Month_to_Text(17); };
if ($@ =~ /month out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Month_to_Text(18); };
if ($@ =~ /month out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Month_to_Text(19); };
if ($@ =~ /month out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Month_to_Text(20); };
if ($@ =~ /month out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Month_to_Text(21); };
if ($@ =~ /month out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Month_to_Text(22); };
if ($@ =~ /month out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Month_to_Text(23); };
if ($@ =~ /month out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Month_to_Text(24); };
if ($@ =~ /month out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Month_to_Text(25); };
if ($@ =~ /month out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Month_to_Text(26); };
if ($@ =~ /month out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}

__END__

