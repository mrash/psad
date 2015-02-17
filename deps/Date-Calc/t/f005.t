#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc qw( check_compressed );

# ======================================================================
#   $flag = check_compressed($date);
# ======================================================================

print "1..5\n";

$n = 1;
if (check_compressed(48163) == 1) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (check_compressed(    0) == 0) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (check_compressed(13170) == 1) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (check_compressed(12892) == 1) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (check_compressed(12893) == 0) {print "ok $n\n";} else {print "not ok $n\n";}

__END__

