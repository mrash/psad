#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc qw( Decode_Month );

# ======================================================================
#   $month_name = Decode_Month($month);
# ======================================================================

print "1..58\n";

$n = 1;
if (Decode_Month("j") == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("ja") == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("jan") == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("January") == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("f") == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("fe") == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("feb") == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("February") == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("m") == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("ma") == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("mar") == 3)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("March") == 3)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("a") == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("ap") == 4)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("apr") == 4)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("April") == 4)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("m") == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("ma") == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("may") == 5)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("May") == 5)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("j") == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("ju") == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("jun") == 6)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("June") == 6)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("j") == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("ju") == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("jul") == 7)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("July") == 7)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("a") == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("au") == 8)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("aug") == 8)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("August") == 8)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("s") == 9)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("se") == 9)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("sep") == 9)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("September") == 9)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("o") == 10)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("oc") == 10)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("oct") == 10)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("October") == 10)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("n") == 11)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("no") == 11)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("nov") == 11)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("November") == 11)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("d") == 12)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("de") == 12)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("dec") == 12)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("December") == 12)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("Spring") == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("Summer") == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("Fall") == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("Winter") == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (Decode_Month("May",0) == 5)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("Mar",1) == 3)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("Mag",7) == 5)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("Giu",7) == 6)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("Tam",11) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Decode_Month("dic",4) == 12)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__
