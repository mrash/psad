#!perl -w

BEGIN { eval { require bytes; }; }
use strict;

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

# ======================================================================
#   $delta->normalize();
# ======================================================================

use Date::Calc::Object;

Date::Calc->delta_format(1);
Date::Calc->accurate_mode(0);

print "1..20\n";

my $n = 1;

my $d1 = Date::Calc->new(2001,3,9,7,35,0);
my $d2 = Date::Calc->new(2002,3,9,19,30,5);
my $d3 = Date::Calc->new(2001,4,8,8,30,11);
my $d4 = Date::Calc->new(2002,3,9,23,0,1);

my $d5 = $d1 - $d2;
my $d6 = $d3 - $d4;

my $d7 = $d6 + $d5;
my $d8 = $d6 - $d5;

if ("[$d5]" eq "[-1 +0 +0 -11 -55 -5]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ("[$d6]" eq "[-1 +1 -1 -14 -29 -50]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ("[$d7]" eq "[-2 +1 -1 -25 -84 -55]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ("[$d8]" eq "[+0 +1 -1 -3 +26 -45]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($d7->number() == -715.022455)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($d8->number() == 29.212515)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

my $e7 = $d7->clone();
my $e8 = $d8->clone();

if ( $d7  ==  $e7  and
     $d7  eq  $e7  and
    "$d7" eq "$e7" and
     $d8  ==  $e8  and
     $d8  eq  $e8  and
    "$d8" eq "$e8")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

Date::Calc->accurate_mode(1);

my @time1 = $d7->normalize()->time();
my @date1 = $d7->date();

my @time2 = $d8->normalize()->time();
my @date2 = $d8->date();

if ("[" . join(' ', map(sprintf("%+d", $_), @date1, @time1)) . "]" eq "[-2 +1 -2 -2 -24 -55]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ("[" . join(' ', map(sprintf("%+d", $_), @date2, @time2)) . "]" eq "[+0 +1 -1 -2 -34 -45]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

Date::Calc->accurate_mode(0);

@time1 = $e7->normalize()->time();
@date1 = $e7->date();

@time2 = $e8->normalize()->time();
@date2 = $e8->date();

if ("[" . join(' ', map(sprintf("%+d", $_), @date1, @time1)) . "]" eq "[-1 -11 -2 -2 -24 -55]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ("[" . join(' ', map(sprintf("%+d", $_), @date2, @time2)) . "]" eq "[+1 -11 -1 -2 -34 -45]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$main::warn = '';

$SIG{'__WARN__'} = sub { $main::warn = join('', @_); };

{
    local $^W = 1;
    $d1->normalize();
}

if ($main::warn =~ /\bnormalizing a date is a no-op\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

my $delta;

Date::Calc->accurate_mode(1);

$delta = Date::Calc->new(1,4,40,400,40,400,4000);

$delta->normalize();

if ("[$delta]" eq "[+4 +40 +401 +23 +46 +40]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$delta = Date::Calc->new(1,-4,-40,-400,-40,-400,-4000);

$delta->normalize();

if ("[$delta]" eq "[-4 -40 -401 -23 -46 -40]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$delta = Date::Calc->new(1,+4,-40,+400,-40,+400,-4000);

$delta->normalize();

if ("[$delta]" eq "[+4 -40 +398 +13 +33 +20]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$delta = Date::Calc->new(1,-4,+40,-400,+40,-400,+4000);

$delta->normalize();

if ("[$delta]" eq "[-4 +40 -398 -13 -33 -20]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

Date::Calc->accurate_mode(0);

$delta = Date::Calc->new(1,4,40,400,40,400,4000);

$delta->normalize();

if ("[$delta]" eq "[+7 +4 +401 +23 +46 +40]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$delta = Date::Calc->new(1,-4,-40,-400,-40,-400,-4000);

$delta->normalize();

if ("[$delta]" eq "[-7 -4 -401 -23 -46 -40]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$delta = Date::Calc->new(1,+2,-40,+400,-40,+400,-4000);

$delta->normalize();

if ("[$delta]" eq "[-2 +8 +398 +13 +33 +20]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$delta = Date::Calc->new(1,-2,+40,-400,+40,-400,+4000);

$delta->normalize();

if ("[$delta]" eq "[+2 -8 -398 -13 -33 -20]")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

