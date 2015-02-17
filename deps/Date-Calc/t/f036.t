#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc::Object qw(:aux);

# ======================================================================
#   $year                          = shift_year(\@_);
#   ($year,$mm,$dd)                = shift_date(\@_);
#   ($hrs,$min,$sec)               = shift_time(\@_);
#   ($year,$mm,$dd,$hrs,$min,$sec) = shift_datetime(\@_);
# ======================================================================

print "1..81\n";

$n = 1;

@today_and_now = Date::Calc::Today_and_Now();
@today         = @today_and_now[0..2];
@now           = @today_and_now[3..5];
$this_year     = $today_and_now[0];

$shortdate     = Date::Calc->new(@today);
$longdate      = Date::Calc->new(@today_and_now);

# ======================================================================
#   $year = shift_year(\@_);
# ======================================================================

$year = 0;
$year = shift_year([$this_year]);
if ($year == $this_year)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $year = shift_year($this_year); };
if ($@ =~ /\binternal error - parameter is not an ARRAY ref\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$year = 0;
$year = shift_year([[@today]]);
if ($year == $this_year)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $year = shift_year([[$this_year]]); };
if ($@ =~ /\bwrong number of elements in date constant\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$year = 0;
$year = shift_year([$shortdate]);
if ($year == $this_year)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$year = 0;
$year = shift_year([$longdate]);
if ($year == $this_year)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$year = 0;
$year = shift_year([$shortdate,1]);
if ($year == $this_year)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$year = 0;
$year = shift_year([$longdate,1]);
if ($year == $this_year)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $year = shift_year([[]]); };
if ($@ =~ /\bwrong number of elements in date constant\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $year = shift_year([]); };
if ($@ =~ /\bnot enough input parameters for a year\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $year = shift_year([[1,2,3,4]]); };
if ($@ =~ /\bwrong number of elements in date constant\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $year = shift_year([[@today,0]]); };
if ($@ =~ /\bwrong number of elements in date constant\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $year = shift_year([[@today_and_now]]); };
if ($@ =~ /\bwrong number of elements in date constant\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$year = 0;
$year = shift_year([$this_year,1,2,3,4]);
if ($year == $this_year)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $year = shift_year([{}]); };
if ($@ =~ /\binput parameter is neither ARRAY ref nor object\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# ======================================================================
#   ($year,$mm,$dd) = shift_date(\@_);
# ======================================================================

@list = ();
@list = shift_date([@today]);
if (@list    == @today    and
    $list[0] == $today[0] and
    $list[1] == $today[1] and
    $list[2] == $today[2])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_date(@today); };
if ($@ =~ /\binternal error - parameter is not an ARRAY ref\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

@list = ();
@list = shift_date([[@today]]);
if (@list    == @today    and
    $list[0] == $today[0] and
    $list[1] == $today[1] and
    $list[2] == $today[2])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_date([[]]); };
if ($@ =~ /\bwrong number of elements in date constant\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_date([[$today[0]]]); };
if ($@ =~ /\bwrong number of elements in date constant\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_date([[@today[0,1]]]); };
if ($@ =~ /\bwrong number of elements in date constant\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_date([[@today,0]]); };
if ($@ =~ /\bwrong number of elements in date constant\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_date([[@today,0,0]]); };
if ($@ =~ /\bwrong number of elements in date constant\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_date([[@today_and_now]]); };
if ($@ =~ /\bwrong number of elements in date constant\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

@list = ();
@list = shift_date([$shortdate]);
if (@list    == @today    and
    $list[0] == $today[0] and
    $list[1] == $today[1] and
    $list[2] == $today[2])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

@list = ();
@list = shift_date([$longdate]);
if (@list    == @today    and
    $list[0] == $today[0] and
    $list[1] == $today[1] and
    $list[2] == $today[2])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

@list = ();
@list = shift_date([$shortdate,1]);
if (@list    == @today    and
    $list[0] == $today[0] and
    $list[1] == $today[1] and
    $list[2] == $today[2])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

@list = ();
@list = shift_date([$longdate,1]);
if (@list    == @today    and
    $list[0] == $today[0] and
    $list[1] == $today[1] and
    $list[2] == $today[2])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_date([]); };
