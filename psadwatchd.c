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
*
*****************************************************************************
*
*  $Id$
*/

/* includes */
#include "psad.h"

/* defines */
#define PSADWATCHD_CONF "/etc/psad/psadwatchd.conf"
#define ALERT_CONF "/etc/psad/alert.conf"

/* globals */
short int psad_syscalls_ctr   = 0;
short int kmsgsd_syscalls_ctr = 0;
unsigned short int no_email   = 0;
const char mail_redr[] = " < /dev/null > /dev/null 2>&1";
char hostname[MAX_GEN_LEN];
char mail_addrs[MAX_GEN_LEN];
char shCmd[MAX_GEN_LEN];
char mailCmd[MAX_GEN_LEN];
static volatile sig_atomic_t received_sighup = 0;

/* prototypes */
static void parse_config(
    char *config_file,
    char *hostname,
    char *psad_binary,
    char *psad_pid_file,
    char *psad_cmdline_file,
    char *kmsgsd_binary,
    char *kmsgsd_pid_file,
    char *shCmd,
    char *mailCmd,
    char *mail_addrs,
    char *psadwatchd_pid_file,
    unsigned int *psadwatchd_check_interval,
    unsigned int *psadwatchd_max_retries
);
static void parse_alert_config(
    char *alert_config_file,
    char *alerting_methods
);
static void check_process(
    const char *pid_name,
    const char *pid_file,
    const char *cmdline_file,
    const char *binary_path,
    unsigned int max_retries
);
static void incr_syscall_ctr(const char *pid_name, unsigned int max_retries);
static void reset_syscall_ctr(const char *pid_name);
static void give_up(const char *pid_name);
static void exec_binary(const char *binary_path, const char *cmdline_file);
static void sighup_handler(int sig);

/* main */
int main(int argc, char *argv[]) {
    char config_file[MAX_PATH_LEN];
    char alert_config_file[MAX_PATH_LEN];
    char alerting_methods[MAX_GEN_LEN];
    char psadCmd[MAX_PATH_LEN];
    char psad_pid_file[MAX_PATH_LEN];
    char psad_cmdline_file[MAX_PATH_LEN];
    char kmsgsdCmd[MAX_PATH_LEN];
    char kmsgsd_pid_file[MAX_PATH_LEN];
    char psadwatchd_pid_file[MAX_PATH_LEN];
    unsigned int psadwatchd_check_interval = 5;  /* default to 5 seconds */
    unsigned int psadwatchd_max_retries = 10; /* default to 10 tries */
    int cmdlopt;

#ifdef DEBUG
    fprintf(stderr, "[+] Entering DEBUG mode\n");
    sleep(1);
#endif

    strlcpy(config_file, PSADWATCHD_CONF, MAX_PATH_LEN);
    strlcpy(alert_config_file, ALERT_CONF, MAX_PATH_LEN);

    while((cmdlopt = getopt(argc, argv, "c:k:")) != -1) {
        switch(cmdlopt) {
            case 'c':
                strlcpy(config_file, optarg, MAX_PATH_LEN);
                break;
            case 'a':
                strlcpy(alert_config_file, optarg, MAX_PATH_LEN);
                break;
            default:
                printf("[+] Usage: psadwatchd [-c <config file>] ");
                printf("[-a <alert config file>]\n");
                exit(EXIT_FAILURE);
        }
    }

#ifdef DEBUG
    fprintf(stderr, "[+] parsing config_file: %s\n", config_file);
#endif

    /* parse the config file */
    parse_config(
        config_file,
        hostname,
        psadCmd,
        psad_pid_file,
        psad_cmdline_file,
        kmsgsdCmd,
        kmsgsd_pid_file,
        shCmd,
        mailCmd,
        mail_addrs,
        psadwatchd_pid_file,
        &psadwatchd_check_interval,
        &psadwatchd_max_retries
    );

    parse_alert_config(alert_config_file, alerting_methods);

    /* see if we are suppose to disable all email alerts */
    if (strncmp("noemail", alerting_methods, MAX_GEN_LEN) == 0) {
        no_email = 1;
    }

    /* first make sure there isn't another psadwatchd already running */
    check_unique_pid(psadwatchd_pid_file, "psadwatchd");

#ifndef DEBUG
    /* become a daemon */
    daemonize_process(psadwatchd_pid_file);
#endif

    /* install signal handler for HUP signals */
    signal(SIGHUP, sighup_handler);

    /* start doing the real work now that the daemon is running and
     * the config file has been processed */

    /* MAIN LOOP */
    for (;;) {
        /* restart processes as necessary */
        check_process("psad", psad_pid_file, psad_cmdline_file,
            psadCmd, psadwatchd_max_retries);
        check_process("kmsgsd", kmsgsd_pid_file, NULL,
            kmsgsdCmd, psadwatchd_max_retries);

        /* sleep and then check to see if we received any signals */
        sleep(psadwatchd_check_interval);

        /* check for sighup */
        if (received_sighup) {
            received_sighup = 0;
#ifdef DEBUG
    fprintf(stderr, "[+] re-parsing config file: %s\n", config_file);
#endif
            /* reparse the config file since we received a
             * HUP signal */
            parse_config(
                config_file,
                hostname,
                psadCmd,
                psad_pid_file,
                psad_cmdline_file,
                kmsgsdCmd,
                kmsgsd_pid_file,
                shCmd,
                mailCmd,
                mail_addrs,
                psadwatchd_pid_file,
                &psadwatchd_check_interval,
                &psadwatchd_max_retries
            );
            slogr("psad(psadwatchd)",
                    "received HUP signal, re-imported psadwatchd.conf");
        }
    }

    /* this statement doesn't get executed, but for completeness... */
    exit(EXIT_SUCCESS);
}
/******************** end main ********************/

