#!perl -w

package Bit::Vector;

use strict;

sub Pattern_Fill
{
    my($vector,$pattern,$length) = @_;
    my($size,$factor);

    $size = $vector->Size();
    $factor = int($size / $length);
    if ($size % $length) { $factor++; }
    $vector->Chunk_List_Store($length, ($pattern) x $factor);
    return $vector;
}

package main;

use strict;

use Bit::Vector;
use Benchmark;

my($i,$n);

my $b = 1024;

my(@v) = Bit::Vector->new($b,8);

$v[1]->Pattern_Fill(0x01,5);
$v[2]->Pattern_Fill(0x01,3);
$v[3]->Pattern_Fill(0x01,2);
$v[4]->Pattern_Fill(0x03,3);
$v[5]->Pattern_Fill(0x07,4);
$v[6]->Pattern_Fill(0x0F,5);
$v[7]->Fill();

for ( $i = 0; $i < 8; $i++ )
{
    $n = $v[$i]->to_Bin();
    print "\nTiming vector #$i:\n$n\n\n";
    timethese
    (
        500000,
        {
            'Norm1' => sub { $n = $v[$i]->Norm(); },
            'Norm2' => sub { $n = $v[$i]->Norm2(); },
            'Norm3' => sub { $n = $v[$i]->Norm3(); }
        }
    );
    print "<<< n = $n, b = $b, ", ( int( ($n / $b) * 1000 + 0.5 ) / 10 ), "% >>>\n";
}

__END__

