#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc qw( leap_year );

# ======================================================================
#   $flag = leap_year($year);
# ======================================================================

print "1..4\n";

$n = 1;
if (leap_year(1900) == 0) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (leap_year(1964) == 1) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (leap_year(1998) == 0) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (leap_year(2000) == 1) {print "ok $n\n";} else {print "not ok $n\n";}

__END__

