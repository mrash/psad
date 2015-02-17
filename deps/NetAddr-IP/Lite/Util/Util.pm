#!/usr/bin/perl
package NetAddr::IP::Util;

use strict;
#use diagnostics;
#use lib qw(blib/lib);

use vars qw($VERSION @EXPORT_OK @ISA %EXPORT_TAGS $Mode);
use AutoLoader qw(AUTOLOAD);
use NetAddr::IP::Util_IS;
use NetAddr::IP::InetBase qw(
	:upper
	:all
);

*NetAddr::IP::Util::upper = \&NetAddr::IP::InetBase::upper;
*NetAddr::IP::Util::lower = \&NetAddr::IP::InetBase::lower;

require DynaLoader;
require Exporter;

@ISA = qw(Exporter DynaLoader);

$VERSION = do { my @r = (q$Revision: 1.51 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

@EXPORT_OK = qw(
	inet_aton
	inet_ntoa
	ipv6_aton
	ipv6_ntoa
	ipv6_n2x
	ipv6_n2d
	inet_any2n
	hasbits
	isIPv4
	isNewIPv4
	isAnyIPv4
	inet_n2dx
	inet_n2ad
	inet_pton
	inet_ntop
	inet_4map6
	shiftleft
	addconst
	add128
	sub128
	notcontiguous
	bin2bcd
	bcd2bin
	mode
	ipv4to6
	mask4to6
	ipanyto6
	maskanyto6
	ipv6to4
	bin2bcdn
	bcdn2txt
	bcdn2bin
	simple_pack
	comp128
	packzeros
	AF_INET
	AF_INET6
	naip_gethostbyname
	havegethostbyname2
);

%EXPORT_TAGS = (
	all     => [@EXPORT_OK],
	inet	=> [qw(
		inet_aton
		inet_ntoa
		ipv6_aton
		ipv6_ntoa
		ipv6_n2x
		ipv6_n2d
		inet_any2n
		inet_n2dx
		inet_n2ad
		inet_pton
		inet_ntop
		inet_4map6
		ipv4to6
		mask4to6
		ipanyto6
		maskanyto6
		ipv6to4
		packzeros
		naip_gethostbyname
	)],
	math	=> [qw(
		shiftleft
		hasbits
		isIPv4
		isNewIPv4
		isAnyIPv4
		addconst
		add128
		sub128
		notcontiguous
		bin2bcd
		bcd2bin
	)],
	ipv4	=> [qw(
		inet_aton
		inet_ntoa
	)],
	ipv6	=> [qw(
		ipv6_aton
		ipv6_ntoa
		ipv6_n2x
		ipv6_n2d
		inet_any2n
		inet_n2dx
		inet_n2ad
		inet_pton
		inet_ntop
		inet_4map6
		ipv4to6
		mask4to6
		ipanyto6
		maskanyto6
		ipv6to4
		packzeros
		naip_gethostbyname
	)],
);

if (NetAddr::IP::Util_IS->not_pure) {
  eval {		## attempt to load 'C' version of utilities
	bootstrap NetAddr::IP::Util $VERSION;
  };
}
if (NetAddr::IP::Util_IS->pure || $@) {	## load the pure perl version if 'C' lib missing
  require NetAddr::IP::UtilPP;
  import NetAddr::IP::UtilPP qw( :all );
#  require Socket;
#  import Socket qw(inet_ntoa);
#  *yinet_aton = \&Socket::inet_aton;
  $Mode = 'Pure Perl';
}
else {
  $Mode = 'CC XS';
}

# if Socket lib is broken in some way, check for overange values
#
#my $overange = yinet_aton('256.1') ? 1:0;
#my $overange = gethostbyname('256.1') ? 1:0;

sub mode() { $Mode };

my $_newV4compat = pack('N4',0,0,0xffff,0);

sub inet_4map6 {
  my $naddr = shift;
  if (length($naddr) == 4) {
    $naddr = ipv4to6($naddr);
  }
  elsif (length($naddr) == 16) {
    ;	# is OK
    return undef unless isAnyIPv4($naddr);
  } else {
    return undef;
  }
  $naddr |= $_newV4compat;
  return $naddr;
}

sub DESTROY {};

my $havegethostbyname2 = 0;

my $mygethostbyname;

my $_Sock6ok = 1;		# for testing gethostbyname

sub havegethostbyname2 {
  return $_Sock6ok
	? $havegethostbyname2
	: 0;
}

sub import {
  if (grep { $_ eq ':noSock6' } @_) {
	$_Sock6ok = 0;
	@_ = grep { $_ ne ':noSock6' } @_;
  }
  NetAddr::IP::Util->export_to_level(1,@_);
}

package NetAddr::IP::UtilPolluted;

# Socket pollutes the name space with all of its symbols. Since
# we don't want them all, confine them to this name space.

use strict;
use Socket;

my $_v4zero = pack('L',0);
my $_zero = pack('L4',0,0,0,0);

# invoke replacement subroutine for Perl's "gethostbyname"
# if Socket6 is available.
#
# NOTE: in certain BSD implementations, Perl's gethostbyname is broken
# we will use our own InetBase::inet_aton instead

sub _end_gethostbyname {
#  my ($name,$aliases,$addrtype,$length,@addrs) = @_;
  my @rv = @_;
# first ip address = rv[4]
  my $tip = $rv[4];
  unless ($tip && $tip ne $_v4zero && $tip ne $_zero) {
    @rv = ();
  }
# length = rv[3]
  elsif ($rv[3] && $rv[3] == 4) {
    foreach (4..$#rv) {
      $rv[$_] = NetAddr::IP::Util::inet_4map6(NetAddr::IP::Util::ipv4to6($rv[$_]));
    }
    $rv[3] = 16;	# unconditionally set length to 16
  }
  elsif ($rv[3] == 16) {
    ;	# is ok
  } else {
    @rv = ();
  }
  return @rv;
}

unless ( eval { require Socket6 }) {
  $mygethostbyname = sub {
# SEE NOTE above about broken BSD
	my @tip = gethostbyname(NetAddr::IP::InetBase::fillIPv4($_[0]));
	return &_end_gethostbyname(@tip);
  };
} else {
  import Socket6 qw( gethostbyname2 getipnodebyname );
  my $try = eval { my @try = gethostbyname2('127.0.0.1',NetAddr::IP::Util::AF_INET()); $try[4] };
  if (! $@ && $try && $try eq INADDR_LOOPBACK()) {
    *_ghbn2 = \&Socket6::gethostbyname2;
    $havegethostbyname2 = 1;
  } else {
    *_ghbn2 = sub { return () };	# use failure branch below
  }

  $mygethostbyname = sub {
	my @tip;
        unless ($_Sock6ok && (@tip = _ghbn2($_[0],NetAddr::IP::Util::AF_INET6())) && @tip > 1) {
# SEE NOTE above about broken BSD
          @tip = gethostbyname(NetAddr::IP::InetBase::fillIPv4($_[0]));
        }
	return &_end_gethostbyname(@tip);
  };
}

package NetAddr::IP::Util;

sub naip_gethostbyname {
# turn off complaint from Socket6 about missing numeric argument
  undef local $^W;
  my @rv = &$mygethostbyname($_[0]);
  return wantarray
	? @rv
	: $rv[4];
}

1;

__END__

=head1 NAME

NetAddr::IP::Util -- IPv4/6 and 128 bit number utilities

=head1 SYNOPSIS

  use NetAddr::IP::Util qw(
	inet_aton
	inet_ntoa
	ipv6_aton
	ipv6_ntoa
	ipv6_n2x
	ipv6_n2d
	inet_any2n
	hasbits
	isIPv4
	isNewIPv4
	isAnyIPv4
	inet_n2dx
	inet_n2ad
	inet_pton
	inet_ntop
	inet_4map6
	ipv4to6
	mask4to6
	ipanyto6
	maskanyto6
	ipv6to4
	packzeros
	shiftleft
	addconst
	add128
	sub128
	notcontiguous
	bin2bcd
	bcd2bin
	mode
	AF_INET
	AF_INET6
	naip_gethostbyname
  );

  use NetAddr::IP::Util qw(:all :inet :ipv4 :ipv6 :math)

  :inet	  =>	inet_aton, inet_ntoa, ipv6_aton
		ipv6_ntoa, ipv6_n2x, ipv6_n2d, 
		inet_any2n, inet_n2dx, inet_n2ad, 
		inet_pton, inet_ntop, inet_4map6, 
		ipv4to6, mask4to6, ipanyto6, packzeros
		maskanyto6, ipv6to4, naip_gethostbyname

  :ipv4	  =>	inet_aton, inet_ntoa

  :ipv6	  =>	ipv6_aton, ipv6_ntoa, ipv6_n2x, 
		ipv6_n2d, inet_any2n, inet_n2dx, 
		inet_n2ad, inet_pton, inet_ntop,
		inet_4map6, ipv4to6, mask4to6,
		ipanyto6, maskanyto6, ipv6to4,
		packzeros, naip_gethostbyname

  :math	  =>	hasbits, isIPv4, isNewIPv4, isAnyIPv4,
		addconst, add128, sub128, notcontiguous,
		bin2bcd, bcd2bin, shiftleft

  $dotquad = inet_ntoa($netaddr);
  $netaddr = inet_aton($dotquad);
  $ipv6naddr = ipv6_aton($ipv6_text);
  $ipv6_text = ipvt_ntoa($ipv6naddr);
  $hex_text = ipv6_n2x($ipv6naddr);
  $dec_text = ipv6_n2d($ipv6naddr);
  $hex_text = packzeros($hex_text);
  $ipv6naddr = inet_any2n($dotquad or $ipv6_text);
  $ipv6naddr = inet_4map6($netaddr or $ipv6naddr);
  $rv = hasbits($bits128);
  $rv = isIPv4($bits128);
  $rv = isNewIPv4($bits128);
  $rv = isAnyIPv4($bits128);
  $dotquad or $hex_text = inet_n2dx($ipv6naddr);
  $dotquad or $dec_text = inet_n2ad($ipv6naddr);
  $netaddr = inet_pton($AF_family,$hex_text);
  $hex_text = inet_ntop($AF_family,$netaddr);
  $ipv6naddr = ipv4to6($netaddr);
  $ipv6naddr = mask4to6($netaddr);
  $ipv6naddr = ipanyto6($netaddr);
  $ipv6naddr = maskanyto6($netaddr);
  $netaddr = ipv6to4($pv6naddr);
  $bitsX2 = shiftleft($bits128,$n);
  $carry = addconst($ipv6naddr,$signed_32con);
  ($carry,$ipv6naddr)=addconst($ipv6naddr,$signed_32con);
  $carry = add128($ipv6naddr1,$ipv6naddr2);
  ($carry,$ipv6naddr)=add128($ipv6naddr1,$ipv6naddr2);
  $carry = sub128($ipv6naddr1,$ipv6naddr2);
  ($carry,$ipv6naddr)=sub128($ipv6naddr1,$ipv6naddr2);
  ($spurious,$cidr) = notcontiguous($mask128);
  $bcdtext = bin2bcd($bits128);
  $bits128 = bcd2bin($bcdtxt);
  $modetext = mode;
  ($name,$aliases,$addrtype,$length,@addrs)=naip_gethostbyname(NAME);
  $trueif = havegethostbyname2();

  NetAddr::IP::Util::lower();
  NetAddr::IP::Util::upper();

=head1 INSTALLATION

Un-tar the distribution in an appropriate directory and type:

	perl Makefile.PL
	make
	make test
	make install

B<NetAddr::IP::Util> installs by default with its primary functions compiled
using Perl's XS extensions to build a 'C' library. If you do not have a 'C'
complier available or would like the slower Pure Perl version for some other
reason, then type:

	perl Makefile.PL -noxs
	make
	make test
	make install

=head1 DESCRIPTION

B<NetAddr::IP::Util> provides a suite of tools for manipulating and
converting IPv4 and IPv6 addresses into 128 bit string context and back to
text. The strings can be manipulated with Perl's logical operators:

	and	&
	or	|
	xor	^
		~	compliment

in the same manner as 'vec' strings.

The IPv6 functions support all rfc1884 formats.

  i.e.	x:x:x:x:x:x:x:x:x
	x:x:x:x:x:x:x:d.d.d.d
	::x:x:x
	::x:d.d.d.d
  and so on...

=over 4

=item * $dotquad = inet_ntoa($netaddr);

Convert a packed IPv4 network address to a dot-quad IP address.

  input:	packed network address
  returns:	IP address i.e. 10.4.12.123

=item * $netaddr = inet_aton($dotquad);

Convert a dot-quad IP address into an IPv4 packed network address.

  input:	IP address i.e. 192.5.16.32
  returns:	packed network address

=item * $ipv6addr = ipv6_aton($ipv6_text);

Takes an IPv6 address of the form described in rfc1884
and returns a 128 bit binary RDATA string.

  input:	ipv6 text
  returns:	128 bit RDATA string

=item * $ipv6_text = ipv6_ntoa($ipv6naddr);

Convert a 128 bit binary IPv6 address to compressed rfc 1884
text representation.

  input:	128 bit RDATA string
  returns:	ipv6 text

=item * $hex_text = ipv6_n2x($ipv6addr);

Takes an IPv6 RDATA string and returns an 8 segment IPv6 hex address

  input:	128 bit RDATA string
  returns:	x:x:x:x:x:x:x:x

=item * $dec_text = ipv6_n2d($ipv6addr);

Takes an IPv6 RDATA string and returns a mixed hex - decimal IPv6 address
with the 6 uppermost chunks in hex and the lower 32 bits in dot-quad
representation.

  input:	128 bit RDATA string
  returns:	x:x:x:x:x:x:d.d.d.d

=item * $ipv6naddr = inet_any2n($dotquad or $ipv6_text);

This function converts a text IPv4 or IPv6 address in text format in any
standard notation into a 128 bit IPv6 string address. It prefixes any
dot-quad address (if found) with '::' and passes it to B<ipv6_aton>.

  input:	dot-quad or rfc1844 address
  returns:	128 bit IPv6 string

=item * $rv = hasbits($bits128);

This function returns true if there are one's present in the 128 bit string
and false if all the bits are zero.

  i.e.	if (hasbits($bits128)) {
	  &do_something;
	}

  or	if (hasbits($bits128 & $mask128) {
	  &do_something;
	}

This allows the implementation of logical functions of the form of:

	if ($bits128 & $mask128) {
	    ...

  input:	128 bit IPv6 string
  returns:	true if any bits are present

=item * $ipv6naddr = inet_4map6($netaddr or $ipv6naddr

This function returns an ipV6 network address with the first 80 bits
set to zero and the next 16 bits set to one, while the last 32 bits
are filled with the ipV4 address. 

  input:	ipV4 netaddr
	    or	ipV6 netaddr
  returns:	ipV6 netaddr

  returns: undef on error

An ipV6 network address must be in one of the two compatible ipV4
mapped address spaces. i.e.

	::ffff::d.d.d.d    or    ::d.d.d.d

=item * $rv = isIPv4($bits128);

This function returns true if there are no on bits present in the IPv6
portion of the 128 bit string and false otherwise.

  i.e.	the address must be of the form - ::d.d.d.d

Note: this is an old and deprecated ipV4 compatible ipV6 address
	
=item * $rv = isNewIPv4($bits128);

This function return true if the IPv6 128 bit string is of the form

	::ffff::d.d.d.d

=item * $rv = isAnyIPv4($bits128);

This function return true if the IPv6 bit string is of the form

	::d.d.d.d	or	::ffff::d.d.d.d

=item * $dotquad or $hex_text = inet_n2dx($ipv6naddr);

This function B<does the right thing> and returns the text for either a
dot-quad IPv4 or a hex notation IPv6 address.

  input:	128 bit IPv6 string
  returns:	ddd.ddd.ddd.ddd
	    or	x:x:x:x:x:x:x:x

=item * $dotquad or $dec_text = inet_n2ad($ipv6naddr);

This function B<does the right thing> and returns the text for either a
dot-quad IPv4 or a hex::decimal notation IPv6 address.

  input:	128 bit IPv6 string
  returns:	ddd.ddd.ddd.ddd
	    or  x:x:x:x:x:x:ddd.ddd.ddd.dd

=item * $netaddr = inet_pton($AF_family,$hex_text);

This function takes an IP address in IPv4 or IPv6 text format and converts it into
binary format. The type of IP address conversion is controlled by the FAMILY
argument.

=item * $hex_text = inet_ntop($AF_family,$netaddr);

This function takes and IP address in binary format and converts it into
text format. The type of IP address conversion is controlled by the FAMILY 
argument.

NOTE: inet_ntop ALWAYS returns lowercase characters.

=item * $hex_text = packzeros($hex_text);

This function optimizes and rfc 1884 IPv6 hex address to reduce the number of
long strings of zero bits as specified in rfc 1884, 2.2 (2) by substituting
B<::> for the first occurence of the longest string of zeros in the address.

=item * $ipv6naddr = ipv4to6($netaddr);

Convert an ipv4 network address into an IPv6 network address.

  input:	32 bit network address
  returns:	128 bit network address

=item * $ipv6naddr = mask4to6($netaddr);

Convert an ipv4 network address/mask into an ipv6 network mask.

  input:	32 bit network/mask address
  returns:	128 bit network/mask address

NOTE: returns the high 96 bits as one's

=item * $ipv6naddr = ipanyto6($netaddr);

Similar to ipv4to6 except that this function takes either an IPv4 or IPv6
input and always returns a 128 bit IPv6 network address.

  input:	32 or 128 bit network address
  returns:	128 bit network address

=item * $ipv6naddr = maskanyto6($netaddr);

Similar to mask4to6 except that this function takes either an IPv4 or IPv6
netmask and always returns a 128 bit IPv6 netmask.

  input:	32 or 128 bit network mask
  returns:	128 bit network mask

=item * $netaddr = ipv6to4($pv6naddr);

Truncate the upper 96 bits of a 128 bit address and return the lower
32 bits. Returns an IPv4 address as returned by inet_aton.

  input:	128 bit network address
  returns:	32 bit inet_aton network address

=item * $bitsXn = shiftleft($bits128,$n);

  input:	128 bit string variable,
		number of shifts [optional]
  returns:	bits X n shifts

  NOTE: a single shift is performed
	if $n is not specified

=item * addconst($ipv6naddr,$signed_32con);

Add a signed constant to a 128 bit string variable.

  input:	128 bit IPv6 string,
		signed 32 bit integer
  returns:  scalar	carry
	    array	(carry, result)

=item * add128($ipv6naddr1,$ipv6naddr2);

Add two 128 bit string variables.

  input:	128 bit string var1,
		128 bit string var2
  returns:  scalar	carry
	    array	(carry, result)

=item * sub128($ipv6naddr1,$ipv6naddr2);

Subtract two 128 bit string variables.

  input:	128 bit string var1,
		128 bit string var2
  returns:  scalar	carry
	    array	(carry, result)

Note: The carry from this operation is the result of adding the one's
complement of ARG2 +1 to the ARG1. It is logically
B<NOT borrow>.

	i.e. 	if ARG1 >= ARG2 then carry = 1
	or	if ARG1  < ARG2 then carry = 0


=item * ($spurious,$cidr) = notcontiguous($mask128);

This function counts the bit positions remaining in the mask when the
rightmost '0's are removed.

	input:	128 bit netmask
	returns true if there are spurious
		    zero bits remaining in the
		    mask, false if the mask is
		    contiguous one's,
		128 bit cidr number

=item * $bcdtext = bin2bcd($bits128);

Convert a 128 bit binary string into binary coded decimal text digits.

  input:	128 bit string variable
  returns:	string of bcd text digits

=item * $bits128 = bcd2bin($bcdtxt);

Convert a bcd text string to 128 bit string variable

  input:	string of bcd text digits
  returns:	128 bit string variable

=cut

#=item * $onescomp=NetAddr::IP::Util::comp128($ipv6addr);
#
#This function is not exported because it is more efficient to use perl " ~ "
#on the bit string directly. This interface to the B<C> routine is published for
#module testing purposes because it is used internally in the B<sub128> routine. The
#function is very fast, but calling if from perl directly is very slow. It is almost
#33% faster to use B<sub128> than to do a 1's comp with perl and then call
#B<add128>.
#
#=item * $bcdpacked = NetAddr::IP::Util::bin2bcdn($bits128);
#
#Convert a 128 bit binary string into binary coded decimal digits.
#This function is not exported.
#
#  input:	128 bit string variable
#  returns:	string of packed decimal digits
#
#  i.e.	text = unpack("H*", $bcd);
#
#=item * $bcdtext =  NetAddr::IP::Util::bcdn2txt($bcdpacked);
#
#Convert a packed bcd string into text digits, suppress the leading zeros.
#This function is not exported.
#
#  input:	string of packed decimal digits
#  returns:	hexadecimal digits
#
#Similar to unpack("H*", $bcd);
#
#=item * $bcdpacked = NetAddr::IP::Util::simple_pack($bcdtext);
#
#Convert a numeric string into a packed bcd string, left fill with zeros
#
#  input:	string of decimal digits
#  returns:	string of packed decimal digits
#
#Similar to pack("H*", $bcdtext);

=item * $modetext = mode;

Returns the operating mode of this module.

	input:		none
	returns:	"Pure Perl"
		   or	"CC XS"

=item * ($name,$aliases,$addrtype,$length,@addrs)=naip_gethostbyname(NAME);

Replacement for Perl's gethostbyname if Socket6 is available

In ARRAY context, returns a list of five elements, the hostname or NAME,
a space separated list of C_NAMES, AF family, length of the address
structure, and an array of one or more netaddr's

In SCALAR context, returns the first netaddr.

This function ALWAYS returns an IPv6 address, even on IPv4 only systems.
IPv4 addresses are mapped into IPv6 space in the form:

	::FFFF:FFFF:d.d.d.d

This is NOT the expected result from Perl's gethostbyname2. It is instead equivalent to:

  On an IPv4 only system:
    $ipv6naddr = ipv4to6 scalar ( gethostbyname( name ));

  On a system with Socket6 and a working gethostbyname2:
    $ipv6naddr = gethostbyname2( name, AF_INET6 );
  and if that fails, the IPv4 conversion above.

For a gethostbyname2 emulator that behave like Socket6, see:
L<Net::DNS::Dig>

=item * $trueif = havegethostbyname2();

This function returns TRUE if Socket6 has a functioning B<gethostbyname2>,
otherwise it returns FALSE. See the comments above about the behavior of
B<naip_gethostbyname>.

=item * NetAddr::IP::Util::lower();

Return IPv6 strings in lowercase.

=item * NetAddr::IP::Util::upper();

Return IPv6 strings in uppercase.  This is the default.

=back

=head1 EXAMPLES


  # convert any textual IP address into a 128 bit vector
  #
  sub text2vec {
    my($anyIP,$anyMask) = @_;

  # not IPv4 bit mask
    my $notiv4 = ipv6_aton('FFFF:FFFF:FFFF:FFFF:FFFF:FFFF::');

    my $vecip	= inet_any2n($anyIP);
    my $mask	= inet_any2n($anyMask);

  # extend mask bits for IPv4
    my $bits = 128;	# default
    unless (hasbits($mask & $notiv4)) {
      $mask |= $notiv4;
      $bits = 32;
    }
    return ($vecip, $mask, $bits);
  }

  ... alternate implementation, a little faster

  sub text2vec {
    my($anyIP,$anyMask) = @_;

  # not IPv4 bit mask
    my $notiv4 = ipv6_aton('FFFF:FFFF:FFFF:FFFF:FFFF:FFFF::');

    my $vecip	= inet_any2n($anyIP);
    my $mask	= inet_any2n($anyMask);

  # extend mask bits for IPv4
    my $bits = 128;	# default
    if (isIPv4($mask)) {
      $mask |= $notiv4;
      $bits = 32;
    }
    return ($vecip, $mask, $bits);
  }


  ... elsewhere
    $nip = {
	addr	=> $vecip,
	mask	=> $mask,
	bits	=> $bits,
    };

  # return network and broadcast addresses from IP and Mask
  #
  sub netbroad {
    my($nip) = shift;
    my $notmask	= ~ $nip->{mask};
    my $bcast	= $nip->{addr} | $notmask;
    my $network	= $nip->{addr} & $nip->{mask};
    return ($network, $broadcast);
  }

  # check if address is within a network
  #
  sub within {
    my($nip,$net) = @_;
    my $addr = $nip->{addr}
    my($nw,$bc) = netbroad($net);
  # arg1 >= arg2, sub128 returns true
    return (sub128($addr,$nw) && sub128($bc,$addr))
	? 1 : 0;
  }

  # truely hard way to do $ip++
  # add a constant, wrapping at netblock boundaries
  # to subtract the constant, negate it before calling
  # 'addwrap' since 'addconst' will extend the sign bits
  #
  sub addwrap {
    my($nip,$const) = @_;
    my $addr	= $nip->{addr};
    my $mask	= $nip->{mask};
    my $bits	= $nip->{bits};
    my $notmask	= ~ $mask;
    my $hibits	= $addr & $mask;
    $addr = addconst($addr,$const);
    my $wraponly = $addr & $notmask;
    my $newip = {
	addr	=> $hibits | $wraponly,
	mask	=> $mask,
	bits	=> $bits,
    };
    # bless $newip as appropriate
    return $newip;
  }

  # something more useful
  # increment a /24 net to the NEXT net at the boundry

  my $nextnet = 256;	# for /24
  LOOP:
  while (...continuing) {
    your code....
    ...
    my $lastip = $ip-copy();
    $ip++;
    if ($ip < $lastip) {	# host part wrapped?
  # discard carry
      (undef, $ip->{addr} = addconst($ip->{addr}, $nextnet);
    }
    next LOOP;
  }


=head1 EXPORT_OK

	inet_aton
	inet_ntoa
	ipv6_aton
	ipv6_ntoa
	ipv6_n2x
	ipv6_n2d
	inet_any2n
	hasbits
	isIPv4
	isNewIPv4
	isAnyIPv4
	inet_n2dx
	inet_n2ad
	inet_pton
	inet_ntop
	inet_4map6
	ipv4to6
	mask4to6
	ipanyto6
	maskanyto6
	ipv6to4
	packzeros
	shiftleft
	addconst
	add128
	sub128
	notcontiguous
	bin2bcd
	bcd2bin
	mode
	naip_gethostbyname
	havegethostbyname2

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

=head1 COPYRIGHT

Copyright 2003 - 2014, Michael Robinton E<lt>michael@bizsystems.comE<gt>

All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either:

  a) the GNU General Public License as published by the Free
  Software Foundation; either version 2, or (at your option) any
  later version, or

  b) the "Artistic License" which comes with this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License with this
distribution, in the file named "Artistic".  If not, I'll be glad to provide
one.

You should also have received a copy of the GNU General Public License
along with this program in the file named "Copying". If not, write to the

	Free Software Foundation, Inc.
	51 Franklin Street, Fifth Floor
	Boston, MA 02110-1301 USA.

or visit their web page on the internet at:

        http://www.gnu.org/copyleft/gpl.html.

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

=head1 SEE ALSO

NetAddr::IP(3), NetAddr::IP::Lite(3), NetAddr::IP::InetBase(3)

=cut

1;
