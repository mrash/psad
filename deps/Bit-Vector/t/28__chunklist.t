#!perl -w

use strict;
no strict "vars";

use Bit::Vector;

# ======================================================================
#   $value = $vector->Chunk_Read($bits,$offset);
#   $vector->Chunk_Store($bits,$offset,$value);
#   @values = $vector->Chunk_List_Read($bits);
#   $vector->Chunk_List_Store($bits,@values);
# ======================================================================

$limit = 1000;

$longbits = Bit::Vector::Long_Bits();

print "1..", 3*$longbits, "\n";

$set = Bit::Vector->new($limit+1);
$tst = $set->Shadow();

$set->Fill();
$set->Bit_Off(0);
$set->Bit_Off(1);
for ( $j = 4; $j <= $limit; $j += 2 ) { $set->Bit_Off($j); }
for ( $i = 3; ($j = $i * $i) <= $limit; $i += 2 )
{
    for ( ; $j <= $limit; $j += $i ) { $set->Bit_Off($j); }
}

$n = 1;

for ( $bits = 1; $bits <= $longbits; $bits++ )
{
    undef @primes;
    $tst->Empty();
    @primes = $set->Chunk_List_Read($bits);
    $tst->Chunk_List_Store($bits,@primes);
    if ($set->equal($tst))
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    undef @chunks;
    $tst->Empty();
    $ok = 1;
    for ( $i = 0, $offset = 0; $offset <= $limit; $i++, $offset += $bits )
    {
        $chunks[$i] = $set->Chunk_Read($bits,$offset);
        if ($primes[$i] != $chunks[$i]) { $ok = 0; }
    }
    if ($ok)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    for ( $i = 0; $i <= $#chunks; $i++ )
    {
        $tst->Chunk_Store($bits,$i*$bits,$chunks[$i]);
    }
    if ($set->equal($tst))
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

__END__

