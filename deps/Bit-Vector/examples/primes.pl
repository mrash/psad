#!perl -w

###############################################################################
##                                                                           ##
##    Copyright (c) 1995 - 2013 by Steffen Beyer.                            ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This program is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

use strict;
use vars qw($limit $set $start $stop $min $max $norm $i $j);

use Bit::Vector;

print "\n***** Calculating Prime Numbers - The Sieve Of Erathostenes *****\n";

$limit = 0;

if (-t STDIN)
{
    while ($limit < 16)
    {
        print "\nPlease enter an upper limit (>15): ";
        $limit = <STDIN>;
        if ($limit =~ /^\s*(\d+)\s*$/) { $limit = $1; } else { $limit = 0; }
    }
    print "\n";
}
else
{
    $limit = 100;
    print "\nRunning in batch mode - using $limit as upper limit.\n\n";
}

$set = Bit::Vector->new($limit+1);

print "Calculating the prime numbers in the range [2..$limit]...\n\n";

$start = time;

$set->Primes();

## Alternative (slower!):

#$set->Fill();
#$set->Bit_Off(0);
#$set->Bit_Off(1);
#for ( $j = 4; $j <= $limit; $j += 2 ) { $set->Bit_Off($j); }
#for ( $i = 3; ($j = $i * $i) <= $limit; $i += 2 )
#{
#    for ( ; $j <= $limit; $j += $i ) { $set->Bit_Off($j); }
#}

$stop = time;

&print_elapsed_time;

$min = $set->Min();
$max = $set->Max();
$norm = $set->Norm();

print "Found $norm prime numbers in the range [2..$limit]:\n\n";

for ( $i = $min, $j = 0; $i <= $max; $i++ )
{
    if ($set->contains($i)) { print "prime number #", ++$j, " = $i\n"; }
}

print "\n";

exit;

sub print_elapsed_time
{
    my($flag) = 0;
    my($sec,$min,$hour,$year,$yday) = (gmtime($stop - $start))[0,1,2,5,7];
    $year -= 70;
    print "Elapsed time: ";
    if ($year > 0)
    {
        printf("%d year%s ", $year, ($year!=1)?"s":"");
        $flag = 1;
    }
    if (($yday > 0) || $flag)
    {
        printf("%d day%s ", $yday, ($yday!=1)?"s":"");
        $flag = 1;
    }
    if (($hour > 0) || $flag)
    {
        printf("%d hour%s ", $hour, ($hour!=1)?"s":"");
        $flag = 1;
    }
    if (($min > 0) || $flag)
    {
        printf("%d minute%s ", $min, ($min!=1)?"s":"");
    }
    printf("%d second%s.\n\n", $sec, ($sec!=1)?"s":"");
}

__END__

