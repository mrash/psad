# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)
$| = 1;
END {print "1..1\nnot ok 1\n" unless $test;}

use NetAddr::IP::Util qw(
	ipv6_aton
	ipv6_n2x
);

$test = 1;

sub ok {
  print "ok $test\n";
  ++$test;
}

my @addr =
qw(	::			0:0:0:0:0:0:0:0
	:::			undef
	foo			undef
	::foo			undef
	foo::			undef
	abc::def::9		undef
	abcd1::			undef
	abcd::			abcd:0:0:0:0:0:0:0
	::abcde			undef
	:a:b:c:d:1:2:3:4	undef
	:a:b:c:d		undef
	a:b:c:d:1:2:3:4:	undef
	a:b:c:d:1:2:3:4::	undef
	::a:b:c:d:1:2:3:4	undef
	::a:b:c:d:1:2:3		0:a:b:c:d:1:2:3
	::a:b:c:d:1:2:3:	undef
	:a:b:c:d:1:2:3::	undef
	a:b:c:d:1:2:3::		a:b:c:d:1:2:3:0
);

my $x = @addr/2;

# notify TEST about number of tests
# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

print '1..',$x,"\n";

for ($x = 0;$x <= $#addr; $x+=2) {
  my $bstr = ipv6_aton($addr[$x]);
  if ($addr[$x +1] =~ /undef/) {
    print "unexpected return value for $addr[$x]: $_\nnot "
	if ($_ = ipv6_aton && (ipv6_n2x($_) || 'not defined'));
  } else {
    my $rv = ipv6_aton($addr[$x]);
    unless ($rv) {
      print "got undefined value for $addr[$x]\nnot ";
    }
    else {
      $rv = ipv6_n2x($rv) || 'not defined';
      print "got: $rv, exp: $addr[$x +1]\nnot "
	unless $rv eq uc $addr[$x +1];
    }
  }
  &ok;
}
