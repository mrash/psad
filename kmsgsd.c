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
*  Copyright (C) 1999-2007 Michael Rash (mbr@cipherdyne.org)
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
*/

/* includes */
#include "psad.h"
#include <getopt.h>

/* defines */
#define CONFIG_FILE "/etc/psad/psad.conf"

/* Maximum number of overwrite files allowed on the command line */
#define MAX_OVW_FILES   3

/* globals */
static volatile sig_atomic_t received_sighup = 0;
extern char *optarg; /* for getopt */
extern int   optind; /* for getopt */
char *fw_msg_search[MAX_GEN_LEN];
char psadfifo_file[MAX_PATH_LEN];
char fwdata_file[MAX_PATH_LEN];
char fw_search_file[MAX_PATH_LEN];
char snort_sid_str[MAX_PATH_LEN];
char install_root[MAX_PATH_LEN];
char psad_dir[MAX_PATH_LEN];
char psad_fifo_dir[MAX_PATH_LEN];
char psad_run_dir[MAX_PATH_LEN];
char kmsgsd_pid_file[MAX_PATH_LEN];
int num_fw_search_strings;
int fw_search_all_flag;
unsigned char dump_cfg;

/* prototypes */
static void usage(void);
static void clean_settings(void);
static void parse_config(char *file);
static void check_config(void);
static void dump_config(void);
static int match_fw_msg(char *fw_mgs);
static void find_sub_var_value(
    char *value,
    char *sub_var,
    char *pre_str,
    char *post_str
);

static void expand_config_vars(void);
static void sighup_handler(int sig);

/* main */
int main(int argc, char *argv[]) {

    char **ovw_file_ptr;
    char  *overwrite_files[MAX_OVW_FILES+1];
    char   overwrite_cmd[MAX_PATH_LEN];
    char   config_file[MAX_PATH_LEN];
    char   buf[MAX_LINE_BUF];
    int    fifo_fd, fwdata_fd;  /* file descriptors */
    int    cmdlopt, numbytes;
#ifdef DEBUG
    int    matched_ipt_log_msg = 0;
    int    fwlinectr = 0;
#endif

#ifdef DEBUG
    fprintf(stderr, "[+] Entering DEBUG mode\n");
    fprintf(stderr, "[+] Firewall messages will be written to both ");
    fprintf(stderr, "STDOUT _and_ to fwdata.\n\n");
#endif

    overwrite_files[0] = NULL;
    strlcpy(config_file, CONFIG_FILE, MAX_PATH_LEN);
    dump_cfg = 0;

    while((cmdlopt = getopt(argc, argv, "c:O:Dh")) != -1) {
        switch(cmdlopt) {
            case 'c':
                strlcpy(config_file, optarg, MAX_PATH_LEN);
                break;
            case 'O':
                strlcpy(overwrite_cmd, optarg, MAX_PATH_LEN);
                list_to_array(overwrite_cmd, ',', overwrite_files, MAX_OVW_FILES);
                break;
            case 'D':
                dump_cfg = 1;
                break;
            default:
                usage();
        }
    }

    /* clean our settings */
    clean_settings();

    /* Parse both the overwrite and configuration file */
    for (ovw_file_ptr=overwrite_files; *ovw_file_ptr!=NULL; ovw_file_ptr++)
        parse_config(*ovw_file_ptr);
    parse_config(config_file);

    /* Check our settings */
    check_config();

    if (dump_cfg == 1)
        dump_config();

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
     * Also, note that we are opening with O_RDWR, since this seems to
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

            /* clean our settings */
            clean_settings();

            /* reparse the config file since we received a HUP signal */
            for (ovw_file_ptr=overwrite_files; *ovw_file_ptr!=NULL; ovw_file_ptr++)
                parse_config(*ovw_file_ptr);
            parse_config(config_file);

            check_config();

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
            slogr("psad(kmsgsd)", "received HUP signal");
        }

        /* see if we matched a firewall message and write it to the
         * fwdata file */
        if ((strstr(buf, "OUT=") != NULL
                && strstr(buf, "IN=") != NULL)) {
            if (! fw_search_all_flag) {
                /* we are looking for specific log prefixes */
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
                fprintf(stderr, "[-] Line did not match search strings.\n");
            }
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

static void parse_config(char * file)
{
    FILE *config_ptr;   /* FILE pointer to the config file */
    int linectr = 0, i;
    char config_buf[MAX_LINE_BUF];
    char tmp_fw_search_buf[MAX_GEN_LEN], *index;

    for (i=0; i < num_fw_search_strings; i++)
        if (fw_msg_search[i] != NULL)
            free(fw_msg_search[i]);

    num_fw_search_strings = 0;
    fw_msg_search[num_fw_search_strings] = NULL;

#ifdef DEBUG
    fprintf(stderr, "[+] Parsing file %s\n", file);
#endif

    if ((config_ptr = fopen(file, "r")) == NULL) {
        perror("[*] Could not open config file");
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

            find_char_var("INSTALL_ROOT", install_root, index);
            find_char_var("PSAD_DIR", psad_dir, index);
            find_char_var("PSAD_FIFO_DIR", psad_fifo_dir, index);
            find_char_var("PSAD_RUN_DIR", psad_run_dir, index);
            find_char_var("SNORT_SID_STR", snort_sid_str, index);
            find_char_var("PSAD_FIFO_FILE", psadfifo_file, index);
            find_char_var("FW_DATA_FILE", fwdata_file, index);
            find_char_var("KMSGSD_PID_FILE", kmsgsd_pid_file, index);
            if (find_char_var("FW_MSG_SEARCH", tmp_fw_search_buf, index)) {
                fw_msg_search[num_fw_search_strings]
                    = (char *) safe_malloc(strlen(tmp_fw_search_buf)+1);
                strlcpy(fw_msg_search[num_fw_search_strings],
                    tmp_fw_search_buf, strlen(tmp_fw_search_buf)+1);
                num_fw_search_strings++;
            }
            if (find_char_var("FW_SEARCH_ALL", tmp_fw_search_buf, index)) {
                if (tmp_fw_search_buf[0] == 'N')
                    fw_search_all_flag = 0;
            }
        }
    }
    fclose(config_ptr);

    return;
}

