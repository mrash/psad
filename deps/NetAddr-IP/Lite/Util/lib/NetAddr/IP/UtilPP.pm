#!/usr/bin/perl
package NetAddr::IP::UtilPP;

use strict;
#use diagnostics;
#use lib qw(blib lib);

use AutoLoader qw(AUTOLOAD);
use vars qw($VERSION @EXPORT_OK @ISA %EXPORT_TAGS);
require Exporter;


@ISA = qw(Exporter);

$VERSION = do { my @r = (q$Revision: 1.9 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

@EXPORT_OK = qw(
	hasbits
	shiftleft
	addconst
	add128
	sub128
	notcontiguous
	ipv4to6
	mask4to6
	ipanyto6
	maskanyto6
	ipv6to4
	bin2bcd
	bcd2bin
	comp128
	bin2bcdn
	bcdn2txt
	bcdn2bin
	simple_pack
);

%EXPORT_TAGS = (
	all	=> [@EXPORT_OK],
);

sub DESTROY {};

1;
__END__

=head1 NAME

NetAddr::IP::UtilPP -- pure Perl functions for NetAddr::IP::Util

=head1 SYNOPSIS

  use NetAddr::IP::UtilPP qw(
	hasbits
	shiftleft
	addconst
	add128
	sub128
	notcontiguous
	ipv4to6
	mask4to6
	ipanyto6
	maskanyto6
	ipv6to4
	bin2bcd
	bcd2bin
  );

  use NetAddr::IP::UtilPP qw(:all)

  $rv = hasbits($bits128);
  $bitsX2 = shiftleft($bits128,$n);
  $carry = addconst($ipv6naddr,$signed_32con);
  ($carry,$ipv6naddr)=addconst($ipv6naddr,$signed_32con);
  $carry = add128($ipv6naddr1,$ipv6naddr2);
  ($carry,$ipv6naddr)=add128($ipv6naddr1,$ipv6naddr2);
  $carry = sub128($ipv6naddr1,$ipv6naddr2);
  ($spurious,$cidr) = notcontiguous($mask128);
  ($carry,$ipv6naddr)=sub128($ipv6naddr1,$ipv6naddr2);
  $ipv6naddr = ipv4to6($netaddr);
  $ipv6naddr = mask4to6($netaddr);
  $ipv6naddr = ipanyto6($netaddr);
  $ipv6naddr = maskanyto6($netaddr);
  $netaddr = ipv6to4($pv6naddr);
  $bcdtext = bin2bcd($bits128);
  $bits128 = bcd2bin($bcdtxt);

=head1 DESCRIPTION

B<NetAddr::IP::UtilPP> provides pure Perl functions for B<NetAddr::IP::Util>

=over 4

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

=cut

sub _deadlen {
  my($len,$should) = @_;
  $len *= 8;
  $should = 128 unless $should;
  my $sub = (caller(1))[3];
  die "Bad argument length for $sub, is $len, should be $should";
}

sub hasbits {
  _deadlen(length($_[0]))
	if length($_[0]) != 16;
  return 1 if vec($_[0],0,32);
  return 1 if vec($_[0],1,32);
  return 1 if vec($_[0],2,32);
  return 1 if vec($_[0],3,32);
  return 0;
}

#=item * $rv = isIPv4($bits128);
#
#This function returns true if there are no on bits present in the IPv6
#portion of the 128 bit string and false otherwise.
#
#=cut
#
#sub xisIPv4 {
#  _deadlen(length($_[0]))
#	if length($_[0]) != 16;
#  return 0 if vec($_[0],0,32);
#  return 0 if vec($_[0],1,32);
#  return 0 if vec($_[0],2,32);
#  return 1;
#}

=item * $bitsXn = shiftleft($bits128,$n);

  input:	128 bit string variable,
		number of shifts [optional]
  returns:	bits X n shifts

  NOTE: input bits are returned
	if $n is not specified

=cut

# multiply x 2
#
sub _128x2 {
  my $inp = shift;
  $$inp[0] = ($$inp[0] << 1 & 0xffffffff) + (($$inp[1] & 0x80000000) ? 1:0);
  $$inp[1] = ($$inp[1] << 1 & 0xffffffff) + (($$inp[2] & 0x80000000) ? 1:0);
  $$inp[2] = ($$inp[2] << 1 & 0xffffffff) + (($$inp[3] & 0x80000000) ? 1:0);
  $$inp[3] = $$inp[3] << 1 & 0xffffffff;
}

# multiply x 10
#
sub _128x10 {
  my($a128p) = @_;
  _128x2($a128p);		# x2
  my @x2 = @$a128p;		# save the x2 value
  _128x2($a128p);
  _128x2($a128p);		# x8
  _sa128($a128p,\@x2,0);	# add for x10
}

sub shiftleft {
  _deadlen(length($_[0]))
	if length($_[0]) != 16;
  my($bits,$shifts) = @_;
  return $bits unless $shifts;
  die "Bad arg value for ".__PACKAGE__.":shiftleft, length should be 0 thru 128"
	if $shifts < 0 || $shifts > 128;
  my @uint32t = unpack('N4',$bits);
  do {
    $bits = _128x2(\@uint32t);
    $shifts--
  } while $shifts > 0;
   pack('N4',@uint32t);
}

sub slowadd128 {
  my @ua = unpack('N4',$_[0]);
  my @ub = unpack('N4',$_[1]);
  my $carry = _sa128(\@ua,\@ub,$_[2]);
  return ($carry,pack('N4',@ua))
        if wantarray;
  return $carry;
}

sub _sa128 {
  my($uap,$ubp,$carry) = @_;
  if (($$uap[3] += $$ubp[3] + $carry) > 0xffffffff) {
    $$uap[3] -= 4294967296;	# 0x1_00000000
    $carry = 1;
  } else {
    $carry = 0;
  }

  if (($$uap[2] += $$ubp[2] + $carry) > 0xffffffff) {
    $$uap[2] -= 4294967296;
    $carry = 1;
  } else {
    $carry = 0;
  }

  if (($$uap[1] += $$ubp[1] + $carry) > 0xffffffff) {
    $$uap[1] -= 4294967296;
    $carry = 1;
  } else {
    $carry = 0;
  }

  if (($$uap[0] += $$ubp[0] + $carry) > 0xffffffff) {
    $$uap[0] -= 4294967296;
    $carry = 1;
  } else {
    $carry = 0;
  }
  $carry;
}

=item * addconst($ipv6naddr,$signed_32con);

Add a signed constant to a 128 bit string variable.

  input:	128 bit IPv6 string,
		signed 32 bit integer
  returns:  scalar	carry
	    array	(carry, result)

=cut

sub addconst {
  my($a128,$const) = @_;
  _deadlen(length($a128))
	if length($a128) != 16;
  unless ($const) {
    return (wantarray) ? ($const,$a128) : $const;
  }
  my $sign = ($const < 0) ? 0xffffffff : 0;
  my $b128 = pack('N4',$sign,$sign,$sign,$const);
  @_ = ($a128,$b128,0);
# perl 5.8.4 fails with this operation. see perl bug [ 23429]
#  goto &slowadd128;
  slowadd128(@_);
}

=item * add128($ipv6naddr1,$ipv6naddr2);

Add two 128 bit string variables.

  input:	128 bit string var1,
		128 bit string var2
  returns:  scalar	carry
	    array	(carry, result)

=cut

sub add128 {
  my($a128,$b128) = @_;
  _deadlen(length($a128))
	if length($a128) != 16;
  _deadlen(length($b128))
	if length($b128) != 16;
  @_ = ($a128,$b128,0);
# perl 5.8.4 fails with this operation. see perl bug [ 23429]
#  goto &slowadd128;
  slowadd128(@_);
}

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

=cut

sub sub128 {
  _deadlen(length($_[0]))
	if length($_[0]) != 16;
  _deadlen(length($_[1]))
	if length($_[1]) != 16;
  my $a128 = $_[0];
  my $b128 = ~$_[1];
  @_ = ($a128,$b128,1);
# perl 5.8.4 fails with this operation. see perl bug [ 23429]
#  goto &slowadd128;
  slowadd128(@_);
}

=item * ($spurious,$cidr) = notcontiguous($mask128);

This function counts the bit positions remaining in the mask when the
rightmost '0's are removed.

	input:  128 bit netmask
	returns true if there are spurious
		    zero bits remaining in the
		    mask, false if the mask is
		    contiguous one's,
		128 bit cidr

=cut

sub notcontiguous {
  _deadlen(length($_[0]))
	if length($_[0]) != 16;
  my @ua = unpack('N4', ~$_[0]);
  my $count;
  for ($count = 128;$count > 0; $count--) {
	last unless $ua[3] & 1;
	$ua[3] >>= 1;
	$ua[3] |= 0x80000000 if $ua[2] & 1;
	$ua[2] >>= 1;
	$ua[2] |= 0x80000000 if $ua[1] & 1;
	$ua[1] >>= 1;
	$ua[1] |= 0x80000000 if $ua[0] & 1;
	$ua[0] >>= 1;
  }

  my $spurious = $ua[0] | $ua[1] | $ua[2] | $ua[3];
  return $spurious unless wantarray;
  return ($spurious,$count);
}

=item * $ipv6naddr = ipv4to6($netaddr);

Convert an ipv4 network address into an ipv6 network address.

  input:	32 bit network address
  returns:	128 bit network address

=cut

sub ipv4to6 {
  _deadlen(length($_[0]),32)
        if length($_[0]) != 4;
#  return pack('L3H8',0,0,0,unpack('H8',$_[0]));
  return pack('L3a4',0,0,0,$_[0]);
}

=item * $ipv6naddr = mask4to6($netaddr);

Convert an ipv4 netowrk address into an ipv6 network mask.

  input:	32 bit network/mask address
  returns:	128 bit network/mask address

NOTE: returns the high 96 bits as one's

=cut

sub mask4to6 {
  _deadlen(length($_[0]),32)
        if length($_[0]) != 4;
#  return pack('L3H8',0xffffffff,0xffffffff,0xffffffff,unpack('H8',$_[0]));
  return pack('L3a4',0xffffffff,0xffffffff,0xffffffff,$_[0]);
}

=item * $ipv6naddr = ipanyto6($netaddr);

Similar to ipv4to6 except that this function takes either an IPv4 or IPv6
input and always returns a 128 bit IPv6 network address.

  input:	32 or 128 bit network address
  returns:	128 bit network address

=cut

sub ipanyto6 {
  my $naddr = shift;
  my $len = length($naddr);
  return $naddr if $len == 16;
#  return pack('L3H8',0,0,0,unpack('H8',$naddr))
  return pack('L3a4',0,0,0,$naddr)
	if $len == 4;
  _deadlen($len,'32 or 128');
}

=item * $ipv6naddr = maskanyto6($netaddr);

Similar to mask4to6 except that this function takes either an IPv4 or IPv6
netmask and always returns a 128 bit IPv6 netmask.

  input:	32 or 128 bit network mask
  returns:	128 bit network mask

=cut

sub maskanyto6 {
  my $naddr = shift;
  my $len = length($naddr);
  return $naddr if $len == 16;
#  return pack('L3H8',0xffffffff,0xffffffff,0xffffffff,unpack('H8',$naddr))
  return pack('L3a4',0xffffffff,0xffffffff,0xffffffff,$naddr)
	if $len == 4;
  _deadlen($len,'32 or 128');
}

=item * $netaddr = ipv6to4($pv6naddr);

Truncate the upper 96 bits of a 128 bit address and return the lower
32 bits. Returns an IPv4 address as returned by inet_aton.

  input:	128 bit network address
  returns:	32 bit inet_aton network address

=cut

sub ipv6to4 {
  my $naddr = shift;
_deadlen(length($naddr))
	if length($naddr) != 16;
  @_ = unpack('L3H8',$naddr);
  return pack('H8',@{_}[3..10]);
}

=item * $bcdtext = bin2bcd($bits128);

Convert a 128 bit binary string into binary coded decimal text digits.

  input:	128 bit string variable
  returns:	string of bcd text digits

=cut

sub bin2bcd {
  _deadlen(length($_[0]))
	if length($_[0]) != 16;
  unpack("H40",&_bin2bcdn) =~ /^0*(.+)/;
  $1;
}

=item * $bits128 = bcd2bin($bcdtxt);

Convert a bcd text string to 128 bit string variable

  input:	string of bcd text digits
  returns:	128 bit string variable

=cut

sub bcd2bin {
  &_bcdcheck;
# perl 5.8.4 fails with this operation. see perl bug [ 23429]
#  goto &_bcd2bin;
  &_bcd2bin;
}

=pod

=back

=cut

#=item * $onescomp = comp128($ipv6addr);
#
#This function is for testing, it is more efficient to use perl " ~ "
#on the bit string directly. This interface to the B<C> routine is published for
#module testing purposes because it is used internally in the B<sub128> routine. The
#function is very fast, but calling if from perl directly is very slow. It is almost
#33% faster to use B<sub128> than to do a 1's comp with perl and then call
#B<add128>. In the PurePerl version, it is a call to
#
#  sub {return ~ $_[0]};
#
#=cut

sub comp128 {
  _deadlen(length($_[0]))
	if length($_[0]) != 16;
  return ~ $_[0];
}

#=item * $bcdpacked = bin2bcdn($bits128);
#
#Convert a 128 bit binary string into binary coded decimal digits.
#This function is for testing only.
#
#  input:	128 bit string variable
#  returns:	string of packed decimal digits
#
#  i.e.	text = unpack("H*", $bcd);
#
#=cut

sub bin2bcdn {
  _deadlen(length($_[0]))
	if length($_[0]) != 16;
# perl 5.8.4 fails with this operation. see perl bug [ 23429]
#  goto &_bin2bcdn;
  &_bin2bcdn;
}

sub _bin2bcdn {
  my($b128) = @_;
  my @binary = unpack('N4',$b128);
  my @nbcd = (0,0,0,0,0);	# 5 - 32 bit registers
  my ($add3, $msk8, $bcd8, $carry, $tmp);
  my $j = 0;
  my $k = -1;
  my $binmsk = 0;
  foreach(0..127) {
    unless ($binmsk) {
      $binmsk = 0x80000000;
      $k++;
    }
    $carry = $binary[$k] & $binmsk;
    $binmsk >>= 1;
    next unless $carry || $j;				# skip leading zeros
    foreach(4,3,2,1,0) {
      $bcd8 = $nbcd[$_];
      $add3 = 3;
      $msk8 = 8;

      $j = 0;
      while ($j < 8) {
	$tmp = $bcd8 + $add3;
	if ($tmp & $msk8) {
	  $bcd8 = $tmp;
	}
	$add3 <<= 4;
	$msk8 <<= 4;
	$j++;
      }
      $tmp = $bcd8 & 0x80000000;	# propagate carry
      $bcd8 <<= 1;			# x2
      if ($carry) {
	$bcd8 += 1;
      }
      $nbcd[$_] = $bcd8;
      $carry = $tmp;
    }
  }
  pack('N5',@nbcd);
}

#=item * $bcdtext = bcdn2txt($bcdpacked);
#
#Convert a packed bcd string into text digits, suppress the leading zeros.
#This function is for testing only.
#
#  input:	string of packed decimal digits
#		consisting of exactly 40 digits
#  returns:	hexdecimal digits
#
#Similar to unpack("H*", $bcd);
#
#=cut

sub bcdn2txt {
  die "Bad argument length for ".__PACKAGE__.":bcdn2txt, is ".(2 * length($_[0])).", should be exactly 40 digits"
	if length($_[0]) != 20;
  (unpack('H40',$_[0])) =~ /^0*(.+)/;
  $1;
}

#=item * $bits128 = bcdn2bin($bcdpacked,$ndigits);
#
# Convert a packed bcd string into a 128 bit string variable
#
# input:	packed bcd string
#		number of digits in string
# returns:	128 bit string variable
#

sub bcdn2bin {
  my($bcd,$dc) = @_;
  $dc = 0 unless $dc;
  die "Bad argument length for ".__PACKAGE__.":bcdn2txt, is ".(2 * length($bcd)).", should be 1 to 40 digits"
	if length($bcd) > 20;
  die "Bad digit count for ".__PACKAGE__.":bcdn2bin, is $dc, should be 1 to 40 digits"
	if $dc < 1 || $dc > 40;
  return _bcd2bin(unpack("H$dc",$bcd));
}

sub _bcd2bin {
  my @bcd = split('',$_[0]);
  my @hbits = (0,0,0,0);
  my @digit = (0,0,0,0);
  my $found = 0;
  foreach(@bcd) {
    my $bcd = $_ & 0xf;		# just the nibble
    unless ($found) {
      next unless $bcd;		# skip leading zeros
      $found = 1;
      $hbits[3] = $bcd;		# set the first digit, no x10 necessary
      next;
    }
    _128x10(\@hbits);
    $digit[3] = $bcd;
    _sa128(\@hbits,\@digit,0);
  }
  return pack('N4',@hbits);
}

#=item * $bcdpacked = simple_pack($bcdtext);
#
#Convert a numeric string into a packed bcd string, left fill with zeros
#This function is for testing only.
#
#  input:	string of decimal digits
#  returns:	string of packed decimal digits
#
#Similar to pack("H*", $bcdtext);
#
sub _bcdcheck {
  my($bcd) = @_;;
  my $sub = (caller(1))[3];
  my $len = length($bcd);
  die "Bad bcd number length $_ ".__PACKAGE__.":simple_pack, should be 1 to 40 digits"
	if $len > 40 || $len < 1;
  die "Bad character in decimal input string '$1' for ".__PACKAGE__.":simple_pack"
	if $bcd =~ /(\D)/;
}

sub simple_pack {
  &_bcdcheck;
  my($bcd) = @_;
  while (length($bcd) < 40) {
    $bcd = '0'. $bcd;
  }
  return pack('H40',$bcd);
}


=head1 EXPORT_OK

	hasbits
	shiftleft
	addconst
	add128
	sub128
	notcontiguous
	ipv4to6
	mask4to6
	ipanyto6
	maskanyto6
	ipv6to4
	bin2bcd
	bcd2bin
	comp128
	bin2bcdn
	bcdn2txt
	bcdn2bin
	simple_pack
	threads

=head1 AUTHOR

Michael Robinton E<lt>michael@bizsystems.comE<gt>

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

=cut

1;
