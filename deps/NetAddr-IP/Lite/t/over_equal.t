
#use diagnostics;
use NetAddr::IP::Lite;

$| = 1;

print "1..14\n";

my $test = 1;
sub ok() {
  print 'ok ',$test++,"\n";
}

my $four	= new NetAddr::IP::Lite('0.0.0.4');		# same as 0.0.0.4/32
my $four120	= new NetAddr::IP::Lite('::4/120');	# same as 0.0.0.4/24

my $t432	= '0.0.0.4/32';
my $t4120	= '0:0:0:0:0:0:0:4/120';

my $five	= new NetAddr::IP::Lite('0.0.0.5');
my $t532	= '0.0.0.5/32';


# 1
## test '""' overload
my $txt = sprintf ("%s",$four120);

print "got: $txt, exp: $t4120\nnot "
	unless $txt eq $t4120;
&ok;

# 2
## test '""' again
$txt = sprintf ("%s",$four);

print "got: $txt, exp: $t432\nnot "
	unless $txt eq $t432;
&ok;

# 3
## test 'eq' to scalar
print 'failed ',$four," eq $t432\nnot "
	unless $four eq $t432;
&ok;

# 4
## test scalar 'eq' to
print "failed $t432 eq ",$four,"\nnot "
	unless $t432 eq $four;
&ok;

# 5
## test 'eq' to self
print 'failed ',$four,' eq ', $four,"\nnot "
	unless $four eq $four;
&ok;

# 6
## test 'eq' cidr !=
print 'failed ',$four,' should not eq ',$four120,"\nnot "
	if $four eq $four120;
&ok;

# 7
## test '==' not for scalars
print "failed scalar $t432 should not == ",$four,"\nnot "
	if $t432 == $four;
&ok;

# 8
## test '== not for scalar, reversed args
print 'failed scalar ',$four," should not == $t432\nnot "
	if $four == $t432;
&ok;

# ==========================================
#
# test "ne" and "!="
#
# 9
## test 'ne' to scalar
print 'failed ',$four120," ne $t432\nnot "
	unless $four120 ne $t432;
&ok;

# 10
## test scalar 'ne' to
print "failed $t432 ne ",$four120,"\nnot "
	unless $t432 ne $four120;
&ok;

# 11
## test 'ne' to cidr
print 'failed ',$four,' ne ', $four120,"\nnot "
	unless $four ne $four120;
&ok;

# 12
## test '!=' not for scalar, reversed args
$rv = $five != $four ? 1 : 0;
#print "rv=$rv\n";
print "failed scalar $five != $four\nnot "
	unless $rv;
&ok;

# unblessed scalars not welcome
undef local $^W;
# 13
## test '!=' not for scalars
my $rv = $t432 != $five ? 1 : 0;
#print "rv=$rv\n";
print "failed scalar $t432  != ",$five,"\nnot "
	unless $rv;
&ok;

# 14
# since both of these are string scalars, the != should fail
$rv = $t532 != $t432 ? 1 : 0;
#print "rv = $rv\n";
print "failed scalar $t532 != $t432\nnot "
	if $rv;
&ok;
