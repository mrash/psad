/*
********************************************************************************
*
*  File: psad.h
*
*  Author: Michael Rash (mbr@cipherdyne.org)
*
*  Purpose: psad.h include appropriate system header files, and defines file
*           paths, function prototypes, and constants that are needed by
*           the C versions of psad.
*
*  Credits:  (see the CREDITS file)
*
*  Version: 1.3.2
*
*  Copyright (C) 1999-2002 Michael Rash (mbr@cipherdyne.org)
*
*  License (GNU Public License):
*
*     This program is distributed in the hope that it will be useful,
*     but WITHOUT ANY WARRANTY; without even the implied warranty of
*     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*     GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
*     USA
*
********************************************************************************
*
*  $Id$
*/

#ifndef __PSAD_H__
#define __PSAD_H__

/* INCLUDES *******************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>    /* read(), write(), and close() */
#include <fcntl.h>     /* open() */
#include <sys/stat.h>  /* umask */
#include <sys/wait.h>
#include <sys/types.h>
#include <signal.h>
#include <syslog.h>

/* DEFINES ********************************************************************/
#define MAX_LINE_BUF 1024
#define MAX_PID_SIZE 6
#define MAX_PATH_LEN 100
#define MAX_MSG_LEN 120
#define MAX_GEN_LEN 80
#define MAX_ARG_LEN 30
#define MAX_NUM_LEN 6

/* PROTOTYPES *****************************************************************/
void slogr(const char *, const char *);
void check_unique_pid(const char *, const char *);
void write_pid(const char *, pid_t);
void daemonize_process(const char *);
void send_alert_email(const char *, const char *, const char *);
int find_char_var(char *, char *, char *);
int check_import_config(time_t *config_mtime, char *config_file);

/* From OpenBSD */
size_t strlcpy(char *, const char *, size_t);
size_t strlcat(char *, const char *, size_t);

#endif  /* __PSAD_H__ */
