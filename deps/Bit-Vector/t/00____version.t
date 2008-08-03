#!perl -w

use strict;
no strict "vars";

$Bit::Vector::VERSION           = 0;
$Bit::Vector::Overload::VERSION = 0;
$Bit::Vector::String::VERSION   = 0;

# ======================================================================
#   $ver = $Bit::Vector::VERSION;
#   $ver = Bit::Vector::Version();
#   $ver = Bit::Vector->Version();
#   $bits = Bit::Vector::Word_Bits();
#   $bits = Bit::Vector->Word_Bits();
#   $bits = Bit::Vector::Long_Bits();
#   $bits = Bit::Vector->Long_Bits();
#   $ver = $Bit::Vector::String::VERSION;
#   $ver = $Bit::Vector::Overload::VERSION;
# ======================================================================

print "1..15\n";

$n = 1;
if ($Bit::Vector::VERSION eq "0")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

require Bit::Vector;

if ($Bit::Vector::VERSION eq "6.4")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (Bit::Vector::Version() eq "6.4")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Bit::Vector::Word_Bits() >= 32)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (Bit::Vector::Long_Bits() >= 32)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (Bit::Vector->Version() eq "6.4")
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

if ($Bit::Vector::Overload::VERSION eq "0")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

require Bit::Vector::Overload;

if ($Bit::Vector::Overload::VERSION eq "6.4")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($Bit::Vector::String::VERSION eq "0")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

require Bit::Vector::String;

if ($Bit::Vector::String::VERSION eq "6.4")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

