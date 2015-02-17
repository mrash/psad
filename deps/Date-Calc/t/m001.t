#!perl -w

package Date::Calc::Subclass;

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc::Object qw(:all);

@ISA = qw(Date::Calc);

# Workaround for what appears to be a bug in Perl 5.003:

*Date::Calc::DESTROY = *Date::Calc::DESTROY = sub { } if ($] < 5.004);

# ======================================================================
#   $date = Date::Calc->new();
# ======================================================================

# Crappy Perl 5.6.0 has internal refcount problems below:

if ($] eq '5.006') { print "1..190\n"; }
else               { print "1..196\n"; }

#   Attempt to free unreferenced scalar at ./t/m001.t line 726 (#1)
#   (W internal) Perl went to decrement the reference count of a scalar to see if it
#   would go to 0, and discovered that it had already gone to 0 earlier,
#   and should have been freed, and in fact, probably was freed.  This
#   could indicate that SvREFCNT_dec() was called too many times, or that
#   SvREFCNT_inc() was called too few times, or that the SV was mortalized
#   when it shouldn't have been, or that memory has been corrupted.

$n = 1;

eval { $date = Date::Calc->new(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref $date)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref $date eq 'Date::Calc')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_valid(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_date(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_delta(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $date = Date::Calc->new(0); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref $date)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref $date eq 'Date::Calc')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_valid(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_date(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_delta(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $date = Date::Calc->new(1); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref $date)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref $date eq 'Date::Calc')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_valid(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_date(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_delta(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $date = Date::Calc::Subclass->new(2000,2,29); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref $date)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref $date eq 'Date::Calc::Subclass')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_valid(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_date(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_delta(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($date->year() == 2000)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date->month() == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date->day() == 29)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (defined $date->hours())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (defined $date->minutes())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (defined $date->seconds())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $date = Date::Calc->new(1900,2,29); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref $date)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref $date eq 'Date::Calc')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_valid(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_date(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_delta(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $day = $date->day(28); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_valid(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_date(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_delta(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (defined $day)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($day == 28)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($date->day() == $day)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date->month() == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date->year() == 1900)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (defined $date->hours())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (defined $date->minutes())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (defined $date->seconds())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $date = Date::Calc->new([2000,2,29]); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_valid(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_date(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_delta(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($date->day() == 29)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date->month() == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date->year() == 2000)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (defined $date->hours())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (defined $date->minutes())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (defined $date->seconds())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $other = $date->new(1964,1,3,11,5,4); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $other->is_valid(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $other->is_date(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $other->is_delta(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($other->day() == 3)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($other->month() == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($other->year() == 1964)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($other->hours() == 11)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($other->minutes() == 5)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($other->seconds() == 4)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_valid(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_date(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_delta(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($date->day() == 29)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date->month() == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date->year() == 2000)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (defined $date->hours())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (defined $date->minutes())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (defined $date->seconds())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $date = Date::Calc->new(0,2001,6,10,9,15,36); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_valid(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_date(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_delta(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($date->day() == 10)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date->month() == 6)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date->year() == 2001)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date->hours() == 9)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date->minutes() == 15)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date->seconds() == 36)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $date = Date::Calc->new(1,37,5,6); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_valid(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_date(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_delta(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($date->year() == 37)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date->month() == 5)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date->day() == 6)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (defined $date->hours())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (defined $date->minutes())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (defined $date->seconds())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $date = Date::Calc->new(1,0,0,13672,22,10,32); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_valid(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_date(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_delta(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($date->year() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date->month() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date->day() == 13672)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date->hours() == 22)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date->minutes() == 10)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date->seconds() == 32)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $date = Date::Calc->new([1,0,0,-13672,-22,-10,-32]); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_valid(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_date(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $flag = $date->is_delta(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $flag)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($flag == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($date->year() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date->month() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date->day() == -13672)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date->hours() == -22)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date->minutes() == -10)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date->seconds() == -32)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# Crappy Perl 5.6.0 has internal refcount problems here:

if ($] ne '5.006')
{
    eval { $date = Date::Calc->new(1,2); };
    if ($@ =~ /\bwrong number of arguments\b/)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    eval { $date = Date::Calc->new(1,2,3,4,5); };
    if ($@ =~ /\bwrong number of arguments\b/)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    eval { $date = Date::Calc->new(1,2,3,4,5,6,7,8); };
    if ($@ =~ /\bwrong number of arguments\b/)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    eval { $date = Date::Calc->new([1,2]); };
    if ($@ =~ /\bwrong number of arguments\b/)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    eval { $date = Date::Calc->new([1,2,3,4,5]); };
    if ($@ =~ /\bwrong number of arguments\b/)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    eval { $date = Date::Calc->new([1,2,3,4,5,6,7,8]); };
    if ($@ =~ /\bwrong number of arguments\b/)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

__END__

