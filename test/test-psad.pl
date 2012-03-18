#!/usr/bin/perl -w

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
my $syn_scan_file  = 'syn_scan_1000_1500';
my $fin_scan_file  = 'fin_scan_1000_1150';
my $xmas_scan_file = 'xmas_scan_1000_1150';
my $null_scan_file = 'null_scan_1000_1150';
my $ack_scan_file  = 'ack_scan_1000_1150';
my $udp_scan_file  = 'udp_scan_1000_1150';
my $ipv6_connect_scan_file  = 'ipv6_tcp_connect_nmap_default_scan';
my $ignore_ipv4_auto_dl_file = "$conf_dir/auto_dl_ignore_192.168.10.55";
my $ignore_ipv4_subnet_auto_dl_file = "$conf_dir/auto_dl_ignore_192.168.10.0_24";
my $ignore_ipv6_addr_auto_dl_file = "$conf_dir/auto_dl_ignore_ipv6_addr";
my $dl5_ipv4_auto_dl_file = "$conf_dir/auto_dl_5_192.168.10.55";
my $dl5_ipv4_subnet_auto_dl_file = "$conf_dir/auto_dl_5_192.168.10.0_24";
my $dl5_ipv4_subnet_auto_dl_file_tcp = "$conf_dir/auto_dl_5_192.168.10.0_24_tcp";
my $dl5_ipv4_subnet_auto_dl_file_udp = "$conf_dir/auto_dl_5_192.168.10.0_24_udp";

my $psadCmd        = 'psad-install/usr/sbin/psad';

my $cmd_out_tmp    = 'cmd.out';
my $default_conf   = "$conf_dir/default_psad.conf";
my $ignore_udp_conf = "$conf_dir/ignore_udp.conf";
my $ignore_tcp_conf = "$conf_dir/ignore_tcp.conf";
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
my $saved_last_results = 0;
my $PRINT_LEN = 68;
my $REQUIRED = 1;
my $OPTIONAL = 0;
my $MATCH_ALL_RE = 1;
my $MATCH_SINGLE_RE = 2;
my $help = 0;

my %test_keys = (
    'category'        => $REQUIRED,
    'subcategory'     => $OPTIONAL,
    'detail'          => $REQUIRED,
    'function'        => $REQUIRED,
    'cmdline'         => $OPTIONAL,
    'fatal'           => $OPTIONAL,
    'exec_err'        => $OPTIONAL,
    'match_all'       => $OPTIONAL,
    'postive_output_matches'  => $OPTIONAL,
    'negative_output_matches' => $OPTIONAL,
);

