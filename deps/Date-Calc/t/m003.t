#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc::Object qw(:all);

# ======================================================================
#   $date->date_format( sub { } );
#   $date->delta_format( sub { } );
# ======================================================================

print "1..6\n";

$n = 1;

$date1 = Date::Calc->new(1970,1,1);
$date2 = Date::Calc->new(2001,6,10,11,12,23);

$date1->delta_format( sub { return join '|', map sprintf("%02d",$_), $_[0]->date(), $_[0]->time(); } );
$date1->date_format(  sub { return join ':', map sprintf("%02d",$_), $_[0]->date(), $_[0]->time(); } );

$date2->date_format(  sub { return join '#', map sprintf("%02d",$_), $_[0]->date(), $_[0]->time(); } );
$date2->delta_format( sub { return join '=', map sprintf("%02d",$_), $_[0]->date(), $_[0]->time(); } );

if ("$date1" eq '1970:01:01')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ("$date2" eq '2001#06#10#11#12#23')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

{
    local($^W) = 0;
    $date2 -= $date1;
}

if ("$date2" eq '00=00=11483=11=12=23')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

{
    local($^W) = 0;
    $date2 += $date1;
}

if ("$date2" eq '2001#06#10#11#12#23')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

{
    local($^W) = 0;
    $date1 -= $date2;
}

if ("$date1" eq '00|00|-11483|-11|-12|-23')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

{
    local($^W) = 0;
    $date1 += $date2;
}

if ("$date1" eq '1970:01:01:00:00:00')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

