#!perl -w

###############################################################################
##                                                                           ##
##    Copyright (c) 1998 - 2002 by Steffen Beyer.                            ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This program is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

use strict;
no strict "vars";

use Date::Calc qw(:all);

$please_enter_birthday[0] = "Please enter the date of your birthday (day-month-year)";
$please_enter_birthday[1] = "S.v.p. saisissez la date de votre anniversaire (jour-mois-année)";
$please_enter_birthday[2] = "Bitte geben Sie das Datum Ihres Geburtstages ein (Tag-Monat-Jahr)";
$please_enter_birthday[3] = "Por favor ingrese la fecha de su cumpleaños (día-mes-año)";
$please_enter_birthday[4] = "Por favor entre a data do seu aniversário (dia-mês-ano)";
$please_enter_birthday[5] = "A.u.b. geef het datum van U verjaardag in (daag-maand-jaar)";

$please_enter_today[0] = "Please enter today's date (day-month-year)";
$please_enter_today[1] = "S.v.p. saisissez la date d'aujourd'hui (jour-mois-année)";
$please_enter_today[2] = "Bitte geben Sie das heutige Datum ein (Tag-Monat-Jahr)";
$please_enter_today[3] = "Por favor ingrese la fecha de hoy (día-mes-año)";
$please_enter_today[4] = "Por favor entre a data de hoje (dia-mês-ano)";
$please_enter_today[5] = "A.u.b. geef het datum van vandaag in (daag-maand-jaar)";

$your_birthday_is[0] = "Your birthday is";
$your_birthday_is[1] = "Votre anniversaire est";
$your_birthday_is[2] = "Ihr Geburtstag ist";
$your_birthday_is[3] = "Su cumpleaños es";
$your_birthday_is[4] = "Seu aniversário é";
$your_birthday_is[5] = "U verjaardag is";

$today_is[0] = "Today is";
$today_is[1] = "Aujourd'hui est";
$today_is[2] = "Heute ist";
$today_is[3] = "Hoy es";
$today_is[4] = "Hoje é";
$today_is[5] = "Vandaag is";

$correct[0] = "Is that correct? (Yes/No)";
$correct[1] = "Est-ce exact? (Oui/Non)";
$correct[2] = "Ist das richtig? (Ja/Nein)";
$correct[3] = "¿Es esto correcto? (Si/No)";
$correct[4] = "Está certo? (Sim/Não)";
$correct[5] = "Is dat juist? (Ja/Nee)";

$yes[0] = "y";
$yes[1] = "o";
$yes[2] = "j";
$yes[3] = "s";
$yes[4] = "s";
$yes[5] = "j";

$you_are[0] = "You are %s days old";
$you_are[1] = "Vous êtes âgé de %s jours";
$you_are[2] = "Sie sind %s Tage alt";
$you_are[3] = "Su edad es %s días";
$you_are[4] = "Você tem uma idade de %s dias";
$you_are[5] = "U bent %s dagen oud";

for ( $i = 1; $i <= 6; $i++ ) { $language[$i-1] = Language_to_Text($i); }

$languages = join(", ",@language);

print "\n";

$ok = 0;
while (! $ok)
{
    print "Please choose a language among $languages: ";
    chomp($lang = <STDIN>);
    print "\n";
    if (($lang = Decode_Language($lang)) && ($lang < 7))
    {
        $string0 = Language_to_Text($lang);
        print "Your chosen language is: $string0\n";
        print "\n";
        print "Is that correct? (Yes/No) ";
        $response = <STDIN>;
        print "\n";
        $ok = ($response =~ /^Y/i);
    }
}

Language($lang--);

$ok = 0;
while (! $ok)
{
    print "$please_enter_birthday[$lang]: ";
    $date = <STDIN>;
    print "\n";
    if (($yy1,$mm1,$dd1) = Decode_Date_EU($date))
    {
        $string1 = Date_to_Text_Long($yy1,$mm1,$dd1);
        print "$your_birthday_is[$lang]: $string1\n";
        print "\n";
        print "$correct[$lang] ";
        $response = <STDIN>;
        print "\n";
        $ok = ($response =~ /^$yes[$lang]/io);
    }
}

eval { ($yy2,$mm2,$dd2) = Today(); };

if ($@)
{
    $ok = 0;
    while (! $ok)
    {
        print "$please_enter_today[$lang]: ";
        $date = <STDIN>;
        print "\n";
        if (($yy2,$mm2,$dd2) = Decode_Date_EU($date))
        {
            $string2 = Date_to_Text_Long($yy2,$mm2,$dd2);
            print "$today_is[$lang]: $string2\n";
            print "\n";
            print "$correct[$lang] ";
            $response = <STDIN>;
            print "\n";
            $ok = ($response =~ /^$yes[$lang]/io);
        }
    }
}
else { $string2 = Date_to_Text_Long($yy2,$mm2,$dd2); }

print "$your_birthday_is[$lang]: $string1\n";
print "\n";

print "$today_is[$lang]: $string2\n";
print "\n";

$days = Delta_Days($yy1,$mm1,$dd1,$yy2,$mm2,$dd2);
printf("$you_are[$lang].\n", $days);
print "\n";

__END__

