#!perl -w

#BEGIN
#{
#    if ($] < 5.006) { print "1..0 # skip current Perl version $] < 5.006000\n"; exit 0; }
#}

use strict;

my $USE_OBJECT_DEADLY = eval {
    require Object::Deadly;
    Object::Deadly->VERSION >= 0.08 or die;
    return 1;
};
if ($USE_OBJECT_DEADLY) {
    print '# Using Object::Deadly ' . Object::Deadly->VERSION . "\n";
}

# ======================================================================
#   use Carp::Clan qw(package::pattern);
#   croak();
#   confess();
#   carp();
#   cluck();
# ======================================================================

# NOTE: Certain ugly contortions needed only for crappy Perl 5.6.0!
# (sorry for the outbreak :-) )

sub diag {
    use overload;
    my $msg = join ' ', map { overload::StrVal($_) } @_;
    $msg =~ s/^/# /mg;
    $msg =~ s/(?<!=\n)\z/\n/;
    print $msg;
    return $msg;
}

print "1..55\n";

my $n = 1;

# If a person's environment predefined carp/croak/confess/cluck then I
# need to know to ignore whether it was properly imported and just
# trust that I have something that works.
my %skip_import_tests;
{
    no strict 'refs';
    @skip_import_tests{ grep { exists(${*{'main::'}}{$_}) and defined(&{${*{'main::'}}{$_}}) }
            qw( croak confess carp cluck ) } = ();
}

eval { require Carp::Clan; };
unless ($@) { print "ok $n\n"; }
else { print "not ok $n\n"; }
$n++;

# Test that stuff that didn't exist before loading Carp::Clan still
# doesn't exist.
for my $function (qw(croak confess carp cluck )) {
    no strict 'refs';
    if ( exists $skip_import_tests{$function} ) {
        print
            "ok $n # skip $function was already defined. Can't test import\n";
    }
    elsif ( not (exists(${*{'main::'}}{$function}) and defined(&{${*{'main::'}}{$function}})) ) {
        print "ok $n\n";
    }
    else {
        print "not ok $n\n";
    }
    ++$n;
}

# Import stuff.
eval { Carp::Clan->import(); };
unless ($@) { print "ok $n\n"; }
else { print "not ok $n\n"; }
$n++;

# Test that everything I expect to exist does.
for my $function (qw(croak confess carp cluck)) {
    no strict 'refs';
    my $name = "$function is defined";
    if ( defined &{"main::$function"} ) {
        print "ok $n # $name\n";
    }
    else {
        print "not ok $n # $name\n";
    }
    ++$n;
}

# Create a hierarchy of packages to create a call stack:
# A( B( C( D( E( F( carp/croak/cluck/confess ))))))
package A;
sub a { B::b(@_); }

package B;
sub b { C::c(@_); }

package C;
sub c { D::d(@_); }

package D;
sub d { E::e(@_); }

package E;
sub e { F::f(@_); }

package F;

eval { Carp::Clan->import(); };

sub f {
    my $select = shift @_;

    if ( $select eq 'croak' ) {
        F::croak(@_);
    }
    elsif ( $select eq 'confess' ) {
        F::confess(@_);
    }
    elsif ( $select eq 'carp' ) {
        F::carp(@_);
    }
    elsif ( $select eq 'cluck' ) {
        F::cluck(@_);
    }
    else {
        die "Invalid function: $select";
    }
}

package main;

eval { main::croak('CROAKing'); };

if ( $@ =~ /^.+\bCROAKing at .+$/ )    # no "\n" except at EOL
{
    print "ok $n\n";
}
else { print "not ok $n\n"; }
$n++;

eval { main::confess('CONFESSing'); };

if ( $@ =~ /\bCONFESSing at .+\n.*\b(?:eval {\.\.\.}|require 0) called at\b/ )
{
    print "ok $n\n";
}
else { print "not ok $n\n"; }
$n++;

eval {
    local $SIG{'__WARN__'} = sub { die $_[0]; };
    main::carp('CARPing');
};

if ( $@ =~ /^.+\bCARPing at .+$/ )    # no "\n" except at EOL
{
    print "ok $n\n";
}
else { print "not ok $n\n"; }
$n++;

