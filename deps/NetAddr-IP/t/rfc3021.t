use NetAddr::IP;

$| = 1;

print '1..4', "\n";

my $test = 1;

my $ip = new NetAddr::IP('192.168.1.8/31');
my @hosts = $ip->hostenum;

print scalar(@hosts)," found where none expected\nnot "
	if @hosts;
print "ok ",$test++,"\n";

NetAddr::IP::import qw(:rfc3021);

@hosts = $ip->hostenum;

print scalar(@hosts)," found where 2 expected\nnot "
	unless @hosts == 2;
print "ok ",$test++,"\n";

print "got: $hosts[0], exp: 192.168.1.8/32\nnot "
	unless "$hosts[0]" eq '192.168.1.8/32';
print "ok ",$test++,"\n";

print "got: $hosts[1], exp: 192.168.1.9/32\nnot "
	unless "$hosts[1]" eq '192.168.1.9/32';
print "ok ",$test++,"\n";

