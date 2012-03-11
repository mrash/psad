#!/usr/bin/perl -w

use File::Copy;
use File::Path;
use strict;

#==================== config =====================
my $logfile        = 'test.log';
my $output_dir     = 'output';
my $conf_dir       = 'conf';
my $run_dir        = 'run';

my $psadCmd        = '../psad';

my $cmd_out_tmp    = 'cmd.out';
my $default_conf   = "$conf_dir/default_psad.conf";
#================== end config ===================

my $YES = 1;
my $NO  = 0;
my $current_test_file = "$output_dir/init";
my $passed = 0;
my $failed = 0;
my $executed = 0;
my $test_include = '';
my @tests_to_include = ();
my $test_exclude = '';
my @tests_to_exclude = ();
my $list_mode = 0;
my $saved_last_results = 0;
my $PRINT_LEN = 68;
my $REQUIRED = 1;
my $OPTIONAL = 0;
my $MATCH_ALL_RE = 1;
my $MATCH_SINGLE_RE = 2;

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
        'category'  => 'operations',
        'detail'    => 'Dump policy: --fw-dump',
        'err_msg'   => 'could not dump fw policy',
        'positive_output_matches' => [qr/^Chain/, qr/pkts\sbytes\starget/,
                qr/\biptables\b/, qr/\bip6tables\b/],
        'match_all' => $MATCH_ALL_RE,
        'function'  => \&generic_exec,
        'cmdline'   => "$psadCmd --fw-dump -c $default_conf",
        'exec_err'  => $NO,
        'fatal'     => $NO
    },
    {
        'category' => 'operations',
        'detail'   => 'config dump+validate',
        'err_msg'  => 'could not dump+validate config',
        'function' => \&validate_config,
        'cmdline'  => "$psadCmd -D -c $default_conf",
        'exec_err' => $NO,
        'fatal'    => $NO
    },

);

my @args_cp = @ARGV;

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
    } else {
        $rv = 0 unless $exec_rv;
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
                "did not match '$re'";
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

    $< == 0 && $> == 0 or
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
