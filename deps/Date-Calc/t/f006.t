#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc qw( Compressed_to_Text );

# ======================================================================
#   $datestr = Compressed_to_Text($date);
# ======================================================================

print "1..20\n";

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
$n++;

if (Compressed_to_Text(48163,0) eq "03-Jan-64") {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Compressed_to_Text(    0,0) eq "??-???-??") {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Compressed_to_Text(13170,0) eq "18-Nov-95") {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Compressed_to_Text(12892,0) eq "28-Feb-95") {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Compressed_to_Text(12893,0) eq "??-???-??") {print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (Compressed_to_Text(48163,1) eq "03-Jan-64") {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Compressed_to_Text(    0,1) eq "??-???-??") {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Compressed_to_Text(13170,1) eq "18-Nov-95") {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Compressed_to_Text(12892,1) eq "28-Feb-95") {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Compressed_to_Text(12893,1) eq "??-???-??") {print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (Compressed_to_Text(48163,11) eq "03-tam-64") {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Compressed_to_Text(    0,11) eq "??-???-??") {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Compressed_to_Text(13170,11) eq "18-mar-95") {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Compressed_to_Text(12892,11) eq "28-hel-95") {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Compressed_to_Text(12893,11) eq "??-???-??") {print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

