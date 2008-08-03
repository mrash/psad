#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

use Date::Calc qw( Parse_Date );

# ======================================================================
#   ($year,$mm,$dd) = Parse_Date($date);
# ======================================================================

print "1..8\n";

$n = 1;
unless (($year,$mm,$dd) = Parse_Date(""))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Parse_Date("Sat Dec  2 00:10:10 1995")) &&
($year==1995) && ($mm==12) && ($dd==2))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Parse_Date("Tue Jan 04 16:31:59 1996")) &&
($year==1996) && ($mm==1) && ($dd==4))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Parse_Date("Sun Feb 16 00:01:13 GMT+0100 1997")) &&
($year==1997) && ($mm==2) && ($dd==16))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Parse_Date("Jane 1997 Feb 16 birthday")) &&
($year==1997) && ($mm==2) && ($dd==16))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Parse_Date("Jan 1997 Feb 16 birthday")) &&
($year==1997) && ($mm==2) && ($dd==16))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

unless (($year,$mm,$dd) = Parse_Date("Tue Jan 04 16:31:59 1896"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

unless (($year,$mm,$dd) = Parse_Date("Sun Feb 29 00:01:13 GMT+0100 1997"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

