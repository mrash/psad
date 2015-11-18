#
##################################################################
#
# File: IPTables::Parse.pm
#
# Purpose: Perl interface to parse iptables and ip6tables rulesets.
#
# Author: Michael Rash (mbr@cipherdyne.org)
#
# Version: 1.6.1
#
##################################################################
#

package IPTables::Parse;

use 5.006;
use POSIX ":sys_wait_h";
use Carp;
use File::Temp;
use strict;
use warnings;
use vars qw($VERSION);

$VERSION = '1.6.1';

sub new() {
    my $class = shift;
    my %args  = @_;

    my $ipt_bin    = '/sbin/iptables';
    my $ipt6_bin   = '/sbin/ip6tables';
    my $fwc_bin    = '/usr/bin/firewall-cmd';
    my $iptout_pat = 'ipt.out.XXXXXX';
    my $ipterr_pat = 'ipt.err.XXXXXX';

    my $self = {
        _iptables        => $args{'iptables'}     || $args{'ip6tables'} || '',
        _firewall_cmd    => $args{'firewall-cmd'} || '',
        _fwd_args        => $args{'fwd_args'}     || '--direct --passthrough ipv4',
        _ipv6            => $args{'use_ipv6'}     || 0,
        _iptout          => $args{'iptout'}       || '',
        _iptout_pat      => $args{'iptout_pat'}   || '',
        _ipterr          => $args{'ipterr'}       || '',
        _ipterr_pat      => $args{'ipterr_pat'}   || '',
        _tmpdir          => $args{'tmpdir'}       || '',
        _ipt_alarm       => $args{'ipt_alarm'}    || 30,
        _debug           => $args{'debug'}        || 0,
        _verbose         => $args{'verbose'}      || 0,
        _ipt_rules_file  => $args{'ipt_rules_file'}  || '',
        _ipt_exec_style  => $args{'ipt_exec_style'}  || 'waitpid',
        _ipt_exec_sleep  => $args{'ipt_exec_sleep'}  || 0,
        _sigchld_handler => $args{'sigchld_handler'} || \&REAPER,
        _skip_ipt_exec_check => $args{'skip_ipt_exec_check'} || 0,
        _lockless_ipt_exec   => $args{'lockless_ipt_exec'}   || 0,
    };

    if ($self->{'_skip_ipt_exec_check'}) {
        unless ($self->{'_firewall_cmd'} or $self->{'_iptables'}) {
            ### default
            $self->{'_iptables'} = $ipt_bin;
        }
    } else {
        if ($self->{'_firewall_cmd'}) {
            croak "[*] $self->{'_firewall_cmd'} incorrect path.\n"
                unless -e $self->{'_firewall_cmd'};
            croak "[*] $self->{'_firewall_cmd'} not executable.\n"
                unless -x $self->{'_firewall_cmd'};
        } elsif ($self->{'_iptables'}) {
            croak "[*] $self->{'_iptables'} incorrect path.\n"
                unless -e $self->{'_iptables'};
            croak "[*] $self->{'_iptables'} not executable.\n"
                unless -x $self->{'_iptables'};
        } else {
            ### check for firewall-cmd first since systems with it
            ### will have iptables installed as well (but firewall-cmd
            ### should be used instead if it exists)
            if (-e $fwc_bin and -x $fwc_bin) {
                $self->{'_firewall_cmd'} = $fwc_bin;
            } elsif (-e $ipt_bin and -x $ipt_bin) {
                $self->{'_iptables'} = $ipt_bin;
            } elsif (-e $ipt6_bin and -x $ipt6_bin) {
                $self->{'_iptables'} = $ipt6_bin;
            } else {
                croak "[*] Could not find/execute iptables, " .
                    "specify path via 'iptables' key.\n";
            }
        }
    }

    if ($self->{'_ipv6'} and $self->{'_iptables'} eq $ipt_bin) {
        if (-e $ipt6_bin and -x $ipt6_bin) {
            $self->{'_iptables'} = $ipt6_bin;
        } else {
            croak "[*] Could not find/execute ip6tables, " .
                "specify path via 'ip6tables' key.\n";
        }
    }

    ### set up the path for temporary files
    if ($self->{'_tmpdir'} and -d $self->{'_tmpdir'}) {
        if ($self->{'_iptout_pat'}) {
            $self->{'_iptout'}
                = mktemp("$self->{'_tmpdir'}/$self->{'_iptout_pat'}");
        } elsif ($self->{'_iptout'}) {
            $self->{'_iptout'} = mktemp("$self->{'_tmpdir'}/$self->{'_iptout'}");
        } else {
            $self->{'_iptout'} = mktemp("$self->{'_tmpdir'}/$iptout_pat");
        }
        if ($self->{'_ipterr_pat'}) {
            $self->{'_ipterr'}
                = mktemp("$self->{'_tmpdir'}/$self->{'_iptout_pat'}");
        } elsif ($self->{'_ipterr'}) {
            $self->{'_ipterr'} = mktemp("$self->{'_tmpdir'}/$self->{'_ipterr'}");
        } else {
            $self->{'_ipterr'} = mktemp("$self->{'_tmpdir'}/$ipterr_pat");
        }
    } else {
        croak "[*] 'iptout_pat' is only valid with 'tmpdir' set."
            if $self->{'_iptout_pat'};
        croak "[*] 'ipterr_pat' is only valid with 'tmpdir' set."
            if $self->{'_iptout_err'};
        $self->{'_iptout'} = mktemp("/tmp/$iptout_pat")
            unless $self->{'_iptout'};
        $self->{'_ipterr'} = mktemp("/tmp/$ipterr_pat")
            unless $self->{'_ipterr'};
    }

    ### set the firewall binary name
    $self->{'_ipt_bin_name'} = 'iptables';
    if ($self->{'_firewall_cmd'}) {
        $self->{'_ipt_bin_name'} = $1 if $self->{'_firewall_cmd'} =~ m|.*/(\S+)|;
    } else {
        $self->{'_ipt_bin_name'} = $1 if $self->{'_iptables'} =~ m|.*/(\S+)|;
    }

    ### handle ipv6
    if ($self->{'_ipv6'}) {
        if ($self->{'_firewall_cmd'}) {
            if ($self->{'_fwd_args'} =~ /ipv4/i) {
                $self->{'_fwd_args'} = '--direct --passthrough ipv6';
            }
        } else {
            if ($self->{'_ipt_bin_name'} eq 'iptables') {
                unless ($self->{'_skip_ipt_exec_check'}) {
                    croak "[*] use_ipv6 is true, " .
                        "but $self->{'_iptables'} not ip6tables.\n";
                }
            }
        }
    }

    $self->{'_ipv6'} = 1 if $self->{'_ipt_bin_name'} eq 'ip6tables';
    if ($self->{'_firewall_cmd'}) {
        $self->{'_ipv6'} = 1 if $self->{'_fwd_args'} =~ /ipv6/;
    }

    ### set the main command string to allow for iptables execution
    ### via firewall-cmd if necessary
    $self->{'_cmd'} = $self->{'_iptables'};
    if ($self->{'_firewall_cmd'}) {
        $self->{'_cmd'} = "$self->{'_firewall_cmd'} $self->{'_fwd_args'}";
    }

    unless ($self->{'_skip_ipt_exec_check'}) {
        unless ($self->{'_lockless_ipt_exec'}) {
            ### now that we have the iptables command defined, see whether
            ### it supports -w to acquire an exclusive lock
            my ($rv, $out_ar, $err_ar) = &exec_iptables($self,
                "$self->{'_cmd'} -w -t filter -n -L INPUT");
            $self->{'_cmd'} .= ' -w' if $rv;
        }
    }

    $self->{'parse_keys'} = &parse_keys();

    bless $self, $class;
}

