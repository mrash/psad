#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

eval { require Bit::Vector; };

if ($@)
{
    print "1..0\n";
    exit 0;
}

require Date::Calendar::Year;

# ======================================================================
#   $year = Date::Calendar::Year->new(YEAR,PROFILE);
#   ($date,$rest,$sign) = $year->_move_forward_(INDEX,OFFSET,SIGN);
# ======================================================================

print "1..166\n";

$n = 1;

$year = Date::Calendar::Year->new(1995,{});
$full = $year->vec_full();
$yday = 0;

foreach $bit (1,0,0,0,0,0,1,1,0,0,0,0,0,1,1,0)
{
    if ($full->bit_test($yday++) == $bit)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

$year = Date::Calendar::Year->new(1996,{});
$full = $year->vec_full();
$yday = 0;

foreach $bit (0,0,0,0,0,1,1,0,0,0,0,0,1,1,0)
{
    if ($full->bit_test($yday++) == $bit)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

$year = Date::Calendar::Year->new(1999,{});
$full = $year->vec_full();
$yday = 0;

foreach $bit (0,1,1,0,0,0,0,0,1,1,0)
{
    if ($full->bit_test($yday++) == $bit)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

##################################################

$year = Date::Calendar::Year->new(1995,{},0,1,3,5);
$full = $year->vec_full();
$yday = 0;

foreach $bit (0,1,0,1,0,1,0,0,1,0,1,0,1,0,0,1)
{
    if ($full->bit_test($yday++) == $bit)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

$year = Date::Calendar::Year->new(1996,{},1,2,4);
$full = $year->vec_full();
$yday = 0;

foreach $bit (0,1,0,1,0,0,0,0,1,0,1,0,0,0,0)
{
    if ($full->bit_test($yday++) == $bit)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

$year = Date::Calendar::Year->new(1999,{},2,1,2,3,4,5);
$full = $year->vec_full();
$yday = 0;

foreach $bit (1,0,0,1,1,1,1,1,0,0,1)
{
    if ($full->bit_test($yday++) == $bit)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

##################################################

$year = Date::Calendar::Year->new(2000,{});
$days = $year->val_days();
$last = $days - 1;

#$work = $year->vec_work();
$full = $year->vec_full();
$half = $year->vec_half();

$yday = 0;
foreach $bit (1,1,0,0,0,0,0,1,1,0)
{
    if ($full->bit_test($yday++) == $bit)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

$full->Fill();
$full->Bit_Off($last);
$full->Bit_Off(0);

$half->Bit_On($last);
$half->Bit_On(0);

eval
{
    ($date,$rest,$sign) = $year->_move_forward_(183,0.5,+1);
};
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date == [2001,1,1])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($rest == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($sign == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval
{
    ($date,$rest,$sign) = $year->_move_forward_(182,-0.5,-1);
};
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date == [1999,12,31])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($rest == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($sign == -1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$half->Bit_Off($last);
$half->Bit_Off(0);

eval
{
    ($date,$rest,$sign) = $year->_move_forward_(183,0.5,+1);
};
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date == [2000,12,31])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($rest == 0.5)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($sign == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval
{
    ($date,$rest,$sign) = $year->_move_forward_(182,-0.5,-1);
};
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date == [2000,1,1])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($rest == -0.5)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($sign == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval
{
    ($date,$rest,$sign) = $year->_move_forward_(183,1.0,+1);
};
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date == [2001,1,1])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($rest == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($sign == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval
{
    ($date,$rest,$sign) = $year->_move_forward_(182,-1.0,-1);
};
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date == [1999,12,31])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($rest == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($sign == -1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$full->Bit_On($last);
$full->Bit_On(0);

eval
{
    ($date,$rest,$sign) = $year->_move_forward_(183,1.0,+1);
};
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date == [2001,1,1])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($rest == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($sign == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval
{
    ($date,$rest,$sign) = $year->_move_forward_(182,-1.0,-1);
};
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date == [1999,12,31])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($rest == -1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($sign == -1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$full->Bit_Off($last);
$full->Bit_Off($last-1);
$full->Bit_Off(0);
$full->Bit_Off(1);

$half->Bit_On($last-1);
$half->Bit_On(1);

eval
{
    ($date,$rest,$sign) = $year->_move_forward_(183,0.5,+1);
};
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date == [2000,12,31])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($rest == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($sign == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval
{
    ($date,$rest,$sign) = $year->_move_forward_(182,-0.5,-1);
};
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date == [2000,1,1])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($rest == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($sign == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval
{
    ($date,$rest,$sign) = $year->_move_forward_(183,1.0,+1);
};
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date == [2000,12,31])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($rest == 0.5)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($sign == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval
{
    ($date,$rest,$sign) = $year->_move_forward_(182,-1.0,-1);
};
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date == [2000,1,1])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($rest == -0.5)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($sign == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$full->Bit_Off($last-9);
$full->Bit_Off(9);

$half->Bit_On($last-9);
$half->Bit_On(9);

eval
{
    ($date,$rest,$sign) = $year->_move_forward_(183,0.5,+1);
};
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date == [2000,12,30])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($rest == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($sign == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval
{
    ($date,$rest,$sign) = $year->_move_forward_(182,-0.5,-1);
};
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date == [2000,1,2])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($rest == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($sign == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval
{
    ($date,$rest,$sign) = $year->_move_forward_(183,1.0,+1);
};
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date == [2000,12,31])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($rest == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($sign == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval
{
    ($date,$rest,$sign) = $year->_move_forward_(182,-1.0,-1);
};
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date == [2000,1,1])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($rest == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($sign == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval
{
    ($date,$rest,$sign) = $year->_move_forward_(183,0.0,+1);
};
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date == [2000,12,22])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($rest == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($sign == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval
{
    ($date,$rest,$sign) = $year->_move_forward_(182,0.0,-1);
};
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($date == [2000,1,10])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($rest == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($sign == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

