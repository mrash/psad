
###############################################################################
##                                                                           ##
##    Copyright (c) 2000 - 2009 by Steffen Beyer.                            ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

package Date::Calendar::Year;

BEGIN { eval { require bytes; }; }
use strict;
use vars qw( @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION );

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw();

@EXPORT_OK = qw( check_year empty_period );

%EXPORT_TAGS = (all => [@EXPORT_OK]);

$VERSION = '6.3';

use Bit::Vector;
use Carp::Clan qw(^Date::);
use Date::Calc::Object qw(:ALL);

sub check_year
{
    my($year) = shift_year(\@_);

    if (($year < 1583) || ($year > 2299))
    {
        croak("given year ($year) out of range [1583..2299]");
    }
}

sub empty_period
{
    carp("dates interval is empty") if ($^W);
}

sub _invalid_
{
    my($item,$name) = @_;

    croak("date '$item' for day '$name' is invalid");
}

sub _check_init_date_
{
    my($item,$name,$year,$yy,$mm,$dd) = @_;

    &_invalid_($item,$name)
        unless (($year == $yy) && (check_date($yy,$mm,$dd)));
}

sub _check_callback_date_
{
    my($name,$year,$yy,$mm,$dd) = @_;

    croak("callback function for day '$name' returned invalid date")
        unless (($year == $yy) && (check_date($yy,$mm,$dd)));
}

sub _set_date_
{
    my($self,$name,$yy,$mm,$dd,$flag) = @_;
    my($type,$index);

    $type = 0;
    $flag ||= '';
    $index = $self->date2index($yy,$mm,$dd);
    if ($flag ne '#')
    {
        if ($flag eq ':') { ${$self}{'HALF'}->Bit_On( $index ); $type = 1; }
        else              { ${$self}{'FULL'}->Bit_On( $index ); $type = 2; }
    }
    $self->{'TAGS'}{$index}{$name} |= $type;
}

sub _set_fixed_date_
{
    my($self) = shift;
    my($item) = shift;
    my($name) = shift;
    my($year) = shift;
    my($lang) = shift || 0;

    if ($_[1] =~ /^[a-zA-Z]+$/)
    {
        &_invalid_($item,$name) unless ($_[1] = Decode_Month($_[1]),$lang);
    }
    &_check_init_date_($item,$name,$year,@_);
    &_set_date_($self,$name,@_);
}

sub date2index
{
    my($self)       = shift;
    my($yy,$mm,$dd) = shift_date(\@_);
    my($year,$index);

    $year = ${$self}{'YEAR'};
    if ($yy != $year)
    {
        croak("given year ($yy) != object's year ($year)");
    }
    if ((check_date($yy,$mm,$dd)) &&
        (($index = (Date_to_Days($yy,$mm,$dd) - ${$self}{'BASE'})) >= 0) &&
        ($index < ${$self}{'DAYS'}))
    {
        return $index;
    }
    else { croak("invalid date ($yy,$mm,$dd)"); }
}

sub index2date
{
    my($self,$index) = @_;
    my($year,$yy,$mm,$dd);

    $year = ${$self}{'YEAR'};
    $yy = $year;
    $mm = 1;
    $dd = 1;
    if (($index == 0) ||
        (($index > 0) &&
         ($index < ${$self}{'DAYS'}) &&
         (($yy,$mm,$dd) = Add_Delta_Days($year,1,1, $index)) &&
         ($yy == $year)))
    {
        return Date::Calc->new($yy,$mm,$dd);
    }
    else { croak("invalid index ($index)"); }
}

sub new
{
    my($class)    = shift;
    my($year)     = shift_year(\@_);
    my($profile)  = shift;
    my($lang)     = shift || 0;
    my($self);

    &check_year($year);
    $self = { };
    $class = ref($class) || $class || 'Date::Calendar::Year';
    bless($self, $class);
    $self->init($year,$profile,$lang,@_);
    return $self;
}

