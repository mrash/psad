

/*****************************************************************************/
/*                                                                           */
/*    Copyright (c) 1995 - 2004 by Steffen Beyer.                            */
/*    All rights reserved.                                                   */
/*                                                                           */
/*    This package is free software; you can redistribute it                 */
/*    and/or modify it under the same terms as Perl itself.                  */
/*                                                                           */
/*****************************************************************************/


#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


#include "patchlevel.h"
#if ((PATCHLEVEL < 4) || ((PATCHLEVEL == 4) && (SUBVERSION < 5)))
/* PL_na was introduced in perl5.004_05 */
#ifndef PL_na
    #define PL_na na
#endif
#endif
#if (PATCHLEVEL < 4)
/* GIMME_V was introduced in perl5.004 */
#ifndef GIMME_V
    #define GIMME_V GIMME
#endif
#endif


#include "DateCalc.h"


const char *_DateCalc_DATE_ERROR       = "not a valid date";
const char *_DateCalc_TIME_ERROR       = "not a valid time";
const char *_DateCalc_YEAR_ERROR       = "year out of range";
const char *_DateCalc_MONTH_ERROR      = "month out of range";
const char *_DateCalc_WEEK_ERROR       = "week out of range";
const char *_DateCalc_DAYOFWEEK_ERROR  = "day of week out of range";
const char *_DateCalc_DATE_RANGE_ERROR = "date out of range";
const char *_DateCalc_TIME_RANGE_ERROR = "time out of range";
const char *_DateCalc_FACTOR_ERROR     = "factor out of range";
const char *_DateCalc_LANGUAGE_ERROR   = "language not available";
const char *_DateCalc_SYSTEM_ERROR     = "not available on this system";
const char *_DateCalc_MEMORY_ERROR     = "unable to allocate memory";
const char *_DateCalc_STRING_ERROR     = "argument is not a string";


#define DATECALC_STRING(ref,var,len) \
    ( ref && !(SvROK(ref)) && SvPOK(ref) && \
    (var = (charptr)SvPV(ref,PL_na)) && \
    ((len = (N_int)SvCUR(ref)) | 1) )


#define DATECALC_ERROR(message) \
    croak("Date::Calc::%s(): %s", GvNAME(CvGV(cv)), message)


#define DATECALC_DATE_ERROR \
    DATECALC_ERROR( _DateCalc_DATE_ERROR )

#define DATECALC_TIME_ERROR \
    DATECALC_ERROR( _DateCalc_TIME_ERROR )

#define DATECALC_YEAR_ERROR \
    DATECALC_ERROR( _DateCalc_YEAR_ERROR )

#define DATECALC_MONTH_ERROR \
    DATECALC_ERROR( _DateCalc_MONTH_ERROR )

#define DATECALC_WEEK_ERROR \
    DATECALC_ERROR( _DateCalc_WEEK_ERROR )

#define DATECALC_DAYOFWEEK_ERROR \
    DATECALC_ERROR( _DateCalc_DAYOFWEEK_ERROR )

#define DATECALC_DATE_RANGE_ERROR \
    DATECALC_ERROR( _DateCalc_DATE_RANGE_ERROR )

#define DATECALC_TIME_RANGE_ERROR \
    DATECALC_ERROR( _DateCalc_TIME_RANGE_ERROR )

#define DATECALC_FACTOR_ERROR \
    DATECALC_ERROR( _DateCalc_FACTOR_ERROR )

#define DATECALC_LANGUAGE_ERROR \
    DATECALC_ERROR( _DateCalc_LANGUAGE_ERROR )

#define DATECALC_SYSTEM_ERROR \
    DATECALC_ERROR( _DateCalc_SYSTEM_ERROR )

#define DATECALC_MEMORY_ERROR \
    DATECALC_ERROR( _DateCalc_MEMORY_ERROR )

#define DATECALC_STRING_ERROR \
    DATECALC_ERROR( _DateCalc_STRING_ERROR )


MODULE = Date::Calc		PACKAGE = Date::Calc		PREFIX = DateCalc_


PROTOTYPES: DISABLE


void
DateCalc_Days_in_Year(year,month)
    Z_int	year
    Z_int	month
PPCODE:
{
    if (year > 0)
    {
        if ((month >= 1) and (month <= 12))
        {
            EXTEND(sp,1);
            PUSHs(sv_2mortal(newSViv((IV)DateCalc_Days_in_Year_[DateCalc_leap_year(year)][month+1])));
        }
        else DATECALC_MONTH_ERROR;
    }
    else DATECALC_YEAR_ERROR;
}


void
DateCalc_Days_in_Month(year,month)
    Z_int	year
    Z_int	month
PPCODE:
{
    if (year > 0)
    {
        if ((month >= 1) and (month <= 12))
        {
            EXTEND(sp,1);
            PUSHs(sv_2mortal(newSViv((IV)DateCalc_Days_in_Month_[DateCalc_leap_year(year)][month])));
        }
        else DATECALC_MONTH_ERROR;
    }
    else DATECALC_YEAR_ERROR;
}


Z_int
DateCalc_Weeks_in_Year(year)
    Z_int	year
CODE:
{
    if (year > 0)
    {
        RETVAL = DateCalc_Weeks_in_Year(year);
    }
    else DATECALC_YEAR_ERROR;
}
OUTPUT:
RETVAL


boolean
DateCalc_leap_year(year)
    Z_int	year
CODE:
{
    if (year > 0)
    {
        RETVAL = DateCalc_leap_year(year);
    }
    else DATECALC_YEAR_ERROR;
}
OUTPUT:
RETVAL


