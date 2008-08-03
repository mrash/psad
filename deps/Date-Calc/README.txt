                     ====================================
                       Package "Date::Calc" Version 5.4
                     ====================================


This package is available for download either from my web site at

                  http://www.engelschall.com/u/sb/download/

or from any CPAN (= "Comprehensive Perl Archive Network") mirror server:

               http://www.perl.com/CPAN/authors/id/S/ST/STBEY/


Abstract:
---------

This package consists of a C library (intended to make life easier for C
developers) and a Perl module to access this library from Perl.

The library provides all sorts of date calculations based on the Gregorian
calendar (the one used in all western countries today), thereby complying
with all relevant norms and standards: ISO/R 2015-1971, DIN 1355 and, to
some extent, ISO 8601 (where applicable).

The package is designed as an efficient (and fast) toolbox, not a bulky
ready-made application. It provides extensive documentation and examples
of use, multi-language support and special functions for business needs.

The C library is specifically designed so that it can be used stand-alone,
without Perl.

Moreover, versions 5.x feature date objects (in addition to the functional
interface) with overloaded operators, and a set of modules for calculations
which take local holidays into account (both additions in Perl only, however).


What's new in version 5.4:
--------------------------

 +  Added compiler directives for C++.
 +  Removed "Carp::Clan" from the distribution (available separately).
 +  Fixed bug in initialization of "Date::Calendar::Year" objects.
 +  Added method "tags()" to "Date::Calendar" and "Date::Calendar::Year".
 +  Fixed the formula for "Labor Day" in the U.S. to "1/Mon/Sep".
 +  Added a new recipe to the "Date::Calc" documentation.
 +  Added Romanian to the list of languages supported by "Date::Calc".
 +  Changed the example script "calendar.cgi" to highlight the name
    which led to a given date being a holiday.
 +  Fixed the Polish entries in "Date::Calc".
 +  Added a few commemorative days to the Norwegian calendar profile.
 +  Added "use bytes" to all Perl files to avoid problems on systems
    not using the standard locale "C".
 +  Fixed test 5 of t/m005.t to (hopefully) work under other locales.


