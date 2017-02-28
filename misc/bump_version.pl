#!/usr/bin/perl -w
#
#############################################################################
#
# File: bump_version.pl
#
# Purpose: Minor script to enforce consistency in psad version tags.
#
#############################################################################
#

use strict;

my @files = qw(
    ../psad
    ../nf2csv
);

my $new_version = $ARGV[0] or die "[*] $0 <new version>";

open F, '< ../VERSION' or die "[*] Could not open VERSION file: $!";
my $old_version = <F>;
close F;
chomp $old_version;

print "[+] Updating software versions...\n";
for my $file (@files) {
    if ($file =~ /\.c/) {
        ###*  Version: 1.8.4-pre2
        my $search_re   = qr/^\*\s+Version:\s+$old_version/;
        my $replace_str = '*  Version: ' . $new_version;
        system qq{perl -p -i -e 's|$search_re|} .
            qq{$replace_str|' $file};
    } else {
        ### Version: 1.8.4
        my $search_re   = qr/#\s+Version:\s+$old_version/;
        my $replace_str = '# Version: ' . $new_version;
        system qq{perl -p -i -e 's|$search_re|$replace_str|' $file};
        ### my $version = '1.8.4';
        $search_re   = qr/^my\s+\x24version\s+=\s+'$old_version';/;
        $replace_str = q|my \x24version = '| . $new_version . q|';|;
        system qq{perl -p -i -e "s|$search_re|$replace_str|" $file};
    }
}
system qq{perl -p -i -e 's|$old_version|$new_version|' ../VERSION};

exit 0;