### define all tests
my @tests = (
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
        'cmdline'  => "$psadCmd -h -c $default_conf",
        'exec_err' => $NO,
        'fatal'    => $NO
    },
    {
        'category' => 'operations',
        'detail'   => 'config dump+validate',
        'err_msg'  => 'could not dump+validate config',
        'function' => \&validate_config,
        'cmdline'  => "$psadCmd --test-mode -D -c $default_conf",
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
        'cmdline'   => "$psadCmd --test-mode --fw-dump -c $default_conf",
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
        'cmdline'   => "$psadCmd --test-mode --fw-list-auto -c $default_conf",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => '--fw-analyze',
        'err_msg'   => 'could not analyze fw policy',
        'positive_output_matches' => [qr/Parsing.*iptables/, qr/Parsing.*ip6tables/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode --fw-analyze -c $default_conf",
        'exec_err'  => $IGNORE,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => '--Status',
        'err_msg'   => 'could not get psad status',
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -S -c $default_conf",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => '--Status --status-summary',
        'err_msg'   => 'could not get psad status summary',
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -S --status-summary -c $default_conf",
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
        'cmdline'   => "$psadCmd --test-mode --get-next-rule-id -c $default_conf",
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
        'cmdline'   => "$psadCmd --test-mode --Benchmark --packets 1000 -c $default_conf",
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
        'cmdline'   => "$psadCmd --test-mode -A -m $scans_dir/" .
                &fw_type() . "/$syn_scan_file -c $default_conf",
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
        'cmdline'   => "$psadCmd --test-mode -A -m $scans_dir/" .
                &fw_type() . "/$fin_scan_file -c $default_conf",
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
        'cmdline'   => "$psadCmd --test-mode -A -m $scans_dir/" .
                &fw_type() . "/$xmas_scan_file -c $default_conf",
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
        'cmdline'   => "$psadCmd --test-mode -A -m $scans_dir/" .
                &fw_type() . "/$null_scan_file -c $default_conf",
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
        'cmdline'   => "$psadCmd --test-mode -A -m $scans_dir/" .
                &fw_type() . "/$ack_scan_file -c $enable_ack_detection_conf",
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
        'cmdline'   => "$psadCmd --test-mode -A -m $scans_dir/" .
                &fw_type() . "/$udp_scan_file -c $default_conf",
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
        'cmdline'   => "$psadCmd --test-mode -A --auto-dl $dl5_ipv4_auto_dl_file " .
                "-m $scans_dir/" .  &fw_type() . "/$syn_scan_file -c $default_conf",
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
        'cmdline'   => "$psadCmd --test-mode -A --auto-dl $dl5_ipv4_subnet_auto_dl_file " .
                "-m $scans_dir/" .  &fw_type() . "/$syn_scan_file -c $default_conf",
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
        'cmdline'   => "$psadCmd --test-mode -A --auto-dl $dl5_ipv4_subnet_auto_dl_file_tcp " .
                "-m $scans_dir/" .  &fw_type() . "/$syn_scan_file -c $default_conf",
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
        'cmdline'   => "$psadCmd --test-mode -A --auto-dl $dl5_ipv4_subnet_auto_dl_file_udp " .
                "-m $scans_dir/" .  &fw_type() . "/$syn_scan_file -c $default_conf",
        'exec_err'  => $NO,
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
        'cmdline'   => "$psadCmd --test-mode -A --auto-dl $dl5_ipv4_auto_dl_file " .
                "-m $scans_dir/" .  &fw_type() . "/$udp_scan_file -c $default_conf",
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
        'cmdline'   => "$psadCmd --test-mode -A --auto-dl $dl5_ipv4_subnet_auto_dl_file " .
                "-m $scans_dir/" .  &fw_type() . "/$udp_scan_file -c $default_conf",
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
        'cmdline'   => "$psadCmd --test-mode -A --auto-dl $dl5_ipv4_subnet_auto_dl_file_udp " .
                "-m $scans_dir/" .  &fw_type() . "/$udp_scan_file -c $default_conf",
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
        'cmdline'   => "$psadCmd --test-mode -A --auto-dl $dl5_ipv4_subnet_auto_dl_file_tcp " .
                "-m $scans_dir/" .  &fw_type() . "/$udp_scan_file -c $default_conf",
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
        'cmdline'   => "$psadCmd --test-mode -A --auto-dl $ignore_ipv4_auto_dl_file " .
                "-m $scans_dir/" .  &fw_type() . "/$syn_scan_file -c $default_conf",
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
        'cmdline'   => "$psadCmd --test-mode -A --auto-dl $ignore_ipv4_subnet_auto_dl_file " .
                "-m $scans_dir/" .  &fw_type() . "/$syn_scan_file -c $default_conf",
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
        'cmdline'   => "$psadCmd --test-mode -A --auto-dl $dl5_ipv4_auto_dl_file " .  ### psad.conf IGNORE_PROTOCOLS trumps auto_dl
                "-m $scans_dir/" .  &fw_type() . "/$syn_scan_file -c $ignore_tcp_conf",
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
        'cmdline'   => "$psadCmd --test-mode -A --auto-dl $dl5_ipv4_auto_dl_file " .  ### psad.conf FW_MSG_SEARCH trumps auto_dl
                "-m $scans_dir/" .  &fw_type() . "/$syn_scan_file -c $require_prefix_conf",
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
        'cmdline'   => "$psadCmd --test-mode -A --auto-dl $dl5_ipv4_auto_dl_file " .  ### psad.conf FW_MSG_SEARCH trumps auto_dl
                "-m $scans_dir/" .  &fw_type() . "/$syn_scan_file -c $require_missing_prefix_conf",
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
        'cmdline'   => "$psadCmd --test-mode -A --auto-dl $ignore_ipv4_auto_dl_file " .
                "-m $scans_dir/" .  &fw_type() . "/$udp_scan_file -c $default_conf",
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
        'cmdline'   => "$psadCmd --test-mode -A --auto-dl $ignore_ipv4_subnet_auto_dl_file " .
                "-m $scans_dir/" .  &fw_type() . "/$udp_scan_file -c $default_conf",
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
        'cmdline'   => "$psadCmd --test-mode -A --auto-dl $dl5_ipv4_auto_dl_file " .  ### psad.conf IGNORE_PROTOCOLS trumps auto_dl
                "-m $scans_dir/" .  &fw_type() . "/$udp_scan_file -c $ignore_udp_conf",
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
                qr/2001\:DB8\:0\:F101\:\:2/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A -m $scans_dir/" .
                &fw_type() . "/$ipv6_connect_scan_file -c $default_conf",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'IPv6 disabled',
        'err_msg'   => 'logged IPv6 traffic',
        'positive_output_matches' => [qr/\[NONE\]/],
        'negative_output_matches' => [qr/2001\:DB8\:0\:F101\:\:2/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A -m $scans_dir/" .
                &fw_type() . "/$ipv6_connect_scan_file -c $disable_ipv6_conf",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category'  => 'operations',
        'detail'    => 'ignore IPv6 connect() scan source',
        'err_msg'   => 'logged IPv6 traffic',
        'positive_output_matches' => [qr/\[NONE\]/],
        'negative_output_matches' => [qr/2001\:DB8\:0\:F101\:\:2/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --test-mode -A --auto-dl $ignore_ipv6_addr_auto_dl_file " .
                "-m $scans_dir/" . &fw_type() . "/$ipv6_connect_scan_file -c $default_conf",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },

);

my @args_cp = @ARGV;

exit 1 unless GetOptions(
    'psad-path=s'       => \$psadCmd,
    'test-include=s'    => \$test_include,
    'include=s'         => \$test_include,  ### synonym
    'test-exclude=s'    => \$test_exclude,
    'exclude=s'         => \$test_exclude,  ### synonym
    'List-mode'         => \$list_mode,
    'diff'              => \$diff_mode,
    'help'              => \$help
);

&usage() if $help;

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
                    "Matched '$re' with line: $line";
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
                "did not match '$re'\n";
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

    if ($test_include) {
        @tests_to_include = split /\s*,\s*/, $test_include;
    }
    if ($test_exclude) {
        @tests_to_exclude = split /\s*,\s*/, $test_exclude;
    }

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
    ### FIXME
}
