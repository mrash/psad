#!perl -w

###############################################################################
##                                                                           ##
##    Copyright (c) 2001, 2002 by Steffen Beyer.                             ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This program is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

use Date::Calendar::Profiles qw( $Profiles );
use Date::Calendar;
use Date::Calc qw(:all);

$self = $0;
$self =~ s!^.*[/\\]!!;
$self =~ s!\.+[^./\\]*$!!;

unless (@ARGV == 4)
{
    die "Usage: $self <year_of_birth> <vacation_days_per_year> <hours_per_week> <brut_yearly_income>\n";
}

$birth = shift;

$vacation = shift;

$hours_per_week = shift;

$brut_yearly_income = shift;

$start = This_Year();

$stop = $birth + 65;

$sum = 0; # total of workdays
$len = 0; # total of days

print "\n";
print "Year of birth      = $birth\n";
print "Current year       = $start\n";
print "Year of retirement = $stop\n";
print "Vacation days/year = $vacation\n";
print "Hours per week     = $hours_per_week\n";
print "Brut annual income = $brut_yearly_income\n";
print "\n";

#$Cal = Date::Calendar->new( $Profiles->{'sdm-MUC'} );
$Cal = Date::Calendar->new( $Profiles->{'DE-NW'} );

for ( $year = $start; $year <= $stop; $year++ )
{
    $Year = $Cal->year( $year );
    $full = $Year->vec_full(); # full holidays
    $half = $Year->vec_half(); # half holidays
    $work = $Year->vec_work(); # workspace
    $work->Complement($full);  # workdays plus half holidays
    $full = $full->Norm();
    $half = $half->Norm();
    $work = $work->Norm();
    $term = $half * 0.5;
    $work -= $term + $vacation;
    $days = $Year->val_days();

    #print "full = $full\n";
    #print "half = $half\n";
    #print "term = $term\n";
    #print "work = $work\n";
    #print "days = $days\n";
    #print "size = ", $Year->vec_full()->Size(), "\n";
    #print "work + full + term = ", $work + $full + $term, "\n";

    print "$year : $work\n";

    $sum += $work;
    $len += $days;
}

print "\nTotal workdays = $sum\n";
print "Average workdays per year = ", $sum / ($stop - $start + 1), "\n";

print "\nTotal days = $len\n";
print "Average year length in days = ", $len / ($stop - $start + 1), "\n";

print "\nQuotient = ", $sum / $len, "\n";

print "\nNet hourly wages (assuming 50% taxes on income) = ",
    $brut_yearly_income * ($stop - $start + 1) * 5 / ($sum * $hours_per_week * 2), "\n";

# "Magic numbers": 5 = workdays per week, 2 = 50% tax

print "\n";

__END__

