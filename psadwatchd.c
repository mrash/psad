/*
*****************************************************************************
*
*  File: psadwatchd.c
*
*  Purpose: psadwatchd checks on an interval of every five seconds to make
*           sure that both kmsgsd and psad are running on the box.  If
*           either daemon has died, psadwatchd will restart it and notify
*           each email address in @email_addresses that the daemon has been
*           restarted.
*
*  Author: Michael B. Rash (mbr@cipherdyne.com)
*
*  Credits:  (see the CREDITS file)
*
*  Version: 1.0
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

/* GLOBALS ******************************************************************/
short int psad_syscalls_ctr     = 0;
short int kmsgsd_syscalls_ctr   = 0;
short int diskmond_syscalls_ctr = 0;
const char mail_redr[] = " < /dev/null > /dev/null 2>&1";
const char hostname[] = HOSTNAME;
char mail_addrs[MAX_GEN_LEN+1];
char mailCmd[MAX_GEN_LEN+1];

/* PROTOTYPES ***************************************************************/
static void parse_config(
    char *config_file,
    char *psad_binary,
    char *psad_pid_file,
    char *kmsgsd_binary,
    char *kmsgsd_pid_file,
    char *diskmond_binary,
    char *diskmond_pid_file,
    char *mailCmd,
    char *mail_addrs,
    char *psadwatchd_pid_file,
    unsigned int *psadwatchd_check_interval,
    unsigned int *psadwatchd_max_retries
);
static void check_process(
    const char *pid_name,
    const char *pid_file,
    const char *binary_path,
    unsigned int max_retries
);
static void incr_syscall_ctr(const char *pid_name, unsigned int max_retries);
static void reset_syscall_ctr(const char *pid_name);
static void give_up(const char *pid_name);

/* MAIN *********************************************************************/
int main(int argc, char *argv[]) {
    char config_file[MAX_PATH_LEN+1];
    char psadCmd[MAX_PATH_LEN+1];
    char psad_pid_file[MAX_PATH_LEN+1];
    char kmsgsdCmd[MAX_PATH_LEN+1];
    char kmsgsd_pid_file[MAX_PATH_LEN+1];
    char diskmondCmd[MAX_PATH_LEN+1];
    char diskmond_pid_file[MAX_PATH_LEN+1];
    char psadwatchd_pid_file[MAX_PATH_LEN+1];
    unsigned int psadwatchd_check_interval = 5;  /* default to 5 seconds */
    unsigned int psadwatchd_max_retries = 10; /* default to 10 tries */
    time_t config_mtime;
    struct stat statbuf;

#ifdef DEBUG
    printf(" .. Entering DEBUG mode ..n");
    sleep(1);
#endif

    /* handle command line arguments */
    if (argc == 1) {  /* nothing but the program name was
                         specified on the command line */
        strcpy(config_file, CONFIG_FILE);
    } else if (argc == 2) {  /* the path to the config file was
                                supplied on the command line */
        strcpy(config_file, argv[1]);
    } else {
        printf(" .. You may only specify the path to a single config file:  ");
        printf("Usage:  psadwatchd <configfile>\n");
        exit(EXIT_FAILURE);
    }

    if (stat(config_file, &statbuf)) {
        printf(" ** Could not get mtime for config file: %s\n",
            config_file);
        exit(EXIT_FAILURE);
    }

    /* initialize config_mtime */
    config_mtime = statbuf.st_mtime;


#ifdef DEBUG
    printf(" .. parsing config_file: %s\n", config_file);
#endif

    /* parse the config file */
    parse_config(
        config_file,
        psadCmd,
        psad_pid_file,
        kmsgsdCmd,
        kmsgsd_pid_file,
        diskmondCmd,
        diskmond_pid_file,
        mailCmd,
        mail_addrs,
        psadwatchd_pid_file,
        &psadwatchd_check_interval,
        &psadwatchd_max_retries
    );

    /* first make sure there isn't another psadwatchd already running */
    check_unique_pid(psadwatchd_pid_file, "psadwatchd");

#ifndef DEBUG
    /* become a daemon */
    daemonize_process(psadwatchd_pid_file);
#endif

    /* start doing the real work now that the daemon is running and
     * the config file has been processed */

    /* MAIN LOOP: */
    for (;;) {
        check_process("psad", psad_pid_file,
            psadCmd, psadwatchd_max_retries);
        check_process("kmsgsd", kmsgsd_pid_file,
            kmsgsdCmd, psadwatchd_max_retries);
        check_process("diskmond", diskmond_pid_file,
            diskmondCmd, psadwatchd_max_retries);

        /* check to see if we need to re-import the config file */
        if (check_import_config(&config_mtime, config_file)) {
#ifdef DEBUG
    printf(" .. re-parsing config file: %s\n", config_file);
#endif
            /* reparse the config file since it was updated */
            parse_config(
                config_file,
                psadCmd,
                psad_pid_file,
                kmsgsdCmd,
                kmsgsd_pid_file,
                diskmondCmd,
                diskmond_pid_file,
                mailCmd,
                mail_addrs,
                psadwatchd_pid_file,
                &psadwatchd_check_interval,
                &psadwatchd_max_retries
            );
        }

        sleep(psadwatchd_check_interval);
    }

    /* this statement doesn't get executed, but for completeness... */
    exit(EXIT_SUCCESS);
}
/******************** end main ********************/

