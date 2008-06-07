#ifndef MODULE_ISO_TO_PC
#define MODULE_ISO_TO_PC
/*****************************************************************************/
/*  MODULE NAME:  iso2pc.c                              MODULE TYPE:  (app)  */
/*****************************************************************************/
/*  MODULE IMPORTS:                                                          */
/*****************************************************************************/
#include <stdio.h>                                  /*  MODULE TYPE:  (sys)  */
#include <string.h>                                 /*  MODULE TYPE:  (sys)  */
/*****************************************************************************/
/*  MODULE INTERFACE:                                                        */
/*****************************************************************************/
/*

    This application is a typical UNIX filter designed to convert
    special characters (with ASCII codes ranging from 0x80 to 0xFF)
    from the "ISO-Latin-1" ("ISO-8859-1") character set to one of the
    "CP 850" PC character sets (and vice-versa) in a REVERSIBLE way
    WITHOUT LOSSES of information.

    This filter thereby tries to provide a "best possible" translation,
    i.e., all characters that are visually the same or very similar in
    both character sets are converted into one another, which should
    give a pretty well readable translation of any text containing
    special international characters.

    Moreover, some of the characters without visual equivalent in the
    other character set are converted anyway (where necessary) to some
    arbitrary character, in order to assure that EVERY character in
    the character set has a UNIQUE equivalent (in order to assure
    the invertibility of the translation table used by this filter
    and thus the reversibility of the transformation performed by
    this filter).

    The filter thereby tries to convert as little of these characters
    without visual equivalent as possible in order to produce as little
    "distortions" in the filtered text as possible.

    Characters affected by the translation of this filter are the ones
    with ASCII codes ranging from 0x80 to 0xFF, all other characters
    are simply passed through.

    Input comes from standard input, output goes to standard output.

    Both can be redirected to/from files using the corresponding UNIX
    redirection operators.

    Available command line options are:

        -v     reverse the conversion (use inverse translation table)
        -d     use "dos" character set (used by older MS-DOS versions
               and the FreeBSD "SCO" console, for instance) (DEFAULT)
        -w     use "win" character set (used by newer MS-DOS versions
               and the Windows NT/95 MS-DOS command shell)
        -n     "neutral" or "no operation" - simply pass through all
               characters (overrides "-v", "-d" and "-w")

        -vd    use "dos" character set, reverse conversion
        -dv    use "dos" character set, reverse conversion
        -vw    use "win" character set, reverse conversion
        -wv    use "win" character set, reverse conversion

        -rev   reverse the conversion
        -dos   use "dos" character set (DEFAULT)
        -win   use "win" character set
        -nop   simply pass through all characters

        -dump  dump the internal translation table (can be combined
               with "-v" or "-rev" to dump the inverse translation
               table) instead of performing any conversion (override)
        -init  initialize the translation table first before dumping
               it (this option has no effect if "-dump" is not present)

    The last options on the command line take precedence over the first
    ones, where applicable.

    "-v" and "-rev" are toggle switches, i.e., specifying this option
    twice is the same as not specifying it at all.

*/
/*****************************************************************************/
/*  MODULE RESOURCES:                                                        */
/*****************************************************************************/

/*
    Only characters that are visually the same or very similar in both
    the source and the target character set need to be specified here,
    the rest of this translation table is filled up automatically.
*/

#define CHARSETS 2

/*
    Character set #0:
            older versions of MS-DOS, FreeBSD SCO-like console (DEFAULT)
    Character set #1:
            newer versions of MS-DOS, Windows NT/95 MS-DOS command shell
*/

