#!perl -w

###############################################################################
##                                                                           ##
##    Copyright (c) 2001, 2002 by Steffen Beyer.                             ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This program is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

use strict;

use Date::Calendar::Profiles qw( $Profiles );
use Date::Calendar;
use Date::Calc::Object qw(:ALL);

sub print_linear_calendar
{
    my(@start) = shift_date(\@_);
    my(@stop)  = shift_date(\@_);
    my($lang)  = shift;
    my($prof)  = shift;
    my($newl)  = Decode_Language($lang);
    my($cal,$start,$stop,$oldl,$oldf,@labels,$dow,$day);

    die "No such language '$lang'" unless ($newl);

    die "No such calendar profile '$prof'"
        unless (exists $Profiles->{$prof});

    $cal   = Date::Calendar->new( $Profiles->{$prof} );
    $start = Date::Calc->new(@start);
    $stop  = Date::Calc->new(@stop);

    $oldl = Language($newl);
    $oldf = Date::Calc->date_format(1);

    while ($start <= $stop)
    {
        @labels = $cal->labels($start);
        $dow = substr(shift(@labels),0,3);
        $day = $cal->is_full($start) ? "+" : $cal->is_half($start) ? "#" : "-";
        print "$dow $start $day ", join(", ", @labels), "\n";
        $start++;
    }

    Language($oldl);
    Date::Calc->date_format($oldf);
}

unless (@ARGV == 8)
{
    die "Usage: perl linearcal.pl YEAR1 MONTH1 DAY1 YEAR2 MONTH2 DAY2 LANGUAGE PROFILE\n";
}

print_linear_calendar( @ARGV );

__END__

