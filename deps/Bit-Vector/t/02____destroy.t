#!perl -w

use strict;
no strict "vars";

use Bit::Vector;

# ======================================================================
#   $set->DESTROY();
# ======================================================================

print "1..15\n";

$n = 1;
$set = 1;
if (ref($set) eq '')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { $set->DESTROY(); };
if ($@ =~ /Can't call method "DESTROY" without a package or object reference/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Bit::Vector::DESTROY($set); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
$obj = 0x00088850;
$set = \$obj;
if (ref($set) eq 'SCALAR')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { $set->DESTROY(); };
if ($@ =~ /Can't call method "DESTROY" on unblessed reference/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Bit::Vector::DESTROY($set); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
$obj = 0x000E9CE0;
$set = \$obj;
bless($set, 'Bit::Vector');
if (ref($set) eq 'Bit::Vector')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { $set->DESTROY(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { Bit::Vector::DESTROY($set); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
$set = new Bit::Vector(1);
if (ref($set) eq 'Bit::Vector')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { $set->DESTROY(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref($set) eq 'Bit::Vector')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined(${$set}) && (${$set} == 0))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { $set->DESTROY(); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
eval { $set = 0; };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

