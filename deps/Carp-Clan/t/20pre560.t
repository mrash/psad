#!perl -w

#BEGIN
#{
#    if ($] >= 5.006) { print "1..0 # skip current Perl version $] >= 5.006000\n"; exit 0; }
#}

use strict;
no strict "vars";

# ======================================================================
#   $version = $Carp::Clan::VERSION;
# ======================================================================

# Test whether Carp::Clan loads and compiles correctly,
# and whether this distribution is self-consistent:

$Carp::Clan::VERSION = $Carp::Clan::VERSION = 0;

print "1..3\n";

$n = 1;

eval { require Carp::Clan; };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { Carp::Clan->import( qw(^Carp\\b) ); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($Carp::Clan::VERSION eq '6.04')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