static void expand_config_vars(void)
{
    char sub_var[MAX_GEN_LEN]  = "";
    char pre_str[MAX_GEN_LEN]  = "";
    char post_str[MAX_GEN_LEN] = "";
    int found_sub_var = 1, resolve_ctr = 0;

    while (found_sub_var) {
        resolve_ctr++;
        if (resolve_ctr >= 20) {
            fprintf(stderr, "[*] Exceeded maximum variable resolution attempts.\n");
            exit(EXIT_FAILURE);
        }
        found_sub_var = 0;

        if (has_sub_var("INSTALL_ROOT", install_root, sub_var,
                pre_str, post_str)) {
            find_sub_var_value(install_root, sub_var, pre_str, post_str);
            found_sub_var = 1;
        }

        if (has_sub_var("SNORT_SID_STR", snort_sid_str, sub_var,
                pre_str, post_str)) {
            find_sub_var_value(snort_sid_str, sub_var, pre_str, post_str);
            found_sub_var = 1;
        }

        if (has_sub_var("FW_DATA_FILE", fwdata_file, sub_var,
                pre_str, post_str)) {
            find_sub_var_value(fwdata_file, sub_var, pre_str, post_str);
            found_sub_var = 1;
        }

        if (has_sub_var("PSAD_FIFO_FILE", psadfifo_file, sub_var,
                pre_str, post_str)) {
            find_sub_var_value(psadfifo_file, sub_var, pre_str, post_str);
            found_sub_var = 1;
        }

        if (has_sub_var("KMSGSD_PID_FILE", kmsgsd_pid_file, sub_var,
                pre_str, post_str)) {
            find_sub_var_value(kmsgsd_pid_file, sub_var, pre_str, post_str);
            found_sub_var = 1;
        }
    }
    return;
}

static void find_sub_var_value(char *value, char *sub_var, char *pre_str,
    char *post_str)
{
    int found_var = 0;
    if (strncmp(sub_var, "PSAD_DIR", MAX_GEN_LEN) == 0) {
        strlcpy(sub_var, psad_dir, MAX_GEN_LEN);
        found_var = 1;
    } else if (strncmp(sub_var, "PSAD_FIFO_DIR", MAX_GEN_LEN) == 0) {
        strlcpy(sub_var, psad_fifo_dir, MAX_GEN_LEN);
        found_var = 1;
    } else if (strncmp(sub_var, "INSTALL_ROOT", MAX_GEN_LEN) == 0) {
        strlcpy(sub_var, install_root, MAX_GEN_LEN);
        found_var = 1;
    } else if (strncmp(sub_var, "PSAD_RUN_DIR", MAX_GEN_LEN) == 0) {
        strlcpy(sub_var, psad_run_dir, MAX_GEN_LEN);
        found_var = 1;
    } else if (strncmp(sub_var, "SNORT_SID_STR", MAX_GEN_LEN) == 0) {
        strlcpy(sub_var, snort_sid_str, MAX_GEN_LEN);
        found_var = 1;
    } else if (strncmp(sub_var, "FW_DATA_FILE", MAX_GEN_LEN) == 0) {
        strlcpy(sub_var, fwdata_file, MAX_GEN_LEN);
        found_var = 1;
    } else if (strncmp(sub_var, "PSAD_FIFO_FILE", MAX_GEN_LEN) == 0) {
        strlcpy(sub_var, psadfifo_file, MAX_GEN_LEN);
        found_var = 1;
    } else if (strncmp(sub_var, "KMSGSD_PID_FILE", MAX_GEN_LEN) == 0) {
        strlcpy(sub_var, kmsgsd_pid_file, MAX_GEN_LEN);
        found_var = 1;
    }

    if (found_var) {

        /* substitute the variable value */
        expand_sub_var_value(value, sub_var, pre_str, post_str);

    } else {
        fprintf(stderr, "[*] Could not resolve sub-var: %s to a value.\n",
            sub_var);
        exit(EXIT_FAILURE);
    }
    return;
}

