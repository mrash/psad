/*
*****************************************************************************
*
*  File: psadwatchd.c
*
*  Purpose: psadwatchd checks on an interval of every five seconds to make
*           sure that both kmsgsd and psad are running on the box. If
*           either daemon has died, psadwatchd will restart it and notify
*           each email address in @email_addresses that the daemon has been
*           restarted.
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
*     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
*     GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
*     USA
*
*****************************************************************************
*/

/* includes */
#include "psad.h"

/* defines */
#define CONFIG_FILE "/etc/psad/psad.conf" /* only used for DATA_INPUT_METHOD */

/* Maximum number of overwrite files allowed on the command line */
#define MAX_OVW_FILES   3

/* globals */
short int psad_syscalls_ctr     = 0;
short int kmsgsd_syscalls_ctr   = 0;
unsigned short int no_email     = 0;
unsigned short int check_kmsgsd;
const char mail_redr[] = " < /dev/null > /dev/null 2>&1";
char hostname[MAX_GEN_LEN];
char mail_addrs[MAX_EMAIL_LEN];
char shCmd[MAX_GEN_LEN];
char mailCmd[MAX_GEN_LEN];
char alerting_methods[MAX_GEN_LEN];
char psadCmd[MAX_PATH_LEN];
char install_root[MAX_PATH_LEN];
char psad_pid_file[MAX_PATH_LEN];
char psad_cmdline_file[MAX_PATH_LEN];
char psad_run_dir[MAX_PATH_LEN];
char kmsgsdCmd[MAX_PATH_LEN];
char kmsgsd_pid_file[MAX_PATH_LEN];
char psadwatchd_pid_file[MAX_PATH_LEN];
char data_input_mode[MAX_GEN_LEN];
char enable_syslog_file[MAX_GEN_LEN];
char char_psadwatchd_check_interval[MAX_NUM_LEN];
char char_psadwatchd_max_retries[MAX_NUM_LEN];
unsigned int psadwatchd_check_interval;
unsigned int psadwatchd_max_retries;
static volatile sig_atomic_t received_sighup = 0;
unsigned char dump_cfg;

/* prototypes */
static void usage(void);
static void clean_settings(void);
static void parse_config(char *file);
static void check_config(void);
static void dump_config(void);
static unsigned short int is_kmsgsd_required(void);

