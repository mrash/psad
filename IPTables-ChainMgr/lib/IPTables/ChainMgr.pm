#
#############################################################################
#
# File: IPTables::ChainMgr.pm
#
# Purpose: Perl interface to add and delete rules to an iptables chain.  The
#          most common application of this module is to create a custom chain
#          and then add blocking rules to it.  Rule additions are (mostly)
#          guaranteed to be unique.
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
use IPTables::Parse;
use Net::IPv4Addr 'ipv4_network';
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

sub create_chain() {
    my $self = shift;
    my $table = shift || croak '[*] Must specify a table, e.g. "filter".';
    my $chain = shift || croak '[*] Must specify a chain to create.';
    my $iptables = $self->{'_iptables'};

    if (&run_ipt_cmd("$iptables -t $table -nL $chain") == 0) {
        ### the chain already exists
        return 1, "[+] $chain already exists.";
    } else {
        ### create the chain
        if (&run_ipt_cmd("$iptables -t $table -N $chain") == 0) {
            return 1, "[+] $chain chain created.";
        } else {
            ### could not create the chain
            return 0, "[-] Could not create $chain chain.";
        }
    }
}

sub delete_chain() {
    my $self = shift;
    my $table = shift || croak '[*] Must specify a table, e.g. "filter".';
    my $chain = shift || croak '[*] Must specify a chain to delete.';
    my $iptables = $self->{'_iptables'};

    ### see if the chain exists first
    if (&run_ipt_cmd("$iptables -t $table -nL $chain") == 0) {
        ### flush the chain first
        if (&run_ipt_cmd("$iptables -t $table -F $chain") == 0) {
            if (&run_ipt_cmd("$iptables -t $table -X $chain") == 0) {
                return 1, "[+] $chain chain deleted.";
            } else {
                return 0, "[-] Could not delete $chain chain.";
            }
        } else {
            return 0, "[-] Could not flush $chain chain.";
        }
    } else {
        return 1, "[+] $chain chain does not exist";
    }
}

sub add_rule() {
    my $self = shift;
    my $src = shift || croak '[-] Must specify a src address/network.';
    my $table  = shift || croak '[-] Must specify a table, e.g. "filter".';
    my $chain  = shift || croak '[-] Must specify a chain.';
    my $target = shift ||
        croak '[-] Must specify a Netfilter target, e.g. "DROP"';
    my $iptables = $self->{'_iptables'};

    ### regex to match an IP address
    my $ip_re = '(?:\d{1,3}\.){3}\d{1,3}';

    ### normalize src network if necessary; this is because Netfilter
    ### always reports network address for subnets
    my $normalized_src = '';
    if ($src =~ m|($ip_re)/($ip_re)|) {
        my ($net_addr, $cidr) = ipv4_network($1, $2);
        $normalized_src = "$net_addr/$cidr";
    } elsif ($src =~ m|($ip_re)/(\d+)|) {
        my ($net_addr, $cidr) = ipv4_network($1, $2);
        $normalized_src = "$net_addr/$cidr";
    } else {
        ### it is a hostname or an individual IP
        $normalized_src = $src;
    }

    ### first check to see if this rule already exists
    if (&find_rule($normalized_src, $table, $chain, $target, $iptables)) {
        return 1, '[-] Rule already exists.';
    } else {
        ### we need to add the rule
        if (&run_ipt_cmd("$iptables " .
            "-t $table -I $chain 1 -s $normalized_src -j $target") == 0) {
            return 1, '[+] Added rule.';
        } else {
            return 0, "[+] Could not add $target rule for $normalized_src.";
        }
    }
}

sub delete_rule() {
    my $self = shift;
    my $src = shift || croak '[-] Must specify a src address/network.';
    my $table  = shift || croak '[-] Must specify a table, e.g. "filter".';
    my $chain  = shift || croak '[-] Must specify a chain.';
    my $target = shift ||
        croak '[-] Must specify a Netfilter target, e.g. "DROP"';
    my $iptables = $self->{'_iptables'};

    ### regex to match an IP address
    my $ip_re = '(?:\d{1,3}\.){3}\d{1,3}';

    ### normalize src network if necessary; this is because Netfilter
    ### always reports network address for subnets
    my $normalized_src = '';
    if ($src =~ m|($ip_re)/($ip_re)|) {
        my ($net_addr, $cidr) = ipv4_network($1, $2);
        $normalized_src = "$net_addr/$cidr";
    } elsif ($src =~ m|($ip_re)/(\d+)|) {
        my ($net_addr, $cidr) = ipv4_network($1, $2);
        $normalized_src = "$net_addr/$cidr";
    } else {
        ### it is a hostname or an individual IP
        $normalized_src = $src;
    }

    ### first check to see if this rule already exists
    my $rulenum = &find_rule($normalized_src, $table,
            $chain, $target, $iptables);
    if ($rulenum) {
        ### we need to delete the rule
        if (&run_ipt_cmd("$iptables " .
            "-t $table -D $chain $rulenum") == 0) {
            return 1, "[+] Deleted rule #$rulenum";
        } else {
            return 0, "[+] Could not delete $target rule " .
                "#$rulenum for $normalized_src.";
        }
    } else {
        return 0, "[-] Rule does not exist in $chain chain.";
    }
}

sub find_rule() {
    my ($src, $table, $chain, $target, $iptables) = @_;

    my $ipt_parse = new IPTables::Parse 'iptables' => $iptables;

    my $chain_href = $ipt_parse->chain_action_rules($table, $chain);

    if (defined $chain_href->{$target}) {
        if (defined $chain_href->{$target}->{'all'}) {
            ### all protocols
            if (defined $chain_href->{$target}->{'all'}->{$src}) {
                ### $src to any destination
                if (defined $chain_href->{$target}->{'all'}
                        ->{$src}->{'0.0.0.0/0'}) {
                    ### return Netfilter rule number
                    return $chain_href->{$target}->{'all'}
                        ->{$src}->{'0.0.0.0/0'};
                }
            }
        }
    }
    return 0;
}

sub run_ipt_cmd() {
    my $cmd = shift || croak '[*] Must specify an iptables command to run.';
    return (system "$cmd > /dev/null 2>&1") >> 8;
}

sub run_ipt_cmd_output() {
    my $cmd = shift || croak '[*] Must specify an iptables command to run.';
    my @output = ();
    my $rv = 0;
    eval {
        open IPT, "$cmd |"
            or croak "[*] Could not execute $cmd: $!";
        @output = <IPT>;
        close IPT or croak "[*] Could not close command $cmd: $!";
        $rv = $?;
    };
    return $rv, \@output;
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
