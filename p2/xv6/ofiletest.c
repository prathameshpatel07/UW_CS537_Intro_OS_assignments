#include "types.h"
#include "stat.h"
#include "user.h"
#include "fs.h"
#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "mmu.h"
#include "proc.h"
#include "x86.h"
#include "syscall.h"
#include "fcntl.h"

//char itoa_u (int num);
int main(int argc, char *argv[])
{
if(argc < 2 ) {
        printf(1,"No file open argument passed\n");
        exit();
}

int fd[100];
int argnum;

argnum = atoi(argv[1]);
for (int i = 0; i < 16; i++) {
        if(i < argnum) {
                fd[i] = open("ofile6",O_CREATE|O_RDWR);
        }
        else ;
}
for(int j = 2; j < argc; j++) {
        close(fd[atoi(argv[j])]);
}
  
  int filecnt;
  int nextfile;
  filecnt = getofilecnt(getpid());
  nextfile = getofilenext(getpid());
  printf(1,"%d %d\n",filecnt, nextfile); 
  exit();
}

