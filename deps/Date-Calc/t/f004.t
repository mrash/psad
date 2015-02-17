#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc qw( Uncompress );

# ======================================================================
#   ($cc,$yy,$mm,$dd) = Uncompress($date);
# ======================================================================

print "1..5\n";

$n = 1;
if ((($cc,$yy,$mm,$dd) = Uncompress(48163)) &&
($cc==2000)&&($yy==64)&&($mm==1)&&($dd==3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (($cc,$yy,$mm,$dd) = Uncompress(0))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($cc,$yy,$mm,$dd) = Uncompress(13170)) &&
($cc==1900)&&($yy==95)&&($mm==11)&&($dd==18))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ((($cc,$yy,$mm,$dd) = Uncompress(12892)) &&
($cc==1900)&&($yy==95)&&($mm==2)&&($dd==28))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (($cc,$yy,$mm,$dd) = Uncompress(12893))
{print "ok $n\n";} else {print "not ok $n\n";}

__END__

