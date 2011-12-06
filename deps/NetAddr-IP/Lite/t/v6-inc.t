use Test::More;
use NetAddr::IP::Lite;

# Test ++ in IPv6 addresses (Bug rt.cpan.org #7070 by a guest)

@ip = (NetAddr::IP::Lite->new('2001:468:ff:fffe::2/64'),
       NetAddr::IP::Lite->new('2001:468:ff:fffe::2/64'),
       NetAddr::IP::Lite->new('2001:468:ff:fffe::2/64'));

$ip[1] ++;
$ip[2] ++; $ip[2] ++;

plan tests => 11;

# Test correct v6 creation
isa_ok($_, 'NetAddr::IP::Lite') for @ip;

# Test that we did actually do something
diag "$ip[0] -- $ip[1]"
    unless ok($ip[0] != $ip[1], "Auto incremented once differ");
diag "$ip[0] -- $ip[2]"
    unless ok($ip[0] != $ip[2], "Auto incremented twice differ");
diag "$ip[1] -- $ip[2]"
    unless ok($ip[1] != $ip[2], "Auto incremented two times differ");

# Test that what we did is correct
is($ip[1], $ip[0] + 1, "Test of first auto-increment");
is($ip[2], $ip[0] + 2, "Test of second auto-increment");

# Now test auto-decrement

$ip[1] --;
$ip[2] --; $ip[2] --;

is($ip[0], $ip[1], "Decrement of decrement once is ok");
is($ip[0], $ip[2], "Decrement of decrement twice is ok");
is($ip[1], $ip[2], "Third case");

