# $Id: loops.t,v 1.2 2006/08/16 19:17:01 lem Exp $

use Test::More;

my @deltas = (0, 1, 2, 3, 255);

plan tests => 16 + @deltas;

use_ok('NetAddr::IP');
my $count = 1;

for (my $ip = new NetAddr::IP '10.0.0.1/28';
     $ip < $ip->broadcast;
     $ip ++)
{
    my $o = $ip->addr;

    $o =~ s/^.+\.(\d+)$/$1/;
    is($o, $count, "Correct octet for " . $ip);
    ++ $count;
}

my $ip = new NetAddr::IP '10.0.0.255/24';
$ip ++;

is($ip, '10.0.0.0/24', "Correct mask wraparound");

$ip = new NetAddr::IP '10.0.0.0/24';

for my $v (@deltas) {
    my $target = '10.0.0.' . $v . '/24';
    is($ip + $v, '10.0.0.' . $v . '/24', "$ip + $v vs $target");
}