static void check_process(
    const char *pid_name,
    const char *pid_file,
    const char *cmdline_file,
    const char *binary_path,
    unsigned int max_retries)
{
    FILE *pidfile_ptr;
    pid_t pid;
    unsigned short int restart = 0;
    char mail_str[MAX_MSG_LEN] = "";
    char pid_line[MAX_PID_SIZE];

    if ((pidfile_ptr = fopen(pid_file, "r")) == NULL) {
#ifdef DEBUG
    fprintf(stderr, "[-] Could not open pid_file: %s\n", pid_file);
#endif
        /* the pid file must not exist (or we can't read it), so
         * setup to start the appropriate process */
        restart = 1;
    }


    /* read the first line of the pid_file, which will contain the
     * process id of any running pid_name process. */
    if (fgets(pid_line, MAX_PID_SIZE, pidfile_ptr) == NULL) {
#ifdef DEBUG
    fprintf(stderr, "[-] Could not read the pid_file: %s\n", pid_file);
#endif
        /* see if we need to give up */
        incr_syscall_ctr(pid_name, max_retries);
        fclose(pidfile_ptr);
        return;
    }

    /* convert the pid_line into an integer */
    pid = atoi(pid_line);

    /* close the pid_file now that we have read it */
    fclose(pidfile_ptr);

    if (kill(pid, 0) != 0) {
        /* the process is not running so start it */
        restart = 1;
    }


    if (restart) {
#ifdef DEBUG
        fprintf(stderr, "[+] executing exec_binary(%s)\n", binary_path);
#endif
        //strlcat(mail_str, mailCmd, MAX_MSG_LEN);
        strlcat(mail_str, " -s \"[*] psadwatchd: Restarting ", MAX_MSG_LEN);
        strlcat(mail_str, pid_name, MAX_MSG_LEN);
        strlcat(mail_str, " on ", MAX_MSG_LEN);
        strlcat(mail_str, hostname, MAX_MSG_LEN);
        strlcat(mail_str, "\" ", MAX_MSG_LEN);
        strlcat(mail_str, mail_addrs, MAX_MSG_LEN);
        strlcat(mail_str, mail_redr, MAX_MSG_LEN);

#ifdef DEBUG
        fprintf(stderr, "sending mail:  %s\n", mail_str);
#endif
        if (! no_email) {
            /* send the email */
            send_alert_email(shCmd, mailCmd, mail_str);
        }

        /* execute the binary_path psad daemon */
        exec_binary(binary_path, cmdline_file);

        /* increment the number of times we have tried to restart the binary */
        incr_syscall_ctr(pid_name, max_retries);
    } else {
#ifdef DEBUG
        fprintf(stderr, "[+] %s is running.\n", pid_name);
#endif
        /* reset the syscall counter since the process is successfully
         * running. */
        reset_syscall_ctr(pid_name);
    }
    return;
}

static void incr_syscall_ctr(const char *pid_name, unsigned int max_retries)
{
    if (strncmp("psad", pid_name, MAX_PATH_LEN) == 0) {
        psad_syscalls_ctr++;
#ifdef DEBUG
        fprintf(stderr,
            "[-] %s not running.  Trying to restart (%d tries so far).\n",
            pid_name, psad_syscalls_ctr);
#endif
        if (psad_syscalls_ctr >= max_retries)
            give_up(pid_name);
    } else if (strncmp("kmsgsd", pid_name, MAX_PATH_LEN) == 0) {
        kmsgsd_syscalls_ctr++;
#ifdef DEBUG
        fprintf(stderr,
            "[-] %s not running.  Trying to restart (%d tries so far).\n",
            pid_name, kmsgsd_syscalls_ctr);
#endif
        if (kmsgsd_syscalls_ctr >= max_retries)
            give_up(pid_name);
    }
    return;
}

static void reset_syscall_ctr(const char *pid_name)
{
    if (strncmp("psad", pid_name, MAX_PATH_LEN) == 0) {
        psad_syscalls_ctr = 0;
    } else if (strncmp("kmsgsd", pid_name, MAX_PATH_LEN) == 0) {
        kmsgsd_syscalls_ctr = 0;
    }
    return;
}

