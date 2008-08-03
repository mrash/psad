#!perl

use Benchmark;
use Bit::Vector::String;

$v = Bit::Vector->new(1024);

$v->Primes();

$s = '';

$b = $v->to_Bin();
$o = $v->to_Oct();
$h = $v->to_Hex();

sub to_Bin
{
    $s = $v->to_Bin();
}

sub to_Oct
{
    $s = $v->to_Oct();
}

sub to_Hex
{
    $s = $v->to_Hex();
}

sub from_Bin
{
    $v->from_Bin($b);
}

sub from_Oct
{
    $v->from_Oct($o);
}

sub from_Hex
{
    $v->from_Hex($h);
}

timethese
(
    10000,
    {
        to_Bin => \&to_Bin,
        to_Oct => \&to_Oct,
        to_Hex => \&to_Hex
    }
);

timethese
(
    10000,
    {
        from_Bin => \&from_Bin,
        from_Oct => \&from_Oct,
        from_Hex => \&from_Hex
    }
);

__END__

