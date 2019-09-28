#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <sys/wait.h>

int main(int argc, char *argv[]) {
        char linebuff[512];
        char *cmds[128];
        int job_ctr = 0;
        int mode = 0;
        FILE *fp;
        char *fname;
        int waitflag = 0;
        int childstatus;
        struct jobstr 
        {
                pid_t pid;
                int jid;
                char *jobcmd;
                int valid;
        };
        struct jobstr job_idx[100];
//Argument Check and File parsing for batch and mode set
        if(argc > 2) {
                fprintf(stderr, "Too many arguments");
                return -1;
        }
        else if (argc == 2) {
                fname = argv[1];
                fp = fopen(fname, "r");
                mode = 0;
                if (fp == NULL) {
                        printf("File not exist\n");
                        return -1;
                }
        }
        else mode = 1;
	
	//Initialization
	for(int j = 0; j < 100; j++) {
		job_idx[j].valid = 0;
	}

//Iteratilon Starts
        while(1) {
                if (mode == 0) {
                        if (fgets(linebuff, 512, fp) == NULL) break;;
                }
                else {
                        write(1, "mysh> ", 6);
                        fgets(linebuff,512, stdin);
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

                if(strcmp(cmds[0], "printjobs") == 0) {
                        for(int i = 0; i < 8; i++) {
                                        fprintf(stdout, "First Loop:i index= %i valid=%i PID pending = %i Jid= %ii CurrPID=%i Name:%s\n", i, job_idx[i].valid, job_idx[i].pid, job_idx[i].jid, (int)getpid(), job_idx[i].jobcmd);
                                        fflush(stdout);
                                if(job_idx[i].valid == 1 && waitpid(job_idx[i].pid, NULL, WNOHANG) == 0) {
                                        //fprintf(stdout, "i index= %i valid=%i PID pending = %i Jid= %ii CurrPID=%i \n", i, job_idx[i].valid, job_idx[i].pid, job_idx[i].jid, (int)getpid());
                                        fprintf(stdout, "%i:%s\n",job_idx[i].jid, job_idx[i].jobcmd);
					fflush(stdout);
                                }
                        }
			continue;
                }
                if(strcmp(cmds[0], "exit") == 0) break;
                if(strcmp(cmds[0], "jobs") == 0) {
                        for(int i = 0; i < 10; i++) {
                                        //fprintf(stdout, "First Loop:i index= %i valid=%i PID pending = %i Jid= %ii CurrPID=%i \n", i, job_idx[i].valid, job_idx[i].pid, job_idx[i].jid, (int)getpid());
                                        //fflush(stdout);
                                if(job_idx[i].valid == 1 && waitpid(job_idx[i].pid, NULL, WNOHANG) == 0) {
                                        //fprintf(stdout, "i index= %i valid=%i PID pending = %i Jid= %ii CurrPID=%i \n", i, job_idx[i].valid, job_idx[i].pid, job_idx[i].jid, (int)getpid());
                                        fprintf(stdout, "%i:%s\n",job_idx[i].jid, job_idx[i].jobcmd);
					fflush(stdout);
                                }
                        }
			continue;
                }
                
		int itr = 0;
        //Each Command iteration
                while(cmds[itr] != NULL) {
                        itr++;
                        cmds[itr] = strtok(NULL, " ");
                        //if(!strchr(cmds[itr], EOF)) break;
                }
        //Forking happening here
                //fprintf(stdout, "Jid name = %s\n", linebuff);
                //fflush(stdout);
                pid_t pid;
                pid = fork();
                job_idx[job_ctr].valid = 1;
                job_idx[job_ctr].pid = pid;
                job_idx[job_ctr].jid = job_ctr;
                job_idx[job_ctr].jobcmd = strdup(linebuff);
//                fprintf(stdout, "Jid pid = %i ctr=%i\n", (int)job_idx[job_ctr].pid, job_ctr);
  //              fflush(stdout);
                job_ctr++;
                if (pid < 0) {
                        fprintf(stderr, "fork failed\n");
                        exit(1);
                }
                else if (pid == 0) {
                        int cmdstatus;
                        //fprintf(stdout, "InnerJid pid = %i ctr=%i\n", (int)job_idx[job_ctr].pid, job_ctr);
                        //fflush(stdout);
                        cmdstatus = execvp(cmds[0], cmds); // runs word count
                        //execvp(cmds[0], cmds); // runs word count
                        if (cmdstatus == -1) {
                               fprintf(stdout, "Command invalid\n");
                               fflush(stdout);
                                //return 0;
                               if (waitflag == 0) exit(1);
                        }
                        //exit(1);
                } else {
                        // parent goes down this path (main)
//                        int pid_wait = wait(NULL);
                       //if(waitflag == 0) wait(NULL);
                       if(waitflag == 0) waitpid(pid, &childstatus, WUNTRACED);
                      //waitpid(pid, &childstatus, WUNTRACED);
                       //wait(NULL);
                }
        }
        if(mode == 0) fclose(fp);
        return 0;
}
