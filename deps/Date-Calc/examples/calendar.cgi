#!perl -w

###############################################################################
##                                                                           ##
##    Copyright (c) 2001, 2002 by Steffen Beyer.                             ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This program is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

           #########################################################
           ##                                                     ##
           ##    See http://www.engelschall.com/u/sb/calendar/    ##
           ##    for a "live" example of this CGI script.         ##
           ##                                                     ##
           #########################################################

use strict;

use Date::Calc qw(:all);
use Date::Calendar::Profiles qw($Profiles);
use Date::Calendar;

my $filler   = '<P>&nbsp;</P>';

my $language = 3;
my $country  = 'DE-BW';
my $select   = 0;
my $fullyear = 0;

my @html     = ();
my @start    = ();
my @marksele = ();
my @markyear = ();
my @language = ();
my @sortlang = ();
my @marklang = ();
my %profiles = ();
my %sortprof = ();
my %markprof = ();
my %sdm      = ();

&init_tables();

&process_profiles();

&process_query_string();

&set_defaults();

&print_page();

exit 0;

sub init_tables()
{
    my $i;
    local $_;

    $html[0x00] = '';
    $html[0x01] = '';
    $html[0x02] = '';
    $html[0x03] = '';
    $html[0x04] = '';
    $html[0x05] = '';
    $html[0x06] = '';
    $html[0x07] = '';
    $html[0x08] = '';
    # $html[0x09] = '';
    # $html[0x0A] = '';
    $html[0x0B] = '';
    $html[0x0C] = '';
    $html[0x0D] = '';
    $html[0x0E] = '';
    $html[0x0F] = '';
    $html[0x10] = '';
    $html[0x11] = '';
    $html[0x12] = '';
    $html[0x13] = '';
    $html[0x14] = '';
    $html[0x15] = '';
    $html[0x16] = '';
    $html[0x17] = '';
    $html[0x18] = '';
    $html[0x19] = '';
    $html[0x1A] = '';
    $html[0x1B] = '';
    $html[0x1C] = '';
    $html[0x1D] = '';
    $html[0x1E] = '';
    $html[0x1F] = '';
    $html[0x22] = '&quot;';
    $html[0x26] = '&amp;';
    # $html[0x27] = '&apos;';
    $html[0x3C] = '&lt;';
    $html[0x3E] = '&gt;';
    $html[0x7F] = '';
    $html[0x80] = '';
    $html[0x81] = '';
    $html[0x82] = '';
    $html[0x83] = '';
    $html[0x84] = '';
    $html[0x85] = '';
    $html[0x86] = '';
    $html[0x87] = '';
    $html[0x88] = '';
    $html[0x89] = '';
    $html[0x8A] = '';
    $html[0x8B] = '';
    $html[0x8C] = '';
    $html[0x8D] = '';
    $html[0x8E] = '';
    $html[0x8F] = '';
    $html[0x90] = '';
    $html[0x91] = '';
    $html[0x92] = '';
    $html[0x93] = '';
    $html[0x94] = '';
    $html[0x95] = '';
    $html[0x96] = '';
    $html[0x97] = '';
    $html[0x98] = '';
    $html[0x99] = '';
    $html[0x9A] = '';
    $html[0x9B] = '';
    $html[0x9C] = '';
    $html[0x9D] = '';
    $html[0x9E] = '';
    $html[0x9F] = '';
    $html[0xA0] = '&nbsp;';
    $html[0xA1] = '&iexcl;';
    $html[0xA2] = '&cent;';
    $html[0xA3] = '&pound;';
    $html[0xA4] = '&curren;';
    $html[0xA5] = '&yen;';
    $html[0xA6] = '&brvbar;';
    $html[0xA7] = '&sect;';
    $html[0xA8] = '&uml;';
    $html[0xA9] = '&copy;';
    $html[0xAA] = '&ordf;';
    $html[0xAB] = '&laquo;';
    $html[0xAC] = '&not;';
    $html[0xAD] = '&shy;';
    $html[0xAE] = '&reg;';
    $html[0xAF] = '&macr;';
    $html[0xB0] = '&deg;';
    $html[0xB1] = '&plusmn;';
    $html[0xB2] = '&sup2;';
    $html[0xB3] = '&sup3;';
    $html[0xB4] = '&acute;';
    $html[0xB5] = '&micro;';
    $html[0xB6] = '&para;';
    $html[0xB7] = '&middot;';
    $html[0xB8] = '&cedil;';
    $html[0xB9] = '&sup1;';
    $html[0xBA] = '&ordm;';
    $html[0xBB] = '&raquo;';
    $html[0xBC] = '&frac14;';
    $html[0xBD] = '&frac12;';
    $html[0xBE] = '&frac34;';
    $html[0xBF] = '&iquest;';
    $html[0xC0] = '&Agrave;';
    $html[0xC1] = '&Aacute;';
    $html[0xC2] = '&Acirc;';
    $html[0xC3] = '&Atilde;';
    $html[0xC4] = '&Auml;';
    $html[0xC5] = '&Aring;';
    $html[0xC6] = '&AElig;';
    $html[0xC7] = '&Ccedil;';
    $html[0xC8] = '&Egrave;';
    $html[0xC9] = '&Eacute;';
    $html[0xCA] = '&Ecirc;';
    $html[0xCB] = '&Euml;';
    $html[0xCC] = '&Igrave;';
    $html[0xCD] = '&Iacute;';
    $html[0xCE] = '&Icirc;';
    $html[0xCF] = '&Iuml;';
    $html[0xD0] = '&ETH;';
    $html[0xD1] = '&Ntilde;';
    $html[0xD2] = '&Ograve;';
    $html[0xD3] = '&Oacute;';
    $html[0xD4] = '&Ocirc;';
    $html[0xD5] = '&Otilde;';
    $html[0xD6] = '&Ouml;';
    $html[0xD7] = '&times;';
    $html[0xD8] = '&Oslash;';
    $html[0xD9] = '&Ugrave;';
    $html[0xDA] = '&Uacute;';
    $html[0xDB] = '&Ucirc;';
    $html[0xDC] = '&Uuml;';
    $html[0xDD] = '&Yacute;';
    $html[0xDE] = '&THORN;';
    $html[0xDF] = '&szlig;';
    $html[0xE0] = '&agrave;';
    $html[0xE1] = '&aacute;';
    $html[0xE2] = '&acirc;';
    $html[0xE3] = '&atilde;';
    $html[0xE4] = '&auml;';
    $html[0xE5] = '&aring;';
    $html[0xE6] = '&aelig;';
    $html[0xE7] = '&ccedil;';
    $html[0xE8] = '&egrave;';
    $html[0xE9] = '&eacute;';
    $html[0xEA] = '&ecirc;';
    $html[0xEB] = '&euml;';
    $html[0xEC] = '&igrave;';
    $html[0xED] = '&iacute;';
    $html[0xEE] = '&icirc;';
    $html[0xEF] = '&iuml;';
    $html[0xF0] = '&eth;';
    $html[0xF1] = '&ntilde;';
    $html[0xF2] = '&ograve;';
    $html[0xF3] = '&oacute;';
    $html[0xF4] = '&ocirc;';
    $html[0xF5] = '&otilde;';
    $html[0xF6] = '&ouml;';
    $html[0xF7] = '&divide;';
    $html[0xF8] = '&oslash;';
    $html[0xF9] = '&ugrave;';
    $html[0xFA] = '&uacute;';
    $html[0xFB] = '&ucirc;';
    $html[0xFC] = '&uuml;';
    $html[0xFD] = '&yacute;';
    $html[0xFE] = '&thorn;';
    $html[0xFF] = '&yuml;';
    $start[0] = [Today()];
    $start[1] = [Week_of_Year(@{$start[0]})];
    for ( $i = 1; $i <= Languages(); $i++ )
    {
        $_ = Language_to_Text($i);
        $language[$i] = html($_);
        $sortlang[$i] = iso_coll(iso_lc($_));
    }
    %sdm =
    (
        'BLN' => 'Berlin',
        'BON' => 'Bonn',
        'CGN' => 'Köln',
        'DET' => 'Detroit (USA)',
        'FFM' => 'Frankfurt a.M.',
        'HAN' => 'Hannover',
        'HH'  => 'Hamburg',
        'MUC' => 'München',
        'RAT' => 'Ratingen (Düsseldorf)',
        'STG' => 'Stuttgart',
        'ZRH' => 'Zürich (Schweiz)'
    );
    %profiles = map { $_, $_ } keys(%{$Profiles});
}