boolean
DateCalc_check_date(year,month,day)
    Z_int	year
    Z_int	month
    Z_int	day


boolean
DateCalc_check_time(hour,min,sec)
    Z_int	hour
    Z_int	min
    Z_int	sec


boolean
DateCalc_check_business_date(year,week,dow)
    Z_int	year
    Z_int	week
    Z_int	dow


Z_int
DateCalc_Day_of_Year(year,month,day)
    Z_int	year
    Z_int	month
    Z_int	day
CODE:
{
    RETVAL = DateCalc_Day_of_Year(year,month,day);
    if (RETVAL == 0) DATECALC_DATE_ERROR;
}
OUTPUT:
RETVAL


Z_long
DateCalc_Date_to_Days(year,month,day)
    Z_int	year
    Z_int	month
    Z_int	day
CODE:
{
    RETVAL = DateCalc_Date_to_Days(year,month,day);
    if (RETVAL == 0) DATECALC_DATE_ERROR;
}
OUTPUT:
RETVAL


Z_int
DateCalc_Day_of_Week(year,month,day)
    Z_int	year
    Z_int	month
    Z_int	day
CODE:
{
    RETVAL = DateCalc_Day_of_Week(year,month,day);
    if (RETVAL == 0) DATECALC_DATE_ERROR;
}
OUTPUT:
RETVAL


Z_int
DateCalc_Week_Number(year,month,day)
    Z_int	year
    Z_int	month
    Z_int	day
CODE:
{
    if (DateCalc_check_date(year,month,day))
    {
        RETVAL = DateCalc_Week_Number(year,month,day);
    }
    else DATECALC_DATE_ERROR;
}
OUTPUT:
RETVAL


void
DateCalc_Week_of_Year(year,month,day)
    Z_int	year
    Z_int	month
    Z_int	day
PPCODE:
{
    Z_int week;

    if (DateCalc_week_of_year(&week,&year,month,day))
    {
        if (GIMME_V == G_ARRAY)
        {
            EXTEND(sp,2);
            PUSHs(sv_2mortal(newSViv((IV)week)));
            PUSHs(sv_2mortal(newSViv((IV)year)));
        }
        else
        {
            EXTEND(sp,1);
            PUSHs(sv_2mortal(newSViv((IV)week)));
        }
    }
    else DATECALC_DATE_ERROR;
}


void
DateCalc_Monday_of_Week(week,year)
    Z_int	week
    Z_int	year
PPCODE:
{
    Z_int month;
    Z_int day;

    if (year > 0)
    {
        if ((week > 0) and (week <= DateCalc_Weeks_in_Year(year)))
        {
            if (DateCalc_monday_of_week(week,&year,&month,&day))
            {
                EXTEND(sp,3);
                PUSHs(sv_2mortal(newSViv((IV)year)));
                PUSHs(sv_2mortal(newSViv((IV)month)));
                PUSHs(sv_2mortal(newSViv((IV)day)));
            }
            else DATECALC_DATE_ERROR;
        }
        else DATECALC_WEEK_ERROR;
    }
    else DATECALC_YEAR_ERROR;
}


void
DateCalc_Nth_Weekday_of_Month_Year(year,month,dow,n)
    Z_int	year
    Z_int	month
    Z_int	dow
    Z_int	n
PPCODE:
{
    Z_int day;

    if (year > 0)
    {
        if ((month >= 1) and (month <= 12))
        {
            if ((dow >= 1) and (dow <= 7))
            {
                if ((n >= 1) and (n <= 5))
                {
                    if (DateCalc_nth_weekday_of_month_year(&year,&month,&day,dow,n))
                    {
                        EXTEND(sp,3);
                        PUSHs(sv_2mortal(newSViv((IV)year)));
                        PUSHs(sv_2mortal(newSViv((IV)month)));
                        PUSHs(sv_2mortal(newSViv((IV)day)));
                    }
                    /* else return empty list */
                }
                else DATECALC_FACTOR_ERROR;
            }
            else DATECALC_DAYOFWEEK_ERROR;
        }
        else DATECALC_MONTH_ERROR;
    }
    else DATECALC_YEAR_ERROR;
}


void
DateCalc_Standard_to_Business(year,month,day)
    Z_int	year
    Z_int	month
    Z_int	day
PPCODE:
{
    Z_int week;
    Z_int dow;

    if (DateCalc_standard_to_business(&year,&week,&dow,month,day))
    {
        EXTEND(sp,3);
        PUSHs(sv_2mortal(newSViv((IV)year)));
        PUSHs(sv_2mortal(newSViv((IV)week)));
        PUSHs(sv_2mortal(newSViv((IV)dow)));
    }
    else DATECALC_DATE_ERROR;
}


void
DateCalc_Business_to_Standard(year,week,dow)
    Z_int	year
    Z_int	week
    Z_int	dow
PPCODE:
{
    Z_int month;
    Z_int day;

    if (DateCalc_business_to_standard(&year,&month,&day,week,dow))
    {
        EXTEND(sp,3);
        PUSHs(sv_2mortal(newSViv((IV)year)));
        PUSHs(sv_2mortal(newSViv((IV)month)));
        PUSHs(sv_2mortal(newSViv((IV)day)));
    }
    else DATECALC_DATE_ERROR;
}


Z_long
DateCalc_Delta_Days(year1,month1,day1, year2,month2,day2)
    Z_int	year1
    Z_int	month1
    Z_int	day1
    Z_int	year2
    Z_int	month2
    Z_int	day2
