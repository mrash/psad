#!perl -w

use strict;
no strict "vars";

use Bit::Vector;

# ======================================================================
#   $carry_out = $vector1->subtract($vector2,$vector3,$carry_in);
# ======================================================================

print "1..1001\n";

$n = 1;

$result0{'FE'}{'FE'} = '00'; $carry0{'FE'}{'FE'} = 0;
$result0{'FE'}{'FF'} = 'FF'; $carry0{'FE'}{'FF'} = 1;
$result0{'FE'}{'00'} = 'FE'; $carry0{'FE'}{'00'} = 0;
$result0{'FE'}{'01'} = 'FD'; $carry0{'FE'}{'01'} = 0;
$result0{'FE'}{'02'} = 'FC'; $carry0{'FE'}{'02'} = 0;

$result0{'FF'}{'FE'} = '01'; $carry0{'FF'}{'FE'} = 0;
$result0{'FF'}{'FF'} = '00'; $carry0{'FF'}{'FF'} = 0;
$result0{'FF'}{'00'} = 'FF'; $carry0{'FF'}{'00'} = 0;
$result0{'FF'}{'01'} = 'FE'; $carry0{'FF'}{'01'} = 0;
$result0{'FF'}{'02'} = 'FD'; $carry0{'FF'}{'02'} = 0;

$result0{'00'}{'FE'} = '02'; $carry0{'00'}{'FE'} = 1;
$result0{'00'}{'FF'} = '01'; $carry0{'00'}{'FF'} = 1;
$result0{'00'}{'00'} = '00'; $carry0{'00'}{'00'} = 0;
$result0{'00'}{'01'} = 'FF'; $carry0{'00'}{'01'} = 1;
$result0{'00'}{'02'} = 'FE'; $carry0{'00'}{'02'} = 1;

$result0{'01'}{'FE'} = '03'; $carry0{'01'}{'FE'} = 1;
$result0{'01'}{'FF'} = '02'; $carry0{'01'}{'FF'} = 1;
$result0{'01'}{'00'} = '01'; $carry0{'01'}{'00'} = 0;
$result0{'01'}{'01'} = '00'; $carry0{'01'}{'01'} = 0;
$result0{'01'}{'02'} = 'FF'; $carry0{'01'}{'02'} = 1;

$result0{'02'}{'FE'} = '04'; $carry0{'02'}{'FE'} = 1;
$result0{'02'}{'FF'} = '03'; $carry0{'02'}{'FF'} = 1;
$result0{'02'}{'00'} = '02'; $carry0{'02'}{'00'} = 0;
$result0{'02'}{'01'} = '01'; $carry0{'02'}{'01'} = 0;
$result0{'02'}{'02'} = '00'; $carry0{'02'}{'02'} = 0;

$result1{'FE'}{'FE'} = 'FF'; $carry1{'FE'}{'FE'} = 1;
$result1{'FE'}{'FF'} = 'FE'; $carry1{'FE'}{'FF'} = 1;
$result1{'FE'}{'00'} = 'FD'; $carry1{'FE'}{'00'} = 0;
$result1{'FE'}{'01'} = 'FC'; $carry1{'FE'}{'01'} = 0;
$result1{'FE'}{'02'} = 'FB'; $carry1{'FE'}{'02'} = 0;

$result1{'FF'}{'FE'} = '00'; $carry1{'FF'}{'FE'} = 0;
$result1{'FF'}{'FF'} = 'FF'; $carry1{'FF'}{'FF'} = 1;
$result1{'FF'}{'00'} = 'FE'; $carry1{'FF'}{'00'} = 0;
$result1{'FF'}{'01'} = 'FD'; $carry1{'FF'}{'01'} = 0;
$result1{'FF'}{'02'} = 'FC'; $carry1{'FF'}{'02'} = 0;

$result1{'00'}{'FE'} = '01'; $carry1{'00'}{'FE'} = 1;
$result1{'00'}{'FF'} = '00'; $carry1{'00'}{'FF'} = 1;
$result1{'00'}{'00'} = 'FF'; $carry1{'00'}{'00'} = 1;
$result1{'00'}{'01'} = 'FE'; $carry1{'00'}{'01'} = 1;
$result1{'00'}{'02'} = 'FD'; $carry1{'00'}{'02'} = 1;

