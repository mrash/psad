#!/usr/bin/perl -w
#
################################################################################
#
################################################################################
#
# $Id$
#

use lib '/usr/lib/psad';
use Psad;
use IPTables::Parse;
use Getopt::Long 'GetOptions';
use strict;

### default psad config file.
my $config_file  = '/etc/psad/psad.conf';

### default fw_search file where FW_MSG_SEARCH strings
### are set.  Both psad and kmsgsd reference this single
### file now instead of having FW_MSG_SEARCH appear in
### psad.conf and kmsgsd.conf.
my $fw_search_file = '/etc/psad/fw_search.conf';

### config hash
my %config = ();

### commands hash
my %cmds;

### fw search string array
my @fw_search = ();

my $help = 0;
my $fw_analyze = 0;
my $fw_file    = '';
my $no_fw_search_all = 0;

&usage(1) unless (GetOptions(
    'config=s'    => \$config_file, # Specify path to configuration file.
    'fw-search=s' => \$fw_search_file,  # Specify path to fw_search.conf.
    'fw-file=s'   => \$fw_file,     # Analyze ruleset contained within
                                    # $fw_file instead of a running
                                    # policy.
    'fw-analyze'  => \$fw_analyze,  # Analyze the local iptables ruleset
                                    # and exit.
    'no-fw-search-all' => \$no_fw_search_all, # looking for specific log
                                              # prefixes
    'help'        => \$help,        # Display help.
));
&usage(0) if $help;

### Everthing after this point must be executed as root.
$< == 0 && $> == 0 or
    die ' ** fwcheck_psad.pl: You must be root (or equivalent ',
        "UID 0 account) to execute fwcheck_psad.pl!  Exiting.\n";

### import psad.conf
&Psad::buildconf(\%config, \%cmds, $config_file);

### check to make sure the commands specified in the config section
### are in the right place, and attempt to correct automatically if not.
&Psad::check_commands(\%cmds);

### import FW_MSG_SEARCH strings
&import_fw_search();

open FWCHECK, "> $config{'FW_CHECK_FILE'}" or die " ** Could not ",
    "open $config{'FW_CHECK_FILE'}: $!";

unless ($no_fw_search_all) {
    print FWCHECK " .. Available search strings in $fw_search_file:\n\n";
    print FWCHECK "        $_\n" for @fw_search;
    print FWCHECK
"\n .. Additional search strings can be added be specifying more\n",
    "    FW_MSG_SEARCH lines in $fw_search_file\n\n";
}

### check the iptables policy
my $rv = &fw_check();

close FWCHECK;

exit $rv;

#========================== end main =========================

sub fw_check() {

    ### only send a firewall config alert if we really need to.
    my $send_alert = 0;

    my $forward_chain_rv = 1;
    my $input_chain_rv = &ipt_chk_chain('INPUT');

    unless ($input_chain_rv) {
        &print_fw_help('INPUT');
        $send_alert = 1;
    }

    ### we don't always have more than one interface or forwarding
    ### turned on, so we only check the FORWARD iptables chain if we
    ### do and we have multiple interfaces on the box.
    if (&check_forwarding()) {
        $forward_chain_rv = &ipt_chk_chain('FORWARD');
        unless ($forward_chain_rv) {
            &print_fw_help('FORWARD');
            $send_alert = 1;
        }
    }

    if ($send_alert) {
        print FWCHECK
"\n .. NOTE: IPTables::Parse does not yet parse user defined chains and so\n",
"    it is possible your firewall config is compatible with psad anyway.\n";

        &Psad::sendmail(" ** psad: firewall setup warning on " .
            "$config{'HOSTNAME'}!", $config{'FW_CHECK_FILE'},
            $config{'EMAIL_ADDRESSES'},
            $cmds{'mail'}
        );
        if ($fw_analyze) {
            print scalar localtime(), " ** Errors found in firewall config.\n";
            print scalar localtime(), " ** Results in " .
                "$config{'FW_CHECK_FILE'}\n";
            print scalar localtime(), "    emailed to ",
                "$config{'EMAIL_ADDRESSES'}\n";
        }
    } else {
        print FWCHECK
" .. The iptables ruleset on $config{'HOSTNAME'} will log and block unwanted\n",
"    packets in both the INPUT and FORWARD chains.  Firewall config success!\n";

        if ($fw_analyze) {
            print scalar localtime(), " .. Firewall config looks good.\n";
            print scalar localtime(), " .. Completed check of firewall ruleset.\n";
        }
    }
    if ($fw_analyze) {
        print scalar localtime(), " .. Exiting.\n";
    }
    return $forward_chain_rv && $input_chain_rv;
}