CODE:
{
    if (DateCalc_check_date(year1,month1,day1) and
        DateCalc_check_date(year2,month2,day2))
    {
        RETVAL = DateCalc_Delta_Days(year1,month1,day1, year2,month2,day2);
    }
    else DATECALC_DATE_ERROR;
}
OUTPUT:
RETVAL


void
DateCalc_Delta_DHMS(year1,month1,day1, hour1,min1,sec1, year2,month2,day2, hour2,min2,sec2)
    Z_int	year1
    Z_int	month1
    Z_int	day1
    Z_int	hour1
    Z_int	min1
    Z_int	sec1
    Z_int	year2
    Z_int	month2
    Z_int	day2
    Z_int	hour2
    Z_int	min2
    Z_int	sec2
PPCODE:
{
    Z_long Dd;
    Z_int  Dh;
    Z_int  Dm;
    Z_int  Ds;

    if (DateCalc_check_date(year1,month1,day1) and
        DateCalc_check_date(year2,month2,day2))
    {
        if (DateCalc_check_time(hour1,min1,sec1) and
            DateCalc_check_time(hour2,min2,sec2))
        {
            if (DateCalc_delta_dhms(&Dd,&Dh,&Dm,&Ds,
                                    year1,month1,day1, hour1,min1,sec1,
                                    year2,month2,day2, hour2,min2,sec2))
            {
                EXTEND(sp,4);
                PUSHs(sv_2mortal(newSViv((IV)Dd)));
                PUSHs(sv_2mortal(newSViv((IV)Dh)));
                PUSHs(sv_2mortal(newSViv((IV)Dm)));
                PUSHs(sv_2mortal(newSViv((IV)Ds)));
            }
            else DATECALC_DATE_ERROR;
        }
        else DATECALC_TIME_ERROR;
    }
    else DATECALC_DATE_ERROR;
}


void
DateCalc_Delta_YMD(year1,month1,day1, year2,month2,day2)
    Z_int	year1
    Z_int	month1
    Z_int	day1
    Z_int	year2
    Z_int	month2
    Z_int	day2
PPCODE:
{
    if (DateCalc_delta_ymd(&year1,&month1,&day1, year2,month2,day2))
    {
        EXTEND(sp,3);
        PUSHs(sv_2mortal(newSViv((IV)year1)));
        PUSHs(sv_2mortal(newSViv((IV)month1)));
        PUSHs(sv_2mortal(newSViv((IV)day1)));
    }
    else DATECALC_DATE_ERROR;
}


void
DateCalc_Delta_YMDHMS(year1,month1,day1, hour1,min1,sec1, year2,month2,day2, hour2,min2,sec2)
    Z_int	year1
    Z_int	month1
    Z_int	day1
    Z_int	hour1
    Z_int	min1
    Z_int	sec1
    Z_int	year2
    Z_int	month2
    Z_int	day2
    Z_int	hour2
    Z_int	min2
    Z_int	sec2
PPCODE:
{
    Z_int  D_y;
    Z_int  D_m;
    Z_int  D_d;
    Z_int  Dh;
    Z_int  Dm;
    Z_int  Ds;

    if (DateCalc_check_date(year1,month1,day1) and
        DateCalc_check_date(year2,month2,day2))
    {
        if (DateCalc_check_time(hour1,min1,sec1) and
            DateCalc_check_time(hour2,min2,sec2))
        {
            if (DateCalc_delta_ymdhms(&D_y,&D_m,&D_d,    &Dh,&Dm,&Ds,
                                      year1,month1,day1, hour1,min1,sec1,
                                      year2,month2,day2, hour2,min2,sec2))
            {
                EXTEND(sp,6);
                PUSHs(sv_2mortal(newSViv((IV)D_y)));
                PUSHs(sv_2mortal(newSViv((IV)D_m)));
                PUSHs(sv_2mortal(newSViv((IV)D_d)));
                PUSHs(sv_2mortal(newSViv((IV)Dh)));
                PUSHs(sv_2mortal(newSViv((IV)Dm)));
                PUSHs(sv_2mortal(newSViv((IV)Ds)));
            }
            else DATECALC_DATE_ERROR;
        }
        else DATECALC_TIME_ERROR;
    }
    else DATECALC_DATE_ERROR;
}


void
DateCalc_Normalize_DHMS(Dd,Dh,Dm,Ds)
    Z_long	Dd
    Z_long	Dh
    Z_long	Dm
    Z_long	Ds
PPCODE:
{
    DateCalc_Normalize_DHMS(&Dd,&Dh,&Dm,&Ds);
    EXTEND(sp,4);
    PUSHs(sv_2mortal(newSViv((IV)Dd)));
    PUSHs(sv_2mortal(newSViv((IV)Dh)));
    PUSHs(sv_2mortal(newSViv((IV)Dm)));
    PUSHs(sv_2mortal(newSViv((IV)Ds)));
}


void
DateCalc_Add_Delta_Days(year,month,day, Dd)
    Z_int	year
    Z_int	month
    Z_int	day
    Z_long	Dd
PPCODE:
{
    if (DateCalc_add_delta_days(&year,&month,&day, Dd))
    {
        EXTEND(sp,3);
        PUSHs(sv_2mortal(newSViv((IV)year)));
        PUSHs(sv_2mortal(newSViv((IV)month)));
        PUSHs(sv_2mortal(newSViv((IV)day)));
    }
    else DATECALC_DATE_ERROR;
}


void
DateCalc_Add_Delta_DHMS(year,month,day, hour,min,sec, Dd,Dh,Dm,Ds)
    Z_int	year
    Z_int	month
    Z_int	day
    Z_int	hour
    Z_int	min
    Z_int	sec
    Z_long	Dd
    Z_long	Dh
    Z_long	Dm
    Z_long	Ds
