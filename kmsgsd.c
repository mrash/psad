/*
******************************************************************************
*
*  File: kmsgsd.c
*
*  Purpose: kmsgsd separates iptables messages from all other
*           kernel messages.
*
*  Strategy: read messages from the /var/log/psadfifo named pipe and
*            print any firewall related dop/reject/deny messages to
*            the psad data file "/var/log/psad/fwdata".
*
*  Author: Michael Rash (mbr@cipherdyne.org)
*
*  Credits:  (see the CREDITS file)
*
*  Copyright (C) 1999-2001 Michael Rash (mbr@cipherdyne.org)
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
******************************************************************************
*
*  $Id$
*/

/* includes */
#include "psad.h"
#include <getopt.h>

/* defines */
#define KMSGSD_CONF "/etc/psad/kmsgsd.conf"
#define FW_SEARCH_FILE "/etc/psad/fw_search.conf"

/* globals */
static volatile sig_atomic_t received_sighup = 0;
extern char *optarg; /* for getopt */
extern int   optind; /* for getopt */
char *fw_msg_search[MAX_GEN_LEN];
int num_fw_search_strings = 0;
int fw_search_all_flag = 1;  /* default to parse all iptables messages */

/* prototypes */
static void parse_config(
    char *config_file,
    char *psadfifo_file,
    char *fwdata_file,
    char *snort_sid_str,
    char *kmsgsd_pid_file
);

static void parse_fw_search_file(char *fw_search_file);
static int match_fw_msg(char *fw_mgs);

static void sighup_handler(int sig);

