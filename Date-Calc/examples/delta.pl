#!perl -w

###############################################################################
##                                                                           ##
##    Copyright (c) 2000 - 2002 by Steffen Beyer.                            ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This program is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

use strict;
use Date::Calc qw(:all);

my $self = $0; $self =~ s!^.*/!!;

die "Usage: $self year1 month1 day1 year2 month2 day2\n" unless (@ARGV == 6);

my @date1;
my @date2;

if (Delta_Days(@ARGV) < 0)
{
    @date1 = (@ARGV)[3,4,5];
    @date2 = (@ARGV)[0,1,2];
}
else
{
    @date1 = (@ARGV)[0,1,2];
    @date2 = (@ARGV)[3,4,5];
}

print "\n", Date_to_Text(@date1), "\n", Date_to_Text(@date2), "\n";

$date1[2] = 1;
$date2[2] = 1;

while (Delta_Days(@date1,@date2) >= 0)
{
    print Calendar((@date1)[0,1]);
    @date1 = Add_Delta_YMD(@date1,0,1,0);
}

print "Difference: ", Delta_Business_Days(@ARGV), " Business Days.\n\n";

exit;

sub Delta_Business_Days
{
    my(@date1) = (@_)[0,1,2];
    my(@date2) = (@_)[3,4,5];
    my($minus,$result,$dow1,$dow2,$diff,$temp);

    $minus  = 0;
    $result = Delta_Days(@date1,@date2);
    if ($result != 0)
    {
        if ($result < 0)
        {
            $minus = 1;
            $result = -$result;
            $dow1 = Day_of_Week(@date2);
            $dow2 = Day_of_Week(@date1);
        }
        else
        {
            $dow1 = Day_of_Week(@date1);
            $dow2 = Day_of_Week(@date2);
        }
        $diff = $dow2 - $dow1;
        $temp = $result;
        if ($diff != 0)
        {
            if ($diff < 0)
            {
                $diff += 7;
            }
            $temp -= $diff;
            $dow1 += $diff;
            if ($dow1 > 6)
            {
                $result--;
                if ($dow1 > 7)
                {
                    $result--;
                }
            }
        }
        die "Assert failed" unless (($temp % 7) == 0);
        if ($temp != 0)
        {
            $temp /= 7;
            $result -= ($temp << 1);
        }
    }
    if ($minus) { return -$result; }
    else        { return  $result; }
}

__END__

