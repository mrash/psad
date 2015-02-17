#!perl -w

BEGIN { eval { require bytes; }; }
use strict;
no strict "vars";

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

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
{print "ok $n\n";} else {print "not ok $n\n";} # 01
$n++;

if (Language_to_Text(Language()) eq 'Français')
{print "ok $n\n";} else {print "not ok $n\n";} # 02
$n++;

$date->date_format(3);
$date->language("Port");

if ("$date" eq 'Domingo, dia 5 de agosto de 2001')
{print "ok $n\n";} else {print "not ok $n\n";} # 03
$n++;

if (Language_to_Text(Language()) eq 'Français')
{print "ok $n\n";} else {print "not ok $n\n";} # 04
$n++;

Date::Calc->date_format(2);
Date::Calc->language(11);

{
    local($date->[0][2]) = undef;
    if ("$date" eq 'Dom 5-ago-2001')
    {print "ok $n\n";} else {print "not ok $n\n";} # 05
    $n++;
    if (Language_to_Text(Language()) eq 'suomi')
    {print "ok $n\n";} else {print "not ok $n\n";} # 06
    $n++;
}

if ("$date" eq 'Domingo, dia 5 de agosto de 2001')
{print "ok $n\n";} else {print "not ok $n\n";} # 07
$n++;

{
    local($date->[0][3]) = undef;
    if ("$date" eq 'sunnuntai, 5. elokuuta 2001')
    {print "ok $n\n";} else {print "not ok $n\n";} # 08
    $n++;
    if (Language_to_Text(Language()) eq 'suomi')
    {print "ok $n\n";} else {print "not ok $n\n";} # 09
    $n++;
}

if ("$date" eq 'Domingo, dia 5 de agosto de 2001')
{print "ok $n\n";} else {print "not ok $n\n";} # 10
$n++;

$text = '<STILL UNTOUCHED>';

{
    if ($text eq '<STILL UNTOUCHED>')
    {print "ok $n\n";} else {print "not ok $n\n";} # 11
    $n++;
    local($date->[0][3]) = -1;
    eval { $text = "$date"; };
    if ($@ =~ /\bDate::Calc::string\(\): no such language\b/)
    {print "ok $n\n";} else {print "not ok $n\n";} # 12
    $n++;
    if ($text eq '<STILL UNTOUCHED>')
    {print "ok $n\n";} else {print "not ok $n\n";} # 13
    $n++;
    if (Language_to_Text(Language()) eq 'suomi')
    {print "ok $n\n";} else {print "not ok $n\n";} # 14
    $n++;
}

$format = sub { Date_to_Text_Long($_[0]->date(),$_[2]); };

if ($date->string($format, 9) eq 'söndag, 5 augusti 2001')
{print "ok $n\n";} else {print "not ok $n\n";} # 15
$n++;

$lang = '<NO LANGUAGE>';

$format = sub { $lang = Language_to_Text($_[2]); Date_to_Text_Long($_[0]->date(),$_[2]); };

if ($lang eq '<NO LANGUAGE>')
{print "ok $n\n";} else {print "not ok $n\n";} # 16
$n++;

if ($date->string($format, 6) eq 'Zondag, 5 augustus 2001')
{print "ok $n\n";} else {print "not ok $n\n";} # 17
$n++;

if ($lang eq 'Nederlands')
{print "ok $n\n";} else {print "not ok $n\n";} # 18
$n++;

if (Language_to_Text(Language()) eq 'suomi')
{print "ok $n\n";} else {print "not ok $n\n";} # 19
$n++;

$format = sub { $lang = Language_to_Text($_[2]); join('~', $_[0]->datetime()); };

if ($lang eq 'Nederlands')
{print "ok $n\n";} else {print "not ok $n\n";} # 20
$n++;

if ($date->string($format, 9) eq '2001~8~5~0~0~0')
{print "ok $n\n";} else {print "not ok $n\n";} # 21
$n++;

if ($lang eq 'Svenska')
{print "ok $n\n";} else {print "not ok $n\n";} # 22
$n++;

if (Language_to_Text(Language()) eq 'suomi')
{print "ok $n\n";} else {print "not ok $n\n";} # 23
$n++;

$lang = '<NO LANGUAGE>';

$format = sub
{
    $lang = Language_to_Text($_[2]);
    die "Let's see if the language is restored nevertheless!";
};

if ($lang eq '<NO LANGUAGE>')
{print "ok $n\n";} else {print "not ok $n\n";} # 24
$n++;

if ($text eq '<STILL UNTOUCHED>')
{print "ok $n\n";} else {print "not ok $n\n";} # 25
$n++;

eval { $text = $date->string($format, 4); };

if ($@ =~ /\bDate::Calc::string\(\): Let's see if the language is restored nevertheless!/)
{print "ok $n\n";} else {print "not ok $n\n";} # 26
$n++;

if (Language_to_Text(Language()) eq 'suomi')
{print "ok $n\n";} else {print "not ok $n\n";} # 27
$n++;

if ($lang eq 'Español')
{print "ok $n\n";} else {print "not ok $n\n";} # 28
$n++;

if ($text eq '<STILL UNTOUCHED>')
{print "ok $n\n";} else {print "not ok $n\n";} # 29
$n++;

if ("$date" eq 'Domingo, dia 5 de agosto de 2001')
{print "ok $n\n";} else {print "not ok $n\n";} # 30
$n++;

exit 0; # vital here: avoid "panic: POPSTACK" in Perl 5.005_03 (and before, probably)

__END__

