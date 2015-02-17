#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc::Object qw(:all);

# ======================================================================
#   $date = Date::Calc->time2date([TIME]);
#   $time = $date->date2time();
# ======================================================================
#   $date = Date::Calc->gmtime([TIME]);
#   $date = Date::Calc->localtime([TIME]);
#   $time = $date->mktime();
# ======================================================================

#          Unix epoch is Thu  1-Jan-1970 00:00:00 (GMT)
# Classic MacOS epoch is Fri  1-Jan-1904 00:00:00 (local time)
#
#  Unix time overflow is Tue 19-Jan-2038 03:14:07 (time=0x7FFFFFFF)
# MacOS time overflow is Mon  6-Feb-2040 06:28:15 (time=0xFFFFFFFF)

if ($^O eq 'MacOS')
{
    $max_time  = 0xFFFFFFFF;
    $epoch_vec = [1904,1,1,0,0,0];
    $epoch_str = 'Friday, January 1st 1904 00:00:00';
    $max_vec   = [2040,2,6,6,28,15];
    $max_str   = 'Monday, February 6th 2040 06:28:15';
    $match_vec = [1935,6,10,15,42,30];
    $match_str = 'Monday, June 10th 1935 15:42:30';
}
else
{
    $max_time  = 0x7FFFFFFF;
    $epoch_vec = [1970,1,1,0,0,0];
    $epoch_str = 'Thursday, January 1st 1970 00:00:00';
    $max_vec   = [2038,1,19,3,14,7];
    $max_str   = 'Tuesday, January 19th 2038 03:14:07';
    $match_vec = [2001,6,10,15,42,30];
    $match_str = 'Sunday, June 10th 2001 15:42:30';
}

print "1..18\n";

$n = 1;

$date = Date::Calc->time2date(0);

if ($date eq $epoch_vec)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$date->date_format(3);

if ("$date" eq $epoch_str)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($date->date2time() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$date->time2date($max_time);

if ($date eq $max_vec)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ("$date" eq $max_str)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($date->date2time() == $max_time)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$time = 992187750;

$date->time2date($time);

if ($date eq $match_vec)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ("$date" eq $match_str)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($date->date2time() == $time)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $date->gmtime(); };

unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($date gt $match_vec)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $date->time2date(); };

unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($date gt $match_vec)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $date->localtime(); };

unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($date->is_valid())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($date gt $match_vec)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $time = $date->mktime(); };

unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($time > 992187750)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

