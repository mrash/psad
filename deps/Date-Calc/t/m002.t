#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc::Object qw(:all);

# ======================================================================
#   (Miscellaneous)
# ======================================================================

if ($] >= 5.004) { print "1..144\n"; } else { print "1..143\n"; }

$n = 1;

$date1 = Date::Calc->new(1964,1,3);
$date2 = Date::Calc->new(2001,7,8,15,39,57);

$temp1 = $date1->clone();

if (@$date1 == 4)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@$date1 == @$temp1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{$date1->[0]} == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{$date1->[0]} == @{$temp1->[0]})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (join("\n", @{$date1}[1..$#{$date1}]) eq join("\n", @{$temp1}[1..$#{$temp1}]))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (join("\n", @{$date1->[0]}) eq join("\n", @{$temp1->[0]}))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($date1 == $temp1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($date1 eq $temp1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$date1->delta_format( sub { return join '|', map sprintf("%02d",$_), $_[0]->date(), $_[0]->time(); } );

if (@{$date1->[0]} == @{$temp1->[0]} + 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$date1->date_format(  sub { return join ':', map sprintf("%02d",$_), $_[0]->date(), $_[0]->time(); } );

if (@{$date1->[0]} == @{$temp1->[0]} + 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$date1->language("Deutsch");

if (@{$date1->[0]} == @{$temp1->[0]} + 3)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp2 = Date::Calc->new();
$temp2->copy($date2);

if (@$date2 == 7)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@$date2 == @$temp2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{$date2->[0]} == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{$date2->[0]} == @{$temp2->[0]})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (join("\n", @{$date2}[1..$#{$date2}]) eq join("\n", @{$temp2}[1..$#{$temp2}]))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (join("\n", @{$date2->[0]}) eq join("\n", @{$temp2->[0]}))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($date2 == $temp2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($date2 eq $temp2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$date2->delta_format( sub { return join '#', map sprintf("%02d",$_), $_[0]->date(), $_[0]->time(); } );

if (@{$date2->[0]} == @{$temp2->[0]} + 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$date2->date_format(  sub { return join '=', map sprintf("%02d",$_), $_[0]->date(), $_[0]->time(); } );

if (@{$date2->[0]} == @{$temp2->[0]} + 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$date2->language("Dansk");

if (@{$date2->[0]} == @{$temp2->[0]} + 3)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

{
    $warn = '';
    local $^W = 1;
    local $SIG{'__WARN__'} = sub { $warn = join '', @_; };
    eval { $temp2 -= $temp1; };
}

unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($warn =~ /\bDate::Calc::_minus_equal_\(\): implicitly changed object type from date to delta vector\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ("$temp2" eq '+0+0+13701+15+39+57')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$diff = Date::Calc->new(1,0,0,13701,15,39,57);

if (@$diff == 7)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@$diff == @$temp2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{$diff->[0]} == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{$diff->[0]} == @{$temp2->[0]})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (join("\n", @{$diff}[1..$#{$diff}]) eq join("\n", @{$temp2}[1..$#{$temp2}]))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (join("\n", @{$diff->[0]}) eq join("\n", @{$temp2->[0]}))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($diff == $temp2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($diff eq $temp2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

{
    $warn = '';
    local $^W = 1;
    local $SIG{'__WARN__'} = sub { $warn = join '', @_; };
    eval { $diff += $temp1; };
}

unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($warn =~ /\bDate::Calc::_plus_equal_\(\): implicitly changed object type from delta vector to date\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

Date::Calc->date_format(1);

if ("$diff" eq '08-Jul-2001 15:39:57')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$diff = Date::Calc->new(1,37,6,5,15,39,57);

{
    $warn = '';
    local $^W = 1;
    local $SIG{'__WARN__'} = sub { $warn = join '', @_; };
    eval { $diff += $temp1; };
}

unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($warn =~ /\bDate::Calc::_plus_equal_\(\): implicitly changed object type from delta vector to date\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ("$diff" eq '08-Jul-2001 15:39:57')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

Date::Calc->accurate_mode(0);

$temp1 = $date1->clone();

if (@$date1 == 4)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@$date1 == @$temp1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{$date1->[0]} == 4)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{$date1->[0]} == @{$temp1->[0]})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (join("\n", @{$date1}[1..$#{$date1}]) eq join("\n", @{$temp1}[1..$#{$temp1}]))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (join("\n", @{$date1->[0]}) eq join("\n", @{$temp1->[0]}))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($date1 == $temp1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($date1 eq $temp1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp2 = Date::Calc->new();
$temp2->copy($date2);

if (@$date2 == 7)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@$date2 == @$temp2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{$date2->[0]} == 4)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{$date2->[0]} == @{$temp2->[0]})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (join("\n", @{$date2}[1..$#{$date2}]) eq join("\n", @{$temp2}[1..$#{$temp2}]))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (join("\n", @{$date2->[0]}) eq join("\n", @{$temp2->[0]}))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($date2 == $temp2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($date2 eq $temp2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

{
    $warn = '';
    local $^W = 1;
    local $SIG{'__WARN__'} = sub { $warn = join '', @_; };
    eval { $temp2 -= $temp1; };
}

unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($warn =~ /\bDate::Calc::_minus_equal_\(\): implicitly changed object type from date to delta vector\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ("$temp2" eq '37#06#05#15#39#57')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$diff = Date::Calc->new(1,37,6,5,15,39,57);

if ($diff == $temp2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($diff eq $temp2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

{
    $warn = '';
    local $^W = 1;
    local $SIG{'__WARN__'} = sub { $warn = join '', @_; };
    eval { $diff += $temp1; };
}

unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($warn =~ /\bDate::Calc::_plus_equal_\(\): implicitly changed object type from delta vector to date\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ("$diff" eq '08-Jul-2001 15:39:57')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$diff = Date::Calc->new(1,0,0,13701,15,39,57);

{
    $warn = '';
    local $^W = 1;
    local $SIG{'__WARN__'} = sub { $warn = join '', @_; };
    eval { $diff += $temp1; };
}

unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($warn =~ /\bDate::Calc::_plus_equal_\(\): implicitly changed object type from delta vector to date\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ("$diff" eq '08-Jul-2001 15:39:57')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$date1->time(11,4,27);

if ("$date1" eq '1964:01:03:11:04:27')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $temp1 = $date1 + $date2; };

if ($@ =~ /\bDate::Calc::_plus_\(\): can't add two dates\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp1 = $date1->clone();
$temp2 = $date2->clone();

eval { $temp1 += $temp2; };

if ($@ =~ /\bDate::Calc::_plus_equal_\(\): can't add two dates\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $temp1 = $date1 x $date2; };
if ($@ =~ /\bDate::Calc::OVERLOAD\(\): operator 'x' is unimplemented\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($] >= 5.004) # Perl 5.003 coughs at the overloaded 'x=' operator
{
    $temp1 = $date1->clone();
    $temp2 = $date2->clone();
    eval ' $temp1 x= $temp2; ';
    if ($@ =~ /\bDate::Calc::OVERLOAD\(\): operator 'x=' is unimplemented\b/)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

if ($date1 . $date2 eq '1964:01:03:11:04:272001=07=08=15=39=57')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $temp1 = $date1 * $date2; };
if ($@ =~ /\bDate::Calc::OVERLOAD\(\): operator '\*' is unimplemented\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp1 = $date1->clone();
$temp2 = $date2->clone();

eval { $temp1 *= $temp2; };
if ($@ =~ /\bDate::Calc::OVERLOAD\(\): operator '\*=' is unimplemented\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $temp1 = $date1 / $date2; };
if ($@ =~ /\bDate::Calc::OVERLOAD\(\): operator '\/' is unimplemented\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp1 = $date1->clone();
$temp2 = $date2->clone();

eval { $temp1 /= $temp2; };
if ($@ =~ /\bDate::Calc::OVERLOAD\(\): operator '\/=' is unimplemented\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $temp1 = $date1 % $date2; };
if ($@ =~ /\bDate::Calc::OVERLOAD\(\): operator '%' is unimplemented\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp1 = $date1->clone();
$temp2 = $date2->clone();

eval { $temp1 %= $temp2; };
if ($@ =~ /\bDate::Calc::OVERLOAD\(\): operator '%=' is unimplemented\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

Date::Calc->date_format(1);
Date::Calc->delta_format(1);

$date1 = Date::Calc->new([1999,12,6]);
$date2 = Date::Calc->new([2000,6,24]);

Date::Calc->accurate_mode(1);
$delta = $date2 - $date1;
if ("[$delta]" eq "[+0 +0 +201]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (abs($delta) == 201)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$delta = $date1 - $date2;
if ("[$delta]" eq "[+0 +0 -201]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (abs($delta) == -201)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

Date::Calc->accurate_mode(0);
$delta = $date2 - $date1;
if ("[$delta]" eq "[+1 -6 +18]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (abs($delta) == 6 * 31 + 18)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$delta = $date1 - $date2;
if ("[$delta]" eq "[-1 +6 -18]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (abs($delta) == -(6 * 31 + 18))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$date1 = Date::Calc->new([2000,1,1]);
$date2 = Date::Calc->new([2000,3,1]);

Date::Calc->accurate_mode(1);
$delta1 = $date1 - $date2;
if ("[$delta1]" eq "[+0 +0 -60]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (abs($delta1) == -60)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$delta1 = $date2 - $date1;
if ("[$delta1]" eq "[+0 +0 +60]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (abs($delta1) == 60)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

Date::Calc->accurate_mode(0);
$delta2 = $date1 - $date2;
if ("[$delta2]" eq "[+0 -2 +0]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (abs($delta2) == -62)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$delta2 = $date2 - $date1;
if ("[$delta2]" eq "[+0 +2 +0]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (abs($delta2) == 62)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp1 = $delta1 + [2000,4,1];
$temp2 = $delta2 + [2000,4,1];

if ("[$temp1]" eq "[31-May-2000]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ("[$temp2]" eq "[01-Jun-2000]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp1 = $delta1 + [1999,1,1];
$temp2 = $delta2 + [1999,1,1];

if ("[$temp1]" eq "[02-Mar-1999]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ("[$temp2]" eq "[01-Mar-1999]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp1 = $delta1 + [2000,12,29];
$temp2 = $delta2 + [2000,12,29];

if ("[$temp1]" eq "[27-Feb-2001]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ("[$temp2]" eq "[01-Mar-2001]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($date1->number(0) == 20000101)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date2->number(0) == 20000301)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($temp1->number(0) == 20010227)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($temp2->number(0) == 20010301)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$date1--;
if ("[$date1]" eq "[31-Dec-1999]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$date2--;
if ("[$date2]" eq "[29-Feb-2000]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$date1++;
if ("[$date1]" eq "[01-Jan-2000]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$date2++;
if ("[$date2]" eq "[01-Mar-2000]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$date1 -= 5;
if ("[$date1]" eq "[27-Dec-1999]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$date2 -= 5;
if ("[$date2]" eq "[25-Feb-2000]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$date1 += 15;
if ("[$date1]" eq "[11-Jan-2000]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$date2 += 15;
if ("[$date2]" eq "[11-Mar-2000]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$date1 += 366;
if ("[$date1]" eq "[11-Jan-2001]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$date2 += 365;
if ("[$date2]" eq "[11-Mar-2001]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp1 += [-1,0,+2];
if ("[$temp1]" eq "[29-Feb-2000]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp2 += [-1,0,-1];
if ("[$temp2]" eq "[29-Feb-2000]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval
{
    $temp1 -= [1,0,0];
};
if ($@ =~ /\bDate::Calc::_minus_equal_\(\): invalid date\/time\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp2 -= [1,1,0,0];
if ("[$temp2]" eq "[01-Mar-1999]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp1 = Date::Calc->new([2000,2,29]);
$temp2 = Date::Calc->new([2000,2,29]);

Date::Calc->accurate_mode(1);
$temp1 -= [1,1,0,0];
if ("[$temp1]" eq "[01-Mar-1999]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

Date::Calc->accurate_mode(0);
$temp2 -= [1,1,0,0];
if ("[$temp2]" eq "[01-Mar-1999]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$date1 = Date::Calc->new([2000,4,30]);
$date2 = Date::Calc->new([2001,5,1]);

$delta1 = Date::Calc->new([1,1,1,-29]);
$delta2 = Date::Calc->new([1,1,0,1]);

if (abs($delta1) == 374)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (abs($delta2) == 373)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

Date::Calc->accurate_mode(1);
$delta = $date2 - $date1;
if ("[$delta]" eq "[+0 +0 +366]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (abs($delta) == 366)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

Date::Calc->accurate_mode(0);
$delta = $date2 - $date1;
if ("[$delta]" eq "[+1 +1 -29]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (abs($delta) == 13 * 31 - 29)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp1 = $date1 + $delta1;
$temp2 = ($date1 += $delta2);

if ("[$temp1]" eq "[01-May-2001]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($temp1 == $date2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($temp1 eq $date2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($temp1 == $date1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($temp1 eq $date1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($temp2 == $date1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($temp2 eq $date1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp1 = $date1 - $delta1;
$temp2 = ($date2 -= $delta2);

if ("[$temp1]" eq "[30-Apr-2000]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ("[$date2]" eq "[30-Apr-2000]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ("[$temp2]" eq "[30-Apr-2000]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$date1 = Date::Calc->new([2000,1,1]);
$date2 = Date::Calc->new([2000,3,1]);

$temp1 = $date1--;
if ("[$temp1]" eq "[01-Jan-2000]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ("[$date1]" eq "[31-Dec-1999]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp2 = --$date2;
if ("[$temp2]" eq "[29-Feb-2000]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ("[$date2]" eq "[29-Feb-2000]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp2 = ++$date1;
if ("[$temp2]" eq "[01-Jan-2000]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ("[$date1]" eq "[01-Jan-2000]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp1 = $date2++;
if ("[$temp1]" eq "[29-Feb-2000]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ("[$date2]" eq "[01-Mar-2000]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

exit 0; # vital here: avoid "panic: POPSTACK" in Perl 5.005_03 (and before, probably)

__END__

