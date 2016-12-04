#!/usr/bin/perl -w

use lib (qw|../lib ../../IPTables-Parse/lib ../../IPTables-Parse.git/lib|);
use Data::Dumper;
use Getopt::Long 'GetOptions';
use strict;

eval {
    require IPTables::ChainMgr;
};
die "[*] Adjust 'use lib' statement to include ",
    "directory where modules live: $@" if $@;

#==================== config =====================
my $iptables_bin  = '/sbin/iptables';
my $ip6tables_bin = '/sbin/ip6tables';
my $fw_cmd_bin    = '/bin/firewall-cmd';

my %test_chains = (
    'filter' => [
        {'chain' => 'CHAINMGR', 'jump_from' => 'INPUT'},
        {'chain' => 'CHAINMGR', 'jump_from' => 'FORWARD'},
        ### iptables allows odd chain names
        {'chain' => 'SC~!@#^%&$*-[]+={}-test', 'jump_from' => 'INPUT'}
    ],
    'mangle' => [
        {'chain' => 'CHAINMGR', 'jump_from' => 'INPUT'},
        {'chain' => 'CHAINMGR', 'jump_from' => 'FORWARD'},
        {'chain' => 'SC~!@#^%&$*-[]+={}-test', 'jump_from' => 'INPUT'}
    ],
    'raw' => [
        {'chain' => 'CHAINMGR', 'jump_from' => 'PREROUTING'},
    ],
    'nat' => [
        {'chain' => 'CHAINMGR', 'jump_from' => 'PREROUTING'},
    ],
);

### normalization will produce the correct network addresses ("10.1.2.3/24" is
### deliberate)
my $ipv4_src = '10.1.2.3/24';
my $ipv4_dst = '192.168.1.2';
my $ipv6_src = 'fe80::200:f8ff:fe21:67cf';
my $ipv6_dst = '0000:0000:00AA:0000:0000:AA00:0000:0001/64';

my $mac_source = 'ff:ff:ff:c6:33:58';

my $logfile   = 'test.log';
my $PRINT_LEN = 68;
my $chain_past_end = 1000;
#================== end config ===================
#

my $exit_on_first_failure = 0;
my $verbose = 0;
my $debug   = 0;
my $help    = 0;

