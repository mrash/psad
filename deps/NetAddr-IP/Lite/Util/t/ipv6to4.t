# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}

use NetAddr::IP::Util qw(
	inet_ntoa
	inet_any2n
	ipv6_n2d
	ipv6to4
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

my $nip = inet_any2n('1.2.3.4');
my $exp = '0:0:0:0:0:0:1.2.3.4';

## test 2	check that we have an ipv6 netaddr
my $ipv6 = ipv6_n2d($nip);
print "got: $ipv6\nexp: $exp\nnot "
	unless $ipv6 eq $exp;
&ok;

## test 3	check conversion back to ipv4
$exp = '1.2.3.4';
print "got: $_, exp: $exp\nnot "
	unless inet_ntoa(ipv6to4($nip)) eq $exp;
&ok;

## test 4	check bad length
$nip = pack("H9",0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09);
eval {
	ipv6to4($nip);
};
print "ipv6to4 accepted bad argument length\nnot "
	unless $@ && $@ =~ /Bad arg.+ipv6to4/;
&ok;
