# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use NetAddr::IP::Util qw(
	:noSock6
	naip_gethostbyname
	havegethostbyname2
	ipv6_n2x
	inet_aton
);

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

my $exp = '0:0:0:0:FFFF:FFFF:7F00:1';
my $host = '127.1';
my $got = ipv6_n2x( scalar naip_gethostbyname($host));
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

$exp = '0:0:0:0:0:0:0:1';
$host = $exp;

if (havegethostbyname2()) {
  $got = ipv6_n2x(scalar naip_gethostbyname($host));
  print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
} else {
  $got = scalar naip_gethostbyname($host);
  if ($got) {
    $got = eval{ inet_ntoa($got) } ||
	   eval{ ipv6_n2x($got) };
  }
  print "unexpected return value got: $got\nnot "
	if $got;
}
&ok;
