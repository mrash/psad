/*
********************************************************************************
*
*  File: psad_funcs.c
*
*  Purpose: psad_funcs.c contains several functions that are needed by
*           the all of the psad daemons, so putting these functions in
*           a single file make sense.
*
*  Author: Michael Rash (mbr@cipherdyne.org)
*
*  Credits:  (see the CREDITS file)
*
*  Version: 1.3.1
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

/* includes */
#include "psad.h"

/* shared functions */
void slogr(const char *ident, const char *msg) {
    openlog(ident, LOG_DAEMON, LOG_LOCAL7);
    syslog(LOG_INFO, "%s", msg);
    closelog();
    return;
}

void check_unique_pid(const char *pid_file, const char *prog_name)
{
    FILE *pidfile_ptr;
    pid_t pid;
    char pid_line[MAX_PID_SIZE+1];

#ifdef DEBUG
    fprintf(stderr,
        " .. check_unique_pid(): opening pid file %s\n", pid_file);
#endif

    if ((pidfile_ptr = fopen(pid_file, "r")) == NULL) {
        /* the pid file must not exist (or we can't read it), so
         * return... write_pid() will create it */
        return;
    }

    /* read the first line of the pid_file, which will contain the
     * process id of any running kmsgsd process */
    if (fgets(pid_line, MAX_PID_SIZE+1, pidfile_ptr) == NULL) {
        return;
    }

    /* turn the pid_line into an integer */
    pid = atoi(pid_line);

    /* close the pid_file now that we have read it */
    fclose(pidfile_ptr);

#ifdef DEBUG
    fprintf(stderr,
        " .. check_unique_pid(): checking pid: %d with kill 0\n", pid);
#endif

    if (kill(pid, 0) == 0) {  /* another prog_name is already running */
        fprintf(stderr, " ** %s is already running as pid: %d\n",
            prog_name, pid);
        exit(EXIT_FAILURE);
    } else {
        return;
    }

    return; /* for completness */
}

void write_pid(const char *pid_file, const pid_t pid)
{
    FILE *pidfile_ptr;

    if ((pidfile_ptr = fopen(pid_file, "w")) == NULL) {
        /* could not open the pid file */
        fprintf(stderr, " ** Could not open the pid file: %s", pid_file);
        exit(EXIT_FAILURE);
    }

    /* write the pid to the pid file */
    if (fprintf(pidfile_ptr, "%d\n", pid) == 0) {
        fprintf(stderr, " ** pid: %d could not be written to pid file: %s",
                pid, pid_file);
        exit(EXIT_FAILURE);
    }

    /* the pid_file now that we have read it */
    fclose(pidfile_ptr);

    return;
}

int find_char_var(char *search_str, char *charvar, char *line)
{
    char *index_tmp;
    int char_ctr = 0, i;

    index_tmp = line;

    /* look for specific variables in the config
     * file that match the search_str */

    for (i=0; i < strlen(search_str); i++)
        if (index_tmp[i] != search_str[i])
            return 0;

#ifdef DEBUG
    fprintf(stderr, " .. find_char_var(): found %s in line: %s",
            search_str, line);
#endif

    /* increment the pointer past the variable name */
    while (*index_tmp != ' ') index_tmp++;

    /* increment the pointer past the whitespace
     * before the variable value */
    while (*index_tmp == ' ') index_tmp++;

    /* make sure that the variable has a semicolon
     * at the end of the line */

    /* get the number of characters in the variable
     * before the ending semicolon */
    while (index_tmp[char_ctr] != ';' && index_tmp[char_ctr] != '\0' &&
           index_tmp[char_ctr] != '\n')
        char_ctr++;

    if (index_tmp[char_ctr] != ';') {
        fprintf(stderr,
            " ** find_char_var(): No ending semicolon found for: %s.\n",
            search_str);
        exit(EXIT_FAILURE);
    }

    if (char_ctr > MAX_GEN_LEN-1) {
        fprintf(stderr,
                " ** find_char_var(): the config line for %s is too long.  Exiting.\n",
                search_str);
        exit(EXIT_FAILURE);
    }

    strncpy(charvar, index_tmp, char_ctr);
    charvar[char_ctr] = '\0';  /* replace the ';' with the NULL character */
    return 1;
}

/*
 * Do everything required to cleanly become a daemon: fork(), start
 * a new session, chdir "/", and close un-needed standard filehandles.
 */
void daemonize_process(const char *pid_file)
{
    pid_t child_pid, sid;

    if ((child_pid = fork()) < 0) {
        fprintf(stderr, " ** Could not fork()");
        exit(EXIT_FAILURE);
    }

    if (child_pid > 0) {
#ifdef DEBUG
        fprintf(stderr, " .. writing pid: %d to pid file: %s\n",
                child_pid, pid_file);
#endif
        write_pid(pid_file, child_pid);
        exit(EXIT_SUCCESS);   /* exit the parent process */
    }

    /*
     * Now we are in the child process
     */

    /* start a new session */
    if ((sid = setsid()) < 0) {
        fprintf(stderr, " ** setsid() Could not start a new session");
        exit(EXIT_FAILURE);
    }

    /* make "/" the current directory */
    if ((chdir("/")) < 0) {
        fprintf(stderr, " ** Could not chdir() to /");
        exit(EXIT_FAILURE);
    }

    /* reset the our umask (for completeness) */
    umask(0);

    /* close un-needed file handles */
    close(STDIN_FILENO);
    close(STDOUT_FILENO);
    close(STDERR_FILENO);

    return;
}

void send_alert_email(const char *shCmd, const char *mailCmd,
        const char *mail_str)
{
    char mail_line[MAX_MSG_LEN] = "";
    pid_t child_pid;

    strlcat(mail_line, mailCmd, MAX_MSG_LEN);
    strlcat(mail_line, " ", MAX_MSG_LEN);
    strlcat(mail_line, mail_str, MAX_MSG_LEN);
    if ((child_pid = fork()) < 0)
        /* could not fork */
        exit(EXIT_FAILURE);
    else if (child_pid > 0)
        wait(NULL);  /* mail better work */
    else
        execle(shCmd, shCmd, "-c", mail_line, NULL, NULL);  /* don't use env */
    return;
}
