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

sub chain_exists() {
    my $self = shift;
    my $table = shift || croak '[*] Must specify a table, e.g. "filter".';
    my $chain = shift || croak '[*] Must specify a chain to create.';
    my $iptables = $self->{'_iptables'};

    return &modinternal_chain_exists($table, $chain, $iptables);
}

sub modinternal_chain_exists() {
    my $table = shift || croak '[*] Must specify a table, e.g. "filter".';
    my $chain = shift || croak '[*] Must specify a chain to create.';
    my $iptables = shift || croak '[*] Must specify iptables command.';

    if (&run_ipt_cmd("$iptables -t $table -n -L $chain") == 0) {
        return 1;
    } else {
        return 0;
    }
}

sub create_chain() {
    my $self = shift;
    my $table = shift || croak '[*] Must specify a table, e.g. "filter".';
    my $chain = shift || croak '[*] Must specify a chain to create.';
    my $iptables = $self->{'_iptables'};

    if (&modinternal_chain_exists($table, $chain, $iptables)) {
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

sub flush_chain() {
    my $self = shift;
    my $table = shift || croak '[*] Must specify a table, e.g. "filter".';
    my $chain = shift || croak '[*] Must specify a chain.';
    my $iptables = $self->{'_iptables'};

    return &modinternal_flush_chain($table, $chain, $iptables);
}

sub modinternal_flush_chain() {
    my ($table, $chain, $iptables) = @_;

    if (&run_ipt_cmd("$iptables -t $table -F $chain") == 0) {
        return 1;
    } else {
        return 0;
    }
}

sub delete_chain() {
    my $self = shift;
    my $table = shift || croak '[*] Must specify a table, e.g. "filter".';
    my $jump_from_chain = shift ||
        croak '[*] Must specify a chain from which ',
            'packets were jumped to this chain';
    my $del_chain = shift || croak '[*] Must specify a chain to delete.';
    my $iptables = $self->{'_iptables'};

    ### see if the chain exists first
    if (&run_ipt_cmd("$iptables -t $table -n -L $del_chain") == 0) {
        ### flush the chain
        if (&modinternal_flush_chain($table, $del_chain, $iptables)) {
            ### find and delete jump rules to this chain (we can't delete
            ### the chain until there are no references to it)
            my $rulenum = &modinternal_find_ip_rule('0.0.0.0/0',
                '0.0.0.0/0', $table, $jump_from_chain, $del_chain, $iptables);
            if ($rulenum) {
                &run_ipt_cmd("$iptables -t $table " .
                    "-D $jump_from_chain $rulenum");
            }
            ### note that we try to delete the chain now regardless
            ### of whether their were jump rules above (should probably
            ### parse for the "0 references" under the -nL <chain> output).
            if (&run_ipt_cmd("$iptables -t $table -X $del_chain") == 0) {
                return 1, "[+] $table $del_chain chain deleted.";
            } else {
                return 0, "[-] Could not delete $table $del_chain chain.";
            }
        } else {
            return 0, "[-] Could not flush $table $del_chain chain.";
        }
    } else {
        return 0, "[+] $table $del_chain chain does not exist";
    }
}

sub add_ip_rule() {
    my $self = shift;
    my $src = shift || croak '[-] Must specify a src address/network.';
    my $dst = shift || croak '[-] Must specify a dst address/network.';
    my $rulenum = shift || croak '[-] Must specify an insert rule number.';
    my $table   = shift || croak '[-] Must specify a table, e.g. "filter".';
    my $chain   = shift || croak '[-] Must specify a chain.';
    my $target  = shift ||
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

    ### normalize dst network if necessary; this is because Netfilter
    ### always reports network address for subnets
    my $normalized_dst = '';
    if ($dst =~ m|($ip_re)/($ip_re)|) {
        my ($net_addr, $cidr) = ipv4_network($1, $2);
        $normalized_dst = "$net_addr/$cidr";
    } elsif ($dst =~ m|($ip_re)/(\d+)|) {
        my ($net_addr, $cidr) = ipv4_network($1, $2);
        $normalized_dst = "$net_addr/$cidr";
    } else {
        ### it is a hostname or an individual IP
        $normalized_dst = $dst;
    }

    ### first check to see if this rule already exists
    if (&modinternal_find_ip_rule($normalized_src, $normalized_dst, $table,
            $chain, $target, $iptables)) {
        return 1, '[-] Rule already exists.';
    } else {
        ### we need to add the rule
        if (&run_ipt_cmd("$iptables -t $table -I $chain $rulenum " .
                "-s $normalized_src -d $normalized_dst -j $target") == 0) {
            return 1, '[+] Added rule.';
        } else {
            return 0, "[+] Could not add $target rule for " .
                "$normalized_src -> $normalized_dst";
        }
    }
}

sub delete_ip_rule() {
    my $self = shift;
    my $src = shift || croak '[-] Must specify a src address/network.';
    my $dst = shift || croak '[-] Must specify a dst address/network.';
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

    ### normalize dst network if necessary; this is because Netfilter
    ### always reports network address for subnets
    my $normalized_dst = '';
    if ($dst =~ m|($ip_re)/($ip_re)|) {
        my ($net_addr, $cidr) = ipv4_network($1, $2);
        $normalized_dst = "$net_addr/$cidr";
    } elsif ($dst =~ m|($ip_re)/(\d+)|) {
        my ($net_addr, $cidr) = ipv4_network($1, $2);
        $normalized_dst = "$net_addr/$cidr";
    } else {
        ### it is a hostname or an individual IP
        $normalized_dst = $dst;
    }

    ### first check to see if this rule already exists
    my $rulenum = &modinternal_find_ip_rule($normalized_src,
        $normalized_dst, $table, $chain, $target, $iptables);
    if ($rulenum) {
        ### we need to delete the rule
        if (&run_ipt_cmd("$iptables " .
            "-t $table -D $chain $rulenum") == 0) {
            return 1, "[+] Deleted rule #$rulenum";
        } else {
            return 0, "[+] Could not delete $target rule " .
                "#$rulenum for $normalized_src -> $normalized_dst.";
        }
    } else {
        return 0, "[-] Rule does not exist in $chain chain.";
    }
}

sub find_ip_rule() {
    my $self = shift;
    my $src   = shift || croak '[*] Must specify source address.';
    my $dst   = shift || croak '[*] Must specify destination address.';
    my $table = shift || croak '[*] Must specify Netfilter table.';
    my $chain = shift || croak '[*] Must specify Netfilter chain.';
    my $target = shift ||
        croak '[*] Must specify Netfilter target (this may be a chain).';
    my $iptables = $self->{'_iptables'};

    return &modinternal_find_ip_rule($src, $dst,
        $table, $chain, $target, $iptables);
}

sub modinternal_find_ip_rule() {
    my $src   = shift || croak '[*] Must specify source address.';
    my $dst   = shift || croak '[*] Must specify destination address.';
    my $table = shift || croak '[*] Must specify Netfilter table.';
    my $chain = shift || croak '[*] Must specify Netfilter chain.';
    my $target = shift ||
        croak '[*] Must specify Netfilter target (this may be a chain).';
    my $iptables = shift || croak '[*] Must specify iptables command.]';

    ### first make sure the chain actually exists
    unless (&modinternal_chain_exists($table, $chain, $iptables)) {
        return 0;
    }

    my $ipt_parse = new IPTables::Parse('iptables' => $iptables)
        or croak "[*] Could not acquire IPTables::Parse object";

    my $chain_aref = $ipt_parse->chain_action_rules($table, $chain);

    for my $rule_href (@$chain_aref) {
        if ($rule_href->{'target'} eq $target
                and $rule_href->{'protocol'} eq 'all'
                and $rule_href->{'src'} eq $src
                and $rule_href->{'dst'} eq $dst
                ### don't want any additional criteria (such as
                ### port numbers) in the rule. Note that we are
                ### also not checking interfaces
                and not $rule_href->{'extended'}) {
            return 1;
        }
    }
    return 0;
}

sub add_jump_rule() {
    my $self  = shift;
    my $table = shift || croak '[-] Must specify a table, e.g. "filter".';
    my $from_chain = shift || croak '[-] Must specify chain to jump from.';
    my $to_chain   = shift || croak '[-] Must specify chain to jump to.';
    my $iptables = $self->{'_iptables'};

    ### first check to see if the jump rule already exists
    if (&modinternal_find_ip_rule('0.0.0.0/0', '0.0.0.0/0', $table,
            $from_chain, $to_chain, $iptables)) {
        return 1, '[-] Jump rule already exists.';
    } else {
        ### we need to add the rule
        if (&run_ipt_cmd("$iptables " .
            "-t $table -I $from_chain 1 -j $to_chain") == 0) {
            return 1, '[+] Added rule.';
        } else {
            return 0, "[+] Could not add jump rule for $to_chain.";
        }
    }
}

sub run_ipt_cmd() {
    my $cmd = shift || croak '[*] Must specify an iptables command to run.';
    croak "[*] $cmd does not look like an iptables command."
        unless $cmd =~ /iptables/;
    return (system "$cmd > /dev/null 2>&1") >> 8;
}

sub run_ipt_cmd_output() {
    my $cmd = shift || croak '[*] Must specify an iptables command to run.';
    croak "[*] $cmd does not look like an iptables command."
        unless $cmd =~ /iptables/;
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
