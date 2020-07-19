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
	totalframes = 0;
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
void
kfree(char *v)
{
  struct run *r;

  if((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);

  if(kmem.use_lock)
    acquire(&kmem.lock);
  r = (struct run*)v;
  r->next = kmem.freelist;
  kmem.freelist = r;
  if(kmem.use_lock)
    release(&kmem.lock);
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
  struct run *r;

  if(kmem.use_lock)
    acquire(&kmem.lock);
  r = kmem.freelist;
  if(r && r->next)
    kmem.freelist = (r->next)->next;
  int pa;
  int framenum;
  pa = V2P(r);
  framenum = (pa >> 12) & 0xffff;
  
  framearr[totalframes] = framenum;
  pidarr[totalframes] = -2;
  totalframes++;
//  cprintf("PA: %x", pa); //ADDED
 // cprintf("\n Frame Number: %x \n", framenum); //ADDED

  //Check Free
  /*
  struct run *testr;
	testr = r;
  for(int i = 0; i < 6; i++) {
  	cprintf("%x \t", (V2P(testr) >> 12) & 0xffff);
	testr = testr->next;
  }
  int framecount = 0;
  struct run *testrcount;
  testrcount = r;
  while(1) {
  framecount++;
  	if(testrcount && testrcount->next)
	  testrcount = testrcount->next->next;
	else
		break;
  }
  cprintf("\n Frame Count: %d \n", framecount); //ADDED
*/
	  
  if(kmem.use_lock)
    release(&kmem.lock);
  return (char*)r;
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
  for(int i = 0; i < numframes; i++) {
 // cprintf("frame arr at %d is: %d\n",i,framearr[i]);
  	frames[i] = framearr[i];
  	pids[i] = pidarr[i];
  }
  //numframe = totalframes;
  if(kmem.use_lock)
    release(&kmem.lock);
  
	return 0;
}

