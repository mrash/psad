
BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}

$loaded = 1;
print "ok 1\n";

#use diagnostics;
use NetAddr::IP::Lite;

$| = 1;

my $test = 2;

sub ok() {
  print 'ok ',$test++,"\n";
}

$exp = '0:0:0:0:0:0:7F00:0/104';
my $ip = new6 NetAddr::IP::Lite('127.0.0.0/8');
print "exp $exp\ngot ", $ip, "\nnot "
	unless $ip eq $exp;
&ok;

$ip = new6 NetAddr::IP::Lite('127/8');
print "exp $exp\ngot ", $ip, "\nnot "
        unless $ip eq $exp;
&ok;
