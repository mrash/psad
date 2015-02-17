#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc qw(:all);

# ======================================================================
#
#     ($Dy,$Dm,$Dd) = N_Delta_YMD($year1,$month1,$day1,
#                                 $year2,$month2,$day2);
#
#     ($D_y,$D_m,$D_d, $Dhh,$Dmm,$Dss) = N_Delta_YMDHMS($year1,$month1,$day1, $hour1,$min1,$sec1,
#                                                       $year2,$month2,$day2, $hour2,$min2,$sec2);
#
#     ($year,$month,$day) = Add_N_Delta_YMD($year,$month,$day, $Dy,$Dm,$Dd);
#
#     ($year,$month,$day, $hour,$min,$sec) = Add_N_Delta_YMDHMS($year,$month,$day, $hour,$min,$sec,
#                                                               $D_y, $D_m,  $D_d, $Dhh, $Dmm,$Dss);
#
# ======================================================================

$tests = (17 + 20) * 6 + 13;

print "1..$tests\n";

$n = 1;
eval { ($d_y, $d_m, $d_d) = N_Delta_YMD(0,2,28,1996,2,29); };    # 01
if ($@ =~ /not a valid date/)
{print "ok $n\n";} else {print "not ok $n\n$@\n";}
$n++;

eval { ($d_y, $d_m, $d_d) = N_Delta_YMD(1997,0,28,1996,2,29); }; # 02
if ($@ =~ /not a valid date/)
{print "ok $n\n";} else {print "not ok $n\n$@\n";}
$n++;

eval { ($d_y, $d_m, $d_d) = N_Delta_YMD(1997,2,0,1996,2,29); };  # 03
if ($@ =~ /not a valid date/)
{print "ok $n\n";} else {print "not ok $n\n$@\n";}
$n++;

eval { ($d_y, $d_m, $d_d) = N_Delta_YMD(1997,2,29,1996,2,29); }; # 04
if ($@ =~ /not a valid date/)
{print "ok $n\n";} else {print "not ok $n\n$@\n";}
$n++;

eval { ($d_y, $d_m, $d_d) = N_Delta_YMD(1996,2,29,0,2,28); };    # 05
if ($@ =~ /not a valid date/)
{print "ok $n\n";} else {print "not ok $n\n$@\n";}
$n++;

eval { ($d_y, $d_m, $d_d) = N_Delta_YMD(1996,2,29,1997,0,28); }; # 06
if ($@ =~ /not a valid date/)
{print "ok $n\n";} else {print "not ok $n\n$@\n";}
$n++;

eval { ($d_y, $d_m, $d_d) = N_Delta_YMD(1996,2,29,1997,2,0); };  # 07
if ($@ =~ /not a valid date/)
{print "ok $n\n";} else {print "not ok $n\n$@\n";}
$n++;

eval { ($d_y, $d_m, $d_d) = N_Delta_YMD(1996,2,29,1997,2,29); }; # 08
if ($@ =~ /not a valid date/)
{print "ok $n\n";} else {print "not ok $n\n$@\n";}
$n++;

eval { ($d_y, $d_m, $d_d) = N_Delta_YMD(1996,2,29,1997,2,28); }; # 09
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n$@\n";}
$n++;

eval { (@diff) = N_Delta_YMDHMS(1996,2,29,23,59,59,1997,2,29,0,0,1); }; # 10
if ($@ =~ /not a valid date/)
{print "ok $n\n";} else {print "not ok $n\n$@\n";}
$n++;

eval { (@diff) = N_Delta_YMDHMS(1997,2,29,23,59,59,1996,2,29,0,0,1); }; # 11
if ($@ =~ /not a valid date/)
{print "ok $n\n";} else {print "not ok $n\n$@\n";}
$n++;

eval { (@diff) = N_Delta_YMDHMS(1996,2,29,24,59,59,1997,2,28,0,0,1); }; # 12
if ($@ =~ /not a valid time/)
{print "ok $n\n";} else {print "not ok $n\n$@\n";}
$n++;

eval { (@diff) = N_Delta_YMDHMS(1996,2,29,23,59,59,1997,2,28,0,60,1); }; # 13
if ($@ =~ /not a valid time/)
{print "ok $n\n";} else {print "not ok $n\n$@\n";}
$n++;

