#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

use Date::Calc qw( check_date );

# ======================================================================
#   $flag = check_date($year,$mm,$dd);
# ======================================================================

print "1..11\n";

$n = 1;
if (check_date(1,1,1) == 1) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (check_date(0,1,1) == 0) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (check_date(1,0,1) == 0) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (check_date(1,1,0) == 0) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (check_date(-1,1,1) == 0) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (check_date(1,-1,1) == 0) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (check_date(1,1,-1) == 0) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (check_date(1964,1,3)  == 1) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (check_date(1964,2,29) == 1) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (check_date(1995,2,28) == 1) {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (check_date(1995,2,29) == 0) {print "ok $n\n";} else {print "not ok $n\n";}

__END__

