#!perl

###############################################################################
##                                                                           ##
##    Copyright (c) 1998 - 2004 by Steffen Beyer.                            ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This program is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

use Config;

$self = $0;
$self =~ s!^.*/!!;

unless (@ARGV)
{
    die "Usage:  perl  $self  <main>[.c]  [ <other.c> ]*\n";
}

$main = shift;
$main =~ s/\.c$//;

unless (-f "$main.c")
{
    die "$self: file '$main.c' does not exist!\n";
}

$cc = $Config{'cc'};

$flags = $Config{'ccflags'};

@ARGV = map("\"$_\"",@ARGV);

system("$cc $flags -o $main $main.c @ARGV");

