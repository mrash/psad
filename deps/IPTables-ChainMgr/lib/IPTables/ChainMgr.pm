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
# Version: 0.4
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

$VERSION = '0.4';

sub new() {
    my $class = shift;
    my %args  = @_;

    my $self = {
        _iptables => $args{'iptables'} || '/sbin/iptables',
        _iptout   => $args{'iptout'}   || '/tmp/ipt.out',
        _ipterr   => $args{'ipterr'}   || '/tmp/ipt.err',
        _debug    => $args{'debug'}    || 0,
        _verbose  => $args{'verbose'}  || 0,
    };
    croak "[*] $self->{'_iptables'} incorrect iptables path.\n"
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

    ### see if the chain exists
    return $self->run_ipt_cmd("$iptables -t $table -n -L $chain");
}

sub create_chain() {
    my $self = shift;
    my $table = shift || croak '[*] Must specify a table, e.g. "filter".';
    my $chain = shift || croak '[*] Must specify a chain to create.';
    my $iptables = $self->{'_iptables'};

    ### see if the chain exists first
    my ($rv, $out_aref, $err_aref) = $self->chain_exists($table, $chain);

    ### the chain already exists
    return 1, $out_aref, $err_aref if $rv;

    ### create the chain
    return $self->run_ipt_cmd("$iptables -t $table -N $chain");
}

sub flush_chain() {
    my $self = shift;
    my $table = shift || croak '[*] Must specify a table, e.g. "filter".';
    my $chain = shift || croak '[*] Must specify a chain.';
    my $iptables = $self->{'_iptables'};

    ### flush the chain
    return $self->run_ipt_cmd("$iptables -t $table -F $chain");
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
    my ($rv, $out_aref, $err_aref) = $self->chain_exists($table, $del_chain);

    ### return true if the chain doesn't exist (it is not an error condition)
    return 1, $out_aref, $err_aref unless $rv;

    ### flush the chain
    ($rv, $out_aref, $err_aref)
        = $self->flush_chain($table, $del_chain, $iptables);

    ### could not flush the chain
    return 0, $out_aref, $err_aref unless $rv;

    ### find and delete jump rules to this chain (we can't delete
    ### the chain until there are no references to it)
    my ($rulenum, $num_chain_rules)
        = $self->find_ip_rule('0.0.0.0/0',
            '0.0.0.0/0', $table, $jump_from_chain, $del_chain, {});

    if ($rulenum) {
        $self->run_ipt_cmd(
            "$iptables -t $table -D $jump_from_chain $rulenum");
    }

    ### note that we try to delete the chain now regardless
    ### of whether their were jump rules above (should probably
    ### parse for the "0 references" under the -nL <chain> output).
    return $self->run_ipt_cmd("$iptables -t $table -X $del_chain");
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
    ### optionally add port numbers and protocols, etc.
    my $extended_href = shift || {};
    my $iptables = $self->{'_iptables'};

    ### normalize src/dst if necessary; this is because Netfilter
    ### always reports network address for subnets
    my $normalized_src = $self->normalize_net($src);
    my $normalized_dst = $self->normalize_net($dst);

    ### first check to see if this rule already exists
    my ($rule_position, $num_chain_rules)
            = $self->find_ip_rule($normalized_src, $normalized_dst, $table,
                $chain, $target, $extended_href);

    if ($rule_position) {
        my $msg = '';
        if ($extended_href) {
            $msg = "Table: $table, chain: $chain, $normalized_src -> " .
                "$normalized_dst ";
            for my $key qw(protocol s_port d_port) {
                $msg .= "$key $extended_href->{$key} "
                    if defined $extended_href->{$key};
            }
            $msg .= 'rule already exists.';
        } else {
            $msg = "Table: $table, chain: $chain, $normalized_src -> " .
                "$normalized_dst rule already exists.";
        }
        return 1, [$msg], [];
    }

    ### we need to add the rule
    my $ipt_cmd = '';
    my $msg     = '';
    my $idx_err = '';

    ### check to see if the insertion index ($rulenum) is too big
    $rulenum = 1 if $rulenum <= 0;
    if ($rulenum > $num_chain_rules+1) {
        $idx_err = "Rule position $rulenum is past end of $chain " .
            "chain ($num_chain_rules rules), compensating."
            if $num_chain_rules > 0;
        $rulenum = $num_chain_rules + 1;
    }
    $rulenum = 1 if $rulenum == 0;

    if ($extended_href) {
        $ipt_cmd = "$iptables -t $table -I $chain $rulenum ";
        $ipt_cmd .= "-p $extended_href->{'protocol'} "
            if defined $extended_href->{'protocol'};
        $ipt_cmd .= "-s $normalized_src ";
        $ipt_cmd .= "--sport $extended_href->{'s_port'} "
            if defined $extended_href->{'s_port'};
        $ipt_cmd .= "-d $normalized_dst ";
        $ipt_cmd .= "--dport $extended_href->{'d_port'} "
            if defined $extended_href->{'d_port'};
        $ipt_cmd .= "-j $target";
        $msg = "Table: $table, chain: $chain, added $normalized_src " .
            "-> $normalized_dst ";
        for my $key qw(protocol s_port d_port) {
            $msg .= "$key $extended_href->{$key} "
                if defined $extended_href->{$key};
        }
        $msg =~ s/\s*$//;
    } else {
        $ipt_cmd = "$iptables -t $table -I $chain $rulenum " .
            "-s $normalized_src -d $normalized_dst -j $target";
        $msg = "Table: $table, chain: $chain, added $normalized_src " .
            "-> $normalized_dst";
    }
    my ($rv, $out_aref, $err_aref) = $self->run_ipt_cmd($ipt_cmd);
    if ($rv) {
        push @$out_aref, $msg if $msg;
    }
    push @$err_aref, $idx_err if $idx_err;
    return $rv, $out_aref, $err_aref;
}

