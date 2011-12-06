use ExtUtils::MakeMaker;
use Config;

my $pkg = 'NetAddr::IP::Lite';
$pkg =~ /[^:]+$/;
my $module = $& .'.pm';

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %makeparms = (
    'NAME'		=> $pkg,
    'VERSION_FROM'	=> $module, # finds $VERSION
    'PREREQ_PM'		=> {Test::More	=> 0,
			},
    'clean'		=> { FILES    => "*~ tmp*"},
    'dist'		=> {COMPRESS=>'gzip', SUFFIX=>'gz'}
);

sub MY::top_targets {
  package MY;
  my $inherited = shift->SUPER::top_targets(@_);
  $inherited =~ s/(pure_all\s+::.+)/$1 README/;
  $inherited;
}

sub MY::post_constants {
  my $post_constants = q|
MY_POD2TEXT = |. $Config{scriptdirexp} .'/pod2text' .q|
|;
}

sub MY::postamble {
  package MY;
  my $postamble = q|
README  : |. $module .q|
	@$(MY_POD2TEXT) |. $module .q| > README

|;
}

WriteMakefile(%makeparms);
