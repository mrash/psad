#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc qw( Decode_Date_EU Decode_Date_US );

# ======================================================================
#   ($year,$mm,$dd) = Decode_Date_EU($buffer);
#   ($year,$mm,$dd) = Decode_Date_US($buffer);
# ======================================================================

print "1..25\n";

$n = 1;
if ((($year,$mm,$dd) = Decode_Date_EU("3.1.64")) &&
($year==1964)&&($mm==1)&&($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($year,$mm,$dd) = Decode_Date_EU("3 1 64")) &&
($year==1964)&&($mm==1)&&($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($year,$mm,$dd) = Decode_Date_EU("03.01.64")) &&
($year==1964)&&($mm==1)&&($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($year,$mm,$dd) = Decode_Date_EU("03/01/64")) &&
($year==1964)&&($mm==1)&&($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($year,$mm,$dd) = Decode_Date_EU("3. Ene 1964",4)) &&
($year==1964)&&($mm==1)&&($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($year,$mm,$dd) = Decode_Date_EU("Geburtstag: 3. Januar '64 in Backnang/Württemberg",3)) &&
($year==1964)&&($mm==1)&&($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($year,$mm,$dd) = Decode_Date_EU("03-Jan-64")) &&
($year==1964)&&($mm==1)&&($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($year,$mm,$dd) = Decode_Date_EU("3.Jan1964",6)) &&
($year==1964)&&($mm==1)&&($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($year,$mm,$dd) = Decode_Date_EU("3Jan64",0)) &&
($year==1964)&&($mm==1)&&($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($year,$mm,$dd) = Decode_Date_EU("030164")) &&
($year==1964)&&($mm==1)&&($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($year,$mm,$dd) = Decode_Date_EU("3ja64")) &&
($year==1964)&&($mm==1)&&($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($year,$mm,$dd) = Decode_Date_EU("3164")) &&
($year==1964)&&($mm==1)&&($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_EU("28.2.1995")) &&
($year==1995)&&($mm==2)&&($dd==28))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (($year,$mm,$dd) = Decode_Date_EU("29.2.1995"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_US("1 3 64")) &&
($year==1964)&&($mm==1)&&($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($year,$mm,$dd) = Decode_Date_US("01/03/64")) &&
($year==1964)&&($mm==1)&&($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($year,$mm,$dd) = Decode_Date_US("Jan 3 '64")) &&
($year==1964)&&($mm==1)&&($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($year,$mm,$dd) = Decode_Date_US("Jan 3 1964")) &&
($year==1964)&&($mm==1)&&($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($year,$mm,$dd) = Decode_Date_US("===> January 3rd 1964 (birthday)")) &&
($year==1964)&&($mm==1)&&($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($year,$mm,$dd) = Decode_Date_US("Jan31964")) &&
($year==1964)&&($mm==1)&&($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($year,$mm,$dd) = Decode_Date_US("Jan364")) &&
($year==1964)&&($mm==1)&&($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($year,$mm,$dd) = Decode_Date_US("ja364")) &&
($year==1964)&&($mm==1)&&($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($year,$mm,$dd) = Decode_Date_US("1364")) &&
($year==1964)&&($mm==1)&&($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Decode_Date_US("2.28.1995")) &&
($year==1995)&&($mm==2)&&($dd==28))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (($year,$mm,$dd) = Decode_Date_US("2.29.1995"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

