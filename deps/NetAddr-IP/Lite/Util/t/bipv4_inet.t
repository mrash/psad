# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..13\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use NetAddr::IP::InetBase qw(
	inet_ntoa
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

## test 2	add stuff to buffer
my @num = # addr
qw(
	0.0.0.0
	255.255.255.255
	1.2.3.4
	10.253.230.9
);

foreach (@num) {
  my @digs = split(/\./,$_);
  my $pkd = pack('C4',@digs);
  my $naddr = inet_aton($_);
  my $addr = join('.',unpack('C4',$naddr));
  my $num = inet_ntoa($pkd);

  print "bits do not match\nnot "
	unless $naddr eq $pkd;
  &ok;

  print "inet_aton: $addr, exp: $_\nnot "
	unless $addr eq $_;
  &ok;

  print "inet_ntoa: $num, exp: $_\nnot "
	unless $num eq $_;
  &ok;
}
