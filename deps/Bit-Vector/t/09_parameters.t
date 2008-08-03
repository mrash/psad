#!perl -w

use strict;
no strict "vars";

use Bit::Vector;

# ======================================================================
#   parameter checks
# ======================================================================

$prefix = 'Bit::Vector';

print "1..964\n";

$n = 1;

#   parameter types:

#   0  =  object reference
#   1  =  number of bits
#   2  =  index       ( 0 <=     index     <  bits )
#   3  =  offset      ( 0 <=     offset    <= bits )
#   4  =  word index  ( 0 <=     index     <  size )
#   5  =  length      ( 0 <= offset+length <= bits )
#   6  =  arbitrary (non-negative) number
#   7  =  boolean
#   8  =  string
#   9  =  chunksize
#  10  =  anything
#  11  =  rows
#  12  =  columns

#  16  =  any number of object references
#  18  =  any number of indices
#  22  =  any number of arbitrary numbers

$method_list{'Version'}             = [ ];
$method_list{'Word_Bits'}           = [ ];
$method_list{'Long_Bits'}           = [ ];
$method_list{'Create'}              = [ 10, 1 ];
$method_list{'Shadow'}              = [ 0 ];
$method_list{'Clone'}               = [ 0 ];
$method_list{'Concat'}              = [ 0, 0 ];
$method_list{'Concat_List'}         = [ 16, 16, 16, 16, 16 ];
$method_list{'Size'}                = [ 0 ];
$method_list{'Resize'}              = [ 0, 1 ];
$method_list{'Copy'}                = [ 0, 0 ];
$method_list{'Empty'}               = [ 0 ];
$method_list{'Fill'}                = [ 0 ];
$method_list{'Flip'}                = [ 0 ];
$method_list{'Primes'}              = [ 0 ];
$method_list{'Reverse'}             = [ 0, 0 ];
$method_list{'Interval_Empty'}      = [ 0, 2, 2 ];
$method_list{'Interval_Fill'}       = [ 0, 2, 2 ];
$method_list{'Interval_Flip'}       = [ 0, 2, 2 ];
$method_list{'Interval_Reverse'}    = [ 0, 2, 2 ];
$method_list{'Interval_Scan_inc'}   = [ 0, 2 ];
$method_list{'Interval_Scan_dec'}   = [ 0, 2 ];
$method_list{'Interval_Copy'}       = [ 0, 0, 2, 2, 5 ];
$method_list{'Interval_Substitute'} = [ 0, 0, 3, 5, 3, 5 ];
$method_list{'is_empty'}            = [ 0 ];
$method_list{'is_full'}             = [ 0 ];
$method_list{'equal'}               = [ 0, 0 ];
$method_list{'Lexicompare'}         = [ 0, 0 ];
$method_list{'Compare'}             = [ 0, 0 ];
$method_list{'to_Hex'}              = [ 0 ];
$method_list{'from_Hex'}            = [ 0, 8 ];
$method_list{'to_Bin'}              = [ 0 ];
$method_list{'from_Bin'}            = [ 0, 8 ];
$method_list{'to_Dec'}              = [ 0 ];
$method_list{'from_Dec'}            = [ 0, 8 ];
$method_list{'to_Enum'}             = [ 0 ];
$method_list{'from_Enum'}           = [ 0, 8 ];
$method_list{'new_Hex'}             = [ 10, 1, 8 ];
$method_list{'new_Bin'}             = [ 10, 1, 8 ];
$method_list{'new_Dec'}             = [ 10, 1, 8 ];
$method_list{'new_Enum'}            = [ 10, 1, 8 ];
$method_list{'Bit_Off'}             = [ 0, 2 ];
$method_list{'Bit_On'}              = [ 0, 2 ];
$method_list{'bit_flip'}            = [ 0, 2 ];
$method_list{'bit_test'}            = [ 0, 2 ];
$method_list{'Bit_Copy'}            = [ 0, 2, 7 ];
$method_list{'LSB'}                 = [ 0, 7 ];
$method_list{'MSB'}                 = [ 0, 7 ];
$method_list{'lsb'}                 = [ 0 ];
$method_list{'msb'}                 = [ 0 ];
$method_list{'rotate_left'}         = [ 0 ];
$method_list{'rotate_right'}        = [ 0 ];
$method_list{'shift_left'}          = [ 0, 7 ];
$method_list{'shift_right'}         = [ 0, 7 ];
$method_list{'Move_Left'}           = [ 0, 6 ];
$method_list{'Move_Right'}          = [ 0, 6 ];
$method_list{'Insert'}              = [ 0, 2, 6 ];
$method_list{'Delete'}              = [ 0, 2, 6 ];
$method_list{'increment'}           = [ 0 ];
$method_list{'decrement'}           = [ 0 ];
$method_list{'add'}                 = [ 0, 0, 0, 7 ];
$method_list{'subtract'}            = [ 0, 0, 0, 7 ];
$method_list{'Negate'}              = [ 0, 0 ];
$method_list{'Absolute'}            = [ 0, 0 ];
$method_list{'Sign'}                = [ 0 ];
$method_list{'Multiply'}            = [ 0, 0, 0 ];
$method_list{'Divide'}              = [ 0, 0, 0, 0 ];
$method_list{'GCD'}                 = [ 0, 0, 0 ];
$method_list{'Power'}               = [ 0, 0, 0 ];
$method_list{'Block_Store'}         = [ 0, 8 ];
$method_list{'Block_Read'}          = [ 0 ];
$method_list{'Word_Size'}           = [ 0 ];
$method_list{'Word_Store'}          = [ 0, 4, 6 ];
$method_list{'Word_Read'}           = [ 0, 4 ];
$method_list{'Word_List_Store'}     = [ 0, 22, 22, 22, 22, 22 ];
$method_list{'Word_List_Read'}      = [ 0 ];
$method_list{'Word_Insert'}         = [ 0, 4, 6 ];
$method_list{'Word_Delete'}         = [ 0, 4, 6 ];
$method_list{'Chunk_Store'}         = [ 0, 9, 2, 6 ];
$method_list{'Chunk_Read'}          = [ 0, 9, 2 ];
$method_list{'Chunk_List_Store'}    = [ 0, 9, 22, 22, 22, 22, 22 ];
$method_list{'Chunk_List_Read'}     = [ 0, 9 ];
$method_list{'Index_List_Remove'}   = [ 0, 18, 18, 18, 18, 18 ];
$method_list{'Index_List_Store'}    = [ 0, 18, 18, 18, 18, 18 ];
$method_list{'Index_List_Read'}     = [ 0 ];
$method_list{'Union'}               = [ 0, 0, 0 ];
$method_list{'Intersection'}        = [ 0, 0, 0 ];
$method_list{'Difference'}          = [ 0, 0, 0 ];
$method_list{'ExclusiveOr'}         = [ 0, 0, 0 ];
$method_list{'Complement'}          = [ 0, 0 ];
$method_list{'subset'}              = [ 0, 0 ];
$method_list{'Norm'}                = [ 0 ];
$method_list{'Min'}                 = [ 0 ];
$method_list{'Max'}                 = [ 0 ];
$method_list{'Multiplication'}      = [ 0, 11, 12, 0, 11, 12, 0, 11, 12 ];
$method_list{'Product'}             = [ 0, 11, 12, 0, 11, 12, 0, 11, 12 ];
$method_list{'Closure'}             = [ 0, 11, 12 ];
$method_list{'Transpose'}           = [ 0, 11, 12, 0, 11, 12 ];


