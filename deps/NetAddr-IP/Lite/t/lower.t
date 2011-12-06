
#use diagnostics;
use Test::More tests => 2;

use_ok ('NetAddr::IP::Lite', qw(:lower));

my $exp = 'ff:0:0:0:0:0:0:eeaa/128';
my $ip = new NetAddr::IP::Lite('FF::eeAA');
my $got = sprintf $ip;
ok ($got eq $exp,"lower case $got");

