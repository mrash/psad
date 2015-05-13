#!/usr/bin/perl -w

use Cwd;
use File::Copy;
use File::Path;
use Getopt::Long 'GetOptions';
use strict;

#==================== config =====================
my $logfile        = 'test.log';
my $output_dir     = 'output';
my $conf_dir       = 'conf';
my $run_dir        = 'run';
my $scans_dir      = 'scans';
my $test_install_dir = 'psad-install';
my $syn_scan_file  = 'syn_scan_1000_1500';
my $topera_syn_scan_file = 'topera_ipv6_syn_scan_no_ip_opts';
my $topera_syn_scan_with_opts_file = 'topera_ipv6_syn_scan_with_ip_opts';
my $fin_scan_file  = 'fin_scan_1000_1150';
my $xmas_scan_file = 'xmas_scan_1000_1150';
my $null_scan_file = 'null_scan_1000_1150';
my $ack_scan_file  = 'ack_scan_1000_1150';
my $udp_scan_file  = 'udp_scan_1000_1150';
my $proto_scan_file = 'proto_scan';
my $igmp_traffic_file = 'ipv4_igmp';
my $fwknop_pkt_file = 'fwknop_spa_pkt';
my $syslog_time_fmt1 = 'syslog_time_fmt1.log';
my $ms_sql_server_sig_match_file  = 'ms_sql_server_sig_match';
my $ipv6_ms_sql_server_sig_match_file  = 'ipv6_ms_sql_server_sig_match';
my $no_ms_sql_server_sig_match_file = "$conf_dir/signatures_no_ms_sql_server_sig";
my $ipv6_connect_scan_file  = 'ipv6_tcp_connect_nmap_default_scan';
my $ipv6_ping_scan_file = 'ipv6_ping_scan';
my $ipv6_invalid_icmp6_type_code_file = 'ipv6_invalid_icmp6_type_code';
my $ipv4_invalid_icmp6_type_code_file = 'invalid_icmp_type_code';
my $ipv4_valid_ping = 'ipv4_valid_ping';
my $ignore_ipv4_auto_dl_file = "$conf_dir/auto_dl_ignore_192.168.10.55";
my $ignore_ipv4_subnet_auto_dl_file = "$conf_dir/auto_dl_ignore_192.168.10.0_24";
my $ignore_ipv6_addr_auto_dl_file = "$conf_dir/auto_dl_ignore_ipv6_addr";
my $ignore_ipv6_addr_auto_dl_file_abbrev = "$conf_dir/auto_dl_ignore_ipv6_addr_abbrev";
my $dl5_ipv4_auto_dl_file = "$conf_dir/auto_dl_5_192.168.10.55";
my $dl5_ipv4_subnet_auto_dl_file = "$conf_dir/auto_dl_5_192.168.10.0_24";
my $dl5_ipv4_subnet_auto_dl_file_tcp = "$conf_dir/auto_dl_5_192.168.10.0_24_tcp";
my $dl5_ipv4_subnet_auto_dl_file_udp = "$conf_dir/auto_dl_5_192.168.10.0_24_udp";

my $psadCmd        = "$test_install_dir/usr/sbin/psad";

my $cmd_out_tmp    = 'cmd.out';
my $default_conf   = "$conf_dir/default_psad.conf";
my $ignore_udp_conf = "$conf_dir/ignore_udp.conf";
my $ignore_tcp_conf = "$conf_dir/ignore_tcp.conf";
my $ignore_igmp_conf = "$conf_dir/ignore_igmp.conf";
my $ignore_intf_conf = "$conf_dir/ignore_intf.conf";
my $auto_blocking_conf = "$conf_dir/auto_blocking.conf";
my $auto_dl5_blocking_conf = "$conf_dir/auto_min_dl5_blocking.conf";
my $require_prefix_conf = "$conf_dir/require_DROP_syslog_prefix_str.conf";
my $require_missing_prefix_conf = "$conf_dir/require_missing_syslog_prefix_str.conf";
my $enable_ack_detection_conf = "$conf_dir/enable_ack_detection.conf";
my $disable_ipv6_conf = "$conf_dir/disable_ipv6_detection.conf";
#================== end config ===================

my $YES = 1;
my $NO  = 0;
my $IGNORE = 2;
my $current_test_file = "$output_dir/init";
my $passed = 0;
my $failed = 0;
my $executed = 0;
my $test_include = '';
my @tests_to_include = ();
my $test_exclude = '';
my @tests_to_exclude = ();
my $list_mode = 0;
my $diff_mode = 0;
my $test_limit = 0;
my $saved_last_results = 0;
my $test_system_install = 0;
my $normal_root_override_str = '';
my $PRINT_LEN = 68;
my $REQUIRED = 1;
my $OPTIONAL = 0;
my $MATCH_ALL_RE = 1;
my $MATCH_SINGLE_RE = 2;
my $help = 0;
my $enable_auto_block_tests = 0;

my %test_keys = (
    'category'        => $REQUIRED,
    'subcategory'     => $OPTIONAL,
    'detail'          => $REQUIRED,
    'function'        => $REQUIRED,
    'cmdline'         => $OPTIONAL,
    'fatal'           => $OPTIONAL,
    'exec_err'        => $OPTIONAL,
    'match_all'       => $OPTIONAL,
    'auto_block_test' => $OPTIONAL,
    'postive_output_matches'  => $OPTIONAL,
    'negative_output_matches' => $OPTIONAL,
);

my @args_cp = @ARGV;

