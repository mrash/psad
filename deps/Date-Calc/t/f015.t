#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc qw( Weeks_in_Year );

# ======================================================================
#   $weeks = Weeks_in_Year($year);
# ======================================================================

print "1..4\n";

$n = 1;
if (Weeks_in_Year(1964) == 53) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Weeks_in_Year(1970) == 53) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Weeks_in_Year(1976) == 53) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Weeks_in_Year(1995) == 52) {print "ok $n\n";} else {print "not ok $n\n";}

__END__
