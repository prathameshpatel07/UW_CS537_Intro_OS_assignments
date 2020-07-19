
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
8010002d:	b8 3f 2b 10 80       	mov    $0x80102b3f,%eax
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
80100046:	e8 25 3c 00 00       	call   80103c70 <acquire>

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
8010007c:	e8 54 3c 00 00       	call   80103cd5 <release>
      acquiresleep(&b->lock);
80100081:	8d 43 0c             	lea    0xc(%ebx),%eax
80100084:	89 04 24             	mov    %eax,(%esp)
80100087:	e8 d0 39 00 00       	call   80103a5c <acquiresleep>
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
801000ca:	e8 06 3c 00 00       	call   80103cd5 <release>
      acquiresleep(&b->lock);
801000cf:	8d 43 0c             	lea    0xc(%ebx),%eax
801000d2:	89 04 24             	mov    %eax,(%esp)
801000d5:	e8 82 39 00 00       	call   80103a5c <acquiresleep>
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
801000ea:	68 80 65 10 80       	push   $0x80106580
801000ef:	e8 54 02 00 00       	call   80100348 <panic>

801000f4 <binit>:
{
801000f4:	55                   	push   %ebp
801000f5:	89 e5                	mov    %esp,%ebp
801000f7:	53                   	push   %ebx
801000f8:	83 ec 0c             	sub    $0xc,%esp
  initlock(&bcache.lock, "bcache");
801000fb:	68 91 65 10 80       	push   $0x80106591
80100100:	68 c0 a5 10 80       	push   $0x8010a5c0
80100105:	e8 2a 3a 00 00       	call   80103b34 <initlock>
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
8010013a:	68 98 65 10 80       	push   $0x80106598
8010013f:	8d 43 0c             	lea    0xc(%ebx),%eax
80100142:	50                   	push   %eax
80100143:	e8 e1 38 00 00       	call   80103a29 <initsleeplock>
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
801001a8:	e8 39 39 00 00       	call   80103ae6 <holdingsleep>
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
801001cb:	68 9f 65 10 80       	push   $0x8010659f
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
801001e4:	e8 fd 38 00 00       	call   80103ae6 <holdingsleep>
801001e9:	83 c4 10             	add    $0x10,%esp
801001ec:	85 c0                	test   %eax,%eax
801001ee:	74 6b                	je     8010025b <brelse+0x86>
    panic("brelse");

  releasesleep(&b->lock);
801001f0:	83 ec 0c             	sub    $0xc,%esp
801001f3:	56                   	push   %esi
801001f4:	e8 b2 38 00 00       	call   80103aab <releasesleep>

  acquire(&bcache.lock);
801001f9:	c7 04 24 c0 a5 10 80 	movl   $0x8010a5c0,(%esp)
80100200:	e8 6b 3a 00 00       	call   80103c70 <acquire>
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
8010024c:	e8 84 3a 00 00       	call   80103cd5 <release>
}
80100251:	83 c4 10             	add    $0x10,%esp
80100254:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100257:	5b                   	pop    %ebx
80100258:	5e                   	pop    %esi
80100259:	5d                   	pop    %ebp
8010025a:	c3                   	ret    
    panic("brelse");
8010025b:	83 ec 0c             	sub    $0xc,%esp
8010025e:	68 a6 65 10 80       	push   $0x801065a6
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
8010028a:	e8 e1 39 00 00       	call   80103c70 <acquire>
  while(n > 0){
8010028f:	83 c4 10             	add    $0x10,%esp
80100292:	85 db                	test   %ebx,%ebx
80100294:	0f 8e 8f 00 00 00    	jle    80100329 <consoleread+0xc1>
    while(input.r == input.w){
8010029a:	a1 a0 ef 10 80       	mov    0x8010efa0,%eax
8010029f:	3b 05 a4 ef 10 80    	cmp    0x8010efa4,%eax
801002a5:	75 47                	jne    801002ee <consoleread+0x86>
      if(myproc()->killed){
801002a7:	e8 25 30 00 00       	call   801032d1 <myproc>
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
801002bf:	e8 b1 34 00 00       	call   80103775 <sleep>
801002c4:	83 c4 10             	add    $0x10,%esp
801002c7:	eb d1                	jmp    8010029a <consoleread+0x32>
        release(&cons.lock);
801002c9:	83 ec 0c             	sub    $0xc,%esp
801002cc:	68 20 95 10 80       	push   $0x80109520
801002d1:	e8 ff 39 00 00       	call   80103cd5 <release>
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
80100331:	e8 9f 39 00 00       	call   80103cd5 <release>
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
8010035a:	e8 fa 20 00 00       	call   80102459 <lapicid>
8010035f:	83 ec 08             	sub    $0x8,%esp
80100362:	50                   	push   %eax
80100363:	68 ad 65 10 80       	push   $0x801065ad
80100368:	e8 9e 02 00 00       	call   8010060b <cprintf>
  cprintf(s);
8010036d:	83 c4 04             	add    $0x4,%esp
80100370:	ff 75 08             	pushl  0x8(%ebp)
80100373:	e8 93 02 00 00       	call   8010060b <cprintf>
  cprintf("\n");
80100378:	c7 04 24 fb 6e 10 80 	movl   $0x80106efb,(%esp)
8010037f:	e8 87 02 00 00       	call   8010060b <cprintf>
  getcallerpcs(&s, pcs);
80100384:	83 c4 08             	add    $0x8,%esp
80100387:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010038a:	50                   	push   %eax
8010038b:	8d 45 08             	lea    0x8(%ebp),%eax
8010038e:	50                   	push   %eax
8010038f:	e8 bb 37 00 00       	call   80103b4f <getcallerpcs>
  for(i=0; i<10; i++)
80100394:	83 c4 10             	add    $0x10,%esp
80100397:	bb 00 00 00 00       	mov    $0x0,%ebx
8010039c:	eb 17                	jmp    801003b5 <panic+0x6d>
    cprintf(" %p", pcs[i]);
8010039e:	83 ec 08             	sub    $0x8,%esp
801003a1:	ff 74 9d d0          	pushl  -0x30(%ebp,%ebx,4)
801003a5:	68 c1 65 10 80       	push   $0x801065c1
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
8010049e:	68 c5 65 10 80       	push   $0x801065c5
801004a3:	e8 a0 fe ff ff       	call   80100348 <panic>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801004a8:	83 ec 04             	sub    $0x4,%esp
801004ab:	68 60 0e 00 00       	push   $0xe60
801004b0:	68 a0 80 0b 80       	push   $0x800b80a0
801004b5:	68 00 80 0b 80       	push   $0x800b8000
801004ba:	e8 d8 38 00 00       	call   80103d97 <memmove>
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
801004d9:	e8 3e 38 00 00       	call   80103d1c <memset>
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
80100506:	e8 4b 4c 00 00       	call   80105156 <uartputc>
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
8010051f:	e8 32 4c 00 00       	call   80105156 <uartputc>
80100524:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010052b:	e8 26 4c 00 00       	call   80105156 <uartputc>
80100530:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100537:	e8 1a 4c 00 00       	call   80105156 <uartputc>
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
80100576:	0f b6 92 f0 65 10 80 	movzbl -0x7fef9a10(%edx),%edx
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
801005ca:	e8 a1 36 00 00       	call   80103c70 <acquire>
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
801005f1:	e8 df 36 00 00       	call   80103cd5 <release>
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
80100638:	e8 33 36 00 00       	call   80103c70 <acquire>
8010063d:	83 c4 10             	add    $0x10,%esp
80100640:	eb de                	jmp    80100620 <cprintf+0x15>
    panic("null fmt");
80100642:	83 ec 0c             	sub    $0xc,%esp
80100645:	68 df 65 10 80       	push   $0x801065df
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
801006ee:	be d8 65 10 80       	mov    $0x801065d8,%esi
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
80100734:	e8 9c 35 00 00       	call   80103cd5 <release>
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
8010074f:	e8 1c 35 00 00       	call   80103c70 <acquire>
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
801007de:	e8 f7 30 00 00       	call   801038da <wakeup>
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
80100873:	e8 5d 34 00 00       	call   80103cd5 <release>
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
80100887:	e8 eb 30 00 00       	call   80103977 <procdump>
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
80100894:	68 e8 65 10 80       	push   $0x801065e8
80100899:	68 20 95 10 80       	push   $0x80109520
8010089e:	e8 91 32 00 00       	call   80103b34 <initlock>

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
801008de:	e8 ee 29 00 00       	call   801032d1 <myproc>
801008e3:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)

  begin_op();
801008e9:	e8 9b 1f 00 00       	call   80102889 <begin_op>

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
80100935:	e8 c9 1f 00 00       	call   80102903 <end_op>
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
8010094a:	e8 b4 1f 00 00       	call   80102903 <end_op>
    cprintf("exec: fail\n");
8010094f:	83 ec 0c             	sub    $0xc,%esp
80100952:	68 01 66 10 80       	push   $0x80106601
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
80100972:	e8 9f 59 00 00       	call   80106316 <setupkvm>
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
80100a06:	e8 b1 57 00 00       	call   801061bc <allocuvm>
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
80100a38:	e8 4d 56 00 00       	call   8010608a <loaduvm>
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
80100a53:	e8 ab 1e 00 00       	call   80102903 <end_op>
  sz = PGROUNDUP(sz);
80100a58:	8d 87 ff 0f 00 00    	lea    0xfff(%edi),%eax
80100a5e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100a63:	83 c4 0c             	add    $0xc,%esp
80100a66:	8d 90 00 20 00 00    	lea    0x2000(%eax),%edx
80100a6c:	52                   	push   %edx
80100a6d:	50                   	push   %eax
80100a6e:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a74:	e8 43 57 00 00       	call   801061bc <allocuvm>
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
80100a9d:	e8 04 58 00 00       	call   801062a6 <freevm>
80100aa2:	83 c4 10             	add    $0x10,%esp
80100aa5:	e9 7a fe ff ff       	jmp    80100924 <exec+0x52>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100aaa:	89 c7                	mov    %eax,%edi
80100aac:	8d 80 00 e0 ff ff    	lea    -0x2000(%eax),%eax
80100ab2:	83 ec 08             	sub    $0x8,%esp
80100ab5:	50                   	push   %eax
80100ab6:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100abc:	e8 da 58 00 00       	call   8010639b <clearpteu>
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
80100ae2:	e8 d7 33 00 00       	call   80103ebe <strlen>
80100ae7:	29 c7                	sub    %eax,%edi
80100ae9:	83 ef 01             	sub    $0x1,%edi
80100aec:	83 e7 fc             	and    $0xfffffffc,%edi
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100aef:	83 c4 04             	add    $0x4,%esp
80100af2:	ff 36                	pushl  (%esi)
80100af4:	e8 c5 33 00 00       	call   80103ebe <strlen>
80100af9:	83 c0 01             	add    $0x1,%eax
80100afc:	50                   	push   %eax
80100afd:	ff 36                	pushl  (%esi)
80100aff:	57                   	push   %edi
80100b00:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b06:	e8 de 59 00 00       	call   801064e9 <copyout>
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
80100b66:	e8 7e 59 00 00       	call   801064e9 <copyout>
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
80100ba3:	e8 db 32 00 00       	call   80103e83 <safestrcpy>
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
80100bd1:	e8 33 53 00 00       	call   80105f09 <switchuvm>
  freevm(oldpgdir);
80100bd6:	89 1c 24             	mov    %ebx,(%esp)
80100bd9:	e8 c8 56 00 00       	call   801062a6 <freevm>
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
80100c19:	68 0d 66 10 80       	push   $0x8010660d
80100c1e:	68 c0 ef 10 80       	push   $0x8010efc0
80100c23:	e8 0c 2f 00 00       	call   80103b34 <initlock>
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
80100c39:	e8 32 30 00 00       	call   80103c70 <acquire>
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
80100c68:	e8 68 30 00 00       	call   80103cd5 <release>
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
80100c7f:	e8 51 30 00 00       	call   80103cd5 <release>
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
80100c9d:	e8 ce 2f 00 00       	call   80103c70 <acquire>
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
80100cba:	e8 16 30 00 00       	call   80103cd5 <release>
  return f;
}
80100cbf:	89 d8                	mov    %ebx,%eax
80100cc1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100cc4:	c9                   	leave  
80100cc5:	c3                   	ret    
    panic("filedup");
80100cc6:	83 ec 0c             	sub    $0xc,%esp
80100cc9:	68 14 66 10 80       	push   $0x80106614
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
80100ce2:	e8 89 2f 00 00       	call   80103c70 <acquire>
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
80100d03:	e8 cd 2f 00 00       	call   80103cd5 <release>
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
80100d13:	68 1c 66 10 80       	push   $0x8010661c
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
80100d49:	e8 87 2f 00 00       	call   80103cd5 <release>
  if(ff.type == FD_PIPE)
80100d4e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d51:	83 c4 10             	add    $0x10,%esp
80100d54:	83 f8 01             	cmp    $0x1,%eax
80100d57:	74 1f                	je     80100d78 <fileclose+0xa5>
  else if(ff.type == FD_INODE){
80100d59:	83 f8 02             	cmp    $0x2,%eax
80100d5c:	75 ad                	jne    80100d0b <fileclose+0x38>
    begin_op();
80100d5e:	e8 26 1b 00 00       	call   80102889 <begin_op>
    iput(ff.ip);
80100d63:	83 ec 0c             	sub    $0xc,%esp
80100d66:	ff 75 f0             	pushl  -0x10(%ebp)
80100d69:	e8 1a 09 00 00       	call   80101688 <iput>
    end_op();
80100d6e:	e8 90 1b 00 00       	call   80102903 <end_op>
80100d73:	83 c4 10             	add    $0x10,%esp
80100d76:	eb 93                	jmp    80100d0b <fileclose+0x38>
    pipeclose(ff.pipe, ff.writable);
80100d78:	83 ec 08             	sub    $0x8,%esp
80100d7b:	0f be 45 e9          	movsbl -0x17(%ebp),%eax
80100d7f:	50                   	push   %eax
80100d80:	ff 75 ec             	pushl  -0x14(%ebp)
80100d83:	e8 75 21 00 00       	call   80102efd <pipeclose>
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
80100e3c:	e8 14 22 00 00       	call   80103055 <piperead>
80100e41:	89 c6                	mov    %eax,%esi
80100e43:	83 c4 10             	add    $0x10,%esp
80100e46:	eb df                	jmp    80100e27 <fileread+0x50>
  panic("fileread");
80100e48:	83 ec 0c             	sub    $0xc,%esp
80100e4b:	68 26 66 10 80       	push   $0x80106626
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
80100e95:	e8 ef 20 00 00       	call   80102f89 <pipewrite>
80100e9a:	83 c4 10             	add    $0x10,%esp
80100e9d:	e9 80 00 00 00       	jmp    80100f22 <filewrite+0xc6>
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
80100ea2:	e8 e2 19 00 00       	call   80102889 <begin_op>
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
80100edd:	e8 21 1a 00 00       	call   80102903 <end_op>

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
80100f10:	68 2f 66 10 80       	push   $0x8010662f
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
80100f2d:	68 35 66 10 80       	push   $0x80106635
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
80100f8a:	e8 08 2e 00 00       	call   80103d97 <memmove>
80100f8f:	83 c4 10             	add    $0x10,%esp
80100f92:	eb 17                	jmp    80100fab <skipelem+0x66>
  else {
    memmove(name, s, len);
80100f94:	83 ec 04             	sub    $0x4,%esp
80100f97:	56                   	push   %esi
80100f98:	50                   	push   %eax
80100f99:	57                   	push   %edi
80100f9a:	e8 f8 2d 00 00       	call   80103d97 <memmove>
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
80100fdf:	e8 38 2d 00 00       	call   80103d1c <memset>
  log_write(bp);
80100fe4:	89 1c 24             	mov    %ebx,(%esp)
80100fe7:	e8 c6 19 00 00       	call   801029b2 <log_write>
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
801010a3:	68 3f 66 10 80       	push   $0x8010663f
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
801010bf:	e8 ee 18 00 00       	call   801029b2 <log_write>
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
80101170:	e8 3d 18 00 00       	call   801029b2 <log_write>
80101175:	83 c4 10             	add    $0x10,%esp
80101178:	eb bf                	jmp    80101139 <bmap+0x58>
  panic("bmap: out of range");
8010117a:	83 ec 0c             	sub    $0xc,%esp
8010117d:	68 55 66 10 80       	push   $0x80106655
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
8010119a:	e8 d1 2a 00 00       	call   80103c70 <acquire>
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
801011e1:	e8 ef 2a 00 00       	call   80103cd5 <release>
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
80101217:	e8 b9 2a 00 00       	call   80103cd5 <release>
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
8010122c:	68 68 66 10 80       	push   $0x80106668
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
80101255:	e8 3d 2b 00 00       	call   80103d97 <memmove>
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
801012c8:	e8 e5 16 00 00       	call   801029b2 <log_write>
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
801012e2:	68 78 66 10 80       	push   $0x80106678
801012e7:	e8 5c f0 ff ff       	call   80100348 <panic>

801012ec <iinit>:
{
801012ec:	55                   	push   %ebp
801012ed:	89 e5                	mov    %esp,%ebp
801012ef:	53                   	push   %ebx
801012f0:	83 ec 0c             	sub    $0xc,%esp
  initlock(&icache.lock, "icache");
801012f3:	68 8b 66 10 80       	push   $0x8010668b
801012f8:	68 e0 f9 10 80       	push   $0x8010f9e0
801012fd:	e8 32 28 00 00       	call   80103b34 <initlock>
  for(i = 0; i < NINODE; i++) {
80101302:	83 c4 10             	add    $0x10,%esp
80101305:	bb 00 00 00 00       	mov    $0x0,%ebx
8010130a:	eb 21                	jmp    8010132d <iinit+0x41>
    initsleeplock(&icache.inode[i].lock, "inode");
8010130c:	83 ec 08             	sub    $0x8,%esp
8010130f:	68 92 66 10 80       	push   $0x80106692
80101314:	8d 14 db             	lea    (%ebx,%ebx,8),%edx
80101317:	89 d0                	mov    %edx,%eax
80101319:	c1 e0 04             	shl    $0x4,%eax
8010131c:	05 20 fa 10 80       	add    $0x8010fa20,%eax
80101321:	50                   	push   %eax
80101322:	e8 02 27 00 00       	call   80103a29 <initsleeplock>
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
8010136c:	68 f8 66 10 80       	push   $0x801066f8
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
801013df:	68 98 66 10 80       	push   $0x80106698
801013e4:	e8 5f ef ff ff       	call   80100348 <panic>
      memset(dip, 0, sizeof(*dip));
801013e9:	83 ec 04             	sub    $0x4,%esp
801013ec:	6a 40                	push   $0x40
801013ee:	6a 00                	push   $0x0
801013f0:	57                   	push   %edi
801013f1:	e8 26 29 00 00       	call   80103d1c <memset>
      dip->type = type;
801013f6:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801013fa:	66 89 07             	mov    %ax,(%edi)
      log_write(bp);   // mark it allocated on the disk
801013fd:	89 34 24             	mov    %esi,(%esp)
80101400:	e8 ad 15 00 00       	call   801029b2 <log_write>
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
80101480:	e8 12 29 00 00       	call   80103d97 <memmove>
  log_write(bp);
80101485:	89 34 24             	mov    %esi,(%esp)
80101488:	e8 25 15 00 00       	call   801029b2 <log_write>
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
80101560:	e8 0b 27 00 00       	call   80103c70 <acquire>
  ip->ref++;
80101565:	8b 43 08             	mov    0x8(%ebx),%eax
80101568:	83 c0 01             	add    $0x1,%eax
8010156b:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
8010156e:	c7 04 24 e0 f9 10 80 	movl   $0x8010f9e0,(%esp)
80101575:	e8 5b 27 00 00       	call   80103cd5 <release>
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
8010159a:	e8 bd 24 00 00       	call   80103a5c <acquiresleep>
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
801015b2:	68 aa 66 10 80       	push   $0x801066aa
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
80101614:	e8 7e 27 00 00       	call   80103d97 <memmove>
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
80101639:	68 b0 66 10 80       	push   $0x801066b0
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
80101656:	e8 8b 24 00 00       	call   80103ae6 <holdingsleep>
8010165b:	83 c4 10             	add    $0x10,%esp
8010165e:	85 c0                	test   %eax,%eax
80101660:	74 19                	je     8010167b <iunlock+0x38>
80101662:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101666:	7e 13                	jle    8010167b <iunlock+0x38>
  releasesleep(&ip->lock);
80101668:	83 ec 0c             	sub    $0xc,%esp
8010166b:	56                   	push   %esi
8010166c:	e8 3a 24 00 00       	call   80103aab <releasesleep>
}
80101671:	83 c4 10             	add    $0x10,%esp
80101674:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101677:	5b                   	pop    %ebx
80101678:	5e                   	pop    %esi
80101679:	5d                   	pop    %ebp
8010167a:	c3                   	ret    
    panic("iunlock");
8010167b:	83 ec 0c             	sub    $0xc,%esp
8010167e:	68 bf 66 10 80       	push   $0x801066bf
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
80101698:	e8 bf 23 00 00       	call   80103a5c <acquiresleep>
  if(ip->valid && ip->nlink == 0){
8010169d:	83 c4 10             	add    $0x10,%esp
801016a0:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801016a4:	74 07                	je     801016ad <iput+0x25>
801016a6:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801016ab:	74 35                	je     801016e2 <iput+0x5a>
  releasesleep(&ip->lock);
801016ad:	83 ec 0c             	sub    $0xc,%esp
801016b0:	56                   	push   %esi
801016b1:	e8 f5 23 00 00       	call   80103aab <releasesleep>
  acquire(&icache.lock);
801016b6:	c7 04 24 e0 f9 10 80 	movl   $0x8010f9e0,(%esp)
801016bd:	e8 ae 25 00 00       	call   80103c70 <acquire>
  ip->ref--;
801016c2:	8b 43 08             	mov    0x8(%ebx),%eax
801016c5:	83 e8 01             	sub    $0x1,%eax
801016c8:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
801016cb:	c7 04 24 e0 f9 10 80 	movl   $0x8010f9e0,(%esp)
801016d2:	e8 fe 25 00 00       	call   80103cd5 <release>
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
801016ea:	e8 81 25 00 00       	call   80103c70 <acquire>
    int r = ip->ref;
801016ef:	8b 7b 08             	mov    0x8(%ebx),%edi
    release(&icache.lock);
801016f2:	c7 04 24 e0 f9 10 80 	movl   $0x8010f9e0,(%esp)
801016f9:	e8 d7 25 00 00       	call   80103cd5 <release>
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
8010182a:	e8 68 25 00 00       	call   80103d97 <memmove>
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
80101926:	e8 6c 24 00 00       	call   80103d97 <memmove>
    log_write(bp);
8010192b:	89 3c 24             	mov    %edi,(%esp)
8010192e:	e8 7f 10 00 00       	call   801029b2 <log_write>
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
801019a9:	e8 50 24 00 00       	call   80103dfe <strncmp>
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
801019d0:	68 c7 66 10 80       	push   $0x801066c7
801019d5:	e8 6e e9 ff ff       	call   80100348 <panic>
      panic("dirlookup read");
801019da:	83 ec 0c             	sub    $0xc,%esp
801019dd:	68 d9 66 10 80       	push   $0x801066d9
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
80101a5a:	e8 72 18 00 00       	call   801032d1 <myproc>
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
80101b92:	68 e8 66 10 80       	push   $0x801066e8
80101b97:	e8 ac e7 ff ff       	call   80100348 <panic>
  strncpy(de.name, name, DIRSIZ);
80101b9c:	83 ec 04             	sub    $0x4,%esp
80101b9f:	6a 0e                	push   $0xe
80101ba1:	57                   	push   %edi
80101ba2:	8d 7d d8             	lea    -0x28(%ebp),%edi
80101ba5:	8d 45 da             	lea    -0x26(%ebp),%eax
80101ba8:	50                   	push   %eax
80101ba9:	e8 8d 22 00 00       	call   80103e3b <strncpy>
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
80101bd7:	68 f4 6c 10 80       	push   $0x80106cf4
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
80101ccc:	68 4b 67 10 80       	push   $0x8010674b
80101cd1:	e8 72 e6 ff ff       	call   80100348 <panic>
    panic("incorrect blockno");
80101cd6:	83 ec 0c             	sub    $0xc,%esp
80101cd9:	68 54 67 10 80       	push   $0x80106754
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
80101d06:	68 66 67 10 80       	push   $0x80106766
80101d0b:	68 80 95 10 80       	push   $0x80109580
80101d10:	e8 1f 1e 00 00       	call   80103b34 <initlock>
  ioapicenable(IRQ_IDE, ncpu - 1);
80101d15:	83 c4 08             	add    $0x8,%esp
80101d18:	a1 20 1d 13 80       	mov    0x80131d20,%eax
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
80101d80:	e8 eb 1e 00 00       	call   80103c70 <acquire>

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
80101dad:	e8 28 1b 00 00       	call   801038da <wakeup>

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
80101dcb:	e8 05 1f 00 00       	call   80103cd5 <release>
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
80101de2:	e8 ee 1e 00 00       	call   80103cd5 <release>
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
80101e1a:	e8 c7 1c 00 00       	call   80103ae6 <holdingsleep>
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
80101e47:	e8 24 1e 00 00       	call   80103c70 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80101e4c:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e53:	83 c4 10             	add    $0x10,%esp
80101e56:	ba 64 95 10 80       	mov    $0x80109564,%edx
80101e5b:	eb 2a                	jmp    80101e87 <iderw+0x7b>
    panic("iderw: buf not locked");
80101e5d:	83 ec 0c             	sub    $0xc,%esp
80101e60:	68 6a 67 10 80       	push   $0x8010676a
80101e65:	e8 de e4 ff ff       	call   80100348 <panic>
    panic("iderw: nothing to do");
80101e6a:	83 ec 0c             	sub    $0xc,%esp
80101e6d:	68 80 67 10 80       	push   $0x80106780
80101e72:	e8 d1 e4 ff ff       	call   80100348 <panic>
    panic("iderw: ide disk 1 not present");
80101e77:	83 ec 0c             	sub    $0xc,%esp
80101e7a:	68 95 67 10 80       	push   $0x80106795
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
80101ea9:	e8 c7 18 00 00       	call   80103775 <sleep>
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
80101ec3:	e8 0d 1e 00 00       	call   80103cd5 <release>
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
80101f2a:	0f b6 15 80 17 13 80 	movzbl 0x80131780,%edx
80101f31:	39 c2                	cmp    %eax,%edx
80101f33:	75 07                	jne    80101f3c <ioapicinit+0x42>
{
80101f35:	bb 00 00 00 00       	mov    $0x0,%ebx
80101f3a:	eb 36                	jmp    80101f72 <ioapicinit+0x78>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80101f3c:	83 ec 0c             	sub    $0xc,%esp
80101f3f:	68 b4 67 10 80       	push   $0x801067b4
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
80101fb6:	81 fb c8 44 13 80    	cmp    $0x801344c8,%ebx
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
80101fd6:	e8 41 1d 00 00       	call   80103d1c <memset>

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
80102005:	68 e6 67 10 80       	push   $0x801067e6
8010200a:	e8 39 e3 ff ff       	call   80100348 <panic>
    acquire(&kmem.lock);
8010200f:	83 ec 0c             	sub    $0xc,%esp
80102012:	68 40 16 11 80       	push   $0x80111640
80102017:	e8 54 1c 00 00       	call   80103c70 <acquire>
8010201c:	83 c4 10             	add    $0x10,%esp
8010201f:	eb c6                	jmp    80101fe7 <kfree+0x43>
    release(&kmem.lock);
80102021:	83 ec 0c             	sub    $0xc,%esp
80102024:	68 40 16 11 80       	push   $0x80111640
80102029:	e8 a7 1c 00 00       	call   80103cd5 <release>
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
8010206f:	68 ec 67 10 80       	push   $0x801067ec
80102074:	68 40 16 11 80       	push   $0x80111640
80102079:	e8 b6 1a 00 00       	call   80103b34 <initlock>
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
801020c0:	c7 04 85 80 16 12 80 	movl   $0xffffffff,-0x7fede980(,%eax,4)
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
80102124:	89 14 85 80 16 12 80 	mov    %edx,-0x7fede980(,%eax,4)
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
80102156:	e8 15 1b 00 00       	call   80103c70 <acquire>
8010215b:	83 c4 10             	add    $0x10,%esp
8010215e:	eb 9c                	jmp    801020fc <kalloc+0x10>
    release(&kmem.lock);
80102160:	83 ec 0c             	sub    $0xc,%esp
80102163:	68 40 16 11 80       	push   $0x80111640
80102168:	e8 68 1b 00 00       	call   80103cd5 <release>
8010216d:	83 c4 10             	add    $0x10,%esp
  return (char*)r;
80102170:	eb d5                	jmp    80102147 <kalloc+0x5b>

80102172 <dump_physmem>:

int
dump_physmem(int *frames, int *pids, int numframe)
{
80102172:	55                   	push   %ebp
80102173:	89 e5                	mov    %esp,%ebp
80102175:	56                   	push   %esi
80102176:	53                   	push   %ebx
80102177:	8b 5d 08             	mov    0x8(%ebp),%ebx
8010217a:	8b 75 0c             	mov    0xc(%ebp),%esi
  if(kmem.use_lock)
8010217d:	83 3d 74 16 11 80 00 	cmpl   $0x0,0x80111674
80102184:	75 07                	jne    8010218d <dump_physmem+0x1b>
{
80102186:	b8 00 00 00 00       	mov    $0x0,%eax
8010218b:	eb 30                	jmp    801021bd <dump_physmem+0x4b>
    acquire(&kmem.lock);
8010218d:	83 ec 0c             	sub    $0xc,%esp
80102190:	68 40 16 11 80       	push   $0x80111640
80102195:	e8 d6 1a 00 00       	call   80103c70 <acquire>
8010219a:	83 c4 10             	add    $0x10,%esp
8010219d:	eb e7                	jmp    80102186 <dump_physmem+0x14>

  for(int i = 0; i < 16384; i++) {
  	frames[i] = framearr[i];
8010219f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801021a6:	8b 0c 85 80 16 12 80 	mov    -0x7fede980(,%eax,4),%ecx
801021ad:	89 0c 13             	mov    %ecx,(%ebx,%edx,1)
  	pids[i] = pidarr[i];
801021b0:	8b 0c 85 80 16 11 80 	mov    -0x7feee980(,%eax,4),%ecx
801021b7:	89 0c 16             	mov    %ecx,(%esi,%edx,1)
  for(int i = 0; i < 16384; i++) {
801021ba:	83 c0 01             	add    $0x1,%eax
801021bd:	3d ff 3f 00 00       	cmp    $0x3fff,%eax
801021c2:	7e db                	jle    8010219f <dump_physmem+0x2d>
  }
  numframe = totalframes;

  if(kmem.use_lock)
801021c4:	83 3d 74 16 11 80 00 	cmpl   $0x0,0x80111674
801021cb:	75 0c                	jne    801021d9 <dump_physmem+0x67>
    release(&kmem.lock);
  
	return -1;
}
801021cd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801021d2:	8d 65 f8             	lea    -0x8(%ebp),%esp
801021d5:	5b                   	pop    %ebx
801021d6:	5e                   	pop    %esi
801021d7:	5d                   	pop    %ebp
801021d8:	c3                   	ret    
    release(&kmem.lock);
801021d9:	83 ec 0c             	sub    $0xc,%esp
801021dc:	68 40 16 11 80       	push   $0x80111640
801021e1:	e8 ef 1a 00 00       	call   80103cd5 <release>
801021e6:	83 c4 10             	add    $0x10,%esp
801021e9:	eb e2                	jmp    801021cd <dump_physmem+0x5b>

801021eb <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
801021eb:	55                   	push   %ebp
801021ec:	89 e5                	mov    %esp,%ebp
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801021ee:	ba 64 00 00 00       	mov    $0x64,%edx
801021f3:	ec                   	in     (%dx),%al
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
  if((st & KBS_DIB) == 0)
801021f4:	a8 01                	test   $0x1,%al
801021f6:	0f 84 b5 00 00 00    	je     801022b1 <kbdgetc+0xc6>
801021fc:	ba 60 00 00 00       	mov    $0x60,%edx
80102201:	ec                   	in     (%dx),%al
    return -1;
  data = inb(KBDATAP);
80102202:	0f b6 d0             	movzbl %al,%edx

  if(data == 0xE0){
80102205:	81 fa e0 00 00 00    	cmp    $0xe0,%edx
8010220b:	74 5c                	je     80102269 <kbdgetc+0x7e>
    shift |= E0ESC;
    return 0;
  } else if(data & 0x80){
8010220d:	84 c0                	test   %al,%al
8010220f:	78 66                	js     80102277 <kbdgetc+0x8c>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
    shift &= ~(shiftcode[data] | E0ESC);
    return 0;
  } else if(shift & E0ESC){
80102211:	8b 0d b4 95 10 80    	mov    0x801095b4,%ecx
80102217:	f6 c1 40             	test   $0x40,%cl
8010221a:	74 0f                	je     8010222b <kbdgetc+0x40>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
8010221c:	83 c8 80             	or     $0xffffff80,%eax
8010221f:	0f b6 d0             	movzbl %al,%edx
    shift &= ~E0ESC;
80102222:	83 e1 bf             	and    $0xffffffbf,%ecx
80102225:	89 0d b4 95 10 80    	mov    %ecx,0x801095b4
  }

  shift |= shiftcode[data];
8010222b:	0f b6 8a 20 69 10 80 	movzbl -0x7fef96e0(%edx),%ecx
80102232:	0b 0d b4 95 10 80    	or     0x801095b4,%ecx
  shift ^= togglecode[data];
80102238:	0f b6 82 20 68 10 80 	movzbl -0x7fef97e0(%edx),%eax
8010223f:	31 c1                	xor    %eax,%ecx
80102241:	89 0d b4 95 10 80    	mov    %ecx,0x801095b4
  c = charcode[shift & (CTL | SHIFT)][data];
80102247:	89 c8                	mov    %ecx,%eax
80102249:	83 e0 03             	and    $0x3,%eax
8010224c:	8b 04 85 00 68 10 80 	mov    -0x7fef9800(,%eax,4),%eax
80102253:	0f b6 04 10          	movzbl (%eax,%edx,1),%eax
  if(shift & CAPSLOCK){
80102257:	f6 c1 08             	test   $0x8,%cl
8010225a:	74 19                	je     80102275 <kbdgetc+0x8a>
    if('a' <= c && c <= 'z')
8010225c:	8d 50 9f             	lea    -0x61(%eax),%edx
8010225f:	83 fa 19             	cmp    $0x19,%edx
80102262:	77 40                	ja     801022a4 <kbdgetc+0xb9>
      c += 'A' - 'a';
80102264:	83 e8 20             	sub    $0x20,%eax
80102267:	eb 0c                	jmp    80102275 <kbdgetc+0x8a>
    shift |= E0ESC;
80102269:	83 0d b4 95 10 80 40 	orl    $0x40,0x801095b4
    return 0;
80102270:	b8 00 00 00 00       	mov    $0x0,%eax
    else if('A' <= c && c <= 'Z')
      c += 'a' - 'A';
  }
  return c;
}
80102275:	5d                   	pop    %ebp
80102276:	c3                   	ret    
    data = (shift & E0ESC ? data : data & 0x7F);
80102277:	8b 0d b4 95 10 80    	mov    0x801095b4,%ecx
8010227d:	f6 c1 40             	test   $0x40,%cl
80102280:	75 05                	jne    80102287 <kbdgetc+0x9c>
80102282:	89 c2                	mov    %eax,%edx
80102284:	83 e2 7f             	and    $0x7f,%edx
    shift &= ~(shiftcode[data] | E0ESC);
80102287:	0f b6 82 20 69 10 80 	movzbl -0x7fef96e0(%edx),%eax
8010228e:	83 c8 40             	or     $0x40,%eax
80102291:	0f b6 c0             	movzbl %al,%eax
80102294:	f7 d0                	not    %eax
80102296:	21 c8                	and    %ecx,%eax
80102298:	a3 b4 95 10 80       	mov    %eax,0x801095b4
    return 0;
8010229d:	b8 00 00 00 00       	mov    $0x0,%eax
801022a2:	eb d1                	jmp    80102275 <kbdgetc+0x8a>
    else if('A' <= c && c <= 'Z')
801022a4:	8d 50 bf             	lea    -0x41(%eax),%edx
801022a7:	83 fa 19             	cmp    $0x19,%edx
801022aa:	77 c9                	ja     80102275 <kbdgetc+0x8a>
      c += 'a' - 'A';
801022ac:	83 c0 20             	add    $0x20,%eax
  return c;
801022af:	eb c4                	jmp    80102275 <kbdgetc+0x8a>
    return -1;
801022b1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801022b6:	eb bd                	jmp    80102275 <kbdgetc+0x8a>

801022b8 <kbdintr>:

void
kbdintr(void)
{
801022b8:	55                   	push   %ebp
801022b9:	89 e5                	mov    %esp,%ebp
801022bb:	83 ec 14             	sub    $0x14,%esp
  consoleintr(kbdgetc);
801022be:	68 eb 21 10 80       	push   $0x801021eb
801022c3:	e8 76 e4 ff ff       	call   8010073e <consoleintr>
}
801022c8:	83 c4 10             	add    $0x10,%esp
801022cb:	c9                   	leave  
801022cc:	c3                   	ret    

801022cd <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
801022cd:	55                   	push   %ebp
801022ce:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
801022d0:	8b 0d 80 16 13 80    	mov    0x80131680,%ecx
801022d6:	8d 04 81             	lea    (%ecx,%eax,4),%eax
801022d9:	89 10                	mov    %edx,(%eax)
  lapic[ID];  // wait for write to finish, by reading
801022db:	a1 80 16 13 80       	mov    0x80131680,%eax
801022e0:	8b 40 20             	mov    0x20(%eax),%eax
}
801022e3:	5d                   	pop    %ebp
801022e4:	c3                   	ret    

801022e5 <cmos_read>:
#define MONTH   0x08
#define YEAR    0x09

static uint
cmos_read(uint reg)
{
801022e5:	55                   	push   %ebp
801022e6:	89 e5                	mov    %esp,%ebp
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801022e8:	ba 70 00 00 00       	mov    $0x70,%edx
801022ed:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801022ee:	ba 71 00 00 00       	mov    $0x71,%edx
801022f3:	ec                   	in     (%dx),%al
  outb(CMOS_PORT,  reg);
  microdelay(200);

  return inb(CMOS_RETURN);
801022f4:	0f b6 c0             	movzbl %al,%eax
}
801022f7:	5d                   	pop    %ebp
801022f8:	c3                   	ret    

801022f9 <fill_rtcdate>:

static void
fill_rtcdate(struct rtcdate *r)
{
801022f9:	55                   	push   %ebp
801022fa:	89 e5                	mov    %esp,%ebp
801022fc:	53                   	push   %ebx
801022fd:	89 c3                	mov    %eax,%ebx
  r->second = cmos_read(SECS);
801022ff:	b8 00 00 00 00       	mov    $0x0,%eax
80102304:	e8 dc ff ff ff       	call   801022e5 <cmos_read>
80102309:	89 03                	mov    %eax,(%ebx)
  r->minute = cmos_read(MINS);
8010230b:	b8 02 00 00 00       	mov    $0x2,%eax
80102310:	e8 d0 ff ff ff       	call   801022e5 <cmos_read>
80102315:	89 43 04             	mov    %eax,0x4(%ebx)
  r->hour   = cmos_read(HOURS);
80102318:	b8 04 00 00 00       	mov    $0x4,%eax
8010231d:	e8 c3 ff ff ff       	call   801022e5 <cmos_read>
80102322:	89 43 08             	mov    %eax,0x8(%ebx)
  r->day    = cmos_read(DAY);
80102325:	b8 07 00 00 00       	mov    $0x7,%eax
8010232a:	e8 b6 ff ff ff       	call   801022e5 <cmos_read>
8010232f:	89 43 0c             	mov    %eax,0xc(%ebx)
  r->month  = cmos_read(MONTH);
80102332:	b8 08 00 00 00       	mov    $0x8,%eax
80102337:	e8 a9 ff ff ff       	call   801022e5 <cmos_read>
8010233c:	89 43 10             	mov    %eax,0x10(%ebx)
  r->year   = cmos_read(YEAR);
8010233f:	b8 09 00 00 00       	mov    $0x9,%eax
80102344:	e8 9c ff ff ff       	call   801022e5 <cmos_read>
80102349:	89 43 14             	mov    %eax,0x14(%ebx)
}
8010234c:	5b                   	pop    %ebx
8010234d:	5d                   	pop    %ebp
8010234e:	c3                   	ret    

8010234f <lapicinit>:
  if(!lapic)
8010234f:	83 3d 80 16 13 80 00 	cmpl   $0x0,0x80131680
80102356:	0f 84 fb 00 00 00    	je     80102457 <lapicinit+0x108>
{
8010235c:	55                   	push   %ebp
8010235d:	89 e5                	mov    %esp,%ebp
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
8010235f:	ba 3f 01 00 00       	mov    $0x13f,%edx
80102364:	b8 3c 00 00 00       	mov    $0x3c,%eax
80102369:	e8 5f ff ff ff       	call   801022cd <lapicw>
  lapicw(TDCR, X1);
8010236e:	ba 0b 00 00 00       	mov    $0xb,%edx
80102373:	b8 f8 00 00 00       	mov    $0xf8,%eax
80102378:	e8 50 ff ff ff       	call   801022cd <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
8010237d:	ba 20 00 02 00       	mov    $0x20020,%edx
80102382:	b8 c8 00 00 00       	mov    $0xc8,%eax
80102387:	e8 41 ff ff ff       	call   801022cd <lapicw>
  lapicw(TICR, 10000000);
8010238c:	ba 80 96 98 00       	mov    $0x989680,%edx
80102391:	b8 e0 00 00 00       	mov    $0xe0,%eax
80102396:	e8 32 ff ff ff       	call   801022cd <lapicw>
  lapicw(LINT0, MASKED);
8010239b:	ba 00 00 01 00       	mov    $0x10000,%edx
801023a0:	b8 d4 00 00 00       	mov    $0xd4,%eax
801023a5:	e8 23 ff ff ff       	call   801022cd <lapicw>
  lapicw(LINT1, MASKED);
801023aa:	ba 00 00 01 00       	mov    $0x10000,%edx
801023af:	b8 d8 00 00 00       	mov    $0xd8,%eax
801023b4:	e8 14 ff ff ff       	call   801022cd <lapicw>
  if(((lapic[VER]>>16) & 0xFF) >= 4)
801023b9:	a1 80 16 13 80       	mov    0x80131680,%eax
801023be:	8b 40 30             	mov    0x30(%eax),%eax
801023c1:	c1 e8 10             	shr    $0x10,%eax
801023c4:	3c 03                	cmp    $0x3,%al
801023c6:	77 7b                	ja     80102443 <lapicinit+0xf4>
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
801023c8:	ba 33 00 00 00       	mov    $0x33,%edx
801023cd:	b8 dc 00 00 00       	mov    $0xdc,%eax
801023d2:	e8 f6 fe ff ff       	call   801022cd <lapicw>
  lapicw(ESR, 0);
801023d7:	ba 00 00 00 00       	mov    $0x0,%edx
801023dc:	b8 a0 00 00 00       	mov    $0xa0,%eax
801023e1:	e8 e7 fe ff ff       	call   801022cd <lapicw>
  lapicw(ESR, 0);
801023e6:	ba 00 00 00 00       	mov    $0x0,%edx
801023eb:	b8 a0 00 00 00       	mov    $0xa0,%eax
801023f0:	e8 d8 fe ff ff       	call   801022cd <lapicw>
  lapicw(EOI, 0);
801023f5:	ba 00 00 00 00       	mov    $0x0,%edx
801023fa:	b8 2c 00 00 00       	mov    $0x2c,%eax
801023ff:	e8 c9 fe ff ff       	call   801022cd <lapicw>
  lapicw(ICRHI, 0);
80102404:	ba 00 00 00 00       	mov    $0x0,%edx
80102409:	b8 c4 00 00 00       	mov    $0xc4,%eax
8010240e:	e8 ba fe ff ff       	call   801022cd <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102413:	ba 00 85 08 00       	mov    $0x88500,%edx
80102418:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010241d:	e8 ab fe ff ff       	call   801022cd <lapicw>
  while(lapic[ICRLO] & DELIVS)
80102422:	a1 80 16 13 80       	mov    0x80131680,%eax
80102427:	8b 80 00 03 00 00    	mov    0x300(%eax),%eax
8010242d:	f6 c4 10             	test   $0x10,%ah
80102430:	75 f0                	jne    80102422 <lapicinit+0xd3>
  lapicw(TPR, 0);
80102432:	ba 00 00 00 00       	mov    $0x0,%edx
80102437:	b8 20 00 00 00       	mov    $0x20,%eax
8010243c:	e8 8c fe ff ff       	call   801022cd <lapicw>
}
80102441:	5d                   	pop    %ebp
80102442:	c3                   	ret    
    lapicw(PCINT, MASKED);
80102443:	ba 00 00 01 00       	mov    $0x10000,%edx
80102448:	b8 d0 00 00 00       	mov    $0xd0,%eax
8010244d:	e8 7b fe ff ff       	call   801022cd <lapicw>
80102452:	e9 71 ff ff ff       	jmp    801023c8 <lapicinit+0x79>
80102457:	f3 c3                	repz ret 

80102459 <lapicid>:
{
80102459:	55                   	push   %ebp
8010245a:	89 e5                	mov    %esp,%ebp
  if (!lapic)
8010245c:	a1 80 16 13 80       	mov    0x80131680,%eax
80102461:	85 c0                	test   %eax,%eax
80102463:	74 08                	je     8010246d <lapicid+0x14>
  return lapic[ID] >> 24;
80102465:	8b 40 20             	mov    0x20(%eax),%eax
80102468:	c1 e8 18             	shr    $0x18,%eax
}
8010246b:	5d                   	pop    %ebp
8010246c:	c3                   	ret    
    return 0;
8010246d:	b8 00 00 00 00       	mov    $0x0,%eax
80102472:	eb f7                	jmp    8010246b <lapicid+0x12>

80102474 <lapiceoi>:
  if(lapic)
80102474:	83 3d 80 16 13 80 00 	cmpl   $0x0,0x80131680
8010247b:	74 14                	je     80102491 <lapiceoi+0x1d>
{
8010247d:	55                   	push   %ebp
8010247e:	89 e5                	mov    %esp,%ebp
    lapicw(EOI, 0);
80102480:	ba 00 00 00 00       	mov    $0x0,%edx
80102485:	b8 2c 00 00 00       	mov    $0x2c,%eax
8010248a:	e8 3e fe ff ff       	call   801022cd <lapicw>
}
8010248f:	5d                   	pop    %ebp
80102490:	c3                   	ret    
80102491:	f3 c3                	repz ret 

80102493 <microdelay>:
{
80102493:	55                   	push   %ebp
80102494:	89 e5                	mov    %esp,%ebp
}
80102496:	5d                   	pop    %ebp
80102497:	c3                   	ret    

80102498 <lapicstartap>:
{
80102498:	55                   	push   %ebp
80102499:	89 e5                	mov    %esp,%ebp
8010249b:	57                   	push   %edi
8010249c:	56                   	push   %esi
8010249d:	53                   	push   %ebx
8010249e:	8b 75 08             	mov    0x8(%ebp),%esi
801024a1:	8b 7d 0c             	mov    0xc(%ebp),%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801024a4:	b8 0f 00 00 00       	mov    $0xf,%eax
801024a9:	ba 70 00 00 00       	mov    $0x70,%edx
801024ae:	ee                   	out    %al,(%dx)
801024af:	b8 0a 00 00 00       	mov    $0xa,%eax
801024b4:	ba 71 00 00 00       	mov    $0x71,%edx
801024b9:	ee                   	out    %al,(%dx)
  wrv[0] = 0;
801024ba:	66 c7 05 67 04 00 80 	movw   $0x0,0x80000467
801024c1:	00 00 
  wrv[1] = addr >> 4;
801024c3:	89 f8                	mov    %edi,%eax
801024c5:	c1 e8 04             	shr    $0x4,%eax
801024c8:	66 a3 69 04 00 80    	mov    %ax,0x80000469
  lapicw(ICRHI, apicid<<24);
801024ce:	c1 e6 18             	shl    $0x18,%esi
801024d1:	89 f2                	mov    %esi,%edx
801024d3:	b8 c4 00 00 00       	mov    $0xc4,%eax
801024d8:	e8 f0 fd ff ff       	call   801022cd <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
801024dd:	ba 00 c5 00 00       	mov    $0xc500,%edx
801024e2:	b8 c0 00 00 00       	mov    $0xc0,%eax
801024e7:	e8 e1 fd ff ff       	call   801022cd <lapicw>
  lapicw(ICRLO, INIT | LEVEL);
801024ec:	ba 00 85 00 00       	mov    $0x8500,%edx
801024f1:	b8 c0 00 00 00       	mov    $0xc0,%eax
801024f6:	e8 d2 fd ff ff       	call   801022cd <lapicw>
  for(i = 0; i < 2; i++){
801024fb:	bb 00 00 00 00       	mov    $0x0,%ebx
80102500:	eb 21                	jmp    80102523 <lapicstartap+0x8b>
    lapicw(ICRHI, apicid<<24);
80102502:	89 f2                	mov    %esi,%edx
80102504:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102509:	e8 bf fd ff ff       	call   801022cd <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
8010250e:	89 fa                	mov    %edi,%edx
80102510:	c1 ea 0c             	shr    $0xc,%edx
80102513:	80 ce 06             	or     $0x6,%dh
80102516:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010251b:	e8 ad fd ff ff       	call   801022cd <lapicw>
  for(i = 0; i < 2; i++){
80102520:	83 c3 01             	add    $0x1,%ebx
80102523:	83 fb 01             	cmp    $0x1,%ebx
80102526:	7e da                	jle    80102502 <lapicstartap+0x6a>
}
80102528:	5b                   	pop    %ebx
80102529:	5e                   	pop    %esi
8010252a:	5f                   	pop    %edi
8010252b:	5d                   	pop    %ebp
8010252c:	c3                   	ret    

8010252d <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void
cmostime(struct rtcdate *r)
{
8010252d:	55                   	push   %ebp
8010252e:	89 e5                	mov    %esp,%ebp
80102530:	57                   	push   %edi
80102531:	56                   	push   %esi
80102532:	53                   	push   %ebx
80102533:	83 ec 3c             	sub    $0x3c,%esp
80102536:	8b 75 08             	mov    0x8(%ebp),%esi
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
80102539:	b8 0b 00 00 00       	mov    $0xb,%eax
8010253e:	e8 a2 fd ff ff       	call   801022e5 <cmos_read>

  bcd = (sb & (1 << 2)) == 0;
80102543:	83 e0 04             	and    $0x4,%eax
80102546:	89 c7                	mov    %eax,%edi

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
80102548:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010254b:	e8 a9 fd ff ff       	call   801022f9 <fill_rtcdate>
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
80102550:	b8 0a 00 00 00       	mov    $0xa,%eax
80102555:	e8 8b fd ff ff       	call   801022e5 <cmos_read>
8010255a:	a8 80                	test   $0x80,%al
8010255c:	75 ea                	jne    80102548 <cmostime+0x1b>
        continue;
    fill_rtcdate(&t2);
8010255e:	8d 5d b8             	lea    -0x48(%ebp),%ebx
80102561:	89 d8                	mov    %ebx,%eax
80102563:	e8 91 fd ff ff       	call   801022f9 <fill_rtcdate>
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
80102568:	83 ec 04             	sub    $0x4,%esp
8010256b:	6a 18                	push   $0x18
8010256d:	53                   	push   %ebx
8010256e:	8d 45 d0             	lea    -0x30(%ebp),%eax
80102571:	50                   	push   %eax
80102572:	e8 eb 17 00 00       	call   80103d62 <memcmp>
80102577:	83 c4 10             	add    $0x10,%esp
8010257a:	85 c0                	test   %eax,%eax
8010257c:	75 ca                	jne    80102548 <cmostime+0x1b>
      break;
  }

  // convert
  if(bcd) {
8010257e:	85 ff                	test   %edi,%edi
80102580:	0f 85 84 00 00 00    	jne    8010260a <cmostime+0xdd>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
80102586:	8b 55 d0             	mov    -0x30(%ebp),%edx
80102589:	89 d0                	mov    %edx,%eax
8010258b:	c1 e8 04             	shr    $0x4,%eax
8010258e:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102591:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102594:	83 e2 0f             	and    $0xf,%edx
80102597:	01 d0                	add    %edx,%eax
80102599:	89 45 d0             	mov    %eax,-0x30(%ebp)
    CONV(minute);
8010259c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
8010259f:	89 d0                	mov    %edx,%eax
801025a1:	c1 e8 04             	shr    $0x4,%eax
801025a4:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801025a7:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801025aa:	83 e2 0f             	and    $0xf,%edx
801025ad:	01 d0                	add    %edx,%eax
801025af:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    CONV(hour  );
801025b2:	8b 55 d8             	mov    -0x28(%ebp),%edx
801025b5:	89 d0                	mov    %edx,%eax
801025b7:	c1 e8 04             	shr    $0x4,%eax
801025ba:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801025bd:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801025c0:	83 e2 0f             	and    $0xf,%edx
801025c3:	01 d0                	add    %edx,%eax
801025c5:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(day   );
801025c8:	8b 55 dc             	mov    -0x24(%ebp),%edx
801025cb:	89 d0                	mov    %edx,%eax
801025cd:	c1 e8 04             	shr    $0x4,%eax
801025d0:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801025d3:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801025d6:	83 e2 0f             	and    $0xf,%edx
801025d9:	01 d0                	add    %edx,%eax
801025db:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(month );
801025de:	8b 55 e0             	mov    -0x20(%ebp),%edx
801025e1:	89 d0                	mov    %edx,%eax
801025e3:	c1 e8 04             	shr    $0x4,%eax
801025e6:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801025e9:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801025ec:	83 e2 0f             	and    $0xf,%edx
801025ef:	01 d0                	add    %edx,%eax
801025f1:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(year  );
801025f4:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801025f7:	89 d0                	mov    %edx,%eax
801025f9:	c1 e8 04             	shr    $0x4,%eax
801025fc:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801025ff:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102602:	83 e2 0f             	and    $0xf,%edx
80102605:	01 d0                	add    %edx,%eax
80102607:	89 45 e4             	mov    %eax,-0x1c(%ebp)
#undef     CONV
  }

  *r = t1;
8010260a:	8b 45 d0             	mov    -0x30(%ebp),%eax
8010260d:	89 06                	mov    %eax,(%esi)
8010260f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80102612:	89 46 04             	mov    %eax,0x4(%esi)
80102615:	8b 45 d8             	mov    -0x28(%ebp),%eax
80102618:	89 46 08             	mov    %eax,0x8(%esi)
8010261b:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010261e:	89 46 0c             	mov    %eax,0xc(%esi)
80102621:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102624:	89 46 10             	mov    %eax,0x10(%esi)
80102627:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010262a:	89 46 14             	mov    %eax,0x14(%esi)
  r->year += 2000;
8010262d:	81 46 14 d0 07 00 00 	addl   $0x7d0,0x14(%esi)
}
80102634:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102637:	5b                   	pop    %ebx
80102638:	5e                   	pop    %esi
80102639:	5f                   	pop    %edi
8010263a:	5d                   	pop    %ebp
8010263b:	c3                   	ret    

8010263c <read_head>:
}

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
8010263c:	55                   	push   %ebp
8010263d:	89 e5                	mov    %esp,%ebp
8010263f:	53                   	push   %ebx
80102640:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
80102643:	ff 35 d4 16 13 80    	pushl  0x801316d4
80102649:	ff 35 e4 16 13 80    	pushl  0x801316e4
8010264f:	e8 18 db ff ff       	call   8010016c <bread>
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
80102654:	8b 58 5c             	mov    0x5c(%eax),%ebx
80102657:	89 1d e8 16 13 80    	mov    %ebx,0x801316e8
  for (i = 0; i < log.lh.n; i++) {
8010265d:	83 c4 10             	add    $0x10,%esp
80102660:	ba 00 00 00 00       	mov    $0x0,%edx
80102665:	eb 0e                	jmp    80102675 <read_head+0x39>
    log.lh.block[i] = lh->block[i];
80102667:	8b 4c 90 60          	mov    0x60(%eax,%edx,4),%ecx
8010266b:	89 0c 95 ec 16 13 80 	mov    %ecx,-0x7fece914(,%edx,4)
  for (i = 0; i < log.lh.n; i++) {
80102672:	83 c2 01             	add    $0x1,%edx
80102675:	39 d3                	cmp    %edx,%ebx
80102677:	7f ee                	jg     80102667 <read_head+0x2b>
  }
  brelse(buf);
80102679:	83 ec 0c             	sub    $0xc,%esp
8010267c:	50                   	push   %eax
8010267d:	e8 53 db ff ff       	call   801001d5 <brelse>
}
80102682:	83 c4 10             	add    $0x10,%esp
80102685:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102688:	c9                   	leave  
80102689:	c3                   	ret    

8010268a <install_trans>:
{
8010268a:	55                   	push   %ebp
8010268b:	89 e5                	mov    %esp,%ebp
8010268d:	57                   	push   %edi
8010268e:	56                   	push   %esi
8010268f:	53                   	push   %ebx
80102690:	83 ec 0c             	sub    $0xc,%esp
  for (tail = 0; tail < log.lh.n; tail++) {
80102693:	bb 00 00 00 00       	mov    $0x0,%ebx
80102698:	eb 66                	jmp    80102700 <install_trans+0x76>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
8010269a:	89 d8                	mov    %ebx,%eax
8010269c:	03 05 d4 16 13 80    	add    0x801316d4,%eax
801026a2:	83 c0 01             	add    $0x1,%eax
801026a5:	83 ec 08             	sub    $0x8,%esp
801026a8:	50                   	push   %eax
801026a9:	ff 35 e4 16 13 80    	pushl  0x801316e4
801026af:	e8 b8 da ff ff       	call   8010016c <bread>
801026b4:	89 c7                	mov    %eax,%edi
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
801026b6:	83 c4 08             	add    $0x8,%esp
801026b9:	ff 34 9d ec 16 13 80 	pushl  -0x7fece914(,%ebx,4)
801026c0:	ff 35 e4 16 13 80    	pushl  0x801316e4
801026c6:	e8 a1 da ff ff       	call   8010016c <bread>
801026cb:	89 c6                	mov    %eax,%esi
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
801026cd:	8d 57 5c             	lea    0x5c(%edi),%edx
801026d0:	8d 40 5c             	lea    0x5c(%eax),%eax
801026d3:	83 c4 0c             	add    $0xc,%esp
801026d6:	68 00 02 00 00       	push   $0x200
801026db:	52                   	push   %edx
801026dc:	50                   	push   %eax
801026dd:	e8 b5 16 00 00       	call   80103d97 <memmove>
    bwrite(dbuf);  // write dst to disk
801026e2:	89 34 24             	mov    %esi,(%esp)
801026e5:	e8 b0 da ff ff       	call   8010019a <bwrite>
    brelse(lbuf);
801026ea:	89 3c 24             	mov    %edi,(%esp)
801026ed:	e8 e3 da ff ff       	call   801001d5 <brelse>
    brelse(dbuf);
801026f2:	89 34 24             	mov    %esi,(%esp)
801026f5:	e8 db da ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
801026fa:	83 c3 01             	add    $0x1,%ebx
801026fd:	83 c4 10             	add    $0x10,%esp
80102700:	39 1d e8 16 13 80    	cmp    %ebx,0x801316e8
80102706:	7f 92                	jg     8010269a <install_trans+0x10>
}
80102708:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010270b:	5b                   	pop    %ebx
8010270c:	5e                   	pop    %esi
8010270d:	5f                   	pop    %edi
8010270e:	5d                   	pop    %ebp
8010270f:	c3                   	ret    

80102710 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80102710:	55                   	push   %ebp
80102711:	89 e5                	mov    %esp,%ebp
80102713:	53                   	push   %ebx
80102714:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
80102717:	ff 35 d4 16 13 80    	pushl  0x801316d4
8010271d:	ff 35 e4 16 13 80    	pushl  0x801316e4
80102723:	e8 44 da ff ff       	call   8010016c <bread>
80102728:	89 c3                	mov    %eax,%ebx
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
8010272a:	8b 0d e8 16 13 80    	mov    0x801316e8,%ecx
80102730:	89 48 5c             	mov    %ecx,0x5c(%eax)
  for (i = 0; i < log.lh.n; i++) {
80102733:	83 c4 10             	add    $0x10,%esp
80102736:	b8 00 00 00 00       	mov    $0x0,%eax
8010273b:	eb 0e                	jmp    8010274b <write_head+0x3b>
    hb->block[i] = log.lh.block[i];
8010273d:	8b 14 85 ec 16 13 80 	mov    -0x7fece914(,%eax,4),%edx
80102744:	89 54 83 60          	mov    %edx,0x60(%ebx,%eax,4)
  for (i = 0; i < log.lh.n; i++) {
80102748:	83 c0 01             	add    $0x1,%eax
8010274b:	39 c1                	cmp    %eax,%ecx
8010274d:	7f ee                	jg     8010273d <write_head+0x2d>
  }
  bwrite(buf);
8010274f:	83 ec 0c             	sub    $0xc,%esp
80102752:	53                   	push   %ebx
80102753:	e8 42 da ff ff       	call   8010019a <bwrite>
  brelse(buf);
80102758:	89 1c 24             	mov    %ebx,(%esp)
8010275b:	e8 75 da ff ff       	call   801001d5 <brelse>
}
80102760:	83 c4 10             	add    $0x10,%esp
80102763:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102766:	c9                   	leave  
80102767:	c3                   	ret    

80102768 <recover_from_log>:

static void
recover_from_log(void)
{
80102768:	55                   	push   %ebp
80102769:	89 e5                	mov    %esp,%ebp
8010276b:	83 ec 08             	sub    $0x8,%esp
  read_head();
8010276e:	e8 c9 fe ff ff       	call   8010263c <read_head>
  install_trans(); // if committed, copy from log to disk
80102773:	e8 12 ff ff ff       	call   8010268a <install_trans>
  log.lh.n = 0;
80102778:	c7 05 e8 16 13 80 00 	movl   $0x0,0x801316e8
8010277f:	00 00 00 
  write_head(); // clear the log
80102782:	e8 89 ff ff ff       	call   80102710 <write_head>
}
80102787:	c9                   	leave  
80102788:	c3                   	ret    

80102789 <write_log>:
}

// Copy modified blocks from cache to log.
static void
write_log(void)
{
80102789:	55                   	push   %ebp
8010278a:	89 e5                	mov    %esp,%ebp
8010278c:	57                   	push   %edi
8010278d:	56                   	push   %esi
8010278e:	53                   	push   %ebx
8010278f:	83 ec 0c             	sub    $0xc,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80102792:	bb 00 00 00 00       	mov    $0x0,%ebx
80102797:	eb 66                	jmp    801027ff <write_log+0x76>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
80102799:	89 d8                	mov    %ebx,%eax
8010279b:	03 05 d4 16 13 80    	add    0x801316d4,%eax
801027a1:	83 c0 01             	add    $0x1,%eax
801027a4:	83 ec 08             	sub    $0x8,%esp
801027a7:	50                   	push   %eax
801027a8:	ff 35 e4 16 13 80    	pushl  0x801316e4
801027ae:	e8 b9 d9 ff ff       	call   8010016c <bread>
801027b3:	89 c6                	mov    %eax,%esi
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
801027b5:	83 c4 08             	add    $0x8,%esp
801027b8:	ff 34 9d ec 16 13 80 	pushl  -0x7fece914(,%ebx,4)
801027bf:	ff 35 e4 16 13 80    	pushl  0x801316e4
801027c5:	e8 a2 d9 ff ff       	call   8010016c <bread>
801027ca:	89 c7                	mov    %eax,%edi
    memmove(to->data, from->data, BSIZE);
801027cc:	8d 50 5c             	lea    0x5c(%eax),%edx
801027cf:	8d 46 5c             	lea    0x5c(%esi),%eax
801027d2:	83 c4 0c             	add    $0xc,%esp
801027d5:	68 00 02 00 00       	push   $0x200
801027da:	52                   	push   %edx
801027db:	50                   	push   %eax
801027dc:	e8 b6 15 00 00       	call   80103d97 <memmove>
    bwrite(to);  // write the log
801027e1:	89 34 24             	mov    %esi,(%esp)
801027e4:	e8 b1 d9 ff ff       	call   8010019a <bwrite>
    brelse(from);
801027e9:	89 3c 24             	mov    %edi,(%esp)
801027ec:	e8 e4 d9 ff ff       	call   801001d5 <brelse>
    brelse(to);
801027f1:	89 34 24             	mov    %esi,(%esp)
801027f4:	e8 dc d9 ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
801027f9:	83 c3 01             	add    $0x1,%ebx
801027fc:	83 c4 10             	add    $0x10,%esp
801027ff:	39 1d e8 16 13 80    	cmp    %ebx,0x801316e8
80102805:	7f 92                	jg     80102799 <write_log+0x10>
  }
}
80102807:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010280a:	5b                   	pop    %ebx
8010280b:	5e                   	pop    %esi
8010280c:	5f                   	pop    %edi
8010280d:	5d                   	pop    %ebp
8010280e:	c3                   	ret    

8010280f <commit>:

static void
commit()
{
  if (log.lh.n > 0) {
8010280f:	83 3d e8 16 13 80 00 	cmpl   $0x0,0x801316e8
80102816:	7e 26                	jle    8010283e <commit+0x2f>
{
80102818:	55                   	push   %ebp
80102819:	89 e5                	mov    %esp,%ebp
8010281b:	83 ec 08             	sub    $0x8,%esp
    write_log();     // Write modified blocks from cache to log
8010281e:	e8 66 ff ff ff       	call   80102789 <write_log>
    write_head();    // Write header to disk -- the real commit
80102823:	e8 e8 fe ff ff       	call   80102710 <write_head>
    install_trans(); // Now install writes to home locations
80102828:	e8 5d fe ff ff       	call   8010268a <install_trans>
    log.lh.n = 0;
8010282d:	c7 05 e8 16 13 80 00 	movl   $0x0,0x801316e8
80102834:	00 00 00 
    write_head();    // Erase the transaction from the log
80102837:	e8 d4 fe ff ff       	call   80102710 <write_head>
  }
}
8010283c:	c9                   	leave  
8010283d:	c3                   	ret    
8010283e:	f3 c3                	repz ret 

80102840 <initlog>:
{
80102840:	55                   	push   %ebp
80102841:	89 e5                	mov    %esp,%ebp
80102843:	53                   	push   %ebx
80102844:	83 ec 2c             	sub    $0x2c,%esp
80102847:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&log.lock, "log");
8010284a:	68 20 6a 10 80       	push   $0x80106a20
8010284f:	68 a0 16 13 80       	push   $0x801316a0
80102854:	e8 db 12 00 00       	call   80103b34 <initlock>
  readsb(dev, &sb);
80102859:	83 c4 08             	add    $0x8,%esp
8010285c:	8d 45 dc             	lea    -0x24(%ebp),%eax
8010285f:	50                   	push   %eax
80102860:	53                   	push   %ebx
80102861:	e8 d0 e9 ff ff       	call   80101236 <readsb>
  log.start = sb.logstart;
80102866:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102869:	a3 d4 16 13 80       	mov    %eax,0x801316d4
  log.size = sb.nlog;
8010286e:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102871:	a3 d8 16 13 80       	mov    %eax,0x801316d8
  log.dev = dev;
80102876:	89 1d e4 16 13 80    	mov    %ebx,0x801316e4
  recover_from_log();
8010287c:	e8 e7 fe ff ff       	call   80102768 <recover_from_log>
}
80102881:	83 c4 10             	add    $0x10,%esp
80102884:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102887:	c9                   	leave  
80102888:	c3                   	ret    

80102889 <begin_op>:
{
80102889:	55                   	push   %ebp
8010288a:	89 e5                	mov    %esp,%ebp
8010288c:	83 ec 14             	sub    $0x14,%esp
  acquire(&log.lock);
8010288f:	68 a0 16 13 80       	push   $0x801316a0
80102894:	e8 d7 13 00 00       	call   80103c70 <acquire>
80102899:	83 c4 10             	add    $0x10,%esp
8010289c:	eb 15                	jmp    801028b3 <begin_op+0x2a>
      sleep(&log, &log.lock);
8010289e:	83 ec 08             	sub    $0x8,%esp
801028a1:	68 a0 16 13 80       	push   $0x801316a0
801028a6:	68 a0 16 13 80       	push   $0x801316a0
801028ab:	e8 c5 0e 00 00       	call   80103775 <sleep>
801028b0:	83 c4 10             	add    $0x10,%esp
    if(log.committing){
801028b3:	83 3d e0 16 13 80 00 	cmpl   $0x0,0x801316e0
801028ba:	75 e2                	jne    8010289e <begin_op+0x15>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
801028bc:	a1 dc 16 13 80       	mov    0x801316dc,%eax
801028c1:	83 c0 01             	add    $0x1,%eax
801028c4:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801028c7:	8d 14 09             	lea    (%ecx,%ecx,1),%edx
801028ca:	03 15 e8 16 13 80    	add    0x801316e8,%edx
801028d0:	83 fa 1e             	cmp    $0x1e,%edx
801028d3:	7e 17                	jle    801028ec <begin_op+0x63>
      sleep(&log, &log.lock);
801028d5:	83 ec 08             	sub    $0x8,%esp
801028d8:	68 a0 16 13 80       	push   $0x801316a0
801028dd:	68 a0 16 13 80       	push   $0x801316a0
801028e2:	e8 8e 0e 00 00       	call   80103775 <sleep>
801028e7:	83 c4 10             	add    $0x10,%esp
801028ea:	eb c7                	jmp    801028b3 <begin_op+0x2a>
      log.outstanding += 1;
801028ec:	a3 dc 16 13 80       	mov    %eax,0x801316dc
      release(&log.lock);
801028f1:	83 ec 0c             	sub    $0xc,%esp
801028f4:	68 a0 16 13 80       	push   $0x801316a0
801028f9:	e8 d7 13 00 00       	call   80103cd5 <release>
}
801028fe:	83 c4 10             	add    $0x10,%esp
80102901:	c9                   	leave  
80102902:	c3                   	ret    

80102903 <end_op>:
{
80102903:	55                   	push   %ebp
80102904:	89 e5                	mov    %esp,%ebp
80102906:	53                   	push   %ebx
80102907:	83 ec 10             	sub    $0x10,%esp
  acquire(&log.lock);
8010290a:	68 a0 16 13 80       	push   $0x801316a0
8010290f:	e8 5c 13 00 00       	call   80103c70 <acquire>
  log.outstanding -= 1;
80102914:	a1 dc 16 13 80       	mov    0x801316dc,%eax
80102919:	83 e8 01             	sub    $0x1,%eax
8010291c:	a3 dc 16 13 80       	mov    %eax,0x801316dc
  if(log.committing)
80102921:	8b 1d e0 16 13 80    	mov    0x801316e0,%ebx
80102927:	83 c4 10             	add    $0x10,%esp
8010292a:	85 db                	test   %ebx,%ebx
8010292c:	75 2c                	jne    8010295a <end_op+0x57>
  if(log.outstanding == 0){
8010292e:	85 c0                	test   %eax,%eax
80102930:	75 35                	jne    80102967 <end_op+0x64>
    log.committing = 1;
80102932:	c7 05 e0 16 13 80 01 	movl   $0x1,0x801316e0
80102939:	00 00 00 
    do_commit = 1;
8010293c:	bb 01 00 00 00       	mov    $0x1,%ebx
  release(&log.lock);
80102941:	83 ec 0c             	sub    $0xc,%esp
80102944:	68 a0 16 13 80       	push   $0x801316a0
80102949:	e8 87 13 00 00       	call   80103cd5 <release>
  if(do_commit){
8010294e:	83 c4 10             	add    $0x10,%esp
80102951:	85 db                	test   %ebx,%ebx
80102953:	75 24                	jne    80102979 <end_op+0x76>
}
80102955:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102958:	c9                   	leave  
80102959:	c3                   	ret    
    panic("log.committing");
8010295a:	83 ec 0c             	sub    $0xc,%esp
8010295d:	68 24 6a 10 80       	push   $0x80106a24
80102962:	e8 e1 d9 ff ff       	call   80100348 <panic>
    wakeup(&log);
80102967:	83 ec 0c             	sub    $0xc,%esp
8010296a:	68 a0 16 13 80       	push   $0x801316a0
8010296f:	e8 66 0f 00 00       	call   801038da <wakeup>
80102974:	83 c4 10             	add    $0x10,%esp
80102977:	eb c8                	jmp    80102941 <end_op+0x3e>
    commit();
80102979:	e8 91 fe ff ff       	call   8010280f <commit>
    acquire(&log.lock);
8010297e:	83 ec 0c             	sub    $0xc,%esp
80102981:	68 a0 16 13 80       	push   $0x801316a0
80102986:	e8 e5 12 00 00       	call   80103c70 <acquire>
    log.committing = 0;
8010298b:	c7 05 e0 16 13 80 00 	movl   $0x0,0x801316e0
80102992:	00 00 00 
    wakeup(&log);
80102995:	c7 04 24 a0 16 13 80 	movl   $0x801316a0,(%esp)
8010299c:	e8 39 0f 00 00       	call   801038da <wakeup>
    release(&log.lock);
801029a1:	c7 04 24 a0 16 13 80 	movl   $0x801316a0,(%esp)
801029a8:	e8 28 13 00 00       	call   80103cd5 <release>
801029ad:	83 c4 10             	add    $0x10,%esp
}
801029b0:	eb a3                	jmp    80102955 <end_op+0x52>

801029b2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
801029b2:	55                   	push   %ebp
801029b3:	89 e5                	mov    %esp,%ebp
801029b5:	53                   	push   %ebx
801029b6:	83 ec 04             	sub    $0x4,%esp
801029b9:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
801029bc:	8b 15 e8 16 13 80    	mov    0x801316e8,%edx
801029c2:	83 fa 1d             	cmp    $0x1d,%edx
801029c5:	7f 45                	jg     80102a0c <log_write+0x5a>
801029c7:	a1 d8 16 13 80       	mov    0x801316d8,%eax
801029cc:	83 e8 01             	sub    $0x1,%eax
801029cf:	39 c2                	cmp    %eax,%edx
801029d1:	7d 39                	jge    80102a0c <log_write+0x5a>
    panic("too big a transaction");
  if (log.outstanding < 1)
801029d3:	83 3d dc 16 13 80 00 	cmpl   $0x0,0x801316dc
801029da:	7e 3d                	jle    80102a19 <log_write+0x67>
    panic("log_write outside of trans");

  acquire(&log.lock);
801029dc:	83 ec 0c             	sub    $0xc,%esp
801029df:	68 a0 16 13 80       	push   $0x801316a0
801029e4:	e8 87 12 00 00       	call   80103c70 <acquire>
  for (i = 0; i < log.lh.n; i++) {
801029e9:	83 c4 10             	add    $0x10,%esp
801029ec:	b8 00 00 00 00       	mov    $0x0,%eax
801029f1:	8b 15 e8 16 13 80    	mov    0x801316e8,%edx
801029f7:	39 c2                	cmp    %eax,%edx
801029f9:	7e 2b                	jle    80102a26 <log_write+0x74>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
801029fb:	8b 4b 08             	mov    0x8(%ebx),%ecx
801029fe:	39 0c 85 ec 16 13 80 	cmp    %ecx,-0x7fece914(,%eax,4)
80102a05:	74 1f                	je     80102a26 <log_write+0x74>
  for (i = 0; i < log.lh.n; i++) {
80102a07:	83 c0 01             	add    $0x1,%eax
80102a0a:	eb e5                	jmp    801029f1 <log_write+0x3f>
    panic("too big a transaction");
80102a0c:	83 ec 0c             	sub    $0xc,%esp
80102a0f:	68 33 6a 10 80       	push   $0x80106a33
80102a14:	e8 2f d9 ff ff       	call   80100348 <panic>
    panic("log_write outside of trans");
80102a19:	83 ec 0c             	sub    $0xc,%esp
80102a1c:	68 49 6a 10 80       	push   $0x80106a49
80102a21:	e8 22 d9 ff ff       	call   80100348 <panic>
      break;
  }
  log.lh.block[i] = b->blockno;
80102a26:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102a29:	89 0c 85 ec 16 13 80 	mov    %ecx,-0x7fece914(,%eax,4)
  if (i == log.lh.n)
80102a30:	39 c2                	cmp    %eax,%edx
80102a32:	74 18                	je     80102a4c <log_write+0x9a>
    log.lh.n++;
  b->flags |= B_DIRTY; // prevent eviction
80102a34:	83 0b 04             	orl    $0x4,(%ebx)
  release(&log.lock);
80102a37:	83 ec 0c             	sub    $0xc,%esp
80102a3a:	68 a0 16 13 80       	push   $0x801316a0
80102a3f:	e8 91 12 00 00       	call   80103cd5 <release>
}
80102a44:	83 c4 10             	add    $0x10,%esp
80102a47:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102a4a:	c9                   	leave  
80102a4b:	c3                   	ret    
    log.lh.n++;
80102a4c:	83 c2 01             	add    $0x1,%edx
80102a4f:	89 15 e8 16 13 80    	mov    %edx,0x801316e8
80102a55:	eb dd                	jmp    80102a34 <log_write+0x82>

80102a57 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80102a57:	55                   	push   %ebp
80102a58:	89 e5                	mov    %esp,%ebp
80102a5a:	53                   	push   %ebx
80102a5b:	83 ec 08             	sub    $0x8,%esp

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80102a5e:	68 8a 00 00 00       	push   $0x8a
80102a63:	68 8c 94 10 80       	push   $0x8010948c
80102a68:	68 00 70 00 80       	push   $0x80007000
80102a6d:	e8 25 13 00 00       	call   80103d97 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80102a72:	83 c4 10             	add    $0x10,%esp
80102a75:	bb a0 17 13 80       	mov    $0x801317a0,%ebx
80102a7a:	eb 06                	jmp    80102a82 <startothers+0x2b>
80102a7c:	81 c3 b0 00 00 00    	add    $0xb0,%ebx
80102a82:	69 05 20 1d 13 80 b0 	imul   $0xb0,0x80131d20,%eax
80102a89:	00 00 00 
80102a8c:	05 a0 17 13 80       	add    $0x801317a0,%eax
80102a91:	39 d8                	cmp    %ebx,%eax
80102a93:	76 4c                	jbe    80102ae1 <startothers+0x8a>
    if(c == mycpu())  // We've started already.
80102a95:	e8 c0 07 00 00       	call   8010325a <mycpu>
80102a9a:	39 d8                	cmp    %ebx,%eax
80102a9c:	74 de                	je     80102a7c <startothers+0x25>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80102a9e:	e8 49 f6 ff ff       	call   801020ec <kalloc>
    *(void**)(code-4) = stack + KSTACKSIZE;
80102aa3:	05 00 10 00 00       	add    $0x1000,%eax
80102aa8:	a3 fc 6f 00 80       	mov    %eax,0x80006ffc
    *(void(**)(void))(code-8) = mpenter;
80102aad:	c7 05 f8 6f 00 80 25 	movl   $0x80102b25,0x80006ff8
80102ab4:	2b 10 80 
    *(int**)(code-12) = (void *) V2P(entrypgdir);
80102ab7:	c7 05 f4 6f 00 80 00 	movl   $0x108000,0x80006ff4
80102abe:	80 10 00 

    lapicstartap(c->apicid, V2P(code));
80102ac1:	83 ec 08             	sub    $0x8,%esp
80102ac4:	68 00 70 00 00       	push   $0x7000
80102ac9:	0f b6 03             	movzbl (%ebx),%eax
80102acc:	50                   	push   %eax
80102acd:	e8 c6 f9 ff ff       	call   80102498 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80102ad2:	83 c4 10             	add    $0x10,%esp
80102ad5:	8b 83 a0 00 00 00    	mov    0xa0(%ebx),%eax
80102adb:	85 c0                	test   %eax,%eax
80102add:	74 f6                	je     80102ad5 <startothers+0x7e>
80102adf:	eb 9b                	jmp    80102a7c <startothers+0x25>
      ;
  }
}
80102ae1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102ae4:	c9                   	leave  
80102ae5:	c3                   	ret    

80102ae6 <mpmain>:
{
80102ae6:	55                   	push   %ebp
80102ae7:	89 e5                	mov    %esp,%ebp
80102ae9:	53                   	push   %ebx
80102aea:	83 ec 04             	sub    $0x4,%esp
  cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
80102aed:	e8 c4 07 00 00       	call   801032b6 <cpuid>
80102af2:	89 c3                	mov    %eax,%ebx
80102af4:	e8 bd 07 00 00       	call   801032b6 <cpuid>
80102af9:	83 ec 04             	sub    $0x4,%esp
80102afc:	53                   	push   %ebx
80102afd:	50                   	push   %eax
80102afe:	68 64 6a 10 80       	push   $0x80106a64
80102b03:	e8 03 db ff ff       	call   8010060b <cprintf>
  idtinit();       // load idt register
80102b08:	e8 e1 23 00 00       	call   80104eee <idtinit>
  xchg(&(mycpu()->started), 1); // tell startothers() we're up
80102b0d:	e8 48 07 00 00       	call   8010325a <mycpu>
80102b12:	89 c2                	mov    %eax,%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80102b14:	b8 01 00 00 00       	mov    $0x1,%eax
80102b19:	f0 87 82 a0 00 00 00 	lock xchg %eax,0xa0(%edx)
  scheduler();     // start running processes
80102b20:	e8 2b 0a 00 00       	call   80103550 <scheduler>

80102b25 <mpenter>:
{
80102b25:	55                   	push   %ebp
80102b26:	89 e5                	mov    %esp,%ebp
80102b28:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
80102b2b:	e8 c7 33 00 00       	call   80105ef7 <switchkvm>
  seginit();
80102b30:	e8 76 32 00 00       	call   80105dab <seginit>
  lapicinit();
80102b35:	e8 15 f8 ff ff       	call   8010234f <lapicinit>
  mpmain();
80102b3a:	e8 a7 ff ff ff       	call   80102ae6 <mpmain>

80102b3f <main>:
{
80102b3f:	8d 4c 24 04          	lea    0x4(%esp),%ecx
80102b43:	83 e4 f0             	and    $0xfffffff0,%esp
80102b46:	ff 71 fc             	pushl  -0x4(%ecx)
80102b49:	55                   	push   %ebp
80102b4a:	89 e5                	mov    %esp,%ebp
80102b4c:	51                   	push   %ecx
80102b4d:	83 ec 0c             	sub    $0xc,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80102b50:	68 00 00 40 80       	push   $0x80400000
80102b55:	68 c8 44 13 80       	push   $0x801344c8
80102b5a:	e8 0a f5 ff ff       	call   80102069 <kinit1>
  kvmalloc();      // kernel page table
80102b5f:	e8 20 38 00 00       	call   80106384 <kvmalloc>
  mpinit();        // detect other processors
80102b64:	e8 c9 01 00 00       	call   80102d32 <mpinit>
  lapicinit();     // interrupt controller
80102b69:	e8 e1 f7 ff ff       	call   8010234f <lapicinit>
  seginit();       // segment descriptors
80102b6e:	e8 38 32 00 00       	call   80105dab <seginit>
  picinit();       // disable pic
80102b73:	e8 82 02 00 00       	call   80102dfa <picinit>
  ioapicinit();    // another interrupt controller
80102b78:	e8 7d f3 ff ff       	call   80101efa <ioapicinit>
  consoleinit();   // console hardware
80102b7d:	e8 0c dd ff ff       	call   8010088e <consoleinit>
  uartinit();      // serial port
80102b82:	e8 15 26 00 00       	call   8010519c <uartinit>
  pinit();         // process table
80102b87:	e8 b4 06 00 00       	call   80103240 <pinit>
  tvinit();        // trap vectors
80102b8c:	e8 ac 22 00 00       	call   80104e3d <tvinit>
  binit();         // buffer cache
80102b91:	e8 5e d5 ff ff       	call   801000f4 <binit>
  fileinit();      // file table
80102b96:	e8 78 e0 ff ff       	call   80100c13 <fileinit>
  ideinit();       // disk 
80102b9b:	e8 60 f1 ff ff       	call   80101d00 <ideinit>
  startothers();   // start other processors
80102ba0:	e8 b2 fe ff ff       	call   80102a57 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80102ba5:	83 c4 08             	add    $0x8,%esp
80102ba8:	68 00 00 00 8e       	push   $0x8e000000
80102bad:	68 00 00 40 80       	push   $0x80400000
80102bb2:	e8 e4 f4 ff ff       	call   8010209b <kinit2>
  userinit();      // first user process
80102bb7:	e8 39 07 00 00       	call   801032f5 <userinit>
  mpmain();        // finish this processor's setup
80102bbc:	e8 25 ff ff ff       	call   80102ae6 <mpmain>

80102bc1 <sum>:
int ncpu;
uchar ioapicid;

static uchar
sum(uchar *addr, int len)
{
80102bc1:	55                   	push   %ebp
80102bc2:	89 e5                	mov    %esp,%ebp
80102bc4:	56                   	push   %esi
80102bc5:	53                   	push   %ebx
  int i, sum;

  sum = 0;
80102bc6:	bb 00 00 00 00       	mov    $0x0,%ebx
  for(i=0; i<len; i++)
80102bcb:	b9 00 00 00 00       	mov    $0x0,%ecx
80102bd0:	eb 09                	jmp    80102bdb <sum+0x1a>
    sum += addr[i];
80102bd2:	0f b6 34 08          	movzbl (%eax,%ecx,1),%esi
80102bd6:	01 f3                	add    %esi,%ebx
  for(i=0; i<len; i++)
80102bd8:	83 c1 01             	add    $0x1,%ecx
80102bdb:	39 d1                	cmp    %edx,%ecx
80102bdd:	7c f3                	jl     80102bd2 <sum+0x11>
  return sum;
}
80102bdf:	89 d8                	mov    %ebx,%eax
80102be1:	5b                   	pop    %ebx
80102be2:	5e                   	pop    %esi
80102be3:	5d                   	pop    %ebp
80102be4:	c3                   	ret    

80102be5 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80102be5:	55                   	push   %ebp
80102be6:	89 e5                	mov    %esp,%ebp
80102be8:	56                   	push   %esi
80102be9:	53                   	push   %ebx
  uchar *e, *p, *addr;

  addr = P2V(a);
80102bea:	8d b0 00 00 00 80    	lea    -0x80000000(%eax),%esi
80102bf0:	89 f3                	mov    %esi,%ebx
  e = addr+len;
80102bf2:	01 d6                	add    %edx,%esi
  for(p = addr; p < e; p += sizeof(struct mp))
80102bf4:	eb 03                	jmp    80102bf9 <mpsearch1+0x14>
80102bf6:	83 c3 10             	add    $0x10,%ebx
80102bf9:	39 f3                	cmp    %esi,%ebx
80102bfb:	73 29                	jae    80102c26 <mpsearch1+0x41>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80102bfd:	83 ec 04             	sub    $0x4,%esp
80102c00:	6a 04                	push   $0x4
80102c02:	68 78 6a 10 80       	push   $0x80106a78
80102c07:	53                   	push   %ebx
80102c08:	e8 55 11 00 00       	call   80103d62 <memcmp>
80102c0d:	83 c4 10             	add    $0x10,%esp
80102c10:	85 c0                	test   %eax,%eax
80102c12:	75 e2                	jne    80102bf6 <mpsearch1+0x11>
80102c14:	ba 10 00 00 00       	mov    $0x10,%edx
80102c19:	89 d8                	mov    %ebx,%eax
80102c1b:	e8 a1 ff ff ff       	call   80102bc1 <sum>
80102c20:	84 c0                	test   %al,%al
80102c22:	75 d2                	jne    80102bf6 <mpsearch1+0x11>
80102c24:	eb 05                	jmp    80102c2b <mpsearch1+0x46>
      return (struct mp*)p;
  return 0;
80102c26:	bb 00 00 00 00       	mov    $0x0,%ebx
}
80102c2b:	89 d8                	mov    %ebx,%eax
80102c2d:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102c30:	5b                   	pop    %ebx
80102c31:	5e                   	pop    %esi
80102c32:	5d                   	pop    %ebp
80102c33:	c3                   	ret    

80102c34 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80102c34:	55                   	push   %ebp
80102c35:	89 e5                	mov    %esp,%ebp
80102c37:	83 ec 08             	sub    $0x8,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80102c3a:	0f b6 05 0f 04 00 80 	movzbl 0x8000040f,%eax
80102c41:	c1 e0 08             	shl    $0x8,%eax
80102c44:	0f b6 15 0e 04 00 80 	movzbl 0x8000040e,%edx
80102c4b:	09 d0                	or     %edx,%eax
80102c4d:	c1 e0 04             	shl    $0x4,%eax
80102c50:	85 c0                	test   %eax,%eax
80102c52:	74 1f                	je     80102c73 <mpsearch+0x3f>
    if((mp = mpsearch1(p, 1024)))
80102c54:	ba 00 04 00 00       	mov    $0x400,%edx
80102c59:	e8 87 ff ff ff       	call   80102be5 <mpsearch1>
80102c5e:	85 c0                	test   %eax,%eax
80102c60:	75 0f                	jne    80102c71 <mpsearch+0x3d>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1(p-1024, 1024)))
      return mp;
  }
  return mpsearch1(0xF0000, 0x10000);
80102c62:	ba 00 00 01 00       	mov    $0x10000,%edx
80102c67:	b8 00 00 0f 00       	mov    $0xf0000,%eax
80102c6c:	e8 74 ff ff ff       	call   80102be5 <mpsearch1>
}
80102c71:	c9                   	leave  
80102c72:	c3                   	ret    
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80102c73:	0f b6 05 14 04 00 80 	movzbl 0x80000414,%eax
80102c7a:	c1 e0 08             	shl    $0x8,%eax
80102c7d:	0f b6 15 13 04 00 80 	movzbl 0x80000413,%edx
80102c84:	09 d0                	or     %edx,%eax
80102c86:	c1 e0 0a             	shl    $0xa,%eax
    if((mp = mpsearch1(p-1024, 1024)))
80102c89:	2d 00 04 00 00       	sub    $0x400,%eax
80102c8e:	ba 00 04 00 00       	mov    $0x400,%edx
80102c93:	e8 4d ff ff ff       	call   80102be5 <mpsearch1>
80102c98:	85 c0                	test   %eax,%eax
80102c9a:	75 d5                	jne    80102c71 <mpsearch+0x3d>
80102c9c:	eb c4                	jmp    80102c62 <mpsearch+0x2e>

80102c9e <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80102c9e:	55                   	push   %ebp
80102c9f:	89 e5                	mov    %esp,%ebp
80102ca1:	57                   	push   %edi
80102ca2:	56                   	push   %esi
80102ca3:	53                   	push   %ebx
80102ca4:	83 ec 1c             	sub    $0x1c,%esp
80102ca7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80102caa:	e8 85 ff ff ff       	call   80102c34 <mpsearch>
80102caf:	85 c0                	test   %eax,%eax
80102cb1:	74 5c                	je     80102d0f <mpconfig+0x71>
80102cb3:	89 c7                	mov    %eax,%edi
80102cb5:	8b 58 04             	mov    0x4(%eax),%ebx
80102cb8:	85 db                	test   %ebx,%ebx
80102cba:	74 5a                	je     80102d16 <mpconfig+0x78>
    return 0;
  conf = (struct mpconf*) P2V((uint) mp->physaddr);
80102cbc:	8d b3 00 00 00 80    	lea    -0x80000000(%ebx),%esi
  if(memcmp(conf, "PCMP", 4) != 0)
80102cc2:	83 ec 04             	sub    $0x4,%esp
80102cc5:	6a 04                	push   $0x4
80102cc7:	68 7d 6a 10 80       	push   $0x80106a7d
80102ccc:	56                   	push   %esi
80102ccd:	e8 90 10 00 00       	call   80103d62 <memcmp>
80102cd2:	83 c4 10             	add    $0x10,%esp
80102cd5:	85 c0                	test   %eax,%eax
80102cd7:	75 44                	jne    80102d1d <mpconfig+0x7f>
    return 0;
  if(conf->version != 1 && conf->version != 4)
80102cd9:	0f b6 83 06 00 00 80 	movzbl -0x7ffffffa(%ebx),%eax
80102ce0:	3c 01                	cmp    $0x1,%al
80102ce2:	0f 95 c2             	setne  %dl
80102ce5:	3c 04                	cmp    $0x4,%al
80102ce7:	0f 95 c0             	setne  %al
80102cea:	84 c2                	test   %al,%dl
80102cec:	75 36                	jne    80102d24 <mpconfig+0x86>
    return 0;
  if(sum((uchar*)conf, conf->length) != 0)
80102cee:	0f b7 93 04 00 00 80 	movzwl -0x7ffffffc(%ebx),%edx
80102cf5:	89 f0                	mov    %esi,%eax
80102cf7:	e8 c5 fe ff ff       	call   80102bc1 <sum>
80102cfc:	84 c0                	test   %al,%al
80102cfe:	75 2b                	jne    80102d2b <mpconfig+0x8d>
    return 0;
  *pmp = mp;
80102d00:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102d03:	89 38                	mov    %edi,(%eax)
  return conf;
}
80102d05:	89 f0                	mov    %esi,%eax
80102d07:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102d0a:	5b                   	pop    %ebx
80102d0b:	5e                   	pop    %esi
80102d0c:	5f                   	pop    %edi
80102d0d:	5d                   	pop    %ebp
80102d0e:	c3                   	ret    
    return 0;
80102d0f:	be 00 00 00 00       	mov    $0x0,%esi
80102d14:	eb ef                	jmp    80102d05 <mpconfig+0x67>
80102d16:	be 00 00 00 00       	mov    $0x0,%esi
80102d1b:	eb e8                	jmp    80102d05 <mpconfig+0x67>
    return 0;
80102d1d:	be 00 00 00 00       	mov    $0x0,%esi
80102d22:	eb e1                	jmp    80102d05 <mpconfig+0x67>
    return 0;
80102d24:	be 00 00 00 00       	mov    $0x0,%esi
80102d29:	eb da                	jmp    80102d05 <mpconfig+0x67>
    return 0;
80102d2b:	be 00 00 00 00       	mov    $0x0,%esi
80102d30:	eb d3                	jmp    80102d05 <mpconfig+0x67>

80102d32 <mpinit>:

void
mpinit(void)
{
80102d32:	55                   	push   %ebp
80102d33:	89 e5                	mov    %esp,%ebp
80102d35:	57                   	push   %edi
80102d36:	56                   	push   %esi
80102d37:	53                   	push   %ebx
80102d38:	83 ec 1c             	sub    $0x1c,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  if((conf = mpconfig(&mp)) == 0)
80102d3b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80102d3e:	e8 5b ff ff ff       	call   80102c9e <mpconfig>
80102d43:	85 c0                	test   %eax,%eax
80102d45:	74 19                	je     80102d60 <mpinit+0x2e>
    panic("Expect to run on an SMP");
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
80102d47:	8b 50 24             	mov    0x24(%eax),%edx
80102d4a:	89 15 80 16 13 80    	mov    %edx,0x80131680
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102d50:	8d 50 2c             	lea    0x2c(%eax),%edx
80102d53:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
80102d57:	01 c1                	add    %eax,%ecx
  ismp = 1;
80102d59:	bb 01 00 00 00       	mov    $0x1,%ebx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102d5e:	eb 34                	jmp    80102d94 <mpinit+0x62>
    panic("Expect to run on an SMP");
80102d60:	83 ec 0c             	sub    $0xc,%esp
80102d63:	68 82 6a 10 80       	push   $0x80106a82
80102d68:	e8 db d5 ff ff       	call   80100348 <panic>
    switch(*p){
    case MPPROC:
      proc = (struct mpproc*)p;
      if(ncpu < NCPU) {
80102d6d:	8b 35 20 1d 13 80    	mov    0x80131d20,%esi
80102d73:	83 fe 07             	cmp    $0x7,%esi
80102d76:	7f 19                	jg     80102d91 <mpinit+0x5f>
        cpus[ncpu].apicid = proc->apicid;  // apicid may differ from ncpu
80102d78:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102d7c:	69 fe b0 00 00 00    	imul   $0xb0,%esi,%edi
80102d82:	88 87 a0 17 13 80    	mov    %al,-0x7fece860(%edi)
        ncpu++;
80102d88:	83 c6 01             	add    $0x1,%esi
80102d8b:	89 35 20 1d 13 80    	mov    %esi,0x80131d20
      }
      p += sizeof(struct mpproc);
80102d91:	83 c2 14             	add    $0x14,%edx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102d94:	39 ca                	cmp    %ecx,%edx
80102d96:	73 2b                	jae    80102dc3 <mpinit+0x91>
    switch(*p){
80102d98:	0f b6 02             	movzbl (%edx),%eax
80102d9b:	3c 04                	cmp    $0x4,%al
80102d9d:	77 1d                	ja     80102dbc <mpinit+0x8a>
80102d9f:	0f b6 c0             	movzbl %al,%eax
80102da2:	ff 24 85 bc 6a 10 80 	jmp    *-0x7fef9544(,%eax,4)
      continue;
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
      ioapicid = ioapic->apicno;
80102da9:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102dad:	a2 80 17 13 80       	mov    %al,0x80131780
      p += sizeof(struct mpioapic);
80102db2:	83 c2 08             	add    $0x8,%edx
      continue;
80102db5:	eb dd                	jmp    80102d94 <mpinit+0x62>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80102db7:	83 c2 08             	add    $0x8,%edx
      continue;
80102dba:	eb d8                	jmp    80102d94 <mpinit+0x62>
    default:
      ismp = 0;
80102dbc:	bb 00 00 00 00       	mov    $0x0,%ebx
80102dc1:	eb d1                	jmp    80102d94 <mpinit+0x62>
      break;
    }
  }
  if(!ismp)
80102dc3:	85 db                	test   %ebx,%ebx
80102dc5:	74 26                	je     80102ded <mpinit+0xbb>
    panic("Didn't find a suitable machine");

  if(mp->imcrp){
80102dc7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102dca:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
80102dce:	74 15                	je     80102de5 <mpinit+0xb3>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102dd0:	b8 70 00 00 00       	mov    $0x70,%eax
80102dd5:	ba 22 00 00 00       	mov    $0x22,%edx
80102dda:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102ddb:	ba 23 00 00 00       	mov    $0x23,%edx
80102de0:	ec                   	in     (%dx),%al
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80102de1:	83 c8 01             	or     $0x1,%eax
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102de4:	ee                   	out    %al,(%dx)
  }
}
80102de5:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102de8:	5b                   	pop    %ebx
80102de9:	5e                   	pop    %esi
80102dea:	5f                   	pop    %edi
80102deb:	5d                   	pop    %ebp
80102dec:	c3                   	ret    
    panic("Didn't find a suitable machine");
80102ded:	83 ec 0c             	sub    $0xc,%esp
80102df0:	68 9c 6a 10 80       	push   $0x80106a9c
80102df5:	e8 4e d5 ff ff       	call   80100348 <panic>

80102dfa <picinit>:
#define IO_PIC2         0xA0    // Slave (IRQs 8-15)

// Don't use the 8259A interrupt controllers.  Xv6 assumes SMP hardware.
void
picinit(void)
{
80102dfa:	55                   	push   %ebp
80102dfb:	89 e5                	mov    %esp,%ebp
80102dfd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102e02:	ba 21 00 00 00       	mov    $0x21,%edx
80102e07:	ee                   	out    %al,(%dx)
80102e08:	ba a1 00 00 00       	mov    $0xa1,%edx
80102e0d:	ee                   	out    %al,(%dx)
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
  outb(IO_PIC2+1, 0xFF);
}
80102e0e:	5d                   	pop    %ebp
80102e0f:	c3                   	ret    

80102e10 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80102e10:	55                   	push   %ebp
80102e11:	89 e5                	mov    %esp,%ebp
80102e13:	57                   	push   %edi
80102e14:	56                   	push   %esi
80102e15:	53                   	push   %ebx
80102e16:	83 ec 0c             	sub    $0xc,%esp
80102e19:	8b 5d 08             	mov    0x8(%ebp),%ebx
80102e1c:	8b 75 0c             	mov    0xc(%ebp),%esi
  struct pipe *p;

  p = 0;
  *f0 = *f1 = 0;
80102e1f:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80102e25:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80102e2b:	e8 fd dd ff ff       	call   80100c2d <filealloc>
80102e30:	89 03                	mov    %eax,(%ebx)
80102e32:	85 c0                	test   %eax,%eax
80102e34:	74 16                	je     80102e4c <pipealloc+0x3c>
80102e36:	e8 f2 dd ff ff       	call   80100c2d <filealloc>
80102e3b:	89 06                	mov    %eax,(%esi)
80102e3d:	85 c0                	test   %eax,%eax
80102e3f:	74 0b                	je     80102e4c <pipealloc+0x3c>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80102e41:	e8 a6 f2 ff ff       	call   801020ec <kalloc>
80102e46:	89 c7                	mov    %eax,%edi
80102e48:	85 c0                	test   %eax,%eax
80102e4a:	75 35                	jne    80102e81 <pipealloc+0x71>
  return 0;

 bad:
  if(p)
    kfree((char*)p);
  if(*f0)
80102e4c:	8b 03                	mov    (%ebx),%eax
80102e4e:	85 c0                	test   %eax,%eax
80102e50:	74 0c                	je     80102e5e <pipealloc+0x4e>
    fileclose(*f0);
80102e52:	83 ec 0c             	sub    $0xc,%esp
80102e55:	50                   	push   %eax
80102e56:	e8 78 de ff ff       	call   80100cd3 <fileclose>
80102e5b:	83 c4 10             	add    $0x10,%esp
  if(*f1)
80102e5e:	8b 06                	mov    (%esi),%eax
80102e60:	85 c0                	test   %eax,%eax
80102e62:	0f 84 8b 00 00 00    	je     80102ef3 <pipealloc+0xe3>
    fileclose(*f1);
80102e68:	83 ec 0c             	sub    $0xc,%esp
80102e6b:	50                   	push   %eax
80102e6c:	e8 62 de ff ff       	call   80100cd3 <fileclose>
80102e71:	83 c4 10             	add    $0x10,%esp
  return -1;
80102e74:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80102e79:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102e7c:	5b                   	pop    %ebx
80102e7d:	5e                   	pop    %esi
80102e7e:	5f                   	pop    %edi
80102e7f:	5d                   	pop    %ebp
80102e80:	c3                   	ret    
  p->readopen = 1;
80102e81:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80102e88:	00 00 00 
  p->writeopen = 1;
80102e8b:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80102e92:	00 00 00 
  p->nwrite = 0;
80102e95:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80102e9c:	00 00 00 
  p->nread = 0;
80102e9f:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80102ea6:	00 00 00 
  initlock(&p->lock, "pipe");
80102ea9:	83 ec 08             	sub    $0x8,%esp
80102eac:	68 d0 6a 10 80       	push   $0x80106ad0
80102eb1:	50                   	push   %eax
80102eb2:	e8 7d 0c 00 00       	call   80103b34 <initlock>
  (*f0)->type = FD_PIPE;
80102eb7:	8b 03                	mov    (%ebx),%eax
80102eb9:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80102ebf:	8b 03                	mov    (%ebx),%eax
80102ec1:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80102ec5:	8b 03                	mov    (%ebx),%eax
80102ec7:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80102ecb:	8b 03                	mov    (%ebx),%eax
80102ecd:	89 78 0c             	mov    %edi,0xc(%eax)
  (*f1)->type = FD_PIPE;
80102ed0:	8b 06                	mov    (%esi),%eax
80102ed2:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80102ed8:	8b 06                	mov    (%esi),%eax
80102eda:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80102ede:	8b 06                	mov    (%esi),%eax
80102ee0:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80102ee4:	8b 06                	mov    (%esi),%eax
80102ee6:	89 78 0c             	mov    %edi,0xc(%eax)
  return 0;
80102ee9:	83 c4 10             	add    $0x10,%esp
80102eec:	b8 00 00 00 00       	mov    $0x0,%eax
80102ef1:	eb 86                	jmp    80102e79 <pipealloc+0x69>
  return -1;
80102ef3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102ef8:	e9 7c ff ff ff       	jmp    80102e79 <pipealloc+0x69>

80102efd <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80102efd:	55                   	push   %ebp
80102efe:	89 e5                	mov    %esp,%ebp
80102f00:	53                   	push   %ebx
80102f01:	83 ec 10             	sub    $0x10,%esp
80102f04:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&p->lock);
80102f07:	53                   	push   %ebx
80102f08:	e8 63 0d 00 00       	call   80103c70 <acquire>
  if(writable){
80102f0d:	83 c4 10             	add    $0x10,%esp
80102f10:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102f14:	74 3f                	je     80102f55 <pipeclose+0x58>
    p->writeopen = 0;
80102f16:	c7 83 40 02 00 00 00 	movl   $0x0,0x240(%ebx)
80102f1d:	00 00 00 
    wakeup(&p->nread);
80102f20:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102f26:	83 ec 0c             	sub    $0xc,%esp
80102f29:	50                   	push   %eax
80102f2a:	e8 ab 09 00 00       	call   801038da <wakeup>
80102f2f:	83 c4 10             	add    $0x10,%esp
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
80102f32:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80102f39:	75 09                	jne    80102f44 <pipeclose+0x47>
80102f3b:	83 bb 40 02 00 00 00 	cmpl   $0x0,0x240(%ebx)
80102f42:	74 2f                	je     80102f73 <pipeclose+0x76>
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
80102f44:	83 ec 0c             	sub    $0xc,%esp
80102f47:	53                   	push   %ebx
80102f48:	e8 88 0d 00 00       	call   80103cd5 <release>
80102f4d:	83 c4 10             	add    $0x10,%esp
}
80102f50:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102f53:	c9                   	leave  
80102f54:	c3                   	ret    
    p->readopen = 0;
80102f55:	c7 83 3c 02 00 00 00 	movl   $0x0,0x23c(%ebx)
80102f5c:	00 00 00 
    wakeup(&p->nwrite);
80102f5f:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80102f65:	83 ec 0c             	sub    $0xc,%esp
80102f68:	50                   	push   %eax
80102f69:	e8 6c 09 00 00       	call   801038da <wakeup>
80102f6e:	83 c4 10             	add    $0x10,%esp
80102f71:	eb bf                	jmp    80102f32 <pipeclose+0x35>
    release(&p->lock);
80102f73:	83 ec 0c             	sub    $0xc,%esp
80102f76:	53                   	push   %ebx
80102f77:	e8 59 0d 00 00       	call   80103cd5 <release>
    kfree((char*)p);
80102f7c:	89 1c 24             	mov    %ebx,(%esp)
80102f7f:	e8 20 f0 ff ff       	call   80101fa4 <kfree>
80102f84:	83 c4 10             	add    $0x10,%esp
80102f87:	eb c7                	jmp    80102f50 <pipeclose+0x53>

80102f89 <pipewrite>:

int
pipewrite(struct pipe *p, char *addr, int n)
{
80102f89:	55                   	push   %ebp
80102f8a:	89 e5                	mov    %esp,%ebp
80102f8c:	57                   	push   %edi
80102f8d:	56                   	push   %esi
80102f8e:	53                   	push   %ebx
80102f8f:	83 ec 18             	sub    $0x18,%esp
80102f92:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80102f95:	89 de                	mov    %ebx,%esi
80102f97:	53                   	push   %ebx
80102f98:	e8 d3 0c 00 00       	call   80103c70 <acquire>
  for(i = 0; i < n; i++){
80102f9d:	83 c4 10             	add    $0x10,%esp
80102fa0:	bf 00 00 00 00       	mov    $0x0,%edi
80102fa5:	3b 7d 10             	cmp    0x10(%ebp),%edi
80102fa8:	0f 8d 88 00 00 00    	jge    80103036 <pipewrite+0xad>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80102fae:	8b 93 38 02 00 00    	mov    0x238(%ebx),%edx
80102fb4:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
80102fba:	05 00 02 00 00       	add    $0x200,%eax
80102fbf:	39 c2                	cmp    %eax,%edx
80102fc1:	75 51                	jne    80103014 <pipewrite+0x8b>
      if(p->readopen == 0 || myproc()->killed){
80102fc3:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80102fca:	74 2f                	je     80102ffb <pipewrite+0x72>
80102fcc:	e8 00 03 00 00       	call   801032d1 <myproc>
80102fd1:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80102fd5:	75 24                	jne    80102ffb <pipewrite+0x72>
        release(&p->lock);
        return -1;
      }
      wakeup(&p->nread);
80102fd7:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102fdd:	83 ec 0c             	sub    $0xc,%esp
80102fe0:	50                   	push   %eax
80102fe1:	e8 f4 08 00 00       	call   801038da <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80102fe6:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80102fec:	83 c4 08             	add    $0x8,%esp
80102fef:	56                   	push   %esi
80102ff0:	50                   	push   %eax
80102ff1:	e8 7f 07 00 00       	call   80103775 <sleep>
80102ff6:	83 c4 10             	add    $0x10,%esp
80102ff9:	eb b3                	jmp    80102fae <pipewrite+0x25>
        release(&p->lock);
80102ffb:	83 ec 0c             	sub    $0xc,%esp
80102ffe:	53                   	push   %ebx
80102fff:	e8 d1 0c 00 00       	call   80103cd5 <release>
        return -1;
80103004:	83 c4 10             	add    $0x10,%esp
80103007:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
  release(&p->lock);
  return n;
}
8010300c:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010300f:	5b                   	pop    %ebx
80103010:	5e                   	pop    %esi
80103011:	5f                   	pop    %edi
80103012:	5d                   	pop    %ebp
80103013:	c3                   	ret    
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80103014:	8d 42 01             	lea    0x1(%edx),%eax
80103017:	89 83 38 02 00 00    	mov    %eax,0x238(%ebx)
8010301d:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80103023:	8b 45 0c             	mov    0xc(%ebp),%eax
80103026:	0f b6 04 38          	movzbl (%eax,%edi,1),%eax
8010302a:	88 44 13 34          	mov    %al,0x34(%ebx,%edx,1)
  for(i = 0; i < n; i++){
8010302e:	83 c7 01             	add    $0x1,%edi
80103031:	e9 6f ff ff ff       	jmp    80102fa5 <pipewrite+0x1c>
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80103036:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
8010303c:	83 ec 0c             	sub    $0xc,%esp
8010303f:	50                   	push   %eax
80103040:	e8 95 08 00 00       	call   801038da <wakeup>
  release(&p->lock);
80103045:	89 1c 24             	mov    %ebx,(%esp)
80103048:	e8 88 0c 00 00       	call   80103cd5 <release>
  return n;
8010304d:	83 c4 10             	add    $0x10,%esp
80103050:	8b 45 10             	mov    0x10(%ebp),%eax
80103053:	eb b7                	jmp    8010300c <pipewrite+0x83>

80103055 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80103055:	55                   	push   %ebp
80103056:	89 e5                	mov    %esp,%ebp
80103058:	57                   	push   %edi
80103059:	56                   	push   %esi
8010305a:	53                   	push   %ebx
8010305b:	83 ec 18             	sub    $0x18,%esp
8010305e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80103061:	89 df                	mov    %ebx,%edi
80103063:	53                   	push   %ebx
80103064:	e8 07 0c 00 00       	call   80103c70 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80103069:	83 c4 10             	add    $0x10,%esp
8010306c:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
80103072:	39 83 34 02 00 00    	cmp    %eax,0x234(%ebx)
80103078:	75 3d                	jne    801030b7 <piperead+0x62>
8010307a:	8b b3 40 02 00 00    	mov    0x240(%ebx),%esi
80103080:	85 f6                	test   %esi,%esi
80103082:	74 38                	je     801030bc <piperead+0x67>
    if(myproc()->killed){
80103084:	e8 48 02 00 00       	call   801032d1 <myproc>
80103089:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010308d:	75 15                	jne    801030a4 <piperead+0x4f>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
8010308f:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80103095:	83 ec 08             	sub    $0x8,%esp
80103098:	57                   	push   %edi
80103099:	50                   	push   %eax
8010309a:	e8 d6 06 00 00       	call   80103775 <sleep>
8010309f:	83 c4 10             	add    $0x10,%esp
801030a2:	eb c8                	jmp    8010306c <piperead+0x17>
      release(&p->lock);
801030a4:	83 ec 0c             	sub    $0xc,%esp
801030a7:	53                   	push   %ebx
801030a8:	e8 28 0c 00 00       	call   80103cd5 <release>
      return -1;
801030ad:	83 c4 10             	add    $0x10,%esp
801030b0:	be ff ff ff ff       	mov    $0xffffffff,%esi
801030b5:	eb 50                	jmp    80103107 <piperead+0xb2>
801030b7:	be 00 00 00 00       	mov    $0x0,%esi
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801030bc:	3b 75 10             	cmp    0x10(%ebp),%esi
801030bf:	7d 2c                	jge    801030ed <piperead+0x98>
    if(p->nread == p->nwrite)
801030c1:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
801030c7:	3b 83 38 02 00 00    	cmp    0x238(%ebx),%eax
801030cd:	74 1e                	je     801030ed <piperead+0x98>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
801030cf:	8d 50 01             	lea    0x1(%eax),%edx
801030d2:	89 93 34 02 00 00    	mov    %edx,0x234(%ebx)
801030d8:	25 ff 01 00 00       	and    $0x1ff,%eax
801030dd:	0f b6 44 03 34       	movzbl 0x34(%ebx,%eax,1),%eax
801030e2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801030e5:	88 04 31             	mov    %al,(%ecx,%esi,1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801030e8:	83 c6 01             	add    $0x1,%esi
801030eb:	eb cf                	jmp    801030bc <piperead+0x67>
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
801030ed:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
801030f3:	83 ec 0c             	sub    $0xc,%esp
801030f6:	50                   	push   %eax
801030f7:	e8 de 07 00 00       	call   801038da <wakeup>
  release(&p->lock);
801030fc:	89 1c 24             	mov    %ebx,(%esp)
801030ff:	e8 d1 0b 00 00       	call   80103cd5 <release>
  return i;
80103104:	83 c4 10             	add    $0x10,%esp
}
80103107:	89 f0                	mov    %esi,%eax
80103109:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010310c:	5b                   	pop    %ebx
8010310d:	5e                   	pop    %esi
8010310e:	5f                   	pop    %edi
8010310f:	5d                   	pop    %ebp
80103110:	c3                   	ret    

80103111 <wakeup1>:

// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80103111:	55                   	push   %ebp
80103112:	89 e5                	mov    %esp,%ebp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103114:	ba 74 1d 13 80       	mov    $0x80131d74,%edx
80103119:	eb 03                	jmp    8010311e <wakeup1+0xd>
8010311b:	83 c2 7c             	add    $0x7c,%edx
8010311e:	81 fa 74 3c 13 80    	cmp    $0x80133c74,%edx
80103124:	73 14                	jae    8010313a <wakeup1+0x29>
    if(p->state == SLEEPING && p->chan == chan)
80103126:	83 7a 0c 02          	cmpl   $0x2,0xc(%edx)
8010312a:	75 ef                	jne    8010311b <wakeup1+0xa>
8010312c:	39 42 20             	cmp    %eax,0x20(%edx)
8010312f:	75 ea                	jne    8010311b <wakeup1+0xa>
      p->state = RUNNABLE;
80103131:	c7 42 0c 03 00 00 00 	movl   $0x3,0xc(%edx)
80103138:	eb e1                	jmp    8010311b <wakeup1+0xa>
}
8010313a:	5d                   	pop    %ebp
8010313b:	c3                   	ret    

8010313c <allocproc>:
{
8010313c:	55                   	push   %ebp
8010313d:	89 e5                	mov    %esp,%ebp
8010313f:	53                   	push   %ebx
80103140:	83 ec 10             	sub    $0x10,%esp
  acquire(&ptable.lock);
80103143:	68 40 1d 13 80       	push   $0x80131d40
80103148:	e8 23 0b 00 00       	call   80103c70 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010314d:	83 c4 10             	add    $0x10,%esp
80103150:	bb 74 1d 13 80       	mov    $0x80131d74,%ebx
80103155:	81 fb 74 3c 13 80    	cmp    $0x80133c74,%ebx
8010315b:	73 0b                	jae    80103168 <allocproc+0x2c>
    if(p->state == UNUSED)
8010315d:	83 7b 0c 00          	cmpl   $0x0,0xc(%ebx)
80103161:	74 1c                	je     8010317f <allocproc+0x43>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103163:	83 c3 7c             	add    $0x7c,%ebx
80103166:	eb ed                	jmp    80103155 <allocproc+0x19>
  release(&ptable.lock);
80103168:	83 ec 0c             	sub    $0xc,%esp
8010316b:	68 40 1d 13 80       	push   $0x80131d40
80103170:	e8 60 0b 00 00       	call   80103cd5 <release>
  return 0;
80103175:	83 c4 10             	add    $0x10,%esp
80103178:	bb 00 00 00 00       	mov    $0x0,%ebx
8010317d:	eb 69                	jmp    801031e8 <allocproc+0xac>
  p->state = EMBRYO;
8010317f:	c7 43 0c 01 00 00 00 	movl   $0x1,0xc(%ebx)
  p->pid = nextpid++;
80103186:	a1 04 90 10 80       	mov    0x80109004,%eax
8010318b:	8d 50 01             	lea    0x1(%eax),%edx
8010318e:	89 15 04 90 10 80    	mov    %edx,0x80109004
80103194:	89 43 10             	mov    %eax,0x10(%ebx)
  release(&ptable.lock);
80103197:	83 ec 0c             	sub    $0xc,%esp
8010319a:	68 40 1d 13 80       	push   $0x80131d40
8010319f:	e8 31 0b 00 00       	call   80103cd5 <release>
  if((p->kstack = kalloc()) == 0){
801031a4:	e8 43 ef ff ff       	call   801020ec <kalloc>
801031a9:	89 43 08             	mov    %eax,0x8(%ebx)
801031ac:	83 c4 10             	add    $0x10,%esp
801031af:	85 c0                	test   %eax,%eax
801031b1:	74 3c                	je     801031ef <allocproc+0xb3>
  sp -= sizeof *p->tf;
801031b3:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
  p->tf = (struct trapframe*)sp;
801031b9:	89 53 18             	mov    %edx,0x18(%ebx)
  *(uint*)sp = (uint)trapret;
801031bc:	c7 80 b0 0f 00 00 32 	movl   $0x80104e32,0xfb0(%eax)
801031c3:	4e 10 80 
  sp -= sizeof *p->context;
801031c6:	05 9c 0f 00 00       	add    $0xf9c,%eax
  p->context = (struct context*)sp;
801031cb:	89 43 1c             	mov    %eax,0x1c(%ebx)
  memset(p->context, 0, sizeof *p->context);
801031ce:	83 ec 04             	sub    $0x4,%esp
801031d1:	6a 14                	push   $0x14
801031d3:	6a 00                	push   $0x0
801031d5:	50                   	push   %eax
801031d6:	e8 41 0b 00 00       	call   80103d1c <memset>
  p->context->eip = (uint)forkret;
801031db:	8b 43 1c             	mov    0x1c(%ebx),%eax
801031de:	c7 40 10 fd 31 10 80 	movl   $0x801031fd,0x10(%eax)
  return p;
801031e5:	83 c4 10             	add    $0x10,%esp
}
801031e8:	89 d8                	mov    %ebx,%eax
801031ea:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801031ed:	c9                   	leave  
801031ee:	c3                   	ret    
    p->state = UNUSED;
801031ef:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return 0;
801031f6:	bb 00 00 00 00       	mov    $0x0,%ebx
801031fb:	eb eb                	jmp    801031e8 <allocproc+0xac>

801031fd <forkret>:
{
801031fd:	55                   	push   %ebp
801031fe:	89 e5                	mov    %esp,%ebp
80103200:	83 ec 14             	sub    $0x14,%esp
  release(&ptable.lock);
80103203:	68 40 1d 13 80       	push   $0x80131d40
80103208:	e8 c8 0a 00 00       	call   80103cd5 <release>
  if (first) {
8010320d:	83 c4 10             	add    $0x10,%esp
80103210:	83 3d 00 90 10 80 00 	cmpl   $0x0,0x80109000
80103217:	75 02                	jne    8010321b <forkret+0x1e>
}
80103219:	c9                   	leave  
8010321a:	c3                   	ret    
    first = 0;
8010321b:	c7 05 00 90 10 80 00 	movl   $0x0,0x80109000
80103222:	00 00 00 
    iinit(ROOTDEV);
80103225:	83 ec 0c             	sub    $0xc,%esp
80103228:	6a 01                	push   $0x1
8010322a:	e8 bd e0 ff ff       	call   801012ec <iinit>
    initlog(ROOTDEV);
8010322f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103236:	e8 05 f6 ff ff       	call   80102840 <initlog>
8010323b:	83 c4 10             	add    $0x10,%esp
}
8010323e:	eb d9                	jmp    80103219 <forkret+0x1c>

80103240 <pinit>:
{
80103240:	55                   	push   %ebp
80103241:	89 e5                	mov    %esp,%ebp
80103243:	83 ec 10             	sub    $0x10,%esp
  initlock(&ptable.lock, "ptable");
80103246:	68 d5 6a 10 80       	push   $0x80106ad5
8010324b:	68 40 1d 13 80       	push   $0x80131d40
80103250:	e8 df 08 00 00       	call   80103b34 <initlock>
}
80103255:	83 c4 10             	add    $0x10,%esp
80103258:	c9                   	leave  
80103259:	c3                   	ret    

8010325a <mycpu>:
{
8010325a:	55                   	push   %ebp
8010325b:	89 e5                	mov    %esp,%ebp
8010325d:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103260:	9c                   	pushf  
80103261:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103262:	f6 c4 02             	test   $0x2,%ah
80103265:	75 28                	jne    8010328f <mycpu+0x35>
  apicid = lapicid();
80103267:	e8 ed f1 ff ff       	call   80102459 <lapicid>
  for (i = 0; i < ncpu; ++i) {
8010326c:	ba 00 00 00 00       	mov    $0x0,%edx
80103271:	39 15 20 1d 13 80    	cmp    %edx,0x80131d20
80103277:	7e 23                	jle    8010329c <mycpu+0x42>
    if (cpus[i].apicid == apicid)
80103279:	69 ca b0 00 00 00    	imul   $0xb0,%edx,%ecx
8010327f:	0f b6 89 a0 17 13 80 	movzbl -0x7fece860(%ecx),%ecx
80103286:	39 c1                	cmp    %eax,%ecx
80103288:	74 1f                	je     801032a9 <mycpu+0x4f>
  for (i = 0; i < ncpu; ++i) {
8010328a:	83 c2 01             	add    $0x1,%edx
8010328d:	eb e2                	jmp    80103271 <mycpu+0x17>
    panic("mycpu called with interrupts enabled\n");
8010328f:	83 ec 0c             	sub    $0xc,%esp
80103292:	68 b8 6b 10 80       	push   $0x80106bb8
80103297:	e8 ac d0 ff ff       	call   80100348 <panic>
  panic("unknown apicid\n");
8010329c:	83 ec 0c             	sub    $0xc,%esp
8010329f:	68 dc 6a 10 80       	push   $0x80106adc
801032a4:	e8 9f d0 ff ff       	call   80100348 <panic>
      return &cpus[i];
801032a9:	69 c2 b0 00 00 00    	imul   $0xb0,%edx,%eax
801032af:	05 a0 17 13 80       	add    $0x801317a0,%eax
}
801032b4:	c9                   	leave  
801032b5:	c3                   	ret    

801032b6 <cpuid>:
cpuid() {
801032b6:	55                   	push   %ebp
801032b7:	89 e5                	mov    %esp,%ebp
801032b9:	83 ec 08             	sub    $0x8,%esp
  return mycpu()-cpus;
801032bc:	e8 99 ff ff ff       	call   8010325a <mycpu>
801032c1:	2d a0 17 13 80       	sub    $0x801317a0,%eax
801032c6:	c1 f8 04             	sar    $0x4,%eax
801032c9:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
801032cf:	c9                   	leave  
801032d0:	c3                   	ret    

801032d1 <myproc>:
myproc(void) {
801032d1:	55                   	push   %ebp
801032d2:	89 e5                	mov    %esp,%ebp
801032d4:	53                   	push   %ebx
801032d5:	83 ec 04             	sub    $0x4,%esp
  pushcli();
801032d8:	e8 b6 08 00 00       	call   80103b93 <pushcli>
  c = mycpu();
801032dd:	e8 78 ff ff ff       	call   8010325a <mycpu>
  p = c->proc;
801032e2:	8b 98 ac 00 00 00    	mov    0xac(%eax),%ebx
  popcli();
801032e8:	e8 e3 08 00 00       	call   80103bd0 <popcli>
}
801032ed:	89 d8                	mov    %ebx,%eax
801032ef:	83 c4 04             	add    $0x4,%esp
801032f2:	5b                   	pop    %ebx
801032f3:	5d                   	pop    %ebp
801032f4:	c3                   	ret    

801032f5 <userinit>:
{
801032f5:	55                   	push   %ebp
801032f6:	89 e5                	mov    %esp,%ebp
801032f8:	53                   	push   %ebx
801032f9:	83 ec 04             	sub    $0x4,%esp
  p = allocproc();
801032fc:	e8 3b fe ff ff       	call   8010313c <allocproc>
80103301:	89 c3                	mov    %eax,%ebx
  initproc = p;
80103303:	a3 b8 95 10 80       	mov    %eax,0x801095b8
  if((p->pgdir = setupkvm()) == 0)
80103308:	e8 09 30 00 00       	call   80106316 <setupkvm>
8010330d:	89 43 04             	mov    %eax,0x4(%ebx)
80103310:	85 c0                	test   %eax,%eax
80103312:	0f 84 b7 00 00 00    	je     801033cf <userinit+0xda>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80103318:	83 ec 04             	sub    $0x4,%esp
8010331b:	68 2c 00 00 00       	push   $0x2c
80103320:	68 60 94 10 80       	push   $0x80109460
80103325:	50                   	push   %eax
80103326:	e8 f6 2c 00 00       	call   80106021 <inituvm>
  p->sz = PGSIZE;
8010332b:	c7 03 00 10 00 00    	movl   $0x1000,(%ebx)
  memset(p->tf, 0, sizeof(*p->tf));
80103331:	83 c4 0c             	add    $0xc,%esp
80103334:	6a 4c                	push   $0x4c
80103336:	6a 00                	push   $0x0
80103338:	ff 73 18             	pushl  0x18(%ebx)
8010333b:	e8 dc 09 00 00       	call   80103d1c <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80103340:	8b 43 18             	mov    0x18(%ebx),%eax
80103343:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
80103349:	8b 43 18             	mov    0x18(%ebx),%eax
8010334c:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
  p->tf->es = p->tf->ds;
80103352:	8b 43 18             	mov    0x18(%ebx),%eax
80103355:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
80103359:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
8010335d:	8b 43 18             	mov    0x18(%ebx),%eax
80103360:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
80103364:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
80103368:	8b 43 18             	mov    0x18(%ebx),%eax
8010336b:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
80103372:	8b 43 18             	mov    0x18(%ebx),%eax
80103375:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
8010337c:	8b 43 18             	mov    0x18(%ebx),%eax
8010337f:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
  safestrcpy(p->name, "initcode", sizeof(p->name));
80103386:	8d 43 6c             	lea    0x6c(%ebx),%eax
80103389:	83 c4 0c             	add    $0xc,%esp
8010338c:	6a 10                	push   $0x10
8010338e:	68 05 6b 10 80       	push   $0x80106b05
80103393:	50                   	push   %eax
80103394:	e8 ea 0a 00 00       	call   80103e83 <safestrcpy>
  p->cwd = namei("/");
80103399:	c7 04 24 0e 6b 10 80 	movl   $0x80106b0e,(%esp)
801033a0:	e8 3c e8 ff ff       	call   80101be1 <namei>
801033a5:	89 43 68             	mov    %eax,0x68(%ebx)
  acquire(&ptable.lock);
801033a8:	c7 04 24 40 1d 13 80 	movl   $0x80131d40,(%esp)
801033af:	e8 bc 08 00 00       	call   80103c70 <acquire>
  p->state = RUNNABLE;
801033b4:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  release(&ptable.lock);
801033bb:	c7 04 24 40 1d 13 80 	movl   $0x80131d40,(%esp)
801033c2:	e8 0e 09 00 00       	call   80103cd5 <release>
}
801033c7:	83 c4 10             	add    $0x10,%esp
801033ca:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801033cd:	c9                   	leave  
801033ce:	c3                   	ret    
    panic("userinit: out of memory?");
801033cf:	83 ec 0c             	sub    $0xc,%esp
801033d2:	68 ec 6a 10 80       	push   $0x80106aec
801033d7:	e8 6c cf ff ff       	call   80100348 <panic>

801033dc <growproc>:
{
801033dc:	55                   	push   %ebp
801033dd:	89 e5                	mov    %esp,%ebp
801033df:	56                   	push   %esi
801033e0:	53                   	push   %ebx
801033e1:	8b 75 08             	mov    0x8(%ebp),%esi
  struct proc *curproc = myproc();
801033e4:	e8 e8 fe ff ff       	call   801032d1 <myproc>
801033e9:	89 c3                	mov    %eax,%ebx
  sz = curproc->sz;
801033eb:	8b 00                	mov    (%eax),%eax
  if(n > 0){
801033ed:	85 f6                	test   %esi,%esi
801033ef:	7f 21                	jg     80103412 <growproc+0x36>
  } else if(n < 0){
801033f1:	85 f6                	test   %esi,%esi
801033f3:	79 33                	jns    80103428 <growproc+0x4c>
    if((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
801033f5:	83 ec 04             	sub    $0x4,%esp
801033f8:	01 c6                	add    %eax,%esi
801033fa:	56                   	push   %esi
801033fb:	50                   	push   %eax
801033fc:	ff 73 04             	pushl  0x4(%ebx)
801033ff:	e8 26 2d 00 00       	call   8010612a <deallocuvm>
80103404:	83 c4 10             	add    $0x10,%esp
80103407:	85 c0                	test   %eax,%eax
80103409:	75 1d                	jne    80103428 <growproc+0x4c>
      return -1;
8010340b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103410:	eb 29                	jmp    8010343b <growproc+0x5f>
    if((sz = allocuvm(curproc->pgdir, sz, sz + n)) == 0)
80103412:	83 ec 04             	sub    $0x4,%esp
80103415:	01 c6                	add    %eax,%esi
80103417:	56                   	push   %esi
80103418:	50                   	push   %eax
80103419:	ff 73 04             	pushl  0x4(%ebx)
8010341c:	e8 9b 2d 00 00       	call   801061bc <allocuvm>
80103421:	83 c4 10             	add    $0x10,%esp
80103424:	85 c0                	test   %eax,%eax
80103426:	74 1a                	je     80103442 <growproc+0x66>
  curproc->sz = sz;
80103428:	89 03                	mov    %eax,(%ebx)
  switchuvm(curproc);
8010342a:	83 ec 0c             	sub    $0xc,%esp
8010342d:	53                   	push   %ebx
8010342e:	e8 d6 2a 00 00       	call   80105f09 <switchuvm>
  return 0;
80103433:	83 c4 10             	add    $0x10,%esp
80103436:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010343b:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010343e:	5b                   	pop    %ebx
8010343f:	5e                   	pop    %esi
80103440:	5d                   	pop    %ebp
80103441:	c3                   	ret    
      return -1;
80103442:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103447:	eb f2                	jmp    8010343b <growproc+0x5f>

80103449 <fork>:
{
80103449:	55                   	push   %ebp
8010344a:	89 e5                	mov    %esp,%ebp
8010344c:	57                   	push   %edi
8010344d:	56                   	push   %esi
8010344e:	53                   	push   %ebx
8010344f:	83 ec 1c             	sub    $0x1c,%esp
  struct proc *curproc = myproc();
80103452:	e8 7a fe ff ff       	call   801032d1 <myproc>
80103457:	89 c3                	mov    %eax,%ebx
  if((np = allocproc()) == 0){
80103459:	e8 de fc ff ff       	call   8010313c <allocproc>
8010345e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80103461:	85 c0                	test   %eax,%eax
80103463:	0f 84 e0 00 00 00    	je     80103549 <fork+0x100>
80103469:	89 c7                	mov    %eax,%edi
  if((np->pgdir = copyuvm(curproc->pgdir, curproc->sz)) == 0){
8010346b:	83 ec 08             	sub    $0x8,%esp
8010346e:	ff 33                	pushl  (%ebx)
80103470:	ff 73 04             	pushl  0x4(%ebx)
80103473:	e8 4f 2f 00 00       	call   801063c7 <copyuvm>
80103478:	89 47 04             	mov    %eax,0x4(%edi)
8010347b:	83 c4 10             	add    $0x10,%esp
8010347e:	85 c0                	test   %eax,%eax
80103480:	74 2a                	je     801034ac <fork+0x63>
  np->sz = curproc->sz;
80103482:	8b 03                	mov    (%ebx),%eax
80103484:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80103487:	89 01                	mov    %eax,(%ecx)
  np->parent = curproc;
80103489:	89 c8                	mov    %ecx,%eax
8010348b:	89 59 14             	mov    %ebx,0x14(%ecx)
  *np->tf = *curproc->tf;
8010348e:	8b 73 18             	mov    0x18(%ebx),%esi
80103491:	8b 79 18             	mov    0x18(%ecx),%edi
80103494:	b9 13 00 00 00       	mov    $0x13,%ecx
80103499:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  np->tf->eax = 0;
8010349b:	8b 40 18             	mov    0x18(%eax),%eax
8010349e:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
  for(i = 0; i < NOFILE; i++)
801034a5:	be 00 00 00 00       	mov    $0x0,%esi
801034aa:	eb 29                	jmp    801034d5 <fork+0x8c>
    kfree(np->kstack);
801034ac:	83 ec 0c             	sub    $0xc,%esp
801034af:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
801034b2:	ff 73 08             	pushl  0x8(%ebx)
801034b5:	e8 ea ea ff ff       	call   80101fa4 <kfree>
    np->kstack = 0;
801034ba:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
    np->state = UNUSED;
801034c1:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return -1;
801034c8:	83 c4 10             	add    $0x10,%esp
801034cb:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801034d0:	eb 6d                	jmp    8010353f <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
801034d2:	83 c6 01             	add    $0x1,%esi
801034d5:	83 fe 0f             	cmp    $0xf,%esi
801034d8:	7f 1d                	jg     801034f7 <fork+0xae>
    if(curproc->ofile[i])
801034da:	8b 44 b3 28          	mov    0x28(%ebx,%esi,4),%eax
801034de:	85 c0                	test   %eax,%eax
801034e0:	74 f0                	je     801034d2 <fork+0x89>
      np->ofile[i] = filedup(curproc->ofile[i]);
801034e2:	83 ec 0c             	sub    $0xc,%esp
801034e5:	50                   	push   %eax
801034e6:	e8 a3 d7 ff ff       	call   80100c8e <filedup>
801034eb:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801034ee:	89 44 b2 28          	mov    %eax,0x28(%edx,%esi,4)
801034f2:	83 c4 10             	add    $0x10,%esp
801034f5:	eb db                	jmp    801034d2 <fork+0x89>
  np->cwd = idup(curproc->cwd);
801034f7:	83 ec 0c             	sub    $0xc,%esp
801034fa:	ff 73 68             	pushl  0x68(%ebx)
801034fd:	e8 4f e0 ff ff       	call   80101551 <idup>
80103502:	8b 7d e4             	mov    -0x1c(%ebp),%edi
80103505:	89 47 68             	mov    %eax,0x68(%edi)
  safestrcpy(np->name, curproc->name, sizeof(curproc->name));
80103508:	83 c3 6c             	add    $0x6c,%ebx
8010350b:	8d 47 6c             	lea    0x6c(%edi),%eax
8010350e:	83 c4 0c             	add    $0xc,%esp
80103511:	6a 10                	push   $0x10
80103513:	53                   	push   %ebx
80103514:	50                   	push   %eax
80103515:	e8 69 09 00 00       	call   80103e83 <safestrcpy>
  pid = np->pid;
8010351a:	8b 5f 10             	mov    0x10(%edi),%ebx
  acquire(&ptable.lock);
8010351d:	c7 04 24 40 1d 13 80 	movl   $0x80131d40,(%esp)
80103524:	e8 47 07 00 00       	call   80103c70 <acquire>
  np->state = RUNNABLE;
80103529:	c7 47 0c 03 00 00 00 	movl   $0x3,0xc(%edi)
  release(&ptable.lock);
80103530:	c7 04 24 40 1d 13 80 	movl   $0x80131d40,(%esp)
80103537:	e8 99 07 00 00       	call   80103cd5 <release>
  return pid;
8010353c:	83 c4 10             	add    $0x10,%esp
}
8010353f:	89 d8                	mov    %ebx,%eax
80103541:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103544:	5b                   	pop    %ebx
80103545:	5e                   	pop    %esi
80103546:	5f                   	pop    %edi
80103547:	5d                   	pop    %ebp
80103548:	c3                   	ret    
    return -1;
80103549:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
8010354e:	eb ef                	jmp    8010353f <fork+0xf6>

80103550 <scheduler>:
{
80103550:	55                   	push   %ebp
80103551:	89 e5                	mov    %esp,%ebp
80103553:	56                   	push   %esi
80103554:	53                   	push   %ebx
  struct cpu *c = mycpu();
80103555:	e8 00 fd ff ff       	call   8010325a <mycpu>
8010355a:	89 c6                	mov    %eax,%esi
  c->proc = 0;
8010355c:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
80103563:	00 00 00 
80103566:	eb 5a                	jmp    801035c2 <scheduler+0x72>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103568:	83 c3 7c             	add    $0x7c,%ebx
8010356b:	81 fb 74 3c 13 80    	cmp    $0x80133c74,%ebx
80103571:	73 3f                	jae    801035b2 <scheduler+0x62>
      if(p->state != RUNNABLE)
80103573:	83 7b 0c 03          	cmpl   $0x3,0xc(%ebx)
80103577:	75 ef                	jne    80103568 <scheduler+0x18>
      c->proc = p;
80103579:	89 9e ac 00 00 00    	mov    %ebx,0xac(%esi)
      switchuvm(p);
8010357f:	83 ec 0c             	sub    $0xc,%esp
80103582:	53                   	push   %ebx
80103583:	e8 81 29 00 00       	call   80105f09 <switchuvm>
      p->state = RUNNING;
80103588:	c7 43 0c 04 00 00 00 	movl   $0x4,0xc(%ebx)
      swtch(&(c->scheduler), p->context);
8010358f:	83 c4 08             	add    $0x8,%esp
80103592:	ff 73 1c             	pushl  0x1c(%ebx)
80103595:	8d 46 04             	lea    0x4(%esi),%eax
80103598:	50                   	push   %eax
80103599:	e8 38 09 00 00       	call   80103ed6 <swtch>
      switchkvm();
8010359e:	e8 54 29 00 00       	call   80105ef7 <switchkvm>
      c->proc = 0;
801035a3:	c7 86 ac 00 00 00 00 	movl   $0x0,0xac(%esi)
801035aa:	00 00 00 
801035ad:	83 c4 10             	add    $0x10,%esp
801035b0:	eb b6                	jmp    80103568 <scheduler+0x18>
    release(&ptable.lock);
801035b2:	83 ec 0c             	sub    $0xc,%esp
801035b5:	68 40 1d 13 80       	push   $0x80131d40
801035ba:	e8 16 07 00 00       	call   80103cd5 <release>
    sti();
801035bf:	83 c4 10             	add    $0x10,%esp
  asm volatile("sti");
801035c2:	fb                   	sti    
    acquire(&ptable.lock);
801035c3:	83 ec 0c             	sub    $0xc,%esp
801035c6:	68 40 1d 13 80       	push   $0x80131d40
801035cb:	e8 a0 06 00 00       	call   80103c70 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801035d0:	83 c4 10             	add    $0x10,%esp
801035d3:	bb 74 1d 13 80       	mov    $0x80131d74,%ebx
801035d8:	eb 91                	jmp    8010356b <scheduler+0x1b>

801035da <sched>:
{
801035da:	55                   	push   %ebp
801035db:	89 e5                	mov    %esp,%ebp
801035dd:	56                   	push   %esi
801035de:	53                   	push   %ebx
  struct proc *p = myproc();
801035df:	e8 ed fc ff ff       	call   801032d1 <myproc>
801035e4:	89 c3                	mov    %eax,%ebx
  if(!holding(&ptable.lock))
801035e6:	83 ec 0c             	sub    $0xc,%esp
801035e9:	68 40 1d 13 80       	push   $0x80131d40
801035ee:	e8 3d 06 00 00       	call   80103c30 <holding>
801035f3:	83 c4 10             	add    $0x10,%esp
801035f6:	85 c0                	test   %eax,%eax
801035f8:	74 4f                	je     80103649 <sched+0x6f>
  if(mycpu()->ncli != 1)
801035fa:	e8 5b fc ff ff       	call   8010325a <mycpu>
801035ff:	83 b8 a4 00 00 00 01 	cmpl   $0x1,0xa4(%eax)
80103606:	75 4e                	jne    80103656 <sched+0x7c>
  if(p->state == RUNNING)
80103608:	83 7b 0c 04          	cmpl   $0x4,0xc(%ebx)
8010360c:	74 55                	je     80103663 <sched+0x89>
  asm volatile("pushfl; popl %0" : "=r" (eflags));
8010360e:	9c                   	pushf  
8010360f:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103610:	f6 c4 02             	test   $0x2,%ah
80103613:	75 5b                	jne    80103670 <sched+0x96>
  intena = mycpu()->intena;
80103615:	e8 40 fc ff ff       	call   8010325a <mycpu>
8010361a:	8b b0 a8 00 00 00    	mov    0xa8(%eax),%esi
  swtch(&p->context, mycpu()->scheduler);
80103620:	e8 35 fc ff ff       	call   8010325a <mycpu>
80103625:	83 ec 08             	sub    $0x8,%esp
80103628:	ff 70 04             	pushl  0x4(%eax)
8010362b:	83 c3 1c             	add    $0x1c,%ebx
8010362e:	53                   	push   %ebx
8010362f:	e8 a2 08 00 00       	call   80103ed6 <swtch>
  mycpu()->intena = intena;
80103634:	e8 21 fc ff ff       	call   8010325a <mycpu>
80103639:	89 b0 a8 00 00 00    	mov    %esi,0xa8(%eax)
}
8010363f:	83 c4 10             	add    $0x10,%esp
80103642:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103645:	5b                   	pop    %ebx
80103646:	5e                   	pop    %esi
80103647:	5d                   	pop    %ebp
80103648:	c3                   	ret    
    panic("sched ptable.lock");
80103649:	83 ec 0c             	sub    $0xc,%esp
8010364c:	68 10 6b 10 80       	push   $0x80106b10
80103651:	e8 f2 cc ff ff       	call   80100348 <panic>
    panic("sched locks");
80103656:	83 ec 0c             	sub    $0xc,%esp
80103659:	68 22 6b 10 80       	push   $0x80106b22
8010365e:	e8 e5 cc ff ff       	call   80100348 <panic>
    panic("sched running");
80103663:	83 ec 0c             	sub    $0xc,%esp
80103666:	68 2e 6b 10 80       	push   $0x80106b2e
8010366b:	e8 d8 cc ff ff       	call   80100348 <panic>
    panic("sched interruptible");
80103670:	83 ec 0c             	sub    $0xc,%esp
80103673:	68 3c 6b 10 80       	push   $0x80106b3c
80103678:	e8 cb cc ff ff       	call   80100348 <panic>

8010367d <exit>:
{
8010367d:	55                   	push   %ebp
8010367e:	89 e5                	mov    %esp,%ebp
80103680:	56                   	push   %esi
80103681:	53                   	push   %ebx
  struct proc *curproc = myproc();
80103682:	e8 4a fc ff ff       	call   801032d1 <myproc>
  if(curproc == initproc)
80103687:	39 05 b8 95 10 80    	cmp    %eax,0x801095b8
8010368d:	74 09                	je     80103698 <exit+0x1b>
8010368f:	89 c6                	mov    %eax,%esi
  for(fd = 0; fd < NOFILE; fd++){
80103691:	bb 00 00 00 00       	mov    $0x0,%ebx
80103696:	eb 10                	jmp    801036a8 <exit+0x2b>
    panic("init exiting");
80103698:	83 ec 0c             	sub    $0xc,%esp
8010369b:	68 50 6b 10 80       	push   $0x80106b50
801036a0:	e8 a3 cc ff ff       	call   80100348 <panic>
  for(fd = 0; fd < NOFILE; fd++){
801036a5:	83 c3 01             	add    $0x1,%ebx
801036a8:	83 fb 0f             	cmp    $0xf,%ebx
801036ab:	7f 1e                	jg     801036cb <exit+0x4e>
    if(curproc->ofile[fd]){
801036ad:	8b 44 9e 28          	mov    0x28(%esi,%ebx,4),%eax
801036b1:	85 c0                	test   %eax,%eax
801036b3:	74 f0                	je     801036a5 <exit+0x28>
      fileclose(curproc->ofile[fd]);
801036b5:	83 ec 0c             	sub    $0xc,%esp
801036b8:	50                   	push   %eax
801036b9:	e8 15 d6 ff ff       	call   80100cd3 <fileclose>
      curproc->ofile[fd] = 0;
801036be:	c7 44 9e 28 00 00 00 	movl   $0x0,0x28(%esi,%ebx,4)
801036c5:	00 
801036c6:	83 c4 10             	add    $0x10,%esp
801036c9:	eb da                	jmp    801036a5 <exit+0x28>
  begin_op();
801036cb:	e8 b9 f1 ff ff       	call   80102889 <begin_op>
  iput(curproc->cwd);
801036d0:	83 ec 0c             	sub    $0xc,%esp
801036d3:	ff 76 68             	pushl  0x68(%esi)
801036d6:	e8 ad df ff ff       	call   80101688 <iput>
  end_op();
801036db:	e8 23 f2 ff ff       	call   80102903 <end_op>
  curproc->cwd = 0;
801036e0:	c7 46 68 00 00 00 00 	movl   $0x0,0x68(%esi)
  acquire(&ptable.lock);
801036e7:	c7 04 24 40 1d 13 80 	movl   $0x80131d40,(%esp)
801036ee:	e8 7d 05 00 00       	call   80103c70 <acquire>
  wakeup1(curproc->parent);
801036f3:	8b 46 14             	mov    0x14(%esi),%eax
801036f6:	e8 16 fa ff ff       	call   80103111 <wakeup1>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801036fb:	83 c4 10             	add    $0x10,%esp
801036fe:	bb 74 1d 13 80       	mov    $0x80131d74,%ebx
80103703:	eb 03                	jmp    80103708 <exit+0x8b>
80103705:	83 c3 7c             	add    $0x7c,%ebx
80103708:	81 fb 74 3c 13 80    	cmp    $0x80133c74,%ebx
8010370e:	73 1a                	jae    8010372a <exit+0xad>
    if(p->parent == curproc){
80103710:	39 73 14             	cmp    %esi,0x14(%ebx)
80103713:	75 f0                	jne    80103705 <exit+0x88>
      p->parent = initproc;
80103715:	a1 b8 95 10 80       	mov    0x801095b8,%eax
8010371a:	89 43 14             	mov    %eax,0x14(%ebx)
      if(p->state == ZOMBIE)
8010371d:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
80103721:	75 e2                	jne    80103705 <exit+0x88>
        wakeup1(initproc);
80103723:	e8 e9 f9 ff ff       	call   80103111 <wakeup1>
80103728:	eb db                	jmp    80103705 <exit+0x88>
  curproc->state = ZOMBIE;
8010372a:	c7 46 0c 05 00 00 00 	movl   $0x5,0xc(%esi)
  sched();
80103731:	e8 a4 fe ff ff       	call   801035da <sched>
  panic("zombie exit");
80103736:	83 ec 0c             	sub    $0xc,%esp
80103739:	68 5d 6b 10 80       	push   $0x80106b5d
8010373e:	e8 05 cc ff ff       	call   80100348 <panic>

80103743 <yield>:
{
80103743:	55                   	push   %ebp
80103744:	89 e5                	mov    %esp,%ebp
80103746:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80103749:	68 40 1d 13 80       	push   $0x80131d40
8010374e:	e8 1d 05 00 00       	call   80103c70 <acquire>
  myproc()->state = RUNNABLE;
80103753:	e8 79 fb ff ff       	call   801032d1 <myproc>
80103758:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
8010375f:	e8 76 fe ff ff       	call   801035da <sched>
  release(&ptable.lock);
80103764:	c7 04 24 40 1d 13 80 	movl   $0x80131d40,(%esp)
8010376b:	e8 65 05 00 00       	call   80103cd5 <release>
}
80103770:	83 c4 10             	add    $0x10,%esp
80103773:	c9                   	leave  
80103774:	c3                   	ret    

80103775 <sleep>:
{
80103775:	55                   	push   %ebp
80103776:	89 e5                	mov    %esp,%ebp
80103778:	56                   	push   %esi
80103779:	53                   	push   %ebx
8010377a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  struct proc *p = myproc();
8010377d:	e8 4f fb ff ff       	call   801032d1 <myproc>
  if(p == 0)
80103782:	85 c0                	test   %eax,%eax
80103784:	74 66                	je     801037ec <sleep+0x77>
80103786:	89 c6                	mov    %eax,%esi
  if(lk == 0)
80103788:	85 db                	test   %ebx,%ebx
8010378a:	74 6d                	je     801037f9 <sleep+0x84>
  if(lk != &ptable.lock){  //DOC: sleeplock0
8010378c:	81 fb 40 1d 13 80    	cmp    $0x80131d40,%ebx
80103792:	74 18                	je     801037ac <sleep+0x37>
    acquire(&ptable.lock);  //DOC: sleeplock1
80103794:	83 ec 0c             	sub    $0xc,%esp
80103797:	68 40 1d 13 80       	push   $0x80131d40
8010379c:	e8 cf 04 00 00       	call   80103c70 <acquire>
    release(lk);
801037a1:	89 1c 24             	mov    %ebx,(%esp)
801037a4:	e8 2c 05 00 00       	call   80103cd5 <release>
801037a9:	83 c4 10             	add    $0x10,%esp
  p->chan = chan;
801037ac:	8b 45 08             	mov    0x8(%ebp),%eax
801037af:	89 46 20             	mov    %eax,0x20(%esi)
  p->state = SLEEPING;
801037b2:	c7 46 0c 02 00 00 00 	movl   $0x2,0xc(%esi)
  sched();
801037b9:	e8 1c fe ff ff       	call   801035da <sched>
  p->chan = 0;
801037be:	c7 46 20 00 00 00 00 	movl   $0x0,0x20(%esi)
  if(lk != &ptable.lock){  //DOC: sleeplock2
801037c5:	81 fb 40 1d 13 80    	cmp    $0x80131d40,%ebx
801037cb:	74 18                	je     801037e5 <sleep+0x70>
    release(&ptable.lock);
801037cd:	83 ec 0c             	sub    $0xc,%esp
801037d0:	68 40 1d 13 80       	push   $0x80131d40
801037d5:	e8 fb 04 00 00       	call   80103cd5 <release>
    acquire(lk);
801037da:	89 1c 24             	mov    %ebx,(%esp)
801037dd:	e8 8e 04 00 00       	call   80103c70 <acquire>
801037e2:	83 c4 10             	add    $0x10,%esp
}
801037e5:	8d 65 f8             	lea    -0x8(%ebp),%esp
801037e8:	5b                   	pop    %ebx
801037e9:	5e                   	pop    %esi
801037ea:	5d                   	pop    %ebp
801037eb:	c3                   	ret    
    panic("sleep");
801037ec:	83 ec 0c             	sub    $0xc,%esp
801037ef:	68 69 6b 10 80       	push   $0x80106b69
801037f4:	e8 4f cb ff ff       	call   80100348 <panic>
    panic("sleep without lk");
801037f9:	83 ec 0c             	sub    $0xc,%esp
801037fc:	68 6f 6b 10 80       	push   $0x80106b6f
80103801:	e8 42 cb ff ff       	call   80100348 <panic>

80103806 <wait>:
{
80103806:	55                   	push   %ebp
80103807:	89 e5                	mov    %esp,%ebp
80103809:	56                   	push   %esi
8010380a:	53                   	push   %ebx
  struct proc *curproc = myproc();
8010380b:	e8 c1 fa ff ff       	call   801032d1 <myproc>
80103810:	89 c6                	mov    %eax,%esi
  acquire(&ptable.lock);
80103812:	83 ec 0c             	sub    $0xc,%esp
80103815:	68 40 1d 13 80       	push   $0x80131d40
8010381a:	e8 51 04 00 00       	call   80103c70 <acquire>
8010381f:	83 c4 10             	add    $0x10,%esp
    havekids = 0;
80103822:	b8 00 00 00 00       	mov    $0x0,%eax
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103827:	bb 74 1d 13 80       	mov    $0x80131d74,%ebx
8010382c:	eb 5b                	jmp    80103889 <wait+0x83>
        pid = p->pid;
8010382e:	8b 73 10             	mov    0x10(%ebx),%esi
        kfree(p->kstack);
80103831:	83 ec 0c             	sub    $0xc,%esp
80103834:	ff 73 08             	pushl  0x8(%ebx)
80103837:	e8 68 e7 ff ff       	call   80101fa4 <kfree>
        p->kstack = 0;
8010383c:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        freevm(p->pgdir);
80103843:	83 c4 04             	add    $0x4,%esp
80103846:	ff 73 04             	pushl  0x4(%ebx)
80103849:	e8 58 2a 00 00       	call   801062a6 <freevm>
        p->pid = 0;
8010384e:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
        p->parent = 0;
80103855:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
        p->name[0] = 0;
8010385c:	c6 43 6c 00          	movb   $0x0,0x6c(%ebx)
        p->killed = 0;
80103860:	c7 43 24 00 00 00 00 	movl   $0x0,0x24(%ebx)
        p->state = UNUSED;
80103867:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        release(&ptable.lock);
8010386e:	c7 04 24 40 1d 13 80 	movl   $0x80131d40,(%esp)
80103875:	e8 5b 04 00 00       	call   80103cd5 <release>
        return pid;
8010387a:	83 c4 10             	add    $0x10,%esp
}
8010387d:	89 f0                	mov    %esi,%eax
8010387f:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103882:	5b                   	pop    %ebx
80103883:	5e                   	pop    %esi
80103884:	5d                   	pop    %ebp
80103885:	c3                   	ret    
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103886:	83 c3 7c             	add    $0x7c,%ebx
80103889:	81 fb 74 3c 13 80    	cmp    $0x80133c74,%ebx
8010388f:	73 12                	jae    801038a3 <wait+0x9d>
      if(p->parent != curproc)
80103891:	39 73 14             	cmp    %esi,0x14(%ebx)
80103894:	75 f0                	jne    80103886 <wait+0x80>
      if(p->state == ZOMBIE){
80103896:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
8010389a:	74 92                	je     8010382e <wait+0x28>
      havekids = 1;
8010389c:	b8 01 00 00 00       	mov    $0x1,%eax
801038a1:	eb e3                	jmp    80103886 <wait+0x80>
    if(!havekids || curproc->killed){
801038a3:	85 c0                	test   %eax,%eax
801038a5:	74 06                	je     801038ad <wait+0xa7>
801038a7:	83 7e 24 00          	cmpl   $0x0,0x24(%esi)
801038ab:	74 17                	je     801038c4 <wait+0xbe>
      release(&ptable.lock);
801038ad:	83 ec 0c             	sub    $0xc,%esp
801038b0:	68 40 1d 13 80       	push   $0x80131d40
801038b5:	e8 1b 04 00 00       	call   80103cd5 <release>
      return -1;
801038ba:	83 c4 10             	add    $0x10,%esp
801038bd:	be ff ff ff ff       	mov    $0xffffffff,%esi
801038c2:	eb b9                	jmp    8010387d <wait+0x77>
    sleep(curproc, &ptable.lock);  //DOC: wait-sleep
801038c4:	83 ec 08             	sub    $0x8,%esp
801038c7:	68 40 1d 13 80       	push   $0x80131d40
801038cc:	56                   	push   %esi
801038cd:	e8 a3 fe ff ff       	call   80103775 <sleep>
    havekids = 0;
801038d2:	83 c4 10             	add    $0x10,%esp
801038d5:	e9 48 ff ff ff       	jmp    80103822 <wait+0x1c>

801038da <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
801038da:	55                   	push   %ebp
801038db:	89 e5                	mov    %esp,%ebp
801038dd:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);
801038e0:	68 40 1d 13 80       	push   $0x80131d40
801038e5:	e8 86 03 00 00       	call   80103c70 <acquire>
  wakeup1(chan);
801038ea:	8b 45 08             	mov    0x8(%ebp),%eax
801038ed:	e8 1f f8 ff ff       	call   80103111 <wakeup1>
  release(&ptable.lock);
801038f2:	c7 04 24 40 1d 13 80 	movl   $0x80131d40,(%esp)
801038f9:	e8 d7 03 00 00       	call   80103cd5 <release>
}
801038fe:	83 c4 10             	add    $0x10,%esp
80103901:	c9                   	leave  
80103902:	c3                   	ret    

80103903 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80103903:	55                   	push   %ebp
80103904:	89 e5                	mov    %esp,%ebp
80103906:	53                   	push   %ebx
80103907:	83 ec 10             	sub    $0x10,%esp
8010390a:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *p;

  acquire(&ptable.lock);
8010390d:	68 40 1d 13 80       	push   $0x80131d40
80103912:	e8 59 03 00 00       	call   80103c70 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103917:	83 c4 10             	add    $0x10,%esp
8010391a:	b8 74 1d 13 80       	mov    $0x80131d74,%eax
8010391f:	3d 74 3c 13 80       	cmp    $0x80133c74,%eax
80103924:	73 3a                	jae    80103960 <kill+0x5d>
    if(p->pid == pid){
80103926:	39 58 10             	cmp    %ebx,0x10(%eax)
80103929:	74 05                	je     80103930 <kill+0x2d>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010392b:	83 c0 7c             	add    $0x7c,%eax
8010392e:	eb ef                	jmp    8010391f <kill+0x1c>
      p->killed = 1;
80103930:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80103937:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
8010393b:	74 1a                	je     80103957 <kill+0x54>
        p->state = RUNNABLE;
      release(&ptable.lock);
8010393d:	83 ec 0c             	sub    $0xc,%esp
80103940:	68 40 1d 13 80       	push   $0x80131d40
80103945:	e8 8b 03 00 00       	call   80103cd5 <release>
      return 0;
8010394a:	83 c4 10             	add    $0x10,%esp
8010394d:	b8 00 00 00 00       	mov    $0x0,%eax
    }
  }
  release(&ptable.lock);
  return -1;
}
80103952:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103955:	c9                   	leave  
80103956:	c3                   	ret    
        p->state = RUNNABLE;
80103957:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
8010395e:	eb dd                	jmp    8010393d <kill+0x3a>
  release(&ptable.lock);
80103960:	83 ec 0c             	sub    $0xc,%esp
80103963:	68 40 1d 13 80       	push   $0x80131d40
80103968:	e8 68 03 00 00       	call   80103cd5 <release>
  return -1;
8010396d:	83 c4 10             	add    $0x10,%esp
80103970:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103975:	eb db                	jmp    80103952 <kill+0x4f>

80103977 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80103977:	55                   	push   %ebp
80103978:	89 e5                	mov    %esp,%ebp
8010397a:	56                   	push   %esi
8010397b:	53                   	push   %ebx
8010397c:	83 ec 30             	sub    $0x30,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010397f:	bb 74 1d 13 80       	mov    $0x80131d74,%ebx
80103984:	eb 33                	jmp    801039b9 <procdump+0x42>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
80103986:	b8 80 6b 10 80       	mov    $0x80106b80,%eax
    cprintf("%d %s %s", p->pid, state, p->name);
8010398b:	8d 53 6c             	lea    0x6c(%ebx),%edx
8010398e:	52                   	push   %edx
8010398f:	50                   	push   %eax
80103990:	ff 73 10             	pushl  0x10(%ebx)
80103993:	68 84 6b 10 80       	push   $0x80106b84
80103998:	e8 6e cc ff ff       	call   8010060b <cprintf>
    if(p->state == SLEEPING){
8010399d:	83 c4 10             	add    $0x10,%esp
801039a0:	83 7b 0c 02          	cmpl   $0x2,0xc(%ebx)
801039a4:	74 39                	je     801039df <procdump+0x68>
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
801039a6:	83 ec 0c             	sub    $0xc,%esp
801039a9:	68 fb 6e 10 80       	push   $0x80106efb
801039ae:	e8 58 cc ff ff       	call   8010060b <cprintf>
801039b3:	83 c4 10             	add    $0x10,%esp
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801039b6:	83 c3 7c             	add    $0x7c,%ebx
801039b9:	81 fb 74 3c 13 80    	cmp    $0x80133c74,%ebx
801039bf:	73 61                	jae    80103a22 <procdump+0xab>
    if(p->state == UNUSED)
801039c1:	8b 43 0c             	mov    0xc(%ebx),%eax
801039c4:	85 c0                	test   %eax,%eax
801039c6:	74 ee                	je     801039b6 <procdump+0x3f>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
801039c8:	83 f8 05             	cmp    $0x5,%eax
801039cb:	77 b9                	ja     80103986 <procdump+0xf>
801039cd:	8b 04 85 e0 6b 10 80 	mov    -0x7fef9420(,%eax,4),%eax
801039d4:	85 c0                	test   %eax,%eax
801039d6:	75 b3                	jne    8010398b <procdump+0x14>
      state = "???";
801039d8:	b8 80 6b 10 80       	mov    $0x80106b80,%eax
801039dd:	eb ac                	jmp    8010398b <procdump+0x14>
      getcallerpcs((uint*)p->context->ebp+2, pc);
801039df:	8b 43 1c             	mov    0x1c(%ebx),%eax
801039e2:	8b 40 0c             	mov    0xc(%eax),%eax
801039e5:	83 c0 08             	add    $0x8,%eax
801039e8:	83 ec 08             	sub    $0x8,%esp
801039eb:	8d 55 d0             	lea    -0x30(%ebp),%edx
801039ee:	52                   	push   %edx
801039ef:	50                   	push   %eax
801039f0:	e8 5a 01 00 00       	call   80103b4f <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
801039f5:	83 c4 10             	add    $0x10,%esp
801039f8:	be 00 00 00 00       	mov    $0x0,%esi
801039fd:	eb 14                	jmp    80103a13 <procdump+0x9c>
        cprintf(" %p", pc[i]);
801039ff:	83 ec 08             	sub    $0x8,%esp
80103a02:	50                   	push   %eax
80103a03:	68 c1 65 10 80       	push   $0x801065c1
80103a08:	e8 fe cb ff ff       	call   8010060b <cprintf>
      for(i=0; i<10 && pc[i] != 0; i++)
80103a0d:	83 c6 01             	add    $0x1,%esi
80103a10:	83 c4 10             	add    $0x10,%esp
80103a13:	83 fe 09             	cmp    $0x9,%esi
80103a16:	7f 8e                	jg     801039a6 <procdump+0x2f>
80103a18:	8b 44 b5 d0          	mov    -0x30(%ebp,%esi,4),%eax
80103a1c:	85 c0                	test   %eax,%eax
80103a1e:	75 df                	jne    801039ff <procdump+0x88>
80103a20:	eb 84                	jmp    801039a6 <procdump+0x2f>
  }
}
80103a22:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103a25:	5b                   	pop    %ebx
80103a26:	5e                   	pop    %esi
80103a27:	5d                   	pop    %ebp
80103a28:	c3                   	ret    

80103a29 <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
80103a29:	55                   	push   %ebp
80103a2a:	89 e5                	mov    %esp,%ebp
80103a2c:	53                   	push   %ebx
80103a2d:	83 ec 0c             	sub    $0xc,%esp
80103a30:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&lk->lk, "sleep lock");
80103a33:	68 f8 6b 10 80       	push   $0x80106bf8
80103a38:	8d 43 04             	lea    0x4(%ebx),%eax
80103a3b:	50                   	push   %eax
80103a3c:	e8 f3 00 00 00       	call   80103b34 <initlock>
  lk->name = name;
80103a41:	8b 45 0c             	mov    0xc(%ebp),%eax
80103a44:	89 43 38             	mov    %eax,0x38(%ebx)
  lk->locked = 0;
80103a47:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103a4d:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
}
80103a54:	83 c4 10             	add    $0x10,%esp
80103a57:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103a5a:	c9                   	leave  
80103a5b:	c3                   	ret    

80103a5c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80103a5c:	55                   	push   %ebp
80103a5d:	89 e5                	mov    %esp,%ebp
80103a5f:	56                   	push   %esi
80103a60:	53                   	push   %ebx
80103a61:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103a64:	8d 73 04             	lea    0x4(%ebx),%esi
80103a67:	83 ec 0c             	sub    $0xc,%esp
80103a6a:	56                   	push   %esi
80103a6b:	e8 00 02 00 00       	call   80103c70 <acquire>
  while (lk->locked) {
80103a70:	83 c4 10             	add    $0x10,%esp
80103a73:	eb 0d                	jmp    80103a82 <acquiresleep+0x26>
    sleep(lk, &lk->lk);
80103a75:	83 ec 08             	sub    $0x8,%esp
80103a78:	56                   	push   %esi
80103a79:	53                   	push   %ebx
80103a7a:	e8 f6 fc ff ff       	call   80103775 <sleep>
80103a7f:	83 c4 10             	add    $0x10,%esp
  while (lk->locked) {
80103a82:	83 3b 00             	cmpl   $0x0,(%ebx)
80103a85:	75 ee                	jne    80103a75 <acquiresleep+0x19>
  }
  lk->locked = 1;
80103a87:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
  lk->pid = myproc()->pid;
80103a8d:	e8 3f f8 ff ff       	call   801032d1 <myproc>
80103a92:	8b 40 10             	mov    0x10(%eax),%eax
80103a95:	89 43 3c             	mov    %eax,0x3c(%ebx)
  release(&lk->lk);
80103a98:	83 ec 0c             	sub    $0xc,%esp
80103a9b:	56                   	push   %esi
80103a9c:	e8 34 02 00 00       	call   80103cd5 <release>
}
80103aa1:	83 c4 10             	add    $0x10,%esp
80103aa4:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103aa7:	5b                   	pop    %ebx
80103aa8:	5e                   	pop    %esi
80103aa9:	5d                   	pop    %ebp
80103aaa:	c3                   	ret    

80103aab <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80103aab:	55                   	push   %ebp
80103aac:	89 e5                	mov    %esp,%ebp
80103aae:	56                   	push   %esi
80103aaf:	53                   	push   %ebx
80103ab0:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103ab3:	8d 73 04             	lea    0x4(%ebx),%esi
80103ab6:	83 ec 0c             	sub    $0xc,%esp
80103ab9:	56                   	push   %esi
80103aba:	e8 b1 01 00 00       	call   80103c70 <acquire>
  lk->locked = 0;
80103abf:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103ac5:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
  wakeup(lk);
80103acc:	89 1c 24             	mov    %ebx,(%esp)
80103acf:	e8 06 fe ff ff       	call   801038da <wakeup>
  release(&lk->lk);
80103ad4:	89 34 24             	mov    %esi,(%esp)
80103ad7:	e8 f9 01 00 00       	call   80103cd5 <release>
}
80103adc:	83 c4 10             	add    $0x10,%esp
80103adf:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103ae2:	5b                   	pop    %ebx
80103ae3:	5e                   	pop    %esi
80103ae4:	5d                   	pop    %ebp
80103ae5:	c3                   	ret    

80103ae6 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80103ae6:	55                   	push   %ebp
80103ae7:	89 e5                	mov    %esp,%ebp
80103ae9:	56                   	push   %esi
80103aea:	53                   	push   %ebx
80103aeb:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;
  
  acquire(&lk->lk);
80103aee:	8d 73 04             	lea    0x4(%ebx),%esi
80103af1:	83 ec 0c             	sub    $0xc,%esp
80103af4:	56                   	push   %esi
80103af5:	e8 76 01 00 00       	call   80103c70 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
80103afa:	83 c4 10             	add    $0x10,%esp
80103afd:	83 3b 00             	cmpl   $0x0,(%ebx)
80103b00:	75 17                	jne    80103b19 <holdingsleep+0x33>
80103b02:	bb 00 00 00 00       	mov    $0x0,%ebx
  release(&lk->lk);
80103b07:	83 ec 0c             	sub    $0xc,%esp
80103b0a:	56                   	push   %esi
80103b0b:	e8 c5 01 00 00       	call   80103cd5 <release>
  return r;
}
80103b10:	89 d8                	mov    %ebx,%eax
80103b12:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103b15:	5b                   	pop    %ebx
80103b16:	5e                   	pop    %esi
80103b17:	5d                   	pop    %ebp
80103b18:	c3                   	ret    
  r = lk->locked && (lk->pid == myproc()->pid);
80103b19:	8b 5b 3c             	mov    0x3c(%ebx),%ebx
80103b1c:	e8 b0 f7 ff ff       	call   801032d1 <myproc>
80103b21:	3b 58 10             	cmp    0x10(%eax),%ebx
80103b24:	74 07                	je     80103b2d <holdingsleep+0x47>
80103b26:	bb 00 00 00 00       	mov    $0x0,%ebx
80103b2b:	eb da                	jmp    80103b07 <holdingsleep+0x21>
80103b2d:	bb 01 00 00 00       	mov    $0x1,%ebx
80103b32:	eb d3                	jmp    80103b07 <holdingsleep+0x21>

80103b34 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80103b34:	55                   	push   %ebp
80103b35:	89 e5                	mov    %esp,%ebp
80103b37:	8b 45 08             	mov    0x8(%ebp),%eax
  lk->name = name;
80103b3a:	8b 55 0c             	mov    0xc(%ebp),%edx
80103b3d:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80103b40:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80103b46:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80103b4d:	5d                   	pop    %ebp
80103b4e:	c3                   	ret    

80103b4f <getcallerpcs>:
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80103b4f:	55                   	push   %ebp
80103b50:	89 e5                	mov    %esp,%ebp
80103b52:	53                   	push   %ebx
80103b53:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80103b56:	8b 45 08             	mov    0x8(%ebp),%eax
80103b59:	8d 50 f8             	lea    -0x8(%eax),%edx
  for(i = 0; i < 10; i++){
80103b5c:	b8 00 00 00 00       	mov    $0x0,%eax
80103b61:	83 f8 09             	cmp    $0x9,%eax
80103b64:	7f 25                	jg     80103b8b <getcallerpcs+0x3c>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80103b66:	8d 9a 00 00 00 80    	lea    -0x80000000(%edx),%ebx
80103b6c:	81 fb fe ff ff 7f    	cmp    $0x7ffffffe,%ebx
80103b72:	77 17                	ja     80103b8b <getcallerpcs+0x3c>
      break;
    pcs[i] = ebp[1];     // saved %eip
80103b74:	8b 5a 04             	mov    0x4(%edx),%ebx
80103b77:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
    ebp = (uint*)ebp[0]; // saved %ebp
80103b7a:	8b 12                	mov    (%edx),%edx
  for(i = 0; i < 10; i++){
80103b7c:	83 c0 01             	add    $0x1,%eax
80103b7f:	eb e0                	jmp    80103b61 <getcallerpcs+0x12>
  }
  for(; i < 10; i++)
    pcs[i] = 0;
80103b81:	c7 04 81 00 00 00 00 	movl   $0x0,(%ecx,%eax,4)
  for(; i < 10; i++)
80103b88:	83 c0 01             	add    $0x1,%eax
80103b8b:	83 f8 09             	cmp    $0x9,%eax
80103b8e:	7e f1                	jle    80103b81 <getcallerpcs+0x32>
}
80103b90:	5b                   	pop    %ebx
80103b91:	5d                   	pop    %ebp
80103b92:	c3                   	ret    

80103b93 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80103b93:	55                   	push   %ebp
80103b94:	89 e5                	mov    %esp,%ebp
80103b96:	53                   	push   %ebx
80103b97:	83 ec 04             	sub    $0x4,%esp
80103b9a:	9c                   	pushf  
80103b9b:	5b                   	pop    %ebx
  asm volatile("cli");
80103b9c:	fa                   	cli    
  int eflags;

  eflags = readeflags();
  cli();
  if(mycpu()->ncli == 0)
80103b9d:	e8 b8 f6 ff ff       	call   8010325a <mycpu>
80103ba2:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103ba9:	74 12                	je     80103bbd <pushcli+0x2a>
    mycpu()->intena = eflags & FL_IF;
  mycpu()->ncli += 1;
80103bab:	e8 aa f6 ff ff       	call   8010325a <mycpu>
80103bb0:	83 80 a4 00 00 00 01 	addl   $0x1,0xa4(%eax)
}
80103bb7:	83 c4 04             	add    $0x4,%esp
80103bba:	5b                   	pop    %ebx
80103bbb:	5d                   	pop    %ebp
80103bbc:	c3                   	ret    
    mycpu()->intena = eflags & FL_IF;
80103bbd:	e8 98 f6 ff ff       	call   8010325a <mycpu>
80103bc2:	81 e3 00 02 00 00    	and    $0x200,%ebx
80103bc8:	89 98 a8 00 00 00    	mov    %ebx,0xa8(%eax)
80103bce:	eb db                	jmp    80103bab <pushcli+0x18>

80103bd0 <popcli>:

void
popcli(void)
{
80103bd0:	55                   	push   %ebp
80103bd1:	89 e5                	mov    %esp,%ebp
80103bd3:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103bd6:	9c                   	pushf  
80103bd7:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103bd8:	f6 c4 02             	test   $0x2,%ah
80103bdb:	75 28                	jne    80103c05 <popcli+0x35>
    panic("popcli - interruptible");
  if(--mycpu()->ncli < 0)
80103bdd:	e8 78 f6 ff ff       	call   8010325a <mycpu>
80103be2:	8b 88 a4 00 00 00    	mov    0xa4(%eax),%ecx
80103be8:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103beb:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
80103bf1:	85 d2                	test   %edx,%edx
80103bf3:	78 1d                	js     80103c12 <popcli+0x42>
    panic("popcli");
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103bf5:	e8 60 f6 ff ff       	call   8010325a <mycpu>
80103bfa:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103c01:	74 1c                	je     80103c1f <popcli+0x4f>
    sti();
}
80103c03:	c9                   	leave  
80103c04:	c3                   	ret    
    panic("popcli - interruptible");
80103c05:	83 ec 0c             	sub    $0xc,%esp
80103c08:	68 03 6c 10 80       	push   $0x80106c03
80103c0d:	e8 36 c7 ff ff       	call   80100348 <panic>
    panic("popcli");
80103c12:	83 ec 0c             	sub    $0xc,%esp
80103c15:	68 1a 6c 10 80       	push   $0x80106c1a
80103c1a:	e8 29 c7 ff ff       	call   80100348 <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103c1f:	e8 36 f6 ff ff       	call   8010325a <mycpu>
80103c24:	83 b8 a8 00 00 00 00 	cmpl   $0x0,0xa8(%eax)
80103c2b:	74 d6                	je     80103c03 <popcli+0x33>
  asm volatile("sti");
80103c2d:	fb                   	sti    
}
80103c2e:	eb d3                	jmp    80103c03 <popcli+0x33>

80103c30 <holding>:
{
80103c30:	55                   	push   %ebp
80103c31:	89 e5                	mov    %esp,%ebp
80103c33:	53                   	push   %ebx
80103c34:	83 ec 04             	sub    $0x4,%esp
80103c37:	8b 5d 08             	mov    0x8(%ebp),%ebx
  pushcli();
80103c3a:	e8 54 ff ff ff       	call   80103b93 <pushcli>
  r = lock->locked && lock->cpu == mycpu();
80103c3f:	83 3b 00             	cmpl   $0x0,(%ebx)
80103c42:	75 12                	jne    80103c56 <holding+0x26>
80103c44:	bb 00 00 00 00       	mov    $0x0,%ebx
  popcli();
80103c49:	e8 82 ff ff ff       	call   80103bd0 <popcli>
}
80103c4e:	89 d8                	mov    %ebx,%eax
80103c50:	83 c4 04             	add    $0x4,%esp
80103c53:	5b                   	pop    %ebx
80103c54:	5d                   	pop    %ebp
80103c55:	c3                   	ret    
  r = lock->locked && lock->cpu == mycpu();
80103c56:	8b 5b 08             	mov    0x8(%ebx),%ebx
80103c59:	e8 fc f5 ff ff       	call   8010325a <mycpu>
80103c5e:	39 c3                	cmp    %eax,%ebx
80103c60:	74 07                	je     80103c69 <holding+0x39>
80103c62:	bb 00 00 00 00       	mov    $0x0,%ebx
80103c67:	eb e0                	jmp    80103c49 <holding+0x19>
80103c69:	bb 01 00 00 00       	mov    $0x1,%ebx
80103c6e:	eb d9                	jmp    80103c49 <holding+0x19>

80103c70 <acquire>:
{
80103c70:	55                   	push   %ebp
80103c71:	89 e5                	mov    %esp,%ebp
80103c73:	53                   	push   %ebx
80103c74:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80103c77:	e8 17 ff ff ff       	call   80103b93 <pushcli>
  if(holding(lk))
80103c7c:	83 ec 0c             	sub    $0xc,%esp
80103c7f:	ff 75 08             	pushl  0x8(%ebp)
80103c82:	e8 a9 ff ff ff       	call   80103c30 <holding>
80103c87:	83 c4 10             	add    $0x10,%esp
80103c8a:	85 c0                	test   %eax,%eax
80103c8c:	75 3a                	jne    80103cc8 <acquire+0x58>
  while(xchg(&lk->locked, 1) != 0)
80103c8e:	8b 55 08             	mov    0x8(%ebp),%edx
  asm volatile("lock; xchgl %0, %1" :
80103c91:	b8 01 00 00 00       	mov    $0x1,%eax
80103c96:	f0 87 02             	lock xchg %eax,(%edx)
80103c99:	85 c0                	test   %eax,%eax
80103c9b:	75 f1                	jne    80103c8e <acquire+0x1e>
  __sync_synchronize();
80103c9d:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  lk->cpu = mycpu();
80103ca2:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103ca5:	e8 b0 f5 ff ff       	call   8010325a <mycpu>
80103caa:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
80103cad:	8b 45 08             	mov    0x8(%ebp),%eax
80103cb0:	83 c0 0c             	add    $0xc,%eax
80103cb3:	83 ec 08             	sub    $0x8,%esp
80103cb6:	50                   	push   %eax
80103cb7:	8d 45 08             	lea    0x8(%ebp),%eax
80103cba:	50                   	push   %eax
80103cbb:	e8 8f fe ff ff       	call   80103b4f <getcallerpcs>
}
80103cc0:	83 c4 10             	add    $0x10,%esp
80103cc3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103cc6:	c9                   	leave  
80103cc7:	c3                   	ret    
    panic("acquire");
80103cc8:	83 ec 0c             	sub    $0xc,%esp
80103ccb:	68 21 6c 10 80       	push   $0x80106c21
80103cd0:	e8 73 c6 ff ff       	call   80100348 <panic>

80103cd5 <release>:
{
80103cd5:	55                   	push   %ebp
80103cd6:	89 e5                	mov    %esp,%ebp
80103cd8:	53                   	push   %ebx
80103cd9:	83 ec 10             	sub    $0x10,%esp
80103cdc:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holding(lk))
80103cdf:	53                   	push   %ebx
80103ce0:	e8 4b ff ff ff       	call   80103c30 <holding>
80103ce5:	83 c4 10             	add    $0x10,%esp
80103ce8:	85 c0                	test   %eax,%eax
80103cea:	74 23                	je     80103d0f <release+0x3a>
  lk->pcs[0] = 0;
80103cec:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
  lk->cpu = 0;
80103cf3:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
  __sync_synchronize();
80103cfa:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
80103cff:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  popcli();
80103d05:	e8 c6 fe ff ff       	call   80103bd0 <popcli>
}
80103d0a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103d0d:	c9                   	leave  
80103d0e:	c3                   	ret    
    panic("release");
80103d0f:	83 ec 0c             	sub    $0xc,%esp
80103d12:	68 29 6c 10 80       	push   $0x80106c29
80103d17:	e8 2c c6 ff ff       	call   80100348 <panic>

80103d1c <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80103d1c:	55                   	push   %ebp
80103d1d:	89 e5                	mov    %esp,%ebp
80103d1f:	57                   	push   %edi
80103d20:	53                   	push   %ebx
80103d21:	8b 55 08             	mov    0x8(%ebp),%edx
80103d24:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if ((int)dst%4 == 0 && n%4 == 0){
80103d27:	f6 c2 03             	test   $0x3,%dl
80103d2a:	75 05                	jne    80103d31 <memset+0x15>
80103d2c:	f6 c1 03             	test   $0x3,%cl
80103d2f:	74 0e                	je     80103d3f <memset+0x23>
  asm volatile("cld; rep stosb" :
80103d31:	89 d7                	mov    %edx,%edi
80103d33:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d36:	fc                   	cld    
80103d37:	f3 aa                	rep stos %al,%es:(%edi)
    c &= 0xFF;
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
  } else
    stosb(dst, c, n);
  return dst;
}
80103d39:	89 d0                	mov    %edx,%eax
80103d3b:	5b                   	pop    %ebx
80103d3c:	5f                   	pop    %edi
80103d3d:	5d                   	pop    %ebp
80103d3e:	c3                   	ret    
    c &= 0xFF;
80103d3f:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80103d43:	c1 e9 02             	shr    $0x2,%ecx
80103d46:	89 f8                	mov    %edi,%eax
80103d48:	c1 e0 18             	shl    $0x18,%eax
80103d4b:	89 fb                	mov    %edi,%ebx
80103d4d:	c1 e3 10             	shl    $0x10,%ebx
80103d50:	09 d8                	or     %ebx,%eax
80103d52:	89 fb                	mov    %edi,%ebx
80103d54:	c1 e3 08             	shl    $0x8,%ebx
80103d57:	09 d8                	or     %ebx,%eax
80103d59:	09 f8                	or     %edi,%eax
  asm volatile("cld; rep stosl" :
80103d5b:	89 d7                	mov    %edx,%edi
80103d5d:	fc                   	cld    
80103d5e:	f3 ab                	rep stos %eax,%es:(%edi)
80103d60:	eb d7                	jmp    80103d39 <memset+0x1d>

80103d62 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80103d62:	55                   	push   %ebp
80103d63:	89 e5                	mov    %esp,%ebp
80103d65:	56                   	push   %esi
80103d66:	53                   	push   %ebx
80103d67:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103d6a:	8b 55 0c             	mov    0xc(%ebp),%edx
80103d6d:	8b 45 10             	mov    0x10(%ebp),%eax
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80103d70:	8d 70 ff             	lea    -0x1(%eax),%esi
80103d73:	85 c0                	test   %eax,%eax
80103d75:	74 1c                	je     80103d93 <memcmp+0x31>
    if(*s1 != *s2)
80103d77:	0f b6 01             	movzbl (%ecx),%eax
80103d7a:	0f b6 1a             	movzbl (%edx),%ebx
80103d7d:	38 d8                	cmp    %bl,%al
80103d7f:	75 0a                	jne    80103d8b <memcmp+0x29>
      return *s1 - *s2;
    s1++, s2++;
80103d81:	83 c1 01             	add    $0x1,%ecx
80103d84:	83 c2 01             	add    $0x1,%edx
  while(n-- > 0){
80103d87:	89 f0                	mov    %esi,%eax
80103d89:	eb e5                	jmp    80103d70 <memcmp+0xe>
      return *s1 - *s2;
80103d8b:	0f b6 c0             	movzbl %al,%eax
80103d8e:	0f b6 db             	movzbl %bl,%ebx
80103d91:	29 d8                	sub    %ebx,%eax
  }

  return 0;
}
80103d93:	5b                   	pop    %ebx
80103d94:	5e                   	pop    %esi
80103d95:	5d                   	pop    %ebp
80103d96:	c3                   	ret    

80103d97 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80103d97:	55                   	push   %ebp
80103d98:	89 e5                	mov    %esp,%ebp
80103d9a:	56                   	push   %esi
80103d9b:	53                   	push   %ebx
80103d9c:	8b 45 08             	mov    0x8(%ebp),%eax
80103d9f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103da2:	8b 55 10             	mov    0x10(%ebp),%edx
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80103da5:	39 c1                	cmp    %eax,%ecx
80103da7:	73 3a                	jae    80103de3 <memmove+0x4c>
80103da9:	8d 1c 11             	lea    (%ecx,%edx,1),%ebx
80103dac:	39 c3                	cmp    %eax,%ebx
80103dae:	76 37                	jbe    80103de7 <memmove+0x50>
    s += n;
    d += n;
80103db0:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
    while(n-- > 0)
80103db3:	eb 0d                	jmp    80103dc2 <memmove+0x2b>
      *--d = *--s;
80103db5:	83 eb 01             	sub    $0x1,%ebx
80103db8:	83 e9 01             	sub    $0x1,%ecx
80103dbb:	0f b6 13             	movzbl (%ebx),%edx
80103dbe:	88 11                	mov    %dl,(%ecx)
    while(n-- > 0)
80103dc0:	89 f2                	mov    %esi,%edx
80103dc2:	8d 72 ff             	lea    -0x1(%edx),%esi
80103dc5:	85 d2                	test   %edx,%edx
80103dc7:	75 ec                	jne    80103db5 <memmove+0x1e>
80103dc9:	eb 14                	jmp    80103ddf <memmove+0x48>
  } else
    while(n-- > 0)
      *d++ = *s++;
80103dcb:	0f b6 11             	movzbl (%ecx),%edx
80103dce:	88 13                	mov    %dl,(%ebx)
80103dd0:	8d 5b 01             	lea    0x1(%ebx),%ebx
80103dd3:	8d 49 01             	lea    0x1(%ecx),%ecx
    while(n-- > 0)
80103dd6:	89 f2                	mov    %esi,%edx
80103dd8:	8d 72 ff             	lea    -0x1(%edx),%esi
80103ddb:	85 d2                	test   %edx,%edx
80103ddd:	75 ec                	jne    80103dcb <memmove+0x34>

  return dst;
}
80103ddf:	5b                   	pop    %ebx
80103de0:	5e                   	pop    %esi
80103de1:	5d                   	pop    %ebp
80103de2:	c3                   	ret    
80103de3:	89 c3                	mov    %eax,%ebx
80103de5:	eb f1                	jmp    80103dd8 <memmove+0x41>
80103de7:	89 c3                	mov    %eax,%ebx
80103de9:	eb ed                	jmp    80103dd8 <memmove+0x41>

80103deb <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80103deb:	55                   	push   %ebp
80103dec:	89 e5                	mov    %esp,%ebp
  return memmove(dst, src, n);
80103dee:	ff 75 10             	pushl  0x10(%ebp)
80103df1:	ff 75 0c             	pushl  0xc(%ebp)
80103df4:	ff 75 08             	pushl  0x8(%ebp)
80103df7:	e8 9b ff ff ff       	call   80103d97 <memmove>
}
80103dfc:	c9                   	leave  
80103dfd:	c3                   	ret    

80103dfe <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80103dfe:	55                   	push   %ebp
80103dff:	89 e5                	mov    %esp,%ebp
80103e01:	53                   	push   %ebx
80103e02:	8b 55 08             	mov    0x8(%ebp),%edx
80103e05:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103e08:	8b 45 10             	mov    0x10(%ebp),%eax
  while(n > 0 && *p && *p == *q)
80103e0b:	eb 09                	jmp    80103e16 <strncmp+0x18>
    n--, p++, q++;
80103e0d:	83 e8 01             	sub    $0x1,%eax
80103e10:	83 c2 01             	add    $0x1,%edx
80103e13:	83 c1 01             	add    $0x1,%ecx
  while(n > 0 && *p && *p == *q)
80103e16:	85 c0                	test   %eax,%eax
80103e18:	74 0b                	je     80103e25 <strncmp+0x27>
80103e1a:	0f b6 1a             	movzbl (%edx),%ebx
80103e1d:	84 db                	test   %bl,%bl
80103e1f:	74 04                	je     80103e25 <strncmp+0x27>
80103e21:	3a 19                	cmp    (%ecx),%bl
80103e23:	74 e8                	je     80103e0d <strncmp+0xf>
  if(n == 0)
80103e25:	85 c0                	test   %eax,%eax
80103e27:	74 0b                	je     80103e34 <strncmp+0x36>
    return 0;
  return (uchar)*p - (uchar)*q;
80103e29:	0f b6 02             	movzbl (%edx),%eax
80103e2c:	0f b6 11             	movzbl (%ecx),%edx
80103e2f:	29 d0                	sub    %edx,%eax
}
80103e31:	5b                   	pop    %ebx
80103e32:	5d                   	pop    %ebp
80103e33:	c3                   	ret    
    return 0;
80103e34:	b8 00 00 00 00       	mov    $0x0,%eax
80103e39:	eb f6                	jmp    80103e31 <strncmp+0x33>

80103e3b <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80103e3b:	55                   	push   %ebp
80103e3c:	89 e5                	mov    %esp,%ebp
80103e3e:	57                   	push   %edi
80103e3f:	56                   	push   %esi
80103e40:	53                   	push   %ebx
80103e41:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103e44:	8b 4d 10             	mov    0x10(%ebp),%ecx
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
80103e47:	8b 45 08             	mov    0x8(%ebp),%eax
80103e4a:	eb 04                	jmp    80103e50 <strncpy+0x15>
80103e4c:	89 fb                	mov    %edi,%ebx
80103e4e:	89 f0                	mov    %esi,%eax
80103e50:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103e53:	85 c9                	test   %ecx,%ecx
80103e55:	7e 1d                	jle    80103e74 <strncpy+0x39>
80103e57:	8d 7b 01             	lea    0x1(%ebx),%edi
80103e5a:	8d 70 01             	lea    0x1(%eax),%esi
80103e5d:	0f b6 1b             	movzbl (%ebx),%ebx
80103e60:	88 18                	mov    %bl,(%eax)
80103e62:	89 d1                	mov    %edx,%ecx
80103e64:	84 db                	test   %bl,%bl
80103e66:	75 e4                	jne    80103e4c <strncpy+0x11>
80103e68:	89 f0                	mov    %esi,%eax
80103e6a:	eb 08                	jmp    80103e74 <strncpy+0x39>
    ;
  while(n-- > 0)
    *s++ = 0;
80103e6c:	c6 00 00             	movb   $0x0,(%eax)
  while(n-- > 0)
80103e6f:	89 ca                	mov    %ecx,%edx
    *s++ = 0;
80103e71:	8d 40 01             	lea    0x1(%eax),%eax
  while(n-- > 0)
80103e74:	8d 4a ff             	lea    -0x1(%edx),%ecx
80103e77:	85 d2                	test   %edx,%edx
80103e79:	7f f1                	jg     80103e6c <strncpy+0x31>
  return os;
}
80103e7b:	8b 45 08             	mov    0x8(%ebp),%eax
80103e7e:	5b                   	pop    %ebx
80103e7f:	5e                   	pop    %esi
80103e80:	5f                   	pop    %edi
80103e81:	5d                   	pop    %ebp
80103e82:	c3                   	ret    

80103e83 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80103e83:	55                   	push   %ebp
80103e84:	89 e5                	mov    %esp,%ebp
80103e86:	57                   	push   %edi
80103e87:	56                   	push   %esi
80103e88:	53                   	push   %ebx
80103e89:	8b 45 08             	mov    0x8(%ebp),%eax
80103e8c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103e8f:	8b 55 10             	mov    0x10(%ebp),%edx
  char *os;

  os = s;
  if(n <= 0)
80103e92:	85 d2                	test   %edx,%edx
80103e94:	7e 23                	jle    80103eb9 <safestrcpy+0x36>
80103e96:	89 c1                	mov    %eax,%ecx
80103e98:	eb 04                	jmp    80103e9e <safestrcpy+0x1b>
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
80103e9a:	89 fb                	mov    %edi,%ebx
80103e9c:	89 f1                	mov    %esi,%ecx
80103e9e:	83 ea 01             	sub    $0x1,%edx
80103ea1:	85 d2                	test   %edx,%edx
80103ea3:	7e 11                	jle    80103eb6 <safestrcpy+0x33>
80103ea5:	8d 7b 01             	lea    0x1(%ebx),%edi
80103ea8:	8d 71 01             	lea    0x1(%ecx),%esi
80103eab:	0f b6 1b             	movzbl (%ebx),%ebx
80103eae:	88 19                	mov    %bl,(%ecx)
80103eb0:	84 db                	test   %bl,%bl
80103eb2:	75 e6                	jne    80103e9a <safestrcpy+0x17>
80103eb4:	89 f1                	mov    %esi,%ecx
    ;
  *s = 0;
80103eb6:	c6 01 00             	movb   $0x0,(%ecx)
  return os;
}
80103eb9:	5b                   	pop    %ebx
80103eba:	5e                   	pop    %esi
80103ebb:	5f                   	pop    %edi
80103ebc:	5d                   	pop    %ebp
80103ebd:	c3                   	ret    

80103ebe <strlen>:

int
strlen(const char *s)
{
80103ebe:	55                   	push   %ebp
80103ebf:	89 e5                	mov    %esp,%ebp
80103ec1:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
80103ec4:	b8 00 00 00 00       	mov    $0x0,%eax
80103ec9:	eb 03                	jmp    80103ece <strlen+0x10>
80103ecb:	83 c0 01             	add    $0x1,%eax
80103ece:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
80103ed2:	75 f7                	jne    80103ecb <strlen+0xd>
    ;
  return n;
}
80103ed4:	5d                   	pop    %ebp
80103ed5:	c3                   	ret    

80103ed6 <swtch>:
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax
80103ed6:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80103eda:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-saved registers
  pushl %ebp
80103ede:	55                   	push   %ebp
  pushl %ebx
80103edf:	53                   	push   %ebx
  pushl %esi
80103ee0:	56                   	push   %esi
  pushl %edi
80103ee1:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80103ee2:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80103ee4:	89 d4                	mov    %edx,%esp

  # Load new callee-saved registers
  popl %edi
80103ee6:	5f                   	pop    %edi
  popl %esi
80103ee7:	5e                   	pop    %esi
  popl %ebx
80103ee8:	5b                   	pop    %ebx
  popl %ebp
80103ee9:	5d                   	pop    %ebp
  ret
80103eea:	c3                   	ret    

80103eeb <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80103eeb:	55                   	push   %ebp
80103eec:	89 e5                	mov    %esp,%ebp
80103eee:	53                   	push   %ebx
80103eef:	83 ec 04             	sub    $0x4,%esp
80103ef2:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *curproc = myproc();
80103ef5:	e8 d7 f3 ff ff       	call   801032d1 <myproc>

  if(addr >= curproc->sz || addr+4 > curproc->sz)
80103efa:	8b 00                	mov    (%eax),%eax
80103efc:	39 d8                	cmp    %ebx,%eax
80103efe:	76 19                	jbe    80103f19 <fetchint+0x2e>
80103f00:	8d 53 04             	lea    0x4(%ebx),%edx
80103f03:	39 d0                	cmp    %edx,%eax
80103f05:	72 19                	jb     80103f20 <fetchint+0x35>
    return -1;
  *ip = *(int*)(addr);
80103f07:	8b 13                	mov    (%ebx),%edx
80103f09:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f0c:	89 10                	mov    %edx,(%eax)
  return 0;
80103f0e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103f13:	83 c4 04             	add    $0x4,%esp
80103f16:	5b                   	pop    %ebx
80103f17:	5d                   	pop    %ebp
80103f18:	c3                   	ret    
    return -1;
80103f19:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f1e:	eb f3                	jmp    80103f13 <fetchint+0x28>
80103f20:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f25:	eb ec                	jmp    80103f13 <fetchint+0x28>

80103f27 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80103f27:	55                   	push   %ebp
80103f28:	89 e5                	mov    %esp,%ebp
80103f2a:	53                   	push   %ebx
80103f2b:	83 ec 04             	sub    $0x4,%esp
80103f2e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  char *s, *ep;
  struct proc *curproc = myproc();
80103f31:	e8 9b f3 ff ff       	call   801032d1 <myproc>

  if(addr >= curproc->sz)
80103f36:	39 18                	cmp    %ebx,(%eax)
80103f38:	76 26                	jbe    80103f60 <fetchstr+0x39>
    return -1;
  *pp = (char*)addr;
80103f3a:	8b 55 0c             	mov    0xc(%ebp),%edx
80103f3d:	89 1a                	mov    %ebx,(%edx)
  ep = (char*)curproc->sz;
80103f3f:	8b 10                	mov    (%eax),%edx
  for(s = *pp; s < ep; s++){
80103f41:	89 d8                	mov    %ebx,%eax
80103f43:	39 d0                	cmp    %edx,%eax
80103f45:	73 0e                	jae    80103f55 <fetchstr+0x2e>
    if(*s == 0)
80103f47:	80 38 00             	cmpb   $0x0,(%eax)
80103f4a:	74 05                	je     80103f51 <fetchstr+0x2a>
  for(s = *pp; s < ep; s++){
80103f4c:	83 c0 01             	add    $0x1,%eax
80103f4f:	eb f2                	jmp    80103f43 <fetchstr+0x1c>
      return s - *pp;
80103f51:	29 d8                	sub    %ebx,%eax
80103f53:	eb 05                	jmp    80103f5a <fetchstr+0x33>
  }
  return -1;
80103f55:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80103f5a:	83 c4 04             	add    $0x4,%esp
80103f5d:	5b                   	pop    %ebx
80103f5e:	5d                   	pop    %ebp
80103f5f:	c3                   	ret    
    return -1;
80103f60:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f65:	eb f3                	jmp    80103f5a <fetchstr+0x33>

80103f67 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80103f67:	55                   	push   %ebp
80103f68:	89 e5                	mov    %esp,%ebp
80103f6a:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
80103f6d:	e8 5f f3 ff ff       	call   801032d1 <myproc>
80103f72:	8b 50 18             	mov    0x18(%eax),%edx
80103f75:	8b 45 08             	mov    0x8(%ebp),%eax
80103f78:	c1 e0 02             	shl    $0x2,%eax
80103f7b:	03 42 44             	add    0x44(%edx),%eax
80103f7e:	83 ec 08             	sub    $0x8,%esp
80103f81:	ff 75 0c             	pushl  0xc(%ebp)
80103f84:	83 c0 04             	add    $0x4,%eax
80103f87:	50                   	push   %eax
80103f88:	e8 5e ff ff ff       	call   80103eeb <fetchint>
}
80103f8d:	c9                   	leave  
80103f8e:	c3                   	ret    

80103f8f <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80103f8f:	55                   	push   %ebp
80103f90:	89 e5                	mov    %esp,%ebp
80103f92:	56                   	push   %esi
80103f93:	53                   	push   %ebx
80103f94:	83 ec 10             	sub    $0x10,%esp
80103f97:	8b 5d 10             	mov    0x10(%ebp),%ebx
  int i;
  struct proc *curproc = myproc();
80103f9a:	e8 32 f3 ff ff       	call   801032d1 <myproc>
80103f9f:	89 c6                	mov    %eax,%esi
 
  if(argint(n, &i) < 0)
80103fa1:	83 ec 08             	sub    $0x8,%esp
80103fa4:	8d 45 f4             	lea    -0xc(%ebp),%eax
80103fa7:	50                   	push   %eax
80103fa8:	ff 75 08             	pushl  0x8(%ebp)
80103fab:	e8 b7 ff ff ff       	call   80103f67 <argint>
80103fb0:	83 c4 10             	add    $0x10,%esp
80103fb3:	85 c0                	test   %eax,%eax
80103fb5:	78 24                	js     80103fdb <argptr+0x4c>
    return -1;
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
80103fb7:	85 db                	test   %ebx,%ebx
80103fb9:	78 27                	js     80103fe2 <argptr+0x53>
80103fbb:	8b 16                	mov    (%esi),%edx
80103fbd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103fc0:	39 c2                	cmp    %eax,%edx
80103fc2:	76 25                	jbe    80103fe9 <argptr+0x5a>
80103fc4:	01 c3                	add    %eax,%ebx
80103fc6:	39 da                	cmp    %ebx,%edx
80103fc8:	72 26                	jb     80103ff0 <argptr+0x61>
    return -1;
  *pp = (char*)i;
80103fca:	8b 55 0c             	mov    0xc(%ebp),%edx
80103fcd:	89 02                	mov    %eax,(%edx)
  return 0;
80103fcf:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103fd4:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103fd7:	5b                   	pop    %ebx
80103fd8:	5e                   	pop    %esi
80103fd9:	5d                   	pop    %ebp
80103fda:	c3                   	ret    
    return -1;
80103fdb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103fe0:	eb f2                	jmp    80103fd4 <argptr+0x45>
    return -1;
80103fe2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103fe7:	eb eb                	jmp    80103fd4 <argptr+0x45>
80103fe9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103fee:	eb e4                	jmp    80103fd4 <argptr+0x45>
80103ff0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103ff5:	eb dd                	jmp    80103fd4 <argptr+0x45>

80103ff7 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80103ff7:	55                   	push   %ebp
80103ff8:	89 e5                	mov    %esp,%ebp
80103ffa:	83 ec 20             	sub    $0x20,%esp
  int addr;
  if(argint(n, &addr) < 0)
80103ffd:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104000:	50                   	push   %eax
80104001:	ff 75 08             	pushl  0x8(%ebp)
80104004:	e8 5e ff ff ff       	call   80103f67 <argint>
80104009:	83 c4 10             	add    $0x10,%esp
8010400c:	85 c0                	test   %eax,%eax
8010400e:	78 13                	js     80104023 <argstr+0x2c>
    return -1;
  return fetchstr(addr, pp);
80104010:	83 ec 08             	sub    $0x8,%esp
80104013:	ff 75 0c             	pushl  0xc(%ebp)
80104016:	ff 75 f4             	pushl  -0xc(%ebp)
80104019:	e8 09 ff ff ff       	call   80103f27 <fetchstr>
8010401e:	83 c4 10             	add    $0x10,%esp
}
80104021:	c9                   	leave  
80104022:	c3                   	ret    
    return -1;
80104023:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104028:	eb f7                	jmp    80104021 <argstr+0x2a>

8010402a <syscall>:
[SYS_dump_physmem] sys_dump_physmem,
};

void
syscall(void)
{
8010402a:	55                   	push   %ebp
8010402b:	89 e5                	mov    %esp,%ebp
8010402d:	53                   	push   %ebx
8010402e:	83 ec 04             	sub    $0x4,%esp
  int num;
  struct proc *curproc = myproc();
80104031:	e8 9b f2 ff ff       	call   801032d1 <myproc>
80104036:	89 c3                	mov    %eax,%ebx

  num = curproc->tf->eax;
80104038:	8b 40 18             	mov    0x18(%eax),%eax
8010403b:	8b 40 1c             	mov    0x1c(%eax),%eax
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
8010403e:	8d 50 ff             	lea    -0x1(%eax),%edx
80104041:	83 fa 15             	cmp    $0x15,%edx
80104044:	77 18                	ja     8010405e <syscall+0x34>
80104046:	8b 14 85 60 6c 10 80 	mov    -0x7fef93a0(,%eax,4),%edx
8010404d:	85 d2                	test   %edx,%edx
8010404f:	74 0d                	je     8010405e <syscall+0x34>
    curproc->tf->eax = syscalls[num]();
80104051:	ff d2                	call   *%edx
80104053:	8b 53 18             	mov    0x18(%ebx),%edx
80104056:	89 42 1c             	mov    %eax,0x1c(%edx)
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
  }
}
80104059:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010405c:	c9                   	leave  
8010405d:	c3                   	ret    
            curproc->pid, curproc->name, num);
8010405e:	8d 53 6c             	lea    0x6c(%ebx),%edx
    cprintf("%d %s: unknown sys call %d\n",
80104061:	50                   	push   %eax
80104062:	52                   	push   %edx
80104063:	ff 73 10             	pushl  0x10(%ebx)
80104066:	68 31 6c 10 80       	push   $0x80106c31
8010406b:	e8 9b c5 ff ff       	call   8010060b <cprintf>
    curproc->tf->eax = -1;
80104070:	8b 43 18             	mov    0x18(%ebx),%eax
80104073:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
8010407a:	83 c4 10             	add    $0x10,%esp
}
8010407d:	eb da                	jmp    80104059 <syscall+0x2f>

8010407f <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
8010407f:	55                   	push   %ebp
80104080:	89 e5                	mov    %esp,%ebp
80104082:	56                   	push   %esi
80104083:	53                   	push   %ebx
80104084:	83 ec 18             	sub    $0x18,%esp
80104087:	89 d6                	mov    %edx,%esi
80104089:	89 cb                	mov    %ecx,%ebx
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
8010408b:	8d 55 f4             	lea    -0xc(%ebp),%edx
8010408e:	52                   	push   %edx
8010408f:	50                   	push   %eax
80104090:	e8 d2 fe ff ff       	call   80103f67 <argint>
80104095:	83 c4 10             	add    $0x10,%esp
80104098:	85 c0                	test   %eax,%eax
8010409a:	78 2e                	js     801040ca <argfd+0x4b>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
8010409c:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
801040a0:	77 2f                	ja     801040d1 <argfd+0x52>
801040a2:	e8 2a f2 ff ff       	call   801032d1 <myproc>
801040a7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801040aa:	8b 44 90 28          	mov    0x28(%eax,%edx,4),%eax
801040ae:	85 c0                	test   %eax,%eax
801040b0:	74 26                	je     801040d8 <argfd+0x59>
    return -1;
  if(pfd)
801040b2:	85 f6                	test   %esi,%esi
801040b4:	74 02                	je     801040b8 <argfd+0x39>
    *pfd = fd;
801040b6:	89 16                	mov    %edx,(%esi)
  if(pf)
801040b8:	85 db                	test   %ebx,%ebx
801040ba:	74 23                	je     801040df <argfd+0x60>
    *pf = f;
801040bc:	89 03                	mov    %eax,(%ebx)
  return 0;
801040be:	b8 00 00 00 00       	mov    $0x0,%eax
}
801040c3:	8d 65 f8             	lea    -0x8(%ebp),%esp
801040c6:	5b                   	pop    %ebx
801040c7:	5e                   	pop    %esi
801040c8:	5d                   	pop    %ebp
801040c9:	c3                   	ret    
    return -1;
801040ca:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040cf:	eb f2                	jmp    801040c3 <argfd+0x44>
    return -1;
801040d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040d6:	eb eb                	jmp    801040c3 <argfd+0x44>
801040d8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040dd:	eb e4                	jmp    801040c3 <argfd+0x44>
  return 0;
801040df:	b8 00 00 00 00       	mov    $0x0,%eax
801040e4:	eb dd                	jmp    801040c3 <argfd+0x44>

801040e6 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
801040e6:	55                   	push   %ebp
801040e7:	89 e5                	mov    %esp,%ebp
801040e9:	53                   	push   %ebx
801040ea:	83 ec 04             	sub    $0x4,%esp
801040ed:	89 c3                	mov    %eax,%ebx
  int fd;
  struct proc *curproc = myproc();
801040ef:	e8 dd f1 ff ff       	call   801032d1 <myproc>

  for(fd = 0; fd < NOFILE; fd++){
801040f4:	ba 00 00 00 00       	mov    $0x0,%edx
801040f9:	83 fa 0f             	cmp    $0xf,%edx
801040fc:	7f 18                	jg     80104116 <fdalloc+0x30>
    if(curproc->ofile[fd] == 0){
801040fe:	83 7c 90 28 00       	cmpl   $0x0,0x28(%eax,%edx,4)
80104103:	74 05                	je     8010410a <fdalloc+0x24>
  for(fd = 0; fd < NOFILE; fd++){
80104105:	83 c2 01             	add    $0x1,%edx
80104108:	eb ef                	jmp    801040f9 <fdalloc+0x13>
      curproc->ofile[fd] = f;
8010410a:	89 5c 90 28          	mov    %ebx,0x28(%eax,%edx,4)
      return fd;
    }
  }
  return -1;
}
8010410e:	89 d0                	mov    %edx,%eax
80104110:	83 c4 04             	add    $0x4,%esp
80104113:	5b                   	pop    %ebx
80104114:	5d                   	pop    %ebp
80104115:	c3                   	ret    
  return -1;
80104116:	ba ff ff ff ff       	mov    $0xffffffff,%edx
8010411b:	eb f1                	jmp    8010410e <fdalloc+0x28>

8010411d <isdirempty>:
}

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
8010411d:	55                   	push   %ebp
8010411e:	89 e5                	mov    %esp,%ebp
80104120:	56                   	push   %esi
80104121:	53                   	push   %ebx
80104122:	83 ec 10             	sub    $0x10,%esp
80104125:	89 c3                	mov    %eax,%ebx
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80104127:	b8 20 00 00 00       	mov    $0x20,%eax
8010412c:	89 c6                	mov    %eax,%esi
8010412e:	39 43 58             	cmp    %eax,0x58(%ebx)
80104131:	76 2e                	jbe    80104161 <isdirempty+0x44>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80104133:	6a 10                	push   $0x10
80104135:	50                   	push   %eax
80104136:	8d 45 e8             	lea    -0x18(%ebp),%eax
80104139:	50                   	push   %eax
8010413a:	53                   	push   %ebx
8010413b:	e8 33 d6 ff ff       	call   80101773 <readi>
80104140:	83 c4 10             	add    $0x10,%esp
80104143:	83 f8 10             	cmp    $0x10,%eax
80104146:	75 0c                	jne    80104154 <isdirempty+0x37>
      panic("isdirempty: readi");
    if(de.inum != 0)
80104148:	66 83 7d e8 00       	cmpw   $0x0,-0x18(%ebp)
8010414d:	75 1e                	jne    8010416d <isdirempty+0x50>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
8010414f:	8d 46 10             	lea    0x10(%esi),%eax
80104152:	eb d8                	jmp    8010412c <isdirempty+0xf>
      panic("isdirempty: readi");
80104154:	83 ec 0c             	sub    $0xc,%esp
80104157:	68 bc 6c 10 80       	push   $0x80106cbc
8010415c:	e8 e7 c1 ff ff       	call   80100348 <panic>
      return 0;
  }
  return 1;
80104161:	b8 01 00 00 00       	mov    $0x1,%eax
}
80104166:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104169:	5b                   	pop    %ebx
8010416a:	5e                   	pop    %esi
8010416b:	5d                   	pop    %ebp
8010416c:	c3                   	ret    
      return 0;
8010416d:	b8 00 00 00 00       	mov    $0x0,%eax
80104172:	eb f2                	jmp    80104166 <isdirempty+0x49>

80104174 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
80104174:	55                   	push   %ebp
80104175:	89 e5                	mov    %esp,%ebp
80104177:	57                   	push   %edi
80104178:	56                   	push   %esi
80104179:	53                   	push   %ebx
8010417a:	83 ec 44             	sub    $0x44,%esp
8010417d:	89 55 c4             	mov    %edx,-0x3c(%ebp)
80104180:	89 4d c0             	mov    %ecx,-0x40(%ebp)
80104183:	8b 7d 08             	mov    0x8(%ebp),%edi
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80104186:	8d 55 d6             	lea    -0x2a(%ebp),%edx
80104189:	52                   	push   %edx
8010418a:	50                   	push   %eax
8010418b:	e8 69 da ff ff       	call   80101bf9 <nameiparent>
80104190:	89 c6                	mov    %eax,%esi
80104192:	83 c4 10             	add    $0x10,%esp
80104195:	85 c0                	test   %eax,%eax
80104197:	0f 84 3a 01 00 00    	je     801042d7 <create+0x163>
    return 0;
  ilock(dp);
8010419d:	83 ec 0c             	sub    $0xc,%esp
801041a0:	50                   	push   %eax
801041a1:	e8 db d3 ff ff       	call   80101581 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
801041a6:	83 c4 0c             	add    $0xc,%esp
801041a9:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801041ac:	50                   	push   %eax
801041ad:	8d 45 d6             	lea    -0x2a(%ebp),%eax
801041b0:	50                   	push   %eax
801041b1:	56                   	push   %esi
801041b2:	e8 f9 d7 ff ff       	call   801019b0 <dirlookup>
801041b7:	89 c3                	mov    %eax,%ebx
801041b9:	83 c4 10             	add    $0x10,%esp
801041bc:	85 c0                	test   %eax,%eax
801041be:	74 3f                	je     801041ff <create+0x8b>
    iunlockput(dp);
801041c0:	83 ec 0c             	sub    $0xc,%esp
801041c3:	56                   	push   %esi
801041c4:	e8 5f d5 ff ff       	call   80101728 <iunlockput>
    ilock(ip);
801041c9:	89 1c 24             	mov    %ebx,(%esp)
801041cc:	e8 b0 d3 ff ff       	call   80101581 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
801041d1:	83 c4 10             	add    $0x10,%esp
801041d4:	66 83 7d c4 02       	cmpw   $0x2,-0x3c(%ebp)
801041d9:	75 11                	jne    801041ec <create+0x78>
801041db:	66 83 7b 50 02       	cmpw   $0x2,0x50(%ebx)
801041e0:	75 0a                	jne    801041ec <create+0x78>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
801041e2:	89 d8                	mov    %ebx,%eax
801041e4:	8d 65 f4             	lea    -0xc(%ebp),%esp
801041e7:	5b                   	pop    %ebx
801041e8:	5e                   	pop    %esi
801041e9:	5f                   	pop    %edi
801041ea:	5d                   	pop    %ebp
801041eb:	c3                   	ret    
    iunlockput(ip);
801041ec:	83 ec 0c             	sub    $0xc,%esp
801041ef:	53                   	push   %ebx
801041f0:	e8 33 d5 ff ff       	call   80101728 <iunlockput>
    return 0;
801041f5:	83 c4 10             	add    $0x10,%esp
801041f8:	bb 00 00 00 00       	mov    $0x0,%ebx
801041fd:	eb e3                	jmp    801041e2 <create+0x6e>
  if((ip = ialloc(dp->dev, type)) == 0)
801041ff:	0f bf 45 c4          	movswl -0x3c(%ebp),%eax
80104203:	83 ec 08             	sub    $0x8,%esp
80104206:	50                   	push   %eax
80104207:	ff 36                	pushl  (%esi)
80104209:	e8 70 d1 ff ff       	call   8010137e <ialloc>
8010420e:	89 c3                	mov    %eax,%ebx
80104210:	83 c4 10             	add    $0x10,%esp
80104213:	85 c0                	test   %eax,%eax
80104215:	74 55                	je     8010426c <create+0xf8>
  ilock(ip);
80104217:	83 ec 0c             	sub    $0xc,%esp
8010421a:	50                   	push   %eax
8010421b:	e8 61 d3 ff ff       	call   80101581 <ilock>
  ip->major = major;
80104220:	0f b7 45 c0          	movzwl -0x40(%ebp),%eax
80104224:	66 89 43 52          	mov    %ax,0x52(%ebx)
  ip->minor = minor;
80104228:	66 89 7b 54          	mov    %di,0x54(%ebx)
  ip->nlink = 1;
8010422c:	66 c7 43 56 01 00    	movw   $0x1,0x56(%ebx)
  iupdate(ip);
80104232:	89 1c 24             	mov    %ebx,(%esp)
80104235:	e8 e6 d1 ff ff       	call   80101420 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
8010423a:	83 c4 10             	add    $0x10,%esp
8010423d:	66 83 7d c4 01       	cmpw   $0x1,-0x3c(%ebp)
80104242:	74 35                	je     80104279 <create+0x105>
  if(dirlink(dp, name, ip->inum) < 0)
80104244:	83 ec 04             	sub    $0x4,%esp
80104247:	ff 73 04             	pushl  0x4(%ebx)
8010424a:	8d 45 d6             	lea    -0x2a(%ebp),%eax
8010424d:	50                   	push   %eax
8010424e:	56                   	push   %esi
8010424f:	e8 dc d8 ff ff       	call   80101b30 <dirlink>
80104254:	83 c4 10             	add    $0x10,%esp
80104257:	85 c0                	test   %eax,%eax
80104259:	78 6f                	js     801042ca <create+0x156>
  iunlockput(dp);
8010425b:	83 ec 0c             	sub    $0xc,%esp
8010425e:	56                   	push   %esi
8010425f:	e8 c4 d4 ff ff       	call   80101728 <iunlockput>
  return ip;
80104264:	83 c4 10             	add    $0x10,%esp
80104267:	e9 76 ff ff ff       	jmp    801041e2 <create+0x6e>
    panic("create: ialloc");
8010426c:	83 ec 0c             	sub    $0xc,%esp
8010426f:	68 ce 6c 10 80       	push   $0x80106cce
80104274:	e8 cf c0 ff ff       	call   80100348 <panic>
    dp->nlink++;  // for ".."
80104279:	0f b7 46 56          	movzwl 0x56(%esi),%eax
8010427d:	83 c0 01             	add    $0x1,%eax
80104280:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
80104284:	83 ec 0c             	sub    $0xc,%esp
80104287:	56                   	push   %esi
80104288:	e8 93 d1 ff ff       	call   80101420 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
8010428d:	83 c4 0c             	add    $0xc,%esp
80104290:	ff 73 04             	pushl  0x4(%ebx)
80104293:	68 de 6c 10 80       	push   $0x80106cde
80104298:	53                   	push   %ebx
80104299:	e8 92 d8 ff ff       	call   80101b30 <dirlink>
8010429e:	83 c4 10             	add    $0x10,%esp
801042a1:	85 c0                	test   %eax,%eax
801042a3:	78 18                	js     801042bd <create+0x149>
801042a5:	83 ec 04             	sub    $0x4,%esp
801042a8:	ff 76 04             	pushl  0x4(%esi)
801042ab:	68 dd 6c 10 80       	push   $0x80106cdd
801042b0:	53                   	push   %ebx
801042b1:	e8 7a d8 ff ff       	call   80101b30 <dirlink>
801042b6:	83 c4 10             	add    $0x10,%esp
801042b9:	85 c0                	test   %eax,%eax
801042bb:	79 87                	jns    80104244 <create+0xd0>
      panic("create dots");
801042bd:	83 ec 0c             	sub    $0xc,%esp
801042c0:	68 e0 6c 10 80       	push   $0x80106ce0
801042c5:	e8 7e c0 ff ff       	call   80100348 <panic>
    panic("create: dirlink");
801042ca:	83 ec 0c             	sub    $0xc,%esp
801042cd:	68 ec 6c 10 80       	push   $0x80106cec
801042d2:	e8 71 c0 ff ff       	call   80100348 <panic>
    return 0;
801042d7:	89 c3                	mov    %eax,%ebx
801042d9:	e9 04 ff ff ff       	jmp    801041e2 <create+0x6e>

801042de <sys_dup>:
{
801042de:	55                   	push   %ebp
801042df:	89 e5                	mov    %esp,%ebp
801042e1:	53                   	push   %ebx
801042e2:	83 ec 14             	sub    $0x14,%esp
  if(argfd(0, 0, &f) < 0)
801042e5:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801042e8:	ba 00 00 00 00       	mov    $0x0,%edx
801042ed:	b8 00 00 00 00       	mov    $0x0,%eax
801042f2:	e8 88 fd ff ff       	call   8010407f <argfd>
801042f7:	85 c0                	test   %eax,%eax
801042f9:	78 23                	js     8010431e <sys_dup+0x40>
  if((fd=fdalloc(f)) < 0)
801042fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042fe:	e8 e3 fd ff ff       	call   801040e6 <fdalloc>
80104303:	89 c3                	mov    %eax,%ebx
80104305:	85 c0                	test   %eax,%eax
80104307:	78 1c                	js     80104325 <sys_dup+0x47>
  filedup(f);
80104309:	83 ec 0c             	sub    $0xc,%esp
8010430c:	ff 75 f4             	pushl  -0xc(%ebp)
8010430f:	e8 7a c9 ff ff       	call   80100c8e <filedup>
  return fd;
80104314:	83 c4 10             	add    $0x10,%esp
}
80104317:	89 d8                	mov    %ebx,%eax
80104319:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010431c:	c9                   	leave  
8010431d:	c3                   	ret    
    return -1;
8010431e:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104323:	eb f2                	jmp    80104317 <sys_dup+0x39>
    return -1;
80104325:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
8010432a:	eb eb                	jmp    80104317 <sys_dup+0x39>

8010432c <sys_read>:
{
8010432c:	55                   	push   %ebp
8010432d:	89 e5                	mov    %esp,%ebp
8010432f:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80104332:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104335:	ba 00 00 00 00       	mov    $0x0,%edx
8010433a:	b8 00 00 00 00       	mov    $0x0,%eax
8010433f:	e8 3b fd ff ff       	call   8010407f <argfd>
80104344:	85 c0                	test   %eax,%eax
80104346:	78 43                	js     8010438b <sys_read+0x5f>
80104348:	83 ec 08             	sub    $0x8,%esp
8010434b:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010434e:	50                   	push   %eax
8010434f:	6a 02                	push   $0x2
80104351:	e8 11 fc ff ff       	call   80103f67 <argint>
80104356:	83 c4 10             	add    $0x10,%esp
80104359:	85 c0                	test   %eax,%eax
8010435b:	78 35                	js     80104392 <sys_read+0x66>
8010435d:	83 ec 04             	sub    $0x4,%esp
80104360:	ff 75 f0             	pushl  -0x10(%ebp)
80104363:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104366:	50                   	push   %eax
80104367:	6a 01                	push   $0x1
80104369:	e8 21 fc ff ff       	call   80103f8f <argptr>
8010436e:	83 c4 10             	add    $0x10,%esp
80104371:	85 c0                	test   %eax,%eax
80104373:	78 24                	js     80104399 <sys_read+0x6d>
  return fileread(f, p, n);
80104375:	83 ec 04             	sub    $0x4,%esp
80104378:	ff 75 f0             	pushl  -0x10(%ebp)
8010437b:	ff 75 ec             	pushl  -0x14(%ebp)
8010437e:	ff 75 f4             	pushl  -0xc(%ebp)
80104381:	e8 51 ca ff ff       	call   80100dd7 <fileread>
80104386:	83 c4 10             	add    $0x10,%esp
}
80104389:	c9                   	leave  
8010438a:	c3                   	ret    
    return -1;
8010438b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104390:	eb f7                	jmp    80104389 <sys_read+0x5d>
80104392:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104397:	eb f0                	jmp    80104389 <sys_read+0x5d>
80104399:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010439e:	eb e9                	jmp    80104389 <sys_read+0x5d>

801043a0 <sys_write>:
{
801043a0:	55                   	push   %ebp
801043a1:	89 e5                	mov    %esp,%ebp
801043a3:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801043a6:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801043a9:	ba 00 00 00 00       	mov    $0x0,%edx
801043ae:	b8 00 00 00 00       	mov    $0x0,%eax
801043b3:	e8 c7 fc ff ff       	call   8010407f <argfd>
801043b8:	85 c0                	test   %eax,%eax
801043ba:	78 43                	js     801043ff <sys_write+0x5f>
801043bc:	83 ec 08             	sub    $0x8,%esp
801043bf:	8d 45 f0             	lea    -0x10(%ebp),%eax
801043c2:	50                   	push   %eax
801043c3:	6a 02                	push   $0x2
801043c5:	e8 9d fb ff ff       	call   80103f67 <argint>
801043ca:	83 c4 10             	add    $0x10,%esp
801043cd:	85 c0                	test   %eax,%eax
801043cf:	78 35                	js     80104406 <sys_write+0x66>
801043d1:	83 ec 04             	sub    $0x4,%esp
801043d4:	ff 75 f0             	pushl  -0x10(%ebp)
801043d7:	8d 45 ec             	lea    -0x14(%ebp),%eax
801043da:	50                   	push   %eax
801043db:	6a 01                	push   $0x1
801043dd:	e8 ad fb ff ff       	call   80103f8f <argptr>
801043e2:	83 c4 10             	add    $0x10,%esp
801043e5:	85 c0                	test   %eax,%eax
801043e7:	78 24                	js     8010440d <sys_write+0x6d>
  return filewrite(f, p, n);
801043e9:	83 ec 04             	sub    $0x4,%esp
801043ec:	ff 75 f0             	pushl  -0x10(%ebp)
801043ef:	ff 75 ec             	pushl  -0x14(%ebp)
801043f2:	ff 75 f4             	pushl  -0xc(%ebp)
801043f5:	e8 62 ca ff ff       	call   80100e5c <filewrite>
801043fa:	83 c4 10             	add    $0x10,%esp
}
801043fd:	c9                   	leave  
801043fe:	c3                   	ret    
    return -1;
801043ff:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104404:	eb f7                	jmp    801043fd <sys_write+0x5d>
80104406:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010440b:	eb f0                	jmp    801043fd <sys_write+0x5d>
8010440d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104412:	eb e9                	jmp    801043fd <sys_write+0x5d>

80104414 <sys_close>:
{
80104414:	55                   	push   %ebp
80104415:	89 e5                	mov    %esp,%ebp
80104417:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, &fd, &f) < 0)
8010441a:	8d 4d f0             	lea    -0x10(%ebp),%ecx
8010441d:	8d 55 f4             	lea    -0xc(%ebp),%edx
80104420:	b8 00 00 00 00       	mov    $0x0,%eax
80104425:	e8 55 fc ff ff       	call   8010407f <argfd>
8010442a:	85 c0                	test   %eax,%eax
8010442c:	78 25                	js     80104453 <sys_close+0x3f>
  myproc()->ofile[fd] = 0;
8010442e:	e8 9e ee ff ff       	call   801032d1 <myproc>
80104433:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104436:	c7 44 90 28 00 00 00 	movl   $0x0,0x28(%eax,%edx,4)
8010443d:	00 
  fileclose(f);
8010443e:	83 ec 0c             	sub    $0xc,%esp
80104441:	ff 75 f0             	pushl  -0x10(%ebp)
80104444:	e8 8a c8 ff ff       	call   80100cd3 <fileclose>
  return 0;
80104449:	83 c4 10             	add    $0x10,%esp
8010444c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104451:	c9                   	leave  
80104452:	c3                   	ret    
    return -1;
80104453:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104458:	eb f7                	jmp    80104451 <sys_close+0x3d>

8010445a <sys_fstat>:
{
8010445a:	55                   	push   %ebp
8010445b:	89 e5                	mov    %esp,%ebp
8010445d:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
80104460:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104463:	ba 00 00 00 00       	mov    $0x0,%edx
80104468:	b8 00 00 00 00       	mov    $0x0,%eax
8010446d:	e8 0d fc ff ff       	call   8010407f <argfd>
80104472:	85 c0                	test   %eax,%eax
80104474:	78 2a                	js     801044a0 <sys_fstat+0x46>
80104476:	83 ec 04             	sub    $0x4,%esp
80104479:	6a 14                	push   $0x14
8010447b:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010447e:	50                   	push   %eax
8010447f:	6a 01                	push   $0x1
80104481:	e8 09 fb ff ff       	call   80103f8f <argptr>
80104486:	83 c4 10             	add    $0x10,%esp
80104489:	85 c0                	test   %eax,%eax
8010448b:	78 1a                	js     801044a7 <sys_fstat+0x4d>
  return filestat(f, st);
8010448d:	83 ec 08             	sub    $0x8,%esp
80104490:	ff 75 f0             	pushl  -0x10(%ebp)
80104493:	ff 75 f4             	pushl  -0xc(%ebp)
80104496:	e8 f5 c8 ff ff       	call   80100d90 <filestat>
8010449b:	83 c4 10             	add    $0x10,%esp
}
8010449e:	c9                   	leave  
8010449f:	c3                   	ret    
    return -1;
801044a0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044a5:	eb f7                	jmp    8010449e <sys_fstat+0x44>
801044a7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044ac:	eb f0                	jmp    8010449e <sys_fstat+0x44>

801044ae <sys_link>:
{
801044ae:	55                   	push   %ebp
801044af:	89 e5                	mov    %esp,%ebp
801044b1:	56                   	push   %esi
801044b2:	53                   	push   %ebx
801044b3:	83 ec 28             	sub    $0x28,%esp
  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
801044b6:	8d 45 e0             	lea    -0x20(%ebp),%eax
801044b9:	50                   	push   %eax
801044ba:	6a 00                	push   $0x0
801044bc:	e8 36 fb ff ff       	call   80103ff7 <argstr>
801044c1:	83 c4 10             	add    $0x10,%esp
801044c4:	85 c0                	test   %eax,%eax
801044c6:	0f 88 32 01 00 00    	js     801045fe <sys_link+0x150>
801044cc:	83 ec 08             	sub    $0x8,%esp
801044cf:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801044d2:	50                   	push   %eax
801044d3:	6a 01                	push   $0x1
801044d5:	e8 1d fb ff ff       	call   80103ff7 <argstr>
801044da:	83 c4 10             	add    $0x10,%esp
801044dd:	85 c0                	test   %eax,%eax
801044df:	0f 88 20 01 00 00    	js     80104605 <sys_link+0x157>
  begin_op();
801044e5:	e8 9f e3 ff ff       	call   80102889 <begin_op>
  if((ip = namei(old)) == 0){
801044ea:	83 ec 0c             	sub    $0xc,%esp
801044ed:	ff 75 e0             	pushl  -0x20(%ebp)
801044f0:	e8 ec d6 ff ff       	call   80101be1 <namei>
801044f5:	89 c3                	mov    %eax,%ebx
801044f7:	83 c4 10             	add    $0x10,%esp
801044fa:	85 c0                	test   %eax,%eax
801044fc:	0f 84 99 00 00 00    	je     8010459b <sys_link+0xed>
  ilock(ip);
80104502:	83 ec 0c             	sub    $0xc,%esp
80104505:	50                   	push   %eax
80104506:	e8 76 d0 ff ff       	call   80101581 <ilock>
  if(ip->type == T_DIR){
8010450b:	83 c4 10             	add    $0x10,%esp
8010450e:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104513:	0f 84 8e 00 00 00    	je     801045a7 <sys_link+0xf9>
  ip->nlink++;
80104519:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
8010451d:	83 c0 01             	add    $0x1,%eax
80104520:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104524:	83 ec 0c             	sub    $0xc,%esp
80104527:	53                   	push   %ebx
80104528:	e8 f3 ce ff ff       	call   80101420 <iupdate>
  iunlock(ip);
8010452d:	89 1c 24             	mov    %ebx,(%esp)
80104530:	e8 0e d1 ff ff       	call   80101643 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
80104535:	83 c4 08             	add    $0x8,%esp
80104538:	8d 45 ea             	lea    -0x16(%ebp),%eax
8010453b:	50                   	push   %eax
8010453c:	ff 75 e4             	pushl  -0x1c(%ebp)
8010453f:	e8 b5 d6 ff ff       	call   80101bf9 <nameiparent>
80104544:	89 c6                	mov    %eax,%esi
80104546:	83 c4 10             	add    $0x10,%esp
80104549:	85 c0                	test   %eax,%eax
8010454b:	74 7e                	je     801045cb <sys_link+0x11d>
  ilock(dp);
8010454d:	83 ec 0c             	sub    $0xc,%esp
80104550:	50                   	push   %eax
80104551:	e8 2b d0 ff ff       	call   80101581 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80104556:	83 c4 10             	add    $0x10,%esp
80104559:	8b 03                	mov    (%ebx),%eax
8010455b:	39 06                	cmp    %eax,(%esi)
8010455d:	75 60                	jne    801045bf <sys_link+0x111>
8010455f:	83 ec 04             	sub    $0x4,%esp
80104562:	ff 73 04             	pushl  0x4(%ebx)
80104565:	8d 45 ea             	lea    -0x16(%ebp),%eax
80104568:	50                   	push   %eax
80104569:	56                   	push   %esi
8010456a:	e8 c1 d5 ff ff       	call   80101b30 <dirlink>
8010456f:	83 c4 10             	add    $0x10,%esp
80104572:	85 c0                	test   %eax,%eax
80104574:	78 49                	js     801045bf <sys_link+0x111>
  iunlockput(dp);
80104576:	83 ec 0c             	sub    $0xc,%esp
80104579:	56                   	push   %esi
8010457a:	e8 a9 d1 ff ff       	call   80101728 <iunlockput>
  iput(ip);
8010457f:	89 1c 24             	mov    %ebx,(%esp)
80104582:	e8 01 d1 ff ff       	call   80101688 <iput>
  end_op();
80104587:	e8 77 e3 ff ff       	call   80102903 <end_op>
  return 0;
8010458c:	83 c4 10             	add    $0x10,%esp
8010458f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104594:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104597:	5b                   	pop    %ebx
80104598:	5e                   	pop    %esi
80104599:	5d                   	pop    %ebp
8010459a:	c3                   	ret    
    end_op();
8010459b:	e8 63 e3 ff ff       	call   80102903 <end_op>
    return -1;
801045a0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045a5:	eb ed                	jmp    80104594 <sys_link+0xe6>
    iunlockput(ip);
801045a7:	83 ec 0c             	sub    $0xc,%esp
801045aa:	53                   	push   %ebx
801045ab:	e8 78 d1 ff ff       	call   80101728 <iunlockput>
    end_op();
801045b0:	e8 4e e3 ff ff       	call   80102903 <end_op>
    return -1;
801045b5:	83 c4 10             	add    $0x10,%esp
801045b8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045bd:	eb d5                	jmp    80104594 <sys_link+0xe6>
    iunlockput(dp);
801045bf:	83 ec 0c             	sub    $0xc,%esp
801045c2:	56                   	push   %esi
801045c3:	e8 60 d1 ff ff       	call   80101728 <iunlockput>
    goto bad;
801045c8:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
801045cb:	83 ec 0c             	sub    $0xc,%esp
801045ce:	53                   	push   %ebx
801045cf:	e8 ad cf ff ff       	call   80101581 <ilock>
  ip->nlink--;
801045d4:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
801045d8:	83 e8 01             	sub    $0x1,%eax
801045db:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
801045df:	89 1c 24             	mov    %ebx,(%esp)
801045e2:	e8 39 ce ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
801045e7:	89 1c 24             	mov    %ebx,(%esp)
801045ea:	e8 39 d1 ff ff       	call   80101728 <iunlockput>
  end_op();
801045ef:	e8 0f e3 ff ff       	call   80102903 <end_op>
  return -1;
801045f4:	83 c4 10             	add    $0x10,%esp
801045f7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045fc:	eb 96                	jmp    80104594 <sys_link+0xe6>
    return -1;
801045fe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104603:	eb 8f                	jmp    80104594 <sys_link+0xe6>
80104605:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010460a:	eb 88                	jmp    80104594 <sys_link+0xe6>

8010460c <sys_unlink>:
{
8010460c:	55                   	push   %ebp
8010460d:	89 e5                	mov    %esp,%ebp
8010460f:	57                   	push   %edi
80104610:	56                   	push   %esi
80104611:	53                   	push   %ebx
80104612:	83 ec 44             	sub    $0x44,%esp
  if(argstr(0, &path) < 0)
80104615:	8d 45 c4             	lea    -0x3c(%ebp),%eax
80104618:	50                   	push   %eax
80104619:	6a 00                	push   $0x0
8010461b:	e8 d7 f9 ff ff       	call   80103ff7 <argstr>
80104620:	83 c4 10             	add    $0x10,%esp
80104623:	85 c0                	test   %eax,%eax
80104625:	0f 88 83 01 00 00    	js     801047ae <sys_unlink+0x1a2>
  begin_op();
8010462b:	e8 59 e2 ff ff       	call   80102889 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
80104630:	83 ec 08             	sub    $0x8,%esp
80104633:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104636:	50                   	push   %eax
80104637:	ff 75 c4             	pushl  -0x3c(%ebp)
8010463a:	e8 ba d5 ff ff       	call   80101bf9 <nameiparent>
8010463f:	89 c6                	mov    %eax,%esi
80104641:	83 c4 10             	add    $0x10,%esp
80104644:	85 c0                	test   %eax,%eax
80104646:	0f 84 ed 00 00 00    	je     80104739 <sys_unlink+0x12d>
  ilock(dp);
8010464c:	83 ec 0c             	sub    $0xc,%esp
8010464f:	50                   	push   %eax
80104650:	e8 2c cf ff ff       	call   80101581 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80104655:	83 c4 08             	add    $0x8,%esp
80104658:	68 de 6c 10 80       	push   $0x80106cde
8010465d:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104660:	50                   	push   %eax
80104661:	e8 35 d3 ff ff       	call   8010199b <namecmp>
80104666:	83 c4 10             	add    $0x10,%esp
80104669:	85 c0                	test   %eax,%eax
8010466b:	0f 84 fc 00 00 00    	je     8010476d <sys_unlink+0x161>
80104671:	83 ec 08             	sub    $0x8,%esp
80104674:	68 dd 6c 10 80       	push   $0x80106cdd
80104679:	8d 45 ca             	lea    -0x36(%ebp),%eax
8010467c:	50                   	push   %eax
8010467d:	e8 19 d3 ff ff       	call   8010199b <namecmp>
80104682:	83 c4 10             	add    $0x10,%esp
80104685:	85 c0                	test   %eax,%eax
80104687:	0f 84 e0 00 00 00    	je     8010476d <sys_unlink+0x161>
  if((ip = dirlookup(dp, name, &off)) == 0)
8010468d:	83 ec 04             	sub    $0x4,%esp
80104690:	8d 45 c0             	lea    -0x40(%ebp),%eax
80104693:	50                   	push   %eax
80104694:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104697:	50                   	push   %eax
80104698:	56                   	push   %esi
80104699:	e8 12 d3 ff ff       	call   801019b0 <dirlookup>
8010469e:	89 c3                	mov    %eax,%ebx
801046a0:	83 c4 10             	add    $0x10,%esp
801046a3:	85 c0                	test   %eax,%eax
801046a5:	0f 84 c2 00 00 00    	je     8010476d <sys_unlink+0x161>
  ilock(ip);
801046ab:	83 ec 0c             	sub    $0xc,%esp
801046ae:	50                   	push   %eax
801046af:	e8 cd ce ff ff       	call   80101581 <ilock>
  if(ip->nlink < 1)
801046b4:	83 c4 10             	add    $0x10,%esp
801046b7:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801046bc:	0f 8e 83 00 00 00    	jle    80104745 <sys_unlink+0x139>
  if(ip->type == T_DIR && !isdirempty(ip)){
801046c2:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
801046c7:	0f 84 85 00 00 00    	je     80104752 <sys_unlink+0x146>
  memset(&de, 0, sizeof(de));
801046cd:	83 ec 04             	sub    $0x4,%esp
801046d0:	6a 10                	push   $0x10
801046d2:	6a 00                	push   $0x0
801046d4:	8d 7d d8             	lea    -0x28(%ebp),%edi
801046d7:	57                   	push   %edi
801046d8:	e8 3f f6 ff ff       	call   80103d1c <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801046dd:	6a 10                	push   $0x10
801046df:	ff 75 c0             	pushl  -0x40(%ebp)
801046e2:	57                   	push   %edi
801046e3:	56                   	push   %esi
801046e4:	e8 87 d1 ff ff       	call   80101870 <writei>
801046e9:	83 c4 20             	add    $0x20,%esp
801046ec:	83 f8 10             	cmp    $0x10,%eax
801046ef:	0f 85 90 00 00 00    	jne    80104785 <sys_unlink+0x179>
  if(ip->type == T_DIR){
801046f5:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
801046fa:	0f 84 92 00 00 00    	je     80104792 <sys_unlink+0x186>
  iunlockput(dp);
80104700:	83 ec 0c             	sub    $0xc,%esp
80104703:	56                   	push   %esi
80104704:	e8 1f d0 ff ff       	call   80101728 <iunlockput>
  ip->nlink--;
80104709:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
8010470d:	83 e8 01             	sub    $0x1,%eax
80104710:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104714:	89 1c 24             	mov    %ebx,(%esp)
80104717:	e8 04 cd ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
8010471c:	89 1c 24             	mov    %ebx,(%esp)
8010471f:	e8 04 d0 ff ff       	call   80101728 <iunlockput>
  end_op();
80104724:	e8 da e1 ff ff       	call   80102903 <end_op>
  return 0;
80104729:	83 c4 10             	add    $0x10,%esp
8010472c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104731:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104734:	5b                   	pop    %ebx
80104735:	5e                   	pop    %esi
80104736:	5f                   	pop    %edi
80104737:	5d                   	pop    %ebp
80104738:	c3                   	ret    
    end_op();
80104739:	e8 c5 e1 ff ff       	call   80102903 <end_op>
    return -1;
8010473e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104743:	eb ec                	jmp    80104731 <sys_unlink+0x125>
    panic("unlink: nlink < 1");
80104745:	83 ec 0c             	sub    $0xc,%esp
80104748:	68 fc 6c 10 80       	push   $0x80106cfc
8010474d:	e8 f6 bb ff ff       	call   80100348 <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80104752:	89 d8                	mov    %ebx,%eax
80104754:	e8 c4 f9 ff ff       	call   8010411d <isdirempty>
80104759:	85 c0                	test   %eax,%eax
8010475b:	0f 85 6c ff ff ff    	jne    801046cd <sys_unlink+0xc1>
    iunlockput(ip);
80104761:	83 ec 0c             	sub    $0xc,%esp
80104764:	53                   	push   %ebx
80104765:	e8 be cf ff ff       	call   80101728 <iunlockput>
    goto bad;
8010476a:	83 c4 10             	add    $0x10,%esp
  iunlockput(dp);
8010476d:	83 ec 0c             	sub    $0xc,%esp
80104770:	56                   	push   %esi
80104771:	e8 b2 cf ff ff       	call   80101728 <iunlockput>
  end_op();
80104776:	e8 88 e1 ff ff       	call   80102903 <end_op>
  return -1;
8010477b:	83 c4 10             	add    $0x10,%esp
8010477e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104783:	eb ac                	jmp    80104731 <sys_unlink+0x125>
    panic("unlink: writei");
80104785:	83 ec 0c             	sub    $0xc,%esp
80104788:	68 0e 6d 10 80       	push   $0x80106d0e
8010478d:	e8 b6 bb ff ff       	call   80100348 <panic>
    dp->nlink--;
80104792:	0f b7 46 56          	movzwl 0x56(%esi),%eax
80104796:	83 e8 01             	sub    $0x1,%eax
80104799:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
8010479d:	83 ec 0c             	sub    $0xc,%esp
801047a0:	56                   	push   %esi
801047a1:	e8 7a cc ff ff       	call   80101420 <iupdate>
801047a6:	83 c4 10             	add    $0x10,%esp
801047a9:	e9 52 ff ff ff       	jmp    80104700 <sys_unlink+0xf4>
    return -1;
801047ae:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047b3:	e9 79 ff ff ff       	jmp    80104731 <sys_unlink+0x125>

801047b8 <sys_open>:

int
sys_open(void)
{
801047b8:	55                   	push   %ebp
801047b9:	89 e5                	mov    %esp,%ebp
801047bb:	57                   	push   %edi
801047bc:	56                   	push   %esi
801047bd:	53                   	push   %ebx
801047be:	83 ec 24             	sub    $0x24,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
801047c1:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801047c4:	50                   	push   %eax
801047c5:	6a 00                	push   $0x0
801047c7:	e8 2b f8 ff ff       	call   80103ff7 <argstr>
801047cc:	83 c4 10             	add    $0x10,%esp
801047cf:	85 c0                	test   %eax,%eax
801047d1:	0f 88 30 01 00 00    	js     80104907 <sys_open+0x14f>
801047d7:	83 ec 08             	sub    $0x8,%esp
801047da:	8d 45 e0             	lea    -0x20(%ebp),%eax
801047dd:	50                   	push   %eax
801047de:	6a 01                	push   $0x1
801047e0:	e8 82 f7 ff ff       	call   80103f67 <argint>
801047e5:	83 c4 10             	add    $0x10,%esp
801047e8:	85 c0                	test   %eax,%eax
801047ea:	0f 88 21 01 00 00    	js     80104911 <sys_open+0x159>
    return -1;

  begin_op();
801047f0:	e8 94 e0 ff ff       	call   80102889 <begin_op>

  if(omode & O_CREATE){
801047f5:	f6 45 e1 02          	testb  $0x2,-0x1f(%ebp)
801047f9:	0f 84 84 00 00 00    	je     80104883 <sys_open+0xcb>
    ip = create(path, T_FILE, 0, 0);
801047ff:	83 ec 0c             	sub    $0xc,%esp
80104802:	6a 00                	push   $0x0
80104804:	b9 00 00 00 00       	mov    $0x0,%ecx
80104809:	ba 02 00 00 00       	mov    $0x2,%edx
8010480e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104811:	e8 5e f9 ff ff       	call   80104174 <create>
80104816:	89 c6                	mov    %eax,%esi
    if(ip == 0){
80104818:	83 c4 10             	add    $0x10,%esp
8010481b:	85 c0                	test   %eax,%eax
8010481d:	74 58                	je     80104877 <sys_open+0xbf>
      end_op();
      return -1;
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
8010481f:	e8 09 c4 ff ff       	call   80100c2d <filealloc>
80104824:	89 c3                	mov    %eax,%ebx
80104826:	85 c0                	test   %eax,%eax
80104828:	0f 84 ae 00 00 00    	je     801048dc <sys_open+0x124>
8010482e:	e8 b3 f8 ff ff       	call   801040e6 <fdalloc>
80104833:	89 c7                	mov    %eax,%edi
80104835:	85 c0                	test   %eax,%eax
80104837:	0f 88 9f 00 00 00    	js     801048dc <sys_open+0x124>
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
8010483d:	83 ec 0c             	sub    $0xc,%esp
80104840:	56                   	push   %esi
80104841:	e8 fd cd ff ff       	call   80101643 <iunlock>
  end_op();
80104846:	e8 b8 e0 ff ff       	call   80102903 <end_op>

  f->type = FD_INODE;
8010484b:	c7 03 02 00 00 00    	movl   $0x2,(%ebx)
  f->ip = ip;
80104851:	89 73 10             	mov    %esi,0x10(%ebx)
  f->off = 0;
80104854:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
  f->readable = !(omode & O_WRONLY);
8010485b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010485e:	83 c4 10             	add    $0x10,%esp
80104861:	a8 01                	test   $0x1,%al
80104863:	0f 94 43 08          	sete   0x8(%ebx)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80104867:	a8 03                	test   $0x3,%al
80104869:	0f 95 43 09          	setne  0x9(%ebx)
  return fd;
}
8010486d:	89 f8                	mov    %edi,%eax
8010486f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104872:	5b                   	pop    %ebx
80104873:	5e                   	pop    %esi
80104874:	5f                   	pop    %edi
80104875:	5d                   	pop    %ebp
80104876:	c3                   	ret    
      end_op();
80104877:	e8 87 e0 ff ff       	call   80102903 <end_op>
      return -1;
8010487c:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104881:	eb ea                	jmp    8010486d <sys_open+0xb5>
    if((ip = namei(path)) == 0){
80104883:	83 ec 0c             	sub    $0xc,%esp
80104886:	ff 75 e4             	pushl  -0x1c(%ebp)
80104889:	e8 53 d3 ff ff       	call   80101be1 <namei>
8010488e:	89 c6                	mov    %eax,%esi
80104890:	83 c4 10             	add    $0x10,%esp
80104893:	85 c0                	test   %eax,%eax
80104895:	74 39                	je     801048d0 <sys_open+0x118>
    ilock(ip);
80104897:	83 ec 0c             	sub    $0xc,%esp
8010489a:	50                   	push   %eax
8010489b:	e8 e1 cc ff ff       	call   80101581 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
801048a0:	83 c4 10             	add    $0x10,%esp
801048a3:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
801048a8:	0f 85 71 ff ff ff    	jne    8010481f <sys_open+0x67>
801048ae:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
801048b2:	0f 84 67 ff ff ff    	je     8010481f <sys_open+0x67>
      iunlockput(ip);
801048b8:	83 ec 0c             	sub    $0xc,%esp
801048bb:	56                   	push   %esi
801048bc:	e8 67 ce ff ff       	call   80101728 <iunlockput>
      end_op();
801048c1:	e8 3d e0 ff ff       	call   80102903 <end_op>
      return -1;
801048c6:	83 c4 10             	add    $0x10,%esp
801048c9:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801048ce:	eb 9d                	jmp    8010486d <sys_open+0xb5>
      end_op();
801048d0:	e8 2e e0 ff ff       	call   80102903 <end_op>
      return -1;
801048d5:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801048da:	eb 91                	jmp    8010486d <sys_open+0xb5>
    if(f)
801048dc:	85 db                	test   %ebx,%ebx
801048de:	74 0c                	je     801048ec <sys_open+0x134>
      fileclose(f);
801048e0:	83 ec 0c             	sub    $0xc,%esp
801048e3:	53                   	push   %ebx
801048e4:	e8 ea c3 ff ff       	call   80100cd3 <fileclose>
801048e9:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
801048ec:	83 ec 0c             	sub    $0xc,%esp
801048ef:	56                   	push   %esi
801048f0:	e8 33 ce ff ff       	call   80101728 <iunlockput>
    end_op();
801048f5:	e8 09 e0 ff ff       	call   80102903 <end_op>
    return -1;
801048fa:	83 c4 10             	add    $0x10,%esp
801048fd:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104902:	e9 66 ff ff ff       	jmp    8010486d <sys_open+0xb5>
    return -1;
80104907:	bf ff ff ff ff       	mov    $0xffffffff,%edi
8010490c:	e9 5c ff ff ff       	jmp    8010486d <sys_open+0xb5>
80104911:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104916:	e9 52 ff ff ff       	jmp    8010486d <sys_open+0xb5>

8010491b <sys_mkdir>:

int
sys_mkdir(void)
{
8010491b:	55                   	push   %ebp
8010491c:	89 e5                	mov    %esp,%ebp
8010491e:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
80104921:	e8 63 df ff ff       	call   80102889 <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80104926:	83 ec 08             	sub    $0x8,%esp
80104929:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010492c:	50                   	push   %eax
8010492d:	6a 00                	push   $0x0
8010492f:	e8 c3 f6 ff ff       	call   80103ff7 <argstr>
80104934:	83 c4 10             	add    $0x10,%esp
80104937:	85 c0                	test   %eax,%eax
80104939:	78 36                	js     80104971 <sys_mkdir+0x56>
8010493b:	83 ec 0c             	sub    $0xc,%esp
8010493e:	6a 00                	push   $0x0
80104940:	b9 00 00 00 00       	mov    $0x0,%ecx
80104945:	ba 01 00 00 00       	mov    $0x1,%edx
8010494a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010494d:	e8 22 f8 ff ff       	call   80104174 <create>
80104952:	83 c4 10             	add    $0x10,%esp
80104955:	85 c0                	test   %eax,%eax
80104957:	74 18                	je     80104971 <sys_mkdir+0x56>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104959:	83 ec 0c             	sub    $0xc,%esp
8010495c:	50                   	push   %eax
8010495d:	e8 c6 cd ff ff       	call   80101728 <iunlockput>
  end_op();
80104962:	e8 9c df ff ff       	call   80102903 <end_op>
  return 0;
80104967:	83 c4 10             	add    $0x10,%esp
8010496a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010496f:	c9                   	leave  
80104970:	c3                   	ret    
    end_op();
80104971:	e8 8d df ff ff       	call   80102903 <end_op>
    return -1;
80104976:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010497b:	eb f2                	jmp    8010496f <sys_mkdir+0x54>

8010497d <sys_mknod>:

int
sys_mknod(void)
{
8010497d:	55                   	push   %ebp
8010497e:	89 e5                	mov    %esp,%ebp
80104980:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
80104983:	e8 01 df ff ff       	call   80102889 <begin_op>
  if((argstr(0, &path)) < 0 ||
80104988:	83 ec 08             	sub    $0x8,%esp
8010498b:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010498e:	50                   	push   %eax
8010498f:	6a 00                	push   $0x0
80104991:	e8 61 f6 ff ff       	call   80103ff7 <argstr>
80104996:	83 c4 10             	add    $0x10,%esp
80104999:	85 c0                	test   %eax,%eax
8010499b:	78 62                	js     801049ff <sys_mknod+0x82>
     argint(1, &major) < 0 ||
8010499d:	83 ec 08             	sub    $0x8,%esp
801049a0:	8d 45 f0             	lea    -0x10(%ebp),%eax
801049a3:	50                   	push   %eax
801049a4:	6a 01                	push   $0x1
801049a6:	e8 bc f5 ff ff       	call   80103f67 <argint>
  if((argstr(0, &path)) < 0 ||
801049ab:	83 c4 10             	add    $0x10,%esp
801049ae:	85 c0                	test   %eax,%eax
801049b0:	78 4d                	js     801049ff <sys_mknod+0x82>
     argint(2, &minor) < 0 ||
801049b2:	83 ec 08             	sub    $0x8,%esp
801049b5:	8d 45 ec             	lea    -0x14(%ebp),%eax
801049b8:	50                   	push   %eax
801049b9:	6a 02                	push   $0x2
801049bb:	e8 a7 f5 ff ff       	call   80103f67 <argint>
     argint(1, &major) < 0 ||
801049c0:	83 c4 10             	add    $0x10,%esp
801049c3:	85 c0                	test   %eax,%eax
801049c5:	78 38                	js     801049ff <sys_mknod+0x82>
     (ip = create(path, T_DEV, major, minor)) == 0){
801049c7:	0f bf 45 ec          	movswl -0x14(%ebp),%eax
801049cb:	0f bf 4d f0          	movswl -0x10(%ebp),%ecx
     argint(2, &minor) < 0 ||
801049cf:	83 ec 0c             	sub    $0xc,%esp
801049d2:	50                   	push   %eax
801049d3:	ba 03 00 00 00       	mov    $0x3,%edx
801049d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049db:	e8 94 f7 ff ff       	call   80104174 <create>
801049e0:	83 c4 10             	add    $0x10,%esp
801049e3:	85 c0                	test   %eax,%eax
801049e5:	74 18                	je     801049ff <sys_mknod+0x82>
    end_op();
    return -1;
  }
  iunlockput(ip);
801049e7:	83 ec 0c             	sub    $0xc,%esp
801049ea:	50                   	push   %eax
801049eb:	e8 38 cd ff ff       	call   80101728 <iunlockput>
  end_op();
801049f0:	e8 0e df ff ff       	call   80102903 <end_op>
  return 0;
801049f5:	83 c4 10             	add    $0x10,%esp
801049f8:	b8 00 00 00 00       	mov    $0x0,%eax
}
801049fd:	c9                   	leave  
801049fe:	c3                   	ret    
    end_op();
801049ff:	e8 ff de ff ff       	call   80102903 <end_op>
    return -1;
80104a04:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a09:	eb f2                	jmp    801049fd <sys_mknod+0x80>

80104a0b <sys_chdir>:

int
sys_chdir(void)
{
80104a0b:	55                   	push   %ebp
80104a0c:	89 e5                	mov    %esp,%ebp
80104a0e:	56                   	push   %esi
80104a0f:	53                   	push   %ebx
80104a10:	83 ec 10             	sub    $0x10,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
80104a13:	e8 b9 e8 ff ff       	call   801032d1 <myproc>
80104a18:	89 c6                	mov    %eax,%esi
  
  begin_op();
80104a1a:	e8 6a de ff ff       	call   80102889 <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80104a1f:	83 ec 08             	sub    $0x8,%esp
80104a22:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104a25:	50                   	push   %eax
80104a26:	6a 00                	push   $0x0
80104a28:	e8 ca f5 ff ff       	call   80103ff7 <argstr>
80104a2d:	83 c4 10             	add    $0x10,%esp
80104a30:	85 c0                	test   %eax,%eax
80104a32:	78 52                	js     80104a86 <sys_chdir+0x7b>
80104a34:	83 ec 0c             	sub    $0xc,%esp
80104a37:	ff 75 f4             	pushl  -0xc(%ebp)
80104a3a:	e8 a2 d1 ff ff       	call   80101be1 <namei>
80104a3f:	89 c3                	mov    %eax,%ebx
80104a41:	83 c4 10             	add    $0x10,%esp
80104a44:	85 c0                	test   %eax,%eax
80104a46:	74 3e                	je     80104a86 <sys_chdir+0x7b>
    end_op();
    return -1;
  }
  ilock(ip);
80104a48:	83 ec 0c             	sub    $0xc,%esp
80104a4b:	50                   	push   %eax
80104a4c:	e8 30 cb ff ff       	call   80101581 <ilock>
  if(ip->type != T_DIR){
80104a51:	83 c4 10             	add    $0x10,%esp
80104a54:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104a59:	75 37                	jne    80104a92 <sys_chdir+0x87>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104a5b:	83 ec 0c             	sub    $0xc,%esp
80104a5e:	53                   	push   %ebx
80104a5f:	e8 df cb ff ff       	call   80101643 <iunlock>
  iput(curproc->cwd);
80104a64:	83 c4 04             	add    $0x4,%esp
80104a67:	ff 76 68             	pushl  0x68(%esi)
80104a6a:	e8 19 cc ff ff       	call   80101688 <iput>
  end_op();
80104a6f:	e8 8f de ff ff       	call   80102903 <end_op>
  curproc->cwd = ip;
80104a74:	89 5e 68             	mov    %ebx,0x68(%esi)
  return 0;
80104a77:	83 c4 10             	add    $0x10,%esp
80104a7a:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104a7f:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104a82:	5b                   	pop    %ebx
80104a83:	5e                   	pop    %esi
80104a84:	5d                   	pop    %ebp
80104a85:	c3                   	ret    
    end_op();
80104a86:	e8 78 de ff ff       	call   80102903 <end_op>
    return -1;
80104a8b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a90:	eb ed                	jmp    80104a7f <sys_chdir+0x74>
    iunlockput(ip);
80104a92:	83 ec 0c             	sub    $0xc,%esp
80104a95:	53                   	push   %ebx
80104a96:	e8 8d cc ff ff       	call   80101728 <iunlockput>
    end_op();
80104a9b:	e8 63 de ff ff       	call   80102903 <end_op>
    return -1;
80104aa0:	83 c4 10             	add    $0x10,%esp
80104aa3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104aa8:	eb d5                	jmp    80104a7f <sys_chdir+0x74>

80104aaa <sys_exec>:

int
sys_exec(void)
{
80104aaa:	55                   	push   %ebp
80104aab:	89 e5                	mov    %esp,%ebp
80104aad:	53                   	push   %ebx
80104aae:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80104ab4:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104ab7:	50                   	push   %eax
80104ab8:	6a 00                	push   $0x0
80104aba:	e8 38 f5 ff ff       	call   80103ff7 <argstr>
80104abf:	83 c4 10             	add    $0x10,%esp
80104ac2:	85 c0                	test   %eax,%eax
80104ac4:	0f 88 a8 00 00 00    	js     80104b72 <sys_exec+0xc8>
80104aca:	83 ec 08             	sub    $0x8,%esp
80104acd:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80104ad3:	50                   	push   %eax
80104ad4:	6a 01                	push   $0x1
80104ad6:	e8 8c f4 ff ff       	call   80103f67 <argint>
80104adb:	83 c4 10             	add    $0x10,%esp
80104ade:	85 c0                	test   %eax,%eax
80104ae0:	0f 88 93 00 00 00    	js     80104b79 <sys_exec+0xcf>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
80104ae6:	83 ec 04             	sub    $0x4,%esp
80104ae9:	68 80 00 00 00       	push   $0x80
80104aee:	6a 00                	push   $0x0
80104af0:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104af6:	50                   	push   %eax
80104af7:	e8 20 f2 ff ff       	call   80103d1c <memset>
80104afc:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
80104aff:	bb 00 00 00 00       	mov    $0x0,%ebx
    if(i >= NELEM(argv))
80104b04:	83 fb 1f             	cmp    $0x1f,%ebx
80104b07:	77 77                	ja     80104b80 <sys_exec+0xd6>
      return -1;
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80104b09:	83 ec 08             	sub    $0x8,%esp
80104b0c:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80104b12:	50                   	push   %eax
80104b13:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
80104b19:	8d 04 98             	lea    (%eax,%ebx,4),%eax
80104b1c:	50                   	push   %eax
80104b1d:	e8 c9 f3 ff ff       	call   80103eeb <fetchint>
80104b22:	83 c4 10             	add    $0x10,%esp
80104b25:	85 c0                	test   %eax,%eax
80104b27:	78 5e                	js     80104b87 <sys_exec+0xdd>
      return -1;
    if(uarg == 0){
80104b29:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80104b2f:	85 c0                	test   %eax,%eax
80104b31:	74 1d                	je     80104b50 <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80104b33:	83 ec 08             	sub    $0x8,%esp
80104b36:	8d 94 9d 74 ff ff ff 	lea    -0x8c(%ebp,%ebx,4),%edx
80104b3d:	52                   	push   %edx
80104b3e:	50                   	push   %eax
80104b3f:	e8 e3 f3 ff ff       	call   80103f27 <fetchstr>
80104b44:	83 c4 10             	add    $0x10,%esp
80104b47:	85 c0                	test   %eax,%eax
80104b49:	78 46                	js     80104b91 <sys_exec+0xe7>
  for(i=0;; i++){
80104b4b:	83 c3 01             	add    $0x1,%ebx
    if(i >= NELEM(argv))
80104b4e:	eb b4                	jmp    80104b04 <sys_exec+0x5a>
      argv[i] = 0;
80104b50:	c7 84 9d 74 ff ff ff 	movl   $0x0,-0x8c(%ebp,%ebx,4)
80104b57:	00 00 00 00 
      return -1;
  }
  return exec(path, argv);
80104b5b:	83 ec 08             	sub    $0x8,%esp
80104b5e:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104b64:	50                   	push   %eax
80104b65:	ff 75 f4             	pushl  -0xc(%ebp)
80104b68:	e8 65 bd ff ff       	call   801008d2 <exec>
80104b6d:	83 c4 10             	add    $0x10,%esp
80104b70:	eb 1a                	jmp    80104b8c <sys_exec+0xe2>
    return -1;
80104b72:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b77:	eb 13                	jmp    80104b8c <sys_exec+0xe2>
80104b79:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b7e:	eb 0c                	jmp    80104b8c <sys_exec+0xe2>
      return -1;
80104b80:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b85:	eb 05                	jmp    80104b8c <sys_exec+0xe2>
      return -1;
80104b87:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104b8c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104b8f:	c9                   	leave  
80104b90:	c3                   	ret    
      return -1;
80104b91:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b96:	eb f4                	jmp    80104b8c <sys_exec+0xe2>

80104b98 <sys_pipe>:

int
sys_pipe(void)
{
80104b98:	55                   	push   %ebp
80104b99:	89 e5                	mov    %esp,%ebp
80104b9b:	53                   	push   %ebx
80104b9c:	83 ec 18             	sub    $0x18,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80104b9f:	6a 08                	push   $0x8
80104ba1:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104ba4:	50                   	push   %eax
80104ba5:	6a 00                	push   $0x0
80104ba7:	e8 e3 f3 ff ff       	call   80103f8f <argptr>
80104bac:	83 c4 10             	add    $0x10,%esp
80104baf:	85 c0                	test   %eax,%eax
80104bb1:	78 77                	js     80104c2a <sys_pipe+0x92>
    return -1;
  if(pipealloc(&rf, &wf) < 0)
80104bb3:	83 ec 08             	sub    $0x8,%esp
80104bb6:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104bb9:	50                   	push   %eax
80104bba:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104bbd:	50                   	push   %eax
80104bbe:	e8 4d e2 ff ff       	call   80102e10 <pipealloc>
80104bc3:	83 c4 10             	add    $0x10,%esp
80104bc6:	85 c0                	test   %eax,%eax
80104bc8:	78 67                	js     80104c31 <sys_pipe+0x99>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80104bca:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bcd:	e8 14 f5 ff ff       	call   801040e6 <fdalloc>
80104bd2:	89 c3                	mov    %eax,%ebx
80104bd4:	85 c0                	test   %eax,%eax
80104bd6:	78 21                	js     80104bf9 <sys_pipe+0x61>
80104bd8:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104bdb:	e8 06 f5 ff ff       	call   801040e6 <fdalloc>
80104be0:	85 c0                	test   %eax,%eax
80104be2:	78 15                	js     80104bf9 <sys_pipe+0x61>
      myproc()->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  fd[0] = fd0;
80104be4:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104be7:	89 1a                	mov    %ebx,(%edx)
  fd[1] = fd1;
80104be9:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104bec:	89 42 04             	mov    %eax,0x4(%edx)
  return 0;
80104bef:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104bf4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104bf7:	c9                   	leave  
80104bf8:	c3                   	ret    
    if(fd0 >= 0)
80104bf9:	85 db                	test   %ebx,%ebx
80104bfb:	78 0d                	js     80104c0a <sys_pipe+0x72>
      myproc()->ofile[fd0] = 0;
80104bfd:	e8 cf e6 ff ff       	call   801032d1 <myproc>
80104c02:	c7 44 98 28 00 00 00 	movl   $0x0,0x28(%eax,%ebx,4)
80104c09:	00 
    fileclose(rf);
80104c0a:	83 ec 0c             	sub    $0xc,%esp
80104c0d:	ff 75 f0             	pushl  -0x10(%ebp)
80104c10:	e8 be c0 ff ff       	call   80100cd3 <fileclose>
    fileclose(wf);
80104c15:	83 c4 04             	add    $0x4,%esp
80104c18:	ff 75 ec             	pushl  -0x14(%ebp)
80104c1b:	e8 b3 c0 ff ff       	call   80100cd3 <fileclose>
    return -1;
80104c20:	83 c4 10             	add    $0x10,%esp
80104c23:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c28:	eb ca                	jmp    80104bf4 <sys_pipe+0x5c>
    return -1;
80104c2a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c2f:	eb c3                	jmp    80104bf4 <sys_pipe+0x5c>
    return -1;
80104c31:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c36:	eb bc                	jmp    80104bf4 <sys_pipe+0x5c>

80104c38 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80104c38:	55                   	push   %ebp
80104c39:	89 e5                	mov    %esp,%ebp
80104c3b:	83 ec 08             	sub    $0x8,%esp
  return fork();
80104c3e:	e8 06 e8 ff ff       	call   80103449 <fork>
}
80104c43:	c9                   	leave  
80104c44:	c3                   	ret    

80104c45 <sys_exit>:

int
sys_exit(void)
{
80104c45:	55                   	push   %ebp
80104c46:	89 e5                	mov    %esp,%ebp
80104c48:	83 ec 08             	sub    $0x8,%esp
  exit();
80104c4b:	e8 2d ea ff ff       	call   8010367d <exit>
  return 0;  // not reached
}
80104c50:	b8 00 00 00 00       	mov    $0x0,%eax
80104c55:	c9                   	leave  
80104c56:	c3                   	ret    

80104c57 <sys_wait>:

int
sys_wait(void)
{
80104c57:	55                   	push   %ebp
80104c58:	89 e5                	mov    %esp,%ebp
80104c5a:	83 ec 08             	sub    $0x8,%esp
  return wait();
80104c5d:	e8 a4 eb ff ff       	call   80103806 <wait>
}
80104c62:	c9                   	leave  
80104c63:	c3                   	ret    

80104c64 <sys_kill>:

int
sys_kill(void)
{
80104c64:	55                   	push   %ebp
80104c65:	89 e5                	mov    %esp,%ebp
80104c67:	83 ec 20             	sub    $0x20,%esp
  int pid;

  if(argint(0, &pid) < 0)
80104c6a:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104c6d:	50                   	push   %eax
80104c6e:	6a 00                	push   $0x0
80104c70:	e8 f2 f2 ff ff       	call   80103f67 <argint>
80104c75:	83 c4 10             	add    $0x10,%esp
80104c78:	85 c0                	test   %eax,%eax
80104c7a:	78 10                	js     80104c8c <sys_kill+0x28>
    return -1;
  return kill(pid);
80104c7c:	83 ec 0c             	sub    $0xc,%esp
80104c7f:	ff 75 f4             	pushl  -0xc(%ebp)
80104c82:	e8 7c ec ff ff       	call   80103903 <kill>
80104c87:	83 c4 10             	add    $0x10,%esp
}
80104c8a:	c9                   	leave  
80104c8b:	c3                   	ret    
    return -1;
80104c8c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c91:	eb f7                	jmp    80104c8a <sys_kill+0x26>

80104c93 <sys_dump_physmem>:

int
sys_dump_physmem(void)
{
80104c93:	55                   	push   %ebp
80104c94:	89 e5                	mov    %esp,%ebp
80104c96:	83 ec 1c             	sub    $0x1c,%esp
  int *frames;
  int *pids;
  int numframes;

  if(argptr(0, (void *)&frames, sizeof(int)) < 0)
80104c99:	6a 04                	push   $0x4
80104c9b:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104c9e:	50                   	push   %eax
80104c9f:	6a 00                	push   $0x0
80104ca1:	e8 e9 f2 ff ff       	call   80103f8f <argptr>
80104ca6:	83 c4 10             	add    $0x10,%esp
80104ca9:	85 c0                	test   %eax,%eax
80104cab:	78 42                	js     80104cef <sys_dump_physmem+0x5c>
    return -1;
  if(argptr(0, (void *)&pids, sizeof(int)) < 0)
80104cad:	83 ec 04             	sub    $0x4,%esp
80104cb0:	6a 04                	push   $0x4
80104cb2:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104cb5:	50                   	push   %eax
80104cb6:	6a 00                	push   $0x0
80104cb8:	e8 d2 f2 ff ff       	call   80103f8f <argptr>
80104cbd:	83 c4 10             	add    $0x10,%esp
80104cc0:	85 c0                	test   %eax,%eax
80104cc2:	78 32                	js     80104cf6 <sys_dump_physmem+0x63>
    return -1;
  if(argint(0, &numframes) < 0)
80104cc4:	83 ec 08             	sub    $0x8,%esp
80104cc7:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104cca:	50                   	push   %eax
80104ccb:	6a 00                	push   $0x0
80104ccd:	e8 95 f2 ff ff       	call   80103f67 <argint>
80104cd2:	83 c4 10             	add    $0x10,%esp
80104cd5:	85 c0                	test   %eax,%eax
80104cd7:	78 24                	js     80104cfd <sys_dump_physmem+0x6a>
    return -1;
  return dump_physmem(frames, pids, numframes);
80104cd9:	83 ec 04             	sub    $0x4,%esp
80104cdc:	ff 75 ec             	pushl  -0x14(%ebp)
80104cdf:	ff 75 f0             	pushl  -0x10(%ebp)
80104ce2:	ff 75 f4             	pushl  -0xc(%ebp)
80104ce5:	e8 88 d4 ff ff       	call   80102172 <dump_physmem>
80104cea:	83 c4 10             	add    $0x10,%esp
}
80104ced:	c9                   	leave  
80104cee:	c3                   	ret    
    return -1;
80104cef:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104cf4:	eb f7                	jmp    80104ced <sys_dump_physmem+0x5a>
    return -1;
80104cf6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104cfb:	eb f0                	jmp    80104ced <sys_dump_physmem+0x5a>
    return -1;
80104cfd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d02:	eb e9                	jmp    80104ced <sys_dump_physmem+0x5a>

80104d04 <sys_getpid>:

int
sys_getpid(void)
{
80104d04:	55                   	push   %ebp
80104d05:	89 e5                	mov    %esp,%ebp
80104d07:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
80104d0a:	e8 c2 e5 ff ff       	call   801032d1 <myproc>
80104d0f:	8b 40 10             	mov    0x10(%eax),%eax
}
80104d12:	c9                   	leave  
80104d13:	c3                   	ret    

80104d14 <sys_sbrk>:

int
sys_sbrk(void)
{
80104d14:	55                   	push   %ebp
80104d15:	89 e5                	mov    %esp,%ebp
80104d17:	53                   	push   %ebx
80104d18:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80104d1b:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d1e:	50                   	push   %eax
80104d1f:	6a 00                	push   $0x0
80104d21:	e8 41 f2 ff ff       	call   80103f67 <argint>
80104d26:	83 c4 10             	add    $0x10,%esp
80104d29:	85 c0                	test   %eax,%eax
80104d2b:	78 27                	js     80104d54 <sys_sbrk+0x40>
    return -1;
  addr = myproc()->sz;
80104d2d:	e8 9f e5 ff ff       	call   801032d1 <myproc>
80104d32:	8b 18                	mov    (%eax),%ebx
  if(growproc(n) < 0)
80104d34:	83 ec 0c             	sub    $0xc,%esp
80104d37:	ff 75 f4             	pushl  -0xc(%ebp)
80104d3a:	e8 9d e6 ff ff       	call   801033dc <growproc>
80104d3f:	83 c4 10             	add    $0x10,%esp
80104d42:	85 c0                	test   %eax,%eax
80104d44:	78 07                	js     80104d4d <sys_sbrk+0x39>
    return -1;
  return addr;
}
80104d46:	89 d8                	mov    %ebx,%eax
80104d48:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104d4b:	c9                   	leave  
80104d4c:	c3                   	ret    
    return -1;
80104d4d:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104d52:	eb f2                	jmp    80104d46 <sys_sbrk+0x32>
    return -1;
80104d54:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104d59:	eb eb                	jmp    80104d46 <sys_sbrk+0x32>

80104d5b <sys_sleep>:

int
sys_sleep(void)
{
80104d5b:	55                   	push   %ebp
80104d5c:	89 e5                	mov    %esp,%ebp
80104d5e:	53                   	push   %ebx
80104d5f:	83 ec 1c             	sub    $0x1c,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
80104d62:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d65:	50                   	push   %eax
80104d66:	6a 00                	push   $0x0
80104d68:	e8 fa f1 ff ff       	call   80103f67 <argint>
80104d6d:	83 c4 10             	add    $0x10,%esp
80104d70:	85 c0                	test   %eax,%eax
80104d72:	78 75                	js     80104de9 <sys_sleep+0x8e>
    return -1;
  acquire(&tickslock);
80104d74:	83 ec 0c             	sub    $0xc,%esp
80104d77:	68 80 3c 13 80       	push   $0x80133c80
80104d7c:	e8 ef ee ff ff       	call   80103c70 <acquire>
  ticks0 = ticks;
80104d81:	8b 1d c0 44 13 80    	mov    0x801344c0,%ebx
  while(ticks - ticks0 < n){
80104d87:	83 c4 10             	add    $0x10,%esp
80104d8a:	a1 c0 44 13 80       	mov    0x801344c0,%eax
80104d8f:	29 d8                	sub    %ebx,%eax
80104d91:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104d94:	73 39                	jae    80104dcf <sys_sleep+0x74>
    if(myproc()->killed){
80104d96:	e8 36 e5 ff ff       	call   801032d1 <myproc>
80104d9b:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104d9f:	75 17                	jne    80104db8 <sys_sleep+0x5d>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
80104da1:	83 ec 08             	sub    $0x8,%esp
80104da4:	68 80 3c 13 80       	push   $0x80133c80
80104da9:	68 c0 44 13 80       	push   $0x801344c0
80104dae:	e8 c2 e9 ff ff       	call   80103775 <sleep>
80104db3:	83 c4 10             	add    $0x10,%esp
80104db6:	eb d2                	jmp    80104d8a <sys_sleep+0x2f>
      release(&tickslock);
80104db8:	83 ec 0c             	sub    $0xc,%esp
80104dbb:	68 80 3c 13 80       	push   $0x80133c80
80104dc0:	e8 10 ef ff ff       	call   80103cd5 <release>
      return -1;
80104dc5:	83 c4 10             	add    $0x10,%esp
80104dc8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104dcd:	eb 15                	jmp    80104de4 <sys_sleep+0x89>
  }
  release(&tickslock);
80104dcf:	83 ec 0c             	sub    $0xc,%esp
80104dd2:	68 80 3c 13 80       	push   $0x80133c80
80104dd7:	e8 f9 ee ff ff       	call   80103cd5 <release>
  return 0;
80104ddc:	83 c4 10             	add    $0x10,%esp
80104ddf:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104de4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104de7:	c9                   	leave  
80104de8:	c3                   	ret    
    return -1;
80104de9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104dee:	eb f4                	jmp    80104de4 <sys_sleep+0x89>

80104df0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80104df0:	55                   	push   %ebp
80104df1:	89 e5                	mov    %esp,%ebp
80104df3:	53                   	push   %ebx
80104df4:	83 ec 10             	sub    $0x10,%esp
  uint xticks;

  acquire(&tickslock);
80104df7:	68 80 3c 13 80       	push   $0x80133c80
80104dfc:	e8 6f ee ff ff       	call   80103c70 <acquire>
  xticks = ticks;
80104e01:	8b 1d c0 44 13 80    	mov    0x801344c0,%ebx
  release(&tickslock);
80104e07:	c7 04 24 80 3c 13 80 	movl   $0x80133c80,(%esp)
80104e0e:	e8 c2 ee ff ff       	call   80103cd5 <release>
  return xticks;
}
80104e13:	89 d8                	mov    %ebx,%eax
80104e15:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104e18:	c9                   	leave  
80104e19:	c3                   	ret    

80104e1a <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80104e1a:	1e                   	push   %ds
  pushl %es
80104e1b:	06                   	push   %es
  pushl %fs
80104e1c:	0f a0                	push   %fs
  pushl %gs
80104e1e:	0f a8                	push   %gs
  pushal
80104e20:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
80104e21:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80104e25:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80104e27:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
80104e29:	54                   	push   %esp
  call trap
80104e2a:	e8 e3 00 00 00       	call   80104f12 <trap>
  addl $4, %esp
80104e2f:	83 c4 04             	add    $0x4,%esp

80104e32 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80104e32:	61                   	popa   
  popl %gs
80104e33:	0f a9                	pop    %gs
  popl %fs
80104e35:	0f a1                	pop    %fs
  popl %es
80104e37:	07                   	pop    %es
  popl %ds
80104e38:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80104e39:	83 c4 08             	add    $0x8,%esp
  iret
80104e3c:	cf                   	iret   

80104e3d <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80104e3d:	55                   	push   %ebp
80104e3e:	89 e5                	mov    %esp,%ebp
80104e40:	83 ec 08             	sub    $0x8,%esp
  int i;

  for(i = 0; i < 256; i++)
80104e43:	b8 00 00 00 00       	mov    $0x0,%eax
80104e48:	eb 4a                	jmp    80104e94 <tvinit+0x57>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80104e4a:	8b 0c 85 08 90 10 80 	mov    -0x7fef6ff8(,%eax,4),%ecx
80104e51:	66 89 0c c5 c0 3c 13 	mov    %cx,-0x7fecc340(,%eax,8)
80104e58:	80 
80104e59:	66 c7 04 c5 c2 3c 13 	movw   $0x8,-0x7fecc33e(,%eax,8)
80104e60:	80 08 00 
80104e63:	c6 04 c5 c4 3c 13 80 	movb   $0x0,-0x7fecc33c(,%eax,8)
80104e6a:	00 
80104e6b:	0f b6 14 c5 c5 3c 13 	movzbl -0x7fecc33b(,%eax,8),%edx
80104e72:	80 
80104e73:	83 e2 f0             	and    $0xfffffff0,%edx
80104e76:	83 ca 0e             	or     $0xe,%edx
80104e79:	83 e2 8f             	and    $0xffffff8f,%edx
80104e7c:	83 ca 80             	or     $0xffffff80,%edx
80104e7f:	88 14 c5 c5 3c 13 80 	mov    %dl,-0x7fecc33b(,%eax,8)
80104e86:	c1 e9 10             	shr    $0x10,%ecx
80104e89:	66 89 0c c5 c6 3c 13 	mov    %cx,-0x7fecc33a(,%eax,8)
80104e90:	80 
  for(i = 0; i < 256; i++)
80104e91:	83 c0 01             	add    $0x1,%eax
80104e94:	3d ff 00 00 00       	cmp    $0xff,%eax
80104e99:	7e af                	jle    80104e4a <tvinit+0xd>
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80104e9b:	8b 15 08 91 10 80    	mov    0x80109108,%edx
80104ea1:	66 89 15 c0 3e 13 80 	mov    %dx,0x80133ec0
80104ea8:	66 c7 05 c2 3e 13 80 	movw   $0x8,0x80133ec2
80104eaf:	08 00 
80104eb1:	c6 05 c4 3e 13 80 00 	movb   $0x0,0x80133ec4
80104eb8:	0f b6 05 c5 3e 13 80 	movzbl 0x80133ec5,%eax
80104ebf:	83 c8 0f             	or     $0xf,%eax
80104ec2:	83 e0 ef             	and    $0xffffffef,%eax
80104ec5:	83 c8 e0             	or     $0xffffffe0,%eax
80104ec8:	a2 c5 3e 13 80       	mov    %al,0x80133ec5
80104ecd:	c1 ea 10             	shr    $0x10,%edx
80104ed0:	66 89 15 c6 3e 13 80 	mov    %dx,0x80133ec6

  initlock(&tickslock, "time");
80104ed7:	83 ec 08             	sub    $0x8,%esp
80104eda:	68 1d 6d 10 80       	push   $0x80106d1d
80104edf:	68 80 3c 13 80       	push   $0x80133c80
80104ee4:	e8 4b ec ff ff       	call   80103b34 <initlock>
}
80104ee9:	83 c4 10             	add    $0x10,%esp
80104eec:	c9                   	leave  
80104eed:	c3                   	ret    

80104eee <idtinit>:

void
idtinit(void)
{
80104eee:	55                   	push   %ebp
80104eef:	89 e5                	mov    %esp,%ebp
80104ef1:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
80104ef4:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
  pd[1] = (uint)p;
80104efa:	b8 c0 3c 13 80       	mov    $0x80133cc0,%eax
80104eff:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80104f03:	c1 e8 10             	shr    $0x10,%eax
80104f06:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lidt (%0)" : : "r" (pd));
80104f0a:	8d 45 fa             	lea    -0x6(%ebp),%eax
80104f0d:	0f 01 18             	lidtl  (%eax)
  lidt(idt, sizeof(idt));
}
80104f10:	c9                   	leave  
80104f11:	c3                   	ret    

80104f12 <trap>:

void
trap(struct trapframe *tf)
{
80104f12:	55                   	push   %ebp
80104f13:	89 e5                	mov    %esp,%ebp
80104f15:	57                   	push   %edi
80104f16:	56                   	push   %esi
80104f17:	53                   	push   %ebx
80104f18:	83 ec 1c             	sub    $0x1c,%esp
80104f1b:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(tf->trapno == T_SYSCALL){
80104f1e:	8b 43 30             	mov    0x30(%ebx),%eax
80104f21:	83 f8 40             	cmp    $0x40,%eax
80104f24:	74 13                	je     80104f39 <trap+0x27>
    if(myproc()->killed)
      exit();
    return;
  }

  switch(tf->trapno){
80104f26:	83 e8 20             	sub    $0x20,%eax
80104f29:	83 f8 1f             	cmp    $0x1f,%eax
80104f2c:	0f 87 3a 01 00 00    	ja     8010506c <trap+0x15a>
80104f32:	ff 24 85 c4 6d 10 80 	jmp    *-0x7fef923c(,%eax,4)
    if(myproc()->killed)
80104f39:	e8 93 e3 ff ff       	call   801032d1 <myproc>
80104f3e:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104f42:	75 1f                	jne    80104f63 <trap+0x51>
    myproc()->tf = tf;
80104f44:	e8 88 e3 ff ff       	call   801032d1 <myproc>
80104f49:	89 58 18             	mov    %ebx,0x18(%eax)
    syscall();
80104f4c:	e8 d9 f0 ff ff       	call   8010402a <syscall>
    if(myproc()->killed)
80104f51:	e8 7b e3 ff ff       	call   801032d1 <myproc>
80104f56:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104f5a:	74 7e                	je     80104fda <trap+0xc8>
      exit();
80104f5c:	e8 1c e7 ff ff       	call   8010367d <exit>
80104f61:	eb 77                	jmp    80104fda <trap+0xc8>
      exit();
80104f63:	e8 15 e7 ff ff       	call   8010367d <exit>
80104f68:	eb da                	jmp    80104f44 <trap+0x32>
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
80104f6a:	e8 47 e3 ff ff       	call   801032b6 <cpuid>
80104f6f:	85 c0                	test   %eax,%eax
80104f71:	74 6f                	je     80104fe2 <trap+0xd0>
      acquire(&tickslock);
      ticks++;
      wakeup(&ticks);
      release(&tickslock);
    }
    lapiceoi();
80104f73:	e8 fc d4 ff ff       	call   80102474 <lapiceoi>
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80104f78:	e8 54 e3 ff ff       	call   801032d1 <myproc>
80104f7d:	85 c0                	test   %eax,%eax
80104f7f:	74 1c                	je     80104f9d <trap+0x8b>
80104f81:	e8 4b e3 ff ff       	call   801032d1 <myproc>
80104f86:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104f8a:	74 11                	je     80104f9d <trap+0x8b>
80104f8c:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80104f90:	83 e0 03             	and    $0x3,%eax
80104f93:	66 83 f8 03          	cmp    $0x3,%ax
80104f97:	0f 84 62 01 00 00    	je     801050ff <trap+0x1ed>
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
80104f9d:	e8 2f e3 ff ff       	call   801032d1 <myproc>
80104fa2:	85 c0                	test   %eax,%eax
80104fa4:	74 0f                	je     80104fb5 <trap+0xa3>
80104fa6:	e8 26 e3 ff ff       	call   801032d1 <myproc>
80104fab:	83 78 0c 04          	cmpl   $0x4,0xc(%eax)
80104faf:	0f 84 54 01 00 00    	je     80105109 <trap+0x1f7>
     tf->trapno == T_IRQ0+IRQ_TIMER)
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80104fb5:	e8 17 e3 ff ff       	call   801032d1 <myproc>
80104fba:	85 c0                	test   %eax,%eax
80104fbc:	74 1c                	je     80104fda <trap+0xc8>
80104fbe:	e8 0e e3 ff ff       	call   801032d1 <myproc>
80104fc3:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104fc7:	74 11                	je     80104fda <trap+0xc8>
80104fc9:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80104fcd:	83 e0 03             	and    $0x3,%eax
80104fd0:	66 83 f8 03          	cmp    $0x3,%ax
80104fd4:	0f 84 43 01 00 00    	je     8010511d <trap+0x20b>
    exit();
}
80104fda:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104fdd:	5b                   	pop    %ebx
80104fde:	5e                   	pop    %esi
80104fdf:	5f                   	pop    %edi
80104fe0:	5d                   	pop    %ebp
80104fe1:	c3                   	ret    
      acquire(&tickslock);
80104fe2:	83 ec 0c             	sub    $0xc,%esp
80104fe5:	68 80 3c 13 80       	push   $0x80133c80
80104fea:	e8 81 ec ff ff       	call   80103c70 <acquire>
      ticks++;
80104fef:	83 05 c0 44 13 80 01 	addl   $0x1,0x801344c0
      wakeup(&ticks);
80104ff6:	c7 04 24 c0 44 13 80 	movl   $0x801344c0,(%esp)
80104ffd:	e8 d8 e8 ff ff       	call   801038da <wakeup>
      release(&tickslock);
80105002:	c7 04 24 80 3c 13 80 	movl   $0x80133c80,(%esp)
80105009:	e8 c7 ec ff ff       	call   80103cd5 <release>
8010500e:	83 c4 10             	add    $0x10,%esp
80105011:	e9 5d ff ff ff       	jmp    80104f73 <trap+0x61>
    ideintr();
80105016:	e8 58 cd ff ff       	call   80101d73 <ideintr>
    lapiceoi();
8010501b:	e8 54 d4 ff ff       	call   80102474 <lapiceoi>
    break;
80105020:	e9 53 ff ff ff       	jmp    80104f78 <trap+0x66>
    kbdintr();
80105025:	e8 8e d2 ff ff       	call   801022b8 <kbdintr>
    lapiceoi();
8010502a:	e8 45 d4 ff ff       	call   80102474 <lapiceoi>
    break;
8010502f:	e9 44 ff ff ff       	jmp    80104f78 <trap+0x66>
    uartintr();
80105034:	e8 05 02 00 00       	call   8010523e <uartintr>
    lapiceoi();
80105039:	e8 36 d4 ff ff       	call   80102474 <lapiceoi>
    break;
8010503e:	e9 35 ff ff ff       	jmp    80104f78 <trap+0x66>
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80105043:	8b 7b 38             	mov    0x38(%ebx),%edi
            cpuid(), tf->cs, tf->eip);
80105046:	0f b7 73 3c          	movzwl 0x3c(%ebx),%esi
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010504a:	e8 67 e2 ff ff       	call   801032b6 <cpuid>
8010504f:	57                   	push   %edi
80105050:	0f b7 f6             	movzwl %si,%esi
80105053:	56                   	push   %esi
80105054:	50                   	push   %eax
80105055:	68 28 6d 10 80       	push   $0x80106d28
8010505a:	e8 ac b5 ff ff       	call   8010060b <cprintf>
    lapiceoi();
8010505f:	e8 10 d4 ff ff       	call   80102474 <lapiceoi>
    break;
80105064:	83 c4 10             	add    $0x10,%esp
80105067:	e9 0c ff ff ff       	jmp    80104f78 <trap+0x66>
    if(myproc() == 0 || (tf->cs&3) == 0){
8010506c:	e8 60 e2 ff ff       	call   801032d1 <myproc>
80105071:	85 c0                	test   %eax,%eax
80105073:	74 5f                	je     801050d4 <trap+0x1c2>
80105075:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
80105079:	74 59                	je     801050d4 <trap+0x1c2>

static inline uint
rcr2(void)
{
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
8010507b:	0f 20 d7             	mov    %cr2,%edi
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010507e:	8b 43 38             	mov    0x38(%ebx),%eax
80105081:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105084:	e8 2d e2 ff ff       	call   801032b6 <cpuid>
80105089:	89 45 e0             	mov    %eax,-0x20(%ebp)
8010508c:	8b 53 34             	mov    0x34(%ebx),%edx
8010508f:	89 55 dc             	mov    %edx,-0x24(%ebp)
80105092:	8b 73 30             	mov    0x30(%ebx),%esi
            myproc()->pid, myproc()->name, tf->trapno,
80105095:	e8 37 e2 ff ff       	call   801032d1 <myproc>
8010509a:	8d 48 6c             	lea    0x6c(%eax),%ecx
8010509d:	89 4d d8             	mov    %ecx,-0x28(%ebp)
801050a0:	e8 2c e2 ff ff       	call   801032d1 <myproc>
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801050a5:	57                   	push   %edi
801050a6:	ff 75 e4             	pushl  -0x1c(%ebp)
801050a9:	ff 75 e0             	pushl  -0x20(%ebp)
801050ac:	ff 75 dc             	pushl  -0x24(%ebp)
801050af:	56                   	push   %esi
801050b0:	ff 75 d8             	pushl  -0x28(%ebp)
801050b3:	ff 70 10             	pushl  0x10(%eax)
801050b6:	68 80 6d 10 80       	push   $0x80106d80
801050bb:	e8 4b b5 ff ff       	call   8010060b <cprintf>
    myproc()->killed = 1;
801050c0:	83 c4 20             	add    $0x20,%esp
801050c3:	e8 09 e2 ff ff       	call   801032d1 <myproc>
801050c8:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
801050cf:	e9 a4 fe ff ff       	jmp    80104f78 <trap+0x66>
801050d4:	0f 20 d7             	mov    %cr2,%edi
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801050d7:	8b 73 38             	mov    0x38(%ebx),%esi
801050da:	e8 d7 e1 ff ff       	call   801032b6 <cpuid>
801050df:	83 ec 0c             	sub    $0xc,%esp
801050e2:	57                   	push   %edi
801050e3:	56                   	push   %esi
801050e4:	50                   	push   %eax
801050e5:	ff 73 30             	pushl  0x30(%ebx)
801050e8:	68 4c 6d 10 80       	push   $0x80106d4c
801050ed:	e8 19 b5 ff ff       	call   8010060b <cprintf>
      panic("trap");
801050f2:	83 c4 14             	add    $0x14,%esp
801050f5:	68 22 6d 10 80       	push   $0x80106d22
801050fa:	e8 49 b2 ff ff       	call   80100348 <panic>
    exit();
801050ff:	e8 79 e5 ff ff       	call   8010367d <exit>
80105104:	e9 94 fe ff ff       	jmp    80104f9d <trap+0x8b>
  if(myproc() && myproc()->state == RUNNING &&
80105109:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
8010510d:	0f 85 a2 fe ff ff    	jne    80104fb5 <trap+0xa3>
    yield();
80105113:	e8 2b e6 ff ff       	call   80103743 <yield>
80105118:	e9 98 fe ff ff       	jmp    80104fb5 <trap+0xa3>
    exit();
8010511d:	e8 5b e5 ff ff       	call   8010367d <exit>
80105122:	e9 b3 fe ff ff       	jmp    80104fda <trap+0xc8>

80105127 <uartgetc>:
  outb(COM1+0, c);
}

static int
uartgetc(void)
{
80105127:	55                   	push   %ebp
80105128:	89 e5                	mov    %esp,%ebp
  if(!uart)
8010512a:	83 3d bc 95 10 80 00 	cmpl   $0x0,0x801095bc
80105131:	74 15                	je     80105148 <uartgetc+0x21>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80105133:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105138:	ec                   	in     (%dx),%al
    return -1;
  if(!(inb(COM1+5) & 0x01))
80105139:	a8 01                	test   $0x1,%al
8010513b:	74 12                	je     8010514f <uartgetc+0x28>
8010513d:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105142:	ec                   	in     (%dx),%al
    return -1;
  return inb(COM1+0);
80105143:	0f b6 c0             	movzbl %al,%eax
}
80105146:	5d                   	pop    %ebp
80105147:	c3                   	ret    
    return -1;
80105148:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010514d:	eb f7                	jmp    80105146 <uartgetc+0x1f>
    return -1;
8010514f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105154:	eb f0                	jmp    80105146 <uartgetc+0x1f>

80105156 <uartputc>:
  if(!uart)
80105156:	83 3d bc 95 10 80 00 	cmpl   $0x0,0x801095bc
8010515d:	74 3b                	je     8010519a <uartputc+0x44>
{
8010515f:	55                   	push   %ebp
80105160:	89 e5                	mov    %esp,%ebp
80105162:	53                   	push   %ebx
80105163:	83 ec 04             	sub    $0x4,%esp
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80105166:	bb 00 00 00 00       	mov    $0x0,%ebx
8010516b:	eb 10                	jmp    8010517d <uartputc+0x27>
    microdelay(10);
8010516d:	83 ec 0c             	sub    $0xc,%esp
80105170:	6a 0a                	push   $0xa
80105172:	e8 1c d3 ff ff       	call   80102493 <microdelay>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80105177:	83 c3 01             	add    $0x1,%ebx
8010517a:	83 c4 10             	add    $0x10,%esp
8010517d:	83 fb 7f             	cmp    $0x7f,%ebx
80105180:	7f 0a                	jg     8010518c <uartputc+0x36>
80105182:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105187:	ec                   	in     (%dx),%al
80105188:	a8 20                	test   $0x20,%al
8010518a:	74 e1                	je     8010516d <uartputc+0x17>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010518c:	8b 45 08             	mov    0x8(%ebp),%eax
8010518f:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105194:	ee                   	out    %al,(%dx)
}
80105195:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80105198:	c9                   	leave  
80105199:	c3                   	ret    
8010519a:	f3 c3                	repz ret 

8010519c <uartinit>:
{
8010519c:	55                   	push   %ebp
8010519d:	89 e5                	mov    %esp,%ebp
8010519f:	56                   	push   %esi
801051a0:	53                   	push   %ebx
801051a1:	b9 00 00 00 00       	mov    $0x0,%ecx
801051a6:	ba fa 03 00 00       	mov    $0x3fa,%edx
801051ab:	89 c8                	mov    %ecx,%eax
801051ad:	ee                   	out    %al,(%dx)
801051ae:	be fb 03 00 00       	mov    $0x3fb,%esi
801051b3:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
801051b8:	89 f2                	mov    %esi,%edx
801051ba:	ee                   	out    %al,(%dx)
801051bb:	b8 0c 00 00 00       	mov    $0xc,%eax
801051c0:	ba f8 03 00 00       	mov    $0x3f8,%edx
801051c5:	ee                   	out    %al,(%dx)
801051c6:	bb f9 03 00 00       	mov    $0x3f9,%ebx
801051cb:	89 c8                	mov    %ecx,%eax
801051cd:	89 da                	mov    %ebx,%edx
801051cf:	ee                   	out    %al,(%dx)
801051d0:	b8 03 00 00 00       	mov    $0x3,%eax
801051d5:	89 f2                	mov    %esi,%edx
801051d7:	ee                   	out    %al,(%dx)
801051d8:	ba fc 03 00 00       	mov    $0x3fc,%edx
801051dd:	89 c8                	mov    %ecx,%eax
801051df:	ee                   	out    %al,(%dx)
801051e0:	b8 01 00 00 00       	mov    $0x1,%eax
801051e5:	89 da                	mov    %ebx,%edx
801051e7:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801051e8:	ba fd 03 00 00       	mov    $0x3fd,%edx
801051ed:	ec                   	in     (%dx),%al
  if(inb(COM1+5) == 0xFF)
801051ee:	3c ff                	cmp    $0xff,%al
801051f0:	74 45                	je     80105237 <uartinit+0x9b>
  uart = 1;
801051f2:	c7 05 bc 95 10 80 01 	movl   $0x1,0x801095bc
801051f9:	00 00 00 
801051fc:	ba fa 03 00 00       	mov    $0x3fa,%edx
80105201:	ec                   	in     (%dx),%al
80105202:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105207:	ec                   	in     (%dx),%al
  ioapicenable(IRQ_COM1, 0);
80105208:	83 ec 08             	sub    $0x8,%esp
8010520b:	6a 00                	push   $0x0
8010520d:	6a 04                	push   $0x4
8010520f:	e8 6a cd ff ff       	call   80101f7e <ioapicenable>
  for(p="xv6...\n"; *p; p++)
80105214:	83 c4 10             	add    $0x10,%esp
80105217:	bb 44 6e 10 80       	mov    $0x80106e44,%ebx
8010521c:	eb 12                	jmp    80105230 <uartinit+0x94>
    uartputc(*p);
8010521e:	83 ec 0c             	sub    $0xc,%esp
80105221:	0f be c0             	movsbl %al,%eax
80105224:	50                   	push   %eax
80105225:	e8 2c ff ff ff       	call   80105156 <uartputc>
  for(p="xv6...\n"; *p; p++)
8010522a:	83 c3 01             	add    $0x1,%ebx
8010522d:	83 c4 10             	add    $0x10,%esp
80105230:	0f b6 03             	movzbl (%ebx),%eax
80105233:	84 c0                	test   %al,%al
80105235:	75 e7                	jne    8010521e <uartinit+0x82>
}
80105237:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010523a:	5b                   	pop    %ebx
8010523b:	5e                   	pop    %esi
8010523c:	5d                   	pop    %ebp
8010523d:	c3                   	ret    

8010523e <uartintr>:

void
uartintr(void)
{
8010523e:	55                   	push   %ebp
8010523f:	89 e5                	mov    %esp,%ebp
80105241:	83 ec 14             	sub    $0x14,%esp
  consoleintr(uartgetc);
80105244:	68 27 51 10 80       	push   $0x80105127
80105249:	e8 f0 b4 ff ff       	call   8010073e <consoleintr>
}
8010524e:	83 c4 10             	add    $0x10,%esp
80105251:	c9                   	leave  
80105252:	c3                   	ret    

80105253 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80105253:	6a 00                	push   $0x0
  pushl $0
80105255:	6a 00                	push   $0x0
  jmp alltraps
80105257:	e9 be fb ff ff       	jmp    80104e1a <alltraps>

8010525c <vector1>:
.globl vector1
vector1:
  pushl $0
8010525c:	6a 00                	push   $0x0
  pushl $1
8010525e:	6a 01                	push   $0x1
  jmp alltraps
80105260:	e9 b5 fb ff ff       	jmp    80104e1a <alltraps>

80105265 <vector2>:
.globl vector2
vector2:
  pushl $0
80105265:	6a 00                	push   $0x0
  pushl $2
80105267:	6a 02                	push   $0x2
  jmp alltraps
80105269:	e9 ac fb ff ff       	jmp    80104e1a <alltraps>

8010526e <vector3>:
.globl vector3
vector3:
  pushl $0
8010526e:	6a 00                	push   $0x0
  pushl $3
80105270:	6a 03                	push   $0x3
  jmp alltraps
80105272:	e9 a3 fb ff ff       	jmp    80104e1a <alltraps>

80105277 <vector4>:
.globl vector4
vector4:
  pushl $0
80105277:	6a 00                	push   $0x0
  pushl $4
80105279:	6a 04                	push   $0x4
  jmp alltraps
8010527b:	e9 9a fb ff ff       	jmp    80104e1a <alltraps>

80105280 <vector5>:
.globl vector5
vector5:
  pushl $0
80105280:	6a 00                	push   $0x0
  pushl $5
80105282:	6a 05                	push   $0x5
  jmp alltraps
80105284:	e9 91 fb ff ff       	jmp    80104e1a <alltraps>

80105289 <vector6>:
.globl vector6
vector6:
  pushl $0
80105289:	6a 00                	push   $0x0
  pushl $6
8010528b:	6a 06                	push   $0x6
  jmp alltraps
8010528d:	e9 88 fb ff ff       	jmp    80104e1a <alltraps>

80105292 <vector7>:
.globl vector7
vector7:
  pushl $0
80105292:	6a 00                	push   $0x0
  pushl $7
80105294:	6a 07                	push   $0x7
  jmp alltraps
80105296:	e9 7f fb ff ff       	jmp    80104e1a <alltraps>

8010529b <vector8>:
.globl vector8
vector8:
  pushl $8
8010529b:	6a 08                	push   $0x8
  jmp alltraps
8010529d:	e9 78 fb ff ff       	jmp    80104e1a <alltraps>

801052a2 <vector9>:
.globl vector9
vector9:
  pushl $0
801052a2:	6a 00                	push   $0x0
  pushl $9
801052a4:	6a 09                	push   $0x9
  jmp alltraps
801052a6:	e9 6f fb ff ff       	jmp    80104e1a <alltraps>

801052ab <vector10>:
.globl vector10
vector10:
  pushl $10
801052ab:	6a 0a                	push   $0xa
  jmp alltraps
801052ad:	e9 68 fb ff ff       	jmp    80104e1a <alltraps>

801052b2 <vector11>:
.globl vector11
vector11:
  pushl $11
801052b2:	6a 0b                	push   $0xb
  jmp alltraps
801052b4:	e9 61 fb ff ff       	jmp    80104e1a <alltraps>

801052b9 <vector12>:
.globl vector12
vector12:
  pushl $12
801052b9:	6a 0c                	push   $0xc
  jmp alltraps
801052bb:	e9 5a fb ff ff       	jmp    80104e1a <alltraps>

801052c0 <vector13>:
.globl vector13
vector13:
  pushl $13
801052c0:	6a 0d                	push   $0xd
  jmp alltraps
801052c2:	e9 53 fb ff ff       	jmp    80104e1a <alltraps>

801052c7 <vector14>:
.globl vector14
vector14:
  pushl $14
801052c7:	6a 0e                	push   $0xe
  jmp alltraps
801052c9:	e9 4c fb ff ff       	jmp    80104e1a <alltraps>

801052ce <vector15>:
.globl vector15
vector15:
  pushl $0
801052ce:	6a 00                	push   $0x0
  pushl $15
801052d0:	6a 0f                	push   $0xf
  jmp alltraps
801052d2:	e9 43 fb ff ff       	jmp    80104e1a <alltraps>

801052d7 <vector16>:
.globl vector16
vector16:
  pushl $0
801052d7:	6a 00                	push   $0x0
  pushl $16
801052d9:	6a 10                	push   $0x10
  jmp alltraps
801052db:	e9 3a fb ff ff       	jmp    80104e1a <alltraps>

801052e0 <vector17>:
.globl vector17
vector17:
  pushl $17
801052e0:	6a 11                	push   $0x11
  jmp alltraps
801052e2:	e9 33 fb ff ff       	jmp    80104e1a <alltraps>

801052e7 <vector18>:
.globl vector18
vector18:
  pushl $0
801052e7:	6a 00                	push   $0x0
  pushl $18
801052e9:	6a 12                	push   $0x12
  jmp alltraps
801052eb:	e9 2a fb ff ff       	jmp    80104e1a <alltraps>

801052f0 <vector19>:
.globl vector19
vector19:
  pushl $0
801052f0:	6a 00                	push   $0x0
  pushl $19
801052f2:	6a 13                	push   $0x13
  jmp alltraps
801052f4:	e9 21 fb ff ff       	jmp    80104e1a <alltraps>

801052f9 <vector20>:
.globl vector20
vector20:
  pushl $0
801052f9:	6a 00                	push   $0x0
  pushl $20
801052fb:	6a 14                	push   $0x14
  jmp alltraps
801052fd:	e9 18 fb ff ff       	jmp    80104e1a <alltraps>

80105302 <vector21>:
.globl vector21
vector21:
  pushl $0
80105302:	6a 00                	push   $0x0
  pushl $21
80105304:	6a 15                	push   $0x15
  jmp alltraps
80105306:	e9 0f fb ff ff       	jmp    80104e1a <alltraps>

8010530b <vector22>:
.globl vector22
vector22:
  pushl $0
8010530b:	6a 00                	push   $0x0
  pushl $22
8010530d:	6a 16                	push   $0x16
  jmp alltraps
8010530f:	e9 06 fb ff ff       	jmp    80104e1a <alltraps>

80105314 <vector23>:
.globl vector23
vector23:
  pushl $0
80105314:	6a 00                	push   $0x0
  pushl $23
80105316:	6a 17                	push   $0x17
  jmp alltraps
80105318:	e9 fd fa ff ff       	jmp    80104e1a <alltraps>

8010531d <vector24>:
.globl vector24
vector24:
  pushl $0
8010531d:	6a 00                	push   $0x0
  pushl $24
8010531f:	6a 18                	push   $0x18
  jmp alltraps
80105321:	e9 f4 fa ff ff       	jmp    80104e1a <alltraps>

80105326 <vector25>:
.globl vector25
vector25:
  pushl $0
80105326:	6a 00                	push   $0x0
  pushl $25
80105328:	6a 19                	push   $0x19
  jmp alltraps
8010532a:	e9 eb fa ff ff       	jmp    80104e1a <alltraps>

8010532f <vector26>:
.globl vector26
vector26:
  pushl $0
8010532f:	6a 00                	push   $0x0
  pushl $26
80105331:	6a 1a                	push   $0x1a
  jmp alltraps
80105333:	e9 e2 fa ff ff       	jmp    80104e1a <alltraps>

80105338 <vector27>:
.globl vector27
vector27:
  pushl $0
80105338:	6a 00                	push   $0x0
  pushl $27
8010533a:	6a 1b                	push   $0x1b
  jmp alltraps
8010533c:	e9 d9 fa ff ff       	jmp    80104e1a <alltraps>

80105341 <vector28>:
.globl vector28
vector28:
  pushl $0
80105341:	6a 00                	push   $0x0
  pushl $28
80105343:	6a 1c                	push   $0x1c
  jmp alltraps
80105345:	e9 d0 fa ff ff       	jmp    80104e1a <alltraps>

8010534a <vector29>:
.globl vector29
vector29:
  pushl $0
8010534a:	6a 00                	push   $0x0
  pushl $29
8010534c:	6a 1d                	push   $0x1d
  jmp alltraps
8010534e:	e9 c7 fa ff ff       	jmp    80104e1a <alltraps>

80105353 <vector30>:
.globl vector30
vector30:
  pushl $0
80105353:	6a 00                	push   $0x0
  pushl $30
80105355:	6a 1e                	push   $0x1e
  jmp alltraps
80105357:	e9 be fa ff ff       	jmp    80104e1a <alltraps>

8010535c <vector31>:
.globl vector31
vector31:
  pushl $0
8010535c:	6a 00                	push   $0x0
  pushl $31
8010535e:	6a 1f                	push   $0x1f
  jmp alltraps
80105360:	e9 b5 fa ff ff       	jmp    80104e1a <alltraps>

80105365 <vector32>:
.globl vector32
vector32:
  pushl $0
80105365:	6a 00                	push   $0x0
  pushl $32
80105367:	6a 20                	push   $0x20
  jmp alltraps
80105369:	e9 ac fa ff ff       	jmp    80104e1a <alltraps>

8010536e <vector33>:
.globl vector33
vector33:
  pushl $0
8010536e:	6a 00                	push   $0x0
  pushl $33
80105370:	6a 21                	push   $0x21
  jmp alltraps
80105372:	e9 a3 fa ff ff       	jmp    80104e1a <alltraps>

80105377 <vector34>:
.globl vector34
vector34:
  pushl $0
80105377:	6a 00                	push   $0x0
  pushl $34
80105379:	6a 22                	push   $0x22
  jmp alltraps
8010537b:	e9 9a fa ff ff       	jmp    80104e1a <alltraps>

80105380 <vector35>:
.globl vector35
vector35:
  pushl $0
80105380:	6a 00                	push   $0x0
  pushl $35
80105382:	6a 23                	push   $0x23
  jmp alltraps
80105384:	e9 91 fa ff ff       	jmp    80104e1a <alltraps>

80105389 <vector36>:
.globl vector36
vector36:
  pushl $0
80105389:	6a 00                	push   $0x0
  pushl $36
8010538b:	6a 24                	push   $0x24
  jmp alltraps
8010538d:	e9 88 fa ff ff       	jmp    80104e1a <alltraps>

80105392 <vector37>:
.globl vector37
vector37:
  pushl $0
80105392:	6a 00                	push   $0x0
  pushl $37
80105394:	6a 25                	push   $0x25
  jmp alltraps
80105396:	e9 7f fa ff ff       	jmp    80104e1a <alltraps>

8010539b <vector38>:
.globl vector38
vector38:
  pushl $0
8010539b:	6a 00                	push   $0x0
  pushl $38
8010539d:	6a 26                	push   $0x26
  jmp alltraps
8010539f:	e9 76 fa ff ff       	jmp    80104e1a <alltraps>

801053a4 <vector39>:
.globl vector39
vector39:
  pushl $0
801053a4:	6a 00                	push   $0x0
  pushl $39
801053a6:	6a 27                	push   $0x27
  jmp alltraps
801053a8:	e9 6d fa ff ff       	jmp    80104e1a <alltraps>

801053ad <vector40>:
.globl vector40
vector40:
  pushl $0
801053ad:	6a 00                	push   $0x0
  pushl $40
801053af:	6a 28                	push   $0x28
  jmp alltraps
801053b1:	e9 64 fa ff ff       	jmp    80104e1a <alltraps>

801053b6 <vector41>:
.globl vector41
vector41:
  pushl $0
801053b6:	6a 00                	push   $0x0
  pushl $41
801053b8:	6a 29                	push   $0x29
  jmp alltraps
801053ba:	e9 5b fa ff ff       	jmp    80104e1a <alltraps>

801053bf <vector42>:
.globl vector42
vector42:
  pushl $0
801053bf:	6a 00                	push   $0x0
  pushl $42
801053c1:	6a 2a                	push   $0x2a
  jmp alltraps
801053c3:	e9 52 fa ff ff       	jmp    80104e1a <alltraps>

801053c8 <vector43>:
.globl vector43
vector43:
  pushl $0
801053c8:	6a 00                	push   $0x0
  pushl $43
801053ca:	6a 2b                	push   $0x2b
  jmp alltraps
801053cc:	e9 49 fa ff ff       	jmp    80104e1a <alltraps>

801053d1 <vector44>:
.globl vector44
vector44:
  pushl $0
801053d1:	6a 00                	push   $0x0
  pushl $44
801053d3:	6a 2c                	push   $0x2c
  jmp alltraps
801053d5:	e9 40 fa ff ff       	jmp    80104e1a <alltraps>

801053da <vector45>:
.globl vector45
vector45:
  pushl $0
801053da:	6a 00                	push   $0x0
  pushl $45
801053dc:	6a 2d                	push   $0x2d
  jmp alltraps
801053de:	e9 37 fa ff ff       	jmp    80104e1a <alltraps>

801053e3 <vector46>:
.globl vector46
vector46:
  pushl $0
801053e3:	6a 00                	push   $0x0
  pushl $46
801053e5:	6a 2e                	push   $0x2e
  jmp alltraps
801053e7:	e9 2e fa ff ff       	jmp    80104e1a <alltraps>

801053ec <vector47>:
.globl vector47
vector47:
  pushl $0
801053ec:	6a 00                	push   $0x0
  pushl $47
801053ee:	6a 2f                	push   $0x2f
  jmp alltraps
801053f0:	e9 25 fa ff ff       	jmp    80104e1a <alltraps>

801053f5 <vector48>:
.globl vector48
vector48:
  pushl $0
801053f5:	6a 00                	push   $0x0
  pushl $48
801053f7:	6a 30                	push   $0x30
  jmp alltraps
801053f9:	e9 1c fa ff ff       	jmp    80104e1a <alltraps>

801053fe <vector49>:
.globl vector49
vector49:
  pushl $0
801053fe:	6a 00                	push   $0x0
  pushl $49
80105400:	6a 31                	push   $0x31
  jmp alltraps
80105402:	e9 13 fa ff ff       	jmp    80104e1a <alltraps>

80105407 <vector50>:
.globl vector50
vector50:
  pushl $0
80105407:	6a 00                	push   $0x0
  pushl $50
80105409:	6a 32                	push   $0x32
  jmp alltraps
8010540b:	e9 0a fa ff ff       	jmp    80104e1a <alltraps>

80105410 <vector51>:
.globl vector51
vector51:
  pushl $0
80105410:	6a 00                	push   $0x0
  pushl $51
80105412:	6a 33                	push   $0x33
  jmp alltraps
80105414:	e9 01 fa ff ff       	jmp    80104e1a <alltraps>

80105419 <vector52>:
.globl vector52
vector52:
  pushl $0
80105419:	6a 00                	push   $0x0
  pushl $52
8010541b:	6a 34                	push   $0x34
  jmp alltraps
8010541d:	e9 f8 f9 ff ff       	jmp    80104e1a <alltraps>

80105422 <vector53>:
.globl vector53
vector53:
  pushl $0
80105422:	6a 00                	push   $0x0
  pushl $53
80105424:	6a 35                	push   $0x35
  jmp alltraps
80105426:	e9 ef f9 ff ff       	jmp    80104e1a <alltraps>

8010542b <vector54>:
.globl vector54
vector54:
  pushl $0
8010542b:	6a 00                	push   $0x0
  pushl $54
8010542d:	6a 36                	push   $0x36
  jmp alltraps
8010542f:	e9 e6 f9 ff ff       	jmp    80104e1a <alltraps>

80105434 <vector55>:
.globl vector55
vector55:
  pushl $0
80105434:	6a 00                	push   $0x0
  pushl $55
80105436:	6a 37                	push   $0x37
  jmp alltraps
80105438:	e9 dd f9 ff ff       	jmp    80104e1a <alltraps>

8010543d <vector56>:
.globl vector56
vector56:
  pushl $0
8010543d:	6a 00                	push   $0x0
  pushl $56
8010543f:	6a 38                	push   $0x38
  jmp alltraps
80105441:	e9 d4 f9 ff ff       	jmp    80104e1a <alltraps>

80105446 <vector57>:
.globl vector57
vector57:
  pushl $0
80105446:	6a 00                	push   $0x0
  pushl $57
80105448:	6a 39                	push   $0x39
  jmp alltraps
8010544a:	e9 cb f9 ff ff       	jmp    80104e1a <alltraps>

8010544f <vector58>:
.globl vector58
vector58:
  pushl $0
8010544f:	6a 00                	push   $0x0
  pushl $58
80105451:	6a 3a                	push   $0x3a
  jmp alltraps
80105453:	e9 c2 f9 ff ff       	jmp    80104e1a <alltraps>

80105458 <vector59>:
.globl vector59
vector59:
  pushl $0
80105458:	6a 00                	push   $0x0
  pushl $59
8010545a:	6a 3b                	push   $0x3b
  jmp alltraps
8010545c:	e9 b9 f9 ff ff       	jmp    80104e1a <alltraps>

80105461 <vector60>:
.globl vector60
vector60:
  pushl $0
80105461:	6a 00                	push   $0x0
  pushl $60
80105463:	6a 3c                	push   $0x3c
  jmp alltraps
80105465:	e9 b0 f9 ff ff       	jmp    80104e1a <alltraps>

8010546a <vector61>:
.globl vector61
vector61:
  pushl $0
8010546a:	6a 00                	push   $0x0
  pushl $61
8010546c:	6a 3d                	push   $0x3d
  jmp alltraps
8010546e:	e9 a7 f9 ff ff       	jmp    80104e1a <alltraps>

80105473 <vector62>:
.globl vector62
vector62:
  pushl $0
80105473:	6a 00                	push   $0x0
  pushl $62
80105475:	6a 3e                	push   $0x3e
  jmp alltraps
80105477:	e9 9e f9 ff ff       	jmp    80104e1a <alltraps>

8010547c <vector63>:
.globl vector63
vector63:
  pushl $0
8010547c:	6a 00                	push   $0x0
  pushl $63
8010547e:	6a 3f                	push   $0x3f
  jmp alltraps
80105480:	e9 95 f9 ff ff       	jmp    80104e1a <alltraps>

80105485 <vector64>:
.globl vector64
vector64:
  pushl $0
80105485:	6a 00                	push   $0x0
  pushl $64
80105487:	6a 40                	push   $0x40
  jmp alltraps
80105489:	e9 8c f9 ff ff       	jmp    80104e1a <alltraps>

8010548e <vector65>:
.globl vector65
vector65:
  pushl $0
8010548e:	6a 00                	push   $0x0
  pushl $65
80105490:	6a 41                	push   $0x41
  jmp alltraps
80105492:	e9 83 f9 ff ff       	jmp    80104e1a <alltraps>

80105497 <vector66>:
.globl vector66
vector66:
  pushl $0
80105497:	6a 00                	push   $0x0
  pushl $66
80105499:	6a 42                	push   $0x42
  jmp alltraps
8010549b:	e9 7a f9 ff ff       	jmp    80104e1a <alltraps>

801054a0 <vector67>:
.globl vector67
vector67:
  pushl $0
801054a0:	6a 00                	push   $0x0
  pushl $67
801054a2:	6a 43                	push   $0x43
  jmp alltraps
801054a4:	e9 71 f9 ff ff       	jmp    80104e1a <alltraps>

801054a9 <vector68>:
.globl vector68
vector68:
  pushl $0
801054a9:	6a 00                	push   $0x0
  pushl $68
801054ab:	6a 44                	push   $0x44
  jmp alltraps
801054ad:	e9 68 f9 ff ff       	jmp    80104e1a <alltraps>

801054b2 <vector69>:
.globl vector69
vector69:
  pushl $0
801054b2:	6a 00                	push   $0x0
  pushl $69
801054b4:	6a 45                	push   $0x45
  jmp alltraps
801054b6:	e9 5f f9 ff ff       	jmp    80104e1a <alltraps>

801054bb <vector70>:
.globl vector70
vector70:
  pushl $0
801054bb:	6a 00                	push   $0x0
  pushl $70
801054bd:	6a 46                	push   $0x46
  jmp alltraps
801054bf:	e9 56 f9 ff ff       	jmp    80104e1a <alltraps>

801054c4 <vector71>:
.globl vector71
vector71:
  pushl $0
801054c4:	6a 00                	push   $0x0
  pushl $71
801054c6:	6a 47                	push   $0x47
  jmp alltraps
801054c8:	e9 4d f9 ff ff       	jmp    80104e1a <alltraps>

801054cd <vector72>:
.globl vector72
vector72:
  pushl $0
801054cd:	6a 00                	push   $0x0
  pushl $72
801054cf:	6a 48                	push   $0x48
  jmp alltraps
801054d1:	e9 44 f9 ff ff       	jmp    80104e1a <alltraps>

801054d6 <vector73>:
.globl vector73
vector73:
  pushl $0
801054d6:	6a 00                	push   $0x0
  pushl $73
801054d8:	6a 49                	push   $0x49
  jmp alltraps
801054da:	e9 3b f9 ff ff       	jmp    80104e1a <alltraps>

801054df <vector74>:
.globl vector74
vector74:
  pushl $0
801054df:	6a 00                	push   $0x0
  pushl $74
801054e1:	6a 4a                	push   $0x4a
  jmp alltraps
801054e3:	e9 32 f9 ff ff       	jmp    80104e1a <alltraps>

801054e8 <vector75>:
.globl vector75
vector75:
  pushl $0
801054e8:	6a 00                	push   $0x0
  pushl $75
801054ea:	6a 4b                	push   $0x4b
  jmp alltraps
801054ec:	e9 29 f9 ff ff       	jmp    80104e1a <alltraps>

801054f1 <vector76>:
.globl vector76
vector76:
  pushl $0
801054f1:	6a 00                	push   $0x0
  pushl $76
801054f3:	6a 4c                	push   $0x4c
  jmp alltraps
801054f5:	e9 20 f9 ff ff       	jmp    80104e1a <alltraps>

801054fa <vector77>:
.globl vector77
vector77:
  pushl $0
801054fa:	6a 00                	push   $0x0
  pushl $77
801054fc:	6a 4d                	push   $0x4d
  jmp alltraps
801054fe:	e9 17 f9 ff ff       	jmp    80104e1a <alltraps>

80105503 <vector78>:
.globl vector78
vector78:
  pushl $0
80105503:	6a 00                	push   $0x0
  pushl $78
80105505:	6a 4e                	push   $0x4e
  jmp alltraps
80105507:	e9 0e f9 ff ff       	jmp    80104e1a <alltraps>

8010550c <vector79>:
.globl vector79
vector79:
  pushl $0
8010550c:	6a 00                	push   $0x0
  pushl $79
8010550e:	6a 4f                	push   $0x4f
  jmp alltraps
80105510:	e9 05 f9 ff ff       	jmp    80104e1a <alltraps>

80105515 <vector80>:
.globl vector80
vector80:
  pushl $0
80105515:	6a 00                	push   $0x0
  pushl $80
80105517:	6a 50                	push   $0x50
  jmp alltraps
80105519:	e9 fc f8 ff ff       	jmp    80104e1a <alltraps>

8010551e <vector81>:
.globl vector81
vector81:
  pushl $0
8010551e:	6a 00                	push   $0x0
  pushl $81
80105520:	6a 51                	push   $0x51
  jmp alltraps
80105522:	e9 f3 f8 ff ff       	jmp    80104e1a <alltraps>

80105527 <vector82>:
.globl vector82
vector82:
  pushl $0
80105527:	6a 00                	push   $0x0
  pushl $82
80105529:	6a 52                	push   $0x52
  jmp alltraps
8010552b:	e9 ea f8 ff ff       	jmp    80104e1a <alltraps>

80105530 <vector83>:
.globl vector83
vector83:
  pushl $0
80105530:	6a 00                	push   $0x0
  pushl $83
80105532:	6a 53                	push   $0x53
  jmp alltraps
80105534:	e9 e1 f8 ff ff       	jmp    80104e1a <alltraps>

80105539 <vector84>:
.globl vector84
vector84:
  pushl $0
80105539:	6a 00                	push   $0x0
  pushl $84
8010553b:	6a 54                	push   $0x54
  jmp alltraps
8010553d:	e9 d8 f8 ff ff       	jmp    80104e1a <alltraps>

80105542 <vector85>:
.globl vector85
vector85:
  pushl $0
80105542:	6a 00                	push   $0x0
  pushl $85
80105544:	6a 55                	push   $0x55
  jmp alltraps
80105546:	e9 cf f8 ff ff       	jmp    80104e1a <alltraps>

8010554b <vector86>:
.globl vector86
vector86:
  pushl $0
8010554b:	6a 00                	push   $0x0
  pushl $86
8010554d:	6a 56                	push   $0x56
  jmp alltraps
8010554f:	e9 c6 f8 ff ff       	jmp    80104e1a <alltraps>

80105554 <vector87>:
.globl vector87
vector87:
  pushl $0
80105554:	6a 00                	push   $0x0
  pushl $87
80105556:	6a 57                	push   $0x57
  jmp alltraps
80105558:	e9 bd f8 ff ff       	jmp    80104e1a <alltraps>

8010555d <vector88>:
.globl vector88
vector88:
  pushl $0
8010555d:	6a 00                	push   $0x0
  pushl $88
8010555f:	6a 58                	push   $0x58
  jmp alltraps
80105561:	e9 b4 f8 ff ff       	jmp    80104e1a <alltraps>

80105566 <vector89>:
.globl vector89
vector89:
  pushl $0
80105566:	6a 00                	push   $0x0
  pushl $89
80105568:	6a 59                	push   $0x59
  jmp alltraps
8010556a:	e9 ab f8 ff ff       	jmp    80104e1a <alltraps>

8010556f <vector90>:
.globl vector90
vector90:
  pushl $0
8010556f:	6a 00                	push   $0x0
  pushl $90
80105571:	6a 5a                	push   $0x5a
  jmp alltraps
80105573:	e9 a2 f8 ff ff       	jmp    80104e1a <alltraps>

80105578 <vector91>:
.globl vector91
vector91:
  pushl $0
80105578:	6a 00                	push   $0x0
  pushl $91
8010557a:	6a 5b                	push   $0x5b
  jmp alltraps
8010557c:	e9 99 f8 ff ff       	jmp    80104e1a <alltraps>

80105581 <vector92>:
.globl vector92
vector92:
  pushl $0
80105581:	6a 00                	push   $0x0
  pushl $92
80105583:	6a 5c                	push   $0x5c
  jmp alltraps
80105585:	e9 90 f8 ff ff       	jmp    80104e1a <alltraps>

8010558a <vector93>:
.globl vector93
vector93:
  pushl $0
8010558a:	6a 00                	push   $0x0
  pushl $93
8010558c:	6a 5d                	push   $0x5d
  jmp alltraps
8010558e:	e9 87 f8 ff ff       	jmp    80104e1a <alltraps>

80105593 <vector94>:
.globl vector94
vector94:
  pushl $0
80105593:	6a 00                	push   $0x0
  pushl $94
80105595:	6a 5e                	push   $0x5e
  jmp alltraps
80105597:	e9 7e f8 ff ff       	jmp    80104e1a <alltraps>

8010559c <vector95>:
.globl vector95
vector95:
  pushl $0
8010559c:	6a 00                	push   $0x0
  pushl $95
8010559e:	6a 5f                	push   $0x5f
  jmp alltraps
801055a0:	e9 75 f8 ff ff       	jmp    80104e1a <alltraps>

801055a5 <vector96>:
.globl vector96
vector96:
  pushl $0
801055a5:	6a 00                	push   $0x0
  pushl $96
801055a7:	6a 60                	push   $0x60
  jmp alltraps
801055a9:	e9 6c f8 ff ff       	jmp    80104e1a <alltraps>

801055ae <vector97>:
.globl vector97
vector97:
  pushl $0
801055ae:	6a 00                	push   $0x0
  pushl $97
801055b0:	6a 61                	push   $0x61
  jmp alltraps
801055b2:	e9 63 f8 ff ff       	jmp    80104e1a <alltraps>

801055b7 <vector98>:
.globl vector98
vector98:
  pushl $0
801055b7:	6a 00                	push   $0x0
  pushl $98
801055b9:	6a 62                	push   $0x62
  jmp alltraps
801055bb:	e9 5a f8 ff ff       	jmp    80104e1a <alltraps>

801055c0 <vector99>:
.globl vector99
vector99:
  pushl $0
801055c0:	6a 00                	push   $0x0
  pushl $99
801055c2:	6a 63                	push   $0x63
  jmp alltraps
801055c4:	e9 51 f8 ff ff       	jmp    80104e1a <alltraps>

801055c9 <vector100>:
.globl vector100
vector100:
  pushl $0
801055c9:	6a 00                	push   $0x0
  pushl $100
801055cb:	6a 64                	push   $0x64
  jmp alltraps
801055cd:	e9 48 f8 ff ff       	jmp    80104e1a <alltraps>

801055d2 <vector101>:
.globl vector101
vector101:
  pushl $0
801055d2:	6a 00                	push   $0x0
  pushl $101
801055d4:	6a 65                	push   $0x65
  jmp alltraps
801055d6:	e9 3f f8 ff ff       	jmp    80104e1a <alltraps>

801055db <vector102>:
.globl vector102
vector102:
  pushl $0
801055db:	6a 00                	push   $0x0
  pushl $102
801055dd:	6a 66                	push   $0x66
  jmp alltraps
801055df:	e9 36 f8 ff ff       	jmp    80104e1a <alltraps>

801055e4 <vector103>:
.globl vector103
vector103:
  pushl $0
801055e4:	6a 00                	push   $0x0
  pushl $103
801055e6:	6a 67                	push   $0x67
  jmp alltraps
801055e8:	e9 2d f8 ff ff       	jmp    80104e1a <alltraps>

801055ed <vector104>:
.globl vector104
vector104:
  pushl $0
801055ed:	6a 00                	push   $0x0
  pushl $104
801055ef:	6a 68                	push   $0x68
  jmp alltraps
801055f1:	e9 24 f8 ff ff       	jmp    80104e1a <alltraps>

801055f6 <vector105>:
.globl vector105
vector105:
  pushl $0
801055f6:	6a 00                	push   $0x0
  pushl $105
801055f8:	6a 69                	push   $0x69
  jmp alltraps
801055fa:	e9 1b f8 ff ff       	jmp    80104e1a <alltraps>

801055ff <vector106>:
.globl vector106
vector106:
  pushl $0
801055ff:	6a 00                	push   $0x0
  pushl $106
80105601:	6a 6a                	push   $0x6a
  jmp alltraps
80105603:	e9 12 f8 ff ff       	jmp    80104e1a <alltraps>

80105608 <vector107>:
.globl vector107
vector107:
  pushl $0
80105608:	6a 00                	push   $0x0
  pushl $107
8010560a:	6a 6b                	push   $0x6b
  jmp alltraps
8010560c:	e9 09 f8 ff ff       	jmp    80104e1a <alltraps>

80105611 <vector108>:
.globl vector108
vector108:
  pushl $0
80105611:	6a 00                	push   $0x0
  pushl $108
80105613:	6a 6c                	push   $0x6c
  jmp alltraps
80105615:	e9 00 f8 ff ff       	jmp    80104e1a <alltraps>

8010561a <vector109>:
.globl vector109
vector109:
  pushl $0
8010561a:	6a 00                	push   $0x0
  pushl $109
8010561c:	6a 6d                	push   $0x6d
  jmp alltraps
8010561e:	e9 f7 f7 ff ff       	jmp    80104e1a <alltraps>

80105623 <vector110>:
.globl vector110
vector110:
  pushl $0
80105623:	6a 00                	push   $0x0
  pushl $110
80105625:	6a 6e                	push   $0x6e
  jmp alltraps
80105627:	e9 ee f7 ff ff       	jmp    80104e1a <alltraps>

8010562c <vector111>:
.globl vector111
vector111:
  pushl $0
8010562c:	6a 00                	push   $0x0
  pushl $111
8010562e:	6a 6f                	push   $0x6f
  jmp alltraps
80105630:	e9 e5 f7 ff ff       	jmp    80104e1a <alltraps>

80105635 <vector112>:
.globl vector112
vector112:
  pushl $0
80105635:	6a 00                	push   $0x0
  pushl $112
80105637:	6a 70                	push   $0x70
  jmp alltraps
80105639:	e9 dc f7 ff ff       	jmp    80104e1a <alltraps>

8010563e <vector113>:
.globl vector113
vector113:
  pushl $0
8010563e:	6a 00                	push   $0x0
  pushl $113
80105640:	6a 71                	push   $0x71
  jmp alltraps
80105642:	e9 d3 f7 ff ff       	jmp    80104e1a <alltraps>

80105647 <vector114>:
.globl vector114
vector114:
  pushl $0
80105647:	6a 00                	push   $0x0
  pushl $114
80105649:	6a 72                	push   $0x72
  jmp alltraps
8010564b:	e9 ca f7 ff ff       	jmp    80104e1a <alltraps>

80105650 <vector115>:
.globl vector115
vector115:
  pushl $0
80105650:	6a 00                	push   $0x0
  pushl $115
80105652:	6a 73                	push   $0x73
  jmp alltraps
80105654:	e9 c1 f7 ff ff       	jmp    80104e1a <alltraps>

80105659 <vector116>:
.globl vector116
vector116:
  pushl $0
80105659:	6a 00                	push   $0x0
  pushl $116
8010565b:	6a 74                	push   $0x74
  jmp alltraps
8010565d:	e9 b8 f7 ff ff       	jmp    80104e1a <alltraps>

80105662 <vector117>:
.globl vector117
vector117:
  pushl $0
80105662:	6a 00                	push   $0x0
  pushl $117
80105664:	6a 75                	push   $0x75
  jmp alltraps
80105666:	e9 af f7 ff ff       	jmp    80104e1a <alltraps>

8010566b <vector118>:
.globl vector118
vector118:
  pushl $0
8010566b:	6a 00                	push   $0x0
  pushl $118
8010566d:	6a 76                	push   $0x76
  jmp alltraps
8010566f:	e9 a6 f7 ff ff       	jmp    80104e1a <alltraps>

80105674 <vector119>:
.globl vector119
vector119:
  pushl $0
80105674:	6a 00                	push   $0x0
  pushl $119
80105676:	6a 77                	push   $0x77
  jmp alltraps
80105678:	e9 9d f7 ff ff       	jmp    80104e1a <alltraps>

8010567d <vector120>:
.globl vector120
vector120:
  pushl $0
8010567d:	6a 00                	push   $0x0
  pushl $120
8010567f:	6a 78                	push   $0x78
  jmp alltraps
80105681:	e9 94 f7 ff ff       	jmp    80104e1a <alltraps>

80105686 <vector121>:
.globl vector121
vector121:
  pushl $0
80105686:	6a 00                	push   $0x0
  pushl $121
80105688:	6a 79                	push   $0x79
  jmp alltraps
8010568a:	e9 8b f7 ff ff       	jmp    80104e1a <alltraps>

8010568f <vector122>:
.globl vector122
vector122:
  pushl $0
8010568f:	6a 00                	push   $0x0
  pushl $122
80105691:	6a 7a                	push   $0x7a
  jmp alltraps
80105693:	e9 82 f7 ff ff       	jmp    80104e1a <alltraps>

80105698 <vector123>:
.globl vector123
vector123:
  pushl $0
80105698:	6a 00                	push   $0x0
  pushl $123
8010569a:	6a 7b                	push   $0x7b
  jmp alltraps
8010569c:	e9 79 f7 ff ff       	jmp    80104e1a <alltraps>

801056a1 <vector124>:
.globl vector124
vector124:
  pushl $0
801056a1:	6a 00                	push   $0x0
  pushl $124
801056a3:	6a 7c                	push   $0x7c
  jmp alltraps
801056a5:	e9 70 f7 ff ff       	jmp    80104e1a <alltraps>

801056aa <vector125>:
.globl vector125
vector125:
  pushl $0
801056aa:	6a 00                	push   $0x0
  pushl $125
801056ac:	6a 7d                	push   $0x7d
  jmp alltraps
801056ae:	e9 67 f7 ff ff       	jmp    80104e1a <alltraps>

801056b3 <vector126>:
.globl vector126
vector126:
  pushl $0
801056b3:	6a 00                	push   $0x0
  pushl $126
801056b5:	6a 7e                	push   $0x7e
  jmp alltraps
801056b7:	e9 5e f7 ff ff       	jmp    80104e1a <alltraps>

801056bc <vector127>:
.globl vector127
vector127:
  pushl $0
801056bc:	6a 00                	push   $0x0
  pushl $127
801056be:	6a 7f                	push   $0x7f
  jmp alltraps
801056c0:	e9 55 f7 ff ff       	jmp    80104e1a <alltraps>

801056c5 <vector128>:
.globl vector128
vector128:
  pushl $0
801056c5:	6a 00                	push   $0x0
  pushl $128
801056c7:	68 80 00 00 00       	push   $0x80
  jmp alltraps
801056cc:	e9 49 f7 ff ff       	jmp    80104e1a <alltraps>

801056d1 <vector129>:
.globl vector129
vector129:
  pushl $0
801056d1:	6a 00                	push   $0x0
  pushl $129
801056d3:	68 81 00 00 00       	push   $0x81
  jmp alltraps
801056d8:	e9 3d f7 ff ff       	jmp    80104e1a <alltraps>

801056dd <vector130>:
.globl vector130
vector130:
  pushl $0
801056dd:	6a 00                	push   $0x0
  pushl $130
801056df:	68 82 00 00 00       	push   $0x82
  jmp alltraps
801056e4:	e9 31 f7 ff ff       	jmp    80104e1a <alltraps>

801056e9 <vector131>:
.globl vector131
vector131:
  pushl $0
801056e9:	6a 00                	push   $0x0
  pushl $131
801056eb:	68 83 00 00 00       	push   $0x83
  jmp alltraps
801056f0:	e9 25 f7 ff ff       	jmp    80104e1a <alltraps>

801056f5 <vector132>:
.globl vector132
vector132:
  pushl $0
801056f5:	6a 00                	push   $0x0
  pushl $132
801056f7:	68 84 00 00 00       	push   $0x84
  jmp alltraps
801056fc:	e9 19 f7 ff ff       	jmp    80104e1a <alltraps>

80105701 <vector133>:
.globl vector133
vector133:
  pushl $0
80105701:	6a 00                	push   $0x0
  pushl $133
80105703:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80105708:	e9 0d f7 ff ff       	jmp    80104e1a <alltraps>

8010570d <vector134>:
.globl vector134
vector134:
  pushl $0
8010570d:	6a 00                	push   $0x0
  pushl $134
8010570f:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80105714:	e9 01 f7 ff ff       	jmp    80104e1a <alltraps>

80105719 <vector135>:
.globl vector135
vector135:
  pushl $0
80105719:	6a 00                	push   $0x0
  pushl $135
8010571b:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80105720:	e9 f5 f6 ff ff       	jmp    80104e1a <alltraps>

80105725 <vector136>:
.globl vector136
vector136:
  pushl $0
80105725:	6a 00                	push   $0x0
  pushl $136
80105727:	68 88 00 00 00       	push   $0x88
  jmp alltraps
8010572c:	e9 e9 f6 ff ff       	jmp    80104e1a <alltraps>

80105731 <vector137>:
.globl vector137
vector137:
  pushl $0
80105731:	6a 00                	push   $0x0
  pushl $137
80105733:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80105738:	e9 dd f6 ff ff       	jmp    80104e1a <alltraps>

8010573d <vector138>:
.globl vector138
vector138:
  pushl $0
8010573d:	6a 00                	push   $0x0
  pushl $138
8010573f:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80105744:	e9 d1 f6 ff ff       	jmp    80104e1a <alltraps>

80105749 <vector139>:
.globl vector139
vector139:
  pushl $0
80105749:	6a 00                	push   $0x0
  pushl $139
8010574b:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80105750:	e9 c5 f6 ff ff       	jmp    80104e1a <alltraps>

80105755 <vector140>:
.globl vector140
vector140:
  pushl $0
80105755:	6a 00                	push   $0x0
  pushl $140
80105757:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
8010575c:	e9 b9 f6 ff ff       	jmp    80104e1a <alltraps>

80105761 <vector141>:
.globl vector141
vector141:
  pushl $0
80105761:	6a 00                	push   $0x0
  pushl $141
80105763:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80105768:	e9 ad f6 ff ff       	jmp    80104e1a <alltraps>

8010576d <vector142>:
.globl vector142
vector142:
  pushl $0
8010576d:	6a 00                	push   $0x0
  pushl $142
8010576f:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80105774:	e9 a1 f6 ff ff       	jmp    80104e1a <alltraps>

80105779 <vector143>:
.globl vector143
vector143:
  pushl $0
80105779:	6a 00                	push   $0x0
  pushl $143
8010577b:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80105780:	e9 95 f6 ff ff       	jmp    80104e1a <alltraps>

80105785 <vector144>:
.globl vector144
vector144:
  pushl $0
80105785:	6a 00                	push   $0x0
  pushl $144
80105787:	68 90 00 00 00       	push   $0x90
  jmp alltraps
8010578c:	e9 89 f6 ff ff       	jmp    80104e1a <alltraps>

80105791 <vector145>:
.globl vector145
vector145:
  pushl $0
80105791:	6a 00                	push   $0x0
  pushl $145
80105793:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80105798:	e9 7d f6 ff ff       	jmp    80104e1a <alltraps>

8010579d <vector146>:
.globl vector146
vector146:
  pushl $0
8010579d:	6a 00                	push   $0x0
  pushl $146
8010579f:	68 92 00 00 00       	push   $0x92
  jmp alltraps
801057a4:	e9 71 f6 ff ff       	jmp    80104e1a <alltraps>

801057a9 <vector147>:
.globl vector147
vector147:
  pushl $0
801057a9:	6a 00                	push   $0x0
  pushl $147
801057ab:	68 93 00 00 00       	push   $0x93
  jmp alltraps
801057b0:	e9 65 f6 ff ff       	jmp    80104e1a <alltraps>

801057b5 <vector148>:
.globl vector148
vector148:
  pushl $0
801057b5:	6a 00                	push   $0x0
  pushl $148
801057b7:	68 94 00 00 00       	push   $0x94
  jmp alltraps
801057bc:	e9 59 f6 ff ff       	jmp    80104e1a <alltraps>

801057c1 <vector149>:
.globl vector149
vector149:
  pushl $0
801057c1:	6a 00                	push   $0x0
  pushl $149
801057c3:	68 95 00 00 00       	push   $0x95
  jmp alltraps
801057c8:	e9 4d f6 ff ff       	jmp    80104e1a <alltraps>

801057cd <vector150>:
.globl vector150
vector150:
  pushl $0
801057cd:	6a 00                	push   $0x0
  pushl $150
801057cf:	68 96 00 00 00       	push   $0x96
  jmp alltraps
801057d4:	e9 41 f6 ff ff       	jmp    80104e1a <alltraps>

801057d9 <vector151>:
.globl vector151
vector151:
  pushl $0
801057d9:	6a 00                	push   $0x0
  pushl $151
801057db:	68 97 00 00 00       	push   $0x97
  jmp alltraps
801057e0:	e9 35 f6 ff ff       	jmp    80104e1a <alltraps>

801057e5 <vector152>:
.globl vector152
vector152:
  pushl $0
801057e5:	6a 00                	push   $0x0
  pushl $152
801057e7:	68 98 00 00 00       	push   $0x98
  jmp alltraps
801057ec:	e9 29 f6 ff ff       	jmp    80104e1a <alltraps>

801057f1 <vector153>:
.globl vector153
vector153:
  pushl $0
801057f1:	6a 00                	push   $0x0
  pushl $153
801057f3:	68 99 00 00 00       	push   $0x99
  jmp alltraps
801057f8:	e9 1d f6 ff ff       	jmp    80104e1a <alltraps>

801057fd <vector154>:
.globl vector154
vector154:
  pushl $0
801057fd:	6a 00                	push   $0x0
  pushl $154
801057ff:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80105804:	e9 11 f6 ff ff       	jmp    80104e1a <alltraps>

80105809 <vector155>:
.globl vector155
vector155:
  pushl $0
80105809:	6a 00                	push   $0x0
  pushl $155
8010580b:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80105810:	e9 05 f6 ff ff       	jmp    80104e1a <alltraps>

80105815 <vector156>:
.globl vector156
vector156:
  pushl $0
80105815:	6a 00                	push   $0x0
  pushl $156
80105817:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
8010581c:	e9 f9 f5 ff ff       	jmp    80104e1a <alltraps>

80105821 <vector157>:
.globl vector157
vector157:
  pushl $0
80105821:	6a 00                	push   $0x0
  pushl $157
80105823:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80105828:	e9 ed f5 ff ff       	jmp    80104e1a <alltraps>

8010582d <vector158>:
.globl vector158
vector158:
  pushl $0
8010582d:	6a 00                	push   $0x0
  pushl $158
8010582f:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80105834:	e9 e1 f5 ff ff       	jmp    80104e1a <alltraps>

80105839 <vector159>:
.globl vector159
vector159:
  pushl $0
80105839:	6a 00                	push   $0x0
  pushl $159
8010583b:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80105840:	e9 d5 f5 ff ff       	jmp    80104e1a <alltraps>

80105845 <vector160>:
.globl vector160
vector160:
  pushl $0
80105845:	6a 00                	push   $0x0
  pushl $160
80105847:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
8010584c:	e9 c9 f5 ff ff       	jmp    80104e1a <alltraps>

80105851 <vector161>:
.globl vector161
vector161:
  pushl $0
80105851:	6a 00                	push   $0x0
  pushl $161
80105853:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80105858:	e9 bd f5 ff ff       	jmp    80104e1a <alltraps>

8010585d <vector162>:
.globl vector162
vector162:
  pushl $0
8010585d:	6a 00                	push   $0x0
  pushl $162
8010585f:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80105864:	e9 b1 f5 ff ff       	jmp    80104e1a <alltraps>

80105869 <vector163>:
.globl vector163
vector163:
  pushl $0
80105869:	6a 00                	push   $0x0
  pushl $163
8010586b:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80105870:	e9 a5 f5 ff ff       	jmp    80104e1a <alltraps>

80105875 <vector164>:
.globl vector164
vector164:
  pushl $0
80105875:	6a 00                	push   $0x0
  pushl $164
80105877:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
8010587c:	e9 99 f5 ff ff       	jmp    80104e1a <alltraps>

80105881 <vector165>:
.globl vector165
vector165:
  pushl $0
80105881:	6a 00                	push   $0x0
  pushl $165
80105883:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80105888:	e9 8d f5 ff ff       	jmp    80104e1a <alltraps>

8010588d <vector166>:
.globl vector166
vector166:
  pushl $0
8010588d:	6a 00                	push   $0x0
  pushl $166
8010588f:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80105894:	e9 81 f5 ff ff       	jmp    80104e1a <alltraps>

80105899 <vector167>:
.globl vector167
vector167:
  pushl $0
80105899:	6a 00                	push   $0x0
  pushl $167
8010589b:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
801058a0:	e9 75 f5 ff ff       	jmp    80104e1a <alltraps>

801058a5 <vector168>:
.globl vector168
vector168:
  pushl $0
801058a5:	6a 00                	push   $0x0
  pushl $168
801058a7:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
801058ac:	e9 69 f5 ff ff       	jmp    80104e1a <alltraps>

801058b1 <vector169>:
.globl vector169
vector169:
  pushl $0
801058b1:	6a 00                	push   $0x0
  pushl $169
801058b3:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
801058b8:	e9 5d f5 ff ff       	jmp    80104e1a <alltraps>

801058bd <vector170>:
.globl vector170
vector170:
  pushl $0
801058bd:	6a 00                	push   $0x0
  pushl $170
801058bf:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
801058c4:	e9 51 f5 ff ff       	jmp    80104e1a <alltraps>

801058c9 <vector171>:
.globl vector171
vector171:
  pushl $0
801058c9:	6a 00                	push   $0x0
  pushl $171
801058cb:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
801058d0:	e9 45 f5 ff ff       	jmp    80104e1a <alltraps>

801058d5 <vector172>:
.globl vector172
vector172:
  pushl $0
801058d5:	6a 00                	push   $0x0
  pushl $172
801058d7:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
801058dc:	e9 39 f5 ff ff       	jmp    80104e1a <alltraps>

801058e1 <vector173>:
.globl vector173
vector173:
  pushl $0
801058e1:	6a 00                	push   $0x0
  pushl $173
801058e3:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
801058e8:	e9 2d f5 ff ff       	jmp    80104e1a <alltraps>

801058ed <vector174>:
.globl vector174
vector174:
  pushl $0
801058ed:	6a 00                	push   $0x0
  pushl $174
801058ef:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
801058f4:	e9 21 f5 ff ff       	jmp    80104e1a <alltraps>

801058f9 <vector175>:
.globl vector175
vector175:
  pushl $0
801058f9:	6a 00                	push   $0x0
  pushl $175
801058fb:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80105900:	e9 15 f5 ff ff       	jmp    80104e1a <alltraps>

80105905 <vector176>:
.globl vector176
vector176:
  pushl $0
80105905:	6a 00                	push   $0x0
  pushl $176
80105907:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
8010590c:	e9 09 f5 ff ff       	jmp    80104e1a <alltraps>

80105911 <vector177>:
.globl vector177
vector177:
  pushl $0
80105911:	6a 00                	push   $0x0
  pushl $177
80105913:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80105918:	e9 fd f4 ff ff       	jmp    80104e1a <alltraps>

8010591d <vector178>:
.globl vector178
vector178:
  pushl $0
8010591d:	6a 00                	push   $0x0
  pushl $178
8010591f:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80105924:	e9 f1 f4 ff ff       	jmp    80104e1a <alltraps>

80105929 <vector179>:
.globl vector179
vector179:
  pushl $0
80105929:	6a 00                	push   $0x0
  pushl $179
8010592b:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80105930:	e9 e5 f4 ff ff       	jmp    80104e1a <alltraps>

80105935 <vector180>:
.globl vector180
vector180:
  pushl $0
80105935:	6a 00                	push   $0x0
  pushl $180
80105937:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
8010593c:	e9 d9 f4 ff ff       	jmp    80104e1a <alltraps>

80105941 <vector181>:
.globl vector181
vector181:
  pushl $0
80105941:	6a 00                	push   $0x0
  pushl $181
80105943:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80105948:	e9 cd f4 ff ff       	jmp    80104e1a <alltraps>

8010594d <vector182>:
.globl vector182
vector182:
  pushl $0
8010594d:	6a 00                	push   $0x0
  pushl $182
8010594f:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80105954:	e9 c1 f4 ff ff       	jmp    80104e1a <alltraps>

80105959 <vector183>:
.globl vector183
vector183:
  pushl $0
80105959:	6a 00                	push   $0x0
  pushl $183
8010595b:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80105960:	e9 b5 f4 ff ff       	jmp    80104e1a <alltraps>

80105965 <vector184>:
.globl vector184
vector184:
  pushl $0
80105965:	6a 00                	push   $0x0
  pushl $184
80105967:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
8010596c:	e9 a9 f4 ff ff       	jmp    80104e1a <alltraps>

80105971 <vector185>:
.globl vector185
vector185:
  pushl $0
80105971:	6a 00                	push   $0x0
  pushl $185
80105973:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80105978:	e9 9d f4 ff ff       	jmp    80104e1a <alltraps>

8010597d <vector186>:
.globl vector186
vector186:
  pushl $0
8010597d:	6a 00                	push   $0x0
  pushl $186
8010597f:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80105984:	e9 91 f4 ff ff       	jmp    80104e1a <alltraps>

80105989 <vector187>:
.globl vector187
vector187:
  pushl $0
80105989:	6a 00                	push   $0x0
  pushl $187
8010598b:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80105990:	e9 85 f4 ff ff       	jmp    80104e1a <alltraps>

80105995 <vector188>:
.globl vector188
vector188:
  pushl $0
80105995:	6a 00                	push   $0x0
  pushl $188
80105997:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
8010599c:	e9 79 f4 ff ff       	jmp    80104e1a <alltraps>

801059a1 <vector189>:
.globl vector189
vector189:
  pushl $0
801059a1:	6a 00                	push   $0x0
  pushl $189
801059a3:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
801059a8:	e9 6d f4 ff ff       	jmp    80104e1a <alltraps>

801059ad <vector190>:
.globl vector190
vector190:
  pushl $0
801059ad:	6a 00                	push   $0x0
  pushl $190
801059af:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
801059b4:	e9 61 f4 ff ff       	jmp    80104e1a <alltraps>

801059b9 <vector191>:
.globl vector191
vector191:
  pushl $0
801059b9:	6a 00                	push   $0x0
  pushl $191
801059bb:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
801059c0:	e9 55 f4 ff ff       	jmp    80104e1a <alltraps>

801059c5 <vector192>:
.globl vector192
vector192:
  pushl $0
801059c5:	6a 00                	push   $0x0
  pushl $192
801059c7:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
801059cc:	e9 49 f4 ff ff       	jmp    80104e1a <alltraps>

801059d1 <vector193>:
.globl vector193
vector193:
  pushl $0
801059d1:	6a 00                	push   $0x0
  pushl $193
801059d3:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
801059d8:	e9 3d f4 ff ff       	jmp    80104e1a <alltraps>

801059dd <vector194>:
.globl vector194
vector194:
  pushl $0
801059dd:	6a 00                	push   $0x0
  pushl $194
801059df:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
801059e4:	e9 31 f4 ff ff       	jmp    80104e1a <alltraps>

801059e9 <vector195>:
.globl vector195
vector195:
  pushl $0
801059e9:	6a 00                	push   $0x0
  pushl $195
801059eb:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
801059f0:	e9 25 f4 ff ff       	jmp    80104e1a <alltraps>

801059f5 <vector196>:
.globl vector196
vector196:
  pushl $0
801059f5:	6a 00                	push   $0x0
  pushl $196
801059f7:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
801059fc:	e9 19 f4 ff ff       	jmp    80104e1a <alltraps>

80105a01 <vector197>:
.globl vector197
vector197:
  pushl $0
80105a01:	6a 00                	push   $0x0
  pushl $197
80105a03:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80105a08:	e9 0d f4 ff ff       	jmp    80104e1a <alltraps>

80105a0d <vector198>:
.globl vector198
vector198:
  pushl $0
80105a0d:	6a 00                	push   $0x0
  pushl $198
80105a0f:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80105a14:	e9 01 f4 ff ff       	jmp    80104e1a <alltraps>

80105a19 <vector199>:
.globl vector199
vector199:
  pushl $0
80105a19:	6a 00                	push   $0x0
  pushl $199
80105a1b:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80105a20:	e9 f5 f3 ff ff       	jmp    80104e1a <alltraps>

80105a25 <vector200>:
.globl vector200
vector200:
  pushl $0
80105a25:	6a 00                	push   $0x0
  pushl $200
80105a27:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80105a2c:	e9 e9 f3 ff ff       	jmp    80104e1a <alltraps>

80105a31 <vector201>:
.globl vector201
vector201:
  pushl $0
80105a31:	6a 00                	push   $0x0
  pushl $201
80105a33:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80105a38:	e9 dd f3 ff ff       	jmp    80104e1a <alltraps>

80105a3d <vector202>:
.globl vector202
vector202:
  pushl $0
80105a3d:	6a 00                	push   $0x0
  pushl $202
80105a3f:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80105a44:	e9 d1 f3 ff ff       	jmp    80104e1a <alltraps>

80105a49 <vector203>:
.globl vector203
vector203:
  pushl $0
80105a49:	6a 00                	push   $0x0
  pushl $203
80105a4b:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80105a50:	e9 c5 f3 ff ff       	jmp    80104e1a <alltraps>

80105a55 <vector204>:
.globl vector204
vector204:
  pushl $0
80105a55:	6a 00                	push   $0x0
  pushl $204
80105a57:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80105a5c:	e9 b9 f3 ff ff       	jmp    80104e1a <alltraps>

80105a61 <vector205>:
.globl vector205
vector205:
  pushl $0
80105a61:	6a 00                	push   $0x0
  pushl $205
80105a63:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80105a68:	e9 ad f3 ff ff       	jmp    80104e1a <alltraps>

80105a6d <vector206>:
.globl vector206
vector206:
  pushl $0
80105a6d:	6a 00                	push   $0x0
  pushl $206
80105a6f:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80105a74:	e9 a1 f3 ff ff       	jmp    80104e1a <alltraps>

80105a79 <vector207>:
.globl vector207
vector207:
  pushl $0
80105a79:	6a 00                	push   $0x0
  pushl $207
80105a7b:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80105a80:	e9 95 f3 ff ff       	jmp    80104e1a <alltraps>

80105a85 <vector208>:
.globl vector208
vector208:
  pushl $0
80105a85:	6a 00                	push   $0x0
  pushl $208
80105a87:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80105a8c:	e9 89 f3 ff ff       	jmp    80104e1a <alltraps>

80105a91 <vector209>:
.globl vector209
vector209:
  pushl $0
80105a91:	6a 00                	push   $0x0
  pushl $209
80105a93:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80105a98:	e9 7d f3 ff ff       	jmp    80104e1a <alltraps>

80105a9d <vector210>:
.globl vector210
vector210:
  pushl $0
80105a9d:	6a 00                	push   $0x0
  pushl $210
80105a9f:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80105aa4:	e9 71 f3 ff ff       	jmp    80104e1a <alltraps>

80105aa9 <vector211>:
.globl vector211
vector211:
  pushl $0
80105aa9:	6a 00                	push   $0x0
  pushl $211
80105aab:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80105ab0:	e9 65 f3 ff ff       	jmp    80104e1a <alltraps>

80105ab5 <vector212>:
.globl vector212
vector212:
  pushl $0
80105ab5:	6a 00                	push   $0x0
  pushl $212
80105ab7:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80105abc:	e9 59 f3 ff ff       	jmp    80104e1a <alltraps>

80105ac1 <vector213>:
.globl vector213
vector213:
  pushl $0
80105ac1:	6a 00                	push   $0x0
  pushl $213
80105ac3:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80105ac8:	e9 4d f3 ff ff       	jmp    80104e1a <alltraps>

80105acd <vector214>:
.globl vector214
vector214:
  pushl $0
80105acd:	6a 00                	push   $0x0
  pushl $214
80105acf:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80105ad4:	e9 41 f3 ff ff       	jmp    80104e1a <alltraps>

80105ad9 <vector215>:
.globl vector215
vector215:
  pushl $0
80105ad9:	6a 00                	push   $0x0
  pushl $215
80105adb:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80105ae0:	e9 35 f3 ff ff       	jmp    80104e1a <alltraps>

80105ae5 <vector216>:
.globl vector216
vector216:
  pushl $0
80105ae5:	6a 00                	push   $0x0
  pushl $216
80105ae7:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80105aec:	e9 29 f3 ff ff       	jmp    80104e1a <alltraps>

80105af1 <vector217>:
.globl vector217
vector217:
  pushl $0
80105af1:	6a 00                	push   $0x0
  pushl $217
80105af3:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80105af8:	e9 1d f3 ff ff       	jmp    80104e1a <alltraps>

80105afd <vector218>:
.globl vector218
vector218:
  pushl $0
80105afd:	6a 00                	push   $0x0
  pushl $218
80105aff:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80105b04:	e9 11 f3 ff ff       	jmp    80104e1a <alltraps>

80105b09 <vector219>:
.globl vector219
vector219:
  pushl $0
80105b09:	6a 00                	push   $0x0
  pushl $219
80105b0b:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80105b10:	e9 05 f3 ff ff       	jmp    80104e1a <alltraps>

80105b15 <vector220>:
.globl vector220
vector220:
  pushl $0
80105b15:	6a 00                	push   $0x0
  pushl $220
80105b17:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80105b1c:	e9 f9 f2 ff ff       	jmp    80104e1a <alltraps>

80105b21 <vector221>:
.globl vector221
vector221:
  pushl $0
80105b21:	6a 00                	push   $0x0
  pushl $221
80105b23:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80105b28:	e9 ed f2 ff ff       	jmp    80104e1a <alltraps>

80105b2d <vector222>:
.globl vector222
vector222:
  pushl $0
80105b2d:	6a 00                	push   $0x0
  pushl $222
80105b2f:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80105b34:	e9 e1 f2 ff ff       	jmp    80104e1a <alltraps>

80105b39 <vector223>:
.globl vector223
vector223:
  pushl $0
80105b39:	6a 00                	push   $0x0
  pushl $223
80105b3b:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80105b40:	e9 d5 f2 ff ff       	jmp    80104e1a <alltraps>

80105b45 <vector224>:
.globl vector224
vector224:
  pushl $0
80105b45:	6a 00                	push   $0x0
  pushl $224
80105b47:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80105b4c:	e9 c9 f2 ff ff       	jmp    80104e1a <alltraps>

80105b51 <vector225>:
.globl vector225
vector225:
  pushl $0
80105b51:	6a 00                	push   $0x0
  pushl $225
80105b53:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80105b58:	e9 bd f2 ff ff       	jmp    80104e1a <alltraps>

80105b5d <vector226>:
.globl vector226
vector226:
  pushl $0
80105b5d:	6a 00                	push   $0x0
  pushl $226
80105b5f:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80105b64:	e9 b1 f2 ff ff       	jmp    80104e1a <alltraps>

80105b69 <vector227>:
.globl vector227
vector227:
  pushl $0
80105b69:	6a 00                	push   $0x0
  pushl $227
80105b6b:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80105b70:	e9 a5 f2 ff ff       	jmp    80104e1a <alltraps>

80105b75 <vector228>:
.globl vector228
vector228:
  pushl $0
80105b75:	6a 00                	push   $0x0
  pushl $228
80105b77:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80105b7c:	e9 99 f2 ff ff       	jmp    80104e1a <alltraps>

80105b81 <vector229>:
.globl vector229
vector229:
  pushl $0
80105b81:	6a 00                	push   $0x0
  pushl $229
80105b83:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80105b88:	e9 8d f2 ff ff       	jmp    80104e1a <alltraps>

80105b8d <vector230>:
.globl vector230
vector230:
  pushl $0
80105b8d:	6a 00                	push   $0x0
  pushl $230
80105b8f:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80105b94:	e9 81 f2 ff ff       	jmp    80104e1a <alltraps>

80105b99 <vector231>:
.globl vector231
vector231:
  pushl $0
80105b99:	6a 00                	push   $0x0
  pushl $231
80105b9b:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80105ba0:	e9 75 f2 ff ff       	jmp    80104e1a <alltraps>

80105ba5 <vector232>:
.globl vector232
vector232:
  pushl $0
80105ba5:	6a 00                	push   $0x0
  pushl $232
80105ba7:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80105bac:	e9 69 f2 ff ff       	jmp    80104e1a <alltraps>

80105bb1 <vector233>:
.globl vector233
vector233:
  pushl $0
80105bb1:	6a 00                	push   $0x0
  pushl $233
80105bb3:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80105bb8:	e9 5d f2 ff ff       	jmp    80104e1a <alltraps>

80105bbd <vector234>:
.globl vector234
vector234:
  pushl $0
80105bbd:	6a 00                	push   $0x0
  pushl $234
80105bbf:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80105bc4:	e9 51 f2 ff ff       	jmp    80104e1a <alltraps>

80105bc9 <vector235>:
.globl vector235
vector235:
  pushl $0
80105bc9:	6a 00                	push   $0x0
  pushl $235
80105bcb:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80105bd0:	e9 45 f2 ff ff       	jmp    80104e1a <alltraps>

80105bd5 <vector236>:
.globl vector236
vector236:
  pushl $0
80105bd5:	6a 00                	push   $0x0
  pushl $236
80105bd7:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80105bdc:	e9 39 f2 ff ff       	jmp    80104e1a <alltraps>

80105be1 <vector237>:
.globl vector237
vector237:
  pushl $0
80105be1:	6a 00                	push   $0x0
  pushl $237
80105be3:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80105be8:	e9 2d f2 ff ff       	jmp    80104e1a <alltraps>

80105bed <vector238>:
.globl vector238
vector238:
  pushl $0
80105bed:	6a 00                	push   $0x0
  pushl $238
80105bef:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80105bf4:	e9 21 f2 ff ff       	jmp    80104e1a <alltraps>

80105bf9 <vector239>:
.globl vector239
vector239:
  pushl $0
80105bf9:	6a 00                	push   $0x0
  pushl $239
80105bfb:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80105c00:	e9 15 f2 ff ff       	jmp    80104e1a <alltraps>

80105c05 <vector240>:
.globl vector240
vector240:
  pushl $0
80105c05:	6a 00                	push   $0x0
  pushl $240
80105c07:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80105c0c:	e9 09 f2 ff ff       	jmp    80104e1a <alltraps>

80105c11 <vector241>:
.globl vector241
vector241:
  pushl $0
80105c11:	6a 00                	push   $0x0
  pushl $241
80105c13:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80105c18:	e9 fd f1 ff ff       	jmp    80104e1a <alltraps>

80105c1d <vector242>:
.globl vector242
vector242:
  pushl $0
80105c1d:	6a 00                	push   $0x0
  pushl $242
80105c1f:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80105c24:	e9 f1 f1 ff ff       	jmp    80104e1a <alltraps>

80105c29 <vector243>:
.globl vector243
vector243:
  pushl $0
80105c29:	6a 00                	push   $0x0
  pushl $243
80105c2b:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80105c30:	e9 e5 f1 ff ff       	jmp    80104e1a <alltraps>

80105c35 <vector244>:
.globl vector244
vector244:
  pushl $0
80105c35:	6a 00                	push   $0x0
  pushl $244
80105c37:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80105c3c:	e9 d9 f1 ff ff       	jmp    80104e1a <alltraps>

80105c41 <vector245>:
.globl vector245
vector245:
  pushl $0
80105c41:	6a 00                	push   $0x0
  pushl $245
80105c43:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80105c48:	e9 cd f1 ff ff       	jmp    80104e1a <alltraps>

80105c4d <vector246>:
.globl vector246
vector246:
  pushl $0
80105c4d:	6a 00                	push   $0x0
  pushl $246
80105c4f:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80105c54:	e9 c1 f1 ff ff       	jmp    80104e1a <alltraps>

80105c59 <vector247>:
.globl vector247
vector247:
  pushl $0
80105c59:	6a 00                	push   $0x0
  pushl $247
80105c5b:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80105c60:	e9 b5 f1 ff ff       	jmp    80104e1a <alltraps>

80105c65 <vector248>:
.globl vector248
vector248:
  pushl $0
80105c65:	6a 00                	push   $0x0
  pushl $248
80105c67:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80105c6c:	e9 a9 f1 ff ff       	jmp    80104e1a <alltraps>

80105c71 <vector249>:
.globl vector249
vector249:
  pushl $0
80105c71:	6a 00                	push   $0x0
  pushl $249
80105c73:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80105c78:	e9 9d f1 ff ff       	jmp    80104e1a <alltraps>

80105c7d <vector250>:
.globl vector250
vector250:
  pushl $0
80105c7d:	6a 00                	push   $0x0
  pushl $250
80105c7f:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80105c84:	e9 91 f1 ff ff       	jmp    80104e1a <alltraps>

80105c89 <vector251>:
.globl vector251
vector251:
  pushl $0
80105c89:	6a 00                	push   $0x0
  pushl $251
80105c8b:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80105c90:	e9 85 f1 ff ff       	jmp    80104e1a <alltraps>

80105c95 <vector252>:
.globl vector252
vector252:
  pushl $0
80105c95:	6a 00                	push   $0x0
  pushl $252
80105c97:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80105c9c:	e9 79 f1 ff ff       	jmp    80104e1a <alltraps>

80105ca1 <vector253>:
.globl vector253
vector253:
  pushl $0
80105ca1:	6a 00                	push   $0x0
  pushl $253
80105ca3:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80105ca8:	e9 6d f1 ff ff       	jmp    80104e1a <alltraps>

80105cad <vector254>:
.globl vector254
vector254:
  pushl $0
80105cad:	6a 00                	push   $0x0
  pushl $254
80105caf:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80105cb4:	e9 61 f1 ff ff       	jmp    80104e1a <alltraps>

80105cb9 <vector255>:
.globl vector255
vector255:
  pushl $0
80105cb9:	6a 00                	push   $0x0
  pushl $255
80105cbb:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80105cc0:	e9 55 f1 ff ff       	jmp    80104e1a <alltraps>

80105cc5 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80105cc5:	55                   	push   %ebp
80105cc6:	89 e5                	mov    %esp,%ebp
80105cc8:	57                   	push   %edi
80105cc9:	56                   	push   %esi
80105cca:	53                   	push   %ebx
80105ccb:	83 ec 0c             	sub    $0xc,%esp
80105cce:	89 d6                	mov    %edx,%esi
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80105cd0:	c1 ea 16             	shr    $0x16,%edx
80105cd3:	8d 3c 90             	lea    (%eax,%edx,4),%edi
  if(*pde & PTE_P){
80105cd6:	8b 1f                	mov    (%edi),%ebx
80105cd8:	f6 c3 01             	test   $0x1,%bl
80105cdb:	74 22                	je     80105cff <walkpgdir+0x3a>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
80105cdd:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
80105ce3:	81 c3 00 00 00 80    	add    $0x80000000,%ebx
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
80105ce9:	c1 ee 0c             	shr    $0xc,%esi
80105cec:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
80105cf2:	8d 1c b3             	lea    (%ebx,%esi,4),%ebx
}
80105cf5:	89 d8                	mov    %ebx,%eax
80105cf7:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105cfa:	5b                   	pop    %ebx
80105cfb:	5e                   	pop    %esi
80105cfc:	5f                   	pop    %edi
80105cfd:	5d                   	pop    %ebp
80105cfe:	c3                   	ret    
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80105cff:	85 c9                	test   %ecx,%ecx
80105d01:	74 2b                	je     80105d2e <walkpgdir+0x69>
80105d03:	e8 e4 c3 ff ff       	call   801020ec <kalloc>
80105d08:	89 c3                	mov    %eax,%ebx
80105d0a:	85 c0                	test   %eax,%eax
80105d0c:	74 e7                	je     80105cf5 <walkpgdir+0x30>
    memset(pgtab, 0, PGSIZE);
80105d0e:	83 ec 04             	sub    $0x4,%esp
80105d11:	68 00 10 00 00       	push   $0x1000
80105d16:	6a 00                	push   $0x0
80105d18:	50                   	push   %eax
80105d19:	e8 fe df ff ff       	call   80103d1c <memset>
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
80105d1e:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80105d24:	83 c8 07             	or     $0x7,%eax
80105d27:	89 07                	mov    %eax,(%edi)
80105d29:	83 c4 10             	add    $0x10,%esp
80105d2c:	eb bb                	jmp    80105ce9 <walkpgdir+0x24>
      return 0;
80105d2e:	bb 00 00 00 00       	mov    $0x0,%ebx
80105d33:	eb c0                	jmp    80105cf5 <walkpgdir+0x30>

80105d35 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80105d35:	55                   	push   %ebp
80105d36:	89 e5                	mov    %esp,%ebp
80105d38:	57                   	push   %edi
80105d39:	56                   	push   %esi
80105d3a:	53                   	push   %ebx
80105d3b:	83 ec 1c             	sub    $0x1c,%esp
80105d3e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105d41:	8b 75 08             	mov    0x8(%ebp),%esi
  char *a, *last;
  pte_t *pte;

  a = (char*)PGROUNDDOWN((uint)va);
80105d44:	89 d3                	mov    %edx,%ebx
80105d46:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80105d4c:	8d 7c 0a ff          	lea    -0x1(%edx,%ecx,1),%edi
80105d50:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105d56:	b9 01 00 00 00       	mov    $0x1,%ecx
80105d5b:	89 da                	mov    %ebx,%edx
80105d5d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105d60:	e8 60 ff ff ff       	call   80105cc5 <walkpgdir>
80105d65:	85 c0                	test   %eax,%eax
80105d67:	74 2e                	je     80105d97 <mappages+0x62>
      return -1;
    if(*pte & PTE_P)
80105d69:	f6 00 01             	testb  $0x1,(%eax)
80105d6c:	75 1c                	jne    80105d8a <mappages+0x55>
      panic("remap");
    *pte = pa | perm | PTE_P;
80105d6e:	89 f2                	mov    %esi,%edx
80105d70:	0b 55 0c             	or     0xc(%ebp),%edx
80105d73:	83 ca 01             	or     $0x1,%edx
80105d76:	89 10                	mov    %edx,(%eax)
    if(a == last)
80105d78:	39 fb                	cmp    %edi,%ebx
80105d7a:	74 28                	je     80105da4 <mappages+0x6f>
      break;
    a += PGSIZE;
80105d7c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pa += PGSIZE;
80105d82:	81 c6 00 10 00 00    	add    $0x1000,%esi
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105d88:	eb cc                	jmp    80105d56 <mappages+0x21>
      panic("remap");
80105d8a:	83 ec 0c             	sub    $0xc,%esp
80105d8d:	68 4c 6e 10 80       	push   $0x80106e4c
80105d92:	e8 b1 a5 ff ff       	call   80100348 <panic>
      return -1;
80105d97:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  return 0;
}
80105d9c:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105d9f:	5b                   	pop    %ebx
80105da0:	5e                   	pop    %esi
80105da1:	5f                   	pop    %edi
80105da2:	5d                   	pop    %ebp
80105da3:	c3                   	ret    
  return 0;
80105da4:	b8 00 00 00 00       	mov    $0x0,%eax
80105da9:	eb f1                	jmp    80105d9c <mappages+0x67>

80105dab <seginit>:
{
80105dab:	55                   	push   %ebp
80105dac:	89 e5                	mov    %esp,%ebp
80105dae:	53                   	push   %ebx
80105daf:	83 ec 14             	sub    $0x14,%esp
  c = &cpus[cpuid()];
80105db2:	e8 ff d4 ff ff       	call   801032b6 <cpuid>
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80105db7:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
80105dbd:	66 c7 80 18 18 13 80 	movw   $0xffff,-0x7fece7e8(%eax)
80105dc4:	ff ff 
80105dc6:	66 c7 80 1a 18 13 80 	movw   $0x0,-0x7fece7e6(%eax)
80105dcd:	00 00 
80105dcf:	c6 80 1c 18 13 80 00 	movb   $0x0,-0x7fece7e4(%eax)
80105dd6:	0f b6 88 1d 18 13 80 	movzbl -0x7fece7e3(%eax),%ecx
80105ddd:	83 e1 f0             	and    $0xfffffff0,%ecx
80105de0:	83 c9 1a             	or     $0x1a,%ecx
80105de3:	83 e1 9f             	and    $0xffffff9f,%ecx
80105de6:	83 c9 80             	or     $0xffffff80,%ecx
80105de9:	88 88 1d 18 13 80    	mov    %cl,-0x7fece7e3(%eax)
80105def:	0f b6 88 1e 18 13 80 	movzbl -0x7fece7e2(%eax),%ecx
80105df6:	83 c9 0f             	or     $0xf,%ecx
80105df9:	83 e1 cf             	and    $0xffffffcf,%ecx
80105dfc:	83 c9 c0             	or     $0xffffffc0,%ecx
80105dff:	88 88 1e 18 13 80    	mov    %cl,-0x7fece7e2(%eax)
80105e05:	c6 80 1f 18 13 80 00 	movb   $0x0,-0x7fece7e1(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80105e0c:	66 c7 80 20 18 13 80 	movw   $0xffff,-0x7fece7e0(%eax)
80105e13:	ff ff 
80105e15:	66 c7 80 22 18 13 80 	movw   $0x0,-0x7fece7de(%eax)
80105e1c:	00 00 
80105e1e:	c6 80 24 18 13 80 00 	movb   $0x0,-0x7fece7dc(%eax)
80105e25:	0f b6 88 25 18 13 80 	movzbl -0x7fece7db(%eax),%ecx
80105e2c:	83 e1 f0             	and    $0xfffffff0,%ecx
80105e2f:	83 c9 12             	or     $0x12,%ecx
80105e32:	83 e1 9f             	and    $0xffffff9f,%ecx
80105e35:	83 c9 80             	or     $0xffffff80,%ecx
80105e38:	88 88 25 18 13 80    	mov    %cl,-0x7fece7db(%eax)
80105e3e:	0f b6 88 26 18 13 80 	movzbl -0x7fece7da(%eax),%ecx
80105e45:	83 c9 0f             	or     $0xf,%ecx
80105e48:	83 e1 cf             	and    $0xffffffcf,%ecx
80105e4b:	83 c9 c0             	or     $0xffffffc0,%ecx
80105e4e:	88 88 26 18 13 80    	mov    %cl,-0x7fece7da(%eax)
80105e54:	c6 80 27 18 13 80 00 	movb   $0x0,-0x7fece7d9(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80105e5b:	66 c7 80 28 18 13 80 	movw   $0xffff,-0x7fece7d8(%eax)
80105e62:	ff ff 
80105e64:	66 c7 80 2a 18 13 80 	movw   $0x0,-0x7fece7d6(%eax)
80105e6b:	00 00 
80105e6d:	c6 80 2c 18 13 80 00 	movb   $0x0,-0x7fece7d4(%eax)
80105e74:	c6 80 2d 18 13 80 fa 	movb   $0xfa,-0x7fece7d3(%eax)
80105e7b:	0f b6 88 2e 18 13 80 	movzbl -0x7fece7d2(%eax),%ecx
80105e82:	83 c9 0f             	or     $0xf,%ecx
80105e85:	83 e1 cf             	and    $0xffffffcf,%ecx
80105e88:	83 c9 c0             	or     $0xffffffc0,%ecx
80105e8b:	88 88 2e 18 13 80    	mov    %cl,-0x7fece7d2(%eax)
80105e91:	c6 80 2f 18 13 80 00 	movb   $0x0,-0x7fece7d1(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80105e98:	66 c7 80 30 18 13 80 	movw   $0xffff,-0x7fece7d0(%eax)
80105e9f:	ff ff 
80105ea1:	66 c7 80 32 18 13 80 	movw   $0x0,-0x7fece7ce(%eax)
80105ea8:	00 00 
80105eaa:	c6 80 34 18 13 80 00 	movb   $0x0,-0x7fece7cc(%eax)
80105eb1:	c6 80 35 18 13 80 f2 	movb   $0xf2,-0x7fece7cb(%eax)
80105eb8:	0f b6 88 36 18 13 80 	movzbl -0x7fece7ca(%eax),%ecx
80105ebf:	83 c9 0f             	or     $0xf,%ecx
80105ec2:	83 e1 cf             	and    $0xffffffcf,%ecx
80105ec5:	83 c9 c0             	or     $0xffffffc0,%ecx
80105ec8:	88 88 36 18 13 80    	mov    %cl,-0x7fece7ca(%eax)
80105ece:	c6 80 37 18 13 80 00 	movb   $0x0,-0x7fece7c9(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
80105ed5:	05 10 18 13 80       	add    $0x80131810,%eax
  pd[0] = size-1;
80105eda:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
  pd[1] = (uint)p;
80105ee0:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
  pd[2] = (uint)p >> 16;
80105ee4:	c1 e8 10             	shr    $0x10,%eax
80105ee7:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
  asm volatile("lgdt (%0)" : : "r" (pd));
80105eeb:	8d 45 f2             	lea    -0xe(%ebp),%eax
80105eee:	0f 01 10             	lgdtl  (%eax)
}
80105ef1:	83 c4 14             	add    $0x14,%esp
80105ef4:	5b                   	pop    %ebx
80105ef5:	5d                   	pop    %ebp
80105ef6:	c3                   	ret    

80105ef7 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80105ef7:	55                   	push   %ebp
80105ef8:	89 e5                	mov    %esp,%ebp
  lcr3(V2P(kpgdir));   // switch to the kernel page table
80105efa:	a1 c4 44 13 80       	mov    0x801344c4,%eax
80105eff:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint val)
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
80105f04:	0f 22 d8             	mov    %eax,%cr3
}
80105f07:	5d                   	pop    %ebp
80105f08:	c3                   	ret    

80105f09 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80105f09:	55                   	push   %ebp
80105f0a:	89 e5                	mov    %esp,%ebp
80105f0c:	57                   	push   %edi
80105f0d:	56                   	push   %esi
80105f0e:	53                   	push   %ebx
80105f0f:	83 ec 1c             	sub    $0x1c,%esp
80105f12:	8b 75 08             	mov    0x8(%ebp),%esi
  if(p == 0)
80105f15:	85 f6                	test   %esi,%esi
80105f17:	0f 84 dd 00 00 00    	je     80105ffa <switchuvm+0xf1>
    panic("switchuvm: no process");
  if(p->kstack == 0)
80105f1d:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
80105f21:	0f 84 e0 00 00 00    	je     80106007 <switchuvm+0xfe>
    panic("switchuvm: no kstack");
  if(p->pgdir == 0)
80105f27:	83 7e 04 00          	cmpl   $0x0,0x4(%esi)
80105f2b:	0f 84 e3 00 00 00    	je     80106014 <switchuvm+0x10b>
    panic("switchuvm: no pgdir");

  pushcli();
80105f31:	e8 5d dc ff ff       	call   80103b93 <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
80105f36:	e8 1f d3 ff ff       	call   8010325a <mycpu>
80105f3b:	89 c3                	mov    %eax,%ebx
80105f3d:	e8 18 d3 ff ff       	call   8010325a <mycpu>
80105f42:	8d 78 08             	lea    0x8(%eax),%edi
80105f45:	e8 10 d3 ff ff       	call   8010325a <mycpu>
80105f4a:	83 c0 08             	add    $0x8,%eax
80105f4d:	c1 e8 10             	shr    $0x10,%eax
80105f50:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105f53:	e8 02 d3 ff ff       	call   8010325a <mycpu>
80105f58:	83 c0 08             	add    $0x8,%eax
80105f5b:	c1 e8 18             	shr    $0x18,%eax
80105f5e:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
80105f65:	67 00 
80105f67:	66 89 bb 9a 00 00 00 	mov    %di,0x9a(%ebx)
80105f6e:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
80105f72:	88 8b 9c 00 00 00    	mov    %cl,0x9c(%ebx)
80105f78:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
80105f7f:	83 e2 f0             	and    $0xfffffff0,%edx
80105f82:	83 ca 19             	or     $0x19,%edx
80105f85:	83 e2 9f             	and    $0xffffff9f,%edx
80105f88:	83 ca 80             	or     $0xffffff80,%edx
80105f8b:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
80105f91:	c6 83 9e 00 00 00 40 	movb   $0x40,0x9e(%ebx)
80105f98:	88 83 9f 00 00 00    	mov    %al,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
80105f9e:	e8 b7 d2 ff ff       	call   8010325a <mycpu>
80105fa3:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80105faa:	83 e2 ef             	and    $0xffffffef,%edx
80105fad:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
80105fb3:	e8 a2 d2 ff ff       	call   8010325a <mycpu>
80105fb8:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
80105fbe:	8b 5e 08             	mov    0x8(%esi),%ebx
80105fc1:	e8 94 d2 ff ff       	call   8010325a <mycpu>
80105fc6:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80105fcc:	89 58 0c             	mov    %ebx,0xc(%eax)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
80105fcf:	e8 86 d2 ff ff       	call   8010325a <mycpu>
80105fd4:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  asm volatile("ltr %0" : : "r" (sel));
80105fda:	b8 28 00 00 00       	mov    $0x28,%eax
80105fdf:	0f 00 d8             	ltr    %ax
  ltr(SEG_TSS << 3);
  lcr3(V2P(p->pgdir));  // switch to process's address space
80105fe2:	8b 46 04             	mov    0x4(%esi),%eax
80105fe5:	05 00 00 00 80       	add    $0x80000000,%eax
  asm volatile("movl %0,%%cr3" : : "r" (val));
80105fea:	0f 22 d8             	mov    %eax,%cr3
  popcli();
80105fed:	e8 de db ff ff       	call   80103bd0 <popcli>
}
80105ff2:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105ff5:	5b                   	pop    %ebx
80105ff6:	5e                   	pop    %esi
80105ff7:	5f                   	pop    %edi
80105ff8:	5d                   	pop    %ebp
80105ff9:	c3                   	ret    
    panic("switchuvm: no process");
80105ffa:	83 ec 0c             	sub    $0xc,%esp
80105ffd:	68 52 6e 10 80       	push   $0x80106e52
80106002:	e8 41 a3 ff ff       	call   80100348 <panic>
    panic("switchuvm: no kstack");
80106007:	83 ec 0c             	sub    $0xc,%esp
8010600a:	68 68 6e 10 80       	push   $0x80106e68
8010600f:	e8 34 a3 ff ff       	call   80100348 <panic>
    panic("switchuvm: no pgdir");
80106014:	83 ec 0c             	sub    $0xc,%esp
80106017:	68 7d 6e 10 80       	push   $0x80106e7d
8010601c:	e8 27 a3 ff ff       	call   80100348 <panic>

80106021 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80106021:	55                   	push   %ebp
80106022:	89 e5                	mov    %esp,%ebp
80106024:	56                   	push   %esi
80106025:	53                   	push   %ebx
80106026:	8b 75 10             	mov    0x10(%ebp),%esi
  char *mem;

  if(sz >= PGSIZE)
80106029:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
8010602f:	77 4c                	ja     8010607d <inituvm+0x5c>
    panic("inituvm: more than a page");
  mem = kalloc();
80106031:	e8 b6 c0 ff ff       	call   801020ec <kalloc>
80106036:	89 c3                	mov    %eax,%ebx
  memset(mem, 0, PGSIZE);
80106038:	83 ec 04             	sub    $0x4,%esp
8010603b:	68 00 10 00 00       	push   $0x1000
80106040:	6a 00                	push   $0x0
80106042:	50                   	push   %eax
80106043:	e8 d4 dc ff ff       	call   80103d1c <memset>
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
80106048:	83 c4 08             	add    $0x8,%esp
8010604b:	6a 06                	push   $0x6
8010604d:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80106053:	50                   	push   %eax
80106054:	b9 00 10 00 00       	mov    $0x1000,%ecx
80106059:	ba 00 00 00 00       	mov    $0x0,%edx
8010605e:	8b 45 08             	mov    0x8(%ebp),%eax
80106061:	e8 cf fc ff ff       	call   80105d35 <mappages>
  memmove(mem, init, sz);
80106066:	83 c4 0c             	add    $0xc,%esp
80106069:	56                   	push   %esi
8010606a:	ff 75 0c             	pushl  0xc(%ebp)
8010606d:	53                   	push   %ebx
8010606e:	e8 24 dd ff ff       	call   80103d97 <memmove>
}
80106073:	83 c4 10             	add    $0x10,%esp
80106076:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106079:	5b                   	pop    %ebx
8010607a:	5e                   	pop    %esi
8010607b:	5d                   	pop    %ebp
8010607c:	c3                   	ret    
    panic("inituvm: more than a page");
8010607d:	83 ec 0c             	sub    $0xc,%esp
80106080:	68 91 6e 10 80       	push   $0x80106e91
80106085:	e8 be a2 ff ff       	call   80100348 <panic>

8010608a <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
8010608a:	55                   	push   %ebp
8010608b:	89 e5                	mov    %esp,%ebp
8010608d:	57                   	push   %edi
8010608e:	56                   	push   %esi
8010608f:	53                   	push   %ebx
80106090:	83 ec 0c             	sub    $0xc,%esp
80106093:	8b 7d 18             	mov    0x18(%ebp),%edi
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80106096:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
8010609d:	75 07                	jne    801060a6 <loaduvm+0x1c>
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
8010609f:	bb 00 00 00 00       	mov    $0x0,%ebx
801060a4:	eb 3c                	jmp    801060e2 <loaduvm+0x58>
    panic("loaduvm: addr must be page aligned");
801060a6:	83 ec 0c             	sub    $0xc,%esp
801060a9:	68 4c 6f 10 80       	push   $0x80106f4c
801060ae:	e8 95 a2 ff ff       	call   80100348 <panic>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
801060b3:	83 ec 0c             	sub    $0xc,%esp
801060b6:	68 ab 6e 10 80       	push   $0x80106eab
801060bb:	e8 88 a2 ff ff       	call   80100348 <panic>
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, P2V(pa), offset+i, n) != n)
801060c0:	05 00 00 00 80       	add    $0x80000000,%eax
801060c5:	56                   	push   %esi
801060c6:	89 da                	mov    %ebx,%edx
801060c8:	03 55 14             	add    0x14(%ebp),%edx
801060cb:	52                   	push   %edx
801060cc:	50                   	push   %eax
801060cd:	ff 75 10             	pushl  0x10(%ebp)
801060d0:	e8 9e b6 ff ff       	call   80101773 <readi>
801060d5:	83 c4 10             	add    $0x10,%esp
801060d8:	39 f0                	cmp    %esi,%eax
801060da:	75 47                	jne    80106123 <loaduvm+0x99>
  for(i = 0; i < sz; i += PGSIZE){
801060dc:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801060e2:	39 fb                	cmp    %edi,%ebx
801060e4:	73 30                	jae    80106116 <loaduvm+0x8c>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
801060e6:	89 da                	mov    %ebx,%edx
801060e8:	03 55 0c             	add    0xc(%ebp),%edx
801060eb:	b9 00 00 00 00       	mov    $0x0,%ecx
801060f0:	8b 45 08             	mov    0x8(%ebp),%eax
801060f3:	e8 cd fb ff ff       	call   80105cc5 <walkpgdir>
801060f8:	85 c0                	test   %eax,%eax
801060fa:	74 b7                	je     801060b3 <loaduvm+0x29>
    pa = PTE_ADDR(*pte);
801060fc:	8b 00                	mov    (%eax),%eax
801060fe:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    if(sz - i < PGSIZE)
80106103:	89 fe                	mov    %edi,%esi
80106105:	29 de                	sub    %ebx,%esi
80106107:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
8010610d:	76 b1                	jbe    801060c0 <loaduvm+0x36>
      n = PGSIZE;
8010610f:	be 00 10 00 00       	mov    $0x1000,%esi
80106114:	eb aa                	jmp    801060c0 <loaduvm+0x36>
      return -1;
  }
  return 0;
80106116:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010611b:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010611e:	5b                   	pop    %ebx
8010611f:	5e                   	pop    %esi
80106120:	5f                   	pop    %edi
80106121:	5d                   	pop    %ebp
80106122:	c3                   	ret    
      return -1;
80106123:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106128:	eb f1                	jmp    8010611b <loaduvm+0x91>

8010612a <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
8010612a:	55                   	push   %ebp
8010612b:	89 e5                	mov    %esp,%ebp
8010612d:	57                   	push   %edi
8010612e:	56                   	push   %esi
8010612f:	53                   	push   %ebx
80106130:	83 ec 0c             	sub    $0xc,%esp
80106133:	8b 7d 0c             	mov    0xc(%ebp),%edi
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80106136:	39 7d 10             	cmp    %edi,0x10(%ebp)
80106139:	73 11                	jae    8010614c <deallocuvm+0x22>
    return oldsz;

  a = PGROUNDUP(newsz);
8010613b:	8b 45 10             	mov    0x10(%ebp),%eax
8010613e:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
80106144:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a  < oldsz; a += PGSIZE){
8010614a:	eb 19                	jmp    80106165 <deallocuvm+0x3b>
    return oldsz;
8010614c:	89 f8                	mov    %edi,%eax
8010614e:	eb 64                	jmp    801061b4 <deallocuvm+0x8a>
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(!pte)
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
80106150:	c1 eb 16             	shr    $0x16,%ebx
80106153:	83 c3 01             	add    $0x1,%ebx
80106156:	c1 e3 16             	shl    $0x16,%ebx
80106159:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
  for(; a  < oldsz; a += PGSIZE){
8010615f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106165:	39 fb                	cmp    %edi,%ebx
80106167:	73 48                	jae    801061b1 <deallocuvm+0x87>
    pte = walkpgdir(pgdir, (char*)a, 0);
80106169:	b9 00 00 00 00       	mov    $0x0,%ecx
8010616e:	89 da                	mov    %ebx,%edx
80106170:	8b 45 08             	mov    0x8(%ebp),%eax
80106173:	e8 4d fb ff ff       	call   80105cc5 <walkpgdir>
80106178:	89 c6                	mov    %eax,%esi
    if(!pte)
8010617a:	85 c0                	test   %eax,%eax
8010617c:	74 d2                	je     80106150 <deallocuvm+0x26>
    else if((*pte & PTE_P) != 0){
8010617e:	8b 00                	mov    (%eax),%eax
80106180:	a8 01                	test   $0x1,%al
80106182:	74 db                	je     8010615f <deallocuvm+0x35>
      pa = PTE_ADDR(*pte);
      if(pa == 0)
80106184:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80106189:	74 19                	je     801061a4 <deallocuvm+0x7a>
        panic("kfree");
      char *v = P2V(pa);
8010618b:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
80106190:	83 ec 0c             	sub    $0xc,%esp
80106193:	50                   	push   %eax
80106194:	e8 0b be ff ff       	call   80101fa4 <kfree>
      *pte = 0;
80106199:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
8010619f:	83 c4 10             	add    $0x10,%esp
801061a2:	eb bb                	jmp    8010615f <deallocuvm+0x35>
        panic("kfree");
801061a4:	83 ec 0c             	sub    $0xc,%esp
801061a7:	68 e6 67 10 80       	push   $0x801067e6
801061ac:	e8 97 a1 ff ff       	call   80100348 <panic>
    }
  }
  return newsz;
801061b1:	8b 45 10             	mov    0x10(%ebp),%eax
}
801061b4:	8d 65 f4             	lea    -0xc(%ebp),%esp
801061b7:	5b                   	pop    %ebx
801061b8:	5e                   	pop    %esi
801061b9:	5f                   	pop    %edi
801061ba:	5d                   	pop    %ebp
801061bb:	c3                   	ret    

801061bc <allocuvm>:
{
801061bc:	55                   	push   %ebp
801061bd:	89 e5                	mov    %esp,%ebp
801061bf:	57                   	push   %edi
801061c0:	56                   	push   %esi
801061c1:	53                   	push   %ebx
801061c2:	83 ec 1c             	sub    $0x1c,%esp
801061c5:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(newsz >= KERNBASE)
801061c8:	89 7d e4             	mov    %edi,-0x1c(%ebp)
801061cb:	85 ff                	test   %edi,%edi
801061cd:	0f 88 c1 00 00 00    	js     80106294 <allocuvm+0xd8>
  if(newsz < oldsz)
801061d3:	3b 7d 0c             	cmp    0xc(%ebp),%edi
801061d6:	72 5c                	jb     80106234 <allocuvm+0x78>
  a = PGROUNDUP(oldsz);
801061d8:	8b 45 0c             	mov    0xc(%ebp),%eax
801061db:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
801061e1:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a < newsz; a += PGSIZE){
801061e7:	39 fb                	cmp    %edi,%ebx
801061e9:	0f 83 ac 00 00 00    	jae    8010629b <allocuvm+0xdf>
    mem = kalloc();
801061ef:	e8 f8 be ff ff       	call   801020ec <kalloc>
801061f4:	89 c6                	mov    %eax,%esi
    if(mem == 0){
801061f6:	85 c0                	test   %eax,%eax
801061f8:	74 42                	je     8010623c <allocuvm+0x80>
    memset(mem, 0, PGSIZE);
801061fa:	83 ec 04             	sub    $0x4,%esp
801061fd:	68 00 10 00 00       	push   $0x1000
80106202:	6a 00                	push   $0x0
80106204:	50                   	push   %eax
80106205:	e8 12 db ff ff       	call   80103d1c <memset>
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
8010620a:	83 c4 08             	add    $0x8,%esp
8010620d:	6a 06                	push   $0x6
8010620f:	8d 86 00 00 00 80    	lea    -0x80000000(%esi),%eax
80106215:	50                   	push   %eax
80106216:	b9 00 10 00 00       	mov    $0x1000,%ecx
8010621b:	89 da                	mov    %ebx,%edx
8010621d:	8b 45 08             	mov    0x8(%ebp),%eax
80106220:	e8 10 fb ff ff       	call   80105d35 <mappages>
80106225:	83 c4 10             	add    $0x10,%esp
80106228:	85 c0                	test   %eax,%eax
8010622a:	78 38                	js     80106264 <allocuvm+0xa8>
  for(; a < newsz; a += PGSIZE){
8010622c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106232:	eb b3                	jmp    801061e7 <allocuvm+0x2b>
    return oldsz;
80106234:	8b 45 0c             	mov    0xc(%ebp),%eax
80106237:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010623a:	eb 5f                	jmp    8010629b <allocuvm+0xdf>
      cprintf("allocuvm out of memory\n");
8010623c:	83 ec 0c             	sub    $0xc,%esp
8010623f:	68 c9 6e 10 80       	push   $0x80106ec9
80106244:	e8 c2 a3 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80106249:	83 c4 0c             	add    $0xc,%esp
8010624c:	ff 75 0c             	pushl  0xc(%ebp)
8010624f:	57                   	push   %edi
80106250:	ff 75 08             	pushl  0x8(%ebp)
80106253:	e8 d2 fe ff ff       	call   8010612a <deallocuvm>
      return 0;
80106258:	83 c4 10             	add    $0x10,%esp
8010625b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80106262:	eb 37                	jmp    8010629b <allocuvm+0xdf>
      cprintf("allocuvm out of memory (2)\n");
80106264:	83 ec 0c             	sub    $0xc,%esp
80106267:	68 e1 6e 10 80       	push   $0x80106ee1
8010626c:	e8 9a a3 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80106271:	83 c4 0c             	add    $0xc,%esp
80106274:	ff 75 0c             	pushl  0xc(%ebp)
80106277:	57                   	push   %edi
80106278:	ff 75 08             	pushl  0x8(%ebp)
8010627b:	e8 aa fe ff ff       	call   8010612a <deallocuvm>
      kfree(mem);
80106280:	89 34 24             	mov    %esi,(%esp)
80106283:	e8 1c bd ff ff       	call   80101fa4 <kfree>
      return 0;
80106288:	83 c4 10             	add    $0x10,%esp
8010628b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80106292:	eb 07                	jmp    8010629b <allocuvm+0xdf>
    return 0;
80106294:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
}
8010629b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010629e:	8d 65 f4             	lea    -0xc(%ebp),%esp
801062a1:	5b                   	pop    %ebx
801062a2:	5e                   	pop    %esi
801062a3:	5f                   	pop    %edi
801062a4:	5d                   	pop    %ebp
801062a5:	c3                   	ret    

801062a6 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
801062a6:	55                   	push   %ebp
801062a7:	89 e5                	mov    %esp,%ebp
801062a9:	56                   	push   %esi
801062aa:	53                   	push   %ebx
801062ab:	8b 75 08             	mov    0x8(%ebp),%esi
  uint i;

  if(pgdir == 0)
801062ae:	85 f6                	test   %esi,%esi
801062b0:	74 1a                	je     801062cc <freevm+0x26>
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
801062b2:	83 ec 04             	sub    $0x4,%esp
801062b5:	6a 00                	push   $0x0
801062b7:	68 00 00 00 80       	push   $0x80000000
801062bc:	56                   	push   %esi
801062bd:	e8 68 fe ff ff       	call   8010612a <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
801062c2:	83 c4 10             	add    $0x10,%esp
801062c5:	bb 00 00 00 00       	mov    $0x0,%ebx
801062ca:	eb 10                	jmp    801062dc <freevm+0x36>
    panic("freevm: no pgdir");
801062cc:	83 ec 0c             	sub    $0xc,%esp
801062cf:	68 fd 6e 10 80       	push   $0x80106efd
801062d4:	e8 6f a0 ff ff       	call   80100348 <panic>
  for(i = 0; i < NPDENTRIES; i++){
801062d9:	83 c3 01             	add    $0x1,%ebx
801062dc:	81 fb ff 03 00 00    	cmp    $0x3ff,%ebx
801062e2:	77 1f                	ja     80106303 <freevm+0x5d>
    if(pgdir[i] & PTE_P){
801062e4:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
801062e7:	a8 01                	test   $0x1,%al
801062e9:	74 ee                	je     801062d9 <freevm+0x33>
      char * v = P2V(PTE_ADDR(pgdir[i]));
801062eb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801062f0:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
801062f5:	83 ec 0c             	sub    $0xc,%esp
801062f8:	50                   	push   %eax
801062f9:	e8 a6 bc ff ff       	call   80101fa4 <kfree>
801062fe:	83 c4 10             	add    $0x10,%esp
80106301:	eb d6                	jmp    801062d9 <freevm+0x33>
    }
  }
  kfree((char*)pgdir);
80106303:	83 ec 0c             	sub    $0xc,%esp
80106306:	56                   	push   %esi
80106307:	e8 98 bc ff ff       	call   80101fa4 <kfree>
}
8010630c:	83 c4 10             	add    $0x10,%esp
8010630f:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106312:	5b                   	pop    %ebx
80106313:	5e                   	pop    %esi
80106314:	5d                   	pop    %ebp
80106315:	c3                   	ret    

80106316 <setupkvm>:
{
80106316:	55                   	push   %ebp
80106317:	89 e5                	mov    %esp,%ebp
80106319:	56                   	push   %esi
8010631a:	53                   	push   %ebx
  if((pgdir = (pde_t*)kalloc()) == 0)
8010631b:	e8 cc bd ff ff       	call   801020ec <kalloc>
80106320:	89 c6                	mov    %eax,%esi
80106322:	85 c0                	test   %eax,%eax
80106324:	74 55                	je     8010637b <setupkvm+0x65>
  memset(pgdir, 0, PGSIZE);
80106326:	83 ec 04             	sub    $0x4,%esp
80106329:	68 00 10 00 00       	push   $0x1000
8010632e:	6a 00                	push   $0x0
80106330:	50                   	push   %eax
80106331:	e8 e6 d9 ff ff       	call   80103d1c <memset>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80106336:	83 c4 10             	add    $0x10,%esp
80106339:	bb 20 94 10 80       	mov    $0x80109420,%ebx
8010633e:	81 fb 60 94 10 80    	cmp    $0x80109460,%ebx
80106344:	73 35                	jae    8010637b <setupkvm+0x65>
                (uint)k->phys_start, k->perm) < 0) {
80106346:	8b 43 04             	mov    0x4(%ebx),%eax
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
80106349:	8b 4b 08             	mov    0x8(%ebx),%ecx
8010634c:	29 c1                	sub    %eax,%ecx
8010634e:	83 ec 08             	sub    $0x8,%esp
80106351:	ff 73 0c             	pushl  0xc(%ebx)
80106354:	50                   	push   %eax
80106355:	8b 13                	mov    (%ebx),%edx
80106357:	89 f0                	mov    %esi,%eax
80106359:	e8 d7 f9 ff ff       	call   80105d35 <mappages>
8010635e:	83 c4 10             	add    $0x10,%esp
80106361:	85 c0                	test   %eax,%eax
80106363:	78 05                	js     8010636a <setupkvm+0x54>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80106365:	83 c3 10             	add    $0x10,%ebx
80106368:	eb d4                	jmp    8010633e <setupkvm+0x28>
      freevm(pgdir);
8010636a:	83 ec 0c             	sub    $0xc,%esp
8010636d:	56                   	push   %esi
8010636e:	e8 33 ff ff ff       	call   801062a6 <freevm>
      return 0;
80106373:	83 c4 10             	add    $0x10,%esp
80106376:	be 00 00 00 00       	mov    $0x0,%esi
}
8010637b:	89 f0                	mov    %esi,%eax
8010637d:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106380:	5b                   	pop    %ebx
80106381:	5e                   	pop    %esi
80106382:	5d                   	pop    %ebp
80106383:	c3                   	ret    

80106384 <kvmalloc>:
{
80106384:	55                   	push   %ebp
80106385:	89 e5                	mov    %esp,%ebp
80106387:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
8010638a:	e8 87 ff ff ff       	call   80106316 <setupkvm>
8010638f:	a3 c4 44 13 80       	mov    %eax,0x801344c4
  switchkvm();
80106394:	e8 5e fb ff ff       	call   80105ef7 <switchkvm>
}
80106399:	c9                   	leave  
8010639a:	c3                   	ret    

8010639b <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
8010639b:	55                   	push   %ebp
8010639c:	89 e5                	mov    %esp,%ebp
8010639e:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801063a1:	b9 00 00 00 00       	mov    $0x0,%ecx
801063a6:	8b 55 0c             	mov    0xc(%ebp),%edx
801063a9:	8b 45 08             	mov    0x8(%ebp),%eax
801063ac:	e8 14 f9 ff ff       	call   80105cc5 <walkpgdir>
  if(pte == 0)
801063b1:	85 c0                	test   %eax,%eax
801063b3:	74 05                	je     801063ba <clearpteu+0x1f>
    panic("clearpteu");
  *pte &= ~PTE_U;
801063b5:	83 20 fb             	andl   $0xfffffffb,(%eax)
}
801063b8:	c9                   	leave  
801063b9:	c3                   	ret    
    panic("clearpteu");
801063ba:	83 ec 0c             	sub    $0xc,%esp
801063bd:	68 0e 6f 10 80       	push   $0x80106f0e
801063c2:	e8 81 9f ff ff       	call   80100348 <panic>

801063c7 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
801063c7:	55                   	push   %ebp
801063c8:	89 e5                	mov    %esp,%ebp
801063ca:	57                   	push   %edi
801063cb:	56                   	push   %esi
801063cc:	53                   	push   %ebx
801063cd:	83 ec 1c             	sub    $0x1c,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
801063d0:	e8 41 ff ff ff       	call   80106316 <setupkvm>
801063d5:	89 45 dc             	mov    %eax,-0x24(%ebp)
801063d8:	85 c0                	test   %eax,%eax
801063da:	0f 84 c4 00 00 00    	je     801064a4 <copyuvm+0xdd>
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
801063e0:	bf 00 00 00 00       	mov    $0x0,%edi
801063e5:	3b 7d 0c             	cmp    0xc(%ebp),%edi
801063e8:	0f 83 b6 00 00 00    	jae    801064a4 <copyuvm+0xdd>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
801063ee:	89 7d e4             	mov    %edi,-0x1c(%ebp)
801063f1:	b9 00 00 00 00       	mov    $0x0,%ecx
801063f6:	89 fa                	mov    %edi,%edx
801063f8:	8b 45 08             	mov    0x8(%ebp),%eax
801063fb:	e8 c5 f8 ff ff       	call   80105cc5 <walkpgdir>
80106400:	85 c0                	test   %eax,%eax
80106402:	74 65                	je     80106469 <copyuvm+0xa2>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
80106404:	8b 00                	mov    (%eax),%eax
80106406:	a8 01                	test   $0x1,%al
80106408:	74 6c                	je     80106476 <copyuvm+0xaf>
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
8010640a:	89 c6                	mov    %eax,%esi
8010640c:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    flags = PTE_FLAGS(*pte);
80106412:	25 ff 0f 00 00       	and    $0xfff,%eax
80106417:	89 45 e0             	mov    %eax,-0x20(%ebp)
    if((mem = kalloc()) == 0)
8010641a:	e8 cd bc ff ff       	call   801020ec <kalloc>
8010641f:	89 c3                	mov    %eax,%ebx
80106421:	85 c0                	test   %eax,%eax
80106423:	74 6a                	je     8010648f <copyuvm+0xc8>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
80106425:	81 c6 00 00 00 80    	add    $0x80000000,%esi
8010642b:	83 ec 04             	sub    $0x4,%esp
8010642e:	68 00 10 00 00       	push   $0x1000
80106433:	56                   	push   %esi
80106434:	50                   	push   %eax
80106435:	e8 5d d9 ff ff       	call   80103d97 <memmove>
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0) {
8010643a:	83 c4 08             	add    $0x8,%esp
8010643d:	ff 75 e0             	pushl  -0x20(%ebp)
80106440:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80106446:	50                   	push   %eax
80106447:	b9 00 10 00 00       	mov    $0x1000,%ecx
8010644c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010644f:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106452:	e8 de f8 ff ff       	call   80105d35 <mappages>
80106457:	83 c4 10             	add    $0x10,%esp
8010645a:	85 c0                	test   %eax,%eax
8010645c:	78 25                	js     80106483 <copyuvm+0xbc>
  for(i = 0; i < sz; i += PGSIZE){
8010645e:	81 c7 00 10 00 00    	add    $0x1000,%edi
80106464:	e9 7c ff ff ff       	jmp    801063e5 <copyuvm+0x1e>
      panic("copyuvm: pte should exist");
80106469:	83 ec 0c             	sub    $0xc,%esp
8010646c:	68 18 6f 10 80       	push   $0x80106f18
80106471:	e8 d2 9e ff ff       	call   80100348 <panic>
      panic("copyuvm: page not present");
80106476:	83 ec 0c             	sub    $0xc,%esp
80106479:	68 32 6f 10 80       	push   $0x80106f32
8010647e:	e8 c5 9e ff ff       	call   80100348 <panic>
      kfree(mem);
80106483:	83 ec 0c             	sub    $0xc,%esp
80106486:	53                   	push   %ebx
80106487:	e8 18 bb ff ff       	call   80101fa4 <kfree>
      goto bad;
8010648c:	83 c4 10             	add    $0x10,%esp
    }
  }
  return d;

bad:
  freevm(d);
8010648f:	83 ec 0c             	sub    $0xc,%esp
80106492:	ff 75 dc             	pushl  -0x24(%ebp)
80106495:	e8 0c fe ff ff       	call   801062a6 <freevm>
  return 0;
8010649a:	83 c4 10             	add    $0x10,%esp
8010649d:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
}
801064a4:	8b 45 dc             	mov    -0x24(%ebp),%eax
801064a7:	8d 65 f4             	lea    -0xc(%ebp),%esp
801064aa:	5b                   	pop    %ebx
801064ab:	5e                   	pop    %esi
801064ac:	5f                   	pop    %edi
801064ad:	5d                   	pop    %ebp
801064ae:	c3                   	ret    

801064af <uva2ka>:

// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
801064af:	55                   	push   %ebp
801064b0:	89 e5                	mov    %esp,%ebp
801064b2:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801064b5:	b9 00 00 00 00       	mov    $0x0,%ecx
801064ba:	8b 55 0c             	mov    0xc(%ebp),%edx
801064bd:	8b 45 08             	mov    0x8(%ebp),%eax
801064c0:	e8 00 f8 ff ff       	call   80105cc5 <walkpgdir>
  if((*pte & PTE_P) == 0)
801064c5:	8b 00                	mov    (%eax),%eax
801064c7:	a8 01                	test   $0x1,%al
801064c9:	74 10                	je     801064db <uva2ka+0x2c>
    return 0;
  if((*pte & PTE_U) == 0)
801064cb:	a8 04                	test   $0x4,%al
801064cd:	74 13                	je     801064e2 <uva2ka+0x33>
    return 0;
  return (char*)P2V(PTE_ADDR(*pte));
801064cf:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801064d4:	05 00 00 00 80       	add    $0x80000000,%eax
}
801064d9:	c9                   	leave  
801064da:	c3                   	ret    
    return 0;
801064db:	b8 00 00 00 00       	mov    $0x0,%eax
801064e0:	eb f7                	jmp    801064d9 <uva2ka+0x2a>
    return 0;
801064e2:	b8 00 00 00 00       	mov    $0x0,%eax
801064e7:	eb f0                	jmp    801064d9 <uva2ka+0x2a>

801064e9 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801064e9:	55                   	push   %ebp
801064ea:	89 e5                	mov    %esp,%ebp
801064ec:	57                   	push   %edi
801064ed:	56                   	push   %esi
801064ee:	53                   	push   %ebx
801064ef:	83 ec 0c             	sub    $0xc,%esp
801064f2:	8b 7d 14             	mov    0x14(%ebp),%edi
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801064f5:	eb 25                	jmp    8010651c <copyout+0x33>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
801064f7:	8b 55 0c             	mov    0xc(%ebp),%edx
801064fa:	29 f2                	sub    %esi,%edx
801064fc:	01 d0                	add    %edx,%eax
801064fe:	83 ec 04             	sub    $0x4,%esp
80106501:	53                   	push   %ebx
80106502:	ff 75 10             	pushl  0x10(%ebp)
80106505:	50                   	push   %eax
80106506:	e8 8c d8 ff ff       	call   80103d97 <memmove>
    len -= n;
8010650b:	29 df                	sub    %ebx,%edi
    buf += n;
8010650d:	01 5d 10             	add    %ebx,0x10(%ebp)
    va = va0 + PGSIZE;
80106510:	8d 86 00 10 00 00    	lea    0x1000(%esi),%eax
80106516:	89 45 0c             	mov    %eax,0xc(%ebp)
80106519:	83 c4 10             	add    $0x10,%esp
  while(len > 0){
8010651c:	85 ff                	test   %edi,%edi
8010651e:	74 2f                	je     8010654f <copyout+0x66>
    va0 = (uint)PGROUNDDOWN(va);
80106520:	8b 75 0c             	mov    0xc(%ebp),%esi
80106523:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    pa0 = uva2ka(pgdir, (char*)va0);
80106529:	83 ec 08             	sub    $0x8,%esp
8010652c:	56                   	push   %esi
8010652d:	ff 75 08             	pushl  0x8(%ebp)
80106530:	e8 7a ff ff ff       	call   801064af <uva2ka>
    if(pa0 == 0)
80106535:	83 c4 10             	add    $0x10,%esp
80106538:	85 c0                	test   %eax,%eax
8010653a:	74 20                	je     8010655c <copyout+0x73>
    n = PGSIZE - (va - va0);
8010653c:	89 f3                	mov    %esi,%ebx
8010653e:	2b 5d 0c             	sub    0xc(%ebp),%ebx
80106541:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    if(n > len)
80106547:	39 df                	cmp    %ebx,%edi
80106549:	73 ac                	jae    801064f7 <copyout+0xe>
      n = len;
8010654b:	89 fb                	mov    %edi,%ebx
8010654d:	eb a8                	jmp    801064f7 <copyout+0xe>
  }
  return 0;
8010654f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106554:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106557:	5b                   	pop    %ebx
80106558:	5e                   	pop    %esi
80106559:	5f                   	pop    %edi
8010655a:	5d                   	pop    %ebp
8010655b:	c3                   	ret    
      return -1;
8010655c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106561:	eb f1                	jmp    80106554 <copyout+0x6b>
