#!perl -w

use strict;
no strict "vars";

$file = $0;
#$file =~ s!^.*[/\\:]+!!;
$file =~ s!\.+[^.]*$!!;
$file .= '.tmp';

eval
{
    require Storable;
    *store    = \&Storable::store;
    *nstore   = \&Storable::nstore;
    *retrieve = \&Storable::retrieve;
};

if ($@ or $Storable::VERSION < 2.21)
{
    print "1..0 # skip module Storable 2.21 or newer not found (we have $Storable::VERSION)\n";
    exit 0;
}

unless (open(TMP, ">$file") and print(TMP "$file\n") and close(TMP) and unlink($file))
{
    print "1..0 # skip cannot write temporary file <$file>: $!\n";
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

$tests = (11 * $set->Norm()) + (30 * $length) - 7; # Determine number of test cases

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

        store($vector,$file);
        $twin = retrieve($file);
        unlink($file);

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

        if ($bits > 0)
        {
            $vector->Flip();

            nstore($vector,$file);
            $clone = retrieve($file);
            unlink($file);

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
            unless ($twin->equal($clone))
            {print "ok $n\n";} else {print "not ok $n\n";} # 10
            $n++;
            $twin->Flip();
            if ($twin->equal($clone))
            {print "ok $n\n";} else {print "not ok $n\n";} # 11
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

nstore($table,$file);
$twin = retrieve($file);
unlink($file);

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

    if ($twin->[$i][0]->Size() == $table->[$i][0]->Size())
    {print "ok $n\n";} else {print "not ok $n\n";} # 04
    $n++;
    if ($twin->[$i][1]->Size() == $table->[$i][1]->Size())
    {print "ok $n\n";} else {print "not ok $n\n";} # 05
    $n++;
    if ($twin->[$i][2]->Size() == $table->[$i][2]->Size())
    {print "ok $n\n";} else {print "not ok $n\n";} # 06
    $n++;

    if ($twin->[$i][0]->equal( $table->[$i][0] ))
    {print "ok $n\n";} else {print "not ok $n\n";} # 07
    $n++;
    if ($twin->[$i][1]->equal( $table->[$i][1] ))
    {print "ok $n\n";} else {print "not ok $n\n";} # 08
    $n++;
    if ($twin->[$i][2]->equal( $table->[$i][2] ))
    {print "ok $n\n";} else {print "not ok $n\n";} # 09
    $n++;

    if ($twin->[$i][0]->Size() == $twin->[$i][1]->Size())
    {print "ok $n\n";} else {print "not ok $n\n";} # 10
    $n++;
    if ($twin->[$i][1]->Size() == $twin->[$i][2]->Size())
    {print "ok $n\n";} else {print "not ok $n\n";} # 11
    $n++;
    if ($twin->[$i][2]->Size() == $twin->[$i][0]->Size())
    {print "ok $n\n";} else {print "not ok $n\n";} # 12
    $n++;

    if ($twin->[$i][0]->equal( $twin->[$i][1] ))
    {print "ok $n\n";} else {print "not ok $n\n";} # 13
    $n++;
    if ($twin->[$i][1]->equal( $twin->[$i][2] ))
    {print "ok $n\n";} else {print "not ok $n\n";} # 14
    $n++;
    if ($twin->[$i][2]->equal( $twin->[$i][0] ))
    {print "ok $n\n";} else {print "not ok $n\n";} # 15
    $n++;

    if (${$twin->[$i][0]} != ${$table->[$i][0]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 16
    $n++;
    if (${$twin->[$i][1]} != ${$table->[$i][0]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 17
    $n++;
    if (${$twin->[$i][2]} != ${$table->[$i][0]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 18
    $n++;
    if (${$twin->[$i][0]} != ${$table->[$i][1]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 19
    $n++;
    if (${$twin->[$i][1]} != ${$table->[$i][1]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 20
    $n++;
    if (${$twin->[$i][2]} != ${$table->[$i][1]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 21
    $n++;
    if (${$twin->[$i][0]} != ${$table->[$i][2]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 22
    $n++;
    if (${$twin->[$i][1]} != ${$table->[$i][2]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 23
    $n++;
    if (${$twin->[$i][2]} != ${$table->[$i][2]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 24
    $n++;

    if ($twin->[$i][0] ne $twin->[$i][1])
    {print "ok $n\n";} else {print "not ok $n\n";} # 25
    $n++;
    if ($twin->[$i][1] ne $twin->[$i][2])
    {print "ok $n\n";} else {print "not ok $n\n";} # 26
    $n++;
    if ($twin->[$i][2] eq $twin->[$i][0])
    {print "ok $n\n";} else {print "not ok $n\n";} # 27
    $n++;

    if (${$twin->[$i][0]} != ${$twin->[$i][1]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 28
    $n++;
    if (${$twin->[$i][1]} != ${$twin->[$i][2]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 29
    $n++;
    if (${$twin->[$i][2]} == ${$twin->[$i][0]})
    {print "ok $n\n";} else {print "not ok $n\n";} # 30
    $n++;
}

__END__

