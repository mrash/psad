
/*****************************************************************************/
/*                                                                           */
/*    Copyright (c) 1998 - 2002 by Steffen Beyer.                            */
/*    All rights reserved.                                                   */
/*                                                                           */
/*    This program is free software; you can redistribute it                 */
/*    and/or modify it under the same terms as Perl.                         */
/*                                                                           */
/*****************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ToolBox.h"
#include "DateCalc.h"

int main(int argc, char *argv[])
{
    int   code = 1;
    char *self;
    Z_int lang;
    Z_int month;
    Z_int year;

    if ((self = strrchr(argv[0],'/')) != NULL) self++; else self = argv[0];

    if (argc != 4)
    {
        fprintf(stderr, "Usage: %s <language> <month> <year>\n", self);
    }
    else
    {
        if (not (lang = DateCalc_Decode_Language(argv[1],strlen(argv[1]))))
        {
            lang = (Z_int) atoi(argv[1]);
        }
        if ((lang < 1) or (lang > DateCalc_LANGUAGES))
        {
            fprintf(stderr, "%s: the chosen language (%d) is not available!\n",
                self, lang);
        }
        else
        {
            DateCalc_Language = lang;

            if (not (month = DateCalc_Decode_Month(argv[2],strlen(argv[2]))))
            {
                month = (Z_int) atoi(argv[2]);
            }

            year = (Z_int) atoi(argv[3]);

            if ((month < 1) or (month > 12))
            {
                fprintf(stderr, "%s: the given month (%d) is out of range!\n",
                    self, month);
            }
            else if (year < 1)
            {
                fprintf(stderr, "%s: the given year (%d) is out of range!\n",
                    self, year);
            }
            else
            {
                fprintf(stdout,"%s", DateCalc_Calendar(year,month,false));
                code = 0;
            }
        }
    }
    return(code);
}

