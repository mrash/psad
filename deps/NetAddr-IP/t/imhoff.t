#!/usr/bin/perl

# This code was provided by Brent Imhoff and adapted to become a real test.
# What this excercises, is that ::compact() should provide the same result
# without caring about the order of its arguments. -lem

use strict;
#use warnings;
use Test::More tests => 3;
use NetAddr::IP qw(Compact);

my @temp = <DATA>;

my @sortreg = sort @temp;
my @sortdec = sort { $b cmp $a} @temp;
my @sortnum = sort { $a cmp $b} @temp;

my $sortnum = Compact(map { NetAddr::IP->new($_) } @sortnum);
my $sorttag = Compact(map { NetAddr::IP->new($_) } @sortreg);
my $sortdec = Compact(map { NetAddr::IP->new($_) } @sortdec);

is($sortnum, $sorttag);
is($sortnum, $sortdec);
is($sortdec, $sorttag);		# I know this one is redundant

__END__
205.170.190.0/24
216.175.9.0/24
205.170.188.0/24
206.175.9.0/24
205.170.0.0/20
205.170.0.0/19
205.170.0.0/18
205.170.0.0/17
205.170.0.0/16
