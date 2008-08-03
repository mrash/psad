#!perl

###############################################################################
##                                                                           ##
##    Copyright (c) 2000 - 2004 by Steffen Beyer.                            ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This program is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

######################################################################
#                                                                    #
# How to emulate the Set::Object module using Bit::Vector (example): #
#                                                                    #
######################################################################

package InheritMe;

use strict;
use vars qw( @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION );

require Exporter;

@ISA         = qw(Exporter);
@EXPORT      = qw();
@EXPORT_OK   = qw( RegisterMe ID2Obj Obj2ID Registered );
%EXPORT_TAGS = (all => [@EXPORT_OK]);
$VERSION     = 1.0;

my $ID      = 0;
my(%id2obj) = ();
my(%obj2id) = ();

sub RegisterMe
{
    my($self) = @_;

    if (exists $obj2id{$self})
    {
        warn "Object '$self' has already been registered!\n";
        return $obj2id{$self};
    }
    else
    {
        $id2obj{$ID} = $self;
        $obj2id{$self} = $ID;
        return $ID++;
    }
}

sub ID2Obj
{
    my($self,$id) = @_;

    return exists($id2obj{$id}) ? $id2obj{$id} : undef;
}

sub Obj2ID
{
    my($self) = @_;

    return exists($obj2id{$self}) ? $obj2id{$self} : undef;
}

sub Registered
{
    return $ID;
}

package main;

use strict;

use Date::Calc::Object;
use Bit::Vector::Overload;

push( @Date::Calc::ISA, 'InheritMe' ); # (make Date::Calc a subclass)

InheritMe->import(':all'); # (as a convenience for dealing with non-objects)

Date::Calc->date_format(2);

my $today     = Date::Calc->today();
my $yesterday = $today - 1;
my $tomorrow  = $today + 1;

print "\nDates:\n";
print "'$yesterday' has got ID #", $yesterday->RegisterMe(), "\n";
print "'$today' has got ID #",         $today->RegisterMe(), "\n";
print "'$tomorrow' has got ID #",   $tomorrow->RegisterMe(), "\n";

my $pears   = 50;
my $apples  =  1;
my $oranges = 'out of stock';

print "\nFruit:\n";
print "\$pears ('$pears') has got ID #",     RegisterMe(\$pears),   "\n";
print "\$apples ('$apples') has got ID #",   RegisterMe(\$apples),  "\n";
print "\$oranges ('$oranges') has got ID #", RegisterMe(\$oranges), "\n";

my $set1 = Bit::Vector->new(&Registered);
my $set2 = Bit::Vector->new(&Registered);

$set1->Bit_On( $today->Obj2ID()  );
$set1->Bit_On( Obj2ID(\$pears)   );
$set1->Bit_On( Obj2ID(\$apples)  );
$set1->Bit_On( Obj2ID(\$oranges) );

$set2->Bit_On( $yesterday->Obj2ID() );
$set2->Bit_On( $today->Obj2ID()     );
$set2->Bit_On( $tomorrow->Obj2ID()  );
$set2->Bit_On( Obj2ID(\$oranges)    );

print "\nSet #1:\n";
print "<",
      join
      (
          '> <',
          map
          (
              ref($_) =~ /^[A-Z]+$/ ? "${$_}" : "$_",
              map
              (
                  InheritMe->ID2Obj($_),
                  $set1->Index_List_Read()
              )
          )
      ),
      ">\n";

print "\nSet #2:\n";
print "<",
      join
      (
          '> <',
          map
          (
              ref($_) =~ /^[A-Z]+$/ ? "${$_}" : "$_",
              map
              (
                  InheritMe->ID2Obj($_),
                  $set2->Index_List_Read()
              )
          )
      ),
      ">\n";

my $intersection = $set1 & $set2;

print "\nIntersection:\n";
print "<",
      join
      (
          '> <',
          map
          (
              ref($_) =~ /^[A-Z]+$/ ? "${$_}" : "$_",
              map
              (
                  InheritMe->ID2Obj($_),
                  $intersection->Index_List_Read()
              )
          )
      ),
      ">\n";

__END__

