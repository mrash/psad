

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


#include "BitVector.h"


static    char *BitVector_Class = "Bit::Vector";
static      HV *BitVector_Stash;

typedef     SV *BitVector_Object;
typedef     SV *BitVector_Handle;
typedef N_word *BitVector_Address;
typedef     SV *BitVector_Scalar;


const char *BitVector_OBJECT_ERROR = "item is not a \"Bit::Vector\" object";
const char *BitVector_SCALAR_ERROR = "item is not a scalar";
const char *BitVector_STRING_ERROR = "item is not a string";
const char *BitVector_MIN_ERROR    = "minimum index out of range";
const char *BitVector_MAX_ERROR    = "maximum index out of range";
const char *BitVector_START_ERROR  = "start index out of range";
const char *BitVector_OFFSET_ERROR = "offset out of range";
const char *BitVector_CHUNK_ERROR  = "chunk size out of range";
const char *BitVector_SET_ERROR    = "set size mismatch";
const char *BitVector_MATRIX_ERROR = "matrix size mismatch";
const char *BitVector_SHAPE_ERROR  = "not a square matrix";
const char *BitVector_MEMORY_ERROR = ERRCODE_NULL;
const char *BitVector_INDEX_ERROR  = ERRCODE_INDX;
const char *BitVector_ORDER_ERROR  = ERRCODE_ORDR;
const char *BitVector_SIZE_ERROR   = ERRCODE_SIZE;


#define BIT_VECTOR_OBJECT(ref,hdl,adr) \
    ( ref && \
    SvROK(ref) && \
    (hdl = (BitVector_Handle)SvRV(ref)) && \
    SvOBJECT(hdl) && \
    SvREADONLY(hdl) && \
    (SvTYPE(hdl) == SVt_PVMG) && \
    (SvSTASH(hdl) == BitVector_Stash) && \
    (adr = (BitVector_Address)SvIV(hdl)) )

#define BIT_VECTOR_SCALAR(ref,typ,var) \
    ( ref && !(SvROK(ref)) && ((var = (typ)SvIV(ref)) | 1) )

#define BIT_VECTOR_STRING(ref,var) \
    ( ref && !(SvROK(ref)) && (var = (charptr)SvPV(ref,PL_na)) )

#define BIT_VECTOR_BUFFER(ref,var,len) \
    ( ref && !(SvROK(ref)) && SvPOK(ref) && \
    (var = (charptr)SvPV(ref,PL_na)) && \
    ((len = (N_int)SvCUR(ref)) | 1) )


#define BIT_VECTOR_ERROR(message) \
    croak("Bit::Vector::%s(): %s", GvNAME(CvGV(cv)), message)


#define BIT_VECTOR_OBJECT_ERROR \
    BIT_VECTOR_ERROR( BitVector_OBJECT_ERROR )

#define BIT_VECTOR_SCALAR_ERROR \
    BIT_VECTOR_ERROR( BitVector_SCALAR_ERROR )

#define BIT_VECTOR_STRING_ERROR \
    BIT_VECTOR_ERROR( BitVector_STRING_ERROR )

#define BIT_VECTOR_MIN_ERROR \
    BIT_VECTOR_ERROR( BitVector_MIN_ERROR )

#define BIT_VECTOR_MAX_ERROR \
    BIT_VECTOR_ERROR( BitVector_MAX_ERROR )

#define BIT_VECTOR_START_ERROR \
    BIT_VECTOR_ERROR( BitVector_START_ERROR )

#define BIT_VECTOR_OFFSET_ERROR \
    BIT_VECTOR_ERROR( BitVector_OFFSET_ERROR )

#define BIT_VECTOR_CHUNK_ERROR \
    BIT_VECTOR_ERROR( BitVector_CHUNK_ERROR )

#define BIT_VECTOR_SET_ERROR \
    BIT_VECTOR_ERROR( BitVector_SET_ERROR )

#define BIT_VECTOR_MATRIX_ERROR \
    BIT_VECTOR_ERROR( BitVector_MATRIX_ERROR )

#define BIT_VECTOR_SHAPE_ERROR \
    BIT_VECTOR_ERROR( BitVector_SHAPE_ERROR )

#define BIT_VECTOR_MEMORY_ERROR \
    BIT_VECTOR_ERROR( BitVector_MEMORY_ERROR )

#define BIT_VECTOR_INDEX_ERROR \
    BIT_VECTOR_ERROR( BitVector_INDEX_ERROR )

#define BIT_VECTOR_ORDER_ERROR \
    BIT_VECTOR_ERROR( BitVector_ORDER_ERROR )

#define BIT_VECTOR_SIZE_ERROR \
    BIT_VECTOR_ERROR( BitVector_SIZE_ERROR )


#define BIT_VECTOR_EXCEPTION(code) \
    BIT_VECTOR_ERROR( BitVector_Error(code) )


MODULE = Bit::Vector		PACKAGE = Bit::Vector		PREFIX = BitVector_


PROTOTYPES: DISABLE


BOOT:
{
    ErrCode rc;

    if ((rc = BitVector_Boot()))
    {
        BIT_VECTOR_EXCEPTION(rc);
        exit((int)rc);
    }
    BitVector_Stash = gv_stashpv(BitVector_Class,1);
}


void
BitVector_Version(...)
PPCODE:
{
    charptr string;

    if ((items >= 0) and (items <= 1))
    {
        string = BitVector_Version();
        if (string != NULL)
        {
            EXTEND(sp,1);
            PUSHs(sv_2mortal(newSVpv((char *)string,0)));
        }
        else BIT_VECTOR_MEMORY_ERROR;
    }
    else croak("Usage: Bit::Vector->Version()");
}


N_int
BitVector_Word_Bits(...)
CODE:
{
    if ((items >= 0) and (items <= 1))
    {
        RETVAL = BitVector_Word_Bits();
    }
    else croak("Usage: Bit::Vector->Word_Bits()");
}
OUTPUT:
RETVAL


N_int
BitVector_Long_Bits(...)
CODE:
{
    if ((items >= 0) and (items <= 1))
    {
        RETVAL = BitVector_Long_Bits();
    }
    else croak("Usage: Bit::Vector->Long_Bits()");
}
OUTPUT:
RETVAL


void
BitVector_Create(...)
ALIAS:
  new = 1
