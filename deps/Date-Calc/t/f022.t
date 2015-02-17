#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc qw( Delta_DHMS Add_Delta_DHMS );

# ======================================================================
#   ($days,$hh,$mm,$ss) = Delta_DHMS
#   (
#       $year1,$month1,$day1,$hh1,$mm1,$ss1,
#       $year2,$month2,$day2,$hh2,$mm2,$ss2
#   );
# ======================================================================

# ======================================================================
#   ($year,$month,$day,$hh,$mm,$ss) = Add_Delta_DHMS
#   (
#       $year,$month,$day,$hh,$mm,$ss,
#       $days_offset,$hh_offset,$mm_offset,$ss_offset
#   );
# ======================================================================

print "1..16\n";

$n = 1;
($dd,$h,$m,$s) = Delta_DHMS(1996,5,23,23,58,2,1996,5,25,0,1,1);
if (($dd == 1) && ($h == 0) && ($m == 2) && ($s == 59))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
($dd,$h,$m,$s) = Delta_DHMS(1996,5,25,0,1,1,1996,5,23,23,58,2);
if (($dd == -1) && ($h == 0) && ($m == -2) && ($s == -59))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
($yy,$mm,$dd,$h,$m,$s) = Add_Delta_DHMS(1996,5,23,23,58,2,1,0,2,59);
if (($yy == 1996) && ($mm == 5) && ($dd == 25) && ($h == 0) && ($m == 1) && ($s == 1))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
($yy,$mm,$dd,$h,$m,$s) = Add_Delta_DHMS(1996,5,25,0,1,1,-1,0,-2,-59);
if (($yy == 1996) && ($mm == 5) && ($dd == 23) && ($h == 23) && ($m == 58) && ($s == 2))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
($dd,$h,$m,$s) = Delta_DHMS(1996,5,25,18,12,8,1996,6,15,14,12,8);
if (($dd == 20) && ($h == 20) && ($m == 0) && ($s == 0))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
($dd,$h,$m,$s) = Delta_DHMS(1996,6,15,14,12,8,1996,5,25,18,12,8);
if (($dd == -20) && ($h == -20) && ($m == 0) && ($s == 0))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
($yy,$mm,$dd,$h,$m,$s) = Add_Delta_DHMS(1996,5,25,18,12,8,0,500,0,0);
if (($yy == 1996) && ($mm == 6) && ($dd == 15) && ($h == 14) && ($m == 12) && ($s == 8))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
($yy,$mm,$dd,$h,$m,$s) = Add_Delta_DHMS(1996,6,15,14,12,8,0,-500,0,0);
if (($yy == 1996) && ($mm == 5) && ($dd == 25) && ($h == 18) && ($m == 12) && ($s == 8))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
($dd,$h,$m,$s) = Delta_DHMS(1996,5,25,18,12,8,1996,6,6,7,58,31);
if (($dd == 11) && ($h == 13) && ($m == 46) && ($s == 23))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
($dd,$h,$m,$s) = Delta_DHMS(1996,6,6,7,58,31,1996,5,25,18,12,8);
if (($dd == -11) && ($h == -13) && ($m == -46) && ($s == -23))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
($yy,$mm,$dd,$h,$m,$s) = Add_Delta_DHMS(1996,5,25,18,12,8,0,0,0,999983);
if (($yy == 1996) && ($mm == 6) && ($dd == 6) && ($h == 7) && ($m == 58) && ($s == 31))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
($yy,$mm,$dd,$h,$m,$s) = Add_Delta_DHMS(1996,6,6,7,58,31,0,0,0,-999983);
if (($yy == 1996) && ($mm == 5) && ($dd == 25) && ($h == 18) && ($m == 12) && ($s == 8))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
($dd,$h,$m,$s) = Delta_DHMS(1964,1,3,11,0,0,1996,5,25,18,12,8);
if (($dd == 11831) && ($h == 7) && ($m == 12) && ($s == 8))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
($dd,$h,$m,$s) = Delta_DHMS(1996,5,25,18,12,8,1964,1,3,11,0,0);
if (($dd == -11831) && ($h == -7) && ($m == -12) && ($s == -8))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
($yy,$mm,$dd,$h,$m,$s) = Add_Delta_DHMS(1964,1,3,11,0,0,11831,7,12,8);
if (($yy == 1996) && ($mm == 5) && ($dd == 25) && ($h == 18) && ($m == 12) && ($s == 8))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
($yy,$mm,$dd,$h,$m,$s) = Add_Delta_DHMS(1996,5,25,18,12,8,-11831,-7,-12,-8);
if (($yy == 1964) && ($mm == 1) && ($dd == 3) && ($h == 11) && ($m == 0) && ($s == 0))
{print "ok $n\n";} else {print "not ok $n\n";}

__END__
