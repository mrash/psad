#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc qw( Add_Delta_Days );

# ======================================================================
#   ($year,$mm,$dd) = Add_Delta_Days($year,$mm,$dd,$offset);
# ======================================================================

print "1..9\n";

$n = 1;
if ((($year,$mm,$dd) = Add_Delta_Days(1964,1,3,11642)) &&
($year==1995)&&($mm==11)&&($dd==18))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($year,$mm,$dd) = Add_Delta_Days(1995,11,18,-11642)) &&
($year==1964)&&($mm==1)&&($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($year,$mm,$dd) = Add_Delta_Days(1995,2,28,0)) &&
($year==1995)&&($mm==2)&&($dd==28))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($year,$mm,$dd) = Add_Delta_Days(1995,2,28,-1)) &&
($year==1995)&&($mm==2)&&($dd==27))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($year,$mm,$dd) = Add_Delta_Days(1995,2,28,1)) &&
($year==1995)&&($mm==3)&&($dd==1))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { ($year,$mm,$dd) = Add_Delta_Days(1995,2,29,-1); };
if ($@ =~ /not a valid date/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($year,$mm,$dd) = Add_Delta_Days(1,1,1,0)) &&
($year==1)&&($mm==1)&&($dd==1))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { ($year,$mm,$dd) = Add_Delta_Days(1,1,1,-1); };
if ($@ =~ /not a valid date/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { ($year,$mm,$dd) = Add_Delta_Days(0,1,1,0); };
if ($@ =~ /not a valid date/)
{print "ok $n\n";} else {print "not ok $n\n";}

__END__