sub delete_ip_rule() {
    my $self = shift;
    my $src = shift || croak '[-] Must specify a src address/network.';
    my $dst = shift || croak '[-] Must specify a dst address/network.';
    my $table  = shift || croak '[-] Must specify a table, e.g. "filter".';
    my $chain  = shift || croak '[-] Must specify a chain.';
    my $target = shift ||
        croak '[-] Must specify a Netfilter target, e.g. "DROP"';
    ### optionally add port numbers and protocols, etc.
    my $extended_href = shift || {};
    my $iptables = $self->{'_iptables'};

    ### normalize src/dst if necessary; this is because Netfilter
    ### always reports network address for subnets
    my $normalized_src = $self->normalize_net($src);
    my $normalized_dst = $self->normalize_net($dst);

    ### first check to see if this rule already exists
    my ($rulenum, $num_chain_rules)
        = $self->find_ip_rule($normalized_src,
            $normalized_dst, $table, $chain, $target, $extended_href);

    if ($rulenum) {
        ### we need to delete the rule
        return $self->run_ipt_cmd("$iptables -t $table -D $chain $rulenum");
    }

    my $extended_msg = '';
    if ($extended_href) {
        for my $key qw(protocol s_port d_port) {
            $extended_msg .= "$key: $extended_href->{$key} "
                if defined $extended_href->{$key};
        }
    }
    $extended_msg =~ s/\s*$//;
    return 0, [], ["Table: $table, chain: $chain, rule $normalized_src " .
        "-> $normalized_dst $extended_msg does not exist."];
}

sub find_ip_rule() {
    my $self = shift;
    my $src   = shift || croak '[*] Must specify source address.';
    my $dst   = shift || croak '[*] Must specify destination address.';
    my $table = shift || croak '[*] Must specify Netfilter table.';
    my $chain = shift || croak '[*] Must specify Netfilter chain.';
    my $target = shift ||
        croak '[*] Must specify Netfilter target (this may be a chain).';
    ### optionally add port numbers and protocols, etc.
    my $extended_href = shift || {};
    my $iptables = $self->{'_iptables'};

    my $ipt_parse = new IPTables::Parse('iptables' => $iptables)
        or croak "[*] Could not acquire IPTables::Parse object";

    my $chain_aref = $ipt_parse->chain_rules($table, $chain);

    my $rulenum = 1;
    for my $rule_href (@$chain_aref) {
        if ($rule_href->{'target'} eq $target
                and $rule_href->{'src'} eq $src
                and $rule_href->{'dst'} eq $dst) {
            if ($extended_href) {
                my $found = 1;
                for my $key qw(
                    protocol
                    s_port
                    d_port
                ) {
                    if (defined $extended_href->{$key}) {
                        unless ($extended_href->{$key}
                                eq $rule_href->{$key}) {
                            $found = 0
                        }
                    }
                }
                return $rulenum, $#$chain_aref+1 if $found;
            } else {
                if ($rule_href->{'protocol'} eq 'all') {
                    if ($target eq 'LOG' or $target eq 'ULOG') {
                        ### built-in LOG and ULOG target rules always
                        ### have extended information
                        return $rulenum, $#$chain_aref+1;
                    } elsif (not $rule_href->{'extended'}) {
                        ### don't want any additional criteria (such as
                        ### port numbers) in the rule. Note that we are
                        ### also not checking interfaces
                        return $rulenum, $#$chain_aref+1;
                    }
                }
            }
        }
        $rulenum++;
    }
    return 0, $#$chain_aref+1;
}

