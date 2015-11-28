#!/usr/bin/perl -w

use lib '../lib';
use Data::Dumper;
use Getopt::Long 'GetOptions';
use strict;

require IPTables::Parse;

#==================== config =====================
my $iptables_bin    = '/sbin/iptables';
my $ip6tables_bin   = '/sbin/ip6tables';
my $fw_cmd_bin      = '/bin/firewall-cmd';
my $dummy_path      = '/bin/invalidpath';

my $logfile        = 'test.log';
my $ipt_rules_file = 'ipt_rules.tmp';
my $basic_ipv4_rules_file = 'basic_ipv4.rules';
my $PRINT_LEN = 68;
#================== end config ===================

my $test_include = '';
my @tests_to_include = ();
my $test_exclude = '';
my @tests_to_exclude = ();
my $verbose = 0;
my $debug   = 0;
my $help    = 0;
my $use_fw_cmd = 0;

die "[*] See '$0 -h' for usage information" unless (GetOptions(
    'test-include=s' => \@tests_to_include,
    'include=s'      => \@tests_to_include,  ### synonym
    'test-exclude=s' => \@tests_to_exclude,
    'exclude=s'      => \@tests_to_exclude,  ### synonym
    'verbose'        => \$verbose,
    'debug'          => \$debug,
    'help'           => \$help,
));
&usage() if $help;

my %ipt_opts = (
    'debug'    => $debug,
    'verbose'  => $verbose
);

my %ipt6_opts = (
    'use_ipv6' => 1,
    'debug'    => $debug,
    'verbose'  => $verbose
);

my %targets = (
    'ACCEPT' => '',
    'DROP'   => '',
    'QUEUE'  => '',
    'RETURN' => '',
);

my @iptables_chains = (
    { 'table'  => 'mangle',
      'chains' => [qw/PREROUTING INPUT OUTPUT FORWARD POSTROUTING/]},
    { 'table'  => 'raw',
      'chains' => [qw/PREROUTING OUTPUT/]},
    { 'table'  => 'filter',
      'chains' => [qw/INPUT OUTPUT FORWARD/]},
    { 'table'  => 'nat',
      'chains' => [qw/PREROUTING OUTPUT POSTROUTING/]},
);

my @ip6tables_chains = (
    { 'table'  => 'mangle',
      'chains' => [qw/PREROUTING INPUT OUTPUT FORWARD POSTROUTING/]},
    { 'table'  =>, 'raw',
      'chains' => [qw/PREROUTING OUTPUT/]},
    { 'table'  => 'filter',
      'chains' => [qw/INPUT OUTPUT FORWARD/]},
);

my $passed = 0;
my $failed = 0;
my $executed = 1;

my $SKIP_IPT_EXEC_CHECK = 1;
my $IPT_EXEC_CHECK = 0;

&init();

### main testing routines
&parse_basic_ipv4_policy();
&iptables_tests('', $IPT_EXEC_CHECK);
&iptables_tests($ipt_rules_file, $IPT_EXEC_CHECK);
&iptables_tests($ipt_rules_file, $SKIP_IPT_EXEC_CHECK);
&ip6tables_tests('', $IPT_EXEC_CHECK);
&ip6tables_tests($ipt_rules_file, $IPT_EXEC_CHECK);
&ip6tables_tests($ipt_rules_file, $SKIP_IPT_EXEC_CHECK);

&logr("\n[+] passed/failed/executed: $passed/$failed/$executed tests\n\n");

exit 0;

sub iptables_tests() {
    my ($rules_file, $skip_ipt_exec_check) = @_;

    if ($rules_file) {
        if ($skip_ipt_exec_check) {
            &logr("\n[+] Running $iptables_bin $rules_file " .
                "(skip ipt exec check) tests...\n");
        } else {
            &logr("\n[+] Running $iptables_bin $rules_file tests...\n");
        }
        $ipt_opts{'ipt_rules_file'} = $rules_file;
        if ($skip_ipt_exec_check == $SKIP_IPT_EXEC_CHECK) {
            $ipt_opts{'skip_ipt_exec_check'} = $skip_ipt_exec_check;
        }
    } else {
        &logr("\n[+] Running $iptables_bin tests...\n");
        $ipt_opts{'ipt_rules_file'} = '';
    }

    my $ipt_obj = IPTables::Parse->new(%ipt_opts)
        or die "[*] Could not acquire IPTables::Parse object";

    &chain_policy_tests($ipt_obj, \@iptables_chains);
    &chain_rules_tests($ipt_obj, \@iptables_chains);
    &default_log_tests($ipt_obj);
    &default_drop_tests($ipt_obj);

    return;
}

