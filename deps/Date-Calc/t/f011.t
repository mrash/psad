#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

use Date::Calc qw( Date_to_Text );

# ======================================================================
#   $datestr = Date_to_Text($year,$mm,$dd);
# ======================================================================

print "1..2\n";

$n = 1;
if (Date_to_Text(1964,1,3) eq "Fri 3-Jan-1964") {print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Date_to_Text(1995,11,18) eq "Sat 18-Nov-1995") {print "ok $n\n";} else {print "not ok $n\n";}

__END__
