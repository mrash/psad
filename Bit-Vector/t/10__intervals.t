#!perl -w

use strict;
no strict "vars";

use Bit::Vector;

# ======================================================================
#   $set->Interval_Empty($lower,$upper);
#   $set->Interval_Fill($lower,$upper);
#   $set->Interval_Flip($lower,$upper);
#   $set->Interval_Reverse($lower,$upper);
#   ($min,$max) = $set->Interval_Scan_inc($start);
#   ($min,$max) = $set->Interval_Scan_dec($start);
# ======================================================================

print "1..4024\n";

$lim = 32768;

$n = 1;

$set = new Bit::Vector($lim);
$rev = new Bit::Vector($lim);
$rev->Primes();
$vec = $rev->Clone();
$primes = $rev->Norm();

if ($rev->equal($vec))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($set->Norm() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Min() > $lim)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Max() < -$lim)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set->Fill();

if ($set->Norm() == $lim)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Min() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Max() == $lim-1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set->Empty();

if ($set->Norm() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Min() > $lim)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Max() < -$lim)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set->Complement($set);

if ($set->Norm() == $lim)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Min() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Max() == $lim-1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set->Flip();

if ($set->Norm() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Min() > $lim)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Max() < -$lim)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

test_set_clr(1,14);      test_flip(1,14);      test_rev(1,14);
test_set_clr(1,30);      test_flip(1,30);      test_rev(1,30);
test_set_clr(1,62);      test_flip(1,62);      test_rev(1,62);
test_set_clr(1,126);     test_flip(1,126);     test_rev(1,126);
test_set_clr(1,254);     test_flip(1,254);     test_rev(1,254);
test_set_clr(1,$lim-2);  test_flip(1,$lim-2);  test_rev(1,$lim-2);

test_set_clr(0,14);      test_flip(0,14);      test_rev(0,14);
test_set_clr(0,30);      test_flip(0,30);      test_rev(0,30);
test_set_clr(0,62);      test_flip(0,62);      test_rev(0,62);
test_set_clr(0,126);     test_flip(0,126);     test_rev(0,126);
test_set_clr(0,254);     test_flip(0,254);     test_rev(0,254);
test_set_clr(0,$lim-2);  test_flip(0,$lim-2);  test_rev(0,$lim-2);

test_set_clr(1,15);      test_flip(1,15);      test_rev(1,15);
test_set_clr(1,31);      test_flip(1,31);      test_rev(1,31);
test_set_clr(1,63);      test_flip(1,63);      test_rev(1,63);
test_set_clr(1,127);     test_flip(1,127);     test_rev(1,127);
test_set_clr(1,255);     test_flip(1,255);     test_rev(1,255);
test_set_clr(1,$lim-1);  test_flip(1,$lim-1);  test_rev(1,$lim-1);

test_set_clr(0,15);      test_flip(0,15);      test_rev(0,15);
test_set_clr(0,31);      test_flip(0,31);      test_rev(0,31);
test_set_clr(0,63);      test_flip(0,63);      test_rev(0,63);
test_set_clr(0,127);     test_flip(0,127);     test_rev(0,127);
test_set_clr(0,255);     test_flip(0,255);     test_rev(0,255);
test_set_clr(0,$lim-1);  test_flip(0,$lim-1);  test_rev(0,$lim-1);

for ( $i = 0; $i < 256; $i++ )
{
    test_set_clr($i,$i); test_flip($i,$i);
}

eval { $set->Interval_Empty(-1,$lim-1); };
if ($@ =~ /[^:]+::[^:]+::Interval_Empty\(\): minimum index out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set->Interval_Fill(-1,$lim-1); };
if ($@ =~ /[^:]+::[^:]+::Interval_Fill\(\): minimum index out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set->Interval_Flip(-1,$lim-1); };
if ($@ =~ /[^:]+::[^:]+::Interval_Flip\(\): minimum index out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set->Interval_Reverse(-1,$lim-1); };
if ($@ =~ /[^:]+::[^:]+::Interval_Reverse\(\): minimum index out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set->Interval_Empty(0,-1); };
if ($@ =~ /[^:]+::[^:]+::Interval_Empty\(\): maximum index out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set->Interval_Fill(0,-1); };
if ($@ =~ /[^:]+::[^:]+::Interval_Fill\(\): maximum index out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set->Interval_Flip(0,-1); };
if ($@ =~ /[^:]+::[^:]+::Interval_Flip\(\): maximum index out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set->Interval_Reverse(0,-1); };
if ($@ =~ /[^:]+::[^:]+::Interval_Reverse\(\): maximum index out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set->Interval_Empty(1,0); };
if ($@ =~ /[^:]+::[^:]+::Interval_Empty\(\): minimum > maximum index/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set->Interval_Fill(1,0); };
if ($@ =~ /[^:]+::[^:]+::Interval_Fill\(\): minimum > maximum index/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set->Interval_Flip(1,0); };
if ($@ =~ /[^:]+::[^:]+::Interval_Flip\(\): minimum > maximum index/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set->Interval_Reverse(1,0); };
if ($@ =~ /[^:]+::[^:]+::Interval_Reverse\(\): minimum > maximum index/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { ($min,$max) = $set->Interval_Scan_inc($lim); };
if ($@ =~ /[^:]+::[^:]+::Interval_Scan_inc\(\): start index out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { ($min,$max) = $set->Interval_Scan_inc(-1); };
if ($@ =~ /[^:]+::[^:]+::Interval_Scan_inc\(\): start index out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { ($min,$max) = $set->Interval_Scan_dec($lim); };
if ($@ =~ /[^:]+::[^:]+::Interval_Scan_dec\(\): start index out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { ($min,$max) = $set->Interval_Scan_dec(-1); };
if ($@ =~ /[^:]+::[^:]+::Interval_Scan_dec\(\): start index out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

exit;

sub test_set_clr
{
    my($lower,$upper) = @_;
    my($span) = $upper - $lower + 1;

    $set->Interval_Fill($lower,$upper);
    if ($set->Norm() == $span)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if (($min,$max) = $set->Interval_Scan_inc(0))
    {print "ok $n\n";} else {print "not ok $n\n";
      $min = $set->Min(); $max = $set->Max(); }
    $n++;
    if ($min == $lower)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if ($max == $upper)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    $set->Interval_Empty($lower,$upper);
    if ($set->Norm() == 0)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if ($set->Min() > $lim)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if ($set->Max() < -$lim)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

sub test_flip
{
    my($lower,$upper) = @_;
    my($span) = $upper - $lower + 1;

    $set->Interval_Flip($lower,$upper);
    if ($set->Norm() == $span)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if (($min,$max) = $set->Interval_Scan_dec($set->Size()-1))
    {print "ok $n\n";} else {print "not ok $n\n";
      $min = $set->Min(); $max = $set->Max(); }
    $n++;
    if ($min == $lower)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if ($max == $upper)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    $set->Interval_Flip($lower,$upper);
    if ($set->Norm() == 0)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if ($set->Min() > $lim)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if ($set->Max() < -$lim)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

sub test_rev
{
    my($lower,$upper) = @_;

    $rev->Interval_Reverse($lower,$upper);
    if ($rev->Norm() == $primes)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    unless ($rev->equal($vec))
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    $rev->Interval_Reverse($lower,$upper);
    if ($rev->equal($vec))
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

__END__

