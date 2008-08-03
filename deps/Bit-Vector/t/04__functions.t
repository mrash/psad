#!perl -w

use strict;
no strict "vars";

use Bit::Vector;

# ======================================================================
#   $set->Norm();
#   $set->Min();
#   $set->Max();
# ======================================================================

print "1..21\n";

$lim = 997;

$set = new Bit::Vector($lim);

$norm = $set->Norm();
$min = $set->Min();
$max = $set->Max();

$n = 1;
if ($norm == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($min > $lim)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($max < -$lim)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set->Fill();
$norm = $set->Norm();
$min = $set->Min();
$max = $set->Max();

if ($norm == $lim)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($min == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($max == $lim-1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set->Empty();
$set->Bit_On(0);
$set->Bit_On($lim-1);
$norm = $set->Norm();
$min = $set->Min();
$max = $set->Max();

if ($norm == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($min == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($max == $lim-1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set->Empty();
$set->Bit_On(0);
$norm = $set->Norm();
$min = $set->Min();
$max = $set->Max();

if ($norm == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($min == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($max == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set->Empty();
$set->Bit_On($lim-1);
$norm = $set->Norm();
$min = $set->Min();
$max = $set->Max();

if ($norm == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($min == $lim-1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($max == $lim-1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set->Empty();
$set->Bit_On(1);
$set->Bit_On($lim-2);
$norm = $set->Norm();
$min = $set->Min();
$max = $set->Max();

if ($norm == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($min == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($max == $lim-2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set->Empty();
$set->Bit_On(int($lim/2));
$norm = $set->Norm();
$min = $set->Min();
$max = $set->Max();

if ($norm == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($min == int($lim/2))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($max == int($lim/2))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

