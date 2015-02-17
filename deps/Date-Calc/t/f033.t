#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc qw( Standard_to_Business Business_to_Standard Add_Delta_Days );

# ======================================================================
#   ($year,$week,$dow) = Standard_to_Business($year,$month,$day);
#   ($year,$month,$day) = Business_to_Standard($year,$week,$dow);
# ======================================================================

$y1 = 1964;
$y2 = 2000;
$d1 = -8;
$d2 = +8;

print "1..", ($y2-$y1+1) * ($d2-$d1+1), "\n";

$n = 1;
for ( $year = $y1; $year <= $y2; $year++ )
{
    for ( $delta = $d1; $delta <= $d2; $delta++ )
    {
        @date = Add_Delta_Days($year,1,1,$delta);
        @business = Standard_to_Business(@date);
        @standard = Business_to_Standard(@business);
        if (($standard[0] == $date[0]) &&
            ($standard[1] == $date[1]) &&
            ($standard[2] == $date[2]))
        {print "ok $n\n";} else {print "not ok $n\n";}
        $n++;
    }
}

__END__

