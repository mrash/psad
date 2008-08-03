#!perl -w

use strict;
no strict "vars";

use Bit::Vector::Overload;

$Bit::Vector::CONFIG[2] = 3;

# ======================================================================
#   $vector->to_Hex();
#   $vector->from_Hex();
#   $vector->to_Enum();
#   $vector->from_Enum();
# ======================================================================

print "1..192\n";

$limit = 100;

$vec1 = Bit::Vector->new($limit+1);
$vec2 = Bit::Vector->new($limit+1);

$n = 1;

eval { $vec1->from_Hex("FEDCBA9876543210"); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str1 = $vec1->to_Hex();
if ($str1 =~ /^0*FEDCBA9876543210$/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $vec2->from_Hex("fedcba9876543210"); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str2 = $vec2->to_Hex();
if ($str2 =~ /^0*FEDCBA9876543210$/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $vec1->from_Hex("deadbeef"); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str1 = $vec1->to_Hex();
if ($str1 =~ /^0*DEADBEEF$/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $vec1->from_Hex("dead beef"); };
if ($@ =~ /syntax error/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $vec2->from_Hex("beef"); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($vec1->equal($vec2))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str1 = $vec1->to_Hex();
if ($str1 =~ /^0*BEEF$/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str2 = $vec2->to_Enum();
if ($str2 eq "0-3,5-7,9-13,15")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$vec1->Primes();

$str1 = $vec1->to_Hex();
if ($str1 =~ /^0*20208828828208A20A08A28AC$/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str2 = $vec1->to_Enum();
if ($str2 eq
"2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73,79,83,89,97")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $vec2->from_Hex("20208828828208A20A08A28AC"); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($vec1->equal($vec2))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$vec2->Flip();
$str1 =
"2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73,79,83,89,97";
eval { $vec2->from_Enum($str1); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($vec1->equal($vec2))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str2 = "43,4,19,2,12,67,31,11,3,23,29,6-9,79-97,14-16,47,53-59,71,37-41,61";
eval { $vec2->from_Enum($str2); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str1 = $vec2->to_Enum();
$str2 = "2-4,6-9,11,12,14-16,19,23,29,31,37-41,43,47,53-59,61,67,71,79-97";
if ($str1 eq $str2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str1 = $vec2->to_Hex();
if ($str1 =~ /^0*3FFFF80882FE08BE0A089DBDC$/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$vec2->Fill();
if ($vec2->Norm() == $limit+1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $vec2->from_Hex("0000000000000000"); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($vec2->Norm() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$vec2->Fill();
if ($vec2->Norm() == $limit+1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $vec2->from_Hex("0"); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($vec2->Norm() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$vec2->Fill();
if ($vec2->Norm() == $limit+1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $vec2->from_Hex(""); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($vec2->Norm() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$vec1 = Bit::Vector->new(64);
eval { $vec1->from_Hex("FEDCBA9876543210"); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str1 = $vec1->to_Hex();
if ($str1 =~ /^0*FEDCBA9876543210$/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$vec2 = Bit::Vector->new(64);
eval { $vec2->from_Hex("fedcba9876543210"); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str2 = $vec2->to_Hex();
if ($str2 =~ /^0*FEDCBA9876543210$/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$vec1 = Bit::Vector->new(32);
eval { $vec1->from_Hex("DEADbeef"); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str1 = $vec1->to_Hex();
if ($str1 =~ /^0*DEADBEEF$/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$vec2 = Bit::Vector->new(36);
eval { $vec2->from_Hex("DEAD beef"); };
if ($@ =~ /syntax error/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str2 = $vec2->to_Hex();
if ($str2 =~ /^0*00000BEEF$/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$vec1 = Bit::Vector->new(64);
eval { $vec1->from_Hex("0000000000000000"); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($vec1->Norm() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($vec1->Size() == 64)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$vec2 = Bit::Vector->new(64);
eval { $vec2->from_Hex("00000g0000000000"); };
if ($@ =~ /syntax error/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $vec2->from_Hex(""); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$vec1 = Bit::Vector->new($limit+1);

$str1 = 3.1415926 * 2.0E+7;
eval { $vec1->from_Hex($str1); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str2 = $vec1->to_Hex();
if ($str2 =~ /^0*62831852$/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$vec2 = Bit::Vector->new($limit+1);
eval { $vec2->from_Hex($str1); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str2 = $vec2->to_Hex();
if ($str2 =~ /^0*62831852$/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str2 = 3.1415926 * 2.0;
eval { $vec1->from_Hex($str2); };
if ($@ =~ /syntax error/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $vec2->from_Hex($str2); };
if ($@ =~ /syntax error/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str1 = "ERRORFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";
#             _123456789ABCDEF_123456789ABCDEF_123456789ABCDEF_123456789ABCDEF
eval { $vec1->from_Hex($str1); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str2 = $vec1->to_Hex();
if ($str2 =~ /^0*1FFFFFFFFFFFFFFFFFFFFFFFFF$/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$vec2 = $vec1->Shadow();

eval { $vec1->from_Enum("0-$limit"); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$vec2->Fill();
if ($vec1->equal($vec2))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $vec1->from_Enum("0..$limit"); };
if ($@ =~ /syntax error/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $vec1->from_Enum("0,$limit"); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$vec2->Empty();
$vec2->Bit_On(0);
$vec2->Bit_On($limit);
if ($vec1->equal($vec2))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $vec1->from_Enum("0,$limit,"); };
if ($@ =~ /syntax error/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $vec1->from_Enum("0,\$limit"); };
if ($@ =~ /syntax error/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $vec1->from_Enum("101-102"); };
if ($@ =~ /index out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $vec1->from_Enum("100-102"); };
if ($@ =~ /index out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $vec1->from_Enum("100-99"); };
if ($@ =~ /minimum > maximum index/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $vec1->from_Enum("100,101"); };
if ($@ =~ /index out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $vec1->from_Enum("101,100"); };
if ($@ =~ /index out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

@first = ('', '1', '3', '7');

for ( $bits = 0; $bits <= 129; $bits++ )
{
    $vec = Bit::Vector->new($bits);
    $vec->Fill();
    if ($vec->to_Hex() eq $first[$bits & 3] . ('F' x ($bits >> 2)))
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

__END__

