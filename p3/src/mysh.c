#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <sys/wait.h>

int main(int argc, char *argv[]) {
        char linebuff[512];
        char *cmds[128];
        int task[100];
        int task_ctr = 0;
	int mode = 0;
        FILE *fp;
        char *fname;
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

//Iteratilon Starts
        while(1) {
		if (mode == 0) {
	        	if (fgets(linebuff, 512, fp) == NULL) break;;
        	}
		else {
                	write(1, "mysh> ", 6);
                	fgets(linebuff,512, stdin);
		}

	// Main Code starts
	//EOL added for single command support 
                if(linebuff[strlen(linebuff)-1] == '\n') linebuff[strlen(linebuff)-1] = '\0';
                cmds[0] = strtok(linebuff, " ");
                if(strcmp(cmds[0], "exit") == 0) break;
		//cmds[1] = NULL; // mark end of array
                int itr = 0;
	//Each Command iteration
                while(cmds[itr] != NULL) {
                        itr++;
                        cmds[itr] = strtok(NULL, " ");
			//if(!strchr(cmds[itr], EOF)) break;
                }
                int pid = fork();
                if (pid < 0) {
                        fprintf(stderr, "fork failed\n");
                        exit(1);
                }
                else if (pid == 0) {
                        execvp(cmds[0], cmds); // runs word count
                } else {
                        // parent goes down this path (main)
//                        int pid_wait = wait(NULL);
                        wait(NULL);
                }
        }
        return 0;
}
