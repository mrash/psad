# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}

use NetAddr::IP::Util qw(
	inet_aton
	ipv6_n2d
	ipv6_aton
	ipv4to6
	mask4to6
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

my $nip = inet_aton('1.2.3.4');
my $exp = '0:0:0:0:0:0:1.2.3.4';

## test 2	check 4->6 conversion
my $nipv6 = ipv4to6($nip);
my $ipv6 = ipv6_n2d($nipv6);
print "got: $ipv6\nexp: $exp\nnot "
	unless $ipv6 eq $exp;
&ok;


## test 3	check mask4->6 extension
$exp = 'FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:1.2.3.4';
$nipv6 = mask4to6($nip);
$ipv6 = ipv6_n2d($nipv6);
print "got: $ipv6\nexp: $exp\nnot "
	unless $ipv6 eq $exp;
&ok;

## test 4	check bad length
$nip = pack("H9",0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09);
eval {
	ipv4to6($nip);
};
print "ipv4to6 accepted bad argument length\nnot "
	unless $@ && $@ =~ /Bad arg.+ipv4to6/;
&ok;

## test 5	check bad length
eval {
	mask4to6($nip);
};
print "mask4to6 accepted bad argument length\nnot "
	unless $@ && $@ =~ /Bad arg.+mask4to6/;
&ok;