PPCODE:
{
    if (DateCalc_check_date(year,month,day))
    {
        if (DateCalc_check_time(hour,min,sec))
        {
            if (DateCalc_add_delta_dhms(&year,&month,&day,
                                        &hour,&min,&sec,
                                        Dd,Dh,Dm,Ds))
            {
                EXTEND(sp,6);
                PUSHs(sv_2mortal(newSViv((IV)year)));
                PUSHs(sv_2mortal(newSViv((IV)month)));
                PUSHs(sv_2mortal(newSViv((IV)day)));
                PUSHs(sv_2mortal(newSViv((IV)hour)));
                PUSHs(sv_2mortal(newSViv((IV)min)));
                PUSHs(sv_2mortal(newSViv((IV)sec)));
            }
            else DATECALC_DATE_ERROR;
        }
        else DATECALC_TIME_ERROR;
    }
    else DATECALC_DATE_ERROR;
}


void
DateCalc_Add_Delta_YM(year,month,day, Dy,Dm)
    Z_int	year
    Z_int	month
    Z_int	day
    Z_long	Dy
    Z_long	Dm
PPCODE:
{
    if (DateCalc_add_delta_ym(&year,&month,&day, Dy,Dm))
    {
        EXTEND(sp,3);
        PUSHs(sv_2mortal(newSViv((IV)year)));
        PUSHs(sv_2mortal(newSViv((IV)month)));
        PUSHs(sv_2mortal(newSViv((IV)day)));
    }
    else DATECALC_DATE_ERROR;
}


void
DateCalc_Add_Delta_YMD(year,month,day, Dy,Dm,Dd)
    Z_int	year
    Z_int	month
    Z_int	day
    Z_long	Dy
    Z_long	Dm
    Z_long	Dd
PPCODE:
{
    if (DateCalc_add_delta_ymd(&year,&month,&day, Dy,Dm,Dd))
    {
        EXTEND(sp,3);
        PUSHs(sv_2mortal(newSViv((IV)year)));
        PUSHs(sv_2mortal(newSViv((IV)month)));
        PUSHs(sv_2mortal(newSViv((IV)day)));
    }
    else DATECALC_DATE_ERROR;
}


void
DateCalc_Add_Delta_YMDHMS(year,month,day, hour,min,sec, D_y,D_m,D_d, Dh,Dm,Ds)
    Z_int	year
    Z_int	month
    Z_int	day
    Z_int	hour
    Z_int	min
    Z_int	sec
    Z_long	D_y
    Z_long	D_m
    Z_long	D_d
    Z_long	Dh
    Z_long	Dm
    Z_long	Ds
PPCODE:
{
    if (DateCalc_check_date(year,month,day))
    {
        if (DateCalc_check_time(hour,min,sec))
        {
            if (DateCalc_add_delta_ymdhms(&year,&month,&day,
                                          &hour,&min,&sec,
                                          D_y,D_m,D_d,
                                          Dh,Dm,Ds))
            {
                EXTEND(sp,6);
                PUSHs(sv_2mortal(newSViv((IV)year)));
                PUSHs(sv_2mortal(newSViv((IV)month)));
                PUSHs(sv_2mortal(newSViv((IV)day)));
                PUSHs(sv_2mortal(newSViv((IV)hour)));
                PUSHs(sv_2mortal(newSViv((IV)min)));
                PUSHs(sv_2mortal(newSViv((IV)sec)));
            }
            else DATECALC_DATE_ERROR;
        }
        else DATECALC_TIME_ERROR;
    }
    else DATECALC_DATE_ERROR;
}


void
DateCalc_System_Clock(...)
PPCODE:
{
    Z_int   year;
    Z_int   month;
    Z_int   day;
    Z_int   hour;
    Z_int   min;
    Z_int   sec;
    Z_int   doy;
    Z_int   dow;
    Z_int   dst;
    boolean gmt;

    if ((items == 0) or (items == 1))
    {
        if (items == 1) gmt = (boolean) SvIV( ST(0) );
        else            gmt = false;
        if (DateCalc_system_clock(&year,&month,&day,
                                  &hour,&min,&sec,
                                  &doy,&dow,&dst,
                                  gmt))
        {
            EXTEND(sp,9);
            PUSHs(sv_2mortal(newSViv((IV)year)));
            PUSHs(sv_2mortal(newSViv((IV)month)));
            PUSHs(sv_2mortal(newSViv((IV)day)));
            PUSHs(sv_2mortal(newSViv((IV)hour)));
            PUSHs(sv_2mortal(newSViv((IV)min)));
            PUSHs(sv_2mortal(newSViv((IV)sec)));
            PUSHs(sv_2mortal(newSViv((IV)doy)));
            PUSHs(sv_2mortal(newSViv((IV)dow)));
            PUSHs(sv_2mortal(newSViv((IV)dst)));
        }
        else DATECALC_SYSTEM_ERROR;
    }
    else croak("Usage: Date::Calc::System_Clock([gmt])");
}