eval {
    local $SIG{'__WARN__'} = sub { die $_[0]; };
    main::cluck('CLUCKing');
};

if ( $@ =~ /\bCLUCKing at .+\n.*\b(?:eval {\.\.\.}|require 0) called at\b/ ) {
    print "ok $n\n";
}
else { print "not ok $n\n"; }
$n++;

eval { Carp::Clan::croak("croakING"); };

if ( $@ =~ /^.+\bcroakING at .+$/ )    # no "\n" except at EOL
{
    print "ok $n\n";
}
else { print "not ok $n\n"; }
$n++;

eval { Carp::Clan::confess("confessING"); };

if ( $@ =~ /\bconfessING at .+\n.*\b(?:eval {\.\.\.}|require 0) called at\b/ )
{
    print "ok $n\n";
}
else { print "not ok $n\n"; }
$n++;

eval {
    local $SIG{'__WARN__'} = sub { die $_[0]; };
    Carp::Clan::carp("carpING");
};

if ( $@ =~ /^.+\bcarpING at .+$/ )    # no "\n" except at EOL
{
    print "ok $n\n";
}
else { print "not ok $n\n"; }
$n++;

eval {
    local $SIG{'__WARN__'} = sub { die $_[0]; };
    Carp::Clan::cluck("cluckING");
};

if ( $@ =~ /\bcluckING at .+\n.*\b(?:eval {\.\.\.}|require 0) called at\b/ ) {
    print "ok $n\n";
}
else { print "not ok $n\n"; }
$n++;

###############################
# Now testing the real thing: #
###############################

eval { A::a( 'croak', "CrOaKiNg" ); };

if ( $@ =~ /\bF::f\(\): CrOaKiNg at / ) { print "ok $n\n"; }
else { print "not ok $n\n"; }
$n++;

eval { A::a( 'confess', "CoNfEsSiNg" ); };

if ($@ =~ /\bCoNfEsSiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*'confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bE::e\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bD::d\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bC::c\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bB::b\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bA::a\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x
    )
{
    print "ok $n\n";
}
else { print "not ok $n\n"; }
$n++;

eval {
    local $SIG{'__WARN__'} = sub { die $_[0]; };
    A::a( 'carp', "CaRpInG" );
};

if ( $@ =~ /\bF::f\(\): CaRpInG at / ) { print "ok $n\n"; }
else { print "not ok $n\n"; }
$n++;

eval {
    local $SIG{'__WARN__'} = sub { die $_[0]; };
    A::a( 'cluck', "ClUcKiNg" );
};

if ($@ =~ /\bClUcKiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*'cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bE::e\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bD::d\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bC::c\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bB::b\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bA::a\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x
    )
{
    print "ok $n\n";
}
else { print "not ok $n\n"; }
$n++;

package F;
eval { local $^W = 0; Carp::Clan->import('^F\b'); };

package main;

eval { A::a( 'croak', "CrOaKiNg" ); };

if ( $@ =~ /\bF::f\(\): CrOaKiNg at / ) { print "ok $n\n"; }
else { print "not ok $n\n"; }
$n++;

eval { A::a( 'confess', "CoNfEsSiNg" ); };

if ($@ =~ /\bCoNfEsSiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*'confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bE::e\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bD::d\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bC::c\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bB::b\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bA::a\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x
    )
{
    print "ok $n\n";
}
else { print "not ok $n\n"; }
$n++;

eval {
    local $SIG{'__WARN__'} = sub { die $_[0]; };
    A::a( 'carp', "CaRpInG" );
};

if ( $@ =~ /\bF::f\(\): CaRpInG at / ) { print "ok $n\n"; }
else { print "not ok $n\n"; }
$n++;

eval {
    local $SIG{'__WARN__'} = sub { die $_[0]; };
    A::a( 'cluck', "ClUcKiNg" );
};

if ($@ =~ /\bClUcKiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*'cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bE::e\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bD::d\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bC::c\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bB::b\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bA::a\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x
    )
{
    print "ok $n\n";
}
else { print "not ok $n\n"; }
$n++;

package F;
eval { local $^W = 0; Carp::Clan->import('^[EF]\b'); };

