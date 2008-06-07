#ifndef MODULE_DATE_CALC
#define MODULE_DATE_CALC
/*****************************************************************************/
/*  MODULE NAME:  DateCalc.c                            MODULE TYPE:  (lib)  */
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

const Z_int DateCalc_Days_in_Year_[2][14] =
{
    { 0, 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365 },
    { 0, 0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366 }
};

const Z_int DateCalc_Days_in_Month_[2][13] =
{
    { 0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 },
    { 0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
};

#define DateCalc_LANGUAGES 14

Z_int DateCalc_Language = 1; /* Default = 1 (English) */

const N_char DateCalc_Month_to_Text_[DateCalc_LANGUAGES+1][13][32] =
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
     /* "???", "Styczen", "Luty", "Marzec", "Kwiecien", "Maj", "Czerwiec", */ /* non-flected? */
     /* "Lipiec", "Sierpien", "Wrzesien", "Pazdziernik", "Listopad", "Grudzien" */
     /* "???", "Styczeñ", "Luty", "Marzec", "Kwiecieñ", "Maj", "Czerwiec", */ /* ISO-Latin-2 */
     /* "Lipiec", "Sierpieñ", "Wrzesieñ", "Pa¼dziernik", "Listopad", "Grudzieñ" */
    },
    {
        "???", "Ianuarie", "Februarie", "Martie", "Aprilie", "Mai", "Iunie",
        "Iulie", "August", "Septembrie", "Octombrie", "Noiembrie", "Decembrie"
    }
};

const N_char DateCalc_Day_of_Week_to_Text_[DateCalc_LANGUAGES+1][8][32] =
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
     /* "???", "Poniedzialek", "Wtorek", "Sroda", */ /* non-flected? */
     /* "Czwartek", "Piatek", "Sobota", "Niedziela" */
     /* "???", "Poniedzia³ek", "Wtorek", "¦roda", */ /* ISO-Latin-2 */
     /* "Czwartek", "Pi±tek", "Sobota", "Niedziela" */
    },
    {
        "???", "Luni", "Marti", "Miercuri",
        "Joi", "Vineri", "Sambata", "Duminica"
    }
};

const N_char DateCalc_Day_of_Week_Abbreviation_[DateCalc_LANGUAGES+1][8][4] =

    /* Fill the fields below _only_ if special abbreviations are needed! */
    /* Note that the first field serves as a flag and must be non-empty! */
{
    {
        "", "", "", "", "", "", "", ""    /*  0 */
    },
    {
        "", "", "", "", "", "", "", ""    /*  1 */
    },
    {
        "", "", "", "", "", "", "", ""    /*  2 */
    },
    {
        "", "", "", "", "", "", "", ""    /*  3 */
    },
    {
        "", "", "", "", "", "", "", ""    /*  4 */
    },
    {
        "???", "2ª", "3ª", "4ª", "5ª", "6ª", "Sáb", "Dom"    /*  5 */
    },
    {
        "", "", "", "", "", "", "", ""    /*  6 */
    },
    {
        "", "", "", "", "", "", "", ""    /*  7 */
    },
    {
        "", "", "", "", "", "", "", ""    /*  8 */
    },
    {
        "", "", "", "", "", "", "", ""    /*  9 */
    },
    {
        "", "", "", "", "", "", "", ""    /* 10 */
    },
    {
        "", "", "", "", "", "", "", ""    /* 11 */
    },
    {
        "", "", "", "", "", "", "", ""    /* 12 */
    },
    {
        "???", "Pn", "Wt", "Sr", "Cz", "Pt", "So", "Ni"    /* 13 */
     /* "???", "Pn", "Wt", "¦r", "Cz", "Pt", "So", "Ni" */ /* 13 */ /* ISO-Latin-2 */
    },
    {
        "", "", "", "", "", "", "", ""    /* 14 */
    }
};

const N_char DateCalc_English_Ordinals_[4][4] =
{
    "th",
    "st",
    "nd",
    "rd"
};

const N_char DateCalc_Date_Long_Format_[DateCalc_LANGUAGES+1][64] =
{
    "%s, %d %s %d",                     /*  0  Default     */
    "%s, %s %s %d",                     /*  1  English     */
    "%s %d %s %d",                      /*  2  Français    */
    "%s, den %d. %s %d",                /*  3  Deutsch     */
    "%s, %d de %s de %d",               /*  4  Español     */
    "%s, dia %d de %s de %d",           /*  5  Português   */
    "%s, %d %s %d",                     /*  6  Nederlands  */
    "%s, %d %s %d",                     /*  7  Italiano    */
    "%s, %d. %s %d",                    /*  8  Norsk       */
    "%s, %d %s %d",                     /*  9  Svenska     */
    "%s, %d. %s %d",                    /* 10  Dansk       */
    "%s, %d. %sta %d",                  /* 11  suomi       */
    "%d. %s %d., %s",                   /* 12  Magyar      */
    "%s, %d %s %d",                     /* 13  polski      */
    "%s %d %s %d"                       /* 14  Romaneste   */
};

const N_char DateCalc_Language_to_Text_[DateCalc_LANGUAGES+1][32] =
{
    "???", "English", "Français", "Deutsch", "Español",
    "Português", "Nederlands", "Italiano", "Norsk", "Svenska",
    "Dansk", "suomi", "Magyar", "polski", "Romaneste"
};

/*****************************************************************************/
/*  MODULE IMPLEMENTATION:                                                   */
/*****************************************************************************/

static boolean DateCalc_is_digit(N_char c)
{
    N_int i = (N_int) c;

    if ((i >= 0x30) and (i <= 0x39)) return(true);
    return(false);
}

static boolean DateCalc_is_alnum(N_char c)
{
    N_int i = (N_int) c;

    if (((i >= 0x30) and (i <= 0x39)) or
        ((i >= 0x41) and (i <= 0x5A)) or
        ((i >= 0x61) and (i <= 0x7A)) or
        ((i >= 0xC0) and (i <= 0xD6)) or
        ((i >= 0xD8) and (i <= 0xF6)) or
        ((i >= 0xF8) and (i <= 0xFF)))
            return(true);
    return(false);
}

N_char DateCalc_ISO_LC(N_char c)
{
    N_int i = (N_int) c;

    if (((i >= 0x41) and (i <= 0x5A)) or
        ((i >= 0xC0) and (i <= 0xD6)) or
        ((i >= 0xD8) and (c <= 0xDE))) i += 0x20;
    return((N_char) i);
}

N_char DateCalc_ISO_UC(N_char c)
{
    N_int i = (N_int) c;

    if (((i >= 0x61) and (i <= 0x7A)) or
        ((i >= 0xE0) and (i <= 0xF6)) or
        ((i >= 0xF8) and (c <= 0xFE))) i -= 0x20;
    return((N_char) i);
}

static Z_long DateCalc_Year_to_Days(Z_int year)
{
    Z_long days;

    days = year * 365L;
    days += year >>= 2;
    days -= year /= 25;
    days += year >>  2;
    return(days);
}

static boolean DateCalc_scan9(charptr str, Z_int len, Z_int idx, boolean neg)
{   /* Mnemonic: COBOL "PIC 9" */
    if ((str != NULL) and (idx >= 0) and (idx < len))
        return( DateCalc_is_digit(str[idx]) XOR neg );
    return(false);
}

static boolean DateCalc_scanx(charptr str, Z_int len, Z_int idx, boolean neg)
{   /* Mnemonic: COBOL "PIC X" */
    if ((str != NULL) and (idx >= 0) and (idx < len))
        return( DateCalc_is_alnum(str[idx]) XOR neg );
    return(false);
}

static Z_int DateCalc_Str2Int(charptr string, Z_int length)
{
    Z_int number = 0;

    while (length-- > 0)
    {
        if (number) number *= 10;
        number += (Z_int) (*string++ - '0');
    }
    return(number);
}

