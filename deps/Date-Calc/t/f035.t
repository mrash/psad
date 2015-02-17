#!perl -w

BEGIN { eval { require bytes; }; }
use strict;

BEGIN { $Date::Calc::XS_DISABLE = $Date::Calc::XS_DISABLE = 1; }

# ======================================================================
#   use Carp::Clan qw(package::pattern);
#   croak();
#   confess();
#   carp();
#   cluck();
# ======================================================================

# NOTE: Certain ugly contortions needed only for crappy Perl 5.6.0!

print "1..58\n";

my $n = 1;

unless (exists $main::{'croak'})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (exists $main::{'confess'})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (exists $main::{'carp'})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (exists $main::{'cluck'})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { require Carp::Clan; };

unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

unless (exists $main::{'croak'})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (exists $main::{'confess'})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (exists $main::{'carp'})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (exists $main::{'cluck'})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { Carp::Clan->import(); };

unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (exists $main::{'croak'})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (exists $main::{'confess'})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (exists $main::{'carp'})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (exists $main::{'cluck'})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

package A;
sub a { &B::b(@_); }

package B;
sub b { &C::c(@_); }

package C;
sub c { &D::d(@_); }

package D;
sub d { &E::e(@_); }

package E;
sub e { &F::f(@_); }

package F;

eval { Carp::Clan->import(); };

sub f
{
    my $select = shift;  # Use symbolic refs without "no strict 'refs';":
    if    ($select == 1) { &{*{${*{$main::{'F::'}}}{'croak'}}}(@_);   }
    elsif ($select == 2) { &{*{${*{$main::{'F::'}}}{'confess'}}}(@_); }
    elsif ($select == 3) { &{*{${*{$main::{'F::'}}}{'carp'}}}(@_);    }
    elsif ($select == 4) { &{*{${*{$main::{'F::'}}}{'cluck'}}}(@_);   }
}

package main;

eval { &{*{$main::{'croak'}}}("CROAKing"); };

if ($@ =~ /^.+\bCROAKing at .+$/) # no "\n" except at EOL
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { &{*{$main::{'confess'}}}("CONFESSing"); };