static int iso2pc[CHARSETS][0x80] =
{
    {
        0x00, 0x00, 0x00, 0x00,   0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,   0x00, 0x00, 0x00, 0x00,

        0x00, 0x00, 0x00, 0x00,   0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,   0x00, 0x00, 0x00, 0x00,

        0x00, 0xAD, 0x9B, 0x9C,   0x00, 0x9D, 0xB3, 0x9F,
        0x00, 0x00, 0xA6, 0xAE,   0xAA, 0xC4, 0x00, 0x00,

        0xF8, 0xF1, 0xFD, 0x00,   0x00, 0xE6, 0xBB, 0xF9,
        0x00, 0x00, 0xA7, 0xAF,   0xAC, 0xAB, 0x00, 0xA8,

        0x00, 0x00, 0x00, 0x00,   0x8E, 0x8F, 0x92, 0x80,
        0x00, 0x90, 0x00, 0x00,   0x00, 0x00, 0x00, 0x00,

        0x00, 0xA5, 0x00, 0x00,   0x00, 0x00, 0x99, 0x00,
        0x00, 0x00, 0x00, 0x00,   0x9A, 0x00, 0x00, 0xE1,

        0x85, 0xA0, 0x83, 0xE0,   0x84, 0x86, 0x91, 0x87,
        0x8A, 0x82, 0x88, 0x89,   0x8D, 0xA1, 0x8C, 0x8B,

        0xEB, 0xA4, 0x95, 0xA2,   0x93, 0x00, 0x94, 0xF6,
        0xED, 0x97, 0xA3, 0x96,   0x81, 0x00, 0x00, 0x98
    },
    {
        0x00, 0x00, 0x00, 0x00,   0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,   0x00, 0x00, 0x00, 0x00,

        0x00, 0x00, 0x00, 0x00,   0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,   0x00, 0x00, 0x00, 0x00,

        0x00, 0xAD, 0xBD, 0x9C,   0xCF, 0xBE, 0xDD, 0xF5,
        0xF9, 0xB8, 0xA6, 0xAE,   0xAA, 0xF0, 0xA9, 0xEE,

        0xF8, 0xF1, 0xFD, 0xFC,   0xEF, 0xE6, 0xF4, 0xFA,
        0xF7, 0xFB, 0xA7, 0xAF,   0xAC, 0xAB, 0xF3, 0xA8,

        0xB7, 0xB5, 0xB6, 0xC7,   0x8E, 0x8F, 0x92, 0x80,
        0xD4, 0x90, 0xD2, 0xD3,   0xDE, 0xD6, 0xD7, 0xD8,

        0xD1, 0xA5, 0xE3, 0xE0,   0xE2, 0xE5, 0x99, 0x9E,
        0x9D, 0xEB, 0xE9, 0xEA,   0x9A, 0xED, 0xE8, 0xE1,

        0x85, 0xA0, 0x83, 0xC6,   0x84, 0x86, 0x91, 0x87,
        0x8A, 0x82, 0x88, 0x89,   0x8D, 0xA1, 0x8C, 0x8B,

        0xD0, 0xA4, 0x95, 0xA2,   0x93, 0xE4, 0x94, 0xF6,
        0x9B, 0x97, 0xA3, 0x96,   0x81, 0xEC, 0xE7, 0x98
    }
};

/*****************************************************************************/
/*  MODULE IMPLEMENTATION:                                                   */
/*****************************************************************************/

static char *self;

static int pc2iso[CHARSETS][0x80];

void clear(int charset)
{
    int i;

    for ( i = 0x00; i < 0x80; i++ )
    {
        pc2iso[charset][i] = 0x00;
    }
}

void initialize(int charset)
{
    int i,j,k;

    clear(charset);
    for ( i = 0x00; i < 0x80; i++ )
    {
        if (iso2pc[charset][i] != 0x00)
        {
            pc2iso[charset][iso2pc[charset][i] & 0x7F] = i | 0x80;
        }
    }
    for ( i = 0x00; i < 0x80; i++ )
    {
        if ((iso2pc[charset][i] == 0x00) &&
            (pc2iso[charset][i] == 0x00))
        {
            iso2pc[charset][i] = i | 0x80;
            pc2iso[charset][i] = i | 0x80;
        }
    }
    k = 0x00;
    for ( i = 0x00; i < 0x80; i++ )
    {
        if (iso2pc[charset][i] == 0x00)
        {
            for ( j = k; j < 0x80; j++ )
            {
                if (pc2iso[charset][j] == 0x00)
                {
                    iso2pc[charset][i] = j | 0x80;
                    pc2iso[charset][j] = i | 0x80;
                    k = j + 1;
                    break;
                }
            }
        }
    }
    for ( i = 0x00; i < 0x80; i++ )
    {
        if ((iso2pc[charset][i] == 0x00) ||
            (pc2iso[charset][i] == 0x00))
        {
            fprintf(stderr,"%s: internal configuration error!\n", self);
            exit(1);
        }
    }
}

void dump_table(int init, int reverse)
{
    int charset,i,k;

    fprintf(stdout,"static int iso2pc[CHARSETS][0x80] =\n");
    fprintf(stdout,"{\n");
    for ( charset = 0; charset < CHARSETS; charset++ )
    {
        if (init) initialize(charset); else clear(charset);
        fprintf(stdout,"    {\n");
        for ( i = 0x00; i < 0x80; i++ )
        {
            k = i & 0x07;
            if      (k == 0x00) fprintf(stdout,"        ");
            else if (k == 0x04) fprintf(stdout,"  ");
            if (reverse) fprintf(stdout,"0x%02.2X", pc2iso[charset][i]);
            else         fprintf(stdout,"0x%02.2X", iso2pc[charset][i]);
            if (k == 0x07)
            {
                if (i == 0x7F)               fprintf(stdout,"\n");
                else if ((i & 0x0F) == 0x0F) fprintf(stdout,",\n\n");
                else                         fprintf(stdout,",\n");
            }
            else                             fprintf(stdout,", ");
        }
        if (charset < CHARSETS-1) fprintf(stdout,"    },\n");
        else                      fprintf(stdout,"    }\n");
    }
    fprintf(stdout,"};\n");
}

