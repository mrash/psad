/*
*****************************************************************************
*
*  File: psadwatchd.c
*
* Purpose: psadwatchd checks on an interval of every five seconds to make
*          sure that both kmsgsd and psad are running on the box.  If
*          either daemon has died, psadwatchd will restart it notify each
*          email address in @email_addresses that the daemon has been
*          restarted.
*
*  Author: Michael B. Rash (mbr@cipherdyne.com)
*
*  Credits:  (see the CREDITS file)
*
*  Version: 1.0.0
*
*  Copyright (C) 1999-2001 Michael B. Rash (mbr@cipherdyne.com)
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
*****************************************************************************
*
*  $Id$
*/

/* INCLUDES *****************************************************************/
#include "psad.h"

#define DEBUG

/* GLOBALS ******************************************************************/
short int psad_syscalls_ctr     = 0;
short int kmsgsd_syscalls_ctr   = 0;
short int diskmond_syscalls_ctr = 0;

/* PROTOTYPES ***************************************************************/
static void parse_config(const char *config_file);
static void check_process(const char *pid_name, const char *pid_file,
    const char *binary_path);
static void incr_syscall_ctr(const char *pid_name);
static void reset_syscall_ctr(const char *pid_name);
static void give_up(const char *pid_name);

/* MAIN *********************************************************************/
int main(int argc, char *argv[]) {
    const char prog_name[] = "psadwatchd";
    char config_file[MAX_PATH_LEN+1];
    unsigned short int psadwatchd_check_interval = 1;

#ifdef DEBUG
    printf(" ... Entering DEBUG mode ...\n");
    sleep(1);
    printf(" ... parsing config_file: %s\n", config_file);
#endif

    /* first make sure there isn't another kmsgsd already running */
    check_unique_pid(PSADWATCHD_PID_FILE, prog_name);

    /* handle command line arguments */
    if (argc == 1) {  /* nothing but the program name was specified on the command line */
        strcpy(config_file, CONFIG_FILE);
    } else if (argc == 2) {  /* the path to the config file was supplied on the command line */
        strcpy(config_file, argv[1]);
    } else {
        printf(" ... You may only specify the path to a single config file:  ");
        printf("Usage:  psadwatchd <configfile>\n");
        exit(EXIT_FAILURE);
    }

    /* parse the config file for the psadfifo_file, fwdata_file,
     * and fw_msg_search variables */
//    parse_config(config_file, &psadwatchd_check_interval

#ifndef DEBUG
    /* become a daemon */
    daemonize_process(PSADWATCHD_PID_FILE);

    /* write the daemon pid to the pid file */
//    printf("writing pid: %d to KMSGSD_PID_FILE\n", child_pid);
//    write_pid(KMSGSD_PID_FILE, child_pid);
#endif

    /* start doing the real work now that the daemon is running and
     * the config file has been processed */

#ifdef DEBUG
    printf("\n");
#endif

    /* MAIN LOOP: */
    for (;;) {
        check_process("psad", PSAD_PID_FILE, PSAD_BINARY_PATH);
        check_process("diskmond", DISKMOND_PID_FILE, DISKMOND_BINARY_PATH);
        check_process("kmsgsd", KMSGSD_PID_FILE, KMSGSD_BINARY_PATH);
        printf("check_process\n");
        sleep(psadwatchd_check_interval);
    }

    /* these statements don't get executed, but for completeness... */
    exit(EXIT_SUCCESS);
}
/******************** end main ********************/

