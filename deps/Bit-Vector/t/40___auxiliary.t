#!perl -w

use strict;
no strict "vars";

use Bit::Vector::String;

my @l = (31,32,33,127,128,129,1023,1024,1025);

my($b,$i,$n,$r,$s,$t,$u,$v,$w,$x);

print "1..", @l * 81, "\n";

$n = 1;

# -------------------------------------------------------

foreach $b (@l)
{
    $v = Bit::Vector->new($b);
    $w = Bit::Vector->new($b);

    for ( $i = 0; $i < 3; $i++ )
    {
        if    ($i == 0) { $v->Primes(); }
        elsif ($i == 1) { $v->Fill(); }
        else
        {
            $v->Empty();
            for ( $x = 0; $x < $b; $x += 12 ) { $v->Bit_On($x); }
            if ($v->to_Oct() =~ /^[01]+$/)
            {print "ok $n\n";} else {print "not ok $n\n";}
            $n++;
            if ($v->to_Hex() =~ /^[01]+$/)
            {print "ok $n\n";} else {print "not ok $n\n";}
            $n++;
        }

# =======================================================

        $x = '$w->from_Oct( $s = $v->to_Oct() );';

        $t = 2;
        $r = 'OCT';
        $w->from_Oct( $s = $v->to_Oct() );
        if ($v->equal($w))
        {print "ok $n\n";} else {print "not ok $n\n";trace($b,$r,$s,$t,$v,$w,$x);}
        $n++;

        $x = '$t = $w->String_Import( $s = $v->String_Export( $r ) );';

        $t = $w->String_Import( $s = $v->String_Export( $r = 'bin' ) );
        if ($v->equal($w))
        {print "ok $n\n";} else {print "not ok $n\n";trace($b,$r,$s,$t,$v,$w,$x);}
        $n++;

        $t = $w->String_Import( $s = $v->String_Export( $r = 'oct' ) );
        if ($v->equal($w))
        {print "ok $n\n";} else {print "not ok $n\n";trace($b,$r,$s,$t,$v,$w,$x);}
        $n++;

        $t = $w->String_Import( $s = $v->String_Export( $r = 'hex' ) );
        if ($v->equal($w))
        {print "ok $n\n";} else {print "not ok $n\n";trace($b,$r,$s,$t,$v,$w,$x);}
        $n++;

        $t = $w->String_Import( $s = $v->String_Export( $r = 'dec' ) );
        if ($v->equal($w))
        {print "ok $n\n";} else {print "not ok $n\n";trace($b,$r,$s,$t,$v,$w,$x);}
        $n++;

        $t = $w->String_Import( $s = $v->String_Export( $r = 'enum' ) );
        if ($v->equal($w))
        {print "ok $n\n";} else {print "not ok $n\n";trace($b,$r,$s,$t,$v,$w,$x);}
        $n++;

        $t = $w->String_Import( $s = $v->String_Export( $r = 'pack' ) );
        if ($v->equal($w))
        {print "ok $n\n";} else {print "not ok $n\n";trace($b,$r,$s,$t,$v,$w,$x);}
        $n++;

# =======================================================

        $x = '$t = $w->String_Import( $s = $v->to_Type() );';

        $r = 'bin';
        $t = $w->String_Import( $s = $v->to_Bin() );
        if ($v->equal($w))
        {print "ok $n\n";} else {print "not ok $n\n";trace($b,$r,$s,$t,$v,$w,$x);}
        $n++;

        if ($i < 2)
        {
            $r = 'oct';
            $t = $w->String_Import( $s = $v->to_Oct() );
            if ($v->equal($w))
            {print "ok $n\n";} else {print "not ok $n\n";trace($b,$r,$s,$t,$v,$w,$x);}
            $n++;

            $r = 'hex';
            $t = $w->String_Import( $s = $v->to_Hex() );
            if ($v->equal($w))
            {print "ok $n\n";} else {print "not ok $n\n";trace($b,$r,$s,$t,$v,$w,$x);}
            $n++;
        }

        $r = 'dec';
        $t = $w->String_Import( $s = $v->to_Dec() );
        if ($v->equal($w))
        {print "ok $n\n";} else {print "not ok $n\n";trace($b,$r,$s,$t,$v,$w,$x);}
        $n++;

        $r = 'enum';
        $t = $w->String_Import( $s = $v->to_Enum() );
        if ($v->equal($w))
        {print "ok $n\n";} else {print "not ok $n\n";trace($b,$r,$s,$t,$v,$w,$x);}
        $n++;

        $r = 'pack';
        $t = $w->String_Import( $s = ':' . $v->Size(). ':' . $v->Block_Read() );
        if ($v->equal($w))
        {print "ok $n\n";} else {print "not ok $n\n";trace($b,$r,$s,$t,$v,$w,$x);}
        $n++;

# =======================================================

        $x = '$w = Bit::Vector->new_Oct( $b, $s = $v->to_Oct() );';

        $t = 2;
        $r = 'OCT';
        $w = Bit::Vector->new_Oct( $b, $s = $v->to_Oct() );
        if ($v->equal($w))
        {print "ok $n\n";} else {print "not ok $n\n";trace($b,$r,$s,$t,$v,$w,$x);}
        $n++;

        $x = '($w,$t) = Bit::Vector->new_String( $b, $s = $v->String_Export( $r ) );';

        ($w,$t) = Bit::Vector->new_String( $b, $s = $v->String_Export( $r = 'bin' ) );
        if ($v->equal($w))
        {print "ok $n\n";} else {print "not ok $n\n";trace($b,$r,$s,$t,$v,$w,$x);}
        $n++;

        ($w,$t) = Bit::Vector->new_String( $b, $s = $v->String_Export( $r = 'oct' ) );
        if ($v->equal($w))
        {print "ok $n\n";} else {print "not ok $n\n";trace($b,$r,$s,$t,$v,$w,$x);}
        $n++;

        ($w,$t) = Bit::Vector->new_String( $b, $s = $v->String_Export( $r = 'hex' ) );
        if ($v->equal($w))
        {print "ok $n\n";} else {print "not ok $n\n";trace($b,$r,$s,$t,$v,$w,$x);}
        $n++;

        ($w,$t) = Bit::Vector->new_String( $b, $s = $v->String_Export( $r = 'dec' ) );
        if ($v->equal($w))
        {print "ok $n\n";} else {print "not ok $n\n";trace($b,$r,$s,$t,$v,$w,$x);}
        $n++;

        ($w,$t) = Bit::Vector->new_String( $b, $s = $v->String_Export( $r = 'enum' ) );
        if ($v->equal($w))
        {print "ok $n\n";} else {print "not ok $n\n";trace($b,$r,$s,$t,$v,$w,$x);}
        $n++;

        ($w,$t) = Bit::Vector->new_String( $b, $s = $v->String_Export( $r = 'pack' ) );
        if ($v->equal($w))
        {print "ok $n\n";} else {print "not ok $n\n";trace($b,$r,$s,$t,$v,$w,$x);}
        $n++;

# =======================================================

        $x = '$w = Bit::Vector->new_Oct( undef, $s = $v->to_Oct() );';

        $t = 2;
        $r = 'OCT';
        $w = Bit::Vector->new_Oct( undef, $s = $v->to_Oct() );
        $w->Resize($b) if ($w->Size() != $b);
        if ($v->equal($w))
        {print "ok $n\n";} else {print "not ok $n\n";trace($b,$r,$s,$t,$v,$w,$x);}
        $n++;

        $x = '($w,$t) = Bit::Vector->new_String( undef, $s = $v->String_Export( $r ) );';

        ($w,$t) = Bit::Vector->new_String( undef, $s = $v->String_Export( $r = 'bin' ) );
        $w->Resize($b) if ($w->Size() != $b);
        if ($v->equal($w))
        {print "ok $n\n";} else {print "not ok $n\n";trace($b,$r,$s,$t,$v,$w,$x);}
        $n++;

        ($w,$t) = Bit::Vector->new_String( undef, $s = $v->String_Export( $r = 'oct' ) );
        $w->Resize($b) if ($w->Size() != $b);
        if ($v->equal($w))
        {print "ok $n\n";} else {print "not ok $n\n";trace($b,$r,$s,$t,$v,$w,$x);}
        $n++;

        ($w,$t) = Bit::Vector->new_String( undef, $s = $v->String_Export( $r = 'hex' ) );
        $w->Resize($b) if ($w->Size() != $b);
        if ($v->equal($w))
        {print "ok $n\n";} else {print "not ok $n\n";trace($b,$r,$s,$t,$v,$w,$x);}
        $n++;

        ($w,$t) = Bit::Vector->new_String( undef, $s = $v->String_Export( $r = 'dec' ) );
        if ($w->Size() != $b)
        {
            if ($v->msb and $w->Size() < $b) # needs sign extension when increasing size
            {
                $u = $w;
                $w = Bit::Vector->new($b);
                $w->Copy($u);
            }
            else { $w->Resize($b); }
        }
        if ($v->equal($w))
        {print "ok $n\n";} else {print "not ok $n\n";trace($b,$r,$s,$t,$v,$w,$x);}
        $n++;

        ($w,$t) = Bit::Vector->new_String( undef, $s = $v->String_Export( $r = 'enum' ) );
        $w->Resize($b) if ($w->Size() != $b);
        if ($v->equal($w))
        {print "ok $n\n";} else {print "not ok $n\n";trace($b,$r,$s,$t,$v,$w,$x);}
        $n++;

        ($w,$t) = Bit::Vector->new_String( undef, $s = $v->String_Export( $r = 'pack' ) );
        $w->Resize($b) if ($w->Size() != $b);
        if ($v->equal($w))
        {print "ok $n\n";} else {print "not ok $n\n";trace($b,$r,$s,$t,$v,$w,$x);}
        $n++;

# =======================================================

    } # for ( $i = 0; $i < 3; $i++ )

} # foreach $b (@l)

# -------------------------------------------------------

sub type
{
    return 'bin'  if ($_[0] == 1);
    return 'oct'  if ($_[0] == 2);
    return 'dec'  if ($_[0] == 3);
    return 'hex'  if ($_[0] == 4);
    return 'enum' if ($_[0] == 5);
    return 'pack' if ($_[0] == 6);
    return undef;
}

sub trace
{
    my($b,$r,$s,$t,$v,$w,$x) = @_;

    warn( "$x\n" );
    warn( "$r, $b bits\n" );
    warn( type($t) . ": <$s>\n" );
    warn( "v = <" . $v->to_Hex() . ">\n" );
    warn( "w = <" . $w->to_Hex() . ">\n" );
}

__END__