foreach $method (sort keys(%method_list))
{
    $definition = $method_list{$method};
    $count = @{$definition};
    if ($count == 0)
    {
        $action = "\$dummy = ${prefix}::${method}();";
        eval "$action";
        unless ($@)
        {print "ok $n\n";} else {print "not ok $n\n";}
        $n++;
        $action = "\$dummy = ${prefix}::${method}(\$dummy);";
        eval "$action";
        unless ($@)
        {print "ok $n\n";} else {print "not ok $n\n";}
        $n++;
        $action = "\$dummy = ${prefix}::${method}(\$dummy,\$dummy);";
        $message = "Usage: ${prefix}->${method}\\(\\)";
        eval "$action";
        if ($@ =~ /$message/)
        {print "ok $n\n";} else {print "not ok $n\n";}
        $n++;
    }
    else
    {
        $action = "${prefix}::${method}(\@parameter_list);";
        $leadin = "${prefix}::${method}\\(\\): ";
        foreach $bits (1024)
        {
            &init_objects();
            &correct_values(0);
            undef @parameters;
            @parameters = @parameter_list;
            eval "$action";
            unless ($@)
            {print "ok $n\n";} else {print "not ok $n\n";}
            $n++;
            if ($objects > 1)
            {
                &init_objects();
                &correct_values(1);
                eval "$action";
                if (($method eq "Divide") or ($method eq "Power"))
                {
                    if ($@ =~ /result vector\(s\) must be distinct/)
                    {print "ok $n\n";} else {print "not ok $n\n";}
                    $n++;
                }
                else
                {
                    unless ($@)
                    {print "ok $n\n";} else {print "not ok $n\n";}
                    $n++;
                }
            }
            if ($limited)
            {
                $message = "Usage: (?:${prefix}::)?${method}\\([a-zA-Z\\[\\]_, ]+\\)";
                &refresh();
                pop(@parameter_list);
                eval "$action";
                if ($@ =~ /$message/)
                {print "ok $n\n";} else {print "not ok $n\n";}
                $n++;
                &refresh();
                push(@parameter_list,0);
                push(@parameter_list,0) if ($method eq "Create");
                eval "$action";
                if ($@ =~ /$message/)
                {print "ok $n\n";} else {print "not ok $n\n";}
                $n++;
            }
            &init_values();
            for ( $i = 0; $i < $count; $i++ )
            {
                $type = $definition->[$i];
                $type &= 0x0F;
                $values = @{$wrong_values[$type]};
                for ( $j = 0; $j < $values; $j++ )
                {
                    &refresh();
                    $parameter_list[$i] = $wrong_values[$type]->[$j];
                    $message = $leadin . $error_message[$type]->[$j];
                    eval "$action";
                    # Special cases "Copy()" and "Power()":
                    if (($n == 170) or ($n == 174) or ($n == 574) or ($n == 578))
                    {
                        unless ($@)
                        {print "ok $n\n";} else {print "not ok $n\n";}
                    }
                    else
                    {
                        if ($@ =~ /$message/)
                        {print "ok $n\n";} else {print "not ok $n\n";}
                    }
                    $n++;
                }
            }
        }
    }
}