package main;

eval { A::a( 'croak', "CrOaKiNg" ); };

if ( $@ =~ /\bE::e\(\): CrOaKiNg at / ) { print "ok $n\n"; }
else { print "not ok $n\n"; }
$n++;

eval { A::a( 'confess', "CoNfEsSiNg" ); };

if ($@ =~ /\bCoNfEsSiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*'confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bE::e\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bD::d\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bC::c\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bB::b\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bA::a\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x
    )
{
    print "ok $n\n";
}
else { print "not ok $n\n"; }
$n++;

eval {
    local $SIG{'__WARN__'} = sub { die $_[0]; };
    A::a( 'carp', "CaRpInG" );
};

if ( $@ =~ /\bE::e\(\): CaRpInG at / ) { print "ok $n\n"; }
else { print "not ok $n\n"; }
$n++;

eval {
    local $SIG{'__WARN__'} = sub { die $_[0]; };
    A::a( 'cluck', "ClUcKiNg" );
};

if ($@ =~ /\bClUcKiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*'cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bE::e\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bD::d\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bC::c\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bB::b\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bA::a\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x
    )
{
    print "ok $n\n";
}
else { print "not ok $n\n"; }
$n++;

package F;
eval { local $^W = 0; Carp::Clan->import('^[DEF]\b'); };

package main;

eval { A::a( 'croak', "CrOaKiNg" ); };

if ( $@ =~ /\bD::d\(\): CrOaKiNg at / ) { print "ok $n\n"; }
else { print "not ok $n\n"; }
$n++;

eval { A::a( 'confess', "CoNfEsSiNg" ); };

if ($@ =~ /\bCoNfEsSiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*'confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bE::e\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bD::d\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bC::c\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bB::b\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bA::a\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x
    )
{
    print "ok $n\n";
}
else { print "not ok $n\n"; }
$n++;

eval {
    local $SIG{'__WARN__'} = sub { die $_[0]; };
    A::a( 'carp', "CaRpInG" );
};

if ( $@ =~ /\bD::d\(\): CaRpInG at / ) { print "ok $n\n"; }
else { print "not ok $n\n"; }
$n++;

eval {
    local $SIG{'__WARN__'} = sub { die $_[0]; };
    A::a( 'cluck', "ClUcKiNg" );
};

if ($@ =~ /\bClUcKiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*'cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bE::e\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bD::d\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bC::c\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bB::b\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bA::a\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x
    )
{
    print "ok $n\n";
}
else { print "not ok $n\n"; }
$n++;

package F;
eval { local $^W = 0; Carp::Clan->import('^[CDEF]\b'); };

package main;

eval { A::a( 'croak', "CrOaKiNg" ); };

if ( $@ =~ /\bC::c\(\): CrOaKiNg at / ) { print "ok $n\n"; }
else { print "not ok $n\n"; }
$n++;

eval { A::a( 'confess', "CoNfEsSiNg" ); };

if ($@ =~ /\bCoNfEsSiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*'confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bE::e\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bD::d\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bC::c\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bB::b\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bA::a\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x
    )
{
    print "ok $n\n";
}
else { print "not ok $n\n"; }
$n++;

eval {
    local $SIG{'__WARN__'} = sub { die $_[0]; };
    A::a( 'carp', "CaRpInG" );
};

if ( $@ =~ /\bC::c\(\): CaRpInG at / ) { print "ok $n\n"; }
else { print "not ok $n\n"; }
$n++;

eval {
    local $SIG{'__WARN__'} = sub { die $_[0]; };
    A::a( 'cluck', "ClUcKiNg" );
};

if ($@ =~ /\bClUcKiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*'cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bE::e\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bD::d\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bC::c\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bB::b\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bA::a\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x
    )
{
    print "ok $n\n";
}
else { print "not ok $n\n"; }
$n++;

package F;
eval { local $^W = 0; Carp::Clan->import('^[BCDEF]\b'); };

package main;

eval { A::a( 'croak', "CrOaKiNg" ); };

if ( $@ =~ /\bB::b\(\): CrOaKiNg at / ) { print "ok $n\n"; }
else { print "not ok $n\n"; }
$n++;

