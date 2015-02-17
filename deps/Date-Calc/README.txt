                     ====================================
                       Package "Date::Calc" Version 6.3
                     ====================================


Abstract:
---------

This package provides all sorts of date calculations based on the Gregorian
calendar (the one used in all western countries today).

The package is designed as an efficient (and fast) toolbox, not a bulky
ready-made application. It provides extensive documentation and examples
of use, multi-language support and special functions for business needs.

Moreover, it optionally provides an object-oriented interface with overloaded
operators for greater convenience, and calendar objects which support
profiles of legal holidays and observances for calculations which need to
take those into account.


What's new in version 6.3:
--------------------------

 +  Changed "Mktime()" to use "POSIX::mktime()"
 +  Fixed the bug that "Date::Calc::PP" was never tested
    when "Date::Calc::XS" is installed


Copyright & License:
--------------------

This package with all its parts is

Copyright (c) 1995 - 2009 by Steffen Beyer.
All rights reserved.

This package is free software; you can use, modify and redistribute
it under the same terms as Perl itself, i.e., at your option, under
the terms either of the "Artistic License" or the "GNU General Public
License".

The C library at the core of the module "Date::Calc::XS" can, at your
discretion, also be used, modified and redistributed under the terms
of the "GNU Library General Public License".

Please refer to the files "Artistic.txt", "GNU_GPL.txt" and
"GNU_LGPL.txt" in the "license" subdirectory of this distribution
for any details!


Installation:
-------------

perl Makefile.PL
make
make test
make install UNINST=1

Under Windows, depending on your environment,
use "nmake" or "dmake" instead of "make".


Contact Author:
---------------

Steffen Beyer <STBEY@cpan.org>
http://www.engelschall.com/u/sb/download/