static void check_process(
    const char *pid_name,
    const char *pid_file,
    const char *binary_path,
    unsigned int max_retries)
{
    FILE *pidfile_ptr;
    pid_t pid;
    char mail_str[MAX_MSG_LEN+1] = "";
    char pid_line[MAX_PID_SIZE+1];

    if ((pidfile_ptr = fopen(pid_file, "r")) == NULL) {
        /* the pid file must not exist (or we can't read it), so
         * start the appropriate process and return */
#ifdef DEBUG
    printf(" .. Could not open pid_file: %s\n", pid_file);
#endif
        strcat(mail_str, mailCmd);
        strcat(mail_str, " -s \" ** psadwatchd: Restarting ");
        strcat(mail_str, pid_name);
        strcat(mail_str, " on ");
        strcat(mail_str, hostname);
        strcat(mail_str, "\" ");
        strcat(mail_str, mail_addrs);
        strcat(mail_str, mail_redr);

#ifdef DEBUG
    printf("sending mail:  %s\n", mail_str);
#endif
        /* send the email */
        system(mail_str);

        /* restart the process */
        system(binary_path);

        /* increment the number of times we have tried to restart the binary */
        incr_syscall_ctr(pid_name, max_retries);
        return;
    }

    /* read the first line of the pid_file, which will contain the
     * process id of any running pid_name process. */
    if (fgets(pid_line, MAX_PID_SIZE+1, pidfile_ptr) == NULL) {
#ifdef DEBUG
    printf(" .. Could not read the pid_file: %s\n", pid_file);
#endif
        return;
    }

    /* convert the pid_line into an integer */
    pid = atoi(pid_line);

    /* close the pid_file now that we have read it */
    fclose(pidfile_ptr);

    if (kill(pid, 0) != 0) {  /* the process is not running so start it */
#ifdef DEBUG
        printf(" .. Executing system(%s)\n", binary_path);
#endif
        strcat(mail_str, mailCmd);
        strcat(mail_str, " -s \" ** psadwatchd: Restarting ");
        strcat(mail_str, pid_name);
        strcat(mail_str, " on ");
        strcat(mail_str, hostname);
        strcat(mail_str, "\" ");
        strcat(mail_str, mail_addrs);
        strcat(mail_str, mail_redr);

#ifdef DEBUG
    printf("sending mail:  %s\n", mail_str);
#endif
        /* send the email */
        system(mail_str);

        /* execute the binary_path psad daemon */
        system(binary_path);

        /* increment the number of times we have tried to restart the binary */
        incr_syscall_ctr(pid_name, max_retries);
    } else {
#ifdef DEBUG
        printf(" .. %s is running.\n", pid_name);
#endif
        reset_syscall_ctr(pid_name); /* reset the syscall counter */
    }
    return;
}

