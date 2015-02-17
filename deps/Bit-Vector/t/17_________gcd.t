#!perl -w

use strict;

use Bit::Vector;

print "1..693\n";

my $n = 1;

my $x = Bit::Vector->new(128);
my $y = Bit::Vector->new(128);
my $z = Bit::Vector->new(128);

my $u = Bit::Vector->new(128);
my $v = Bit::Vector->new(128);
my $w = Bit::Vector->new(128);

my($uu,$vv,$ww,$xx,$yy,$zz);

sub gcd($$$$$)
{
    my($a,$b,$c,$d,$e) = @_;
    my($q,$r,$i);
    my(@t);

    $t[0] = [ $a, 1, 0, 0 ];
    $t[1] = [ $b, 0, 1, 0 ];

    $x->from_Dec($a);
    $y->from_Dec($b);

#   printf("\n[ %6d, %6d, %6d, %6d ]\n", @{$t[0]});

    $i = 0;

    if ($t[$i][0])
    {
        while ($t[$i+1][0])
        {
            $a = $t[$i][0];
            $b = $t[$i+1][0];
            $q = int( $a / $b );
            $r = $a - $q * $b;
            $t[$i+2][0] = $r;
            $t[$i+2][1] = $t[$i][1] - $t[$i+1][1] * $q;
            $t[$i+2][2] = $t[$i][2] - $t[$i+1][2] * $q;
            $t[$i+1][3] = $q;
#           printf("[ %6d, %6d, %6d, %6d ]\n", @{$t[$i+1]});
            $i++;
        }
    }
    else
    {
        $t[$i][0] = $t[$i+1][0];
        $t[$i][1] = 0;
        $t[$i][2] = 1;
    }

#   printf("[ %6d, %6d, %6d, %6d ]\n", @{$t[$i+1]});

#   print "\nGCD1( $t[0][0], $t[1][0] ) = ", $t[$i][0], "\n";

    if ($t[$i][0] == $c)
    {print "ok $n\n";} else {print "not ok $n\n";warn "#1: $t[$i][0] != $c\n";} # 1
    $n++;

    $z->GCD($x,$y);

    $xx = $x->to_Dec();
    $yy = $y->to_Dec();
    $zz = $z->to_Dec();

#   printf("GCD2( %s, %s ) = %s\n", $xx, $yy, $zz);

    if ($zz == $c)
    {print "ok $n\n";} else {print "not ok $n\n";warn "#2: $zz != $c\n";} # 2
    $n++;

    $z->GCD($v,$w,$x,$y);

    $xx = $x->to_Dec();
    $yy = $y->to_Dec();
    $zz = $z->to_Dec();

    $vv = $v->to_Dec();
    $ww = $w->to_Dec();

#   printf("GCD3( %s, %s ) = %s\n", $xx, $yy, $zz);

    if ($zz == $c)
    {print "ok $n\n";} else {print "not ok $n\n";warn "#3: $zz != $c\n";} # 3
    $n++;

    $v->Multiply($v,$x);
    $w->Multiply($w,$y);
    $u->add($v,$w,0);

    $uu = $u->to_Dec();

#   printf("\n%d * %d + %d * %d = %d\n",
#       $t[$i][1],  $t[0][0],
#       $t[$i][2],  $t[1][0],
#       $t[$i][1] * $t[0][0] +
#       $t[$i][2] * $t[1][0]);

    if (($t[$i][1] * $t[0][0] + $t[$i][2] * $t[1][0]) == $c)
    {print "ok $n\n";} else {print "not ok $n\n";warn "#4: $t[$i][1] * $t[0][0] + $t[$i][2] * $t[1][0] != $c\n";} # 4
    $n++;

    if ($t[$i][1] == $d)
    {print "ok $n\n";} else {print "not ok $n\n";warn "#5: $t[$i][1] != $d\n";} # 5
    $n++;

    if ($t[$i][2] == $e)
    {print "ok $n\n";} else {print "not ok $n\n";warn "#6: $t[$i][2] != $e\n";} # 6
    $n++;

#   printf("%s * %s + %s * %s = %s\n\n", $vv, $xx, $ww, $yy, $uu);

    if ($uu == $c)
    {print "ok $n\n";} else {print "not ok $n\n";warn "#7: $uu != $c\n";} # 7
    $n++;

    if ($vv == $d)
    {print "ok $n\n";} else {print "not ok $n\n";warn "#8: $vv != $d\n";} # 8
    $n++;

    if ($ww == $e)
    {print "ok $n\n";} else {print "not ok $n\n";warn "#9: $ww != $e\n";} # 9
    $n++;
}

