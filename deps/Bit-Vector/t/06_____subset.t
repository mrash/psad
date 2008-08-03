#!perl -w

use strict;
no strict "vars";

use Bit::Vector;

# ======================================================================
#   $set1->subset($set2);
# ======================================================================

$bits = 6;

print "1..$bits\n";

$n = 1;
for ( $b = 1; $b <= $bits; ++$b )
{

    $set1 = new Bit::Vector($b);
    $set2 = new Bit::Vector($b);

    $c1 = 0;
    $c2 = 0;

    for ( $k = 0; $k <= $b; ++$k )
    {
        $c1 += (1<<$k) * &binomial($b,$k);
    }

    for ( $i = 0; $i < (1<<$b); ++$i )
    {
        $c = $i;
        for ( $k = 0; $k < $b; ++$k )
        {
            if ($c & 1) { $set1->Bit_On($k); } else { $set1->Bit_Off($k); }
            $c >>= 1;
        }
        for ( $j = 0; $j < (1<<$b); ++$j )
        {
            $c = $j;
            for ( $k = 0; $k < $b; ++$k )
            {
                if ($c & 1) { $set2->Bit_On($k); } else { $set2->Bit_Off($k); }
                $c >>= 1;
            }
            if ($set1->subset($set2)) { ++$c2; }
        }
    }

    if ($c1 == $c2)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

exit;

sub binomial
{
    my($n,$k) = @_;
    my($prod) = 1;
    my($j) = 0;

    if (($n <= 0) || ($k <= 0) || ($n <= $k)) { return(1); }
    if ($k > $n - $k) { $k = $n - $k; }
    while ($j < $k)
    {
        $prod *= $n--;
        $prod /= ++$j;
    }
    return(int($prod + 0.5));
}

__END__

