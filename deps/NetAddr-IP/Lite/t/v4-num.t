use NetAddr::IP::Lite;

my $nets = {
    '10.1.2.3'		=> [ 32, 0 ],
    '10.2.3.4'		=> [ 31, 1 ],
    '10.0.0.16'		=> [ 24, 255 ],
    '10.128.0.1'	=> [ 8, 2 ** 24 - 1 ],
    '10.0.0.5'		=> [ 30, 3 ],
};

my $new = 1;		# flag for old vs new numeric returns

$| = 1;

$test = keys %$nets;
$test *= 2;
print "1..", $test, "\n";

$test = 1;
sub tst {
  for my $a (keys %$nets) {
    my $nc = $nets->{$a}->[1] - $new;	# net count
    $nc = 1 if $nc < 0;
    $nc = 2 if $new && $nets->{$a}->[0] == 31;	# special case for /31, /127
    my $ip = new NetAddr::IP::Lite $a, $nets->{$a}->[0];
    print "got: $_, exp: $nc\nnot "
	unless ($_ = $ip->num) == $nc;
    print "ok ", $test++, "\n";
  }
}

tst();

import NetAddr::IP::Lite qw(:old_nth);
$new = 0;
tst();