static void expand_config_vars(void);
static void find_sub_var_value(
    char *value,
    char *sub_var,
    char *pre_str,
    char *post_str
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

    int    cmdlopt;
    char **ovw_file_ptr;
    char  *overwrite_files[MAX_OVW_FILES+1];
    char   overwrite_cmd[MAX_PATH_LEN];
    char   config_file[MAX_PATH_LEN];

#ifdef DEBUG
    fprintf(stderr, "[+] Entering DEBUG mode\n");
    sleep(1);
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

    /* see if we are suppose to disable all email alerts */
    if (strncmp("noemail", alerting_methods, MAX_GEN_LEN) == 0)
        no_email = 1;

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

        if (check_kmsgsd)
            check_process("kmsgsd", kmsgsd_pid_file, NULL,
                kmsgsdCmd, psadwatchd_max_retries);

        /* sleep and then check to see if we received any signals */
        sleep(psadwatchd_check_interval);

        /* check for sighup */
        if (received_sighup) {

            slogr("psad(psadwatchd)", "received HUP signal");
            received_sighup = 0;

            /* clean our settings */
            clean_settings();

            /* reparse the config file since we received a HUP signal */
            for (ovw_file_ptr=overwrite_files; *ovw_file_ptr!=NULL; ovw_file_ptr++)
                parse_config(*ovw_file_ptr);
            parse_config(config_file);

            check_config();
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
    char syslog_str[MAX_MSG_LEN] = "";
    char pid_line[MAX_PID_SIZE];

    if ((pidfile_ptr = fopen(pid_file, "r")) == NULL) {
#ifdef DEBUG
    fprintf(stderr, "[-] Could not open pid file: %s\n", pid_file);
#endif
        snprintf(syslog_str, MAX_MSG_LEN,
                "could not open pid file: %s on %s", pid_file, hostname);
        slogr("psad(psadwatchd)", syslog_str);
        /* the pid file must not exist (or we can't read it), so
         * setup to start the appropriate process */
        restart = 1;
    }

    /* read the first line of the pid_file, which will contain the
     * process id of any running pid_name process. */
    if (! restart) {
        if (fgets(pid_line, MAX_PID_SIZE, pidfile_ptr) == NULL) {
#ifdef DEBUG
            fprintf(stderr, "[-] Could not read the pid file: %s\n",
                pid_file);
#endif
            fclose(pidfile_ptr);

            snprintf(syslog_str, MAX_MSG_LEN,
                "could not read pid file: %s on %s", pid_file, hostname);
            slogr("psad(psadwatchd)", syslog_str);

            /* see if we need to give up */
            incr_syscall_ctr(pid_name, max_retries);

            return;
        }

        /* close the pid_file now that we have read it */
        fclose(pidfile_ptr);

        if (pid_line[strlen(pid_line)] == '\n')
            pid_line[strlen(pid_line)] = '\0';

        /* convert the pid_line into an integer */
        pid = atoi(pid_line);

        if (kill(pid, 0) != 0) {
            /* the process is not running so start it */
            restart = 1;
        }
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

        snprintf(syslog_str, MAX_MSG_LEN,
            "restarting %s on %s", pid_name, hostname);
        slogr("psad(psadwatchd)", syslog_str);

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
            "[-] %s not running. Trying to restart (%d tries so far).\n",
            pid_name, psad_syscalls_ctr);
#endif
        if (psad_syscalls_ctr >= max_retries)
            give_up(pid_name);
    } else if (strncmp("kmsgsd", pid_name, MAX_PATH_LEN) == 0) {
        kmsgsd_syscalls_ctr++;
#ifdef DEBUG
        fprintf(stderr,
            "[-] %s not running. Trying to restart (%d tries so far).\n",
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
    fprintf(stderr, "[*] Could not restart %s process. Exiting.\n", pid_name);
#endif
    strlcat(mail_str, " -s \"[*] psadwatchd: Could not restart ", MAX_MSG_LEN);
    strlcat(mail_str, pid_name, MAX_MSG_LEN);
    strlcat(mail_str, " on ", MAX_MSG_LEN);
    strlcat(mail_str, hostname, MAX_MSG_LEN);
    strlcat(mail_str, ". Exiting.\" ", MAX_MSG_LEN);
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

    prog_argv[arg_num] = (char *) safe_malloc(strlen(binary)+1);

    strlcpy(prog_argv[arg_num], binary, strlen(binary)+1);
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

            if (arg_num >= MAX_ARG_LEN)
                exit(EXIT_FAILURE);

            prog_argv[arg_num] = (char *) safe_malloc(non_ws+1);

            for (i=0; i<non_ws; i++)
                prog_argv[arg_num][i] = *(index - (non_ws - i));
            prog_argv[arg_num][i] = '\0';

            arg_num++;

            /* get past any whitespace */
            while (*index == ' ' || *index == '\t') index++;
        }
    }

    if (arg_num >= MAX_ARG_LEN)
        exit(EXIT_FAILURE);
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

static void parse_config(char * file)
{
    FILE *config_ptr;         /* FILE pointer to the config file */
    int linectr = 0;
    char config_buf[MAX_LINE_BUF];
    char *index;
    int tmp;

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
        index = config_buf;  /* set the index pointer to the
                                beginning of the line */

        /* advance the index pointer through any whitespace
         * at the beginning of the line */
        while (*index == ' ' || *index == '\t') index++;

        /* skip comments and blank lines, etc. */
        if ((*index != '#') && (*index != '\n') &&
                (*index != ';') && (index != NULL)) {

            find_char_var("HOSTNAME", hostname, index);
            find_char_var("INSTALL_ROOT", install_root, index);
            find_char_var("PSAD_RUN_DIR", psad_run_dir, index);
            find_char_var("PSAD_PID_FILE", psad_pid_file, index);
            find_char_var("PSAD_CMDLINE_FILE", psad_cmdline_file, index);
            find_char_var("ALERTING_METHODS", alerting_methods, index);
            find_char_var("KMSGSD_PID_FILE", kmsgsd_pid_file, index);
            find_char_var("PSADWATCHD_PID_FILE", psadwatchd_pid_file, index);
            find_char_var("PSADWATCHD_CHECK_INTERVAL",
                char_psadwatchd_check_interval, index);
            find_char_var("PSADWATCHD_MAX_RETRIES",
                char_psadwatchd_max_retries, index);
            find_char_var("SYSLOG_DAEMON", data_input_mode, index);
            find_char_var("ENABLE_SYSLOG_FILE", enable_syslog_file, index);
            find_char_var("EMAIL_ADDRESSES", mail_addrs, index);

            /* commands */
            find_char_var("kmsgsdCmd", kmsgsdCmd, index);
            find_char_var("mailCmd", mailCmd, index);
            find_char_var("shCmd", shCmd, index);
            find_char_var("psadCmd", psadCmd, index);
        }
    }
    fclose(config_ptr);

    tmp = atoi(char_psadwatchd_check_interval);
    if (tmp != 0)
        psadwatchd_check_interval = tmp;

    tmp = atoi(char_psadwatchd_max_retries);
    if (tmp != 0)
        psadwatchd_max_retries = tmp;

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
        if (has_sub_var("EMAIL_ADDRESSES", mail_addrs, sub_var,
                pre_str, post_str)) {
            find_sub_var_value(mail_addrs, sub_var, pre_str, post_str);
            found_sub_var = 1;
        }

        if (has_sub_var("HOSTNAME", hostname, sub_var,
                pre_str, post_str)) {
            find_sub_var_value(hostname, sub_var, pre_str, post_str);
            found_sub_var = 1;
        }

        if (has_sub_var("PSAD_RUN_DIR", psad_run_dir, sub_var,
                pre_str, post_str)) {
            find_sub_var_value(psad_run_dir, sub_var, pre_str, post_str);
            found_sub_var = 1;
        }

        if (has_sub_var("INSTALL_ROOT", install_root, sub_var,
                pre_str, post_str)) {
            find_sub_var_value(install_root, sub_var, pre_str, post_str);
            found_sub_var = 1;
        }

        if (has_sub_var("PSAD_PID_FILE", psad_pid_file, sub_var,
                pre_str, post_str)) {
            find_sub_var_value(psad_pid_file, sub_var, pre_str, post_str);
            found_sub_var = 1;
        }

        if (has_sub_var("PSAD_CMDLINE_FILE", psad_cmdline_file, sub_var,
                pre_str, post_str)) {
            find_sub_var_value(psad_cmdline_file, sub_var, pre_str, post_str);
            found_sub_var = 1;
        }

        if (has_sub_var("KMSGSD_PID_FILE", kmsgsd_pid_file, sub_var,
                pre_str, post_str)) {
            find_sub_var_value(kmsgsd_pid_file, sub_var, pre_str, post_str);
            found_sub_var = 1;
        }

        if (has_sub_var("PSADWATCHD_PID_FILE", psadwatchd_pid_file, sub_var,
                pre_str, post_str)) {
            find_sub_var_value(psadwatchd_pid_file, sub_var, pre_str, post_str);
            found_sub_var = 1;
        }

        if (has_sub_var("PSADWATCHD_CHECK_INTERVAL",
                char_psadwatchd_check_interval, sub_var,
                pre_str, post_str)) {
            find_sub_var_value(char_psadwatchd_check_interval,
                sub_var, pre_str, post_str);
            found_sub_var = 1;
        }

        if (has_sub_var("PSADWATCHD_MAX_RETRIES", char_psadwatchd_max_retries,
                sub_var, pre_str, post_str)) {
            find_sub_var_value(char_psadwatchd_max_retries,
                sub_var, pre_str, post_str);
            found_sub_var = 1;
        }

        if (has_sub_var("mailCmd", mailCmd, sub_var,
                pre_str, post_str)) {
            find_sub_var_value(mailCmd, sub_var, pre_str, post_str);
            found_sub_var = 1;
        }

        if (has_sub_var("shCmd", shCmd, sub_var,
                pre_str, post_str)) {
            find_sub_var_value(shCmd, sub_var, pre_str, post_str);
            found_sub_var = 1;
        }

        if (has_sub_var("kmsgsdCmd", kmsgsdCmd, sub_var,
                pre_str, post_str)) {
            find_sub_var_value(kmsgsdCmd, sub_var, pre_str, post_str);
            found_sub_var = 1;
        }

        if (has_sub_var("psadCmd", psadCmd, sub_var,
                pre_str, post_str)) {
            find_sub_var_value(psadCmd, sub_var, pre_str, post_str);
            found_sub_var = 1;
        }
    }

    return;
}