if ($@ =~ /\bCONFESSing at .+\n.*\b(?:eval {\.\.\.}|require 0) called at\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { local $SIG{'__WARN__'} = sub { die $_[0]; }; &{*{$main::{'carp'}}}("CARPing"); };

if ($@ =~ /^.+\bCARPing at .+$/) # no "\n" except at EOL
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { local $SIG{'__WARN__'} = sub { die $_[0]; }; &{*{$main::{'cluck'}}}("CLUCKing"); };

if ($@ =~ /\bCLUCKing at .+\n.*\b(?:eval {\.\.\.}|require 0) called at\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { Carp::Clan::croak("croakING"); };

if ($@ =~ /^.+\bcroakING at .+$/) # no "\n" except at EOL
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { Carp::Clan::confess("confessING"); };

if ($@ =~ /\bconfessING at .+\n.*\b(?:eval {\.\.\.}|require 0) called at\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { local $SIG{'__WARN__'} = sub { die $_[0]; }; Carp::Clan::carp("carpING"); };

if ($@ =~ /^.+\bcarpING at .+$/) # no "\n" except at EOL
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { local $SIG{'__WARN__'} = sub { die $_[0]; }; Carp::Clan::cluck("cluckING"); };

if ($@ =~ /\bcluckING at .+\n.*\b(?:eval {\.\.\.}|require 0) called at\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

###############################
# Now testing the real thing: #
###############################

eval { &A::a(1, "CrOaKiNg"); };

if ($@ =~ /\bF::f\(\): CrOaKiNg at /)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { &A::a(2, "CoNfEsSiNg"); };

if ($@ =~ /\bCoNfEsSiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bE::e\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bD::d\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bC::c\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bB::b\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bA::a\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { local $SIG{'__WARN__'} = sub { die $_[0]; }; &A::a(3, "CaRpInG"); };

if ($@ =~ /\bF::f\(\): CaRpInG at /)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { local $SIG{'__WARN__'} = sub { die $_[0]; }; &A::a(4, "ClUcKiNg"); };

if ($@ =~ /\bClUcKiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bE::e\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bD::d\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bC::c\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bB::b\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bA::a\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

package F;
eval { local $^W = 0; Carp::Clan->import('^F\b'); };
package main;

eval { &A::a(1, "CrOaKiNg"); };

if ($@ =~ /\bF::f\(\): CrOaKiNg at /)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { &A::a(2, "CoNfEsSiNg"); };

if ($@ =~ /\bCoNfEsSiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bE::e\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bD::d\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bC::c\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bB::b\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bA::a\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { local $SIG{'__WARN__'} = sub { die $_[0]; }; &A::a(3, "CaRpInG"); };

if ($@ =~ /\bF::f\(\): CaRpInG at /)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { local $SIG{'__WARN__'} = sub { die $_[0]; }; &A::a(4, "ClUcKiNg"); };

if ($@ =~ /\bClUcKiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bE::e\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bD::d\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bC::c\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bB::b\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bA::a\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

package F;
eval { local $^W = 0; Carp::Clan->import('^[EF]\b'); };
package main;

eval { &A::a(1, "CrOaKiNg"); };

if ($@ =~ /\bE::e\(\): CrOaKiNg at /)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { &A::a(2, "CoNfEsSiNg"); };

if ($@ =~ /\bCoNfEsSiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bE::e\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bD::d\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bC::c\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bB::b\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bA::a\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { local $SIG{'__WARN__'} = sub { die $_[0]; }; &A::a(3, "CaRpInG"); };

if ($@ =~ /\bE::e\(\): CaRpInG at /)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { local $SIG{'__WARN__'} = sub { die $_[0]; }; &A::a(4, "ClUcKiNg"); };

if ($@ =~ /\bClUcKiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bE::e\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bD::d\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bC::c\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bB::b\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bA::a\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

package F;
eval { local $^W = 0; Carp::Clan->import('^[DEF]\b'); };
package main;

eval { &A::a(1, "CrOaKiNg"); };

if ($@ =~ /\bD::d\(\): CrOaKiNg at /)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { &A::a(2, "CoNfEsSiNg"); };

if ($@ =~ /\bCoNfEsSiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bE::e\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bD::d\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bC::c\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bB::b\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bA::a\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { local $SIG{'__WARN__'} = sub { die $_[0]; }; &A::a(3, "CaRpInG"); };

if ($@ =~ /\bD::d\(\): CaRpInG at /)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { local $SIG{'__WARN__'} = sub { die $_[0]; }; &A::a(4, "ClUcKiNg"); };

if ($@ =~ /\bClUcKiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bE::e\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bD::d\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bC::c\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bB::b\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bA::a\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

package F;
eval { local $^W = 0; Carp::Clan->import('^[CDEF]\b'); };
package main;

eval { &A::a(1, "CrOaKiNg"); };

if ($@ =~ /\bC::c\(\): CrOaKiNg at /)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { &A::a(2, "CoNfEsSiNg"); };

if ($@ =~ /\bCoNfEsSiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bE::e\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bD::d\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bC::c\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bB::b\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bA::a\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { local $SIG{'__WARN__'} = sub { die $_[0]; }; &A::a(3, "CaRpInG"); };

if ($@ =~ /\bC::c\(\): CaRpInG at /)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { local $SIG{'__WARN__'} = sub { die $_[0]; }; &A::a(4, "ClUcKiNg"); };

if ($@ =~ /\bClUcKiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bE::e\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bD::d\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bC::c\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bB::b\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bA::a\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

package F;
eval { local $^W = 0; Carp::Clan->import('^[BCDEF]\b'); };
package main;

eval { &A::a(1, "CrOaKiNg"); };

if ($@ =~ /\bB::b\(\): CrOaKiNg at /)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { &A::a(2, "CoNfEsSiNg"); };

if ($@ =~ /\bCoNfEsSiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bE::e\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bD::d\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bC::c\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bB::b\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bA::a\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { local $SIG{'__WARN__'} = sub { die $_[0]; }; &A::a(3, "CaRpInG"); };

if ($@ =~ /\bB::b\(\): CaRpInG at /)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { local $SIG{'__WARN__'} = sub { die $_[0]; }; &A::a(4, "ClUcKiNg"); };

if ($@ =~ /\bClUcKiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bE::e\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bD::d\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bC::c\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bB::b\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bA::a\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

package F;
eval { local $^W = 0; Carp::Clan->import('^[ABCDEF]\b'); };
package main;

eval { &A::a(1, "CrOaKiNg"); };

if ($@ =~ /\bA::a\(\): CrOaKiNg at /)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { &A::a(2, "CoNfEsSiNg"); };

if ($@ =~ /\bCoNfEsSiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bE::e\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bD::d\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bC::c\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bB::b\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bA::a\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { local $SIG{'__WARN__'} = sub { die $_[0]; }; &A::a(3, "CaRpInG"); };

if ($@ =~ /\bA::a\(\): CaRpInG at /)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { local $SIG{'__WARN__'} = sub { die $_[0]; }; &A::a(4, "ClUcKiNg"); };

if ($@ =~ /\bClUcKiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bE::e\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bD::d\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bC::c\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bB::b\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bA::a\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

package F;
eval { local $^W = 0; Carp::Clan->import('^(?:[ABCDEF]|main)\b'); };
package main;

eval { &A::a(1, "CrOaKiNg"); };

if ($@ =~ /\bCrOaKiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*1,\ 'CrOaKiNg'\)\ called\ at\ .+\n
         .*\bE::e\(1,\ 'CrOaKiNg'\)\ called\ at\ .+\n
         .*\bD::d\(1,\ 'CrOaKiNg'\)\ called\ at\ .+\n
         .*\bC::c\(1,\ 'CrOaKiNg'\)\ called\ at\ .+\n
         .*\bB::b\(1,\ 'CrOaKiNg'\)\ called\ at\ .+\n
         .*\bA::a\(1,\ 'CrOaKiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { &A::a(2, "CoNfEsSiNg"); };

if ($@ =~ /\bCoNfEsSiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bE::e\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bD::d\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bC::c\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bB::b\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bA::a\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { local $SIG{'__WARN__'} = sub { die $_[0]; }; &A::a(3, "CaRpInG"); };

if ($@ =~ /\bCaRpInG\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*3,\ 'CaRpInG'\)\ called\ at\ .+\n
         .*\bE::e\(3,\ 'CaRpInG'\)\ called\ at\ .+\n
         .*\bD::d\(3,\ 'CaRpInG'\)\ called\ at\ .+\n
         .*\bC::c\(3,\ 'CaRpInG'\)\ called\ at\ .+\n
         .*\bB::b\(3,\ 'CaRpInG'\)\ called\ at\ .+\n
         .*\bA::a\(3,\ 'CaRpInG'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { local $SIG{'__WARN__'} = sub { die $_[0]; }; &A::a(4, "ClUcKiNg"); };

if ($@ =~ /\bClUcKiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bE::e\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bD::d\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bC::c\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bB::b\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bA::a\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

package F;
eval { local $^W = 0; Carp::Clan->import('.'); };
package main;

eval { &A::a(1, "CrOaKiNg"); };

if ($@ =~ /\bCrOaKiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*1,\ 'CrOaKiNg'\)\ called\ at\ .+\n
         .*\bE::e\(1,\ 'CrOaKiNg'\)\ called\ at\ .+\n
         .*\bD::d\(1,\ 'CrOaKiNg'\)\ called\ at\ .+\n
         .*\bC::c\(1,\ 'CrOaKiNg'\)\ called\ at\ .+\n
         .*\bB::b\(1,\ 'CrOaKiNg'\)\ called\ at\ .+\n
         .*\bA::a\(1,\ 'CrOaKiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { &A::a(2, "CoNfEsSiNg"); };

if ($@ =~ /\bCoNfEsSiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bE::e\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bD::d\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bC::c\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bB::b\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bA::a\(2,\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { local $SIG{'__WARN__'} = sub { die $_[0]; }; &A::a(3, "CaRpInG"); };

if ($@ =~ /\bCaRpInG\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*3,\ 'CaRpInG'\)\ called\ at\ .+\n
         .*\bE::e\(3,\ 'CaRpInG'\)\ called\ at\ .+\n
         .*\bD::d\(3,\ 'CaRpInG'\)\ called\ at\ .+\n
         .*\bC::c\(3,\ 'CaRpInG'\)\ called\ at\ .+\n
         .*\bB::b\(3,\ 'CaRpInG'\)\ called\ at\ .+\n
         .*\bA::a\(3,\ 'CaRpInG'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { local $SIG{'__WARN__'} = sub { die $_[0]; }; &A::a(4, "ClUcKiNg"); };

if ($@ =~ /\bClUcKiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bE::e\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bD::d\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bC::c\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bB::b\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bA::a\(4,\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