static void check_process(const char *pid_name, const char *pid_file, const char *binary_path)
{
    FILE *pidfile_ptr;
    pid_t pid;
    char pid_line[MAX_PID_SIZE+1];

    if ((pidfile_ptr = fopen(pid_file, "r")) == NULL) {
        /* the pid file must not exist (or we can't read it), so
         * start the appropriate process and return */
#ifdef DEBUG
    printf(" ... Could not open pid_file: %s\n", pid_file);
#endif
        // system(pid_path);
        return;
    }

    /* read the first line of the pid_file, which will contain the
     * process id of any running pid_name process. */
    if (fgets(pid_line, MAX_PID_SIZE+1, pidfile_ptr) == NULL) {
#ifdef DEBUG
    printf(" ... Could not read the pid_file: %s\n", pid_file);
#endif
        return;
    }

    /* convert the pid_line into an integer */
    pid = atoi(pid_line);

    /* close the pid_file now that we have read it */
    fclose(pidfile_ptr);

    if (kill(pid, 0) != 0) {  /* the process is not running so start it */
        incr_syscall_ctr(pid_name);
        // system(binary_path);
        system("/bin/true");
    } else {
#ifdef DEBUG
        printf(" ... %s is running.\n", pid_name);
#endif
        reset_syscall_ctr(pid_name); /* reset the syscall counter */
    }
    return;
}

static void incr_syscall_ctr(const char *pid_name)
{
    if (strcmp("psad", pid_name) == 0) {
        psad_syscalls_ctr++;
#ifdef DEBUG
        printf(" ... %s not running.  Trying to restart (%d tries so far).\n",
            pid_name, psad_syscalls_ctr);
#endif
        if (psad_syscalls_ctr >= RESTART_LIMIT)
            give_up(pid_name);
    } else if (strcmp("diskmond", pid_name) == 0) {
        diskmond_syscalls_ctr++;
#ifdef DEBUG
        printf(" ... %s not running.  Trying to restart (%d tries so far).\n",
            pid_name, diskmond_syscalls_ctr);
#endif
        if (diskmond_syscalls_ctr >= RESTART_LIMIT)
            give_up(pid_name);
    } else if (strcmp("kmsgsd", pid_name) == 0) {
        kmsgsd_syscalls_ctr++;
#ifdef DEBUG
        printf(" ... %s not running.  Trying to restart (%d tries so far).\n",
            pid_name, kmsgsd_syscalls_ctr);
#endif
        if (kmsgsd_syscalls_ctr >= RESTART_LIMIT)
            give_up(pid_name);
    }
    return;
}

static void reset_syscall_ctr(const char *pid_name)
{
    if (strcmp("psad", pid_name) == 0) {
        kmsgsd_syscalls_ctr = 0;
    } else if (strcmp("diskmond", pid_name) == 0) {
        psad_syscalls_ctr = 0;
    } else if (strcmp("kmsgsd", pid_name) == 0) {
        diskmond_syscalls_ctr = 0;
    }
    return;
}

static void give_up(const char *pid_name)
{
#ifdef DEBUG
    printf(" ... @@@ Could not restart %s process.  Exiting.\n", pid_name);
#endif
    exit(EXIT_FAILURE);
}
#if 0
static void parse_config(char *config_file, char *psadfifo_file, char *fwdata_file, char *fw_msg_search)
{
    FILE *config_ptr;         /* FILE pointer to the config file */
    int linectr = 0;
    char config_buf[MAX_LINE_BUF];
    char *index;

    if ((config_ptr = fopen(config_file, "r")) == NULL) {
        /* fprintf(stderr, " ... @@@ Could not open the config file: %s\n", config_file);  */
        perror(" ... @@@ Could not open config file");
        exit(EXIT_FAILURE);
    }

    /* increment through each line of the config file */
    while ((fgets(config_buf, MAX_LINE_BUF, config_ptr)) != NULL) {
        linectr++;
        index = config_buf;  /* set the index pointer to the beginning of the line */

        /* advance the index pointer through any whitespace at the beginning of the line */
        while (*index == ' ' || *index == '\t') index++;

        /* skip comments and blank lines, etc. */
        if ((*index != '#') && (*index != '\n') && (*index != ';') && (index != NULL)) {

            find_char_var("PSAD_FIFO ", psadfifo_file, index);
            find_char_var("FW_DATA ", fwdata_file, index);
            find_char_var("FW_MSG_SEARCH ", fw_msg_search, index);
        }
    }
    fclose(config_ptr);
    return;
}
#endif
