/*
*****************************************************************************
*
*  File: diskmond.c
*
*  Purpose: diskmond checks the disk partition on which psad scan data
*           lives and will remove the data if the disk utilization goes
*           above a (configurable) threshold (95% by default).
*
*  Author: Michael B. Rash (mbr@cipherdyne.com)
*
*  Credits:  (see the CREDITS file)
*
*  Version: 1.0.0-pre4
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
short int email_ctr = 0;
const char mail_redr[] = " < /dev/null > /dev/null 2>&1";
const char hostname[] = HOSTNAME;
char mail_addrs[MAX_GEN_LEN+1];
char mailCmd[MAX_GEN_LEN+1];

/* PROTOTYPES ***************************************************************/
static void parse_config(
    char *config_file,
    char *mailCmd,
    char *mail_addrs,
    char *diskmond_pid_file,
    unsigned short int *max_disk_percentage,
    unsigned int *diskmond_check_interval,
    unsigned int *diskmond_max_retries
);

/* MAIN *********************************************************************/
int main(int argc, char *argv[]) {
    char config_file[MAX_PATH_LEN+1];
    char diskmond_pid_file[MAX_PATH_LEN+1];
    unsigned short int max_disk_percentage = 95; /* default to 95% utilization */
    unsigned int diskmond_check_interval = 5;  /* default to 5 seconds */
    unsigned int diskmond_max_retries = 10;    /* default to 10 tries */
    time_t config_mtime;
    struct stat statbuf;

#ifdef DEBUG
    printf(" ... Entering DEBUG mode ...\n");
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
        printf(" ... You may only specify the path to a single config file:  ");
        printf("Usage:  psadwatchd <configfile>\n");
        exit(EXIT_FAILURE);
    }

    if (stat(config_file, &statbuf)) {
        printf(" ... @@@ Could not get mtime for config file: %s\n",
            config_file);
        exit(EXIT_FAILURE);
    }

    /* initialize config_mtime */
    config_mtime = statbuf.st_mtime;

#ifdef DEBUG
    printf(" ... parsing config_file: %s\n", config_file);
#endif

    /* parse the config file */
    parse_config(
        config_file,
        mailCmd,
        mail_addrs,
        disdmond_pid_file,
        &max_disk_percentage,
        &diskmond_check_interval,
        &diskmond_max_retries
    );

    /* first make sure there isn't another psadwatchd already running */
    check_unique_pid(psadwatchd_pid_file, "psadwatchd");

#ifndef DEBUG
    /* become a daemon */
    daemonize_process(psadwatchd_pid_file);
#endif

    /* start doing the real work now that the daemon is running and
     * the config file has been processed */

#ifdef DEBUG
    printf("\n");
#endif

    /* MAIN LOOP: */
    for (;;) {
        sleep(psadwatchd_check_interval);

        /* check to see if we need to re-import the config file */
        if (check_import_config(&config_mtime, config_file)) {
#ifdef DEBUG
    printf(" ... re-parsing config file: %s\n", config_file);
#endif
            /* reparse the config file since it was updated */
            parse_config(
                config_file,
                mailCmd,
                mail_addrs,
                diskmond_pid_file,
                &max_disk_percentage,
                &diskmond_check_interval,
                &diskmond_max_retries
            );
        }
    }

    /* this statements don't get executed, but for completeness... */
    exit(EXIT_SUCCESS);
}
/******************** end main ********************/

static void parse_config(
    char *config_file,
    char *mailCmd,
    char *mail_addrs,
    char *diskmond_pid_file,
    unsigned short int *max_disk_percentage,
    unsigned int *diskmond_check_interval,
    unsigned int *diskmond_max_retries)
{
    FILE *config_ptr;         /* FILE pointer to the config file */
    int linectr = 0;
    char config_buf[MAX_LINE_BUF];
    char char_diskmond_check_interval[MAX_NUM_LEN+1];
    char char_diskmond_max_retries[MAX_NUM_LEN+1];
    char *index;

    if ((config_ptr = fopen(config_file, "r")) == NULL) {
        perror(" ... @@@ Could not open config file");
        exit(EXIT_FAILURE);
    }

    /* increment through each line of the config file */
    while ((fgets(config_buf, MAX_LINE_BUF, config_ptr)) != NULL) {
        linectr++;
        index = config_buf;  /* set the index pointer to the
                                beginning of the line */

        /* advance the index pointer through any
         * whitespace at the beginning of the line */
        while (*index == ' ' || *index == '\t') index++;

        /* skip comments and blank lines, etc. */
        if ((*index != '#') && (*index != '\n')
                && (*index != ';') && (index != NULL)) {

            find_char_var("mailCmd ", mailCmd, index);
            find_char_var("EMAIL_ADDRESSES ", mail_addrs, index);
            find_char_var("DISKMOND_PID_FILE ", diskmond_pid_file, index);
            find_char_var("MAX_DISK_PERCENTAGE ",
                char_max_disk_percentage, index);
            find_char_var("DISKMOND_CHECK_INTERVAL ",
                char_diskmond_check_interval, index);
            find_char_var("DISKMOND_MAX_RETRIES ",
                char_diskmond_max_retries, index);
            find_char_var("DISKMOND_PID_FILE ", diskmond_pid_file, index);
        }
    }
    *max_disk_percentage     = atoi(char_max_disk_percentage);
    *diskmond_check_interval = atoi(char_diskmond_check_interval);
    *diskmond_max_retries    = atoi(char_diskmond_max_retries);
    fclose(config_ptr);
    return;
}
