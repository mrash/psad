#!/usr/bin/perl -w
#
################################################################################
#
################################################################################
#
# $Id$
#

use lib '/usr/lib/psad';
use IPTables::Parse;
use Getopt::Long 'GetOptions';
use strict;

sub fw_check() {
    unlink $config{'FW_CHECK_FILE'} if -e $config{'FW_CHECK_FILE'};

    ### only send a firewall config alert if we really need to.
    my $send_alert = 0;

    my $forward_chain_rv = 1;
    my $input_chain_rv = &ipt_chk_chain('INPUT');

    unless ($input_chain_rv) {
#        &print_fw_help('INPUT');
        $send_alert = 1;
    }

    ### we don't always have more than one interface or forwarding
    ### turned on, so we only check the FORWARD iptables chain if we
    ### do and we have multiple interfaces on the box.
    if (&check_forwarding()) {
        $forward_chain_rv = &ipt_chk_chain('FORWARD');
        unless ($forward_chain_rv) {
#            &print_fw_help('FORWARD');
            $send_alert = 1;
        }
    }

    if ($send_alert) {
        &Psad::logr("\n", {$config{'FW_CHECK_FILE'} => 1});
        &Psad::logr(' .. NOTE: IPTables::Parse does not yet parse user ' .
            'defined chains and so it is possible your firewall config ' .
            "is compatible with psad anyway.\n",
            {$config{'FW_CHECK_FILE'} => 1});
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
        &Psad::logr(" .. The iptables ruleset on $config{'HOSTNAME'} " .
            "will log and block unwanted packets in both the INPUT and " .
            "FORWARD chains.  Firewall config success!\n",
            {$config{'FW_CHECK_FILE'} => 1});
        if ($fw_analyze) {
            print scalar localtime(), " .. Firewall config looks good.\n";
            print scalar localtime(), " .. Completed check of firewall ruleset.\n";
        }
    }
    if ($fw_analyze) {
        print scalar localtime(), " .. Exiting.\n";
        exit 0;
    }
    return;
}

sub print_fw_help() {
    my $chain = shift;
    &Psad::logr(" ** The $chain chain in the iptables ruleset on " .
        "$config{'HOSTNAME'} does not include default rules that will " .
        "log and drop unwanted packets. You need to include two default " .
        "rules; one that logs packets that have not been accepted by " .
        "previous rules (this rule should have a logging prefix of " .
        "\"$config{'FW_MSG_SEARCH'}\"), and a final rule that drops any " .
        "unwanted packets.\n",
        {$config{'FW_CHECK_FILE'} => 1});
    &Psad::logr("\n", {$config{'FW_CHECK_FILE'} => 1});
    &Psad::logr('    FOR EXAMPLE:  Assuming you have already setup ' .
        'iptables rules to accept traffic you want to allow, you can ' .
        'probably execute the following two commands to have iptables ' .
        "log and drop unwanted packets in the $chain chain by " .
        "default.\n",
        {$config{'FW_CHECK_FILE'} => 1});
    &Psad::logr("\n", {$config{'FW_CHECK_FILE'} => 1});
    &Psad::logr("              iptables -A $chain -j LOG --log-prefix " .
        qq("$config{'FW_MSG_SEARCH'} "\n), {$config{'FW_CHECK_FILE'} => 1});
    &Psad::logr("              iptables -A $chain -j DROP\n\n",
        {$config{'FW_CHECK_FILE'} => 1});
    &Psad::logr(" ** Psad will not detect in the iptables $chain chain " .
        'scans without an iptables ruleset that includes rules similar ' .
        "to the two rules above.\n",
        {$config{'FW_CHECK_FILE'} => 1});
    &Psad::logr("\n", {$config{'FW_CHECK_FILE'} => 1});
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
        print STDERR " .. forwarding value: $forwarding\n" if $debug;
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
    print STDERR " .. number of interfaces: $num_intf\n" if $debug;
    if ($num_intf < 2) {
        return 0;
    }
    return 1;
}


### should probably make this into its own script
sub ipt_chk_chain() {
    my $chain = shift;

    print STDERR " .. ipt_chk_chain($chain)\n" if $debug;

    my $ipt = new IPTables::Parse 'iptables' => $cmds{'iptables'};

    if ($fw_analyze) {
        print scalar localtime(),
            " .. Parsing iptables $chain chain rules.\n";
    }
    ### for now we are only looking at the filter table, so if
    ### the iptables ruleset includes the log and drop rules in
    ### a user defined chain then psad will not see this.
    my $ld_hr;
    if ($fw_file) {
        $ld_hr = $ipt->default_drop('filter', $chain, $fw_file);
    } else {
        $ld_hr = $ipt->default_drop('filter', $chain);
    }

    print STDERR Dumper $ld_hr if $debug;

    my $rv = 1;
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
                &Psad::logr(" ** The $chain chain in the iptables ruleset on " .
                    "$config{'HOSTNAME'} does not include a default LOG rule " .
                    "$str1.  psad will not be able to detect $str2 without " .
                    "such a rule.\n",
                    {$config{'FW_CHECK_FILE'} => 1});
                &Psad::logr("\n", {$config{'FW_CHECK_FILE'} => 1});
                $rv = 0;
            }
            if (defined $ld_hr->{$proto}->{'LOG'}->{'prefix'}
                    && $ld_hr->{$proto}->{'LOG'}->{'prefix'}
                    !~ /$config{'FW_MSG_SEARCH'}/) {
                if ($proto eq 'all') {
                    $str1 = " ** The $chain chain in the iptables ruleset " .
                    "on $config{'HOSTNAME'} includes a default LOG rule for " .
                    "all protocols,";
                    $str2 = 'scans';
                } else {
                    $str1 = " ** The $chain chain in the iptables ruleset " .
                    "on $config{'HOSTNAME'} inclues a default LOG rule for " .
                    "the $proto protocol,";
                    $str2 = "$proto scans";
                }
                &Psad::logr("$str1 but the rule does not have a log prefix " .
                    qq(of "$config{'FW_MSG_SEARCH'}".  It appears as though ) .
                    qq(the log prefix is set to "$ld_hr->{$proto}->{'LOG'}->{'prefix'}".) .
                    qq(  psad will not be able to detect $str2 without adding ) .
                    qq(--log-prefix "$config{'FW_MSG_SEARCH'}" to the rule.\n),
                    {$config{'FW_CHECK_FILE'} => 1});
                &Psad::logr("\n", {$config{'FW_CHECK_FILE'} => 1});
                $rv = 0;
            }
            if (! defined $ld_hr->{$proto}->{'DROP'}) {
                if ($proto eq 'all') {
                    $str1 = "for all protocols";
                } else {
                    $str1 = "for the $proto protocol";
                }
                &Psad::logr(" ** The $chain chain in the iptables ruleset on " .
                    "$config{'HOSTNAME'} does not include a default DROP " .
                    "rule $str1.\n", {$config{'FW_CHECK_FILE'} => 1});
                &Psad::logr("\n", {$config{'FW_CHECK_FILE'} => 1});
                $rv = 0;
            }
        }
    }
    ### make sure there was _something_ return from the IPTables::Parse
    ### module.
    return 0 unless $num_keys > 0;
    return $rv;
}

