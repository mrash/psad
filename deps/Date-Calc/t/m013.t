#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc::Object qw(:all);

# ======================================================================
#   (Miscellaneous)
# ======================================================================

print "1..66\n";

$n = 1;

Date::Calc->normalized_mode(1);

Date::Calc->date_format(1);
Date::Calc->delta_format(1);

$date1 = Date::Calc->new([1999,12,6]);
$date2 = Date::Calc->new([2000,6,24]);

$delta = $date2 - $date1;
if ("[$delta]" eq "[+0 +0 +201]")
{print "ok $n\n";} else {print "not ok $n ($delta)\n";}  # 01
$n++;
if (abs($delta) == 201)
{print "ok $n\n";} else {print "not ok $n\n";}           # 02
$n++;

$delta = $date1 - $date2;
if ("[$delta]" eq "[+0 +0 -201]")
{print "ok $n\n";} else {print "not ok $n ($delta)\n";}  # 03
$n++;
if (abs($delta) == -201)
{print "ok $n\n";} else {print "not ok $n\n";}           # 04
$n++;

Date::Calc->accurate_mode(0);

$delta = $date2 - $date1;
if ("[$delta]" eq "[+0 +6 +18]")
{print "ok $n\n";} else {print "not ok $n ($delta)\n";}  # 05
$n++;
if (abs($delta) == 6 * 31 + 18)
{print "ok $n\n";} else {print "not ok $n\n";}           # 06
$n++;

$delta = $date1 - $date2;
if ("[$delta]" eq "[+0 -6 -18]")
{print "ok $n\n";} else {print "not ok $n ($delta)\n";}  # 07
$n++;
if (abs($delta) == -(6 * 31 + 18))
{print "ok $n\n";} else {print "not ok $n\n";}           # 08
$n++;

$date1 = Date::Calc->new([2000,1,1]);
$date2 = Date::Calc->new([2000,3,1]);

Date::Calc->accurate_mode(1);

$delta1 = $date1 - $date2;
if ("[$delta1]" eq "[+0 +0 -60]")
{print "ok $n\n";} else {print "not ok $n ($delta1)\n";} # 09
$n++;
if (abs($delta1) == -60)
{print "ok $n\n";} else {print "not ok $n\n";}           # 10
$n++;

$delta1 = $date2 - $date1;
if ("[$delta1]" eq "[+0 +0 +60]")
{print "ok $n\n";} else {print "not ok $n ($delta1)\n";} # 11
$n++;
if (abs($delta1) == 60)
{print "ok $n\n";} else {print "not ok $n\n";}           # 12
$n++;

Date::Calc->accurate_mode(0);

$delta2 = $date1 - $date2;
if ("[$delta2]" eq "[+0 -2 +0]")
{print "ok $n\n";} else {print "not ok $n ($delta2)\n";} # 13
$n++;
if (abs($delta2) == -62)
{print "ok $n\n";} else {print "not ok $n\n";}           # 14
$n++;

$delta2 = $date2 - $date1;
if ("[$delta2]" eq "[+0 +2 +0]")
{print "ok $n\n";} else {print "not ok $n ($delta2)\n";} # 15
$n++;
if (abs($delta2) == 62)
{print "ok $n\n";} else {print "not ok $n\n";}           # 16
$n++;

$temp1 = $delta1 + [2000,4,1];
$temp2 = $delta2 + [2000,4,1];

if ("[$temp1]" eq "[31-May-2000]")
{print "ok $n\n";} else {print "not ok $n ($temp1)\n";}  # 17
$n++;

if ("[$temp2]" eq "[01-Jun-2000]")
{print "ok $n\n";} else {print "not ok $n ($temp2)\n";}  # 18
$n++;

$temp1 = $delta1 + [1999,1,1];
$temp2 = $delta2 + [1999,1,1];

if ("[$temp1]" eq "[02-Mar-1999]")
{print "ok $n\n";} else {print "not ok $n ($temp1)\n";}  # 19
$n++;

if ("[$temp2]" eq "[01-Mar-1999]")
{print "ok $n\n";} else {print "not ok $n ($temp2)\n";}  # 20
$n++;

$temp1 = $delta1 + [2000,12,29];
$temp2 = $delta2 + [2000,12,29];

