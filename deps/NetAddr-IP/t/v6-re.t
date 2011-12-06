#use diagnostics;
use Test::More;
use NetAddr::IP;
use NetAddr::IP::Util qw(addconst);

my @ips = qw!
	::0:0f00
	::FF:1e10
	::ffFF:2d20
	::eFF:3c30
	::eeFF:4b40
	::FF:5a50
	::FF:6960
	::FF:7870
	::FF:8780
	::FF:9690
	::FF:a5a0
	::FF:b4b0
	::FF:c3c0
	::FF:d2d0
	::FF:e1e0
	::FF:f0f0
!;
my @mask = qw! 127 126 125 124 123 122 121 120 !;

if (defined($ENV{LIGHTERIPTESTS}) and $ENV{LIGHTERIPTESTS} =~ /yes/i) {
  pop @mask; pop @mask;
}

my $tests = 0;
my @addrs;
foreach(@mask) {
  foreach my $ip (@ips) {
    push @addrs, new NetAddr::IP($ip,$_);
  }
  $tests += ((2**(128 - $_)) * @ips)
}

$tests += (5 * @ips * @mask);

plan tests => $tests;

for my $a (@addrs)
{
    isa_ok($a, 'NetAddr::IP');
    my $re = $a->re6;
    my $rx;

    eval { $rx = qr/$re/ };
    diag "Compilation of the resulting regular expression failed: $@"
	unless ok(!$@, "Compilation of the resulting regular expression");

    for (my $ip = $a->network;
	 $ip < $a->broadcast && $a->masklen != 128;
	 $ip ++)
    {
	ok($a->addr =~ m/$rx/, "Match of $ip in $a");
    }

    ok($a->broadcast->addr =~ m/$rx/, "Match of broadcast of $a");
    my $under = $a->network->copy;
    $under->{addr} = (addconst($under->{addr},-1))[1];
    my $over = $a->broadcast->copy;
    $over->{addr} = (addconst($over->{addr},1))[1];
    ok($under !~ m/$rx/, "$under does not match");
    ok($over !~ m/$rx/, "$over does not match");
    ok(NetAddr::IP->new('::') !~ m/$rx/, ":: does not match");
}