sub print_fw_help() {
    my $chain = shift;
    print FWCHECK
" ** The $chain chain in the iptables ruleset on $config{'HOSTNAME'} does not\n",
"    appear to include default rules that will log and drop unwanted packets.\n",
"    You need to include two default rules; one that logs packets that have\n",
"    not been accepted by previous rules ";
    if ($no_fw_search_all) {
        print FWCHECK "(this rule should have a logging\n",
"   prefix of one of the search strings mentioned above), and a final rule\n";
    } else {
        print FWCHECK "(this rule can have a logging\n",
"   prefix such as \"DROP\" or \"REJECT\"), and a final rule\n";
    }
    print FWCHECK
"    that drops any unwanted packets.\n\n",
"    FOR EXAMPLE:  Assuming you have already setup iptables rules to accept\n",
"    traffic you want to allow, you can probably execute the following two\n",
"    commandsto have iptables log and drop unwanted packets in the $chain\n",
"    chain by default.\n\n";
    if ($no_fw_search_all) {
        print FWCHECK
"              iptables -A $chain -j LOG --log-prefix \"$fw_search[0] \"\n";
    } else {
        print FWCHECK
"              iptables -A $chain -j LOG\n";
    }
        print FWCHECK
"              iptables -A $chain -j DROP\n\n",
" ** Psad will not detect in the iptables $chain chain scans without an\n",
"    iptables ruleset that includes rules similar to the two rules above.\n\n";
    return;
}

sub check_forwarding() {
    ### check to see if there are multiple interfaces on the
    ### machine and return false if no since the machine will
    ### not be able to forward packets anyway (e.g. desktop
    ### machines).  Also return false if forwarding is turned
    ### off (we have to trust the machine config is as the
    ### admin wants it).
    my $forwarding;
    if (-e $config{'PROC_FORWARD_FILE'}) {
        open F, "< $config{'PROC_FORWARD_FILE'}"
            or die " ** Could not open $config{'PROC_FORWARD_FILE'}: $!";
        $forwarding = <F>;
        close F;
        chomp $forwarding;
        return 0 if $forwarding == 0;
    } else {
        die " ** Make sure the path to the IP forwarding file correct.\n",
            "    The PROC_FORWARD_FILE in $config_file points to\n",
            "    $config{'PROC_FORWARD_FILE'}";
    }
    open IFC, "$cmds{'ifconfig'} -a |" or die " ** Could not ",
        "execute: $cmds{'ifconfig'} -a: $!";
    my @if_out = <IFC>;
    close IFC;
    my $num_intf = 0;
    for my $line (@if_out) {
        if ($line =~ /inet\s+/i && $line !~ /127\.0\.0\.1/) {
            $num_intf++;
        }
    }
    if ($num_intf < 2) {
        return 0;
    }
    return 1;
}

