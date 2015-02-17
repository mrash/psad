#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc qw( Month_to_Text );

# ======================================================================
#   $month = Month_to_Text($mm);
# ======================================================================

print "1..63\n";

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

if (Month_to_Text(1,0) eq "January")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(2,0) eq "February")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(3,0) eq "March")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(4,0) eq "April")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(5,0) eq "May")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(6,0) eq "June")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(7,0) eq "July")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(8,0) eq "August")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(9,0) eq "September")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(10,0) eq "October")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(11,0) eq "November")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(12,0) eq "December")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (Month_to_Text(1,1) eq "January")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(2,1) eq "February")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(3,1) eq "March")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(4,1) eq "April")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(5,1) eq "May")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(6,1) eq "June")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(7,1) eq "July")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(8,1) eq "August")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(9,1) eq "September")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(10,1) eq "October")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(11,1) eq "November")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(12,1) eq "December")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (Month_to_Text(1,6) eq "januari")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(2,6) eq "februari")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(3,6) eq "maart")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(4,6) eq "april")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(5,6) eq "mei")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(6,6) eq "juni")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(7,6) eq "juli")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(8,6) eq "augustus")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(9,6) eq "september")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(10,6) eq "oktober")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(11,6) eq "november")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Month_to_Text(12,6) eq "december")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { Month_to_Text(13); };
if ($@ =~ /month out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Month_to_Text(14,0); };
if ($@ =~ /month out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Month_to_Text(15,1); };
if ($@ =~ /month out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Month_to_Text(16,()); };
if ($@ =~ /month out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Month_to_Text(17,); };
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