static void DateCalc_Center(charptr *target, charptr source, Z_int width)
{
    Z_int length;
    Z_int blank;

    length = strlen((char *)source);
    if (length > width) length = width;
    blank = width - length;
    blank >>= 1;
    while (blank-- > 0) *(*target)++ = ' ';
    while (length-- > 0) *(*target)++ = *source++;
    *(*target)++ = '\n';
    *(*target)   = '\0';
}

static void DateCalc_Blank(charptr *target, Z_int count)
{
    while (count-- > 0) *(*target)++ = ' ';
    *(*target) = '\0';
}

static void DateCalc_Newline(charptr *target, Z_int count)
{
    while (count-- > 0) *(*target)++ = '\n';
    *(*target) = '\0';
}

static void DateCalc_Normalize_Time(Z_long *Dd, Z_long *Dh, Z_long *Dm, Z_long *Ds)
{
    Z_long quot;

    quot = (Z_long) (*Ds / 60L);
    *Ds -= quot * 60L;
    *Dm += quot;
    quot = (Z_long) (*Dm / 60L);
    *Dm -= quot * 60L;
    *Dh += quot;
    quot = (Z_long) (*Dh / 24L);
    *Dh -= quot * 24L;
    *Dd += quot;
}

static void DateCalc_Normalize_Ranges(Z_long *Dd, Z_long *Dh, Z_long *Dm, Z_long *Ds)
{
    Z_long quot;

    /* Prevent overflow errors on systems */
    /* with short "long"s (e.g. 32 bits): */

    quot = (Z_long) (*Dh / 24L);
    *Dh -= quot * 24L;
    *Dd += quot;
    quot = (Z_long) (*Dm / 60L);
    *Dm -= quot * 60L;
    *Dh += quot;
    DateCalc_Normalize_Time(Dd,Dh,Dm,Ds);
}

static void DateCalc_Normalize_Signs(Z_long *Dd, Z_long *Dh, Z_long *Dm, Z_long *Ds)
{
    Z_long quot;

    quot = (Z_long) (*Ds / 86400L);
    *Ds -= quot * 86400L;
    *Dd += quot;
    if (*Dd != 0L)
    {
        if (*Dd > 0L)
        {
            if (*Ds < 0L)
            {
                *Ds += 86400L;
                (*Dd)--;
            }
        }
        else
        {
            if (*Ds > 0L)
            {
                *Ds -= 86400L;
                (*Dd)++;
            }
        }
    }
    *Dh = 0L;
    *Dm = 0L;
    if (*Ds != 0L) DateCalc_Normalize_Time(Dd,Dh,Dm,Ds);
}

void DateCalc_Normalize_DHMS(Z_long *Dd, Z_long *Dh, Z_long *Dm, Z_long *Ds)
{
    DateCalc_Normalize_Ranges(Dd,Dh,Dm,Ds);
    *Ds += ((*Dh * 60L) + *Dm) * 60L;
    DateCalc_Normalize_Signs(Dd,Dh,Dm,Ds);
}

/*****************************************************************************/

boolean DateCalc_leap_year(Z_int year)
{
    Z_int yy;

    return( ((year AND 0x03) == 0) and
            ( (((yy = (Z_int) (year / 100)) * 100) != year) or
                ((yy AND 0x03) == 0) ) );
}

boolean DateCalc_check_date(Z_int year, Z_int month, Z_int day)
{
    if ((year >= 1) and
        (month >= 1) and (month <= 12) and
        (day >= 1) and
        (day <= DateCalc_Days_in_Month_[DateCalc_leap_year(year)][month]))
            return(true);
    return(false);
}

boolean DateCalc_check_time(Z_int hour, Z_int min, Z_int sec)
{
    if ((hour >= 0) and (min >= 0) and (sec >= 0) and
        (hour < 24) and (min < 60) and (sec < 60))
            return(true);
    return(false);
}

boolean DateCalc_check_business_date(Z_int year, Z_int week, Z_int dow)
{
    if ((year >= 1) and
        (week >= 1) and (week <= DateCalc_Weeks_in_Year(year)) and
        (dow >= 1) and (dow <= 7))
            return(true);
    return(false);
}

Z_int DateCalc_Day_of_Year(Z_int year, Z_int month, Z_int day)
{
    boolean leap;

    if ((year >= 1) and
        (month >= 1) and (month <= 12) and
        (day >= 1) and
        (day <= DateCalc_Days_in_Month_[leap=DateCalc_leap_year(year)][month]))
            return( DateCalc_Days_in_Year_[leap][month] + day );
    return(0);
}

Z_long DateCalc_Date_to_Days(Z_int year, Z_int month, Z_int day)
{
    boolean leap;

    if ((year >= 1) and
        (month >= 1) and (month <= 12) and
        (day >= 1) and
        (day <= DateCalc_Days_in_Month_[leap=DateCalc_leap_year(year)][month]))
            return( DateCalc_Year_to_Days(--year) +
                    DateCalc_Days_in_Year_[leap][month] + day );
    return(0L);
}

Z_int DateCalc_Day_of_Week(Z_int year, Z_int month, Z_int day)
{
    Z_long days;

    days = DateCalc_Date_to_Days(year,month,day);
    if (days > 0L)
    {
        days--;
        days %= 7L;
        days++;
    }
    return( (Z_int) days );
}

Z_int DateCalc_Weeks_in_Year(Z_int year)
{
    return( 52 + ((DateCalc_Day_of_Week(year,1,1)   == 4) or
                  (DateCalc_Day_of_Week(year,12,31) == 4)) );
}

Z_int DateCalc_Week_Number(Z_int year, Z_int month, Z_int day)
{
    Z_int first;

    first = DateCalc_Day_of_Week(year,1,1) - 1;
    return( (Z_int)
        ( (DateCalc_Delta_Days(year,1,1, year,month,day) + first) / 7L )
        + (first < 4) );
}

boolean DateCalc_week_of_year(Z_int *week,
                              Z_int *year, Z_int month, Z_int day)
{
    if (DateCalc_check_date(*year,month,day))
    {
        *week = DateCalc_Week_Number(*year,month,day);
        if (*week == 0) *week = DateCalc_Weeks_in_Year(--(*year));
        else if (*week > DateCalc_Weeks_in_Year(*year))
        {
            *week = 1;
            (*year)++;
        }
        return(true);
    }
    return(false);
}

boolean DateCalc_monday_of_week(Z_int  week,
                                Z_int *year, Z_int *month, Z_int *day)
{
    Z_int first;

    *month = *day = 1;
    first = DateCalc_Day_of_Week(*year,1,1) - 1;
    if (first < 4) week--;
    return( DateCalc_add_delta_days(year,month,day, (week * 7L - first)) );
}

boolean
DateCalc_nth_weekday_of_month_year(Z_int *year, Z_int *month, Z_int *day,
                                   Z_int  dow,  Z_int  n)
{
    Z_int  mm = *month;
    Z_int  first;
    Z_long delta;

    *day = 1;
    if ((*year < 1) or
        (mm < 1) or (mm > 12) or
        (dow < 1) or (dow > 7) or
        (n < 1) or (n > 5))
        return(false);
    first = DateCalc_Day_of_Week(*year,mm,1);
    if (dow < first) dow += 7;
    delta = (Z_long) (dow - first);
    delta += (n-1) * 7L;
    if (DateCalc_add_delta_days(year,month,day,delta) and (*month == mm))
        return(true);
    return(false);
}

boolean DateCalc_standard_to_business(Z_int *year,  Z_int *week, Z_int *dow,
                                      Z_int  month, Z_int  day)
{
    Z_int yy = *year;

    if (DateCalc_week_of_year(week,year,month,day))
    {
        *dow = DateCalc_Day_of_Week(yy,month,day);
        return(true);
    }
    return(false);
}

