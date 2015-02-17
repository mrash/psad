#!perl -w

use strict;

use Bit::Vector;

# ======================================================================
#   $value = $vector->Chunk_Read($bits,$offset);
#   $vector->Chunk_Store($bits,$offset,$value);
#   @values = $vector->Chunk_List_Read($bits);
#   $vector->Chunk_List_Store($bits,@values);
# ======================================================================

my $limit = 1013; # Prime number in order to avoid trivial cases

my $longbits = Bit::Vector::Long_Bits();

print "1..", 12*$longbits, "\n";

my($set,$tst,$bits,$ok,$i,$offset);
my(@primes,@chunks);

my(@vec) = Bit::Vector->new($limit,5);

$vec[0]->Primes(); # Make sure all chunks here are unique, i.e., mutually different (as far as possible)
$vec[3]->Fill();
$tst = $vec[4];

my $k = 0;
while ($k < $limit)
{
    $vec[1]->Bit_On($k++);
    $vec[2]->Bit_On($k++) if ($k < $limit);
}

my $n = 1;
for ( $k = 0; $k < 4; $k++ )
{
    $set = $vec[$k];
    for ( $bits = 1; $bits <= $longbits; $bits++ )
    {
        undef @primes;
        $tst->Empty();
        @primes = $set->Chunk_List_Read($bits);
        $tst->Chunk_List_Store($bits,@primes);
        if ($set->equal($tst))
        {print "ok $n\n";} else {print "not ok $n\n";print "k = $k\nvect. bits: $limit bits\nchunk size: $bits bits\nset=".$set->to_Hex()."\ntst=".$tst->to_Hex()."\n";$tst->Xor($tst,$set);print "xor=".$tst->to_Hex()."\n";Dump(\@primes,'primes',$bits);}
        $n++;
        undef @chunks;
        $tst->Empty();
        $ok = 1;
        for ( $i = 0, $offset = 0; $offset < $limit; $i++, $offset += $bits )
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
        {print "ok $n\n";} else {print "not ok $n\n";print "k = $k\nvect. bits: $limit bits\nchunk size: $bits bits\nset=".$set->to_Hex()."\ntst=".$tst->to_Hex()."\n";$tst->Xor($tst,$set);print "xor=".$tst->to_Hex()."\n";Dump(\@chunks,'chunks',$bits);}
        $n++;
    }
}

sub Dump
{
    my($list,$name,$size) = @_;
    my($i,$len);
    my($sum) = 0;
    $len = $size >> 2; $len++ if ($size & 0x03);
    for ( $i = 0; $i < @{$list}; $i++ )
    {
        $sum += $bits;
        printf('$' . $name . "[%02d] = '%0${len}X'; # %d\n", $i, $list->[$i], $sum);
    }
}

__END__

