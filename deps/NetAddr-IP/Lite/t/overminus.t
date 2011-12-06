
#use diagnostics;
use Test::More tests => 32;
use NetAddr::IP::Lite;

my $ip80 = new NetAddr::IP::Lite('::1:8000:0/80');
my $ip7f = $ip80 - 1;
my $maxplus = 2147483647;
my $maxminus = 2147483648;

my $rv;

my $ipmax = $ip80 + $maxplus;
ok(($rv = sprintf("%s",$ipmax)) eq '0:0:0:0:0:1:FFFF:FFFF/80',"ip80 maxplus eq $rv eq 0:0:0:0:0:1:FFFF:FFFF/80");

my $ipmin = $ip80 - $maxminus;
ok(($rv = sprintf("%s",$ipmin)) eq '0:0:0:0:0:1:0:0/80',"ip80 maxminus€ eq $rv eq 0:0:0:0:0:1:0:0/80");

my $over = $maxplus +1;
ok(($rv = sprintf("%s",$ip80 + $over)) eq '0:0:0:0:0:1:8000:0/80',"ip80 +overange unchanged, $rv");

$over = $maxminus +1;
ok(($rv = sprintf("%s",$ip80 - $over)) eq '0:0:0:0:0:1:8000:0/80',"ip80 -overange unchanged, $rv");


ok(($rv = sprintf("%s",$ip80)) eq '0:0:0:0:0:1:8000:0/80',"ip80 eq $rv eq 0:0:0:0:0:1:8000:0/80");
ok(($rv = sprintf("%s",$ip7f)) eq '0:0:0:0:0:1:7FFF:FFFF/80',"ip7f eq $rv eq 0:0:0:0:0:1:7FFF:FFFF/80");

ok(($rv = $ip80 - $ip7f) == 1,"ip80 - ip7f = $rv");
ok(($rv = $ip7f - $ip80) == -1,"ip7f - ip80 = $rv");

ok(($rv = $ipmax - $ip80) == $maxplus,"ipmax - ip80 = $rv should be $maxplus");
ok(($rv = $ipmin - $ip80) == -$maxminus,"ipmin - ip80 = $rv should be \-$maxminus");

++$ipmax;
--$ipmin;
ok(! defined($ipmax - $ip80),'undefined $ipmax - $ip80 is overange');
ok(! defined($ipmin - $ip80),'undefined $ipmin - $ip80 is -overange');

my $ipx = $ip80->copy + 256;
foreach (1..10) {
  ok(($rv = $ipx - $ip80) == $_ * 256,"$ipx - $ip80 = ". $_*256 ." should be $rv");
  ok(($rv = $ip80 - $ipx) == - $_ * 256,"$ip80 - $ipx = ". -$_*256 ." should be $rv");
  $ipx += 256;
}
