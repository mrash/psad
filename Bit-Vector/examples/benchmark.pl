#!/usr/local/bin/perl

use Benchmark;

sub init
{
    delete $INC{'Carp.pm'};
    delete $INC{'Exporter.pm'};
    delete $INC{'overload.pm'};
    delete $INC{'Bit/Vector/Overload.pm'};
    delete $INC{'Bit/Vector.pm'};
    delete $INC{'DynaLoader.pm'};
}

sub plain
{
    init();
    require Bit::Vector;
}

sub ovrld
{
    init();
    require Bit::Vector::Overload;
}

timethese
(
    100,
    {
        plain => \&plain,
        ovrld => \&ovrld
    }
);

__END__

