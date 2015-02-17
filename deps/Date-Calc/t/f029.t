#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc qw( Add_Delta_YMD );

# ======================================================================
#   ($year,$mm,$dd) = Add_Delta_YMD($year,  $mm,    $dd,
#                                   $y_offs,$m_offs,$d_offs);
# ======================================================================

print "1..23\n";

$n = 1;
eval { ($year,$mm,$dd) = Add_Delta_YMD(0,0,0,0,0,0); };
if ($@ =~ /not a valid date/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { ($year,$mm,$dd) = Add_Delta_YMD(0,2,28,0,0,0); };
if ($@ =~ /not a valid date/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { ($year,$mm,$dd) = Add_Delta_YMD(1997,0,28,0,0,0); };
if ($@ =~ /not a valid date/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { ($year,$mm,$dd) = Add_Delta_YMD(1997,2,0,0,0,0); };
if ($@ =~ /not a valid date/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { ($year,$mm,$dd) = Add_Delta_YMD(1997,2,29,0,0,0); };
if ($@ =~ /not a valid date/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Add_Delta_YMD(1996,2,29,0,0,0)) &&
($year==1996) && ($mm==2) && ($dd==29))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Add_Delta_YMD(1992,2,29,4,0,0)) &&
($year==1996) && ($mm==2) && ($dd==29))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Add_Delta_YMD(1996,2,29,1,0,0)) &&
($year==1997) && ($mm==3) && ($dd==1))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Add_Delta_YMD(1997,1,29,0,1,0)) &&
($year==1997) && ($mm==3) && ($dd==1))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Add_Delta_YMD(1996,2,28,0,0,1)) &&
($year==1996) && ($mm==2) && ($dd==29))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Add_Delta_YMD(1997,2,28,0,0,1)) &&
($year==1997) && ($mm==3) && ($dd==1))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { ($year,$mm,$dd) = Add_Delta_YMD(1,1,1,0,0,-1); };
if ($@ =~ /not a valid date/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { ($year,$mm,$dd) = Add_Delta_YMD(1,1,1,0,-1,0); };
if ($@ =~ /not a valid date/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { ($year,$mm,$dd) = Add_Delta_YMD(1,1,1,-1,0,0); };
if ($@ =~ /not a valid date/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

($year,$mm,$dd) = (1997,2,26); ($y,$m,$d) = (0,-1,17);

if ((($year,$mm,$dd) = Add_Delta_YMD($year,$mm,$dd, $y,$m,$d)) &&
($year==1997) && ($mm==2) && ($dd==12))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Add_Delta_YMD($year,$mm,$dd, -$y,-$m,-$d)) &&
($year==1997) && ($mm==2) && ($dd==23))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

($year,$mm,$dd) = (1997,2,15); ($y,$m,$d) = (0,1,-17);

if ((($year,$mm,$dd) = Add_Delta_YMD($year,$mm,$dd, $y,$m,$d)) &&
($year==1997) && ($mm==2) && ($dd==26))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Add_Delta_YMD($year,$mm,$dd, -$y,-$m,-$d)) &&
($year==1997) && ($mm==2) && ($dd==12))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

($year,$mm,$dd) = (1997,2,15); ($y,$m,$d) = (1,-24,14);

if ((($year,$mm,$dd) = Add_Delta_YMD($year,$mm,$dd, $y,$m,$d)) &&
($year==1996) && ($mm==2) && ($dd==29))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Add_Delta_YMD($year,$mm,$dd, -$y,-$m,-$d)) &&
($year==1997) && ($mm==2) && ($dd==15))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Add_Delta_YMD(1998,1,30,0,1,0)) &&
($year==1998) && ($mm==3) && ($dd==2))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Add_Delta_YMD(2000,1,30,0,1,0)) &&
($year==2000) && ($mm==3) && ($dd==1))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($year,$mm,$dd) = Add_Delta_YMD(2000,1,31,0,3,0)) &&
($year==2000) && ($mm==5) && ($dd==1))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

