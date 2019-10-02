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
        struct jobstr 
        {
                pid_t pid;
                int jid;
                char *jobcmd;
                int valid;
                int bg;
        };
        struct jobstr job_idx[100];
//Argument Check and File parsing for batch and mode set
        if(argc > 2) {
                fprintf(stderr, "Usage: mysh [batchFile]\n");
		fflush(stderr);
                return 1;
        }
        else if (argc == 2) {
                fname = argv[1];
                fp = fopen(fname, "r");
                mode = 0;
                if (fp == NULL) {
                        fprintf(stderr, "Error: Cannot open file %s\n", fname);
			fflush(stderr);
                        return 1;
                }
        }
        else mode = 1;
	
	//Initialization
	for(int j = 0; j < 100; j++) {
		job_idx[j].valid = 0;
	}

//Iteratilon Starts
        while(1) {
		strcpy(jname, "");
                if (mode == 0) {
                        if (fgets(linebuff, 512, fp) == NULL) {
				//fprintf(stdout, "File Reading Done \n");
				//fflush(stdout);
				break;
			}
			else {
				fprintf(stdout, "%s", linebuff);
				fflush(stdout);
			}
                }
                else {
                        write(1, "mysh> ", 6);
                        if (fgets(linebuff, 512, stdin) == NULL) break;
                        //fgets(linebuff,512, stdin);
                }

                if(linebuff[0] == '\n') continue;
                if(linebuff[strlen(linebuff)-2] == '&') {
			waitflag = 1;
			linebuff[strlen(linebuff)-2] = '\0';
		}
                else waitflag = 0;

        // Main Code starts
        //EOL added for single command support 
                if(linebuff[strlen(linebuff)-1] == '\n') linebuff[strlen(linebuff)-1] = '\0';
                cmds[0] = strtok(linebuff, " ");
		if(cmds[0] == NULL) continue;

                /*if(strcmp(cmds[0], "printjobs") == 0) {
                        for(int i = 0; i < 8; i++) {
                                        fprintf(stdout, "First Loop:i index= %i valid=%i PID pending = %i Jid= %ii CurrPID=%i Name:%s\n", i, job_idx[i].valid, job_idx[i].pid, job_idx[i].jid, (int)getpid(), job_idx[i].jobcmd);
                                        fflush(stdout);
                                if(job_idx[i].valid == 1 && waitpid(job_idx[i].pid, NULL, WNOHANG) == 0) {
                                        //fprintf(stdout, "i index= %i valid=%i PID pending = %i Jid= %ii CurrPID=%i \n", i, job_idx[i].valid, job_idx[i].pid, job_idx[i].jid, (int)getpid());
                                        fprintf(stdout, "%i : %s\n",job_idx[i].jid, job_idx[i].jobcmd);
					fflush(stdout);
                                }
                        }
			continue;
                }*/
                
		int itr = 0;
		redirectcnt = 0;
		strcat(jname, cmds[0]);
		//strcat(jname, " ");
        //Each Command iteration
                while(cmds[itr] != NULL) {
                	if(strcmp(cmds[itr], ">") == 0)	redirectcnt++;
                        itr++;
                        cmds[itr] = strtok(NULL, " ");
			if(cmds[itr] != NULL) { 
				strcat(jname, " ");
				strcat(jname, cmds[itr]);
			}
                        //if(!strchr(cmds[itr], EOF)) break;
                }
//		fprintf(stdout, "Jname = %s", jname);
//		fflush(stdout);
                if(strcmp(cmds[0], "exit") == 0 && cmds[1] == NULL) break;
                if(strcmp(cmds[0], "jobs") == 0) {
                        for(int i = 0; i < 10; i++) {
                                        //fprintf(stdout, "First Loop:i index= %i valid=%i PID pending = %i Jid= %ii CurrPID=%i \n", i, job_idx[i].valid, job_idx[i].pid, job_idx[i].jid, (int)getpid());
                                        //fflush(stdout);
                                if(job_idx[i].valid == 1 && waitpid(job_idx[i].pid, NULL, WNOHANG) == 0) {
                                        //fprintf(stdout, "i index= %i valid=%i PID pending = %i Jid= %ii CurrPID=%i \n", i, job_idx[i].valid, job_idx[i].pid, job_idx[i].jid, (int)getpid());
                                        fprintf(stdout, "%i : %s\n",job_idx[i].jid, job_idx[i].jobcmd);
					fflush(stdout);
                                }
                        }
			continue;
                }
		if(strcmp(cmds[0], "wait") == 0) {
		int jid;
		jid = atoi(cmds[1]);
			if(jid > job_ctr || job_idx[jid].bg == 0) {
				fprintf(stderr, "Invalid JID %d\n", jid);
				fflush(stderr);
			}
			else if(waitpid(job_idx[jid].pid, NULL, WUNTRACED)) {
				fprintf(stdout, "JID %d terminated\n", jid);
				fflush(stdout);
			}
		continue;
		}
		redirectflag = 0;
                if(itr > 1 && (redirectcnt > 1 || (redirectcnt == 1 && strcmp(cmds[itr-2], ">") != 0))) continue;
                if(itr > 1 && strcmp(cmds[itr-2], ">") == 0) {
			//fprintf(stdout, "redirection Found itr=%d\n", itr);
			//fflush(stdout);
			redirectflag = 1;
			cmds[itr-2] = NULL;
		//	close(STDOUT_FILENO);
		//	open(cmds[itr-1], O_CREAT|O_WRONLY|O_TRUNC, S_IRWXU);
		}
        //Forking happening here
                //fprintf(stdout, "Jid name = %s\n", linebuff);
                //fflush(stdout);
                pid_t pid;
                pid = fork();
                //fprintf(stdout, "After fork Loop PID:%i \n", (int)getpid());
                //fflush(stdout);
                job_idx[job_ctr].valid = 1;
                job_idx[job_ctr].bg = waitflag;
                job_idx[job_ctr].pid = pid;
                job_idx[job_ctr].jid = job_ctr;
                job_idx[job_ctr].jobcmd = strdup(jname);
//                fprintf(stdout, "Jid pid = %i ctr=%i\n", (int)job_idx[job_ctr].pid, job_ctr);
  //              fflush(stdout);
                job_ctr++;
                if (pid < 0) {
                        fprintf(stderr, "fork failed\n");
			fflush(stderr);
                        exit(1);
                }
                else if (pid == 0) {
                        //fprintf(stdout, "Entered Child Loop\n");
                        //fflush(stdout);
			if(redirectflag == 1) {
				close(STDOUT_FILENO);
				open(cmds[itr-1], O_CREAT|O_WRONLY|O_TRUNC, S_IRWXU);
				//redirectflag = 0;
			}

                        int cmdstatus;
                        //fprintf(stdout, "InnerJid pid = %i ctr=%i\n", (int)job_idx[job_ctr].pid, job_ctr);
                        //fflush(stdout);
                        cmdstatus = execvp(cmds[0], cmds); // runs word count
                        //fprintf(stdout, "Exited Child Loop\n");
                        //fflush(stdout);
                        //execvp(cmds[0], cmds); // runs word count
                        if (cmdstatus == -1) {
                               fprintf(stderr, "%s: Command not found\n", cmds[0]);
                               fflush(stderr);
                                //return 0;
                               if (waitflag == 0) _exit(1);
                        }
                        //exit(1);
                } else {
                        // parent goes down this path (main)
//                        int pid_wait = wait(NULL);
                       //if(waitflag == 0) wait(NULL);
                        //fprintf(stdout, "Parent Loop Still running\n");
                        //fflush(stdout);
                       if(waitflag == 0) waitpid(pid, &childstatus, WUNTRACED);
		       		//sleep(1);
                        //fprintf(stdout, "Parent Loop done\n");
                        //fflush(stdout);
                      //waitpid(pid, &childstatus, WUNTRACED);
                       //wait(NULL);
                }
        }
        if(mode == 0) fclose(fp);
        return 0;
}