static void give_up(const char *pid_name)
{
    char mail_str[MAX_MSG_LEN] = "";
#ifdef DEBUG
    fprintf(stderr, "[*] Could not restart %s process.  Exiting.\n", pid_name);
#endif
    strlcat(mail_str, " -s \"[*] psadwatchd: Could not restart ", MAX_MSG_LEN);
    strlcat(mail_str, pid_name, MAX_MSG_LEN);
    strlcat(mail_str, " on ", MAX_MSG_LEN);
    strlcat(mail_str, hostname, MAX_MSG_LEN);
    strlcat(mail_str, ".  Exiting.\" ", MAX_MSG_LEN);
    strlcat(mail_str, mail_addrs, MAX_MSG_LEN);
    strlcat(mail_str, mail_redr, MAX_MSG_LEN);

    if (! no_email) {
        /* Send the email */
        send_alert_email(shCmd, mailCmd, mail_str);
    }
    exit(EXIT_FAILURE);
}

static void exec_binary(const char *binary, const char *cmdlinefile)
{
    FILE *cmdline_ptr;
    char *prog_argv[MAX_ARG_LEN];
    char cmdline_buf[MAX_LINE_BUF];
    char *index;
    pid_t child_pid;
    int arg_num=0, non_ws, i;

    prog_argv[arg_num] = (char *) malloc(strlen(binary));
    if (prog_argv[arg_num] == NULL) {
        exit(EXIT_FAILURE);
    }
    strlcpy(prog_argv[arg_num], binary, MAX_ARG_LEN);
    arg_num++;

    if (cmdlinefile != NULL) {
        /* restart binary with its command line arguments intact */
        if ((cmdline_ptr = fopen(cmdlinefile, "r")) == NULL) {
            exit(EXIT_FAILURE);
        }
        if ((fgets(cmdline_buf, MAX_LINE_BUF, cmdline_ptr)) == NULL) {
            exit(EXIT_FAILURE);
        }
        fclose(cmdline_ptr);

        /* initialize index to the beginning of the line */
        index = cmdline_buf;

        /* advance the index pointer through any whitespace
         * at the beginning of the line */
        while (*index == ' ' || *index == '\t') index++;

        while (*index != '\n' && *index != '\0') {
            non_ws = 0;
            while (*index != ' ' && *index != '\t'
                    && index != '\0' && *index != '\n') {
                index++;
                non_ws++;
            }
            prog_argv[arg_num] = (char *) malloc(non_ws+1);
            if (prog_argv[arg_num] == NULL) {
                exit(EXIT_FAILURE);
            }
            for (i=0; i<non_ws; i++)
                prog_argv[arg_num][i] = *(index - (non_ws - i));
            prog_argv[arg_num][i] = '\0';

            arg_num++;

            /* get past any whitespace */
            while (*index == ' ' || *index == '\t') index++;
        }
    }
    /* is it necessary to malloc for the ending NULL? */
    prog_argv[arg_num] = (char *) malloc(1);
    if (prog_argv[arg_num] == NULL) {
        exit(EXIT_FAILURE);
    }
    prog_argv[arg_num] = NULL;

    if ((child_pid = fork()) < 0)
        /* could not fork */
        exit(EXIT_FAILURE);
    else if (child_pid > 0) {
        wait(NULL);
        for (i=0; i<=arg_num; i++) {
            free(prog_argv[i]);
        }
    } else {
#ifdef DEBUG
        fprintf(stderr, "[+] restarting %s\n", binary);
#endif
        execve(binary, prog_argv, NULL);  /* don't use environment */
    }
    return;
}

static void parse_config(
    char *config_file,
    char *hostname,
    char *psadCmd,
    char *psad_pid_file,
    char *psad_cmdline_file,
    char *kmsgsdCmd,
    char *kmsgsd_pid_file,
    char *shCmd,
    char *mailCmd,
    char *mail_addrs,
    char *psadwatchd_pid_file,
    unsigned int *psadwatchd_check_interval,
    unsigned int *psadwatchd_max_retries)
{
    FILE *config_ptr;         /* FILE pointer to the config file */
    int linectr = 0;
    char config_buf[MAX_LINE_BUF];
    char char_psadwatchd_check_interval[MAX_NUM_LEN];
    char char_psadwatchd_max_retries[MAX_NUM_LEN];
    char *index;

    if ((config_ptr = fopen(config_file, "r")) == NULL) {
        perror("[*] Could not open config file");
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
            find_char_var("HOSTNAME ", hostname, index);
            find_char_var("PSAD_PID_FILE ", psad_pid_file, index);
            find_char_var("PSAD_CMDLINE_FILE ", psad_cmdline_file, index);
            find_char_var("kmsgsdCmd ", kmsgsdCmd, index);
            find_char_var("KMSGSD_PID_FILE ", kmsgsd_pid_file, index);
            find_char_var("shCmd ", shCmd, index);
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

static void parse_alert_config(
    char *alert_config_file,
    char *alerting_methods)
{
    FILE *config_ptr;         /* FILE pointer to the config file */
    int linectr = 0;
    char config_buf[MAX_LINE_BUF];
    char *index;

    if ((config_ptr = fopen(alert_config_file, "r")) == NULL) {
        perror("[*] Could not open config file");
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

            find_char_var("ALERTING_METHODS ", alerting_methods, index);
        }
    }
    fclose(config_ptr);
    return;
}

static void sighup_handler(int sig)
{
    received_sighup = 1;
}