&try( [2008, 1, 3], [2009, 8,21], [ 1, 7,18] ); # 01
&try( [2009, 8,26], [2011, 7,27], [ 1,11, 1] ); # 02
&try( [1964, 1, 3], [2009, 8,26], [45, 7,23] ); # 03
&try( [2009, 1,31], [2009, 2,28], [ 0, 0,28] ); # 04
&try( [2009, 2,28], [2009, 3,31], [ 0, 1, 3], [0, -1,  0] ); # 05
&try( [2008, 1,31], [2009, 1, 1], [ 0,11, 1] ); # 06
&try( [2008, 2,29], [2009, 2, 1], [ 0,11, 3], [0,-11, -1] ); # 07
&try( [2008, 3,31], [2009, 3, 1], [ 0,11, 1] ); # 08
&try( [1996, 2,29], [1997, 2,28], [ 1, 0, 0], [0,-11,-28] ); # 09
&try( [2009, 1,31], [2009, 3, 2], [ 0, 0,30] ); # 10
&try( [2009, 1,30], [2009, 3, 1], [ 0, 0,30] ); # 11
&try( [2008, 1,31], [2008, 3, 1], [ 0, 0,30] ); # 12
&try( [2008, 2,15], [2008, 3,15], [ 0, 0,29] ); # 13
&try( [2009, 2,15], [2009, 3,15], [ 0, 0,28] ); # 14
&try( [2007, 2, 1], [2008, 1,31], [ 0,11,30], [0,-11,-27] ); # 15
&try( [2007, 2,28], [2008, 1, 1], [ 0,10, 4], [0,-10, -1] ); # 16
&try( [2008, 1,31], [2009, 2, 1], [ 1, 0, 1] ); # 17

&try2( [2008, 1, 3,  0,  0,  0], [2009, 8,21, 23, 59, 59], [ 1, 7,18, 23, 59, 59] ); # 01
&try2( [2009, 8,26,  0,  0,  0], [2011, 7,27,  0,  0,  0], [ 1,11, 1,  0,  0,  0] ); # 02
&try2( [1964, 1, 3, 11,  7, 55], [2009, 8,26,  8, 39, 40], [45, 7,22, 21, 31, 45] ); # 03
&try2( [2009, 1,31, 23, 59, 59], [2009, 2,28,  0,  1,  0], [ 0, 0,27,  0,  1,  1] ); # 04
&try2( [2009, 2,28,  0,  0,  2], [2009, 3,31,  0,  0,  1], [ 0, 1, 2, 23, 59, 59], [0,0,-30,-23,-59,-59] );   # 05
&try2( [2009, 2,28,  0,  0,  2], [2009, 3, 1,  0,  0,  1], [ 0, 0, 0, 23, 59, 59] ); # 06
&try2( [2009, 1, 1,  0,  0,  2], [2009, 2, 1,  0,  0,  1], [ 0, 0,30, 23, 59, 59] ); # 07
&try2( [2008, 2,29,  0,  0,  2], [2009, 2,28,  0,  0,  1], [ 0,11,29, 23, 59, 59], [0,-11,-27,-23,-59,-59] ); # 08
&try2( [2008, 1,31, 23, 59, 58], [2009, 1, 1,  0,  0,  1], [ 0,11, 0,  0,  0,  3] ); # 09
&try2( [2008, 2,29,  0,  2,  0], [2009, 2, 1,  0,  0,  1], [ 0,11, 2, 23, 58,  1], [0,-11,0,-23,-58,-1] );    # 10
&try2( [2008, 3,31,  0,  2,  0], [2009, 3, 1,  0,  0,  1], [ 0,11, 0, 23, 58,  1] ); # 11
&try2( [1996, 2,29,  8, 11, 27], [1997, 2,28, 16, 45, 10], [ 1, 0, 0,  8, 33, 43], [0,-11,-28,-8,-33,-43] );  # 12
&try2( [2009, 1,31, 23, 59, 59], [2009, 3, 2,  0,  0,  1], [ 0, 0,29,  0,  0,  2] ); # 13
&try2( [2009, 1,30, 23, 59, 59], [2009, 3, 1,  0,  0,  1], [ 0, 0,29,  0,  0,  2] ); # 14
&try2( [2008, 1,31, 23, 59, 59], [2008, 3, 1,  0,  0,  1], [ 0, 0,29,  0,  0,  2] ); # 15
&try2( [2008, 2,15, 23, 59, 59], [2008, 3,15,  0,  0,  1], [ 0, 0,28,  0,  0,  2] ); # 16
&try2( [2009, 2,15,  0,  0,  0], [2009, 3,15,  0,  0,  0], [ 0, 0,28,  0,  0,  0] ); # 17
&try2( [2007, 2, 1,  0,  0,  1], [2008, 1,31,  0,  0,  0], [ 0,11,29, 23, 59, 59], [0,-11,-26,-23,-59,-59] ); # 18
&try2( [2007, 2,28,  0,  2,  0], [2008, 1, 1,  0,  0,  1], [ 0,10, 3, 23, 58,  1], [0,-10,0,-23,-58,-1] );    # 19
&try2( [2008, 1,31,  0,  0,  0], [2009, 2, 1,  0,  1,  0], [ 1, 0, 1,  0,  1,  0] ); # 20

