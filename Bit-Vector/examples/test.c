
/*****************************************************************************/
/*                                                                           */
/*    Copyright (c) 2002 by Steffen Beyer.                                   */
/*    All rights reserved.                                                   */
/*                                                                           */
/*    This program is free software; you can redistribute it                 */
/*    and/or modify it under the same terms as Perl itself.                  */
/*                                                                           */
/*****************************************************************************/

/******************************************************/
/*                                                    */
/*  Example for using the BitVector.c library from C  */
/*                                                    */
/*  (Just for playing around; also shows how one can  */
/*   deal with error handling)                        */
/*                                                    */
/*  Copy ToolBox.h and BitVector.h to this directory  */
/*  then compile this file and link with BitVector.o  */
/*                                                    */
/******************************************************/

#include <stdio.h>
#include "ToolBox.h"
#include "BitVector.h"

void ListErrCode(ErrCode code)
{
    if (code) fprintf(stdout, "BitVector ErrCode %2d: %s\n", code, BitVector_Error(code));
}

void PrintErrorMessage(ErrCode code, char *name)
{
    if (code) fprintf(stdout, "Bit::Vector::%s(): %s\n", name, BitVector_Error(code));
}

#define FATAL_ERROR(name,code) \
{ fprintf(stderr, "Bit::Vector::" name "(): %s\n", BitVector_Error(code)); exit(code); }

int main(void)
{
    N_int bits = 5;
//  N_char x[] = "001010";  /* 10 */
    N_char x[] = "001x10";  /* 10 */
//  N_char y[] = "000100";  /*  4 */
//  N_char y[] = "000111";  /*  7 */
    N_char y[] = "001111";  /* 63 */
    wordptr X;
    wordptr Y;
    wordptr Z;
    ErrCode err;
    boolean ovrflw;
    boolean carry = false;

    ListErrCode( 0);
    ListErrCode( 1);
    ListErrCode( 2);
    ListErrCode( 3);
    ListErrCode( 4);
    ListErrCode( 5);
    ListErrCode( 6);
    ListErrCode( 7);
    ListErrCode( 8);
    ListErrCode( 9);
    ListErrCode(10);
    ListErrCode(11);
    ListErrCode(12);
    ListErrCode(13);
    ListErrCode(14);
    ListErrCode(15);
    ListErrCode(16);
    ListErrCode(17);
    ListErrCode(18);
    ListErrCode(19);
    ListErrCode(20);

    err = BitVector_Boot();
    if (err) FATAL_ERROR("Boot", err);

    printf("Number of bits in a WORD: %d\n", BitVector_Word_Bits());
    printf("Number of bits in a LONG: %d\n", BitVector_Long_Bits());

    X = BitVector_Create(bits, 1);
    if (X == NULL) FATAL_ERROR("Create", ErrCode_Null);

    err = BitVector_from_Bin(X, x);
    PrintErrorMessage(err,"from_Bin");

    Y = BitVector_Create(bits, 1);
    if (Y == NULL) FATAL_ERROR("Create", ErrCode_Null);

    err = BitVector_from_Bin(Y, y);
    PrintErrorMessage(err,"from_Bin");

    Z = BitVector_Create(bits, 1);
    if (Z == NULL) FATAL_ERROR("Create", ErrCode_Null);

    ovrflw = BitVector_add(Z, X, Y, &carry);

    printf("result of %s + %s is %s (carry = %d, overflow = %d)\n",
        BitVector_to_Dec(X),
        BitVector_to_Dec(Y),  /* Beware the memory leaks here! */
        BitVector_to_Dec(Z),  /* (Call "BitVector_Dispose()"!) */
        carry, ovrflw);

    err = BitVector_Multiply(Z, X, Y);

    printf("result of %s * %s is %s\n",
        BitVector_to_Dec(X),
        BitVector_to_Dec(Y),  /* Beware the memory leaks here! */
        BitVector_to_Dec(Z)); /* (Call "BitVector_Dispose()"!) */

    PrintErrorMessage(err,"Multiply");

    return(0);
}

