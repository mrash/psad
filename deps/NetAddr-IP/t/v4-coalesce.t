use Test::More;

if (defined($ENV{LIGHTERIPTESTS}) and $ENV{LIGHTERIPTESTS} =~ /yes/i) {
    print "1..0 # Skipped: LIGHTERIPTESTS = yes\n";
    exit 0;
}

plan tests => 21;

die "# Cannot continue without NetAddr::IP\n"
    unless use_ok('NetAddr::IP', 'Coalesce');

# Test a rather large set...

my @ips = ();

for my $o (0 .. 255)
{
    push @ips, new NetAddr::IP "10.0.$o.1";
    push @ips, new NetAddr::IP "10.0.$o.10";
    push @ips, new NetAddr::IP "10.0.$o.100";
}

sub tst {
# This should return the empty list...
  my $r = Coalesce(24, 4, @ips);
  diag "Coalesce returned $r"
    unless isa_ok($r, 'ARRAY', 'Return type from Coalesce');
  is(@$r, 0, "Empty array returned as expected");

# This should produce a list with all the /24s
  $r = Coalesce(24, 2, @ips);
  diag "Coalesce returned $r"
    unless isa_ok($r, 'ARRAY', 'Return type from Coalesce');
  is(@$r, 256, "Whole result set as expected");
  my @c = NetAddr::IP::Compact(@$r);
  is(@c, 1, "Results are compactable");
  ok($c[0] eq '10.0.0.0/16', "Correct results");

# This should produce the same result as before, with an added /23
  $r = Coalesce(24, 2, @ips, NetAddr::IP->new('10.0.0.125/23'));
  diag "Coalesce returned $r"
    unless isa_ok($r, 'ARRAY', 'Return type from Coalesce');
  ok((grep { $_ eq '10.0.0.0/23' } @$r), "/23 went through");
  @c = NetAddr::IP::Compact(@$r);
  is(@c, 1, "Results are compactable");
  ok($c[0] eq '10.0.0.0/16', "Correct results");
}

tst();

import NetAddr::IP qw(:old_nth);

tst();
