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
int main(int argc, char *argv[])
{
//  struct proc *curproc = myproc();
//
int fd[4];
//char strr[10] = "ofile4";
char *strr = "ofile5";
fd[0] = open("ofile",O_CREATE|O_RDWR);
fd[1] = open("ofile",O_CREATE|O_RDWR);
fd[2] = open("ofile",O_CREATE|O_RDWR);
//fd[3] = open(strr,O_CREATE|O_RDWR);
printf(1,"File: %d\n",fd);
  int  pid;
  pid = getofilecnt(getpid());
  printf(1,"The PID is %d\n",pid); 
  printf(1,"The filename is %s\n",strr); 
//  printf(1,"The SPID is %d\n",curproc->pid); 
  exit();
}

