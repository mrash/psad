#!perl -w

use strict;
no strict "vars";

use Bit::Vector;

# ======================================================================
#   $vector->increment();
#   $vector->decrement();
# ======================================================================

print "1..5296\n";

$n = 1;

$bits = 10;

$limit = (1 << $bits) - 1;

$k = 0;

$test_vector = bitvector($bits,$k);

for ( $i = 0; $i <= $limit; $i++ )
{
    if ($k++ == $limit) { $k = 0; }

    $ref_carry = ($test_vector->Norm() == $bits);

    $test_carry = $test_vector->increment();

    if ($test_carry == $ref_carry)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    $ref_vector = bitvector($bits,$k);

    if ($test_vector->equal($ref_vector))
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

$k = $limit;

$test_vector = bitvector($bits,$k);

for ( $i = $limit; $i >= 0; $i-- )
{
    if ($k-- == 0) { $k = $limit; }

    $ref_carry = ($test_vector->Norm() == 0);

    $test_carry = $test_vector->decrement();

    if ($test_carry == $ref_carry)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    $ref_vector = bitvector($bits,$k);

    if ($test_vector->equal($ref_vector))
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

$bits = 2000;

$upper =  150;
$lower = -150;

$k = $lower;

$test_vector = bitvector($bits,$k);

while (++$k <= $upper)
{
    $ref_carry = ($test_vector->Norm() == $bits);

    $test_carry = $test_vector->increment();

    if ($test_carry == $ref_carry)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    $ref_vector = bitvector($bits,$k);

    if ($test_vector->equal($ref_vector))
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

$k = $upper;

$test_vector = bitvector($bits,$k);

while (--$k >= $lower)
{
    $ref_carry = ($test_vector->Norm() == 0);

    $test_carry = $test_vector->decrement();

    if ($test_carry == $ref_carry)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    $ref_vector = bitvector($bits,$k);

    if ($test_vector->equal($ref_vector))
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

exit;

sub bitvector
{
    my($bits,$value) = @_;
    my($vector,$bit);

    $vector = Bit::Vector->new($bits);

    if ($value < 0)
    {
        $value = -1 - $value;
        $vector->Fill();
    }

    $bit = 0;
    while ($value)
    {
        if ($value & 1) { $vector->bit_flip($bit); }
        $value >>= 1;
        $bit++;
    }

    return($vector);
}

__END__

