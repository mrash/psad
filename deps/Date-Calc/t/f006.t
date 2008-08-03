#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

use Date::Calc qw( Compressed_to_Text );

# ======================================================================
#   $datestr = Compressed_to_Text($date);
# ======================================================================

print "1..5\n";

$n = 1;
if (Compressed_to_Text(48163) eq "03-Jan-64") {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Compressed_to_Text(    0) eq "??-???-??") {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Compressed_to_Text(13170) eq "18-Nov-95") {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Compressed_to_Text(12892) eq "28-Feb-95") {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Compressed_to_Text(12893) eq "??-???-??") {print "ok $n\n";} else {print "not ok $n\n";}

__END__

