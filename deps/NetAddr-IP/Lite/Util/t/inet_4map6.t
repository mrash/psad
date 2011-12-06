# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)
$| = 1;
END {print "1..1\nnot ok 1\n" unless $test;}

#use diagnostics;
use NetAddr::IP::Util qw(
	ipv6_n2d
	inet_aton
	ipv6_aton
	inet_4map6
);

$test = 1;

sub ok {
  print "ok $test\n";
  ++$test;
}

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
print "1..6\n";

my @stuff = qw(
	192.168.1.1
	1.2.3.4
	::3.4.5.6
	::FFFF:FFFF:4.5.6.7
	::1:5.4.3.2
	::FEFF:FFFF:4.3.2.1
);

  my $p4 = '0:0:0:0:FFFF:FFFF:';
  my $p6 = '0:0:0:0:';

  foreach(0..$#stuff) {
    my $pass = 1;
    my $result;
    my $bstr;
    $pass = 0 if $_ > 3;
    if ($stuff[$_] =~ /\:/) {
      $bstr = ipv6_aton($stuff[$_]);
      my $prefix = ($stuff[$_] =~ /^\:\:F/)
	? $p6 : $p4;
      ($result = $stuff[$_]) =~ s/\:\:/$prefix/;
    }
    else {
      $bstr = inet_aton($stuff[$_]);
      $result = $p4 . $stuff[$_];
    }
    my $rv = inet_4map6($bstr);
    if ($pass && ! $rv) {
      print "failed to return valid address\nnot ";
    }
    elsif ($pass) {
      $rv = ipv6_n2d($rv);
      print "got: $rv, exp: $result\nnot " unless $rv eq $result;
    }
    else {
      print 'unknown return ', ipv6_n2d($rv), "\nnot " if $rv;
    }
    &ok;
  }