void
DateCalc_Today(...)
PPCODE:
{
    Z_int   year;
    Z_int   month;
    Z_int   day;
    Z_int   hour;
    Z_int   min;
    Z_int   sec;
    Z_int   doy;
    Z_int   dow;
    Z_int   dst;
    boolean gmt;

    if ((items == 0) or (items == 1))
    {
        if (items == 1) gmt = (boolean) SvIV( ST(0) );
        else            gmt = false;
        if (DateCalc_system_clock(&year,&month,&day,
                                  &hour,&min,&sec,
                                  &doy,&dow,&dst,
                                  gmt))
        {
            EXTEND(sp,3);
            PUSHs(sv_2mortal(newSViv((IV)year)));
            PUSHs(sv_2mortal(newSViv((IV)month)));
            PUSHs(sv_2mortal(newSViv((IV)day)));
        }
        else DATECALC_SYSTEM_ERROR;
    }
    else croak("Usage: Date::Calc::Today([gmt])");
}


void
DateCalc_Now(...)
PPCODE:
{
    Z_int   year;
    Z_int   month;
    Z_int   day;
    Z_int   hour;
    Z_int   min;
    Z_int   sec;
    Z_int   doy;
    Z_int   dow;
    Z_int   dst;
    boolean gmt;

    if ((items == 0) or (items == 1))
    {
        if (items == 1) gmt = (boolean) SvIV( ST(0) );
        else            gmt = false;
        if (DateCalc_system_clock(&year,&month,&day,
                                  &hour,&min,&sec,
                                  &doy,&dow,&dst,
                                  gmt))
        {
            EXTEND(sp,3);
            PUSHs(sv_2mortal(newSViv((IV)hour)));
            PUSHs(sv_2mortal(newSViv((IV)min)));
            PUSHs(sv_2mortal(newSViv((IV)sec)));
        }
        else DATECALC_SYSTEM_ERROR;
    }
    else croak("Usage: Date::Calc::Now([gmt])");
}


void
DateCalc_Today_and_Now(...)
PPCODE:
{
    Z_int   year;
    Z_int   month;
    Z_int   day;
    Z_int   hour;
    Z_int   min;
    Z_int   sec;
    Z_int   doy;
    Z_int   dow;
    Z_int   dst;
    boolean gmt;

    if ((items == 0) or (items == 1))
    {
        if (items == 1) gmt = (boolean) SvIV( ST(0) );
        else            gmt = false;
        if (DateCalc_system_clock(&year,&month,&day,
                                  &hour,&min,&sec,
                                  &doy,&dow,&dst,
                                  gmt))
        {
            EXTEND(sp,6);
            PUSHs(sv_2mortal(newSViv((IV)year)));
            PUSHs(sv_2mortal(newSViv((IV)month)));
            PUSHs(sv_2mortal(newSViv((IV)day)));
            PUSHs(sv_2mortal(newSViv((IV)hour)));
            PUSHs(sv_2mortal(newSViv((IV)min)));
            PUSHs(sv_2mortal(newSViv((IV)sec)));
        }
        else DATECALC_SYSTEM_ERROR;
    }
    else croak("Usage: Date::Calc::Today_and_Now([gmt])");
}


void
DateCalc_This_Year(...)
PPCODE:
{
    Z_int   year;
    Z_int   month;
    Z_int   day;
    Z_int   hour;
    Z_int   min;
    Z_int   sec;
    Z_int   doy;
    Z_int   dow;
    Z_int   dst;
    boolean gmt;

    if ((items == 0) or (items == 1))
    {
        if (items == 1) gmt = (boolean) SvIV( ST(0) );
        else            gmt = false;
        if (DateCalc_system_clock(&year,&month,&day,
                                  &hour,&min,&sec,
                                  &doy,&dow,&dst,
                                  gmt))
        {
            EXTEND(sp,1);
            PUSHs(sv_2mortal(newSViv((IV)year)));
        }
        else DATECALC_SYSTEM_ERROR;
    }
    else croak("Usage: Date::Calc::This_Year([gmt])");
}


void
DateCalc_Gmtime(...)
PPCODE:
{
#ifdef MACOS_TRADITIONAL
    double  f_seconds;
#endif
    time_t  seconds;
    Z_int   year;
    Z_int   month;
    Z_int   day;
    Z_int   hour;
    Z_int   min;
    Z_int   sec;
    Z_int   doy;
    Z_int   dow;
    Z_int   dst;

    if ((items == 0) or (items == 1))
    {
#ifdef MACOS_TRADITIONAL
        if (items == 1) f_seconds = (double) SvNV( ST(0) );
        else            f_seconds = (double) time(NULL);
        if ((f_seconds < 0) or (f_seconds > 0xFFFFFFFF))
            DATECALC_TIME_RANGE_ERROR;
        seconds = (time_t) f_seconds;
#else
        if (items == 1) seconds = (time_t) SvIV( ST(0) );
        else            seconds = time(NULL);
#endif
        if (DateCalc_gmtime(&year,&month,&day,
                            &hour,&min,&sec,
                            &doy,&dow,&dst,
                            seconds))
        {
            EXTEND(sp,9);
            PUSHs(sv_2mortal(newSViv((IV)year)));
            PUSHs(sv_2mortal(newSViv((IV)month)));
            PUSHs(sv_2mortal(newSViv((IV)day)));
            PUSHs(sv_2mortal(newSViv((IV)hour)));
            PUSHs(sv_2mortal(newSViv((IV)min)));
            PUSHs(sv_2mortal(newSViv((IV)sec)));
            PUSHs(sv_2mortal(newSViv((IV)doy)));
            PUSHs(sv_2mortal(newSViv((IV)dow)));
            PUSHs(sv_2mortal(newSViv((IV)dst)));
        }
        else DATECALC_TIME_RANGE_ERROR;
    }
    else croak("Usage: Date::Calc::Gmtime([time])");
}