die "[*] See '$0 -h' for usage information" unless (GetOptions(
    'verbose' => \$verbose,
    'exit-on-first-failure' => \$exit_on_first_failure,
    'debug'   => \$debug,
    'help'    => \$help,
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

my %iptables_chains = (
    'mangle' => [qw/PREROUTING INPUT OUTPUT FORWARD POSTROUTING/],
    'raw'    => [qw/PREROUTING OUTPUT/],
    'filter' => [qw/INPUT OUTPUT FORWARD/],
    'nat'    => [qw/PREROUTING OUTPUT POSTROUTING/]
);

my %ip6tables_chains = (
    'mangle' => [qw/PREROUTING INPUT OUTPUT FORWARD POSTROUTING/],
    'raw'    => [qw/PREROUTING OUTPUT/],
    'filter' => [qw/INPUT OUTPUT FORWARD/],
);

my $passed = 0;
my $failed = 0;
my $executed = 0;

&init();

&iptables_tests();
&ip6tables_tests();

&logr("\n[+] passed/failed/executed: $passed/$failed/$executed tests\n\n");

exit 0;

sub iptables_tests() {

    &logr("\n[+] Running $iptables_bin tests...\n");

    my $ipt_obj = IPTables::ChainMgr->new(%ipt_opts)
        or die "[*] Could not acquire IPTables::ChainMgr object";

    ### built-in chains
    &chain_exists_tests($ipt_obj, \%iptables_chains);

    &test_cycle($ipt_obj);

    return;
}

sub ip6tables_tests() {

    &logr("\n[+] Running $ip6tables_bin tests...\n");

    my $ipt_obj = IPTables::ChainMgr->new(%ipt6_opts)
        or die "[*] Could not acquire IPTables::ChainMgr object";

    ### built-in chains
    &chain_exists_tests($ipt_obj, \%ip6tables_chains);

    &test_cycle($ipt_obj);

    return;
}

sub test_cycle() {
    my $ipt_obj = shift;

    for my $table (keys %test_chains) {
        for my $hr (@{$test_chains{$table}}) {
            my $chain = $hr->{'chain'};
            my $jump_from_chain = $hr->{'jump_from'};

            &custom_chain_init($ipt_obj, $table,
                $jump_from_chain, $chain);

            ### create/delete chain cycle
            &chain_does_not_exist_test($ipt_obj, $table, $chain);
            &create_chain_test($ipt_obj, $table, $chain);
            &flush_chain_test($ipt_obj, $table, $chain);
            &delete_chain_test($ipt_obj, $table, $jump_from_chain,
                $chain);

            ### create chain, add rules, delete chain cycle
            &chain_does_not_exist_test($ipt_obj, $table, $chain);
            &create_chain_test($ipt_obj, $table, $chain);
            &add_rules_tests($ipt_obj, $table, $chain);
            &flush_chain_test($ipt_obj, $table, $chain);
            &delete_chain_test($ipt_obj, $table, $jump_from_chain,
                $chain);

            ### create chain add rules, add jump rule, delete chain cycle
            &chain_does_not_exist_test($ipt_obj, $table, $chain);
            &create_chain_test($ipt_obj, $table, $chain);
            &add_rules_tests($ipt_obj, $table, $chain);
            &add_extended_rules_tests($ipt_obj, $table, $chain);
            &add_jump_rule_test($ipt_obj, $table, $chain, $jump_from_chain);
            &flush_chain_test($ipt_obj, $table, $chain);
            &set_chain_policy_test($ipt_obj, $table, $chain);
            &delete_chain_test($ipt_obj, $table, $jump_from_chain,
                $chain);
        }
    }
    return;
}

sub chain_exists_tests() {
    my ($ipt_obj, $tables_chains_hr) = @_;

    for my $table (keys %$tables_chains_hr) {
        for my $chain (@{$tables_chains_hr->{$table}}) {
            &dots_print("chain_exists(): $table $chain");

            my ($rv, $out_ar, $err_ar) = $ipt_obj->chain_exists($table, $chain);

            &pass_fail($rv, "   $table chain $chain does not exist.");
        }
    }

    return;
}

sub flush_chain_test() {
    my ($ipt_obj, $table, $chain) = @_;

    &dots_print("flush_chain(): $table $chain");

    my ($rv, $out_ar, $err_ar) = $ipt_obj->flush_chain($table, $chain);
    &pass_fail($rv, "   Could not flush $table $chain chain.");

    return;
}

sub set_chain_policy_test() {
    my ($ipt_obj, $table, $chain) = @_;

    for my $target (qw/DROP ACCEPT/) {
        &dots_print("cannot set chain policy: $table $chain $target");

        my ($rv, $out_ar, $err_ar) = $ipt_obj->set_chain_policy($table,
            $chain, $target);

        if ($rv) {  ### bad, cannot set policy for a non built-in chain
            $rv = 0;
        } else {
            $rv = 1;
        }

        &pass_fail($rv, "   Was able to set $table $chain chain " .
            "policy to $target, should only be able to do this for built-in chains.");
    }

    return;
}

sub add_jump_rule_test() {
    my ($ipt_obj, $table, $chain, $jump_from_chain) = @_;

    &dots_print("add_jump_rule(): $table $jump_from_chain -> $chain ");
    my ($rv, $out_ar, $err_ar) = $ipt_obj->add_jump_rule($table,
        $jump_from_chain, 1, $chain);

    &pass_fail($rv, "   Could not add jump rule.");

    my $ip_any_net = '0.0.0.0/0';
    $ip_any_net = '::/0' if $ipt_obj->{'_ipv6'};

    &dots_print("find jump rule: $table $jump_from_chain -> $chain ");

    my ($rule_position, $num_chain_rules) = $ipt_obj->find_ip_rule($ip_any_net,
            $ip_any_net, $table, $jump_from_chain, $chain, {});

    &pass_fail($rule_position, "   Could not find jump rule.");

    return;
}

sub add_rules_tests() {
    my ($ipt_obj, $table, $chain) = @_;

    my $src_ip = $ipt_obj->normalize_net($ipv4_src);
    my $dst_ip = $ipt_obj->normalize_net($ipv4_dst);

    if ($ipt_obj->{'_ipv6'}) {
        $src_ip = $ipt_obj->normalize_net($ipv6_src);
        $dst_ip = $ipt_obj->normalize_net($ipv6_dst);
    }

    for my $target (qw/LOG ACCEPT RETURN/) {
        &dots_print("add_ip_rule(): $table $chain $src_ip -> $dst_ip $target ");
        my ($rv, $out_ar, $err_ar) = $ipt_obj->add_ip_rule($src_ip,
                $dst_ip, $chain_past_end, $table, $chain, $target, {});

        &pass_fail($rv, "   Could not add $src_ip -> $dst_ip $target rule.");

        &dots_print("find rule: $table $chain $src_ip -> $dst_ip $target ");
        my ($rule_position, $num_chain_rules) = $ipt_obj->find_ip_rule($src_ip,
                $dst_ip, $table, $chain, $target, {'normalize' => 1});

        &pass_fail($rule_position, "   Could not find $src_ip -> $dst_ip $target rule.");
    }

    for my $target (qw/LOG ACCEPT RETURN/) {
        &dots_print("append_ip_rule(): $table $chain $src_ip -> $dst_ip $target ");
        my ($rv, $out_ar, $err_ar) = $ipt_obj->add_ip_rule($src_ip,
                $dst_ip, -1, $table, $chain, $target, {});

        &pass_fail($rv, "   Could not append $src_ip -> $dst_ip $target rule.");

        &dots_print("find rule: $table $chain $src_ip -> $dst_ip $target ");
        my ($rule_position, $num_chain_rules) = $ipt_obj->find_ip_rule($src_ip,
                $dst_ip, $table, $chain, $target, {'normalize' => 1});

        &pass_fail($rule_position, "   Could not find $src_ip -> $dst_ip $target rule.");
    }

    return;
}

sub add_extended_rules_tests() {
    my ($ipt_obj, $table, $chain) = @_;

    ### for any -> any testing
    my $ip_any_net = '0.0.0.0/0';
    $ip_any_net = '::/0' if $ipt_obj->{'_ipv6'};

    my $src_ip = $ipt_obj->normalize_net($ipv4_src);
    my $dst_ip = $ipt_obj->normalize_net($ipv4_dst);

    if ($ipt_obj->{'_ipv6'}) {
        $src_ip = $ipt_obj->normalize_net($ipv6_src);
        $dst_ip = $ipt_obj->normalize_net($ipv6_dst);
    }

    for my $target (qw/LOG ACCEPT RETURN/) {

        ### TCP
        &dots_print("add_ext_ip_rules(): $table $chain TCP $src_ip(0) -> $dst_ip(80) $target ");
        my ($rv, $out_ar, $err_ar) = $ipt_obj->add_ip_rule($src_ip,
                $dst_ip, $chain_past_end, $table, $chain, $target,
                {'protocol' => 'tcp', 's_port' => 0, 'd_port' => 80});
        &pass_fail($rv, "   Could not add TCP $src_ip(0) -> $dst_ip(80) $target rule");

        &dots_print("find ext rule: $table $chain TCP $src_ip(0) -> $dst_ip(80) $target ");
        my ($rule_position, $num_chain_rules) = $ipt_obj->find_ip_rule($src_ip,
                $dst_ip, $table, $chain, $target,
                {'normalize' => 1, 'protocol' => 'tcp', 's_port' => 0,
                'd_port' => 80});
        &pass_fail($rule_position, "   Could not find TCP $src_ip(0) -> $dst_ip(80) $target rule");

        ### TCP + state tracking
        &dots_print("add_ext_ip_rules(): $table $chain TCP $src_ip(0) " .
            "-> $dst_ip(80) state ESTABLISHED,RELATED $target ");
        ($rv, $out_ar, $err_ar) = $ipt_obj->add_ip_rule($src_ip,
                $dst_ip, $chain_past_end, $table, $chain, $target,
                {'protocol' => 'tcp', 's_port' => 0, 'd_port' => 80,
                'state' => 'ESTABLISHED,RELATED'});
        &pass_fail($rv, "   Could not add TCP $src_ip(0) -> $dst_ip(80) " .
            "state ESTABLISHED,RELATED $target rule");

        &dots_print("find ext rule: $table $chain TCP $src_ip(0) " .
            "-> $dst_ip(80) state ESTABLISHED,RELATED $target ");
        ($rule_position, $num_chain_rules) = $ipt_obj->find_ip_rule($src_ip,
                $dst_ip, $table, $chain, $target,
                {'normalize' => 1, 'protocol' => 'tcp', 's_port' => 0,
                'd_port' => 80, 'state' => 'ESTABLISHED,RELATED'});
        &pass_fail($rule_position, "   Could not find TCP $src_ip(0) -> " .
            "$dst_ip(80) state ESTABLISHED,RELATED $target rule");

        ### TCP + ctstate tracking
        &dots_print("add_ext_ip_rules(): $table $chain TCP " .
            "$src_ip(0) -> $dst_ip(80) ctstate ESTABLISHED,RELATED $target ");
        ($rv, $out_ar, $err_ar) = $ipt_obj->add_ip_rule($src_ip,
                $dst_ip, $chain_past_end, $table, $chain, $target,
                {'protocol' => 'tcp', 's_port' => 0, 'd_port' => 80,
                'ctstate' => 'ESTABLISHED,RELATED'});
        &pass_fail($rv, "   Could not add TCP $src_ip(0) -> $dst_ip(80) " .
            "ctstate ESTABLISHED,RELATED $target rule");

        &dots_print("find ext rule: $table $chain TCP $src_ip(0) " .
            "-> $dst_ip(80) ctstate ESTABLISHED,RELATED $target ");
        ($rule_position, $num_chain_rules) = $ipt_obj->find_ip_rule($src_ip,
                $dst_ip, $table, $chain, $target,
                {'normalize' => 1, 'protocol' => 'tcp', 's_port' => 0,
                'd_port' => 80, 'ctstate' => 'ESTABLISHED,RELATED'});
        &pass_fail($rule_position, "   Could not find TCP $src_ip(0) -> " .
            "$dst_ip(80) ctstate ESTABLISHED,RELATED $target rule");

        ### all protocols and IP's, MAC source
        &dots_print("add_ext_ip_rules(): $table $chain $ip_any_net " .
            "-> $ip_any_net $target mac_source $mac_source ");
        ($rv, $out_ar, $err_ar) = $ipt_obj->add_ip_rule($ip_any_net,
                $ip_any_net, $chain_past_end, $table, $chain, $target,
                {'mac_source' => $mac_source});
        &pass_fail($rv, "   Could not add $ip_any_net -> $ip_any_net " .
            "$target mac_source $mac_source");

        &dots_print("find ext rule: $table $chain $ip_any_net " .
            "-> $ip_any_net $target mac_source $mac_source ");
        ($rule_position, $num_chain_rules) = $ipt_obj->find_ip_rule($ip_any_net,
                $ip_any_net, $table, $chain, $target,
                {'mac_source' => $mac_source});
        &pass_fail($rule_position, "   Could not find $ip_any_net " .
                "-> $ip_any_net $target mac_source $mac_source");

        ### TCP + mac source
        &dots_print("add_ext_ip_rules(): $table $chain TCP " .
            "$src_ip(0) -> $dst_ip(80) $target mac_source $mac_source ");
        ($rv, $out_ar, $err_ar) = $ipt_obj->add_ip_rule($src_ip,
                $dst_ip, $chain_past_end, $table, $chain, $target,
                {'protocol' => 'tcp', 's_port' => 0, 'd_port' => 80,
                'mac_source' => $mac_source});
        &pass_fail($rv, "   Could not add TCP $src_ip(0) -> $dst_ip(80) " .
            "$target mac_source $mac_source");

        &dots_print("find ext rule: $table $chain TCP $src_ip(0) " .
            "-> $dst_ip(80) $target mac_source $mac_source ");
        ($rule_position, $num_chain_rules) = $ipt_obj->find_ip_rule($src_ip,
                $dst_ip, $table, $chain, $target,
                {'protocol' => 'tcp', 's_port' => 0, 'd_port' => 80,
                'mac_source' => $mac_source});
        &pass_fail($rule_position, "   Could not find TCP $src_ip(0) " .
                "-> $dst_ip(80) $target mac_source $mac_source");

        ### TCP + comment
        &dots_print("add_ext_ip_rules(): $table $chain TCP " .
            "$src_ip(0) -> $dst_ip(80) $target comment 'test comment' ");
        ($rv, $out_ar, $err_ar) = $ipt_obj->add_ip_rule($src_ip,
                $dst_ip, $chain_past_end, $table, $chain, $target,
                {'protocol' => 'tcp', 's_port' => 0, 'd_port' => 80,
                'comment' => 'test comment'});
        &pass_fail($rv, "   Could not add TCP $src_ip(0) -> " .
            "$dst_ip(80) $target comment 'test comment'");

        &dots_print("find ext rule: $table $chain TCP " .
            "$src_ip(0) -> $dst_ip(80) $target comment 'test comment' ");
        ($rule_position, $num_chain_rules) = $ipt_obj->find_ip_rule($src_ip,
                $dst_ip, $table, $chain, $target,
                {'protocol' => 'tcp', 's_port' => 0, 'd_port' => 80,
                'comment' => 'test comment'});
        &pass_fail($rule_position, "   Could not find TCP $src_ip(0) " .
                "-> $dst_ip(80) $target comment 'test comment'");

        ### TCP + comment + string match
        &dots_print("add_ext_ip_rules(): $table $chain TCP " .
                "$src_ip(0) -> $dst_ip(80) $target comment 'test comment' string 'search str'");
        ($rv, $out_ar, $err_ar) = $ipt_obj->add_ip_rule($src_ip,
                $dst_ip, $chain_past_end, $table, $chain, $target,
                {'protocol' => 'tcp', 's_port' => 0, 'd_port' => 80,
                'comment' => 'test comment', 'string' => 'search str'});
        &pass_fail($rv, "   Could not add TCP $src_ip(0) -> $dst_ip(80) " .
                "$target comment 'test comment' string 'search str'");

        &dots_print("find ext rule: $table $chain TCP " .
                "$src_ip(0) -> $dst_ip(80) $target comment 'test comment' string 'search str' ");
        ($rule_position, $num_chain_rules) = $ipt_obj->find_ip_rule($src_ip,
                $dst_ip, $table, $chain, $target,
                {'protocol' => 'tcp', 's_port' => 0, 'd_port' => 80, 'comment' => 'test comment',
                'string' => 'search str'});
        &pass_fail($rule_position, "   Could not find TCP $src_ip(0) -> " .
            "$dst_ip(80) $target comment 'test comment' 'string' => 'search str'");

        ### UDP
        &dots_print("add_ext_ip_rules(): $table $chain " .
            "UDP $src_ip(0) -> $dst_ip(53) $target ");
        ($rv, $out_ar, $err_ar) = $ipt_obj->add_ip_rule($src_ip,
                $dst_ip, $chain_past_end, $table, $chain, $target,
                {'protocol' => 'udp', 's_port' => 0, 'd_port' => 53});
        &pass_fail($rv, "   Could not add UDP $src_ip(0) -> $dst_ip(53) $target rule");

        &dots_print("find ext rule: $table $chain " .
                "UDP $src_ip(0) -> $dst_ip(53) $target ");
        ($rule_position, $num_chain_rules) = $ipt_obj->find_ip_rule($src_ip,
                $dst_ip, $table, $chain, $target,
                {'normalize' => 1, 'protocol' => 'udp', 's_port' => 0,
                'd_port' => 53});
        &pass_fail($rule_position, "   Could not find UDP " .
            "$src_ip(0) -> $dst_ip(53) $target rule");

        ### UDP length
        &dots_print("add_ext_ip_rules(): $table $chain " .
                "UDP $src_ip(0) -> $dst_ip(53) $target length 10:100 ");
        ($rv, $out_ar, $err_ar) = $ipt_obj->add_ip_rule($src_ip,
                $dst_ip, $chain_past_end, $table, $chain, $target,
                {'protocol' => 'udp', 's_port' => 0, 'd_port' => 53,
                'length' => '10:100'});
        &pass_fail($rv, "   Could not add UDP $src_ip(0) -> " .
                "$dst_ip(53) $target length 10:100 rule");

        &dots_print("find ext rule: $table $chain " .
                "UDP $src_ip(0) -> $dst_ip(53) $target ");
        ($rule_position, $num_chain_rules) = $ipt_obj->find_ip_rule($src_ip,
                $dst_ip, $table, $chain, $target,
                {'normalize' => 1, 'protocol' => 'udp', 's_port' => 0,
                'd_port' => 53, 'length' => '10:100'});
        &pass_fail($rule_position, "   Could not find UDP " .
                "$src_ip(0) -> $dst_ip(53) $target  length 10:100 rule");

    }

    return;
}

sub create_chain_test() {
    my ($ipt_obj, $table, $chain) = @_;

    &dots_print("create_chain(): $table $chain");

    my ($rv, $out_ar, $err_ar) = $ipt_obj->create_chain($table, $chain);

    &pass_fail($rv, "   Could not create $table $chain chain");
    die "[*] FATAL" unless $rv;

    return;
}

sub chain_does_not_exist_test() {
    my ($ipt_obj, $table, $chain) = @_;

    &dots_print("!chain_exists(): $table $chain");

    my ($rv, $out_ar, $err_ar) = $ipt_obj->chain_exists($table, $chain);

    if ($rv) {
        $rv = 0;
    } else {
        $rv = 1;
    }
    &pass_fail(++$rv, "   Chain exists.");
    die "[*] FATAL" unless $rv;

    return;
}

sub custom_chain_init() {
    my ($ipt_obj, $table, $jump_from_chain, $chain) = @_;

    my ($rv, $out_ar, $err_ar) = $ipt_obj->chain_exists($table,
            $chain);
    if ($rv) {
        $ipt_obj->delete_chain($table, $jump_from_chain, $chain);
    }
    return;
}

sub delete_chain_test() {
    my ($ipt_obj, $table, $jump_from_chain, $chain) = @_;

    &dots_print("delete_chain(): $table $chain");

    my ($rv, $out_ar, $err_ar) = $ipt_obj->delete_chain($table,
        $jump_from_chain, $chain);

    &pass_fail($rv, "   Could not delete chain.");
    die "[*] FATAL" unless $rv;

    return;
}

sub dots_print() {
    my $msg = shift;
    &logr($msg);
    my $dots = '';
    for (my $i=length($msg); $i < $PRINT_LEN; $i++) {
        $dots .= '.';
    }
    if ($dots) {
        &logr($dots);
    } else {
        &logr(' ') unless $msg =~ /\s$/;
    }
    return;
}

sub pass_fail() {
    my ($rv, $fail_msg) = @_;

    $executed++;

    if ($rv) {
        &logr("pass ($executed)\n");
        $passed++;
    } else {
        &logr("fail ($executed)\n");
        &logr("$fail_msg\n");
        $failed++;
        exit $rv if $exit_on_first_failure;
    }

    return;
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
            "UID 0 account) to effectively test IPTables::ChainMgr";

    unlink $logfile if -e $logfile;

    for my $bin ($iptables_bin, $ip6tables_bin) {
        die "[*] $bin does not exist" unless -e $bin;
        die "[*] $bin not executable" unless -x $bin;
    }

    return;
}

sub usage() {
    print "$0 [--debug] [--verbose] [-h]\n";
    exit 0;
}