if ("[$temp1]" eq "[27-Feb-2001]")
{print "ok $n\n";} else {print "not ok $n ($temp1)\n";}  # 21
$n++;

if ("[$temp2]" eq "[28-Feb-2001]")
{print "ok $n\n";} else {print "not ok $n ($temp2)\n";}  # 22
$n++;

if ($date1->number(0) == 20000101)
{print "ok $n\n";} else {print "not ok $n\n";}           # 23
$n++;
if ($date2->number(0) == 20000301)
{print "ok $n\n";} else {print "not ok $n\n";}           # 24
$n++;
if ($temp1->number(0) == 20010227)
{print "ok $n\n";} else {print "not ok $n\n";}           # 25
$n++;
if ($temp2->number(0) == 20010228)
{print "ok $n\n";} else {print "not ok $n\n";}           # 26
$n++;

$date1--;
if ("[$date1]" eq "[31-Dec-1999]")
{print "ok $n\n";} else {print "not ok $n ($date1)\n";}  # 27
$n++;

$date2--;
if ("[$date2]" eq "[29-Feb-2000]")
{print "ok $n\n";} else {print "not ok $n ($date2)\n";}  # 28
$n++;

$date1++;
if ("[$date1]" eq "[01-Jan-2000]")
{print "ok $n\n";} else {print "not ok $n ($date1)\n";}  # 29
$n++;

$date2++;
if ("[$date2]" eq "[01-Mar-2000]")
{print "ok $n\n";} else {print "not ok $n ($date2)\n";}  # 30
$n++;

$date1 -= 5;
if ("[$date1]" eq "[27-Dec-1999]")
{print "ok $n\n";} else {print "not ok $n ($date1)\n";}  # 31
$n++;

$date2 -= 5;
if ("[$date2]" eq "[25-Feb-2000]")
{print "ok $n\n";} else {print "not ok $n ($date2)\n";}  # 32
$n++;

$date1 += 15;
if ("[$date1]" eq "[11-Jan-2000]")
{print "ok $n\n";} else {print "not ok $n ($date1)\n";}  # 33
$n++;

$date2 += 15;
if ("[$date2]" eq "[11-Mar-2000]")
{print "ok $n\n";} else {print "not ok $n ($date2)\n";}  # 34
$n++;

$date1 += 366;
if ("[$date1]" eq "[11-Jan-2001]")
{print "ok $n\n";} else {print "not ok $n ($date1)\n";}  # 35
$n++;

$date2 += 365;
if ("[$date2]" eq "[11-Mar-2001]")
{print "ok $n\n";} else {print "not ok $n ($date2)\n";}  # 36
$n++;

$temp1 += [-1,0,+2];
if ("[$temp1]" eq "[29-Feb-2000]")
{print "ok $n\n";} else {print "not ok $n ($temp1)\n";}  # 37
$n++;

$temp2 += [-1,0,-1];
if ("[$temp2]" eq "[27-Feb-2000]")
{print "ok $n\n";} else {print "not ok $n ($temp2)\n";}  # 38
$n++;

eval
{
    $temp1 -= [1,0,0];
};
if ($@ =~ /\bDate::Calc::_minus_equal_\(\): invalid date\/time\b/)
{print "ok $n\n";} else {print "not ok $n\n";}           # 39
$n++;

$temp2 -= [1,1,0,0];
if ("[$temp2]" eq "[27-Feb-1999]")
{print "ok $n\n";} else {print "not ok $n ($temp2)\n";}  # 40
$n++;

$temp1 = Date::Calc->new([2000,2,29]);
$temp2 = Date::Calc->new([2000,2,29]);

Date::Calc->accurate_mode(1);

$temp1 -= [1,1,0,0];
if ("[$temp1]" eq "[01-Mar-1999]")
{print "ok $n\n";} else {print "not ok $n ($temp1)\n";}  # 41
$n++;

Date::Calc->accurate_mode(0);

$temp2 -= [1,1,0,0];
if ("[$temp2]" eq "[28-Feb-1999]")
{print "ok $n\n";} else {print "not ok $n ($temp2)\n";}  # 42
$n++;

$date1 = Date::Calc->new([2000,4,30]);
$date2 = Date::Calc->new([2001,5,1]);

$delta1 = Date::Calc->new([1,1,1,-29]);
$delta2 = Date::Calc->new([1,1,0,1]);

