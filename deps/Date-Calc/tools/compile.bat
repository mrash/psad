@ECHO OFF

rem ###########################################################################
rem ##                                                                       ##
rem ##    Copyright (c) 1998 - 2004 by Steffen Beyer.                        ##
rem ##    All rights reserved.                                               ##
rem ##                                                                       ##
rem ##    This program is free software; you can redistribute it             ##
rem ##    and/or modify it under the same terms as Perl.                     ##
rem ##                                                                       ##
rem ###########################################################################

if "%1" == "" goto usage
if exist %1.c goto compile
    echo %0: file '%1.c' does not exist!
    goto exit
:usage
    echo Usage:  %0  main  [ other.c ]*
    goto exit
:compile
    cl -O2 -o %1 %1.c %2 %3 %4 %5 %6 %7 %8 %9
:exit

