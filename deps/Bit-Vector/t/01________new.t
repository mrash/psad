#!perl -w

use strict;
no strict "vars";
use integer;

use Bit::Vector;

@ISA = qw(Bit::Vector);

# ======================================================================
#   $set = Bit::Vector::new('Bit::Vector',$elements);
# ======================================================================

print "1..131\n";

$n = 1;

# test if the constructor works at all:

$set = Bit::Vector::new('Bit::Vector',1);
if (defined $set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref($set) eq 'Bit::Vector')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${$set} != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# test if the constructor handles NULL pointers as expected:

eval { $ref = Bit::Vector::new('Bit::Vector',0); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# test if the copy of an object reference works as expected:

$ref = $set;
if (defined $ref)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref($ref) eq 'Bit::Vector')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${$ref} != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (${$ref} == ${$set})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# test the constructor with a large set (13,983,816 elements):

$set = Bit::Vector::new('Bit::Vector',&binomial(49,6));
if (defined $set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref($set) eq 'Bit::Vector')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${$set} != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# are the two sets really distinct and set objects behaving as expected?

if (${$ref} != ${$set})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# are set objects behaving as expected, i.e. are they write-protected?

eval { ${$set} = 0x00088850; };
if ($@ =~ /Modification of a read-only value attempted/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
$set = 0x00088850;
if ($set == 559184)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { ${$ref} = 0x000E9CE0; };
if ($@ =~ /Modification of a read-only value attempted/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
$ref = 0x000E9CE0;
if ($ref == 957664)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# test various ways of calling the constructor:

# 1: $set = Bit::Vector::new('Bit::Vector',1);
# 2: $class = 'Bit::Vector'; $set = Bit::Vector::new($class,2);
# 3: $set = new Bit::Vector(3);
# 4: $set = Bit::Vector->new(4);
# 5: $ref = $set->new(5);
# 6: $set = $set->new(6);

# (test case #1 has been handled above)

# test case #2:

$class = 'Bit::Vector';
$set = Bit::Vector::new($class,2);
if (defined $set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref($set) eq 'Bit::Vector')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${$set} != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# test case #3:

$ref = new Bit::Vector(3);
if (defined $ref)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref($ref) eq 'Bit::Vector')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${$ref} != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# coherence test:

if (${$ref} != ${$set})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# test case #4:

$set = Bit::Vector->new(4);
if (defined $set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref($set) eq 'Bit::Vector')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${$set} != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# coherence test:

if (${$ref} != ${$set})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# prepare possibility for id check:

$old = ${$set};
if (${$set} == $old)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# test case #5:

$ref = $set->new(5);
if (defined $ref)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref($ref) eq 'Bit::Vector')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${$ref} != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# coherence tests:

if (defined $set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref($set) eq 'Bit::Vector')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${$set} != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (${$set} == $old)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (${$ref} != ${$set})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# prepare exact copy of object reference:

$ref = $set;
if (defined $ref)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref($ref) eq 'Bit::Vector')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${$ref} != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (${$ref} == ${$set})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (${$ref} == $old)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# test case #6 (pseudo auto-destruction test):

$set = $set->new(6);
if (defined $set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref($set) eq 'Bit::Vector')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${$set} != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# coherence tests:

if (defined $ref)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref($ref) eq 'Bit::Vector')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${$ref} != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (${$ref} == $old)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (${$ref} != ${$set})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# auto-destruction test:

$set = $set->new(7);
if (defined $set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref($set) eq 'Bit::Vector')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${$set} != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# coherence test:

if (${$ref} != ${$set})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# test weird ways of calling the constructor:

eval { $set = Bit::Vector::new("",8); };
if (ref($set) eq 'Bit::Vector')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set = Bit::Vector::new('',9); };
if (ref($set) eq 'Bit::Vector')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set = Bit::Vector::new(undef,10); };
if (ref($set) eq 'Bit::Vector')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set = Bit::Vector::new(6502,11); };
if (ref($set) eq 'Bit::Vector')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set = Bit::Vector::new('main',12); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ( (ref($set) eq 'main') || (ref($set) eq 'Bit::Vector') )
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${$set} != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set = 0; };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set = Bit::Vector::new('nonsense',13); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ( (ref($set) eq 'nonsense') || (ref($set) eq 'Bit::Vector') )
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${$set} != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set = 0; };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set = new main(14); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ( (ref($set) eq 'main') || (ref($set) eq 'Bit::Vector') )
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${$set} != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set = 0; };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

@parameters = ( 'main', 15 );
eval { $set = Bit::Vector::new(@parameters); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ( (ref($set) eq 'main') || (ref($set) eq 'Bit::Vector') )
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${$set} != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set = 0; };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# test syntactically incorrect constructor calls:

eval { $set = Bit::Vector::new(16); };
if ($@ =~ /Usage: new\(class,bits\[,count\]\)/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set = Bit::Vector::new('main'); };
if ($@ =~ /Usage: new\(class,bits\[,count\]\)/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set = Bit::Vector::new($set); };
if ($@ =~ /Usage: new\(class,bits\[,count\]\)/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set = Bit::Vector::new('main',17,1,0); };
if ($@ =~ /Usage: new\(class,bits\[,count\]\)/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set = Bit::Vector::Create($set,'main',18,0); };
if ($@ =~ /Usage: Create\(class,bits\[,count\]\)/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set = Bit::Vector::new($set,19,'main',0); };
if ($@ =~ /Usage: new\(class,bits\[,count\]\)/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# test if size is correct:

for ( $i = 1; $i <= 16; $i++ )
{
    $k = int(2 ** $i + 0.5);
    for ( $j = $k-1; $j <= $k+1; $j++ )
    {
        $set = Bit::Vector->new($j);
        if ($set->Size() == $j)
        {print "ok $n\n";} else {print "not ok $n\n";}
        $n++;
    }
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

