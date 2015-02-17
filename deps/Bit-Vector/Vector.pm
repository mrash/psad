
###############################################################################
##                                                                           ##
##    Copyright (c) 1995 - 2013 by Steffen Beyer.                            ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

package Bit::Vector;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION @CONFIG);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);

@EXPORT = qw();

@EXPORT_OK = qw();

$VERSION = '7.4';

bootstrap Bit::Vector $VERSION;

sub STORABLE_freeze
{
    my($self, $clone) = @_;
    return( Storable::nfreeze( [ $self->Size(), $self->Block_Read() ] ) );
}

sub STORABLE_thaw
{
    my($self, $clone, $string) = @_;
    my($size,$buffer) = @{ Storable::thaw($string) };
    $self->Unfake($size);          # Undocumented feature, only for use by "Storable"!
    $self->Block_Store($buffer);
}

#sub STORABLE_attach # Does not work properly in nested data structures (see test cases)
#{
#    my($class, $clone, $string) = @_;
#    my($size,$buffer) = @{ Storable::thaw($string) };
#    my $self = Bit::Vector->new($size);
#    $self->Block_Store($buffer);
#    return $self;
#}

1;

__END__

