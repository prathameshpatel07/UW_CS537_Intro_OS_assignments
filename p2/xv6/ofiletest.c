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
char filename[100][8] = 
{
	"ofile0", "ofile1", "ofile2", "ofile3", "ofile4", "ofile5", "ofile6", "ofile7", "ofile8", "ofile9", 
	"ofile10", "ofile11", "ofile12", "ofile13", "ofile14", "ofile15", "ofile16", "ofile17", "ofile18", "ofile19",
	"ofile20", "ofile21", "ofile22", "ofile23", "ofile24", "ofile25", "ofile26", "ofile27", "ofile28", "ofile29",
	"ofile30", "ofile31", "ofile32", "ofile33", "ofile34", "ofile35", "ofile36", "ofile37", "ofile38", "ofile39",
	"ofile40", "ofile41", "ofile42", "ofile43", "ofile44", "ofile45", "ofile46", "ofile47", "ofile48", "ofile49",
	"ofile50", "ofile51", "ofile52", "ofile53", "ofile54", "ofile55", "ofile56", "ofile57", "ofile58", "ofile59",
	"ofile60", "ofile61", "ofile62", "ofile63", "ofile64", "ofile65", "ofile66", "ofile67", "ofile68", "ofile69",
	"ofile70", "ofile71", "ofile72", "ofile73", "ofile74", "ofile75", "ofile76", "ofile77", "ofile78", "ofile79",
	"ofile80", "ofile81", "ofile82", "ofile83", "ofile84", "ofile85", "ofile86", "ofile87", "ofile88", "ofile89",
	"ofile90", "ofile91", "ofile92", "ofile93", "ofile94", "ofile95", "ofile96", "ofile97", "ofile98", "ofile99"

};
argnum = atoi(argv[1]);
for (int i = 0; i < 100; i++) {
        if(i < argnum) {
                fd[i] = open(filename[i],O_CREATE|O_RDWR);
        }
        else ;
}
for(int j = 2; j < argc; j++) {
        close(fd[atoi(argv[j])]);
	unlink(filename[atoi(argv[j])]);
}
  
  int filecnt;
  int nextfile;
  filecnt = getofilecnt(getpid());
  nextfile = getofilenext(getpid());
  printf(1,"%d %d\n",filecnt, nextfile); 
  exit();
}

