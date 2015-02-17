#!perl -w

use strict;
no strict "vars";

use Bit::Vector::Overload;

# ======================================================================
#   $carry_out = $vector->rotate_left();
#   $carry_out = $vector->rotate_right();
#   $carry_out = $vector->shift_left($carry_in);
#   $carry_out = $vector->shift_right($carry_in);
#   $vector->Move_Left($bits);
#   $vector->Move_Right($bits);
# ======================================================================
#   $vec1 = $vec2->Shadow();
#   $vec1 = $vec2->Clone();
# ======================================================================

print "1..36416\n";

$n = 1;

foreach $limit (15,16,31,32,63,64,127,128,255,256,511,512,1023,1024)
{
    $ref = Bit::Vector->new($limit);

    $ref->Fill();
    $ref->Bit_Off(0);
    $ref->Bit_Off(1);
    for ( $j = 4; $j < $limit; $j += 2 ) { $ref->Bit_Off($j); }
    for ( $i = 3; ($j = $i * $i) < $limit; $i += 2 )
    {
        for ( ; $j < $limit; $j += $i ) { $ref->Bit_Off($j); }
    }

    $rol = $ref->Clone();
    $ror = $ref->Clone();
    $shl = $ref->Clone();
    $shr = $ref->Clone();

    $crl = $rol->Shadow();
    $crr = $ror->Shadow();
    $csl = $shl->Shadow();
    $csr = $shr->Shadow();

    &test_rotat_reg_same(0);
    &test_shift_reg_same(0);
    &test_rotat_carry_same(1);
    &test_shift_carry_same(1);

    for ( $i = 0; $i < $limit; $i++ )
    {
        $crl->shift_left ( $rol->rotate_left () );
        $crr->shift_right( $ror->rotate_right() );
        $csl->shift_left ( $shl->shift_left  ( $shl->bit_test($limit-1) ) );
        $csr->shift_right( $shr->shift_right ( $shr->bit_test(0)        ) );

        if (($i == 0) || ($i == ($limit-2)))
        {
            &test_rotat_reg_same(1);
            &test_shift_reg_same(1);
            &test_rotat_carry_same(1);
            &test_shift_carry_same(1);
            &test_rotat_reg_diff;
            &test_rotat_carry_diff if ($i);
            &test_shift_reg_diff;
            &test_shift_carry_diff if ($i);
        }
    }

    &test_rotat_reg_same(0);
    &test_shift_reg_same(0);
    &test_rotat_carry_same(0);
    &test_shift_carry_same(0);
}

$ref = Bit::Vector->new(1);
$Minimum = $ref->Min();
$Maximum = $ref->Max();

if ($Minimum >= 32767)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($Maximum <= -32767)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

foreach $limit (15,16,31,32,63,64,127,128,1023,1024)
{
    $ref = Bit::Vector->new($limit);

    for ( $bits = -2; $bits <= $limit + 1; $bits++ )
    {
        $ref->Fill();
        $vec = ($ref << $bits);
        $ref->Move_Left($bits);
        $norm_ = $limit - $bits;
        $min_ = $bits;
        $max_ = $limit - 1;
        if (($norm_ <= 0) || ($bits < 0))
        {
            $norm_ = 0;
            $min_ = $Minimum;
            $max_ = $Maximum;
        }
        &verify;

        if ($vec->equal($ref))
        {print "ok $n\n";} else {print "not ok $n\n";}
        $n++;
        $vec->Fill();
        $vec <<= $bits;
        if ($vec->equal($ref))
        {print "ok $n\n";} else {print "not ok $n\n";}
        $n++;

        $ref->Fill();
        $vec = ($ref >> $bits);
        $ref->Move_Right($bits);
        $norm_ = $limit - $bits;
        $min_ = 0;
        $max_ = $limit - $bits - 1;
        if (($norm_ <= 0) || ($bits < 0))
        {
            $norm_ = 0;
            $min_ = $Minimum;
            $max_ = $Maximum;
        }
        &verify;

        if ($vec->equal($ref))
        {print "ok $n\n";} else {print "not ok $n\n";}
        $n++;
        $vec->Fill();
        $vec >>= $bits;
        if ($vec->equal($ref))
        {print "ok $n\n";} else {print "not ok $n\n";}
        $n++;
    }
}

exit;

sub test_rotat_reg_same
{
    my($flag) = @_;

    if (($ref->equal($rol)) ^ $flag)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    if (($ref->equal($ror)) ^ $flag)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

sub test_shift_reg_same
{
    my($flag) = @_;

    if (($ref->equal($shl)) ^ $flag)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    if (($ref->equal($shr)) ^ $flag)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

sub test_rotat_carry_same
{
    my($flag) = @_;

    if (($ref->equal($crl)) ^ $flag)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    if (($ref->equal($crr)) ^ $flag)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

sub test_shift_carry_same
{
    my($flag) = @_;

    if (($ref->equal($csl)) ^ $flag)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    if (($ref->equal($csr)) ^ $flag)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

sub test_rotat_reg_diff
{
    unless ($rol->equal($ror))
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

sub test_rotat_carry_diff
{
    unless ($crl->equal($crr))
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

sub test_shift_reg_diff
{
    unless ($shl->equal($shr))
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

sub test_shift_carry_diff
{
    unless ($csl->equal($csr))
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

sub verify
{
    $norm = $ref->Norm();
    if ($norm == $norm_)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    unless (($min,$max) = $ref->Interval_Scan_inc(0))
    {
        $min = $ref->Min();
        $max = $ref->Max();
    }
    if ($min == $min_)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if ($max == $max_)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    unless (($min,$max) = $ref->Interval_Scan_dec($limit-1))
    {
        $min = $ref->Min();
        $max = $ref->Max();
    }
    if ($min == $min_)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if ($max == $max_)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

__END__