boolean DateCalc_business_to_standard(Z_int *year, Z_int *month, Z_int *day,
                                      Z_int  week, Z_int  dow)
{
    Z_int  first;
    Z_long delta;

    if (DateCalc_check_business_date(*year,week,dow))
    {
        *month = *day = 1;
        first = DateCalc_Day_of_Week(*year,1,1);
        delta = ((week + (first > 4) - 1) * 7L) + (dow - first);
        return( DateCalc_add_delta_days(year,month,day,delta) );
    }
    return(false);
}

Z_long DateCalc_Delta_Days(Z_int year1, Z_int month1, Z_int day1,
                           Z_int year2, Z_int month2, Z_int day2)
{
    return( DateCalc_Date_to_Days(year2,month2,day2) -
            DateCalc_Date_to_Days(year1,month1,day1) );
}

boolean DateCalc_delta_hms(Z_long *Dd,
                           Z_int  *Dh,    Z_int *Dm,   Z_int *Ds,
                           Z_int   hour1, Z_int  min1, Z_int  sec1,
                           Z_int   hour2, Z_int  min2, Z_int  sec2)
{
    Z_long HH;
    Z_long MM;
    Z_long SS;

    if (DateCalc_check_time(hour1,min1,sec1) and
        DateCalc_check_time(hour2,min2,sec2))
    {
        SS = ((((hour2 * 60L) + min2) * 60L) + sec2) -
             ((((hour1 * 60L) + min1) * 60L) + sec1);
        DateCalc_Normalize_Signs(Dd,&HH,&MM,&SS);
        *Dh = (Z_int) HH;
        *Dm = (Z_int) MM;
        *Ds = (Z_int) SS;
        return(true);
    }
    return(false);
}

boolean DateCalc_delta_dhms(Z_long *Dd,
                            Z_int  *Dh,    Z_int *Dm,     Z_int *Ds,
                            Z_int   year1, Z_int  month1, Z_int  day1,
                            Z_int   hour1, Z_int  min1,   Z_int  sec1,
                            Z_int   year2, Z_int  month2, Z_int  day2,
                            Z_int   hour2, Z_int  min2,   Z_int  sec2)
{
    *Dd = *Dh = *Dm = *Ds = 0;
    if (DateCalc_check_date(year1,month1,day1) and
        DateCalc_check_date(year2,month2,day2))
    {
        *Dd = DateCalc_Delta_Days(year1,month1,day1, year2,month2,day2);
        return( DateCalc_delta_hms(Dd,Dh,Dm,Ds,
                                   hour1,min1,sec1,
                                   hour2,min2,sec2) );
    }
    return(false);
}

boolean DateCalc_delta_ymd(Z_int *year1, Z_int *month1, Z_int *day1,
                           Z_int  year2, Z_int  month2, Z_int  day2)
{
    if (DateCalc_check_date(*year1,*month1,*day1) and
        DateCalc_check_date(year2,month2,day2))
    {
        *day1   = day2   - *day1;
        *month1 = month2 - *month1;
        *year1  = year2  - *year1;
        return(true);
    }
    return(false);
}

boolean DateCalc_delta_ymdhms(Z_int *D_y,   Z_int *D_m,    Z_int *D_d,
                              Z_int *Dh,    Z_int *Dm,     Z_int *Ds,
                              Z_int  year1, Z_int  month1, Z_int  day1,
                              Z_int  hour1, Z_int  min1,   Z_int  sec1,
                              Z_int  year2, Z_int  month2, Z_int  day2,
                              Z_int  hour2, Z_int  min2,   Z_int  sec2)
{
    Z_long Dd;

    if (not DateCalc_delta_ymd(&year1,&month1,&day1, year2,month2,day2))
        return(false);
    Dd = (Z_long) day1;
    if (not DateCalc_delta_hms(&Dd,Dh,Dm,Ds, hour1,min1,sec1, hour2,min2,sec2))
        return(false);
    *D_y = year1;
    *D_m = month1;
    *D_d = (Z_int) Dd;
    return(true);
}

boolean DateCalc_add_delta_days(Z_int *year, Z_int *month, Z_int *day,
                                                           Z_long Dd)
{
    Z_long  days;
    boolean leap;

    if (((days = DateCalc_Date_to_Days(*year,*month,*day)) > 0L) and
        ((days += Dd) > 0L))
    {
        *year = (Z_int) ( days / 365.2425 );
        *day  = (Z_int) ( days - DateCalc_Year_to_Days(*year) );
        if (*day < 1)
        {
            *day = (Z_int) ( days - DateCalc_Year_to_Days(*year-1) );
        }
        else (*year)++;
        leap = DateCalc_leap_year(*year);
        if (*day > DateCalc_Days_in_Year_[leap][13])
        {
            *day -= DateCalc_Days_in_Year_[leap][13];
            leap  = DateCalc_leap_year(++(*year));
        }
        for ( *month = 12; *month >= 1; (*month)-- )
        {
            if (*day > DateCalc_Days_in_Year_[leap][*month])
            {
                *day -= DateCalc_Days_in_Year_[leap][*month];
                break;
            }
        }
        return(true);
    }
    return(false);
}

boolean DateCalc_add_delta_dhms(Z_int *year, Z_int *month, Z_int *day,
                                Z_int *hour, Z_int *min,   Z_int *sec,
                                Z_long Dd,
                                Z_long Dh,   Z_long Dm,    Z_long Ds)
{
    if (DateCalc_check_date(*year,*month,*day) and
        DateCalc_check_time(*hour,*min,*sec))
    {
        DateCalc_Normalize_Ranges(&Dd,&Dh,&Dm,&Ds);
        Ds += ((((*hour * 60L) + *min) * 60L) + *sec) +
               ((( Dh   * 60L) +  Dm)  * 60L);
        while (Ds < 0L)
        {
            Ds += 86400L;
            Dd--;
        }
        if (Ds > 0L)
        {
            Dh = 0L;
            Dm = 0L;
            DateCalc_Normalize_Time(&Dd,&Dh,&Dm,&Ds);
            *hour = (Z_int) Dh;
            *min  = (Z_int) Dm;
            *sec  = (Z_int) Ds;
        }
        else *hour = *min = *sec = 0;
        return( DateCalc_add_delta_days(year,month,day,Dd) );
    }
    return(false);
}

boolean DateCalc_add_year_month(Z_int *year, Z_int *month,
                                Z_long Dy,   Z_long Dm)
{
    Z_long quot;

    if ((*year < 1) or (*month < 1) or (*month > 12)) return(false);
    if (Dm != 0L)
    {
        Dm  += (Z_long) (*month - 1);
        quot = (Z_long) (Dm / 12L);
        Dm  -= quot * 12L;
        if (Dm < 0L)
        {
            Dm += 12L;
            quot--;
        }
        *month = (Z_int) (Dm + 1);
        Dy += quot;
    }
    if (Dy != 0L)
    {
        Dy += (Z_long) *year;
        *year = (Z_int) Dy;
    }
    if (*year < 1) return(false);
    return(true);
}

boolean DateCalc_add_delta_ym(Z_int *year, Z_int *month, Z_int *day,
                              Z_long Dy,   Z_long Dm)
{
    Z_int Dd;

    if (not DateCalc_check_date(*year,*month,*day)) return(false);
    if (not DateCalc_add_year_month(year,month,Dy,Dm)) return(false);
    if (*day >
        (Dd = DateCalc_Days_in_Month_[DateCalc_leap_year(*year)][*month]))
            *day = Dd;
    return(true);
}