if ($@ =~ /\bnot enough input parameters for a date\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_date([$today[0]]); };
if ($@ =~ /\bnot enough input parameters for a date\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_date([@today[0,1]]); };
if ($@ =~ /\bnot enough input parameters for a date\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

@list = ();
@list = shift_date([@today,0]);
if (@list    == @today    and
    $list[0] == $today[0] and
    $list[1] == $today[1] and
    $list[2] == $today[2])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

@list = ();
@list = shift_date([@today,0,0]);
if (@list    == @today    and
    $list[0] == $today[0] and
    $list[1] == $today[1] and
    $list[2] == $today[2])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

@list = ();
@list = shift_date([@today_and_now]);
if (@list    == @today    and
    $list[0] == $today[0] and
    $list[1] == $today[1] and
    $list[2] == $today[2])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_date([{}]); };
if ($@ =~ /\binput parameter is neither ARRAY ref nor object\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# ======================================================================
#   ($hrs,$min,$sec) = shift_time(\@_);
# ======================================================================

@list = ();
@list = shift_time([@now]);
if (@list    == @now    and
    $list[0] == $now[0] and
    $list[1] == $now[1] and
    $list[2] == $now[2])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_time(@now); };
if ($@ =~ /\binternal error - parameter is not an ARRAY ref\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

@list = ();
@list = shift_time([[@now]]);
if (@list    == @now    and
    $list[0] == $now[0] and
    $list[1] == $now[1] and
    $list[2] == $now[2])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_time([[]]); };