PPCODE:
{
    BitVector_Scalar  arg1;
    BitVector_Scalar  arg2;
    BitVector_Address address;
    BitVector_Handle  handle;
    BitVector_Object  reference;
    listptr list;
    listptr slot;
    N_int bits;
    N_int count;

    if ((items >= 2) and (items <= 3))
    {
        arg1 = ST(1);
        if ( BIT_VECTOR_SCALAR(arg1,N_int,bits) )
        {
            if (items > 2)
            {
                arg2 = ST(2);
                if ( BIT_VECTOR_SCALAR(arg2,N_int,count) )
                {
                    if (count > 0)
                    {
                        if ((list = BitVector_Create_List(bits,true,count)) != NULL)
                        {
                            EXTEND(sp,(int)count);
                            slot = list;
                            while (count-- > 0)
                            {
                                address = *slot++;
                                handle = newSViv((IV)address);
                                reference = sv_bless(sv_2mortal(newRV(handle)),
                                    BitVector_Stash);
                                SvREFCNT_dec(handle);
                                SvREADONLY_on(handle);
                                PUSHs(reference);
                            }
                            BitVector_Destroy_List(list,0);
                        }
                        else BIT_VECTOR_MEMORY_ERROR;
                    }
                }
                else BIT_VECTOR_SCALAR_ERROR;
            }
            else
            {
                if ((address = BitVector_Create(bits,true)) != NULL)
                {
                    handle = newSViv((IV)address);
                    reference = sv_bless(sv_2mortal(newRV(handle)),
                        BitVector_Stash);
                    SvREFCNT_dec(handle);
                    SvREADONLY_on(handle);
                    PUSHs(reference);
                }
                else BIT_VECTOR_MEMORY_ERROR;
            }
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else croak("Usage: %s(class,bits[,count])", GvNAME(CvGV(cv)));
}


void
BitVector_new_Hex(class,bits,string)
BitVector_Object	class
BitVector_Scalar	bits
BitVector_Scalar	string
PPCODE:
{
    BitVector_Address address;
    BitVector_Handle  handle;
    BitVector_Object  reference;
    N_int   size;
    charptr pointer;
    ErrCode code;

    if ( BIT_VECTOR_SCALAR(bits,N_int,size) )
    {
        if ( BIT_VECTOR_STRING(string,pointer) )
        {
            if ((address = BitVector_Create(size,false)) != NULL)
            {
                if ((code = BitVector_from_Hex(address,pointer)))
                {
                    BitVector_Destroy(address);
                    BIT_VECTOR_EXCEPTION(code);
                }
                else
                {
                    handle = newSViv((IV)address);
                    reference = sv_bless(sv_2mortal(newRV(handle)),
                        BitVector_Stash);
                    SvREFCNT_dec(handle);
                    SvREADONLY_on(handle);
                    PUSHs(reference);
                }
            }
            else BIT_VECTOR_MEMORY_ERROR;
        }
        else BIT_VECTOR_STRING_ERROR;
    }
    else BIT_VECTOR_SCALAR_ERROR;
}


void
BitVector_new_Bin(class,bits,string)
BitVector_Object	class
BitVector_Scalar	bits
BitVector_Scalar	string
PPCODE:
{
    BitVector_Address address;
    BitVector_Handle  handle;
    BitVector_Object  reference;
    N_int   size;
    charptr pointer;
    ErrCode code;

    if ( BIT_VECTOR_SCALAR(bits,N_int,size) )
    {
        if ( BIT_VECTOR_STRING(string,pointer) )
        {
            if ((address = BitVector_Create(size,false)) != NULL)
            {
                if ((code = BitVector_from_Bin(address,pointer)))
                {
                    BitVector_Destroy(address);
                    BIT_VECTOR_EXCEPTION(code);
                }
                else
                {
                    handle = newSViv((IV)address);
                    reference = sv_bless(sv_2mortal(newRV(handle)),
                        BitVector_Stash);
                    SvREFCNT_dec(handle);
                    SvREADONLY_on(handle);
                    PUSHs(reference);
                }
            }
            else BIT_VECTOR_MEMORY_ERROR;
        }
        else BIT_VECTOR_STRING_ERROR;
    }
    else BIT_VECTOR_SCALAR_ERROR;
}


void
BitVector_new_Dec(class,bits,string)
BitVector_Object	class
BitVector_Scalar	bits
BitVector_Scalar	string
PPCODE:
{
    BitVector_Address address;
    BitVector_Handle  handle;
    BitVector_Object  reference;
    N_int   size;
    charptr pointer;
    ErrCode code;

    if ( BIT_VECTOR_SCALAR(bits,N_int,size) )
    {
        if ( BIT_VECTOR_STRING(string,pointer) )
        {
            if ((address = BitVector_Create(size,false)) != NULL)
            {
                if ((code = BitVector_from_Dec(address,pointer)))
                {
                    BitVector_Destroy(address);
                    BIT_VECTOR_EXCEPTION(code);
                }
                else
                {
                    handle = newSViv((IV)address);
                    reference = sv_bless(sv_2mortal(newRV(handle)),
                        BitVector_Stash);
                    SvREFCNT_dec(handle);
                    SvREADONLY_on(handle);
                    PUSHs(reference);
                }
            }
            else BIT_VECTOR_MEMORY_ERROR;
        }
        else BIT_VECTOR_STRING_ERROR;
    }
    else BIT_VECTOR_SCALAR_ERROR;
}


void
BitVector_new_Enum(class,bits,string)
BitVector_Object	class
BitVector_Scalar	bits
BitVector_Scalar	string
PPCODE:
{
    BitVector_Address address;
    BitVector_Handle  handle;
    BitVector_Object  reference;
    N_int   size;
    charptr pointer;
    ErrCode code;

    if ( BIT_VECTOR_SCALAR(bits,N_int,size) )
    {
        if ( BIT_VECTOR_STRING(string,pointer) )
        {
            if ((address = BitVector_Create(size,false)) != NULL)
            {
                if ((code = BitVector_from_Enum(address,pointer)))
                {
                    BitVector_Destroy(address);
                    BIT_VECTOR_EXCEPTION(code);
                }
                else
                {
                    handle = newSViv((IV)address);
                    reference = sv_bless(sv_2mortal(newRV(handle)),
                        BitVector_Stash);
                    SvREFCNT_dec(handle);
                    SvREADONLY_on(handle);
                    PUSHs(reference);
                }
            }
            else BIT_VECTOR_MEMORY_ERROR;
        }
        else BIT_VECTOR_STRING_ERROR;
    }
    else BIT_VECTOR_SCALAR_ERROR;
}


void
BitVector_Shadow(reference)
BitVector_Object        reference
PPCODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ((address = BitVector_Shadow(address)) != NULL)
        {
            handle = newSViv((IV)address);
            reference = sv_bless(sv_2mortal(newRV(handle)),
                BitVector_Stash);
            SvREFCNT_dec(handle);
            SvREADONLY_on(handle);
            PUSHs(reference);
        }
        else BIT_VECTOR_MEMORY_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_Clone(reference)
BitVector_Object        reference
PPCODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ((address = BitVector_Clone(address)) != NULL)
        {
            handle = newSViv((IV)address);
            reference = sv_bless(sv_2mortal(newRV(handle)),
                BitVector_Stash);
            SvREFCNT_dec(handle);
            SvREADONLY_on(handle);
            PUSHs(reference);
        }
        else BIT_VECTOR_MEMORY_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_Concat(Xref,Yref)
BitVector_Object        Xref
BitVector_Object        Yref
PPCODE:
{
    BitVector_Handle  Xhdl;
    BitVector_Address Xadr;
    BitVector_Handle  Yhdl;
    BitVector_Address Yadr;
    BitVector_Object  reference;
    BitVector_Handle  handle;
    BitVector_Address address;

    if ( BIT_VECTOR_OBJECT(Xref,Xhdl,Xadr) &&
         BIT_VECTOR_OBJECT(Yref,Yhdl,Yadr) )
    {
        if ((address = BitVector_Concat(Xadr,Yadr)) != NULL)
        {
            handle = newSViv((IV)address);
            reference = sv_bless(sv_2mortal(newRV(handle)),
                BitVector_Stash);
            SvREFCNT_dec(handle);
            SvREADONLY_on(handle);
            PUSHs(reference);
        }
        else BIT_VECTOR_MEMORY_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_Concat_List(...)
PPCODE:
{
    BitVector_Object  Xref;
    BitVector_Handle  Xhdl;
    BitVector_Address Xadr;
    BitVector_Object  reference;
    BitVector_Handle  handle;
    BitVector_Address address;
    N_int offset;
    N_int bits;
    I32 index;

    bits = 0;
    index = items;
    while (index-- > 0)
    {
        Xref = ST(index);
        if ( BIT_VECTOR_OBJECT(Xref,Xhdl,Xadr) )
        {
            bits += bits_(Xadr);
        }
        else if ((index != 0) or SvROK(Xref))
          BIT_VECTOR_OBJECT_ERROR;
    }
    if ((address = BitVector_Create(bits,false)) != NULL)
    {
        offset = 0;
        index = items;
        while (index-- > 0)
        {
            Xref = ST(index);
            if ( BIT_VECTOR_OBJECT(Xref,Xhdl,Xadr) )
            {
                if ((bits = bits_(Xadr)) > 0)
                {
                    BitVector_Interval_Copy(address,Xadr,offset,0,bits);
                    offset += bits;
                }
            }
            else if ((index != 0) or SvROK(Xref)) BIT_VECTOR_OBJECT_ERROR;
        }
        handle = newSViv((IV)address);
        reference = sv_bless(sv_2mortal(newRV(handle)),
            BitVector_Stash);
        SvREFCNT_dec(handle);
        SvREADONLY_on(handle);
        PUSHs(reference);
    }
    else BIT_VECTOR_MEMORY_ERROR;
}


N_int
BitVector_Size(reference)
BitVector_Object	reference
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        RETVAL = bits_(address);
    }
    else BIT_VECTOR_OBJECT_ERROR;
}
OUTPUT:
RETVAL


void
BitVector_Resize(reference,bits)
BitVector_Object	reference
BitVector_Scalar	bits
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    N_int size;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_SCALAR(bits,N_int,size) )
        {
            address = BitVector_Resize(address,size);
            SvREADONLY_off(handle);
            sv_setiv(handle,(IV)address);
            SvREADONLY_on(handle);
            if (address == NULL) BIT_VECTOR_MEMORY_ERROR;
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_DESTROY(reference)
BitVector_Object	reference
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        BitVector_Destroy(address);
        SvREADONLY_off(handle);
        sv_setiv(handle,(IV)NULL);
        SvREADONLY_on(handle);
    }
    /* else BIT_VECTOR_OBJECT_ERROR; */
}