sub process_profiles()
{
    my $profile = $INC{'Date/Calendar/Profiles.pm'};
    my($read,$cache,$line,$key);

    $read = 1;
    if (defined($profile) and $profile ne '' and -f $profile and -r $profile and -s $profile)
    {
        $cache = $0;
        $cache =~ s!\.+[^/\\\.]*$!!;
        $cache .= ".cache";
        if (!(-f $cache and -s $cache) or ((stat($cache))[9] < (stat($profile))[9]))
        {
            if (open(PROFILE, "<$profile"))
            {
                if (open(CACHE, ">$cache"))
                {
                    while (defined ($line = <PROFILE>))
                    {
                        if ($line =~ m!^\s*\$Profiles->{'([A-Za-z]+(?:-[A-Za-z]+)?)'}\s*=\s*\#\s*(.+?)\s*$!)
                        {
                            $profiles{$1} = $2;
                        }
                    }
                    foreach $key (keys %profiles)
                    {
                        if ($key =~ m!^([A-Za-z]+)-([A-Za-z]+)$! and defined $profiles{$1})
                        {
                            if ($1 eq 'sdm')
                            {
                                $profiles{$key} = $profiles{$1} . " - " . $sdm{$2};
                            }
                            else
                            {
                                $profiles{$key} = $profiles{$1} . " - " . $profiles{$key};
                            }
                        }
                    }
                    foreach $key (sort keys(%profiles))
                    {
                        printf(CACHE "%8s => %s\n", $key, $profiles{$key});
                        $read = 0;
                    }
                    close(CACHE);
                }
                close(PROFILE);
            }
        }
    }
    if ($read and -f $cache and -r $cache and -s $cache)
    {
        if (open(CACHE, "<$cache"))
        {
            while (defined ($line = <CACHE>))
            {
                if ($line =~ m!^\s*([A-Za-z]+(?:-[A-Za-z]+)?)\s*=>\s*(.+?)\s*$!)
                {
                    $profiles{$1} = $2;
                }
            }
            close(CACHE);
        }
    }
    foreach $key (keys(%profiles))
    {
        $line = $profiles{$key};
        $profiles{$key} = html($line);
        $sortprof{$key} = iso_coll(iso_lc($line));
    }
}

sub process_query_string()
{
    my $query = $ENV{'QUERY_STRING'} || $ENV{'REDIRECT_QUERY_STRING'} || '';
    my @pairs = split(/&/, $query);
    my($pair,$var,$val);

    foreach $pair (@pairs)
    {
        ($var,$val) = split(/=/,$pair,2);
        if ($var =~ m!^[a-z]+$!)
        {
            if    ($var eq 'select')
            {
                if ($val =~ m!^[0-9]+$!) { $select = $val ? 1 : 0; }
            }
            elsif ($var eq 'fullyear')
            {
                if ($val =~ m!^[0-9]+$! and $val >= 0 and $val <= 2) { $fullyear = $val; }
            }
            elsif ($var eq 'language')
            {
                if ($val =~ m!^[0-9]+$! and $val >= 1 and $val <= Languages()) { $language = $val; }
            }
            elsif ($var eq 'country')
            {
                if ($val =~ m!^[A-Za-z]+(?:-[A-Za-z]+)?$! and defined $profiles{$val}) { $country = $val; }
            }
            elsif ($var eq 'myear')
            {
                if ($val =~ m!^[0-9]+$! and $val >= 1583 and $val <= 2299) { $start[0][0] = $val; }
            }
            elsif ($var eq 'month')
            {
                if ($val =~ m!^[0-9]+$! and $val >= 1 and $val <= 12) { $start[0][1] = $val; }
            }
            elsif ($var eq 'week')
            {
                if ($val =~ m!^[0-9]+$! and $val >= 1 and $val <= 53) { $start[1][0] = $val; }
            }
            elsif ($var eq 'wyear')
            {
                if ($val =~ m!^[0-9]+$! and $val >= 1583 and $val <= 2299) { $start[1][1] = $val; }
            }
        }
    }
}

sub set_defaults()
{
    my $year;
    local $_;

    @marksele = ('', '');
    @markyear = ('', '', '');
    @marklang = ('') x (Languages() + 1);
    %markprof = map { $_, '' } keys(%profiles);

    $marksele[$select]   = ' CHECKED';
    $markyear[$fullyear] = ' CHECKED';
    $marklang[$language] = ' SELECTED';
    $markprof{$country}  = ' SELECTED';

    if ($fullyear > 0)
    {
        if ($select) { $year = $start[1][1]; }
        else         { $year = $start[0][0]; }
        $start[0] = [$year,1,1];
        $start[1] = [1,$year];
        $start[2] = Days_in_Year($year,12);
        $start[3] = [$year-1,1,1];
        $start[4] = [1,$year-1];
        $start[5] = [$year+1,1,1];
        $start[6] = [1,$year+1];
    }
    else
    {
        if ($select)
        {
            $_ = Weeks_in_Year($start[1][1]);
            $start[1][0] = $_ if ($start[1][0] > $_);
            $start[0] = [Monday_of_Week(@{$start[1]})];
            $start[2] = 28;
            $start[3] = [Add_Delta_Days(@{$start[0]},-28)];
            $start[4] = [Week_of_Year(@{$start[3]})];
            $start[5] = [Add_Delta_Days(@{$start[0]},+28)];
            $start[6] = [Week_of_Year(@{$start[5]})];
        }
        else
        {
            $start[0][2] = 1;
            $start[1] = [Week_of_Year(@{$start[0]})];
            $start[2] = Days_in_Month(@{$start[0]}[0,1]);
            $start[3] = [Add_Delta_YM(@{$start[0]},0,-1)];
            $start[4] = [Week_of_Year(@{$start[3]})];
            $start[5] = [Add_Delta_YM(@{$start[0]},0,+1)];
            $start[6] = [Week_of_Year(@{$start[5]})];
        }
    }
    Language($language);
}

sub print_page()
{
    my($i,$key);

    print <<"VERBATIM";
Content-type: text/html

<HTML>
<HEAD>
    <TITLE>Steffen Beyer's International Eternal Gregorian Calendar</TITLE>
</HEAD>
<BODY BGCOLOR="#FFFFFF">
<CENTER>

<P>
<HR NOSHADE SIZE="2">
<P>
    <H1>Steffen Beyer's International Eternal Gregorian Calendar</H1>
<P>
<HR NOSHADE SIZE="2">
<P>

<FORM METHOD="GET" ACTION="">
<TABLE CELLSPACING="0" CELLPADDING="4" BORDER="0"><TR>
<TD ALIGN="left">Your language:</TD>
<TD ALIGN="right" COLSPAN="2"><SELECT NAME="language">
VERBATIM

    foreach $i (sort { $sortlang[$a] cmp $sortlang[$b] } 1..Languages())
    {
        print qq(<OPTION VALUE="$i"$marklang[$i]>$language[$i]\n);
    }

    print <<"VERBATIM";
</SELECT></TD>
</TR><TR>
<TD ALIGN="left">Your country:</TD>
<TD ALIGN="right" COLSPAN="2"><SELECT NAME="country" SIZE="10">
VERBATIM

    foreach $key (sort { $sortprof{$a} cmp $sortprof{$b} } keys(%profiles))
    {
        print qq(<OPTION VALUE="$key"$markprof{$key}>$profiles{$key}\n);
    }

    print <<"VERBATIM";
</SELECT></TD>
</TR><TR>
<TD ALIGN="left">Select by:</TD>
<TD ALIGN="right"><INPUT TYPE="radio" NAME="select" VALUE="0"$marksele[0]>&nbsp;Year and Month</TD>
<TD ALIGN="right"><INPUT TYPE="radio" NAME="select" VALUE="1"$marksele[1]>&nbsp;Week and Year</TD>
</TR><TR>
<TD ALIGN="left">$filler</TD>
<TD ALIGN="right">Year (1583..2299): <INPUT TYPE="text" SIZE="4" MAXLENGTH="4" NAME="myear" VALUE="$start[0][0]"></TD>
<TD ALIGN="right">     Week (1..53): <INPUT TYPE="text" SIZE="4" MAXLENGTH="4" NAME="week"  VALUE="$start[1][0]"></TD>
</TR><TR>
<TD ALIGN="left">$filler</TD>
<TD ALIGN="right">    Month (1..12): <INPUT TYPE="text" SIZE="4" MAXLENGTH="4" NAME="month" VALUE="$start[0][1]"></TD>
<TD ALIGN="right">Year (1583..2299): <INPUT TYPE="text" SIZE="4" MAXLENGTH="4" NAME="wyear" VALUE="$start[1][1]"></TD>
</TR><TR>
<TD ALIGN="left">Show full year:</TD>
<TD ALIGN="right" COLSPAN="2">
<TABLE WIDTH="100%" CELLSPACING="0" CELLPADDING="0" BORDER="0"><TR>
<TD ALIGN="right" WIDTH="20%"><INPUT TYPE="radio" NAME="fullyear" VALUE="0"$markyear[0]>&nbsp;Off</TD>
<TD ALIGN="right" WIDTH="40%"><INPUT TYPE="radio" NAME="fullyear" VALUE="1"$markyear[1]>&nbsp;Days off only</TD>
<TD ALIGN="right" WIDTH="40%"><INPUT TYPE="radio" NAME="fullyear" VALUE="2"$markyear[2]>&nbsp;All named days</TD>
</TR></TABLE>
</TD>
</TR><TR>
<TD ALIGN="center" COLSPAN="3"><INPUT TYPE="reset" VALUE="Reset"></TD>
</TR><TR>
<TD ALIGN="center" COLSPAN="3"><INPUT TYPE="submit" VALUE="Display"></TD>
</TR><TR>
<TD ALIGN="center" COLSPAN="3"><FONT COLOR="#FF0000">Note: Historical irregularities are (usually) not taken into account!</FONT></TD>
</TR></TABLE>
</FORM>

<P>
<HR NOSHADE SIZE="2">
<P>

<TABLE CELLSPACING="1" CELLPADDING="7" BORDER="2">
VERBATIM

    &print_calendar();

    print <<"VERBATIM";
</TABLE>

<P>
<HR NOSHADE SIZE="2">
<P>

<TABLE CELLSPACING="0" CELLPADDING="8" BORDER="0"><TR>

<TD ALIGN="left">
<FORM METHOD="GET" ACTION="">
<INPUT TYPE="hidden" NAME="language" VALUE="$language">
<INPUT TYPE="hidden" NAME="country"  VALUE="$country">
<INPUT TYPE="hidden" NAME="select"   VALUE="$select">
<INPUT TYPE="hidden" NAME="myear"    VALUE="$start[3][0]">
<INPUT TYPE="hidden" NAME="week"     VALUE="$start[4][0]">
<INPUT TYPE="hidden" NAME="month"    VALUE="$start[3][1]">
<INPUT TYPE="hidden" NAME="wyear"    VALUE="$start[4][1]">
<INPUT TYPE="hidden" NAME="fullyear" VALUE="$fullyear">
<INPUT TYPE="submit" VALUE="&nbsp;&lt;&nbsp;&lt;&nbsp;&lt;&nbsp;">
</FORM>
</TD>

<TD WIDTH="50%">
$filler
</TD>

<TD ALIGN="right">
<FORM METHOD="GET" ACTION="">
<INPUT TYPE="hidden" NAME="language" VALUE="$language">
<INPUT TYPE="hidden" NAME="country"  VALUE="$country">
<INPUT TYPE="hidden" NAME="select"   VALUE="$select">
<INPUT TYPE="hidden" NAME="myear"    VALUE="$start[5][0]">
<INPUT TYPE="hidden" NAME="week"     VALUE="$start[6][0]">
<INPUT TYPE="hidden" NAME="month"    VALUE="$start[5][1]">
<INPUT TYPE="hidden" NAME="wyear"    VALUE="$start[6][1]">
<INPUT TYPE="hidden" NAME="fullyear" VALUE="$fullyear">
<INPUT TYPE="submit" VALUE="&nbsp;&gt;&nbsp;&gt;&nbsp;&gt;&nbsp;">
</FORM>
</TD>

</TR></TABLE>

<P>
<HR NOSHADE SIZE="2">
<P>

<FONT COLOR="#FF0000">Please
<A HREF="mailto:sb\@engelschall.com?subject=Error%20in%20calendar%20web%20page">report</A>
any errors you find on this page!</FONT>

<P>
<HR NOSHADE SIZE="2">
<P>

<A HREF="http://www.engelschall.com/u/sb/download/pkg/Date-Calc-5.3.tar.gz">Download</A>
the Perl software that does all this!

<P>
<HR NOSHADE SIZE="2">
<P>

</CENTER>
</BODY>
</HTML>
VERBATIM
}

sub print_calendar()
{
    my $year  = 0;
    my $index = 0;
    my $oyear = 0;
    my $oweek = 0;
    my $omonth = 0;
    my($calendar,$full,$half,$C,$N,$cell,$week,$dow);
    my(@date,@tags);
    local $_;

    $calendar = Date::Calendar->new( $Profiles->{$country} );

    print <<"VERBATIM";
<TR>
<TD COLSPAN="6" ALIGN="center"><B>$profiles{$country}</B></TD>
</TR>
<TR>
<TD ALIGN="right"><B>Year</B></TD>
<TD ALIGN="right"><B>Week<BR>Number</B></TD>
<TD ALIGN="left" ><B>Day of<BR>Week</B></TD>
<TD ALIGN="left" ><B>Month</B></TD>
<TD ALIGN="right"><B>Day</B></TD>
<TD ALIGN="left" ><B>Name</B></TD>
</TR>
VERBATIM

    @date = @{$start[0]};
    while ($start[2] > 0 and $date[0] <= 2299)
    {
        if ($date[0] >= 1583)
        {
            if ($year != $date[0])
            {
                $year  = $date[0];
                $index = $calendar->date2index(@date);
                $full  = $calendar->year($year)->vec_full();
                $half  = $calendar->year($year)->vec_half();
            }
            if ( ($fullyear == 0) or
                (($fullyear == 2) and ((@tags = $calendar->labels(@date)) > 1)) or
                (($fullyear == 1) and ($full->bit_test($index) or $half->bit_test($index)) and (Day_of_Week(@date) < 6)))
            {
                print "<TR>\n";
                if    ($full->bit_test($index)) { $C = '<FONT COLOR="#FF0000">'; $N = '</FONT>'; }
                elsif ($half->bit_test($index)) { $C = '<FONT COLOR="#CC00CC">'; $N = '</FONT>'; }
                else                            { $C = '';                       $N = '';        }
                if ($oyear != $date[0])
                {
                    $oyear = $date[0];
                    $cell  = "<B>$oyear</B>";
                }
                else { $cell = $filler; }
                print qq(<TD ALIGN="right">$cell</TD>\n);         # Year
                $week = Week_of_Year(@date);
                if ($oweek != $week)
                {
                    $oweek = $week;
                    $cell = "<B>$week</B>";
                }
                else { $cell = $filler; }
                print qq(<TD ALIGN="right">$cell</TD>\n);         # Week Number
                @tags = $calendar->labels(@date) unless ($fullyear == 2);
                $dow = html(shift(@tags));
                print qq(<TD ALIGN="left" >$C$dow$N</TD>\n);      # Day of Week
                if ($omonth != $date[1])
                {
                    $omonth = $date[1];
                    $cell = "<B>" . html(Month_to_Text($omonth)) . "</B>";
                }
                else { $cell = $filler; }
                print qq(<TD ALIGN="left" >$cell</TD>\n);         # Month
                print qq(<TD ALIGN="right">$C$date[2]$N</TD>\n);  # Day
                if (@tags)
                {
                    print
                        qq(<TD ALIGN="left" >\n),
                        join( "<BR>\n", map( html($_), @tags ) ), # Name
                        qq(\n</TD>\n);
                }
                else
                {
                    print qq(<TD ALIGN="left" >$filler</TD>\n);   # Name
                }
                print "</TR>\n";
            }
        }
        if (--$start[2] > 0) { @date = Add_Delta_Days(@date,1); $index++; }
    }
}

sub html($)
{
    my $string = $_[0];
    my $o;
    $string =~ s!(.)!(defined $html[$o=ord($1)])?($html[$o]||"&\#$o;"):$1!eg;
    $string;
}

sub iso_lc($)
{
    my $string = $_[0];
    $string =~ tr/\x41-\x5A\xC0-\xD6\xD8-\xDE\x8A\x8C\x9F/\x61-\x7A\xE0-\xF6\xF8-\xFE\x9A\x9C\xFF/;
    $string;
}

sub iso_coll($)
{
    my $string = $_[0];
    $string =~ s/\xC4/Ae/g; # German
    $string =~ s/\xE4/ae/g;
    $string =~ s/\xD6/Oe/g;
    $string =~ s/\xF6/oe/g;
    $string =~ s/\xDC/Ue/g;
    $string =~ s/\xFC/ue/g;
    $string =~ s/\xDF/ss/g;
    $string =~ s/\xC6/AE/g; # Scandinavian
    $string =~ s/\xE6/ae/g;
#   $string =~ s/\xD8/OE/g;
#   $string =~ s/\xF8/oe/g;
    $string =~ s/\xFF/ij/g; # Dutch
    $string =~ s/\x9F/IJ/g; # Dutch  (Non-Standard!)
    $string =~ s/\x8C/OE/g; # French (Non-Standard!)
    $string =~ s/\x9C/oe/g; # French (Non-Standard!)
    $string =~ tr/\x20\x2D\x5F\x30-\x39A\xC0-\xC6a\xE0-\xE6BbC\xC7c\xE7DdE\xC8-\xCBe\xE8-\xEBFfGgHhI\xCC-\xCFi\xEC-\xEFJjKkLlMmNn\xD1\xF1O\xD2-\xD6\xD8\x8Co\xF2-\xF6\xF8\x9CPpQqRrS\x8As\x9A\xDFTtU\xD9-\xDCu\xF9-\xFCVvWwXxY\xDD\x9Fy\xFD\xFFZz\xD0\xF0\xDE\xFE\x21-\x2C\x2E\x2F\x3A-\x40\x5B-\x5E\x60\x7B-\x89\x8B\x8D-\x99\x9B\x9D\x9E\xA0-\xBF\xD7\xF7/\x20-\xFF/;
    $string;
}

__END__