/* main */
int main(int argc, char *argv[]) {
    char psadfifo_file[MAX_PATH_LEN];
    char fwdata_file[MAX_PATH_LEN];
    char config_file[MAX_PATH_LEN];
    char fw_search_file[MAX_PATH_LEN];
    char snort_sid_str[MAX_PATH_LEN];
    char kmsgsd_pid_file[MAX_PATH_LEN];
    char buf[MAX_LINE_BUF];
    int fifo_fd, fwdata_fd;  /* file descriptors */
    int cmdlopt, numbytes;
#ifdef DEBUG
    int matched_ipt_log_msg = 0;
    int fwlinectr = 0;
#endif

#ifdef DEBUG
    fprintf(stderr, "[+] Entering DEBUG mode\n");
    fprintf(stderr, "[+] Firewall messages will be written to both ");
    fprintf(stderr, "STDOUT _and_ to fwdata.\n\n");
#endif

    /* establish default paths to config and fw_search file (may be
     * overriden with command line args below */
    strlcpy(config_file, KMSGSD_CONF, MAX_PATH_LEN);
    strlcpy(fw_search_file, FW_SEARCH_FILE, MAX_PATH_LEN);

    while((cmdlopt = getopt(argc, argv, "c:k:")) != -1) {
        switch(cmdlopt) {
            case 'c':
                strlcpy(config_file, optarg, MAX_PATH_LEN);
                break;
            case 'k':
                strlcpy(fw_search_file, optarg, MAX_PATH_LEN);
                break;
            default:
                printf("[+] Usage:  kmsgsd [-c <config file>] ");
                printf("[-k <fw_search file>]\n");
                exit(EXIT_FAILURE);
        }
    }

#ifdef DEBUG
    fprintf(stderr, "[+] parsing config_file: %s\n", config_file);
#endif
    /* parse config file (kmsgsd.conf) */
    parse_config(config_file, psadfifo_file,
        fwdata_file, snort_sid_str, kmsgsd_pid_file);

    /* parse fw_search.conf file */
    parse_fw_search_file(fw_search_file);

    /* make sure there isn't another kmsgsd already running */
    check_unique_pid(kmsgsd_pid_file, "kmsgsd");

#ifndef DEBUG
    /* become a daemon */
    daemonize_process(kmsgsd_pid_file);
#endif

    /* install signal handler for HUP signals */
    signal(SIGHUP, sighup_handler);

    /* start doing the real work now that the daemon is running and
     * the config file has been processed */

    /* open the psadfifo named pipe.  Note that we are opening the pipe
     * _without_ the O_NONBLOCK flag since we want the read on the file
     * descriptor to block until there is something new in the pipe.
     * Also, not that we are opening with O_RDWR, since this seems to
     * fix the problem with kmsgsd not blocking on the read() if the
     * system logger dies (and hence closes its file descriptor for the
     * psadfifo). */
    if ((fifo_fd = open(psadfifo_file, O_RDWR)) < 0) {
        fprintf(stderr, "[*] Could not open %s for reading.\n",
            psadfifo_file);
        exit(EXIT_FAILURE);  /* could not open psadfifo named pipe */
    }

    /* open the fwdata file in append mode so we can write messages from
     * the pipe into this file. */
    if ((fwdata_fd = open(fwdata_file,
            O_CREAT|O_WRONLY|O_APPEND, 0600)) < 0) {
        fprintf(stderr, "[*] Could not open %s for writing.\n", fwdata_file);
        exit(EXIT_FAILURE);  /* could not open fwdata file */
    }

    /* MAIN LOOP;
     * Read data from the pipe indefinitely (we opened it _without_
     * O_NONBLOCK) and write it to the fwdata file if it is a firewall message
     */
    while ((numbytes = read(fifo_fd, buf, MAX_LINE_BUF-1)) >= 0) {

#ifdef DEBUG
        fprintf(stderr,
            "read %d bytes from %s fifo.\n", numbytes, psadfifo_file);
#endif

        /* make sure the buf contents qualifies as a string */
        buf[numbytes] = '\0';

        if (received_sighup) {
            /* clear the signal flag */
            received_sighup = 0;

            /* re-parse the config file after receiving HUP signal */
            parse_config(config_file, psadfifo_file,
                fwdata_file, snort_sid_str, kmsgsd_pid_file);

            /* re-parse the fw_search.conf file */
            parse_fw_search_file(fw_search_file);

            /* close file descriptors and re-open them after
             * re-reading config file */
            close(fifo_fd);
            close(fwdata_fd);

            /* re-open psadfifo and fwdata files */
            if ((fifo_fd = open(psadfifo_file, O_RDWR)) < 0) {
                fprintf(stderr, "[*] Could not open %s for reading.\n",
                    psadfifo_file);
                exit(EXIT_FAILURE);  /* could not open psadfifo named pipe */
            }

            if ((fwdata_fd = open(fwdata_file, O_CREAT|O_WRONLY|O_APPEND,
                    0600)) < 0) {
                fprintf(stderr, "[*] Could not open %s for writing.\n",
                    fwdata_file);
                exit(EXIT_FAILURE);  /* could not open fwdata file */
            }
            slogr("psad(kmsgsd)",
                    "received HUP signal, re-imported kmsgsd.conf");
        }

        /* see if we matched a firewall message and write it to the
         * fwdata file */
        if ((strstr(buf, "OUT") != NULL
                && strstr(buf, "IN") != NULL)) {
            if (! fw_search_all_flag) {  /* we are looking for specific log prefixes */
                if (match_fw_msg(buf) || strstr(buf, snort_sid_str) != NULL) {
                    if (write(fwdata_fd, buf, numbytes) < 0) {
                        exit(EXIT_FAILURE);  /* could not write to the fwdata file */
                    }
#ifdef DEBUG
                    matched_ipt_log_msg = 1;
#endif
                }
            } else {
                if (write(fwdata_fd, buf, numbytes) < 0)
                    exit(EXIT_FAILURE);  /* could not write to the fwdata file */
#ifdef DEBUG
                matched_ipt_log_msg = 1;
#endif
            }
#ifdef DEBUG
        if (matched_ipt_log_msg) {
            puts(buf);
            fprintf(stderr, "[+] Line matched search strings.\n");
            fwlinectr++;
            if (fwlinectr % 50 == 0)
                fprintf(stderr,
                    "[+] Processed %d firewall lines.\n", fwlinectr);
            matched_ipt_log_msg = 0;
        } else {
            puts(buf);
            printf("[-] Line did not match search strings.\n");
#endif
        }
    }

    /* these statements don't get executed, but for completeness... */
    close(fifo_fd);
    close(fwdata_fd);

    exit(EXIT_SUCCESS);
}
/******************** end main ********************/

static int match_fw_msg(char *fw_msg)
{
    int i;
    for (i=0; i < num_fw_search_strings; i++)
        if (strstr(fw_msg, fw_msg_search[i]) != NULL)
            return 1;
    return 0;
}

static void parse_config(char *config_file, char *psadfifo_file,
    char *fwdata_file, char *snort_sid_str,
    char *kmsgsd_pid_file)
{
    FILE *config_ptr;   /* FILE pointer to the config file */
    int linectr = 0;
    char config_buf[MAX_LINE_BUF];
    char *index;

    if ((config_ptr = fopen(config_file, "r")) == NULL) {
        fprintf(stderr, "[*] Could not open %s for reading.\n",
            config_file);
        exit(EXIT_FAILURE);
    }

    /* increment through each line of the config file */
    while ((fgets(config_buf, MAX_LINE_BUF, config_ptr)) != NULL) {
        linectr++;
        /* set the index pointer to the beginning of the line */
        index = config_buf;

        /* advance the index pointer through any whitespace
         * at the beginning of the line */
        while (*index == ' ' || *index == '\t') index++;

        /* skip comments and blank lines, etc. */
        if ((*index != '#') && (*index != '\n') &&
                (*index != ';') && (index != NULL)) {

            find_char_var("PSAD_FIFO ", psadfifo_file, index);
            find_char_var("FW_DATA_FILE ", fwdata_file, index);
            find_char_var("SNORT_SID_STR ", snort_sid_str, index);
            find_char_var("KMSGSD_PID_FILE ", kmsgsd_pid_file, index);
        }
    }
    fclose(config_ptr);
#ifdef DEBUG
    fprintf(stderr, "[+] PSAD_FIFO: %s\n", psadfifo_file);
    fprintf(stderr, "[+] FW_DATA_FILE: %s\n", fwdata_file);
    fprintf(stderr, "[+] SNORT_SID_STR: %s\n", snort_sid_str);
    fprintf(stderr, "[+] KMSGSD_PID_FILE: %s\n", kmsgsd_pid_file);
#endif
    return;
}

static void parse_fw_search_file(char *fw_search_file)
{
    FILE *fw_search_ptr;
    char fw_search_buf[MAX_LINE_BUF], tmp_fw_search_buf[MAX_GEN_LEN], *index;
    int linectr = 0, i;

    for (i=0; i < num_fw_search_strings; i++)
        free(fw_msg_search[i]);

    num_fw_search_strings = 0;
    fw_msg_search[num_fw_search_strings] = NULL;

    if ((fw_search_ptr = fopen(fw_search_file, "r")) == NULL) {
        fprintf(stderr, "[*] Could not open %s for reading.\n",
            fw_search_file);
        exit(EXIT_FAILURE);
    }

    /* increment through each line of the config file */
    while ((fgets(fw_search_buf, MAX_LINE_BUF, fw_search_ptr)) != NULL) {
        linectr++;
        /* set the index pointer to the beginning of the line */
        index = fw_search_buf;

        /* advance the index pointer through any whitespace
         * at the beginning of the line */
        while (*index == ' ' || *index == '\t') index++;

        /* skip comments and blank lines, etc. */
        if ((*index != '#') && (*index != '\n') &&
                (*index != ';') && (index != NULL)) {

            if (find_char_var("FW_MSG_SEARCH", tmp_fw_search_buf, index)) {
                fw_msg_search[num_fw_search_strings]
                    = (char *) malloc(strlen(tmp_fw_search_buf));
                strlcpy(fw_msg_search[num_fw_search_strings],
                    tmp_fw_search_buf, MAX_GEN_LEN);
                num_fw_search_strings++;
            }
            if (find_char_var("FW_SEARCH_ALL", tmp_fw_search_buf, index)) {
                if (tmp_fw_search_buf[0] == 'N')
                    fw_search_all_flag = 0;
            }
        }
    }
    fclose(fw_search_ptr);
    return;
}

static void sighup_handler(int sig)
{
    received_sighup = 1;
}
