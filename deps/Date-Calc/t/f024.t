#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc qw( Add_Delta_DHMS );

# ======================================================================
#   ($year,$month,$day,$hh,$mm,$ss) = Add_Delta_DHMS
#   (
#       $year,$month,$day,$hh,$mm,$ss,
#       $days_offset,$hh_offset,$mm_offset,$ss_offset
#   );
# ======================================================================

print "1..8\n";

$n = 1;
if ((($yy,$mm,$dd,$h,$m,$s) = Add_Delta_DHMS(1995,2,28,18,12,8,0,0,0,999983)) &&
($yy == 1995) && ($mm == 3) && ($dd == 12) && ($h == 7) && ($m == 58) && ($s == 31))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { ($yy,$mm,$dd,$h,$m,$s) = Add_Delta_DHMS(1995,2,29,18,12,8,0,0,0,999983); };
if ($@ =~ /not a valid date/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { ($yy,$mm,$dd,$h,$m,$s) = Add_Delta_DHMS(1995,2,28,24,12,8,0,0,0,999983); };
if ($@ =~ /not a valid time/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { ($yy,$mm,$dd,$h,$m,$s) = Add_Delta_DHMS(1995,2,28,18,60,8,0,0,0,999983); };
if ($@ =~ /not a valid time/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { ($yy,$mm,$dd,$h,$m,$s) = Add_Delta_DHMS(1995,2,28,18,12,60,0,0,0,999983); };
if ($@ =~ /not a valid time/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($yy,$mm,$dd,$h,$m,$s) = Add_Delta_DHMS(2,2,28,18,12,8,-58,-19,2,-1)) &&
($yy == 1) && ($mm == 12) && ($dd == 31) && ($h == 23) && ($m == 14) && ($s == 7))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($yy,$mm,$dd,$h,$m,$s) = Add_Delta_DHMS(1,2,28,18,12,8,-57,-19,2,-1)) &&
($yy == 1) && ($mm == 1) && ($dd == 1) && ($h == 23) && ($m == 14) && ($s == 7))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { ($yy,$mm,$dd,$h,$m,$s) = Add_Delta_DHMS(1,2,28,18,12,8,-58,-19,2,-1); };
if ($@ =~ /not a valid date/)
{print "ok $n\n";} else {print "not ok $n\n";}

__END__

