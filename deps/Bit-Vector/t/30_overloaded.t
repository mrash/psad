#!perl -w

use strict;
no strict "vars";

use Bit::Vector::Overload;

$Bit::Vector::CONFIG[2] = 3;

# ======================================================================
#   test overloaded operators
# ======================================================================

$operator_list{'+='}  = 1;
$operator_list{'|='}  = 1;
$operator_list{'-='}  = 1;
$operator_list{'*='}  = 1;
$operator_list{'&='}  = 1;
$operator_list{'^='}  = 1;
$operator_list{'<<='} = 1;
$operator_list{'>>='} = 1;
$operator_list{'x='}  = 1;
$operator_list{'.='}  = 1;

$operator_list{'+'}   = 2;
$operator_list{'|'}   = 2;
$operator_list{'-'}   = 2;
$operator_list{'*'}   = 2;
$operator_list{'&'}   = 2;
$operator_list{'^'}   = 2;
$operator_list{'<<'}  = 2;
$operator_list{'>>'}  = 2;
$operator_list{'x'}   = 2;
$operator_list{'.'}   = 2;

$operator_list{'=='}  = 2;
$operator_list{'!='}  = 2;
$operator_list{'<'}   = 2;
$operator_list{'<='}  = 2;
$operator_list{'>'}   = 2;
$operator_list{'>='}  = 2;
$operator_list{'cmp'} = 2;
$operator_list{'eq'}  = 2;
$operator_list{'ne'}  = 2;
$operator_list{'lt'}  = 2;
$operator_list{'le'}  = 2;
$operator_list{'gt'}  = 2;
$operator_list{'ge'}  = 2;

print "1..15695\n";

$n = 1;

$set = Bit::Vector->new(500);
if (abs($set) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Min() >= 500)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Max() < 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless ($set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (! $set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set += 0;
if (abs($set) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Min() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Max() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (! $set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set += 1;
if (abs($set) == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Min() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Max() == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (! $set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set ^= 0;
if (abs($set) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Min() == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Max() == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set += 400;
if (abs($set) == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Min() == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Max() == 400)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set ^= 0;
if (abs($set) == 3)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Min() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Max() == 400)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$ref = $set;
if ($ref == $set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$ref = $set->new(500);
if (! $ref)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$ref->Copy($set);
if ($ref == $set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$ref = $set + 11;
if (abs($ref) == 4)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref->Min() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref->Max() == 400)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref->bit_test(11))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (!($ref == $set))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref != $set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set < $ref)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set <= $ref)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref > $set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref >= $set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$ref = $set + 499;
if (abs($ref) == 4)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref->Min() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref->Max() == 499)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$ref = $ref - 400;
if (abs($ref) == 3)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref->Min() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref->Max() == 499)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$ref = $ref - 0;
if (abs($ref) == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref->Min() == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref->Max() == 499)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$ref -= 499;
if (abs($ref) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref->Min() == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref->Max() == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$ref -= 1;
if (abs($ref) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref->Min() >= 500)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref->Max() < 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$limit = 1000; # some tests below assume this limit to be even!

$primes = Bit::Vector->new($limit+1);
if (! $primes)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$primes->Fill();
if ($primes)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (abs($primes) == $limit+1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($primes->Min() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($primes->Max() == $limit)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$primes -= 0;
$primes -= 1;

for ( $j = 4; $j <= $limit; $j += 2 ) { $primes -= $j; }

for ( $i = 3; ($j = $i * $i) <= $limit; $i += 2 )
{
    for ( ; $j <= $limit; $j += $i ) { $primes -= $j; }
}

if (abs($primes) == 168)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($primes->Min() == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($primes->Max() == 997)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$odd = $primes->new($limit+1);
if (! $odd)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

for ( $i = 1; $i <= $limit; $i += 2 ) { $odd += $i; }

if ($odd)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (abs($odd) == $limit/2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($odd->Min() == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($odd->Max() == 999)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (!($odd == $primes))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($odd != $primes)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!($primes < $odd))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!($primes <= $odd))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!($primes > $odd))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!($primes >= $odd))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp = $primes - $odd;
if ($temp == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (2 == $temp)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$odd = $odd + 2;
if (abs($odd) == ($limit/2)+1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($odd->Min() == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($odd->Max() == 999)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!($odd == $primes))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($odd != $primes)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($primes < $odd)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($primes <= $odd)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!($primes > $odd))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!($primes >= $odd))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($odd > $primes)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($odd >= $primes)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!($odd < $primes))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!($odd <= $primes))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp = $primes * $odd;
if ($temp == $primes)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp = $primes + $odd;
if ($temp == $odd)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp = $primes ^ $odd;

$xor = $primes->new($limit+1);
if (! $xor)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$xor->ExclusiveOr($primes,$odd);
if ($xor)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($temp == $xor)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($temp->equal($xor))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (23 < $primes)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (23 <= $primes)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!(23 > $primes))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!(23 >= $primes))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($primes > 23)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($primes >= 23)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!($primes < 23))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!($primes <= 23))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp = ($primes + $odd) - ($primes * $odd);

