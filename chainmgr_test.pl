#!/usr/bin/perl -w

use strict;

### path to default psad library directory for psad perl modules
my $psad_lib_dir = '/usr/lib/psad';

### import psad perl modules
&import_psad_perl_modules();

my $ipt = new IPTables::ChainMgr(
    'iptables' => '/sbin/iptables',
    'verbose'  => 1
);
my $total_rules = 0;

my ($rv, $out_aref, $err_aref) = $ipt->create_chain('filter', 'PSAD');
print "create_chain() rv: $rv\n";
print "$_\n" for @$out_aref;
print "$_\n" for @$err_aref;

($rv, $out_aref, $err_aref) = $ipt->add_jump_rule('filter', 'INPUT', 'PSAD');
print "add_jump_rule() rv: $rv\n";
print "$_\n" for @$out_aref;
print "$_\n" for @$err_aref;

($rv, $out_aref, $err_aref) = $ipt->add_ip_rule('1.1.1.1',
    '0.0.0.0/0', 10, 'filter', 'PSAD', 'DROP');
print "add_ip_rule() rv: $rv\n";
print "$_\n" for @$out_aref;
print "$_\n" for @$err_aref;

($rv, $total_rules) = $ipt->find_ip_rule('1.1.1.1', '0.0.0.0/0', 'filter', 'PSAD', 'DROP');
print "find ip: $rv, total chain rules: $total_rules\n";

($rv, $out_aref, $err_aref) = $ipt->add_ip_rule('2.2.1.1', '0.0.0.0/0', 10,
    'filter', 'PSAD', 'DROP');
print "add_ip_rule() rv: $rv\n";
print "$_\n" for @$out_aref;
print "$_\n" for @$err_aref;

($rv, $out_aref, $err_aref) = $ipt->add_ip_rule('2.2.4.1', '0.0.0.0/0', 10,
    'filter', 'PSAD', 'DROP');
print "add_ip_rule() rv: $rv\n";
print "$_\n" for @$out_aref;
print "$_\n" for @$err_aref;

($rv, $out_aref, $err_aref) = $ipt->delete_ip_rule('1.1.1.1', '0.0.0.0/0',
    'filter', 'PSAD', 'DROP');
print "delete_ip_rule() rv: $rv\n";
print "$_\n" for @$out_aref;
print "$_\n" for @$err_aref;

($rv, $out_aref, $err_aref) = $ipt->delete_chain('filter', 'INPUT', 'PSAD');
print "delete_chain() rv: $rv\n";
print "$_\n" for @$out_aref;
print "$_\n" for @$err_aref;

($rv, $out_aref, $err_aref) = $ipt->run_ipt_cmd('/sbin/iptables -nL INPUT');
print "list on 'INPUT' chain rv: $rv\n";
print for @$out_aref;
print for @$err_aref;

($rv, $out_aref, $err_aref) = $ipt->run_ipt_cmd('/sbin/iptables -nL INPU');
print "bogus list on 'INPU' chain rv: $rv (this is expected).\n";
print for @$out_aref;
print for @$err_aref;

exit 0;

sub import_psad_perl_modules() {

    my $mod_paths_ar = &get_psad_mod_paths();

    splice @INC, 0, $#$mod_paths_ar+1, @$mod_paths_ar;

    require IPTables::Parse;
    require IPTables::ChainMgr;

    return;
}

sub get_psad_mod_paths() {

    my @paths = ();

    unless (-d $psad_lib_dir) {
        my $dir_tmp = $psad_lib_dir;
        $dir_tmp =~ s|lib/|lib64/|;
        if (-d $dir_tmp) {
            $psad_lib_dir = $dir_tmp;
        } else {
            die "[*] psad lib directory: $psad_lib_dir does not exist, ",
                "use --Lib-dir <dir>";
        }
    }

    opendir D, $psad_lib_dir or die "[*] Could not open $psad_lib_dir: $!";
    my @dirs = readdir D;
    closedir D;
    shift @dirs; shift @dirs;

    push @paths, $psad_lib_dir;

    for my $dir (@dirs) {
        ### get directories like "/usr/lib/psad/x86_64-linux"
        next unless -d "$psad_lib_dir/$dir";
        push @paths, "$psad_lib_dir/$dir"
            if $dir =~ m|linux| or $dir =~ m|thread|;
    }
    return \@paths;
}