if ($@ =~ /\bwrong number of elements in time constant\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_time([[$now[0]]]); };
if ($@ =~ /\bwrong number of elements in time constant\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_time([[@now[0,1]]]); };
if ($@ =~ /\bwrong number of elements in time constant\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_time([[@now,0]]); };
if ($@ =~ /\bwrong number of elements in time constant\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_time([[@now,0,0]]); };
if ($@ =~ /\bwrong number of elements in time constant\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_time([[@now,@today]]); };
if ($@ =~ /\bwrong number of elements in time constant\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

@list = ();
@list = shift_time([$shortdate]);
if (@list    == @now    and
    $list[0] == 0 and
    $list[1] == 0 and
    $list[2] == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

@list = ();
@list = shift_time([$longdate]);
if (@list    == @now    and
    $list[0] == $now[0] and
    $list[1] == $now[1] and
    $list[2] == $now[2])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

@list = ();
@list = shift_time([$shortdate,1]);
if (@list    == @now    and
    $list[0] == 0 and
    $list[1] == 0 and
    $list[2] == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

@list = ();
@list = shift_time([$longdate,1]);
if (@list    == @now    and
    $list[0] == $now[0] and
    $list[1] == $now[1] and
    $list[2] == $now[2])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_time([]); };
if ($@ =~ /\bnot enough input parameters for time values\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_time([$now[0]]); };
if ($@ =~ /\bnot enough input parameters for time values\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_time([@now[0,1]]); };
if ($@ =~ /\bnot enough input parameters for time values\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

@list = ();
@list = shift_time([@now,0]);
if (@list    == @now    and
    $list[0] == $now[0] and
    $list[1] == $now[1] and
    $list[2] == $now[2])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

@list = ();
@list = shift_time([@now,0,0]);
if (@list    == @now    and
    $list[0] == $now[0] and
    $list[1] == $now[1] and
    $list[2] == $now[2])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

@list = ();
@list = shift_time([@now,@today]);
if (@list    == @now    and
    $list[0] == $now[0] and
    $list[1] == $now[1] and
    $list[2] == $now[2])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_time([{}]); };
if ($@ =~ /\binput parameter is neither ARRAY ref nor object\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# ======================================================================
#   ($year,$mm,$dd,$hrs,$min,$sec) = shift_datetime(\@_);
# ======================================================================

@list = ();
@list = shift_datetime([@today_and_now]);
if (@list    == @today_and_now    and
    $list[0] == $today_and_now[0] and
    $list[1] == $today_and_now[1] and
    $list[2] == $today_and_now[2] and
    $list[3] == $today_and_now[3] and
    $list[4] == $today_and_now[4] and
    $list[5] == $today_and_now[5])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_datetime(@today_and_now); };
if ($@ =~ /\binternal error - parameter is not an ARRAY ref\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

@list = ();
@list = shift_datetime([[@today_and_now]]);
if (@list    == @today_and_now    and
    $list[0] == $today_and_now[0] and
    $list[1] == $today_and_now[1] and
    $list[2] == $today_and_now[2] and
    $list[3] == $today_and_now[3] and
    $list[4] == $today_and_now[4] and
    $list[5] == $today_and_now[5])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_datetime([[]]); };
if ($@ =~ /\bwrong number of elements in date-time constant\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_datetime([[$today_and_now[0]]]); };
if ($@ =~ /\bwrong number of elements in date-time constant\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_datetime([[@today_and_now[0,1]]]); };
if ($@ =~ /\bwrong number of elements in date-time constant\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_datetime([[@today_and_now[0..2]]]); };
if ($@ =~ /\bwrong number of elements in date-time constant\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_datetime([[@today_and_now[0..3]]]); };
if ($@ =~ /\bwrong number of elements in date-time constant\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_datetime([[@today_and_now[0..4]]]); };
if ($@ =~ /\bwrong number of elements in date-time constant\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_datetime([[@today_and_now,0]]); };
if ($@ =~ /\bwrong number of elements in date-time constant\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_datetime([[@today_and_now,0,0]]); };
if ($@ =~ /\bwrong number of elements in date-time constant\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_datetime([[@today_and_now,0,0,0]]); };
if ($@ =~ /\bwrong number of elements in date-time constant\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

@list = ();
@list = shift_datetime([$shortdate]);
if (@list    == @today_and_now    and
    $list[0] == $today_and_now[0] and
    $list[1] == $today_and_now[1] and
    $list[2] == $today_and_now[2] and
    $list[3] == 0 and
    $list[4] == 0 and
    $list[5] == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

@list = ();
@list = shift_datetime([$longdate]);
if (@list    == @today_and_now    and
    $list[0] == $today_and_now[0] and
    $list[1] == $today_and_now[1] and
    $list[2] == $today_and_now[2] and
    $list[3] == $today_and_now[3] and
    $list[4] == $today_and_now[4] and
    $list[5] == $today_and_now[5])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

@list = ();
@list = shift_datetime([$shortdate,1]);
if (@list    == @today_and_now    and
    $list[0] == $today_and_now[0] and
    $list[1] == $today_and_now[1] and
    $list[2] == $today_and_now[2] and
    $list[3] == 0 and
    $list[4] == 0 and
    $list[5] == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

@list = ();
@list = shift_datetime([$longdate,1]);
if (@list    == @today_and_now    and
    $list[0] == $today_and_now[0] and
    $list[1] == $today_and_now[1] and
    $list[2] == $today_and_now[2] and
    $list[3] == $today_and_now[3] and
    $list[4] == $today_and_now[4] and
    $list[5] == $today_and_now[5])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_datetime([]); };
if ($@ =~ /\bnot enough input parameters for a date and time\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_datetime([$today_and_now[0]]); };
if ($@ =~ /\bnot enough input parameters for a date and time\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_datetime([@today_and_now[0,1]]); };
if ($@ =~ /\bnot enough input parameters for a date and time\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_datetime([@today_and_now[0..2]]); };
if ($@ =~ /\bnot enough input parameters for a date and time\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_datetime([@today_and_now[0..3]]); };
if ($@ =~ /\bnot enough input parameters for a date and time\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_datetime([@today_and_now[0..4]]); };
if ($@ =~ /\bnot enough input parameters for a date and time\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

@list = ();
@list = shift_datetime([@today_and_now,0]);
if (@list    == @today_and_now    and
    $list[0] == $today_and_now[0] and
    $list[1] == $today_and_now[1] and
    $list[2] == $today_and_now[2] and
    $list[3] == $today_and_now[3] and
    $list[4] == $today_and_now[4] and
    $list[5] == $today_and_now[5])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

@list = ();
@list = shift_datetime([@today_and_now,0,0]);
if (@list    == @today_and_now    and
    $list[0] == $today_and_now[0] and
    $list[1] == $today_and_now[1] and
    $list[2] == $today_and_now[2] and
    $list[3] == $today_and_now[3] and
    $list[4] == $today_and_now[4] and
    $list[5] == $today_and_now[5])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

@list = ();
@list = shift_datetime([@today_and_now,0,0,0]);
if (@list    == @today_and_now    and
    $list[0] == $today_and_now[0] and
    $list[1] == $today_and_now[1] and
    $list[2] == $today_and_now[2] and
    $list[3] == $today_and_now[3] and
    $list[4] == $today_and_now[4] and
    $list[5] == $today_and_now[5])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { @list = shift_datetime([{}]); };
if ($@ =~ /\binput parameter is neither ARRAY ref nor object\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