exit 1 unless GetOptions(
    'psad-path=s'         => \$psadCmd,
    'test-include=s'      => \@tests_to_include,
    'include=s'           => \@tests_to_include,  ### synonym
    'test-exclude=s'      => \@tests_to_exclude,
    'exclude=s'           => \@tests_to_exclude,  ### synonym
    'test-system-install' => \$test_system_install,
    'enable-auto-block-tests' => \$enable_auto_block_tests,
    'List-mode'           => \$list_mode,
    'diff'                => \$diff_mode,
    'test-limit=i'        => \$test_limit,
    'help'                => \$help
);

&usage() if $help;

if ($test_system_install) {
    $normal_root_override_str = "-O $conf_dir/normal_root_override.conf";
    $psadCmd = '/usr/sbin/psad';
}

### define all tests
my @tests = (
    {
        'category' => 'install',
        'detail'   => "test directory: $test_install_dir",
        'err_msg'  => 'could not install',
        'function' => \&install_test_dir,
        'cmdline'  => "./install.pl --install-test-dir --Use-answers " .
            "--answers-file test/install.answers",
        'exec_err' => $NO,
        'fatal'    => $YES
    },
    {
        'category' => 'compilation',
        'detail'   => 'psad compiles',
        'err_msg'  => 'could not compile',
        'function' => \&generic_exec,
        'cmdline'  => "perl -c $psadCmd",
        'exec_err' => $NO,
        'fatal'    => $YES
    },
    {
        'category' => 'operations',
        'detail'   => '--help',
        'err_msg'  => 'could not get --help output',
        'function' => \&generic_exec,
        'cmdline'  => "$psadCmd -h -c $default_conf $normal_root_override_str",
        'exec_err' => $NO,
        'fatal'    => $NO
    },
    {
        'category' => 'operations',
        'detail'   => 'config dump+validate',
        'err_msg'  => 'could not dump+validate config',
        'function' => \&validate_config,
        'cmdline'  => "$psadCmd --test-mode -D -c $default_conf $normal_root_override_str",
        'exec_err' => $NO,
        'fatal'    => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => '--fw-dump',
        'err_msg'   => 'could not dump fw policy',
        'positive_output_matches' => [qr/^Chain/, qr/pkts\sbytes\starget/,
                qr/\biptables\b/, qr/\bip6tables\b/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode --fw-dump -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => '--fw-list-auto',
        'err_msg'   => 'could not list auto fw policy',
        'positive_output_matches' => [qr/Listing\schains\sfrom\sIPT_AUTO_CHAIN/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode --fw-list-auto -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => '--fw-analyze',
        'err_msg'   => 'could not analyze fw policy',
        'positive_output_matches' => [qr/Parsing.*rules/, qr/Parsing.*rules/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode --fw-analyze -c $default_conf $normal_root_override_str",
        'exec_err'  => $IGNORE,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => '--Status',
        'err_msg'   => 'could not get psad status',
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -S -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => '--Status --status-summary',
        'err_msg'   => 'could not get psad status summary',
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -S --status-summary -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => '--get-next-rule-id',
        'err_msg'   => 'could not get next rule id',
        'positive_output_matches' => [qr/Next\savailable.*\s\d+/i],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode --get-next-rule-id -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => '--Benchmark --packets 1000',
        'err_msg'   => 'could not run psad in --Benchmark mode',
        'positive_output_matches' => [qr/Entering\sbenchmark\smode/, qr/processing\stime\:\s\d+/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode --Benchmark --packets 1000 -c $default_conf $normal_root_override_str",
        'exec_err'  => $IGNORE,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'IPv4 SYN scan detection',
        'err_msg'   => 'did not detect SYN scan',
        'positive_output_matches' => [qr/Top\s\d+\sattackers/i,
                qr/scanned\sports.*?1000\-1500\b/i,
                qr/Source\sOS/i, qr/BACKDOOR/i,
                qr/IP\sstatus/i,
                qr/192\.168\.10\.55/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data -m $scans_dir/" .
                &fw_type() . "/$syn_scan_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'IPv6 Topera SYN scan detection',
        'err_msg'   => 'did not detect SYN scan',
        'positive_output_matches' => [qr/Top\s\d+\sattackers/i,
                qr/scanned\sports.*?0\-1023\b/i,
                qr/BACKDOOR/i,
                qr/IP\sstatus/i,
                qr/SRC\:\s+2012\:1234\:1234\:0000\:0000\:0000\:0000\:0001/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data -m $scans_dir/" .
                &fw_type() . "/$topera_syn_scan_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'IPv6 Topera SYN scan detection (with IP opts)',
        'err_msg'   => 'did not detect SYN scan',
        'positive_output_matches' => [qr/Top\s\d+\sattackers/i,
                qr/scanned\sports.*?0\-1234\b/i,
                qr/BACKDOOR/i,
                qr/Topera\sIPv6\sscan/i,
                qr/IP\sstatus/i,
                qr/SRC\:\s+2012\:1234\:1234\:0000\:0000\:0000\:0000\:0001/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data -m $scans_dir/" .
                &fw_type() . "/$topera_syn_scan_with_opts_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },

    {
        'category'  => 'operations',
        'detail'    => 'IPv4 MS SQL Server communication attempt detection',
        'err_msg'   => 'did not detect MS SQL Server attempt',
        'positive_output_matches' => [qr/Top\s\d+\sattackers/i,
                qr/scanned\sports/i,
                qr/IP\sstatus/i,
                qr/SQL\sServer\scommunication/i,
                qr/192\.168\.10\.55/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data -m $scans_dir/" .
                &fw_type() . "/$ms_sql_server_sig_match_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'IPv6 MS SQL Server communication attempt detection',
        'err_msg'   => 'did not detect MS SQL Server attempt',
        'positive_output_matches' => [qr/Top\s\d+\sattackers/i,
                qr/scanned\sports/i,
                qr/IP\sstatus/i,
                qr/SQL\sServer\scommunication/i,
                qr/SRC\:.*2001\:DB8\:0\:F101\:\:2/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data -m $scans_dir/" .
                &fw_type() . "/$ipv6_ms_sql_server_sig_match_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'IPv4 exclude MS SQL Server sig match',
        'err_msg'   => 'logged MS SQL Server attempt',
        'negative_output_matches' => [
                qr/SQL\sServer\scommunication/i],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data -m $scans_dir/" .
                &fw_type() . "/$ms_sql_server_sig_match_file " .
                "--signatures $no_ms_sql_server_sig_match_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'IPv6 exclude MS SQL Server sig match',
        'err_msg'   => 'logged MS SQL Server attempt',
        'negative_output_matches' => [
                qr/SQL\sServer\scommunication/i],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data -m $scans_dir/" .
                &fw_type() . "/$ipv6_ms_sql_server_sig_match_file " .
                "--signatures $no_ms_sql_server_sig_match_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },

    {
        'category'  => 'operations',
        'detail'    => 'IPv4 FIN scan detection',
        'err_msg'   => 'did not detect FIN scan',
        'positive_output_matches' => [qr/Top\s\d+\sattackers/i,
                qr/scanned\sports.*?1000\-1150\b/i,
                qr/IP\sstatus/i,
                qr/SCAN\sFIN/i,
                qr/192\.168\.10\.55/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data -m $scans_dir/" .
                &fw_type() . "/$fin_scan_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'IPv4 XMAS scan detection',
        'err_msg'   => 'did not detect XMAS scan',
        'positive_output_matches' => [qr/Top\s\d+\sattackers/i,
                qr/scanned\sports.*?1000\-1150\b/i,
                qr/IP\sstatus/i,
                qr/SCAN\snmap\sXMAS/i,
                qr/192\.168\.10\.55/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data -m $scans_dir/" .
                &fw_type() . "/$xmas_scan_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'IPv4 NULL scan detection',
        'err_msg'   => 'did not detect NULL scan',
        'positive_output_matches' => [qr/Top\s\d+\sattackers/i,
                qr/scanned\sports.*?1000\-1150\b/i,
                qr/IP\sstatus/i,
                qr/192\.168\.10\.55/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data -m $scans_dir/" .
                &fw_type() . "/$null_scan_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'IPv4 IP protocol scan detection',
        'err_msg'   => 'did not detect protocol scan',
        'positive_output_matches' => [qr/Top\s\d+\sattackers/i,
                qr/IP\sprotocols\:\s251\,/i,
                qr/IP\sstatus/i,
                qr/192\.168\.10\.55/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data -m $scans_dir/" .
                &fw_type() . "/$proto_scan_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'IPv4 fwknop SPA packet detection',
        'err_msg'   => 'did not detect fwknop SPA packet',
        'positive_output_matches' => [qr/Top\s\d+\sattackers/i,
                qr/fwknop\sSingle\sPacket/i,
                qr/IP\sstatus/i,
                qr/192\.168\.10\.55/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data -m $scans_dir/" .
                &fw_type() . "/$fwknop_pkt_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'syslog time format (1)',
        'err_msg'   => 'did not parse syslog time format',
        'positive_output_matches' => [qr/syslog\shostname\:\sservername/,
                qr/timestamp\:\s2015\-03\-08T/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data -m $scans_dir/" .
                &fw_type() . "/$syslog_time_fmt1 -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },

    {
        'category'  => 'operations',
        'detail'    => 'IPv4 ACK scan detection',
        'err_msg'   => 'did not detect ACK scan',
        'positive_output_matches' => [qr/Top\s\d+\sattackers/i,
                qr/scanned\sports.*?1000\-1150\b/i,
                qr/IP\sstatus/i,
                qr/192\.168\.10\.55/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data -m $scans_dir/" .
                &fw_type() . "/$ack_scan_file -c $enable_ack_detection_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'IPv4 UDP scan detection',
        'err_msg'   => 'did not detect UDP scan',
        'positive_output_matches' => [qr/Top\s\d+\sattackers/i,
                qr/scanned\sports.*?1000\-1150/i,
                qr/IP\sstatus/i,
                qr/192\.168\.10\.55/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data -m $scans_dir/" .
                &fw_type() . "/$udp_scan_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },

    {
        'category'  => 'operations',
        'detail'    => 'DL5 IPv4 SYN scan source',
        'err_msg'   => 'did not set SYN scan source to DL5',
        'positive_output_matches' => [qr/Top\s\d+\sattackers/i,
                qr/scanned\sports.*?1000\-1500/i,
                qr/IP\sstatus/i,
                qr/192\.168\.10\.55,\sDL\:\s5/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data --auto-dl $dl5_ipv4_auto_dl_file " .
                "-m $scans_dir/" .  &fw_type() . "/$syn_scan_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'DL5 IPv4 SYN scan source subnet',
        'err_msg'   => 'did not set SYN scan source to DL5',
        'positive_output_matches' => [qr/Top\s\d+\sattackers/i,
                qr/scanned\sports.*?1000\-1500/i,
                qr/IP\sstatus/i,
                qr/192\.168\.10\.55,\sDL\:\s5/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data --auto-dl $dl5_ipv4_subnet_auto_dl_file " .
                "-m $scans_dir/" .  &fw_type() . "/$syn_scan_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'DL5 IPv4 SYN scan src subnet+tcp',
        'err_msg'   => 'did not set SYN scan source to DL5',
        'positive_output_matches' => [qr/Top\s\d+\sattackers/i,
                qr/scanned\sports.*?1000\-1500/i,
                qr/IP\sstatus/i,
                qr/192\.168\.10\.55,\sDL\:\s5/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data --auto-dl $dl5_ipv4_subnet_auto_dl_file_tcp " .
                "-m $scans_dir/" .  &fw_type() . "/$syn_scan_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'non-DL5 IPv4 SYN scan src subnet+udp',
        'err_msg'   => 'set SYN scan source to DL5',
        'negative_output_matches' => [qr/192\.168\.10\.55,\sDL\:\s5/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data --auto-dl $dl5_ipv4_subnet_auto_dl_file_udp " .
                "-m $scans_dir/" .  &fw_type() . "/$syn_scan_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },

    ### auto-blocking tests
    {
        'category'  => 'operations',
        'detail'    => 'DL5 IPv4 <BLOCK> SYN scan',
        'err_msg'   => 'did not block scan src',
        'positive_output_matches' => [qr/Top\s\d+\sattackers/i,
                qr/scanned\sports.*?1000\-1500/i,
                qr/IP\sstatus/i,
                qr/192\.168\.10\.55,\sDL\:\s5/,
                qr/DROP\s.*192\.168\.10\.55/,
                qr/Flushing\sand\sdeleting\spsad\schains/,
                qr/unlimited\stime/,
         ],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data --auto-dl $dl5_ipv4_auto_dl_file " .
                "-m $scans_dir/" .  &fw_type() . "/$syn_scan_file -c $auto_dl5_blocking_conf " .
                "$normal_root_override_str --analysis-auto-block",
        'auto_block_test' => $YES,
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'IPv4 <BLOCK> SYN scan',
        'err_msg'   => 'did not block scan src',
        'positive_output_matches' => [qr/Top\s\d+\sattackers/i,
                qr/scanned\sports.*?1000\-1500/i,
                qr/IP\sstatus/i,
                qr/192\.168\.10\.55,\sDL\:\s3/,
                qr/DROP\s.*192\.168\.10\.55/,
                qr/Flushing\sand\sdeleting\spsad\schains/,
                qr/for\s3\sseconds/,
                qr/removed\siptables\sblock/,
         ],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data " .
                "-m $scans_dir/" .  &fw_type() . "/$syn_scan_file -c $auto_blocking_conf " .
                "$normal_root_override_str --analysis-auto-block",
        'auto_block_test' => $YES,
        'exec_err'  => $NO,
        'fatal'     => $NO
    },

    {
        'category'  => 'operations',
        'detail'    => 'ignore src via --analysis-fields SRC:1.2.3.4',
        'err_msg'   => 'did not ignore SRC:1.2.3.4',
        'positive_output_matches' => [
            qr/Level 1\: 0 IP addresses/,
            qr/Level 2\: 0 IP addresses/,
            qr/Level 3\: 0 IP addresses/,
            qr/Level 4\: 0 IP addresses/,
            qr/Level 5\: 0 IP addresses/,
        ],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-fields SRC:1.2.3.4 " .
                "-m $scans_dir/" .  &fw_type() . "/$syn_scan_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'match src via --analysis-fields SRC:192.168.10.55',
        'err_msg'   => 'did not match SRC:192.168.10.55',
        'positive_output_matches' => [
            qr/Top\s\d+\sattackers/i,
            qr/scanned\sports.*?1000\-1500\b/i,
            qr/Source\sOS/i, qr/BACKDOOR/i,
            qr/IP\sstatus/i,
            qr/192\.168\.10\.55/
        ],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-fields SRC:192.168.10.55 " .
                "-m $scans_dir/" .  &fw_type() . "/$syn_scan_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'ignore src via --analysis-fields DST:1.2.3.4',
        'err_msg'   => 'did not ignore DST:1.2.3.4',
        'positive_output_matches' => [
            qr/Level 1\: 0 IP addresses/,
            qr/Level 2\: 0 IP addresses/,
            qr/Level 3\: 0 IP addresses/,
            qr/Level 4\: 0 IP addresses/,
            qr/Level 5\: 0 IP addresses/,
        ],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-fields DST:1.2.3.4 " .
                "-m $scans_dir/" .  &fw_type() . "/$syn_scan_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'match src via --analysis-fields DST:192.168.10.1',
        'err_msg'   => 'did not match DST:192.168.10.1',
        'positive_output_matches' => [
            qr/Top\s\d+\sattackers/i,
            qr/scanned\sports.*?1000\-1500\b/i,
            qr/Source\sOS/i, qr/BACKDOOR/i,
            qr/IP\sstatus/i,
            qr/192\.168\.10\.55/
        ],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-fields DST:192.168.10.1 " .
                "-m $scans_dir/" .  &fw_type() . "/$syn_scan_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => '--analysis-fields SRC:192.168.10.55, DST:192.168.10.1',
        'err_msg'   => 'did not match SRC:192.168.10.55, DST:192.168.10.1',
        'positive_output_matches' => [
            qr/Top\s\d+\sattackers/i,
            qr/scanned\sports.*?1000\-1500\b/i,
            qr/Source\sOS/i, qr/BACKDOOR/i,
            qr/IP\sstatus/i,
            qr/192\.168\.10\.55/
        ],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => qq|$psadCmd --test-mode -A --analysis-fields "SRC:192.168.10.55, DST:192.168.10.1" | .
                "-m $scans_dir/" .  &fw_type() . "/$syn_scan_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'ignore length via --analysis-fields LEN:15',
        'err_msg'   => 'did not ignore LEN:15',
        'positive_output_matches' => [
            qr/Level 1\: 0 IP addresses/,
            qr/Level 2\: 0 IP addresses/,
            qr/Level 3\: 0 IP addresses/,
            qr/Level 4\: 0 IP addresses/,
            qr/Level 5\: 0 IP addresses/,
        ],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-fields LEN:15 " .
                "-m $scans_dir/" .  &fw_type() . "/$syn_scan_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'match length via --analysis-fields LEN:44',
        'err_msg'   => 'did not match LEN:44',
        'positive_output_matches' => [
            qr/Top\s\d+\sattackers/i,
            qr/scanned\sports.*?1000\-1500\b/i,
            qr/Source\sOS/i, qr/BACKDOOR/i,
            qr/IP\sstatus/i,
            qr/192\.168\.10\.55/
        ],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-fields LEN:44 " .
                "-m $scans_dir/" .  &fw_type() . "/$syn_scan_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'invalid --analysis-fields BOGUS:44',
        'err_msg'   => 'allowed BOGUS:44',
        'positive_output_matches' => [
            qr/valid fields are/
        ],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-fields BOGUS:44 " .
                "-m $scans_dir/" .  &fw_type() . "/$syn_scan_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $YES,
        'fatal'     => $NO
    },

    {
        'category'  => 'operations',
        'detail'    => 'DL5 IPv4 UDP scan source',
        'err_msg'   => 'did not set UDP scan source to DL5',
        'positive_output_matches' => [qr/Top\s\d+\sattackers/i,
                qr/scanned\sports.*?1000\-1150/i,
                qr/IP\sstatus/i,
                qr/192\.168\.10\.55,\sDL\:\s5/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data --auto-dl $dl5_ipv4_auto_dl_file " .
                "-m $scans_dir/" .  &fw_type() . "/$udp_scan_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'DL5 IPv4 UDP scan source subnet',
        'err_msg'   => 'did not set UDP scan source to DL5',
        'positive_output_matches' => [qr/Top\s\d+\sattackers/i,
                qr/scanned\sports.*?1000\-1150/i,
                qr/IP\sstatus/i,
                qr/192\.168\.10\.55,\sDL\:\s5/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data --auto-dl $dl5_ipv4_subnet_auto_dl_file " .
                "-m $scans_dir/" .  &fw_type() . "/$udp_scan_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'DL5 IPv4 UDP scan src subnet+udp',
        'err_msg'   => 'did not set UDP scan source to DL5',
        'positive_output_matches' => [qr/Top\s\d+\sattackers/i,
                qr/scanned\sports.*?1000\-1150/i,
                qr/IP\sstatus/i,
                qr/192\.168\.10\.55,\sDL\:\s5/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data --auto-dl $dl5_ipv4_subnet_auto_dl_file_udp " .
                "-m $scans_dir/" .  &fw_type() . "/$udp_scan_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'non-DL5 IPv4 UDP scan src subnet+tcp',
        'err_msg'   => 'set UDP scan source to DL5',
        'negative_output_matches' => [qr/192\.168\.10\.55,\sDL\:\s5/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data --auto-dl $dl5_ipv4_subnet_auto_dl_file_tcp " .
                "-m $scans_dir/" .  &fw_type() . "/$udp_scan_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },

    {
        'category'  => 'operations',
        'detail'    => 'ignore IPv4 SYN scan source',
        'err_msg'   => 'did not ignore SYN scan',
        'negative_output_matches' => [qr/SRC\:\s+192\.168\.10\.55/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data --auto-dl $ignore_ipv4_auto_dl_file " .
                "-m $scans_dir/" .  &fw_type() . "/$syn_scan_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'ignore IPv4 SYN scan source subnet',
        'err_msg'   => 'did not ignore SYN scan',
        'negative_output_matches' => [qr/SRC\:\s+192\.168\.10\.55/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data --auto-dl $ignore_ipv4_subnet_auto_dl_file " .
                "-m $scans_dir/" .  &fw_type() . "/$syn_scan_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'psad.conf ignore IPv4 TCP traffic',
        'err_msg'   => 'did not ignore TCP traffic',
        'negative_output_matches' => [qr/SRC\:\s+192\.168\.10\.55/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data --auto-dl $dl5_ipv4_auto_dl_file " .  ### psad.conf IGNORE_PROTOCOLS trumps auto_dl
                "-m $scans_dir/" .  &fw_type() . "/$syn_scan_file -c $ignore_tcp_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'psad.conf ignore IPv4 IGMP traffic',
        'err_msg'   => 'did not ignore TCP traffic',
        'negative_output_matches' => [qr/SRC\:\s+192\.168\.10\.55/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data --auto-dl $dl5_ipv4_auto_dl_file " .  ### psad.conf IGNORE_PROTOCOLS trumps auto_dl
                "-m $scans_dir/" .  &fw_type() . "/$igmp_traffic_file -c $ignore_igmp_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'psad.conf ignore eth1 traffic',
        'err_msg'   => 'did not ignore eth1 traffic',
        'negative_output_matches' => [qr/SRC\:\s+192\.168\.10\.55/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data --auto-dl $dl5_ipv4_auto_dl_file " .
                "-m $scans_dir/" .  &fw_type() . "/$syn_scan_file -c $ignore_intf_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'psad.conf require DROP prefix',
        'err_msg'   => 'did not find DROP prefix logs',
        'positive_output_matches' => [qr/SRC\:\s+192\.168\.10\.55/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data --auto-dl $dl5_ipv4_auto_dl_file " .  ### psad.conf FW_MSG_SEARCH trumps auto_dl
                "-m $scans_dir/" .  &fw_type() . "/$syn_scan_file -c $require_prefix_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'psad.conf require missing DROP prefix',
        'err_msg'   => 'found DROP prefix logs',
        'negative_output_matches' => [qr/SRC\:\s+192\.168\.10\.55/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data --auto-dl $dl5_ipv4_auto_dl_file " .  ### psad.conf FW_MSG_SEARCH trumps auto_dl
                "-m $scans_dir/" .  &fw_type() . "/$syn_scan_file -c $require_missing_prefix_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },

    ### UDP
    {
        'category'  => 'operations',
        'detail'    => 'ignore IPv4 UDP scan source',
        'err_msg'   => 'did not ignore UDP scan',
        'negative_output_matches' => [qr/SRC\:\s+192\.168\.10\.55/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data --auto-dl $ignore_ipv4_auto_dl_file " .
                "-m $scans_dir/" .  &fw_type() . "/$udp_scan_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'ignore IPv4 UDP scan source subnet',
        'err_msg'   => 'did not ignore UDP scan',
        'negative_output_matches' => [qr/SRC\:\s+192\.168\.10\.55/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data --auto-dl $ignore_ipv4_subnet_auto_dl_file " .
                "-m $scans_dir/" .  &fw_type() . "/$udp_scan_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'psad.conf ignore IPv4 UDP traffic',
        'err_msg'   => 'did not ignore UDP traffic',
        'negative_output_matches' => [qr/SRC\:\s+192\.168\.10\.55/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data --auto-dl $dl5_ipv4_auto_dl_file " .  ### psad.conf IGNORE_PROTOCOLS trumps auto_dl
                "-m $scans_dir/" .  &fw_type() . "/$udp_scan_file -c $ignore_udp_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },

    {
        'category'  => 'operations',
        'detail'    => 'IPv6 TCP connect() scan detection',
        'err_msg'   => 'did not detect TCP connect() scan',
        'positive_output_matches' => [qr/Top\s\d+\sattackers/i,
                qr/scanned\sports.*?1\-65389\b/i,
                qr/IP\sstatus/i,
                qr/SRC\:.*2001\:DB8\:0\:F101\:\:2/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data -m $scans_dir/" .
                &fw_type() . "/$ipv6_connect_scan_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'IPv6 allow valid ping packets',
        'err_msg'   => 'generated detection event',
        'negative_output_matches' => [
                qr/SRC\:.*2001\:DB8\:0\:F101\:\:2/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data -m $scans_dir/" .
                &fw_type() . "/$ipv6_ping_scan_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'IPv6 invalid ICMP6 type/code detection',
        'err_msg'   => 'did not generate detection event',
        'positive_output_matches' => [
                qr/Invalid\sICMP6/,
                qr/SRC\:.*2001\:DB8\:0\:F101\:\:2/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data -m $scans_dir/" .
                &fw_type() . "/$ipv6_invalid_icmp6_type_code_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'IPv4 allow valid ICMP echo request',
        'err_msg'   => 'generated detection event',
        'negative_output_matches' => [
                qr/Invalid\sICMP/,
                qr/SRC\:\s+192.168.10.55/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data -m $scans_dir/" .
                &fw_type() . "/$ipv4_valid_ping -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },

    {
        'category'  => 'operations',
        'detail'    => 'IPv4 invalid ICMP type/code detection',
        'err_msg'   => 'did not generate detection event',
        'positive_output_matches' => [
                qr/Invalid\sICMP/,
                qr/SRC\:\s+192.168.10.55/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data -m $scans_dir/" .
                &fw_type() . "/$ipv4_invalid_icmp6_type_code_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },

    {
        'category'  => 'operations',
        'detail'    => 'IPv6 disabled',
        'err_msg'   => 'logged IPv6 traffic',
        'positive_output_matches' => [qr/\[NONE\]/],
        'negative_output_matches' => [qr/SRC\:.*2001\:DB8\:0\:F101\:\:2/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data -m $scans_dir/" .
                &fw_type() . "/$ipv6_connect_scan_file -c $disable_ipv6_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'ignore IPv6 connect() scan source',
        'err_msg'   => 'logged IPv6 traffic',
        'positive_output_matches' => [qr/\[NONE\]/],
        'negative_output_matches' => [qr/SRC\:.*2001\:DB8\:0\:F101\:\:2/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data --auto-dl $ignore_ipv6_addr_auto_dl_file " .
                "-m $scans_dir/" . &fw_type() . "/$ipv6_connect_scan_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'ignore IPv6 connect() scan abbrev source',
        'err_msg'   => 'logged IPv6 traffic',
        'positive_output_matches' => [qr/\[NONE\]/],
        'negative_output_matches' => [qr/SRC\:.*2001\:DB8\:0\:F101\:\:2/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --analysis-write-data --auto-dl $ignore_ipv6_addr_auto_dl_file_abbrev " .
                "-m $scans_dir/" . &fw_type() . "/$ipv6_connect_scan_file -c $default_conf $normal_root_override_str",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },

    {
        'category'  => 'errors',
        'detail'    => 'look for perl warnings',
        'err_msg'   => 'found perl warnings',
        'negative_output_matches' => [qr/Use\sof\suninitialized\svalue/i,
            qr/Missing\sargument/,
            qr/Argument.*isn\'t\snumeric/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&look_for_warnings,
        'cmdline'   => "grep -i uninit $output_dir/*.test",
        'exec_err'  => $IGNORE,
        'fatal'     => $NO
    },

);

### make sure everything looks as expected before continuing
&init();

&logr("\n[+] Starting the psad test suite...\n\n" .
    "    args: @args_cp\n\n"
);

### save the results from any previous test suite run
### so that we can potentially compare them with --diff
if ($saved_last_results) {
    &logr("    Saved results from previous run " .
        "to: ${output_dir}.last/\n\n");
}

### main loop through all of the tests
for my $test_hr (@tests) {
    &run_test($test_hr);
    last if $test_limit > 0 and $executed >= $test_limit;
}

&logr("\n[+] passed/failed/executed: $passed/$failed/$executed tests\n\n");

copy $logfile, "$output_dir/$logfile" or die $!;

exit 0;

#===================== end main =======================

sub run_test() {
    my $test_hr = shift;

    my $msg = "[$test_hr->{'category'}]";
    $msg .= " [$test_hr->{'subcategory'}]" if $test_hr->{'subcategory'};
    $msg .= " $test_hr->{'detail'}";

    return unless &process_include_exclude($msg);

    if ($list_mode) {
        print $msg, "\n";
        return;
    }

    &dots_print($msg);

    $executed++;
    $current_test_file  = "$output_dir/$executed.test";

    &write_test_file("[+] TEST: $msg\n");
    if (&{$test_hr->{'function'}}($test_hr)) {
        &logr("pass ($executed)\n");
        $passed++;
    } else {
        &logr("fail ($executed)\n");
        $failed++;

        if ($test_hr->{'fatal'} eq $YES) {
            die "[*] required test failed, exiting.";
        }
    }

    return;
}

sub validate_config() {
    my $test_hr = shift;

    open F, "< $default_conf" or die $!;
    while (<F>) {
        next unless /\S/;
        next if /^#/;
        if (/^(\S+?)(?:Cmd)?\s+.*;/) {
            push @{$test_hr->{'positive_output_matches'}}, qr/\b$1\b/;
            $test_hr->{'match_all'} = $MATCH_ALL_RE;
        }
    }
    close F;

    return &generic_exec($test_hr);
}

sub look_for_warnings() {
    my $test_hr = shift;

    my $orig_test_file = $current_test_file;

    $current_test_file = "$output_dir/grep.output";

    my $rv = &generic_exec($test_hr);

    copy $current_test_file, $orig_test_file;
    unlink $current_test_file;

    return $rv;
}

sub install_test_dir() {
    my $test_hr = shift;

    my $rv = 1;
    my $curr_pwd = cwd() or die $!;

    if (-d $test_install_dir) {
        rmtree $test_install_dir or die $!;
    }
    mkdir $test_install_dir  or die $!;

    chdir '..' or die $!;

    my $exec_rv = &run_cmd($test_hr->{'cmdline'},
                "test/$cmd_out_tmp", "test/$current_test_file");

    if ($test_hr->{'exec_err'} eq $YES) {
        $rv = 0 if $exec_rv;
    } elsif ($test_hr->{'exec_err'} eq $NO) {
        $rv = 0 unless $exec_rv;
    } else {
        $rv = 1;
    }

    if ($test_hr->{'positive_output_matches'}) {
        $rv = 0 unless &file_find_regex(
            $test_hr->{'positive_output_matches'},
            $test_hr->{'match_all'},
            $current_test_file);
    }

    if ($test_hr->{'negative_output_matches'}) {
        $rv = 0 if &file_find_regex(
            $test_hr->{'negative_output_matches'},
            $test_hr->{'match_all'},
            $current_test_file);
    }

    chdir $curr_pwd or die $!;

    return $rv;
}

sub generic_exec() {
    my $test_hr = shift;

    my $rv = 1;

    my $exec_rv = &run_cmd($test_hr->{'cmdline'},
                $cmd_out_tmp, $current_test_file);

    if ($test_hr->{'exec_err'} eq $YES) {
        $rv = 0 if $exec_rv;
    } elsif ($test_hr->{'exec_err'} eq $NO) {
        $rv = 0 unless $exec_rv;
    } else {
        $rv = 1;
    }

    if ($test_hr->{'auto_block_test'}) {
        &run_cmd("$psadCmd -c $auto_blocking_conf --fw-list",
                $cmd_out_tmp, $current_test_file);
        &run_cmd("$psadCmd -c $auto_blocking_conf -F -X",
                $cmd_out_tmp, $current_test_file);
    }

    if ($test_hr->{'positive_output_matches'}) {
        $rv = 0 unless &file_find_regex(
            $test_hr->{'positive_output_matches'},
            $test_hr->{'match_all'},
            $current_test_file);
    }

    if ($test_hr->{'negative_output_matches'}) {
        $rv = 0 if &file_find_regex(
            $test_hr->{'negative_output_matches'},
            $test_hr->{'match_all'},
            $current_test_file);
    }

    return $rv;
}

sub run_cmd() {
    my ($cmd, $cmd_out, $file) = @_;

    if (-e $file) {
        open F, ">> $file"
            or die "[*] Could not open $file: $!";
        print F localtime() . " CMD: $cmd\n";
        close F;
    } else {
        open F, "> $file"
            or die "[*] Could not open $file: $!";
        print F localtime() . " CMD: $cmd\n";
        close F;
    }

    my $rv = ((system "$cmd > $cmd_out 2>&1") >> 8);

    open C, "< $cmd_out" or die "[*] Could not open $cmd_out: $!";
    my @cmd_lines = <C>;
    close C;

    open F, ">> $file" or die "[*] Could not open $file: $!";
    print F $_ for @cmd_lines;
    close F;

    if ($rv == 0) {
        return 1;
    }
    return 0;
}

sub file_find_regex() {
    my ($re_ar, $match_all_flag, $file) = @_;

    my @write_lines = ();
    my @file_lines  = ();

    open F, "< $file" or die "[*] Could not open $file: $!";
    while (<F>) {
        push @file_lines, $_;
    }
    close F;

    my $found = 0;
    RE: for my $re (@$re_ar) {
        $found = 0;
        LINE: for my $line (@file_lines) {
            next LINE if $line =~ /file_file_regex\(\)/;
            if ($line =~ $re) {
                push @write_lines, "[.] file_find_regex() " .
                    "Matched '$re' with line: $line (file: $file)\n";
                $found = 1;
                last LINE;
            }
        }
        if ($found) {
            if ($match_all_flag == $MATCH_SINGLE_RE) {
                last RE;
            }
        } else {
            push @write_lines, "[.] file_find_regex() " .
                "did not match '$re' (file: $file)\n";
            if ($match_all_flag == $MATCH_ALL_RE) {
                last RE;
            }
        }
    }

    for my $line (@write_lines) {
        &write_test_file($line, $file);
    }

    return $found;
}

sub dots_print() {
    my $msg = shift;
    &logr($msg);
    my $dots = '';
    for (my $i=length($msg); $i < $PRINT_LEN; $i++) {
        $dots .= '.';
    }
    &logr($dots);
    return;
}

sub init() {

    $|++; ### turn off buffering

    $< == 0 and $> == 0 or
        die "[*] $0: You must be root (or equivalent ",
            "UID 0 account) to effectively test psad";

    ### validate test hashes
    my $hash_num = 0;
    for my $test_hr (@tests) {
        for my $key (keys %test_keys) {
            if ($test_keys{$key} == $REQUIRED) {
                die "[*] Missing '$key' element in hash: $hash_num"
                    unless defined $test_hr->{$key};
            } else {
                $test_hr->{$key} = '' unless defined $test_hr->{$key};
            }
        }
        $hash_num++;
    }

    die "[*] $conf_dir directory does not exist." unless -d $conf_dir;
    die "[*] default config $default_conf does not exist" unless -e $default_conf;

    if (-d $output_dir) {
        if (-d "${output_dir}.last") {
            rmtree "${output_dir}.last"
                or die "[*] rmtree ${output_dir}.last $!";
        }
        mkdir "${output_dir}.last"
            or die "[*] ${output_dir}.last: $!";
        for my $file (glob("$output_dir/*.test")) {
            if ($file =~ m|.*/(.*)|) {
                copy $file, "${output_dir}.last/$1" or die $!;
            }
        }
        if (-e "$output_dir/init") {
            copy "$output_dir/init", "${output_dir}.last/init";
        }
        if (-e $logfile) {
            copy $logfile, "${output_dir}.last/$logfile" or die $!;
        }
        $saved_last_results = 1;
    } else {
        mkdir $output_dir or die "[*] Could not mkdir $output_dir: $!";
    }
    unless (-d $scans_dir) {
        die "[*] $scans_dir dir does not exist.";
    }
    unless (-d $run_dir) {
        mkdir $run_dir or die "[*] Could not mkdir $run_dir: $!";
    }

    for my $file (glob("$output_dir/*.test")) {
        unlink $file or die "[*] Could not unlink($file)";
    }
    if (-e "$output_dir/init") {
        unlink "$output_dir/init" or die $!;
    }

    if (-e $logfile) {
        unlink $logfile or die $!;
    }

    push @tests_to_exclude, 'BLOCK' unless $enable_auto_block_tests;

    return;
}

sub process_include_exclude() {
    my $msg = shift;

    ### inclusions/exclusions
    if (@tests_to_include) {
        my $found = 0;
        for my $test (@tests_to_include) {
            if ($msg =~ /$test/) {
                $found = 1;
                last;
            }
        }
        return 0 unless $found;
    }
    if (@tests_to_exclude) {
        my $found = 0;
        for my $test (@tests_to_exclude) {
            if ($msg =~ /$test/) {
                $found = 1;
                last;
            }
        }
        return 0 if $found;
    }
    return 1;
}

sub fw_type() {
    return 'iptables';
}

sub write_test_file() {
    my $msg = shift;

    if (-e $current_test_file) {
        open F, ">> $current_test_file"
            or die "[*] Could not open $current_test_file: $!";
        print F $msg;
        close F;
    } else {
        open F, "> $current_test_file"
            or die "[*] Could not open $current_test_file: $!";
        print F $msg;
        close F;
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

sub usage() {
    print <<_HELP_;

$0 [options]

    -i, --include <test>        - Include tests that match <str>.
    --exclude <test>            - Exclude tests that match <str>.
    --enable-auto-block-tests   - Run auto blocking tests.
    -t, --test-limit <num>      - Run <num> tests.
    -L, --List-mode             - List available tests.
    -h, --help                  - Print help and exit.

_HELP_
    exit 0;
}
