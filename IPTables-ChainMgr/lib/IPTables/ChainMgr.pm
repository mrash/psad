#
#############################################################################
#
# File: IPTables::ChainMgr.pm
#
# Purpose: Perl interface to add and delete rules to an iptables chain.  The
#          most common application of this module is to create a custom chain
#          and then add blocking rules to it.
#
# Author: Michael Rash (mbr@cipherdyne.org)
#
# Version: 0.1
#
#############################################################################
#
# $Id$
#


package IPTables::ChainMgr;

use 5.006;
use Carp;
use strict;
use warnings;
use vars qw($VERSION);

$VERSION = '0.1';

sub new() {
    my $class = shift;
    my %args  = @_;

    my $self = {
        _iptables => $args{'iptables'} || '/sbin/iptables',
        _table    => $args{'table'}    || '',
        _chain    => $args{'chain'}    || '',
        _debug    => $args{'debug'}    || 0
    };
    croak "[*] $self->{'_iptables'} incorrect path.\n"
        unless -e $self->{'_iptables'};
    croak "[*] $self->{'_iptables'} not executable.\n"
        unless -x $self->{'_iptables'};
    croak "[*] Must specify a table to which to add/delete rules.\n"
        unless $self->{'_table'};
    croak "[*] Must specify a chain to which to add/delete rules.\n"
        unless $self->{'_chain'};
    bless $self, $class;
}

sub create_chain() {
    my $self = shift;
    my $iptables = $self->{'iptables'};
    my $table    = $self->{'_table'};
    my $chain    = $self->{'_chain'};

    if (&run_ipt_cmd($iptables, "-t $table -nL $chain") == 0) {
        ### the chain already exists
        return 1, "[+] $chain already exists.";
    } else {
        ### create the chain
        if (&run_ipt_cmd($iptables, "-t $table -N $chain") == 0) {
            return 1, "[+] $chain chain created.";
        } else {
            ### could not create the chain
            return 0, "[-] Could not create $chain chain.";
        }
    }
}

sub delete_chain() {
    my $self = shift;
    my $iptables = $self->{'_iptables'};
    my $table    = $self->{'_table'};
    my $chain    = $self->{'_chain'};

    if(&run_ipt_cmd($iptables, "-t $table -nL $chain") == 0) {
        if (&run_ipt_cmd($iptables, "-t $table -X $chain") == 0) {
            return 1, "[+] $chain chain deleted.";
        } else {
            return 0, "[-] Could not delete $chain chain.";
        }
    } else {
        return 1, "[+] $chain chain does not exist";
    }
}

sub add_rule() {
    my $self = shift;
    my $src = shift || croak '[-] Must specify a src address/network.';
    my $target = shift ||
        croak '[-] Must specify a Netfilter target, e.g. "DROP"';
    my $iptables = $self->{'_iptables'};
    my $table    = $self->{'_table'};
    my $chain    = $self->{'_chain'};

    ### first check to see if this rule already exists
    my ($rv, $chain_lines_aref) =
        &run_ipt_cmd_output($iptables, "-t $table -nL $chain");

    if (&find_rule($chain_lines_aref)) {
        return 1, '[-] Rule already exists.';
    } else {
        ### we need to add the rule
        if (&run_ipt_cmd($iptables,
            "-t $table -I $chain 1 -s $src -j $target") == 0) {
        }
    }
}

sub run_ipt_cmd() {
    my ($iptables, $cmd) = @_;
    croak "[*] Must specify an iptables command to run unless $cmd"
        unless $cmd;
    open IPT, "$iptables $cmd |"
        or croak "[*] Could not execute $iptables $cmd: $!";
    close IPT;
    return $?;
}

sub run_ipt_cmd_output() {
    my ($iptables, $cmd) = @_;
    croak "[*] Must specify an iptables command to run unless $cmd"
        unless $cmd;
    my @output = ();
    open IPT, "$iptables $cmd |"
        or croak "[*] Could not execute $iptables $cmd: $!";
    @output = <IPT>;
    close IPT;
    return $?, \@output;
}

1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

IPTables::ChainMgr - Perl extension for blah blah blah

=head1 SYNOPSIS

  use IPTables::ChainMgr;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for IPTables::ChainMgr, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

A. U. Thor, E<lt>mbr@gambrl01.md.comcast.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by A. U. Thor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