sub ip6tables_tests() {
    my ($rules_file, $skip_ipt_exec_check) = @_;

    if ($rules_file) {
        if ($skip_ipt_exec_check) {
            &logr("\n[+] Running $ip6tables_bin $rules_file " .
                "(skip ipt exec check) tests...\n");
        } else {
            &logr("\n[+] Running $ip6tables_bin $rules_file tests...\n");
        }
        $ipt_opts{'ipt_rules_file'} = $rules_file;
        if ($skip_ipt_exec_check == $SKIP_IPT_EXEC_CHECK) {
            $ipt_opts{'iptables'} = $dummy_path;
            $ipt_opts{'skip_ipt_exec_check'} = $skip_ipt_exec_check;
        }
    } else {
        &logr("\n[+] Running $ip6tables_bin tests...\n");
        $ipt_opts{'ipt_rules_file'} = '';
    }

    my $ipt_obj = IPTables::Parse->new(%ipt6_opts)
        or die "[*] Could not acquire IPTables::Parse object";

    &chain_policy_tests($ipt_obj, \@ip6tables_chains);
    &chain_rules_tests($ipt_obj, \@ip6tables_chains);
    &default_log_tests($ipt_obj);
    &default_drop_tests($ipt_obj);

    return;
}

sub default_log_tests() {
    my $ipt_obj = shift;

    for my $chain (qw/INPUT OUTPUT FORWARD/) {
        next unless &dots_print("default_log($ipt_obj->{'_ipt_rules_file'}): " .
            "filter $chain");

        if ($ipt_obj->{'_ipt_rules_file'}) {
            &write_rules($ipt_obj,
                "$ipt_obj->{'_cmd'} -t filter -v -n -L $chain");
        }

        my ($ipt_log, $rv) = $ipt_obj->default_log('filter', $chain);
        $executed++;
        if ($rv) {
            &logr("pass ($executed) (found)\n");
            $passed++;
        } else {
            &logr("fail ($executed) (not found)\n");
            $failed++;
        }
    }
    return;
}

sub default_drop_tests() {
    my $ipt_obj = shift;

    for my $chain (qw/INPUT OUTPUT FORWARD/) {
        next unless &dots_print("default_drop($ipt_obj->{'_ipt_rules_file'}): " .
            "filter $chain");

        if ($ipt_obj->{'_ipt_rules_file'}) {
            &write_rules($ipt_obj,
                "$ipt_obj->{'_cmd'} -t filter -v -n -L $chain");
        }

        my ($ipt_drop, $rv) = $ipt_obj->default_drop('filter', $chain);
        $executed++;
        if ($rv) {
            &logr("pass ($executed) (found)\n");
            $passed++;
        } else {
            &logr("fail ($executed) (not found)\n");
            $failed++;
        }
    }
    return;
}

sub chain_policy_tests() {
    my ($ipt_obj, $chains_ar) = @_;

    for my $hr (@$chains_ar) {
        my $table = $hr->{'table'};
        for my $chain (@{$hr->{'chains'}}) {

            next unless &dots_print(
                "chain_policy($ipt_obj->{'_ipt_rules_file'}): " .
                "$table $chain policy");

            if ($ipt_obj->{'_ipt_rules_file'}) {
                &write_rules($ipt_obj,
                    "$ipt_obj->{'_cmd'} -t $table -v -n -L $chain");
            }

            my $target = $ipt_obj->chain_policy($table, $chain);

            $executed++;

            if (defined $targets{$target}) {
                &logr("pass ($executed) ($target)\n");
                $passed++;
            } else {
                &logr("fail ($executed) ($target)\n");
                &logr("   Unrecognized target '$target'\n");
                $failed++;
            }
        }
    }

    return;
}

sub parse_basic_ipv4_policy() {

    return unless &dots_print("Basic IPv4 parse " .
        "$basic_ipv4_rules_file via chain_rules()");

    $ipt_opts{'ipt_rules_file'} = $basic_ipv4_rules_file;

    my $ipt_obj = IPTables::Parse->new(%ipt_opts)
        or die "[*] Could not acquire IPTables::Parse object";

    my $rules_ar = $ipt_obj->chain_rules('filter', 'INPUT');

    if ($#$rules_ar > -1) {
        &logr("pass ($executed)\n");
        $passed++;
    } else {
        &logr("fail ($executed)\n");
        $failed++;
    }
    $executed++;

    $ipt_opts{'ipt_rules_file'} = '';

    return;
}

