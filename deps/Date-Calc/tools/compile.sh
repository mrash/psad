#!/bin/sh

###############################################################################
##                                                                           ##
##    Copyright (c) 1998 - 2004 by Steffen Beyer.                            ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This program is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl.                         ##
##                                                                           ##
###############################################################################

self=`basename $0`

if [ $# = 0 ]
then
    echo "Usage:  $self  <main>[.c]  [ <other.c> ]*"
    exit 0
fi

main=`basename $1 .c`

if [ -f "$main.c" ]
then
    shift
    gcc -ansi -O2 -o $main $main.c "$@"
else
    echo "$self: file '$main.c' does not exist!"
fi