void
BitVector_Copy(Xref,Yref)
BitVector_Object        Xref
BitVector_Object        Yref
CODE:
{
    BitVector_Handle  Xhdl;
    BitVector_Address Xadr;
    BitVector_Handle  Yhdl;
    BitVector_Address Yadr;

    if ( BIT_VECTOR_OBJECT(Xref,Xhdl,Xadr) &&
         BIT_VECTOR_OBJECT(Yref,Yhdl,Yadr) )
    {
        BitVector_Copy(Xadr,Yadr);
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_Empty(reference)
BitVector_Object	reference
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        BitVector_Empty(address);
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_Fill(reference)
BitVector_Object	reference
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        BitVector_Fill(address);
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_Flip(reference)
BitVector_Object	reference
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        BitVector_Flip(address);
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_Primes(reference)
BitVector_Object	reference
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        BitVector_Primes(address);
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_Reverse(Xref,Yref)
BitVector_Object	Xref
BitVector_Object	Yref
CODE:
{
    BitVector_Handle  Xhdl;
    BitVector_Address Xadr;
    BitVector_Handle  Yhdl;
    BitVector_Address Yadr;

    if ( BIT_VECTOR_OBJECT(Xref,Xhdl,Xadr) &&
         BIT_VECTOR_OBJECT(Yref,Yhdl,Yadr) )
    {
        if (bits_(Xadr) == bits_(Yadr))
        {
            BitVector_Reverse(Xadr,Yadr);
        }
        else BIT_VECTOR_SIZE_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_Interval_Empty(reference,min,max)
BitVector_Object	reference
BitVector_Scalar	min
BitVector_Scalar	max
ALIAS:
  Empty_Interval = 2
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    N_int lower;
    N_int upper;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_SCALAR(min,N_int,lower) &&
             BIT_VECTOR_SCALAR(max,N_int,upper) )
        {
            if      (lower >= bits_(address)) BIT_VECTOR_MIN_ERROR;
            else if (upper >= bits_(address)) BIT_VECTOR_MAX_ERROR;
            else if (lower > upper)           BIT_VECTOR_ORDER_ERROR;
            else                       BitVector_Interval_Empty(address,lower,upper);
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_Interval_Fill(reference,min,max)
BitVector_Object	reference
BitVector_Scalar	min
BitVector_Scalar	max
ALIAS:
  Fill_Interval = 2
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    N_int lower;
    N_int upper;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_SCALAR(min,N_int,lower) &&
             BIT_VECTOR_SCALAR(max,N_int,upper) )
        {
            if      (lower >= bits_(address)) BIT_VECTOR_MIN_ERROR;
            else if (upper >= bits_(address)) BIT_VECTOR_MAX_ERROR;
            else if (lower > upper)           BIT_VECTOR_ORDER_ERROR;
            else                       BitVector_Interval_Fill(address,lower,upper);
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_Interval_Flip(reference,min,max)
BitVector_Object	reference
BitVector_Scalar	min
BitVector_Scalar	max
ALIAS:
  Flip_Interval = 2
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    N_int lower;
    N_int upper;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_SCALAR(min,N_int,lower) &&
             BIT_VECTOR_SCALAR(max,N_int,upper) )
        {
            if      (lower >= bits_(address)) BIT_VECTOR_MIN_ERROR;
            else if (upper >= bits_(address)) BIT_VECTOR_MAX_ERROR;
            else if (lower > upper)           BIT_VECTOR_ORDER_ERROR;
            else                       BitVector_Interval_Flip(address,lower,upper);
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_Interval_Reverse(reference,min,max)
BitVector_Object	reference
BitVector_Scalar	min
BitVector_Scalar	max
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    N_int lower;
    N_int upper;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_SCALAR(min,N_int,lower) &&
             BIT_VECTOR_SCALAR(max,N_int,upper) )
        {
            if      (lower >= bits_(address)) BIT_VECTOR_MIN_ERROR;
            else if (upper >= bits_(address)) BIT_VECTOR_MAX_ERROR;
            else if (lower > upper)           BIT_VECTOR_ORDER_ERROR;
            else                       BitVector_Interval_Reverse(address,lower,upper);
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_Interval_Scan_inc(reference,start)
BitVector_Object	reference
BitVector_Scalar	start
PPCODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    N_int first;
    N_int min;
    N_int max;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_SCALAR(start,N_int,first) )
        {
            if (first < bits_(address))
            {
                if ( BitVector_interval_scan_inc(address,first,&min,&max) )
                {
                    EXTEND(sp,2);
                    PUSHs(sv_2mortal(newSViv((IV)min)));
                    PUSHs(sv_2mortal(newSViv((IV)max)));
                }
                /* else return empty list */
            }
            else BIT_VECTOR_START_ERROR;
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_Interval_Scan_dec(reference,start)
BitVector_Object	reference
BitVector_Scalar	start
PPCODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    N_int first;
    N_int min;
    N_int max;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_SCALAR(start,N_int,first) )
        {
            if (first < bits_(address))
            {
                if ( BitVector_interval_scan_dec(address,first,&min,&max) )
                {
                    EXTEND(sp,2);
                    PUSHs(sv_2mortal(newSViv((IV)min)));
                    PUSHs(sv_2mortal(newSViv((IV)max)));
                }
                /* else return empty list */
            }
            else BIT_VECTOR_START_ERROR;
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_Interval_Copy(Xref,Yref,Xoffset,Yoffset,length)
BitVector_Object	Xref
BitVector_Object	Yref
BitVector_Scalar	Xoffset
BitVector_Scalar	Yoffset
BitVector_Scalar	length
CODE:
{
    BitVector_Handle  Xhdl;
    BitVector_Address Xadr;
    BitVector_Handle  Yhdl;
    BitVector_Address Yadr;
    N_int Xoff;
    N_int Yoff;
    N_int len;

    if ( BIT_VECTOR_OBJECT(Xref,Xhdl,Xadr) &&
         BIT_VECTOR_OBJECT(Yref,Yhdl,Yadr) )
    {
        if ( BIT_VECTOR_SCALAR(Xoffset,N_int,Xoff) &&
             BIT_VECTOR_SCALAR(Yoffset,N_int,Yoff) &&
             BIT_VECTOR_SCALAR(length, N_int,len) )
        {
            if ((Xoff < bits_(Xadr)) and (Yoff < bits_(Yadr)))
            {
                if (len > 0) BitVector_Interval_Copy(Xadr,Yadr,Xoff,Yoff,len);
            }
            else BIT_VECTOR_OFFSET_ERROR;
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_Interval_Substitute(Xref,Yref,Xoffset,Xlength,Yoffset,Ylength)
BitVector_Object	Xref
BitVector_Object	Yref
BitVector_Scalar	Xoffset
BitVector_Scalar	Xlength
BitVector_Scalar	Yoffset
BitVector_Scalar	Ylength
CODE:
{
    BitVector_Handle  Xhdl;
    BitVector_Address Xadr;
    BitVector_Handle  Yhdl;
    BitVector_Address Yadr;
    N_int Xoff;
    N_int Xlen;
    N_int Yoff;
    N_int Ylen;

    if ( BIT_VECTOR_OBJECT(Xref,Xhdl,Xadr) &&
         BIT_VECTOR_OBJECT(Yref,Yhdl,Yadr) )
    {
        if ( BIT_VECTOR_SCALAR(Xoffset,N_int,Xoff) &&
             BIT_VECTOR_SCALAR(Xlength,N_int,Xlen) &&
             BIT_VECTOR_SCALAR(Yoffset,N_int,Yoff) &&
             BIT_VECTOR_SCALAR(Ylength,N_int,Ylen) )
        {
            if ((Xoff <= bits_(Xadr)) and (Yoff <= bits_(Yadr)))
            {
                Xadr = BitVector_Interval_Substitute(Xadr,Yadr,Xoff,Xlen,Yoff,Ylen);
                SvREADONLY_off(Xhdl);
                sv_setiv(Xhdl,(IV)Xadr);
                SvREADONLY_on(Xhdl);
                if (Xadr == NULL) BIT_VECTOR_MEMORY_ERROR;
            }
            else BIT_VECTOR_OFFSET_ERROR;
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


boolean
BitVector_is_empty(reference)
BitVector_Object	reference
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        RETVAL = BitVector_is_empty(address);
    }
    else BIT_VECTOR_OBJECT_ERROR;
}
OUTPUT:
RETVAL


boolean
BitVector_is_full(reference)
BitVector_Object	reference
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        RETVAL = BitVector_is_full(address);
    }
    else BIT_VECTOR_OBJECT_ERROR;
}
OUTPUT:
RETVAL


boolean
BitVector_equal(Xref,Yref)
BitVector_Object	Xref
BitVector_Object	Yref
CODE:
{
    BitVector_Handle  Xhdl;
    BitVector_Address Xadr;
    BitVector_Handle  Yhdl;
    BitVector_Address Yadr;

    if ( BIT_VECTOR_OBJECT(Xref,Xhdl,Xadr) &&
         BIT_VECTOR_OBJECT(Yref,Yhdl,Yadr) )
    {
        if (bits_(Xadr) == bits_(Yadr))
        {
            RETVAL = BitVector_equal(Xadr,Yadr);
        }
        else BIT_VECTOR_SIZE_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}
OUTPUT:
RETVAL


Z_int
BitVector_Lexicompare(Xref,Yref)
BitVector_Object	Xref
BitVector_Object	Yref
CODE:
{
    BitVector_Handle  Xhdl;
    BitVector_Address Xadr;
    BitVector_Handle  Yhdl;
    BitVector_Address Yadr;

    if ( BIT_VECTOR_OBJECT(Xref,Xhdl,Xadr) &&
         BIT_VECTOR_OBJECT(Yref,Yhdl,Yadr) )
    {
        if (bits_(Xadr) == bits_(Yadr))
        {
            RETVAL = BitVector_Lexicompare(Xadr,Yadr);
        }
        else BIT_VECTOR_SIZE_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}
OUTPUT:
RETVAL


Z_int
BitVector_Compare(Xref,Yref)
BitVector_Object	Xref
BitVector_Object	Yref
CODE:
{
    BitVector_Handle  Xhdl;
    BitVector_Address Xadr;
    BitVector_Handle  Yhdl;
    BitVector_Address Yadr;

    if ( BIT_VECTOR_OBJECT(Xref,Xhdl,Xadr) &&
         BIT_VECTOR_OBJECT(Yref,Yhdl,Yadr) )
    {
        if (bits_(Xadr) == bits_(Yadr))
        {
            RETVAL = BitVector_Compare(Xadr,Yadr);
        }
        else BIT_VECTOR_SIZE_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}
OUTPUT:
RETVAL


void
BitVector_to_Hex(reference)
BitVector_Object	reference
ALIAS:
  to_String = 2
PPCODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    charptr string;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        string = BitVector_to_Hex(address);
        if (string != NULL)
        {
            EXTEND(sp,1);
            PUSHs(sv_2mortal(newSVpv((char *)string,0)));
            BitVector_Dispose(string);
        }
        else BIT_VECTOR_MEMORY_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_from_Hex(reference,string)
BitVector_Object	reference
BitVector_Scalar	string
ALIAS:
  from_string = 2
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    charptr pointer;
    ErrCode code;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_STRING(string,pointer) )
        {
            if ((code = BitVector_from_Hex(address,pointer)))
                BIT_VECTOR_EXCEPTION(code);
        }
        else BIT_VECTOR_STRING_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_to_Bin(reference)
BitVector_Object	reference
PPCODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    charptr string;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        string = BitVector_to_Bin(address);
        if (string != NULL)
        {
            EXTEND(sp,1);
            PUSHs(sv_2mortal(newSVpv((char *)string,0)));
            BitVector_Dispose(string);
        }
        else BIT_VECTOR_MEMORY_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_from_Bin(reference,string)
BitVector_Object	reference
BitVector_Scalar	string
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    charptr pointer;
    ErrCode code;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_STRING(string,pointer) )
        {
            if ((code = BitVector_from_Bin(address,pointer)))
                BIT_VECTOR_EXCEPTION(code);
        }
        else BIT_VECTOR_STRING_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_to_Dec(reference)
BitVector_Object	reference
PPCODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    charptr string;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        string = BitVector_to_Dec(address);
        if (string != NULL)
        {
            EXTEND(sp,1);
            PUSHs(sv_2mortal(newSVpv((char *)string,0)));
            BitVector_Dispose(string);
        }
        else BIT_VECTOR_MEMORY_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_from_Dec(reference,string)
BitVector_Object	reference
BitVector_Scalar	string
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    charptr pointer;
    ErrCode code;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_STRING(string,pointer) )
        {
            if ((code = BitVector_from_Dec(address,pointer)))
                BIT_VECTOR_EXCEPTION(code);
        }
        else BIT_VECTOR_STRING_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_to_Enum(reference)
BitVector_Object	reference
ALIAS:
  to_ASCII = 2
PPCODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    charptr string;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        string = BitVector_to_Enum(address);
        if (string != NULL)
        {
            EXTEND(sp,1);
            PUSHs(sv_2mortal(newSVpv((char *)string,0)));
            BitVector_Dispose(string);
        }
        else BIT_VECTOR_MEMORY_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_from_Enum(reference,string)
BitVector_Object	reference
BitVector_Scalar	string
ALIAS:
  from_ASCII = 2
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    charptr pointer;
    ErrCode code;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_STRING(string,pointer) )
        {
            if ((code = BitVector_from_Enum(address,pointer)))
                BIT_VECTOR_EXCEPTION(code);
        }
        else BIT_VECTOR_STRING_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_Bit_Off(reference,index)
BitVector_Object	reference
BitVector_Scalar	index
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    N_int idx;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_SCALAR(index,N_int,idx) )
        {
            if (idx < bits_(address))
            {
                BitVector_Bit_Off(address,idx);
            }
            else BIT_VECTOR_INDEX_ERROR;
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_Bit_On(reference,index)
BitVector_Object	reference
BitVector_Scalar	index
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    N_int idx;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_SCALAR(index,N_int,idx) )
        {
            if (idx < bits_(address))
            {
                BitVector_Bit_On(address,idx);
            }
            else BIT_VECTOR_INDEX_ERROR;
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


boolean
BitVector_bit_flip(reference,index)
BitVector_Object	reference
BitVector_Scalar	index
ALIAS:
  flip = 2
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    N_int idx;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_SCALAR(index,N_int,idx) )
        {
            if (idx < bits_(address))
            {
                RETVAL = BitVector_bit_flip(address,idx);
            }
            else BIT_VECTOR_INDEX_ERROR;
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}
OUTPUT:
RETVAL


boolean
BitVector_bit_test(reference,index)
BitVector_Object	reference
BitVector_Scalar	index
ALIAS:
  contains = 1
  in = 2
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    N_int idx;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_SCALAR(index,N_int,idx) )
        {
            if (idx < bits_(address))
            {
                RETVAL = BitVector_bit_test(address,idx);
            }
            else BIT_VECTOR_INDEX_ERROR;
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}
OUTPUT:
RETVAL


void
BitVector_Bit_Copy(reference,index,bit)
BitVector_Object	reference
BitVector_Scalar	index
BitVector_Scalar	bit
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    N_int idx;
    boolean b;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_SCALAR(index,N_int,idx) &&
             BIT_VECTOR_SCALAR(bit,boolean,b) )
        {
            if (idx < bits_(address))
            {
                BitVector_Bit_Copy(address,idx,b);
            }
            else BIT_VECTOR_INDEX_ERROR;
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_LSB(reference,bit)
BitVector_Object	reference
BitVector_Scalar	bit
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    boolean b;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_SCALAR(bit,boolean,b) )
        {
            BitVector_LSB(address,b);
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_MSB(reference,bit)
BitVector_Object	reference
BitVector_Scalar	bit
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    boolean b;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_SCALAR(bit,boolean,b) )
        {
            BitVector_MSB(address,b);
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


boolean
BitVector_lsb(reference)
BitVector_Object	reference
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        RETVAL = BitVector_lsb_(address);
    }
    else BIT_VECTOR_OBJECT_ERROR;
}
OUTPUT:
RETVAL


boolean
BitVector_msb(reference)
BitVector_Object	reference
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        RETVAL = BitVector_msb_(address);
    }
    else BIT_VECTOR_OBJECT_ERROR;
}
OUTPUT:
RETVAL


