#
##################################################################
#
# File: IPTables::Parse.pm
#
# Purpose: Perl interface to parse iptables rulesets.
#
# Author: Michael Rash (mbr@cipherdyne.org)
#
# Version: 0.2
#
##################################################################
#
# $Id$
#

package IPTables::Parse;

use 5.006;
use Carp;
use strict;
use warnings;
use vars qw($VERSION);

$VERSION = '0.2';

sub new() {
    my $class = shift;
    my %args  = @_;

    my $self = {
        _iptables => $args{'iptables'} || '/sbin/iptables'
    };
    croak "[*] $self->{'_iptables'} incorrect path.\n"
        unless -e $self->{'_iptables'};
    croak "[*] $self->{'_iptables'} not executable.\n"
        unless -x $self->{'_iptables'};
    bless $self, $class;
}

sub chain_action_rules() {
    my $self   = shift;
    my $table  = shift || croak "[*] Specify a table, e.g. \"nat\"";
    my $chain  = shift || croak "[*] Specify a chain, e.g. \"OUTPUT\"";
    my $action = shift || croak "[*] Specify either ",
        "\"ACCEPT\", \"DROP\", or \"LOG\"";
    my $file   = shift || '';
    my $iptables  = $self->{'_iptables'};
    my @ipt_lines;

    if ($file) {
        ### read the iptables rules out of $file instead of executing
        ### the iptables command.
        open F, "< $file" or croak "[*] Could not open file $file: $!";
        @ipt_lines = <F>;
        close F;
    } else {
        eval {
            open IPT, "$iptables -t $table -nL $chain |"
                or croak "[*] Could not execute $iptables -t $table -nL $chain";
            @ipt_lines = <IPT>;
            close IPT;
        };
    }

    my $found_chain = 0;
    my $rule_ctr = 0;
    my %chain = ();

    LINE: for my $line (@ipt_lines) {
        $rule_ctr++;
        chomp $line;

        last if ($found_chain and $line =~ /^\s*Chain\s+/);
        ### ACCEPT tcp  -- 164.109.8.0/24  0.0.0.0/0  tcp dpt:22 flags:0x16/0x02
        ### ACCEPT tcp  -- 216.109.125.67  0.0.0.0/0  tcp dpts:7000:7500
        ### ACCEPT udp  -- 0.0.0.0/0       0.0.0.0/0  udp dpts:7000:7500
        ### ACCEPT udp  -- 0.0.0.0/0       0.0.0.0/0  udp dpt:!7000
        ### ACCEPT icmp --  0.0.0.0/0      0.0.0.0/0
        ### ACCEPT tcp  --  0.0.0.0/0      0.0.0.0/0  tcp spt:35000 dpt:5000
        ### ACCEPT tcp  --  10.1.1.1       0.0.0.0/0

        ### LOG  all  --  0.0.0.0/0  0.0.0.0/0  LOG flags 0 level 4 prefix `DROP '
        ### LOG  all  --  127.0.0.2  0.0.0.0/0  LOG flags 0 level 4

        if ($line =~ /^\s*Chain\s+$chain\s+\(policy\s+(\w+)\)/) {
            $found_chain = 1;
        }
        next unless $found_chain;
        if ($line =~ m|^$action\s+(\S+)\s+\-\-\s+(\S+)\s+(\S+)\s*(.*)|) {
            my $proto = $1;
            my $src   = $2;
            my $dst   = $3;
            my $p_str = $4;
            if ($p_str and ($proto eq 'tcp' or $proto eq 'udp')) {
                my $s_port  = '0:0';  ### any to any
                my $d_port  = '0:0';
                if ($p_str =~ /dpts?:(\S+)/) {
                    $d_port = $1;
                }
                if ($p_str =~ /spts?:(\S+)/) {
                    $s_port = $1;
                }
                $chain{$proto}{$s_port}{$d_port}{$src}{$dst}
                    = $rule_ctr;
            } else {
                $chain{$proto}{$src}{$dst} = $rule_ctr;
            }
        }
    }
    return \%chain;
}

