#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc qw( Compress );

# ======================================================================
#   $date = Compress($yy,$mm,$dd);
# ======================================================================

print "1..6\n";

$n = 1;
if (Compress(64,1,3)     == 48163) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Compress(1964,1,3)   ==     0) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Compress(95,11,18)   == 13170) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Compress(1995,11,18) == 13170) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Compress(1995,2,28)  == 12892) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Compress(1995,2,29)  ==     0) {print "ok $n\n";} else {print "not ok $n\n";}

__END__