void
DateCalc_Localtime(...)
PPCODE:
{
#ifdef MACOS_TRADITIONAL
    double  f_seconds;
#endif
    time_t  seconds;
    Z_int   year;
    Z_int   month;
    Z_int   day;
    Z_int   hour;
    Z_int   min;
    Z_int   sec;
    Z_int   doy;
    Z_int   dow;
    Z_int   dst;

    if ((items == 0) or (items == 1))
    {
#ifdef MACOS_TRADITIONAL
        if (items == 1) f_seconds = (double) SvNV( ST(0) );
        else            f_seconds = (double) time(NULL);
        if ((f_seconds < 0) or (f_seconds > 0xFFFFFFFF))
            DATECALC_TIME_RANGE_ERROR;
        seconds = (time_t) f_seconds;
#else
        if (items == 1) seconds = (time_t) SvIV( ST(0) );
        else            seconds = time(NULL);
#endif
        if (DateCalc_localtime(&year,&month,&day,
                               &hour,&min,&sec,
                               &doy,&dow,&dst,
                               seconds))
        {
            EXTEND(sp,9);
            PUSHs(sv_2mortal(newSViv((IV)year)));
            PUSHs(sv_2mortal(newSViv((IV)month)));
            PUSHs(sv_2mortal(newSViv((IV)day)));
            PUSHs(sv_2mortal(newSViv((IV)hour)));
            PUSHs(sv_2mortal(newSViv((IV)min)));
            PUSHs(sv_2mortal(newSViv((IV)sec)));
            PUSHs(sv_2mortal(newSViv((IV)doy)));
            PUSHs(sv_2mortal(newSViv((IV)dow)));
            PUSHs(sv_2mortal(newSViv((IV)dst)));
        }
        else DATECALC_TIME_RANGE_ERROR;
    }
    else croak("Usage: Date::Calc::Localtime([time])");
}


void
DateCalc_Mktime(year,month,day, hour,min,sec)
    Z_int	year
    Z_int	month
    Z_int	day
    Z_int	hour
    Z_int	min
    Z_int	sec
PPCODE:
{
    time_t seconds;

    if (DateCalc_mktime(&seconds, year,month,day, hour,min,sec, -1,-1,-1))
    {
        EXTEND(sp,1);
#ifdef MACOS_TRADITIONAL
        PUSHs(sv_2mortal(newSVuv((UV)seconds)));
#else
        PUSHs(sv_2mortal(newSViv((IV)seconds)));
#endif
    }
    else DATECALC_DATE_RANGE_ERROR;
}


void
DateCalc_Timezone(...)
PPCODE:
{
#ifdef MACOS_TRADITIONAL
    double  f_when;
#endif
    time_t  when;
    Z_int   year;
    Z_int   month;
    Z_int   day;
    Z_int   hour;
    Z_int   min;
    Z_int   sec;
    Z_int   dst;

    if ((items == 0) or (items == 1))
    {
#ifdef MACOS_TRADITIONAL
        if (items == 1) f_when = (double) SvNV( ST(0) );
        else            f_when = (double) time(NULL);
        if ((f_when < 0) or (f_when > 0xFFFFFFFF))
            DATECALC_TIME_RANGE_ERROR;
        when = (time_t) f_when;
#else
        if (items == 1) when = (time_t) SvIV( ST(0) );
        else            when = time(NULL);
#endif
        if (DateCalc_timezone(&year,&month,&day,
                              &hour,&min,&sec,
                              &dst,when))
        {
            EXTEND(sp,7);
            PUSHs(sv_2mortal(newSViv((IV)year)));
            PUSHs(sv_2mortal(newSViv((IV)month)));
            PUSHs(sv_2mortal(newSViv((IV)day)));
            PUSHs(sv_2mortal(newSViv((IV)hour)));
            PUSHs(sv_2mortal(newSViv((IV)min)));
            PUSHs(sv_2mortal(newSViv((IV)sec)));
            PUSHs(sv_2mortal(newSViv((IV)dst)));
        }
        else DATECALC_TIME_RANGE_ERROR;
    }
    else croak("Usage: Date::Calc::Timezone([time])");
}


void
DateCalc_Date_to_Time(year,month,day, hour,min,sec)
    Z_int	year
    Z_int	month
    Z_int	day
    Z_int	hour
    Z_int	min
    Z_int	sec
PPCODE:
{
    time_t seconds;

    if (DateCalc_date2time(&seconds, year,month,day, hour,min,sec))
    {
        EXTEND(sp,1);
#ifdef MACOS_TRADITIONAL
        PUSHs(sv_2mortal(newSVuv((UV)seconds)));
#else
        PUSHs(sv_2mortal(newSViv((IV)seconds)));
#endif
    }
    else DATECALC_DATE_RANGE_ERROR;
}


void
DateCalc_Time_to_Date(...)
PPCODE:
{
#ifdef MACOS_TRADITIONAL
    double  f_seconds;
#endif
    time_t  seconds;
    Z_int   year;
    Z_int   month;
    Z_int   day;
    Z_int   hour;
    Z_int   min;
    Z_int   sec;

    if ((items == 0) or (items == 1))
    {
#ifdef MACOS_TRADITIONAL
        if (items == 1) f_seconds = (double) SvNV( ST(0) );
        else            f_seconds = (double) time(NULL);
        if ((f_seconds < 0) or (f_seconds > 0xFFFFFFFF))
            DATECALC_TIME_RANGE_ERROR;
        seconds = (time_t) f_seconds;
#else
        if (items == 1) seconds = (time_t) SvIV( ST(0) );
        else            seconds = time(NULL);
#endif
        if (DateCalc_time2date(&year,&month,&day, &hour,&min,&sec, seconds))
        {
            EXTEND(sp,6);
            PUSHs(sv_2mortal(newSViv((IV)year)));
            PUSHs(sv_2mortal(newSViv((IV)month)));
            PUSHs(sv_2mortal(newSViv((IV)day)));
            PUSHs(sv_2mortal(newSViv((IV)hour)));
            PUSHs(sv_2mortal(newSViv((IV)min)));
            PUSHs(sv_2mortal(newSViv((IV)sec)));
        }
        else DATECALC_TIME_RANGE_ERROR;
    }
    else croak("Usage: Date::Calc::Time_to_Date([time])");
}