New features in version 5.0:
----------------------------

 *  Many new functions in Date::Calc
    (but the module continues to be small, fast and simple)

 *  Optionally, Date::Calc objects with overloaded operators
    for more ease of use (when speed is not so critical)

 *  An optional module for performing date calculations which
    take holidays into account, e.g., today plus 60 workdays,
    what date gives that?  Or how many workdays are there
    between two dates?

 *  A library containing profiles for a large number of countries
    with all their legal holidays (i.e., you get a day off) and
    many commemorative days (you don't)

 *  The possibility to create your own profiles for any special
    needs you may have, for instance for schools, banks, stock
    market, birthdays of relatives and friends, ...

 *  It is easy to generate calendars for any of these profiles
    and any year you like - there is a script to do so on the
    command line, and a CGI script for doing so on the web

 *  A couple of new example scripts to illustrate the use of
    the various modules

 *  Modularized, tailor-made components to assist you in particular
    tasks, instead of one bulky application larger than your own
    costing lots of overhead for features you do not need or want


Legal issues:
-------------

This package with all its parts is

Copyright (c) 1995 - 2004 by Steffen Beyer.
All rights reserved.

This package is free software; you can use, modify and redistribute
it under the same terms as Perl itself, i.e., under the terms of
the "Artistic License" or the "GNU General Public License".

The C library at the core of this Perl module can additionally
be used, modified and redistributed under the terms of the
"GNU Library General Public License".

Please refer to the files "Artistic.txt", "GNU_GPL.txt" and
"GNU_LGPL.txt" in this distribution, respectively, for details!


Prerequisites:
--------------

Perl version 5.000 or higher, and an ANSI C compiler. (!)
                                     ^^^^^^
Module "Carp::Clan" version 5.0 or higher.

If you plan to use the modules "Date::Calendar" or
"Date::Calendar::Year" from this package, you will
also need the module "Bit::Vector" version 6.4 or
newer (which also needs an ANSI C compiler!).

Otherwise you may safely ignore the warning message
"Warning: prerequisite Bit::Vector 6.4 not found at ..."
when running "perl Makefile.PL".

Anyway, you can always install "Bit::Vector" later
at any time if you change your mind.

Note that in order to compile Perl modules which contain
C (and/or XS) code (such as this one), you always HAVE
to use the very same compiler your Perl itself was compiled
with.

Many vendors nowadays ship their operating system already
comprising a precompiled version of Perl. Many times the
compilers used to compile this version of Perl are not
available to or not usually used by the users of these
operating systems.

In such cases building this module (or any other Perl
module containing C and/or XS code) will not work. You
will either have to get the compiler which was used to
compile Perl itself (see for example the section "Compiler:"
in the output of the command "perl -V"), or to build
your own Perl with the compiler of your choice (which
also allows you to take advantage of the various compile-
time switches Perl offers).

Note that Sun Solaris and Red Hat Linux frequently were
reported to suffer from this kind of problem.

Moreover, you usually cannot build any modules under
Windows 95/98 since the Win 95/98 command shell doesn't
support the "&&" operator. You will need the Windows NT
command shell ("cmd.exe") or the "4DOS" shell to be
installed on your Windows 95/98 system first. Note that
Windows NT and Windows 2000 are not affected and just
work fine. I don't know about Windows XP, however.

Note that ActiveState provides precompiled binaries of
this module for their Win32 port of Perl ("ActivePerl")
on their web site, which you should be able to install
simply by typing "ppm install Date-Calc" in your MS-DOS
command shell (but note the "-" instead of "::" in the
package name!). This also works under Windows 95/98 (!).

If your firewall prevents "ppm" from downloading
this package, you can also download it manually from
http://www.activestate.com/ppmpackages/5.005/zips/ or
http://www.activestate.com/ppmpackages/5.6/zips/.
Follow the installation instructions included in
the "zip" archive.

Note also that a "plain Perl" version of "Date::Calc" called
"Date::Pcalc" exists (written by J. David Eisenberg); you
should be able to download it from the same place where
you found this package, or from David's web site at
http://catcode.com/date/pcalc.html.


Note to CPAN Testers:
---------------------

After completion, version 5.4 of this module has already
been tested successfully with the following configurations:

  Perl 5.005_03  -  FreeBSD 4.1.1-RELEASE (with "dlopen() relative paths" patch)
  Perl 5.6.0     -  FreeBSD 4.1.1-RELEASE
  Perl 5.6.1     -  FreeBSD 4.1.1-RELEASE
  Perl 5.7.0     -  FreeBSD 4.1.1-RELEASE
  Perl 5.7.1     -  FreeBSD 4.1.1-RELEASE
  Perl 5.7.2     -  FreeBSD 4.1.1-RELEASE
  Perl 5.8.0     -  FreeBSD 4.1.1-RELEASE
  Perl 5.8.4     -  FreeBSD 4.10-BETA
  Perl 5.8.0     -  Windows 2000 & MS VC++ 6.0 (native Perl build)

Note: You can safely ignore the failing tests in module Bit::Vector 6.0
(Bit::Vector::Overload, to be precise) in file "t/30_overloaded.t" under
Perl 5.7.1 and Perl 5.7.2. The same applies to older versions of
Bit::Vector.

The failing tests are due to a change in Perl's core module "overload.pm"
which attempts to modify a read-only value when an exception is thrown
in the handler of an overloaded operator. This just causes a different
error message to be printed than the intended one.


Installation:
-------------

Please see the file "INSTALL.txt" in this distribution for instructions
on how to install this package.

It is essential that you read this file since one of the special cases
described in it might apply to you, especially if you are running Perl
under Windows.


Adding more languages:
----------------------

Please see the corresponding section in the file "INSTALL.txt" in this
distribution for detailed instructions on how to add other languages.


Changes over previous versions:
-------------------------------

Please refer to the file "CHANGES.txt" in this distribution for a more
detailed version history log.


Documentation:
--------------

The documentation of this package is included in POD format (= "Plain
Old Documentation") in the files with the extension ".pod" in this
distribution, the human-readable markup-language standard for Perl
documentation.

By building this package, this documentation will automatically be
converted into man pages, which will automatically be installed in
your Perl tree for further reference through the installation process,
where they can be accessed by the commands "man Date::Calc" (Unix)
and "perldoc Date::Calc" (Unix and Win32 alike), for example.

Available man pages:

    Carp::Clan(3)
    Date::Calc(3)
    Date::Calc::Object(3)
    Date::Calendar(3)
    Date::Calendar::Profiles(3)
    Date::Calendar::Year(3)

If Perl is not available on your system, you can also read the ".pod"
files

    ./Calc.pod
    ./Calendar.pod
    ./lib/Carp/Clan.pod
    ./lib/Date/Calc/Object.pod
    ./lib/Date/Calendar/Profiles.pod
    ./lib/Date/Calendar/Year.pod

directly.


What does it do:
----------------

This package performs date calculations based on the Gregorian calendar
(the one used in all western countries today), thereby complying with
all relevant norms and standards: ISO/R 2015-1971, DIN 1355 and, to
some extent, ISO 8601 (where applicable).

See also http://www.engelschall.com/u/sb/download/Date-Calc/DIN1355/
for a scan of part of the "DIN 1355" document (in German).

The module of course handles year numbers of 2000 and above correctly
("Year 2000" or "Y2K" compliance) -- actually all year numbers from 1
to the largest positive integer representable on your system (which
is at least 32767) can be dealt with.

Note that this package projects the Gregorian calendar back until the
year 1 A.D. -- even though the Gregorian calendar was only adopted
in 1582, mostly by the Catholic European countries, in obedience to
the corresponding decree of Pope Gregory XIII in that year.

Some (mainly protestant) countries continued to use the Julian calendar
(used until then) until as late as the beginning of the 20th century.

Therefore, do *NEVER* write something like "99" when you really mean
"1999" - or you may get wrong results!

Finally, note that this package is not intended to do everything you could
ever imagine automagically :-) for you; it is rather intended to serve as a
toolbox (in the best of UNIX spirit and tradition) which should, however,
always get you where you need and want to go.

See the section "RECIPES" at the end of the manual pages for solutions
to common problems!

If nevertheless you can't figure out how to solve a particular problem,
please let me know! (See e-mail address at the bottom of this file.)

The new module "Date::Calc::Object" adds date objects to the (functional)
"Date::Calc" module (just "use Date::Calc::Object qw(...);" INSTEAD of
"use Date::Calc qw(...);"), plus built-in operators like +,+=,++,-,-=,--,
<=>,<,<=,>,>=,==,!=,cmp,lt,le,gt,ge,eq,ne,abs(),"" and true/false
testing, as well as a number of other useful methods.

The new modules "Date::Calendar::Year" and "Date::Calendar" allow you
to create calendar objects (for a single year or arbitrary (dynamic)
ranges of years, respectively) for different countries/states/locations/
companies/individuals which know about all local holidays, and which allow
you to perform calculations based on work days (rather than just days),
like calculating the difference between two dates in terms of work days,
or adding/subtracting a number of work days to/from a date to yield a
new date. The dates in the calendar are also tagged with their names,
so that you can find out the name of a given day, or search for the
date of a given holiday.


Note to C developers:
---------------------

Note again that the C library at the core of this module can also be
used stand-alone (i.e., it contains no inter-dependencies whatsoever
with Perl).

The library itself consists of three files: "DateCalc.c", "DateCalc.h"
and "ToolBox.h".

Just compile "DateCalc.c" (which automatically includes "ToolBox.h")
and link the resulting output file "DateCalc.o" with your application,
which in turn should include "ToolBox.h" and "DateCalc.h" (in this order).


Example applications:
---------------------

Please refer to the file "EXAMPLES.txt" in this distribution for details
about the example applications in the "examples" subdirectory.


Tools:
------

Please refer to the file "TOOLS.txt" in this distribution for details
about the various tools to be found in the "tools" subdirectory.


Credits:
--------

Please refer to the file "CREDITS.txt" in this distribution for a list
of contributors.


Author's note:
--------------

If you have any questions, suggestions or need any assistance, please
let me know!

Please do send feedback, this is essential for improving this module
according to your needs!

I hope you will find this module useful. Enjoy!

Yours,
--
  Steffen Beyer <sb@engelschall.com> http://www.engelschall.com/u/sb/
  "There is enough for the need of everyone in this world, but not
   for the greed of everyone." - Mohandas Karamchand "Mahatma" Gandhi
