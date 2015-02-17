use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $check0 = 0;
my $check1 = 0;
my $now = time;
my $then = (stat('./Makefile.old'))[9];
# set number of seconds to view
my $view = $then +86400 < $now ? 5:0;

my $pv = sprintf "%vd", $^V;
unless ($pv lt '5.8.0' || $pv gt '5.8.5') {
  print
qq(
#################################################################
######################### WARNING ###############################
#								#
#        YOUR VERSION OF PERL = $pv HAS SERIOUS BUGS		#
#								#
# Early versions of perl 5.8.x contain bugs that cause certain 	#
# \@_ operations to fail. 	See perl bug [ 23429]		#
#	Please upgrade to at least perl 5.8.6			#
#                                                              	# 
################################################################# 
);
  sleep $view if $view;
}

unless (grep { m/-noxs/ } @ARGV) {
  print q{
This build requires a C compiler by default except on Windows where
the Pure Perl version is mandatory. The Pure Perl version, which does
not require compilation of XS code, can be used by invoking this as:

  perl Makefile.PL -noxs

};
  sleep $view if $view;
}

sleep $view if $view && ($check0 || $check1);

print <<EOF;

======================================================================
W A R N I N G - Please do read below if you have legacy code
======================================================================

Versions 3.21 and above of NetAddr::IP, include hooks for the Storable
class that are incompatible with the old (automatic) method of storing
data. To regain backwards compatibility, the module must be use()d as

    use NetAddr::IP ':old_storable';

which will disable the new hooks and revert back to the old ways.

If you do not use Storable along with NetAddr::IP, or just don't know
what this all means, most likely you're safe to go ahead.

Versions before 3.25 recognized by default IP addresses as returned by
inet_aton. This is no longer the default. To enable this behavior
again, the module must be use()d as

    use NetAddr::IP ':aton';

Versions before 4.008 recognized the above syntax. This behavior is
fundamentally broken, is DEPRECATED and WILL BE REMOVED in version 5.0
Use this method to create new objects from 'aton's

    \$ip = new_from_aton NetAddr::IP(inet_aton('1.2.3.4'))

EOF
    ;
sleep $view if $view;

my %makeparms = (
#	      (MM->can('signature_target') ? (SIGN => 1) : ()),
	      'NAME'		=> 'NetAddr::IP',
	      'VERSION_FROM'	=> 'IP.pm', # finds $VERSION
	      'PREREQ_PM'		=> {
		  Test::More => 0,
		}, # e.g., Module::Name => 1.1
	      ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       (ABSTRACT_FROM	=> 'IP.pm',
		AUTHOR     	=> 'Luis E. Muñoz <luismunoz@cpan.org>, Michael Robinton <miker@cpan.org>') : ()),
		clean		=> { FILES    => "*~ tmp* META.yml"},
);

WriteMakefile(%makeparms);
