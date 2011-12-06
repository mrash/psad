#!/usr/bin/perl
#
# DO NOT ALTER THIS FILE
# IT IS WRITTEN BY Makefile.PL
# EDIT THAT INSTEAD
#
package NetAddr::IP::Util_IS;
use vars qw($VERSION);
$VERSION = 1.00;


sub pure {
  return 1;
}
sub not_pure {
  return 0;
}
1;
__END__

=head1 NAME

NetAddr::IP::Util_IS - Tell about Pure Perl

=head1 SYNOPSIS

  use NetAddr::IP::Util_IS;

  $rv = NetAddr::IP::Util_IS->pure;
  $rv = NetAddr::IP::Util_IS->not_pure;

=head1 DESCRIPTION

Util_IS indicates whether or not B<NetAddr::IP::Util> was compiled in Pure
Perl mode.

=over 4

=item * $rv = NetAddr::IP::Util_IS->pure;

Returns true if PurePerl mode, else false.

=item * $rv = NetAddr::IP::Util_IS->not_pure;

Returns true if NOT PurePerl mode, else false

=back

=cut

1;
