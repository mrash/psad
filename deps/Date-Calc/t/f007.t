#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc qw( Date_to_Days );

# ======================================================================
#   $days = Date_to_Days($year,$mm,$dd);
# ======================================================================

print "1..2\n";

$n = 1;
if (Date_to_Days(1964,1,3) == 716973)   {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Date_to_Days(1995,11,18) == 728615) {print "ok $n\n";} else {print "not ok $n\n";}

__END__