sub DESTROY {
    my $self = shift;

    ### clean up tmp files
    unless ($self->{'_debug'}) {
        unlink $self->{'_iptout'};
        unlink $self->{'_ipterr'};
    }

    return;
}

sub parse_keys() {
    my $self = shift;

    ### only used for IPv4 + NAT
    my $ipv4_re = qr|(?:[0-2]?\d{1,2}\.){3}[0-2]?\d{1,2}|;

    my %keys = (
        'regular' => {
            'packets'  => {
                'regex'     => '',
                'ipt_match' => ''
            },
            'bytes'    => {
                'regex'     => '',
                'ipt_match' => ''
            },
            'target'   => {
                'regex'     => '',
                'ipt_match' => ''
            },
            'protocol' => {
                'regex'     => '',
                'ipt_match' => '-p'
            },
            'proto'    => {
                'regex'     => '',
                'ipt_match' => '-p'
            },
            'intf_in'  => {
                'regex'     => '',
                'ipt_match' => '-i'
            },
            'intf_out' => {
                'regex'     => '',
                'ipt_match' => '-o'
            },
            'src'      => {
                'regex'     => '',
                'ipt_match' => '-s'
            },
            'dst'      => {
                'regex'     => '',
                'ipt_match' => '-d'
            }
        },
        'extended' => {
            's_port' => {
                'regex'     => qr/\bspts?:(\S+)/,
                'ipt_match' => '--sport'
            },
            'sport' => {
                'regex'     => qr/\bspts?:(\S+)/,
                'ipt_match' => '--sport'
            },
            'd_port' => {
                'regex'     => qr/\bdpts?:(\S+)/,
                'ipt_match' => '--dport'
            },
            'dport' => {
                'regex'     => qr/\bdpts?:(\S+)/,
                'ipt_match' => '--dport'
            },
            'to_ip' => {
                'regex'     => qr/\bto:($ipv4_re):\d+/,
                'ipt_match' => ''
            },
            'to_port' => {
                'regex'     => qr/\bto:$ipv4_re:(\d+)/,
                'ipt_match' => ''
            },
            'mac_source' => {
                'regex'     => qr/\bMAC\s+(\S+)/,
                'ipt_match' => '-m mac --mac-source'
            },
            'state' => {
                'regex'     => qr/\bstate\s+(\S+)/,
                'ipt_match' => '-m state --state'
            },
            'ctstate' => {
                'regex'     => qr/\bctstate\s+(\S+)/,
                'ipt_match' => '-m conntrack --ctstate'
            },
            'comment' => {
                'regex'      => qr|\/\*\s(.*?)\s\*\/|,
                'ipt_match'  => '-m comment --comment',
                'use_quotes' => 1
            },
            'string' => {
                'regex'      => qr|STRING\s+match\s+\"(.*?)\"|,
                'ipt_match'  => '-m string --algo bm --string',
                'use_quotes' => 1
            },
            'length' => {
                'regex'      => qr|\blength\s(\S+)|,
                'ipt_match'  => '-m length --length',
            },
        },
        'rule_num' => '',
        'raw' => ''
    );

    return \%keys;
}

