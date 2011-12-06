#!/usr/bin/perl
use Math::BigInt;
use NetAddr::IP::Util qw(
	bcd2bin
	ipv6_n2x
);

my $data = q|
          got: '340282366920938963520000944000010176000'
#     expected: '340282366920938463463374607431768211455'

#   Failed test 'cafe:cafe::/64 Scalar numeric ok'
#   at t/v6-numeric.t line 57.
#          got: '269827015721314205120005577600083392000'
#     expected: '269827015721314068804783158349174669312'

#   Failed test 'cafe:cafe::/64 Array numeric ok for network'
#   at t/v6-numeric.t line 58.
#          got: '269827015721314205120005577600083392000'
#     expected: '269827015721314068804783158349174669312'

#   Failed test 'cafe:cafe::/64 Array numeric ok for mask'
#   at t/v6-numeric.t line 59.
#          got: '340282366920938963520000944000010176000'
#     expected: '340282366920938463444927863358058659840'

#   Failed test 'cafe:cafe::1/64 Scalar numeric ok'
#   at t/v6-numeric.t line 57.
#          got: '269827015721314205120005577600083392000'
#     expected: '269827015721314068804783158349174669313'

#   Failed test 'cafe:cafe::1/64 Array numeric ok for network'
#   at t/v6-numeric.t line 58.
#          got: '269827015721314205120005577600083392000'
#     expected: '269827015721314068804783158349174669313'

#   Failed test 'cafe:cafe::1/64 Array numeric ok for mask'
#   at t/v6-numeric.t line 59.
#          got: '340282366920938963520000944000010176000'
#     expected: '340282366920938463444927863358058659840'

#   Failed test 'dead:beef::/100 Scalar numeric ok'
#   at t/v6-numeric.t line 57.
#          got: '295990755014136299520006003200014752000'
#     expected: '295990755014133383690938178081940045824'

#   Failed test 'dead:beef::/100 Array numeric ok for network'
#   at t/v6-numeric.t line 58.
#          got: '295990755014136299520006003200014752000'
#     expected: '295990755014133383690938178081940045824'

#   Failed test 'dead:beef::/100 Array numeric ok for mask'
#   at t/v6-numeric.t line 59.
#          got: '340282366920938963520000944000010176000'
#     expected: '340282366920938463463374607431499776000'

#   Failed test 'dead:beef::1/100 Scalar numeric ok'
#   at t/v6-numeric.t line 57.
#          got: '295990755014136299520006003200014752000'
#     expected: '295990755014133383690938178081940045825'

#   Failed test 'dead:beef::1/100 Array numeric ok for network'
#   at t/v6-numeric.t line 58.
#          got: '295990755014136299520006003200014752000'
#     expected: '295990755014133383690938178081940045825'

#   Failed test 'dead:beef::1/100 Array numeric ok for mask'
#   at t/v6-numeric.t line 59.
#          got: '340282366920938963520000944000010176000'
#     expected: '340282366920938463463374607431499776000'
|;

my @trial = split("\n",$data);
my @data;
foreach(@trial) {
  if ($_ =~ /(?:got|expected)\:\s+\'(\d+)/) {
    push @data,$1;
  }
}

#for(my $i=0;$i <= $#data;$i +=2) {
#  print $data[$i]," -\n";
#  print $data[$i +1]," =\n";
#  my $x = Math::BigInt->new($data[$i]);
#  my $y = Math::BigInt->new($data[$i +1]);
#  $x->bsub($y);
#  print $x,"\n\n";
#}

for(my $i=0;$i <= $#data;$i +=2) {
  my $x = ipv6_n2x(bcd2bin($data[$i]));
  print $data[$i],"\t=> $x\n";
  my $y = ipv6_n2x(bcd2bin($data[$i +1]));
  print $data[$i +1],"\t=> $y\n";
}

