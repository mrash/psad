#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

use Date::Calc::Object qw(:all);

# ======================================================================
#   $lang = Date::Calc->language([LANG]);
#   $lang = $date->language([LANG]);
# ======================================================================

print "1..9\n";

$n = 1;

$date = Date::Calc->new();

$lang = Date::Calc->language();
if ($lang eq 'English')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$lang = Date::Calc->language("fr");
if ($lang eq 'English')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$lang = Date::Calc->language();
if ($lang eq 'Français')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$lang = $date->language();
unless (defined $lang)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$lang = $date->language("SV");
unless (defined $lang)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$lang = $date->language();
if ($lang eq 'Svenska')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$lang = $date->language(3);
if ($lang eq 'Svenska')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$lang = $date->language();
if ($lang eq 'Deutsch')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$date->[0][3] = 0;

eval { $lang = $date->language(); };
if ($@ =~ /\bDate::Calc::language\(\): language not available\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