static void incr_syscall_ctr(const char *pid_name, unsigned int max_retries)
{
    if (strcmp("psad", pid_name) == 0) {
        psad_syscalls_ctr++;
#ifdef DEBUG
        printf(" .. %s not running.  Trying to restart (%d tries so far).\n",
            pid_name, psad_syscalls_ctr);
#endif
        if (psad_syscalls_ctr >= max_retries)
            give_up(pid_name);
    } else if (strcmp("diskmond", pid_name) == 0) {
        diskmond_syscalls_ctr++;
#ifdef DEBUG
        printf(" .. %s not running.  Trying to restart (%d tries so far).\n",
            pid_name, diskmond_syscalls_ctr);
#endif
        if (diskmond_syscalls_ctr >= max_retries)
            give_up(pid_name);
    } else if (strcmp("kmsgsd", pid_name) == 0) {
        kmsgsd_syscalls_ctr++;
#ifdef DEBUG
        printf(" .. %s not running.  Trying to restart (%d tries so far).\n",
            pid_name, kmsgsd_syscalls_ctr);
#endif
        if (kmsgsd_syscalls_ctr >= max_retries)
            give_up(pid_name);
    }
    return;
}

static void reset_syscall_ctr(const char *pid_name)
{
    if (strcmp("psad", pid_name) == 0) {
        psad_syscalls_ctr = 0;
    } else if (strcmp("diskmond", pid_name) == 0) {
        diskmond_syscalls_ctr = 0;
    } else if (strcmp("kmsgsd", pid_name) == 0) {
        kmsgsd_syscalls_ctr = 0;
    }
    return;
}

static void give_up(const char *pid_name)
{
    char mail_str[MAX_MSG_LEN+1] = "";
#ifdef DEBUG
    printf(" ** Could not restart %s process.  Exiting.\n", pid_name);
#endif
    strcat(mail_str, mailCmd);
    strcat(mail_str, " -s \"** psadwatchd: Could not restart ");
    strcat(mail_str, pid_name);
    strcat(mail_str, " on ");
    strcat(mail_str, hostname);
    strcat(mail_str, ".  Exiting.\" ");
    strcat(mail_str, mail_addrs);
    strcat(mail_str, mail_redr);

    /* Send the email */
    system(mail_str);
    exit(EXIT_FAILURE);
}

static void parse_config(
    char *config_file,
    char *psadCmd,
    char *psad_pid_file,
    char *kmsgsdCmd,
    char *kmsgsd_pid_file,
    char *diskmondCmd,
    char *diskmond_pid_file,
    char *mailCmd,
    char *mail_addrs,
    char *psadwatchd_pid_file,
    unsigned int *psadwatchd_check_interval,
    unsigned int *psadwatchd_max_retries)
{
    FILE *config_ptr;         /* FILE pointer to the config file */
    int linectr = 0;
    char config_buf[MAX_LINE_BUF];
    char char_psadwatchd_check_interval[MAX_NUM_LEN+1];
    char char_psadwatchd_max_retries[MAX_NUM_LEN+1];
    char *index;

    if ((config_ptr = fopen(config_file, "r")) == NULL) {
        perror(" ** Could not open config file");
        exit(EXIT_FAILURE);
    }

    /* increment through each line of the config file */
    while ((fgets(config_buf, MAX_LINE_BUF, config_ptr)) != NULL) {
        linectr++;
        index = config_buf;  /* set the index pointer to the
                                beginning of the line */

        /* advance the index pointer through any whitespace
         * at the beginning of the line */
        while (*index == ' ' || *index == '\t') index++;

        /* skip comments and blank lines, etc. */
        if ((*index != '#') && (*index != '\n') &&
                (*index != ';') && (index != NULL)) {

            find_char_var("psadCmd ", psadCmd, index);
            find_char_var("PSAD_PID_FILE ", psad_pid_file, index);
            find_char_var("kmsgsdCmd ", kmsgsdCmd, index);
            find_char_var("KMSGSD_PID_FILE ", kmsgsd_pid_file, index);
            find_char_var("diskmondCmd ", diskmondCmd, index);
            find_char_var("DISKMOND_PID_FILE ", diskmond_pid_file, index);
            find_char_var("mailCmd ", mailCmd, index);
            find_char_var("EMAIL_ADDRESSES ", mail_addrs, index);
            find_char_var("PSADWATCHD_CHECK_INTERVAL ",
                char_psadwatchd_check_interval, index);
            find_char_var("PSADWATCHD_MAX_RETRIES ",
                char_psadwatchd_max_retries, index);
            find_char_var("PSADWATCHD_PID_FILE ", psadwatchd_pid_file, index);
        }
    }
    *psadwatchd_check_interval = atoi(char_psadwatchd_check_interval);
    *psadwatchd_max_retries    = atoi(char_psadwatchd_max_retries);
    fclose(config_ptr);
    return;
}
