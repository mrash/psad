use NetAddr::IP::Lite;

$| = 1;

my @deltas = (0, 1, 2, 3, 255);

print "1..", 15 + @deltas, "\n";

my $count = 1;

for (my $ip = new NetAddr::IP::Lite '10.0.0.1/28';
     $ip < $ip->broadcast;
     $ip ++)
{
    my $o = $ip->addr;

    $o =~ s/^.+\.(\d+)$/$1/;

    if ($o == $count) {
	print "ok $count\n";
    }
    else {
	print "not ok $count\n";
    }

    ++ $count;
}

my $ip = new NetAddr::IP::Lite '10.0.0.255/24';
$ip ++;

if ($ip eq '10.0.0.0/24') {
    print "ok $count\n";
}
else {
    print "not ok $count\n";
}

++$count;

$ip = new NetAddr::IP::Lite '10.0.0.0/24';

for my $v (@deltas) {
    if ($ip + $v eq '10.0.0.' . $v . '/24') {
	print "ok $count\n";
    }
    else {
	print "not ok $count\n";
    }
    ++ $count;
}
