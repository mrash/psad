#ifndef MODULE_DATE_CALC
#define MODULE_DATE_CALC
#ifdef __cplusplus
extern "C"
{
#endif
/*****************************************************************************/
/*  MODULE NAME:  DateCalc.h                            MODULE TYPE:  (lib)  */
/*****************************************************************************/
/*          Gregorian calendar date calculations in compliance with          */
/*          ISO/R 2015-1971, DIN 1355 and (to some extent) ISO 8601.         */
/*****************************************************************************/
/*  MODULE IMPORTS:                                                          */
/*****************************************************************************/
#include <stdio.h>                                  /*  MODULE TYPE:  (sys)  */
#include <stdlib.h>                                 /*  MODULE TYPE:  (sys)  */
#include <string.h>                                 /*  MODULE TYPE:  (sys)  */
#include <time.h>                                   /*  MODULE TYPE:  (sys)  */
#include "ToolBox.h"                                /*  MODULE TYPE:  (dat)  */
/*****************************************************************************/
/*  MODULE INTERFACE:                                                        */
/*****************************************************************************/

/* Make the VMS linker happy: */

#ifdef VMS
#define DateCalc_Day_of_Week_Abbreviation_ DateCalc_DoW_Abbrev_
#define DateCalc_nth_weekday_of_month_year DateCalc_nth_weekday
#endif

boolean
DateCalc_leap_year                     (Z_int   year);

boolean
DateCalc_check_date                    (Z_int   year,
                                        Z_int   month,
                                        Z_int   day);

boolean
DateCalc_check_time                    (Z_int   hour,
                                        Z_int   min,
                                        Z_int   sec);

boolean
DateCalc_check_business_date           (Z_int   year,
                                        Z_int   week,
                                        Z_int   dow);

Z_int
DateCalc_Day_of_Year                   (Z_int   year,
                                        Z_int   month,
                                        Z_int   day);

Z_long
DateCalc_Date_to_Days                  (Z_int   year,
                                        Z_int   month,
                                        Z_int   day);

Z_int
DateCalc_Day_of_Week                   (Z_int   year,
                                        Z_int   month,
                                        Z_int   day);

Z_int
DateCalc_Weeks_in_Year                 (Z_int   year);

Z_int
DateCalc_Week_Number                   (Z_int   year,
                                        Z_int   month,
                                        Z_int   day);

boolean
DateCalc_week_of_year                  (Z_int  *week,       /*   O   */
                                        Z_int  *year,       /*  I/O  */
                                        Z_int   month,      /*   I   */
                                        Z_int   day);       /*   I   */

boolean
DateCalc_monday_of_week                (Z_int   week,       /*   I   */
                                        Z_int  *year,       /*  I/O  */
                                        Z_int  *month,      /*   O   */
                                        Z_int  *day);       /*   O   */

boolean
DateCalc_nth_weekday_of_month_year     (Z_int  *year,       /*  I/O  */
                                        Z_int  *month,      /*  I/O  */
                                        Z_int  *day,        /*   O   */
                                        Z_int   dow,        /*   I   */
                                        Z_int   n);         /*   I   */

boolean
DateCalc_standard_to_business          (Z_int  *year,       /*  I/O  */
                                        Z_int  *week,       /*   O   */
                                        Z_int  *dow,        /*   O   */
                                        Z_int   month,      /*   I   */
                                        Z_int   day);       /*   I   */

boolean
DateCalc_business_to_standard          (Z_int  *year,       /*  I/O  */
                                        Z_int  *month,      /*   O   */
                                        Z_int  *day,        /*   O   */
                                        Z_int   week,       /*   I   */
                                        Z_int   dow);       /*   I   */

Z_long
DateCalc_Delta_Days                    (Z_int   year1,
                                        Z_int   month1,
                                        Z_int   day1,
                                        Z_int   year2,
                                        Z_int   month2,
                                        Z_int   day2);

boolean /* PRIVATE */
DateCalc_delta_hms                     (Z_long *Dd,         /*  I/O  */
                                        Z_int  *Dh,         /*   O   */
                                        Z_int  *Dm,         /*   O   */
                                        Z_int  *Ds,         /*   O   */
                                        Z_int   hour1,      /*   I   */
                                        Z_int   min1,       /*   I   */
                                        Z_int   sec1,       /*   I   */
                                        Z_int   hour2,      /*   I   */
                                        Z_int   min2,       /*   I   */
                                        Z_int   sec2);      /*   I   */

boolean
DateCalc_delta_dhms                    (Z_long *Dd,         /*   O   */
                                        Z_int  *Dh,         /*   O   */
                                        Z_int  *Dm,         /*   O   */
                                        Z_int  *Ds,         /*   O   */
                                        Z_int   year1,      /*   I   */
                                        Z_int   month1,     /*   I   */
                                        Z_int   day1,       /*   I   */
                                        Z_int   hour1,      /*   I   */
                                        Z_int   min1,       /*   I   */
                                        Z_int   sec1,       /*   I   */
                                        Z_int   year2,      /*   I   */
                                        Z_int   month2,     /*   I   */
                                        Z_int   day2,       /*   I   */
                                        Z_int   hour2,      /*   I   */
                                        Z_int   min2,       /*   I   */
                                        Z_int   sec2);      /*   I   */

boolean
DateCalc_delta_ymd                     (Z_int  *year1,      /*  I/O  */
                                        Z_int  *month1,     /*  I/O  */
                                        Z_int  *day1,       /*  I/O  */
                                        Z_int   year2,      /*   I   */
                                        Z_int   month2,     /*   I   */
                                        Z_int   day2);      /*   I   */

boolean
DateCalc_delta_ymdhms                  (Z_int  *D_y,        /*   O   */
                                        Z_int  *D_m,        /*   O   */
                                        Z_int  *D_d,        /*   O   */
                                        Z_int  *Dh,         /*   O   */
                                        Z_int  *Dm,         /*   O   */
                                        Z_int  *Ds,         /*   O   */
                                        Z_int   year1,      /*   I   */
                                        Z_int   month1,     /*   I   */
                                        Z_int   day1,       /*   I   */
                                        Z_int   hour1,      /*   I   */
                                        Z_int   min1,       /*   I   */
                                        Z_int   sec1,       /*   I   */
                                        Z_int   year2,      /*   I   */
                                        Z_int   month2,     /*   I   */
                                        Z_int   day2,       /*   I   */
                                        Z_int   hour2,      /*   I   */
                                        Z_int   min2,       /*   I   */
                                        Z_int   sec2);      /*   I   */

void
DateCalc_Normalize_DHMS                (Z_long *Dd,         /*  I/O  */
                                        Z_long *Dh,         /*  I/O  */
                                        Z_long *Dm,         /*  I/O  */
                                        Z_long *Ds);        /*  I/O  */

boolean
DateCalc_add_delta_days                (Z_int  *year,       /*  I/O  */
                                        Z_int  *month,      /*  I/O  */
                                        Z_int  *day,        /*  I/O  */
                                        Z_long  Dd);        /*   I   */

boolean
DateCalc_add_delta_dhms                (Z_int  *year,       /*  I/O  */
                                        Z_int  *month,      /*  I/O  */
                                        Z_int  *day,        /*  I/O  */
                                        Z_int  *hour,       /*  I/O  */
                                        Z_int  *min,        /*  I/O  */
                                        Z_int  *sec,        /*  I/O  */
                                        Z_long  Dd,         /*   I   */
                                        Z_long  Dh,         /*   I   */
                                        Z_long  Dm,         /*   I   */
                                        Z_long  Ds);        /*   I   */

boolean /* PRIVATE */
DateCalc_add_year_month                (Z_int  *year,       /*  I/O  */
                                        Z_int  *month,      /*  I/O  */
                                        Z_long  Dy,         /*   I   */
                                        Z_long  Dm);        /*   I   */

boolean
DateCalc_add_delta_ym                  (Z_int  *year,       /*  I/O  */
                                        Z_int  *month,      /*  I/O  */
                                        Z_int  *day,        /*  I/O  */
                                        Z_long  Dy,         /*   I   */
                                        Z_long  Dm);        /*   I   */

boolean
DateCalc_add_delta_ymd                 (Z_int  *year,       /*  I/O  */
                                        Z_int  *month,      /*  I/O  */
                                        Z_int  *day,        /*  I/O  */
                                        Z_long  Dy,         /*   I   */
                                        Z_long  Dm,         /*   I   */
                                        Z_long  Dd);        /*   I   */

boolean
DateCalc_add_delta_ymdhms              (Z_int  *year,       /*  I/O  */
                                        Z_int  *month,      /*  I/O  */
                                        Z_int  *day,        /*  I/O  */
                                        Z_int  *hour,       /*  I/O  */
                                        Z_int  *min,        /*  I/O  */
                                        Z_int  *sec,        /*  I/O  */
                                        Z_long  D_y,        /*   I   */
                                        Z_long  D_m,        /*   I   */
                                        Z_long  D_d,        /*   I   */
                                        Z_long  Dh,         /*   I   */
                                        Z_long  Dm,         /*   I   */
                                        Z_long  Ds);        /*   I   */

boolean
DateCalc_system_clock                  (Z_int  *year,       /*   O   */
                                        Z_int  *month,      /*   O   */
                                        Z_int  *day,        /*   O   */
                                        Z_int  *hour,       /*   O   */
                                        Z_int  *min,        /*   O   */
                                        Z_int  *sec,        /*   O   */
                                        Z_int  *doy,        /*   O   */
                                        Z_int  *dow,        /*   O   */
                                        Z_int  *dst,        /*   O   */
                                        boolean gmt);       /*   I   */

boolean
DateCalc_gmtime                        (Z_int  *year,       /*   O   */
                                        Z_int  *month,      /*   O   */
                                        Z_int  *day,        /*   O   */
                                        Z_int  *hour,       /*   O   */
                                        Z_int  *min,        /*   O   */
                                        Z_int  *sec,        /*   O   */
                                        Z_int  *doy,        /*   O   */
                                        Z_int  *dow,        /*   O   */
                                        Z_int  *dst,        /*   O   */
                                        time_t  seconds);   /*   I   */

boolean
DateCalc_localtime                     (Z_int  *year,       /*   O   */
                                        Z_int  *month,      /*   O   */
                                        Z_int  *day,        /*   O   */
                                        Z_int  *hour,       /*   O   */
                                        Z_int  *min,        /*   O   */
                                        Z_int  *sec,        /*   O   */
                                        Z_int  *doy,        /*   O   */
                                        Z_int  *dow,        /*   O   */
                                        Z_int  *dst,        /*   O   */
                                        time_t  seconds);   /*   I   */

boolean
DateCalc_mktime                        (time_t *seconds,    /*   O   */
                                        Z_int   year,       /*   I   */
                                        Z_int   month,      /*   I   */
                                        Z_int   day,        /*   I   */
                                        Z_int   hour,       /*   I   */
                                        Z_int   min,        /*   I   */
                                        Z_int   sec,        /*   I   */
                                        Z_int   doy,        /*   I   */
                                        Z_int   dow,        /*   I   */
                                        Z_int   dst);       /*   I   */

boolean
DateCalc_timezone                      (Z_int  *year,       /*   O   */
                                        Z_int  *month,      /*   O   */
                                        Z_int  *day,        /*   O   */
                                        Z_int  *hour,       /*   O   */
                                        Z_int  *min,        /*   O   */
                                        Z_int  *sec,        /*   O   */
                                        Z_int  *dst,        /*   O   */
                                        time_t when);       /*   I   */

boolean
DateCalc_date2time                     (time_t *seconds,    /*   O   */
                                        Z_int   year,       /*   I   */
                                        Z_int   month,      /*   I   */
                                        Z_int   day,        /*   I   */
                                        Z_int   hour,       /*   I   */
                                        Z_int   min,        /*   I   */
                                        Z_int   sec);       /*   I   */

boolean
DateCalc_time2date                     (Z_int  *year,       /*   O   */
                                        Z_int  *month,      /*   O   */
                                        Z_int  *day,        /*   O   */
                                        Z_int  *hour,       /*   O   */
                                        Z_int  *min,        /*   O   */
                                        Z_int  *sec,        /*   O   */
                                        time_t  seconds);   /*   I   */

boolean
DateCalc_easter_sunday                 (Z_int  *year,       /*  I/O  */
                                        Z_int  *month,      /*   O   */
                                        Z_int  *day);       /*   O   */

Z_int
DateCalc_Decode_Month                  (charptr buffer,
                                        Z_int   length);

Z_int
DateCalc_Decode_Day_of_Week            (charptr buffer,
                                        Z_int   length);

Z_int
DateCalc_Decode_Language               (charptr buffer,
                                        Z_int   length);

boolean
DateCalc_decode_date_eu                (charptr buffer,     /*   I   */
                                        Z_int  *year,       /*   O   */
                                        Z_int  *month,      /*   O   */
                                        Z_int  *day);       /*   O   */

boolean
DateCalc_decode_date_us                (charptr buffer,     /*   I   */
                                        Z_int  *year,       /*   O   */
                                        Z_int  *month,      /*   O   */
                                        Z_int  *day);       /*   O   */

Z_int
DateCalc_Fixed_Window                  (Z_int   year);

Z_int
DateCalc_Moving_Window                 (Z_int   year);

Z_int
DateCalc_Compress                      (Z_int   year,
                                        Z_int   month,
                                        Z_int   day);

boolean
DateCalc_uncompress                    (Z_int   date,       /*   I   */
                                        Z_int  *century,    /*   O   */
                                        Z_int  *year,       /*   O   */
                                        Z_int  *month,      /*   O   */
                                        Z_int  *day);       /*   O   */

boolean
DateCalc_check_compressed              (Z_int   date);

charptr
DateCalc_Compressed_to_Text            (Z_int   date);

charptr
DateCalc_Date_to_Text                  (Z_int   year,
                                        Z_int   month,
                                        Z_int   day);

charptr
DateCalc_Date_to_Text_Long             (Z_int   year,
                                        Z_int   month,
                                        Z_int   day);

charptr                                                     /*   O   */
DateCalc_English_Ordinal               (charptr result,     /*   O   */
                                        Z_int   number);    /*   I   */

charptr
DateCalc_Calendar                      (Z_int   year,
                                        Z_int   month,
                                        boolean orthodox);

void
DateCalc_Dispose                       (charptr string);

N_char
DateCalc_ISO_LC                        (N_char c);

N_char
DateCalc_ISO_UC                        (N_char c);

charptr
DateCalc_Version                       (void);

/*****************************************************************************/
/*  MODULE RESOURCES:                                                        */
/*****************************************************************************/

#define  DateCalc_YEAR_OF_EPOCH        70    /* year of reference (epoch)    */
#define  DateCalc_CENTURY_OF_EPOCH   1900    /* century of reference (epoch) */
#define  DateCalc_EPOCH (DateCalc_CENTURY_OF_EPOCH + DateCalc_YEAR_OF_EPOCH)

extern const Z_int DateCalc_Days_in_Year_[2][14];
/*
{
    { 0, 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365 },
    { 0, 0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366 }
};
*/

extern const Z_int DateCalc_Days_in_Month_[2][13];
/*
{
    { 0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 },
    { 0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
};
*/

#define DateCalc_LANGUAGES 14

extern Z_int DateCalc_Language; /* Default = 1 (English) */

extern const N_char DateCalc_Month_to_Text_[DateCalc_LANGUAGES+1][13][32];
/*
{
    {
        "???", "???", "???", "???", "???", "???", "???",
        "???", "???", "???", "???", "???", "???"
    },
    {
        "???", "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    },
    {
        "???", "janvier", "février", "mars", "avril", "mai", "juin",
        "juillet", "août", "septembre", "octobre", "novembre", "décembre"
    },
    {
        "???", "Januar", "Februar", "März", "April", "Mai", "Juni",
        "Juli", "August", "September", "Oktober", "November", "Dezember"
    },
    {
        "???", "enero", "febrero", "marzo", "abril", "mayo", "junio",
        "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"
    },
    {
        "???", "janeiro", "fevereiro", "março", "abril", "maio", "junho",
        "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"
    },
    {
        "???", "januari", "februari", "maart", "april", "mei", "juni",
        "juli", "augustus", "september", "october", "november", "december"
    },
    {
        "???", "Gennaio", "Febbraio", "Marzo", "Aprile", "Maggio", "Giugno",
        "Luglio", "Agosto", "Settembre", "Ottobre", "Novembre", "Dicembre"
    },
    {
        "???", "januar", "februar", "mars", "april", "mai", "juni",
        "juli", "august", "september", "oktober", "november", "desember"
    },
    {
        "???", "januari", "februari", "mars", "april", "maj", "juni",
        "juli", "augusti", "september", "oktober", "november", "december"
    },
    {
        "???", "januar", "februar", "marts", "april", "maj", "juni",
        "juli", "august", "september", "oktober", "november", "december"
    },
    {
        "???", "tammikuu", "helmikuu", "maaliskuu", "huhtikuu",
        "toukokuu", "kesäkuu", "heinäkuu", "elokuu",
        "syyskuu", "lokakuu", "marraskuu", "joulukuu"
    },
    {
        "???", "Január", "Február", "Március", "Április", "Május", "Június",
        "Július", "Augusztus", "Szeptember", "Október", "November", "December"
    },
    {
        "???", "stycznia", "lutego", "marca", "kwietnia", "maja", "czerwca",
        "lipca", "sierpnia", "wrzesnia", "pazdziernika", "listopada", "grudnia"
    },
    {
        "???", "Ianuarie", "Februarie", "Martie", "Aprilie", "Mai", "Iunie",
        "Iulie", "August", "Septembrie", "Octombrie", "Noiembrie", "Decembrie"
    }
};
*/

extern const N_char DateCalc_Day_of_Week_to_Text_[DateCalc_LANGUAGES+1][8][32];
/*
{
    {
        "???", "???", "???", "???",
        "???", "???", "???", "???"
    },
    {
        "???", "Monday", "Tuesday", "Wednesday",
        "Thursday", "Friday", "Saturday", "Sunday"
    },
    {
        "???", "Lundi", "Mardi", "Mercredi",
        "Jeudi", "Vendredi", "Samedi", "Dimanche"
    },
    {
        "???", "Montag", "Dienstag", "Mittwoch",
        "Donnerstag", "Freitag", "Samstag", "Sonntag"
    },
    {
        "???", "Lunes", "Martes", "Miércoles",
        "Jueves", "Viernes", "Sábado", "Domingo"
    },
    {
        "???", "Segunda-feira", "Terça-feira", "Quarta-feira",
        "Quinta-feira", "Sexta-feira", "Sábado", "Domingo"
    },
    {
        "???", "Maandag", "Dinsdag", "Woensdag",
        "Donderdag", "Vrijdag", "Zaterdag", "Zondag"
    },
    {
        "???", "Lunedì", "Martedì", "Mercoledì",
        "Giovedì", "Venerdì", "Sabato", "Domenica"
    },
    {
        "???", "mandag", "tirsdag", "onsdag",
        "torsdag", "fredag", "lørdag", "søndag"
    },
    {
        "???", "måndag", "tisdag", "onsdag",
        "torsdag", "fredag", "lördag", "söndag"
    },
    {
        "???", "mandag", "tirsdag", "onsdag",
        "torsdag", "fredag", "lørdag", "søndag"
    },
    {
        "???", "maanantai", "tiistai", "keskiviikko",
        "torstai", "perjantai", "lauantai", "sunnuntai"
    },
    {
        "???", "hétfõ", "kedd", "szerda",
        "csütörtök", "péntek", "szombat", "vasárnap"
    },
    {
        "???", "poniedzialek", "wtorek", "srodek",
        "czwartek", "piatek", "sobota", "niedziele"
    },
    {
        "???", "Luni", "Marti", "Miercuri",
        "Joi", "Vineri", "Sambata", "Duminica"
    }
};
*/

extern const N_char DateCalc_Day_of_Week_Abbreviation_[DateCalc_LANGUAGES+1][8][4];

    /* Fill the fields below _only_ if special abbreviations are needed! */
    /* Note that the first field serves as a flag and must be non-empty! */
/*
{
    {
        "", "", "", "", "", "", "", ""
    },
    {
        "", "", "", "", "", "", "", ""
    },
    {
        "", "", "", "", "", "", "", ""
    },
    {
        "", "", "", "", "", "", "", ""
    },
    {
        "", "", "", "", "", "", "", ""
    },
    {
        "???", "2ª", "3ª", "4ª", "5ª", "6ª", "Sáb", "Dom"
    },
    {
        "", "", "", "", "", "", "", ""
    },
    {
        "", "", "", "", "", "", "", ""
    },
    {
        "", "", "", "", "", "", "", ""
    },
    {
        "", "", "", "", "", "", "", ""
    },
    {
        "", "", "", "", "", "", "", ""
    },
    {
        "", "", "", "", "", "", "", ""
    },
    {
        "", "", "", "", "", "", "", ""
    },
    {
        "???", "Pn", "Wt", "Sr", "Cz", "Pt", "So", "Ni"
    },
    {
        "", "", "", "", "", "", "", ""
    }
};
*/

extern const N_char DateCalc_English_Ordinals_[4][4];
/*
{
    "th",
    "st",
    "nd",
    "rd"
};
*/

extern const N_char DateCalc_Date_Long_Format_[DateCalc_LANGUAGES+1][64];
/*
{
    "%s, %d %s %d",
    "%s, %s %s %d",
    "%s %d %s %d",
    "%s, den %d. %s %d",
    "%s, %d de %s de %d",
    "%s, dia %d de %s de %d",
    "%s, %d %s %d",
    "%s, %d %s %d",
    "%s, %d. %s %d",
    "%s, %d %s %d",
    "%s, %d. %s %d",
    "%s, %d. %sta %d",
    "%d. %s %d., %s",
    "%s, %d %s %d",
    "%s %d %s %d"
};
*/

extern const N_char DateCalc_Language_to_Text_[DateCalc_LANGUAGES+1][32];
/*
{
    "???", "English", "Français", "Deutsch", "Español",
    "Português", "Nederlands", "Italiano", "Norsk", "Svenska",
    "Dansk", "suomi", "Magyar", "polski", "Romaneste"
};
*/

/*****************************************************************************/
/*  MODULE IMPLEMENTATION:                                                   */
/*****************************************************************************/

/*****************************************************************************/
/*  VERSION:  5.4                                                            */
/*****************************************************************************/
/*  VERSION HISTORY:                                                         */
/*****************************************************************************/
/*                                                                           */
/*    Version 5.4  03.10.04  Added compiler directives for C++.              */
/*    Version 5.3  29.09.02  No changes.                                     */
/*    Version 5.2  18.09.02  No changes.                                     */
/*    Version 5.1  08.09.02  Added conditional changes for MacOS/MacPerl.    */
/*    Version 5.0  10.10.01  New YMD/HMS functions, replaced <ctype.h>, ...  */
/*    Version 4.3  08.01.00  decode_date_??: (yy < 70 ? 20yy : 19yy)         */
/*    Version 4.2  07.09.98  No changes.                                     */
/*    Version 4.1  08.06.98  Fixed bug in "add_delta_ymd()".                 */
/*    Version 4.0  12.05.98  Major rework. Added multi-language support.     */
/*    Version 3.2  15.06.97  Added "week_of_year()".                         */
/*    Version 3.1  12.06.97  No significant changes.                         */
/*    Version 3.0  16.02.97  Changed conventions for unsuccessful returns.   */
/*    Version 2.3  22.11.96  Fixed unbalanced "malloc" and "free".           */
/*    Version 2.2  26.05.96  No significant changes.                         */
/*    Version 2.1  26.05.96  Fixed HH MM SS parameter checks.                */
/*    Version 2.0  25.05.96  Added time calculations. Major rework.          */
/*    Version 1.6  20.04.96  Not published.                                  */
/*    Version 1.5  14.03.96  No significant changes.                         */
/*    Version 1.4  11.02.96  No significant changes.                         */
/*    Version 1.3  10.12.95  Added "days_in_month()".                        */
/*    Version 1.2b 27.11.95  No significant changes.                         */
/*    Version 1.2a 21.11.95  Fix for type name clashes.                      */
/*    Version 1.1  18.11.95  Fix for type name clashes.                      */
/*    Version 1.01 16.11.95  Improved compliance w/ programming standards.   */
/*    Version 1.0  14.11.95  First version under UNIX (with Perl module).    */
/*    Version 0.9  01.11.93  First version of C library under MS-DOS.        */
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
/*    Copyright (c) 1993 - 2004 by Steffen Beyer.                            */
/*    All rights reserved.                                                   */
/*                                                                           */
/*****************************************************************************/
/*  LICENSE:                                                                 */
/*****************************************************************************/
/*                                                                           */
/*    This library is free software; you can redistribute it and/or          */
/*    modify it under the terms of the GNU Library General Public            */
/*    License as published by the Free Software Foundation; either           */
/*    version 2 of the License, or (at your option) any later version.       */
/*                                                                           */
/*    This library is distributed in the hope that it will be useful,        */
/*    but WITHOUT ANY WARRANTY; without even the implied warranty of         */
/*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU       */
/*    Library General Public License for more details.                       */
/*                                                                           */
/*    You should have received a copy of the GNU Library General Public      */
/*    License along with this library; if not, write to the                  */
/*    Free Software Foundation, Inc.,                                        */
/*    59 Temple Place, Suite 330, Boston, MA 02111-1307 USA                  */
/*    or download a copy from ftp://ftp.gnu.org/pub/gnu/COPYING.LIB-2.0      */
/*                                                                           */
/*****************************************************************************/
#ifdef __cplusplus
}
#endif
#endif