sub default_drop() {
    my $self  = shift;
    my $table = shift || croak "[*] Specify a table, e.g. \"nat\"";
    my $chain = shift || croak "[*] Specify a chain, e.g. \"OUTPUT\"";
    my $file  = shift || '';
    my $iptables  = $self->{'_iptables'};
    my @ipt_lines;

    if ($file) {
        ### read the iptables rules out of $file instead of executing
        ### the iptables command.
        open F, "< $file" or croak "[*] Could not open file $file: $!";
        @ipt_lines = <F>;
        close F;
    } else {
        eval {
            open IPT, "$iptables -t $table -nL $chain |"
                or croak "[*] Could not execute $iptables -t $table -nL $chain";
            @ipt_lines = <IPT>;
            close IPT;
        };
    }

    return '[-] Could not get iptables output!', 0
        unless @ipt_lines;

    my %protocols = ();
    my $found_chain = 0;
    my $rule_ctr = 0;
    my $prefix;
    my $policy = 'ACCEPT';
    my $any_ip_re = '(?:0\.){3}0/0';

    for my $line (@ipt_lines) {
        $rule_ctr++;
        chomp $line;

        last if ($found_chain and $line =~ /^\s*Chain\s+/);

        ### Chain INPUT (policy DROP)
        ### Chain FORWARD (policy ACCEPT)
        if ($line =~ /^\s*Chain\s+$chain\s+\(policy\s+(\w+)\)/) {
            $policy = $1;
            $found_chain = 1;
        }
        next unless $found_chain;
        if ($line =~ m|^LOG\s+(\w+)\s+\-\-\s+
            $any_ip_re\s+$any_ip_re\s+(.*)|x) {
            my $proto  = $1;
            my $p_tmp  = $2;
            my $prefix = 'NONE';
            ### LOG flags 0 level 4 prefix `DROP '
            if ($p_tmp && $p_tmp =~ m|LOG.*\s+prefix\s+
                \`\s*(.+?)\s*\'|x) {
                $prefix = $1;
            }
            ### $proto may equal "all" here
            $protocols{$proto}{'LOG'}{'prefix'} = $prefix;
            $protocols{$proto}{'LOG'}{'rulenum'} = $rule_ctr;
        } elsif ($policy eq 'ACCEPT' and $line =~ m|^DROP\s+(\w+)\s+\-\-\s+
            $any_ip_re\s+$any_ip_re\s*$|x) {
            ### DROP    all  --  0.0.0.0/0     0.0.0.0/0
            $protocols{$1}{'DROP'} = $rule_ctr;
        }
    }
    ### if the policy in the chain is DROP, then we don't
    ### necessarily need to find a default DROP rule.
    if ($policy eq 'DROP') {
        $protocols{'all'}{'DROP'} = 0;
    }
    return \%protocols;
}

sub default_log() {
    my $self  = shift;
    my $table = shift || croak "[*] Specify a table, e.g. \"nat\"";
    my $chain = shift || croak "[*] Specify a chain, e.g. \"OUTPUT\"";
    my $file  = shift || '';
    my $iptables  = $self->{'_iptables'};

    my $any_ip_re = '(?:0\.){3}0/0';
    my @ipt_lines;
    my %log_chains = ();
    my %log_rules  = ();

    ### note that we are not restricting the view to the current chain
    ### with the iptables -nL output; we are going to parse the given
    ### chain and all chains to which packets are jumped from the given
    ### chain.
    if ($file) {
        ### read the iptables rules out of $file instead of executing
        ### the iptables command.
        open F, "< $file" or croak "[*] Could not open file $file: $!";
        @ipt_lines = <F>;
        close F;
    } else {
        eval {
            open IPT, "$iptables -t $table -nL |"
                or croak "[*] Could not execute $iptables -t $table -nL";
            @ipt_lines = <IPT>;
            close IPT;
        };
    }

    return '[-] Could not get iptables output!', 0
        unless @ipt_lines;

    ### first get all logging rules and associated chains
    my $log_chain;
    for my $line (@ipt_lines) {
        chomp $line;

        ### Chain INPUT (policy DROP)
        ### Chain fwsnort_INPUT_eth1 (1 references)
        if ($line =~ /^\s*Chain\s+(.*?)\s+\(/ and
                $line !~ /0\s+references/) {
            $log_chain = $1;
        }
        $log_chain = '' unless $line =~ /\S/;
        next unless $log_chain;

        if ($line =~ m|^\s*LOG\s+(\w+)\s+\-\-\s+$any_ip_re
            \s+$any_ip_re\s+LOG|x) {
            $log_chains{$log_chain}{$1} = '';  ### protocol

            if ($log_chain eq $chain) {
                $log_rules{$1} = '';
            }
        }
    }

    return '[-] There are no logging rules in the iptables policy!', 0
        unless %log_chains;

    my %sub_chains = ();

    ### get all sub-chains of the main chain we passed into default_log()
    &sub_chains($chain, \%sub_chains, \@ipt_lines);

    ### see which (if any) logging rules can be mapped back to the
    ### main chain we passed in.
    for my $log_chain (keys %log_chains) {
        if (defined $sub_chains{$log_chain}) {
            ### the logging rule is in the main chain (e.g. INPUT)
            for my $proto (keys %{$log_chains{$log_chain}}) {
                $log_rules{$proto} = '';
            }
        }
    }

    return \%log_rules;
}

sub sub_chains() {
    my ($start_chain, $chains_href, $ipt_lines_aref) = @_;
    my $found = 0;
    for my $line (@$ipt_lines_aref) {
        chomp $line;
        ### Chain INPUT (policy DROP)
        ### Chain fwsnort_INPUT_eth1 (1 references)
        if ($line =~ /^\s*Chain\s+$start_chain\s+\(/ and
                $line !~ /0\s+references/) {
            $found = 1;
            next;
        }
        next unless $found;
        if ($found and $line =~ /^\s*Chain\s/) {
            last;
        }
        if ($line =~ m|^\s*(\S+)\s+\S+\s+\-\-|) {
            my $new_chain = $1;
            if ($new_chain ne 'LOG'
                    and $new_chain ne 'DROP'
                    and $new_chain ne 'REJECT'
                    and $new_chain ne 'ACCEPT'
                    and $new_chain ne 'RETURN'
                    and $new_chain ne 'QUEUE'
                    and $new_chain ne 'SNAT'
                    and $new_chain ne 'DNAT'
                    and $new_chain ne 'MASQUERADE') {
                $chains_href->{$new_chain} = '';
                &sub_chains($new_chain, $chains_href, $ipt_lines_aref);
            }
        }
    }
    return;
}

1;
__END__

=head1 NAME

IPTables::Parse - Perl extension for parsing iptables firewall rulesets

=head1 SYNOPSIS

    use IPTables::Parse;

    my $table = 'filter';
    my $chain = 'INPUT';
    if (&IPTables::Parse::default_drop($table, $chain)) {
        print "[+] Table: $table, chain: $chain has a default rule\n";
    } else {
        print "[-] No default drop rule in table: $table, chain: $chain.\n";
    }

=head1 DESCRIPTION

IPTables::Parse provides a perl module interface to parse iptables rulesets.

=head1 AUTHOR

Michael Rash, E<lt>mbr@cipherdyne.orgE<gt>

=head1 SEE ALSO

L<perl>.

=cut
