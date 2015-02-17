#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc qw( Delta_Days );

# ======================================================================
#   $days = Delta_Days($year1,$mm1,$dd1,$year2,$mm2,$dd2);
# ======================================================================

print "1..5\n";

$n = 1;
if (Delta_Days(1964,1,3,1995,11,18) == 11642) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Delta_Days(1995,11,18,1964,1,3) == -11642) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Delta_Days(1964,1,3,1995,2,29); };
if ($@ =~ /not a valid date/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Delta_Days(1964,2,30,1995,11,18); };
if ($@ =~ /not a valid date/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Delta_Days(1964,2,30,1995,2,29); };
if ($@ =~ /not a valid date/)
{print "ok $n\n";} else {print "not ok $n\n";}

__END__

