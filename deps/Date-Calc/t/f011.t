#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc qw( Date_to_Text );

# ======================================================================
#   $datestr = Date_to_Text($year,$mm,$dd);
# ======================================================================

print "1..8\n";

$n = 1;
if (Date_to_Text(1964,1,3) eq "Fri 3-Jan-1964") {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Date_to_Text(1995,11,18) eq "Sat 18-Nov-1995") {print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (Date_to_Text(1964,1,3,0) eq "Fri 3-Jan-1964") {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Date_to_Text(1995,11,18,0) eq "Sat 18-Nov-1995") {print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (Date_to_Text(1964,1,3,1) eq "Fri 3-Jan-1964") {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Date_to_Text(1995,11,18,1) eq "Sat 18-Nov-1995") {print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (Date_to_Text(1964,1,3,11) eq "per 3-tam-1964") {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Date_to_Text(1995,11,18,11) eq "lau 18-mar-1995") {print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__
