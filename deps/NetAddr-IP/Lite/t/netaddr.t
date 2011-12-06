# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..35\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Data::Dumper;
use NetAddr::IP::Lite;

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

=pod

$rv=list2NetAddr(\@inlist,\@NAobject);

Build of NetAddr object structure from a list of IPv4 addresses or address
ranges. This object is passed to B<matchNetAddr> to check if a given IP
address is contained in the list.

  input:	array reference pointer
		to a list of addresses

  i.e.		11.22.33.44
		11.22.33.0/24
		11.22.33.0/255.255.255.0
		11.22.33.20-11.22.33.46
		11.22.33.20 - 11.22.33.46

  output:	Number of objects created
		or undef on error

The NAobject array is filled with NetAddr::IP::Lite object references.

=cut

sub list2NetAddr {
  my($inref,$outref) = @_;
  return undef
	unless ref $inref eq 'ARRAY'
	&& ref $outref eq 'ARRAY';
  unless ($SKIP_NetAddrIP) {
    require NetAddr::IP::Lite;
    $SKIP_NetAddrIP = 1;
  }
  @$outref = ();
  my $IP;
  no strict;
  foreach $IP (@$inref) {
    $IP =~ s/\s//g;
	# 11.22.33.44
    if ($IP =~ /^\d+\.\d+\.\d+\.\d+$/o) {
      push @$outref, NetAddr::IP::Lite->new($IP), 0;
    }
	# 11.22.33.44 - 11.22.33.49
    elsif ($IP =~ /^(\d+\.\d+\.\d+\.\d+)\s*\-\s*(\d+\.\d+\.\d+\.\d+)$/o) {
      push @$outref, NetAddr::IP::Lite->new($1), NetAddr::IP::Lite->new($2);
    }
	# 11.22.33.44/63
    elsif ($IP =~ m|^\d+\.\d+\.\d+\.\d+/\d+$|) {
      push @$outref, NetAddr::IP::Lite->new($IP), 0;
    }
	# 11.22.33.44/255.255.255.224
    elsif ($IP =~ m|^\d+\.\d+\.\d+\.\d+/\d+\.\d+\.\d+\.\d+$|o) {
      push @$outref, NetAddr::IP::Lite->new($IP), 0;
    }
# ignore un-matched IP patterns
  }
  return (scalar @$outref)/2;
}

=pod

$rv = matchNetAddr($ip,\@NAobject);

Check if an IP address appears in a list of NetAddr objects.

  input:	dot quad IP address,
		reference to NetAddr objects
  output:	true if match else false

=cut

sub matchNetAddr {
  my($ip,$naref) = @_;
  return 0 unless $ip && $ip =~ /\d+\.\d+\.\d+\.\d+/;
  $ip =~ s/\s//g;
  $ip = new NetAddr::IP::Lite($ip);
  my $i;
  for($i=0; $i <= $#{$naref}; $i += 2) {
    my $beg = $naref->[$i];
    my $end = $naref->[$i+1];
    if ($end) {
      return 1  if $ip >= $beg && $ip <= $end;
    } else {
      return 1 if $ip->within($beg);
    }
  }
  return 0;
}



$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

## test 2	instantiate netaddr array
#
# A multi-formated array of IP address that will never be tarpitted.
#
# WARNING: if you are using a private network, then you should include the
# address description for the net/subnets that you are using or you might
# find your DMZ or internal mail servers blocked since many DNSBLS list the
# private network addresses as BLACKLISTED
#
#       127./8, 10./8, 172.16/12, 192.168/16
#
#       class A         xxx.0.0.0/8
#       class B         xxx.xxx.0.0/16
#       class C         xxx.xxx.xxx.0/24	0
#       128 subnet      xxx.xxx.xxx.xxx/25	128
#        64 subnet      xxx.xxx.xxx.xxx/26	192
#        32 subnet      xxx.xxx.xxx.xxx/27	224
#        16 subnet      xxx.xxx.xxx.xxx/28	240
#         8 subnet      xxx.xxx.xxx.xxx/29	248
#         4 subnet      xxx.xxx.xxx.xxx/30	252
#         2 subnet      xxx.xxx.xxx.xxx/31	254
#       single address  xxx.xxx.xxx.xxx/32	255
#
@tstrng = (
	    # a single address
	'11.22.33.44',
	    # a range of ip's, ONLY VALID WITHIN THE SAME CLASS 'C'
	'22.33.44.55 - 22.33.44.65',
	'45.67.89.10-45.67.89.32',
	    # a CIDR range
	'5.6.7.16/28',
	    # a range specified with a netmask
	'7.8.9.128/255.255.255.240',
	    # this should ALWAYS be here
	'127.0.0.0/8',  # ignore all test entries and localhost
);
my @NAobject;
my $rv = list2NetAddr(\@tstrng,\@NAobject);
print "wrong number of NA objects\ngot: $rv, exp: 6\nnot "
	unless $rv == 6;
&ok;

## test 3	check disallowed terms
print "accepted null parameter\nnot "
	if matchNetAddr();
&ok;

## test 4	check disallowed parm
print "accepted non-numeric parameter\nnot "
	if matchNetAddr('junk');
&ok;

##test 5	check non-ip short
print "accepted short ip segment\nnot "
	if matchNetAddr('1.2.3');
&ok;

# yeah, it will accept a long one, but that's tough!

## test 6-35	bracket NA objects
#
my @chkary =	# 5 x 6 tests
    #	out left	in left		middle		in right	out right
qw(	11.22.33.43	11.22.33.44	11.22.33.44	11.22.33.44	11.22.33.45
	22.33.44.54	22.33.44.55	22.33.44.60	22.33.44.65	22.33.44.66
	45.67.89.9	45.67.89.10	45.67.89.20	45.67.89.32	45.67.89.33
	5.6.7.15	5.6.7.16	5.6.7.20	5.6.7.31	5.6.7.32
	7.8.9.127	7.8.9.128	7.8.9.138	7.8.9.143	7.8.9.144
	126.255.255.255	127.0.0.0	127.128.128.128	127.255.255.255	128.0.0.0
);

for(my $i=0;$i <= $#chkary; $i+=5) {
  print "accepted outside left bound $chkary[$i]\nnot "
	if matchNetAddr($chkary[$i],\@NAobject);
  &ok;
  print "rejected inside left bound $chkary[$i+1]\nnot "
	unless matchNetAddr($chkary[$i+1],\@NAobject);
  &ok;
  print "rejected inside middle bound $chkary[$i+2]\nnot "
	unless matchNetAddr($chkary[$i+2],\@NAobject);
  &ok;
  print "rejected inside right bound $chkary[$i+3]\nnot "
	unless matchNetAddr($chkary[$i+3],\@NAobject);
  &ok;
  print "accepted outside right bound $chkary[$i+4]\nnot "
	if matchNetAddr($chkary[$i+4],\@NAobject);
  &ok;
}