void
DateCalc_Easter_Sunday(year)
    Z_int	year
PPCODE:
{
    Z_int month;
    Z_int day;

    if ((year > 0) and DateCalc_easter_sunday(&year,&month,&day))
    {
        EXTEND(sp,3);
        PUSHs(sv_2mortal(newSViv((IV)year)));
        PUSHs(sv_2mortal(newSViv((IV)month)));
        PUSHs(sv_2mortal(newSViv((IV)day)));
    }
    else DATECALC_YEAR_ERROR;
}


Z_int
DateCalc_Decode_Month(string)
    charptr	string
CODE:
{
    RETVAL = DateCalc_Decode_Month(string,strlen((char *)string));
}
OUTPUT:
RETVAL


Z_int
DateCalc_Decode_Day_of_Week(string)
    charptr	string
CODE:
{
    RETVAL = DateCalc_Decode_Day_of_Week(string,strlen((char *)string));
}
OUTPUT:
RETVAL


Z_int
DateCalc_Decode_Language(string)
    charptr	string
CODE:
{
    RETVAL = DateCalc_Decode_Language(string,strlen((char *)string));
}
OUTPUT:
RETVAL


void
DateCalc_Decode_Date_EU(string)
    charptr	string
PPCODE:
{
    Z_int year;
    Z_int month;
    Z_int day;

    if (DateCalc_decode_date_eu(string,&year,&month,&day))
    {
        EXTEND(sp,3);
        PUSHs(sv_2mortal(newSViv((IV)year)));
        PUSHs(sv_2mortal(newSViv((IV)month)));
        PUSHs(sv_2mortal(newSViv((IV)day)));
    }
    /* else return empty list */
}


void
DateCalc_Decode_Date_US(string)
    charptr	string
PPCODE:
{
    Z_int year;
    Z_int month;
    Z_int day;

    if (DateCalc_decode_date_us(string,&year,&month,&day))
    {
        EXTEND(sp,3);
        PUSHs(sv_2mortal(newSViv((IV)year)));
        PUSHs(sv_2mortal(newSViv((IV)month)));
        PUSHs(sv_2mortal(newSViv((IV)day)));
    }
    /* else return empty list */
}


Z_int
DateCalc_Fixed_Window(year)
    Z_int	year


Z_int
DateCalc_Moving_Window(year)
    Z_int	year


Z_int
DateCalc_Compress(year,month,day)
    Z_int	year
    Z_int	month
    Z_int	day


void
DateCalc_Uncompress(date)
    Z_int	date
PPCODE:
{
    Z_int century;
    Z_int year;
    Z_int month;
    Z_int day;

    if (DateCalc_uncompress(date,&century,&year,&month,&day))
    {
        EXTEND(sp,4);
        PUSHs(sv_2mortal(newSViv((IV)century)));
        PUSHs(sv_2mortal(newSViv((IV)year)));
        PUSHs(sv_2mortal(newSViv((IV)month)));
        PUSHs(sv_2mortal(newSViv((IV)day)));
    }
    /* else return empty list */
    /* else DATECALC_DATE_ERROR; */
}


boolean
DateCalc_check_compressed(date)
    Z_int	date


void
DateCalc_Compressed_to_Text(date)
    Z_int	date
PPCODE:
{
    charptr string;

    string = DateCalc_Compressed_to_Text(date);
    if (string != NULL)
    {
        EXTEND(sp,1);
        PUSHs(sv_2mortal(newSVpv((char *)string,0)));
        DateCalc_Dispose(string);
    }
    else DATECALC_MEMORY_ERROR;
}


void
DateCalc_Date_to_Text(year,month,day)
    Z_int	year
    Z_int	month
    Z_int	day
PPCODE:
{
    charptr string;

    if (DateCalc_check_date(year,month,day))
    {
        string = DateCalc_Date_to_Text(year,month,day);
        if (string != NULL)
        {
            EXTEND(sp,1);
            PUSHs(sv_2mortal(newSVpv((char *)string,0)));
            DateCalc_Dispose(string);
        }
        else DATECALC_MEMORY_ERROR;
    }
    else DATECALC_DATE_ERROR;
}


void
DateCalc_Date_to_Text_Long(year,month,day)
    Z_int	year
    Z_int	month
    Z_int	day
PPCODE:
{
    charptr string;

    if (DateCalc_check_date(year,month,day))
    {
        string = DateCalc_Date_to_Text_Long(year,month,day);
        if (string != NULL)
        {
            EXTEND(sp,1);
            PUSHs(sv_2mortal(newSVpv((char *)string,0)));
            DateCalc_Dispose(string);
        }
        else DATECALC_MEMORY_ERROR;
    }
    else DATECALC_DATE_ERROR;
}


void
DateCalc_English_Ordinal(number)
    Z_int	number
PPCODE:
{
    blockdef(string,64);

    DateCalc_English_Ordinal(string,number);
    EXTEND(sp,1);
    PUSHs(sv_2mortal(newSVpv((char *)string,0)));
}


