#!perl -w

use strict;
no strict "vars";

use Bit::Vector 6.3;

# ======================================================================
#   $ver = $Bit::Vector::VERSION;
#   $ver = Bit::Vector::Version();
#   $ver = Bit::Vector->Version();
#   $bits = Bit::Vector::Word_Bits();
#   $bits = Bit::Vector->Word_Bits();
#   $bits = Bit::Vector::Long_Bits();
#   $bits = Bit::Vector->Long_Bits();
# ======================================================================

print "1..10\n";

$n = 1;
if ($Bit::Vector::VERSION eq "6.3")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (Bit::Vector::Version() eq "6.3")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Bit::Vector::Word_Bits() >= 32)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Bit::Vector::Long_Bits() >= 32)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (Bit::Vector->Version() eq "6.3")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Bit::Vector->Word_Bits() >= 32)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Bit::Vector->Long_Bits() >= 32)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { Bit::Vector->Version(0); };
if ($@ =~ /Usage: Bit::Vector->Version\(\)/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Bit::Vector->Word_Bits(0); };
if ($@ =~ /Usage: Bit::Vector->Word_Bits\(\)/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Bit::Vector->Long_Bits(0); };
if ($@ =~ /Usage: Bit::Vector->Long_Bits\(\)/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