if (abs($delta1) == 374)
{print "ok $n\n";} else {print "not ok $n\n";}           # 43
$n++;

if (abs($delta2) == 373)
{print "ok $n\n";} else {print "not ok $n\n";}           # 44
$n++;

Date::Calc->accurate_mode(1);

$delta = $date2 - $date1;
if ("[$delta]" eq "[+0 +0 +366]")
{print "ok $n\n";} else {print "not ok $n ($delta)\n";}  # 45
$n++;
if (abs($delta) == 366)
{print "ok $n\n";} else {print "not ok $n\n";}           # 46
$n++;

Date::Calc->accurate_mode(0);

$delta = $date2 - $date1;
if ("[$delta]" eq "[+1 +0 +1]")
{print "ok $n\n";} else {print "not ok $n ($delta)\n";}  # 47
$n++;
if (abs($delta) == 373)
{print "ok $n\n";} else {print "not ok $n\n";}           # 48
$n++;

$temp1 = $date1 + $delta1;
$temp2 = ($date1 += $delta2);

if ("[$temp1]" eq "[01-May-2001]")
{print "ok $n\n";} else {print "not ok $n ($temp1)\n";}  # 49
$n++;

if ($temp1 == $date2)
{print "ok $n\n";} else {print "not ok $n ($temp1) != ($date2)\n";} # 50
$n++;
if ($temp1 eq $date2)
{print "ok $n\n";} else {print "not ok $n ($temp1) ne ($date2)\n";} # 51
$n++;

if ($temp1 == $date1)
{print "ok $n\n";} else {print "not ok $n ($temp1) != ($date1)\n";} # 52
$n++;
if ($temp1 eq $date1)
{print "ok $n\n";} else {print "not ok $n ($temp1) ne ($date1)\n";} # 53
$n++;

if ($temp2 == $date1)
{print "ok $n\n";} else {print "not ok $n ($temp2) != ($date1)\n";} # 54
$n++;
if ($temp2 eq $date1)
{print "ok $n\n";} else {print "not ok $n ($temp2) ne ($date1)\n";} # 55
$n++;

$temp1 = $date1 - $delta1;
$temp2 = ($date2 -= $delta2);

if ("[$temp1]" eq "[30-Apr-2000]")
{print "ok $n\n";} else {print "not ok $n ($temp1)\n";}  # 56
$n++;

if ("[$date2]" eq "[30-Apr-2000]")
{print "ok $n\n";} else {print "not ok $n ($date2)\n";}  # 57
$n++;

if ("[$temp2]" eq "[30-Apr-2000]")
{print "ok $n\n";} else {print "not ok $n ($temp2)\n";}  # 58
$n++;

$date1 = Date::Calc->new([2000,1,1]);
$date2 = Date::Calc->new([2000,3,1]);

$temp1 = $date1--;
if ("[$temp1]" eq "[01-Jan-2000]")
{print "ok $n\n";} else {print "not ok $n ($temp1)\n";}  # 59
$n++;
if ("[$date1]" eq "[31-Dec-1999]")
{print "ok $n\n";} else {print "not ok $n ($date1)\n";}  # 60
$n++;

$temp2 = --$date2;
if ("[$temp2]" eq "[29-Feb-2000]")
{print "ok $n\n";} else {print "not ok $n ($temp2)\n";}  # 61
$n++;
if ("[$date2]" eq "[29-Feb-2000]")
{print "ok $n\n";} else {print "not ok $n ($date2)\n";}  # 62
$n++;

$temp2 = ++$date1;
if ("[$temp2]" eq "[01-Jan-2000]")
{print "ok $n\n";} else {print "not ok $n ($temp2)\n";}  # 63
$n++;
if ("[$date1]" eq "[01-Jan-2000]")
{print "ok $n\n";} else {print "not ok $n ($date1)\n";}  # 64
$n++;

$temp1 = $date2++;
if ("[$temp1]" eq "[29-Feb-2000]")
{print "ok $n\n";} else {print "not ok $n ($temp1)\n";}  # 65
$n++;
if ("[$date2]" eq "[01-Mar-2000]")
{print "ok $n\n";} else {print "not ok $n ($date2)\n";}  # 66
$n++;

exit 0; # vital here: avoid "panic: POPSTACK" in Perl 5.005_03 (and before, probably)

__END__

