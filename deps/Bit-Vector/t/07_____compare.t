#!perl -w

use strict;
no strict "vars";

use Bit::Vector;

# ======================================================================
#   $set1->Compare($set2);
#   $set1->Lexicompare($set2);
# ======================================================================

print "1..50\n";

$set0 = new Bit::Vector(65536);
$set1 = new Bit::Vector(65536);
$set2 = new Bit::Vector(65536);
$set3 = new Bit::Vector(65536);
$set4 = new Bit::Vector(65536);

$set1->Bit_On(0);
$set2->Bit_On(1);
$set3->Fill();
$set3->Bit_Off(0);
$set4->Fill();

$n = 1;
if ($set0->Compare($set0) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set0->Compare($set1) == -1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set0->Compare($set2) == -1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set0->Compare($set3) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set0->Compare($set4) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set1->Compare($set0) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set1->Compare($set1) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set1->Compare($set2) == -1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set1->Compare($set3) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set1->Compare($set4) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set2->Compare($set0) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set2->Compare($set1) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set2->Compare($set2) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set2->Compare($set3) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set2->Compare($set4) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set3->Compare($set0) == -1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set3->Compare($set1) == -1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set3->Compare($set2) == -1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set3->Compare($set3) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set3->Compare($set4) == -1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set4->Compare($set0) == -1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set4->Compare($set1) == -1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set4->Compare($set2) == -1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set4->Compare($set3) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set4->Compare($set4) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($set0->Lexicompare($set0) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set0->Lexicompare($set1) == -1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set0->Lexicompare($set2) == -1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set0->Lexicompare($set3) == -1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set0->Lexicompare($set4) == -1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set1->Lexicompare($set0) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set1->Lexicompare($set1) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set1->Lexicompare($set2) == -1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set1->Lexicompare($set3) == -1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set1->Lexicompare($set4) == -1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set2->Lexicompare($set0) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set2->Lexicompare($set1) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set2->Lexicompare($set2) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set2->Lexicompare($set3) == -1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set2->Lexicompare($set4) == -1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set3->Lexicompare($set0) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set3->Lexicompare($set1) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set3->Lexicompare($set2) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set3->Lexicompare($set3) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set3->Lexicompare($set4) == -1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set4->Lexicompare($set0) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set4->Lexicompare($set1) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set4->Lexicompare($set2) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set4->Lexicompare($set3) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set4->Lexicompare($set4) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