sub normalize_net() {
    my $self = shift;
    my $net  = shift || croak '[*] Must specify net.';

    ### regex to match an IP address
    my $ip_re = '(?:\d{1,3}\.){3}\d{1,3}';

    my $normalized_net = '';
    if ($net =~ m|($ip_re)/($ip_re)|) {
        my ($net_addr, $cidr) = ipv4_network($1, $2);
        $normalized_net = "$net_addr/$cidr";
    } elsif ($net =~ m|($ip_re)/(\d+)|) {
        my ($net_addr, $cidr) = ipv4_network($1, $2);
        $normalized_net = "$net_addr/$cidr";
    } else {
        ### it is a hostname or an individual IP
        $normalized_net = $net;
    }
    return $normalized_net;
}

sub add_jump_rule() {
    my $self  = shift;
    my $table = shift || croak '[-] Must specify a table, e.g. "filter".';
    my $from_chain = shift || croak '[-] Must specify chain to jump from.';
    my $rulenum    = shift || croak '[-] Must specify jump rule chain position';
    my $to_chain   = shift || croak '[-] Must specify chain to jump to.';
    my $iptables = $self->{'_iptables'};
    my $idx_err = '';

    if ($from_chain eq $to_chain) {
        return 0, ["Identical from_chain and to_chain ($from_chain) " .
            "not allowed."], [];
    }

    ### first check to see if the jump rule already exists
    my ($rule_position, $num_chain_rules)
        = $self->find_ip_rule('0.0.0.0/0', '0.0.0.0/0', $table,
            $from_chain, $to_chain, {});

    ### check to see if the insertion index ($rulenum) is too big
    $rulenum = 1 if $rulenum <= 0;
    if ($rulenum > $num_chain_rules+1) {
        $idx_err = "Rule position $rulenum is past end of $from_chain " .
            "chain ($num_chain_rules rules), compensating."
            if $num_chain_rules > 0;
        $rulenum = $num_chain_rules + 1;
    }
    $rulenum = 1 if $rulenum == 0;

    if ($rule_position) {
        ### the rule already exists
        return 1,
            ["Table: $table, chain: $to_chain, jump rule already exists."], [];
    }

    ### we need to add the rule
    my ($rv, $out_aref, $err_aref) = $self->run_ipt_cmd(
        "$iptables -t $table -I $from_chain $rulenum -j $to_chain");
    push @$err_aref, $idx_err if $idx_err;
    return $rv, $out_aref, $err_aref;
}

sub run_ipt_cmd() {
    my $self  = shift;
    my $cmd = shift || croak '[*] Must specify an iptables command to run.';
    my $iptables = $self->{'_iptables'};
    my $iptout   = $self->{'_iptout'};
    my $ipterr   = $self->{'_ipterr'};
    my $debug    = $self->{'_debug'};
    my $verbose  = $self->{'_verbose'};
    croak "[*] $cmd does not look like an iptables command."
        unless $cmd =~ m|^\s*iptables| or $cmd =~ m|^\S+/iptables|;

    if ($verbose) {
        print STDOUT $cmd, "\n";
    } elsif ($debug) {
        print STDERR $cmd, "\n";
    }

    ### run the command and collect both stdout and stderr
    system "$cmd > $iptout 2> $ipterr";

    my $rv = 1;
    my @stdout = ();
    my @stderr = ();

    if (-e $iptout) {
        open F, "< $iptout" or croak "[*] Could not open $iptout";
        @stdout = <F>;
        close F;
    }
    if (-e $ipterr) {
        open F, "< $ipterr" or croak "[*] Could not open $ipterr";
        @stderr = <F>;
        close F;

        $rv = 0 if @stderr;
    }

    if ($debug and $verbose) {
        print "[+] iptables command stdout:\n";
        for my $line (@stdout) {
            if ($line =~ /\n$/) {
                print $line;
            } else {
                print $line, "\n";
            }
        }
        print "[+] iptables command stderr:\n";
        for my $line (@stderr) {
            if ($line =~ /\n$/) {
                print $line;
            } else {
                print $line, "\n";
            }
        }
    }

    return $rv, \@stdout, \@stderr;
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