static void find_sub_var_value(char *value, char *sub_var, char *pre_str,
    char *post_str)
{
    int found_var = 0;
    if (strncmp(sub_var, "EMAIL_ADDRESSES", MAX_GEN_LEN) == 0) {
        strlcpy(sub_var, mail_addrs, MAX_GEN_LEN);
        found_var = 1;
    } else if (strncmp(sub_var, "HOSTNAME", MAX_GEN_LEN) == 0) {
        strlcpy(sub_var, hostname, MAX_GEN_LEN);
        found_var = 1;
    } else if (strncmp(sub_var, "INSTALL_ROOT", MAX_GEN_LEN) == 0) {
        strlcpy(sub_var, install_root, MAX_GEN_LEN);
        found_var = 1;
    } else if (strncmp(sub_var, "PSAD_RUN_DIR", MAX_GEN_LEN) == 0) {
        strlcpy(sub_var, psad_run_dir, MAX_GEN_LEN);
        found_var = 1;
    } else if (strncmp(sub_var, "PSAD_PID_FILE", MAX_GEN_LEN) == 0) {
        strlcpy(sub_var, psad_pid_file, MAX_GEN_LEN);
        found_var = 1;
    } else if (strncmp(sub_var, "PSAD_CMDLINE_FILE", MAX_GEN_LEN) == 0) {
        strlcpy(sub_var, psad_cmdline_file, MAX_GEN_LEN);
        found_var = 1;
    } else if (strncmp(sub_var, "KMSGSD_PID_FILE", MAX_GEN_LEN) == 0) {
        strlcpy(sub_var, kmsgsd_pid_file, MAX_GEN_LEN);
        found_var = 1;
    } else if (strncmp(sub_var, "PSADWATCHD_PID_FILE", MAX_GEN_LEN) == 0) {
        strlcpy(sub_var, psadwatchd_pid_file, MAX_GEN_LEN);
        found_var = 1;
    } else if (strncmp(sub_var, "PSADWATCHD_CHECK_INTERVAL", MAX_GEN_LEN) == 0) {
        strlcpy(sub_var, char_psadwatchd_check_interval, MAX_GEN_LEN);
        found_var = 1;
    } else if (strncmp(sub_var, "PSADWATCHD_MAX_RETRIES", MAX_GEN_LEN) == 0) {
        strlcpy(sub_var, char_psadwatchd_max_retries, MAX_GEN_LEN);
        found_var = 1;
    } else if (strncmp(sub_var, "mailCmd", MAX_GEN_LEN) == 0) {
        strlcpy(sub_var, mailCmd, MAX_GEN_LEN);
        found_var = 1;
    } else if (strncmp(sub_var, "shCmd", MAX_GEN_LEN) == 0) {
        strlcpy(sub_var, shCmd, MAX_GEN_LEN);
        found_var = 1;
    } else if (strncmp(sub_var, "kmsgsdCmd", MAX_GEN_LEN) == 0) {
        strlcpy(sub_var, kmsgsdCmd, MAX_GEN_LEN);
        found_var = 1;
    } else if (strncmp(sub_var, "psadCmd", MAX_GEN_LEN) == 0) {
        strlcpy(sub_var, psadCmd, MAX_GEN_LEN);
        found_var = 1;
    }

    if (found_var)

        /* substitute the variable value */
        expand_sub_var_value(value, sub_var, pre_str, post_str);

    else {
        fprintf(stderr, "[*] Could not resolve sub-var: %s to a value.\n",
            sub_var);
        exit(EXIT_FAILURE);
    }
    return;
}