sub init
{
    my($self)     = shift;
    my($year)     = shift_year(\@_);
    my($profile)  = shift;
    my($lang)     = shift || 0;
    my($days,$dow,$name,$item,$flag,$temp,$n);
    my(@weekend,@easter,@date);

    if (@_ > 0) { @weekend = @_; }
    else        { @weekend = (6,7); } # Mon=1 Tue=2 Wed=3 Thu=4 Fri=5 Sat=6 Sun=7
    &check_year($year);
    croak("given profile is not a HASH ref") unless (ref($profile) eq 'HASH');
    $days = Days_in_Year($year,12);
    ${$self}{'YEAR'} = $year;
    ${$self}{'DAYS'} = $days;
    ${$self}{'BASE'} = Date_to_Days($year,1,1);
    ${$self}{'TAGS'} = { };
    ${$self}{'HALF'} = Bit::Vector->new($days);
    ${$self}{'FULL'} = Bit::Vector->new($days);
    ${$self}{'WORK'} = Bit::Vector->new($days);
    $dow = Day_of_Week($year,1,1); # Mon=1 Tue=2 Wed=3 Thu=4 Fri=5 Sat=6 Sun=7
    foreach $item (@weekend)
    {
        $n = $item || 0;
        if (($n >= 1) and ($n <= 7))
        {
            $n -= $dow;
            while ($n < 0)                                     { $n += 7; }
            while ($n < $days) { ${$self}{'FULL'}->Bit_On( $n ); $n += 7; }
        }
    }
    @easter = Easter_Sunday($year);
    $lang = Decode_Language($lang) unless ($lang =~ /^\d+$/);
    $lang = Language() unless (($lang >= 1) and ($lang <= Languages()));
    foreach $name (keys %{$profile})
    {
        @date = ();
        $item = ${$profile}{$name};
        if (ref($item))
        {
            if (ref($item) eq 'CODE')
            {
                if (@date = &$item($year,$name))
                {
                    &_check_callback_date_($name,$year,@date);
                    &_set_date_($self,$name,@date);
                }
            }
            else { croak("value for day '$name' is not a CODE ref"); }
        }
        elsif ($item =~ /^ ([#:]?) ([+-]\d+) $/x)
        {
            $flag = $1;
            $temp = $2;
            if ($temp == 0) { @date = @easter; }
            else            { @date = Add_Delta_Days(@easter, $temp); }
            &_check_init_date_($item,$name,$year,@date);
            &_set_date_($self,$name,@date,$flag);
        }
        elsif (($item =~ /^ ([#:]?) (\d+) \.  (\d+)           \.? $/x) ||
               ($item =~ /^ ([#:]?) (\d+) \.? ([a-zA-Z]+)     \.? $/x) ||
               ($item =~ /^ ([#:]?) (\d+)  -  (\d+|[a-zA-Z]+)  -? $/x))
        {
            $flag = $1;
            @date = ($year,$3,$2);
            &_set_fixed_date_($self,$item,$name,$year,$lang,@date,$flag);
        }
        elsif (($item =~ /^ ([#:]?) (\d+)       \/  (\d+) $/x) ||
               ($item =~ /^ ([#:]?) ([a-zA-Z]+) \/? (\d+) $/x))
        {
            $flag = $1;
            @date = ($year,$2,$3);
            &_set_fixed_date_($self,$item,$name,$year,$lang,@date,$flag);
        }
        elsif (($item =~ /^ ([#:]?) ([1-5])          ([a-zA-Z]+)    (\d+)           $/x) ||
               ($item =~ /^ ([#:]?) ([1-5]) \/ ([1-7]|[a-zA-Z]+) \/ (\d+|[a-zA-Z]+) $/x))
        {
            $flag = $1;
            $n    = $2;
            $dow  = $3;
            $temp = $4;
            if ($dow =~ /^[a-zA-Z]+$/)
            {
                &_invalid_($item,$name) unless ($dow = Decode_Day_of_Week($dow,$lang));
            }
            if ($temp =~ /^[a-zA-Z]+$/)
            {
                &_invalid_($item,$name) unless ($temp = Decode_Month($temp,$lang));
            }
            else
            {
                &_invalid_($item,$name) unless (($temp > 0) && ($temp < 13));
            }
            unless (@date = Nth_Weekday_of_Month_Year($year,$temp,$dow,$n))
            {
                if ($n == 5)
                {
                    &_invalid_($item,$name)
                        unless (@date = Nth_Weekday_of_Month_Year($year,$temp,$dow,4));
                }
                else { &_invalid_($item,$name); }
            }
            &_set_date_($self,$name,@date,$flag);
        }
        else
        {
            croak("unrecognized date '$item' for day '$name'");
        }
    }
    ${$self}{'HALF'}->AndNot( ${$self}{'HALF'}, ${$self}{'FULL'} );
}

sub vec_full # full holidays
{
    my($self) = @_;

    return ${$self}{'FULL'};
}

sub vec_half # half holidays
{
    my($self) = @_;

    return ${$self}{'HALF'};
}

sub vec_work # work space
{
    my($self) = @_;

    return ${$self}{'WORK'};
}

sub val_days
{
    my($self) = @_;

    return ${$self}{'DAYS'};
}

sub val_base
{
    my($self) = @_;

    return ${$self}{'BASE'};
}

sub val_year
{
    my($self) = @_;

    return ${$self}{'YEAR'};
}

sub year # as a shortcut and to enable shift_year
{
    my($self) = @_;

    return ${$self}{'YEAR'};
}

sub labels
{
    my($self) = shift;
    my(@date);
    my($index);
    my(%result);

    if (@_)
    {
        @date = shift_date(\@_);
        $index = $self->date2index(@date);
        if (defined $self->{'TAGS'}{$index})
        {
            if (defined wantarray and wantarray)
            {
                return
                (
                    Day_of_Week_to_Text(Day_of_Week(@date)),
                    keys(%{$self->{'TAGS'}{$index}})
                );
            }
            else
            {
                return 1 + scalar( keys(%{$self->{'TAGS'}{$index}}) );
            }
        }
        else
        {
            if (defined wantarray and wantarray)
            {
                return( Day_of_Week_to_Text(Day_of_Week(@date)) );
            }
            else
            {
                return 1;
            }
        }
    }
    else
    {
        local($_);
        %result = ();
        foreach $index (keys %{$self->{'TAGS'}})
        {
            grep( $result{$_} = 0, keys(%{$self->{'TAGS'}{$index}}) );
        }
        if (defined wantarray and wantarray)
        {
            return( keys %result );
        }
        else
        {
            return scalar( keys %result );
        }
    }
}

sub search
{
    my($self,$pattern) = @_;
    my($index,$label,$upper);
    my(@result);

    local($_);
    @result = ();
    $pattern = ISO_UC($pattern);
    foreach $index (keys %{$self->{'TAGS'}})
    {
        LABEL:
        foreach $label (keys %{$self->{'TAGS'}{$index}})
        {
            $upper = ISO_UC($label);
            if (index($upper,$pattern) >= $[)
            {
                push( @result, $index );
                last LABEL;
            }
        }
    }
    return( map( $self->index2date($_), sort {$a<=>$b} @result ) );
}

sub tags
{
    my($self) = shift;
    my(%result) = ();
    my($index);
    my(@date);

    if (@_ == 1 and not ref($_[0]))
    {
        $index = shift;
    }
    else
    {
        @date = shift_date(\@_);
        $index = $self->date2index(@date);
    }
    if (exists  $self->{'TAGS'}{$index} and
        defined $self->{'TAGS'}{$index})
    {
        %result = %{$self->{'TAGS'}{$index}};
    }
    return \%result;
}

sub _interval_workdays_
{
    my($self,$lower,$upper) = @_;
    my($work,$full,$half,$days);

    $work = ${$self}{'WORK'};
    $full = ${$self}{'FULL'};
    $half = ${$self}{'HALF'};
    $work->Empty();
    $work->Interval_Fill($lower,$upper);
    $work->AndNot($work,$full);
    $days = $work->Norm();
    $work->And($work,$half);
    $days -= $work->Norm() * 0.5;
    return $days;
}

sub _delta_workdays_
{
    my($self,$lower_index,$upper_index,$include_lower,$include_upper) = @_;
    my($days);

    $days = ${$self}{'DAYS'};
    if (($lower_index < 0) || ($lower_index >= $days))
    {
        croak("invalid lower index ($lower_index)");
    }
    if (($upper_index < 0) || ($upper_index >= $days))
    {
        croak("invalid upper index ($upper_index)");
    }
    if ($lower_index > $upper_index)
    {
        croak("lower index ($lower_index) > upper index ($upper_index)");
    }
    $lower_index++ unless ($include_lower);
    $upper_index-- unless ($include_upper);
    if (($upper_index < 0) ||
        ($lower_index >= $days) ||
        ($lower_index > $upper_index))
    {
        &empty_period();
        return 0;
    }
    return $self->_interval_workdays_($lower_index,$upper_index);
}

sub delta_workdays
{
    my($self)                   =  shift;
    my($yy1,$mm1,$dd1)          =  shift_date(\@_);
    my($yy2,$mm2,$dd2)          =  shift_date(\@_);
    my($including1,$including2) = (shift,shift);
    my($index1,$index2);

    $index1 = $self->date2index($yy1,$mm1,$dd1);
    $index2 = $self->date2index($yy2,$mm2,$dd2);
    if ($index1 > $index2)
    {
        return -$self->_delta_workdays_(
            $index2,$index1,$including2,$including1);
    }
    else
    {
        return $self->_delta_workdays_(
            $index1,$index2,$including1,$including2);
    }
}

sub _move_forward_
{
    my($self,$index,$rest,$sign) = @_;
    my($limit,$year,$full,$half,$loop,$min,$max);

    if ($sign == 0)
    {
        return( $self->index2date($index), $rest, 0 );
    }
    $limit = ${$self}{'DAYS'} - 1;
    $year  = ${$self}{'YEAR'};
    $full  = ${$self}{'FULL'};
    $half  = ${$self}{'HALF'};
    $loop  = 1;
    if ($sign > 0)
    {
        $rest = -$rest if ($rest < 0);
        while ($loop)
        {
            $loop = 0;
            if ($full->bit_test($index) &&
                (($min,$max) = $full->Interval_Scan_inc($index)) &&
                ($min == $index))
            {
                if ($max >= $limit)
                {
                    return( Date::Calc->new(++$year,1,1), $rest, +1 );
                }
                else { $index = $max + 1; }
            }
            if ($half->bit_test($index))
            {
                if ($rest >= 0.5) { $rest -= 0.5; $index++; $loop = 1; }
            }
            elsif  ($rest >= 1.0) { $rest -= 1.0; $index++; $loop = 1; }
            if ($loop && ($index > $limit))
            {
                return( Date::Calc->new(++$year,1,1), $rest, +1 );
            }
        }
        return( $self->index2date($index), $rest, 0 );
    }
    else # ($sign < 0)
    {
        $rest = -$rest if ($rest > 0);
        while ($loop)
        {
            $loop = 0;
            if ($full->bit_test($index) &&
                (($min,$max) = $full->Interval_Scan_dec($index)) &&
                ($max == $index))
            {
                if ($min <= 0)
                {
                    return( Date::Calc->new(--$year,12,31), $rest, -1 );
                }
                else { $index = $min - 1; }
            }
            if ($half->bit_test($index))
            {
                if ($rest <= -0.5) { $rest += 0.5; $index--; $loop = 1; }
            }
            elsif  ($rest <= -1.0) { $rest += 1.0; $index--; $loop = 1; }
            if ($loop && ($index < 0))
            {
                return( Date::Calc->new(--$year,12,31), $rest, -1 );
            }
        }
        return( $self->index2date($index), $rest, 0 );
    }
}

sub add_delta_workdays
{
    my($self)       = shift;
    my($yy,$mm,$dd) = shift_date(\@_);
    my($days)       = shift;
    my($sign)       = shift;
    my($index,$full,$half,$limit,$diff,$guess);

    $index = $self->date2index($yy,$mm,$dd); # check date
    if ($sign == 0)
    {
        return( Date::Calc->new($yy,$mm,$dd), $days, 0 );
    }
    $days = -$days if ($days < 0);
    if ($days < 2) # other values possible for fine-tuning optimal speed
    {
        return( $self->_move_forward_($index,$days,$sign) );
    }
    # else sufficiently large distance
    $full = ${$self}{'FULL'};
    $half = ${$self}{'HALF'};
    if ($sign > 0)
    {
        # First, check against whole rest of year:
        $limit = ${$self}{'DAYS'} - 1;
        $diff = $self->_interval_workdays_($index,$limit);
        if ($days >= $diff)
        {
            $days -= $diff;
            return( Date::Calc->new(++$yy,1,1), $days, +1 );
        }
        # else ($days < $diff)
        # Now calculate proportional jump (approximatively):
        $guess = $index + int($days * ($limit-$index+1) / $diff);
        $guess = $limit if ($guess > $limit);
        if ($index + 2 > $guess) # again, other values possible for fine-tuning
        {
            return( $self->_move_forward_($index,$days,+1) );
        }
        # else sufficiently long jump
        $diff = $self->_interval_workdays_($index,$guess-1);
        while ($days < $diff) # reverse gear (jumped too far)
        {
            $guess--;
            unless ($full->bit_test($guess))
            {
                if ($half->bit_test($guess)) { $diff -= 0.5; }
                else                         { $diff -= 1.0; }
            }
        }
        # Now move in original direction:
        $days -= $diff;
        return( $self->_move_forward_($guess,$days,+1) );
    }
    else # ($sign < 0)
    {
        # First, check against whole rest of year:
        $limit = 0;
        $diff = $self->_interval_workdays_($limit,$index);
        if ($days >= $diff)
        {
            $days -= $diff;
            return( Date::Calc->new(--$yy,12,31), -$days, -1 );
        }
        # else ($days < $diff)
        # Now calculate proportional jump (approximatively):
        $guess = $index - int($days * ($index+1) / $diff);
        $guess = $limit if ($guess < $limit);
        if ($guess > $index - 2) # again, other values possible for fine-tuning
        {
            return( $self->_move_forward_($index,-$days,-1) );
        }
        # else sufficiently long jump
        $diff = $self->_interval_workdays_($guess+1,$index);
        while ($days < $diff) # reverse gear (jumped too far)
        {
            $guess++;
            unless ($full->bit_test($guess))
            {
                if ($half->bit_test($guess)) { $diff -= 0.5; }
                else                         { $diff -= 1.0; }
            }
        }
        # Now move in original direction:
        $days -= $diff;
        return( $self->_move_forward_($guess,-$days,-1) );
    }
}

sub is_full
{
    my($self) = shift;
    my(@date) = shift_date(\@_);

    return $self->vec_full->bit_test( $self->date2index(@date) );
}

sub is_half
{
    my($self) = shift;
    my(@date) = shift_date(\@_);

    return $self->vec_half->bit_test( $self->date2index(@date) );
}

sub is_work
{
    my($self) = shift;
    my(@date) = shift_date(\@_);

    return $self->vec_work->bit_test( $self->date2index(@date) );
}

1;

__END__

