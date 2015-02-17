#!/usr/bin/perl
package NetAddr::IP::InetBase;

use strict;
#use diagnostics;
#use lib qw(blib lib);

use vars qw($VERSION @EXPORT_OK @ISA %EXPORT_TAGS $Mode);
use AutoLoader qw(AUTOLOAD);
require Exporter;

@ISA = qw(Exporter);

$VERSION = do { my @r = (q$Revision: 0.08 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

@EXPORT_OK = qw(
	inet_aton
	inet_ntoa
	ipv6_aton
	ipv6_ntoa
	ipv6_n2x
	ipv6_n2d
	inet_any2n
	inet_n2dx
	inet_n2ad
	inet_ntop
	inet_pton
	packzeros
	isIPv4
	isNewIPv4
	isAnyIPv4
	AF_INET
	AF_INET6
	fake_AF_INET6
	fillIPv4
);

%EXPORT_TAGS = (
	all     => [@EXPORT_OK],
	ipv4	=> [qw(
		inet_aton
		inet_ntoa
		fillIPv4
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
		packzeros
	)],
);

# prototypes
sub inet_ntoa;
sub ipv6_aton;
sub ipv6_ntoa;
sub inet_any2n($);
sub inet_n2dx($);
sub inet_n2ad($);
sub _inet_ntop;
sub _inet_pton;

my $emulateAF_INET6 = 0;

{ no warnings 'once';

*packzeros = \&_packzeros;

## dynamic configuraton for IPv6

require Socket;

*AF_INET = \&Socket::AF_INET;

if (eval { AF_INET6() } ) {
  *AF_INET6 = \&Socket::AF_INET6;
  $emulateAF_INET6 = -1;			# have it, remind below
}
if (eval{ require Socket6 } ) {
  import Socket6 qw(
	inet_pton
	inet_ntop
  );
  unless ($emulateAF_INET6) {
    *AF_INET6 = \&Socket6::AF_INET6;
  }
  $emulateAF_INET6 = 0;				# clear, have it from elsewhere or here
} else {
  unless ($emulateAF_INET6) {	# unlikely at this point
    if ($^O =~ /(?:free|dragon.+)bsd/i) {	# FreeBSD, DragonFlyBSD
	$emulateAF_INET6 = 28;
    } elsif ($^O =~ /bsd/i) {		# other BSD flavors like NetBDS, OpenBSD, BSD
	$emulateAF_INET6 = 24;
    } elsif ($^O =~ /(?:darwin|mac)/i) {	# Mac OS X
	$emulateAF_INET6 = 30;
    } elsif ($^O =~ /win/i) {		# Windows
	$emulateAF_INET6 = 23;
    } elsif ($^O =~ /(?:solaris|sun)/i) {		# Sun box
	$emulateAF_INET6 = 26;
    } else {					# use linux default
	$emulateAF_INET6 = 10;
    }
    *AF_INET6 = sub { $emulateAF_INET6; };
  } else {
    $emulateAF_INET6 = 0;			# clear, have it from elsewhere
  }
  *inet_pton = \&_inet_pton;
  *inet_ntop = \&_inet_ntop;
}

} # end no warnings 'once'

sub fake_AF_INET6 {
  return $emulateAF_INET6;
}

# allow user to choose upper or lower case
BEGIN {
  use vars qw($n2x_format $n2d_format);
  $n2x_format = "%x:%x:%x:%x:%x:%x:%x:%x";
  $n2d_format = "%x:%x:%x:%x:%x:%x:%d.%d.%d.%d";
}

my $case = 0;	# default lower case

sub upper { $n2x_format = uc($n2x_format); $n2d_format = uc($n2d_format); $case = 1; }
sub lower { $n2x_format = lc($n2x_format); $n2d_format = lc($n2d_format); $case = 0; }

sub ipv6_n2x {
  die "Bad arg length for 'ipv6_n2x', length is ". length($_[0]) ." should be 16"
	unless length($_[0]) == 16;
  return sprintf($n2x_format,unpack("n8",$_[0]));
}

sub ipv6_n2d {
  die "Bad arg length for 'ipv6_n2d', length is ". length($_[0]) ." should be 16"
	unless length($_[0]) == 16;
  my @hex = (unpack("n8",$_[0]));
  $hex[9] = $hex[7] & 0xff;
  $hex[8] = $hex[7] >> 8;
  $hex[7] = $hex[6] & 0xff;
  $hex[6] >>= 8;
  return sprintf($n2d_format,@hex);
}

# if Socket lib is broken in some way, check for overange values
#
#my $overange = yinet_aton('256.1') ? 1:0;
#my $overange = gethostbyname('256.1') ? 1:0;

#sub inet_aton {
#  unless (! $overange || $_[0] =~ /[^0-9\.]/) {	# hostname
#    my @dq = split(/\./,$_[0]);
#    foreach (@dq) {
#      return undef if $_ > 255;
#    }
#  }
#  scalar gethostbyname($_[0]);
#}

sub fillIPv4 {
  my $host = $_[0];
  return undef unless defined $host;
  if ($host =~ /^(\d+)(?:|\.(\d+)(?:|\.(\d+)(?:|\.(\d+))))$/) {
    if (defined $4) {
      return undef unless
        $1 >= 0 && $1 < 256 &&
        $2 >= 0 && $2 < 256 &&
        $3 >= 0 && $3 < 256 &&
        $4 >= 0 && $4 < 256;
      $host = $1.'.'.$2.'.'.$3.'.'.$4;
#      return pack('C4',$1,$2,$3,$4);
#      $host = ($1 << 24) + ($2 << 16) + ($3 << 8) + $4;
    } elsif (defined $3) {
      return undef unless  
        $1 >= 0 && $1 < 256 &&
        $2 >= 0 && $2 < 256 &&
        $3 >= 0 && $3 < 256;  
      $host = $1.'.'.$2.'.0.'.$3
#      return pack('C4',$1,$2,0,$3);
#      $host = ($1 << 24) + ($2 << 16) + $3;
    } elsif (defined $2) {
      return undef unless  
        $1 >= 0 && $1 < 256 &&
        $2 >= 0 && $2 < 256;  
      $host = $1.'.0.0.'.$2;
#      return pack('C4',$1,0,0,$2);
#      $host = ($1 << 24) + $2;
    } else {
      $host = '0.0.0.'.$1;
#      return pack('C4',0,0,0,$1);
#      $host = $1;
    }
#    return pack('N',$host);
  }
  $host;
} 	

sub inet_aton {
  my $host = fillIPv4($_[0]);
  return $host ? scalar gethostbyname($host) : undef;
}

#sub inet_aton {
#  my $host = $_[0];
#  return undef unless defined $host;
#  if ($host =~ /^(\d+)(?:|\.(\d+)(?:|\.(\d+)(?:|\.(\d+))))$/) {
#    if (defined $4) {
#      return undef unless
#        $1 >= 0 && $1 < 256 &&
#        $2 >= 0 && $2 < 256 &&
#        $3 >= 0 && $3 < 256 &&
#        $4 >= 0 && $4 < 256;
#      return pack('C4',$1,$2,$3,$4);
##      $host = ($1 << 24) + ($2 << 16) + ($3 << 8) + $4;
#    } elsif (defined $3) {
#      return undef unless  
#        $1 >= 0 && $1 < 256 &&
#        $2 >= 0 && $2 < 256 &&
#        $3 >= 0 && $3 < 256;  
#      return pack('C4',$1,$2,0,$3);
##      $host = ($1 << 24) + ($2 << 16) + $3;
#    } elsif (defined $2) {
#      return undef unless  
#        $1 >= 0 && $1 < 256 &&
#        $2 >= 0 && $2 < 256;  
#      return pack('C4',$1,0,0,$2);
##      $host = ($1 << 24) + $2;
#    } else {
#      return pack('C4',0,0,0,$1);
##      $host = $1;
#    }
##    return pack('N',$host);
#  }
#  scalar gethostbyname($host);
#} 	

my $_zero = pack('L4',0,0,0,0);
my $_ipv4mask = pack('L4',0xffffffff,0xffffffff,0xffffffff,0);

sub isIPv4 {
  if (length($_[0]) != 16) {
    my $sub = (caller(1))[3] || (caller(0))[3];
    die "Bad arg length for $sub, length is ". (length($_[0]) *8) .", should be 128";
  }
  return ($_[0] & $_ipv4mask) eq $_zero
	? 1 : 0;
}

my $_newV4compat = pack('N4',0,0,0xffff,0);

sub isNewIPv4 {
  my $naddr = $_[0] ^ $_newV4compat;
  return isIPv4($naddr);
}

sub isAnyIPv4 {
  my $naddr = $_[0];
  my $rv = isIPv4($_[0]);
  return $rv if $rv;
  return isNewIPv4($naddr);
}

sub DESTROY {};

sub import {
  if (grep { $_ eq ':upper' } @_) {
	upper();
	@_ = grep { $_ ne ':upper' } @_;
  }
  NetAddr::IP::InetBase->export_to_level(1,@_);
}

1;

__END__

=head1 NAME

NetAddr::IP::InetBase -- IPv4 and IPV6 utilities

=head1 SYNOPSIS

  use NetAddr::IP::Base qw(
	:upper
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
	packzeros
	isIPv4
	isNewIPv4
	isAnyIPv4
	AF_INET
	AF_INET6
	fake_AF_INET6
	fillIPv4
  );

  use NetAddr::IP::Util qw(:all :inet :ipv4 :ipv6 :math)

  :ipv4	  =>	inet_aton, inet_ntoa, fillIPv4

  :ipv6	  =>	ipv6_aton, ipv6_ntoa,ipv6_n2x, ipv6_n2d,
		inet_any2n, inet_n2dx, inet_n2ad
		inet_pton, inet_ntop, packzeros

  $dotquad = inet_ntoa($netaddr);
  $netaddr = inet_aton($dotquad);
  $ipv6naddr = ipv6_aton($ipv6_text);
  $ipv6_text = ipv6_ntoa($ipv6naddr);
  $hex_text = ipv6_n2x($ipv6naddr);
  $dec_text = ipv6_n2d($ipv6naddr);
  $ipv6naddr = inet_any2n($dotquad or $ipv6_text);
  $dotquad or $hex_text = inet_n2dx($ipv6naddr);
  $dotquad or $dec_text = inet_n2ad($ipv6naddr);
  $netaddr = inet_pton($AF_family,$text_addr);
  $text_addr = inet_ntop($AF_family,$netaddr);
  $hex_text = packzeros($hex_text);
  $rv = isIPv4($bits128);
  $rv = isNewIPv4($bits128);
  $rv = isAnyIPv4($bits128);
  $constant = AF_INET();
  $constant = AF_INET6();
  $trueif   = fake_AF_INET6();
  $ip_filled = fillIPv4($shortIP);

  NetAddr::IP::InetBase::lower();
  NetAddr::IP::InetBase::upper();

=head1 INSTALLATION

Un-tar the distribution in an appropriate directory and type:

	perl Makefile.PL
	make
	make test
	make install

=head1 DESCRIPTION

B<NetAddr::IP::InetBase> provides a suite network of conversion functions 
written in pure Perl for converting both IPv4 and IPv6 addresses to
and from network address format and text format.

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

=cut

sub inet_ntoa {
  die 'Bad arg length for '. __PACKAGE__ ."::inet_ntoa, length is ". length($_[0]) ." should be 4"
        unless length($_[0]) == 4;
  my @hex = (unpack("n2",$_[0]));
  $hex[3] = $hex[1] & 0xff;
  $hex[2] = $hex[1] >> 8;
  $hex[1] = $hex[0] & 0xff;
  $hex[0] >>= 8;
  return sprintf("%d.%d.%d.%d",@hex);
}

=item * $netaddr = inet_aton($dotquad);

Convert a dot-quad IP address into an IPv4 packed network address.

  input:	IP address i.e. 192.5.16.32
  returns:	packed network address

=item * $ipv6addr = ipv6_aton($ipv6_text);

Takes an IPv6 address of the form described in rfc1884
and returns a 128 bit binary RDATA string.

  input:	ipv6 text
  returns:	128 bit RDATA string

=cut

sub ipv6_aton {
  my($ipv6) = @_;
  return undef unless $ipv6;
  local($1,$2,$3,$4,$5);
  if ($ipv6 =~ /^(.*:)(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/) {	# mixed hex, dot-quad
    return undef if $2 > 255 || $3 > 255 || $4 > 255 || $5 > 255;
    $ipv6 = sprintf("%s%X%02X:%X%02X",$1,$2,$3,$4,$5);			# convert to pure hex
  }
  my $c;
  return undef if
	$ipv6 =~ /[^:0-9a-fA-F]/ ||			# non-hex character
	(($c = $ipv6) =~ s/::/x/ && $c =~ /(?:x|:):/) ||	# double :: ::?
	$ipv6 =~ /[0-9a-fA-F]{5,}/;			# more than 4 digits
  $c = $ipv6 =~ tr/:/:/;				# count the colons
  return undef if $c < 7 && $ipv6 !~ /::/;
  if ($c > 7) {						# strip leading or trailing ::
    return undef unless
	$ipv6 =~ s/^::/:/ ||
	$ipv6 =~ s/::$/:/;
    return undef if --$c > 7;
  }
  while ($c++ < 7) {					# expand compressed fields
    $ipv6 =~ s/::/:::/;
  }
  $ipv6 .= 0 if $ipv6 =~ /:$/;
  my @hex = split(/:/,$ipv6);
  foreach(0..$#hex) {
    $hex[$_] = hex($hex[$_] || 0);
  }
  pack("n8",@hex);
}

=item * $ipv6text = ipv6_ntoa($ipv6naddr);

Convert a 128 bit binary IPv6 address to compressed rfc 1884
text representation.

  input:	128 bit RDATA string
  returns:	ipv6 text

=cut

sub ipv6_ntoa {
  return inet_ntop(AF_INET6(),$_[0]);
}

=item * $hex_text = ipv6_n2x($ipv6addr);

Takes an IPv6 RDATA string and returns an 8 segment IPv6 hex address

  input:	128 bit RDATA string
  returns:	x:x:x:x:x:x:x:x

  Note: this function does NOT compress adjacent
  strings of 0:0:0:0 into the :: format

=item * $dec_text = ipv6_n2d($ipv6addr);

Takes an IPv6 RDATA string and returns a mixed hex - decimal IPv6 address
with the 6 uppermost chunks in hex and the lower 32 bits in dot-quad
representation.

  input:	128 bit RDATA string
  returns:	x:x:x:x:x:x:d.d.d.d

  Note: this function does NOT compress adjacent
  strings of 0:0:0:0 into the :: format

=item * $ipv6naddr = inet_any2n($dotquad or $ipv6_text);

This function converts a text IPv4 or IPv6 address in text format in any
standard notation into a 128 bit IPv6 string address. It prefixes any
dot-quad address (if found) with '::' and passes it to B<ipv6_aton>.

  input:	dot-quad or rfc1844 address
  returns:	128 bit IPv6 string

=cut

sub inet_any2n($) {
  my($addr) = @_;
  $addr = '' unless $addr;
  $addr = '::' . $addr
	unless $addr =~ /:/;
  return ipv6_aton($addr);
}

=item * $dotquad or $hex_text = inet_n2dx($ipv6naddr);

This function B<does the right thing> and returns the text for either a
dot-quad IPv4 or a hex notation IPv6 address.

  input:	128 bit IPv6 string
  returns:	ddd.ddd.ddd.ddd
	    or	x:x:x:x:x:x:x:x

  Note: this function does NOT compress adjacent
  strings of 0:0:0:0 into the :: format

=cut

sub inet_n2dx($) {
  my($nadr) = @_;
  if (isAnyIPv4($nadr)) {
    local $1;
    ipv6_n2d($nadr) =~ /([^:]+)$/;
    return $1;
  }
  return ipv6_n2x($nadr);
}

=item * $dotquad or $dec_text = inet_n2ad($ipv6naddr);

This function B<does the right thing> and returns the text for either a
dot-quad IPv4 or a hex::decimal notation IPv6 address.

  input:	128 bit IPv6 string
  returns:	ddd.ddd.ddd.ddd
	    or  x:x:x:x:x:x:ddd.ddd.ddd.dd

  Note: this function does NOT compress adjacent
  strings of 0:0:0:0 into the :: format

=cut

sub inet_n2ad($) {
  my($nadr) = @_;
  my $addr = ipv6_n2d($nadr);
  return $addr unless isAnyIPv4($nadr);
  local $1;
  $addr =~ /([^:]+)$/;
  return $1;
}

=item * $netaddr = inet_pton($AF_family,$text_addr);

This function takes an IP address in IPv4 or IPv6 text format and converts it into
binary format. The type of IP address conversion is controlled by the FAMILY
argument.

NOTE: inet_pton, inet_ntop and AF_INET6 come from the Socket6 library if it
is present on this host.

=cut

sub _inet_pton {
  my($af,$ip) = @_;
  die 'Bad address family for '. __PACKAGE__ ."::inet_pton, got $af"
	unless $af == AF_INET6() || $af == AF_INET();
  if ($af == AF_INET()) {
    inet_aton($ip);
  } else {
    ipv6_aton($ip);
  }
}

=item * $text_addr = inet_ntop($AF_family,$netaddr);

This function takes and IP address in binary format and converts it into
text format. The type of IP address conversion is controlled by the FAMILY 
argument.

NOTE: inet_ntop ALWAYS returns lowercase characters.

NOTE: inet_pton, inet_ntop and AF_INET6 come from the Socket6 library if it
is present on this host.

=cut

sub _inet_ntop {
  my($af,$naddr) = @_;
  die 'Unsupported address family for '. __PACKAGE__ ."::inet_ntop, af is $af"
	unless $af == AF_INET6() || $af == AF_INET();
  if ($af == AF_INET()) {
    inet_ntoa($naddr);
  } else {
    return ($case)
	? lc packzeros(ipv6_n2x($naddr))
	: _packzeros(ipv6_n2x($naddr));
  }
}

=item * $hex_text = packzeros($hex_text);

This function optimizes and rfc 1884 IPv6 hex address to reduce the number of
long strings of zero bits as specified in rfc 1884, 2.2 (2) by substituting
B<::> for the first occurence of the longest string of zeros in the address.

=cut

sub _packzeros {
  my $x6 = shift;
  if ($x6 =~ /\:\:/) {				# already contains ::
# then re-optimize
    $x6 = ($x6 =~ /\:\d+\.\d+\.\d+\.\d+/)	# ipv4 notation ?
	? ipv6_n2d(ipv6_aton($x6))
	: ipv6_n2x(ipv6_aton($x6));
  }
  $x6 = ':'. lc $x6;				# prefix : & always lower case
  my $d = '';
  if ($x6 =~ /(.+\:)(\d+\.\d+\.\d+\.\d+)/) {	# if contains dot quad
    $x6 = $1;					# save hex piece
    $d = $2;					# and dot quad piece
  }
  $x6 .= ':';					# suffix :
  $x6 =~ s/\:0+/\:0/g;				# compress strings of 0's to single '0'
  $x6 =~ s/\:0([1-9a-f]+)/\:$1/g;		# eliminate leading 0's in hex strings
  my @x = $x6 =~ /(?:\:0)*/g;			# split only strings of :0:0..."

  my $m = 0;
  my $i = 0;

  for (0..$#x) {				# find next longest pattern :0:0:0...
    my $len = length($x[$_]);
    next unless $len > $m;
    $m = $len;
    $i = $_;					# index to first longest pattern
  }

  if ($m > 2) {					# there was a string of 2 or more zeros
    $x6 =~ s/$x[$i]/\:/;	  		# replace first longest :0:0:0... with "::"
    unless ($i) {				# if it is the first match, $i = 0
      $x6 = substr($x6,0,-1);			# keep the leading ::, remove trailing ':'
    } else {
      $x6 = substr($x6,1,-1);			# else remove leading & trailing ':'
    }
    $x6 .= ':' unless $x6 =~ /\:\:/;		# restore ':' if match and we can't see it, implies trailing '::'
  } else {					# there was no match
    $x6 = substr($x6,1,-1);			# remove leading & trailing ':'
  }
  $x6 .= $d;					# append digits if any
  return $case
	? uc $x6
	: $x6;
}

=item * $ipv6naddr = ipv4to6($netaddr);

Convert an ipv4 network address into an ipv6 network address.

  input:	32 bit network address
  returns:	128 bit network address

=item * $rv = isIPv4($bits128);

This function returns true if there are no on bits present in the IPv6
portion of the 128 bit string and false otherwise.

  i.e.	the address must be of the form - ::d.d.d.d

Note: this is an old and deprecated ipV4 compatible ipV6 address
	
=item * $rv = isNewIPv4($bits128);

This function return true if the IPv6 128 bit string is of the form

	::ffff:d.d.d.d

=item * $rv = isAnyIPv4($bits128);

This function return true if the IPv6 bit string is of the form

	::d.d.d.d	or	::ffff:d.d.d.d

=item * NetAddr::IP::InetBase::lower();

Return IPv6 strings in lowercase. This is the default.

=item * NetAddr::IP::InetBase::upper();

Return IPv6 strings in uppercase.

The default may be set to uppercase when the module is loaded by invoking
the TAG :upper. i.e.

	use NetAddr::IP::InetBase qw( :upper );

=item * $constant = AF_INET;

This function returns the system value for AF_INET. 

=item * $constant = AF_INET6;

AF_INET6 is sometimes present in the Socket library and always present in the Socket6 library. When the Socket 
library does not contain AF_INET6 and when Socket6 is not present, a place holder value is C<guessed> based on
the underlying host operating system. See B<fake_AF_INET6> below.

NOTE: inet_pton, inet_ntop and AF_INET6 come from the Socket6 library if it
is present on this host.

=item * $trueif = fake_AF_INET6;

This function return FALSE if AF_INET6 is provided by Socket or Socket6. Otherwise, it returns the best guess
value based on name of the host operating system.

=item * $ip_filled = fillIPv4($shortIP);

This function converts IPv4 addresses of the form 127.1 to the long form
127.0.0.1 

If the function is passed an argument that does not match the form of an IP
address, the original argument is returned. i.e. pass it a hostname or a
short IP and it will return a hostname or a filled IP.

=back

=head1 EXPORT_OK

	:upper
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
	packzeros
	isIPv4
	isNewIPv4
	isAnyIPv4
	AF_INET
	AF_INET6
	fake_AF_INET6
	fillIPv4

=head1 %EXPORT_TAGS

	:all
	:ipv4
	:ipv6
	:upper

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

=head1 COPYRIGHT

Copyright 2003 - 2012, Michael Robinton E<lt>michael@bizsystems.comE<gt>

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

	Free Software Foundation, Inc.,
	51 Franklin Street, Fifth Floor
	Boston, MA 02110-1301 USA

or visit their web page on the internet at:

        http://www.gnu.org/copyleft/gpl.html.

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

=head1 SEE ALSO

NetAddr::IP(3), NetAddr::IP::Lite(3), NetAddr::IP::Util(3)

=cut

1;
