
###############################################################################
##                                                                           ##
##    Copyright (c) 2000 - 2009 by Steffen Beyer.                            ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

###############################################################################
##                                                                           ##
## Mottos of this module:                                                    ##
##                                                                           ##
## 1) Small is beautiful.                                                    ##
##                                                                           ##
## 2) Make frequent things easy and infrequent or hard things possible.      ##
##                                                                           ##
###############################################################################

package Date::Calc::Object;

BEGIN { eval { require bytes; }; }
use strict;
use vars qw(@ISA @AUXILIARY @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Carp::Clan qw(^Date::);

BEGIN # Re-export imports from Date::Calc:
{
    require Exporter;
    require Date::Calc;
    @ISA         = qw(Exporter Date::Calc);
    @AUXILIARY   = qw(shift_year shift_date shift_time shift_datetime);
    @EXPORT      = @Date::Calc::EXPORT;
    @EXPORT_OK   = (@Date::Calc::EXPORT_OK,@AUXILIARY);
    %EXPORT_TAGS = (all => [@Date::Calc::EXPORT_OK],
                    aux => [@AUXILIARY],
                    ALL => [@EXPORT_OK]);
    $VERSION     = '6.3';
    Date::Calc->import(@Date::Calc::EXPORT,@Date::Calc::EXPORT_OK);
}

sub shift_year
{
    croak("internal error - parameter is not an ARRAY ref") if (ref($_[0]) ne 'ARRAY');

    if (ref($_[0][0]))
    {
        if (ref($_[0][0]) eq 'ARRAY')
        {
            if (@{$_[0][0]} == 3) # otherwise anonymous array is pointless
            {
                return ${shift(@{$_[0]})}[0];
            }
            else
            {
                croak("wrong number of elements in date constant");
            }
        }
        elsif (ref($_[0][0]) =~ /[^:]::[^:]/)
        {
            return shift(@{$_[0]})->year();
        }
        else
        {
            croak("input parameter is neither ARRAY ref nor object");
        }
    }
    else
    {
        if (@{$_[0]} >= 1)
        {
            return shift(@{$_[0]});
        }
        else
        {
            croak("not enough input parameters for a year");
        }
    }
}

sub shift_date
{
    croak("internal error - parameter is not an ARRAY ref") if (ref($_[0]) ne 'ARRAY');

    if (ref($_[0][0]))
    {
        if (ref($_[0][0]) eq 'ARRAY')
        {
            if (@{$_[0][0]} == 3)
            {
                return( @{shift(@{$_[0]})} );
            }
            else
            {
                croak("wrong number of elements in date constant");
            }
        }
        elsif (ref($_[0][0]) =~ /[^:]::[^:]/)
        {
            return( shift(@{$_[0]})->date() );
        }
        else
        {
            croak("input parameter is neither ARRAY ref nor object");
        }
    }
    else
    {
        if (@{$_[0]} >= 3)
        {
            return( shift(@{$_[0]}), shift(@{$_[0]}), shift(@{$_[0]}) );
        }
        else
        {
            croak("not enough input parameters for a date");
        }
    }
}

sub shift_time
{
    croak("internal error - parameter is not an ARRAY ref") if (ref($_[0]) ne 'ARRAY');

    if (ref($_[0][0]))
    {
        if (ref($_[0][0]) eq 'ARRAY')
        {
            if (@{$_[0][0]} == 3)
            {
                return( @{shift(@{$_[0]})} );
            }
            else
            {
                croak("wrong number of elements in time constant");
            }
        }
        elsif (ref($_[0][0]) =~ /[^:]::[^:]/)
        {
            return( (shift(@{$_[0]})->datetime())[3,4,5] );
        }
        else
        {
            croak("input parameter is neither ARRAY ref nor object");
        }
    }
    else
    {
        if (@{$_[0]} >= 3)
        {
            return( shift(@{$_[0]}), shift(@{$_[0]}), shift(@{$_[0]}) );
        }
        else
        {
            croak("not enough input parameters for time values");
        }
    }
}

sub shift_datetime
{
    croak("internal error - parameter is not an ARRAY ref") if (ref($_[0]) ne 'ARRAY');

    if (ref($_[0][0]))
    {
        if (ref($_[0][0]) eq 'ARRAY')
        {
            if (@{$_[0][0]} == 6)
            {
                return( @{shift(@{$_[0]})} );
            }
            else
            {
                croak("wrong number of elements in date-time constant");
            }
        }
        elsif (ref($_[0][0]) =~ /[^:]::[^:]/)
        {
            return( shift(@{$_[0]})->datetime() );
        }
        else
        {
            croak("input parameter is neither ARRAY ref nor object");
        }
    }
    else
    {
        if (@{$_[0]} >= 6)
        {
            return( shift(@{$_[0]}), shift(@{$_[0]}), shift(@{$_[0]}),
                    shift(@{$_[0]}), shift(@{$_[0]}), shift(@{$_[0]}) );
        }
        else
        {
            croak("not enough input parameters for a date and time");
        }
    }
}

package Date::Calc;

use strict;

use Carp::Clan qw(^Date::);

use overload
      '0+' => 'number',
      '""' => 'string',
    'bool' => 'is_valid',
     'neg' => '_unary_minus_',
     'abs' => 'number',
     '<=>' => '_compare_date_',
     'cmp' => '_compare_date_time_',
      '==' => '_equal_date_',
      '!=' => '_not_equal_date_',
      'eq' => '_equal_date_time_',
      'ne' => '_not_equal_date_time_',
       '+' => '_plus_',
       '-' => '_minus_',
      '+=' => '_plus_equal_',
      '-=' => '_minus_equal_',
      '++' => '_increment_',
      '--' => '_decrement_',
       'x' => '_times_',
      'x=' => '_times_equal_',
       '=' => 'clone',
'nomethod' => 'OVERLOAD', # equivalent of AUTOLOAD ;-)
'fallback' =>  undef;

# Report unimplemented overloaded operators:

sub OVERLOAD
{
    croak("operator '$_[3]' is unimplemented");
}

# Prevent nearly infinite loops:

sub _times_
{
    $_[3] = 'x';
    goto &OVERLOAD;
}

sub _times_equal_
{
    $_[3] = 'x=';
    goto &OVERLOAD;
}

my $ACCURATE_MODE = 1;
my $NORMALIZED_MODE = 0; # disabled by default for backward compatibility
my $NUMBER_FORMAT = 0;
my $DELTA_FORMAT = 0;
my $DATE_FORMAT = 0;

sub accurate_mode
{
    my($flag) = $ACCURATE_MODE;

    if (@_ > 1)
    {
        $ACCURATE_MODE = $_[1] || 0;
    }
    return $flag;
}

sub normalized_mode
{
    my($flag) = $NORMALIZED_MODE;

    if (@_ > 1)
    {
        $NORMALIZED_MODE = $_[1] || 0;
    }
    return $flag;
}

sub number_format
{
    my($flag) = $NUMBER_FORMAT;

    if (@_ > 1)
    {
        $NUMBER_FORMAT = $_[1] || 0;
    }
    return $flag;
}

sub delta_format
{
    my($self) = shift;
    my($flag);

    if (ref $self) # object method
    {
        $flag = defined($self->[0][1]) ? $self->[0][1] : undef;
        if (@_ > 0)
        {
            $self->[0][1] = defined($_[0]) ? $_[0] : undef;
        }
    }
    else           # class method
    {
        $flag = $DELTA_FORMAT;
        if (@_ > 0)
        {
            $DELTA_FORMAT = $_[0] || 0;
        }
    }
    return $flag;
}

sub date_format
{
    my($self) = shift;
    my($flag);

    if (ref $self) # object method
    {
        $flag = defined($self->[0][2]) ? $self->[0][2] : undef;
        if (@_ > 0)
        {
            $self->[0][2] = defined($_[0]) ? $_[0] : undef;
        }
    }
    else           # class method
    {
        $flag = $DATE_FORMAT;
        if (@_ > 0)
        {
            $DATE_FORMAT = $_[0] || 0;
        }
    }
    return $flag;
}

sub language
{
    my($self) = shift;
    my($lang,$temp);

    eval
    {
        if (ref $self) # object method
        {
            $lang = defined($self->[0][3]) ? Language_to_Text($self->[0][3]) : undef;
            if (@_ > 0)
            {
                if (defined $_[0])
                {
                    $temp = $_[0];
                    if ($temp !~ /^\d+$/)
                        { $temp = Decode_Language($temp); }
                    if ($temp >= 1 and $temp <= Languages())
                        { $self->[0][3] = $temp; }
                    else
                        { croak "no such language '$_[0]'"; }
                }
                else { $self->[0][3] = undef; }
            }
        }
        else           # class method
        {
            $lang = Language_to_Text(Language());
            if (@_ > 0)
            {
                $temp = $_[0];
                if ($temp !~ /^\d+$/)
                    { $temp = Decode_Language($temp); }
                if ($temp >= 1 and $temp <= Languages())
                    { Language($temp); }
                else
                    { croak "no such language '$_[0]'"; }
            }
        }
    };
    if ($@)
    {
        $@ =~ s!^.*[A-Za-z0-9_]+(?:::[A-Za-z0-9_]+)*\(\):\s*!!;
        $@ =~ s!\s+at\s+\S.*\s*$!!;
        croak($@);
    }
    return $lang;
}

sub is_delta
{
    my($self) = @_;
    my($bool) = undef;

    eval
    {
        if (defined($self->[0]) and
            ref($self->[0]) eq 'ARRAY' and
            defined($self->[0][0]))
        { $bool = ($self->[0][0] ? 1 : 0); }
    };
    if ($@) { $@ =~ s!\s+at\s+\S.*\s*$!!; croak($@); }
    return $bool;
}

sub is_date
{
    my($self) = @_;
    my($bool) = undef;

    eval
    {
        if (defined($self->[0]) and
            ref($self->[0]) eq 'ARRAY' and
            defined($self->[0][0]))
        { $bool = ($self->[0][0] ? 0 : 1); }
    };
    if ($@) { $@ =~ s!\s+at\s+\S.*\s*$!!; croak($@); }
    return $bool;
}

sub is_short
{
    my($self) = @_;
    my($bool) = undef;

    eval
    {
        if    (@{$self} == 4) { $bool = 1; }
        elsif (@{$self} == 7) { $bool = 0; }
    };
    if ($@) { $@ =~ s!\s+at\s+\S.*\s*$!!; croak($@); }
    return $bool;
}

sub is_long
{
    my($self) = @_;
    my($bool) = undef;

    eval
    {
        if    (@{$self} == 7) { $bool = 1; }
        elsif (@{$self} == 4) { $bool = 0; }
    };
    if ($@) { $@ =~ s!\s+at\s+\S.*\s*$!!; croak($@); }
    return $bool;
}

sub is_valid
{
    my($self) = @_;
    my($bool);

    $bool = eval
    {
        if (defined($self->[0]) and
            ref($self->[0]) eq 'ARRAY' and
            @{$self->[0]} > 0 and
            defined($self->[0][0]) and
            not ref($self->[0][0]) and
            ($self->[0][0] == 0 or $self->[0][0] == 1) and
            (@{$self} == 4 or @{$self} == 7))
        {
            if ($self->[0][0]) # is_delta
            {
                return 0 unless
                (
                    defined($self->[1]) and not ref($self->[1]) and
                    defined($self->[2]) and not ref($self->[2]) and
                    defined($self->[3]) and not ref($self->[3])
                );
                if (@{$self} > 4) # is_long
                {
                    return 0 unless
                    (
                        defined($self->[4]) and not ref($self->[4]) and
                        defined($self->[5]) and not ref($self->[5]) and
                        defined($self->[6]) and not ref($self->[6])
                    );
                }
                return 1;
            }
            else # is_date
            {
                return 0 unless
                (
                    defined($self->[1]) and not ref($self->[1]) and
                    defined($self->[2]) and not ref($self->[2]) and
                    defined($self->[3]) and not ref($self->[3]) and
                    check_date(@{$self}[1..3])
                );
                if (@{$self} > 4) # is_long
                {
                    return 0 unless
                    (
                        defined($self->[4]) and not ref($self->[4]) and
                        defined($self->[5]) and not ref($self->[5]) and
                        defined($self->[6]) and not ref($self->[6]) and
                        check_time(@{$self}[4..6])
                    );
                }
                return 1;
            }
        }
        return undef;
    };
    if ($@) { $@ =~ s!\s+at\s+\S.*\s*$!!; croak($@); }
    return $bool;
}

sub normalize
{
    my($self) = shift;
    my($quot);

    if ($self->is_valid())
    {
        if ($self->is_delta())
        {
            if ($self->is_long())
            {
                splice( @{$self}, 3, 4, Normalize_DHMS(@{$self}[3..6]) );
            }
            unless ($ACCURATE_MODE) # YMD_MODE or N_YMD_MODE
            {
                if ($self->[2] and ($quot = int($self->[2] / 12)))
                {
                    $self->[1] += $quot;
                    $self->[2] -= $quot * 12;
                }
                if
                (
                    $self->[2] < 0 and
                  ( $self->[3] > 0 or
                    $self->[4] > 0 or
                    $self->[5] > 0 or
                    $self->[6] > 0 )
                )
                {
                    $self->[1]--;
                    $self->[2] += 12;
                }
                elsif
                (
                    $self->[2] > 0 and
                  ( $self->[3] < 0 or
                    $self->[4] < 0 or
                    $self->[5] < 0 or
                    $self->[6] < 0 )
                )
                {
                    $self->[1]++;
                    $self->[2] -= 12;
                }
            }
        }
        else
        {
            carp("normalizing a date is a no-op") if ($^W);
        }
    }
    return $self;
}

sub new
{
    my($class,$list,$type,$self);

    if (@_)
    {
        $class = shift;
        if (@_ == 1 and ref($_[0]) eq 'ARRAY') { $list = $_[0]; } else { $list = \@_; }
    }
    croak("wrong number of arguments")
        unless (defined($list) and
        (@$list == 0 or @$list == 1 or @$list == 3 or @$list == 4 or @$list == 6 or @$list == 7));
    if (@$list == 1 or @$list == 4 or @$list == 7)
    {
        $type = (shift(@$list) ? 1 : 0);
        $self = [ [$type], @$list ];
    }
    elsif (@$list == 3 or @$list == 6)
    {
        $self = [ [0], @$list ];
    }
    else
    {
        $self = [ [] ];
    }
    bless($self, ref($class) || $class || 'Date::Calc');
    return $self;
}

sub clone
{
    my($self) = @_;
    my($this);

    croak("invalid date/time") unless ($self->is_valid());
    $this = $self->new();
    @{$this} = @{$self};
    $this->[0] = [];
    @{$this->[0]} = @{$self->[0]};
    return $this;
}

sub copy
{
    my($self) = shift;
    my($this);

    eval
    {
        if (@_ == 1 and ref($_[0])) { $this = $_[0]; } else { $this = \@_; }
        @{$self} = @{$this};
        $self->[0] = [];
        if (defined $this->[0])
        {
            if (ref($this->[0]) eq 'ARRAY') { @{$self->[0]} = @{$this->[0]}; }
            else                            { $self->[0][0] = $this->[0]; }
        }
    };
    if ($@) { $@ =~ s!\s+at\s+\S.*\s*$!!; croak($@); }
    croak("invalid date/time") unless ($self->is_valid());
    return $self;
}

sub date
{
    my($self,$list);

    if (@_)
    {
        $self = shift;
        if (@_ == 1 and ref($_[0]) eq 'ARRAY') { $list = $_[0]; } else { $list = \@_; }
    }
    croak("wrong number of arguments")
        unless (defined($list) and
        (@$list == 0 or @$list == 1 or @$list == 3 or @$list == 4 or @$list == 6 or @$list == 7));
    eval
    {
        if (@$list == 1 or @$list == 4 or @$list == 7)
        {
            $self->[0][0] = (shift(@$list) ? 1 : 0);
        }
        if (@$list == 3 or @$list == 6)
        {
            splice( @{$self}, 1, scalar(@$list), @$list );
        }
    };
    if ($@) { $@ =~ s!\s+at\s+\S.*\s*$!!; croak($@); }
    croak("invalid date/time") unless ($self->is_valid());
    return (@{$self}[1..3]);
}

sub time
{
    my($self,$list);

    if (@_)
    {
        $self = shift;
        if (@_ == 1 and ref($_[0]) eq 'ARRAY') { $list = $_[0]; } else { $list = \@_; }
    }
    croak("wrong number of arguments")
        unless (defined($list) and
        (@$list == 0 or @$list == 1 or @$list == 3 or @$list == 4));
    eval
    {
        if (@$list == 1 or @$list == 4)
        {
            $self->[0][0] = (shift(@$list) ? 1 : 0);
        }
        if (@$list == 3)
        {
            splice( @{$self}, 4, 3, @$list );
        }
    };
    if ($@) { $@ =~ s!\s+at\s+\S.*\s*$!!; croak($@); }
    croak("invalid date/time") unless ($self->is_valid());
    if (@{$self} == 7) { return (@{$self}[4..6]); }
    else               { return (); }
}

sub datetime
{
    my($self,$list);

    if (@_)
    {
        $self = shift;
        if (@_ == 1 and ref($_[0]) eq 'ARRAY') { $list = $_[0]; } else { $list = \@_; }
    }
    croak("wrong number of arguments")
        unless (defined($list) and
        (@$list == 0 or @$list == 1 or @$list == 3 or @$list == 4 or @$list == 6 or @$list == 7));
    eval
    {
        if (@$list == 1 or @$list == 4 or @$list == 7)
        {
            $self->[0][0] = (shift(@$list) ? 1 : 0);
        }
        if (@$list == 3)
        {
            splice( @{$self}, 1, 6, @$list, 0,0,0 );
        }
        elsif (@$list == 6)
        {
            splice( @{$self}, 1, 6, @$list );
        }
    };
    if ($@) { $@ =~ s!\s+at\s+\S.*\s*$!!; croak($@); }
    croak("invalid date/time") unless ($self->is_valid());
    if (@{$self} == 7) { return (@{$self}[1..6]); }
    else               { return (@{$self}[1..3],0,0,0); }
}

sub today
{
    my($self) = shift;
    my($gmt)  = shift || 0;

    if (ref $self) # object method
    {
        $self->date( 0, Today($gmt) );
        return $self;
    }
    else           # class method
    {
        $self ||= 'Date::Calc';
        return $self->new( 0, Today($gmt) );
    }
}

sub now
{
    my($self) = shift;
    my($gmt)  = shift || 0;

    if (ref $self) # object method
    {
        $self->time( 0, Now($gmt) );
        return $self;
    }
    else           # class method
    {
        $self ||= 'Date::Calc';
        return $self->new( 0, Today_and_Now($gmt) );
    }
}

sub today_and_now
{
    my($self) = shift;
    my($gmt)  = shift || 0;

    if (ref $self) # object method
    {
        $self->date( 0, Today_and_Now($gmt) );
        return $self;
    }
    else           # class method
    {
        $self ||= 'Date::Calc';
        return $self->new( 0, Today_and_Now($gmt) );
    }
}

sub gmtime
{
    my($self) = shift;
    my(@date);

    eval
    {
        @date = (Gmtime(@_))[0..5];
    };
    if ($@)
    {
        $@ =~ s!^.*[A-Za-z0-9_]+(?:::[A-Za-z0-9_]+)*\(\):\s*!!;
        $@ =~ s!\s+at\s+\S.*\s*$!!;
        croak($@);
    }
    if (ref $self) # object method
    {
        $self->date( 0, @date );
        return $self;
    }
    else           # class method
    {
        $self ||= 'Date::Calc';
        return $self->new( 0, @date );
    }
}

sub localtime
{
    my($self) = shift;
    my(@date);

    eval
    {
        @date = (Localtime(@_))[0..5];
    };
    if ($@)
    {
        $@ =~ s!^.*[A-Za-z0-9_]+(?:::[A-Za-z0-9_]+)*\(\):\s*!!;
        $@ =~ s!\s+at\s+\S.*\s*$!!;
        croak($@);
    }
    if (ref $self) # object method
    {
        $self->date( 0, @date );
        return $self;
    }
    else           # class method
    {
        $self ||= 'Date::Calc';
        return $self->new( 0, @date );
    }
}

sub mktime
{
    my($self) = @_;
    my($time);

    if (ref $self) # object method
    {
        croak("invalid date/time")            unless ($self->is_valid());
        croak("can't mktime from a delta vector") if ($self->is_delta()); # add [1970,1,1,0,0,0] first!
        eval
        {
            $time = Mktime( $self->datetime() );
        };
        if ($@)
        {
            $@ =~ s!^.*[A-Za-z0-9_]+(?:::[A-Za-z0-9_]+)*\(\):\s*!!;
            $@ =~ s!\s+at\s+\S.*\s*$!!;
            croak($@);
        }
        return $time;
    }
    else           # class method
    {
        return CORE::time();
    }
}

sub tzoffset
{
    my($self) = shift;
    my(@diff);

    eval
    {
        @diff = (Timezone(@_))[0..5];
    };
    if ($@)
    {
        $@ =~ s!^.*[A-Za-z0-9_]+(?:::[A-Za-z0-9_]+)*\(\):\s*!!;
        $@ =~ s!\s+at\s+\S.*\s*$!!;
        croak($@);
    }
    if (ref $self) # object method
    {
        $self->date( 1, @diff );
        return $self;
    }
    else           # class method
    {
        $self ||= 'Date::Calc';
        return $self->new( 1, @diff );
    }
}

sub date2time
{
    my($self) = @_;
    my($time);

    if (ref $self) # object method
    {
        croak("invalid date/time")               unless ($self->is_valid());
        croak("can't make time from a delta vector") if ($self->is_delta()); # add [1970,1,1,0,0,0] first!
        eval
        {
            $time = Date_to_Time( $self->datetime() );
        };
        if ($@)
        {
            $@ =~ s!^.*[A-Za-z0-9_]+(?:::[A-Za-z0-9_]+)*\(\):\s*!!;
            $@ =~ s!\s+at\s+\S.*\s*$!!;
            croak($@);
        }
        return $time;
    }
    else           # class method
    {
        return CORE::time();
    }
}

sub time2date
{
    my($self) = shift;
    my(@date);

    eval
    {
        @date = Time_to_Date(@_);
    };
    if ($@)
    {
        $@ =~ s!^.*[A-Za-z0-9_]+(?:::[A-Za-z0-9_]+)*\(\):\s*!!;
        $@ =~ s!\s+at\s+\S.*\s*$!!;
        croak($@);
    }
    if (ref $self) # object method
    {
        $self->date( 0, @date );
        return $self;
    }
    else           # class method
    {
        $self ||= 'Date::Calc';
        return $self->new( 0, @date );
    }
}

sub year
{
    my($self) = shift;

    if (@_ > 0)
    {
        eval { $self->[1] = $_[0] || 0; };
        if ($@) { $@ =~ s!\s+at\s+\S.*\s*$!!; croak($@); }
    }
    croak("invalid date/time") unless ($self->is_valid());
    return $self->[1];
}

sub month
{
    my($self) = shift;

    if (@_ > 0)
    {
        eval { $self->[2] = $_[0] || 0; };
        if ($@) { $@ =~ s!\s+at\s+\S.*\s*$!!; croak($@); }
    }
    croak("invalid date/time") unless ($self->is_valid());
    return $self->[2];
}

sub day
{
    my($self) = shift;

    if (@_ > 0)
    {
        eval { $self->[3] = $_[0] || 0; };
        if ($@) { $@ =~ s!\s+at\s+\S.*\s*$!!; croak($@); }
    }
    croak("invalid date/time") unless ($self->is_valid());
    return $self->[3];
}

sub hours
{
    my($self) = shift;

    if (@_ > 0)
    {
        eval
        {
            if (@{$self} == 4)
            {
                $self->[4] = 0;
                $self->[5] = 0;
                $self->[6] = 0;
            }
            if (@{$self} == 7)
            {
                $self->[4] = $_[0] || 0;
            }
        };
        if ($@) { $@ =~ s!\s+at\s+\S.*\s*$!!; croak($@); }
    }
    croak("invalid date/time") unless ($self->is_valid());
    if (@{$self} == 7) { return $self->[4]; }
    else               { return undef; }
}

sub minutes
{
    my($self) = shift;

    if (@_ > 0)
    {
        eval
        {
            if (@{$self} == 4)
            {
                $self->[4] = 0;
                $self->[5] = 0;
                $self->[6] = 0;
            }
            if (@{$self} == 7)
            {
                $self->[5] = $_[0] || 0;
            }
        };
        if ($@) { $@ =~ s!\s+at\s+\S.*\s*$!!; croak($@); }
    }
    croak("invalid date/time") unless ($self->is_valid());
    if (@{$self} == 7) { return $self->[5]; }
    else               { return undef; }
}

sub seconds
{
    my($self) = shift;

    if (@_ > 0)
    {
        eval
        {
            if (@{$self} == 4)
            {
                $self->[4] = 0;
                $self->[5] = 0;
                $self->[6] = 0;
            }
            if (@{$self} == 7)
            {
                $self->[6] = $_[0] || 0;
            }
        };
        if ($@) { $@ =~ s!\s+at\s+\S.*\s*$!!; croak($@); }
    }
    croak("invalid date/time") unless ($self->is_valid());
    if (@{$self} == 7) { return $self->[6]; }
    else               { return undef; }
}

###############################
##                           ##
##    Selector constants     ##
##    for formatting         ##
##    callback functions:    ##
##                           ##
###############################
##                           ##
##    IS_SHORT   =  0x00;    ##
##    IS_LONG    =  0x01;    ##
##    IS_DATE    =  0x00;    ##
##    IS_DELTA   =  0x02;    ##
##    TO_NUMBER  =  0x00;    ##
##    TO_STRING  =  0x04;    ##
##                           ##
###############################

sub number
{
    my($self,$format) = @_;
    my($number,$sign,@temp);

    if ($self->is_valid())
    {
        eval
        {
            $format = $NUMBER_FORMAT unless (defined $format); # because of overloading!
            if ($self->[0][0]) # is_delta
            {
#               carp("returning a fictitious number of days for delta vector")
#                   if ((($self->[1] != 0) or ($self->[2] != 0)) and $^W);
                if (@{$self} == 4) # is_short
                {
                    if (ref($format) eq 'CODE')
                    {
                        $number = &{$format}( $self, 0x02 ); # = TO_NUMBER | IS_DELTA | IS_SHORT
                    }
                    else
                    {
                        $number = ($self->[1]*12+$self->[2])*31+$self->[3];
                    }
                }
                else # is_long
                {
                    if (ref($format) eq 'CODE')
                    {
                        $number = &{$format}( $self, 0x03 ); # = TO_NUMBER | IS_DELTA | IS_LONG
                    }
                    elsif ($format == 2)
                    {
                        $number = ($self->[1]*12+$self->[2])*31+$self->[3] +
                            ((($self->[4]*60+$self->[5])*60+$self->[6])/86400);
                    }
                    else
                    {
                        local($_);
                        $sign = 0;
                        @temp = @{$self}[3..6];
                        $temp[0] += ($self->[1] * 12 + $self->[2]) * 31;
                        @temp = map( $_ < 0 ? $sign = -$_ : $_, Normalize_DHMS(@temp) );
                        $number = sprintf( "%s%d.%02d%02d%02d", $sign ? '-' : '', @temp );
                    }
                }
            }
            else # is_date
            {
                if (@{$self} == 4) # is_short
                {
                    if (ref($format) eq 'CODE')
                    {
                        $number = &{$format}( $self, 0x00 ); # = TO_NUMBER | IS_DATE | IS_SHORT
                    }
                    elsif ($format == 2 or $format == 1)
                    {
                        $number = Date_to_Days( @{$self}[1..3] );
                    }
                    else
                    {
                        $number = sprintf( "%04d%02d%02d",
                            @{$self}[1..3] );
                    }
                }
                else # is_long
                {
                    if (ref($format) eq 'CODE')
                    {
                        $number = &{$format}( $self, 0x01 ); # = TO_NUMBER | IS_DATE | IS_LONG
                    }
                    elsif ($format == 2)
                    {
                        $number = Date_to_Days( @{$self}[1..3] ) +
                            ((($self->[4]*60+$self->[5])*60+$self->[6])/86400);
                    }
                    elsif ($format == 1)
                    {
                        $number = Date_to_Days( @{$self}[1..3] ) .
                            sprintf( ".%02d%02d%02d", @{$self}[4..6] );
                    }
                    else
                    {
                        $number = sprintf( "%04d%02d%02d.%02d%02d%02d",
                            @{$self}[1..6] );
                    }
                }
            }
        };
        if ($@)
        {
            $@ =~ s!^.*[A-Za-z0-9_]+(?:::[A-Za-z0-9_]+)*\(\):\s*!!;
            $@ =~ s!\s+at\s+\S.*\s*$!!;
            croak($@);
        }
        return $number;
    }
    return undef;
}

sub string
{
    my($self,$format,$lang) = @_;
    my($restore,$string);

    if ($self->is_valid())
    {
        if (defined($lang) and $lang ne '') # because of overloading!
        {
            $lang = Decode_Language($lang) unless ($lang =~ /^\d+$/);
        }
        else
        {
            if (defined $self->[0][3]) { $lang = $self->[0][3]; }
            else                       { $lang = Language(); }
        }
        croak "no such language '$lang'" unless ($lang >= 1 and $lang <= Languages());
        eval
        {
            if ($self->[0][0]) # is_delta
            {
                $format = defined($self->[0][1]) ? $self->[0][1] : $DELTA_FORMAT
                    unless (defined $format); # because of overloading!
                if (@{$self} == 4) # is_short
                {
                    if (ref($format) eq 'CODE')
                    {
                        $string = &{$format}( $self, 0x06, $lang ); # = TO_STRING | IS_DELTA | IS_SHORT
                    }
                    elsif ($format == 4)
                    {
                        $string = '(' . join(',', @{$self}[1..3]) . ')';
                    }
                    elsif ($format == 3)
                    {
                        $string = sprintf( "%+d Y %+d M %+d D",
                            @{$self}[1..3] );
                    }
                    elsif ($format == 2)
                    {
                        $string = sprintf( "%+dY %+dM %+dD",
                            @{$self}[1..3] );
                    }
                    elsif ($format == 1)
                    {
                        $string = sprintf( "%+d %+d %+d",
                            @{$self}[1..3] );
                    }
                    else
                    {
                        $string = sprintf( "%+d%+d%+d",
                            @{$self}[1..3] );
                    }
                }
                else # is_long
                {
                    if (ref($format) eq 'CODE')
                    {
                        $string = &{$format}( $self, 0x07, $lang ); # = TO_STRING | IS_DELTA | IS_LONG
                    }
                    elsif ($format == 4)
                    {
                        $string = '(' . join(',', @{$self}[1..6]) . ')';
                    }
                    elsif ($format == 3)
                    {
                        $string = sprintf( "%+d Y %+d M %+d D %+d h %+d m %+d s",
                            @{$self}[1..6] );
                    }
                    elsif ($format == 2)
                    {
                        $string = sprintf( "%+dY %+dM %+dD %+dh %+dm %+ds",
                            @{$self}[1..6] );
                    }
                    elsif ($format == 1)
                    {
                        $string = sprintf( "%+d %+d %+d %+d %+d %+d",
                            @{$self}[1..6] );
                    }
                    else
                    {
                        $string = sprintf( "%+d%+d%+d%+d%+d%+d",
                            @{$self}[1..6] );
                    }
                }
            }
            else # is_date
            {
                $format = defined($self->[0][2]) ? $self->[0][2] : $DATE_FORMAT
                    unless (defined $format); # because of overloading!
                if (@{$self} == 4) # is_short
                {
                    if (ref($format) eq 'CODE')
                    {
                        $string = &{$format}( $self, 0x04, $lang ); # = TO_STRING | IS_DATE | IS_SHORT
                    }
                    elsif ($format == 4)
                    {
                        $string = '[' . join(',', @{$self}[1..3]) . ']';
                    }
                    elsif ($format == 3)
                    {
                        $string = Date_to_Text_Long( @{$self}[1..3], $lang );
                    }
                    elsif ($format == 2)
                    {
                        $string = Date_to_Text( @{$self}[1..3], $lang );
                    }
                    elsif ($format == 1)
                    {
                        $string = sprintf( "%02d-%.3s-%04d",
                            $self->[3],
                            Month_to_Text($self->[2],$lang),
                            $self->[1] );
                    }
                    else
                    {
                        $string = sprintf( "%04d%02d%02d",
                            @{$self}[1..3] );
                    }
                }
                else # is_long
                {
                    if (ref($format) eq 'CODE')
                    {
                        $string = &{$format}( $self, 0x05, $lang ); # = TO_STRING | IS_DATE | IS_LONG
                    }
                    elsif ($format == 4)
                    {
                        $string = '[' . join(',', @{$self}[1..6]) . ']';
                    }
                    elsif ($format == 3)
                    {
                        $string = Date_to_Text_Long( @{$self}[1..3], $lang ) .
                            sprintf( " %02d:%02d:%02d", @{$self}[4..6] );
                    }
                    elsif ($format == 2)
                    {
                        $string = Date_to_Text( @{$self}[1..3], $lang ) .
                            sprintf( " %02d:%02d:%02d", @{$self}[4..6] );
                    }
                    elsif ($format == 1)
                    {
                        $string = sprintf( "%02d-%.3s-%04d %02d:%02d:%02d",
                            $self->[3],
                            Month_to_Text($self->[2],$lang),
                            $self->[1],
                            @{$self}[4..6] );
                    }
                    else
                    {
                        $string = sprintf( "%04d%02d%02d%02d%02d%02d",
                            @{$self}[1..6] );
                    }
                }
            }
        };
        if ($@)
        {
            $@ =~ s!^.*[A-Za-z0-9_]+(?:::[A-Za-z0-9_]+)*\(\):\s*!!;
            $@ =~ s!\s+at\s+\S.*\s*$!!;
            croak($@);
        }
        return $string;
    }
    return undef;
}

sub _process_
{
    my($self,$this,$flag,$code) = @_;
    my($result,$val1,$val2,$len1,$len2,$last,$item);

    croak("invalid date/time") unless ($self->is_valid());
    if ($code == 0)
    {
        croak("can't apply unary minus to a date")
            unless ($self->is_delta());
        $result = $self->new();
        $result->[0][0] = $self->[0][0];
        for ( $item = 1; $item < @{$self}; $item++ )
        {
            $result->[$item] = -$self->[$item];
        }
        return $result;
    }
    if (defined $this and ref($this) =~ /[^:]::[^:]/)
    {
        croak("invalid date/time") unless ($this->is_valid());
    }
    elsif (defined $this and ref($this) eq 'ARRAY')
    {
        if (@{$this} == 3 or @{$this} == 6)
        {
            if ($code == 6)
            {
                $this = $self->new(0,@{$this});
            }
            elsif ($code == 5)
            {
                $this = $self->new($self->is_date(),@{$this});
            }
            else
            {
                $this = $self->new($self->is_delta(),@{$this});
            }
        }
        else
        {
            $this = $self->new(@{$this});
        }
        croak("invalid date/time") unless ($this->is_valid());
    }
    elsif (defined $this and not ref($this))
    {
        $this = $self->new(1,0,0,$this || 0);
        croak("invalid date/time") unless ($this->is_valid());
    }
    else { croak("illegal operand type"); }
    $val1 = $self->is_date();
    $val2 = $this->is_date();
    if ($code == 6 or $code == 5)
    {
        if ($code == 6)
        {
            croak("can't subtract a date from a delta vector")
                if ((not $val1 and $val2 and not $flag) or
                    ($val1 and not $val2 and $flag));
        }
        else
        {
            croak("can't add two dates")
                if ($val1 and $val2);
        }
        $len1 = $self->is_long();
        $len2 = $this->is_long();
        if ($len1 or $len2) { $last = 7; }
        else                { $last = 4; }
        if (defined $flag) { $result = $self->new((0) x $last); }
        else               { $result = $self; }
        if (not $val1 and not $val2)
        {
            $result->[0][0] = 1;
            for ( $item = 1; $item < $last; $item++ )
            {
                if ($code == 6)
                {
                    if ($flag)
                    {
                        $result->[$item] =
                            ($this->[$item] || 0) -
                            ($self->[$item] || 0);
                    }
                    else
                    {
                        $result->[$item] =
                            ($self->[$item] || 0) -
                            ($this->[$item] || 0);
                    }
                }
                else
                {
                    $result->[$item] =
                        ($self->[$item] || 0) +
                        ($this->[$item] || 0);
                }
            }
        }
        return ($result,$this,$val1,$val2,$len1,$len2);
    }
    elsif ($code <= 4 and $code >= 1)
    {
        croak("can't compare a date and a delta vector")
            if ($val1 xor $val2);
        if ($code >= 3)
        {
            if ($code == 4) { $last = 7; }
            else            { $last = 4; }
            $result = 1;
            ITEM:
            for ( $item = 1; $item < $last; $item++ )
            {
                if (($self->[$item] || 0) !=
                    ($this->[$item] || 0))
                { $result = 0; last ITEM; }
            }
            return $result;
        }
        else # ($code <= 2)
        {
#           croak("can't compare two delta vectors")
#               if (not $val1 and not $val2);
            if ($code == 2)
            {
                $len1 = $self->number();
                $len2 = $this->number();
            }
            else
            {
                $len1 = int($self->number());
                $len2 = int($this->number());
            }
            if ($flag) { return $len2 <=> $len1; }
            else       { return $len1 <=> $len2; }
        }
    }
    else { croak("unexpected internal error; please contact author"); }
}

sub _unary_minus_
{
    my($self,$this,$flag) = @_;

    return $self->_process_($this,$flag,0);
}

sub _compare_date_
{
    my($self,$this,$flag) = @_;

    return $self->_process_($this,$flag,1);
}

sub _compare_date_time_
{
    my($self,$this,$flag) = @_;

    return $self->_process_($this,$flag,2);
}

sub _equal_date_
{
    my($self,$this,$flag) = @_;

    return $self->_process_($this,$flag,3);
}

sub _not_equal_date_
{
    my($self,$this,$flag) = @_;

    return $self->_process_($this,$flag,3) ^ 1;
}

sub _equal_date_time_
{
    my($self,$this,$flag) = @_;

    return $self->_process_($this,$flag,4);
}

sub _not_equal_date_time_
{
    my($self,$this,$flag) = @_;

    return $self->_process_($this,$flag,4) ^ 1;
}

sub _date_time_
{
    my($self) = @_;

    if (@{$self} == 7) { return (@{$self}[1..6]); }
    else               { return (@{$self}[1..3],0,0,0); }
}

sub _add_
{
    my($result,$self,$this,$flag,$val1,$val2,$len1,$len2) = @_;

    if ($val1) # date + delta => date
    {
        if ($len1 or $len2)
        {
            if (not $ACCURATE_MODE and $NORMALIZED_MODE)
            {
                splice( @{$result}, 1, 6,
                    Add_N_Delta_YMDHMS( $self->_date_time_(),
                                        $this->_date_time_() ) );
            }
            else # ACCURATE_MODE or YMD_MODE
            {
                splice( @{$result}, 1, 6,
                    Add_Delta_YMDHMS( $self->_date_time_(),
                                      $this->_date_time_() ) );
            }
        }
        else # short
        {
            if (not $ACCURATE_MODE and $NORMALIZED_MODE)
            {
                splice( @{$result}, 1, 3,
                    Add_N_Delta_YMD( @{$self}[1..3], @{$this}[1..3] ) );
            }
            else # ACCURATE_MODE or YMD_MODE
            {
                splice( @{$result}, 1, 3,
                    Add_Delta_YMD( @{$self}[1..3], @{$this}[1..3] ) );
            }
        }
    }
    else # delta + date => date
    {
        if ($len1 or $len2)
        {
            if (not $ACCURATE_MODE and $NORMALIZED_MODE)
            {
                splice( @{$result}, 1, 6,
                    Add_N_Delta_YMDHMS( $this->_date_time_(),
                                        $self->_date_time_() ) );
            }
            else # ACCURATE_MODE or YMD_MODE
            {
                splice( @{$result}, 1, 6,
                    Add_Delta_YMDHMS( $this->_date_time_(),
                                      $self->_date_time_() ) );
            }
        }
        else # short
        {
            if (not $ACCURATE_MODE and $NORMALIZED_MODE)
            {
                splice( @{$result}, 1, 3,
                    Add_N_Delta_YMD( @{$this}[1..3], @{$self}[1..3] ) );
            }
            else # ACCURATE_MODE or YMD_MODE
            {
                splice( @{$result}, 1, 3,
                    Add_Delta_YMD( @{$this}[1..3], @{$self}[1..3] ) );
            }
        }
        carp("implicitly changed object type from delta vector to date")
            if (not defined $flag and $^W);
    }
    $result->[0][0] = 0;
}

sub _plus_
{
    my($self,$this,$flag) = @_;
    my($result,$val1,$val2,$len1,$len2);

    ($result,$this,$val1,$val2,$len1,$len2) = $self->_process_($this,$flag,5);
    if ($val1 or $val2)
    {
        $result->_add_($self,$this,$flag,$val1,$val2,$len1,$len2);
    }
    return $result;
}

sub _minus_
{
    my($self,$this,$flag) = @_;
    my($result,$val1,$val2,$len1,$len2,$temp,$item);

    ($result,$this,$val1,$val2,$len1,$len2) = $self->_process_($this,$flag,6);
    if ($val1 or $val2)
    {
        if ($val1 and $val2) # date - date => delta
        {
            if ($len1 or $len2)
            {
                if ($ACCURATE_MODE)
                {
                    if ($flag)
                    {
                        splice( @{$result}, 1, 6, 0, 0,
                            Delta_DHMS( $self->_date_time_(),
                                        $this->_date_time_() ) );
                    }
                    else
                    {
                        splice( @{$result}, 1, 6, 0, 0,
                            Delta_DHMS( $this->_date_time_(),
                                        $self->_date_time_() ) );
                    }
                }
                else # YMD_MODE or N_YMD_MODE
                {
                    if ($NORMALIZED_MODE) # N_YMD_MODE
                    {
                        if ($flag)
                        {
                            splice( @{$result}, 1, 6,
                                N_Delta_YMDHMS( $self->_date_time_(),
                                                $this->_date_time_() ) );
                        }
                        else
                        {
                            splice( @{$result}, 1, 6,
                                N_Delta_YMDHMS( $this->_date_time_(),
                                                $self->_date_time_() ) );
                        }
                    }
                    else # YMD_MODE
                    {
                        if ($flag)
                        {
                            splice( @{$result}, 1, 6,
                                Delta_YMDHMS( $self->_date_time_(),
                                              $this->_date_time_() ) );
                        }
                        else
                        {
                            splice( @{$result}, 1, 6,
                                Delta_YMDHMS( $this->_date_time_(),
                                              $self->_date_time_() ) );
                        }
                    }
                }
            }
            else # short
            {
                if ($ACCURATE_MODE)
                {
                    if ($flag)
                    {
                        splice( @{$result}, 1, 3, 0, 0,
                            Delta_Days( @{$self}[1..3], @{$this}[1..3] ) );
                    }
                    else
                    {
                        splice( @{$result}, 1, 3, 0, 0,
                            Delta_Days( @{$this}[1..3], @{$self}[1..3] ) );
                    }
                }
                else # YMD_MODE or N_YMD_MODE
                {
                    if ($NORMALIZED_MODE) # N_YMD_MODE
                    {
                        if ($flag)
                        {
                            splice( @{$result}, 1, 3,
                                N_Delta_YMD( @{$self}[1..3], @{$this}[1..3] ) );
                        }
                        else
                        {
                            splice( @{$result}, 1, 3,
                                N_Delta_YMD( @{$this}[1..3], @{$self}[1..3] ) );
                        }
                    }
                    else # YMD_MODE
                    {
                        if ($flag)
                        {
                            splice( @{$result}, 1, 3,
                                Delta_YMD( @{$self}[1..3], @{$this}[1..3] ) );
                        }
                        else
                        {
                            splice( @{$result}, 1, 3,
                                Delta_YMD( @{$this}[1..3], @{$self}[1..3] ) );
                        }
                    }
                }
            }
            carp("implicitly changed object type from date to delta vector")
                if (not defined $flag and $^W);
            $result->[0][0] = 1;
        }
        else # date - delta => date
        {
            if ($val1)
            {
                $temp = $this->new();
                $temp->[0][0] = $this->[0][0];
                for ( $item = 1; $item < @{$this}; $item++ )
                {
                    $temp->[$item] = -$this->[$item];
                }
                $result->_add_($self,$temp,$flag,$val1,$val2,$len1,$len2);
            }
            else
            {
                $temp = $self->new();
                $temp->[0][0] = $self->[0][0];
                for ( $item = 1; $item < @{$self}; $item++ )
                {
                    $temp->[$item] = -$self->[$item];
                }
                $result->_add_($temp,$this,$flag,$val1,$val2,$len1,$len2);
            }
        }
    }
    return $result;
}

sub _plus_equal_
{
    my($self,$this) = @_;

    return $self->_plus_($this,undef);
}

sub _minus_equal_
{
    my($self,$this) = @_;

    return $self->_minus_($this,undef);
}

sub _increment_
{
    my($self) = @_;

    return $self->_plus_(1,undef);
}

sub _decrement_
{
    my($self) = @_;

    return $self->_minus_(1,undef);
}

1;

__END__