static void dump_config(void)
{
    fprintf(stderr, "[+] dump_config()\n");
    fprintf(stderr, "    INSTALL_ROOT: %s\n", install_root);
    fprintf(stderr, "    PSAD_DIR: %s\n", psad_dir);
    fprintf(stderr, "    PSAD_RUN_DIR: %s\n", psad_run_dir);
    fprintf(stderr, "    PSAD_FIFO_FILE: %s\n", psadfifo_file);
    fprintf(stderr, "    FW_DATA_FILE: %s\n", fwdata_file);
    fprintf(stderr, "    SNORT_SID_STR: %s\n", snort_sid_str);
    fprintf(stderr, "    KMSGSD_PID_FILE: %s\n", kmsgsd_pid_file);

    exit(EXIT_SUCCESS);
}

static void check_config(void)
{
    unsigned char err;

#ifdef DEBUG
    fprintf(stderr, "[+] Checking configuration...\n");
#endif

    err = 1;
    if (psad_dir[0] == '\0')
        fprintf(stderr, "[*] Could not find PSAD_DIR\n");

    else if (install_root[0] == '\0')
        fprintf(stderr, "[*] Could not find INSTALL_ROOT\n");

    else if (psad_run_dir[0] == '\0')
        fprintf(stderr, "[*] Could not find PSAD_RUN_DIR\n");

    else if (psadfifo_file[0] == '\0')
        fprintf(stderr, "[*] Could not find PSAD_FIFO_FILE\n");

    else if (fwdata_file[0] == '\0')
        fprintf(stderr, "[*] Could not find FW_DATA_FILE\n");

    else if (snort_sid_str[0] == '\0')
        fprintf(stderr, "[*] Could not find SNORT_SID_STR\n");

    else if (kmsgsd_pid_file[0] == '\0')
        fprintf(stderr, "[*] Could not find KMSGSD_PID_FILE\n");

    /* Resolve any embedded variables */
    else {
        expand_config_vars();

        /* there are no FW_MSG_SEARCH vars in fw_search.conf; default
         * to "DROP".  Psad will generate a syslog warning.  */
        if (! fw_search_all_flag && num_fw_search_strings == 0) {
            fw_msg_search[num_fw_search_strings]
                = (char *) safe_malloc(strlen("DROP")+1);
            strlcpy(fw_msg_search[0], "DROP", strlen("DROP")+1);
            num_fw_search_strings++;
        }

        err = 0;
    }

    if (err == 1)
        exit(EXIT_FAILURE);
}

static void clean_settings (void)
{

#ifdef DEBUG
    fprintf(stderr, "[+] Cleaning settings\n");
#endif

    /* default to parse all iptables messages */
    num_fw_search_strings = 0;
    fw_search_all_flag    = 1;

    *psad_dir        = '\0';
    *psad_fifo_dir   = '\0';
    *install_root    = '\0';
    *psad_run_dir    = '\0';
    *psadfifo_file   = '\0';
    *fwdata_file     = '\0';
    *snort_sid_str   = '\0';
    *kmsgsd_pid_file = '\0';
}


static void sighup_handler(int sig)
{
    received_sighup = 1;
}

/*
 * Usage message to be displayed when -h option is supplied or a bad option
 * is passed to the daemon. This function ends the execution of the program.
 */
static void usage (void)
{
    fprintf(stderr,
"kmsgsd - separates iptables messages from all other kernel messages\n\n");

    fprintf(stderr, "[+] Version: %s\n", PSAD_VERSION);
    fprintf(stderr,
"    By Michael Rash (mbr@cipherdyne.org)\n"
"    URL: http://www.cipherdyne.org/psad/\n\n");

    fprintf(stderr, "Usage: kmsgsd [options]\n\n");

    fprintf(stderr,
"Options:\n"
"    -c <file>          - Specify path to config file instead of using the\n"
"                         default $config_file.\n"
"    -D                 - Dump  the  configuration values that psad\n"
"                         derives from the /etc/psad/psad.conf (or other\n"
"                         override files) on STDERR\n"
"    -h                 - Display this usage message and exit\n"
"    -O <file>          - Override config variable values that are normally\n"
"                         read from the /etc/psad/psad.conf file with\n"
"                         values from the specified file\n");

    exit(EXIT_FAILURE);
}