if ($temp == $xor)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($temp->equal($xor))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$even = $xor;
$even->Empty();
for ( $i = 0; $i <= $limit; $i += 2 ) { $even += $i; }

if (($primes * $even) == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (($odd * $even) == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$full = $temp;
$full->Fill();
if (($odd + $even) == $full)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (($primes + $even) == ~($odd - $primes))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (($primes + $even) == ~($odd * ~$primes))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set = Bit::Vector->new(500);
if (abs($set) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Min() >= 500)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Max() < 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless ($set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (++$set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (abs($set) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Min() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Max() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (++$set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (abs($set) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Min() == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Max() == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (++$set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (abs($set) == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Min() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Max() == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (--$set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (abs($set) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Min() == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Max() == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (--$set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (abs($set) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Min() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Max() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

unless (--$set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (abs($set) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Min() >= 500)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Max() < 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless ($set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (--$set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (abs($set) == 500)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Min() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Max() == 499)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

unless (++$set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (abs($set) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Min() >= 500)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Max() < 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless ($set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set->Empty();
unless ($set++)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set->Empty();
if (++$set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set->Empty();
unless ($set--)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set->Empty();
if (--$set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set->Empty();
if (($set++)->Norm() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set->Empty();
if ((++$set)->Norm() == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set->Empty();
if (($set--)->Norm() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set->Empty();
if ((--$set)->Norm() == 500)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (($primes cmp $odd) == -1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (($odd cmp $primes) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($odd + $even) cmp $full) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($odd * $even) cmp 2) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((2 cmp ($odd * $even)) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (($odd ^= 2) == ($full - $even))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# systematic tests:

$temp = $odd + $even;
if ($temp == $full)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp->Copy($odd);
if ($temp == $odd)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp += $even;
if ($temp == $full)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp = $odd + 2;
if (abs($temp) == abs($odd) + 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp->Copy($odd);
$temp += 4;
if (abs($temp) == abs($odd) + 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp = $odd | $even;
if ($temp == $full)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp->Copy($odd);
if ($temp == $odd)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp |= $even;
if ($temp == $full)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp = $odd | 2;
if (abs($temp) == abs($odd) + 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp->Copy($odd);
$temp |= 4;
if (abs($temp) == abs($odd) + 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp = $full - $even;
if ($temp == $odd)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$empty = $temp->new($limit+1);

$temp -= $odd;
if ($temp == $empty)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp = $even - 2;
if (abs($temp) == abs($even) - 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp->Copy($even);
if ($temp == $even)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp -= 8;
if (abs($temp) == abs($even) - 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp = $primes * $even;
if ($temp == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp->Copy($primes);
if ($temp == $primes)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp *= $even;
if ($temp == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp = $primes * 2;
if ($temp == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp->Copy($primes);
$temp *= 2;
if ($temp == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp = $primes & $even;
if ($temp == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp->Copy($primes);
if ($temp == $primes)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp &= $even;
if ($temp == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp = $primes & 2;
if ($temp == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp->Copy($primes);
$temp &= 2;
if ($temp == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp = $odd ^ $even;
if ($temp == $full)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp->Copy($odd);
if ($temp == $odd)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp ^= $even;
if ($temp == $full)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp = $odd ^ 2;
if (abs($temp) == abs($odd) + 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp->Copy($odd);
$temp ^= 4;
if (abs($temp) == abs($odd) + 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (($odd cmp $even) == -1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (($even cmp $odd) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp ^= 4;
if ($temp == $odd)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (($temp cmp $odd) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (($odd cmp $temp) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($odd eq $temp)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (!($odd ne $temp))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (!($primes eq $odd))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($primes ne $odd)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($odd lt $even)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($odd le $even)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (!($even lt $odd))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (!($even le $odd))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (!($odd gt $even))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (!($odd ge $even))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($even gt $odd)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($even ge $odd)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# wrong parameter checks:

$set = Bit::Vector->new(500);

if ($set->Norm() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set->Fill();

if ($set->Norm() == 500)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

foreach $operator (keys %operator_list)
{
    $parms = $operator_list{$operator};

    $obj = 0x000E9CE0;
    $fake = \$obj;
    if (ref($fake) eq 'SCALAR')
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    &test_fake($parms);

    $fake = [ ];
    if (ref($fake) eq 'ARRAY')
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    &test_fake($parms);

    $fake = { };
    if (ref($fake) eq 'HASH')
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    &test_fake($parms);

    $fake = sub { };
    if (ref($fake) eq 'CODE')
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    &test_fake($parms);

    $obj = { };
    $fake = \$obj;
    if (ref($fake) eq 'REF')
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    &test_fake($parms);
}

# bit shift operator tests:

foreach $bits (0,1,2,3,4,16,32,61,97,256,257,499,512)
{
    $shift = ($primes << $bits);
    &verify($bits);
    $shift = $primes->Clone();
    $shift <<= $bits;
    &verify($bits);
    $shift = ($primes >> $bits);
    &verify(-$bits);
    $shift = $primes->Clone();
    $shift >>= $bits;
    &verify(-$bits);
}

eval { $shift = (0 << $primes); };
if ($@ =~ /\billegal reversed operands in overloaded '<<' operator\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $shift = (1 << $primes); };
if ($@ =~ /\billegal reversed operands in overloaded '<<' operator\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $shift = (0 >> $primes); };
if ($@ =~ /\billegal reversed operands in overloaded '>>' operator\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $shift = (1 >> $primes); };
if ($@ =~ /\billegal reversed operands in overloaded '>>' operator\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $shift = (0 x $primes); };
if ($@ =~ /\billegal reversed operands in overloaded 'x' operator\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $shift = (1 x $primes); };
if ($@ =~ /\billegal reversed operands in overloaded 'x' operator\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

exit;

sub test_fake
{
    my($parms) = @_;
    my($op,$message);

    $op = $operator;
    $op =~ s/^[a-wyz]+$/cmp/;

    $message = quotemeta("illegal operand type in overloaded '$op' operator");
    if ($parms == 1)
    {
        $action = "\$set $operator \$fake";
        eval "$action";
        if ($@ =~ /$message/)
        {print "ok $n\n";} else {print "not ok $n\n";}
        $n++;
    }
    elsif ($parms == 2)
    {
        $action = "\$temp = \$set $operator \$fake";
        eval "$action";
        if ($@ =~ /$message/)
        {print "ok $n\n";} else {print "not ok $n\n";}

        $n++;
        $action = "\$temp = \$fake $operator \$set";
        eval "$action";
        if ($@ =~ /$message/)
        {print "ok $n\n";} else {print "not ok $n)\n";}
        $n++;
    }
    else { }
}

sub verify
{
    my($offset) = @_;
    my($i,$j);

    for ( $i = 0; $i <= $limit; $i++ )
    {
        if ($primes->contains($i))
        {
            $j = $i + $offset;
            if (($j >= 0) && ($j <= $limit))
            {
                if ($shift->contains($j))
                {print "ok $n\n";} else {print "not ok $n\n";}
                $n++;
            }
        }
        if ($shift->contains($i))
        {
            $j = $i - $offset;
            if (($j >= 0) && ($j <= $limit))
            {
                if ($primes->contains($j))
                {print "ok $n\n";} else {print "not ok $n\n";}
                $n++;
            }
        }
    }
}

__END__

