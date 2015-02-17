#!perl -w

use strict;
no strict "vars";

eval
{
    require Storable;
    *freeze  = \&Storable::freeze;
    *nfreeze = \&Storable::nfreeze;
    *thaw    = \&Storable::thaw;
    *dclone  = \&Storable::dclone;
};

if ($@ or $Storable::VERSION < 2.21)
{
    print "1..0 # skip module Storable 2.21 or newer not found (we have $Storable::VERSION)\n";
    exit 0;
}

require Bit::Vector;

# ======================================================================

# Determine the size of the nested data structure to be tested in the second part:

$length = 20;

# Create a set of numbers which will represent vector lengths to be tested:

$limit = 4096;

$set = Bit::Vector->new($limit);

$set->Primes();  # Initialize the set with prime numbers (pseudo-random)

$set->Bit_On(0); # Also test special cases with vectors of 0 and 1 bits length
$set->Bit_On(1);

for ( $i = 4; $i-1 < $limit; $i <<= 1 ) # Also test special cases of multiples of two and +/- 1
{
    $set->Bit_On($i-1) if ($i-1 < $limit);
    $set->Bit_On($i)   if ($i   < $limit);
    $set->Bit_On($i+1) if ($i+1 < $limit);
}

$tests = (24 * $set->Norm()) + (69 * $length) - 14; # Determine number of test cases

print "1..$tests\n";

$n = 1;

$start = 0;
while (($start < $set->Size()) &&
  (($min,$max) = $set->Interval_Scan_inc($start)))
{
    $start = $max + 2;
    for ( $bits = $min; $bits <= $max; $bits++ )
    {
        $vector = Bit::Vector->new($bits);
        $vector->Primes();

        $twin = thaw(freeze($vector));

        if (ref($twin) eq 'Bit::Vector')
        {print "ok $n\n";} else {print "not ok $n\n";} # 01
        $n++;
        if ($twin->Size() == $bits)
        {print "ok $n\n";} else {print "not ok $n\n";} # 02
        $n++;
        if (${$vector} != ${$twin})
        {print "ok $n\n";} else {print "not ok $n\n";} # 03
        $n++;
        if ($vector->equal($twin))
        {print "ok $n\n";} else {print "not ok $n\n";} # 04
        $n++;

        $clone = dclone($vector);

        if (ref($clone) eq 'Bit::Vector')
        {print "ok $n\n";} else {print "not ok $n\n";} # 05
        $n++;
        if ($clone->Size() == $bits)
        {print "ok $n\n";} else {print "not ok $n\n";} # 06
        $n++;
        if (${$vector} != ${$clone})
        {print "ok $n\n";} else {print "not ok $n\n";} # 07
        $n++;
        if ($vector->equal($clone))
        {print "ok $n\n";} else {print "not ok $n\n";} # 08
        $n++;

        if (${$twin} != ${$clone})
        {print "ok $n\n";} else {print "not ok $n\n";} # 09
        $n++;
        if ($twin->equal($clone))
        {print "ok $n\n";} else {print "not ok $n\n";} # 10
        $n++;

        if ($bits > 0)
        {
            $vector->Flip();

            $twin = thaw(nfreeze($vector));

            if (ref($twin) eq 'Bit::Vector')
            {print "ok $n\n";} else {print "not ok $n\n";} # 11
            $n++;
            if ($twin->Size() == $bits)
            {print "ok $n\n";} else {print "not ok $n\n";} # 12
            $n++;
            if (${$vector} != ${$twin})
            {print "ok $n\n";} else {print "not ok $n\n";} # 13
            $n++;
            if ($vector->equal($twin))
            {print "ok $n\n";} else {print "not ok $n\n";} # 14
            $n++;

            if (${$twin} != ${$clone})
            {print "ok $n\n";} else {print "not ok $n\n";} # 15
            $n++;
            unless ($twin->equal($clone))
            {print "ok $n\n";} else {print "not ok $n\n";} # 16
            $n++;
            $twin->Flip();
            if ($twin->equal($clone))
            {print "ok $n\n";} else {print "not ok $n\n";} # 17
            $n++;

            $clone = dclone($vector);

            if (ref($clone) eq 'Bit::Vector')
            {print "ok $n\n";} else {print "not ok $n\n";} # 18
            $n++;
            if ($clone->Size() == $bits)
            {print "ok $n\n";} else {print "not ok $n\n";} # 19
            $n++;
            if (${$vector} != ${$clone})
            {print "ok $n\n";} else {print "not ok $n\n";} # 20
            $n++;
            if ($vector->equal($clone))
            {print "ok $n\n";} else {print "not ok $n\n";} # 21
            $n++;

            if (${$twin} != ${$clone})
            {print "ok $n\n";} else {print "not ok $n\n";} # 22
            $n++;
            unless ($twin->equal($clone))
            {print "ok $n\n";} else {print "not ok $n\n";} # 23
            $n++;
            $twin->Flip();
            if ($twin->equal($clone))
            {print "ok $n\n";} else {print "not ok $n\n";} # 24
            $n++;
        }
    }
}

