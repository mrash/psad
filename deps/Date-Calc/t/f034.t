#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc qw(:all);

# ======================================================================
#   ($year,$month,$day, $hour,$min,$sec) = Time_to_Date([time]);
#   $time = Date_to_Time($year,$month,$day, $hour,$min,$sec);
# ======================================================================
#   ($year,$month,$day, $hour,$min,$sec, $doy,$dow,$dst) = Gmtime([time]);
#   ($year,$month,$day, $hour,$min,$sec, $doy,$dow,$dst) = Localtime([time]);
#   $time = Mktime($year,$month,$day, $hour,$min,$sec);
# ======================================================================

#          Unix epoch is Thu  1-Jan-1970 00:00:00 (GMT)
# Classic MacOS epoch is Fri  1-Jan-1904 00:00:00 (local time)
#
#  Unix time overflow is Tue 19-Jan-2038 03:14:07 (time=0x7FFFFFFF)
# MacOS time overflow is Mon  6-Feb-2040 06:28:15 (time=0xFFFFFFFF)

if ($^O eq 'MacOS')
{
    $max_time  = 0xFFFFFFFF;
    $epoch_vec = [1904,1,1,0,0,0,1,5];
    $max_vec   = [2040,2,6,6,28,15,37,1];
    $match_vec = [1935,6,10,15,42,30,161,1];
}
else
{
    $max_time  = 0x7FFFFFFF;
    $epoch_vec = [1970,1,1,0,0,0,1,4];
    $max_vec   = [2038,1,19,3,14,7,19,2];
    $match_vec = [2001,6,10,15,42,30,161,7];
}

if (@ARGV and $ARGV[0])
{
    $all = 1;
    print "1..38\n";
}
else
{
    $all = 0;
    print "1..30\n";
}

$n = 1;

@date = Time_to_Date(0);

for ( $i = 0; $i < 6; $i++ )
{
    if ($date[$i] == $epoch_vec->[$i])
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

if (Date_to_Time(@date) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

@date = Time_to_Date($max_time);

for ( $i = 0; $i < 6; $i++ )
{
    if ($date[$i] == $max_vec->[$i])
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

if (Date_to_Time(@date) == $max_time)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$time = 992187750;

@date = Time_to_Date($time);

for ( $i = 0; $i < 6; $i++ )
{
    if ($date[$i] == $match_vec->[$i])
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

if (Date_to_Time(@date) == $time)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @date = Gmtime(); };

unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (Date_to_Days(@date[0..2]) > Date_to_Days(@{$match_vec}[0..2]))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @date = Time_to_Date(); };

unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (Date_to_Days(@date[0..2]) > Date_to_Days(@{$match_vec}[0..2]))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @date = Localtime(); };

unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (check_date(@date[0..2]) and check_time(@date[3..5]))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (Date_to_Days(@date[0..2]) > Date_to_Days(@{$match_vec}[0..2]))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $time = Mktime(@date[0..5]); };

unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($time > 992187750)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($all)
{
    eval
    {
        $secs = Mktime( $max_vec->[0],   $max_vec->[1],   $max_vec->[2],
                        $max_vec->[3],   $max_vec->[4],   $max_vec->[5]    );
    };
    unless ($@)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    if ( ($secs <= $max_time) and ($secs >= $max_time-86400) )
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    eval
    {
        $secs = Mktime( $max_vec->[0],   $max_vec->[1],   $max_vec->[2],
                        $max_vec->[3],   $max_vec->[4],   $max_vec->[5]+1  );
    };
    if ($@ =~ /\bDate::Calc::Mktime\(\): date out of range\b/)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    eval
    {
        $secs = Mktime( $max_vec->[0],   $max_vec->[1],   $max_vec->[2],
                        $max_vec->[3],   $max_vec->[4]+1, $max_vec->[5]    );
    };
    if ($@ =~ /\bDate::Calc::Mktime\(\): date out of range\b/)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    eval
    {
        $secs = Mktime( $max_vec->[0],   $max_vec->[1],   $max_vec->[2],
                        $max_vec->[3]+1, $max_vec->[4],   $max_vec->[5]    );
    };
    if ($@ =~ /\bDate::Calc::Mktime\(\): date out of range\b/)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    eval
    {
        $secs = Mktime( $max_vec->[0],   $max_vec->[1],   $max_vec->[2]+1,
                        $max_vec->[3],   $max_vec->[4],   $max_vec->[5]    );
    };
    if ($@ =~ /\bDate::Calc::Mktime\(\): date out of range\b/)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    eval
    {
        $secs = Mktime( $max_vec->[0],   $max_vec->[1]+1, $max_vec->[2],
                        $max_vec->[3],   $max_vec->[4],   $max_vec->[5]    );
    };
    if ($@ =~ /\bDate::Calc::Mktime\(\): date out of range\b/)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    eval
    {
        $secs = Mktime( $max_vec->[0]+1, $max_vec->[1],   $max_vec->[2],
                        $max_vec->[3],   $max_vec->[4],   $max_vec->[5]    );
    };
    if ($@ =~ /\bDate::Calc::Mktime\(\): date out of range\b/)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

__END__