eval { A::a( 'confess', "CoNfEsSiNg" ); };

if ($@ =~ /\bCoNfEsSiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*'confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bE::e\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bD::d\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bC::c\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bB::b\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bA::a\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x
    )
{
    print "ok $n\n";
}
else { print "not ok $n\n"; }
$n++;

eval {
    local $SIG{'__WARN__'} = sub { die $_[0]; };
    A::a( 'carp', "CaRpInG" );
};

if ( $@ =~ /\bB::b\(\): CaRpInG at / ) { print "ok $n\n"; }
else { print "not ok $n\n"; }
$n++;

eval {
    local $SIG{'__WARN__'} = sub { die $_[0]; };
    A::a( 'cluck', "ClUcKiNg" );
};

if ($@ =~ /\bClUcKiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*'cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bE::e\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bD::d\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bC::c\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bB::b\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bA::a\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x
    )
{
    print "ok $n\n";
}
else { print "not ok $n\n"; }
$n++;

package F;
eval { local $^W = 0; Carp::Clan->import('^[ABCDEF]\b'); };

package main;

eval { A::a( 'croak', "CrOaKiNg" ); };

if ( $@ =~ /\bA::a\(\): CrOaKiNg at / ) { print "ok $n\n"; }
else { print "not ok $n\n"; }
$n++;

eval { A::a( 'confess', "CoNfEsSiNg" ); };

if ($@ =~ /\bCoNfEsSiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*'confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bE::e\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bD::d\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bC::c\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bB::b\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bA::a\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x
    )
{
    print "ok $n\n";
}
else { print "not ok $n\n"; }
$n++;

eval {
    local $SIG{'__WARN__'} = sub { die $_[0]; };
    A::a( 'carp', "CaRpInG" );
};

if ( $@ =~ /\bA::a\(\): CaRpInG at / ) { print "ok $n\n"; }
else { print "not ok $n\n"; }
$n++;

eval {
    local $SIG{'__WARN__'} = sub { die $_[0]; };
    A::a( 'cluck', "ClUcKiNg" );
};

if ($@ =~ /\bClUcKiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*'cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bE::e\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bD::d\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bC::c\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bB::b\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bA::a\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x
    )
{
    print "ok $n\n";
}
else { print "not ok $n\n"; }
$n++;

package F;
eval { local $^W = 0; Carp::Clan->import('^(?:[ABCDEF]|main)\b'); };

package main;

eval { A::a( 'croak', "CrOaKiNg" ); };

if ($@ =~ /\bCrOaKiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*'croak',\ 'CrOaKiNg'\)\ called\ at\ .+\n
         .*\bE::e\('croak',\ 'CrOaKiNg'\)\ called\ at\ .+\n
         .*\bD::d\('croak',\ 'CrOaKiNg'\)\ called\ at\ .+\n
         .*\bC::c\('croak',\ 'CrOaKiNg'\)\ called\ at\ .+\n
         .*\bB::b\('croak',\ 'CrOaKiNg'\)\ called\ at\ .+\n
         .*\bA::a\('croak',\ 'CrOaKiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x
    )
{
    print "ok $n\n";
}
else { print "not ok $n\n"; }
$n++;

eval { A::a( 'confess', "CoNfEsSiNg" ); };

if ($@ =~ /\bCoNfEsSiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*'confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bE::e\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bD::d\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bC::c\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bB::b\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bA::a\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x
    )
{
    print "ok $n\n";
}
else { print "not ok $n\n"; }
$n++;

eval {
    local $SIG{'__WARN__'} = sub { die $_[0]; };
    A::a( 'carp', "CaRpInG" );
};

if ($@ =~ /\bCaRpInG\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*'carp',\ 'CaRpInG'\)\ called\ at\ .+\n
         .*\bE::e\('carp',\ 'CaRpInG'\)\ called\ at\ .+\n
         .*\bD::d\('carp',\ 'CaRpInG'\)\ called\ at\ .+\n
         .*\bC::c\('carp',\ 'CaRpInG'\)\ called\ at\ .+\n
         .*\bB::b\('carp',\ 'CaRpInG'\)\ called\ at\ .+\n
         .*\bA::a\('carp',\ 'CaRpInG'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x
    )
{
    print "ok $n\n";
}
else { print "not ok $n\n"; }
$n++;