boolean
BitVector_rotate_left(reference)
BitVector_Object	reference
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        RETVAL = BitVector_rotate_left(address);
    }
    else BIT_VECTOR_OBJECT_ERROR;
}
OUTPUT:
RETVAL


boolean
BitVector_rotate_right(reference)
BitVector_Object	reference
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        RETVAL = BitVector_rotate_right(address);
    }
    else BIT_VECTOR_OBJECT_ERROR;
}
OUTPUT:
RETVAL


boolean
BitVector_shift_left(reference,carry)
BitVector_Object	reference
BitVector_Scalar	carry
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    boolean c;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_SCALAR(carry,boolean,c) )
        {
            RETVAL = BitVector_shift_left(address,c);
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}
OUTPUT:
RETVAL


boolean
BitVector_shift_right(reference,carry)
BitVector_Object	reference
BitVector_Scalar	carry
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    boolean c;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_SCALAR(carry,boolean,c) )
        {
            RETVAL = BitVector_shift_right(address,c);
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}
OUTPUT:
RETVAL


void
BitVector_Move_Left(reference,bits)
BitVector_Object	reference
BitVector_Scalar	bits
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    N_int cnt;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_SCALAR(bits,N_int,cnt) )
        {
            BitVector_Move_Left(address,cnt);
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_Move_Right(reference,bits)
BitVector_Object	reference
BitVector_Scalar	bits
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    N_int cnt;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_SCALAR(bits,N_int,cnt) )
        {
            BitVector_Move_Right(address,cnt);
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_Insert(reference,offset,count)
BitVector_Object	reference
BitVector_Scalar	offset
BitVector_Scalar	count
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    N_int off;
    N_int cnt;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_SCALAR(offset,N_int,off) &&
             BIT_VECTOR_SCALAR(count,N_int,cnt) )
        {
            if (off < bits_(address))
            {
                BitVector_Insert(address,off,cnt,true);
            }
            else BIT_VECTOR_OFFSET_ERROR;
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_Delete(reference,offset,count)
BitVector_Object	reference
BitVector_Scalar	offset
BitVector_Scalar	count
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    N_int off;
    N_int cnt;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_SCALAR(offset,N_int,off) &&
             BIT_VECTOR_SCALAR(count,N_int,cnt) )
        {
            if (off < bits_(address))
            {
                BitVector_Delete(address,off,cnt,true);
            }
            else BIT_VECTOR_OFFSET_ERROR;
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


boolean
BitVector_increment(reference)
BitVector_Object	reference
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        RETVAL = BitVector_increment(address);
    }
    else BIT_VECTOR_OBJECT_ERROR;
}
OUTPUT:
RETVAL


