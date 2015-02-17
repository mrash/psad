#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc qw( Decode_Day_of_Week );

# ======================================================================
#   $weekday = Decode_Day_of_Week($buffer);
# ======================================================================

print "1..40\n";

$n = 1;
if (Decode_Day_of_Week("m") == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("mo") == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("mon") == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("Monday") == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("t") == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("tu") == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("tue") == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("Tuesday") == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("w") == 3)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("we") == 3)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("wed") == 3)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("Wednesday") == 3)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("t") == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("th") == 4)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("thu") == 4)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("Thursday") == 4)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("f") == 5)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("fr") == 5)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("fri") == 5)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("Friday") == 5)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("s") == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("sa") == 6)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("sat") == 6)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("Saturday") == 6)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("s") == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("su") == 7)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("sun") == 7)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("Sunday") == 7)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("workday") == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("funday") == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("bad day") == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("sunny day") == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("payday") == 0)                     # too bad! ;-)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("holyday") == 0)                    # sigh. ;-)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (Decode_Day_of_Week("Sun",0) == 7)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("Sonntag",3) == 7)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("Dimanche",2) == 7)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("Dim",2) == 7)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("Jue",4) == 4)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Day_of_Week("Qua",5) == 3)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__