boolean DateCalc_add_delta_ymd(Z_int *year, Z_int *month, Z_int *day,
                               Z_long Dy,   Z_long Dm,    Z_long Dd)
{
    if (not DateCalc_check_date(*year,*month,*day)) return(false);
    if (not DateCalc_add_year_month(year,month,Dy,Dm)) return(false);
    Dd += (Z_long) (*day - 1);
    *day = 1;
    if ((Dd != 0L) and not DateCalc_add_delta_days(year,month,day,Dd))
        return(false);
    return(true);
}

boolean DateCalc_add_delta_ymdhms(Z_int *year, Z_int *month, Z_int *day,
                                  Z_int *hour, Z_int *min,   Z_int *sec,
                                  Z_long D_y,  Z_long D_m,   Z_long D_d,
                                  Z_long Dh,   Z_long Dm,    Z_long Ds)
{
    if (not (DateCalc_check_date(*year,*month,*day) and
             DateCalc_check_time(*hour,*min,*sec))) return(false);
    if (not  DateCalc_add_year_month(year,month,D_y,D_m)) return(false);
    D_d += (Z_long) (*day - 1);
    *day = 1;
    return( DateCalc_add_delta_dhms(year,month,day,hour,min,sec,D_d,Dh,Dm,Ds) );
}

boolean DateCalc_system_clock(Z_int  *year, Z_int *month, Z_int *day,
                              Z_int  *hour, Z_int *min,   Z_int *sec,
                              Z_int  *doy,  Z_int *dow,   Z_int *dst,
                              boolean gmt)
{
    time_t seconds;
    struct tm *date;

    if (time(&seconds) >= 0)
    {
        if (gmt) date = gmtime(&seconds);
        else     date = localtime(&seconds);
        if (date != NULL)
        {
            *year  = (*date).tm_year + 1900;
            *month = (*date).tm_mon + 1;
            *day   = (*date).tm_mday;
            *hour  = (*date).tm_hour;
            *min   = (*date).tm_min;
            *sec   = (*date).tm_sec;
            *doy   = (*date).tm_yday + 1;
            *dow   = (*date).tm_wday; if (*dow == 0) *dow = 7;
            *dst   = (*date).tm_isdst;
            if (*dst != 0)
            {
                if (*dst < 0) *dst = -1;
                else          *dst =  1;
            }
            return(true);
        }
    }
    return(false);
}

boolean DateCalc_gmtime(Z_int  *year, Z_int *month, Z_int *day,
                        Z_int  *hour, Z_int *min,   Z_int *sec,
                        Z_int  *doy,  Z_int *dow,   Z_int *dst,
                        time_t  seconds)
{
    struct tm *date;

    if ((seconds >= 0) and ((date = gmtime(&seconds)) != NULL))
    {
        *year  = (*date).tm_year + 1900;
        *month = (*date).tm_mon + 1;
        *day   = (*date).tm_mday;
        *hour  = (*date).tm_hour;
        *min   = (*date).tm_min;
        *sec   = (*date).tm_sec;
        *doy   = (*date).tm_yday + 1;
        *dow   = (*date).tm_wday; if (*dow == 0) *dow = 7;
        *dst   = (*date).tm_isdst;
        if (*dst != 0)
        {
            if (*dst < 0) *dst = -1;
            else          *dst =  1;
        }
        return(true);
    }
    return(false);
}

boolean DateCalc_localtime(Z_int  *year, Z_int *month, Z_int *day,
                           Z_int  *hour, Z_int *min,   Z_int *sec,
                           Z_int  *doy,  Z_int *dow,   Z_int *dst,
                           time_t  seconds)
{
    struct tm *date;

    if ((seconds >= 0) and ((date = localtime(&seconds)) != NULL))
    {
        *year  = (*date).tm_year + 1900;
        *month = (*date).tm_mon + 1;
        *day   = (*date).tm_mday;
        *hour  = (*date).tm_hour;
        *min   = (*date).tm_min;
        *sec   = (*date).tm_sec;
        *doy   = (*date).tm_yday + 1;
        *dow   = (*date).tm_wday; if (*dow == 0) *dow = 7;
        *dst   = (*date).tm_isdst;
        if (*dst != 0)
        {
            if (*dst < 0) *dst = -1;
            else          *dst =  1;
        }
        return(true);
    }
    return(false);
}

/* MacOS (Classic):                                            */
/* <695056.0>     = Fri  1-Jan-1904 00:00:00 (time=0x00000000) */
/* <744766.23295> = Mon  6-Feb-2040 06:28:15 (time=0xFFFFFFFF) */

/* Unix:                                                       */
/* <719163.0>     = Thu  1-Jan-1970 00:00:00 (time=0x00000000) */
/* <744018.11647> = Tue 19-Jan-2038 03:14:07 (time=0x7FFFFFFF) */