sub ipt_chk_chain() {
    my $chain = shift;
    my $rv = 1;

    my $ipt = new IPTables::Parse 'iptables' => $cmds{'iptables'};

    if ($fw_analyze) {
        print scalar localtime(),
            " .. Parsing iptables $chain chain rules.\n";
    }

    if ($no_fw_search_all) {  ### we are not looking for specific log
                              ### prefixes, but we need _some_ logging rule
        my $ipt_log = $ipt->chain_action_rules('filter', $chain, 'LOG');
        return 0 unless $ipt_log;
        if (defined $ipt_log->{'all'}
                and defined $ipt_log->{'all'}->{'0.0.0.0/0'}
                and defined $ipt_log->{'all'}->{'0.0.0.0/0'}->{'0.0.0.0/0'}) {
            ### found real default logging rule (assuming it is above a default
            ### drop rule, which we are not actually checking here).
            return 1;
        } elsif (defined $ipt_log->{'all'}) {
            print FWCHECK
" ** Indeterminate firewall logging config for chain $chain on $config{'HOSTNAME'}. ",
"    There are logging rules however, so at least psad will be able to analyze ",
"    packets logged through these rules.\n\n";
            return 1;
        } else {
            print FWCHECK
" ** Your firewall config no $config{'HOSTNAME'} does not include any logging ",
"    rules at all in the $chain chain.\n\n";
            return 0;
        }
    } else {  ### we are looking for specific log prefixes.
        ### for now we are only looking at the filter table, so if
        ### the iptables ruleset includes the log and drop rules in
        ### a user defined chain then psad will not see this.
        my $ld_hr;
        if ($fw_file) {
            $ld_hr = $ipt->default_drop('filter', $chain, $fw_file);
        } else {
            $ld_hr = $ipt->default_drop('filter', $chain);
        }

        my $num_keys = 0;
        if (defined $ld_hr and keys %$ld_hr) {
            $num_keys++;
            my @protos;
            if (defined $ld_hr->{'all'}) {
                @protos = qw(all);
            } else {
                @protos = qw(tcp udp icmp);
            }
            for my $proto (@protos) {
                my $str1;
                my $str2;
                if (! defined $ld_hr->{$proto}->{'LOG'}) {
                    if ($proto eq 'all') {
                        $str1 = 'for all protocols';
                        $str2 = 'scans';
                    } else {
                        $str1 = "for the $proto protocol";
                        $str2 = "$proto scans";
                    }
                    print FWCHECK
" ** The $chain chain in the iptables ruleset on $config{'HOSTNAME'} does not\n",
"    appear to include a default LOG rule $str1.  psad will not be able to\n",
"    detect $str2 without such a rule.\n\n";

                    $rv = 0;
                }
                if (defined $ld_hr->{$proto}->{'LOG'}->{'prefix'}) {
                    my $found = 0;
                    for my $fwstr (@fw_search) {
                        $found = 1
                            if $ld_hr->{$proto}->{'LOG'}->{'prefix'} =~ /$fwstr/;
                    }
                    unless ($found) {
                        if ($proto eq 'all') {
                            $str1 = " ** The $chain chain in the iptables ruleset " .
                            "on $config{'HOSTNAME'} includes a default\n    LOG rule for " .
                            "all protocols,";
                            $str2 = 'scans';
                        } else {
                            $str1 = " ** The $chain chain in the iptables ruleset " .
                            "on $config{'HOSTNAME'} inclues a default\n    LOG rule for " .
                            "the $proto protocol,";
                            $str2 = "$proto scans";
                        }
                        print FWCHECK
"$str1\n",
"    but the rule does not include one of the log prefixes mentioned above.\n",
"    It appears as though the log prefix is set to \"$ld_hr->{$proto}->{'LOG'}->{'prefix'}\"\n",
"    psad will not be able to detect $str2 without adding one of the above\n",
"    logging prefixes to the rule.\n\n";
                        $rv = 0;
                    }
                }
                if (! defined $ld_hr->{$proto}->{'DROP'}) {
                    if ($proto eq 'all') {
                        $str1 = "for all protocols";
                    } else {
                        $str1 = "for the $proto protocol";
                    }
                    print FWCHECK
" ** The $chain chain in the iptables ruleset on $config{'HOSTNAME'} does not\n",
"    appear to include a default DROP rule $str1.\n\n";
                    $rv = 0;
                }
            }
        }
        ### make sure there was _something_ returned from the IPTables::Parse
        ### module.
        return 0 unless $num_keys > 0;
    }
    return $rv;
}

sub import_fw_search() {
    open F, "< $fw_search_file" or die " ** Could not open fw search ",
        "string file $fw_search_file: $!";
    my @lines = <F>;
    close F;
    for my $line (@lines) {
        next unless $line =~ /\S/;
        next if $line =~ /^\s*#/;
        if ($line =~ /^\s*FW_MSG_SEARCH\s+(.*?);/) {
            push @fw_search, $1;
        }
    }
    return;
}
