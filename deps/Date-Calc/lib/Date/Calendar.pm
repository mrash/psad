
###############################################################################
##                                                                           ##
##    Copyright (c) 2000 - 2009 by Steffen Beyer.                            ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

package Date::Calendar;

BEGIN { eval { require bytes; }; }
use strict;
use vars qw( @ISA @EXPORT @EXPORT_OK $VERSION );

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw();

@EXPORT_OK = qw();

$VERSION = '6.3';

use Carp::Clan qw(^Date::);
use Date::Calc::Object qw(:ALL);
use Date::Calendar::Year qw( check_year empty_period );

sub new
{
    my($class)    = shift;
    my($profile)  = shift;
    my($language) = shift || 0;
    my($self);

    $self = [ ];
    $class = ref($class) || $class || 'Date::Calendar';
    bless($self, $class);
    $self->[0] = { };
    $self->[1] = $profile;
    $self->[2] = $language;
    $self->[3] = [@_];
    return $self;
}

sub year
{
    my($self) = shift;
    my($year) = shift_year(\@_);

    &check_year($year);
    if (defined $self->[0]{$year})
    {
        return $self->[0]{$year};
    }
    else
    {
        return $self->[0]{$year} =
            Date::Calendar::Year->new( $year, $self->[1], $self->[2], @{$self->[3]} );
    }
}

sub cache_keys
{
    my($self) = shift;

    return( sort {$a<=>$b} keys(%{$self->[0]}) );
}

sub cache_vals
{
    my($self) = shift;
    local($_);

    return( map $self->[0]{$_}, sort {$a<=>$b} keys(%{$self->[0]}) );
}

sub cache_clr
{
    my($self) = shift;

    $self->[0] = { };
}

sub cache_add
{
    my($self) = shift;
    my($year);

    while (@_)
    {
        $year = shift_year(\@_);
        $self->year($year);
    }
}

sub cache_del
{
    my($self) = shift;
    my($year);

    while (@_)
    {
        $year = shift_year(\@_);
        if (exists $self->[0]{$year})
        {
            delete $self->[0]{$year};
        }
    }
}

sub date2index
{
    my($self) = shift;
    my(@date) = shift_date(\@_);

    return $self->year($date[0])->date2index(@date);
}

sub labels
{
    my($self) = shift;
    my($year);
    my(@date);
    my(%result);

    if (@_)
    {
        @date = shift_date(\@_);
        return $self->year($date[0])->labels(@date);
    }
    else
    {
        local($_);
        %result = ();
        foreach $year (keys(%{$self->[0]}))
        {
            grep( $result{$_} = 0, $self->year($year)->labels() );
        }
        return wantarray ? (keys %result) : scalar(keys %result);
    }
}

sub search
{
    my($self,$pattern) = @_;
    my($year);
    my(@result);

    @result = ();
    foreach $year (sort {$a<=>$b} keys(%{$self->[0]}))
    {
        push( @result, $self->year($year)->search($pattern) );
    }
    return wantarray ? (@result) : scalar(@result);
}

sub tags
{
    my($self) = shift;
    my(%result) = ();
    my(@date);

    if (@_)
    {
        @date = shift_date(\@_);
        return $self->year($date[0])->tags(@date);
    }
    else { return \%result; }
}

sub delta_workdays
{
    my($self)                   =  shift;
    my($yy1,$mm1,$dd1)          =  shift_date(\@_);
    my($yy2,$mm2,$dd2)          =  shift_date(\@_);
    my($including1,$including2) = (shift,shift);
    my($days,$empty,$year);

    $days = 0;
    $empty = 1;
    if ($yy1 == $yy2)
    {
        return $self->year($yy1)->delta_workdays(
            $yy1,$mm1,$dd1, $yy2,$mm2,$dd2, $including1,$including2);
    }
    elsif ($yy1 < $yy2)
    {
        unless (($mm1 == 12) && ($dd1 == 31) && (!$including1))
        {
            $days += $self->year($yy1)->delta_workdays(
                $yy1,$mm1,$dd1, $yy1,12,31, $including1,1);
            $empty = 0;
        }
        unless (($mm2 ==  1) && ($dd2 ==  1) && (!$including2))
        {
            $days += $self->year($yy2)->delta_workdays(
                $yy2, 1, 1, $yy2,$mm2,$dd2, 1,$including2);
            $empty = 0;
        }
        for ( $year = $yy1 + 1; $year < $yy2; $year++ )
        {
            $days += $self->year($year)->delta_workdays(
                $year,1,1, $year,12,31, 1,1);
            $empty = 0;
        }
    }
    else
    {
        unless (($mm2 == 12) && ($dd2 == 31) && (!$including2))
        {
            $days -= $self->year($yy2)->delta_workdays(
                $yy2,$mm2,$dd2, $yy2,12,31, $including2,1);
            $empty = 0;
        }
        unless (($mm1 ==  1) && ($dd1 ==  1) && (!$including1))
        {
            $days -= $self->year($yy1)->delta_workdays(
                $yy1, 1, 1, $yy1,$mm1,$dd1, 1,$including1);
            $empty = 0;
        }
        for ( $year = $yy2 + 1; $year < $yy1; $year++ )
        {
            $days -= $self->year($year)->delta_workdays(
                $year,1,1, $year,12,31, 1,1);
            $empty = 0;
        }
    }
    &empty_period() if ($empty);
    return $days;
}

sub add_delta_workdays
{
    my($self)       = shift;
    my($yy,$mm,$dd) = shift_date(\@_);
    my($days)       = shift;
    my($date,$rest,$sign);

    if ($days == 0)
    {
        $rest = $self->year($yy)->date2index($yy,$mm,$dd); # check date
        $date = Date::Calc->new($yy,$mm,$dd);
        return wantarray ? ($date,$days) : $date;
    }
    else
    {
        $sign = ($days > 0) ? +1 : -1;
        ($date,$rest,$sign) = $self->year($yy)->add_delta_workdays($yy,$mm,$dd,$days,$sign);
        while ($sign)
        {
            ($date,$rest,$sign) = $self->year($date)->add_delta_workdays($date,$rest,$sign);
        }
        return wantarray ? ($date,$rest) : $date;
    }
}

sub is_full
{
    my($self) = shift;
    my(@date) = shift_date(\@_);
    my($year) = $self->year($date[0]);

    return $year->vec_full->bit_test( $year->date2index(@date) );
}

sub is_half
{
    my($self) = shift;
    my(@date) = shift_date(\@_);
    my($year) = $self->year($date[0]);

    return $year->vec_half->bit_test( $year->date2index(@date) );
}

sub is_work
{
    my($self) = shift;
    my(@date) = shift_date(\@_);
    my($year) = $self->year($date[0]);

    return $year->vec_work->bit_test( $year->date2index(@date) );
}

1;

__END__

