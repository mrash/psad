
use strict;
use Test::More;

use NetAddr::IP::Lite;
#use NetAddr::IP::Util qw(
#	bcd2bin
#	ipv6_n2x
#	bin2bcd
#);
#use Data::Dumper;

my @num = qw(
	2001:468:D01:3C:0:0:80DF:3C1B/128	42540577535367674011024906890208295963
	73.150.6.197/32				1234568901
	128.0.0.0/32				2147483648
	0:0:0:0:0:1:0:0/128			4294967296
	0:0:0:0:0:2:0:0/128			8589934592
	0:0:0:0:0:2:540B:E400/128		10000000000
	0:0:0:0:0:4:0:0/128			17179869184
	0:0:0:0:0:8:0:0/128			34359738368
	0:0:0:0:0:10:0:0/128			68719476736
	0:0:0:0:0:20:0:0/128			137438953472
	0:0:0:0:0:40:0:0/128			274877906944
	0:0:0:0:0:80:0:0/128			549755813888
	0:0:0:0:0:100:0:0/128			1099511627776
	0:0:0:0:0:200:0:0/128			2199023255552
	0:0:0:0:0:400:0:0/128			4398046511104
	0:0:0:0:0:800:0:0/128			8796093022208
	0:0:0:0:0:1000:0:0/128			17592186044416
	0:0:0:0:0:2000:0:0/128			35184372088832
	0:0:0:0:0:4000:0:0/128			70368744177664
	0:0:0:0:0:8000:0:0/128			140737488355328
	0:0:0:0:8000:0:0:0/128			9223372036854775808
	0:0:0:8000:0:0:0:0/128			604462909807314587353088
	0:0:8000:0:0:0:0:0/128			39614081257132168796771975168
	0:8000:0:0:0:0:0:0/128			2596148429267413814265248164610048
	8000:0:0:0:0:0:0:0/128			170141183460469231731687303715884105728
	255.255.255.255/32			4294967295
	1.2.3.4/32				16909060
	10.253.230.9/32				184411657
);

plan tests => scalar @num;

#diag ("\ntesting SCALARS\n\n");

for(my $i = 0;$i <= $#num;$i += 2) {
  my $n = $num[$i +1];
  my $ip  = new NetAddr::IP::Lite($n);
  ok($ip eq $num[$i],"$n\t=> got: $ip\texp: ". $num[$i]);
}

#diag ("\ntesting Math::BigInt's\n\n");

for(my $i = 0;$i <= $#num;$i += 2) {
  my $n = new Math::BigInt($num[$i +1]);
  my $ip  = new NetAddr::IP::Lite($num[$i +1]);
  ok($ip eq $num[$i],"$n\t=> got: $ip\texp: ". $num[$i]);
}




# simulate the use of Math::BigInt

package Math::BigInt;
use strict;

use overload
'""'	=> sub { $_[0]->_str(); };

sub BASE_LEN () { 7 };

sub _str {					# adapted from Math::BigInt::Calc::_str
  # (ref to BINT) return num_str
  # Convert number from internal base 100000 format to string format.
  # internal format is always normalized (no leading zeros, "-0" => "+0")
  my $ar = $_[0]->{value};

  my $l = scalar @$ar;				# number of parts
  my $ret = "";
  # handle first one different to strip leading zeros from it (there are no
  # leading zero parts in internal representation)
  $l --; $ret .= int($ar->[$l]); $l--;
  # Interestingly, the pre-padd method uses more time
  # the old grep variant takes longer (14 vs. 10 sec)
  my $z = '0' x (BASE_LEN -1);			    
  while ($l >= 0)
    {
    $ret .= substr($z.$ar->[$l],- BASE_LEN);	# fastest way I could think of
    $l--;
    }
  $ret;
}

sub new {		# adapted from Math::BigInt::new
  my ($class,$wanted) = @_;
  my $self = bless {}, $class;

  die "oops, not a good Math::BigInt number"
	unless  ((!ref $wanted) && ($wanted =~ /^([+-]?)[1-9][0-9]*\z/));
  $self->{sign} = $1 || '+';

  if ($wanted =~ /^[+-]/) {
# remove sign without touching wanted to make it work with constants
    my $t = $wanted; $t =~ s/^[+-]//;
    $self->{value} = _new($t);
  }
  else {
    $self->{value} = _new($wanted);
  }
  return $self;
}

sub _new {		# adapted from Math::BigInt::Calc::_new
  my $wanted = $_[0];
  # (ref to string) return ref to num_array
  # Convert a number from string format (without sign) to internal base
  # 1ex format. Assumes normalized value as input.
  my $il = length($wanted)-1;

  # < BASE_LEN due len-1 above
  return [ int($wanted) ] if $il < BASE_LEN;		# shortcut for short numbers

  my $base_len = BASE_LEN;
  # this leaves '00000' instead of int 0 and will be corrected after any op
  [ reverse(unpack("a" . ($il % BASE_LEN +1) 
    . ("a$base_len" x ($il / BASE_LEN)), $wanted)) ];
}
