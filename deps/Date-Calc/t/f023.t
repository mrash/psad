#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc qw( Delta_DHMS );

# ======================================================================
#   ($days,$hh,$mm,$ss) = Delta_DHMS
#   (
#       $year1,$month1,$day1,$hh1,$mm1,$ss1,
#       $year2,$month2,$day2,$hh2,$mm2,$ss2
#   );
# ======================================================================

print "1..21\n";

$n = 1;
if ((($dd,$h,$m,$s) = Delta_DHMS(1995,2,28,7,58,31,1995,2,28,18,12,8)) &&
($dd == 0) && ($h == 10) && ($m == 13) && ($s == 37))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($dd,$h,$m,$s) = Delta_DHMS(1995,2,28,18,12,8,1995,2,28,7,58,31)) &&
($dd == 0) && ($h == -10) && ($m == -13) && ($s == -37))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($dd,$h,$m,$s) = Delta_DHMS(1995,2,28,18,12,8,1995,3,1,7,58,31)) &&
($dd == 0) && ($h == 13) && ($m == 46) && ($s == 23))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($dd,$h,$m,$s) = Delta_DHMS(1995,3,1,18,12,8,1995,2,28,7,58,31)) &&
($dd == -1) && ($h == -10) && ($m == -13) && ($s == -37))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { ($dd,$h,$m,$s) = Delta_DHMS(1995,2,29,18,12,8,1995,2,28,7,58,31); };
if ($@ =~ /not a valid (?:date|time)/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { ($dd,$h,$m,$s) = Delta_DHMS(1995,2,28,18,12,8,1995,2,29,7,58,31); };
if ($@ =~ /not a valid (?:date|time)/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { ($dd,$h,$m,$s) = Delta_DHMS(1995,2,29,18,12,8,1995,2,29,7,58,31); };
if ($@ =~ /not a valid (?:date|time)/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { ($dd,$h,$m,$s) = Delta_DHMS(1995,2,28,-1,12,8,1995,2,28,7,58,31); };
if ($@ =~ /not a valid (?:date|time)/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { ($dd,$h,$m,$s) = Delta_DHMS(1995,2,28,18,-1,8,1995,2,28,7,58,31); };
if ($@ =~ /not a valid (?:date|time)/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { ($dd,$h,$m,$s) = Delta_DHMS(1995,2,28,18,12,-1,1995,2,28,7,58,31); };
if ($@ =~ /not a valid (?:date|time)/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { ($dd,$h,$m,$s) = Delta_DHMS(1995,2,28,18,12,8,1995,2,28,-1,58,31); };
if ($@ =~ /not a valid (?:date|time)/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { ($dd,$h,$m,$s) = Delta_DHMS(1995,2,28,18,12,8,1995,2,28,7,-1,31); };
if ($@ =~ /not a valid (?:date|time)/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { ($dd,$h,$m,$s) = Delta_DHMS(1995,2,28,18,12,8,1995,2,28,7,58,-1); };
if ($@ =~ /not a valid (?:date|time)/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { ($dd,$h,$m,$s) = Delta_DHMS(1995,2,28,24,12,8,1995,2,28,7,58,31); };
if ($@ =~ /not a valid (?:date|time)/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { ($dd,$h,$m,$s) = Delta_DHMS(1995,2,28,18,60,8,1995,2,28,7,58,31); };
if ($@ =~ /not a valid (?:date|time)/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { ($dd,$h,$m,$s) = Delta_DHMS(1995,2,28,18,12,60,1995,2,28,7,58,31); };
if ($@ =~ /not a valid (?:date|time)/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { ($dd,$h,$m,$s) = Delta_DHMS(1995,2,28,18,12,8,1995,2,28,24,58,31); };
if ($@ =~ /not a valid (?:date|time)/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { ($dd,$h,$m,$s) = Delta_DHMS(1995,2,28,18,12,8,1995,2,28,7,60,31); };
if ($@ =~ /not a valid (?:date|time)/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { ($dd,$h,$m,$s) = Delta_DHMS(1995,2,28,18,12,8,1995,2,28,7,58,60); };
if ($@ =~ /not a valid (?:date|time)/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($dd,$h,$m,$s) = Delta_DHMS(1964,1,3,11,4,0,1997,2,13,22,51,31)) &&
($dd == 12095) && ($h == 11) && ($m == 47) && ($s == 31))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($dd,$h,$m,$s) = Delta_DHMS(1997,2,13,22,51,31,1964,1,3,11,4,0)) &&
($dd == -12095) && ($h == -11) && ($m == -47) && ($s == -31))
{print "ok $n\n";} else {print "not ok $n\n";}

__END__