sub chain_rules_tests() {
    my ($ipt_obj, $chains_ar) = @_;

    for my $hr (@$chains_ar) {

        my $table = $hr->{'table'};

        next unless &dots_print(
            "list_table_chains($ipt_obj->{'_ipt_rules_file'}): $table");

        if ($ipt_obj->{'_ipt_rules_file'}) {
            &write_rules($ipt_obj,
                "$ipt_obj->{'_cmd'} -t $table -v -n -L");
        }

        my $chains_ar = $ipt_obj->list_table_chains($table);
        if ($#$chains_ar > -1) {
            &logr("pass ($executed)\n");
            $passed++;
        } else {
            &logr("fail ($executed)\n");
            $failed++;
        }
        $executed++;

        for my $chain (@{$hr->{'chains'}}) {
            next unless &dots_print(
                "chain_rules($ipt_obj->{'_ipt_rules_file'}): " .
                "$table $chain rules");

            my $out_ar = &write_rules($ipt_obj,
                "$ipt_obj->{'_cmd'} -t $table -v -n -L $chain");

            if ($ipt_obj->{'_ipt_rules_file'}) {
            }

            my $rules_ar = $ipt_obj->chain_rules($table, $chain);

            $executed++;

            my $matched_state = 1;
            for (my $i=2; $i<=$#$out_ar; $i++) {
                if ($out_ar->[$i] =~ /\sctstate/) {
                    unless (defined $rules_ar->[$i-2]->{'ctstate'}
                            and $rules_ar->[$i-2]->{'ctstate'}) {
                        $matched_state = 0;
                        last;
                    }
                } elsif ($out_ar->[$i] =~ /\sstate/) {
                    unless (defined $rules_ar->[$i-2]->{'state'}
                            and $rules_ar->[$i-2]->{'state'}) {
                        $matched_state = 0;
                        last;
                    }
                }
            }

            ### compare raw rules list with parsed chain_rules()
            ### output - basic number check
            if (($#$out_ar - 2) == $#$rules_ar and $matched_state) {
                &logr("pass ($executed)\n");
                $passed++;
            } else {
                &logr("fail ($executed)\n");
                if ($matched_state) {
                    &logr("    chain_rules() missed extended state info.\n");
                } else {
                    if (($#$out_ar - 2) > $#$rules_ar) {
                        &logr("    chain_rules() missed rules.\n");
                    } elsif (($#$out_ar - 2) < $#$rules_ar) {
                        &logr("    chain_rules() added inappropriate rules.\n");
                    }
                }
                $failed++;
            }
        }
    }
    return;
}

sub dots_print() {
    my $msg = shift;

    return 0 unless &process_include_exclude($msg);

    &logr($msg);
    my $dots = '';
    for (my $i=length($msg); $i < $PRINT_LEN; $i++) {
        $dots .= '.';
    }
    &logr($dots);
    return 1;
}

sub process_include_exclude() {
    my $msg = shift;

    ### inclusions/exclusions
    if (@tests_to_include) {
        my $found = 0;
        for my $test (@tests_to_include) {
            if ($msg =~ qr/$test/) {
                $found = 1;
                last;
            }
        }
        return 0 unless $found;
    }
    if (@tests_to_exclude) {
        my $found = 0;
        for my $test (@tests_to_exclude) {
            if ($msg =~ qr/$test/) {
                $found = 1;
                last;
            }
        }
        return 0 if $found;
    }
    return 1;
}

sub logr() {
    my $msg = shift;
    print STDOUT $msg;
    open F, ">> $logfile" or die $!;
    print F $msg;
    close F;
    return;
}

sub init() {

    $|++; ### turn off buffering

    $< == 0 && $> == 0 or
        die "[*] $0: You must be root (or equivalent ",
            "UID 0 account) to effectively test fwknop";

    unlink $logfile if -e $logfile;
    unlink $ipt_rules_file if -e $ipt_rules_file;

    if (-e $fw_cmd_bin and -x $fw_cmd_bin) {
        $use_fw_cmd = 1;
    } else {
        for my $bin ($iptables_bin, $ip6tables_bin) {
            die "[*] $bin does not exist" unless -e $bin;
            die "[*] $bin not executable" unless -x $bin;
        }
    }

    return;
}

sub write_rules() {
    my ($ipt_obj, $cmd) = @_;

    my $rv = 0;
    my $out_ar = ();
    my $err_ar = ();

    ### if the original iptables object skipped the iptables exec
    ### check, then acquire a new object to execute the command
    if ($ipt_obj->{'_skip_ipt_exec_check'}) {
        my %opts_cp = %ipt_opts;

        if ($use_fw_cmd) {
            $cmd =~ s|^$dummy_path|$fw_cmd_bin|;
        } else {
            if ($ipt_obj->{'use_ipv6'}) {
                %opts_cp = %ipt6_opts;
                $cmd =~ s|^$dummy_path|$ip6tables_bin|;
            } else {
                $cmd =~ s|^$dummy_path|$iptables_bin|;
            }
        }
        $opts_cp{'skip_ipt_exec_check'} = 0;

        my $obj = IPTables::Parse->new(%opts_cp);
        ($rv, $out_ar, $err_ar) = $obj->exec_iptables($cmd);
    } else {
        ($rv, $out_ar, $err_ar) = $ipt_obj->exec_iptables($cmd);
    }

    &write_rules_file($out_ar);

    return $out_ar;
}

sub write_rules_file() {
    my $lines_ar = shift;
    open F, "> $ipt_rules_file" or die $!;
    print F $_ for @$lines_ar;
    close F;
    return;
}

sub usage() {
    print "$0 [--debug] [--verbose] [-h]\n";
    exit 0;
}
