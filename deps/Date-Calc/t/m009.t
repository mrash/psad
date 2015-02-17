#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

eval { require Bit::Vector; };

if ($@)
{
    print "1..0\n";
    exit 0;
}

require Date::Calendar::Profiles;
require Date::Calendar;

# ======================================================================
#   $cal = Date::Calendar->new(PROFILE);
#   ($date,$rest) = $cal->add_delta_workdays(DATE,OFFSET);
#   $diff = $cal->delta_workdays(DATE1,DATE2,INC1,INC2);
# ======================================================================

print "1..24\n";

$n = 1;

$cal_DE_NW   = Date::Calendar->new( $Date::Calendar::Profiles::Profiles->{'DE-NW'} );
$cal_sdm_MUC = Date::Calendar->new( $Date::Calendar::Profiles::Profiles->{'sdm-MUC'} );

($date,$rest) = $cal_DE_NW->add_delta_workdays([2000,12,4],28);

if ($date == [2001,1,16])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($rest == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$diff = $cal_DE_NW->delta_workdays([2000,12,4],[2001,1,16],1,0);

if ($diff == 28)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

($date,$rest) = $cal_sdm_MUC->add_delta_workdays([2000,12,4],28);

if ($date == [2001,1,16])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($rest == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$diff = $cal_sdm_MUC->delta_workdays([2000,12,4],[2001,1,16],1,0);

if ($diff == 28)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

($date,$rest) = $cal_DE_NW->add_delta_workdays([2001,1,16],-28);

if ($date == [2000,12,4])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($rest == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

($date,$rest) = $cal_sdm_MUC->add_delta_workdays([2001,1,16],-28);

if ($date == [2000,12,4])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($rest == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$diff = $cal_DE_NW->delta_workdays([2001,1,16],[2000,12,4],1,0);

if ($diff == -28)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$diff = $cal_sdm_MUC->delta_workdays([2001,1,16],[2000,12,4],1,0);

if ($diff == -28)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$diff = $cal_DE_NW->delta_workdays([2001,1,16],[2000,12,4],0,1);

if ($diff == -28)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$diff = $cal_sdm_MUC->delta_workdays([2001,1,16],[2000,12,4],0,1);

if ($diff == -28)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$diff = $cal_DE_NW->delta_workdays([2001,1,16],[2000,12,4],0,0);

if ($diff == -27)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$diff = $cal_sdm_MUC->delta_workdays([2001,1,16],[2000,12,4],0,0);

if ($diff == -27)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$diff = $cal_DE_NW->delta_workdays([2001,1,16],[2000,12,4],1,1);

if ($diff == -29)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$diff = $cal_sdm_MUC->delta_workdays([2001,1,16],[2000,12,4],1,1);

if ($diff == -29)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

($date,$rest) = $cal_DE_NW->add_delta_workdays([2001,1,16],-29);

if ($date == [2000,12,1])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($rest == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

($date,$rest) = $cal_DE_NW->add_delta_workdays([2000,12,4],32);

if ($date == [2001,1,22])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($rest == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$date = 0;

eval { $date = $cal_DE_NW->add_delta_workdays([2000,12,4],32); };

unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date == [2001,1,22])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

