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
no strict "vars";

use Date::Calc qw(:all);
use Date::Calendar;

# How many days in advance:

$Days = 90; # = roughly 3 months

$Anniversaries =
{
    "Spouse 1971"             =>  "30.12.",
    "Wedding Day 1992"        =>  "01.09.",
    "Valentine's Day"         =>  "14.02.",
    "Son Richard 1996"        =>  "11.05.",
    "Daughter Irene 1994"     =>  "17.01.",
    "Mom 1939"                =>  "19.08.",
    "Dad 1937"                =>  "23.04.",
    "Brother Timothy 1969"    =>  "24.04.",
    "Sister Catherine 1973"   =>  "21.10.",
    "Cousin Paul 1970"        =>  "16.10.",
    "Aunt Marjorie 1944"      =>  "09.06.",
    "Uncle George 1941"       =>  "02.08.",
    "Friend Alexander 1968"   =>  "12.06.",
};

$calendar = Date::Calendar->new( $Anniversaries );

@date = Today();

for ( $delta = 0; $delta <= $Days; $delta++ )
{
    if ($calendar->is_full(@date) and
        ((@labels = $calendar->labels(@date)) > 1))
    {
        $dow = shift(@labels);
        foreach $name (sort @labels)
        {
            $age = '';
            if ($name =~ s!\s*(\d+)\s*$!!)
            {
                $age = $date[0] - $1;
            }
            printf
            (
                "%+5d days :  %3.3s %2d-%3.3s-%d  (%2s)  %s\n",
                $delta,
                $dow,
                $date[2],
                Month_to_Text($date[1]),
                $date[0],
                $age,
                $name
            );
        }
    }
    @date = Add_Delta_Days(@date,1) if ($delta < $Days);
}

__END__

