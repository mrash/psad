#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

eval { require Bit::Vector; };

if ($@)
{
    print "1..0\n";
    exit 0;
}

require Date::Calendar;
require Date::Calendar::Profiles;

Date::Calendar::Profiles->import('$Profiles');

# ======================================================================
#   $cal  = Date::Calendar->new($prof);
#   $year = $cal->year($year);
#   $year = Date::Calendar::Year->new($year,$prof); # (implicitly)
# ======================================================================

print "1..", scalar(keys %{$Profiles}), "\n";

$n = 1;

$year = 2000;

foreach $key (keys %{$Profiles})
{
    eval
    {
        $cal  = Date::Calendar->new( $Profiles->{$key} );
        $year = $cal->year( $year );
    };
    unless ($@)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

__END__

