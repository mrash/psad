# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Config;
use NetAddr::IP::InetBase qw(
	AF_INET
	AF_INET6
	fake_AF_INET6
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

## test 2 - 13	add stuff to buffer
my $af;
print "AF_INET = 2 not found in the Socket library\nnot "
	unless ($af = AF_INET()) && $af == 2;
&ok;

my $fake = fake_AF_INET6();
my $af_inet6 = AF_INET6();
my $txt = $fake
	? "\n\tSocket does not have AF_INET6, Socket6 not present\n\tguessed AF_INET6 for '$Config{osname}' = $fake\n"
	: "\n\tAF_INET6 = $af_inet6 derived from Socket or Socket6\n";
print STDERR $txt;
&ok;