boolean DateCalc_mktime(time_t *seconds,
                        Z_int year, Z_int month, Z_int day,
                        Z_int hour, Z_int min,   Z_int sec,
                        Z_int doy,  Z_int dow,   Z_int dst)
{
    struct tm date;

    *seconds = (time_t) 0;

#ifdef MACOS_TRADITIONAL
    if ( (year  < 1904) or (year  > 2040) or
#else
    if ( (year  < 1970) or (year  > 2038) or
#endif
         (month <    1) or (month >   12) or
         (day   <    1) or (day   >   31) or
         (hour  <    0) or (hour  >   23) or
         (min   <    0) or (min   >   59) or
         (sec   <    0) or (sec   >   59) )
    return(false);

#ifdef MACOS_TRADITIONAL
    if ( (year == 2040) and ( (month >  2) or
                            ( (month == 2) and ( (day >  6) or
                                               ( (day == 6) and ( (hour >  6) or
                                                                ( (hour == 6) and ( (min >  28) or
                                                                                  ( (min == 28) and (sec > 15) ) ))))))) )
    return(false);
#else
    if ( (year == 2038) and ( (month >  1) or
                            ( (month == 1) and ( (day >  19) or
                                               ( (day == 19) and ( (hour >  3) or
                                                                 ( (hour == 3) and ( (min >  14) or
                                                                                   ( (min == 14) and (sec > 7) ) ))))))) )
    return(false);
#endif

    year -= 1900;
    month--;
    if (doy <= 0) doy = -1;
    else          doy--;
    if (dow <= 0) dow = -1; else
    if (dow == 7) dow =  0;
    if (dst != 0)
    {
        if (dst < 0) dst = -1;
        else         dst =  1;
    }
    date.tm_year  = year;
    date.tm_mon   = month;
    date.tm_mday  = day;
    date.tm_hour  = hour;
    date.tm_min   = min;
    date.tm_sec   = sec;
    date.tm_yday  = doy;
    date.tm_wday  = dow;
    date.tm_isdst = dst;
    *seconds = mktime(&date);
    return(*seconds >= 0);
}

boolean DateCalc_timezone(Z_int *year, Z_int *month, Z_int *day,
                          Z_int *hour, Z_int *min,   Z_int *sec,
                          Z_int *dst,  time_t when)
{
    struct tm *date;
    Z_int  year1;
    Z_int  month1;
    Z_int  day1;
    Z_int  hour1;
    Z_int  min1;
    Z_int  sec1;
    Z_int  year2;
    Z_int  month2;
    Z_int  day2;
    Z_int  hour2;
    Z_int  min2;
    Z_int  sec2;

    if (when >= 0)
    {
        if ((date = gmtime(&when)) == NULL) return(false);
        year1  = (*date).tm_year + 1900;
        month1 = (*date).tm_mon + 1;
        day1   = (*date).tm_mday;
        hour1  = (*date).tm_hour;
        min1   = (*date).tm_min;
        sec1   = (*date).tm_sec;
        if ((date = localtime(&when)) == NULL) return(false);
        year2  = (*date).tm_year + 1900;
        month2 = (*date).tm_mon + 1;
        day2   = (*date).tm_mday;
        hour2  = (*date).tm_hour;
        min2   = (*date).tm_min;
        sec2   = (*date).tm_sec;
        if (DateCalc_delta_ymdhms(year, month, day,  hour, min, sec,
                                  year1,month1,day1, hour1,min1,sec1,
                                  year2,month2,day2, hour2,min2,sec2))
        {
            *dst = (*date).tm_isdst;
            if (*dst != 0)
            {
                if (*dst < 0) *dst = -1;
                else          *dst =  1;
            }
            return(true);
        }
    }
    return(false);
}

/* MacOS (Classic):                                            */
/* <695056.0>     = Fri  1-Jan-1904 00:00:00 (time=0x00000000) */
/* <744766.23295> = Mon  6-Feb-2040 06:28:15 (time=0xFFFFFFFF) */

/* Unix:                                                       */
/* <719163.0>     = Thu  1-Jan-1970 00:00:00 (time=0x00000000) */
/* <744018.11647> = Tue 19-Jan-2038 03:14:07 (time=0x7FFFFFFF) */

#ifdef MACOS_TRADITIONAL
    #define DateCalc_DAYS_TO_EPOCH  695056L
    #define DateCalc_DAYS_TO_OVFLW  744766L
    #define DateCalc_SECS_TO_OVFLW   23295L
#else
    #define DateCalc_DAYS_TO_EPOCH  719163L
    #define DateCalc_DAYS_TO_OVFLW  744018L
    #define DateCalc_SECS_TO_OVFLW   11647L
#endif

/* Substitute for BSD's timegm(3) function: */

boolean DateCalc_date2time(time_t *seconds,
                           Z_int year, Z_int month, Z_int day,
                           Z_int hour, Z_int min,   Z_int sec)
{
    Z_long days;
#ifdef MACOS_TRADITIONAL
    N_long secs;
#else
    Z_long secs;
#endif

    *seconds = (time_t) 0;

    days = DateCalc_Date_to_Days(year,month,day);
    secs = (((hour * 60L) + min) * 60L) + sec;

    if (   (days <  DateCalc_DAYS_TO_EPOCH) or
#ifndef MACOS_TRADITIONAL
           (secs <  0L) or
#endif
           (days >  DateCalc_DAYS_TO_OVFLW) or
         ( (days == DateCalc_DAYS_TO_OVFLW) and (secs > DateCalc_SECS_TO_OVFLW) ) )
    return(false);

    *seconds = (time_t) (((days - DateCalc_DAYS_TO_EPOCH) * 86400L) + secs);
    return(true);
}

/* Substitute for POSIX's gmtime(3) function: */

boolean DateCalc_time2date(Z_int *year, Z_int *month, Z_int *day,
                           Z_int *hour, Z_int *min,   Z_int *sec,
                           time_t seconds)
{
#ifdef MACOS_TRADITIONAL
    N_long ss = (N_long) seconds;
    N_long mm;
    N_long hh;
    N_long dd;

    dd = (N_long) (ss / 86400L);
    ss -= dd * 86400L;
    mm = (N_long) (ss / 60L);
    ss -= mm * 60L;
    hh = (N_long) (mm / 60L);
#else
    Z_long ss = (Z_long) seconds;
    Z_long mm;
    Z_long hh;
    Z_long dd;

    if (ss < 0L) return(false);
    dd = (Z_long) (ss / 86400L);
    ss -= dd * 86400L;
    mm = (Z_long) (ss / 60L);
    ss -= mm * 60L;
    hh = (Z_long) (mm / 60L);
#endif

    mm -= hh * 60L;
    dd += (DateCalc_DAYS_TO_EPOCH-1L);
    *sec   = (Z_int) ss;
    *min   = (Z_int) mm;
    *hour  = (Z_int) hh;
    *day   = (Z_int) 1;
    *month = (Z_int) 1;
    *year  = (Z_int) 1;
    return( DateCalc_add_delta_days(year,month,day,dd) );
}

boolean DateCalc_easter_sunday(Z_int *year, Z_int *month, Z_int *day)
{
    /****************************************************************/
    /*                                                              */
    /*  Gauss'sche Regel (Gaussian Rule)                            */
    /*  ================================                            */
    /*                                                              */
    /*  Quelle / Source:                                            */
    /*                                                              */
    /*  H. H. Voigt, "Abriss der Astronomie", Wissenschaftsverlag,  */
    /*  Bibliographisches Institut, Seite 9.                        */
    /*                                                              */
    /****************************************************************/

    Z_int a, b, c, d, e, m, n;

    if ((*year < 1583) or (*year > 2299)) return(false);

    if      (*year < 1700) { m = 22; n = 2; }
    else if (*year < 1800) { m = 23; n = 3; }
    else if (*year < 1900) { m = 23; n = 4; }
    else if (*year < 2100) { m = 24; n = 5; }
    else if (*year < 2200) { m = 24; n = 6; }
    else                   { m = 25; n = 0; }

    a = *year % 19;
    b = *year % 4;
    c = *year % 7;
    d = (19 * a + m) % 30;
    e = (2 * b + 4 * c + 6 * d + n) % 7;
    *day = 22 + d + e;
    *month = 3;
    if (*day > 31)
    {
        *day -= 31; /* same as *day = d + e - 9; */
        (*month)++;
    }
    if ((*day == 26) and (*month == 4)) *day = 19;
    if ((*day == 25) and (*month == 4) and
        (d == 28) and (e == 6) and (a > 10)) *day = 18;
    return(true);
}

/*  Carnival Monday / Rosenmontag / Veille du Mardi Gras   =  easter sunday - 48  */
/*  Mardi Gras / Karnevalsdienstag / Mardi Gras            =  easter sunday - 47  */
/*  Ash Wednesday / Aschermittwoch / Mercredi des Cendres  =  easter sunday - 46  */
/*  Palm Sunday / Palmsonntag / Dimanche des Rameaux       =  easter sunday - 7   */
/*  Easter Friday / Karfreitag / Vendredi Saint            =  easter sunday - 2   */
/*  Easter Saturday / Ostersamstag / Samedi de Paques      =  easter sunday - 1   */
/*  Easter Monday / Ostermontag / Lundi de Paques          =  easter sunday + 1   */
/*  Ascension of Christ / Christi Himmelfahrt / Ascension  =  easter sunday + 39  */
/*  Whitsunday / Pfingstsonntag / Dimanche de Pentecote    =  easter sunday + 49  */
/*  Whitmonday / Pfingstmontag / Lundi de Pentecote        =  easter sunday + 50  */
/*  Feast of Corpus Christi / Fronleichnam / Fete-Dieu     =  easter sunday + 60  */

Z_int DateCalc_Decode_Month(charptr buffer, Z_int length) /* 0 = error */
{
    Z_int   i,j;
    Z_int   month;
    boolean same;
    boolean ok;

/*****************************************************************************/
/*  BEWARE that the parameter "length" must always be set in such a way      */
/*  so that the string in "buffer[0]" up to "buffer[length-1]" does not      */
/*  contain any terminating null character '\0'. Otherwise this routine      */
/*  may read beyond allocated memory, probably resulting in an access        */
/*  violation and program abortion. This problem cannot arise, for example,  */
/*  if you use the library function "strlen" to determine the length         */
/*  "length" of the string in "buffer".                                      */
/*****************************************************************************/

    month = 0;
    ok = true;
    for ( i = 1; ok and (i <= 12); i++ )
    {
        same = true;
        for ( j = 0; same and (j < length); j++ )
        {
            same = ( DateCalc_ISO_UC(buffer[j]) ==
                     DateCalc_ISO_UC(DateCalc_Month_to_Text_[DateCalc_Language][i][j]) );
        }
        if (same)
        {
            if (month > 0) ok = false;
            else           month = i;
        }
    }
    if (ok) return(month);
    else return(0);
}

Z_int DateCalc_Decode_Day_of_Week(charptr buffer, Z_int length) /* 0 = error */
{
    Z_int   i,j;
    Z_int   day;
    boolean same;
    boolean ok;

/*****************************************************************************/
/*  BEWARE that the parameter "length" must always be set in such a way      */
/*  so that the string in "buffer[0]" up to "buffer[length-1]" does not      */
/*  contain any terminating null character '\0'. Otherwise this routine      */
/*  may read beyond allocated memory, probably resulting in an access        */
/*  violation and program abortion. This problem cannot arise, for example,  */
/*  if you use the library function "strlen" to determine the length         */
/*  "length" of the string in "buffer".                                      */
/*****************************************************************************/

    day = 0;
    ok = true;
    for ( i = 1; ok and (i <= 7); i++ )
    {
        same = true;
        for ( j = 0; same and (j < length); j++ )
        {
            same = ( DateCalc_ISO_UC(buffer[j]) ==
                     DateCalc_ISO_UC(DateCalc_Day_of_Week_to_Text_[DateCalc_Language][i][j]) );
        }
        if (same)
        {
            if (day > 0) ok = false;
            else         day = i;
        }
    }
    if (ok) return(day);
    else return(0);
}

Z_int DateCalc_Decode_Language(charptr buffer, Z_int length) /* 0 = error */
{
    Z_int   i,j;
    Z_int   lang;
    boolean same;
    boolean ok;

/*****************************************************************************/
/*  BEWARE that the parameter "length" must always be set in such a way      */
/*  so that the string in "buffer[0]" up to "buffer[length-1]" does not      */
/*  contain any terminating null character '\0'. Otherwise this routine      */
/*  may read beyond allocated memory, probably resulting in an access        */
/*  violation and program abortion. This problem cannot arise, for example,  */
/*  if you use the library function "strlen" to determine the length         */
/*  "length" of the string in "buffer".                                      */
/*****************************************************************************/

    lang = 0;
    ok = true;
    for ( i = 1; ok and (i <= DateCalc_LANGUAGES); i++ )
    {
        same = true;
        for ( j = 0; same and (j < length); j++ )
        {
            same = ( DateCalc_ISO_UC(buffer[j]) ==
                     DateCalc_ISO_UC(DateCalc_Language_to_Text_[i][j]) );
        }
        if (same)
        {
            if (lang > 0) ok = false;
            else          lang = i;
        }
    }
    if (ok) return(lang);
    else return(0);
}

boolean DateCalc_decode_date_eu(charptr buffer,
                                Z_int *year, Z_int *month, Z_int *day)
{
    Z_int i,j;
    Z_int length;

    *year = *month = *day = 0;
    length = strlen((char *)buffer);
    if (length > 0)
    {
        i = 0;
        while (DateCalc_scan9(buffer,length,i,true)) i++;
        j = length-1;
        while (DateCalc_scan9(buffer,length,j,true)) j--;
        if (i+1 < j)        /* at least 3 chars, else error! */
        {
            buffer += i;
            length = j-i+1;
            i = 1;
            while (DateCalc_scan9(buffer,length,i,false)) i++;
            j = length-2;
            while (DateCalc_scan9(buffer,length,j,false)) j--;
            if (j < i)  /* only numerical chars without delimiters */
            {
                switch (length)
                {
                case 3:
                    *day   = DateCalc_Str2Int(buffer,  1);
                    *month = DateCalc_Str2Int(buffer+1,1);
                    *year  = DateCalc_Str2Int(buffer+2,1);
                    break;
                case 4:
                    *day   = DateCalc_Str2Int(buffer,  1);
                    *month = DateCalc_Str2Int(buffer+1,1);
                    *year  = DateCalc_Str2Int(buffer+2,2);
                    break;
                case 5:
                    *day   = DateCalc_Str2Int(buffer,  1);
                    *month = DateCalc_Str2Int(buffer+1,2);
                    *year  = DateCalc_Str2Int(buffer+3,2);
                    break;
                case 6:
                    *day   = DateCalc_Str2Int(buffer,  2);
                    *month = DateCalc_Str2Int(buffer+2,2);
                    *year  = DateCalc_Str2Int(buffer+4,2);
                    break;
                case 7:
                    *day   = DateCalc_Str2Int(buffer,  1);
                    *month = DateCalc_Str2Int(buffer+1,2);
                    *year  = DateCalc_Str2Int(buffer+3,4);
                    break;
                case 8:
                    *day   = DateCalc_Str2Int(buffer,  2);
                    *month = DateCalc_Str2Int(buffer+2,2);
                    *year  = DateCalc_Str2Int(buffer+4,4);
                    break;
                default:
                    return(false);
                    break;
                }
            }
            else        /* at least one non-numerical char (i <= j) */
            {
                *day  = DateCalc_Str2Int(buffer,i);
                *year = DateCalc_Str2Int(buffer+(j+1),length-(j+1));
                while (DateCalc_scanx(buffer,length,i,true)) i++;
                while (DateCalc_scanx(buffer,length,j,true)) j--;
                if (i <= j)         /* at least one char left for month */
                {
                    buffer += i;
                    length = j-i+1;
                    i = 1;
                    while (DateCalc_scanx(buffer,length,i,false)) i++;
                    if (i >= length)    /* ok, no more delimiters */
                    {
                        i = 0;
                        while (DateCalc_scan9(buffer,length,i,false)) i++;
                        if (i >= length) /* only digits for month */
                        {
                            *month = DateCalc_Str2Int(buffer,length);
                        }
                        else             /* match with month names */
                        {
                            *month = DateCalc_Decode_Month(buffer,length);
                        }
                    }
                    else return(false); /* delimiters inside month string */
                }
                else return(false); /* no chars left for month */
            }           /* at least one non-numerical char (i <= j) */
        }
        else return(false); /* less than 3 chars in buffer */
    }
    else return(false); /* length <= 0 */
    *year = DateCalc_Moving_Window(*year);
    return( DateCalc_check_date(*year,*month,*day) );
}

boolean DateCalc_decode_date_us(charptr buffer,
                                Z_int *year, Z_int *month, Z_int *day)
{
    Z_int i,j,k;
    Z_int length;

    *year = *month = *day = 0;
    length = strlen((char *)buffer);
    if (length > 0)
    {
        i = 0;
        while (DateCalc_scanx(buffer,length,i,true)) i++;
        j = length-1;
        while (DateCalc_scan9(buffer,length,j,true)) j--;
        if (i+1 < j)        /* at least 3 chars, else error! */
        {
            buffer += i;
            length = j-i+1;
            i = 1;
            while (DateCalc_scanx(buffer,length,i,false)) i++;
            j = length-2;
            while (DateCalc_scan9(buffer,length,j,false)) j--;
            if (i >= length)  /* only alphanumeric chars left */
            {
                if (j < 0) /* case 0 : xxxx999999xxxx */
                {          /*             j0     i    */
                    switch (length)
                    {
                    case 3:
                        *month = DateCalc_Str2Int(buffer,  1);
                        *day   = DateCalc_Str2Int(buffer+1,1);
                        *year  = DateCalc_Str2Int(buffer+2,1);
                        break;
                    case 4:
                        *month = DateCalc_Str2Int(buffer,  1);
                        *day   = DateCalc_Str2Int(buffer+1,1);
                        *year  = DateCalc_Str2Int(buffer+2,2);
                        break;
                    case 5:
                        *month = DateCalc_Str2Int(buffer,  1);
                        *day   = DateCalc_Str2Int(buffer+1,2);
                        *year  = DateCalc_Str2Int(buffer+3,2);
                        break;
                    case 6:
                        *month = DateCalc_Str2Int(buffer,  2);
                        *day   = DateCalc_Str2Int(buffer+2,2);
                        *year  = DateCalc_Str2Int(buffer+4,2);
                        break;
                    case 7:
                        *month = DateCalc_Str2Int(buffer,  1);
                        *day   = DateCalc_Str2Int(buffer+1,2);
                        *year  = DateCalc_Str2Int(buffer+3,4);
                        break;
                    case 8:
                        *month = DateCalc_Str2Int(buffer,  2);
                        *day   = DateCalc_Str2Int(buffer+2,2);
                        *year  = DateCalc_Str2Int(buffer+4,4);
                        break;
                    default:
                        return(false);
                        break;
                    }
                }
                else       /* case 1 : xxxxAAA999999xxxx */
                {          /*              0 j      i    */
                    *month = DateCalc_Decode_Month(buffer,j+1);
                    buffer += j+1;
                    length -= j+1;
                    switch (length)
                    {
                    case 2:
                        *day  = DateCalc_Str2Int(buffer,  1);
                        *year = DateCalc_Str2Int(buffer+1,1);
                        break;
                    case 3:
                        *day  = DateCalc_Str2Int(buffer,  1);
                        *year = DateCalc_Str2Int(buffer+1,2);
                        break;
                    case 4:
                        *day  = DateCalc_Str2Int(buffer,  2);
                        *year = DateCalc_Str2Int(buffer+2,2);
                        break;
                    case 5:
                        *day  = DateCalc_Str2Int(buffer,  1);
                        *year = DateCalc_Str2Int(buffer+1,4);
                        break;
                    case 6:
                        *day  = DateCalc_Str2Int(buffer,  2);
                        *year = DateCalc_Str2Int(buffer+2,4);
                        break;
                    default:
                        return(false);
                        break;
                    }
                }
            }              /*              0  i  j    l         */
            else           /* case 2 : xxxxAAAxxxx9999xxxx _OR_ */
            {              /* case 3 : xxxxAAAxx99xx9999xx      */
                k = 0;     /*              0  i    j    l       */
                while (DateCalc_scan9(buffer,length,k,false)) k++;
                if (k >= i) /* ok, only digits */
                {
                    *month = DateCalc_Str2Int(buffer,i);
                }
                else       /* no, some non-digits */
                {
                    *month = DateCalc_Decode_Month(buffer,i);
                    if (*month == 0) return(false);
                }
                buffer += i;
                length -= i;
                j -= i;
                k = j+1; /* remember start posn of day+year(2)/year(3) */
                i = 1;
                while (DateCalc_scanx(buffer,length,i,true)) i++;
                j--;
                while (DateCalc_scan9(buffer,length,j,true)) j--;
                if (j < i) /* case 2 : xxxxAAAxxxx9999xxxx */
                {          /*                j0   i   l    */
                    buffer += k;    /*            k        */
                    length -= k;
                    switch (length)
                    {
                    case 2:
                        *day  = DateCalc_Str2Int(buffer,  1);
                        *year = DateCalc_Str2Int(buffer+1,1);
                        break;
                    case 3:
                        *day  = DateCalc_Str2Int(buffer,  1);
                        *year = DateCalc_Str2Int(buffer+1,2);
                        break;
                    case 4:
                        *day  = DateCalc_Str2Int(buffer,  2);
                        *year = DateCalc_Str2Int(buffer+2,2);
                        break;
                    case 5:
                        *day  = DateCalc_Str2Int(buffer,  1);
                        *year = DateCalc_Str2Int(buffer+1,4);
                        break;
                    case 6:
                        *day  = DateCalc_Str2Int(buffer,  2);
                        *year = DateCalc_Str2Int(buffer+2,4);
                        break;
                    default:
                        return(false);
                        break;
                    }
                }
                else       /* case 3 : xxxxAAAxx99xx9999xx */
                {          /*                 0 ij  k   l  */
                    *year = DateCalc_Str2Int(buffer+k,length-k);
                    k = i;
                    while (DateCalc_scan9(buffer,length,k,false)) k++;
                    if (k > j)          /* ok, only digits */
                    {
                        *day = DateCalc_Str2Int(buffer+i,j-i+1);
                    }
                    else return(false); /* non-digits inside day */
                }
            }                 /* i < length */
        }
        else return(false); /* less than 3 chars in buffer */
    }
    else return(false); /* length <= 0 */
    *year = DateCalc_Moving_Window(*year);
    return( DateCalc_check_date(*year,*month,*day) );
}

Z_int DateCalc_Fixed_Window(Z_int year)
{
    if (year < 0) return(0);
    if (year < 100)
    {
        if (year < DateCalc_YEAR_OF_EPOCH) year += 100;
        year += DateCalc_CENTURY_OF_EPOCH;
    }
    return(year);
}

Z_int DateCalc_Moving_Window(Z_int year)
{
    time_t seconds;
    struct tm *date;
    Z_int  current;
    Z_int  century;

    if (year < 0) return(0);
    if (year < 100)
    {
        if ((time(&seconds) >= 0) and ((date = gmtime(&seconds)) != NULL))
        {
            current = (*date).tm_year + 1900;
            century = (Z_int)(current / 100);
            year += century * 100;
            if      (year <  current - 50) year += 100;
            else if (year >= current + 50) year -= 100;
        }
        else year = DateCalc_Fixed_Window(year);
    }
    return(year);
}

Z_int DateCalc_Compress(Z_int year, Z_int month, Z_int day)
{
    Z_int yy;

    if ((year >= DateCalc_EPOCH) and (year < (DateCalc_EPOCH + 100)))
    {
        yy = year;
        year -= DateCalc_EPOCH;
    }
    else
    {
        if ((year < 0) or (year > 99)) return(0);
        if (year < DateCalc_YEAR_OF_EPOCH)
        {
            yy = DateCalc_CENTURY_OF_EPOCH + 100 + year;
            year += 100 - DateCalc_YEAR_OF_EPOCH;
        }
        else
        {
            yy = DateCalc_CENTURY_OF_EPOCH + year;
            year -= DateCalc_YEAR_OF_EPOCH;
        }
    }
    if ((month < 1) or (month > 12)) return(0);
    if ((day < 1) or
        (day > DateCalc_Days_in_Month_[DateCalc_leap_year(yy)][month]))
        return(0);
    return( (year SHL 9) OR (month SHL 5) OR day );
}

boolean
DateCalc_uncompress(Z_int date,
                    Z_int *century, Z_int *year, Z_int *month, Z_int *day)
{
    if (date > 0)
    {
        *year  =  date SHR 9;
        *month = (date AND 0x01FF) SHR 5;
        *day   =  date AND 0x001F;

        if (*year < 100)
        {
            if (*year < 100-DateCalc_YEAR_OF_EPOCH)
            {
                *century = DateCalc_CENTURY_OF_EPOCH;
                *year += DateCalc_YEAR_OF_EPOCH;
            }
            else
            {
                *century = DateCalc_CENTURY_OF_EPOCH+100;
                *year -= 100-DateCalc_YEAR_OF_EPOCH;
            }
            return( DateCalc_check_date(*century+*year,*month,*day) );
        }
    }
    return(false);
}

boolean DateCalc_check_compressed(Z_int date)
{
    Z_int century;
    Z_int year;
    Z_int month;
    Z_int day;

    return( DateCalc_uncompress(date,&century,&year,&month,&day) );
}

charptr DateCalc_Compressed_to_Text(Z_int date)
{
    Z_int   century;
    Z_int   year;
    Z_int   month;
    Z_int   day;
    charptr string;

    string = (charptr) malloc(16);
    if (string == NULL) return(NULL);
    if (DateCalc_uncompress(date,&century,&year,&month,&day))
        sprintf((char *)string,"%02d-%.3s-%02d",day,
        DateCalc_Month_to_Text_[DateCalc_Language][month],year);
    else
        sprintf((char *)string,"??""-???""-??");
        /* prevent interpretation as trigraphs */
    return(string);
}

charptr DateCalc_Date_to_Text(Z_int year, Z_int month, Z_int day)
{
    charptr string;

    if (DateCalc_check_date(year,month,day) and
        ((string = (charptr) malloc(32)) != NULL))
    {
        if (DateCalc_Day_of_Week_Abbreviation_[DateCalc_Language][0][0] != '\0')
        {
            sprintf((char *)string,"%.3s %d-%.3s-%d",
                DateCalc_Day_of_Week_Abbreviation_[DateCalc_Language][DateCalc_Day_of_Week(year,month,day)],
                day,DateCalc_Month_to_Text_[DateCalc_Language][month],year);
            return(string);
        }
        else
        {
            sprintf((char *)string,"%.3s %d-%.3s-%d",
                DateCalc_Day_of_Week_to_Text_[DateCalc_Language][DateCalc_Day_of_Week(year,month,day)],
                day,DateCalc_Month_to_Text_[DateCalc_Language][month],year);
            return(string);
        }
    }
    return(NULL);
}

charptr DateCalc_English_Ordinal(charptr result, Z_int number)
{
    N_int length;
    N_int digit;

    sprintf((char *)result, "%d", number);
    if ((length = strlen((char *)result)))
    {
        if ( not
             (
               ( ((length > 1) and (result[length-2] != '1')) or (length == 1) )
               and
               ( (digit = (N_int)(result[length-1] XOR '0')) <= 3 )
             )
           )
        {
            digit = 0;
        }
        sprintf( (char *)(result+length), "%s",
            DateCalc_English_Ordinals_[digit] );
    }
    return(result);
}

charptr DateCalc_Date_to_Text_Long(Z_int year, Z_int month, Z_int day)
{
    charptr string;
    blockdef(buffer,64);

    if (DateCalc_check_date(year,month,day) and
        ((string = (charptr) malloc(64)) != NULL))
    {
        switch (DateCalc_Language)
        {
            case 1:
                sprintf(
                    (char *)string,
                    (char *)DateCalc_Date_Long_Format_[DateCalc_Language],
                    DateCalc_Day_of_Week_to_Text_[DateCalc_Language]
                        [DateCalc_Day_of_Week(year,month,day)],
                    DateCalc_Month_to_Text_[DateCalc_Language][month],
                    DateCalc_English_Ordinal(buffer,day),
                    year );
                break;
            case 12:
                sprintf(
                    (char *)string,
                    (char *)DateCalc_Date_Long_Format_[DateCalc_Language],
                    year,
                    DateCalc_Month_to_Text_[DateCalc_Language][month],
                    day,
                    DateCalc_Day_of_Week_to_Text_[DateCalc_Language]
                        [DateCalc_Day_of_Week(year,month,day)] );
                break;
            default:
                sprintf(
                    (char *)string,
                    (char *)DateCalc_Date_Long_Format_[DateCalc_Language],
                    DateCalc_Day_of_Week_to_Text_[DateCalc_Language]
                        [DateCalc_Day_of_Week(year,month,day)],
                    day,
                    DateCalc_Month_to_Text_[DateCalc_Language][month],
                    year );
                break;
        }
        return(string);
    }
    return(NULL);
}

charptr DateCalc_Calendar(Z_int year, Z_int month, boolean orthodox)
{
    blockdef(buffer,64);
    charptr string;
    charptr cursor;
    Z_int first;
    Z_int last;
    Z_int day;

    string = (charptr) malloc(256);
    if (string == NULL) return(NULL);
    cursor = string;
    DateCalc_Newline(&cursor,1);
    sprintf((char *)buffer,"%s %d",
        DateCalc_Month_to_Text_[DateCalc_Language][month],year);
    *buffer = DateCalc_ISO_UC(*buffer);
    DateCalc_Center(&cursor,buffer,27);
    if (DateCalc_Day_of_Week_Abbreviation_[DateCalc_Language][0][0] != '\0')
    {
        if (orthodox)
            sprintf((char *)cursor,"%3.3s %3.3s %3.3s %3.3s %3.3s %3.3s %3.3s\n",
                DateCalc_Day_of_Week_Abbreviation_[DateCalc_Language][7],
                DateCalc_Day_of_Week_Abbreviation_[DateCalc_Language][1],
                DateCalc_Day_of_Week_Abbreviation_[DateCalc_Language][2],
                DateCalc_Day_of_Week_Abbreviation_[DateCalc_Language][3],
                DateCalc_Day_of_Week_Abbreviation_[DateCalc_Language][4],
                DateCalc_Day_of_Week_Abbreviation_[DateCalc_Language][5],
                DateCalc_Day_of_Week_Abbreviation_[DateCalc_Language][6]);
        else /* conform to ISO standard */
            sprintf((char *)cursor,"%3.3s %3.3s %3.3s %3.3s %3.3s %3.3s %3.3s\n",
                DateCalc_Day_of_Week_Abbreviation_[DateCalc_Language][1],
                DateCalc_Day_of_Week_Abbreviation_[DateCalc_Language][2],
                DateCalc_Day_of_Week_Abbreviation_[DateCalc_Language][3],
                DateCalc_Day_of_Week_Abbreviation_[DateCalc_Language][4],
                DateCalc_Day_of_Week_Abbreviation_[DateCalc_Language][5],
                DateCalc_Day_of_Week_Abbreviation_[DateCalc_Language][6],
                DateCalc_Day_of_Week_Abbreviation_[DateCalc_Language][7]);
    }
    else
    {
        if (orthodox)
            sprintf((char *)cursor,"%3.3s %3.3s %3.3s %3.3s %3.3s %3.3s %3.3s\n",
                DateCalc_Day_of_Week_to_Text_[DateCalc_Language][7],
                DateCalc_Day_of_Week_to_Text_[DateCalc_Language][1],
                DateCalc_Day_of_Week_to_Text_[DateCalc_Language][2],
                DateCalc_Day_of_Week_to_Text_[DateCalc_Language][3],
                DateCalc_Day_of_Week_to_Text_[DateCalc_Language][4],
                DateCalc_Day_of_Week_to_Text_[DateCalc_Language][5],
                DateCalc_Day_of_Week_to_Text_[DateCalc_Language][6]);
        else /* conform to ISO standard */
            sprintf((char *)cursor,"%3.3s %3.3s %3.3s %3.3s %3.3s %3.3s %3.3s\n",
                DateCalc_Day_of_Week_to_Text_[DateCalc_Language][1],
                DateCalc_Day_of_Week_to_Text_[DateCalc_Language][2],
                DateCalc_Day_of_Week_to_Text_[DateCalc_Language][3],
                DateCalc_Day_of_Week_to_Text_[DateCalc_Language][4],
                DateCalc_Day_of_Week_to_Text_[DateCalc_Language][5],
                DateCalc_Day_of_Week_to_Text_[DateCalc_Language][6],
                DateCalc_Day_of_Week_to_Text_[DateCalc_Language][7]);
    }
    cursor += 28;
    first = DateCalc_Day_of_Week(year,month,1);
    last = DateCalc_Days_in_Month_[DateCalc_leap_year(year)][month];
    if (orthodox) { if (first == 7) first = 0; }
    else          { first--; }
    if (first) DateCalc_Blank(&cursor,(first<<2)-1);
    for ( day = 1; day <= last; day++, first++ )
    {
        if (first > 0)
        {
            if (first > 6)
            {
                first = 0;
                DateCalc_Newline(&cursor,1);
            }
            else DateCalc_Blank(&cursor,1);
        }
        sprintf((char *)cursor," %2d",day);
        cursor += 3;
    }
    DateCalc_Newline(&cursor,2);
    return(string);
}

void DateCalc_Dispose(charptr string)
{
    free((voidptr) string);
}

charptr DateCalc_Version(void)
{
    return( (charptr) "5.4" );
}

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
#endif
