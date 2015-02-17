#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc qw( Week_of_Year Monday_of_Week );

# ======================================================================
#   ($week,$year) = Week_of_Year($year,$mm,$dd);
#   ($year,$mm,$dd) = Monday_of_Week($week,$year);
# ======================================================================

print "1..1\n";

$n = 1;
($year,$mm,$dd) = Monday_of_Week(Week_of_Year(1996,6,26));
if (($year==1996)&&($mm==6)&&($dd==24)) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__