void
DateCalc_Calendar(...)
PPCODE:
{
    Z_int   year;
    Z_int   month;
    boolean orthodox;
    charptr string;

    if ((items >= 2) and (items <= 3))
    {
        year  = (Z_int) SvIV( ST(0) );
        month = (Z_int) SvIV( ST(1) );
        if (items == 3) orthodox = (boolean) SvIV( ST(2) );
        else            orthodox = false;
        if (year > 0)
        {
            if ((month >= 1) and (month <= 12))
            {
                string = DateCalc_Calendar(year,month,orthodox);
                if (string != NULL)
                {
                    EXTEND(sp,1);
                    PUSHs(sv_2mortal(newSVpv((char *)string,0)));
                    DateCalc_Dispose(string);
                }
                else DATECALC_MEMORY_ERROR;
            }
            else DATECALC_MONTH_ERROR;
        }
        else DATECALC_YEAR_ERROR;
    }
    else croak("Usage: Date::Calc::Calendar(year,month[,orthodox])");
}


void
DateCalc_Month_to_Text(month)
    Z_int	month
PPCODE:
{
    if ((month >= 1) and (month <= 12))
    {
        EXTEND(sp,1);
        PUSHs(sv_2mortal(newSVpv((char *)DateCalc_Month_to_Text_[DateCalc_Language][month],0)));
    }
    else DATECALC_MONTH_ERROR;
}


void
DateCalc_Day_of_Week_to_Text(dow)
    Z_int	dow
PPCODE:
{
    if ((dow >= 1) and (dow <= 7))
    {
        EXTEND(sp,1);
        PUSHs(sv_2mortal(newSVpv((char *)DateCalc_Day_of_Week_to_Text_[DateCalc_Language][dow],0)));
    }
    else DATECALC_DAYOFWEEK_ERROR;
}


void
DateCalc_Day_of_Week_Abbreviation(dow)
    Z_int	dow
PPCODE:
{
    blockdef(buffer,4);

    if ((dow >= 1) and (dow <= 7))
    {
        EXTEND(sp,1);
        if (DateCalc_Day_of_Week_Abbreviation_[DateCalc_Language][0][0] != '\0')
        {
            PUSHs(sv_2mortal(newSVpv((char *)DateCalc_Day_of_Week_Abbreviation_[DateCalc_Language][dow],0)));
        }
        else
        {
            strncpy((char *)buffer,(char *)DateCalc_Day_of_Week_to_Text_[DateCalc_Language][dow],3);
            buffer[3] = '\0';
            PUSHs(sv_2mortal(newSVpv((char *)buffer,0)));
        }
    }
    else DATECALC_DAYOFWEEK_ERROR;
}


void
DateCalc_Language_to_Text(lang)
    Z_int	lang
PPCODE:
{
    if ((lang >= 1) and (lang <= DateCalc_LANGUAGES))
    {
        EXTEND(sp,1);
        PUSHs(sv_2mortal(newSVpv((char *)DateCalc_Language_to_Text_[lang],0)));
    }
    else DATECALC_LANGUAGE_ERROR;
}


Z_int
DateCalc_Language(...)
CODE:
{
    Z_int lang;

    if ((items >= 0) and (items <= 1))
    {
        RETVAL = DateCalc_Language;
        if (items == 1)
        {
            lang = (Z_int) SvIV( ST(0) );
            if ((lang >= 1) and (lang <= DateCalc_LANGUAGES))
            {
                DateCalc_Language = lang;
            }
            else DATECALC_LANGUAGE_ERROR;
        }
    }
    else croak("Usage: Date::Calc::Language([lang])");
}
OUTPUT:
RETVAL


Z_int
DateCalc_Languages()
CODE:
{
    RETVAL = DateCalc_LANGUAGES;
}
OUTPUT:
RETVAL


void
DateCalc_ISO_LC(scalar)
    SV *	scalar
PPCODE:
{
    charptr string;
    charptr buffer;
    N_int length;
    N_int index;

    if ( DATECALC_STRING(scalar,string,length) )
    {
        buffer = (charptr) malloc(length+1);
        if (buffer != NULL)
        {
            for ( index = 0; index < length; index++ )
                buffer[index] = DateCalc_ISO_LC(string[index]);
            buffer[length] = '\0';
            EXTEND(sp,1);
            PUSHs(sv_2mortal(newSVpv((char *)buffer,length)));
            free(buffer);
        }
        else DATECALC_MEMORY_ERROR;
    }
    else DATECALC_STRING_ERROR;
}


void
DateCalc_ISO_UC(scalar)
    SV *	scalar
PPCODE:
{
    charptr string;
    charptr buffer;
    N_int length;
    N_int index;

    if ( DATECALC_STRING(scalar,string,length) )
    {
        buffer = (charptr) malloc(length+1);
        if (buffer != NULL)
        {
            for ( index = 0; index < length; index++ )
                buffer[index] = DateCalc_ISO_UC(string[index]);
            buffer[length] = '\0';
            EXTEND(sp,1);
            PUSHs(sv_2mortal(newSVpv((char *)buffer,length)));
            free(buffer);
        }
        else DATECALC_MEMORY_ERROR;
    }
    else DATECALC_STRING_ERROR;
}


void
DateCalc_Version()
PPCODE:
{
    charptr string;

    string = DateCalc_Version();
    if (string != NULL)
    {
        EXTEND(sp,1);
        PUSHs(sv_2mortal(newSVpv((char *)string,0)));
    }
    else DATECALC_MEMORY_ERROR;
}


