/**
 **  File: psad.h
 **
 **  Author: Michael B. Rash (mbr@cipherdyne.com)
 **
 **  Credits:  (see the CREDITS file)
 **
 **  Version: 0.9.8
 **
 **  Copyright (C) 1999-2002 Michael B. Rash (mbr@cipherdyne.com)
 **
 **  License (GNU Public License):
 **
 **     This program is distributed in the hope that it will be useful,
 **     but WITHOUT ANY WARRANTY; without even the implied warranty of
 **     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 **     GNU General Public License for more details.
 **
 **     You should have received a copy of the GNU General Public License
 **     along with this program; if not, write to the Free Software
 **     Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
 **     USA
 **
 **  $Id$
 **
 ***********************************************************************************/

#ifndef __PSAD_H__
#define __PSAD_H__

/* INCLUDES ************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>    /* read(), write(), and close() */
#include <fcntl.h>     /* open() */
#include <sys/stat.h>  /* umask */
#include <sys/types.h>
#include <signal.h>

/* DEFINES *************************************************************************/
/* #define DEBUG */
#define MAX_LINE_BUF 1024
#define MAX_PID_SIZE 5
#define MAX_PATH_LEN 50
#define RESTART_LIMIT 5

#define CONFIG_FILE "/etc/psad/psad.conf"                  /* default config file */

#define PSAD_PID_FILE "/home/mbr/src/psad.pid"             /* psad pid file */
#define PSAD_BINARY_PATH "/usr/sbin/psad"

#define PSADWATCHD_PID_FILE "/home/mbr/src/psadwatchd.pid" /* psadwatchd pid file */
#define PSADWATCHD_BINARY_PATH "/usr/sbin/psadwatchd"

#define KMSGSD_PID_FILE "/var/run/kmsgsd.pid"              /* kmsgsd pid file */
#define KMSGSD_BINARY_PATH "/usr/sbin/kmsgsd"

#define DISKMOND_PID_FILE "/home/mbr/src/diskmond.pid"     /* diskmond file */
#define DISKMOND_BINARY_PATH "/usr/sbin/diskmond"

/* PROTOTYPES **********************************************************************/
void check_unique_pid(const char *, const char *);
void write_pid(const char *, pid_t);
void daemonize_process(const char *);
void find_char_var(char *, char *, char *);

#endif  /* __PSAD_H__ */