int main(int argc, char *argv[])
{
    char *option;
    int   reverse = 0;
    int   charset = 0;
    int   neutral = 0;
    int   dump = 0;
    int   init = 0;
    int   err = 0;
    int   c;

    if ((self = strrchr(argv[0],'/')) != NULL) self++; else self = argv[0];
    for ( c = 1; c < argc; c++ )
    {
        option = argv[c];
        if (*option == '-')
        {
            option++;
            switch (strlen(option))
            {
                case 1:
                    if      (*option == 'v') reverse = ! reverse;
                    else if (*option == 'd') charset = 0;
                    else if (*option == 'w') charset = 1;
                    else if (*option == 'n') neutral = 1;
                    else err = 1;
                  break;
                case 2:
                    if      (strcmp(option,"vd") == 0)
                            { reverse = ! reverse; charset = 0; }
                    else if (strcmp(option,"dv") == 0)
                            { reverse = ! reverse; charset = 0; }
                    else if (strcmp(option,"vw") == 0)
                            { reverse = ! reverse; charset = 1; }
                    else if (strcmp(option,"wv") == 0)
                            { reverse = ! reverse; charset = 1; }
                    else err = 1;
                  break;
                case 3:
                    if      (strcmp(option,"rev") == 0) reverse = ! reverse;
                    else if (strcmp(option,"dos") == 0) charset = 0;
                    else if (strcmp(option,"win") == 0) charset = 1;
                    else if (strcmp(option,"nop") == 0) neutral = 1;
                    else err = 1;
                  break;
                case 4:
                    if      (strcmp(option,"dump") == 0) dump = 1;
                    else if (strcmp(option,"init") == 0) init = 1;
                    else err = 1;
                  break;
                default:
                    err = 1;
                  break;
            }
        }
        else err = 1;
        if (err)
        {
            fprintf(stderr,"%s: unknown option '%s'!\n", self, argv[c]);
            exit(1);
        }
    }
    if (dump) dump_table(init,reverse);
    else if (neutral)
    {
        while ((c = getchar()) != EOF) putchar(c);
    }
    else
    {
        initialize(charset);
        while ((c = getchar()) != EOF)
        {
            if ((c & ~0x7F) == 0x80)
            {
                if (reverse) putchar(pc2iso[charset][c & 0x7F]);
                else         putchar(iso2pc[charset][c & 0x7F]);
            }
            else putchar(c);
        }
    }
    return(0);
}

/*****************************************************************************/
/*  VERSION:  2.1                                                            */
/*****************************************************************************/
/*  VERSION HISTORY:                                                         */
/*****************************************************************************/
/*                                                                           */
/*    21.04.98    Version 2.1  added "neutral" behaviour                     */
/*    19.04.98    Version 2.0  support for multiple target charsets added    */
/*    10.04.98    Version 1.0                                                */
/*                                                                           */
/*****************************************************************************/
/*  AUTHOR:                                                                  */
/*****************************************************************************/
/*                                                                           */
/*    Steffen Beyer                                                          */
/*    mailto:sb@engelschall.com                                              */
/*    http://www.engelschall.com/u/sb/download/                              */
/*                                                                           */
/*****************************************************************************/
/*  COPYRIGHT:                                                               */
/*****************************************************************************/
/*                                                                           */
/*    Copyright (c) 1998 - 2004 by Steffen Beyer.                            */
/*    All rights reserved.                                                   */
/*                                                                           */
/*****************************************************************************/
/*  LICENSE:                                                                 */
/*****************************************************************************/
/*                                                                           */
/*    This program is free software; you can redistribute it and/or          */
/*    modify it under the terms of the GNU General Public License            */
/*    as published by the Free Software Foundation; either version 2         */
/*    of the License, or (at your option) any later version.                 */
/*                                                                           */
/*    This program is distributed in the hope that it will be useful,        */
/*    but WITHOUT ANY WARRANTY; without even the implied warranty of         */
/*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the           */
/*    GNU General Public License for more details.                           */
/*                                                                           */
/*    You should have received a copy of the GNU General Public License      */
/*    along with this program; if not, write to the                          */
/*    Free Software Foundation, Inc.,                                        */
/*    59 Temple Place, Suite 330, Boston, MA 02111-1307 USA                  */
/*    or download a copy from ftp://ftp.gnu.org/pub/gnu/COPYING-2.0          */
/*                                                                           */
/*****************************************************************************/
#endif