sub try
{
    my($d1) = shift;
    my($d2) = shift;
    my($dd) = shift;
    my(@tt,@cc,@ee);

#print "&try( [", join(',',@$d1), "], [", join(',',@$d2), "], [", join(',',@$dd), "] );\n";
    @tt = N_Delta_YMD(@$d1,@$d2);
#print "diff: (", join(',',@tt), ")\n";
    @cc = Add_Delta_Days( Add_Delta_YM(@$d1,@tt[0,1]), $tt[2] );
    @ee = Add_N_Delta_YMD(@$d1,@tt);
#print "check: (", join(',',@cc), ")\n";
    if (($tt[0] == $dd->[0]) and
        ($tt[1] == $dd->[1]) and
        ($tt[2] == $dd->[2]))
    {print "ok $n\n";} else {print "not ok $n\n($tt[0],$tt[1],$tt[2]) != ($dd->[0],$dd->[1],$dd->[2])\n";} # 01
    $n++;
    if (($cc[0] == $d2->[0]) and
        ($cc[1] == $d2->[1]) and
        ($cc[2] == $d2->[2]))
    {print "ok $n\n";} else {print "not ok $n\n($cc[0],$cc[1],$cc[2]) != ($d2->[0],$d2->[1],$d2->[2])\n";} # 02
    $n++;
    if (($ee[0] == $d2->[0]) and
        ($ee[1] == $d2->[1]) and
        ($ee[2] == $d2->[2]))
    {print "ok $n\n";} else {print "not ok $n\n($ee[0],$ee[1],$ee[2]) != ($d2->[0],$d2->[1],$d2->[2])\n";} # 03
    $n++;
    if (@_ > 0) { $dd = shift; }
    else
    {
        $dd->[0] = -$dd->[0];
        $dd->[1] = -$dd->[1];
        $dd->[2] = -$dd->[2];
    }
    @tt = N_Delta_YMD(@$d2,@$d1);
#print "diff: (", join(',',@tt), ")\n";
#   @cc = Add_Delta_YM(@$d2,@tt[0,1]);
#print "check: (", join(',',@cc), ")\n";
#   @cc = Add_Delta_Days( @cc, $tt[2] );
    @cc = Add_Delta_Days( Add_Delta_YM(@$d2,@tt[0,1]), $tt[2] );
    @ee = Add_N_Delta_YMD(@$d2,@tt);
#print "check: (", join(',',@cc), ")\n";
    if (($tt[0] == $dd->[0]) and
        ($tt[1] == $dd->[1]) and
        ($tt[2] == $dd->[2]))
    {print "ok $n\n";} else {print "not ok $n\n($tt[0],$tt[1],$tt[2]) != ($dd->[0],$dd->[1],$dd->[2])\n";} # 04
    $n++;
    if (($cc[0] == $d1->[0]) and
        ($cc[1] == $d1->[1]) and
        ($cc[2] == $d1->[2]))
    {print "ok $n\n";} else {print "not ok $n\n($cc[0],$cc[1],$cc[2]) != ($d1->[0],$d1->[1],$d1->[2])\n";} # 05
    $n++;
    if (($ee[0] == $d1->[0]) and
        ($ee[1] == $d1->[1]) and
        ($ee[2] == $d1->[2]))
    {print "ok $n\n";} else {print "not ok $n\n($ee[0],$ee[1],$ee[2]) != ($d1->[0],$d1->[1],$d1->[2])\n";} # 06
    $n++;
}

