#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <sys/wait.h>

int main(int argc, char *argv[]) {
        char linebuff[512];
        char jname[512];
        char *cmds[128];
        int job_ctr = 0;
        int mode = 0;
        FILE *fp;
        char *fname;
        int waitflag = 0;
        int childstatus;
        int redirectflag = 0;
        int redirectcnt = 0;
        char *freeptr;
        struct jobstr {
                pid_t pid;
                int jid;
                char *jobcmd;
                int valid;
                int bg;
        };
        struct jobstr job_idx[100];
// Argument Check and File parsing for batch and mode set
        if (argc > 2) {
                fprintf(stderr, "Usage: mysh [batchFile]\n");
                fflush(stderr);
                return 1;
        } else if (argc == 2) {
                fname = argv[1];
                fp = fopen(fname, "r");
                mode = 0;
                if (fp == NULL) {
                        fprintf(stderr, "Error: Cannot open file %s\n", fname);
                        fflush(stderr);
                        return 1;
                }
        } else {
                mode = 1;
        }
        // Initialization
        for (int j = 0; j < 100; j++) {
                job_idx[j].valid = 0;
        }

// Iteratilon Starts
        while (1) {
                strcpy(jname, "");
                if (mode == 0) {
                        if (fgets(linebuff, 512, fp) == NULL) {
                                break;
                        } else {
                                fprintf(stdout, "%s", linebuff);
                                fflush(stdout);
                        }
                } else {
                        write(1, "mysh> ", 6);
                        if (fgets(linebuff, 512, stdin) == NULL) break;
                }

                if (linebuff[0] == '\n') continue;
                if (linebuff[strlen(linebuff)-2] == '&') {
                        waitflag = 1;
                        linebuff[strlen(linebuff)-2] = '\0';
                } else {
                        waitflag = 0;
                }

        // Main Code starts
        // EOL added for single command support
                if (linebuff[strlen(linebuff)-1] == '\n')
                        linebuff[strlen(linebuff)-1] = '\0';
                cmds[0] = strtok(linebuff, " ");
                if (cmds[0] == NULL) continue;

                int itr = 0;
                redirectcnt = 0;
                strcat(jname, cmds[0]);
        // Each Command iteration
                while (cmds[itr] != NULL) {
                        if (strcmp(cmds[itr], ">") == 0) redirectcnt++;
                        itr++;
                        cmds[itr] = strtok(NULL, " ");
                        if (cmds[itr] != NULL) {
                                strcat(jname, " ");
                                strcat(jname, cmds[itr]);
                        }
                }
                if (strcmp(cmds[0], "exit") == 0 && cmds[1] == NULL) break;
                if (strcmp(cmds[0], "jobs") == 0) {
                  for (int i = 0; i < 10; i++) {
  if (job_idx[i].valid == 1 && waitpid(job_idx[i].pid, NULL, WNOHANG) == 0) {
      fprintf(stdout, "%i : %s\n", job_idx[i].jid, job_idx[i].jobcmd);
                       fflush(stdout);
                                }
                        }
                        continue;
                }
                if (strcmp(cmds[0], "wait") == 0) {
                int jid;
                jid = atoi(cmds[1]);
                        if (jid > job_ctr || job_idx[jid].bg == 0) {
                                fprintf(stderr, "Invalid JID %d\n", jid);
                                fflush(stderr);
                        } else if (waitpid(job_idx[jid].pid, NULL, WUNTRACED)) {
                                fprintf(stdout, "JID %d terminated\n", jid);
                                fflush(stdout);
                        }
                continue;
                }
                redirectflag = 0;
if (itr > 1) {
  if (redirectcnt > 1 || (redirectcnt == 1 && strcmp(cmds[itr-2], ">"))) {
              continue;
       }
  }
                if (itr > 1 && strcmp(cmds[itr-2], ">") == 0) {
                        redirectflag = 1;
                        cmds[itr-2] = NULL;
                }
        // Forking happening here
                pid_t pid;
                pid = fork();
                job_idx[job_ctr].valid = 1;
                job_idx[job_ctr].bg = waitflag;
                job_idx[job_ctr].pid = pid;
                job_idx[job_ctr].jid = job_ctr;
                freeptr = strdup(jname);
                job_idx[job_ctr].jobcmd = freeptr;
                job_ctr++;
                if (pid < 0) {
                        fprintf(stderr, "fork failed\n");
                        fflush(stderr);
                        exit(1);
                } else if (pid == 0) {
                   if (redirectflag == 1) {
                       close(STDOUT_FILENO);
                       // close(STDERR_FILENO);
                       open(cmds[itr-1], O_CREAT|O_WRONLY|O_TRUNC, S_IRWXU);
                }

                        int cmdstatus;
                        cmdstatus = execvp(cmds[0], cmds);
                   if (cmdstatus == -1) {
                      fprintf(stderr, "%s: Command not found\n", cmds[0]);
                               fflush(stderr);
                               if (waitflag == 0) _exit(1);
                        }
                } else {
                       if (waitflag == 0) waitpid(pid, &childstatus, WUNTRACED);
                }
        }
        if (mode == 0) fclose(fp);
        return 0;
}
