
kernel:     file format elf32-i386


Disassembly of section .text:

80100000 <multiboot_header>:
80100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
80100006:	00 00                	add    %al,(%eax)
80100008:	fe 4f 52             	decb   0x52(%edi)
8010000b:	e4                   	.byte 0xe4

8010000c <entry>:

# Entering xv6 on boot processor, with paging off.
.globl entry
entry:
  # Turn on page size extension for 4Mbyte pages
  movl    %cr4, %eax
8010000c:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax
8010000f:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
80100012:	0f 22 e0             	mov    %eax,%cr4
  # Set page directory
  movl    $(V2P_WO(entrypgdir)), %eax
80100015:	b8 00 80 10 00       	mov    $0x108000,%eax
  movl    %eax, %cr3
8010001a:	0f 22 d8             	mov    %eax,%cr3
  # Turn on paging.
  movl    %cr0, %eax
8010001d:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
80100020:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
80100025:	0f 22 c0             	mov    %eax,%cr0

  # Set up the stack pointer.
  movl $(stack + KSTACKSIZE), %esp
80100028:	bc c0 a5 10 80       	mov    $0x8010a5c0,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 7b 2b 10 80       	mov    $0x80102b7b,%eax
  jmp *%eax
80100032:	ff e0                	jmp    *%eax

80100034 <bget>:
// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return locked buffer.
static struct buf*
bget(uint dev, uint blockno)
{
80100034:	55                   	push   %ebp
80100035:	89 e5                	mov    %esp,%ebp
80100037:	57                   	push   %edi
80100038:	56                   	push   %esi
80100039:	53                   	push   %ebx
8010003a:	83 ec 18             	sub    $0x18,%esp
8010003d:	89 c6                	mov    %eax,%esi
8010003f:	89 d7                	mov    %edx,%edi
  struct buf *b;

  acquire(&bcache.lock);
80100041:	68 c0 a5 10 80       	push   $0x8010a5c0
80100046:	e8 61 3c 00 00       	call   80103cac <acquire>

  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
8010004b:	8b 1d 10 ed 10 80    	mov    0x8010ed10,%ebx
80100051:	83 c4 10             	add    $0x10,%esp
80100054:	eb 03                	jmp    80100059 <bget+0x25>
80100056:	8b 5b 54             	mov    0x54(%ebx),%ebx
80100059:	81 fb bc ec 10 80    	cmp    $0x8010ecbc,%ebx
8010005f:	74 30                	je     80100091 <bget+0x5d>
    if(b->dev == dev && b->blockno == blockno){
80100061:	39 73 04             	cmp    %esi,0x4(%ebx)
80100064:	75 f0                	jne    80100056 <bget+0x22>
80100066:	39 7b 08             	cmp    %edi,0x8(%ebx)
80100069:	75 eb                	jne    80100056 <bget+0x22>
      b->refcnt++;
8010006b:	8b 43 4c             	mov    0x4c(%ebx),%eax
8010006e:	83 c0 01             	add    $0x1,%eax
80100071:	89 43 4c             	mov    %eax,0x4c(%ebx)
      release(&bcache.lock);
80100074:	83 ec 0c             	sub    $0xc,%esp
80100077:	68 c0 a5 10 80       	push   $0x8010a5c0
8010007c:	e8 90 3c 00 00       	call   80103d11 <release>
      acquiresleep(&b->lock);
80100081:	8d 43 0c             	lea    0xc(%ebx),%eax
80100084:	89 04 24             	mov    %eax,(%esp)
80100087:	e8 0c 3a 00 00       	call   80103a98 <acquiresleep>
      return b;
8010008c:	83 c4 10             	add    $0x10,%esp
8010008f:	eb 4c                	jmp    801000dd <bget+0xa9>
  }

  // Not cached; recycle an unused buffer.
  // Even if refcnt==0, B_DIRTY indicates a buffer is in use
  // because log.c has modified it but not yet committed it.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100091:	8b 1d 0c ed 10 80    	mov    0x8010ed0c,%ebx
80100097:	eb 03                	jmp    8010009c <bget+0x68>
80100099:	8b 5b 50             	mov    0x50(%ebx),%ebx
8010009c:	81 fb bc ec 10 80    	cmp    $0x8010ecbc,%ebx
801000a2:	74 43                	je     801000e7 <bget+0xb3>
    if(b->refcnt == 0 && (b->flags & B_DIRTY) == 0) {
801000a4:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801000a8:	75 ef                	jne    80100099 <bget+0x65>
801000aa:	f6 03 04             	testb  $0x4,(%ebx)
801000ad:	75 ea                	jne    80100099 <bget+0x65>
      b->dev = dev;
801000af:	89 73 04             	mov    %esi,0x4(%ebx)
      b->blockno = blockno;
801000b2:	89 7b 08             	mov    %edi,0x8(%ebx)
      b->flags = 0;
801000b5:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
      b->refcnt = 1;
801000bb:	c7 43 4c 01 00 00 00 	movl   $0x1,0x4c(%ebx)
      release(&bcache.lock);
801000c2:	83 ec 0c             	sub    $0xc,%esp
801000c5:	68 c0 a5 10 80       	push   $0x8010a5c0
801000ca:	e8 42 3c 00 00       	call   80103d11 <release>
      acquiresleep(&b->lock);
801000cf:	8d 43 0c             	lea    0xc(%ebx),%eax
801000d2:	89 04 24             	mov    %eax,(%esp)
801000d5:	e8 be 39 00 00       	call   80103a98 <acquiresleep>
      return b;
801000da:	83 c4 10             	add    $0x10,%esp
    }
  }
  panic("bget: no buffers");
}
801000dd:	89 d8                	mov    %ebx,%eax
801000df:	8d 65 f4             	lea    -0xc(%ebp),%esp
801000e2:	5b                   	pop    %ebx
801000e3:	5e                   	pop    %esi
801000e4:	5f                   	pop    %edi
801000e5:	5d                   	pop    %ebp
801000e6:	c3                   	ret    
  panic("bget: no buffers");
801000e7:	83 ec 0c             	sub    $0xc,%esp
801000ea:	68 c0 65 10 80       	push   $0x801065c0
801000ef:	e8 54 02 00 00       	call   80100348 <panic>

801000f4 <binit>:
{
801000f4:	55                   	push   %ebp
801000f5:	89 e5                	mov    %esp,%ebp
801000f7:	53                   	push   %ebx
801000f8:	83 ec 0c             	sub    $0xc,%esp
  initlock(&bcache.lock, "bcache");
801000fb:	68 d1 65 10 80       	push   $0x801065d1
80100100:	68 c0 a5 10 80       	push   $0x8010a5c0
80100105:	e8 66 3a 00 00       	call   80103b70 <initlock>
  bcache.head.prev = &bcache.head;
8010010a:	c7 05 0c ed 10 80 bc 	movl   $0x8010ecbc,0x8010ed0c
80100111:	ec 10 80 
  bcache.head.next = &bcache.head;
80100114:	c7 05 10 ed 10 80 bc 	movl   $0x8010ecbc,0x8010ed10
8010011b:	ec 10 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010011e:	83 c4 10             	add    $0x10,%esp
80100121:	bb f4 a5 10 80       	mov    $0x8010a5f4,%ebx
80100126:	eb 37                	jmp    8010015f <binit+0x6b>
    b->next = bcache.head.next;
80100128:	a1 10 ed 10 80       	mov    0x8010ed10,%eax
8010012d:	89 43 54             	mov    %eax,0x54(%ebx)
    b->prev = &bcache.head;
80100130:	c7 43 50 bc ec 10 80 	movl   $0x8010ecbc,0x50(%ebx)
    initsleeplock(&b->lock, "buffer");
80100137:	83 ec 08             	sub    $0x8,%esp
8010013a:	68 d8 65 10 80       	push   $0x801065d8
8010013f:	8d 43 0c             	lea    0xc(%ebx),%eax
80100142:	50                   	push   %eax
80100143:	e8 1d 39 00 00       	call   80103a65 <initsleeplock>
    bcache.head.next->prev = b;
80100148:	a1 10 ed 10 80       	mov    0x8010ed10,%eax
8010014d:	89 58 50             	mov    %ebx,0x50(%eax)
    bcache.head.next = b;
80100150:	89 1d 10 ed 10 80    	mov    %ebx,0x8010ed10
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100156:	81 c3 5c 02 00 00    	add    $0x25c,%ebx
8010015c:	83 c4 10             	add    $0x10,%esp
8010015f:	81 fb bc ec 10 80    	cmp    $0x8010ecbc,%ebx
80100165:	72 c1                	jb     80100128 <binit+0x34>
}
80100167:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010016a:	c9                   	leave  
8010016b:	c3                   	ret    

8010016c <bread>:

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
8010016c:	55                   	push   %ebp
8010016d:	89 e5                	mov    %esp,%ebp
8010016f:	53                   	push   %ebx
80100170:	83 ec 04             	sub    $0x4,%esp
  struct buf *b;

  b = bget(dev, blockno);
80100173:	8b 55 0c             	mov    0xc(%ebp),%edx
80100176:	8b 45 08             	mov    0x8(%ebp),%eax
80100179:	e8 b6 fe ff ff       	call   80100034 <bget>
8010017e:	89 c3                	mov    %eax,%ebx
  if((b->flags & B_VALID) == 0) {
80100180:	f6 00 02             	testb  $0x2,(%eax)
80100183:	74 07                	je     8010018c <bread+0x20>
    iderw(b);
  }
  return b;
}
80100185:	89 d8                	mov    %ebx,%eax
80100187:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010018a:	c9                   	leave  
8010018b:	c3                   	ret    
    iderw(b);
8010018c:	83 ec 0c             	sub    $0xc,%esp
8010018f:	50                   	push   %eax
80100190:	e8 77 1c 00 00       	call   80101e0c <iderw>
80100195:	83 c4 10             	add    $0x10,%esp
  return b;
80100198:	eb eb                	jmp    80100185 <bread+0x19>

8010019a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
8010019a:	55                   	push   %ebp
8010019b:	89 e5                	mov    %esp,%ebp
8010019d:	53                   	push   %ebx
8010019e:	83 ec 10             	sub    $0x10,%esp
801001a1:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holdingsleep(&b->lock))
801001a4:	8d 43 0c             	lea    0xc(%ebx),%eax
801001a7:	50                   	push   %eax
801001a8:	e8 75 39 00 00       	call   80103b22 <holdingsleep>
801001ad:	83 c4 10             	add    $0x10,%esp
801001b0:	85 c0                	test   %eax,%eax
801001b2:	74 14                	je     801001c8 <bwrite+0x2e>
    panic("bwrite");
  b->flags |= B_DIRTY;
801001b4:	83 0b 04             	orl    $0x4,(%ebx)
  iderw(b);
801001b7:	83 ec 0c             	sub    $0xc,%esp
801001ba:	53                   	push   %ebx
801001bb:	e8 4c 1c 00 00       	call   80101e0c <iderw>
}
801001c0:	83 c4 10             	add    $0x10,%esp
801001c3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801001c6:	c9                   	leave  
801001c7:	c3                   	ret    
    panic("bwrite");
801001c8:	83 ec 0c             	sub    $0xc,%esp
801001cb:	68 df 65 10 80       	push   $0x801065df
801001d0:	e8 73 01 00 00       	call   80100348 <panic>

801001d5 <brelse>:

// Release a locked buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
801001d5:	55                   	push   %ebp
801001d6:	89 e5                	mov    %esp,%ebp
801001d8:	56                   	push   %esi
801001d9:	53                   	push   %ebx
801001da:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holdingsleep(&b->lock))
801001dd:	8d 73 0c             	lea    0xc(%ebx),%esi
801001e0:	83 ec 0c             	sub    $0xc,%esp
801001e3:	56                   	push   %esi
801001e4:	e8 39 39 00 00       	call   80103b22 <holdingsleep>
801001e9:	83 c4 10             	add    $0x10,%esp
801001ec:	85 c0                	test   %eax,%eax
801001ee:	74 6b                	je     8010025b <brelse+0x86>
    panic("brelse");

  releasesleep(&b->lock);
801001f0:	83 ec 0c             	sub    $0xc,%esp
801001f3:	56                   	push   %esi
801001f4:	e8 ee 38 00 00       	call   80103ae7 <releasesleep>

  acquire(&bcache.lock);
801001f9:	c7 04 24 c0 a5 10 80 	movl   $0x8010a5c0,(%esp)
80100200:	e8 a7 3a 00 00       	call   80103cac <acquire>
  b->refcnt--;
80100205:	8b 43 4c             	mov    0x4c(%ebx),%eax
80100208:	83 e8 01             	sub    $0x1,%eax
8010020b:	89 43 4c             	mov    %eax,0x4c(%ebx)
  if (b->refcnt == 0) {
8010020e:	83 c4 10             	add    $0x10,%esp
80100211:	85 c0                	test   %eax,%eax
80100213:	75 2f                	jne    80100244 <brelse+0x6f>
    // no one is waiting for it.
    b->next->prev = b->prev;
80100215:	8b 43 54             	mov    0x54(%ebx),%eax
80100218:	8b 53 50             	mov    0x50(%ebx),%edx
8010021b:	89 50 50             	mov    %edx,0x50(%eax)
    b->prev->next = b->next;
8010021e:	8b 43 50             	mov    0x50(%ebx),%eax
80100221:	8b 53 54             	mov    0x54(%ebx),%edx
80100224:	89 50 54             	mov    %edx,0x54(%eax)
    b->next = bcache.head.next;
80100227:	a1 10 ed 10 80       	mov    0x8010ed10,%eax
8010022c:	89 43 54             	mov    %eax,0x54(%ebx)
    b->prev = &bcache.head;
8010022f:	c7 43 50 bc ec 10 80 	movl   $0x8010ecbc,0x50(%ebx)
    bcache.head.next->prev = b;
80100236:	a1 10 ed 10 80       	mov    0x8010ed10,%eax
8010023b:	89 58 50             	mov    %ebx,0x50(%eax)
    bcache.head.next = b;
8010023e:	89 1d 10 ed 10 80    	mov    %ebx,0x8010ed10
  }
  
  release(&bcache.lock);
80100244:	83 ec 0c             	sub    $0xc,%esp
80100247:	68 c0 a5 10 80       	push   $0x8010a5c0
8010024c:	e8 c0 3a 00 00       	call   80103d11 <release>
}
80100251:	83 c4 10             	add    $0x10,%esp
80100254:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100257:	5b                   	pop    %ebx
80100258:	5e                   	pop    %esi
80100259:	5d                   	pop    %ebp
8010025a:	c3                   	ret    
    panic("brelse");
8010025b:	83 ec 0c             	sub    $0xc,%esp
8010025e:	68 e6 65 10 80       	push   $0x801065e6
80100263:	e8 e0 00 00 00       	call   80100348 <panic>

80100268 <consoleread>:
  }
}

int
consoleread(struct inode *ip, char *dst, int n)
{
80100268:	55                   	push   %ebp
80100269:	89 e5                	mov    %esp,%ebp
8010026b:	57                   	push   %edi
8010026c:	56                   	push   %esi
8010026d:	53                   	push   %ebx
8010026e:	83 ec 28             	sub    $0x28,%esp
80100271:	8b 7d 08             	mov    0x8(%ebp),%edi
80100274:	8b 75 0c             	mov    0xc(%ebp),%esi
80100277:	8b 5d 10             	mov    0x10(%ebp),%ebx
  uint target;
  int c;

  iunlock(ip);
8010027a:	57                   	push   %edi
8010027b:	e8 c3 13 00 00       	call   80101643 <iunlock>
  target = n;
80100280:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  acquire(&cons.lock);
80100283:	c7 04 24 20 95 10 80 	movl   $0x80109520,(%esp)
8010028a:	e8 1d 3a 00 00       	call   80103cac <acquire>
  while(n > 0){
8010028f:	83 c4 10             	add    $0x10,%esp
80100292:	85 db                	test   %ebx,%ebx
80100294:	0f 8e 8f 00 00 00    	jle    80100329 <consoleread+0xc1>
    while(input.r == input.w){
8010029a:	a1 a0 ef 10 80       	mov    0x8010efa0,%eax
8010029f:	3b 05 a4 ef 10 80    	cmp    0x8010efa4,%eax
801002a5:	75 47                	jne    801002ee <consoleread+0x86>
      if(myproc()->killed){
801002a7:	e8 61 30 00 00       	call   8010330d <myproc>
801002ac:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801002b0:	75 17                	jne    801002c9 <consoleread+0x61>
        release(&cons.lock);
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &cons.lock);
801002b2:	83 ec 08             	sub    $0x8,%esp
801002b5:	68 20 95 10 80       	push   $0x80109520
801002ba:	68 a0 ef 10 80       	push   $0x8010efa0
801002bf:	e8 ed 34 00 00       	call   801037b1 <sleep>
801002c4:	83 c4 10             	add    $0x10,%esp
801002c7:	eb d1                	jmp    8010029a <consoleread+0x32>
        release(&cons.lock);
801002c9:	83 ec 0c             	sub    $0xc,%esp
801002cc:	68 20 95 10 80       	push   $0x80109520
801002d1:	e8 3b 3a 00 00       	call   80103d11 <release>
        ilock(ip);
801002d6:	89 3c 24             	mov    %edi,(%esp)
801002d9:	e8 a3 12 00 00       	call   80101581 <ilock>
        return -1;
801002de:	83 c4 10             	add    $0x10,%esp
801002e1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  release(&cons.lock);
  ilock(ip);

  return target - n;
}
801002e6:	8d 65 f4             	lea    -0xc(%ebp),%esp
801002e9:	5b                   	pop    %ebx
801002ea:	5e                   	pop    %esi
801002eb:	5f                   	pop    %edi
801002ec:	5d                   	pop    %ebp
801002ed:	c3                   	ret    
    c = input.buf[input.r++ % INPUT_BUF];
801002ee:	8d 50 01             	lea    0x1(%eax),%edx
801002f1:	89 15 a0 ef 10 80    	mov    %edx,0x8010efa0
801002f7:	89 c2                	mov    %eax,%edx
801002f9:	83 e2 7f             	and    $0x7f,%edx
801002fc:	0f b6 8a 20 ef 10 80 	movzbl -0x7fef10e0(%edx),%ecx
80100303:	0f be d1             	movsbl %cl,%edx
    if(c == C('D')){  // EOF
80100306:	83 fa 04             	cmp    $0x4,%edx
80100309:	74 14                	je     8010031f <consoleread+0xb7>
    *dst++ = c;
8010030b:	8d 46 01             	lea    0x1(%esi),%eax
8010030e:	88 0e                	mov    %cl,(%esi)
    --n;
80100310:	83 eb 01             	sub    $0x1,%ebx
    if(c == '\n')
80100313:	83 fa 0a             	cmp    $0xa,%edx
80100316:	74 11                	je     80100329 <consoleread+0xc1>
    *dst++ = c;
80100318:	89 c6                	mov    %eax,%esi
8010031a:	e9 73 ff ff ff       	jmp    80100292 <consoleread+0x2a>
      if(n < target){
8010031f:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
80100322:	73 05                	jae    80100329 <consoleread+0xc1>
        input.r--;
80100324:	a3 a0 ef 10 80       	mov    %eax,0x8010efa0
  release(&cons.lock);
80100329:	83 ec 0c             	sub    $0xc,%esp
8010032c:	68 20 95 10 80       	push   $0x80109520
80100331:	e8 db 39 00 00       	call   80103d11 <release>
  ilock(ip);
80100336:	89 3c 24             	mov    %edi,(%esp)
80100339:	e8 43 12 00 00       	call   80101581 <ilock>
  return target - n;
8010033e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100341:	29 d8                	sub    %ebx,%eax
80100343:	83 c4 10             	add    $0x10,%esp
80100346:	eb 9e                	jmp    801002e6 <consoleread+0x7e>

80100348 <panic>:
{
80100348:	55                   	push   %ebp
80100349:	89 e5                	mov    %esp,%ebp
8010034b:	53                   	push   %ebx
8010034c:	83 ec 34             	sub    $0x34,%esp
}

static inline void
cli(void)
{
  asm volatile("cli");
8010034f:	fa                   	cli    
  cons.locking = 0;
80100350:	c7 05 54 95 10 80 00 	movl   $0x0,0x80109554
80100357:	00 00 00 
  cprintf("lapicid %d: panic: ", lapicid());
8010035a:	e8 36 21 00 00       	call   80102495 <lapicid>
8010035f:	83 ec 08             	sub    $0x8,%esp
80100362:	50                   	push   %eax
80100363:	68 ed 65 10 80       	push   $0x801065ed
80100368:	e8 9e 02 00 00       	call   8010060b <cprintf>
  cprintf(s);
8010036d:	83 c4 04             	add    $0x4,%esp
80100370:	ff 75 08             	pushl  0x8(%ebp)
80100373:	e8 93 02 00 00       	call   8010060b <cprintf>
  cprintf("\n");
80100378:	c7 04 24 3b 6f 10 80 	movl   $0x80106f3b,(%esp)
8010037f:	e8 87 02 00 00       	call   8010060b <cprintf>
  getcallerpcs(&s, pcs);
80100384:	83 c4 08             	add    $0x8,%esp
80100387:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010038a:	50                   	push   %eax
8010038b:	8d 45 08             	lea    0x8(%ebp),%eax
8010038e:	50                   	push   %eax
8010038f:	e8 f7 37 00 00       	call   80103b8b <getcallerpcs>
  for(i=0; i<10; i++)
80100394:	83 c4 10             	add    $0x10,%esp
80100397:	bb 00 00 00 00       	mov    $0x0,%ebx
8010039c:	eb 17                	jmp    801003b5 <panic+0x6d>
    cprintf(" %p", pcs[i]);
8010039e:	83 ec 08             	sub    $0x8,%esp
801003a1:	ff 74 9d d0          	pushl  -0x30(%ebp,%ebx,4)
801003a5:	68 01 66 10 80       	push   $0x80106601
801003aa:	e8 5c 02 00 00       	call   8010060b <cprintf>
  for(i=0; i<10; i++)
801003af:	83 c3 01             	add    $0x1,%ebx
801003b2:	83 c4 10             	add    $0x10,%esp
801003b5:	83 fb 09             	cmp    $0x9,%ebx
801003b8:	7e e4                	jle    8010039e <panic+0x56>
  panicked = 1; // freeze other CPU
801003ba:	c7 05 58 95 10 80 01 	movl   $0x1,0x80109558
801003c1:	00 00 00 
801003c4:	eb fe                	jmp    801003c4 <panic+0x7c>

801003c6 <cgaputc>:
{
801003c6:	55                   	push   %ebp
801003c7:	89 e5                	mov    %esp,%ebp
801003c9:	57                   	push   %edi
801003ca:	56                   	push   %esi
801003cb:	53                   	push   %ebx
801003cc:	83 ec 0c             	sub    $0xc,%esp
801003cf:	89 c6                	mov    %eax,%esi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801003d1:	b9 d4 03 00 00       	mov    $0x3d4,%ecx
801003d6:	b8 0e 00 00 00       	mov    $0xe,%eax
801003db:	89 ca                	mov    %ecx,%edx
801003dd:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801003de:	bb d5 03 00 00       	mov    $0x3d5,%ebx
801003e3:	89 da                	mov    %ebx,%edx
801003e5:	ec                   	in     (%dx),%al
  pos = inb(CRTPORT+1) << 8;
801003e6:	0f b6 f8             	movzbl %al,%edi
801003e9:	c1 e7 08             	shl    $0x8,%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801003ec:	b8 0f 00 00 00       	mov    $0xf,%eax
801003f1:	89 ca                	mov    %ecx,%edx
801003f3:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801003f4:	89 da                	mov    %ebx,%edx
801003f6:	ec                   	in     (%dx),%al
  pos |= inb(CRTPORT+1);
801003f7:	0f b6 c8             	movzbl %al,%ecx
801003fa:	09 f9                	or     %edi,%ecx
  if(c == '\n')
801003fc:	83 fe 0a             	cmp    $0xa,%esi
801003ff:	74 6a                	je     8010046b <cgaputc+0xa5>
  else if(c == BACKSPACE){
80100401:	81 fe 00 01 00 00    	cmp    $0x100,%esi
80100407:	0f 84 81 00 00 00    	je     8010048e <cgaputc+0xc8>
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
8010040d:	89 f0                	mov    %esi,%eax
8010040f:	0f b6 f0             	movzbl %al,%esi
80100412:	8d 59 01             	lea    0x1(%ecx),%ebx
80100415:	66 81 ce 00 07       	or     $0x700,%si
8010041a:	66 89 b4 09 00 80 0b 	mov    %si,-0x7ff48000(%ecx,%ecx,1)
80100421:	80 
  if(pos < 0 || pos > 25*80)
80100422:	81 fb d0 07 00 00    	cmp    $0x7d0,%ebx
80100428:	77 71                	ja     8010049b <cgaputc+0xd5>
  if((pos/80) >= 24){  // Scroll up.
8010042a:	81 fb 7f 07 00 00    	cmp    $0x77f,%ebx
80100430:	7f 76                	jg     801004a8 <cgaputc+0xe2>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80100432:	be d4 03 00 00       	mov    $0x3d4,%esi
80100437:	b8 0e 00 00 00       	mov    $0xe,%eax
8010043c:	89 f2                	mov    %esi,%edx
8010043e:	ee                   	out    %al,(%dx)
  outb(CRTPORT+1, pos>>8);
8010043f:	89 d8                	mov    %ebx,%eax
80100441:	c1 f8 08             	sar    $0x8,%eax
80100444:	b9 d5 03 00 00       	mov    $0x3d5,%ecx
80100449:	89 ca                	mov    %ecx,%edx
8010044b:	ee                   	out    %al,(%dx)
8010044c:	b8 0f 00 00 00       	mov    $0xf,%eax
80100451:	89 f2                	mov    %esi,%edx
80100453:	ee                   	out    %al,(%dx)
80100454:	89 d8                	mov    %ebx,%eax
80100456:	89 ca                	mov    %ecx,%edx
80100458:	ee                   	out    %al,(%dx)
  crt[pos] = ' ' | 0x0700;
80100459:	66 c7 84 1b 00 80 0b 	movw   $0x720,-0x7ff48000(%ebx,%ebx,1)
80100460:	80 20 07 
}
80100463:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100466:	5b                   	pop    %ebx
80100467:	5e                   	pop    %esi
80100468:	5f                   	pop    %edi
80100469:	5d                   	pop    %ebp
8010046a:	c3                   	ret    
    pos += 80 - pos%80;
8010046b:	ba 67 66 66 66       	mov    $0x66666667,%edx
80100470:	89 c8                	mov    %ecx,%eax
80100472:	f7 ea                	imul   %edx
80100474:	c1 fa 05             	sar    $0x5,%edx
80100477:	8d 14 92             	lea    (%edx,%edx,4),%edx
8010047a:	89 d0                	mov    %edx,%eax
8010047c:	c1 e0 04             	shl    $0x4,%eax
8010047f:	89 ca                	mov    %ecx,%edx
80100481:	29 c2                	sub    %eax,%edx
80100483:	bb 50 00 00 00       	mov    $0x50,%ebx
80100488:	29 d3                	sub    %edx,%ebx
8010048a:	01 cb                	add    %ecx,%ebx
8010048c:	eb 94                	jmp    80100422 <cgaputc+0x5c>
    if(pos > 0) --pos;
8010048e:	85 c9                	test   %ecx,%ecx
80100490:	7e 05                	jle    80100497 <cgaputc+0xd1>
80100492:	8d 59 ff             	lea    -0x1(%ecx),%ebx
80100495:	eb 8b                	jmp    80100422 <cgaputc+0x5c>
  pos |= inb(CRTPORT+1);
80100497:	89 cb                	mov    %ecx,%ebx
80100499:	eb 87                	jmp    80100422 <cgaputc+0x5c>
    panic("pos under/overflow");
8010049b:	83 ec 0c             	sub    $0xc,%esp
8010049e:	68 05 66 10 80       	push   $0x80106605
801004a3:	e8 a0 fe ff ff       	call   80100348 <panic>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801004a8:	83 ec 04             	sub    $0x4,%esp
801004ab:	68 60 0e 00 00       	push   $0xe60
801004b0:	68 a0 80 0b 80       	push   $0x800b80a0
801004b5:	68 00 80 0b 80       	push   $0x800b8000
801004ba:	e8 14 39 00 00       	call   80103dd3 <memmove>
    pos -= 80;
801004bf:	83 eb 50             	sub    $0x50,%ebx
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801004c2:	b8 80 07 00 00       	mov    $0x780,%eax
801004c7:	29 d8                	sub    %ebx,%eax
801004c9:	8d 94 1b 00 80 0b 80 	lea    -0x7ff48000(%ebx,%ebx,1),%edx
801004d0:	83 c4 0c             	add    $0xc,%esp
801004d3:	01 c0                	add    %eax,%eax
801004d5:	50                   	push   %eax
801004d6:	6a 00                	push   $0x0
801004d8:	52                   	push   %edx
801004d9:	e8 7a 38 00 00       	call   80103d58 <memset>
801004de:	83 c4 10             	add    $0x10,%esp
801004e1:	e9 4c ff ff ff       	jmp    80100432 <cgaputc+0x6c>

801004e6 <consputc>:
  if(panicked){
801004e6:	83 3d 58 95 10 80 00 	cmpl   $0x0,0x80109558
801004ed:	74 03                	je     801004f2 <consputc+0xc>
  asm volatile("cli");
801004ef:	fa                   	cli    
801004f0:	eb fe                	jmp    801004f0 <consputc+0xa>
{
801004f2:	55                   	push   %ebp
801004f3:	89 e5                	mov    %esp,%ebp
801004f5:	53                   	push   %ebx
801004f6:	83 ec 04             	sub    $0x4,%esp
801004f9:	89 c3                	mov    %eax,%ebx
  if(c == BACKSPACE){
801004fb:	3d 00 01 00 00       	cmp    $0x100,%eax
80100500:	74 18                	je     8010051a <consputc+0x34>
    uartputc(c);
80100502:	83 ec 0c             	sub    $0xc,%esp
80100505:	50                   	push   %eax
80100506:	e8 91 4c 00 00       	call   8010519c <uartputc>
8010050b:	83 c4 10             	add    $0x10,%esp
  cgaputc(c);
8010050e:	89 d8                	mov    %ebx,%eax
80100510:	e8 b1 fe ff ff       	call   801003c6 <cgaputc>
}
80100515:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100518:	c9                   	leave  
80100519:	c3                   	ret    
    uartputc('\b'); uartputc(' '); uartputc('\b');
8010051a:	83 ec 0c             	sub    $0xc,%esp
8010051d:	6a 08                	push   $0x8
8010051f:	e8 78 4c 00 00       	call   8010519c <uartputc>
80100524:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010052b:	e8 6c 4c 00 00       	call   8010519c <uartputc>
80100530:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100537:	e8 60 4c 00 00       	call   8010519c <uartputc>
8010053c:	83 c4 10             	add    $0x10,%esp
8010053f:	eb cd                	jmp    8010050e <consputc+0x28>

80100541 <printint>:
{
80100541:	55                   	push   %ebp
80100542:	89 e5                	mov    %esp,%ebp
80100544:	57                   	push   %edi
80100545:	56                   	push   %esi
80100546:	53                   	push   %ebx
80100547:	83 ec 1c             	sub    $0x1c,%esp
8010054a:	89 d7                	mov    %edx,%edi
  if(sign && (sign = xx < 0))
8010054c:	85 c9                	test   %ecx,%ecx
8010054e:	74 09                	je     80100559 <printint+0x18>
80100550:	89 c1                	mov    %eax,%ecx
80100552:	c1 e9 1f             	shr    $0x1f,%ecx
80100555:	85 c0                	test   %eax,%eax
80100557:	78 09                	js     80100562 <printint+0x21>
    x = xx;
80100559:	89 c2                	mov    %eax,%edx
  i = 0;
8010055b:	be 00 00 00 00       	mov    $0x0,%esi
80100560:	eb 08                	jmp    8010056a <printint+0x29>
    x = -xx;
80100562:	f7 d8                	neg    %eax
80100564:	89 c2                	mov    %eax,%edx
80100566:	eb f3                	jmp    8010055b <printint+0x1a>
    buf[i++] = digits[x % base];
80100568:	89 de                	mov    %ebx,%esi
8010056a:	89 d0                	mov    %edx,%eax
8010056c:	ba 00 00 00 00       	mov    $0x0,%edx
80100571:	f7 f7                	div    %edi
80100573:	8d 5e 01             	lea    0x1(%esi),%ebx
80100576:	0f b6 92 30 66 10 80 	movzbl -0x7fef99d0(%edx),%edx
8010057d:	88 54 35 d8          	mov    %dl,-0x28(%ebp,%esi,1)
  }while((x /= base) != 0);
80100581:	89 c2                	mov    %eax,%edx
80100583:	85 c0                	test   %eax,%eax
80100585:	75 e1                	jne    80100568 <printint+0x27>
  if(sign)
80100587:	85 c9                	test   %ecx,%ecx
80100589:	74 14                	je     8010059f <printint+0x5e>
    buf[i++] = '-';
8010058b:	c6 44 1d d8 2d       	movb   $0x2d,-0x28(%ebp,%ebx,1)
80100590:	8d 5e 02             	lea    0x2(%esi),%ebx
80100593:	eb 0a                	jmp    8010059f <printint+0x5e>
    consputc(buf[i]);
80100595:	0f be 44 1d d8       	movsbl -0x28(%ebp,%ebx,1),%eax
8010059a:	e8 47 ff ff ff       	call   801004e6 <consputc>
  while(--i >= 0)
8010059f:	83 eb 01             	sub    $0x1,%ebx
801005a2:	79 f1                	jns    80100595 <printint+0x54>
}
801005a4:	83 c4 1c             	add    $0x1c,%esp
801005a7:	5b                   	pop    %ebx
801005a8:	5e                   	pop    %esi
801005a9:	5f                   	pop    %edi
801005aa:	5d                   	pop    %ebp
801005ab:	c3                   	ret    

801005ac <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
801005ac:	55                   	push   %ebp
801005ad:	89 e5                	mov    %esp,%ebp
801005af:	57                   	push   %edi
801005b0:	56                   	push   %esi
801005b1:	53                   	push   %ebx
801005b2:	83 ec 18             	sub    $0x18,%esp
801005b5:	8b 7d 0c             	mov    0xc(%ebp),%edi
801005b8:	8b 75 10             	mov    0x10(%ebp),%esi
  int i;

  iunlock(ip);
801005bb:	ff 75 08             	pushl  0x8(%ebp)
801005be:	e8 80 10 00 00       	call   80101643 <iunlock>
  acquire(&cons.lock);
801005c3:	c7 04 24 20 95 10 80 	movl   $0x80109520,(%esp)
801005ca:	e8 dd 36 00 00       	call   80103cac <acquire>
  for(i = 0; i < n; i++)
801005cf:	83 c4 10             	add    $0x10,%esp
801005d2:	bb 00 00 00 00       	mov    $0x0,%ebx
801005d7:	eb 0c                	jmp    801005e5 <consolewrite+0x39>
    consputc(buf[i] & 0xff);
801005d9:	0f b6 04 1f          	movzbl (%edi,%ebx,1),%eax
801005dd:	e8 04 ff ff ff       	call   801004e6 <consputc>
  for(i = 0; i < n; i++)
801005e2:	83 c3 01             	add    $0x1,%ebx
801005e5:	39 f3                	cmp    %esi,%ebx
801005e7:	7c f0                	jl     801005d9 <consolewrite+0x2d>
  release(&cons.lock);
801005e9:	83 ec 0c             	sub    $0xc,%esp
801005ec:	68 20 95 10 80       	push   $0x80109520
801005f1:	e8 1b 37 00 00       	call   80103d11 <release>
  ilock(ip);
801005f6:	83 c4 04             	add    $0x4,%esp
801005f9:	ff 75 08             	pushl  0x8(%ebp)
801005fc:	e8 80 0f 00 00       	call   80101581 <ilock>

  return n;
}
80100601:	89 f0                	mov    %esi,%eax
80100603:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100606:	5b                   	pop    %ebx
80100607:	5e                   	pop    %esi
80100608:	5f                   	pop    %edi
80100609:	5d                   	pop    %ebp
8010060a:	c3                   	ret    

8010060b <cprintf>:
{
8010060b:	55                   	push   %ebp
8010060c:	89 e5                	mov    %esp,%ebp
8010060e:	57                   	push   %edi
8010060f:	56                   	push   %esi
80100610:	53                   	push   %ebx
80100611:	83 ec 1c             	sub    $0x1c,%esp
  locking = cons.locking;
80100614:	a1 54 95 10 80       	mov    0x80109554,%eax
80100619:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  if(locking)
8010061c:	85 c0                	test   %eax,%eax
8010061e:	75 10                	jne    80100630 <cprintf+0x25>
  if (fmt == 0)
80100620:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80100624:	74 1c                	je     80100642 <cprintf+0x37>
  argp = (uint*)(void*)(&fmt + 1);
80100626:	8d 7d 0c             	lea    0xc(%ebp),%edi
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100629:	bb 00 00 00 00       	mov    $0x0,%ebx
8010062e:	eb 27                	jmp    80100657 <cprintf+0x4c>
    acquire(&cons.lock);
80100630:	83 ec 0c             	sub    $0xc,%esp
80100633:	68 20 95 10 80       	push   $0x80109520
80100638:	e8 6f 36 00 00       	call   80103cac <acquire>
8010063d:	83 c4 10             	add    $0x10,%esp
80100640:	eb de                	jmp    80100620 <cprintf+0x15>
    panic("null fmt");
80100642:	83 ec 0c             	sub    $0xc,%esp
80100645:	68 1f 66 10 80       	push   $0x8010661f
8010064a:	e8 f9 fc ff ff       	call   80100348 <panic>
      consputc(c);
8010064f:	e8 92 fe ff ff       	call   801004e6 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100654:	83 c3 01             	add    $0x1,%ebx
80100657:	8b 55 08             	mov    0x8(%ebp),%edx
8010065a:	0f b6 04 1a          	movzbl (%edx,%ebx,1),%eax
8010065e:	85 c0                	test   %eax,%eax
80100660:	0f 84 b8 00 00 00    	je     8010071e <cprintf+0x113>
    if(c != '%'){
80100666:	83 f8 25             	cmp    $0x25,%eax
80100669:	75 e4                	jne    8010064f <cprintf+0x44>
    c = fmt[++i] & 0xff;
8010066b:	83 c3 01             	add    $0x1,%ebx
8010066e:	0f b6 34 1a          	movzbl (%edx,%ebx,1),%esi
    if(c == 0)
80100672:	85 f6                	test   %esi,%esi
80100674:	0f 84 a4 00 00 00    	je     8010071e <cprintf+0x113>
    switch(c){
8010067a:	83 fe 70             	cmp    $0x70,%esi
8010067d:	74 48                	je     801006c7 <cprintf+0xbc>
8010067f:	83 fe 70             	cmp    $0x70,%esi
80100682:	7f 26                	jg     801006aa <cprintf+0x9f>
80100684:	83 fe 25             	cmp    $0x25,%esi
80100687:	0f 84 82 00 00 00    	je     8010070f <cprintf+0x104>
8010068d:	83 fe 64             	cmp    $0x64,%esi
80100690:	75 22                	jne    801006b4 <cprintf+0xa9>
      printint(*argp++, 10, 1);
80100692:	8d 77 04             	lea    0x4(%edi),%esi
80100695:	8b 07                	mov    (%edi),%eax
80100697:	b9 01 00 00 00       	mov    $0x1,%ecx
8010069c:	ba 0a 00 00 00       	mov    $0xa,%edx
801006a1:	e8 9b fe ff ff       	call   80100541 <printint>
801006a6:	89 f7                	mov    %esi,%edi
      break;
801006a8:	eb aa                	jmp    80100654 <cprintf+0x49>
    switch(c){
801006aa:	83 fe 73             	cmp    $0x73,%esi
801006ad:	74 33                	je     801006e2 <cprintf+0xd7>
801006af:	83 fe 78             	cmp    $0x78,%esi
801006b2:	74 13                	je     801006c7 <cprintf+0xbc>
      consputc('%');
801006b4:	b8 25 00 00 00       	mov    $0x25,%eax
801006b9:	e8 28 fe ff ff       	call   801004e6 <consputc>
      consputc(c);
801006be:	89 f0                	mov    %esi,%eax
801006c0:	e8 21 fe ff ff       	call   801004e6 <consputc>
      break;
801006c5:	eb 8d                	jmp    80100654 <cprintf+0x49>
      printint(*argp++, 16, 0);
801006c7:	8d 77 04             	lea    0x4(%edi),%esi
801006ca:	8b 07                	mov    (%edi),%eax
801006cc:	b9 00 00 00 00       	mov    $0x0,%ecx
801006d1:	ba 10 00 00 00       	mov    $0x10,%edx
801006d6:	e8 66 fe ff ff       	call   80100541 <printint>
801006db:	89 f7                	mov    %esi,%edi
      break;
801006dd:	e9 72 ff ff ff       	jmp    80100654 <cprintf+0x49>
      if((s = (char*)*argp++) == 0)
801006e2:	8d 47 04             	lea    0x4(%edi),%eax
801006e5:	89 45 e0             	mov    %eax,-0x20(%ebp)
801006e8:	8b 37                	mov    (%edi),%esi
801006ea:	85 f6                	test   %esi,%esi
801006ec:	75 12                	jne    80100700 <cprintf+0xf5>
        s = "(null)";
801006ee:	be 18 66 10 80       	mov    $0x80106618,%esi
801006f3:	eb 0b                	jmp    80100700 <cprintf+0xf5>
        consputc(*s);
801006f5:	0f be c0             	movsbl %al,%eax
801006f8:	e8 e9 fd ff ff       	call   801004e6 <consputc>
      for(; *s; s++)
801006fd:	83 c6 01             	add    $0x1,%esi
80100700:	0f b6 06             	movzbl (%esi),%eax
80100703:	84 c0                	test   %al,%al
80100705:	75 ee                	jne    801006f5 <cprintf+0xea>
      if((s = (char*)*argp++) == 0)
80100707:	8b 7d e0             	mov    -0x20(%ebp),%edi
8010070a:	e9 45 ff ff ff       	jmp    80100654 <cprintf+0x49>
      consputc('%');
8010070f:	b8 25 00 00 00       	mov    $0x25,%eax
80100714:	e8 cd fd ff ff       	call   801004e6 <consputc>
      break;
80100719:	e9 36 ff ff ff       	jmp    80100654 <cprintf+0x49>
  if(locking)
8010071e:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100722:	75 08                	jne    8010072c <cprintf+0x121>
}
80100724:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100727:	5b                   	pop    %ebx
80100728:	5e                   	pop    %esi
80100729:	5f                   	pop    %edi
8010072a:	5d                   	pop    %ebp
8010072b:	c3                   	ret    
    release(&cons.lock);
8010072c:	83 ec 0c             	sub    $0xc,%esp
8010072f:	68 20 95 10 80       	push   $0x80109520
80100734:	e8 d8 35 00 00       	call   80103d11 <release>
80100739:	83 c4 10             	add    $0x10,%esp
}
8010073c:	eb e6                	jmp    80100724 <cprintf+0x119>

8010073e <consoleintr>:
{
8010073e:	55                   	push   %ebp
8010073f:	89 e5                	mov    %esp,%ebp
80100741:	57                   	push   %edi
80100742:	56                   	push   %esi
80100743:	53                   	push   %ebx
80100744:	83 ec 18             	sub    $0x18,%esp
80100747:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&cons.lock);
8010074a:	68 20 95 10 80       	push   $0x80109520
8010074f:	e8 58 35 00 00       	call   80103cac <acquire>
  while((c = getc()) >= 0){
80100754:	83 c4 10             	add    $0x10,%esp
  int c, doprocdump = 0;
80100757:	be 00 00 00 00       	mov    $0x0,%esi
  while((c = getc()) >= 0){
8010075c:	e9 c5 00 00 00       	jmp    80100826 <consoleintr+0xe8>
    switch(c){
80100761:	83 ff 08             	cmp    $0x8,%edi
80100764:	0f 84 e0 00 00 00    	je     8010084a <consoleintr+0x10c>
      if(c != 0 && input.e-input.r < INPUT_BUF){
8010076a:	85 ff                	test   %edi,%edi
8010076c:	0f 84 b4 00 00 00    	je     80100826 <consoleintr+0xe8>
80100772:	a1 a8 ef 10 80       	mov    0x8010efa8,%eax
80100777:	89 c2                	mov    %eax,%edx
80100779:	2b 15 a0 ef 10 80    	sub    0x8010efa0,%edx
8010077f:	83 fa 7f             	cmp    $0x7f,%edx
80100782:	0f 87 9e 00 00 00    	ja     80100826 <consoleintr+0xe8>
        c = (c == '\r') ? '\n' : c;
80100788:	83 ff 0d             	cmp    $0xd,%edi
8010078b:	0f 84 86 00 00 00    	je     80100817 <consoleintr+0xd9>
        input.buf[input.e++ % INPUT_BUF] = c;
80100791:	8d 50 01             	lea    0x1(%eax),%edx
80100794:	89 15 a8 ef 10 80    	mov    %edx,0x8010efa8
8010079a:	83 e0 7f             	and    $0x7f,%eax
8010079d:	89 f9                	mov    %edi,%ecx
8010079f:	88 88 20 ef 10 80    	mov    %cl,-0x7fef10e0(%eax)
        consputc(c);
801007a5:	89 f8                	mov    %edi,%eax
801007a7:	e8 3a fd ff ff       	call   801004e6 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
801007ac:	83 ff 0a             	cmp    $0xa,%edi
801007af:	0f 94 c2             	sete   %dl
801007b2:	83 ff 04             	cmp    $0x4,%edi
801007b5:	0f 94 c0             	sete   %al
801007b8:	08 c2                	or     %al,%dl
801007ba:	75 10                	jne    801007cc <consoleintr+0x8e>
801007bc:	a1 a0 ef 10 80       	mov    0x8010efa0,%eax
801007c1:	83 e8 80             	sub    $0xffffff80,%eax
801007c4:	39 05 a8 ef 10 80    	cmp    %eax,0x8010efa8
801007ca:	75 5a                	jne    80100826 <consoleintr+0xe8>
          input.w = input.e;
801007cc:	a1 a8 ef 10 80       	mov    0x8010efa8,%eax
801007d1:	a3 a4 ef 10 80       	mov    %eax,0x8010efa4
          wakeup(&input.r);
801007d6:	83 ec 0c             	sub    $0xc,%esp
801007d9:	68 a0 ef 10 80       	push   $0x8010efa0
801007de:	e8 33 31 00 00       	call   80103916 <wakeup>
801007e3:	83 c4 10             	add    $0x10,%esp
801007e6:	eb 3e                	jmp    80100826 <consoleintr+0xe8>
        input.e--;
801007e8:	a3 a8 ef 10 80       	mov    %eax,0x8010efa8
        consputc(BACKSPACE);
801007ed:	b8 00 01 00 00       	mov    $0x100,%eax
801007f2:	e8 ef fc ff ff       	call   801004e6 <consputc>
      while(input.e != input.w &&
801007f7:	a1 a8 ef 10 80       	mov    0x8010efa8,%eax
801007fc:	3b 05 a4 ef 10 80    	cmp    0x8010efa4,%eax
80100802:	74 22                	je     80100826 <consoleintr+0xe8>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100804:	83 e8 01             	sub    $0x1,%eax
80100807:	89 c2                	mov    %eax,%edx
80100809:	83 e2 7f             	and    $0x7f,%edx
      while(input.e != input.w &&
8010080c:	80 ba 20 ef 10 80 0a 	cmpb   $0xa,-0x7fef10e0(%edx)
80100813:	75 d3                	jne    801007e8 <consoleintr+0xaa>
80100815:	eb 0f                	jmp    80100826 <consoleintr+0xe8>
        c = (c == '\r') ? '\n' : c;
80100817:	bf 0a 00 00 00       	mov    $0xa,%edi
8010081c:	e9 70 ff ff ff       	jmp    80100791 <consoleintr+0x53>
      doprocdump = 1;
80100821:	be 01 00 00 00       	mov    $0x1,%esi
  while((c = getc()) >= 0){
80100826:	ff d3                	call   *%ebx
80100828:	89 c7                	mov    %eax,%edi
8010082a:	85 c0                	test   %eax,%eax
8010082c:	78 3d                	js     8010086b <consoleintr+0x12d>
    switch(c){
8010082e:	83 ff 10             	cmp    $0x10,%edi
80100831:	74 ee                	je     80100821 <consoleintr+0xe3>
80100833:	83 ff 10             	cmp    $0x10,%edi
80100836:	0f 8e 25 ff ff ff    	jle    80100761 <consoleintr+0x23>
8010083c:	83 ff 15             	cmp    $0x15,%edi
8010083f:	74 b6                	je     801007f7 <consoleintr+0xb9>
80100841:	83 ff 7f             	cmp    $0x7f,%edi
80100844:	0f 85 20 ff ff ff    	jne    8010076a <consoleintr+0x2c>
      if(input.e != input.w){
8010084a:	a1 a8 ef 10 80       	mov    0x8010efa8,%eax
8010084f:	3b 05 a4 ef 10 80    	cmp    0x8010efa4,%eax
80100855:	74 cf                	je     80100826 <consoleintr+0xe8>
        input.e--;
80100857:	83 e8 01             	sub    $0x1,%eax
8010085a:	a3 a8 ef 10 80       	mov    %eax,0x8010efa8
        consputc(BACKSPACE);
8010085f:	b8 00 01 00 00       	mov    $0x100,%eax
80100864:	e8 7d fc ff ff       	call   801004e6 <consputc>
80100869:	eb bb                	jmp    80100826 <consoleintr+0xe8>
  release(&cons.lock);
8010086b:	83 ec 0c             	sub    $0xc,%esp
8010086e:	68 20 95 10 80       	push   $0x80109520
80100873:	e8 99 34 00 00       	call   80103d11 <release>
  if(doprocdump) {
80100878:	83 c4 10             	add    $0x10,%esp
8010087b:	85 f6                	test   %esi,%esi
8010087d:	75 08                	jne    80100887 <consoleintr+0x149>
}
8010087f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100882:	5b                   	pop    %ebx
80100883:	5e                   	pop    %esi
80100884:	5f                   	pop    %edi
80100885:	5d                   	pop    %ebp
80100886:	c3                   	ret    
    procdump();  // now call procdump() wo. cons.lock held
80100887:	e8 27 31 00 00       	call   801039b3 <procdump>
}
8010088c:	eb f1                	jmp    8010087f <consoleintr+0x141>

8010088e <consoleinit>:

void
consoleinit(void)
{
8010088e:	55                   	push   %ebp
8010088f:	89 e5                	mov    %esp,%ebp
80100891:	83 ec 10             	sub    $0x10,%esp
  initlock(&cons.lock, "console");
80100894:	68 28 66 10 80       	push   $0x80106628
80100899:	68 20 95 10 80       	push   $0x80109520
8010089e:	e8 cd 32 00 00       	call   80103b70 <initlock>

  devsw[CONSOLE].write = consolewrite;
801008a3:	c7 05 6c f9 10 80 ac 	movl   $0x801005ac,0x8010f96c
801008aa:	05 10 80 
  devsw[CONSOLE].read = consoleread;
801008ad:	c7 05 68 f9 10 80 68 	movl   $0x80100268,0x8010f968
801008b4:	02 10 80 
  cons.locking = 1;
801008b7:	c7 05 54 95 10 80 01 	movl   $0x1,0x80109554
801008be:	00 00 00 

  ioapicenable(IRQ_KBD, 0);
801008c1:	83 c4 08             	add    $0x8,%esp
801008c4:	6a 00                	push   $0x0
801008c6:	6a 01                	push   $0x1
801008c8:	e8 b1 16 00 00       	call   80101f7e <ioapicenable>
}
801008cd:	83 c4 10             	add    $0x10,%esp
801008d0:	c9                   	leave  
801008d1:	c3                   	ret    

801008d2 <exec>:
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
{
801008d2:	55                   	push   %ebp
801008d3:	89 e5                	mov    %esp,%ebp
801008d5:	57                   	push   %edi
801008d6:	56                   	push   %esi
801008d7:	53                   	push   %ebx
801008d8:	81 ec 0c 01 00 00    	sub    $0x10c,%esp
  uint argc, sz, sp, ustack[3+MAXARG+1];
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;
  struct proc *curproc = myproc();
801008de:	e8 2a 2a 00 00       	call   8010330d <myproc>
801008e3:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)

  begin_op();
801008e9:	e8 d7 1f 00 00       	call   801028c5 <begin_op>

  if((ip = namei(path)) == 0){
801008ee:	83 ec 0c             	sub    $0xc,%esp
801008f1:	ff 75 08             	pushl  0x8(%ebp)
801008f4:	e8 e8 12 00 00       	call   80101be1 <namei>
801008f9:	83 c4 10             	add    $0x10,%esp
801008fc:	85 c0                	test   %eax,%eax
801008fe:	74 4a                	je     8010094a <exec+0x78>
80100900:	89 c3                	mov    %eax,%ebx
    end_op();
    cprintf("exec: fail\n");
    return -1;
  }
  ilock(ip);
80100902:	83 ec 0c             	sub    $0xc,%esp
80100905:	50                   	push   %eax
80100906:	e8 76 0c 00 00       	call   80101581 <ilock>
  pgdir = 0;

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) != sizeof(elf))
8010090b:	6a 34                	push   $0x34
8010090d:	6a 00                	push   $0x0
8010090f:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
80100915:	50                   	push   %eax
80100916:	53                   	push   %ebx
80100917:	e8 57 0e 00 00       	call   80101773 <readi>
8010091c:	83 c4 20             	add    $0x20,%esp
8010091f:	83 f8 34             	cmp    $0x34,%eax
80100922:	74 42                	je     80100966 <exec+0x94>
  return 0;

 bad:
  if(pgdir)
    freevm(pgdir);
  if(ip){
80100924:	85 db                	test   %ebx,%ebx
80100926:	0f 84 dd 02 00 00    	je     80100c09 <exec+0x337>
    iunlockput(ip);
8010092c:	83 ec 0c             	sub    $0xc,%esp
8010092f:	53                   	push   %ebx
80100930:	e8 f3 0d 00 00       	call   80101728 <iunlockput>
    end_op();
80100935:	e8 05 20 00 00       	call   8010293f <end_op>
8010093a:	83 c4 10             	add    $0x10,%esp
  }
  return -1;
8010093d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80100942:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100945:	5b                   	pop    %ebx
80100946:	5e                   	pop    %esi
80100947:	5f                   	pop    %edi
80100948:	5d                   	pop    %ebp
80100949:	c3                   	ret    
    end_op();
8010094a:	e8 f0 1f 00 00       	call   8010293f <end_op>
    cprintf("exec: fail\n");
8010094f:	83 ec 0c             	sub    $0xc,%esp
80100952:	68 41 66 10 80       	push   $0x80106641
80100957:	e8 af fc ff ff       	call   8010060b <cprintf>
    return -1;
8010095c:	83 c4 10             	add    $0x10,%esp
8010095f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100964:	eb dc                	jmp    80100942 <exec+0x70>
  if(elf.magic != ELF_MAGIC)
80100966:	81 bd 24 ff ff ff 7f 	cmpl   $0x464c457f,-0xdc(%ebp)
8010096d:	45 4c 46 
80100970:	75 b2                	jne    80100924 <exec+0x52>
  if((pgdir = setupkvm()) == 0)
80100972:	e8 e5 59 00 00       	call   8010635c <setupkvm>
80100977:	89 85 ec fe ff ff    	mov    %eax,-0x114(%ebp)
8010097d:	85 c0                	test   %eax,%eax
8010097f:	0f 84 06 01 00 00    	je     80100a8b <exec+0x1b9>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100985:	8b 85 40 ff ff ff    	mov    -0xc0(%ebp),%eax
  sz = 0;
8010098b:	bf 00 00 00 00       	mov    $0x0,%edi
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100990:	be 00 00 00 00       	mov    $0x0,%esi
80100995:	eb 0c                	jmp    801009a3 <exec+0xd1>
80100997:	83 c6 01             	add    $0x1,%esi
8010099a:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
801009a0:	83 c0 20             	add    $0x20,%eax
801009a3:	0f b7 95 50 ff ff ff 	movzwl -0xb0(%ebp),%edx
801009aa:	39 f2                	cmp    %esi,%edx
801009ac:	0f 8e 98 00 00 00    	jle    80100a4a <exec+0x178>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
801009b2:	89 85 f0 fe ff ff    	mov    %eax,-0x110(%ebp)
801009b8:	6a 20                	push   $0x20
801009ba:	50                   	push   %eax
801009bb:	8d 85 04 ff ff ff    	lea    -0xfc(%ebp),%eax
801009c1:	50                   	push   %eax
801009c2:	53                   	push   %ebx
801009c3:	e8 ab 0d 00 00       	call   80101773 <readi>
801009c8:	83 c4 10             	add    $0x10,%esp
801009cb:	83 f8 20             	cmp    $0x20,%eax
801009ce:	0f 85 b7 00 00 00    	jne    80100a8b <exec+0x1b9>
    if(ph.type != ELF_PROG_LOAD)
801009d4:	83 bd 04 ff ff ff 01 	cmpl   $0x1,-0xfc(%ebp)
801009db:	75 ba                	jne    80100997 <exec+0xc5>
    if(ph.memsz < ph.filesz)
801009dd:	8b 85 18 ff ff ff    	mov    -0xe8(%ebp),%eax
801009e3:	3b 85 14 ff ff ff    	cmp    -0xec(%ebp),%eax
801009e9:	0f 82 9c 00 00 00    	jb     80100a8b <exec+0x1b9>
    if(ph.vaddr + ph.memsz < ph.vaddr)
801009ef:	03 85 0c ff ff ff    	add    -0xf4(%ebp),%eax
801009f5:	0f 82 90 00 00 00    	jb     80100a8b <exec+0x1b9>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
801009fb:	83 ec 04             	sub    $0x4,%esp
801009fe:	50                   	push   %eax
801009ff:	57                   	push   %edi
80100a00:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a06:	e8 f7 57 00 00       	call   80106202 <allocuvm>
80100a0b:	89 c7                	mov    %eax,%edi
80100a0d:	83 c4 10             	add    $0x10,%esp
80100a10:	85 c0                	test   %eax,%eax
80100a12:	74 77                	je     80100a8b <exec+0x1b9>
    if(ph.vaddr % PGSIZE != 0)
80100a14:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100a1a:	a9 ff 0f 00 00       	test   $0xfff,%eax
80100a1f:	75 6a                	jne    80100a8b <exec+0x1b9>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100a21:	83 ec 0c             	sub    $0xc,%esp
80100a24:	ff b5 14 ff ff ff    	pushl  -0xec(%ebp)
80100a2a:	ff b5 08 ff ff ff    	pushl  -0xf8(%ebp)
80100a30:	53                   	push   %ebx
80100a31:	50                   	push   %eax
80100a32:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a38:	e8 93 56 00 00       	call   801060d0 <loaduvm>
80100a3d:	83 c4 20             	add    $0x20,%esp
80100a40:	85 c0                	test   %eax,%eax
80100a42:	0f 89 4f ff ff ff    	jns    80100997 <exec+0xc5>
 bad:
80100a48:	eb 41                	jmp    80100a8b <exec+0x1b9>
  iunlockput(ip);
80100a4a:	83 ec 0c             	sub    $0xc,%esp
80100a4d:	53                   	push   %ebx
80100a4e:	e8 d5 0c 00 00       	call   80101728 <iunlockput>
  end_op();
80100a53:	e8 e7 1e 00 00       	call   8010293f <end_op>
  sz = PGROUNDUP(sz);
80100a58:	8d 87 ff 0f 00 00    	lea    0xfff(%edi),%eax
80100a5e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100a63:	83 c4 0c             	add    $0xc,%esp
80100a66:	8d 90 00 20 00 00    	lea    0x2000(%eax),%edx
80100a6c:	52                   	push   %edx
80100a6d:	50                   	push   %eax
80100a6e:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a74:	e8 89 57 00 00       	call   80106202 <allocuvm>
80100a79:	89 85 f0 fe ff ff    	mov    %eax,-0x110(%ebp)
80100a7f:	83 c4 10             	add    $0x10,%esp
80100a82:	85 c0                	test   %eax,%eax
80100a84:	75 24                	jne    80100aaa <exec+0x1d8>
  ip = 0;
80100a86:	bb 00 00 00 00       	mov    $0x0,%ebx
  if(pgdir)
80100a8b:	8b 85 ec fe ff ff    	mov    -0x114(%ebp),%eax
80100a91:	85 c0                	test   %eax,%eax
80100a93:	0f 84 8b fe ff ff    	je     80100924 <exec+0x52>
    freevm(pgdir);
80100a99:	83 ec 0c             	sub    $0xc,%esp
80100a9c:	50                   	push   %eax
80100a9d:	e8 4a 58 00 00       	call   801062ec <freevm>
80100aa2:	83 c4 10             	add    $0x10,%esp
80100aa5:	e9 7a fe ff ff       	jmp    80100924 <exec+0x52>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100aaa:	89 c7                	mov    %eax,%edi
80100aac:	8d 80 00 e0 ff ff    	lea    -0x2000(%eax),%eax
80100ab2:	83 ec 08             	sub    $0x8,%esp
80100ab5:	50                   	push   %eax
80100ab6:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100abc:	e8 20 59 00 00       	call   801063e1 <clearpteu>
  for(argc = 0; argv[argc]; argc++) {
80100ac1:	83 c4 10             	add    $0x10,%esp
80100ac4:	bb 00 00 00 00       	mov    $0x0,%ebx
80100ac9:	8b 45 0c             	mov    0xc(%ebp),%eax
80100acc:	8d 34 98             	lea    (%eax,%ebx,4),%esi
80100acf:	8b 06                	mov    (%esi),%eax
80100ad1:	85 c0                	test   %eax,%eax
80100ad3:	74 4d                	je     80100b22 <exec+0x250>
    if(argc >= MAXARG)
80100ad5:	83 fb 1f             	cmp    $0x1f,%ebx
80100ad8:	0f 87 0d 01 00 00    	ja     80100beb <exec+0x319>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100ade:	83 ec 0c             	sub    $0xc,%esp
80100ae1:	50                   	push   %eax
80100ae2:	e8 13 34 00 00       	call   80103efa <strlen>
80100ae7:	29 c7                	sub    %eax,%edi
80100ae9:	83 ef 01             	sub    $0x1,%edi
80100aec:	83 e7 fc             	and    $0xfffffffc,%edi
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100aef:	83 c4 04             	add    $0x4,%esp
80100af2:	ff 36                	pushl  (%esi)
80100af4:	e8 01 34 00 00       	call   80103efa <strlen>
80100af9:	83 c0 01             	add    $0x1,%eax
80100afc:	50                   	push   %eax
80100afd:	ff 36                	pushl  (%esi)
80100aff:	57                   	push   %edi
80100b00:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b06:	e8 24 5a 00 00       	call   8010652f <copyout>
80100b0b:	83 c4 20             	add    $0x20,%esp
80100b0e:	85 c0                	test   %eax,%eax
80100b10:	0f 88 df 00 00 00    	js     80100bf5 <exec+0x323>
    ustack[3+argc] = sp;
80100b16:	89 bc 9d 64 ff ff ff 	mov    %edi,-0x9c(%ebp,%ebx,4)
  for(argc = 0; argv[argc]; argc++) {
80100b1d:	83 c3 01             	add    $0x1,%ebx
80100b20:	eb a7                	jmp    80100ac9 <exec+0x1f7>
  ustack[3+argc] = 0;
80100b22:	c7 84 9d 64 ff ff ff 	movl   $0x0,-0x9c(%ebp,%ebx,4)
80100b29:	00 00 00 00 
  ustack[0] = 0xffffffff;  // fake return PC
80100b2d:	c7 85 58 ff ff ff ff 	movl   $0xffffffff,-0xa8(%ebp)
80100b34:	ff ff ff 
  ustack[1] = argc;
80100b37:	89 9d 5c ff ff ff    	mov    %ebx,-0xa4(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100b3d:	8d 04 9d 04 00 00 00 	lea    0x4(,%ebx,4),%eax
80100b44:	89 f9                	mov    %edi,%ecx
80100b46:	29 c1                	sub    %eax,%ecx
80100b48:	89 8d 60 ff ff ff    	mov    %ecx,-0xa0(%ebp)
  sp -= (3+argc+1) * 4;
80100b4e:	8d 04 9d 10 00 00 00 	lea    0x10(,%ebx,4),%eax
80100b55:	29 c7                	sub    %eax,%edi
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100b57:	50                   	push   %eax
80100b58:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
80100b5e:	50                   	push   %eax
80100b5f:	57                   	push   %edi
80100b60:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b66:	e8 c4 59 00 00       	call   8010652f <copyout>
80100b6b:	83 c4 10             	add    $0x10,%esp
80100b6e:	85 c0                	test   %eax,%eax
80100b70:	0f 88 89 00 00 00    	js     80100bff <exec+0x32d>
  for(last=s=path; *s; s++)
80100b76:	8b 55 08             	mov    0x8(%ebp),%edx
80100b79:	89 d0                	mov    %edx,%eax
80100b7b:	eb 03                	jmp    80100b80 <exec+0x2ae>
80100b7d:	83 c0 01             	add    $0x1,%eax
80100b80:	0f b6 08             	movzbl (%eax),%ecx
80100b83:	84 c9                	test   %cl,%cl
80100b85:	74 0a                	je     80100b91 <exec+0x2bf>
    if(*s == '/')
80100b87:	80 f9 2f             	cmp    $0x2f,%cl
80100b8a:	75 f1                	jne    80100b7d <exec+0x2ab>
      last = s+1;
80100b8c:	8d 50 01             	lea    0x1(%eax),%edx
80100b8f:	eb ec                	jmp    80100b7d <exec+0x2ab>
  safestrcpy(curproc->name, last, sizeof(curproc->name));
80100b91:	8b b5 f4 fe ff ff    	mov    -0x10c(%ebp),%esi
80100b97:	89 f0                	mov    %esi,%eax
80100b99:	83 c0 6c             	add    $0x6c,%eax
80100b9c:	83 ec 04             	sub    $0x4,%esp
80100b9f:	6a 10                	push   $0x10
80100ba1:	52                   	push   %edx
80100ba2:	50                   	push   %eax
80100ba3:	e8 17 33 00 00       	call   80103ebf <safestrcpy>
  oldpgdir = curproc->pgdir;
80100ba8:	8b 5e 04             	mov    0x4(%esi),%ebx
  curproc->pgdir = pgdir;
80100bab:	8b 8d ec fe ff ff    	mov    -0x114(%ebp),%ecx
80100bb1:	89 4e 04             	mov    %ecx,0x4(%esi)
  curproc->sz = sz;
80100bb4:	8b 8d f0 fe ff ff    	mov    -0x110(%ebp),%ecx
80100bba:	89 0e                	mov    %ecx,(%esi)
  curproc->tf->eip = elf.entry;  // main
80100bbc:	8b 46 18             	mov    0x18(%esi),%eax
80100bbf:	8b 95 3c ff ff ff    	mov    -0xc4(%ebp),%edx
80100bc5:	89 50 38             	mov    %edx,0x38(%eax)
  curproc->tf->esp = sp;
80100bc8:	8b 46 18             	mov    0x18(%esi),%eax
80100bcb:	89 78 44             	mov    %edi,0x44(%eax)
  switchuvm(curproc);
80100bce:	89 34 24             	mov    %esi,(%esp)
80100bd1:	e8 79 53 00 00       	call   80105f4f <switchuvm>
  freevm(oldpgdir);
80100bd6:	89 1c 24             	mov    %ebx,(%esp)
80100bd9:	e8 0e 57 00 00       	call   801062ec <freevm>
  return 0;
80100bde:	83 c4 10             	add    $0x10,%esp
80100be1:	b8 00 00 00 00       	mov    $0x0,%eax
80100be6:	e9 57 fd ff ff       	jmp    80100942 <exec+0x70>
  ip = 0;
80100beb:	bb 00 00 00 00       	mov    $0x0,%ebx
80100bf0:	e9 96 fe ff ff       	jmp    80100a8b <exec+0x1b9>
80100bf5:	bb 00 00 00 00       	mov    $0x0,%ebx
80100bfa:	e9 8c fe ff ff       	jmp    80100a8b <exec+0x1b9>
80100bff:	bb 00 00 00 00       	mov    $0x0,%ebx
80100c04:	e9 82 fe ff ff       	jmp    80100a8b <exec+0x1b9>
  return -1;
80100c09:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100c0e:	e9 2f fd ff ff       	jmp    80100942 <exec+0x70>

80100c13 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80100c13:	55                   	push   %ebp
80100c14:	89 e5                	mov    %esp,%ebp
80100c16:	83 ec 10             	sub    $0x10,%esp
  initlock(&ftable.lock, "ftable");
80100c19:	68 4d 66 10 80       	push   $0x8010664d
80100c1e:	68 c0 ef 10 80       	push   $0x8010efc0
80100c23:	e8 48 2f 00 00       	call   80103b70 <initlock>
}
80100c28:	83 c4 10             	add    $0x10,%esp
80100c2b:	c9                   	leave  
80100c2c:	c3                   	ret    

80100c2d <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80100c2d:	55                   	push   %ebp
80100c2e:	89 e5                	mov    %esp,%ebp
80100c30:	53                   	push   %ebx
80100c31:	83 ec 10             	sub    $0x10,%esp
  struct file *f;

  acquire(&ftable.lock);
80100c34:	68 c0 ef 10 80       	push   $0x8010efc0
80100c39:	e8 6e 30 00 00       	call   80103cac <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100c3e:	83 c4 10             	add    $0x10,%esp
80100c41:	bb f4 ef 10 80       	mov    $0x8010eff4,%ebx
80100c46:	81 fb 54 f9 10 80    	cmp    $0x8010f954,%ebx
80100c4c:	73 29                	jae    80100c77 <filealloc+0x4a>
    if(f->ref == 0){
80100c4e:	83 7b 04 00          	cmpl   $0x0,0x4(%ebx)
80100c52:	74 05                	je     80100c59 <filealloc+0x2c>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100c54:	83 c3 18             	add    $0x18,%ebx
80100c57:	eb ed                	jmp    80100c46 <filealloc+0x19>
      f->ref = 1;
80100c59:	c7 43 04 01 00 00 00 	movl   $0x1,0x4(%ebx)
      release(&ftable.lock);
80100c60:	83 ec 0c             	sub    $0xc,%esp
80100c63:	68 c0 ef 10 80       	push   $0x8010efc0
80100c68:	e8 a4 30 00 00       	call   80103d11 <release>
      return f;
80100c6d:	83 c4 10             	add    $0x10,%esp
    }
  }
  release(&ftable.lock);
  return 0;
}
80100c70:	89 d8                	mov    %ebx,%eax
80100c72:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100c75:	c9                   	leave  
80100c76:	c3                   	ret    
  release(&ftable.lock);
80100c77:	83 ec 0c             	sub    $0xc,%esp
80100c7a:	68 c0 ef 10 80       	push   $0x8010efc0
80100c7f:	e8 8d 30 00 00       	call   80103d11 <release>
  return 0;
80100c84:	83 c4 10             	add    $0x10,%esp
80100c87:	bb 00 00 00 00       	mov    $0x0,%ebx
80100c8c:	eb e2                	jmp    80100c70 <filealloc+0x43>

80100c8e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80100c8e:	55                   	push   %ebp
80100c8f:	89 e5                	mov    %esp,%ebp
80100c91:	53                   	push   %ebx
80100c92:	83 ec 10             	sub    $0x10,%esp
80100c95:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&ftable.lock);
80100c98:	68 c0 ef 10 80       	push   $0x8010efc0
80100c9d:	e8 0a 30 00 00       	call   80103cac <acquire>
  if(f->ref < 1)
80100ca2:	8b 43 04             	mov    0x4(%ebx),%eax
80100ca5:	83 c4 10             	add    $0x10,%esp
80100ca8:	85 c0                	test   %eax,%eax
80100caa:	7e 1a                	jle    80100cc6 <filedup+0x38>
    panic("filedup");
  f->ref++;
80100cac:	83 c0 01             	add    $0x1,%eax
80100caf:	89 43 04             	mov    %eax,0x4(%ebx)
  release(&ftable.lock);
80100cb2:	83 ec 0c             	sub    $0xc,%esp
80100cb5:	68 c0 ef 10 80       	push   $0x8010efc0
80100cba:	e8 52 30 00 00       	call   80103d11 <release>
  return f;
}
80100cbf:	89 d8                	mov    %ebx,%eax
80100cc1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100cc4:	c9                   	leave  
80100cc5:	c3                   	ret    
    panic("filedup");
80100cc6:	83 ec 0c             	sub    $0xc,%esp
80100cc9:	68 54 66 10 80       	push   $0x80106654
80100cce:	e8 75 f6 ff ff       	call   80100348 <panic>

80100cd3 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
80100cd3:	55                   	push   %ebp
80100cd4:	89 e5                	mov    %esp,%ebp
80100cd6:	53                   	push   %ebx
80100cd7:	83 ec 30             	sub    $0x30,%esp
80100cda:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct file ff;

  acquire(&ftable.lock);
80100cdd:	68 c0 ef 10 80       	push   $0x8010efc0
80100ce2:	e8 c5 2f 00 00       	call   80103cac <acquire>
  if(f->ref < 1)
80100ce7:	8b 43 04             	mov    0x4(%ebx),%eax
80100cea:	83 c4 10             	add    $0x10,%esp
80100ced:	85 c0                	test   %eax,%eax
80100cef:	7e 1f                	jle    80100d10 <fileclose+0x3d>
    panic("fileclose");
  if(--f->ref > 0){
80100cf1:	83 e8 01             	sub    $0x1,%eax
80100cf4:	89 43 04             	mov    %eax,0x4(%ebx)
80100cf7:	85 c0                	test   %eax,%eax
80100cf9:	7e 22                	jle    80100d1d <fileclose+0x4a>
    release(&ftable.lock);
80100cfb:	83 ec 0c             	sub    $0xc,%esp
80100cfe:	68 c0 ef 10 80       	push   $0x8010efc0
80100d03:	e8 09 30 00 00       	call   80103d11 <release>
    return;
80100d08:	83 c4 10             	add    $0x10,%esp
  else if(ff.type == FD_INODE){
    begin_op();
    iput(ff.ip);
    end_op();
  }
}
80100d0b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100d0e:	c9                   	leave  
80100d0f:	c3                   	ret    
    panic("fileclose");
80100d10:	83 ec 0c             	sub    $0xc,%esp
80100d13:	68 5c 66 10 80       	push   $0x8010665c
80100d18:	e8 2b f6 ff ff       	call   80100348 <panic>
  ff = *f;
80100d1d:	8b 03                	mov    (%ebx),%eax
80100d1f:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100d22:	8b 43 08             	mov    0x8(%ebx),%eax
80100d25:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100d28:	8b 43 0c             	mov    0xc(%ebx),%eax
80100d2b:	89 45 ec             	mov    %eax,-0x14(%ebp)
80100d2e:	8b 43 10             	mov    0x10(%ebx),%eax
80100d31:	89 45 f0             	mov    %eax,-0x10(%ebp)
  f->ref = 0;
80100d34:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
  f->type = FD_NONE;
80100d3b:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  release(&ftable.lock);
80100d41:	83 ec 0c             	sub    $0xc,%esp
80100d44:	68 c0 ef 10 80       	push   $0x8010efc0
80100d49:	e8 c3 2f 00 00       	call   80103d11 <release>
  if(ff.type == FD_PIPE)
80100d4e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d51:	83 c4 10             	add    $0x10,%esp
80100d54:	83 f8 01             	cmp    $0x1,%eax
80100d57:	74 1f                	je     80100d78 <fileclose+0xa5>
  else if(ff.type == FD_INODE){
80100d59:	83 f8 02             	cmp    $0x2,%eax
80100d5c:	75 ad                	jne    80100d0b <fileclose+0x38>
    begin_op();
80100d5e:	e8 62 1b 00 00       	call   801028c5 <begin_op>
    iput(ff.ip);
80100d63:	83 ec 0c             	sub    $0xc,%esp
80100d66:	ff 75 f0             	pushl  -0x10(%ebp)
80100d69:	e8 1a 09 00 00       	call   80101688 <iput>
    end_op();
80100d6e:	e8 cc 1b 00 00       	call   8010293f <end_op>
80100d73:	83 c4 10             	add    $0x10,%esp
80100d76:	eb 93                	jmp    80100d0b <fileclose+0x38>
    pipeclose(ff.pipe, ff.writable);
80100d78:	83 ec 08             	sub    $0x8,%esp
80100d7b:	0f be 45 e9          	movsbl -0x17(%ebp),%eax
80100d7f:	50                   	push   %eax
80100d80:	ff 75 ec             	pushl  -0x14(%ebp)
80100d83:	e8 b1 21 00 00       	call   80102f39 <pipeclose>
80100d88:	83 c4 10             	add    $0x10,%esp
80100d8b:	e9 7b ff ff ff       	jmp    80100d0b <fileclose+0x38>

80100d90 <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
80100d90:	55                   	push   %ebp
80100d91:	89 e5                	mov    %esp,%ebp
80100d93:	53                   	push   %ebx
80100d94:	83 ec 04             	sub    $0x4,%esp
80100d97:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(f->type == FD_INODE){
80100d9a:	83 3b 02             	cmpl   $0x2,(%ebx)
80100d9d:	75 31                	jne    80100dd0 <filestat+0x40>
    ilock(f->ip);
80100d9f:	83 ec 0c             	sub    $0xc,%esp
80100da2:	ff 73 10             	pushl  0x10(%ebx)
80100da5:	e8 d7 07 00 00       	call   80101581 <ilock>
    stati(f->ip, st);
80100daa:	83 c4 08             	add    $0x8,%esp
80100dad:	ff 75 0c             	pushl  0xc(%ebp)
80100db0:	ff 73 10             	pushl  0x10(%ebx)
80100db3:	e8 90 09 00 00       	call   80101748 <stati>
    iunlock(f->ip);
80100db8:	83 c4 04             	add    $0x4,%esp
80100dbb:	ff 73 10             	pushl  0x10(%ebx)
80100dbe:	e8 80 08 00 00       	call   80101643 <iunlock>
    return 0;
80100dc3:	83 c4 10             	add    $0x10,%esp
80100dc6:	b8 00 00 00 00       	mov    $0x0,%eax
  }
  return -1;
}
80100dcb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100dce:	c9                   	leave  
80100dcf:	c3                   	ret    
  return -1;
80100dd0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100dd5:	eb f4                	jmp    80100dcb <filestat+0x3b>

80100dd7 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
80100dd7:	55                   	push   %ebp
80100dd8:	89 e5                	mov    %esp,%ebp
80100dda:	56                   	push   %esi
80100ddb:	53                   	push   %ebx
80100ddc:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;

  if(f->readable == 0)
80100ddf:	80 7b 08 00          	cmpb   $0x0,0x8(%ebx)
80100de3:	74 70                	je     80100e55 <fileread+0x7e>
    return -1;
  if(f->type == FD_PIPE)
80100de5:	8b 03                	mov    (%ebx),%eax
80100de7:	83 f8 01             	cmp    $0x1,%eax
80100dea:	74 44                	je     80100e30 <fileread+0x59>
    return piperead(f->pipe, addr, n);
  if(f->type == FD_INODE){
80100dec:	83 f8 02             	cmp    $0x2,%eax
80100def:	75 57                	jne    80100e48 <fileread+0x71>
    ilock(f->ip);
80100df1:	83 ec 0c             	sub    $0xc,%esp
80100df4:	ff 73 10             	pushl  0x10(%ebx)
80100df7:	e8 85 07 00 00       	call   80101581 <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
80100dfc:	ff 75 10             	pushl  0x10(%ebp)
80100dff:	ff 73 14             	pushl  0x14(%ebx)
80100e02:	ff 75 0c             	pushl  0xc(%ebp)
80100e05:	ff 73 10             	pushl  0x10(%ebx)
80100e08:	e8 66 09 00 00       	call   80101773 <readi>
80100e0d:	89 c6                	mov    %eax,%esi
80100e0f:	83 c4 20             	add    $0x20,%esp
80100e12:	85 c0                	test   %eax,%eax
80100e14:	7e 03                	jle    80100e19 <fileread+0x42>
      f->off += r;
80100e16:	01 43 14             	add    %eax,0x14(%ebx)
    iunlock(f->ip);
80100e19:	83 ec 0c             	sub    $0xc,%esp
80100e1c:	ff 73 10             	pushl  0x10(%ebx)
80100e1f:	e8 1f 08 00 00       	call   80101643 <iunlock>
    return r;
80100e24:	83 c4 10             	add    $0x10,%esp
  }
  panic("fileread");
}
80100e27:	89 f0                	mov    %esi,%eax
80100e29:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100e2c:	5b                   	pop    %ebx
80100e2d:	5e                   	pop    %esi
80100e2e:	5d                   	pop    %ebp
80100e2f:	c3                   	ret    
    return piperead(f->pipe, addr, n);
80100e30:	83 ec 04             	sub    $0x4,%esp
80100e33:	ff 75 10             	pushl  0x10(%ebp)
80100e36:	ff 75 0c             	pushl  0xc(%ebp)
80100e39:	ff 73 0c             	pushl  0xc(%ebx)
80100e3c:	e8 50 22 00 00       	call   80103091 <piperead>
80100e41:	89 c6                	mov    %eax,%esi
80100e43:	83 c4 10             	add    $0x10,%esp
80100e46:	eb df                	jmp    80100e27 <fileread+0x50>
  panic("fileread");
80100e48:	83 ec 0c             	sub    $0xc,%esp
80100e4b:	68 66 66 10 80       	push   $0x80106666
80100e50:	e8 f3 f4 ff ff       	call   80100348 <panic>
    return -1;
80100e55:	be ff ff ff ff       	mov    $0xffffffff,%esi
80100e5a:	eb cb                	jmp    80100e27 <fileread+0x50>

80100e5c <filewrite>:

// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
80100e5c:	55                   	push   %ebp
80100e5d:	89 e5                	mov    %esp,%ebp
80100e5f:	57                   	push   %edi
80100e60:	56                   	push   %esi
80100e61:	53                   	push   %ebx
80100e62:	83 ec 1c             	sub    $0x1c,%esp
80100e65:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;

  if(f->writable == 0)
80100e68:	80 7b 09 00          	cmpb   $0x0,0x9(%ebx)
80100e6c:	0f 84 c5 00 00 00    	je     80100f37 <filewrite+0xdb>
    return -1;
  if(f->type == FD_PIPE)
80100e72:	8b 03                	mov    (%ebx),%eax
80100e74:	83 f8 01             	cmp    $0x1,%eax
80100e77:	74 10                	je     80100e89 <filewrite+0x2d>
    return pipewrite(f->pipe, addr, n);
  if(f->type == FD_INODE){
80100e79:	83 f8 02             	cmp    $0x2,%eax
80100e7c:	0f 85 a8 00 00 00    	jne    80100f2a <filewrite+0xce>
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * 512;
    int i = 0;
80100e82:	bf 00 00 00 00       	mov    $0x0,%edi
80100e87:	eb 67                	jmp    80100ef0 <filewrite+0x94>
    return pipewrite(f->pipe, addr, n);
80100e89:	83 ec 04             	sub    $0x4,%esp
80100e8c:	ff 75 10             	pushl  0x10(%ebp)
80100e8f:	ff 75 0c             	pushl  0xc(%ebp)
80100e92:	ff 73 0c             	pushl  0xc(%ebx)
80100e95:	e8 2b 21 00 00       	call   80102fc5 <pipewrite>
80100e9a:	83 c4 10             	add    $0x10,%esp
80100e9d:	e9 80 00 00 00       	jmp    80100f22 <filewrite+0xc6>
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
80100ea2:	e8 1e 1a 00 00       	call   801028c5 <begin_op>
      ilock(f->ip);
80100ea7:	83 ec 0c             	sub    $0xc,%esp
80100eaa:	ff 73 10             	pushl  0x10(%ebx)
80100ead:	e8 cf 06 00 00       	call   80101581 <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
80100eb2:	89 f8                	mov    %edi,%eax
80100eb4:	03 45 0c             	add    0xc(%ebp),%eax
80100eb7:	ff 75 e4             	pushl  -0x1c(%ebp)
80100eba:	ff 73 14             	pushl  0x14(%ebx)
80100ebd:	50                   	push   %eax
80100ebe:	ff 73 10             	pushl  0x10(%ebx)
80100ec1:	e8 aa 09 00 00       	call   80101870 <writei>
80100ec6:	89 c6                	mov    %eax,%esi
80100ec8:	83 c4 20             	add    $0x20,%esp
80100ecb:	85 c0                	test   %eax,%eax
80100ecd:	7e 03                	jle    80100ed2 <filewrite+0x76>
        f->off += r;
80100ecf:	01 43 14             	add    %eax,0x14(%ebx)
      iunlock(f->ip);
80100ed2:	83 ec 0c             	sub    $0xc,%esp
80100ed5:	ff 73 10             	pushl  0x10(%ebx)
80100ed8:	e8 66 07 00 00       	call   80101643 <iunlock>
      end_op();
80100edd:	e8 5d 1a 00 00       	call   8010293f <end_op>

      if(r < 0)
80100ee2:	83 c4 10             	add    $0x10,%esp
80100ee5:	85 f6                	test   %esi,%esi
80100ee7:	78 31                	js     80100f1a <filewrite+0xbe>
        break;
      if(r != n1)
80100ee9:	39 75 e4             	cmp    %esi,-0x1c(%ebp)
80100eec:	75 1f                	jne    80100f0d <filewrite+0xb1>
        panic("short filewrite");
      i += r;
80100eee:	01 f7                	add    %esi,%edi
    while(i < n){
80100ef0:	3b 7d 10             	cmp    0x10(%ebp),%edi
80100ef3:	7d 25                	jge    80100f1a <filewrite+0xbe>
      int n1 = n - i;
80100ef5:	8b 45 10             	mov    0x10(%ebp),%eax
80100ef8:	29 f8                	sub    %edi,%eax
80100efa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      if(n1 > max)
80100efd:	3d 00 06 00 00       	cmp    $0x600,%eax
80100f02:	7e 9e                	jle    80100ea2 <filewrite+0x46>
        n1 = max;
80100f04:	c7 45 e4 00 06 00 00 	movl   $0x600,-0x1c(%ebp)
80100f0b:	eb 95                	jmp    80100ea2 <filewrite+0x46>
        panic("short filewrite");
80100f0d:	83 ec 0c             	sub    $0xc,%esp
80100f10:	68 6f 66 10 80       	push   $0x8010666f
80100f15:	e8 2e f4 ff ff       	call   80100348 <panic>
    }
    return i == n ? n : -1;
80100f1a:	3b 7d 10             	cmp    0x10(%ebp),%edi
80100f1d:	75 1f                	jne    80100f3e <filewrite+0xe2>
80100f1f:	8b 45 10             	mov    0x10(%ebp),%eax
  }
  panic("filewrite");
}
80100f22:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100f25:	5b                   	pop    %ebx
80100f26:	5e                   	pop    %esi
80100f27:	5f                   	pop    %edi
80100f28:	5d                   	pop    %ebp
80100f29:	c3                   	ret    
  panic("filewrite");
80100f2a:	83 ec 0c             	sub    $0xc,%esp
80100f2d:	68 75 66 10 80       	push   $0x80106675
80100f32:	e8 11 f4 ff ff       	call   80100348 <panic>
    return -1;
80100f37:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100f3c:	eb e4                	jmp    80100f22 <filewrite+0xc6>
    return i == n ? n : -1;
80100f3e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100f43:	eb dd                	jmp    80100f22 <filewrite+0xc6>

80100f45 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
80100f45:	55                   	push   %ebp
80100f46:	89 e5                	mov    %esp,%ebp
80100f48:	57                   	push   %edi
80100f49:	56                   	push   %esi
80100f4a:	53                   	push   %ebx
80100f4b:	83 ec 0c             	sub    $0xc,%esp
80100f4e:	89 d7                	mov    %edx,%edi
  char *s;
  int len;

  while(*path == '/')
80100f50:	eb 03                	jmp    80100f55 <skipelem+0x10>
    path++;
80100f52:	83 c0 01             	add    $0x1,%eax
  while(*path == '/')
80100f55:	0f b6 10             	movzbl (%eax),%edx
80100f58:	80 fa 2f             	cmp    $0x2f,%dl
80100f5b:	74 f5                	je     80100f52 <skipelem+0xd>
  if(*path == 0)
80100f5d:	84 d2                	test   %dl,%dl
80100f5f:	74 59                	je     80100fba <skipelem+0x75>
80100f61:	89 c3                	mov    %eax,%ebx
80100f63:	eb 03                	jmp    80100f68 <skipelem+0x23>
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
    path++;
80100f65:	83 c3 01             	add    $0x1,%ebx
  while(*path != '/' && *path != 0)
80100f68:	0f b6 13             	movzbl (%ebx),%edx
80100f6b:	80 fa 2f             	cmp    $0x2f,%dl
80100f6e:	0f 95 c1             	setne  %cl
80100f71:	84 d2                	test   %dl,%dl
80100f73:	0f 95 c2             	setne  %dl
80100f76:	84 d1                	test   %dl,%cl
80100f78:	75 eb                	jne    80100f65 <skipelem+0x20>
  len = path - s;
80100f7a:	89 de                	mov    %ebx,%esi
80100f7c:	29 c6                	sub    %eax,%esi
  if(len >= DIRSIZ)
80100f7e:	83 fe 0d             	cmp    $0xd,%esi
80100f81:	7e 11                	jle    80100f94 <skipelem+0x4f>
    memmove(name, s, DIRSIZ);
80100f83:	83 ec 04             	sub    $0x4,%esp
80100f86:	6a 0e                	push   $0xe
80100f88:	50                   	push   %eax
80100f89:	57                   	push   %edi
80100f8a:	e8 44 2e 00 00       	call   80103dd3 <memmove>
80100f8f:	83 c4 10             	add    $0x10,%esp
80100f92:	eb 17                	jmp    80100fab <skipelem+0x66>
  else {
    memmove(name, s, len);
80100f94:	83 ec 04             	sub    $0x4,%esp
80100f97:	56                   	push   %esi
80100f98:	50                   	push   %eax
80100f99:	57                   	push   %edi
80100f9a:	e8 34 2e 00 00       	call   80103dd3 <memmove>
    name[len] = 0;
80100f9f:	c6 04 37 00          	movb   $0x0,(%edi,%esi,1)
80100fa3:	83 c4 10             	add    $0x10,%esp
80100fa6:	eb 03                	jmp    80100fab <skipelem+0x66>
  }
  while(*path == '/')
    path++;
80100fa8:	83 c3 01             	add    $0x1,%ebx
  while(*path == '/')
80100fab:	80 3b 2f             	cmpb   $0x2f,(%ebx)
80100fae:	74 f8                	je     80100fa8 <skipelem+0x63>
  return path;
}
80100fb0:	89 d8                	mov    %ebx,%eax
80100fb2:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100fb5:	5b                   	pop    %ebx
80100fb6:	5e                   	pop    %esi
80100fb7:	5f                   	pop    %edi
80100fb8:	5d                   	pop    %ebp
80100fb9:	c3                   	ret    
    return 0;
80100fba:	bb 00 00 00 00       	mov    $0x0,%ebx
80100fbf:	eb ef                	jmp    80100fb0 <skipelem+0x6b>

80100fc1 <bzero>:
{
80100fc1:	55                   	push   %ebp
80100fc2:	89 e5                	mov    %esp,%ebp
80100fc4:	53                   	push   %ebx
80100fc5:	83 ec 0c             	sub    $0xc,%esp
  bp = bread(dev, bno);
80100fc8:	52                   	push   %edx
80100fc9:	50                   	push   %eax
80100fca:	e8 9d f1 ff ff       	call   8010016c <bread>
80100fcf:	89 c3                	mov    %eax,%ebx
  memset(bp->data, 0, BSIZE);
80100fd1:	8d 40 5c             	lea    0x5c(%eax),%eax
80100fd4:	83 c4 0c             	add    $0xc,%esp
80100fd7:	68 00 02 00 00       	push   $0x200
80100fdc:	6a 00                	push   $0x0
80100fde:	50                   	push   %eax
80100fdf:	e8 74 2d 00 00       	call   80103d58 <memset>
  log_write(bp);
80100fe4:	89 1c 24             	mov    %ebx,(%esp)
80100fe7:	e8 02 1a 00 00       	call   801029ee <log_write>
  brelse(bp);
80100fec:	89 1c 24             	mov    %ebx,(%esp)
80100fef:	e8 e1 f1 ff ff       	call   801001d5 <brelse>
}
80100ff4:	83 c4 10             	add    $0x10,%esp
80100ff7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100ffa:	c9                   	leave  
80100ffb:	c3                   	ret    

80100ffc <balloc>:
{
80100ffc:	55                   	push   %ebp
80100ffd:	89 e5                	mov    %esp,%ebp
80100fff:	57                   	push   %edi
80101000:	56                   	push   %esi
80101001:	53                   	push   %ebx
80101002:	83 ec 1c             	sub    $0x1c,%esp
80101005:	89 45 d8             	mov    %eax,-0x28(%ebp)
  for(b = 0; b < sb.size; b += BPB){
80101008:	be 00 00 00 00       	mov    $0x0,%esi
8010100d:	eb 14                	jmp    80101023 <balloc+0x27>
    brelse(bp);
8010100f:	83 ec 0c             	sub    $0xc,%esp
80101012:	ff 75 e4             	pushl  -0x1c(%ebp)
80101015:	e8 bb f1 ff ff       	call   801001d5 <brelse>
  for(b = 0; b < sb.size; b += BPB){
8010101a:	81 c6 00 10 00 00    	add    $0x1000,%esi
80101020:	83 c4 10             	add    $0x10,%esp
80101023:	39 35 c0 f9 10 80    	cmp    %esi,0x8010f9c0
80101029:	76 75                	jbe    801010a0 <balloc+0xa4>
    bp = bread(dev, BBLOCK(b, sb));
8010102b:	8d 86 ff 0f 00 00    	lea    0xfff(%esi),%eax
80101031:	85 f6                	test   %esi,%esi
80101033:	0f 49 c6             	cmovns %esi,%eax
80101036:	c1 f8 0c             	sar    $0xc,%eax
80101039:	03 05 d8 f9 10 80    	add    0x8010f9d8,%eax
8010103f:	83 ec 08             	sub    $0x8,%esp
80101042:	50                   	push   %eax
80101043:	ff 75 d8             	pushl  -0x28(%ebp)
80101046:	e8 21 f1 ff ff       	call   8010016c <bread>
8010104b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
8010104e:	83 c4 10             	add    $0x10,%esp
80101051:	b8 00 00 00 00       	mov    $0x0,%eax
80101056:	3d ff 0f 00 00       	cmp    $0xfff,%eax
8010105b:	7f b2                	jg     8010100f <balloc+0x13>
8010105d:	8d 1c 06             	lea    (%esi,%eax,1),%ebx
80101060:	89 5d e0             	mov    %ebx,-0x20(%ebp)
80101063:	3b 1d c0 f9 10 80    	cmp    0x8010f9c0,%ebx
80101069:	73 a4                	jae    8010100f <balloc+0x13>
      m = 1 << (bi % 8);
8010106b:	99                   	cltd   
8010106c:	c1 ea 1d             	shr    $0x1d,%edx
8010106f:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
80101072:	83 e1 07             	and    $0x7,%ecx
80101075:	29 d1                	sub    %edx,%ecx
80101077:	ba 01 00 00 00       	mov    $0x1,%edx
8010107c:	d3 e2                	shl    %cl,%edx
      if((bp->data[bi/8] & m) == 0){  // Is block free?
8010107e:	8d 48 07             	lea    0x7(%eax),%ecx
80101081:	85 c0                	test   %eax,%eax
80101083:	0f 49 c8             	cmovns %eax,%ecx
80101086:	c1 f9 03             	sar    $0x3,%ecx
80101089:	89 4d dc             	mov    %ecx,-0x24(%ebp)
8010108c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
8010108f:	0f b6 4c 0f 5c       	movzbl 0x5c(%edi,%ecx,1),%ecx
80101094:	0f b6 f9             	movzbl %cl,%edi
80101097:	85 d7                	test   %edx,%edi
80101099:	74 12                	je     801010ad <balloc+0xb1>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
8010109b:	83 c0 01             	add    $0x1,%eax
8010109e:	eb b6                	jmp    80101056 <balloc+0x5a>
  panic("balloc: out of blocks");
801010a0:	83 ec 0c             	sub    $0xc,%esp
801010a3:	68 7f 66 10 80       	push   $0x8010667f
801010a8:	e8 9b f2 ff ff       	call   80100348 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
801010ad:	09 ca                	or     %ecx,%edx
801010af:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801010b2:	8b 75 dc             	mov    -0x24(%ebp),%esi
801010b5:	88 54 30 5c          	mov    %dl,0x5c(%eax,%esi,1)
        log_write(bp);
801010b9:	83 ec 0c             	sub    $0xc,%esp
801010bc:	89 c6                	mov    %eax,%esi
801010be:	50                   	push   %eax
801010bf:	e8 2a 19 00 00       	call   801029ee <log_write>
        brelse(bp);
801010c4:	89 34 24             	mov    %esi,(%esp)
801010c7:	e8 09 f1 ff ff       	call   801001d5 <brelse>
        bzero(dev, b + bi);
801010cc:	89 da                	mov    %ebx,%edx
801010ce:	8b 45 d8             	mov    -0x28(%ebp),%eax
801010d1:	e8 eb fe ff ff       	call   80100fc1 <bzero>
}
801010d6:	8b 45 e0             	mov    -0x20(%ebp),%eax
801010d9:	8d 65 f4             	lea    -0xc(%ebp),%esp
801010dc:	5b                   	pop    %ebx
801010dd:	5e                   	pop    %esi
801010de:	5f                   	pop    %edi
801010df:	5d                   	pop    %ebp
801010e0:	c3                   	ret    

801010e1 <bmap>:
{
801010e1:	55                   	push   %ebp
801010e2:	89 e5                	mov    %esp,%ebp
801010e4:	57                   	push   %edi
801010e5:	56                   	push   %esi
801010e6:	53                   	push   %ebx
801010e7:	83 ec 1c             	sub    $0x1c,%esp
801010ea:	89 c6                	mov    %eax,%esi
801010ec:	89 d7                	mov    %edx,%edi
  if(bn < NDIRECT){
801010ee:	83 fa 0b             	cmp    $0xb,%edx
801010f1:	77 17                	ja     8010110a <bmap+0x29>
    if((addr = ip->addrs[bn]) == 0)
801010f3:	8b 5c 90 5c          	mov    0x5c(%eax,%edx,4),%ebx
801010f7:	85 db                	test   %ebx,%ebx
801010f9:	75 4a                	jne    80101145 <bmap+0x64>
      ip->addrs[bn] = addr = balloc(ip->dev);
801010fb:	8b 00                	mov    (%eax),%eax
801010fd:	e8 fa fe ff ff       	call   80100ffc <balloc>
80101102:	89 c3                	mov    %eax,%ebx
80101104:	89 44 be 5c          	mov    %eax,0x5c(%esi,%edi,4)
80101108:	eb 3b                	jmp    80101145 <bmap+0x64>
  bn -= NDIRECT;
8010110a:	8d 5a f4             	lea    -0xc(%edx),%ebx
  if(bn < NINDIRECT){
8010110d:	83 fb 7f             	cmp    $0x7f,%ebx
80101110:	77 68                	ja     8010117a <bmap+0x99>
    if((addr = ip->addrs[NDIRECT]) == 0)
80101112:	8b 80 8c 00 00 00    	mov    0x8c(%eax),%eax
80101118:	85 c0                	test   %eax,%eax
8010111a:	74 33                	je     8010114f <bmap+0x6e>
    bp = bread(ip->dev, addr);
8010111c:	83 ec 08             	sub    $0x8,%esp
8010111f:	50                   	push   %eax
80101120:	ff 36                	pushl  (%esi)
80101122:	e8 45 f0 ff ff       	call   8010016c <bread>
80101127:	89 c7                	mov    %eax,%edi
    if((addr = a[bn]) == 0){
80101129:	8d 44 98 5c          	lea    0x5c(%eax,%ebx,4),%eax
8010112d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80101130:	8b 18                	mov    (%eax),%ebx
80101132:	83 c4 10             	add    $0x10,%esp
80101135:	85 db                	test   %ebx,%ebx
80101137:	74 25                	je     8010115e <bmap+0x7d>
    brelse(bp);
80101139:	83 ec 0c             	sub    $0xc,%esp
8010113c:	57                   	push   %edi
8010113d:	e8 93 f0 ff ff       	call   801001d5 <brelse>
    return addr;
80101142:	83 c4 10             	add    $0x10,%esp
}
80101145:	89 d8                	mov    %ebx,%eax
80101147:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010114a:	5b                   	pop    %ebx
8010114b:	5e                   	pop    %esi
8010114c:	5f                   	pop    %edi
8010114d:	5d                   	pop    %ebp
8010114e:	c3                   	ret    
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
8010114f:	8b 06                	mov    (%esi),%eax
80101151:	e8 a6 fe ff ff       	call   80100ffc <balloc>
80101156:	89 86 8c 00 00 00    	mov    %eax,0x8c(%esi)
8010115c:	eb be                	jmp    8010111c <bmap+0x3b>
      a[bn] = addr = balloc(ip->dev);
8010115e:	8b 06                	mov    (%esi),%eax
80101160:	e8 97 fe ff ff       	call   80100ffc <balloc>
80101165:	89 c3                	mov    %eax,%ebx
80101167:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010116a:	89 18                	mov    %ebx,(%eax)
      log_write(bp);
8010116c:	83 ec 0c             	sub    $0xc,%esp
8010116f:	57                   	push   %edi
80101170:	e8 79 18 00 00       	call   801029ee <log_write>
80101175:	83 c4 10             	add    $0x10,%esp
80101178:	eb bf                	jmp    80101139 <bmap+0x58>
  panic("bmap: out of range");
8010117a:	83 ec 0c             	sub    $0xc,%esp
8010117d:	68 95 66 10 80       	push   $0x80106695
80101182:	e8 c1 f1 ff ff       	call   80100348 <panic>

80101187 <iget>:
{
80101187:	55                   	push   %ebp
80101188:	89 e5                	mov    %esp,%ebp
8010118a:	57                   	push   %edi
8010118b:	56                   	push   %esi
8010118c:	53                   	push   %ebx
8010118d:	83 ec 28             	sub    $0x28,%esp
80101190:	89 c7                	mov    %eax,%edi
80101192:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  acquire(&icache.lock);
80101195:	68 e0 f9 10 80       	push   $0x8010f9e0
8010119a:	e8 0d 2b 00 00       	call   80103cac <acquire>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010119f:	83 c4 10             	add    $0x10,%esp
  empty = 0;
801011a2:	be 00 00 00 00       	mov    $0x0,%esi
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801011a7:	bb 14 fa 10 80       	mov    $0x8010fa14,%ebx
801011ac:	eb 0a                	jmp    801011b8 <iget+0x31>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801011ae:	85 f6                	test   %esi,%esi
801011b0:	74 3b                	je     801011ed <iget+0x66>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801011b2:	81 c3 90 00 00 00    	add    $0x90,%ebx
801011b8:	81 fb 34 16 11 80    	cmp    $0x80111634,%ebx
801011be:	73 35                	jae    801011f5 <iget+0x6e>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
801011c0:	8b 43 08             	mov    0x8(%ebx),%eax
801011c3:	85 c0                	test   %eax,%eax
801011c5:	7e e7                	jle    801011ae <iget+0x27>
801011c7:	39 3b                	cmp    %edi,(%ebx)
801011c9:	75 e3                	jne    801011ae <iget+0x27>
801011cb:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801011ce:	39 4b 04             	cmp    %ecx,0x4(%ebx)
801011d1:	75 db                	jne    801011ae <iget+0x27>
      ip->ref++;
801011d3:	83 c0 01             	add    $0x1,%eax
801011d6:	89 43 08             	mov    %eax,0x8(%ebx)
      release(&icache.lock);
801011d9:	83 ec 0c             	sub    $0xc,%esp
801011dc:	68 e0 f9 10 80       	push   $0x8010f9e0
801011e1:	e8 2b 2b 00 00       	call   80103d11 <release>
      return ip;
801011e6:	83 c4 10             	add    $0x10,%esp
801011e9:	89 de                	mov    %ebx,%esi
801011eb:	eb 32                	jmp    8010121f <iget+0x98>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801011ed:	85 c0                	test   %eax,%eax
801011ef:	75 c1                	jne    801011b2 <iget+0x2b>
      empty = ip;
801011f1:	89 de                	mov    %ebx,%esi
801011f3:	eb bd                	jmp    801011b2 <iget+0x2b>
  if(empty == 0)
801011f5:	85 f6                	test   %esi,%esi
801011f7:	74 30                	je     80101229 <iget+0xa2>
  ip->dev = dev;
801011f9:	89 3e                	mov    %edi,(%esi)
  ip->inum = inum;
801011fb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801011fe:	89 46 04             	mov    %eax,0x4(%esi)
  ip->ref = 1;
80101201:	c7 46 08 01 00 00 00 	movl   $0x1,0x8(%esi)
  ip->valid = 0;
80101208:	c7 46 4c 00 00 00 00 	movl   $0x0,0x4c(%esi)
  release(&icache.lock);
8010120f:	83 ec 0c             	sub    $0xc,%esp
80101212:	68 e0 f9 10 80       	push   $0x8010f9e0
80101217:	e8 f5 2a 00 00       	call   80103d11 <release>
  return ip;
8010121c:	83 c4 10             	add    $0x10,%esp
}
8010121f:	89 f0                	mov    %esi,%eax
80101221:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101224:	5b                   	pop    %ebx
80101225:	5e                   	pop    %esi
80101226:	5f                   	pop    %edi
80101227:	5d                   	pop    %ebp
80101228:	c3                   	ret    
    panic("iget: no inodes");
80101229:	83 ec 0c             	sub    $0xc,%esp
8010122c:	68 a8 66 10 80       	push   $0x801066a8
80101231:	e8 12 f1 ff ff       	call   80100348 <panic>

80101236 <readsb>:
{
80101236:	55                   	push   %ebp
80101237:	89 e5                	mov    %esp,%ebp
80101239:	53                   	push   %ebx
8010123a:	83 ec 0c             	sub    $0xc,%esp
  bp = bread(dev, 1);
8010123d:	6a 01                	push   $0x1
8010123f:	ff 75 08             	pushl  0x8(%ebp)
80101242:	e8 25 ef ff ff       	call   8010016c <bread>
80101247:	89 c3                	mov    %eax,%ebx
  memmove(sb, bp->data, sizeof(*sb));
80101249:	8d 40 5c             	lea    0x5c(%eax),%eax
8010124c:	83 c4 0c             	add    $0xc,%esp
8010124f:	6a 1c                	push   $0x1c
80101251:	50                   	push   %eax
80101252:	ff 75 0c             	pushl  0xc(%ebp)
80101255:	e8 79 2b 00 00       	call   80103dd3 <memmove>
  brelse(bp);
8010125a:	89 1c 24             	mov    %ebx,(%esp)
8010125d:	e8 73 ef ff ff       	call   801001d5 <brelse>
}
80101262:	83 c4 10             	add    $0x10,%esp
80101265:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101268:	c9                   	leave  
80101269:	c3                   	ret    

8010126a <bfree>:
{
8010126a:	55                   	push   %ebp
8010126b:	89 e5                	mov    %esp,%ebp
8010126d:	56                   	push   %esi
8010126e:	53                   	push   %ebx
8010126f:	89 c6                	mov    %eax,%esi
80101271:	89 d3                	mov    %edx,%ebx
  readsb(dev, &sb);
80101273:	83 ec 08             	sub    $0x8,%esp
80101276:	68 c0 f9 10 80       	push   $0x8010f9c0
8010127b:	50                   	push   %eax
8010127c:	e8 b5 ff ff ff       	call   80101236 <readsb>
  bp = bread(dev, BBLOCK(b, sb));
80101281:	89 d8                	mov    %ebx,%eax
80101283:	c1 e8 0c             	shr    $0xc,%eax
80101286:	03 05 d8 f9 10 80    	add    0x8010f9d8,%eax
8010128c:	83 c4 08             	add    $0x8,%esp
8010128f:	50                   	push   %eax
80101290:	56                   	push   %esi
80101291:	e8 d6 ee ff ff       	call   8010016c <bread>
80101296:	89 c6                	mov    %eax,%esi
  m = 1 << (bi % 8);
80101298:	89 d9                	mov    %ebx,%ecx
8010129a:	83 e1 07             	and    $0x7,%ecx
8010129d:	b8 01 00 00 00       	mov    $0x1,%eax
801012a2:	d3 e0                	shl    %cl,%eax
  if((bp->data[bi/8] & m) == 0)
801012a4:	83 c4 10             	add    $0x10,%esp
801012a7:	81 e3 ff 0f 00 00    	and    $0xfff,%ebx
801012ad:	c1 fb 03             	sar    $0x3,%ebx
801012b0:	0f b6 54 1e 5c       	movzbl 0x5c(%esi,%ebx,1),%edx
801012b5:	0f b6 ca             	movzbl %dl,%ecx
801012b8:	85 c1                	test   %eax,%ecx
801012ba:	74 23                	je     801012df <bfree+0x75>
  bp->data[bi/8] &= ~m;
801012bc:	f7 d0                	not    %eax
801012be:	21 d0                	and    %edx,%eax
801012c0:	88 44 1e 5c          	mov    %al,0x5c(%esi,%ebx,1)
  log_write(bp);
801012c4:	83 ec 0c             	sub    $0xc,%esp
801012c7:	56                   	push   %esi
801012c8:	e8 21 17 00 00       	call   801029ee <log_write>
  brelse(bp);
801012cd:	89 34 24             	mov    %esi,(%esp)
801012d0:	e8 00 ef ff ff       	call   801001d5 <brelse>
}
801012d5:	83 c4 10             	add    $0x10,%esp
801012d8:	8d 65 f8             	lea    -0x8(%ebp),%esp
801012db:	5b                   	pop    %ebx
801012dc:	5e                   	pop    %esi
801012dd:	5d                   	pop    %ebp
801012de:	c3                   	ret    
    panic("freeing free block");
801012df:	83 ec 0c             	sub    $0xc,%esp
801012e2:	68 b8 66 10 80       	push   $0x801066b8
801012e7:	e8 5c f0 ff ff       	call   80100348 <panic>

801012ec <iinit>:
{
801012ec:	55                   	push   %ebp
801012ed:	89 e5                	mov    %esp,%ebp
801012ef:	53                   	push   %ebx
801012f0:	83 ec 0c             	sub    $0xc,%esp
  initlock(&icache.lock, "icache");
801012f3:	68 cb 66 10 80       	push   $0x801066cb
801012f8:	68 e0 f9 10 80       	push   $0x8010f9e0
801012fd:	e8 6e 28 00 00       	call   80103b70 <initlock>
  for(i = 0; i < NINODE; i++) {
80101302:	83 c4 10             	add    $0x10,%esp
80101305:	bb 00 00 00 00       	mov    $0x0,%ebx
8010130a:	eb 21                	jmp    8010132d <iinit+0x41>
    initsleeplock(&icache.inode[i].lock, "inode");
8010130c:	83 ec 08             	sub    $0x8,%esp
8010130f:	68 d2 66 10 80       	push   $0x801066d2
80101314:	8d 14 db             	lea    (%ebx,%ebx,8),%edx
80101317:	89 d0                	mov    %edx,%eax
80101319:	c1 e0 04             	shl    $0x4,%eax
8010131c:	05 20 fa 10 80       	add    $0x8010fa20,%eax
80101321:	50                   	push   %eax
80101322:	e8 3e 27 00 00       	call   80103a65 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
80101327:	83 c3 01             	add    $0x1,%ebx
8010132a:	83 c4 10             	add    $0x10,%esp
8010132d:	83 fb 31             	cmp    $0x31,%ebx
80101330:	7e da                	jle    8010130c <iinit+0x20>
  readsb(dev, &sb);
80101332:	83 ec 08             	sub    $0x8,%esp
80101335:	68 c0 f9 10 80       	push   $0x8010f9c0
8010133a:	ff 75 08             	pushl  0x8(%ebp)
8010133d:	e8 f4 fe ff ff       	call   80101236 <readsb>
  cprintf("sb: size %d nblocks %d ninodes %d nlog %d logstart %d\
80101342:	ff 35 d8 f9 10 80    	pushl  0x8010f9d8
80101348:	ff 35 d4 f9 10 80    	pushl  0x8010f9d4
8010134e:	ff 35 d0 f9 10 80    	pushl  0x8010f9d0
80101354:	ff 35 cc f9 10 80    	pushl  0x8010f9cc
8010135a:	ff 35 c8 f9 10 80    	pushl  0x8010f9c8
80101360:	ff 35 c4 f9 10 80    	pushl  0x8010f9c4
80101366:	ff 35 c0 f9 10 80    	pushl  0x8010f9c0
8010136c:	68 38 67 10 80       	push   $0x80106738
80101371:	e8 95 f2 ff ff       	call   8010060b <cprintf>
}
80101376:	83 c4 30             	add    $0x30,%esp
80101379:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010137c:	c9                   	leave  
8010137d:	c3                   	ret    

8010137e <ialloc>:
{
8010137e:	55                   	push   %ebp
8010137f:	89 e5                	mov    %esp,%ebp
80101381:	57                   	push   %edi
80101382:	56                   	push   %esi
80101383:	53                   	push   %ebx
80101384:	83 ec 1c             	sub    $0x1c,%esp
80101387:	8b 45 0c             	mov    0xc(%ebp),%eax
8010138a:	89 45 e0             	mov    %eax,-0x20(%ebp)
  for(inum = 1; inum < sb.ninodes; inum++){
8010138d:	bb 01 00 00 00       	mov    $0x1,%ebx
80101392:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
80101395:	39 1d c8 f9 10 80    	cmp    %ebx,0x8010f9c8
8010139b:	76 3f                	jbe    801013dc <ialloc+0x5e>
    bp = bread(dev, IBLOCK(inum, sb));
8010139d:	89 d8                	mov    %ebx,%eax
8010139f:	c1 e8 03             	shr    $0x3,%eax
801013a2:	03 05 d4 f9 10 80    	add    0x8010f9d4,%eax
801013a8:	83 ec 08             	sub    $0x8,%esp
801013ab:	50                   	push   %eax
801013ac:	ff 75 08             	pushl  0x8(%ebp)
801013af:	e8 b8 ed ff ff       	call   8010016c <bread>
801013b4:	89 c6                	mov    %eax,%esi
    dip = (struct dinode*)bp->data + inum%IPB;
801013b6:	89 d8                	mov    %ebx,%eax
801013b8:	83 e0 07             	and    $0x7,%eax
801013bb:	c1 e0 06             	shl    $0x6,%eax
801013be:	8d 7c 06 5c          	lea    0x5c(%esi,%eax,1),%edi
    if(dip->type == 0){  // a free inode
801013c2:	83 c4 10             	add    $0x10,%esp
801013c5:	66 83 3f 00          	cmpw   $0x0,(%edi)
801013c9:	74 1e                	je     801013e9 <ialloc+0x6b>
    brelse(bp);
801013cb:	83 ec 0c             	sub    $0xc,%esp
801013ce:	56                   	push   %esi
801013cf:	e8 01 ee ff ff       	call   801001d5 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
801013d4:	83 c3 01             	add    $0x1,%ebx
801013d7:	83 c4 10             	add    $0x10,%esp
801013da:	eb b6                	jmp    80101392 <ialloc+0x14>
  panic("ialloc: no inodes");
801013dc:	83 ec 0c             	sub    $0xc,%esp
801013df:	68 d8 66 10 80       	push   $0x801066d8
801013e4:	e8 5f ef ff ff       	call   80100348 <panic>
      memset(dip, 0, sizeof(*dip));
801013e9:	83 ec 04             	sub    $0x4,%esp
801013ec:	6a 40                	push   $0x40
801013ee:	6a 00                	push   $0x0
801013f0:	57                   	push   %edi
801013f1:	e8 62 29 00 00       	call   80103d58 <memset>
      dip->type = type;
801013f6:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801013fa:	66 89 07             	mov    %ax,(%edi)
      log_write(bp);   // mark it allocated on the disk
801013fd:	89 34 24             	mov    %esi,(%esp)
80101400:	e8 e9 15 00 00       	call   801029ee <log_write>
      brelse(bp);
80101405:	89 34 24             	mov    %esi,(%esp)
80101408:	e8 c8 ed ff ff       	call   801001d5 <brelse>
      return iget(dev, inum);
8010140d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80101410:	8b 45 08             	mov    0x8(%ebp),%eax
80101413:	e8 6f fd ff ff       	call   80101187 <iget>
}
80101418:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010141b:	5b                   	pop    %ebx
8010141c:	5e                   	pop    %esi
8010141d:	5f                   	pop    %edi
8010141e:	5d                   	pop    %ebp
8010141f:	c3                   	ret    

80101420 <iupdate>:
{
80101420:	55                   	push   %ebp
80101421:	89 e5                	mov    %esp,%ebp
80101423:	56                   	push   %esi
80101424:	53                   	push   %ebx
80101425:	8b 5d 08             	mov    0x8(%ebp),%ebx
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
80101428:	8b 43 04             	mov    0x4(%ebx),%eax
8010142b:	c1 e8 03             	shr    $0x3,%eax
8010142e:	03 05 d4 f9 10 80    	add    0x8010f9d4,%eax
80101434:	83 ec 08             	sub    $0x8,%esp
80101437:	50                   	push   %eax
80101438:	ff 33                	pushl  (%ebx)
8010143a:	e8 2d ed ff ff       	call   8010016c <bread>
8010143f:	89 c6                	mov    %eax,%esi
  dip = (struct dinode*)bp->data + ip->inum%IPB;
80101441:	8b 43 04             	mov    0x4(%ebx),%eax
80101444:	83 e0 07             	and    $0x7,%eax
80101447:	c1 e0 06             	shl    $0x6,%eax
8010144a:	8d 44 06 5c          	lea    0x5c(%esi,%eax,1),%eax
  dip->type = ip->type;
8010144e:	0f b7 53 50          	movzwl 0x50(%ebx),%edx
80101452:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
80101455:	0f b7 53 52          	movzwl 0x52(%ebx),%edx
80101459:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
8010145d:	0f b7 53 54          	movzwl 0x54(%ebx),%edx
80101461:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
80101465:	0f b7 53 56          	movzwl 0x56(%ebx),%edx
80101469:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
8010146d:	8b 53 58             	mov    0x58(%ebx),%edx
80101470:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
80101473:	83 c3 5c             	add    $0x5c,%ebx
80101476:	83 c0 0c             	add    $0xc,%eax
80101479:	83 c4 0c             	add    $0xc,%esp
8010147c:	6a 34                	push   $0x34
8010147e:	53                   	push   %ebx
8010147f:	50                   	push   %eax
80101480:	e8 4e 29 00 00       	call   80103dd3 <memmove>
  log_write(bp);
80101485:	89 34 24             	mov    %esi,(%esp)
80101488:	e8 61 15 00 00       	call   801029ee <log_write>
  brelse(bp);
8010148d:	89 34 24             	mov    %esi,(%esp)
80101490:	e8 40 ed ff ff       	call   801001d5 <brelse>
}
80101495:	83 c4 10             	add    $0x10,%esp
80101498:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010149b:	5b                   	pop    %ebx
8010149c:	5e                   	pop    %esi
8010149d:	5d                   	pop    %ebp
8010149e:	c3                   	ret    

8010149f <itrunc>:
{
8010149f:	55                   	push   %ebp
801014a0:	89 e5                	mov    %esp,%ebp
801014a2:	57                   	push   %edi
801014a3:	56                   	push   %esi
801014a4:	53                   	push   %ebx
801014a5:	83 ec 1c             	sub    $0x1c,%esp
801014a8:	89 c6                	mov    %eax,%esi
  for(i = 0; i < NDIRECT; i++){
801014aa:	bb 00 00 00 00       	mov    $0x0,%ebx
801014af:	eb 03                	jmp    801014b4 <itrunc+0x15>
801014b1:	83 c3 01             	add    $0x1,%ebx
801014b4:	83 fb 0b             	cmp    $0xb,%ebx
801014b7:	7f 19                	jg     801014d2 <itrunc+0x33>
    if(ip->addrs[i]){
801014b9:	8b 54 9e 5c          	mov    0x5c(%esi,%ebx,4),%edx
801014bd:	85 d2                	test   %edx,%edx
801014bf:	74 f0                	je     801014b1 <itrunc+0x12>
      bfree(ip->dev, ip->addrs[i]);
801014c1:	8b 06                	mov    (%esi),%eax
801014c3:	e8 a2 fd ff ff       	call   8010126a <bfree>
      ip->addrs[i] = 0;
801014c8:	c7 44 9e 5c 00 00 00 	movl   $0x0,0x5c(%esi,%ebx,4)
801014cf:	00 
801014d0:	eb df                	jmp    801014b1 <itrunc+0x12>
  if(ip->addrs[NDIRECT]){
801014d2:	8b 86 8c 00 00 00    	mov    0x8c(%esi),%eax
801014d8:	85 c0                	test   %eax,%eax
801014da:	75 1b                	jne    801014f7 <itrunc+0x58>
  ip->size = 0;
801014dc:	c7 46 58 00 00 00 00 	movl   $0x0,0x58(%esi)
  iupdate(ip);
801014e3:	83 ec 0c             	sub    $0xc,%esp
801014e6:	56                   	push   %esi
801014e7:	e8 34 ff ff ff       	call   80101420 <iupdate>
}
801014ec:	83 c4 10             	add    $0x10,%esp
801014ef:	8d 65 f4             	lea    -0xc(%ebp),%esp
801014f2:	5b                   	pop    %ebx
801014f3:	5e                   	pop    %esi
801014f4:	5f                   	pop    %edi
801014f5:	5d                   	pop    %ebp
801014f6:	c3                   	ret    
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
801014f7:	83 ec 08             	sub    $0x8,%esp
801014fa:	50                   	push   %eax
801014fb:	ff 36                	pushl  (%esi)
801014fd:	e8 6a ec ff ff       	call   8010016c <bread>
80101502:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    a = (uint*)bp->data;
80101505:	8d 78 5c             	lea    0x5c(%eax),%edi
    for(j = 0; j < NINDIRECT; j++){
80101508:	83 c4 10             	add    $0x10,%esp
8010150b:	bb 00 00 00 00       	mov    $0x0,%ebx
80101510:	eb 03                	jmp    80101515 <itrunc+0x76>
80101512:	83 c3 01             	add    $0x1,%ebx
80101515:	83 fb 7f             	cmp    $0x7f,%ebx
80101518:	77 10                	ja     8010152a <itrunc+0x8b>
      if(a[j])
8010151a:	8b 14 9f             	mov    (%edi,%ebx,4),%edx
8010151d:	85 d2                	test   %edx,%edx
8010151f:	74 f1                	je     80101512 <itrunc+0x73>
        bfree(ip->dev, a[j]);
80101521:	8b 06                	mov    (%esi),%eax
80101523:	e8 42 fd ff ff       	call   8010126a <bfree>
80101528:	eb e8                	jmp    80101512 <itrunc+0x73>
    brelse(bp);
8010152a:	83 ec 0c             	sub    $0xc,%esp
8010152d:	ff 75 e4             	pushl  -0x1c(%ebp)
80101530:	e8 a0 ec ff ff       	call   801001d5 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101535:	8b 06                	mov    (%esi),%eax
80101537:	8b 96 8c 00 00 00    	mov    0x8c(%esi),%edx
8010153d:	e8 28 fd ff ff       	call   8010126a <bfree>
    ip->addrs[NDIRECT] = 0;
80101542:	c7 86 8c 00 00 00 00 	movl   $0x0,0x8c(%esi)
80101549:	00 00 00 
8010154c:	83 c4 10             	add    $0x10,%esp
8010154f:	eb 8b                	jmp    801014dc <itrunc+0x3d>

80101551 <idup>:
{
80101551:	55                   	push   %ebp
80101552:	89 e5                	mov    %esp,%ebp
80101554:	53                   	push   %ebx
80101555:	83 ec 10             	sub    $0x10,%esp
80101558:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&icache.lock);
8010155b:	68 e0 f9 10 80       	push   $0x8010f9e0
80101560:	e8 47 27 00 00       	call   80103cac <acquire>
  ip->ref++;
80101565:	8b 43 08             	mov    0x8(%ebx),%eax
80101568:	83 c0 01             	add    $0x1,%eax
8010156b:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
8010156e:	c7 04 24 e0 f9 10 80 	movl   $0x8010f9e0,(%esp)
80101575:	e8 97 27 00 00       	call   80103d11 <release>
}
8010157a:	89 d8                	mov    %ebx,%eax
8010157c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010157f:	c9                   	leave  
80101580:	c3                   	ret    

80101581 <ilock>:
{
80101581:	55                   	push   %ebp
80101582:	89 e5                	mov    %esp,%ebp
80101584:	56                   	push   %esi
80101585:	53                   	push   %ebx
80101586:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(ip == 0 || ip->ref < 1)
80101589:	85 db                	test   %ebx,%ebx
8010158b:	74 22                	je     801015af <ilock+0x2e>
8010158d:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101591:	7e 1c                	jle    801015af <ilock+0x2e>
  acquiresleep(&ip->lock);
80101593:	83 ec 0c             	sub    $0xc,%esp
80101596:	8d 43 0c             	lea    0xc(%ebx),%eax
80101599:	50                   	push   %eax
8010159a:	e8 f9 24 00 00       	call   80103a98 <acquiresleep>
  if(ip->valid == 0){
8010159f:	83 c4 10             	add    $0x10,%esp
801015a2:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801015a6:	74 14                	je     801015bc <ilock+0x3b>
}
801015a8:	8d 65 f8             	lea    -0x8(%ebp),%esp
801015ab:	5b                   	pop    %ebx
801015ac:	5e                   	pop    %esi
801015ad:	5d                   	pop    %ebp
801015ae:	c3                   	ret    
    panic("ilock");
801015af:	83 ec 0c             	sub    $0xc,%esp
801015b2:	68 ea 66 10 80       	push   $0x801066ea
801015b7:	e8 8c ed ff ff       	call   80100348 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
801015bc:	8b 43 04             	mov    0x4(%ebx),%eax
801015bf:	c1 e8 03             	shr    $0x3,%eax
801015c2:	03 05 d4 f9 10 80    	add    0x8010f9d4,%eax
801015c8:	83 ec 08             	sub    $0x8,%esp
801015cb:	50                   	push   %eax
801015cc:	ff 33                	pushl  (%ebx)
801015ce:	e8 99 eb ff ff       	call   8010016c <bread>
801015d3:	89 c6                	mov    %eax,%esi
    dip = (struct dinode*)bp->data + ip->inum%IPB;
801015d5:	8b 43 04             	mov    0x4(%ebx),%eax
801015d8:	83 e0 07             	and    $0x7,%eax
801015db:	c1 e0 06             	shl    $0x6,%eax
801015de:	8d 44 06 5c          	lea    0x5c(%esi,%eax,1),%eax
    ip->type = dip->type;
801015e2:	0f b7 10             	movzwl (%eax),%edx
801015e5:	66 89 53 50          	mov    %dx,0x50(%ebx)
    ip->major = dip->major;
801015e9:	0f b7 50 02          	movzwl 0x2(%eax),%edx
801015ed:	66 89 53 52          	mov    %dx,0x52(%ebx)
    ip->minor = dip->minor;
801015f1:	0f b7 50 04          	movzwl 0x4(%eax),%edx
801015f5:	66 89 53 54          	mov    %dx,0x54(%ebx)
    ip->nlink = dip->nlink;
801015f9:	0f b7 50 06          	movzwl 0x6(%eax),%edx
801015fd:	66 89 53 56          	mov    %dx,0x56(%ebx)
    ip->size = dip->size;
80101601:	8b 50 08             	mov    0x8(%eax),%edx
80101604:	89 53 58             	mov    %edx,0x58(%ebx)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101607:	83 c0 0c             	add    $0xc,%eax
8010160a:	8d 53 5c             	lea    0x5c(%ebx),%edx
8010160d:	83 c4 0c             	add    $0xc,%esp
80101610:	6a 34                	push   $0x34
80101612:	50                   	push   %eax
80101613:	52                   	push   %edx
80101614:	e8 ba 27 00 00       	call   80103dd3 <memmove>
    brelse(bp);
80101619:	89 34 24             	mov    %esi,(%esp)
8010161c:	e8 b4 eb ff ff       	call   801001d5 <brelse>
    ip->valid = 1;
80101621:	c7 43 4c 01 00 00 00 	movl   $0x1,0x4c(%ebx)
    if(ip->type == 0)
80101628:	83 c4 10             	add    $0x10,%esp
8010162b:	66 83 7b 50 00       	cmpw   $0x0,0x50(%ebx)
80101630:	0f 85 72 ff ff ff    	jne    801015a8 <ilock+0x27>
      panic("ilock: no type");
80101636:	83 ec 0c             	sub    $0xc,%esp
80101639:	68 f0 66 10 80       	push   $0x801066f0
8010163e:	e8 05 ed ff ff       	call   80100348 <panic>

80101643 <iunlock>:
{
80101643:	55                   	push   %ebp
80101644:	89 e5                	mov    %esp,%ebp
80101646:	56                   	push   %esi
80101647:	53                   	push   %ebx
80101648:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
8010164b:	85 db                	test   %ebx,%ebx
8010164d:	74 2c                	je     8010167b <iunlock+0x38>
8010164f:	8d 73 0c             	lea    0xc(%ebx),%esi
80101652:	83 ec 0c             	sub    $0xc,%esp
80101655:	56                   	push   %esi
80101656:	e8 c7 24 00 00       	call   80103b22 <holdingsleep>
8010165b:	83 c4 10             	add    $0x10,%esp
8010165e:	85 c0                	test   %eax,%eax
80101660:	74 19                	je     8010167b <iunlock+0x38>
80101662:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101666:	7e 13                	jle    8010167b <iunlock+0x38>
  releasesleep(&ip->lock);
80101668:	83 ec 0c             	sub    $0xc,%esp
8010166b:	56                   	push   %esi
8010166c:	e8 76 24 00 00       	call   80103ae7 <releasesleep>
}
80101671:	83 c4 10             	add    $0x10,%esp
80101674:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101677:	5b                   	pop    %ebx
80101678:	5e                   	pop    %esi
80101679:	5d                   	pop    %ebp
8010167a:	c3                   	ret    
    panic("iunlock");
8010167b:	83 ec 0c             	sub    $0xc,%esp
8010167e:	68 ff 66 10 80       	push   $0x801066ff
80101683:	e8 c0 ec ff ff       	call   80100348 <panic>

80101688 <iput>:
{
80101688:	55                   	push   %ebp
80101689:	89 e5                	mov    %esp,%ebp
8010168b:	57                   	push   %edi
8010168c:	56                   	push   %esi
8010168d:	53                   	push   %ebx
8010168e:	83 ec 18             	sub    $0x18,%esp
80101691:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquiresleep(&ip->lock);
80101694:	8d 73 0c             	lea    0xc(%ebx),%esi
80101697:	56                   	push   %esi
80101698:	e8 fb 23 00 00       	call   80103a98 <acquiresleep>
  if(ip->valid && ip->nlink == 0){
8010169d:	83 c4 10             	add    $0x10,%esp
801016a0:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801016a4:	74 07                	je     801016ad <iput+0x25>
801016a6:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801016ab:	74 35                	je     801016e2 <iput+0x5a>
  releasesleep(&ip->lock);
801016ad:	83 ec 0c             	sub    $0xc,%esp
801016b0:	56                   	push   %esi
801016b1:	e8 31 24 00 00       	call   80103ae7 <releasesleep>
  acquire(&icache.lock);
801016b6:	c7 04 24 e0 f9 10 80 	movl   $0x8010f9e0,(%esp)
801016bd:	e8 ea 25 00 00       	call   80103cac <acquire>
  ip->ref--;
801016c2:	8b 43 08             	mov    0x8(%ebx),%eax
801016c5:	83 e8 01             	sub    $0x1,%eax
801016c8:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
801016cb:	c7 04 24 e0 f9 10 80 	movl   $0x8010f9e0,(%esp)
801016d2:	e8 3a 26 00 00       	call   80103d11 <release>
}
801016d7:	83 c4 10             	add    $0x10,%esp
801016da:	8d 65 f4             	lea    -0xc(%ebp),%esp
801016dd:	5b                   	pop    %ebx
801016de:	5e                   	pop    %esi
801016df:	5f                   	pop    %edi
801016e0:	5d                   	pop    %ebp
801016e1:	c3                   	ret    
    acquire(&icache.lock);
801016e2:	83 ec 0c             	sub    $0xc,%esp
801016e5:	68 e0 f9 10 80       	push   $0x8010f9e0
801016ea:	e8 bd 25 00 00       	call   80103cac <acquire>
    int r = ip->ref;
801016ef:	8b 7b 08             	mov    0x8(%ebx),%edi
    release(&icache.lock);
801016f2:	c7 04 24 e0 f9 10 80 	movl   $0x8010f9e0,(%esp)
801016f9:	e8 13 26 00 00       	call   80103d11 <release>
    if(r == 1){
801016fe:	83 c4 10             	add    $0x10,%esp
80101701:	83 ff 01             	cmp    $0x1,%edi
80101704:	75 a7                	jne    801016ad <iput+0x25>
      itrunc(ip);
80101706:	89 d8                	mov    %ebx,%eax
80101708:	e8 92 fd ff ff       	call   8010149f <itrunc>
      ip->type = 0;
8010170d:	66 c7 43 50 00 00    	movw   $0x0,0x50(%ebx)
      iupdate(ip);
80101713:	83 ec 0c             	sub    $0xc,%esp
80101716:	53                   	push   %ebx
80101717:	e8 04 fd ff ff       	call   80101420 <iupdate>
      ip->valid = 0;
8010171c:	c7 43 4c 00 00 00 00 	movl   $0x0,0x4c(%ebx)
80101723:	83 c4 10             	add    $0x10,%esp
80101726:	eb 85                	jmp    801016ad <iput+0x25>

80101728 <iunlockput>:
{
80101728:	55                   	push   %ebp
80101729:	89 e5                	mov    %esp,%ebp
8010172b:	53                   	push   %ebx
8010172c:	83 ec 10             	sub    $0x10,%esp
8010172f:	8b 5d 08             	mov    0x8(%ebp),%ebx
  iunlock(ip);
80101732:	53                   	push   %ebx
80101733:	e8 0b ff ff ff       	call   80101643 <iunlock>
  iput(ip);
80101738:	89 1c 24             	mov    %ebx,(%esp)
8010173b:	e8 48 ff ff ff       	call   80101688 <iput>
}
80101740:	83 c4 10             	add    $0x10,%esp
80101743:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101746:	c9                   	leave  
80101747:	c3                   	ret    

80101748 <stati>:
{
80101748:	55                   	push   %ebp
80101749:	89 e5                	mov    %esp,%ebp
8010174b:	8b 55 08             	mov    0x8(%ebp),%edx
8010174e:	8b 45 0c             	mov    0xc(%ebp),%eax
  st->dev = ip->dev;
80101751:	8b 0a                	mov    (%edx),%ecx
80101753:	89 48 04             	mov    %ecx,0x4(%eax)
  st->ino = ip->inum;
80101756:	8b 4a 04             	mov    0x4(%edx),%ecx
80101759:	89 48 08             	mov    %ecx,0x8(%eax)
  st->type = ip->type;
8010175c:	0f b7 4a 50          	movzwl 0x50(%edx),%ecx
80101760:	66 89 08             	mov    %cx,(%eax)
  st->nlink = ip->nlink;
80101763:	0f b7 4a 56          	movzwl 0x56(%edx),%ecx
80101767:	66 89 48 0c          	mov    %cx,0xc(%eax)
  st->size = ip->size;
8010176b:	8b 52 58             	mov    0x58(%edx),%edx
8010176e:	89 50 10             	mov    %edx,0x10(%eax)
}
80101771:	5d                   	pop    %ebp
80101772:	c3                   	ret    

80101773 <readi>:
{
80101773:	55                   	push   %ebp
80101774:	89 e5                	mov    %esp,%ebp
80101776:	57                   	push   %edi
80101777:	56                   	push   %esi
80101778:	53                   	push   %ebx
80101779:	83 ec 1c             	sub    $0x1c,%esp
8010177c:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(ip->type == T_DEV){
8010177f:	8b 45 08             	mov    0x8(%ebp),%eax
80101782:	66 83 78 50 03       	cmpw   $0x3,0x50(%eax)
80101787:	74 2c                	je     801017b5 <readi+0x42>
  if(off > ip->size || off + n < off)
80101789:	8b 45 08             	mov    0x8(%ebp),%eax
8010178c:	8b 40 58             	mov    0x58(%eax),%eax
8010178f:	39 f8                	cmp    %edi,%eax
80101791:	0f 82 cb 00 00 00    	jb     80101862 <readi+0xef>
80101797:	89 fa                	mov    %edi,%edx
80101799:	03 55 14             	add    0x14(%ebp),%edx
8010179c:	0f 82 c7 00 00 00    	jb     80101869 <readi+0xf6>
  if(off + n > ip->size)
801017a2:	39 d0                	cmp    %edx,%eax
801017a4:	73 05                	jae    801017ab <readi+0x38>
    n = ip->size - off;
801017a6:	29 f8                	sub    %edi,%eax
801017a8:	89 45 14             	mov    %eax,0x14(%ebp)
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
801017ab:	be 00 00 00 00       	mov    $0x0,%esi
801017b0:	e9 8f 00 00 00       	jmp    80101844 <readi+0xd1>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
801017b5:	0f b7 40 52          	movzwl 0x52(%eax),%eax
801017b9:	66 83 f8 09          	cmp    $0x9,%ax
801017bd:	0f 87 91 00 00 00    	ja     80101854 <readi+0xe1>
801017c3:	98                   	cwtl   
801017c4:	8b 04 c5 60 f9 10 80 	mov    -0x7fef06a0(,%eax,8),%eax
801017cb:	85 c0                	test   %eax,%eax
801017cd:	0f 84 88 00 00 00    	je     8010185b <readi+0xe8>
    return devsw[ip->major].read(ip, dst, n);
801017d3:	83 ec 04             	sub    $0x4,%esp
801017d6:	ff 75 14             	pushl  0x14(%ebp)
801017d9:	ff 75 0c             	pushl  0xc(%ebp)
801017dc:	ff 75 08             	pushl  0x8(%ebp)
801017df:	ff d0                	call   *%eax
801017e1:	83 c4 10             	add    $0x10,%esp
801017e4:	eb 66                	jmp    8010184c <readi+0xd9>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
801017e6:	89 fa                	mov    %edi,%edx
801017e8:	c1 ea 09             	shr    $0x9,%edx
801017eb:	8b 45 08             	mov    0x8(%ebp),%eax
801017ee:	e8 ee f8 ff ff       	call   801010e1 <bmap>
801017f3:	83 ec 08             	sub    $0x8,%esp
801017f6:	50                   	push   %eax
801017f7:	8b 45 08             	mov    0x8(%ebp),%eax
801017fa:	ff 30                	pushl  (%eax)
801017fc:	e8 6b e9 ff ff       	call   8010016c <bread>
80101801:	89 c1                	mov    %eax,%ecx
    m = min(n - tot, BSIZE - off%BSIZE);
80101803:	89 f8                	mov    %edi,%eax
80101805:	25 ff 01 00 00       	and    $0x1ff,%eax
8010180a:	bb 00 02 00 00       	mov    $0x200,%ebx
8010180f:	29 c3                	sub    %eax,%ebx
80101811:	8b 55 14             	mov    0x14(%ebp),%edx
80101814:	29 f2                	sub    %esi,%edx
80101816:	83 c4 0c             	add    $0xc,%esp
80101819:	39 d3                	cmp    %edx,%ebx
8010181b:	0f 47 da             	cmova  %edx,%ebx
    memmove(dst, bp->data + off%BSIZE, m);
8010181e:	53                   	push   %ebx
8010181f:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
80101822:	8d 44 01 5c          	lea    0x5c(%ecx,%eax,1),%eax
80101826:	50                   	push   %eax
80101827:	ff 75 0c             	pushl  0xc(%ebp)
8010182a:	e8 a4 25 00 00       	call   80103dd3 <memmove>
    brelse(bp);
8010182f:	83 c4 04             	add    $0x4,%esp
80101832:	ff 75 e4             	pushl  -0x1c(%ebp)
80101835:	e8 9b e9 ff ff       	call   801001d5 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
8010183a:	01 de                	add    %ebx,%esi
8010183c:	01 df                	add    %ebx,%edi
8010183e:	01 5d 0c             	add    %ebx,0xc(%ebp)
80101841:	83 c4 10             	add    $0x10,%esp
80101844:	39 75 14             	cmp    %esi,0x14(%ebp)
80101847:	77 9d                	ja     801017e6 <readi+0x73>
  return n;
80101849:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010184c:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010184f:	5b                   	pop    %ebx
80101850:	5e                   	pop    %esi
80101851:	5f                   	pop    %edi
80101852:	5d                   	pop    %ebp
80101853:	c3                   	ret    
      return -1;
80101854:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101859:	eb f1                	jmp    8010184c <readi+0xd9>
8010185b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101860:	eb ea                	jmp    8010184c <readi+0xd9>
    return -1;
80101862:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101867:	eb e3                	jmp    8010184c <readi+0xd9>
80101869:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010186e:	eb dc                	jmp    8010184c <readi+0xd9>

80101870 <writei>:
{
80101870:	55                   	push   %ebp
80101871:	89 e5                	mov    %esp,%ebp
80101873:	57                   	push   %edi
80101874:	56                   	push   %esi
80101875:	53                   	push   %ebx
80101876:	83 ec 0c             	sub    $0xc,%esp
  if(ip->type == T_DEV){
80101879:	8b 45 08             	mov    0x8(%ebp),%eax
8010187c:	66 83 78 50 03       	cmpw   $0x3,0x50(%eax)
80101881:	74 2f                	je     801018b2 <writei+0x42>
  if(off > ip->size || off + n < off)
80101883:	8b 45 08             	mov    0x8(%ebp),%eax
80101886:	8b 4d 10             	mov    0x10(%ebp),%ecx
80101889:	39 48 58             	cmp    %ecx,0x58(%eax)
8010188c:	0f 82 f4 00 00 00    	jb     80101986 <writei+0x116>
80101892:	89 c8                	mov    %ecx,%eax
80101894:	03 45 14             	add    0x14(%ebp),%eax
80101897:	0f 82 f0 00 00 00    	jb     8010198d <writei+0x11d>
  if(off + n > MAXFILE*BSIZE)
8010189d:	3d 00 18 01 00       	cmp    $0x11800,%eax
801018a2:	0f 87 ec 00 00 00    	ja     80101994 <writei+0x124>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
801018a8:	be 00 00 00 00       	mov    $0x0,%esi
801018ad:	e9 94 00 00 00       	jmp    80101946 <writei+0xd6>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
801018b2:	0f b7 40 52          	movzwl 0x52(%eax),%eax
801018b6:	66 83 f8 09          	cmp    $0x9,%ax
801018ba:	0f 87 b8 00 00 00    	ja     80101978 <writei+0x108>
801018c0:	98                   	cwtl   
801018c1:	8b 04 c5 64 f9 10 80 	mov    -0x7fef069c(,%eax,8),%eax
801018c8:	85 c0                	test   %eax,%eax
801018ca:	0f 84 af 00 00 00    	je     8010197f <writei+0x10f>
    return devsw[ip->major].write(ip, src, n);
801018d0:	83 ec 04             	sub    $0x4,%esp
801018d3:	ff 75 14             	pushl  0x14(%ebp)
801018d6:	ff 75 0c             	pushl  0xc(%ebp)
801018d9:	ff 75 08             	pushl  0x8(%ebp)
801018dc:	ff d0                	call   *%eax
801018de:	83 c4 10             	add    $0x10,%esp
801018e1:	eb 7c                	jmp    8010195f <writei+0xef>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
801018e3:	8b 55 10             	mov    0x10(%ebp),%edx
801018e6:	c1 ea 09             	shr    $0x9,%edx
801018e9:	8b 45 08             	mov    0x8(%ebp),%eax
801018ec:	e8 f0 f7 ff ff       	call   801010e1 <bmap>
801018f1:	83 ec 08             	sub    $0x8,%esp
801018f4:	50                   	push   %eax
801018f5:	8b 45 08             	mov    0x8(%ebp),%eax
801018f8:	ff 30                	pushl  (%eax)
801018fa:	e8 6d e8 ff ff       	call   8010016c <bread>
801018ff:	89 c7                	mov    %eax,%edi
    m = min(n - tot, BSIZE - off%BSIZE);
80101901:	8b 45 10             	mov    0x10(%ebp),%eax
80101904:	25 ff 01 00 00       	and    $0x1ff,%eax
80101909:	bb 00 02 00 00       	mov    $0x200,%ebx
8010190e:	29 c3                	sub    %eax,%ebx
80101910:	8b 55 14             	mov    0x14(%ebp),%edx
80101913:	29 f2                	sub    %esi,%edx
80101915:	83 c4 0c             	add    $0xc,%esp
80101918:	39 d3                	cmp    %edx,%ebx
8010191a:	0f 47 da             	cmova  %edx,%ebx
    memmove(bp->data + off%BSIZE, src, m);
8010191d:	53                   	push   %ebx
8010191e:	ff 75 0c             	pushl  0xc(%ebp)
80101921:	8d 44 07 5c          	lea    0x5c(%edi,%eax,1),%eax
80101925:	50                   	push   %eax
80101926:	e8 a8 24 00 00       	call   80103dd3 <memmove>
    log_write(bp);
8010192b:	89 3c 24             	mov    %edi,(%esp)
8010192e:	e8 bb 10 00 00       	call   801029ee <log_write>
    brelse(bp);
80101933:	89 3c 24             	mov    %edi,(%esp)
80101936:	e8 9a e8 ff ff       	call   801001d5 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
8010193b:	01 de                	add    %ebx,%esi
8010193d:	01 5d 10             	add    %ebx,0x10(%ebp)
80101940:	01 5d 0c             	add    %ebx,0xc(%ebp)
80101943:	83 c4 10             	add    $0x10,%esp
80101946:	3b 75 14             	cmp    0x14(%ebp),%esi
80101949:	72 98                	jb     801018e3 <writei+0x73>
  if(n > 0 && off > ip->size){
8010194b:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
8010194f:	74 0b                	je     8010195c <writei+0xec>
80101951:	8b 45 08             	mov    0x8(%ebp),%eax
80101954:	8b 4d 10             	mov    0x10(%ebp),%ecx
80101957:	39 48 58             	cmp    %ecx,0x58(%eax)
8010195a:	72 0b                	jb     80101967 <writei+0xf7>
  return n;
8010195c:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010195f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101962:	5b                   	pop    %ebx
80101963:	5e                   	pop    %esi
80101964:	5f                   	pop    %edi
80101965:	5d                   	pop    %ebp
80101966:	c3                   	ret    
    ip->size = off;
80101967:	89 48 58             	mov    %ecx,0x58(%eax)
    iupdate(ip);
8010196a:	83 ec 0c             	sub    $0xc,%esp
8010196d:	50                   	push   %eax
8010196e:	e8 ad fa ff ff       	call   80101420 <iupdate>
80101973:	83 c4 10             	add    $0x10,%esp
80101976:	eb e4                	jmp    8010195c <writei+0xec>
      return -1;
80101978:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010197d:	eb e0                	jmp    8010195f <writei+0xef>
8010197f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101984:	eb d9                	jmp    8010195f <writei+0xef>
    return -1;
80101986:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010198b:	eb d2                	jmp    8010195f <writei+0xef>
8010198d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101992:	eb cb                	jmp    8010195f <writei+0xef>
    return -1;
80101994:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101999:	eb c4                	jmp    8010195f <writei+0xef>

8010199b <namecmp>:
{
8010199b:	55                   	push   %ebp
8010199c:	89 e5                	mov    %esp,%ebp
8010199e:	83 ec 0c             	sub    $0xc,%esp
  return strncmp(s, t, DIRSIZ);
801019a1:	6a 0e                	push   $0xe
801019a3:	ff 75 0c             	pushl  0xc(%ebp)
801019a6:	ff 75 08             	pushl  0x8(%ebp)
801019a9:	e8 8c 24 00 00       	call   80103e3a <strncmp>
}
801019ae:	c9                   	leave  
801019af:	c3                   	ret    

801019b0 <dirlookup>:
{
801019b0:	55                   	push   %ebp
801019b1:	89 e5                	mov    %esp,%ebp
801019b3:	57                   	push   %edi
801019b4:	56                   	push   %esi
801019b5:	53                   	push   %ebx
801019b6:	83 ec 1c             	sub    $0x1c,%esp
801019b9:	8b 75 08             	mov    0x8(%ebp),%esi
801019bc:	8b 7d 0c             	mov    0xc(%ebp),%edi
  if(dp->type != T_DIR)
801019bf:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
801019c4:	75 07                	jne    801019cd <dirlookup+0x1d>
  for(off = 0; off < dp->size; off += sizeof(de)){
801019c6:	bb 00 00 00 00       	mov    $0x0,%ebx
801019cb:	eb 1d                	jmp    801019ea <dirlookup+0x3a>
    panic("dirlookup not DIR");
801019cd:	83 ec 0c             	sub    $0xc,%esp
801019d0:	68 07 67 10 80       	push   $0x80106707
801019d5:	e8 6e e9 ff ff       	call   80100348 <panic>
      panic("dirlookup read");
801019da:	83 ec 0c             	sub    $0xc,%esp
801019dd:	68 19 67 10 80       	push   $0x80106719
801019e2:	e8 61 e9 ff ff       	call   80100348 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
801019e7:	83 c3 10             	add    $0x10,%ebx
801019ea:	39 5e 58             	cmp    %ebx,0x58(%esi)
801019ed:	76 48                	jbe    80101a37 <dirlookup+0x87>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801019ef:	6a 10                	push   $0x10
801019f1:	53                   	push   %ebx
801019f2:	8d 45 d8             	lea    -0x28(%ebp),%eax
801019f5:	50                   	push   %eax
801019f6:	56                   	push   %esi
801019f7:	e8 77 fd ff ff       	call   80101773 <readi>
801019fc:	83 c4 10             	add    $0x10,%esp
801019ff:	83 f8 10             	cmp    $0x10,%eax
80101a02:	75 d6                	jne    801019da <dirlookup+0x2a>
    if(de.inum == 0)
80101a04:	66 83 7d d8 00       	cmpw   $0x0,-0x28(%ebp)
80101a09:	74 dc                	je     801019e7 <dirlookup+0x37>
    if(namecmp(name, de.name) == 0){
80101a0b:	83 ec 08             	sub    $0x8,%esp
80101a0e:	8d 45 da             	lea    -0x26(%ebp),%eax
80101a11:	50                   	push   %eax
80101a12:	57                   	push   %edi
80101a13:	e8 83 ff ff ff       	call   8010199b <namecmp>
80101a18:	83 c4 10             	add    $0x10,%esp
80101a1b:	85 c0                	test   %eax,%eax
80101a1d:	75 c8                	jne    801019e7 <dirlookup+0x37>
      if(poff)
80101a1f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80101a23:	74 05                	je     80101a2a <dirlookup+0x7a>
        *poff = off;
80101a25:	8b 45 10             	mov    0x10(%ebp),%eax
80101a28:	89 18                	mov    %ebx,(%eax)
      inum = de.inum;
80101a2a:	0f b7 55 d8          	movzwl -0x28(%ebp),%edx
      return iget(dp->dev, inum);
80101a2e:	8b 06                	mov    (%esi),%eax
80101a30:	e8 52 f7 ff ff       	call   80101187 <iget>
80101a35:	eb 05                	jmp    80101a3c <dirlookup+0x8c>
  return 0;
80101a37:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101a3c:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101a3f:	5b                   	pop    %ebx
80101a40:	5e                   	pop    %esi
80101a41:	5f                   	pop    %edi
80101a42:	5d                   	pop    %ebp
80101a43:	c3                   	ret    

80101a44 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
80101a44:	55                   	push   %ebp
80101a45:	89 e5                	mov    %esp,%ebp
80101a47:	57                   	push   %edi
80101a48:	56                   	push   %esi
80101a49:	53                   	push   %ebx
80101a4a:	83 ec 1c             	sub    $0x1c,%esp
80101a4d:	89 c6                	mov    %eax,%esi
80101a4f:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101a52:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  struct inode *ip, *next;

  if(*path == '/')
80101a55:	80 38 2f             	cmpb   $0x2f,(%eax)
80101a58:	74 17                	je     80101a71 <namex+0x2d>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
80101a5a:	e8 ae 18 00 00       	call   8010330d <myproc>
80101a5f:	83 ec 0c             	sub    $0xc,%esp
80101a62:	ff 70 68             	pushl  0x68(%eax)
80101a65:	e8 e7 fa ff ff       	call   80101551 <idup>
80101a6a:	89 c3                	mov    %eax,%ebx
80101a6c:	83 c4 10             	add    $0x10,%esp
80101a6f:	eb 53                	jmp    80101ac4 <namex+0x80>
    ip = iget(ROOTDEV, ROOTINO);
80101a71:	ba 01 00 00 00       	mov    $0x1,%edx
80101a76:	b8 01 00 00 00       	mov    $0x1,%eax
80101a7b:	e8 07 f7 ff ff       	call   80101187 <iget>
80101a80:	89 c3                	mov    %eax,%ebx
80101a82:	eb 40                	jmp    80101ac4 <namex+0x80>

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
      iunlockput(ip);
80101a84:	83 ec 0c             	sub    $0xc,%esp
80101a87:	53                   	push   %ebx
80101a88:	e8 9b fc ff ff       	call   80101728 <iunlockput>
      return 0;
80101a8d:	83 c4 10             	add    $0x10,%esp
80101a90:	bb 00 00 00 00       	mov    $0x0,%ebx
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
80101a95:	89 d8                	mov    %ebx,%eax
80101a97:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101a9a:	5b                   	pop    %ebx
80101a9b:	5e                   	pop    %esi
80101a9c:	5f                   	pop    %edi
80101a9d:	5d                   	pop    %ebp
80101a9e:	c3                   	ret    
    if((next = dirlookup(ip, name, 0)) == 0){
80101a9f:	83 ec 04             	sub    $0x4,%esp
80101aa2:	6a 00                	push   $0x0
80101aa4:	ff 75 e4             	pushl  -0x1c(%ebp)
80101aa7:	53                   	push   %ebx
80101aa8:	e8 03 ff ff ff       	call   801019b0 <dirlookup>
80101aad:	89 c7                	mov    %eax,%edi
80101aaf:	83 c4 10             	add    $0x10,%esp
80101ab2:	85 c0                	test   %eax,%eax
80101ab4:	74 4a                	je     80101b00 <namex+0xbc>
    iunlockput(ip);
80101ab6:	83 ec 0c             	sub    $0xc,%esp
80101ab9:	53                   	push   %ebx
80101aba:	e8 69 fc ff ff       	call   80101728 <iunlockput>
    ip = next;
80101abf:	83 c4 10             	add    $0x10,%esp
80101ac2:	89 fb                	mov    %edi,%ebx
  while((path = skipelem(path, name)) != 0){
80101ac4:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80101ac7:	89 f0                	mov    %esi,%eax
80101ac9:	e8 77 f4 ff ff       	call   80100f45 <skipelem>
80101ace:	89 c6                	mov    %eax,%esi
80101ad0:	85 c0                	test   %eax,%eax
80101ad2:	74 3c                	je     80101b10 <namex+0xcc>
    ilock(ip);
80101ad4:	83 ec 0c             	sub    $0xc,%esp
80101ad7:	53                   	push   %ebx
80101ad8:	e8 a4 fa ff ff       	call   80101581 <ilock>
    if(ip->type != T_DIR){
80101add:	83 c4 10             	add    $0x10,%esp
80101ae0:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80101ae5:	75 9d                	jne    80101a84 <namex+0x40>
    if(nameiparent && *path == '\0'){
80101ae7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101aeb:	74 b2                	je     80101a9f <namex+0x5b>
80101aed:	80 3e 00             	cmpb   $0x0,(%esi)
80101af0:	75 ad                	jne    80101a9f <namex+0x5b>
      iunlock(ip);
80101af2:	83 ec 0c             	sub    $0xc,%esp
80101af5:	53                   	push   %ebx
80101af6:	e8 48 fb ff ff       	call   80101643 <iunlock>
      return ip;
80101afb:	83 c4 10             	add    $0x10,%esp
80101afe:	eb 95                	jmp    80101a95 <namex+0x51>
      iunlockput(ip);
80101b00:	83 ec 0c             	sub    $0xc,%esp
80101b03:	53                   	push   %ebx
80101b04:	e8 1f fc ff ff       	call   80101728 <iunlockput>
      return 0;
80101b09:	83 c4 10             	add    $0x10,%esp
80101b0c:	89 fb                	mov    %edi,%ebx
80101b0e:	eb 85                	jmp    80101a95 <namex+0x51>
  if(nameiparent){
80101b10:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101b14:	0f 84 7b ff ff ff    	je     80101a95 <namex+0x51>
    iput(ip);
80101b1a:	83 ec 0c             	sub    $0xc,%esp
80101b1d:	53                   	push   %ebx
80101b1e:	e8 65 fb ff ff       	call   80101688 <iput>
    return 0;
80101b23:	83 c4 10             	add    $0x10,%esp
80101b26:	bb 00 00 00 00       	mov    $0x0,%ebx
80101b2b:	e9 65 ff ff ff       	jmp    80101a95 <namex+0x51>

80101b30 <dirlink>:
{
80101b30:	55                   	push   %ebp
80101b31:	89 e5                	mov    %esp,%ebp
80101b33:	57                   	push   %edi
80101b34:	56                   	push   %esi
80101b35:	53                   	push   %ebx
80101b36:	83 ec 20             	sub    $0x20,%esp
80101b39:	8b 5d 08             	mov    0x8(%ebp),%ebx
80101b3c:	8b 7d 0c             	mov    0xc(%ebp),%edi
  if((ip = dirlookup(dp, name, 0)) != 0){
80101b3f:	6a 00                	push   $0x0
80101b41:	57                   	push   %edi
80101b42:	53                   	push   %ebx
80101b43:	e8 68 fe ff ff       	call   801019b0 <dirlookup>
80101b48:	83 c4 10             	add    $0x10,%esp
80101b4b:	85 c0                	test   %eax,%eax
80101b4d:	75 2d                	jne    80101b7c <dirlink+0x4c>
  for(off = 0; off < dp->size; off += sizeof(de)){
80101b4f:	b8 00 00 00 00       	mov    $0x0,%eax
80101b54:	89 c6                	mov    %eax,%esi
80101b56:	39 43 58             	cmp    %eax,0x58(%ebx)
80101b59:	76 41                	jbe    80101b9c <dirlink+0x6c>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80101b5b:	6a 10                	push   $0x10
80101b5d:	50                   	push   %eax
80101b5e:	8d 45 d8             	lea    -0x28(%ebp),%eax
80101b61:	50                   	push   %eax
80101b62:	53                   	push   %ebx
80101b63:	e8 0b fc ff ff       	call   80101773 <readi>
80101b68:	83 c4 10             	add    $0x10,%esp
80101b6b:	83 f8 10             	cmp    $0x10,%eax
80101b6e:	75 1f                	jne    80101b8f <dirlink+0x5f>
    if(de.inum == 0)
80101b70:	66 83 7d d8 00       	cmpw   $0x0,-0x28(%ebp)
80101b75:	74 25                	je     80101b9c <dirlink+0x6c>
  for(off = 0; off < dp->size; off += sizeof(de)){
80101b77:	8d 46 10             	lea    0x10(%esi),%eax
80101b7a:	eb d8                	jmp    80101b54 <dirlink+0x24>
    iput(ip);
80101b7c:	83 ec 0c             	sub    $0xc,%esp
80101b7f:	50                   	push   %eax
80101b80:	e8 03 fb ff ff       	call   80101688 <iput>
    return -1;
80101b85:	83 c4 10             	add    $0x10,%esp
80101b88:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101b8d:	eb 3d                	jmp    80101bcc <dirlink+0x9c>
      panic("dirlink read");
80101b8f:	83 ec 0c             	sub    $0xc,%esp
80101b92:	68 28 67 10 80       	push   $0x80106728
80101b97:	e8 ac e7 ff ff       	call   80100348 <panic>
  strncpy(de.name, name, DIRSIZ);
80101b9c:	83 ec 04             	sub    $0x4,%esp
80101b9f:	6a 0e                	push   $0xe
80101ba1:	57                   	push   %edi
80101ba2:	8d 7d d8             	lea    -0x28(%ebp),%edi
80101ba5:	8d 45 da             	lea    -0x26(%ebp),%eax
80101ba8:	50                   	push   %eax
80101ba9:	e8 c9 22 00 00       	call   80103e77 <strncpy>
  de.inum = inum;
80101bae:	8b 45 10             	mov    0x10(%ebp),%eax
80101bb1:	66 89 45 d8          	mov    %ax,-0x28(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80101bb5:	6a 10                	push   $0x10
80101bb7:	56                   	push   %esi
80101bb8:	57                   	push   %edi
80101bb9:	53                   	push   %ebx
80101bba:	e8 b1 fc ff ff       	call   80101870 <writei>
80101bbf:	83 c4 20             	add    $0x20,%esp
80101bc2:	83 f8 10             	cmp    $0x10,%eax
80101bc5:	75 0d                	jne    80101bd4 <dirlink+0xa4>
  return 0;
80101bc7:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101bcc:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101bcf:	5b                   	pop    %ebx
80101bd0:	5e                   	pop    %esi
80101bd1:	5f                   	pop    %edi
80101bd2:	5d                   	pop    %ebp
80101bd3:	c3                   	ret    
    panic("dirlink");
80101bd4:	83 ec 0c             	sub    $0xc,%esp
80101bd7:	68 34 6d 10 80       	push   $0x80106d34
80101bdc:	e8 67 e7 ff ff       	call   80100348 <panic>

80101be1 <namei>:

struct inode*
namei(char *path)
{
80101be1:	55                   	push   %ebp
80101be2:	89 e5                	mov    %esp,%ebp
80101be4:	83 ec 18             	sub    $0x18,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80101be7:	8d 4d ea             	lea    -0x16(%ebp),%ecx
80101bea:	ba 00 00 00 00       	mov    $0x0,%edx
80101bef:	8b 45 08             	mov    0x8(%ebp),%eax
80101bf2:	e8 4d fe ff ff       	call   80101a44 <namex>
}
80101bf7:	c9                   	leave  
80101bf8:	c3                   	ret    

80101bf9 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80101bf9:	55                   	push   %ebp
80101bfa:	89 e5                	mov    %esp,%ebp
80101bfc:	83 ec 08             	sub    $0x8,%esp
  return namex(path, 1, name);
80101bff:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80101c02:	ba 01 00 00 00       	mov    $0x1,%edx
80101c07:	8b 45 08             	mov    0x8(%ebp),%eax
80101c0a:	e8 35 fe ff ff       	call   80101a44 <namex>
}
80101c0f:	c9                   	leave  
80101c10:	c3                   	ret    

80101c11 <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
80101c11:	55                   	push   %ebp
80101c12:	89 e5                	mov    %esp,%ebp
80101c14:	89 c1                	mov    %eax,%ecx
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80101c16:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101c1b:	ec                   	in     (%dx),%al
80101c1c:	89 c2                	mov    %eax,%edx
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY)
80101c1e:	83 e0 c0             	and    $0xffffffc0,%eax
80101c21:	3c 40                	cmp    $0x40,%al
80101c23:	75 f1                	jne    80101c16 <idewait+0x5>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80101c25:	85 c9                	test   %ecx,%ecx
80101c27:	74 0c                	je     80101c35 <idewait+0x24>
80101c29:	f6 c2 21             	test   $0x21,%dl
80101c2c:	75 0e                	jne    80101c3c <idewait+0x2b>
    return -1;
  return 0;
80101c2e:	b8 00 00 00 00       	mov    $0x0,%eax
80101c33:	eb 05                	jmp    80101c3a <idewait+0x29>
80101c35:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101c3a:	5d                   	pop    %ebp
80101c3b:	c3                   	ret    
    return -1;
80101c3c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101c41:	eb f7                	jmp    80101c3a <idewait+0x29>

80101c43 <idestart>:
}

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80101c43:	55                   	push   %ebp
80101c44:	89 e5                	mov    %esp,%ebp
80101c46:	56                   	push   %esi
80101c47:	53                   	push   %ebx
  if(b == 0)
80101c48:	85 c0                	test   %eax,%eax
80101c4a:	74 7d                	je     80101cc9 <idestart+0x86>
80101c4c:	89 c6                	mov    %eax,%esi
    panic("idestart");
  if(b->blockno >= FSSIZE)
80101c4e:	8b 58 08             	mov    0x8(%eax),%ebx
80101c51:	81 fb e7 03 00 00    	cmp    $0x3e7,%ebx
80101c57:	77 7d                	ja     80101cd6 <idestart+0x93>
  int read_cmd = (sector_per_block == 1) ? IDE_CMD_READ :  IDE_CMD_RDMUL;
  int write_cmd = (sector_per_block == 1) ? IDE_CMD_WRITE : IDE_CMD_WRMUL;

  if (sector_per_block > 7) panic("idestart");

  idewait(0);
80101c59:	b8 00 00 00 00       	mov    $0x0,%eax
80101c5e:	e8 ae ff ff ff       	call   80101c11 <idewait>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101c63:	b8 00 00 00 00       	mov    $0x0,%eax
80101c68:	ba f6 03 00 00       	mov    $0x3f6,%edx
80101c6d:	ee                   	out    %al,(%dx)
80101c6e:	b8 01 00 00 00       	mov    $0x1,%eax
80101c73:	ba f2 01 00 00       	mov    $0x1f2,%edx
80101c78:	ee                   	out    %al,(%dx)
80101c79:	ba f3 01 00 00       	mov    $0x1f3,%edx
80101c7e:	89 d8                	mov    %ebx,%eax
80101c80:	ee                   	out    %al,(%dx)
  outb(0x3f6, 0);  // generate interrupt
  outb(0x1f2, sector_per_block);  // number of sectors
  outb(0x1f3, sector & 0xff);
  outb(0x1f4, (sector >> 8) & 0xff);
80101c81:	89 d8                	mov    %ebx,%eax
80101c83:	c1 f8 08             	sar    $0x8,%eax
80101c86:	ba f4 01 00 00       	mov    $0x1f4,%edx
80101c8b:	ee                   	out    %al,(%dx)
  outb(0x1f5, (sector >> 16) & 0xff);
80101c8c:	89 d8                	mov    %ebx,%eax
80101c8e:	c1 f8 10             	sar    $0x10,%eax
80101c91:	ba f5 01 00 00       	mov    $0x1f5,%edx
80101c96:	ee                   	out    %al,(%dx)
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((sector>>24)&0x0f));
80101c97:	0f b6 46 04          	movzbl 0x4(%esi),%eax
80101c9b:	c1 e0 04             	shl    $0x4,%eax
80101c9e:	83 e0 10             	and    $0x10,%eax
80101ca1:	c1 fb 18             	sar    $0x18,%ebx
80101ca4:	83 e3 0f             	and    $0xf,%ebx
80101ca7:	09 d8                	or     %ebx,%eax
80101ca9:	83 c8 e0             	or     $0xffffffe0,%eax
80101cac:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101cb1:	ee                   	out    %al,(%dx)
  if(b->flags & B_DIRTY){
80101cb2:	f6 06 04             	testb  $0x4,(%esi)
80101cb5:	75 2c                	jne    80101ce3 <idestart+0xa0>
80101cb7:	b8 20 00 00 00       	mov    $0x20,%eax
80101cbc:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101cc1:	ee                   	out    %al,(%dx)
    outb(0x1f7, write_cmd);
    outsl(0x1f0, b->data, BSIZE/4);
  } else {
    outb(0x1f7, read_cmd);
  }
}
80101cc2:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101cc5:	5b                   	pop    %ebx
80101cc6:	5e                   	pop    %esi
80101cc7:	5d                   	pop    %ebp
80101cc8:	c3                   	ret    
    panic("idestart");
80101cc9:	83 ec 0c             	sub    $0xc,%esp
80101ccc:	68 8b 67 10 80       	push   $0x8010678b
80101cd1:	e8 72 e6 ff ff       	call   80100348 <panic>
    panic("incorrect blockno");
80101cd6:	83 ec 0c             	sub    $0xc,%esp
80101cd9:	68 94 67 10 80       	push   $0x80106794
80101cde:	e8 65 e6 ff ff       	call   80100348 <panic>
80101ce3:	b8 30 00 00 00       	mov    $0x30,%eax
80101ce8:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101ced:	ee                   	out    %al,(%dx)
    outsl(0x1f0, b->data, BSIZE/4);
80101cee:	83 c6 5c             	add    $0x5c,%esi
  asm volatile("cld; rep outsl" :
80101cf1:	b9 80 00 00 00       	mov    $0x80,%ecx
80101cf6:	ba f0 01 00 00       	mov    $0x1f0,%edx
80101cfb:	fc                   	cld    
80101cfc:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80101cfe:	eb c2                	jmp    80101cc2 <idestart+0x7f>

80101d00 <ideinit>:
{
80101d00:	55                   	push   %ebp
80101d01:	89 e5                	mov    %esp,%ebp
80101d03:	83 ec 10             	sub    $0x10,%esp
  initlock(&idelock, "ide");
80101d06:	68 a6 67 10 80       	push   $0x801067a6
80101d0b:	68 80 95 10 80       	push   $0x80109580
80101d10:	e8 5b 1e 00 00       	call   80103b70 <initlock>
  ioapicenable(IRQ_IDE, ncpu - 1);
80101d15:	83 c4 08             	add    $0x8,%esp
80101d18:	a1 20 1d 19 80       	mov    0x80191d20,%eax
80101d1d:	83 e8 01             	sub    $0x1,%eax
80101d20:	50                   	push   %eax
80101d21:	6a 0e                	push   $0xe
80101d23:	e8 56 02 00 00       	call   80101f7e <ioapicenable>
  idewait(0);
80101d28:	b8 00 00 00 00       	mov    $0x0,%eax
80101d2d:	e8 df fe ff ff       	call   80101c11 <idewait>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101d32:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
80101d37:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101d3c:	ee                   	out    %al,(%dx)
  for(i=0; i<1000; i++){
80101d3d:	83 c4 10             	add    $0x10,%esp
80101d40:	b9 00 00 00 00       	mov    $0x0,%ecx
80101d45:	81 f9 e7 03 00 00    	cmp    $0x3e7,%ecx
80101d4b:	7f 19                	jg     80101d66 <ideinit+0x66>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80101d4d:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101d52:	ec                   	in     (%dx),%al
    if(inb(0x1f7) != 0){
80101d53:	84 c0                	test   %al,%al
80101d55:	75 05                	jne    80101d5c <ideinit+0x5c>
  for(i=0; i<1000; i++){
80101d57:	83 c1 01             	add    $0x1,%ecx
80101d5a:	eb e9                	jmp    80101d45 <ideinit+0x45>
      havedisk1 = 1;
80101d5c:	c7 05 60 95 10 80 01 	movl   $0x1,0x80109560
80101d63:	00 00 00 
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101d66:	b8 e0 ff ff ff       	mov    $0xffffffe0,%eax
80101d6b:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101d70:	ee                   	out    %al,(%dx)
}
80101d71:	c9                   	leave  
80101d72:	c3                   	ret    

80101d73 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80101d73:	55                   	push   %ebp
80101d74:	89 e5                	mov    %esp,%ebp
80101d76:	57                   	push   %edi
80101d77:	53                   	push   %ebx
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
80101d78:	83 ec 0c             	sub    $0xc,%esp
80101d7b:	68 80 95 10 80       	push   $0x80109580
80101d80:	e8 27 1f 00 00       	call   80103cac <acquire>

  if((b = idequeue) == 0){
80101d85:	8b 1d 64 95 10 80    	mov    0x80109564,%ebx
80101d8b:	83 c4 10             	add    $0x10,%esp
80101d8e:	85 db                	test   %ebx,%ebx
80101d90:	74 48                	je     80101dda <ideintr+0x67>
    release(&idelock);
    return;
  }
  idequeue = b->qnext;
80101d92:	8b 43 58             	mov    0x58(%ebx),%eax
80101d95:	a3 64 95 10 80       	mov    %eax,0x80109564

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80101d9a:	f6 03 04             	testb  $0x4,(%ebx)
80101d9d:	74 4d                	je     80101dec <ideintr+0x79>
    insl(0x1f0, b->data, BSIZE/4);

  // Wake process waiting for this buf.
  b->flags |= B_VALID;
80101d9f:	8b 03                	mov    (%ebx),%eax
80101da1:	83 c8 02             	or     $0x2,%eax
  b->flags &= ~B_DIRTY;
80101da4:	83 e0 fb             	and    $0xfffffffb,%eax
80101da7:	89 03                	mov    %eax,(%ebx)
  wakeup(b);
80101da9:	83 ec 0c             	sub    $0xc,%esp
80101dac:	53                   	push   %ebx
80101dad:	e8 64 1b 00 00       	call   80103916 <wakeup>

  // Start disk on next buf in queue.
  if(idequeue != 0)
80101db2:	a1 64 95 10 80       	mov    0x80109564,%eax
80101db7:	83 c4 10             	add    $0x10,%esp
80101dba:	85 c0                	test   %eax,%eax
80101dbc:	74 05                	je     80101dc3 <ideintr+0x50>
    idestart(idequeue);
80101dbe:	e8 80 fe ff ff       	call   80101c43 <idestart>

  release(&idelock);
80101dc3:	83 ec 0c             	sub    $0xc,%esp
80101dc6:	68 80 95 10 80       	push   $0x80109580
80101dcb:	e8 41 1f 00 00       	call   80103d11 <release>
80101dd0:	83 c4 10             	add    $0x10,%esp
}
80101dd3:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101dd6:	5b                   	pop    %ebx
80101dd7:	5f                   	pop    %edi
80101dd8:	5d                   	pop    %ebp
80101dd9:	c3                   	ret    
    release(&idelock);
80101dda:	83 ec 0c             	sub    $0xc,%esp
80101ddd:	68 80 95 10 80       	push   $0x80109580
80101de2:	e8 2a 1f 00 00       	call   80103d11 <release>
    return;
80101de7:	83 c4 10             	add    $0x10,%esp
80101dea:	eb e7                	jmp    80101dd3 <ideintr+0x60>
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80101dec:	b8 01 00 00 00       	mov    $0x1,%eax
80101df1:	e8 1b fe ff ff       	call   80101c11 <idewait>
80101df6:	85 c0                	test   %eax,%eax
80101df8:	78 a5                	js     80101d9f <ideintr+0x2c>
    insl(0x1f0, b->data, BSIZE/4);
80101dfa:	8d 7b 5c             	lea    0x5c(%ebx),%edi
  asm volatile("cld; rep insl" :
80101dfd:	b9 80 00 00 00       	mov    $0x80,%ecx
80101e02:	ba f0 01 00 00       	mov    $0x1f0,%edx
80101e07:	fc                   	cld    
80101e08:	f3 6d                	rep insl (%dx),%es:(%edi)
80101e0a:	eb 93                	jmp    80101d9f <ideintr+0x2c>

80101e0c <iderw>:
// Sync buf with disk.
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80101e0c:	55                   	push   %ebp
80101e0d:	89 e5                	mov    %esp,%ebp
80101e0f:	53                   	push   %ebx
80101e10:	83 ec 10             	sub    $0x10,%esp
80101e13:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct buf **pp;

  if(!holdingsleep(&b->lock))
80101e16:	8d 43 0c             	lea    0xc(%ebx),%eax
80101e19:	50                   	push   %eax
80101e1a:	e8 03 1d 00 00       	call   80103b22 <holdingsleep>
80101e1f:	83 c4 10             	add    $0x10,%esp
80101e22:	85 c0                	test   %eax,%eax
80101e24:	74 37                	je     80101e5d <iderw+0x51>
    panic("iderw: buf not locked");
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80101e26:	8b 03                	mov    (%ebx),%eax
80101e28:	83 e0 06             	and    $0x6,%eax
80101e2b:	83 f8 02             	cmp    $0x2,%eax
80101e2e:	74 3a                	je     80101e6a <iderw+0x5e>
    panic("iderw: nothing to do");
  if(b->dev != 0 && !havedisk1)
80101e30:	83 7b 04 00          	cmpl   $0x0,0x4(%ebx)
80101e34:	74 09                	je     80101e3f <iderw+0x33>
80101e36:	83 3d 60 95 10 80 00 	cmpl   $0x0,0x80109560
80101e3d:	74 38                	je     80101e77 <iderw+0x6b>
    panic("iderw: ide disk 1 not present");

  acquire(&idelock);  //DOC:acquire-lock
80101e3f:	83 ec 0c             	sub    $0xc,%esp
80101e42:	68 80 95 10 80       	push   $0x80109580
80101e47:	e8 60 1e 00 00       	call   80103cac <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80101e4c:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e53:	83 c4 10             	add    $0x10,%esp
80101e56:	ba 64 95 10 80       	mov    $0x80109564,%edx
80101e5b:	eb 2a                	jmp    80101e87 <iderw+0x7b>
    panic("iderw: buf not locked");
80101e5d:	83 ec 0c             	sub    $0xc,%esp
80101e60:	68 aa 67 10 80       	push   $0x801067aa
80101e65:	e8 de e4 ff ff       	call   80100348 <panic>
    panic("iderw: nothing to do");
80101e6a:	83 ec 0c             	sub    $0xc,%esp
80101e6d:	68 c0 67 10 80       	push   $0x801067c0
80101e72:	e8 d1 e4 ff ff       	call   80100348 <panic>
    panic("iderw: ide disk 1 not present");
80101e77:	83 ec 0c             	sub    $0xc,%esp
80101e7a:	68 d5 67 10 80       	push   $0x801067d5
80101e7f:	e8 c4 e4 ff ff       	call   80100348 <panic>
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e84:	8d 50 58             	lea    0x58(%eax),%edx
80101e87:	8b 02                	mov    (%edx),%eax
80101e89:	85 c0                	test   %eax,%eax
80101e8b:	75 f7                	jne    80101e84 <iderw+0x78>
    ;
  *pp = b;
80101e8d:	89 1a                	mov    %ebx,(%edx)

  // Start disk if necessary.
  if(idequeue == b)
80101e8f:	39 1d 64 95 10 80    	cmp    %ebx,0x80109564
80101e95:	75 1a                	jne    80101eb1 <iderw+0xa5>
    idestart(b);
80101e97:	89 d8                	mov    %ebx,%eax
80101e99:	e8 a5 fd ff ff       	call   80101c43 <idestart>
80101e9e:	eb 11                	jmp    80101eb1 <iderw+0xa5>

  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
    sleep(b, &idelock);
80101ea0:	83 ec 08             	sub    $0x8,%esp
80101ea3:	68 80 95 10 80       	push   $0x80109580
80101ea8:	53                   	push   %ebx
80101ea9:	e8 03 19 00 00       	call   801037b1 <sleep>
80101eae:	83 c4 10             	add    $0x10,%esp
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80101eb1:	8b 03                	mov    (%ebx),%eax
80101eb3:	83 e0 06             	and    $0x6,%eax
80101eb6:	83 f8 02             	cmp    $0x2,%eax
80101eb9:	75 e5                	jne    80101ea0 <iderw+0x94>
  }


  release(&idelock);
80101ebb:	83 ec 0c             	sub    $0xc,%esp
80101ebe:	68 80 95 10 80       	push   $0x80109580
80101ec3:	e8 49 1e 00 00       	call   80103d11 <release>
}
80101ec8:	83 c4 10             	add    $0x10,%esp
80101ecb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101ece:	c9                   	leave  
80101ecf:	c3                   	ret    

80101ed0 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80101ed0:	55                   	push   %ebp
80101ed1:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80101ed3:	8b 15 34 16 11 80    	mov    0x80111634,%edx
80101ed9:	89 02                	mov    %eax,(%edx)
  return ioapic->data;
80101edb:	a1 34 16 11 80       	mov    0x80111634,%eax
80101ee0:	8b 40 10             	mov    0x10(%eax),%eax
}
80101ee3:	5d                   	pop    %ebp
80101ee4:	c3                   	ret    

80101ee5 <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80101ee5:	55                   	push   %ebp
80101ee6:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80101ee8:	8b 0d 34 16 11 80    	mov    0x80111634,%ecx
80101eee:	89 01                	mov    %eax,(%ecx)
  ioapic->data = data;
80101ef0:	a1 34 16 11 80       	mov    0x80111634,%eax
80101ef5:	89 50 10             	mov    %edx,0x10(%eax)
}
80101ef8:	5d                   	pop    %ebp
80101ef9:	c3                   	ret    

80101efa <ioapicinit>:

void
ioapicinit(void)
{
80101efa:	55                   	push   %ebp
80101efb:	89 e5                	mov    %esp,%ebp
80101efd:	57                   	push   %edi
80101efe:	56                   	push   %esi
80101eff:	53                   	push   %ebx
80101f00:	83 ec 0c             	sub    $0xc,%esp
  int i, id, maxintr;

  ioapic = (volatile struct ioapic*)IOAPIC;
80101f03:	c7 05 34 16 11 80 00 	movl   $0xfec00000,0x80111634
80101f0a:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80101f0d:	b8 01 00 00 00       	mov    $0x1,%eax
80101f12:	e8 b9 ff ff ff       	call   80101ed0 <ioapicread>
80101f17:	c1 e8 10             	shr    $0x10,%eax
80101f1a:	0f b6 f8             	movzbl %al,%edi
  id = ioapicread(REG_ID) >> 24;
80101f1d:	b8 00 00 00 00       	mov    $0x0,%eax
80101f22:	e8 a9 ff ff ff       	call   80101ed0 <ioapicread>
80101f27:	c1 e8 18             	shr    $0x18,%eax
  if(id != ioapicid)
80101f2a:	0f b6 15 80 17 19 80 	movzbl 0x80191780,%edx
80101f31:	39 c2                	cmp    %eax,%edx
80101f33:	75 07                	jne    80101f3c <ioapicinit+0x42>
{
80101f35:	bb 00 00 00 00       	mov    $0x0,%ebx
80101f3a:	eb 36                	jmp    80101f72 <ioapicinit+0x78>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80101f3c:	83 ec 0c             	sub    $0xc,%esp
80101f3f:	68 f4 67 10 80       	push   $0x801067f4
80101f44:	e8 c2 e6 ff ff       	call   8010060b <cprintf>
80101f49:	83 c4 10             	add    $0x10,%esp
80101f4c:	eb e7                	jmp    80101f35 <ioapicinit+0x3b>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80101f4e:	8d 53 20             	lea    0x20(%ebx),%edx
80101f51:	81 ca 00 00 01 00    	or     $0x10000,%edx
80101f57:	8d 74 1b 10          	lea    0x10(%ebx,%ebx,1),%esi
80101f5b:	89 f0                	mov    %esi,%eax
80101f5d:	e8 83 ff ff ff       	call   80101ee5 <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80101f62:	8d 46 01             	lea    0x1(%esi),%eax
80101f65:	ba 00 00 00 00       	mov    $0x0,%edx
80101f6a:	e8 76 ff ff ff       	call   80101ee5 <ioapicwrite>
  for(i = 0; i <= maxintr; i++){
80101f6f:	83 c3 01             	add    $0x1,%ebx
80101f72:	39 fb                	cmp    %edi,%ebx
80101f74:	7e d8                	jle    80101f4e <ioapicinit+0x54>
  }
}
80101f76:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101f79:	5b                   	pop    %ebx
80101f7a:	5e                   	pop    %esi
80101f7b:	5f                   	pop    %edi
80101f7c:	5d                   	pop    %ebp
80101f7d:	c3                   	ret    

80101f7e <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80101f7e:	55                   	push   %ebp
80101f7f:	89 e5                	mov    %esp,%ebp
80101f81:	53                   	push   %ebx
80101f82:	8b 45 08             	mov    0x8(%ebp),%eax
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80101f85:	8d 50 20             	lea    0x20(%eax),%edx
80101f88:	8d 5c 00 10          	lea    0x10(%eax,%eax,1),%ebx
80101f8c:	89 d8                	mov    %ebx,%eax
80101f8e:	e8 52 ff ff ff       	call   80101ee5 <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80101f93:	8b 55 0c             	mov    0xc(%ebp),%edx
80101f96:	c1 e2 18             	shl    $0x18,%edx
80101f99:	8d 43 01             	lea    0x1(%ebx),%eax
80101f9c:	e8 44 ff ff ff       	call   80101ee5 <ioapicwrite>
}
80101fa1:	5b                   	pop    %ebx
80101fa2:	5d                   	pop    %ebp
80101fa3:	c3                   	ret    

80101fa4 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80101fa4:	55                   	push   %ebp
80101fa5:	89 e5                	mov    %esp,%ebp
80101fa7:	53                   	push   %ebx
80101fa8:	83 ec 04             	sub    $0x4,%esp
80101fab:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct run *r;

  if((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
80101fae:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
80101fb4:	75 4c                	jne    80102002 <kfree+0x5e>
80101fb6:	81 fb c8 44 19 80    	cmp    $0x801944c8,%ebx
80101fbc:	72 44                	jb     80102002 <kfree+0x5e>
80101fbe:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80101fc4:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80101fc9:	77 37                	ja     80102002 <kfree+0x5e>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80101fcb:	83 ec 04             	sub    $0x4,%esp
80101fce:	68 00 10 00 00       	push   $0x1000
80101fd3:	6a 01                	push   $0x1
80101fd5:	53                   	push   %ebx
80101fd6:	e8 7d 1d 00 00       	call   80103d58 <memset>

  if(kmem.use_lock)
80101fdb:	83 c4 10             	add    $0x10,%esp
80101fde:	83 3d 74 16 11 80 00 	cmpl   $0x0,0x80111674
80101fe5:	75 28                	jne    8010200f <kfree+0x6b>
    acquire(&kmem.lock);
  r = (struct run*)v;
  r->next = kmem.freelist;
80101fe7:	a1 78 16 11 80       	mov    0x80111678,%eax
80101fec:	89 03                	mov    %eax,(%ebx)
  kmem.freelist = r;
80101fee:	89 1d 78 16 11 80    	mov    %ebx,0x80111678
  if(kmem.use_lock)
80101ff4:	83 3d 74 16 11 80 00 	cmpl   $0x0,0x80111674
80101ffb:	75 24                	jne    80102021 <kfree+0x7d>
    release(&kmem.lock);
}
80101ffd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102000:	c9                   	leave  
80102001:	c3                   	ret    
    panic("kfree");
80102002:	83 ec 0c             	sub    $0xc,%esp
80102005:	68 26 68 10 80       	push   $0x80106826
8010200a:	e8 39 e3 ff ff       	call   80100348 <panic>
    acquire(&kmem.lock);
8010200f:	83 ec 0c             	sub    $0xc,%esp
80102012:	68 40 16 11 80       	push   $0x80111640
80102017:	e8 90 1c 00 00       	call   80103cac <acquire>
8010201c:	83 c4 10             	add    $0x10,%esp
8010201f:	eb c6                	jmp    80101fe7 <kfree+0x43>
    release(&kmem.lock);
80102021:	83 ec 0c             	sub    $0xc,%esp
80102024:	68 40 16 11 80       	push   $0x80111640
80102029:	e8 e3 1c 00 00       	call   80103d11 <release>
8010202e:	83 c4 10             	add    $0x10,%esp
}
80102031:	eb ca                	jmp    80101ffd <kfree+0x59>

80102033 <freerange>:
{
80102033:	55                   	push   %ebp
80102034:	89 e5                	mov    %esp,%ebp
80102036:	56                   	push   %esi
80102037:	53                   	push   %ebx
80102038:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  p = (char*)PGROUNDUP((uint)vstart);
8010203b:	8b 45 08             	mov    0x8(%ebp),%eax
8010203e:	05 ff 0f 00 00       	add    $0xfff,%eax
80102043:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102048:	eb 0e                	jmp    80102058 <freerange+0x25>
    kfree(p);
8010204a:	83 ec 0c             	sub    $0xc,%esp
8010204d:	50                   	push   %eax
8010204e:	e8 51 ff ff ff       	call   80101fa4 <kfree>
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102053:	83 c4 10             	add    $0x10,%esp
80102056:	89 f0                	mov    %esi,%eax
80102058:	8d b0 00 10 00 00    	lea    0x1000(%eax),%esi
8010205e:	39 de                	cmp    %ebx,%esi
80102060:	76 e8                	jbe    8010204a <freerange+0x17>
}
80102062:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102065:	5b                   	pop    %ebx
80102066:	5e                   	pop    %esi
80102067:	5d                   	pop    %ebp
80102068:	c3                   	ret    

80102069 <kinit1>:
{
80102069:	55                   	push   %ebp
8010206a:	89 e5                	mov    %esp,%ebp
8010206c:	83 ec 10             	sub    $0x10,%esp
  initlock(&kmem.lock, "kmem");
8010206f:	68 2c 68 10 80       	push   $0x8010682c
80102074:	68 40 16 11 80       	push   $0x80111640
80102079:	e8 f2 1a 00 00       	call   80103b70 <initlock>
  kmem.use_lock = 0;
8010207e:	c7 05 74 16 11 80 00 	movl   $0x0,0x80111674
80102085:	00 00 00 
  freerange(vstart, vend);
80102088:	83 c4 08             	add    $0x8,%esp
8010208b:	ff 75 0c             	pushl  0xc(%ebp)
8010208e:	ff 75 08             	pushl  0x8(%ebp)
80102091:	e8 9d ff ff ff       	call   80102033 <freerange>
}
80102096:	83 c4 10             	add    $0x10,%esp
80102099:	c9                   	leave  
8010209a:	c3                   	ret    

8010209b <kinit2>:
{
8010209b:	55                   	push   %ebp
8010209c:	89 e5                	mov    %esp,%ebp
8010209e:	83 ec 10             	sub    $0x10,%esp
  freerange(vstart, vend);
801020a1:	ff 75 0c             	pushl  0xc(%ebp)
801020a4:	ff 75 08             	pushl  0x8(%ebp)
801020a7:	e8 87 ff ff ff       	call   80102033 <freerange>
  kmem.use_lock = 1;
801020ac:	c7 05 74 16 11 80 01 	movl   $0x1,0x80111674
801020b3:	00 00 00 
  for(int i = 0; i < 16384; i++) {
801020b6:	83 c4 10             	add    $0x10,%esp
801020b9:	b8 00 00 00 00       	mov    $0x0,%eax
801020be:	eb 19                	jmp    801020d9 <kinit2+0x3e>
  	framearr[i] = -1;
801020c0:	c7 04 85 80 16 15 80 	movl   $0xffffffff,-0x7feae980(,%eax,4)
801020c7:	ff ff ff ff 
  	pidarr[i] = -1;
801020cb:	c7 04 85 80 16 11 80 	movl   $0xffffffff,-0x7feee980(,%eax,4)
801020d2:	ff ff ff ff 
  for(int i = 0; i < 16384; i++) {
801020d6:	83 c0 01             	add    $0x1,%eax
801020d9:	3d ff 3f 00 00       	cmp    $0x3fff,%eax
801020de:	7e e0                	jle    801020c0 <kinit2+0x25>
	totalframes = 0;
801020e0:	c7 05 7c 16 11 80 00 	movl   $0x0,0x8011167c
801020e7:	00 00 00 
}
801020ea:	c9                   	leave  
801020eb:	c3                   	ret    

801020ec <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
801020ec:	55                   	push   %ebp
801020ed:	89 e5                	mov    %esp,%ebp
801020ef:	53                   	push   %ebx
801020f0:	83 ec 04             	sub    $0x4,%esp
  struct run *r;

  if(kmem.use_lock)
801020f3:	83 3d 74 16 11 80 00 	cmpl   $0x0,0x80111674
801020fa:	75 52                	jne    8010214e <kalloc+0x62>
    acquire(&kmem.lock);
  r = kmem.freelist;
801020fc:	8b 1d 78 16 11 80    	mov    0x80111678,%ebx
  if(r && r->next)
80102102:	85 db                	test   %ebx,%ebx
80102104:	74 0d                	je     80102113 <kalloc+0x27>
80102106:	8b 03                	mov    (%ebx),%eax
80102108:	85 c0                	test   %eax,%eax
8010210a:	74 07                	je     80102113 <kalloc+0x27>
    kmem.freelist = (r->next)->next;
8010210c:	8b 00                	mov    (%eax),%eax
8010210e:	a3 78 16 11 80       	mov    %eax,0x80111678
  int pa;
  int framenum;
  pa = V2P(r);
80102113:	8d 93 00 00 00 80    	lea    -0x80000000(%ebx),%edx
  framenum = (pa >> 12) & 0xffff;
80102119:	c1 fa 0c             	sar    $0xc,%edx
8010211c:	0f b7 d2             	movzwl %dx,%edx
  
  framearr[totalframes] = framenum;
8010211f:	a1 7c 16 11 80       	mov    0x8011167c,%eax
80102124:	89 14 85 80 16 15 80 	mov    %edx,-0x7feae980(,%eax,4)
  pidarr[totalframes] = -2;
8010212b:	c7 04 85 80 16 11 80 	movl   $0xfffffffe,-0x7feee980(,%eax,4)
80102132:	fe ff ff ff 
  totalframes++;
80102136:	83 c0 01             	add    $0x1,%eax
80102139:	a3 7c 16 11 80       	mov    %eax,0x8011167c
		break;
  }
  cprintf("\n Frame Count: %d \n", framecount); //ADDED
*/
	  
  if(kmem.use_lock)
8010213e:	83 3d 74 16 11 80 00 	cmpl   $0x0,0x80111674
80102145:	75 19                	jne    80102160 <kalloc+0x74>
    release(&kmem.lock);
  return (char*)r;
}
80102147:	89 d8                	mov    %ebx,%eax
80102149:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010214c:	c9                   	leave  
8010214d:	c3                   	ret    
    acquire(&kmem.lock);
8010214e:	83 ec 0c             	sub    $0xc,%esp
80102151:	68 40 16 11 80       	push   $0x80111640
80102156:	e8 51 1b 00 00       	call   80103cac <acquire>
8010215b:	83 c4 10             	add    $0x10,%esp
8010215e:	eb 9c                	jmp    801020fc <kalloc+0x10>
    release(&kmem.lock);
80102160:	83 ec 0c             	sub    $0xc,%esp
80102163:	68 40 16 11 80       	push   $0x80111640
80102168:	e8 a4 1b 00 00       	call   80103d11 <release>
8010216d:	83 c4 10             	add    $0x10,%esp
  return (char*)r;
80102170:	eb d5                	jmp    80102147 <kalloc+0x5b>

80102172 <dump_physmem>:

int
dump_physmem(int *frames, int *pids, int numframes)
{
80102172:	55                   	push   %ebp
80102173:	89 e5                	mov    %esp,%ebp
80102175:	57                   	push   %edi
80102176:	56                   	push   %esi
80102177:	53                   	push   %ebx
80102178:	83 ec 0c             	sub    $0xc,%esp
8010217b:	8b 5d 08             	mov    0x8(%ebp),%ebx
8010217e:	8b 75 0c             	mov    0xc(%ebp),%esi
80102181:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(kmem.use_lock)
80102184:	83 3d 74 16 11 80 00 	cmpl   $0x0,0x80111674
8010218b:	75 28                	jne    801021b5 <dump_physmem+0x43>
    release(&kmem.lock);
  
	return -1;
  	
  }*/
  if(!frames || !pids) {
8010218d:	85 db                	test   %ebx,%ebx
8010218f:	0f 94 c2             	sete   %dl
80102192:	85 f6                	test   %esi,%esi
80102194:	0f 94 c0             	sete   %al
80102197:	08 c2                	or     %al,%dl
80102199:	0f 84 81 00 00 00    	je     80102220 <dump_physmem+0xae>
  	if(kmem.use_lock)
8010219f:	83 3d 74 16 11 80 00 	cmpl   $0x0,0x80111674
801021a6:	75 1f                	jne    801021c7 <dump_physmem+0x55>
    		release(&kmem.lock);
  
  	return -1;
801021a8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  //numframe = totalframes;
  if(kmem.use_lock)
    release(&kmem.lock);
  
	return 0;
}
801021ad:	8d 65 f4             	lea    -0xc(%ebp),%esp
801021b0:	5b                   	pop    %ebx
801021b1:	5e                   	pop    %esi
801021b2:	5f                   	pop    %edi
801021b3:	5d                   	pop    %ebp
801021b4:	c3                   	ret    
    acquire(&kmem.lock);
801021b5:	83 ec 0c             	sub    $0xc,%esp
801021b8:	68 40 16 11 80       	push   $0x80111640
801021bd:	e8 ea 1a 00 00       	call   80103cac <acquire>
801021c2:	83 c4 10             	add    $0x10,%esp
801021c5:	eb c6                	jmp    8010218d <dump_physmem+0x1b>
    		release(&kmem.lock);
801021c7:	83 ec 0c             	sub    $0xc,%esp
801021ca:	68 40 16 11 80       	push   $0x80111640
801021cf:	e8 3d 1b 00 00       	call   80103d11 <release>
801021d4:	83 c4 10             	add    $0x10,%esp
  	return -1;
801021d7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801021dc:	eb cf                	jmp    801021ad <dump_physmem+0x3b>
  	frames[i] = framearr[i];
801021de:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801021e5:	8b 0c 85 80 16 15 80 	mov    -0x7feae980(,%eax,4),%ecx
801021ec:	89 0c 13             	mov    %ecx,(%ebx,%edx,1)
  	pids[i] = pidarr[i];
801021ef:	8b 0c 85 80 16 11 80 	mov    -0x7feee980(,%eax,4),%ecx
801021f6:	89 0c 16             	mov    %ecx,(%esi,%edx,1)
  for(int i = 0; i < numframes; i++) {
801021f9:	83 c0 01             	add    $0x1,%eax
801021fc:	39 f8                	cmp    %edi,%eax
801021fe:	7c de                	jl     801021de <dump_physmem+0x6c>
  if(kmem.use_lock)
80102200:	a1 74 16 11 80       	mov    0x80111674,%eax
80102205:	85 c0                	test   %eax,%eax
80102207:	74 a4                	je     801021ad <dump_physmem+0x3b>
    release(&kmem.lock);
80102209:	83 ec 0c             	sub    $0xc,%esp
8010220c:	68 40 16 11 80       	push   $0x80111640
80102211:	e8 fb 1a 00 00       	call   80103d11 <release>
80102216:	83 c4 10             	add    $0x10,%esp
	return 0;
80102219:	b8 00 00 00 00       	mov    $0x0,%eax
8010221e:	eb 8d                	jmp    801021ad <dump_physmem+0x3b>
  for(int i = 0; i < numframes; i++) {
80102220:	b8 00 00 00 00       	mov    $0x0,%eax
80102225:	eb d5                	jmp    801021fc <dump_physmem+0x8a>

80102227 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102227:	55                   	push   %ebp
80102228:	89 e5                	mov    %esp,%ebp
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010222a:	ba 64 00 00 00       	mov    $0x64,%edx
8010222f:	ec                   	in     (%dx),%al
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
  if((st & KBS_DIB) == 0)
80102230:	a8 01                	test   $0x1,%al
80102232:	0f 84 b5 00 00 00    	je     801022ed <kbdgetc+0xc6>
80102238:	ba 60 00 00 00       	mov    $0x60,%edx
8010223d:	ec                   	in     (%dx),%al
    return -1;
  data = inb(KBDATAP);
8010223e:	0f b6 d0             	movzbl %al,%edx

  if(data == 0xE0){
80102241:	81 fa e0 00 00 00    	cmp    $0xe0,%edx
80102247:	74 5c                	je     801022a5 <kbdgetc+0x7e>
    shift |= E0ESC;
    return 0;
  } else if(data & 0x80){
80102249:	84 c0                	test   %al,%al
8010224b:	78 66                	js     801022b3 <kbdgetc+0x8c>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
    shift &= ~(shiftcode[data] | E0ESC);
    return 0;
  } else if(shift & E0ESC){
8010224d:	8b 0d b4 95 10 80    	mov    0x801095b4,%ecx
80102253:	f6 c1 40             	test   $0x40,%cl
80102256:	74 0f                	je     80102267 <kbdgetc+0x40>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102258:	83 c8 80             	or     $0xffffff80,%eax
8010225b:	0f b6 d0             	movzbl %al,%edx
    shift &= ~E0ESC;
8010225e:	83 e1 bf             	and    $0xffffffbf,%ecx
80102261:	89 0d b4 95 10 80    	mov    %ecx,0x801095b4
  }

  shift |= shiftcode[data];
80102267:	0f b6 8a 60 69 10 80 	movzbl -0x7fef96a0(%edx),%ecx
8010226e:	0b 0d b4 95 10 80    	or     0x801095b4,%ecx
  shift ^= togglecode[data];
80102274:	0f b6 82 60 68 10 80 	movzbl -0x7fef97a0(%edx),%eax
8010227b:	31 c1                	xor    %eax,%ecx
8010227d:	89 0d b4 95 10 80    	mov    %ecx,0x801095b4
  c = charcode[shift & (CTL | SHIFT)][data];
80102283:	89 c8                	mov    %ecx,%eax
80102285:	83 e0 03             	and    $0x3,%eax
80102288:	8b 04 85 40 68 10 80 	mov    -0x7fef97c0(,%eax,4),%eax
8010228f:	0f b6 04 10          	movzbl (%eax,%edx,1),%eax
  if(shift & CAPSLOCK){
80102293:	f6 c1 08             	test   $0x8,%cl
80102296:	74 19                	je     801022b1 <kbdgetc+0x8a>
    if('a' <= c && c <= 'z')
80102298:	8d 50 9f             	lea    -0x61(%eax),%edx
8010229b:	83 fa 19             	cmp    $0x19,%edx
8010229e:	77 40                	ja     801022e0 <kbdgetc+0xb9>
      c += 'A' - 'a';
801022a0:	83 e8 20             	sub    $0x20,%eax
801022a3:	eb 0c                	jmp    801022b1 <kbdgetc+0x8a>
    shift |= E0ESC;
801022a5:	83 0d b4 95 10 80 40 	orl    $0x40,0x801095b4
    return 0;
801022ac:	b8 00 00 00 00       	mov    $0x0,%eax
    else if('A' <= c && c <= 'Z')
      c += 'a' - 'A';
  }
  return c;
}
801022b1:	5d                   	pop    %ebp
801022b2:	c3                   	ret    
    data = (shift & E0ESC ? data : data & 0x7F);
801022b3:	8b 0d b4 95 10 80    	mov    0x801095b4,%ecx
801022b9:	f6 c1 40             	test   $0x40,%cl
801022bc:	75 05                	jne    801022c3 <kbdgetc+0x9c>
801022be:	89 c2                	mov    %eax,%edx
801022c0:	83 e2 7f             	and    $0x7f,%edx
    shift &= ~(shiftcode[data] | E0ESC);
801022c3:	0f b6 82 60 69 10 80 	movzbl -0x7fef96a0(%edx),%eax
801022ca:	83 c8 40             	or     $0x40,%eax
801022cd:	0f b6 c0             	movzbl %al,%eax
801022d0:	f7 d0                	not    %eax
801022d2:	21 c8                	and    %ecx,%eax
801022d4:	a3 b4 95 10 80       	mov    %eax,0x801095b4
    return 0;
801022d9:	b8 00 00 00 00       	mov    $0x0,%eax
801022de:	eb d1                	jmp    801022b1 <kbdgetc+0x8a>
    else if('A' <= c && c <= 'Z')
801022e0:	8d 50 bf             	lea    -0x41(%eax),%edx
801022e3:	83 fa 19             	cmp    $0x19,%edx
801022e6:	77 c9                	ja     801022b1 <kbdgetc+0x8a>
      c += 'a' - 'A';
801022e8:	83 c0 20             	add    $0x20,%eax
  return c;
801022eb:	eb c4                	jmp    801022b1 <kbdgetc+0x8a>
    return -1;
801022ed:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801022f2:	eb bd                	jmp    801022b1 <kbdgetc+0x8a>

801022f4 <kbdintr>:

void
kbdintr(void)
{
801022f4:	55                   	push   %ebp
801022f5:	89 e5                	mov    %esp,%ebp
801022f7:	83 ec 14             	sub    $0x14,%esp
  consoleintr(kbdgetc);
801022fa:	68 27 22 10 80       	push   $0x80102227
801022ff:	e8 3a e4 ff ff       	call   8010073e <consoleintr>
}
80102304:	83 c4 10             	add    $0x10,%esp
80102307:	c9                   	leave  
80102308:	c3                   	ret    

80102309 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102309:	55                   	push   %ebp
8010230a:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
8010230c:	8b 0d 80 16 19 80    	mov    0x80191680,%ecx
80102312:	8d 04 81             	lea    (%ecx,%eax,4),%eax
80102315:	89 10                	mov    %edx,(%eax)
  lapic[ID];  // wait for write to finish, by reading
80102317:	a1 80 16 19 80       	mov    0x80191680,%eax
8010231c:	8b 40 20             	mov    0x20(%eax),%eax
}
8010231f:	5d                   	pop    %ebp
80102320:	c3                   	ret    

80102321 <cmos_read>:
#define MONTH   0x08
#define YEAR    0x09

static uint
cmos_read(uint reg)
{
80102321:	55                   	push   %ebp
80102322:	89 e5                	mov    %esp,%ebp
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102324:	ba 70 00 00 00       	mov    $0x70,%edx
80102329:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010232a:	ba 71 00 00 00       	mov    $0x71,%edx
8010232f:	ec                   	in     (%dx),%al
  outb(CMOS_PORT,  reg);
  microdelay(200);

  return inb(CMOS_RETURN);
80102330:	0f b6 c0             	movzbl %al,%eax
}
80102333:	5d                   	pop    %ebp
80102334:	c3                   	ret    

80102335 <fill_rtcdate>:

static void
fill_rtcdate(struct rtcdate *r)
{
80102335:	55                   	push   %ebp
80102336:	89 e5                	mov    %esp,%ebp
80102338:	53                   	push   %ebx
80102339:	89 c3                	mov    %eax,%ebx
  r->second = cmos_read(SECS);
8010233b:	b8 00 00 00 00       	mov    $0x0,%eax
80102340:	e8 dc ff ff ff       	call   80102321 <cmos_read>
80102345:	89 03                	mov    %eax,(%ebx)
  r->minute = cmos_read(MINS);
80102347:	b8 02 00 00 00       	mov    $0x2,%eax
8010234c:	e8 d0 ff ff ff       	call   80102321 <cmos_read>
80102351:	89 43 04             	mov    %eax,0x4(%ebx)
  r->hour   = cmos_read(HOURS);
80102354:	b8 04 00 00 00       	mov    $0x4,%eax
80102359:	e8 c3 ff ff ff       	call   80102321 <cmos_read>
8010235e:	89 43 08             	mov    %eax,0x8(%ebx)
  r->day    = cmos_read(DAY);
80102361:	b8 07 00 00 00       	mov    $0x7,%eax
80102366:	e8 b6 ff ff ff       	call   80102321 <cmos_read>
8010236b:	89 43 0c             	mov    %eax,0xc(%ebx)
  r->month  = cmos_read(MONTH);
8010236e:	b8 08 00 00 00       	mov    $0x8,%eax
80102373:	e8 a9 ff ff ff       	call   80102321 <cmos_read>
80102378:	89 43 10             	mov    %eax,0x10(%ebx)
  r->year   = cmos_read(YEAR);
8010237b:	b8 09 00 00 00       	mov    $0x9,%eax
80102380:	e8 9c ff ff ff       	call   80102321 <cmos_read>
80102385:	89 43 14             	mov    %eax,0x14(%ebx)
}
80102388:	5b                   	pop    %ebx
80102389:	5d                   	pop    %ebp
8010238a:	c3                   	ret    

8010238b <lapicinit>:
  if(!lapic)
8010238b:	83 3d 80 16 19 80 00 	cmpl   $0x0,0x80191680
80102392:	0f 84 fb 00 00 00    	je     80102493 <lapicinit+0x108>
{
80102398:	55                   	push   %ebp
80102399:	89 e5                	mov    %esp,%ebp
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
8010239b:	ba 3f 01 00 00       	mov    $0x13f,%edx
801023a0:	b8 3c 00 00 00       	mov    $0x3c,%eax
801023a5:	e8 5f ff ff ff       	call   80102309 <lapicw>
  lapicw(TDCR, X1);
801023aa:	ba 0b 00 00 00       	mov    $0xb,%edx
801023af:	b8 f8 00 00 00       	mov    $0xf8,%eax
801023b4:	e8 50 ff ff ff       	call   80102309 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
801023b9:	ba 20 00 02 00       	mov    $0x20020,%edx
801023be:	b8 c8 00 00 00       	mov    $0xc8,%eax
801023c3:	e8 41 ff ff ff       	call   80102309 <lapicw>
  lapicw(TICR, 10000000);
801023c8:	ba 80 96 98 00       	mov    $0x989680,%edx
801023cd:	b8 e0 00 00 00       	mov    $0xe0,%eax
801023d2:	e8 32 ff ff ff       	call   80102309 <lapicw>
  lapicw(LINT0, MASKED);
801023d7:	ba 00 00 01 00       	mov    $0x10000,%edx
801023dc:	b8 d4 00 00 00       	mov    $0xd4,%eax
801023e1:	e8 23 ff ff ff       	call   80102309 <lapicw>
  lapicw(LINT1, MASKED);
801023e6:	ba 00 00 01 00       	mov    $0x10000,%edx
801023eb:	b8 d8 00 00 00       	mov    $0xd8,%eax
801023f0:	e8 14 ff ff ff       	call   80102309 <lapicw>
  if(((lapic[VER]>>16) & 0xFF) >= 4)
801023f5:	a1 80 16 19 80       	mov    0x80191680,%eax
801023fa:	8b 40 30             	mov    0x30(%eax),%eax
801023fd:	c1 e8 10             	shr    $0x10,%eax
80102400:	3c 03                	cmp    $0x3,%al
80102402:	77 7b                	ja     8010247f <lapicinit+0xf4>
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80102404:	ba 33 00 00 00       	mov    $0x33,%edx
80102409:	b8 dc 00 00 00       	mov    $0xdc,%eax
8010240e:	e8 f6 fe ff ff       	call   80102309 <lapicw>
  lapicw(ESR, 0);
80102413:	ba 00 00 00 00       	mov    $0x0,%edx
80102418:	b8 a0 00 00 00       	mov    $0xa0,%eax
8010241d:	e8 e7 fe ff ff       	call   80102309 <lapicw>
  lapicw(ESR, 0);
80102422:	ba 00 00 00 00       	mov    $0x0,%edx
80102427:	b8 a0 00 00 00       	mov    $0xa0,%eax
8010242c:	e8 d8 fe ff ff       	call   80102309 <lapicw>
  lapicw(EOI, 0);
80102431:	ba 00 00 00 00       	mov    $0x0,%edx
80102436:	b8 2c 00 00 00       	mov    $0x2c,%eax
8010243b:	e8 c9 fe ff ff       	call   80102309 <lapicw>
  lapicw(ICRHI, 0);
80102440:	ba 00 00 00 00       	mov    $0x0,%edx
80102445:	b8 c4 00 00 00       	mov    $0xc4,%eax
8010244a:	e8 ba fe ff ff       	call   80102309 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
8010244f:	ba 00 85 08 00       	mov    $0x88500,%edx
80102454:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102459:	e8 ab fe ff ff       	call   80102309 <lapicw>
  while(lapic[ICRLO] & DELIVS)
8010245e:	a1 80 16 19 80       	mov    0x80191680,%eax
80102463:	8b 80 00 03 00 00    	mov    0x300(%eax),%eax
80102469:	f6 c4 10             	test   $0x10,%ah
8010246c:	75 f0                	jne    8010245e <lapicinit+0xd3>
  lapicw(TPR, 0);
8010246e:	ba 00 00 00 00       	mov    $0x0,%edx
80102473:	b8 20 00 00 00       	mov    $0x20,%eax
80102478:	e8 8c fe ff ff       	call   80102309 <lapicw>
}
8010247d:	5d                   	pop    %ebp
8010247e:	c3                   	ret    
    lapicw(PCINT, MASKED);
8010247f:	ba 00 00 01 00       	mov    $0x10000,%edx
80102484:	b8 d0 00 00 00       	mov    $0xd0,%eax
80102489:	e8 7b fe ff ff       	call   80102309 <lapicw>
8010248e:	e9 71 ff ff ff       	jmp    80102404 <lapicinit+0x79>
80102493:	f3 c3                	repz ret 

80102495 <lapicid>:
{
80102495:	55                   	push   %ebp
80102496:	89 e5                	mov    %esp,%ebp
  if (!lapic)
80102498:	a1 80 16 19 80       	mov    0x80191680,%eax
8010249d:	85 c0                	test   %eax,%eax
8010249f:	74 08                	je     801024a9 <lapicid+0x14>
  return lapic[ID] >> 24;
801024a1:	8b 40 20             	mov    0x20(%eax),%eax
801024a4:	c1 e8 18             	shr    $0x18,%eax
}
801024a7:	5d                   	pop    %ebp
801024a8:	c3                   	ret    
    return 0;
801024a9:	b8 00 00 00 00       	mov    $0x0,%eax
801024ae:	eb f7                	jmp    801024a7 <lapicid+0x12>

801024b0 <lapiceoi>:
  if(lapic)
801024b0:	83 3d 80 16 19 80 00 	cmpl   $0x0,0x80191680
801024b7:	74 14                	je     801024cd <lapiceoi+0x1d>
{
801024b9:	55                   	push   %ebp
801024ba:	89 e5                	mov    %esp,%ebp
    lapicw(EOI, 0);
801024bc:	ba 00 00 00 00       	mov    $0x0,%edx
801024c1:	b8 2c 00 00 00       	mov    $0x2c,%eax
801024c6:	e8 3e fe ff ff       	call   80102309 <lapicw>
}
801024cb:	5d                   	pop    %ebp
801024cc:	c3                   	ret    
801024cd:	f3 c3                	repz ret 

801024cf <microdelay>:
{
801024cf:	55                   	push   %ebp
801024d0:	89 e5                	mov    %esp,%ebp
}
801024d2:	5d                   	pop    %ebp
801024d3:	c3                   	ret    

801024d4 <lapicstartap>:
{
801024d4:	55                   	push   %ebp
801024d5:	89 e5                	mov    %esp,%ebp
801024d7:	57                   	push   %edi
801024d8:	56                   	push   %esi
801024d9:	53                   	push   %ebx
801024da:	8b 75 08             	mov    0x8(%ebp),%esi
801024dd:	8b 7d 0c             	mov    0xc(%ebp),%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801024e0:	b8 0f 00 00 00       	mov    $0xf,%eax
801024e5:	ba 70 00 00 00       	mov    $0x70,%edx
801024ea:	ee                   	out    %al,(%dx)
801024eb:	b8 0a 00 00 00       	mov    $0xa,%eax
801024f0:	ba 71 00 00 00       	mov    $0x71,%edx
801024f5:	ee                   	out    %al,(%dx)
  wrv[0] = 0;
801024f6:	66 c7 05 67 04 00 80 	movw   $0x0,0x80000467
801024fd:	00 00 
  wrv[1] = addr >> 4;
801024ff:	89 f8                	mov    %edi,%eax
80102501:	c1 e8 04             	shr    $0x4,%eax
80102504:	66 a3 69 04 00 80    	mov    %ax,0x80000469
  lapicw(ICRHI, apicid<<24);
8010250a:	c1 e6 18             	shl    $0x18,%esi
8010250d:	89 f2                	mov    %esi,%edx
8010250f:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102514:	e8 f0 fd ff ff       	call   80102309 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80102519:	ba 00 c5 00 00       	mov    $0xc500,%edx
8010251e:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102523:	e8 e1 fd ff ff       	call   80102309 <lapicw>
  lapicw(ICRLO, INIT | LEVEL);
80102528:	ba 00 85 00 00       	mov    $0x8500,%edx
8010252d:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102532:	e8 d2 fd ff ff       	call   80102309 <lapicw>
  for(i = 0; i < 2; i++){
80102537:	bb 00 00 00 00       	mov    $0x0,%ebx
8010253c:	eb 21                	jmp    8010255f <lapicstartap+0x8b>
    lapicw(ICRHI, apicid<<24);
8010253e:	89 f2                	mov    %esi,%edx
80102540:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102545:	e8 bf fd ff ff       	call   80102309 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
8010254a:	89 fa                	mov    %edi,%edx
8010254c:	c1 ea 0c             	shr    $0xc,%edx
8010254f:	80 ce 06             	or     $0x6,%dh
80102552:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102557:	e8 ad fd ff ff       	call   80102309 <lapicw>
  for(i = 0; i < 2; i++){
8010255c:	83 c3 01             	add    $0x1,%ebx
8010255f:	83 fb 01             	cmp    $0x1,%ebx
80102562:	7e da                	jle    8010253e <lapicstartap+0x6a>
}
80102564:	5b                   	pop    %ebx
80102565:	5e                   	pop    %esi
80102566:	5f                   	pop    %edi
80102567:	5d                   	pop    %ebp
80102568:	c3                   	ret    

80102569 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void
cmostime(struct rtcdate *r)
{
80102569:	55                   	push   %ebp
8010256a:	89 e5                	mov    %esp,%ebp
8010256c:	57                   	push   %edi
8010256d:	56                   	push   %esi
8010256e:	53                   	push   %ebx
8010256f:	83 ec 3c             	sub    $0x3c,%esp
80102572:	8b 75 08             	mov    0x8(%ebp),%esi
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
80102575:	b8 0b 00 00 00       	mov    $0xb,%eax
8010257a:	e8 a2 fd ff ff       	call   80102321 <cmos_read>

  bcd = (sb & (1 << 2)) == 0;
8010257f:	83 e0 04             	and    $0x4,%eax
80102582:	89 c7                	mov    %eax,%edi

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
80102584:	8d 45 d0             	lea    -0x30(%ebp),%eax
80102587:	e8 a9 fd ff ff       	call   80102335 <fill_rtcdate>
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
8010258c:	b8 0a 00 00 00       	mov    $0xa,%eax
80102591:	e8 8b fd ff ff       	call   80102321 <cmos_read>
80102596:	a8 80                	test   $0x80,%al
80102598:	75 ea                	jne    80102584 <cmostime+0x1b>
        continue;
    fill_rtcdate(&t2);
8010259a:	8d 5d b8             	lea    -0x48(%ebp),%ebx
8010259d:	89 d8                	mov    %ebx,%eax
8010259f:	e8 91 fd ff ff       	call   80102335 <fill_rtcdate>
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
801025a4:	83 ec 04             	sub    $0x4,%esp
801025a7:	6a 18                	push   $0x18
801025a9:	53                   	push   %ebx
801025aa:	8d 45 d0             	lea    -0x30(%ebp),%eax
801025ad:	50                   	push   %eax
801025ae:	e8 eb 17 00 00       	call   80103d9e <memcmp>
801025b3:	83 c4 10             	add    $0x10,%esp
801025b6:	85 c0                	test   %eax,%eax
801025b8:	75 ca                	jne    80102584 <cmostime+0x1b>
      break;
  }

  // convert
  if(bcd) {
801025ba:	85 ff                	test   %edi,%edi
801025bc:	0f 85 84 00 00 00    	jne    80102646 <cmostime+0xdd>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
801025c2:	8b 55 d0             	mov    -0x30(%ebp),%edx
801025c5:	89 d0                	mov    %edx,%eax
801025c7:	c1 e8 04             	shr    $0x4,%eax
801025ca:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801025cd:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801025d0:	83 e2 0f             	and    $0xf,%edx
801025d3:	01 d0                	add    %edx,%eax
801025d5:	89 45 d0             	mov    %eax,-0x30(%ebp)
    CONV(minute);
801025d8:	8b 55 d4             	mov    -0x2c(%ebp),%edx
801025db:	89 d0                	mov    %edx,%eax
801025dd:	c1 e8 04             	shr    $0x4,%eax
801025e0:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801025e3:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801025e6:	83 e2 0f             	and    $0xf,%edx
801025e9:	01 d0                	add    %edx,%eax
801025eb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    CONV(hour  );
801025ee:	8b 55 d8             	mov    -0x28(%ebp),%edx
801025f1:	89 d0                	mov    %edx,%eax
801025f3:	c1 e8 04             	shr    $0x4,%eax
801025f6:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801025f9:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801025fc:	83 e2 0f             	and    $0xf,%edx
801025ff:	01 d0                	add    %edx,%eax
80102601:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(day   );
80102604:	8b 55 dc             	mov    -0x24(%ebp),%edx
80102607:	89 d0                	mov    %edx,%eax
80102609:	c1 e8 04             	shr    $0x4,%eax
8010260c:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010260f:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102612:	83 e2 0f             	and    $0xf,%edx
80102615:	01 d0                	add    %edx,%eax
80102617:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(month );
8010261a:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010261d:	89 d0                	mov    %edx,%eax
8010261f:	c1 e8 04             	shr    $0x4,%eax
80102622:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102625:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102628:	83 e2 0f             	and    $0xf,%edx
8010262b:	01 d0                	add    %edx,%eax
8010262d:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(year  );
80102630:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80102633:	89 d0                	mov    %edx,%eax
80102635:	c1 e8 04             	shr    $0x4,%eax
80102638:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010263b:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
8010263e:	83 e2 0f             	and    $0xf,%edx
80102641:	01 d0                	add    %edx,%eax
80102643:	89 45 e4             	mov    %eax,-0x1c(%ebp)
#undef     CONV
  }

  *r = t1;
80102646:	8b 45 d0             	mov    -0x30(%ebp),%eax
80102649:	89 06                	mov    %eax,(%esi)
8010264b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
8010264e:	89 46 04             	mov    %eax,0x4(%esi)
80102651:	8b 45 d8             	mov    -0x28(%ebp),%eax
80102654:	89 46 08             	mov    %eax,0x8(%esi)
80102657:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010265a:	89 46 0c             	mov    %eax,0xc(%esi)
8010265d:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102660:	89 46 10             	mov    %eax,0x10(%esi)
80102663:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102666:	89 46 14             	mov    %eax,0x14(%esi)
  r->year += 2000;
80102669:	81 46 14 d0 07 00 00 	addl   $0x7d0,0x14(%esi)
}
80102670:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102673:	5b                   	pop    %ebx
80102674:	5e                   	pop    %esi
80102675:	5f                   	pop    %edi
80102676:	5d                   	pop    %ebp
80102677:	c3                   	ret    

80102678 <read_head>:
}

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80102678:	55                   	push   %ebp
80102679:	89 e5                	mov    %esp,%ebp
8010267b:	53                   	push   %ebx
8010267c:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
8010267f:	ff 35 d4 16 19 80    	pushl  0x801916d4
80102685:	ff 35 e4 16 19 80    	pushl  0x801916e4
8010268b:	e8 dc da ff ff       	call   8010016c <bread>
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
80102690:	8b 58 5c             	mov    0x5c(%eax),%ebx
80102693:	89 1d e8 16 19 80    	mov    %ebx,0x801916e8
  for (i = 0; i < log.lh.n; i++) {
80102699:	83 c4 10             	add    $0x10,%esp
8010269c:	ba 00 00 00 00       	mov    $0x0,%edx
801026a1:	eb 0e                	jmp    801026b1 <read_head+0x39>
    log.lh.block[i] = lh->block[i];
801026a3:	8b 4c 90 60          	mov    0x60(%eax,%edx,4),%ecx
801026a7:	89 0c 95 ec 16 19 80 	mov    %ecx,-0x7fe6e914(,%edx,4)
  for (i = 0; i < log.lh.n; i++) {
801026ae:	83 c2 01             	add    $0x1,%edx
801026b1:	39 d3                	cmp    %edx,%ebx
801026b3:	7f ee                	jg     801026a3 <read_head+0x2b>
  }
  brelse(buf);
801026b5:	83 ec 0c             	sub    $0xc,%esp
801026b8:	50                   	push   %eax
801026b9:	e8 17 db ff ff       	call   801001d5 <brelse>
}
801026be:	83 c4 10             	add    $0x10,%esp
801026c1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801026c4:	c9                   	leave  
801026c5:	c3                   	ret    

801026c6 <install_trans>:
{
801026c6:	55                   	push   %ebp
801026c7:	89 e5                	mov    %esp,%ebp
801026c9:	57                   	push   %edi
801026ca:	56                   	push   %esi
801026cb:	53                   	push   %ebx
801026cc:	83 ec 0c             	sub    $0xc,%esp
  for (tail = 0; tail < log.lh.n; tail++) {
801026cf:	bb 00 00 00 00       	mov    $0x0,%ebx
801026d4:	eb 66                	jmp    8010273c <install_trans+0x76>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801026d6:	89 d8                	mov    %ebx,%eax
801026d8:	03 05 d4 16 19 80    	add    0x801916d4,%eax
801026de:	83 c0 01             	add    $0x1,%eax
801026e1:	83 ec 08             	sub    $0x8,%esp
801026e4:	50                   	push   %eax
801026e5:	ff 35 e4 16 19 80    	pushl  0x801916e4
801026eb:	e8 7c da ff ff       	call   8010016c <bread>
801026f0:	89 c7                	mov    %eax,%edi
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
801026f2:	83 c4 08             	add    $0x8,%esp
801026f5:	ff 34 9d ec 16 19 80 	pushl  -0x7fe6e914(,%ebx,4)
801026fc:	ff 35 e4 16 19 80    	pushl  0x801916e4
80102702:	e8 65 da ff ff       	call   8010016c <bread>
80102707:	89 c6                	mov    %eax,%esi
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80102709:	8d 57 5c             	lea    0x5c(%edi),%edx
8010270c:	8d 40 5c             	lea    0x5c(%eax),%eax
8010270f:	83 c4 0c             	add    $0xc,%esp
80102712:	68 00 02 00 00       	push   $0x200
80102717:	52                   	push   %edx
80102718:	50                   	push   %eax
80102719:	e8 b5 16 00 00       	call   80103dd3 <memmove>
    bwrite(dbuf);  // write dst to disk
8010271e:	89 34 24             	mov    %esi,(%esp)
80102721:	e8 74 da ff ff       	call   8010019a <bwrite>
    brelse(lbuf);
80102726:	89 3c 24             	mov    %edi,(%esp)
80102729:	e8 a7 da ff ff       	call   801001d5 <brelse>
    brelse(dbuf);
8010272e:	89 34 24             	mov    %esi,(%esp)
80102731:	e8 9f da ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
80102736:	83 c3 01             	add    $0x1,%ebx
80102739:	83 c4 10             	add    $0x10,%esp
8010273c:	39 1d e8 16 19 80    	cmp    %ebx,0x801916e8
80102742:	7f 92                	jg     801026d6 <install_trans+0x10>
}
80102744:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102747:	5b                   	pop    %ebx
80102748:	5e                   	pop    %esi
80102749:	5f                   	pop    %edi
8010274a:	5d                   	pop    %ebp
8010274b:	c3                   	ret    

8010274c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
8010274c:	55                   	push   %ebp
8010274d:	89 e5                	mov    %esp,%ebp
8010274f:	53                   	push   %ebx
80102750:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
80102753:	ff 35 d4 16 19 80    	pushl  0x801916d4
80102759:	ff 35 e4 16 19 80    	pushl  0x801916e4
8010275f:	e8 08 da ff ff       	call   8010016c <bread>
80102764:	89 c3                	mov    %eax,%ebx
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
80102766:	8b 0d e8 16 19 80    	mov    0x801916e8,%ecx
8010276c:	89 48 5c             	mov    %ecx,0x5c(%eax)
  for (i = 0; i < log.lh.n; i++) {
8010276f:	83 c4 10             	add    $0x10,%esp
80102772:	b8 00 00 00 00       	mov    $0x0,%eax
80102777:	eb 0e                	jmp    80102787 <write_head+0x3b>
    hb->block[i] = log.lh.block[i];
80102779:	8b 14 85 ec 16 19 80 	mov    -0x7fe6e914(,%eax,4),%edx
80102780:	89 54 83 60          	mov    %edx,0x60(%ebx,%eax,4)
  for (i = 0; i < log.lh.n; i++) {
80102784:	83 c0 01             	add    $0x1,%eax
80102787:	39 c1                	cmp    %eax,%ecx
80102789:	7f ee                	jg     80102779 <write_head+0x2d>
  }
  bwrite(buf);
8010278b:	83 ec 0c             	sub    $0xc,%esp
8010278e:	53                   	push   %ebx
8010278f:	e8 06 da ff ff       	call   8010019a <bwrite>
  brelse(buf);
80102794:	89 1c 24             	mov    %ebx,(%esp)
80102797:	e8 39 da ff ff       	call   801001d5 <brelse>
}
8010279c:	83 c4 10             	add    $0x10,%esp
8010279f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801027a2:	c9                   	leave  
801027a3:	c3                   	ret    

801027a4 <recover_from_log>:

static void
recover_from_log(void)
{
801027a4:	55                   	push   %ebp
801027a5:	89 e5                	mov    %esp,%ebp
801027a7:	83 ec 08             	sub    $0x8,%esp
  read_head();
801027aa:	e8 c9 fe ff ff       	call   80102678 <read_head>
  install_trans(); // if committed, copy from log to disk
801027af:	e8 12 ff ff ff       	call   801026c6 <install_trans>
  log.lh.n = 0;
801027b4:	c7 05 e8 16 19 80 00 	movl   $0x0,0x801916e8
801027bb:	00 00 00 
  write_head(); // clear the log
801027be:	e8 89 ff ff ff       	call   8010274c <write_head>
}
801027c3:	c9                   	leave  
801027c4:	c3                   	ret    

801027c5 <write_log>:
}

// Copy modified blocks from cache to log.
static void
write_log(void)
{
801027c5:	55                   	push   %ebp
801027c6:	89 e5                	mov    %esp,%ebp
801027c8:	57                   	push   %edi
801027c9:	56                   	push   %esi
801027ca:	53                   	push   %ebx
801027cb:	83 ec 0c             	sub    $0xc,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801027ce:	bb 00 00 00 00       	mov    $0x0,%ebx
801027d3:	eb 66                	jmp    8010283b <write_log+0x76>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
801027d5:	89 d8                	mov    %ebx,%eax
801027d7:	03 05 d4 16 19 80    	add    0x801916d4,%eax
801027dd:	83 c0 01             	add    $0x1,%eax
801027e0:	83 ec 08             	sub    $0x8,%esp
801027e3:	50                   	push   %eax
801027e4:	ff 35 e4 16 19 80    	pushl  0x801916e4
801027ea:	e8 7d d9 ff ff       	call   8010016c <bread>
801027ef:	89 c6                	mov    %eax,%esi
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
801027f1:	83 c4 08             	add    $0x8,%esp
801027f4:	ff 34 9d ec 16 19 80 	pushl  -0x7fe6e914(,%ebx,4)
801027fb:	ff 35 e4 16 19 80    	pushl  0x801916e4
80102801:	e8 66 d9 ff ff       	call   8010016c <bread>
80102806:	89 c7                	mov    %eax,%edi
    memmove(to->data, from->data, BSIZE);
80102808:	8d 50 5c             	lea    0x5c(%eax),%edx
8010280b:	8d 46 5c             	lea    0x5c(%esi),%eax
8010280e:	83 c4 0c             	add    $0xc,%esp
80102811:	68 00 02 00 00       	push   $0x200
80102816:	52                   	push   %edx
80102817:	50                   	push   %eax
80102818:	e8 b6 15 00 00       	call   80103dd3 <memmove>
    bwrite(to);  // write the log
8010281d:	89 34 24             	mov    %esi,(%esp)
80102820:	e8 75 d9 ff ff       	call   8010019a <bwrite>
    brelse(from);
80102825:	89 3c 24             	mov    %edi,(%esp)
80102828:	e8 a8 d9 ff ff       	call   801001d5 <brelse>
    brelse(to);
8010282d:	89 34 24             	mov    %esi,(%esp)
80102830:	e8 a0 d9 ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
80102835:	83 c3 01             	add    $0x1,%ebx
80102838:	83 c4 10             	add    $0x10,%esp
8010283b:	39 1d e8 16 19 80    	cmp    %ebx,0x801916e8
80102841:	7f 92                	jg     801027d5 <write_log+0x10>
  }
}
80102843:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102846:	5b                   	pop    %ebx
80102847:	5e                   	pop    %esi
80102848:	5f                   	pop    %edi
80102849:	5d                   	pop    %ebp
8010284a:	c3                   	ret    

8010284b <commit>:

static void
commit()
{
  if (log.lh.n > 0) {
8010284b:	83 3d e8 16 19 80 00 	cmpl   $0x0,0x801916e8
80102852:	7e 26                	jle    8010287a <commit+0x2f>
{
80102854:	55                   	push   %ebp
80102855:	89 e5                	mov    %esp,%ebp
80102857:	83 ec 08             	sub    $0x8,%esp
    write_log();     // Write modified blocks from cache to log
8010285a:	e8 66 ff ff ff       	call   801027c5 <write_log>
    write_head();    // Write header to disk -- the real commit
8010285f:	e8 e8 fe ff ff       	call   8010274c <write_head>
    install_trans(); // Now install writes to home locations
80102864:	e8 5d fe ff ff       	call   801026c6 <install_trans>
    log.lh.n = 0;
80102869:	c7 05 e8 16 19 80 00 	movl   $0x0,0x801916e8
80102870:	00 00 00 
    write_head();    // Erase the transaction from the log
80102873:	e8 d4 fe ff ff       	call   8010274c <write_head>
  }
}
80102878:	c9                   	leave  
80102879:	c3                   	ret    
8010287a:	f3 c3                	repz ret 

8010287c <initlog>:
{
8010287c:	55                   	push   %ebp
8010287d:	89 e5                	mov    %esp,%ebp
8010287f:	53                   	push   %ebx
80102880:	83 ec 2c             	sub    $0x2c,%esp
80102883:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&log.lock, "log");
80102886:	68 60 6a 10 80       	push   $0x80106a60
8010288b:	68 a0 16 19 80       	push   $0x801916a0
80102890:	e8 db 12 00 00       	call   80103b70 <initlock>
  readsb(dev, &sb);
80102895:	83 c4 08             	add    $0x8,%esp
80102898:	8d 45 dc             	lea    -0x24(%ebp),%eax
8010289b:	50                   	push   %eax
8010289c:	53                   	push   %ebx
8010289d:	e8 94 e9 ff ff       	call   80101236 <readsb>
  log.start = sb.logstart;
801028a2:	8b 45 ec             	mov    -0x14(%ebp),%eax
801028a5:	a3 d4 16 19 80       	mov    %eax,0x801916d4
  log.size = sb.nlog;
801028aa:	8b 45 e8             	mov    -0x18(%ebp),%eax
801028ad:	a3 d8 16 19 80       	mov    %eax,0x801916d8
  log.dev = dev;
801028b2:	89 1d e4 16 19 80    	mov    %ebx,0x801916e4
  recover_from_log();
801028b8:	e8 e7 fe ff ff       	call   801027a4 <recover_from_log>
}
801028bd:	83 c4 10             	add    $0x10,%esp
801028c0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801028c3:	c9                   	leave  
801028c4:	c3                   	ret    

801028c5 <begin_op>:
{
801028c5:	55                   	push   %ebp
801028c6:	89 e5                	mov    %esp,%ebp
801028c8:	83 ec 14             	sub    $0x14,%esp
  acquire(&log.lock);
801028cb:	68 a0 16 19 80       	push   $0x801916a0
801028d0:	e8 d7 13 00 00       	call   80103cac <acquire>
801028d5:	83 c4 10             	add    $0x10,%esp
801028d8:	eb 15                	jmp    801028ef <begin_op+0x2a>
      sleep(&log, &log.lock);
801028da:	83 ec 08             	sub    $0x8,%esp
801028dd:	68 a0 16 19 80       	push   $0x801916a0
801028e2:	68 a0 16 19 80       	push   $0x801916a0
801028e7:	e8 c5 0e 00 00       	call   801037b1 <sleep>
801028ec:	83 c4 10             	add    $0x10,%esp
    if(log.committing){
801028ef:	83 3d e0 16 19 80 00 	cmpl   $0x0,0x801916e0
801028f6:	75 e2                	jne    801028da <begin_op+0x15>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
801028f8:	a1 dc 16 19 80       	mov    0x801916dc,%eax
801028fd:	83 c0 01             	add    $0x1,%eax
80102900:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102903:	8d 14 09             	lea    (%ecx,%ecx,1),%edx
80102906:	03 15 e8 16 19 80    	add    0x801916e8,%edx
8010290c:	83 fa 1e             	cmp    $0x1e,%edx
8010290f:	7e 17                	jle    80102928 <begin_op+0x63>
      sleep(&log, &log.lock);
80102911:	83 ec 08             	sub    $0x8,%esp
80102914:	68 a0 16 19 80       	push   $0x801916a0
80102919:	68 a0 16 19 80       	push   $0x801916a0
8010291e:	e8 8e 0e 00 00       	call   801037b1 <sleep>
80102923:	83 c4 10             	add    $0x10,%esp
80102926:	eb c7                	jmp    801028ef <begin_op+0x2a>
      log.outstanding += 1;
80102928:	a3 dc 16 19 80       	mov    %eax,0x801916dc
      release(&log.lock);
8010292d:	83 ec 0c             	sub    $0xc,%esp
80102930:	68 a0 16 19 80       	push   $0x801916a0
80102935:	e8 d7 13 00 00       	call   80103d11 <release>
}
8010293a:	83 c4 10             	add    $0x10,%esp
8010293d:	c9                   	leave  
8010293e:	c3                   	ret    

8010293f <end_op>:
{
8010293f:	55                   	push   %ebp
80102940:	89 e5                	mov    %esp,%ebp
80102942:	53                   	push   %ebx
80102943:	83 ec 10             	sub    $0x10,%esp
  acquire(&log.lock);
80102946:	68 a0 16 19 80       	push   $0x801916a0
8010294b:	e8 5c 13 00 00       	call   80103cac <acquire>
  log.outstanding -= 1;
80102950:	a1 dc 16 19 80       	mov    0x801916dc,%eax
80102955:	83 e8 01             	sub    $0x1,%eax
80102958:	a3 dc 16 19 80       	mov    %eax,0x801916dc
  if(log.committing)
8010295d:	8b 1d e0 16 19 80    	mov    0x801916e0,%ebx
80102963:	83 c4 10             	add    $0x10,%esp
80102966:	85 db                	test   %ebx,%ebx
80102968:	75 2c                	jne    80102996 <end_op+0x57>
  if(log.outstanding == 0){
8010296a:	85 c0                	test   %eax,%eax
8010296c:	75 35                	jne    801029a3 <end_op+0x64>
    log.committing = 1;
8010296e:	c7 05 e0 16 19 80 01 	movl   $0x1,0x801916e0
80102975:	00 00 00 
    do_commit = 1;
80102978:	bb 01 00 00 00       	mov    $0x1,%ebx
  release(&log.lock);
8010297d:	83 ec 0c             	sub    $0xc,%esp
80102980:	68 a0 16 19 80       	push   $0x801916a0
80102985:	e8 87 13 00 00       	call   80103d11 <release>
  if(do_commit){
8010298a:	83 c4 10             	add    $0x10,%esp
8010298d:	85 db                	test   %ebx,%ebx
8010298f:	75 24                	jne    801029b5 <end_op+0x76>
}
80102991:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102994:	c9                   	leave  
80102995:	c3                   	ret    
    panic("log.committing");
80102996:	83 ec 0c             	sub    $0xc,%esp
80102999:	68 64 6a 10 80       	push   $0x80106a64
8010299e:	e8 a5 d9 ff ff       	call   80100348 <panic>
    wakeup(&log);
801029a3:	83 ec 0c             	sub    $0xc,%esp
801029a6:	68 a0 16 19 80       	push   $0x801916a0
801029ab:	e8 66 0f 00 00       	call   80103916 <wakeup>
801029b0:	83 c4 10             	add    $0x10,%esp
801029b3:	eb c8                	jmp    8010297d <end_op+0x3e>
    commit();
801029b5:	e8 91 fe ff ff       	call   8010284b <commit>
    acquire(&log.lock);
801029ba:	83 ec 0c             	sub    $0xc,%esp
801029bd:	68 a0 16 19 80       	push   $0x801916a0
801029c2:	e8 e5 12 00 00       	call   80103cac <acquire>
    log.committing = 0;
801029c7:	c7 05 e0 16 19 80 00 	movl   $0x0,0x801916e0
801029ce:	00 00 00 
    wakeup(&log);
801029d1:	c7 04 24 a0 16 19 80 	movl   $0x801916a0,(%esp)
801029d8:	e8 39 0f 00 00       	call   80103916 <wakeup>
    release(&log.lock);
801029dd:	c7 04 24 a0 16 19 80 	movl   $0x801916a0,(%esp)
801029e4:	e8 28 13 00 00       	call   80103d11 <release>
801029e9:	83 c4 10             	add    $0x10,%esp
}
801029ec:	eb a3                	jmp    80102991 <end_op+0x52>

801029ee <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
801029ee:	55                   	push   %ebp
801029ef:	89 e5                	mov    %esp,%ebp
801029f1:	53                   	push   %ebx
801029f2:	83 ec 04             	sub    $0x4,%esp
801029f5:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
801029f8:	8b 15 e8 16 19 80    	mov    0x801916e8,%edx
801029fe:	83 fa 1d             	cmp    $0x1d,%edx
80102a01:	7f 45                	jg     80102a48 <log_write+0x5a>
80102a03:	a1 d8 16 19 80       	mov    0x801916d8,%eax
80102a08:	83 e8 01             	sub    $0x1,%eax
80102a0b:	39 c2                	cmp    %eax,%edx
80102a0d:	7d 39                	jge    80102a48 <log_write+0x5a>
    panic("too big a transaction");
  if (log.outstanding < 1)
80102a0f:	83 3d dc 16 19 80 00 	cmpl   $0x0,0x801916dc
80102a16:	7e 3d                	jle    80102a55 <log_write+0x67>
    panic("log_write outside of trans");

  acquire(&log.lock);
80102a18:	83 ec 0c             	sub    $0xc,%esp
80102a1b:	68 a0 16 19 80       	push   $0x801916a0
80102a20:	e8 87 12 00 00       	call   80103cac <acquire>
  for (i = 0; i < log.lh.n; i++) {
80102a25:	83 c4 10             	add    $0x10,%esp
80102a28:	b8 00 00 00 00       	mov    $0x0,%eax
80102a2d:	8b 15 e8 16 19 80    	mov    0x801916e8,%edx
80102a33:	39 c2                	cmp    %eax,%edx
80102a35:	7e 2b                	jle    80102a62 <log_write+0x74>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
80102a37:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102a3a:	39 0c 85 ec 16 19 80 	cmp    %ecx,-0x7fe6e914(,%eax,4)
80102a41:	74 1f                	je     80102a62 <log_write+0x74>
  for (i = 0; i < log.lh.n; i++) {
80102a43:	83 c0 01             	add    $0x1,%eax
80102a46:	eb e5                	jmp    80102a2d <log_write+0x3f>
    panic("too big a transaction");
80102a48:	83 ec 0c             	sub    $0xc,%esp
80102a4b:	68 73 6a 10 80       	push   $0x80106a73
80102a50:	e8 f3 d8 ff ff       	call   80100348 <panic>
    panic("log_write outside of trans");
80102a55:	83 ec 0c             	sub    $0xc,%esp
80102a58:	68 89 6a 10 80       	push   $0x80106a89
80102a5d:	e8 e6 d8 ff ff       	call   80100348 <panic>
      break;
  }
  log.lh.block[i] = b->blockno;
80102a62:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102a65:	89 0c 85 ec 16 19 80 	mov    %ecx,-0x7fe6e914(,%eax,4)
  if (i == log.lh.n)
80102a6c:	39 c2                	cmp    %eax,%edx
80102a6e:	74 18                	je     80102a88 <log_write+0x9a>
    log.lh.n++;
  b->flags |= B_DIRTY; // prevent eviction
80102a70:	83 0b 04             	orl    $0x4,(%ebx)
  release(&log.lock);
80102a73:	83 ec 0c             	sub    $0xc,%esp
80102a76:	68 a0 16 19 80       	push   $0x801916a0
80102a7b:	e8 91 12 00 00       	call   80103d11 <release>
}
80102a80:	83 c4 10             	add    $0x10,%esp
80102a83:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102a86:	c9                   	leave  
80102a87:	c3                   	ret    
    log.lh.n++;
80102a88:	83 c2 01             	add    $0x1,%edx
80102a8b:	89 15 e8 16 19 80    	mov    %edx,0x801916e8
80102a91:	eb dd                	jmp    80102a70 <log_write+0x82>

80102a93 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80102a93:	55                   	push   %ebp
80102a94:	89 e5                	mov    %esp,%ebp
80102a96:	53                   	push   %ebx
80102a97:	83 ec 08             	sub    $0x8,%esp

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80102a9a:	68 8a 00 00 00       	push   $0x8a
80102a9f:	68 8c 94 10 80       	push   $0x8010948c
80102aa4:	68 00 70 00 80       	push   $0x80007000
80102aa9:	e8 25 13 00 00       	call   80103dd3 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80102aae:	83 c4 10             	add    $0x10,%esp
80102ab1:	bb a0 17 19 80       	mov    $0x801917a0,%ebx
80102ab6:	eb 06                	jmp    80102abe <startothers+0x2b>
80102ab8:	81 c3 b0 00 00 00    	add    $0xb0,%ebx
80102abe:	69 05 20 1d 19 80 b0 	imul   $0xb0,0x80191d20,%eax
80102ac5:	00 00 00 
80102ac8:	05 a0 17 19 80       	add    $0x801917a0,%eax
80102acd:	39 d8                	cmp    %ebx,%eax
80102acf:	76 4c                	jbe    80102b1d <startothers+0x8a>
    if(c == mycpu())  // We've started already.
80102ad1:	e8 c0 07 00 00       	call   80103296 <mycpu>
80102ad6:	39 d8                	cmp    %ebx,%eax
80102ad8:	74 de                	je     80102ab8 <startothers+0x25>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80102ada:	e8 0d f6 ff ff       	call   801020ec <kalloc>
    *(void**)(code-4) = stack + KSTACKSIZE;
80102adf:	05 00 10 00 00       	add    $0x1000,%eax
80102ae4:	a3 fc 6f 00 80       	mov    %eax,0x80006ffc
    *(void(**)(void))(code-8) = mpenter;
80102ae9:	c7 05 f8 6f 00 80 61 	movl   $0x80102b61,0x80006ff8
80102af0:	2b 10 80 
    *(int**)(code-12) = (void *) V2P(entrypgdir);
80102af3:	c7 05 f4 6f 00 80 00 	movl   $0x108000,0x80006ff4
80102afa:	80 10 00 

    lapicstartap(c->apicid, V2P(code));
80102afd:	83 ec 08             	sub    $0x8,%esp
80102b00:	68 00 70 00 00       	push   $0x7000
80102b05:	0f b6 03             	movzbl (%ebx),%eax
80102b08:	50                   	push   %eax
80102b09:	e8 c6 f9 ff ff       	call   801024d4 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80102b0e:	83 c4 10             	add    $0x10,%esp
80102b11:	8b 83 a0 00 00 00    	mov    0xa0(%ebx),%eax
80102b17:	85 c0                	test   %eax,%eax
80102b19:	74 f6                	je     80102b11 <startothers+0x7e>
80102b1b:	eb 9b                	jmp    80102ab8 <startothers+0x25>
      ;
  }
}
80102b1d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102b20:	c9                   	leave  
80102b21:	c3                   	ret    

80102b22 <mpmain>:
{
80102b22:	55                   	push   %ebp
80102b23:	89 e5                	mov    %esp,%ebp
80102b25:	53                   	push   %ebx
80102b26:	83 ec 04             	sub    $0x4,%esp
  cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
80102b29:	e8 c4 07 00 00       	call   801032f2 <cpuid>
80102b2e:	89 c3                	mov    %eax,%ebx
80102b30:	e8 bd 07 00 00       	call   801032f2 <cpuid>
80102b35:	83 ec 04             	sub    $0x4,%esp
80102b38:	53                   	push   %ebx
80102b39:	50                   	push   %eax
80102b3a:	68 a4 6a 10 80       	push   $0x80106aa4
80102b3f:	e8 c7 da ff ff       	call   8010060b <cprintf>
  idtinit();       // load idt register
80102b44:	e8 eb 23 00 00       	call   80104f34 <idtinit>
  xchg(&(mycpu()->started), 1); // tell startothers() we're up
80102b49:	e8 48 07 00 00       	call   80103296 <mycpu>
80102b4e:	89 c2                	mov    %eax,%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80102b50:	b8 01 00 00 00       	mov    $0x1,%eax
80102b55:	f0 87 82 a0 00 00 00 	lock xchg %eax,0xa0(%edx)
  scheduler();     // start running processes
80102b5c:	e8 2b 0a 00 00       	call   8010358c <scheduler>

80102b61 <mpenter>:
{
80102b61:	55                   	push   %ebp
80102b62:	89 e5                	mov    %esp,%ebp
80102b64:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
80102b67:	e8 d1 33 00 00       	call   80105f3d <switchkvm>
  seginit();
80102b6c:	e8 80 32 00 00       	call   80105df1 <seginit>
  lapicinit();
80102b71:	e8 15 f8 ff ff       	call   8010238b <lapicinit>
  mpmain();
80102b76:	e8 a7 ff ff ff       	call   80102b22 <mpmain>

80102b7b <main>:
{
80102b7b:	8d 4c 24 04          	lea    0x4(%esp),%ecx
80102b7f:	83 e4 f0             	and    $0xfffffff0,%esp
80102b82:	ff 71 fc             	pushl  -0x4(%ecx)
80102b85:	55                   	push   %ebp
80102b86:	89 e5                	mov    %esp,%ebp
80102b88:	51                   	push   %ecx
80102b89:	83 ec 0c             	sub    $0xc,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80102b8c:	68 00 00 40 80       	push   $0x80400000
80102b91:	68 c8 44 19 80       	push   $0x801944c8
80102b96:	e8 ce f4 ff ff       	call   80102069 <kinit1>
  kvmalloc();      // kernel page table
80102b9b:	e8 2a 38 00 00       	call   801063ca <kvmalloc>
  mpinit();        // detect other processors
80102ba0:	e8 c9 01 00 00       	call   80102d6e <mpinit>
  lapicinit();     // interrupt controller
80102ba5:	e8 e1 f7 ff ff       	call   8010238b <lapicinit>
  seginit();       // segment descriptors
80102baa:	e8 42 32 00 00       	call   80105df1 <seginit>
  picinit();       // disable pic
80102baf:	e8 82 02 00 00       	call   80102e36 <picinit>
  ioapicinit();    // another interrupt controller
80102bb4:	e8 41 f3 ff ff       	call   80101efa <ioapicinit>
  consoleinit();   // console hardware
80102bb9:	e8 d0 dc ff ff       	call   8010088e <consoleinit>
  uartinit();      // serial port
80102bbe:	e8 1f 26 00 00       	call   801051e2 <uartinit>
  pinit();         // process table
80102bc3:	e8 b4 06 00 00       	call   8010327c <pinit>
  tvinit();        // trap vectors
80102bc8:	e8 b6 22 00 00       	call   80104e83 <tvinit>
  binit();         // buffer cache
80102bcd:	e8 22 d5 ff ff       	call   801000f4 <binit>
  fileinit();      // file table
80102bd2:	e8 3c e0 ff ff       	call   80100c13 <fileinit>
  ideinit();       // disk 
80102bd7:	e8 24 f1 ff ff       	call   80101d00 <ideinit>
  startothers();   // start other processors
80102bdc:	e8 b2 fe ff ff       	call   80102a93 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80102be1:	83 c4 08             	add    $0x8,%esp
80102be4:	68 00 00 00 8e       	push   $0x8e000000
80102be9:	68 00 00 40 80       	push   $0x80400000
80102bee:	e8 a8 f4 ff ff       	call   8010209b <kinit2>
  userinit();      // first user process
80102bf3:	e8 39 07 00 00       	call   80103331 <userinit>
  mpmain();        // finish this processor's setup
80102bf8:	e8 25 ff ff ff       	call   80102b22 <mpmain>

80102bfd <sum>:
int ncpu;
uchar ioapicid;

static uchar
sum(uchar *addr, int len)
{
80102bfd:	55                   	push   %ebp
80102bfe:	89 e5                	mov    %esp,%ebp
80102c00:	56                   	push   %esi
80102c01:	53                   	push   %ebx
  int i, sum;

  sum = 0;
80102c02:	bb 00 00 00 00       	mov    $0x0,%ebx
  for(i=0; i<len; i++)
80102c07:	b9 00 00 00 00       	mov    $0x0,%ecx
80102c0c:	eb 09                	jmp    80102c17 <sum+0x1a>
    sum += addr[i];
80102c0e:	0f b6 34 08          	movzbl (%eax,%ecx,1),%esi
80102c12:	01 f3                	add    %esi,%ebx
  for(i=0; i<len; i++)
80102c14:	83 c1 01             	add    $0x1,%ecx
80102c17:	39 d1                	cmp    %edx,%ecx
80102c19:	7c f3                	jl     80102c0e <sum+0x11>
  return sum;
}
80102c1b:	89 d8                	mov    %ebx,%eax
80102c1d:	5b                   	pop    %ebx
80102c1e:	5e                   	pop    %esi
80102c1f:	5d                   	pop    %ebp
80102c20:	c3                   	ret    

80102c21 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80102c21:	55                   	push   %ebp
80102c22:	89 e5                	mov    %esp,%ebp
80102c24:	56                   	push   %esi
80102c25:	53                   	push   %ebx
  uchar *e, *p, *addr;

  addr = P2V(a);
80102c26:	8d b0 00 00 00 80    	lea    -0x80000000(%eax),%esi
80102c2c:	89 f3                	mov    %esi,%ebx
  e = addr+len;
80102c2e:	01 d6                	add    %edx,%esi
  for(p = addr; p < e; p += sizeof(struct mp))
80102c30:	eb 03                	jmp    80102c35 <mpsearch1+0x14>
80102c32:	83 c3 10             	add    $0x10,%ebx
80102c35:	39 f3                	cmp    %esi,%ebx
80102c37:	73 29                	jae    80102c62 <mpsearch1+0x41>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80102c39:	83 ec 04             	sub    $0x4,%esp
80102c3c:	6a 04                	push   $0x4
80102c3e:	68 b8 6a 10 80       	push   $0x80106ab8
80102c43:	53                   	push   %ebx
80102c44:	e8 55 11 00 00       	call   80103d9e <memcmp>
80102c49:	83 c4 10             	add    $0x10,%esp
80102c4c:	85 c0                	test   %eax,%eax
80102c4e:	75 e2                	jne    80102c32 <mpsearch1+0x11>
80102c50:	ba 10 00 00 00       	mov    $0x10,%edx
80102c55:	89 d8                	mov    %ebx,%eax
80102c57:	e8 a1 ff ff ff       	call   80102bfd <sum>
80102c5c:	84 c0                	test   %al,%al
80102c5e:	75 d2                	jne    80102c32 <mpsearch1+0x11>
80102c60:	eb 05                	jmp    80102c67 <mpsearch1+0x46>
      return (struct mp*)p;
  return 0;
80102c62:	bb 00 00 00 00       	mov    $0x0,%ebx
}
80102c67:	89 d8                	mov    %ebx,%eax
80102c69:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102c6c:	5b                   	pop    %ebx
80102c6d:	5e                   	pop    %esi
80102c6e:	5d                   	pop    %ebp
80102c6f:	c3                   	ret    

80102c70 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80102c70:	55                   	push   %ebp
80102c71:	89 e5                	mov    %esp,%ebp
80102c73:	83 ec 08             	sub    $0x8,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80102c76:	0f b6 05 0f 04 00 80 	movzbl 0x8000040f,%eax
80102c7d:	c1 e0 08             	shl    $0x8,%eax
80102c80:	0f b6 15 0e 04 00 80 	movzbl 0x8000040e,%edx
80102c87:	09 d0                	or     %edx,%eax
80102c89:	c1 e0 04             	shl    $0x4,%eax
80102c8c:	85 c0                	test   %eax,%eax
80102c8e:	74 1f                	je     80102caf <mpsearch+0x3f>
    if((mp = mpsearch1(p, 1024)))
80102c90:	ba 00 04 00 00       	mov    $0x400,%edx
80102c95:	e8 87 ff ff ff       	call   80102c21 <mpsearch1>
80102c9a:	85 c0                	test   %eax,%eax
80102c9c:	75 0f                	jne    80102cad <mpsearch+0x3d>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1(p-1024, 1024)))
      return mp;
  }
  return mpsearch1(0xF0000, 0x10000);
80102c9e:	ba 00 00 01 00       	mov    $0x10000,%edx
80102ca3:	b8 00 00 0f 00       	mov    $0xf0000,%eax
80102ca8:	e8 74 ff ff ff       	call   80102c21 <mpsearch1>
}
80102cad:	c9                   	leave  
80102cae:	c3                   	ret    
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80102caf:	0f b6 05 14 04 00 80 	movzbl 0x80000414,%eax
80102cb6:	c1 e0 08             	shl    $0x8,%eax
80102cb9:	0f b6 15 13 04 00 80 	movzbl 0x80000413,%edx
80102cc0:	09 d0                	or     %edx,%eax
80102cc2:	c1 e0 0a             	shl    $0xa,%eax
    if((mp = mpsearch1(p-1024, 1024)))
80102cc5:	2d 00 04 00 00       	sub    $0x400,%eax
80102cca:	ba 00 04 00 00       	mov    $0x400,%edx
80102ccf:	e8 4d ff ff ff       	call   80102c21 <mpsearch1>
80102cd4:	85 c0                	test   %eax,%eax
80102cd6:	75 d5                	jne    80102cad <mpsearch+0x3d>
80102cd8:	eb c4                	jmp    80102c9e <mpsearch+0x2e>

80102cda <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80102cda:	55                   	push   %ebp
80102cdb:	89 e5                	mov    %esp,%ebp
80102cdd:	57                   	push   %edi
80102cde:	56                   	push   %esi
80102cdf:	53                   	push   %ebx
80102ce0:	83 ec 1c             	sub    $0x1c,%esp
80102ce3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80102ce6:	e8 85 ff ff ff       	call   80102c70 <mpsearch>
80102ceb:	85 c0                	test   %eax,%eax
80102ced:	74 5c                	je     80102d4b <mpconfig+0x71>
80102cef:	89 c7                	mov    %eax,%edi
80102cf1:	8b 58 04             	mov    0x4(%eax),%ebx
80102cf4:	85 db                	test   %ebx,%ebx
80102cf6:	74 5a                	je     80102d52 <mpconfig+0x78>
    return 0;
  conf = (struct mpconf*) P2V((uint) mp->physaddr);
80102cf8:	8d b3 00 00 00 80    	lea    -0x80000000(%ebx),%esi
  if(memcmp(conf, "PCMP", 4) != 0)
80102cfe:	83 ec 04             	sub    $0x4,%esp
80102d01:	6a 04                	push   $0x4
80102d03:	68 bd 6a 10 80       	push   $0x80106abd
80102d08:	56                   	push   %esi
80102d09:	e8 90 10 00 00       	call   80103d9e <memcmp>
80102d0e:	83 c4 10             	add    $0x10,%esp
80102d11:	85 c0                	test   %eax,%eax
80102d13:	75 44                	jne    80102d59 <mpconfig+0x7f>
    return 0;
  if(conf->version != 1 && conf->version != 4)
80102d15:	0f b6 83 06 00 00 80 	movzbl -0x7ffffffa(%ebx),%eax
80102d1c:	3c 01                	cmp    $0x1,%al
80102d1e:	0f 95 c2             	setne  %dl
80102d21:	3c 04                	cmp    $0x4,%al
80102d23:	0f 95 c0             	setne  %al
80102d26:	84 c2                	test   %al,%dl
80102d28:	75 36                	jne    80102d60 <mpconfig+0x86>
    return 0;
  if(sum((uchar*)conf, conf->length) != 0)
80102d2a:	0f b7 93 04 00 00 80 	movzwl -0x7ffffffc(%ebx),%edx
80102d31:	89 f0                	mov    %esi,%eax
80102d33:	e8 c5 fe ff ff       	call   80102bfd <sum>
80102d38:	84 c0                	test   %al,%al
80102d3a:	75 2b                	jne    80102d67 <mpconfig+0x8d>
    return 0;
  *pmp = mp;
80102d3c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102d3f:	89 38                	mov    %edi,(%eax)
  return conf;
}
80102d41:	89 f0                	mov    %esi,%eax
80102d43:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102d46:	5b                   	pop    %ebx
80102d47:	5e                   	pop    %esi
80102d48:	5f                   	pop    %edi
80102d49:	5d                   	pop    %ebp
80102d4a:	c3                   	ret    
    return 0;
80102d4b:	be 00 00 00 00       	mov    $0x0,%esi
80102d50:	eb ef                	jmp    80102d41 <mpconfig+0x67>
80102d52:	be 00 00 00 00       	mov    $0x0,%esi
80102d57:	eb e8                	jmp    80102d41 <mpconfig+0x67>
    return 0;
80102d59:	be 00 00 00 00       	mov    $0x0,%esi
80102d5e:	eb e1                	jmp    80102d41 <mpconfig+0x67>
    return 0;
80102d60:	be 00 00 00 00       	mov    $0x0,%esi
80102d65:	eb da                	jmp    80102d41 <mpconfig+0x67>
    return 0;
80102d67:	be 00 00 00 00       	mov    $0x0,%esi
80102d6c:	eb d3                	jmp    80102d41 <mpconfig+0x67>

80102d6e <mpinit>:

void
mpinit(void)
{
80102d6e:	55                   	push   %ebp
80102d6f:	89 e5                	mov    %esp,%ebp
80102d71:	57                   	push   %edi
80102d72:	56                   	push   %esi
80102d73:	53                   	push   %ebx
80102d74:	83 ec 1c             	sub    $0x1c,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  if((conf = mpconfig(&mp)) == 0)
80102d77:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80102d7a:	e8 5b ff ff ff       	call   80102cda <mpconfig>
80102d7f:	85 c0                	test   %eax,%eax
80102d81:	74 19                	je     80102d9c <mpinit+0x2e>
    panic("Expect to run on an SMP");
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
80102d83:	8b 50 24             	mov    0x24(%eax),%edx
80102d86:	89 15 80 16 19 80    	mov    %edx,0x80191680
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102d8c:	8d 50 2c             	lea    0x2c(%eax),%edx
80102d8f:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
80102d93:	01 c1                	add    %eax,%ecx
  ismp = 1;
80102d95:	bb 01 00 00 00       	mov    $0x1,%ebx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102d9a:	eb 34                	jmp    80102dd0 <mpinit+0x62>
    panic("Expect to run on an SMP");
80102d9c:	83 ec 0c             	sub    $0xc,%esp
80102d9f:	68 c2 6a 10 80       	push   $0x80106ac2
80102da4:	e8 9f d5 ff ff       	call   80100348 <panic>
    switch(*p){
    case MPPROC:
      proc = (struct mpproc*)p;
      if(ncpu < NCPU) {
80102da9:	8b 35 20 1d 19 80    	mov    0x80191d20,%esi
80102daf:	83 fe 07             	cmp    $0x7,%esi
80102db2:	7f 19                	jg     80102dcd <mpinit+0x5f>
        cpus[ncpu].apicid = proc->apicid;  // apicid may differ from ncpu
80102db4:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102db8:	69 fe b0 00 00 00    	imul   $0xb0,%esi,%edi
80102dbe:	88 87 a0 17 19 80    	mov    %al,-0x7fe6e860(%edi)
        ncpu++;
80102dc4:	83 c6 01             	add    $0x1,%esi
80102dc7:	89 35 20 1d 19 80    	mov    %esi,0x80191d20
      }
      p += sizeof(struct mpproc);
80102dcd:	83 c2 14             	add    $0x14,%edx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102dd0:	39 ca                	cmp    %ecx,%edx
80102dd2:	73 2b                	jae    80102dff <mpinit+0x91>
    switch(*p){
80102dd4:	0f b6 02             	movzbl (%edx),%eax
80102dd7:	3c 04                	cmp    $0x4,%al
80102dd9:	77 1d                	ja     80102df8 <mpinit+0x8a>
80102ddb:	0f b6 c0             	movzbl %al,%eax
80102dde:	ff 24 85 fc 6a 10 80 	jmp    *-0x7fef9504(,%eax,4)
      continue;
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
      ioapicid = ioapic->apicno;
80102de5:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102de9:	a2 80 17 19 80       	mov    %al,0x80191780
      p += sizeof(struct mpioapic);
80102dee:	83 c2 08             	add    $0x8,%edx
      continue;
80102df1:	eb dd                	jmp    80102dd0 <mpinit+0x62>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80102df3:	83 c2 08             	add    $0x8,%edx
      continue;
80102df6:	eb d8                	jmp    80102dd0 <mpinit+0x62>
    default:
      ismp = 0;
80102df8:	bb 00 00 00 00       	mov    $0x0,%ebx
80102dfd:	eb d1                	jmp    80102dd0 <mpinit+0x62>
      break;
    }
  }
  if(!ismp)
80102dff:	85 db                	test   %ebx,%ebx
80102e01:	74 26                	je     80102e29 <mpinit+0xbb>
    panic("Didn't find a suitable machine");

  if(mp->imcrp){
80102e03:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102e06:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
80102e0a:	74 15                	je     80102e21 <mpinit+0xb3>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102e0c:	b8 70 00 00 00       	mov    $0x70,%eax
80102e11:	ba 22 00 00 00       	mov    $0x22,%edx
80102e16:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102e17:	ba 23 00 00 00       	mov    $0x23,%edx
80102e1c:	ec                   	in     (%dx),%al
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80102e1d:	83 c8 01             	or     $0x1,%eax
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102e20:	ee                   	out    %al,(%dx)
  }
}
80102e21:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102e24:	5b                   	pop    %ebx
80102e25:	5e                   	pop    %esi
80102e26:	5f                   	pop    %edi
80102e27:	5d                   	pop    %ebp
80102e28:	c3                   	ret    
    panic("Didn't find a suitable machine");
80102e29:	83 ec 0c             	sub    $0xc,%esp
80102e2c:	68 dc 6a 10 80       	push   $0x80106adc
80102e31:	e8 12 d5 ff ff       	call   80100348 <panic>

80102e36 <picinit>:
#define IO_PIC2         0xA0    // Slave (IRQs 8-15)

// Don't use the 8259A interrupt controllers.  Xv6 assumes SMP hardware.
void
picinit(void)
{
80102e36:	55                   	push   %ebp
80102e37:	89 e5                	mov    %esp,%ebp
80102e39:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102e3e:	ba 21 00 00 00       	mov    $0x21,%edx
80102e43:	ee                   	out    %al,(%dx)
80102e44:	ba a1 00 00 00       	mov    $0xa1,%edx
80102e49:	ee                   	out    %al,(%dx)
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
  outb(IO_PIC2+1, 0xFF);
}
80102e4a:	5d                   	pop    %ebp
80102e4b:	c3                   	ret    

80102e4c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80102e4c:	55                   	push   %ebp
80102e4d:	89 e5                	mov    %esp,%ebp
80102e4f:	57                   	push   %edi
80102e50:	56                   	push   %esi
80102e51:	53                   	push   %ebx
80102e52:	83 ec 0c             	sub    $0xc,%esp
80102e55:	8b 5d 08             	mov    0x8(%ebp),%ebx
80102e58:	8b 75 0c             	mov    0xc(%ebp),%esi
  struct pipe *p;

  p = 0;
  *f0 = *f1 = 0;
80102e5b:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80102e61:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80102e67:	e8 c1 dd ff ff       	call   80100c2d <filealloc>
80102e6c:	89 03                	mov    %eax,(%ebx)
80102e6e:	85 c0                	test   %eax,%eax
80102e70:	74 16                	je     80102e88 <pipealloc+0x3c>
80102e72:	e8 b6 dd ff ff       	call   80100c2d <filealloc>
80102e77:	89 06                	mov    %eax,(%esi)
80102e79:	85 c0                	test   %eax,%eax
80102e7b:	74 0b                	je     80102e88 <pipealloc+0x3c>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80102e7d:	e8 6a f2 ff ff       	call   801020ec <kalloc>
80102e82:	89 c7                	mov    %eax,%edi
80102e84:	85 c0                	test   %eax,%eax
80102e86:	75 35                	jne    80102ebd <pipealloc+0x71>
  return 0;

 bad:
  if(p)
    kfree((char*)p);
  if(*f0)
80102e88:	8b 03                	mov    (%ebx),%eax
80102e8a:	85 c0                	test   %eax,%eax
80102e8c:	74 0c                	je     80102e9a <pipealloc+0x4e>
    fileclose(*f0);
80102e8e:	83 ec 0c             	sub    $0xc,%esp
80102e91:	50                   	push   %eax
80102e92:	e8 3c de ff ff       	call   80100cd3 <fileclose>
80102e97:	83 c4 10             	add    $0x10,%esp
  if(*f1)
80102e9a:	8b 06                	mov    (%esi),%eax
80102e9c:	85 c0                	test   %eax,%eax
80102e9e:	0f 84 8b 00 00 00    	je     80102f2f <pipealloc+0xe3>
    fileclose(*f1);
80102ea4:	83 ec 0c             	sub    $0xc,%esp
80102ea7:	50                   	push   %eax
80102ea8:	e8 26 de ff ff       	call   80100cd3 <fileclose>
80102ead:	83 c4 10             	add    $0x10,%esp
  return -1;
80102eb0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80102eb5:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102eb8:	5b                   	pop    %ebx
80102eb9:	5e                   	pop    %esi
80102eba:	5f                   	pop    %edi
80102ebb:	5d                   	pop    %ebp
80102ebc:	c3                   	ret    
  p->readopen = 1;
80102ebd:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80102ec4:	00 00 00 
  p->writeopen = 1;
80102ec7:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80102ece:	00 00 00 
  p->nwrite = 0;
80102ed1:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80102ed8:	00 00 00 
  p->nread = 0;
80102edb:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80102ee2:	00 00 00 
  initlock(&p->lock, "pipe");
80102ee5:	83 ec 08             	sub    $0x8,%esp
80102ee8:	68 10 6b 10 80       	push   $0x80106b10
80102eed:	50                   	push   %eax
80102eee:	e8 7d 0c 00 00       	call   80103b70 <initlock>
  (*f0)->type = FD_PIPE;
80102ef3:	8b 03                	mov    (%ebx),%eax
80102ef5:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80102efb:	8b 03                	mov    (%ebx),%eax
80102efd:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80102f01:	8b 03                	mov    (%ebx),%eax
80102f03:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80102f07:	8b 03                	mov    (%ebx),%eax
80102f09:	89 78 0c             	mov    %edi,0xc(%eax)
  (*f1)->type = FD_PIPE;
80102f0c:	8b 06                	mov    (%esi),%eax
80102f0e:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80102f14:	8b 06                	mov    (%esi),%eax
80102f16:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80102f1a:	8b 06                	mov    (%esi),%eax
80102f1c:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80102f20:	8b 06                	mov    (%esi),%eax
80102f22:	89 78 0c             	mov    %edi,0xc(%eax)
  return 0;
80102f25:	83 c4 10             	add    $0x10,%esp
80102f28:	b8 00 00 00 00       	mov    $0x0,%eax
80102f2d:	eb 86                	jmp    80102eb5 <pipealloc+0x69>
  return -1;
80102f2f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102f34:	e9 7c ff ff ff       	jmp    80102eb5 <pipealloc+0x69>

80102f39 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80102f39:	55                   	push   %ebp
80102f3a:	89 e5                	mov    %esp,%ebp
80102f3c:	53                   	push   %ebx
80102f3d:	83 ec 10             	sub    $0x10,%esp
80102f40:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&p->lock);
80102f43:	53                   	push   %ebx
80102f44:	e8 63 0d 00 00       	call   80103cac <acquire>
  if(writable){
80102f49:	83 c4 10             	add    $0x10,%esp
80102f4c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102f50:	74 3f                	je     80102f91 <pipeclose+0x58>
    p->writeopen = 0;
80102f52:	c7 83 40 02 00 00 00 	movl   $0x0,0x240(%ebx)
80102f59:	00 00 00 
    wakeup(&p->nread);
80102f5c:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102f62:	83 ec 0c             	sub    $0xc,%esp
80102f65:	50                   	push   %eax
80102f66:	e8 ab 09 00 00       	call   80103916 <wakeup>
80102f6b:	83 c4 10             	add    $0x10,%esp
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
80102f6e:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80102f75:	75 09                	jne    80102f80 <pipeclose+0x47>
80102f77:	83 bb 40 02 00 00 00 	cmpl   $0x0,0x240(%ebx)
80102f7e:	74 2f                	je     80102faf <pipeclose+0x76>
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
80102f80:	83 ec 0c             	sub    $0xc,%esp
80102f83:	53                   	push   %ebx
80102f84:	e8 88 0d 00 00       	call   80103d11 <release>
80102f89:	83 c4 10             	add    $0x10,%esp
}
80102f8c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102f8f:	c9                   	leave  
80102f90:	c3                   	ret    
    p->readopen = 0;
80102f91:	c7 83 3c 02 00 00 00 	movl   $0x0,0x23c(%ebx)
80102f98:	00 00 00 
    wakeup(&p->nwrite);
80102f9b:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80102fa1:	83 ec 0c             	sub    $0xc,%esp
80102fa4:	50                   	push   %eax
80102fa5:	e8 6c 09 00 00       	call   80103916 <wakeup>
80102faa:	83 c4 10             	add    $0x10,%esp
80102fad:	eb bf                	jmp    80102f6e <pipeclose+0x35>
    release(&p->lock);
80102faf:	83 ec 0c             	sub    $0xc,%esp
80102fb2:	53                   	push   %ebx
80102fb3:	e8 59 0d 00 00       	call   80103d11 <release>
    kfree((char*)p);
80102fb8:	89 1c 24             	mov    %ebx,(%esp)
80102fbb:	e8 e4 ef ff ff       	call   80101fa4 <kfree>
80102fc0:	83 c4 10             	add    $0x10,%esp
80102fc3:	eb c7                	jmp    80102f8c <pipeclose+0x53>

80102fc5 <pipewrite>:

int
pipewrite(struct pipe *p, char *addr, int n)
{
80102fc5:	55                   	push   %ebp
80102fc6:	89 e5                	mov    %esp,%ebp
80102fc8:	57                   	push   %edi
80102fc9:	56                   	push   %esi
80102fca:	53                   	push   %ebx
80102fcb:	83 ec 18             	sub    $0x18,%esp
80102fce:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80102fd1:	89 de                	mov    %ebx,%esi
80102fd3:	53                   	push   %ebx
80102fd4:	e8 d3 0c 00 00       	call   80103cac <acquire>
  for(i = 0; i < n; i++){
80102fd9:	83 c4 10             	add    $0x10,%esp
80102fdc:	bf 00 00 00 00       	mov    $0x0,%edi
80102fe1:	3b 7d 10             	cmp    0x10(%ebp),%edi
80102fe4:	0f 8d 88 00 00 00    	jge    80103072 <pipewrite+0xad>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80102fea:	8b 93 38 02 00 00    	mov    0x238(%ebx),%edx
80102ff0:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
80102ff6:	05 00 02 00 00       	add    $0x200,%eax
80102ffb:	39 c2                	cmp    %eax,%edx
80102ffd:	75 51                	jne    80103050 <pipewrite+0x8b>
      if(p->readopen == 0 || myproc()->killed){
80102fff:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80103006:	74 2f                	je     80103037 <pipewrite+0x72>
80103008:	e8 00 03 00 00       	call   8010330d <myproc>
8010300d:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80103011:	75 24                	jne    80103037 <pipewrite+0x72>
        release(&p->lock);
        return -1;
      }
      wakeup(&p->nread);
80103013:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80103019:	83 ec 0c             	sub    $0xc,%esp
8010301c:	50                   	push   %eax
8010301d:	e8 f4 08 00 00       	call   80103916 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80103022:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80103028:	83 c4 08             	add    $0x8,%esp
8010302b:	56                   	push   %esi
8010302c:	50                   	push   %eax
8010302d:	e8 7f 07 00 00       	call   801037b1 <sleep>
80103032:	83 c4 10             	add    $0x10,%esp
80103035:	eb b3                	jmp    80102fea <pipewrite+0x25>
        release(&p->lock);
80103037:	83 ec 0c             	sub    $0xc,%esp
8010303a:	53                   	push   %ebx
8010303b:	e8 d1 0c 00 00       	call   80103d11 <release>
        return -1;
80103040:	83 c4 10             	add    $0x10,%esp
80103043:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
  release(&p->lock);
  return n;
}
80103048:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010304b:	5b                   	pop    %ebx
8010304c:	5e                   	pop    %esi
8010304d:	5f                   	pop    %edi
8010304e:	5d                   	pop    %ebp
8010304f:	c3                   	ret    
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80103050:	8d 42 01             	lea    0x1(%edx),%eax
80103053:	89 83 38 02 00 00    	mov    %eax,0x238(%ebx)
80103059:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
8010305f:	8b 45 0c             	mov    0xc(%ebp),%eax
80103062:	0f b6 04 38          	movzbl (%eax,%edi,1),%eax
80103066:	88 44 13 34          	mov    %al,0x34(%ebx,%edx,1)
  for(i = 0; i < n; i++){
8010306a:	83 c7 01             	add    $0x1,%edi
8010306d:	e9 6f ff ff ff       	jmp    80102fe1 <pipewrite+0x1c>
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80103072:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80103078:	83 ec 0c             	sub    $0xc,%esp
8010307b:	50                   	push   %eax
8010307c:	e8 95 08 00 00       	call   80103916 <wakeup>
  release(&p->lock);
80103081:	89 1c 24             	mov    %ebx,(%esp)
80103084:	e8 88 0c 00 00       	call   80103d11 <release>
  return n;
80103089:	83 c4 10             	add    $0x10,%esp
8010308c:	8b 45 10             	mov    0x10(%ebp),%eax
8010308f:	eb b7                	jmp    80103048 <pipewrite+0x83>

80103091 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80103091:	55                   	push   %ebp
80103092:	89 e5                	mov    %esp,%ebp
80103094:	57                   	push   %edi
80103095:	56                   	push   %esi
80103096:	53                   	push   %ebx
80103097:	83 ec 18             	sub    $0x18,%esp
8010309a:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
8010309d:	89 df                	mov    %ebx,%edi
8010309f:	53                   	push   %ebx
801030a0:	e8 07 0c 00 00       	call   80103cac <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801030a5:	83 c4 10             	add    $0x10,%esp
801030a8:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
801030ae:	39 83 34 02 00 00    	cmp    %eax,0x234(%ebx)
801030b4:	75 3d                	jne    801030f3 <piperead+0x62>
801030b6:	8b b3 40 02 00 00    	mov    0x240(%ebx),%esi
801030bc:	85 f6                	test   %esi,%esi
801030be:	74 38                	je     801030f8 <piperead+0x67>
    if(myproc()->killed){
801030c0:	e8 48 02 00 00       	call   8010330d <myproc>
801030c5:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801030c9:	75 15                	jne    801030e0 <piperead+0x4f>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
801030cb:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
801030d1:	83 ec 08             	sub    $0x8,%esp
801030d4:	57                   	push   %edi
801030d5:	50                   	push   %eax
801030d6:	e8 d6 06 00 00       	call   801037b1 <sleep>
801030db:	83 c4 10             	add    $0x10,%esp
801030de:	eb c8                	jmp    801030a8 <piperead+0x17>
      release(&p->lock);
801030e0:	83 ec 0c             	sub    $0xc,%esp
801030e3:	53                   	push   %ebx
801030e4:	e8 28 0c 00 00       	call   80103d11 <release>
      return -1;
801030e9:	83 c4 10             	add    $0x10,%esp
801030ec:	be ff ff ff ff       	mov    $0xffffffff,%esi
801030f1:	eb 50                	jmp    80103143 <piperead+0xb2>
801030f3:	be 00 00 00 00       	mov    $0x0,%esi
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801030f8:	3b 75 10             	cmp    0x10(%ebp),%esi
801030fb:	7d 2c                	jge    80103129 <piperead+0x98>
    if(p->nread == p->nwrite)
801030fd:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
80103103:	3b 83 38 02 00 00    	cmp    0x238(%ebx),%eax
80103109:	74 1e                	je     80103129 <piperead+0x98>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
8010310b:	8d 50 01             	lea    0x1(%eax),%edx
8010310e:	89 93 34 02 00 00    	mov    %edx,0x234(%ebx)
80103114:	25 ff 01 00 00       	and    $0x1ff,%eax
80103119:	0f b6 44 03 34       	movzbl 0x34(%ebx,%eax,1),%eax
8010311e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103121:	88 04 31             	mov    %al,(%ecx,%esi,1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80103124:	83 c6 01             	add    $0x1,%esi
80103127:	eb cf                	jmp    801030f8 <piperead+0x67>
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80103129:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
8010312f:	83 ec 0c             	sub    $0xc,%esp
80103132:	50                   	push   %eax
80103133:	e8 de 07 00 00       	call   80103916 <wakeup>
  release(&p->lock);
80103138:	89 1c 24             	mov    %ebx,(%esp)
8010313b:	e8 d1 0b 00 00       	call   80103d11 <release>
  return i;
80103140:	83 c4 10             	add    $0x10,%esp
}
80103143:	89 f0                	mov    %esi,%eax
80103145:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103148:	5b                   	pop    %ebx
80103149:	5e                   	pop    %esi
8010314a:	5f                   	pop    %edi
8010314b:	5d                   	pop    %ebp
8010314c:	c3                   	ret    

8010314d <wakeup1>:

// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
8010314d:	55                   	push   %ebp
8010314e:	89 e5                	mov    %esp,%ebp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103150:	ba 74 1d 19 80       	mov    $0x80191d74,%edx
80103155:	eb 03                	jmp    8010315a <wakeup1+0xd>
80103157:	83 c2 7c             	add    $0x7c,%edx
8010315a:	81 fa 74 3c 19 80    	cmp    $0x80193c74,%edx
80103160:	73 14                	jae    80103176 <wakeup1+0x29>
    if(p->state == SLEEPING && p->chan == chan)
80103162:	83 7a 0c 02          	cmpl   $0x2,0xc(%edx)
80103166:	75 ef                	jne    80103157 <wakeup1+0xa>
80103168:	39 42 20             	cmp    %eax,0x20(%edx)
8010316b:	75 ea                	jne    80103157 <wakeup1+0xa>
      p->state = RUNNABLE;
8010316d:	c7 42 0c 03 00 00 00 	movl   $0x3,0xc(%edx)
80103174:	eb e1                	jmp    80103157 <wakeup1+0xa>
}
80103176:	5d                   	pop    %ebp
80103177:	c3                   	ret    

80103178 <allocproc>:
{
80103178:	55                   	push   %ebp
80103179:	89 e5                	mov    %esp,%ebp
8010317b:	53                   	push   %ebx
8010317c:	83 ec 10             	sub    $0x10,%esp
  acquire(&ptable.lock);
8010317f:	68 40 1d 19 80       	push   $0x80191d40
80103184:	e8 23 0b 00 00       	call   80103cac <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103189:	83 c4 10             	add    $0x10,%esp
8010318c:	bb 74 1d 19 80       	mov    $0x80191d74,%ebx
80103191:	81 fb 74 3c 19 80    	cmp    $0x80193c74,%ebx
80103197:	73 0b                	jae    801031a4 <allocproc+0x2c>
    if(p->state == UNUSED)
80103199:	83 7b 0c 00          	cmpl   $0x0,0xc(%ebx)
8010319d:	74 1c                	je     801031bb <allocproc+0x43>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010319f:	83 c3 7c             	add    $0x7c,%ebx
801031a2:	eb ed                	jmp    80103191 <allocproc+0x19>
  release(&ptable.lock);
801031a4:	83 ec 0c             	sub    $0xc,%esp
801031a7:	68 40 1d 19 80       	push   $0x80191d40
801031ac:	e8 60 0b 00 00       	call   80103d11 <release>
  return 0;
801031b1:	83 c4 10             	add    $0x10,%esp
801031b4:	bb 00 00 00 00       	mov    $0x0,%ebx
801031b9:	eb 69                	jmp    80103224 <allocproc+0xac>
  p->state = EMBRYO;
801031bb:	c7 43 0c 01 00 00 00 	movl   $0x1,0xc(%ebx)
  p->pid = nextpid++;
801031c2:	a1 04 90 10 80       	mov    0x80109004,%eax
801031c7:	8d 50 01             	lea    0x1(%eax),%edx
801031ca:	89 15 04 90 10 80    	mov    %edx,0x80109004
801031d0:	89 43 10             	mov    %eax,0x10(%ebx)
  release(&ptable.lock);
801031d3:	83 ec 0c             	sub    $0xc,%esp
801031d6:	68 40 1d 19 80       	push   $0x80191d40
801031db:	e8 31 0b 00 00       	call   80103d11 <release>
  if((p->kstack = kalloc()) == 0){
801031e0:	e8 07 ef ff ff       	call   801020ec <kalloc>
801031e5:	89 43 08             	mov    %eax,0x8(%ebx)
801031e8:	83 c4 10             	add    $0x10,%esp
801031eb:	85 c0                	test   %eax,%eax
801031ed:	74 3c                	je     8010322b <allocproc+0xb3>
  sp -= sizeof *p->tf;
801031ef:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
  p->tf = (struct trapframe*)sp;
801031f5:	89 53 18             	mov    %edx,0x18(%ebx)
  *(uint*)sp = (uint)trapret;
801031f8:	c7 80 b0 0f 00 00 78 	movl   $0x80104e78,0xfb0(%eax)
801031ff:	4e 10 80 
  sp -= sizeof *p->context;
80103202:	05 9c 0f 00 00       	add    $0xf9c,%eax
  p->context = (struct context*)sp;
80103207:	89 43 1c             	mov    %eax,0x1c(%ebx)
  memset(p->context, 0, sizeof *p->context);
8010320a:	83 ec 04             	sub    $0x4,%esp
8010320d:	6a 14                	push   $0x14
8010320f:	6a 00                	push   $0x0
80103211:	50                   	push   %eax
80103212:	e8 41 0b 00 00       	call   80103d58 <memset>
  p->context->eip = (uint)forkret;
80103217:	8b 43 1c             	mov    0x1c(%ebx),%eax
8010321a:	c7 40 10 39 32 10 80 	movl   $0x80103239,0x10(%eax)
  return p;
80103221:	83 c4 10             	add    $0x10,%esp
}
80103224:	89 d8                	mov    %ebx,%eax
80103226:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103229:	c9                   	leave  
8010322a:	c3                   	ret    
    p->state = UNUSED;
8010322b:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return 0;
80103232:	bb 00 00 00 00       	mov    $0x0,%ebx
80103237:	eb eb                	jmp    80103224 <allocproc+0xac>

80103239 <forkret>:
{
80103239:	55                   	push   %ebp
8010323a:	89 e5                	mov    %esp,%ebp
8010323c:	83 ec 14             	sub    $0x14,%esp
  release(&ptable.lock);
8010323f:	68 40 1d 19 80       	push   $0x80191d40
80103244:	e8 c8 0a 00 00       	call   80103d11 <release>
  if (first) {
80103249:	83 c4 10             	add    $0x10,%esp
8010324c:	83 3d 00 90 10 80 00 	cmpl   $0x0,0x80109000
80103253:	75 02                	jne    80103257 <forkret+0x1e>
}
80103255:	c9                   	leave  
80103256:	c3                   	ret    
    first = 0;
80103257:	c7 05 00 90 10 80 00 	movl   $0x0,0x80109000
8010325e:	00 00 00 
    iinit(ROOTDEV);
80103261:	83 ec 0c             	sub    $0xc,%esp
80103264:	6a 01                	push   $0x1
80103266:	e8 81 e0 ff ff       	call   801012ec <iinit>
    initlog(ROOTDEV);
8010326b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103272:	e8 05 f6 ff ff       	call   8010287c <initlog>
80103277:	83 c4 10             	add    $0x10,%esp
}
8010327a:	eb d9                	jmp    80103255 <forkret+0x1c>

8010327c <pinit>:
{
8010327c:	55                   	push   %ebp
8010327d:	89 e5                	mov    %esp,%ebp
8010327f:	83 ec 10             	sub    $0x10,%esp
  initlock(&ptable.lock, "ptable");
80103282:	68 15 6b 10 80       	push   $0x80106b15
80103287:	68 40 1d 19 80       	push   $0x80191d40
8010328c:	e8 df 08 00 00       	call   80103b70 <initlock>
}
80103291:	83 c4 10             	add    $0x10,%esp
80103294:	c9                   	leave  
80103295:	c3                   	ret    

80103296 <mycpu>:
{
80103296:	55                   	push   %ebp
80103297:	89 e5                	mov    %esp,%ebp
80103299:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
8010329c:	9c                   	pushf  
8010329d:	58                   	pop    %eax
  if(readeflags()&FL_IF)
8010329e:	f6 c4 02             	test   $0x2,%ah
801032a1:	75 28                	jne    801032cb <mycpu+0x35>
  apicid = lapicid();
801032a3:	e8 ed f1 ff ff       	call   80102495 <lapicid>
  for (i = 0; i < ncpu; ++i) {
801032a8:	ba 00 00 00 00       	mov    $0x0,%edx
801032ad:	39 15 20 1d 19 80    	cmp    %edx,0x80191d20
801032b3:	7e 23                	jle    801032d8 <mycpu+0x42>
    if (cpus[i].apicid == apicid)
801032b5:	69 ca b0 00 00 00    	imul   $0xb0,%edx,%ecx
801032bb:	0f b6 89 a0 17 19 80 	movzbl -0x7fe6e860(%ecx),%ecx
801032c2:	39 c1                	cmp    %eax,%ecx
801032c4:	74 1f                	je     801032e5 <mycpu+0x4f>
  for (i = 0; i < ncpu; ++i) {
801032c6:	83 c2 01             	add    $0x1,%edx
801032c9:	eb e2                	jmp    801032ad <mycpu+0x17>
    panic("mycpu called with interrupts enabled\n");
801032cb:	83 ec 0c             	sub    $0xc,%esp
801032ce:	68 f8 6b 10 80       	push   $0x80106bf8
801032d3:	e8 70 d0 ff ff       	call   80100348 <panic>
  panic("unknown apicid\n");
801032d8:	83 ec 0c             	sub    $0xc,%esp
801032db:	68 1c 6b 10 80       	push   $0x80106b1c
801032e0:	e8 63 d0 ff ff       	call   80100348 <panic>
      return &cpus[i];
801032e5:	69 c2 b0 00 00 00    	imul   $0xb0,%edx,%eax
801032eb:	05 a0 17 19 80       	add    $0x801917a0,%eax
}
801032f0:	c9                   	leave  
801032f1:	c3                   	ret    

801032f2 <cpuid>:
cpuid() {
801032f2:	55                   	push   %ebp
801032f3:	89 e5                	mov    %esp,%ebp
801032f5:	83 ec 08             	sub    $0x8,%esp
  return mycpu()-cpus;
801032f8:	e8 99 ff ff ff       	call   80103296 <mycpu>
801032fd:	2d a0 17 19 80       	sub    $0x801917a0,%eax
80103302:	c1 f8 04             	sar    $0x4,%eax
80103305:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
8010330b:	c9                   	leave  
8010330c:	c3                   	ret    

8010330d <myproc>:
myproc(void) {
8010330d:	55                   	push   %ebp
8010330e:	89 e5                	mov    %esp,%ebp
80103310:	53                   	push   %ebx
80103311:	83 ec 04             	sub    $0x4,%esp
  pushcli();
80103314:	e8 b6 08 00 00       	call   80103bcf <pushcli>
  c = mycpu();
80103319:	e8 78 ff ff ff       	call   80103296 <mycpu>
  p = c->proc;
8010331e:	8b 98 ac 00 00 00    	mov    0xac(%eax),%ebx
  popcli();
80103324:	e8 e3 08 00 00       	call   80103c0c <popcli>
}
80103329:	89 d8                	mov    %ebx,%eax
8010332b:	83 c4 04             	add    $0x4,%esp
8010332e:	5b                   	pop    %ebx
8010332f:	5d                   	pop    %ebp
80103330:	c3                   	ret    

80103331 <userinit>:
{
80103331:	55                   	push   %ebp
80103332:	89 e5                	mov    %esp,%ebp
80103334:	53                   	push   %ebx
80103335:	83 ec 04             	sub    $0x4,%esp
  p = allocproc();
80103338:	e8 3b fe ff ff       	call   80103178 <allocproc>
8010333d:	89 c3                	mov    %eax,%ebx
  initproc = p;
8010333f:	a3 b8 95 10 80       	mov    %eax,0x801095b8
  if((p->pgdir = setupkvm()) == 0)
80103344:	e8 13 30 00 00       	call   8010635c <setupkvm>
80103349:	89 43 04             	mov    %eax,0x4(%ebx)
8010334c:	85 c0                	test   %eax,%eax
8010334e:	0f 84 b7 00 00 00    	je     8010340b <userinit+0xda>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80103354:	83 ec 04             	sub    $0x4,%esp
80103357:	68 2c 00 00 00       	push   $0x2c
8010335c:	68 60 94 10 80       	push   $0x80109460
80103361:	50                   	push   %eax
80103362:	e8 00 2d 00 00       	call   80106067 <inituvm>
  p->sz = PGSIZE;
80103367:	c7 03 00 10 00 00    	movl   $0x1000,(%ebx)
  memset(p->tf, 0, sizeof(*p->tf));
8010336d:	83 c4 0c             	add    $0xc,%esp
80103370:	6a 4c                	push   $0x4c
80103372:	6a 00                	push   $0x0
80103374:	ff 73 18             	pushl  0x18(%ebx)
80103377:	e8 dc 09 00 00       	call   80103d58 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
8010337c:	8b 43 18             	mov    0x18(%ebx),%eax
8010337f:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
80103385:	8b 43 18             	mov    0x18(%ebx),%eax
80103388:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
  p->tf->es = p->tf->ds;
8010338e:	8b 43 18             	mov    0x18(%ebx),%eax
80103391:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
80103395:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
80103399:	8b 43 18             	mov    0x18(%ebx),%eax
8010339c:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801033a0:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
801033a4:	8b 43 18             	mov    0x18(%ebx),%eax
801033a7:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801033ae:	8b 43 18             	mov    0x18(%ebx),%eax
801033b1:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
801033b8:	8b 43 18             	mov    0x18(%ebx),%eax
801033bb:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
  safestrcpy(p->name, "initcode", sizeof(p->name));
801033c2:	8d 43 6c             	lea    0x6c(%ebx),%eax
801033c5:	83 c4 0c             	add    $0xc,%esp
801033c8:	6a 10                	push   $0x10
801033ca:	68 45 6b 10 80       	push   $0x80106b45
801033cf:	50                   	push   %eax
801033d0:	e8 ea 0a 00 00       	call   80103ebf <safestrcpy>
  p->cwd = namei("/");
801033d5:	c7 04 24 4e 6b 10 80 	movl   $0x80106b4e,(%esp)
801033dc:	e8 00 e8 ff ff       	call   80101be1 <namei>
801033e1:	89 43 68             	mov    %eax,0x68(%ebx)
  acquire(&ptable.lock);
801033e4:	c7 04 24 40 1d 19 80 	movl   $0x80191d40,(%esp)
801033eb:	e8 bc 08 00 00       	call   80103cac <acquire>
  p->state = RUNNABLE;
801033f0:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  release(&ptable.lock);
801033f7:	c7 04 24 40 1d 19 80 	movl   $0x80191d40,(%esp)
801033fe:	e8 0e 09 00 00       	call   80103d11 <release>
}
80103403:	83 c4 10             	add    $0x10,%esp
80103406:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103409:	c9                   	leave  
8010340a:	c3                   	ret    
    panic("userinit: out of memory?");
8010340b:	83 ec 0c             	sub    $0xc,%esp
8010340e:	68 2c 6b 10 80       	push   $0x80106b2c
80103413:	e8 30 cf ff ff       	call   80100348 <panic>

80103418 <growproc>:
{
80103418:	55                   	push   %ebp
80103419:	89 e5                	mov    %esp,%ebp
8010341b:	56                   	push   %esi
8010341c:	53                   	push   %ebx
8010341d:	8b 75 08             	mov    0x8(%ebp),%esi
  struct proc *curproc = myproc();
80103420:	e8 e8 fe ff ff       	call   8010330d <myproc>
80103425:	89 c3                	mov    %eax,%ebx
  sz = curproc->sz;
80103427:	8b 00                	mov    (%eax),%eax
  if(n > 0){
80103429:	85 f6                	test   %esi,%esi
8010342b:	7f 21                	jg     8010344e <growproc+0x36>
  } else if(n < 0){
8010342d:	85 f6                	test   %esi,%esi
8010342f:	79 33                	jns    80103464 <growproc+0x4c>
    if((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
80103431:	83 ec 04             	sub    $0x4,%esp
80103434:	01 c6                	add    %eax,%esi
80103436:	56                   	push   %esi
80103437:	50                   	push   %eax
80103438:	ff 73 04             	pushl  0x4(%ebx)
8010343b:	e8 30 2d 00 00       	call   80106170 <deallocuvm>
80103440:	83 c4 10             	add    $0x10,%esp
80103443:	85 c0                	test   %eax,%eax
80103445:	75 1d                	jne    80103464 <growproc+0x4c>
      return -1;
80103447:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010344c:	eb 29                	jmp    80103477 <growproc+0x5f>
    if((sz = allocuvm(curproc->pgdir, sz, sz + n)) == 0)
8010344e:	83 ec 04             	sub    $0x4,%esp
80103451:	01 c6                	add    %eax,%esi
80103453:	56                   	push   %esi
80103454:	50                   	push   %eax
80103455:	ff 73 04             	pushl  0x4(%ebx)
80103458:	e8 a5 2d 00 00       	call   80106202 <allocuvm>
8010345d:	83 c4 10             	add    $0x10,%esp
80103460:	85 c0                	test   %eax,%eax
80103462:	74 1a                	je     8010347e <growproc+0x66>
  curproc->sz = sz;
80103464:	89 03                	mov    %eax,(%ebx)
  switchuvm(curproc);
80103466:	83 ec 0c             	sub    $0xc,%esp
80103469:	53                   	push   %ebx
8010346a:	e8 e0 2a 00 00       	call   80105f4f <switchuvm>
  return 0;
8010346f:	83 c4 10             	add    $0x10,%esp
80103472:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103477:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010347a:	5b                   	pop    %ebx
8010347b:	5e                   	pop    %esi
8010347c:	5d                   	pop    %ebp
8010347d:	c3                   	ret    
      return -1;
8010347e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103483:	eb f2                	jmp    80103477 <growproc+0x5f>

80103485 <fork>:
{
80103485:	55                   	push   %ebp
80103486:	89 e5                	mov    %esp,%ebp
80103488:	57                   	push   %edi
80103489:	56                   	push   %esi
8010348a:	53                   	push   %ebx
8010348b:	83 ec 1c             	sub    $0x1c,%esp
  struct proc *curproc = myproc();
8010348e:	e8 7a fe ff ff       	call   8010330d <myproc>
80103493:	89 c3                	mov    %eax,%ebx
  if((np = allocproc()) == 0){
80103495:	e8 de fc ff ff       	call   80103178 <allocproc>
8010349a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010349d:	85 c0                	test   %eax,%eax
8010349f:	0f 84 e0 00 00 00    	je     80103585 <fork+0x100>
801034a5:	89 c7                	mov    %eax,%edi
  if((np->pgdir = copyuvm(curproc->pgdir, curproc->sz)) == 0){
801034a7:	83 ec 08             	sub    $0x8,%esp
801034aa:	ff 33                	pushl  (%ebx)
801034ac:	ff 73 04             	pushl  0x4(%ebx)
801034af:	e8 59 2f 00 00       	call   8010640d <copyuvm>
801034b4:	89 47 04             	mov    %eax,0x4(%edi)
801034b7:	83 c4 10             	add    $0x10,%esp
801034ba:	85 c0                	test   %eax,%eax
801034bc:	74 2a                	je     801034e8 <fork+0x63>
  np->sz = curproc->sz;
801034be:	8b 03                	mov    (%ebx),%eax
801034c0:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801034c3:	89 01                	mov    %eax,(%ecx)
  np->parent = curproc;
801034c5:	89 c8                	mov    %ecx,%eax
801034c7:	89 59 14             	mov    %ebx,0x14(%ecx)
  *np->tf = *curproc->tf;
801034ca:	8b 73 18             	mov    0x18(%ebx),%esi
801034cd:	8b 79 18             	mov    0x18(%ecx),%edi
801034d0:	b9 13 00 00 00       	mov    $0x13,%ecx
801034d5:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  np->tf->eax = 0;
801034d7:	8b 40 18             	mov    0x18(%eax),%eax
801034da:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
  for(i = 0; i < NOFILE; i++)
801034e1:	be 00 00 00 00       	mov    $0x0,%esi
801034e6:	eb 29                	jmp    80103511 <fork+0x8c>
    kfree(np->kstack);
801034e8:	83 ec 0c             	sub    $0xc,%esp
801034eb:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
801034ee:	ff 73 08             	pushl  0x8(%ebx)
801034f1:	e8 ae ea ff ff       	call   80101fa4 <kfree>
    np->kstack = 0;
801034f6:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
    np->state = UNUSED;
801034fd:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return -1;
80103504:	83 c4 10             	add    $0x10,%esp
80103507:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
8010350c:	eb 6d                	jmp    8010357b <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
8010350e:	83 c6 01             	add    $0x1,%esi
80103511:	83 fe 0f             	cmp    $0xf,%esi
80103514:	7f 1d                	jg     80103533 <fork+0xae>
    if(curproc->ofile[i])
80103516:	8b 44 b3 28          	mov    0x28(%ebx,%esi,4),%eax
8010351a:	85 c0                	test   %eax,%eax
8010351c:	74 f0                	je     8010350e <fork+0x89>
      np->ofile[i] = filedup(curproc->ofile[i]);
8010351e:	83 ec 0c             	sub    $0xc,%esp
80103521:	50                   	push   %eax
80103522:	e8 67 d7 ff ff       	call   80100c8e <filedup>
80103527:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010352a:	89 44 b2 28          	mov    %eax,0x28(%edx,%esi,4)
8010352e:	83 c4 10             	add    $0x10,%esp
80103531:	eb db                	jmp    8010350e <fork+0x89>
  np->cwd = idup(curproc->cwd);
80103533:	83 ec 0c             	sub    $0xc,%esp
80103536:	ff 73 68             	pushl  0x68(%ebx)
80103539:	e8 13 e0 ff ff       	call   80101551 <idup>
8010353e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
80103541:	89 47 68             	mov    %eax,0x68(%edi)
  safestrcpy(np->name, curproc->name, sizeof(curproc->name));
80103544:	83 c3 6c             	add    $0x6c,%ebx
80103547:	8d 47 6c             	lea    0x6c(%edi),%eax
8010354a:	83 c4 0c             	add    $0xc,%esp
8010354d:	6a 10                	push   $0x10
8010354f:	53                   	push   %ebx
80103550:	50                   	push   %eax
80103551:	e8 69 09 00 00       	call   80103ebf <safestrcpy>
  pid = np->pid;
80103556:	8b 5f 10             	mov    0x10(%edi),%ebx
  acquire(&ptable.lock);
80103559:	c7 04 24 40 1d 19 80 	movl   $0x80191d40,(%esp)
80103560:	e8 47 07 00 00       	call   80103cac <acquire>
  np->state = RUNNABLE;
80103565:	c7 47 0c 03 00 00 00 	movl   $0x3,0xc(%edi)
  release(&ptable.lock);
8010356c:	c7 04 24 40 1d 19 80 	movl   $0x80191d40,(%esp)
80103573:	e8 99 07 00 00       	call   80103d11 <release>
  return pid;
80103578:	83 c4 10             	add    $0x10,%esp
}
8010357b:	89 d8                	mov    %ebx,%eax
8010357d:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103580:	5b                   	pop    %ebx
80103581:	5e                   	pop    %esi
80103582:	5f                   	pop    %edi
80103583:	5d                   	pop    %ebp
80103584:	c3                   	ret    
    return -1;
80103585:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
8010358a:	eb ef                	jmp    8010357b <fork+0xf6>

8010358c <scheduler>:
{
8010358c:	55                   	push   %ebp
8010358d:	89 e5                	mov    %esp,%ebp
8010358f:	56                   	push   %esi
80103590:	53                   	push   %ebx
  struct cpu *c = mycpu();
80103591:	e8 00 fd ff ff       	call   80103296 <mycpu>
80103596:	89 c6                	mov    %eax,%esi
  c->proc = 0;
80103598:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
8010359f:	00 00 00 
801035a2:	eb 5a                	jmp    801035fe <scheduler+0x72>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801035a4:	83 c3 7c             	add    $0x7c,%ebx
801035a7:	81 fb 74 3c 19 80    	cmp    $0x80193c74,%ebx
801035ad:	73 3f                	jae    801035ee <scheduler+0x62>
      if(p->state != RUNNABLE)
801035af:	83 7b 0c 03          	cmpl   $0x3,0xc(%ebx)
801035b3:	75 ef                	jne    801035a4 <scheduler+0x18>
      c->proc = p;
801035b5:	89 9e ac 00 00 00    	mov    %ebx,0xac(%esi)
      switchuvm(p);
801035bb:	83 ec 0c             	sub    $0xc,%esp
801035be:	53                   	push   %ebx
801035bf:	e8 8b 29 00 00       	call   80105f4f <switchuvm>
      p->state = RUNNING;
801035c4:	c7 43 0c 04 00 00 00 	movl   $0x4,0xc(%ebx)
      swtch(&(c->scheduler), p->context);
801035cb:	83 c4 08             	add    $0x8,%esp
801035ce:	ff 73 1c             	pushl  0x1c(%ebx)
801035d1:	8d 46 04             	lea    0x4(%esi),%eax
801035d4:	50                   	push   %eax
801035d5:	e8 38 09 00 00       	call   80103f12 <swtch>
      switchkvm();
801035da:	e8 5e 29 00 00       	call   80105f3d <switchkvm>
      c->proc = 0;
801035df:	c7 86 ac 00 00 00 00 	movl   $0x0,0xac(%esi)
801035e6:	00 00 00 
801035e9:	83 c4 10             	add    $0x10,%esp
801035ec:	eb b6                	jmp    801035a4 <scheduler+0x18>
    release(&ptable.lock);
801035ee:	83 ec 0c             	sub    $0xc,%esp
801035f1:	68 40 1d 19 80       	push   $0x80191d40
801035f6:	e8 16 07 00 00       	call   80103d11 <release>
    sti();
801035fb:	83 c4 10             	add    $0x10,%esp
  asm volatile("sti");
801035fe:	fb                   	sti    
    acquire(&ptable.lock);
801035ff:	83 ec 0c             	sub    $0xc,%esp
80103602:	68 40 1d 19 80       	push   $0x80191d40
80103607:	e8 a0 06 00 00       	call   80103cac <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010360c:	83 c4 10             	add    $0x10,%esp
8010360f:	bb 74 1d 19 80       	mov    $0x80191d74,%ebx
80103614:	eb 91                	jmp    801035a7 <scheduler+0x1b>

80103616 <sched>:
{
80103616:	55                   	push   %ebp
80103617:	89 e5                	mov    %esp,%ebp
80103619:	56                   	push   %esi
8010361a:	53                   	push   %ebx
  struct proc *p = myproc();
8010361b:	e8 ed fc ff ff       	call   8010330d <myproc>
80103620:	89 c3                	mov    %eax,%ebx
  if(!holding(&ptable.lock))
80103622:	83 ec 0c             	sub    $0xc,%esp
80103625:	68 40 1d 19 80       	push   $0x80191d40
8010362a:	e8 3d 06 00 00       	call   80103c6c <holding>
8010362f:	83 c4 10             	add    $0x10,%esp
80103632:	85 c0                	test   %eax,%eax
80103634:	74 4f                	je     80103685 <sched+0x6f>
  if(mycpu()->ncli != 1)
80103636:	e8 5b fc ff ff       	call   80103296 <mycpu>
8010363b:	83 b8 a4 00 00 00 01 	cmpl   $0x1,0xa4(%eax)
80103642:	75 4e                	jne    80103692 <sched+0x7c>
  if(p->state == RUNNING)
80103644:	83 7b 0c 04          	cmpl   $0x4,0xc(%ebx)
80103648:	74 55                	je     8010369f <sched+0x89>
  asm volatile("pushfl; popl %0" : "=r" (eflags));
8010364a:	9c                   	pushf  
8010364b:	58                   	pop    %eax
  if(readeflags()&FL_IF)
8010364c:	f6 c4 02             	test   $0x2,%ah
8010364f:	75 5b                	jne    801036ac <sched+0x96>
  intena = mycpu()->intena;
80103651:	e8 40 fc ff ff       	call   80103296 <mycpu>
80103656:	8b b0 a8 00 00 00    	mov    0xa8(%eax),%esi
  swtch(&p->context, mycpu()->scheduler);
8010365c:	e8 35 fc ff ff       	call   80103296 <mycpu>
80103661:	83 ec 08             	sub    $0x8,%esp
80103664:	ff 70 04             	pushl  0x4(%eax)
80103667:	83 c3 1c             	add    $0x1c,%ebx
8010366a:	53                   	push   %ebx
8010366b:	e8 a2 08 00 00       	call   80103f12 <swtch>
  mycpu()->intena = intena;
80103670:	e8 21 fc ff ff       	call   80103296 <mycpu>
80103675:	89 b0 a8 00 00 00    	mov    %esi,0xa8(%eax)
}
8010367b:	83 c4 10             	add    $0x10,%esp
8010367e:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103681:	5b                   	pop    %ebx
80103682:	5e                   	pop    %esi
80103683:	5d                   	pop    %ebp
80103684:	c3                   	ret    
    panic("sched ptable.lock");
80103685:	83 ec 0c             	sub    $0xc,%esp
80103688:	68 50 6b 10 80       	push   $0x80106b50
8010368d:	e8 b6 cc ff ff       	call   80100348 <panic>
    panic("sched locks");
80103692:	83 ec 0c             	sub    $0xc,%esp
80103695:	68 62 6b 10 80       	push   $0x80106b62
8010369a:	e8 a9 cc ff ff       	call   80100348 <panic>
    panic("sched running");
8010369f:	83 ec 0c             	sub    $0xc,%esp
801036a2:	68 6e 6b 10 80       	push   $0x80106b6e
801036a7:	e8 9c cc ff ff       	call   80100348 <panic>
    panic("sched interruptible");
801036ac:	83 ec 0c             	sub    $0xc,%esp
801036af:	68 7c 6b 10 80       	push   $0x80106b7c
801036b4:	e8 8f cc ff ff       	call   80100348 <panic>

801036b9 <exit>:
{
801036b9:	55                   	push   %ebp
801036ba:	89 e5                	mov    %esp,%ebp
801036bc:	56                   	push   %esi
801036bd:	53                   	push   %ebx
  struct proc *curproc = myproc();
801036be:	e8 4a fc ff ff       	call   8010330d <myproc>
  if(curproc == initproc)
801036c3:	39 05 b8 95 10 80    	cmp    %eax,0x801095b8
801036c9:	74 09                	je     801036d4 <exit+0x1b>
801036cb:	89 c6                	mov    %eax,%esi
  for(fd = 0; fd < NOFILE; fd++){
801036cd:	bb 00 00 00 00       	mov    $0x0,%ebx
801036d2:	eb 10                	jmp    801036e4 <exit+0x2b>
    panic("init exiting");
801036d4:	83 ec 0c             	sub    $0xc,%esp
801036d7:	68 90 6b 10 80       	push   $0x80106b90
801036dc:	e8 67 cc ff ff       	call   80100348 <panic>
  for(fd = 0; fd < NOFILE; fd++){
801036e1:	83 c3 01             	add    $0x1,%ebx
801036e4:	83 fb 0f             	cmp    $0xf,%ebx
801036e7:	7f 1e                	jg     80103707 <exit+0x4e>
    if(curproc->ofile[fd]){
801036e9:	8b 44 9e 28          	mov    0x28(%esi,%ebx,4),%eax
801036ed:	85 c0                	test   %eax,%eax
801036ef:	74 f0                	je     801036e1 <exit+0x28>
      fileclose(curproc->ofile[fd]);
801036f1:	83 ec 0c             	sub    $0xc,%esp
801036f4:	50                   	push   %eax
801036f5:	e8 d9 d5 ff ff       	call   80100cd3 <fileclose>
      curproc->ofile[fd] = 0;
801036fa:	c7 44 9e 28 00 00 00 	movl   $0x0,0x28(%esi,%ebx,4)
80103701:	00 
80103702:	83 c4 10             	add    $0x10,%esp
80103705:	eb da                	jmp    801036e1 <exit+0x28>
  begin_op();
80103707:	e8 b9 f1 ff ff       	call   801028c5 <begin_op>
  iput(curproc->cwd);
8010370c:	83 ec 0c             	sub    $0xc,%esp
8010370f:	ff 76 68             	pushl  0x68(%esi)
80103712:	e8 71 df ff ff       	call   80101688 <iput>
  end_op();
80103717:	e8 23 f2 ff ff       	call   8010293f <end_op>
  curproc->cwd = 0;
8010371c:	c7 46 68 00 00 00 00 	movl   $0x0,0x68(%esi)
  acquire(&ptable.lock);
80103723:	c7 04 24 40 1d 19 80 	movl   $0x80191d40,(%esp)
8010372a:	e8 7d 05 00 00       	call   80103cac <acquire>
  wakeup1(curproc->parent);
8010372f:	8b 46 14             	mov    0x14(%esi),%eax
80103732:	e8 16 fa ff ff       	call   8010314d <wakeup1>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103737:	83 c4 10             	add    $0x10,%esp
8010373a:	bb 74 1d 19 80       	mov    $0x80191d74,%ebx
8010373f:	eb 03                	jmp    80103744 <exit+0x8b>
80103741:	83 c3 7c             	add    $0x7c,%ebx
80103744:	81 fb 74 3c 19 80    	cmp    $0x80193c74,%ebx
8010374a:	73 1a                	jae    80103766 <exit+0xad>
    if(p->parent == curproc){
8010374c:	39 73 14             	cmp    %esi,0x14(%ebx)
8010374f:	75 f0                	jne    80103741 <exit+0x88>
      p->parent = initproc;
80103751:	a1 b8 95 10 80       	mov    0x801095b8,%eax
80103756:	89 43 14             	mov    %eax,0x14(%ebx)
      if(p->state == ZOMBIE)
80103759:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
8010375d:	75 e2                	jne    80103741 <exit+0x88>
        wakeup1(initproc);
8010375f:	e8 e9 f9 ff ff       	call   8010314d <wakeup1>
80103764:	eb db                	jmp    80103741 <exit+0x88>
  curproc->state = ZOMBIE;
80103766:	c7 46 0c 05 00 00 00 	movl   $0x5,0xc(%esi)
  sched();
8010376d:	e8 a4 fe ff ff       	call   80103616 <sched>
  panic("zombie exit");
80103772:	83 ec 0c             	sub    $0xc,%esp
80103775:	68 9d 6b 10 80       	push   $0x80106b9d
8010377a:	e8 c9 cb ff ff       	call   80100348 <panic>

8010377f <yield>:
{
8010377f:	55                   	push   %ebp
80103780:	89 e5                	mov    %esp,%ebp
80103782:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80103785:	68 40 1d 19 80       	push   $0x80191d40
8010378a:	e8 1d 05 00 00       	call   80103cac <acquire>
  myproc()->state = RUNNABLE;
8010378f:	e8 79 fb ff ff       	call   8010330d <myproc>
80103794:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
8010379b:	e8 76 fe ff ff       	call   80103616 <sched>
  release(&ptable.lock);
801037a0:	c7 04 24 40 1d 19 80 	movl   $0x80191d40,(%esp)
801037a7:	e8 65 05 00 00       	call   80103d11 <release>
}
801037ac:	83 c4 10             	add    $0x10,%esp
801037af:	c9                   	leave  
801037b0:	c3                   	ret    

801037b1 <sleep>:
{
801037b1:	55                   	push   %ebp
801037b2:	89 e5                	mov    %esp,%ebp
801037b4:	56                   	push   %esi
801037b5:	53                   	push   %ebx
801037b6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  struct proc *p = myproc();
801037b9:	e8 4f fb ff ff       	call   8010330d <myproc>
  if(p == 0)
801037be:	85 c0                	test   %eax,%eax
801037c0:	74 66                	je     80103828 <sleep+0x77>
801037c2:	89 c6                	mov    %eax,%esi
  if(lk == 0)
801037c4:	85 db                	test   %ebx,%ebx
801037c6:	74 6d                	je     80103835 <sleep+0x84>
  if(lk != &ptable.lock){  //DOC: sleeplock0
801037c8:	81 fb 40 1d 19 80    	cmp    $0x80191d40,%ebx
801037ce:	74 18                	je     801037e8 <sleep+0x37>
    acquire(&ptable.lock);  //DOC: sleeplock1
801037d0:	83 ec 0c             	sub    $0xc,%esp
801037d3:	68 40 1d 19 80       	push   $0x80191d40
801037d8:	e8 cf 04 00 00       	call   80103cac <acquire>
    release(lk);
801037dd:	89 1c 24             	mov    %ebx,(%esp)
801037e0:	e8 2c 05 00 00       	call   80103d11 <release>
801037e5:	83 c4 10             	add    $0x10,%esp
  p->chan = chan;
801037e8:	8b 45 08             	mov    0x8(%ebp),%eax
801037eb:	89 46 20             	mov    %eax,0x20(%esi)
  p->state = SLEEPING;
801037ee:	c7 46 0c 02 00 00 00 	movl   $0x2,0xc(%esi)
  sched();
801037f5:	e8 1c fe ff ff       	call   80103616 <sched>
  p->chan = 0;
801037fa:	c7 46 20 00 00 00 00 	movl   $0x0,0x20(%esi)
  if(lk != &ptable.lock){  //DOC: sleeplock2
80103801:	81 fb 40 1d 19 80    	cmp    $0x80191d40,%ebx
80103807:	74 18                	je     80103821 <sleep+0x70>
    release(&ptable.lock);
80103809:	83 ec 0c             	sub    $0xc,%esp
8010380c:	68 40 1d 19 80       	push   $0x80191d40
80103811:	e8 fb 04 00 00       	call   80103d11 <release>
    acquire(lk);
80103816:	89 1c 24             	mov    %ebx,(%esp)
80103819:	e8 8e 04 00 00       	call   80103cac <acquire>
8010381e:	83 c4 10             	add    $0x10,%esp
}
80103821:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103824:	5b                   	pop    %ebx
80103825:	5e                   	pop    %esi
80103826:	5d                   	pop    %ebp
80103827:	c3                   	ret    
    panic("sleep");
80103828:	83 ec 0c             	sub    $0xc,%esp
8010382b:	68 a9 6b 10 80       	push   $0x80106ba9
80103830:	e8 13 cb ff ff       	call   80100348 <panic>
    panic("sleep without lk");
80103835:	83 ec 0c             	sub    $0xc,%esp
80103838:	68 af 6b 10 80       	push   $0x80106baf
8010383d:	e8 06 cb ff ff       	call   80100348 <panic>

80103842 <wait>:
{
80103842:	55                   	push   %ebp
80103843:	89 e5                	mov    %esp,%ebp
80103845:	56                   	push   %esi
80103846:	53                   	push   %ebx
  struct proc *curproc = myproc();
80103847:	e8 c1 fa ff ff       	call   8010330d <myproc>
8010384c:	89 c6                	mov    %eax,%esi
  acquire(&ptable.lock);
8010384e:	83 ec 0c             	sub    $0xc,%esp
80103851:	68 40 1d 19 80       	push   $0x80191d40
80103856:	e8 51 04 00 00       	call   80103cac <acquire>
8010385b:	83 c4 10             	add    $0x10,%esp
    havekids = 0;
8010385e:	b8 00 00 00 00       	mov    $0x0,%eax
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103863:	bb 74 1d 19 80       	mov    $0x80191d74,%ebx
80103868:	eb 5b                	jmp    801038c5 <wait+0x83>
        pid = p->pid;
8010386a:	8b 73 10             	mov    0x10(%ebx),%esi
        kfree(p->kstack);
8010386d:	83 ec 0c             	sub    $0xc,%esp
80103870:	ff 73 08             	pushl  0x8(%ebx)
80103873:	e8 2c e7 ff ff       	call   80101fa4 <kfree>
        p->kstack = 0;
80103878:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        freevm(p->pgdir);
8010387f:	83 c4 04             	add    $0x4,%esp
80103882:	ff 73 04             	pushl  0x4(%ebx)
80103885:	e8 62 2a 00 00       	call   801062ec <freevm>
        p->pid = 0;
8010388a:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
        p->parent = 0;
80103891:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
        p->name[0] = 0;
80103898:	c6 43 6c 00          	movb   $0x0,0x6c(%ebx)
        p->killed = 0;
8010389c:	c7 43 24 00 00 00 00 	movl   $0x0,0x24(%ebx)
        p->state = UNUSED;
801038a3:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        release(&ptable.lock);
801038aa:	c7 04 24 40 1d 19 80 	movl   $0x80191d40,(%esp)
801038b1:	e8 5b 04 00 00       	call   80103d11 <release>
        return pid;
801038b6:	83 c4 10             	add    $0x10,%esp
}
801038b9:	89 f0                	mov    %esi,%eax
801038bb:	8d 65 f8             	lea    -0x8(%ebp),%esp
801038be:	5b                   	pop    %ebx
801038bf:	5e                   	pop    %esi
801038c0:	5d                   	pop    %ebp
801038c1:	c3                   	ret    
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801038c2:	83 c3 7c             	add    $0x7c,%ebx
801038c5:	81 fb 74 3c 19 80    	cmp    $0x80193c74,%ebx
801038cb:	73 12                	jae    801038df <wait+0x9d>
      if(p->parent != curproc)
801038cd:	39 73 14             	cmp    %esi,0x14(%ebx)
801038d0:	75 f0                	jne    801038c2 <wait+0x80>
      if(p->state == ZOMBIE){
801038d2:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
801038d6:	74 92                	je     8010386a <wait+0x28>
      havekids = 1;
801038d8:	b8 01 00 00 00       	mov    $0x1,%eax
801038dd:	eb e3                	jmp    801038c2 <wait+0x80>
    if(!havekids || curproc->killed){
801038df:	85 c0                	test   %eax,%eax
801038e1:	74 06                	je     801038e9 <wait+0xa7>
801038e3:	83 7e 24 00          	cmpl   $0x0,0x24(%esi)
801038e7:	74 17                	je     80103900 <wait+0xbe>
      release(&ptable.lock);
801038e9:	83 ec 0c             	sub    $0xc,%esp
801038ec:	68 40 1d 19 80       	push   $0x80191d40
801038f1:	e8 1b 04 00 00       	call   80103d11 <release>
      return -1;
801038f6:	83 c4 10             	add    $0x10,%esp
801038f9:	be ff ff ff ff       	mov    $0xffffffff,%esi
801038fe:	eb b9                	jmp    801038b9 <wait+0x77>
    sleep(curproc, &ptable.lock);  //DOC: wait-sleep
80103900:	83 ec 08             	sub    $0x8,%esp
80103903:	68 40 1d 19 80       	push   $0x80191d40
80103908:	56                   	push   %esi
80103909:	e8 a3 fe ff ff       	call   801037b1 <sleep>
    havekids = 0;
8010390e:	83 c4 10             	add    $0x10,%esp
80103911:	e9 48 ff ff ff       	jmp    8010385e <wait+0x1c>

80103916 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80103916:	55                   	push   %ebp
80103917:	89 e5                	mov    %esp,%ebp
80103919:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);
8010391c:	68 40 1d 19 80       	push   $0x80191d40
80103921:	e8 86 03 00 00       	call   80103cac <acquire>
  wakeup1(chan);
80103926:	8b 45 08             	mov    0x8(%ebp),%eax
80103929:	e8 1f f8 ff ff       	call   8010314d <wakeup1>
  release(&ptable.lock);
8010392e:	c7 04 24 40 1d 19 80 	movl   $0x80191d40,(%esp)
80103935:	e8 d7 03 00 00       	call   80103d11 <release>
}
8010393a:	83 c4 10             	add    $0x10,%esp
8010393d:	c9                   	leave  
8010393e:	c3                   	ret    

8010393f <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
8010393f:	55                   	push   %ebp
80103940:	89 e5                	mov    %esp,%ebp
80103942:	53                   	push   %ebx
80103943:	83 ec 10             	sub    $0x10,%esp
80103946:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *p;

  acquire(&ptable.lock);
80103949:	68 40 1d 19 80       	push   $0x80191d40
8010394e:	e8 59 03 00 00       	call   80103cac <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103953:	83 c4 10             	add    $0x10,%esp
80103956:	b8 74 1d 19 80       	mov    $0x80191d74,%eax
8010395b:	3d 74 3c 19 80       	cmp    $0x80193c74,%eax
80103960:	73 3a                	jae    8010399c <kill+0x5d>
    if(p->pid == pid){
80103962:	39 58 10             	cmp    %ebx,0x10(%eax)
80103965:	74 05                	je     8010396c <kill+0x2d>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103967:	83 c0 7c             	add    $0x7c,%eax
8010396a:	eb ef                	jmp    8010395b <kill+0x1c>
      p->killed = 1;
8010396c:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80103973:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
80103977:	74 1a                	je     80103993 <kill+0x54>
        p->state = RUNNABLE;
      release(&ptable.lock);
80103979:	83 ec 0c             	sub    $0xc,%esp
8010397c:	68 40 1d 19 80       	push   $0x80191d40
80103981:	e8 8b 03 00 00       	call   80103d11 <release>
      return 0;
80103986:	83 c4 10             	add    $0x10,%esp
80103989:	b8 00 00 00 00       	mov    $0x0,%eax
    }
  }
  release(&ptable.lock);
  return -1;
}
8010398e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103991:	c9                   	leave  
80103992:	c3                   	ret    
        p->state = RUNNABLE;
80103993:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
8010399a:	eb dd                	jmp    80103979 <kill+0x3a>
  release(&ptable.lock);
8010399c:	83 ec 0c             	sub    $0xc,%esp
8010399f:	68 40 1d 19 80       	push   $0x80191d40
801039a4:	e8 68 03 00 00       	call   80103d11 <release>
  return -1;
801039a9:	83 c4 10             	add    $0x10,%esp
801039ac:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801039b1:	eb db                	jmp    8010398e <kill+0x4f>

801039b3 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
801039b3:	55                   	push   %ebp
801039b4:	89 e5                	mov    %esp,%ebp
801039b6:	56                   	push   %esi
801039b7:	53                   	push   %ebx
801039b8:	83 ec 30             	sub    $0x30,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801039bb:	bb 74 1d 19 80       	mov    $0x80191d74,%ebx
801039c0:	eb 33                	jmp    801039f5 <procdump+0x42>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
801039c2:	b8 c0 6b 10 80       	mov    $0x80106bc0,%eax
    cprintf("%d %s %s", p->pid, state, p->name);
801039c7:	8d 53 6c             	lea    0x6c(%ebx),%edx
801039ca:	52                   	push   %edx
801039cb:	50                   	push   %eax
801039cc:	ff 73 10             	pushl  0x10(%ebx)
801039cf:	68 c4 6b 10 80       	push   $0x80106bc4
801039d4:	e8 32 cc ff ff       	call   8010060b <cprintf>
    if(p->state == SLEEPING){
801039d9:	83 c4 10             	add    $0x10,%esp
801039dc:	83 7b 0c 02          	cmpl   $0x2,0xc(%ebx)
801039e0:	74 39                	je     80103a1b <procdump+0x68>
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
801039e2:	83 ec 0c             	sub    $0xc,%esp
801039e5:	68 3b 6f 10 80       	push   $0x80106f3b
801039ea:	e8 1c cc ff ff       	call   8010060b <cprintf>
801039ef:	83 c4 10             	add    $0x10,%esp
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801039f2:	83 c3 7c             	add    $0x7c,%ebx
801039f5:	81 fb 74 3c 19 80    	cmp    $0x80193c74,%ebx
801039fb:	73 61                	jae    80103a5e <procdump+0xab>
    if(p->state == UNUSED)
801039fd:	8b 43 0c             	mov    0xc(%ebx),%eax
80103a00:	85 c0                	test   %eax,%eax
80103a02:	74 ee                	je     801039f2 <procdump+0x3f>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80103a04:	83 f8 05             	cmp    $0x5,%eax
80103a07:	77 b9                	ja     801039c2 <procdump+0xf>
80103a09:	8b 04 85 20 6c 10 80 	mov    -0x7fef93e0(,%eax,4),%eax
80103a10:	85 c0                	test   %eax,%eax
80103a12:	75 b3                	jne    801039c7 <procdump+0x14>
      state = "???";
80103a14:	b8 c0 6b 10 80       	mov    $0x80106bc0,%eax
80103a19:	eb ac                	jmp    801039c7 <procdump+0x14>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80103a1b:	8b 43 1c             	mov    0x1c(%ebx),%eax
80103a1e:	8b 40 0c             	mov    0xc(%eax),%eax
80103a21:	83 c0 08             	add    $0x8,%eax
80103a24:	83 ec 08             	sub    $0x8,%esp
80103a27:	8d 55 d0             	lea    -0x30(%ebp),%edx
80103a2a:	52                   	push   %edx
80103a2b:	50                   	push   %eax
80103a2c:	e8 5a 01 00 00       	call   80103b8b <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80103a31:	83 c4 10             	add    $0x10,%esp
80103a34:	be 00 00 00 00       	mov    $0x0,%esi
80103a39:	eb 14                	jmp    80103a4f <procdump+0x9c>
        cprintf(" %p", pc[i]);
80103a3b:	83 ec 08             	sub    $0x8,%esp
80103a3e:	50                   	push   %eax
80103a3f:	68 01 66 10 80       	push   $0x80106601
80103a44:	e8 c2 cb ff ff       	call   8010060b <cprintf>
      for(i=0; i<10 && pc[i] != 0; i++)
80103a49:	83 c6 01             	add    $0x1,%esi
80103a4c:	83 c4 10             	add    $0x10,%esp
80103a4f:	83 fe 09             	cmp    $0x9,%esi
80103a52:	7f 8e                	jg     801039e2 <procdump+0x2f>
80103a54:	8b 44 b5 d0          	mov    -0x30(%ebp,%esi,4),%eax
80103a58:	85 c0                	test   %eax,%eax
80103a5a:	75 df                	jne    80103a3b <procdump+0x88>
80103a5c:	eb 84                	jmp    801039e2 <procdump+0x2f>
  }
}
80103a5e:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103a61:	5b                   	pop    %ebx
80103a62:	5e                   	pop    %esi
80103a63:	5d                   	pop    %ebp
80103a64:	c3                   	ret    

80103a65 <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
80103a65:	55                   	push   %ebp
80103a66:	89 e5                	mov    %esp,%ebp
80103a68:	53                   	push   %ebx
80103a69:	83 ec 0c             	sub    $0xc,%esp
80103a6c:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&lk->lk, "sleep lock");
80103a6f:	68 38 6c 10 80       	push   $0x80106c38
80103a74:	8d 43 04             	lea    0x4(%ebx),%eax
80103a77:	50                   	push   %eax
80103a78:	e8 f3 00 00 00       	call   80103b70 <initlock>
  lk->name = name;
80103a7d:	8b 45 0c             	mov    0xc(%ebp),%eax
80103a80:	89 43 38             	mov    %eax,0x38(%ebx)
  lk->locked = 0;
80103a83:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103a89:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
}
80103a90:	83 c4 10             	add    $0x10,%esp
80103a93:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103a96:	c9                   	leave  
80103a97:	c3                   	ret    

80103a98 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80103a98:	55                   	push   %ebp
80103a99:	89 e5                	mov    %esp,%ebp
80103a9b:	56                   	push   %esi
80103a9c:	53                   	push   %ebx
80103a9d:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103aa0:	8d 73 04             	lea    0x4(%ebx),%esi
80103aa3:	83 ec 0c             	sub    $0xc,%esp
80103aa6:	56                   	push   %esi
80103aa7:	e8 00 02 00 00       	call   80103cac <acquire>
  while (lk->locked) {
80103aac:	83 c4 10             	add    $0x10,%esp
80103aaf:	eb 0d                	jmp    80103abe <acquiresleep+0x26>
    sleep(lk, &lk->lk);
80103ab1:	83 ec 08             	sub    $0x8,%esp
80103ab4:	56                   	push   %esi
80103ab5:	53                   	push   %ebx
80103ab6:	e8 f6 fc ff ff       	call   801037b1 <sleep>
80103abb:	83 c4 10             	add    $0x10,%esp
  while (lk->locked) {
80103abe:	83 3b 00             	cmpl   $0x0,(%ebx)
80103ac1:	75 ee                	jne    80103ab1 <acquiresleep+0x19>
  }
  lk->locked = 1;
80103ac3:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
  lk->pid = myproc()->pid;
80103ac9:	e8 3f f8 ff ff       	call   8010330d <myproc>
80103ace:	8b 40 10             	mov    0x10(%eax),%eax
80103ad1:	89 43 3c             	mov    %eax,0x3c(%ebx)
  release(&lk->lk);
80103ad4:	83 ec 0c             	sub    $0xc,%esp
80103ad7:	56                   	push   %esi
80103ad8:	e8 34 02 00 00       	call   80103d11 <release>
}
80103add:	83 c4 10             	add    $0x10,%esp
80103ae0:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103ae3:	5b                   	pop    %ebx
80103ae4:	5e                   	pop    %esi
80103ae5:	5d                   	pop    %ebp
80103ae6:	c3                   	ret    

80103ae7 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80103ae7:	55                   	push   %ebp
80103ae8:	89 e5                	mov    %esp,%ebp
80103aea:	56                   	push   %esi
80103aeb:	53                   	push   %ebx
80103aec:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103aef:	8d 73 04             	lea    0x4(%ebx),%esi
80103af2:	83 ec 0c             	sub    $0xc,%esp
80103af5:	56                   	push   %esi
80103af6:	e8 b1 01 00 00       	call   80103cac <acquire>
  lk->locked = 0;
80103afb:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103b01:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
  wakeup(lk);
80103b08:	89 1c 24             	mov    %ebx,(%esp)
80103b0b:	e8 06 fe ff ff       	call   80103916 <wakeup>
  release(&lk->lk);
80103b10:	89 34 24             	mov    %esi,(%esp)
80103b13:	e8 f9 01 00 00       	call   80103d11 <release>
}
80103b18:	83 c4 10             	add    $0x10,%esp
80103b1b:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103b1e:	5b                   	pop    %ebx
80103b1f:	5e                   	pop    %esi
80103b20:	5d                   	pop    %ebp
80103b21:	c3                   	ret    

80103b22 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80103b22:	55                   	push   %ebp
80103b23:	89 e5                	mov    %esp,%ebp
80103b25:	56                   	push   %esi
80103b26:	53                   	push   %ebx
80103b27:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;
  
  acquire(&lk->lk);
80103b2a:	8d 73 04             	lea    0x4(%ebx),%esi
80103b2d:	83 ec 0c             	sub    $0xc,%esp
80103b30:	56                   	push   %esi
80103b31:	e8 76 01 00 00       	call   80103cac <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
80103b36:	83 c4 10             	add    $0x10,%esp
80103b39:	83 3b 00             	cmpl   $0x0,(%ebx)
80103b3c:	75 17                	jne    80103b55 <holdingsleep+0x33>
80103b3e:	bb 00 00 00 00       	mov    $0x0,%ebx
  release(&lk->lk);
80103b43:	83 ec 0c             	sub    $0xc,%esp
80103b46:	56                   	push   %esi
80103b47:	e8 c5 01 00 00       	call   80103d11 <release>
  return r;
}
80103b4c:	89 d8                	mov    %ebx,%eax
80103b4e:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103b51:	5b                   	pop    %ebx
80103b52:	5e                   	pop    %esi
80103b53:	5d                   	pop    %ebp
80103b54:	c3                   	ret    
  r = lk->locked && (lk->pid == myproc()->pid);
80103b55:	8b 5b 3c             	mov    0x3c(%ebx),%ebx
80103b58:	e8 b0 f7 ff ff       	call   8010330d <myproc>
80103b5d:	3b 58 10             	cmp    0x10(%eax),%ebx
80103b60:	74 07                	je     80103b69 <holdingsleep+0x47>
80103b62:	bb 00 00 00 00       	mov    $0x0,%ebx
80103b67:	eb da                	jmp    80103b43 <holdingsleep+0x21>
80103b69:	bb 01 00 00 00       	mov    $0x1,%ebx
80103b6e:	eb d3                	jmp    80103b43 <holdingsleep+0x21>

80103b70 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80103b70:	55                   	push   %ebp
80103b71:	89 e5                	mov    %esp,%ebp
80103b73:	8b 45 08             	mov    0x8(%ebp),%eax
  lk->name = name;
80103b76:	8b 55 0c             	mov    0xc(%ebp),%edx
80103b79:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80103b7c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80103b82:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80103b89:	5d                   	pop    %ebp
80103b8a:	c3                   	ret    

80103b8b <getcallerpcs>:
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80103b8b:	55                   	push   %ebp
80103b8c:	89 e5                	mov    %esp,%ebp
80103b8e:	53                   	push   %ebx
80103b8f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80103b92:	8b 45 08             	mov    0x8(%ebp),%eax
80103b95:	8d 50 f8             	lea    -0x8(%eax),%edx
  for(i = 0; i < 10; i++){
80103b98:	b8 00 00 00 00       	mov    $0x0,%eax
80103b9d:	83 f8 09             	cmp    $0x9,%eax
80103ba0:	7f 25                	jg     80103bc7 <getcallerpcs+0x3c>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80103ba2:	8d 9a 00 00 00 80    	lea    -0x80000000(%edx),%ebx
80103ba8:	81 fb fe ff ff 7f    	cmp    $0x7ffffffe,%ebx
80103bae:	77 17                	ja     80103bc7 <getcallerpcs+0x3c>
      break;
    pcs[i] = ebp[1];     // saved %eip
80103bb0:	8b 5a 04             	mov    0x4(%edx),%ebx
80103bb3:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
    ebp = (uint*)ebp[0]; // saved %ebp
80103bb6:	8b 12                	mov    (%edx),%edx
  for(i = 0; i < 10; i++){
80103bb8:	83 c0 01             	add    $0x1,%eax
80103bbb:	eb e0                	jmp    80103b9d <getcallerpcs+0x12>
  }
  for(; i < 10; i++)
    pcs[i] = 0;
80103bbd:	c7 04 81 00 00 00 00 	movl   $0x0,(%ecx,%eax,4)
  for(; i < 10; i++)
80103bc4:	83 c0 01             	add    $0x1,%eax
80103bc7:	83 f8 09             	cmp    $0x9,%eax
80103bca:	7e f1                	jle    80103bbd <getcallerpcs+0x32>
}
80103bcc:	5b                   	pop    %ebx
80103bcd:	5d                   	pop    %ebp
80103bce:	c3                   	ret    

80103bcf <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80103bcf:	55                   	push   %ebp
80103bd0:	89 e5                	mov    %esp,%ebp
80103bd2:	53                   	push   %ebx
80103bd3:	83 ec 04             	sub    $0x4,%esp
80103bd6:	9c                   	pushf  
80103bd7:	5b                   	pop    %ebx
  asm volatile("cli");
80103bd8:	fa                   	cli    
  int eflags;

  eflags = readeflags();
  cli();
  if(mycpu()->ncli == 0)
80103bd9:	e8 b8 f6 ff ff       	call   80103296 <mycpu>
80103bde:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103be5:	74 12                	je     80103bf9 <pushcli+0x2a>
    mycpu()->intena = eflags & FL_IF;
  mycpu()->ncli += 1;
80103be7:	e8 aa f6 ff ff       	call   80103296 <mycpu>
80103bec:	83 80 a4 00 00 00 01 	addl   $0x1,0xa4(%eax)
}
80103bf3:	83 c4 04             	add    $0x4,%esp
80103bf6:	5b                   	pop    %ebx
80103bf7:	5d                   	pop    %ebp
80103bf8:	c3                   	ret    
    mycpu()->intena = eflags & FL_IF;
80103bf9:	e8 98 f6 ff ff       	call   80103296 <mycpu>
80103bfe:	81 e3 00 02 00 00    	and    $0x200,%ebx
80103c04:	89 98 a8 00 00 00    	mov    %ebx,0xa8(%eax)
80103c0a:	eb db                	jmp    80103be7 <pushcli+0x18>

80103c0c <popcli>:

void
popcli(void)
{
80103c0c:	55                   	push   %ebp
80103c0d:	89 e5                	mov    %esp,%ebp
80103c0f:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103c12:	9c                   	pushf  
80103c13:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103c14:	f6 c4 02             	test   $0x2,%ah
80103c17:	75 28                	jne    80103c41 <popcli+0x35>
    panic("popcli - interruptible");
  if(--mycpu()->ncli < 0)
80103c19:	e8 78 f6 ff ff       	call   80103296 <mycpu>
80103c1e:	8b 88 a4 00 00 00    	mov    0xa4(%eax),%ecx
80103c24:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103c27:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
80103c2d:	85 d2                	test   %edx,%edx
80103c2f:	78 1d                	js     80103c4e <popcli+0x42>
    panic("popcli");
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103c31:	e8 60 f6 ff ff       	call   80103296 <mycpu>
80103c36:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103c3d:	74 1c                	je     80103c5b <popcli+0x4f>
    sti();
}
80103c3f:	c9                   	leave  
80103c40:	c3                   	ret    
    panic("popcli - interruptible");
80103c41:	83 ec 0c             	sub    $0xc,%esp
80103c44:	68 43 6c 10 80       	push   $0x80106c43
80103c49:	e8 fa c6 ff ff       	call   80100348 <panic>
    panic("popcli");
80103c4e:	83 ec 0c             	sub    $0xc,%esp
80103c51:	68 5a 6c 10 80       	push   $0x80106c5a
80103c56:	e8 ed c6 ff ff       	call   80100348 <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103c5b:	e8 36 f6 ff ff       	call   80103296 <mycpu>
80103c60:	83 b8 a8 00 00 00 00 	cmpl   $0x0,0xa8(%eax)
80103c67:	74 d6                	je     80103c3f <popcli+0x33>
  asm volatile("sti");
80103c69:	fb                   	sti    
}
80103c6a:	eb d3                	jmp    80103c3f <popcli+0x33>

80103c6c <holding>:
{
80103c6c:	55                   	push   %ebp
80103c6d:	89 e5                	mov    %esp,%ebp
80103c6f:	53                   	push   %ebx
80103c70:	83 ec 04             	sub    $0x4,%esp
80103c73:	8b 5d 08             	mov    0x8(%ebp),%ebx
  pushcli();
80103c76:	e8 54 ff ff ff       	call   80103bcf <pushcli>
  r = lock->locked && lock->cpu == mycpu();
80103c7b:	83 3b 00             	cmpl   $0x0,(%ebx)
80103c7e:	75 12                	jne    80103c92 <holding+0x26>
80103c80:	bb 00 00 00 00       	mov    $0x0,%ebx
  popcli();
80103c85:	e8 82 ff ff ff       	call   80103c0c <popcli>
}
80103c8a:	89 d8                	mov    %ebx,%eax
80103c8c:	83 c4 04             	add    $0x4,%esp
80103c8f:	5b                   	pop    %ebx
80103c90:	5d                   	pop    %ebp
80103c91:	c3                   	ret    
  r = lock->locked && lock->cpu == mycpu();
80103c92:	8b 5b 08             	mov    0x8(%ebx),%ebx
80103c95:	e8 fc f5 ff ff       	call   80103296 <mycpu>
80103c9a:	39 c3                	cmp    %eax,%ebx
80103c9c:	74 07                	je     80103ca5 <holding+0x39>
80103c9e:	bb 00 00 00 00       	mov    $0x0,%ebx
80103ca3:	eb e0                	jmp    80103c85 <holding+0x19>
80103ca5:	bb 01 00 00 00       	mov    $0x1,%ebx
80103caa:	eb d9                	jmp    80103c85 <holding+0x19>

80103cac <acquire>:
{
80103cac:	55                   	push   %ebp
80103cad:	89 e5                	mov    %esp,%ebp
80103caf:	53                   	push   %ebx
80103cb0:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80103cb3:	e8 17 ff ff ff       	call   80103bcf <pushcli>
  if(holding(lk))
80103cb8:	83 ec 0c             	sub    $0xc,%esp
80103cbb:	ff 75 08             	pushl  0x8(%ebp)
80103cbe:	e8 a9 ff ff ff       	call   80103c6c <holding>
80103cc3:	83 c4 10             	add    $0x10,%esp
80103cc6:	85 c0                	test   %eax,%eax
80103cc8:	75 3a                	jne    80103d04 <acquire+0x58>
  while(xchg(&lk->locked, 1) != 0)
80103cca:	8b 55 08             	mov    0x8(%ebp),%edx
  asm volatile("lock; xchgl %0, %1" :
80103ccd:	b8 01 00 00 00       	mov    $0x1,%eax
80103cd2:	f0 87 02             	lock xchg %eax,(%edx)
80103cd5:	85 c0                	test   %eax,%eax
80103cd7:	75 f1                	jne    80103cca <acquire+0x1e>
  __sync_synchronize();
80103cd9:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  lk->cpu = mycpu();
80103cde:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103ce1:	e8 b0 f5 ff ff       	call   80103296 <mycpu>
80103ce6:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
80103ce9:	8b 45 08             	mov    0x8(%ebp),%eax
80103cec:	83 c0 0c             	add    $0xc,%eax
80103cef:	83 ec 08             	sub    $0x8,%esp
80103cf2:	50                   	push   %eax
80103cf3:	8d 45 08             	lea    0x8(%ebp),%eax
80103cf6:	50                   	push   %eax
80103cf7:	e8 8f fe ff ff       	call   80103b8b <getcallerpcs>
}
80103cfc:	83 c4 10             	add    $0x10,%esp
80103cff:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103d02:	c9                   	leave  
80103d03:	c3                   	ret    
    panic("acquire");
80103d04:	83 ec 0c             	sub    $0xc,%esp
80103d07:	68 61 6c 10 80       	push   $0x80106c61
80103d0c:	e8 37 c6 ff ff       	call   80100348 <panic>

80103d11 <release>:
{
80103d11:	55                   	push   %ebp
80103d12:	89 e5                	mov    %esp,%ebp
80103d14:	53                   	push   %ebx
80103d15:	83 ec 10             	sub    $0x10,%esp
80103d18:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holding(lk))
80103d1b:	53                   	push   %ebx
80103d1c:	e8 4b ff ff ff       	call   80103c6c <holding>
80103d21:	83 c4 10             	add    $0x10,%esp
80103d24:	85 c0                	test   %eax,%eax
80103d26:	74 23                	je     80103d4b <release+0x3a>
  lk->pcs[0] = 0;
80103d28:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
  lk->cpu = 0;
80103d2f:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
  __sync_synchronize();
80103d36:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
80103d3b:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  popcli();
80103d41:	e8 c6 fe ff ff       	call   80103c0c <popcli>
}
80103d46:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103d49:	c9                   	leave  
80103d4a:	c3                   	ret    
    panic("release");
80103d4b:	83 ec 0c             	sub    $0xc,%esp
80103d4e:	68 69 6c 10 80       	push   $0x80106c69
80103d53:	e8 f0 c5 ff ff       	call   80100348 <panic>

80103d58 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80103d58:	55                   	push   %ebp
80103d59:	89 e5                	mov    %esp,%ebp
80103d5b:	57                   	push   %edi
80103d5c:	53                   	push   %ebx
80103d5d:	8b 55 08             	mov    0x8(%ebp),%edx
80103d60:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if ((int)dst%4 == 0 && n%4 == 0){
80103d63:	f6 c2 03             	test   $0x3,%dl
80103d66:	75 05                	jne    80103d6d <memset+0x15>
80103d68:	f6 c1 03             	test   $0x3,%cl
80103d6b:	74 0e                	je     80103d7b <memset+0x23>
  asm volatile("cld; rep stosb" :
80103d6d:	89 d7                	mov    %edx,%edi
80103d6f:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d72:	fc                   	cld    
80103d73:	f3 aa                	rep stos %al,%es:(%edi)
    c &= 0xFF;
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
  } else
    stosb(dst, c, n);
  return dst;
}
80103d75:	89 d0                	mov    %edx,%eax
80103d77:	5b                   	pop    %ebx
80103d78:	5f                   	pop    %edi
80103d79:	5d                   	pop    %ebp
80103d7a:	c3                   	ret    
    c &= 0xFF;
80103d7b:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80103d7f:	c1 e9 02             	shr    $0x2,%ecx
80103d82:	89 f8                	mov    %edi,%eax
80103d84:	c1 e0 18             	shl    $0x18,%eax
80103d87:	89 fb                	mov    %edi,%ebx
80103d89:	c1 e3 10             	shl    $0x10,%ebx
80103d8c:	09 d8                	or     %ebx,%eax
80103d8e:	89 fb                	mov    %edi,%ebx
80103d90:	c1 e3 08             	shl    $0x8,%ebx
80103d93:	09 d8                	or     %ebx,%eax
80103d95:	09 f8                	or     %edi,%eax
  asm volatile("cld; rep stosl" :
80103d97:	89 d7                	mov    %edx,%edi
80103d99:	fc                   	cld    
80103d9a:	f3 ab                	rep stos %eax,%es:(%edi)
80103d9c:	eb d7                	jmp    80103d75 <memset+0x1d>

80103d9e <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80103d9e:	55                   	push   %ebp
80103d9f:	89 e5                	mov    %esp,%ebp
80103da1:	56                   	push   %esi
80103da2:	53                   	push   %ebx
80103da3:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103da6:	8b 55 0c             	mov    0xc(%ebp),%edx
80103da9:	8b 45 10             	mov    0x10(%ebp),%eax
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80103dac:	8d 70 ff             	lea    -0x1(%eax),%esi
80103daf:	85 c0                	test   %eax,%eax
80103db1:	74 1c                	je     80103dcf <memcmp+0x31>
    if(*s1 != *s2)
80103db3:	0f b6 01             	movzbl (%ecx),%eax
80103db6:	0f b6 1a             	movzbl (%edx),%ebx
80103db9:	38 d8                	cmp    %bl,%al
80103dbb:	75 0a                	jne    80103dc7 <memcmp+0x29>
      return *s1 - *s2;
    s1++, s2++;
80103dbd:	83 c1 01             	add    $0x1,%ecx
80103dc0:	83 c2 01             	add    $0x1,%edx
  while(n-- > 0){
80103dc3:	89 f0                	mov    %esi,%eax
80103dc5:	eb e5                	jmp    80103dac <memcmp+0xe>
      return *s1 - *s2;
80103dc7:	0f b6 c0             	movzbl %al,%eax
80103dca:	0f b6 db             	movzbl %bl,%ebx
80103dcd:	29 d8                	sub    %ebx,%eax
  }

  return 0;
}
80103dcf:	5b                   	pop    %ebx
80103dd0:	5e                   	pop    %esi
80103dd1:	5d                   	pop    %ebp
80103dd2:	c3                   	ret    

80103dd3 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80103dd3:	55                   	push   %ebp
80103dd4:	89 e5                	mov    %esp,%ebp
80103dd6:	56                   	push   %esi
80103dd7:	53                   	push   %ebx
80103dd8:	8b 45 08             	mov    0x8(%ebp),%eax
80103ddb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103dde:	8b 55 10             	mov    0x10(%ebp),%edx
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80103de1:	39 c1                	cmp    %eax,%ecx
80103de3:	73 3a                	jae    80103e1f <memmove+0x4c>
80103de5:	8d 1c 11             	lea    (%ecx,%edx,1),%ebx
80103de8:	39 c3                	cmp    %eax,%ebx
80103dea:	76 37                	jbe    80103e23 <memmove+0x50>
    s += n;
    d += n;
80103dec:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
    while(n-- > 0)
80103def:	eb 0d                	jmp    80103dfe <memmove+0x2b>
      *--d = *--s;
80103df1:	83 eb 01             	sub    $0x1,%ebx
80103df4:	83 e9 01             	sub    $0x1,%ecx
80103df7:	0f b6 13             	movzbl (%ebx),%edx
80103dfa:	88 11                	mov    %dl,(%ecx)
    while(n-- > 0)
80103dfc:	89 f2                	mov    %esi,%edx
80103dfe:	8d 72 ff             	lea    -0x1(%edx),%esi
80103e01:	85 d2                	test   %edx,%edx
80103e03:	75 ec                	jne    80103df1 <memmove+0x1e>
80103e05:	eb 14                	jmp    80103e1b <memmove+0x48>
  } else
    while(n-- > 0)
      *d++ = *s++;
80103e07:	0f b6 11             	movzbl (%ecx),%edx
80103e0a:	88 13                	mov    %dl,(%ebx)
80103e0c:	8d 5b 01             	lea    0x1(%ebx),%ebx
80103e0f:	8d 49 01             	lea    0x1(%ecx),%ecx
    while(n-- > 0)
80103e12:	89 f2                	mov    %esi,%edx
80103e14:	8d 72 ff             	lea    -0x1(%edx),%esi
80103e17:	85 d2                	test   %edx,%edx
80103e19:	75 ec                	jne    80103e07 <memmove+0x34>

  return dst;
}
80103e1b:	5b                   	pop    %ebx
80103e1c:	5e                   	pop    %esi
80103e1d:	5d                   	pop    %ebp
80103e1e:	c3                   	ret    
80103e1f:	89 c3                	mov    %eax,%ebx
80103e21:	eb f1                	jmp    80103e14 <memmove+0x41>
80103e23:	89 c3                	mov    %eax,%ebx
80103e25:	eb ed                	jmp    80103e14 <memmove+0x41>

80103e27 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80103e27:	55                   	push   %ebp
80103e28:	89 e5                	mov    %esp,%ebp
  return memmove(dst, src, n);
80103e2a:	ff 75 10             	pushl  0x10(%ebp)
80103e2d:	ff 75 0c             	pushl  0xc(%ebp)
80103e30:	ff 75 08             	pushl  0x8(%ebp)
80103e33:	e8 9b ff ff ff       	call   80103dd3 <memmove>
}
80103e38:	c9                   	leave  
80103e39:	c3                   	ret    

80103e3a <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80103e3a:	55                   	push   %ebp
80103e3b:	89 e5                	mov    %esp,%ebp
80103e3d:	53                   	push   %ebx
80103e3e:	8b 55 08             	mov    0x8(%ebp),%edx
80103e41:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103e44:	8b 45 10             	mov    0x10(%ebp),%eax
  while(n > 0 && *p && *p == *q)
80103e47:	eb 09                	jmp    80103e52 <strncmp+0x18>
    n--, p++, q++;
80103e49:	83 e8 01             	sub    $0x1,%eax
80103e4c:	83 c2 01             	add    $0x1,%edx
80103e4f:	83 c1 01             	add    $0x1,%ecx
  while(n > 0 && *p && *p == *q)
80103e52:	85 c0                	test   %eax,%eax
80103e54:	74 0b                	je     80103e61 <strncmp+0x27>
80103e56:	0f b6 1a             	movzbl (%edx),%ebx
80103e59:	84 db                	test   %bl,%bl
80103e5b:	74 04                	je     80103e61 <strncmp+0x27>
80103e5d:	3a 19                	cmp    (%ecx),%bl
80103e5f:	74 e8                	je     80103e49 <strncmp+0xf>
  if(n == 0)
80103e61:	85 c0                	test   %eax,%eax
80103e63:	74 0b                	je     80103e70 <strncmp+0x36>
    return 0;
  return (uchar)*p - (uchar)*q;
80103e65:	0f b6 02             	movzbl (%edx),%eax
80103e68:	0f b6 11             	movzbl (%ecx),%edx
80103e6b:	29 d0                	sub    %edx,%eax
}
80103e6d:	5b                   	pop    %ebx
80103e6e:	5d                   	pop    %ebp
80103e6f:	c3                   	ret    
    return 0;
80103e70:	b8 00 00 00 00       	mov    $0x0,%eax
80103e75:	eb f6                	jmp    80103e6d <strncmp+0x33>

80103e77 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80103e77:	55                   	push   %ebp
80103e78:	89 e5                	mov    %esp,%ebp
80103e7a:	57                   	push   %edi
80103e7b:	56                   	push   %esi
80103e7c:	53                   	push   %ebx
80103e7d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103e80:	8b 4d 10             	mov    0x10(%ebp),%ecx
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
80103e83:	8b 45 08             	mov    0x8(%ebp),%eax
80103e86:	eb 04                	jmp    80103e8c <strncpy+0x15>
80103e88:	89 fb                	mov    %edi,%ebx
80103e8a:	89 f0                	mov    %esi,%eax
80103e8c:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103e8f:	85 c9                	test   %ecx,%ecx
80103e91:	7e 1d                	jle    80103eb0 <strncpy+0x39>
80103e93:	8d 7b 01             	lea    0x1(%ebx),%edi
80103e96:	8d 70 01             	lea    0x1(%eax),%esi
80103e99:	0f b6 1b             	movzbl (%ebx),%ebx
80103e9c:	88 18                	mov    %bl,(%eax)
80103e9e:	89 d1                	mov    %edx,%ecx
80103ea0:	84 db                	test   %bl,%bl
80103ea2:	75 e4                	jne    80103e88 <strncpy+0x11>
80103ea4:	89 f0                	mov    %esi,%eax
80103ea6:	eb 08                	jmp    80103eb0 <strncpy+0x39>
    ;
  while(n-- > 0)
    *s++ = 0;
80103ea8:	c6 00 00             	movb   $0x0,(%eax)
  while(n-- > 0)
80103eab:	89 ca                	mov    %ecx,%edx
    *s++ = 0;
80103ead:	8d 40 01             	lea    0x1(%eax),%eax
  while(n-- > 0)
80103eb0:	8d 4a ff             	lea    -0x1(%edx),%ecx
80103eb3:	85 d2                	test   %edx,%edx
80103eb5:	7f f1                	jg     80103ea8 <strncpy+0x31>
  return os;
}
80103eb7:	8b 45 08             	mov    0x8(%ebp),%eax
80103eba:	5b                   	pop    %ebx
80103ebb:	5e                   	pop    %esi
80103ebc:	5f                   	pop    %edi
80103ebd:	5d                   	pop    %ebp
80103ebe:	c3                   	ret    

80103ebf <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80103ebf:	55                   	push   %ebp
80103ec0:	89 e5                	mov    %esp,%ebp
80103ec2:	57                   	push   %edi
80103ec3:	56                   	push   %esi
80103ec4:	53                   	push   %ebx
80103ec5:	8b 45 08             	mov    0x8(%ebp),%eax
80103ec8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103ecb:	8b 55 10             	mov    0x10(%ebp),%edx
  char *os;

  os = s;
  if(n <= 0)
80103ece:	85 d2                	test   %edx,%edx
80103ed0:	7e 23                	jle    80103ef5 <safestrcpy+0x36>
80103ed2:	89 c1                	mov    %eax,%ecx
80103ed4:	eb 04                	jmp    80103eda <safestrcpy+0x1b>
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
80103ed6:	89 fb                	mov    %edi,%ebx
80103ed8:	89 f1                	mov    %esi,%ecx
80103eda:	83 ea 01             	sub    $0x1,%edx
80103edd:	85 d2                	test   %edx,%edx
80103edf:	7e 11                	jle    80103ef2 <safestrcpy+0x33>
80103ee1:	8d 7b 01             	lea    0x1(%ebx),%edi
80103ee4:	8d 71 01             	lea    0x1(%ecx),%esi
80103ee7:	0f b6 1b             	movzbl (%ebx),%ebx
80103eea:	88 19                	mov    %bl,(%ecx)
80103eec:	84 db                	test   %bl,%bl
80103eee:	75 e6                	jne    80103ed6 <safestrcpy+0x17>
80103ef0:	89 f1                	mov    %esi,%ecx
    ;
  *s = 0;
80103ef2:	c6 01 00             	movb   $0x0,(%ecx)
  return os;
}
80103ef5:	5b                   	pop    %ebx
80103ef6:	5e                   	pop    %esi
80103ef7:	5f                   	pop    %edi
80103ef8:	5d                   	pop    %ebp
80103ef9:	c3                   	ret    

80103efa <strlen>:

int
strlen(const char *s)
{
80103efa:	55                   	push   %ebp
80103efb:	89 e5                	mov    %esp,%ebp
80103efd:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
80103f00:	b8 00 00 00 00       	mov    $0x0,%eax
80103f05:	eb 03                	jmp    80103f0a <strlen+0x10>
80103f07:	83 c0 01             	add    $0x1,%eax
80103f0a:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
80103f0e:	75 f7                	jne    80103f07 <strlen+0xd>
    ;
  return n;
}
80103f10:	5d                   	pop    %ebp
80103f11:	c3                   	ret    

80103f12 <swtch>:
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax
80103f12:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80103f16:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-saved registers
  pushl %ebp
80103f1a:	55                   	push   %ebp
  pushl %ebx
80103f1b:	53                   	push   %ebx
  pushl %esi
80103f1c:	56                   	push   %esi
  pushl %edi
80103f1d:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80103f1e:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80103f20:	89 d4                	mov    %edx,%esp

  # Load new callee-saved registers
  popl %edi
80103f22:	5f                   	pop    %edi
  popl %esi
80103f23:	5e                   	pop    %esi
  popl %ebx
80103f24:	5b                   	pop    %ebx
  popl %ebp
80103f25:	5d                   	pop    %ebp
  ret
80103f26:	c3                   	ret    

80103f27 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80103f27:	55                   	push   %ebp
80103f28:	89 e5                	mov    %esp,%ebp
80103f2a:	53                   	push   %ebx
80103f2b:	83 ec 04             	sub    $0x4,%esp
80103f2e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *curproc = myproc();
80103f31:	e8 d7 f3 ff ff       	call   8010330d <myproc>

  if(addr >= curproc->sz || addr+4 > curproc->sz)
80103f36:	8b 00                	mov    (%eax),%eax
80103f38:	39 d8                	cmp    %ebx,%eax
80103f3a:	76 19                	jbe    80103f55 <fetchint+0x2e>
80103f3c:	8d 53 04             	lea    0x4(%ebx),%edx
80103f3f:	39 d0                	cmp    %edx,%eax
80103f41:	72 19                	jb     80103f5c <fetchint+0x35>
    return -1;
  *ip = *(int*)(addr);
80103f43:	8b 13                	mov    (%ebx),%edx
80103f45:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f48:	89 10                	mov    %edx,(%eax)
  return 0;
80103f4a:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103f4f:	83 c4 04             	add    $0x4,%esp
80103f52:	5b                   	pop    %ebx
80103f53:	5d                   	pop    %ebp
80103f54:	c3                   	ret    
    return -1;
80103f55:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f5a:	eb f3                	jmp    80103f4f <fetchint+0x28>
80103f5c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f61:	eb ec                	jmp    80103f4f <fetchint+0x28>

80103f63 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80103f63:	55                   	push   %ebp
80103f64:	89 e5                	mov    %esp,%ebp
80103f66:	53                   	push   %ebx
80103f67:	83 ec 04             	sub    $0x4,%esp
80103f6a:	8b 5d 08             	mov    0x8(%ebp),%ebx
  char *s, *ep;
  struct proc *curproc = myproc();
80103f6d:	e8 9b f3 ff ff       	call   8010330d <myproc>

  if(addr >= curproc->sz)
80103f72:	39 18                	cmp    %ebx,(%eax)
80103f74:	76 26                	jbe    80103f9c <fetchstr+0x39>
    return -1;
  *pp = (char*)addr;
80103f76:	8b 55 0c             	mov    0xc(%ebp),%edx
80103f79:	89 1a                	mov    %ebx,(%edx)
  ep = (char*)curproc->sz;
80103f7b:	8b 10                	mov    (%eax),%edx
  for(s = *pp; s < ep; s++){
80103f7d:	89 d8                	mov    %ebx,%eax
80103f7f:	39 d0                	cmp    %edx,%eax
80103f81:	73 0e                	jae    80103f91 <fetchstr+0x2e>
    if(*s == 0)
80103f83:	80 38 00             	cmpb   $0x0,(%eax)
80103f86:	74 05                	je     80103f8d <fetchstr+0x2a>
  for(s = *pp; s < ep; s++){
80103f88:	83 c0 01             	add    $0x1,%eax
80103f8b:	eb f2                	jmp    80103f7f <fetchstr+0x1c>
      return s - *pp;
80103f8d:	29 d8                	sub    %ebx,%eax
80103f8f:	eb 05                	jmp    80103f96 <fetchstr+0x33>
  }
  return -1;
80103f91:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80103f96:	83 c4 04             	add    $0x4,%esp
80103f99:	5b                   	pop    %ebx
80103f9a:	5d                   	pop    %ebp
80103f9b:	c3                   	ret    
    return -1;
80103f9c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103fa1:	eb f3                	jmp    80103f96 <fetchstr+0x33>

80103fa3 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80103fa3:	55                   	push   %ebp
80103fa4:	89 e5                	mov    %esp,%ebp
80103fa6:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
80103fa9:	e8 5f f3 ff ff       	call   8010330d <myproc>
80103fae:	8b 50 18             	mov    0x18(%eax),%edx
80103fb1:	8b 45 08             	mov    0x8(%ebp),%eax
80103fb4:	c1 e0 02             	shl    $0x2,%eax
80103fb7:	03 42 44             	add    0x44(%edx),%eax
80103fba:	83 ec 08             	sub    $0x8,%esp
80103fbd:	ff 75 0c             	pushl  0xc(%ebp)
80103fc0:	83 c0 04             	add    $0x4,%eax
80103fc3:	50                   	push   %eax
80103fc4:	e8 5e ff ff ff       	call   80103f27 <fetchint>
}
80103fc9:	c9                   	leave  
80103fca:	c3                   	ret    

80103fcb <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80103fcb:	55                   	push   %ebp
80103fcc:	89 e5                	mov    %esp,%ebp
80103fce:	56                   	push   %esi
80103fcf:	53                   	push   %ebx
80103fd0:	83 ec 10             	sub    $0x10,%esp
80103fd3:	8b 5d 10             	mov    0x10(%ebp),%ebx
  int i;
  struct proc *curproc = myproc();
80103fd6:	e8 32 f3 ff ff       	call   8010330d <myproc>
80103fdb:	89 c6                	mov    %eax,%esi
 
  if(argint(n, &i) < 0)
80103fdd:	83 ec 08             	sub    $0x8,%esp
80103fe0:	8d 45 f4             	lea    -0xc(%ebp),%eax
80103fe3:	50                   	push   %eax
80103fe4:	ff 75 08             	pushl  0x8(%ebp)
80103fe7:	e8 b7 ff ff ff       	call   80103fa3 <argint>
80103fec:	83 c4 10             	add    $0x10,%esp
80103fef:	85 c0                	test   %eax,%eax
80103ff1:	78 24                	js     80104017 <argptr+0x4c>
    return -1;
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
80103ff3:	85 db                	test   %ebx,%ebx
80103ff5:	78 27                	js     8010401e <argptr+0x53>
80103ff7:	8b 16                	mov    (%esi),%edx
80103ff9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ffc:	39 c2                	cmp    %eax,%edx
80103ffe:	76 25                	jbe    80104025 <argptr+0x5a>
80104000:	01 c3                	add    %eax,%ebx
80104002:	39 da                	cmp    %ebx,%edx
80104004:	72 26                	jb     8010402c <argptr+0x61>
    return -1;
  *pp = (char*)i;
80104006:	8b 55 0c             	mov    0xc(%ebp),%edx
80104009:	89 02                	mov    %eax,(%edx)
  return 0;
8010400b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104010:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104013:	5b                   	pop    %ebx
80104014:	5e                   	pop    %esi
80104015:	5d                   	pop    %ebp
80104016:	c3                   	ret    
    return -1;
80104017:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010401c:	eb f2                	jmp    80104010 <argptr+0x45>
    return -1;
8010401e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104023:	eb eb                	jmp    80104010 <argptr+0x45>
80104025:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010402a:	eb e4                	jmp    80104010 <argptr+0x45>
8010402c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104031:	eb dd                	jmp    80104010 <argptr+0x45>

80104033 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80104033:	55                   	push   %ebp
80104034:	89 e5                	mov    %esp,%ebp
80104036:	83 ec 20             	sub    $0x20,%esp
  int addr;
  if(argint(n, &addr) < 0)
80104039:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010403c:	50                   	push   %eax
8010403d:	ff 75 08             	pushl  0x8(%ebp)
80104040:	e8 5e ff ff ff       	call   80103fa3 <argint>
80104045:	83 c4 10             	add    $0x10,%esp
80104048:	85 c0                	test   %eax,%eax
8010404a:	78 13                	js     8010405f <argstr+0x2c>
    return -1;
  return fetchstr(addr, pp);
8010404c:	83 ec 08             	sub    $0x8,%esp
8010404f:	ff 75 0c             	pushl  0xc(%ebp)
80104052:	ff 75 f4             	pushl  -0xc(%ebp)
80104055:	e8 09 ff ff ff       	call   80103f63 <fetchstr>
8010405a:	83 c4 10             	add    $0x10,%esp
}
8010405d:	c9                   	leave  
8010405e:	c3                   	ret    
    return -1;
8010405f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104064:	eb f7                	jmp    8010405d <argstr+0x2a>

80104066 <syscall>:
[SYS_dump_physmem] sys_dump_physmem,
};

void
syscall(void)
{
80104066:	55                   	push   %ebp
80104067:	89 e5                	mov    %esp,%ebp
80104069:	53                   	push   %ebx
8010406a:	83 ec 04             	sub    $0x4,%esp
  int num;
  struct proc *curproc = myproc();
8010406d:	e8 9b f2 ff ff       	call   8010330d <myproc>
80104072:	89 c3                	mov    %eax,%ebx

  num = curproc->tf->eax;
80104074:	8b 40 18             	mov    0x18(%eax),%eax
80104077:	8b 40 1c             	mov    0x1c(%eax),%eax
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
8010407a:	8d 50 ff             	lea    -0x1(%eax),%edx
8010407d:	83 fa 15             	cmp    $0x15,%edx
80104080:	77 18                	ja     8010409a <syscall+0x34>
80104082:	8b 14 85 a0 6c 10 80 	mov    -0x7fef9360(,%eax,4),%edx
80104089:	85 d2                	test   %edx,%edx
8010408b:	74 0d                	je     8010409a <syscall+0x34>
    curproc->tf->eax = syscalls[num]();
8010408d:	ff d2                	call   *%edx
8010408f:	8b 53 18             	mov    0x18(%ebx),%edx
80104092:	89 42 1c             	mov    %eax,0x1c(%edx)
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
  }
}
80104095:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104098:	c9                   	leave  
80104099:	c3                   	ret    
            curproc->pid, curproc->name, num);
8010409a:	8d 53 6c             	lea    0x6c(%ebx),%edx
    cprintf("%d %s: unknown sys call %d\n",
8010409d:	50                   	push   %eax
8010409e:	52                   	push   %edx
8010409f:	ff 73 10             	pushl  0x10(%ebx)
801040a2:	68 71 6c 10 80       	push   $0x80106c71
801040a7:	e8 5f c5 ff ff       	call   8010060b <cprintf>
    curproc->tf->eax = -1;
801040ac:	8b 43 18             	mov    0x18(%ebx),%eax
801040af:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
801040b6:	83 c4 10             	add    $0x10,%esp
}
801040b9:	eb da                	jmp    80104095 <syscall+0x2f>

801040bb <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
801040bb:	55                   	push   %ebp
801040bc:	89 e5                	mov    %esp,%ebp
801040be:	56                   	push   %esi
801040bf:	53                   	push   %ebx
801040c0:	83 ec 18             	sub    $0x18,%esp
801040c3:	89 d6                	mov    %edx,%esi
801040c5:	89 cb                	mov    %ecx,%ebx
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
801040c7:	8d 55 f4             	lea    -0xc(%ebp),%edx
801040ca:	52                   	push   %edx
801040cb:	50                   	push   %eax
801040cc:	e8 d2 fe ff ff       	call   80103fa3 <argint>
801040d1:	83 c4 10             	add    $0x10,%esp
801040d4:	85 c0                	test   %eax,%eax
801040d6:	78 2e                	js     80104106 <argfd+0x4b>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
801040d8:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
801040dc:	77 2f                	ja     8010410d <argfd+0x52>
801040de:	e8 2a f2 ff ff       	call   8010330d <myproc>
801040e3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801040e6:	8b 44 90 28          	mov    0x28(%eax,%edx,4),%eax
801040ea:	85 c0                	test   %eax,%eax
801040ec:	74 26                	je     80104114 <argfd+0x59>
    return -1;
  if(pfd)
801040ee:	85 f6                	test   %esi,%esi
801040f0:	74 02                	je     801040f4 <argfd+0x39>
    *pfd = fd;
801040f2:	89 16                	mov    %edx,(%esi)
  if(pf)
801040f4:	85 db                	test   %ebx,%ebx
801040f6:	74 23                	je     8010411b <argfd+0x60>
    *pf = f;
801040f8:	89 03                	mov    %eax,(%ebx)
  return 0;
801040fa:	b8 00 00 00 00       	mov    $0x0,%eax
}
801040ff:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104102:	5b                   	pop    %ebx
80104103:	5e                   	pop    %esi
80104104:	5d                   	pop    %ebp
80104105:	c3                   	ret    
    return -1;
80104106:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010410b:	eb f2                	jmp    801040ff <argfd+0x44>
    return -1;
8010410d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104112:	eb eb                	jmp    801040ff <argfd+0x44>
80104114:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104119:	eb e4                	jmp    801040ff <argfd+0x44>
  return 0;
8010411b:	b8 00 00 00 00       	mov    $0x0,%eax
80104120:	eb dd                	jmp    801040ff <argfd+0x44>

80104122 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80104122:	55                   	push   %ebp
80104123:	89 e5                	mov    %esp,%ebp
80104125:	53                   	push   %ebx
80104126:	83 ec 04             	sub    $0x4,%esp
80104129:	89 c3                	mov    %eax,%ebx
  int fd;
  struct proc *curproc = myproc();
8010412b:	e8 dd f1 ff ff       	call   8010330d <myproc>

  for(fd = 0; fd < NOFILE; fd++){
80104130:	ba 00 00 00 00       	mov    $0x0,%edx
80104135:	83 fa 0f             	cmp    $0xf,%edx
80104138:	7f 18                	jg     80104152 <fdalloc+0x30>
    if(curproc->ofile[fd] == 0){
8010413a:	83 7c 90 28 00       	cmpl   $0x0,0x28(%eax,%edx,4)
8010413f:	74 05                	je     80104146 <fdalloc+0x24>
  for(fd = 0; fd < NOFILE; fd++){
80104141:	83 c2 01             	add    $0x1,%edx
80104144:	eb ef                	jmp    80104135 <fdalloc+0x13>
      curproc->ofile[fd] = f;
80104146:	89 5c 90 28          	mov    %ebx,0x28(%eax,%edx,4)
      return fd;
    }
  }
  return -1;
}
8010414a:	89 d0                	mov    %edx,%eax
8010414c:	83 c4 04             	add    $0x4,%esp
8010414f:	5b                   	pop    %ebx
80104150:	5d                   	pop    %ebp
80104151:	c3                   	ret    
  return -1;
80104152:	ba ff ff ff ff       	mov    $0xffffffff,%edx
80104157:	eb f1                	jmp    8010414a <fdalloc+0x28>

80104159 <isdirempty>:
}

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80104159:	55                   	push   %ebp
8010415a:	89 e5                	mov    %esp,%ebp
8010415c:	56                   	push   %esi
8010415d:	53                   	push   %ebx
8010415e:	83 ec 10             	sub    $0x10,%esp
80104161:	89 c3                	mov    %eax,%ebx
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80104163:	b8 20 00 00 00       	mov    $0x20,%eax
80104168:	89 c6                	mov    %eax,%esi
8010416a:	39 43 58             	cmp    %eax,0x58(%ebx)
8010416d:	76 2e                	jbe    8010419d <isdirempty+0x44>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010416f:	6a 10                	push   $0x10
80104171:	50                   	push   %eax
80104172:	8d 45 e8             	lea    -0x18(%ebp),%eax
80104175:	50                   	push   %eax
80104176:	53                   	push   %ebx
80104177:	e8 f7 d5 ff ff       	call   80101773 <readi>
8010417c:	83 c4 10             	add    $0x10,%esp
8010417f:	83 f8 10             	cmp    $0x10,%eax
80104182:	75 0c                	jne    80104190 <isdirempty+0x37>
      panic("isdirempty: readi");
    if(de.inum != 0)
80104184:	66 83 7d e8 00       	cmpw   $0x0,-0x18(%ebp)
80104189:	75 1e                	jne    801041a9 <isdirempty+0x50>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
8010418b:	8d 46 10             	lea    0x10(%esi),%eax
8010418e:	eb d8                	jmp    80104168 <isdirempty+0xf>
      panic("isdirempty: readi");
80104190:	83 ec 0c             	sub    $0xc,%esp
80104193:	68 fc 6c 10 80       	push   $0x80106cfc
80104198:	e8 ab c1 ff ff       	call   80100348 <panic>
      return 0;
  }
  return 1;
8010419d:	b8 01 00 00 00       	mov    $0x1,%eax
}
801041a2:	8d 65 f8             	lea    -0x8(%ebp),%esp
801041a5:	5b                   	pop    %ebx
801041a6:	5e                   	pop    %esi
801041a7:	5d                   	pop    %ebp
801041a8:	c3                   	ret    
      return 0;
801041a9:	b8 00 00 00 00       	mov    $0x0,%eax
801041ae:	eb f2                	jmp    801041a2 <isdirempty+0x49>

801041b0 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
801041b0:	55                   	push   %ebp
801041b1:	89 e5                	mov    %esp,%ebp
801041b3:	57                   	push   %edi
801041b4:	56                   	push   %esi
801041b5:	53                   	push   %ebx
801041b6:	83 ec 44             	sub    $0x44,%esp
801041b9:	89 55 c4             	mov    %edx,-0x3c(%ebp)
801041bc:	89 4d c0             	mov    %ecx,-0x40(%ebp)
801041bf:	8b 7d 08             	mov    0x8(%ebp),%edi
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
801041c2:	8d 55 d6             	lea    -0x2a(%ebp),%edx
801041c5:	52                   	push   %edx
801041c6:	50                   	push   %eax
801041c7:	e8 2d da ff ff       	call   80101bf9 <nameiparent>
801041cc:	89 c6                	mov    %eax,%esi
801041ce:	83 c4 10             	add    $0x10,%esp
801041d1:	85 c0                	test   %eax,%eax
801041d3:	0f 84 3a 01 00 00    	je     80104313 <create+0x163>
    return 0;
  ilock(dp);
801041d9:	83 ec 0c             	sub    $0xc,%esp
801041dc:	50                   	push   %eax
801041dd:	e8 9f d3 ff ff       	call   80101581 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
801041e2:	83 c4 0c             	add    $0xc,%esp
801041e5:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801041e8:	50                   	push   %eax
801041e9:	8d 45 d6             	lea    -0x2a(%ebp),%eax
801041ec:	50                   	push   %eax
801041ed:	56                   	push   %esi
801041ee:	e8 bd d7 ff ff       	call   801019b0 <dirlookup>
801041f3:	89 c3                	mov    %eax,%ebx
801041f5:	83 c4 10             	add    $0x10,%esp
801041f8:	85 c0                	test   %eax,%eax
801041fa:	74 3f                	je     8010423b <create+0x8b>
    iunlockput(dp);
801041fc:	83 ec 0c             	sub    $0xc,%esp
801041ff:	56                   	push   %esi
80104200:	e8 23 d5 ff ff       	call   80101728 <iunlockput>
    ilock(ip);
80104205:	89 1c 24             	mov    %ebx,(%esp)
80104208:	e8 74 d3 ff ff       	call   80101581 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
8010420d:	83 c4 10             	add    $0x10,%esp
80104210:	66 83 7d c4 02       	cmpw   $0x2,-0x3c(%ebp)
80104215:	75 11                	jne    80104228 <create+0x78>
80104217:	66 83 7b 50 02       	cmpw   $0x2,0x50(%ebx)
8010421c:	75 0a                	jne    80104228 <create+0x78>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
8010421e:	89 d8                	mov    %ebx,%eax
80104220:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104223:	5b                   	pop    %ebx
80104224:	5e                   	pop    %esi
80104225:	5f                   	pop    %edi
80104226:	5d                   	pop    %ebp
80104227:	c3                   	ret    
    iunlockput(ip);
80104228:	83 ec 0c             	sub    $0xc,%esp
8010422b:	53                   	push   %ebx
8010422c:	e8 f7 d4 ff ff       	call   80101728 <iunlockput>
    return 0;
80104231:	83 c4 10             	add    $0x10,%esp
80104234:	bb 00 00 00 00       	mov    $0x0,%ebx
80104239:	eb e3                	jmp    8010421e <create+0x6e>
  if((ip = ialloc(dp->dev, type)) == 0)
8010423b:	0f bf 45 c4          	movswl -0x3c(%ebp),%eax
8010423f:	83 ec 08             	sub    $0x8,%esp
80104242:	50                   	push   %eax
80104243:	ff 36                	pushl  (%esi)
80104245:	e8 34 d1 ff ff       	call   8010137e <ialloc>
8010424a:	89 c3                	mov    %eax,%ebx
8010424c:	83 c4 10             	add    $0x10,%esp
8010424f:	85 c0                	test   %eax,%eax
80104251:	74 55                	je     801042a8 <create+0xf8>
  ilock(ip);
80104253:	83 ec 0c             	sub    $0xc,%esp
80104256:	50                   	push   %eax
80104257:	e8 25 d3 ff ff       	call   80101581 <ilock>
  ip->major = major;
8010425c:	0f b7 45 c0          	movzwl -0x40(%ebp),%eax
80104260:	66 89 43 52          	mov    %ax,0x52(%ebx)
  ip->minor = minor;
80104264:	66 89 7b 54          	mov    %di,0x54(%ebx)
  ip->nlink = 1;
80104268:	66 c7 43 56 01 00    	movw   $0x1,0x56(%ebx)
  iupdate(ip);
8010426e:	89 1c 24             	mov    %ebx,(%esp)
80104271:	e8 aa d1 ff ff       	call   80101420 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
80104276:	83 c4 10             	add    $0x10,%esp
80104279:	66 83 7d c4 01       	cmpw   $0x1,-0x3c(%ebp)
8010427e:	74 35                	je     801042b5 <create+0x105>
  if(dirlink(dp, name, ip->inum) < 0)
80104280:	83 ec 04             	sub    $0x4,%esp
80104283:	ff 73 04             	pushl  0x4(%ebx)
80104286:	8d 45 d6             	lea    -0x2a(%ebp),%eax
80104289:	50                   	push   %eax
8010428a:	56                   	push   %esi
8010428b:	e8 a0 d8 ff ff       	call   80101b30 <dirlink>
80104290:	83 c4 10             	add    $0x10,%esp
80104293:	85 c0                	test   %eax,%eax
80104295:	78 6f                	js     80104306 <create+0x156>
  iunlockput(dp);
80104297:	83 ec 0c             	sub    $0xc,%esp
8010429a:	56                   	push   %esi
8010429b:	e8 88 d4 ff ff       	call   80101728 <iunlockput>
  return ip;
801042a0:	83 c4 10             	add    $0x10,%esp
801042a3:	e9 76 ff ff ff       	jmp    8010421e <create+0x6e>
    panic("create: ialloc");
801042a8:	83 ec 0c             	sub    $0xc,%esp
801042ab:	68 0e 6d 10 80       	push   $0x80106d0e
801042b0:	e8 93 c0 ff ff       	call   80100348 <panic>
    dp->nlink++;  // for ".."
801042b5:	0f b7 46 56          	movzwl 0x56(%esi),%eax
801042b9:	83 c0 01             	add    $0x1,%eax
801042bc:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
801042c0:	83 ec 0c             	sub    $0xc,%esp
801042c3:	56                   	push   %esi
801042c4:	e8 57 d1 ff ff       	call   80101420 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
801042c9:	83 c4 0c             	add    $0xc,%esp
801042cc:	ff 73 04             	pushl  0x4(%ebx)
801042cf:	68 1e 6d 10 80       	push   $0x80106d1e
801042d4:	53                   	push   %ebx
801042d5:	e8 56 d8 ff ff       	call   80101b30 <dirlink>
801042da:	83 c4 10             	add    $0x10,%esp
801042dd:	85 c0                	test   %eax,%eax
801042df:	78 18                	js     801042f9 <create+0x149>
801042e1:	83 ec 04             	sub    $0x4,%esp
801042e4:	ff 76 04             	pushl  0x4(%esi)
801042e7:	68 1d 6d 10 80       	push   $0x80106d1d
801042ec:	53                   	push   %ebx
801042ed:	e8 3e d8 ff ff       	call   80101b30 <dirlink>
801042f2:	83 c4 10             	add    $0x10,%esp
801042f5:	85 c0                	test   %eax,%eax
801042f7:	79 87                	jns    80104280 <create+0xd0>
      panic("create dots");
801042f9:	83 ec 0c             	sub    $0xc,%esp
801042fc:	68 20 6d 10 80       	push   $0x80106d20
80104301:	e8 42 c0 ff ff       	call   80100348 <panic>
    panic("create: dirlink");
80104306:	83 ec 0c             	sub    $0xc,%esp
80104309:	68 2c 6d 10 80       	push   $0x80106d2c
8010430e:	e8 35 c0 ff ff       	call   80100348 <panic>
    return 0;
80104313:	89 c3                	mov    %eax,%ebx
80104315:	e9 04 ff ff ff       	jmp    8010421e <create+0x6e>

8010431a <sys_dup>:
{
8010431a:	55                   	push   %ebp
8010431b:	89 e5                	mov    %esp,%ebp
8010431d:	53                   	push   %ebx
8010431e:	83 ec 14             	sub    $0x14,%esp
  if(argfd(0, 0, &f) < 0)
80104321:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104324:	ba 00 00 00 00       	mov    $0x0,%edx
80104329:	b8 00 00 00 00       	mov    $0x0,%eax
8010432e:	e8 88 fd ff ff       	call   801040bb <argfd>
80104333:	85 c0                	test   %eax,%eax
80104335:	78 23                	js     8010435a <sys_dup+0x40>
  if((fd=fdalloc(f)) < 0)
80104337:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010433a:	e8 e3 fd ff ff       	call   80104122 <fdalloc>
8010433f:	89 c3                	mov    %eax,%ebx
80104341:	85 c0                	test   %eax,%eax
80104343:	78 1c                	js     80104361 <sys_dup+0x47>
  filedup(f);
80104345:	83 ec 0c             	sub    $0xc,%esp
80104348:	ff 75 f4             	pushl  -0xc(%ebp)
8010434b:	e8 3e c9 ff ff       	call   80100c8e <filedup>
  return fd;
80104350:	83 c4 10             	add    $0x10,%esp
}
80104353:	89 d8                	mov    %ebx,%eax
80104355:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104358:	c9                   	leave  
80104359:	c3                   	ret    
    return -1;
8010435a:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
8010435f:	eb f2                	jmp    80104353 <sys_dup+0x39>
    return -1;
80104361:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104366:	eb eb                	jmp    80104353 <sys_dup+0x39>

80104368 <sys_read>:
{
80104368:	55                   	push   %ebp
80104369:	89 e5                	mov    %esp,%ebp
8010436b:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
8010436e:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104371:	ba 00 00 00 00       	mov    $0x0,%edx
80104376:	b8 00 00 00 00       	mov    $0x0,%eax
8010437b:	e8 3b fd ff ff       	call   801040bb <argfd>
80104380:	85 c0                	test   %eax,%eax
80104382:	78 43                	js     801043c7 <sys_read+0x5f>
80104384:	83 ec 08             	sub    $0x8,%esp
80104387:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010438a:	50                   	push   %eax
8010438b:	6a 02                	push   $0x2
8010438d:	e8 11 fc ff ff       	call   80103fa3 <argint>
80104392:	83 c4 10             	add    $0x10,%esp
80104395:	85 c0                	test   %eax,%eax
80104397:	78 35                	js     801043ce <sys_read+0x66>
80104399:	83 ec 04             	sub    $0x4,%esp
8010439c:	ff 75 f0             	pushl  -0x10(%ebp)
8010439f:	8d 45 ec             	lea    -0x14(%ebp),%eax
801043a2:	50                   	push   %eax
801043a3:	6a 01                	push   $0x1
801043a5:	e8 21 fc ff ff       	call   80103fcb <argptr>
801043aa:	83 c4 10             	add    $0x10,%esp
801043ad:	85 c0                	test   %eax,%eax
801043af:	78 24                	js     801043d5 <sys_read+0x6d>
  return fileread(f, p, n);
801043b1:	83 ec 04             	sub    $0x4,%esp
801043b4:	ff 75 f0             	pushl  -0x10(%ebp)
801043b7:	ff 75 ec             	pushl  -0x14(%ebp)
801043ba:	ff 75 f4             	pushl  -0xc(%ebp)
801043bd:	e8 15 ca ff ff       	call   80100dd7 <fileread>
801043c2:	83 c4 10             	add    $0x10,%esp
}
801043c5:	c9                   	leave  
801043c6:	c3                   	ret    
    return -1;
801043c7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043cc:	eb f7                	jmp    801043c5 <sys_read+0x5d>
801043ce:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043d3:	eb f0                	jmp    801043c5 <sys_read+0x5d>
801043d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043da:	eb e9                	jmp    801043c5 <sys_read+0x5d>

801043dc <sys_write>:
{
801043dc:	55                   	push   %ebp
801043dd:	89 e5                	mov    %esp,%ebp
801043df:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801043e2:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801043e5:	ba 00 00 00 00       	mov    $0x0,%edx
801043ea:	b8 00 00 00 00       	mov    $0x0,%eax
801043ef:	e8 c7 fc ff ff       	call   801040bb <argfd>
801043f4:	85 c0                	test   %eax,%eax
801043f6:	78 43                	js     8010443b <sys_write+0x5f>
801043f8:	83 ec 08             	sub    $0x8,%esp
801043fb:	8d 45 f0             	lea    -0x10(%ebp),%eax
801043fe:	50                   	push   %eax
801043ff:	6a 02                	push   $0x2
80104401:	e8 9d fb ff ff       	call   80103fa3 <argint>
80104406:	83 c4 10             	add    $0x10,%esp
80104409:	85 c0                	test   %eax,%eax
8010440b:	78 35                	js     80104442 <sys_write+0x66>
8010440d:	83 ec 04             	sub    $0x4,%esp
80104410:	ff 75 f0             	pushl  -0x10(%ebp)
80104413:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104416:	50                   	push   %eax
80104417:	6a 01                	push   $0x1
80104419:	e8 ad fb ff ff       	call   80103fcb <argptr>
8010441e:	83 c4 10             	add    $0x10,%esp
80104421:	85 c0                	test   %eax,%eax
80104423:	78 24                	js     80104449 <sys_write+0x6d>
  return filewrite(f, p, n);
80104425:	83 ec 04             	sub    $0x4,%esp
80104428:	ff 75 f0             	pushl  -0x10(%ebp)
8010442b:	ff 75 ec             	pushl  -0x14(%ebp)
8010442e:	ff 75 f4             	pushl  -0xc(%ebp)
80104431:	e8 26 ca ff ff       	call   80100e5c <filewrite>
80104436:	83 c4 10             	add    $0x10,%esp
}
80104439:	c9                   	leave  
8010443a:	c3                   	ret    
    return -1;
8010443b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104440:	eb f7                	jmp    80104439 <sys_write+0x5d>
80104442:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104447:	eb f0                	jmp    80104439 <sys_write+0x5d>
80104449:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010444e:	eb e9                	jmp    80104439 <sys_write+0x5d>

80104450 <sys_close>:
{
80104450:	55                   	push   %ebp
80104451:	89 e5                	mov    %esp,%ebp
80104453:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, &fd, &f) < 0)
80104456:	8d 4d f0             	lea    -0x10(%ebp),%ecx
80104459:	8d 55 f4             	lea    -0xc(%ebp),%edx
8010445c:	b8 00 00 00 00       	mov    $0x0,%eax
80104461:	e8 55 fc ff ff       	call   801040bb <argfd>
80104466:	85 c0                	test   %eax,%eax
80104468:	78 25                	js     8010448f <sys_close+0x3f>
  myproc()->ofile[fd] = 0;
8010446a:	e8 9e ee ff ff       	call   8010330d <myproc>
8010446f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104472:	c7 44 90 28 00 00 00 	movl   $0x0,0x28(%eax,%edx,4)
80104479:	00 
  fileclose(f);
8010447a:	83 ec 0c             	sub    $0xc,%esp
8010447d:	ff 75 f0             	pushl  -0x10(%ebp)
80104480:	e8 4e c8 ff ff       	call   80100cd3 <fileclose>
  return 0;
80104485:	83 c4 10             	add    $0x10,%esp
80104488:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010448d:	c9                   	leave  
8010448e:	c3                   	ret    
    return -1;
8010448f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104494:	eb f7                	jmp    8010448d <sys_close+0x3d>

80104496 <sys_fstat>:
{
80104496:	55                   	push   %ebp
80104497:	89 e5                	mov    %esp,%ebp
80104499:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
8010449c:	8d 4d f4             	lea    -0xc(%ebp),%ecx
8010449f:	ba 00 00 00 00       	mov    $0x0,%edx
801044a4:	b8 00 00 00 00       	mov    $0x0,%eax
801044a9:	e8 0d fc ff ff       	call   801040bb <argfd>
801044ae:	85 c0                	test   %eax,%eax
801044b0:	78 2a                	js     801044dc <sys_fstat+0x46>
801044b2:	83 ec 04             	sub    $0x4,%esp
801044b5:	6a 14                	push   $0x14
801044b7:	8d 45 f0             	lea    -0x10(%ebp),%eax
801044ba:	50                   	push   %eax
801044bb:	6a 01                	push   $0x1
801044bd:	e8 09 fb ff ff       	call   80103fcb <argptr>
801044c2:	83 c4 10             	add    $0x10,%esp
801044c5:	85 c0                	test   %eax,%eax
801044c7:	78 1a                	js     801044e3 <sys_fstat+0x4d>
  return filestat(f, st);
801044c9:	83 ec 08             	sub    $0x8,%esp
801044cc:	ff 75 f0             	pushl  -0x10(%ebp)
801044cf:	ff 75 f4             	pushl  -0xc(%ebp)
801044d2:	e8 b9 c8 ff ff       	call   80100d90 <filestat>
801044d7:	83 c4 10             	add    $0x10,%esp
}
801044da:	c9                   	leave  
801044db:	c3                   	ret    
    return -1;
801044dc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044e1:	eb f7                	jmp    801044da <sys_fstat+0x44>
801044e3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044e8:	eb f0                	jmp    801044da <sys_fstat+0x44>

801044ea <sys_link>:
{
801044ea:	55                   	push   %ebp
801044eb:	89 e5                	mov    %esp,%ebp
801044ed:	56                   	push   %esi
801044ee:	53                   	push   %ebx
801044ef:	83 ec 28             	sub    $0x28,%esp
  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
801044f2:	8d 45 e0             	lea    -0x20(%ebp),%eax
801044f5:	50                   	push   %eax
801044f6:	6a 00                	push   $0x0
801044f8:	e8 36 fb ff ff       	call   80104033 <argstr>
801044fd:	83 c4 10             	add    $0x10,%esp
80104500:	85 c0                	test   %eax,%eax
80104502:	0f 88 32 01 00 00    	js     8010463a <sys_link+0x150>
80104508:	83 ec 08             	sub    $0x8,%esp
8010450b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010450e:	50                   	push   %eax
8010450f:	6a 01                	push   $0x1
80104511:	e8 1d fb ff ff       	call   80104033 <argstr>
80104516:	83 c4 10             	add    $0x10,%esp
80104519:	85 c0                	test   %eax,%eax
8010451b:	0f 88 20 01 00 00    	js     80104641 <sys_link+0x157>
  begin_op();
80104521:	e8 9f e3 ff ff       	call   801028c5 <begin_op>
  if((ip = namei(old)) == 0){
80104526:	83 ec 0c             	sub    $0xc,%esp
80104529:	ff 75 e0             	pushl  -0x20(%ebp)
8010452c:	e8 b0 d6 ff ff       	call   80101be1 <namei>
80104531:	89 c3                	mov    %eax,%ebx
80104533:	83 c4 10             	add    $0x10,%esp
80104536:	85 c0                	test   %eax,%eax
80104538:	0f 84 99 00 00 00    	je     801045d7 <sys_link+0xed>
  ilock(ip);
8010453e:	83 ec 0c             	sub    $0xc,%esp
80104541:	50                   	push   %eax
80104542:	e8 3a d0 ff ff       	call   80101581 <ilock>
  if(ip->type == T_DIR){
80104547:	83 c4 10             	add    $0x10,%esp
8010454a:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
8010454f:	0f 84 8e 00 00 00    	je     801045e3 <sys_link+0xf9>
  ip->nlink++;
80104555:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104559:	83 c0 01             	add    $0x1,%eax
8010455c:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104560:	83 ec 0c             	sub    $0xc,%esp
80104563:	53                   	push   %ebx
80104564:	e8 b7 ce ff ff       	call   80101420 <iupdate>
  iunlock(ip);
80104569:	89 1c 24             	mov    %ebx,(%esp)
8010456c:	e8 d2 d0 ff ff       	call   80101643 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
80104571:	83 c4 08             	add    $0x8,%esp
80104574:	8d 45 ea             	lea    -0x16(%ebp),%eax
80104577:	50                   	push   %eax
80104578:	ff 75 e4             	pushl  -0x1c(%ebp)
8010457b:	e8 79 d6 ff ff       	call   80101bf9 <nameiparent>
80104580:	89 c6                	mov    %eax,%esi
80104582:	83 c4 10             	add    $0x10,%esp
80104585:	85 c0                	test   %eax,%eax
80104587:	74 7e                	je     80104607 <sys_link+0x11d>
  ilock(dp);
80104589:	83 ec 0c             	sub    $0xc,%esp
8010458c:	50                   	push   %eax
8010458d:	e8 ef cf ff ff       	call   80101581 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80104592:	83 c4 10             	add    $0x10,%esp
80104595:	8b 03                	mov    (%ebx),%eax
80104597:	39 06                	cmp    %eax,(%esi)
80104599:	75 60                	jne    801045fb <sys_link+0x111>
8010459b:	83 ec 04             	sub    $0x4,%esp
8010459e:	ff 73 04             	pushl  0x4(%ebx)
801045a1:	8d 45 ea             	lea    -0x16(%ebp),%eax
801045a4:	50                   	push   %eax
801045a5:	56                   	push   %esi
801045a6:	e8 85 d5 ff ff       	call   80101b30 <dirlink>
801045ab:	83 c4 10             	add    $0x10,%esp
801045ae:	85 c0                	test   %eax,%eax
801045b0:	78 49                	js     801045fb <sys_link+0x111>
  iunlockput(dp);
801045b2:	83 ec 0c             	sub    $0xc,%esp
801045b5:	56                   	push   %esi
801045b6:	e8 6d d1 ff ff       	call   80101728 <iunlockput>
  iput(ip);
801045bb:	89 1c 24             	mov    %ebx,(%esp)
801045be:	e8 c5 d0 ff ff       	call   80101688 <iput>
  end_op();
801045c3:	e8 77 e3 ff ff       	call   8010293f <end_op>
  return 0;
801045c8:	83 c4 10             	add    $0x10,%esp
801045cb:	b8 00 00 00 00       	mov    $0x0,%eax
}
801045d0:	8d 65 f8             	lea    -0x8(%ebp),%esp
801045d3:	5b                   	pop    %ebx
801045d4:	5e                   	pop    %esi
801045d5:	5d                   	pop    %ebp
801045d6:	c3                   	ret    
    end_op();
801045d7:	e8 63 e3 ff ff       	call   8010293f <end_op>
    return -1;
801045dc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045e1:	eb ed                	jmp    801045d0 <sys_link+0xe6>
    iunlockput(ip);
801045e3:	83 ec 0c             	sub    $0xc,%esp
801045e6:	53                   	push   %ebx
801045e7:	e8 3c d1 ff ff       	call   80101728 <iunlockput>
    end_op();
801045ec:	e8 4e e3 ff ff       	call   8010293f <end_op>
    return -1;
801045f1:	83 c4 10             	add    $0x10,%esp
801045f4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045f9:	eb d5                	jmp    801045d0 <sys_link+0xe6>
    iunlockput(dp);
801045fb:	83 ec 0c             	sub    $0xc,%esp
801045fe:	56                   	push   %esi
801045ff:	e8 24 d1 ff ff       	call   80101728 <iunlockput>
    goto bad;
80104604:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
80104607:	83 ec 0c             	sub    $0xc,%esp
8010460a:	53                   	push   %ebx
8010460b:	e8 71 cf ff ff       	call   80101581 <ilock>
  ip->nlink--;
80104610:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104614:	83 e8 01             	sub    $0x1,%eax
80104617:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
8010461b:	89 1c 24             	mov    %ebx,(%esp)
8010461e:	e8 fd cd ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
80104623:	89 1c 24             	mov    %ebx,(%esp)
80104626:	e8 fd d0 ff ff       	call   80101728 <iunlockput>
  end_op();
8010462b:	e8 0f e3 ff ff       	call   8010293f <end_op>
  return -1;
80104630:	83 c4 10             	add    $0x10,%esp
80104633:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104638:	eb 96                	jmp    801045d0 <sys_link+0xe6>
    return -1;
8010463a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010463f:	eb 8f                	jmp    801045d0 <sys_link+0xe6>
80104641:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104646:	eb 88                	jmp    801045d0 <sys_link+0xe6>

80104648 <sys_unlink>:
{
80104648:	55                   	push   %ebp
80104649:	89 e5                	mov    %esp,%ebp
8010464b:	57                   	push   %edi
8010464c:	56                   	push   %esi
8010464d:	53                   	push   %ebx
8010464e:	83 ec 44             	sub    $0x44,%esp
  if(argstr(0, &path) < 0)
80104651:	8d 45 c4             	lea    -0x3c(%ebp),%eax
80104654:	50                   	push   %eax
80104655:	6a 00                	push   $0x0
80104657:	e8 d7 f9 ff ff       	call   80104033 <argstr>
8010465c:	83 c4 10             	add    $0x10,%esp
8010465f:	85 c0                	test   %eax,%eax
80104661:	0f 88 83 01 00 00    	js     801047ea <sys_unlink+0x1a2>
  begin_op();
80104667:	e8 59 e2 ff ff       	call   801028c5 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
8010466c:	83 ec 08             	sub    $0x8,%esp
8010466f:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104672:	50                   	push   %eax
80104673:	ff 75 c4             	pushl  -0x3c(%ebp)
80104676:	e8 7e d5 ff ff       	call   80101bf9 <nameiparent>
8010467b:	89 c6                	mov    %eax,%esi
8010467d:	83 c4 10             	add    $0x10,%esp
80104680:	85 c0                	test   %eax,%eax
80104682:	0f 84 ed 00 00 00    	je     80104775 <sys_unlink+0x12d>
  ilock(dp);
80104688:	83 ec 0c             	sub    $0xc,%esp
8010468b:	50                   	push   %eax
8010468c:	e8 f0 ce ff ff       	call   80101581 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80104691:	83 c4 08             	add    $0x8,%esp
80104694:	68 1e 6d 10 80       	push   $0x80106d1e
80104699:	8d 45 ca             	lea    -0x36(%ebp),%eax
8010469c:	50                   	push   %eax
8010469d:	e8 f9 d2 ff ff       	call   8010199b <namecmp>
801046a2:	83 c4 10             	add    $0x10,%esp
801046a5:	85 c0                	test   %eax,%eax
801046a7:	0f 84 fc 00 00 00    	je     801047a9 <sys_unlink+0x161>
801046ad:	83 ec 08             	sub    $0x8,%esp
801046b0:	68 1d 6d 10 80       	push   $0x80106d1d
801046b5:	8d 45 ca             	lea    -0x36(%ebp),%eax
801046b8:	50                   	push   %eax
801046b9:	e8 dd d2 ff ff       	call   8010199b <namecmp>
801046be:	83 c4 10             	add    $0x10,%esp
801046c1:	85 c0                	test   %eax,%eax
801046c3:	0f 84 e0 00 00 00    	je     801047a9 <sys_unlink+0x161>
  if((ip = dirlookup(dp, name, &off)) == 0)
801046c9:	83 ec 04             	sub    $0x4,%esp
801046cc:	8d 45 c0             	lea    -0x40(%ebp),%eax
801046cf:	50                   	push   %eax
801046d0:	8d 45 ca             	lea    -0x36(%ebp),%eax
801046d3:	50                   	push   %eax
801046d4:	56                   	push   %esi
801046d5:	e8 d6 d2 ff ff       	call   801019b0 <dirlookup>
801046da:	89 c3                	mov    %eax,%ebx
801046dc:	83 c4 10             	add    $0x10,%esp
801046df:	85 c0                	test   %eax,%eax
801046e1:	0f 84 c2 00 00 00    	je     801047a9 <sys_unlink+0x161>
  ilock(ip);
801046e7:	83 ec 0c             	sub    $0xc,%esp
801046ea:	50                   	push   %eax
801046eb:	e8 91 ce ff ff       	call   80101581 <ilock>
  if(ip->nlink < 1)
801046f0:	83 c4 10             	add    $0x10,%esp
801046f3:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801046f8:	0f 8e 83 00 00 00    	jle    80104781 <sys_unlink+0x139>
  if(ip->type == T_DIR && !isdirempty(ip)){
801046fe:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104703:	0f 84 85 00 00 00    	je     8010478e <sys_unlink+0x146>
  memset(&de, 0, sizeof(de));
80104709:	83 ec 04             	sub    $0x4,%esp
8010470c:	6a 10                	push   $0x10
8010470e:	6a 00                	push   $0x0
80104710:	8d 7d d8             	lea    -0x28(%ebp),%edi
80104713:	57                   	push   %edi
80104714:	e8 3f f6 ff ff       	call   80103d58 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80104719:	6a 10                	push   $0x10
8010471b:	ff 75 c0             	pushl  -0x40(%ebp)
8010471e:	57                   	push   %edi
8010471f:	56                   	push   %esi
80104720:	e8 4b d1 ff ff       	call   80101870 <writei>
80104725:	83 c4 20             	add    $0x20,%esp
80104728:	83 f8 10             	cmp    $0x10,%eax
8010472b:	0f 85 90 00 00 00    	jne    801047c1 <sys_unlink+0x179>
  if(ip->type == T_DIR){
80104731:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104736:	0f 84 92 00 00 00    	je     801047ce <sys_unlink+0x186>
  iunlockput(dp);
8010473c:	83 ec 0c             	sub    $0xc,%esp
8010473f:	56                   	push   %esi
80104740:	e8 e3 cf ff ff       	call   80101728 <iunlockput>
  ip->nlink--;
80104745:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104749:	83 e8 01             	sub    $0x1,%eax
8010474c:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104750:	89 1c 24             	mov    %ebx,(%esp)
80104753:	e8 c8 cc ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
80104758:	89 1c 24             	mov    %ebx,(%esp)
8010475b:	e8 c8 cf ff ff       	call   80101728 <iunlockput>
  end_op();
80104760:	e8 da e1 ff ff       	call   8010293f <end_op>
  return 0;
80104765:	83 c4 10             	add    $0x10,%esp
80104768:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010476d:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104770:	5b                   	pop    %ebx
80104771:	5e                   	pop    %esi
80104772:	5f                   	pop    %edi
80104773:	5d                   	pop    %ebp
80104774:	c3                   	ret    
    end_op();
80104775:	e8 c5 e1 ff ff       	call   8010293f <end_op>
    return -1;
8010477a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010477f:	eb ec                	jmp    8010476d <sys_unlink+0x125>
    panic("unlink: nlink < 1");
80104781:	83 ec 0c             	sub    $0xc,%esp
80104784:	68 3c 6d 10 80       	push   $0x80106d3c
80104789:	e8 ba bb ff ff       	call   80100348 <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
8010478e:	89 d8                	mov    %ebx,%eax
80104790:	e8 c4 f9 ff ff       	call   80104159 <isdirempty>
80104795:	85 c0                	test   %eax,%eax
80104797:	0f 85 6c ff ff ff    	jne    80104709 <sys_unlink+0xc1>
    iunlockput(ip);
8010479d:	83 ec 0c             	sub    $0xc,%esp
801047a0:	53                   	push   %ebx
801047a1:	e8 82 cf ff ff       	call   80101728 <iunlockput>
    goto bad;
801047a6:	83 c4 10             	add    $0x10,%esp
  iunlockput(dp);
801047a9:	83 ec 0c             	sub    $0xc,%esp
801047ac:	56                   	push   %esi
801047ad:	e8 76 cf ff ff       	call   80101728 <iunlockput>
  end_op();
801047b2:	e8 88 e1 ff ff       	call   8010293f <end_op>
  return -1;
801047b7:	83 c4 10             	add    $0x10,%esp
801047ba:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047bf:	eb ac                	jmp    8010476d <sys_unlink+0x125>
    panic("unlink: writei");
801047c1:	83 ec 0c             	sub    $0xc,%esp
801047c4:	68 4e 6d 10 80       	push   $0x80106d4e
801047c9:	e8 7a bb ff ff       	call   80100348 <panic>
    dp->nlink--;
801047ce:	0f b7 46 56          	movzwl 0x56(%esi),%eax
801047d2:	83 e8 01             	sub    $0x1,%eax
801047d5:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
801047d9:	83 ec 0c             	sub    $0xc,%esp
801047dc:	56                   	push   %esi
801047dd:	e8 3e cc ff ff       	call   80101420 <iupdate>
801047e2:	83 c4 10             	add    $0x10,%esp
801047e5:	e9 52 ff ff ff       	jmp    8010473c <sys_unlink+0xf4>
    return -1;
801047ea:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047ef:	e9 79 ff ff ff       	jmp    8010476d <sys_unlink+0x125>

801047f4 <sys_open>:

int
sys_open(void)
{
801047f4:	55                   	push   %ebp
801047f5:	89 e5                	mov    %esp,%ebp
801047f7:	57                   	push   %edi
801047f8:	56                   	push   %esi
801047f9:	53                   	push   %ebx
801047fa:	83 ec 24             	sub    $0x24,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
801047fd:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104800:	50                   	push   %eax
80104801:	6a 00                	push   $0x0
80104803:	e8 2b f8 ff ff       	call   80104033 <argstr>
80104808:	83 c4 10             	add    $0x10,%esp
8010480b:	85 c0                	test   %eax,%eax
8010480d:	0f 88 30 01 00 00    	js     80104943 <sys_open+0x14f>
80104813:	83 ec 08             	sub    $0x8,%esp
80104816:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104819:	50                   	push   %eax
8010481a:	6a 01                	push   $0x1
8010481c:	e8 82 f7 ff ff       	call   80103fa3 <argint>
80104821:	83 c4 10             	add    $0x10,%esp
80104824:	85 c0                	test   %eax,%eax
80104826:	0f 88 21 01 00 00    	js     8010494d <sys_open+0x159>
    return -1;

  begin_op();
8010482c:	e8 94 e0 ff ff       	call   801028c5 <begin_op>

  if(omode & O_CREATE){
80104831:	f6 45 e1 02          	testb  $0x2,-0x1f(%ebp)
80104835:	0f 84 84 00 00 00    	je     801048bf <sys_open+0xcb>
    ip = create(path, T_FILE, 0, 0);
8010483b:	83 ec 0c             	sub    $0xc,%esp
8010483e:	6a 00                	push   $0x0
80104840:	b9 00 00 00 00       	mov    $0x0,%ecx
80104845:	ba 02 00 00 00       	mov    $0x2,%edx
8010484a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010484d:	e8 5e f9 ff ff       	call   801041b0 <create>
80104852:	89 c6                	mov    %eax,%esi
    if(ip == 0){
80104854:	83 c4 10             	add    $0x10,%esp
80104857:	85 c0                	test   %eax,%eax
80104859:	74 58                	je     801048b3 <sys_open+0xbf>
      end_op();
      return -1;
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
8010485b:	e8 cd c3 ff ff       	call   80100c2d <filealloc>
80104860:	89 c3                	mov    %eax,%ebx
80104862:	85 c0                	test   %eax,%eax
80104864:	0f 84 ae 00 00 00    	je     80104918 <sys_open+0x124>
8010486a:	e8 b3 f8 ff ff       	call   80104122 <fdalloc>
8010486f:	89 c7                	mov    %eax,%edi
80104871:	85 c0                	test   %eax,%eax
80104873:	0f 88 9f 00 00 00    	js     80104918 <sys_open+0x124>
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104879:	83 ec 0c             	sub    $0xc,%esp
8010487c:	56                   	push   %esi
8010487d:	e8 c1 cd ff ff       	call   80101643 <iunlock>
  end_op();
80104882:	e8 b8 e0 ff ff       	call   8010293f <end_op>

  f->type = FD_INODE;
80104887:	c7 03 02 00 00 00    	movl   $0x2,(%ebx)
  f->ip = ip;
8010488d:	89 73 10             	mov    %esi,0x10(%ebx)
  f->off = 0;
80104890:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
  f->readable = !(omode & O_WRONLY);
80104897:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010489a:	83 c4 10             	add    $0x10,%esp
8010489d:	a8 01                	test   $0x1,%al
8010489f:	0f 94 43 08          	sete   0x8(%ebx)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
801048a3:	a8 03                	test   $0x3,%al
801048a5:	0f 95 43 09          	setne  0x9(%ebx)
  return fd;
}
801048a9:	89 f8                	mov    %edi,%eax
801048ab:	8d 65 f4             	lea    -0xc(%ebp),%esp
801048ae:	5b                   	pop    %ebx
801048af:	5e                   	pop    %esi
801048b0:	5f                   	pop    %edi
801048b1:	5d                   	pop    %ebp
801048b2:	c3                   	ret    
      end_op();
801048b3:	e8 87 e0 ff ff       	call   8010293f <end_op>
      return -1;
801048b8:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801048bd:	eb ea                	jmp    801048a9 <sys_open+0xb5>
    if((ip = namei(path)) == 0){
801048bf:	83 ec 0c             	sub    $0xc,%esp
801048c2:	ff 75 e4             	pushl  -0x1c(%ebp)
801048c5:	e8 17 d3 ff ff       	call   80101be1 <namei>
801048ca:	89 c6                	mov    %eax,%esi
801048cc:	83 c4 10             	add    $0x10,%esp
801048cf:	85 c0                	test   %eax,%eax
801048d1:	74 39                	je     8010490c <sys_open+0x118>
    ilock(ip);
801048d3:	83 ec 0c             	sub    $0xc,%esp
801048d6:	50                   	push   %eax
801048d7:	e8 a5 cc ff ff       	call   80101581 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
801048dc:	83 c4 10             	add    $0x10,%esp
801048df:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
801048e4:	0f 85 71 ff ff ff    	jne    8010485b <sys_open+0x67>
801048ea:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
801048ee:	0f 84 67 ff ff ff    	je     8010485b <sys_open+0x67>
      iunlockput(ip);
801048f4:	83 ec 0c             	sub    $0xc,%esp
801048f7:	56                   	push   %esi
801048f8:	e8 2b ce ff ff       	call   80101728 <iunlockput>
      end_op();
801048fd:	e8 3d e0 ff ff       	call   8010293f <end_op>
      return -1;
80104902:	83 c4 10             	add    $0x10,%esp
80104905:	bf ff ff ff ff       	mov    $0xffffffff,%edi
8010490a:	eb 9d                	jmp    801048a9 <sys_open+0xb5>
      end_op();
8010490c:	e8 2e e0 ff ff       	call   8010293f <end_op>
      return -1;
80104911:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104916:	eb 91                	jmp    801048a9 <sys_open+0xb5>
    if(f)
80104918:	85 db                	test   %ebx,%ebx
8010491a:	74 0c                	je     80104928 <sys_open+0x134>
      fileclose(f);
8010491c:	83 ec 0c             	sub    $0xc,%esp
8010491f:	53                   	push   %ebx
80104920:	e8 ae c3 ff ff       	call   80100cd3 <fileclose>
80104925:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
80104928:	83 ec 0c             	sub    $0xc,%esp
8010492b:	56                   	push   %esi
8010492c:	e8 f7 cd ff ff       	call   80101728 <iunlockput>
    end_op();
80104931:	e8 09 e0 ff ff       	call   8010293f <end_op>
    return -1;
80104936:	83 c4 10             	add    $0x10,%esp
80104939:	bf ff ff ff ff       	mov    $0xffffffff,%edi
8010493e:	e9 66 ff ff ff       	jmp    801048a9 <sys_open+0xb5>
    return -1;
80104943:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104948:	e9 5c ff ff ff       	jmp    801048a9 <sys_open+0xb5>
8010494d:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104952:	e9 52 ff ff ff       	jmp    801048a9 <sys_open+0xb5>

80104957 <sys_mkdir>:

int
sys_mkdir(void)
{
80104957:	55                   	push   %ebp
80104958:	89 e5                	mov    %esp,%ebp
8010495a:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
8010495d:	e8 63 df ff ff       	call   801028c5 <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80104962:	83 ec 08             	sub    $0x8,%esp
80104965:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104968:	50                   	push   %eax
80104969:	6a 00                	push   $0x0
8010496b:	e8 c3 f6 ff ff       	call   80104033 <argstr>
80104970:	83 c4 10             	add    $0x10,%esp
80104973:	85 c0                	test   %eax,%eax
80104975:	78 36                	js     801049ad <sys_mkdir+0x56>
80104977:	83 ec 0c             	sub    $0xc,%esp
8010497a:	6a 00                	push   $0x0
8010497c:	b9 00 00 00 00       	mov    $0x0,%ecx
80104981:	ba 01 00 00 00       	mov    $0x1,%edx
80104986:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104989:	e8 22 f8 ff ff       	call   801041b0 <create>
8010498e:	83 c4 10             	add    $0x10,%esp
80104991:	85 c0                	test   %eax,%eax
80104993:	74 18                	je     801049ad <sys_mkdir+0x56>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104995:	83 ec 0c             	sub    $0xc,%esp
80104998:	50                   	push   %eax
80104999:	e8 8a cd ff ff       	call   80101728 <iunlockput>
  end_op();
8010499e:	e8 9c df ff ff       	call   8010293f <end_op>
  return 0;
801049a3:	83 c4 10             	add    $0x10,%esp
801049a6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801049ab:	c9                   	leave  
801049ac:	c3                   	ret    
    end_op();
801049ad:	e8 8d df ff ff       	call   8010293f <end_op>
    return -1;
801049b2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801049b7:	eb f2                	jmp    801049ab <sys_mkdir+0x54>

801049b9 <sys_mknod>:

int
sys_mknod(void)
{
801049b9:	55                   	push   %ebp
801049ba:	89 e5                	mov    %esp,%ebp
801049bc:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
801049bf:	e8 01 df ff ff       	call   801028c5 <begin_op>
  if((argstr(0, &path)) < 0 ||
801049c4:	83 ec 08             	sub    $0x8,%esp
801049c7:	8d 45 f4             	lea    -0xc(%ebp),%eax
801049ca:	50                   	push   %eax
801049cb:	6a 00                	push   $0x0
801049cd:	e8 61 f6 ff ff       	call   80104033 <argstr>
801049d2:	83 c4 10             	add    $0x10,%esp
801049d5:	85 c0                	test   %eax,%eax
801049d7:	78 62                	js     80104a3b <sys_mknod+0x82>
     argint(1, &major) < 0 ||
801049d9:	83 ec 08             	sub    $0x8,%esp
801049dc:	8d 45 f0             	lea    -0x10(%ebp),%eax
801049df:	50                   	push   %eax
801049e0:	6a 01                	push   $0x1
801049e2:	e8 bc f5 ff ff       	call   80103fa3 <argint>
  if((argstr(0, &path)) < 0 ||
801049e7:	83 c4 10             	add    $0x10,%esp
801049ea:	85 c0                	test   %eax,%eax
801049ec:	78 4d                	js     80104a3b <sys_mknod+0x82>
     argint(2, &minor) < 0 ||
801049ee:	83 ec 08             	sub    $0x8,%esp
801049f1:	8d 45 ec             	lea    -0x14(%ebp),%eax
801049f4:	50                   	push   %eax
801049f5:	6a 02                	push   $0x2
801049f7:	e8 a7 f5 ff ff       	call   80103fa3 <argint>
     argint(1, &major) < 0 ||
801049fc:	83 c4 10             	add    $0x10,%esp
801049ff:	85 c0                	test   %eax,%eax
80104a01:	78 38                	js     80104a3b <sys_mknod+0x82>
     (ip = create(path, T_DEV, major, minor)) == 0){
80104a03:	0f bf 45 ec          	movswl -0x14(%ebp),%eax
80104a07:	0f bf 4d f0          	movswl -0x10(%ebp),%ecx
     argint(2, &minor) < 0 ||
80104a0b:	83 ec 0c             	sub    $0xc,%esp
80104a0e:	50                   	push   %eax
80104a0f:	ba 03 00 00 00       	mov    $0x3,%edx
80104a14:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a17:	e8 94 f7 ff ff       	call   801041b0 <create>
80104a1c:	83 c4 10             	add    $0x10,%esp
80104a1f:	85 c0                	test   %eax,%eax
80104a21:	74 18                	je     80104a3b <sys_mknod+0x82>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104a23:	83 ec 0c             	sub    $0xc,%esp
80104a26:	50                   	push   %eax
80104a27:	e8 fc cc ff ff       	call   80101728 <iunlockput>
  end_op();
80104a2c:	e8 0e df ff ff       	call   8010293f <end_op>
  return 0;
80104a31:	83 c4 10             	add    $0x10,%esp
80104a34:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104a39:	c9                   	leave  
80104a3a:	c3                   	ret    
    end_op();
80104a3b:	e8 ff de ff ff       	call   8010293f <end_op>
    return -1;
80104a40:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a45:	eb f2                	jmp    80104a39 <sys_mknod+0x80>

80104a47 <sys_chdir>:

int
sys_chdir(void)
{
80104a47:	55                   	push   %ebp
80104a48:	89 e5                	mov    %esp,%ebp
80104a4a:	56                   	push   %esi
80104a4b:	53                   	push   %ebx
80104a4c:	83 ec 10             	sub    $0x10,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
80104a4f:	e8 b9 e8 ff ff       	call   8010330d <myproc>
80104a54:	89 c6                	mov    %eax,%esi
  
  begin_op();
80104a56:	e8 6a de ff ff       	call   801028c5 <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80104a5b:	83 ec 08             	sub    $0x8,%esp
80104a5e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104a61:	50                   	push   %eax
80104a62:	6a 00                	push   $0x0
80104a64:	e8 ca f5 ff ff       	call   80104033 <argstr>
80104a69:	83 c4 10             	add    $0x10,%esp
80104a6c:	85 c0                	test   %eax,%eax
80104a6e:	78 52                	js     80104ac2 <sys_chdir+0x7b>
80104a70:	83 ec 0c             	sub    $0xc,%esp
80104a73:	ff 75 f4             	pushl  -0xc(%ebp)
80104a76:	e8 66 d1 ff ff       	call   80101be1 <namei>
80104a7b:	89 c3                	mov    %eax,%ebx
80104a7d:	83 c4 10             	add    $0x10,%esp
80104a80:	85 c0                	test   %eax,%eax
80104a82:	74 3e                	je     80104ac2 <sys_chdir+0x7b>
    end_op();
    return -1;
  }
  ilock(ip);
80104a84:	83 ec 0c             	sub    $0xc,%esp
80104a87:	50                   	push   %eax
80104a88:	e8 f4 ca ff ff       	call   80101581 <ilock>
  if(ip->type != T_DIR){
80104a8d:	83 c4 10             	add    $0x10,%esp
80104a90:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104a95:	75 37                	jne    80104ace <sys_chdir+0x87>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104a97:	83 ec 0c             	sub    $0xc,%esp
80104a9a:	53                   	push   %ebx
80104a9b:	e8 a3 cb ff ff       	call   80101643 <iunlock>
  iput(curproc->cwd);
80104aa0:	83 c4 04             	add    $0x4,%esp
80104aa3:	ff 76 68             	pushl  0x68(%esi)
80104aa6:	e8 dd cb ff ff       	call   80101688 <iput>
  end_op();
80104aab:	e8 8f de ff ff       	call   8010293f <end_op>
  curproc->cwd = ip;
80104ab0:	89 5e 68             	mov    %ebx,0x68(%esi)
  return 0;
80104ab3:	83 c4 10             	add    $0x10,%esp
80104ab6:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104abb:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104abe:	5b                   	pop    %ebx
80104abf:	5e                   	pop    %esi
80104ac0:	5d                   	pop    %ebp
80104ac1:	c3                   	ret    
    end_op();
80104ac2:	e8 78 de ff ff       	call   8010293f <end_op>
    return -1;
80104ac7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104acc:	eb ed                	jmp    80104abb <sys_chdir+0x74>
    iunlockput(ip);
80104ace:	83 ec 0c             	sub    $0xc,%esp
80104ad1:	53                   	push   %ebx
80104ad2:	e8 51 cc ff ff       	call   80101728 <iunlockput>
    end_op();
80104ad7:	e8 63 de ff ff       	call   8010293f <end_op>
    return -1;
80104adc:	83 c4 10             	add    $0x10,%esp
80104adf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ae4:	eb d5                	jmp    80104abb <sys_chdir+0x74>

80104ae6 <sys_exec>:

int
sys_exec(void)
{
80104ae6:	55                   	push   %ebp
80104ae7:	89 e5                	mov    %esp,%ebp
80104ae9:	53                   	push   %ebx
80104aea:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80104af0:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104af3:	50                   	push   %eax
80104af4:	6a 00                	push   $0x0
80104af6:	e8 38 f5 ff ff       	call   80104033 <argstr>
80104afb:	83 c4 10             	add    $0x10,%esp
80104afe:	85 c0                	test   %eax,%eax
80104b00:	0f 88 a8 00 00 00    	js     80104bae <sys_exec+0xc8>
80104b06:	83 ec 08             	sub    $0x8,%esp
80104b09:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80104b0f:	50                   	push   %eax
80104b10:	6a 01                	push   $0x1
80104b12:	e8 8c f4 ff ff       	call   80103fa3 <argint>
80104b17:	83 c4 10             	add    $0x10,%esp
80104b1a:	85 c0                	test   %eax,%eax
80104b1c:	0f 88 93 00 00 00    	js     80104bb5 <sys_exec+0xcf>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
80104b22:	83 ec 04             	sub    $0x4,%esp
80104b25:	68 80 00 00 00       	push   $0x80
80104b2a:	6a 00                	push   $0x0
80104b2c:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104b32:	50                   	push   %eax
80104b33:	e8 20 f2 ff ff       	call   80103d58 <memset>
80104b38:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
80104b3b:	bb 00 00 00 00       	mov    $0x0,%ebx
    if(i >= NELEM(argv))
80104b40:	83 fb 1f             	cmp    $0x1f,%ebx
80104b43:	77 77                	ja     80104bbc <sys_exec+0xd6>
      return -1;
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80104b45:	83 ec 08             	sub    $0x8,%esp
80104b48:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80104b4e:	50                   	push   %eax
80104b4f:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
80104b55:	8d 04 98             	lea    (%eax,%ebx,4),%eax
80104b58:	50                   	push   %eax
80104b59:	e8 c9 f3 ff ff       	call   80103f27 <fetchint>
80104b5e:	83 c4 10             	add    $0x10,%esp
80104b61:	85 c0                	test   %eax,%eax
80104b63:	78 5e                	js     80104bc3 <sys_exec+0xdd>
      return -1;
    if(uarg == 0){
80104b65:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80104b6b:	85 c0                	test   %eax,%eax
80104b6d:	74 1d                	je     80104b8c <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80104b6f:	83 ec 08             	sub    $0x8,%esp
80104b72:	8d 94 9d 74 ff ff ff 	lea    -0x8c(%ebp,%ebx,4),%edx
80104b79:	52                   	push   %edx
80104b7a:	50                   	push   %eax
80104b7b:	e8 e3 f3 ff ff       	call   80103f63 <fetchstr>
80104b80:	83 c4 10             	add    $0x10,%esp
80104b83:	85 c0                	test   %eax,%eax
80104b85:	78 46                	js     80104bcd <sys_exec+0xe7>
  for(i=0;; i++){
80104b87:	83 c3 01             	add    $0x1,%ebx
    if(i >= NELEM(argv))
80104b8a:	eb b4                	jmp    80104b40 <sys_exec+0x5a>
      argv[i] = 0;
80104b8c:	c7 84 9d 74 ff ff ff 	movl   $0x0,-0x8c(%ebp,%ebx,4)
80104b93:	00 00 00 00 
      return -1;
  }
  return exec(path, argv);
80104b97:	83 ec 08             	sub    $0x8,%esp
80104b9a:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104ba0:	50                   	push   %eax
80104ba1:	ff 75 f4             	pushl  -0xc(%ebp)
80104ba4:	e8 29 bd ff ff       	call   801008d2 <exec>
80104ba9:	83 c4 10             	add    $0x10,%esp
80104bac:	eb 1a                	jmp    80104bc8 <sys_exec+0xe2>
    return -1;
80104bae:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104bb3:	eb 13                	jmp    80104bc8 <sys_exec+0xe2>
80104bb5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104bba:	eb 0c                	jmp    80104bc8 <sys_exec+0xe2>
      return -1;
80104bbc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104bc1:	eb 05                	jmp    80104bc8 <sys_exec+0xe2>
      return -1;
80104bc3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104bc8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104bcb:	c9                   	leave  
80104bcc:	c3                   	ret    
      return -1;
80104bcd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104bd2:	eb f4                	jmp    80104bc8 <sys_exec+0xe2>

80104bd4 <sys_pipe>:

int
sys_pipe(void)
{
80104bd4:	55                   	push   %ebp
80104bd5:	89 e5                	mov    %esp,%ebp
80104bd7:	53                   	push   %ebx
80104bd8:	83 ec 18             	sub    $0x18,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80104bdb:	6a 08                	push   $0x8
80104bdd:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104be0:	50                   	push   %eax
80104be1:	6a 00                	push   $0x0
80104be3:	e8 e3 f3 ff ff       	call   80103fcb <argptr>
80104be8:	83 c4 10             	add    $0x10,%esp
80104beb:	85 c0                	test   %eax,%eax
80104bed:	78 77                	js     80104c66 <sys_pipe+0x92>
    return -1;
  if(pipealloc(&rf, &wf) < 0)
80104bef:	83 ec 08             	sub    $0x8,%esp
80104bf2:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104bf5:	50                   	push   %eax
80104bf6:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104bf9:	50                   	push   %eax
80104bfa:	e8 4d e2 ff ff       	call   80102e4c <pipealloc>
80104bff:	83 c4 10             	add    $0x10,%esp
80104c02:	85 c0                	test   %eax,%eax
80104c04:	78 67                	js     80104c6d <sys_pipe+0x99>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80104c06:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104c09:	e8 14 f5 ff ff       	call   80104122 <fdalloc>
80104c0e:	89 c3                	mov    %eax,%ebx
80104c10:	85 c0                	test   %eax,%eax
80104c12:	78 21                	js     80104c35 <sys_pipe+0x61>
80104c14:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104c17:	e8 06 f5 ff ff       	call   80104122 <fdalloc>
80104c1c:	85 c0                	test   %eax,%eax
80104c1e:	78 15                	js     80104c35 <sys_pipe+0x61>
      myproc()->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  fd[0] = fd0;
80104c20:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c23:	89 1a                	mov    %ebx,(%edx)
  fd[1] = fd1;
80104c25:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c28:	89 42 04             	mov    %eax,0x4(%edx)
  return 0;
80104c2b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104c30:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104c33:	c9                   	leave  
80104c34:	c3                   	ret    
    if(fd0 >= 0)
80104c35:	85 db                	test   %ebx,%ebx
80104c37:	78 0d                	js     80104c46 <sys_pipe+0x72>
      myproc()->ofile[fd0] = 0;
80104c39:	e8 cf e6 ff ff       	call   8010330d <myproc>
80104c3e:	c7 44 98 28 00 00 00 	movl   $0x0,0x28(%eax,%ebx,4)
80104c45:	00 
    fileclose(rf);
80104c46:	83 ec 0c             	sub    $0xc,%esp
80104c49:	ff 75 f0             	pushl  -0x10(%ebp)
80104c4c:	e8 82 c0 ff ff       	call   80100cd3 <fileclose>
    fileclose(wf);
80104c51:	83 c4 04             	add    $0x4,%esp
80104c54:	ff 75 ec             	pushl  -0x14(%ebp)
80104c57:	e8 77 c0 ff ff       	call   80100cd3 <fileclose>
    return -1;
80104c5c:	83 c4 10             	add    $0x10,%esp
80104c5f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c64:	eb ca                	jmp    80104c30 <sys_pipe+0x5c>
    return -1;
80104c66:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c6b:	eb c3                	jmp    80104c30 <sys_pipe+0x5c>
    return -1;
80104c6d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c72:	eb bc                	jmp    80104c30 <sys_pipe+0x5c>

80104c74 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80104c74:	55                   	push   %ebp
80104c75:	89 e5                	mov    %esp,%ebp
80104c77:	83 ec 08             	sub    $0x8,%esp
  return fork();
80104c7a:	e8 06 e8 ff ff       	call   80103485 <fork>
}
80104c7f:	c9                   	leave  
80104c80:	c3                   	ret    

80104c81 <sys_exit>:

int
sys_exit(void)
{
80104c81:	55                   	push   %ebp
80104c82:	89 e5                	mov    %esp,%ebp
80104c84:	83 ec 08             	sub    $0x8,%esp
  exit();
80104c87:	e8 2d ea ff ff       	call   801036b9 <exit>
  return 0;  // not reached
}
80104c8c:	b8 00 00 00 00       	mov    $0x0,%eax
80104c91:	c9                   	leave  
80104c92:	c3                   	ret    

80104c93 <sys_wait>:

int
sys_wait(void)
{
80104c93:	55                   	push   %ebp
80104c94:	89 e5                	mov    %esp,%ebp
80104c96:	83 ec 08             	sub    $0x8,%esp
  return wait();
80104c99:	e8 a4 eb ff ff       	call   80103842 <wait>
}
80104c9e:	c9                   	leave  
80104c9f:	c3                   	ret    

80104ca0 <sys_kill>:

int
sys_kill(void)
{
80104ca0:	55                   	push   %ebp
80104ca1:	89 e5                	mov    %esp,%ebp
80104ca3:	83 ec 20             	sub    $0x20,%esp
  int pid;

  if(argint(0, &pid) < 0)
80104ca6:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104ca9:	50                   	push   %eax
80104caa:	6a 00                	push   $0x0
80104cac:	e8 f2 f2 ff ff       	call   80103fa3 <argint>
80104cb1:	83 c4 10             	add    $0x10,%esp
80104cb4:	85 c0                	test   %eax,%eax
80104cb6:	78 10                	js     80104cc8 <sys_kill+0x28>
    return -1;
  return kill(pid);
80104cb8:	83 ec 0c             	sub    $0xc,%esp
80104cbb:	ff 75 f4             	pushl  -0xc(%ebp)
80104cbe:	e8 7c ec ff ff       	call   8010393f <kill>
80104cc3:	83 c4 10             	add    $0x10,%esp
}
80104cc6:	c9                   	leave  
80104cc7:	c3                   	ret    
    return -1;
80104cc8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ccd:	eb f7                	jmp    80104cc6 <sys_kill+0x26>

80104ccf <sys_dump_physmem>:

int
sys_dump_physmem(void)
{
80104ccf:	55                   	push   %ebp
80104cd0:	89 e5                	mov    %esp,%ebp
80104cd2:	83 ec 20             	sub    $0x20,%esp
  int *frames;
  int *pids;
  int numframes;

  if(argint(2, &numframes) < 0)
80104cd5:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104cd8:	50                   	push   %eax
80104cd9:	6a 02                	push   $0x2
80104cdb:	e8 c3 f2 ff ff       	call   80103fa3 <argint>
80104ce0:	83 c4 10             	add    $0x10,%esp
80104ce3:	85 c0                	test   %eax,%eax
80104ce5:	78 4e                	js     80104d35 <sys_dump_physmem+0x66>
    return -1;
  if(argptr(0, (void *)&frames, numframes*sizeof(frames)) < 0)
80104ce7:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104cea:	c1 e0 02             	shl    $0x2,%eax
80104ced:	83 ec 04             	sub    $0x4,%esp
80104cf0:	50                   	push   %eax
80104cf1:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104cf4:	50                   	push   %eax
80104cf5:	6a 00                	push   $0x0
80104cf7:	e8 cf f2 ff ff       	call   80103fcb <argptr>
80104cfc:	83 c4 10             	add    $0x10,%esp
80104cff:	85 c0                	test   %eax,%eax
80104d01:	78 39                	js     80104d3c <sys_dump_physmem+0x6d>
    return -1;
  if(argptr(1, (void *)&pids, numframes*sizeof(pids)) < 0)
80104d03:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104d06:	c1 e0 02             	shl    $0x2,%eax
80104d09:	83 ec 04             	sub    $0x4,%esp
80104d0c:	50                   	push   %eax
80104d0d:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104d10:	50                   	push   %eax
80104d11:	6a 01                	push   $0x1
80104d13:	e8 b3 f2 ff ff       	call   80103fcb <argptr>
80104d18:	83 c4 10             	add    $0x10,%esp
80104d1b:	85 c0                	test   %eax,%eax
80104d1d:	78 24                	js     80104d43 <sys_dump_physmem+0x74>
    return -1;
  return dump_physmem(frames, pids, numframes);
80104d1f:	83 ec 04             	sub    $0x4,%esp
80104d22:	ff 75 ec             	pushl  -0x14(%ebp)
80104d25:	ff 75 f0             	pushl  -0x10(%ebp)
80104d28:	ff 75 f4             	pushl  -0xc(%ebp)
80104d2b:	e8 42 d4 ff ff       	call   80102172 <dump_physmem>
80104d30:	83 c4 10             	add    $0x10,%esp
}
80104d33:	c9                   	leave  
80104d34:	c3                   	ret    
    return -1;
80104d35:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d3a:	eb f7                	jmp    80104d33 <sys_dump_physmem+0x64>
    return -1;
80104d3c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d41:	eb f0                	jmp    80104d33 <sys_dump_physmem+0x64>
    return -1;
80104d43:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d48:	eb e9                	jmp    80104d33 <sys_dump_physmem+0x64>

80104d4a <sys_getpid>:

int
sys_getpid(void)
{
80104d4a:	55                   	push   %ebp
80104d4b:	89 e5                	mov    %esp,%ebp
80104d4d:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
80104d50:	e8 b8 e5 ff ff       	call   8010330d <myproc>
80104d55:	8b 40 10             	mov    0x10(%eax),%eax
}
80104d58:	c9                   	leave  
80104d59:	c3                   	ret    

80104d5a <sys_sbrk>:

int
sys_sbrk(void)
{
80104d5a:	55                   	push   %ebp
80104d5b:	89 e5                	mov    %esp,%ebp
80104d5d:	53                   	push   %ebx
80104d5e:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80104d61:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d64:	50                   	push   %eax
80104d65:	6a 00                	push   $0x0
80104d67:	e8 37 f2 ff ff       	call   80103fa3 <argint>
80104d6c:	83 c4 10             	add    $0x10,%esp
80104d6f:	85 c0                	test   %eax,%eax
80104d71:	78 27                	js     80104d9a <sys_sbrk+0x40>
    return -1;
  addr = myproc()->sz;
80104d73:	e8 95 e5 ff ff       	call   8010330d <myproc>
80104d78:	8b 18                	mov    (%eax),%ebx
  if(growproc(n) < 0)
80104d7a:	83 ec 0c             	sub    $0xc,%esp
80104d7d:	ff 75 f4             	pushl  -0xc(%ebp)
80104d80:	e8 93 e6 ff ff       	call   80103418 <growproc>
80104d85:	83 c4 10             	add    $0x10,%esp
80104d88:	85 c0                	test   %eax,%eax
80104d8a:	78 07                	js     80104d93 <sys_sbrk+0x39>
    return -1;
  return addr;
}
80104d8c:	89 d8                	mov    %ebx,%eax
80104d8e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104d91:	c9                   	leave  
80104d92:	c3                   	ret    
    return -1;
80104d93:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104d98:	eb f2                	jmp    80104d8c <sys_sbrk+0x32>
    return -1;
80104d9a:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104d9f:	eb eb                	jmp    80104d8c <sys_sbrk+0x32>

80104da1 <sys_sleep>:

int
sys_sleep(void)
{
80104da1:	55                   	push   %ebp
80104da2:	89 e5                	mov    %esp,%ebp
80104da4:	53                   	push   %ebx
80104da5:	83 ec 1c             	sub    $0x1c,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
80104da8:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104dab:	50                   	push   %eax
80104dac:	6a 00                	push   $0x0
80104dae:	e8 f0 f1 ff ff       	call   80103fa3 <argint>
80104db3:	83 c4 10             	add    $0x10,%esp
80104db6:	85 c0                	test   %eax,%eax
80104db8:	78 75                	js     80104e2f <sys_sleep+0x8e>
    return -1;
  acquire(&tickslock);
80104dba:	83 ec 0c             	sub    $0xc,%esp
80104dbd:	68 80 3c 19 80       	push   $0x80193c80
80104dc2:	e8 e5 ee ff ff       	call   80103cac <acquire>
  ticks0 = ticks;
80104dc7:	8b 1d c0 44 19 80    	mov    0x801944c0,%ebx
  while(ticks - ticks0 < n){
80104dcd:	83 c4 10             	add    $0x10,%esp
80104dd0:	a1 c0 44 19 80       	mov    0x801944c0,%eax
80104dd5:	29 d8                	sub    %ebx,%eax
80104dd7:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104dda:	73 39                	jae    80104e15 <sys_sleep+0x74>
    if(myproc()->killed){
80104ddc:	e8 2c e5 ff ff       	call   8010330d <myproc>
80104de1:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104de5:	75 17                	jne    80104dfe <sys_sleep+0x5d>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
80104de7:	83 ec 08             	sub    $0x8,%esp
80104dea:	68 80 3c 19 80       	push   $0x80193c80
80104def:	68 c0 44 19 80       	push   $0x801944c0
80104df4:	e8 b8 e9 ff ff       	call   801037b1 <sleep>
80104df9:	83 c4 10             	add    $0x10,%esp
80104dfc:	eb d2                	jmp    80104dd0 <sys_sleep+0x2f>
      release(&tickslock);
80104dfe:	83 ec 0c             	sub    $0xc,%esp
80104e01:	68 80 3c 19 80       	push   $0x80193c80
80104e06:	e8 06 ef ff ff       	call   80103d11 <release>
      return -1;
80104e0b:	83 c4 10             	add    $0x10,%esp
80104e0e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e13:	eb 15                	jmp    80104e2a <sys_sleep+0x89>
  }
  release(&tickslock);
80104e15:	83 ec 0c             	sub    $0xc,%esp
80104e18:	68 80 3c 19 80       	push   $0x80193c80
80104e1d:	e8 ef ee ff ff       	call   80103d11 <release>
  return 0;
80104e22:	83 c4 10             	add    $0x10,%esp
80104e25:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104e2a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104e2d:	c9                   	leave  
80104e2e:	c3                   	ret    
    return -1;
80104e2f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e34:	eb f4                	jmp    80104e2a <sys_sleep+0x89>

80104e36 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80104e36:	55                   	push   %ebp
80104e37:	89 e5                	mov    %esp,%ebp
80104e39:	53                   	push   %ebx
80104e3a:	83 ec 10             	sub    $0x10,%esp
  uint xticks;

  acquire(&tickslock);
80104e3d:	68 80 3c 19 80       	push   $0x80193c80
80104e42:	e8 65 ee ff ff       	call   80103cac <acquire>
  xticks = ticks;
80104e47:	8b 1d c0 44 19 80    	mov    0x801944c0,%ebx
  release(&tickslock);
80104e4d:	c7 04 24 80 3c 19 80 	movl   $0x80193c80,(%esp)
80104e54:	e8 b8 ee ff ff       	call   80103d11 <release>
  return xticks;
}
80104e59:	89 d8                	mov    %ebx,%eax
80104e5b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104e5e:	c9                   	leave  
80104e5f:	c3                   	ret    

80104e60 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80104e60:	1e                   	push   %ds
  pushl %es
80104e61:	06                   	push   %es
  pushl %fs
80104e62:	0f a0                	push   %fs
  pushl %gs
80104e64:	0f a8                	push   %gs
  pushal
80104e66:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
80104e67:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80104e6b:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80104e6d:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
80104e6f:	54                   	push   %esp
  call trap
80104e70:	e8 e3 00 00 00       	call   80104f58 <trap>
  addl $4, %esp
80104e75:	83 c4 04             	add    $0x4,%esp

80104e78 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80104e78:	61                   	popa   
  popl %gs
80104e79:	0f a9                	pop    %gs
  popl %fs
80104e7b:	0f a1                	pop    %fs
  popl %es
80104e7d:	07                   	pop    %es
  popl %ds
80104e7e:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80104e7f:	83 c4 08             	add    $0x8,%esp
  iret
80104e82:	cf                   	iret   

80104e83 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80104e83:	55                   	push   %ebp
80104e84:	89 e5                	mov    %esp,%ebp
80104e86:	83 ec 08             	sub    $0x8,%esp
  int i;

  for(i = 0; i < 256; i++)
80104e89:	b8 00 00 00 00       	mov    $0x0,%eax
80104e8e:	eb 4a                	jmp    80104eda <tvinit+0x57>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80104e90:	8b 0c 85 08 90 10 80 	mov    -0x7fef6ff8(,%eax,4),%ecx
80104e97:	66 89 0c c5 c0 3c 19 	mov    %cx,-0x7fe6c340(,%eax,8)
80104e9e:	80 
80104e9f:	66 c7 04 c5 c2 3c 19 	movw   $0x8,-0x7fe6c33e(,%eax,8)
80104ea6:	80 08 00 
80104ea9:	c6 04 c5 c4 3c 19 80 	movb   $0x0,-0x7fe6c33c(,%eax,8)
80104eb0:	00 
80104eb1:	0f b6 14 c5 c5 3c 19 	movzbl -0x7fe6c33b(,%eax,8),%edx
80104eb8:	80 
80104eb9:	83 e2 f0             	and    $0xfffffff0,%edx
80104ebc:	83 ca 0e             	or     $0xe,%edx
80104ebf:	83 e2 8f             	and    $0xffffff8f,%edx
80104ec2:	83 ca 80             	or     $0xffffff80,%edx
80104ec5:	88 14 c5 c5 3c 19 80 	mov    %dl,-0x7fe6c33b(,%eax,8)
80104ecc:	c1 e9 10             	shr    $0x10,%ecx
80104ecf:	66 89 0c c5 c6 3c 19 	mov    %cx,-0x7fe6c33a(,%eax,8)
80104ed6:	80 
  for(i = 0; i < 256; i++)
80104ed7:	83 c0 01             	add    $0x1,%eax
80104eda:	3d ff 00 00 00       	cmp    $0xff,%eax
80104edf:	7e af                	jle    80104e90 <tvinit+0xd>
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80104ee1:	8b 15 08 91 10 80    	mov    0x80109108,%edx
80104ee7:	66 89 15 c0 3e 19 80 	mov    %dx,0x80193ec0
80104eee:	66 c7 05 c2 3e 19 80 	movw   $0x8,0x80193ec2
80104ef5:	08 00 
80104ef7:	c6 05 c4 3e 19 80 00 	movb   $0x0,0x80193ec4
80104efe:	0f b6 05 c5 3e 19 80 	movzbl 0x80193ec5,%eax
80104f05:	83 c8 0f             	or     $0xf,%eax
80104f08:	83 e0 ef             	and    $0xffffffef,%eax
80104f0b:	83 c8 e0             	or     $0xffffffe0,%eax
80104f0e:	a2 c5 3e 19 80       	mov    %al,0x80193ec5
80104f13:	c1 ea 10             	shr    $0x10,%edx
80104f16:	66 89 15 c6 3e 19 80 	mov    %dx,0x80193ec6

  initlock(&tickslock, "time");
80104f1d:	83 ec 08             	sub    $0x8,%esp
80104f20:	68 5d 6d 10 80       	push   $0x80106d5d
80104f25:	68 80 3c 19 80       	push   $0x80193c80
80104f2a:	e8 41 ec ff ff       	call   80103b70 <initlock>
}
80104f2f:	83 c4 10             	add    $0x10,%esp
80104f32:	c9                   	leave  
80104f33:	c3                   	ret    

80104f34 <idtinit>:

void
idtinit(void)
{
80104f34:	55                   	push   %ebp
80104f35:	89 e5                	mov    %esp,%ebp
80104f37:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
80104f3a:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
  pd[1] = (uint)p;
80104f40:	b8 c0 3c 19 80       	mov    $0x80193cc0,%eax
80104f45:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80104f49:	c1 e8 10             	shr    $0x10,%eax
80104f4c:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lidt (%0)" : : "r" (pd));
80104f50:	8d 45 fa             	lea    -0x6(%ebp),%eax
80104f53:	0f 01 18             	lidtl  (%eax)
  lidt(idt, sizeof(idt));
}
80104f56:	c9                   	leave  
80104f57:	c3                   	ret    

80104f58 <trap>:

void
trap(struct trapframe *tf)
{
80104f58:	55                   	push   %ebp
80104f59:	89 e5                	mov    %esp,%ebp
80104f5b:	57                   	push   %edi
80104f5c:	56                   	push   %esi
80104f5d:	53                   	push   %ebx
80104f5e:	83 ec 1c             	sub    $0x1c,%esp
80104f61:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(tf->trapno == T_SYSCALL){
80104f64:	8b 43 30             	mov    0x30(%ebx),%eax
80104f67:	83 f8 40             	cmp    $0x40,%eax
80104f6a:	74 13                	je     80104f7f <trap+0x27>
    if(myproc()->killed)
      exit();
    return;
  }

  switch(tf->trapno){
80104f6c:	83 e8 20             	sub    $0x20,%eax
80104f6f:	83 f8 1f             	cmp    $0x1f,%eax
80104f72:	0f 87 3a 01 00 00    	ja     801050b2 <trap+0x15a>
80104f78:	ff 24 85 04 6e 10 80 	jmp    *-0x7fef91fc(,%eax,4)
    if(myproc()->killed)
80104f7f:	e8 89 e3 ff ff       	call   8010330d <myproc>
80104f84:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104f88:	75 1f                	jne    80104fa9 <trap+0x51>
    myproc()->tf = tf;
80104f8a:	e8 7e e3 ff ff       	call   8010330d <myproc>
80104f8f:	89 58 18             	mov    %ebx,0x18(%eax)
    syscall();
80104f92:	e8 cf f0 ff ff       	call   80104066 <syscall>
    if(myproc()->killed)
80104f97:	e8 71 e3 ff ff       	call   8010330d <myproc>
80104f9c:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104fa0:	74 7e                	je     80105020 <trap+0xc8>
      exit();
80104fa2:	e8 12 e7 ff ff       	call   801036b9 <exit>
80104fa7:	eb 77                	jmp    80105020 <trap+0xc8>
      exit();
80104fa9:	e8 0b e7 ff ff       	call   801036b9 <exit>
80104fae:	eb da                	jmp    80104f8a <trap+0x32>
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
80104fb0:	e8 3d e3 ff ff       	call   801032f2 <cpuid>
80104fb5:	85 c0                	test   %eax,%eax
80104fb7:	74 6f                	je     80105028 <trap+0xd0>
      acquire(&tickslock);
      ticks++;
      wakeup(&ticks);
      release(&tickslock);
    }
    lapiceoi();
80104fb9:	e8 f2 d4 ff ff       	call   801024b0 <lapiceoi>
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80104fbe:	e8 4a e3 ff ff       	call   8010330d <myproc>
80104fc3:	85 c0                	test   %eax,%eax
80104fc5:	74 1c                	je     80104fe3 <trap+0x8b>
80104fc7:	e8 41 e3 ff ff       	call   8010330d <myproc>
80104fcc:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104fd0:	74 11                	je     80104fe3 <trap+0x8b>
80104fd2:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80104fd6:	83 e0 03             	and    $0x3,%eax
80104fd9:	66 83 f8 03          	cmp    $0x3,%ax
80104fdd:	0f 84 62 01 00 00    	je     80105145 <trap+0x1ed>
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
80104fe3:	e8 25 e3 ff ff       	call   8010330d <myproc>
80104fe8:	85 c0                	test   %eax,%eax
80104fea:	74 0f                	je     80104ffb <trap+0xa3>
80104fec:	e8 1c e3 ff ff       	call   8010330d <myproc>
80104ff1:	83 78 0c 04          	cmpl   $0x4,0xc(%eax)
80104ff5:	0f 84 54 01 00 00    	je     8010514f <trap+0x1f7>
     tf->trapno == T_IRQ0+IRQ_TIMER)
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80104ffb:	e8 0d e3 ff ff       	call   8010330d <myproc>
80105000:	85 c0                	test   %eax,%eax
80105002:	74 1c                	je     80105020 <trap+0xc8>
80105004:	e8 04 e3 ff ff       	call   8010330d <myproc>
80105009:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010500d:	74 11                	je     80105020 <trap+0xc8>
8010500f:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80105013:	83 e0 03             	and    $0x3,%eax
80105016:	66 83 f8 03          	cmp    $0x3,%ax
8010501a:	0f 84 43 01 00 00    	je     80105163 <trap+0x20b>
    exit();
}
80105020:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105023:	5b                   	pop    %ebx
80105024:	5e                   	pop    %esi
80105025:	5f                   	pop    %edi
80105026:	5d                   	pop    %ebp
80105027:	c3                   	ret    
      acquire(&tickslock);
80105028:	83 ec 0c             	sub    $0xc,%esp
8010502b:	68 80 3c 19 80       	push   $0x80193c80
80105030:	e8 77 ec ff ff       	call   80103cac <acquire>
      ticks++;
80105035:	83 05 c0 44 19 80 01 	addl   $0x1,0x801944c0
      wakeup(&ticks);
8010503c:	c7 04 24 c0 44 19 80 	movl   $0x801944c0,(%esp)
80105043:	e8 ce e8 ff ff       	call   80103916 <wakeup>
      release(&tickslock);
80105048:	c7 04 24 80 3c 19 80 	movl   $0x80193c80,(%esp)
8010504f:	e8 bd ec ff ff       	call   80103d11 <release>
80105054:	83 c4 10             	add    $0x10,%esp
80105057:	e9 5d ff ff ff       	jmp    80104fb9 <trap+0x61>
    ideintr();
8010505c:	e8 12 cd ff ff       	call   80101d73 <ideintr>
    lapiceoi();
80105061:	e8 4a d4 ff ff       	call   801024b0 <lapiceoi>
    break;
80105066:	e9 53 ff ff ff       	jmp    80104fbe <trap+0x66>
    kbdintr();
8010506b:	e8 84 d2 ff ff       	call   801022f4 <kbdintr>
    lapiceoi();
80105070:	e8 3b d4 ff ff       	call   801024b0 <lapiceoi>
    break;
80105075:	e9 44 ff ff ff       	jmp    80104fbe <trap+0x66>
    uartintr();
8010507a:	e8 05 02 00 00       	call   80105284 <uartintr>
    lapiceoi();
8010507f:	e8 2c d4 ff ff       	call   801024b0 <lapiceoi>
    break;
80105084:	e9 35 ff ff ff       	jmp    80104fbe <trap+0x66>
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80105089:	8b 7b 38             	mov    0x38(%ebx),%edi
            cpuid(), tf->cs, tf->eip);
8010508c:	0f b7 73 3c          	movzwl 0x3c(%ebx),%esi
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80105090:	e8 5d e2 ff ff       	call   801032f2 <cpuid>
80105095:	57                   	push   %edi
80105096:	0f b7 f6             	movzwl %si,%esi
80105099:	56                   	push   %esi
8010509a:	50                   	push   %eax
8010509b:	68 68 6d 10 80       	push   $0x80106d68
801050a0:	e8 66 b5 ff ff       	call   8010060b <cprintf>
    lapiceoi();
801050a5:	e8 06 d4 ff ff       	call   801024b0 <lapiceoi>
    break;
801050aa:	83 c4 10             	add    $0x10,%esp
801050ad:	e9 0c ff ff ff       	jmp    80104fbe <trap+0x66>
    if(myproc() == 0 || (tf->cs&3) == 0){
801050b2:	e8 56 e2 ff ff       	call   8010330d <myproc>
801050b7:	85 c0                	test   %eax,%eax
801050b9:	74 5f                	je     8010511a <trap+0x1c2>
801050bb:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
801050bf:	74 59                	je     8010511a <trap+0x1c2>

static inline uint
rcr2(void)
{
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
801050c1:	0f 20 d7             	mov    %cr2,%edi
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801050c4:	8b 43 38             	mov    0x38(%ebx),%eax
801050c7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801050ca:	e8 23 e2 ff ff       	call   801032f2 <cpuid>
801050cf:	89 45 e0             	mov    %eax,-0x20(%ebp)
801050d2:	8b 53 34             	mov    0x34(%ebx),%edx
801050d5:	89 55 dc             	mov    %edx,-0x24(%ebp)
801050d8:	8b 73 30             	mov    0x30(%ebx),%esi
            myproc()->pid, myproc()->name, tf->trapno,
801050db:	e8 2d e2 ff ff       	call   8010330d <myproc>
801050e0:	8d 48 6c             	lea    0x6c(%eax),%ecx
801050e3:	89 4d d8             	mov    %ecx,-0x28(%ebp)
801050e6:	e8 22 e2 ff ff       	call   8010330d <myproc>
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801050eb:	57                   	push   %edi
801050ec:	ff 75 e4             	pushl  -0x1c(%ebp)
801050ef:	ff 75 e0             	pushl  -0x20(%ebp)
801050f2:	ff 75 dc             	pushl  -0x24(%ebp)
801050f5:	56                   	push   %esi
801050f6:	ff 75 d8             	pushl  -0x28(%ebp)
801050f9:	ff 70 10             	pushl  0x10(%eax)
801050fc:	68 c0 6d 10 80       	push   $0x80106dc0
80105101:	e8 05 b5 ff ff       	call   8010060b <cprintf>
    myproc()->killed = 1;
80105106:	83 c4 20             	add    $0x20,%esp
80105109:	e8 ff e1 ff ff       	call   8010330d <myproc>
8010510e:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80105115:	e9 a4 fe ff ff       	jmp    80104fbe <trap+0x66>
8010511a:	0f 20 d7             	mov    %cr2,%edi
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
8010511d:	8b 73 38             	mov    0x38(%ebx),%esi
80105120:	e8 cd e1 ff ff       	call   801032f2 <cpuid>
80105125:	83 ec 0c             	sub    $0xc,%esp
80105128:	57                   	push   %edi
80105129:	56                   	push   %esi
8010512a:	50                   	push   %eax
8010512b:	ff 73 30             	pushl  0x30(%ebx)
8010512e:	68 8c 6d 10 80       	push   $0x80106d8c
80105133:	e8 d3 b4 ff ff       	call   8010060b <cprintf>
      panic("trap");
80105138:	83 c4 14             	add    $0x14,%esp
8010513b:	68 62 6d 10 80       	push   $0x80106d62
80105140:	e8 03 b2 ff ff       	call   80100348 <panic>
    exit();
80105145:	e8 6f e5 ff ff       	call   801036b9 <exit>
8010514a:	e9 94 fe ff ff       	jmp    80104fe3 <trap+0x8b>
  if(myproc() && myproc()->state == RUNNING &&
8010514f:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
80105153:	0f 85 a2 fe ff ff    	jne    80104ffb <trap+0xa3>
    yield();
80105159:	e8 21 e6 ff ff       	call   8010377f <yield>
8010515e:	e9 98 fe ff ff       	jmp    80104ffb <trap+0xa3>
    exit();
80105163:	e8 51 e5 ff ff       	call   801036b9 <exit>
80105168:	e9 b3 fe ff ff       	jmp    80105020 <trap+0xc8>

8010516d <uartgetc>:
  outb(COM1+0, c);
}

static int
uartgetc(void)
{
8010516d:	55                   	push   %ebp
8010516e:	89 e5                	mov    %esp,%ebp
  if(!uart)
80105170:	83 3d bc 95 10 80 00 	cmpl   $0x0,0x801095bc
80105177:	74 15                	je     8010518e <uartgetc+0x21>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80105179:	ba fd 03 00 00       	mov    $0x3fd,%edx
8010517e:	ec                   	in     (%dx),%al
    return -1;
  if(!(inb(COM1+5) & 0x01))
8010517f:	a8 01                	test   $0x1,%al
80105181:	74 12                	je     80105195 <uartgetc+0x28>
80105183:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105188:	ec                   	in     (%dx),%al
    return -1;
  return inb(COM1+0);
80105189:	0f b6 c0             	movzbl %al,%eax
}
8010518c:	5d                   	pop    %ebp
8010518d:	c3                   	ret    
    return -1;
8010518e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105193:	eb f7                	jmp    8010518c <uartgetc+0x1f>
    return -1;
80105195:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010519a:	eb f0                	jmp    8010518c <uartgetc+0x1f>

8010519c <uartputc>:
  if(!uart)
8010519c:	83 3d bc 95 10 80 00 	cmpl   $0x0,0x801095bc
801051a3:	74 3b                	je     801051e0 <uartputc+0x44>
{
801051a5:	55                   	push   %ebp
801051a6:	89 e5                	mov    %esp,%ebp
801051a8:	53                   	push   %ebx
801051a9:	83 ec 04             	sub    $0x4,%esp
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801051ac:	bb 00 00 00 00       	mov    $0x0,%ebx
801051b1:	eb 10                	jmp    801051c3 <uartputc+0x27>
    microdelay(10);
801051b3:	83 ec 0c             	sub    $0xc,%esp
801051b6:	6a 0a                	push   $0xa
801051b8:	e8 12 d3 ff ff       	call   801024cf <microdelay>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801051bd:	83 c3 01             	add    $0x1,%ebx
801051c0:	83 c4 10             	add    $0x10,%esp
801051c3:	83 fb 7f             	cmp    $0x7f,%ebx
801051c6:	7f 0a                	jg     801051d2 <uartputc+0x36>
801051c8:	ba fd 03 00 00       	mov    $0x3fd,%edx
801051cd:	ec                   	in     (%dx),%al
801051ce:	a8 20                	test   $0x20,%al
801051d0:	74 e1                	je     801051b3 <uartputc+0x17>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801051d2:	8b 45 08             	mov    0x8(%ebp),%eax
801051d5:	ba f8 03 00 00       	mov    $0x3f8,%edx
801051da:	ee                   	out    %al,(%dx)
}
801051db:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801051de:	c9                   	leave  
801051df:	c3                   	ret    
801051e0:	f3 c3                	repz ret 

801051e2 <uartinit>:
{
801051e2:	55                   	push   %ebp
801051e3:	89 e5                	mov    %esp,%ebp
801051e5:	56                   	push   %esi
801051e6:	53                   	push   %ebx
801051e7:	b9 00 00 00 00       	mov    $0x0,%ecx
801051ec:	ba fa 03 00 00       	mov    $0x3fa,%edx
801051f1:	89 c8                	mov    %ecx,%eax
801051f3:	ee                   	out    %al,(%dx)
801051f4:	be fb 03 00 00       	mov    $0x3fb,%esi
801051f9:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
801051fe:	89 f2                	mov    %esi,%edx
80105200:	ee                   	out    %al,(%dx)
80105201:	b8 0c 00 00 00       	mov    $0xc,%eax
80105206:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010520b:	ee                   	out    %al,(%dx)
8010520c:	bb f9 03 00 00       	mov    $0x3f9,%ebx
80105211:	89 c8                	mov    %ecx,%eax
80105213:	89 da                	mov    %ebx,%edx
80105215:	ee                   	out    %al,(%dx)
80105216:	b8 03 00 00 00       	mov    $0x3,%eax
8010521b:	89 f2                	mov    %esi,%edx
8010521d:	ee                   	out    %al,(%dx)
8010521e:	ba fc 03 00 00       	mov    $0x3fc,%edx
80105223:	89 c8                	mov    %ecx,%eax
80105225:	ee                   	out    %al,(%dx)
80105226:	b8 01 00 00 00       	mov    $0x1,%eax
8010522b:	89 da                	mov    %ebx,%edx
8010522d:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010522e:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105233:	ec                   	in     (%dx),%al
  if(inb(COM1+5) == 0xFF)
80105234:	3c ff                	cmp    $0xff,%al
80105236:	74 45                	je     8010527d <uartinit+0x9b>
  uart = 1;
80105238:	c7 05 bc 95 10 80 01 	movl   $0x1,0x801095bc
8010523f:	00 00 00 
80105242:	ba fa 03 00 00       	mov    $0x3fa,%edx
80105247:	ec                   	in     (%dx),%al
80105248:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010524d:	ec                   	in     (%dx),%al
  ioapicenable(IRQ_COM1, 0);
8010524e:	83 ec 08             	sub    $0x8,%esp
80105251:	6a 00                	push   $0x0
80105253:	6a 04                	push   $0x4
80105255:	e8 24 cd ff ff       	call   80101f7e <ioapicenable>
  for(p="xv6...\n"; *p; p++)
8010525a:	83 c4 10             	add    $0x10,%esp
8010525d:	bb 84 6e 10 80       	mov    $0x80106e84,%ebx
80105262:	eb 12                	jmp    80105276 <uartinit+0x94>
    uartputc(*p);
80105264:	83 ec 0c             	sub    $0xc,%esp
80105267:	0f be c0             	movsbl %al,%eax
8010526a:	50                   	push   %eax
8010526b:	e8 2c ff ff ff       	call   8010519c <uartputc>
  for(p="xv6...\n"; *p; p++)
80105270:	83 c3 01             	add    $0x1,%ebx
80105273:	83 c4 10             	add    $0x10,%esp
80105276:	0f b6 03             	movzbl (%ebx),%eax
80105279:	84 c0                	test   %al,%al
8010527b:	75 e7                	jne    80105264 <uartinit+0x82>
}
8010527d:	8d 65 f8             	lea    -0x8(%ebp),%esp
80105280:	5b                   	pop    %ebx
80105281:	5e                   	pop    %esi
80105282:	5d                   	pop    %ebp
80105283:	c3                   	ret    

80105284 <uartintr>:

void
uartintr(void)
{
80105284:	55                   	push   %ebp
80105285:	89 e5                	mov    %esp,%ebp
80105287:	83 ec 14             	sub    $0x14,%esp
  consoleintr(uartgetc);
8010528a:	68 6d 51 10 80       	push   $0x8010516d
8010528f:	e8 aa b4 ff ff       	call   8010073e <consoleintr>
}
80105294:	83 c4 10             	add    $0x10,%esp
80105297:	c9                   	leave  
80105298:	c3                   	ret    

80105299 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80105299:	6a 00                	push   $0x0
  pushl $0
8010529b:	6a 00                	push   $0x0
  jmp alltraps
8010529d:	e9 be fb ff ff       	jmp    80104e60 <alltraps>

801052a2 <vector1>:
.globl vector1
vector1:
  pushl $0
801052a2:	6a 00                	push   $0x0
  pushl $1
801052a4:	6a 01                	push   $0x1
  jmp alltraps
801052a6:	e9 b5 fb ff ff       	jmp    80104e60 <alltraps>

801052ab <vector2>:
.globl vector2
vector2:
  pushl $0
801052ab:	6a 00                	push   $0x0
  pushl $2
801052ad:	6a 02                	push   $0x2
  jmp alltraps
801052af:	e9 ac fb ff ff       	jmp    80104e60 <alltraps>

801052b4 <vector3>:
.globl vector3
vector3:
  pushl $0
801052b4:	6a 00                	push   $0x0
  pushl $3
801052b6:	6a 03                	push   $0x3
  jmp alltraps
801052b8:	e9 a3 fb ff ff       	jmp    80104e60 <alltraps>

801052bd <vector4>:
.globl vector4
vector4:
  pushl $0
801052bd:	6a 00                	push   $0x0
  pushl $4
801052bf:	6a 04                	push   $0x4
  jmp alltraps
801052c1:	e9 9a fb ff ff       	jmp    80104e60 <alltraps>

801052c6 <vector5>:
.globl vector5
vector5:
  pushl $0
801052c6:	6a 00                	push   $0x0
  pushl $5
801052c8:	6a 05                	push   $0x5
  jmp alltraps
801052ca:	e9 91 fb ff ff       	jmp    80104e60 <alltraps>

801052cf <vector6>:
.globl vector6
vector6:
  pushl $0
801052cf:	6a 00                	push   $0x0
  pushl $6
801052d1:	6a 06                	push   $0x6
  jmp alltraps
801052d3:	e9 88 fb ff ff       	jmp    80104e60 <alltraps>

801052d8 <vector7>:
.globl vector7
vector7:
  pushl $0
801052d8:	6a 00                	push   $0x0
  pushl $7
801052da:	6a 07                	push   $0x7
  jmp alltraps
801052dc:	e9 7f fb ff ff       	jmp    80104e60 <alltraps>

801052e1 <vector8>:
.globl vector8
vector8:
  pushl $8
801052e1:	6a 08                	push   $0x8
  jmp alltraps
801052e3:	e9 78 fb ff ff       	jmp    80104e60 <alltraps>

801052e8 <vector9>:
.globl vector9
vector9:
  pushl $0
801052e8:	6a 00                	push   $0x0
  pushl $9
801052ea:	6a 09                	push   $0x9
  jmp alltraps
801052ec:	e9 6f fb ff ff       	jmp    80104e60 <alltraps>

801052f1 <vector10>:
.globl vector10
vector10:
  pushl $10
801052f1:	6a 0a                	push   $0xa
  jmp alltraps
801052f3:	e9 68 fb ff ff       	jmp    80104e60 <alltraps>

801052f8 <vector11>:
.globl vector11
vector11:
  pushl $11
801052f8:	6a 0b                	push   $0xb
  jmp alltraps
801052fa:	e9 61 fb ff ff       	jmp    80104e60 <alltraps>

801052ff <vector12>:
.globl vector12
vector12:
  pushl $12
801052ff:	6a 0c                	push   $0xc
  jmp alltraps
80105301:	e9 5a fb ff ff       	jmp    80104e60 <alltraps>

80105306 <vector13>:
.globl vector13
vector13:
  pushl $13
80105306:	6a 0d                	push   $0xd
  jmp alltraps
80105308:	e9 53 fb ff ff       	jmp    80104e60 <alltraps>

8010530d <vector14>:
.globl vector14
vector14:
  pushl $14
8010530d:	6a 0e                	push   $0xe
  jmp alltraps
8010530f:	e9 4c fb ff ff       	jmp    80104e60 <alltraps>

80105314 <vector15>:
.globl vector15
vector15:
  pushl $0
80105314:	6a 00                	push   $0x0
  pushl $15
80105316:	6a 0f                	push   $0xf
  jmp alltraps
80105318:	e9 43 fb ff ff       	jmp    80104e60 <alltraps>

8010531d <vector16>:
.globl vector16
vector16:
  pushl $0
8010531d:	6a 00                	push   $0x0
  pushl $16
8010531f:	6a 10                	push   $0x10
  jmp alltraps
80105321:	e9 3a fb ff ff       	jmp    80104e60 <alltraps>

80105326 <vector17>:
.globl vector17
vector17:
  pushl $17
80105326:	6a 11                	push   $0x11
  jmp alltraps
80105328:	e9 33 fb ff ff       	jmp    80104e60 <alltraps>

8010532d <vector18>:
.globl vector18
vector18:
  pushl $0
8010532d:	6a 00                	push   $0x0
  pushl $18
8010532f:	6a 12                	push   $0x12
  jmp alltraps
80105331:	e9 2a fb ff ff       	jmp    80104e60 <alltraps>

80105336 <vector19>:
.globl vector19
vector19:
  pushl $0
80105336:	6a 00                	push   $0x0
  pushl $19
80105338:	6a 13                	push   $0x13
  jmp alltraps
8010533a:	e9 21 fb ff ff       	jmp    80104e60 <alltraps>

8010533f <vector20>:
.globl vector20
vector20:
  pushl $0
8010533f:	6a 00                	push   $0x0
  pushl $20
80105341:	6a 14                	push   $0x14
  jmp alltraps
80105343:	e9 18 fb ff ff       	jmp    80104e60 <alltraps>

80105348 <vector21>:
.globl vector21
vector21:
  pushl $0
80105348:	6a 00                	push   $0x0
  pushl $21
8010534a:	6a 15                	push   $0x15
  jmp alltraps
8010534c:	e9 0f fb ff ff       	jmp    80104e60 <alltraps>

80105351 <vector22>:
.globl vector22
vector22:
  pushl $0
80105351:	6a 00                	push   $0x0
  pushl $22
80105353:	6a 16                	push   $0x16
  jmp alltraps
80105355:	e9 06 fb ff ff       	jmp    80104e60 <alltraps>

8010535a <vector23>:
.globl vector23
vector23:
  pushl $0
8010535a:	6a 00                	push   $0x0
  pushl $23
8010535c:	6a 17                	push   $0x17
  jmp alltraps
8010535e:	e9 fd fa ff ff       	jmp    80104e60 <alltraps>

80105363 <vector24>:
.globl vector24
vector24:
  pushl $0
80105363:	6a 00                	push   $0x0
  pushl $24
80105365:	6a 18                	push   $0x18
  jmp alltraps
80105367:	e9 f4 fa ff ff       	jmp    80104e60 <alltraps>

8010536c <vector25>:
.globl vector25
vector25:
  pushl $0
8010536c:	6a 00                	push   $0x0
  pushl $25
8010536e:	6a 19                	push   $0x19
  jmp alltraps
80105370:	e9 eb fa ff ff       	jmp    80104e60 <alltraps>

80105375 <vector26>:
.globl vector26
vector26:
  pushl $0
80105375:	6a 00                	push   $0x0
  pushl $26
80105377:	6a 1a                	push   $0x1a
  jmp alltraps
80105379:	e9 e2 fa ff ff       	jmp    80104e60 <alltraps>

8010537e <vector27>:
.globl vector27
vector27:
  pushl $0
8010537e:	6a 00                	push   $0x0
  pushl $27
80105380:	6a 1b                	push   $0x1b
  jmp alltraps
80105382:	e9 d9 fa ff ff       	jmp    80104e60 <alltraps>

80105387 <vector28>:
.globl vector28
vector28:
  pushl $0
80105387:	6a 00                	push   $0x0
  pushl $28
80105389:	6a 1c                	push   $0x1c
  jmp alltraps
8010538b:	e9 d0 fa ff ff       	jmp    80104e60 <alltraps>

80105390 <vector29>:
.globl vector29
vector29:
  pushl $0
80105390:	6a 00                	push   $0x0
  pushl $29
80105392:	6a 1d                	push   $0x1d
  jmp alltraps
80105394:	e9 c7 fa ff ff       	jmp    80104e60 <alltraps>

80105399 <vector30>:
.globl vector30
vector30:
  pushl $0
80105399:	6a 00                	push   $0x0
  pushl $30
8010539b:	6a 1e                	push   $0x1e
  jmp alltraps
8010539d:	e9 be fa ff ff       	jmp    80104e60 <alltraps>

801053a2 <vector31>:
.globl vector31
vector31:
  pushl $0
801053a2:	6a 00                	push   $0x0
  pushl $31
801053a4:	6a 1f                	push   $0x1f
  jmp alltraps
801053a6:	e9 b5 fa ff ff       	jmp    80104e60 <alltraps>

801053ab <vector32>:
.globl vector32
vector32:
  pushl $0
801053ab:	6a 00                	push   $0x0
  pushl $32
801053ad:	6a 20                	push   $0x20
  jmp alltraps
801053af:	e9 ac fa ff ff       	jmp    80104e60 <alltraps>

801053b4 <vector33>:
.globl vector33
vector33:
  pushl $0
801053b4:	6a 00                	push   $0x0
  pushl $33
801053b6:	6a 21                	push   $0x21
  jmp alltraps
801053b8:	e9 a3 fa ff ff       	jmp    80104e60 <alltraps>

801053bd <vector34>:
.globl vector34
vector34:
  pushl $0
801053bd:	6a 00                	push   $0x0
  pushl $34
801053bf:	6a 22                	push   $0x22
  jmp alltraps
801053c1:	e9 9a fa ff ff       	jmp    80104e60 <alltraps>

801053c6 <vector35>:
.globl vector35
vector35:
  pushl $0
801053c6:	6a 00                	push   $0x0
  pushl $35
801053c8:	6a 23                	push   $0x23
  jmp alltraps
801053ca:	e9 91 fa ff ff       	jmp    80104e60 <alltraps>

801053cf <vector36>:
.globl vector36
vector36:
  pushl $0
801053cf:	6a 00                	push   $0x0
  pushl $36
801053d1:	6a 24                	push   $0x24
  jmp alltraps
801053d3:	e9 88 fa ff ff       	jmp    80104e60 <alltraps>

801053d8 <vector37>:
.globl vector37
vector37:
  pushl $0
801053d8:	6a 00                	push   $0x0
  pushl $37
801053da:	6a 25                	push   $0x25
  jmp alltraps
801053dc:	e9 7f fa ff ff       	jmp    80104e60 <alltraps>

801053e1 <vector38>:
.globl vector38
vector38:
  pushl $0
801053e1:	6a 00                	push   $0x0
  pushl $38
801053e3:	6a 26                	push   $0x26
  jmp alltraps
801053e5:	e9 76 fa ff ff       	jmp    80104e60 <alltraps>

801053ea <vector39>:
.globl vector39
vector39:
  pushl $0
801053ea:	6a 00                	push   $0x0
  pushl $39
801053ec:	6a 27                	push   $0x27
  jmp alltraps
801053ee:	e9 6d fa ff ff       	jmp    80104e60 <alltraps>

801053f3 <vector40>:
.globl vector40
vector40:
  pushl $0
801053f3:	6a 00                	push   $0x0
  pushl $40
801053f5:	6a 28                	push   $0x28
  jmp alltraps
801053f7:	e9 64 fa ff ff       	jmp    80104e60 <alltraps>

801053fc <vector41>:
.globl vector41
vector41:
  pushl $0
801053fc:	6a 00                	push   $0x0
  pushl $41
801053fe:	6a 29                	push   $0x29
  jmp alltraps
80105400:	e9 5b fa ff ff       	jmp    80104e60 <alltraps>

80105405 <vector42>:
.globl vector42
vector42:
  pushl $0
80105405:	6a 00                	push   $0x0
  pushl $42
80105407:	6a 2a                	push   $0x2a
  jmp alltraps
80105409:	e9 52 fa ff ff       	jmp    80104e60 <alltraps>

8010540e <vector43>:
.globl vector43
vector43:
  pushl $0
8010540e:	6a 00                	push   $0x0
  pushl $43
80105410:	6a 2b                	push   $0x2b
  jmp alltraps
80105412:	e9 49 fa ff ff       	jmp    80104e60 <alltraps>

80105417 <vector44>:
.globl vector44
vector44:
  pushl $0
80105417:	6a 00                	push   $0x0
  pushl $44
80105419:	6a 2c                	push   $0x2c
  jmp alltraps
8010541b:	e9 40 fa ff ff       	jmp    80104e60 <alltraps>

80105420 <vector45>:
.globl vector45
vector45:
  pushl $0
80105420:	6a 00                	push   $0x0
  pushl $45
80105422:	6a 2d                	push   $0x2d
  jmp alltraps
80105424:	e9 37 fa ff ff       	jmp    80104e60 <alltraps>

80105429 <vector46>:
.globl vector46
vector46:
  pushl $0
80105429:	6a 00                	push   $0x0
  pushl $46
8010542b:	6a 2e                	push   $0x2e
  jmp alltraps
8010542d:	e9 2e fa ff ff       	jmp    80104e60 <alltraps>

80105432 <vector47>:
.globl vector47
vector47:
  pushl $0
80105432:	6a 00                	push   $0x0
  pushl $47
80105434:	6a 2f                	push   $0x2f
  jmp alltraps
80105436:	e9 25 fa ff ff       	jmp    80104e60 <alltraps>

8010543b <vector48>:
.globl vector48
vector48:
  pushl $0
8010543b:	6a 00                	push   $0x0
  pushl $48
8010543d:	6a 30                	push   $0x30
  jmp alltraps
8010543f:	e9 1c fa ff ff       	jmp    80104e60 <alltraps>

80105444 <vector49>:
.globl vector49
vector49:
  pushl $0
80105444:	6a 00                	push   $0x0
  pushl $49
80105446:	6a 31                	push   $0x31
  jmp alltraps
80105448:	e9 13 fa ff ff       	jmp    80104e60 <alltraps>

8010544d <vector50>:
.globl vector50
vector50:
  pushl $0
8010544d:	6a 00                	push   $0x0
  pushl $50
8010544f:	6a 32                	push   $0x32
  jmp alltraps
80105451:	e9 0a fa ff ff       	jmp    80104e60 <alltraps>

80105456 <vector51>:
.globl vector51
vector51:
  pushl $0
80105456:	6a 00                	push   $0x0
  pushl $51
80105458:	6a 33                	push   $0x33
  jmp alltraps
8010545a:	e9 01 fa ff ff       	jmp    80104e60 <alltraps>

8010545f <vector52>:
.globl vector52
vector52:
  pushl $0
8010545f:	6a 00                	push   $0x0
  pushl $52
80105461:	6a 34                	push   $0x34
  jmp alltraps
80105463:	e9 f8 f9 ff ff       	jmp    80104e60 <alltraps>

80105468 <vector53>:
.globl vector53
vector53:
  pushl $0
80105468:	6a 00                	push   $0x0
  pushl $53
8010546a:	6a 35                	push   $0x35
  jmp alltraps
8010546c:	e9 ef f9 ff ff       	jmp    80104e60 <alltraps>

80105471 <vector54>:
.globl vector54
vector54:
  pushl $0
80105471:	6a 00                	push   $0x0
  pushl $54
80105473:	6a 36                	push   $0x36
  jmp alltraps
80105475:	e9 e6 f9 ff ff       	jmp    80104e60 <alltraps>

8010547a <vector55>:
.globl vector55
vector55:
  pushl $0
8010547a:	6a 00                	push   $0x0
  pushl $55
8010547c:	6a 37                	push   $0x37
  jmp alltraps
8010547e:	e9 dd f9 ff ff       	jmp    80104e60 <alltraps>

80105483 <vector56>:
.globl vector56
vector56:
  pushl $0
80105483:	6a 00                	push   $0x0
  pushl $56
80105485:	6a 38                	push   $0x38
  jmp alltraps
80105487:	e9 d4 f9 ff ff       	jmp    80104e60 <alltraps>

8010548c <vector57>:
.globl vector57
vector57:
  pushl $0
8010548c:	6a 00                	push   $0x0
  pushl $57
8010548e:	6a 39                	push   $0x39
  jmp alltraps
80105490:	e9 cb f9 ff ff       	jmp    80104e60 <alltraps>

80105495 <vector58>:
.globl vector58
vector58:
  pushl $0
80105495:	6a 00                	push   $0x0
  pushl $58
80105497:	6a 3a                	push   $0x3a
  jmp alltraps
80105499:	e9 c2 f9 ff ff       	jmp    80104e60 <alltraps>

8010549e <vector59>:
.globl vector59
vector59:
  pushl $0
8010549e:	6a 00                	push   $0x0
  pushl $59
801054a0:	6a 3b                	push   $0x3b
  jmp alltraps
801054a2:	e9 b9 f9 ff ff       	jmp    80104e60 <alltraps>

801054a7 <vector60>:
.globl vector60
vector60:
  pushl $0
801054a7:	6a 00                	push   $0x0
  pushl $60
801054a9:	6a 3c                	push   $0x3c
  jmp alltraps
801054ab:	e9 b0 f9 ff ff       	jmp    80104e60 <alltraps>

801054b0 <vector61>:
.globl vector61
vector61:
  pushl $0
801054b0:	6a 00                	push   $0x0
  pushl $61
801054b2:	6a 3d                	push   $0x3d
  jmp alltraps
801054b4:	e9 a7 f9 ff ff       	jmp    80104e60 <alltraps>

801054b9 <vector62>:
.globl vector62
vector62:
  pushl $0
801054b9:	6a 00                	push   $0x0
  pushl $62
801054bb:	6a 3e                	push   $0x3e
  jmp alltraps
801054bd:	e9 9e f9 ff ff       	jmp    80104e60 <alltraps>

801054c2 <vector63>:
.globl vector63
vector63:
  pushl $0
801054c2:	6a 00                	push   $0x0
  pushl $63
801054c4:	6a 3f                	push   $0x3f
  jmp alltraps
801054c6:	e9 95 f9 ff ff       	jmp    80104e60 <alltraps>

801054cb <vector64>:
.globl vector64
vector64:
  pushl $0
801054cb:	6a 00                	push   $0x0
  pushl $64
801054cd:	6a 40                	push   $0x40
  jmp alltraps
801054cf:	e9 8c f9 ff ff       	jmp    80104e60 <alltraps>

801054d4 <vector65>:
.globl vector65
vector65:
  pushl $0
801054d4:	6a 00                	push   $0x0
  pushl $65
801054d6:	6a 41                	push   $0x41
  jmp alltraps
801054d8:	e9 83 f9 ff ff       	jmp    80104e60 <alltraps>

801054dd <vector66>:
.globl vector66
vector66:
  pushl $0
801054dd:	6a 00                	push   $0x0
  pushl $66
801054df:	6a 42                	push   $0x42
  jmp alltraps
801054e1:	e9 7a f9 ff ff       	jmp    80104e60 <alltraps>

801054e6 <vector67>:
.globl vector67
vector67:
  pushl $0
801054e6:	6a 00                	push   $0x0
  pushl $67
801054e8:	6a 43                	push   $0x43
  jmp alltraps
801054ea:	e9 71 f9 ff ff       	jmp    80104e60 <alltraps>

801054ef <vector68>:
.globl vector68
vector68:
  pushl $0
801054ef:	6a 00                	push   $0x0
  pushl $68
801054f1:	6a 44                	push   $0x44
  jmp alltraps
801054f3:	e9 68 f9 ff ff       	jmp    80104e60 <alltraps>

801054f8 <vector69>:
.globl vector69
vector69:
  pushl $0
801054f8:	6a 00                	push   $0x0
  pushl $69
801054fa:	6a 45                	push   $0x45
  jmp alltraps
801054fc:	e9 5f f9 ff ff       	jmp    80104e60 <alltraps>

80105501 <vector70>:
.globl vector70
vector70:
  pushl $0
80105501:	6a 00                	push   $0x0
  pushl $70
80105503:	6a 46                	push   $0x46
  jmp alltraps
80105505:	e9 56 f9 ff ff       	jmp    80104e60 <alltraps>

8010550a <vector71>:
.globl vector71
vector71:
  pushl $0
8010550a:	6a 00                	push   $0x0
  pushl $71
8010550c:	6a 47                	push   $0x47
  jmp alltraps
8010550e:	e9 4d f9 ff ff       	jmp    80104e60 <alltraps>

80105513 <vector72>:
.globl vector72
vector72:
  pushl $0
80105513:	6a 00                	push   $0x0
  pushl $72
80105515:	6a 48                	push   $0x48
  jmp alltraps
80105517:	e9 44 f9 ff ff       	jmp    80104e60 <alltraps>

8010551c <vector73>:
.globl vector73
vector73:
  pushl $0
8010551c:	6a 00                	push   $0x0
  pushl $73
8010551e:	6a 49                	push   $0x49
  jmp alltraps
80105520:	e9 3b f9 ff ff       	jmp    80104e60 <alltraps>

80105525 <vector74>:
.globl vector74
vector74:
  pushl $0
80105525:	6a 00                	push   $0x0
  pushl $74
80105527:	6a 4a                	push   $0x4a
  jmp alltraps
80105529:	e9 32 f9 ff ff       	jmp    80104e60 <alltraps>

8010552e <vector75>:
.globl vector75
vector75:
  pushl $0
8010552e:	6a 00                	push   $0x0
  pushl $75
80105530:	6a 4b                	push   $0x4b
  jmp alltraps
80105532:	e9 29 f9 ff ff       	jmp    80104e60 <alltraps>

80105537 <vector76>:
.globl vector76
vector76:
  pushl $0
80105537:	6a 00                	push   $0x0
  pushl $76
80105539:	6a 4c                	push   $0x4c
  jmp alltraps
8010553b:	e9 20 f9 ff ff       	jmp    80104e60 <alltraps>

80105540 <vector77>:
.globl vector77
vector77:
  pushl $0
80105540:	6a 00                	push   $0x0
  pushl $77
80105542:	6a 4d                	push   $0x4d
  jmp alltraps
80105544:	e9 17 f9 ff ff       	jmp    80104e60 <alltraps>

80105549 <vector78>:
.globl vector78
vector78:
  pushl $0
80105549:	6a 00                	push   $0x0
  pushl $78
8010554b:	6a 4e                	push   $0x4e
  jmp alltraps
8010554d:	e9 0e f9 ff ff       	jmp    80104e60 <alltraps>

80105552 <vector79>:
.globl vector79
vector79:
  pushl $0
80105552:	6a 00                	push   $0x0
  pushl $79
80105554:	6a 4f                	push   $0x4f
  jmp alltraps
80105556:	e9 05 f9 ff ff       	jmp    80104e60 <alltraps>

8010555b <vector80>:
.globl vector80
vector80:
  pushl $0
8010555b:	6a 00                	push   $0x0
  pushl $80
8010555d:	6a 50                	push   $0x50
  jmp alltraps
8010555f:	e9 fc f8 ff ff       	jmp    80104e60 <alltraps>

80105564 <vector81>:
.globl vector81
vector81:
  pushl $0
80105564:	6a 00                	push   $0x0
  pushl $81
80105566:	6a 51                	push   $0x51
  jmp alltraps
80105568:	e9 f3 f8 ff ff       	jmp    80104e60 <alltraps>

8010556d <vector82>:
.globl vector82
vector82:
  pushl $0
8010556d:	6a 00                	push   $0x0
  pushl $82
8010556f:	6a 52                	push   $0x52
  jmp alltraps
80105571:	e9 ea f8 ff ff       	jmp    80104e60 <alltraps>

80105576 <vector83>:
.globl vector83
vector83:
  pushl $0
80105576:	6a 00                	push   $0x0
  pushl $83
80105578:	6a 53                	push   $0x53
  jmp alltraps
8010557a:	e9 e1 f8 ff ff       	jmp    80104e60 <alltraps>

8010557f <vector84>:
.globl vector84
vector84:
  pushl $0
8010557f:	6a 00                	push   $0x0
  pushl $84
80105581:	6a 54                	push   $0x54
  jmp alltraps
80105583:	e9 d8 f8 ff ff       	jmp    80104e60 <alltraps>

80105588 <vector85>:
.globl vector85
vector85:
  pushl $0
80105588:	6a 00                	push   $0x0
  pushl $85
8010558a:	6a 55                	push   $0x55
  jmp alltraps
8010558c:	e9 cf f8 ff ff       	jmp    80104e60 <alltraps>

80105591 <vector86>:
.globl vector86
vector86:
  pushl $0
80105591:	6a 00                	push   $0x0
  pushl $86
80105593:	6a 56                	push   $0x56
  jmp alltraps
80105595:	e9 c6 f8 ff ff       	jmp    80104e60 <alltraps>

8010559a <vector87>:
.globl vector87
vector87:
  pushl $0
8010559a:	6a 00                	push   $0x0
  pushl $87
8010559c:	6a 57                	push   $0x57
  jmp alltraps
8010559e:	e9 bd f8 ff ff       	jmp    80104e60 <alltraps>

801055a3 <vector88>:
.globl vector88
vector88:
  pushl $0
801055a3:	6a 00                	push   $0x0
  pushl $88
801055a5:	6a 58                	push   $0x58
  jmp alltraps
801055a7:	e9 b4 f8 ff ff       	jmp    80104e60 <alltraps>

801055ac <vector89>:
.globl vector89
vector89:
  pushl $0
801055ac:	6a 00                	push   $0x0
  pushl $89
801055ae:	6a 59                	push   $0x59
  jmp alltraps
801055b0:	e9 ab f8 ff ff       	jmp    80104e60 <alltraps>

801055b5 <vector90>:
.globl vector90
vector90:
  pushl $0
801055b5:	6a 00                	push   $0x0
  pushl $90
801055b7:	6a 5a                	push   $0x5a
  jmp alltraps
801055b9:	e9 a2 f8 ff ff       	jmp    80104e60 <alltraps>

801055be <vector91>:
.globl vector91
vector91:
  pushl $0
801055be:	6a 00                	push   $0x0
  pushl $91
801055c0:	6a 5b                	push   $0x5b
  jmp alltraps
801055c2:	e9 99 f8 ff ff       	jmp    80104e60 <alltraps>

801055c7 <vector92>:
.globl vector92
vector92:
  pushl $0
801055c7:	6a 00                	push   $0x0
  pushl $92
801055c9:	6a 5c                	push   $0x5c
  jmp alltraps
801055cb:	e9 90 f8 ff ff       	jmp    80104e60 <alltraps>

801055d0 <vector93>:
.globl vector93
vector93:
  pushl $0
801055d0:	6a 00                	push   $0x0
  pushl $93
801055d2:	6a 5d                	push   $0x5d
  jmp alltraps
801055d4:	e9 87 f8 ff ff       	jmp    80104e60 <alltraps>

801055d9 <vector94>:
.globl vector94
vector94:
  pushl $0
801055d9:	6a 00                	push   $0x0
  pushl $94
801055db:	6a 5e                	push   $0x5e
  jmp alltraps
801055dd:	e9 7e f8 ff ff       	jmp    80104e60 <alltraps>

801055e2 <vector95>:
.globl vector95
vector95:
  pushl $0
801055e2:	6a 00                	push   $0x0
  pushl $95
801055e4:	6a 5f                	push   $0x5f
  jmp alltraps
801055e6:	e9 75 f8 ff ff       	jmp    80104e60 <alltraps>

801055eb <vector96>:
.globl vector96
vector96:
  pushl $0
801055eb:	6a 00                	push   $0x0
  pushl $96
801055ed:	6a 60                	push   $0x60
  jmp alltraps
801055ef:	e9 6c f8 ff ff       	jmp    80104e60 <alltraps>

801055f4 <vector97>:
.globl vector97
vector97:
  pushl $0
801055f4:	6a 00                	push   $0x0
  pushl $97
801055f6:	6a 61                	push   $0x61
  jmp alltraps
801055f8:	e9 63 f8 ff ff       	jmp    80104e60 <alltraps>

801055fd <vector98>:
.globl vector98
vector98:
  pushl $0
801055fd:	6a 00                	push   $0x0
  pushl $98
801055ff:	6a 62                	push   $0x62
  jmp alltraps
80105601:	e9 5a f8 ff ff       	jmp    80104e60 <alltraps>

80105606 <vector99>:
.globl vector99
vector99:
  pushl $0
80105606:	6a 00                	push   $0x0
  pushl $99
80105608:	6a 63                	push   $0x63
  jmp alltraps
8010560a:	e9 51 f8 ff ff       	jmp    80104e60 <alltraps>

8010560f <vector100>:
.globl vector100
vector100:
  pushl $0
8010560f:	6a 00                	push   $0x0
  pushl $100
80105611:	6a 64                	push   $0x64
  jmp alltraps
80105613:	e9 48 f8 ff ff       	jmp    80104e60 <alltraps>

80105618 <vector101>:
.globl vector101
vector101:
  pushl $0
80105618:	6a 00                	push   $0x0
  pushl $101
8010561a:	6a 65                	push   $0x65
  jmp alltraps
8010561c:	e9 3f f8 ff ff       	jmp    80104e60 <alltraps>

80105621 <vector102>:
.globl vector102
vector102:
  pushl $0
80105621:	6a 00                	push   $0x0
  pushl $102
80105623:	6a 66                	push   $0x66
  jmp alltraps
80105625:	e9 36 f8 ff ff       	jmp    80104e60 <alltraps>

8010562a <vector103>:
.globl vector103
vector103:
  pushl $0
8010562a:	6a 00                	push   $0x0
  pushl $103
8010562c:	6a 67                	push   $0x67
  jmp alltraps
8010562e:	e9 2d f8 ff ff       	jmp    80104e60 <alltraps>

80105633 <vector104>:
.globl vector104
vector104:
  pushl $0
80105633:	6a 00                	push   $0x0
  pushl $104
80105635:	6a 68                	push   $0x68
  jmp alltraps
80105637:	e9 24 f8 ff ff       	jmp    80104e60 <alltraps>

8010563c <vector105>:
.globl vector105
vector105:
  pushl $0
8010563c:	6a 00                	push   $0x0
  pushl $105
8010563e:	6a 69                	push   $0x69
  jmp alltraps
80105640:	e9 1b f8 ff ff       	jmp    80104e60 <alltraps>

80105645 <vector106>:
.globl vector106
vector106:
  pushl $0
80105645:	6a 00                	push   $0x0
  pushl $106
80105647:	6a 6a                	push   $0x6a
  jmp alltraps
80105649:	e9 12 f8 ff ff       	jmp    80104e60 <alltraps>

8010564e <vector107>:
.globl vector107
vector107:
  pushl $0
8010564e:	6a 00                	push   $0x0
  pushl $107
80105650:	6a 6b                	push   $0x6b
  jmp alltraps
80105652:	e9 09 f8 ff ff       	jmp    80104e60 <alltraps>

80105657 <vector108>:
.globl vector108
vector108:
  pushl $0
80105657:	6a 00                	push   $0x0
  pushl $108
80105659:	6a 6c                	push   $0x6c
  jmp alltraps
8010565b:	e9 00 f8 ff ff       	jmp    80104e60 <alltraps>

80105660 <vector109>:
.globl vector109
vector109:
  pushl $0
80105660:	6a 00                	push   $0x0
  pushl $109
80105662:	6a 6d                	push   $0x6d
  jmp alltraps
80105664:	e9 f7 f7 ff ff       	jmp    80104e60 <alltraps>

80105669 <vector110>:
.globl vector110
vector110:
  pushl $0
80105669:	6a 00                	push   $0x0
  pushl $110
8010566b:	6a 6e                	push   $0x6e
  jmp alltraps
8010566d:	e9 ee f7 ff ff       	jmp    80104e60 <alltraps>

80105672 <vector111>:
.globl vector111
vector111:
  pushl $0
80105672:	6a 00                	push   $0x0
  pushl $111
80105674:	6a 6f                	push   $0x6f
  jmp alltraps
80105676:	e9 e5 f7 ff ff       	jmp    80104e60 <alltraps>

8010567b <vector112>:
.globl vector112
vector112:
  pushl $0
8010567b:	6a 00                	push   $0x0
  pushl $112
8010567d:	6a 70                	push   $0x70
  jmp alltraps
8010567f:	e9 dc f7 ff ff       	jmp    80104e60 <alltraps>

80105684 <vector113>:
.globl vector113
vector113:
  pushl $0
80105684:	6a 00                	push   $0x0
  pushl $113
80105686:	6a 71                	push   $0x71
  jmp alltraps
80105688:	e9 d3 f7 ff ff       	jmp    80104e60 <alltraps>

8010568d <vector114>:
.globl vector114
vector114:
  pushl $0
8010568d:	6a 00                	push   $0x0
  pushl $114
8010568f:	6a 72                	push   $0x72
  jmp alltraps
80105691:	e9 ca f7 ff ff       	jmp    80104e60 <alltraps>

80105696 <vector115>:
.globl vector115
vector115:
  pushl $0
80105696:	6a 00                	push   $0x0
  pushl $115
80105698:	6a 73                	push   $0x73
  jmp alltraps
8010569a:	e9 c1 f7 ff ff       	jmp    80104e60 <alltraps>

8010569f <vector116>:
.globl vector116
vector116:
  pushl $0
8010569f:	6a 00                	push   $0x0
  pushl $116
801056a1:	6a 74                	push   $0x74
  jmp alltraps
801056a3:	e9 b8 f7 ff ff       	jmp    80104e60 <alltraps>

801056a8 <vector117>:
.globl vector117
vector117:
  pushl $0
801056a8:	6a 00                	push   $0x0
  pushl $117
801056aa:	6a 75                	push   $0x75
  jmp alltraps
801056ac:	e9 af f7 ff ff       	jmp    80104e60 <alltraps>

801056b1 <vector118>:
.globl vector118
vector118:
  pushl $0
801056b1:	6a 00                	push   $0x0
  pushl $118
801056b3:	6a 76                	push   $0x76
  jmp alltraps
801056b5:	e9 a6 f7 ff ff       	jmp    80104e60 <alltraps>

801056ba <vector119>:
.globl vector119
vector119:
  pushl $0
801056ba:	6a 00                	push   $0x0
  pushl $119
801056bc:	6a 77                	push   $0x77
  jmp alltraps
801056be:	e9 9d f7 ff ff       	jmp    80104e60 <alltraps>

801056c3 <vector120>:
.globl vector120
vector120:
  pushl $0
801056c3:	6a 00                	push   $0x0
  pushl $120
801056c5:	6a 78                	push   $0x78
  jmp alltraps
801056c7:	e9 94 f7 ff ff       	jmp    80104e60 <alltraps>

801056cc <vector121>:
.globl vector121
vector121:
  pushl $0
801056cc:	6a 00                	push   $0x0
  pushl $121
801056ce:	6a 79                	push   $0x79
  jmp alltraps
801056d0:	e9 8b f7 ff ff       	jmp    80104e60 <alltraps>

801056d5 <vector122>:
.globl vector122
vector122:
  pushl $0
801056d5:	6a 00                	push   $0x0
  pushl $122
801056d7:	6a 7a                	push   $0x7a
  jmp alltraps
801056d9:	e9 82 f7 ff ff       	jmp    80104e60 <alltraps>

801056de <vector123>:
.globl vector123
vector123:
  pushl $0
801056de:	6a 00                	push   $0x0
  pushl $123
801056e0:	6a 7b                	push   $0x7b
  jmp alltraps
801056e2:	e9 79 f7 ff ff       	jmp    80104e60 <alltraps>

801056e7 <vector124>:
.globl vector124
vector124:
  pushl $0
801056e7:	6a 00                	push   $0x0
  pushl $124
801056e9:	6a 7c                	push   $0x7c
  jmp alltraps
801056eb:	e9 70 f7 ff ff       	jmp    80104e60 <alltraps>

801056f0 <vector125>:
.globl vector125
vector125:
  pushl $0
801056f0:	6a 00                	push   $0x0
  pushl $125
801056f2:	6a 7d                	push   $0x7d
  jmp alltraps
801056f4:	e9 67 f7 ff ff       	jmp    80104e60 <alltraps>

801056f9 <vector126>:
.globl vector126
vector126:
  pushl $0
801056f9:	6a 00                	push   $0x0
  pushl $126
801056fb:	6a 7e                	push   $0x7e
  jmp alltraps
801056fd:	e9 5e f7 ff ff       	jmp    80104e60 <alltraps>

80105702 <vector127>:
.globl vector127
vector127:
  pushl $0
80105702:	6a 00                	push   $0x0
  pushl $127
80105704:	6a 7f                	push   $0x7f
  jmp alltraps
80105706:	e9 55 f7 ff ff       	jmp    80104e60 <alltraps>

8010570b <vector128>:
.globl vector128
vector128:
  pushl $0
8010570b:	6a 00                	push   $0x0
  pushl $128
8010570d:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80105712:	e9 49 f7 ff ff       	jmp    80104e60 <alltraps>

80105717 <vector129>:
.globl vector129
vector129:
  pushl $0
80105717:	6a 00                	push   $0x0
  pushl $129
80105719:	68 81 00 00 00       	push   $0x81
  jmp alltraps
8010571e:	e9 3d f7 ff ff       	jmp    80104e60 <alltraps>

80105723 <vector130>:
.globl vector130
vector130:
  pushl $0
80105723:	6a 00                	push   $0x0
  pushl $130
80105725:	68 82 00 00 00       	push   $0x82
  jmp alltraps
8010572a:	e9 31 f7 ff ff       	jmp    80104e60 <alltraps>

8010572f <vector131>:
.globl vector131
vector131:
  pushl $0
8010572f:	6a 00                	push   $0x0
  pushl $131
80105731:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80105736:	e9 25 f7 ff ff       	jmp    80104e60 <alltraps>

8010573b <vector132>:
.globl vector132
vector132:
  pushl $0
8010573b:	6a 00                	push   $0x0
  pushl $132
8010573d:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80105742:	e9 19 f7 ff ff       	jmp    80104e60 <alltraps>

80105747 <vector133>:
.globl vector133
vector133:
  pushl $0
80105747:	6a 00                	push   $0x0
  pushl $133
80105749:	68 85 00 00 00       	push   $0x85
  jmp alltraps
8010574e:	e9 0d f7 ff ff       	jmp    80104e60 <alltraps>

80105753 <vector134>:
.globl vector134
vector134:
  pushl $0
80105753:	6a 00                	push   $0x0
  pushl $134
80105755:	68 86 00 00 00       	push   $0x86
  jmp alltraps
8010575a:	e9 01 f7 ff ff       	jmp    80104e60 <alltraps>

8010575f <vector135>:
.globl vector135
vector135:
  pushl $0
8010575f:	6a 00                	push   $0x0
  pushl $135
80105761:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80105766:	e9 f5 f6 ff ff       	jmp    80104e60 <alltraps>

8010576b <vector136>:
.globl vector136
vector136:
  pushl $0
8010576b:	6a 00                	push   $0x0
  pushl $136
8010576d:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80105772:	e9 e9 f6 ff ff       	jmp    80104e60 <alltraps>

80105777 <vector137>:
.globl vector137
vector137:
  pushl $0
80105777:	6a 00                	push   $0x0
  pushl $137
80105779:	68 89 00 00 00       	push   $0x89
  jmp alltraps
8010577e:	e9 dd f6 ff ff       	jmp    80104e60 <alltraps>

80105783 <vector138>:
.globl vector138
vector138:
  pushl $0
80105783:	6a 00                	push   $0x0
  pushl $138
80105785:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
8010578a:	e9 d1 f6 ff ff       	jmp    80104e60 <alltraps>

8010578f <vector139>:
.globl vector139
vector139:
  pushl $0
8010578f:	6a 00                	push   $0x0
  pushl $139
80105791:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80105796:	e9 c5 f6 ff ff       	jmp    80104e60 <alltraps>

8010579b <vector140>:
.globl vector140
vector140:
  pushl $0
8010579b:	6a 00                	push   $0x0
  pushl $140
8010579d:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
801057a2:	e9 b9 f6 ff ff       	jmp    80104e60 <alltraps>

801057a7 <vector141>:
.globl vector141
vector141:
  pushl $0
801057a7:	6a 00                	push   $0x0
  pushl $141
801057a9:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
801057ae:	e9 ad f6 ff ff       	jmp    80104e60 <alltraps>

801057b3 <vector142>:
.globl vector142
vector142:
  pushl $0
801057b3:	6a 00                	push   $0x0
  pushl $142
801057b5:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
801057ba:	e9 a1 f6 ff ff       	jmp    80104e60 <alltraps>

801057bf <vector143>:
.globl vector143
vector143:
  pushl $0
801057bf:	6a 00                	push   $0x0
  pushl $143
801057c1:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
801057c6:	e9 95 f6 ff ff       	jmp    80104e60 <alltraps>

801057cb <vector144>:
.globl vector144
vector144:
  pushl $0
801057cb:	6a 00                	push   $0x0
  pushl $144
801057cd:	68 90 00 00 00       	push   $0x90
  jmp alltraps
801057d2:	e9 89 f6 ff ff       	jmp    80104e60 <alltraps>

801057d7 <vector145>:
.globl vector145
vector145:
  pushl $0
801057d7:	6a 00                	push   $0x0
  pushl $145
801057d9:	68 91 00 00 00       	push   $0x91
  jmp alltraps
801057de:	e9 7d f6 ff ff       	jmp    80104e60 <alltraps>

801057e3 <vector146>:
.globl vector146
vector146:
  pushl $0
801057e3:	6a 00                	push   $0x0
  pushl $146
801057e5:	68 92 00 00 00       	push   $0x92
  jmp alltraps
801057ea:	e9 71 f6 ff ff       	jmp    80104e60 <alltraps>

801057ef <vector147>:
.globl vector147
vector147:
  pushl $0
801057ef:	6a 00                	push   $0x0
  pushl $147
801057f1:	68 93 00 00 00       	push   $0x93
  jmp alltraps
801057f6:	e9 65 f6 ff ff       	jmp    80104e60 <alltraps>

801057fb <vector148>:
.globl vector148
vector148:
  pushl $0
801057fb:	6a 00                	push   $0x0
  pushl $148
801057fd:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80105802:	e9 59 f6 ff ff       	jmp    80104e60 <alltraps>

80105807 <vector149>:
.globl vector149
vector149:
  pushl $0
80105807:	6a 00                	push   $0x0
  pushl $149
80105809:	68 95 00 00 00       	push   $0x95
  jmp alltraps
8010580e:	e9 4d f6 ff ff       	jmp    80104e60 <alltraps>

80105813 <vector150>:
.globl vector150
vector150:
  pushl $0
80105813:	6a 00                	push   $0x0
  pushl $150
80105815:	68 96 00 00 00       	push   $0x96
  jmp alltraps
8010581a:	e9 41 f6 ff ff       	jmp    80104e60 <alltraps>

8010581f <vector151>:
.globl vector151
vector151:
  pushl $0
8010581f:	6a 00                	push   $0x0
  pushl $151
80105821:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80105826:	e9 35 f6 ff ff       	jmp    80104e60 <alltraps>

8010582b <vector152>:
.globl vector152
vector152:
  pushl $0
8010582b:	6a 00                	push   $0x0
  pushl $152
8010582d:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80105832:	e9 29 f6 ff ff       	jmp    80104e60 <alltraps>

80105837 <vector153>:
.globl vector153
vector153:
  pushl $0
80105837:	6a 00                	push   $0x0
  pushl $153
80105839:	68 99 00 00 00       	push   $0x99
  jmp alltraps
8010583e:	e9 1d f6 ff ff       	jmp    80104e60 <alltraps>

80105843 <vector154>:
.globl vector154
vector154:
  pushl $0
80105843:	6a 00                	push   $0x0
  pushl $154
80105845:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
8010584a:	e9 11 f6 ff ff       	jmp    80104e60 <alltraps>

8010584f <vector155>:
.globl vector155
vector155:
  pushl $0
8010584f:	6a 00                	push   $0x0
  pushl $155
80105851:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80105856:	e9 05 f6 ff ff       	jmp    80104e60 <alltraps>

8010585b <vector156>:
.globl vector156
vector156:
  pushl $0
8010585b:	6a 00                	push   $0x0
  pushl $156
8010585d:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80105862:	e9 f9 f5 ff ff       	jmp    80104e60 <alltraps>

80105867 <vector157>:
.globl vector157
vector157:
  pushl $0
80105867:	6a 00                	push   $0x0
  pushl $157
80105869:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
8010586e:	e9 ed f5 ff ff       	jmp    80104e60 <alltraps>

80105873 <vector158>:
.globl vector158
vector158:
  pushl $0
80105873:	6a 00                	push   $0x0
  pushl $158
80105875:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
8010587a:	e9 e1 f5 ff ff       	jmp    80104e60 <alltraps>

8010587f <vector159>:
.globl vector159
vector159:
  pushl $0
8010587f:	6a 00                	push   $0x0
  pushl $159
80105881:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80105886:	e9 d5 f5 ff ff       	jmp    80104e60 <alltraps>

8010588b <vector160>:
.globl vector160
vector160:
  pushl $0
8010588b:	6a 00                	push   $0x0
  pushl $160
8010588d:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80105892:	e9 c9 f5 ff ff       	jmp    80104e60 <alltraps>

80105897 <vector161>:
.globl vector161
vector161:
  pushl $0
80105897:	6a 00                	push   $0x0
  pushl $161
80105899:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
8010589e:	e9 bd f5 ff ff       	jmp    80104e60 <alltraps>

801058a3 <vector162>:
.globl vector162
vector162:
  pushl $0
801058a3:	6a 00                	push   $0x0
  pushl $162
801058a5:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
801058aa:	e9 b1 f5 ff ff       	jmp    80104e60 <alltraps>

801058af <vector163>:
.globl vector163
vector163:
  pushl $0
801058af:	6a 00                	push   $0x0
  pushl $163
801058b1:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
801058b6:	e9 a5 f5 ff ff       	jmp    80104e60 <alltraps>

801058bb <vector164>:
.globl vector164
vector164:
  pushl $0
801058bb:	6a 00                	push   $0x0
  pushl $164
801058bd:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
801058c2:	e9 99 f5 ff ff       	jmp    80104e60 <alltraps>

801058c7 <vector165>:
.globl vector165
vector165:
  pushl $0
801058c7:	6a 00                	push   $0x0
  pushl $165
801058c9:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
801058ce:	e9 8d f5 ff ff       	jmp    80104e60 <alltraps>

801058d3 <vector166>:
.globl vector166
vector166:
  pushl $0
801058d3:	6a 00                	push   $0x0
  pushl $166
801058d5:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
801058da:	e9 81 f5 ff ff       	jmp    80104e60 <alltraps>

801058df <vector167>:
.globl vector167
vector167:
  pushl $0
801058df:	6a 00                	push   $0x0
  pushl $167
801058e1:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
801058e6:	e9 75 f5 ff ff       	jmp    80104e60 <alltraps>

801058eb <vector168>:
.globl vector168
vector168:
  pushl $0
801058eb:	6a 00                	push   $0x0
  pushl $168
801058ed:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
801058f2:	e9 69 f5 ff ff       	jmp    80104e60 <alltraps>

801058f7 <vector169>:
.globl vector169
vector169:
  pushl $0
801058f7:	6a 00                	push   $0x0
  pushl $169
801058f9:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
801058fe:	e9 5d f5 ff ff       	jmp    80104e60 <alltraps>

80105903 <vector170>:
.globl vector170
vector170:
  pushl $0
80105903:	6a 00                	push   $0x0
  pushl $170
80105905:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
8010590a:	e9 51 f5 ff ff       	jmp    80104e60 <alltraps>

8010590f <vector171>:
.globl vector171
vector171:
  pushl $0
8010590f:	6a 00                	push   $0x0
  pushl $171
80105911:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80105916:	e9 45 f5 ff ff       	jmp    80104e60 <alltraps>

8010591b <vector172>:
.globl vector172
vector172:
  pushl $0
8010591b:	6a 00                	push   $0x0
  pushl $172
8010591d:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80105922:	e9 39 f5 ff ff       	jmp    80104e60 <alltraps>

80105927 <vector173>:
.globl vector173
vector173:
  pushl $0
80105927:	6a 00                	push   $0x0
  pushl $173
80105929:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
8010592e:	e9 2d f5 ff ff       	jmp    80104e60 <alltraps>

80105933 <vector174>:
.globl vector174
vector174:
  pushl $0
80105933:	6a 00                	push   $0x0
  pushl $174
80105935:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
8010593a:	e9 21 f5 ff ff       	jmp    80104e60 <alltraps>

8010593f <vector175>:
.globl vector175
vector175:
  pushl $0
8010593f:	6a 00                	push   $0x0
  pushl $175
80105941:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80105946:	e9 15 f5 ff ff       	jmp    80104e60 <alltraps>

8010594b <vector176>:
.globl vector176
vector176:
  pushl $0
8010594b:	6a 00                	push   $0x0
  pushl $176
8010594d:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80105952:	e9 09 f5 ff ff       	jmp    80104e60 <alltraps>

80105957 <vector177>:
.globl vector177
vector177:
  pushl $0
80105957:	6a 00                	push   $0x0
  pushl $177
80105959:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
8010595e:	e9 fd f4 ff ff       	jmp    80104e60 <alltraps>

80105963 <vector178>:
.globl vector178
vector178:
  pushl $0
80105963:	6a 00                	push   $0x0
  pushl $178
80105965:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
8010596a:	e9 f1 f4 ff ff       	jmp    80104e60 <alltraps>

8010596f <vector179>:
.globl vector179
vector179:
  pushl $0
8010596f:	6a 00                	push   $0x0
  pushl $179
80105971:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80105976:	e9 e5 f4 ff ff       	jmp    80104e60 <alltraps>

8010597b <vector180>:
.globl vector180
vector180:
  pushl $0
8010597b:	6a 00                	push   $0x0
  pushl $180
8010597d:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80105982:	e9 d9 f4 ff ff       	jmp    80104e60 <alltraps>

80105987 <vector181>:
.globl vector181
vector181:
  pushl $0
80105987:	6a 00                	push   $0x0
  pushl $181
80105989:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
8010598e:	e9 cd f4 ff ff       	jmp    80104e60 <alltraps>

80105993 <vector182>:
.globl vector182
vector182:
  pushl $0
80105993:	6a 00                	push   $0x0
  pushl $182
80105995:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
8010599a:	e9 c1 f4 ff ff       	jmp    80104e60 <alltraps>

8010599f <vector183>:
.globl vector183
vector183:
  pushl $0
8010599f:	6a 00                	push   $0x0
  pushl $183
801059a1:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
801059a6:	e9 b5 f4 ff ff       	jmp    80104e60 <alltraps>

801059ab <vector184>:
.globl vector184
vector184:
  pushl $0
801059ab:	6a 00                	push   $0x0
  pushl $184
801059ad:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
801059b2:	e9 a9 f4 ff ff       	jmp    80104e60 <alltraps>

801059b7 <vector185>:
.globl vector185
vector185:
  pushl $0
801059b7:	6a 00                	push   $0x0
  pushl $185
801059b9:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
801059be:	e9 9d f4 ff ff       	jmp    80104e60 <alltraps>

801059c3 <vector186>:
.globl vector186
vector186:
  pushl $0
801059c3:	6a 00                	push   $0x0
  pushl $186
801059c5:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
801059ca:	e9 91 f4 ff ff       	jmp    80104e60 <alltraps>

801059cf <vector187>:
.globl vector187
vector187:
  pushl $0
801059cf:	6a 00                	push   $0x0
  pushl $187
801059d1:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
801059d6:	e9 85 f4 ff ff       	jmp    80104e60 <alltraps>

801059db <vector188>:
.globl vector188
vector188:
  pushl $0
801059db:	6a 00                	push   $0x0
  pushl $188
801059dd:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
801059e2:	e9 79 f4 ff ff       	jmp    80104e60 <alltraps>

801059e7 <vector189>:
.globl vector189
vector189:
  pushl $0
801059e7:	6a 00                	push   $0x0
  pushl $189
801059e9:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
801059ee:	e9 6d f4 ff ff       	jmp    80104e60 <alltraps>

801059f3 <vector190>:
.globl vector190
vector190:
  pushl $0
801059f3:	6a 00                	push   $0x0
  pushl $190
801059f5:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
801059fa:	e9 61 f4 ff ff       	jmp    80104e60 <alltraps>

801059ff <vector191>:
.globl vector191
vector191:
  pushl $0
801059ff:	6a 00                	push   $0x0
  pushl $191
80105a01:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80105a06:	e9 55 f4 ff ff       	jmp    80104e60 <alltraps>

80105a0b <vector192>:
.globl vector192
vector192:
  pushl $0
80105a0b:	6a 00                	push   $0x0
  pushl $192
80105a0d:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80105a12:	e9 49 f4 ff ff       	jmp    80104e60 <alltraps>

80105a17 <vector193>:
.globl vector193
vector193:
  pushl $0
80105a17:	6a 00                	push   $0x0
  pushl $193
80105a19:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80105a1e:	e9 3d f4 ff ff       	jmp    80104e60 <alltraps>

80105a23 <vector194>:
.globl vector194
vector194:
  pushl $0
80105a23:	6a 00                	push   $0x0
  pushl $194
80105a25:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80105a2a:	e9 31 f4 ff ff       	jmp    80104e60 <alltraps>

80105a2f <vector195>:
.globl vector195
vector195:
  pushl $0
80105a2f:	6a 00                	push   $0x0
  pushl $195
80105a31:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80105a36:	e9 25 f4 ff ff       	jmp    80104e60 <alltraps>

80105a3b <vector196>:
.globl vector196
vector196:
  pushl $0
80105a3b:	6a 00                	push   $0x0
  pushl $196
80105a3d:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80105a42:	e9 19 f4 ff ff       	jmp    80104e60 <alltraps>

80105a47 <vector197>:
.globl vector197
vector197:
  pushl $0
80105a47:	6a 00                	push   $0x0
  pushl $197
80105a49:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80105a4e:	e9 0d f4 ff ff       	jmp    80104e60 <alltraps>

80105a53 <vector198>:
.globl vector198
vector198:
  pushl $0
80105a53:	6a 00                	push   $0x0
  pushl $198
80105a55:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80105a5a:	e9 01 f4 ff ff       	jmp    80104e60 <alltraps>

80105a5f <vector199>:
.globl vector199
vector199:
  pushl $0
80105a5f:	6a 00                	push   $0x0
  pushl $199
80105a61:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80105a66:	e9 f5 f3 ff ff       	jmp    80104e60 <alltraps>

80105a6b <vector200>:
.globl vector200
vector200:
  pushl $0
80105a6b:	6a 00                	push   $0x0
  pushl $200
80105a6d:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80105a72:	e9 e9 f3 ff ff       	jmp    80104e60 <alltraps>

80105a77 <vector201>:
.globl vector201
vector201:
  pushl $0
80105a77:	6a 00                	push   $0x0
  pushl $201
80105a79:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80105a7e:	e9 dd f3 ff ff       	jmp    80104e60 <alltraps>

80105a83 <vector202>:
.globl vector202
vector202:
  pushl $0
80105a83:	6a 00                	push   $0x0
  pushl $202
80105a85:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80105a8a:	e9 d1 f3 ff ff       	jmp    80104e60 <alltraps>

80105a8f <vector203>:
.globl vector203
vector203:
  pushl $0
80105a8f:	6a 00                	push   $0x0
  pushl $203
80105a91:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80105a96:	e9 c5 f3 ff ff       	jmp    80104e60 <alltraps>

80105a9b <vector204>:
.globl vector204
vector204:
  pushl $0
80105a9b:	6a 00                	push   $0x0
  pushl $204
80105a9d:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80105aa2:	e9 b9 f3 ff ff       	jmp    80104e60 <alltraps>

80105aa7 <vector205>:
.globl vector205
vector205:
  pushl $0
80105aa7:	6a 00                	push   $0x0
  pushl $205
80105aa9:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80105aae:	e9 ad f3 ff ff       	jmp    80104e60 <alltraps>

80105ab3 <vector206>:
.globl vector206
vector206:
  pushl $0
80105ab3:	6a 00                	push   $0x0
  pushl $206
80105ab5:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80105aba:	e9 a1 f3 ff ff       	jmp    80104e60 <alltraps>

80105abf <vector207>:
.globl vector207
vector207:
  pushl $0
80105abf:	6a 00                	push   $0x0
  pushl $207
80105ac1:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80105ac6:	e9 95 f3 ff ff       	jmp    80104e60 <alltraps>

80105acb <vector208>:
.globl vector208
vector208:
  pushl $0
80105acb:	6a 00                	push   $0x0
  pushl $208
80105acd:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80105ad2:	e9 89 f3 ff ff       	jmp    80104e60 <alltraps>

80105ad7 <vector209>:
.globl vector209
vector209:
  pushl $0
80105ad7:	6a 00                	push   $0x0
  pushl $209
80105ad9:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80105ade:	e9 7d f3 ff ff       	jmp    80104e60 <alltraps>

80105ae3 <vector210>:
.globl vector210
vector210:
  pushl $0
80105ae3:	6a 00                	push   $0x0
  pushl $210
80105ae5:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80105aea:	e9 71 f3 ff ff       	jmp    80104e60 <alltraps>

80105aef <vector211>:
.globl vector211
vector211:
  pushl $0
80105aef:	6a 00                	push   $0x0
  pushl $211
80105af1:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80105af6:	e9 65 f3 ff ff       	jmp    80104e60 <alltraps>

80105afb <vector212>:
.globl vector212
vector212:
  pushl $0
80105afb:	6a 00                	push   $0x0
  pushl $212
80105afd:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80105b02:	e9 59 f3 ff ff       	jmp    80104e60 <alltraps>

80105b07 <vector213>:
.globl vector213
vector213:
  pushl $0
80105b07:	6a 00                	push   $0x0
  pushl $213
80105b09:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80105b0e:	e9 4d f3 ff ff       	jmp    80104e60 <alltraps>

80105b13 <vector214>:
.globl vector214
vector214:
  pushl $0
80105b13:	6a 00                	push   $0x0
  pushl $214
80105b15:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80105b1a:	e9 41 f3 ff ff       	jmp    80104e60 <alltraps>

80105b1f <vector215>:
.globl vector215
vector215:
  pushl $0
80105b1f:	6a 00                	push   $0x0
  pushl $215
80105b21:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80105b26:	e9 35 f3 ff ff       	jmp    80104e60 <alltraps>

80105b2b <vector216>:
.globl vector216
vector216:
  pushl $0
80105b2b:	6a 00                	push   $0x0
  pushl $216
80105b2d:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80105b32:	e9 29 f3 ff ff       	jmp    80104e60 <alltraps>

80105b37 <vector217>:
.globl vector217
vector217:
  pushl $0
80105b37:	6a 00                	push   $0x0
  pushl $217
80105b39:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80105b3e:	e9 1d f3 ff ff       	jmp    80104e60 <alltraps>

80105b43 <vector218>:
.globl vector218
vector218:
  pushl $0
80105b43:	6a 00                	push   $0x0
  pushl $218
80105b45:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80105b4a:	e9 11 f3 ff ff       	jmp    80104e60 <alltraps>

80105b4f <vector219>:
.globl vector219
vector219:
  pushl $0
80105b4f:	6a 00                	push   $0x0
  pushl $219
80105b51:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80105b56:	e9 05 f3 ff ff       	jmp    80104e60 <alltraps>

80105b5b <vector220>:
.globl vector220
vector220:
  pushl $0
80105b5b:	6a 00                	push   $0x0
  pushl $220
80105b5d:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80105b62:	e9 f9 f2 ff ff       	jmp    80104e60 <alltraps>

80105b67 <vector221>:
.globl vector221
vector221:
  pushl $0
80105b67:	6a 00                	push   $0x0
  pushl $221
80105b69:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80105b6e:	e9 ed f2 ff ff       	jmp    80104e60 <alltraps>

80105b73 <vector222>:
.globl vector222
vector222:
  pushl $0
80105b73:	6a 00                	push   $0x0
  pushl $222
80105b75:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80105b7a:	e9 e1 f2 ff ff       	jmp    80104e60 <alltraps>

80105b7f <vector223>:
.globl vector223
vector223:
  pushl $0
80105b7f:	6a 00                	push   $0x0
  pushl $223
80105b81:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80105b86:	e9 d5 f2 ff ff       	jmp    80104e60 <alltraps>

80105b8b <vector224>:
.globl vector224
vector224:
  pushl $0
80105b8b:	6a 00                	push   $0x0
  pushl $224
80105b8d:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80105b92:	e9 c9 f2 ff ff       	jmp    80104e60 <alltraps>

80105b97 <vector225>:
.globl vector225
vector225:
  pushl $0
80105b97:	6a 00                	push   $0x0
  pushl $225
80105b99:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80105b9e:	e9 bd f2 ff ff       	jmp    80104e60 <alltraps>

80105ba3 <vector226>:
.globl vector226
vector226:
  pushl $0
80105ba3:	6a 00                	push   $0x0
  pushl $226
80105ba5:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80105baa:	e9 b1 f2 ff ff       	jmp    80104e60 <alltraps>

80105baf <vector227>:
.globl vector227
vector227:
  pushl $0
80105baf:	6a 00                	push   $0x0
  pushl $227
80105bb1:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80105bb6:	e9 a5 f2 ff ff       	jmp    80104e60 <alltraps>

80105bbb <vector228>:
.globl vector228
vector228:
  pushl $0
80105bbb:	6a 00                	push   $0x0
  pushl $228
80105bbd:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80105bc2:	e9 99 f2 ff ff       	jmp    80104e60 <alltraps>

80105bc7 <vector229>:
.globl vector229
vector229:
  pushl $0
80105bc7:	6a 00                	push   $0x0
  pushl $229
80105bc9:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80105bce:	e9 8d f2 ff ff       	jmp    80104e60 <alltraps>

80105bd3 <vector230>:
.globl vector230
vector230:
  pushl $0
80105bd3:	6a 00                	push   $0x0
  pushl $230
80105bd5:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80105bda:	e9 81 f2 ff ff       	jmp    80104e60 <alltraps>

80105bdf <vector231>:
.globl vector231
vector231:
  pushl $0
80105bdf:	6a 00                	push   $0x0
  pushl $231
80105be1:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80105be6:	e9 75 f2 ff ff       	jmp    80104e60 <alltraps>

80105beb <vector232>:
.globl vector232
vector232:
  pushl $0
80105beb:	6a 00                	push   $0x0
  pushl $232
80105bed:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80105bf2:	e9 69 f2 ff ff       	jmp    80104e60 <alltraps>

80105bf7 <vector233>:
.globl vector233
vector233:
  pushl $0
80105bf7:	6a 00                	push   $0x0
  pushl $233
80105bf9:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80105bfe:	e9 5d f2 ff ff       	jmp    80104e60 <alltraps>

80105c03 <vector234>:
.globl vector234
vector234:
  pushl $0
80105c03:	6a 00                	push   $0x0
  pushl $234
80105c05:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80105c0a:	e9 51 f2 ff ff       	jmp    80104e60 <alltraps>

80105c0f <vector235>:
.globl vector235
vector235:
  pushl $0
80105c0f:	6a 00                	push   $0x0
  pushl $235
80105c11:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80105c16:	e9 45 f2 ff ff       	jmp    80104e60 <alltraps>

80105c1b <vector236>:
.globl vector236
vector236:
  pushl $0
80105c1b:	6a 00                	push   $0x0
  pushl $236
80105c1d:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80105c22:	e9 39 f2 ff ff       	jmp    80104e60 <alltraps>

80105c27 <vector237>:
.globl vector237
vector237:
  pushl $0
80105c27:	6a 00                	push   $0x0
  pushl $237
80105c29:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80105c2e:	e9 2d f2 ff ff       	jmp    80104e60 <alltraps>

80105c33 <vector238>:
.globl vector238
vector238:
  pushl $0
80105c33:	6a 00                	push   $0x0
  pushl $238
80105c35:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80105c3a:	e9 21 f2 ff ff       	jmp    80104e60 <alltraps>

80105c3f <vector239>:
.globl vector239
vector239:
  pushl $0
80105c3f:	6a 00                	push   $0x0
  pushl $239
80105c41:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80105c46:	e9 15 f2 ff ff       	jmp    80104e60 <alltraps>

80105c4b <vector240>:
.globl vector240
vector240:
  pushl $0
80105c4b:	6a 00                	push   $0x0
  pushl $240
80105c4d:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80105c52:	e9 09 f2 ff ff       	jmp    80104e60 <alltraps>

80105c57 <vector241>:
.globl vector241
vector241:
  pushl $0
80105c57:	6a 00                	push   $0x0
  pushl $241
80105c59:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80105c5e:	e9 fd f1 ff ff       	jmp    80104e60 <alltraps>

80105c63 <vector242>:
.globl vector242
vector242:
  pushl $0
80105c63:	6a 00                	push   $0x0
  pushl $242
80105c65:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80105c6a:	e9 f1 f1 ff ff       	jmp    80104e60 <alltraps>

80105c6f <vector243>:
.globl vector243
vector243:
  pushl $0
80105c6f:	6a 00                	push   $0x0
  pushl $243
80105c71:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80105c76:	e9 e5 f1 ff ff       	jmp    80104e60 <alltraps>

80105c7b <vector244>:
.globl vector244
vector244:
  pushl $0
80105c7b:	6a 00                	push   $0x0
  pushl $244
80105c7d:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80105c82:	e9 d9 f1 ff ff       	jmp    80104e60 <alltraps>

80105c87 <vector245>:
.globl vector245
vector245:
  pushl $0
80105c87:	6a 00                	push   $0x0
  pushl $245
80105c89:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80105c8e:	e9 cd f1 ff ff       	jmp    80104e60 <alltraps>

80105c93 <vector246>:
.globl vector246
vector246:
  pushl $0
80105c93:	6a 00                	push   $0x0
  pushl $246
80105c95:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80105c9a:	e9 c1 f1 ff ff       	jmp    80104e60 <alltraps>

80105c9f <vector247>:
.globl vector247
vector247:
  pushl $0
80105c9f:	6a 00                	push   $0x0
  pushl $247
80105ca1:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80105ca6:	e9 b5 f1 ff ff       	jmp    80104e60 <alltraps>

80105cab <vector248>:
.globl vector248
vector248:
  pushl $0
80105cab:	6a 00                	push   $0x0
  pushl $248
80105cad:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80105cb2:	e9 a9 f1 ff ff       	jmp    80104e60 <alltraps>

80105cb7 <vector249>:
.globl vector249
vector249:
  pushl $0
80105cb7:	6a 00                	push   $0x0
  pushl $249
80105cb9:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80105cbe:	e9 9d f1 ff ff       	jmp    80104e60 <alltraps>

80105cc3 <vector250>:
.globl vector250
vector250:
  pushl $0
80105cc3:	6a 00                	push   $0x0
  pushl $250
80105cc5:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80105cca:	e9 91 f1 ff ff       	jmp    80104e60 <alltraps>

80105ccf <vector251>:
.globl vector251
vector251:
  pushl $0
80105ccf:	6a 00                	push   $0x0
  pushl $251
80105cd1:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80105cd6:	e9 85 f1 ff ff       	jmp    80104e60 <alltraps>

80105cdb <vector252>:
.globl vector252
vector252:
  pushl $0
80105cdb:	6a 00                	push   $0x0
  pushl $252
80105cdd:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80105ce2:	e9 79 f1 ff ff       	jmp    80104e60 <alltraps>

80105ce7 <vector253>:
.globl vector253
vector253:
  pushl $0
80105ce7:	6a 00                	push   $0x0
  pushl $253
80105ce9:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80105cee:	e9 6d f1 ff ff       	jmp    80104e60 <alltraps>

80105cf3 <vector254>:
.globl vector254
vector254:
  pushl $0
80105cf3:	6a 00                	push   $0x0
  pushl $254
80105cf5:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80105cfa:	e9 61 f1 ff ff       	jmp    80104e60 <alltraps>

80105cff <vector255>:
.globl vector255
vector255:
  pushl $0
80105cff:	6a 00                	push   $0x0
  pushl $255
80105d01:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80105d06:	e9 55 f1 ff ff       	jmp    80104e60 <alltraps>

80105d0b <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80105d0b:	55                   	push   %ebp
80105d0c:	89 e5                	mov    %esp,%ebp
80105d0e:	57                   	push   %edi
80105d0f:	56                   	push   %esi
80105d10:	53                   	push   %ebx
80105d11:	83 ec 0c             	sub    $0xc,%esp
80105d14:	89 d6                	mov    %edx,%esi
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80105d16:	c1 ea 16             	shr    $0x16,%edx
80105d19:	8d 3c 90             	lea    (%eax,%edx,4),%edi
  if(*pde & PTE_P){
80105d1c:	8b 1f                	mov    (%edi),%ebx
80105d1e:	f6 c3 01             	test   $0x1,%bl
80105d21:	74 22                	je     80105d45 <walkpgdir+0x3a>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
80105d23:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
80105d29:	81 c3 00 00 00 80    	add    $0x80000000,%ebx
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
80105d2f:	c1 ee 0c             	shr    $0xc,%esi
80105d32:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
80105d38:	8d 1c b3             	lea    (%ebx,%esi,4),%ebx
}
80105d3b:	89 d8                	mov    %ebx,%eax
80105d3d:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105d40:	5b                   	pop    %ebx
80105d41:	5e                   	pop    %esi
80105d42:	5f                   	pop    %edi
80105d43:	5d                   	pop    %ebp
80105d44:	c3                   	ret    
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80105d45:	85 c9                	test   %ecx,%ecx
80105d47:	74 2b                	je     80105d74 <walkpgdir+0x69>
80105d49:	e8 9e c3 ff ff       	call   801020ec <kalloc>
80105d4e:	89 c3                	mov    %eax,%ebx
80105d50:	85 c0                	test   %eax,%eax
80105d52:	74 e7                	je     80105d3b <walkpgdir+0x30>
    memset(pgtab, 0, PGSIZE);
80105d54:	83 ec 04             	sub    $0x4,%esp
80105d57:	68 00 10 00 00       	push   $0x1000
80105d5c:	6a 00                	push   $0x0
80105d5e:	50                   	push   %eax
80105d5f:	e8 f4 df ff ff       	call   80103d58 <memset>
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
80105d64:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80105d6a:	83 c8 07             	or     $0x7,%eax
80105d6d:	89 07                	mov    %eax,(%edi)
80105d6f:	83 c4 10             	add    $0x10,%esp
80105d72:	eb bb                	jmp    80105d2f <walkpgdir+0x24>
      return 0;
80105d74:	bb 00 00 00 00       	mov    $0x0,%ebx
80105d79:	eb c0                	jmp    80105d3b <walkpgdir+0x30>

80105d7b <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80105d7b:	55                   	push   %ebp
80105d7c:	89 e5                	mov    %esp,%ebp
80105d7e:	57                   	push   %edi
80105d7f:	56                   	push   %esi
80105d80:	53                   	push   %ebx
80105d81:	83 ec 1c             	sub    $0x1c,%esp
80105d84:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105d87:	8b 75 08             	mov    0x8(%ebp),%esi
  char *a, *last;
  pte_t *pte;

  a = (char*)PGROUNDDOWN((uint)va);
80105d8a:	89 d3                	mov    %edx,%ebx
80105d8c:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80105d92:	8d 7c 0a ff          	lea    -0x1(%edx,%ecx,1),%edi
80105d96:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105d9c:	b9 01 00 00 00       	mov    $0x1,%ecx
80105da1:	89 da                	mov    %ebx,%edx
80105da3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105da6:	e8 60 ff ff ff       	call   80105d0b <walkpgdir>
80105dab:	85 c0                	test   %eax,%eax
80105dad:	74 2e                	je     80105ddd <mappages+0x62>
      return -1;
    if(*pte & PTE_P)
80105daf:	f6 00 01             	testb  $0x1,(%eax)
80105db2:	75 1c                	jne    80105dd0 <mappages+0x55>
      panic("remap");
    *pte = pa | perm | PTE_P;
80105db4:	89 f2                	mov    %esi,%edx
80105db6:	0b 55 0c             	or     0xc(%ebp),%edx
80105db9:	83 ca 01             	or     $0x1,%edx
80105dbc:	89 10                	mov    %edx,(%eax)
    if(a == last)
80105dbe:	39 fb                	cmp    %edi,%ebx
80105dc0:	74 28                	je     80105dea <mappages+0x6f>
      break;
    a += PGSIZE;
80105dc2:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pa += PGSIZE;
80105dc8:	81 c6 00 10 00 00    	add    $0x1000,%esi
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105dce:	eb cc                	jmp    80105d9c <mappages+0x21>
      panic("remap");
80105dd0:	83 ec 0c             	sub    $0xc,%esp
80105dd3:	68 8c 6e 10 80       	push   $0x80106e8c
80105dd8:	e8 6b a5 ff ff       	call   80100348 <panic>
      return -1;
80105ddd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  return 0;
}
80105de2:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105de5:	5b                   	pop    %ebx
80105de6:	5e                   	pop    %esi
80105de7:	5f                   	pop    %edi
80105de8:	5d                   	pop    %ebp
80105de9:	c3                   	ret    
  return 0;
80105dea:	b8 00 00 00 00       	mov    $0x0,%eax
80105def:	eb f1                	jmp    80105de2 <mappages+0x67>

80105df1 <seginit>:
{
80105df1:	55                   	push   %ebp
80105df2:	89 e5                	mov    %esp,%ebp
80105df4:	53                   	push   %ebx
80105df5:	83 ec 14             	sub    $0x14,%esp
  c = &cpus[cpuid()];
80105df8:	e8 f5 d4 ff ff       	call   801032f2 <cpuid>
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80105dfd:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
80105e03:	66 c7 80 18 18 19 80 	movw   $0xffff,-0x7fe6e7e8(%eax)
80105e0a:	ff ff 
80105e0c:	66 c7 80 1a 18 19 80 	movw   $0x0,-0x7fe6e7e6(%eax)
80105e13:	00 00 
80105e15:	c6 80 1c 18 19 80 00 	movb   $0x0,-0x7fe6e7e4(%eax)
80105e1c:	0f b6 88 1d 18 19 80 	movzbl -0x7fe6e7e3(%eax),%ecx
80105e23:	83 e1 f0             	and    $0xfffffff0,%ecx
80105e26:	83 c9 1a             	or     $0x1a,%ecx
80105e29:	83 e1 9f             	and    $0xffffff9f,%ecx
80105e2c:	83 c9 80             	or     $0xffffff80,%ecx
80105e2f:	88 88 1d 18 19 80    	mov    %cl,-0x7fe6e7e3(%eax)
80105e35:	0f b6 88 1e 18 19 80 	movzbl -0x7fe6e7e2(%eax),%ecx
80105e3c:	83 c9 0f             	or     $0xf,%ecx
80105e3f:	83 e1 cf             	and    $0xffffffcf,%ecx
80105e42:	83 c9 c0             	or     $0xffffffc0,%ecx
80105e45:	88 88 1e 18 19 80    	mov    %cl,-0x7fe6e7e2(%eax)
80105e4b:	c6 80 1f 18 19 80 00 	movb   $0x0,-0x7fe6e7e1(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80105e52:	66 c7 80 20 18 19 80 	movw   $0xffff,-0x7fe6e7e0(%eax)
80105e59:	ff ff 
80105e5b:	66 c7 80 22 18 19 80 	movw   $0x0,-0x7fe6e7de(%eax)
80105e62:	00 00 
80105e64:	c6 80 24 18 19 80 00 	movb   $0x0,-0x7fe6e7dc(%eax)
80105e6b:	0f b6 88 25 18 19 80 	movzbl -0x7fe6e7db(%eax),%ecx
80105e72:	83 e1 f0             	and    $0xfffffff0,%ecx
80105e75:	83 c9 12             	or     $0x12,%ecx
80105e78:	83 e1 9f             	and    $0xffffff9f,%ecx
80105e7b:	83 c9 80             	or     $0xffffff80,%ecx
80105e7e:	88 88 25 18 19 80    	mov    %cl,-0x7fe6e7db(%eax)
80105e84:	0f b6 88 26 18 19 80 	movzbl -0x7fe6e7da(%eax),%ecx
80105e8b:	83 c9 0f             	or     $0xf,%ecx
80105e8e:	83 e1 cf             	and    $0xffffffcf,%ecx
80105e91:	83 c9 c0             	or     $0xffffffc0,%ecx
80105e94:	88 88 26 18 19 80    	mov    %cl,-0x7fe6e7da(%eax)
80105e9a:	c6 80 27 18 19 80 00 	movb   $0x0,-0x7fe6e7d9(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80105ea1:	66 c7 80 28 18 19 80 	movw   $0xffff,-0x7fe6e7d8(%eax)
80105ea8:	ff ff 
80105eaa:	66 c7 80 2a 18 19 80 	movw   $0x0,-0x7fe6e7d6(%eax)
80105eb1:	00 00 
80105eb3:	c6 80 2c 18 19 80 00 	movb   $0x0,-0x7fe6e7d4(%eax)
80105eba:	c6 80 2d 18 19 80 fa 	movb   $0xfa,-0x7fe6e7d3(%eax)
80105ec1:	0f b6 88 2e 18 19 80 	movzbl -0x7fe6e7d2(%eax),%ecx
80105ec8:	83 c9 0f             	or     $0xf,%ecx
80105ecb:	83 e1 cf             	and    $0xffffffcf,%ecx
80105ece:	83 c9 c0             	or     $0xffffffc0,%ecx
80105ed1:	88 88 2e 18 19 80    	mov    %cl,-0x7fe6e7d2(%eax)
80105ed7:	c6 80 2f 18 19 80 00 	movb   $0x0,-0x7fe6e7d1(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80105ede:	66 c7 80 30 18 19 80 	movw   $0xffff,-0x7fe6e7d0(%eax)
80105ee5:	ff ff 
80105ee7:	66 c7 80 32 18 19 80 	movw   $0x0,-0x7fe6e7ce(%eax)
80105eee:	00 00 
80105ef0:	c6 80 34 18 19 80 00 	movb   $0x0,-0x7fe6e7cc(%eax)
80105ef7:	c6 80 35 18 19 80 f2 	movb   $0xf2,-0x7fe6e7cb(%eax)
80105efe:	0f b6 88 36 18 19 80 	movzbl -0x7fe6e7ca(%eax),%ecx
80105f05:	83 c9 0f             	or     $0xf,%ecx
80105f08:	83 e1 cf             	and    $0xffffffcf,%ecx
80105f0b:	83 c9 c0             	or     $0xffffffc0,%ecx
80105f0e:	88 88 36 18 19 80    	mov    %cl,-0x7fe6e7ca(%eax)
80105f14:	c6 80 37 18 19 80 00 	movb   $0x0,-0x7fe6e7c9(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
80105f1b:	05 10 18 19 80       	add    $0x80191810,%eax
  pd[0] = size-1;
80105f20:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
  pd[1] = (uint)p;
80105f26:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
  pd[2] = (uint)p >> 16;
80105f2a:	c1 e8 10             	shr    $0x10,%eax
80105f2d:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
  asm volatile("lgdt (%0)" : : "r" (pd));
80105f31:	8d 45 f2             	lea    -0xe(%ebp),%eax
80105f34:	0f 01 10             	lgdtl  (%eax)
}
80105f37:	83 c4 14             	add    $0x14,%esp
80105f3a:	5b                   	pop    %ebx
80105f3b:	5d                   	pop    %ebp
80105f3c:	c3                   	ret    

80105f3d <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80105f3d:	55                   	push   %ebp
80105f3e:	89 e5                	mov    %esp,%ebp
  lcr3(V2P(kpgdir));   // switch to the kernel page table
80105f40:	a1 c4 44 19 80       	mov    0x801944c4,%eax
80105f45:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint val)
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
80105f4a:	0f 22 d8             	mov    %eax,%cr3
}
80105f4d:	5d                   	pop    %ebp
80105f4e:	c3                   	ret    

80105f4f <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80105f4f:	55                   	push   %ebp
80105f50:	89 e5                	mov    %esp,%ebp
80105f52:	57                   	push   %edi
80105f53:	56                   	push   %esi
80105f54:	53                   	push   %ebx
80105f55:	83 ec 1c             	sub    $0x1c,%esp
80105f58:	8b 75 08             	mov    0x8(%ebp),%esi
  if(p == 0)
80105f5b:	85 f6                	test   %esi,%esi
80105f5d:	0f 84 dd 00 00 00    	je     80106040 <switchuvm+0xf1>
    panic("switchuvm: no process");
  if(p->kstack == 0)
80105f63:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
80105f67:	0f 84 e0 00 00 00    	je     8010604d <switchuvm+0xfe>
    panic("switchuvm: no kstack");
  if(p->pgdir == 0)
80105f6d:	83 7e 04 00          	cmpl   $0x0,0x4(%esi)
80105f71:	0f 84 e3 00 00 00    	je     8010605a <switchuvm+0x10b>
    panic("switchuvm: no pgdir");

  pushcli();
80105f77:	e8 53 dc ff ff       	call   80103bcf <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
80105f7c:	e8 15 d3 ff ff       	call   80103296 <mycpu>
80105f81:	89 c3                	mov    %eax,%ebx
80105f83:	e8 0e d3 ff ff       	call   80103296 <mycpu>
80105f88:	8d 78 08             	lea    0x8(%eax),%edi
80105f8b:	e8 06 d3 ff ff       	call   80103296 <mycpu>
80105f90:	83 c0 08             	add    $0x8,%eax
80105f93:	c1 e8 10             	shr    $0x10,%eax
80105f96:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105f99:	e8 f8 d2 ff ff       	call   80103296 <mycpu>
80105f9e:	83 c0 08             	add    $0x8,%eax
80105fa1:	c1 e8 18             	shr    $0x18,%eax
80105fa4:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
80105fab:	67 00 
80105fad:	66 89 bb 9a 00 00 00 	mov    %di,0x9a(%ebx)
80105fb4:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
80105fb8:	88 8b 9c 00 00 00    	mov    %cl,0x9c(%ebx)
80105fbe:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
80105fc5:	83 e2 f0             	and    $0xfffffff0,%edx
80105fc8:	83 ca 19             	or     $0x19,%edx
80105fcb:	83 e2 9f             	and    $0xffffff9f,%edx
80105fce:	83 ca 80             	or     $0xffffff80,%edx
80105fd1:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
80105fd7:	c6 83 9e 00 00 00 40 	movb   $0x40,0x9e(%ebx)
80105fde:	88 83 9f 00 00 00    	mov    %al,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
80105fe4:	e8 ad d2 ff ff       	call   80103296 <mycpu>
80105fe9:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80105ff0:	83 e2 ef             	and    $0xffffffef,%edx
80105ff3:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
80105ff9:	e8 98 d2 ff ff       	call   80103296 <mycpu>
80105ffe:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
80106004:	8b 5e 08             	mov    0x8(%esi),%ebx
80106007:	e8 8a d2 ff ff       	call   80103296 <mycpu>
8010600c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106012:	89 58 0c             	mov    %ebx,0xc(%eax)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
80106015:	e8 7c d2 ff ff       	call   80103296 <mycpu>
8010601a:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  asm volatile("ltr %0" : : "r" (sel));
80106020:	b8 28 00 00 00       	mov    $0x28,%eax
80106025:	0f 00 d8             	ltr    %ax
  ltr(SEG_TSS << 3);
  lcr3(V2P(p->pgdir));  // switch to process's address space
80106028:	8b 46 04             	mov    0x4(%esi),%eax
8010602b:	05 00 00 00 80       	add    $0x80000000,%eax
  asm volatile("movl %0,%%cr3" : : "r" (val));
80106030:	0f 22 d8             	mov    %eax,%cr3
  popcli();
80106033:	e8 d4 db ff ff       	call   80103c0c <popcli>
}
80106038:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010603b:	5b                   	pop    %ebx
8010603c:	5e                   	pop    %esi
8010603d:	5f                   	pop    %edi
8010603e:	5d                   	pop    %ebp
8010603f:	c3                   	ret    
    panic("switchuvm: no process");
80106040:	83 ec 0c             	sub    $0xc,%esp
80106043:	68 92 6e 10 80       	push   $0x80106e92
80106048:	e8 fb a2 ff ff       	call   80100348 <panic>
    panic("switchuvm: no kstack");
8010604d:	83 ec 0c             	sub    $0xc,%esp
80106050:	68 a8 6e 10 80       	push   $0x80106ea8
80106055:	e8 ee a2 ff ff       	call   80100348 <panic>
    panic("switchuvm: no pgdir");
8010605a:	83 ec 0c             	sub    $0xc,%esp
8010605d:	68 bd 6e 10 80       	push   $0x80106ebd
80106062:	e8 e1 a2 ff ff       	call   80100348 <panic>

80106067 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80106067:	55                   	push   %ebp
80106068:	89 e5                	mov    %esp,%ebp
8010606a:	56                   	push   %esi
8010606b:	53                   	push   %ebx
8010606c:	8b 75 10             	mov    0x10(%ebp),%esi
  char *mem;

  if(sz >= PGSIZE)
8010606f:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
80106075:	77 4c                	ja     801060c3 <inituvm+0x5c>
    panic("inituvm: more than a page");
  mem = kalloc();
80106077:	e8 70 c0 ff ff       	call   801020ec <kalloc>
8010607c:	89 c3                	mov    %eax,%ebx
  memset(mem, 0, PGSIZE);
8010607e:	83 ec 04             	sub    $0x4,%esp
80106081:	68 00 10 00 00       	push   $0x1000
80106086:	6a 00                	push   $0x0
80106088:	50                   	push   %eax
80106089:	e8 ca dc ff ff       	call   80103d58 <memset>
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
8010608e:	83 c4 08             	add    $0x8,%esp
80106091:	6a 06                	push   $0x6
80106093:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80106099:	50                   	push   %eax
8010609a:	b9 00 10 00 00       	mov    $0x1000,%ecx
8010609f:	ba 00 00 00 00       	mov    $0x0,%edx
801060a4:	8b 45 08             	mov    0x8(%ebp),%eax
801060a7:	e8 cf fc ff ff       	call   80105d7b <mappages>
  memmove(mem, init, sz);
801060ac:	83 c4 0c             	add    $0xc,%esp
801060af:	56                   	push   %esi
801060b0:	ff 75 0c             	pushl  0xc(%ebp)
801060b3:	53                   	push   %ebx
801060b4:	e8 1a dd ff ff       	call   80103dd3 <memmove>
}
801060b9:	83 c4 10             	add    $0x10,%esp
801060bc:	8d 65 f8             	lea    -0x8(%ebp),%esp
801060bf:	5b                   	pop    %ebx
801060c0:	5e                   	pop    %esi
801060c1:	5d                   	pop    %ebp
801060c2:	c3                   	ret    
    panic("inituvm: more than a page");
801060c3:	83 ec 0c             	sub    $0xc,%esp
801060c6:	68 d1 6e 10 80       	push   $0x80106ed1
801060cb:	e8 78 a2 ff ff       	call   80100348 <panic>

801060d0 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
801060d0:	55                   	push   %ebp
801060d1:	89 e5                	mov    %esp,%ebp
801060d3:	57                   	push   %edi
801060d4:	56                   	push   %esi
801060d5:	53                   	push   %ebx
801060d6:	83 ec 0c             	sub    $0xc,%esp
801060d9:	8b 7d 18             	mov    0x18(%ebp),%edi
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
801060dc:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
801060e3:	75 07                	jne    801060ec <loaduvm+0x1c>
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
801060e5:	bb 00 00 00 00       	mov    $0x0,%ebx
801060ea:	eb 3c                	jmp    80106128 <loaduvm+0x58>
    panic("loaduvm: addr must be page aligned");
801060ec:	83 ec 0c             	sub    $0xc,%esp
801060ef:	68 8c 6f 10 80       	push   $0x80106f8c
801060f4:	e8 4f a2 ff ff       	call   80100348 <panic>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
801060f9:	83 ec 0c             	sub    $0xc,%esp
801060fc:	68 eb 6e 10 80       	push   $0x80106eeb
80106101:	e8 42 a2 ff ff       	call   80100348 <panic>
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, P2V(pa), offset+i, n) != n)
80106106:	05 00 00 00 80       	add    $0x80000000,%eax
8010610b:	56                   	push   %esi
8010610c:	89 da                	mov    %ebx,%edx
8010610e:	03 55 14             	add    0x14(%ebp),%edx
80106111:	52                   	push   %edx
80106112:	50                   	push   %eax
80106113:	ff 75 10             	pushl  0x10(%ebp)
80106116:	e8 58 b6 ff ff       	call   80101773 <readi>
8010611b:	83 c4 10             	add    $0x10,%esp
8010611e:	39 f0                	cmp    %esi,%eax
80106120:	75 47                	jne    80106169 <loaduvm+0x99>
  for(i = 0; i < sz; i += PGSIZE){
80106122:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106128:	39 fb                	cmp    %edi,%ebx
8010612a:	73 30                	jae    8010615c <loaduvm+0x8c>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
8010612c:	89 da                	mov    %ebx,%edx
8010612e:	03 55 0c             	add    0xc(%ebp),%edx
80106131:	b9 00 00 00 00       	mov    $0x0,%ecx
80106136:	8b 45 08             	mov    0x8(%ebp),%eax
80106139:	e8 cd fb ff ff       	call   80105d0b <walkpgdir>
8010613e:	85 c0                	test   %eax,%eax
80106140:	74 b7                	je     801060f9 <loaduvm+0x29>
    pa = PTE_ADDR(*pte);
80106142:	8b 00                	mov    (%eax),%eax
80106144:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    if(sz - i < PGSIZE)
80106149:	89 fe                	mov    %edi,%esi
8010614b:	29 de                	sub    %ebx,%esi
8010614d:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
80106153:	76 b1                	jbe    80106106 <loaduvm+0x36>
      n = PGSIZE;
80106155:	be 00 10 00 00       	mov    $0x1000,%esi
8010615a:	eb aa                	jmp    80106106 <loaduvm+0x36>
      return -1;
  }
  return 0;
8010615c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106161:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106164:	5b                   	pop    %ebx
80106165:	5e                   	pop    %esi
80106166:	5f                   	pop    %edi
80106167:	5d                   	pop    %ebp
80106168:	c3                   	ret    
      return -1;
80106169:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010616e:	eb f1                	jmp    80106161 <loaduvm+0x91>

80106170 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80106170:	55                   	push   %ebp
80106171:	89 e5                	mov    %esp,%ebp
80106173:	57                   	push   %edi
80106174:	56                   	push   %esi
80106175:	53                   	push   %ebx
80106176:	83 ec 0c             	sub    $0xc,%esp
80106179:	8b 7d 0c             	mov    0xc(%ebp),%edi
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
8010617c:	39 7d 10             	cmp    %edi,0x10(%ebp)
8010617f:	73 11                	jae    80106192 <deallocuvm+0x22>
    return oldsz;

  a = PGROUNDUP(newsz);
80106181:	8b 45 10             	mov    0x10(%ebp),%eax
80106184:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
8010618a:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a  < oldsz; a += PGSIZE){
80106190:	eb 19                	jmp    801061ab <deallocuvm+0x3b>
    return oldsz;
80106192:	89 f8                	mov    %edi,%eax
80106194:	eb 64                	jmp    801061fa <deallocuvm+0x8a>
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(!pte)
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
80106196:	c1 eb 16             	shr    $0x16,%ebx
80106199:	83 c3 01             	add    $0x1,%ebx
8010619c:	c1 e3 16             	shl    $0x16,%ebx
8010619f:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
  for(; a  < oldsz; a += PGSIZE){
801061a5:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801061ab:	39 fb                	cmp    %edi,%ebx
801061ad:	73 48                	jae    801061f7 <deallocuvm+0x87>
    pte = walkpgdir(pgdir, (char*)a, 0);
801061af:	b9 00 00 00 00       	mov    $0x0,%ecx
801061b4:	89 da                	mov    %ebx,%edx
801061b6:	8b 45 08             	mov    0x8(%ebp),%eax
801061b9:	e8 4d fb ff ff       	call   80105d0b <walkpgdir>
801061be:	89 c6                	mov    %eax,%esi
    if(!pte)
801061c0:	85 c0                	test   %eax,%eax
801061c2:	74 d2                	je     80106196 <deallocuvm+0x26>
    else if((*pte & PTE_P) != 0){
801061c4:	8b 00                	mov    (%eax),%eax
801061c6:	a8 01                	test   $0x1,%al
801061c8:	74 db                	je     801061a5 <deallocuvm+0x35>
      pa = PTE_ADDR(*pte);
      if(pa == 0)
801061ca:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801061cf:	74 19                	je     801061ea <deallocuvm+0x7a>
        panic("kfree");
      char *v = P2V(pa);
801061d1:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
801061d6:	83 ec 0c             	sub    $0xc,%esp
801061d9:	50                   	push   %eax
801061da:	e8 c5 bd ff ff       	call   80101fa4 <kfree>
      *pte = 0;
801061df:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
801061e5:	83 c4 10             	add    $0x10,%esp
801061e8:	eb bb                	jmp    801061a5 <deallocuvm+0x35>
        panic("kfree");
801061ea:	83 ec 0c             	sub    $0xc,%esp
801061ed:	68 26 68 10 80       	push   $0x80106826
801061f2:	e8 51 a1 ff ff       	call   80100348 <panic>
    }
  }
  return newsz;
801061f7:	8b 45 10             	mov    0x10(%ebp),%eax
}
801061fa:	8d 65 f4             	lea    -0xc(%ebp),%esp
801061fd:	5b                   	pop    %ebx
801061fe:	5e                   	pop    %esi
801061ff:	5f                   	pop    %edi
80106200:	5d                   	pop    %ebp
80106201:	c3                   	ret    

80106202 <allocuvm>:
{
80106202:	55                   	push   %ebp
80106203:	89 e5                	mov    %esp,%ebp
80106205:	57                   	push   %edi
80106206:	56                   	push   %esi
80106207:	53                   	push   %ebx
80106208:	83 ec 1c             	sub    $0x1c,%esp
8010620b:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(newsz >= KERNBASE)
8010620e:	89 7d e4             	mov    %edi,-0x1c(%ebp)
80106211:	85 ff                	test   %edi,%edi
80106213:	0f 88 c1 00 00 00    	js     801062da <allocuvm+0xd8>
  if(newsz < oldsz)
80106219:	3b 7d 0c             	cmp    0xc(%ebp),%edi
8010621c:	72 5c                	jb     8010627a <allocuvm+0x78>
  a = PGROUNDUP(oldsz);
8010621e:	8b 45 0c             	mov    0xc(%ebp),%eax
80106221:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
80106227:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a < newsz; a += PGSIZE){
8010622d:	39 fb                	cmp    %edi,%ebx
8010622f:	0f 83 ac 00 00 00    	jae    801062e1 <allocuvm+0xdf>
    mem = kalloc();
80106235:	e8 b2 be ff ff       	call   801020ec <kalloc>
8010623a:	89 c6                	mov    %eax,%esi
    if(mem == 0){
8010623c:	85 c0                	test   %eax,%eax
8010623e:	74 42                	je     80106282 <allocuvm+0x80>
    memset(mem, 0, PGSIZE);
80106240:	83 ec 04             	sub    $0x4,%esp
80106243:	68 00 10 00 00       	push   $0x1000
80106248:	6a 00                	push   $0x0
8010624a:	50                   	push   %eax
8010624b:	e8 08 db ff ff       	call   80103d58 <memset>
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
80106250:	83 c4 08             	add    $0x8,%esp
80106253:	6a 06                	push   $0x6
80106255:	8d 86 00 00 00 80    	lea    -0x80000000(%esi),%eax
8010625b:	50                   	push   %eax
8010625c:	b9 00 10 00 00       	mov    $0x1000,%ecx
80106261:	89 da                	mov    %ebx,%edx
80106263:	8b 45 08             	mov    0x8(%ebp),%eax
80106266:	e8 10 fb ff ff       	call   80105d7b <mappages>
8010626b:	83 c4 10             	add    $0x10,%esp
8010626e:	85 c0                	test   %eax,%eax
80106270:	78 38                	js     801062aa <allocuvm+0xa8>
  for(; a < newsz; a += PGSIZE){
80106272:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106278:	eb b3                	jmp    8010622d <allocuvm+0x2b>
    return oldsz;
8010627a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010627d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80106280:	eb 5f                	jmp    801062e1 <allocuvm+0xdf>
      cprintf("allocuvm out of memory\n");
80106282:	83 ec 0c             	sub    $0xc,%esp
80106285:	68 09 6f 10 80       	push   $0x80106f09
8010628a:	e8 7c a3 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
8010628f:	83 c4 0c             	add    $0xc,%esp
80106292:	ff 75 0c             	pushl  0xc(%ebp)
80106295:	57                   	push   %edi
80106296:	ff 75 08             	pushl  0x8(%ebp)
80106299:	e8 d2 fe ff ff       	call   80106170 <deallocuvm>
      return 0;
8010629e:	83 c4 10             	add    $0x10,%esp
801062a1:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801062a8:	eb 37                	jmp    801062e1 <allocuvm+0xdf>
      cprintf("allocuvm out of memory (2)\n");
801062aa:	83 ec 0c             	sub    $0xc,%esp
801062ad:	68 21 6f 10 80       	push   $0x80106f21
801062b2:	e8 54 a3 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
801062b7:	83 c4 0c             	add    $0xc,%esp
801062ba:	ff 75 0c             	pushl  0xc(%ebp)
801062bd:	57                   	push   %edi
801062be:	ff 75 08             	pushl  0x8(%ebp)
801062c1:	e8 aa fe ff ff       	call   80106170 <deallocuvm>
      kfree(mem);
801062c6:	89 34 24             	mov    %esi,(%esp)
801062c9:	e8 d6 bc ff ff       	call   80101fa4 <kfree>
      return 0;
801062ce:	83 c4 10             	add    $0x10,%esp
801062d1:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801062d8:	eb 07                	jmp    801062e1 <allocuvm+0xdf>
    return 0;
801062da:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
}
801062e1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801062e4:	8d 65 f4             	lea    -0xc(%ebp),%esp
801062e7:	5b                   	pop    %ebx
801062e8:	5e                   	pop    %esi
801062e9:	5f                   	pop    %edi
801062ea:	5d                   	pop    %ebp
801062eb:	c3                   	ret    

801062ec <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
801062ec:	55                   	push   %ebp
801062ed:	89 e5                	mov    %esp,%ebp
801062ef:	56                   	push   %esi
801062f0:	53                   	push   %ebx
801062f1:	8b 75 08             	mov    0x8(%ebp),%esi
  uint i;

  if(pgdir == 0)
801062f4:	85 f6                	test   %esi,%esi
801062f6:	74 1a                	je     80106312 <freevm+0x26>
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
801062f8:	83 ec 04             	sub    $0x4,%esp
801062fb:	6a 00                	push   $0x0
801062fd:	68 00 00 00 80       	push   $0x80000000
80106302:	56                   	push   %esi
80106303:	e8 68 fe ff ff       	call   80106170 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80106308:	83 c4 10             	add    $0x10,%esp
8010630b:	bb 00 00 00 00       	mov    $0x0,%ebx
80106310:	eb 10                	jmp    80106322 <freevm+0x36>
    panic("freevm: no pgdir");
80106312:	83 ec 0c             	sub    $0xc,%esp
80106315:	68 3d 6f 10 80       	push   $0x80106f3d
8010631a:	e8 29 a0 ff ff       	call   80100348 <panic>
  for(i = 0; i < NPDENTRIES; i++){
8010631f:	83 c3 01             	add    $0x1,%ebx
80106322:	81 fb ff 03 00 00    	cmp    $0x3ff,%ebx
80106328:	77 1f                	ja     80106349 <freevm+0x5d>
    if(pgdir[i] & PTE_P){
8010632a:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
8010632d:	a8 01                	test   $0x1,%al
8010632f:	74 ee                	je     8010631f <freevm+0x33>
      char * v = P2V(PTE_ADDR(pgdir[i]));
80106331:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80106336:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
8010633b:	83 ec 0c             	sub    $0xc,%esp
8010633e:	50                   	push   %eax
8010633f:	e8 60 bc ff ff       	call   80101fa4 <kfree>
80106344:	83 c4 10             	add    $0x10,%esp
80106347:	eb d6                	jmp    8010631f <freevm+0x33>
    }
  }
  kfree((char*)pgdir);
80106349:	83 ec 0c             	sub    $0xc,%esp
8010634c:	56                   	push   %esi
8010634d:	e8 52 bc ff ff       	call   80101fa4 <kfree>
}
80106352:	83 c4 10             	add    $0x10,%esp
80106355:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106358:	5b                   	pop    %ebx
80106359:	5e                   	pop    %esi
8010635a:	5d                   	pop    %ebp
8010635b:	c3                   	ret    

8010635c <setupkvm>:
{
8010635c:	55                   	push   %ebp
8010635d:	89 e5                	mov    %esp,%ebp
8010635f:	56                   	push   %esi
80106360:	53                   	push   %ebx
  if((pgdir = (pde_t*)kalloc()) == 0)
80106361:	e8 86 bd ff ff       	call   801020ec <kalloc>
80106366:	89 c6                	mov    %eax,%esi
80106368:	85 c0                	test   %eax,%eax
8010636a:	74 55                	je     801063c1 <setupkvm+0x65>
  memset(pgdir, 0, PGSIZE);
8010636c:	83 ec 04             	sub    $0x4,%esp
8010636f:	68 00 10 00 00       	push   $0x1000
80106374:	6a 00                	push   $0x0
80106376:	50                   	push   %eax
80106377:	e8 dc d9 ff ff       	call   80103d58 <memset>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
8010637c:	83 c4 10             	add    $0x10,%esp
8010637f:	bb 20 94 10 80       	mov    $0x80109420,%ebx
80106384:	81 fb 60 94 10 80    	cmp    $0x80109460,%ebx
8010638a:	73 35                	jae    801063c1 <setupkvm+0x65>
                (uint)k->phys_start, k->perm) < 0) {
8010638c:	8b 43 04             	mov    0x4(%ebx),%eax
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
8010638f:	8b 4b 08             	mov    0x8(%ebx),%ecx
80106392:	29 c1                	sub    %eax,%ecx
80106394:	83 ec 08             	sub    $0x8,%esp
80106397:	ff 73 0c             	pushl  0xc(%ebx)
8010639a:	50                   	push   %eax
8010639b:	8b 13                	mov    (%ebx),%edx
8010639d:	89 f0                	mov    %esi,%eax
8010639f:	e8 d7 f9 ff ff       	call   80105d7b <mappages>
801063a4:	83 c4 10             	add    $0x10,%esp
801063a7:	85 c0                	test   %eax,%eax
801063a9:	78 05                	js     801063b0 <setupkvm+0x54>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801063ab:	83 c3 10             	add    $0x10,%ebx
801063ae:	eb d4                	jmp    80106384 <setupkvm+0x28>
      freevm(pgdir);
801063b0:	83 ec 0c             	sub    $0xc,%esp
801063b3:	56                   	push   %esi
801063b4:	e8 33 ff ff ff       	call   801062ec <freevm>
      return 0;
801063b9:	83 c4 10             	add    $0x10,%esp
801063bc:	be 00 00 00 00       	mov    $0x0,%esi
}
801063c1:	89 f0                	mov    %esi,%eax
801063c3:	8d 65 f8             	lea    -0x8(%ebp),%esp
801063c6:	5b                   	pop    %ebx
801063c7:	5e                   	pop    %esi
801063c8:	5d                   	pop    %ebp
801063c9:	c3                   	ret    

801063ca <kvmalloc>:
{
801063ca:	55                   	push   %ebp
801063cb:	89 e5                	mov    %esp,%ebp
801063cd:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
801063d0:	e8 87 ff ff ff       	call   8010635c <setupkvm>
801063d5:	a3 c4 44 19 80       	mov    %eax,0x801944c4
  switchkvm();
801063da:	e8 5e fb ff ff       	call   80105f3d <switchkvm>
}
801063df:	c9                   	leave  
801063e0:	c3                   	ret    

801063e1 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
801063e1:	55                   	push   %ebp
801063e2:	89 e5                	mov    %esp,%ebp
801063e4:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801063e7:	b9 00 00 00 00       	mov    $0x0,%ecx
801063ec:	8b 55 0c             	mov    0xc(%ebp),%edx
801063ef:	8b 45 08             	mov    0x8(%ebp),%eax
801063f2:	e8 14 f9 ff ff       	call   80105d0b <walkpgdir>
  if(pte == 0)
801063f7:	85 c0                	test   %eax,%eax
801063f9:	74 05                	je     80106400 <clearpteu+0x1f>
    panic("clearpteu");
  *pte &= ~PTE_U;
801063fb:	83 20 fb             	andl   $0xfffffffb,(%eax)
}
801063fe:	c9                   	leave  
801063ff:	c3                   	ret    
    panic("clearpteu");
80106400:	83 ec 0c             	sub    $0xc,%esp
80106403:	68 4e 6f 10 80       	push   $0x80106f4e
80106408:	e8 3b 9f ff ff       	call   80100348 <panic>

8010640d <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
8010640d:	55                   	push   %ebp
8010640e:	89 e5                	mov    %esp,%ebp
80106410:	57                   	push   %edi
80106411:	56                   	push   %esi
80106412:	53                   	push   %ebx
80106413:	83 ec 1c             	sub    $0x1c,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
80106416:	e8 41 ff ff ff       	call   8010635c <setupkvm>
8010641b:	89 45 dc             	mov    %eax,-0x24(%ebp)
8010641e:	85 c0                	test   %eax,%eax
80106420:	0f 84 c4 00 00 00    	je     801064ea <copyuvm+0xdd>
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80106426:	bf 00 00 00 00       	mov    $0x0,%edi
8010642b:	3b 7d 0c             	cmp    0xc(%ebp),%edi
8010642e:	0f 83 b6 00 00 00    	jae    801064ea <copyuvm+0xdd>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80106434:	89 7d e4             	mov    %edi,-0x1c(%ebp)
80106437:	b9 00 00 00 00       	mov    $0x0,%ecx
8010643c:	89 fa                	mov    %edi,%edx
8010643e:	8b 45 08             	mov    0x8(%ebp),%eax
80106441:	e8 c5 f8 ff ff       	call   80105d0b <walkpgdir>
80106446:	85 c0                	test   %eax,%eax
80106448:	74 65                	je     801064af <copyuvm+0xa2>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
8010644a:	8b 00                	mov    (%eax),%eax
8010644c:	a8 01                	test   $0x1,%al
8010644e:	74 6c                	je     801064bc <copyuvm+0xaf>
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
80106450:	89 c6                	mov    %eax,%esi
80106452:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    flags = PTE_FLAGS(*pte);
80106458:	25 ff 0f 00 00       	and    $0xfff,%eax
8010645d:	89 45 e0             	mov    %eax,-0x20(%ebp)
    if((mem = kalloc()) == 0)
80106460:	e8 87 bc ff ff       	call   801020ec <kalloc>
80106465:	89 c3                	mov    %eax,%ebx
80106467:	85 c0                	test   %eax,%eax
80106469:	74 6a                	je     801064d5 <copyuvm+0xc8>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
8010646b:	81 c6 00 00 00 80    	add    $0x80000000,%esi
80106471:	83 ec 04             	sub    $0x4,%esp
80106474:	68 00 10 00 00       	push   $0x1000
80106479:	56                   	push   %esi
8010647a:	50                   	push   %eax
8010647b:	e8 53 d9 ff ff       	call   80103dd3 <memmove>
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0) {
80106480:	83 c4 08             	add    $0x8,%esp
80106483:	ff 75 e0             	pushl  -0x20(%ebp)
80106486:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
8010648c:	50                   	push   %eax
8010648d:	b9 00 10 00 00       	mov    $0x1000,%ecx
80106492:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80106495:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106498:	e8 de f8 ff ff       	call   80105d7b <mappages>
8010649d:	83 c4 10             	add    $0x10,%esp
801064a0:	85 c0                	test   %eax,%eax
801064a2:	78 25                	js     801064c9 <copyuvm+0xbc>
  for(i = 0; i < sz; i += PGSIZE){
801064a4:	81 c7 00 10 00 00    	add    $0x1000,%edi
801064aa:	e9 7c ff ff ff       	jmp    8010642b <copyuvm+0x1e>
      panic("copyuvm: pte should exist");
801064af:	83 ec 0c             	sub    $0xc,%esp
801064b2:	68 58 6f 10 80       	push   $0x80106f58
801064b7:	e8 8c 9e ff ff       	call   80100348 <panic>
      panic("copyuvm: page not present");
801064bc:	83 ec 0c             	sub    $0xc,%esp
801064bf:	68 72 6f 10 80       	push   $0x80106f72
801064c4:	e8 7f 9e ff ff       	call   80100348 <panic>
      kfree(mem);
801064c9:	83 ec 0c             	sub    $0xc,%esp
801064cc:	53                   	push   %ebx
801064cd:	e8 d2 ba ff ff       	call   80101fa4 <kfree>
      goto bad;
801064d2:	83 c4 10             	add    $0x10,%esp
    }
  }
  return d;

bad:
  freevm(d);
801064d5:	83 ec 0c             	sub    $0xc,%esp
801064d8:	ff 75 dc             	pushl  -0x24(%ebp)
801064db:	e8 0c fe ff ff       	call   801062ec <freevm>
  return 0;
801064e0:	83 c4 10             	add    $0x10,%esp
801064e3:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
}
801064ea:	8b 45 dc             	mov    -0x24(%ebp),%eax
801064ed:	8d 65 f4             	lea    -0xc(%ebp),%esp
801064f0:	5b                   	pop    %ebx
801064f1:	5e                   	pop    %esi
801064f2:	5f                   	pop    %edi
801064f3:	5d                   	pop    %ebp
801064f4:	c3                   	ret    

801064f5 <uva2ka>:

// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
801064f5:	55                   	push   %ebp
801064f6:	89 e5                	mov    %esp,%ebp
801064f8:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801064fb:	b9 00 00 00 00       	mov    $0x0,%ecx
80106500:	8b 55 0c             	mov    0xc(%ebp),%edx
80106503:	8b 45 08             	mov    0x8(%ebp),%eax
80106506:	e8 00 f8 ff ff       	call   80105d0b <walkpgdir>
  if((*pte & PTE_P) == 0)
8010650b:	8b 00                	mov    (%eax),%eax
8010650d:	a8 01                	test   $0x1,%al
8010650f:	74 10                	je     80106521 <uva2ka+0x2c>
    return 0;
  if((*pte & PTE_U) == 0)
80106511:	a8 04                	test   $0x4,%al
80106513:	74 13                	je     80106528 <uva2ka+0x33>
    return 0;
  return (char*)P2V(PTE_ADDR(*pte));
80106515:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010651a:	05 00 00 00 80       	add    $0x80000000,%eax
}
8010651f:	c9                   	leave  
80106520:	c3                   	ret    
    return 0;
80106521:	b8 00 00 00 00       	mov    $0x0,%eax
80106526:	eb f7                	jmp    8010651f <uva2ka+0x2a>
    return 0;
80106528:	b8 00 00 00 00       	mov    $0x0,%eax
8010652d:	eb f0                	jmp    8010651f <uva2ka+0x2a>

8010652f <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
8010652f:	55                   	push   %ebp
80106530:	89 e5                	mov    %esp,%ebp
80106532:	57                   	push   %edi
80106533:	56                   	push   %esi
80106534:	53                   	push   %ebx
80106535:	83 ec 0c             	sub    $0xc,%esp
80106538:	8b 7d 14             	mov    0x14(%ebp),%edi
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
8010653b:	eb 25                	jmp    80106562 <copyout+0x33>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
8010653d:	8b 55 0c             	mov    0xc(%ebp),%edx
80106540:	29 f2                	sub    %esi,%edx
80106542:	01 d0                	add    %edx,%eax
80106544:	83 ec 04             	sub    $0x4,%esp
80106547:	53                   	push   %ebx
80106548:	ff 75 10             	pushl  0x10(%ebp)
8010654b:	50                   	push   %eax
8010654c:	e8 82 d8 ff ff       	call   80103dd3 <memmove>
    len -= n;
80106551:	29 df                	sub    %ebx,%edi
    buf += n;
80106553:	01 5d 10             	add    %ebx,0x10(%ebp)
    va = va0 + PGSIZE;
80106556:	8d 86 00 10 00 00    	lea    0x1000(%esi),%eax
8010655c:	89 45 0c             	mov    %eax,0xc(%ebp)
8010655f:	83 c4 10             	add    $0x10,%esp
  while(len > 0){
80106562:	85 ff                	test   %edi,%edi
80106564:	74 2f                	je     80106595 <copyout+0x66>
    va0 = (uint)PGROUNDDOWN(va);
80106566:	8b 75 0c             	mov    0xc(%ebp),%esi
80106569:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    pa0 = uva2ka(pgdir, (char*)va0);
8010656f:	83 ec 08             	sub    $0x8,%esp
80106572:	56                   	push   %esi
80106573:	ff 75 08             	pushl  0x8(%ebp)
80106576:	e8 7a ff ff ff       	call   801064f5 <uva2ka>
    if(pa0 == 0)
8010657b:	83 c4 10             	add    $0x10,%esp
8010657e:	85 c0                	test   %eax,%eax
80106580:	74 20                	je     801065a2 <copyout+0x73>
    n = PGSIZE - (va - va0);
80106582:	89 f3                	mov    %esi,%ebx
80106584:	2b 5d 0c             	sub    0xc(%ebp),%ebx
80106587:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    if(n > len)
8010658d:	39 df                	cmp    %ebx,%edi
8010658f:	73 ac                	jae    8010653d <copyout+0xe>
      n = len;
80106591:	89 fb                	mov    %edi,%ebx
80106593:	eb a8                	jmp    8010653d <copyout+0xe>
  }
  return 0;
80106595:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010659a:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010659d:	5b                   	pop    %ebx
8010659e:	5e                   	pop    %esi
8010659f:	5f                   	pop    %edi
801065a0:	5d                   	pop    %ebp
801065a1:	c3                   	ret    
      return -1;
801065a2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801065a7:	eb f1                	jmp    8010659a <copyout+0x6b>