static void check_config(void)
{
    unsigned char err;

#ifdef DEBUG
    fprintf(stderr, "[+] Checking configuration...\n");
#endif

    err = 1;
    if (psadwatchd_check_interval <= 0)
        fprintf(stderr, "[*] PSADWATCHD_CHECK_INTERVAL must be > 0\n");

    else if (psadwatchd_max_retries <= 0)
        fprintf(stderr, "[*] PSADWATCHD_MAX_RETRIES must be > 0\n");

    else if (mail_addrs[0] == '\0')
        fprintf(stderr, "[*] Could not find EMAIL_ADDRESSES\n");

    else if (hostname[0] == '\0')
        fprintf(stderr, "[*] Could not find HOSTNAME\n");

    else if (psad_run_dir[0] == '\0')
        fprintf(stderr, "[*] Could not find PSAD_RUN_DIR\n");

    else if (install_root[0] == '\0')
        fprintf(stderr, "[*] Could not find INSTALL_ROOT\n");

    else if (psad_pid_file[0] == '\0')
        fprintf(stderr, "[*] Could not find PSAD_PID_FILE\n");

    else if (psad_cmdline_file[0] == '\0')
        fprintf(stderr, "[*] Could not find PSAD_CMDLINE_FILE\n");

    else if (kmsgsd_pid_file[0] == '\0')
        fprintf(stderr, "[*] Could not find KMSGD_PID_FILE\n");

    else if (psadwatchd_pid_file[0] == '\0')
        fprintf(stderr, "[*] Could not find PSADWATCHD_PID_FILE\n");

    else if (mailCmd[0] == '\0')
        fprintf(stderr, "[*] Could not find mailCmd\n");

    else if (shCmd[0] == '\0')
        fprintf(stderr, "[*] Could not find shCmd\n");

    else if (kmsgsdCmd[0] == '\0')
        fprintf(stderr, "[*] Could not find kmsgsdCmd\n");

    else if (psadCmd[0] == '\0')
        fprintf(stderr, "[*] Could not find psadCmd\n");

    else if (alerting_methods[0] == '\0')
        fprintf(stderr, "[*] Could not find ALERTING_METHODS\n");

    else {

        /* Resolve any embedded variables */
        expand_config_vars();

        /* Refresh the need to check kmsgsd */
        check_kmsgsd = is_kmsgsd_required();

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

    /* Set the default values used by psadwatchd when trying to
     * restart the psad and kmsgsd daemons (5s /10 times) */
    psadwatchd_check_interval = 5;
    psadwatchd_max_retries    = 10;

    *mail_addrs             = '\0';
    *hostname               = '\0';
    *install_root           = '\0';
    *psad_run_dir           = '\0';
    *psad_pid_file          = '\0';
    *psad_cmdline_file      = '\0';
    *kmsgsd_pid_file        = '\0';
    *psadwatchd_pid_file    = '\0';
    *mailCmd                = '\0';
    *shCmd                  = '\0';
    *kmsgsdCmd              = '\0';
    *psadCmd                = '\0';
    *alerting_methods       = '\0';
    *data_input_mode        = '\0';
    *enable_syslog_file     = '\0';
}

static void dump_config(void)
{
    fprintf(stderr, "[+] dump_config()\n");
    fprintf(stderr, "    EMAIL_ADDRESSES: %s\n", mail_addrs);
    fprintf(stderr, "    HOSTNAME: %s\n", hostname);
    fprintf(stderr, "    INSTALL_ROOT: %s\n", install_root);
    fprintf(stderr, "    PSAD_RUN_DIR: %s\n", psad_run_dir);
    fprintf(stderr, "    PSAD_PID_FILE: %s\n", psad_pid_file);
    fprintf(stderr, "    PSAD_CMDLINE_FILE: %s\n", psad_cmdline_file);
    fprintf(stderr, "    KMSGSD_PID_FILE: %s\n", kmsgsd_pid_file);
    fprintf(stderr, "    ALERTING_METHODS: %s\n", alerting_methods);
    fprintf(stderr, "    PSADWATCHD_PID_FILE: %s\n", psadwatchd_pid_file);
    fprintf(stderr, "    PSADWATCHD_CHECK_INTERVAL: %u\n",
        psadwatchd_check_interval);
    fprintf(stderr, "    PSADWATCHD_MAX_RETRIES: %u\n",
        psadwatchd_max_retries);
    fprintf(stderr, "    kmsgsdCmd: %s\n", kmsgsdCmd);
    fprintf(stderr, "    mailCmd: %s\n", mailCmd);
    fprintf(stderr, "    shCmd: %s\n", shCmd);
    fprintf(stderr, "    psadCmd: %s\n", psadCmd);

    exit(EXIT_SUCCESS);
}

static void sighup_handler(int sig)
{
    received_sighup = 1;
}

/*
 * Check to see if kmsgsd should not be running:
 *
 *   - first check if we are using the ulog mode
 *   - then, if ENABLE_SYSLOG_FILE is enabled so psad is just parsing
 *     a file written to by syslog directly
 *
 * \return 0 if not required
 *         1 otherwise
 */
static unsigned short int is_kmsgsd_required(void)
{
    unsigned short int required;

    if (strncmp(data_input_mode, "ulogd", MAX_GEN_LEN) == 0)
        required = 0;

    else if (strncmp(enable_syslog_file, "Y", 1) == 0)
        required = 0;

    else
        required = 1;

    return required;
}

/*
 * Usage message to be displayed when -h option is supplied or a bad option
 * is passed to the daemon. This function ends the execution of the program.
 */
static void usage (void)
{
    fprintf(stderr, "psadwatchd - Psad watch daemon\n\n");

    fprintf(stderr, "[+] Version: %s\n", PSAD_VERSION);
    fprintf(stderr,
"    By Michael Rash (mbr@cipherdyne.org)\n"
"    URL: http://www.cipherdyne.org/psad/\n\n");

    fprintf(stderr, "Usage: psadwatchd [options]\n\n");

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
