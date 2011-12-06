# Process this file with autoconf to produce a configure script.
AC_INIT()
AC_CONFIG_HEADER([config.h])

# Checks for programs.
AC_PROG_CC

# Checks for header files.
AC_HEADER_STDC
AC_CHECK_HEADERS([sys/socket.h netinet/in.h arpa/inet.h netdb.h])

# Checks for typedefs, structures, and compiler characteristics.
AC_C_CONST
AC_TYPE_INT32_T
AC_TYPE_UINT16_T
AC_TYPE_UINT32_T
AC_TYPE_UINT8_T

# Checks for library functions.
AC_PROG_GCC_TRADITIONAL
AH_TEMPLATE([LIBS],[Extra libraries needed for this build])
AH_TEMPLATE([HAVE_LIBNSL],[Define if library library 'nsl' is present])

AH_TEMPLATE([HAVE_GETHOSTBYNAME],[Define to 1 if function 'gethostbyname' is present])
AC_SEARCH_LIBS([gethostbyname],[nsl],[
	AC_DEFINE([HAVE_GETHOSTBYNAME])])

AH_TEMPLATE([HAVE_INET_ATON],[Define to 1 if function 'inet_aton' is present])
AC_SEARCH_LIBS([inet_aton],[socket],[
	AC_DEFINE([HAVE_INET_ATON])])

AH_TEMPLATE([HAVE_INET_PTON],[Define to 1 if function 'inet_pton' is present])
AC_SEARCH_LIBS([inet_pton],[socket],[
	AC_DEFINE([HAVE_INET_PTON])])

AH_TEMPLATE([HAVE_INET_ADDR],[Define to 1 if function 'inet_addr' is present])
AC_SEARCH_LIBS([inet_addr],[socket],[
	AC_DEFINE([HAVE_INET_ADDR])])

AC_C_BIGENDIAN
AC_CHECK_SIZEOF([uint8_t])
AC_CHECK_SIZEOF([uint16_t])
AC_CHECK_SIZEOF([uint32_t])
AC_CHECK_SIZEOF([u_int8_t])
AC_CHECK_SIZEOF([u_int16_t])
AC_CHECK_SIZEOF([u_int32_t])

AC_CONFIG_COMMANDS_PRE([
	if test "$LIBS" != ""; then
	AC_DEFINE_UNQUOTED([LIBS],[$LIBS],[Extra libraries])
	fi
])

AC_OUTPUT