boolean
BitVector_decrement(reference)
BitVector_Object	reference
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        RETVAL = BitVector_decrement(address);
    }
    else BIT_VECTOR_OBJECT_ERROR;
}
OUTPUT:
RETVAL


void
BitVector_add(Xref,Yref,Zref,carry)
BitVector_Object	Xref
BitVector_Object	Yref
BitVector_Object	Zref
BitVector_Scalar	carry
PPCODE:
{
    BitVector_Handle  Xhdl;
    BitVector_Address Xadr;
    BitVector_Handle  Yhdl;
    BitVector_Address Yadr;
    BitVector_Handle  Zhdl;
    BitVector_Address Zadr;
    boolean c;
    boolean v;

    if ( BIT_VECTOR_OBJECT(Xref,Xhdl,Xadr) &&
         BIT_VECTOR_OBJECT(Yref,Yhdl,Yadr) &&
         BIT_VECTOR_OBJECT(Zref,Zhdl,Zadr) )
    {
        if ( BIT_VECTOR_SCALAR(carry,boolean,c) )
        {
            if ((bits_(Xadr) == bits_(Yadr)) and (bits_(Xadr) == bits_(Zadr)))
            {
                v = BitVector_compute(Xadr,Yadr,Zadr,false,&c);
                if (GIMME_V == G_ARRAY)
                {
                    EXTEND(sp,2);
                    PUSHs(sv_2mortal(newSViv((IV)c)));
                    PUSHs(sv_2mortal(newSViv((IV)v)));
                }
                else
                {
                    EXTEND(sp,1);
                    PUSHs(sv_2mortal(newSViv((IV)c)));
                }
            }
            else BIT_VECTOR_SIZE_ERROR;
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_subtract(Xref,Yref,Zref,carry)
BitVector_Object	Xref
BitVector_Object	Yref
BitVector_Object	Zref
BitVector_Scalar	carry
ALIAS:
  sub = 2
PPCODE:
{
    BitVector_Handle  Xhdl;
    BitVector_Address Xadr;
    BitVector_Handle  Yhdl;
    BitVector_Address Yadr;
    BitVector_Handle  Zhdl;
    BitVector_Address Zadr;
    boolean c;
    boolean v;

    if ( BIT_VECTOR_OBJECT(Xref,Xhdl,Xadr) &&
         BIT_VECTOR_OBJECT(Yref,Yhdl,Yadr) &&
         BIT_VECTOR_OBJECT(Zref,Zhdl,Zadr) )
    {
        if ( BIT_VECTOR_SCALAR(carry,boolean,c) )
        {
            if ((bits_(Xadr) == bits_(Yadr)) and (bits_(Xadr) == bits_(Zadr)))
            {
                v = BitVector_compute(Xadr,Yadr,Zadr,true,&c);
                if (GIMME_V == G_ARRAY)
                {
                    EXTEND(sp,2);
                    PUSHs(sv_2mortal(newSViv((IV)c)));
                    PUSHs(sv_2mortal(newSViv((IV)v)));
                }
                else
                {
                    EXTEND(sp,1);
                    PUSHs(sv_2mortal(newSViv((IV)c)));
                }
            }
            else BIT_VECTOR_SIZE_ERROR;
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


boolean
BitVector_inc(Xref,Yref)
BitVector_Object	Xref
BitVector_Object	Yref
CODE:
{
    BitVector_Handle  Xhdl;
    BitVector_Address Xadr;
    BitVector_Handle  Yhdl;
    BitVector_Address Yadr;
    boolean c = true;

    if ( BIT_VECTOR_OBJECT(Xref,Xhdl,Xadr) &&
         BIT_VECTOR_OBJECT(Yref,Yhdl,Yadr) )
    {
        if (bits_(Xadr) == bits_(Yadr))
        {
            RETVAL = BitVector_compute(Xadr,Yadr,NULL,false,&c);
        }
        else BIT_VECTOR_SIZE_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}
OUTPUT:
RETVAL


boolean
BitVector_dec(Xref,Yref)
BitVector_Object	Xref
BitVector_Object	Yref
CODE:
{
    BitVector_Handle  Xhdl;
    BitVector_Address Xadr;
    BitVector_Handle  Yhdl;
    BitVector_Address Yadr;
    boolean c = true;

    if ( BIT_VECTOR_OBJECT(Xref,Xhdl,Xadr) &&
         BIT_VECTOR_OBJECT(Yref,Yhdl,Yadr) )
    {
        if (bits_(Xadr) == bits_(Yadr))
        {
            RETVAL = BitVector_compute(Xadr,Yadr,NULL,true,&c);
        }
        else BIT_VECTOR_SIZE_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}
OUTPUT:
RETVAL


void
BitVector_Negate(Xref,Yref)
BitVector_Object	Xref
BitVector_Object	Yref
ALIAS:
  Neg = 1
CODE:
{
    BitVector_Handle  Xhdl;
    BitVector_Address Xadr;
    BitVector_Handle  Yhdl;
    BitVector_Address Yadr;

    if ( BIT_VECTOR_OBJECT(Xref,Xhdl,Xadr) &&
         BIT_VECTOR_OBJECT(Yref,Yhdl,Yadr) )
    {
        if (bits_(Xadr) == bits_(Yadr))
        {
            BitVector_Negate(Xadr,Yadr);
        }
        else BIT_VECTOR_SIZE_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_Absolute(Xref,Yref)
BitVector_Object	Xref
BitVector_Object	Yref
ALIAS:
  Abs = 1
CODE:
{
    BitVector_Handle  Xhdl;
    BitVector_Address Xadr;
    BitVector_Handle  Yhdl;
    BitVector_Address Yadr;

    if ( BIT_VECTOR_OBJECT(Xref,Xhdl,Xadr) &&
         BIT_VECTOR_OBJECT(Yref,Yhdl,Yadr) )
    {
        if (bits_(Xadr) == bits_(Yadr))
        {
            BitVector_Absolute(Xadr,Yadr);
        }
        else BIT_VECTOR_SIZE_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


Z_int
BitVector_Sign(reference)
BitVector_Object	reference
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        RETVAL = BitVector_Sign(address);
    }
    else BIT_VECTOR_OBJECT_ERROR;
}
OUTPUT:
RETVAL


void
BitVector_Multiply(Xref,Yref,Zref)
BitVector_Object	Xref
BitVector_Object	Yref
BitVector_Object	Zref
CODE:
{
    BitVector_Handle  Xhdl;
    BitVector_Address Xadr;
    BitVector_Handle  Yhdl;
    BitVector_Address Yadr;
    BitVector_Handle  Zhdl;
    BitVector_Address Zadr;
    ErrCode           code;

    if ( BIT_VECTOR_OBJECT(Xref,Xhdl,Xadr) &&
         BIT_VECTOR_OBJECT(Yref,Yhdl,Yadr) &&
         BIT_VECTOR_OBJECT(Zref,Zhdl,Zadr) )
    {
        if ((bits_(Xadr) >= bits_(Yadr)) and (bits_(Yadr) == bits_(Zadr)))
        {
            if ((code = BitVector_Multiply(Xadr,Yadr,Zadr)))
                BIT_VECTOR_EXCEPTION(code);
        }
        else BIT_VECTOR_SIZE_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_Divide(Qref,Xref,Yref,Rref)
BitVector_Object	Qref
BitVector_Object	Xref
BitVector_Object	Yref
BitVector_Object	Rref
CODE:
{
    BitVector_Handle  Qhdl;
    BitVector_Address Qadr;
    BitVector_Handle  Xhdl;
    BitVector_Address Xadr;
    BitVector_Handle  Yhdl;
    BitVector_Address Yadr;
    BitVector_Handle  Rhdl;
    BitVector_Address Radr;
    ErrCode           code;

    if ( BIT_VECTOR_OBJECT(Qref,Qhdl,Qadr) &&
         BIT_VECTOR_OBJECT(Xref,Xhdl,Xadr) &&
         BIT_VECTOR_OBJECT(Yref,Yhdl,Yadr) &&
         BIT_VECTOR_OBJECT(Rref,Rhdl,Radr) )
    {
        if ((code = BitVector_Divide(Qadr,Xadr,Yadr,Radr)))
            BIT_VECTOR_EXCEPTION(code);
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_GCD(...)
CODE:
{
    BitVector_Object  Uref;
    BitVector_Handle  Uhdl;
    BitVector_Address Uadr;
    BitVector_Object  Vref;
    BitVector_Handle  Vhdl;
    BitVector_Address Vadr;
    BitVector_Object  Wref;
    BitVector_Handle  Whdl;
    BitVector_Address Wadr;
    BitVector_Object  Xref;
    BitVector_Handle  Xhdl;
    BitVector_Address Xadr;
    BitVector_Object  Yref;
    BitVector_Handle  Yhdl;
    BitVector_Address Yadr;
    ErrCode           code;

    if      (items == 3)
    {
        Uref = ST(0);
        Xref = ST(1);
        Yref = ST(2);
        if ( BIT_VECTOR_OBJECT(Uref,Uhdl,Uadr) &&
             BIT_VECTOR_OBJECT(Xref,Xhdl,Xadr) &&
             BIT_VECTOR_OBJECT(Yref,Yhdl,Yadr) )
        {
            if ((code = BitVector_GCD(Uadr,Xadr,Yadr)))
                BIT_VECTOR_EXCEPTION(code);
        }
        else BIT_VECTOR_OBJECT_ERROR;
    }
    else if (items == 5)
    {
        Uref = ST(0);
        Vref = ST(1);
        Wref = ST(2);
        Xref = ST(3);
        Yref = ST(4);
        if ( BIT_VECTOR_OBJECT(Uref,Uhdl,Uadr) &&
             BIT_VECTOR_OBJECT(Vref,Vhdl,Vadr) &&
             BIT_VECTOR_OBJECT(Wref,Whdl,Wadr) &&
             BIT_VECTOR_OBJECT(Xref,Xhdl,Xadr) &&
             BIT_VECTOR_OBJECT(Yref,Yhdl,Yadr) )
        {
            if ((code = BitVector_GCD2(Uadr,Vadr,Wadr,Xadr,Yadr)))
                BIT_VECTOR_EXCEPTION(code);
        }
        else BIT_VECTOR_OBJECT_ERROR;
    }
    else croak("Usage: %s(Uref[,Vref,Wref],Xref,Yref)", GvNAME(CvGV(cv)));
}


void
BitVector_Power(Xref,Yref,Zref)
BitVector_Object	Xref
BitVector_Object	Yref
BitVector_Object	Zref
CODE:
{
    BitVector_Handle  Xhdl;
    BitVector_Address Xadr;
    BitVector_Handle  Yhdl;
    BitVector_Address Yadr;
    BitVector_Handle  Zhdl;
    BitVector_Address Zadr;
    ErrCode           code;

    if ( BIT_VECTOR_OBJECT(Xref,Xhdl,Xadr) &&
         BIT_VECTOR_OBJECT(Yref,Yhdl,Yadr) &&
         BIT_VECTOR_OBJECT(Zref,Zhdl,Zadr) )
    {
        if ((code = BitVector_Power(Xadr,Yadr,Zadr)))
            BIT_VECTOR_EXCEPTION(code);
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_Block_Store(reference,buffer)
BitVector_Object	reference
BitVector_Scalar	buffer
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    charptr string;
    N_int length;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_BUFFER(buffer,string,length) )
        {
            BitVector_Block_Store(address,string,length);
        }
        else BIT_VECTOR_STRING_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_Block_Read(reference)
BitVector_Object	reference
PPCODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    charptr string;
    N_int length;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        string = BitVector_Block_Read(address,&length);
        if (string != NULL)
        {
            EXTEND(sp,1);
            PUSHs(sv_2mortal(newSVpv((char *)string,length)));
            BitVector_Dispose(string);
        }
        else BIT_VECTOR_MEMORY_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


N_int
BitVector_Word_Size(reference)
BitVector_Object	reference
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        RETVAL = size_(address);
    }
    else BIT_VECTOR_OBJECT_ERROR;
}
OUTPUT:
RETVAL


void
BitVector_Word_Store(reference,offset,value)
BitVector_Object	reference
BitVector_Scalar	offset
BitVector_Scalar	value
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    N_int off;
    N_int val;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_SCALAR(offset,N_int,off) &&
             BIT_VECTOR_SCALAR(value,N_int,val) )
        {
            if (off < size_(address))
            {
                BitVector_Word_Store(address,off,val);
            }
            else BIT_VECTOR_OFFSET_ERROR;
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


N_int
BitVector_Word_Read(reference,offset)
BitVector_Object	reference
BitVector_Scalar	offset
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    N_int off;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_SCALAR(offset,N_int,off) )
        {
            if (off < size_(address))
            {
                RETVAL = BitVector_Word_Read(address,off);
            }
            else BIT_VECTOR_OFFSET_ERROR;
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}
OUTPUT:
RETVAL


void
BitVector_Word_List_Store(reference,...)
BitVector_Object	reference
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    BitVector_Scalar  scalar;
    N_int offset;
    N_int value;
    N_int size;
    I32 index;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        size = size_(address);
        for ( offset = 0, index = 1;
            ((offset < size) and (index < items)); offset++, index++ )
        {
            scalar = ST(index);
            if ( BIT_VECTOR_SCALAR(scalar,N_int,value) )
            {
                BitVector_Word_Store(address,offset,value);
            }
            else BIT_VECTOR_SCALAR_ERROR;
        }
        for ( ; (offset < size); offset++ )
        {
            BitVector_Word_Store(address,offset,0);
        }
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_Word_List_Read(reference)
BitVector_Object	reference
PPCODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    N_int offset;
    N_int value;
    N_int size;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        size = size_(address);
        EXTEND(sp,(int)size);
        for ( offset = 0; (offset < size); offset++ )
        {
            value = BitVector_Word_Read(address,offset);
            PUSHs(sv_2mortal(newSViv((IV)value)));
        }
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_Word_Insert(reference,offset,count)
BitVector_Object	reference
BitVector_Scalar	offset
BitVector_Scalar	count
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    N_int off;
    N_int cnt;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_SCALAR(offset,N_int,off) &&
             BIT_VECTOR_SCALAR(count,N_int,cnt) )
        {
            if (off < size_(address))
            {
                BitVector_Word_Insert(address,off,cnt,true);
            }
            else BIT_VECTOR_OFFSET_ERROR;
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_Word_Delete(reference,offset,count)
BitVector_Object	reference
BitVector_Scalar	offset
BitVector_Scalar	count
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    N_int off;
    N_int cnt;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_SCALAR(offset,N_int,off) &&
             BIT_VECTOR_SCALAR(count,N_int,cnt) )
        {
            if (off < size_(address))
            {
                BitVector_Word_Delete(address,off,cnt,true);
            }
            else BIT_VECTOR_OFFSET_ERROR;
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_Chunk_Store(reference,chunksize,offset,value)
BitVector_Object	reference
BitVector_Scalar	chunksize
BitVector_Scalar	offset
BitVector_Scalar	value
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    N_int bits;
    N_int off;
    N_long val;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_SCALAR(chunksize,N_int,bits) &&
             BIT_VECTOR_SCALAR(offset,N_int,off) &&
             BIT_VECTOR_SCALAR(value,N_long,val) )
        {
            if ((bits > 0) and (bits <= BitVector_Long_Bits()))
            {
                if (off < bits_(address))
                {
                    BitVector_Chunk_Store(address,bits,off,val);
                }
                else BIT_VECTOR_OFFSET_ERROR;
            }
            else BIT_VECTOR_CHUNK_ERROR;
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


N_long
BitVector_Chunk_Read(reference,chunksize,offset)
BitVector_Object	reference
BitVector_Scalar	chunksize
BitVector_Scalar	offset
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    N_int bits;
    N_int off;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_SCALAR(chunksize,N_int,bits) &&
             BIT_VECTOR_SCALAR(offset,N_int,off) )
        {
            if ((bits > 0) and (bits <= BitVector_Long_Bits()))
            {
                if (off < bits_(address))
                {
                    RETVAL = BitVector_Chunk_Read(address,bits,off);
                }
                else BIT_VECTOR_OFFSET_ERROR;
            }
            else BIT_VECTOR_CHUNK_ERROR;
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}
OUTPUT:
RETVAL


void
BitVector_Chunk_List_Store(reference,chunksize,...)
BitVector_Object	reference
BitVector_Scalar	chunksize
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    BitVector_Scalar  scalar;
    N_int chunkspan;
    N_long chunkmask;
    N_long mask;
    N_long chunk;
    N_long value;
    N_int chunkbits;
    N_int wordbits;
    N_int wordsize;
    N_int offset;
    N_int size;
    N_int bits;
    I32 index;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_SCALAR(chunksize,N_int,chunkspan) )
        {
            if ((chunkspan > 0) and (chunkspan <= BitVector_Long_Bits()))
            {
                wordsize = BitVector_Word_Bits();
                size = size_(address);
                chunkmask = ~((~0L << (chunkspan-1)) << 1); /* C bug work-around */
                chunk = 0L;
                value = 0L;
                index = 2;
                offset = 0;
                wordbits = 0;
                chunkbits = 0;
                while (offset < size)
                {
                    if ((chunkbits == 0) and (index < items))
                    {
                        scalar = ST(index);
                        if ( BIT_VECTOR_SCALAR(scalar,N_long,chunk) )
                        {
                            chunk &= chunkmask;
                            chunkbits = chunkspan;
                            index++;
                        }
                        else BIT_VECTOR_SCALAR_ERROR;
                    }
                    bits = wordsize - wordbits;
                    if (chunkbits <= bits)
                    {
                        chunk <<= wordbits;
                        value |= chunk;
                        wordbits += chunkbits;
                        chunk = 0L;
                        chunkbits = 0;
                    }
                    else
                    {
                        mask = ~(~0L << bits);
                        mask &= chunk;
                        mask <<= wordbits;
                        value |= mask;
                        wordbits += bits;
                        chunk >>= bits;
                        chunkbits -= bits;
                    }
                    if ((wordbits >= wordsize) or (index >= items))
                    {
                        BitVector_Word_Store(address,offset,(N_int)value);
                        value = 0L;
                        wordbits = 0;
                        offset++;
                    }
                }
            }
            else BIT_VECTOR_CHUNK_ERROR;
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_Chunk_List_Read(reference,chunksize)
BitVector_Object	reference
BitVector_Scalar	chunksize
PPCODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    N_int chunkspan;
    N_long chunk;
    N_long value;
    N_long mask;
    N_int chunkbits;
    N_int wordbits;
    N_int wordsize;
    N_int length;
    N_int index;
    N_int offset;
    N_int size;
    N_int bits;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_SCALAR(chunksize,N_int,chunkspan) )
        {
            if ((chunkspan > 0) and (chunkspan <= BitVector_Long_Bits()))
            {
                wordsize = BitVector_Word_Bits();
                bits = bits_(address);
                size = size_(address);
                length = (N_int) (bits / chunkspan);
                if ((length * chunkspan) < bits) length++;
                EXTEND(sp,(int)length);
                chunk = 0L;
                value = 0L;
                index = 0;
                offset = 0;
                wordbits = 0;
                chunkbits = 0;
                while (index < length)
                {
                    if ((wordbits == 0) and (offset < size))
                    {
                        value = (N_long) BitVector_Word_Read(address,offset);
                        wordbits = wordsize;
                        offset++;
                    }
                    bits = chunkspan - chunkbits;
                    if (wordbits <= bits)
                    {
                        value <<= chunkbits;
                        chunk |= value;
                        chunkbits += wordbits;
                        value = 0L;
                        wordbits = 0;
                    }
                    else
                    {
                        mask = ~(~0L << bits);
                        mask &= value;
                        mask <<= chunkbits;
                        chunk |= mask;
                        chunkbits += bits;
                        value >>= bits;
                        wordbits -= bits;
                    }
                    if ((chunkbits >= chunkspan) or
                        ((offset >= size) and (chunkbits > 0)))
                    {
                        PUSHs(sv_2mortal(newSViv((IV)chunk)));
                        chunk = 0L;
                        chunkbits = 0;
                        index++;
                    }
                }
            }
            else BIT_VECTOR_CHUNK_ERROR;
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_Index_List_Remove(reference,...)
BitVector_Object	reference
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    BitVector_Scalar  scalar;
    N_int value;
    N_int bits;
    I32 index;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        bits = bits_(address);
        for ( index = 1; index < items; index++ )
        {
            scalar = ST(index);
            if ( BIT_VECTOR_SCALAR(scalar,N_int,value) )
            {
                if (value < bits)
                {
                    BitVector_Bit_Off(address,value);
                }
                else BIT_VECTOR_INDEX_ERROR;
            }
            else BIT_VECTOR_SCALAR_ERROR;
        }
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_Index_List_Store(reference,...)
BitVector_Object	reference
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    BitVector_Scalar  scalar;
    N_int value;
    N_int bits;
    I32 index;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        bits = bits_(address);
        for ( index = 1; index < items; index++ )
        {
            scalar = ST(index);
            if ( BIT_VECTOR_SCALAR(scalar,N_int,value) )
            {
                if (value < bits)
                {
                    BitVector_Bit_On(address,value);
                }
                else BIT_VECTOR_INDEX_ERROR;
            }
            else BIT_VECTOR_SCALAR_ERROR;
        }
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
BitVector_Index_List_Read(reference)
BitVector_Object	reference
PPCODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    N_int size;
    N_int bits;
    N_int norm;
    N_int base;
    N_int word;
    N_int index;
    N_int value;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        size = size_(address);
        bits = BitVector_Word_Bits();
        norm = Set_Norm(address);
        if (norm > 0)
        {
            EXTEND(sp,(int)norm);
            for ( base = word = 0; word < size; word++, base += bits )
            {
                index = base;
                value = BitVector_Word_Read(address,word);
                while (value)
                {
                    if (value AND 0x0001)
                      PUSHs(sv_2mortal(newSViv((IV)index)));
                    value >>= 1;
                    index++;
                }
            }
        }
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


MODULE = Bit::Vector		PACKAGE = Bit::Vector		PREFIX = Set_


void
Set_Union(Xref,Yref,Zref)
BitVector_Object	Xref
BitVector_Object	Yref
BitVector_Object	Zref
ALIAS:
  Or = 1
CODE:
{
    BitVector_Handle  Xhdl;
    BitVector_Address Xadr;
    BitVector_Handle  Yhdl;
    BitVector_Address Yadr;
    BitVector_Handle  Zhdl;
    BitVector_Address Zadr;

    if ( BIT_VECTOR_OBJECT(Xref,Xhdl,Xadr) &&
         BIT_VECTOR_OBJECT(Yref,Yhdl,Yadr) &&
         BIT_VECTOR_OBJECT(Zref,Zhdl,Zadr) )
    {
        if ((bits_(Xadr) == bits_(Yadr)) and (bits_(Xadr) == bits_(Zadr)))
        {
            Set_Union(Xadr,Yadr,Zadr);
        }
        else BIT_VECTOR_SET_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
Set_Intersection(Xref,Yref,Zref)
BitVector_Object	Xref
BitVector_Object	Yref
BitVector_Object	Zref
ALIAS:
  And = 1
CODE:
{
    BitVector_Handle  Xhdl;
    BitVector_Address Xadr;
    BitVector_Handle  Yhdl;
    BitVector_Address Yadr;
    BitVector_Handle  Zhdl;
    BitVector_Address Zadr;

    if ( BIT_VECTOR_OBJECT(Xref,Xhdl,Xadr) &&
         BIT_VECTOR_OBJECT(Yref,Yhdl,Yadr) &&
         BIT_VECTOR_OBJECT(Zref,Zhdl,Zadr) )
    {
        if ((bits_(Xadr) == bits_(Yadr)) and (bits_(Xadr) == bits_(Zadr)))
        {
            Set_Intersection(Xadr,Yadr,Zadr);
        }
        else BIT_VECTOR_SET_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
Set_Difference(Xref,Yref,Zref)
BitVector_Object	Xref
BitVector_Object	Yref
BitVector_Object	Zref
ALIAS:
  AndNot = 1
CODE:
{
    BitVector_Handle  Xhdl;
    BitVector_Address Xadr;
    BitVector_Handle  Yhdl;
    BitVector_Address Yadr;
    BitVector_Handle  Zhdl;
    BitVector_Address Zadr;

    if ( BIT_VECTOR_OBJECT(Xref,Xhdl,Xadr) &&
         BIT_VECTOR_OBJECT(Yref,Yhdl,Yadr) &&
         BIT_VECTOR_OBJECT(Zref,Zhdl,Zadr) )
    {
        if ((bits_(Xadr) == bits_(Yadr)) and (bits_(Xadr) == bits_(Zadr)))
        {
            Set_Difference(Xadr,Yadr,Zadr);
        }
        else BIT_VECTOR_SET_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
Set_ExclusiveOr(Xref,Yref,Zref)
BitVector_Object	Xref
BitVector_Object	Yref
BitVector_Object	Zref
ALIAS:
  Xor = 1
CODE:
{
    BitVector_Handle  Xhdl;
    BitVector_Address Xadr;
    BitVector_Handle  Yhdl;
    BitVector_Address Yadr;
    BitVector_Handle  Zhdl;
    BitVector_Address Zadr;

    if ( BIT_VECTOR_OBJECT(Xref,Xhdl,Xadr) &&
         BIT_VECTOR_OBJECT(Yref,Yhdl,Yadr) &&
         BIT_VECTOR_OBJECT(Zref,Zhdl,Zadr) )
    {
        if ((bits_(Xadr) == bits_(Yadr)) and (bits_(Xadr) == bits_(Zadr)))
        {
            Set_ExclusiveOr(Xadr,Yadr,Zadr);
        }
        else BIT_VECTOR_SET_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
Set_Complement(Xref,Yref)
BitVector_Object	Xref
BitVector_Object	Yref
ALIAS:
  Not = 1
CODE:
{
    BitVector_Handle  Xhdl;
    BitVector_Address Xadr;
    BitVector_Handle  Yhdl;
    BitVector_Address Yadr;

    if ( BIT_VECTOR_OBJECT(Xref,Xhdl,Xadr) &&
         BIT_VECTOR_OBJECT(Yref,Yhdl,Yadr) )
    {
        if (bits_(Xadr) == bits_(Yadr))
        {
            Set_Complement(Xadr,Yadr);
        }
        else BIT_VECTOR_SET_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


boolean
Set_subset(Xref,Yref)
BitVector_Object	Xref
BitVector_Object	Yref
ALIAS:
  inclusion = 2
CODE:
{
    BitVector_Handle  Xhdl;
    BitVector_Address Xadr;
    BitVector_Handle  Yhdl;
    BitVector_Address Yadr;

    if ( BIT_VECTOR_OBJECT(Xref,Xhdl,Xadr) &&
         BIT_VECTOR_OBJECT(Yref,Yhdl,Yadr) )
    {
        if (bits_(Xadr) == bits_(Yadr))
        {
            RETVAL = Set_subset(Xadr,Yadr);
        }
        else BIT_VECTOR_SET_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}
OUTPUT:
RETVAL


N_int
Set_Norm(reference)
BitVector_Object	reference
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        RETVAL = Set_Norm(address);
    }
    else BIT_VECTOR_OBJECT_ERROR;
}
OUTPUT:
RETVAL


N_int
Set_Norm2(reference)
BitVector_Object	reference
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        RETVAL = Set_Norm2(address);
    }
    else BIT_VECTOR_OBJECT_ERROR;
}
OUTPUT:
RETVAL


N_int
Set_Norm3(reference)
BitVector_Object	reference
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        RETVAL = Set_Norm3(address);
    }
    else BIT_VECTOR_OBJECT_ERROR;
}
OUTPUT:
RETVAL


Z_long
Set_Min(reference)
BitVector_Object	reference
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        RETVAL = Set_Min(address);
    }
    else BIT_VECTOR_OBJECT_ERROR;
}
OUTPUT:
RETVAL


Z_long
Set_Max(reference)
BitVector_Object	reference
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        RETVAL = Set_Max(address);
    }
    else BIT_VECTOR_OBJECT_ERROR;
}
OUTPUT:
RETVAL


MODULE = Bit::Vector		PACKAGE = Bit::Vector		PREFIX = Matrix_


void
Matrix_Multiplication(Xref,Xrows,Xcols,Yref,Yrows,Ycols,Zref,Zrows,Zcols)
BitVector_Object	Xref
BitVector_Scalar	Xrows
BitVector_Scalar	Xcols
BitVector_Object	Yref
BitVector_Scalar	Yrows
BitVector_Scalar	Ycols
BitVector_Object	Zref
BitVector_Scalar	Zrows
BitVector_Scalar	Zcols
CODE:
{
    BitVector_Handle  Xhdl;
    BitVector_Address Xadr;
    BitVector_Handle  Yhdl;
    BitVector_Address Yadr;
    BitVector_Handle  Zhdl;
    BitVector_Address Zadr;
    N_int rowsX;
    N_int colsX;
    N_int rowsY;
    N_int colsY;
    N_int rowsZ;
    N_int colsZ;

    if ( BIT_VECTOR_OBJECT(Xref,Xhdl,Xadr) &&
         BIT_VECTOR_OBJECT(Yref,Yhdl,Yadr) &&
         BIT_VECTOR_OBJECT(Zref,Zhdl,Zadr) )
    {
        if ( BIT_VECTOR_SCALAR(Xrows,N_int,rowsX) &&
             BIT_VECTOR_SCALAR(Xcols,N_int,colsX) &&
             BIT_VECTOR_SCALAR(Yrows,N_int,rowsY) &&
             BIT_VECTOR_SCALAR(Ycols,N_int,colsY) &&
             BIT_VECTOR_SCALAR(Zrows,N_int,rowsZ) &&
             BIT_VECTOR_SCALAR(Zcols,N_int,colsZ) )
        {
            if ((colsY == rowsZ) and (rowsX == rowsY) and (colsX == colsZ) and
                (bits_(Xadr) == rowsX*colsX) and
                (bits_(Yadr) == rowsY*colsY) and
                (bits_(Zadr) == rowsZ*colsZ))
            {
                Matrix_Multiplication(Xadr,rowsX,colsX,
                                      Yadr,rowsY,colsY,
                                      Zadr,rowsZ,colsZ);
            }
            else BIT_VECTOR_MATRIX_ERROR;
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
Matrix_Product(Xref,Xrows,Xcols,Yref,Yrows,Ycols,Zref,Zrows,Zcols)
BitVector_Object	Xref
BitVector_Scalar	Xrows
BitVector_Scalar	Xcols
BitVector_Object	Yref
BitVector_Scalar	Yrows
BitVector_Scalar	Ycols
BitVector_Object	Zref
BitVector_Scalar	Zrows
BitVector_Scalar	Zcols
CODE:
{
    BitVector_Handle  Xhdl;
    BitVector_Address Xadr;
    BitVector_Handle  Yhdl;
    BitVector_Address Yadr;
    BitVector_Handle  Zhdl;
    BitVector_Address Zadr;
    N_int rowsX;
    N_int colsX;
    N_int rowsY;
    N_int colsY;
    N_int rowsZ;
    N_int colsZ;

    if ( BIT_VECTOR_OBJECT(Xref,Xhdl,Xadr) &&
         BIT_VECTOR_OBJECT(Yref,Yhdl,Yadr) &&
         BIT_VECTOR_OBJECT(Zref,Zhdl,Zadr) )
    {
        if ( BIT_VECTOR_SCALAR(Xrows,N_int,rowsX) &&
             BIT_VECTOR_SCALAR(Xcols,N_int,colsX) &&
             BIT_VECTOR_SCALAR(Yrows,N_int,rowsY) &&
             BIT_VECTOR_SCALAR(Ycols,N_int,colsY) &&
             BIT_VECTOR_SCALAR(Zrows,N_int,rowsZ) &&
             BIT_VECTOR_SCALAR(Zcols,N_int,colsZ) )
        {
            if ((colsY == rowsZ) and (rowsX == rowsY) and (colsX == colsZ) and
                (bits_(Xadr) == rowsX*colsX) and
                (bits_(Yadr) == rowsY*colsY) and
                (bits_(Zadr) == rowsZ*colsZ))
            {
                Matrix_Product(Xadr,rowsX,colsX,
                               Yadr,rowsY,colsY,
                               Zadr,rowsZ,colsZ);
            }
            else BIT_VECTOR_MATRIX_ERROR;
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
Matrix_Closure(reference,rows,cols)
BitVector_Object	reference
BitVector_Scalar	rows
BitVector_Scalar	cols
CODE:
{
    BitVector_Handle  handle;
    BitVector_Address address;
    N_int r;
    N_int c;

    if ( BIT_VECTOR_OBJECT(reference,handle,address) )
    {
        if ( BIT_VECTOR_SCALAR(rows,N_int,r) &&
             BIT_VECTOR_SCALAR(cols,N_int,c) )
        {
            if (bits_(address) == r*c)
            {
                if (r == c)
                {
                    Matrix_Closure(address,r,c);
                }
                else BIT_VECTOR_SHAPE_ERROR;
            }
            else BIT_VECTOR_MATRIX_ERROR;
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


void
Matrix_Transpose(Xref,Xrows,Xcols,Yref,Yrows,Ycols)
BitVector_Object	Xref
BitVector_Scalar	Xrows
BitVector_Scalar	Xcols
BitVector_Object	Yref
BitVector_Scalar	Yrows
BitVector_Scalar	Ycols
CODE:
{
    BitVector_Handle  Xhdl;
    BitVector_Address Xadr;
    BitVector_Handle  Yhdl;
    BitVector_Address Yadr;
    N_int rowsX;
    N_int colsX;
    N_int rowsY;
    N_int colsY;

    if ( BIT_VECTOR_OBJECT(Xref,Xhdl,Xadr) &&
         BIT_VECTOR_OBJECT(Yref,Yhdl,Yadr) )
    {
        if ( BIT_VECTOR_SCALAR(Xrows,N_int,rowsX) &&
             BIT_VECTOR_SCALAR(Xcols,N_int,colsX) &&
             BIT_VECTOR_SCALAR(Yrows,N_int,rowsY) &&
             BIT_VECTOR_SCALAR(Ycols,N_int,colsY) )
        {
            if ((rowsX == colsY) and (colsX == rowsY) and
                (bits_(Xadr) == rowsX*colsX) and
                (bits_(Yadr) == rowsY*colsY))
            {
                if ((Xadr != Yadr) or (rowsY == colsY))
                {
                    Matrix_Transpose(Xadr,rowsX,colsX,
                                     Yadr,rowsY,colsY);
                }
                else BIT_VECTOR_SHAPE_ERROR;
            }
            else BIT_VECTOR_MATRIX_ERROR;
        }
        else BIT_VECTOR_SCALAR_ERROR;
    }
    else BIT_VECTOR_OBJECT_ERROR;
}