sub refresh
{
    if ($method eq "Resize")
    {
        &init_objects();
        &correct_values(0);
    }
    else
    {
        undef @parameter_list;
        @parameter_list = @parameters;
    }
}

sub init_objects
{
    undef @vector;
    $vector[0] = Bit::Vector->new($bits);
    $vector[1] = Bit::Vector->new($bits);
    $vector[2] = Bit::Vector->new($bits);
    $vector[3] = Bit::Vector->new($bits);
    $vector[4] = Bit::Vector->new($bits);
    $vector[5] = Bit::Vector->new($bits);
    $vector[6] = Bit::Vector->new($bits);
    if ($bits > 0)
    {
        $vector[0]->Bit_On(0);
        $vector[1]->Bit_On(0);
        $vector[2]->Bit_On(0);
        $vector[3]->Bit_On(0);
        $vector[4]->Bit_On(0);
        $vector[5]->Bit_On(0);
        $vector[6]->Bit_On(0);
    }
}

sub correct_values
{
    my($flag) = @_;
    my($i,$type);

#   0  =  object reference
#   1  =  number of bits
#   2  =  index       ( 0 <=     index     <  bits )
#   3  =  offset      ( 0 <=     offset    <= bits )
#   4  =  word index  ( 0 <=     index     <  size )
#   5  =  length      ( 0 <= offset+length <= bits )
#   6  =  arbitrary (non-negative) number
#   7  =  boolean
#   8  =  string
#   9  =  chunksize
#  10  =  anything
#  11  =  rows
#  12  =  columns

    $objects = 0;
    $limited = 1;
    undef @parameter_list;
    for ( $i = 0; $i < $count; $i++ )
    {
        $type = $definition->[$i];
        if ($type >= 16) { $limited = 0; }
        $type &= 0x0F;
        if    ($type == 0)
        {
            $objects++;
            if ($flag)
            {
                $parameter_list[$i] = $vector[0];
            }
            else
            {
                $parameter_list[$i] = $vector[$i];
            }
        }
        elsif ($type == 1)
        {
            $parameter_list[$i] = ($bits << 1) | 1;
        }
        elsif ($type == 2)
        {
            $parameter_list[$i] = $bits - 1;
        }
        elsif ($type == 3)
        {
            $parameter_list[$i] = $bits;
        }
        elsif ($type == 4)
        {
            $parameter_list[$i] = $vector[0]->Word_Size() - 1;
        }
        elsif ($type == 5)
        {
            $parameter_list[$i] = $bits + 1;
        }
        elsif ($type == 6)
        {
            $parameter_list[$i] = (1 << (Bit::Vector->Word_Bits()-1)) - 1;
        }
        elsif ($type == 7)
        {
            $parameter_list[$i] = 1;
        }
        elsif ($type == 8)
        {
            $parameter_list[$i] = '1011';
        }
        elsif ($type == 9)
        {
            $parameter_list[$i] = Bit::Vector->Long_Bits();
        }
        elsif ($type == 10)
        {
            $parameter_list[$i] = 'anything';
        }
        elsif ($type == 11)
        {
            $parameter_list[$i] = int(sqrt($bits) + 0.5);
        }
        elsif ($type == 12)
        {
            $parameter_list[$i] = int(sqrt($bits) + 0.5);
        }
        else
        {
            die "internal error";
        }
    }
}