eval {
    local $SIG{'__WARN__'} = sub { die $_[0]; };
    A::a( 'cluck', "ClUcKiNg" );
};

if ($@ =~ /\bClUcKiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*'cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bE::e\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bD::d\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bC::c\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bB::b\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bA::a\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x
    )
{
    print "ok $n\n";
}
else { print "not ok $n\n"; }
$n++;

package F;
eval { local $^W = 0; Carp::Clan->import('.'); };

package main;

eval { A::a( 'croak', "CrOaKiNg" ); };

if ($@ =~ /\bCrOaKiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*'croak',\ 'CrOaKiNg'\)\ called\ at\ .+\n
         .*\bE::e\('croak',\ 'CrOaKiNg'\)\ called\ at\ .+\n
         .*\bD::d\('croak',\ 'CrOaKiNg'\)\ called\ at\ .+\n
         .*\bC::c\('croak',\ 'CrOaKiNg'\)\ called\ at\ .+\n
         .*\bB::b\('croak',\ 'CrOaKiNg'\)\ called\ at\ .+\n
         .*\bA::a\('croak',\ 'CrOaKiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x
    )
{
    print "ok $n\n";
}
else { print "not ok $n\n"; }
$n++;

eval { A::a( 'confess', "CoNfEsSiNg" ); };

if ($@ =~ /\bCoNfEsSiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*'confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bE::e\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bD::d\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bC::c\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bB::b\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\bA::a\('confess',\ 'CoNfEsSiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x
    )
{
    print "ok $n\n";
}
else { print "not ok $n\n"; }
$n++;

eval {
    local $SIG{'__WARN__'} = sub { die $_[0]; };
    A::a( 'carp', "CaRpInG" );
};

if ($@ =~ /\bCaRpInG\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*'carp',\ 'CaRpInG'\)\ called\ at\ .+\n
         .*\bE::e\('carp',\ 'CaRpInG'\)\ called\ at\ .+\n
         .*\bD::d\('carp',\ 'CaRpInG'\)\ called\ at\ .+\n
         .*\bC::c\('carp',\ 'CaRpInG'\)\ called\ at\ .+\n
         .*\bB::b\('carp',\ 'CaRpInG'\)\ called\ at\ .+\n
         .*\bA::a\('carp',\ 'CaRpInG'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x
    )
{
    print "ok $n\n";
}
else { print "not ok $n\n"; }
$n++;

eval {
    local $SIG{'__WARN__'} = sub { die $_[0]; };
    A::a( 'cluck', "ClUcKiNg" );
};

if ($@ =~ /\bClUcKiNg\ at\ .+\n
         .*\bF::f\((?:\d+,\s*)*'cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bE::e\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bD::d\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bC::c\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bB::b\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\bA::a\('cluck',\ 'ClUcKiNg'\)\ called\ at\ .+\n
         .*\b(?:eval\ {\.\.\.}|require\ 0)\ called\ at\ /x
    )
{
    print "ok $n\n";
}
else { print "not ok $n\n"; }
$n++;

if ($USE_OBJECT_DEADLY) {

    # Test that objects with overloading in the call stack don't have
    # their overloading triggered.
    eval {
        package Elsewhere;
        Carp::Clan->import;

        # Outer function call has an Object::Deadly object.
        sub {

            # Inner function call has an empty arg list
            sub {

            # Call confess which causes the entire call stack to get examined.
                confess('here');
                }
                ->();
            }
            ->( Object::Deadly->new('RIP') );
    };
    if ($@ =~ /\A  Carp::Clan::__ANON__\(\):\ here\ .+\n
               \s+ Elsewhere::__ANON__\(\)\ called\ .+\n
               \s+ Elsewhere::__ANON__\(Object::Deadly .+\n
               \s+ eval/x
        )
    {
        print "ok $n\n";
    }
    else {
        diag($@);
        print "not ok $n\n";
    }
}
else {
    print "ok $n # skip Object::Deadly is not available on this platform\n";
}
$n++;

__END__