$result1{'01'}{'FE'} = '02'; $carry1{'01'}{'FE'} = 1;
$result1{'01'}{'FF'} = '01'; $carry1{'01'}{'FF'} = 1;
$result1{'01'}{'00'} = '00'; $carry1{'01'}{'00'} = 0;
$result1{'01'}{'01'} = 'FF'; $carry1{'01'}{'01'} = 1;
$result1{'01'}{'02'} = 'FE'; $carry1{'01'}{'02'} = 1;

$result1{'02'}{'FE'} = '03'; $carry1{'02'}{'FE'} = 1;
$result1{'02'}{'FF'} = '02'; $carry1{'02'}{'FF'} = 1;
$result1{'02'}{'00'} = '01'; $carry1{'02'}{'00'} = 0;
$result1{'02'}{'01'} = '00'; $carry1{'02'}{'01'} = 0;
$result1{'02'}{'02'} = 'FF'; $carry1{'02'}{'02'} = 1;

foreach $bits (31, 32, 33, 63, 64, 65, 127, 128, 129, 997)
{
    $vec0 = Bit::Vector->new($bits);
    $vec1 = Bit::Vector->new($bits);
    $vec2 = Bit::Vector->new($bits);
    $vec3 = Bit::Vector->new($bits);

    foreach $arg1 (sort hexadecimal (keys %result0))
    {
        foreach $arg2 (sort hexadecimal (keys %{$result0{$arg1}}))
        {
#           print "subtract '$arg1' - '$arg2'\n";
            $vec1->from_Hex(convert($arg1));
            $vec2->from_Hex(convert($arg2));
            $vec3->from_Hex(convert($result0{$arg1}{$arg2}));
            $carry3 =                   $carry0{$arg1}{$arg2};
            $carry0 = $vec0->subtract($vec1,$vec2,0);
#           print "Result:    '", $vec0->to_Hex(), "' $carry0\n";
#           print "Should be: '", $vec3->to_Hex(), "' $carry3\n";
            if ($vec0->equal($vec3))
            {print "ok $n\n";} else {print "not ok $n\n";}
            $n++;
            if ($carry0 == $carry3)
            {print "ok $n\n";} else {print "not ok $n\n";}
            $n++;
        }
    }

    foreach $arg1 (sort hexadecimal (keys %result0))
    {
        foreach $arg2 (sort hexadecimal (keys %{$result0{$arg1}}))
        {
#           print "subtract '$arg1' - '$arg2' - 1\n";
            $vec1->from_Hex(convert($arg1));
            $vec2->from_Hex(convert($arg2));
            $vec3->from_Hex(convert($result1{$arg1}{$arg2}));
            $carry3 =                   $carry1{$arg1}{$arg2};
            $carry0 = $vec0->subtract($vec1,$vec2,1);
#           print "Result:    '", $vec0->to_Hex(), "' $carry0\n";
#           print "Should be: '", $vec3->to_Hex(), "' $carry3\n";
            if ($vec0->equal($vec3))
            {print "ok $n\n";} else {print "not ok $n\n";}
            $n++;
            if ($carry0 == $carry3)
            {print "ok $n\n";} else {print "not ok $n\n";}
            $n++;
        }
    }
}

$vec = Bit::Vector->new(1024);
$vec->subtract($vec,$vec,5);
if ($vec->is_full())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

exit;

sub hexadecimal
{
    my($x,$y) = (hex($a),hex($b));

    if ($x > 127) { $x -= 256; }
    if ($y > 127) { $y -= 256; }

    return( $x <=> $y );
}

sub convert
{
    my($hex) = shift;
    my($dec) = hex($hex);
    my($len);

    $len = int($bits / 4);
    if ($len * 4 < $bits) { $len++; }
    $len -= 2;

    if ($dec > 127) { return( ('F' x $len) . $hex ); }
    else            { return( ('0' x $len) . $hex ); }
}

__END__