sub list_table_chains() {
    my $self   = shift;
    my $table  = shift || croak '[*] Specify a table, e.g. "nat"';
    my $file   = shift || '';

    my @ipt_lines = ();
    my @chains = ();

    if ($self->{'_ipt_rules_file'} and not $file) {
        $file = $self->{'_ipt_rules_file'};
    }

    if ($file) {
        ### read the iptables rules out of $file instead of executing
        ### the iptables command.
        open F, "< $file" or croak "[*] Could not open file $file: $!";
        @ipt_lines = <F>;
        close F;
    } else {
        my ($rv, $out_ar, $err_ar) = $self->exec_iptables(
                "$self->{'_cmd'} -t $table -v -n -L");
        @ipt_lines = @$out_ar;
    }

    for (@ipt_lines) {
        if (/^\s*Chain\s(.*?)\s\(/) {
            push @chains, $1;
        }
    }
    return \@chains;
}

sub chain_policy() {
    my $self   = shift;
    my $table  = shift || croak '[*] Specify a table, e.g. "nat"';
    my $chain  = shift || croak '[*] Specify a chain, e.g. "OUTPUT"';
    my $file   = shift || '';

    my @ipt_lines = ();

    if ($self->{'_ipt_rules_file'} and not $file) {
        $file = $self->{'_ipt_rules_file'};
    }

    if ($file) {
        ### read the iptables rules out of $file instead of executing
        ### the iptables command.
        open F, "< $file" or croak "[*] Could not open file $file: $!";
        @ipt_lines = <F>;
        close F;
    } else {
        my ($rv, $out_ar, $err_ar) = $self->exec_iptables(
                "$self->{'_cmd'} -t $table -v -n -L $chain");
        @ipt_lines = @$out_ar;
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

    my $found_chain  = 0;
    my @ipt_lines = ();

    my $fh = *STDERR;
    $fh = *STDOUT if $self->{'_verbose'};

    ### only used for IPv4 + NAT
    my $ip_re = qr|(?:[0-2]?\d{1,2}\.){3}[0-2]?\d{1,2}|;

    ### array of hash refs
    my @chain = ();
    my @global_accept_state = ();

    if ($self->{'_ipt_rules_file'} and not $file) {
        $file = $self->{'_ipt_rules_file'};
    }

    if ($file) {
        ### read the iptables rules out of $file instead of executing
        ### the iptables command.
        open F, "< $file" or croak "[*] Could not open file $file: $!";
        @ipt_lines = <F>;
        close F;
    } else {
        my ($rv, $out_ar, $err_ar) = $self->exec_iptables(
                "$self->{'_cmd'} -t $table -v -n -L $chain --line-numbers");
        @ipt_lines = @$out_ar;
    }

    ### determine the output style (e.g. "-nL -v" or just plain "-nL"; if the
    ### policy data came from a file then -v might not have been used)
    my $ipt_verbose = 0;
    for my $line (@ipt_lines) {
        if ($line =~ /\spkts\s+bytes\s+target/) {
            $ipt_verbose = 1;
            last;
        }
    }
    my $has_line_numbers = 0;
    for my $line (@ipt_lines) {
        if ($line =~ /^num\s+pkts\s+bytes\s+target/) {
            $has_line_numbers = 1;
            last;
        }
    }

    my $rule_num = 0;

    LINE: for my $line (@ipt_lines) {
        chomp $line;

        last LINE if ($found_chain and $line =~ /^\s*Chain\s+/);

        if ($line =~ /^\s*Chain\s\Q$chain\E\s\(/i) {
            $found_chain = 1;
            next LINE;
        }
        next LINE if $line =~ /\starget\s{2,}prot/i;
        next LINE unless $found_chain;
        next LINE unless $line;

        ### track the rule number independently of --line-numbers,
        ### but the values should always match
        $rule_num++;

        ### initialize hash
        my %rule = (
            'extended' => '',
            'raw'      => $line,
            'rule_num' => $rule_num
        );
        for my $key (keys %{$self->{'parse_keys'}->{'regular'}}) {
            $rule{$key} = '';
        }
        for my $key (keys %{$self->{'parse_keys'}->{'extended'}}) {
            $rule{$key} = '';
        }

        my $rule_body = '';
        my $packets   = '';
        my $bytes     = '';
        my $rnum      = '';

        if ($ipt_verbose) {
            if ($has_line_numbers) {
                if ($line =~ /^\s*(\d+)\s+(\S+)\s+(\S+)\s+(.*)/) {
                    $rnum      = $1;
                    $packets   = $2;
                    $bytes     = $3;
                    $rule_body = $4;
                }
            } else {
                if ($line =~ /^\s*(\S+)\s+(\S+)\s+(.*)/) {
                    $packets   = $1;
                    $bytes     = $2;
                    $rule_body = $3;
                }
            }
        } else {
            if ($has_line_numbers) {
                if ($line =~ /^\s*(\d+)\s+(.*)/) {
                    $rnum      = $1;
                    $rule_body = $2;
                }
            } else {
                $rule_body = $line;
                $rnum      = $rule_num;
                $rnum      = $rule_num;
            }
        }

        if ($rnum and $rnum ne $rule_num) {
            croak "[*] Rule number mis-match.";
        }

        if ($ipt_verbose) {

            ### iptables:
            ### 0     0 ACCEPT  tcp  --  eth1 * 192.168.10.3  0.0.0.0/0  tcp dpt:80
            ### 0     0 ACCEPT  tcp  --  eth1 * 192.168.10.15 0.0.0.0/0  tcp dpt:22
            ### 33 2348 ACCEPT  tcp  --  eth1 * 192.168.10.2  0.0.0.0/0  tcp dpt:22
            ### 0     0 ACCEPT  tcp  --  eth1 * 192.168.10.2  0.0.0.0/0  tcp dpt:80
            ### 0     0 DNAT    tcp  --  *    * 123.123.123.123 0.0.0.0/0 tcp dpt:55000 to:192.168.12.12:80

            ### ip6tables:
            ### 0     0 ACCEPT  tcp   *   *   ::/0     fe80::aa:0:1/128    tcp dpt:12345
            ### 0     0 LOG     all   *   *   ::/0     ::/0                LOG flags 0 level 4

            my $match_re = qr/^(\S+)\s+(\S+)\s+\-\-\s+
                                (\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s*(.*)/x;

            if ($self->{'_ipt_bin_name'} eq 'ip6tables'
                    or ($self->{'_ipt_bin_name'} eq 'firewall-cmd'
                    and $self->{'_fwd_args'} =~ /\sipv6/)) {
                $match_re = qr/^(\S+)\s+(\S+)\s+
                                (\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s*(.*)/x;
            }

            if ($rule_body =~ $match_re) {
                $rule{'packets'}  = $packets;
                $rule{'bytes'}    = $bytes;
                $rule{'target'}   = $1;
                my $proto = $2;
                $proto = 'all' if $proto eq '0';
                $rule{'protocol'} = $rule{'proto'} = lc($proto);
                $rule{'intf_in'}  = $3;
                $rule{'intf_out'} = $4;
                $rule{'src'}      = $5;
                $rule{'dst'}      = $6;
                $rule{'extended'} = $7 || '';

                &parse_rule_extended(\%rule, $self->{'parse_keys'}->{'extended'});
            } else {
                if ($self->{'_debug'}) {
                    print $fh localtime() . "     -v Did not match parse regex: $line\n";
                }
            }
        } else {

            ### iptables:
            ### ACCEPT tcp  -- 164.109.8.0/24  0.0.0.0/0  tcp dpt:22 flags:0x16/0x02
            ### ACCEPT tcp  -- 216.109.125.67  0.0.0.0/0  tcp dpts:7000:7500
            ### ACCEPT udp  -- 0.0.0.0/0       0.0.0.0/0  udp dpts:7000:7500
            ### ACCEPT udp  -- 0.0.0.0/0       0.0.0.0/0  udp dpt:!7000
            ### ACCEPT icmp --  0.0.0.0/0      0.0.0.0/0
            ### ACCEPT tcp  --  0.0.0.0/0      0.0.0.0/0  tcp spt:35000 dpt:5000
            ### ACCEPT tcp  --  10.1.1.1       0.0.0.0/0

            ### LOG  all  --  0.0.0.0/0  0.0.0.0/0  LOG flags 0 level 4 prefix `DROP '
            ### LOG  all  --  127.0.0.2  0.0.0.0/0  LOG flags 0 level 4
            ### DNAT tcp  --  123.123.123.123  0.0.0.0/0  tcp dpt:55000 to:192.168.12.12:80

            ### ip6tables:
            ### ACCEPT     tcp   ::/0     fe80::aa:0:1/128    tcp dpt:12345
            ### LOG        all   ::/0     ::/0                LOG flags 0 level 4

            my $match_re = qr/^(\S+)\s+(\S+)\s+\-\-\s+(\S+)\s+(\S+)\s*(.*)/;

            if ($self->{'_ipt_bin_name'} eq 'ip6tables'
                    or ($self->{'_ipt_bin_name'} eq 'firewall-cmd'
                    and $self->{'_fwd_args'} =~ /\sipv6/)) {
                $match_re = qr/^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s*(.*)/;
            }

            if ($rule_body =~ $match_re) {
                $rule{'target'}   = $1;
                my $proto = $2;
                $proto = 'all' if $proto eq '0';
                $rule{'protocol'} = $rule{'proto'} = lc($proto);
                $rule{'src'}      = $3;
                $rule{'dst'}      = $4;
                $rule{'extended'} = $5 || '';

                &parse_rule_extended(\%rule, $self->{'parse_keys'}->{'extended'});
            } else {
                if ($self->{'_debug'}) {
                    print $fh localtime() . "     Did not match parse regex: $line\n";
                }
            }
        }
        push @chain, \%rule;
    }
    return \@chain;
}

sub parse_rule_extended() {
    my ($rule_hr, $ext_keys_hr) = @_;

    for my $key (keys %$ext_keys_hr) {
        if ($rule_hr->{'extended'}
                =~ /$ext_keys_hr->{$key}->{'regex'}/) {
            $rule_hr->{$key} = $1;
        }
    }

    if ($rule_hr->{'protocol'} eq '0') {
        $rule_hr->{'s_port'} = $rule_hr->{'sport'} = 0;
        $rule_hr->{'d_port'} = $rule_hr->{'dport'} = 0;
    } elsif ($rule_hr->{'protocol'} eq 'tcp'
            or $rule_hr->{'protocol'} eq 'udp') {
        $rule_hr->{'s_port'} = $rule_hr->{'sport'} = 0
            if $rule_hr->{'s_port'} eq '';
        $rule_hr->{'d_port'} = $rule_hr->{'dport'} = 0
            if $rule_hr->{'d_port'} eq '';
    }

    return;
}

sub default_drop() {
    my $self  = shift;
    my $table = shift || croak "[*] Specify a table, e.g. \"nat\"";
    my $chain = shift || croak "[*] Specify a chain, e.g. \"OUTPUT\"";
    my $file  = shift || '';

    my @ipt_lines = ();

    if ($self->{'_ipt_rules_file'} and not $file) {
        $file = $self->{'_ipt_rules_file'};
    }

    if ($file) {
        ### read the iptables rules out of $file instead of executing
        ### the iptables command.
        open F, "< $file" or croak "[*] Could not open file $file: $!";
        @ipt_lines = <F>;
        close F;
    } else {
### FIXME -v for interfaces?
        my ($rv, $out_ar, $err_ar) = $self->exec_iptables(
                "$self->{'_cmd'} -t $table -n -L $chain");
        @ipt_lines = @$out_ar;
    }

    return "[-] Could not get $self->{'_ipt_bin_name'} output!", 0
        unless @ipt_lines;

    my %protocols = ();
    my $found_chain = 0;
    my $found_default_drop = 0;
    my $rule_ctr = 1;
    my $prefix;
    my $policy = 'ACCEPT';
    my $any_ip_re = qr/(?:0\.){3}0\x2f0|\x3a{2}\x2f0/;

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
        my $log_re = qr/^\s*U?LOG\s+(\w+)\s+\-\-\s+.*
                $any_ip_re\s+$any_ip_re\s+(.*)/x;
        my $drop_re = qr/^DROP\s+(\w+)\s+\-\-\s+.*
            $any_ip_re\s+$any_ip_re\s*$/x;

        if ($self->{'_ipt_bin_name'} eq 'ip6tables'
                or ($self->{'_ipt_bin_name'} eq 'firewall-cmd'
                and $self->{'_fwd_args'} =~ /ipv6/)) {
            $log_re = qr/^\s*U?LOG\s+(\w+)\s+
                    $any_ip_re\s+$any_ip_re\s+(.*)/x;
            $drop_re = qr/^DROP\s+(\w+)\s+
                $any_ip_re\s+$any_ip_re\s*$/x;
        }

        ### might as well pick up any default logging rules as well
        if ($line =~ $log_re) {
            my $proto  = $1;
            my $p_tmp  = $2;
            my $prefix = 'NONE';

            ### some recent iptables versions return "0" instead of "all"
            ### for the protocol number
            $proto = 'all' if $proto eq '0';
            ### LOG flags 0 level 4 prefix `DROP '
            if ($p_tmp && $p_tmp =~ m|LOG.*\s+prefix\s+
                \`\s*(.+?)\s*\'|x) {
                $prefix = $1;
            }
            ### $proto may equal "all" here
            $protocols{$proto}{'LOG'}{'prefix'} = $prefix;
            $protocols{$proto}{'LOG'}{'rulenum'} = $rule_ctr;
        } elsif ($policy eq 'ACCEPT' and $line =~ $drop_re) {
            my $proto = $1;
            $proto = 'all' if $proto eq '0';
            ### DROP    all  --  0.0.0.0/0     0.0.0.0/0
            $protocols{$1}{'DROP'} = $rule_ctr;
            $found_default_drop = 1;
        }
        $rule_ctr++;
    }

    ### if the policy in the chain is DROP, then we don't
    ### necessarily need to find a default DROP rule.
    if ($policy eq 'DROP') {
        $protocols{'all'}{'DROP'} = 0;
        $found_default_drop = 1;
    }

    return "[-] There are no default drop rules in the " .
            "$self->{'_ipt_bin_name'} policy!", 0
        unless %protocols and $found_default_drop;

    return \%protocols, 1;
}

sub default_log() {
    my $self  = shift;
    my $table = shift || croak "[*] Specify a table, e.g. \"nat\"";
    my $chain = shift || croak "[*] Specify a chain, e.g. \"OUTPUT\"";
    my $file  = shift || '';

    my $any_ip_re  = qr/(?:0\.){3}0\x2f0|\x3a{2}\x2f0/;
    my @ipt_lines  = ();
    my %log_chains = ();
    my %log_rules  = ();

    if ($self->{'_ipt_rules_file'} and not $file) {
        $file = $self->{'_ipt_rules_file'};
    }

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
        my ($rv, $out_ar, $err_ar) = $self->exec_iptables(
                "$self->{'_cmd'} -t $table -n -L $chain");
        @ipt_lines = @$out_ar;
    }

    ### determine the output style (e.g. "-nL -v" or just plain "-nL"; if the
    ### policy data came from a file then -v might not have been used)
    my $ipt_verbose = 0;
    for my $line (@ipt_lines) {
        if ($line =~ /^\s*pkts\s+bytes\s+target/) {
            $ipt_verbose = 1;
            last;
        }
    }

    return "[-] Could not get $self->{'_ipt_bin_name'} output!", 0
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

        my $proto = '';
        my $found = 0;
        if ($ipt_verbose) {
            if ($self->{'_ipt_bin_name'} eq 'ip6tables'
                    or ($self->{'_ipt_bin_name'} eq 'firewall-cmd'
                    and $self->{'_fwd_args'} =~ /\sipv6/)) {
                if ($line =~ m|^\s*\d+\s+\d+\s*U?LOG\s+(\w+)\s+
                        \S+\s+\S+\s+$any_ip_re
                        \s+$any_ip_re\s+.*U?LOG|x) {
                    $proto = $1;
                    $found = 1;
                }
            } else {
                if ($line =~ m|^\s*\d+\s+\d+\s*U?LOG\s+(\w+)\s+\-\-\s+
                        \S+\s+\S+\s+$any_ip_re
                        \s+$any_ip_re\s+.*U?LOG|x) {
                    $proto = $1;
                    $found = 1;
                }
            }
        } else {
            if ($self->{'_ipt_bin_name'} eq 'ip6tables'
                    or ($self->{'_ipt_bin_name'} eq 'firewall-cmd'
                    and $self->{'_fwd_args'} =~ /\sipv6/)) {
                if ($line =~ m|^\s*U?LOG\s+(\w+)\s+$any_ip_re
                        \s+$any_ip_re\s+.*U?LOG|x) {
                    $proto = $1;
                    $found = 1;
                }
            } else {
                if ($line =~ m|^\s*U?LOG\s+(\w+)\s+\-\-\s+$any_ip_re
                        \s+$any_ip_re\s+.*U?LOG|x) {
                    $proto = $1;
                    $found = 1;
                }
            }
        }

        if ($found) {
            $proto = 'all' if $proto eq '0';
            ### the above regex allows the limit target to be used
            $log_chains{$log_chain}{$proto} = '';  ### protocol
            $log_rules{$proto} = '' if $log_chain eq $chain;
        }
    }

    return "[-] There are no default logging rules " .
        "in the $self->{'_ipt_bin_name'} policy!", 0 unless %log_chains;

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

    return \%log_rules, 1;
}

sub sub_chains() {
    my ($start_chain, $chains_hr, $ipt_lines_ar) = @_;
    my $found = 0;
    for my $line (@$ipt_lines_ar) {
        chomp $line;
        ### Chain INPUT (policy DROP)
        ### Chain fwsnort_INPUT_eth1 (1 references)
        if ($line =~ /^\s*Chain\s+\Q$start_chain\E\s+\(/ and
                $line !~ /0\s+references/) {
            $found = 1;
            next;
        }
        next unless $found;
        if ($found and $line =~ /^\s*Chain\s/) {
            last;
        }
        if ($line =~ m|^\s*(\S+)\s+\S+\s+|) {
            my $new_chain = $1;
            if ($new_chain ne 'LOG'
                    and $new_chain ne 'DROP'
                    and $new_chain ne 'REJECT'
                    and $new_chain ne 'ACCEPT'
                    and $new_chain ne 'RETURN'
                    and $new_chain ne 'QUEUE'
                    and $new_chain ne 'SNAT'
                    and $new_chain ne 'DNAT'
                    and $new_chain ne 'MASQUERADE'
                    and $new_chain ne 'pkts'
                    and $new_chain ne 'Chain'
                    and $new_chain ne 'target') {
                $chains_hr->{$new_chain} = '';
                &sub_chains($new_chain, $chains_hr, $ipt_lines_ar);
            }
        }
    }
    return;
}

sub exec_iptables() {
    my $self  = shift;
    my $cmd = shift || croak "[*] Must specify an " .
        "$self->{'_ipt_bin_name'} command to run.";
    my $iptout    = $self->{'_iptout'};
    my $ipterr    = $self->{'_ipterr'};
    my $debug     = $self->{'_debug'};
    my $ipt_alarm = $self->{'_ipt_alarm'};
    my $verbose   = $self->{'_verbose'};
    my $ipt_exec_style = $self->{'_ipt_exec_style'};
    my $ipt_exec_sleep = $self->{'_ipt_exec_sleep'};
    my $sigchld_handler = $self->{'_sigchld_handler'};

    croak "[*] $cmd does not look like an $self->{'_ipt_bin_name'} command."
        unless $cmd =~ m|^\s*iptables| or $cmd =~ m|^\S+/iptables|
            or $cmd =~ m|^\s*ip6tables| or $cmd =~ m|^\S+/ip6tables|
            or $cmd =~ m|^\s*firewall-cmd| or $cmd =~ m|^\S+/firewall-cmd|;

    ### sanitize $cmd - this is not bullet proof, but better than
    ### nothing (especially for strange iptables chain names). Further,
    ### quotemeta() is too aggressive since things like IPv6 addresses
    ### contain ":" chars, etc.
    $cmd =~ s/([;<>\$\|`\@&\(\)\[\]\{\}])/\\$1/g;

    my $rv = 1;
    my @stdout = ();
    my @stderr = ();

    my $fh = *STDERR;
    $fh = *STDOUT if $verbose;

    if ($debug or $verbose) {
        print $fh localtime() . " [+] IPTables::Parse::",
            "exec_iptables(${ipt_exec_style}()) $cmd\n";
        if ($ipt_exec_sleep > 0) {
            print $fh localtime() . " [+] IPTables::Parse::",
                "exec_iptables() sleep seconds: $ipt_exec_sleep\n";
        }
    }

    if ($ipt_exec_sleep > 0) {
        if ($debug or $verbose) {
            print $fh localtime() . " [+] IPTables::Parse: ",
                "sleeping for $ipt_exec_sleep seconds before ",
                "executing $self->{'_ipt_bin_name'} command.\n";
        }
        sleep $ipt_exec_sleep;
    }

    if ($ipt_exec_style eq 'system') {
        system qq{$cmd > $iptout 2> $ipterr};
    } elsif ($ipt_exec_style eq 'popen') {
        open CMD, "$cmd 2> $ipterr |" or croak "[*] Could not execute $cmd: $!";
        @stdout = <CMD>;
        close CMD;
        open F, "> $iptout" or croak "[*] Could not open $iptout: $!";
        print F for @stdout;
        close F;
    } else {
        my $ipt_pid;

        if ($debug or $verbose) {
            print $fh localtime() . " [+] IPTables::Parse: " .
                "Setting SIGCHLD handler to: " . $sigchld_handler . "\n";
        }

        local $SIG{'CHLD'} = $sigchld_handler;
        if ($ipt_pid = fork()) {
            eval {
                ### iptables should never take longer than 30 seconds to execute,
                ### unless there is some absolutely enormous policy or the kernel
                ### is exceedingly busy
                local $SIG{'ALRM'} = sub {die "[*] $self->{'_ipt_bin_name'} " .
                    "command timeout.\n"};
                alarm $ipt_alarm;
                waitpid($ipt_pid, 0);
                alarm 0;
            };
            if ($@) {
                kill 9, $ipt_pid unless kill 15, $ipt_pid;
            }
        } else {
            croak "[*] Could not fork $self->{'_ipt_bin_name'}: $!"
                unless defined $ipt_pid;

            ### exec the iptables command and preserve stdout and stderr
            exec qq{$cmd > $iptout 2> $ipterr};
        }
    }

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

    if (@stdout) {
        if ($stdout[$#stdout] =~ /^success/) {
            pop @stdout;
        }
        if ($self->{'_ipt_bin_name'} eq 'firewall-cmd') {
            for (@stdout) {
                if (/COMMAND_FAILED/) {
                    $rv = 0;
                    last;
                }
            }
        }
    }

    if ($debug or $verbose) {
        print $fh localtime() . "     $self->{'_ipt_bin_name'} " .
            "command stdout:\n";
        for my $line (@stdout) {
            if ($line =~ /\n$/) {
                print $fh $line;
            } else {
                print $fh $line, "\n";
            }
        }
        print $fh localtime() . "     $self->{'_ipt_bin_name'} " .
            "command stderr:\n";
        for my $line (@stderr) {
            if ($line =~ /\n$/) {
                print $fh $line;
            } else {
                print $fh $line, "\n";
            }
        }
    }

    if ($debug or $verbose) {
        print $fh localtime() . "     Return value: $rv\n";
    }

    return $rv, \@stdout, \@stderr;
}

sub REAPER {
    my $stiff;
    while(($stiff = waitpid(-1,WNOHANG))>0){
        # do something with $stiff if you want
    }
    local $SIG{'CHLD'} = \&REAPER;
    return;
}

1;
__END__

=encoding UTF-8

=head1 NAME

IPTables::Parse - Perl extension for parsing iptables and ip6tables policies

=head1 SYNOPSIS

  use IPTables::Parse;

  my %opts = (
      'use_ipv6' => 0,         # can set to 1 to force ip6tables usage
      'ipt_rules_file' => '',  # optional file path from
                               # which to read iptables rules
      'debug'    => 0,
      'verbose'  => 0
  );

  my $ipt_obj = IPTables::Parse->new(%opts)
      or die "[*] Could not acquire IPTables::Parse object";

  my $rv = 0;

  ### look for default DROP rules in the filter table INPUT chain
  my ($ipt_hr, $rv) = $ipt_obj->default_drop('filter', 'INPUT');
  if ($rv) {
      if (defined $ipt_hr->{'all'}) {
          print "The INPUT chain has a default DROP rule for all protocols.\n";
      } else {
          my $found = 0;
          for my $proto (qw/tcp udp icmp/) {
              if (defined $ipt_hr->{$proto}) {
                  print "The INPUT chain drops $proto by default.\n";
                  $found = 1;
              }
          }
          unless ($found) {
              print "The INPUT chain does not have any default DROP rule.\n";
          }
      }
  } else {
      print "[-] Could not parse $ipt_obj->{'_ipt_bin_name'} policy\n";
  }

  ### look for default LOG rules in the filter table INPUT chain
  ($ipt_hr, $rv) = $ipt_obj->default_log('filter', 'INPUT');
  if ($rv) {
      if (defined $ipt_hr->{'all'}) {
          print "The INPUT chain has a default LOG rule for all protocols.\n";
      } else {
          my $found = 0;
          for my $proto (qw/tcp udp icmp/) {
              if (defined $ipt_hr->{$proto}) {
                  print "The INPUT chain logs $proto by default.\n";
                  $found = 1;
              }
          }
          unless ($found) {
              print "The INPUT chain does not have any default LOG rule.\n";
          }
      }
  } else {
      print "[-] Could not parse $ipt_obj->{'_ipt_bin_name'} policy\n";
  }

  ### print all chains in the filter table
  for my $chain (@{$ipt_obj->list_table_chains('filter')}) {
      print $chain, "\n";
  }

=head1 DESCRIPTION

The C<IPTables::Parse> package provides an interface to parse iptables or
ip6tables rules on Linux systems through the direct execution of
iptables/ip6tables commands, or from parsing a file that contains an
iptables/ip6tables policy listing. Note that the 'firewalld' infrastructure on
Fedora21 is also supported through execution of the 'firewall-cmd' binary.
By default, the path to iptables is assumed to be '/sbin/iptables', but if the
firewall is 'firewalld', then the '/usr/bin/firewall-cmd' is used. Both of
these paths are configurable via the keys mentioned below.

With this module, you can get the current policy applied to a
table/chain, look for a specific user-defined chain, check for a default DROP
policy, or determine whether or not a default LOG rule exists. Also, you can
get a listing of all rules in a chain with each rule parsed into its own hash.

Note that if you initialize the IPTables::Parse object with the 'ipt_rules_file'
key, then all parsing routines will open the specified file for iptables rules
data. So, you can create this file with a command like
'iptables -t filter -nL -v > ipt.rules', and then initialize the object with
IPTables::Parse->new('ipt_rules_file' => 'ipt.rules'). Further, if you are
running on a system without iptables installed, but you have an iptables policy
written to the ipt.rules file, then you can pass in 'skip_ipt_exec_check=>1'
in order to analyze the file without having IPTables::Parse check for the
iptables binary.

In summary, in addition to the hash keys mentioned above, optional keys that
can be passed to new() include 'iptables' (set path to iptables binary),
'firewall_cmd' (set path to 'firewall-cmd' binary for systems with
'firewalld'), 'fwd_args' (set 'firewall-cmd' usage args; defaults to
'--direct --passthrough ipv4'), 'ipv6' (set IPv6 mode for ip6tables),
'iptout' (set path to temporary stdout file, defaults to /tmp/ipt.out.XXXXXX),
'iptout_pat' (set pattern for temporary stdout file in the 'tmpdir' directory),
'ipterr' (set path to temporary stderr file, defaults to /tmp/ipt.err.XXXXXX),
'iptout_err' (set pattern for temporary stderr file in the 'tmpdir' directory),
'tmpdir' (set path to temporary file handling directory),
'debug', 'verbose', and 'lockless_ipt_exec' (disable usage of the iptables
'-w' argument that acquires an exclusive lock on command execution).

=head1 FUNCTIONS

The IPTables::Parse extension provides an object interface to the following
functions:

=over 4

=item chain_policy($table, $chain)

This function returns the policy (e.g. 'DROP', 'ACCEPT', etc.) for the specified
table and chain:

  print "INPUT policy: ",
        $ipt_obj->chain_policy('filter', 'INPUT'), "\n";

=item chain_rules($table, $chain)

This function parses the specified chain and table and returns an array reference
for all rules in the chain.  Each element in the array reference is a hash with
the following keys (that contain values depending on the rule): C<src>, C<dst>,
C<protocol>, C<s_port>, C<d_port>, C<target>, C<packets>, C<bytes>, C<intf_in>,
C<intf_out>, C<to_ip>, C<to_port>, C<state>, C<raw>, and C<extended>.  The C<extended>
element contains the rule output past the protocol information, and the C<raw>
element contains the complete rule itself as reported by iptables or ip6tables.
Here is an example of checking whether the second rule in the INPUT chain (array
index 1) allows traffic from any IP to TCP port 80:

  $rules_ar = $ipt_obj->chain_rules('filter', 'INPUT);

  if ($rules_ar->[1]->{'src'} eq '0.0.0.0/0'
          and $rules_ar->[1]->{'protocol'} eq 'tcp'
          and $rules_ar->[1]->{'d_port'}   eq '80'
          and $rules_ar->[1]->{'target'}   eq 'ACCEPT') {

      print "traffic accepted to TCP port 80 from anywhere\n";
  }

=item default_drop($table, $chain)

This function parses the running iptables or ip6tables policy in order to
determine if the specified chain contains a default DROP rule.  Two values
are returned, a hash reference whose keys are the protocols that are dropped by
default (if a global ACCEPT rule has not accepted matching packets first), along
with a return value that tells the caller if parsing the iptables or ip6tables
policy was successful.  Note that if all protocols are dropped by default, then
the hash key 'all' will be defined.

  ($ipt_hr, $rv) = $ipt_obj->default_drop('filter', 'INPUT');

=item default_log($table, $chain)

This function parses the running iptables or ip6tables policy in order to determine if
the specified chain contains a default LOG rule.  Two values are returned,
a hash reference whose keys are the protocols that are logged by default
(if a global ACCEPT rule has not accepted matching packets first), along with
a return value that tells the caller if parsing the iptables or ip6tables policy was
successful.  Note that if all protocols are logged by default, then the
hash key 'all' will be defined.  An example invocation is:

  ($ipt_hr, $rv) = $ipt_obj->default_log('filter', 'INPUT');

=item list_table_chains($table)

This function parses the specified table for all chains that are defined within
the table. Data is returned as an array reference. For example, if there are no
user-defined chains in the 'filter' table, then the returned array reference will
contain the strings 'INPUT', 'FORWARD', and 'OUTPUT'.

  for my $chain (@{$ipt_obj->list_table_chains('filter')}) {
      print $chain, "\n";
  }

=back

=head1 AUTHOR

Michael Rash, E<lt>mbr@cipherdyne.orgE<gt>

=head1 SEE ALSO

The IPTables::Parse module is used by the IPTables::ChainMgr extension in support of
the psad and fwsnort projects to parse iptables or ip6tables policies (see the psad(8),
and fwsnort(8) man pages).  As always, the iptables(8) and ip6tables(8) man pages
provide the best information on command line execution and theory behind iptables
and ip6tables.

Although there is no mailing that is devoted specifically to the IPTables::Parse
extension, questions about the extension will be answered on the following
lists:

  The psad mailing list: http://lists.sourceforge.net/lists/listinfo/psad-discuss
  The fwsnort mailing list: http://lists.sourceforge.net/lists/listinfo/fwsnort-discuss

The latest version of the IPTables::Parse extension can be found on CPAN and
also here:

  http://www.cipherdyne.org/modules/

Source control is provided by git:

  https://github.com/mrash/IPTables-Parse.git

=head1 CREDITS

Thanks to the following people:

  Franck Joncourt <franck.mail@dthconnex.com>
  Stuart Schneider
  Grant Ferley
  Fabien Mazieres
  Miloslav Trmač

=head1 AUTHOR

The IPTables::Parse extension was written by Michael Rash F<E<lt>mbr@cipherdyne.orgE<gt>>
to support the psad and fwsnort projects.  Please send email to
this address if there are any questions, comments, or bug reports.

=head1 VERSION

Version 1.6.1 (November, 2015)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2015 Michael Rash.  All rights reserved.

This module is free software.  You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.  More information
can be found here: http://www.perl.com/perl/misc/Artistic.html

This program is distributed "as is" in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
