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
        _debug    => $args{'debug'}    || 0
    };
    croak "[*] $self->{'_iptables'} incorrect path.\n"
        unless -e $self->{'_iptables'};
    croak "[*] $self->{'_iptables'} not executable.\n"
        unless -x $self->{'_iptables'};
    bless $self, $class;
}

sub get_iptables_chains() {
    my $self = shift;

    print STDERR "[+] get_iptables_chains()\n" if $self->{'_debug'};

    my $iptables = $self->{'_iptables'};

    my %ipt_chains = ();

    my $nat_rv    = 1;
    my $mangle_rv = 1;
    my $filter_input_rv   = 1;
    my $filter_forward_rv = 1;

    my %ipt_chain_test = (
        'filter' => {
            'INPUT'   => '',
            'OUTPUT'  => '',
            'FORWARD' => ''
        },
        'nat' => {
            'PREROUTING' => ''
        },
        'mangle' => {
            'PREROUTING' => ''
        }
    );

    for my $table (keys %ipt_chain_test) {
        for my $chain (keys %{$ipt_chain_test{$table}}) {
            my $rv = 1;
            eval {
                $rv = (system "$cmds{'iptables'} -nL -t $table " .
                    "> /dev/null 2>&1") >> 8;
            };
            if ($rv == 0) {
                eval {
                    $rv = (system "$cmds{'iptables'} -t $table -I " .
                        "$chain 1 -s 127.0.0.2 -j DROP > /dev/null " .
                        "2>&1") >> 8;
                };
                if ($rv == 0) {
                    eval {
                        $rv = (system "$cmds{'iptables'} -t $table -D " .
                            "$chain 1 > /dev/null 2>&1") >> 8;
                    };
                }
                if ($rv == 0) {
                    $ipt_chains{$table}{$chain} = '';
                }
            }
            print STDERR "[+] get_iptables_chains(): $table $chain rv: $rv\n"
                if $debug;
        }
    }
    return \%ipt_chains;
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
