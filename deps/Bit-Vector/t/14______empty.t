#!perl -w

use strict;
no strict "vars";

use Bit::Vector;

# ======================================================================
#   $vec->is_empty();
#   $vec->is_full();
# ======================================================================

print "1..40\n";

$n = 1;

$vec = Bit::Vector->new(5000);

if ($vec->is_empty())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!$vec->is_full())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$vec->Flip();

if (!$vec->is_empty())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($vec->is_full())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$vec->Complement($vec);

if ($vec->is_empty())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!$vec->is_full())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

&Empty(   0);
&Empty(   1);
&Empty(4999);
&Empty(4998);

$vec->Fill();

if (!$vec->is_empty())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($vec->is_full())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

&Full(   0);
&Full(   1);
&Full(4999);
&Full(4998);

exit;

sub Empty
{
    my($bit) = @_;

    $vec->bit_flip($bit);

    if (!$vec->is_empty())
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if (!$vec->is_full())
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    $vec->bit_flip($bit);

    if ($vec->is_empty())
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if (!$vec->is_full())
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

sub Full
{
    my($bit) = @_;

    $vec->bit_flip($bit);

    if (!$vec->is_empty())
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if (!$vec->is_full())
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    $vec->bit_flip($bit);

    if (!$vec->is_empty())
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if ($vec->is_full())
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

__END__

