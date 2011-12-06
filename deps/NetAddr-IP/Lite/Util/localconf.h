/*
 *	localconf.h
 *
 */

#include "config.h"

#ifdef WORDS_BIGENDIAN
#define host_is_BIG_ENDIAN 1
#else
#define host_is_LITTLE_ENDIAN 1
#endif

#include <stdio.h>
#ifdef HAVE_SYS_TYPES_H
# include <sys/types.h>
#endif
#ifdef HAVE_SYS_STAT_H
# include <sys/stat.h>
#endif
#ifdef STDC_HEADERS
# include <stdlib.h>
# include <stddef.h>
#else
# ifdef HAVE_STDLIB_H
#  include <stdlib.h>
# endif
#endif
#ifdef HAVE_STRING_H
# if !defined STDC_HEADERS && defined HAVE_MEMORY_H
#  include <memory.h>
# endif
# include <string.h>
#endif
#ifdef HAVE_STRINGS_H
# include <strings.h>
#endif
#ifdef HAVE_INTTYPES_H
# include <inttypes.h>
#endif
#ifdef HAVE_STDINT_H
# include <stdint.h>
#endif
#ifdef HAVE_UNISTD_H
# include <unistd.h>
#endif

#ifdef HAVE_SYS_SOCKET_H
# include <sys/socket.h>
#endif
#ifdef HAVE_NET_INET_H
# include <netinet/in.h>
#endif
#ifdef HAVE_ARPA_INET_H
# include <arpa/inet.h>
#endif
#ifdef HAVE_NETDB_H
# include <netdb.h>
#endif

#if SIZEOF_U_INT8_T == 0
#undef SIZEOF_U_INT8_T
#define SIZEOF_U_INT8_T SIZEOF_UINT8_T
typedef uint8_t u_int8_t;
#endif

#if SIZEOF_U_INT16_T == 0
#undef SIZEOF_U_INT16_T
#define SIZEOF_U_INT16_T SIZEOF_UINT16_T
typedef uint16_t u_int16_t;
#endif

#if SIZEOF_U_INT32_T == 0
#undef SIZEOF_U_INT32_T
#define SIZEOF_U_INT32_T SIZEOF_UINT32_T
typedef uint32_t u_int32_t;
#endif

#include "localperl.h"