$i = 0;
$table = [];
$vector->Primes();
$start = $vector->Size() - 1;
while (($start >= 0) && ($i < $length) &&
    (($min,$max) = $vector->Interval_Scan_dec($start)))
{
    $start = $min - 2;
    for ( $bits = $max; ($bits >= $min) && ($i < $length); $bits-- )
    {
        $temp = Bit::Vector->new($bits);
        $temp->Primes();
        $temp->Flip() if ($i & 1);
        $table->[$i][0] = $temp;
        $table->[$i][1] = $temp->Clone();
        $table->[$i][2] = $temp;
        $i++;
    }
}

$twin = thaw(freeze( $table ));
$clone = dclone( $table );

for ( $i = 0; $i < $length; $i++ )
{
    if (ref($twin->[$i][0]) eq 'Bit::Vector')
    {print "ok $n\n";} else {print "not ok $n\n";} # 01
    $n++;
    if (ref($twin->[$i][1]) eq 'Bit::Vector')
    {print "ok $n\n";} else {print "not ok $n\n";} # 02
    $n++;
    if (ref($twin->[$i][2]) eq 'Bit::Vector')
    {print "ok $n\n";} else {print "not ok $n\n";} # 03
    $n++;

    if (ref($clone->[$i][0]) eq 'Bit::Vector')
    {print "ok $n\n";} else {print "not ok $n\n";} # 04
    $n++;
    if (ref($clone->[$i][1]) eq 'Bit::Vector')
    {print "ok $n\n";} else {print "not ok $n\n";} # 05
    $n++;
    if (ref($clone->[$i][2]) eq 'Bit::Vector')
    {print "ok $n\n";} else {print "not ok $n\n";} # 06
    $n++;

    #####################################################

    if ($twin->[$i][0]->Size() == $table->[$i][0]->Size())
    {print "ok $n\n";} else {print "not ok $n\n";} # 07
    $n++;
    if ($twin->[$i][1]->Size() == $table->[$i][1]->Size())
    {print "ok $n\n";} else {print "not ok $n\n";} # 08
    $n++;
    if ($twin->[$i][2]->Size() == $table->[$i][2]->Size())
    {print "ok $n\n";} else {print "not ok $n\n";} # 09
    $n++;

    if ($twin->[$i][0]->equal( $table->[$i][0] ))
    {print "ok $n\n";} else {print "not ok $n\n";} # 10
    $n++;
    if ($twin->[$i][1]->equal( $table->[$i][1] ))
    {print "ok $n\n";} else {print "not ok $n\n";} # 11
    $n++;
    if ($twin->[$i][2]->equal( $table->[$i][2] ))
    {print "ok $n\n";} else {print "not ok $n\n";} # 12
    $n++;

    if ($twin->[$i][0]->Size() == $twin->[$i][1]->Size())
    {print "ok $n\n";} else {print "not ok $n\n";} # 13
    $n++;
    if ($twin->[$i][1]->Size() == $twin->[$i][2]->Size())
    {print "ok $n\n";} else {print "not ok $n\n";} # 14
    $n++;
    if ($twin->[$i][2]->Size() == $twin->[$i][0]->Size())
    {print "ok $n\n";} else {print "not ok $n\n";} # 15
    $n++;

    if ($twin->[$i][0]->equal( $twin->[$i][1] ))
    {print "ok $n\n";} else {print "not ok $n\n";} # 16
    $n++;
    if ($twin->[$i][1]->equal( $twin->[$i][2] ))
    {print "ok $n\n";} else {print "not ok $n\n";} # 17
    $n++;
    if ($twin->[$i][2]->equal( $twin->[$i][0] ))
    {print "ok $n\n";} else {print "not ok $n\n";} # 18
    $n++;

    if (${$twin->[$i][0]} != ${$table->[$i][0]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 19
    $n++;
    if (${$twin->[$i][1]} != ${$table->[$i][0]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 20
    $n++;
    if (${$twin->[$i][2]} != ${$table->[$i][0]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 21
    $n++;
    if (${$twin->[$i][0]} != ${$table->[$i][1]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 22
    $n++;
    if (${$twin->[$i][1]} != ${$table->[$i][1]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 23
    $n++;
    if (${$twin->[$i][2]} != ${$table->[$i][1]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 24
    $n++;
    if (${$twin->[$i][0]} != ${$table->[$i][2]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 25
    $n++;
    if (${$twin->[$i][1]} != ${$table->[$i][2]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 26
    $n++;
    if (${$twin->[$i][2]} != ${$table->[$i][2]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 27
    $n++;

    if ($twin->[$i][0] ne $twin->[$i][1])
    {print "ok $n\n";} else {print "not ok $n\n";} # 28
    $n++;
    if ($twin->[$i][1] ne $twin->[$i][2])
    {print "ok $n\n";} else {print "not ok $n\n";} # 29
    $n++;
    if ($twin->[$i][2] eq $twin->[$i][0])
    {print "ok $n\n";} else {print "not ok $n\n";} # 30
    $n++;

    if (${$twin->[$i][0]} != ${$twin->[$i][1]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 31
    $n++;
    if (${$twin->[$i][1]} != ${$twin->[$i][2]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 32
    $n++;
    if (${$twin->[$i][2]} == ${$twin->[$i][0]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 33
    $n++;

    #####################################################

    if ($clone->[$i][0]->Size() == $table->[$i][0]->Size())
    {print "ok $n\n";} else {print "not ok $n\n";} # 34
    $n++;
    if ($clone->[$i][1]->Size() == $table->[$i][1]->Size())
    {print "ok $n\n";} else {print "not ok $n\n";} # 35
    $n++;
    if ($clone->[$i][2]->Size() == $table->[$i][2]->Size())
    {print "ok $n\n";} else {print "not ok $n\n";} # 36
    $n++;

    if ($clone->[$i][0]->equal( $table->[$i][0] ))
    {print "ok $n\n";} else {print "not ok $n\n";} # 37
    $n++;
    if ($clone->[$i][1]->equal( $table->[$i][1] ))
    {print "ok $n\n";} else {print "not ok $n\n";} # 38
    $n++;
    if ($clone->[$i][2]->equal( $table->[$i][2] ))
    {print "ok $n\n";} else {print "not ok $n\n";} # 39
    $n++;

    if ($clone->[$i][0]->Size() == $clone->[$i][1]->Size())
    {print "ok $n\n";} else {print "not ok $n\n";} # 40
    $n++;
    if ($clone->[$i][1]->Size() == $clone->[$i][2]->Size())
    {print "ok $n\n";} else {print "not ok $n\n";} # 41
    $n++;
    if ($clone->[$i][2]->Size() == $clone->[$i][0]->Size())
    {print "ok $n\n";} else {print "not ok $n\n";} # 42
    $n++;

    if ($clone->[$i][0]->equal( $clone->[$i][1] ))
    {print "ok $n\n";} else {print "not ok $n\n";} # 43
    $n++;
    if ($clone->[$i][1]->equal( $clone->[$i][2] ))
    {print "ok $n\n";} else {print "not ok $n\n";} # 44
    $n++;
    if ($clone->[$i][2]->equal( $clone->[$i][0] ))
    {print "ok $n\n";} else {print "not ok $n\n";} # 45
    $n++;

    if (${$clone->[$i][0]} != ${$table->[$i][0]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 46
    $n++;
    if (${$clone->[$i][1]} != ${$table->[$i][0]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 47
    $n++;
    if (${$clone->[$i][2]} != ${$table->[$i][0]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 48
    $n++;
    if (${$clone->[$i][0]} != ${$table->[$i][1]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 49
    $n++;
    if (${$clone->[$i][1]} != ${$table->[$i][1]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 50
    $n++;
    if (${$clone->[$i][2]} != ${$table->[$i][1]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 51
    $n++;
    if (${$clone->[$i][0]} != ${$table->[$i][2]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 52
    $n++;
    if (${$clone->[$i][1]} != ${$table->[$i][2]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 53
    $n++;
    if (${$clone->[$i][2]} != ${$table->[$i][2]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 54
    $n++;

    if ($clone->[$i][0] ne $clone->[$i][1])
    {print "ok $n\n";} else {print "not ok $n\n";} # 55
    $n++;
    if ($clone->[$i][1] ne $clone->[$i][2])
    {print "ok $n\n";} else {print "not ok $n\n";} # 56
    $n++;
    if ($clone->[$i][2] eq $clone->[$i][0])
    {print "ok $n\n";} else {print "not ok $n\n";} # 57
    $n++;

    if (${$clone->[$i][0]} != ${$clone->[$i][1]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 58
    $n++;
    if (${$clone->[$i][1]} != ${$clone->[$i][2]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 59
    $n++;
    if (${$clone->[$i][2]} == ${$clone->[$i][0]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 60
    $n++;

    #####################################################

    if (${$twin->[$i][0]} != ${$clone->[$i][0]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 61
    $n++;
    if (${$twin->[$i][1]} != ${$clone->[$i][0]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 62
    $n++;
    if (${$twin->[$i][2]} != ${$clone->[$i][0]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 63
    $n++;
    if (${$twin->[$i][0]} != ${$clone->[$i][1]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 64
    $n++;
    if (${$twin->[$i][1]} != ${$clone->[$i][1]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 65
    $n++;
    if (${$twin->[$i][2]} != ${$clone->[$i][1]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 66
    $n++;
    if (${$twin->[$i][0]} != ${$clone->[$i][2]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 67
    $n++;
    if (${$twin->[$i][1]} != ${$clone->[$i][2]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 68
    $n++;
    if (${$twin->[$i][2]} != ${$clone->[$i][2]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 69
    $n++;
}

__END__

