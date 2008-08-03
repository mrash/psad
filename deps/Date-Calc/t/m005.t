#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

use Date::Calc::Object qw(:all);

# ======================================================================
#   $form = Date::Calc->date_format([FORMAT]);
#   $lang = Date::Calc->language([LANG]);
#   $form = $date->date_format([FORMAT]);
#   $lang = $date->language([LANG]);
#   $text = $date->string([FORMAT[,LANG]]);
# ======================================================================

print "1..30\n";

$n = 1;

Date::Calc->date_format(1);
Date::Calc->language(2);

$date = Date::Calc->new(2001,8,5);

if ("$date" eq '05-aoû-2001')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (Language_to_Text(Language()) eq 'Français')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$date->date_format(3);
$date->language("Port");

if ("$date" eq 'Domingo, dia 5 de agosto de 2001')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (Language_to_Text(Language()) eq 'Français')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

Date::Calc->date_format(2);
Date::Calc->language(11);

{
    local($date->[0][2]) = undef;
    if ("$date" eq 'Dom 5-ago-2001')
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if (Language_to_Text(Language()) eq 'suomi')
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

if ("$date" eq 'Domingo, dia 5 de agosto de 2001')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

{
    local($date->[0][3]) = undef;
    if ("$date" eq 'sunnuntai, 5. elokuuta 2001')
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if (Language_to_Text(Language()) eq 'suomi')
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

if ("$date" eq 'Domingo, dia 5 de agosto de 2001')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$text = '<STILL UNTOUCHED>';

{
    if ($text eq '<STILL UNTOUCHED>')
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    local($date->[0][3]) = -1;
    eval { $text = "$date"; };
    if ($@ =~ /\bDate::Calc::string\(\): language not available\b/)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if ($text eq '<STILL UNTOUCHED>')
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if (Language_to_Text(Language()) eq 'suomi')
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

$format = sub { Date_to_Text_Long($_[0]->date()); };

if ($date->string($format, 9) eq 'söndag, 5 augusti 2001')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$lang = '<NO LANGUAGE>';

$format = sub { $lang = Language_to_Text(Language()); Date_to_Text_Long($_[0]->date()); };

if ($lang eq '<NO LANGUAGE>')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($date->string($format, 6) eq 'Zondag, 5 augustus 2001')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($lang eq 'Nederlands')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (Language_to_Text(Language()) eq 'suomi')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$format = sub { $lang = Language_to_Text(Language()); join('~', $_[0]->datetime()); };

if ($lang eq 'Nederlands')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($date->string($format, 9) eq '2001~8~5~0~0~0')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($lang eq 'Svenska')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (Language_to_Text(Language()) eq 'suomi')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$lang = '<NO LANGUAGE>';

$format = sub
{
    $lang = Language_to_Text(Language());
    die "Let's see if the language is restored nevertheless!";
};

if ($lang eq '<NO LANGUAGE>')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($text eq '<STILL UNTOUCHED>')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $text = $date->string($format, 4); };

if ($@ =~ /\bDate::Calc::string\(\): Let's see if the language is restored nevertheless!/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (Language_to_Text(Language()) eq 'suomi')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($lang eq 'Español')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($text eq '<STILL UNTOUCHED>')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ("$date" eq 'Domingo, dia 5 de agosto de 2001')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

exit 0; # vital here: avoid "panic: POPSTACK" in Perl 5.005_03 (and before, probably)

__END__

