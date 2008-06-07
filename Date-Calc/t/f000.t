#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

# ======================================================================
#   $version = $Carp::Clan::VERSION;
#   $version = $Date::Calc::VERSION;
#   $version = &Date::Calc::Version();
#   $version = $Date::Calc::Object::VERSION;
#   $version = $Date::Calendar::Profiles::VERSION;
#   $version = $Date::Calendar::Year::VERSION;
#   $version = $Date::Calendar::VERSION;
# ======================================================================

$Carp::Clan::VERSION               = $Carp::Clan::VERSION               = 0;
$Date::Calc::VERSION               = $Date::Calc::VERSION               = 0;
$Date::Calc::Object::VERSION       = $Date::Calc::Object::VERSION       = 0;
$Date::Calendar::Profiles::VERSION = $Date::Calendar::Profiles::VERSION = 0;
$Date::Calendar::Year::VERSION     = $Date::Calendar::Year::VERSION     = 0;
$Date::Calendar::VERSION           = $Date::Calendar::VERSION           = 0;
$Bit::Vector::VERSION              = $Bit::Vector::VERSION              = 0;

$tests = 9;

eval { require Bit::Vector; };

unless ($@) { $tests += 6; }

print "1..$tests\n";

$n = 1;

eval
{
    require Carp::Clan;
    Carp::Clan->import( qw(^Date::) );
};
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($Carp::Clan::VERSION >= 5.0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval
{
    require Date::Calc;
    Date::Calc->import( qw(:all) );
};
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($Date::Calc::VERSION eq '5.4')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (&Date::Calc::Version() eq '5.4')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval
{
    require Date::Calc::Object;
    Date::Calc::Object->import( qw(:all) );
};
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($Date::Calc::Object::VERSION eq '5.4')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval
{
    require Date::Calendar::Profiles;
    Date::Calendar::Profiles->import( qw( $Profiles ) );
};
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($Date::Calendar::Profiles::VERSION eq '5.4')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

exit 0 if $n > $tests;

if ($Bit::Vector::VERSION >= '6.3')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (&Bit::Vector::Version() >= '6.3')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval
{
    require Date::Calendar::Year;
    Date::Calendar::Year->import( qw(:all) );
};
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($Date::Calendar::Year::VERSION eq '5.4')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval
{
    require Date::Calendar;
    Date::Calendar::Year->import( qw() );
};
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($Date::Calendar::VERSION eq '5.4')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

