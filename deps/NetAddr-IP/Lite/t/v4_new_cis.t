#use diagnostics;
use NetAddr::IP::Lite;

use Test::More;

my $binword;
{
  local $SIG{__WARN__} = sub {};
  $binword = eval "0b11111111111111110000000000000000";
}
if ($@) {
  $binword = 0xffff0000;
  print STDERR "\t\tskipped! 0b11111111111111110000000000000000\n\t\tbinary bit strings unsupported in Perl version $]\n";
}

@a = (
	  [ 'localhost', '127.0.0.1' ],
	  [ 0x01010101, '1.1.1.1' ],
	  [ 1, '1.0.0.0' ],	# Because it will have a mask. 0.0.0.1 ow
	  [ 'default', '0.0.0.0' ],
	  [ 'any', '0.0.0.0' ],
	  [-809041407, '207.199.2.1'],
	  [3485925889, '207.199.2.1'],
);

@m = (
	 [ 0, '0.0.0.0' ],
	 [ 1, '128.0.0.0' ],
	 [ 2, '192.0.0.0' ],
	 [ 4, '240.0.0.0' ],
	 [ 8, '255.0.0.0' ],
	 [ 16, '255.255.0.0' ],
	 [ 17, '255.255.128.0' ],
	 [ 24, '255.255.255.0' ],
	 [ 'default', '0.0.0.0' ],
	 [ 32, '255.255.255.255' ],
	 [ 'host', '255.255.255.255' ],
	 [ 0xffffff00, '255.255.255.0' ],
	 [ '255.255.255.240', '255.255.255.240' ],
	 [ '255.255.128.0', '255.255.128.0' ],
	 [ $binword, '255.255.0.0' ],
);

plan tests => (4 * scalar @a * scalar @m) + 4;

foreach my $invalid (qw(
	256.1.1.1
	256.256.1.1
	256.256.256.1
	256.256.256.256
)) {
  ok (! defined NetAddr::IP::Lite->new($invalid), "Invalid IP $invalid returns undef");
}

for my $a (@a) {
    for my $m (@m) {
	my $ip = new_cis NetAddr::IP::Lite "$a->[0] $m->[0]";
      SKIP:
	{
	    skip "Failed to make an object for $a->[0]/$m->[0]", 4
		unless defined $ip;
	    is($ip->addr, $a->[1], "$a->[0] / $m->[0] is $a->[1]");
	    is($ip->mask, $m->[1], "$a->[0] / $m->[0] is $m->[1]");
	    is($ip->bits, 32, "$a->[0] / $m->[0] is 32 bits wide");
	    is($ip->version, 4, "$a->[0] / $m->[0] is version 4");
	};
    }
}