sub try2
{
    my($d1) = shift;
    my($d2) = shift;
    my($dd) = shift;
    my(@tt,@cc,@ee);

    @tt = N_Delta_YMDHMS(@$d1,@$d2);
    @cc = Add_Delta_DHMS( Add_Delta_YM(@{$d1}[0..2],@tt[0,1]), @{$d1}[3..5], @tt[2..5] );
    @ee = Add_N_Delta_YMDHMS(@$d1,@tt);
    if (($tt[0] == $dd->[0]) and
        ($tt[1] == $dd->[1]) and
        ($tt[2] == $dd->[2]) and
        ($tt[3] == $dd->[3]) and
        ($tt[4] == $dd->[4]) and
        ($tt[5] == $dd->[5]))
    {print "ok $n\n";} else {print "not ok $n\n($tt[0],$tt[1],$tt[2],$tt[3],$tt[4],$tt[5]) != ($dd->[0],$dd->[1],$dd->[2],$dd->[3],$dd->[4],$dd->[5])\n";} # 01
    $n++;
    if (($cc[0] == $d2->[0]) and
        ($cc[1] == $d2->[1]) and
        ($cc[2] == $d2->[2]) and
        ($cc[3] == $d2->[3]) and
        ($cc[4] == $d2->[4]) and
        ($cc[5] == $d2->[5]))
    {print "ok $n\n";} else {print "not ok $n\n($cc[0],$cc[1],$cc[2],$cc[3],$cc[4],$cc[5]) != ($d2->[0],$d2->[1],$d2->[2],$d2->[3],$d2->[4],$d2->[5])\n";} # 02
    $n++;
    if (($ee[0] == $d2->[0]) and
        ($ee[1] == $d2->[1]) and
        ($ee[2] == $d2->[2]) and
        ($ee[3] == $d2->[3]) and
        ($ee[4] == $d2->[4]) and
        ($ee[5] == $d2->[5]))
    {print "ok $n\n";} else {print "not ok $n\n($ee[0],$ee[1],$ee[2],$ee[3],$ee[4],$ee[5]) != ($d2->[0],$d2->[1],$d2->[2],$d2->[3],$d2->[4],$d2->[5])\n";} # 03
    $n++;
    if (@_ > 0) { $dd = shift; }
    else
    {
        $dd->[0] = -$dd->[0];
        $dd->[1] = -$dd->[1];
        $dd->[2] = -$dd->[2];
        $dd->[3] = -$dd->[3];
        $dd->[4] = -$dd->[4];
        $dd->[5] = -$dd->[5];
    }
    @tt = N_Delta_YMDHMS(@$d2,@$d1);
    @cc = Add_Delta_DHMS( Add_Delta_YM(@{$d2}[0..2],@tt[0,1]), @{$d2}[3..5], @tt[2..5] );
    @ee = Add_N_Delta_YMDHMS(@$d2,@tt);
    if (($tt[0] == $dd->[0]) and
        ($tt[1] == $dd->[1]) and
        ($tt[2] == $dd->[2]) and
        ($tt[3] == $dd->[3]) and
        ($tt[4] == $dd->[4]) and
        ($tt[5] == $dd->[5]))
    {print "ok $n\n";} else {print "not ok $n\n($tt[0],$tt[1],$tt[2],$tt[3],$tt[4],$tt[5]) != ($dd->[0],$dd->[1],$dd->[2],$dd->[3],$dd->[4],$dd->[5])\n";} # 04
    $n++;
    if (($cc[0] == $d1->[0]) and
        ($cc[1] == $d1->[1]) and
        ($cc[2] == $d1->[2]) and
        ($cc[3] == $d1->[3]) and
        ($cc[4] == $d1->[4]) and
        ($cc[5] == $d1->[5]))
    {print "ok $n\n";} else {print "not ok $n\n($cc[0],$cc[1],$cc[2],$cc[3],$cc[4],$cc[5]) != ($d1->[0],$d1->[1],$d1->[2],$d1->[3],$d1->[4],$d1->[5])\n";} # 05
    $n++;
    if (($ee[0] == $d1->[0]) and
        ($ee[1] == $d1->[1]) and
        ($ee[2] == $d1->[2]) and
        ($ee[3] == $d1->[3]) and
        ($ee[4] == $d1->[4]) and
        ($ee[5] == $d1->[5]))
    {print "ok $n\n";} else {print "not ok $n\n($ee[0],$ee[1],$ee[2],$ee[3],$ee[4],$ee[5]) != ($d1->[0],$d1->[1],$d1->[2],$d1->[3],$d1->[4],$d1->[5])\n";} # 06
    $n++;
}

__END__

