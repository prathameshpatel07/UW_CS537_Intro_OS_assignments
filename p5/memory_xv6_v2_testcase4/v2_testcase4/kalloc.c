// Physical memory allocator, intended to allocate
// memory for user processes, kernel stacks, page table pages,
// and pipe buffers. Allocates 4096-byte pages.

#include "types.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "mmu.h"
#include "spinlock.h"

void freerange(void *vstart, void *vend);
extern char end[]; // first address after kernel loaded from ELF file
                   // defined by the kernel linker script in kernel.ld

struct run {
  struct run *next;
};

struct {
  struct spinlock lock;
  int use_lock;
  struct run *freelist;
} kmem;

  int framearr[65536];
  int pidarr[65536];
  int totalframes;
  int dd =0;
  int inidone =0;
// Initialization happens in two phases.
// 1. main() calls kinit1() while still using entrypgdir to place just
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
  initlock(&kmem.lock, "kmem");
  kmem.use_lock = 0;
  freerange(vstart, vend);
}

void
kinit2(void *vstart, void *vend)
{
  freerange(vstart, vend);
  kmem.use_lock = 1;

  for(int i = 0; i < 16384; i++) {
  	framearr[i] = -1;
  	pidarr[i] = -1;
  }
	dd =1;
}

void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
    kfree(p);
}
// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
int findIndexinframeArr(int frame)
{
  for(int i=0; i<65536; i++){

                if(frame == framearr[i])
                {
                  return i;
                }
        }
  return -1;
}

int getPidforFrame(int frame)
{
        for(int i=0; i<65536; i++){

                if(frame == framearr[i])
                {
                  return pidarr[i];
                }
        }

        return -1;
}


void
kfree(char *v)
{
  struct run *r;

  if((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
    panic("kfree");
   inidone =1;
  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);

  if(kmem.use_lock)
    acquire(&kmem.lock);
  r = (struct run*)v;
  r->next = kmem.freelist;
  kmem.freelist = r;

   
  if(inidone){
  int pa;
  int framenum;
  pa = V2P(r);
  framenum = (pa >> 12) & 0xffff;
  int i = findIndexinframeArr(framenum);
 // cprintf("I am freeing frame %x at i val: %d",framenum,i);
  if(i!=-1){
  framearr[i]=-1;
  pidarr[i]=-1;
  }
  }
  if(kmem.use_lock)
    release(&kmem.lock);
}

int isSafeToAllocare(int pid, int frame)
{
	if(pid == -2)
		return 1;
	
	int lpid = getPidforFrame(frame-1);
	int rpid = getPidforFrame(frame+1);
	if( (pid == lpid || lpid<0) && (rpid<0 || rpid == pid) )
	       return 1;
	return 0;	

}
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(int pid)
{
  struct run *r;
 // cprintf("pid : %d\n",pid);  
  if(kmem.use_lock)
    acquire(&kmem.lock);

 // int isSafe = 0;
  r = kmem.freelist;
  //if(r && r->next)
  //  kmem.freelist = (r->next)->next;
  if(!r) { 
  	if(kmem.use_lock)
    	release(&kmem.lock);
  }
  int pa;
  int framenum;
  pa = V2P(r);
  framenum = (pa >> 12) & 0xffff;
 // cprintf("head:  %x ",framenum);
  struct run *curr = r;
  struct run *prev = 0;
  while(curr && !isSafeToAllocare(pid,framenum))
  {
  // cprintf("my logic safe %d for frame %x and pid %d",isSafeToAllocare(pid,framenum),framenum,pid);
  // cprintf("it is safe:%d",isSafe);
   prev = curr;
   curr = curr->next;   
   pa = V2P(curr);
   framenum = (pa >> 12) & 0xffff;
  }

  if(!prev)
  {
//	   cprintf("allocate first free at head wgich was %x:",kmem.freelist);
	  kmem.freelist = curr->next;
  }
  else
  {
	  prev->next = curr->next;

  }
   framearr[totalframes]=framenum;
   pidarr[totalframes]= pid;
   totalframes ++;

  if(kmem.use_lock)
    release(&kmem.lock);
  return (char*)curr;
}

void swap(int *xp, int *yp)
{
    int temp = *xp;
    *xp = *yp;
    *yp = temp;
}

void bubbleSort(int *frame, int *pid, int n)
{
   int i, j;
   for (i = 0; i < n-1; i++)
       for (j = 0; j < n-i-1; j++)
           if (frame[j] < frame[j+1])
           {
                   swap(&frame[j], &frame[j+1]);
                   swap(&pid[j], &pid[j+1]);
           }
}

int
dump_physmem(int *frames, int *pids, int numframes)
{
  if(kmem.use_lock)
    acquire(&kmem.lock);
  //cprintf("numframes: %d\n",numframes);
  /*cprintf("size  of frames: %d\n ",sizeof(frames));
  if(sizeof(frames)/sizeof(int) < numframes || sizeof(pids)/sizeof(int) < numframes) {
  if(kmem.use_lock)
    release(&kmem.lock);
  
	return -1;
  	
  }*/
  if(!frames || !pids) {
  	if(kmem.use_lock)
    		release(&kmem.lock);
  
  	return -1;
  }
  int x =0;
  
 bubbleSort(framearr, pidarr, 16000);

  for(int i = 0; i < 65536; i++) {
 // cprintf("frame arr at %d is: %d\n",i,framearr[i]);
  	if(pidarr[i]!=-1){
  	 frames[x] = framearr[i];
  	 pids[x] = pidarr[i];
//	 cprintf("i: %d framearr[i]= %x pidarr[i]: %d     ",i,framearr[i],pidarr[i]);
	 x++;
	 if(x >= numframes) {
	 	break;
	 }
	}
  }
  //numframe = totalframes;
  if(kmem.use_lock)
    release(&kmem.lock);
  
	return 0;
}