sub init_values
{
    undef @fake;
    undef @wrong_values;
    undef @error_message;

    $wrong_values[0] = [ ];
    $error_message[0] = [ ];
    $wrong_values[1] = [ ];
    $error_message[1] = [ ];
    $wrong_values[2] = [ ];
    $error_message[2] = [ ];
    $wrong_values[3] = [ ];
    $error_message[3] = [ ];
    $wrong_values[4] = [ ];
    $error_message[4] = [ ];
    $wrong_values[5] = [ ];
    $error_message[5] = [ ];
    $wrong_values[6] = [ ];
    $error_message[6] = [ ];
    $wrong_values[7] = [ ];
    $error_message[7] = [ ];
    $wrong_values[8] = [ ];
    $error_message[8] = [ ];
    $wrong_values[9] = [ ];
    $error_message[9] = [ ];
    $wrong_values[10] = [ ];
    $error_message[10] = [ ];
    $wrong_values[11] = [ ];
    $error_message[11] = [ ];
    $wrong_values[12] = [ ];
    $error_message[12] = [ ];

#   0  =  object reference
#   1  =  number of bits
#   2  =  index       ( 0 <=     index     <  bits )
#   3  =  offset      ( 0 <=     offset    <= bits )
#   4  =  word index  ( 0 <=     index     <  size )
#   5  =  length      ( 0 <= offset+length <= bits )
#   6  =  arbitrary (non-negative) number
#   7  =  boolean
#   8  =  string
#   9  =  chunksize
#  10  =  anything
#  11  =  rows
#  12  =  columns

    if ($objects > 1)
    {
        if ($method !~ /^(?:Concat(?:_List)?|Interval_(?:Copy|Substitute))$/)
        {
            push(@{$wrong_values[0]}, Bit::Vector->new($bits-1));
            push(@{$error_message[0]}, "(?:bit vector|set|matrix) size mismatch");
        }
    }

    $global = 0x000E9CE0;

    if ($method ne "Concat_List")
    {
        push(@{$wrong_values[0]}, $global);
        push(@{$error_message[0]}, "item is not a \"$prefix\" object");
    }

    $fake[0] = Bit::Vector->new($bits);
    $fake[0]->DESTROY();
    push(@{$wrong_values[0]}, $fake[0]);
    push(@{$error_message[0]}, "item is not a \"$prefix\" object");

    $fake[1] = \$global;
    bless($fake[1], $prefix);
    push(@{$wrong_values[0]}, $fake[1]);
    push(@{$error_message[0]}, "item is not a \"$prefix\" object");

#   push(@{$wrong_values[1]}, -1);
#   push(@{$error_message[1]}, "unable to allocate memory");

    push(@{$wrong_values[2]}, $bits);
    push(@{$error_message[2]}, "(?:(?:start |m(?:in|ax)imum )?index|offset) out of range");

    push(@{$wrong_values[2]}, -1);
    push(@{$error_message[2]}, "(?:(?:start |m(?:in|ax)imum )?index|offset) out of range");

    push(@{$wrong_values[3]}, $bits+1);
    push(@{$error_message[3]}, "offset out of range");

    push(@{$wrong_values[3]}, -1);
    push(@{$error_message[3]}, "offset out of range");

    push(@{$wrong_values[4]}, $vector[0]->Word_Size());
    push(@{$error_message[4]}, "offset out of range");

    push(@{$wrong_values[4]}, -1);
    push(@{$error_message[4]}, "offset out of range");

    push(@{$wrong_values[9]}, 0);
    push(@{$error_message[9]}, "chunk size out of range");

    push(@{$wrong_values[9]}, Bit::Vector->Long_Bits()+1);
    push(@{$error_message[9]}, "chunk size out of range");

    push(@{$wrong_values[9]}, -1);
    push(@{$error_message[9]}, "chunk size out of range");

    push(@{$wrong_values[11]}, 0);
    push(@{$error_message[11]}, "matrix size mismatch");

    push(@{$wrong_values[12]}, 0);
    push(@{$error_message[12]}, "matrix size mismatch");

    push(@{$wrong_values[1]}, \$global);
    push(@{$error_message[1]}, "item is not a (?:string|scalar)");

    push(@{$wrong_values[2]}, \$global);
    push(@{$error_message[2]}, "item is not a (?:string|scalar)");

    push(@{$wrong_values[3]}, \$global);
    push(@{$error_message[3]}, "item is not a (?:string|scalar)");

    push(@{$wrong_values[4]}, \$global);
    push(@{$error_message[4]}, "item is not a (?:string|scalar)");

    push(@{$wrong_values[5]}, \$global);
    push(@{$error_message[5]}, "item is not a (?:string|scalar)");

    push(@{$wrong_values[6]}, \$global);
    push(@{$error_message[6]}, "item is not a (?:string|scalar)");

    push(@{$wrong_values[7]}, \$global);
    push(@{$error_message[7]}, "item is not a (?:string|scalar)");

    push(@{$wrong_values[8]}, \$global);
    push(@{$error_message[8]}, "item is not a (?:string|scalar)");

    push(@{$wrong_values[9]}, \$global);
    push(@{$error_message[9]}, "item is not a (?:string|scalar)");

    push(@{$wrong_values[11]}, \$global);
    push(@{$error_message[11]}, "item is not a (?:string|scalar)");

    push(@{$wrong_values[12]}, \$global);
    push(@{$error_message[12]}, "item is not a (?:string|scalar)");
}

__END__

