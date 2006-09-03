#
##################################################################
#
# File: IPTables::Parse.pm
#
# Purpose: Perl interface to parse iptables rulesets.
#
# Author: Michael Rash (mbr@cipherdyne.org)
#
# Version: 0.3
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

$VERSION = '0.3';

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

sub chain_policy() {
    my $self   = shift;
    my $table  = shift || croak '[*] Specify a table, e.g. "nat"';
    my $chain  = shift || croak '[*] Specify a chain, e.g. "OUTPUT"';
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
            open IPT, "$iptables -t $table -n -L $chain -v |"
                or croak "[*] Could not execute $iptables -t $table -n -L $chain -v";
            @ipt_lines = <IPT>;
            close IPT;
        };
    }

    my $policy = '';

    for my $line (@ipt_lines) {
        ### Chain INPUT (policy ACCEPT 16 packets, 800 bytes)
        if ($line =~ /^\s*Chain\s+$chain\s+\(policy\s+(\w+)/) {
            $policy = $1;
            last;
        }
    }

    return $policy;
}

sub chain_action_rules() {
    return &chain_rules();
}

sub chain_rules() {
    my $self   = shift;
    my $table  = shift || croak '[*] Specify a table, e.g. "nat"';
    my $chain  = shift || croak '[*] Specify a chain, e.g. "OUTPUT"';
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
            open IPT, "$iptables -t $table -n -L $chain -v |"
                or croak "[*] Could not execute $iptables -t $table -n -L $chain -v";
            @ipt_lines = <IPT>;
            close IPT;
        };
    }

    my $found_chain = 0;

    ### array of hash refs
    my @chain = ();

    ### determine the output style (e.g. "-nL -v" or just plain "-nL"; if the
    ### policy data came from a file then -v might not have been used)
    my $ipt_verbose = 0;
    for my $line (@ipt_lines) {
        if ($line =~ /^\s*pkts\s+bytes\s+target/) {
            $ipt_verbose = 1;
            last;
        }
    }

    LINE: for my $line (@ipt_lines) {
        chomp $line;

        last LINE if ($found_chain and $line =~ /^\s*Chain\s+/);

        if ($line =~ /^\s*Chain\s+$chain\s+\(/i) {
            $found_chain = 1;
            next LINE;
        }
        if ($ipt_verbose) {
            next LINE if $line =~ /^\s*pkts\s+bytes\s+target\s/i;
        } else {
            next LINE if $line =~ /^\s*target\s+prot/i;
        }
        next LINE unless $found_chain;

        ### initialize hash
        my %rule = (
            'packets'  => '',
            'bytes'    => '',
            'target'   => '',
            'protocol' => '',
            'proto'    => '',
            'intf_in'  => '',
            'intf_out' => '',
            'src'      => '',
            's_port'   => '',
            'sport'    => '',
            'dst'      => '',
            'd_port'   => '',
            'dport'    => '',
            'extended' => '',
            'raw'      => ''  ### only used if regex doesn't match
        );

        if ($ipt_verbose) {
            ### 0     0 ACCEPT  tcp  --  eth1 * 192.168.10.3  0.0.0.0/0  tcp dpt:80
            ### 0     0 ACCEPT  tcp  --  eth1 * 192.168.10.15 0.0.0.0/0  tcp dpt:22
            ### 33 2348 ACCEPT  tcp  --  eth1 * 192.168.10.2  0.0.0.0/0  tcp dpt:22
            ### 0     0 ACCEPT  tcp  --  eth1 * 192.168.10.2  0.0.0.0/0  tcp dpt:80
            if ($line =~ m|^\s*(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+\-\-\s+
                                (\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s*(.*)|x) {
                $rule{'packets'}  = $1;
                $rule{'bytes'}    = $2;
                $rule{'target'}   = $3;
                $rule{'protocol'} = $rule{'proto'} = $4;
                $rule{'intf_in'}  = $5;
                $rule{'intf_out'} = $6;
                $rule{'src'}      = $7;
                $rule{'dst'}      = $8;
                $rule{'extended'} = $9;
                if ($rule{'extended'}
                        and ($rule{'protocol'} eq 'tcp'
                        or $rule{'protocol'} eq 'udp')) {
                    my $s_port  = '0:0';  ### any to any
                    my $d_port  = '0:0';
                    if ($rule{'extended'} =~ /dpts?:(\S+)/) {
                        $d_port = $1;
                    }
                    if ($rule{'extended'} =~ /spts?:(\S+)/) {
                        $s_port = $1;
                    }
                    $rule{'s_port'} = $s_port;
                    $rule{'sport'}  = $s_port;
                    $rule{'d_port'} = $d_port;
                    $rule{'dport'}  = $d_port;
                }
            } else {
                $rule{'raw'} = $line;
            }
        } else {
            ### ACCEPT tcp  -- 164.109.8.0/24  0.0.0.0/0  tcp dpt:22 flags:0x16/0x02
            ### ACCEPT tcp  -- 216.109.125.67  0.0.0.0/0  tcp dpts:7000:7500
            ### ACCEPT udp  -- 0.0.0.0/0       0.0.0.0/0  udp dpts:7000:7500
            ### ACCEPT udp  -- 0.0.0.0/0       0.0.0.0/0  udp dpt:!7000
            ### ACCEPT icmp --  0.0.0.0/0      0.0.0.0/0
            ### ACCEPT tcp  --  0.0.0.0/0      0.0.0.0/0  tcp spt:35000 dpt:5000
            ### ACCEPT tcp  --  10.1.1.1       0.0.0.0/0

            ### LOG  all  --  0.0.0.0/0  0.0.0.0/0  LOG flags 0 level 4 prefix `DROP '
            ### LOG  all  --  127.0.0.2  0.0.0.0/0  LOG flags 0 level 4

            if ($line =~ m|^\s*(\S+)\s+(\S+)\s+\-\-\s+(\S+)\s+(\S+)\s*(.*)|) {
                $rule{'target'}   = $1;
                $rule{'protocol'} = $rule{'proto'} = $2;
                $rule{'src'}      = $3;
                $rule{'dst'}      = $4;
                $rule{'extended'} = $5;
                if ($rule{'extended'}
                        and ($rule{'protocol'} eq 'tcp'
                        or $rule{'protocol'} eq 'udp')) {
                    my $s_port  = '0:0';  ### any to any
                    my $d_port  = '0:0';
                    if ($rule{'extended'} =~ /dpts?:(\S+)/) {
                        $d_port = $1;
                    }
                    if ($rule{'extended'} =~ /spts?:(\S+)/) {
                        $s_port = $1;
                    }
                    $rule{'s_port'} = $rule{'sport'} = $s_port;
                    $rule{'d_port'} = $rule{'dport'} = $d_port;
                }
            } else {
                $rule{'raw'} = $line;
            }
        }
        push @chain, \%rule;
    }
    return \@chain;
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
### FIXME -v for interfaces?
        eval {
            open IPT, "$iptables -t $table -n -L $chain |"
                or croak "[*] Could not execute $iptables -t $table -n -L $chain";
            @ipt_lines = <IPT>;
            close IPT;
        };
    }

    return '[-] Could not get iptables output!', 0
        unless @ipt_lines;

    my %protocols = ();
    my $found_chain = 0;
    my $rule_ctr = 1;
    my $prefix;
    my $policy = 'ACCEPT';
    my $any_ip_re = '(?:0\.){3}0/0';

    LINE: for my $line (@ipt_lines) {
        chomp $line;

        last if ($found_chain and $line =~ /^\s*Chain\s+/);

        ### Chain INPUT (policy DROP)
        ### Chain FORWARD (policy ACCEPT)
        if ($line =~ /^\s*Chain\s+$chain\s+\(policy\s+(\w+)\)/) {
            $policy = $1;
            $found_chain = 1;
        }
        next LINE if $line =~ /^\s*target\s/i;
        next LINE unless $found_chain;

        ### include ULOG target as well
        if ($line =~ m|^\s*U?LOG\s+(\w+)\s+\-\-\s+.*
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
        } elsif ($policy eq 'ACCEPT' and $line =~ m|^DROP\s+(\w+)\s+\-\-\s+.*
            $any_ip_re\s+$any_ip_re\s*$|x) {
            ### DROP    all  --  0.0.0.0/0     0.0.0.0/0
            $protocols{$1}{'DROP'} = $rule_ctr;
        }
        $rule_ctr++;
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
            open IPT, "$iptables -t $table -n -L |"
                or croak "[*] Could not execute $iptables -t $table -n -L";
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

        if ($line =~ m|^\s*U?LOG\s+(\w+)\s+\-\-\s+.*$any_ip_re
                \s+$any_ip_re\s+.*U?LOG|x) {
            ### the above regex allows the limit target to be used
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