gcd(      0,      0,      0,      0,      1 );

gcd(      0,      1,      1,      0,      1 );
gcd(      1,      0,      1,      1,      0 );
gcd(      0,     -1,     -1,      0,      1 );
gcd(     -1,      0,     -1,      1,      0 );

gcd(      0,      2,      2,      0,      1 );
gcd(      2,      0,      2,      1,      0 );
gcd(      0,     -2,     -2,      0,      1 );
gcd(     -2,      0,     -2,      1,      0 );

gcd(      0,      3,      3,      0,      1 );
gcd(      3,      0,      3,      1,      0 );
gcd(      0,     -3,     -3,      0,      1 );
gcd(     -3,      0,     -3,      1,      0 );

gcd(      1,      1,      1,      0,      1 );
gcd(      1,     -1,     -1,      0,      1 );
gcd(     -1,      1,      1,      0,      1 );
gcd(     -1,     -1,     -1,      0,      1 );

gcd(      1,      2,      1,      1,      0 );
gcd(      2,      1,      1,      0,      1 );
gcd(     -1,      2,     -1,      1,      0 );
gcd(      2,     -1,     -1,      0,      1 );
gcd(      1,     -2,      1,      1,      0 );
gcd(     -2,      1,      1,      0,      1 );
gcd(     -1,     -2,     -1,      1,      0 );
gcd(     -2,     -1,     -1,      0,      1 );

gcd(      2,      3,      1,     -1,      1 );
gcd(      3,      2,      1,      1,     -1 );
gcd(     -2,      3,      1,      1,      1 );
gcd(      3,     -2,      1,      1,      1 );
gcd(      2,     -3,     -1,      1,      1 );
gcd(     -3,      2,     -1,      1,      1 );
gcd(     -2,     -3,     -1,     -1,      1 );
gcd(     -3,     -2,     -1,      1,     -1 );

gcd(      3,      5,      1,      2,     -1 );
gcd(      5,      3,      1,     -1,      2 );
gcd(     -3,      5,     -1,      2,      1 );
gcd(      5,     -3,     -1,      1,      2 );
gcd(      3,     -5,      1,      2,      1 );
gcd(     -5,      3,      1,      1,      2 );
gcd(     -3,     -5,     -1,      2,     -1 );
gcd(     -5,     -3,     -1,     -1,      2 );

gcd(      5,      7,      1,      3,     -2 );
gcd(      7,      5,      1,     -2,      3 );
gcd(     -5,      7,     -1,      3,      2 );
gcd(      7,     -5,     -1,      2,      3 );
gcd(      5,     -7,      1,      3,      2 );
gcd(     -7,      5,      1,      2,      3 );
gcd(     -5,     -7,     -1,      3,     -2 );
gcd(     -7,     -5,     -1,     -2,      3 );

gcd(      6,     30,      6,      1,      0 );
gcd(     30,      6,      6,      0,      1 );
gcd(     -6,     30,     -6,      1,      0 );
gcd(     30,     -6,     -6,      0,      1 );
gcd(      6,    -30,      6,      1,      0 );
gcd(    -30,      6,      6,      0,      1 );
gcd(     -6,    -30,     -6,      1,      0 );
gcd(    -30,     -6,     -6,      0,      1 );

gcd(   2322,      0,   2322,      1,      0 );
gcd(      0,    654,    654,      0,      1 );
gcd(  -2322,      0,  -2322,      1,      0 );
gcd(      0,   -654,   -654,      0,      1 );

gcd(   2322,    654,      6,     20,    -71 );
gcd(   2322,   -654,      6,     20,     71 );
gcd(  -2322,    654,     -6,     20,     71 );
gcd(  -2322,   -654,     -6,     20,    -71 );
gcd(    654,   2322,      6,    -71,     20 );
gcd(    654,  -2322,     -6,     71,     20 );
gcd(   -654,   2322,      6,     71,     20 );
gcd(   -654,  -2322,     -6,    -71,     20 );

gcd(  12345,  54321,      3,   3617,   -822 );
gcd(  12345, -54321,      3,   3617,    822 );
gcd( -12345,  54321,     -3,   3617,    822 );
gcd( -12345, -54321,     -3,   3617,   -822 );
gcd(  54321,  12345,      3,   -822,   3617 );
gcd(  54321, -12345,     -3,    822,   3617 );
gcd( -54321,  12345,      3,    822,   3617 );
gcd( -54321, -12345,     -3,   -822,   3617 );

__END__

