
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
8010002d:	b8 8b 2b 10 80       	mov    $0x80102b8b,%eax
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
80100046:	e8 82 3c 00 00       	call   80103ccd <acquire>

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
8010007c:	e8 b1 3c 00 00       	call   80103d32 <release>
      acquiresleep(&b->lock);
80100081:	8d 43 0c             	lea    0xc(%ebx),%eax
80100084:	89 04 24             	mov    %eax,(%esp)
80100087:	e8 2d 3a 00 00       	call   80103ab9 <acquiresleep>
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
801000ca:	e8 63 3c 00 00       	call   80103d32 <release>
      acquiresleep(&b->lock);
801000cf:	8d 43 0c             	lea    0xc(%ebx),%eax
801000d2:	89 04 24             	mov    %eax,(%esp)
801000d5:	e8 df 39 00 00       	call   80103ab9 <acquiresleep>
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
801000ea:	68 00 66 10 80       	push   $0x80106600
801000ef:	e8 54 02 00 00       	call   80100348 <panic>

801000f4 <binit>:
{
801000f4:	55                   	push   %ebp
801000f5:	89 e5                	mov    %esp,%ebp
801000f7:	53                   	push   %ebx
801000f8:	83 ec 0c             	sub    $0xc,%esp
  initlock(&bcache.lock, "bcache");
801000fb:	68 11 66 10 80       	push   $0x80106611
80100100:	68 c0 a5 10 80       	push   $0x8010a5c0
80100105:	e8 87 3a 00 00       	call   80103b91 <initlock>
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
8010013a:	68 18 66 10 80       	push   $0x80106618
8010013f:	8d 43 0c             	lea    0xc(%ebx),%eax
80100142:	50                   	push   %eax
80100143:	e8 3e 39 00 00       	call   80103a86 <initsleeplock>
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
80100190:	e8 83 1c 00 00       	call   80101e18 <iderw>
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
801001a8:	e8 96 39 00 00       	call   80103b43 <holdingsleep>
801001ad:	83 c4 10             	add    $0x10,%esp
801001b0:	85 c0                	test   %eax,%eax
801001b2:	74 14                	je     801001c8 <bwrite+0x2e>
    panic("bwrite");
  b->flags |= B_DIRTY;
801001b4:	83 0b 04             	orl    $0x4,(%ebx)
  iderw(b);
801001b7:	83 ec 0c             	sub    $0xc,%esp
801001ba:	53                   	push   %ebx
801001bb:	e8 58 1c 00 00       	call   80101e18 <iderw>
}
801001c0:	83 c4 10             	add    $0x10,%esp
801001c3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801001c6:	c9                   	leave  
801001c7:	c3                   	ret    
    panic("bwrite");
801001c8:	83 ec 0c             	sub    $0xc,%esp
801001cb:	68 1f 66 10 80       	push   $0x8010661f
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
801001e4:	e8 5a 39 00 00       	call   80103b43 <holdingsleep>
801001e9:	83 c4 10             	add    $0x10,%esp
801001ec:	85 c0                	test   %eax,%eax
801001ee:	74 6b                	je     8010025b <brelse+0x86>
    panic("brelse");

  releasesleep(&b->lock);
801001f0:	83 ec 0c             	sub    $0xc,%esp
801001f3:	56                   	push   %esi
801001f4:	e8 0f 39 00 00       	call   80103b08 <releasesleep>

  acquire(&bcache.lock);
801001f9:	c7 04 24 c0 a5 10 80 	movl   $0x8010a5c0,(%esp)
80100200:	e8 c8 3a 00 00       	call   80103ccd <acquire>
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
8010024c:	e8 e1 3a 00 00       	call   80103d32 <release>
}
80100251:	83 c4 10             	add    $0x10,%esp
80100254:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100257:	5b                   	pop    %ebx
80100258:	5e                   	pop    %esi
80100259:	5d                   	pop    %ebp
8010025a:	c3                   	ret    
    panic("brelse");
8010025b:	83 ec 0c             	sub    $0xc,%esp
8010025e:	68 26 66 10 80       	push   $0x80106626
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
8010027b:	e8 cf 13 00 00       	call   8010164f <iunlock>
  target = n;
80100280:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  acquire(&cons.lock);
80100283:	c7 04 24 20 95 10 80 	movl   $0x80109520,(%esp)
8010028a:	e8 3e 3a 00 00       	call   80103ccd <acquire>
  while(n > 0){
8010028f:	83 c4 10             	add    $0x10,%esp
80100292:	85 db                	test   %ebx,%ebx
80100294:	0f 8e 8f 00 00 00    	jle    80100329 <consoleread+0xc1>
    while(input.r == input.w){
8010029a:	a1 a0 ef 10 80       	mov    0x8010efa0,%eax
8010029f:	3b 05 a4 ef 10 80    	cmp    0x8010efa4,%eax
801002a5:	75 47                	jne    801002ee <consoleread+0x86>
      if(myproc()->killed){
801002a7:	e8 7f 30 00 00       	call   8010332b <myproc>
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
801002bf:	e8 0e 35 00 00       	call   801037d2 <sleep>
801002c4:	83 c4 10             	add    $0x10,%esp
801002c7:	eb d1                	jmp    8010029a <consoleread+0x32>
        release(&cons.lock);
801002c9:	83 ec 0c             	sub    $0xc,%esp
801002cc:	68 20 95 10 80       	push   $0x80109520
801002d1:	e8 5c 3a 00 00       	call   80103d32 <release>
        ilock(ip);
801002d6:	89 3c 24             	mov    %edi,(%esp)
801002d9:	e8 af 12 00 00       	call   8010158d <ilock>
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
80100331:	e8 fc 39 00 00       	call   80103d32 <release>
  ilock(ip);
80100336:	89 3c 24             	mov    %edi,(%esp)
80100339:	e8 4f 12 00 00       	call   8010158d <ilock>
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
8010035a:	e8 41 21 00 00       	call   801024a0 <lapicid>
8010035f:	83 ec 08             	sub    $0x8,%esp
80100362:	50                   	push   %eax
80100363:	68 2d 66 10 80       	push   $0x8010662d
80100368:	e8 9e 02 00 00       	call   8010060b <cprintf>
  cprintf(s);
8010036d:	83 c4 04             	add    $0x4,%esp
80100370:	ff 75 08             	pushl  0x8(%ebp)
80100373:	e8 93 02 00 00       	call   8010060b <cprintf>
  cprintf("\n");
80100378:	c7 04 24 7b 6f 10 80 	movl   $0x80106f7b,(%esp)
8010037f:	e8 87 02 00 00       	call   8010060b <cprintf>
  getcallerpcs(&s, pcs);
80100384:	83 c4 08             	add    $0x8,%esp
80100387:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010038a:	50                   	push   %eax
8010038b:	8d 45 08             	lea    0x8(%ebp),%eax
8010038e:	50                   	push   %eax
8010038f:	e8 18 38 00 00       	call   80103bac <getcallerpcs>
  for(i=0; i<10; i++)
80100394:	83 c4 10             	add    $0x10,%esp
80100397:	bb 00 00 00 00       	mov    $0x0,%ebx
8010039c:	eb 17                	jmp    801003b5 <panic+0x6d>
    cprintf(" %p", pcs[i]);
8010039e:	83 ec 08             	sub    $0x8,%esp
801003a1:	ff 74 9d d0          	pushl  -0x30(%ebp,%ebx,4)
801003a5:	68 41 66 10 80       	push   $0x80106641
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
8010049e:	68 45 66 10 80       	push   $0x80106645
801004a3:	e8 a0 fe ff ff       	call   80100348 <panic>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801004a8:	83 ec 04             	sub    $0x4,%esp
801004ab:	68 60 0e 00 00       	push   $0xe60
801004b0:	68 a0 80 0b 80       	push   $0x800b80a0
801004b5:	68 00 80 0b 80       	push   $0x800b8000
801004ba:	e8 35 39 00 00       	call   80103df4 <memmove>
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
801004d9:	e8 9b 38 00 00       	call   80103d79 <memset>
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
80100506:	e8 b2 4c 00 00       	call   801051bd <uartputc>
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
8010051f:	e8 99 4c 00 00       	call   801051bd <uartputc>
80100524:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010052b:	e8 8d 4c 00 00       	call   801051bd <uartputc>
80100530:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100537:	e8 81 4c 00 00       	call   801051bd <uartputc>
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
80100576:	0f b6 92 70 66 10 80 	movzbl -0x7fef9990(%edx),%edx
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
801005be:	e8 8c 10 00 00       	call   8010164f <iunlock>
  acquire(&cons.lock);
801005c3:	c7 04 24 20 95 10 80 	movl   $0x80109520,(%esp)
801005ca:	e8 fe 36 00 00       	call   80103ccd <acquire>
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
801005f1:	e8 3c 37 00 00       	call   80103d32 <release>
  ilock(ip);
801005f6:	83 c4 04             	add    $0x4,%esp
801005f9:	ff 75 08             	pushl  0x8(%ebp)
801005fc:	e8 8c 0f 00 00       	call   8010158d <ilock>

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
80100638:	e8 90 36 00 00       	call   80103ccd <acquire>
8010063d:	83 c4 10             	add    $0x10,%esp
80100640:	eb de                	jmp    80100620 <cprintf+0x15>
    panic("null fmt");
80100642:	83 ec 0c             	sub    $0xc,%esp
80100645:	68 5f 66 10 80       	push   $0x8010665f
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
801006ee:	be 58 66 10 80       	mov    $0x80106658,%esi
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
80100734:	e8 f9 35 00 00       	call   80103d32 <release>
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
8010074f:	e8 79 35 00 00       	call   80103ccd <acquire>
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
801007de:	e8 54 31 00 00       	call   80103937 <wakeup>
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
80100873:	e8 ba 34 00 00       	call   80103d32 <release>
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
80100887:	e8 48 31 00 00       	call   801039d4 <procdump>
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
80100894:	68 68 66 10 80       	push   $0x80106668
80100899:	68 20 95 10 80       	push   $0x80109520
8010089e:	e8 ee 32 00 00       	call   80103b91 <initlock>

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
801008c8:	e8 bd 16 00 00       	call   80101f8a <ioapicenable>
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
801008de:	e8 48 2a 00 00       	call   8010332b <myproc>
801008e3:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)

  begin_op();
801008e9:	e8 e2 1f 00 00       	call   801028d0 <begin_op>

  if((ip = namei(path)) == 0){
801008ee:	83 ec 0c             	sub    $0xc,%esp
801008f1:	ff 75 08             	pushl  0x8(%ebp)
801008f4:	e8 f4 12 00 00       	call   80101bed <namei>
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
80100906:	e8 82 0c 00 00       	call   8010158d <ilock>
  pgdir = 0;

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) != sizeof(elf))
8010090b:	6a 34                	push   $0x34
8010090d:	6a 00                	push   $0x0
8010090f:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
80100915:	50                   	push   %eax
80100916:	53                   	push   %ebx
80100917:	e8 63 0e 00 00       	call   8010177f <readi>
8010091c:	83 c4 20             	add    $0x20,%esp
8010091f:	83 f8 34             	cmp    $0x34,%eax
80100922:	74 42                	je     80100966 <exec+0x94>
  return 0;

 bad:
  if(pgdir)
    freevm(pgdir);
  if(ip){
80100924:	85 db                	test   %ebx,%ebx
80100926:	0f 84 e9 02 00 00    	je     80100c15 <exec+0x343>
    iunlockput(ip);
8010092c:	83 ec 0c             	sub    $0xc,%esp
8010092f:	53                   	push   %ebx
80100930:	e8 ff 0d 00 00       	call   80101734 <iunlockput>
    end_op();
80100935:	e8 10 20 00 00       	call   8010294a <end_op>
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
8010094a:	e8 fb 1f 00 00       	call   8010294a <end_op>
    cprintf("exec: fail\n");
8010094f:	83 ec 0c             	sub    $0xc,%esp
80100952:	68 81 66 10 80       	push   $0x80106681
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
80100972:	e8 1c 5a 00 00       	call   80106393 <setupkvm>
80100977:	89 85 ec fe ff ff    	mov    %eax,-0x114(%ebp)
8010097d:	85 c0                	test   %eax,%eax
8010097f:	0f 84 12 01 00 00    	je     80100a97 <exec+0x1c5>
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
801009ac:	0f 8e 9e 00 00 00    	jle    80100a50 <exec+0x17e>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
801009b2:	89 85 f0 fe ff ff    	mov    %eax,-0x110(%ebp)
801009b8:	6a 20                	push   $0x20
801009ba:	50                   	push   %eax
801009bb:	8d 85 04 ff ff ff    	lea    -0xfc(%ebp),%eax
801009c1:	50                   	push   %eax
801009c2:	53                   	push   %ebx
801009c3:	e8 b7 0d 00 00       	call   8010177f <readi>
801009c8:	83 c4 10             	add    $0x10,%esp
801009cb:	83 f8 20             	cmp    $0x20,%eax
801009ce:	0f 85 c3 00 00 00    	jne    80100a97 <exec+0x1c5>
    if(ph.type != ELF_PROG_LOAD)
801009d4:	83 bd 04 ff ff ff 01 	cmpl   $0x1,-0xfc(%ebp)
801009db:	75 ba                	jne    80100997 <exec+0xc5>
    if(ph.memsz < ph.filesz)
801009dd:	8b 85 18 ff ff ff    	mov    -0xe8(%ebp),%eax
801009e3:	3b 85 14 ff ff ff    	cmp    -0xec(%ebp),%eax
801009e9:	0f 82 a8 00 00 00    	jb     80100a97 <exec+0x1c5>
    if(ph.vaddr + ph.memsz < ph.vaddr)
801009ef:	03 85 0c ff ff ff    	add    -0xf4(%ebp),%eax
801009f5:	0f 82 9c 00 00 00    	jb     80100a97 <exec+0x1c5>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz, curproc->pid)) == 0)
801009fb:	8b 8d f4 fe ff ff    	mov    -0x10c(%ebp),%ecx
80100a01:	ff 71 10             	pushl  0x10(%ecx)
80100a04:	50                   	push   %eax
80100a05:	57                   	push   %edi
80100a06:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a0c:	e8 1f 58 00 00       	call   80106230 <allocuvm>
80100a11:	89 c7                	mov    %eax,%edi
80100a13:	83 c4 10             	add    $0x10,%esp
80100a16:	85 c0                	test   %eax,%eax
80100a18:	74 7d                	je     80100a97 <exec+0x1c5>
    if(ph.vaddr % PGSIZE != 0)
80100a1a:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100a20:	a9 ff 0f 00 00       	test   $0xfff,%eax
80100a25:	75 70                	jne    80100a97 <exec+0x1c5>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100a27:	83 ec 0c             	sub    $0xc,%esp
80100a2a:	ff b5 14 ff ff ff    	pushl  -0xec(%ebp)
80100a30:	ff b5 08 ff ff ff    	pushl  -0xf8(%ebp)
80100a36:	53                   	push   %ebx
80100a37:	50                   	push   %eax
80100a38:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a3e:	e8 bb 56 00 00       	call   801060fe <loaduvm>
80100a43:	83 c4 20             	add    $0x20,%esp
80100a46:	85 c0                	test   %eax,%eax
80100a48:	0f 89 49 ff ff ff    	jns    80100997 <exec+0xc5>
 bad:
80100a4e:	eb 47                	jmp    80100a97 <exec+0x1c5>
  iunlockput(ip);
80100a50:	83 ec 0c             	sub    $0xc,%esp
80100a53:	53                   	push   %ebx
80100a54:	e8 db 0c 00 00       	call   80101734 <iunlockput>
  end_op();
80100a59:	e8 ec 1e 00 00       	call   8010294a <end_op>
  sz = PGROUNDUP(sz);
80100a5e:	8d 87 ff 0f 00 00    	lea    0xfff(%edi),%eax
80100a64:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE, curproc->pid)) == 0)
80100a69:	8b 8d f4 fe ff ff    	mov    -0x10c(%ebp),%ecx
80100a6f:	ff 71 10             	pushl  0x10(%ecx)
80100a72:	8d 90 00 20 00 00    	lea    0x2000(%eax),%edx
80100a78:	52                   	push   %edx
80100a79:	50                   	push   %eax
80100a7a:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a80:	e8 ab 57 00 00       	call   80106230 <allocuvm>
80100a85:	89 85 f0 fe ff ff    	mov    %eax,-0x110(%ebp)
80100a8b:	83 c4 20             	add    $0x20,%esp
80100a8e:	85 c0                	test   %eax,%eax
80100a90:	75 24                	jne    80100ab6 <exec+0x1e4>
  ip = 0;
80100a92:	bb 00 00 00 00       	mov    $0x0,%ebx
  if(pgdir)
80100a97:	8b 85 ec fe ff ff    	mov    -0x114(%ebp),%eax
80100a9d:	85 c0                	test   %eax,%eax
80100a9f:	0f 84 7f fe ff ff    	je     80100924 <exec+0x52>
    freevm(pgdir);
80100aa5:	83 ec 0c             	sub    $0xc,%esp
80100aa8:	50                   	push   %eax
80100aa9:	e8 75 58 00 00       	call   80106323 <freevm>
80100aae:	83 c4 10             	add    $0x10,%esp
80100ab1:	e9 6e fe ff ff       	jmp    80100924 <exec+0x52>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100ab6:	89 c7                	mov    %eax,%edi
80100ab8:	8d 80 00 e0 ff ff    	lea    -0x2000(%eax),%eax
80100abe:	83 ec 08             	sub    $0x8,%esp
80100ac1:	50                   	push   %eax
80100ac2:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100ac8:	e8 53 59 00 00       	call   80106420 <clearpteu>
  for(argc = 0; argv[argc]; argc++) {
80100acd:	83 c4 10             	add    $0x10,%esp
80100ad0:	be 00 00 00 00       	mov    $0x0,%esi
80100ad5:	8b 45 0c             	mov    0xc(%ebp),%eax
80100ad8:	8d 1c b0             	lea    (%eax,%esi,4),%ebx
80100adb:	8b 03                	mov    (%ebx),%eax
80100add:	85 c0                	test   %eax,%eax
80100adf:	74 4d                	je     80100b2e <exec+0x25c>
    if(argc >= MAXARG)
80100ae1:	83 fe 1f             	cmp    $0x1f,%esi
80100ae4:	0f 87 0d 01 00 00    	ja     80100bf7 <exec+0x325>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100aea:	83 ec 0c             	sub    $0xc,%esp
80100aed:	50                   	push   %eax
80100aee:	e8 28 34 00 00       	call   80103f1b <strlen>
80100af3:	29 c7                	sub    %eax,%edi
80100af5:	83 ef 01             	sub    $0x1,%edi
80100af8:	83 e7 fc             	and    $0xfffffffc,%edi
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100afb:	83 c4 04             	add    $0x4,%esp
80100afe:	ff 33                	pushl  (%ebx)
80100b00:	e8 16 34 00 00       	call   80103f1b <strlen>
80100b05:	83 c0 01             	add    $0x1,%eax
80100b08:	50                   	push   %eax
80100b09:	ff 33                	pushl  (%ebx)
80100b0b:	57                   	push   %edi
80100b0c:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b12:	e8 64 5a 00 00       	call   8010657b <copyout>
80100b17:	83 c4 20             	add    $0x20,%esp
80100b1a:	85 c0                	test   %eax,%eax
80100b1c:	0f 88 df 00 00 00    	js     80100c01 <exec+0x32f>
    ustack[3+argc] = sp;
80100b22:	89 bc b5 64 ff ff ff 	mov    %edi,-0x9c(%ebp,%esi,4)
  for(argc = 0; argv[argc]; argc++) {
80100b29:	83 c6 01             	add    $0x1,%esi
80100b2c:	eb a7                	jmp    80100ad5 <exec+0x203>
  ustack[3+argc] = 0;
80100b2e:	c7 84 b5 64 ff ff ff 	movl   $0x0,-0x9c(%ebp,%esi,4)
80100b35:	00 00 00 00 
  ustack[0] = 0xffffffff;  // fake return PC
80100b39:	c7 85 58 ff ff ff ff 	movl   $0xffffffff,-0xa8(%ebp)
80100b40:	ff ff ff 
  ustack[1] = argc;
80100b43:	89 b5 5c ff ff ff    	mov    %esi,-0xa4(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100b49:	8d 04 b5 04 00 00 00 	lea    0x4(,%esi,4),%eax
80100b50:	89 f9                	mov    %edi,%ecx
80100b52:	29 c1                	sub    %eax,%ecx
80100b54:	89 8d 60 ff ff ff    	mov    %ecx,-0xa0(%ebp)
  sp -= (3+argc+1) * 4;
80100b5a:	8d 04 b5 10 00 00 00 	lea    0x10(,%esi,4),%eax
80100b61:	29 c7                	sub    %eax,%edi
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100b63:	50                   	push   %eax
80100b64:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
80100b6a:	50                   	push   %eax
80100b6b:	57                   	push   %edi
80100b6c:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b72:	e8 04 5a 00 00       	call   8010657b <copyout>
80100b77:	83 c4 10             	add    $0x10,%esp
80100b7a:	85 c0                	test   %eax,%eax
80100b7c:	0f 88 89 00 00 00    	js     80100c0b <exec+0x339>
  for(last=s=path; *s; s++)
80100b82:	8b 55 08             	mov    0x8(%ebp),%edx
80100b85:	89 d0                	mov    %edx,%eax
80100b87:	eb 03                	jmp    80100b8c <exec+0x2ba>
80100b89:	83 c0 01             	add    $0x1,%eax
80100b8c:	0f b6 08             	movzbl (%eax),%ecx
80100b8f:	84 c9                	test   %cl,%cl
80100b91:	74 0a                	je     80100b9d <exec+0x2cb>
    if(*s == '/')
80100b93:	80 f9 2f             	cmp    $0x2f,%cl
80100b96:	75 f1                	jne    80100b89 <exec+0x2b7>
      last = s+1;
80100b98:	8d 50 01             	lea    0x1(%eax),%edx
80100b9b:	eb ec                	jmp    80100b89 <exec+0x2b7>
  safestrcpy(curproc->name, last, sizeof(curproc->name));
80100b9d:	8b b5 f4 fe ff ff    	mov    -0x10c(%ebp),%esi
80100ba3:	89 f0                	mov    %esi,%eax
80100ba5:	83 c0 6c             	add    $0x6c,%eax
80100ba8:	83 ec 04             	sub    $0x4,%esp
80100bab:	6a 10                	push   $0x10
80100bad:	52                   	push   %edx
80100bae:	50                   	push   %eax
80100baf:	e8 2c 33 00 00       	call   80103ee0 <safestrcpy>
  oldpgdir = curproc->pgdir;
80100bb4:	8b 5e 04             	mov    0x4(%esi),%ebx
  curproc->pgdir = pgdir;
80100bb7:	8b 8d ec fe ff ff    	mov    -0x114(%ebp),%ecx
80100bbd:	89 4e 04             	mov    %ecx,0x4(%esi)
  curproc->sz = sz;
80100bc0:	8b 8d f0 fe ff ff    	mov    -0x110(%ebp),%ecx
80100bc6:	89 0e                	mov    %ecx,(%esi)
  curproc->tf->eip = elf.entry;  // main
80100bc8:	8b 46 18             	mov    0x18(%esi),%eax
80100bcb:	8b 95 3c ff ff ff    	mov    -0xc4(%ebp),%edx
80100bd1:	89 50 38             	mov    %edx,0x38(%eax)
  curproc->tf->esp = sp;
80100bd4:	8b 46 18             	mov    0x18(%esi),%eax
80100bd7:	89 78 44             	mov    %edi,0x44(%eax)
  switchuvm(curproc);
80100bda:	89 34 24             	mov    %esi,(%esp)
80100bdd:	e8 96 53 00 00       	call   80105f78 <switchuvm>
  freevm(oldpgdir);
80100be2:	89 1c 24             	mov    %ebx,(%esp)
80100be5:	e8 39 57 00 00       	call   80106323 <freevm>
  return 0;
80100bea:	83 c4 10             	add    $0x10,%esp
80100bed:	b8 00 00 00 00       	mov    $0x0,%eax
80100bf2:	e9 4b fd ff ff       	jmp    80100942 <exec+0x70>
  ip = 0;
80100bf7:	bb 00 00 00 00       	mov    $0x0,%ebx
80100bfc:	e9 96 fe ff ff       	jmp    80100a97 <exec+0x1c5>
80100c01:	bb 00 00 00 00       	mov    $0x0,%ebx
80100c06:	e9 8c fe ff ff       	jmp    80100a97 <exec+0x1c5>
80100c0b:	bb 00 00 00 00       	mov    $0x0,%ebx
80100c10:	e9 82 fe ff ff       	jmp    80100a97 <exec+0x1c5>
  return -1;
80100c15:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100c1a:	e9 23 fd ff ff       	jmp    80100942 <exec+0x70>

80100c1f <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80100c1f:	55                   	push   %ebp
80100c20:	89 e5                	mov    %esp,%ebp
80100c22:	83 ec 10             	sub    $0x10,%esp
  initlock(&ftable.lock, "ftable");
80100c25:	68 8d 66 10 80       	push   $0x8010668d
80100c2a:	68 c0 ef 10 80       	push   $0x8010efc0
80100c2f:	e8 5d 2f 00 00       	call   80103b91 <initlock>
}
80100c34:	83 c4 10             	add    $0x10,%esp
80100c37:	c9                   	leave  
80100c38:	c3                   	ret    

80100c39 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80100c39:	55                   	push   %ebp
80100c3a:	89 e5                	mov    %esp,%ebp
80100c3c:	53                   	push   %ebx
80100c3d:	83 ec 10             	sub    $0x10,%esp
  struct file *f;

  acquire(&ftable.lock);
80100c40:	68 c0 ef 10 80       	push   $0x8010efc0
80100c45:	e8 83 30 00 00       	call   80103ccd <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100c4a:	83 c4 10             	add    $0x10,%esp
80100c4d:	bb f4 ef 10 80       	mov    $0x8010eff4,%ebx
80100c52:	81 fb 54 f9 10 80    	cmp    $0x8010f954,%ebx
80100c58:	73 29                	jae    80100c83 <filealloc+0x4a>
    if(f->ref == 0){
80100c5a:	83 7b 04 00          	cmpl   $0x0,0x4(%ebx)
80100c5e:	74 05                	je     80100c65 <filealloc+0x2c>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100c60:	83 c3 18             	add    $0x18,%ebx
80100c63:	eb ed                	jmp    80100c52 <filealloc+0x19>
      f->ref = 1;
80100c65:	c7 43 04 01 00 00 00 	movl   $0x1,0x4(%ebx)
      release(&ftable.lock);
80100c6c:	83 ec 0c             	sub    $0xc,%esp
80100c6f:	68 c0 ef 10 80       	push   $0x8010efc0
80100c74:	e8 b9 30 00 00       	call   80103d32 <release>
      return f;
80100c79:	83 c4 10             	add    $0x10,%esp
    }
  }
  release(&ftable.lock);
  return 0;
}
80100c7c:	89 d8                	mov    %ebx,%eax
80100c7e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100c81:	c9                   	leave  
80100c82:	c3                   	ret    
  release(&ftable.lock);
80100c83:	83 ec 0c             	sub    $0xc,%esp
80100c86:	68 c0 ef 10 80       	push   $0x8010efc0
80100c8b:	e8 a2 30 00 00       	call   80103d32 <release>
  return 0;
80100c90:	83 c4 10             	add    $0x10,%esp
80100c93:	bb 00 00 00 00       	mov    $0x0,%ebx
80100c98:	eb e2                	jmp    80100c7c <filealloc+0x43>

80100c9a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80100c9a:	55                   	push   %ebp
80100c9b:	89 e5                	mov    %esp,%ebp
80100c9d:	53                   	push   %ebx
80100c9e:	83 ec 10             	sub    $0x10,%esp
80100ca1:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&ftable.lock);
80100ca4:	68 c0 ef 10 80       	push   $0x8010efc0
80100ca9:	e8 1f 30 00 00       	call   80103ccd <acquire>
  if(f->ref < 1)
80100cae:	8b 43 04             	mov    0x4(%ebx),%eax
80100cb1:	83 c4 10             	add    $0x10,%esp
80100cb4:	85 c0                	test   %eax,%eax
80100cb6:	7e 1a                	jle    80100cd2 <filedup+0x38>
    panic("filedup");
  f->ref++;
80100cb8:	83 c0 01             	add    $0x1,%eax
80100cbb:	89 43 04             	mov    %eax,0x4(%ebx)
  release(&ftable.lock);
80100cbe:	83 ec 0c             	sub    $0xc,%esp
80100cc1:	68 c0 ef 10 80       	push   $0x8010efc0
80100cc6:	e8 67 30 00 00       	call   80103d32 <release>
  return f;
}
80100ccb:	89 d8                	mov    %ebx,%eax
80100ccd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100cd0:	c9                   	leave  
80100cd1:	c3                   	ret    
    panic("filedup");
80100cd2:	83 ec 0c             	sub    $0xc,%esp
80100cd5:	68 94 66 10 80       	push   $0x80106694
80100cda:	e8 69 f6 ff ff       	call   80100348 <panic>

80100cdf <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
80100cdf:	55                   	push   %ebp
80100ce0:	89 e5                	mov    %esp,%ebp
80100ce2:	53                   	push   %ebx
80100ce3:	83 ec 30             	sub    $0x30,%esp
80100ce6:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct file ff;

  acquire(&ftable.lock);
80100ce9:	68 c0 ef 10 80       	push   $0x8010efc0
80100cee:	e8 da 2f 00 00       	call   80103ccd <acquire>
  if(f->ref < 1)
80100cf3:	8b 43 04             	mov    0x4(%ebx),%eax
80100cf6:	83 c4 10             	add    $0x10,%esp
80100cf9:	85 c0                	test   %eax,%eax
80100cfb:	7e 1f                	jle    80100d1c <fileclose+0x3d>
    panic("fileclose");
  if(--f->ref > 0){
80100cfd:	83 e8 01             	sub    $0x1,%eax
80100d00:	89 43 04             	mov    %eax,0x4(%ebx)
80100d03:	85 c0                	test   %eax,%eax
80100d05:	7e 22                	jle    80100d29 <fileclose+0x4a>
    release(&ftable.lock);
80100d07:	83 ec 0c             	sub    $0xc,%esp
80100d0a:	68 c0 ef 10 80       	push   $0x8010efc0
80100d0f:	e8 1e 30 00 00       	call   80103d32 <release>
    return;
80100d14:	83 c4 10             	add    $0x10,%esp
  else if(ff.type == FD_INODE){
    begin_op();
    iput(ff.ip);
    end_op();
  }
}
80100d17:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100d1a:	c9                   	leave  
80100d1b:	c3                   	ret    
    panic("fileclose");
80100d1c:	83 ec 0c             	sub    $0xc,%esp
80100d1f:	68 9c 66 10 80       	push   $0x8010669c
80100d24:	e8 1f f6 ff ff       	call   80100348 <panic>
  ff = *f;
80100d29:	8b 03                	mov    (%ebx),%eax
80100d2b:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100d2e:	8b 43 08             	mov    0x8(%ebx),%eax
80100d31:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100d34:	8b 43 0c             	mov    0xc(%ebx),%eax
80100d37:	89 45 ec             	mov    %eax,-0x14(%ebp)
80100d3a:	8b 43 10             	mov    0x10(%ebx),%eax
80100d3d:	89 45 f0             	mov    %eax,-0x10(%ebp)
  f->ref = 0;
80100d40:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
  f->type = FD_NONE;
80100d47:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  release(&ftable.lock);
80100d4d:	83 ec 0c             	sub    $0xc,%esp
80100d50:	68 c0 ef 10 80       	push   $0x8010efc0
80100d55:	e8 d8 2f 00 00       	call   80103d32 <release>
  if(ff.type == FD_PIPE)
80100d5a:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d5d:	83 c4 10             	add    $0x10,%esp
80100d60:	83 f8 01             	cmp    $0x1,%eax
80100d63:	74 1f                	je     80100d84 <fileclose+0xa5>
  else if(ff.type == FD_INODE){
80100d65:	83 f8 02             	cmp    $0x2,%eax
80100d68:	75 ad                	jne    80100d17 <fileclose+0x38>
    begin_op();
80100d6a:	e8 61 1b 00 00       	call   801028d0 <begin_op>
    iput(ff.ip);
80100d6f:	83 ec 0c             	sub    $0xc,%esp
80100d72:	ff 75 f0             	pushl  -0x10(%ebp)
80100d75:	e8 1a 09 00 00       	call   80101694 <iput>
    end_op();
80100d7a:	e8 cb 1b 00 00       	call   8010294a <end_op>
80100d7f:	83 c4 10             	add    $0x10,%esp
80100d82:	eb 93                	jmp    80100d17 <fileclose+0x38>
    pipeclose(ff.pipe, ff.writable);
80100d84:	83 ec 08             	sub    $0x8,%esp
80100d87:	0f be 45 e9          	movsbl -0x17(%ebp),%eax
80100d8b:	50                   	push   %eax
80100d8c:	ff 75 ec             	pushl  -0x14(%ebp)
80100d8f:	e8 bd 21 00 00       	call   80102f51 <pipeclose>
80100d94:	83 c4 10             	add    $0x10,%esp
80100d97:	e9 7b ff ff ff       	jmp    80100d17 <fileclose+0x38>

80100d9c <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
80100d9c:	55                   	push   %ebp
80100d9d:	89 e5                	mov    %esp,%ebp
80100d9f:	53                   	push   %ebx
80100da0:	83 ec 04             	sub    $0x4,%esp
80100da3:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(f->type == FD_INODE){
80100da6:	83 3b 02             	cmpl   $0x2,(%ebx)
80100da9:	75 31                	jne    80100ddc <filestat+0x40>
    ilock(f->ip);
80100dab:	83 ec 0c             	sub    $0xc,%esp
80100dae:	ff 73 10             	pushl  0x10(%ebx)
80100db1:	e8 d7 07 00 00       	call   8010158d <ilock>
    stati(f->ip, st);
80100db6:	83 c4 08             	add    $0x8,%esp
80100db9:	ff 75 0c             	pushl  0xc(%ebp)
80100dbc:	ff 73 10             	pushl  0x10(%ebx)
80100dbf:	e8 90 09 00 00       	call   80101754 <stati>
    iunlock(f->ip);
80100dc4:	83 c4 04             	add    $0x4,%esp
80100dc7:	ff 73 10             	pushl  0x10(%ebx)
80100dca:	e8 80 08 00 00       	call   8010164f <iunlock>
    return 0;
80100dcf:	83 c4 10             	add    $0x10,%esp
80100dd2:	b8 00 00 00 00       	mov    $0x0,%eax
  }
  return -1;
}
80100dd7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100dda:	c9                   	leave  
80100ddb:	c3                   	ret    
  return -1;
80100ddc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100de1:	eb f4                	jmp    80100dd7 <filestat+0x3b>

80100de3 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
80100de3:	55                   	push   %ebp
80100de4:	89 e5                	mov    %esp,%ebp
80100de6:	56                   	push   %esi
80100de7:	53                   	push   %ebx
80100de8:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;

  if(f->readable == 0)
80100deb:	80 7b 08 00          	cmpb   $0x0,0x8(%ebx)
80100def:	74 70                	je     80100e61 <fileread+0x7e>
    return -1;
  if(f->type == FD_PIPE)
80100df1:	8b 03                	mov    (%ebx),%eax
80100df3:	83 f8 01             	cmp    $0x1,%eax
80100df6:	74 44                	je     80100e3c <fileread+0x59>
    return piperead(f->pipe, addr, n);
  if(f->type == FD_INODE){
80100df8:	83 f8 02             	cmp    $0x2,%eax
80100dfb:	75 57                	jne    80100e54 <fileread+0x71>
    ilock(f->ip);
80100dfd:	83 ec 0c             	sub    $0xc,%esp
80100e00:	ff 73 10             	pushl  0x10(%ebx)
80100e03:	e8 85 07 00 00       	call   8010158d <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
80100e08:	ff 75 10             	pushl  0x10(%ebp)
80100e0b:	ff 73 14             	pushl  0x14(%ebx)
80100e0e:	ff 75 0c             	pushl  0xc(%ebp)
80100e11:	ff 73 10             	pushl  0x10(%ebx)
80100e14:	e8 66 09 00 00       	call   8010177f <readi>
80100e19:	89 c6                	mov    %eax,%esi
80100e1b:	83 c4 20             	add    $0x20,%esp
80100e1e:	85 c0                	test   %eax,%eax
80100e20:	7e 03                	jle    80100e25 <fileread+0x42>
      f->off += r;
80100e22:	01 43 14             	add    %eax,0x14(%ebx)
    iunlock(f->ip);
80100e25:	83 ec 0c             	sub    $0xc,%esp
80100e28:	ff 73 10             	pushl  0x10(%ebx)
80100e2b:	e8 1f 08 00 00       	call   8010164f <iunlock>
    return r;
80100e30:	83 c4 10             	add    $0x10,%esp
  }
  panic("fileread");
}
80100e33:	89 f0                	mov    %esi,%eax
80100e35:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100e38:	5b                   	pop    %ebx
80100e39:	5e                   	pop    %esi
80100e3a:	5d                   	pop    %ebp
80100e3b:	c3                   	ret    
    return piperead(f->pipe, addr, n);
80100e3c:	83 ec 04             	sub    $0x4,%esp
80100e3f:	ff 75 10             	pushl  0x10(%ebp)
80100e42:	ff 75 0c             	pushl  0xc(%ebp)
80100e45:	ff 73 0c             	pushl  0xc(%ebx)
80100e48:	e8 5c 22 00 00       	call   801030a9 <piperead>
80100e4d:	89 c6                	mov    %eax,%esi
80100e4f:	83 c4 10             	add    $0x10,%esp
80100e52:	eb df                	jmp    80100e33 <fileread+0x50>
  panic("fileread");
80100e54:	83 ec 0c             	sub    $0xc,%esp
80100e57:	68 a6 66 10 80       	push   $0x801066a6
80100e5c:	e8 e7 f4 ff ff       	call   80100348 <panic>
    return -1;
80100e61:	be ff ff ff ff       	mov    $0xffffffff,%esi
80100e66:	eb cb                	jmp    80100e33 <fileread+0x50>

80100e68 <filewrite>:

// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
80100e68:	55                   	push   %ebp
80100e69:	89 e5                	mov    %esp,%ebp
80100e6b:	57                   	push   %edi
80100e6c:	56                   	push   %esi
80100e6d:	53                   	push   %ebx
80100e6e:	83 ec 1c             	sub    $0x1c,%esp
80100e71:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;

  if(f->writable == 0)
80100e74:	80 7b 09 00          	cmpb   $0x0,0x9(%ebx)
80100e78:	0f 84 c5 00 00 00    	je     80100f43 <filewrite+0xdb>
    return -1;
  if(f->type == FD_PIPE)
80100e7e:	8b 03                	mov    (%ebx),%eax
80100e80:	83 f8 01             	cmp    $0x1,%eax
80100e83:	74 10                	je     80100e95 <filewrite+0x2d>
    return pipewrite(f->pipe, addr, n);
  if(f->type == FD_INODE){
80100e85:	83 f8 02             	cmp    $0x2,%eax
80100e88:	0f 85 a8 00 00 00    	jne    80100f36 <filewrite+0xce>
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * 512;
    int i = 0;
80100e8e:	bf 00 00 00 00       	mov    $0x0,%edi
80100e93:	eb 67                	jmp    80100efc <filewrite+0x94>
    return pipewrite(f->pipe, addr, n);
80100e95:	83 ec 04             	sub    $0x4,%esp
80100e98:	ff 75 10             	pushl  0x10(%ebp)
80100e9b:	ff 75 0c             	pushl  0xc(%ebp)
80100e9e:	ff 73 0c             	pushl  0xc(%ebx)
80100ea1:	e8 37 21 00 00       	call   80102fdd <pipewrite>
80100ea6:	83 c4 10             	add    $0x10,%esp
80100ea9:	e9 80 00 00 00       	jmp    80100f2e <filewrite+0xc6>
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
80100eae:	e8 1d 1a 00 00       	call   801028d0 <begin_op>
      ilock(f->ip);
80100eb3:	83 ec 0c             	sub    $0xc,%esp
80100eb6:	ff 73 10             	pushl  0x10(%ebx)
80100eb9:	e8 cf 06 00 00       	call   8010158d <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
80100ebe:	89 f8                	mov    %edi,%eax
80100ec0:	03 45 0c             	add    0xc(%ebp),%eax
80100ec3:	ff 75 e4             	pushl  -0x1c(%ebp)
80100ec6:	ff 73 14             	pushl  0x14(%ebx)
80100ec9:	50                   	push   %eax
80100eca:	ff 73 10             	pushl  0x10(%ebx)
80100ecd:	e8 aa 09 00 00       	call   8010187c <writei>
80100ed2:	89 c6                	mov    %eax,%esi
80100ed4:	83 c4 20             	add    $0x20,%esp
80100ed7:	85 c0                	test   %eax,%eax
80100ed9:	7e 03                	jle    80100ede <filewrite+0x76>
        f->off += r;
80100edb:	01 43 14             	add    %eax,0x14(%ebx)
      iunlock(f->ip);
80100ede:	83 ec 0c             	sub    $0xc,%esp
80100ee1:	ff 73 10             	pushl  0x10(%ebx)
80100ee4:	e8 66 07 00 00       	call   8010164f <iunlock>
      end_op();
80100ee9:	e8 5c 1a 00 00       	call   8010294a <end_op>

      if(r < 0)
80100eee:	83 c4 10             	add    $0x10,%esp
80100ef1:	85 f6                	test   %esi,%esi
80100ef3:	78 31                	js     80100f26 <filewrite+0xbe>
        break;
      if(r != n1)
80100ef5:	39 75 e4             	cmp    %esi,-0x1c(%ebp)
80100ef8:	75 1f                	jne    80100f19 <filewrite+0xb1>
        panic("short filewrite");
      i += r;
80100efa:	01 f7                	add    %esi,%edi
    while(i < n){
80100efc:	3b 7d 10             	cmp    0x10(%ebp),%edi
80100eff:	7d 25                	jge    80100f26 <filewrite+0xbe>
      int n1 = n - i;
80100f01:	8b 45 10             	mov    0x10(%ebp),%eax
80100f04:	29 f8                	sub    %edi,%eax
80100f06:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      if(n1 > max)
80100f09:	3d 00 06 00 00       	cmp    $0x600,%eax
80100f0e:	7e 9e                	jle    80100eae <filewrite+0x46>
        n1 = max;
80100f10:	c7 45 e4 00 06 00 00 	movl   $0x600,-0x1c(%ebp)
80100f17:	eb 95                	jmp    80100eae <filewrite+0x46>
        panic("short filewrite");
80100f19:	83 ec 0c             	sub    $0xc,%esp
80100f1c:	68 af 66 10 80       	push   $0x801066af
80100f21:	e8 22 f4 ff ff       	call   80100348 <panic>
    }
    return i == n ? n : -1;
80100f26:	3b 7d 10             	cmp    0x10(%ebp),%edi
80100f29:	75 1f                	jne    80100f4a <filewrite+0xe2>
80100f2b:	8b 45 10             	mov    0x10(%ebp),%eax
  }
  panic("filewrite");
}
80100f2e:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100f31:	5b                   	pop    %ebx
80100f32:	5e                   	pop    %esi
80100f33:	5f                   	pop    %edi
80100f34:	5d                   	pop    %ebp
80100f35:	c3                   	ret    
  panic("filewrite");
80100f36:	83 ec 0c             	sub    $0xc,%esp
80100f39:	68 b5 66 10 80       	push   $0x801066b5
80100f3e:	e8 05 f4 ff ff       	call   80100348 <panic>
    return -1;
80100f43:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100f48:	eb e4                	jmp    80100f2e <filewrite+0xc6>
    return i == n ? n : -1;
80100f4a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100f4f:	eb dd                	jmp    80100f2e <filewrite+0xc6>

80100f51 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
80100f51:	55                   	push   %ebp
80100f52:	89 e5                	mov    %esp,%ebp
80100f54:	57                   	push   %edi
80100f55:	56                   	push   %esi
80100f56:	53                   	push   %ebx
80100f57:	83 ec 0c             	sub    $0xc,%esp
80100f5a:	89 d7                	mov    %edx,%edi
  char *s;
  int len;

  while(*path == '/')
80100f5c:	eb 03                	jmp    80100f61 <skipelem+0x10>
    path++;
80100f5e:	83 c0 01             	add    $0x1,%eax
  while(*path == '/')
80100f61:	0f b6 10             	movzbl (%eax),%edx
80100f64:	80 fa 2f             	cmp    $0x2f,%dl
80100f67:	74 f5                	je     80100f5e <skipelem+0xd>
  if(*path == 0)
80100f69:	84 d2                	test   %dl,%dl
80100f6b:	74 59                	je     80100fc6 <skipelem+0x75>
80100f6d:	89 c3                	mov    %eax,%ebx
80100f6f:	eb 03                	jmp    80100f74 <skipelem+0x23>
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
    path++;
80100f71:	83 c3 01             	add    $0x1,%ebx
  while(*path != '/' && *path != 0)
80100f74:	0f b6 13             	movzbl (%ebx),%edx
80100f77:	80 fa 2f             	cmp    $0x2f,%dl
80100f7a:	0f 95 c1             	setne  %cl
80100f7d:	84 d2                	test   %dl,%dl
80100f7f:	0f 95 c2             	setne  %dl
80100f82:	84 d1                	test   %dl,%cl
80100f84:	75 eb                	jne    80100f71 <skipelem+0x20>
  len = path - s;
80100f86:	89 de                	mov    %ebx,%esi
80100f88:	29 c6                	sub    %eax,%esi
  if(len >= DIRSIZ)
80100f8a:	83 fe 0d             	cmp    $0xd,%esi
80100f8d:	7e 11                	jle    80100fa0 <skipelem+0x4f>
    memmove(name, s, DIRSIZ);
80100f8f:	83 ec 04             	sub    $0x4,%esp
80100f92:	6a 0e                	push   $0xe
80100f94:	50                   	push   %eax
80100f95:	57                   	push   %edi
80100f96:	e8 59 2e 00 00       	call   80103df4 <memmove>
80100f9b:	83 c4 10             	add    $0x10,%esp
80100f9e:	eb 17                	jmp    80100fb7 <skipelem+0x66>
  else {
    memmove(name, s, len);
80100fa0:	83 ec 04             	sub    $0x4,%esp
80100fa3:	56                   	push   %esi
80100fa4:	50                   	push   %eax
80100fa5:	57                   	push   %edi
80100fa6:	e8 49 2e 00 00       	call   80103df4 <memmove>
    name[len] = 0;
80100fab:	c6 04 37 00          	movb   $0x0,(%edi,%esi,1)
80100faf:	83 c4 10             	add    $0x10,%esp
80100fb2:	eb 03                	jmp    80100fb7 <skipelem+0x66>
  }
  while(*path == '/')
    path++;
80100fb4:	83 c3 01             	add    $0x1,%ebx
  while(*path == '/')
80100fb7:	80 3b 2f             	cmpb   $0x2f,(%ebx)
80100fba:	74 f8                	je     80100fb4 <skipelem+0x63>
  return path;
}
80100fbc:	89 d8                	mov    %ebx,%eax
80100fbe:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100fc1:	5b                   	pop    %ebx
80100fc2:	5e                   	pop    %esi
80100fc3:	5f                   	pop    %edi
80100fc4:	5d                   	pop    %ebp
80100fc5:	c3                   	ret    
    return 0;
80100fc6:	bb 00 00 00 00       	mov    $0x0,%ebx
80100fcb:	eb ef                	jmp    80100fbc <skipelem+0x6b>

80100fcd <bzero>:
{
80100fcd:	55                   	push   %ebp
80100fce:	89 e5                	mov    %esp,%ebp
80100fd0:	53                   	push   %ebx
80100fd1:	83 ec 0c             	sub    $0xc,%esp
  bp = bread(dev, bno);
80100fd4:	52                   	push   %edx
80100fd5:	50                   	push   %eax
80100fd6:	e8 91 f1 ff ff       	call   8010016c <bread>
80100fdb:	89 c3                	mov    %eax,%ebx
  memset(bp->data, 0, BSIZE);
80100fdd:	8d 40 5c             	lea    0x5c(%eax),%eax
80100fe0:	83 c4 0c             	add    $0xc,%esp
80100fe3:	68 00 02 00 00       	push   $0x200
80100fe8:	6a 00                	push   $0x0
80100fea:	50                   	push   %eax
80100feb:	e8 89 2d 00 00       	call   80103d79 <memset>
  log_write(bp);
80100ff0:	89 1c 24             	mov    %ebx,(%esp)
80100ff3:	e8 01 1a 00 00       	call   801029f9 <log_write>
  brelse(bp);
80100ff8:	89 1c 24             	mov    %ebx,(%esp)
80100ffb:	e8 d5 f1 ff ff       	call   801001d5 <brelse>
}
80101000:	83 c4 10             	add    $0x10,%esp
80101003:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101006:	c9                   	leave  
80101007:	c3                   	ret    

80101008 <balloc>:
{
80101008:	55                   	push   %ebp
80101009:	89 e5                	mov    %esp,%ebp
8010100b:	57                   	push   %edi
8010100c:	56                   	push   %esi
8010100d:	53                   	push   %ebx
8010100e:	83 ec 1c             	sub    $0x1c,%esp
80101011:	89 45 d8             	mov    %eax,-0x28(%ebp)
  for(b = 0; b < sb.size; b += BPB){
80101014:	be 00 00 00 00       	mov    $0x0,%esi
80101019:	eb 14                	jmp    8010102f <balloc+0x27>
    brelse(bp);
8010101b:	83 ec 0c             	sub    $0xc,%esp
8010101e:	ff 75 e4             	pushl  -0x1c(%ebp)
80101021:	e8 af f1 ff ff       	call   801001d5 <brelse>
  for(b = 0; b < sb.size; b += BPB){
80101026:	81 c6 00 10 00 00    	add    $0x1000,%esi
8010102c:	83 c4 10             	add    $0x10,%esp
8010102f:	39 35 c0 f9 10 80    	cmp    %esi,0x8010f9c0
80101035:	76 75                	jbe    801010ac <balloc+0xa4>
    bp = bread(dev, BBLOCK(b, sb));
80101037:	8d 86 ff 0f 00 00    	lea    0xfff(%esi),%eax
8010103d:	85 f6                	test   %esi,%esi
8010103f:	0f 49 c6             	cmovns %esi,%eax
80101042:	c1 f8 0c             	sar    $0xc,%eax
80101045:	03 05 d8 f9 10 80    	add    0x8010f9d8,%eax
8010104b:	83 ec 08             	sub    $0x8,%esp
8010104e:	50                   	push   %eax
8010104f:	ff 75 d8             	pushl  -0x28(%ebp)
80101052:	e8 15 f1 ff ff       	call   8010016c <bread>
80101057:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
8010105a:	83 c4 10             	add    $0x10,%esp
8010105d:	b8 00 00 00 00       	mov    $0x0,%eax
80101062:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80101067:	7f b2                	jg     8010101b <balloc+0x13>
80101069:	8d 1c 06             	lea    (%esi,%eax,1),%ebx
8010106c:	89 5d e0             	mov    %ebx,-0x20(%ebp)
8010106f:	3b 1d c0 f9 10 80    	cmp    0x8010f9c0,%ebx
80101075:	73 a4                	jae    8010101b <balloc+0x13>
      m = 1 << (bi % 8);
80101077:	99                   	cltd   
80101078:	c1 ea 1d             	shr    $0x1d,%edx
8010107b:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
8010107e:	83 e1 07             	and    $0x7,%ecx
80101081:	29 d1                	sub    %edx,%ecx
80101083:	ba 01 00 00 00       	mov    $0x1,%edx
80101088:	d3 e2                	shl    %cl,%edx
      if((bp->data[bi/8] & m) == 0){  // Is block free?
8010108a:	8d 48 07             	lea    0x7(%eax),%ecx
8010108d:	85 c0                	test   %eax,%eax
8010108f:	0f 49 c8             	cmovns %eax,%ecx
80101092:	c1 f9 03             	sar    $0x3,%ecx
80101095:	89 4d dc             	mov    %ecx,-0x24(%ebp)
80101098:	8b 7d e4             	mov    -0x1c(%ebp),%edi
8010109b:	0f b6 4c 0f 5c       	movzbl 0x5c(%edi,%ecx,1),%ecx
801010a0:	0f b6 f9             	movzbl %cl,%edi
801010a3:	85 d7                	test   %edx,%edi
801010a5:	74 12                	je     801010b9 <balloc+0xb1>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801010a7:	83 c0 01             	add    $0x1,%eax
801010aa:	eb b6                	jmp    80101062 <balloc+0x5a>
  panic("balloc: out of blocks");
801010ac:	83 ec 0c             	sub    $0xc,%esp
801010af:	68 bf 66 10 80       	push   $0x801066bf
801010b4:	e8 8f f2 ff ff       	call   80100348 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
801010b9:	09 ca                	or     %ecx,%edx
801010bb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801010be:	8b 75 dc             	mov    -0x24(%ebp),%esi
801010c1:	88 54 30 5c          	mov    %dl,0x5c(%eax,%esi,1)
        log_write(bp);
801010c5:	83 ec 0c             	sub    $0xc,%esp
801010c8:	89 c6                	mov    %eax,%esi
801010ca:	50                   	push   %eax
801010cb:	e8 29 19 00 00       	call   801029f9 <log_write>
        brelse(bp);
801010d0:	89 34 24             	mov    %esi,(%esp)
801010d3:	e8 fd f0 ff ff       	call   801001d5 <brelse>
        bzero(dev, b + bi);
801010d8:	89 da                	mov    %ebx,%edx
801010da:	8b 45 d8             	mov    -0x28(%ebp),%eax
801010dd:	e8 eb fe ff ff       	call   80100fcd <bzero>
}
801010e2:	8b 45 e0             	mov    -0x20(%ebp),%eax
801010e5:	8d 65 f4             	lea    -0xc(%ebp),%esp
801010e8:	5b                   	pop    %ebx
801010e9:	5e                   	pop    %esi
801010ea:	5f                   	pop    %edi
801010eb:	5d                   	pop    %ebp
801010ec:	c3                   	ret    

801010ed <bmap>:
{
801010ed:	55                   	push   %ebp
801010ee:	89 e5                	mov    %esp,%ebp
801010f0:	57                   	push   %edi
801010f1:	56                   	push   %esi
801010f2:	53                   	push   %ebx
801010f3:	83 ec 1c             	sub    $0x1c,%esp
801010f6:	89 c6                	mov    %eax,%esi
801010f8:	89 d7                	mov    %edx,%edi
  if(bn < NDIRECT){
801010fa:	83 fa 0b             	cmp    $0xb,%edx
801010fd:	77 17                	ja     80101116 <bmap+0x29>
    if((addr = ip->addrs[bn]) == 0)
801010ff:	8b 5c 90 5c          	mov    0x5c(%eax,%edx,4),%ebx
80101103:	85 db                	test   %ebx,%ebx
80101105:	75 4a                	jne    80101151 <bmap+0x64>
      ip->addrs[bn] = addr = balloc(ip->dev);
80101107:	8b 00                	mov    (%eax),%eax
80101109:	e8 fa fe ff ff       	call   80101008 <balloc>
8010110e:	89 c3                	mov    %eax,%ebx
80101110:	89 44 be 5c          	mov    %eax,0x5c(%esi,%edi,4)
80101114:	eb 3b                	jmp    80101151 <bmap+0x64>
  bn -= NDIRECT;
80101116:	8d 5a f4             	lea    -0xc(%edx),%ebx
  if(bn < NINDIRECT){
80101119:	83 fb 7f             	cmp    $0x7f,%ebx
8010111c:	77 68                	ja     80101186 <bmap+0x99>
    if((addr = ip->addrs[NDIRECT]) == 0)
8010111e:	8b 80 8c 00 00 00    	mov    0x8c(%eax),%eax
80101124:	85 c0                	test   %eax,%eax
80101126:	74 33                	je     8010115b <bmap+0x6e>
    bp = bread(ip->dev, addr);
80101128:	83 ec 08             	sub    $0x8,%esp
8010112b:	50                   	push   %eax
8010112c:	ff 36                	pushl  (%esi)
8010112e:	e8 39 f0 ff ff       	call   8010016c <bread>
80101133:	89 c7                	mov    %eax,%edi
    if((addr = a[bn]) == 0){
80101135:	8d 44 98 5c          	lea    0x5c(%eax,%ebx,4),%eax
80101139:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010113c:	8b 18                	mov    (%eax),%ebx
8010113e:	83 c4 10             	add    $0x10,%esp
80101141:	85 db                	test   %ebx,%ebx
80101143:	74 25                	je     8010116a <bmap+0x7d>
    brelse(bp);
80101145:	83 ec 0c             	sub    $0xc,%esp
80101148:	57                   	push   %edi
80101149:	e8 87 f0 ff ff       	call   801001d5 <brelse>
    return addr;
8010114e:	83 c4 10             	add    $0x10,%esp
}
80101151:	89 d8                	mov    %ebx,%eax
80101153:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101156:	5b                   	pop    %ebx
80101157:	5e                   	pop    %esi
80101158:	5f                   	pop    %edi
80101159:	5d                   	pop    %ebp
8010115a:	c3                   	ret    
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
8010115b:	8b 06                	mov    (%esi),%eax
8010115d:	e8 a6 fe ff ff       	call   80101008 <balloc>
80101162:	89 86 8c 00 00 00    	mov    %eax,0x8c(%esi)
80101168:	eb be                	jmp    80101128 <bmap+0x3b>
      a[bn] = addr = balloc(ip->dev);
8010116a:	8b 06                	mov    (%esi),%eax
8010116c:	e8 97 fe ff ff       	call   80101008 <balloc>
80101171:	89 c3                	mov    %eax,%ebx
80101173:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101176:	89 18                	mov    %ebx,(%eax)
      log_write(bp);
80101178:	83 ec 0c             	sub    $0xc,%esp
8010117b:	57                   	push   %edi
8010117c:	e8 78 18 00 00       	call   801029f9 <log_write>
80101181:	83 c4 10             	add    $0x10,%esp
80101184:	eb bf                	jmp    80101145 <bmap+0x58>
  panic("bmap: out of range");
80101186:	83 ec 0c             	sub    $0xc,%esp
80101189:	68 d5 66 10 80       	push   $0x801066d5
8010118e:	e8 b5 f1 ff ff       	call   80100348 <panic>

80101193 <iget>:
{
80101193:	55                   	push   %ebp
80101194:	89 e5                	mov    %esp,%ebp
80101196:	57                   	push   %edi
80101197:	56                   	push   %esi
80101198:	53                   	push   %ebx
80101199:	83 ec 28             	sub    $0x28,%esp
8010119c:	89 c7                	mov    %eax,%edi
8010119e:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  acquire(&icache.lock);
801011a1:	68 e0 f9 10 80       	push   $0x8010f9e0
801011a6:	e8 22 2b 00 00       	call   80103ccd <acquire>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801011ab:	83 c4 10             	add    $0x10,%esp
  empty = 0;
801011ae:	be 00 00 00 00       	mov    $0x0,%esi
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801011b3:	bb 14 fa 10 80       	mov    $0x8010fa14,%ebx
801011b8:	eb 0a                	jmp    801011c4 <iget+0x31>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801011ba:	85 f6                	test   %esi,%esi
801011bc:	74 3b                	je     801011f9 <iget+0x66>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801011be:	81 c3 90 00 00 00    	add    $0x90,%ebx
801011c4:	81 fb 34 16 11 80    	cmp    $0x80111634,%ebx
801011ca:	73 35                	jae    80101201 <iget+0x6e>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
801011cc:	8b 43 08             	mov    0x8(%ebx),%eax
801011cf:	85 c0                	test   %eax,%eax
801011d1:	7e e7                	jle    801011ba <iget+0x27>
801011d3:	39 3b                	cmp    %edi,(%ebx)
801011d5:	75 e3                	jne    801011ba <iget+0x27>
801011d7:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801011da:	39 4b 04             	cmp    %ecx,0x4(%ebx)
801011dd:	75 db                	jne    801011ba <iget+0x27>
      ip->ref++;
801011df:	83 c0 01             	add    $0x1,%eax
801011e2:	89 43 08             	mov    %eax,0x8(%ebx)
      release(&icache.lock);
801011e5:	83 ec 0c             	sub    $0xc,%esp
801011e8:	68 e0 f9 10 80       	push   $0x8010f9e0
801011ed:	e8 40 2b 00 00       	call   80103d32 <release>
      return ip;
801011f2:	83 c4 10             	add    $0x10,%esp
801011f5:	89 de                	mov    %ebx,%esi
801011f7:	eb 32                	jmp    8010122b <iget+0x98>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801011f9:	85 c0                	test   %eax,%eax
801011fb:	75 c1                	jne    801011be <iget+0x2b>
      empty = ip;
801011fd:	89 de                	mov    %ebx,%esi
801011ff:	eb bd                	jmp    801011be <iget+0x2b>
  if(empty == 0)
80101201:	85 f6                	test   %esi,%esi
80101203:	74 30                	je     80101235 <iget+0xa2>
  ip->dev = dev;
80101205:	89 3e                	mov    %edi,(%esi)
  ip->inum = inum;
80101207:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010120a:	89 46 04             	mov    %eax,0x4(%esi)
  ip->ref = 1;
8010120d:	c7 46 08 01 00 00 00 	movl   $0x1,0x8(%esi)
  ip->valid = 0;
80101214:	c7 46 4c 00 00 00 00 	movl   $0x0,0x4c(%esi)
  release(&icache.lock);
8010121b:	83 ec 0c             	sub    $0xc,%esp
8010121e:	68 e0 f9 10 80       	push   $0x8010f9e0
80101223:	e8 0a 2b 00 00       	call   80103d32 <release>
  return ip;
80101228:	83 c4 10             	add    $0x10,%esp
}
8010122b:	89 f0                	mov    %esi,%eax
8010122d:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101230:	5b                   	pop    %ebx
80101231:	5e                   	pop    %esi
80101232:	5f                   	pop    %edi
80101233:	5d                   	pop    %ebp
80101234:	c3                   	ret    
    panic("iget: no inodes");
80101235:	83 ec 0c             	sub    $0xc,%esp
80101238:	68 e8 66 10 80       	push   $0x801066e8
8010123d:	e8 06 f1 ff ff       	call   80100348 <panic>

80101242 <readsb>:
{
80101242:	55                   	push   %ebp
80101243:	89 e5                	mov    %esp,%ebp
80101245:	53                   	push   %ebx
80101246:	83 ec 0c             	sub    $0xc,%esp
  bp = bread(dev, 1);
80101249:	6a 01                	push   $0x1
8010124b:	ff 75 08             	pushl  0x8(%ebp)
8010124e:	e8 19 ef ff ff       	call   8010016c <bread>
80101253:	89 c3                	mov    %eax,%ebx
  memmove(sb, bp->data, sizeof(*sb));
80101255:	8d 40 5c             	lea    0x5c(%eax),%eax
80101258:	83 c4 0c             	add    $0xc,%esp
8010125b:	6a 1c                	push   $0x1c
8010125d:	50                   	push   %eax
8010125e:	ff 75 0c             	pushl  0xc(%ebp)
80101261:	e8 8e 2b 00 00       	call   80103df4 <memmove>
  brelse(bp);
80101266:	89 1c 24             	mov    %ebx,(%esp)
80101269:	e8 67 ef ff ff       	call   801001d5 <brelse>
}
8010126e:	83 c4 10             	add    $0x10,%esp
80101271:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101274:	c9                   	leave  
80101275:	c3                   	ret    

80101276 <bfree>:
{
80101276:	55                   	push   %ebp
80101277:	89 e5                	mov    %esp,%ebp
80101279:	56                   	push   %esi
8010127a:	53                   	push   %ebx
8010127b:	89 c6                	mov    %eax,%esi
8010127d:	89 d3                	mov    %edx,%ebx
  readsb(dev, &sb);
8010127f:	83 ec 08             	sub    $0x8,%esp
80101282:	68 c0 f9 10 80       	push   $0x8010f9c0
80101287:	50                   	push   %eax
80101288:	e8 b5 ff ff ff       	call   80101242 <readsb>
  bp = bread(dev, BBLOCK(b, sb));
8010128d:	89 d8                	mov    %ebx,%eax
8010128f:	c1 e8 0c             	shr    $0xc,%eax
80101292:	03 05 d8 f9 10 80    	add    0x8010f9d8,%eax
80101298:	83 c4 08             	add    $0x8,%esp
8010129b:	50                   	push   %eax
8010129c:	56                   	push   %esi
8010129d:	e8 ca ee ff ff       	call   8010016c <bread>
801012a2:	89 c6                	mov    %eax,%esi
  m = 1 << (bi % 8);
801012a4:	89 d9                	mov    %ebx,%ecx
801012a6:	83 e1 07             	and    $0x7,%ecx
801012a9:	b8 01 00 00 00       	mov    $0x1,%eax
801012ae:	d3 e0                	shl    %cl,%eax
  if((bp->data[bi/8] & m) == 0)
801012b0:	83 c4 10             	add    $0x10,%esp
801012b3:	81 e3 ff 0f 00 00    	and    $0xfff,%ebx
801012b9:	c1 fb 03             	sar    $0x3,%ebx
801012bc:	0f b6 54 1e 5c       	movzbl 0x5c(%esi,%ebx,1),%edx
801012c1:	0f b6 ca             	movzbl %dl,%ecx
801012c4:	85 c1                	test   %eax,%ecx
801012c6:	74 23                	je     801012eb <bfree+0x75>
  bp->data[bi/8] &= ~m;
801012c8:	f7 d0                	not    %eax
801012ca:	21 d0                	and    %edx,%eax
801012cc:	88 44 1e 5c          	mov    %al,0x5c(%esi,%ebx,1)
  log_write(bp);
801012d0:	83 ec 0c             	sub    $0xc,%esp
801012d3:	56                   	push   %esi
801012d4:	e8 20 17 00 00       	call   801029f9 <log_write>
  brelse(bp);
801012d9:	89 34 24             	mov    %esi,(%esp)
801012dc:	e8 f4 ee ff ff       	call   801001d5 <brelse>
}
801012e1:	83 c4 10             	add    $0x10,%esp
801012e4:	8d 65 f8             	lea    -0x8(%ebp),%esp
801012e7:	5b                   	pop    %ebx
801012e8:	5e                   	pop    %esi
801012e9:	5d                   	pop    %ebp
801012ea:	c3                   	ret    
    panic("freeing free block");
801012eb:	83 ec 0c             	sub    $0xc,%esp
801012ee:	68 f8 66 10 80       	push   $0x801066f8
801012f3:	e8 50 f0 ff ff       	call   80100348 <panic>

801012f8 <iinit>:
{
801012f8:	55                   	push   %ebp
801012f9:	89 e5                	mov    %esp,%ebp
801012fb:	53                   	push   %ebx
801012fc:	83 ec 0c             	sub    $0xc,%esp
  initlock(&icache.lock, "icache");
801012ff:	68 0b 67 10 80       	push   $0x8010670b
80101304:	68 e0 f9 10 80       	push   $0x8010f9e0
80101309:	e8 83 28 00 00       	call   80103b91 <initlock>
  for(i = 0; i < NINODE; i++) {
8010130e:	83 c4 10             	add    $0x10,%esp
80101311:	bb 00 00 00 00       	mov    $0x0,%ebx
80101316:	eb 21                	jmp    80101339 <iinit+0x41>
    initsleeplock(&icache.inode[i].lock, "inode");
80101318:	83 ec 08             	sub    $0x8,%esp
8010131b:	68 12 67 10 80       	push   $0x80106712
80101320:	8d 14 db             	lea    (%ebx,%ebx,8),%edx
80101323:	89 d0                	mov    %edx,%eax
80101325:	c1 e0 04             	shl    $0x4,%eax
80101328:	05 20 fa 10 80       	add    $0x8010fa20,%eax
8010132d:	50                   	push   %eax
8010132e:	e8 53 27 00 00       	call   80103a86 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
80101333:	83 c3 01             	add    $0x1,%ebx
80101336:	83 c4 10             	add    $0x10,%esp
80101339:	83 fb 31             	cmp    $0x31,%ebx
8010133c:	7e da                	jle    80101318 <iinit+0x20>
  readsb(dev, &sb);
8010133e:	83 ec 08             	sub    $0x8,%esp
80101341:	68 c0 f9 10 80       	push   $0x8010f9c0
80101346:	ff 75 08             	pushl  0x8(%ebp)
80101349:	e8 f4 fe ff ff       	call   80101242 <readsb>
  cprintf("sb: size %d nblocks %d ninodes %d nlog %d logstart %d\
8010134e:	ff 35 d8 f9 10 80    	pushl  0x8010f9d8
80101354:	ff 35 d4 f9 10 80    	pushl  0x8010f9d4
8010135a:	ff 35 d0 f9 10 80    	pushl  0x8010f9d0
80101360:	ff 35 cc f9 10 80    	pushl  0x8010f9cc
80101366:	ff 35 c8 f9 10 80    	pushl  0x8010f9c8
8010136c:	ff 35 c4 f9 10 80    	pushl  0x8010f9c4
80101372:	ff 35 c0 f9 10 80    	pushl  0x8010f9c0
80101378:	68 78 67 10 80       	push   $0x80106778
8010137d:	e8 89 f2 ff ff       	call   8010060b <cprintf>
}
80101382:	83 c4 30             	add    $0x30,%esp
80101385:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101388:	c9                   	leave  
80101389:	c3                   	ret    

8010138a <ialloc>:
{
8010138a:	55                   	push   %ebp
8010138b:	89 e5                	mov    %esp,%ebp
8010138d:	57                   	push   %edi
8010138e:	56                   	push   %esi
8010138f:	53                   	push   %ebx
80101390:	83 ec 1c             	sub    $0x1c,%esp
80101393:	8b 45 0c             	mov    0xc(%ebp),%eax
80101396:	89 45 e0             	mov    %eax,-0x20(%ebp)
  for(inum = 1; inum < sb.ninodes; inum++){
80101399:	bb 01 00 00 00       	mov    $0x1,%ebx
8010139e:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
801013a1:	39 1d c8 f9 10 80    	cmp    %ebx,0x8010f9c8
801013a7:	76 3f                	jbe    801013e8 <ialloc+0x5e>
    bp = bread(dev, IBLOCK(inum, sb));
801013a9:	89 d8                	mov    %ebx,%eax
801013ab:	c1 e8 03             	shr    $0x3,%eax
801013ae:	03 05 d4 f9 10 80    	add    0x8010f9d4,%eax
801013b4:	83 ec 08             	sub    $0x8,%esp
801013b7:	50                   	push   %eax
801013b8:	ff 75 08             	pushl  0x8(%ebp)
801013bb:	e8 ac ed ff ff       	call   8010016c <bread>
801013c0:	89 c6                	mov    %eax,%esi
    dip = (struct dinode*)bp->data + inum%IPB;
801013c2:	89 d8                	mov    %ebx,%eax
801013c4:	83 e0 07             	and    $0x7,%eax
801013c7:	c1 e0 06             	shl    $0x6,%eax
801013ca:	8d 7c 06 5c          	lea    0x5c(%esi,%eax,1),%edi
    if(dip->type == 0){  // a free inode
801013ce:	83 c4 10             	add    $0x10,%esp
801013d1:	66 83 3f 00          	cmpw   $0x0,(%edi)
801013d5:	74 1e                	je     801013f5 <ialloc+0x6b>
    brelse(bp);
801013d7:	83 ec 0c             	sub    $0xc,%esp
801013da:	56                   	push   %esi
801013db:	e8 f5 ed ff ff       	call   801001d5 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
801013e0:	83 c3 01             	add    $0x1,%ebx
801013e3:	83 c4 10             	add    $0x10,%esp
801013e6:	eb b6                	jmp    8010139e <ialloc+0x14>
  panic("ialloc: no inodes");
801013e8:	83 ec 0c             	sub    $0xc,%esp
801013eb:	68 18 67 10 80       	push   $0x80106718
801013f0:	e8 53 ef ff ff       	call   80100348 <panic>
      memset(dip, 0, sizeof(*dip));
801013f5:	83 ec 04             	sub    $0x4,%esp
801013f8:	6a 40                	push   $0x40
801013fa:	6a 00                	push   $0x0
801013fc:	57                   	push   %edi
801013fd:	e8 77 29 00 00       	call   80103d79 <memset>
      dip->type = type;
80101402:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80101406:	66 89 07             	mov    %ax,(%edi)
      log_write(bp);   // mark it allocated on the disk
80101409:	89 34 24             	mov    %esi,(%esp)
8010140c:	e8 e8 15 00 00       	call   801029f9 <log_write>
      brelse(bp);
80101411:	89 34 24             	mov    %esi,(%esp)
80101414:	e8 bc ed ff ff       	call   801001d5 <brelse>
      return iget(dev, inum);
80101419:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010141c:	8b 45 08             	mov    0x8(%ebp),%eax
8010141f:	e8 6f fd ff ff       	call   80101193 <iget>
}
80101424:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101427:	5b                   	pop    %ebx
80101428:	5e                   	pop    %esi
80101429:	5f                   	pop    %edi
8010142a:	5d                   	pop    %ebp
8010142b:	c3                   	ret    

8010142c <iupdate>:
{
8010142c:	55                   	push   %ebp
8010142d:	89 e5                	mov    %esp,%ebp
8010142f:	56                   	push   %esi
80101430:	53                   	push   %ebx
80101431:	8b 5d 08             	mov    0x8(%ebp),%ebx
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
80101434:	8b 43 04             	mov    0x4(%ebx),%eax
80101437:	c1 e8 03             	shr    $0x3,%eax
8010143a:	03 05 d4 f9 10 80    	add    0x8010f9d4,%eax
80101440:	83 ec 08             	sub    $0x8,%esp
80101443:	50                   	push   %eax
80101444:	ff 33                	pushl  (%ebx)
80101446:	e8 21 ed ff ff       	call   8010016c <bread>
8010144b:	89 c6                	mov    %eax,%esi
  dip = (struct dinode*)bp->data + ip->inum%IPB;
8010144d:	8b 43 04             	mov    0x4(%ebx),%eax
80101450:	83 e0 07             	and    $0x7,%eax
80101453:	c1 e0 06             	shl    $0x6,%eax
80101456:	8d 44 06 5c          	lea    0x5c(%esi,%eax,1),%eax
  dip->type = ip->type;
8010145a:	0f b7 53 50          	movzwl 0x50(%ebx),%edx
8010145e:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
80101461:	0f b7 53 52          	movzwl 0x52(%ebx),%edx
80101465:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
80101469:	0f b7 53 54          	movzwl 0x54(%ebx),%edx
8010146d:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
80101471:	0f b7 53 56          	movzwl 0x56(%ebx),%edx
80101475:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
80101479:	8b 53 58             	mov    0x58(%ebx),%edx
8010147c:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
8010147f:	83 c3 5c             	add    $0x5c,%ebx
80101482:	83 c0 0c             	add    $0xc,%eax
80101485:	83 c4 0c             	add    $0xc,%esp
80101488:	6a 34                	push   $0x34
8010148a:	53                   	push   %ebx
8010148b:	50                   	push   %eax
8010148c:	e8 63 29 00 00       	call   80103df4 <memmove>
  log_write(bp);
80101491:	89 34 24             	mov    %esi,(%esp)
80101494:	e8 60 15 00 00       	call   801029f9 <log_write>
  brelse(bp);
80101499:	89 34 24             	mov    %esi,(%esp)
8010149c:	e8 34 ed ff ff       	call   801001d5 <brelse>
}
801014a1:	83 c4 10             	add    $0x10,%esp
801014a4:	8d 65 f8             	lea    -0x8(%ebp),%esp
801014a7:	5b                   	pop    %ebx
801014a8:	5e                   	pop    %esi
801014a9:	5d                   	pop    %ebp
801014aa:	c3                   	ret    

801014ab <itrunc>:
{
801014ab:	55                   	push   %ebp
801014ac:	89 e5                	mov    %esp,%ebp
801014ae:	57                   	push   %edi
801014af:	56                   	push   %esi
801014b0:	53                   	push   %ebx
801014b1:	83 ec 1c             	sub    $0x1c,%esp
801014b4:	89 c6                	mov    %eax,%esi
  for(i = 0; i < NDIRECT; i++){
801014b6:	bb 00 00 00 00       	mov    $0x0,%ebx
801014bb:	eb 03                	jmp    801014c0 <itrunc+0x15>
801014bd:	83 c3 01             	add    $0x1,%ebx
801014c0:	83 fb 0b             	cmp    $0xb,%ebx
801014c3:	7f 19                	jg     801014de <itrunc+0x33>
    if(ip->addrs[i]){
801014c5:	8b 54 9e 5c          	mov    0x5c(%esi,%ebx,4),%edx
801014c9:	85 d2                	test   %edx,%edx
801014cb:	74 f0                	je     801014bd <itrunc+0x12>
      bfree(ip->dev, ip->addrs[i]);
801014cd:	8b 06                	mov    (%esi),%eax
801014cf:	e8 a2 fd ff ff       	call   80101276 <bfree>
      ip->addrs[i] = 0;
801014d4:	c7 44 9e 5c 00 00 00 	movl   $0x0,0x5c(%esi,%ebx,4)
801014db:	00 
801014dc:	eb df                	jmp    801014bd <itrunc+0x12>
  if(ip->addrs[NDIRECT]){
801014de:	8b 86 8c 00 00 00    	mov    0x8c(%esi),%eax
801014e4:	85 c0                	test   %eax,%eax
801014e6:	75 1b                	jne    80101503 <itrunc+0x58>
  ip->size = 0;
801014e8:	c7 46 58 00 00 00 00 	movl   $0x0,0x58(%esi)
  iupdate(ip);
801014ef:	83 ec 0c             	sub    $0xc,%esp
801014f2:	56                   	push   %esi
801014f3:	e8 34 ff ff ff       	call   8010142c <iupdate>
}
801014f8:	83 c4 10             	add    $0x10,%esp
801014fb:	8d 65 f4             	lea    -0xc(%ebp),%esp
801014fe:	5b                   	pop    %ebx
801014ff:	5e                   	pop    %esi
80101500:	5f                   	pop    %edi
80101501:	5d                   	pop    %ebp
80101502:	c3                   	ret    
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80101503:	83 ec 08             	sub    $0x8,%esp
80101506:	50                   	push   %eax
80101507:	ff 36                	pushl  (%esi)
80101509:	e8 5e ec ff ff       	call   8010016c <bread>
8010150e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    a = (uint*)bp->data;
80101511:	8d 78 5c             	lea    0x5c(%eax),%edi
    for(j = 0; j < NINDIRECT; j++){
80101514:	83 c4 10             	add    $0x10,%esp
80101517:	bb 00 00 00 00       	mov    $0x0,%ebx
8010151c:	eb 03                	jmp    80101521 <itrunc+0x76>
8010151e:	83 c3 01             	add    $0x1,%ebx
80101521:	83 fb 7f             	cmp    $0x7f,%ebx
80101524:	77 10                	ja     80101536 <itrunc+0x8b>
      if(a[j])
80101526:	8b 14 9f             	mov    (%edi,%ebx,4),%edx
80101529:	85 d2                	test   %edx,%edx
8010152b:	74 f1                	je     8010151e <itrunc+0x73>
        bfree(ip->dev, a[j]);
8010152d:	8b 06                	mov    (%esi),%eax
8010152f:	e8 42 fd ff ff       	call   80101276 <bfree>
80101534:	eb e8                	jmp    8010151e <itrunc+0x73>
    brelse(bp);
80101536:	83 ec 0c             	sub    $0xc,%esp
80101539:	ff 75 e4             	pushl  -0x1c(%ebp)
8010153c:	e8 94 ec ff ff       	call   801001d5 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101541:	8b 06                	mov    (%esi),%eax
80101543:	8b 96 8c 00 00 00    	mov    0x8c(%esi),%edx
80101549:	e8 28 fd ff ff       	call   80101276 <bfree>
    ip->addrs[NDIRECT] = 0;
8010154e:	c7 86 8c 00 00 00 00 	movl   $0x0,0x8c(%esi)
80101555:	00 00 00 
80101558:	83 c4 10             	add    $0x10,%esp
8010155b:	eb 8b                	jmp    801014e8 <itrunc+0x3d>

8010155d <idup>:
{
8010155d:	55                   	push   %ebp
8010155e:	89 e5                	mov    %esp,%ebp
80101560:	53                   	push   %ebx
80101561:	83 ec 10             	sub    $0x10,%esp
80101564:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&icache.lock);
80101567:	68 e0 f9 10 80       	push   $0x8010f9e0
8010156c:	e8 5c 27 00 00       	call   80103ccd <acquire>
  ip->ref++;
80101571:	8b 43 08             	mov    0x8(%ebx),%eax
80101574:	83 c0 01             	add    $0x1,%eax
80101577:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
8010157a:	c7 04 24 e0 f9 10 80 	movl   $0x8010f9e0,(%esp)
80101581:	e8 ac 27 00 00       	call   80103d32 <release>
}
80101586:	89 d8                	mov    %ebx,%eax
80101588:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010158b:	c9                   	leave  
8010158c:	c3                   	ret    

8010158d <ilock>:
{
8010158d:	55                   	push   %ebp
8010158e:	89 e5                	mov    %esp,%ebp
80101590:	56                   	push   %esi
80101591:	53                   	push   %ebx
80101592:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(ip == 0 || ip->ref < 1)
80101595:	85 db                	test   %ebx,%ebx
80101597:	74 22                	je     801015bb <ilock+0x2e>
80101599:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
8010159d:	7e 1c                	jle    801015bb <ilock+0x2e>
  acquiresleep(&ip->lock);
8010159f:	83 ec 0c             	sub    $0xc,%esp
801015a2:	8d 43 0c             	lea    0xc(%ebx),%eax
801015a5:	50                   	push   %eax
801015a6:	e8 0e 25 00 00       	call   80103ab9 <acquiresleep>
  if(ip->valid == 0){
801015ab:	83 c4 10             	add    $0x10,%esp
801015ae:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801015b2:	74 14                	je     801015c8 <ilock+0x3b>
}
801015b4:	8d 65 f8             	lea    -0x8(%ebp),%esp
801015b7:	5b                   	pop    %ebx
801015b8:	5e                   	pop    %esi
801015b9:	5d                   	pop    %ebp
801015ba:	c3                   	ret    
    panic("ilock");
801015bb:	83 ec 0c             	sub    $0xc,%esp
801015be:	68 2a 67 10 80       	push   $0x8010672a
801015c3:	e8 80 ed ff ff       	call   80100348 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
801015c8:	8b 43 04             	mov    0x4(%ebx),%eax
801015cb:	c1 e8 03             	shr    $0x3,%eax
801015ce:	03 05 d4 f9 10 80    	add    0x8010f9d4,%eax
801015d4:	83 ec 08             	sub    $0x8,%esp
801015d7:	50                   	push   %eax
801015d8:	ff 33                	pushl  (%ebx)
801015da:	e8 8d eb ff ff       	call   8010016c <bread>
801015df:	89 c6                	mov    %eax,%esi
    dip = (struct dinode*)bp->data + ip->inum%IPB;
801015e1:	8b 43 04             	mov    0x4(%ebx),%eax
801015e4:	83 e0 07             	and    $0x7,%eax
801015e7:	c1 e0 06             	shl    $0x6,%eax
801015ea:	8d 44 06 5c          	lea    0x5c(%esi,%eax,1),%eax
    ip->type = dip->type;
801015ee:	0f b7 10             	movzwl (%eax),%edx
801015f1:	66 89 53 50          	mov    %dx,0x50(%ebx)
    ip->major = dip->major;
801015f5:	0f b7 50 02          	movzwl 0x2(%eax),%edx
801015f9:	66 89 53 52          	mov    %dx,0x52(%ebx)
    ip->minor = dip->minor;
801015fd:	0f b7 50 04          	movzwl 0x4(%eax),%edx
80101601:	66 89 53 54          	mov    %dx,0x54(%ebx)
    ip->nlink = dip->nlink;
80101605:	0f b7 50 06          	movzwl 0x6(%eax),%edx
80101609:	66 89 53 56          	mov    %dx,0x56(%ebx)
    ip->size = dip->size;
8010160d:	8b 50 08             	mov    0x8(%eax),%edx
80101610:	89 53 58             	mov    %edx,0x58(%ebx)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101613:	83 c0 0c             	add    $0xc,%eax
80101616:	8d 53 5c             	lea    0x5c(%ebx),%edx
80101619:	83 c4 0c             	add    $0xc,%esp
8010161c:	6a 34                	push   $0x34
8010161e:	50                   	push   %eax
8010161f:	52                   	push   %edx
80101620:	e8 cf 27 00 00       	call   80103df4 <memmove>
    brelse(bp);
80101625:	89 34 24             	mov    %esi,(%esp)
80101628:	e8 a8 eb ff ff       	call   801001d5 <brelse>
    ip->valid = 1;
8010162d:	c7 43 4c 01 00 00 00 	movl   $0x1,0x4c(%ebx)
    if(ip->type == 0)
80101634:	83 c4 10             	add    $0x10,%esp
80101637:	66 83 7b 50 00       	cmpw   $0x0,0x50(%ebx)
8010163c:	0f 85 72 ff ff ff    	jne    801015b4 <ilock+0x27>
      panic("ilock: no type");
80101642:	83 ec 0c             	sub    $0xc,%esp
80101645:	68 30 67 10 80       	push   $0x80106730
8010164a:	e8 f9 ec ff ff       	call   80100348 <panic>

8010164f <iunlock>:
{
8010164f:	55                   	push   %ebp
80101650:	89 e5                	mov    %esp,%ebp
80101652:	56                   	push   %esi
80101653:	53                   	push   %ebx
80101654:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
80101657:	85 db                	test   %ebx,%ebx
80101659:	74 2c                	je     80101687 <iunlock+0x38>
8010165b:	8d 73 0c             	lea    0xc(%ebx),%esi
8010165e:	83 ec 0c             	sub    $0xc,%esp
80101661:	56                   	push   %esi
80101662:	e8 dc 24 00 00       	call   80103b43 <holdingsleep>
80101667:	83 c4 10             	add    $0x10,%esp
8010166a:	85 c0                	test   %eax,%eax
8010166c:	74 19                	je     80101687 <iunlock+0x38>
8010166e:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101672:	7e 13                	jle    80101687 <iunlock+0x38>
  releasesleep(&ip->lock);
80101674:	83 ec 0c             	sub    $0xc,%esp
80101677:	56                   	push   %esi
80101678:	e8 8b 24 00 00       	call   80103b08 <releasesleep>
}
8010167d:	83 c4 10             	add    $0x10,%esp
80101680:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101683:	5b                   	pop    %ebx
80101684:	5e                   	pop    %esi
80101685:	5d                   	pop    %ebp
80101686:	c3                   	ret    
    panic("iunlock");
80101687:	83 ec 0c             	sub    $0xc,%esp
8010168a:	68 3f 67 10 80       	push   $0x8010673f
8010168f:	e8 b4 ec ff ff       	call   80100348 <panic>

80101694 <iput>:
{
80101694:	55                   	push   %ebp
80101695:	89 e5                	mov    %esp,%ebp
80101697:	57                   	push   %edi
80101698:	56                   	push   %esi
80101699:	53                   	push   %ebx
8010169a:	83 ec 18             	sub    $0x18,%esp
8010169d:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquiresleep(&ip->lock);
801016a0:	8d 73 0c             	lea    0xc(%ebx),%esi
801016a3:	56                   	push   %esi
801016a4:	e8 10 24 00 00       	call   80103ab9 <acquiresleep>
  if(ip->valid && ip->nlink == 0){
801016a9:	83 c4 10             	add    $0x10,%esp
801016ac:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801016b0:	74 07                	je     801016b9 <iput+0x25>
801016b2:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801016b7:	74 35                	je     801016ee <iput+0x5a>
  releasesleep(&ip->lock);
801016b9:	83 ec 0c             	sub    $0xc,%esp
801016bc:	56                   	push   %esi
801016bd:	e8 46 24 00 00       	call   80103b08 <releasesleep>
  acquire(&icache.lock);
801016c2:	c7 04 24 e0 f9 10 80 	movl   $0x8010f9e0,(%esp)
801016c9:	e8 ff 25 00 00       	call   80103ccd <acquire>
  ip->ref--;
801016ce:	8b 43 08             	mov    0x8(%ebx),%eax
801016d1:	83 e8 01             	sub    $0x1,%eax
801016d4:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
801016d7:	c7 04 24 e0 f9 10 80 	movl   $0x8010f9e0,(%esp)
801016de:	e8 4f 26 00 00       	call   80103d32 <release>
}
801016e3:	83 c4 10             	add    $0x10,%esp
801016e6:	8d 65 f4             	lea    -0xc(%ebp),%esp
801016e9:	5b                   	pop    %ebx
801016ea:	5e                   	pop    %esi
801016eb:	5f                   	pop    %edi
801016ec:	5d                   	pop    %ebp
801016ed:	c3                   	ret    
    acquire(&icache.lock);
801016ee:	83 ec 0c             	sub    $0xc,%esp
801016f1:	68 e0 f9 10 80       	push   $0x8010f9e0
801016f6:	e8 d2 25 00 00       	call   80103ccd <acquire>
    int r = ip->ref;
801016fb:	8b 7b 08             	mov    0x8(%ebx),%edi
    release(&icache.lock);
801016fe:	c7 04 24 e0 f9 10 80 	movl   $0x8010f9e0,(%esp)
80101705:	e8 28 26 00 00       	call   80103d32 <release>
    if(r == 1){
8010170a:	83 c4 10             	add    $0x10,%esp
8010170d:	83 ff 01             	cmp    $0x1,%edi
80101710:	75 a7                	jne    801016b9 <iput+0x25>
      itrunc(ip);
80101712:	89 d8                	mov    %ebx,%eax
80101714:	e8 92 fd ff ff       	call   801014ab <itrunc>
      ip->type = 0;
80101719:	66 c7 43 50 00 00    	movw   $0x0,0x50(%ebx)
      iupdate(ip);
8010171f:	83 ec 0c             	sub    $0xc,%esp
80101722:	53                   	push   %ebx
80101723:	e8 04 fd ff ff       	call   8010142c <iupdate>
      ip->valid = 0;
80101728:	c7 43 4c 00 00 00 00 	movl   $0x0,0x4c(%ebx)
8010172f:	83 c4 10             	add    $0x10,%esp
80101732:	eb 85                	jmp    801016b9 <iput+0x25>

80101734 <iunlockput>:
{
80101734:	55                   	push   %ebp
80101735:	89 e5                	mov    %esp,%ebp
80101737:	53                   	push   %ebx
80101738:	83 ec 10             	sub    $0x10,%esp
8010173b:	8b 5d 08             	mov    0x8(%ebp),%ebx
  iunlock(ip);
8010173e:	53                   	push   %ebx
8010173f:	e8 0b ff ff ff       	call   8010164f <iunlock>
  iput(ip);
80101744:	89 1c 24             	mov    %ebx,(%esp)
80101747:	e8 48 ff ff ff       	call   80101694 <iput>
}
8010174c:	83 c4 10             	add    $0x10,%esp
8010174f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101752:	c9                   	leave  
80101753:	c3                   	ret    

80101754 <stati>:
{
80101754:	55                   	push   %ebp
80101755:	89 e5                	mov    %esp,%ebp
80101757:	8b 55 08             	mov    0x8(%ebp),%edx
8010175a:	8b 45 0c             	mov    0xc(%ebp),%eax
  st->dev = ip->dev;
8010175d:	8b 0a                	mov    (%edx),%ecx
8010175f:	89 48 04             	mov    %ecx,0x4(%eax)
  st->ino = ip->inum;
80101762:	8b 4a 04             	mov    0x4(%edx),%ecx
80101765:	89 48 08             	mov    %ecx,0x8(%eax)
  st->type = ip->type;
80101768:	0f b7 4a 50          	movzwl 0x50(%edx),%ecx
8010176c:	66 89 08             	mov    %cx,(%eax)
  st->nlink = ip->nlink;
8010176f:	0f b7 4a 56          	movzwl 0x56(%edx),%ecx
80101773:	66 89 48 0c          	mov    %cx,0xc(%eax)
  st->size = ip->size;
80101777:	8b 52 58             	mov    0x58(%edx),%edx
8010177a:	89 50 10             	mov    %edx,0x10(%eax)
}
8010177d:	5d                   	pop    %ebp
8010177e:	c3                   	ret    

8010177f <readi>:
{
8010177f:	55                   	push   %ebp
80101780:	89 e5                	mov    %esp,%ebp
80101782:	57                   	push   %edi
80101783:	56                   	push   %esi
80101784:	53                   	push   %ebx
80101785:	83 ec 1c             	sub    $0x1c,%esp
80101788:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(ip->type == T_DEV){
8010178b:	8b 45 08             	mov    0x8(%ebp),%eax
8010178e:	66 83 78 50 03       	cmpw   $0x3,0x50(%eax)
80101793:	74 2c                	je     801017c1 <readi+0x42>
  if(off > ip->size || off + n < off)
80101795:	8b 45 08             	mov    0x8(%ebp),%eax
80101798:	8b 40 58             	mov    0x58(%eax),%eax
8010179b:	39 f8                	cmp    %edi,%eax
8010179d:	0f 82 cb 00 00 00    	jb     8010186e <readi+0xef>
801017a3:	89 fa                	mov    %edi,%edx
801017a5:	03 55 14             	add    0x14(%ebp),%edx
801017a8:	0f 82 c7 00 00 00    	jb     80101875 <readi+0xf6>
  if(off + n > ip->size)
801017ae:	39 d0                	cmp    %edx,%eax
801017b0:	73 05                	jae    801017b7 <readi+0x38>
    n = ip->size - off;
801017b2:	29 f8                	sub    %edi,%eax
801017b4:	89 45 14             	mov    %eax,0x14(%ebp)
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
801017b7:	be 00 00 00 00       	mov    $0x0,%esi
801017bc:	e9 8f 00 00 00       	jmp    80101850 <readi+0xd1>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
801017c1:	0f b7 40 52          	movzwl 0x52(%eax),%eax
801017c5:	66 83 f8 09          	cmp    $0x9,%ax
801017c9:	0f 87 91 00 00 00    	ja     80101860 <readi+0xe1>
801017cf:	98                   	cwtl   
801017d0:	8b 04 c5 60 f9 10 80 	mov    -0x7fef06a0(,%eax,8),%eax
801017d7:	85 c0                	test   %eax,%eax
801017d9:	0f 84 88 00 00 00    	je     80101867 <readi+0xe8>
    return devsw[ip->major].read(ip, dst, n);
801017df:	83 ec 04             	sub    $0x4,%esp
801017e2:	ff 75 14             	pushl  0x14(%ebp)
801017e5:	ff 75 0c             	pushl  0xc(%ebp)
801017e8:	ff 75 08             	pushl  0x8(%ebp)
801017eb:	ff d0                	call   *%eax
801017ed:	83 c4 10             	add    $0x10,%esp
801017f0:	eb 66                	jmp    80101858 <readi+0xd9>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
801017f2:	89 fa                	mov    %edi,%edx
801017f4:	c1 ea 09             	shr    $0x9,%edx
801017f7:	8b 45 08             	mov    0x8(%ebp),%eax
801017fa:	e8 ee f8 ff ff       	call   801010ed <bmap>
801017ff:	83 ec 08             	sub    $0x8,%esp
80101802:	50                   	push   %eax
80101803:	8b 45 08             	mov    0x8(%ebp),%eax
80101806:	ff 30                	pushl  (%eax)
80101808:	e8 5f e9 ff ff       	call   8010016c <bread>
8010180d:	89 c1                	mov    %eax,%ecx
    m = min(n - tot, BSIZE - off%BSIZE);
8010180f:	89 f8                	mov    %edi,%eax
80101811:	25 ff 01 00 00       	and    $0x1ff,%eax
80101816:	bb 00 02 00 00       	mov    $0x200,%ebx
8010181b:	29 c3                	sub    %eax,%ebx
8010181d:	8b 55 14             	mov    0x14(%ebp),%edx
80101820:	29 f2                	sub    %esi,%edx
80101822:	83 c4 0c             	add    $0xc,%esp
80101825:	39 d3                	cmp    %edx,%ebx
80101827:	0f 47 da             	cmova  %edx,%ebx
    memmove(dst, bp->data + off%BSIZE, m);
8010182a:	53                   	push   %ebx
8010182b:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
8010182e:	8d 44 01 5c          	lea    0x5c(%ecx,%eax,1),%eax
80101832:	50                   	push   %eax
80101833:	ff 75 0c             	pushl  0xc(%ebp)
80101836:	e8 b9 25 00 00       	call   80103df4 <memmove>
    brelse(bp);
8010183b:	83 c4 04             	add    $0x4,%esp
8010183e:	ff 75 e4             	pushl  -0x1c(%ebp)
80101841:	e8 8f e9 ff ff       	call   801001d5 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101846:	01 de                	add    %ebx,%esi
80101848:	01 df                	add    %ebx,%edi
8010184a:	01 5d 0c             	add    %ebx,0xc(%ebp)
8010184d:	83 c4 10             	add    $0x10,%esp
80101850:	39 75 14             	cmp    %esi,0x14(%ebp)
80101853:	77 9d                	ja     801017f2 <readi+0x73>
  return n;
80101855:	8b 45 14             	mov    0x14(%ebp),%eax
}
80101858:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010185b:	5b                   	pop    %ebx
8010185c:	5e                   	pop    %esi
8010185d:	5f                   	pop    %edi
8010185e:	5d                   	pop    %ebp
8010185f:	c3                   	ret    
      return -1;
80101860:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101865:	eb f1                	jmp    80101858 <readi+0xd9>
80101867:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010186c:	eb ea                	jmp    80101858 <readi+0xd9>
    return -1;
8010186e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101873:	eb e3                	jmp    80101858 <readi+0xd9>
80101875:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010187a:	eb dc                	jmp    80101858 <readi+0xd9>

8010187c <writei>:
{
8010187c:	55                   	push   %ebp
8010187d:	89 e5                	mov    %esp,%ebp
8010187f:	57                   	push   %edi
80101880:	56                   	push   %esi
80101881:	53                   	push   %ebx
80101882:	83 ec 0c             	sub    $0xc,%esp
  if(ip->type == T_DEV){
80101885:	8b 45 08             	mov    0x8(%ebp),%eax
80101888:	66 83 78 50 03       	cmpw   $0x3,0x50(%eax)
8010188d:	74 2f                	je     801018be <writei+0x42>
  if(off > ip->size || off + n < off)
8010188f:	8b 45 08             	mov    0x8(%ebp),%eax
80101892:	8b 4d 10             	mov    0x10(%ebp),%ecx
80101895:	39 48 58             	cmp    %ecx,0x58(%eax)
80101898:	0f 82 f4 00 00 00    	jb     80101992 <writei+0x116>
8010189e:	89 c8                	mov    %ecx,%eax
801018a0:	03 45 14             	add    0x14(%ebp),%eax
801018a3:	0f 82 f0 00 00 00    	jb     80101999 <writei+0x11d>
  if(off + n > MAXFILE*BSIZE)
801018a9:	3d 00 18 01 00       	cmp    $0x11800,%eax
801018ae:	0f 87 ec 00 00 00    	ja     801019a0 <writei+0x124>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
801018b4:	be 00 00 00 00       	mov    $0x0,%esi
801018b9:	e9 94 00 00 00       	jmp    80101952 <writei+0xd6>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
801018be:	0f b7 40 52          	movzwl 0x52(%eax),%eax
801018c2:	66 83 f8 09          	cmp    $0x9,%ax
801018c6:	0f 87 b8 00 00 00    	ja     80101984 <writei+0x108>
801018cc:	98                   	cwtl   
801018cd:	8b 04 c5 64 f9 10 80 	mov    -0x7fef069c(,%eax,8),%eax
801018d4:	85 c0                	test   %eax,%eax
801018d6:	0f 84 af 00 00 00    	je     8010198b <writei+0x10f>
    return devsw[ip->major].write(ip, src, n);
801018dc:	83 ec 04             	sub    $0x4,%esp
801018df:	ff 75 14             	pushl  0x14(%ebp)
801018e2:	ff 75 0c             	pushl  0xc(%ebp)
801018e5:	ff 75 08             	pushl  0x8(%ebp)
801018e8:	ff d0                	call   *%eax
801018ea:	83 c4 10             	add    $0x10,%esp
801018ed:	eb 7c                	jmp    8010196b <writei+0xef>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
801018ef:	8b 55 10             	mov    0x10(%ebp),%edx
801018f2:	c1 ea 09             	shr    $0x9,%edx
801018f5:	8b 45 08             	mov    0x8(%ebp),%eax
801018f8:	e8 f0 f7 ff ff       	call   801010ed <bmap>
801018fd:	83 ec 08             	sub    $0x8,%esp
80101900:	50                   	push   %eax
80101901:	8b 45 08             	mov    0x8(%ebp),%eax
80101904:	ff 30                	pushl  (%eax)
80101906:	e8 61 e8 ff ff       	call   8010016c <bread>
8010190b:	89 c7                	mov    %eax,%edi
    m = min(n - tot, BSIZE - off%BSIZE);
8010190d:	8b 45 10             	mov    0x10(%ebp),%eax
80101910:	25 ff 01 00 00       	and    $0x1ff,%eax
80101915:	bb 00 02 00 00       	mov    $0x200,%ebx
8010191a:	29 c3                	sub    %eax,%ebx
8010191c:	8b 55 14             	mov    0x14(%ebp),%edx
8010191f:	29 f2                	sub    %esi,%edx
80101921:	83 c4 0c             	add    $0xc,%esp
80101924:	39 d3                	cmp    %edx,%ebx
80101926:	0f 47 da             	cmova  %edx,%ebx
    memmove(bp->data + off%BSIZE, src, m);
80101929:	53                   	push   %ebx
8010192a:	ff 75 0c             	pushl  0xc(%ebp)
8010192d:	8d 44 07 5c          	lea    0x5c(%edi,%eax,1),%eax
80101931:	50                   	push   %eax
80101932:	e8 bd 24 00 00       	call   80103df4 <memmove>
    log_write(bp);
80101937:	89 3c 24             	mov    %edi,(%esp)
8010193a:	e8 ba 10 00 00       	call   801029f9 <log_write>
    brelse(bp);
8010193f:	89 3c 24             	mov    %edi,(%esp)
80101942:	e8 8e e8 ff ff       	call   801001d5 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80101947:	01 de                	add    %ebx,%esi
80101949:	01 5d 10             	add    %ebx,0x10(%ebp)
8010194c:	01 5d 0c             	add    %ebx,0xc(%ebp)
8010194f:	83 c4 10             	add    $0x10,%esp
80101952:	3b 75 14             	cmp    0x14(%ebp),%esi
80101955:	72 98                	jb     801018ef <writei+0x73>
  if(n > 0 && off > ip->size){
80101957:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
8010195b:	74 0b                	je     80101968 <writei+0xec>
8010195d:	8b 45 08             	mov    0x8(%ebp),%eax
80101960:	8b 4d 10             	mov    0x10(%ebp),%ecx
80101963:	39 48 58             	cmp    %ecx,0x58(%eax)
80101966:	72 0b                	jb     80101973 <writei+0xf7>
  return n;
80101968:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010196b:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010196e:	5b                   	pop    %ebx
8010196f:	5e                   	pop    %esi
80101970:	5f                   	pop    %edi
80101971:	5d                   	pop    %ebp
80101972:	c3                   	ret    
    ip->size = off;
80101973:	89 48 58             	mov    %ecx,0x58(%eax)
    iupdate(ip);
80101976:	83 ec 0c             	sub    $0xc,%esp
80101979:	50                   	push   %eax
8010197a:	e8 ad fa ff ff       	call   8010142c <iupdate>
8010197f:	83 c4 10             	add    $0x10,%esp
80101982:	eb e4                	jmp    80101968 <writei+0xec>
      return -1;
80101984:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101989:	eb e0                	jmp    8010196b <writei+0xef>
8010198b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101990:	eb d9                	jmp    8010196b <writei+0xef>
    return -1;
80101992:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101997:	eb d2                	jmp    8010196b <writei+0xef>
80101999:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010199e:	eb cb                	jmp    8010196b <writei+0xef>
    return -1;
801019a0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801019a5:	eb c4                	jmp    8010196b <writei+0xef>

801019a7 <namecmp>:
{
801019a7:	55                   	push   %ebp
801019a8:	89 e5                	mov    %esp,%ebp
801019aa:	83 ec 0c             	sub    $0xc,%esp
  return strncmp(s, t, DIRSIZ);
801019ad:	6a 0e                	push   $0xe
801019af:	ff 75 0c             	pushl  0xc(%ebp)
801019b2:	ff 75 08             	pushl  0x8(%ebp)
801019b5:	e8 a1 24 00 00       	call   80103e5b <strncmp>
}
801019ba:	c9                   	leave  
801019bb:	c3                   	ret    

801019bc <dirlookup>:
{
801019bc:	55                   	push   %ebp
801019bd:	89 e5                	mov    %esp,%ebp
801019bf:	57                   	push   %edi
801019c0:	56                   	push   %esi
801019c1:	53                   	push   %ebx
801019c2:	83 ec 1c             	sub    $0x1c,%esp
801019c5:	8b 75 08             	mov    0x8(%ebp),%esi
801019c8:	8b 7d 0c             	mov    0xc(%ebp),%edi
  if(dp->type != T_DIR)
801019cb:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
801019d0:	75 07                	jne    801019d9 <dirlookup+0x1d>
  for(off = 0; off < dp->size; off += sizeof(de)){
801019d2:	bb 00 00 00 00       	mov    $0x0,%ebx
801019d7:	eb 1d                	jmp    801019f6 <dirlookup+0x3a>
    panic("dirlookup not DIR");
801019d9:	83 ec 0c             	sub    $0xc,%esp
801019dc:	68 47 67 10 80       	push   $0x80106747
801019e1:	e8 62 e9 ff ff       	call   80100348 <panic>
      panic("dirlookup read");
801019e6:	83 ec 0c             	sub    $0xc,%esp
801019e9:	68 59 67 10 80       	push   $0x80106759
801019ee:	e8 55 e9 ff ff       	call   80100348 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
801019f3:	83 c3 10             	add    $0x10,%ebx
801019f6:	39 5e 58             	cmp    %ebx,0x58(%esi)
801019f9:	76 48                	jbe    80101a43 <dirlookup+0x87>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801019fb:	6a 10                	push   $0x10
801019fd:	53                   	push   %ebx
801019fe:	8d 45 d8             	lea    -0x28(%ebp),%eax
80101a01:	50                   	push   %eax
80101a02:	56                   	push   %esi
80101a03:	e8 77 fd ff ff       	call   8010177f <readi>
80101a08:	83 c4 10             	add    $0x10,%esp
80101a0b:	83 f8 10             	cmp    $0x10,%eax
80101a0e:	75 d6                	jne    801019e6 <dirlookup+0x2a>
    if(de.inum == 0)
80101a10:	66 83 7d d8 00       	cmpw   $0x0,-0x28(%ebp)
80101a15:	74 dc                	je     801019f3 <dirlookup+0x37>
    if(namecmp(name, de.name) == 0){
80101a17:	83 ec 08             	sub    $0x8,%esp
80101a1a:	8d 45 da             	lea    -0x26(%ebp),%eax
80101a1d:	50                   	push   %eax
80101a1e:	57                   	push   %edi
80101a1f:	e8 83 ff ff ff       	call   801019a7 <namecmp>
80101a24:	83 c4 10             	add    $0x10,%esp
80101a27:	85 c0                	test   %eax,%eax
80101a29:	75 c8                	jne    801019f3 <dirlookup+0x37>
      if(poff)
80101a2b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80101a2f:	74 05                	je     80101a36 <dirlookup+0x7a>
        *poff = off;
80101a31:	8b 45 10             	mov    0x10(%ebp),%eax
80101a34:	89 18                	mov    %ebx,(%eax)
      inum = de.inum;
80101a36:	0f b7 55 d8          	movzwl -0x28(%ebp),%edx
      return iget(dp->dev, inum);
80101a3a:	8b 06                	mov    (%esi),%eax
80101a3c:	e8 52 f7 ff ff       	call   80101193 <iget>
80101a41:	eb 05                	jmp    80101a48 <dirlookup+0x8c>
  return 0;
80101a43:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101a48:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101a4b:	5b                   	pop    %ebx
80101a4c:	5e                   	pop    %esi
80101a4d:	5f                   	pop    %edi
80101a4e:	5d                   	pop    %ebp
80101a4f:	c3                   	ret    

80101a50 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
80101a50:	55                   	push   %ebp
80101a51:	89 e5                	mov    %esp,%ebp
80101a53:	57                   	push   %edi
80101a54:	56                   	push   %esi
80101a55:	53                   	push   %ebx
80101a56:	83 ec 1c             	sub    $0x1c,%esp
80101a59:	89 c6                	mov    %eax,%esi
80101a5b:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101a5e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  struct inode *ip, *next;

  if(*path == '/')
80101a61:	80 38 2f             	cmpb   $0x2f,(%eax)
80101a64:	74 17                	je     80101a7d <namex+0x2d>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
80101a66:	e8 c0 18 00 00       	call   8010332b <myproc>
80101a6b:	83 ec 0c             	sub    $0xc,%esp
80101a6e:	ff 70 68             	pushl  0x68(%eax)
80101a71:	e8 e7 fa ff ff       	call   8010155d <idup>
80101a76:	89 c3                	mov    %eax,%ebx
80101a78:	83 c4 10             	add    $0x10,%esp
80101a7b:	eb 53                	jmp    80101ad0 <namex+0x80>
    ip = iget(ROOTDEV, ROOTINO);
80101a7d:	ba 01 00 00 00       	mov    $0x1,%edx
80101a82:	b8 01 00 00 00       	mov    $0x1,%eax
80101a87:	e8 07 f7 ff ff       	call   80101193 <iget>
80101a8c:	89 c3                	mov    %eax,%ebx
80101a8e:	eb 40                	jmp    80101ad0 <namex+0x80>

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
      iunlockput(ip);
80101a90:	83 ec 0c             	sub    $0xc,%esp
80101a93:	53                   	push   %ebx
80101a94:	e8 9b fc ff ff       	call   80101734 <iunlockput>
      return 0;
80101a99:	83 c4 10             	add    $0x10,%esp
80101a9c:	bb 00 00 00 00       	mov    $0x0,%ebx
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
80101aa1:	89 d8                	mov    %ebx,%eax
80101aa3:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101aa6:	5b                   	pop    %ebx
80101aa7:	5e                   	pop    %esi
80101aa8:	5f                   	pop    %edi
80101aa9:	5d                   	pop    %ebp
80101aaa:	c3                   	ret    
    if((next = dirlookup(ip, name, 0)) == 0){
80101aab:	83 ec 04             	sub    $0x4,%esp
80101aae:	6a 00                	push   $0x0
80101ab0:	ff 75 e4             	pushl  -0x1c(%ebp)
80101ab3:	53                   	push   %ebx
80101ab4:	e8 03 ff ff ff       	call   801019bc <dirlookup>
80101ab9:	89 c7                	mov    %eax,%edi
80101abb:	83 c4 10             	add    $0x10,%esp
80101abe:	85 c0                	test   %eax,%eax
80101ac0:	74 4a                	je     80101b0c <namex+0xbc>
    iunlockput(ip);
80101ac2:	83 ec 0c             	sub    $0xc,%esp
80101ac5:	53                   	push   %ebx
80101ac6:	e8 69 fc ff ff       	call   80101734 <iunlockput>
    ip = next;
80101acb:	83 c4 10             	add    $0x10,%esp
80101ace:	89 fb                	mov    %edi,%ebx
  while((path = skipelem(path, name)) != 0){
80101ad0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80101ad3:	89 f0                	mov    %esi,%eax
80101ad5:	e8 77 f4 ff ff       	call   80100f51 <skipelem>
80101ada:	89 c6                	mov    %eax,%esi
80101adc:	85 c0                	test   %eax,%eax
80101ade:	74 3c                	je     80101b1c <namex+0xcc>
    ilock(ip);
80101ae0:	83 ec 0c             	sub    $0xc,%esp
80101ae3:	53                   	push   %ebx
80101ae4:	e8 a4 fa ff ff       	call   8010158d <ilock>
    if(ip->type != T_DIR){
80101ae9:	83 c4 10             	add    $0x10,%esp
80101aec:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80101af1:	75 9d                	jne    80101a90 <namex+0x40>
    if(nameiparent && *path == '\0'){
80101af3:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101af7:	74 b2                	je     80101aab <namex+0x5b>
80101af9:	80 3e 00             	cmpb   $0x0,(%esi)
80101afc:	75 ad                	jne    80101aab <namex+0x5b>
      iunlock(ip);
80101afe:	83 ec 0c             	sub    $0xc,%esp
80101b01:	53                   	push   %ebx
80101b02:	e8 48 fb ff ff       	call   8010164f <iunlock>
      return ip;
80101b07:	83 c4 10             	add    $0x10,%esp
80101b0a:	eb 95                	jmp    80101aa1 <namex+0x51>
      iunlockput(ip);
80101b0c:	83 ec 0c             	sub    $0xc,%esp
80101b0f:	53                   	push   %ebx
80101b10:	e8 1f fc ff ff       	call   80101734 <iunlockput>
      return 0;
80101b15:	83 c4 10             	add    $0x10,%esp
80101b18:	89 fb                	mov    %edi,%ebx
80101b1a:	eb 85                	jmp    80101aa1 <namex+0x51>
  if(nameiparent){
80101b1c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101b20:	0f 84 7b ff ff ff    	je     80101aa1 <namex+0x51>
    iput(ip);
80101b26:	83 ec 0c             	sub    $0xc,%esp
80101b29:	53                   	push   %ebx
80101b2a:	e8 65 fb ff ff       	call   80101694 <iput>
    return 0;
80101b2f:	83 c4 10             	add    $0x10,%esp
80101b32:	bb 00 00 00 00       	mov    $0x0,%ebx
80101b37:	e9 65 ff ff ff       	jmp    80101aa1 <namex+0x51>

80101b3c <dirlink>:
{
80101b3c:	55                   	push   %ebp
80101b3d:	89 e5                	mov    %esp,%ebp
80101b3f:	57                   	push   %edi
80101b40:	56                   	push   %esi
80101b41:	53                   	push   %ebx
80101b42:	83 ec 20             	sub    $0x20,%esp
80101b45:	8b 5d 08             	mov    0x8(%ebp),%ebx
80101b48:	8b 7d 0c             	mov    0xc(%ebp),%edi
  if((ip = dirlookup(dp, name, 0)) != 0){
80101b4b:	6a 00                	push   $0x0
80101b4d:	57                   	push   %edi
80101b4e:	53                   	push   %ebx
80101b4f:	e8 68 fe ff ff       	call   801019bc <dirlookup>
80101b54:	83 c4 10             	add    $0x10,%esp
80101b57:	85 c0                	test   %eax,%eax
80101b59:	75 2d                	jne    80101b88 <dirlink+0x4c>
  for(off = 0; off < dp->size; off += sizeof(de)){
80101b5b:	b8 00 00 00 00       	mov    $0x0,%eax
80101b60:	89 c6                	mov    %eax,%esi
80101b62:	39 43 58             	cmp    %eax,0x58(%ebx)
80101b65:	76 41                	jbe    80101ba8 <dirlink+0x6c>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80101b67:	6a 10                	push   $0x10
80101b69:	50                   	push   %eax
80101b6a:	8d 45 d8             	lea    -0x28(%ebp),%eax
80101b6d:	50                   	push   %eax
80101b6e:	53                   	push   %ebx
80101b6f:	e8 0b fc ff ff       	call   8010177f <readi>
80101b74:	83 c4 10             	add    $0x10,%esp
80101b77:	83 f8 10             	cmp    $0x10,%eax
80101b7a:	75 1f                	jne    80101b9b <dirlink+0x5f>
    if(de.inum == 0)
80101b7c:	66 83 7d d8 00       	cmpw   $0x0,-0x28(%ebp)
80101b81:	74 25                	je     80101ba8 <dirlink+0x6c>
  for(off = 0; off < dp->size; off += sizeof(de)){
80101b83:	8d 46 10             	lea    0x10(%esi),%eax
80101b86:	eb d8                	jmp    80101b60 <dirlink+0x24>
    iput(ip);
80101b88:	83 ec 0c             	sub    $0xc,%esp
80101b8b:	50                   	push   %eax
80101b8c:	e8 03 fb ff ff       	call   80101694 <iput>
    return -1;
80101b91:	83 c4 10             	add    $0x10,%esp
80101b94:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101b99:	eb 3d                	jmp    80101bd8 <dirlink+0x9c>
      panic("dirlink read");
80101b9b:	83 ec 0c             	sub    $0xc,%esp
80101b9e:	68 68 67 10 80       	push   $0x80106768
80101ba3:	e8 a0 e7 ff ff       	call   80100348 <panic>
  strncpy(de.name, name, DIRSIZ);
80101ba8:	83 ec 04             	sub    $0x4,%esp
80101bab:	6a 0e                	push   $0xe
80101bad:	57                   	push   %edi
80101bae:	8d 7d d8             	lea    -0x28(%ebp),%edi
80101bb1:	8d 45 da             	lea    -0x26(%ebp),%eax
80101bb4:	50                   	push   %eax
80101bb5:	e8 de 22 00 00       	call   80103e98 <strncpy>
  de.inum = inum;
80101bba:	8b 45 10             	mov    0x10(%ebp),%eax
80101bbd:	66 89 45 d8          	mov    %ax,-0x28(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80101bc1:	6a 10                	push   $0x10
80101bc3:	56                   	push   %esi
80101bc4:	57                   	push   %edi
80101bc5:	53                   	push   %ebx
80101bc6:	e8 b1 fc ff ff       	call   8010187c <writei>
80101bcb:	83 c4 20             	add    $0x20,%esp
80101bce:	83 f8 10             	cmp    $0x10,%eax
80101bd1:	75 0d                	jne    80101be0 <dirlink+0xa4>
  return 0;
80101bd3:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101bd8:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101bdb:	5b                   	pop    %ebx
80101bdc:	5e                   	pop    %esi
80101bdd:	5f                   	pop    %edi
80101bde:	5d                   	pop    %ebp
80101bdf:	c3                   	ret    
    panic("dirlink");
80101be0:	83 ec 0c             	sub    $0xc,%esp
80101be3:	68 74 6d 10 80       	push   $0x80106d74
80101be8:	e8 5b e7 ff ff       	call   80100348 <panic>

80101bed <namei>:

struct inode*
namei(char *path)
{
80101bed:	55                   	push   %ebp
80101bee:	89 e5                	mov    %esp,%ebp
80101bf0:	83 ec 18             	sub    $0x18,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80101bf3:	8d 4d ea             	lea    -0x16(%ebp),%ecx
80101bf6:	ba 00 00 00 00       	mov    $0x0,%edx
80101bfb:	8b 45 08             	mov    0x8(%ebp),%eax
80101bfe:	e8 4d fe ff ff       	call   80101a50 <namex>
}
80101c03:	c9                   	leave  
80101c04:	c3                   	ret    

80101c05 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80101c05:	55                   	push   %ebp
80101c06:	89 e5                	mov    %esp,%ebp
80101c08:	83 ec 08             	sub    $0x8,%esp
  return namex(path, 1, name);
80101c0b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80101c0e:	ba 01 00 00 00       	mov    $0x1,%edx
80101c13:	8b 45 08             	mov    0x8(%ebp),%eax
80101c16:	e8 35 fe ff ff       	call   80101a50 <namex>
}
80101c1b:	c9                   	leave  
80101c1c:	c3                   	ret    

80101c1d <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
80101c1d:	55                   	push   %ebp
80101c1e:	89 e5                	mov    %esp,%ebp
80101c20:	89 c1                	mov    %eax,%ecx
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80101c22:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101c27:	ec                   	in     (%dx),%al
80101c28:	89 c2                	mov    %eax,%edx
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY)
80101c2a:	83 e0 c0             	and    $0xffffffc0,%eax
80101c2d:	3c 40                	cmp    $0x40,%al
80101c2f:	75 f1                	jne    80101c22 <idewait+0x5>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80101c31:	85 c9                	test   %ecx,%ecx
80101c33:	74 0c                	je     80101c41 <idewait+0x24>
80101c35:	f6 c2 21             	test   $0x21,%dl
80101c38:	75 0e                	jne    80101c48 <idewait+0x2b>
    return -1;
  return 0;
80101c3a:	b8 00 00 00 00       	mov    $0x0,%eax
80101c3f:	eb 05                	jmp    80101c46 <idewait+0x29>
80101c41:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101c46:	5d                   	pop    %ebp
80101c47:	c3                   	ret    
    return -1;
80101c48:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101c4d:	eb f7                	jmp    80101c46 <idewait+0x29>

80101c4f <idestart>:
}

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80101c4f:	55                   	push   %ebp
80101c50:	89 e5                	mov    %esp,%ebp
80101c52:	56                   	push   %esi
80101c53:	53                   	push   %ebx
  if(b == 0)
80101c54:	85 c0                	test   %eax,%eax
80101c56:	74 7d                	je     80101cd5 <idestart+0x86>
80101c58:	89 c6                	mov    %eax,%esi
    panic("idestart");
  if(b->blockno >= FSSIZE)
80101c5a:	8b 58 08             	mov    0x8(%eax),%ebx
80101c5d:	81 fb e7 03 00 00    	cmp    $0x3e7,%ebx
80101c63:	77 7d                	ja     80101ce2 <idestart+0x93>
  int read_cmd = (sector_per_block == 1) ? IDE_CMD_READ :  IDE_CMD_RDMUL;
  int write_cmd = (sector_per_block == 1) ? IDE_CMD_WRITE : IDE_CMD_WRMUL;

  if (sector_per_block > 7) panic("idestart");

  idewait(0);
80101c65:	b8 00 00 00 00       	mov    $0x0,%eax
80101c6a:	e8 ae ff ff ff       	call   80101c1d <idewait>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101c6f:	b8 00 00 00 00       	mov    $0x0,%eax
80101c74:	ba f6 03 00 00       	mov    $0x3f6,%edx
80101c79:	ee                   	out    %al,(%dx)
80101c7a:	b8 01 00 00 00       	mov    $0x1,%eax
80101c7f:	ba f2 01 00 00       	mov    $0x1f2,%edx
80101c84:	ee                   	out    %al,(%dx)
80101c85:	ba f3 01 00 00       	mov    $0x1f3,%edx
80101c8a:	89 d8                	mov    %ebx,%eax
80101c8c:	ee                   	out    %al,(%dx)
  outb(0x3f6, 0);  // generate interrupt
  outb(0x1f2, sector_per_block);  // number of sectors
  outb(0x1f3, sector & 0xff);
  outb(0x1f4, (sector >> 8) & 0xff);
80101c8d:	89 d8                	mov    %ebx,%eax
80101c8f:	c1 f8 08             	sar    $0x8,%eax
80101c92:	ba f4 01 00 00       	mov    $0x1f4,%edx
80101c97:	ee                   	out    %al,(%dx)
  outb(0x1f5, (sector >> 16) & 0xff);
80101c98:	89 d8                	mov    %ebx,%eax
80101c9a:	c1 f8 10             	sar    $0x10,%eax
80101c9d:	ba f5 01 00 00       	mov    $0x1f5,%edx
80101ca2:	ee                   	out    %al,(%dx)
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((sector>>24)&0x0f));
80101ca3:	0f b6 46 04          	movzbl 0x4(%esi),%eax
80101ca7:	c1 e0 04             	shl    $0x4,%eax
80101caa:	83 e0 10             	and    $0x10,%eax
80101cad:	c1 fb 18             	sar    $0x18,%ebx
80101cb0:	83 e3 0f             	and    $0xf,%ebx
80101cb3:	09 d8                	or     %ebx,%eax
80101cb5:	83 c8 e0             	or     $0xffffffe0,%eax
80101cb8:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101cbd:	ee                   	out    %al,(%dx)
  if(b->flags & B_DIRTY){
80101cbe:	f6 06 04             	testb  $0x4,(%esi)
80101cc1:	75 2c                	jne    80101cef <idestart+0xa0>
80101cc3:	b8 20 00 00 00       	mov    $0x20,%eax
80101cc8:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101ccd:	ee                   	out    %al,(%dx)
    outb(0x1f7, write_cmd);
    outsl(0x1f0, b->data, BSIZE/4);
  } else {
    outb(0x1f7, read_cmd);
  }
}
80101cce:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101cd1:	5b                   	pop    %ebx
80101cd2:	5e                   	pop    %esi
80101cd3:	5d                   	pop    %ebp
80101cd4:	c3                   	ret    
    panic("idestart");
80101cd5:	83 ec 0c             	sub    $0xc,%esp
80101cd8:	68 cb 67 10 80       	push   $0x801067cb
80101cdd:	e8 66 e6 ff ff       	call   80100348 <panic>
    panic("incorrect blockno");
80101ce2:	83 ec 0c             	sub    $0xc,%esp
80101ce5:	68 d4 67 10 80       	push   $0x801067d4
80101cea:	e8 59 e6 ff ff       	call   80100348 <panic>
80101cef:	b8 30 00 00 00       	mov    $0x30,%eax
80101cf4:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101cf9:	ee                   	out    %al,(%dx)
    outsl(0x1f0, b->data, BSIZE/4);
80101cfa:	83 c6 5c             	add    $0x5c,%esi
  asm volatile("cld; rep outsl" :
80101cfd:	b9 80 00 00 00       	mov    $0x80,%ecx
80101d02:	ba f0 01 00 00       	mov    $0x1f0,%edx
80101d07:	fc                   	cld    
80101d08:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80101d0a:	eb c2                	jmp    80101cce <idestart+0x7f>

80101d0c <ideinit>:
{
80101d0c:	55                   	push   %ebp
80101d0d:	89 e5                	mov    %esp,%ebp
80101d0f:	83 ec 10             	sub    $0x10,%esp
  initlock(&idelock, "ide");
80101d12:	68 e6 67 10 80       	push   $0x801067e6
80101d17:	68 80 95 10 80       	push   $0x80109580
80101d1c:	e8 70 1e 00 00       	call   80103b91 <initlock>
  ioapicenable(IRQ_IDE, ncpu - 1);
80101d21:	83 c4 08             	add    $0x8,%esp
80101d24:	a1 20 1d 19 80       	mov    0x80191d20,%eax
80101d29:	83 e8 01             	sub    $0x1,%eax
80101d2c:	50                   	push   %eax
80101d2d:	6a 0e                	push   $0xe
80101d2f:	e8 56 02 00 00       	call   80101f8a <ioapicenable>
  idewait(0);
80101d34:	b8 00 00 00 00       	mov    $0x0,%eax
80101d39:	e8 df fe ff ff       	call   80101c1d <idewait>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101d3e:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
80101d43:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101d48:	ee                   	out    %al,(%dx)
  for(i=0; i<1000; i++){
80101d49:	83 c4 10             	add    $0x10,%esp
80101d4c:	b9 00 00 00 00       	mov    $0x0,%ecx
80101d51:	81 f9 e7 03 00 00    	cmp    $0x3e7,%ecx
80101d57:	7f 19                	jg     80101d72 <ideinit+0x66>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80101d59:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101d5e:	ec                   	in     (%dx),%al
    if(inb(0x1f7) != 0){
80101d5f:	84 c0                	test   %al,%al
80101d61:	75 05                	jne    80101d68 <ideinit+0x5c>
  for(i=0; i<1000; i++){
80101d63:	83 c1 01             	add    $0x1,%ecx
80101d66:	eb e9                	jmp    80101d51 <ideinit+0x45>
      havedisk1 = 1;
80101d68:	c7 05 60 95 10 80 01 	movl   $0x1,0x80109560
80101d6f:	00 00 00 
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101d72:	b8 e0 ff ff ff       	mov    $0xffffffe0,%eax
80101d77:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101d7c:	ee                   	out    %al,(%dx)
}
80101d7d:	c9                   	leave  
80101d7e:	c3                   	ret    

80101d7f <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80101d7f:	55                   	push   %ebp
80101d80:	89 e5                	mov    %esp,%ebp
80101d82:	57                   	push   %edi
80101d83:	53                   	push   %ebx
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
80101d84:	83 ec 0c             	sub    $0xc,%esp
80101d87:	68 80 95 10 80       	push   $0x80109580
80101d8c:	e8 3c 1f 00 00       	call   80103ccd <acquire>

  if((b = idequeue) == 0){
80101d91:	8b 1d 64 95 10 80    	mov    0x80109564,%ebx
80101d97:	83 c4 10             	add    $0x10,%esp
80101d9a:	85 db                	test   %ebx,%ebx
80101d9c:	74 48                	je     80101de6 <ideintr+0x67>
    release(&idelock);
    return;
  }
  idequeue = b->qnext;
80101d9e:	8b 43 58             	mov    0x58(%ebx),%eax
80101da1:	a3 64 95 10 80       	mov    %eax,0x80109564

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80101da6:	f6 03 04             	testb  $0x4,(%ebx)
80101da9:	74 4d                	je     80101df8 <ideintr+0x79>
    insl(0x1f0, b->data, BSIZE/4);

  // Wake process waiting for this buf.
  b->flags |= B_VALID;
80101dab:	8b 03                	mov    (%ebx),%eax
80101dad:	83 c8 02             	or     $0x2,%eax
  b->flags &= ~B_DIRTY;
80101db0:	83 e0 fb             	and    $0xfffffffb,%eax
80101db3:	89 03                	mov    %eax,(%ebx)
  wakeup(b);
80101db5:	83 ec 0c             	sub    $0xc,%esp
80101db8:	53                   	push   %ebx
80101db9:	e8 79 1b 00 00       	call   80103937 <wakeup>

  // Start disk on next buf in queue.
  if(idequeue != 0)
80101dbe:	a1 64 95 10 80       	mov    0x80109564,%eax
80101dc3:	83 c4 10             	add    $0x10,%esp
80101dc6:	85 c0                	test   %eax,%eax
80101dc8:	74 05                	je     80101dcf <ideintr+0x50>
    idestart(idequeue);
80101dca:	e8 80 fe ff ff       	call   80101c4f <idestart>

  release(&idelock);
80101dcf:	83 ec 0c             	sub    $0xc,%esp
80101dd2:	68 80 95 10 80       	push   $0x80109580
80101dd7:	e8 56 1f 00 00       	call   80103d32 <release>
80101ddc:	83 c4 10             	add    $0x10,%esp
}
80101ddf:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101de2:	5b                   	pop    %ebx
80101de3:	5f                   	pop    %edi
80101de4:	5d                   	pop    %ebp
80101de5:	c3                   	ret    
    release(&idelock);
80101de6:	83 ec 0c             	sub    $0xc,%esp
80101de9:	68 80 95 10 80       	push   $0x80109580
80101dee:	e8 3f 1f 00 00       	call   80103d32 <release>
    return;
80101df3:	83 c4 10             	add    $0x10,%esp
80101df6:	eb e7                	jmp    80101ddf <ideintr+0x60>
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80101df8:	b8 01 00 00 00       	mov    $0x1,%eax
80101dfd:	e8 1b fe ff ff       	call   80101c1d <idewait>
80101e02:	85 c0                	test   %eax,%eax
80101e04:	78 a5                	js     80101dab <ideintr+0x2c>
    insl(0x1f0, b->data, BSIZE/4);
80101e06:	8d 7b 5c             	lea    0x5c(%ebx),%edi
  asm volatile("cld; rep insl" :
80101e09:	b9 80 00 00 00       	mov    $0x80,%ecx
80101e0e:	ba f0 01 00 00       	mov    $0x1f0,%edx
80101e13:	fc                   	cld    
80101e14:	f3 6d                	rep insl (%dx),%es:(%edi)
80101e16:	eb 93                	jmp    80101dab <ideintr+0x2c>

80101e18 <iderw>:
// Sync buf with disk.
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80101e18:	55                   	push   %ebp
80101e19:	89 e5                	mov    %esp,%ebp
80101e1b:	53                   	push   %ebx
80101e1c:	83 ec 10             	sub    $0x10,%esp
80101e1f:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct buf **pp;

  if(!holdingsleep(&b->lock))
80101e22:	8d 43 0c             	lea    0xc(%ebx),%eax
80101e25:	50                   	push   %eax
80101e26:	e8 18 1d 00 00       	call   80103b43 <holdingsleep>
80101e2b:	83 c4 10             	add    $0x10,%esp
80101e2e:	85 c0                	test   %eax,%eax
80101e30:	74 37                	je     80101e69 <iderw+0x51>
    panic("iderw: buf not locked");
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80101e32:	8b 03                	mov    (%ebx),%eax
80101e34:	83 e0 06             	and    $0x6,%eax
80101e37:	83 f8 02             	cmp    $0x2,%eax
80101e3a:	74 3a                	je     80101e76 <iderw+0x5e>
    panic("iderw: nothing to do");
  if(b->dev != 0 && !havedisk1)
80101e3c:	83 7b 04 00          	cmpl   $0x0,0x4(%ebx)
80101e40:	74 09                	je     80101e4b <iderw+0x33>
80101e42:	83 3d 60 95 10 80 00 	cmpl   $0x0,0x80109560
80101e49:	74 38                	je     80101e83 <iderw+0x6b>
    panic("iderw: ide disk 1 not present");

  acquire(&idelock);  //DOC:acquire-lock
80101e4b:	83 ec 0c             	sub    $0xc,%esp
80101e4e:	68 80 95 10 80       	push   $0x80109580
80101e53:	e8 75 1e 00 00       	call   80103ccd <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80101e58:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e5f:	83 c4 10             	add    $0x10,%esp
80101e62:	ba 64 95 10 80       	mov    $0x80109564,%edx
80101e67:	eb 2a                	jmp    80101e93 <iderw+0x7b>
    panic("iderw: buf not locked");
80101e69:	83 ec 0c             	sub    $0xc,%esp
80101e6c:	68 ea 67 10 80       	push   $0x801067ea
80101e71:	e8 d2 e4 ff ff       	call   80100348 <panic>
    panic("iderw: nothing to do");
80101e76:	83 ec 0c             	sub    $0xc,%esp
80101e79:	68 00 68 10 80       	push   $0x80106800
80101e7e:	e8 c5 e4 ff ff       	call   80100348 <panic>
    panic("iderw: ide disk 1 not present");
80101e83:	83 ec 0c             	sub    $0xc,%esp
80101e86:	68 15 68 10 80       	push   $0x80106815
80101e8b:	e8 b8 e4 ff ff       	call   80100348 <panic>
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e90:	8d 50 58             	lea    0x58(%eax),%edx
80101e93:	8b 02                	mov    (%edx),%eax
80101e95:	85 c0                	test   %eax,%eax
80101e97:	75 f7                	jne    80101e90 <iderw+0x78>
    ;
  *pp = b;
80101e99:	89 1a                	mov    %ebx,(%edx)

  // Start disk if necessary.
  if(idequeue == b)
80101e9b:	39 1d 64 95 10 80    	cmp    %ebx,0x80109564
80101ea1:	75 1a                	jne    80101ebd <iderw+0xa5>
    idestart(b);
80101ea3:	89 d8                	mov    %ebx,%eax
80101ea5:	e8 a5 fd ff ff       	call   80101c4f <idestart>
80101eaa:	eb 11                	jmp    80101ebd <iderw+0xa5>

  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
    sleep(b, &idelock);
80101eac:	83 ec 08             	sub    $0x8,%esp
80101eaf:	68 80 95 10 80       	push   $0x80109580
80101eb4:	53                   	push   %ebx
80101eb5:	e8 18 19 00 00       	call   801037d2 <sleep>
80101eba:	83 c4 10             	add    $0x10,%esp
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80101ebd:	8b 03                	mov    (%ebx),%eax
80101ebf:	83 e0 06             	and    $0x6,%eax
80101ec2:	83 f8 02             	cmp    $0x2,%eax
80101ec5:	75 e5                	jne    80101eac <iderw+0x94>
  }


  release(&idelock);
80101ec7:	83 ec 0c             	sub    $0xc,%esp
80101eca:	68 80 95 10 80       	push   $0x80109580
80101ecf:	e8 5e 1e 00 00       	call   80103d32 <release>
}
80101ed4:	83 c4 10             	add    $0x10,%esp
80101ed7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101eda:	c9                   	leave  
80101edb:	c3                   	ret    

80101edc <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80101edc:	55                   	push   %ebp
80101edd:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80101edf:	8b 15 34 16 11 80    	mov    0x80111634,%edx
80101ee5:	89 02                	mov    %eax,(%edx)
  return ioapic->data;
80101ee7:	a1 34 16 11 80       	mov    0x80111634,%eax
80101eec:	8b 40 10             	mov    0x10(%eax),%eax
}
80101eef:	5d                   	pop    %ebp
80101ef0:	c3                   	ret    

80101ef1 <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80101ef1:	55                   	push   %ebp
80101ef2:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80101ef4:	8b 0d 34 16 11 80    	mov    0x80111634,%ecx
80101efa:	89 01                	mov    %eax,(%ecx)
  ioapic->data = data;
80101efc:	a1 34 16 11 80       	mov    0x80111634,%eax
80101f01:	89 50 10             	mov    %edx,0x10(%eax)
}
80101f04:	5d                   	pop    %ebp
80101f05:	c3                   	ret    

80101f06 <ioapicinit>:

void
ioapicinit(void)
{
80101f06:	55                   	push   %ebp
80101f07:	89 e5                	mov    %esp,%ebp
80101f09:	57                   	push   %edi
80101f0a:	56                   	push   %esi
80101f0b:	53                   	push   %ebx
80101f0c:	83 ec 0c             	sub    $0xc,%esp
  int i, id, maxintr;

  ioapic = (volatile struct ioapic*)IOAPIC;
80101f0f:	c7 05 34 16 11 80 00 	movl   $0xfec00000,0x80111634
80101f16:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80101f19:	b8 01 00 00 00       	mov    $0x1,%eax
80101f1e:	e8 b9 ff ff ff       	call   80101edc <ioapicread>
80101f23:	c1 e8 10             	shr    $0x10,%eax
80101f26:	0f b6 f8             	movzbl %al,%edi
  id = ioapicread(REG_ID) >> 24;
80101f29:	b8 00 00 00 00       	mov    $0x0,%eax
80101f2e:	e8 a9 ff ff ff       	call   80101edc <ioapicread>
80101f33:	c1 e8 18             	shr    $0x18,%eax
  if(id != ioapicid)
80101f36:	0f b6 15 80 17 19 80 	movzbl 0x80191780,%edx
80101f3d:	39 c2                	cmp    %eax,%edx
80101f3f:	75 07                	jne    80101f48 <ioapicinit+0x42>
{
80101f41:	bb 00 00 00 00       	mov    $0x0,%ebx
80101f46:	eb 36                	jmp    80101f7e <ioapicinit+0x78>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80101f48:	83 ec 0c             	sub    $0xc,%esp
80101f4b:	68 34 68 10 80       	push   $0x80106834
80101f50:	e8 b6 e6 ff ff       	call   8010060b <cprintf>
80101f55:	83 c4 10             	add    $0x10,%esp
80101f58:	eb e7                	jmp    80101f41 <ioapicinit+0x3b>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80101f5a:	8d 53 20             	lea    0x20(%ebx),%edx
80101f5d:	81 ca 00 00 01 00    	or     $0x10000,%edx
80101f63:	8d 74 1b 10          	lea    0x10(%ebx,%ebx,1),%esi
80101f67:	89 f0                	mov    %esi,%eax
80101f69:	e8 83 ff ff ff       	call   80101ef1 <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80101f6e:	8d 46 01             	lea    0x1(%esi),%eax
80101f71:	ba 00 00 00 00       	mov    $0x0,%edx
80101f76:	e8 76 ff ff ff       	call   80101ef1 <ioapicwrite>
  for(i = 0; i <= maxintr; i++){
80101f7b:	83 c3 01             	add    $0x1,%ebx
80101f7e:	39 fb                	cmp    %edi,%ebx
80101f80:	7e d8                	jle    80101f5a <ioapicinit+0x54>
  }
}
80101f82:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101f85:	5b                   	pop    %ebx
80101f86:	5e                   	pop    %esi
80101f87:	5f                   	pop    %edi
80101f88:	5d                   	pop    %ebp
80101f89:	c3                   	ret    

80101f8a <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80101f8a:	55                   	push   %ebp
80101f8b:	89 e5                	mov    %esp,%ebp
80101f8d:	53                   	push   %ebx
80101f8e:	8b 45 08             	mov    0x8(%ebp),%eax
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80101f91:	8d 50 20             	lea    0x20(%eax),%edx
80101f94:	8d 5c 00 10          	lea    0x10(%eax,%eax,1),%ebx
80101f98:	89 d8                	mov    %ebx,%eax
80101f9a:	e8 52 ff ff ff       	call   80101ef1 <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80101f9f:	8b 55 0c             	mov    0xc(%ebp),%edx
80101fa2:	c1 e2 18             	shl    $0x18,%edx
80101fa5:	8d 43 01             	lea    0x1(%ebx),%eax
80101fa8:	e8 44 ff ff ff       	call   80101ef1 <ioapicwrite>
}
80101fad:	5b                   	pop    %ebx
80101fae:	5d                   	pop    %ebp
80101faf:	c3                   	ret    

80101fb0 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80101fb0:	55                   	push   %ebp
80101fb1:	89 e5                	mov    %esp,%ebp
80101fb3:	53                   	push   %ebx
80101fb4:	83 ec 04             	sub    $0x4,%esp
80101fb7:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct run *r;

  if((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
80101fba:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
80101fc0:	75 4c                	jne    8010200e <kfree+0x5e>
80101fc2:	81 fb c8 44 19 80    	cmp    $0x801944c8,%ebx
80101fc8:	72 44                	jb     8010200e <kfree+0x5e>
80101fca:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80101fd0:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80101fd5:	77 37                	ja     8010200e <kfree+0x5e>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80101fd7:	83 ec 04             	sub    $0x4,%esp
80101fda:	68 00 10 00 00       	push   $0x1000
80101fdf:	6a 01                	push   $0x1
80101fe1:	53                   	push   %ebx
80101fe2:	e8 92 1d 00 00       	call   80103d79 <memset>

  if(kmem.use_lock)
80101fe7:	83 c4 10             	add    $0x10,%esp
80101fea:	83 3d 74 16 11 80 00 	cmpl   $0x0,0x80111674
80101ff1:	75 28                	jne    8010201b <kfree+0x6b>
    acquire(&kmem.lock);
  r = (struct run*)v;
  r->next = kmem.freelist;
80101ff3:	a1 78 16 11 80       	mov    0x80111678,%eax
80101ff8:	89 03                	mov    %eax,(%ebx)
  kmem.freelist = r;
80101ffa:	89 1d 78 16 11 80    	mov    %ebx,0x80111678
  if(kmem.use_lock)
80102000:	83 3d 74 16 11 80 00 	cmpl   $0x0,0x80111674
80102007:	75 24                	jne    8010202d <kfree+0x7d>
    release(&kmem.lock);
}
80102009:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010200c:	c9                   	leave  
8010200d:	c3                   	ret    
    panic("kfree");
8010200e:	83 ec 0c             	sub    $0xc,%esp
80102011:	68 66 68 10 80       	push   $0x80106866
80102016:	e8 2d e3 ff ff       	call   80100348 <panic>
    acquire(&kmem.lock);
8010201b:	83 ec 0c             	sub    $0xc,%esp
8010201e:	68 40 16 11 80       	push   $0x80111640
80102023:	e8 a5 1c 00 00       	call   80103ccd <acquire>
80102028:	83 c4 10             	add    $0x10,%esp
8010202b:	eb c6                	jmp    80101ff3 <kfree+0x43>
    release(&kmem.lock);
8010202d:	83 ec 0c             	sub    $0xc,%esp
80102030:	68 40 16 11 80       	push   $0x80111640
80102035:	e8 f8 1c 00 00       	call   80103d32 <release>
8010203a:	83 c4 10             	add    $0x10,%esp
}
8010203d:	eb ca                	jmp    80102009 <kfree+0x59>

8010203f <freerange>:
{
8010203f:	55                   	push   %ebp
80102040:	89 e5                	mov    %esp,%ebp
80102042:	56                   	push   %esi
80102043:	53                   	push   %ebx
80102044:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  p = (char*)PGROUNDUP((uint)vstart);
80102047:	8b 45 08             	mov    0x8(%ebp),%eax
8010204a:	05 ff 0f 00 00       	add    $0xfff,%eax
8010204f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102054:	eb 0e                	jmp    80102064 <freerange+0x25>
    kfree(p);
80102056:	83 ec 0c             	sub    $0xc,%esp
80102059:	50                   	push   %eax
8010205a:	e8 51 ff ff ff       	call   80101fb0 <kfree>
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
8010205f:	83 c4 10             	add    $0x10,%esp
80102062:	89 f0                	mov    %esi,%eax
80102064:	8d b0 00 10 00 00    	lea    0x1000(%eax),%esi
8010206a:	39 de                	cmp    %ebx,%esi
8010206c:	76 e8                	jbe    80102056 <freerange+0x17>
}
8010206e:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102071:	5b                   	pop    %ebx
80102072:	5e                   	pop    %esi
80102073:	5d                   	pop    %ebp
80102074:	c3                   	ret    

80102075 <kinit1>:
{
80102075:	55                   	push   %ebp
80102076:	89 e5                	mov    %esp,%ebp
80102078:	83 ec 10             	sub    $0x10,%esp
  initlock(&kmem.lock, "kmem");
8010207b:	68 6c 68 10 80       	push   $0x8010686c
80102080:	68 40 16 11 80       	push   $0x80111640
80102085:	e8 07 1b 00 00       	call   80103b91 <initlock>
  kmem.use_lock = 0;
8010208a:	c7 05 74 16 11 80 00 	movl   $0x0,0x80111674
80102091:	00 00 00 
  freerange(vstart, vend);
80102094:	83 c4 08             	add    $0x8,%esp
80102097:	ff 75 0c             	pushl  0xc(%ebp)
8010209a:	ff 75 08             	pushl  0x8(%ebp)
8010209d:	e8 9d ff ff ff       	call   8010203f <freerange>
}
801020a2:	83 c4 10             	add    $0x10,%esp
801020a5:	c9                   	leave  
801020a6:	c3                   	ret    

801020a7 <kinit2>:
{
801020a7:	55                   	push   %ebp
801020a8:	89 e5                	mov    %esp,%ebp
801020aa:	83 ec 10             	sub    $0x10,%esp
  freerange(vstart, vend);
801020ad:	ff 75 0c             	pushl  0xc(%ebp)
801020b0:	ff 75 08             	pushl  0x8(%ebp)
801020b3:	e8 87 ff ff ff       	call   8010203f <freerange>
  kmem.use_lock = 1;
801020b8:	c7 05 74 16 11 80 01 	movl   $0x1,0x80111674
801020bf:	00 00 00 
  for(int i = 0; i < 16384; i++) {
801020c2:	83 c4 10             	add    $0x10,%esp
801020c5:	b8 00 00 00 00       	mov    $0x0,%eax
801020ca:	eb 19                	jmp    801020e5 <kinit2+0x3e>
  	framearr[i] = -1;
801020cc:	c7 04 85 80 16 15 80 	movl   $0xffffffff,-0x7feae980(,%eax,4)
801020d3:	ff ff ff ff 
  	pidarr[i] = -1;
801020d7:	c7 04 85 80 16 11 80 	movl   $0xffffffff,-0x7feee980(,%eax,4)
801020de:	ff ff ff ff 
  for(int i = 0; i < 16384; i++) {
801020e2:	83 c0 01             	add    $0x1,%eax
801020e5:	3d ff 3f 00 00       	cmp    $0x3fff,%eax
801020ea:	7e e0                	jle    801020cc <kinit2+0x25>
	totalframes = 0;
801020ec:	c7 05 7c 16 11 80 00 	movl   $0x0,0x8011167c
801020f3:	00 00 00 
}
801020f6:	c9                   	leave  
801020f7:	c3                   	ret    

801020f8 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(int pid)
{
801020f8:	55                   	push   %ebp
801020f9:	89 e5                	mov    %esp,%ebp
801020fb:	53                   	push   %ebx
801020fc:	83 ec 04             	sub    $0x4,%esp
  struct run *r;

  if(kmem.use_lock)
801020ff:	83 3d 74 16 11 80 00 	cmpl   $0x0,0x80111674
80102106:	75 51                	jne    80102159 <kalloc+0x61>
    acquire(&kmem.lock);
  r = kmem.freelist;
80102108:	8b 1d 78 16 11 80    	mov    0x80111678,%ebx
  if(r && r->next)
8010210e:	85 db                	test   %ebx,%ebx
80102110:	74 0d                	je     8010211f <kalloc+0x27>
80102112:	8b 03                	mov    (%ebx),%eax
80102114:	85 c0                	test   %eax,%eax
80102116:	74 07                	je     8010211f <kalloc+0x27>
    kmem.freelist = (r->next)->next;
80102118:	8b 00                	mov    (%eax),%eax
8010211a:	a3 78 16 11 80       	mov    %eax,0x80111678
  int pa;
  int framenum;
  pa = V2P(r);
8010211f:	8d 93 00 00 00 80    	lea    -0x80000000(%ebx),%edx
  framenum = (pa >> 12) & 0xffff;
80102125:	c1 fa 0c             	sar    $0xc,%edx
80102128:	0f b7 d2             	movzwl %dx,%edx
  
  framearr[totalframes] = framenum;
8010212b:	a1 7c 16 11 80       	mov    0x8011167c,%eax
80102130:	89 14 85 80 16 15 80 	mov    %edx,-0x7feae980(,%eax,4)
  pidarr[totalframes] = pid;
80102137:	8b 55 08             	mov    0x8(%ebp),%edx
8010213a:	89 14 85 80 16 11 80 	mov    %edx,-0x7feee980(,%eax,4)
  totalframes++;
80102141:	83 c0 01             	add    $0x1,%eax
80102144:	a3 7c 16 11 80       	mov    %eax,0x8011167c
		break;
  }
  cprintf("\n Frame Count: %d \n", framecount); //ADDED
*/
	  
  if(kmem.use_lock)
80102149:	83 3d 74 16 11 80 00 	cmpl   $0x0,0x80111674
80102150:	75 19                	jne    8010216b <kalloc+0x73>
    release(&kmem.lock);
  return (char*)r;
}
80102152:	89 d8                	mov    %ebx,%eax
80102154:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102157:	c9                   	leave  
80102158:	c3                   	ret    
    acquire(&kmem.lock);
80102159:	83 ec 0c             	sub    $0xc,%esp
8010215c:	68 40 16 11 80       	push   $0x80111640
80102161:	e8 67 1b 00 00       	call   80103ccd <acquire>
80102166:	83 c4 10             	add    $0x10,%esp
80102169:	eb 9d                	jmp    80102108 <kalloc+0x10>
    release(&kmem.lock);
8010216b:	83 ec 0c             	sub    $0xc,%esp
8010216e:	68 40 16 11 80       	push   $0x80111640
80102173:	e8 ba 1b 00 00       	call   80103d32 <release>
80102178:	83 c4 10             	add    $0x10,%esp
  return (char*)r;
8010217b:	eb d5                	jmp    80102152 <kalloc+0x5a>

8010217d <dump_physmem>:

int
dump_physmem(int *frames, int *pids, int numframes)
{
8010217d:	55                   	push   %ebp
8010217e:	89 e5                	mov    %esp,%ebp
80102180:	57                   	push   %edi
80102181:	56                   	push   %esi
80102182:	53                   	push   %ebx
80102183:	83 ec 0c             	sub    $0xc,%esp
80102186:	8b 5d 08             	mov    0x8(%ebp),%ebx
80102189:	8b 75 0c             	mov    0xc(%ebp),%esi
8010218c:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(kmem.use_lock)
8010218f:	83 3d 74 16 11 80 00 	cmpl   $0x0,0x80111674
80102196:	75 28                	jne    801021c0 <dump_physmem+0x43>
    release(&kmem.lock);
  
	return -1;
  	
  }*/
  if(!frames || !pids) {
80102198:	85 db                	test   %ebx,%ebx
8010219a:	0f 94 c2             	sete   %dl
8010219d:	85 f6                	test   %esi,%esi
8010219f:	0f 94 c0             	sete   %al
801021a2:	08 c2                	or     %al,%dl
801021a4:	0f 84 81 00 00 00    	je     8010222b <dump_physmem+0xae>
  	if(kmem.use_lock)
801021aa:	83 3d 74 16 11 80 00 	cmpl   $0x0,0x80111674
801021b1:	75 1f                	jne    801021d2 <dump_physmem+0x55>
    		release(&kmem.lock);
  
  	return -1;
801021b3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  //numframe = totalframes;
  if(kmem.use_lock)
    release(&kmem.lock);
  
	return 0;
}
801021b8:	8d 65 f4             	lea    -0xc(%ebp),%esp
801021bb:	5b                   	pop    %ebx
801021bc:	5e                   	pop    %esi
801021bd:	5f                   	pop    %edi
801021be:	5d                   	pop    %ebp
801021bf:	c3                   	ret    
    acquire(&kmem.lock);
801021c0:	83 ec 0c             	sub    $0xc,%esp
801021c3:	68 40 16 11 80       	push   $0x80111640
801021c8:	e8 00 1b 00 00       	call   80103ccd <acquire>
801021cd:	83 c4 10             	add    $0x10,%esp
801021d0:	eb c6                	jmp    80102198 <dump_physmem+0x1b>
    		release(&kmem.lock);
801021d2:	83 ec 0c             	sub    $0xc,%esp
801021d5:	68 40 16 11 80       	push   $0x80111640
801021da:	e8 53 1b 00 00       	call   80103d32 <release>
801021df:	83 c4 10             	add    $0x10,%esp
  	return -1;
801021e2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801021e7:	eb cf                	jmp    801021b8 <dump_physmem+0x3b>
  	frames[i] = framearr[i];
801021e9:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801021f0:	8b 0c 85 80 16 15 80 	mov    -0x7feae980(,%eax,4),%ecx
801021f7:	89 0c 13             	mov    %ecx,(%ebx,%edx,1)
  	pids[i] = pidarr[i];
801021fa:	8b 0c 85 80 16 11 80 	mov    -0x7feee980(,%eax,4),%ecx
80102201:	89 0c 16             	mov    %ecx,(%esi,%edx,1)
  for(int i = 0; i < numframes; i++) {
80102204:	83 c0 01             	add    $0x1,%eax
80102207:	39 f8                	cmp    %edi,%eax
80102209:	7c de                	jl     801021e9 <dump_physmem+0x6c>
  if(kmem.use_lock)
8010220b:	a1 74 16 11 80       	mov    0x80111674,%eax
80102210:	85 c0                	test   %eax,%eax
80102212:	74 a4                	je     801021b8 <dump_physmem+0x3b>
    release(&kmem.lock);
80102214:	83 ec 0c             	sub    $0xc,%esp
80102217:	68 40 16 11 80       	push   $0x80111640
8010221c:	e8 11 1b 00 00       	call   80103d32 <release>
80102221:	83 c4 10             	add    $0x10,%esp
	return 0;
80102224:	b8 00 00 00 00       	mov    $0x0,%eax
80102229:	eb 8d                	jmp    801021b8 <dump_physmem+0x3b>
  for(int i = 0; i < numframes; i++) {
8010222b:	b8 00 00 00 00       	mov    $0x0,%eax
80102230:	eb d5                	jmp    80102207 <dump_physmem+0x8a>

80102232 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102232:	55                   	push   %ebp
80102233:	89 e5                	mov    %esp,%ebp
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102235:	ba 64 00 00 00       	mov    $0x64,%edx
8010223a:	ec                   	in     (%dx),%al
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
  if((st & KBS_DIB) == 0)
8010223b:	a8 01                	test   $0x1,%al
8010223d:	0f 84 b5 00 00 00    	je     801022f8 <kbdgetc+0xc6>
80102243:	ba 60 00 00 00       	mov    $0x60,%edx
80102248:	ec                   	in     (%dx),%al
    return -1;
  data = inb(KBDATAP);
80102249:	0f b6 d0             	movzbl %al,%edx

  if(data == 0xE0){
8010224c:	81 fa e0 00 00 00    	cmp    $0xe0,%edx
80102252:	74 5c                	je     801022b0 <kbdgetc+0x7e>
    shift |= E0ESC;
    return 0;
  } else if(data & 0x80){
80102254:	84 c0                	test   %al,%al
80102256:	78 66                	js     801022be <kbdgetc+0x8c>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
    shift &= ~(shiftcode[data] | E0ESC);
    return 0;
  } else if(shift & E0ESC){
80102258:	8b 0d b4 95 10 80    	mov    0x801095b4,%ecx
8010225e:	f6 c1 40             	test   $0x40,%cl
80102261:	74 0f                	je     80102272 <kbdgetc+0x40>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102263:	83 c8 80             	or     $0xffffff80,%eax
80102266:	0f b6 d0             	movzbl %al,%edx
    shift &= ~E0ESC;
80102269:	83 e1 bf             	and    $0xffffffbf,%ecx
8010226c:	89 0d b4 95 10 80    	mov    %ecx,0x801095b4
  }

  shift |= shiftcode[data];
80102272:	0f b6 8a a0 69 10 80 	movzbl -0x7fef9660(%edx),%ecx
80102279:	0b 0d b4 95 10 80    	or     0x801095b4,%ecx
  shift ^= togglecode[data];
8010227f:	0f b6 82 a0 68 10 80 	movzbl -0x7fef9760(%edx),%eax
80102286:	31 c1                	xor    %eax,%ecx
80102288:	89 0d b4 95 10 80    	mov    %ecx,0x801095b4
  c = charcode[shift & (CTL | SHIFT)][data];
8010228e:	89 c8                	mov    %ecx,%eax
80102290:	83 e0 03             	and    $0x3,%eax
80102293:	8b 04 85 80 68 10 80 	mov    -0x7fef9780(,%eax,4),%eax
8010229a:	0f b6 04 10          	movzbl (%eax,%edx,1),%eax
  if(shift & CAPSLOCK){
8010229e:	f6 c1 08             	test   $0x8,%cl
801022a1:	74 19                	je     801022bc <kbdgetc+0x8a>
    if('a' <= c && c <= 'z')
801022a3:	8d 50 9f             	lea    -0x61(%eax),%edx
801022a6:	83 fa 19             	cmp    $0x19,%edx
801022a9:	77 40                	ja     801022eb <kbdgetc+0xb9>
      c += 'A' - 'a';
801022ab:	83 e8 20             	sub    $0x20,%eax
801022ae:	eb 0c                	jmp    801022bc <kbdgetc+0x8a>
    shift |= E0ESC;
801022b0:	83 0d b4 95 10 80 40 	orl    $0x40,0x801095b4
    return 0;
801022b7:	b8 00 00 00 00       	mov    $0x0,%eax
    else if('A' <= c && c <= 'Z')
      c += 'a' - 'A';
  }
  return c;
}
801022bc:	5d                   	pop    %ebp
801022bd:	c3                   	ret    
    data = (shift & E0ESC ? data : data & 0x7F);
801022be:	8b 0d b4 95 10 80    	mov    0x801095b4,%ecx
801022c4:	f6 c1 40             	test   $0x40,%cl
801022c7:	75 05                	jne    801022ce <kbdgetc+0x9c>
801022c9:	89 c2                	mov    %eax,%edx
801022cb:	83 e2 7f             	and    $0x7f,%edx
    shift &= ~(shiftcode[data] | E0ESC);
801022ce:	0f b6 82 a0 69 10 80 	movzbl -0x7fef9660(%edx),%eax
801022d5:	83 c8 40             	or     $0x40,%eax
801022d8:	0f b6 c0             	movzbl %al,%eax
801022db:	f7 d0                	not    %eax
801022dd:	21 c8                	and    %ecx,%eax
801022df:	a3 b4 95 10 80       	mov    %eax,0x801095b4
    return 0;
801022e4:	b8 00 00 00 00       	mov    $0x0,%eax
801022e9:	eb d1                	jmp    801022bc <kbdgetc+0x8a>
    else if('A' <= c && c <= 'Z')
801022eb:	8d 50 bf             	lea    -0x41(%eax),%edx
801022ee:	83 fa 19             	cmp    $0x19,%edx
801022f1:	77 c9                	ja     801022bc <kbdgetc+0x8a>
      c += 'a' - 'A';
801022f3:	83 c0 20             	add    $0x20,%eax
  return c;
801022f6:	eb c4                	jmp    801022bc <kbdgetc+0x8a>
    return -1;
801022f8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801022fd:	eb bd                	jmp    801022bc <kbdgetc+0x8a>

801022ff <kbdintr>:

void
kbdintr(void)
{
801022ff:	55                   	push   %ebp
80102300:	89 e5                	mov    %esp,%ebp
80102302:	83 ec 14             	sub    $0x14,%esp
  consoleintr(kbdgetc);
80102305:	68 32 22 10 80       	push   $0x80102232
8010230a:	e8 2f e4 ff ff       	call   8010073e <consoleintr>
}
8010230f:	83 c4 10             	add    $0x10,%esp
80102312:	c9                   	leave  
80102313:	c3                   	ret    

80102314 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102314:	55                   	push   %ebp
80102315:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102317:	8b 0d 80 16 19 80    	mov    0x80191680,%ecx
8010231d:	8d 04 81             	lea    (%ecx,%eax,4),%eax
80102320:	89 10                	mov    %edx,(%eax)
  lapic[ID];  // wait for write to finish, by reading
80102322:	a1 80 16 19 80       	mov    0x80191680,%eax
80102327:	8b 40 20             	mov    0x20(%eax),%eax
}
8010232a:	5d                   	pop    %ebp
8010232b:	c3                   	ret    

8010232c <cmos_read>:
#define MONTH   0x08
#define YEAR    0x09

static uint
cmos_read(uint reg)
{
8010232c:	55                   	push   %ebp
8010232d:	89 e5                	mov    %esp,%ebp
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010232f:	ba 70 00 00 00       	mov    $0x70,%edx
80102334:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102335:	ba 71 00 00 00       	mov    $0x71,%edx
8010233a:	ec                   	in     (%dx),%al
  outb(CMOS_PORT,  reg);
  microdelay(200);

  return inb(CMOS_RETURN);
8010233b:	0f b6 c0             	movzbl %al,%eax
}
8010233e:	5d                   	pop    %ebp
8010233f:	c3                   	ret    

80102340 <fill_rtcdate>:

static void
fill_rtcdate(struct rtcdate *r)
{
80102340:	55                   	push   %ebp
80102341:	89 e5                	mov    %esp,%ebp
80102343:	53                   	push   %ebx
80102344:	89 c3                	mov    %eax,%ebx
  r->second = cmos_read(SECS);
80102346:	b8 00 00 00 00       	mov    $0x0,%eax
8010234b:	e8 dc ff ff ff       	call   8010232c <cmos_read>
80102350:	89 03                	mov    %eax,(%ebx)
  r->minute = cmos_read(MINS);
80102352:	b8 02 00 00 00       	mov    $0x2,%eax
80102357:	e8 d0 ff ff ff       	call   8010232c <cmos_read>
8010235c:	89 43 04             	mov    %eax,0x4(%ebx)
  r->hour   = cmos_read(HOURS);
8010235f:	b8 04 00 00 00       	mov    $0x4,%eax
80102364:	e8 c3 ff ff ff       	call   8010232c <cmos_read>
80102369:	89 43 08             	mov    %eax,0x8(%ebx)
  r->day    = cmos_read(DAY);
8010236c:	b8 07 00 00 00       	mov    $0x7,%eax
80102371:	e8 b6 ff ff ff       	call   8010232c <cmos_read>
80102376:	89 43 0c             	mov    %eax,0xc(%ebx)
  r->month  = cmos_read(MONTH);
80102379:	b8 08 00 00 00       	mov    $0x8,%eax
8010237e:	e8 a9 ff ff ff       	call   8010232c <cmos_read>
80102383:	89 43 10             	mov    %eax,0x10(%ebx)
  r->year   = cmos_read(YEAR);
80102386:	b8 09 00 00 00       	mov    $0x9,%eax
8010238b:	e8 9c ff ff ff       	call   8010232c <cmos_read>
80102390:	89 43 14             	mov    %eax,0x14(%ebx)
}
80102393:	5b                   	pop    %ebx
80102394:	5d                   	pop    %ebp
80102395:	c3                   	ret    

80102396 <lapicinit>:
  if(!lapic)
80102396:	83 3d 80 16 19 80 00 	cmpl   $0x0,0x80191680
8010239d:	0f 84 fb 00 00 00    	je     8010249e <lapicinit+0x108>
{
801023a3:	55                   	push   %ebp
801023a4:	89 e5                	mov    %esp,%ebp
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
801023a6:	ba 3f 01 00 00       	mov    $0x13f,%edx
801023ab:	b8 3c 00 00 00       	mov    $0x3c,%eax
801023b0:	e8 5f ff ff ff       	call   80102314 <lapicw>
  lapicw(TDCR, X1);
801023b5:	ba 0b 00 00 00       	mov    $0xb,%edx
801023ba:	b8 f8 00 00 00       	mov    $0xf8,%eax
801023bf:	e8 50 ff ff ff       	call   80102314 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
801023c4:	ba 20 00 02 00       	mov    $0x20020,%edx
801023c9:	b8 c8 00 00 00       	mov    $0xc8,%eax
801023ce:	e8 41 ff ff ff       	call   80102314 <lapicw>
  lapicw(TICR, 10000000);
801023d3:	ba 80 96 98 00       	mov    $0x989680,%edx
801023d8:	b8 e0 00 00 00       	mov    $0xe0,%eax
801023dd:	e8 32 ff ff ff       	call   80102314 <lapicw>
  lapicw(LINT0, MASKED);
801023e2:	ba 00 00 01 00       	mov    $0x10000,%edx
801023e7:	b8 d4 00 00 00       	mov    $0xd4,%eax
801023ec:	e8 23 ff ff ff       	call   80102314 <lapicw>
  lapicw(LINT1, MASKED);
801023f1:	ba 00 00 01 00       	mov    $0x10000,%edx
801023f6:	b8 d8 00 00 00       	mov    $0xd8,%eax
801023fb:	e8 14 ff ff ff       	call   80102314 <lapicw>
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80102400:	a1 80 16 19 80       	mov    0x80191680,%eax
80102405:	8b 40 30             	mov    0x30(%eax),%eax
80102408:	c1 e8 10             	shr    $0x10,%eax
8010240b:	3c 03                	cmp    $0x3,%al
8010240d:	77 7b                	ja     8010248a <lapicinit+0xf4>
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
8010240f:	ba 33 00 00 00       	mov    $0x33,%edx
80102414:	b8 dc 00 00 00       	mov    $0xdc,%eax
80102419:	e8 f6 fe ff ff       	call   80102314 <lapicw>
  lapicw(ESR, 0);
8010241e:	ba 00 00 00 00       	mov    $0x0,%edx
80102423:	b8 a0 00 00 00       	mov    $0xa0,%eax
80102428:	e8 e7 fe ff ff       	call   80102314 <lapicw>
  lapicw(ESR, 0);
8010242d:	ba 00 00 00 00       	mov    $0x0,%edx
80102432:	b8 a0 00 00 00       	mov    $0xa0,%eax
80102437:	e8 d8 fe ff ff       	call   80102314 <lapicw>
  lapicw(EOI, 0);
8010243c:	ba 00 00 00 00       	mov    $0x0,%edx
80102441:	b8 2c 00 00 00       	mov    $0x2c,%eax
80102446:	e8 c9 fe ff ff       	call   80102314 <lapicw>
  lapicw(ICRHI, 0);
8010244b:	ba 00 00 00 00       	mov    $0x0,%edx
80102450:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102455:	e8 ba fe ff ff       	call   80102314 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
8010245a:	ba 00 85 08 00       	mov    $0x88500,%edx
8010245f:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102464:	e8 ab fe ff ff       	call   80102314 <lapicw>
  while(lapic[ICRLO] & DELIVS)
80102469:	a1 80 16 19 80       	mov    0x80191680,%eax
8010246e:	8b 80 00 03 00 00    	mov    0x300(%eax),%eax
80102474:	f6 c4 10             	test   $0x10,%ah
80102477:	75 f0                	jne    80102469 <lapicinit+0xd3>
  lapicw(TPR, 0);
80102479:	ba 00 00 00 00       	mov    $0x0,%edx
8010247e:	b8 20 00 00 00       	mov    $0x20,%eax
80102483:	e8 8c fe ff ff       	call   80102314 <lapicw>
}
80102488:	5d                   	pop    %ebp
80102489:	c3                   	ret    
    lapicw(PCINT, MASKED);
8010248a:	ba 00 00 01 00       	mov    $0x10000,%edx
8010248f:	b8 d0 00 00 00       	mov    $0xd0,%eax
80102494:	e8 7b fe ff ff       	call   80102314 <lapicw>
80102499:	e9 71 ff ff ff       	jmp    8010240f <lapicinit+0x79>
8010249e:	f3 c3                	repz ret 

801024a0 <lapicid>:
{
801024a0:	55                   	push   %ebp
801024a1:	89 e5                	mov    %esp,%ebp
  if (!lapic)
801024a3:	a1 80 16 19 80       	mov    0x80191680,%eax
801024a8:	85 c0                	test   %eax,%eax
801024aa:	74 08                	je     801024b4 <lapicid+0x14>
  return lapic[ID] >> 24;
801024ac:	8b 40 20             	mov    0x20(%eax),%eax
801024af:	c1 e8 18             	shr    $0x18,%eax
}
801024b2:	5d                   	pop    %ebp
801024b3:	c3                   	ret    
    return 0;
801024b4:	b8 00 00 00 00       	mov    $0x0,%eax
801024b9:	eb f7                	jmp    801024b2 <lapicid+0x12>

801024bb <lapiceoi>:
  if(lapic)
801024bb:	83 3d 80 16 19 80 00 	cmpl   $0x0,0x80191680
801024c2:	74 14                	je     801024d8 <lapiceoi+0x1d>
{
801024c4:	55                   	push   %ebp
801024c5:	89 e5                	mov    %esp,%ebp
    lapicw(EOI, 0);
801024c7:	ba 00 00 00 00       	mov    $0x0,%edx
801024cc:	b8 2c 00 00 00       	mov    $0x2c,%eax
801024d1:	e8 3e fe ff ff       	call   80102314 <lapicw>
}
801024d6:	5d                   	pop    %ebp
801024d7:	c3                   	ret    
801024d8:	f3 c3                	repz ret 

801024da <microdelay>:
{
801024da:	55                   	push   %ebp
801024db:	89 e5                	mov    %esp,%ebp
}
801024dd:	5d                   	pop    %ebp
801024de:	c3                   	ret    

801024df <lapicstartap>:
{
801024df:	55                   	push   %ebp
801024e0:	89 e5                	mov    %esp,%ebp
801024e2:	57                   	push   %edi
801024e3:	56                   	push   %esi
801024e4:	53                   	push   %ebx
801024e5:	8b 75 08             	mov    0x8(%ebp),%esi
801024e8:	8b 7d 0c             	mov    0xc(%ebp),%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801024eb:	b8 0f 00 00 00       	mov    $0xf,%eax
801024f0:	ba 70 00 00 00       	mov    $0x70,%edx
801024f5:	ee                   	out    %al,(%dx)
801024f6:	b8 0a 00 00 00       	mov    $0xa,%eax
801024fb:	ba 71 00 00 00       	mov    $0x71,%edx
80102500:	ee                   	out    %al,(%dx)
  wrv[0] = 0;
80102501:	66 c7 05 67 04 00 80 	movw   $0x0,0x80000467
80102508:	00 00 
  wrv[1] = addr >> 4;
8010250a:	89 f8                	mov    %edi,%eax
8010250c:	c1 e8 04             	shr    $0x4,%eax
8010250f:	66 a3 69 04 00 80    	mov    %ax,0x80000469
  lapicw(ICRHI, apicid<<24);
80102515:	c1 e6 18             	shl    $0x18,%esi
80102518:	89 f2                	mov    %esi,%edx
8010251a:	b8 c4 00 00 00       	mov    $0xc4,%eax
8010251f:	e8 f0 fd ff ff       	call   80102314 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80102524:	ba 00 c5 00 00       	mov    $0xc500,%edx
80102529:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010252e:	e8 e1 fd ff ff       	call   80102314 <lapicw>
  lapicw(ICRLO, INIT | LEVEL);
80102533:	ba 00 85 00 00       	mov    $0x8500,%edx
80102538:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010253d:	e8 d2 fd ff ff       	call   80102314 <lapicw>
  for(i = 0; i < 2; i++){
80102542:	bb 00 00 00 00       	mov    $0x0,%ebx
80102547:	eb 21                	jmp    8010256a <lapicstartap+0x8b>
    lapicw(ICRHI, apicid<<24);
80102549:	89 f2                	mov    %esi,%edx
8010254b:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102550:	e8 bf fd ff ff       	call   80102314 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80102555:	89 fa                	mov    %edi,%edx
80102557:	c1 ea 0c             	shr    $0xc,%edx
8010255a:	80 ce 06             	or     $0x6,%dh
8010255d:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102562:	e8 ad fd ff ff       	call   80102314 <lapicw>
  for(i = 0; i < 2; i++){
80102567:	83 c3 01             	add    $0x1,%ebx
8010256a:	83 fb 01             	cmp    $0x1,%ebx
8010256d:	7e da                	jle    80102549 <lapicstartap+0x6a>
}
8010256f:	5b                   	pop    %ebx
80102570:	5e                   	pop    %esi
80102571:	5f                   	pop    %edi
80102572:	5d                   	pop    %ebp
80102573:	c3                   	ret    

80102574 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void
cmostime(struct rtcdate *r)
{
80102574:	55                   	push   %ebp
80102575:	89 e5                	mov    %esp,%ebp
80102577:	57                   	push   %edi
80102578:	56                   	push   %esi
80102579:	53                   	push   %ebx
8010257a:	83 ec 3c             	sub    $0x3c,%esp
8010257d:	8b 75 08             	mov    0x8(%ebp),%esi
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
80102580:	b8 0b 00 00 00       	mov    $0xb,%eax
80102585:	e8 a2 fd ff ff       	call   8010232c <cmos_read>

  bcd = (sb & (1 << 2)) == 0;
8010258a:	83 e0 04             	and    $0x4,%eax
8010258d:	89 c7                	mov    %eax,%edi

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
8010258f:	8d 45 d0             	lea    -0x30(%ebp),%eax
80102592:	e8 a9 fd ff ff       	call   80102340 <fill_rtcdate>
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
80102597:	b8 0a 00 00 00       	mov    $0xa,%eax
8010259c:	e8 8b fd ff ff       	call   8010232c <cmos_read>
801025a1:	a8 80                	test   $0x80,%al
801025a3:	75 ea                	jne    8010258f <cmostime+0x1b>
        continue;
    fill_rtcdate(&t2);
801025a5:	8d 5d b8             	lea    -0x48(%ebp),%ebx
801025a8:	89 d8                	mov    %ebx,%eax
801025aa:	e8 91 fd ff ff       	call   80102340 <fill_rtcdate>
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
801025af:	83 ec 04             	sub    $0x4,%esp
801025b2:	6a 18                	push   $0x18
801025b4:	53                   	push   %ebx
801025b5:	8d 45 d0             	lea    -0x30(%ebp),%eax
801025b8:	50                   	push   %eax
801025b9:	e8 01 18 00 00       	call   80103dbf <memcmp>
801025be:	83 c4 10             	add    $0x10,%esp
801025c1:	85 c0                	test   %eax,%eax
801025c3:	75 ca                	jne    8010258f <cmostime+0x1b>
      break;
  }

  // convert
  if(bcd) {
801025c5:	85 ff                	test   %edi,%edi
801025c7:	0f 85 84 00 00 00    	jne    80102651 <cmostime+0xdd>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
801025cd:	8b 55 d0             	mov    -0x30(%ebp),%edx
801025d0:	89 d0                	mov    %edx,%eax
801025d2:	c1 e8 04             	shr    $0x4,%eax
801025d5:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801025d8:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801025db:	83 e2 0f             	and    $0xf,%edx
801025de:	01 d0                	add    %edx,%eax
801025e0:	89 45 d0             	mov    %eax,-0x30(%ebp)
    CONV(minute);
801025e3:	8b 55 d4             	mov    -0x2c(%ebp),%edx
801025e6:	89 d0                	mov    %edx,%eax
801025e8:	c1 e8 04             	shr    $0x4,%eax
801025eb:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801025ee:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801025f1:	83 e2 0f             	and    $0xf,%edx
801025f4:	01 d0                	add    %edx,%eax
801025f6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    CONV(hour  );
801025f9:	8b 55 d8             	mov    -0x28(%ebp),%edx
801025fc:	89 d0                	mov    %edx,%eax
801025fe:	c1 e8 04             	shr    $0x4,%eax
80102601:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102604:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102607:	83 e2 0f             	and    $0xf,%edx
8010260a:	01 d0                	add    %edx,%eax
8010260c:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(day   );
8010260f:	8b 55 dc             	mov    -0x24(%ebp),%edx
80102612:	89 d0                	mov    %edx,%eax
80102614:	c1 e8 04             	shr    $0x4,%eax
80102617:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010261a:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
8010261d:	83 e2 0f             	and    $0xf,%edx
80102620:	01 d0                	add    %edx,%eax
80102622:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(month );
80102625:	8b 55 e0             	mov    -0x20(%ebp),%edx
80102628:	89 d0                	mov    %edx,%eax
8010262a:	c1 e8 04             	shr    $0x4,%eax
8010262d:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102630:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102633:	83 e2 0f             	and    $0xf,%edx
80102636:	01 d0                	add    %edx,%eax
80102638:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(year  );
8010263b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010263e:	89 d0                	mov    %edx,%eax
80102640:	c1 e8 04             	shr    $0x4,%eax
80102643:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102646:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102649:	83 e2 0f             	and    $0xf,%edx
8010264c:	01 d0                	add    %edx,%eax
8010264e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
#undef     CONV
  }

  *r = t1;
80102651:	8b 45 d0             	mov    -0x30(%ebp),%eax
80102654:	89 06                	mov    %eax,(%esi)
80102656:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80102659:	89 46 04             	mov    %eax,0x4(%esi)
8010265c:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010265f:	89 46 08             	mov    %eax,0x8(%esi)
80102662:	8b 45 dc             	mov    -0x24(%ebp),%eax
80102665:	89 46 0c             	mov    %eax,0xc(%esi)
80102668:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010266b:	89 46 10             	mov    %eax,0x10(%esi)
8010266e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102671:	89 46 14             	mov    %eax,0x14(%esi)
  r->year += 2000;
80102674:	81 46 14 d0 07 00 00 	addl   $0x7d0,0x14(%esi)
}
8010267b:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010267e:	5b                   	pop    %ebx
8010267f:	5e                   	pop    %esi
80102680:	5f                   	pop    %edi
80102681:	5d                   	pop    %ebp
80102682:	c3                   	ret    

80102683 <read_head>:
}

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80102683:	55                   	push   %ebp
80102684:	89 e5                	mov    %esp,%ebp
80102686:	53                   	push   %ebx
80102687:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
8010268a:	ff 35 d4 16 19 80    	pushl  0x801916d4
80102690:	ff 35 e4 16 19 80    	pushl  0x801916e4
80102696:	e8 d1 da ff ff       	call   8010016c <bread>
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
8010269b:	8b 58 5c             	mov    0x5c(%eax),%ebx
8010269e:	89 1d e8 16 19 80    	mov    %ebx,0x801916e8
  for (i = 0; i < log.lh.n; i++) {
801026a4:	83 c4 10             	add    $0x10,%esp
801026a7:	ba 00 00 00 00       	mov    $0x0,%edx
801026ac:	eb 0e                	jmp    801026bc <read_head+0x39>
    log.lh.block[i] = lh->block[i];
801026ae:	8b 4c 90 60          	mov    0x60(%eax,%edx,4),%ecx
801026b2:	89 0c 95 ec 16 19 80 	mov    %ecx,-0x7fe6e914(,%edx,4)
  for (i = 0; i < log.lh.n; i++) {
801026b9:	83 c2 01             	add    $0x1,%edx
801026bc:	39 d3                	cmp    %edx,%ebx
801026be:	7f ee                	jg     801026ae <read_head+0x2b>
  }
  brelse(buf);
801026c0:	83 ec 0c             	sub    $0xc,%esp
801026c3:	50                   	push   %eax
801026c4:	e8 0c db ff ff       	call   801001d5 <brelse>
}
801026c9:	83 c4 10             	add    $0x10,%esp
801026cc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801026cf:	c9                   	leave  
801026d0:	c3                   	ret    

801026d1 <install_trans>:
{
801026d1:	55                   	push   %ebp
801026d2:	89 e5                	mov    %esp,%ebp
801026d4:	57                   	push   %edi
801026d5:	56                   	push   %esi
801026d6:	53                   	push   %ebx
801026d7:	83 ec 0c             	sub    $0xc,%esp
  for (tail = 0; tail < log.lh.n; tail++) {
801026da:	bb 00 00 00 00       	mov    $0x0,%ebx
801026df:	eb 66                	jmp    80102747 <install_trans+0x76>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801026e1:	89 d8                	mov    %ebx,%eax
801026e3:	03 05 d4 16 19 80    	add    0x801916d4,%eax
801026e9:	83 c0 01             	add    $0x1,%eax
801026ec:	83 ec 08             	sub    $0x8,%esp
801026ef:	50                   	push   %eax
801026f0:	ff 35 e4 16 19 80    	pushl  0x801916e4
801026f6:	e8 71 da ff ff       	call   8010016c <bread>
801026fb:	89 c7                	mov    %eax,%edi
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
801026fd:	83 c4 08             	add    $0x8,%esp
80102700:	ff 34 9d ec 16 19 80 	pushl  -0x7fe6e914(,%ebx,4)
80102707:	ff 35 e4 16 19 80    	pushl  0x801916e4
8010270d:	e8 5a da ff ff       	call   8010016c <bread>
80102712:	89 c6                	mov    %eax,%esi
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80102714:	8d 57 5c             	lea    0x5c(%edi),%edx
80102717:	8d 40 5c             	lea    0x5c(%eax),%eax
8010271a:	83 c4 0c             	add    $0xc,%esp
8010271d:	68 00 02 00 00       	push   $0x200
80102722:	52                   	push   %edx
80102723:	50                   	push   %eax
80102724:	e8 cb 16 00 00       	call   80103df4 <memmove>
    bwrite(dbuf);  // write dst to disk
80102729:	89 34 24             	mov    %esi,(%esp)
8010272c:	e8 69 da ff ff       	call   8010019a <bwrite>
    brelse(lbuf);
80102731:	89 3c 24             	mov    %edi,(%esp)
80102734:	e8 9c da ff ff       	call   801001d5 <brelse>
    brelse(dbuf);
80102739:	89 34 24             	mov    %esi,(%esp)
8010273c:	e8 94 da ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
80102741:	83 c3 01             	add    $0x1,%ebx
80102744:	83 c4 10             	add    $0x10,%esp
80102747:	39 1d e8 16 19 80    	cmp    %ebx,0x801916e8
8010274d:	7f 92                	jg     801026e1 <install_trans+0x10>
}
8010274f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102752:	5b                   	pop    %ebx
80102753:	5e                   	pop    %esi
80102754:	5f                   	pop    %edi
80102755:	5d                   	pop    %ebp
80102756:	c3                   	ret    

80102757 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80102757:	55                   	push   %ebp
80102758:	89 e5                	mov    %esp,%ebp
8010275a:	53                   	push   %ebx
8010275b:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
8010275e:	ff 35 d4 16 19 80    	pushl  0x801916d4
80102764:	ff 35 e4 16 19 80    	pushl  0x801916e4
8010276a:	e8 fd d9 ff ff       	call   8010016c <bread>
8010276f:	89 c3                	mov    %eax,%ebx
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
80102771:	8b 0d e8 16 19 80    	mov    0x801916e8,%ecx
80102777:	89 48 5c             	mov    %ecx,0x5c(%eax)
  for (i = 0; i < log.lh.n; i++) {
8010277a:	83 c4 10             	add    $0x10,%esp
8010277d:	b8 00 00 00 00       	mov    $0x0,%eax
80102782:	eb 0e                	jmp    80102792 <write_head+0x3b>
    hb->block[i] = log.lh.block[i];
80102784:	8b 14 85 ec 16 19 80 	mov    -0x7fe6e914(,%eax,4),%edx
8010278b:	89 54 83 60          	mov    %edx,0x60(%ebx,%eax,4)
  for (i = 0; i < log.lh.n; i++) {
8010278f:	83 c0 01             	add    $0x1,%eax
80102792:	39 c1                	cmp    %eax,%ecx
80102794:	7f ee                	jg     80102784 <write_head+0x2d>
  }
  bwrite(buf);
80102796:	83 ec 0c             	sub    $0xc,%esp
80102799:	53                   	push   %ebx
8010279a:	e8 fb d9 ff ff       	call   8010019a <bwrite>
  brelse(buf);
8010279f:	89 1c 24             	mov    %ebx,(%esp)
801027a2:	e8 2e da ff ff       	call   801001d5 <brelse>
}
801027a7:	83 c4 10             	add    $0x10,%esp
801027aa:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801027ad:	c9                   	leave  
801027ae:	c3                   	ret    

801027af <recover_from_log>:

static void
recover_from_log(void)
{
801027af:	55                   	push   %ebp
801027b0:	89 e5                	mov    %esp,%ebp
801027b2:	83 ec 08             	sub    $0x8,%esp
  read_head();
801027b5:	e8 c9 fe ff ff       	call   80102683 <read_head>
  install_trans(); // if committed, copy from log to disk
801027ba:	e8 12 ff ff ff       	call   801026d1 <install_trans>
  log.lh.n = 0;
801027bf:	c7 05 e8 16 19 80 00 	movl   $0x0,0x801916e8
801027c6:	00 00 00 
  write_head(); // clear the log
801027c9:	e8 89 ff ff ff       	call   80102757 <write_head>
}
801027ce:	c9                   	leave  
801027cf:	c3                   	ret    

801027d0 <write_log>:
}

// Copy modified blocks from cache to log.
static void
write_log(void)
{
801027d0:	55                   	push   %ebp
801027d1:	89 e5                	mov    %esp,%ebp
801027d3:	57                   	push   %edi
801027d4:	56                   	push   %esi
801027d5:	53                   	push   %ebx
801027d6:	83 ec 0c             	sub    $0xc,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801027d9:	bb 00 00 00 00       	mov    $0x0,%ebx
801027de:	eb 66                	jmp    80102846 <write_log+0x76>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
801027e0:	89 d8                	mov    %ebx,%eax
801027e2:	03 05 d4 16 19 80    	add    0x801916d4,%eax
801027e8:	83 c0 01             	add    $0x1,%eax
801027eb:	83 ec 08             	sub    $0x8,%esp
801027ee:	50                   	push   %eax
801027ef:	ff 35 e4 16 19 80    	pushl  0x801916e4
801027f5:	e8 72 d9 ff ff       	call   8010016c <bread>
801027fa:	89 c6                	mov    %eax,%esi
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
801027fc:	83 c4 08             	add    $0x8,%esp
801027ff:	ff 34 9d ec 16 19 80 	pushl  -0x7fe6e914(,%ebx,4)
80102806:	ff 35 e4 16 19 80    	pushl  0x801916e4
8010280c:	e8 5b d9 ff ff       	call   8010016c <bread>
80102811:	89 c7                	mov    %eax,%edi
    memmove(to->data, from->data, BSIZE);
80102813:	8d 50 5c             	lea    0x5c(%eax),%edx
80102816:	8d 46 5c             	lea    0x5c(%esi),%eax
80102819:	83 c4 0c             	add    $0xc,%esp
8010281c:	68 00 02 00 00       	push   $0x200
80102821:	52                   	push   %edx
80102822:	50                   	push   %eax
80102823:	e8 cc 15 00 00       	call   80103df4 <memmove>
    bwrite(to);  // write the log
80102828:	89 34 24             	mov    %esi,(%esp)
8010282b:	e8 6a d9 ff ff       	call   8010019a <bwrite>
    brelse(from);
80102830:	89 3c 24             	mov    %edi,(%esp)
80102833:	e8 9d d9 ff ff       	call   801001d5 <brelse>
    brelse(to);
80102838:	89 34 24             	mov    %esi,(%esp)
8010283b:	e8 95 d9 ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
80102840:	83 c3 01             	add    $0x1,%ebx
80102843:	83 c4 10             	add    $0x10,%esp
80102846:	39 1d e8 16 19 80    	cmp    %ebx,0x801916e8
8010284c:	7f 92                	jg     801027e0 <write_log+0x10>
  }
}
8010284e:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102851:	5b                   	pop    %ebx
80102852:	5e                   	pop    %esi
80102853:	5f                   	pop    %edi
80102854:	5d                   	pop    %ebp
80102855:	c3                   	ret    

80102856 <commit>:

static void
commit()
{
  if (log.lh.n > 0) {
80102856:	83 3d e8 16 19 80 00 	cmpl   $0x0,0x801916e8
8010285d:	7e 26                	jle    80102885 <commit+0x2f>
{
8010285f:	55                   	push   %ebp
80102860:	89 e5                	mov    %esp,%ebp
80102862:	83 ec 08             	sub    $0x8,%esp
    write_log();     // Write modified blocks from cache to log
80102865:	e8 66 ff ff ff       	call   801027d0 <write_log>
    write_head();    // Write header to disk -- the real commit
8010286a:	e8 e8 fe ff ff       	call   80102757 <write_head>
    install_trans(); // Now install writes to home locations
8010286f:	e8 5d fe ff ff       	call   801026d1 <install_trans>
    log.lh.n = 0;
80102874:	c7 05 e8 16 19 80 00 	movl   $0x0,0x801916e8
8010287b:	00 00 00 
    write_head();    // Erase the transaction from the log
8010287e:	e8 d4 fe ff ff       	call   80102757 <write_head>
  }
}
80102883:	c9                   	leave  
80102884:	c3                   	ret    
80102885:	f3 c3                	repz ret 

80102887 <initlog>:
{
80102887:	55                   	push   %ebp
80102888:	89 e5                	mov    %esp,%ebp
8010288a:	53                   	push   %ebx
8010288b:	83 ec 2c             	sub    $0x2c,%esp
8010288e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&log.lock, "log");
80102891:	68 a0 6a 10 80       	push   $0x80106aa0
80102896:	68 a0 16 19 80       	push   $0x801916a0
8010289b:	e8 f1 12 00 00       	call   80103b91 <initlock>
  readsb(dev, &sb);
801028a0:	83 c4 08             	add    $0x8,%esp
801028a3:	8d 45 dc             	lea    -0x24(%ebp),%eax
801028a6:	50                   	push   %eax
801028a7:	53                   	push   %ebx
801028a8:	e8 95 e9 ff ff       	call   80101242 <readsb>
  log.start = sb.logstart;
801028ad:	8b 45 ec             	mov    -0x14(%ebp),%eax
801028b0:	a3 d4 16 19 80       	mov    %eax,0x801916d4
  log.size = sb.nlog;
801028b5:	8b 45 e8             	mov    -0x18(%ebp),%eax
801028b8:	a3 d8 16 19 80       	mov    %eax,0x801916d8
  log.dev = dev;
801028bd:	89 1d e4 16 19 80    	mov    %ebx,0x801916e4
  recover_from_log();
801028c3:	e8 e7 fe ff ff       	call   801027af <recover_from_log>
}
801028c8:	83 c4 10             	add    $0x10,%esp
801028cb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801028ce:	c9                   	leave  
801028cf:	c3                   	ret    

801028d0 <begin_op>:
{
801028d0:	55                   	push   %ebp
801028d1:	89 e5                	mov    %esp,%ebp
801028d3:	83 ec 14             	sub    $0x14,%esp
  acquire(&log.lock);
801028d6:	68 a0 16 19 80       	push   $0x801916a0
801028db:	e8 ed 13 00 00       	call   80103ccd <acquire>
801028e0:	83 c4 10             	add    $0x10,%esp
801028e3:	eb 15                	jmp    801028fa <begin_op+0x2a>
      sleep(&log, &log.lock);
801028e5:	83 ec 08             	sub    $0x8,%esp
801028e8:	68 a0 16 19 80       	push   $0x801916a0
801028ed:	68 a0 16 19 80       	push   $0x801916a0
801028f2:	e8 db 0e 00 00       	call   801037d2 <sleep>
801028f7:	83 c4 10             	add    $0x10,%esp
    if(log.committing){
801028fa:	83 3d e0 16 19 80 00 	cmpl   $0x0,0x801916e0
80102901:	75 e2                	jne    801028e5 <begin_op+0x15>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
80102903:	a1 dc 16 19 80       	mov    0x801916dc,%eax
80102908:	83 c0 01             	add    $0x1,%eax
8010290b:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010290e:	8d 14 09             	lea    (%ecx,%ecx,1),%edx
80102911:	03 15 e8 16 19 80    	add    0x801916e8,%edx
80102917:	83 fa 1e             	cmp    $0x1e,%edx
8010291a:	7e 17                	jle    80102933 <begin_op+0x63>
      sleep(&log, &log.lock);
8010291c:	83 ec 08             	sub    $0x8,%esp
8010291f:	68 a0 16 19 80       	push   $0x801916a0
80102924:	68 a0 16 19 80       	push   $0x801916a0
80102929:	e8 a4 0e 00 00       	call   801037d2 <sleep>
8010292e:	83 c4 10             	add    $0x10,%esp
80102931:	eb c7                	jmp    801028fa <begin_op+0x2a>
      log.outstanding += 1;
80102933:	a3 dc 16 19 80       	mov    %eax,0x801916dc
      release(&log.lock);
80102938:	83 ec 0c             	sub    $0xc,%esp
8010293b:	68 a0 16 19 80       	push   $0x801916a0
80102940:	e8 ed 13 00 00       	call   80103d32 <release>
}
80102945:	83 c4 10             	add    $0x10,%esp
80102948:	c9                   	leave  
80102949:	c3                   	ret    

8010294a <end_op>:
{
8010294a:	55                   	push   %ebp
8010294b:	89 e5                	mov    %esp,%ebp
8010294d:	53                   	push   %ebx
8010294e:	83 ec 10             	sub    $0x10,%esp
  acquire(&log.lock);
80102951:	68 a0 16 19 80       	push   $0x801916a0
80102956:	e8 72 13 00 00       	call   80103ccd <acquire>
  log.outstanding -= 1;
8010295b:	a1 dc 16 19 80       	mov    0x801916dc,%eax
80102960:	83 e8 01             	sub    $0x1,%eax
80102963:	a3 dc 16 19 80       	mov    %eax,0x801916dc
  if(log.committing)
80102968:	8b 1d e0 16 19 80    	mov    0x801916e0,%ebx
8010296e:	83 c4 10             	add    $0x10,%esp
80102971:	85 db                	test   %ebx,%ebx
80102973:	75 2c                	jne    801029a1 <end_op+0x57>
  if(log.outstanding == 0){
80102975:	85 c0                	test   %eax,%eax
80102977:	75 35                	jne    801029ae <end_op+0x64>
    log.committing = 1;
80102979:	c7 05 e0 16 19 80 01 	movl   $0x1,0x801916e0
80102980:	00 00 00 
    do_commit = 1;
80102983:	bb 01 00 00 00       	mov    $0x1,%ebx
  release(&log.lock);
80102988:	83 ec 0c             	sub    $0xc,%esp
8010298b:	68 a0 16 19 80       	push   $0x801916a0
80102990:	e8 9d 13 00 00       	call   80103d32 <release>
  if(do_commit){
80102995:	83 c4 10             	add    $0x10,%esp
80102998:	85 db                	test   %ebx,%ebx
8010299a:	75 24                	jne    801029c0 <end_op+0x76>
}
8010299c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010299f:	c9                   	leave  
801029a0:	c3                   	ret    
    panic("log.committing");
801029a1:	83 ec 0c             	sub    $0xc,%esp
801029a4:	68 a4 6a 10 80       	push   $0x80106aa4
801029a9:	e8 9a d9 ff ff       	call   80100348 <panic>
    wakeup(&log);
801029ae:	83 ec 0c             	sub    $0xc,%esp
801029b1:	68 a0 16 19 80       	push   $0x801916a0
801029b6:	e8 7c 0f 00 00       	call   80103937 <wakeup>
801029bb:	83 c4 10             	add    $0x10,%esp
801029be:	eb c8                	jmp    80102988 <end_op+0x3e>
    commit();
801029c0:	e8 91 fe ff ff       	call   80102856 <commit>
    acquire(&log.lock);
801029c5:	83 ec 0c             	sub    $0xc,%esp
801029c8:	68 a0 16 19 80       	push   $0x801916a0
801029cd:	e8 fb 12 00 00       	call   80103ccd <acquire>
    log.committing = 0;
801029d2:	c7 05 e0 16 19 80 00 	movl   $0x0,0x801916e0
801029d9:	00 00 00 
    wakeup(&log);
801029dc:	c7 04 24 a0 16 19 80 	movl   $0x801916a0,(%esp)
801029e3:	e8 4f 0f 00 00       	call   80103937 <wakeup>
    release(&log.lock);
801029e8:	c7 04 24 a0 16 19 80 	movl   $0x801916a0,(%esp)
801029ef:	e8 3e 13 00 00       	call   80103d32 <release>
801029f4:	83 c4 10             	add    $0x10,%esp
}
801029f7:	eb a3                	jmp    8010299c <end_op+0x52>

801029f9 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
801029f9:	55                   	push   %ebp
801029fa:	89 e5                	mov    %esp,%ebp
801029fc:	53                   	push   %ebx
801029fd:	83 ec 04             	sub    $0x4,%esp
80102a00:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80102a03:	8b 15 e8 16 19 80    	mov    0x801916e8,%edx
80102a09:	83 fa 1d             	cmp    $0x1d,%edx
80102a0c:	7f 45                	jg     80102a53 <log_write+0x5a>
80102a0e:	a1 d8 16 19 80       	mov    0x801916d8,%eax
80102a13:	83 e8 01             	sub    $0x1,%eax
80102a16:	39 c2                	cmp    %eax,%edx
80102a18:	7d 39                	jge    80102a53 <log_write+0x5a>
    panic("too big a transaction");
  if (log.outstanding < 1)
80102a1a:	83 3d dc 16 19 80 00 	cmpl   $0x0,0x801916dc
80102a21:	7e 3d                	jle    80102a60 <log_write+0x67>
    panic("log_write outside of trans");

  acquire(&log.lock);
80102a23:	83 ec 0c             	sub    $0xc,%esp
80102a26:	68 a0 16 19 80       	push   $0x801916a0
80102a2b:	e8 9d 12 00 00       	call   80103ccd <acquire>
  for (i = 0; i < log.lh.n; i++) {
80102a30:	83 c4 10             	add    $0x10,%esp
80102a33:	b8 00 00 00 00       	mov    $0x0,%eax
80102a38:	8b 15 e8 16 19 80    	mov    0x801916e8,%edx
80102a3e:	39 c2                	cmp    %eax,%edx
80102a40:	7e 2b                	jle    80102a6d <log_write+0x74>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
80102a42:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102a45:	39 0c 85 ec 16 19 80 	cmp    %ecx,-0x7fe6e914(,%eax,4)
80102a4c:	74 1f                	je     80102a6d <log_write+0x74>
  for (i = 0; i < log.lh.n; i++) {
80102a4e:	83 c0 01             	add    $0x1,%eax
80102a51:	eb e5                	jmp    80102a38 <log_write+0x3f>
    panic("too big a transaction");
80102a53:	83 ec 0c             	sub    $0xc,%esp
80102a56:	68 b3 6a 10 80       	push   $0x80106ab3
80102a5b:	e8 e8 d8 ff ff       	call   80100348 <panic>
    panic("log_write outside of trans");
80102a60:	83 ec 0c             	sub    $0xc,%esp
80102a63:	68 c9 6a 10 80       	push   $0x80106ac9
80102a68:	e8 db d8 ff ff       	call   80100348 <panic>
      break;
  }
  log.lh.block[i] = b->blockno;
80102a6d:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102a70:	89 0c 85 ec 16 19 80 	mov    %ecx,-0x7fe6e914(,%eax,4)
  if (i == log.lh.n)
80102a77:	39 c2                	cmp    %eax,%edx
80102a79:	74 18                	je     80102a93 <log_write+0x9a>
    log.lh.n++;
  b->flags |= B_DIRTY; // prevent eviction
80102a7b:	83 0b 04             	orl    $0x4,(%ebx)
  release(&log.lock);
80102a7e:	83 ec 0c             	sub    $0xc,%esp
80102a81:	68 a0 16 19 80       	push   $0x801916a0
80102a86:	e8 a7 12 00 00       	call   80103d32 <release>
}
80102a8b:	83 c4 10             	add    $0x10,%esp
80102a8e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102a91:	c9                   	leave  
80102a92:	c3                   	ret    
    log.lh.n++;
80102a93:	83 c2 01             	add    $0x1,%edx
80102a96:	89 15 e8 16 19 80    	mov    %edx,0x801916e8
80102a9c:	eb dd                	jmp    80102a7b <log_write+0x82>

80102a9e <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80102a9e:	55                   	push   %ebp
80102a9f:	89 e5                	mov    %esp,%ebp
80102aa1:	53                   	push   %ebx
80102aa2:	83 ec 08             	sub    $0x8,%esp

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80102aa5:	68 8a 00 00 00       	push   $0x8a
80102aaa:	68 8c 94 10 80       	push   $0x8010948c
80102aaf:	68 00 70 00 80       	push   $0x80007000
80102ab4:	e8 3b 13 00 00       	call   80103df4 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80102ab9:	83 c4 10             	add    $0x10,%esp
80102abc:	bb a0 17 19 80       	mov    $0x801917a0,%ebx
80102ac1:	eb 06                	jmp    80102ac9 <startothers+0x2b>
80102ac3:	81 c3 b0 00 00 00    	add    $0xb0,%ebx
80102ac9:	69 05 20 1d 19 80 b0 	imul   $0xb0,0x80191d20,%eax
80102ad0:	00 00 00 
80102ad3:	05 a0 17 19 80       	add    $0x801917a0,%eax
80102ad8:	39 d8                	cmp    %ebx,%eax
80102ada:	76 51                	jbe    80102b2d <startothers+0x8f>
    if(c == mycpu())  // We've started already.
80102adc:	e8 d3 07 00 00       	call   801032b4 <mycpu>
80102ae1:	39 d8                	cmp    %ebx,%eax
80102ae3:	74 de                	je     80102ac3 <startothers+0x25>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc(-2);
80102ae5:	83 ec 0c             	sub    $0xc,%esp
80102ae8:	6a fe                	push   $0xfffffffe
80102aea:	e8 09 f6 ff ff       	call   801020f8 <kalloc>
    *(void**)(code-4) = stack + KSTACKSIZE;
80102aef:	05 00 10 00 00       	add    $0x1000,%eax
80102af4:	a3 fc 6f 00 80       	mov    %eax,0x80006ffc
    *(void(**)(void))(code-8) = mpenter;
80102af9:	c7 05 f8 6f 00 80 71 	movl   $0x80102b71,0x80006ff8
80102b00:	2b 10 80 
    *(int**)(code-12) = (void *) V2P(entrypgdir);
80102b03:	c7 05 f4 6f 00 80 00 	movl   $0x108000,0x80006ff4
80102b0a:	80 10 00 

    lapicstartap(c->apicid, V2P(code));
80102b0d:	83 c4 08             	add    $0x8,%esp
80102b10:	68 00 70 00 00       	push   $0x7000
80102b15:	0f b6 03             	movzbl (%ebx),%eax
80102b18:	50                   	push   %eax
80102b19:	e8 c1 f9 ff ff       	call   801024df <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80102b1e:	83 c4 10             	add    $0x10,%esp
80102b21:	8b 83 a0 00 00 00    	mov    0xa0(%ebx),%eax
80102b27:	85 c0                	test   %eax,%eax
80102b29:	74 f6                	je     80102b21 <startothers+0x83>
80102b2b:	eb 96                	jmp    80102ac3 <startothers+0x25>
      ;
  }
}
80102b2d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102b30:	c9                   	leave  
80102b31:	c3                   	ret    

80102b32 <mpmain>:
{
80102b32:	55                   	push   %ebp
80102b33:	89 e5                	mov    %esp,%ebp
80102b35:	53                   	push   %ebx
80102b36:	83 ec 04             	sub    $0x4,%esp
  cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
80102b39:	e8 d2 07 00 00       	call   80103310 <cpuid>
80102b3e:	89 c3                	mov    %eax,%ebx
80102b40:	e8 cb 07 00 00       	call   80103310 <cpuid>
80102b45:	83 ec 04             	sub    $0x4,%esp
80102b48:	53                   	push   %ebx
80102b49:	50                   	push   %eax
80102b4a:	68 e4 6a 10 80       	push   $0x80106ae4
80102b4f:	e8 b7 da ff ff       	call   8010060b <cprintf>
  idtinit();       // load idt register
80102b54:	e8 fc 23 00 00       	call   80104f55 <idtinit>
  xchg(&(mycpu()->started), 1); // tell startothers() we're up
80102b59:	e8 56 07 00 00       	call   801032b4 <mycpu>
80102b5e:	89 c2                	mov    %eax,%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80102b60:	b8 01 00 00 00       	mov    $0x1,%eax
80102b65:	f0 87 82 a0 00 00 00 	lock xchg %eax,0xa0(%edx)
  scheduler();     // start running processes
80102b6c:	e8 3c 0a 00 00       	call   801035ad <scheduler>

80102b71 <mpenter>:
{
80102b71:	55                   	push   %ebp
80102b72:	89 e5                	mov    %esp,%ebp
80102b74:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
80102b77:	e8 ea 33 00 00       	call   80105f66 <switchkvm>
  seginit();
80102b7c:	e8 99 32 00 00       	call   80105e1a <seginit>
  lapicinit();
80102b81:	e8 10 f8 ff ff       	call   80102396 <lapicinit>
  mpmain();
80102b86:	e8 a7 ff ff ff       	call   80102b32 <mpmain>

80102b8b <main>:
{
80102b8b:	8d 4c 24 04          	lea    0x4(%esp),%ecx
80102b8f:	83 e4 f0             	and    $0xfffffff0,%esp
80102b92:	ff 71 fc             	pushl  -0x4(%ecx)
80102b95:	55                   	push   %ebp
80102b96:	89 e5                	mov    %esp,%ebp
80102b98:	51                   	push   %ecx
80102b99:	83 ec 0c             	sub    $0xc,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80102b9c:	68 00 00 40 80       	push   $0x80400000
80102ba1:	68 c8 44 19 80       	push   $0x801944c8
80102ba6:	e8 ca f4 ff ff       	call   80102075 <kinit1>
  kvmalloc();      // kernel page table
80102bab:	e8 59 38 00 00       	call   80106409 <kvmalloc>
  mpinit();        // detect other processors
80102bb0:	e8 c9 01 00 00       	call   80102d7e <mpinit>
  lapicinit();     // interrupt controller
80102bb5:	e8 dc f7 ff ff       	call   80102396 <lapicinit>
  seginit();       // segment descriptors
80102bba:	e8 5b 32 00 00       	call   80105e1a <seginit>
  picinit();       // disable pic
80102bbf:	e8 82 02 00 00       	call   80102e46 <picinit>
  ioapicinit();    // another interrupt controller
80102bc4:	e8 3d f3 ff ff       	call   80101f06 <ioapicinit>
  consoleinit();   // console hardware
80102bc9:	e8 c0 dc ff ff       	call   8010088e <consoleinit>
  uartinit();      // serial port
80102bce:	e8 30 26 00 00       	call   80105203 <uartinit>
  pinit();         // process table
80102bd3:	e8 c2 06 00 00       	call   8010329a <pinit>
  tvinit();        // trap vectors
80102bd8:	e8 c7 22 00 00       	call   80104ea4 <tvinit>
  binit();         // buffer cache
80102bdd:	e8 12 d5 ff ff       	call   801000f4 <binit>
  fileinit();      // file table
80102be2:	e8 38 e0 ff ff       	call   80100c1f <fileinit>
  ideinit();       // disk 
80102be7:	e8 20 f1 ff ff       	call   80101d0c <ideinit>
  startothers();   // start other processors
80102bec:	e8 ad fe ff ff       	call   80102a9e <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80102bf1:	83 c4 08             	add    $0x8,%esp
80102bf4:	68 00 00 00 8e       	push   $0x8e000000
80102bf9:	68 00 00 40 80       	push   $0x80400000
80102bfe:	e8 a4 f4 ff ff       	call   801020a7 <kinit2>
  userinit();      // first user process
80102c03:	e8 47 07 00 00       	call   8010334f <userinit>
  mpmain();        // finish this processor's setup
80102c08:	e8 25 ff ff ff       	call   80102b32 <mpmain>

80102c0d <sum>:
int ncpu;
uchar ioapicid;

static uchar
sum(uchar *addr, int len)
{
80102c0d:	55                   	push   %ebp
80102c0e:	89 e5                	mov    %esp,%ebp
80102c10:	56                   	push   %esi
80102c11:	53                   	push   %ebx
  int i, sum;

  sum = 0;
80102c12:	bb 00 00 00 00       	mov    $0x0,%ebx
  for(i=0; i<len; i++)
80102c17:	b9 00 00 00 00       	mov    $0x0,%ecx
80102c1c:	eb 09                	jmp    80102c27 <sum+0x1a>
    sum += addr[i];
80102c1e:	0f b6 34 08          	movzbl (%eax,%ecx,1),%esi
80102c22:	01 f3                	add    %esi,%ebx
  for(i=0; i<len; i++)
80102c24:	83 c1 01             	add    $0x1,%ecx
80102c27:	39 d1                	cmp    %edx,%ecx
80102c29:	7c f3                	jl     80102c1e <sum+0x11>
  return sum;
}
80102c2b:	89 d8                	mov    %ebx,%eax
80102c2d:	5b                   	pop    %ebx
80102c2e:	5e                   	pop    %esi
80102c2f:	5d                   	pop    %ebp
80102c30:	c3                   	ret    

80102c31 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80102c31:	55                   	push   %ebp
80102c32:	89 e5                	mov    %esp,%ebp
80102c34:	56                   	push   %esi
80102c35:	53                   	push   %ebx
  uchar *e, *p, *addr;

  addr = P2V(a);
80102c36:	8d b0 00 00 00 80    	lea    -0x80000000(%eax),%esi
80102c3c:	89 f3                	mov    %esi,%ebx
  e = addr+len;
80102c3e:	01 d6                	add    %edx,%esi
  for(p = addr; p < e; p += sizeof(struct mp))
80102c40:	eb 03                	jmp    80102c45 <mpsearch1+0x14>
80102c42:	83 c3 10             	add    $0x10,%ebx
80102c45:	39 f3                	cmp    %esi,%ebx
80102c47:	73 29                	jae    80102c72 <mpsearch1+0x41>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80102c49:	83 ec 04             	sub    $0x4,%esp
80102c4c:	6a 04                	push   $0x4
80102c4e:	68 f8 6a 10 80       	push   $0x80106af8
80102c53:	53                   	push   %ebx
80102c54:	e8 66 11 00 00       	call   80103dbf <memcmp>
80102c59:	83 c4 10             	add    $0x10,%esp
80102c5c:	85 c0                	test   %eax,%eax
80102c5e:	75 e2                	jne    80102c42 <mpsearch1+0x11>
80102c60:	ba 10 00 00 00       	mov    $0x10,%edx
80102c65:	89 d8                	mov    %ebx,%eax
80102c67:	e8 a1 ff ff ff       	call   80102c0d <sum>
80102c6c:	84 c0                	test   %al,%al
80102c6e:	75 d2                	jne    80102c42 <mpsearch1+0x11>
80102c70:	eb 05                	jmp    80102c77 <mpsearch1+0x46>
      return (struct mp*)p;
  return 0;
80102c72:	bb 00 00 00 00       	mov    $0x0,%ebx
}
80102c77:	89 d8                	mov    %ebx,%eax
80102c79:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102c7c:	5b                   	pop    %ebx
80102c7d:	5e                   	pop    %esi
80102c7e:	5d                   	pop    %ebp
80102c7f:	c3                   	ret    

80102c80 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80102c80:	55                   	push   %ebp
80102c81:	89 e5                	mov    %esp,%ebp
80102c83:	83 ec 08             	sub    $0x8,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80102c86:	0f b6 05 0f 04 00 80 	movzbl 0x8000040f,%eax
80102c8d:	c1 e0 08             	shl    $0x8,%eax
80102c90:	0f b6 15 0e 04 00 80 	movzbl 0x8000040e,%edx
80102c97:	09 d0                	or     %edx,%eax
80102c99:	c1 e0 04             	shl    $0x4,%eax
80102c9c:	85 c0                	test   %eax,%eax
80102c9e:	74 1f                	je     80102cbf <mpsearch+0x3f>
    if((mp = mpsearch1(p, 1024)))
80102ca0:	ba 00 04 00 00       	mov    $0x400,%edx
80102ca5:	e8 87 ff ff ff       	call   80102c31 <mpsearch1>
80102caa:	85 c0                	test   %eax,%eax
80102cac:	75 0f                	jne    80102cbd <mpsearch+0x3d>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1(p-1024, 1024)))
      return mp;
  }
  return mpsearch1(0xF0000, 0x10000);
80102cae:	ba 00 00 01 00       	mov    $0x10000,%edx
80102cb3:	b8 00 00 0f 00       	mov    $0xf0000,%eax
80102cb8:	e8 74 ff ff ff       	call   80102c31 <mpsearch1>
}
80102cbd:	c9                   	leave  
80102cbe:	c3                   	ret    
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80102cbf:	0f b6 05 14 04 00 80 	movzbl 0x80000414,%eax
80102cc6:	c1 e0 08             	shl    $0x8,%eax
80102cc9:	0f b6 15 13 04 00 80 	movzbl 0x80000413,%edx
80102cd0:	09 d0                	or     %edx,%eax
80102cd2:	c1 e0 0a             	shl    $0xa,%eax
    if((mp = mpsearch1(p-1024, 1024)))
80102cd5:	2d 00 04 00 00       	sub    $0x400,%eax
80102cda:	ba 00 04 00 00       	mov    $0x400,%edx
80102cdf:	e8 4d ff ff ff       	call   80102c31 <mpsearch1>
80102ce4:	85 c0                	test   %eax,%eax
80102ce6:	75 d5                	jne    80102cbd <mpsearch+0x3d>
80102ce8:	eb c4                	jmp    80102cae <mpsearch+0x2e>

80102cea <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80102cea:	55                   	push   %ebp
80102ceb:	89 e5                	mov    %esp,%ebp
80102ced:	57                   	push   %edi
80102cee:	56                   	push   %esi
80102cef:	53                   	push   %ebx
80102cf0:	83 ec 1c             	sub    $0x1c,%esp
80102cf3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80102cf6:	e8 85 ff ff ff       	call   80102c80 <mpsearch>
80102cfb:	85 c0                	test   %eax,%eax
80102cfd:	74 5c                	je     80102d5b <mpconfig+0x71>
80102cff:	89 c7                	mov    %eax,%edi
80102d01:	8b 58 04             	mov    0x4(%eax),%ebx
80102d04:	85 db                	test   %ebx,%ebx
80102d06:	74 5a                	je     80102d62 <mpconfig+0x78>
    return 0;
  conf = (struct mpconf*) P2V((uint) mp->physaddr);
80102d08:	8d b3 00 00 00 80    	lea    -0x80000000(%ebx),%esi
  if(memcmp(conf, "PCMP", 4) != 0)
80102d0e:	83 ec 04             	sub    $0x4,%esp
80102d11:	6a 04                	push   $0x4
80102d13:	68 fd 6a 10 80       	push   $0x80106afd
80102d18:	56                   	push   %esi
80102d19:	e8 a1 10 00 00       	call   80103dbf <memcmp>
80102d1e:	83 c4 10             	add    $0x10,%esp
80102d21:	85 c0                	test   %eax,%eax
80102d23:	75 44                	jne    80102d69 <mpconfig+0x7f>
    return 0;
  if(conf->version != 1 && conf->version != 4)
80102d25:	0f b6 83 06 00 00 80 	movzbl -0x7ffffffa(%ebx),%eax
80102d2c:	3c 01                	cmp    $0x1,%al
80102d2e:	0f 95 c2             	setne  %dl
80102d31:	3c 04                	cmp    $0x4,%al
80102d33:	0f 95 c0             	setne  %al
80102d36:	84 c2                	test   %al,%dl
80102d38:	75 36                	jne    80102d70 <mpconfig+0x86>
    return 0;
  if(sum((uchar*)conf, conf->length) != 0)
80102d3a:	0f b7 93 04 00 00 80 	movzwl -0x7ffffffc(%ebx),%edx
80102d41:	89 f0                	mov    %esi,%eax
80102d43:	e8 c5 fe ff ff       	call   80102c0d <sum>
80102d48:	84 c0                	test   %al,%al
80102d4a:	75 2b                	jne    80102d77 <mpconfig+0x8d>
    return 0;
  *pmp = mp;
80102d4c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102d4f:	89 38                	mov    %edi,(%eax)
  return conf;
}
80102d51:	89 f0                	mov    %esi,%eax
80102d53:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102d56:	5b                   	pop    %ebx
80102d57:	5e                   	pop    %esi
80102d58:	5f                   	pop    %edi
80102d59:	5d                   	pop    %ebp
80102d5a:	c3                   	ret    
    return 0;
80102d5b:	be 00 00 00 00       	mov    $0x0,%esi
80102d60:	eb ef                	jmp    80102d51 <mpconfig+0x67>
80102d62:	be 00 00 00 00       	mov    $0x0,%esi
80102d67:	eb e8                	jmp    80102d51 <mpconfig+0x67>
    return 0;
80102d69:	be 00 00 00 00       	mov    $0x0,%esi
80102d6e:	eb e1                	jmp    80102d51 <mpconfig+0x67>
    return 0;
80102d70:	be 00 00 00 00       	mov    $0x0,%esi
80102d75:	eb da                	jmp    80102d51 <mpconfig+0x67>
    return 0;
80102d77:	be 00 00 00 00       	mov    $0x0,%esi
80102d7c:	eb d3                	jmp    80102d51 <mpconfig+0x67>

80102d7e <mpinit>:

void
mpinit(void)
{
80102d7e:	55                   	push   %ebp
80102d7f:	89 e5                	mov    %esp,%ebp
80102d81:	57                   	push   %edi
80102d82:	56                   	push   %esi
80102d83:	53                   	push   %ebx
80102d84:	83 ec 1c             	sub    $0x1c,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  if((conf = mpconfig(&mp)) == 0)
80102d87:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80102d8a:	e8 5b ff ff ff       	call   80102cea <mpconfig>
80102d8f:	85 c0                	test   %eax,%eax
80102d91:	74 19                	je     80102dac <mpinit+0x2e>
    panic("Expect to run on an SMP");
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
80102d93:	8b 50 24             	mov    0x24(%eax),%edx
80102d96:	89 15 80 16 19 80    	mov    %edx,0x80191680
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102d9c:	8d 50 2c             	lea    0x2c(%eax),%edx
80102d9f:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
80102da3:	01 c1                	add    %eax,%ecx
  ismp = 1;
80102da5:	bb 01 00 00 00       	mov    $0x1,%ebx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102daa:	eb 34                	jmp    80102de0 <mpinit+0x62>
    panic("Expect to run on an SMP");
80102dac:	83 ec 0c             	sub    $0xc,%esp
80102daf:	68 02 6b 10 80       	push   $0x80106b02
80102db4:	e8 8f d5 ff ff       	call   80100348 <panic>
    switch(*p){
    case MPPROC:
      proc = (struct mpproc*)p;
      if(ncpu < NCPU) {
80102db9:	8b 35 20 1d 19 80    	mov    0x80191d20,%esi
80102dbf:	83 fe 07             	cmp    $0x7,%esi
80102dc2:	7f 19                	jg     80102ddd <mpinit+0x5f>
        cpus[ncpu].apicid = proc->apicid;  // apicid may differ from ncpu
80102dc4:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102dc8:	69 fe b0 00 00 00    	imul   $0xb0,%esi,%edi
80102dce:	88 87 a0 17 19 80    	mov    %al,-0x7fe6e860(%edi)
        ncpu++;
80102dd4:	83 c6 01             	add    $0x1,%esi
80102dd7:	89 35 20 1d 19 80    	mov    %esi,0x80191d20
      }
      p += sizeof(struct mpproc);
80102ddd:	83 c2 14             	add    $0x14,%edx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102de0:	39 ca                	cmp    %ecx,%edx
80102de2:	73 2b                	jae    80102e0f <mpinit+0x91>
    switch(*p){
80102de4:	0f b6 02             	movzbl (%edx),%eax
80102de7:	3c 04                	cmp    $0x4,%al
80102de9:	77 1d                	ja     80102e08 <mpinit+0x8a>
80102deb:	0f b6 c0             	movzbl %al,%eax
80102dee:	ff 24 85 3c 6b 10 80 	jmp    *-0x7fef94c4(,%eax,4)
      continue;
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
      ioapicid = ioapic->apicno;
80102df5:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102df9:	a2 80 17 19 80       	mov    %al,0x80191780
      p += sizeof(struct mpioapic);
80102dfe:	83 c2 08             	add    $0x8,%edx
      continue;
80102e01:	eb dd                	jmp    80102de0 <mpinit+0x62>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80102e03:	83 c2 08             	add    $0x8,%edx
      continue;
80102e06:	eb d8                	jmp    80102de0 <mpinit+0x62>
    default:
      ismp = 0;
80102e08:	bb 00 00 00 00       	mov    $0x0,%ebx
80102e0d:	eb d1                	jmp    80102de0 <mpinit+0x62>
      break;
    }
  }
  if(!ismp)
80102e0f:	85 db                	test   %ebx,%ebx
80102e11:	74 26                	je     80102e39 <mpinit+0xbb>
    panic("Didn't find a suitable machine");

  if(mp->imcrp){
80102e13:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102e16:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
80102e1a:	74 15                	je     80102e31 <mpinit+0xb3>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102e1c:	b8 70 00 00 00       	mov    $0x70,%eax
80102e21:	ba 22 00 00 00       	mov    $0x22,%edx
80102e26:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102e27:	ba 23 00 00 00       	mov    $0x23,%edx
80102e2c:	ec                   	in     (%dx),%al
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80102e2d:	83 c8 01             	or     $0x1,%eax
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102e30:	ee                   	out    %al,(%dx)
  }
}
80102e31:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102e34:	5b                   	pop    %ebx
80102e35:	5e                   	pop    %esi
80102e36:	5f                   	pop    %edi
80102e37:	5d                   	pop    %ebp
80102e38:	c3                   	ret    
    panic("Didn't find a suitable machine");
80102e39:	83 ec 0c             	sub    $0xc,%esp
80102e3c:	68 1c 6b 10 80       	push   $0x80106b1c
80102e41:	e8 02 d5 ff ff       	call   80100348 <panic>

80102e46 <picinit>:
#define IO_PIC2         0xA0    // Slave (IRQs 8-15)

// Don't use the 8259A interrupt controllers.  Xv6 assumes SMP hardware.
void
picinit(void)
{
80102e46:	55                   	push   %ebp
80102e47:	89 e5                	mov    %esp,%ebp
80102e49:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102e4e:	ba 21 00 00 00       	mov    $0x21,%edx
80102e53:	ee                   	out    %al,(%dx)
80102e54:	ba a1 00 00 00       	mov    $0xa1,%edx
80102e59:	ee                   	out    %al,(%dx)
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
  outb(IO_PIC2+1, 0xFF);
}
80102e5a:	5d                   	pop    %ebp
80102e5b:	c3                   	ret    

80102e5c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80102e5c:	55                   	push   %ebp
80102e5d:	89 e5                	mov    %esp,%ebp
80102e5f:	57                   	push   %edi
80102e60:	56                   	push   %esi
80102e61:	53                   	push   %ebx
80102e62:	83 ec 0c             	sub    $0xc,%esp
80102e65:	8b 5d 08             	mov    0x8(%ebp),%ebx
80102e68:	8b 75 0c             	mov    0xc(%ebp),%esi
  struct pipe *p;

  p = 0;
  *f0 = *f1 = 0;
80102e6b:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80102e71:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80102e77:	e8 bd dd ff ff       	call   80100c39 <filealloc>
80102e7c:	89 03                	mov    %eax,(%ebx)
80102e7e:	85 c0                	test   %eax,%eax
80102e80:	74 1e                	je     80102ea0 <pipealloc+0x44>
80102e82:	e8 b2 dd ff ff       	call   80100c39 <filealloc>
80102e87:	89 06                	mov    %eax,(%esi)
80102e89:	85 c0                	test   %eax,%eax
80102e8b:	74 13                	je     80102ea0 <pipealloc+0x44>
    goto bad;
  if((p = (struct pipe*)kalloc(-2)) == 0)
80102e8d:	83 ec 0c             	sub    $0xc,%esp
80102e90:	6a fe                	push   $0xfffffffe
80102e92:	e8 61 f2 ff ff       	call   801020f8 <kalloc>
80102e97:	89 c7                	mov    %eax,%edi
80102e99:	83 c4 10             	add    $0x10,%esp
80102e9c:	85 c0                	test   %eax,%eax
80102e9e:	75 35                	jne    80102ed5 <pipealloc+0x79>
  return 0;

 bad:
  if(p)
    kfree((char*)p);
  if(*f0)
80102ea0:	8b 03                	mov    (%ebx),%eax
80102ea2:	85 c0                	test   %eax,%eax
80102ea4:	74 0c                	je     80102eb2 <pipealloc+0x56>
    fileclose(*f0);
80102ea6:	83 ec 0c             	sub    $0xc,%esp
80102ea9:	50                   	push   %eax
80102eaa:	e8 30 de ff ff       	call   80100cdf <fileclose>
80102eaf:	83 c4 10             	add    $0x10,%esp
  if(*f1)
80102eb2:	8b 06                	mov    (%esi),%eax
80102eb4:	85 c0                	test   %eax,%eax
80102eb6:	0f 84 8b 00 00 00    	je     80102f47 <pipealloc+0xeb>
    fileclose(*f1);
80102ebc:	83 ec 0c             	sub    $0xc,%esp
80102ebf:	50                   	push   %eax
80102ec0:	e8 1a de ff ff       	call   80100cdf <fileclose>
80102ec5:	83 c4 10             	add    $0x10,%esp
  return -1;
80102ec8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80102ecd:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102ed0:	5b                   	pop    %ebx
80102ed1:	5e                   	pop    %esi
80102ed2:	5f                   	pop    %edi
80102ed3:	5d                   	pop    %ebp
80102ed4:	c3                   	ret    
  p->readopen = 1;
80102ed5:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80102edc:	00 00 00 
  p->writeopen = 1;
80102edf:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80102ee6:	00 00 00 
  p->nwrite = 0;
80102ee9:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80102ef0:	00 00 00 
  p->nread = 0;
80102ef3:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80102efa:	00 00 00 
  initlock(&p->lock, "pipe");
80102efd:	83 ec 08             	sub    $0x8,%esp
80102f00:	68 50 6b 10 80       	push   $0x80106b50
80102f05:	50                   	push   %eax
80102f06:	e8 86 0c 00 00       	call   80103b91 <initlock>
  (*f0)->type = FD_PIPE;
80102f0b:	8b 03                	mov    (%ebx),%eax
80102f0d:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80102f13:	8b 03                	mov    (%ebx),%eax
80102f15:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80102f19:	8b 03                	mov    (%ebx),%eax
80102f1b:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80102f1f:	8b 03                	mov    (%ebx),%eax
80102f21:	89 78 0c             	mov    %edi,0xc(%eax)
  (*f1)->type = FD_PIPE;
80102f24:	8b 06                	mov    (%esi),%eax
80102f26:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80102f2c:	8b 06                	mov    (%esi),%eax
80102f2e:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80102f32:	8b 06                	mov    (%esi),%eax
80102f34:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80102f38:	8b 06                	mov    (%esi),%eax
80102f3a:	89 78 0c             	mov    %edi,0xc(%eax)
  return 0;
80102f3d:	83 c4 10             	add    $0x10,%esp
80102f40:	b8 00 00 00 00       	mov    $0x0,%eax
80102f45:	eb 86                	jmp    80102ecd <pipealloc+0x71>
  return -1;
80102f47:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102f4c:	e9 7c ff ff ff       	jmp    80102ecd <pipealloc+0x71>

80102f51 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80102f51:	55                   	push   %ebp
80102f52:	89 e5                	mov    %esp,%ebp
80102f54:	53                   	push   %ebx
80102f55:	83 ec 10             	sub    $0x10,%esp
80102f58:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&p->lock);
80102f5b:	53                   	push   %ebx
80102f5c:	e8 6c 0d 00 00       	call   80103ccd <acquire>
  if(writable){
80102f61:	83 c4 10             	add    $0x10,%esp
80102f64:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102f68:	74 3f                	je     80102fa9 <pipeclose+0x58>
    p->writeopen = 0;
80102f6a:	c7 83 40 02 00 00 00 	movl   $0x0,0x240(%ebx)
80102f71:	00 00 00 
    wakeup(&p->nread);
80102f74:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102f7a:	83 ec 0c             	sub    $0xc,%esp
80102f7d:	50                   	push   %eax
80102f7e:	e8 b4 09 00 00       	call   80103937 <wakeup>
80102f83:	83 c4 10             	add    $0x10,%esp
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
80102f86:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80102f8d:	75 09                	jne    80102f98 <pipeclose+0x47>
80102f8f:	83 bb 40 02 00 00 00 	cmpl   $0x0,0x240(%ebx)
80102f96:	74 2f                	je     80102fc7 <pipeclose+0x76>
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
80102f98:	83 ec 0c             	sub    $0xc,%esp
80102f9b:	53                   	push   %ebx
80102f9c:	e8 91 0d 00 00       	call   80103d32 <release>
80102fa1:	83 c4 10             	add    $0x10,%esp
}
80102fa4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102fa7:	c9                   	leave  
80102fa8:	c3                   	ret    
    p->readopen = 0;
80102fa9:	c7 83 3c 02 00 00 00 	movl   $0x0,0x23c(%ebx)
80102fb0:	00 00 00 
    wakeup(&p->nwrite);
80102fb3:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80102fb9:	83 ec 0c             	sub    $0xc,%esp
80102fbc:	50                   	push   %eax
80102fbd:	e8 75 09 00 00       	call   80103937 <wakeup>
80102fc2:	83 c4 10             	add    $0x10,%esp
80102fc5:	eb bf                	jmp    80102f86 <pipeclose+0x35>
    release(&p->lock);
80102fc7:	83 ec 0c             	sub    $0xc,%esp
80102fca:	53                   	push   %ebx
80102fcb:	e8 62 0d 00 00       	call   80103d32 <release>
    kfree((char*)p);
80102fd0:	89 1c 24             	mov    %ebx,(%esp)
80102fd3:	e8 d8 ef ff ff       	call   80101fb0 <kfree>
80102fd8:	83 c4 10             	add    $0x10,%esp
80102fdb:	eb c7                	jmp    80102fa4 <pipeclose+0x53>

80102fdd <pipewrite>:

int
pipewrite(struct pipe *p, char *addr, int n)
{
80102fdd:	55                   	push   %ebp
80102fde:	89 e5                	mov    %esp,%ebp
80102fe0:	57                   	push   %edi
80102fe1:	56                   	push   %esi
80102fe2:	53                   	push   %ebx
80102fe3:	83 ec 18             	sub    $0x18,%esp
80102fe6:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80102fe9:	89 de                	mov    %ebx,%esi
80102feb:	53                   	push   %ebx
80102fec:	e8 dc 0c 00 00       	call   80103ccd <acquire>
  for(i = 0; i < n; i++){
80102ff1:	83 c4 10             	add    $0x10,%esp
80102ff4:	bf 00 00 00 00       	mov    $0x0,%edi
80102ff9:	3b 7d 10             	cmp    0x10(%ebp),%edi
80102ffc:	0f 8d 88 00 00 00    	jge    8010308a <pipewrite+0xad>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80103002:	8b 93 38 02 00 00    	mov    0x238(%ebx),%edx
80103008:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
8010300e:	05 00 02 00 00       	add    $0x200,%eax
80103013:	39 c2                	cmp    %eax,%edx
80103015:	75 51                	jne    80103068 <pipewrite+0x8b>
      if(p->readopen == 0 || myproc()->killed){
80103017:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
8010301e:	74 2f                	je     8010304f <pipewrite+0x72>
80103020:	e8 06 03 00 00       	call   8010332b <myproc>
80103025:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80103029:	75 24                	jne    8010304f <pipewrite+0x72>
        release(&p->lock);
        return -1;
      }
      wakeup(&p->nread);
8010302b:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80103031:	83 ec 0c             	sub    $0xc,%esp
80103034:	50                   	push   %eax
80103035:	e8 fd 08 00 00       	call   80103937 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
8010303a:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80103040:	83 c4 08             	add    $0x8,%esp
80103043:	56                   	push   %esi
80103044:	50                   	push   %eax
80103045:	e8 88 07 00 00       	call   801037d2 <sleep>
8010304a:	83 c4 10             	add    $0x10,%esp
8010304d:	eb b3                	jmp    80103002 <pipewrite+0x25>
        release(&p->lock);
8010304f:	83 ec 0c             	sub    $0xc,%esp
80103052:	53                   	push   %ebx
80103053:	e8 da 0c 00 00       	call   80103d32 <release>
        return -1;
80103058:	83 c4 10             	add    $0x10,%esp
8010305b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
  release(&p->lock);
  return n;
}
80103060:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103063:	5b                   	pop    %ebx
80103064:	5e                   	pop    %esi
80103065:	5f                   	pop    %edi
80103066:	5d                   	pop    %ebp
80103067:	c3                   	ret    
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80103068:	8d 42 01             	lea    0x1(%edx),%eax
8010306b:	89 83 38 02 00 00    	mov    %eax,0x238(%ebx)
80103071:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80103077:	8b 45 0c             	mov    0xc(%ebp),%eax
8010307a:	0f b6 04 38          	movzbl (%eax,%edi,1),%eax
8010307e:	88 44 13 34          	mov    %al,0x34(%ebx,%edx,1)
  for(i = 0; i < n; i++){
80103082:	83 c7 01             	add    $0x1,%edi
80103085:	e9 6f ff ff ff       	jmp    80102ff9 <pipewrite+0x1c>
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
8010308a:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80103090:	83 ec 0c             	sub    $0xc,%esp
80103093:	50                   	push   %eax
80103094:	e8 9e 08 00 00       	call   80103937 <wakeup>
  release(&p->lock);
80103099:	89 1c 24             	mov    %ebx,(%esp)
8010309c:	e8 91 0c 00 00       	call   80103d32 <release>
  return n;
801030a1:	83 c4 10             	add    $0x10,%esp
801030a4:	8b 45 10             	mov    0x10(%ebp),%eax
801030a7:	eb b7                	jmp    80103060 <pipewrite+0x83>

801030a9 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
801030a9:	55                   	push   %ebp
801030aa:	89 e5                	mov    %esp,%ebp
801030ac:	57                   	push   %edi
801030ad:	56                   	push   %esi
801030ae:	53                   	push   %ebx
801030af:	83 ec 18             	sub    $0x18,%esp
801030b2:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
801030b5:	89 df                	mov    %ebx,%edi
801030b7:	53                   	push   %ebx
801030b8:	e8 10 0c 00 00       	call   80103ccd <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801030bd:	83 c4 10             	add    $0x10,%esp
801030c0:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
801030c6:	39 83 34 02 00 00    	cmp    %eax,0x234(%ebx)
801030cc:	75 3d                	jne    8010310b <piperead+0x62>
801030ce:	8b b3 40 02 00 00    	mov    0x240(%ebx),%esi
801030d4:	85 f6                	test   %esi,%esi
801030d6:	74 38                	je     80103110 <piperead+0x67>
    if(myproc()->killed){
801030d8:	e8 4e 02 00 00       	call   8010332b <myproc>
801030dd:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801030e1:	75 15                	jne    801030f8 <piperead+0x4f>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
801030e3:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
801030e9:	83 ec 08             	sub    $0x8,%esp
801030ec:	57                   	push   %edi
801030ed:	50                   	push   %eax
801030ee:	e8 df 06 00 00       	call   801037d2 <sleep>
801030f3:	83 c4 10             	add    $0x10,%esp
801030f6:	eb c8                	jmp    801030c0 <piperead+0x17>
      release(&p->lock);
801030f8:	83 ec 0c             	sub    $0xc,%esp
801030fb:	53                   	push   %ebx
801030fc:	e8 31 0c 00 00       	call   80103d32 <release>
      return -1;
80103101:	83 c4 10             	add    $0x10,%esp
80103104:	be ff ff ff ff       	mov    $0xffffffff,%esi
80103109:	eb 50                	jmp    8010315b <piperead+0xb2>
8010310b:	be 00 00 00 00       	mov    $0x0,%esi
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80103110:	3b 75 10             	cmp    0x10(%ebp),%esi
80103113:	7d 2c                	jge    80103141 <piperead+0x98>
    if(p->nread == p->nwrite)
80103115:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
8010311b:	3b 83 38 02 00 00    	cmp    0x238(%ebx),%eax
80103121:	74 1e                	je     80103141 <piperead+0x98>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
80103123:	8d 50 01             	lea    0x1(%eax),%edx
80103126:	89 93 34 02 00 00    	mov    %edx,0x234(%ebx)
8010312c:	25 ff 01 00 00       	and    $0x1ff,%eax
80103131:	0f b6 44 03 34       	movzbl 0x34(%ebx,%eax,1),%eax
80103136:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103139:	88 04 31             	mov    %al,(%ecx,%esi,1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
8010313c:	83 c6 01             	add    $0x1,%esi
8010313f:	eb cf                	jmp    80103110 <piperead+0x67>
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80103141:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80103147:	83 ec 0c             	sub    $0xc,%esp
8010314a:	50                   	push   %eax
8010314b:	e8 e7 07 00 00       	call   80103937 <wakeup>
  release(&p->lock);
80103150:	89 1c 24             	mov    %ebx,(%esp)
80103153:	e8 da 0b 00 00       	call   80103d32 <release>
  return i;
80103158:	83 c4 10             	add    $0x10,%esp
}
8010315b:	89 f0                	mov    %esi,%eax
8010315d:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103160:	5b                   	pop    %ebx
80103161:	5e                   	pop    %esi
80103162:	5f                   	pop    %edi
80103163:	5d                   	pop    %ebp
80103164:	c3                   	ret    

80103165 <wakeup1>:

// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80103165:	55                   	push   %ebp
80103166:	89 e5                	mov    %esp,%ebp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103168:	ba 74 1d 19 80       	mov    $0x80191d74,%edx
8010316d:	eb 03                	jmp    80103172 <wakeup1+0xd>
8010316f:	83 c2 7c             	add    $0x7c,%edx
80103172:	81 fa 74 3c 19 80    	cmp    $0x80193c74,%edx
80103178:	73 14                	jae    8010318e <wakeup1+0x29>
    if(p->state == SLEEPING && p->chan == chan)
8010317a:	83 7a 0c 02          	cmpl   $0x2,0xc(%edx)
8010317e:	75 ef                	jne    8010316f <wakeup1+0xa>
80103180:	39 42 20             	cmp    %eax,0x20(%edx)
80103183:	75 ea                	jne    8010316f <wakeup1+0xa>
      p->state = RUNNABLE;
80103185:	c7 42 0c 03 00 00 00 	movl   $0x3,0xc(%edx)
8010318c:	eb e1                	jmp    8010316f <wakeup1+0xa>
}
8010318e:	5d                   	pop    %ebp
8010318f:	c3                   	ret    

80103190 <allocproc>:
{
80103190:	55                   	push   %ebp
80103191:	89 e5                	mov    %esp,%ebp
80103193:	53                   	push   %ebx
80103194:	83 ec 10             	sub    $0x10,%esp
  acquire(&ptable.lock);
80103197:	68 40 1d 19 80       	push   $0x80191d40
8010319c:	e8 2c 0b 00 00       	call   80103ccd <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801031a1:	83 c4 10             	add    $0x10,%esp
801031a4:	bb 74 1d 19 80       	mov    $0x80191d74,%ebx
801031a9:	81 fb 74 3c 19 80    	cmp    $0x80193c74,%ebx
801031af:	73 0b                	jae    801031bc <allocproc+0x2c>
    if(p->state == UNUSED)
801031b1:	83 7b 0c 00          	cmpl   $0x0,0xc(%ebx)
801031b5:	74 1c                	je     801031d3 <allocproc+0x43>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801031b7:	83 c3 7c             	add    $0x7c,%ebx
801031ba:	eb ed                	jmp    801031a9 <allocproc+0x19>
  release(&ptable.lock);
801031bc:	83 ec 0c             	sub    $0xc,%esp
801031bf:	68 40 1d 19 80       	push   $0x80191d40
801031c4:	e8 69 0b 00 00       	call   80103d32 <release>
  return 0;
801031c9:	83 c4 10             	add    $0x10,%esp
801031cc:	bb 00 00 00 00       	mov    $0x0,%ebx
801031d1:	eb 6f                	jmp    80103242 <allocproc+0xb2>
  p->state = EMBRYO;
801031d3:	c7 43 0c 01 00 00 00 	movl   $0x1,0xc(%ebx)
  p->pid = nextpid++;
801031da:	a1 04 90 10 80       	mov    0x80109004,%eax
801031df:	8d 50 01             	lea    0x1(%eax),%edx
801031e2:	89 15 04 90 10 80    	mov    %edx,0x80109004
801031e8:	89 43 10             	mov    %eax,0x10(%ebx)
  release(&ptable.lock);
801031eb:	83 ec 0c             	sub    $0xc,%esp
801031ee:	68 40 1d 19 80       	push   $0x80191d40
801031f3:	e8 3a 0b 00 00       	call   80103d32 <release>
  if((p->kstack = kalloc(p->pid)) == 0){
801031f8:	83 c4 04             	add    $0x4,%esp
801031fb:	ff 73 10             	pushl  0x10(%ebx)
801031fe:	e8 f5 ee ff ff       	call   801020f8 <kalloc>
80103203:	89 43 08             	mov    %eax,0x8(%ebx)
80103206:	83 c4 10             	add    $0x10,%esp
80103209:	85 c0                	test   %eax,%eax
8010320b:	74 3c                	je     80103249 <allocproc+0xb9>
  sp -= sizeof *p->tf;
8010320d:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
  p->tf = (struct trapframe*)sp;
80103213:	89 53 18             	mov    %edx,0x18(%ebx)
  *(uint*)sp = (uint)trapret;
80103216:	c7 80 b0 0f 00 00 99 	movl   $0x80104e99,0xfb0(%eax)
8010321d:	4e 10 80 
  sp -= sizeof *p->context;
80103220:	05 9c 0f 00 00       	add    $0xf9c,%eax
  p->context = (struct context*)sp;
80103225:	89 43 1c             	mov    %eax,0x1c(%ebx)
  memset(p->context, 0, sizeof *p->context);
80103228:	83 ec 04             	sub    $0x4,%esp
8010322b:	6a 14                	push   $0x14
8010322d:	6a 00                	push   $0x0
8010322f:	50                   	push   %eax
80103230:	e8 44 0b 00 00       	call   80103d79 <memset>
  p->context->eip = (uint)forkret;
80103235:	8b 43 1c             	mov    0x1c(%ebx),%eax
80103238:	c7 40 10 57 32 10 80 	movl   $0x80103257,0x10(%eax)
  return p;
8010323f:	83 c4 10             	add    $0x10,%esp
}
80103242:	89 d8                	mov    %ebx,%eax
80103244:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103247:	c9                   	leave  
80103248:	c3                   	ret    
    p->state = UNUSED;
80103249:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return 0;
80103250:	bb 00 00 00 00       	mov    $0x0,%ebx
80103255:	eb eb                	jmp    80103242 <allocproc+0xb2>

80103257 <forkret>:
{
80103257:	55                   	push   %ebp
80103258:	89 e5                	mov    %esp,%ebp
8010325a:	83 ec 14             	sub    $0x14,%esp
  release(&ptable.lock);
8010325d:	68 40 1d 19 80       	push   $0x80191d40
80103262:	e8 cb 0a 00 00       	call   80103d32 <release>
  if (first) {
80103267:	83 c4 10             	add    $0x10,%esp
8010326a:	83 3d 00 90 10 80 00 	cmpl   $0x0,0x80109000
80103271:	75 02                	jne    80103275 <forkret+0x1e>
}
80103273:	c9                   	leave  
80103274:	c3                   	ret    
    first = 0;
80103275:	c7 05 00 90 10 80 00 	movl   $0x0,0x80109000
8010327c:	00 00 00 
    iinit(ROOTDEV);
8010327f:	83 ec 0c             	sub    $0xc,%esp
80103282:	6a 01                	push   $0x1
80103284:	e8 6f e0 ff ff       	call   801012f8 <iinit>
    initlog(ROOTDEV);
80103289:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103290:	e8 f2 f5 ff ff       	call   80102887 <initlog>
80103295:	83 c4 10             	add    $0x10,%esp
}
80103298:	eb d9                	jmp    80103273 <forkret+0x1c>

8010329a <pinit>:
{
8010329a:	55                   	push   %ebp
8010329b:	89 e5                	mov    %esp,%ebp
8010329d:	83 ec 10             	sub    $0x10,%esp
  initlock(&ptable.lock, "ptable");
801032a0:	68 55 6b 10 80       	push   $0x80106b55
801032a5:	68 40 1d 19 80       	push   $0x80191d40
801032aa:	e8 e2 08 00 00       	call   80103b91 <initlock>
}
801032af:	83 c4 10             	add    $0x10,%esp
801032b2:	c9                   	leave  
801032b3:	c3                   	ret    

801032b4 <mycpu>:
{
801032b4:	55                   	push   %ebp
801032b5:	89 e5                	mov    %esp,%ebp
801032b7:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801032ba:	9c                   	pushf  
801032bb:	58                   	pop    %eax
  if(readeflags()&FL_IF)
801032bc:	f6 c4 02             	test   $0x2,%ah
801032bf:	75 28                	jne    801032e9 <mycpu+0x35>
  apicid = lapicid();
801032c1:	e8 da f1 ff ff       	call   801024a0 <lapicid>
  for (i = 0; i < ncpu; ++i) {
801032c6:	ba 00 00 00 00       	mov    $0x0,%edx
801032cb:	39 15 20 1d 19 80    	cmp    %edx,0x80191d20
801032d1:	7e 23                	jle    801032f6 <mycpu+0x42>
    if (cpus[i].apicid == apicid)
801032d3:	69 ca b0 00 00 00    	imul   $0xb0,%edx,%ecx
801032d9:	0f b6 89 a0 17 19 80 	movzbl -0x7fe6e860(%ecx),%ecx
801032e0:	39 c1                	cmp    %eax,%ecx
801032e2:	74 1f                	je     80103303 <mycpu+0x4f>
  for (i = 0; i < ncpu; ++i) {
801032e4:	83 c2 01             	add    $0x1,%edx
801032e7:	eb e2                	jmp    801032cb <mycpu+0x17>
    panic("mycpu called with interrupts enabled\n");
801032e9:	83 ec 0c             	sub    $0xc,%esp
801032ec:	68 38 6c 10 80       	push   $0x80106c38
801032f1:	e8 52 d0 ff ff       	call   80100348 <panic>
  panic("unknown apicid\n");
801032f6:	83 ec 0c             	sub    $0xc,%esp
801032f9:	68 5c 6b 10 80       	push   $0x80106b5c
801032fe:	e8 45 d0 ff ff       	call   80100348 <panic>
      return &cpus[i];
80103303:	69 c2 b0 00 00 00    	imul   $0xb0,%edx,%eax
80103309:	05 a0 17 19 80       	add    $0x801917a0,%eax
}
8010330e:	c9                   	leave  
8010330f:	c3                   	ret    

80103310 <cpuid>:
cpuid() {
80103310:	55                   	push   %ebp
80103311:	89 e5                	mov    %esp,%ebp
80103313:	83 ec 08             	sub    $0x8,%esp
  return mycpu()-cpus;
80103316:	e8 99 ff ff ff       	call   801032b4 <mycpu>
8010331b:	2d a0 17 19 80       	sub    $0x801917a0,%eax
80103320:	c1 f8 04             	sar    $0x4,%eax
80103323:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
80103329:	c9                   	leave  
8010332a:	c3                   	ret    

8010332b <myproc>:
myproc(void) {
8010332b:	55                   	push   %ebp
8010332c:	89 e5                	mov    %esp,%ebp
8010332e:	53                   	push   %ebx
8010332f:	83 ec 04             	sub    $0x4,%esp
  pushcli();
80103332:	e8 b9 08 00 00       	call   80103bf0 <pushcli>
  c = mycpu();
80103337:	e8 78 ff ff ff       	call   801032b4 <mycpu>
  p = c->proc;
8010333c:	8b 98 ac 00 00 00    	mov    0xac(%eax),%ebx
  popcli();
80103342:	e8 e6 08 00 00       	call   80103c2d <popcli>
}
80103347:	89 d8                	mov    %ebx,%eax
80103349:	83 c4 04             	add    $0x4,%esp
8010334c:	5b                   	pop    %ebx
8010334d:	5d                   	pop    %ebp
8010334e:	c3                   	ret    

8010334f <userinit>:
{
8010334f:	55                   	push   %ebp
80103350:	89 e5                	mov    %esp,%ebp
80103352:	53                   	push   %ebx
80103353:	83 ec 04             	sub    $0x4,%esp
  p = allocproc();
80103356:	e8 35 fe ff ff       	call   80103190 <allocproc>
8010335b:	89 c3                	mov    %eax,%ebx
  initproc = p;
8010335d:	a3 b8 95 10 80       	mov    %eax,0x801095b8
  if((p->pgdir = setupkvm()) == 0)
80103362:	e8 2c 30 00 00       	call   80106393 <setupkvm>
80103367:	89 43 04             	mov    %eax,0x4(%ebx)
8010336a:	85 c0                	test   %eax,%eax
8010336c:	0f 84 b7 00 00 00    	je     80103429 <userinit+0xda>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80103372:	83 ec 04             	sub    $0x4,%esp
80103375:	68 2c 00 00 00       	push   $0x2c
8010337a:	68 60 94 10 80       	push   $0x80109460
8010337f:	50                   	push   %eax
80103380:	e8 0b 2d 00 00       	call   80106090 <inituvm>
  p->sz = PGSIZE;
80103385:	c7 03 00 10 00 00    	movl   $0x1000,(%ebx)
  memset(p->tf, 0, sizeof(*p->tf));
8010338b:	83 c4 0c             	add    $0xc,%esp
8010338e:	6a 4c                	push   $0x4c
80103390:	6a 00                	push   $0x0
80103392:	ff 73 18             	pushl  0x18(%ebx)
80103395:	e8 df 09 00 00       	call   80103d79 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
8010339a:	8b 43 18             	mov    0x18(%ebx),%eax
8010339d:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
801033a3:	8b 43 18             	mov    0x18(%ebx),%eax
801033a6:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
  p->tf->es = p->tf->ds;
801033ac:	8b 43 18             	mov    0x18(%ebx),%eax
801033af:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801033b3:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
801033b7:	8b 43 18             	mov    0x18(%ebx),%eax
801033ba:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801033be:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
801033c2:	8b 43 18             	mov    0x18(%ebx),%eax
801033c5:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801033cc:	8b 43 18             	mov    0x18(%ebx),%eax
801033cf:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
801033d6:	8b 43 18             	mov    0x18(%ebx),%eax
801033d9:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
  safestrcpy(p->name, "initcode", sizeof(p->name));
801033e0:	8d 43 6c             	lea    0x6c(%ebx),%eax
801033e3:	83 c4 0c             	add    $0xc,%esp
801033e6:	6a 10                	push   $0x10
801033e8:	68 85 6b 10 80       	push   $0x80106b85
801033ed:	50                   	push   %eax
801033ee:	e8 ed 0a 00 00       	call   80103ee0 <safestrcpy>
  p->cwd = namei("/");
801033f3:	c7 04 24 8e 6b 10 80 	movl   $0x80106b8e,(%esp)
801033fa:	e8 ee e7 ff ff       	call   80101bed <namei>
801033ff:	89 43 68             	mov    %eax,0x68(%ebx)
  acquire(&ptable.lock);
80103402:	c7 04 24 40 1d 19 80 	movl   $0x80191d40,(%esp)
80103409:	e8 bf 08 00 00       	call   80103ccd <acquire>
  p->state = RUNNABLE;
8010340e:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  release(&ptable.lock);
80103415:	c7 04 24 40 1d 19 80 	movl   $0x80191d40,(%esp)
8010341c:	e8 11 09 00 00       	call   80103d32 <release>
}
80103421:	83 c4 10             	add    $0x10,%esp
80103424:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103427:	c9                   	leave  
80103428:	c3                   	ret    
    panic("userinit: out of memory?");
80103429:	83 ec 0c             	sub    $0xc,%esp
8010342c:	68 6c 6b 10 80       	push   $0x80106b6c
80103431:	e8 12 cf ff ff       	call   80100348 <panic>

80103436 <growproc>:
{
80103436:	55                   	push   %ebp
80103437:	89 e5                	mov    %esp,%ebp
80103439:	56                   	push   %esi
8010343a:	53                   	push   %ebx
8010343b:	8b 75 08             	mov    0x8(%ebp),%esi
  struct proc *curproc = myproc();
8010343e:	e8 e8 fe ff ff       	call   8010332b <myproc>
80103443:	89 c3                	mov    %eax,%ebx
  sz = curproc->sz;
80103445:	8b 00                	mov    (%eax),%eax
  if(n > 0){
80103447:	85 f6                	test   %esi,%esi
80103449:	7f 21                	jg     8010346c <growproc+0x36>
  } else if(n < 0){
8010344b:	85 f6                	test   %esi,%esi
8010344d:	79 33                	jns    80103482 <growproc+0x4c>
    if((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
8010344f:	83 ec 04             	sub    $0x4,%esp
80103452:	01 c6                	add    %eax,%esi
80103454:	56                   	push   %esi
80103455:	50                   	push   %eax
80103456:	ff 73 04             	pushl  0x4(%ebx)
80103459:	e8 40 2d 00 00       	call   8010619e <deallocuvm>
8010345e:	83 c4 10             	add    $0x10,%esp
80103461:	85 c0                	test   %eax,%eax
80103463:	75 1d                	jne    80103482 <growproc+0x4c>
      return -1;
80103465:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010346a:	eb 29                	jmp    80103495 <growproc+0x5f>
    if((sz = allocuvm(curproc->pgdir, sz, sz + n, curproc->pid)) == 0)
8010346c:	ff 73 10             	pushl  0x10(%ebx)
8010346f:	01 c6                	add    %eax,%esi
80103471:	56                   	push   %esi
80103472:	50                   	push   %eax
80103473:	ff 73 04             	pushl  0x4(%ebx)
80103476:	e8 b5 2d 00 00       	call   80106230 <allocuvm>
8010347b:	83 c4 10             	add    $0x10,%esp
8010347e:	85 c0                	test   %eax,%eax
80103480:	74 1a                	je     8010349c <growproc+0x66>
  curproc->sz = sz;
80103482:	89 03                	mov    %eax,(%ebx)
  switchuvm(curproc);
80103484:	83 ec 0c             	sub    $0xc,%esp
80103487:	53                   	push   %ebx
80103488:	e8 eb 2a 00 00       	call   80105f78 <switchuvm>
  return 0;
8010348d:	83 c4 10             	add    $0x10,%esp
80103490:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103495:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103498:	5b                   	pop    %ebx
80103499:	5e                   	pop    %esi
8010349a:	5d                   	pop    %ebp
8010349b:	c3                   	ret    
      return -1;
8010349c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801034a1:	eb f2                	jmp    80103495 <growproc+0x5f>

801034a3 <fork>:
{
801034a3:	55                   	push   %ebp
801034a4:	89 e5                	mov    %esp,%ebp
801034a6:	57                   	push   %edi
801034a7:	56                   	push   %esi
801034a8:	53                   	push   %ebx
801034a9:	83 ec 1c             	sub    $0x1c,%esp
  struct proc *curproc = myproc();
801034ac:	e8 7a fe ff ff       	call   8010332b <myproc>
801034b1:	89 c3                	mov    %eax,%ebx
  if((np = allocproc()) == 0){
801034b3:	e8 d8 fc ff ff       	call   80103190 <allocproc>
801034b8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801034bb:	85 c0                	test   %eax,%eax
801034bd:	0f 84 e3 00 00 00    	je     801035a6 <fork+0x103>
801034c3:	89 c7                	mov    %eax,%edi
  if((np->pgdir = copyuvm(curproc->pgdir, curproc->sz, np->pid)) == 0){
801034c5:	83 ec 04             	sub    $0x4,%esp
801034c8:	ff 70 10             	pushl  0x10(%eax)
801034cb:	ff 33                	pushl  (%ebx)
801034cd:	ff 73 04             	pushl  0x4(%ebx)
801034d0:	e8 77 2f 00 00       	call   8010644c <copyuvm>
801034d5:	89 47 04             	mov    %eax,0x4(%edi)
801034d8:	83 c4 10             	add    $0x10,%esp
801034db:	85 c0                	test   %eax,%eax
801034dd:	74 2a                	je     80103509 <fork+0x66>
  np->sz = curproc->sz;
801034df:	8b 03                	mov    (%ebx),%eax
801034e1:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801034e4:	89 01                	mov    %eax,(%ecx)
  np->parent = curproc;
801034e6:	89 c8                	mov    %ecx,%eax
801034e8:	89 59 14             	mov    %ebx,0x14(%ecx)
  *np->tf = *curproc->tf;
801034eb:	8b 73 18             	mov    0x18(%ebx),%esi
801034ee:	8b 79 18             	mov    0x18(%ecx),%edi
801034f1:	b9 13 00 00 00       	mov    $0x13,%ecx
801034f6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  np->tf->eax = 0;
801034f8:	8b 40 18             	mov    0x18(%eax),%eax
801034fb:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
  for(i = 0; i < NOFILE; i++)
80103502:	be 00 00 00 00       	mov    $0x0,%esi
80103507:	eb 29                	jmp    80103532 <fork+0x8f>
    kfree(np->kstack);
80103509:	83 ec 0c             	sub    $0xc,%esp
8010350c:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
8010350f:	ff 73 08             	pushl  0x8(%ebx)
80103512:	e8 99 ea ff ff       	call   80101fb0 <kfree>
    np->kstack = 0;
80103517:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
    np->state = UNUSED;
8010351e:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return -1;
80103525:	83 c4 10             	add    $0x10,%esp
80103528:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
8010352d:	eb 6d                	jmp    8010359c <fork+0xf9>
  for(i = 0; i < NOFILE; i++)
8010352f:	83 c6 01             	add    $0x1,%esi
80103532:	83 fe 0f             	cmp    $0xf,%esi
80103535:	7f 1d                	jg     80103554 <fork+0xb1>
    if(curproc->ofile[i])
80103537:	8b 44 b3 28          	mov    0x28(%ebx,%esi,4),%eax
8010353b:	85 c0                	test   %eax,%eax
8010353d:	74 f0                	je     8010352f <fork+0x8c>
      np->ofile[i] = filedup(curproc->ofile[i]);
8010353f:	83 ec 0c             	sub    $0xc,%esp
80103542:	50                   	push   %eax
80103543:	e8 52 d7 ff ff       	call   80100c9a <filedup>
80103548:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010354b:	89 44 b2 28          	mov    %eax,0x28(%edx,%esi,4)
8010354f:	83 c4 10             	add    $0x10,%esp
80103552:	eb db                	jmp    8010352f <fork+0x8c>
  np->cwd = idup(curproc->cwd);
80103554:	83 ec 0c             	sub    $0xc,%esp
80103557:	ff 73 68             	pushl  0x68(%ebx)
8010355a:	e8 fe df ff ff       	call   8010155d <idup>
8010355f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
80103562:	89 47 68             	mov    %eax,0x68(%edi)
  safestrcpy(np->name, curproc->name, sizeof(curproc->name));
80103565:	83 c3 6c             	add    $0x6c,%ebx
80103568:	8d 47 6c             	lea    0x6c(%edi),%eax
8010356b:	83 c4 0c             	add    $0xc,%esp
8010356e:	6a 10                	push   $0x10
80103570:	53                   	push   %ebx
80103571:	50                   	push   %eax
80103572:	e8 69 09 00 00       	call   80103ee0 <safestrcpy>
  pid = np->pid;
80103577:	8b 5f 10             	mov    0x10(%edi),%ebx
  acquire(&ptable.lock);
8010357a:	c7 04 24 40 1d 19 80 	movl   $0x80191d40,(%esp)
80103581:	e8 47 07 00 00       	call   80103ccd <acquire>
  np->state = RUNNABLE;
80103586:	c7 47 0c 03 00 00 00 	movl   $0x3,0xc(%edi)
  release(&ptable.lock);
8010358d:	c7 04 24 40 1d 19 80 	movl   $0x80191d40,(%esp)
80103594:	e8 99 07 00 00       	call   80103d32 <release>
  return pid;
80103599:	83 c4 10             	add    $0x10,%esp
}
8010359c:	89 d8                	mov    %ebx,%eax
8010359e:	8d 65 f4             	lea    -0xc(%ebp),%esp
801035a1:	5b                   	pop    %ebx
801035a2:	5e                   	pop    %esi
801035a3:	5f                   	pop    %edi
801035a4:	5d                   	pop    %ebp
801035a5:	c3                   	ret    
    return -1;
801035a6:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801035ab:	eb ef                	jmp    8010359c <fork+0xf9>

801035ad <scheduler>:
{
801035ad:	55                   	push   %ebp
801035ae:	89 e5                	mov    %esp,%ebp
801035b0:	56                   	push   %esi
801035b1:	53                   	push   %ebx
  struct cpu *c = mycpu();
801035b2:	e8 fd fc ff ff       	call   801032b4 <mycpu>
801035b7:	89 c6                	mov    %eax,%esi
  c->proc = 0;
801035b9:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
801035c0:	00 00 00 
801035c3:	eb 5a                	jmp    8010361f <scheduler+0x72>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801035c5:	83 c3 7c             	add    $0x7c,%ebx
801035c8:	81 fb 74 3c 19 80    	cmp    $0x80193c74,%ebx
801035ce:	73 3f                	jae    8010360f <scheduler+0x62>
      if(p->state != RUNNABLE)
801035d0:	83 7b 0c 03          	cmpl   $0x3,0xc(%ebx)
801035d4:	75 ef                	jne    801035c5 <scheduler+0x18>
      c->proc = p;
801035d6:	89 9e ac 00 00 00    	mov    %ebx,0xac(%esi)
      switchuvm(p);
801035dc:	83 ec 0c             	sub    $0xc,%esp
801035df:	53                   	push   %ebx
801035e0:	e8 93 29 00 00       	call   80105f78 <switchuvm>
      p->state = RUNNING;
801035e5:	c7 43 0c 04 00 00 00 	movl   $0x4,0xc(%ebx)
      swtch(&(c->scheduler), p->context);
801035ec:	83 c4 08             	add    $0x8,%esp
801035ef:	ff 73 1c             	pushl  0x1c(%ebx)
801035f2:	8d 46 04             	lea    0x4(%esi),%eax
801035f5:	50                   	push   %eax
801035f6:	e8 38 09 00 00       	call   80103f33 <swtch>
      switchkvm();
801035fb:	e8 66 29 00 00       	call   80105f66 <switchkvm>
      c->proc = 0;
80103600:	c7 86 ac 00 00 00 00 	movl   $0x0,0xac(%esi)
80103607:	00 00 00 
8010360a:	83 c4 10             	add    $0x10,%esp
8010360d:	eb b6                	jmp    801035c5 <scheduler+0x18>
    release(&ptable.lock);
8010360f:	83 ec 0c             	sub    $0xc,%esp
80103612:	68 40 1d 19 80       	push   $0x80191d40
80103617:	e8 16 07 00 00       	call   80103d32 <release>
    sti();
8010361c:	83 c4 10             	add    $0x10,%esp
  asm volatile("sti");
8010361f:	fb                   	sti    
    acquire(&ptable.lock);
80103620:	83 ec 0c             	sub    $0xc,%esp
80103623:	68 40 1d 19 80       	push   $0x80191d40
80103628:	e8 a0 06 00 00       	call   80103ccd <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010362d:	83 c4 10             	add    $0x10,%esp
80103630:	bb 74 1d 19 80       	mov    $0x80191d74,%ebx
80103635:	eb 91                	jmp    801035c8 <scheduler+0x1b>

80103637 <sched>:
{
80103637:	55                   	push   %ebp
80103638:	89 e5                	mov    %esp,%ebp
8010363a:	56                   	push   %esi
8010363b:	53                   	push   %ebx
  struct proc *p = myproc();
8010363c:	e8 ea fc ff ff       	call   8010332b <myproc>
80103641:	89 c3                	mov    %eax,%ebx
  if(!holding(&ptable.lock))
80103643:	83 ec 0c             	sub    $0xc,%esp
80103646:	68 40 1d 19 80       	push   $0x80191d40
8010364b:	e8 3d 06 00 00       	call   80103c8d <holding>
80103650:	83 c4 10             	add    $0x10,%esp
80103653:	85 c0                	test   %eax,%eax
80103655:	74 4f                	je     801036a6 <sched+0x6f>
  if(mycpu()->ncli != 1)
80103657:	e8 58 fc ff ff       	call   801032b4 <mycpu>
8010365c:	83 b8 a4 00 00 00 01 	cmpl   $0x1,0xa4(%eax)
80103663:	75 4e                	jne    801036b3 <sched+0x7c>
  if(p->state == RUNNING)
80103665:	83 7b 0c 04          	cmpl   $0x4,0xc(%ebx)
80103669:	74 55                	je     801036c0 <sched+0x89>
  asm volatile("pushfl; popl %0" : "=r" (eflags));
8010366b:	9c                   	pushf  
8010366c:	58                   	pop    %eax
  if(readeflags()&FL_IF)
8010366d:	f6 c4 02             	test   $0x2,%ah
80103670:	75 5b                	jne    801036cd <sched+0x96>
  intena = mycpu()->intena;
80103672:	e8 3d fc ff ff       	call   801032b4 <mycpu>
80103677:	8b b0 a8 00 00 00    	mov    0xa8(%eax),%esi
  swtch(&p->context, mycpu()->scheduler);
8010367d:	e8 32 fc ff ff       	call   801032b4 <mycpu>
80103682:	83 ec 08             	sub    $0x8,%esp
80103685:	ff 70 04             	pushl  0x4(%eax)
80103688:	83 c3 1c             	add    $0x1c,%ebx
8010368b:	53                   	push   %ebx
8010368c:	e8 a2 08 00 00       	call   80103f33 <swtch>
  mycpu()->intena = intena;
80103691:	e8 1e fc ff ff       	call   801032b4 <mycpu>
80103696:	89 b0 a8 00 00 00    	mov    %esi,0xa8(%eax)
}
8010369c:	83 c4 10             	add    $0x10,%esp
8010369f:	8d 65 f8             	lea    -0x8(%ebp),%esp
801036a2:	5b                   	pop    %ebx
801036a3:	5e                   	pop    %esi
801036a4:	5d                   	pop    %ebp
801036a5:	c3                   	ret    
    panic("sched ptable.lock");
801036a6:	83 ec 0c             	sub    $0xc,%esp
801036a9:	68 90 6b 10 80       	push   $0x80106b90
801036ae:	e8 95 cc ff ff       	call   80100348 <panic>
    panic("sched locks");
801036b3:	83 ec 0c             	sub    $0xc,%esp
801036b6:	68 a2 6b 10 80       	push   $0x80106ba2
801036bb:	e8 88 cc ff ff       	call   80100348 <panic>
    panic("sched running");
801036c0:	83 ec 0c             	sub    $0xc,%esp
801036c3:	68 ae 6b 10 80       	push   $0x80106bae
801036c8:	e8 7b cc ff ff       	call   80100348 <panic>
    panic("sched interruptible");
801036cd:	83 ec 0c             	sub    $0xc,%esp
801036d0:	68 bc 6b 10 80       	push   $0x80106bbc
801036d5:	e8 6e cc ff ff       	call   80100348 <panic>

801036da <exit>:
{
801036da:	55                   	push   %ebp
801036db:	89 e5                	mov    %esp,%ebp
801036dd:	56                   	push   %esi
801036de:	53                   	push   %ebx
  struct proc *curproc = myproc();
801036df:	e8 47 fc ff ff       	call   8010332b <myproc>
  if(curproc == initproc)
801036e4:	39 05 b8 95 10 80    	cmp    %eax,0x801095b8
801036ea:	74 09                	je     801036f5 <exit+0x1b>
801036ec:	89 c6                	mov    %eax,%esi
  for(fd = 0; fd < NOFILE; fd++){
801036ee:	bb 00 00 00 00       	mov    $0x0,%ebx
801036f3:	eb 10                	jmp    80103705 <exit+0x2b>
    panic("init exiting");
801036f5:	83 ec 0c             	sub    $0xc,%esp
801036f8:	68 d0 6b 10 80       	push   $0x80106bd0
801036fd:	e8 46 cc ff ff       	call   80100348 <panic>
  for(fd = 0; fd < NOFILE; fd++){
80103702:	83 c3 01             	add    $0x1,%ebx
80103705:	83 fb 0f             	cmp    $0xf,%ebx
80103708:	7f 1e                	jg     80103728 <exit+0x4e>
    if(curproc->ofile[fd]){
8010370a:	8b 44 9e 28          	mov    0x28(%esi,%ebx,4),%eax
8010370e:	85 c0                	test   %eax,%eax
80103710:	74 f0                	je     80103702 <exit+0x28>
      fileclose(curproc->ofile[fd]);
80103712:	83 ec 0c             	sub    $0xc,%esp
80103715:	50                   	push   %eax
80103716:	e8 c4 d5 ff ff       	call   80100cdf <fileclose>
      curproc->ofile[fd] = 0;
8010371b:	c7 44 9e 28 00 00 00 	movl   $0x0,0x28(%esi,%ebx,4)
80103722:	00 
80103723:	83 c4 10             	add    $0x10,%esp
80103726:	eb da                	jmp    80103702 <exit+0x28>
  begin_op();
80103728:	e8 a3 f1 ff ff       	call   801028d0 <begin_op>
  iput(curproc->cwd);
8010372d:	83 ec 0c             	sub    $0xc,%esp
80103730:	ff 76 68             	pushl  0x68(%esi)
80103733:	e8 5c df ff ff       	call   80101694 <iput>
  end_op();
80103738:	e8 0d f2 ff ff       	call   8010294a <end_op>
  curproc->cwd = 0;
8010373d:	c7 46 68 00 00 00 00 	movl   $0x0,0x68(%esi)
  acquire(&ptable.lock);
80103744:	c7 04 24 40 1d 19 80 	movl   $0x80191d40,(%esp)
8010374b:	e8 7d 05 00 00       	call   80103ccd <acquire>
  wakeup1(curproc->parent);
80103750:	8b 46 14             	mov    0x14(%esi),%eax
80103753:	e8 0d fa ff ff       	call   80103165 <wakeup1>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103758:	83 c4 10             	add    $0x10,%esp
8010375b:	bb 74 1d 19 80       	mov    $0x80191d74,%ebx
80103760:	eb 03                	jmp    80103765 <exit+0x8b>
80103762:	83 c3 7c             	add    $0x7c,%ebx
80103765:	81 fb 74 3c 19 80    	cmp    $0x80193c74,%ebx
8010376b:	73 1a                	jae    80103787 <exit+0xad>
    if(p->parent == curproc){
8010376d:	39 73 14             	cmp    %esi,0x14(%ebx)
80103770:	75 f0                	jne    80103762 <exit+0x88>
      p->parent = initproc;
80103772:	a1 b8 95 10 80       	mov    0x801095b8,%eax
80103777:	89 43 14             	mov    %eax,0x14(%ebx)
      if(p->state == ZOMBIE)
8010377a:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
8010377e:	75 e2                	jne    80103762 <exit+0x88>
        wakeup1(initproc);
80103780:	e8 e0 f9 ff ff       	call   80103165 <wakeup1>
80103785:	eb db                	jmp    80103762 <exit+0x88>
  curproc->state = ZOMBIE;
80103787:	c7 46 0c 05 00 00 00 	movl   $0x5,0xc(%esi)
  sched();
8010378e:	e8 a4 fe ff ff       	call   80103637 <sched>
  panic("zombie exit");
80103793:	83 ec 0c             	sub    $0xc,%esp
80103796:	68 dd 6b 10 80       	push   $0x80106bdd
8010379b:	e8 a8 cb ff ff       	call   80100348 <panic>

801037a0 <yield>:
{
801037a0:	55                   	push   %ebp
801037a1:	89 e5                	mov    %esp,%ebp
801037a3:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
801037a6:	68 40 1d 19 80       	push   $0x80191d40
801037ab:	e8 1d 05 00 00       	call   80103ccd <acquire>
  myproc()->state = RUNNABLE;
801037b0:	e8 76 fb ff ff       	call   8010332b <myproc>
801037b5:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
801037bc:	e8 76 fe ff ff       	call   80103637 <sched>
  release(&ptable.lock);
801037c1:	c7 04 24 40 1d 19 80 	movl   $0x80191d40,(%esp)
801037c8:	e8 65 05 00 00       	call   80103d32 <release>
}
801037cd:	83 c4 10             	add    $0x10,%esp
801037d0:	c9                   	leave  
801037d1:	c3                   	ret    

801037d2 <sleep>:
{
801037d2:	55                   	push   %ebp
801037d3:	89 e5                	mov    %esp,%ebp
801037d5:	56                   	push   %esi
801037d6:	53                   	push   %ebx
801037d7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  struct proc *p = myproc();
801037da:	e8 4c fb ff ff       	call   8010332b <myproc>
  if(p == 0)
801037df:	85 c0                	test   %eax,%eax
801037e1:	74 66                	je     80103849 <sleep+0x77>
801037e3:	89 c6                	mov    %eax,%esi
  if(lk == 0)
801037e5:	85 db                	test   %ebx,%ebx
801037e7:	74 6d                	je     80103856 <sleep+0x84>
  if(lk != &ptable.lock){  //DOC: sleeplock0
801037e9:	81 fb 40 1d 19 80    	cmp    $0x80191d40,%ebx
801037ef:	74 18                	je     80103809 <sleep+0x37>
    acquire(&ptable.lock);  //DOC: sleeplock1
801037f1:	83 ec 0c             	sub    $0xc,%esp
801037f4:	68 40 1d 19 80       	push   $0x80191d40
801037f9:	e8 cf 04 00 00       	call   80103ccd <acquire>
    release(lk);
801037fe:	89 1c 24             	mov    %ebx,(%esp)
80103801:	e8 2c 05 00 00       	call   80103d32 <release>
80103806:	83 c4 10             	add    $0x10,%esp
  p->chan = chan;
80103809:	8b 45 08             	mov    0x8(%ebp),%eax
8010380c:	89 46 20             	mov    %eax,0x20(%esi)
  p->state = SLEEPING;
8010380f:	c7 46 0c 02 00 00 00 	movl   $0x2,0xc(%esi)
  sched();
80103816:	e8 1c fe ff ff       	call   80103637 <sched>
  p->chan = 0;
8010381b:	c7 46 20 00 00 00 00 	movl   $0x0,0x20(%esi)
  if(lk != &ptable.lock){  //DOC: sleeplock2
80103822:	81 fb 40 1d 19 80    	cmp    $0x80191d40,%ebx
80103828:	74 18                	je     80103842 <sleep+0x70>
    release(&ptable.lock);
8010382a:	83 ec 0c             	sub    $0xc,%esp
8010382d:	68 40 1d 19 80       	push   $0x80191d40
80103832:	e8 fb 04 00 00       	call   80103d32 <release>
    acquire(lk);
80103837:	89 1c 24             	mov    %ebx,(%esp)
8010383a:	e8 8e 04 00 00       	call   80103ccd <acquire>
8010383f:	83 c4 10             	add    $0x10,%esp
}
80103842:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103845:	5b                   	pop    %ebx
80103846:	5e                   	pop    %esi
80103847:	5d                   	pop    %ebp
80103848:	c3                   	ret    
    panic("sleep");
80103849:	83 ec 0c             	sub    $0xc,%esp
8010384c:	68 e9 6b 10 80       	push   $0x80106be9
80103851:	e8 f2 ca ff ff       	call   80100348 <panic>
    panic("sleep without lk");
80103856:	83 ec 0c             	sub    $0xc,%esp
80103859:	68 ef 6b 10 80       	push   $0x80106bef
8010385e:	e8 e5 ca ff ff       	call   80100348 <panic>

80103863 <wait>:
{
80103863:	55                   	push   %ebp
80103864:	89 e5                	mov    %esp,%ebp
80103866:	56                   	push   %esi
80103867:	53                   	push   %ebx
  struct proc *curproc = myproc();
80103868:	e8 be fa ff ff       	call   8010332b <myproc>
8010386d:	89 c6                	mov    %eax,%esi
  acquire(&ptable.lock);
8010386f:	83 ec 0c             	sub    $0xc,%esp
80103872:	68 40 1d 19 80       	push   $0x80191d40
80103877:	e8 51 04 00 00       	call   80103ccd <acquire>
8010387c:	83 c4 10             	add    $0x10,%esp
    havekids = 0;
8010387f:	b8 00 00 00 00       	mov    $0x0,%eax
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103884:	bb 74 1d 19 80       	mov    $0x80191d74,%ebx
80103889:	eb 5b                	jmp    801038e6 <wait+0x83>
        pid = p->pid;
8010388b:	8b 73 10             	mov    0x10(%ebx),%esi
        kfree(p->kstack);
8010388e:	83 ec 0c             	sub    $0xc,%esp
80103891:	ff 73 08             	pushl  0x8(%ebx)
80103894:	e8 17 e7 ff ff       	call   80101fb0 <kfree>
        p->kstack = 0;
80103899:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        freevm(p->pgdir);
801038a0:	83 c4 04             	add    $0x4,%esp
801038a3:	ff 73 04             	pushl  0x4(%ebx)
801038a6:	e8 78 2a 00 00       	call   80106323 <freevm>
        p->pid = 0;
801038ab:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
        p->parent = 0;
801038b2:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
        p->name[0] = 0;
801038b9:	c6 43 6c 00          	movb   $0x0,0x6c(%ebx)
        p->killed = 0;
801038bd:	c7 43 24 00 00 00 00 	movl   $0x0,0x24(%ebx)
        p->state = UNUSED;
801038c4:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        release(&ptable.lock);
801038cb:	c7 04 24 40 1d 19 80 	movl   $0x80191d40,(%esp)
801038d2:	e8 5b 04 00 00       	call   80103d32 <release>
        return pid;
801038d7:	83 c4 10             	add    $0x10,%esp
}
801038da:	89 f0                	mov    %esi,%eax
801038dc:	8d 65 f8             	lea    -0x8(%ebp),%esp
801038df:	5b                   	pop    %ebx
801038e0:	5e                   	pop    %esi
801038e1:	5d                   	pop    %ebp
801038e2:	c3                   	ret    
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801038e3:	83 c3 7c             	add    $0x7c,%ebx
801038e6:	81 fb 74 3c 19 80    	cmp    $0x80193c74,%ebx
801038ec:	73 12                	jae    80103900 <wait+0x9d>
      if(p->parent != curproc)
801038ee:	39 73 14             	cmp    %esi,0x14(%ebx)
801038f1:	75 f0                	jne    801038e3 <wait+0x80>
      if(p->state == ZOMBIE){
801038f3:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
801038f7:	74 92                	je     8010388b <wait+0x28>
      havekids = 1;
801038f9:	b8 01 00 00 00       	mov    $0x1,%eax
801038fe:	eb e3                	jmp    801038e3 <wait+0x80>
    if(!havekids || curproc->killed){
80103900:	85 c0                	test   %eax,%eax
80103902:	74 06                	je     8010390a <wait+0xa7>
80103904:	83 7e 24 00          	cmpl   $0x0,0x24(%esi)
80103908:	74 17                	je     80103921 <wait+0xbe>
      release(&ptable.lock);
8010390a:	83 ec 0c             	sub    $0xc,%esp
8010390d:	68 40 1d 19 80       	push   $0x80191d40
80103912:	e8 1b 04 00 00       	call   80103d32 <release>
      return -1;
80103917:	83 c4 10             	add    $0x10,%esp
8010391a:	be ff ff ff ff       	mov    $0xffffffff,%esi
8010391f:	eb b9                	jmp    801038da <wait+0x77>
    sleep(curproc, &ptable.lock);  //DOC: wait-sleep
80103921:	83 ec 08             	sub    $0x8,%esp
80103924:	68 40 1d 19 80       	push   $0x80191d40
80103929:	56                   	push   %esi
8010392a:	e8 a3 fe ff ff       	call   801037d2 <sleep>
    havekids = 0;
8010392f:	83 c4 10             	add    $0x10,%esp
80103932:	e9 48 ff ff ff       	jmp    8010387f <wait+0x1c>

80103937 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80103937:	55                   	push   %ebp
80103938:	89 e5                	mov    %esp,%ebp
8010393a:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);
8010393d:	68 40 1d 19 80       	push   $0x80191d40
80103942:	e8 86 03 00 00       	call   80103ccd <acquire>
  wakeup1(chan);
80103947:	8b 45 08             	mov    0x8(%ebp),%eax
8010394a:	e8 16 f8 ff ff       	call   80103165 <wakeup1>
  release(&ptable.lock);
8010394f:	c7 04 24 40 1d 19 80 	movl   $0x80191d40,(%esp)
80103956:	e8 d7 03 00 00       	call   80103d32 <release>
}
8010395b:	83 c4 10             	add    $0x10,%esp
8010395e:	c9                   	leave  
8010395f:	c3                   	ret    

80103960 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80103960:	55                   	push   %ebp
80103961:	89 e5                	mov    %esp,%ebp
80103963:	53                   	push   %ebx
80103964:	83 ec 10             	sub    $0x10,%esp
80103967:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *p;

  acquire(&ptable.lock);
8010396a:	68 40 1d 19 80       	push   $0x80191d40
8010396f:	e8 59 03 00 00       	call   80103ccd <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103974:	83 c4 10             	add    $0x10,%esp
80103977:	b8 74 1d 19 80       	mov    $0x80191d74,%eax
8010397c:	3d 74 3c 19 80       	cmp    $0x80193c74,%eax
80103981:	73 3a                	jae    801039bd <kill+0x5d>
    if(p->pid == pid){
80103983:	39 58 10             	cmp    %ebx,0x10(%eax)
80103986:	74 05                	je     8010398d <kill+0x2d>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103988:	83 c0 7c             	add    $0x7c,%eax
8010398b:	eb ef                	jmp    8010397c <kill+0x1c>
      p->killed = 1;
8010398d:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80103994:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
80103998:	74 1a                	je     801039b4 <kill+0x54>
        p->state = RUNNABLE;
      release(&ptable.lock);
8010399a:	83 ec 0c             	sub    $0xc,%esp
8010399d:	68 40 1d 19 80       	push   $0x80191d40
801039a2:	e8 8b 03 00 00       	call   80103d32 <release>
      return 0;
801039a7:	83 c4 10             	add    $0x10,%esp
801039aa:	b8 00 00 00 00       	mov    $0x0,%eax
    }
  }
  release(&ptable.lock);
  return -1;
}
801039af:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801039b2:	c9                   	leave  
801039b3:	c3                   	ret    
        p->state = RUNNABLE;
801039b4:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
801039bb:	eb dd                	jmp    8010399a <kill+0x3a>
  release(&ptable.lock);
801039bd:	83 ec 0c             	sub    $0xc,%esp
801039c0:	68 40 1d 19 80       	push   $0x80191d40
801039c5:	e8 68 03 00 00       	call   80103d32 <release>
  return -1;
801039ca:	83 c4 10             	add    $0x10,%esp
801039cd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801039d2:	eb db                	jmp    801039af <kill+0x4f>

801039d4 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
801039d4:	55                   	push   %ebp
801039d5:	89 e5                	mov    %esp,%ebp
801039d7:	56                   	push   %esi
801039d8:	53                   	push   %ebx
801039d9:	83 ec 30             	sub    $0x30,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801039dc:	bb 74 1d 19 80       	mov    $0x80191d74,%ebx
801039e1:	eb 33                	jmp    80103a16 <procdump+0x42>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
801039e3:	b8 00 6c 10 80       	mov    $0x80106c00,%eax
    cprintf("%d %s %s", p->pid, state, p->name);
801039e8:	8d 53 6c             	lea    0x6c(%ebx),%edx
801039eb:	52                   	push   %edx
801039ec:	50                   	push   %eax
801039ed:	ff 73 10             	pushl  0x10(%ebx)
801039f0:	68 04 6c 10 80       	push   $0x80106c04
801039f5:	e8 11 cc ff ff       	call   8010060b <cprintf>
    if(p->state == SLEEPING){
801039fa:	83 c4 10             	add    $0x10,%esp
801039fd:	83 7b 0c 02          	cmpl   $0x2,0xc(%ebx)
80103a01:	74 39                	je     80103a3c <procdump+0x68>
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80103a03:	83 ec 0c             	sub    $0xc,%esp
80103a06:	68 7b 6f 10 80       	push   $0x80106f7b
80103a0b:	e8 fb cb ff ff       	call   8010060b <cprintf>
80103a10:	83 c4 10             	add    $0x10,%esp
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103a13:	83 c3 7c             	add    $0x7c,%ebx
80103a16:	81 fb 74 3c 19 80    	cmp    $0x80193c74,%ebx
80103a1c:	73 61                	jae    80103a7f <procdump+0xab>
    if(p->state == UNUSED)
80103a1e:	8b 43 0c             	mov    0xc(%ebx),%eax
80103a21:	85 c0                	test   %eax,%eax
80103a23:	74 ee                	je     80103a13 <procdump+0x3f>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80103a25:	83 f8 05             	cmp    $0x5,%eax
80103a28:	77 b9                	ja     801039e3 <procdump+0xf>
80103a2a:	8b 04 85 60 6c 10 80 	mov    -0x7fef93a0(,%eax,4),%eax
80103a31:	85 c0                	test   %eax,%eax
80103a33:	75 b3                	jne    801039e8 <procdump+0x14>
      state = "???";
80103a35:	b8 00 6c 10 80       	mov    $0x80106c00,%eax
80103a3a:	eb ac                	jmp    801039e8 <procdump+0x14>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80103a3c:	8b 43 1c             	mov    0x1c(%ebx),%eax
80103a3f:	8b 40 0c             	mov    0xc(%eax),%eax
80103a42:	83 c0 08             	add    $0x8,%eax
80103a45:	83 ec 08             	sub    $0x8,%esp
80103a48:	8d 55 d0             	lea    -0x30(%ebp),%edx
80103a4b:	52                   	push   %edx
80103a4c:	50                   	push   %eax
80103a4d:	e8 5a 01 00 00       	call   80103bac <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80103a52:	83 c4 10             	add    $0x10,%esp
80103a55:	be 00 00 00 00       	mov    $0x0,%esi
80103a5a:	eb 14                	jmp    80103a70 <procdump+0x9c>
        cprintf(" %p", pc[i]);
80103a5c:	83 ec 08             	sub    $0x8,%esp
80103a5f:	50                   	push   %eax
80103a60:	68 41 66 10 80       	push   $0x80106641
80103a65:	e8 a1 cb ff ff       	call   8010060b <cprintf>
      for(i=0; i<10 && pc[i] != 0; i++)
80103a6a:	83 c6 01             	add    $0x1,%esi
80103a6d:	83 c4 10             	add    $0x10,%esp
80103a70:	83 fe 09             	cmp    $0x9,%esi
80103a73:	7f 8e                	jg     80103a03 <procdump+0x2f>
80103a75:	8b 44 b5 d0          	mov    -0x30(%ebp,%esi,4),%eax
80103a79:	85 c0                	test   %eax,%eax
80103a7b:	75 df                	jne    80103a5c <procdump+0x88>
80103a7d:	eb 84                	jmp    80103a03 <procdump+0x2f>
  }
}
80103a7f:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103a82:	5b                   	pop    %ebx
80103a83:	5e                   	pop    %esi
80103a84:	5d                   	pop    %ebp
80103a85:	c3                   	ret    

80103a86 <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
80103a86:	55                   	push   %ebp
80103a87:	89 e5                	mov    %esp,%ebp
80103a89:	53                   	push   %ebx
80103a8a:	83 ec 0c             	sub    $0xc,%esp
80103a8d:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&lk->lk, "sleep lock");
80103a90:	68 78 6c 10 80       	push   $0x80106c78
80103a95:	8d 43 04             	lea    0x4(%ebx),%eax
80103a98:	50                   	push   %eax
80103a99:	e8 f3 00 00 00       	call   80103b91 <initlock>
  lk->name = name;
80103a9e:	8b 45 0c             	mov    0xc(%ebp),%eax
80103aa1:	89 43 38             	mov    %eax,0x38(%ebx)
  lk->locked = 0;
80103aa4:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103aaa:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
}
80103ab1:	83 c4 10             	add    $0x10,%esp
80103ab4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103ab7:	c9                   	leave  
80103ab8:	c3                   	ret    

80103ab9 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80103ab9:	55                   	push   %ebp
80103aba:	89 e5                	mov    %esp,%ebp
80103abc:	56                   	push   %esi
80103abd:	53                   	push   %ebx
80103abe:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103ac1:	8d 73 04             	lea    0x4(%ebx),%esi
80103ac4:	83 ec 0c             	sub    $0xc,%esp
80103ac7:	56                   	push   %esi
80103ac8:	e8 00 02 00 00       	call   80103ccd <acquire>
  while (lk->locked) {
80103acd:	83 c4 10             	add    $0x10,%esp
80103ad0:	eb 0d                	jmp    80103adf <acquiresleep+0x26>
    sleep(lk, &lk->lk);
80103ad2:	83 ec 08             	sub    $0x8,%esp
80103ad5:	56                   	push   %esi
80103ad6:	53                   	push   %ebx
80103ad7:	e8 f6 fc ff ff       	call   801037d2 <sleep>
80103adc:	83 c4 10             	add    $0x10,%esp
  while (lk->locked) {
80103adf:	83 3b 00             	cmpl   $0x0,(%ebx)
80103ae2:	75 ee                	jne    80103ad2 <acquiresleep+0x19>
  }
  lk->locked = 1;
80103ae4:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
  lk->pid = myproc()->pid;
80103aea:	e8 3c f8 ff ff       	call   8010332b <myproc>
80103aef:	8b 40 10             	mov    0x10(%eax),%eax
80103af2:	89 43 3c             	mov    %eax,0x3c(%ebx)
  release(&lk->lk);
80103af5:	83 ec 0c             	sub    $0xc,%esp
80103af8:	56                   	push   %esi
80103af9:	e8 34 02 00 00       	call   80103d32 <release>
}
80103afe:	83 c4 10             	add    $0x10,%esp
80103b01:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103b04:	5b                   	pop    %ebx
80103b05:	5e                   	pop    %esi
80103b06:	5d                   	pop    %ebp
80103b07:	c3                   	ret    

80103b08 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80103b08:	55                   	push   %ebp
80103b09:	89 e5                	mov    %esp,%ebp
80103b0b:	56                   	push   %esi
80103b0c:	53                   	push   %ebx
80103b0d:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103b10:	8d 73 04             	lea    0x4(%ebx),%esi
80103b13:	83 ec 0c             	sub    $0xc,%esp
80103b16:	56                   	push   %esi
80103b17:	e8 b1 01 00 00       	call   80103ccd <acquire>
  lk->locked = 0;
80103b1c:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103b22:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
  wakeup(lk);
80103b29:	89 1c 24             	mov    %ebx,(%esp)
80103b2c:	e8 06 fe ff ff       	call   80103937 <wakeup>
  release(&lk->lk);
80103b31:	89 34 24             	mov    %esi,(%esp)
80103b34:	e8 f9 01 00 00       	call   80103d32 <release>
}
80103b39:	83 c4 10             	add    $0x10,%esp
80103b3c:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103b3f:	5b                   	pop    %ebx
80103b40:	5e                   	pop    %esi
80103b41:	5d                   	pop    %ebp
80103b42:	c3                   	ret    

80103b43 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80103b43:	55                   	push   %ebp
80103b44:	89 e5                	mov    %esp,%ebp
80103b46:	56                   	push   %esi
80103b47:	53                   	push   %ebx
80103b48:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;
  
  acquire(&lk->lk);
80103b4b:	8d 73 04             	lea    0x4(%ebx),%esi
80103b4e:	83 ec 0c             	sub    $0xc,%esp
80103b51:	56                   	push   %esi
80103b52:	e8 76 01 00 00       	call   80103ccd <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
80103b57:	83 c4 10             	add    $0x10,%esp
80103b5a:	83 3b 00             	cmpl   $0x0,(%ebx)
80103b5d:	75 17                	jne    80103b76 <holdingsleep+0x33>
80103b5f:	bb 00 00 00 00       	mov    $0x0,%ebx
  release(&lk->lk);
80103b64:	83 ec 0c             	sub    $0xc,%esp
80103b67:	56                   	push   %esi
80103b68:	e8 c5 01 00 00       	call   80103d32 <release>
  return r;
}
80103b6d:	89 d8                	mov    %ebx,%eax
80103b6f:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103b72:	5b                   	pop    %ebx
80103b73:	5e                   	pop    %esi
80103b74:	5d                   	pop    %ebp
80103b75:	c3                   	ret    
  r = lk->locked && (lk->pid == myproc()->pid);
80103b76:	8b 5b 3c             	mov    0x3c(%ebx),%ebx
80103b79:	e8 ad f7 ff ff       	call   8010332b <myproc>
80103b7e:	3b 58 10             	cmp    0x10(%eax),%ebx
80103b81:	74 07                	je     80103b8a <holdingsleep+0x47>
80103b83:	bb 00 00 00 00       	mov    $0x0,%ebx
80103b88:	eb da                	jmp    80103b64 <holdingsleep+0x21>
80103b8a:	bb 01 00 00 00       	mov    $0x1,%ebx
80103b8f:	eb d3                	jmp    80103b64 <holdingsleep+0x21>

80103b91 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80103b91:	55                   	push   %ebp
80103b92:	89 e5                	mov    %esp,%ebp
80103b94:	8b 45 08             	mov    0x8(%ebp),%eax
  lk->name = name;
80103b97:	8b 55 0c             	mov    0xc(%ebp),%edx
80103b9a:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80103b9d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80103ba3:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80103baa:	5d                   	pop    %ebp
80103bab:	c3                   	ret    

80103bac <getcallerpcs>:
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80103bac:	55                   	push   %ebp
80103bad:	89 e5                	mov    %esp,%ebp
80103baf:	53                   	push   %ebx
80103bb0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80103bb3:	8b 45 08             	mov    0x8(%ebp),%eax
80103bb6:	8d 50 f8             	lea    -0x8(%eax),%edx
  for(i = 0; i < 10; i++){
80103bb9:	b8 00 00 00 00       	mov    $0x0,%eax
80103bbe:	83 f8 09             	cmp    $0x9,%eax
80103bc1:	7f 25                	jg     80103be8 <getcallerpcs+0x3c>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80103bc3:	8d 9a 00 00 00 80    	lea    -0x80000000(%edx),%ebx
80103bc9:	81 fb fe ff ff 7f    	cmp    $0x7ffffffe,%ebx
80103bcf:	77 17                	ja     80103be8 <getcallerpcs+0x3c>
      break;
    pcs[i] = ebp[1];     // saved %eip
80103bd1:	8b 5a 04             	mov    0x4(%edx),%ebx
80103bd4:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
    ebp = (uint*)ebp[0]; // saved %ebp
80103bd7:	8b 12                	mov    (%edx),%edx
  for(i = 0; i < 10; i++){
80103bd9:	83 c0 01             	add    $0x1,%eax
80103bdc:	eb e0                	jmp    80103bbe <getcallerpcs+0x12>
  }
  for(; i < 10; i++)
    pcs[i] = 0;
80103bde:	c7 04 81 00 00 00 00 	movl   $0x0,(%ecx,%eax,4)
  for(; i < 10; i++)
80103be5:	83 c0 01             	add    $0x1,%eax
80103be8:	83 f8 09             	cmp    $0x9,%eax
80103beb:	7e f1                	jle    80103bde <getcallerpcs+0x32>
}
80103bed:	5b                   	pop    %ebx
80103bee:	5d                   	pop    %ebp
80103bef:	c3                   	ret    

80103bf0 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80103bf0:	55                   	push   %ebp
80103bf1:	89 e5                	mov    %esp,%ebp
80103bf3:	53                   	push   %ebx
80103bf4:	83 ec 04             	sub    $0x4,%esp
80103bf7:	9c                   	pushf  
80103bf8:	5b                   	pop    %ebx
  asm volatile("cli");
80103bf9:	fa                   	cli    
  int eflags;

  eflags = readeflags();
  cli();
  if(mycpu()->ncli == 0)
80103bfa:	e8 b5 f6 ff ff       	call   801032b4 <mycpu>
80103bff:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103c06:	74 12                	je     80103c1a <pushcli+0x2a>
    mycpu()->intena = eflags & FL_IF;
  mycpu()->ncli += 1;
80103c08:	e8 a7 f6 ff ff       	call   801032b4 <mycpu>
80103c0d:	83 80 a4 00 00 00 01 	addl   $0x1,0xa4(%eax)
}
80103c14:	83 c4 04             	add    $0x4,%esp
80103c17:	5b                   	pop    %ebx
80103c18:	5d                   	pop    %ebp
80103c19:	c3                   	ret    
    mycpu()->intena = eflags & FL_IF;
80103c1a:	e8 95 f6 ff ff       	call   801032b4 <mycpu>
80103c1f:	81 e3 00 02 00 00    	and    $0x200,%ebx
80103c25:	89 98 a8 00 00 00    	mov    %ebx,0xa8(%eax)
80103c2b:	eb db                	jmp    80103c08 <pushcli+0x18>

80103c2d <popcli>:

void
popcli(void)
{
80103c2d:	55                   	push   %ebp
80103c2e:	89 e5                	mov    %esp,%ebp
80103c30:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103c33:	9c                   	pushf  
80103c34:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103c35:	f6 c4 02             	test   $0x2,%ah
80103c38:	75 28                	jne    80103c62 <popcli+0x35>
    panic("popcli - interruptible");
  if(--mycpu()->ncli < 0)
80103c3a:	e8 75 f6 ff ff       	call   801032b4 <mycpu>
80103c3f:	8b 88 a4 00 00 00    	mov    0xa4(%eax),%ecx
80103c45:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103c48:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
80103c4e:	85 d2                	test   %edx,%edx
80103c50:	78 1d                	js     80103c6f <popcli+0x42>
    panic("popcli");
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103c52:	e8 5d f6 ff ff       	call   801032b4 <mycpu>
80103c57:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103c5e:	74 1c                	je     80103c7c <popcli+0x4f>
    sti();
}
80103c60:	c9                   	leave  
80103c61:	c3                   	ret    
    panic("popcli - interruptible");
80103c62:	83 ec 0c             	sub    $0xc,%esp
80103c65:	68 83 6c 10 80       	push   $0x80106c83
80103c6a:	e8 d9 c6 ff ff       	call   80100348 <panic>
    panic("popcli");
80103c6f:	83 ec 0c             	sub    $0xc,%esp
80103c72:	68 9a 6c 10 80       	push   $0x80106c9a
80103c77:	e8 cc c6 ff ff       	call   80100348 <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103c7c:	e8 33 f6 ff ff       	call   801032b4 <mycpu>
80103c81:	83 b8 a8 00 00 00 00 	cmpl   $0x0,0xa8(%eax)
80103c88:	74 d6                	je     80103c60 <popcli+0x33>
  asm volatile("sti");
80103c8a:	fb                   	sti    
}
80103c8b:	eb d3                	jmp    80103c60 <popcli+0x33>

80103c8d <holding>:
{
80103c8d:	55                   	push   %ebp
80103c8e:	89 e5                	mov    %esp,%ebp
80103c90:	53                   	push   %ebx
80103c91:	83 ec 04             	sub    $0x4,%esp
80103c94:	8b 5d 08             	mov    0x8(%ebp),%ebx
  pushcli();
80103c97:	e8 54 ff ff ff       	call   80103bf0 <pushcli>
  r = lock->locked && lock->cpu == mycpu();
80103c9c:	83 3b 00             	cmpl   $0x0,(%ebx)
80103c9f:	75 12                	jne    80103cb3 <holding+0x26>
80103ca1:	bb 00 00 00 00       	mov    $0x0,%ebx
  popcli();
80103ca6:	e8 82 ff ff ff       	call   80103c2d <popcli>
}
80103cab:	89 d8                	mov    %ebx,%eax
80103cad:	83 c4 04             	add    $0x4,%esp
80103cb0:	5b                   	pop    %ebx
80103cb1:	5d                   	pop    %ebp
80103cb2:	c3                   	ret    
  r = lock->locked && lock->cpu == mycpu();
80103cb3:	8b 5b 08             	mov    0x8(%ebx),%ebx
80103cb6:	e8 f9 f5 ff ff       	call   801032b4 <mycpu>
80103cbb:	39 c3                	cmp    %eax,%ebx
80103cbd:	74 07                	je     80103cc6 <holding+0x39>
80103cbf:	bb 00 00 00 00       	mov    $0x0,%ebx
80103cc4:	eb e0                	jmp    80103ca6 <holding+0x19>
80103cc6:	bb 01 00 00 00       	mov    $0x1,%ebx
80103ccb:	eb d9                	jmp    80103ca6 <holding+0x19>

80103ccd <acquire>:
{
80103ccd:	55                   	push   %ebp
80103cce:	89 e5                	mov    %esp,%ebp
80103cd0:	53                   	push   %ebx
80103cd1:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80103cd4:	e8 17 ff ff ff       	call   80103bf0 <pushcli>
  if(holding(lk))
80103cd9:	83 ec 0c             	sub    $0xc,%esp
80103cdc:	ff 75 08             	pushl  0x8(%ebp)
80103cdf:	e8 a9 ff ff ff       	call   80103c8d <holding>
80103ce4:	83 c4 10             	add    $0x10,%esp
80103ce7:	85 c0                	test   %eax,%eax
80103ce9:	75 3a                	jne    80103d25 <acquire+0x58>
  while(xchg(&lk->locked, 1) != 0)
80103ceb:	8b 55 08             	mov    0x8(%ebp),%edx
  asm volatile("lock; xchgl %0, %1" :
80103cee:	b8 01 00 00 00       	mov    $0x1,%eax
80103cf3:	f0 87 02             	lock xchg %eax,(%edx)
80103cf6:	85 c0                	test   %eax,%eax
80103cf8:	75 f1                	jne    80103ceb <acquire+0x1e>
  __sync_synchronize();
80103cfa:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  lk->cpu = mycpu();
80103cff:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103d02:	e8 ad f5 ff ff       	call   801032b4 <mycpu>
80103d07:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
80103d0a:	8b 45 08             	mov    0x8(%ebp),%eax
80103d0d:	83 c0 0c             	add    $0xc,%eax
80103d10:	83 ec 08             	sub    $0x8,%esp
80103d13:	50                   	push   %eax
80103d14:	8d 45 08             	lea    0x8(%ebp),%eax
80103d17:	50                   	push   %eax
80103d18:	e8 8f fe ff ff       	call   80103bac <getcallerpcs>
}
80103d1d:	83 c4 10             	add    $0x10,%esp
80103d20:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103d23:	c9                   	leave  
80103d24:	c3                   	ret    
    panic("acquire");
80103d25:	83 ec 0c             	sub    $0xc,%esp
80103d28:	68 a1 6c 10 80       	push   $0x80106ca1
80103d2d:	e8 16 c6 ff ff       	call   80100348 <panic>

80103d32 <release>:
{
80103d32:	55                   	push   %ebp
80103d33:	89 e5                	mov    %esp,%ebp
80103d35:	53                   	push   %ebx
80103d36:	83 ec 10             	sub    $0x10,%esp
80103d39:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holding(lk))
80103d3c:	53                   	push   %ebx
80103d3d:	e8 4b ff ff ff       	call   80103c8d <holding>
80103d42:	83 c4 10             	add    $0x10,%esp
80103d45:	85 c0                	test   %eax,%eax
80103d47:	74 23                	je     80103d6c <release+0x3a>
  lk->pcs[0] = 0;
80103d49:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
  lk->cpu = 0;
80103d50:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
  __sync_synchronize();
80103d57:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
80103d5c:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  popcli();
80103d62:	e8 c6 fe ff ff       	call   80103c2d <popcli>
}
80103d67:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103d6a:	c9                   	leave  
80103d6b:	c3                   	ret    
    panic("release");
80103d6c:	83 ec 0c             	sub    $0xc,%esp
80103d6f:	68 a9 6c 10 80       	push   $0x80106ca9
80103d74:	e8 cf c5 ff ff       	call   80100348 <panic>

80103d79 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80103d79:	55                   	push   %ebp
80103d7a:	89 e5                	mov    %esp,%ebp
80103d7c:	57                   	push   %edi
80103d7d:	53                   	push   %ebx
80103d7e:	8b 55 08             	mov    0x8(%ebp),%edx
80103d81:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if ((int)dst%4 == 0 && n%4 == 0){
80103d84:	f6 c2 03             	test   $0x3,%dl
80103d87:	75 05                	jne    80103d8e <memset+0x15>
80103d89:	f6 c1 03             	test   $0x3,%cl
80103d8c:	74 0e                	je     80103d9c <memset+0x23>
  asm volatile("cld; rep stosb" :
80103d8e:	89 d7                	mov    %edx,%edi
80103d90:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d93:	fc                   	cld    
80103d94:	f3 aa                	rep stos %al,%es:(%edi)
    c &= 0xFF;
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
  } else
    stosb(dst, c, n);
  return dst;
}
80103d96:	89 d0                	mov    %edx,%eax
80103d98:	5b                   	pop    %ebx
80103d99:	5f                   	pop    %edi
80103d9a:	5d                   	pop    %ebp
80103d9b:	c3                   	ret    
    c &= 0xFF;
80103d9c:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80103da0:	c1 e9 02             	shr    $0x2,%ecx
80103da3:	89 f8                	mov    %edi,%eax
80103da5:	c1 e0 18             	shl    $0x18,%eax
80103da8:	89 fb                	mov    %edi,%ebx
80103daa:	c1 e3 10             	shl    $0x10,%ebx
80103dad:	09 d8                	or     %ebx,%eax
80103daf:	89 fb                	mov    %edi,%ebx
80103db1:	c1 e3 08             	shl    $0x8,%ebx
80103db4:	09 d8                	or     %ebx,%eax
80103db6:	09 f8                	or     %edi,%eax
  asm volatile("cld; rep stosl" :
80103db8:	89 d7                	mov    %edx,%edi
80103dba:	fc                   	cld    
80103dbb:	f3 ab                	rep stos %eax,%es:(%edi)
80103dbd:	eb d7                	jmp    80103d96 <memset+0x1d>

80103dbf <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80103dbf:	55                   	push   %ebp
80103dc0:	89 e5                	mov    %esp,%ebp
80103dc2:	56                   	push   %esi
80103dc3:	53                   	push   %ebx
80103dc4:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103dc7:	8b 55 0c             	mov    0xc(%ebp),%edx
80103dca:	8b 45 10             	mov    0x10(%ebp),%eax
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80103dcd:	8d 70 ff             	lea    -0x1(%eax),%esi
80103dd0:	85 c0                	test   %eax,%eax
80103dd2:	74 1c                	je     80103df0 <memcmp+0x31>
    if(*s1 != *s2)
80103dd4:	0f b6 01             	movzbl (%ecx),%eax
80103dd7:	0f b6 1a             	movzbl (%edx),%ebx
80103dda:	38 d8                	cmp    %bl,%al
80103ddc:	75 0a                	jne    80103de8 <memcmp+0x29>
      return *s1 - *s2;
    s1++, s2++;
80103dde:	83 c1 01             	add    $0x1,%ecx
80103de1:	83 c2 01             	add    $0x1,%edx
  while(n-- > 0){
80103de4:	89 f0                	mov    %esi,%eax
80103de6:	eb e5                	jmp    80103dcd <memcmp+0xe>
      return *s1 - *s2;
80103de8:	0f b6 c0             	movzbl %al,%eax
80103deb:	0f b6 db             	movzbl %bl,%ebx
80103dee:	29 d8                	sub    %ebx,%eax
  }

  return 0;
}
80103df0:	5b                   	pop    %ebx
80103df1:	5e                   	pop    %esi
80103df2:	5d                   	pop    %ebp
80103df3:	c3                   	ret    

80103df4 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80103df4:	55                   	push   %ebp
80103df5:	89 e5                	mov    %esp,%ebp
80103df7:	56                   	push   %esi
80103df8:	53                   	push   %ebx
80103df9:	8b 45 08             	mov    0x8(%ebp),%eax
80103dfc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103dff:	8b 55 10             	mov    0x10(%ebp),%edx
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80103e02:	39 c1                	cmp    %eax,%ecx
80103e04:	73 3a                	jae    80103e40 <memmove+0x4c>
80103e06:	8d 1c 11             	lea    (%ecx,%edx,1),%ebx
80103e09:	39 c3                	cmp    %eax,%ebx
80103e0b:	76 37                	jbe    80103e44 <memmove+0x50>
    s += n;
    d += n;
80103e0d:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
    while(n-- > 0)
80103e10:	eb 0d                	jmp    80103e1f <memmove+0x2b>
      *--d = *--s;
80103e12:	83 eb 01             	sub    $0x1,%ebx
80103e15:	83 e9 01             	sub    $0x1,%ecx
80103e18:	0f b6 13             	movzbl (%ebx),%edx
80103e1b:	88 11                	mov    %dl,(%ecx)
    while(n-- > 0)
80103e1d:	89 f2                	mov    %esi,%edx
80103e1f:	8d 72 ff             	lea    -0x1(%edx),%esi
80103e22:	85 d2                	test   %edx,%edx
80103e24:	75 ec                	jne    80103e12 <memmove+0x1e>
80103e26:	eb 14                	jmp    80103e3c <memmove+0x48>
  } else
    while(n-- > 0)
      *d++ = *s++;
80103e28:	0f b6 11             	movzbl (%ecx),%edx
80103e2b:	88 13                	mov    %dl,(%ebx)
80103e2d:	8d 5b 01             	lea    0x1(%ebx),%ebx
80103e30:	8d 49 01             	lea    0x1(%ecx),%ecx
    while(n-- > 0)
80103e33:	89 f2                	mov    %esi,%edx
80103e35:	8d 72 ff             	lea    -0x1(%edx),%esi
80103e38:	85 d2                	test   %edx,%edx
80103e3a:	75 ec                	jne    80103e28 <memmove+0x34>

  return dst;
}
80103e3c:	5b                   	pop    %ebx
80103e3d:	5e                   	pop    %esi
80103e3e:	5d                   	pop    %ebp
80103e3f:	c3                   	ret    
80103e40:	89 c3                	mov    %eax,%ebx
80103e42:	eb f1                	jmp    80103e35 <memmove+0x41>
80103e44:	89 c3                	mov    %eax,%ebx
80103e46:	eb ed                	jmp    80103e35 <memmove+0x41>

80103e48 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80103e48:	55                   	push   %ebp
80103e49:	89 e5                	mov    %esp,%ebp
  return memmove(dst, src, n);
80103e4b:	ff 75 10             	pushl  0x10(%ebp)
80103e4e:	ff 75 0c             	pushl  0xc(%ebp)
80103e51:	ff 75 08             	pushl  0x8(%ebp)
80103e54:	e8 9b ff ff ff       	call   80103df4 <memmove>
}
80103e59:	c9                   	leave  
80103e5a:	c3                   	ret    

80103e5b <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80103e5b:	55                   	push   %ebp
80103e5c:	89 e5                	mov    %esp,%ebp
80103e5e:	53                   	push   %ebx
80103e5f:	8b 55 08             	mov    0x8(%ebp),%edx
80103e62:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103e65:	8b 45 10             	mov    0x10(%ebp),%eax
  while(n > 0 && *p && *p == *q)
80103e68:	eb 09                	jmp    80103e73 <strncmp+0x18>
    n--, p++, q++;
80103e6a:	83 e8 01             	sub    $0x1,%eax
80103e6d:	83 c2 01             	add    $0x1,%edx
80103e70:	83 c1 01             	add    $0x1,%ecx
  while(n > 0 && *p && *p == *q)
80103e73:	85 c0                	test   %eax,%eax
80103e75:	74 0b                	je     80103e82 <strncmp+0x27>
80103e77:	0f b6 1a             	movzbl (%edx),%ebx
80103e7a:	84 db                	test   %bl,%bl
80103e7c:	74 04                	je     80103e82 <strncmp+0x27>
80103e7e:	3a 19                	cmp    (%ecx),%bl
80103e80:	74 e8                	je     80103e6a <strncmp+0xf>
  if(n == 0)
80103e82:	85 c0                	test   %eax,%eax
80103e84:	74 0b                	je     80103e91 <strncmp+0x36>
    return 0;
  return (uchar)*p - (uchar)*q;
80103e86:	0f b6 02             	movzbl (%edx),%eax
80103e89:	0f b6 11             	movzbl (%ecx),%edx
80103e8c:	29 d0                	sub    %edx,%eax
}
80103e8e:	5b                   	pop    %ebx
80103e8f:	5d                   	pop    %ebp
80103e90:	c3                   	ret    
    return 0;
80103e91:	b8 00 00 00 00       	mov    $0x0,%eax
80103e96:	eb f6                	jmp    80103e8e <strncmp+0x33>

80103e98 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80103e98:	55                   	push   %ebp
80103e99:	89 e5                	mov    %esp,%ebp
80103e9b:	57                   	push   %edi
80103e9c:	56                   	push   %esi
80103e9d:	53                   	push   %ebx
80103e9e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103ea1:	8b 4d 10             	mov    0x10(%ebp),%ecx
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
80103ea4:	8b 45 08             	mov    0x8(%ebp),%eax
80103ea7:	eb 04                	jmp    80103ead <strncpy+0x15>
80103ea9:	89 fb                	mov    %edi,%ebx
80103eab:	89 f0                	mov    %esi,%eax
80103ead:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103eb0:	85 c9                	test   %ecx,%ecx
80103eb2:	7e 1d                	jle    80103ed1 <strncpy+0x39>
80103eb4:	8d 7b 01             	lea    0x1(%ebx),%edi
80103eb7:	8d 70 01             	lea    0x1(%eax),%esi
80103eba:	0f b6 1b             	movzbl (%ebx),%ebx
80103ebd:	88 18                	mov    %bl,(%eax)
80103ebf:	89 d1                	mov    %edx,%ecx
80103ec1:	84 db                	test   %bl,%bl
80103ec3:	75 e4                	jne    80103ea9 <strncpy+0x11>
80103ec5:	89 f0                	mov    %esi,%eax
80103ec7:	eb 08                	jmp    80103ed1 <strncpy+0x39>
    ;
  while(n-- > 0)
    *s++ = 0;
80103ec9:	c6 00 00             	movb   $0x0,(%eax)
  while(n-- > 0)
80103ecc:	89 ca                	mov    %ecx,%edx
    *s++ = 0;
80103ece:	8d 40 01             	lea    0x1(%eax),%eax
  while(n-- > 0)
80103ed1:	8d 4a ff             	lea    -0x1(%edx),%ecx
80103ed4:	85 d2                	test   %edx,%edx
80103ed6:	7f f1                	jg     80103ec9 <strncpy+0x31>
  return os;
}
80103ed8:	8b 45 08             	mov    0x8(%ebp),%eax
80103edb:	5b                   	pop    %ebx
80103edc:	5e                   	pop    %esi
80103edd:	5f                   	pop    %edi
80103ede:	5d                   	pop    %ebp
80103edf:	c3                   	ret    

80103ee0 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80103ee0:	55                   	push   %ebp
80103ee1:	89 e5                	mov    %esp,%ebp
80103ee3:	57                   	push   %edi
80103ee4:	56                   	push   %esi
80103ee5:	53                   	push   %ebx
80103ee6:	8b 45 08             	mov    0x8(%ebp),%eax
80103ee9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103eec:	8b 55 10             	mov    0x10(%ebp),%edx
  char *os;

  os = s;
  if(n <= 0)
80103eef:	85 d2                	test   %edx,%edx
80103ef1:	7e 23                	jle    80103f16 <safestrcpy+0x36>
80103ef3:	89 c1                	mov    %eax,%ecx
80103ef5:	eb 04                	jmp    80103efb <safestrcpy+0x1b>
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
80103ef7:	89 fb                	mov    %edi,%ebx
80103ef9:	89 f1                	mov    %esi,%ecx
80103efb:	83 ea 01             	sub    $0x1,%edx
80103efe:	85 d2                	test   %edx,%edx
80103f00:	7e 11                	jle    80103f13 <safestrcpy+0x33>
80103f02:	8d 7b 01             	lea    0x1(%ebx),%edi
80103f05:	8d 71 01             	lea    0x1(%ecx),%esi
80103f08:	0f b6 1b             	movzbl (%ebx),%ebx
80103f0b:	88 19                	mov    %bl,(%ecx)
80103f0d:	84 db                	test   %bl,%bl
80103f0f:	75 e6                	jne    80103ef7 <safestrcpy+0x17>
80103f11:	89 f1                	mov    %esi,%ecx
    ;
  *s = 0;
80103f13:	c6 01 00             	movb   $0x0,(%ecx)
  return os;
}
80103f16:	5b                   	pop    %ebx
80103f17:	5e                   	pop    %esi
80103f18:	5f                   	pop    %edi
80103f19:	5d                   	pop    %ebp
80103f1a:	c3                   	ret    

80103f1b <strlen>:

int
strlen(const char *s)
{
80103f1b:	55                   	push   %ebp
80103f1c:	89 e5                	mov    %esp,%ebp
80103f1e:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
80103f21:	b8 00 00 00 00       	mov    $0x0,%eax
80103f26:	eb 03                	jmp    80103f2b <strlen+0x10>
80103f28:	83 c0 01             	add    $0x1,%eax
80103f2b:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
80103f2f:	75 f7                	jne    80103f28 <strlen+0xd>
    ;
  return n;
}
80103f31:	5d                   	pop    %ebp
80103f32:	c3                   	ret    

80103f33 <swtch>:
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax
80103f33:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80103f37:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-saved registers
  pushl %ebp
80103f3b:	55                   	push   %ebp
  pushl %ebx
80103f3c:	53                   	push   %ebx
  pushl %esi
80103f3d:	56                   	push   %esi
  pushl %edi
80103f3e:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80103f3f:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80103f41:	89 d4                	mov    %edx,%esp

  # Load new callee-saved registers
  popl %edi
80103f43:	5f                   	pop    %edi
  popl %esi
80103f44:	5e                   	pop    %esi
  popl %ebx
80103f45:	5b                   	pop    %ebx
  popl %ebp
80103f46:	5d                   	pop    %ebp
  ret
80103f47:	c3                   	ret    

80103f48 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80103f48:	55                   	push   %ebp
80103f49:	89 e5                	mov    %esp,%ebp
80103f4b:	53                   	push   %ebx
80103f4c:	83 ec 04             	sub    $0x4,%esp
80103f4f:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *curproc = myproc();
80103f52:	e8 d4 f3 ff ff       	call   8010332b <myproc>

  if(addr >= curproc->sz || addr+4 > curproc->sz)
80103f57:	8b 00                	mov    (%eax),%eax
80103f59:	39 d8                	cmp    %ebx,%eax
80103f5b:	76 19                	jbe    80103f76 <fetchint+0x2e>
80103f5d:	8d 53 04             	lea    0x4(%ebx),%edx
80103f60:	39 d0                	cmp    %edx,%eax
80103f62:	72 19                	jb     80103f7d <fetchint+0x35>
    return -1;
  *ip = *(int*)(addr);
80103f64:	8b 13                	mov    (%ebx),%edx
80103f66:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f69:	89 10                	mov    %edx,(%eax)
  return 0;
80103f6b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103f70:	83 c4 04             	add    $0x4,%esp
80103f73:	5b                   	pop    %ebx
80103f74:	5d                   	pop    %ebp
80103f75:	c3                   	ret    
    return -1;
80103f76:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f7b:	eb f3                	jmp    80103f70 <fetchint+0x28>
80103f7d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f82:	eb ec                	jmp    80103f70 <fetchint+0x28>

80103f84 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80103f84:	55                   	push   %ebp
80103f85:	89 e5                	mov    %esp,%ebp
80103f87:	53                   	push   %ebx
80103f88:	83 ec 04             	sub    $0x4,%esp
80103f8b:	8b 5d 08             	mov    0x8(%ebp),%ebx
  char *s, *ep;
  struct proc *curproc = myproc();
80103f8e:	e8 98 f3 ff ff       	call   8010332b <myproc>

  if(addr >= curproc->sz)
80103f93:	39 18                	cmp    %ebx,(%eax)
80103f95:	76 26                	jbe    80103fbd <fetchstr+0x39>
    return -1;
  *pp = (char*)addr;
80103f97:	8b 55 0c             	mov    0xc(%ebp),%edx
80103f9a:	89 1a                	mov    %ebx,(%edx)
  ep = (char*)curproc->sz;
80103f9c:	8b 10                	mov    (%eax),%edx
  for(s = *pp; s < ep; s++){
80103f9e:	89 d8                	mov    %ebx,%eax
80103fa0:	39 d0                	cmp    %edx,%eax
80103fa2:	73 0e                	jae    80103fb2 <fetchstr+0x2e>
    if(*s == 0)
80103fa4:	80 38 00             	cmpb   $0x0,(%eax)
80103fa7:	74 05                	je     80103fae <fetchstr+0x2a>
  for(s = *pp; s < ep; s++){
80103fa9:	83 c0 01             	add    $0x1,%eax
80103fac:	eb f2                	jmp    80103fa0 <fetchstr+0x1c>
      return s - *pp;
80103fae:	29 d8                	sub    %ebx,%eax
80103fb0:	eb 05                	jmp    80103fb7 <fetchstr+0x33>
  }
  return -1;
80103fb2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80103fb7:	83 c4 04             	add    $0x4,%esp
80103fba:	5b                   	pop    %ebx
80103fbb:	5d                   	pop    %ebp
80103fbc:	c3                   	ret    
    return -1;
80103fbd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103fc2:	eb f3                	jmp    80103fb7 <fetchstr+0x33>

80103fc4 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80103fc4:	55                   	push   %ebp
80103fc5:	89 e5                	mov    %esp,%ebp
80103fc7:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
80103fca:	e8 5c f3 ff ff       	call   8010332b <myproc>
80103fcf:	8b 50 18             	mov    0x18(%eax),%edx
80103fd2:	8b 45 08             	mov    0x8(%ebp),%eax
80103fd5:	c1 e0 02             	shl    $0x2,%eax
80103fd8:	03 42 44             	add    0x44(%edx),%eax
80103fdb:	83 ec 08             	sub    $0x8,%esp
80103fde:	ff 75 0c             	pushl  0xc(%ebp)
80103fe1:	83 c0 04             	add    $0x4,%eax
80103fe4:	50                   	push   %eax
80103fe5:	e8 5e ff ff ff       	call   80103f48 <fetchint>
}
80103fea:	c9                   	leave  
80103feb:	c3                   	ret    

80103fec <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80103fec:	55                   	push   %ebp
80103fed:	89 e5                	mov    %esp,%ebp
80103fef:	56                   	push   %esi
80103ff0:	53                   	push   %ebx
80103ff1:	83 ec 10             	sub    $0x10,%esp
80103ff4:	8b 5d 10             	mov    0x10(%ebp),%ebx
  int i;
  struct proc *curproc = myproc();
80103ff7:	e8 2f f3 ff ff       	call   8010332b <myproc>
80103ffc:	89 c6                	mov    %eax,%esi
 
  if(argint(n, &i) < 0)
80103ffe:	83 ec 08             	sub    $0x8,%esp
80104001:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104004:	50                   	push   %eax
80104005:	ff 75 08             	pushl  0x8(%ebp)
80104008:	e8 b7 ff ff ff       	call   80103fc4 <argint>
8010400d:	83 c4 10             	add    $0x10,%esp
80104010:	85 c0                	test   %eax,%eax
80104012:	78 24                	js     80104038 <argptr+0x4c>
    return -1;
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
80104014:	85 db                	test   %ebx,%ebx
80104016:	78 27                	js     8010403f <argptr+0x53>
80104018:	8b 16                	mov    (%esi),%edx
8010401a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010401d:	39 c2                	cmp    %eax,%edx
8010401f:	76 25                	jbe    80104046 <argptr+0x5a>
80104021:	01 c3                	add    %eax,%ebx
80104023:	39 da                	cmp    %ebx,%edx
80104025:	72 26                	jb     8010404d <argptr+0x61>
    return -1;
  *pp = (char*)i;
80104027:	8b 55 0c             	mov    0xc(%ebp),%edx
8010402a:	89 02                	mov    %eax,(%edx)
  return 0;
8010402c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104031:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104034:	5b                   	pop    %ebx
80104035:	5e                   	pop    %esi
80104036:	5d                   	pop    %ebp
80104037:	c3                   	ret    
    return -1;
80104038:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010403d:	eb f2                	jmp    80104031 <argptr+0x45>
    return -1;
8010403f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104044:	eb eb                	jmp    80104031 <argptr+0x45>
80104046:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010404b:	eb e4                	jmp    80104031 <argptr+0x45>
8010404d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104052:	eb dd                	jmp    80104031 <argptr+0x45>

80104054 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80104054:	55                   	push   %ebp
80104055:	89 e5                	mov    %esp,%ebp
80104057:	83 ec 20             	sub    $0x20,%esp
  int addr;
  if(argint(n, &addr) < 0)
8010405a:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010405d:	50                   	push   %eax
8010405e:	ff 75 08             	pushl  0x8(%ebp)
80104061:	e8 5e ff ff ff       	call   80103fc4 <argint>
80104066:	83 c4 10             	add    $0x10,%esp
80104069:	85 c0                	test   %eax,%eax
8010406b:	78 13                	js     80104080 <argstr+0x2c>
    return -1;
  return fetchstr(addr, pp);
8010406d:	83 ec 08             	sub    $0x8,%esp
80104070:	ff 75 0c             	pushl  0xc(%ebp)
80104073:	ff 75 f4             	pushl  -0xc(%ebp)
80104076:	e8 09 ff ff ff       	call   80103f84 <fetchstr>
8010407b:	83 c4 10             	add    $0x10,%esp
}
8010407e:	c9                   	leave  
8010407f:	c3                   	ret    
    return -1;
80104080:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104085:	eb f7                	jmp    8010407e <argstr+0x2a>

80104087 <syscall>:
[SYS_dump_physmem] sys_dump_physmem,
};

void
syscall(void)
{
80104087:	55                   	push   %ebp
80104088:	89 e5                	mov    %esp,%ebp
8010408a:	53                   	push   %ebx
8010408b:	83 ec 04             	sub    $0x4,%esp
  int num;
  struct proc *curproc = myproc();
8010408e:	e8 98 f2 ff ff       	call   8010332b <myproc>
80104093:	89 c3                	mov    %eax,%ebx

  num = curproc->tf->eax;
80104095:	8b 40 18             	mov    0x18(%eax),%eax
80104098:	8b 40 1c             	mov    0x1c(%eax),%eax
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
8010409b:	8d 50 ff             	lea    -0x1(%eax),%edx
8010409e:	83 fa 15             	cmp    $0x15,%edx
801040a1:	77 18                	ja     801040bb <syscall+0x34>
801040a3:	8b 14 85 e0 6c 10 80 	mov    -0x7fef9320(,%eax,4),%edx
801040aa:	85 d2                	test   %edx,%edx
801040ac:	74 0d                	je     801040bb <syscall+0x34>
    curproc->tf->eax = syscalls[num]();
801040ae:	ff d2                	call   *%edx
801040b0:	8b 53 18             	mov    0x18(%ebx),%edx
801040b3:	89 42 1c             	mov    %eax,0x1c(%edx)
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
  }
}
801040b6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801040b9:	c9                   	leave  
801040ba:	c3                   	ret    
            curproc->pid, curproc->name, num);
801040bb:	8d 53 6c             	lea    0x6c(%ebx),%edx
    cprintf("%d %s: unknown sys call %d\n",
801040be:	50                   	push   %eax
801040bf:	52                   	push   %edx
801040c0:	ff 73 10             	pushl  0x10(%ebx)
801040c3:	68 b1 6c 10 80       	push   $0x80106cb1
801040c8:	e8 3e c5 ff ff       	call   8010060b <cprintf>
    curproc->tf->eax = -1;
801040cd:	8b 43 18             	mov    0x18(%ebx),%eax
801040d0:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
801040d7:	83 c4 10             	add    $0x10,%esp
}
801040da:	eb da                	jmp    801040b6 <syscall+0x2f>

801040dc <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
801040dc:	55                   	push   %ebp
801040dd:	89 e5                	mov    %esp,%ebp
801040df:	56                   	push   %esi
801040e0:	53                   	push   %ebx
801040e1:	83 ec 18             	sub    $0x18,%esp
801040e4:	89 d6                	mov    %edx,%esi
801040e6:	89 cb                	mov    %ecx,%ebx
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
801040e8:	8d 55 f4             	lea    -0xc(%ebp),%edx
801040eb:	52                   	push   %edx
801040ec:	50                   	push   %eax
801040ed:	e8 d2 fe ff ff       	call   80103fc4 <argint>
801040f2:	83 c4 10             	add    $0x10,%esp
801040f5:	85 c0                	test   %eax,%eax
801040f7:	78 2e                	js     80104127 <argfd+0x4b>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
801040f9:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
801040fd:	77 2f                	ja     8010412e <argfd+0x52>
801040ff:	e8 27 f2 ff ff       	call   8010332b <myproc>
80104104:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104107:	8b 44 90 28          	mov    0x28(%eax,%edx,4),%eax
8010410b:	85 c0                	test   %eax,%eax
8010410d:	74 26                	je     80104135 <argfd+0x59>
    return -1;
  if(pfd)
8010410f:	85 f6                	test   %esi,%esi
80104111:	74 02                	je     80104115 <argfd+0x39>
    *pfd = fd;
80104113:	89 16                	mov    %edx,(%esi)
  if(pf)
80104115:	85 db                	test   %ebx,%ebx
80104117:	74 23                	je     8010413c <argfd+0x60>
    *pf = f;
80104119:	89 03                	mov    %eax,(%ebx)
  return 0;
8010411b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104120:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104123:	5b                   	pop    %ebx
80104124:	5e                   	pop    %esi
80104125:	5d                   	pop    %ebp
80104126:	c3                   	ret    
    return -1;
80104127:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010412c:	eb f2                	jmp    80104120 <argfd+0x44>
    return -1;
8010412e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104133:	eb eb                	jmp    80104120 <argfd+0x44>
80104135:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010413a:	eb e4                	jmp    80104120 <argfd+0x44>
  return 0;
8010413c:	b8 00 00 00 00       	mov    $0x0,%eax
80104141:	eb dd                	jmp    80104120 <argfd+0x44>

80104143 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80104143:	55                   	push   %ebp
80104144:	89 e5                	mov    %esp,%ebp
80104146:	53                   	push   %ebx
80104147:	83 ec 04             	sub    $0x4,%esp
8010414a:	89 c3                	mov    %eax,%ebx
  int fd;
  struct proc *curproc = myproc();
8010414c:	e8 da f1 ff ff       	call   8010332b <myproc>

  for(fd = 0; fd < NOFILE; fd++){
80104151:	ba 00 00 00 00       	mov    $0x0,%edx
80104156:	83 fa 0f             	cmp    $0xf,%edx
80104159:	7f 18                	jg     80104173 <fdalloc+0x30>
    if(curproc->ofile[fd] == 0){
8010415b:	83 7c 90 28 00       	cmpl   $0x0,0x28(%eax,%edx,4)
80104160:	74 05                	je     80104167 <fdalloc+0x24>
  for(fd = 0; fd < NOFILE; fd++){
80104162:	83 c2 01             	add    $0x1,%edx
80104165:	eb ef                	jmp    80104156 <fdalloc+0x13>
      curproc->ofile[fd] = f;
80104167:	89 5c 90 28          	mov    %ebx,0x28(%eax,%edx,4)
      return fd;
    }
  }
  return -1;
}
8010416b:	89 d0                	mov    %edx,%eax
8010416d:	83 c4 04             	add    $0x4,%esp
80104170:	5b                   	pop    %ebx
80104171:	5d                   	pop    %ebp
80104172:	c3                   	ret    
  return -1;
80104173:	ba ff ff ff ff       	mov    $0xffffffff,%edx
80104178:	eb f1                	jmp    8010416b <fdalloc+0x28>

8010417a <isdirempty>:
}

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
8010417a:	55                   	push   %ebp
8010417b:	89 e5                	mov    %esp,%ebp
8010417d:	56                   	push   %esi
8010417e:	53                   	push   %ebx
8010417f:	83 ec 10             	sub    $0x10,%esp
80104182:	89 c3                	mov    %eax,%ebx
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80104184:	b8 20 00 00 00       	mov    $0x20,%eax
80104189:	89 c6                	mov    %eax,%esi
8010418b:	39 43 58             	cmp    %eax,0x58(%ebx)
8010418e:	76 2e                	jbe    801041be <isdirempty+0x44>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80104190:	6a 10                	push   $0x10
80104192:	50                   	push   %eax
80104193:	8d 45 e8             	lea    -0x18(%ebp),%eax
80104196:	50                   	push   %eax
80104197:	53                   	push   %ebx
80104198:	e8 e2 d5 ff ff       	call   8010177f <readi>
8010419d:	83 c4 10             	add    $0x10,%esp
801041a0:	83 f8 10             	cmp    $0x10,%eax
801041a3:	75 0c                	jne    801041b1 <isdirempty+0x37>
      panic("isdirempty: readi");
    if(de.inum != 0)
801041a5:	66 83 7d e8 00       	cmpw   $0x0,-0x18(%ebp)
801041aa:	75 1e                	jne    801041ca <isdirempty+0x50>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801041ac:	8d 46 10             	lea    0x10(%esi),%eax
801041af:	eb d8                	jmp    80104189 <isdirempty+0xf>
      panic("isdirempty: readi");
801041b1:	83 ec 0c             	sub    $0xc,%esp
801041b4:	68 3c 6d 10 80       	push   $0x80106d3c
801041b9:	e8 8a c1 ff ff       	call   80100348 <panic>
      return 0;
  }
  return 1;
801041be:	b8 01 00 00 00       	mov    $0x1,%eax
}
801041c3:	8d 65 f8             	lea    -0x8(%ebp),%esp
801041c6:	5b                   	pop    %ebx
801041c7:	5e                   	pop    %esi
801041c8:	5d                   	pop    %ebp
801041c9:	c3                   	ret    
      return 0;
801041ca:	b8 00 00 00 00       	mov    $0x0,%eax
801041cf:	eb f2                	jmp    801041c3 <isdirempty+0x49>

801041d1 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
801041d1:	55                   	push   %ebp
801041d2:	89 e5                	mov    %esp,%ebp
801041d4:	57                   	push   %edi
801041d5:	56                   	push   %esi
801041d6:	53                   	push   %ebx
801041d7:	83 ec 44             	sub    $0x44,%esp
801041da:	89 55 c4             	mov    %edx,-0x3c(%ebp)
801041dd:	89 4d c0             	mov    %ecx,-0x40(%ebp)
801041e0:	8b 7d 08             	mov    0x8(%ebp),%edi
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
801041e3:	8d 55 d6             	lea    -0x2a(%ebp),%edx
801041e6:	52                   	push   %edx
801041e7:	50                   	push   %eax
801041e8:	e8 18 da ff ff       	call   80101c05 <nameiparent>
801041ed:	89 c6                	mov    %eax,%esi
801041ef:	83 c4 10             	add    $0x10,%esp
801041f2:	85 c0                	test   %eax,%eax
801041f4:	0f 84 3a 01 00 00    	je     80104334 <create+0x163>
    return 0;
  ilock(dp);
801041fa:	83 ec 0c             	sub    $0xc,%esp
801041fd:	50                   	push   %eax
801041fe:	e8 8a d3 ff ff       	call   8010158d <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80104203:	83 c4 0c             	add    $0xc,%esp
80104206:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104209:	50                   	push   %eax
8010420a:	8d 45 d6             	lea    -0x2a(%ebp),%eax
8010420d:	50                   	push   %eax
8010420e:	56                   	push   %esi
8010420f:	e8 a8 d7 ff ff       	call   801019bc <dirlookup>
80104214:	89 c3                	mov    %eax,%ebx
80104216:	83 c4 10             	add    $0x10,%esp
80104219:	85 c0                	test   %eax,%eax
8010421b:	74 3f                	je     8010425c <create+0x8b>
    iunlockput(dp);
8010421d:	83 ec 0c             	sub    $0xc,%esp
80104220:	56                   	push   %esi
80104221:	e8 0e d5 ff ff       	call   80101734 <iunlockput>
    ilock(ip);
80104226:	89 1c 24             	mov    %ebx,(%esp)
80104229:	e8 5f d3 ff ff       	call   8010158d <ilock>
    if(type == T_FILE && ip->type == T_FILE)
8010422e:	83 c4 10             	add    $0x10,%esp
80104231:	66 83 7d c4 02       	cmpw   $0x2,-0x3c(%ebp)
80104236:	75 11                	jne    80104249 <create+0x78>
80104238:	66 83 7b 50 02       	cmpw   $0x2,0x50(%ebx)
8010423d:	75 0a                	jne    80104249 <create+0x78>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
8010423f:	89 d8                	mov    %ebx,%eax
80104241:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104244:	5b                   	pop    %ebx
80104245:	5e                   	pop    %esi
80104246:	5f                   	pop    %edi
80104247:	5d                   	pop    %ebp
80104248:	c3                   	ret    
    iunlockput(ip);
80104249:	83 ec 0c             	sub    $0xc,%esp
8010424c:	53                   	push   %ebx
8010424d:	e8 e2 d4 ff ff       	call   80101734 <iunlockput>
    return 0;
80104252:	83 c4 10             	add    $0x10,%esp
80104255:	bb 00 00 00 00       	mov    $0x0,%ebx
8010425a:	eb e3                	jmp    8010423f <create+0x6e>
  if((ip = ialloc(dp->dev, type)) == 0)
8010425c:	0f bf 45 c4          	movswl -0x3c(%ebp),%eax
80104260:	83 ec 08             	sub    $0x8,%esp
80104263:	50                   	push   %eax
80104264:	ff 36                	pushl  (%esi)
80104266:	e8 1f d1 ff ff       	call   8010138a <ialloc>
8010426b:	89 c3                	mov    %eax,%ebx
8010426d:	83 c4 10             	add    $0x10,%esp
80104270:	85 c0                	test   %eax,%eax
80104272:	74 55                	je     801042c9 <create+0xf8>
  ilock(ip);
80104274:	83 ec 0c             	sub    $0xc,%esp
80104277:	50                   	push   %eax
80104278:	e8 10 d3 ff ff       	call   8010158d <ilock>
  ip->major = major;
8010427d:	0f b7 45 c0          	movzwl -0x40(%ebp),%eax
80104281:	66 89 43 52          	mov    %ax,0x52(%ebx)
  ip->minor = minor;
80104285:	66 89 7b 54          	mov    %di,0x54(%ebx)
  ip->nlink = 1;
80104289:	66 c7 43 56 01 00    	movw   $0x1,0x56(%ebx)
  iupdate(ip);
8010428f:	89 1c 24             	mov    %ebx,(%esp)
80104292:	e8 95 d1 ff ff       	call   8010142c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
80104297:	83 c4 10             	add    $0x10,%esp
8010429a:	66 83 7d c4 01       	cmpw   $0x1,-0x3c(%ebp)
8010429f:	74 35                	je     801042d6 <create+0x105>
  if(dirlink(dp, name, ip->inum) < 0)
801042a1:	83 ec 04             	sub    $0x4,%esp
801042a4:	ff 73 04             	pushl  0x4(%ebx)
801042a7:	8d 45 d6             	lea    -0x2a(%ebp),%eax
801042aa:	50                   	push   %eax
801042ab:	56                   	push   %esi
801042ac:	e8 8b d8 ff ff       	call   80101b3c <dirlink>
801042b1:	83 c4 10             	add    $0x10,%esp
801042b4:	85 c0                	test   %eax,%eax
801042b6:	78 6f                	js     80104327 <create+0x156>
  iunlockput(dp);
801042b8:	83 ec 0c             	sub    $0xc,%esp
801042bb:	56                   	push   %esi
801042bc:	e8 73 d4 ff ff       	call   80101734 <iunlockput>
  return ip;
801042c1:	83 c4 10             	add    $0x10,%esp
801042c4:	e9 76 ff ff ff       	jmp    8010423f <create+0x6e>
    panic("create: ialloc");
801042c9:	83 ec 0c             	sub    $0xc,%esp
801042cc:	68 4e 6d 10 80       	push   $0x80106d4e
801042d1:	e8 72 c0 ff ff       	call   80100348 <panic>
    dp->nlink++;  // for ".."
801042d6:	0f b7 46 56          	movzwl 0x56(%esi),%eax
801042da:	83 c0 01             	add    $0x1,%eax
801042dd:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
801042e1:	83 ec 0c             	sub    $0xc,%esp
801042e4:	56                   	push   %esi
801042e5:	e8 42 d1 ff ff       	call   8010142c <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
801042ea:	83 c4 0c             	add    $0xc,%esp
801042ed:	ff 73 04             	pushl  0x4(%ebx)
801042f0:	68 5e 6d 10 80       	push   $0x80106d5e
801042f5:	53                   	push   %ebx
801042f6:	e8 41 d8 ff ff       	call   80101b3c <dirlink>
801042fb:	83 c4 10             	add    $0x10,%esp
801042fe:	85 c0                	test   %eax,%eax
80104300:	78 18                	js     8010431a <create+0x149>
80104302:	83 ec 04             	sub    $0x4,%esp
80104305:	ff 76 04             	pushl  0x4(%esi)
80104308:	68 5d 6d 10 80       	push   $0x80106d5d
8010430d:	53                   	push   %ebx
8010430e:	e8 29 d8 ff ff       	call   80101b3c <dirlink>
80104313:	83 c4 10             	add    $0x10,%esp
80104316:	85 c0                	test   %eax,%eax
80104318:	79 87                	jns    801042a1 <create+0xd0>
      panic("create dots");
8010431a:	83 ec 0c             	sub    $0xc,%esp
8010431d:	68 60 6d 10 80       	push   $0x80106d60
80104322:	e8 21 c0 ff ff       	call   80100348 <panic>
    panic("create: dirlink");
80104327:	83 ec 0c             	sub    $0xc,%esp
8010432a:	68 6c 6d 10 80       	push   $0x80106d6c
8010432f:	e8 14 c0 ff ff       	call   80100348 <panic>
    return 0;
80104334:	89 c3                	mov    %eax,%ebx
80104336:	e9 04 ff ff ff       	jmp    8010423f <create+0x6e>

8010433b <sys_dup>:
{
8010433b:	55                   	push   %ebp
8010433c:	89 e5                	mov    %esp,%ebp
8010433e:	53                   	push   %ebx
8010433f:	83 ec 14             	sub    $0x14,%esp
  if(argfd(0, 0, &f) < 0)
80104342:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104345:	ba 00 00 00 00       	mov    $0x0,%edx
8010434a:	b8 00 00 00 00       	mov    $0x0,%eax
8010434f:	e8 88 fd ff ff       	call   801040dc <argfd>
80104354:	85 c0                	test   %eax,%eax
80104356:	78 23                	js     8010437b <sys_dup+0x40>
  if((fd=fdalloc(f)) < 0)
80104358:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010435b:	e8 e3 fd ff ff       	call   80104143 <fdalloc>
80104360:	89 c3                	mov    %eax,%ebx
80104362:	85 c0                	test   %eax,%eax
80104364:	78 1c                	js     80104382 <sys_dup+0x47>
  filedup(f);
80104366:	83 ec 0c             	sub    $0xc,%esp
80104369:	ff 75 f4             	pushl  -0xc(%ebp)
8010436c:	e8 29 c9 ff ff       	call   80100c9a <filedup>
  return fd;
80104371:	83 c4 10             	add    $0x10,%esp
}
80104374:	89 d8                	mov    %ebx,%eax
80104376:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104379:	c9                   	leave  
8010437a:	c3                   	ret    
    return -1;
8010437b:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104380:	eb f2                	jmp    80104374 <sys_dup+0x39>
    return -1;
80104382:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104387:	eb eb                	jmp    80104374 <sys_dup+0x39>

80104389 <sys_read>:
{
80104389:	55                   	push   %ebp
8010438a:	89 e5                	mov    %esp,%ebp
8010438c:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
8010438f:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104392:	ba 00 00 00 00       	mov    $0x0,%edx
80104397:	b8 00 00 00 00       	mov    $0x0,%eax
8010439c:	e8 3b fd ff ff       	call   801040dc <argfd>
801043a1:	85 c0                	test   %eax,%eax
801043a3:	78 43                	js     801043e8 <sys_read+0x5f>
801043a5:	83 ec 08             	sub    $0x8,%esp
801043a8:	8d 45 f0             	lea    -0x10(%ebp),%eax
801043ab:	50                   	push   %eax
801043ac:	6a 02                	push   $0x2
801043ae:	e8 11 fc ff ff       	call   80103fc4 <argint>
801043b3:	83 c4 10             	add    $0x10,%esp
801043b6:	85 c0                	test   %eax,%eax
801043b8:	78 35                	js     801043ef <sys_read+0x66>
801043ba:	83 ec 04             	sub    $0x4,%esp
801043bd:	ff 75 f0             	pushl  -0x10(%ebp)
801043c0:	8d 45 ec             	lea    -0x14(%ebp),%eax
801043c3:	50                   	push   %eax
801043c4:	6a 01                	push   $0x1
801043c6:	e8 21 fc ff ff       	call   80103fec <argptr>
801043cb:	83 c4 10             	add    $0x10,%esp
801043ce:	85 c0                	test   %eax,%eax
801043d0:	78 24                	js     801043f6 <sys_read+0x6d>
  return fileread(f, p, n);
801043d2:	83 ec 04             	sub    $0x4,%esp
801043d5:	ff 75 f0             	pushl  -0x10(%ebp)
801043d8:	ff 75 ec             	pushl  -0x14(%ebp)
801043db:	ff 75 f4             	pushl  -0xc(%ebp)
801043de:	e8 00 ca ff ff       	call   80100de3 <fileread>
801043e3:	83 c4 10             	add    $0x10,%esp
}
801043e6:	c9                   	leave  
801043e7:	c3                   	ret    
    return -1;
801043e8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043ed:	eb f7                	jmp    801043e6 <sys_read+0x5d>
801043ef:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043f4:	eb f0                	jmp    801043e6 <sys_read+0x5d>
801043f6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043fb:	eb e9                	jmp    801043e6 <sys_read+0x5d>

801043fd <sys_write>:
{
801043fd:	55                   	push   %ebp
801043fe:	89 e5                	mov    %esp,%ebp
80104400:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80104403:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104406:	ba 00 00 00 00       	mov    $0x0,%edx
8010440b:	b8 00 00 00 00       	mov    $0x0,%eax
80104410:	e8 c7 fc ff ff       	call   801040dc <argfd>
80104415:	85 c0                	test   %eax,%eax
80104417:	78 43                	js     8010445c <sys_write+0x5f>
80104419:	83 ec 08             	sub    $0x8,%esp
8010441c:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010441f:	50                   	push   %eax
80104420:	6a 02                	push   $0x2
80104422:	e8 9d fb ff ff       	call   80103fc4 <argint>
80104427:	83 c4 10             	add    $0x10,%esp
8010442a:	85 c0                	test   %eax,%eax
8010442c:	78 35                	js     80104463 <sys_write+0x66>
8010442e:	83 ec 04             	sub    $0x4,%esp
80104431:	ff 75 f0             	pushl  -0x10(%ebp)
80104434:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104437:	50                   	push   %eax
80104438:	6a 01                	push   $0x1
8010443a:	e8 ad fb ff ff       	call   80103fec <argptr>
8010443f:	83 c4 10             	add    $0x10,%esp
80104442:	85 c0                	test   %eax,%eax
80104444:	78 24                	js     8010446a <sys_write+0x6d>
  return filewrite(f, p, n);
80104446:	83 ec 04             	sub    $0x4,%esp
80104449:	ff 75 f0             	pushl  -0x10(%ebp)
8010444c:	ff 75 ec             	pushl  -0x14(%ebp)
8010444f:	ff 75 f4             	pushl  -0xc(%ebp)
80104452:	e8 11 ca ff ff       	call   80100e68 <filewrite>
80104457:	83 c4 10             	add    $0x10,%esp
}
8010445a:	c9                   	leave  
8010445b:	c3                   	ret    
    return -1;
8010445c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104461:	eb f7                	jmp    8010445a <sys_write+0x5d>
80104463:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104468:	eb f0                	jmp    8010445a <sys_write+0x5d>
8010446a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010446f:	eb e9                	jmp    8010445a <sys_write+0x5d>

80104471 <sys_close>:
{
80104471:	55                   	push   %ebp
80104472:	89 e5                	mov    %esp,%ebp
80104474:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, &fd, &f) < 0)
80104477:	8d 4d f0             	lea    -0x10(%ebp),%ecx
8010447a:	8d 55 f4             	lea    -0xc(%ebp),%edx
8010447d:	b8 00 00 00 00       	mov    $0x0,%eax
80104482:	e8 55 fc ff ff       	call   801040dc <argfd>
80104487:	85 c0                	test   %eax,%eax
80104489:	78 25                	js     801044b0 <sys_close+0x3f>
  myproc()->ofile[fd] = 0;
8010448b:	e8 9b ee ff ff       	call   8010332b <myproc>
80104490:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104493:	c7 44 90 28 00 00 00 	movl   $0x0,0x28(%eax,%edx,4)
8010449a:	00 
  fileclose(f);
8010449b:	83 ec 0c             	sub    $0xc,%esp
8010449e:	ff 75 f0             	pushl  -0x10(%ebp)
801044a1:	e8 39 c8 ff ff       	call   80100cdf <fileclose>
  return 0;
801044a6:	83 c4 10             	add    $0x10,%esp
801044a9:	b8 00 00 00 00       	mov    $0x0,%eax
}
801044ae:	c9                   	leave  
801044af:	c3                   	ret    
    return -1;
801044b0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044b5:	eb f7                	jmp    801044ae <sys_close+0x3d>

801044b7 <sys_fstat>:
{
801044b7:	55                   	push   %ebp
801044b8:	89 e5                	mov    %esp,%ebp
801044ba:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801044bd:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801044c0:	ba 00 00 00 00       	mov    $0x0,%edx
801044c5:	b8 00 00 00 00       	mov    $0x0,%eax
801044ca:	e8 0d fc ff ff       	call   801040dc <argfd>
801044cf:	85 c0                	test   %eax,%eax
801044d1:	78 2a                	js     801044fd <sys_fstat+0x46>
801044d3:	83 ec 04             	sub    $0x4,%esp
801044d6:	6a 14                	push   $0x14
801044d8:	8d 45 f0             	lea    -0x10(%ebp),%eax
801044db:	50                   	push   %eax
801044dc:	6a 01                	push   $0x1
801044de:	e8 09 fb ff ff       	call   80103fec <argptr>
801044e3:	83 c4 10             	add    $0x10,%esp
801044e6:	85 c0                	test   %eax,%eax
801044e8:	78 1a                	js     80104504 <sys_fstat+0x4d>
  return filestat(f, st);
801044ea:	83 ec 08             	sub    $0x8,%esp
801044ed:	ff 75 f0             	pushl  -0x10(%ebp)
801044f0:	ff 75 f4             	pushl  -0xc(%ebp)
801044f3:	e8 a4 c8 ff ff       	call   80100d9c <filestat>
801044f8:	83 c4 10             	add    $0x10,%esp
}
801044fb:	c9                   	leave  
801044fc:	c3                   	ret    
    return -1;
801044fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104502:	eb f7                	jmp    801044fb <sys_fstat+0x44>
80104504:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104509:	eb f0                	jmp    801044fb <sys_fstat+0x44>

8010450b <sys_link>:
{
8010450b:	55                   	push   %ebp
8010450c:	89 e5                	mov    %esp,%ebp
8010450e:	56                   	push   %esi
8010450f:	53                   	push   %ebx
80104510:	83 ec 28             	sub    $0x28,%esp
  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80104513:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104516:	50                   	push   %eax
80104517:	6a 00                	push   $0x0
80104519:	e8 36 fb ff ff       	call   80104054 <argstr>
8010451e:	83 c4 10             	add    $0x10,%esp
80104521:	85 c0                	test   %eax,%eax
80104523:	0f 88 32 01 00 00    	js     8010465b <sys_link+0x150>
80104529:	83 ec 08             	sub    $0x8,%esp
8010452c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010452f:	50                   	push   %eax
80104530:	6a 01                	push   $0x1
80104532:	e8 1d fb ff ff       	call   80104054 <argstr>
80104537:	83 c4 10             	add    $0x10,%esp
8010453a:	85 c0                	test   %eax,%eax
8010453c:	0f 88 20 01 00 00    	js     80104662 <sys_link+0x157>
  begin_op();
80104542:	e8 89 e3 ff ff       	call   801028d0 <begin_op>
  if((ip = namei(old)) == 0){
80104547:	83 ec 0c             	sub    $0xc,%esp
8010454a:	ff 75 e0             	pushl  -0x20(%ebp)
8010454d:	e8 9b d6 ff ff       	call   80101bed <namei>
80104552:	89 c3                	mov    %eax,%ebx
80104554:	83 c4 10             	add    $0x10,%esp
80104557:	85 c0                	test   %eax,%eax
80104559:	0f 84 99 00 00 00    	je     801045f8 <sys_link+0xed>
  ilock(ip);
8010455f:	83 ec 0c             	sub    $0xc,%esp
80104562:	50                   	push   %eax
80104563:	e8 25 d0 ff ff       	call   8010158d <ilock>
  if(ip->type == T_DIR){
80104568:	83 c4 10             	add    $0x10,%esp
8010456b:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104570:	0f 84 8e 00 00 00    	je     80104604 <sys_link+0xf9>
  ip->nlink++;
80104576:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
8010457a:	83 c0 01             	add    $0x1,%eax
8010457d:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104581:	83 ec 0c             	sub    $0xc,%esp
80104584:	53                   	push   %ebx
80104585:	e8 a2 ce ff ff       	call   8010142c <iupdate>
  iunlock(ip);
8010458a:	89 1c 24             	mov    %ebx,(%esp)
8010458d:	e8 bd d0 ff ff       	call   8010164f <iunlock>
  if((dp = nameiparent(new, name)) == 0)
80104592:	83 c4 08             	add    $0x8,%esp
80104595:	8d 45 ea             	lea    -0x16(%ebp),%eax
80104598:	50                   	push   %eax
80104599:	ff 75 e4             	pushl  -0x1c(%ebp)
8010459c:	e8 64 d6 ff ff       	call   80101c05 <nameiparent>
801045a1:	89 c6                	mov    %eax,%esi
801045a3:	83 c4 10             	add    $0x10,%esp
801045a6:	85 c0                	test   %eax,%eax
801045a8:	74 7e                	je     80104628 <sys_link+0x11d>
  ilock(dp);
801045aa:	83 ec 0c             	sub    $0xc,%esp
801045ad:	50                   	push   %eax
801045ae:	e8 da cf ff ff       	call   8010158d <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
801045b3:	83 c4 10             	add    $0x10,%esp
801045b6:	8b 03                	mov    (%ebx),%eax
801045b8:	39 06                	cmp    %eax,(%esi)
801045ba:	75 60                	jne    8010461c <sys_link+0x111>
801045bc:	83 ec 04             	sub    $0x4,%esp
801045bf:	ff 73 04             	pushl  0x4(%ebx)
801045c2:	8d 45 ea             	lea    -0x16(%ebp),%eax
801045c5:	50                   	push   %eax
801045c6:	56                   	push   %esi
801045c7:	e8 70 d5 ff ff       	call   80101b3c <dirlink>
801045cc:	83 c4 10             	add    $0x10,%esp
801045cf:	85 c0                	test   %eax,%eax
801045d1:	78 49                	js     8010461c <sys_link+0x111>
  iunlockput(dp);
801045d3:	83 ec 0c             	sub    $0xc,%esp
801045d6:	56                   	push   %esi
801045d7:	e8 58 d1 ff ff       	call   80101734 <iunlockput>
  iput(ip);
801045dc:	89 1c 24             	mov    %ebx,(%esp)
801045df:	e8 b0 d0 ff ff       	call   80101694 <iput>
  end_op();
801045e4:	e8 61 e3 ff ff       	call   8010294a <end_op>
  return 0;
801045e9:	83 c4 10             	add    $0x10,%esp
801045ec:	b8 00 00 00 00       	mov    $0x0,%eax
}
801045f1:	8d 65 f8             	lea    -0x8(%ebp),%esp
801045f4:	5b                   	pop    %ebx
801045f5:	5e                   	pop    %esi
801045f6:	5d                   	pop    %ebp
801045f7:	c3                   	ret    
    end_op();
801045f8:	e8 4d e3 ff ff       	call   8010294a <end_op>
    return -1;
801045fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104602:	eb ed                	jmp    801045f1 <sys_link+0xe6>
    iunlockput(ip);
80104604:	83 ec 0c             	sub    $0xc,%esp
80104607:	53                   	push   %ebx
80104608:	e8 27 d1 ff ff       	call   80101734 <iunlockput>
    end_op();
8010460d:	e8 38 e3 ff ff       	call   8010294a <end_op>
    return -1;
80104612:	83 c4 10             	add    $0x10,%esp
80104615:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010461a:	eb d5                	jmp    801045f1 <sys_link+0xe6>
    iunlockput(dp);
8010461c:	83 ec 0c             	sub    $0xc,%esp
8010461f:	56                   	push   %esi
80104620:	e8 0f d1 ff ff       	call   80101734 <iunlockput>
    goto bad;
80104625:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
80104628:	83 ec 0c             	sub    $0xc,%esp
8010462b:	53                   	push   %ebx
8010462c:	e8 5c cf ff ff       	call   8010158d <ilock>
  ip->nlink--;
80104631:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104635:	83 e8 01             	sub    $0x1,%eax
80104638:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
8010463c:	89 1c 24             	mov    %ebx,(%esp)
8010463f:	e8 e8 cd ff ff       	call   8010142c <iupdate>
  iunlockput(ip);
80104644:	89 1c 24             	mov    %ebx,(%esp)
80104647:	e8 e8 d0 ff ff       	call   80101734 <iunlockput>
  end_op();
8010464c:	e8 f9 e2 ff ff       	call   8010294a <end_op>
  return -1;
80104651:	83 c4 10             	add    $0x10,%esp
80104654:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104659:	eb 96                	jmp    801045f1 <sys_link+0xe6>
    return -1;
8010465b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104660:	eb 8f                	jmp    801045f1 <sys_link+0xe6>
80104662:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104667:	eb 88                	jmp    801045f1 <sys_link+0xe6>

80104669 <sys_unlink>:
{
80104669:	55                   	push   %ebp
8010466a:	89 e5                	mov    %esp,%ebp
8010466c:	57                   	push   %edi
8010466d:	56                   	push   %esi
8010466e:	53                   	push   %ebx
8010466f:	83 ec 44             	sub    $0x44,%esp
  if(argstr(0, &path) < 0)
80104672:	8d 45 c4             	lea    -0x3c(%ebp),%eax
80104675:	50                   	push   %eax
80104676:	6a 00                	push   $0x0
80104678:	e8 d7 f9 ff ff       	call   80104054 <argstr>
8010467d:	83 c4 10             	add    $0x10,%esp
80104680:	85 c0                	test   %eax,%eax
80104682:	0f 88 83 01 00 00    	js     8010480b <sys_unlink+0x1a2>
  begin_op();
80104688:	e8 43 e2 ff ff       	call   801028d0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
8010468d:	83 ec 08             	sub    $0x8,%esp
80104690:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104693:	50                   	push   %eax
80104694:	ff 75 c4             	pushl  -0x3c(%ebp)
80104697:	e8 69 d5 ff ff       	call   80101c05 <nameiparent>
8010469c:	89 c6                	mov    %eax,%esi
8010469e:	83 c4 10             	add    $0x10,%esp
801046a1:	85 c0                	test   %eax,%eax
801046a3:	0f 84 ed 00 00 00    	je     80104796 <sys_unlink+0x12d>
  ilock(dp);
801046a9:	83 ec 0c             	sub    $0xc,%esp
801046ac:	50                   	push   %eax
801046ad:	e8 db ce ff ff       	call   8010158d <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
801046b2:	83 c4 08             	add    $0x8,%esp
801046b5:	68 5e 6d 10 80       	push   $0x80106d5e
801046ba:	8d 45 ca             	lea    -0x36(%ebp),%eax
801046bd:	50                   	push   %eax
801046be:	e8 e4 d2 ff ff       	call   801019a7 <namecmp>
801046c3:	83 c4 10             	add    $0x10,%esp
801046c6:	85 c0                	test   %eax,%eax
801046c8:	0f 84 fc 00 00 00    	je     801047ca <sys_unlink+0x161>
801046ce:	83 ec 08             	sub    $0x8,%esp
801046d1:	68 5d 6d 10 80       	push   $0x80106d5d
801046d6:	8d 45 ca             	lea    -0x36(%ebp),%eax
801046d9:	50                   	push   %eax
801046da:	e8 c8 d2 ff ff       	call   801019a7 <namecmp>
801046df:	83 c4 10             	add    $0x10,%esp
801046e2:	85 c0                	test   %eax,%eax
801046e4:	0f 84 e0 00 00 00    	je     801047ca <sys_unlink+0x161>
  if((ip = dirlookup(dp, name, &off)) == 0)
801046ea:	83 ec 04             	sub    $0x4,%esp
801046ed:	8d 45 c0             	lea    -0x40(%ebp),%eax
801046f0:	50                   	push   %eax
801046f1:	8d 45 ca             	lea    -0x36(%ebp),%eax
801046f4:	50                   	push   %eax
801046f5:	56                   	push   %esi
801046f6:	e8 c1 d2 ff ff       	call   801019bc <dirlookup>
801046fb:	89 c3                	mov    %eax,%ebx
801046fd:	83 c4 10             	add    $0x10,%esp
80104700:	85 c0                	test   %eax,%eax
80104702:	0f 84 c2 00 00 00    	je     801047ca <sys_unlink+0x161>
  ilock(ip);
80104708:	83 ec 0c             	sub    $0xc,%esp
8010470b:	50                   	push   %eax
8010470c:	e8 7c ce ff ff       	call   8010158d <ilock>
  if(ip->nlink < 1)
80104711:	83 c4 10             	add    $0x10,%esp
80104714:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
80104719:	0f 8e 83 00 00 00    	jle    801047a2 <sys_unlink+0x139>
  if(ip->type == T_DIR && !isdirempty(ip)){
8010471f:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104724:	0f 84 85 00 00 00    	je     801047af <sys_unlink+0x146>
  memset(&de, 0, sizeof(de));
8010472a:	83 ec 04             	sub    $0x4,%esp
8010472d:	6a 10                	push   $0x10
8010472f:	6a 00                	push   $0x0
80104731:	8d 7d d8             	lea    -0x28(%ebp),%edi
80104734:	57                   	push   %edi
80104735:	e8 3f f6 ff ff       	call   80103d79 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010473a:	6a 10                	push   $0x10
8010473c:	ff 75 c0             	pushl  -0x40(%ebp)
8010473f:	57                   	push   %edi
80104740:	56                   	push   %esi
80104741:	e8 36 d1 ff ff       	call   8010187c <writei>
80104746:	83 c4 20             	add    $0x20,%esp
80104749:	83 f8 10             	cmp    $0x10,%eax
8010474c:	0f 85 90 00 00 00    	jne    801047e2 <sys_unlink+0x179>
  if(ip->type == T_DIR){
80104752:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104757:	0f 84 92 00 00 00    	je     801047ef <sys_unlink+0x186>
  iunlockput(dp);
8010475d:	83 ec 0c             	sub    $0xc,%esp
80104760:	56                   	push   %esi
80104761:	e8 ce cf ff ff       	call   80101734 <iunlockput>
  ip->nlink--;
80104766:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
8010476a:	83 e8 01             	sub    $0x1,%eax
8010476d:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104771:	89 1c 24             	mov    %ebx,(%esp)
80104774:	e8 b3 cc ff ff       	call   8010142c <iupdate>
  iunlockput(ip);
80104779:	89 1c 24             	mov    %ebx,(%esp)
8010477c:	e8 b3 cf ff ff       	call   80101734 <iunlockput>
  end_op();
80104781:	e8 c4 e1 ff ff       	call   8010294a <end_op>
  return 0;
80104786:	83 c4 10             	add    $0x10,%esp
80104789:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010478e:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104791:	5b                   	pop    %ebx
80104792:	5e                   	pop    %esi
80104793:	5f                   	pop    %edi
80104794:	5d                   	pop    %ebp
80104795:	c3                   	ret    
    end_op();
80104796:	e8 af e1 ff ff       	call   8010294a <end_op>
    return -1;
8010479b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047a0:	eb ec                	jmp    8010478e <sys_unlink+0x125>
    panic("unlink: nlink < 1");
801047a2:	83 ec 0c             	sub    $0xc,%esp
801047a5:	68 7c 6d 10 80       	push   $0x80106d7c
801047aa:	e8 99 bb ff ff       	call   80100348 <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
801047af:	89 d8                	mov    %ebx,%eax
801047b1:	e8 c4 f9 ff ff       	call   8010417a <isdirempty>
801047b6:	85 c0                	test   %eax,%eax
801047b8:	0f 85 6c ff ff ff    	jne    8010472a <sys_unlink+0xc1>
    iunlockput(ip);
801047be:	83 ec 0c             	sub    $0xc,%esp
801047c1:	53                   	push   %ebx
801047c2:	e8 6d cf ff ff       	call   80101734 <iunlockput>
    goto bad;
801047c7:	83 c4 10             	add    $0x10,%esp
  iunlockput(dp);
801047ca:	83 ec 0c             	sub    $0xc,%esp
801047cd:	56                   	push   %esi
801047ce:	e8 61 cf ff ff       	call   80101734 <iunlockput>
  end_op();
801047d3:	e8 72 e1 ff ff       	call   8010294a <end_op>
  return -1;
801047d8:	83 c4 10             	add    $0x10,%esp
801047db:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047e0:	eb ac                	jmp    8010478e <sys_unlink+0x125>
    panic("unlink: writei");
801047e2:	83 ec 0c             	sub    $0xc,%esp
801047e5:	68 8e 6d 10 80       	push   $0x80106d8e
801047ea:	e8 59 bb ff ff       	call   80100348 <panic>
    dp->nlink--;
801047ef:	0f b7 46 56          	movzwl 0x56(%esi),%eax
801047f3:	83 e8 01             	sub    $0x1,%eax
801047f6:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
801047fa:	83 ec 0c             	sub    $0xc,%esp
801047fd:	56                   	push   %esi
801047fe:	e8 29 cc ff ff       	call   8010142c <iupdate>
80104803:	83 c4 10             	add    $0x10,%esp
80104806:	e9 52 ff ff ff       	jmp    8010475d <sys_unlink+0xf4>
    return -1;
8010480b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104810:	e9 79 ff ff ff       	jmp    8010478e <sys_unlink+0x125>

80104815 <sys_open>:

int
sys_open(void)
{
80104815:	55                   	push   %ebp
80104816:	89 e5                	mov    %esp,%ebp
80104818:	57                   	push   %edi
80104819:	56                   	push   %esi
8010481a:	53                   	push   %ebx
8010481b:	83 ec 24             	sub    $0x24,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
8010481e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104821:	50                   	push   %eax
80104822:	6a 00                	push   $0x0
80104824:	e8 2b f8 ff ff       	call   80104054 <argstr>
80104829:	83 c4 10             	add    $0x10,%esp
8010482c:	85 c0                	test   %eax,%eax
8010482e:	0f 88 30 01 00 00    	js     80104964 <sys_open+0x14f>
80104834:	83 ec 08             	sub    $0x8,%esp
80104837:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010483a:	50                   	push   %eax
8010483b:	6a 01                	push   $0x1
8010483d:	e8 82 f7 ff ff       	call   80103fc4 <argint>
80104842:	83 c4 10             	add    $0x10,%esp
80104845:	85 c0                	test   %eax,%eax
80104847:	0f 88 21 01 00 00    	js     8010496e <sys_open+0x159>
    return -1;

  begin_op();
8010484d:	e8 7e e0 ff ff       	call   801028d0 <begin_op>

  if(omode & O_CREATE){
80104852:	f6 45 e1 02          	testb  $0x2,-0x1f(%ebp)
80104856:	0f 84 84 00 00 00    	je     801048e0 <sys_open+0xcb>
    ip = create(path, T_FILE, 0, 0);
8010485c:	83 ec 0c             	sub    $0xc,%esp
8010485f:	6a 00                	push   $0x0
80104861:	b9 00 00 00 00       	mov    $0x0,%ecx
80104866:	ba 02 00 00 00       	mov    $0x2,%edx
8010486b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010486e:	e8 5e f9 ff ff       	call   801041d1 <create>
80104873:	89 c6                	mov    %eax,%esi
    if(ip == 0){
80104875:	83 c4 10             	add    $0x10,%esp
80104878:	85 c0                	test   %eax,%eax
8010487a:	74 58                	je     801048d4 <sys_open+0xbf>
      end_op();
      return -1;
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
8010487c:	e8 b8 c3 ff ff       	call   80100c39 <filealloc>
80104881:	89 c3                	mov    %eax,%ebx
80104883:	85 c0                	test   %eax,%eax
80104885:	0f 84 ae 00 00 00    	je     80104939 <sys_open+0x124>
8010488b:	e8 b3 f8 ff ff       	call   80104143 <fdalloc>
80104890:	89 c7                	mov    %eax,%edi
80104892:	85 c0                	test   %eax,%eax
80104894:	0f 88 9f 00 00 00    	js     80104939 <sys_open+0x124>
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
8010489a:	83 ec 0c             	sub    $0xc,%esp
8010489d:	56                   	push   %esi
8010489e:	e8 ac cd ff ff       	call   8010164f <iunlock>
  end_op();
801048a3:	e8 a2 e0 ff ff       	call   8010294a <end_op>

  f->type = FD_INODE;
801048a8:	c7 03 02 00 00 00    	movl   $0x2,(%ebx)
  f->ip = ip;
801048ae:	89 73 10             	mov    %esi,0x10(%ebx)
  f->off = 0;
801048b1:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
  f->readable = !(omode & O_WRONLY);
801048b8:	8b 45 e0             	mov    -0x20(%ebp),%eax
801048bb:	83 c4 10             	add    $0x10,%esp
801048be:	a8 01                	test   $0x1,%al
801048c0:	0f 94 43 08          	sete   0x8(%ebx)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
801048c4:	a8 03                	test   $0x3,%al
801048c6:	0f 95 43 09          	setne  0x9(%ebx)
  return fd;
}
801048ca:	89 f8                	mov    %edi,%eax
801048cc:	8d 65 f4             	lea    -0xc(%ebp),%esp
801048cf:	5b                   	pop    %ebx
801048d0:	5e                   	pop    %esi
801048d1:	5f                   	pop    %edi
801048d2:	5d                   	pop    %ebp
801048d3:	c3                   	ret    
      end_op();
801048d4:	e8 71 e0 ff ff       	call   8010294a <end_op>
      return -1;
801048d9:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801048de:	eb ea                	jmp    801048ca <sys_open+0xb5>
    if((ip = namei(path)) == 0){
801048e0:	83 ec 0c             	sub    $0xc,%esp
801048e3:	ff 75 e4             	pushl  -0x1c(%ebp)
801048e6:	e8 02 d3 ff ff       	call   80101bed <namei>
801048eb:	89 c6                	mov    %eax,%esi
801048ed:	83 c4 10             	add    $0x10,%esp
801048f0:	85 c0                	test   %eax,%eax
801048f2:	74 39                	je     8010492d <sys_open+0x118>
    ilock(ip);
801048f4:	83 ec 0c             	sub    $0xc,%esp
801048f7:	50                   	push   %eax
801048f8:	e8 90 cc ff ff       	call   8010158d <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
801048fd:	83 c4 10             	add    $0x10,%esp
80104900:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
80104905:	0f 85 71 ff ff ff    	jne    8010487c <sys_open+0x67>
8010490b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
8010490f:	0f 84 67 ff ff ff    	je     8010487c <sys_open+0x67>
      iunlockput(ip);
80104915:	83 ec 0c             	sub    $0xc,%esp
80104918:	56                   	push   %esi
80104919:	e8 16 ce ff ff       	call   80101734 <iunlockput>
      end_op();
8010491e:	e8 27 e0 ff ff       	call   8010294a <end_op>
      return -1;
80104923:	83 c4 10             	add    $0x10,%esp
80104926:	bf ff ff ff ff       	mov    $0xffffffff,%edi
8010492b:	eb 9d                	jmp    801048ca <sys_open+0xb5>
      end_op();
8010492d:	e8 18 e0 ff ff       	call   8010294a <end_op>
      return -1;
80104932:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104937:	eb 91                	jmp    801048ca <sys_open+0xb5>
    if(f)
80104939:	85 db                	test   %ebx,%ebx
8010493b:	74 0c                	je     80104949 <sys_open+0x134>
      fileclose(f);
8010493d:	83 ec 0c             	sub    $0xc,%esp
80104940:	53                   	push   %ebx
80104941:	e8 99 c3 ff ff       	call   80100cdf <fileclose>
80104946:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
80104949:	83 ec 0c             	sub    $0xc,%esp
8010494c:	56                   	push   %esi
8010494d:	e8 e2 cd ff ff       	call   80101734 <iunlockput>
    end_op();
80104952:	e8 f3 df ff ff       	call   8010294a <end_op>
    return -1;
80104957:	83 c4 10             	add    $0x10,%esp
8010495a:	bf ff ff ff ff       	mov    $0xffffffff,%edi
8010495f:	e9 66 ff ff ff       	jmp    801048ca <sys_open+0xb5>
    return -1;
80104964:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104969:	e9 5c ff ff ff       	jmp    801048ca <sys_open+0xb5>
8010496e:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104973:	e9 52 ff ff ff       	jmp    801048ca <sys_open+0xb5>

80104978 <sys_mkdir>:

int
sys_mkdir(void)
{
80104978:	55                   	push   %ebp
80104979:	89 e5                	mov    %esp,%ebp
8010497b:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
8010497e:	e8 4d df ff ff       	call   801028d0 <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80104983:	83 ec 08             	sub    $0x8,%esp
80104986:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104989:	50                   	push   %eax
8010498a:	6a 00                	push   $0x0
8010498c:	e8 c3 f6 ff ff       	call   80104054 <argstr>
80104991:	83 c4 10             	add    $0x10,%esp
80104994:	85 c0                	test   %eax,%eax
80104996:	78 36                	js     801049ce <sys_mkdir+0x56>
80104998:	83 ec 0c             	sub    $0xc,%esp
8010499b:	6a 00                	push   $0x0
8010499d:	b9 00 00 00 00       	mov    $0x0,%ecx
801049a2:	ba 01 00 00 00       	mov    $0x1,%edx
801049a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049aa:	e8 22 f8 ff ff       	call   801041d1 <create>
801049af:	83 c4 10             	add    $0x10,%esp
801049b2:	85 c0                	test   %eax,%eax
801049b4:	74 18                	je     801049ce <sys_mkdir+0x56>
    end_op();
    return -1;
  }
  iunlockput(ip);
801049b6:	83 ec 0c             	sub    $0xc,%esp
801049b9:	50                   	push   %eax
801049ba:	e8 75 cd ff ff       	call   80101734 <iunlockput>
  end_op();
801049bf:	e8 86 df ff ff       	call   8010294a <end_op>
  return 0;
801049c4:	83 c4 10             	add    $0x10,%esp
801049c7:	b8 00 00 00 00       	mov    $0x0,%eax
}
801049cc:	c9                   	leave  
801049cd:	c3                   	ret    
    end_op();
801049ce:	e8 77 df ff ff       	call   8010294a <end_op>
    return -1;
801049d3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801049d8:	eb f2                	jmp    801049cc <sys_mkdir+0x54>

801049da <sys_mknod>:

int
sys_mknod(void)
{
801049da:	55                   	push   %ebp
801049db:	89 e5                	mov    %esp,%ebp
801049dd:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
801049e0:	e8 eb de ff ff       	call   801028d0 <begin_op>
  if((argstr(0, &path)) < 0 ||
801049e5:	83 ec 08             	sub    $0x8,%esp
801049e8:	8d 45 f4             	lea    -0xc(%ebp),%eax
801049eb:	50                   	push   %eax
801049ec:	6a 00                	push   $0x0
801049ee:	e8 61 f6 ff ff       	call   80104054 <argstr>
801049f3:	83 c4 10             	add    $0x10,%esp
801049f6:	85 c0                	test   %eax,%eax
801049f8:	78 62                	js     80104a5c <sys_mknod+0x82>
     argint(1, &major) < 0 ||
801049fa:	83 ec 08             	sub    $0x8,%esp
801049fd:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104a00:	50                   	push   %eax
80104a01:	6a 01                	push   $0x1
80104a03:	e8 bc f5 ff ff       	call   80103fc4 <argint>
  if((argstr(0, &path)) < 0 ||
80104a08:	83 c4 10             	add    $0x10,%esp
80104a0b:	85 c0                	test   %eax,%eax
80104a0d:	78 4d                	js     80104a5c <sys_mknod+0x82>
     argint(2, &minor) < 0 ||
80104a0f:	83 ec 08             	sub    $0x8,%esp
80104a12:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104a15:	50                   	push   %eax
80104a16:	6a 02                	push   $0x2
80104a18:	e8 a7 f5 ff ff       	call   80103fc4 <argint>
     argint(1, &major) < 0 ||
80104a1d:	83 c4 10             	add    $0x10,%esp
80104a20:	85 c0                	test   %eax,%eax
80104a22:	78 38                	js     80104a5c <sys_mknod+0x82>
     (ip = create(path, T_DEV, major, minor)) == 0){
80104a24:	0f bf 45 ec          	movswl -0x14(%ebp),%eax
80104a28:	0f bf 4d f0          	movswl -0x10(%ebp),%ecx
     argint(2, &minor) < 0 ||
80104a2c:	83 ec 0c             	sub    $0xc,%esp
80104a2f:	50                   	push   %eax
80104a30:	ba 03 00 00 00       	mov    $0x3,%edx
80104a35:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a38:	e8 94 f7 ff ff       	call   801041d1 <create>
80104a3d:	83 c4 10             	add    $0x10,%esp
80104a40:	85 c0                	test   %eax,%eax
80104a42:	74 18                	je     80104a5c <sys_mknod+0x82>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104a44:	83 ec 0c             	sub    $0xc,%esp
80104a47:	50                   	push   %eax
80104a48:	e8 e7 cc ff ff       	call   80101734 <iunlockput>
  end_op();
80104a4d:	e8 f8 de ff ff       	call   8010294a <end_op>
  return 0;
80104a52:	83 c4 10             	add    $0x10,%esp
80104a55:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104a5a:	c9                   	leave  
80104a5b:	c3                   	ret    
    end_op();
80104a5c:	e8 e9 de ff ff       	call   8010294a <end_op>
    return -1;
80104a61:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a66:	eb f2                	jmp    80104a5a <sys_mknod+0x80>

80104a68 <sys_chdir>:

int
sys_chdir(void)
{
80104a68:	55                   	push   %ebp
80104a69:	89 e5                	mov    %esp,%ebp
80104a6b:	56                   	push   %esi
80104a6c:	53                   	push   %ebx
80104a6d:	83 ec 10             	sub    $0x10,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
80104a70:	e8 b6 e8 ff ff       	call   8010332b <myproc>
80104a75:	89 c6                	mov    %eax,%esi
  
  begin_op();
80104a77:	e8 54 de ff ff       	call   801028d0 <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80104a7c:	83 ec 08             	sub    $0x8,%esp
80104a7f:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104a82:	50                   	push   %eax
80104a83:	6a 00                	push   $0x0
80104a85:	e8 ca f5 ff ff       	call   80104054 <argstr>
80104a8a:	83 c4 10             	add    $0x10,%esp
80104a8d:	85 c0                	test   %eax,%eax
80104a8f:	78 52                	js     80104ae3 <sys_chdir+0x7b>
80104a91:	83 ec 0c             	sub    $0xc,%esp
80104a94:	ff 75 f4             	pushl  -0xc(%ebp)
80104a97:	e8 51 d1 ff ff       	call   80101bed <namei>
80104a9c:	89 c3                	mov    %eax,%ebx
80104a9e:	83 c4 10             	add    $0x10,%esp
80104aa1:	85 c0                	test   %eax,%eax
80104aa3:	74 3e                	je     80104ae3 <sys_chdir+0x7b>
    end_op();
    return -1;
  }
  ilock(ip);
80104aa5:	83 ec 0c             	sub    $0xc,%esp
80104aa8:	50                   	push   %eax
80104aa9:	e8 df ca ff ff       	call   8010158d <ilock>
  if(ip->type != T_DIR){
80104aae:	83 c4 10             	add    $0x10,%esp
80104ab1:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104ab6:	75 37                	jne    80104aef <sys_chdir+0x87>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104ab8:	83 ec 0c             	sub    $0xc,%esp
80104abb:	53                   	push   %ebx
80104abc:	e8 8e cb ff ff       	call   8010164f <iunlock>
  iput(curproc->cwd);
80104ac1:	83 c4 04             	add    $0x4,%esp
80104ac4:	ff 76 68             	pushl  0x68(%esi)
80104ac7:	e8 c8 cb ff ff       	call   80101694 <iput>
  end_op();
80104acc:	e8 79 de ff ff       	call   8010294a <end_op>
  curproc->cwd = ip;
80104ad1:	89 5e 68             	mov    %ebx,0x68(%esi)
  return 0;
80104ad4:	83 c4 10             	add    $0x10,%esp
80104ad7:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104adc:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104adf:	5b                   	pop    %ebx
80104ae0:	5e                   	pop    %esi
80104ae1:	5d                   	pop    %ebp
80104ae2:	c3                   	ret    
    end_op();
80104ae3:	e8 62 de ff ff       	call   8010294a <end_op>
    return -1;
80104ae8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104aed:	eb ed                	jmp    80104adc <sys_chdir+0x74>
    iunlockput(ip);
80104aef:	83 ec 0c             	sub    $0xc,%esp
80104af2:	53                   	push   %ebx
80104af3:	e8 3c cc ff ff       	call   80101734 <iunlockput>
    end_op();
80104af8:	e8 4d de ff ff       	call   8010294a <end_op>
    return -1;
80104afd:	83 c4 10             	add    $0x10,%esp
80104b00:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b05:	eb d5                	jmp    80104adc <sys_chdir+0x74>

80104b07 <sys_exec>:

int
sys_exec(void)
{
80104b07:	55                   	push   %ebp
80104b08:	89 e5                	mov    %esp,%ebp
80104b0a:	53                   	push   %ebx
80104b0b:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80104b11:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104b14:	50                   	push   %eax
80104b15:	6a 00                	push   $0x0
80104b17:	e8 38 f5 ff ff       	call   80104054 <argstr>
80104b1c:	83 c4 10             	add    $0x10,%esp
80104b1f:	85 c0                	test   %eax,%eax
80104b21:	0f 88 a8 00 00 00    	js     80104bcf <sys_exec+0xc8>
80104b27:	83 ec 08             	sub    $0x8,%esp
80104b2a:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80104b30:	50                   	push   %eax
80104b31:	6a 01                	push   $0x1
80104b33:	e8 8c f4 ff ff       	call   80103fc4 <argint>
80104b38:	83 c4 10             	add    $0x10,%esp
80104b3b:	85 c0                	test   %eax,%eax
80104b3d:	0f 88 93 00 00 00    	js     80104bd6 <sys_exec+0xcf>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
80104b43:	83 ec 04             	sub    $0x4,%esp
80104b46:	68 80 00 00 00       	push   $0x80
80104b4b:	6a 00                	push   $0x0
80104b4d:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104b53:	50                   	push   %eax
80104b54:	e8 20 f2 ff ff       	call   80103d79 <memset>
80104b59:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
80104b5c:	bb 00 00 00 00       	mov    $0x0,%ebx
    if(i >= NELEM(argv))
80104b61:	83 fb 1f             	cmp    $0x1f,%ebx
80104b64:	77 77                	ja     80104bdd <sys_exec+0xd6>
      return -1;
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80104b66:	83 ec 08             	sub    $0x8,%esp
80104b69:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80104b6f:	50                   	push   %eax
80104b70:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
80104b76:	8d 04 98             	lea    (%eax,%ebx,4),%eax
80104b79:	50                   	push   %eax
80104b7a:	e8 c9 f3 ff ff       	call   80103f48 <fetchint>
80104b7f:	83 c4 10             	add    $0x10,%esp
80104b82:	85 c0                	test   %eax,%eax
80104b84:	78 5e                	js     80104be4 <sys_exec+0xdd>
      return -1;
    if(uarg == 0){
80104b86:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80104b8c:	85 c0                	test   %eax,%eax
80104b8e:	74 1d                	je     80104bad <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80104b90:	83 ec 08             	sub    $0x8,%esp
80104b93:	8d 94 9d 74 ff ff ff 	lea    -0x8c(%ebp,%ebx,4),%edx
80104b9a:	52                   	push   %edx
80104b9b:	50                   	push   %eax
80104b9c:	e8 e3 f3 ff ff       	call   80103f84 <fetchstr>
80104ba1:	83 c4 10             	add    $0x10,%esp
80104ba4:	85 c0                	test   %eax,%eax
80104ba6:	78 46                	js     80104bee <sys_exec+0xe7>
  for(i=0;; i++){
80104ba8:	83 c3 01             	add    $0x1,%ebx
    if(i >= NELEM(argv))
80104bab:	eb b4                	jmp    80104b61 <sys_exec+0x5a>
      argv[i] = 0;
80104bad:	c7 84 9d 74 ff ff ff 	movl   $0x0,-0x8c(%ebp,%ebx,4)
80104bb4:	00 00 00 00 
      return -1;
  }
  return exec(path, argv);
80104bb8:	83 ec 08             	sub    $0x8,%esp
80104bbb:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104bc1:	50                   	push   %eax
80104bc2:	ff 75 f4             	pushl  -0xc(%ebp)
80104bc5:	e8 08 bd ff ff       	call   801008d2 <exec>
80104bca:	83 c4 10             	add    $0x10,%esp
80104bcd:	eb 1a                	jmp    80104be9 <sys_exec+0xe2>
    return -1;
80104bcf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104bd4:	eb 13                	jmp    80104be9 <sys_exec+0xe2>
80104bd6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104bdb:	eb 0c                	jmp    80104be9 <sys_exec+0xe2>
      return -1;
80104bdd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104be2:	eb 05                	jmp    80104be9 <sys_exec+0xe2>
      return -1;
80104be4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104be9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104bec:	c9                   	leave  
80104bed:	c3                   	ret    
      return -1;
80104bee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104bf3:	eb f4                	jmp    80104be9 <sys_exec+0xe2>

80104bf5 <sys_pipe>:

int
sys_pipe(void)
{
80104bf5:	55                   	push   %ebp
80104bf6:	89 e5                	mov    %esp,%ebp
80104bf8:	53                   	push   %ebx
80104bf9:	83 ec 18             	sub    $0x18,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80104bfc:	6a 08                	push   $0x8
80104bfe:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104c01:	50                   	push   %eax
80104c02:	6a 00                	push   $0x0
80104c04:	e8 e3 f3 ff ff       	call   80103fec <argptr>
80104c09:	83 c4 10             	add    $0x10,%esp
80104c0c:	85 c0                	test   %eax,%eax
80104c0e:	78 77                	js     80104c87 <sys_pipe+0x92>
    return -1;
  if(pipealloc(&rf, &wf) < 0)
80104c10:	83 ec 08             	sub    $0x8,%esp
80104c13:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104c16:	50                   	push   %eax
80104c17:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104c1a:	50                   	push   %eax
80104c1b:	e8 3c e2 ff ff       	call   80102e5c <pipealloc>
80104c20:	83 c4 10             	add    $0x10,%esp
80104c23:	85 c0                	test   %eax,%eax
80104c25:	78 67                	js     80104c8e <sys_pipe+0x99>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80104c27:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104c2a:	e8 14 f5 ff ff       	call   80104143 <fdalloc>
80104c2f:	89 c3                	mov    %eax,%ebx
80104c31:	85 c0                	test   %eax,%eax
80104c33:	78 21                	js     80104c56 <sys_pipe+0x61>
80104c35:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104c38:	e8 06 f5 ff ff       	call   80104143 <fdalloc>
80104c3d:	85 c0                	test   %eax,%eax
80104c3f:	78 15                	js     80104c56 <sys_pipe+0x61>
      myproc()->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  fd[0] = fd0;
80104c41:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c44:	89 1a                	mov    %ebx,(%edx)
  fd[1] = fd1;
80104c46:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c49:	89 42 04             	mov    %eax,0x4(%edx)
  return 0;
80104c4c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104c51:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104c54:	c9                   	leave  
80104c55:	c3                   	ret    
    if(fd0 >= 0)
80104c56:	85 db                	test   %ebx,%ebx
80104c58:	78 0d                	js     80104c67 <sys_pipe+0x72>
      myproc()->ofile[fd0] = 0;
80104c5a:	e8 cc e6 ff ff       	call   8010332b <myproc>
80104c5f:	c7 44 98 28 00 00 00 	movl   $0x0,0x28(%eax,%ebx,4)
80104c66:	00 
    fileclose(rf);
80104c67:	83 ec 0c             	sub    $0xc,%esp
80104c6a:	ff 75 f0             	pushl  -0x10(%ebp)
80104c6d:	e8 6d c0 ff ff       	call   80100cdf <fileclose>
    fileclose(wf);
80104c72:	83 c4 04             	add    $0x4,%esp
80104c75:	ff 75 ec             	pushl  -0x14(%ebp)
80104c78:	e8 62 c0 ff ff       	call   80100cdf <fileclose>
    return -1;
80104c7d:	83 c4 10             	add    $0x10,%esp
80104c80:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c85:	eb ca                	jmp    80104c51 <sys_pipe+0x5c>
    return -1;
80104c87:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c8c:	eb c3                	jmp    80104c51 <sys_pipe+0x5c>
    return -1;
80104c8e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c93:	eb bc                	jmp    80104c51 <sys_pipe+0x5c>

80104c95 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80104c95:	55                   	push   %ebp
80104c96:	89 e5                	mov    %esp,%ebp
80104c98:	83 ec 08             	sub    $0x8,%esp
  return fork();
80104c9b:	e8 03 e8 ff ff       	call   801034a3 <fork>
}
80104ca0:	c9                   	leave  
80104ca1:	c3                   	ret    

80104ca2 <sys_exit>:

int
sys_exit(void)
{
80104ca2:	55                   	push   %ebp
80104ca3:	89 e5                	mov    %esp,%ebp
80104ca5:	83 ec 08             	sub    $0x8,%esp
  exit();
80104ca8:	e8 2d ea ff ff       	call   801036da <exit>
  return 0;  // not reached
}
80104cad:	b8 00 00 00 00       	mov    $0x0,%eax
80104cb2:	c9                   	leave  
80104cb3:	c3                   	ret    

80104cb4 <sys_wait>:

int
sys_wait(void)
{
80104cb4:	55                   	push   %ebp
80104cb5:	89 e5                	mov    %esp,%ebp
80104cb7:	83 ec 08             	sub    $0x8,%esp
  return wait();
80104cba:	e8 a4 eb ff ff       	call   80103863 <wait>
}
80104cbf:	c9                   	leave  
80104cc0:	c3                   	ret    

80104cc1 <sys_kill>:

int
sys_kill(void)
{
80104cc1:	55                   	push   %ebp
80104cc2:	89 e5                	mov    %esp,%ebp
80104cc4:	83 ec 20             	sub    $0x20,%esp
  int pid;

  if(argint(0, &pid) < 0)
80104cc7:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104cca:	50                   	push   %eax
80104ccb:	6a 00                	push   $0x0
80104ccd:	e8 f2 f2 ff ff       	call   80103fc4 <argint>
80104cd2:	83 c4 10             	add    $0x10,%esp
80104cd5:	85 c0                	test   %eax,%eax
80104cd7:	78 10                	js     80104ce9 <sys_kill+0x28>
    return -1;
  return kill(pid);
80104cd9:	83 ec 0c             	sub    $0xc,%esp
80104cdc:	ff 75 f4             	pushl  -0xc(%ebp)
80104cdf:	e8 7c ec ff ff       	call   80103960 <kill>
80104ce4:	83 c4 10             	add    $0x10,%esp
}
80104ce7:	c9                   	leave  
80104ce8:	c3                   	ret    
    return -1;
80104ce9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104cee:	eb f7                	jmp    80104ce7 <sys_kill+0x26>

80104cf0 <sys_dump_physmem>:

int
sys_dump_physmem(void)
{
80104cf0:	55                   	push   %ebp
80104cf1:	89 e5                	mov    %esp,%ebp
80104cf3:	83 ec 20             	sub    $0x20,%esp
  int *frames;
  int *pids;
  int numframes;

  if(argint(2, &numframes) < 0)
80104cf6:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104cf9:	50                   	push   %eax
80104cfa:	6a 02                	push   $0x2
80104cfc:	e8 c3 f2 ff ff       	call   80103fc4 <argint>
80104d01:	83 c4 10             	add    $0x10,%esp
80104d04:	85 c0                	test   %eax,%eax
80104d06:	78 4e                	js     80104d56 <sys_dump_physmem+0x66>
    return -1;
  if(argptr(0, (void *)&frames, numframes*sizeof(frames)) < 0)
80104d08:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104d0b:	c1 e0 02             	shl    $0x2,%eax
80104d0e:	83 ec 04             	sub    $0x4,%esp
80104d11:	50                   	push   %eax
80104d12:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d15:	50                   	push   %eax
80104d16:	6a 00                	push   $0x0
80104d18:	e8 cf f2 ff ff       	call   80103fec <argptr>
80104d1d:	83 c4 10             	add    $0x10,%esp
80104d20:	85 c0                	test   %eax,%eax
80104d22:	78 39                	js     80104d5d <sys_dump_physmem+0x6d>
    return -1;
  if(argptr(1, (void *)&pids, numframes*sizeof(pids)) < 0)
80104d24:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104d27:	c1 e0 02             	shl    $0x2,%eax
80104d2a:	83 ec 04             	sub    $0x4,%esp
80104d2d:	50                   	push   %eax
80104d2e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104d31:	50                   	push   %eax
80104d32:	6a 01                	push   $0x1
80104d34:	e8 b3 f2 ff ff       	call   80103fec <argptr>
80104d39:	83 c4 10             	add    $0x10,%esp
80104d3c:	85 c0                	test   %eax,%eax
80104d3e:	78 24                	js     80104d64 <sys_dump_physmem+0x74>
    return -1;
  return dump_physmem(frames, pids, numframes);
80104d40:	83 ec 04             	sub    $0x4,%esp
80104d43:	ff 75 ec             	pushl  -0x14(%ebp)
80104d46:	ff 75 f0             	pushl  -0x10(%ebp)
80104d49:	ff 75 f4             	pushl  -0xc(%ebp)
80104d4c:	e8 2c d4 ff ff       	call   8010217d <dump_physmem>
80104d51:	83 c4 10             	add    $0x10,%esp
}
80104d54:	c9                   	leave  
80104d55:	c3                   	ret    
    return -1;
80104d56:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d5b:	eb f7                	jmp    80104d54 <sys_dump_physmem+0x64>
    return -1;
80104d5d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d62:	eb f0                	jmp    80104d54 <sys_dump_physmem+0x64>
    return -1;
80104d64:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d69:	eb e9                	jmp    80104d54 <sys_dump_physmem+0x64>

80104d6b <sys_getpid>:

int
sys_getpid(void)
{
80104d6b:	55                   	push   %ebp
80104d6c:	89 e5                	mov    %esp,%ebp
80104d6e:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
80104d71:	e8 b5 e5 ff ff       	call   8010332b <myproc>
80104d76:	8b 40 10             	mov    0x10(%eax),%eax
}
80104d79:	c9                   	leave  
80104d7a:	c3                   	ret    

80104d7b <sys_sbrk>:

int
sys_sbrk(void)
{
80104d7b:	55                   	push   %ebp
80104d7c:	89 e5                	mov    %esp,%ebp
80104d7e:	53                   	push   %ebx
80104d7f:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80104d82:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d85:	50                   	push   %eax
80104d86:	6a 00                	push   $0x0
80104d88:	e8 37 f2 ff ff       	call   80103fc4 <argint>
80104d8d:	83 c4 10             	add    $0x10,%esp
80104d90:	85 c0                	test   %eax,%eax
80104d92:	78 27                	js     80104dbb <sys_sbrk+0x40>
    return -1;
  addr = myproc()->sz;
80104d94:	e8 92 e5 ff ff       	call   8010332b <myproc>
80104d99:	8b 18                	mov    (%eax),%ebx
  if(growproc(n) < 0)
80104d9b:	83 ec 0c             	sub    $0xc,%esp
80104d9e:	ff 75 f4             	pushl  -0xc(%ebp)
80104da1:	e8 90 e6 ff ff       	call   80103436 <growproc>
80104da6:	83 c4 10             	add    $0x10,%esp
80104da9:	85 c0                	test   %eax,%eax
80104dab:	78 07                	js     80104db4 <sys_sbrk+0x39>
    return -1;
  return addr;
}
80104dad:	89 d8                	mov    %ebx,%eax
80104daf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104db2:	c9                   	leave  
80104db3:	c3                   	ret    
    return -1;
80104db4:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104db9:	eb f2                	jmp    80104dad <sys_sbrk+0x32>
    return -1;
80104dbb:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104dc0:	eb eb                	jmp    80104dad <sys_sbrk+0x32>

80104dc2 <sys_sleep>:

int
sys_sleep(void)
{
80104dc2:	55                   	push   %ebp
80104dc3:	89 e5                	mov    %esp,%ebp
80104dc5:	53                   	push   %ebx
80104dc6:	83 ec 1c             	sub    $0x1c,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
80104dc9:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104dcc:	50                   	push   %eax
80104dcd:	6a 00                	push   $0x0
80104dcf:	e8 f0 f1 ff ff       	call   80103fc4 <argint>
80104dd4:	83 c4 10             	add    $0x10,%esp
80104dd7:	85 c0                	test   %eax,%eax
80104dd9:	78 75                	js     80104e50 <sys_sleep+0x8e>
    return -1;
  acquire(&tickslock);
80104ddb:	83 ec 0c             	sub    $0xc,%esp
80104dde:	68 80 3c 19 80       	push   $0x80193c80
80104de3:	e8 e5 ee ff ff       	call   80103ccd <acquire>
  ticks0 = ticks;
80104de8:	8b 1d c0 44 19 80    	mov    0x801944c0,%ebx
  while(ticks - ticks0 < n){
80104dee:	83 c4 10             	add    $0x10,%esp
80104df1:	a1 c0 44 19 80       	mov    0x801944c0,%eax
80104df6:	29 d8                	sub    %ebx,%eax
80104df8:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104dfb:	73 39                	jae    80104e36 <sys_sleep+0x74>
    if(myproc()->killed){
80104dfd:	e8 29 e5 ff ff       	call   8010332b <myproc>
80104e02:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104e06:	75 17                	jne    80104e1f <sys_sleep+0x5d>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
80104e08:	83 ec 08             	sub    $0x8,%esp
80104e0b:	68 80 3c 19 80       	push   $0x80193c80
80104e10:	68 c0 44 19 80       	push   $0x801944c0
80104e15:	e8 b8 e9 ff ff       	call   801037d2 <sleep>
80104e1a:	83 c4 10             	add    $0x10,%esp
80104e1d:	eb d2                	jmp    80104df1 <sys_sleep+0x2f>
      release(&tickslock);
80104e1f:	83 ec 0c             	sub    $0xc,%esp
80104e22:	68 80 3c 19 80       	push   $0x80193c80
80104e27:	e8 06 ef ff ff       	call   80103d32 <release>
      return -1;
80104e2c:	83 c4 10             	add    $0x10,%esp
80104e2f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e34:	eb 15                	jmp    80104e4b <sys_sleep+0x89>
  }
  release(&tickslock);
80104e36:	83 ec 0c             	sub    $0xc,%esp
80104e39:	68 80 3c 19 80       	push   $0x80193c80
80104e3e:	e8 ef ee ff ff       	call   80103d32 <release>
  return 0;
80104e43:	83 c4 10             	add    $0x10,%esp
80104e46:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104e4b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104e4e:	c9                   	leave  
80104e4f:	c3                   	ret    
    return -1;
80104e50:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e55:	eb f4                	jmp    80104e4b <sys_sleep+0x89>

80104e57 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80104e57:	55                   	push   %ebp
80104e58:	89 e5                	mov    %esp,%ebp
80104e5a:	53                   	push   %ebx
80104e5b:	83 ec 10             	sub    $0x10,%esp
  uint xticks;

  acquire(&tickslock);
80104e5e:	68 80 3c 19 80       	push   $0x80193c80
80104e63:	e8 65 ee ff ff       	call   80103ccd <acquire>
  xticks = ticks;
80104e68:	8b 1d c0 44 19 80    	mov    0x801944c0,%ebx
  release(&tickslock);
80104e6e:	c7 04 24 80 3c 19 80 	movl   $0x80193c80,(%esp)
80104e75:	e8 b8 ee ff ff       	call   80103d32 <release>
  return xticks;
}
80104e7a:	89 d8                	mov    %ebx,%eax
80104e7c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104e7f:	c9                   	leave  
80104e80:	c3                   	ret    

80104e81 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80104e81:	1e                   	push   %ds
  pushl %es
80104e82:	06                   	push   %es
  pushl %fs
80104e83:	0f a0                	push   %fs
  pushl %gs
80104e85:	0f a8                	push   %gs
  pushal
80104e87:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
80104e88:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80104e8c:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80104e8e:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
80104e90:	54                   	push   %esp
  call trap
80104e91:	e8 e3 00 00 00       	call   80104f79 <trap>
  addl $4, %esp
80104e96:	83 c4 04             	add    $0x4,%esp

80104e99 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80104e99:	61                   	popa   
  popl %gs
80104e9a:	0f a9                	pop    %gs
  popl %fs
80104e9c:	0f a1                	pop    %fs
  popl %es
80104e9e:	07                   	pop    %es
  popl %ds
80104e9f:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80104ea0:	83 c4 08             	add    $0x8,%esp
  iret
80104ea3:	cf                   	iret   

80104ea4 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80104ea4:	55                   	push   %ebp
80104ea5:	89 e5                	mov    %esp,%ebp
80104ea7:	83 ec 08             	sub    $0x8,%esp
  int i;

  for(i = 0; i < 256; i++)
80104eaa:	b8 00 00 00 00       	mov    $0x0,%eax
80104eaf:	eb 4a                	jmp    80104efb <tvinit+0x57>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80104eb1:	8b 0c 85 08 90 10 80 	mov    -0x7fef6ff8(,%eax,4),%ecx
80104eb8:	66 89 0c c5 c0 3c 19 	mov    %cx,-0x7fe6c340(,%eax,8)
80104ebf:	80 
80104ec0:	66 c7 04 c5 c2 3c 19 	movw   $0x8,-0x7fe6c33e(,%eax,8)
80104ec7:	80 08 00 
80104eca:	c6 04 c5 c4 3c 19 80 	movb   $0x0,-0x7fe6c33c(,%eax,8)
80104ed1:	00 
80104ed2:	0f b6 14 c5 c5 3c 19 	movzbl -0x7fe6c33b(,%eax,8),%edx
80104ed9:	80 
80104eda:	83 e2 f0             	and    $0xfffffff0,%edx
80104edd:	83 ca 0e             	or     $0xe,%edx
80104ee0:	83 e2 8f             	and    $0xffffff8f,%edx
80104ee3:	83 ca 80             	or     $0xffffff80,%edx
80104ee6:	88 14 c5 c5 3c 19 80 	mov    %dl,-0x7fe6c33b(,%eax,8)
80104eed:	c1 e9 10             	shr    $0x10,%ecx
80104ef0:	66 89 0c c5 c6 3c 19 	mov    %cx,-0x7fe6c33a(,%eax,8)
80104ef7:	80 
  for(i = 0; i < 256; i++)
80104ef8:	83 c0 01             	add    $0x1,%eax
80104efb:	3d ff 00 00 00       	cmp    $0xff,%eax
80104f00:	7e af                	jle    80104eb1 <tvinit+0xd>
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80104f02:	8b 15 08 91 10 80    	mov    0x80109108,%edx
80104f08:	66 89 15 c0 3e 19 80 	mov    %dx,0x80193ec0
80104f0f:	66 c7 05 c2 3e 19 80 	movw   $0x8,0x80193ec2
80104f16:	08 00 
80104f18:	c6 05 c4 3e 19 80 00 	movb   $0x0,0x80193ec4
80104f1f:	0f b6 05 c5 3e 19 80 	movzbl 0x80193ec5,%eax
80104f26:	83 c8 0f             	or     $0xf,%eax
80104f29:	83 e0 ef             	and    $0xffffffef,%eax
80104f2c:	83 c8 e0             	or     $0xffffffe0,%eax
80104f2f:	a2 c5 3e 19 80       	mov    %al,0x80193ec5
80104f34:	c1 ea 10             	shr    $0x10,%edx
80104f37:	66 89 15 c6 3e 19 80 	mov    %dx,0x80193ec6

  initlock(&tickslock, "time");
80104f3e:	83 ec 08             	sub    $0x8,%esp
80104f41:	68 9d 6d 10 80       	push   $0x80106d9d
80104f46:	68 80 3c 19 80       	push   $0x80193c80
80104f4b:	e8 41 ec ff ff       	call   80103b91 <initlock>
}
80104f50:	83 c4 10             	add    $0x10,%esp
80104f53:	c9                   	leave  
80104f54:	c3                   	ret    

80104f55 <idtinit>:

void
idtinit(void)
{
80104f55:	55                   	push   %ebp
80104f56:	89 e5                	mov    %esp,%ebp
80104f58:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
80104f5b:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
  pd[1] = (uint)p;
80104f61:	b8 c0 3c 19 80       	mov    $0x80193cc0,%eax
80104f66:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80104f6a:	c1 e8 10             	shr    $0x10,%eax
80104f6d:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lidt (%0)" : : "r" (pd));
80104f71:	8d 45 fa             	lea    -0x6(%ebp),%eax
80104f74:	0f 01 18             	lidtl  (%eax)
  lidt(idt, sizeof(idt));
}
80104f77:	c9                   	leave  
80104f78:	c3                   	ret    

80104f79 <trap>:

void
trap(struct trapframe *tf)
{
80104f79:	55                   	push   %ebp
80104f7a:	89 e5                	mov    %esp,%ebp
80104f7c:	57                   	push   %edi
80104f7d:	56                   	push   %esi
80104f7e:	53                   	push   %ebx
80104f7f:	83 ec 1c             	sub    $0x1c,%esp
80104f82:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(tf->trapno == T_SYSCALL){
80104f85:	8b 43 30             	mov    0x30(%ebx),%eax
80104f88:	83 f8 40             	cmp    $0x40,%eax
80104f8b:	74 13                	je     80104fa0 <trap+0x27>
    if(myproc()->killed)
      exit();
    return;
  }

  switch(tf->trapno){
80104f8d:	83 e8 20             	sub    $0x20,%eax
80104f90:	83 f8 1f             	cmp    $0x1f,%eax
80104f93:	0f 87 3a 01 00 00    	ja     801050d3 <trap+0x15a>
80104f99:	ff 24 85 44 6e 10 80 	jmp    *-0x7fef91bc(,%eax,4)
    if(myproc()->killed)
80104fa0:	e8 86 e3 ff ff       	call   8010332b <myproc>
80104fa5:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104fa9:	75 1f                	jne    80104fca <trap+0x51>
    myproc()->tf = tf;
80104fab:	e8 7b e3 ff ff       	call   8010332b <myproc>
80104fb0:	89 58 18             	mov    %ebx,0x18(%eax)
    syscall();
80104fb3:	e8 cf f0 ff ff       	call   80104087 <syscall>
    if(myproc()->killed)
80104fb8:	e8 6e e3 ff ff       	call   8010332b <myproc>
80104fbd:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104fc1:	74 7e                	je     80105041 <trap+0xc8>
      exit();
80104fc3:	e8 12 e7 ff ff       	call   801036da <exit>
80104fc8:	eb 77                	jmp    80105041 <trap+0xc8>
      exit();
80104fca:	e8 0b e7 ff ff       	call   801036da <exit>
80104fcf:	eb da                	jmp    80104fab <trap+0x32>
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
80104fd1:	e8 3a e3 ff ff       	call   80103310 <cpuid>
80104fd6:	85 c0                	test   %eax,%eax
80104fd8:	74 6f                	je     80105049 <trap+0xd0>
      acquire(&tickslock);
      ticks++;
      wakeup(&ticks);
      release(&tickslock);
    }
    lapiceoi();
80104fda:	e8 dc d4 ff ff       	call   801024bb <lapiceoi>
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80104fdf:	e8 47 e3 ff ff       	call   8010332b <myproc>
80104fe4:	85 c0                	test   %eax,%eax
80104fe6:	74 1c                	je     80105004 <trap+0x8b>
80104fe8:	e8 3e e3 ff ff       	call   8010332b <myproc>
80104fed:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104ff1:	74 11                	je     80105004 <trap+0x8b>
80104ff3:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80104ff7:	83 e0 03             	and    $0x3,%eax
80104ffa:	66 83 f8 03          	cmp    $0x3,%ax
80104ffe:	0f 84 62 01 00 00    	je     80105166 <trap+0x1ed>
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
80105004:	e8 22 e3 ff ff       	call   8010332b <myproc>
80105009:	85 c0                	test   %eax,%eax
8010500b:	74 0f                	je     8010501c <trap+0xa3>
8010500d:	e8 19 e3 ff ff       	call   8010332b <myproc>
80105012:	83 78 0c 04          	cmpl   $0x4,0xc(%eax)
80105016:	0f 84 54 01 00 00    	je     80105170 <trap+0x1f7>
     tf->trapno == T_IRQ0+IRQ_TIMER)
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
8010501c:	e8 0a e3 ff ff       	call   8010332b <myproc>
80105021:	85 c0                	test   %eax,%eax
80105023:	74 1c                	je     80105041 <trap+0xc8>
80105025:	e8 01 e3 ff ff       	call   8010332b <myproc>
8010502a:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010502e:	74 11                	je     80105041 <trap+0xc8>
80105030:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80105034:	83 e0 03             	and    $0x3,%eax
80105037:	66 83 f8 03          	cmp    $0x3,%ax
8010503b:	0f 84 43 01 00 00    	je     80105184 <trap+0x20b>
    exit();
}
80105041:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105044:	5b                   	pop    %ebx
80105045:	5e                   	pop    %esi
80105046:	5f                   	pop    %edi
80105047:	5d                   	pop    %ebp
80105048:	c3                   	ret    
      acquire(&tickslock);
80105049:	83 ec 0c             	sub    $0xc,%esp
8010504c:	68 80 3c 19 80       	push   $0x80193c80
80105051:	e8 77 ec ff ff       	call   80103ccd <acquire>
      ticks++;
80105056:	83 05 c0 44 19 80 01 	addl   $0x1,0x801944c0
      wakeup(&ticks);
8010505d:	c7 04 24 c0 44 19 80 	movl   $0x801944c0,(%esp)
80105064:	e8 ce e8 ff ff       	call   80103937 <wakeup>
      release(&tickslock);
80105069:	c7 04 24 80 3c 19 80 	movl   $0x80193c80,(%esp)
80105070:	e8 bd ec ff ff       	call   80103d32 <release>
80105075:	83 c4 10             	add    $0x10,%esp
80105078:	e9 5d ff ff ff       	jmp    80104fda <trap+0x61>
    ideintr();
8010507d:	e8 fd cc ff ff       	call   80101d7f <ideintr>
    lapiceoi();
80105082:	e8 34 d4 ff ff       	call   801024bb <lapiceoi>
    break;
80105087:	e9 53 ff ff ff       	jmp    80104fdf <trap+0x66>
    kbdintr();
8010508c:	e8 6e d2 ff ff       	call   801022ff <kbdintr>
    lapiceoi();
80105091:	e8 25 d4 ff ff       	call   801024bb <lapiceoi>
    break;
80105096:	e9 44 ff ff ff       	jmp    80104fdf <trap+0x66>
    uartintr();
8010509b:	e8 05 02 00 00       	call   801052a5 <uartintr>
    lapiceoi();
801050a0:	e8 16 d4 ff ff       	call   801024bb <lapiceoi>
    break;
801050a5:	e9 35 ff ff ff       	jmp    80104fdf <trap+0x66>
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801050aa:	8b 7b 38             	mov    0x38(%ebx),%edi
            cpuid(), tf->cs, tf->eip);
801050ad:	0f b7 73 3c          	movzwl 0x3c(%ebx),%esi
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801050b1:	e8 5a e2 ff ff       	call   80103310 <cpuid>
801050b6:	57                   	push   %edi
801050b7:	0f b7 f6             	movzwl %si,%esi
801050ba:	56                   	push   %esi
801050bb:	50                   	push   %eax
801050bc:	68 a8 6d 10 80       	push   $0x80106da8
801050c1:	e8 45 b5 ff ff       	call   8010060b <cprintf>
    lapiceoi();
801050c6:	e8 f0 d3 ff ff       	call   801024bb <lapiceoi>
    break;
801050cb:	83 c4 10             	add    $0x10,%esp
801050ce:	e9 0c ff ff ff       	jmp    80104fdf <trap+0x66>
    if(myproc() == 0 || (tf->cs&3) == 0){
801050d3:	e8 53 e2 ff ff       	call   8010332b <myproc>
801050d8:	85 c0                	test   %eax,%eax
801050da:	74 5f                	je     8010513b <trap+0x1c2>
801050dc:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
801050e0:	74 59                	je     8010513b <trap+0x1c2>

static inline uint
rcr2(void)
{
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
801050e2:	0f 20 d7             	mov    %cr2,%edi
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801050e5:	8b 43 38             	mov    0x38(%ebx),%eax
801050e8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801050eb:	e8 20 e2 ff ff       	call   80103310 <cpuid>
801050f0:	89 45 e0             	mov    %eax,-0x20(%ebp)
801050f3:	8b 53 34             	mov    0x34(%ebx),%edx
801050f6:	89 55 dc             	mov    %edx,-0x24(%ebp)
801050f9:	8b 73 30             	mov    0x30(%ebx),%esi
            myproc()->pid, myproc()->name, tf->trapno,
801050fc:	e8 2a e2 ff ff       	call   8010332b <myproc>
80105101:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105104:	89 4d d8             	mov    %ecx,-0x28(%ebp)
80105107:	e8 1f e2 ff ff       	call   8010332b <myproc>
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010510c:	57                   	push   %edi
8010510d:	ff 75 e4             	pushl  -0x1c(%ebp)
80105110:	ff 75 e0             	pushl  -0x20(%ebp)
80105113:	ff 75 dc             	pushl  -0x24(%ebp)
80105116:	56                   	push   %esi
80105117:	ff 75 d8             	pushl  -0x28(%ebp)
8010511a:	ff 70 10             	pushl  0x10(%eax)
8010511d:	68 00 6e 10 80       	push   $0x80106e00
80105122:	e8 e4 b4 ff ff       	call   8010060b <cprintf>
    myproc()->killed = 1;
80105127:	83 c4 20             	add    $0x20,%esp
8010512a:	e8 fc e1 ff ff       	call   8010332b <myproc>
8010512f:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80105136:	e9 a4 fe ff ff       	jmp    80104fdf <trap+0x66>
8010513b:	0f 20 d7             	mov    %cr2,%edi
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
8010513e:	8b 73 38             	mov    0x38(%ebx),%esi
80105141:	e8 ca e1 ff ff       	call   80103310 <cpuid>
80105146:	83 ec 0c             	sub    $0xc,%esp
80105149:	57                   	push   %edi
8010514a:	56                   	push   %esi
8010514b:	50                   	push   %eax
8010514c:	ff 73 30             	pushl  0x30(%ebx)
8010514f:	68 cc 6d 10 80       	push   $0x80106dcc
80105154:	e8 b2 b4 ff ff       	call   8010060b <cprintf>
      panic("trap");
80105159:	83 c4 14             	add    $0x14,%esp
8010515c:	68 a2 6d 10 80       	push   $0x80106da2
80105161:	e8 e2 b1 ff ff       	call   80100348 <panic>
    exit();
80105166:	e8 6f e5 ff ff       	call   801036da <exit>
8010516b:	e9 94 fe ff ff       	jmp    80105004 <trap+0x8b>
  if(myproc() && myproc()->state == RUNNING &&
80105170:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
80105174:	0f 85 a2 fe ff ff    	jne    8010501c <trap+0xa3>
    yield();
8010517a:	e8 21 e6 ff ff       	call   801037a0 <yield>
8010517f:	e9 98 fe ff ff       	jmp    8010501c <trap+0xa3>
    exit();
80105184:	e8 51 e5 ff ff       	call   801036da <exit>
80105189:	e9 b3 fe ff ff       	jmp    80105041 <trap+0xc8>

8010518e <uartgetc>:
  outb(COM1+0, c);
}

static int
uartgetc(void)
{
8010518e:	55                   	push   %ebp
8010518f:	89 e5                	mov    %esp,%ebp
  if(!uart)
80105191:	83 3d bc 95 10 80 00 	cmpl   $0x0,0x801095bc
80105198:	74 15                	je     801051af <uartgetc+0x21>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010519a:	ba fd 03 00 00       	mov    $0x3fd,%edx
8010519f:	ec                   	in     (%dx),%al
    return -1;
  if(!(inb(COM1+5) & 0x01))
801051a0:	a8 01                	test   $0x1,%al
801051a2:	74 12                	je     801051b6 <uartgetc+0x28>
801051a4:	ba f8 03 00 00       	mov    $0x3f8,%edx
801051a9:	ec                   	in     (%dx),%al
    return -1;
  return inb(COM1+0);
801051aa:	0f b6 c0             	movzbl %al,%eax
}
801051ad:	5d                   	pop    %ebp
801051ae:	c3                   	ret    
    return -1;
801051af:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801051b4:	eb f7                	jmp    801051ad <uartgetc+0x1f>
    return -1;
801051b6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801051bb:	eb f0                	jmp    801051ad <uartgetc+0x1f>

801051bd <uartputc>:
  if(!uart)
801051bd:	83 3d bc 95 10 80 00 	cmpl   $0x0,0x801095bc
801051c4:	74 3b                	je     80105201 <uartputc+0x44>
{
801051c6:	55                   	push   %ebp
801051c7:	89 e5                	mov    %esp,%ebp
801051c9:	53                   	push   %ebx
801051ca:	83 ec 04             	sub    $0x4,%esp
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801051cd:	bb 00 00 00 00       	mov    $0x0,%ebx
801051d2:	eb 10                	jmp    801051e4 <uartputc+0x27>
    microdelay(10);
801051d4:	83 ec 0c             	sub    $0xc,%esp
801051d7:	6a 0a                	push   $0xa
801051d9:	e8 fc d2 ff ff       	call   801024da <microdelay>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801051de:	83 c3 01             	add    $0x1,%ebx
801051e1:	83 c4 10             	add    $0x10,%esp
801051e4:	83 fb 7f             	cmp    $0x7f,%ebx
801051e7:	7f 0a                	jg     801051f3 <uartputc+0x36>
801051e9:	ba fd 03 00 00       	mov    $0x3fd,%edx
801051ee:	ec                   	in     (%dx),%al
801051ef:	a8 20                	test   $0x20,%al
801051f1:	74 e1                	je     801051d4 <uartputc+0x17>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801051f3:	8b 45 08             	mov    0x8(%ebp),%eax
801051f6:	ba f8 03 00 00       	mov    $0x3f8,%edx
801051fb:	ee                   	out    %al,(%dx)
}
801051fc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801051ff:	c9                   	leave  
80105200:	c3                   	ret    
80105201:	f3 c3                	repz ret 

80105203 <uartinit>:
{
80105203:	55                   	push   %ebp
80105204:	89 e5                	mov    %esp,%ebp
80105206:	56                   	push   %esi
80105207:	53                   	push   %ebx
80105208:	b9 00 00 00 00       	mov    $0x0,%ecx
8010520d:	ba fa 03 00 00       	mov    $0x3fa,%edx
80105212:	89 c8                	mov    %ecx,%eax
80105214:	ee                   	out    %al,(%dx)
80105215:	be fb 03 00 00       	mov    $0x3fb,%esi
8010521a:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
8010521f:	89 f2                	mov    %esi,%edx
80105221:	ee                   	out    %al,(%dx)
80105222:	b8 0c 00 00 00       	mov    $0xc,%eax
80105227:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010522c:	ee                   	out    %al,(%dx)
8010522d:	bb f9 03 00 00       	mov    $0x3f9,%ebx
80105232:	89 c8                	mov    %ecx,%eax
80105234:	89 da                	mov    %ebx,%edx
80105236:	ee                   	out    %al,(%dx)
80105237:	b8 03 00 00 00       	mov    $0x3,%eax
8010523c:	89 f2                	mov    %esi,%edx
8010523e:	ee                   	out    %al,(%dx)
8010523f:	ba fc 03 00 00       	mov    $0x3fc,%edx
80105244:	89 c8                	mov    %ecx,%eax
80105246:	ee                   	out    %al,(%dx)
80105247:	b8 01 00 00 00       	mov    $0x1,%eax
8010524c:	89 da                	mov    %ebx,%edx
8010524e:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010524f:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105254:	ec                   	in     (%dx),%al
  if(inb(COM1+5) == 0xFF)
80105255:	3c ff                	cmp    $0xff,%al
80105257:	74 45                	je     8010529e <uartinit+0x9b>
  uart = 1;
80105259:	c7 05 bc 95 10 80 01 	movl   $0x1,0x801095bc
80105260:	00 00 00 
80105263:	ba fa 03 00 00       	mov    $0x3fa,%edx
80105268:	ec                   	in     (%dx),%al
80105269:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010526e:	ec                   	in     (%dx),%al
  ioapicenable(IRQ_COM1, 0);
8010526f:	83 ec 08             	sub    $0x8,%esp
80105272:	6a 00                	push   $0x0
80105274:	6a 04                	push   $0x4
80105276:	e8 0f cd ff ff       	call   80101f8a <ioapicenable>
  for(p="xv6...\n"; *p; p++)
8010527b:	83 c4 10             	add    $0x10,%esp
8010527e:	bb c4 6e 10 80       	mov    $0x80106ec4,%ebx
80105283:	eb 12                	jmp    80105297 <uartinit+0x94>
    uartputc(*p);
80105285:	83 ec 0c             	sub    $0xc,%esp
80105288:	0f be c0             	movsbl %al,%eax
8010528b:	50                   	push   %eax
8010528c:	e8 2c ff ff ff       	call   801051bd <uartputc>
  for(p="xv6...\n"; *p; p++)
80105291:	83 c3 01             	add    $0x1,%ebx
80105294:	83 c4 10             	add    $0x10,%esp
80105297:	0f b6 03             	movzbl (%ebx),%eax
8010529a:	84 c0                	test   %al,%al
8010529c:	75 e7                	jne    80105285 <uartinit+0x82>
}
8010529e:	8d 65 f8             	lea    -0x8(%ebp),%esp
801052a1:	5b                   	pop    %ebx
801052a2:	5e                   	pop    %esi
801052a3:	5d                   	pop    %ebp
801052a4:	c3                   	ret    

801052a5 <uartintr>:

void
uartintr(void)
{
801052a5:	55                   	push   %ebp
801052a6:	89 e5                	mov    %esp,%ebp
801052a8:	83 ec 14             	sub    $0x14,%esp
  consoleintr(uartgetc);
801052ab:	68 8e 51 10 80       	push   $0x8010518e
801052b0:	e8 89 b4 ff ff       	call   8010073e <consoleintr>
}
801052b5:	83 c4 10             	add    $0x10,%esp
801052b8:	c9                   	leave  
801052b9:	c3                   	ret    

801052ba <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
801052ba:	6a 00                	push   $0x0
  pushl $0
801052bc:	6a 00                	push   $0x0
  jmp alltraps
801052be:	e9 be fb ff ff       	jmp    80104e81 <alltraps>

801052c3 <vector1>:
.globl vector1
vector1:
  pushl $0
801052c3:	6a 00                	push   $0x0
  pushl $1
801052c5:	6a 01                	push   $0x1
  jmp alltraps
801052c7:	e9 b5 fb ff ff       	jmp    80104e81 <alltraps>

801052cc <vector2>:
.globl vector2
vector2:
  pushl $0
801052cc:	6a 00                	push   $0x0
  pushl $2
801052ce:	6a 02                	push   $0x2
  jmp alltraps
801052d0:	e9 ac fb ff ff       	jmp    80104e81 <alltraps>

801052d5 <vector3>:
.globl vector3
vector3:
  pushl $0
801052d5:	6a 00                	push   $0x0
  pushl $3
801052d7:	6a 03                	push   $0x3
  jmp alltraps
801052d9:	e9 a3 fb ff ff       	jmp    80104e81 <alltraps>

801052de <vector4>:
.globl vector4
vector4:
  pushl $0
801052de:	6a 00                	push   $0x0
  pushl $4
801052e0:	6a 04                	push   $0x4
  jmp alltraps
801052e2:	e9 9a fb ff ff       	jmp    80104e81 <alltraps>

801052e7 <vector5>:
.globl vector5
vector5:
  pushl $0
801052e7:	6a 00                	push   $0x0
  pushl $5
801052e9:	6a 05                	push   $0x5
  jmp alltraps
801052eb:	e9 91 fb ff ff       	jmp    80104e81 <alltraps>

801052f0 <vector6>:
.globl vector6
vector6:
  pushl $0
801052f0:	6a 00                	push   $0x0
  pushl $6
801052f2:	6a 06                	push   $0x6
  jmp alltraps
801052f4:	e9 88 fb ff ff       	jmp    80104e81 <alltraps>

801052f9 <vector7>:
.globl vector7
vector7:
  pushl $0
801052f9:	6a 00                	push   $0x0
  pushl $7
801052fb:	6a 07                	push   $0x7
  jmp alltraps
801052fd:	e9 7f fb ff ff       	jmp    80104e81 <alltraps>

80105302 <vector8>:
.globl vector8
vector8:
  pushl $8
80105302:	6a 08                	push   $0x8
  jmp alltraps
80105304:	e9 78 fb ff ff       	jmp    80104e81 <alltraps>

80105309 <vector9>:
.globl vector9
vector9:
  pushl $0
80105309:	6a 00                	push   $0x0
  pushl $9
8010530b:	6a 09                	push   $0x9
  jmp alltraps
8010530d:	e9 6f fb ff ff       	jmp    80104e81 <alltraps>

80105312 <vector10>:
.globl vector10
vector10:
  pushl $10
80105312:	6a 0a                	push   $0xa
  jmp alltraps
80105314:	e9 68 fb ff ff       	jmp    80104e81 <alltraps>

80105319 <vector11>:
.globl vector11
vector11:
  pushl $11
80105319:	6a 0b                	push   $0xb
  jmp alltraps
8010531b:	e9 61 fb ff ff       	jmp    80104e81 <alltraps>

80105320 <vector12>:
.globl vector12
vector12:
  pushl $12
80105320:	6a 0c                	push   $0xc
  jmp alltraps
80105322:	e9 5a fb ff ff       	jmp    80104e81 <alltraps>

80105327 <vector13>:
.globl vector13
vector13:
  pushl $13
80105327:	6a 0d                	push   $0xd
  jmp alltraps
80105329:	e9 53 fb ff ff       	jmp    80104e81 <alltraps>

8010532e <vector14>:
.globl vector14
vector14:
  pushl $14
8010532e:	6a 0e                	push   $0xe
  jmp alltraps
80105330:	e9 4c fb ff ff       	jmp    80104e81 <alltraps>

80105335 <vector15>:
.globl vector15
vector15:
  pushl $0
80105335:	6a 00                	push   $0x0
  pushl $15
80105337:	6a 0f                	push   $0xf
  jmp alltraps
80105339:	e9 43 fb ff ff       	jmp    80104e81 <alltraps>

8010533e <vector16>:
.globl vector16
vector16:
  pushl $0
8010533e:	6a 00                	push   $0x0
  pushl $16
80105340:	6a 10                	push   $0x10
  jmp alltraps
80105342:	e9 3a fb ff ff       	jmp    80104e81 <alltraps>

80105347 <vector17>:
.globl vector17
vector17:
  pushl $17
80105347:	6a 11                	push   $0x11
  jmp alltraps
80105349:	e9 33 fb ff ff       	jmp    80104e81 <alltraps>

8010534e <vector18>:
.globl vector18
vector18:
  pushl $0
8010534e:	6a 00                	push   $0x0
  pushl $18
80105350:	6a 12                	push   $0x12
  jmp alltraps
80105352:	e9 2a fb ff ff       	jmp    80104e81 <alltraps>

80105357 <vector19>:
.globl vector19
vector19:
  pushl $0
80105357:	6a 00                	push   $0x0
  pushl $19
80105359:	6a 13                	push   $0x13
  jmp alltraps
8010535b:	e9 21 fb ff ff       	jmp    80104e81 <alltraps>

80105360 <vector20>:
.globl vector20
vector20:
  pushl $0
80105360:	6a 00                	push   $0x0
  pushl $20
80105362:	6a 14                	push   $0x14
  jmp alltraps
80105364:	e9 18 fb ff ff       	jmp    80104e81 <alltraps>

80105369 <vector21>:
.globl vector21
vector21:
  pushl $0
80105369:	6a 00                	push   $0x0
  pushl $21
8010536b:	6a 15                	push   $0x15
  jmp alltraps
8010536d:	e9 0f fb ff ff       	jmp    80104e81 <alltraps>

80105372 <vector22>:
.globl vector22
vector22:
  pushl $0
80105372:	6a 00                	push   $0x0
  pushl $22
80105374:	6a 16                	push   $0x16
  jmp alltraps
80105376:	e9 06 fb ff ff       	jmp    80104e81 <alltraps>

8010537b <vector23>:
.globl vector23
vector23:
  pushl $0
8010537b:	6a 00                	push   $0x0
  pushl $23
8010537d:	6a 17                	push   $0x17
  jmp alltraps
8010537f:	e9 fd fa ff ff       	jmp    80104e81 <alltraps>

80105384 <vector24>:
.globl vector24
vector24:
  pushl $0
80105384:	6a 00                	push   $0x0
  pushl $24
80105386:	6a 18                	push   $0x18
  jmp alltraps
80105388:	e9 f4 fa ff ff       	jmp    80104e81 <alltraps>

8010538d <vector25>:
.globl vector25
vector25:
  pushl $0
8010538d:	6a 00                	push   $0x0
  pushl $25
8010538f:	6a 19                	push   $0x19
  jmp alltraps
80105391:	e9 eb fa ff ff       	jmp    80104e81 <alltraps>

80105396 <vector26>:
.globl vector26
vector26:
  pushl $0
80105396:	6a 00                	push   $0x0
  pushl $26
80105398:	6a 1a                	push   $0x1a
  jmp alltraps
8010539a:	e9 e2 fa ff ff       	jmp    80104e81 <alltraps>

8010539f <vector27>:
.globl vector27
vector27:
  pushl $0
8010539f:	6a 00                	push   $0x0
  pushl $27
801053a1:	6a 1b                	push   $0x1b
  jmp alltraps
801053a3:	e9 d9 fa ff ff       	jmp    80104e81 <alltraps>

801053a8 <vector28>:
.globl vector28
vector28:
  pushl $0
801053a8:	6a 00                	push   $0x0
  pushl $28
801053aa:	6a 1c                	push   $0x1c
  jmp alltraps
801053ac:	e9 d0 fa ff ff       	jmp    80104e81 <alltraps>

801053b1 <vector29>:
.globl vector29
vector29:
  pushl $0
801053b1:	6a 00                	push   $0x0
  pushl $29
801053b3:	6a 1d                	push   $0x1d
  jmp alltraps
801053b5:	e9 c7 fa ff ff       	jmp    80104e81 <alltraps>

801053ba <vector30>:
.globl vector30
vector30:
  pushl $0
801053ba:	6a 00                	push   $0x0
  pushl $30
801053bc:	6a 1e                	push   $0x1e
  jmp alltraps
801053be:	e9 be fa ff ff       	jmp    80104e81 <alltraps>

801053c3 <vector31>:
.globl vector31
vector31:
  pushl $0
801053c3:	6a 00                	push   $0x0
  pushl $31
801053c5:	6a 1f                	push   $0x1f
  jmp alltraps
801053c7:	e9 b5 fa ff ff       	jmp    80104e81 <alltraps>

801053cc <vector32>:
.globl vector32
vector32:
  pushl $0
801053cc:	6a 00                	push   $0x0
  pushl $32
801053ce:	6a 20                	push   $0x20
  jmp alltraps
801053d0:	e9 ac fa ff ff       	jmp    80104e81 <alltraps>

801053d5 <vector33>:
.globl vector33
vector33:
  pushl $0
801053d5:	6a 00                	push   $0x0
  pushl $33
801053d7:	6a 21                	push   $0x21
  jmp alltraps
801053d9:	e9 a3 fa ff ff       	jmp    80104e81 <alltraps>

801053de <vector34>:
.globl vector34
vector34:
  pushl $0
801053de:	6a 00                	push   $0x0
  pushl $34
801053e0:	6a 22                	push   $0x22
  jmp alltraps
801053e2:	e9 9a fa ff ff       	jmp    80104e81 <alltraps>

801053e7 <vector35>:
.globl vector35
vector35:
  pushl $0
801053e7:	6a 00                	push   $0x0
  pushl $35
801053e9:	6a 23                	push   $0x23
  jmp alltraps
801053eb:	e9 91 fa ff ff       	jmp    80104e81 <alltraps>

801053f0 <vector36>:
.globl vector36
vector36:
  pushl $0
801053f0:	6a 00                	push   $0x0
  pushl $36
801053f2:	6a 24                	push   $0x24
  jmp alltraps
801053f4:	e9 88 fa ff ff       	jmp    80104e81 <alltraps>

801053f9 <vector37>:
.globl vector37
vector37:
  pushl $0
801053f9:	6a 00                	push   $0x0
  pushl $37
801053fb:	6a 25                	push   $0x25
  jmp alltraps
801053fd:	e9 7f fa ff ff       	jmp    80104e81 <alltraps>

80105402 <vector38>:
.globl vector38
vector38:
  pushl $0
80105402:	6a 00                	push   $0x0
  pushl $38
80105404:	6a 26                	push   $0x26
  jmp alltraps
80105406:	e9 76 fa ff ff       	jmp    80104e81 <alltraps>

8010540b <vector39>:
.globl vector39
vector39:
  pushl $0
8010540b:	6a 00                	push   $0x0
  pushl $39
8010540d:	6a 27                	push   $0x27
  jmp alltraps
8010540f:	e9 6d fa ff ff       	jmp    80104e81 <alltraps>

80105414 <vector40>:
.globl vector40
vector40:
  pushl $0
80105414:	6a 00                	push   $0x0
  pushl $40
80105416:	6a 28                	push   $0x28
  jmp alltraps
80105418:	e9 64 fa ff ff       	jmp    80104e81 <alltraps>

8010541d <vector41>:
.globl vector41
vector41:
  pushl $0
8010541d:	6a 00                	push   $0x0
  pushl $41
8010541f:	6a 29                	push   $0x29
  jmp alltraps
80105421:	e9 5b fa ff ff       	jmp    80104e81 <alltraps>

80105426 <vector42>:
.globl vector42
vector42:
  pushl $0
80105426:	6a 00                	push   $0x0
  pushl $42
80105428:	6a 2a                	push   $0x2a
  jmp alltraps
8010542a:	e9 52 fa ff ff       	jmp    80104e81 <alltraps>

8010542f <vector43>:
.globl vector43
vector43:
  pushl $0
8010542f:	6a 00                	push   $0x0
  pushl $43
80105431:	6a 2b                	push   $0x2b
  jmp alltraps
80105433:	e9 49 fa ff ff       	jmp    80104e81 <alltraps>

80105438 <vector44>:
.globl vector44
vector44:
  pushl $0
80105438:	6a 00                	push   $0x0
  pushl $44
8010543a:	6a 2c                	push   $0x2c
  jmp alltraps
8010543c:	e9 40 fa ff ff       	jmp    80104e81 <alltraps>

80105441 <vector45>:
.globl vector45
vector45:
  pushl $0
80105441:	6a 00                	push   $0x0
  pushl $45
80105443:	6a 2d                	push   $0x2d
  jmp alltraps
80105445:	e9 37 fa ff ff       	jmp    80104e81 <alltraps>

8010544a <vector46>:
.globl vector46
vector46:
  pushl $0
8010544a:	6a 00                	push   $0x0
  pushl $46
8010544c:	6a 2e                	push   $0x2e
  jmp alltraps
8010544e:	e9 2e fa ff ff       	jmp    80104e81 <alltraps>

80105453 <vector47>:
.globl vector47
vector47:
  pushl $0
80105453:	6a 00                	push   $0x0
  pushl $47
80105455:	6a 2f                	push   $0x2f
  jmp alltraps
80105457:	e9 25 fa ff ff       	jmp    80104e81 <alltraps>

8010545c <vector48>:
.globl vector48
vector48:
  pushl $0
8010545c:	6a 00                	push   $0x0
  pushl $48
8010545e:	6a 30                	push   $0x30
  jmp alltraps
80105460:	e9 1c fa ff ff       	jmp    80104e81 <alltraps>

80105465 <vector49>:
.globl vector49
vector49:
  pushl $0
80105465:	6a 00                	push   $0x0
  pushl $49
80105467:	6a 31                	push   $0x31
  jmp alltraps
80105469:	e9 13 fa ff ff       	jmp    80104e81 <alltraps>

8010546e <vector50>:
.globl vector50
vector50:
  pushl $0
8010546e:	6a 00                	push   $0x0
  pushl $50
80105470:	6a 32                	push   $0x32
  jmp alltraps
80105472:	e9 0a fa ff ff       	jmp    80104e81 <alltraps>

80105477 <vector51>:
.globl vector51
vector51:
  pushl $0
80105477:	6a 00                	push   $0x0
  pushl $51
80105479:	6a 33                	push   $0x33
  jmp alltraps
8010547b:	e9 01 fa ff ff       	jmp    80104e81 <alltraps>

80105480 <vector52>:
.globl vector52
vector52:
  pushl $0
80105480:	6a 00                	push   $0x0
  pushl $52
80105482:	6a 34                	push   $0x34
  jmp alltraps
80105484:	e9 f8 f9 ff ff       	jmp    80104e81 <alltraps>

80105489 <vector53>:
.globl vector53
vector53:
  pushl $0
80105489:	6a 00                	push   $0x0
  pushl $53
8010548b:	6a 35                	push   $0x35
  jmp alltraps
8010548d:	e9 ef f9 ff ff       	jmp    80104e81 <alltraps>

80105492 <vector54>:
.globl vector54
vector54:
  pushl $0
80105492:	6a 00                	push   $0x0
  pushl $54
80105494:	6a 36                	push   $0x36
  jmp alltraps
80105496:	e9 e6 f9 ff ff       	jmp    80104e81 <alltraps>

8010549b <vector55>:
.globl vector55
vector55:
  pushl $0
8010549b:	6a 00                	push   $0x0
  pushl $55
8010549d:	6a 37                	push   $0x37
  jmp alltraps
8010549f:	e9 dd f9 ff ff       	jmp    80104e81 <alltraps>

801054a4 <vector56>:
.globl vector56
vector56:
  pushl $0
801054a4:	6a 00                	push   $0x0
  pushl $56
801054a6:	6a 38                	push   $0x38
  jmp alltraps
801054a8:	e9 d4 f9 ff ff       	jmp    80104e81 <alltraps>

801054ad <vector57>:
.globl vector57
vector57:
  pushl $0
801054ad:	6a 00                	push   $0x0
  pushl $57
801054af:	6a 39                	push   $0x39
  jmp alltraps
801054b1:	e9 cb f9 ff ff       	jmp    80104e81 <alltraps>

801054b6 <vector58>:
.globl vector58
vector58:
  pushl $0
801054b6:	6a 00                	push   $0x0
  pushl $58
801054b8:	6a 3a                	push   $0x3a
  jmp alltraps
801054ba:	e9 c2 f9 ff ff       	jmp    80104e81 <alltraps>

801054bf <vector59>:
.globl vector59
vector59:
  pushl $0
801054bf:	6a 00                	push   $0x0
  pushl $59
801054c1:	6a 3b                	push   $0x3b
  jmp alltraps
801054c3:	e9 b9 f9 ff ff       	jmp    80104e81 <alltraps>

801054c8 <vector60>:
.globl vector60
vector60:
  pushl $0
801054c8:	6a 00                	push   $0x0
  pushl $60
801054ca:	6a 3c                	push   $0x3c
  jmp alltraps
801054cc:	e9 b0 f9 ff ff       	jmp    80104e81 <alltraps>

801054d1 <vector61>:
.globl vector61
vector61:
  pushl $0
801054d1:	6a 00                	push   $0x0
  pushl $61
801054d3:	6a 3d                	push   $0x3d
  jmp alltraps
801054d5:	e9 a7 f9 ff ff       	jmp    80104e81 <alltraps>

801054da <vector62>:
.globl vector62
vector62:
  pushl $0
801054da:	6a 00                	push   $0x0
  pushl $62
801054dc:	6a 3e                	push   $0x3e
  jmp alltraps
801054de:	e9 9e f9 ff ff       	jmp    80104e81 <alltraps>

801054e3 <vector63>:
.globl vector63
vector63:
  pushl $0
801054e3:	6a 00                	push   $0x0
  pushl $63
801054e5:	6a 3f                	push   $0x3f
  jmp alltraps
801054e7:	e9 95 f9 ff ff       	jmp    80104e81 <alltraps>

801054ec <vector64>:
.globl vector64
vector64:
  pushl $0
801054ec:	6a 00                	push   $0x0
  pushl $64
801054ee:	6a 40                	push   $0x40
  jmp alltraps
801054f0:	e9 8c f9 ff ff       	jmp    80104e81 <alltraps>

801054f5 <vector65>:
.globl vector65
vector65:
  pushl $0
801054f5:	6a 00                	push   $0x0
  pushl $65
801054f7:	6a 41                	push   $0x41
  jmp alltraps
801054f9:	e9 83 f9 ff ff       	jmp    80104e81 <alltraps>

801054fe <vector66>:
.globl vector66
vector66:
  pushl $0
801054fe:	6a 00                	push   $0x0
  pushl $66
80105500:	6a 42                	push   $0x42
  jmp alltraps
80105502:	e9 7a f9 ff ff       	jmp    80104e81 <alltraps>

80105507 <vector67>:
.globl vector67
vector67:
  pushl $0
80105507:	6a 00                	push   $0x0
  pushl $67
80105509:	6a 43                	push   $0x43
  jmp alltraps
8010550b:	e9 71 f9 ff ff       	jmp    80104e81 <alltraps>

80105510 <vector68>:
.globl vector68
vector68:
  pushl $0
80105510:	6a 00                	push   $0x0
  pushl $68
80105512:	6a 44                	push   $0x44
  jmp alltraps
80105514:	e9 68 f9 ff ff       	jmp    80104e81 <alltraps>

80105519 <vector69>:
.globl vector69
vector69:
  pushl $0
80105519:	6a 00                	push   $0x0
  pushl $69
8010551b:	6a 45                	push   $0x45
  jmp alltraps
8010551d:	e9 5f f9 ff ff       	jmp    80104e81 <alltraps>

80105522 <vector70>:
.globl vector70
vector70:
  pushl $0
80105522:	6a 00                	push   $0x0
  pushl $70
80105524:	6a 46                	push   $0x46
  jmp alltraps
80105526:	e9 56 f9 ff ff       	jmp    80104e81 <alltraps>

8010552b <vector71>:
.globl vector71
vector71:
  pushl $0
8010552b:	6a 00                	push   $0x0
  pushl $71
8010552d:	6a 47                	push   $0x47
  jmp alltraps
8010552f:	e9 4d f9 ff ff       	jmp    80104e81 <alltraps>

80105534 <vector72>:
.globl vector72
vector72:
  pushl $0
80105534:	6a 00                	push   $0x0
  pushl $72
80105536:	6a 48                	push   $0x48
  jmp alltraps
80105538:	e9 44 f9 ff ff       	jmp    80104e81 <alltraps>

8010553d <vector73>:
.globl vector73
vector73:
  pushl $0
8010553d:	6a 00                	push   $0x0
  pushl $73
8010553f:	6a 49                	push   $0x49
  jmp alltraps
80105541:	e9 3b f9 ff ff       	jmp    80104e81 <alltraps>

80105546 <vector74>:
.globl vector74
vector74:
  pushl $0
80105546:	6a 00                	push   $0x0
  pushl $74
80105548:	6a 4a                	push   $0x4a
  jmp alltraps
8010554a:	e9 32 f9 ff ff       	jmp    80104e81 <alltraps>

8010554f <vector75>:
.globl vector75
vector75:
  pushl $0
8010554f:	6a 00                	push   $0x0
  pushl $75
80105551:	6a 4b                	push   $0x4b
  jmp alltraps
80105553:	e9 29 f9 ff ff       	jmp    80104e81 <alltraps>

80105558 <vector76>:
.globl vector76
vector76:
  pushl $0
80105558:	6a 00                	push   $0x0
  pushl $76
8010555a:	6a 4c                	push   $0x4c
  jmp alltraps
8010555c:	e9 20 f9 ff ff       	jmp    80104e81 <alltraps>

80105561 <vector77>:
.globl vector77
vector77:
  pushl $0
80105561:	6a 00                	push   $0x0
  pushl $77
80105563:	6a 4d                	push   $0x4d
  jmp alltraps
80105565:	e9 17 f9 ff ff       	jmp    80104e81 <alltraps>

8010556a <vector78>:
.globl vector78
vector78:
  pushl $0
8010556a:	6a 00                	push   $0x0
  pushl $78
8010556c:	6a 4e                	push   $0x4e
  jmp alltraps
8010556e:	e9 0e f9 ff ff       	jmp    80104e81 <alltraps>

80105573 <vector79>:
.globl vector79
vector79:
  pushl $0
80105573:	6a 00                	push   $0x0
  pushl $79
80105575:	6a 4f                	push   $0x4f
  jmp alltraps
80105577:	e9 05 f9 ff ff       	jmp    80104e81 <alltraps>

8010557c <vector80>:
.globl vector80
vector80:
  pushl $0
8010557c:	6a 00                	push   $0x0
  pushl $80
8010557e:	6a 50                	push   $0x50
  jmp alltraps
80105580:	e9 fc f8 ff ff       	jmp    80104e81 <alltraps>

80105585 <vector81>:
.globl vector81
vector81:
  pushl $0
80105585:	6a 00                	push   $0x0
  pushl $81
80105587:	6a 51                	push   $0x51
  jmp alltraps
80105589:	e9 f3 f8 ff ff       	jmp    80104e81 <alltraps>

8010558e <vector82>:
.globl vector82
vector82:
  pushl $0
8010558e:	6a 00                	push   $0x0
  pushl $82
80105590:	6a 52                	push   $0x52
  jmp alltraps
80105592:	e9 ea f8 ff ff       	jmp    80104e81 <alltraps>

80105597 <vector83>:
.globl vector83
vector83:
  pushl $0
80105597:	6a 00                	push   $0x0
  pushl $83
80105599:	6a 53                	push   $0x53
  jmp alltraps
8010559b:	e9 e1 f8 ff ff       	jmp    80104e81 <alltraps>

801055a0 <vector84>:
.globl vector84
vector84:
  pushl $0
801055a0:	6a 00                	push   $0x0
  pushl $84
801055a2:	6a 54                	push   $0x54
  jmp alltraps
801055a4:	e9 d8 f8 ff ff       	jmp    80104e81 <alltraps>

801055a9 <vector85>:
.globl vector85
vector85:
  pushl $0
801055a9:	6a 00                	push   $0x0
  pushl $85
801055ab:	6a 55                	push   $0x55
  jmp alltraps
801055ad:	e9 cf f8 ff ff       	jmp    80104e81 <alltraps>

801055b2 <vector86>:
.globl vector86
vector86:
  pushl $0
801055b2:	6a 00                	push   $0x0
  pushl $86
801055b4:	6a 56                	push   $0x56
  jmp alltraps
801055b6:	e9 c6 f8 ff ff       	jmp    80104e81 <alltraps>

801055bb <vector87>:
.globl vector87
vector87:
  pushl $0
801055bb:	6a 00                	push   $0x0
  pushl $87
801055bd:	6a 57                	push   $0x57
  jmp alltraps
801055bf:	e9 bd f8 ff ff       	jmp    80104e81 <alltraps>

801055c4 <vector88>:
.globl vector88
vector88:
  pushl $0
801055c4:	6a 00                	push   $0x0
  pushl $88
801055c6:	6a 58                	push   $0x58
  jmp alltraps
801055c8:	e9 b4 f8 ff ff       	jmp    80104e81 <alltraps>

801055cd <vector89>:
.globl vector89
vector89:
  pushl $0
801055cd:	6a 00                	push   $0x0
  pushl $89
801055cf:	6a 59                	push   $0x59
  jmp alltraps
801055d1:	e9 ab f8 ff ff       	jmp    80104e81 <alltraps>

801055d6 <vector90>:
.globl vector90
vector90:
  pushl $0
801055d6:	6a 00                	push   $0x0
  pushl $90
801055d8:	6a 5a                	push   $0x5a
  jmp alltraps
801055da:	e9 a2 f8 ff ff       	jmp    80104e81 <alltraps>

801055df <vector91>:
.globl vector91
vector91:
  pushl $0
801055df:	6a 00                	push   $0x0
  pushl $91
801055e1:	6a 5b                	push   $0x5b
  jmp alltraps
801055e3:	e9 99 f8 ff ff       	jmp    80104e81 <alltraps>

801055e8 <vector92>:
.globl vector92
vector92:
  pushl $0
801055e8:	6a 00                	push   $0x0
  pushl $92
801055ea:	6a 5c                	push   $0x5c
  jmp alltraps
801055ec:	e9 90 f8 ff ff       	jmp    80104e81 <alltraps>

801055f1 <vector93>:
.globl vector93
vector93:
  pushl $0
801055f1:	6a 00                	push   $0x0
  pushl $93
801055f3:	6a 5d                	push   $0x5d
  jmp alltraps
801055f5:	e9 87 f8 ff ff       	jmp    80104e81 <alltraps>

801055fa <vector94>:
.globl vector94
vector94:
  pushl $0
801055fa:	6a 00                	push   $0x0
  pushl $94
801055fc:	6a 5e                	push   $0x5e
  jmp alltraps
801055fe:	e9 7e f8 ff ff       	jmp    80104e81 <alltraps>

80105603 <vector95>:
.globl vector95
vector95:
  pushl $0
80105603:	6a 00                	push   $0x0
  pushl $95
80105605:	6a 5f                	push   $0x5f
  jmp alltraps
80105607:	e9 75 f8 ff ff       	jmp    80104e81 <alltraps>

8010560c <vector96>:
.globl vector96
vector96:
  pushl $0
8010560c:	6a 00                	push   $0x0
  pushl $96
8010560e:	6a 60                	push   $0x60
  jmp alltraps
80105610:	e9 6c f8 ff ff       	jmp    80104e81 <alltraps>

80105615 <vector97>:
.globl vector97
vector97:
  pushl $0
80105615:	6a 00                	push   $0x0
  pushl $97
80105617:	6a 61                	push   $0x61
  jmp alltraps
80105619:	e9 63 f8 ff ff       	jmp    80104e81 <alltraps>

8010561e <vector98>:
.globl vector98
vector98:
  pushl $0
8010561e:	6a 00                	push   $0x0
  pushl $98
80105620:	6a 62                	push   $0x62
  jmp alltraps
80105622:	e9 5a f8 ff ff       	jmp    80104e81 <alltraps>

80105627 <vector99>:
.globl vector99
vector99:
  pushl $0
80105627:	6a 00                	push   $0x0
  pushl $99
80105629:	6a 63                	push   $0x63
  jmp alltraps
8010562b:	e9 51 f8 ff ff       	jmp    80104e81 <alltraps>

80105630 <vector100>:
.globl vector100
vector100:
  pushl $0
80105630:	6a 00                	push   $0x0
  pushl $100
80105632:	6a 64                	push   $0x64
  jmp alltraps
80105634:	e9 48 f8 ff ff       	jmp    80104e81 <alltraps>

80105639 <vector101>:
.globl vector101
vector101:
  pushl $0
80105639:	6a 00                	push   $0x0
  pushl $101
8010563b:	6a 65                	push   $0x65
  jmp alltraps
8010563d:	e9 3f f8 ff ff       	jmp    80104e81 <alltraps>

80105642 <vector102>:
.globl vector102
vector102:
  pushl $0
80105642:	6a 00                	push   $0x0
  pushl $102
80105644:	6a 66                	push   $0x66
  jmp alltraps
80105646:	e9 36 f8 ff ff       	jmp    80104e81 <alltraps>

8010564b <vector103>:
.globl vector103
vector103:
  pushl $0
8010564b:	6a 00                	push   $0x0
  pushl $103
8010564d:	6a 67                	push   $0x67
  jmp alltraps
8010564f:	e9 2d f8 ff ff       	jmp    80104e81 <alltraps>

80105654 <vector104>:
.globl vector104
vector104:
  pushl $0
80105654:	6a 00                	push   $0x0
  pushl $104
80105656:	6a 68                	push   $0x68
  jmp alltraps
80105658:	e9 24 f8 ff ff       	jmp    80104e81 <alltraps>

8010565d <vector105>:
.globl vector105
vector105:
  pushl $0
8010565d:	6a 00                	push   $0x0
  pushl $105
8010565f:	6a 69                	push   $0x69
  jmp alltraps
80105661:	e9 1b f8 ff ff       	jmp    80104e81 <alltraps>

80105666 <vector106>:
.globl vector106
vector106:
  pushl $0
80105666:	6a 00                	push   $0x0
  pushl $106
80105668:	6a 6a                	push   $0x6a
  jmp alltraps
8010566a:	e9 12 f8 ff ff       	jmp    80104e81 <alltraps>

8010566f <vector107>:
.globl vector107
vector107:
  pushl $0
8010566f:	6a 00                	push   $0x0
  pushl $107
80105671:	6a 6b                	push   $0x6b
  jmp alltraps
80105673:	e9 09 f8 ff ff       	jmp    80104e81 <alltraps>

80105678 <vector108>:
.globl vector108
vector108:
  pushl $0
80105678:	6a 00                	push   $0x0
  pushl $108
8010567a:	6a 6c                	push   $0x6c
  jmp alltraps
8010567c:	e9 00 f8 ff ff       	jmp    80104e81 <alltraps>

80105681 <vector109>:
.globl vector109
vector109:
  pushl $0
80105681:	6a 00                	push   $0x0
  pushl $109
80105683:	6a 6d                	push   $0x6d
  jmp alltraps
80105685:	e9 f7 f7 ff ff       	jmp    80104e81 <alltraps>

8010568a <vector110>:
.globl vector110
vector110:
  pushl $0
8010568a:	6a 00                	push   $0x0
  pushl $110
8010568c:	6a 6e                	push   $0x6e
  jmp alltraps
8010568e:	e9 ee f7 ff ff       	jmp    80104e81 <alltraps>

80105693 <vector111>:
.globl vector111
vector111:
  pushl $0
80105693:	6a 00                	push   $0x0
  pushl $111
80105695:	6a 6f                	push   $0x6f
  jmp alltraps
80105697:	e9 e5 f7 ff ff       	jmp    80104e81 <alltraps>

8010569c <vector112>:
.globl vector112
vector112:
  pushl $0
8010569c:	6a 00                	push   $0x0
  pushl $112
8010569e:	6a 70                	push   $0x70
  jmp alltraps
801056a0:	e9 dc f7 ff ff       	jmp    80104e81 <alltraps>

801056a5 <vector113>:
.globl vector113
vector113:
  pushl $0
801056a5:	6a 00                	push   $0x0
  pushl $113
801056a7:	6a 71                	push   $0x71
  jmp alltraps
801056a9:	e9 d3 f7 ff ff       	jmp    80104e81 <alltraps>

801056ae <vector114>:
.globl vector114
vector114:
  pushl $0
801056ae:	6a 00                	push   $0x0
  pushl $114
801056b0:	6a 72                	push   $0x72
  jmp alltraps
801056b2:	e9 ca f7 ff ff       	jmp    80104e81 <alltraps>

801056b7 <vector115>:
.globl vector115
vector115:
  pushl $0
801056b7:	6a 00                	push   $0x0
  pushl $115
801056b9:	6a 73                	push   $0x73
  jmp alltraps
801056bb:	e9 c1 f7 ff ff       	jmp    80104e81 <alltraps>

801056c0 <vector116>:
.globl vector116
vector116:
  pushl $0
801056c0:	6a 00                	push   $0x0
  pushl $116
801056c2:	6a 74                	push   $0x74
  jmp alltraps
801056c4:	e9 b8 f7 ff ff       	jmp    80104e81 <alltraps>

801056c9 <vector117>:
.globl vector117
vector117:
  pushl $0
801056c9:	6a 00                	push   $0x0
  pushl $117
801056cb:	6a 75                	push   $0x75
  jmp alltraps
801056cd:	e9 af f7 ff ff       	jmp    80104e81 <alltraps>

801056d2 <vector118>:
.globl vector118
vector118:
  pushl $0
801056d2:	6a 00                	push   $0x0
  pushl $118
801056d4:	6a 76                	push   $0x76
  jmp alltraps
801056d6:	e9 a6 f7 ff ff       	jmp    80104e81 <alltraps>

801056db <vector119>:
.globl vector119
vector119:
  pushl $0
801056db:	6a 00                	push   $0x0
  pushl $119
801056dd:	6a 77                	push   $0x77
  jmp alltraps
801056df:	e9 9d f7 ff ff       	jmp    80104e81 <alltraps>

801056e4 <vector120>:
.globl vector120
vector120:
  pushl $0
801056e4:	6a 00                	push   $0x0
  pushl $120
801056e6:	6a 78                	push   $0x78
  jmp alltraps
801056e8:	e9 94 f7 ff ff       	jmp    80104e81 <alltraps>

801056ed <vector121>:
.globl vector121
vector121:
  pushl $0
801056ed:	6a 00                	push   $0x0
  pushl $121
801056ef:	6a 79                	push   $0x79
  jmp alltraps
801056f1:	e9 8b f7 ff ff       	jmp    80104e81 <alltraps>

801056f6 <vector122>:
.globl vector122
vector122:
  pushl $0
801056f6:	6a 00                	push   $0x0
  pushl $122
801056f8:	6a 7a                	push   $0x7a
  jmp alltraps
801056fa:	e9 82 f7 ff ff       	jmp    80104e81 <alltraps>

801056ff <vector123>:
.globl vector123
vector123:
  pushl $0
801056ff:	6a 00                	push   $0x0
  pushl $123
80105701:	6a 7b                	push   $0x7b
  jmp alltraps
80105703:	e9 79 f7 ff ff       	jmp    80104e81 <alltraps>

80105708 <vector124>:
.globl vector124
vector124:
  pushl $0
80105708:	6a 00                	push   $0x0
  pushl $124
8010570a:	6a 7c                	push   $0x7c
  jmp alltraps
8010570c:	e9 70 f7 ff ff       	jmp    80104e81 <alltraps>

80105711 <vector125>:
.globl vector125
vector125:
  pushl $0
80105711:	6a 00                	push   $0x0
  pushl $125
80105713:	6a 7d                	push   $0x7d
  jmp alltraps
80105715:	e9 67 f7 ff ff       	jmp    80104e81 <alltraps>

8010571a <vector126>:
.globl vector126
vector126:
  pushl $0
8010571a:	6a 00                	push   $0x0
  pushl $126
8010571c:	6a 7e                	push   $0x7e
  jmp alltraps
8010571e:	e9 5e f7 ff ff       	jmp    80104e81 <alltraps>

80105723 <vector127>:
.globl vector127
vector127:
  pushl $0
80105723:	6a 00                	push   $0x0
  pushl $127
80105725:	6a 7f                	push   $0x7f
  jmp alltraps
80105727:	e9 55 f7 ff ff       	jmp    80104e81 <alltraps>

8010572c <vector128>:
.globl vector128
vector128:
  pushl $0
8010572c:	6a 00                	push   $0x0
  pushl $128
8010572e:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80105733:	e9 49 f7 ff ff       	jmp    80104e81 <alltraps>

80105738 <vector129>:
.globl vector129
vector129:
  pushl $0
80105738:	6a 00                	push   $0x0
  pushl $129
8010573a:	68 81 00 00 00       	push   $0x81
  jmp alltraps
8010573f:	e9 3d f7 ff ff       	jmp    80104e81 <alltraps>

80105744 <vector130>:
.globl vector130
vector130:
  pushl $0
80105744:	6a 00                	push   $0x0
  pushl $130
80105746:	68 82 00 00 00       	push   $0x82
  jmp alltraps
8010574b:	e9 31 f7 ff ff       	jmp    80104e81 <alltraps>

80105750 <vector131>:
.globl vector131
vector131:
  pushl $0
80105750:	6a 00                	push   $0x0
  pushl $131
80105752:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80105757:	e9 25 f7 ff ff       	jmp    80104e81 <alltraps>

8010575c <vector132>:
.globl vector132
vector132:
  pushl $0
8010575c:	6a 00                	push   $0x0
  pushl $132
8010575e:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80105763:	e9 19 f7 ff ff       	jmp    80104e81 <alltraps>

80105768 <vector133>:
.globl vector133
vector133:
  pushl $0
80105768:	6a 00                	push   $0x0
  pushl $133
8010576a:	68 85 00 00 00       	push   $0x85
  jmp alltraps
8010576f:	e9 0d f7 ff ff       	jmp    80104e81 <alltraps>

80105774 <vector134>:
.globl vector134
vector134:
  pushl $0
80105774:	6a 00                	push   $0x0
  pushl $134
80105776:	68 86 00 00 00       	push   $0x86
  jmp alltraps
8010577b:	e9 01 f7 ff ff       	jmp    80104e81 <alltraps>

80105780 <vector135>:
.globl vector135
vector135:
  pushl $0
80105780:	6a 00                	push   $0x0
  pushl $135
80105782:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80105787:	e9 f5 f6 ff ff       	jmp    80104e81 <alltraps>

8010578c <vector136>:
.globl vector136
vector136:
  pushl $0
8010578c:	6a 00                	push   $0x0
  pushl $136
8010578e:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80105793:	e9 e9 f6 ff ff       	jmp    80104e81 <alltraps>

80105798 <vector137>:
.globl vector137
vector137:
  pushl $0
80105798:	6a 00                	push   $0x0
  pushl $137
8010579a:	68 89 00 00 00       	push   $0x89
  jmp alltraps
8010579f:	e9 dd f6 ff ff       	jmp    80104e81 <alltraps>

801057a4 <vector138>:
.globl vector138
vector138:
  pushl $0
801057a4:	6a 00                	push   $0x0
  pushl $138
801057a6:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
801057ab:	e9 d1 f6 ff ff       	jmp    80104e81 <alltraps>

801057b0 <vector139>:
.globl vector139
vector139:
  pushl $0
801057b0:	6a 00                	push   $0x0
  pushl $139
801057b2:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
801057b7:	e9 c5 f6 ff ff       	jmp    80104e81 <alltraps>

801057bc <vector140>:
.globl vector140
vector140:
  pushl $0
801057bc:	6a 00                	push   $0x0
  pushl $140
801057be:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
801057c3:	e9 b9 f6 ff ff       	jmp    80104e81 <alltraps>

801057c8 <vector141>:
.globl vector141
vector141:
  pushl $0
801057c8:	6a 00                	push   $0x0
  pushl $141
801057ca:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
801057cf:	e9 ad f6 ff ff       	jmp    80104e81 <alltraps>

801057d4 <vector142>:
.globl vector142
vector142:
  pushl $0
801057d4:	6a 00                	push   $0x0
  pushl $142
801057d6:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
801057db:	e9 a1 f6 ff ff       	jmp    80104e81 <alltraps>

801057e0 <vector143>:
.globl vector143
vector143:
  pushl $0
801057e0:	6a 00                	push   $0x0
  pushl $143
801057e2:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
801057e7:	e9 95 f6 ff ff       	jmp    80104e81 <alltraps>

801057ec <vector144>:
.globl vector144
vector144:
  pushl $0
801057ec:	6a 00                	push   $0x0
  pushl $144
801057ee:	68 90 00 00 00       	push   $0x90
  jmp alltraps
801057f3:	e9 89 f6 ff ff       	jmp    80104e81 <alltraps>

801057f8 <vector145>:
.globl vector145
vector145:
  pushl $0
801057f8:	6a 00                	push   $0x0
  pushl $145
801057fa:	68 91 00 00 00       	push   $0x91
  jmp alltraps
801057ff:	e9 7d f6 ff ff       	jmp    80104e81 <alltraps>

80105804 <vector146>:
.globl vector146
vector146:
  pushl $0
80105804:	6a 00                	push   $0x0
  pushl $146
80105806:	68 92 00 00 00       	push   $0x92
  jmp alltraps
8010580b:	e9 71 f6 ff ff       	jmp    80104e81 <alltraps>

80105810 <vector147>:
.globl vector147
vector147:
  pushl $0
80105810:	6a 00                	push   $0x0
  pushl $147
80105812:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80105817:	e9 65 f6 ff ff       	jmp    80104e81 <alltraps>

8010581c <vector148>:
.globl vector148
vector148:
  pushl $0
8010581c:	6a 00                	push   $0x0
  pushl $148
8010581e:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80105823:	e9 59 f6 ff ff       	jmp    80104e81 <alltraps>

80105828 <vector149>:
.globl vector149
vector149:
  pushl $0
80105828:	6a 00                	push   $0x0
  pushl $149
8010582a:	68 95 00 00 00       	push   $0x95
  jmp alltraps
8010582f:	e9 4d f6 ff ff       	jmp    80104e81 <alltraps>

80105834 <vector150>:
.globl vector150
vector150:
  pushl $0
80105834:	6a 00                	push   $0x0
  pushl $150
80105836:	68 96 00 00 00       	push   $0x96
  jmp alltraps
8010583b:	e9 41 f6 ff ff       	jmp    80104e81 <alltraps>

80105840 <vector151>:
.globl vector151
vector151:
  pushl $0
80105840:	6a 00                	push   $0x0
  pushl $151
80105842:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80105847:	e9 35 f6 ff ff       	jmp    80104e81 <alltraps>

8010584c <vector152>:
.globl vector152
vector152:
  pushl $0
8010584c:	6a 00                	push   $0x0
  pushl $152
8010584e:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80105853:	e9 29 f6 ff ff       	jmp    80104e81 <alltraps>

80105858 <vector153>:
.globl vector153
vector153:
  pushl $0
80105858:	6a 00                	push   $0x0
  pushl $153
8010585a:	68 99 00 00 00       	push   $0x99
  jmp alltraps
8010585f:	e9 1d f6 ff ff       	jmp    80104e81 <alltraps>

80105864 <vector154>:
.globl vector154
vector154:
  pushl $0
80105864:	6a 00                	push   $0x0
  pushl $154
80105866:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
8010586b:	e9 11 f6 ff ff       	jmp    80104e81 <alltraps>

80105870 <vector155>:
.globl vector155
vector155:
  pushl $0
80105870:	6a 00                	push   $0x0
  pushl $155
80105872:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80105877:	e9 05 f6 ff ff       	jmp    80104e81 <alltraps>

8010587c <vector156>:
.globl vector156
vector156:
  pushl $0
8010587c:	6a 00                	push   $0x0
  pushl $156
8010587e:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80105883:	e9 f9 f5 ff ff       	jmp    80104e81 <alltraps>

80105888 <vector157>:
.globl vector157
vector157:
  pushl $0
80105888:	6a 00                	push   $0x0
  pushl $157
8010588a:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
8010588f:	e9 ed f5 ff ff       	jmp    80104e81 <alltraps>

80105894 <vector158>:
.globl vector158
vector158:
  pushl $0
80105894:	6a 00                	push   $0x0
  pushl $158
80105896:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
8010589b:	e9 e1 f5 ff ff       	jmp    80104e81 <alltraps>

801058a0 <vector159>:
.globl vector159
vector159:
  pushl $0
801058a0:	6a 00                	push   $0x0
  pushl $159
801058a2:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
801058a7:	e9 d5 f5 ff ff       	jmp    80104e81 <alltraps>

801058ac <vector160>:
.globl vector160
vector160:
  pushl $0
801058ac:	6a 00                	push   $0x0
  pushl $160
801058ae:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
801058b3:	e9 c9 f5 ff ff       	jmp    80104e81 <alltraps>

801058b8 <vector161>:
.globl vector161
vector161:
  pushl $0
801058b8:	6a 00                	push   $0x0
  pushl $161
801058ba:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
801058bf:	e9 bd f5 ff ff       	jmp    80104e81 <alltraps>

801058c4 <vector162>:
.globl vector162
vector162:
  pushl $0
801058c4:	6a 00                	push   $0x0
  pushl $162
801058c6:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
801058cb:	e9 b1 f5 ff ff       	jmp    80104e81 <alltraps>

801058d0 <vector163>:
.globl vector163
vector163:
  pushl $0
801058d0:	6a 00                	push   $0x0
  pushl $163
801058d2:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
801058d7:	e9 a5 f5 ff ff       	jmp    80104e81 <alltraps>

801058dc <vector164>:
.globl vector164
vector164:
  pushl $0
801058dc:	6a 00                	push   $0x0
  pushl $164
801058de:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
801058e3:	e9 99 f5 ff ff       	jmp    80104e81 <alltraps>

801058e8 <vector165>:
.globl vector165
vector165:
  pushl $0
801058e8:	6a 00                	push   $0x0
  pushl $165
801058ea:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
801058ef:	e9 8d f5 ff ff       	jmp    80104e81 <alltraps>

801058f4 <vector166>:
.globl vector166
vector166:
  pushl $0
801058f4:	6a 00                	push   $0x0
  pushl $166
801058f6:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
801058fb:	e9 81 f5 ff ff       	jmp    80104e81 <alltraps>

80105900 <vector167>:
.globl vector167
vector167:
  pushl $0
80105900:	6a 00                	push   $0x0
  pushl $167
80105902:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80105907:	e9 75 f5 ff ff       	jmp    80104e81 <alltraps>

8010590c <vector168>:
.globl vector168
vector168:
  pushl $0
8010590c:	6a 00                	push   $0x0
  pushl $168
8010590e:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80105913:	e9 69 f5 ff ff       	jmp    80104e81 <alltraps>

80105918 <vector169>:
.globl vector169
vector169:
  pushl $0
80105918:	6a 00                	push   $0x0
  pushl $169
8010591a:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
8010591f:	e9 5d f5 ff ff       	jmp    80104e81 <alltraps>

80105924 <vector170>:
.globl vector170
vector170:
  pushl $0
80105924:	6a 00                	push   $0x0
  pushl $170
80105926:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
8010592b:	e9 51 f5 ff ff       	jmp    80104e81 <alltraps>

80105930 <vector171>:
.globl vector171
vector171:
  pushl $0
80105930:	6a 00                	push   $0x0
  pushl $171
80105932:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80105937:	e9 45 f5 ff ff       	jmp    80104e81 <alltraps>

8010593c <vector172>:
.globl vector172
vector172:
  pushl $0
8010593c:	6a 00                	push   $0x0
  pushl $172
8010593e:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80105943:	e9 39 f5 ff ff       	jmp    80104e81 <alltraps>

80105948 <vector173>:
.globl vector173
vector173:
  pushl $0
80105948:	6a 00                	push   $0x0
  pushl $173
8010594a:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
8010594f:	e9 2d f5 ff ff       	jmp    80104e81 <alltraps>

80105954 <vector174>:
.globl vector174
vector174:
  pushl $0
80105954:	6a 00                	push   $0x0
  pushl $174
80105956:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
8010595b:	e9 21 f5 ff ff       	jmp    80104e81 <alltraps>

80105960 <vector175>:
.globl vector175
vector175:
  pushl $0
80105960:	6a 00                	push   $0x0
  pushl $175
80105962:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80105967:	e9 15 f5 ff ff       	jmp    80104e81 <alltraps>

8010596c <vector176>:
.globl vector176
vector176:
  pushl $0
8010596c:	6a 00                	push   $0x0
  pushl $176
8010596e:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80105973:	e9 09 f5 ff ff       	jmp    80104e81 <alltraps>

80105978 <vector177>:
.globl vector177
vector177:
  pushl $0
80105978:	6a 00                	push   $0x0
  pushl $177
8010597a:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
8010597f:	e9 fd f4 ff ff       	jmp    80104e81 <alltraps>

80105984 <vector178>:
.globl vector178
vector178:
  pushl $0
80105984:	6a 00                	push   $0x0
  pushl $178
80105986:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
8010598b:	e9 f1 f4 ff ff       	jmp    80104e81 <alltraps>

80105990 <vector179>:
.globl vector179
vector179:
  pushl $0
80105990:	6a 00                	push   $0x0
  pushl $179
80105992:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80105997:	e9 e5 f4 ff ff       	jmp    80104e81 <alltraps>

8010599c <vector180>:
.globl vector180
vector180:
  pushl $0
8010599c:	6a 00                	push   $0x0
  pushl $180
8010599e:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
801059a3:	e9 d9 f4 ff ff       	jmp    80104e81 <alltraps>

801059a8 <vector181>:
.globl vector181
vector181:
  pushl $0
801059a8:	6a 00                	push   $0x0
  pushl $181
801059aa:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
801059af:	e9 cd f4 ff ff       	jmp    80104e81 <alltraps>

801059b4 <vector182>:
.globl vector182
vector182:
  pushl $0
801059b4:	6a 00                	push   $0x0
  pushl $182
801059b6:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
801059bb:	e9 c1 f4 ff ff       	jmp    80104e81 <alltraps>

801059c0 <vector183>:
.globl vector183
vector183:
  pushl $0
801059c0:	6a 00                	push   $0x0
  pushl $183
801059c2:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
801059c7:	e9 b5 f4 ff ff       	jmp    80104e81 <alltraps>

801059cc <vector184>:
.globl vector184
vector184:
  pushl $0
801059cc:	6a 00                	push   $0x0
  pushl $184
801059ce:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
801059d3:	e9 a9 f4 ff ff       	jmp    80104e81 <alltraps>

801059d8 <vector185>:
.globl vector185
vector185:
  pushl $0
801059d8:	6a 00                	push   $0x0
  pushl $185
801059da:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
801059df:	e9 9d f4 ff ff       	jmp    80104e81 <alltraps>

801059e4 <vector186>:
.globl vector186
vector186:
  pushl $0
801059e4:	6a 00                	push   $0x0
  pushl $186
801059e6:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
801059eb:	e9 91 f4 ff ff       	jmp    80104e81 <alltraps>

801059f0 <vector187>:
.globl vector187
vector187:
  pushl $0
801059f0:	6a 00                	push   $0x0
  pushl $187
801059f2:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
801059f7:	e9 85 f4 ff ff       	jmp    80104e81 <alltraps>

801059fc <vector188>:
.globl vector188
vector188:
  pushl $0
801059fc:	6a 00                	push   $0x0
  pushl $188
801059fe:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80105a03:	e9 79 f4 ff ff       	jmp    80104e81 <alltraps>

80105a08 <vector189>:
.globl vector189
vector189:
  pushl $0
80105a08:	6a 00                	push   $0x0
  pushl $189
80105a0a:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80105a0f:	e9 6d f4 ff ff       	jmp    80104e81 <alltraps>

80105a14 <vector190>:
.globl vector190
vector190:
  pushl $0
80105a14:	6a 00                	push   $0x0
  pushl $190
80105a16:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80105a1b:	e9 61 f4 ff ff       	jmp    80104e81 <alltraps>

80105a20 <vector191>:
.globl vector191
vector191:
  pushl $0
80105a20:	6a 00                	push   $0x0
  pushl $191
80105a22:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80105a27:	e9 55 f4 ff ff       	jmp    80104e81 <alltraps>

80105a2c <vector192>:
.globl vector192
vector192:
  pushl $0
80105a2c:	6a 00                	push   $0x0
  pushl $192
80105a2e:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80105a33:	e9 49 f4 ff ff       	jmp    80104e81 <alltraps>

80105a38 <vector193>:
.globl vector193
vector193:
  pushl $0
80105a38:	6a 00                	push   $0x0
  pushl $193
80105a3a:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80105a3f:	e9 3d f4 ff ff       	jmp    80104e81 <alltraps>

80105a44 <vector194>:
.globl vector194
vector194:
  pushl $0
80105a44:	6a 00                	push   $0x0
  pushl $194
80105a46:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80105a4b:	e9 31 f4 ff ff       	jmp    80104e81 <alltraps>

80105a50 <vector195>:
.globl vector195
vector195:
  pushl $0
80105a50:	6a 00                	push   $0x0
  pushl $195
80105a52:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80105a57:	e9 25 f4 ff ff       	jmp    80104e81 <alltraps>

80105a5c <vector196>:
.globl vector196
vector196:
  pushl $0
80105a5c:	6a 00                	push   $0x0
  pushl $196
80105a5e:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80105a63:	e9 19 f4 ff ff       	jmp    80104e81 <alltraps>

80105a68 <vector197>:
.globl vector197
vector197:
  pushl $0
80105a68:	6a 00                	push   $0x0
  pushl $197
80105a6a:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80105a6f:	e9 0d f4 ff ff       	jmp    80104e81 <alltraps>

80105a74 <vector198>:
.globl vector198
vector198:
  pushl $0
80105a74:	6a 00                	push   $0x0
  pushl $198
80105a76:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80105a7b:	e9 01 f4 ff ff       	jmp    80104e81 <alltraps>

80105a80 <vector199>:
.globl vector199
vector199:
  pushl $0
80105a80:	6a 00                	push   $0x0
  pushl $199
80105a82:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80105a87:	e9 f5 f3 ff ff       	jmp    80104e81 <alltraps>

80105a8c <vector200>:
.globl vector200
vector200:
  pushl $0
80105a8c:	6a 00                	push   $0x0
  pushl $200
80105a8e:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80105a93:	e9 e9 f3 ff ff       	jmp    80104e81 <alltraps>

80105a98 <vector201>:
.globl vector201
vector201:
  pushl $0
80105a98:	6a 00                	push   $0x0
  pushl $201
80105a9a:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80105a9f:	e9 dd f3 ff ff       	jmp    80104e81 <alltraps>

80105aa4 <vector202>:
.globl vector202
vector202:
  pushl $0
80105aa4:	6a 00                	push   $0x0
  pushl $202
80105aa6:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80105aab:	e9 d1 f3 ff ff       	jmp    80104e81 <alltraps>

80105ab0 <vector203>:
.globl vector203
vector203:
  pushl $0
80105ab0:	6a 00                	push   $0x0
  pushl $203
80105ab2:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80105ab7:	e9 c5 f3 ff ff       	jmp    80104e81 <alltraps>

80105abc <vector204>:
.globl vector204
vector204:
  pushl $0
80105abc:	6a 00                	push   $0x0
  pushl $204
80105abe:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80105ac3:	e9 b9 f3 ff ff       	jmp    80104e81 <alltraps>

80105ac8 <vector205>:
.globl vector205
vector205:
  pushl $0
80105ac8:	6a 00                	push   $0x0
  pushl $205
80105aca:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80105acf:	e9 ad f3 ff ff       	jmp    80104e81 <alltraps>

80105ad4 <vector206>:
.globl vector206
vector206:
  pushl $0
80105ad4:	6a 00                	push   $0x0
  pushl $206
80105ad6:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80105adb:	e9 a1 f3 ff ff       	jmp    80104e81 <alltraps>

80105ae0 <vector207>:
.globl vector207
vector207:
  pushl $0
80105ae0:	6a 00                	push   $0x0
  pushl $207
80105ae2:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80105ae7:	e9 95 f3 ff ff       	jmp    80104e81 <alltraps>

80105aec <vector208>:
.globl vector208
vector208:
  pushl $0
80105aec:	6a 00                	push   $0x0
  pushl $208
80105aee:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80105af3:	e9 89 f3 ff ff       	jmp    80104e81 <alltraps>

80105af8 <vector209>:
.globl vector209
vector209:
  pushl $0
80105af8:	6a 00                	push   $0x0
  pushl $209
80105afa:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80105aff:	e9 7d f3 ff ff       	jmp    80104e81 <alltraps>

80105b04 <vector210>:
.globl vector210
vector210:
  pushl $0
80105b04:	6a 00                	push   $0x0
  pushl $210
80105b06:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80105b0b:	e9 71 f3 ff ff       	jmp    80104e81 <alltraps>

80105b10 <vector211>:
.globl vector211
vector211:
  pushl $0
80105b10:	6a 00                	push   $0x0
  pushl $211
80105b12:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80105b17:	e9 65 f3 ff ff       	jmp    80104e81 <alltraps>

80105b1c <vector212>:
.globl vector212
vector212:
  pushl $0
80105b1c:	6a 00                	push   $0x0
  pushl $212
80105b1e:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80105b23:	e9 59 f3 ff ff       	jmp    80104e81 <alltraps>

80105b28 <vector213>:
.globl vector213
vector213:
  pushl $0
80105b28:	6a 00                	push   $0x0
  pushl $213
80105b2a:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80105b2f:	e9 4d f3 ff ff       	jmp    80104e81 <alltraps>

80105b34 <vector214>:
.globl vector214
vector214:
  pushl $0
80105b34:	6a 00                	push   $0x0
  pushl $214
80105b36:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80105b3b:	e9 41 f3 ff ff       	jmp    80104e81 <alltraps>

80105b40 <vector215>:
.globl vector215
vector215:
  pushl $0
80105b40:	6a 00                	push   $0x0
  pushl $215
80105b42:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80105b47:	e9 35 f3 ff ff       	jmp    80104e81 <alltraps>

80105b4c <vector216>:
.globl vector216
vector216:
  pushl $0
80105b4c:	6a 00                	push   $0x0
  pushl $216
80105b4e:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80105b53:	e9 29 f3 ff ff       	jmp    80104e81 <alltraps>

80105b58 <vector217>:
.globl vector217
vector217:
  pushl $0
80105b58:	6a 00                	push   $0x0
  pushl $217
80105b5a:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80105b5f:	e9 1d f3 ff ff       	jmp    80104e81 <alltraps>

80105b64 <vector218>:
.globl vector218
vector218:
  pushl $0
80105b64:	6a 00                	push   $0x0
  pushl $218
80105b66:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80105b6b:	e9 11 f3 ff ff       	jmp    80104e81 <alltraps>

80105b70 <vector219>:
.globl vector219
vector219:
  pushl $0
80105b70:	6a 00                	push   $0x0
  pushl $219
80105b72:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80105b77:	e9 05 f3 ff ff       	jmp    80104e81 <alltraps>

80105b7c <vector220>:
.globl vector220
vector220:
  pushl $0
80105b7c:	6a 00                	push   $0x0
  pushl $220
80105b7e:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80105b83:	e9 f9 f2 ff ff       	jmp    80104e81 <alltraps>

80105b88 <vector221>:
.globl vector221
vector221:
  pushl $0
80105b88:	6a 00                	push   $0x0
  pushl $221
80105b8a:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80105b8f:	e9 ed f2 ff ff       	jmp    80104e81 <alltraps>

80105b94 <vector222>:
.globl vector222
vector222:
  pushl $0
80105b94:	6a 00                	push   $0x0
  pushl $222
80105b96:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80105b9b:	e9 e1 f2 ff ff       	jmp    80104e81 <alltraps>

80105ba0 <vector223>:
.globl vector223
vector223:
  pushl $0
80105ba0:	6a 00                	push   $0x0
  pushl $223
80105ba2:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80105ba7:	e9 d5 f2 ff ff       	jmp    80104e81 <alltraps>

80105bac <vector224>:
.globl vector224
vector224:
  pushl $0
80105bac:	6a 00                	push   $0x0
  pushl $224
80105bae:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80105bb3:	e9 c9 f2 ff ff       	jmp    80104e81 <alltraps>

80105bb8 <vector225>:
.globl vector225
vector225:
  pushl $0
80105bb8:	6a 00                	push   $0x0
  pushl $225
80105bba:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80105bbf:	e9 bd f2 ff ff       	jmp    80104e81 <alltraps>

80105bc4 <vector226>:
.globl vector226
vector226:
  pushl $0
80105bc4:	6a 00                	push   $0x0
  pushl $226
80105bc6:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80105bcb:	e9 b1 f2 ff ff       	jmp    80104e81 <alltraps>

80105bd0 <vector227>:
.globl vector227
vector227:
  pushl $0
80105bd0:	6a 00                	push   $0x0
  pushl $227
80105bd2:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80105bd7:	e9 a5 f2 ff ff       	jmp    80104e81 <alltraps>

80105bdc <vector228>:
.globl vector228
vector228:
  pushl $0
80105bdc:	6a 00                	push   $0x0
  pushl $228
80105bde:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80105be3:	e9 99 f2 ff ff       	jmp    80104e81 <alltraps>

80105be8 <vector229>:
.globl vector229
vector229:
  pushl $0
80105be8:	6a 00                	push   $0x0
  pushl $229
80105bea:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80105bef:	e9 8d f2 ff ff       	jmp    80104e81 <alltraps>

80105bf4 <vector230>:
.globl vector230
vector230:
  pushl $0
80105bf4:	6a 00                	push   $0x0
  pushl $230
80105bf6:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80105bfb:	e9 81 f2 ff ff       	jmp    80104e81 <alltraps>

80105c00 <vector231>:
.globl vector231
vector231:
  pushl $0
80105c00:	6a 00                	push   $0x0
  pushl $231
80105c02:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80105c07:	e9 75 f2 ff ff       	jmp    80104e81 <alltraps>

80105c0c <vector232>:
.globl vector232
vector232:
  pushl $0
80105c0c:	6a 00                	push   $0x0
  pushl $232
80105c0e:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80105c13:	e9 69 f2 ff ff       	jmp    80104e81 <alltraps>

80105c18 <vector233>:
.globl vector233
vector233:
  pushl $0
80105c18:	6a 00                	push   $0x0
  pushl $233
80105c1a:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80105c1f:	e9 5d f2 ff ff       	jmp    80104e81 <alltraps>

80105c24 <vector234>:
.globl vector234
vector234:
  pushl $0
80105c24:	6a 00                	push   $0x0
  pushl $234
80105c26:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80105c2b:	e9 51 f2 ff ff       	jmp    80104e81 <alltraps>

80105c30 <vector235>:
.globl vector235
vector235:
  pushl $0
80105c30:	6a 00                	push   $0x0
  pushl $235
80105c32:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80105c37:	e9 45 f2 ff ff       	jmp    80104e81 <alltraps>

80105c3c <vector236>:
.globl vector236
vector236:
  pushl $0
80105c3c:	6a 00                	push   $0x0
  pushl $236
80105c3e:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80105c43:	e9 39 f2 ff ff       	jmp    80104e81 <alltraps>

80105c48 <vector237>:
.globl vector237
vector237:
  pushl $0
80105c48:	6a 00                	push   $0x0
  pushl $237
80105c4a:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80105c4f:	e9 2d f2 ff ff       	jmp    80104e81 <alltraps>

80105c54 <vector238>:
.globl vector238
vector238:
  pushl $0
80105c54:	6a 00                	push   $0x0
  pushl $238
80105c56:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80105c5b:	e9 21 f2 ff ff       	jmp    80104e81 <alltraps>

80105c60 <vector239>:
.globl vector239
vector239:
  pushl $0
80105c60:	6a 00                	push   $0x0
  pushl $239
80105c62:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80105c67:	e9 15 f2 ff ff       	jmp    80104e81 <alltraps>

80105c6c <vector240>:
.globl vector240
vector240:
  pushl $0
80105c6c:	6a 00                	push   $0x0
  pushl $240
80105c6e:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80105c73:	e9 09 f2 ff ff       	jmp    80104e81 <alltraps>

80105c78 <vector241>:
.globl vector241
vector241:
  pushl $0
80105c78:	6a 00                	push   $0x0
  pushl $241
80105c7a:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80105c7f:	e9 fd f1 ff ff       	jmp    80104e81 <alltraps>

80105c84 <vector242>:
.globl vector242
vector242:
  pushl $0
80105c84:	6a 00                	push   $0x0
  pushl $242
80105c86:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80105c8b:	e9 f1 f1 ff ff       	jmp    80104e81 <alltraps>

80105c90 <vector243>:
.globl vector243
vector243:
  pushl $0
80105c90:	6a 00                	push   $0x0
  pushl $243
80105c92:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80105c97:	e9 e5 f1 ff ff       	jmp    80104e81 <alltraps>

80105c9c <vector244>:
.globl vector244
vector244:
  pushl $0
80105c9c:	6a 00                	push   $0x0
  pushl $244
80105c9e:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80105ca3:	e9 d9 f1 ff ff       	jmp    80104e81 <alltraps>

80105ca8 <vector245>:
.globl vector245
vector245:
  pushl $0
80105ca8:	6a 00                	push   $0x0
  pushl $245
80105caa:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80105caf:	e9 cd f1 ff ff       	jmp    80104e81 <alltraps>

80105cb4 <vector246>:
.globl vector246
vector246:
  pushl $0
80105cb4:	6a 00                	push   $0x0
  pushl $246
80105cb6:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80105cbb:	e9 c1 f1 ff ff       	jmp    80104e81 <alltraps>

80105cc0 <vector247>:
.globl vector247
vector247:
  pushl $0
80105cc0:	6a 00                	push   $0x0
  pushl $247
80105cc2:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80105cc7:	e9 b5 f1 ff ff       	jmp    80104e81 <alltraps>

80105ccc <vector248>:
.globl vector248
vector248:
  pushl $0
80105ccc:	6a 00                	push   $0x0
  pushl $248
80105cce:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80105cd3:	e9 a9 f1 ff ff       	jmp    80104e81 <alltraps>

80105cd8 <vector249>:
.globl vector249
vector249:
  pushl $0
80105cd8:	6a 00                	push   $0x0
  pushl $249
80105cda:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80105cdf:	e9 9d f1 ff ff       	jmp    80104e81 <alltraps>

80105ce4 <vector250>:
.globl vector250
vector250:
  pushl $0
80105ce4:	6a 00                	push   $0x0
  pushl $250
80105ce6:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80105ceb:	e9 91 f1 ff ff       	jmp    80104e81 <alltraps>

80105cf0 <vector251>:
.globl vector251
vector251:
  pushl $0
80105cf0:	6a 00                	push   $0x0
  pushl $251
80105cf2:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80105cf7:	e9 85 f1 ff ff       	jmp    80104e81 <alltraps>

80105cfc <vector252>:
.globl vector252
vector252:
  pushl $0
80105cfc:	6a 00                	push   $0x0
  pushl $252
80105cfe:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80105d03:	e9 79 f1 ff ff       	jmp    80104e81 <alltraps>

80105d08 <vector253>:
.globl vector253
vector253:
  pushl $0
80105d08:	6a 00                	push   $0x0
  pushl $253
80105d0a:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80105d0f:	e9 6d f1 ff ff       	jmp    80104e81 <alltraps>

80105d14 <vector254>:
.globl vector254
vector254:
  pushl $0
80105d14:	6a 00                	push   $0x0
  pushl $254
80105d16:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80105d1b:	e9 61 f1 ff ff       	jmp    80104e81 <alltraps>

80105d20 <vector255>:
.globl vector255
vector255:
  pushl $0
80105d20:	6a 00                	push   $0x0
  pushl $255
80105d22:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80105d27:	e9 55 f1 ff ff       	jmp    80104e81 <alltraps>

80105d2c <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80105d2c:	55                   	push   %ebp
80105d2d:	89 e5                	mov    %esp,%ebp
80105d2f:	57                   	push   %edi
80105d30:	56                   	push   %esi
80105d31:	53                   	push   %ebx
80105d32:	83 ec 0c             	sub    $0xc,%esp
80105d35:	89 d6                	mov    %edx,%esi
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80105d37:	c1 ea 16             	shr    $0x16,%edx
80105d3a:	8d 3c 90             	lea    (%eax,%edx,4),%edi
  if(*pde & PTE_P){
80105d3d:	8b 1f                	mov    (%edi),%ebx
80105d3f:	f6 c3 01             	test   $0x1,%bl
80105d42:	74 22                	je     80105d66 <walkpgdir+0x3a>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
80105d44:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
80105d4a:	81 c3 00 00 00 80    	add    $0x80000000,%ebx
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
80105d50:	c1 ee 0c             	shr    $0xc,%esi
80105d53:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
80105d59:	8d 1c b3             	lea    (%ebx,%esi,4),%ebx
}
80105d5c:	89 d8                	mov    %ebx,%eax
80105d5e:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105d61:	5b                   	pop    %ebx
80105d62:	5e                   	pop    %esi
80105d63:	5f                   	pop    %edi
80105d64:	5d                   	pop    %ebp
80105d65:	c3                   	ret    
    if(!alloc || (pgtab = (pte_t*)kalloc(-2)) == 0)
80105d66:	85 c9                	test   %ecx,%ecx
80105d68:	74 33                	je     80105d9d <walkpgdir+0x71>
80105d6a:	83 ec 0c             	sub    $0xc,%esp
80105d6d:	6a fe                	push   $0xfffffffe
80105d6f:	e8 84 c3 ff ff       	call   801020f8 <kalloc>
80105d74:	89 c3                	mov    %eax,%ebx
80105d76:	83 c4 10             	add    $0x10,%esp
80105d79:	85 c0                	test   %eax,%eax
80105d7b:	74 df                	je     80105d5c <walkpgdir+0x30>
    memset(pgtab, 0, PGSIZE);
80105d7d:	83 ec 04             	sub    $0x4,%esp
80105d80:	68 00 10 00 00       	push   $0x1000
80105d85:	6a 00                	push   $0x0
80105d87:	50                   	push   %eax
80105d88:	e8 ec df ff ff       	call   80103d79 <memset>
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
80105d8d:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80105d93:	83 c8 07             	or     $0x7,%eax
80105d96:	89 07                	mov    %eax,(%edi)
80105d98:	83 c4 10             	add    $0x10,%esp
80105d9b:	eb b3                	jmp    80105d50 <walkpgdir+0x24>
      return 0;
80105d9d:	bb 00 00 00 00       	mov    $0x0,%ebx
80105da2:	eb b8                	jmp    80105d5c <walkpgdir+0x30>

80105da4 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80105da4:	55                   	push   %ebp
80105da5:	89 e5                	mov    %esp,%ebp
80105da7:	57                   	push   %edi
80105da8:	56                   	push   %esi
80105da9:	53                   	push   %ebx
80105daa:	83 ec 1c             	sub    $0x1c,%esp
80105dad:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105db0:	8b 75 08             	mov    0x8(%ebp),%esi
  char *a, *last;
  pte_t *pte;

  a = (char*)PGROUNDDOWN((uint)va);
80105db3:	89 d3                	mov    %edx,%ebx
80105db5:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80105dbb:	8d 7c 0a ff          	lea    -0x1(%edx,%ecx,1),%edi
80105dbf:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105dc5:	b9 01 00 00 00       	mov    $0x1,%ecx
80105dca:	89 da                	mov    %ebx,%edx
80105dcc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105dcf:	e8 58 ff ff ff       	call   80105d2c <walkpgdir>
80105dd4:	85 c0                	test   %eax,%eax
80105dd6:	74 2e                	je     80105e06 <mappages+0x62>
      return -1;
    if(*pte & PTE_P)
80105dd8:	f6 00 01             	testb  $0x1,(%eax)
80105ddb:	75 1c                	jne    80105df9 <mappages+0x55>
      panic("remap");
    *pte = pa | perm | PTE_P;
80105ddd:	89 f2                	mov    %esi,%edx
80105ddf:	0b 55 0c             	or     0xc(%ebp),%edx
80105de2:	83 ca 01             	or     $0x1,%edx
80105de5:	89 10                	mov    %edx,(%eax)
    if(a == last)
80105de7:	39 fb                	cmp    %edi,%ebx
80105de9:	74 28                	je     80105e13 <mappages+0x6f>
      break;
    a += PGSIZE;
80105deb:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pa += PGSIZE;
80105df1:	81 c6 00 10 00 00    	add    $0x1000,%esi
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105df7:	eb cc                	jmp    80105dc5 <mappages+0x21>
      panic("remap");
80105df9:	83 ec 0c             	sub    $0xc,%esp
80105dfc:	68 cc 6e 10 80       	push   $0x80106ecc
80105e01:	e8 42 a5 ff ff       	call   80100348 <panic>
      return -1;
80105e06:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  return 0;
}
80105e0b:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105e0e:	5b                   	pop    %ebx
80105e0f:	5e                   	pop    %esi
80105e10:	5f                   	pop    %edi
80105e11:	5d                   	pop    %ebp
80105e12:	c3                   	ret    
  return 0;
80105e13:	b8 00 00 00 00       	mov    $0x0,%eax
80105e18:	eb f1                	jmp    80105e0b <mappages+0x67>

80105e1a <seginit>:
{
80105e1a:	55                   	push   %ebp
80105e1b:	89 e5                	mov    %esp,%ebp
80105e1d:	53                   	push   %ebx
80105e1e:	83 ec 14             	sub    $0x14,%esp
  c = &cpus[cpuid()];
80105e21:	e8 ea d4 ff ff       	call   80103310 <cpuid>
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80105e26:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
80105e2c:	66 c7 80 18 18 19 80 	movw   $0xffff,-0x7fe6e7e8(%eax)
80105e33:	ff ff 
80105e35:	66 c7 80 1a 18 19 80 	movw   $0x0,-0x7fe6e7e6(%eax)
80105e3c:	00 00 
80105e3e:	c6 80 1c 18 19 80 00 	movb   $0x0,-0x7fe6e7e4(%eax)
80105e45:	0f b6 88 1d 18 19 80 	movzbl -0x7fe6e7e3(%eax),%ecx
80105e4c:	83 e1 f0             	and    $0xfffffff0,%ecx
80105e4f:	83 c9 1a             	or     $0x1a,%ecx
80105e52:	83 e1 9f             	and    $0xffffff9f,%ecx
80105e55:	83 c9 80             	or     $0xffffff80,%ecx
80105e58:	88 88 1d 18 19 80    	mov    %cl,-0x7fe6e7e3(%eax)
80105e5e:	0f b6 88 1e 18 19 80 	movzbl -0x7fe6e7e2(%eax),%ecx
80105e65:	83 c9 0f             	or     $0xf,%ecx
80105e68:	83 e1 cf             	and    $0xffffffcf,%ecx
80105e6b:	83 c9 c0             	or     $0xffffffc0,%ecx
80105e6e:	88 88 1e 18 19 80    	mov    %cl,-0x7fe6e7e2(%eax)
80105e74:	c6 80 1f 18 19 80 00 	movb   $0x0,-0x7fe6e7e1(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80105e7b:	66 c7 80 20 18 19 80 	movw   $0xffff,-0x7fe6e7e0(%eax)
80105e82:	ff ff 
80105e84:	66 c7 80 22 18 19 80 	movw   $0x0,-0x7fe6e7de(%eax)
80105e8b:	00 00 
80105e8d:	c6 80 24 18 19 80 00 	movb   $0x0,-0x7fe6e7dc(%eax)
80105e94:	0f b6 88 25 18 19 80 	movzbl -0x7fe6e7db(%eax),%ecx
80105e9b:	83 e1 f0             	and    $0xfffffff0,%ecx
80105e9e:	83 c9 12             	or     $0x12,%ecx
80105ea1:	83 e1 9f             	and    $0xffffff9f,%ecx
80105ea4:	83 c9 80             	or     $0xffffff80,%ecx
80105ea7:	88 88 25 18 19 80    	mov    %cl,-0x7fe6e7db(%eax)
80105ead:	0f b6 88 26 18 19 80 	movzbl -0x7fe6e7da(%eax),%ecx
80105eb4:	83 c9 0f             	or     $0xf,%ecx
80105eb7:	83 e1 cf             	and    $0xffffffcf,%ecx
80105eba:	83 c9 c0             	or     $0xffffffc0,%ecx
80105ebd:	88 88 26 18 19 80    	mov    %cl,-0x7fe6e7da(%eax)
80105ec3:	c6 80 27 18 19 80 00 	movb   $0x0,-0x7fe6e7d9(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80105eca:	66 c7 80 28 18 19 80 	movw   $0xffff,-0x7fe6e7d8(%eax)
80105ed1:	ff ff 
80105ed3:	66 c7 80 2a 18 19 80 	movw   $0x0,-0x7fe6e7d6(%eax)
80105eda:	00 00 
80105edc:	c6 80 2c 18 19 80 00 	movb   $0x0,-0x7fe6e7d4(%eax)
80105ee3:	c6 80 2d 18 19 80 fa 	movb   $0xfa,-0x7fe6e7d3(%eax)
80105eea:	0f b6 88 2e 18 19 80 	movzbl -0x7fe6e7d2(%eax),%ecx
80105ef1:	83 c9 0f             	or     $0xf,%ecx
80105ef4:	83 e1 cf             	and    $0xffffffcf,%ecx
80105ef7:	83 c9 c0             	or     $0xffffffc0,%ecx
80105efa:	88 88 2e 18 19 80    	mov    %cl,-0x7fe6e7d2(%eax)
80105f00:	c6 80 2f 18 19 80 00 	movb   $0x0,-0x7fe6e7d1(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80105f07:	66 c7 80 30 18 19 80 	movw   $0xffff,-0x7fe6e7d0(%eax)
80105f0e:	ff ff 
80105f10:	66 c7 80 32 18 19 80 	movw   $0x0,-0x7fe6e7ce(%eax)
80105f17:	00 00 
80105f19:	c6 80 34 18 19 80 00 	movb   $0x0,-0x7fe6e7cc(%eax)
80105f20:	c6 80 35 18 19 80 f2 	movb   $0xf2,-0x7fe6e7cb(%eax)
80105f27:	0f b6 88 36 18 19 80 	movzbl -0x7fe6e7ca(%eax),%ecx
80105f2e:	83 c9 0f             	or     $0xf,%ecx
80105f31:	83 e1 cf             	and    $0xffffffcf,%ecx
80105f34:	83 c9 c0             	or     $0xffffffc0,%ecx
80105f37:	88 88 36 18 19 80    	mov    %cl,-0x7fe6e7ca(%eax)
80105f3d:	c6 80 37 18 19 80 00 	movb   $0x0,-0x7fe6e7c9(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
80105f44:	05 10 18 19 80       	add    $0x80191810,%eax
  pd[0] = size-1;
80105f49:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
  pd[1] = (uint)p;
80105f4f:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
  pd[2] = (uint)p >> 16;
80105f53:	c1 e8 10             	shr    $0x10,%eax
80105f56:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
  asm volatile("lgdt (%0)" : : "r" (pd));
80105f5a:	8d 45 f2             	lea    -0xe(%ebp),%eax
80105f5d:	0f 01 10             	lgdtl  (%eax)
}
80105f60:	83 c4 14             	add    $0x14,%esp
80105f63:	5b                   	pop    %ebx
80105f64:	5d                   	pop    %ebp
80105f65:	c3                   	ret    

80105f66 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80105f66:	55                   	push   %ebp
80105f67:	89 e5                	mov    %esp,%ebp
  lcr3(V2P(kpgdir));   // switch to the kernel page table
80105f69:	a1 c4 44 19 80       	mov    0x801944c4,%eax
80105f6e:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint val)
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
80105f73:	0f 22 d8             	mov    %eax,%cr3
}
80105f76:	5d                   	pop    %ebp
80105f77:	c3                   	ret    

80105f78 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80105f78:	55                   	push   %ebp
80105f79:	89 e5                	mov    %esp,%ebp
80105f7b:	57                   	push   %edi
80105f7c:	56                   	push   %esi
80105f7d:	53                   	push   %ebx
80105f7e:	83 ec 1c             	sub    $0x1c,%esp
80105f81:	8b 75 08             	mov    0x8(%ebp),%esi
  if(p == 0)
80105f84:	85 f6                	test   %esi,%esi
80105f86:	0f 84 dd 00 00 00    	je     80106069 <switchuvm+0xf1>
    panic("switchuvm: no process");
  if(p->kstack == 0)
80105f8c:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
80105f90:	0f 84 e0 00 00 00    	je     80106076 <switchuvm+0xfe>
    panic("switchuvm: no kstack");
  if(p->pgdir == 0)
80105f96:	83 7e 04 00          	cmpl   $0x0,0x4(%esi)
80105f9a:	0f 84 e3 00 00 00    	je     80106083 <switchuvm+0x10b>
    panic("switchuvm: no pgdir");

  pushcli();
80105fa0:	e8 4b dc ff ff       	call   80103bf0 <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
80105fa5:	e8 0a d3 ff ff       	call   801032b4 <mycpu>
80105faa:	89 c3                	mov    %eax,%ebx
80105fac:	e8 03 d3 ff ff       	call   801032b4 <mycpu>
80105fb1:	8d 78 08             	lea    0x8(%eax),%edi
80105fb4:	e8 fb d2 ff ff       	call   801032b4 <mycpu>
80105fb9:	83 c0 08             	add    $0x8,%eax
80105fbc:	c1 e8 10             	shr    $0x10,%eax
80105fbf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105fc2:	e8 ed d2 ff ff       	call   801032b4 <mycpu>
80105fc7:	83 c0 08             	add    $0x8,%eax
80105fca:	c1 e8 18             	shr    $0x18,%eax
80105fcd:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
80105fd4:	67 00 
80105fd6:	66 89 bb 9a 00 00 00 	mov    %di,0x9a(%ebx)
80105fdd:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
80105fe1:	88 8b 9c 00 00 00    	mov    %cl,0x9c(%ebx)
80105fe7:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
80105fee:	83 e2 f0             	and    $0xfffffff0,%edx
80105ff1:	83 ca 19             	or     $0x19,%edx
80105ff4:	83 e2 9f             	and    $0xffffff9f,%edx
80105ff7:	83 ca 80             	or     $0xffffff80,%edx
80105ffa:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
80106000:	c6 83 9e 00 00 00 40 	movb   $0x40,0x9e(%ebx)
80106007:	88 83 9f 00 00 00    	mov    %al,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
8010600d:	e8 a2 d2 ff ff       	call   801032b4 <mycpu>
80106012:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80106019:	83 e2 ef             	and    $0xffffffef,%edx
8010601c:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
80106022:	e8 8d d2 ff ff       	call   801032b4 <mycpu>
80106027:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
8010602d:	8b 5e 08             	mov    0x8(%esi),%ebx
80106030:	e8 7f d2 ff ff       	call   801032b4 <mycpu>
80106035:	81 c3 00 10 00 00    	add    $0x1000,%ebx
8010603b:	89 58 0c             	mov    %ebx,0xc(%eax)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
8010603e:	e8 71 d2 ff ff       	call   801032b4 <mycpu>
80106043:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  asm volatile("ltr %0" : : "r" (sel));
80106049:	b8 28 00 00 00       	mov    $0x28,%eax
8010604e:	0f 00 d8             	ltr    %ax
  ltr(SEG_TSS << 3);
  lcr3(V2P(p->pgdir));  // switch to process's address space
80106051:	8b 46 04             	mov    0x4(%esi),%eax
80106054:	05 00 00 00 80       	add    $0x80000000,%eax
  asm volatile("movl %0,%%cr3" : : "r" (val));
80106059:	0f 22 d8             	mov    %eax,%cr3
  popcli();
8010605c:	e8 cc db ff ff       	call   80103c2d <popcli>
}
80106061:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106064:	5b                   	pop    %ebx
80106065:	5e                   	pop    %esi
80106066:	5f                   	pop    %edi
80106067:	5d                   	pop    %ebp
80106068:	c3                   	ret    
    panic("switchuvm: no process");
80106069:	83 ec 0c             	sub    $0xc,%esp
8010606c:	68 d2 6e 10 80       	push   $0x80106ed2
80106071:	e8 d2 a2 ff ff       	call   80100348 <panic>
    panic("switchuvm: no kstack");
80106076:	83 ec 0c             	sub    $0xc,%esp
80106079:	68 e8 6e 10 80       	push   $0x80106ee8
8010607e:	e8 c5 a2 ff ff       	call   80100348 <panic>
    panic("switchuvm: no pgdir");
80106083:	83 ec 0c             	sub    $0xc,%esp
80106086:	68 fd 6e 10 80       	push   $0x80106efd
8010608b:	e8 b8 a2 ff ff       	call   80100348 <panic>

80106090 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80106090:	55                   	push   %ebp
80106091:	89 e5                	mov    %esp,%ebp
80106093:	56                   	push   %esi
80106094:	53                   	push   %ebx
80106095:	8b 75 10             	mov    0x10(%ebp),%esi
  char *mem;

  if(sz >= PGSIZE)
80106098:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
8010609e:	77 51                	ja     801060f1 <inituvm+0x61>
    panic("inituvm: more than a page");
  mem = kalloc(-2);
801060a0:	83 ec 0c             	sub    $0xc,%esp
801060a3:	6a fe                	push   $0xfffffffe
801060a5:	e8 4e c0 ff ff       	call   801020f8 <kalloc>
801060aa:	89 c3                	mov    %eax,%ebx
  memset(mem, 0, PGSIZE);
801060ac:	83 c4 0c             	add    $0xc,%esp
801060af:	68 00 10 00 00       	push   $0x1000
801060b4:	6a 00                	push   $0x0
801060b6:	50                   	push   %eax
801060b7:	e8 bd dc ff ff       	call   80103d79 <memset>
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
801060bc:	83 c4 08             	add    $0x8,%esp
801060bf:	6a 06                	push   $0x6
801060c1:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801060c7:	50                   	push   %eax
801060c8:	b9 00 10 00 00       	mov    $0x1000,%ecx
801060cd:	ba 00 00 00 00       	mov    $0x0,%edx
801060d2:	8b 45 08             	mov    0x8(%ebp),%eax
801060d5:	e8 ca fc ff ff       	call   80105da4 <mappages>
  memmove(mem, init, sz);
801060da:	83 c4 0c             	add    $0xc,%esp
801060dd:	56                   	push   %esi
801060de:	ff 75 0c             	pushl  0xc(%ebp)
801060e1:	53                   	push   %ebx
801060e2:	e8 0d dd ff ff       	call   80103df4 <memmove>
}
801060e7:	83 c4 10             	add    $0x10,%esp
801060ea:	8d 65 f8             	lea    -0x8(%ebp),%esp
801060ed:	5b                   	pop    %ebx
801060ee:	5e                   	pop    %esi
801060ef:	5d                   	pop    %ebp
801060f0:	c3                   	ret    
    panic("inituvm: more than a page");
801060f1:	83 ec 0c             	sub    $0xc,%esp
801060f4:	68 11 6f 10 80       	push   $0x80106f11
801060f9:	e8 4a a2 ff ff       	call   80100348 <panic>

801060fe <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
801060fe:	55                   	push   %ebp
801060ff:	89 e5                	mov    %esp,%ebp
80106101:	57                   	push   %edi
80106102:	56                   	push   %esi
80106103:	53                   	push   %ebx
80106104:	83 ec 0c             	sub    $0xc,%esp
80106107:	8b 7d 18             	mov    0x18(%ebp),%edi
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
8010610a:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
80106111:	75 07                	jne    8010611a <loaduvm+0x1c>
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80106113:	bb 00 00 00 00       	mov    $0x0,%ebx
80106118:	eb 3c                	jmp    80106156 <loaduvm+0x58>
    panic("loaduvm: addr must be page aligned");
8010611a:	83 ec 0c             	sub    $0xc,%esp
8010611d:	68 cc 6f 10 80       	push   $0x80106fcc
80106122:	e8 21 a2 ff ff       	call   80100348 <panic>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
80106127:	83 ec 0c             	sub    $0xc,%esp
8010612a:	68 2b 6f 10 80       	push   $0x80106f2b
8010612f:	e8 14 a2 ff ff       	call   80100348 <panic>
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, P2V(pa), offset+i, n) != n)
80106134:	05 00 00 00 80       	add    $0x80000000,%eax
80106139:	56                   	push   %esi
8010613a:	89 da                	mov    %ebx,%edx
8010613c:	03 55 14             	add    0x14(%ebp),%edx
8010613f:	52                   	push   %edx
80106140:	50                   	push   %eax
80106141:	ff 75 10             	pushl  0x10(%ebp)
80106144:	e8 36 b6 ff ff       	call   8010177f <readi>
80106149:	83 c4 10             	add    $0x10,%esp
8010614c:	39 f0                	cmp    %esi,%eax
8010614e:	75 47                	jne    80106197 <loaduvm+0x99>
  for(i = 0; i < sz; i += PGSIZE){
80106150:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106156:	39 fb                	cmp    %edi,%ebx
80106158:	73 30                	jae    8010618a <loaduvm+0x8c>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
8010615a:	89 da                	mov    %ebx,%edx
8010615c:	03 55 0c             	add    0xc(%ebp),%edx
8010615f:	b9 00 00 00 00       	mov    $0x0,%ecx
80106164:	8b 45 08             	mov    0x8(%ebp),%eax
80106167:	e8 c0 fb ff ff       	call   80105d2c <walkpgdir>
8010616c:	85 c0                	test   %eax,%eax
8010616e:	74 b7                	je     80106127 <loaduvm+0x29>
    pa = PTE_ADDR(*pte);
80106170:	8b 00                	mov    (%eax),%eax
80106172:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    if(sz - i < PGSIZE)
80106177:	89 fe                	mov    %edi,%esi
80106179:	29 de                	sub    %ebx,%esi
8010617b:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
80106181:	76 b1                	jbe    80106134 <loaduvm+0x36>
      n = PGSIZE;
80106183:	be 00 10 00 00       	mov    $0x1000,%esi
80106188:	eb aa                	jmp    80106134 <loaduvm+0x36>
      return -1;
  }
  return 0;
8010618a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010618f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106192:	5b                   	pop    %ebx
80106193:	5e                   	pop    %esi
80106194:	5f                   	pop    %edi
80106195:	5d                   	pop    %ebp
80106196:	c3                   	ret    
      return -1;
80106197:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010619c:	eb f1                	jmp    8010618f <loaduvm+0x91>

8010619e <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
8010619e:	55                   	push   %ebp
8010619f:	89 e5                	mov    %esp,%ebp
801061a1:	57                   	push   %edi
801061a2:	56                   	push   %esi
801061a3:	53                   	push   %ebx
801061a4:	83 ec 0c             	sub    $0xc,%esp
801061a7:	8b 7d 0c             	mov    0xc(%ebp),%edi
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
801061aa:	39 7d 10             	cmp    %edi,0x10(%ebp)
801061ad:	73 11                	jae    801061c0 <deallocuvm+0x22>
    return oldsz;

  a = PGROUNDUP(newsz);
801061af:	8b 45 10             	mov    0x10(%ebp),%eax
801061b2:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
801061b8:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a  < oldsz; a += PGSIZE){
801061be:	eb 19                	jmp    801061d9 <deallocuvm+0x3b>
    return oldsz;
801061c0:	89 f8                	mov    %edi,%eax
801061c2:	eb 64                	jmp    80106228 <deallocuvm+0x8a>
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(!pte)
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
801061c4:	c1 eb 16             	shr    $0x16,%ebx
801061c7:	83 c3 01             	add    $0x1,%ebx
801061ca:	c1 e3 16             	shl    $0x16,%ebx
801061cd:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
  for(; a  < oldsz; a += PGSIZE){
801061d3:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801061d9:	39 fb                	cmp    %edi,%ebx
801061db:	73 48                	jae    80106225 <deallocuvm+0x87>
    pte = walkpgdir(pgdir, (char*)a, 0);
801061dd:	b9 00 00 00 00       	mov    $0x0,%ecx
801061e2:	89 da                	mov    %ebx,%edx
801061e4:	8b 45 08             	mov    0x8(%ebp),%eax
801061e7:	e8 40 fb ff ff       	call   80105d2c <walkpgdir>
801061ec:	89 c6                	mov    %eax,%esi
    if(!pte)
801061ee:	85 c0                	test   %eax,%eax
801061f0:	74 d2                	je     801061c4 <deallocuvm+0x26>
    else if((*pte & PTE_P) != 0){
801061f2:	8b 00                	mov    (%eax),%eax
801061f4:	a8 01                	test   $0x1,%al
801061f6:	74 db                	je     801061d3 <deallocuvm+0x35>
      pa = PTE_ADDR(*pte);
      if(pa == 0)
801061f8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801061fd:	74 19                	je     80106218 <deallocuvm+0x7a>
        panic("kfree");
      char *v = P2V(pa);
801061ff:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
80106204:	83 ec 0c             	sub    $0xc,%esp
80106207:	50                   	push   %eax
80106208:	e8 a3 bd ff ff       	call   80101fb0 <kfree>
      *pte = 0;
8010620d:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80106213:	83 c4 10             	add    $0x10,%esp
80106216:	eb bb                	jmp    801061d3 <deallocuvm+0x35>
        panic("kfree");
80106218:	83 ec 0c             	sub    $0xc,%esp
8010621b:	68 66 68 10 80       	push   $0x80106866
80106220:	e8 23 a1 ff ff       	call   80100348 <panic>
    }
  }
  return newsz;
80106225:	8b 45 10             	mov    0x10(%ebp),%eax
}
80106228:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010622b:	5b                   	pop    %ebx
8010622c:	5e                   	pop    %esi
8010622d:	5f                   	pop    %edi
8010622e:	5d                   	pop    %ebp
8010622f:	c3                   	ret    

80106230 <allocuvm>:
{
80106230:	55                   	push   %ebp
80106231:	89 e5                	mov    %esp,%ebp
80106233:	57                   	push   %edi
80106234:	56                   	push   %esi
80106235:	53                   	push   %ebx
80106236:	83 ec 1c             	sub    $0x1c,%esp
80106239:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(newsz >= KERNBASE)
8010623c:	89 7d e4             	mov    %edi,-0x1c(%ebp)
8010623f:	85 ff                	test   %edi,%edi
80106241:	0f 88 ca 00 00 00    	js     80106311 <allocuvm+0xe1>
  if(newsz < oldsz)
80106247:	3b 7d 0c             	cmp    0xc(%ebp),%edi
8010624a:	72 65                	jb     801062b1 <allocuvm+0x81>
  a = PGROUNDUP(oldsz);
8010624c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010624f:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
80106255:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a < newsz; a += PGSIZE){
8010625b:	39 fb                	cmp    %edi,%ebx
8010625d:	0f 83 b5 00 00 00    	jae    80106318 <allocuvm+0xe8>
    mem = kalloc(pid);
80106263:	83 ec 0c             	sub    $0xc,%esp
80106266:	ff 75 14             	pushl  0x14(%ebp)
80106269:	e8 8a be ff ff       	call   801020f8 <kalloc>
8010626e:	89 c6                	mov    %eax,%esi
    if(mem == 0){
80106270:	83 c4 10             	add    $0x10,%esp
80106273:	85 c0                	test   %eax,%eax
80106275:	74 42                	je     801062b9 <allocuvm+0x89>
    memset(mem, 0, PGSIZE);
80106277:	83 ec 04             	sub    $0x4,%esp
8010627a:	68 00 10 00 00       	push   $0x1000
8010627f:	6a 00                	push   $0x0
80106281:	50                   	push   %eax
80106282:	e8 f2 da ff ff       	call   80103d79 <memset>
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
80106287:	83 c4 08             	add    $0x8,%esp
8010628a:	6a 06                	push   $0x6
8010628c:	8d 86 00 00 00 80    	lea    -0x80000000(%esi),%eax
80106292:	50                   	push   %eax
80106293:	b9 00 10 00 00       	mov    $0x1000,%ecx
80106298:	89 da                	mov    %ebx,%edx
8010629a:	8b 45 08             	mov    0x8(%ebp),%eax
8010629d:	e8 02 fb ff ff       	call   80105da4 <mappages>
801062a2:	83 c4 10             	add    $0x10,%esp
801062a5:	85 c0                	test   %eax,%eax
801062a7:	78 38                	js     801062e1 <allocuvm+0xb1>
  for(; a < newsz; a += PGSIZE){
801062a9:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801062af:	eb aa                	jmp    8010625b <allocuvm+0x2b>
    return oldsz;
801062b1:	8b 45 0c             	mov    0xc(%ebp),%eax
801062b4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801062b7:	eb 5f                	jmp    80106318 <allocuvm+0xe8>
      cprintf("allocuvm out of memory\n");
801062b9:	83 ec 0c             	sub    $0xc,%esp
801062bc:	68 49 6f 10 80       	push   $0x80106f49
801062c1:	e8 45 a3 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
801062c6:	83 c4 0c             	add    $0xc,%esp
801062c9:	ff 75 0c             	pushl  0xc(%ebp)
801062cc:	57                   	push   %edi
801062cd:	ff 75 08             	pushl  0x8(%ebp)
801062d0:	e8 c9 fe ff ff       	call   8010619e <deallocuvm>
      return 0;
801062d5:	83 c4 10             	add    $0x10,%esp
801062d8:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801062df:	eb 37                	jmp    80106318 <allocuvm+0xe8>
      cprintf("allocuvm out of memory (2)\n");
801062e1:	83 ec 0c             	sub    $0xc,%esp
801062e4:	68 61 6f 10 80       	push   $0x80106f61
801062e9:	e8 1d a3 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
801062ee:	83 c4 0c             	add    $0xc,%esp
801062f1:	ff 75 0c             	pushl  0xc(%ebp)
801062f4:	57                   	push   %edi
801062f5:	ff 75 08             	pushl  0x8(%ebp)
801062f8:	e8 a1 fe ff ff       	call   8010619e <deallocuvm>
      kfree(mem);
801062fd:	89 34 24             	mov    %esi,(%esp)
80106300:	e8 ab bc ff ff       	call   80101fb0 <kfree>
      return 0;
80106305:	83 c4 10             	add    $0x10,%esp
80106308:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
8010630f:	eb 07                	jmp    80106318 <allocuvm+0xe8>
    return 0;
80106311:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
}
80106318:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010631b:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010631e:	5b                   	pop    %ebx
8010631f:	5e                   	pop    %esi
80106320:	5f                   	pop    %edi
80106321:	5d                   	pop    %ebp
80106322:	c3                   	ret    

80106323 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80106323:	55                   	push   %ebp
80106324:	89 e5                	mov    %esp,%ebp
80106326:	56                   	push   %esi
80106327:	53                   	push   %ebx
80106328:	8b 75 08             	mov    0x8(%ebp),%esi
  uint i;

  if(pgdir == 0)
8010632b:	85 f6                	test   %esi,%esi
8010632d:	74 1a                	je     80106349 <freevm+0x26>
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
8010632f:	83 ec 04             	sub    $0x4,%esp
80106332:	6a 00                	push   $0x0
80106334:	68 00 00 00 80       	push   $0x80000000
80106339:	56                   	push   %esi
8010633a:	e8 5f fe ff ff       	call   8010619e <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
8010633f:	83 c4 10             	add    $0x10,%esp
80106342:	bb 00 00 00 00       	mov    $0x0,%ebx
80106347:	eb 10                	jmp    80106359 <freevm+0x36>
    panic("freevm: no pgdir");
80106349:	83 ec 0c             	sub    $0xc,%esp
8010634c:	68 7d 6f 10 80       	push   $0x80106f7d
80106351:	e8 f2 9f ff ff       	call   80100348 <panic>
  for(i = 0; i < NPDENTRIES; i++){
80106356:	83 c3 01             	add    $0x1,%ebx
80106359:	81 fb ff 03 00 00    	cmp    $0x3ff,%ebx
8010635f:	77 1f                	ja     80106380 <freevm+0x5d>
    if(pgdir[i] & PTE_P){
80106361:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
80106364:	a8 01                	test   $0x1,%al
80106366:	74 ee                	je     80106356 <freevm+0x33>
      char * v = P2V(PTE_ADDR(pgdir[i]));
80106368:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010636d:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
80106372:	83 ec 0c             	sub    $0xc,%esp
80106375:	50                   	push   %eax
80106376:	e8 35 bc ff ff       	call   80101fb0 <kfree>
8010637b:	83 c4 10             	add    $0x10,%esp
8010637e:	eb d6                	jmp    80106356 <freevm+0x33>
    }
  }
  kfree((char*)pgdir);
80106380:	83 ec 0c             	sub    $0xc,%esp
80106383:	56                   	push   %esi
80106384:	e8 27 bc ff ff       	call   80101fb0 <kfree>
}
80106389:	83 c4 10             	add    $0x10,%esp
8010638c:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010638f:	5b                   	pop    %ebx
80106390:	5e                   	pop    %esi
80106391:	5d                   	pop    %ebp
80106392:	c3                   	ret    

80106393 <setupkvm>:
{
80106393:	55                   	push   %ebp
80106394:	89 e5                	mov    %esp,%ebp
80106396:	56                   	push   %esi
80106397:	53                   	push   %ebx
  if((pgdir = (pde_t*)kalloc(-2)) == 0)
80106398:	83 ec 0c             	sub    $0xc,%esp
8010639b:	6a fe                	push   $0xfffffffe
8010639d:	e8 56 bd ff ff       	call   801020f8 <kalloc>
801063a2:	89 c6                	mov    %eax,%esi
801063a4:	83 c4 10             	add    $0x10,%esp
801063a7:	85 c0                	test   %eax,%eax
801063a9:	74 55                	je     80106400 <setupkvm+0x6d>
  memset(pgdir, 0, PGSIZE);
801063ab:	83 ec 04             	sub    $0x4,%esp
801063ae:	68 00 10 00 00       	push   $0x1000
801063b3:	6a 00                	push   $0x0
801063b5:	50                   	push   %eax
801063b6:	e8 be d9 ff ff       	call   80103d79 <memset>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801063bb:	83 c4 10             	add    $0x10,%esp
801063be:	bb 20 94 10 80       	mov    $0x80109420,%ebx
801063c3:	81 fb 60 94 10 80    	cmp    $0x80109460,%ebx
801063c9:	73 35                	jae    80106400 <setupkvm+0x6d>
                (uint)k->phys_start, k->perm) < 0) {
801063cb:	8b 43 04             	mov    0x4(%ebx),%eax
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
801063ce:	8b 4b 08             	mov    0x8(%ebx),%ecx
801063d1:	29 c1                	sub    %eax,%ecx
801063d3:	83 ec 08             	sub    $0x8,%esp
801063d6:	ff 73 0c             	pushl  0xc(%ebx)
801063d9:	50                   	push   %eax
801063da:	8b 13                	mov    (%ebx),%edx
801063dc:	89 f0                	mov    %esi,%eax
801063de:	e8 c1 f9 ff ff       	call   80105da4 <mappages>
801063e3:	83 c4 10             	add    $0x10,%esp
801063e6:	85 c0                	test   %eax,%eax
801063e8:	78 05                	js     801063ef <setupkvm+0x5c>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801063ea:	83 c3 10             	add    $0x10,%ebx
801063ed:	eb d4                	jmp    801063c3 <setupkvm+0x30>
      freevm(pgdir);
801063ef:	83 ec 0c             	sub    $0xc,%esp
801063f2:	56                   	push   %esi
801063f3:	e8 2b ff ff ff       	call   80106323 <freevm>
      return 0;
801063f8:	83 c4 10             	add    $0x10,%esp
801063fb:	be 00 00 00 00       	mov    $0x0,%esi
}
80106400:	89 f0                	mov    %esi,%eax
80106402:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106405:	5b                   	pop    %ebx
80106406:	5e                   	pop    %esi
80106407:	5d                   	pop    %ebp
80106408:	c3                   	ret    

80106409 <kvmalloc>:
{
80106409:	55                   	push   %ebp
8010640a:	89 e5                	mov    %esp,%ebp
8010640c:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
8010640f:	e8 7f ff ff ff       	call   80106393 <setupkvm>
80106414:	a3 c4 44 19 80       	mov    %eax,0x801944c4
  switchkvm();
80106419:	e8 48 fb ff ff       	call   80105f66 <switchkvm>
}
8010641e:	c9                   	leave  
8010641f:	c3                   	ret    

80106420 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80106420:	55                   	push   %ebp
80106421:	89 e5                	mov    %esp,%ebp
80106423:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80106426:	b9 00 00 00 00       	mov    $0x0,%ecx
8010642b:	8b 55 0c             	mov    0xc(%ebp),%edx
8010642e:	8b 45 08             	mov    0x8(%ebp),%eax
80106431:	e8 f6 f8 ff ff       	call   80105d2c <walkpgdir>
  if(pte == 0)
80106436:	85 c0                	test   %eax,%eax
80106438:	74 05                	je     8010643f <clearpteu+0x1f>
    panic("clearpteu");
  *pte &= ~PTE_U;
8010643a:	83 20 fb             	andl   $0xfffffffb,(%eax)
}
8010643d:	c9                   	leave  
8010643e:	c3                   	ret    
    panic("clearpteu");
8010643f:	83 ec 0c             	sub    $0xc,%esp
80106442:	68 8e 6f 10 80       	push   $0x80106f8e
80106447:	e8 fc 9e ff ff       	call   80100348 <panic>

8010644c <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz, int pid)
{
8010644c:	55                   	push   %ebp
8010644d:	89 e5                	mov    %esp,%ebp
8010644f:	57                   	push   %edi
80106450:	56                   	push   %esi
80106451:	53                   	push   %ebx
80106452:	83 ec 1c             	sub    $0x1c,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
80106455:	e8 39 ff ff ff       	call   80106393 <setupkvm>
8010645a:	89 45 dc             	mov    %eax,-0x24(%ebp)
8010645d:	85 c0                	test   %eax,%eax
8010645f:	0f 84 d1 00 00 00    	je     80106536 <copyuvm+0xea>
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80106465:	bf 00 00 00 00       	mov    $0x0,%edi
8010646a:	89 fe                	mov    %edi,%esi
8010646c:	3b 75 0c             	cmp    0xc(%ebp),%esi
8010646f:	0f 83 c1 00 00 00    	jae    80106536 <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80106475:	89 75 e4             	mov    %esi,-0x1c(%ebp)
80106478:	b9 00 00 00 00       	mov    $0x0,%ecx
8010647d:	89 f2                	mov    %esi,%edx
8010647f:	8b 45 08             	mov    0x8(%ebp),%eax
80106482:	e8 a5 f8 ff ff       	call   80105d2c <walkpgdir>
80106487:	85 c0                	test   %eax,%eax
80106489:	74 70                	je     801064fb <copyuvm+0xaf>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
8010648b:	8b 18                	mov    (%eax),%ebx
8010648d:	f6 c3 01             	test   $0x1,%bl
80106490:	74 76                	je     80106508 <copyuvm+0xbc>
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
80106492:	89 df                	mov    %ebx,%edi
80106494:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
    flags = PTE_FLAGS(*pte);
8010649a:	81 e3 ff 0f 00 00    	and    $0xfff,%ebx
801064a0:	89 5d e0             	mov    %ebx,-0x20(%ebp)
    if((mem = kalloc(pid)) == 0)
801064a3:	83 ec 0c             	sub    $0xc,%esp
801064a6:	ff 75 10             	pushl  0x10(%ebp)
801064a9:	e8 4a bc ff ff       	call   801020f8 <kalloc>
801064ae:	89 c3                	mov    %eax,%ebx
801064b0:	83 c4 10             	add    $0x10,%esp
801064b3:	85 c0                	test   %eax,%eax
801064b5:	74 6a                	je     80106521 <copyuvm+0xd5>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
801064b7:	81 c7 00 00 00 80    	add    $0x80000000,%edi
801064bd:	83 ec 04             	sub    $0x4,%esp
801064c0:	68 00 10 00 00       	push   $0x1000
801064c5:	57                   	push   %edi
801064c6:	50                   	push   %eax
801064c7:	e8 28 d9 ff ff       	call   80103df4 <memmove>
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0) {
801064cc:	83 c4 08             	add    $0x8,%esp
801064cf:	ff 75 e0             	pushl  -0x20(%ebp)
801064d2:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801064d8:	50                   	push   %eax
801064d9:	b9 00 10 00 00       	mov    $0x1000,%ecx
801064de:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801064e1:	8b 45 dc             	mov    -0x24(%ebp),%eax
801064e4:	e8 bb f8 ff ff       	call   80105da4 <mappages>
801064e9:	83 c4 10             	add    $0x10,%esp
801064ec:	85 c0                	test   %eax,%eax
801064ee:	78 25                	js     80106515 <copyuvm+0xc9>
  for(i = 0; i < sz; i += PGSIZE){
801064f0:	81 c6 00 10 00 00    	add    $0x1000,%esi
801064f6:	e9 71 ff ff ff       	jmp    8010646c <copyuvm+0x20>
      panic("copyuvm: pte should exist");
801064fb:	83 ec 0c             	sub    $0xc,%esp
801064fe:	68 98 6f 10 80       	push   $0x80106f98
80106503:	e8 40 9e ff ff       	call   80100348 <panic>
      panic("copyuvm: page not present");
80106508:	83 ec 0c             	sub    $0xc,%esp
8010650b:	68 b2 6f 10 80       	push   $0x80106fb2
80106510:	e8 33 9e ff ff       	call   80100348 <panic>
      kfree(mem);
80106515:	83 ec 0c             	sub    $0xc,%esp
80106518:	53                   	push   %ebx
80106519:	e8 92 ba ff ff       	call   80101fb0 <kfree>
      goto bad;
8010651e:	83 c4 10             	add    $0x10,%esp
    }
  }
  return d;

bad:
  freevm(d);
80106521:	83 ec 0c             	sub    $0xc,%esp
80106524:	ff 75 dc             	pushl  -0x24(%ebp)
80106527:	e8 f7 fd ff ff       	call   80106323 <freevm>
  return 0;
8010652c:	83 c4 10             	add    $0x10,%esp
8010652f:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
}
80106536:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106539:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010653c:	5b                   	pop    %ebx
8010653d:	5e                   	pop    %esi
8010653e:	5f                   	pop    %edi
8010653f:	5d                   	pop    %ebp
80106540:	c3                   	ret    

80106541 <uva2ka>:

// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80106541:	55                   	push   %ebp
80106542:	89 e5                	mov    %esp,%ebp
80106544:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80106547:	b9 00 00 00 00       	mov    $0x0,%ecx
8010654c:	8b 55 0c             	mov    0xc(%ebp),%edx
8010654f:	8b 45 08             	mov    0x8(%ebp),%eax
80106552:	e8 d5 f7 ff ff       	call   80105d2c <walkpgdir>
  if((*pte & PTE_P) == 0)
80106557:	8b 00                	mov    (%eax),%eax
80106559:	a8 01                	test   $0x1,%al
8010655b:	74 10                	je     8010656d <uva2ka+0x2c>
    return 0;
  if((*pte & PTE_U) == 0)
8010655d:	a8 04                	test   $0x4,%al
8010655f:	74 13                	je     80106574 <uva2ka+0x33>
    return 0;
  return (char*)P2V(PTE_ADDR(*pte));
80106561:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80106566:	05 00 00 00 80       	add    $0x80000000,%eax
}
8010656b:	c9                   	leave  
8010656c:	c3                   	ret    
    return 0;
8010656d:	b8 00 00 00 00       	mov    $0x0,%eax
80106572:	eb f7                	jmp    8010656b <uva2ka+0x2a>
    return 0;
80106574:	b8 00 00 00 00       	mov    $0x0,%eax
80106579:	eb f0                	jmp    8010656b <uva2ka+0x2a>

8010657b <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
8010657b:	55                   	push   %ebp
8010657c:	89 e5                	mov    %esp,%ebp
8010657e:	57                   	push   %edi
8010657f:	56                   	push   %esi
80106580:	53                   	push   %ebx
80106581:	83 ec 0c             	sub    $0xc,%esp
80106584:	8b 7d 14             	mov    0x14(%ebp),%edi
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
80106587:	eb 25                	jmp    801065ae <copyout+0x33>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
80106589:	8b 55 0c             	mov    0xc(%ebp),%edx
8010658c:	29 f2                	sub    %esi,%edx
8010658e:	01 d0                	add    %edx,%eax
80106590:	83 ec 04             	sub    $0x4,%esp
80106593:	53                   	push   %ebx
80106594:	ff 75 10             	pushl  0x10(%ebp)
80106597:	50                   	push   %eax
80106598:	e8 57 d8 ff ff       	call   80103df4 <memmove>
    len -= n;
8010659d:	29 df                	sub    %ebx,%edi
    buf += n;
8010659f:	01 5d 10             	add    %ebx,0x10(%ebp)
    va = va0 + PGSIZE;
801065a2:	8d 86 00 10 00 00    	lea    0x1000(%esi),%eax
801065a8:	89 45 0c             	mov    %eax,0xc(%ebp)
801065ab:	83 c4 10             	add    $0x10,%esp
  while(len > 0){
801065ae:	85 ff                	test   %edi,%edi
801065b0:	74 2f                	je     801065e1 <copyout+0x66>
    va0 = (uint)PGROUNDDOWN(va);
801065b2:	8b 75 0c             	mov    0xc(%ebp),%esi
801065b5:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    pa0 = uva2ka(pgdir, (char*)va0);
801065bb:	83 ec 08             	sub    $0x8,%esp
801065be:	56                   	push   %esi
801065bf:	ff 75 08             	pushl  0x8(%ebp)
801065c2:	e8 7a ff ff ff       	call   80106541 <uva2ka>
    if(pa0 == 0)
801065c7:	83 c4 10             	add    $0x10,%esp
801065ca:	85 c0                	test   %eax,%eax
801065cc:	74 20                	je     801065ee <copyout+0x73>
    n = PGSIZE - (va - va0);
801065ce:	89 f3                	mov    %esi,%ebx
801065d0:	2b 5d 0c             	sub    0xc(%ebp),%ebx
801065d3:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    if(n > len)
801065d9:	39 df                	cmp    %ebx,%edi
801065db:	73 ac                	jae    80106589 <copyout+0xe>
      n = len;
801065dd:	89 fb                	mov    %edi,%ebx
801065df:	eb a8                	jmp    80106589 <copyout+0xe>
  }
  return 0;
801065e1:	b8 00 00 00 00       	mov    $0x0,%eax
}
801065e6:	8d 65 f4             	lea    -0xc(%ebp),%esp
801065e9:	5b                   	pop    %ebx
801065ea:	5e                   	pop    %esi
801065eb:	5f                   	pop    %edi
801065ec:	5d                   	pop    %ebp
801065ed:	c3                   	ret    
      return -1;
801065ee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801065f3:	eb f1                	jmp    801065e6 <copyout+0x6b>
