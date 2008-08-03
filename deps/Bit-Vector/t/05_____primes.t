#!perl -w

use strict;
no strict "vars";

use Bit::Vector;

# ======================================================================
#   $set = new Bit::Vector($elements);
#   $set->Fill();
#   $set->Empty();
#   $set->Primes();
#   $set->Bit_Off($i);
#   $set->Bit_On($i);
#   $set->bit_flip($i);
#   $set->contains($i);
#   $set->Norm();
#   $set1->equal($set2);
# ======================================================================

$limit = 1000;

print "1..", ($limit+4)*2, "\n";

@prime = (0) x ($limit+1);

$prime[2] = 1;
$prime[3] = 1;
$prime[5] = 1;
$prime[7] = 1;
$prime[11] = 1;
$prime[13] = 1;
$prime[17] = 1;
$prime[19] = 1;
$prime[23] = 1;
$prime[29] = 1;
$prime[31] = 1;
$prime[37] = 1;
$prime[41] = 1;
$prime[43] = 1;
$prime[47] = 1;
$prime[53] = 1;
$prime[59] = 1;
$prime[61] = 1;
$prime[67] = 1;
$prime[71] = 1;
$prime[73] = 1;
$prime[79] = 1;
$prime[83] = 1;
$prime[89] = 1;
$prime[97] = 1;
$prime[101] = 1;
$prime[103] = 1;
$prime[107] = 1;
$prime[109] = 1;
$prime[113] = 1;
$prime[127] = 1;
$prime[131] = 1;
$prime[137] = 1;
$prime[139] = 1;
$prime[149] = 1;
$prime[151] = 1;
$prime[157] = 1;
$prime[163] = 1;
$prime[167] = 1;
$prime[173] = 1;
$prime[179] = 1;
$prime[181] = 1;
$prime[191] = 1;
$prime[193] = 1;
$prime[197] = 1;
$prime[199] = 1;
$prime[211] = 1;
$prime[223] = 1;
$prime[227] = 1;
$prime[229] = 1;
$prime[233] = 1;
$prime[239] = 1;
$prime[241] = 1;
$prime[251] = 1;
$prime[257] = 1;
$prime[263] = 1;
$prime[269] = 1;
$prime[271] = 1;
$prime[277] = 1;
$prime[281] = 1;
$prime[283] = 1;
$prime[293] = 1;
$prime[307] = 1;
$prime[311] = 1;
$prime[313] = 1;
$prime[317] = 1;
$prime[331] = 1;
$prime[337] = 1;
$prime[347] = 1;
$prime[349] = 1;
$prime[353] = 1;
$prime[359] = 1;
$prime[367] = 1;
$prime[373] = 1;
$prime[379] = 1;
$prime[383] = 1;
$prime[389] = 1;
$prime[397] = 1;
$prime[401] = 1;
$prime[409] = 1;
$prime[419] = 1;
$prime[421] = 1;
$prime[431] = 1;
$prime[433] = 1;
$prime[439] = 1;
$prime[443] = 1;
$prime[449] = 1;
$prime[457] = 1;
$prime[461] = 1;
$prime[463] = 1;
$prime[467] = 1;
$prime[479] = 1;
$prime[487] = 1;
$prime[491] = 1;
$prime[499] = 1;
$prime[503] = 1;
$prime[509] = 1;
$prime[521] = 1;
$prime[523] = 1;
$prime[541] = 1;
$prime[547] = 1;
$prime[557] = 1;
$prime[563] = 1;
$prime[569] = 1;
$prime[571] = 1;
$prime[577] = 1;
$prime[587] = 1;
$prime[593] = 1;
$prime[599] = 1;
$prime[601] = 1;
$prime[607] = 1;
$prime[613] = 1;
$prime[617] = 1;
$prime[619] = 1;
$prime[631] = 1;
$prime[641] = 1;
$prime[643] = 1;
$prime[647] = 1;
$prime[653] = 1;
$prime[659] = 1;
$prime[661] = 1;
$prime[673] = 1;
$prime[677] = 1;
$prime[683] = 1;
$prime[691] = 1;
$prime[701] = 1;
$prime[709] = 1;
$prime[719] = 1;
$prime[727] = 1;
$prime[733] = 1;
$prime[739] = 1;
$prime[743] = 1;
$prime[751] = 1;
$prime[757] = 1;
$prime[761] = 1;
$prime[769] = 1;
$prime[773] = 1;
$prime[787] = 1;
$prime[797] = 1;
$prime[809] = 1;
$prime[811] = 1;
$prime[821] = 1;
$prime[823] = 1;
$prime[827] = 1;
$prime[829] = 1;
$prime[839] = 1;
$prime[853] = 1;
$prime[857] = 1;
$prime[859] = 1;
$prime[863] = 1;
$prime[877] = 1;
$prime[881] = 1;
$prime[883] = 1;
$prime[887] = 1;
$prime[907] = 1;
$prime[911] = 1;
$prime[919] = 1;
$prime[929] = 1;
$prime[937] = 1;
$prime[941] = 1;
$prime[947] = 1;
$prime[953] = 1;
$prime[967] = 1;
$prime[971] = 1;
$prime[977] = 1;
$prime[983] = 1;
$prime[991] = 1;
$prime[997] = 1;

$set1 = new Bit::Vector($limit+1);
$set2 = new Bit::Vector($limit+1);
$set3 = new Bit::Vector($limit+1);

$set1->Fill();
$set2->Empty();
$set3->Primes();

$set1->Bit_Off(0);
$set1->Bit_Off(1);
$set2->Bit_On(0);
$set2->Bit_On(1);

for ( $j = 4; $j <= $limit; $j += 2 )
{
    $set1->Bit_Off($j);
    $set2->Bit_On($j);
}

for ( $i = 3; ($j = $i * $i) <= $limit; $i += 2 )
{
    for ( ; $j <= $limit; $j += $i )
    {
        $set1->Bit_Off($j);
        $set2->Bit_On($j);
    }
}

$n = 1;
for ( $i = 0; $i <= $limit; ++$i )
{
    if ($set1->contains($i) == $prime[$i])
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if ($set2->bit_flip($i) == $prime[$i])
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

if ($set1->Norm() == 168)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($set2->Norm() == 168)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($set3->Norm() == 168)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($set1->equal($set2))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($set1->equal($set3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($set2->equal($set3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

