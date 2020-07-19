
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
80100015:	b8 00 90 10 00       	mov    $0x109000,%eax
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
80100028:	bc d0 b5 10 80       	mov    $0x8010b5d0,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 bb 2d 10 80       	mov    $0x80102dbb,%eax
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
80100041:	68 e0 b5 10 80       	push   $0x8010b5e0
80100046:	e8 b2 3e 00 00       	call   80103efd <acquire>

  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
8010004b:	8b 1d 30 fd 10 80    	mov    0x8010fd30,%ebx
80100051:	83 c4 10             	add    $0x10,%esp
80100054:	eb 03                	jmp    80100059 <bget+0x25>
80100056:	8b 5b 54             	mov    0x54(%ebx),%ebx
80100059:	81 fb dc fc 10 80    	cmp    $0x8010fcdc,%ebx
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
80100077:	68 e0 b5 10 80       	push   $0x8010b5e0
8010007c:	e8 e1 3e 00 00       	call   80103f62 <release>
      acquiresleep(&b->lock);
80100081:	8d 43 0c             	lea    0xc(%ebx),%eax
80100084:	89 04 24             	mov    %eax,(%esp)
80100087:	e8 5d 3c 00 00       	call   80103ce9 <acquiresleep>
      return b;
8010008c:	83 c4 10             	add    $0x10,%esp
8010008f:	eb 4c                	jmp    801000dd <bget+0xa9>
  }

  // Not cached; recycle an unused buffer.
  // Even if refcnt==0, B_DIRTY indicates a buffer is in use
  // because log.c has modified it but not yet committed it.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100091:	8b 1d 2c fd 10 80    	mov    0x8010fd2c,%ebx
80100097:	eb 03                	jmp    8010009c <bget+0x68>
80100099:	8b 5b 50             	mov    0x50(%ebx),%ebx
8010009c:	81 fb dc fc 10 80    	cmp    $0x8010fcdc,%ebx
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
801000c5:	68 e0 b5 10 80       	push   $0x8010b5e0
801000ca:	e8 93 3e 00 00       	call   80103f62 <release>
      acquiresleep(&b->lock);
801000cf:	8d 43 0c             	lea    0xc(%ebx),%eax
801000d2:	89 04 24             	mov    %eax,(%esp)
801000d5:	e8 0f 3c 00 00       	call   80103ce9 <acquiresleep>
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
801000ea:	68 40 68 10 80       	push   $0x80106840
801000ef:	e8 54 02 00 00       	call   80100348 <panic>

801000f4 <binit>:
{
801000f4:	55                   	push   %ebp
801000f5:	89 e5                	mov    %esp,%ebp
801000f7:	53                   	push   %ebx
801000f8:	83 ec 0c             	sub    $0xc,%esp
  initlock(&bcache.lock, "bcache");
801000fb:	68 51 68 10 80       	push   $0x80106851
80100100:	68 e0 b5 10 80       	push   $0x8010b5e0
80100105:	e8 b7 3c 00 00       	call   80103dc1 <initlock>
  bcache.head.prev = &bcache.head;
8010010a:	c7 05 2c fd 10 80 dc 	movl   $0x8010fcdc,0x8010fd2c
80100111:	fc 10 80 
  bcache.head.next = &bcache.head;
80100114:	c7 05 30 fd 10 80 dc 	movl   $0x8010fcdc,0x8010fd30
8010011b:	fc 10 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010011e:	83 c4 10             	add    $0x10,%esp
80100121:	bb 14 b6 10 80       	mov    $0x8010b614,%ebx
80100126:	eb 37                	jmp    8010015f <binit+0x6b>
    b->next = bcache.head.next;
80100128:	a1 30 fd 10 80       	mov    0x8010fd30,%eax
8010012d:	89 43 54             	mov    %eax,0x54(%ebx)
    b->prev = &bcache.head;
80100130:	c7 43 50 dc fc 10 80 	movl   $0x8010fcdc,0x50(%ebx)
    initsleeplock(&b->lock, "buffer");
80100137:	83 ec 08             	sub    $0x8,%esp
8010013a:	68 58 68 10 80       	push   $0x80106858
8010013f:	8d 43 0c             	lea    0xc(%ebx),%eax
80100142:	50                   	push   %eax
80100143:	e8 6e 3b 00 00       	call   80103cb6 <initsleeplock>
    bcache.head.next->prev = b;
80100148:	a1 30 fd 10 80       	mov    0x8010fd30,%eax
8010014d:	89 58 50             	mov    %ebx,0x50(%eax)
    bcache.head.next = b;
80100150:	89 1d 30 fd 10 80    	mov    %ebx,0x8010fd30
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100156:	81 c3 5c 02 00 00    	add    $0x25c,%ebx
8010015c:	83 c4 10             	add    $0x10,%esp
8010015f:	81 fb dc fc 10 80    	cmp    $0x8010fcdc,%ebx
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
801001a8:	e8 c6 3b 00 00       	call   80103d73 <holdingsleep>
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
801001cb:	68 5f 68 10 80       	push   $0x8010685f
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
801001e4:	e8 8a 3b 00 00       	call   80103d73 <holdingsleep>
801001e9:	83 c4 10             	add    $0x10,%esp
801001ec:	85 c0                	test   %eax,%eax
801001ee:	74 6b                	je     8010025b <brelse+0x86>
    panic("brelse");

  releasesleep(&b->lock);
801001f0:	83 ec 0c             	sub    $0xc,%esp
801001f3:	56                   	push   %esi
801001f4:	e8 3f 3b 00 00       	call   80103d38 <releasesleep>

  acquire(&bcache.lock);
801001f9:	c7 04 24 e0 b5 10 80 	movl   $0x8010b5e0,(%esp)
80100200:	e8 f8 3c 00 00       	call   80103efd <acquire>
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
80100227:	a1 30 fd 10 80       	mov    0x8010fd30,%eax
8010022c:	89 43 54             	mov    %eax,0x54(%ebx)
    b->prev = &bcache.head;
8010022f:	c7 43 50 dc fc 10 80 	movl   $0x8010fcdc,0x50(%ebx)
    bcache.head.next->prev = b;
80100236:	a1 30 fd 10 80       	mov    0x8010fd30,%eax
8010023b:	89 58 50             	mov    %ebx,0x50(%eax)
    bcache.head.next = b;
8010023e:	89 1d 30 fd 10 80    	mov    %ebx,0x8010fd30
  }
  
  release(&bcache.lock);
80100244:	83 ec 0c             	sub    $0xc,%esp
80100247:	68 e0 b5 10 80       	push   $0x8010b5e0
8010024c:	e8 11 3d 00 00       	call   80103f62 <release>
}
80100251:	83 c4 10             	add    $0x10,%esp
80100254:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100257:	5b                   	pop    %ebx
80100258:	5e                   	pop    %esi
80100259:	5d                   	pop    %ebp
8010025a:	c3                   	ret    
    panic("brelse");
8010025b:	83 ec 0c             	sub    $0xc,%esp
8010025e:	68 66 68 10 80       	push   $0x80106866
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
80100283:	c7 04 24 20 a5 10 80 	movl   $0x8010a520,(%esp)
8010028a:	e8 6e 3c 00 00       	call   80103efd <acquire>
  while(n > 0){
8010028f:	83 c4 10             	add    $0x10,%esp
80100292:	85 db                	test   %ebx,%ebx
80100294:	0f 8e 8f 00 00 00    	jle    80100329 <consoleread+0xc1>
    while(input.r == input.w){
8010029a:	a1 c0 ff 10 80       	mov    0x8010ffc0,%eax
8010029f:	3b 05 c4 ff 10 80    	cmp    0x8010ffc4,%eax
801002a5:	75 47                	jne    801002ee <consoleread+0x86>
      if(myproc()->killed){
801002a7:	e8 af 32 00 00       	call   8010355b <myproc>
801002ac:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801002b0:	75 17                	jne    801002c9 <consoleread+0x61>
        release(&cons.lock);
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &cons.lock);
801002b2:	83 ec 08             	sub    $0x8,%esp
801002b5:	68 20 a5 10 80       	push   $0x8010a520
801002ba:	68 c0 ff 10 80       	push   $0x8010ffc0
801002bf:	e8 3e 37 00 00       	call   80103a02 <sleep>
801002c4:	83 c4 10             	add    $0x10,%esp
801002c7:	eb d1                	jmp    8010029a <consoleread+0x32>
        release(&cons.lock);
801002c9:	83 ec 0c             	sub    $0xc,%esp
801002cc:	68 20 a5 10 80       	push   $0x8010a520
801002d1:	e8 8c 3c 00 00       	call   80103f62 <release>
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
801002f1:	89 15 c0 ff 10 80    	mov    %edx,0x8010ffc0
801002f7:	89 c2                	mov    %eax,%edx
801002f9:	83 e2 7f             	and    $0x7f,%edx
801002fc:	0f b6 8a 40 ff 10 80 	movzbl -0x7fef00c0(%edx),%ecx
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
80100324:	a3 c0 ff 10 80       	mov    %eax,0x8010ffc0
  release(&cons.lock);
80100329:	83 ec 0c             	sub    $0xc,%esp
8010032c:	68 20 a5 10 80       	push   $0x8010a520
80100331:	e8 2c 3c 00 00       	call   80103f62 <release>
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
80100350:	c7 05 54 a5 10 80 00 	movl   $0x0,0x8010a554
80100357:	00 00 00 
  cprintf("lapicid %d: panic: ", lapicid());
8010035a:	e8 71 23 00 00       	call   801026d0 <lapicid>
8010035f:	83 ec 08             	sub    $0x8,%esp
80100362:	50                   	push   %eax
80100363:	68 6d 68 10 80       	push   $0x8010686d
80100368:	e8 9e 02 00 00       	call   8010060b <cprintf>
  cprintf(s);
8010036d:	83 c4 04             	add    $0x4,%esp
80100370:	ff 75 08             	pushl  0x8(%ebp)
80100373:	e8 93 02 00 00       	call   8010060b <cprintf>
  cprintf("\n");
80100378:	c7 04 24 bb 71 10 80 	movl   $0x801071bb,(%esp)
8010037f:	e8 87 02 00 00       	call   8010060b <cprintf>
  getcallerpcs(&s, pcs);
80100384:	83 c4 08             	add    $0x8,%esp
80100387:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010038a:	50                   	push   %eax
8010038b:	8d 45 08             	lea    0x8(%ebp),%eax
8010038e:	50                   	push   %eax
8010038f:	e8 48 3a 00 00       	call   80103ddc <getcallerpcs>
  for(i=0; i<10; i++)
80100394:	83 c4 10             	add    $0x10,%esp
80100397:	bb 00 00 00 00       	mov    $0x0,%ebx
8010039c:	eb 17                	jmp    801003b5 <panic+0x6d>
    cprintf(" %p", pcs[i]);
8010039e:	83 ec 08             	sub    $0x8,%esp
801003a1:	ff 74 9d d0          	pushl  -0x30(%ebp,%ebx,4)
801003a5:	68 81 68 10 80       	push   $0x80106881
801003aa:	e8 5c 02 00 00       	call   8010060b <cprintf>
  for(i=0; i<10; i++)
801003af:	83 c3 01             	add    $0x1,%ebx
801003b2:	83 c4 10             	add    $0x10,%esp
801003b5:	83 fb 09             	cmp    $0x9,%ebx
801003b8:	7e e4                	jle    8010039e <panic+0x56>
  panicked = 1; // freeze other CPU
801003ba:	c7 05 58 a5 10 80 01 	movl   $0x1,0x8010a558
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
8010049e:	68 85 68 10 80       	push   $0x80106885
801004a3:	e8 a0 fe ff ff       	call   80100348 <panic>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801004a8:	83 ec 04             	sub    $0x4,%esp
801004ab:	68 60 0e 00 00       	push   $0xe60
801004b0:	68 a0 80 0b 80       	push   $0x800b80a0
801004b5:	68 00 80 0b 80       	push   $0x800b8000
801004ba:	e8 65 3b 00 00       	call   80104024 <memmove>
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
801004d9:	e8 cb 3a 00 00       	call   80103fa9 <memset>
801004de:	83 c4 10             	add    $0x10,%esp
801004e1:	e9 4c ff ff ff       	jmp    80100432 <cgaputc+0x6c>

801004e6 <consputc>:
  if(panicked){
801004e6:	83 3d 58 a5 10 80 00 	cmpl   $0x0,0x8010a558
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
80100506:	e8 e2 4e 00 00       	call   801053ed <uartputc>
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
8010051f:	e8 c9 4e 00 00       	call   801053ed <uartputc>
80100524:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010052b:	e8 bd 4e 00 00       	call   801053ed <uartputc>
80100530:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100537:	e8 b1 4e 00 00       	call   801053ed <uartputc>
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
80100576:	0f b6 92 b0 68 10 80 	movzbl -0x7fef9750(%edx),%edx
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
801005c3:	c7 04 24 20 a5 10 80 	movl   $0x8010a520,(%esp)
801005ca:	e8 2e 39 00 00       	call   80103efd <acquire>
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
801005ec:	68 20 a5 10 80       	push   $0x8010a520
801005f1:	e8 6c 39 00 00       	call   80103f62 <release>
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
80100614:	a1 54 a5 10 80       	mov    0x8010a554,%eax
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
80100633:	68 20 a5 10 80       	push   $0x8010a520
80100638:	e8 c0 38 00 00       	call   80103efd <acquire>
8010063d:	83 c4 10             	add    $0x10,%esp
80100640:	eb de                	jmp    80100620 <cprintf+0x15>
    panic("null fmt");
80100642:	83 ec 0c             	sub    $0xc,%esp
80100645:	68 9f 68 10 80       	push   $0x8010689f
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
801006ee:	be 98 68 10 80       	mov    $0x80106898,%esi
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
8010072f:	68 20 a5 10 80       	push   $0x8010a520
80100734:	e8 29 38 00 00       	call   80103f62 <release>
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
8010074a:	68 20 a5 10 80       	push   $0x8010a520
8010074f:	e8 a9 37 00 00       	call   80103efd <acquire>
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
80100772:	a1 c8 ff 10 80       	mov    0x8010ffc8,%eax
80100777:	89 c2                	mov    %eax,%edx
80100779:	2b 15 c0 ff 10 80    	sub    0x8010ffc0,%edx
8010077f:	83 fa 7f             	cmp    $0x7f,%edx
80100782:	0f 87 9e 00 00 00    	ja     80100826 <consoleintr+0xe8>
        c = (c == '\r') ? '\n' : c;
80100788:	83 ff 0d             	cmp    $0xd,%edi
8010078b:	0f 84 86 00 00 00    	je     80100817 <consoleintr+0xd9>
        input.buf[input.e++ % INPUT_BUF] = c;
80100791:	8d 50 01             	lea    0x1(%eax),%edx
80100794:	89 15 c8 ff 10 80    	mov    %edx,0x8010ffc8
8010079a:	83 e0 7f             	and    $0x7f,%eax
8010079d:	89 f9                	mov    %edi,%ecx
8010079f:	88 88 40 ff 10 80    	mov    %cl,-0x7fef00c0(%eax)
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
801007bc:	a1 c0 ff 10 80       	mov    0x8010ffc0,%eax
801007c1:	83 e8 80             	sub    $0xffffff80,%eax
801007c4:	39 05 c8 ff 10 80    	cmp    %eax,0x8010ffc8
801007ca:	75 5a                	jne    80100826 <consoleintr+0xe8>
          input.w = input.e;
801007cc:	a1 c8 ff 10 80       	mov    0x8010ffc8,%eax
801007d1:	a3 c4 ff 10 80       	mov    %eax,0x8010ffc4
          wakeup(&input.r);
801007d6:	83 ec 0c             	sub    $0xc,%esp
801007d9:	68 c0 ff 10 80       	push   $0x8010ffc0
801007de:	e8 84 33 00 00       	call   80103b67 <wakeup>
801007e3:	83 c4 10             	add    $0x10,%esp
801007e6:	eb 3e                	jmp    80100826 <consoleintr+0xe8>
        input.e--;
801007e8:	a3 c8 ff 10 80       	mov    %eax,0x8010ffc8
        consputc(BACKSPACE);
801007ed:	b8 00 01 00 00       	mov    $0x100,%eax
801007f2:	e8 ef fc ff ff       	call   801004e6 <consputc>
      while(input.e != input.w &&
801007f7:	a1 c8 ff 10 80       	mov    0x8010ffc8,%eax
801007fc:	3b 05 c4 ff 10 80    	cmp    0x8010ffc4,%eax
80100802:	74 22                	je     80100826 <consoleintr+0xe8>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100804:	83 e8 01             	sub    $0x1,%eax
80100807:	89 c2                	mov    %eax,%edx
80100809:	83 e2 7f             	and    $0x7f,%edx
      while(input.e != input.w &&
8010080c:	80 ba 40 ff 10 80 0a 	cmpb   $0xa,-0x7fef00c0(%edx)
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
8010084a:	a1 c8 ff 10 80       	mov    0x8010ffc8,%eax
8010084f:	3b 05 c4 ff 10 80    	cmp    0x8010ffc4,%eax
80100855:	74 cf                	je     80100826 <consoleintr+0xe8>
        input.e--;
80100857:	83 e8 01             	sub    $0x1,%eax
8010085a:	a3 c8 ff 10 80       	mov    %eax,0x8010ffc8
        consputc(BACKSPACE);
8010085f:	b8 00 01 00 00       	mov    $0x100,%eax
80100864:	e8 7d fc ff ff       	call   801004e6 <consputc>
80100869:	eb bb                	jmp    80100826 <consoleintr+0xe8>
  release(&cons.lock);
8010086b:	83 ec 0c             	sub    $0xc,%esp
8010086e:	68 20 a5 10 80       	push   $0x8010a520
80100873:	e8 ea 36 00 00       	call   80103f62 <release>
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
80100887:	e8 78 33 00 00       	call   80103c04 <procdump>
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
80100894:	68 a8 68 10 80       	push   $0x801068a8
80100899:	68 20 a5 10 80       	push   $0x8010a520
8010089e:	e8 1e 35 00 00       	call   80103dc1 <initlock>

  devsw[CONSOLE].write = consolewrite;
801008a3:	c7 05 8c 09 11 80 ac 	movl   $0x801005ac,0x8011098c
801008aa:	05 10 80 
  devsw[CONSOLE].read = consoleread;
801008ad:	c7 05 88 09 11 80 68 	movl   $0x80100268,0x80110988
801008b4:	02 10 80 
  cons.locking = 1;
801008b7:	c7 05 54 a5 10 80 01 	movl   $0x1,0x8010a554
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
801008de:	e8 78 2c 00 00       	call   8010355b <myproc>
801008e3:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)

  begin_op();
801008e9:	e8 12 22 00 00       	call   80102b00 <begin_op>

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
80100935:	e8 40 22 00 00       	call   80102b7a <end_op>
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
8010094a:	e8 2b 22 00 00       	call   80102b7a <end_op>
    cprintf("exec: fail\n");
8010094f:	83 ec 0c             	sub    $0xc,%esp
80100952:	68 c1 68 10 80       	push   $0x801068c1
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
80100972:	e8 4c 5c 00 00       	call   801065c3 <setupkvm>
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
80100a0c:	e8 4f 5a 00 00       	call   80106460 <allocuvm>
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
80100a3e:	e8 eb 58 00 00       	call   8010632e <loaduvm>
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
80100a59:	e8 1c 21 00 00       	call   80102b7a <end_op>
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
80100a80:	e8 db 59 00 00       	call   80106460 <allocuvm>
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
80100aa9:	e8 a5 5a 00 00       	call   80106553 <freevm>
80100aae:	83 c4 10             	add    $0x10,%esp
80100ab1:	e9 6e fe ff ff       	jmp    80100924 <exec+0x52>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100ab6:	89 c7                	mov    %eax,%edi
80100ab8:	8d 80 00 e0 ff ff    	lea    -0x2000(%eax),%eax
80100abe:	83 ec 08             	sub    $0x8,%esp
80100ac1:	50                   	push   %eax
80100ac2:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100ac8:	e8 83 5b 00 00       	call   80106650 <clearpteu>
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
80100aee:	e8 58 36 00 00       	call   8010414b <strlen>
80100af3:	29 c7                	sub    %eax,%edi
80100af5:	83 ef 01             	sub    $0x1,%edi
80100af8:	83 e7 fc             	and    $0xfffffffc,%edi
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100afb:	83 c4 04             	add    $0x4,%esp
80100afe:	ff 33                	pushl  (%ebx)
80100b00:	e8 46 36 00 00       	call   8010414b <strlen>
80100b05:	83 c0 01             	add    $0x1,%eax
80100b08:	50                   	push   %eax
80100b09:	ff 33                	pushl  (%ebx)
80100b0b:	57                   	push   %edi
80100b0c:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b12:	e8 94 5c 00 00       	call   801067ab <copyout>
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
80100b72:	e8 34 5c 00 00       	call   801067ab <copyout>
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
80100baf:	e8 5c 35 00 00       	call   80104110 <safestrcpy>
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
80100bdd:	e8 c6 55 00 00       	call   801061a8 <switchuvm>
  freevm(oldpgdir);
80100be2:	89 1c 24             	mov    %ebx,(%esp)
80100be5:	e8 69 59 00 00       	call   80106553 <freevm>
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
80100c25:	68 cd 68 10 80       	push   $0x801068cd
80100c2a:	68 e0 ff 10 80       	push   $0x8010ffe0
80100c2f:	e8 8d 31 00 00       	call   80103dc1 <initlock>
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
80100c40:	68 e0 ff 10 80       	push   $0x8010ffe0
80100c45:	e8 b3 32 00 00       	call   80103efd <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100c4a:	83 c4 10             	add    $0x10,%esp
80100c4d:	bb 14 00 11 80       	mov    $0x80110014,%ebx
80100c52:	81 fb 74 09 11 80    	cmp    $0x80110974,%ebx
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
80100c6f:	68 e0 ff 10 80       	push   $0x8010ffe0
80100c74:	e8 e9 32 00 00       	call   80103f62 <release>
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
80100c86:	68 e0 ff 10 80       	push   $0x8010ffe0
80100c8b:	e8 d2 32 00 00       	call   80103f62 <release>
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
80100ca4:	68 e0 ff 10 80       	push   $0x8010ffe0
80100ca9:	e8 4f 32 00 00       	call   80103efd <acquire>
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
80100cc1:	68 e0 ff 10 80       	push   $0x8010ffe0
80100cc6:	e8 97 32 00 00       	call   80103f62 <release>
  return f;
}
80100ccb:	89 d8                	mov    %ebx,%eax
80100ccd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100cd0:	c9                   	leave  
80100cd1:	c3                   	ret    
    panic("filedup");
80100cd2:	83 ec 0c             	sub    $0xc,%esp
80100cd5:	68 d4 68 10 80       	push   $0x801068d4
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
80100ce9:	68 e0 ff 10 80       	push   $0x8010ffe0
80100cee:	e8 0a 32 00 00       	call   80103efd <acquire>
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
80100d0a:	68 e0 ff 10 80       	push   $0x8010ffe0
80100d0f:	e8 4e 32 00 00       	call   80103f62 <release>
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
80100d1f:	68 dc 68 10 80       	push   $0x801068dc
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
80100d50:	68 e0 ff 10 80       	push   $0x8010ffe0
80100d55:	e8 08 32 00 00       	call   80103f62 <release>
  if(ff.type == FD_PIPE)
80100d5a:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d5d:	83 c4 10             	add    $0x10,%esp
80100d60:	83 f8 01             	cmp    $0x1,%eax
80100d63:	74 1f                	je     80100d84 <fileclose+0xa5>
  else if(ff.type == FD_INODE){
80100d65:	83 f8 02             	cmp    $0x2,%eax
80100d68:	75 ad                	jne    80100d17 <fileclose+0x38>
    begin_op();
80100d6a:	e8 91 1d 00 00       	call   80102b00 <begin_op>
    iput(ff.ip);
80100d6f:	83 ec 0c             	sub    $0xc,%esp
80100d72:	ff 75 f0             	pushl  -0x10(%ebp)
80100d75:	e8 1a 09 00 00       	call   80101694 <iput>
    end_op();
80100d7a:	e8 fb 1d 00 00       	call   80102b7a <end_op>
80100d7f:	83 c4 10             	add    $0x10,%esp
80100d82:	eb 93                	jmp    80100d17 <fileclose+0x38>
    pipeclose(ff.pipe, ff.writable);
80100d84:	83 ec 08             	sub    $0x8,%esp
80100d87:	0f be 45 e9          	movsbl -0x17(%ebp),%eax
80100d8b:	50                   	push   %eax
80100d8c:	ff 75 ec             	pushl  -0x14(%ebp)
80100d8f:	e8 ed 23 00 00       	call   80103181 <pipeclose>
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
80100e48:	e8 8c 24 00 00       	call   801032d9 <piperead>
80100e4d:	89 c6                	mov    %eax,%esi
80100e4f:	83 c4 10             	add    $0x10,%esp
80100e52:	eb df                	jmp    80100e33 <fileread+0x50>
  panic("fileread");
80100e54:	83 ec 0c             	sub    $0xc,%esp
80100e57:	68 e6 68 10 80       	push   $0x801068e6
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
80100ea1:	e8 67 23 00 00       	call   8010320d <pipewrite>
80100ea6:	83 c4 10             	add    $0x10,%esp
80100ea9:	e9 80 00 00 00       	jmp    80100f2e <filewrite+0xc6>
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
80100eae:	e8 4d 1c 00 00       	call   80102b00 <begin_op>
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
80100ee9:	e8 8c 1c 00 00       	call   80102b7a <end_op>

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
80100f1c:	68 ef 68 10 80       	push   $0x801068ef
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
80100f39:	68 f5 68 10 80       	push   $0x801068f5
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
80100f96:	e8 89 30 00 00       	call   80104024 <memmove>
80100f9b:	83 c4 10             	add    $0x10,%esp
80100f9e:	eb 17                	jmp    80100fb7 <skipelem+0x66>
  else {
    memmove(name, s, len);
80100fa0:	83 ec 04             	sub    $0x4,%esp
80100fa3:	56                   	push   %esi
80100fa4:	50                   	push   %eax
80100fa5:	57                   	push   %edi
80100fa6:	e8 79 30 00 00       	call   80104024 <memmove>
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
80100feb:	e8 b9 2f 00 00       	call   80103fa9 <memset>
  log_write(bp);
80100ff0:	89 1c 24             	mov    %ebx,(%esp)
80100ff3:	e8 31 1c 00 00       	call   80102c29 <log_write>
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
8010102f:	39 35 e0 09 11 80    	cmp    %esi,0x801109e0
80101035:	76 75                	jbe    801010ac <balloc+0xa4>
    bp = bread(dev, BBLOCK(b, sb));
80101037:	8d 86 ff 0f 00 00    	lea    0xfff(%esi),%eax
8010103d:	85 f6                	test   %esi,%esi
8010103f:	0f 49 c6             	cmovns %esi,%eax
80101042:	c1 f8 0c             	sar    $0xc,%eax
80101045:	03 05 f8 09 11 80    	add    0x801109f8,%eax
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
8010106f:	3b 1d e0 09 11 80    	cmp    0x801109e0,%ebx
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
801010af:	68 ff 68 10 80       	push   $0x801068ff
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
801010cb:	e8 59 1b 00 00       	call   80102c29 <log_write>
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
8010117c:	e8 a8 1a 00 00       	call   80102c29 <log_write>
80101181:	83 c4 10             	add    $0x10,%esp
80101184:	eb bf                	jmp    80101145 <bmap+0x58>
  panic("bmap: out of range");
80101186:	83 ec 0c             	sub    $0xc,%esp
80101189:	68 15 69 10 80       	push   $0x80106915
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
801011a1:	68 00 0a 11 80       	push   $0x80110a00
801011a6:	e8 52 2d 00 00       	call   80103efd <acquire>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801011ab:	83 c4 10             	add    $0x10,%esp
  empty = 0;
801011ae:	be 00 00 00 00       	mov    $0x0,%esi
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801011b3:	bb 34 0a 11 80       	mov    $0x80110a34,%ebx
801011b8:	eb 0a                	jmp    801011c4 <iget+0x31>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801011ba:	85 f6                	test   %esi,%esi
801011bc:	74 3b                	je     801011f9 <iget+0x66>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801011be:	81 c3 90 00 00 00    	add    $0x90,%ebx
801011c4:	81 fb 54 26 11 80    	cmp    $0x80112654,%ebx
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
801011e8:	68 00 0a 11 80       	push   $0x80110a00
801011ed:	e8 70 2d 00 00       	call   80103f62 <release>
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
8010121e:	68 00 0a 11 80       	push   $0x80110a00
80101223:	e8 3a 2d 00 00       	call   80103f62 <release>
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
80101238:	68 28 69 10 80       	push   $0x80106928
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
80101261:	e8 be 2d 00 00       	call   80104024 <memmove>
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
80101282:	68 e0 09 11 80       	push   $0x801109e0
80101287:	50                   	push   %eax
80101288:	e8 b5 ff ff ff       	call   80101242 <readsb>
  bp = bread(dev, BBLOCK(b, sb));
8010128d:	89 d8                	mov    %ebx,%eax
8010128f:	c1 e8 0c             	shr    $0xc,%eax
80101292:	03 05 f8 09 11 80    	add    0x801109f8,%eax
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
801012d4:	e8 50 19 00 00       	call   80102c29 <log_write>
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
801012ee:	68 38 69 10 80       	push   $0x80106938
801012f3:	e8 50 f0 ff ff       	call   80100348 <panic>

801012f8 <iinit>:
{
801012f8:	55                   	push   %ebp
801012f9:	89 e5                	mov    %esp,%ebp
801012fb:	53                   	push   %ebx
801012fc:	83 ec 0c             	sub    $0xc,%esp
  initlock(&icache.lock, "icache");
801012ff:	68 4b 69 10 80       	push   $0x8010694b
80101304:	68 00 0a 11 80       	push   $0x80110a00
80101309:	e8 b3 2a 00 00       	call   80103dc1 <initlock>
  for(i = 0; i < NINODE; i++) {
8010130e:	83 c4 10             	add    $0x10,%esp
80101311:	bb 00 00 00 00       	mov    $0x0,%ebx
80101316:	eb 21                	jmp    80101339 <iinit+0x41>
    initsleeplock(&icache.inode[i].lock, "inode");
80101318:	83 ec 08             	sub    $0x8,%esp
8010131b:	68 52 69 10 80       	push   $0x80106952
80101320:	8d 14 db             	lea    (%ebx,%ebx,8),%edx
80101323:	89 d0                	mov    %edx,%eax
80101325:	c1 e0 04             	shl    $0x4,%eax
80101328:	05 40 0a 11 80       	add    $0x80110a40,%eax
8010132d:	50                   	push   %eax
8010132e:	e8 83 29 00 00       	call   80103cb6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
80101333:	83 c3 01             	add    $0x1,%ebx
80101336:	83 c4 10             	add    $0x10,%esp
80101339:	83 fb 31             	cmp    $0x31,%ebx
8010133c:	7e da                	jle    80101318 <iinit+0x20>
  readsb(dev, &sb);
8010133e:	83 ec 08             	sub    $0x8,%esp
80101341:	68 e0 09 11 80       	push   $0x801109e0
80101346:	ff 75 08             	pushl  0x8(%ebp)
80101349:	e8 f4 fe ff ff       	call   80101242 <readsb>
  cprintf("sb: size %d nblocks %d ninodes %d nlog %d logstart %d\
8010134e:	ff 35 f8 09 11 80    	pushl  0x801109f8
80101354:	ff 35 f4 09 11 80    	pushl  0x801109f4
8010135a:	ff 35 f0 09 11 80    	pushl  0x801109f0
80101360:	ff 35 ec 09 11 80    	pushl  0x801109ec
80101366:	ff 35 e8 09 11 80    	pushl  0x801109e8
8010136c:	ff 35 e4 09 11 80    	pushl  0x801109e4
80101372:	ff 35 e0 09 11 80    	pushl  0x801109e0
80101378:	68 b8 69 10 80       	push   $0x801069b8
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
801013a1:	39 1d e8 09 11 80    	cmp    %ebx,0x801109e8
801013a7:	76 3f                	jbe    801013e8 <ialloc+0x5e>
    bp = bread(dev, IBLOCK(inum, sb));
801013a9:	89 d8                	mov    %ebx,%eax
801013ab:	c1 e8 03             	shr    $0x3,%eax
801013ae:	03 05 f4 09 11 80    	add    0x801109f4,%eax
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
801013eb:	68 58 69 10 80       	push   $0x80106958
801013f0:	e8 53 ef ff ff       	call   80100348 <panic>
      memset(dip, 0, sizeof(*dip));
801013f5:	83 ec 04             	sub    $0x4,%esp
801013f8:	6a 40                	push   $0x40
801013fa:	6a 00                	push   $0x0
801013fc:	57                   	push   %edi
801013fd:	e8 a7 2b 00 00       	call   80103fa9 <memset>
      dip->type = type;
80101402:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80101406:	66 89 07             	mov    %ax,(%edi)
      log_write(bp);   // mark it allocated on the disk
80101409:	89 34 24             	mov    %esi,(%esp)
8010140c:	e8 18 18 00 00       	call   80102c29 <log_write>
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
8010143a:	03 05 f4 09 11 80    	add    0x801109f4,%eax
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
8010148c:	e8 93 2b 00 00       	call   80104024 <memmove>
  log_write(bp);
80101491:	89 34 24             	mov    %esi,(%esp)
80101494:	e8 90 17 00 00       	call   80102c29 <log_write>
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
80101567:	68 00 0a 11 80       	push   $0x80110a00
8010156c:	e8 8c 29 00 00       	call   80103efd <acquire>
  ip->ref++;
80101571:	8b 43 08             	mov    0x8(%ebx),%eax
80101574:	83 c0 01             	add    $0x1,%eax
80101577:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
8010157a:	c7 04 24 00 0a 11 80 	movl   $0x80110a00,(%esp)
80101581:	e8 dc 29 00 00       	call   80103f62 <release>
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
801015a6:	e8 3e 27 00 00       	call   80103ce9 <acquiresleep>
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
801015be:	68 6a 69 10 80       	push   $0x8010696a
801015c3:	e8 80 ed ff ff       	call   80100348 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
801015c8:	8b 43 04             	mov    0x4(%ebx),%eax
801015cb:	c1 e8 03             	shr    $0x3,%eax
801015ce:	03 05 f4 09 11 80    	add    0x801109f4,%eax
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
80101620:	e8 ff 29 00 00       	call   80104024 <memmove>
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
80101645:	68 70 69 10 80       	push   $0x80106970
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
80101662:	e8 0c 27 00 00       	call   80103d73 <holdingsleep>
80101667:	83 c4 10             	add    $0x10,%esp
8010166a:	85 c0                	test   %eax,%eax
8010166c:	74 19                	je     80101687 <iunlock+0x38>
8010166e:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101672:	7e 13                	jle    80101687 <iunlock+0x38>
  releasesleep(&ip->lock);
80101674:	83 ec 0c             	sub    $0xc,%esp
80101677:	56                   	push   %esi
80101678:	e8 bb 26 00 00       	call   80103d38 <releasesleep>
}
8010167d:	83 c4 10             	add    $0x10,%esp
80101680:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101683:	5b                   	pop    %ebx
80101684:	5e                   	pop    %esi
80101685:	5d                   	pop    %ebp
80101686:	c3                   	ret    
    panic("iunlock");
80101687:	83 ec 0c             	sub    $0xc,%esp
8010168a:	68 7f 69 10 80       	push   $0x8010697f
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
801016a4:	e8 40 26 00 00       	call   80103ce9 <acquiresleep>
  if(ip->valid && ip->nlink == 0){
801016a9:	83 c4 10             	add    $0x10,%esp
801016ac:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801016b0:	74 07                	je     801016b9 <iput+0x25>
801016b2:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801016b7:	74 35                	je     801016ee <iput+0x5a>
  releasesleep(&ip->lock);
801016b9:	83 ec 0c             	sub    $0xc,%esp
801016bc:	56                   	push   %esi
801016bd:	e8 76 26 00 00       	call   80103d38 <releasesleep>
  acquire(&icache.lock);
801016c2:	c7 04 24 00 0a 11 80 	movl   $0x80110a00,(%esp)
801016c9:	e8 2f 28 00 00       	call   80103efd <acquire>
  ip->ref--;
801016ce:	8b 43 08             	mov    0x8(%ebx),%eax
801016d1:	83 e8 01             	sub    $0x1,%eax
801016d4:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
801016d7:	c7 04 24 00 0a 11 80 	movl   $0x80110a00,(%esp)
801016de:	e8 7f 28 00 00       	call   80103f62 <release>
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
801016f1:	68 00 0a 11 80       	push   $0x80110a00
801016f6:	e8 02 28 00 00       	call   80103efd <acquire>
    int r = ip->ref;
801016fb:	8b 7b 08             	mov    0x8(%ebx),%edi
    release(&icache.lock);
801016fe:	c7 04 24 00 0a 11 80 	movl   $0x80110a00,(%esp)
80101705:	e8 58 28 00 00       	call   80103f62 <release>
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
801017d0:	8b 04 c5 80 09 11 80 	mov    -0x7feef680(,%eax,8),%eax
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
80101836:	e8 e9 27 00 00       	call   80104024 <memmove>
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
801018cd:	8b 04 c5 84 09 11 80 	mov    -0x7feef67c(,%eax,8),%eax
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
80101932:	e8 ed 26 00 00       	call   80104024 <memmove>
    log_write(bp);
80101937:	89 3c 24             	mov    %edi,(%esp)
8010193a:	e8 ea 12 00 00       	call   80102c29 <log_write>
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
801019b5:	e8 d1 26 00 00       	call   8010408b <strncmp>
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
801019dc:	68 87 69 10 80       	push   $0x80106987
801019e1:	e8 62 e9 ff ff       	call   80100348 <panic>
      panic("dirlookup read");
801019e6:	83 ec 0c             	sub    $0xc,%esp
801019e9:	68 99 69 10 80       	push   $0x80106999
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
80101a66:	e8 f0 1a 00 00       	call   8010355b <myproc>
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
80101b9e:	68 a8 69 10 80       	push   $0x801069a8
80101ba3:	e8 a0 e7 ff ff       	call   80100348 <panic>
  strncpy(de.name, name, DIRSIZ);
80101ba8:	83 ec 04             	sub    $0x4,%esp
80101bab:	6a 0e                	push   $0xe
80101bad:	57                   	push   %edi
80101bae:	8d 7d d8             	lea    -0x28(%ebp),%edi
80101bb1:	8d 45 da             	lea    -0x26(%ebp),%eax
80101bb4:	50                   	push   %eax
80101bb5:	e8 0e 25 00 00       	call   801040c8 <strncpy>
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
80101be3:	68 b4 6f 10 80       	push   $0x80106fb4
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
80101cd8:	68 0b 6a 10 80       	push   $0x80106a0b
80101cdd:	e8 66 e6 ff ff       	call   80100348 <panic>
    panic("incorrect blockno");
80101ce2:	83 ec 0c             	sub    $0xc,%esp
80101ce5:	68 14 6a 10 80       	push   $0x80106a14
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
80101d12:	68 26 6a 10 80       	push   $0x80106a26
80101d17:	68 80 a5 10 80       	push   $0x8010a580
80101d1c:	e8 a0 20 00 00       	call   80103dc1 <initlock>
  ioapicenable(IRQ_IDE, ncpu - 1);
80101d21:	83 c4 08             	add    $0x8,%esp
80101d24:	a1 40 2d 19 80       	mov    0x80192d40,%eax
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
80101d68:	c7 05 60 a5 10 80 01 	movl   $0x1,0x8010a560
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
80101d87:	68 80 a5 10 80       	push   $0x8010a580
80101d8c:	e8 6c 21 00 00       	call   80103efd <acquire>

  if((b = idequeue) == 0){
80101d91:	8b 1d 64 a5 10 80    	mov    0x8010a564,%ebx
80101d97:	83 c4 10             	add    $0x10,%esp
80101d9a:	85 db                	test   %ebx,%ebx
80101d9c:	74 48                	je     80101de6 <ideintr+0x67>
    release(&idelock);
    return;
  }
  idequeue = b->qnext;
80101d9e:	8b 43 58             	mov    0x58(%ebx),%eax
80101da1:	a3 64 a5 10 80       	mov    %eax,0x8010a564

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
80101db9:	e8 a9 1d 00 00       	call   80103b67 <wakeup>

  // Start disk on next buf in queue.
  if(idequeue != 0)
80101dbe:	a1 64 a5 10 80       	mov    0x8010a564,%eax
80101dc3:	83 c4 10             	add    $0x10,%esp
80101dc6:	85 c0                	test   %eax,%eax
80101dc8:	74 05                	je     80101dcf <ideintr+0x50>
    idestart(idequeue);
80101dca:	e8 80 fe ff ff       	call   80101c4f <idestart>

  release(&idelock);
80101dcf:	83 ec 0c             	sub    $0xc,%esp
80101dd2:	68 80 a5 10 80       	push   $0x8010a580
80101dd7:	e8 86 21 00 00       	call   80103f62 <release>
80101ddc:	83 c4 10             	add    $0x10,%esp
}
80101ddf:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101de2:	5b                   	pop    %ebx
80101de3:	5f                   	pop    %edi
80101de4:	5d                   	pop    %ebp
80101de5:	c3                   	ret    
    release(&idelock);
80101de6:	83 ec 0c             	sub    $0xc,%esp
80101de9:	68 80 a5 10 80       	push   $0x8010a580
80101dee:	e8 6f 21 00 00       	call   80103f62 <release>
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
80101e26:	e8 48 1f 00 00       	call   80103d73 <holdingsleep>
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
80101e42:	83 3d 60 a5 10 80 00 	cmpl   $0x0,0x8010a560
80101e49:	74 38                	je     80101e83 <iderw+0x6b>
    panic("iderw: ide disk 1 not present");

  acquire(&idelock);  //DOC:acquire-lock
80101e4b:	83 ec 0c             	sub    $0xc,%esp
80101e4e:	68 80 a5 10 80       	push   $0x8010a580
80101e53:	e8 a5 20 00 00       	call   80103efd <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80101e58:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e5f:	83 c4 10             	add    $0x10,%esp
80101e62:	ba 64 a5 10 80       	mov    $0x8010a564,%edx
80101e67:	eb 2a                	jmp    80101e93 <iderw+0x7b>
    panic("iderw: buf not locked");
80101e69:	83 ec 0c             	sub    $0xc,%esp
80101e6c:	68 2a 6a 10 80       	push   $0x80106a2a
80101e71:	e8 d2 e4 ff ff       	call   80100348 <panic>
    panic("iderw: nothing to do");
80101e76:	83 ec 0c             	sub    $0xc,%esp
80101e79:	68 40 6a 10 80       	push   $0x80106a40
80101e7e:	e8 c5 e4 ff ff       	call   80100348 <panic>
    panic("iderw: ide disk 1 not present");
80101e83:	83 ec 0c             	sub    $0xc,%esp
80101e86:	68 55 6a 10 80       	push   $0x80106a55
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
80101e9b:	39 1d 64 a5 10 80    	cmp    %ebx,0x8010a564
80101ea1:	75 1a                	jne    80101ebd <iderw+0xa5>
    idestart(b);
80101ea3:	89 d8                	mov    %ebx,%eax
80101ea5:	e8 a5 fd ff ff       	call   80101c4f <idestart>
80101eaa:	eb 11                	jmp    80101ebd <iderw+0xa5>

  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
    sleep(b, &idelock);
80101eac:	83 ec 08             	sub    $0x8,%esp
80101eaf:	68 80 a5 10 80       	push   $0x8010a580
80101eb4:	53                   	push   %ebx
80101eb5:	e8 48 1b 00 00       	call   80103a02 <sleep>
80101eba:	83 c4 10             	add    $0x10,%esp
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80101ebd:	8b 03                	mov    (%ebx),%eax
80101ebf:	83 e0 06             	and    $0x6,%eax
80101ec2:	83 f8 02             	cmp    $0x2,%eax
80101ec5:	75 e5                	jne    80101eac <iderw+0x94>
  }


  release(&idelock);
80101ec7:	83 ec 0c             	sub    $0xc,%esp
80101eca:	68 80 a5 10 80       	push   $0x8010a580
80101ecf:	e8 8e 20 00 00       	call   80103f62 <release>
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
80101edf:	8b 15 54 26 11 80    	mov    0x80112654,%edx
80101ee5:	89 02                	mov    %eax,(%edx)
  return ioapic->data;
80101ee7:	a1 54 26 11 80       	mov    0x80112654,%eax
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
80101ef4:	8b 0d 54 26 11 80    	mov    0x80112654,%ecx
80101efa:	89 01                	mov    %eax,(%ecx)
  ioapic->data = data;
80101efc:	a1 54 26 11 80       	mov    0x80112654,%eax
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
80101f0f:	c7 05 54 26 11 80 00 	movl   $0xfec00000,0x80112654
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
80101f36:	0f b6 15 a0 27 19 80 	movzbl 0x801927a0,%edx
80101f3d:	39 c2                	cmp    %eax,%edx
80101f3f:	75 07                	jne    80101f48 <ioapicinit+0x42>
{
80101f41:	bb 00 00 00 00       	mov    $0x0,%ebx
80101f46:	eb 36                	jmp    80101f7e <ioapicinit+0x78>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80101f48:	83 ec 0c             	sub    $0xc,%esp
80101f4b:	68 74 6a 10 80       	push   $0x80106a74
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

80101fb0 <findIndexinframeArr>:
// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
int findIndexinframeArr(int frame)
{
80101fb0:	55                   	push   %ebp
80101fb1:	89 e5                	mov    %esp,%ebp
80101fb3:	8b 55 08             	mov    0x8(%ebp),%edx
  for(int i=0; i<65536; i++){
80101fb6:	b8 00 00 00 00       	mov    $0x0,%eax
80101fbb:	3d ff ff 00 00       	cmp    $0xffff,%eax
80101fc0:	7f 0e                	jg     80101fd0 <findIndexinframeArr+0x20>

                if(frame == framearr[i])
80101fc2:	39 14 85 a0 26 15 80 	cmp    %edx,-0x7fead960(,%eax,4)
80101fc9:	74 0a                	je     80101fd5 <findIndexinframeArr+0x25>
  for(int i=0; i<65536; i++){
80101fcb:	83 c0 01             	add    $0x1,%eax
80101fce:	eb eb                	jmp    80101fbb <findIndexinframeArr+0xb>
                {
                  return i;
                }
        }
  return -1;
80101fd0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80101fd5:	5d                   	pop    %ebp
80101fd6:	c3                   	ret    

80101fd7 <getPidforFrame>:

int getPidforFrame(int frame)
{
80101fd7:	55                   	push   %ebp
80101fd8:	89 e5                	mov    %esp,%ebp
80101fda:	8b 55 08             	mov    0x8(%ebp),%edx
        for(int i=0; i<65536; i++){
80101fdd:	b8 00 00 00 00       	mov    $0x0,%eax
80101fe2:	3d ff ff 00 00       	cmp    $0xffff,%eax
80101fe7:	7f 17                	jg     80102000 <getPidforFrame+0x29>

                if(frame == framearr[i])
80101fe9:	39 14 85 a0 26 15 80 	cmp    %edx,-0x7fead960(,%eax,4)
80101ff0:	74 05                	je     80101ff7 <getPidforFrame+0x20>
        for(int i=0; i<65536; i++){
80101ff2:	83 c0 01             	add    $0x1,%eax
80101ff5:	eb eb                	jmp    80101fe2 <getPidforFrame+0xb>
                {
                  return pidarr[i];
80101ff7:	8b 04 85 a0 26 11 80 	mov    -0x7feed960(,%eax,4),%eax
                }
        }

        return -1;
}
80101ffe:	5d                   	pop    %ebp
80101fff:	c3                   	ret    
        return -1;
80102000:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102005:	eb f7                	jmp    80101ffe <getPidforFrame+0x27>

80102007 <kfree>:


void
kfree(char *v)
{
80102007:	55                   	push   %ebp
80102008:	89 e5                	mov    %esp,%ebp
8010200a:	56                   	push   %esi
8010200b:	53                   	push   %ebx
8010200c:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct run *r;

  if((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
8010200f:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
80102015:	0f 85 93 00 00 00    	jne    801020ae <kfree+0xa7>
8010201b:	81 fb e8 54 19 80    	cmp    $0x801954e8,%ebx
80102021:	0f 82 87 00 00 00    	jb     801020ae <kfree+0xa7>
80102027:	8d b3 00 00 00 80    	lea    -0x80000000(%ebx),%esi
8010202d:	81 fe ff ff ff 0d    	cmp    $0xdffffff,%esi
80102033:	77 79                	ja     801020ae <kfree+0xa7>
    panic("kfree");
   inidone =1;
80102035:	c7 05 b4 a5 10 80 01 	movl   $0x1,0x8010a5b4
8010203c:	00 00 00 
  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
8010203f:	83 ec 04             	sub    $0x4,%esp
80102042:	68 00 10 00 00       	push   $0x1000
80102047:	6a 01                	push   $0x1
80102049:	53                   	push   %ebx
8010204a:	e8 5a 1f 00 00       	call   80103fa9 <memset>

  if(kmem.use_lock)
8010204f:	83 c4 10             	add    $0x10,%esp
80102052:	83 3d 94 26 11 80 00 	cmpl   $0x0,0x80112694
80102059:	75 60                	jne    801020bb <kfree+0xb4>
    acquire(&kmem.lock);
  r = (struct run*)v;
  r->next = kmem.freelist;
8010205b:	a1 98 26 11 80       	mov    0x80112698,%eax
80102060:	89 03                	mov    %eax,(%ebx)
  kmem.freelist = r;
80102062:	89 1d 98 26 11 80    	mov    %ebx,0x80112698

   
  if(inidone){
80102068:	83 3d b4 a5 10 80 00 	cmpl   $0x0,0x8010a5b4
8010206f:	74 2d                	je     8010209e <kfree+0x97>
  int pa;
  int framenum;
  pa = V2P(r);
  framenum = (pa >> 12) & 0xffff;
80102071:	c1 fe 0c             	sar    $0xc,%esi
80102074:	0f b7 f6             	movzwl %si,%esi
  int i = findIndexinframeArr(framenum);
80102077:	83 ec 0c             	sub    $0xc,%esp
8010207a:	56                   	push   %esi
8010207b:	e8 30 ff ff ff       	call   80101fb0 <findIndexinframeArr>
80102080:	83 c4 10             	add    $0x10,%esp
 // cprintf("I am freeing frame %x at i val: %d",framenum,i);
  if(i!=-1){
80102083:	83 f8 ff             	cmp    $0xffffffff,%eax
80102086:	74 16                	je     8010209e <kfree+0x97>
  framearr[i]=-1;
80102088:	c7 04 85 a0 26 15 80 	movl   $0xffffffff,-0x7fead960(,%eax,4)
8010208f:	ff ff ff ff 
  pidarr[i]=-1;
80102093:	c7 04 85 a0 26 11 80 	movl   $0xffffffff,-0x7feed960(,%eax,4)
8010209a:	ff ff ff ff 
  }
  }
  if(kmem.use_lock)
8010209e:	83 3d 94 26 11 80 00 	cmpl   $0x0,0x80112694
801020a5:	75 26                	jne    801020cd <kfree+0xc6>
    release(&kmem.lock);
}
801020a7:	8d 65 f8             	lea    -0x8(%ebp),%esp
801020aa:	5b                   	pop    %ebx
801020ab:	5e                   	pop    %esi
801020ac:	5d                   	pop    %ebp
801020ad:	c3                   	ret    
    panic("kfree");
801020ae:	83 ec 0c             	sub    $0xc,%esp
801020b1:	68 a6 6a 10 80       	push   $0x80106aa6
801020b6:	e8 8d e2 ff ff       	call   80100348 <panic>
    acquire(&kmem.lock);
801020bb:	83 ec 0c             	sub    $0xc,%esp
801020be:	68 60 26 11 80       	push   $0x80112660
801020c3:	e8 35 1e 00 00       	call   80103efd <acquire>
801020c8:	83 c4 10             	add    $0x10,%esp
801020cb:	eb 8e                	jmp    8010205b <kfree+0x54>
    release(&kmem.lock);
801020cd:	83 ec 0c             	sub    $0xc,%esp
801020d0:	68 60 26 11 80       	push   $0x80112660
801020d5:	e8 88 1e 00 00       	call   80103f62 <release>
801020da:	83 c4 10             	add    $0x10,%esp
}
801020dd:	eb c8                	jmp    801020a7 <kfree+0xa0>

801020df <freerange>:
{
801020df:	55                   	push   %ebp
801020e0:	89 e5                	mov    %esp,%ebp
801020e2:	56                   	push   %esi
801020e3:	53                   	push   %ebx
801020e4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  p = (char*)PGROUNDUP((uint)vstart);
801020e7:	8b 45 08             	mov    0x8(%ebp),%eax
801020ea:	05 ff 0f 00 00       	add    $0xfff,%eax
801020ef:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
801020f4:	eb 0e                	jmp    80102104 <freerange+0x25>
    kfree(p);
801020f6:	83 ec 0c             	sub    $0xc,%esp
801020f9:	50                   	push   %eax
801020fa:	e8 08 ff ff ff       	call   80102007 <kfree>
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
801020ff:	83 c4 10             	add    $0x10,%esp
80102102:	89 f0                	mov    %esi,%eax
80102104:	8d b0 00 10 00 00    	lea    0x1000(%eax),%esi
8010210a:	39 de                	cmp    %ebx,%esi
8010210c:	76 e8                	jbe    801020f6 <freerange+0x17>
}
8010210e:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102111:	5b                   	pop    %ebx
80102112:	5e                   	pop    %esi
80102113:	5d                   	pop    %ebp
80102114:	c3                   	ret    

80102115 <kinit1>:
{
80102115:	55                   	push   %ebp
80102116:	89 e5                	mov    %esp,%ebp
80102118:	83 ec 10             	sub    $0x10,%esp
  initlock(&kmem.lock, "kmem");
8010211b:	68 ac 6a 10 80       	push   $0x80106aac
80102120:	68 60 26 11 80       	push   $0x80112660
80102125:	e8 97 1c 00 00       	call   80103dc1 <initlock>
  kmem.use_lock = 0;
8010212a:	c7 05 94 26 11 80 00 	movl   $0x0,0x80112694
80102131:	00 00 00 
  freerange(vstart, vend);
80102134:	83 c4 08             	add    $0x8,%esp
80102137:	ff 75 0c             	pushl  0xc(%ebp)
8010213a:	ff 75 08             	pushl  0x8(%ebp)
8010213d:	e8 9d ff ff ff       	call   801020df <freerange>
}
80102142:	83 c4 10             	add    $0x10,%esp
80102145:	c9                   	leave  
80102146:	c3                   	ret    

80102147 <kinit2>:
{
80102147:	55                   	push   %ebp
80102148:	89 e5                	mov    %esp,%ebp
8010214a:	83 ec 10             	sub    $0x10,%esp
  freerange(vstart, vend);
8010214d:	ff 75 0c             	pushl  0xc(%ebp)
80102150:	ff 75 08             	pushl  0x8(%ebp)
80102153:	e8 87 ff ff ff       	call   801020df <freerange>
  kmem.use_lock = 1;
80102158:	c7 05 94 26 11 80 01 	movl   $0x1,0x80112694
8010215f:	00 00 00 
  for(int i = 0; i < 16384; i++) {
80102162:	83 c4 10             	add    $0x10,%esp
80102165:	b8 00 00 00 00       	mov    $0x0,%eax
8010216a:	eb 19                	jmp    80102185 <kinit2+0x3e>
  	framearr[i] = -1;
8010216c:	c7 04 85 a0 26 15 80 	movl   $0xffffffff,-0x7fead960(,%eax,4)
80102173:	ff ff ff ff 
  	pidarr[i] = -1;
80102177:	c7 04 85 a0 26 11 80 	movl   $0xffffffff,-0x7feed960(,%eax,4)
8010217e:	ff ff ff ff 
  for(int i = 0; i < 16384; i++) {
80102182:	83 c0 01             	add    $0x1,%eax
80102185:	3d ff 3f 00 00       	cmp    $0x3fff,%eax
8010218a:	7e e0                	jle    8010216c <kinit2+0x25>
	dd =1;
8010218c:	c7 05 b8 a5 10 80 01 	movl   $0x1,0x8010a5b8
80102193:	00 00 00 
}
80102196:	c9                   	leave  
80102197:	c3                   	ret    

80102198 <isSafeToAllocare>:

int isSafeToAllocare(int pid, int frame)
{
80102198:	55                   	push   %ebp
80102199:	89 e5                	mov    %esp,%ebp
8010219b:	57                   	push   %edi
8010219c:	56                   	push   %esi
8010219d:	53                   	push   %ebx
8010219e:	8b 7d 08             	mov    0x8(%ebp),%edi
801021a1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	if(pid == -2)
801021a4:	83 ff fe             	cmp    $0xfffffffe,%edi
801021a7:	74 3c                	je     801021e5 <isSafeToAllocare+0x4d>
		return 1;
	
	int lpid = getPidforFrame(frame-1);
801021a9:	8d 43 ff             	lea    -0x1(%ebx),%eax
801021ac:	50                   	push   %eax
801021ad:	e8 25 fe ff ff       	call   80101fd7 <getPidforFrame>
801021b2:	89 c6                	mov    %eax,%esi
	int rpid = getPidforFrame(frame+1);
801021b4:	83 c3 01             	add    $0x1,%ebx
801021b7:	89 1c 24             	mov    %ebx,(%esp)
801021ba:	e8 18 fe ff ff       	call   80101fd7 <getPidforFrame>
801021bf:	83 c4 04             	add    $0x4,%esp
	if( (pid == lpid || lpid<0) && (rpid<0 || rpid == pid) )
801021c2:	39 f7                	cmp    %esi,%edi
801021c4:	0f 94 c1             	sete   %cl
801021c7:	89 f2                	mov    %esi,%edx
801021c9:	c1 ea 1f             	shr    $0x1f,%edx
801021cc:	08 d1                	or     %dl,%cl
801021ce:	74 1c                	je     801021ec <isSafeToAllocare+0x54>
801021d0:	89 c2                	mov    %eax,%edx
801021d2:	c1 ea 1f             	shr    $0x1f,%edx
801021d5:	39 c7                	cmp    %eax,%edi
801021d7:	0f 94 c0             	sete   %al
801021da:	08 d0                	or     %dl,%al
801021dc:	75 1b                	jne    801021f9 <isSafeToAllocare+0x61>
	       return 1;
	return 0;	
801021de:	b8 00 00 00 00       	mov    $0x0,%eax
801021e3:	eb 0c                	jmp    801021f1 <isSafeToAllocare+0x59>
		return 1;
801021e5:	b8 01 00 00 00       	mov    $0x1,%eax
801021ea:	eb 05                	jmp    801021f1 <isSafeToAllocare+0x59>
	return 0;	
801021ec:	b8 00 00 00 00       	mov    $0x0,%eax

}
801021f1:	8d 65 f4             	lea    -0xc(%ebp),%esp
801021f4:	5b                   	pop    %ebx
801021f5:	5e                   	pop    %esi
801021f6:	5f                   	pop    %edi
801021f7:	5d                   	pop    %ebp
801021f8:	c3                   	ret    
	       return 1;
801021f9:	b8 01 00 00 00       	mov    $0x1,%eax
801021fe:	eb f1                	jmp    801021f1 <isSafeToAllocare+0x59>

80102200 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(int pid)
{
80102200:	55                   	push   %ebp
80102201:	89 e5                	mov    %esp,%ebp
80102203:	57                   	push   %edi
80102204:	56                   	push   %esi
80102205:	53                   	push   %ebx
80102206:	83 ec 1c             	sub    $0x1c,%esp
80102209:	8b 7d 08             	mov    0x8(%ebp),%edi
  struct run *r;
 // cprintf("pid : %d\n",pid);  
  if(kmem.use_lock)
8010220c:	83 3d 94 26 11 80 00 	cmpl   $0x0,0x80112694
80102213:	75 1f                	jne    80102234 <kalloc+0x34>
    acquire(&kmem.lock);

 // int isSafe = 0;
  r = kmem.freelist;
80102215:	8b 35 98 26 11 80    	mov    0x80112698,%esi
  //if(r && r->next)
  //  kmem.freelist = (r->next)->next;
  if(!r) { 
8010221b:	85 f6                	test   %esi,%esi
8010221d:	74 27                	je     80102246 <kalloc+0x46>
  	if(kmem.use_lock)
    	release(&kmem.lock);
  }
  int pa;
  int framenum;
  pa = V2P(r);
8010221f:	8d 9e 00 00 00 80    	lea    -0x80000000(%esi),%ebx
  framenum = (pa >> 12) & 0xffff;
80102225:	c1 fb 0c             	sar    $0xc,%ebx
80102228:	0f b7 db             	movzwl %bx,%ebx
 // cprintf("head:  %x ",framenum);
  struct run *curr = r;
  struct run *prev = 0;
8010222b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
  while(curr && !isSafeToAllocare(pid,framenum))
80102232:	eb 40                	jmp    80102274 <kalloc+0x74>
    acquire(&kmem.lock);
80102234:	83 ec 0c             	sub    $0xc,%esp
80102237:	68 60 26 11 80       	push   $0x80112660
8010223c:	e8 bc 1c 00 00       	call   80103efd <acquire>
80102241:	83 c4 10             	add    $0x10,%esp
80102244:	eb cf                	jmp    80102215 <kalloc+0x15>
  	if(kmem.use_lock)
80102246:	83 3d 94 26 11 80 00 	cmpl   $0x0,0x80112694
8010224d:	74 d0                	je     8010221f <kalloc+0x1f>
    	release(&kmem.lock);
8010224f:	83 ec 0c             	sub    $0xc,%esp
80102252:	68 60 26 11 80       	push   $0x80112660
80102257:	e8 06 1d 00 00       	call   80103f62 <release>
8010225c:	83 c4 10             	add    $0x10,%esp
8010225f:	eb be                	jmp    8010221f <kalloc+0x1f>
  {
  // cprintf("my logic safe %d for frame %x and pid %d",isSafeToAllocare(pid,framenum),framenum,pid);
  // cprintf("it is safe:%d",isSafe);
   prev = curr;
   curr = curr->next;   
80102261:	8b 06                	mov    (%esi),%eax
   pa = V2P(curr);
80102263:	8d 98 00 00 00 80    	lea    -0x80000000(%eax),%ebx
   framenum = (pa >> 12) & 0xffff;
80102269:	c1 fb 0c             	sar    $0xc,%ebx
8010226c:	0f b7 db             	movzwl %bx,%ebx
   prev = curr;
8010226f:	89 75 e4             	mov    %esi,-0x1c(%ebp)
   curr = curr->next;   
80102272:	89 c6                	mov    %eax,%esi
  while(curr && !isSafeToAllocare(pid,framenum))
80102274:	85 f6                	test   %esi,%esi
80102276:	74 11                	je     80102289 <kalloc+0x89>
80102278:	83 ec 08             	sub    $0x8,%esp
8010227b:	53                   	push   %ebx
8010227c:	57                   	push   %edi
8010227d:	e8 16 ff ff ff       	call   80102198 <isSafeToAllocare>
80102282:	83 c4 10             	add    $0x10,%esp
80102285:	85 c0                	test   %eax,%eax
80102287:	74 d8                	je     80102261 <kalloc+0x61>
  }

  if(!prev)
80102289:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
8010228d:	74 35                	je     801022c4 <kalloc+0xc4>
//	   cprintf("allocate first free at head wgich was %x:",kmem.freelist);
	  kmem.freelist = curr->next;
  }
  else
  {
	  prev->next = curr->next;
8010228f:	8b 06                	mov    (%esi),%eax
80102291:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80102294:	89 02                	mov    %eax,(%edx)

  }
   framearr[totalframes]=framenum;
80102296:	a1 9c 26 11 80       	mov    0x8011269c,%eax
8010229b:	89 1c 85 a0 26 15 80 	mov    %ebx,-0x7fead960(,%eax,4)
   pidarr[totalframes]= pid;
801022a2:	89 3c 85 a0 26 11 80 	mov    %edi,-0x7feed960(,%eax,4)
   totalframes ++;
801022a9:	83 c0 01             	add    $0x1,%eax
801022ac:	a3 9c 26 11 80       	mov    %eax,0x8011269c

  if(kmem.use_lock)
801022b1:	83 3d 94 26 11 80 00 	cmpl   $0x0,0x80112694
801022b8:	75 13                	jne    801022cd <kalloc+0xcd>
    release(&kmem.lock);
  return (char*)curr;
}
801022ba:	89 f0                	mov    %esi,%eax
801022bc:	8d 65 f4             	lea    -0xc(%ebp),%esp
801022bf:	5b                   	pop    %ebx
801022c0:	5e                   	pop    %esi
801022c1:	5f                   	pop    %edi
801022c2:	5d                   	pop    %ebp
801022c3:	c3                   	ret    
	  kmem.freelist = curr->next;
801022c4:	8b 06                	mov    (%esi),%eax
801022c6:	a3 98 26 11 80       	mov    %eax,0x80112698
801022cb:	eb c9                	jmp    80102296 <kalloc+0x96>
    release(&kmem.lock);
801022cd:	83 ec 0c             	sub    $0xc,%esp
801022d0:	68 60 26 11 80       	push   $0x80112660
801022d5:	e8 88 1c 00 00       	call   80103f62 <release>
801022da:	83 c4 10             	add    $0x10,%esp
  return (char*)curr;
801022dd:	eb db                	jmp    801022ba <kalloc+0xba>

801022df <swap>:

void swap(int *xp, int *yp)
{
801022df:	55                   	push   %ebp
801022e0:	89 e5                	mov    %esp,%ebp
801022e2:	53                   	push   %ebx
801022e3:	8b 55 08             	mov    0x8(%ebp),%edx
801022e6:	8b 45 0c             	mov    0xc(%ebp),%eax
    int temp = *xp;
801022e9:	8b 0a                	mov    (%edx),%ecx
    *xp = *yp;
801022eb:	8b 18                	mov    (%eax),%ebx
801022ed:	89 1a                	mov    %ebx,(%edx)
    *yp = temp;
801022ef:	89 08                	mov    %ecx,(%eax)
}
801022f1:	5b                   	pop    %ebx
801022f2:	5d                   	pop    %ebp
801022f3:	c3                   	ret    

801022f4 <bubbleSort>:

void bubbleSort(int *frame, int *pid, int n)
{
801022f4:	55                   	push   %ebp
801022f5:	89 e5                	mov    %esp,%ebp
801022f7:	57                   	push   %edi
801022f8:	56                   	push   %esi
801022f9:	53                   	push   %ebx
801022fa:	83 ec 04             	sub    $0x4,%esp
   int i, j;
   for (i = 0; i < n-1; i++)
801022fd:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80102304:	eb 4b                	jmp    80102351 <bubbleSort+0x5d>
       for (j = 0; j < n-i-1; j++)
80102306:	83 c3 01             	add    $0x1,%ebx
80102309:	8b 45 10             	mov    0x10(%ebp),%eax
8010230c:	2b 45 f0             	sub    -0x10(%ebp),%eax
8010230f:	83 e8 01             	sub    $0x1,%eax
80102312:	39 d8                	cmp    %ebx,%eax
80102314:	7e 37                	jle    8010234d <bubbleSort+0x59>
           if (frame[j] < frame[j+1])
80102316:	8d 34 9d 00 00 00 00 	lea    0x0(,%ebx,4),%esi
8010231d:	89 f0                	mov    %esi,%eax
8010231f:	03 45 08             	add    0x8(%ebp),%eax
80102322:	8d 3c 9d 04 00 00 00 	lea    0x4(,%ebx,4),%edi
80102329:	89 fa                	mov    %edi,%edx
8010232b:	03 55 08             	add    0x8(%ebp),%edx
8010232e:	8b 0a                	mov    (%edx),%ecx
80102330:	39 08                	cmp    %ecx,(%eax)
80102332:	7d d2                	jge    80102306 <bubbleSort+0x12>
           {
                   swap(&frame[j], &frame[j+1]);
80102334:	52                   	push   %edx
80102335:	50                   	push   %eax
80102336:	e8 a4 ff ff ff       	call   801022df <swap>
                   swap(&pid[j], &pid[j+1]);
8010233b:	03 7d 0c             	add    0xc(%ebp),%edi
8010233e:	57                   	push   %edi
8010233f:	03 75 0c             	add    0xc(%ebp),%esi
80102342:	56                   	push   %esi
80102343:	e8 97 ff ff ff       	call   801022df <swap>
80102348:	83 c4 10             	add    $0x10,%esp
8010234b:	eb b9                	jmp    80102306 <bubbleSort+0x12>
   for (i = 0; i < n-1; i++)
8010234d:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80102351:	8b 45 10             	mov    0x10(%ebp),%eax
80102354:	83 e8 01             	sub    $0x1,%eax
80102357:	3b 45 f0             	cmp    -0x10(%ebp),%eax
8010235a:	7e 07                	jle    80102363 <bubbleSort+0x6f>
       for (j = 0; j < n-i-1; j++)
8010235c:	bb 00 00 00 00       	mov    $0x0,%ebx
80102361:	eb a6                	jmp    80102309 <bubbleSort+0x15>
           }
}
80102363:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102366:	5b                   	pop    %ebx
80102367:	5e                   	pop    %esi
80102368:	5f                   	pop    %edi
80102369:	5d                   	pop    %ebp
8010236a:	c3                   	ret    

8010236b <dump_physmem>:

int
dump_physmem(int *frames, int *pids, int numframes)
{
8010236b:	55                   	push   %ebp
8010236c:	89 e5                	mov    %esp,%ebp
8010236e:	57                   	push   %edi
8010236f:	56                   	push   %esi
80102370:	53                   	push   %ebx
80102371:	83 ec 0c             	sub    $0xc,%esp
80102374:	8b 5d 08             	mov    0x8(%ebp),%ebx
80102377:	8b 75 0c             	mov    0xc(%ebp),%esi
8010237a:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(kmem.use_lock)
8010237d:	83 3d 94 26 11 80 00 	cmpl   $0x0,0x80112694
80102384:	75 24                	jne    801023aa <dump_physmem+0x3f>
    release(&kmem.lock);
  
	return -1;
  	
  }*/
  if(!frames || !pids) {
80102386:	85 db                	test   %ebx,%ebx
80102388:	0f 94 c2             	sete   %dl
8010238b:	85 f6                	test   %esi,%esi
8010238d:	0f 94 c0             	sete   %al
80102390:	08 c2                	or     %al,%dl
80102392:	74 3f                	je     801023d3 <dump_physmem+0x68>
  	if(kmem.use_lock)
80102394:	83 3d 94 26 11 80 00 	cmpl   $0x0,0x80112694
8010239b:	75 1f                	jne    801023bc <dump_physmem+0x51>
    		release(&kmem.lock);
  
  	return -1;
8010239d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  //numframe = totalframes;
  if(kmem.use_lock)
    release(&kmem.lock);
  
	return 0;
}
801023a2:	8d 65 f4             	lea    -0xc(%ebp),%esp
801023a5:	5b                   	pop    %ebx
801023a6:	5e                   	pop    %esi
801023a7:	5f                   	pop    %edi
801023a8:	5d                   	pop    %ebp
801023a9:	c3                   	ret    
    acquire(&kmem.lock);
801023aa:	83 ec 0c             	sub    $0xc,%esp
801023ad:	68 60 26 11 80       	push   $0x80112660
801023b2:	e8 46 1b 00 00       	call   80103efd <acquire>
801023b7:	83 c4 10             	add    $0x10,%esp
801023ba:	eb ca                	jmp    80102386 <dump_physmem+0x1b>
    		release(&kmem.lock);
801023bc:	83 ec 0c             	sub    $0xc,%esp
801023bf:	68 60 26 11 80       	push   $0x80112660
801023c4:	e8 99 1b 00 00       	call   80103f62 <release>
801023c9:	83 c4 10             	add    $0x10,%esp
  	return -1;
801023cc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801023d1:	eb cf                	jmp    801023a2 <dump_physmem+0x37>
 bubbleSort(framearr, pidarr, 1000);
801023d3:	83 ec 04             	sub    $0x4,%esp
801023d6:	68 e8 03 00 00       	push   $0x3e8
801023db:	68 a0 26 11 80       	push   $0x801126a0
801023e0:	68 a0 26 15 80       	push   $0x801526a0
801023e5:	e8 0a ff ff ff       	call   801022f4 <bubbleSort>
  for(int i = 0; i < 65536; i++) {
801023ea:	83 c4 10             	add    $0x10,%esp
801023ed:	b8 00 00 00 00       	mov    $0x0,%eax
  int x =0;
801023f2:	ba 00 00 00 00       	mov    $0x0,%edx
801023f7:	89 5d 08             	mov    %ebx,0x8(%ebp)
801023fa:	89 75 0c             	mov    %esi,0xc(%ebp)
  for(int i = 0; i < 65536; i++) {
801023fd:	eb 03                	jmp    80102402 <dump_physmem+0x97>
801023ff:	83 c0 01             	add    $0x1,%eax
80102402:	3d ff ff 00 00       	cmp    $0xffff,%eax
80102407:	7f 32                	jg     8010243b <dump_physmem+0xd0>
  	if(pidarr[i]!=-1){
80102409:	83 3c 85 a0 26 11 80 	cmpl   $0xffffffff,-0x7feed960(,%eax,4)
80102410:	ff 
80102411:	74 ec                	je     801023ff <dump_physmem+0x94>
  	 frames[x] = framearr[i];
80102413:	8d 0c 95 00 00 00 00 	lea    0x0(,%edx,4),%ecx
8010241a:	8b 34 85 a0 26 15 80 	mov    -0x7fead960(,%eax,4),%esi
80102421:	8b 5d 08             	mov    0x8(%ebp),%ebx
80102424:	89 34 0b             	mov    %esi,(%ebx,%ecx,1)
  	 pids[x] = pidarr[i];
80102427:	8b 34 85 a0 26 11 80 	mov    -0x7feed960(,%eax,4),%esi
8010242e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80102431:	89 34 0b             	mov    %esi,(%ebx,%ecx,1)
	 x++;
80102434:	83 c2 01             	add    $0x1,%edx
	 if(x >= numframes) {
80102437:	39 fa                	cmp    %edi,%edx
80102439:	7c c4                	jl     801023ff <dump_physmem+0x94>
  if(kmem.use_lock)
8010243b:	a1 94 26 11 80       	mov    0x80112694,%eax
80102440:	85 c0                	test   %eax,%eax
80102442:	0f 84 5a ff ff ff    	je     801023a2 <dump_physmem+0x37>
    release(&kmem.lock);
80102448:	83 ec 0c             	sub    $0xc,%esp
8010244b:	68 60 26 11 80       	push   $0x80112660
80102450:	e8 0d 1b 00 00       	call   80103f62 <release>
80102455:	83 c4 10             	add    $0x10,%esp
	return 0;
80102458:	b8 00 00 00 00       	mov    $0x0,%eax
8010245d:	e9 40 ff ff ff       	jmp    801023a2 <dump_physmem+0x37>

80102462 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102462:	55                   	push   %ebp
80102463:	89 e5                	mov    %esp,%ebp
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102465:	ba 64 00 00 00       	mov    $0x64,%edx
8010246a:	ec                   	in     (%dx),%al
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
  if((st & KBS_DIB) == 0)
8010246b:	a8 01                	test   $0x1,%al
8010246d:	0f 84 b5 00 00 00    	je     80102528 <kbdgetc+0xc6>
80102473:	ba 60 00 00 00       	mov    $0x60,%edx
80102478:	ec                   	in     (%dx),%al
    return -1;
  data = inb(KBDATAP);
80102479:	0f b6 d0             	movzbl %al,%edx

  if(data == 0xE0){
8010247c:	81 fa e0 00 00 00    	cmp    $0xe0,%edx
80102482:	74 5c                	je     801024e0 <kbdgetc+0x7e>
    shift |= E0ESC;
    return 0;
  } else if(data & 0x80){
80102484:	84 c0                	test   %al,%al
80102486:	78 66                	js     801024ee <kbdgetc+0x8c>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
    shift &= ~(shiftcode[data] | E0ESC);
    return 0;
  } else if(shift & E0ESC){
80102488:	8b 0d bc a5 10 80    	mov    0x8010a5bc,%ecx
8010248e:	f6 c1 40             	test   $0x40,%cl
80102491:	74 0f                	je     801024a2 <kbdgetc+0x40>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102493:	83 c8 80             	or     $0xffffff80,%eax
80102496:	0f b6 d0             	movzbl %al,%edx
    shift &= ~E0ESC;
80102499:	83 e1 bf             	and    $0xffffffbf,%ecx
8010249c:	89 0d bc a5 10 80    	mov    %ecx,0x8010a5bc
  }

  shift |= shiftcode[data];
801024a2:	0f b6 8a e0 6b 10 80 	movzbl -0x7fef9420(%edx),%ecx
801024a9:	0b 0d bc a5 10 80    	or     0x8010a5bc,%ecx
  shift ^= togglecode[data];
801024af:	0f b6 82 e0 6a 10 80 	movzbl -0x7fef9520(%edx),%eax
801024b6:	31 c1                	xor    %eax,%ecx
801024b8:	89 0d bc a5 10 80    	mov    %ecx,0x8010a5bc
  c = charcode[shift & (CTL | SHIFT)][data];
801024be:	89 c8                	mov    %ecx,%eax
801024c0:	83 e0 03             	and    $0x3,%eax
801024c3:	8b 04 85 c0 6a 10 80 	mov    -0x7fef9540(,%eax,4),%eax
801024ca:	0f b6 04 10          	movzbl (%eax,%edx,1),%eax
  if(shift & CAPSLOCK){
801024ce:	f6 c1 08             	test   $0x8,%cl
801024d1:	74 19                	je     801024ec <kbdgetc+0x8a>
    if('a' <= c && c <= 'z')
801024d3:	8d 50 9f             	lea    -0x61(%eax),%edx
801024d6:	83 fa 19             	cmp    $0x19,%edx
801024d9:	77 40                	ja     8010251b <kbdgetc+0xb9>
      c += 'A' - 'a';
801024db:	83 e8 20             	sub    $0x20,%eax
801024de:	eb 0c                	jmp    801024ec <kbdgetc+0x8a>
    shift |= E0ESC;
801024e0:	83 0d bc a5 10 80 40 	orl    $0x40,0x8010a5bc
    return 0;
801024e7:	b8 00 00 00 00       	mov    $0x0,%eax
    else if('A' <= c && c <= 'Z')
      c += 'a' - 'A';
  }
  return c;
}
801024ec:	5d                   	pop    %ebp
801024ed:	c3                   	ret    
    data = (shift & E0ESC ? data : data & 0x7F);
801024ee:	8b 0d bc a5 10 80    	mov    0x8010a5bc,%ecx
801024f4:	f6 c1 40             	test   $0x40,%cl
801024f7:	75 05                	jne    801024fe <kbdgetc+0x9c>
801024f9:	89 c2                	mov    %eax,%edx
801024fb:	83 e2 7f             	and    $0x7f,%edx
    shift &= ~(shiftcode[data] | E0ESC);
801024fe:	0f b6 82 e0 6b 10 80 	movzbl -0x7fef9420(%edx),%eax
80102505:	83 c8 40             	or     $0x40,%eax
80102508:	0f b6 c0             	movzbl %al,%eax
8010250b:	f7 d0                	not    %eax
8010250d:	21 c8                	and    %ecx,%eax
8010250f:	a3 bc a5 10 80       	mov    %eax,0x8010a5bc
    return 0;
80102514:	b8 00 00 00 00       	mov    $0x0,%eax
80102519:	eb d1                	jmp    801024ec <kbdgetc+0x8a>
    else if('A' <= c && c <= 'Z')
8010251b:	8d 50 bf             	lea    -0x41(%eax),%edx
8010251e:	83 fa 19             	cmp    $0x19,%edx
80102521:	77 c9                	ja     801024ec <kbdgetc+0x8a>
      c += 'a' - 'A';
80102523:	83 c0 20             	add    $0x20,%eax
  return c;
80102526:	eb c4                	jmp    801024ec <kbdgetc+0x8a>
    return -1;
80102528:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010252d:	eb bd                	jmp    801024ec <kbdgetc+0x8a>

8010252f <kbdintr>:

void
kbdintr(void)
{
8010252f:	55                   	push   %ebp
80102530:	89 e5                	mov    %esp,%ebp
80102532:	83 ec 14             	sub    $0x14,%esp
  consoleintr(kbdgetc);
80102535:	68 62 24 10 80       	push   $0x80102462
8010253a:	e8 ff e1 ff ff       	call   8010073e <consoleintr>
}
8010253f:	83 c4 10             	add    $0x10,%esp
80102542:	c9                   	leave  
80102543:	c3                   	ret    

80102544 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102544:	55                   	push   %ebp
80102545:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102547:	8b 0d a0 26 19 80    	mov    0x801926a0,%ecx
8010254d:	8d 04 81             	lea    (%ecx,%eax,4),%eax
80102550:	89 10                	mov    %edx,(%eax)
  lapic[ID];  // wait for write to finish, by reading
80102552:	a1 a0 26 19 80       	mov    0x801926a0,%eax
80102557:	8b 40 20             	mov    0x20(%eax),%eax
}
8010255a:	5d                   	pop    %ebp
8010255b:	c3                   	ret    

8010255c <cmos_read>:
#define MONTH   0x08
#define YEAR    0x09

static uint
cmos_read(uint reg)
{
8010255c:	55                   	push   %ebp
8010255d:	89 e5                	mov    %esp,%ebp
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010255f:	ba 70 00 00 00       	mov    $0x70,%edx
80102564:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102565:	ba 71 00 00 00       	mov    $0x71,%edx
8010256a:	ec                   	in     (%dx),%al
  outb(CMOS_PORT,  reg);
  microdelay(200);

  return inb(CMOS_RETURN);
8010256b:	0f b6 c0             	movzbl %al,%eax
}
8010256e:	5d                   	pop    %ebp
8010256f:	c3                   	ret    

80102570 <fill_rtcdate>:

static void
fill_rtcdate(struct rtcdate *r)
{
80102570:	55                   	push   %ebp
80102571:	89 e5                	mov    %esp,%ebp
80102573:	53                   	push   %ebx
80102574:	89 c3                	mov    %eax,%ebx
  r->second = cmos_read(SECS);
80102576:	b8 00 00 00 00       	mov    $0x0,%eax
8010257b:	e8 dc ff ff ff       	call   8010255c <cmos_read>
80102580:	89 03                	mov    %eax,(%ebx)
  r->minute = cmos_read(MINS);
80102582:	b8 02 00 00 00       	mov    $0x2,%eax
80102587:	e8 d0 ff ff ff       	call   8010255c <cmos_read>
8010258c:	89 43 04             	mov    %eax,0x4(%ebx)
  r->hour   = cmos_read(HOURS);
8010258f:	b8 04 00 00 00       	mov    $0x4,%eax
80102594:	e8 c3 ff ff ff       	call   8010255c <cmos_read>
80102599:	89 43 08             	mov    %eax,0x8(%ebx)
  r->day    = cmos_read(DAY);
8010259c:	b8 07 00 00 00       	mov    $0x7,%eax
801025a1:	e8 b6 ff ff ff       	call   8010255c <cmos_read>
801025a6:	89 43 0c             	mov    %eax,0xc(%ebx)
  r->month  = cmos_read(MONTH);
801025a9:	b8 08 00 00 00       	mov    $0x8,%eax
801025ae:	e8 a9 ff ff ff       	call   8010255c <cmos_read>
801025b3:	89 43 10             	mov    %eax,0x10(%ebx)
  r->year   = cmos_read(YEAR);
801025b6:	b8 09 00 00 00       	mov    $0x9,%eax
801025bb:	e8 9c ff ff ff       	call   8010255c <cmos_read>
801025c0:	89 43 14             	mov    %eax,0x14(%ebx)
}
801025c3:	5b                   	pop    %ebx
801025c4:	5d                   	pop    %ebp
801025c5:	c3                   	ret    

801025c6 <lapicinit>:
  if(!lapic)
801025c6:	83 3d a0 26 19 80 00 	cmpl   $0x0,0x801926a0
801025cd:	0f 84 fb 00 00 00    	je     801026ce <lapicinit+0x108>
{
801025d3:	55                   	push   %ebp
801025d4:	89 e5                	mov    %esp,%ebp
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
801025d6:	ba 3f 01 00 00       	mov    $0x13f,%edx
801025db:	b8 3c 00 00 00       	mov    $0x3c,%eax
801025e0:	e8 5f ff ff ff       	call   80102544 <lapicw>
  lapicw(TDCR, X1);
801025e5:	ba 0b 00 00 00       	mov    $0xb,%edx
801025ea:	b8 f8 00 00 00       	mov    $0xf8,%eax
801025ef:	e8 50 ff ff ff       	call   80102544 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
801025f4:	ba 20 00 02 00       	mov    $0x20020,%edx
801025f9:	b8 c8 00 00 00       	mov    $0xc8,%eax
801025fe:	e8 41 ff ff ff       	call   80102544 <lapicw>
  lapicw(TICR, 10000000);
80102603:	ba 80 96 98 00       	mov    $0x989680,%edx
80102608:	b8 e0 00 00 00       	mov    $0xe0,%eax
8010260d:	e8 32 ff ff ff       	call   80102544 <lapicw>
  lapicw(LINT0, MASKED);
80102612:	ba 00 00 01 00       	mov    $0x10000,%edx
80102617:	b8 d4 00 00 00       	mov    $0xd4,%eax
8010261c:	e8 23 ff ff ff       	call   80102544 <lapicw>
  lapicw(LINT1, MASKED);
80102621:	ba 00 00 01 00       	mov    $0x10000,%edx
80102626:	b8 d8 00 00 00       	mov    $0xd8,%eax
8010262b:	e8 14 ff ff ff       	call   80102544 <lapicw>
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80102630:	a1 a0 26 19 80       	mov    0x801926a0,%eax
80102635:	8b 40 30             	mov    0x30(%eax),%eax
80102638:	c1 e8 10             	shr    $0x10,%eax
8010263b:	3c 03                	cmp    $0x3,%al
8010263d:	77 7b                	ja     801026ba <lapicinit+0xf4>
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
8010263f:	ba 33 00 00 00       	mov    $0x33,%edx
80102644:	b8 dc 00 00 00       	mov    $0xdc,%eax
80102649:	e8 f6 fe ff ff       	call   80102544 <lapicw>
  lapicw(ESR, 0);
8010264e:	ba 00 00 00 00       	mov    $0x0,%edx
80102653:	b8 a0 00 00 00       	mov    $0xa0,%eax
80102658:	e8 e7 fe ff ff       	call   80102544 <lapicw>
  lapicw(ESR, 0);
8010265d:	ba 00 00 00 00       	mov    $0x0,%edx
80102662:	b8 a0 00 00 00       	mov    $0xa0,%eax
80102667:	e8 d8 fe ff ff       	call   80102544 <lapicw>
  lapicw(EOI, 0);
8010266c:	ba 00 00 00 00       	mov    $0x0,%edx
80102671:	b8 2c 00 00 00       	mov    $0x2c,%eax
80102676:	e8 c9 fe ff ff       	call   80102544 <lapicw>
  lapicw(ICRHI, 0);
8010267b:	ba 00 00 00 00       	mov    $0x0,%edx
80102680:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102685:	e8 ba fe ff ff       	call   80102544 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
8010268a:	ba 00 85 08 00       	mov    $0x88500,%edx
8010268f:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102694:	e8 ab fe ff ff       	call   80102544 <lapicw>
  while(lapic[ICRLO] & DELIVS)
80102699:	a1 a0 26 19 80       	mov    0x801926a0,%eax
8010269e:	8b 80 00 03 00 00    	mov    0x300(%eax),%eax
801026a4:	f6 c4 10             	test   $0x10,%ah
801026a7:	75 f0                	jne    80102699 <lapicinit+0xd3>
  lapicw(TPR, 0);
801026a9:	ba 00 00 00 00       	mov    $0x0,%edx
801026ae:	b8 20 00 00 00       	mov    $0x20,%eax
801026b3:	e8 8c fe ff ff       	call   80102544 <lapicw>
}
801026b8:	5d                   	pop    %ebp
801026b9:	c3                   	ret    
    lapicw(PCINT, MASKED);
801026ba:	ba 00 00 01 00       	mov    $0x10000,%edx
801026bf:	b8 d0 00 00 00       	mov    $0xd0,%eax
801026c4:	e8 7b fe ff ff       	call   80102544 <lapicw>
801026c9:	e9 71 ff ff ff       	jmp    8010263f <lapicinit+0x79>
801026ce:	f3 c3                	repz ret 

801026d0 <lapicid>:
{
801026d0:	55                   	push   %ebp
801026d1:	89 e5                	mov    %esp,%ebp
  if (!lapic)
801026d3:	a1 a0 26 19 80       	mov    0x801926a0,%eax
801026d8:	85 c0                	test   %eax,%eax
801026da:	74 08                	je     801026e4 <lapicid+0x14>
  return lapic[ID] >> 24;
801026dc:	8b 40 20             	mov    0x20(%eax),%eax
801026df:	c1 e8 18             	shr    $0x18,%eax
}
801026e2:	5d                   	pop    %ebp
801026e3:	c3                   	ret    
    return 0;
801026e4:	b8 00 00 00 00       	mov    $0x0,%eax
801026e9:	eb f7                	jmp    801026e2 <lapicid+0x12>

801026eb <lapiceoi>:
  if(lapic)
801026eb:	83 3d a0 26 19 80 00 	cmpl   $0x0,0x801926a0
801026f2:	74 14                	je     80102708 <lapiceoi+0x1d>
{
801026f4:	55                   	push   %ebp
801026f5:	89 e5                	mov    %esp,%ebp
    lapicw(EOI, 0);
801026f7:	ba 00 00 00 00       	mov    $0x0,%edx
801026fc:	b8 2c 00 00 00       	mov    $0x2c,%eax
80102701:	e8 3e fe ff ff       	call   80102544 <lapicw>
}
80102706:	5d                   	pop    %ebp
80102707:	c3                   	ret    
80102708:	f3 c3                	repz ret 

8010270a <microdelay>:
{
8010270a:	55                   	push   %ebp
8010270b:	89 e5                	mov    %esp,%ebp
}
8010270d:	5d                   	pop    %ebp
8010270e:	c3                   	ret    

8010270f <lapicstartap>:
{
8010270f:	55                   	push   %ebp
80102710:	89 e5                	mov    %esp,%ebp
80102712:	57                   	push   %edi
80102713:	56                   	push   %esi
80102714:	53                   	push   %ebx
80102715:	8b 75 08             	mov    0x8(%ebp),%esi
80102718:	8b 7d 0c             	mov    0xc(%ebp),%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010271b:	b8 0f 00 00 00       	mov    $0xf,%eax
80102720:	ba 70 00 00 00       	mov    $0x70,%edx
80102725:	ee                   	out    %al,(%dx)
80102726:	b8 0a 00 00 00       	mov    $0xa,%eax
8010272b:	ba 71 00 00 00       	mov    $0x71,%edx
80102730:	ee                   	out    %al,(%dx)
  wrv[0] = 0;
80102731:	66 c7 05 67 04 00 80 	movw   $0x0,0x80000467
80102738:	00 00 
  wrv[1] = addr >> 4;
8010273a:	89 f8                	mov    %edi,%eax
8010273c:	c1 e8 04             	shr    $0x4,%eax
8010273f:	66 a3 69 04 00 80    	mov    %ax,0x80000469
  lapicw(ICRHI, apicid<<24);
80102745:	c1 e6 18             	shl    $0x18,%esi
80102748:	89 f2                	mov    %esi,%edx
8010274a:	b8 c4 00 00 00       	mov    $0xc4,%eax
8010274f:	e8 f0 fd ff ff       	call   80102544 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80102754:	ba 00 c5 00 00       	mov    $0xc500,%edx
80102759:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010275e:	e8 e1 fd ff ff       	call   80102544 <lapicw>
  lapicw(ICRLO, INIT | LEVEL);
80102763:	ba 00 85 00 00       	mov    $0x8500,%edx
80102768:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010276d:	e8 d2 fd ff ff       	call   80102544 <lapicw>
  for(i = 0; i < 2; i++){
80102772:	bb 00 00 00 00       	mov    $0x0,%ebx
80102777:	eb 21                	jmp    8010279a <lapicstartap+0x8b>
    lapicw(ICRHI, apicid<<24);
80102779:	89 f2                	mov    %esi,%edx
8010277b:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102780:	e8 bf fd ff ff       	call   80102544 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80102785:	89 fa                	mov    %edi,%edx
80102787:	c1 ea 0c             	shr    $0xc,%edx
8010278a:	80 ce 06             	or     $0x6,%dh
8010278d:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102792:	e8 ad fd ff ff       	call   80102544 <lapicw>
  for(i = 0; i < 2; i++){
80102797:	83 c3 01             	add    $0x1,%ebx
8010279a:	83 fb 01             	cmp    $0x1,%ebx
8010279d:	7e da                	jle    80102779 <lapicstartap+0x6a>
}
8010279f:	5b                   	pop    %ebx
801027a0:	5e                   	pop    %esi
801027a1:	5f                   	pop    %edi
801027a2:	5d                   	pop    %ebp
801027a3:	c3                   	ret    

801027a4 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void
cmostime(struct rtcdate *r)
{
801027a4:	55                   	push   %ebp
801027a5:	89 e5                	mov    %esp,%ebp
801027a7:	57                   	push   %edi
801027a8:	56                   	push   %esi
801027a9:	53                   	push   %ebx
801027aa:	83 ec 3c             	sub    $0x3c,%esp
801027ad:	8b 75 08             	mov    0x8(%ebp),%esi
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
801027b0:	b8 0b 00 00 00       	mov    $0xb,%eax
801027b5:	e8 a2 fd ff ff       	call   8010255c <cmos_read>

  bcd = (sb & (1 << 2)) == 0;
801027ba:	83 e0 04             	and    $0x4,%eax
801027bd:	89 c7                	mov    %eax,%edi

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
801027bf:	8d 45 d0             	lea    -0x30(%ebp),%eax
801027c2:	e8 a9 fd ff ff       	call   80102570 <fill_rtcdate>
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
801027c7:	b8 0a 00 00 00       	mov    $0xa,%eax
801027cc:	e8 8b fd ff ff       	call   8010255c <cmos_read>
801027d1:	a8 80                	test   $0x80,%al
801027d3:	75 ea                	jne    801027bf <cmostime+0x1b>
        continue;
    fill_rtcdate(&t2);
801027d5:	8d 5d b8             	lea    -0x48(%ebp),%ebx
801027d8:	89 d8                	mov    %ebx,%eax
801027da:	e8 91 fd ff ff       	call   80102570 <fill_rtcdate>
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
801027df:	83 ec 04             	sub    $0x4,%esp
801027e2:	6a 18                	push   $0x18
801027e4:	53                   	push   %ebx
801027e5:	8d 45 d0             	lea    -0x30(%ebp),%eax
801027e8:	50                   	push   %eax
801027e9:	e8 01 18 00 00       	call   80103fef <memcmp>
801027ee:	83 c4 10             	add    $0x10,%esp
801027f1:	85 c0                	test   %eax,%eax
801027f3:	75 ca                	jne    801027bf <cmostime+0x1b>
      break;
  }

  // convert
  if(bcd) {
801027f5:	85 ff                	test   %edi,%edi
801027f7:	0f 85 84 00 00 00    	jne    80102881 <cmostime+0xdd>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
801027fd:	8b 55 d0             	mov    -0x30(%ebp),%edx
80102800:	89 d0                	mov    %edx,%eax
80102802:	c1 e8 04             	shr    $0x4,%eax
80102805:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102808:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
8010280b:	83 e2 0f             	and    $0xf,%edx
8010280e:	01 d0                	add    %edx,%eax
80102810:	89 45 d0             	mov    %eax,-0x30(%ebp)
    CONV(minute);
80102813:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80102816:	89 d0                	mov    %edx,%eax
80102818:	c1 e8 04             	shr    $0x4,%eax
8010281b:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010281e:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102821:	83 e2 0f             	and    $0xf,%edx
80102824:	01 d0                	add    %edx,%eax
80102826:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    CONV(hour  );
80102829:	8b 55 d8             	mov    -0x28(%ebp),%edx
8010282c:	89 d0                	mov    %edx,%eax
8010282e:	c1 e8 04             	shr    $0x4,%eax
80102831:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102834:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102837:	83 e2 0f             	and    $0xf,%edx
8010283a:	01 d0                	add    %edx,%eax
8010283c:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(day   );
8010283f:	8b 55 dc             	mov    -0x24(%ebp),%edx
80102842:	89 d0                	mov    %edx,%eax
80102844:	c1 e8 04             	shr    $0x4,%eax
80102847:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010284a:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
8010284d:	83 e2 0f             	and    $0xf,%edx
80102850:	01 d0                	add    %edx,%eax
80102852:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(month );
80102855:	8b 55 e0             	mov    -0x20(%ebp),%edx
80102858:	89 d0                	mov    %edx,%eax
8010285a:	c1 e8 04             	shr    $0x4,%eax
8010285d:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102860:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102863:	83 e2 0f             	and    $0xf,%edx
80102866:	01 d0                	add    %edx,%eax
80102868:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(year  );
8010286b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010286e:	89 d0                	mov    %edx,%eax
80102870:	c1 e8 04             	shr    $0x4,%eax
80102873:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102876:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102879:	83 e2 0f             	and    $0xf,%edx
8010287c:	01 d0                	add    %edx,%eax
8010287e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
#undef     CONV
  }

  *r = t1;
80102881:	8b 45 d0             	mov    -0x30(%ebp),%eax
80102884:	89 06                	mov    %eax,(%esi)
80102886:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80102889:	89 46 04             	mov    %eax,0x4(%esi)
8010288c:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010288f:	89 46 08             	mov    %eax,0x8(%esi)
80102892:	8b 45 dc             	mov    -0x24(%ebp),%eax
80102895:	89 46 0c             	mov    %eax,0xc(%esi)
80102898:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010289b:	89 46 10             	mov    %eax,0x10(%esi)
8010289e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801028a1:	89 46 14             	mov    %eax,0x14(%esi)
  r->year += 2000;
801028a4:	81 46 14 d0 07 00 00 	addl   $0x7d0,0x14(%esi)
}
801028ab:	8d 65 f4             	lea    -0xc(%ebp),%esp
801028ae:	5b                   	pop    %ebx
801028af:	5e                   	pop    %esi
801028b0:	5f                   	pop    %edi
801028b1:	5d                   	pop    %ebp
801028b2:	c3                   	ret    

801028b3 <read_head>:
}

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
801028b3:	55                   	push   %ebp
801028b4:	89 e5                	mov    %esp,%ebp
801028b6:	53                   	push   %ebx
801028b7:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
801028ba:	ff 35 f4 26 19 80    	pushl  0x801926f4
801028c0:	ff 35 04 27 19 80    	pushl  0x80192704
801028c6:	e8 a1 d8 ff ff       	call   8010016c <bread>
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
801028cb:	8b 58 5c             	mov    0x5c(%eax),%ebx
801028ce:	89 1d 08 27 19 80    	mov    %ebx,0x80192708
  for (i = 0; i < log.lh.n; i++) {
801028d4:	83 c4 10             	add    $0x10,%esp
801028d7:	ba 00 00 00 00       	mov    $0x0,%edx
801028dc:	eb 0e                	jmp    801028ec <read_head+0x39>
    log.lh.block[i] = lh->block[i];
801028de:	8b 4c 90 60          	mov    0x60(%eax,%edx,4),%ecx
801028e2:	89 0c 95 0c 27 19 80 	mov    %ecx,-0x7fe6d8f4(,%edx,4)
  for (i = 0; i < log.lh.n; i++) {
801028e9:	83 c2 01             	add    $0x1,%edx
801028ec:	39 d3                	cmp    %edx,%ebx
801028ee:	7f ee                	jg     801028de <read_head+0x2b>
  }
  brelse(buf);
801028f0:	83 ec 0c             	sub    $0xc,%esp
801028f3:	50                   	push   %eax
801028f4:	e8 dc d8 ff ff       	call   801001d5 <brelse>
}
801028f9:	83 c4 10             	add    $0x10,%esp
801028fc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801028ff:	c9                   	leave  
80102900:	c3                   	ret    

80102901 <install_trans>:
{
80102901:	55                   	push   %ebp
80102902:	89 e5                	mov    %esp,%ebp
80102904:	57                   	push   %edi
80102905:	56                   	push   %esi
80102906:	53                   	push   %ebx
80102907:	83 ec 0c             	sub    $0xc,%esp
  for (tail = 0; tail < log.lh.n; tail++) {
8010290a:	bb 00 00 00 00       	mov    $0x0,%ebx
8010290f:	eb 66                	jmp    80102977 <install_trans+0x76>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
80102911:	89 d8                	mov    %ebx,%eax
80102913:	03 05 f4 26 19 80    	add    0x801926f4,%eax
80102919:	83 c0 01             	add    $0x1,%eax
8010291c:	83 ec 08             	sub    $0x8,%esp
8010291f:	50                   	push   %eax
80102920:	ff 35 04 27 19 80    	pushl  0x80192704
80102926:	e8 41 d8 ff ff       	call   8010016c <bread>
8010292b:	89 c7                	mov    %eax,%edi
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
8010292d:	83 c4 08             	add    $0x8,%esp
80102930:	ff 34 9d 0c 27 19 80 	pushl  -0x7fe6d8f4(,%ebx,4)
80102937:	ff 35 04 27 19 80    	pushl  0x80192704
8010293d:	e8 2a d8 ff ff       	call   8010016c <bread>
80102942:	89 c6                	mov    %eax,%esi
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80102944:	8d 57 5c             	lea    0x5c(%edi),%edx
80102947:	8d 40 5c             	lea    0x5c(%eax),%eax
8010294a:	83 c4 0c             	add    $0xc,%esp
8010294d:	68 00 02 00 00       	push   $0x200
80102952:	52                   	push   %edx
80102953:	50                   	push   %eax
80102954:	e8 cb 16 00 00       	call   80104024 <memmove>
    bwrite(dbuf);  // write dst to disk
80102959:	89 34 24             	mov    %esi,(%esp)
8010295c:	e8 39 d8 ff ff       	call   8010019a <bwrite>
    brelse(lbuf);
80102961:	89 3c 24             	mov    %edi,(%esp)
80102964:	e8 6c d8 ff ff       	call   801001d5 <brelse>
    brelse(dbuf);
80102969:	89 34 24             	mov    %esi,(%esp)
8010296c:	e8 64 d8 ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
80102971:	83 c3 01             	add    $0x1,%ebx
80102974:	83 c4 10             	add    $0x10,%esp
80102977:	39 1d 08 27 19 80    	cmp    %ebx,0x80192708
8010297d:	7f 92                	jg     80102911 <install_trans+0x10>
}
8010297f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102982:	5b                   	pop    %ebx
80102983:	5e                   	pop    %esi
80102984:	5f                   	pop    %edi
80102985:	5d                   	pop    %ebp
80102986:	c3                   	ret    

80102987 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80102987:	55                   	push   %ebp
80102988:	89 e5                	mov    %esp,%ebp
8010298a:	53                   	push   %ebx
8010298b:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
8010298e:	ff 35 f4 26 19 80    	pushl  0x801926f4
80102994:	ff 35 04 27 19 80    	pushl  0x80192704
8010299a:	e8 cd d7 ff ff       	call   8010016c <bread>
8010299f:	89 c3                	mov    %eax,%ebx
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
801029a1:	8b 0d 08 27 19 80    	mov    0x80192708,%ecx
801029a7:	89 48 5c             	mov    %ecx,0x5c(%eax)
  for (i = 0; i < log.lh.n; i++) {
801029aa:	83 c4 10             	add    $0x10,%esp
801029ad:	b8 00 00 00 00       	mov    $0x0,%eax
801029b2:	eb 0e                	jmp    801029c2 <write_head+0x3b>
    hb->block[i] = log.lh.block[i];
801029b4:	8b 14 85 0c 27 19 80 	mov    -0x7fe6d8f4(,%eax,4),%edx
801029bb:	89 54 83 60          	mov    %edx,0x60(%ebx,%eax,4)
  for (i = 0; i < log.lh.n; i++) {
801029bf:	83 c0 01             	add    $0x1,%eax
801029c2:	39 c1                	cmp    %eax,%ecx
801029c4:	7f ee                	jg     801029b4 <write_head+0x2d>
  }
  bwrite(buf);
801029c6:	83 ec 0c             	sub    $0xc,%esp
801029c9:	53                   	push   %ebx
801029ca:	e8 cb d7 ff ff       	call   8010019a <bwrite>
  brelse(buf);
801029cf:	89 1c 24             	mov    %ebx,(%esp)
801029d2:	e8 fe d7 ff ff       	call   801001d5 <brelse>
}
801029d7:	83 c4 10             	add    $0x10,%esp
801029da:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801029dd:	c9                   	leave  
801029de:	c3                   	ret    

801029df <recover_from_log>:

static void
recover_from_log(void)
{
801029df:	55                   	push   %ebp
801029e0:	89 e5                	mov    %esp,%ebp
801029e2:	83 ec 08             	sub    $0x8,%esp
  read_head();
801029e5:	e8 c9 fe ff ff       	call   801028b3 <read_head>
  install_trans(); // if committed, copy from log to disk
801029ea:	e8 12 ff ff ff       	call   80102901 <install_trans>
  log.lh.n = 0;
801029ef:	c7 05 08 27 19 80 00 	movl   $0x0,0x80192708
801029f6:	00 00 00 
  write_head(); // clear the log
801029f9:	e8 89 ff ff ff       	call   80102987 <write_head>
}
801029fe:	c9                   	leave  
801029ff:	c3                   	ret    

80102a00 <write_log>:
}

// Copy modified blocks from cache to log.
static void
write_log(void)
{
80102a00:	55                   	push   %ebp
80102a01:	89 e5                	mov    %esp,%ebp
80102a03:	57                   	push   %edi
80102a04:	56                   	push   %esi
80102a05:	53                   	push   %ebx
80102a06:	83 ec 0c             	sub    $0xc,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80102a09:	bb 00 00 00 00       	mov    $0x0,%ebx
80102a0e:	eb 66                	jmp    80102a76 <write_log+0x76>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
80102a10:	89 d8                	mov    %ebx,%eax
80102a12:	03 05 f4 26 19 80    	add    0x801926f4,%eax
80102a18:	83 c0 01             	add    $0x1,%eax
80102a1b:	83 ec 08             	sub    $0x8,%esp
80102a1e:	50                   	push   %eax
80102a1f:	ff 35 04 27 19 80    	pushl  0x80192704
80102a25:	e8 42 d7 ff ff       	call   8010016c <bread>
80102a2a:	89 c6                	mov    %eax,%esi
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
80102a2c:	83 c4 08             	add    $0x8,%esp
80102a2f:	ff 34 9d 0c 27 19 80 	pushl  -0x7fe6d8f4(,%ebx,4)
80102a36:	ff 35 04 27 19 80    	pushl  0x80192704
80102a3c:	e8 2b d7 ff ff       	call   8010016c <bread>
80102a41:	89 c7                	mov    %eax,%edi
    memmove(to->data, from->data, BSIZE);
80102a43:	8d 50 5c             	lea    0x5c(%eax),%edx
80102a46:	8d 46 5c             	lea    0x5c(%esi),%eax
80102a49:	83 c4 0c             	add    $0xc,%esp
80102a4c:	68 00 02 00 00       	push   $0x200
80102a51:	52                   	push   %edx
80102a52:	50                   	push   %eax
80102a53:	e8 cc 15 00 00       	call   80104024 <memmove>
    bwrite(to);  // write the log
80102a58:	89 34 24             	mov    %esi,(%esp)
80102a5b:	e8 3a d7 ff ff       	call   8010019a <bwrite>
    brelse(from);
80102a60:	89 3c 24             	mov    %edi,(%esp)
80102a63:	e8 6d d7 ff ff       	call   801001d5 <brelse>
    brelse(to);
80102a68:	89 34 24             	mov    %esi,(%esp)
80102a6b:	e8 65 d7 ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
80102a70:	83 c3 01             	add    $0x1,%ebx
80102a73:	83 c4 10             	add    $0x10,%esp
80102a76:	39 1d 08 27 19 80    	cmp    %ebx,0x80192708
80102a7c:	7f 92                	jg     80102a10 <write_log+0x10>
  }
}
80102a7e:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102a81:	5b                   	pop    %ebx
80102a82:	5e                   	pop    %esi
80102a83:	5f                   	pop    %edi
80102a84:	5d                   	pop    %ebp
80102a85:	c3                   	ret    

80102a86 <commit>:

static void
commit()
{
  if (log.lh.n > 0) {
80102a86:	83 3d 08 27 19 80 00 	cmpl   $0x0,0x80192708
80102a8d:	7e 26                	jle    80102ab5 <commit+0x2f>
{
80102a8f:	55                   	push   %ebp
80102a90:	89 e5                	mov    %esp,%ebp
80102a92:	83 ec 08             	sub    $0x8,%esp
    write_log();     // Write modified blocks from cache to log
80102a95:	e8 66 ff ff ff       	call   80102a00 <write_log>
    write_head();    // Write header to disk -- the real commit
80102a9a:	e8 e8 fe ff ff       	call   80102987 <write_head>
    install_trans(); // Now install writes to home locations
80102a9f:	e8 5d fe ff ff       	call   80102901 <install_trans>
    log.lh.n = 0;
80102aa4:	c7 05 08 27 19 80 00 	movl   $0x0,0x80192708
80102aab:	00 00 00 
    write_head();    // Erase the transaction from the log
80102aae:	e8 d4 fe ff ff       	call   80102987 <write_head>
  }
}
80102ab3:	c9                   	leave  
80102ab4:	c3                   	ret    
80102ab5:	f3 c3                	repz ret 

80102ab7 <initlog>:
{
80102ab7:	55                   	push   %ebp
80102ab8:	89 e5                	mov    %esp,%ebp
80102aba:	53                   	push   %ebx
80102abb:	83 ec 2c             	sub    $0x2c,%esp
80102abe:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&log.lock, "log");
80102ac1:	68 e0 6c 10 80       	push   $0x80106ce0
80102ac6:	68 c0 26 19 80       	push   $0x801926c0
80102acb:	e8 f1 12 00 00       	call   80103dc1 <initlock>
  readsb(dev, &sb);
80102ad0:	83 c4 08             	add    $0x8,%esp
80102ad3:	8d 45 dc             	lea    -0x24(%ebp),%eax
80102ad6:	50                   	push   %eax
80102ad7:	53                   	push   %ebx
80102ad8:	e8 65 e7 ff ff       	call   80101242 <readsb>
  log.start = sb.logstart;
80102add:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102ae0:	a3 f4 26 19 80       	mov    %eax,0x801926f4
  log.size = sb.nlog;
80102ae5:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102ae8:	a3 f8 26 19 80       	mov    %eax,0x801926f8
  log.dev = dev;
80102aed:	89 1d 04 27 19 80    	mov    %ebx,0x80192704
  recover_from_log();
80102af3:	e8 e7 fe ff ff       	call   801029df <recover_from_log>
}
80102af8:	83 c4 10             	add    $0x10,%esp
80102afb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102afe:	c9                   	leave  
80102aff:	c3                   	ret    

80102b00 <begin_op>:
{
80102b00:	55                   	push   %ebp
80102b01:	89 e5                	mov    %esp,%ebp
80102b03:	83 ec 14             	sub    $0x14,%esp
  acquire(&log.lock);
80102b06:	68 c0 26 19 80       	push   $0x801926c0
80102b0b:	e8 ed 13 00 00       	call   80103efd <acquire>
80102b10:	83 c4 10             	add    $0x10,%esp
80102b13:	eb 15                	jmp    80102b2a <begin_op+0x2a>
      sleep(&log, &log.lock);
80102b15:	83 ec 08             	sub    $0x8,%esp
80102b18:	68 c0 26 19 80       	push   $0x801926c0
80102b1d:	68 c0 26 19 80       	push   $0x801926c0
80102b22:	e8 db 0e 00 00       	call   80103a02 <sleep>
80102b27:	83 c4 10             	add    $0x10,%esp
    if(log.committing){
80102b2a:	83 3d 00 27 19 80 00 	cmpl   $0x0,0x80192700
80102b31:	75 e2                	jne    80102b15 <begin_op+0x15>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
80102b33:	a1 fc 26 19 80       	mov    0x801926fc,%eax
80102b38:	83 c0 01             	add    $0x1,%eax
80102b3b:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102b3e:	8d 14 09             	lea    (%ecx,%ecx,1),%edx
80102b41:	03 15 08 27 19 80    	add    0x80192708,%edx
80102b47:	83 fa 1e             	cmp    $0x1e,%edx
80102b4a:	7e 17                	jle    80102b63 <begin_op+0x63>
      sleep(&log, &log.lock);
80102b4c:	83 ec 08             	sub    $0x8,%esp
80102b4f:	68 c0 26 19 80       	push   $0x801926c0
80102b54:	68 c0 26 19 80       	push   $0x801926c0
80102b59:	e8 a4 0e 00 00       	call   80103a02 <sleep>
80102b5e:	83 c4 10             	add    $0x10,%esp
80102b61:	eb c7                	jmp    80102b2a <begin_op+0x2a>
      log.outstanding += 1;
80102b63:	a3 fc 26 19 80       	mov    %eax,0x801926fc
      release(&log.lock);
80102b68:	83 ec 0c             	sub    $0xc,%esp
80102b6b:	68 c0 26 19 80       	push   $0x801926c0
80102b70:	e8 ed 13 00 00       	call   80103f62 <release>
}
80102b75:	83 c4 10             	add    $0x10,%esp
80102b78:	c9                   	leave  
80102b79:	c3                   	ret    

80102b7a <end_op>:
{
80102b7a:	55                   	push   %ebp
80102b7b:	89 e5                	mov    %esp,%ebp
80102b7d:	53                   	push   %ebx
80102b7e:	83 ec 10             	sub    $0x10,%esp
  acquire(&log.lock);
80102b81:	68 c0 26 19 80       	push   $0x801926c0
80102b86:	e8 72 13 00 00       	call   80103efd <acquire>
  log.outstanding -= 1;
80102b8b:	a1 fc 26 19 80       	mov    0x801926fc,%eax
80102b90:	83 e8 01             	sub    $0x1,%eax
80102b93:	a3 fc 26 19 80       	mov    %eax,0x801926fc
  if(log.committing)
80102b98:	8b 1d 00 27 19 80    	mov    0x80192700,%ebx
80102b9e:	83 c4 10             	add    $0x10,%esp
80102ba1:	85 db                	test   %ebx,%ebx
80102ba3:	75 2c                	jne    80102bd1 <end_op+0x57>
  if(log.outstanding == 0){
80102ba5:	85 c0                	test   %eax,%eax
80102ba7:	75 35                	jne    80102bde <end_op+0x64>
    log.committing = 1;
80102ba9:	c7 05 00 27 19 80 01 	movl   $0x1,0x80192700
80102bb0:	00 00 00 
    do_commit = 1;
80102bb3:	bb 01 00 00 00       	mov    $0x1,%ebx
  release(&log.lock);
80102bb8:	83 ec 0c             	sub    $0xc,%esp
80102bbb:	68 c0 26 19 80       	push   $0x801926c0
80102bc0:	e8 9d 13 00 00       	call   80103f62 <release>
  if(do_commit){
80102bc5:	83 c4 10             	add    $0x10,%esp
80102bc8:	85 db                	test   %ebx,%ebx
80102bca:	75 24                	jne    80102bf0 <end_op+0x76>
}
80102bcc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102bcf:	c9                   	leave  
80102bd0:	c3                   	ret    
    panic("log.committing");
80102bd1:	83 ec 0c             	sub    $0xc,%esp
80102bd4:	68 e4 6c 10 80       	push   $0x80106ce4
80102bd9:	e8 6a d7 ff ff       	call   80100348 <panic>
    wakeup(&log);
80102bde:	83 ec 0c             	sub    $0xc,%esp
80102be1:	68 c0 26 19 80       	push   $0x801926c0
80102be6:	e8 7c 0f 00 00       	call   80103b67 <wakeup>
80102beb:	83 c4 10             	add    $0x10,%esp
80102bee:	eb c8                	jmp    80102bb8 <end_op+0x3e>
    commit();
80102bf0:	e8 91 fe ff ff       	call   80102a86 <commit>
    acquire(&log.lock);
80102bf5:	83 ec 0c             	sub    $0xc,%esp
80102bf8:	68 c0 26 19 80       	push   $0x801926c0
80102bfd:	e8 fb 12 00 00       	call   80103efd <acquire>
    log.committing = 0;
80102c02:	c7 05 00 27 19 80 00 	movl   $0x0,0x80192700
80102c09:	00 00 00 
    wakeup(&log);
80102c0c:	c7 04 24 c0 26 19 80 	movl   $0x801926c0,(%esp)
80102c13:	e8 4f 0f 00 00       	call   80103b67 <wakeup>
    release(&log.lock);
80102c18:	c7 04 24 c0 26 19 80 	movl   $0x801926c0,(%esp)
80102c1f:	e8 3e 13 00 00       	call   80103f62 <release>
80102c24:	83 c4 10             	add    $0x10,%esp
}
80102c27:	eb a3                	jmp    80102bcc <end_op+0x52>

80102c29 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80102c29:	55                   	push   %ebp
80102c2a:	89 e5                	mov    %esp,%ebp
80102c2c:	53                   	push   %ebx
80102c2d:	83 ec 04             	sub    $0x4,%esp
80102c30:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80102c33:	8b 15 08 27 19 80    	mov    0x80192708,%edx
80102c39:	83 fa 1d             	cmp    $0x1d,%edx
80102c3c:	7f 45                	jg     80102c83 <log_write+0x5a>
80102c3e:	a1 f8 26 19 80       	mov    0x801926f8,%eax
80102c43:	83 e8 01             	sub    $0x1,%eax
80102c46:	39 c2                	cmp    %eax,%edx
80102c48:	7d 39                	jge    80102c83 <log_write+0x5a>
    panic("too big a transaction");
  if (log.outstanding < 1)
80102c4a:	83 3d fc 26 19 80 00 	cmpl   $0x0,0x801926fc
80102c51:	7e 3d                	jle    80102c90 <log_write+0x67>
    panic("log_write outside of trans");

  acquire(&log.lock);
80102c53:	83 ec 0c             	sub    $0xc,%esp
80102c56:	68 c0 26 19 80       	push   $0x801926c0
80102c5b:	e8 9d 12 00 00       	call   80103efd <acquire>
  for (i = 0; i < log.lh.n; i++) {
80102c60:	83 c4 10             	add    $0x10,%esp
80102c63:	b8 00 00 00 00       	mov    $0x0,%eax
80102c68:	8b 15 08 27 19 80    	mov    0x80192708,%edx
80102c6e:	39 c2                	cmp    %eax,%edx
80102c70:	7e 2b                	jle    80102c9d <log_write+0x74>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
80102c72:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102c75:	39 0c 85 0c 27 19 80 	cmp    %ecx,-0x7fe6d8f4(,%eax,4)
80102c7c:	74 1f                	je     80102c9d <log_write+0x74>
  for (i = 0; i < log.lh.n; i++) {
80102c7e:	83 c0 01             	add    $0x1,%eax
80102c81:	eb e5                	jmp    80102c68 <log_write+0x3f>
    panic("too big a transaction");
80102c83:	83 ec 0c             	sub    $0xc,%esp
80102c86:	68 f3 6c 10 80       	push   $0x80106cf3
80102c8b:	e8 b8 d6 ff ff       	call   80100348 <panic>
    panic("log_write outside of trans");
80102c90:	83 ec 0c             	sub    $0xc,%esp
80102c93:	68 09 6d 10 80       	push   $0x80106d09
80102c98:	e8 ab d6 ff ff       	call   80100348 <panic>
      break;
  }
  log.lh.block[i] = b->blockno;
80102c9d:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102ca0:	89 0c 85 0c 27 19 80 	mov    %ecx,-0x7fe6d8f4(,%eax,4)
  if (i == log.lh.n)
80102ca7:	39 c2                	cmp    %eax,%edx
80102ca9:	74 18                	je     80102cc3 <log_write+0x9a>
    log.lh.n++;
  b->flags |= B_DIRTY; // prevent eviction
80102cab:	83 0b 04             	orl    $0x4,(%ebx)
  release(&log.lock);
80102cae:	83 ec 0c             	sub    $0xc,%esp
80102cb1:	68 c0 26 19 80       	push   $0x801926c0
80102cb6:	e8 a7 12 00 00       	call   80103f62 <release>
}
80102cbb:	83 c4 10             	add    $0x10,%esp
80102cbe:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102cc1:	c9                   	leave  
80102cc2:	c3                   	ret    
    log.lh.n++;
80102cc3:	83 c2 01             	add    $0x1,%edx
80102cc6:	89 15 08 27 19 80    	mov    %edx,0x80192708
80102ccc:	eb dd                	jmp    80102cab <log_write+0x82>

80102cce <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80102cce:	55                   	push   %ebp
80102ccf:	89 e5                	mov    %esp,%ebp
80102cd1:	53                   	push   %ebx
80102cd2:	83 ec 08             	sub    $0x8,%esp

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80102cd5:	68 8a 00 00 00       	push   $0x8a
80102cda:	68 8c a4 10 80       	push   $0x8010a48c
80102cdf:	68 00 70 00 80       	push   $0x80007000
80102ce4:	e8 3b 13 00 00       	call   80104024 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80102ce9:	83 c4 10             	add    $0x10,%esp
80102cec:	bb c0 27 19 80       	mov    $0x801927c0,%ebx
80102cf1:	eb 06                	jmp    80102cf9 <startothers+0x2b>
80102cf3:	81 c3 b0 00 00 00    	add    $0xb0,%ebx
80102cf9:	69 05 40 2d 19 80 b0 	imul   $0xb0,0x80192d40,%eax
80102d00:	00 00 00 
80102d03:	05 c0 27 19 80       	add    $0x801927c0,%eax
80102d08:	39 d8                	cmp    %ebx,%eax
80102d0a:	76 51                	jbe    80102d5d <startothers+0x8f>
    if(c == mycpu())  // We've started already.
80102d0c:	e8 d3 07 00 00       	call   801034e4 <mycpu>
80102d11:	39 d8                	cmp    %ebx,%eax
80102d13:	74 de                	je     80102cf3 <startothers+0x25>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc(-2);
80102d15:	83 ec 0c             	sub    $0xc,%esp
80102d18:	6a fe                	push   $0xfffffffe
80102d1a:	e8 e1 f4 ff ff       	call   80102200 <kalloc>
    *(void**)(code-4) = stack + KSTACKSIZE;
80102d1f:	05 00 10 00 00       	add    $0x1000,%eax
80102d24:	a3 fc 6f 00 80       	mov    %eax,0x80006ffc
    *(void(**)(void))(code-8) = mpenter;
80102d29:	c7 05 f8 6f 00 80 a1 	movl   $0x80102da1,0x80006ff8
80102d30:	2d 10 80 
    *(int**)(code-12) = (void *) V2P(entrypgdir);
80102d33:	c7 05 f4 6f 00 80 00 	movl   $0x109000,0x80006ff4
80102d3a:	90 10 00 

    lapicstartap(c->apicid, V2P(code));
80102d3d:	83 c4 08             	add    $0x8,%esp
80102d40:	68 00 70 00 00       	push   $0x7000
80102d45:	0f b6 03             	movzbl (%ebx),%eax
80102d48:	50                   	push   %eax
80102d49:	e8 c1 f9 ff ff       	call   8010270f <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80102d4e:	83 c4 10             	add    $0x10,%esp
80102d51:	8b 83 a0 00 00 00    	mov    0xa0(%ebx),%eax
80102d57:	85 c0                	test   %eax,%eax
80102d59:	74 f6                	je     80102d51 <startothers+0x83>
80102d5b:	eb 96                	jmp    80102cf3 <startothers+0x25>
      ;
  }
}
80102d5d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102d60:	c9                   	leave  
80102d61:	c3                   	ret    

80102d62 <mpmain>:
{
80102d62:	55                   	push   %ebp
80102d63:	89 e5                	mov    %esp,%ebp
80102d65:	53                   	push   %ebx
80102d66:	83 ec 04             	sub    $0x4,%esp
  cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
80102d69:	e8 d2 07 00 00       	call   80103540 <cpuid>
80102d6e:	89 c3                	mov    %eax,%ebx
80102d70:	e8 cb 07 00 00       	call   80103540 <cpuid>
80102d75:	83 ec 04             	sub    $0x4,%esp
80102d78:	53                   	push   %ebx
80102d79:	50                   	push   %eax
80102d7a:	68 24 6d 10 80       	push   $0x80106d24
80102d7f:	e8 87 d8 ff ff       	call   8010060b <cprintf>
  idtinit();       // load idt register
80102d84:	e8 fc 23 00 00       	call   80105185 <idtinit>
  xchg(&(mycpu()->started), 1); // tell startothers() we're up
80102d89:	e8 56 07 00 00       	call   801034e4 <mycpu>
80102d8e:	89 c2                	mov    %eax,%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80102d90:	b8 01 00 00 00       	mov    $0x1,%eax
80102d95:	f0 87 82 a0 00 00 00 	lock xchg %eax,0xa0(%edx)
  scheduler();     // start running processes
80102d9c:	e8 3c 0a 00 00       	call   801037dd <scheduler>

80102da1 <mpenter>:
{
80102da1:	55                   	push   %ebp
80102da2:	89 e5                	mov    %esp,%ebp
80102da4:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
80102da7:	e8 ea 33 00 00       	call   80106196 <switchkvm>
  seginit();
80102dac:	e8 99 32 00 00       	call   8010604a <seginit>
  lapicinit();
80102db1:	e8 10 f8 ff ff       	call   801025c6 <lapicinit>
  mpmain();
80102db6:	e8 a7 ff ff ff       	call   80102d62 <mpmain>

80102dbb <main>:
{
80102dbb:	8d 4c 24 04          	lea    0x4(%esp),%ecx
80102dbf:	83 e4 f0             	and    $0xfffffff0,%esp
80102dc2:	ff 71 fc             	pushl  -0x4(%ecx)
80102dc5:	55                   	push   %ebp
80102dc6:	89 e5                	mov    %esp,%ebp
80102dc8:	51                   	push   %ecx
80102dc9:	83 ec 0c             	sub    $0xc,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80102dcc:	68 00 00 40 80       	push   $0x80400000
80102dd1:	68 e8 54 19 80       	push   $0x801954e8
80102dd6:	e8 3a f3 ff ff       	call   80102115 <kinit1>
  kvmalloc();      // kernel page table
80102ddb:	e8 59 38 00 00       	call   80106639 <kvmalloc>
  mpinit();        // detect other processors
80102de0:	e8 c9 01 00 00       	call   80102fae <mpinit>
  lapicinit();     // interrupt controller
80102de5:	e8 dc f7 ff ff       	call   801025c6 <lapicinit>
  seginit();       // segment descriptors
80102dea:	e8 5b 32 00 00       	call   8010604a <seginit>
  picinit();       // disable pic
80102def:	e8 82 02 00 00       	call   80103076 <picinit>
  ioapicinit();    // another interrupt controller
80102df4:	e8 0d f1 ff ff       	call   80101f06 <ioapicinit>
  consoleinit();   // console hardware
80102df9:	e8 90 da ff ff       	call   8010088e <consoleinit>
  uartinit();      // serial port
80102dfe:	e8 30 26 00 00       	call   80105433 <uartinit>
  pinit();         // process table
80102e03:	e8 c2 06 00 00       	call   801034ca <pinit>
  tvinit();        // trap vectors
80102e08:	e8 c7 22 00 00       	call   801050d4 <tvinit>
  binit();         // buffer cache
80102e0d:	e8 e2 d2 ff ff       	call   801000f4 <binit>
  fileinit();      // file table
80102e12:	e8 08 de ff ff       	call   80100c1f <fileinit>
  ideinit();       // disk 
80102e17:	e8 f0 ee ff ff       	call   80101d0c <ideinit>
  startothers();   // start other processors
80102e1c:	e8 ad fe ff ff       	call   80102cce <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80102e21:	83 c4 08             	add    $0x8,%esp
80102e24:	68 00 00 00 8e       	push   $0x8e000000
80102e29:	68 00 00 40 80       	push   $0x80400000
80102e2e:	e8 14 f3 ff ff       	call   80102147 <kinit2>
  userinit();      // first user process
80102e33:	e8 47 07 00 00       	call   8010357f <userinit>
  mpmain();        // finish this processor's setup
80102e38:	e8 25 ff ff ff       	call   80102d62 <mpmain>

80102e3d <sum>:
int ncpu;
uchar ioapicid;

static uchar
sum(uchar *addr, int len)
{
80102e3d:	55                   	push   %ebp
80102e3e:	89 e5                	mov    %esp,%ebp
80102e40:	56                   	push   %esi
80102e41:	53                   	push   %ebx
  int i, sum;

  sum = 0;
80102e42:	bb 00 00 00 00       	mov    $0x0,%ebx
  for(i=0; i<len; i++)
80102e47:	b9 00 00 00 00       	mov    $0x0,%ecx
80102e4c:	eb 09                	jmp    80102e57 <sum+0x1a>
    sum += addr[i];
80102e4e:	0f b6 34 08          	movzbl (%eax,%ecx,1),%esi
80102e52:	01 f3                	add    %esi,%ebx
  for(i=0; i<len; i++)
80102e54:	83 c1 01             	add    $0x1,%ecx
80102e57:	39 d1                	cmp    %edx,%ecx
80102e59:	7c f3                	jl     80102e4e <sum+0x11>
  return sum;
}
80102e5b:	89 d8                	mov    %ebx,%eax
80102e5d:	5b                   	pop    %ebx
80102e5e:	5e                   	pop    %esi
80102e5f:	5d                   	pop    %ebp
80102e60:	c3                   	ret    

80102e61 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80102e61:	55                   	push   %ebp
80102e62:	89 e5                	mov    %esp,%ebp
80102e64:	56                   	push   %esi
80102e65:	53                   	push   %ebx
  uchar *e, *p, *addr;

  addr = P2V(a);
80102e66:	8d b0 00 00 00 80    	lea    -0x80000000(%eax),%esi
80102e6c:	89 f3                	mov    %esi,%ebx
  e = addr+len;
80102e6e:	01 d6                	add    %edx,%esi
  for(p = addr; p < e; p += sizeof(struct mp))
80102e70:	eb 03                	jmp    80102e75 <mpsearch1+0x14>
80102e72:	83 c3 10             	add    $0x10,%ebx
80102e75:	39 f3                	cmp    %esi,%ebx
80102e77:	73 29                	jae    80102ea2 <mpsearch1+0x41>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80102e79:	83 ec 04             	sub    $0x4,%esp
80102e7c:	6a 04                	push   $0x4
80102e7e:	68 38 6d 10 80       	push   $0x80106d38
80102e83:	53                   	push   %ebx
80102e84:	e8 66 11 00 00       	call   80103fef <memcmp>
80102e89:	83 c4 10             	add    $0x10,%esp
80102e8c:	85 c0                	test   %eax,%eax
80102e8e:	75 e2                	jne    80102e72 <mpsearch1+0x11>
80102e90:	ba 10 00 00 00       	mov    $0x10,%edx
80102e95:	89 d8                	mov    %ebx,%eax
80102e97:	e8 a1 ff ff ff       	call   80102e3d <sum>
80102e9c:	84 c0                	test   %al,%al
80102e9e:	75 d2                	jne    80102e72 <mpsearch1+0x11>
80102ea0:	eb 05                	jmp    80102ea7 <mpsearch1+0x46>
      return (struct mp*)p;
  return 0;
80102ea2:	bb 00 00 00 00       	mov    $0x0,%ebx
}
80102ea7:	89 d8                	mov    %ebx,%eax
80102ea9:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102eac:	5b                   	pop    %ebx
80102ead:	5e                   	pop    %esi
80102eae:	5d                   	pop    %ebp
80102eaf:	c3                   	ret    

80102eb0 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80102eb0:	55                   	push   %ebp
80102eb1:	89 e5                	mov    %esp,%ebp
80102eb3:	83 ec 08             	sub    $0x8,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80102eb6:	0f b6 05 0f 04 00 80 	movzbl 0x8000040f,%eax
80102ebd:	c1 e0 08             	shl    $0x8,%eax
80102ec0:	0f b6 15 0e 04 00 80 	movzbl 0x8000040e,%edx
80102ec7:	09 d0                	or     %edx,%eax
80102ec9:	c1 e0 04             	shl    $0x4,%eax
80102ecc:	85 c0                	test   %eax,%eax
80102ece:	74 1f                	je     80102eef <mpsearch+0x3f>
    if((mp = mpsearch1(p, 1024)))
80102ed0:	ba 00 04 00 00       	mov    $0x400,%edx
80102ed5:	e8 87 ff ff ff       	call   80102e61 <mpsearch1>
80102eda:	85 c0                	test   %eax,%eax
80102edc:	75 0f                	jne    80102eed <mpsearch+0x3d>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1(p-1024, 1024)))
      return mp;
  }
  return mpsearch1(0xF0000, 0x10000);
80102ede:	ba 00 00 01 00       	mov    $0x10000,%edx
80102ee3:	b8 00 00 0f 00       	mov    $0xf0000,%eax
80102ee8:	e8 74 ff ff ff       	call   80102e61 <mpsearch1>
}
80102eed:	c9                   	leave  
80102eee:	c3                   	ret    
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80102eef:	0f b6 05 14 04 00 80 	movzbl 0x80000414,%eax
80102ef6:	c1 e0 08             	shl    $0x8,%eax
80102ef9:	0f b6 15 13 04 00 80 	movzbl 0x80000413,%edx
80102f00:	09 d0                	or     %edx,%eax
80102f02:	c1 e0 0a             	shl    $0xa,%eax
    if((mp = mpsearch1(p-1024, 1024)))
80102f05:	2d 00 04 00 00       	sub    $0x400,%eax
80102f0a:	ba 00 04 00 00       	mov    $0x400,%edx
80102f0f:	e8 4d ff ff ff       	call   80102e61 <mpsearch1>
80102f14:	85 c0                	test   %eax,%eax
80102f16:	75 d5                	jne    80102eed <mpsearch+0x3d>
80102f18:	eb c4                	jmp    80102ede <mpsearch+0x2e>

80102f1a <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80102f1a:	55                   	push   %ebp
80102f1b:	89 e5                	mov    %esp,%ebp
80102f1d:	57                   	push   %edi
80102f1e:	56                   	push   %esi
80102f1f:	53                   	push   %ebx
80102f20:	83 ec 1c             	sub    $0x1c,%esp
80102f23:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80102f26:	e8 85 ff ff ff       	call   80102eb0 <mpsearch>
80102f2b:	85 c0                	test   %eax,%eax
80102f2d:	74 5c                	je     80102f8b <mpconfig+0x71>
80102f2f:	89 c7                	mov    %eax,%edi
80102f31:	8b 58 04             	mov    0x4(%eax),%ebx
80102f34:	85 db                	test   %ebx,%ebx
80102f36:	74 5a                	je     80102f92 <mpconfig+0x78>
    return 0;
  conf = (struct mpconf*) P2V((uint) mp->physaddr);
80102f38:	8d b3 00 00 00 80    	lea    -0x80000000(%ebx),%esi
  if(memcmp(conf, "PCMP", 4) != 0)
80102f3e:	83 ec 04             	sub    $0x4,%esp
80102f41:	6a 04                	push   $0x4
80102f43:	68 3d 6d 10 80       	push   $0x80106d3d
80102f48:	56                   	push   %esi
80102f49:	e8 a1 10 00 00       	call   80103fef <memcmp>
80102f4e:	83 c4 10             	add    $0x10,%esp
80102f51:	85 c0                	test   %eax,%eax
80102f53:	75 44                	jne    80102f99 <mpconfig+0x7f>
    return 0;
  if(conf->version != 1 && conf->version != 4)
80102f55:	0f b6 83 06 00 00 80 	movzbl -0x7ffffffa(%ebx),%eax
80102f5c:	3c 01                	cmp    $0x1,%al
80102f5e:	0f 95 c2             	setne  %dl
80102f61:	3c 04                	cmp    $0x4,%al
80102f63:	0f 95 c0             	setne  %al
80102f66:	84 c2                	test   %al,%dl
80102f68:	75 36                	jne    80102fa0 <mpconfig+0x86>
    return 0;
  if(sum((uchar*)conf, conf->length) != 0)
80102f6a:	0f b7 93 04 00 00 80 	movzwl -0x7ffffffc(%ebx),%edx
80102f71:	89 f0                	mov    %esi,%eax
80102f73:	e8 c5 fe ff ff       	call   80102e3d <sum>
80102f78:	84 c0                	test   %al,%al
80102f7a:	75 2b                	jne    80102fa7 <mpconfig+0x8d>
    return 0;
  *pmp = mp;
80102f7c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102f7f:	89 38                	mov    %edi,(%eax)
  return conf;
}
80102f81:	89 f0                	mov    %esi,%eax
80102f83:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102f86:	5b                   	pop    %ebx
80102f87:	5e                   	pop    %esi
80102f88:	5f                   	pop    %edi
80102f89:	5d                   	pop    %ebp
80102f8a:	c3                   	ret    
    return 0;
80102f8b:	be 00 00 00 00       	mov    $0x0,%esi
80102f90:	eb ef                	jmp    80102f81 <mpconfig+0x67>
80102f92:	be 00 00 00 00       	mov    $0x0,%esi
80102f97:	eb e8                	jmp    80102f81 <mpconfig+0x67>
    return 0;
80102f99:	be 00 00 00 00       	mov    $0x0,%esi
80102f9e:	eb e1                	jmp    80102f81 <mpconfig+0x67>
    return 0;
80102fa0:	be 00 00 00 00       	mov    $0x0,%esi
80102fa5:	eb da                	jmp    80102f81 <mpconfig+0x67>
    return 0;
80102fa7:	be 00 00 00 00       	mov    $0x0,%esi
80102fac:	eb d3                	jmp    80102f81 <mpconfig+0x67>

80102fae <mpinit>:

void
mpinit(void)
{
80102fae:	55                   	push   %ebp
80102faf:	89 e5                	mov    %esp,%ebp
80102fb1:	57                   	push   %edi
80102fb2:	56                   	push   %esi
80102fb3:	53                   	push   %ebx
80102fb4:	83 ec 1c             	sub    $0x1c,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  if((conf = mpconfig(&mp)) == 0)
80102fb7:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80102fba:	e8 5b ff ff ff       	call   80102f1a <mpconfig>
80102fbf:	85 c0                	test   %eax,%eax
80102fc1:	74 19                	je     80102fdc <mpinit+0x2e>
    panic("Expect to run on an SMP");
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
80102fc3:	8b 50 24             	mov    0x24(%eax),%edx
80102fc6:	89 15 a0 26 19 80    	mov    %edx,0x801926a0
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102fcc:	8d 50 2c             	lea    0x2c(%eax),%edx
80102fcf:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
80102fd3:	01 c1                	add    %eax,%ecx
  ismp = 1;
80102fd5:	bb 01 00 00 00       	mov    $0x1,%ebx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102fda:	eb 34                	jmp    80103010 <mpinit+0x62>
    panic("Expect to run on an SMP");
80102fdc:	83 ec 0c             	sub    $0xc,%esp
80102fdf:	68 42 6d 10 80       	push   $0x80106d42
80102fe4:	e8 5f d3 ff ff       	call   80100348 <panic>
    switch(*p){
    case MPPROC:
      proc = (struct mpproc*)p;
      if(ncpu < NCPU) {
80102fe9:	8b 35 40 2d 19 80    	mov    0x80192d40,%esi
80102fef:	83 fe 07             	cmp    $0x7,%esi
80102ff2:	7f 19                	jg     8010300d <mpinit+0x5f>
        cpus[ncpu].apicid = proc->apicid;  // apicid may differ from ncpu
80102ff4:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102ff8:	69 fe b0 00 00 00    	imul   $0xb0,%esi,%edi
80102ffe:	88 87 c0 27 19 80    	mov    %al,-0x7fe6d840(%edi)
        ncpu++;
80103004:	83 c6 01             	add    $0x1,%esi
80103007:	89 35 40 2d 19 80    	mov    %esi,0x80192d40
      }
      p += sizeof(struct mpproc);
8010300d:	83 c2 14             	add    $0x14,%edx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103010:	39 ca                	cmp    %ecx,%edx
80103012:	73 2b                	jae    8010303f <mpinit+0x91>
    switch(*p){
80103014:	0f b6 02             	movzbl (%edx),%eax
80103017:	3c 04                	cmp    $0x4,%al
80103019:	77 1d                	ja     80103038 <mpinit+0x8a>
8010301b:	0f b6 c0             	movzbl %al,%eax
8010301e:	ff 24 85 7c 6d 10 80 	jmp    *-0x7fef9284(,%eax,4)
      continue;
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
      ioapicid = ioapic->apicno;
80103025:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80103029:	a2 a0 27 19 80       	mov    %al,0x801927a0
      p += sizeof(struct mpioapic);
8010302e:	83 c2 08             	add    $0x8,%edx
      continue;
80103031:	eb dd                	jmp    80103010 <mpinit+0x62>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80103033:	83 c2 08             	add    $0x8,%edx
      continue;
80103036:	eb d8                	jmp    80103010 <mpinit+0x62>
    default:
      ismp = 0;
80103038:	bb 00 00 00 00       	mov    $0x0,%ebx
8010303d:	eb d1                	jmp    80103010 <mpinit+0x62>
      break;
    }
  }
  if(!ismp)
8010303f:	85 db                	test   %ebx,%ebx
80103041:	74 26                	je     80103069 <mpinit+0xbb>
    panic("Didn't find a suitable machine");

  if(mp->imcrp){
80103043:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103046:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
8010304a:	74 15                	je     80103061 <mpinit+0xb3>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010304c:	b8 70 00 00 00       	mov    $0x70,%eax
80103051:	ba 22 00 00 00       	mov    $0x22,%edx
80103056:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103057:	ba 23 00 00 00       	mov    $0x23,%edx
8010305c:	ec                   	in     (%dx),%al
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
8010305d:	83 c8 01             	or     $0x1,%eax
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103060:	ee                   	out    %al,(%dx)
  }
}
80103061:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103064:	5b                   	pop    %ebx
80103065:	5e                   	pop    %esi
80103066:	5f                   	pop    %edi
80103067:	5d                   	pop    %ebp
80103068:	c3                   	ret    
    panic("Didn't find a suitable machine");
80103069:	83 ec 0c             	sub    $0xc,%esp
8010306c:	68 5c 6d 10 80       	push   $0x80106d5c
80103071:	e8 d2 d2 ff ff       	call   80100348 <panic>

80103076 <picinit>:
#define IO_PIC2         0xA0    // Slave (IRQs 8-15)

// Don't use the 8259A interrupt controllers.  Xv6 assumes SMP hardware.
void
picinit(void)
{
80103076:	55                   	push   %ebp
80103077:	89 e5                	mov    %esp,%ebp
80103079:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010307e:	ba 21 00 00 00       	mov    $0x21,%edx
80103083:	ee                   	out    %al,(%dx)
80103084:	ba a1 00 00 00       	mov    $0xa1,%edx
80103089:	ee                   	out    %al,(%dx)
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
  outb(IO_PIC2+1, 0xFF);
}
8010308a:	5d                   	pop    %ebp
8010308b:	c3                   	ret    

8010308c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
8010308c:	55                   	push   %ebp
8010308d:	89 e5                	mov    %esp,%ebp
8010308f:	57                   	push   %edi
80103090:	56                   	push   %esi
80103091:	53                   	push   %ebx
80103092:	83 ec 0c             	sub    $0xc,%esp
80103095:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103098:	8b 75 0c             	mov    0xc(%ebp),%esi
  struct pipe *p;

  p = 0;
  *f0 = *f1 = 0;
8010309b:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
801030a1:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
801030a7:	e8 8d db ff ff       	call   80100c39 <filealloc>
801030ac:	89 03                	mov    %eax,(%ebx)
801030ae:	85 c0                	test   %eax,%eax
801030b0:	74 1e                	je     801030d0 <pipealloc+0x44>
801030b2:	e8 82 db ff ff       	call   80100c39 <filealloc>
801030b7:	89 06                	mov    %eax,(%esi)
801030b9:	85 c0                	test   %eax,%eax
801030bb:	74 13                	je     801030d0 <pipealloc+0x44>
    goto bad;
  if((p = (struct pipe*)kalloc(-2)) == 0)
801030bd:	83 ec 0c             	sub    $0xc,%esp
801030c0:	6a fe                	push   $0xfffffffe
801030c2:	e8 39 f1 ff ff       	call   80102200 <kalloc>
801030c7:	89 c7                	mov    %eax,%edi
801030c9:	83 c4 10             	add    $0x10,%esp
801030cc:	85 c0                	test   %eax,%eax
801030ce:	75 35                	jne    80103105 <pipealloc+0x79>
  return 0;

 bad:
  if(p)
    kfree((char*)p);
  if(*f0)
801030d0:	8b 03                	mov    (%ebx),%eax
801030d2:	85 c0                	test   %eax,%eax
801030d4:	74 0c                	je     801030e2 <pipealloc+0x56>
    fileclose(*f0);
801030d6:	83 ec 0c             	sub    $0xc,%esp
801030d9:	50                   	push   %eax
801030da:	e8 00 dc ff ff       	call   80100cdf <fileclose>
801030df:	83 c4 10             	add    $0x10,%esp
  if(*f1)
801030e2:	8b 06                	mov    (%esi),%eax
801030e4:	85 c0                	test   %eax,%eax
801030e6:	0f 84 8b 00 00 00    	je     80103177 <pipealloc+0xeb>
    fileclose(*f1);
801030ec:	83 ec 0c             	sub    $0xc,%esp
801030ef:	50                   	push   %eax
801030f0:	e8 ea db ff ff       	call   80100cdf <fileclose>
801030f5:	83 c4 10             	add    $0x10,%esp
  return -1;
801030f8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801030fd:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103100:	5b                   	pop    %ebx
80103101:	5e                   	pop    %esi
80103102:	5f                   	pop    %edi
80103103:	5d                   	pop    %ebp
80103104:	c3                   	ret    
  p->readopen = 1;
80103105:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
8010310c:	00 00 00 
  p->writeopen = 1;
8010310f:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80103116:	00 00 00 
  p->nwrite = 0;
80103119:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80103120:	00 00 00 
  p->nread = 0;
80103123:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
8010312a:	00 00 00 
  initlock(&p->lock, "pipe");
8010312d:	83 ec 08             	sub    $0x8,%esp
80103130:	68 90 6d 10 80       	push   $0x80106d90
80103135:	50                   	push   %eax
80103136:	e8 86 0c 00 00       	call   80103dc1 <initlock>
  (*f0)->type = FD_PIPE;
8010313b:	8b 03                	mov    (%ebx),%eax
8010313d:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80103143:	8b 03                	mov    (%ebx),%eax
80103145:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80103149:	8b 03                	mov    (%ebx),%eax
8010314b:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
8010314f:	8b 03                	mov    (%ebx),%eax
80103151:	89 78 0c             	mov    %edi,0xc(%eax)
  (*f1)->type = FD_PIPE;
80103154:	8b 06                	mov    (%esi),%eax
80103156:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
8010315c:	8b 06                	mov    (%esi),%eax
8010315e:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80103162:	8b 06                	mov    (%esi),%eax
80103164:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80103168:	8b 06                	mov    (%esi),%eax
8010316a:	89 78 0c             	mov    %edi,0xc(%eax)
  return 0;
8010316d:	83 c4 10             	add    $0x10,%esp
80103170:	b8 00 00 00 00       	mov    $0x0,%eax
80103175:	eb 86                	jmp    801030fd <pipealloc+0x71>
  return -1;
80103177:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010317c:	e9 7c ff ff ff       	jmp    801030fd <pipealloc+0x71>

80103181 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80103181:	55                   	push   %ebp
80103182:	89 e5                	mov    %esp,%ebp
80103184:	53                   	push   %ebx
80103185:	83 ec 10             	sub    $0x10,%esp
80103188:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&p->lock);
8010318b:	53                   	push   %ebx
8010318c:	e8 6c 0d 00 00       	call   80103efd <acquire>
  if(writable){
80103191:	83 c4 10             	add    $0x10,%esp
80103194:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80103198:	74 3f                	je     801031d9 <pipeclose+0x58>
    p->writeopen = 0;
8010319a:	c7 83 40 02 00 00 00 	movl   $0x0,0x240(%ebx)
801031a1:	00 00 00 
    wakeup(&p->nread);
801031a4:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
801031aa:	83 ec 0c             	sub    $0xc,%esp
801031ad:	50                   	push   %eax
801031ae:	e8 b4 09 00 00       	call   80103b67 <wakeup>
801031b3:	83 c4 10             	add    $0x10,%esp
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
801031b6:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
801031bd:	75 09                	jne    801031c8 <pipeclose+0x47>
801031bf:	83 bb 40 02 00 00 00 	cmpl   $0x0,0x240(%ebx)
801031c6:	74 2f                	je     801031f7 <pipeclose+0x76>
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
801031c8:	83 ec 0c             	sub    $0xc,%esp
801031cb:	53                   	push   %ebx
801031cc:	e8 91 0d 00 00       	call   80103f62 <release>
801031d1:	83 c4 10             	add    $0x10,%esp
}
801031d4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801031d7:	c9                   	leave  
801031d8:	c3                   	ret    
    p->readopen = 0;
801031d9:	c7 83 3c 02 00 00 00 	movl   $0x0,0x23c(%ebx)
801031e0:	00 00 00 
    wakeup(&p->nwrite);
801031e3:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
801031e9:	83 ec 0c             	sub    $0xc,%esp
801031ec:	50                   	push   %eax
801031ed:	e8 75 09 00 00       	call   80103b67 <wakeup>
801031f2:	83 c4 10             	add    $0x10,%esp
801031f5:	eb bf                	jmp    801031b6 <pipeclose+0x35>
    release(&p->lock);
801031f7:	83 ec 0c             	sub    $0xc,%esp
801031fa:	53                   	push   %ebx
801031fb:	e8 62 0d 00 00       	call   80103f62 <release>
    kfree((char*)p);
80103200:	89 1c 24             	mov    %ebx,(%esp)
80103203:	e8 ff ed ff ff       	call   80102007 <kfree>
80103208:	83 c4 10             	add    $0x10,%esp
8010320b:	eb c7                	jmp    801031d4 <pipeclose+0x53>

8010320d <pipewrite>:

int
pipewrite(struct pipe *p, char *addr, int n)
{
8010320d:	55                   	push   %ebp
8010320e:	89 e5                	mov    %esp,%ebp
80103210:	57                   	push   %edi
80103211:	56                   	push   %esi
80103212:	53                   	push   %ebx
80103213:	83 ec 18             	sub    $0x18,%esp
80103216:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80103219:	89 de                	mov    %ebx,%esi
8010321b:	53                   	push   %ebx
8010321c:	e8 dc 0c 00 00       	call   80103efd <acquire>
  for(i = 0; i < n; i++){
80103221:	83 c4 10             	add    $0x10,%esp
80103224:	bf 00 00 00 00       	mov    $0x0,%edi
80103229:	3b 7d 10             	cmp    0x10(%ebp),%edi
8010322c:	0f 8d 88 00 00 00    	jge    801032ba <pipewrite+0xad>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80103232:	8b 93 38 02 00 00    	mov    0x238(%ebx),%edx
80103238:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
8010323e:	05 00 02 00 00       	add    $0x200,%eax
80103243:	39 c2                	cmp    %eax,%edx
80103245:	75 51                	jne    80103298 <pipewrite+0x8b>
      if(p->readopen == 0 || myproc()->killed){
80103247:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
8010324e:	74 2f                	je     8010327f <pipewrite+0x72>
80103250:	e8 06 03 00 00       	call   8010355b <myproc>
80103255:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80103259:	75 24                	jne    8010327f <pipewrite+0x72>
        release(&p->lock);
        return -1;
      }
      wakeup(&p->nread);
8010325b:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80103261:	83 ec 0c             	sub    $0xc,%esp
80103264:	50                   	push   %eax
80103265:	e8 fd 08 00 00       	call   80103b67 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
8010326a:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80103270:	83 c4 08             	add    $0x8,%esp
80103273:	56                   	push   %esi
80103274:	50                   	push   %eax
80103275:	e8 88 07 00 00       	call   80103a02 <sleep>
8010327a:	83 c4 10             	add    $0x10,%esp
8010327d:	eb b3                	jmp    80103232 <pipewrite+0x25>
        release(&p->lock);
8010327f:	83 ec 0c             	sub    $0xc,%esp
80103282:	53                   	push   %ebx
80103283:	e8 da 0c 00 00       	call   80103f62 <release>
        return -1;
80103288:	83 c4 10             	add    $0x10,%esp
8010328b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
  release(&p->lock);
  return n;
}
80103290:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103293:	5b                   	pop    %ebx
80103294:	5e                   	pop    %esi
80103295:	5f                   	pop    %edi
80103296:	5d                   	pop    %ebp
80103297:	c3                   	ret    
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80103298:	8d 42 01             	lea    0x1(%edx),%eax
8010329b:	89 83 38 02 00 00    	mov    %eax,0x238(%ebx)
801032a1:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
801032a7:	8b 45 0c             	mov    0xc(%ebp),%eax
801032aa:	0f b6 04 38          	movzbl (%eax,%edi,1),%eax
801032ae:	88 44 13 34          	mov    %al,0x34(%ebx,%edx,1)
  for(i = 0; i < n; i++){
801032b2:	83 c7 01             	add    $0x1,%edi
801032b5:	e9 6f ff ff ff       	jmp    80103229 <pipewrite+0x1c>
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
801032ba:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
801032c0:	83 ec 0c             	sub    $0xc,%esp
801032c3:	50                   	push   %eax
801032c4:	e8 9e 08 00 00       	call   80103b67 <wakeup>
  release(&p->lock);
801032c9:	89 1c 24             	mov    %ebx,(%esp)
801032cc:	e8 91 0c 00 00       	call   80103f62 <release>
  return n;
801032d1:	83 c4 10             	add    $0x10,%esp
801032d4:	8b 45 10             	mov    0x10(%ebp),%eax
801032d7:	eb b7                	jmp    80103290 <pipewrite+0x83>

801032d9 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
801032d9:	55                   	push   %ebp
801032da:	89 e5                	mov    %esp,%ebp
801032dc:	57                   	push   %edi
801032dd:	56                   	push   %esi
801032de:	53                   	push   %ebx
801032df:	83 ec 18             	sub    $0x18,%esp
801032e2:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
801032e5:	89 df                	mov    %ebx,%edi
801032e7:	53                   	push   %ebx
801032e8:	e8 10 0c 00 00       	call   80103efd <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801032ed:	83 c4 10             	add    $0x10,%esp
801032f0:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
801032f6:	39 83 34 02 00 00    	cmp    %eax,0x234(%ebx)
801032fc:	75 3d                	jne    8010333b <piperead+0x62>
801032fe:	8b b3 40 02 00 00    	mov    0x240(%ebx),%esi
80103304:	85 f6                	test   %esi,%esi
80103306:	74 38                	je     80103340 <piperead+0x67>
    if(myproc()->killed){
80103308:	e8 4e 02 00 00       	call   8010355b <myproc>
8010330d:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80103311:	75 15                	jne    80103328 <piperead+0x4f>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
80103313:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80103319:	83 ec 08             	sub    $0x8,%esp
8010331c:	57                   	push   %edi
8010331d:	50                   	push   %eax
8010331e:	e8 df 06 00 00       	call   80103a02 <sleep>
80103323:	83 c4 10             	add    $0x10,%esp
80103326:	eb c8                	jmp    801032f0 <piperead+0x17>
      release(&p->lock);
80103328:	83 ec 0c             	sub    $0xc,%esp
8010332b:	53                   	push   %ebx
8010332c:	e8 31 0c 00 00       	call   80103f62 <release>
      return -1;
80103331:	83 c4 10             	add    $0x10,%esp
80103334:	be ff ff ff ff       	mov    $0xffffffff,%esi
80103339:	eb 50                	jmp    8010338b <piperead+0xb2>
8010333b:	be 00 00 00 00       	mov    $0x0,%esi
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80103340:	3b 75 10             	cmp    0x10(%ebp),%esi
80103343:	7d 2c                	jge    80103371 <piperead+0x98>
    if(p->nread == p->nwrite)
80103345:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
8010334b:	3b 83 38 02 00 00    	cmp    0x238(%ebx),%eax
80103351:	74 1e                	je     80103371 <piperead+0x98>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
80103353:	8d 50 01             	lea    0x1(%eax),%edx
80103356:	89 93 34 02 00 00    	mov    %edx,0x234(%ebx)
8010335c:	25 ff 01 00 00       	and    $0x1ff,%eax
80103361:	0f b6 44 03 34       	movzbl 0x34(%ebx,%eax,1),%eax
80103366:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103369:	88 04 31             	mov    %al,(%ecx,%esi,1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
8010336c:	83 c6 01             	add    $0x1,%esi
8010336f:	eb cf                	jmp    80103340 <piperead+0x67>
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80103371:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80103377:	83 ec 0c             	sub    $0xc,%esp
8010337a:	50                   	push   %eax
8010337b:	e8 e7 07 00 00       	call   80103b67 <wakeup>
  release(&p->lock);
80103380:	89 1c 24             	mov    %ebx,(%esp)
80103383:	e8 da 0b 00 00       	call   80103f62 <release>
  return i;
80103388:	83 c4 10             	add    $0x10,%esp
}
8010338b:	89 f0                	mov    %esi,%eax
8010338d:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103390:	5b                   	pop    %ebx
80103391:	5e                   	pop    %esi
80103392:	5f                   	pop    %edi
80103393:	5d                   	pop    %ebp
80103394:	c3                   	ret    

80103395 <wakeup1>:

// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80103395:	55                   	push   %ebp
80103396:	89 e5                	mov    %esp,%ebp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103398:	ba 94 2d 19 80       	mov    $0x80192d94,%edx
8010339d:	eb 03                	jmp    801033a2 <wakeup1+0xd>
8010339f:	83 c2 7c             	add    $0x7c,%edx
801033a2:	81 fa 94 4c 19 80    	cmp    $0x80194c94,%edx
801033a8:	73 14                	jae    801033be <wakeup1+0x29>
    if(p->state == SLEEPING && p->chan == chan)
801033aa:	83 7a 0c 02          	cmpl   $0x2,0xc(%edx)
801033ae:	75 ef                	jne    8010339f <wakeup1+0xa>
801033b0:	39 42 20             	cmp    %eax,0x20(%edx)
801033b3:	75 ea                	jne    8010339f <wakeup1+0xa>
      p->state = RUNNABLE;
801033b5:	c7 42 0c 03 00 00 00 	movl   $0x3,0xc(%edx)
801033bc:	eb e1                	jmp    8010339f <wakeup1+0xa>
}
801033be:	5d                   	pop    %ebp
801033bf:	c3                   	ret    

801033c0 <allocproc>:
{
801033c0:	55                   	push   %ebp
801033c1:	89 e5                	mov    %esp,%ebp
801033c3:	53                   	push   %ebx
801033c4:	83 ec 10             	sub    $0x10,%esp
  acquire(&ptable.lock);
801033c7:	68 60 2d 19 80       	push   $0x80192d60
801033cc:	e8 2c 0b 00 00       	call   80103efd <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801033d1:	83 c4 10             	add    $0x10,%esp
801033d4:	bb 94 2d 19 80       	mov    $0x80192d94,%ebx
801033d9:	81 fb 94 4c 19 80    	cmp    $0x80194c94,%ebx
801033df:	73 0b                	jae    801033ec <allocproc+0x2c>
    if(p->state == UNUSED)
801033e1:	83 7b 0c 00          	cmpl   $0x0,0xc(%ebx)
801033e5:	74 1c                	je     80103403 <allocproc+0x43>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801033e7:	83 c3 7c             	add    $0x7c,%ebx
801033ea:	eb ed                	jmp    801033d9 <allocproc+0x19>
  release(&ptable.lock);
801033ec:	83 ec 0c             	sub    $0xc,%esp
801033ef:	68 60 2d 19 80       	push   $0x80192d60
801033f4:	e8 69 0b 00 00       	call   80103f62 <release>
  return 0;
801033f9:	83 c4 10             	add    $0x10,%esp
801033fc:	bb 00 00 00 00       	mov    $0x0,%ebx
80103401:	eb 6f                	jmp    80103472 <allocproc+0xb2>
  p->state = EMBRYO;
80103403:	c7 43 0c 01 00 00 00 	movl   $0x1,0xc(%ebx)
  p->pid = nextpid++;
8010340a:	a1 04 a0 10 80       	mov    0x8010a004,%eax
8010340f:	8d 50 01             	lea    0x1(%eax),%edx
80103412:	89 15 04 a0 10 80    	mov    %edx,0x8010a004
80103418:	89 43 10             	mov    %eax,0x10(%ebx)
  release(&ptable.lock);
8010341b:	83 ec 0c             	sub    $0xc,%esp
8010341e:	68 60 2d 19 80       	push   $0x80192d60
80103423:	e8 3a 0b 00 00       	call   80103f62 <release>
  if((p->kstack = kalloc(p->pid)) == 0){
80103428:	83 c4 04             	add    $0x4,%esp
8010342b:	ff 73 10             	pushl  0x10(%ebx)
8010342e:	e8 cd ed ff ff       	call   80102200 <kalloc>
80103433:	89 43 08             	mov    %eax,0x8(%ebx)
80103436:	83 c4 10             	add    $0x10,%esp
80103439:	85 c0                	test   %eax,%eax
8010343b:	74 3c                	je     80103479 <allocproc+0xb9>
  sp -= sizeof *p->tf;
8010343d:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
  p->tf = (struct trapframe*)sp;
80103443:	89 53 18             	mov    %edx,0x18(%ebx)
  *(uint*)sp = (uint)trapret;
80103446:	c7 80 b0 0f 00 00 c9 	movl   $0x801050c9,0xfb0(%eax)
8010344d:	50 10 80 
  sp -= sizeof *p->context;
80103450:	05 9c 0f 00 00       	add    $0xf9c,%eax
  p->context = (struct context*)sp;
80103455:	89 43 1c             	mov    %eax,0x1c(%ebx)
  memset(p->context, 0, sizeof *p->context);
80103458:	83 ec 04             	sub    $0x4,%esp
8010345b:	6a 14                	push   $0x14
8010345d:	6a 00                	push   $0x0
8010345f:	50                   	push   %eax
80103460:	e8 44 0b 00 00       	call   80103fa9 <memset>
  p->context->eip = (uint)forkret;
80103465:	8b 43 1c             	mov    0x1c(%ebx),%eax
80103468:	c7 40 10 87 34 10 80 	movl   $0x80103487,0x10(%eax)
  return p;
8010346f:	83 c4 10             	add    $0x10,%esp
}
80103472:	89 d8                	mov    %ebx,%eax
80103474:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103477:	c9                   	leave  
80103478:	c3                   	ret    
    p->state = UNUSED;
80103479:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return 0;
80103480:	bb 00 00 00 00       	mov    $0x0,%ebx
80103485:	eb eb                	jmp    80103472 <allocproc+0xb2>

80103487 <forkret>:
{
80103487:	55                   	push   %ebp
80103488:	89 e5                	mov    %esp,%ebp
8010348a:	83 ec 14             	sub    $0x14,%esp
  release(&ptable.lock);
8010348d:	68 60 2d 19 80       	push   $0x80192d60
80103492:	e8 cb 0a 00 00       	call   80103f62 <release>
  if (first) {
80103497:	83 c4 10             	add    $0x10,%esp
8010349a:	83 3d 00 a0 10 80 00 	cmpl   $0x0,0x8010a000
801034a1:	75 02                	jne    801034a5 <forkret+0x1e>
}
801034a3:	c9                   	leave  
801034a4:	c3                   	ret    
    first = 0;
801034a5:	c7 05 00 a0 10 80 00 	movl   $0x0,0x8010a000
801034ac:	00 00 00 
    iinit(ROOTDEV);
801034af:	83 ec 0c             	sub    $0xc,%esp
801034b2:	6a 01                	push   $0x1
801034b4:	e8 3f de ff ff       	call   801012f8 <iinit>
    initlog(ROOTDEV);
801034b9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801034c0:	e8 f2 f5 ff ff       	call   80102ab7 <initlog>
801034c5:	83 c4 10             	add    $0x10,%esp
}
801034c8:	eb d9                	jmp    801034a3 <forkret+0x1c>

801034ca <pinit>:
{
801034ca:	55                   	push   %ebp
801034cb:	89 e5                	mov    %esp,%ebp
801034cd:	83 ec 10             	sub    $0x10,%esp
  initlock(&ptable.lock, "ptable");
801034d0:	68 95 6d 10 80       	push   $0x80106d95
801034d5:	68 60 2d 19 80       	push   $0x80192d60
801034da:	e8 e2 08 00 00       	call   80103dc1 <initlock>
}
801034df:	83 c4 10             	add    $0x10,%esp
801034e2:	c9                   	leave  
801034e3:	c3                   	ret    

801034e4 <mycpu>:
{
801034e4:	55                   	push   %ebp
801034e5:	89 e5                	mov    %esp,%ebp
801034e7:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801034ea:	9c                   	pushf  
801034eb:	58                   	pop    %eax
  if(readeflags()&FL_IF)
801034ec:	f6 c4 02             	test   $0x2,%ah
801034ef:	75 28                	jne    80103519 <mycpu+0x35>
  apicid = lapicid();
801034f1:	e8 da f1 ff ff       	call   801026d0 <lapicid>
  for (i = 0; i < ncpu; ++i) {
801034f6:	ba 00 00 00 00       	mov    $0x0,%edx
801034fb:	39 15 40 2d 19 80    	cmp    %edx,0x80192d40
80103501:	7e 23                	jle    80103526 <mycpu+0x42>
    if (cpus[i].apicid == apicid)
80103503:	69 ca b0 00 00 00    	imul   $0xb0,%edx,%ecx
80103509:	0f b6 89 c0 27 19 80 	movzbl -0x7fe6d840(%ecx),%ecx
80103510:	39 c1                	cmp    %eax,%ecx
80103512:	74 1f                	je     80103533 <mycpu+0x4f>
  for (i = 0; i < ncpu; ++i) {
80103514:	83 c2 01             	add    $0x1,%edx
80103517:	eb e2                	jmp    801034fb <mycpu+0x17>
    panic("mycpu called with interrupts enabled\n");
80103519:	83 ec 0c             	sub    $0xc,%esp
8010351c:	68 78 6e 10 80       	push   $0x80106e78
80103521:	e8 22 ce ff ff       	call   80100348 <panic>
  panic("unknown apicid\n");
80103526:	83 ec 0c             	sub    $0xc,%esp
80103529:	68 9c 6d 10 80       	push   $0x80106d9c
8010352e:	e8 15 ce ff ff       	call   80100348 <panic>
      return &cpus[i];
80103533:	69 c2 b0 00 00 00    	imul   $0xb0,%edx,%eax
80103539:	05 c0 27 19 80       	add    $0x801927c0,%eax
}
8010353e:	c9                   	leave  
8010353f:	c3                   	ret    

80103540 <cpuid>:
cpuid() {
80103540:	55                   	push   %ebp
80103541:	89 e5                	mov    %esp,%ebp
80103543:	83 ec 08             	sub    $0x8,%esp
  return mycpu()-cpus;
80103546:	e8 99 ff ff ff       	call   801034e4 <mycpu>
8010354b:	2d c0 27 19 80       	sub    $0x801927c0,%eax
80103550:	c1 f8 04             	sar    $0x4,%eax
80103553:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
80103559:	c9                   	leave  
8010355a:	c3                   	ret    

8010355b <myproc>:
myproc(void) {
8010355b:	55                   	push   %ebp
8010355c:	89 e5                	mov    %esp,%ebp
8010355e:	53                   	push   %ebx
8010355f:	83 ec 04             	sub    $0x4,%esp
  pushcli();
80103562:	e8 b9 08 00 00       	call   80103e20 <pushcli>
  c = mycpu();
80103567:	e8 78 ff ff ff       	call   801034e4 <mycpu>
  p = c->proc;
8010356c:	8b 98 ac 00 00 00    	mov    0xac(%eax),%ebx
  popcli();
80103572:	e8 e6 08 00 00       	call   80103e5d <popcli>
}
80103577:	89 d8                	mov    %ebx,%eax
80103579:	83 c4 04             	add    $0x4,%esp
8010357c:	5b                   	pop    %ebx
8010357d:	5d                   	pop    %ebp
8010357e:	c3                   	ret    

8010357f <userinit>:
{
8010357f:	55                   	push   %ebp
80103580:	89 e5                	mov    %esp,%ebp
80103582:	53                   	push   %ebx
80103583:	83 ec 04             	sub    $0x4,%esp
  p = allocproc();
80103586:	e8 35 fe ff ff       	call   801033c0 <allocproc>
8010358b:	89 c3                	mov    %eax,%ebx
  initproc = p;
8010358d:	a3 c0 a5 10 80       	mov    %eax,0x8010a5c0
  if((p->pgdir = setupkvm()) == 0)
80103592:	e8 2c 30 00 00       	call   801065c3 <setupkvm>
80103597:	89 43 04             	mov    %eax,0x4(%ebx)
8010359a:	85 c0                	test   %eax,%eax
8010359c:	0f 84 b7 00 00 00    	je     80103659 <userinit+0xda>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
801035a2:	83 ec 04             	sub    $0x4,%esp
801035a5:	68 2c 00 00 00       	push   $0x2c
801035aa:	68 60 a4 10 80       	push   $0x8010a460
801035af:	50                   	push   %eax
801035b0:	e8 0b 2d 00 00       	call   801062c0 <inituvm>
  p->sz = PGSIZE;
801035b5:	c7 03 00 10 00 00    	movl   $0x1000,(%ebx)
  memset(p->tf, 0, sizeof(*p->tf));
801035bb:	83 c4 0c             	add    $0xc,%esp
801035be:	6a 4c                	push   $0x4c
801035c0:	6a 00                	push   $0x0
801035c2:	ff 73 18             	pushl  0x18(%ebx)
801035c5:	e8 df 09 00 00       	call   80103fa9 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
801035ca:	8b 43 18             	mov    0x18(%ebx),%eax
801035cd:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
801035d3:	8b 43 18             	mov    0x18(%ebx),%eax
801035d6:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
  p->tf->es = p->tf->ds;
801035dc:	8b 43 18             	mov    0x18(%ebx),%eax
801035df:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801035e3:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
801035e7:	8b 43 18             	mov    0x18(%ebx),%eax
801035ea:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801035ee:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
801035f2:	8b 43 18             	mov    0x18(%ebx),%eax
801035f5:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801035fc:	8b 43 18             	mov    0x18(%ebx),%eax
801035ff:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80103606:	8b 43 18             	mov    0x18(%ebx),%eax
80103609:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
  safestrcpy(p->name, "initcode", sizeof(p->name));
80103610:	8d 43 6c             	lea    0x6c(%ebx),%eax
80103613:	83 c4 0c             	add    $0xc,%esp
80103616:	6a 10                	push   $0x10
80103618:	68 c5 6d 10 80       	push   $0x80106dc5
8010361d:	50                   	push   %eax
8010361e:	e8 ed 0a 00 00       	call   80104110 <safestrcpy>
  p->cwd = namei("/");
80103623:	c7 04 24 ce 6d 10 80 	movl   $0x80106dce,(%esp)
8010362a:	e8 be e5 ff ff       	call   80101bed <namei>
8010362f:	89 43 68             	mov    %eax,0x68(%ebx)
  acquire(&ptable.lock);
80103632:	c7 04 24 60 2d 19 80 	movl   $0x80192d60,(%esp)
80103639:	e8 bf 08 00 00       	call   80103efd <acquire>
  p->state = RUNNABLE;
8010363e:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  release(&ptable.lock);
80103645:	c7 04 24 60 2d 19 80 	movl   $0x80192d60,(%esp)
8010364c:	e8 11 09 00 00       	call   80103f62 <release>
}
80103651:	83 c4 10             	add    $0x10,%esp
80103654:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103657:	c9                   	leave  
80103658:	c3                   	ret    
    panic("userinit: out of memory?");
80103659:	83 ec 0c             	sub    $0xc,%esp
8010365c:	68 ac 6d 10 80       	push   $0x80106dac
80103661:	e8 e2 cc ff ff       	call   80100348 <panic>

80103666 <growproc>:
{
80103666:	55                   	push   %ebp
80103667:	89 e5                	mov    %esp,%ebp
80103669:	56                   	push   %esi
8010366a:	53                   	push   %ebx
8010366b:	8b 75 08             	mov    0x8(%ebp),%esi
  struct proc *curproc = myproc();
8010366e:	e8 e8 fe ff ff       	call   8010355b <myproc>
80103673:	89 c3                	mov    %eax,%ebx
  sz = curproc->sz;
80103675:	8b 00                	mov    (%eax),%eax
  if(n > 0){
80103677:	85 f6                	test   %esi,%esi
80103679:	7f 21                	jg     8010369c <growproc+0x36>
  } else if(n < 0){
8010367b:	85 f6                	test   %esi,%esi
8010367d:	79 33                	jns    801036b2 <growproc+0x4c>
    if((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
8010367f:	83 ec 04             	sub    $0x4,%esp
80103682:	01 c6                	add    %eax,%esi
80103684:	56                   	push   %esi
80103685:	50                   	push   %eax
80103686:	ff 73 04             	pushl  0x4(%ebx)
80103689:	e8 40 2d 00 00       	call   801063ce <deallocuvm>
8010368e:	83 c4 10             	add    $0x10,%esp
80103691:	85 c0                	test   %eax,%eax
80103693:	75 1d                	jne    801036b2 <growproc+0x4c>
      return -1;
80103695:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010369a:	eb 29                	jmp    801036c5 <growproc+0x5f>
    if((sz = allocuvm(curproc->pgdir, sz, sz + n, curproc->pid)) == 0)
8010369c:	ff 73 10             	pushl  0x10(%ebx)
8010369f:	01 c6                	add    %eax,%esi
801036a1:	56                   	push   %esi
801036a2:	50                   	push   %eax
801036a3:	ff 73 04             	pushl  0x4(%ebx)
801036a6:	e8 b5 2d 00 00       	call   80106460 <allocuvm>
801036ab:	83 c4 10             	add    $0x10,%esp
801036ae:	85 c0                	test   %eax,%eax
801036b0:	74 1a                	je     801036cc <growproc+0x66>
  curproc->sz = sz;
801036b2:	89 03                	mov    %eax,(%ebx)
  switchuvm(curproc);
801036b4:	83 ec 0c             	sub    $0xc,%esp
801036b7:	53                   	push   %ebx
801036b8:	e8 eb 2a 00 00       	call   801061a8 <switchuvm>
  return 0;
801036bd:	83 c4 10             	add    $0x10,%esp
801036c0:	b8 00 00 00 00       	mov    $0x0,%eax
}
801036c5:	8d 65 f8             	lea    -0x8(%ebp),%esp
801036c8:	5b                   	pop    %ebx
801036c9:	5e                   	pop    %esi
801036ca:	5d                   	pop    %ebp
801036cb:	c3                   	ret    
      return -1;
801036cc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801036d1:	eb f2                	jmp    801036c5 <growproc+0x5f>

801036d3 <fork>:
{
801036d3:	55                   	push   %ebp
801036d4:	89 e5                	mov    %esp,%ebp
801036d6:	57                   	push   %edi
801036d7:	56                   	push   %esi
801036d8:	53                   	push   %ebx
801036d9:	83 ec 1c             	sub    $0x1c,%esp
  struct proc *curproc = myproc();
801036dc:	e8 7a fe ff ff       	call   8010355b <myproc>
801036e1:	89 c3                	mov    %eax,%ebx
  if((np = allocproc()) == 0){
801036e3:	e8 d8 fc ff ff       	call   801033c0 <allocproc>
801036e8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801036eb:	85 c0                	test   %eax,%eax
801036ed:	0f 84 e3 00 00 00    	je     801037d6 <fork+0x103>
801036f3:	89 c7                	mov    %eax,%edi
  if((np->pgdir = copyuvm(curproc->pgdir, curproc->sz, np->pid)) == 0){
801036f5:	83 ec 04             	sub    $0x4,%esp
801036f8:	ff 70 10             	pushl  0x10(%eax)
801036fb:	ff 33                	pushl  (%ebx)
801036fd:	ff 73 04             	pushl  0x4(%ebx)
80103700:	e8 77 2f 00 00       	call   8010667c <copyuvm>
80103705:	89 47 04             	mov    %eax,0x4(%edi)
80103708:	83 c4 10             	add    $0x10,%esp
8010370b:	85 c0                	test   %eax,%eax
8010370d:	74 2a                	je     80103739 <fork+0x66>
  np->sz = curproc->sz;
8010370f:	8b 03                	mov    (%ebx),%eax
80103711:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80103714:	89 01                	mov    %eax,(%ecx)
  np->parent = curproc;
80103716:	89 c8                	mov    %ecx,%eax
80103718:	89 59 14             	mov    %ebx,0x14(%ecx)
  *np->tf = *curproc->tf;
8010371b:	8b 73 18             	mov    0x18(%ebx),%esi
8010371e:	8b 79 18             	mov    0x18(%ecx),%edi
80103721:	b9 13 00 00 00       	mov    $0x13,%ecx
80103726:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  np->tf->eax = 0;
80103728:	8b 40 18             	mov    0x18(%eax),%eax
8010372b:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
  for(i = 0; i < NOFILE; i++)
80103732:	be 00 00 00 00       	mov    $0x0,%esi
80103737:	eb 29                	jmp    80103762 <fork+0x8f>
    kfree(np->kstack);
80103739:	83 ec 0c             	sub    $0xc,%esp
8010373c:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
8010373f:	ff 73 08             	pushl  0x8(%ebx)
80103742:	e8 c0 e8 ff ff       	call   80102007 <kfree>
    np->kstack = 0;
80103747:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
    np->state = UNUSED;
8010374e:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return -1;
80103755:	83 c4 10             	add    $0x10,%esp
80103758:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
8010375d:	eb 6d                	jmp    801037cc <fork+0xf9>
  for(i = 0; i < NOFILE; i++)
8010375f:	83 c6 01             	add    $0x1,%esi
80103762:	83 fe 0f             	cmp    $0xf,%esi
80103765:	7f 1d                	jg     80103784 <fork+0xb1>
    if(curproc->ofile[i])
80103767:	8b 44 b3 28          	mov    0x28(%ebx,%esi,4),%eax
8010376b:	85 c0                	test   %eax,%eax
8010376d:	74 f0                	je     8010375f <fork+0x8c>
      np->ofile[i] = filedup(curproc->ofile[i]);
8010376f:	83 ec 0c             	sub    $0xc,%esp
80103772:	50                   	push   %eax
80103773:	e8 22 d5 ff ff       	call   80100c9a <filedup>
80103778:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010377b:	89 44 b2 28          	mov    %eax,0x28(%edx,%esi,4)
8010377f:	83 c4 10             	add    $0x10,%esp
80103782:	eb db                	jmp    8010375f <fork+0x8c>
  np->cwd = idup(curproc->cwd);
80103784:	83 ec 0c             	sub    $0xc,%esp
80103787:	ff 73 68             	pushl  0x68(%ebx)
8010378a:	e8 ce dd ff ff       	call   8010155d <idup>
8010378f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
80103792:	89 47 68             	mov    %eax,0x68(%edi)
  safestrcpy(np->name, curproc->name, sizeof(curproc->name));
80103795:	83 c3 6c             	add    $0x6c,%ebx
80103798:	8d 47 6c             	lea    0x6c(%edi),%eax
8010379b:	83 c4 0c             	add    $0xc,%esp
8010379e:	6a 10                	push   $0x10
801037a0:	53                   	push   %ebx
801037a1:	50                   	push   %eax
801037a2:	e8 69 09 00 00       	call   80104110 <safestrcpy>
  pid = np->pid;
801037a7:	8b 5f 10             	mov    0x10(%edi),%ebx
  acquire(&ptable.lock);
801037aa:	c7 04 24 60 2d 19 80 	movl   $0x80192d60,(%esp)
801037b1:	e8 47 07 00 00       	call   80103efd <acquire>
  np->state = RUNNABLE;
801037b6:	c7 47 0c 03 00 00 00 	movl   $0x3,0xc(%edi)
  release(&ptable.lock);
801037bd:	c7 04 24 60 2d 19 80 	movl   $0x80192d60,(%esp)
801037c4:	e8 99 07 00 00       	call   80103f62 <release>
  return pid;
801037c9:	83 c4 10             	add    $0x10,%esp
}
801037cc:	89 d8                	mov    %ebx,%eax
801037ce:	8d 65 f4             	lea    -0xc(%ebp),%esp
801037d1:	5b                   	pop    %ebx
801037d2:	5e                   	pop    %esi
801037d3:	5f                   	pop    %edi
801037d4:	5d                   	pop    %ebp
801037d5:	c3                   	ret    
    return -1;
801037d6:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801037db:	eb ef                	jmp    801037cc <fork+0xf9>

801037dd <scheduler>:
{
801037dd:	55                   	push   %ebp
801037de:	89 e5                	mov    %esp,%ebp
801037e0:	56                   	push   %esi
801037e1:	53                   	push   %ebx
  struct cpu *c = mycpu();
801037e2:	e8 fd fc ff ff       	call   801034e4 <mycpu>
801037e7:	89 c6                	mov    %eax,%esi
  c->proc = 0;
801037e9:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
801037f0:	00 00 00 
801037f3:	eb 5a                	jmp    8010384f <scheduler+0x72>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801037f5:	83 c3 7c             	add    $0x7c,%ebx
801037f8:	81 fb 94 4c 19 80    	cmp    $0x80194c94,%ebx
801037fe:	73 3f                	jae    8010383f <scheduler+0x62>
      if(p->state != RUNNABLE)
80103800:	83 7b 0c 03          	cmpl   $0x3,0xc(%ebx)
80103804:	75 ef                	jne    801037f5 <scheduler+0x18>
      c->proc = p;
80103806:	89 9e ac 00 00 00    	mov    %ebx,0xac(%esi)
      switchuvm(p);
8010380c:	83 ec 0c             	sub    $0xc,%esp
8010380f:	53                   	push   %ebx
80103810:	e8 93 29 00 00       	call   801061a8 <switchuvm>
      p->state = RUNNING;
80103815:	c7 43 0c 04 00 00 00 	movl   $0x4,0xc(%ebx)
      swtch(&(c->scheduler), p->context);
8010381c:	83 c4 08             	add    $0x8,%esp
8010381f:	ff 73 1c             	pushl  0x1c(%ebx)
80103822:	8d 46 04             	lea    0x4(%esi),%eax
80103825:	50                   	push   %eax
80103826:	e8 38 09 00 00       	call   80104163 <swtch>
      switchkvm();
8010382b:	e8 66 29 00 00       	call   80106196 <switchkvm>
      c->proc = 0;
80103830:	c7 86 ac 00 00 00 00 	movl   $0x0,0xac(%esi)
80103837:	00 00 00 
8010383a:	83 c4 10             	add    $0x10,%esp
8010383d:	eb b6                	jmp    801037f5 <scheduler+0x18>
    release(&ptable.lock);
8010383f:	83 ec 0c             	sub    $0xc,%esp
80103842:	68 60 2d 19 80       	push   $0x80192d60
80103847:	e8 16 07 00 00       	call   80103f62 <release>
    sti();
8010384c:	83 c4 10             	add    $0x10,%esp
  asm volatile("sti");
8010384f:	fb                   	sti    
    acquire(&ptable.lock);
80103850:	83 ec 0c             	sub    $0xc,%esp
80103853:	68 60 2d 19 80       	push   $0x80192d60
80103858:	e8 a0 06 00 00       	call   80103efd <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010385d:	83 c4 10             	add    $0x10,%esp
80103860:	bb 94 2d 19 80       	mov    $0x80192d94,%ebx
80103865:	eb 91                	jmp    801037f8 <scheduler+0x1b>

80103867 <sched>:
{
80103867:	55                   	push   %ebp
80103868:	89 e5                	mov    %esp,%ebp
8010386a:	56                   	push   %esi
8010386b:	53                   	push   %ebx
  struct proc *p = myproc();
8010386c:	e8 ea fc ff ff       	call   8010355b <myproc>
80103871:	89 c3                	mov    %eax,%ebx
  if(!holding(&ptable.lock))
80103873:	83 ec 0c             	sub    $0xc,%esp
80103876:	68 60 2d 19 80       	push   $0x80192d60
8010387b:	e8 3d 06 00 00       	call   80103ebd <holding>
80103880:	83 c4 10             	add    $0x10,%esp
80103883:	85 c0                	test   %eax,%eax
80103885:	74 4f                	je     801038d6 <sched+0x6f>
  if(mycpu()->ncli != 1)
80103887:	e8 58 fc ff ff       	call   801034e4 <mycpu>
8010388c:	83 b8 a4 00 00 00 01 	cmpl   $0x1,0xa4(%eax)
80103893:	75 4e                	jne    801038e3 <sched+0x7c>
  if(p->state == RUNNING)
80103895:	83 7b 0c 04          	cmpl   $0x4,0xc(%ebx)
80103899:	74 55                	je     801038f0 <sched+0x89>
  asm volatile("pushfl; popl %0" : "=r" (eflags));
8010389b:	9c                   	pushf  
8010389c:	58                   	pop    %eax
  if(readeflags()&FL_IF)
8010389d:	f6 c4 02             	test   $0x2,%ah
801038a0:	75 5b                	jne    801038fd <sched+0x96>
  intena = mycpu()->intena;
801038a2:	e8 3d fc ff ff       	call   801034e4 <mycpu>
801038a7:	8b b0 a8 00 00 00    	mov    0xa8(%eax),%esi
  swtch(&p->context, mycpu()->scheduler);
801038ad:	e8 32 fc ff ff       	call   801034e4 <mycpu>
801038b2:	83 ec 08             	sub    $0x8,%esp
801038b5:	ff 70 04             	pushl  0x4(%eax)
801038b8:	83 c3 1c             	add    $0x1c,%ebx
801038bb:	53                   	push   %ebx
801038bc:	e8 a2 08 00 00       	call   80104163 <swtch>
  mycpu()->intena = intena;
801038c1:	e8 1e fc ff ff       	call   801034e4 <mycpu>
801038c6:	89 b0 a8 00 00 00    	mov    %esi,0xa8(%eax)
}
801038cc:	83 c4 10             	add    $0x10,%esp
801038cf:	8d 65 f8             	lea    -0x8(%ebp),%esp
801038d2:	5b                   	pop    %ebx
801038d3:	5e                   	pop    %esi
801038d4:	5d                   	pop    %ebp
801038d5:	c3                   	ret    
    panic("sched ptable.lock");
801038d6:	83 ec 0c             	sub    $0xc,%esp
801038d9:	68 d0 6d 10 80       	push   $0x80106dd0
801038de:	e8 65 ca ff ff       	call   80100348 <panic>
    panic("sched locks");
801038e3:	83 ec 0c             	sub    $0xc,%esp
801038e6:	68 e2 6d 10 80       	push   $0x80106de2
801038eb:	e8 58 ca ff ff       	call   80100348 <panic>
    panic("sched running");
801038f0:	83 ec 0c             	sub    $0xc,%esp
801038f3:	68 ee 6d 10 80       	push   $0x80106dee
801038f8:	e8 4b ca ff ff       	call   80100348 <panic>
    panic("sched interruptible");
801038fd:	83 ec 0c             	sub    $0xc,%esp
80103900:	68 fc 6d 10 80       	push   $0x80106dfc
80103905:	e8 3e ca ff ff       	call   80100348 <panic>

8010390a <exit>:
{
8010390a:	55                   	push   %ebp
8010390b:	89 e5                	mov    %esp,%ebp
8010390d:	56                   	push   %esi
8010390e:	53                   	push   %ebx
  struct proc *curproc = myproc();
8010390f:	e8 47 fc ff ff       	call   8010355b <myproc>
  if(curproc == initproc)
80103914:	39 05 c0 a5 10 80    	cmp    %eax,0x8010a5c0
8010391a:	74 09                	je     80103925 <exit+0x1b>
8010391c:	89 c6                	mov    %eax,%esi
  for(fd = 0; fd < NOFILE; fd++){
8010391e:	bb 00 00 00 00       	mov    $0x0,%ebx
80103923:	eb 10                	jmp    80103935 <exit+0x2b>
    panic("init exiting");
80103925:	83 ec 0c             	sub    $0xc,%esp
80103928:	68 10 6e 10 80       	push   $0x80106e10
8010392d:	e8 16 ca ff ff       	call   80100348 <panic>
  for(fd = 0; fd < NOFILE; fd++){
80103932:	83 c3 01             	add    $0x1,%ebx
80103935:	83 fb 0f             	cmp    $0xf,%ebx
80103938:	7f 1e                	jg     80103958 <exit+0x4e>
    if(curproc->ofile[fd]){
8010393a:	8b 44 9e 28          	mov    0x28(%esi,%ebx,4),%eax
8010393e:	85 c0                	test   %eax,%eax
80103940:	74 f0                	je     80103932 <exit+0x28>
      fileclose(curproc->ofile[fd]);
80103942:	83 ec 0c             	sub    $0xc,%esp
80103945:	50                   	push   %eax
80103946:	e8 94 d3 ff ff       	call   80100cdf <fileclose>
      curproc->ofile[fd] = 0;
8010394b:	c7 44 9e 28 00 00 00 	movl   $0x0,0x28(%esi,%ebx,4)
80103952:	00 
80103953:	83 c4 10             	add    $0x10,%esp
80103956:	eb da                	jmp    80103932 <exit+0x28>
  begin_op();
80103958:	e8 a3 f1 ff ff       	call   80102b00 <begin_op>
  iput(curproc->cwd);
8010395d:	83 ec 0c             	sub    $0xc,%esp
80103960:	ff 76 68             	pushl  0x68(%esi)
80103963:	e8 2c dd ff ff       	call   80101694 <iput>
  end_op();
80103968:	e8 0d f2 ff ff       	call   80102b7a <end_op>
  curproc->cwd = 0;
8010396d:	c7 46 68 00 00 00 00 	movl   $0x0,0x68(%esi)
  acquire(&ptable.lock);
80103974:	c7 04 24 60 2d 19 80 	movl   $0x80192d60,(%esp)
8010397b:	e8 7d 05 00 00       	call   80103efd <acquire>
  wakeup1(curproc->parent);
80103980:	8b 46 14             	mov    0x14(%esi),%eax
80103983:	e8 0d fa ff ff       	call   80103395 <wakeup1>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103988:	83 c4 10             	add    $0x10,%esp
8010398b:	bb 94 2d 19 80       	mov    $0x80192d94,%ebx
80103990:	eb 03                	jmp    80103995 <exit+0x8b>
80103992:	83 c3 7c             	add    $0x7c,%ebx
80103995:	81 fb 94 4c 19 80    	cmp    $0x80194c94,%ebx
8010399b:	73 1a                	jae    801039b7 <exit+0xad>
    if(p->parent == curproc){
8010399d:	39 73 14             	cmp    %esi,0x14(%ebx)
801039a0:	75 f0                	jne    80103992 <exit+0x88>
      p->parent = initproc;
801039a2:	a1 c0 a5 10 80       	mov    0x8010a5c0,%eax
801039a7:	89 43 14             	mov    %eax,0x14(%ebx)
      if(p->state == ZOMBIE)
801039aa:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
801039ae:	75 e2                	jne    80103992 <exit+0x88>
        wakeup1(initproc);
801039b0:	e8 e0 f9 ff ff       	call   80103395 <wakeup1>
801039b5:	eb db                	jmp    80103992 <exit+0x88>
  curproc->state = ZOMBIE;
801039b7:	c7 46 0c 05 00 00 00 	movl   $0x5,0xc(%esi)
  sched();
801039be:	e8 a4 fe ff ff       	call   80103867 <sched>
  panic("zombie exit");
801039c3:	83 ec 0c             	sub    $0xc,%esp
801039c6:	68 1d 6e 10 80       	push   $0x80106e1d
801039cb:	e8 78 c9 ff ff       	call   80100348 <panic>

801039d0 <yield>:
{
801039d0:	55                   	push   %ebp
801039d1:	89 e5                	mov    %esp,%ebp
801039d3:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
801039d6:	68 60 2d 19 80       	push   $0x80192d60
801039db:	e8 1d 05 00 00       	call   80103efd <acquire>
  myproc()->state = RUNNABLE;
801039e0:	e8 76 fb ff ff       	call   8010355b <myproc>
801039e5:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
801039ec:	e8 76 fe ff ff       	call   80103867 <sched>
  release(&ptable.lock);
801039f1:	c7 04 24 60 2d 19 80 	movl   $0x80192d60,(%esp)
801039f8:	e8 65 05 00 00       	call   80103f62 <release>
}
801039fd:	83 c4 10             	add    $0x10,%esp
80103a00:	c9                   	leave  
80103a01:	c3                   	ret    

80103a02 <sleep>:
{
80103a02:	55                   	push   %ebp
80103a03:	89 e5                	mov    %esp,%ebp
80103a05:	56                   	push   %esi
80103a06:	53                   	push   %ebx
80103a07:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  struct proc *p = myproc();
80103a0a:	e8 4c fb ff ff       	call   8010355b <myproc>
  if(p == 0)
80103a0f:	85 c0                	test   %eax,%eax
80103a11:	74 66                	je     80103a79 <sleep+0x77>
80103a13:	89 c6                	mov    %eax,%esi
  if(lk == 0)
80103a15:	85 db                	test   %ebx,%ebx
80103a17:	74 6d                	je     80103a86 <sleep+0x84>
  if(lk != &ptable.lock){  //DOC: sleeplock0
80103a19:	81 fb 60 2d 19 80    	cmp    $0x80192d60,%ebx
80103a1f:	74 18                	je     80103a39 <sleep+0x37>
    acquire(&ptable.lock);  //DOC: sleeplock1
80103a21:	83 ec 0c             	sub    $0xc,%esp
80103a24:	68 60 2d 19 80       	push   $0x80192d60
80103a29:	e8 cf 04 00 00       	call   80103efd <acquire>
    release(lk);
80103a2e:	89 1c 24             	mov    %ebx,(%esp)
80103a31:	e8 2c 05 00 00       	call   80103f62 <release>
80103a36:	83 c4 10             	add    $0x10,%esp
  p->chan = chan;
80103a39:	8b 45 08             	mov    0x8(%ebp),%eax
80103a3c:	89 46 20             	mov    %eax,0x20(%esi)
  p->state = SLEEPING;
80103a3f:	c7 46 0c 02 00 00 00 	movl   $0x2,0xc(%esi)
  sched();
80103a46:	e8 1c fe ff ff       	call   80103867 <sched>
  p->chan = 0;
80103a4b:	c7 46 20 00 00 00 00 	movl   $0x0,0x20(%esi)
  if(lk != &ptable.lock){  //DOC: sleeplock2
80103a52:	81 fb 60 2d 19 80    	cmp    $0x80192d60,%ebx
80103a58:	74 18                	je     80103a72 <sleep+0x70>
    release(&ptable.lock);
80103a5a:	83 ec 0c             	sub    $0xc,%esp
80103a5d:	68 60 2d 19 80       	push   $0x80192d60
80103a62:	e8 fb 04 00 00       	call   80103f62 <release>
    acquire(lk);
80103a67:	89 1c 24             	mov    %ebx,(%esp)
80103a6a:	e8 8e 04 00 00       	call   80103efd <acquire>
80103a6f:	83 c4 10             	add    $0x10,%esp
}
80103a72:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103a75:	5b                   	pop    %ebx
80103a76:	5e                   	pop    %esi
80103a77:	5d                   	pop    %ebp
80103a78:	c3                   	ret    
    panic("sleep");
80103a79:	83 ec 0c             	sub    $0xc,%esp
80103a7c:	68 29 6e 10 80       	push   $0x80106e29
80103a81:	e8 c2 c8 ff ff       	call   80100348 <panic>
    panic("sleep without lk");
80103a86:	83 ec 0c             	sub    $0xc,%esp
80103a89:	68 2f 6e 10 80       	push   $0x80106e2f
80103a8e:	e8 b5 c8 ff ff       	call   80100348 <panic>

80103a93 <wait>:
{
80103a93:	55                   	push   %ebp
80103a94:	89 e5                	mov    %esp,%ebp
80103a96:	56                   	push   %esi
80103a97:	53                   	push   %ebx
  struct proc *curproc = myproc();
80103a98:	e8 be fa ff ff       	call   8010355b <myproc>
80103a9d:	89 c6                	mov    %eax,%esi
  acquire(&ptable.lock);
80103a9f:	83 ec 0c             	sub    $0xc,%esp
80103aa2:	68 60 2d 19 80       	push   $0x80192d60
80103aa7:	e8 51 04 00 00       	call   80103efd <acquire>
80103aac:	83 c4 10             	add    $0x10,%esp
    havekids = 0;
80103aaf:	b8 00 00 00 00       	mov    $0x0,%eax
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103ab4:	bb 94 2d 19 80       	mov    $0x80192d94,%ebx
80103ab9:	eb 5b                	jmp    80103b16 <wait+0x83>
        pid = p->pid;
80103abb:	8b 73 10             	mov    0x10(%ebx),%esi
        kfree(p->kstack);
80103abe:	83 ec 0c             	sub    $0xc,%esp
80103ac1:	ff 73 08             	pushl  0x8(%ebx)
80103ac4:	e8 3e e5 ff ff       	call   80102007 <kfree>
        p->kstack = 0;
80103ac9:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        freevm(p->pgdir);
80103ad0:	83 c4 04             	add    $0x4,%esp
80103ad3:	ff 73 04             	pushl  0x4(%ebx)
80103ad6:	e8 78 2a 00 00       	call   80106553 <freevm>
        p->pid = 0;
80103adb:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
        p->parent = 0;
80103ae2:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
        p->name[0] = 0;
80103ae9:	c6 43 6c 00          	movb   $0x0,0x6c(%ebx)
        p->killed = 0;
80103aed:	c7 43 24 00 00 00 00 	movl   $0x0,0x24(%ebx)
        p->state = UNUSED;
80103af4:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        release(&ptable.lock);
80103afb:	c7 04 24 60 2d 19 80 	movl   $0x80192d60,(%esp)
80103b02:	e8 5b 04 00 00       	call   80103f62 <release>
        return pid;
80103b07:	83 c4 10             	add    $0x10,%esp
}
80103b0a:	89 f0                	mov    %esi,%eax
80103b0c:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103b0f:	5b                   	pop    %ebx
80103b10:	5e                   	pop    %esi
80103b11:	5d                   	pop    %ebp
80103b12:	c3                   	ret    
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103b13:	83 c3 7c             	add    $0x7c,%ebx
80103b16:	81 fb 94 4c 19 80    	cmp    $0x80194c94,%ebx
80103b1c:	73 12                	jae    80103b30 <wait+0x9d>
      if(p->parent != curproc)
80103b1e:	39 73 14             	cmp    %esi,0x14(%ebx)
80103b21:	75 f0                	jne    80103b13 <wait+0x80>
      if(p->state == ZOMBIE){
80103b23:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
80103b27:	74 92                	je     80103abb <wait+0x28>
      havekids = 1;
80103b29:	b8 01 00 00 00       	mov    $0x1,%eax
80103b2e:	eb e3                	jmp    80103b13 <wait+0x80>
    if(!havekids || curproc->killed){
80103b30:	85 c0                	test   %eax,%eax
80103b32:	74 06                	je     80103b3a <wait+0xa7>
80103b34:	83 7e 24 00          	cmpl   $0x0,0x24(%esi)
80103b38:	74 17                	je     80103b51 <wait+0xbe>
      release(&ptable.lock);
80103b3a:	83 ec 0c             	sub    $0xc,%esp
80103b3d:	68 60 2d 19 80       	push   $0x80192d60
80103b42:	e8 1b 04 00 00       	call   80103f62 <release>
      return -1;
80103b47:	83 c4 10             	add    $0x10,%esp
80103b4a:	be ff ff ff ff       	mov    $0xffffffff,%esi
80103b4f:	eb b9                	jmp    80103b0a <wait+0x77>
    sleep(curproc, &ptable.lock);  //DOC: wait-sleep
80103b51:	83 ec 08             	sub    $0x8,%esp
80103b54:	68 60 2d 19 80       	push   $0x80192d60
80103b59:	56                   	push   %esi
80103b5a:	e8 a3 fe ff ff       	call   80103a02 <sleep>
    havekids = 0;
80103b5f:	83 c4 10             	add    $0x10,%esp
80103b62:	e9 48 ff ff ff       	jmp    80103aaf <wait+0x1c>

80103b67 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80103b67:	55                   	push   %ebp
80103b68:	89 e5                	mov    %esp,%ebp
80103b6a:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);
80103b6d:	68 60 2d 19 80       	push   $0x80192d60
80103b72:	e8 86 03 00 00       	call   80103efd <acquire>
  wakeup1(chan);
80103b77:	8b 45 08             	mov    0x8(%ebp),%eax
80103b7a:	e8 16 f8 ff ff       	call   80103395 <wakeup1>
  release(&ptable.lock);
80103b7f:	c7 04 24 60 2d 19 80 	movl   $0x80192d60,(%esp)
80103b86:	e8 d7 03 00 00       	call   80103f62 <release>
}
80103b8b:	83 c4 10             	add    $0x10,%esp
80103b8e:	c9                   	leave  
80103b8f:	c3                   	ret    

80103b90 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80103b90:	55                   	push   %ebp
80103b91:	89 e5                	mov    %esp,%ebp
80103b93:	53                   	push   %ebx
80103b94:	83 ec 10             	sub    $0x10,%esp
80103b97:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *p;

  acquire(&ptable.lock);
80103b9a:	68 60 2d 19 80       	push   $0x80192d60
80103b9f:	e8 59 03 00 00       	call   80103efd <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103ba4:	83 c4 10             	add    $0x10,%esp
80103ba7:	b8 94 2d 19 80       	mov    $0x80192d94,%eax
80103bac:	3d 94 4c 19 80       	cmp    $0x80194c94,%eax
80103bb1:	73 3a                	jae    80103bed <kill+0x5d>
    if(p->pid == pid){
80103bb3:	39 58 10             	cmp    %ebx,0x10(%eax)
80103bb6:	74 05                	je     80103bbd <kill+0x2d>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103bb8:	83 c0 7c             	add    $0x7c,%eax
80103bbb:	eb ef                	jmp    80103bac <kill+0x1c>
      p->killed = 1;
80103bbd:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80103bc4:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
80103bc8:	74 1a                	je     80103be4 <kill+0x54>
        p->state = RUNNABLE;
      release(&ptable.lock);
80103bca:	83 ec 0c             	sub    $0xc,%esp
80103bcd:	68 60 2d 19 80       	push   $0x80192d60
80103bd2:	e8 8b 03 00 00       	call   80103f62 <release>
      return 0;
80103bd7:	83 c4 10             	add    $0x10,%esp
80103bda:	b8 00 00 00 00       	mov    $0x0,%eax
    }
  }
  release(&ptable.lock);
  return -1;
}
80103bdf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103be2:	c9                   	leave  
80103be3:	c3                   	ret    
        p->state = RUNNABLE;
80103be4:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
80103beb:	eb dd                	jmp    80103bca <kill+0x3a>
  release(&ptable.lock);
80103bed:	83 ec 0c             	sub    $0xc,%esp
80103bf0:	68 60 2d 19 80       	push   $0x80192d60
80103bf5:	e8 68 03 00 00       	call   80103f62 <release>
  return -1;
80103bfa:	83 c4 10             	add    $0x10,%esp
80103bfd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103c02:	eb db                	jmp    80103bdf <kill+0x4f>

80103c04 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80103c04:	55                   	push   %ebp
80103c05:	89 e5                	mov    %esp,%ebp
80103c07:	56                   	push   %esi
80103c08:	53                   	push   %ebx
80103c09:	83 ec 30             	sub    $0x30,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103c0c:	bb 94 2d 19 80       	mov    $0x80192d94,%ebx
80103c11:	eb 33                	jmp    80103c46 <procdump+0x42>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
80103c13:	b8 40 6e 10 80       	mov    $0x80106e40,%eax
    cprintf("%d %s %s", p->pid, state, p->name);
80103c18:	8d 53 6c             	lea    0x6c(%ebx),%edx
80103c1b:	52                   	push   %edx
80103c1c:	50                   	push   %eax
80103c1d:	ff 73 10             	pushl  0x10(%ebx)
80103c20:	68 44 6e 10 80       	push   $0x80106e44
80103c25:	e8 e1 c9 ff ff       	call   8010060b <cprintf>
    if(p->state == SLEEPING){
80103c2a:	83 c4 10             	add    $0x10,%esp
80103c2d:	83 7b 0c 02          	cmpl   $0x2,0xc(%ebx)
80103c31:	74 39                	je     80103c6c <procdump+0x68>
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80103c33:	83 ec 0c             	sub    $0xc,%esp
80103c36:	68 bb 71 10 80       	push   $0x801071bb
80103c3b:	e8 cb c9 ff ff       	call   8010060b <cprintf>
80103c40:	83 c4 10             	add    $0x10,%esp
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103c43:	83 c3 7c             	add    $0x7c,%ebx
80103c46:	81 fb 94 4c 19 80    	cmp    $0x80194c94,%ebx
80103c4c:	73 61                	jae    80103caf <procdump+0xab>
    if(p->state == UNUSED)
80103c4e:	8b 43 0c             	mov    0xc(%ebx),%eax
80103c51:	85 c0                	test   %eax,%eax
80103c53:	74 ee                	je     80103c43 <procdump+0x3f>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80103c55:	83 f8 05             	cmp    $0x5,%eax
80103c58:	77 b9                	ja     80103c13 <procdump+0xf>
80103c5a:	8b 04 85 a0 6e 10 80 	mov    -0x7fef9160(,%eax,4),%eax
80103c61:	85 c0                	test   %eax,%eax
80103c63:	75 b3                	jne    80103c18 <procdump+0x14>
      state = "???";
80103c65:	b8 40 6e 10 80       	mov    $0x80106e40,%eax
80103c6a:	eb ac                	jmp    80103c18 <procdump+0x14>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80103c6c:	8b 43 1c             	mov    0x1c(%ebx),%eax
80103c6f:	8b 40 0c             	mov    0xc(%eax),%eax
80103c72:	83 c0 08             	add    $0x8,%eax
80103c75:	83 ec 08             	sub    $0x8,%esp
80103c78:	8d 55 d0             	lea    -0x30(%ebp),%edx
80103c7b:	52                   	push   %edx
80103c7c:	50                   	push   %eax
80103c7d:	e8 5a 01 00 00       	call   80103ddc <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80103c82:	83 c4 10             	add    $0x10,%esp
80103c85:	be 00 00 00 00       	mov    $0x0,%esi
80103c8a:	eb 14                	jmp    80103ca0 <procdump+0x9c>
        cprintf(" %p", pc[i]);
80103c8c:	83 ec 08             	sub    $0x8,%esp
80103c8f:	50                   	push   %eax
80103c90:	68 81 68 10 80       	push   $0x80106881
80103c95:	e8 71 c9 ff ff       	call   8010060b <cprintf>
      for(i=0; i<10 && pc[i] != 0; i++)
80103c9a:	83 c6 01             	add    $0x1,%esi
80103c9d:	83 c4 10             	add    $0x10,%esp
80103ca0:	83 fe 09             	cmp    $0x9,%esi
80103ca3:	7f 8e                	jg     80103c33 <procdump+0x2f>
80103ca5:	8b 44 b5 d0          	mov    -0x30(%ebp,%esi,4),%eax
80103ca9:	85 c0                	test   %eax,%eax
80103cab:	75 df                	jne    80103c8c <procdump+0x88>
80103cad:	eb 84                	jmp    80103c33 <procdump+0x2f>
  }
}
80103caf:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103cb2:	5b                   	pop    %ebx
80103cb3:	5e                   	pop    %esi
80103cb4:	5d                   	pop    %ebp
80103cb5:	c3                   	ret    

80103cb6 <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
80103cb6:	55                   	push   %ebp
80103cb7:	89 e5                	mov    %esp,%ebp
80103cb9:	53                   	push   %ebx
80103cba:	83 ec 0c             	sub    $0xc,%esp
80103cbd:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&lk->lk, "sleep lock");
80103cc0:	68 b8 6e 10 80       	push   $0x80106eb8
80103cc5:	8d 43 04             	lea    0x4(%ebx),%eax
80103cc8:	50                   	push   %eax
80103cc9:	e8 f3 00 00 00       	call   80103dc1 <initlock>
  lk->name = name;
80103cce:	8b 45 0c             	mov    0xc(%ebp),%eax
80103cd1:	89 43 38             	mov    %eax,0x38(%ebx)
  lk->locked = 0;
80103cd4:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103cda:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
}
80103ce1:	83 c4 10             	add    $0x10,%esp
80103ce4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103ce7:	c9                   	leave  
80103ce8:	c3                   	ret    

80103ce9 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80103ce9:	55                   	push   %ebp
80103cea:	89 e5                	mov    %esp,%ebp
80103cec:	56                   	push   %esi
80103ced:	53                   	push   %ebx
80103cee:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103cf1:	8d 73 04             	lea    0x4(%ebx),%esi
80103cf4:	83 ec 0c             	sub    $0xc,%esp
80103cf7:	56                   	push   %esi
80103cf8:	e8 00 02 00 00       	call   80103efd <acquire>
  while (lk->locked) {
80103cfd:	83 c4 10             	add    $0x10,%esp
80103d00:	eb 0d                	jmp    80103d0f <acquiresleep+0x26>
    sleep(lk, &lk->lk);
80103d02:	83 ec 08             	sub    $0x8,%esp
80103d05:	56                   	push   %esi
80103d06:	53                   	push   %ebx
80103d07:	e8 f6 fc ff ff       	call   80103a02 <sleep>
80103d0c:	83 c4 10             	add    $0x10,%esp
  while (lk->locked) {
80103d0f:	83 3b 00             	cmpl   $0x0,(%ebx)
80103d12:	75 ee                	jne    80103d02 <acquiresleep+0x19>
  }
  lk->locked = 1;
80103d14:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
  lk->pid = myproc()->pid;
80103d1a:	e8 3c f8 ff ff       	call   8010355b <myproc>
80103d1f:	8b 40 10             	mov    0x10(%eax),%eax
80103d22:	89 43 3c             	mov    %eax,0x3c(%ebx)
  release(&lk->lk);
80103d25:	83 ec 0c             	sub    $0xc,%esp
80103d28:	56                   	push   %esi
80103d29:	e8 34 02 00 00       	call   80103f62 <release>
}
80103d2e:	83 c4 10             	add    $0x10,%esp
80103d31:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103d34:	5b                   	pop    %ebx
80103d35:	5e                   	pop    %esi
80103d36:	5d                   	pop    %ebp
80103d37:	c3                   	ret    

80103d38 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80103d38:	55                   	push   %ebp
80103d39:	89 e5                	mov    %esp,%ebp
80103d3b:	56                   	push   %esi
80103d3c:	53                   	push   %ebx
80103d3d:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103d40:	8d 73 04             	lea    0x4(%ebx),%esi
80103d43:	83 ec 0c             	sub    $0xc,%esp
80103d46:	56                   	push   %esi
80103d47:	e8 b1 01 00 00       	call   80103efd <acquire>
  lk->locked = 0;
80103d4c:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103d52:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
  wakeup(lk);
80103d59:	89 1c 24             	mov    %ebx,(%esp)
80103d5c:	e8 06 fe ff ff       	call   80103b67 <wakeup>
  release(&lk->lk);
80103d61:	89 34 24             	mov    %esi,(%esp)
80103d64:	e8 f9 01 00 00       	call   80103f62 <release>
}
80103d69:	83 c4 10             	add    $0x10,%esp
80103d6c:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103d6f:	5b                   	pop    %ebx
80103d70:	5e                   	pop    %esi
80103d71:	5d                   	pop    %ebp
80103d72:	c3                   	ret    

80103d73 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80103d73:	55                   	push   %ebp
80103d74:	89 e5                	mov    %esp,%ebp
80103d76:	56                   	push   %esi
80103d77:	53                   	push   %ebx
80103d78:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;
  
  acquire(&lk->lk);
80103d7b:	8d 73 04             	lea    0x4(%ebx),%esi
80103d7e:	83 ec 0c             	sub    $0xc,%esp
80103d81:	56                   	push   %esi
80103d82:	e8 76 01 00 00       	call   80103efd <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
80103d87:	83 c4 10             	add    $0x10,%esp
80103d8a:	83 3b 00             	cmpl   $0x0,(%ebx)
80103d8d:	75 17                	jne    80103da6 <holdingsleep+0x33>
80103d8f:	bb 00 00 00 00       	mov    $0x0,%ebx
  release(&lk->lk);
80103d94:	83 ec 0c             	sub    $0xc,%esp
80103d97:	56                   	push   %esi
80103d98:	e8 c5 01 00 00       	call   80103f62 <release>
  return r;
}
80103d9d:	89 d8                	mov    %ebx,%eax
80103d9f:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103da2:	5b                   	pop    %ebx
80103da3:	5e                   	pop    %esi
80103da4:	5d                   	pop    %ebp
80103da5:	c3                   	ret    
  r = lk->locked && (lk->pid == myproc()->pid);
80103da6:	8b 5b 3c             	mov    0x3c(%ebx),%ebx
80103da9:	e8 ad f7 ff ff       	call   8010355b <myproc>
80103dae:	3b 58 10             	cmp    0x10(%eax),%ebx
80103db1:	74 07                	je     80103dba <holdingsleep+0x47>
80103db3:	bb 00 00 00 00       	mov    $0x0,%ebx
80103db8:	eb da                	jmp    80103d94 <holdingsleep+0x21>
80103dba:	bb 01 00 00 00       	mov    $0x1,%ebx
80103dbf:	eb d3                	jmp    80103d94 <holdingsleep+0x21>

80103dc1 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80103dc1:	55                   	push   %ebp
80103dc2:	89 e5                	mov    %esp,%ebp
80103dc4:	8b 45 08             	mov    0x8(%ebp),%eax
  lk->name = name;
80103dc7:	8b 55 0c             	mov    0xc(%ebp),%edx
80103dca:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80103dcd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80103dd3:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80103dda:	5d                   	pop    %ebp
80103ddb:	c3                   	ret    

80103ddc <getcallerpcs>:
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80103ddc:	55                   	push   %ebp
80103ddd:	89 e5                	mov    %esp,%ebp
80103ddf:	53                   	push   %ebx
80103de0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80103de3:	8b 45 08             	mov    0x8(%ebp),%eax
80103de6:	8d 50 f8             	lea    -0x8(%eax),%edx
  for(i = 0; i < 10; i++){
80103de9:	b8 00 00 00 00       	mov    $0x0,%eax
80103dee:	83 f8 09             	cmp    $0x9,%eax
80103df1:	7f 25                	jg     80103e18 <getcallerpcs+0x3c>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80103df3:	8d 9a 00 00 00 80    	lea    -0x80000000(%edx),%ebx
80103df9:	81 fb fe ff ff 7f    	cmp    $0x7ffffffe,%ebx
80103dff:	77 17                	ja     80103e18 <getcallerpcs+0x3c>
      break;
    pcs[i] = ebp[1];     // saved %eip
80103e01:	8b 5a 04             	mov    0x4(%edx),%ebx
80103e04:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
    ebp = (uint*)ebp[0]; // saved %ebp
80103e07:	8b 12                	mov    (%edx),%edx
  for(i = 0; i < 10; i++){
80103e09:	83 c0 01             	add    $0x1,%eax
80103e0c:	eb e0                	jmp    80103dee <getcallerpcs+0x12>
  }
  for(; i < 10; i++)
    pcs[i] = 0;
80103e0e:	c7 04 81 00 00 00 00 	movl   $0x0,(%ecx,%eax,4)
  for(; i < 10; i++)
80103e15:	83 c0 01             	add    $0x1,%eax
80103e18:	83 f8 09             	cmp    $0x9,%eax
80103e1b:	7e f1                	jle    80103e0e <getcallerpcs+0x32>
}
80103e1d:	5b                   	pop    %ebx
80103e1e:	5d                   	pop    %ebp
80103e1f:	c3                   	ret    

80103e20 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80103e20:	55                   	push   %ebp
80103e21:	89 e5                	mov    %esp,%ebp
80103e23:	53                   	push   %ebx
80103e24:	83 ec 04             	sub    $0x4,%esp
80103e27:	9c                   	pushf  
80103e28:	5b                   	pop    %ebx
  asm volatile("cli");
80103e29:	fa                   	cli    
  int eflags;

  eflags = readeflags();
  cli();
  if(mycpu()->ncli == 0)
80103e2a:	e8 b5 f6 ff ff       	call   801034e4 <mycpu>
80103e2f:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103e36:	74 12                	je     80103e4a <pushcli+0x2a>
    mycpu()->intena = eflags & FL_IF;
  mycpu()->ncli += 1;
80103e38:	e8 a7 f6 ff ff       	call   801034e4 <mycpu>
80103e3d:	83 80 a4 00 00 00 01 	addl   $0x1,0xa4(%eax)
}
80103e44:	83 c4 04             	add    $0x4,%esp
80103e47:	5b                   	pop    %ebx
80103e48:	5d                   	pop    %ebp
80103e49:	c3                   	ret    
    mycpu()->intena = eflags & FL_IF;
80103e4a:	e8 95 f6 ff ff       	call   801034e4 <mycpu>
80103e4f:	81 e3 00 02 00 00    	and    $0x200,%ebx
80103e55:	89 98 a8 00 00 00    	mov    %ebx,0xa8(%eax)
80103e5b:	eb db                	jmp    80103e38 <pushcli+0x18>

80103e5d <popcli>:

void
popcli(void)
{
80103e5d:	55                   	push   %ebp
80103e5e:	89 e5                	mov    %esp,%ebp
80103e60:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103e63:	9c                   	pushf  
80103e64:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103e65:	f6 c4 02             	test   $0x2,%ah
80103e68:	75 28                	jne    80103e92 <popcli+0x35>
    panic("popcli - interruptible");
  if(--mycpu()->ncli < 0)
80103e6a:	e8 75 f6 ff ff       	call   801034e4 <mycpu>
80103e6f:	8b 88 a4 00 00 00    	mov    0xa4(%eax),%ecx
80103e75:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103e78:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
80103e7e:	85 d2                	test   %edx,%edx
80103e80:	78 1d                	js     80103e9f <popcli+0x42>
    panic("popcli");
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103e82:	e8 5d f6 ff ff       	call   801034e4 <mycpu>
80103e87:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103e8e:	74 1c                	je     80103eac <popcli+0x4f>
    sti();
}
80103e90:	c9                   	leave  
80103e91:	c3                   	ret    
    panic("popcli - interruptible");
80103e92:	83 ec 0c             	sub    $0xc,%esp
80103e95:	68 c3 6e 10 80       	push   $0x80106ec3
80103e9a:	e8 a9 c4 ff ff       	call   80100348 <panic>
    panic("popcli");
80103e9f:	83 ec 0c             	sub    $0xc,%esp
80103ea2:	68 da 6e 10 80       	push   $0x80106eda
80103ea7:	e8 9c c4 ff ff       	call   80100348 <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103eac:	e8 33 f6 ff ff       	call   801034e4 <mycpu>
80103eb1:	83 b8 a8 00 00 00 00 	cmpl   $0x0,0xa8(%eax)
80103eb8:	74 d6                	je     80103e90 <popcli+0x33>
  asm volatile("sti");
80103eba:	fb                   	sti    
}
80103ebb:	eb d3                	jmp    80103e90 <popcli+0x33>

80103ebd <holding>:
{
80103ebd:	55                   	push   %ebp
80103ebe:	89 e5                	mov    %esp,%ebp
80103ec0:	53                   	push   %ebx
80103ec1:	83 ec 04             	sub    $0x4,%esp
80103ec4:	8b 5d 08             	mov    0x8(%ebp),%ebx
  pushcli();
80103ec7:	e8 54 ff ff ff       	call   80103e20 <pushcli>
  r = lock->locked && lock->cpu == mycpu();
80103ecc:	83 3b 00             	cmpl   $0x0,(%ebx)
80103ecf:	75 12                	jne    80103ee3 <holding+0x26>
80103ed1:	bb 00 00 00 00       	mov    $0x0,%ebx
  popcli();
80103ed6:	e8 82 ff ff ff       	call   80103e5d <popcli>
}
80103edb:	89 d8                	mov    %ebx,%eax
80103edd:	83 c4 04             	add    $0x4,%esp
80103ee0:	5b                   	pop    %ebx
80103ee1:	5d                   	pop    %ebp
80103ee2:	c3                   	ret    
  r = lock->locked && lock->cpu == mycpu();
80103ee3:	8b 5b 08             	mov    0x8(%ebx),%ebx
80103ee6:	e8 f9 f5 ff ff       	call   801034e4 <mycpu>
80103eeb:	39 c3                	cmp    %eax,%ebx
80103eed:	74 07                	je     80103ef6 <holding+0x39>
80103eef:	bb 00 00 00 00       	mov    $0x0,%ebx
80103ef4:	eb e0                	jmp    80103ed6 <holding+0x19>
80103ef6:	bb 01 00 00 00       	mov    $0x1,%ebx
80103efb:	eb d9                	jmp    80103ed6 <holding+0x19>

80103efd <acquire>:
{
80103efd:	55                   	push   %ebp
80103efe:	89 e5                	mov    %esp,%ebp
80103f00:	53                   	push   %ebx
80103f01:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80103f04:	e8 17 ff ff ff       	call   80103e20 <pushcli>
  if(holding(lk))
80103f09:	83 ec 0c             	sub    $0xc,%esp
80103f0c:	ff 75 08             	pushl  0x8(%ebp)
80103f0f:	e8 a9 ff ff ff       	call   80103ebd <holding>
80103f14:	83 c4 10             	add    $0x10,%esp
80103f17:	85 c0                	test   %eax,%eax
80103f19:	75 3a                	jne    80103f55 <acquire+0x58>
  while(xchg(&lk->locked, 1) != 0)
80103f1b:	8b 55 08             	mov    0x8(%ebp),%edx
  asm volatile("lock; xchgl %0, %1" :
80103f1e:	b8 01 00 00 00       	mov    $0x1,%eax
80103f23:	f0 87 02             	lock xchg %eax,(%edx)
80103f26:	85 c0                	test   %eax,%eax
80103f28:	75 f1                	jne    80103f1b <acquire+0x1e>
  __sync_synchronize();
80103f2a:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  lk->cpu = mycpu();
80103f2f:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103f32:	e8 ad f5 ff ff       	call   801034e4 <mycpu>
80103f37:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
80103f3a:	8b 45 08             	mov    0x8(%ebp),%eax
80103f3d:	83 c0 0c             	add    $0xc,%eax
80103f40:	83 ec 08             	sub    $0x8,%esp
80103f43:	50                   	push   %eax
80103f44:	8d 45 08             	lea    0x8(%ebp),%eax
80103f47:	50                   	push   %eax
80103f48:	e8 8f fe ff ff       	call   80103ddc <getcallerpcs>
}
80103f4d:	83 c4 10             	add    $0x10,%esp
80103f50:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103f53:	c9                   	leave  
80103f54:	c3                   	ret    
    panic("acquire");
80103f55:	83 ec 0c             	sub    $0xc,%esp
80103f58:	68 e1 6e 10 80       	push   $0x80106ee1
80103f5d:	e8 e6 c3 ff ff       	call   80100348 <panic>

80103f62 <release>:
{
80103f62:	55                   	push   %ebp
80103f63:	89 e5                	mov    %esp,%ebp
80103f65:	53                   	push   %ebx
80103f66:	83 ec 10             	sub    $0x10,%esp
80103f69:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holding(lk))
80103f6c:	53                   	push   %ebx
80103f6d:	e8 4b ff ff ff       	call   80103ebd <holding>
80103f72:	83 c4 10             	add    $0x10,%esp
80103f75:	85 c0                	test   %eax,%eax
80103f77:	74 23                	je     80103f9c <release+0x3a>
  lk->pcs[0] = 0;
80103f79:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
  lk->cpu = 0;
80103f80:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
  __sync_synchronize();
80103f87:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
80103f8c:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  popcli();
80103f92:	e8 c6 fe ff ff       	call   80103e5d <popcli>
}
80103f97:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103f9a:	c9                   	leave  
80103f9b:	c3                   	ret    
    panic("release");
80103f9c:	83 ec 0c             	sub    $0xc,%esp
80103f9f:	68 e9 6e 10 80       	push   $0x80106ee9
80103fa4:	e8 9f c3 ff ff       	call   80100348 <panic>

80103fa9 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80103fa9:	55                   	push   %ebp
80103faa:	89 e5                	mov    %esp,%ebp
80103fac:	57                   	push   %edi
80103fad:	53                   	push   %ebx
80103fae:	8b 55 08             	mov    0x8(%ebp),%edx
80103fb1:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if ((int)dst%4 == 0 && n%4 == 0){
80103fb4:	f6 c2 03             	test   $0x3,%dl
80103fb7:	75 05                	jne    80103fbe <memset+0x15>
80103fb9:	f6 c1 03             	test   $0x3,%cl
80103fbc:	74 0e                	je     80103fcc <memset+0x23>
  asm volatile("cld; rep stosb" :
80103fbe:	89 d7                	mov    %edx,%edi
80103fc0:	8b 45 0c             	mov    0xc(%ebp),%eax
80103fc3:	fc                   	cld    
80103fc4:	f3 aa                	rep stos %al,%es:(%edi)
    c &= 0xFF;
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
  } else
    stosb(dst, c, n);
  return dst;
}
80103fc6:	89 d0                	mov    %edx,%eax
80103fc8:	5b                   	pop    %ebx
80103fc9:	5f                   	pop    %edi
80103fca:	5d                   	pop    %ebp
80103fcb:	c3                   	ret    
    c &= 0xFF;
80103fcc:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80103fd0:	c1 e9 02             	shr    $0x2,%ecx
80103fd3:	89 f8                	mov    %edi,%eax
80103fd5:	c1 e0 18             	shl    $0x18,%eax
80103fd8:	89 fb                	mov    %edi,%ebx
80103fda:	c1 e3 10             	shl    $0x10,%ebx
80103fdd:	09 d8                	or     %ebx,%eax
80103fdf:	89 fb                	mov    %edi,%ebx
80103fe1:	c1 e3 08             	shl    $0x8,%ebx
80103fe4:	09 d8                	or     %ebx,%eax
80103fe6:	09 f8                	or     %edi,%eax
  asm volatile("cld; rep stosl" :
80103fe8:	89 d7                	mov    %edx,%edi
80103fea:	fc                   	cld    
80103feb:	f3 ab                	rep stos %eax,%es:(%edi)
80103fed:	eb d7                	jmp    80103fc6 <memset+0x1d>

80103fef <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80103fef:	55                   	push   %ebp
80103ff0:	89 e5                	mov    %esp,%ebp
80103ff2:	56                   	push   %esi
80103ff3:	53                   	push   %ebx
80103ff4:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103ff7:	8b 55 0c             	mov    0xc(%ebp),%edx
80103ffa:	8b 45 10             	mov    0x10(%ebp),%eax
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80103ffd:	8d 70 ff             	lea    -0x1(%eax),%esi
80104000:	85 c0                	test   %eax,%eax
80104002:	74 1c                	je     80104020 <memcmp+0x31>
    if(*s1 != *s2)
80104004:	0f b6 01             	movzbl (%ecx),%eax
80104007:	0f b6 1a             	movzbl (%edx),%ebx
8010400a:	38 d8                	cmp    %bl,%al
8010400c:	75 0a                	jne    80104018 <memcmp+0x29>
      return *s1 - *s2;
    s1++, s2++;
8010400e:	83 c1 01             	add    $0x1,%ecx
80104011:	83 c2 01             	add    $0x1,%edx
  while(n-- > 0){
80104014:	89 f0                	mov    %esi,%eax
80104016:	eb e5                	jmp    80103ffd <memcmp+0xe>
      return *s1 - *s2;
80104018:	0f b6 c0             	movzbl %al,%eax
8010401b:	0f b6 db             	movzbl %bl,%ebx
8010401e:	29 d8                	sub    %ebx,%eax
  }

  return 0;
}
80104020:	5b                   	pop    %ebx
80104021:	5e                   	pop    %esi
80104022:	5d                   	pop    %ebp
80104023:	c3                   	ret    

80104024 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80104024:	55                   	push   %ebp
80104025:	89 e5                	mov    %esp,%ebp
80104027:	56                   	push   %esi
80104028:	53                   	push   %ebx
80104029:	8b 45 08             	mov    0x8(%ebp),%eax
8010402c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010402f:	8b 55 10             	mov    0x10(%ebp),%edx
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80104032:	39 c1                	cmp    %eax,%ecx
80104034:	73 3a                	jae    80104070 <memmove+0x4c>
80104036:	8d 1c 11             	lea    (%ecx,%edx,1),%ebx
80104039:	39 c3                	cmp    %eax,%ebx
8010403b:	76 37                	jbe    80104074 <memmove+0x50>
    s += n;
    d += n;
8010403d:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
    while(n-- > 0)
80104040:	eb 0d                	jmp    8010404f <memmove+0x2b>
      *--d = *--s;
80104042:	83 eb 01             	sub    $0x1,%ebx
80104045:	83 e9 01             	sub    $0x1,%ecx
80104048:	0f b6 13             	movzbl (%ebx),%edx
8010404b:	88 11                	mov    %dl,(%ecx)
    while(n-- > 0)
8010404d:	89 f2                	mov    %esi,%edx
8010404f:	8d 72 ff             	lea    -0x1(%edx),%esi
80104052:	85 d2                	test   %edx,%edx
80104054:	75 ec                	jne    80104042 <memmove+0x1e>
80104056:	eb 14                	jmp    8010406c <memmove+0x48>
  } else
    while(n-- > 0)
      *d++ = *s++;
80104058:	0f b6 11             	movzbl (%ecx),%edx
8010405b:	88 13                	mov    %dl,(%ebx)
8010405d:	8d 5b 01             	lea    0x1(%ebx),%ebx
80104060:	8d 49 01             	lea    0x1(%ecx),%ecx
    while(n-- > 0)
80104063:	89 f2                	mov    %esi,%edx
80104065:	8d 72 ff             	lea    -0x1(%edx),%esi
80104068:	85 d2                	test   %edx,%edx
8010406a:	75 ec                	jne    80104058 <memmove+0x34>

  return dst;
}
8010406c:	5b                   	pop    %ebx
8010406d:	5e                   	pop    %esi
8010406e:	5d                   	pop    %ebp
8010406f:	c3                   	ret    
80104070:	89 c3                	mov    %eax,%ebx
80104072:	eb f1                	jmp    80104065 <memmove+0x41>
80104074:	89 c3                	mov    %eax,%ebx
80104076:	eb ed                	jmp    80104065 <memmove+0x41>

80104078 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80104078:	55                   	push   %ebp
80104079:	89 e5                	mov    %esp,%ebp
  return memmove(dst, src, n);
8010407b:	ff 75 10             	pushl  0x10(%ebp)
8010407e:	ff 75 0c             	pushl  0xc(%ebp)
80104081:	ff 75 08             	pushl  0x8(%ebp)
80104084:	e8 9b ff ff ff       	call   80104024 <memmove>
}
80104089:	c9                   	leave  
8010408a:	c3                   	ret    

8010408b <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
8010408b:	55                   	push   %ebp
8010408c:	89 e5                	mov    %esp,%ebp
8010408e:	53                   	push   %ebx
8010408f:	8b 55 08             	mov    0x8(%ebp),%edx
80104092:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80104095:	8b 45 10             	mov    0x10(%ebp),%eax
  while(n > 0 && *p && *p == *q)
80104098:	eb 09                	jmp    801040a3 <strncmp+0x18>
    n--, p++, q++;
8010409a:	83 e8 01             	sub    $0x1,%eax
8010409d:	83 c2 01             	add    $0x1,%edx
801040a0:	83 c1 01             	add    $0x1,%ecx
  while(n > 0 && *p && *p == *q)
801040a3:	85 c0                	test   %eax,%eax
801040a5:	74 0b                	je     801040b2 <strncmp+0x27>
801040a7:	0f b6 1a             	movzbl (%edx),%ebx
801040aa:	84 db                	test   %bl,%bl
801040ac:	74 04                	je     801040b2 <strncmp+0x27>
801040ae:	3a 19                	cmp    (%ecx),%bl
801040b0:	74 e8                	je     8010409a <strncmp+0xf>
  if(n == 0)
801040b2:	85 c0                	test   %eax,%eax
801040b4:	74 0b                	je     801040c1 <strncmp+0x36>
    return 0;
  return (uchar)*p - (uchar)*q;
801040b6:	0f b6 02             	movzbl (%edx),%eax
801040b9:	0f b6 11             	movzbl (%ecx),%edx
801040bc:	29 d0                	sub    %edx,%eax
}
801040be:	5b                   	pop    %ebx
801040bf:	5d                   	pop    %ebp
801040c0:	c3                   	ret    
    return 0;
801040c1:	b8 00 00 00 00       	mov    $0x0,%eax
801040c6:	eb f6                	jmp    801040be <strncmp+0x33>

801040c8 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
801040c8:	55                   	push   %ebp
801040c9:	89 e5                	mov    %esp,%ebp
801040cb:	57                   	push   %edi
801040cc:	56                   	push   %esi
801040cd:	53                   	push   %ebx
801040ce:	8b 5d 0c             	mov    0xc(%ebp),%ebx
801040d1:	8b 4d 10             	mov    0x10(%ebp),%ecx
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
801040d4:	8b 45 08             	mov    0x8(%ebp),%eax
801040d7:	eb 04                	jmp    801040dd <strncpy+0x15>
801040d9:	89 fb                	mov    %edi,%ebx
801040db:	89 f0                	mov    %esi,%eax
801040dd:	8d 51 ff             	lea    -0x1(%ecx),%edx
801040e0:	85 c9                	test   %ecx,%ecx
801040e2:	7e 1d                	jle    80104101 <strncpy+0x39>
801040e4:	8d 7b 01             	lea    0x1(%ebx),%edi
801040e7:	8d 70 01             	lea    0x1(%eax),%esi
801040ea:	0f b6 1b             	movzbl (%ebx),%ebx
801040ed:	88 18                	mov    %bl,(%eax)
801040ef:	89 d1                	mov    %edx,%ecx
801040f1:	84 db                	test   %bl,%bl
801040f3:	75 e4                	jne    801040d9 <strncpy+0x11>
801040f5:	89 f0                	mov    %esi,%eax
801040f7:	eb 08                	jmp    80104101 <strncpy+0x39>
    ;
  while(n-- > 0)
    *s++ = 0;
801040f9:	c6 00 00             	movb   $0x0,(%eax)
  while(n-- > 0)
801040fc:	89 ca                	mov    %ecx,%edx
    *s++ = 0;
801040fe:	8d 40 01             	lea    0x1(%eax),%eax
  while(n-- > 0)
80104101:	8d 4a ff             	lea    -0x1(%edx),%ecx
80104104:	85 d2                	test   %edx,%edx
80104106:	7f f1                	jg     801040f9 <strncpy+0x31>
  return os;
}
80104108:	8b 45 08             	mov    0x8(%ebp),%eax
8010410b:	5b                   	pop    %ebx
8010410c:	5e                   	pop    %esi
8010410d:	5f                   	pop    %edi
8010410e:	5d                   	pop    %ebp
8010410f:	c3                   	ret    

80104110 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80104110:	55                   	push   %ebp
80104111:	89 e5                	mov    %esp,%ebp
80104113:	57                   	push   %edi
80104114:	56                   	push   %esi
80104115:	53                   	push   %ebx
80104116:	8b 45 08             	mov    0x8(%ebp),%eax
80104119:	8b 5d 0c             	mov    0xc(%ebp),%ebx
8010411c:	8b 55 10             	mov    0x10(%ebp),%edx
  char *os;

  os = s;
  if(n <= 0)
8010411f:	85 d2                	test   %edx,%edx
80104121:	7e 23                	jle    80104146 <safestrcpy+0x36>
80104123:	89 c1                	mov    %eax,%ecx
80104125:	eb 04                	jmp    8010412b <safestrcpy+0x1b>
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
80104127:	89 fb                	mov    %edi,%ebx
80104129:	89 f1                	mov    %esi,%ecx
8010412b:	83 ea 01             	sub    $0x1,%edx
8010412e:	85 d2                	test   %edx,%edx
80104130:	7e 11                	jle    80104143 <safestrcpy+0x33>
80104132:	8d 7b 01             	lea    0x1(%ebx),%edi
80104135:	8d 71 01             	lea    0x1(%ecx),%esi
80104138:	0f b6 1b             	movzbl (%ebx),%ebx
8010413b:	88 19                	mov    %bl,(%ecx)
8010413d:	84 db                	test   %bl,%bl
8010413f:	75 e6                	jne    80104127 <safestrcpy+0x17>
80104141:	89 f1                	mov    %esi,%ecx
    ;
  *s = 0;
80104143:	c6 01 00             	movb   $0x0,(%ecx)
  return os;
}
80104146:	5b                   	pop    %ebx
80104147:	5e                   	pop    %esi
80104148:	5f                   	pop    %edi
80104149:	5d                   	pop    %ebp
8010414a:	c3                   	ret    

8010414b <strlen>:

int
strlen(const char *s)
{
8010414b:	55                   	push   %ebp
8010414c:	89 e5                	mov    %esp,%ebp
8010414e:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
80104151:	b8 00 00 00 00       	mov    $0x0,%eax
80104156:	eb 03                	jmp    8010415b <strlen+0x10>
80104158:	83 c0 01             	add    $0x1,%eax
8010415b:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
8010415f:	75 f7                	jne    80104158 <strlen+0xd>
    ;
  return n;
}
80104161:	5d                   	pop    %ebp
80104162:	c3                   	ret    

80104163 <swtch>:
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax
80104163:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80104167:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-saved registers
  pushl %ebp
8010416b:	55                   	push   %ebp
  pushl %ebx
8010416c:	53                   	push   %ebx
  pushl %esi
8010416d:	56                   	push   %esi
  pushl %edi
8010416e:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
8010416f:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80104171:	89 d4                	mov    %edx,%esp

  # Load new callee-saved registers
  popl %edi
80104173:	5f                   	pop    %edi
  popl %esi
80104174:	5e                   	pop    %esi
  popl %ebx
80104175:	5b                   	pop    %ebx
  popl %ebp
80104176:	5d                   	pop    %ebp
  ret
80104177:	c3                   	ret    

80104178 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80104178:	55                   	push   %ebp
80104179:	89 e5                	mov    %esp,%ebp
8010417b:	53                   	push   %ebx
8010417c:	83 ec 04             	sub    $0x4,%esp
8010417f:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *curproc = myproc();
80104182:	e8 d4 f3 ff ff       	call   8010355b <myproc>

  if(addr >= curproc->sz || addr+4 > curproc->sz)
80104187:	8b 00                	mov    (%eax),%eax
80104189:	39 d8                	cmp    %ebx,%eax
8010418b:	76 19                	jbe    801041a6 <fetchint+0x2e>
8010418d:	8d 53 04             	lea    0x4(%ebx),%edx
80104190:	39 d0                	cmp    %edx,%eax
80104192:	72 19                	jb     801041ad <fetchint+0x35>
    return -1;
  *ip = *(int*)(addr);
80104194:	8b 13                	mov    (%ebx),%edx
80104196:	8b 45 0c             	mov    0xc(%ebp),%eax
80104199:	89 10                	mov    %edx,(%eax)
  return 0;
8010419b:	b8 00 00 00 00       	mov    $0x0,%eax
}
801041a0:	83 c4 04             	add    $0x4,%esp
801041a3:	5b                   	pop    %ebx
801041a4:	5d                   	pop    %ebp
801041a5:	c3                   	ret    
    return -1;
801041a6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801041ab:	eb f3                	jmp    801041a0 <fetchint+0x28>
801041ad:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801041b2:	eb ec                	jmp    801041a0 <fetchint+0x28>

801041b4 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
801041b4:	55                   	push   %ebp
801041b5:	89 e5                	mov    %esp,%ebp
801041b7:	53                   	push   %ebx
801041b8:	83 ec 04             	sub    $0x4,%esp
801041bb:	8b 5d 08             	mov    0x8(%ebp),%ebx
  char *s, *ep;
  struct proc *curproc = myproc();
801041be:	e8 98 f3 ff ff       	call   8010355b <myproc>

  if(addr >= curproc->sz)
801041c3:	39 18                	cmp    %ebx,(%eax)
801041c5:	76 26                	jbe    801041ed <fetchstr+0x39>
    return -1;
  *pp = (char*)addr;
801041c7:	8b 55 0c             	mov    0xc(%ebp),%edx
801041ca:	89 1a                	mov    %ebx,(%edx)
  ep = (char*)curproc->sz;
801041cc:	8b 10                	mov    (%eax),%edx
  for(s = *pp; s < ep; s++){
801041ce:	89 d8                	mov    %ebx,%eax
801041d0:	39 d0                	cmp    %edx,%eax
801041d2:	73 0e                	jae    801041e2 <fetchstr+0x2e>
    if(*s == 0)
801041d4:	80 38 00             	cmpb   $0x0,(%eax)
801041d7:	74 05                	je     801041de <fetchstr+0x2a>
  for(s = *pp; s < ep; s++){
801041d9:	83 c0 01             	add    $0x1,%eax
801041dc:	eb f2                	jmp    801041d0 <fetchstr+0x1c>
      return s - *pp;
801041de:	29 d8                	sub    %ebx,%eax
801041e0:	eb 05                	jmp    801041e7 <fetchstr+0x33>
  }
  return -1;
801041e2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801041e7:	83 c4 04             	add    $0x4,%esp
801041ea:	5b                   	pop    %ebx
801041eb:	5d                   	pop    %ebp
801041ec:	c3                   	ret    
    return -1;
801041ed:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801041f2:	eb f3                	jmp    801041e7 <fetchstr+0x33>

801041f4 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
801041f4:	55                   	push   %ebp
801041f5:	89 e5                	mov    %esp,%ebp
801041f7:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
801041fa:	e8 5c f3 ff ff       	call   8010355b <myproc>
801041ff:	8b 50 18             	mov    0x18(%eax),%edx
80104202:	8b 45 08             	mov    0x8(%ebp),%eax
80104205:	c1 e0 02             	shl    $0x2,%eax
80104208:	03 42 44             	add    0x44(%edx),%eax
8010420b:	83 ec 08             	sub    $0x8,%esp
8010420e:	ff 75 0c             	pushl  0xc(%ebp)
80104211:	83 c0 04             	add    $0x4,%eax
80104214:	50                   	push   %eax
80104215:	e8 5e ff ff ff       	call   80104178 <fetchint>
}
8010421a:	c9                   	leave  
8010421b:	c3                   	ret    

8010421c <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
8010421c:	55                   	push   %ebp
8010421d:	89 e5                	mov    %esp,%ebp
8010421f:	56                   	push   %esi
80104220:	53                   	push   %ebx
80104221:	83 ec 10             	sub    $0x10,%esp
80104224:	8b 5d 10             	mov    0x10(%ebp),%ebx
  int i;
  struct proc *curproc = myproc();
80104227:	e8 2f f3 ff ff       	call   8010355b <myproc>
8010422c:	89 c6                	mov    %eax,%esi
 
  if(argint(n, &i) < 0)
8010422e:	83 ec 08             	sub    $0x8,%esp
80104231:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104234:	50                   	push   %eax
80104235:	ff 75 08             	pushl  0x8(%ebp)
80104238:	e8 b7 ff ff ff       	call   801041f4 <argint>
8010423d:	83 c4 10             	add    $0x10,%esp
80104240:	85 c0                	test   %eax,%eax
80104242:	78 24                	js     80104268 <argptr+0x4c>
    return -1;
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
80104244:	85 db                	test   %ebx,%ebx
80104246:	78 27                	js     8010426f <argptr+0x53>
80104248:	8b 16                	mov    (%esi),%edx
8010424a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010424d:	39 c2                	cmp    %eax,%edx
8010424f:	76 25                	jbe    80104276 <argptr+0x5a>
80104251:	01 c3                	add    %eax,%ebx
80104253:	39 da                	cmp    %ebx,%edx
80104255:	72 26                	jb     8010427d <argptr+0x61>
    return -1;
  *pp = (char*)i;
80104257:	8b 55 0c             	mov    0xc(%ebp),%edx
8010425a:	89 02                	mov    %eax,(%edx)
  return 0;
8010425c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104261:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104264:	5b                   	pop    %ebx
80104265:	5e                   	pop    %esi
80104266:	5d                   	pop    %ebp
80104267:	c3                   	ret    
    return -1;
80104268:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010426d:	eb f2                	jmp    80104261 <argptr+0x45>
    return -1;
8010426f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104274:	eb eb                	jmp    80104261 <argptr+0x45>
80104276:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010427b:	eb e4                	jmp    80104261 <argptr+0x45>
8010427d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104282:	eb dd                	jmp    80104261 <argptr+0x45>

80104284 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80104284:	55                   	push   %ebp
80104285:	89 e5                	mov    %esp,%ebp
80104287:	83 ec 20             	sub    $0x20,%esp
  int addr;
  if(argint(n, &addr) < 0)
8010428a:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010428d:	50                   	push   %eax
8010428e:	ff 75 08             	pushl  0x8(%ebp)
80104291:	e8 5e ff ff ff       	call   801041f4 <argint>
80104296:	83 c4 10             	add    $0x10,%esp
80104299:	85 c0                	test   %eax,%eax
8010429b:	78 13                	js     801042b0 <argstr+0x2c>
    return -1;
  return fetchstr(addr, pp);
8010429d:	83 ec 08             	sub    $0x8,%esp
801042a0:	ff 75 0c             	pushl  0xc(%ebp)
801042a3:	ff 75 f4             	pushl  -0xc(%ebp)
801042a6:	e8 09 ff ff ff       	call   801041b4 <fetchstr>
801042ab:	83 c4 10             	add    $0x10,%esp
}
801042ae:	c9                   	leave  
801042af:	c3                   	ret    
    return -1;
801042b0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801042b5:	eb f7                	jmp    801042ae <argstr+0x2a>

801042b7 <syscall>:
[SYS_dump_physmem] sys_dump_physmem,
};

void
syscall(void)
{
801042b7:	55                   	push   %ebp
801042b8:	89 e5                	mov    %esp,%ebp
801042ba:	53                   	push   %ebx
801042bb:	83 ec 04             	sub    $0x4,%esp
  int num;
  struct proc *curproc = myproc();
801042be:	e8 98 f2 ff ff       	call   8010355b <myproc>
801042c3:	89 c3                	mov    %eax,%ebx

  num = curproc->tf->eax;
801042c5:	8b 40 18             	mov    0x18(%eax),%eax
801042c8:	8b 40 1c             	mov    0x1c(%eax),%eax
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
801042cb:	8d 50 ff             	lea    -0x1(%eax),%edx
801042ce:	83 fa 15             	cmp    $0x15,%edx
801042d1:	77 18                	ja     801042eb <syscall+0x34>
801042d3:	8b 14 85 20 6f 10 80 	mov    -0x7fef90e0(,%eax,4),%edx
801042da:	85 d2                	test   %edx,%edx
801042dc:	74 0d                	je     801042eb <syscall+0x34>
    curproc->tf->eax = syscalls[num]();
801042de:	ff d2                	call   *%edx
801042e0:	8b 53 18             	mov    0x18(%ebx),%edx
801042e3:	89 42 1c             	mov    %eax,0x1c(%edx)
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
  }
}
801042e6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801042e9:	c9                   	leave  
801042ea:	c3                   	ret    
            curproc->pid, curproc->name, num);
801042eb:	8d 53 6c             	lea    0x6c(%ebx),%edx
    cprintf("%d %s: unknown sys call %d\n",
801042ee:	50                   	push   %eax
801042ef:	52                   	push   %edx
801042f0:	ff 73 10             	pushl  0x10(%ebx)
801042f3:	68 f1 6e 10 80       	push   $0x80106ef1
801042f8:	e8 0e c3 ff ff       	call   8010060b <cprintf>
    curproc->tf->eax = -1;
801042fd:	8b 43 18             	mov    0x18(%ebx),%eax
80104300:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
80104307:	83 c4 10             	add    $0x10,%esp
}
8010430a:	eb da                	jmp    801042e6 <syscall+0x2f>

8010430c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
8010430c:	55                   	push   %ebp
8010430d:	89 e5                	mov    %esp,%ebp
8010430f:	56                   	push   %esi
80104310:	53                   	push   %ebx
80104311:	83 ec 18             	sub    $0x18,%esp
80104314:	89 d6                	mov    %edx,%esi
80104316:	89 cb                	mov    %ecx,%ebx
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80104318:	8d 55 f4             	lea    -0xc(%ebp),%edx
8010431b:	52                   	push   %edx
8010431c:	50                   	push   %eax
8010431d:	e8 d2 fe ff ff       	call   801041f4 <argint>
80104322:	83 c4 10             	add    $0x10,%esp
80104325:	85 c0                	test   %eax,%eax
80104327:	78 2e                	js     80104357 <argfd+0x4b>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
80104329:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
8010432d:	77 2f                	ja     8010435e <argfd+0x52>
8010432f:	e8 27 f2 ff ff       	call   8010355b <myproc>
80104334:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104337:	8b 44 90 28          	mov    0x28(%eax,%edx,4),%eax
8010433b:	85 c0                	test   %eax,%eax
8010433d:	74 26                	je     80104365 <argfd+0x59>
    return -1;
  if(pfd)
8010433f:	85 f6                	test   %esi,%esi
80104341:	74 02                	je     80104345 <argfd+0x39>
    *pfd = fd;
80104343:	89 16                	mov    %edx,(%esi)
  if(pf)
80104345:	85 db                	test   %ebx,%ebx
80104347:	74 23                	je     8010436c <argfd+0x60>
    *pf = f;
80104349:	89 03                	mov    %eax,(%ebx)
  return 0;
8010434b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104350:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104353:	5b                   	pop    %ebx
80104354:	5e                   	pop    %esi
80104355:	5d                   	pop    %ebp
80104356:	c3                   	ret    
    return -1;
80104357:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010435c:	eb f2                	jmp    80104350 <argfd+0x44>
    return -1;
8010435e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104363:	eb eb                	jmp    80104350 <argfd+0x44>
80104365:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010436a:	eb e4                	jmp    80104350 <argfd+0x44>
  return 0;
8010436c:	b8 00 00 00 00       	mov    $0x0,%eax
80104371:	eb dd                	jmp    80104350 <argfd+0x44>

80104373 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80104373:	55                   	push   %ebp
80104374:	89 e5                	mov    %esp,%ebp
80104376:	53                   	push   %ebx
80104377:	83 ec 04             	sub    $0x4,%esp
8010437a:	89 c3                	mov    %eax,%ebx
  int fd;
  struct proc *curproc = myproc();
8010437c:	e8 da f1 ff ff       	call   8010355b <myproc>

  for(fd = 0; fd < NOFILE; fd++){
80104381:	ba 00 00 00 00       	mov    $0x0,%edx
80104386:	83 fa 0f             	cmp    $0xf,%edx
80104389:	7f 18                	jg     801043a3 <fdalloc+0x30>
    if(curproc->ofile[fd] == 0){
8010438b:	83 7c 90 28 00       	cmpl   $0x0,0x28(%eax,%edx,4)
80104390:	74 05                	je     80104397 <fdalloc+0x24>
  for(fd = 0; fd < NOFILE; fd++){
80104392:	83 c2 01             	add    $0x1,%edx
80104395:	eb ef                	jmp    80104386 <fdalloc+0x13>
      curproc->ofile[fd] = f;
80104397:	89 5c 90 28          	mov    %ebx,0x28(%eax,%edx,4)
      return fd;
    }
  }
  return -1;
}
8010439b:	89 d0                	mov    %edx,%eax
8010439d:	83 c4 04             	add    $0x4,%esp
801043a0:	5b                   	pop    %ebx
801043a1:	5d                   	pop    %ebp
801043a2:	c3                   	ret    
  return -1;
801043a3:	ba ff ff ff ff       	mov    $0xffffffff,%edx
801043a8:	eb f1                	jmp    8010439b <fdalloc+0x28>

801043aa <isdirempty>:
}

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
801043aa:	55                   	push   %ebp
801043ab:	89 e5                	mov    %esp,%ebp
801043ad:	56                   	push   %esi
801043ae:	53                   	push   %ebx
801043af:	83 ec 10             	sub    $0x10,%esp
801043b2:	89 c3                	mov    %eax,%ebx
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801043b4:	b8 20 00 00 00       	mov    $0x20,%eax
801043b9:	89 c6                	mov    %eax,%esi
801043bb:	39 43 58             	cmp    %eax,0x58(%ebx)
801043be:	76 2e                	jbe    801043ee <isdirempty+0x44>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801043c0:	6a 10                	push   $0x10
801043c2:	50                   	push   %eax
801043c3:	8d 45 e8             	lea    -0x18(%ebp),%eax
801043c6:	50                   	push   %eax
801043c7:	53                   	push   %ebx
801043c8:	e8 b2 d3 ff ff       	call   8010177f <readi>
801043cd:	83 c4 10             	add    $0x10,%esp
801043d0:	83 f8 10             	cmp    $0x10,%eax
801043d3:	75 0c                	jne    801043e1 <isdirempty+0x37>
      panic("isdirempty: readi");
    if(de.inum != 0)
801043d5:	66 83 7d e8 00       	cmpw   $0x0,-0x18(%ebp)
801043da:	75 1e                	jne    801043fa <isdirempty+0x50>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801043dc:	8d 46 10             	lea    0x10(%esi),%eax
801043df:	eb d8                	jmp    801043b9 <isdirempty+0xf>
      panic("isdirempty: readi");
801043e1:	83 ec 0c             	sub    $0xc,%esp
801043e4:	68 7c 6f 10 80       	push   $0x80106f7c
801043e9:	e8 5a bf ff ff       	call   80100348 <panic>
      return 0;
  }
  return 1;
801043ee:	b8 01 00 00 00       	mov    $0x1,%eax
}
801043f3:	8d 65 f8             	lea    -0x8(%ebp),%esp
801043f6:	5b                   	pop    %ebx
801043f7:	5e                   	pop    %esi
801043f8:	5d                   	pop    %ebp
801043f9:	c3                   	ret    
      return 0;
801043fa:	b8 00 00 00 00       	mov    $0x0,%eax
801043ff:	eb f2                	jmp    801043f3 <isdirempty+0x49>

80104401 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
80104401:	55                   	push   %ebp
80104402:	89 e5                	mov    %esp,%ebp
80104404:	57                   	push   %edi
80104405:	56                   	push   %esi
80104406:	53                   	push   %ebx
80104407:	83 ec 44             	sub    $0x44,%esp
8010440a:	89 55 c4             	mov    %edx,-0x3c(%ebp)
8010440d:	89 4d c0             	mov    %ecx,-0x40(%ebp)
80104410:	8b 7d 08             	mov    0x8(%ebp),%edi
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80104413:	8d 55 d6             	lea    -0x2a(%ebp),%edx
80104416:	52                   	push   %edx
80104417:	50                   	push   %eax
80104418:	e8 e8 d7 ff ff       	call   80101c05 <nameiparent>
8010441d:	89 c6                	mov    %eax,%esi
8010441f:	83 c4 10             	add    $0x10,%esp
80104422:	85 c0                	test   %eax,%eax
80104424:	0f 84 3a 01 00 00    	je     80104564 <create+0x163>
    return 0;
  ilock(dp);
8010442a:	83 ec 0c             	sub    $0xc,%esp
8010442d:	50                   	push   %eax
8010442e:	e8 5a d1 ff ff       	call   8010158d <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80104433:	83 c4 0c             	add    $0xc,%esp
80104436:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104439:	50                   	push   %eax
8010443a:	8d 45 d6             	lea    -0x2a(%ebp),%eax
8010443d:	50                   	push   %eax
8010443e:	56                   	push   %esi
8010443f:	e8 78 d5 ff ff       	call   801019bc <dirlookup>
80104444:	89 c3                	mov    %eax,%ebx
80104446:	83 c4 10             	add    $0x10,%esp
80104449:	85 c0                	test   %eax,%eax
8010444b:	74 3f                	je     8010448c <create+0x8b>
    iunlockput(dp);
8010444d:	83 ec 0c             	sub    $0xc,%esp
80104450:	56                   	push   %esi
80104451:	e8 de d2 ff ff       	call   80101734 <iunlockput>
    ilock(ip);
80104456:	89 1c 24             	mov    %ebx,(%esp)
80104459:	e8 2f d1 ff ff       	call   8010158d <ilock>
    if(type == T_FILE && ip->type == T_FILE)
8010445e:	83 c4 10             	add    $0x10,%esp
80104461:	66 83 7d c4 02       	cmpw   $0x2,-0x3c(%ebp)
80104466:	75 11                	jne    80104479 <create+0x78>
80104468:	66 83 7b 50 02       	cmpw   $0x2,0x50(%ebx)
8010446d:	75 0a                	jne    80104479 <create+0x78>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
8010446f:	89 d8                	mov    %ebx,%eax
80104471:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104474:	5b                   	pop    %ebx
80104475:	5e                   	pop    %esi
80104476:	5f                   	pop    %edi
80104477:	5d                   	pop    %ebp
80104478:	c3                   	ret    
    iunlockput(ip);
80104479:	83 ec 0c             	sub    $0xc,%esp
8010447c:	53                   	push   %ebx
8010447d:	e8 b2 d2 ff ff       	call   80101734 <iunlockput>
    return 0;
80104482:	83 c4 10             	add    $0x10,%esp
80104485:	bb 00 00 00 00       	mov    $0x0,%ebx
8010448a:	eb e3                	jmp    8010446f <create+0x6e>
  if((ip = ialloc(dp->dev, type)) == 0)
8010448c:	0f bf 45 c4          	movswl -0x3c(%ebp),%eax
80104490:	83 ec 08             	sub    $0x8,%esp
80104493:	50                   	push   %eax
80104494:	ff 36                	pushl  (%esi)
80104496:	e8 ef ce ff ff       	call   8010138a <ialloc>
8010449b:	89 c3                	mov    %eax,%ebx
8010449d:	83 c4 10             	add    $0x10,%esp
801044a0:	85 c0                	test   %eax,%eax
801044a2:	74 55                	je     801044f9 <create+0xf8>
  ilock(ip);
801044a4:	83 ec 0c             	sub    $0xc,%esp
801044a7:	50                   	push   %eax
801044a8:	e8 e0 d0 ff ff       	call   8010158d <ilock>
  ip->major = major;
801044ad:	0f b7 45 c0          	movzwl -0x40(%ebp),%eax
801044b1:	66 89 43 52          	mov    %ax,0x52(%ebx)
  ip->minor = minor;
801044b5:	66 89 7b 54          	mov    %di,0x54(%ebx)
  ip->nlink = 1;
801044b9:	66 c7 43 56 01 00    	movw   $0x1,0x56(%ebx)
  iupdate(ip);
801044bf:	89 1c 24             	mov    %ebx,(%esp)
801044c2:	e8 65 cf ff ff       	call   8010142c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
801044c7:	83 c4 10             	add    $0x10,%esp
801044ca:	66 83 7d c4 01       	cmpw   $0x1,-0x3c(%ebp)
801044cf:	74 35                	je     80104506 <create+0x105>
  if(dirlink(dp, name, ip->inum) < 0)
801044d1:	83 ec 04             	sub    $0x4,%esp
801044d4:	ff 73 04             	pushl  0x4(%ebx)
801044d7:	8d 45 d6             	lea    -0x2a(%ebp),%eax
801044da:	50                   	push   %eax
801044db:	56                   	push   %esi
801044dc:	e8 5b d6 ff ff       	call   80101b3c <dirlink>
801044e1:	83 c4 10             	add    $0x10,%esp
801044e4:	85 c0                	test   %eax,%eax
801044e6:	78 6f                	js     80104557 <create+0x156>
  iunlockput(dp);
801044e8:	83 ec 0c             	sub    $0xc,%esp
801044eb:	56                   	push   %esi
801044ec:	e8 43 d2 ff ff       	call   80101734 <iunlockput>
  return ip;
801044f1:	83 c4 10             	add    $0x10,%esp
801044f4:	e9 76 ff ff ff       	jmp    8010446f <create+0x6e>
    panic("create: ialloc");
801044f9:	83 ec 0c             	sub    $0xc,%esp
801044fc:	68 8e 6f 10 80       	push   $0x80106f8e
80104501:	e8 42 be ff ff       	call   80100348 <panic>
    dp->nlink++;  // for ".."
80104506:	0f b7 46 56          	movzwl 0x56(%esi),%eax
8010450a:	83 c0 01             	add    $0x1,%eax
8010450d:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
80104511:	83 ec 0c             	sub    $0xc,%esp
80104514:	56                   	push   %esi
80104515:	e8 12 cf ff ff       	call   8010142c <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
8010451a:	83 c4 0c             	add    $0xc,%esp
8010451d:	ff 73 04             	pushl  0x4(%ebx)
80104520:	68 9e 6f 10 80       	push   $0x80106f9e
80104525:	53                   	push   %ebx
80104526:	e8 11 d6 ff ff       	call   80101b3c <dirlink>
8010452b:	83 c4 10             	add    $0x10,%esp
8010452e:	85 c0                	test   %eax,%eax
80104530:	78 18                	js     8010454a <create+0x149>
80104532:	83 ec 04             	sub    $0x4,%esp
80104535:	ff 76 04             	pushl  0x4(%esi)
80104538:	68 9d 6f 10 80       	push   $0x80106f9d
8010453d:	53                   	push   %ebx
8010453e:	e8 f9 d5 ff ff       	call   80101b3c <dirlink>
80104543:	83 c4 10             	add    $0x10,%esp
80104546:	85 c0                	test   %eax,%eax
80104548:	79 87                	jns    801044d1 <create+0xd0>
      panic("create dots");
8010454a:	83 ec 0c             	sub    $0xc,%esp
8010454d:	68 a0 6f 10 80       	push   $0x80106fa0
80104552:	e8 f1 bd ff ff       	call   80100348 <panic>
    panic("create: dirlink");
80104557:	83 ec 0c             	sub    $0xc,%esp
8010455a:	68 ac 6f 10 80       	push   $0x80106fac
8010455f:	e8 e4 bd ff ff       	call   80100348 <panic>
    return 0;
80104564:	89 c3                	mov    %eax,%ebx
80104566:	e9 04 ff ff ff       	jmp    8010446f <create+0x6e>

8010456b <sys_dup>:
{
8010456b:	55                   	push   %ebp
8010456c:	89 e5                	mov    %esp,%ebp
8010456e:	53                   	push   %ebx
8010456f:	83 ec 14             	sub    $0x14,%esp
  if(argfd(0, 0, &f) < 0)
80104572:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104575:	ba 00 00 00 00       	mov    $0x0,%edx
8010457a:	b8 00 00 00 00       	mov    $0x0,%eax
8010457f:	e8 88 fd ff ff       	call   8010430c <argfd>
80104584:	85 c0                	test   %eax,%eax
80104586:	78 23                	js     801045ab <sys_dup+0x40>
  if((fd=fdalloc(f)) < 0)
80104588:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010458b:	e8 e3 fd ff ff       	call   80104373 <fdalloc>
80104590:	89 c3                	mov    %eax,%ebx
80104592:	85 c0                	test   %eax,%eax
80104594:	78 1c                	js     801045b2 <sys_dup+0x47>
  filedup(f);
80104596:	83 ec 0c             	sub    $0xc,%esp
80104599:	ff 75 f4             	pushl  -0xc(%ebp)
8010459c:	e8 f9 c6 ff ff       	call   80100c9a <filedup>
  return fd;
801045a1:	83 c4 10             	add    $0x10,%esp
}
801045a4:	89 d8                	mov    %ebx,%eax
801045a6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801045a9:	c9                   	leave  
801045aa:	c3                   	ret    
    return -1;
801045ab:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801045b0:	eb f2                	jmp    801045a4 <sys_dup+0x39>
    return -1;
801045b2:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801045b7:	eb eb                	jmp    801045a4 <sys_dup+0x39>

801045b9 <sys_read>:
{
801045b9:	55                   	push   %ebp
801045ba:	89 e5                	mov    %esp,%ebp
801045bc:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801045bf:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801045c2:	ba 00 00 00 00       	mov    $0x0,%edx
801045c7:	b8 00 00 00 00       	mov    $0x0,%eax
801045cc:	e8 3b fd ff ff       	call   8010430c <argfd>
801045d1:	85 c0                	test   %eax,%eax
801045d3:	78 43                	js     80104618 <sys_read+0x5f>
801045d5:	83 ec 08             	sub    $0x8,%esp
801045d8:	8d 45 f0             	lea    -0x10(%ebp),%eax
801045db:	50                   	push   %eax
801045dc:	6a 02                	push   $0x2
801045de:	e8 11 fc ff ff       	call   801041f4 <argint>
801045e3:	83 c4 10             	add    $0x10,%esp
801045e6:	85 c0                	test   %eax,%eax
801045e8:	78 35                	js     8010461f <sys_read+0x66>
801045ea:	83 ec 04             	sub    $0x4,%esp
801045ed:	ff 75 f0             	pushl  -0x10(%ebp)
801045f0:	8d 45 ec             	lea    -0x14(%ebp),%eax
801045f3:	50                   	push   %eax
801045f4:	6a 01                	push   $0x1
801045f6:	e8 21 fc ff ff       	call   8010421c <argptr>
801045fb:	83 c4 10             	add    $0x10,%esp
801045fe:	85 c0                	test   %eax,%eax
80104600:	78 24                	js     80104626 <sys_read+0x6d>
  return fileread(f, p, n);
80104602:	83 ec 04             	sub    $0x4,%esp
80104605:	ff 75 f0             	pushl  -0x10(%ebp)
80104608:	ff 75 ec             	pushl  -0x14(%ebp)
8010460b:	ff 75 f4             	pushl  -0xc(%ebp)
8010460e:	e8 d0 c7 ff ff       	call   80100de3 <fileread>
80104613:	83 c4 10             	add    $0x10,%esp
}
80104616:	c9                   	leave  
80104617:	c3                   	ret    
    return -1;
80104618:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010461d:	eb f7                	jmp    80104616 <sys_read+0x5d>
8010461f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104624:	eb f0                	jmp    80104616 <sys_read+0x5d>
80104626:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010462b:	eb e9                	jmp    80104616 <sys_read+0x5d>

8010462d <sys_write>:
{
8010462d:	55                   	push   %ebp
8010462e:	89 e5                	mov    %esp,%ebp
80104630:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80104633:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104636:	ba 00 00 00 00       	mov    $0x0,%edx
8010463b:	b8 00 00 00 00       	mov    $0x0,%eax
80104640:	e8 c7 fc ff ff       	call   8010430c <argfd>
80104645:	85 c0                	test   %eax,%eax
80104647:	78 43                	js     8010468c <sys_write+0x5f>
80104649:	83 ec 08             	sub    $0x8,%esp
8010464c:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010464f:	50                   	push   %eax
80104650:	6a 02                	push   $0x2
80104652:	e8 9d fb ff ff       	call   801041f4 <argint>
80104657:	83 c4 10             	add    $0x10,%esp
8010465a:	85 c0                	test   %eax,%eax
8010465c:	78 35                	js     80104693 <sys_write+0x66>
8010465e:	83 ec 04             	sub    $0x4,%esp
80104661:	ff 75 f0             	pushl  -0x10(%ebp)
80104664:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104667:	50                   	push   %eax
80104668:	6a 01                	push   $0x1
8010466a:	e8 ad fb ff ff       	call   8010421c <argptr>
8010466f:	83 c4 10             	add    $0x10,%esp
80104672:	85 c0                	test   %eax,%eax
80104674:	78 24                	js     8010469a <sys_write+0x6d>
  return filewrite(f, p, n);
80104676:	83 ec 04             	sub    $0x4,%esp
80104679:	ff 75 f0             	pushl  -0x10(%ebp)
8010467c:	ff 75 ec             	pushl  -0x14(%ebp)
8010467f:	ff 75 f4             	pushl  -0xc(%ebp)
80104682:	e8 e1 c7 ff ff       	call   80100e68 <filewrite>
80104687:	83 c4 10             	add    $0x10,%esp
}
8010468a:	c9                   	leave  
8010468b:	c3                   	ret    
    return -1;
8010468c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104691:	eb f7                	jmp    8010468a <sys_write+0x5d>
80104693:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104698:	eb f0                	jmp    8010468a <sys_write+0x5d>
8010469a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010469f:	eb e9                	jmp    8010468a <sys_write+0x5d>

801046a1 <sys_close>:
{
801046a1:	55                   	push   %ebp
801046a2:	89 e5                	mov    %esp,%ebp
801046a4:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, &fd, &f) < 0)
801046a7:	8d 4d f0             	lea    -0x10(%ebp),%ecx
801046aa:	8d 55 f4             	lea    -0xc(%ebp),%edx
801046ad:	b8 00 00 00 00       	mov    $0x0,%eax
801046b2:	e8 55 fc ff ff       	call   8010430c <argfd>
801046b7:	85 c0                	test   %eax,%eax
801046b9:	78 25                	js     801046e0 <sys_close+0x3f>
  myproc()->ofile[fd] = 0;
801046bb:	e8 9b ee ff ff       	call   8010355b <myproc>
801046c0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801046c3:	c7 44 90 28 00 00 00 	movl   $0x0,0x28(%eax,%edx,4)
801046ca:	00 
  fileclose(f);
801046cb:	83 ec 0c             	sub    $0xc,%esp
801046ce:	ff 75 f0             	pushl  -0x10(%ebp)
801046d1:	e8 09 c6 ff ff       	call   80100cdf <fileclose>
  return 0;
801046d6:	83 c4 10             	add    $0x10,%esp
801046d9:	b8 00 00 00 00       	mov    $0x0,%eax
}
801046de:	c9                   	leave  
801046df:	c3                   	ret    
    return -1;
801046e0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046e5:	eb f7                	jmp    801046de <sys_close+0x3d>

801046e7 <sys_fstat>:
{
801046e7:	55                   	push   %ebp
801046e8:	89 e5                	mov    %esp,%ebp
801046ea:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801046ed:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801046f0:	ba 00 00 00 00       	mov    $0x0,%edx
801046f5:	b8 00 00 00 00       	mov    $0x0,%eax
801046fa:	e8 0d fc ff ff       	call   8010430c <argfd>
801046ff:	85 c0                	test   %eax,%eax
80104701:	78 2a                	js     8010472d <sys_fstat+0x46>
80104703:	83 ec 04             	sub    $0x4,%esp
80104706:	6a 14                	push   $0x14
80104708:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010470b:	50                   	push   %eax
8010470c:	6a 01                	push   $0x1
8010470e:	e8 09 fb ff ff       	call   8010421c <argptr>
80104713:	83 c4 10             	add    $0x10,%esp
80104716:	85 c0                	test   %eax,%eax
80104718:	78 1a                	js     80104734 <sys_fstat+0x4d>
  return filestat(f, st);
8010471a:	83 ec 08             	sub    $0x8,%esp
8010471d:	ff 75 f0             	pushl  -0x10(%ebp)
80104720:	ff 75 f4             	pushl  -0xc(%ebp)
80104723:	e8 74 c6 ff ff       	call   80100d9c <filestat>
80104728:	83 c4 10             	add    $0x10,%esp
}
8010472b:	c9                   	leave  
8010472c:	c3                   	ret    
    return -1;
8010472d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104732:	eb f7                	jmp    8010472b <sys_fstat+0x44>
80104734:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104739:	eb f0                	jmp    8010472b <sys_fstat+0x44>

8010473b <sys_link>:
{
8010473b:	55                   	push   %ebp
8010473c:	89 e5                	mov    %esp,%ebp
8010473e:	56                   	push   %esi
8010473f:	53                   	push   %ebx
80104740:	83 ec 28             	sub    $0x28,%esp
  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80104743:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104746:	50                   	push   %eax
80104747:	6a 00                	push   $0x0
80104749:	e8 36 fb ff ff       	call   80104284 <argstr>
8010474e:	83 c4 10             	add    $0x10,%esp
80104751:	85 c0                	test   %eax,%eax
80104753:	0f 88 32 01 00 00    	js     8010488b <sys_link+0x150>
80104759:	83 ec 08             	sub    $0x8,%esp
8010475c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010475f:	50                   	push   %eax
80104760:	6a 01                	push   $0x1
80104762:	e8 1d fb ff ff       	call   80104284 <argstr>
80104767:	83 c4 10             	add    $0x10,%esp
8010476a:	85 c0                	test   %eax,%eax
8010476c:	0f 88 20 01 00 00    	js     80104892 <sys_link+0x157>
  begin_op();
80104772:	e8 89 e3 ff ff       	call   80102b00 <begin_op>
  if((ip = namei(old)) == 0){
80104777:	83 ec 0c             	sub    $0xc,%esp
8010477a:	ff 75 e0             	pushl  -0x20(%ebp)
8010477d:	e8 6b d4 ff ff       	call   80101bed <namei>
80104782:	89 c3                	mov    %eax,%ebx
80104784:	83 c4 10             	add    $0x10,%esp
80104787:	85 c0                	test   %eax,%eax
80104789:	0f 84 99 00 00 00    	je     80104828 <sys_link+0xed>
  ilock(ip);
8010478f:	83 ec 0c             	sub    $0xc,%esp
80104792:	50                   	push   %eax
80104793:	e8 f5 cd ff ff       	call   8010158d <ilock>
  if(ip->type == T_DIR){
80104798:	83 c4 10             	add    $0x10,%esp
8010479b:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
801047a0:	0f 84 8e 00 00 00    	je     80104834 <sys_link+0xf9>
  ip->nlink++;
801047a6:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
801047aa:	83 c0 01             	add    $0x1,%eax
801047ad:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
801047b1:	83 ec 0c             	sub    $0xc,%esp
801047b4:	53                   	push   %ebx
801047b5:	e8 72 cc ff ff       	call   8010142c <iupdate>
  iunlock(ip);
801047ba:	89 1c 24             	mov    %ebx,(%esp)
801047bd:	e8 8d ce ff ff       	call   8010164f <iunlock>
  if((dp = nameiparent(new, name)) == 0)
801047c2:	83 c4 08             	add    $0x8,%esp
801047c5:	8d 45 ea             	lea    -0x16(%ebp),%eax
801047c8:	50                   	push   %eax
801047c9:	ff 75 e4             	pushl  -0x1c(%ebp)
801047cc:	e8 34 d4 ff ff       	call   80101c05 <nameiparent>
801047d1:	89 c6                	mov    %eax,%esi
801047d3:	83 c4 10             	add    $0x10,%esp
801047d6:	85 c0                	test   %eax,%eax
801047d8:	74 7e                	je     80104858 <sys_link+0x11d>
  ilock(dp);
801047da:	83 ec 0c             	sub    $0xc,%esp
801047dd:	50                   	push   %eax
801047de:	e8 aa cd ff ff       	call   8010158d <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
801047e3:	83 c4 10             	add    $0x10,%esp
801047e6:	8b 03                	mov    (%ebx),%eax
801047e8:	39 06                	cmp    %eax,(%esi)
801047ea:	75 60                	jne    8010484c <sys_link+0x111>
801047ec:	83 ec 04             	sub    $0x4,%esp
801047ef:	ff 73 04             	pushl  0x4(%ebx)
801047f2:	8d 45 ea             	lea    -0x16(%ebp),%eax
801047f5:	50                   	push   %eax
801047f6:	56                   	push   %esi
801047f7:	e8 40 d3 ff ff       	call   80101b3c <dirlink>
801047fc:	83 c4 10             	add    $0x10,%esp
801047ff:	85 c0                	test   %eax,%eax
80104801:	78 49                	js     8010484c <sys_link+0x111>
  iunlockput(dp);
80104803:	83 ec 0c             	sub    $0xc,%esp
80104806:	56                   	push   %esi
80104807:	e8 28 cf ff ff       	call   80101734 <iunlockput>
  iput(ip);
8010480c:	89 1c 24             	mov    %ebx,(%esp)
8010480f:	e8 80 ce ff ff       	call   80101694 <iput>
  end_op();
80104814:	e8 61 e3 ff ff       	call   80102b7a <end_op>
  return 0;
80104819:	83 c4 10             	add    $0x10,%esp
8010481c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104821:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104824:	5b                   	pop    %ebx
80104825:	5e                   	pop    %esi
80104826:	5d                   	pop    %ebp
80104827:	c3                   	ret    
    end_op();
80104828:	e8 4d e3 ff ff       	call   80102b7a <end_op>
    return -1;
8010482d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104832:	eb ed                	jmp    80104821 <sys_link+0xe6>
    iunlockput(ip);
80104834:	83 ec 0c             	sub    $0xc,%esp
80104837:	53                   	push   %ebx
80104838:	e8 f7 ce ff ff       	call   80101734 <iunlockput>
    end_op();
8010483d:	e8 38 e3 ff ff       	call   80102b7a <end_op>
    return -1;
80104842:	83 c4 10             	add    $0x10,%esp
80104845:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010484a:	eb d5                	jmp    80104821 <sys_link+0xe6>
    iunlockput(dp);
8010484c:	83 ec 0c             	sub    $0xc,%esp
8010484f:	56                   	push   %esi
80104850:	e8 df ce ff ff       	call   80101734 <iunlockput>
    goto bad;
80104855:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
80104858:	83 ec 0c             	sub    $0xc,%esp
8010485b:	53                   	push   %ebx
8010485c:	e8 2c cd ff ff       	call   8010158d <ilock>
  ip->nlink--;
80104861:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104865:	83 e8 01             	sub    $0x1,%eax
80104868:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
8010486c:	89 1c 24             	mov    %ebx,(%esp)
8010486f:	e8 b8 cb ff ff       	call   8010142c <iupdate>
  iunlockput(ip);
80104874:	89 1c 24             	mov    %ebx,(%esp)
80104877:	e8 b8 ce ff ff       	call   80101734 <iunlockput>
  end_op();
8010487c:	e8 f9 e2 ff ff       	call   80102b7a <end_op>
  return -1;
80104881:	83 c4 10             	add    $0x10,%esp
80104884:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104889:	eb 96                	jmp    80104821 <sys_link+0xe6>
    return -1;
8010488b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104890:	eb 8f                	jmp    80104821 <sys_link+0xe6>
80104892:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104897:	eb 88                	jmp    80104821 <sys_link+0xe6>

80104899 <sys_unlink>:
{
80104899:	55                   	push   %ebp
8010489a:	89 e5                	mov    %esp,%ebp
8010489c:	57                   	push   %edi
8010489d:	56                   	push   %esi
8010489e:	53                   	push   %ebx
8010489f:	83 ec 44             	sub    $0x44,%esp
  if(argstr(0, &path) < 0)
801048a2:	8d 45 c4             	lea    -0x3c(%ebp),%eax
801048a5:	50                   	push   %eax
801048a6:	6a 00                	push   $0x0
801048a8:	e8 d7 f9 ff ff       	call   80104284 <argstr>
801048ad:	83 c4 10             	add    $0x10,%esp
801048b0:	85 c0                	test   %eax,%eax
801048b2:	0f 88 83 01 00 00    	js     80104a3b <sys_unlink+0x1a2>
  begin_op();
801048b8:	e8 43 e2 ff ff       	call   80102b00 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
801048bd:	83 ec 08             	sub    $0x8,%esp
801048c0:	8d 45 ca             	lea    -0x36(%ebp),%eax
801048c3:	50                   	push   %eax
801048c4:	ff 75 c4             	pushl  -0x3c(%ebp)
801048c7:	e8 39 d3 ff ff       	call   80101c05 <nameiparent>
801048cc:	89 c6                	mov    %eax,%esi
801048ce:	83 c4 10             	add    $0x10,%esp
801048d1:	85 c0                	test   %eax,%eax
801048d3:	0f 84 ed 00 00 00    	je     801049c6 <sys_unlink+0x12d>
  ilock(dp);
801048d9:	83 ec 0c             	sub    $0xc,%esp
801048dc:	50                   	push   %eax
801048dd:	e8 ab cc ff ff       	call   8010158d <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
801048e2:	83 c4 08             	add    $0x8,%esp
801048e5:	68 9e 6f 10 80       	push   $0x80106f9e
801048ea:	8d 45 ca             	lea    -0x36(%ebp),%eax
801048ed:	50                   	push   %eax
801048ee:	e8 b4 d0 ff ff       	call   801019a7 <namecmp>
801048f3:	83 c4 10             	add    $0x10,%esp
801048f6:	85 c0                	test   %eax,%eax
801048f8:	0f 84 fc 00 00 00    	je     801049fa <sys_unlink+0x161>
801048fe:	83 ec 08             	sub    $0x8,%esp
80104901:	68 9d 6f 10 80       	push   $0x80106f9d
80104906:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104909:	50                   	push   %eax
8010490a:	e8 98 d0 ff ff       	call   801019a7 <namecmp>
8010490f:	83 c4 10             	add    $0x10,%esp
80104912:	85 c0                	test   %eax,%eax
80104914:	0f 84 e0 00 00 00    	je     801049fa <sys_unlink+0x161>
  if((ip = dirlookup(dp, name, &off)) == 0)
8010491a:	83 ec 04             	sub    $0x4,%esp
8010491d:	8d 45 c0             	lea    -0x40(%ebp),%eax
80104920:	50                   	push   %eax
80104921:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104924:	50                   	push   %eax
80104925:	56                   	push   %esi
80104926:	e8 91 d0 ff ff       	call   801019bc <dirlookup>
8010492b:	89 c3                	mov    %eax,%ebx
8010492d:	83 c4 10             	add    $0x10,%esp
80104930:	85 c0                	test   %eax,%eax
80104932:	0f 84 c2 00 00 00    	je     801049fa <sys_unlink+0x161>
  ilock(ip);
80104938:	83 ec 0c             	sub    $0xc,%esp
8010493b:	50                   	push   %eax
8010493c:	e8 4c cc ff ff       	call   8010158d <ilock>
  if(ip->nlink < 1)
80104941:	83 c4 10             	add    $0x10,%esp
80104944:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
80104949:	0f 8e 83 00 00 00    	jle    801049d2 <sys_unlink+0x139>
  if(ip->type == T_DIR && !isdirempty(ip)){
8010494f:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104954:	0f 84 85 00 00 00    	je     801049df <sys_unlink+0x146>
  memset(&de, 0, sizeof(de));
8010495a:	83 ec 04             	sub    $0x4,%esp
8010495d:	6a 10                	push   $0x10
8010495f:	6a 00                	push   $0x0
80104961:	8d 7d d8             	lea    -0x28(%ebp),%edi
80104964:	57                   	push   %edi
80104965:	e8 3f f6 ff ff       	call   80103fa9 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010496a:	6a 10                	push   $0x10
8010496c:	ff 75 c0             	pushl  -0x40(%ebp)
8010496f:	57                   	push   %edi
80104970:	56                   	push   %esi
80104971:	e8 06 cf ff ff       	call   8010187c <writei>
80104976:	83 c4 20             	add    $0x20,%esp
80104979:	83 f8 10             	cmp    $0x10,%eax
8010497c:	0f 85 90 00 00 00    	jne    80104a12 <sys_unlink+0x179>
  if(ip->type == T_DIR){
80104982:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104987:	0f 84 92 00 00 00    	je     80104a1f <sys_unlink+0x186>
  iunlockput(dp);
8010498d:	83 ec 0c             	sub    $0xc,%esp
80104990:	56                   	push   %esi
80104991:	e8 9e cd ff ff       	call   80101734 <iunlockput>
  ip->nlink--;
80104996:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
8010499a:	83 e8 01             	sub    $0x1,%eax
8010499d:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
801049a1:	89 1c 24             	mov    %ebx,(%esp)
801049a4:	e8 83 ca ff ff       	call   8010142c <iupdate>
  iunlockput(ip);
801049a9:	89 1c 24             	mov    %ebx,(%esp)
801049ac:	e8 83 cd ff ff       	call   80101734 <iunlockput>
  end_op();
801049b1:	e8 c4 e1 ff ff       	call   80102b7a <end_op>
  return 0;
801049b6:	83 c4 10             	add    $0x10,%esp
801049b9:	b8 00 00 00 00       	mov    $0x0,%eax
}
801049be:	8d 65 f4             	lea    -0xc(%ebp),%esp
801049c1:	5b                   	pop    %ebx
801049c2:	5e                   	pop    %esi
801049c3:	5f                   	pop    %edi
801049c4:	5d                   	pop    %ebp
801049c5:	c3                   	ret    
    end_op();
801049c6:	e8 af e1 ff ff       	call   80102b7a <end_op>
    return -1;
801049cb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801049d0:	eb ec                	jmp    801049be <sys_unlink+0x125>
    panic("unlink: nlink < 1");
801049d2:	83 ec 0c             	sub    $0xc,%esp
801049d5:	68 bc 6f 10 80       	push   $0x80106fbc
801049da:	e8 69 b9 ff ff       	call   80100348 <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
801049df:	89 d8                	mov    %ebx,%eax
801049e1:	e8 c4 f9 ff ff       	call   801043aa <isdirempty>
801049e6:	85 c0                	test   %eax,%eax
801049e8:	0f 85 6c ff ff ff    	jne    8010495a <sys_unlink+0xc1>
    iunlockput(ip);
801049ee:	83 ec 0c             	sub    $0xc,%esp
801049f1:	53                   	push   %ebx
801049f2:	e8 3d cd ff ff       	call   80101734 <iunlockput>
    goto bad;
801049f7:	83 c4 10             	add    $0x10,%esp
  iunlockput(dp);
801049fa:	83 ec 0c             	sub    $0xc,%esp
801049fd:	56                   	push   %esi
801049fe:	e8 31 cd ff ff       	call   80101734 <iunlockput>
  end_op();
80104a03:	e8 72 e1 ff ff       	call   80102b7a <end_op>
  return -1;
80104a08:	83 c4 10             	add    $0x10,%esp
80104a0b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a10:	eb ac                	jmp    801049be <sys_unlink+0x125>
    panic("unlink: writei");
80104a12:	83 ec 0c             	sub    $0xc,%esp
80104a15:	68 ce 6f 10 80       	push   $0x80106fce
80104a1a:	e8 29 b9 ff ff       	call   80100348 <panic>
    dp->nlink--;
80104a1f:	0f b7 46 56          	movzwl 0x56(%esi),%eax
80104a23:	83 e8 01             	sub    $0x1,%eax
80104a26:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
80104a2a:	83 ec 0c             	sub    $0xc,%esp
80104a2d:	56                   	push   %esi
80104a2e:	e8 f9 c9 ff ff       	call   8010142c <iupdate>
80104a33:	83 c4 10             	add    $0x10,%esp
80104a36:	e9 52 ff ff ff       	jmp    8010498d <sys_unlink+0xf4>
    return -1;
80104a3b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a40:	e9 79 ff ff ff       	jmp    801049be <sys_unlink+0x125>

80104a45 <sys_open>:

int
sys_open(void)
{
80104a45:	55                   	push   %ebp
80104a46:	89 e5                	mov    %esp,%ebp
80104a48:	57                   	push   %edi
80104a49:	56                   	push   %esi
80104a4a:	53                   	push   %ebx
80104a4b:	83 ec 24             	sub    $0x24,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80104a4e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104a51:	50                   	push   %eax
80104a52:	6a 00                	push   $0x0
80104a54:	e8 2b f8 ff ff       	call   80104284 <argstr>
80104a59:	83 c4 10             	add    $0x10,%esp
80104a5c:	85 c0                	test   %eax,%eax
80104a5e:	0f 88 30 01 00 00    	js     80104b94 <sys_open+0x14f>
80104a64:	83 ec 08             	sub    $0x8,%esp
80104a67:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104a6a:	50                   	push   %eax
80104a6b:	6a 01                	push   $0x1
80104a6d:	e8 82 f7 ff ff       	call   801041f4 <argint>
80104a72:	83 c4 10             	add    $0x10,%esp
80104a75:	85 c0                	test   %eax,%eax
80104a77:	0f 88 21 01 00 00    	js     80104b9e <sys_open+0x159>
    return -1;

  begin_op();
80104a7d:	e8 7e e0 ff ff       	call   80102b00 <begin_op>

  if(omode & O_CREATE){
80104a82:	f6 45 e1 02          	testb  $0x2,-0x1f(%ebp)
80104a86:	0f 84 84 00 00 00    	je     80104b10 <sys_open+0xcb>
    ip = create(path, T_FILE, 0, 0);
80104a8c:	83 ec 0c             	sub    $0xc,%esp
80104a8f:	6a 00                	push   $0x0
80104a91:	b9 00 00 00 00       	mov    $0x0,%ecx
80104a96:	ba 02 00 00 00       	mov    $0x2,%edx
80104a9b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104a9e:	e8 5e f9 ff ff       	call   80104401 <create>
80104aa3:	89 c6                	mov    %eax,%esi
    if(ip == 0){
80104aa5:	83 c4 10             	add    $0x10,%esp
80104aa8:	85 c0                	test   %eax,%eax
80104aaa:	74 58                	je     80104b04 <sys_open+0xbf>
      end_op();
      return -1;
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80104aac:	e8 88 c1 ff ff       	call   80100c39 <filealloc>
80104ab1:	89 c3                	mov    %eax,%ebx
80104ab3:	85 c0                	test   %eax,%eax
80104ab5:	0f 84 ae 00 00 00    	je     80104b69 <sys_open+0x124>
80104abb:	e8 b3 f8 ff ff       	call   80104373 <fdalloc>
80104ac0:	89 c7                	mov    %eax,%edi
80104ac2:	85 c0                	test   %eax,%eax
80104ac4:	0f 88 9f 00 00 00    	js     80104b69 <sys_open+0x124>
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104aca:	83 ec 0c             	sub    $0xc,%esp
80104acd:	56                   	push   %esi
80104ace:	e8 7c cb ff ff       	call   8010164f <iunlock>
  end_op();
80104ad3:	e8 a2 e0 ff ff       	call   80102b7a <end_op>

  f->type = FD_INODE;
80104ad8:	c7 03 02 00 00 00    	movl   $0x2,(%ebx)
  f->ip = ip;
80104ade:	89 73 10             	mov    %esi,0x10(%ebx)
  f->off = 0;
80104ae1:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
  f->readable = !(omode & O_WRONLY);
80104ae8:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104aeb:	83 c4 10             	add    $0x10,%esp
80104aee:	a8 01                	test   $0x1,%al
80104af0:	0f 94 43 08          	sete   0x8(%ebx)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80104af4:	a8 03                	test   $0x3,%al
80104af6:	0f 95 43 09          	setne  0x9(%ebx)
  return fd;
}
80104afa:	89 f8                	mov    %edi,%eax
80104afc:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104aff:	5b                   	pop    %ebx
80104b00:	5e                   	pop    %esi
80104b01:	5f                   	pop    %edi
80104b02:	5d                   	pop    %ebp
80104b03:	c3                   	ret    
      end_op();
80104b04:	e8 71 e0 ff ff       	call   80102b7a <end_op>
      return -1;
80104b09:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104b0e:	eb ea                	jmp    80104afa <sys_open+0xb5>
    if((ip = namei(path)) == 0){
80104b10:	83 ec 0c             	sub    $0xc,%esp
80104b13:	ff 75 e4             	pushl  -0x1c(%ebp)
80104b16:	e8 d2 d0 ff ff       	call   80101bed <namei>
80104b1b:	89 c6                	mov    %eax,%esi
80104b1d:	83 c4 10             	add    $0x10,%esp
80104b20:	85 c0                	test   %eax,%eax
80104b22:	74 39                	je     80104b5d <sys_open+0x118>
    ilock(ip);
80104b24:	83 ec 0c             	sub    $0xc,%esp
80104b27:	50                   	push   %eax
80104b28:	e8 60 ca ff ff       	call   8010158d <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80104b2d:	83 c4 10             	add    $0x10,%esp
80104b30:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
80104b35:	0f 85 71 ff ff ff    	jne    80104aac <sys_open+0x67>
80104b3b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104b3f:	0f 84 67 ff ff ff    	je     80104aac <sys_open+0x67>
      iunlockput(ip);
80104b45:	83 ec 0c             	sub    $0xc,%esp
80104b48:	56                   	push   %esi
80104b49:	e8 e6 cb ff ff       	call   80101734 <iunlockput>
      end_op();
80104b4e:	e8 27 e0 ff ff       	call   80102b7a <end_op>
      return -1;
80104b53:	83 c4 10             	add    $0x10,%esp
80104b56:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104b5b:	eb 9d                	jmp    80104afa <sys_open+0xb5>
      end_op();
80104b5d:	e8 18 e0 ff ff       	call   80102b7a <end_op>
      return -1;
80104b62:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104b67:	eb 91                	jmp    80104afa <sys_open+0xb5>
    if(f)
80104b69:	85 db                	test   %ebx,%ebx
80104b6b:	74 0c                	je     80104b79 <sys_open+0x134>
      fileclose(f);
80104b6d:	83 ec 0c             	sub    $0xc,%esp
80104b70:	53                   	push   %ebx
80104b71:	e8 69 c1 ff ff       	call   80100cdf <fileclose>
80104b76:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
80104b79:	83 ec 0c             	sub    $0xc,%esp
80104b7c:	56                   	push   %esi
80104b7d:	e8 b2 cb ff ff       	call   80101734 <iunlockput>
    end_op();
80104b82:	e8 f3 df ff ff       	call   80102b7a <end_op>
    return -1;
80104b87:	83 c4 10             	add    $0x10,%esp
80104b8a:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104b8f:	e9 66 ff ff ff       	jmp    80104afa <sys_open+0xb5>
    return -1;
80104b94:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104b99:	e9 5c ff ff ff       	jmp    80104afa <sys_open+0xb5>
80104b9e:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104ba3:	e9 52 ff ff ff       	jmp    80104afa <sys_open+0xb5>

80104ba8 <sys_mkdir>:

int
sys_mkdir(void)
{
80104ba8:	55                   	push   %ebp
80104ba9:	89 e5                	mov    %esp,%ebp
80104bab:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
80104bae:	e8 4d df ff ff       	call   80102b00 <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80104bb3:	83 ec 08             	sub    $0x8,%esp
80104bb6:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104bb9:	50                   	push   %eax
80104bba:	6a 00                	push   $0x0
80104bbc:	e8 c3 f6 ff ff       	call   80104284 <argstr>
80104bc1:	83 c4 10             	add    $0x10,%esp
80104bc4:	85 c0                	test   %eax,%eax
80104bc6:	78 36                	js     80104bfe <sys_mkdir+0x56>
80104bc8:	83 ec 0c             	sub    $0xc,%esp
80104bcb:	6a 00                	push   $0x0
80104bcd:	b9 00 00 00 00       	mov    $0x0,%ecx
80104bd2:	ba 01 00 00 00       	mov    $0x1,%edx
80104bd7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bda:	e8 22 f8 ff ff       	call   80104401 <create>
80104bdf:	83 c4 10             	add    $0x10,%esp
80104be2:	85 c0                	test   %eax,%eax
80104be4:	74 18                	je     80104bfe <sys_mkdir+0x56>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104be6:	83 ec 0c             	sub    $0xc,%esp
80104be9:	50                   	push   %eax
80104bea:	e8 45 cb ff ff       	call   80101734 <iunlockput>
  end_op();
80104bef:	e8 86 df ff ff       	call   80102b7a <end_op>
  return 0;
80104bf4:	83 c4 10             	add    $0x10,%esp
80104bf7:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104bfc:	c9                   	leave  
80104bfd:	c3                   	ret    
    end_op();
80104bfe:	e8 77 df ff ff       	call   80102b7a <end_op>
    return -1;
80104c03:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c08:	eb f2                	jmp    80104bfc <sys_mkdir+0x54>

80104c0a <sys_mknod>:

int
sys_mknod(void)
{
80104c0a:	55                   	push   %ebp
80104c0b:	89 e5                	mov    %esp,%ebp
80104c0d:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
80104c10:	e8 eb de ff ff       	call   80102b00 <begin_op>
  if((argstr(0, &path)) < 0 ||
80104c15:	83 ec 08             	sub    $0x8,%esp
80104c18:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104c1b:	50                   	push   %eax
80104c1c:	6a 00                	push   $0x0
80104c1e:	e8 61 f6 ff ff       	call   80104284 <argstr>
80104c23:	83 c4 10             	add    $0x10,%esp
80104c26:	85 c0                	test   %eax,%eax
80104c28:	78 62                	js     80104c8c <sys_mknod+0x82>
     argint(1, &major) < 0 ||
80104c2a:	83 ec 08             	sub    $0x8,%esp
80104c2d:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104c30:	50                   	push   %eax
80104c31:	6a 01                	push   $0x1
80104c33:	e8 bc f5 ff ff       	call   801041f4 <argint>
  if((argstr(0, &path)) < 0 ||
80104c38:	83 c4 10             	add    $0x10,%esp
80104c3b:	85 c0                	test   %eax,%eax
80104c3d:	78 4d                	js     80104c8c <sys_mknod+0x82>
     argint(2, &minor) < 0 ||
80104c3f:	83 ec 08             	sub    $0x8,%esp
80104c42:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104c45:	50                   	push   %eax
80104c46:	6a 02                	push   $0x2
80104c48:	e8 a7 f5 ff ff       	call   801041f4 <argint>
     argint(1, &major) < 0 ||
80104c4d:	83 c4 10             	add    $0x10,%esp
80104c50:	85 c0                	test   %eax,%eax
80104c52:	78 38                	js     80104c8c <sys_mknod+0x82>
     (ip = create(path, T_DEV, major, minor)) == 0){
80104c54:	0f bf 45 ec          	movswl -0x14(%ebp),%eax
80104c58:	0f bf 4d f0          	movswl -0x10(%ebp),%ecx
     argint(2, &minor) < 0 ||
80104c5c:	83 ec 0c             	sub    $0xc,%esp
80104c5f:	50                   	push   %eax
80104c60:	ba 03 00 00 00       	mov    $0x3,%edx
80104c65:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c68:	e8 94 f7 ff ff       	call   80104401 <create>
80104c6d:	83 c4 10             	add    $0x10,%esp
80104c70:	85 c0                	test   %eax,%eax
80104c72:	74 18                	je     80104c8c <sys_mknod+0x82>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104c74:	83 ec 0c             	sub    $0xc,%esp
80104c77:	50                   	push   %eax
80104c78:	e8 b7 ca ff ff       	call   80101734 <iunlockput>
  end_op();
80104c7d:	e8 f8 de ff ff       	call   80102b7a <end_op>
  return 0;
80104c82:	83 c4 10             	add    $0x10,%esp
80104c85:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104c8a:	c9                   	leave  
80104c8b:	c3                   	ret    
    end_op();
80104c8c:	e8 e9 de ff ff       	call   80102b7a <end_op>
    return -1;
80104c91:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c96:	eb f2                	jmp    80104c8a <sys_mknod+0x80>

80104c98 <sys_chdir>:

int
sys_chdir(void)
{
80104c98:	55                   	push   %ebp
80104c99:	89 e5                	mov    %esp,%ebp
80104c9b:	56                   	push   %esi
80104c9c:	53                   	push   %ebx
80104c9d:	83 ec 10             	sub    $0x10,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
80104ca0:	e8 b6 e8 ff ff       	call   8010355b <myproc>
80104ca5:	89 c6                	mov    %eax,%esi
  
  begin_op();
80104ca7:	e8 54 de ff ff       	call   80102b00 <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80104cac:	83 ec 08             	sub    $0x8,%esp
80104caf:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104cb2:	50                   	push   %eax
80104cb3:	6a 00                	push   $0x0
80104cb5:	e8 ca f5 ff ff       	call   80104284 <argstr>
80104cba:	83 c4 10             	add    $0x10,%esp
80104cbd:	85 c0                	test   %eax,%eax
80104cbf:	78 52                	js     80104d13 <sys_chdir+0x7b>
80104cc1:	83 ec 0c             	sub    $0xc,%esp
80104cc4:	ff 75 f4             	pushl  -0xc(%ebp)
80104cc7:	e8 21 cf ff ff       	call   80101bed <namei>
80104ccc:	89 c3                	mov    %eax,%ebx
80104cce:	83 c4 10             	add    $0x10,%esp
80104cd1:	85 c0                	test   %eax,%eax
80104cd3:	74 3e                	je     80104d13 <sys_chdir+0x7b>
    end_op();
    return -1;
  }
  ilock(ip);
80104cd5:	83 ec 0c             	sub    $0xc,%esp
80104cd8:	50                   	push   %eax
80104cd9:	e8 af c8 ff ff       	call   8010158d <ilock>
  if(ip->type != T_DIR){
80104cde:	83 c4 10             	add    $0x10,%esp
80104ce1:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104ce6:	75 37                	jne    80104d1f <sys_chdir+0x87>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104ce8:	83 ec 0c             	sub    $0xc,%esp
80104ceb:	53                   	push   %ebx
80104cec:	e8 5e c9 ff ff       	call   8010164f <iunlock>
  iput(curproc->cwd);
80104cf1:	83 c4 04             	add    $0x4,%esp
80104cf4:	ff 76 68             	pushl  0x68(%esi)
80104cf7:	e8 98 c9 ff ff       	call   80101694 <iput>
  end_op();
80104cfc:	e8 79 de ff ff       	call   80102b7a <end_op>
  curproc->cwd = ip;
80104d01:	89 5e 68             	mov    %ebx,0x68(%esi)
  return 0;
80104d04:	83 c4 10             	add    $0x10,%esp
80104d07:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104d0c:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104d0f:	5b                   	pop    %ebx
80104d10:	5e                   	pop    %esi
80104d11:	5d                   	pop    %ebp
80104d12:	c3                   	ret    
    end_op();
80104d13:	e8 62 de ff ff       	call   80102b7a <end_op>
    return -1;
80104d18:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d1d:	eb ed                	jmp    80104d0c <sys_chdir+0x74>
    iunlockput(ip);
80104d1f:	83 ec 0c             	sub    $0xc,%esp
80104d22:	53                   	push   %ebx
80104d23:	e8 0c ca ff ff       	call   80101734 <iunlockput>
    end_op();
80104d28:	e8 4d de ff ff       	call   80102b7a <end_op>
    return -1;
80104d2d:	83 c4 10             	add    $0x10,%esp
80104d30:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d35:	eb d5                	jmp    80104d0c <sys_chdir+0x74>

80104d37 <sys_exec>:

int
sys_exec(void)
{
80104d37:	55                   	push   %ebp
80104d38:	89 e5                	mov    %esp,%ebp
80104d3a:	53                   	push   %ebx
80104d3b:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80104d41:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d44:	50                   	push   %eax
80104d45:	6a 00                	push   $0x0
80104d47:	e8 38 f5 ff ff       	call   80104284 <argstr>
80104d4c:	83 c4 10             	add    $0x10,%esp
80104d4f:	85 c0                	test   %eax,%eax
80104d51:	0f 88 a8 00 00 00    	js     80104dff <sys_exec+0xc8>
80104d57:	83 ec 08             	sub    $0x8,%esp
80104d5a:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80104d60:	50                   	push   %eax
80104d61:	6a 01                	push   $0x1
80104d63:	e8 8c f4 ff ff       	call   801041f4 <argint>
80104d68:	83 c4 10             	add    $0x10,%esp
80104d6b:	85 c0                	test   %eax,%eax
80104d6d:	0f 88 93 00 00 00    	js     80104e06 <sys_exec+0xcf>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
80104d73:	83 ec 04             	sub    $0x4,%esp
80104d76:	68 80 00 00 00       	push   $0x80
80104d7b:	6a 00                	push   $0x0
80104d7d:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104d83:	50                   	push   %eax
80104d84:	e8 20 f2 ff ff       	call   80103fa9 <memset>
80104d89:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
80104d8c:	bb 00 00 00 00       	mov    $0x0,%ebx
    if(i >= NELEM(argv))
80104d91:	83 fb 1f             	cmp    $0x1f,%ebx
80104d94:	77 77                	ja     80104e0d <sys_exec+0xd6>
      return -1;
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80104d96:	83 ec 08             	sub    $0x8,%esp
80104d99:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80104d9f:	50                   	push   %eax
80104da0:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
80104da6:	8d 04 98             	lea    (%eax,%ebx,4),%eax
80104da9:	50                   	push   %eax
80104daa:	e8 c9 f3 ff ff       	call   80104178 <fetchint>
80104daf:	83 c4 10             	add    $0x10,%esp
80104db2:	85 c0                	test   %eax,%eax
80104db4:	78 5e                	js     80104e14 <sys_exec+0xdd>
      return -1;
    if(uarg == 0){
80104db6:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80104dbc:	85 c0                	test   %eax,%eax
80104dbe:	74 1d                	je     80104ddd <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80104dc0:	83 ec 08             	sub    $0x8,%esp
80104dc3:	8d 94 9d 74 ff ff ff 	lea    -0x8c(%ebp,%ebx,4),%edx
80104dca:	52                   	push   %edx
80104dcb:	50                   	push   %eax
80104dcc:	e8 e3 f3 ff ff       	call   801041b4 <fetchstr>
80104dd1:	83 c4 10             	add    $0x10,%esp
80104dd4:	85 c0                	test   %eax,%eax
80104dd6:	78 46                	js     80104e1e <sys_exec+0xe7>
  for(i=0;; i++){
80104dd8:	83 c3 01             	add    $0x1,%ebx
    if(i >= NELEM(argv))
80104ddb:	eb b4                	jmp    80104d91 <sys_exec+0x5a>
      argv[i] = 0;
80104ddd:	c7 84 9d 74 ff ff ff 	movl   $0x0,-0x8c(%ebp,%ebx,4)
80104de4:	00 00 00 00 
      return -1;
  }
  return exec(path, argv);
80104de8:	83 ec 08             	sub    $0x8,%esp
80104deb:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104df1:	50                   	push   %eax
80104df2:	ff 75 f4             	pushl  -0xc(%ebp)
80104df5:	e8 d8 ba ff ff       	call   801008d2 <exec>
80104dfa:	83 c4 10             	add    $0x10,%esp
80104dfd:	eb 1a                	jmp    80104e19 <sys_exec+0xe2>
    return -1;
80104dff:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e04:	eb 13                	jmp    80104e19 <sys_exec+0xe2>
80104e06:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e0b:	eb 0c                	jmp    80104e19 <sys_exec+0xe2>
      return -1;
80104e0d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e12:	eb 05                	jmp    80104e19 <sys_exec+0xe2>
      return -1;
80104e14:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104e19:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104e1c:	c9                   	leave  
80104e1d:	c3                   	ret    
      return -1;
80104e1e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e23:	eb f4                	jmp    80104e19 <sys_exec+0xe2>

80104e25 <sys_pipe>:

int
sys_pipe(void)
{
80104e25:	55                   	push   %ebp
80104e26:	89 e5                	mov    %esp,%ebp
80104e28:	53                   	push   %ebx
80104e29:	83 ec 18             	sub    $0x18,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80104e2c:	6a 08                	push   $0x8
80104e2e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104e31:	50                   	push   %eax
80104e32:	6a 00                	push   $0x0
80104e34:	e8 e3 f3 ff ff       	call   8010421c <argptr>
80104e39:	83 c4 10             	add    $0x10,%esp
80104e3c:	85 c0                	test   %eax,%eax
80104e3e:	78 77                	js     80104eb7 <sys_pipe+0x92>
    return -1;
  if(pipealloc(&rf, &wf) < 0)
80104e40:	83 ec 08             	sub    $0x8,%esp
80104e43:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104e46:	50                   	push   %eax
80104e47:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104e4a:	50                   	push   %eax
80104e4b:	e8 3c e2 ff ff       	call   8010308c <pipealloc>
80104e50:	83 c4 10             	add    $0x10,%esp
80104e53:	85 c0                	test   %eax,%eax
80104e55:	78 67                	js     80104ebe <sys_pipe+0x99>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80104e57:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104e5a:	e8 14 f5 ff ff       	call   80104373 <fdalloc>
80104e5f:	89 c3                	mov    %eax,%ebx
80104e61:	85 c0                	test   %eax,%eax
80104e63:	78 21                	js     80104e86 <sys_pipe+0x61>
80104e65:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104e68:	e8 06 f5 ff ff       	call   80104373 <fdalloc>
80104e6d:	85 c0                	test   %eax,%eax
80104e6f:	78 15                	js     80104e86 <sys_pipe+0x61>
      myproc()->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  fd[0] = fd0;
80104e71:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104e74:	89 1a                	mov    %ebx,(%edx)
  fd[1] = fd1;
80104e76:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104e79:	89 42 04             	mov    %eax,0x4(%edx)
  return 0;
80104e7c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104e81:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104e84:	c9                   	leave  
80104e85:	c3                   	ret    
    if(fd0 >= 0)
80104e86:	85 db                	test   %ebx,%ebx
80104e88:	78 0d                	js     80104e97 <sys_pipe+0x72>
      myproc()->ofile[fd0] = 0;
80104e8a:	e8 cc e6 ff ff       	call   8010355b <myproc>
80104e8f:	c7 44 98 28 00 00 00 	movl   $0x0,0x28(%eax,%ebx,4)
80104e96:	00 
    fileclose(rf);
80104e97:	83 ec 0c             	sub    $0xc,%esp
80104e9a:	ff 75 f0             	pushl  -0x10(%ebp)
80104e9d:	e8 3d be ff ff       	call   80100cdf <fileclose>
    fileclose(wf);
80104ea2:	83 c4 04             	add    $0x4,%esp
80104ea5:	ff 75 ec             	pushl  -0x14(%ebp)
80104ea8:	e8 32 be ff ff       	call   80100cdf <fileclose>
    return -1;
80104ead:	83 c4 10             	add    $0x10,%esp
80104eb0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104eb5:	eb ca                	jmp    80104e81 <sys_pipe+0x5c>
    return -1;
80104eb7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ebc:	eb c3                	jmp    80104e81 <sys_pipe+0x5c>
    return -1;
80104ebe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ec3:	eb bc                	jmp    80104e81 <sys_pipe+0x5c>

80104ec5 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80104ec5:	55                   	push   %ebp
80104ec6:	89 e5                	mov    %esp,%ebp
80104ec8:	83 ec 08             	sub    $0x8,%esp
  return fork();
80104ecb:	e8 03 e8 ff ff       	call   801036d3 <fork>
}
80104ed0:	c9                   	leave  
80104ed1:	c3                   	ret    

80104ed2 <sys_exit>:

int
sys_exit(void)
{
80104ed2:	55                   	push   %ebp
80104ed3:	89 e5                	mov    %esp,%ebp
80104ed5:	83 ec 08             	sub    $0x8,%esp
  exit();
80104ed8:	e8 2d ea ff ff       	call   8010390a <exit>
  return 0;  // not reached
}
80104edd:	b8 00 00 00 00       	mov    $0x0,%eax
80104ee2:	c9                   	leave  
80104ee3:	c3                   	ret    

80104ee4 <sys_wait>:

int
sys_wait(void)
{
80104ee4:	55                   	push   %ebp
80104ee5:	89 e5                	mov    %esp,%ebp
80104ee7:	83 ec 08             	sub    $0x8,%esp
  return wait();
80104eea:	e8 a4 eb ff ff       	call   80103a93 <wait>
}
80104eef:	c9                   	leave  
80104ef0:	c3                   	ret    

80104ef1 <sys_kill>:

int
sys_kill(void)
{
80104ef1:	55                   	push   %ebp
80104ef2:	89 e5                	mov    %esp,%ebp
80104ef4:	83 ec 20             	sub    $0x20,%esp
  int pid;

  if(argint(0, &pid) < 0)
80104ef7:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104efa:	50                   	push   %eax
80104efb:	6a 00                	push   $0x0
80104efd:	e8 f2 f2 ff ff       	call   801041f4 <argint>
80104f02:	83 c4 10             	add    $0x10,%esp
80104f05:	85 c0                	test   %eax,%eax
80104f07:	78 10                	js     80104f19 <sys_kill+0x28>
    return -1;
  return kill(pid);
80104f09:	83 ec 0c             	sub    $0xc,%esp
80104f0c:	ff 75 f4             	pushl  -0xc(%ebp)
80104f0f:	e8 7c ec ff ff       	call   80103b90 <kill>
80104f14:	83 c4 10             	add    $0x10,%esp
}
80104f17:	c9                   	leave  
80104f18:	c3                   	ret    
    return -1;
80104f19:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f1e:	eb f7                	jmp    80104f17 <sys_kill+0x26>

80104f20 <sys_dump_physmem>:

int
sys_dump_physmem(void)
{
80104f20:	55                   	push   %ebp
80104f21:	89 e5                	mov    %esp,%ebp
80104f23:	83 ec 20             	sub    $0x20,%esp
  int *frames;
  int *pids;
  int numframes;

  if(argint(2, &numframes) < 0)
80104f26:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104f29:	50                   	push   %eax
80104f2a:	6a 02                	push   $0x2
80104f2c:	e8 c3 f2 ff ff       	call   801041f4 <argint>
80104f31:	83 c4 10             	add    $0x10,%esp
80104f34:	85 c0                	test   %eax,%eax
80104f36:	78 4e                	js     80104f86 <sys_dump_physmem+0x66>
    return -1;
  if(argptr(0, (void *)&frames, numframes*sizeof(frames)) < 0)
80104f38:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104f3b:	c1 e0 02             	shl    $0x2,%eax
80104f3e:	83 ec 04             	sub    $0x4,%esp
80104f41:	50                   	push   %eax
80104f42:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104f45:	50                   	push   %eax
80104f46:	6a 00                	push   $0x0
80104f48:	e8 cf f2 ff ff       	call   8010421c <argptr>
80104f4d:	83 c4 10             	add    $0x10,%esp
80104f50:	85 c0                	test   %eax,%eax
80104f52:	78 39                	js     80104f8d <sys_dump_physmem+0x6d>
    return -1;
  if(argptr(1, (void *)&pids, numframes*sizeof(pids)) < 0)
80104f54:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104f57:	c1 e0 02             	shl    $0x2,%eax
80104f5a:	83 ec 04             	sub    $0x4,%esp
80104f5d:	50                   	push   %eax
80104f5e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104f61:	50                   	push   %eax
80104f62:	6a 01                	push   $0x1
80104f64:	e8 b3 f2 ff ff       	call   8010421c <argptr>
80104f69:	83 c4 10             	add    $0x10,%esp
80104f6c:	85 c0                	test   %eax,%eax
80104f6e:	78 24                	js     80104f94 <sys_dump_physmem+0x74>
    return -1;
  return dump_physmem(frames, pids, numframes);
80104f70:	83 ec 04             	sub    $0x4,%esp
80104f73:	ff 75 ec             	pushl  -0x14(%ebp)
80104f76:	ff 75 f0             	pushl  -0x10(%ebp)
80104f79:	ff 75 f4             	pushl  -0xc(%ebp)
80104f7c:	e8 ea d3 ff ff       	call   8010236b <dump_physmem>
80104f81:	83 c4 10             	add    $0x10,%esp
}
80104f84:	c9                   	leave  
80104f85:	c3                   	ret    
    return -1;
80104f86:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f8b:	eb f7                	jmp    80104f84 <sys_dump_physmem+0x64>
    return -1;
80104f8d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f92:	eb f0                	jmp    80104f84 <sys_dump_physmem+0x64>
    return -1;
80104f94:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f99:	eb e9                	jmp    80104f84 <sys_dump_physmem+0x64>

80104f9b <sys_getpid>:

int
sys_getpid(void)
{
80104f9b:	55                   	push   %ebp
80104f9c:	89 e5                	mov    %esp,%ebp
80104f9e:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
80104fa1:	e8 b5 e5 ff ff       	call   8010355b <myproc>
80104fa6:	8b 40 10             	mov    0x10(%eax),%eax
}
80104fa9:	c9                   	leave  
80104faa:	c3                   	ret    

80104fab <sys_sbrk>:

int
sys_sbrk(void)
{
80104fab:	55                   	push   %ebp
80104fac:	89 e5                	mov    %esp,%ebp
80104fae:	53                   	push   %ebx
80104faf:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80104fb2:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104fb5:	50                   	push   %eax
80104fb6:	6a 00                	push   $0x0
80104fb8:	e8 37 f2 ff ff       	call   801041f4 <argint>
80104fbd:	83 c4 10             	add    $0x10,%esp
80104fc0:	85 c0                	test   %eax,%eax
80104fc2:	78 27                	js     80104feb <sys_sbrk+0x40>
    return -1;
  addr = myproc()->sz;
80104fc4:	e8 92 e5 ff ff       	call   8010355b <myproc>
80104fc9:	8b 18                	mov    (%eax),%ebx
  if(growproc(n) < 0)
80104fcb:	83 ec 0c             	sub    $0xc,%esp
80104fce:	ff 75 f4             	pushl  -0xc(%ebp)
80104fd1:	e8 90 e6 ff ff       	call   80103666 <growproc>
80104fd6:	83 c4 10             	add    $0x10,%esp
80104fd9:	85 c0                	test   %eax,%eax
80104fdb:	78 07                	js     80104fe4 <sys_sbrk+0x39>
    return -1;
  return addr;
}
80104fdd:	89 d8                	mov    %ebx,%eax
80104fdf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104fe2:	c9                   	leave  
80104fe3:	c3                   	ret    
    return -1;
80104fe4:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104fe9:	eb f2                	jmp    80104fdd <sys_sbrk+0x32>
    return -1;
80104feb:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104ff0:	eb eb                	jmp    80104fdd <sys_sbrk+0x32>

80104ff2 <sys_sleep>:

int
sys_sleep(void)
{
80104ff2:	55                   	push   %ebp
80104ff3:	89 e5                	mov    %esp,%ebp
80104ff5:	53                   	push   %ebx
80104ff6:	83 ec 1c             	sub    $0x1c,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
80104ff9:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104ffc:	50                   	push   %eax
80104ffd:	6a 00                	push   $0x0
80104fff:	e8 f0 f1 ff ff       	call   801041f4 <argint>
80105004:	83 c4 10             	add    $0x10,%esp
80105007:	85 c0                	test   %eax,%eax
80105009:	78 75                	js     80105080 <sys_sleep+0x8e>
    return -1;
  acquire(&tickslock);
8010500b:	83 ec 0c             	sub    $0xc,%esp
8010500e:	68 a0 4c 19 80       	push   $0x80194ca0
80105013:	e8 e5 ee ff ff       	call   80103efd <acquire>
  ticks0 = ticks;
80105018:	8b 1d e0 54 19 80    	mov    0x801954e0,%ebx
  while(ticks - ticks0 < n){
8010501e:	83 c4 10             	add    $0x10,%esp
80105021:	a1 e0 54 19 80       	mov    0x801954e0,%eax
80105026:	29 d8                	sub    %ebx,%eax
80105028:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010502b:	73 39                	jae    80105066 <sys_sleep+0x74>
    if(myproc()->killed){
8010502d:	e8 29 e5 ff ff       	call   8010355b <myproc>
80105032:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105036:	75 17                	jne    8010504f <sys_sleep+0x5d>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
80105038:	83 ec 08             	sub    $0x8,%esp
8010503b:	68 a0 4c 19 80       	push   $0x80194ca0
80105040:	68 e0 54 19 80       	push   $0x801954e0
80105045:	e8 b8 e9 ff ff       	call   80103a02 <sleep>
8010504a:	83 c4 10             	add    $0x10,%esp
8010504d:	eb d2                	jmp    80105021 <sys_sleep+0x2f>
      release(&tickslock);
8010504f:	83 ec 0c             	sub    $0xc,%esp
80105052:	68 a0 4c 19 80       	push   $0x80194ca0
80105057:	e8 06 ef ff ff       	call   80103f62 <release>
      return -1;
8010505c:	83 c4 10             	add    $0x10,%esp
8010505f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105064:	eb 15                	jmp    8010507b <sys_sleep+0x89>
  }
  release(&tickslock);
80105066:	83 ec 0c             	sub    $0xc,%esp
80105069:	68 a0 4c 19 80       	push   $0x80194ca0
8010506e:	e8 ef ee ff ff       	call   80103f62 <release>
  return 0;
80105073:	83 c4 10             	add    $0x10,%esp
80105076:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010507b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010507e:	c9                   	leave  
8010507f:	c3                   	ret    
    return -1;
80105080:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105085:	eb f4                	jmp    8010507b <sys_sleep+0x89>

80105087 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80105087:	55                   	push   %ebp
80105088:	89 e5                	mov    %esp,%ebp
8010508a:	53                   	push   %ebx
8010508b:	83 ec 10             	sub    $0x10,%esp
  uint xticks;

  acquire(&tickslock);
8010508e:	68 a0 4c 19 80       	push   $0x80194ca0
80105093:	e8 65 ee ff ff       	call   80103efd <acquire>
  xticks = ticks;
80105098:	8b 1d e0 54 19 80    	mov    0x801954e0,%ebx
  release(&tickslock);
8010509e:	c7 04 24 a0 4c 19 80 	movl   $0x80194ca0,(%esp)
801050a5:	e8 b8 ee ff ff       	call   80103f62 <release>
  return xticks;
}
801050aa:	89 d8                	mov    %ebx,%eax
801050ac:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801050af:	c9                   	leave  
801050b0:	c3                   	ret    

801050b1 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
801050b1:	1e                   	push   %ds
  pushl %es
801050b2:	06                   	push   %es
  pushl %fs
801050b3:	0f a0                	push   %fs
  pushl %gs
801050b5:	0f a8                	push   %gs
  pushal
801050b7:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
801050b8:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
801050bc:	8e d8                	mov    %eax,%ds
  movw %ax, %es
801050be:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
801050c0:	54                   	push   %esp
  call trap
801050c1:	e8 e3 00 00 00       	call   801051a9 <trap>
  addl $4, %esp
801050c6:	83 c4 04             	add    $0x4,%esp

801050c9 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
801050c9:	61                   	popa   
  popl %gs
801050ca:	0f a9                	pop    %gs
  popl %fs
801050cc:	0f a1                	pop    %fs
  popl %es
801050ce:	07                   	pop    %es
  popl %ds
801050cf:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
801050d0:	83 c4 08             	add    $0x8,%esp
  iret
801050d3:	cf                   	iret   

801050d4 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
801050d4:	55                   	push   %ebp
801050d5:	89 e5                	mov    %esp,%ebp
801050d7:	83 ec 08             	sub    $0x8,%esp
  int i;

  for(i = 0; i < 256; i++)
801050da:	b8 00 00 00 00       	mov    $0x0,%eax
801050df:	eb 4a                	jmp    8010512b <tvinit+0x57>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
801050e1:	8b 0c 85 08 a0 10 80 	mov    -0x7fef5ff8(,%eax,4),%ecx
801050e8:	66 89 0c c5 e0 4c 19 	mov    %cx,-0x7fe6b320(,%eax,8)
801050ef:	80 
801050f0:	66 c7 04 c5 e2 4c 19 	movw   $0x8,-0x7fe6b31e(,%eax,8)
801050f7:	80 08 00 
801050fa:	c6 04 c5 e4 4c 19 80 	movb   $0x0,-0x7fe6b31c(,%eax,8)
80105101:	00 
80105102:	0f b6 14 c5 e5 4c 19 	movzbl -0x7fe6b31b(,%eax,8),%edx
80105109:	80 
8010510a:	83 e2 f0             	and    $0xfffffff0,%edx
8010510d:	83 ca 0e             	or     $0xe,%edx
80105110:	83 e2 8f             	and    $0xffffff8f,%edx
80105113:	83 ca 80             	or     $0xffffff80,%edx
80105116:	88 14 c5 e5 4c 19 80 	mov    %dl,-0x7fe6b31b(,%eax,8)
8010511d:	c1 e9 10             	shr    $0x10,%ecx
80105120:	66 89 0c c5 e6 4c 19 	mov    %cx,-0x7fe6b31a(,%eax,8)
80105127:	80 
  for(i = 0; i < 256; i++)
80105128:	83 c0 01             	add    $0x1,%eax
8010512b:	3d ff 00 00 00       	cmp    $0xff,%eax
80105130:	7e af                	jle    801050e1 <tvinit+0xd>
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80105132:	8b 15 08 a1 10 80    	mov    0x8010a108,%edx
80105138:	66 89 15 e0 4e 19 80 	mov    %dx,0x80194ee0
8010513f:	66 c7 05 e2 4e 19 80 	movw   $0x8,0x80194ee2
80105146:	08 00 
80105148:	c6 05 e4 4e 19 80 00 	movb   $0x0,0x80194ee4
8010514f:	0f b6 05 e5 4e 19 80 	movzbl 0x80194ee5,%eax
80105156:	83 c8 0f             	or     $0xf,%eax
80105159:	83 e0 ef             	and    $0xffffffef,%eax
8010515c:	83 c8 e0             	or     $0xffffffe0,%eax
8010515f:	a2 e5 4e 19 80       	mov    %al,0x80194ee5
80105164:	c1 ea 10             	shr    $0x10,%edx
80105167:	66 89 15 e6 4e 19 80 	mov    %dx,0x80194ee6

  initlock(&tickslock, "time");
8010516e:	83 ec 08             	sub    $0x8,%esp
80105171:	68 dd 6f 10 80       	push   $0x80106fdd
80105176:	68 a0 4c 19 80       	push   $0x80194ca0
8010517b:	e8 41 ec ff ff       	call   80103dc1 <initlock>
}
80105180:	83 c4 10             	add    $0x10,%esp
80105183:	c9                   	leave  
80105184:	c3                   	ret    

80105185 <idtinit>:

void
idtinit(void)
{
80105185:	55                   	push   %ebp
80105186:	89 e5                	mov    %esp,%ebp
80105188:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
8010518b:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
  pd[1] = (uint)p;
80105191:	b8 e0 4c 19 80       	mov    $0x80194ce0,%eax
80105196:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
8010519a:	c1 e8 10             	shr    $0x10,%eax
8010519d:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lidt (%0)" : : "r" (pd));
801051a1:	8d 45 fa             	lea    -0x6(%ebp),%eax
801051a4:	0f 01 18             	lidtl  (%eax)
  lidt(idt, sizeof(idt));
}
801051a7:	c9                   	leave  
801051a8:	c3                   	ret    

801051a9 <trap>:

void
trap(struct trapframe *tf)
{
801051a9:	55                   	push   %ebp
801051aa:	89 e5                	mov    %esp,%ebp
801051ac:	57                   	push   %edi
801051ad:	56                   	push   %esi
801051ae:	53                   	push   %ebx
801051af:	83 ec 1c             	sub    $0x1c,%esp
801051b2:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(tf->trapno == T_SYSCALL){
801051b5:	8b 43 30             	mov    0x30(%ebx),%eax
801051b8:	83 f8 40             	cmp    $0x40,%eax
801051bb:	74 13                	je     801051d0 <trap+0x27>
    if(myproc()->killed)
      exit();
    return;
  }

  switch(tf->trapno){
801051bd:	83 e8 20             	sub    $0x20,%eax
801051c0:	83 f8 1f             	cmp    $0x1f,%eax
801051c3:	0f 87 3a 01 00 00    	ja     80105303 <trap+0x15a>
801051c9:	ff 24 85 84 70 10 80 	jmp    *-0x7fef8f7c(,%eax,4)
    if(myproc()->killed)
801051d0:	e8 86 e3 ff ff       	call   8010355b <myproc>
801051d5:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801051d9:	75 1f                	jne    801051fa <trap+0x51>
    myproc()->tf = tf;
801051db:	e8 7b e3 ff ff       	call   8010355b <myproc>
801051e0:	89 58 18             	mov    %ebx,0x18(%eax)
    syscall();
801051e3:	e8 cf f0 ff ff       	call   801042b7 <syscall>
    if(myproc()->killed)
801051e8:	e8 6e e3 ff ff       	call   8010355b <myproc>
801051ed:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801051f1:	74 7e                	je     80105271 <trap+0xc8>
      exit();
801051f3:	e8 12 e7 ff ff       	call   8010390a <exit>
801051f8:	eb 77                	jmp    80105271 <trap+0xc8>
      exit();
801051fa:	e8 0b e7 ff ff       	call   8010390a <exit>
801051ff:	eb da                	jmp    801051db <trap+0x32>
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
80105201:	e8 3a e3 ff ff       	call   80103540 <cpuid>
80105206:	85 c0                	test   %eax,%eax
80105208:	74 6f                	je     80105279 <trap+0xd0>
      acquire(&tickslock);
      ticks++;
      wakeup(&ticks);
      release(&tickslock);
    }
    lapiceoi();
8010520a:	e8 dc d4 ff ff       	call   801026eb <lapiceoi>
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
8010520f:	e8 47 e3 ff ff       	call   8010355b <myproc>
80105214:	85 c0                	test   %eax,%eax
80105216:	74 1c                	je     80105234 <trap+0x8b>
80105218:	e8 3e e3 ff ff       	call   8010355b <myproc>
8010521d:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105221:	74 11                	je     80105234 <trap+0x8b>
80105223:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80105227:	83 e0 03             	and    $0x3,%eax
8010522a:	66 83 f8 03          	cmp    $0x3,%ax
8010522e:	0f 84 62 01 00 00    	je     80105396 <trap+0x1ed>
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
80105234:	e8 22 e3 ff ff       	call   8010355b <myproc>
80105239:	85 c0                	test   %eax,%eax
8010523b:	74 0f                	je     8010524c <trap+0xa3>
8010523d:	e8 19 e3 ff ff       	call   8010355b <myproc>
80105242:	83 78 0c 04          	cmpl   $0x4,0xc(%eax)
80105246:	0f 84 54 01 00 00    	je     801053a0 <trap+0x1f7>
     tf->trapno == T_IRQ0+IRQ_TIMER)
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
8010524c:	e8 0a e3 ff ff       	call   8010355b <myproc>
80105251:	85 c0                	test   %eax,%eax
80105253:	74 1c                	je     80105271 <trap+0xc8>
80105255:	e8 01 e3 ff ff       	call   8010355b <myproc>
8010525a:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010525e:	74 11                	je     80105271 <trap+0xc8>
80105260:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80105264:	83 e0 03             	and    $0x3,%eax
80105267:	66 83 f8 03          	cmp    $0x3,%ax
8010526b:	0f 84 43 01 00 00    	je     801053b4 <trap+0x20b>
    exit();
}
80105271:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105274:	5b                   	pop    %ebx
80105275:	5e                   	pop    %esi
80105276:	5f                   	pop    %edi
80105277:	5d                   	pop    %ebp
80105278:	c3                   	ret    
      acquire(&tickslock);
80105279:	83 ec 0c             	sub    $0xc,%esp
8010527c:	68 a0 4c 19 80       	push   $0x80194ca0
80105281:	e8 77 ec ff ff       	call   80103efd <acquire>
      ticks++;
80105286:	83 05 e0 54 19 80 01 	addl   $0x1,0x801954e0
      wakeup(&ticks);
8010528d:	c7 04 24 e0 54 19 80 	movl   $0x801954e0,(%esp)
80105294:	e8 ce e8 ff ff       	call   80103b67 <wakeup>
      release(&tickslock);
80105299:	c7 04 24 a0 4c 19 80 	movl   $0x80194ca0,(%esp)
801052a0:	e8 bd ec ff ff       	call   80103f62 <release>
801052a5:	83 c4 10             	add    $0x10,%esp
801052a8:	e9 5d ff ff ff       	jmp    8010520a <trap+0x61>
    ideintr();
801052ad:	e8 cd ca ff ff       	call   80101d7f <ideintr>
    lapiceoi();
801052b2:	e8 34 d4 ff ff       	call   801026eb <lapiceoi>
    break;
801052b7:	e9 53 ff ff ff       	jmp    8010520f <trap+0x66>
    kbdintr();
801052bc:	e8 6e d2 ff ff       	call   8010252f <kbdintr>
    lapiceoi();
801052c1:	e8 25 d4 ff ff       	call   801026eb <lapiceoi>
    break;
801052c6:	e9 44 ff ff ff       	jmp    8010520f <trap+0x66>
    uartintr();
801052cb:	e8 05 02 00 00       	call   801054d5 <uartintr>
    lapiceoi();
801052d0:	e8 16 d4 ff ff       	call   801026eb <lapiceoi>
    break;
801052d5:	e9 35 ff ff ff       	jmp    8010520f <trap+0x66>
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801052da:	8b 7b 38             	mov    0x38(%ebx),%edi
            cpuid(), tf->cs, tf->eip);
801052dd:	0f b7 73 3c          	movzwl 0x3c(%ebx),%esi
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801052e1:	e8 5a e2 ff ff       	call   80103540 <cpuid>
801052e6:	57                   	push   %edi
801052e7:	0f b7 f6             	movzwl %si,%esi
801052ea:	56                   	push   %esi
801052eb:	50                   	push   %eax
801052ec:	68 e8 6f 10 80       	push   $0x80106fe8
801052f1:	e8 15 b3 ff ff       	call   8010060b <cprintf>
    lapiceoi();
801052f6:	e8 f0 d3 ff ff       	call   801026eb <lapiceoi>
    break;
801052fb:	83 c4 10             	add    $0x10,%esp
801052fe:	e9 0c ff ff ff       	jmp    8010520f <trap+0x66>
    if(myproc() == 0 || (tf->cs&3) == 0){
80105303:	e8 53 e2 ff ff       	call   8010355b <myproc>
80105308:	85 c0                	test   %eax,%eax
8010530a:	74 5f                	je     8010536b <trap+0x1c2>
8010530c:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
80105310:	74 59                	je     8010536b <trap+0x1c2>

static inline uint
rcr2(void)
{
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80105312:	0f 20 d7             	mov    %cr2,%edi
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80105315:	8b 43 38             	mov    0x38(%ebx),%eax
80105318:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010531b:	e8 20 e2 ff ff       	call   80103540 <cpuid>
80105320:	89 45 e0             	mov    %eax,-0x20(%ebp)
80105323:	8b 53 34             	mov    0x34(%ebx),%edx
80105326:	89 55 dc             	mov    %edx,-0x24(%ebp)
80105329:	8b 73 30             	mov    0x30(%ebx),%esi
            myproc()->pid, myproc()->name, tf->trapno,
8010532c:	e8 2a e2 ff ff       	call   8010355b <myproc>
80105331:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105334:	89 4d d8             	mov    %ecx,-0x28(%ebp)
80105337:	e8 1f e2 ff ff       	call   8010355b <myproc>
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010533c:	57                   	push   %edi
8010533d:	ff 75 e4             	pushl  -0x1c(%ebp)
80105340:	ff 75 e0             	pushl  -0x20(%ebp)
80105343:	ff 75 dc             	pushl  -0x24(%ebp)
80105346:	56                   	push   %esi
80105347:	ff 75 d8             	pushl  -0x28(%ebp)
8010534a:	ff 70 10             	pushl  0x10(%eax)
8010534d:	68 40 70 10 80       	push   $0x80107040
80105352:	e8 b4 b2 ff ff       	call   8010060b <cprintf>
    myproc()->killed = 1;
80105357:	83 c4 20             	add    $0x20,%esp
8010535a:	e8 fc e1 ff ff       	call   8010355b <myproc>
8010535f:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80105366:	e9 a4 fe ff ff       	jmp    8010520f <trap+0x66>
8010536b:	0f 20 d7             	mov    %cr2,%edi
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
8010536e:	8b 73 38             	mov    0x38(%ebx),%esi
80105371:	e8 ca e1 ff ff       	call   80103540 <cpuid>
80105376:	83 ec 0c             	sub    $0xc,%esp
80105379:	57                   	push   %edi
8010537a:	56                   	push   %esi
8010537b:	50                   	push   %eax
8010537c:	ff 73 30             	pushl  0x30(%ebx)
8010537f:	68 0c 70 10 80       	push   $0x8010700c
80105384:	e8 82 b2 ff ff       	call   8010060b <cprintf>
      panic("trap");
80105389:	83 c4 14             	add    $0x14,%esp
8010538c:	68 e2 6f 10 80       	push   $0x80106fe2
80105391:	e8 b2 af ff ff       	call   80100348 <panic>
    exit();
80105396:	e8 6f e5 ff ff       	call   8010390a <exit>
8010539b:	e9 94 fe ff ff       	jmp    80105234 <trap+0x8b>
  if(myproc() && myproc()->state == RUNNING &&
801053a0:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
801053a4:	0f 85 a2 fe ff ff    	jne    8010524c <trap+0xa3>
    yield();
801053aa:	e8 21 e6 ff ff       	call   801039d0 <yield>
801053af:	e9 98 fe ff ff       	jmp    8010524c <trap+0xa3>
    exit();
801053b4:	e8 51 e5 ff ff       	call   8010390a <exit>
801053b9:	e9 b3 fe ff ff       	jmp    80105271 <trap+0xc8>

801053be <uartgetc>:
  outb(COM1+0, c);
}

static int
uartgetc(void)
{
801053be:	55                   	push   %ebp
801053bf:	89 e5                	mov    %esp,%ebp
  if(!uart)
801053c1:	83 3d c4 a5 10 80 00 	cmpl   $0x0,0x8010a5c4
801053c8:	74 15                	je     801053df <uartgetc+0x21>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801053ca:	ba fd 03 00 00       	mov    $0x3fd,%edx
801053cf:	ec                   	in     (%dx),%al
    return -1;
  if(!(inb(COM1+5) & 0x01))
801053d0:	a8 01                	test   $0x1,%al
801053d2:	74 12                	je     801053e6 <uartgetc+0x28>
801053d4:	ba f8 03 00 00       	mov    $0x3f8,%edx
801053d9:	ec                   	in     (%dx),%al
    return -1;
  return inb(COM1+0);
801053da:	0f b6 c0             	movzbl %al,%eax
}
801053dd:	5d                   	pop    %ebp
801053de:	c3                   	ret    
    return -1;
801053df:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801053e4:	eb f7                	jmp    801053dd <uartgetc+0x1f>
    return -1;
801053e6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801053eb:	eb f0                	jmp    801053dd <uartgetc+0x1f>

801053ed <uartputc>:
  if(!uart)
801053ed:	83 3d c4 a5 10 80 00 	cmpl   $0x0,0x8010a5c4
801053f4:	74 3b                	je     80105431 <uartputc+0x44>
{
801053f6:	55                   	push   %ebp
801053f7:	89 e5                	mov    %esp,%ebp
801053f9:	53                   	push   %ebx
801053fa:	83 ec 04             	sub    $0x4,%esp
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801053fd:	bb 00 00 00 00       	mov    $0x0,%ebx
80105402:	eb 10                	jmp    80105414 <uartputc+0x27>
    microdelay(10);
80105404:	83 ec 0c             	sub    $0xc,%esp
80105407:	6a 0a                	push   $0xa
80105409:	e8 fc d2 ff ff       	call   8010270a <microdelay>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
8010540e:	83 c3 01             	add    $0x1,%ebx
80105411:	83 c4 10             	add    $0x10,%esp
80105414:	83 fb 7f             	cmp    $0x7f,%ebx
80105417:	7f 0a                	jg     80105423 <uartputc+0x36>
80105419:	ba fd 03 00 00       	mov    $0x3fd,%edx
8010541e:	ec                   	in     (%dx),%al
8010541f:	a8 20                	test   $0x20,%al
80105421:	74 e1                	je     80105404 <uartputc+0x17>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80105423:	8b 45 08             	mov    0x8(%ebp),%eax
80105426:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010542b:	ee                   	out    %al,(%dx)
}
8010542c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010542f:	c9                   	leave  
80105430:	c3                   	ret    
80105431:	f3 c3                	repz ret 

80105433 <uartinit>:
{
80105433:	55                   	push   %ebp
80105434:	89 e5                	mov    %esp,%ebp
80105436:	56                   	push   %esi
80105437:	53                   	push   %ebx
80105438:	b9 00 00 00 00       	mov    $0x0,%ecx
8010543d:	ba fa 03 00 00       	mov    $0x3fa,%edx
80105442:	89 c8                	mov    %ecx,%eax
80105444:	ee                   	out    %al,(%dx)
80105445:	be fb 03 00 00       	mov    $0x3fb,%esi
8010544a:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
8010544f:	89 f2                	mov    %esi,%edx
80105451:	ee                   	out    %al,(%dx)
80105452:	b8 0c 00 00 00       	mov    $0xc,%eax
80105457:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010545c:	ee                   	out    %al,(%dx)
8010545d:	bb f9 03 00 00       	mov    $0x3f9,%ebx
80105462:	89 c8                	mov    %ecx,%eax
80105464:	89 da                	mov    %ebx,%edx
80105466:	ee                   	out    %al,(%dx)
80105467:	b8 03 00 00 00       	mov    $0x3,%eax
8010546c:	89 f2                	mov    %esi,%edx
8010546e:	ee                   	out    %al,(%dx)
8010546f:	ba fc 03 00 00       	mov    $0x3fc,%edx
80105474:	89 c8                	mov    %ecx,%eax
80105476:	ee                   	out    %al,(%dx)
80105477:	b8 01 00 00 00       	mov    $0x1,%eax
8010547c:	89 da                	mov    %ebx,%edx
8010547e:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010547f:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105484:	ec                   	in     (%dx),%al
  if(inb(COM1+5) == 0xFF)
80105485:	3c ff                	cmp    $0xff,%al
80105487:	74 45                	je     801054ce <uartinit+0x9b>
  uart = 1;
80105489:	c7 05 c4 a5 10 80 01 	movl   $0x1,0x8010a5c4
80105490:	00 00 00 
80105493:	ba fa 03 00 00       	mov    $0x3fa,%edx
80105498:	ec                   	in     (%dx),%al
80105499:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010549e:	ec                   	in     (%dx),%al
  ioapicenable(IRQ_COM1, 0);
8010549f:	83 ec 08             	sub    $0x8,%esp
801054a2:	6a 00                	push   $0x0
801054a4:	6a 04                	push   $0x4
801054a6:	e8 df ca ff ff       	call   80101f8a <ioapicenable>
  for(p="xv6...\n"; *p; p++)
801054ab:	83 c4 10             	add    $0x10,%esp
801054ae:	bb 04 71 10 80       	mov    $0x80107104,%ebx
801054b3:	eb 12                	jmp    801054c7 <uartinit+0x94>
    uartputc(*p);
801054b5:	83 ec 0c             	sub    $0xc,%esp
801054b8:	0f be c0             	movsbl %al,%eax
801054bb:	50                   	push   %eax
801054bc:	e8 2c ff ff ff       	call   801053ed <uartputc>
  for(p="xv6...\n"; *p; p++)
801054c1:	83 c3 01             	add    $0x1,%ebx
801054c4:	83 c4 10             	add    $0x10,%esp
801054c7:	0f b6 03             	movzbl (%ebx),%eax
801054ca:	84 c0                	test   %al,%al
801054cc:	75 e7                	jne    801054b5 <uartinit+0x82>
}
801054ce:	8d 65 f8             	lea    -0x8(%ebp),%esp
801054d1:	5b                   	pop    %ebx
801054d2:	5e                   	pop    %esi
801054d3:	5d                   	pop    %ebp
801054d4:	c3                   	ret    

801054d5 <uartintr>:

void
uartintr(void)
{
801054d5:	55                   	push   %ebp
801054d6:	89 e5                	mov    %esp,%ebp
801054d8:	83 ec 14             	sub    $0x14,%esp
  consoleintr(uartgetc);
801054db:	68 be 53 10 80       	push   $0x801053be
801054e0:	e8 59 b2 ff ff       	call   8010073e <consoleintr>
}
801054e5:	83 c4 10             	add    $0x10,%esp
801054e8:	c9                   	leave  
801054e9:	c3                   	ret    

801054ea <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
801054ea:	6a 00                	push   $0x0
  pushl $0
801054ec:	6a 00                	push   $0x0
  jmp alltraps
801054ee:	e9 be fb ff ff       	jmp    801050b1 <alltraps>

801054f3 <vector1>:
.globl vector1
vector1:
  pushl $0
801054f3:	6a 00                	push   $0x0
  pushl $1
801054f5:	6a 01                	push   $0x1
  jmp alltraps
801054f7:	e9 b5 fb ff ff       	jmp    801050b1 <alltraps>

801054fc <vector2>:
.globl vector2
vector2:
  pushl $0
801054fc:	6a 00                	push   $0x0
  pushl $2
801054fe:	6a 02                	push   $0x2
  jmp alltraps
80105500:	e9 ac fb ff ff       	jmp    801050b1 <alltraps>

80105505 <vector3>:
.globl vector3
vector3:
  pushl $0
80105505:	6a 00                	push   $0x0
  pushl $3
80105507:	6a 03                	push   $0x3
  jmp alltraps
80105509:	e9 a3 fb ff ff       	jmp    801050b1 <alltraps>

8010550e <vector4>:
.globl vector4
vector4:
  pushl $0
8010550e:	6a 00                	push   $0x0
  pushl $4
80105510:	6a 04                	push   $0x4
  jmp alltraps
80105512:	e9 9a fb ff ff       	jmp    801050b1 <alltraps>

80105517 <vector5>:
.globl vector5
vector5:
  pushl $0
80105517:	6a 00                	push   $0x0
  pushl $5
80105519:	6a 05                	push   $0x5
  jmp alltraps
8010551b:	e9 91 fb ff ff       	jmp    801050b1 <alltraps>

80105520 <vector6>:
.globl vector6
vector6:
  pushl $0
80105520:	6a 00                	push   $0x0
  pushl $6
80105522:	6a 06                	push   $0x6
  jmp alltraps
80105524:	e9 88 fb ff ff       	jmp    801050b1 <alltraps>

80105529 <vector7>:
.globl vector7
vector7:
  pushl $0
80105529:	6a 00                	push   $0x0
  pushl $7
8010552b:	6a 07                	push   $0x7
  jmp alltraps
8010552d:	e9 7f fb ff ff       	jmp    801050b1 <alltraps>

80105532 <vector8>:
.globl vector8
vector8:
  pushl $8
80105532:	6a 08                	push   $0x8
  jmp alltraps
80105534:	e9 78 fb ff ff       	jmp    801050b1 <alltraps>

80105539 <vector9>:
.globl vector9
vector9:
  pushl $0
80105539:	6a 00                	push   $0x0
  pushl $9
8010553b:	6a 09                	push   $0x9
  jmp alltraps
8010553d:	e9 6f fb ff ff       	jmp    801050b1 <alltraps>

80105542 <vector10>:
.globl vector10
vector10:
  pushl $10
80105542:	6a 0a                	push   $0xa
  jmp alltraps
80105544:	e9 68 fb ff ff       	jmp    801050b1 <alltraps>

80105549 <vector11>:
.globl vector11
vector11:
  pushl $11
80105549:	6a 0b                	push   $0xb
  jmp alltraps
8010554b:	e9 61 fb ff ff       	jmp    801050b1 <alltraps>

80105550 <vector12>:
.globl vector12
vector12:
  pushl $12
80105550:	6a 0c                	push   $0xc
  jmp alltraps
80105552:	e9 5a fb ff ff       	jmp    801050b1 <alltraps>

80105557 <vector13>:
.globl vector13
vector13:
  pushl $13
80105557:	6a 0d                	push   $0xd
  jmp alltraps
80105559:	e9 53 fb ff ff       	jmp    801050b1 <alltraps>

8010555e <vector14>:
.globl vector14
vector14:
  pushl $14
8010555e:	6a 0e                	push   $0xe
  jmp alltraps
80105560:	e9 4c fb ff ff       	jmp    801050b1 <alltraps>

80105565 <vector15>:
.globl vector15
vector15:
  pushl $0
80105565:	6a 00                	push   $0x0
  pushl $15
80105567:	6a 0f                	push   $0xf
  jmp alltraps
80105569:	e9 43 fb ff ff       	jmp    801050b1 <alltraps>

8010556e <vector16>:
.globl vector16
vector16:
  pushl $0
8010556e:	6a 00                	push   $0x0
  pushl $16
80105570:	6a 10                	push   $0x10
  jmp alltraps
80105572:	e9 3a fb ff ff       	jmp    801050b1 <alltraps>

80105577 <vector17>:
.globl vector17
vector17:
  pushl $17
80105577:	6a 11                	push   $0x11
  jmp alltraps
80105579:	e9 33 fb ff ff       	jmp    801050b1 <alltraps>

8010557e <vector18>:
.globl vector18
vector18:
  pushl $0
8010557e:	6a 00                	push   $0x0
  pushl $18
80105580:	6a 12                	push   $0x12
  jmp alltraps
80105582:	e9 2a fb ff ff       	jmp    801050b1 <alltraps>

80105587 <vector19>:
.globl vector19
vector19:
  pushl $0
80105587:	6a 00                	push   $0x0
  pushl $19
80105589:	6a 13                	push   $0x13
  jmp alltraps
8010558b:	e9 21 fb ff ff       	jmp    801050b1 <alltraps>

80105590 <vector20>:
.globl vector20
vector20:
  pushl $0
80105590:	6a 00                	push   $0x0
  pushl $20
80105592:	6a 14                	push   $0x14
  jmp alltraps
80105594:	e9 18 fb ff ff       	jmp    801050b1 <alltraps>

80105599 <vector21>:
.globl vector21
vector21:
  pushl $0
80105599:	6a 00                	push   $0x0
  pushl $21
8010559b:	6a 15                	push   $0x15
  jmp alltraps
8010559d:	e9 0f fb ff ff       	jmp    801050b1 <alltraps>

801055a2 <vector22>:
.globl vector22
vector22:
  pushl $0
801055a2:	6a 00                	push   $0x0
  pushl $22
801055a4:	6a 16                	push   $0x16
  jmp alltraps
801055a6:	e9 06 fb ff ff       	jmp    801050b1 <alltraps>

801055ab <vector23>:
.globl vector23
vector23:
  pushl $0
801055ab:	6a 00                	push   $0x0
  pushl $23
801055ad:	6a 17                	push   $0x17
  jmp alltraps
801055af:	e9 fd fa ff ff       	jmp    801050b1 <alltraps>

801055b4 <vector24>:
.globl vector24
vector24:
  pushl $0
801055b4:	6a 00                	push   $0x0
  pushl $24
801055b6:	6a 18                	push   $0x18
  jmp alltraps
801055b8:	e9 f4 fa ff ff       	jmp    801050b1 <alltraps>

801055bd <vector25>:
.globl vector25
vector25:
  pushl $0
801055bd:	6a 00                	push   $0x0
  pushl $25
801055bf:	6a 19                	push   $0x19
  jmp alltraps
801055c1:	e9 eb fa ff ff       	jmp    801050b1 <alltraps>

801055c6 <vector26>:
.globl vector26
vector26:
  pushl $0
801055c6:	6a 00                	push   $0x0
  pushl $26
801055c8:	6a 1a                	push   $0x1a
  jmp alltraps
801055ca:	e9 e2 fa ff ff       	jmp    801050b1 <alltraps>

801055cf <vector27>:
.globl vector27
vector27:
  pushl $0
801055cf:	6a 00                	push   $0x0
  pushl $27
801055d1:	6a 1b                	push   $0x1b
  jmp alltraps
801055d3:	e9 d9 fa ff ff       	jmp    801050b1 <alltraps>

801055d8 <vector28>:
.globl vector28
vector28:
  pushl $0
801055d8:	6a 00                	push   $0x0
  pushl $28
801055da:	6a 1c                	push   $0x1c
  jmp alltraps
801055dc:	e9 d0 fa ff ff       	jmp    801050b1 <alltraps>

801055e1 <vector29>:
.globl vector29
vector29:
  pushl $0
801055e1:	6a 00                	push   $0x0
  pushl $29
801055e3:	6a 1d                	push   $0x1d
  jmp alltraps
801055e5:	e9 c7 fa ff ff       	jmp    801050b1 <alltraps>

801055ea <vector30>:
.globl vector30
vector30:
  pushl $0
801055ea:	6a 00                	push   $0x0
  pushl $30
801055ec:	6a 1e                	push   $0x1e
  jmp alltraps
801055ee:	e9 be fa ff ff       	jmp    801050b1 <alltraps>

801055f3 <vector31>:
.globl vector31
vector31:
  pushl $0
801055f3:	6a 00                	push   $0x0
  pushl $31
801055f5:	6a 1f                	push   $0x1f
  jmp alltraps
801055f7:	e9 b5 fa ff ff       	jmp    801050b1 <alltraps>

801055fc <vector32>:
.globl vector32
vector32:
  pushl $0
801055fc:	6a 00                	push   $0x0
  pushl $32
801055fe:	6a 20                	push   $0x20
  jmp alltraps
80105600:	e9 ac fa ff ff       	jmp    801050b1 <alltraps>

80105605 <vector33>:
.globl vector33
vector33:
  pushl $0
80105605:	6a 00                	push   $0x0
  pushl $33
80105607:	6a 21                	push   $0x21
  jmp alltraps
80105609:	e9 a3 fa ff ff       	jmp    801050b1 <alltraps>

8010560e <vector34>:
.globl vector34
vector34:
  pushl $0
8010560e:	6a 00                	push   $0x0
  pushl $34
80105610:	6a 22                	push   $0x22
  jmp alltraps
80105612:	e9 9a fa ff ff       	jmp    801050b1 <alltraps>

80105617 <vector35>:
.globl vector35
vector35:
  pushl $0
80105617:	6a 00                	push   $0x0
  pushl $35
80105619:	6a 23                	push   $0x23
  jmp alltraps
8010561b:	e9 91 fa ff ff       	jmp    801050b1 <alltraps>

80105620 <vector36>:
.globl vector36
vector36:
  pushl $0
80105620:	6a 00                	push   $0x0
  pushl $36
80105622:	6a 24                	push   $0x24
  jmp alltraps
80105624:	e9 88 fa ff ff       	jmp    801050b1 <alltraps>

80105629 <vector37>:
.globl vector37
vector37:
  pushl $0
80105629:	6a 00                	push   $0x0
  pushl $37
8010562b:	6a 25                	push   $0x25
  jmp alltraps
8010562d:	e9 7f fa ff ff       	jmp    801050b1 <alltraps>

80105632 <vector38>:
.globl vector38
vector38:
  pushl $0
80105632:	6a 00                	push   $0x0
  pushl $38
80105634:	6a 26                	push   $0x26
  jmp alltraps
80105636:	e9 76 fa ff ff       	jmp    801050b1 <alltraps>

8010563b <vector39>:
.globl vector39
vector39:
  pushl $0
8010563b:	6a 00                	push   $0x0
  pushl $39
8010563d:	6a 27                	push   $0x27
  jmp alltraps
8010563f:	e9 6d fa ff ff       	jmp    801050b1 <alltraps>

80105644 <vector40>:
.globl vector40
vector40:
  pushl $0
80105644:	6a 00                	push   $0x0
  pushl $40
80105646:	6a 28                	push   $0x28
  jmp alltraps
80105648:	e9 64 fa ff ff       	jmp    801050b1 <alltraps>

8010564d <vector41>:
.globl vector41
vector41:
  pushl $0
8010564d:	6a 00                	push   $0x0
  pushl $41
8010564f:	6a 29                	push   $0x29
  jmp alltraps
80105651:	e9 5b fa ff ff       	jmp    801050b1 <alltraps>

80105656 <vector42>:
.globl vector42
vector42:
  pushl $0
80105656:	6a 00                	push   $0x0
  pushl $42
80105658:	6a 2a                	push   $0x2a
  jmp alltraps
8010565a:	e9 52 fa ff ff       	jmp    801050b1 <alltraps>

8010565f <vector43>:
.globl vector43
vector43:
  pushl $0
8010565f:	6a 00                	push   $0x0
  pushl $43
80105661:	6a 2b                	push   $0x2b
  jmp alltraps
80105663:	e9 49 fa ff ff       	jmp    801050b1 <alltraps>

80105668 <vector44>:
.globl vector44
vector44:
  pushl $0
80105668:	6a 00                	push   $0x0
  pushl $44
8010566a:	6a 2c                	push   $0x2c
  jmp alltraps
8010566c:	e9 40 fa ff ff       	jmp    801050b1 <alltraps>

80105671 <vector45>:
.globl vector45
vector45:
  pushl $0
80105671:	6a 00                	push   $0x0
  pushl $45
80105673:	6a 2d                	push   $0x2d
  jmp alltraps
80105675:	e9 37 fa ff ff       	jmp    801050b1 <alltraps>

8010567a <vector46>:
.globl vector46
vector46:
  pushl $0
8010567a:	6a 00                	push   $0x0
  pushl $46
8010567c:	6a 2e                	push   $0x2e
  jmp alltraps
8010567e:	e9 2e fa ff ff       	jmp    801050b1 <alltraps>

80105683 <vector47>:
.globl vector47
vector47:
  pushl $0
80105683:	6a 00                	push   $0x0
  pushl $47
80105685:	6a 2f                	push   $0x2f
  jmp alltraps
80105687:	e9 25 fa ff ff       	jmp    801050b1 <alltraps>

8010568c <vector48>:
.globl vector48
vector48:
  pushl $0
8010568c:	6a 00                	push   $0x0
  pushl $48
8010568e:	6a 30                	push   $0x30
  jmp alltraps
80105690:	e9 1c fa ff ff       	jmp    801050b1 <alltraps>

80105695 <vector49>:
.globl vector49
vector49:
  pushl $0
80105695:	6a 00                	push   $0x0
  pushl $49
80105697:	6a 31                	push   $0x31
  jmp alltraps
80105699:	e9 13 fa ff ff       	jmp    801050b1 <alltraps>

8010569e <vector50>:
.globl vector50
vector50:
  pushl $0
8010569e:	6a 00                	push   $0x0
  pushl $50
801056a0:	6a 32                	push   $0x32
  jmp alltraps
801056a2:	e9 0a fa ff ff       	jmp    801050b1 <alltraps>

801056a7 <vector51>:
.globl vector51
vector51:
  pushl $0
801056a7:	6a 00                	push   $0x0
  pushl $51
801056a9:	6a 33                	push   $0x33
  jmp alltraps
801056ab:	e9 01 fa ff ff       	jmp    801050b1 <alltraps>

801056b0 <vector52>:
.globl vector52
vector52:
  pushl $0
801056b0:	6a 00                	push   $0x0
  pushl $52
801056b2:	6a 34                	push   $0x34
  jmp alltraps
801056b4:	e9 f8 f9 ff ff       	jmp    801050b1 <alltraps>

801056b9 <vector53>:
.globl vector53
vector53:
  pushl $0
801056b9:	6a 00                	push   $0x0
  pushl $53
801056bb:	6a 35                	push   $0x35
  jmp alltraps
801056bd:	e9 ef f9 ff ff       	jmp    801050b1 <alltraps>

801056c2 <vector54>:
.globl vector54
vector54:
  pushl $0
801056c2:	6a 00                	push   $0x0
  pushl $54
801056c4:	6a 36                	push   $0x36
  jmp alltraps
801056c6:	e9 e6 f9 ff ff       	jmp    801050b1 <alltraps>

801056cb <vector55>:
.globl vector55
vector55:
  pushl $0
801056cb:	6a 00                	push   $0x0
  pushl $55
801056cd:	6a 37                	push   $0x37
  jmp alltraps
801056cf:	e9 dd f9 ff ff       	jmp    801050b1 <alltraps>

801056d4 <vector56>:
.globl vector56
vector56:
  pushl $0
801056d4:	6a 00                	push   $0x0
  pushl $56
801056d6:	6a 38                	push   $0x38
  jmp alltraps
801056d8:	e9 d4 f9 ff ff       	jmp    801050b1 <alltraps>

801056dd <vector57>:
.globl vector57
vector57:
  pushl $0
801056dd:	6a 00                	push   $0x0
  pushl $57
801056df:	6a 39                	push   $0x39
  jmp alltraps
801056e1:	e9 cb f9 ff ff       	jmp    801050b1 <alltraps>

801056e6 <vector58>:
.globl vector58
vector58:
  pushl $0
801056e6:	6a 00                	push   $0x0
  pushl $58
801056e8:	6a 3a                	push   $0x3a
  jmp alltraps
801056ea:	e9 c2 f9 ff ff       	jmp    801050b1 <alltraps>

801056ef <vector59>:
.globl vector59
vector59:
  pushl $0
801056ef:	6a 00                	push   $0x0
  pushl $59
801056f1:	6a 3b                	push   $0x3b
  jmp alltraps
801056f3:	e9 b9 f9 ff ff       	jmp    801050b1 <alltraps>

801056f8 <vector60>:
.globl vector60
vector60:
  pushl $0
801056f8:	6a 00                	push   $0x0
  pushl $60
801056fa:	6a 3c                	push   $0x3c
  jmp alltraps
801056fc:	e9 b0 f9 ff ff       	jmp    801050b1 <alltraps>

80105701 <vector61>:
.globl vector61
vector61:
  pushl $0
80105701:	6a 00                	push   $0x0
  pushl $61
80105703:	6a 3d                	push   $0x3d
  jmp alltraps
80105705:	e9 a7 f9 ff ff       	jmp    801050b1 <alltraps>

8010570a <vector62>:
.globl vector62
vector62:
  pushl $0
8010570a:	6a 00                	push   $0x0
  pushl $62
8010570c:	6a 3e                	push   $0x3e
  jmp alltraps
8010570e:	e9 9e f9 ff ff       	jmp    801050b1 <alltraps>

80105713 <vector63>:
.globl vector63
vector63:
  pushl $0
80105713:	6a 00                	push   $0x0
  pushl $63
80105715:	6a 3f                	push   $0x3f
  jmp alltraps
80105717:	e9 95 f9 ff ff       	jmp    801050b1 <alltraps>

8010571c <vector64>:
.globl vector64
vector64:
  pushl $0
8010571c:	6a 00                	push   $0x0
  pushl $64
8010571e:	6a 40                	push   $0x40
  jmp alltraps
80105720:	e9 8c f9 ff ff       	jmp    801050b1 <alltraps>

80105725 <vector65>:
.globl vector65
vector65:
  pushl $0
80105725:	6a 00                	push   $0x0
  pushl $65
80105727:	6a 41                	push   $0x41
  jmp alltraps
80105729:	e9 83 f9 ff ff       	jmp    801050b1 <alltraps>

8010572e <vector66>:
.globl vector66
vector66:
  pushl $0
8010572e:	6a 00                	push   $0x0
  pushl $66
80105730:	6a 42                	push   $0x42
  jmp alltraps
80105732:	e9 7a f9 ff ff       	jmp    801050b1 <alltraps>

80105737 <vector67>:
.globl vector67
vector67:
  pushl $0
80105737:	6a 00                	push   $0x0
  pushl $67
80105739:	6a 43                	push   $0x43
  jmp alltraps
8010573b:	e9 71 f9 ff ff       	jmp    801050b1 <alltraps>

80105740 <vector68>:
.globl vector68
vector68:
  pushl $0
80105740:	6a 00                	push   $0x0
  pushl $68
80105742:	6a 44                	push   $0x44
  jmp alltraps
80105744:	e9 68 f9 ff ff       	jmp    801050b1 <alltraps>

80105749 <vector69>:
.globl vector69
vector69:
  pushl $0
80105749:	6a 00                	push   $0x0
  pushl $69
8010574b:	6a 45                	push   $0x45
  jmp alltraps
8010574d:	e9 5f f9 ff ff       	jmp    801050b1 <alltraps>

80105752 <vector70>:
.globl vector70
vector70:
  pushl $0
80105752:	6a 00                	push   $0x0
  pushl $70
80105754:	6a 46                	push   $0x46
  jmp alltraps
80105756:	e9 56 f9 ff ff       	jmp    801050b1 <alltraps>

8010575b <vector71>:
.globl vector71
vector71:
  pushl $0
8010575b:	6a 00                	push   $0x0
  pushl $71
8010575d:	6a 47                	push   $0x47
  jmp alltraps
8010575f:	e9 4d f9 ff ff       	jmp    801050b1 <alltraps>

80105764 <vector72>:
.globl vector72
vector72:
  pushl $0
80105764:	6a 00                	push   $0x0
  pushl $72
80105766:	6a 48                	push   $0x48
  jmp alltraps
80105768:	e9 44 f9 ff ff       	jmp    801050b1 <alltraps>

8010576d <vector73>:
.globl vector73
vector73:
  pushl $0
8010576d:	6a 00                	push   $0x0
  pushl $73
8010576f:	6a 49                	push   $0x49
  jmp alltraps
80105771:	e9 3b f9 ff ff       	jmp    801050b1 <alltraps>

80105776 <vector74>:
.globl vector74
vector74:
  pushl $0
80105776:	6a 00                	push   $0x0
  pushl $74
80105778:	6a 4a                	push   $0x4a
  jmp alltraps
8010577a:	e9 32 f9 ff ff       	jmp    801050b1 <alltraps>

8010577f <vector75>:
.globl vector75
vector75:
  pushl $0
8010577f:	6a 00                	push   $0x0
  pushl $75
80105781:	6a 4b                	push   $0x4b
  jmp alltraps
80105783:	e9 29 f9 ff ff       	jmp    801050b1 <alltraps>

80105788 <vector76>:
.globl vector76
vector76:
  pushl $0
80105788:	6a 00                	push   $0x0
  pushl $76
8010578a:	6a 4c                	push   $0x4c
  jmp alltraps
8010578c:	e9 20 f9 ff ff       	jmp    801050b1 <alltraps>

80105791 <vector77>:
.globl vector77
vector77:
  pushl $0
80105791:	6a 00                	push   $0x0
  pushl $77
80105793:	6a 4d                	push   $0x4d
  jmp alltraps
80105795:	e9 17 f9 ff ff       	jmp    801050b1 <alltraps>

8010579a <vector78>:
.globl vector78
vector78:
  pushl $0
8010579a:	6a 00                	push   $0x0
  pushl $78
8010579c:	6a 4e                	push   $0x4e
  jmp alltraps
8010579e:	e9 0e f9 ff ff       	jmp    801050b1 <alltraps>

801057a3 <vector79>:
.globl vector79
vector79:
  pushl $0
801057a3:	6a 00                	push   $0x0
  pushl $79
801057a5:	6a 4f                	push   $0x4f
  jmp alltraps
801057a7:	e9 05 f9 ff ff       	jmp    801050b1 <alltraps>

801057ac <vector80>:
.globl vector80
vector80:
  pushl $0
801057ac:	6a 00                	push   $0x0
  pushl $80
801057ae:	6a 50                	push   $0x50
  jmp alltraps
801057b0:	e9 fc f8 ff ff       	jmp    801050b1 <alltraps>

801057b5 <vector81>:
.globl vector81
vector81:
  pushl $0
801057b5:	6a 00                	push   $0x0
  pushl $81
801057b7:	6a 51                	push   $0x51
  jmp alltraps
801057b9:	e9 f3 f8 ff ff       	jmp    801050b1 <alltraps>

801057be <vector82>:
.globl vector82
vector82:
  pushl $0
801057be:	6a 00                	push   $0x0
  pushl $82
801057c0:	6a 52                	push   $0x52
  jmp alltraps
801057c2:	e9 ea f8 ff ff       	jmp    801050b1 <alltraps>

801057c7 <vector83>:
.globl vector83
vector83:
  pushl $0
801057c7:	6a 00                	push   $0x0
  pushl $83
801057c9:	6a 53                	push   $0x53
  jmp alltraps
801057cb:	e9 e1 f8 ff ff       	jmp    801050b1 <alltraps>

801057d0 <vector84>:
.globl vector84
vector84:
  pushl $0
801057d0:	6a 00                	push   $0x0
  pushl $84
801057d2:	6a 54                	push   $0x54
  jmp alltraps
801057d4:	e9 d8 f8 ff ff       	jmp    801050b1 <alltraps>

801057d9 <vector85>:
.globl vector85
vector85:
  pushl $0
801057d9:	6a 00                	push   $0x0
  pushl $85
801057db:	6a 55                	push   $0x55
  jmp alltraps
801057dd:	e9 cf f8 ff ff       	jmp    801050b1 <alltraps>

801057e2 <vector86>:
.globl vector86
vector86:
  pushl $0
801057e2:	6a 00                	push   $0x0
  pushl $86
801057e4:	6a 56                	push   $0x56
  jmp alltraps
801057e6:	e9 c6 f8 ff ff       	jmp    801050b1 <alltraps>

801057eb <vector87>:
.globl vector87
vector87:
  pushl $0
801057eb:	6a 00                	push   $0x0
  pushl $87
801057ed:	6a 57                	push   $0x57
  jmp alltraps
801057ef:	e9 bd f8 ff ff       	jmp    801050b1 <alltraps>

801057f4 <vector88>:
.globl vector88
vector88:
  pushl $0
801057f4:	6a 00                	push   $0x0
  pushl $88
801057f6:	6a 58                	push   $0x58
  jmp alltraps
801057f8:	e9 b4 f8 ff ff       	jmp    801050b1 <alltraps>

801057fd <vector89>:
.globl vector89
vector89:
  pushl $0
801057fd:	6a 00                	push   $0x0
  pushl $89
801057ff:	6a 59                	push   $0x59
  jmp alltraps
80105801:	e9 ab f8 ff ff       	jmp    801050b1 <alltraps>

80105806 <vector90>:
.globl vector90
vector90:
  pushl $0
80105806:	6a 00                	push   $0x0
  pushl $90
80105808:	6a 5a                	push   $0x5a
  jmp alltraps
8010580a:	e9 a2 f8 ff ff       	jmp    801050b1 <alltraps>

8010580f <vector91>:
.globl vector91
vector91:
  pushl $0
8010580f:	6a 00                	push   $0x0
  pushl $91
80105811:	6a 5b                	push   $0x5b
  jmp alltraps
80105813:	e9 99 f8 ff ff       	jmp    801050b1 <alltraps>

80105818 <vector92>:
.globl vector92
vector92:
  pushl $0
80105818:	6a 00                	push   $0x0
  pushl $92
8010581a:	6a 5c                	push   $0x5c
  jmp alltraps
8010581c:	e9 90 f8 ff ff       	jmp    801050b1 <alltraps>

80105821 <vector93>:
.globl vector93
vector93:
  pushl $0
80105821:	6a 00                	push   $0x0
  pushl $93
80105823:	6a 5d                	push   $0x5d
  jmp alltraps
80105825:	e9 87 f8 ff ff       	jmp    801050b1 <alltraps>

8010582a <vector94>:
.globl vector94
vector94:
  pushl $0
8010582a:	6a 00                	push   $0x0
  pushl $94
8010582c:	6a 5e                	push   $0x5e
  jmp alltraps
8010582e:	e9 7e f8 ff ff       	jmp    801050b1 <alltraps>

80105833 <vector95>:
.globl vector95
vector95:
  pushl $0
80105833:	6a 00                	push   $0x0
  pushl $95
80105835:	6a 5f                	push   $0x5f
  jmp alltraps
80105837:	e9 75 f8 ff ff       	jmp    801050b1 <alltraps>

8010583c <vector96>:
.globl vector96
vector96:
  pushl $0
8010583c:	6a 00                	push   $0x0
  pushl $96
8010583e:	6a 60                	push   $0x60
  jmp alltraps
80105840:	e9 6c f8 ff ff       	jmp    801050b1 <alltraps>

80105845 <vector97>:
.globl vector97
vector97:
  pushl $0
80105845:	6a 00                	push   $0x0
  pushl $97
80105847:	6a 61                	push   $0x61
  jmp alltraps
80105849:	e9 63 f8 ff ff       	jmp    801050b1 <alltraps>

8010584e <vector98>:
.globl vector98
vector98:
  pushl $0
8010584e:	6a 00                	push   $0x0
  pushl $98
80105850:	6a 62                	push   $0x62
  jmp alltraps
80105852:	e9 5a f8 ff ff       	jmp    801050b1 <alltraps>

80105857 <vector99>:
.globl vector99
vector99:
  pushl $0
80105857:	6a 00                	push   $0x0
  pushl $99
80105859:	6a 63                	push   $0x63
  jmp alltraps
8010585b:	e9 51 f8 ff ff       	jmp    801050b1 <alltraps>

80105860 <vector100>:
.globl vector100
vector100:
  pushl $0
80105860:	6a 00                	push   $0x0
  pushl $100
80105862:	6a 64                	push   $0x64
  jmp alltraps
80105864:	e9 48 f8 ff ff       	jmp    801050b1 <alltraps>

80105869 <vector101>:
.globl vector101
vector101:
  pushl $0
80105869:	6a 00                	push   $0x0
  pushl $101
8010586b:	6a 65                	push   $0x65
  jmp alltraps
8010586d:	e9 3f f8 ff ff       	jmp    801050b1 <alltraps>

80105872 <vector102>:
.globl vector102
vector102:
  pushl $0
80105872:	6a 00                	push   $0x0
  pushl $102
80105874:	6a 66                	push   $0x66
  jmp alltraps
80105876:	e9 36 f8 ff ff       	jmp    801050b1 <alltraps>

8010587b <vector103>:
.globl vector103
vector103:
  pushl $0
8010587b:	6a 00                	push   $0x0
  pushl $103
8010587d:	6a 67                	push   $0x67
  jmp alltraps
8010587f:	e9 2d f8 ff ff       	jmp    801050b1 <alltraps>

80105884 <vector104>:
.globl vector104
vector104:
  pushl $0
80105884:	6a 00                	push   $0x0
  pushl $104
80105886:	6a 68                	push   $0x68
  jmp alltraps
80105888:	e9 24 f8 ff ff       	jmp    801050b1 <alltraps>

8010588d <vector105>:
.globl vector105
vector105:
  pushl $0
8010588d:	6a 00                	push   $0x0
  pushl $105
8010588f:	6a 69                	push   $0x69
  jmp alltraps
80105891:	e9 1b f8 ff ff       	jmp    801050b1 <alltraps>

80105896 <vector106>:
.globl vector106
vector106:
  pushl $0
80105896:	6a 00                	push   $0x0
  pushl $106
80105898:	6a 6a                	push   $0x6a
  jmp alltraps
8010589a:	e9 12 f8 ff ff       	jmp    801050b1 <alltraps>

8010589f <vector107>:
.globl vector107
vector107:
  pushl $0
8010589f:	6a 00                	push   $0x0
  pushl $107
801058a1:	6a 6b                	push   $0x6b
  jmp alltraps
801058a3:	e9 09 f8 ff ff       	jmp    801050b1 <alltraps>

801058a8 <vector108>:
.globl vector108
vector108:
  pushl $0
801058a8:	6a 00                	push   $0x0
  pushl $108
801058aa:	6a 6c                	push   $0x6c
  jmp alltraps
801058ac:	e9 00 f8 ff ff       	jmp    801050b1 <alltraps>

801058b1 <vector109>:
.globl vector109
vector109:
  pushl $0
801058b1:	6a 00                	push   $0x0
  pushl $109
801058b3:	6a 6d                	push   $0x6d
  jmp alltraps
801058b5:	e9 f7 f7 ff ff       	jmp    801050b1 <alltraps>

801058ba <vector110>:
.globl vector110
vector110:
  pushl $0
801058ba:	6a 00                	push   $0x0
  pushl $110
801058bc:	6a 6e                	push   $0x6e
  jmp alltraps
801058be:	e9 ee f7 ff ff       	jmp    801050b1 <alltraps>

801058c3 <vector111>:
.globl vector111
vector111:
  pushl $0
801058c3:	6a 00                	push   $0x0
  pushl $111
801058c5:	6a 6f                	push   $0x6f
  jmp alltraps
801058c7:	e9 e5 f7 ff ff       	jmp    801050b1 <alltraps>

801058cc <vector112>:
.globl vector112
vector112:
  pushl $0
801058cc:	6a 00                	push   $0x0
  pushl $112
801058ce:	6a 70                	push   $0x70
  jmp alltraps
801058d0:	e9 dc f7 ff ff       	jmp    801050b1 <alltraps>

801058d5 <vector113>:
.globl vector113
vector113:
  pushl $0
801058d5:	6a 00                	push   $0x0
  pushl $113
801058d7:	6a 71                	push   $0x71
  jmp alltraps
801058d9:	e9 d3 f7 ff ff       	jmp    801050b1 <alltraps>

801058de <vector114>:
.globl vector114
vector114:
  pushl $0
801058de:	6a 00                	push   $0x0
  pushl $114
801058e0:	6a 72                	push   $0x72
  jmp alltraps
801058e2:	e9 ca f7 ff ff       	jmp    801050b1 <alltraps>

801058e7 <vector115>:
.globl vector115
vector115:
  pushl $0
801058e7:	6a 00                	push   $0x0
  pushl $115
801058e9:	6a 73                	push   $0x73
  jmp alltraps
801058eb:	e9 c1 f7 ff ff       	jmp    801050b1 <alltraps>

801058f0 <vector116>:
.globl vector116
vector116:
  pushl $0
801058f0:	6a 00                	push   $0x0
  pushl $116
801058f2:	6a 74                	push   $0x74
  jmp alltraps
801058f4:	e9 b8 f7 ff ff       	jmp    801050b1 <alltraps>

801058f9 <vector117>:
.globl vector117
vector117:
  pushl $0
801058f9:	6a 00                	push   $0x0
  pushl $117
801058fb:	6a 75                	push   $0x75
  jmp alltraps
801058fd:	e9 af f7 ff ff       	jmp    801050b1 <alltraps>

80105902 <vector118>:
.globl vector118
vector118:
  pushl $0
80105902:	6a 00                	push   $0x0
  pushl $118
80105904:	6a 76                	push   $0x76
  jmp alltraps
80105906:	e9 a6 f7 ff ff       	jmp    801050b1 <alltraps>

8010590b <vector119>:
.globl vector119
vector119:
  pushl $0
8010590b:	6a 00                	push   $0x0
  pushl $119
8010590d:	6a 77                	push   $0x77
  jmp alltraps
8010590f:	e9 9d f7 ff ff       	jmp    801050b1 <alltraps>

80105914 <vector120>:
.globl vector120
vector120:
  pushl $0
80105914:	6a 00                	push   $0x0
  pushl $120
80105916:	6a 78                	push   $0x78
  jmp alltraps
80105918:	e9 94 f7 ff ff       	jmp    801050b1 <alltraps>

8010591d <vector121>:
.globl vector121
vector121:
  pushl $0
8010591d:	6a 00                	push   $0x0
  pushl $121
8010591f:	6a 79                	push   $0x79
  jmp alltraps
80105921:	e9 8b f7 ff ff       	jmp    801050b1 <alltraps>

80105926 <vector122>:
.globl vector122
vector122:
  pushl $0
80105926:	6a 00                	push   $0x0
  pushl $122
80105928:	6a 7a                	push   $0x7a
  jmp alltraps
8010592a:	e9 82 f7 ff ff       	jmp    801050b1 <alltraps>

8010592f <vector123>:
.globl vector123
vector123:
  pushl $0
8010592f:	6a 00                	push   $0x0
  pushl $123
80105931:	6a 7b                	push   $0x7b
  jmp alltraps
80105933:	e9 79 f7 ff ff       	jmp    801050b1 <alltraps>

80105938 <vector124>:
.globl vector124
vector124:
  pushl $0
80105938:	6a 00                	push   $0x0
  pushl $124
8010593a:	6a 7c                	push   $0x7c
  jmp alltraps
8010593c:	e9 70 f7 ff ff       	jmp    801050b1 <alltraps>

80105941 <vector125>:
.globl vector125
vector125:
  pushl $0
80105941:	6a 00                	push   $0x0
  pushl $125
80105943:	6a 7d                	push   $0x7d
  jmp alltraps
80105945:	e9 67 f7 ff ff       	jmp    801050b1 <alltraps>

8010594a <vector126>:
.globl vector126
vector126:
  pushl $0
8010594a:	6a 00                	push   $0x0
  pushl $126
8010594c:	6a 7e                	push   $0x7e
  jmp alltraps
8010594e:	e9 5e f7 ff ff       	jmp    801050b1 <alltraps>

80105953 <vector127>:
.globl vector127
vector127:
  pushl $0
80105953:	6a 00                	push   $0x0
  pushl $127
80105955:	6a 7f                	push   $0x7f
  jmp alltraps
80105957:	e9 55 f7 ff ff       	jmp    801050b1 <alltraps>

8010595c <vector128>:
.globl vector128
vector128:
  pushl $0
8010595c:	6a 00                	push   $0x0
  pushl $128
8010595e:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80105963:	e9 49 f7 ff ff       	jmp    801050b1 <alltraps>

80105968 <vector129>:
.globl vector129
vector129:
  pushl $0
80105968:	6a 00                	push   $0x0
  pushl $129
8010596a:	68 81 00 00 00       	push   $0x81
  jmp alltraps
8010596f:	e9 3d f7 ff ff       	jmp    801050b1 <alltraps>

80105974 <vector130>:
.globl vector130
vector130:
  pushl $0
80105974:	6a 00                	push   $0x0
  pushl $130
80105976:	68 82 00 00 00       	push   $0x82
  jmp alltraps
8010597b:	e9 31 f7 ff ff       	jmp    801050b1 <alltraps>

80105980 <vector131>:
.globl vector131
vector131:
  pushl $0
80105980:	6a 00                	push   $0x0
  pushl $131
80105982:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80105987:	e9 25 f7 ff ff       	jmp    801050b1 <alltraps>

8010598c <vector132>:
.globl vector132
vector132:
  pushl $0
8010598c:	6a 00                	push   $0x0
  pushl $132
8010598e:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80105993:	e9 19 f7 ff ff       	jmp    801050b1 <alltraps>

80105998 <vector133>:
.globl vector133
vector133:
  pushl $0
80105998:	6a 00                	push   $0x0
  pushl $133
8010599a:	68 85 00 00 00       	push   $0x85
  jmp alltraps
8010599f:	e9 0d f7 ff ff       	jmp    801050b1 <alltraps>

801059a4 <vector134>:
.globl vector134
vector134:
  pushl $0
801059a4:	6a 00                	push   $0x0
  pushl $134
801059a6:	68 86 00 00 00       	push   $0x86
  jmp alltraps
801059ab:	e9 01 f7 ff ff       	jmp    801050b1 <alltraps>

801059b0 <vector135>:
.globl vector135
vector135:
  pushl $0
801059b0:	6a 00                	push   $0x0
  pushl $135
801059b2:	68 87 00 00 00       	push   $0x87
  jmp alltraps
801059b7:	e9 f5 f6 ff ff       	jmp    801050b1 <alltraps>

801059bc <vector136>:
.globl vector136
vector136:
  pushl $0
801059bc:	6a 00                	push   $0x0
  pushl $136
801059be:	68 88 00 00 00       	push   $0x88
  jmp alltraps
801059c3:	e9 e9 f6 ff ff       	jmp    801050b1 <alltraps>

801059c8 <vector137>:
.globl vector137
vector137:
  pushl $0
801059c8:	6a 00                	push   $0x0
  pushl $137
801059ca:	68 89 00 00 00       	push   $0x89
  jmp alltraps
801059cf:	e9 dd f6 ff ff       	jmp    801050b1 <alltraps>

801059d4 <vector138>:
.globl vector138
vector138:
  pushl $0
801059d4:	6a 00                	push   $0x0
  pushl $138
801059d6:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
801059db:	e9 d1 f6 ff ff       	jmp    801050b1 <alltraps>

801059e0 <vector139>:
.globl vector139
vector139:
  pushl $0
801059e0:	6a 00                	push   $0x0
  pushl $139
801059e2:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
801059e7:	e9 c5 f6 ff ff       	jmp    801050b1 <alltraps>

801059ec <vector140>:
.globl vector140
vector140:
  pushl $0
801059ec:	6a 00                	push   $0x0
  pushl $140
801059ee:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
801059f3:	e9 b9 f6 ff ff       	jmp    801050b1 <alltraps>

801059f8 <vector141>:
.globl vector141
vector141:
  pushl $0
801059f8:	6a 00                	push   $0x0
  pushl $141
801059fa:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
801059ff:	e9 ad f6 ff ff       	jmp    801050b1 <alltraps>

80105a04 <vector142>:
.globl vector142
vector142:
  pushl $0
80105a04:	6a 00                	push   $0x0
  pushl $142
80105a06:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80105a0b:	e9 a1 f6 ff ff       	jmp    801050b1 <alltraps>

80105a10 <vector143>:
.globl vector143
vector143:
  pushl $0
80105a10:	6a 00                	push   $0x0
  pushl $143
80105a12:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80105a17:	e9 95 f6 ff ff       	jmp    801050b1 <alltraps>

80105a1c <vector144>:
.globl vector144
vector144:
  pushl $0
80105a1c:	6a 00                	push   $0x0
  pushl $144
80105a1e:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80105a23:	e9 89 f6 ff ff       	jmp    801050b1 <alltraps>

80105a28 <vector145>:
.globl vector145
vector145:
  pushl $0
80105a28:	6a 00                	push   $0x0
  pushl $145
80105a2a:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80105a2f:	e9 7d f6 ff ff       	jmp    801050b1 <alltraps>

80105a34 <vector146>:
.globl vector146
vector146:
  pushl $0
80105a34:	6a 00                	push   $0x0
  pushl $146
80105a36:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80105a3b:	e9 71 f6 ff ff       	jmp    801050b1 <alltraps>

80105a40 <vector147>:
.globl vector147
vector147:
  pushl $0
80105a40:	6a 00                	push   $0x0
  pushl $147
80105a42:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80105a47:	e9 65 f6 ff ff       	jmp    801050b1 <alltraps>

80105a4c <vector148>:
.globl vector148
vector148:
  pushl $0
80105a4c:	6a 00                	push   $0x0
  pushl $148
80105a4e:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80105a53:	e9 59 f6 ff ff       	jmp    801050b1 <alltraps>

80105a58 <vector149>:
.globl vector149
vector149:
  pushl $0
80105a58:	6a 00                	push   $0x0
  pushl $149
80105a5a:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80105a5f:	e9 4d f6 ff ff       	jmp    801050b1 <alltraps>

80105a64 <vector150>:
.globl vector150
vector150:
  pushl $0
80105a64:	6a 00                	push   $0x0
  pushl $150
80105a66:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80105a6b:	e9 41 f6 ff ff       	jmp    801050b1 <alltraps>

80105a70 <vector151>:
.globl vector151
vector151:
  pushl $0
80105a70:	6a 00                	push   $0x0
  pushl $151
80105a72:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80105a77:	e9 35 f6 ff ff       	jmp    801050b1 <alltraps>

80105a7c <vector152>:
.globl vector152
vector152:
  pushl $0
80105a7c:	6a 00                	push   $0x0
  pushl $152
80105a7e:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80105a83:	e9 29 f6 ff ff       	jmp    801050b1 <alltraps>

80105a88 <vector153>:
.globl vector153
vector153:
  pushl $0
80105a88:	6a 00                	push   $0x0
  pushl $153
80105a8a:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80105a8f:	e9 1d f6 ff ff       	jmp    801050b1 <alltraps>

80105a94 <vector154>:
.globl vector154
vector154:
  pushl $0
80105a94:	6a 00                	push   $0x0
  pushl $154
80105a96:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80105a9b:	e9 11 f6 ff ff       	jmp    801050b1 <alltraps>

80105aa0 <vector155>:
.globl vector155
vector155:
  pushl $0
80105aa0:	6a 00                	push   $0x0
  pushl $155
80105aa2:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80105aa7:	e9 05 f6 ff ff       	jmp    801050b1 <alltraps>

80105aac <vector156>:
.globl vector156
vector156:
  pushl $0
80105aac:	6a 00                	push   $0x0
  pushl $156
80105aae:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80105ab3:	e9 f9 f5 ff ff       	jmp    801050b1 <alltraps>

80105ab8 <vector157>:
.globl vector157
vector157:
  pushl $0
80105ab8:	6a 00                	push   $0x0
  pushl $157
80105aba:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80105abf:	e9 ed f5 ff ff       	jmp    801050b1 <alltraps>

80105ac4 <vector158>:
.globl vector158
vector158:
  pushl $0
80105ac4:	6a 00                	push   $0x0
  pushl $158
80105ac6:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80105acb:	e9 e1 f5 ff ff       	jmp    801050b1 <alltraps>

80105ad0 <vector159>:
.globl vector159
vector159:
  pushl $0
80105ad0:	6a 00                	push   $0x0
  pushl $159
80105ad2:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80105ad7:	e9 d5 f5 ff ff       	jmp    801050b1 <alltraps>

80105adc <vector160>:
.globl vector160
vector160:
  pushl $0
80105adc:	6a 00                	push   $0x0
  pushl $160
80105ade:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80105ae3:	e9 c9 f5 ff ff       	jmp    801050b1 <alltraps>

80105ae8 <vector161>:
.globl vector161
vector161:
  pushl $0
80105ae8:	6a 00                	push   $0x0
  pushl $161
80105aea:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80105aef:	e9 bd f5 ff ff       	jmp    801050b1 <alltraps>

80105af4 <vector162>:
.globl vector162
vector162:
  pushl $0
80105af4:	6a 00                	push   $0x0
  pushl $162
80105af6:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80105afb:	e9 b1 f5 ff ff       	jmp    801050b1 <alltraps>

80105b00 <vector163>:
.globl vector163
vector163:
  pushl $0
80105b00:	6a 00                	push   $0x0
  pushl $163
80105b02:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80105b07:	e9 a5 f5 ff ff       	jmp    801050b1 <alltraps>

80105b0c <vector164>:
.globl vector164
vector164:
  pushl $0
80105b0c:	6a 00                	push   $0x0
  pushl $164
80105b0e:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80105b13:	e9 99 f5 ff ff       	jmp    801050b1 <alltraps>

80105b18 <vector165>:
.globl vector165
vector165:
  pushl $0
80105b18:	6a 00                	push   $0x0
  pushl $165
80105b1a:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80105b1f:	e9 8d f5 ff ff       	jmp    801050b1 <alltraps>

80105b24 <vector166>:
.globl vector166
vector166:
  pushl $0
80105b24:	6a 00                	push   $0x0
  pushl $166
80105b26:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80105b2b:	e9 81 f5 ff ff       	jmp    801050b1 <alltraps>

80105b30 <vector167>:
.globl vector167
vector167:
  pushl $0
80105b30:	6a 00                	push   $0x0
  pushl $167
80105b32:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80105b37:	e9 75 f5 ff ff       	jmp    801050b1 <alltraps>

80105b3c <vector168>:
.globl vector168
vector168:
  pushl $0
80105b3c:	6a 00                	push   $0x0
  pushl $168
80105b3e:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80105b43:	e9 69 f5 ff ff       	jmp    801050b1 <alltraps>

80105b48 <vector169>:
.globl vector169
vector169:
  pushl $0
80105b48:	6a 00                	push   $0x0
  pushl $169
80105b4a:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80105b4f:	e9 5d f5 ff ff       	jmp    801050b1 <alltraps>

80105b54 <vector170>:
.globl vector170
vector170:
  pushl $0
80105b54:	6a 00                	push   $0x0
  pushl $170
80105b56:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80105b5b:	e9 51 f5 ff ff       	jmp    801050b1 <alltraps>

80105b60 <vector171>:
.globl vector171
vector171:
  pushl $0
80105b60:	6a 00                	push   $0x0
  pushl $171
80105b62:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80105b67:	e9 45 f5 ff ff       	jmp    801050b1 <alltraps>

80105b6c <vector172>:
.globl vector172
vector172:
  pushl $0
80105b6c:	6a 00                	push   $0x0
  pushl $172
80105b6e:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80105b73:	e9 39 f5 ff ff       	jmp    801050b1 <alltraps>

80105b78 <vector173>:
.globl vector173
vector173:
  pushl $0
80105b78:	6a 00                	push   $0x0
  pushl $173
80105b7a:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80105b7f:	e9 2d f5 ff ff       	jmp    801050b1 <alltraps>

80105b84 <vector174>:
.globl vector174
vector174:
  pushl $0
80105b84:	6a 00                	push   $0x0
  pushl $174
80105b86:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80105b8b:	e9 21 f5 ff ff       	jmp    801050b1 <alltraps>

80105b90 <vector175>:
.globl vector175
vector175:
  pushl $0
80105b90:	6a 00                	push   $0x0
  pushl $175
80105b92:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80105b97:	e9 15 f5 ff ff       	jmp    801050b1 <alltraps>

80105b9c <vector176>:
.globl vector176
vector176:
  pushl $0
80105b9c:	6a 00                	push   $0x0
  pushl $176
80105b9e:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80105ba3:	e9 09 f5 ff ff       	jmp    801050b1 <alltraps>

80105ba8 <vector177>:
.globl vector177
vector177:
  pushl $0
80105ba8:	6a 00                	push   $0x0
  pushl $177
80105baa:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80105baf:	e9 fd f4 ff ff       	jmp    801050b1 <alltraps>

80105bb4 <vector178>:
.globl vector178
vector178:
  pushl $0
80105bb4:	6a 00                	push   $0x0
  pushl $178
80105bb6:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80105bbb:	e9 f1 f4 ff ff       	jmp    801050b1 <alltraps>

80105bc0 <vector179>:
.globl vector179
vector179:
  pushl $0
80105bc0:	6a 00                	push   $0x0
  pushl $179
80105bc2:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80105bc7:	e9 e5 f4 ff ff       	jmp    801050b1 <alltraps>

80105bcc <vector180>:
.globl vector180
vector180:
  pushl $0
80105bcc:	6a 00                	push   $0x0
  pushl $180
80105bce:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80105bd3:	e9 d9 f4 ff ff       	jmp    801050b1 <alltraps>

80105bd8 <vector181>:
.globl vector181
vector181:
  pushl $0
80105bd8:	6a 00                	push   $0x0
  pushl $181
80105bda:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80105bdf:	e9 cd f4 ff ff       	jmp    801050b1 <alltraps>

80105be4 <vector182>:
.globl vector182
vector182:
  pushl $0
80105be4:	6a 00                	push   $0x0
  pushl $182
80105be6:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80105beb:	e9 c1 f4 ff ff       	jmp    801050b1 <alltraps>

80105bf0 <vector183>:
.globl vector183
vector183:
  pushl $0
80105bf0:	6a 00                	push   $0x0
  pushl $183
80105bf2:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80105bf7:	e9 b5 f4 ff ff       	jmp    801050b1 <alltraps>

80105bfc <vector184>:
.globl vector184
vector184:
  pushl $0
80105bfc:	6a 00                	push   $0x0
  pushl $184
80105bfe:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80105c03:	e9 a9 f4 ff ff       	jmp    801050b1 <alltraps>

80105c08 <vector185>:
.globl vector185
vector185:
  pushl $0
80105c08:	6a 00                	push   $0x0
  pushl $185
80105c0a:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80105c0f:	e9 9d f4 ff ff       	jmp    801050b1 <alltraps>

80105c14 <vector186>:
.globl vector186
vector186:
  pushl $0
80105c14:	6a 00                	push   $0x0
  pushl $186
80105c16:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80105c1b:	e9 91 f4 ff ff       	jmp    801050b1 <alltraps>

80105c20 <vector187>:
.globl vector187
vector187:
  pushl $0
80105c20:	6a 00                	push   $0x0
  pushl $187
80105c22:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80105c27:	e9 85 f4 ff ff       	jmp    801050b1 <alltraps>

80105c2c <vector188>:
.globl vector188
vector188:
  pushl $0
80105c2c:	6a 00                	push   $0x0
  pushl $188
80105c2e:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80105c33:	e9 79 f4 ff ff       	jmp    801050b1 <alltraps>

80105c38 <vector189>:
.globl vector189
vector189:
  pushl $0
80105c38:	6a 00                	push   $0x0
  pushl $189
80105c3a:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80105c3f:	e9 6d f4 ff ff       	jmp    801050b1 <alltraps>

80105c44 <vector190>:
.globl vector190
vector190:
  pushl $0
80105c44:	6a 00                	push   $0x0
  pushl $190
80105c46:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80105c4b:	e9 61 f4 ff ff       	jmp    801050b1 <alltraps>

80105c50 <vector191>:
.globl vector191
vector191:
  pushl $0
80105c50:	6a 00                	push   $0x0
  pushl $191
80105c52:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80105c57:	e9 55 f4 ff ff       	jmp    801050b1 <alltraps>

80105c5c <vector192>:
.globl vector192
vector192:
  pushl $0
80105c5c:	6a 00                	push   $0x0
  pushl $192
80105c5e:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80105c63:	e9 49 f4 ff ff       	jmp    801050b1 <alltraps>

80105c68 <vector193>:
.globl vector193
vector193:
  pushl $0
80105c68:	6a 00                	push   $0x0
  pushl $193
80105c6a:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80105c6f:	e9 3d f4 ff ff       	jmp    801050b1 <alltraps>

80105c74 <vector194>:
.globl vector194
vector194:
  pushl $0
80105c74:	6a 00                	push   $0x0
  pushl $194
80105c76:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80105c7b:	e9 31 f4 ff ff       	jmp    801050b1 <alltraps>

80105c80 <vector195>:
.globl vector195
vector195:
  pushl $0
80105c80:	6a 00                	push   $0x0
  pushl $195
80105c82:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80105c87:	e9 25 f4 ff ff       	jmp    801050b1 <alltraps>

80105c8c <vector196>:
.globl vector196
vector196:
  pushl $0
80105c8c:	6a 00                	push   $0x0
  pushl $196
80105c8e:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80105c93:	e9 19 f4 ff ff       	jmp    801050b1 <alltraps>

80105c98 <vector197>:
.globl vector197
vector197:
  pushl $0
80105c98:	6a 00                	push   $0x0
  pushl $197
80105c9a:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80105c9f:	e9 0d f4 ff ff       	jmp    801050b1 <alltraps>

80105ca4 <vector198>:
.globl vector198
vector198:
  pushl $0
80105ca4:	6a 00                	push   $0x0
  pushl $198
80105ca6:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80105cab:	e9 01 f4 ff ff       	jmp    801050b1 <alltraps>

80105cb0 <vector199>:
.globl vector199
vector199:
  pushl $0
80105cb0:	6a 00                	push   $0x0
  pushl $199
80105cb2:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80105cb7:	e9 f5 f3 ff ff       	jmp    801050b1 <alltraps>

80105cbc <vector200>:
.globl vector200
vector200:
  pushl $0
80105cbc:	6a 00                	push   $0x0
  pushl $200
80105cbe:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80105cc3:	e9 e9 f3 ff ff       	jmp    801050b1 <alltraps>

80105cc8 <vector201>:
.globl vector201
vector201:
  pushl $0
80105cc8:	6a 00                	push   $0x0
  pushl $201
80105cca:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80105ccf:	e9 dd f3 ff ff       	jmp    801050b1 <alltraps>

80105cd4 <vector202>:
.globl vector202
vector202:
  pushl $0
80105cd4:	6a 00                	push   $0x0
  pushl $202
80105cd6:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80105cdb:	e9 d1 f3 ff ff       	jmp    801050b1 <alltraps>

80105ce0 <vector203>:
.globl vector203
vector203:
  pushl $0
80105ce0:	6a 00                	push   $0x0
  pushl $203
80105ce2:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80105ce7:	e9 c5 f3 ff ff       	jmp    801050b1 <alltraps>

80105cec <vector204>:
.globl vector204
vector204:
  pushl $0
80105cec:	6a 00                	push   $0x0
  pushl $204
80105cee:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80105cf3:	e9 b9 f3 ff ff       	jmp    801050b1 <alltraps>

80105cf8 <vector205>:
.globl vector205
vector205:
  pushl $0
80105cf8:	6a 00                	push   $0x0
  pushl $205
80105cfa:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80105cff:	e9 ad f3 ff ff       	jmp    801050b1 <alltraps>

80105d04 <vector206>:
.globl vector206
vector206:
  pushl $0
80105d04:	6a 00                	push   $0x0
  pushl $206
80105d06:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80105d0b:	e9 a1 f3 ff ff       	jmp    801050b1 <alltraps>

80105d10 <vector207>:
.globl vector207
vector207:
  pushl $0
80105d10:	6a 00                	push   $0x0
  pushl $207
80105d12:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80105d17:	e9 95 f3 ff ff       	jmp    801050b1 <alltraps>

80105d1c <vector208>:
.globl vector208
vector208:
  pushl $0
80105d1c:	6a 00                	push   $0x0
  pushl $208
80105d1e:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80105d23:	e9 89 f3 ff ff       	jmp    801050b1 <alltraps>

80105d28 <vector209>:
.globl vector209
vector209:
  pushl $0
80105d28:	6a 00                	push   $0x0
  pushl $209
80105d2a:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80105d2f:	e9 7d f3 ff ff       	jmp    801050b1 <alltraps>

80105d34 <vector210>:
.globl vector210
vector210:
  pushl $0
80105d34:	6a 00                	push   $0x0
  pushl $210
80105d36:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80105d3b:	e9 71 f3 ff ff       	jmp    801050b1 <alltraps>

80105d40 <vector211>:
.globl vector211
vector211:
  pushl $0
80105d40:	6a 00                	push   $0x0
  pushl $211
80105d42:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80105d47:	e9 65 f3 ff ff       	jmp    801050b1 <alltraps>

80105d4c <vector212>:
.globl vector212
vector212:
  pushl $0
80105d4c:	6a 00                	push   $0x0
  pushl $212
80105d4e:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80105d53:	e9 59 f3 ff ff       	jmp    801050b1 <alltraps>

80105d58 <vector213>:
.globl vector213
vector213:
  pushl $0
80105d58:	6a 00                	push   $0x0
  pushl $213
80105d5a:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80105d5f:	e9 4d f3 ff ff       	jmp    801050b1 <alltraps>

80105d64 <vector214>:
.globl vector214
vector214:
  pushl $0
80105d64:	6a 00                	push   $0x0
  pushl $214
80105d66:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80105d6b:	e9 41 f3 ff ff       	jmp    801050b1 <alltraps>

80105d70 <vector215>:
.globl vector215
vector215:
  pushl $0
80105d70:	6a 00                	push   $0x0
  pushl $215
80105d72:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80105d77:	e9 35 f3 ff ff       	jmp    801050b1 <alltraps>

80105d7c <vector216>:
.globl vector216
vector216:
  pushl $0
80105d7c:	6a 00                	push   $0x0
  pushl $216
80105d7e:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80105d83:	e9 29 f3 ff ff       	jmp    801050b1 <alltraps>

80105d88 <vector217>:
.globl vector217
vector217:
  pushl $0
80105d88:	6a 00                	push   $0x0
  pushl $217
80105d8a:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80105d8f:	e9 1d f3 ff ff       	jmp    801050b1 <alltraps>

80105d94 <vector218>:
.globl vector218
vector218:
  pushl $0
80105d94:	6a 00                	push   $0x0
  pushl $218
80105d96:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80105d9b:	e9 11 f3 ff ff       	jmp    801050b1 <alltraps>

80105da0 <vector219>:
.globl vector219
vector219:
  pushl $0
80105da0:	6a 00                	push   $0x0
  pushl $219
80105da2:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80105da7:	e9 05 f3 ff ff       	jmp    801050b1 <alltraps>

80105dac <vector220>:
.globl vector220
vector220:
  pushl $0
80105dac:	6a 00                	push   $0x0
  pushl $220
80105dae:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80105db3:	e9 f9 f2 ff ff       	jmp    801050b1 <alltraps>

80105db8 <vector221>:
.globl vector221
vector221:
  pushl $0
80105db8:	6a 00                	push   $0x0
  pushl $221
80105dba:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80105dbf:	e9 ed f2 ff ff       	jmp    801050b1 <alltraps>

80105dc4 <vector222>:
.globl vector222
vector222:
  pushl $0
80105dc4:	6a 00                	push   $0x0
  pushl $222
80105dc6:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80105dcb:	e9 e1 f2 ff ff       	jmp    801050b1 <alltraps>

80105dd0 <vector223>:
.globl vector223
vector223:
  pushl $0
80105dd0:	6a 00                	push   $0x0
  pushl $223
80105dd2:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80105dd7:	e9 d5 f2 ff ff       	jmp    801050b1 <alltraps>

80105ddc <vector224>:
.globl vector224
vector224:
  pushl $0
80105ddc:	6a 00                	push   $0x0
  pushl $224
80105dde:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80105de3:	e9 c9 f2 ff ff       	jmp    801050b1 <alltraps>

80105de8 <vector225>:
.globl vector225
vector225:
  pushl $0
80105de8:	6a 00                	push   $0x0
  pushl $225
80105dea:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80105def:	e9 bd f2 ff ff       	jmp    801050b1 <alltraps>

80105df4 <vector226>:
.globl vector226
vector226:
  pushl $0
80105df4:	6a 00                	push   $0x0
  pushl $226
80105df6:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80105dfb:	e9 b1 f2 ff ff       	jmp    801050b1 <alltraps>

80105e00 <vector227>:
.globl vector227
vector227:
  pushl $0
80105e00:	6a 00                	push   $0x0
  pushl $227
80105e02:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80105e07:	e9 a5 f2 ff ff       	jmp    801050b1 <alltraps>

80105e0c <vector228>:
.globl vector228
vector228:
  pushl $0
80105e0c:	6a 00                	push   $0x0
  pushl $228
80105e0e:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80105e13:	e9 99 f2 ff ff       	jmp    801050b1 <alltraps>

80105e18 <vector229>:
.globl vector229
vector229:
  pushl $0
80105e18:	6a 00                	push   $0x0
  pushl $229
80105e1a:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80105e1f:	e9 8d f2 ff ff       	jmp    801050b1 <alltraps>

80105e24 <vector230>:
.globl vector230
vector230:
  pushl $0
80105e24:	6a 00                	push   $0x0
  pushl $230
80105e26:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80105e2b:	e9 81 f2 ff ff       	jmp    801050b1 <alltraps>

80105e30 <vector231>:
.globl vector231
vector231:
  pushl $0
80105e30:	6a 00                	push   $0x0
  pushl $231
80105e32:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80105e37:	e9 75 f2 ff ff       	jmp    801050b1 <alltraps>

80105e3c <vector232>:
.globl vector232
vector232:
  pushl $0
80105e3c:	6a 00                	push   $0x0
  pushl $232
80105e3e:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80105e43:	e9 69 f2 ff ff       	jmp    801050b1 <alltraps>

80105e48 <vector233>:
.globl vector233
vector233:
  pushl $0
80105e48:	6a 00                	push   $0x0
  pushl $233
80105e4a:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80105e4f:	e9 5d f2 ff ff       	jmp    801050b1 <alltraps>

80105e54 <vector234>:
.globl vector234
vector234:
  pushl $0
80105e54:	6a 00                	push   $0x0
  pushl $234
80105e56:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80105e5b:	e9 51 f2 ff ff       	jmp    801050b1 <alltraps>

80105e60 <vector235>:
.globl vector235
vector235:
  pushl $0
80105e60:	6a 00                	push   $0x0
  pushl $235
80105e62:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80105e67:	e9 45 f2 ff ff       	jmp    801050b1 <alltraps>

80105e6c <vector236>:
.globl vector236
vector236:
  pushl $0
80105e6c:	6a 00                	push   $0x0
  pushl $236
80105e6e:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80105e73:	e9 39 f2 ff ff       	jmp    801050b1 <alltraps>

80105e78 <vector237>:
.globl vector237
vector237:
  pushl $0
80105e78:	6a 00                	push   $0x0
  pushl $237
80105e7a:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80105e7f:	e9 2d f2 ff ff       	jmp    801050b1 <alltraps>

80105e84 <vector238>:
.globl vector238
vector238:
  pushl $0
80105e84:	6a 00                	push   $0x0
  pushl $238
80105e86:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80105e8b:	e9 21 f2 ff ff       	jmp    801050b1 <alltraps>

80105e90 <vector239>:
.globl vector239
vector239:
  pushl $0
80105e90:	6a 00                	push   $0x0
  pushl $239
80105e92:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80105e97:	e9 15 f2 ff ff       	jmp    801050b1 <alltraps>

80105e9c <vector240>:
.globl vector240
vector240:
  pushl $0
80105e9c:	6a 00                	push   $0x0
  pushl $240
80105e9e:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80105ea3:	e9 09 f2 ff ff       	jmp    801050b1 <alltraps>

80105ea8 <vector241>:
.globl vector241
vector241:
  pushl $0
80105ea8:	6a 00                	push   $0x0
  pushl $241
80105eaa:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80105eaf:	e9 fd f1 ff ff       	jmp    801050b1 <alltraps>

80105eb4 <vector242>:
.globl vector242
vector242:
  pushl $0
80105eb4:	6a 00                	push   $0x0
  pushl $242
80105eb6:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80105ebb:	e9 f1 f1 ff ff       	jmp    801050b1 <alltraps>

80105ec0 <vector243>:
.globl vector243
vector243:
  pushl $0
80105ec0:	6a 00                	push   $0x0
  pushl $243
80105ec2:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80105ec7:	e9 e5 f1 ff ff       	jmp    801050b1 <alltraps>

80105ecc <vector244>:
.globl vector244
vector244:
  pushl $0
80105ecc:	6a 00                	push   $0x0
  pushl $244
80105ece:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80105ed3:	e9 d9 f1 ff ff       	jmp    801050b1 <alltraps>

80105ed8 <vector245>:
.globl vector245
vector245:
  pushl $0
80105ed8:	6a 00                	push   $0x0
  pushl $245
80105eda:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80105edf:	e9 cd f1 ff ff       	jmp    801050b1 <alltraps>

80105ee4 <vector246>:
.globl vector246
vector246:
  pushl $0
80105ee4:	6a 00                	push   $0x0
  pushl $246
80105ee6:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80105eeb:	e9 c1 f1 ff ff       	jmp    801050b1 <alltraps>

80105ef0 <vector247>:
.globl vector247
vector247:
  pushl $0
80105ef0:	6a 00                	push   $0x0
  pushl $247
80105ef2:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80105ef7:	e9 b5 f1 ff ff       	jmp    801050b1 <alltraps>

80105efc <vector248>:
.globl vector248
vector248:
  pushl $0
80105efc:	6a 00                	push   $0x0
  pushl $248
80105efe:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80105f03:	e9 a9 f1 ff ff       	jmp    801050b1 <alltraps>

80105f08 <vector249>:
.globl vector249
vector249:
  pushl $0
80105f08:	6a 00                	push   $0x0
  pushl $249
80105f0a:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80105f0f:	e9 9d f1 ff ff       	jmp    801050b1 <alltraps>

80105f14 <vector250>:
.globl vector250
vector250:
  pushl $0
80105f14:	6a 00                	push   $0x0
  pushl $250
80105f16:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80105f1b:	e9 91 f1 ff ff       	jmp    801050b1 <alltraps>

80105f20 <vector251>:
.globl vector251
vector251:
  pushl $0
80105f20:	6a 00                	push   $0x0
  pushl $251
80105f22:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80105f27:	e9 85 f1 ff ff       	jmp    801050b1 <alltraps>

80105f2c <vector252>:
.globl vector252
vector252:
  pushl $0
80105f2c:	6a 00                	push   $0x0
  pushl $252
80105f2e:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80105f33:	e9 79 f1 ff ff       	jmp    801050b1 <alltraps>

80105f38 <vector253>:
.globl vector253
vector253:
  pushl $0
80105f38:	6a 00                	push   $0x0
  pushl $253
80105f3a:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80105f3f:	e9 6d f1 ff ff       	jmp    801050b1 <alltraps>

80105f44 <vector254>:
.globl vector254
vector254:
  pushl $0
80105f44:	6a 00                	push   $0x0
  pushl $254
80105f46:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80105f4b:	e9 61 f1 ff ff       	jmp    801050b1 <alltraps>

80105f50 <vector255>:
.globl vector255
vector255:
  pushl $0
80105f50:	6a 00                	push   $0x0
  pushl $255
80105f52:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80105f57:	e9 55 f1 ff ff       	jmp    801050b1 <alltraps>

80105f5c <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80105f5c:	55                   	push   %ebp
80105f5d:	89 e5                	mov    %esp,%ebp
80105f5f:	57                   	push   %edi
80105f60:	56                   	push   %esi
80105f61:	53                   	push   %ebx
80105f62:	83 ec 0c             	sub    $0xc,%esp
80105f65:	89 d6                	mov    %edx,%esi
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80105f67:	c1 ea 16             	shr    $0x16,%edx
80105f6a:	8d 3c 90             	lea    (%eax,%edx,4),%edi
  if(*pde & PTE_P){
80105f6d:	8b 1f                	mov    (%edi),%ebx
80105f6f:	f6 c3 01             	test   $0x1,%bl
80105f72:	74 22                	je     80105f96 <walkpgdir+0x3a>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
80105f74:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
80105f7a:	81 c3 00 00 00 80    	add    $0x80000000,%ebx
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
80105f80:	c1 ee 0c             	shr    $0xc,%esi
80105f83:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
80105f89:	8d 1c b3             	lea    (%ebx,%esi,4),%ebx
}
80105f8c:	89 d8                	mov    %ebx,%eax
80105f8e:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105f91:	5b                   	pop    %ebx
80105f92:	5e                   	pop    %esi
80105f93:	5f                   	pop    %edi
80105f94:	5d                   	pop    %ebp
80105f95:	c3                   	ret    
    if(!alloc || (pgtab = (pte_t*)kalloc(-2)) == 0)
80105f96:	85 c9                	test   %ecx,%ecx
80105f98:	74 33                	je     80105fcd <walkpgdir+0x71>
80105f9a:	83 ec 0c             	sub    $0xc,%esp
80105f9d:	6a fe                	push   $0xfffffffe
80105f9f:	e8 5c c2 ff ff       	call   80102200 <kalloc>
80105fa4:	89 c3                	mov    %eax,%ebx
80105fa6:	83 c4 10             	add    $0x10,%esp
80105fa9:	85 c0                	test   %eax,%eax
80105fab:	74 df                	je     80105f8c <walkpgdir+0x30>
    memset(pgtab, 0, PGSIZE);
80105fad:	83 ec 04             	sub    $0x4,%esp
80105fb0:	68 00 10 00 00       	push   $0x1000
80105fb5:	6a 00                	push   $0x0
80105fb7:	50                   	push   %eax
80105fb8:	e8 ec df ff ff       	call   80103fa9 <memset>
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
80105fbd:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80105fc3:	83 c8 07             	or     $0x7,%eax
80105fc6:	89 07                	mov    %eax,(%edi)
80105fc8:	83 c4 10             	add    $0x10,%esp
80105fcb:	eb b3                	jmp    80105f80 <walkpgdir+0x24>
      return 0;
80105fcd:	bb 00 00 00 00       	mov    $0x0,%ebx
80105fd2:	eb b8                	jmp    80105f8c <walkpgdir+0x30>

80105fd4 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80105fd4:	55                   	push   %ebp
80105fd5:	89 e5                	mov    %esp,%ebp
80105fd7:	57                   	push   %edi
80105fd8:	56                   	push   %esi
80105fd9:	53                   	push   %ebx
80105fda:	83 ec 1c             	sub    $0x1c,%esp
80105fdd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105fe0:	8b 75 08             	mov    0x8(%ebp),%esi
  char *a, *last;
  pte_t *pte;

  a = (char*)PGROUNDDOWN((uint)va);
80105fe3:	89 d3                	mov    %edx,%ebx
80105fe5:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80105feb:	8d 7c 0a ff          	lea    -0x1(%edx,%ecx,1),%edi
80105fef:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105ff5:	b9 01 00 00 00       	mov    $0x1,%ecx
80105ffa:	89 da                	mov    %ebx,%edx
80105ffc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105fff:	e8 58 ff ff ff       	call   80105f5c <walkpgdir>
80106004:	85 c0                	test   %eax,%eax
80106006:	74 2e                	je     80106036 <mappages+0x62>
      return -1;
    if(*pte & PTE_P)
80106008:	f6 00 01             	testb  $0x1,(%eax)
8010600b:	75 1c                	jne    80106029 <mappages+0x55>
      panic("remap");
    *pte = pa | perm | PTE_P;
8010600d:	89 f2                	mov    %esi,%edx
8010600f:	0b 55 0c             	or     0xc(%ebp),%edx
80106012:	83 ca 01             	or     $0x1,%edx
80106015:	89 10                	mov    %edx,(%eax)
    if(a == last)
80106017:	39 fb                	cmp    %edi,%ebx
80106019:	74 28                	je     80106043 <mappages+0x6f>
      break;
    a += PGSIZE;
8010601b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pa += PGSIZE;
80106021:	81 c6 00 10 00 00    	add    $0x1000,%esi
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80106027:	eb cc                	jmp    80105ff5 <mappages+0x21>
      panic("remap");
80106029:	83 ec 0c             	sub    $0xc,%esp
8010602c:	68 0c 71 10 80       	push   $0x8010710c
80106031:	e8 12 a3 ff ff       	call   80100348 <panic>
      return -1;
80106036:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  return 0;
}
8010603b:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010603e:	5b                   	pop    %ebx
8010603f:	5e                   	pop    %esi
80106040:	5f                   	pop    %edi
80106041:	5d                   	pop    %ebp
80106042:	c3                   	ret    
  return 0;
80106043:	b8 00 00 00 00       	mov    $0x0,%eax
80106048:	eb f1                	jmp    8010603b <mappages+0x67>

8010604a <seginit>:
{
8010604a:	55                   	push   %ebp
8010604b:	89 e5                	mov    %esp,%ebp
8010604d:	53                   	push   %ebx
8010604e:	83 ec 14             	sub    $0x14,%esp
  c = &cpus[cpuid()];
80106051:	e8 ea d4 ff ff       	call   80103540 <cpuid>
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80106056:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
8010605c:	66 c7 80 38 28 19 80 	movw   $0xffff,-0x7fe6d7c8(%eax)
80106063:	ff ff 
80106065:	66 c7 80 3a 28 19 80 	movw   $0x0,-0x7fe6d7c6(%eax)
8010606c:	00 00 
8010606e:	c6 80 3c 28 19 80 00 	movb   $0x0,-0x7fe6d7c4(%eax)
80106075:	0f b6 88 3d 28 19 80 	movzbl -0x7fe6d7c3(%eax),%ecx
8010607c:	83 e1 f0             	and    $0xfffffff0,%ecx
8010607f:	83 c9 1a             	or     $0x1a,%ecx
80106082:	83 e1 9f             	and    $0xffffff9f,%ecx
80106085:	83 c9 80             	or     $0xffffff80,%ecx
80106088:	88 88 3d 28 19 80    	mov    %cl,-0x7fe6d7c3(%eax)
8010608e:	0f b6 88 3e 28 19 80 	movzbl -0x7fe6d7c2(%eax),%ecx
80106095:	83 c9 0f             	or     $0xf,%ecx
80106098:	83 e1 cf             	and    $0xffffffcf,%ecx
8010609b:	83 c9 c0             	or     $0xffffffc0,%ecx
8010609e:	88 88 3e 28 19 80    	mov    %cl,-0x7fe6d7c2(%eax)
801060a4:	c6 80 3f 28 19 80 00 	movb   $0x0,-0x7fe6d7c1(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
801060ab:	66 c7 80 40 28 19 80 	movw   $0xffff,-0x7fe6d7c0(%eax)
801060b2:	ff ff 
801060b4:	66 c7 80 42 28 19 80 	movw   $0x0,-0x7fe6d7be(%eax)
801060bb:	00 00 
801060bd:	c6 80 44 28 19 80 00 	movb   $0x0,-0x7fe6d7bc(%eax)
801060c4:	0f b6 88 45 28 19 80 	movzbl -0x7fe6d7bb(%eax),%ecx
801060cb:	83 e1 f0             	and    $0xfffffff0,%ecx
801060ce:	83 c9 12             	or     $0x12,%ecx
801060d1:	83 e1 9f             	and    $0xffffff9f,%ecx
801060d4:	83 c9 80             	or     $0xffffff80,%ecx
801060d7:	88 88 45 28 19 80    	mov    %cl,-0x7fe6d7bb(%eax)
801060dd:	0f b6 88 46 28 19 80 	movzbl -0x7fe6d7ba(%eax),%ecx
801060e4:	83 c9 0f             	or     $0xf,%ecx
801060e7:	83 e1 cf             	and    $0xffffffcf,%ecx
801060ea:	83 c9 c0             	or     $0xffffffc0,%ecx
801060ed:	88 88 46 28 19 80    	mov    %cl,-0x7fe6d7ba(%eax)
801060f3:	c6 80 47 28 19 80 00 	movb   $0x0,-0x7fe6d7b9(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
801060fa:	66 c7 80 48 28 19 80 	movw   $0xffff,-0x7fe6d7b8(%eax)
80106101:	ff ff 
80106103:	66 c7 80 4a 28 19 80 	movw   $0x0,-0x7fe6d7b6(%eax)
8010610a:	00 00 
8010610c:	c6 80 4c 28 19 80 00 	movb   $0x0,-0x7fe6d7b4(%eax)
80106113:	c6 80 4d 28 19 80 fa 	movb   $0xfa,-0x7fe6d7b3(%eax)
8010611a:	0f b6 88 4e 28 19 80 	movzbl -0x7fe6d7b2(%eax),%ecx
80106121:	83 c9 0f             	or     $0xf,%ecx
80106124:	83 e1 cf             	and    $0xffffffcf,%ecx
80106127:	83 c9 c0             	or     $0xffffffc0,%ecx
8010612a:	88 88 4e 28 19 80    	mov    %cl,-0x7fe6d7b2(%eax)
80106130:	c6 80 4f 28 19 80 00 	movb   $0x0,-0x7fe6d7b1(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80106137:	66 c7 80 50 28 19 80 	movw   $0xffff,-0x7fe6d7b0(%eax)
8010613e:	ff ff 
80106140:	66 c7 80 52 28 19 80 	movw   $0x0,-0x7fe6d7ae(%eax)
80106147:	00 00 
80106149:	c6 80 54 28 19 80 00 	movb   $0x0,-0x7fe6d7ac(%eax)
80106150:	c6 80 55 28 19 80 f2 	movb   $0xf2,-0x7fe6d7ab(%eax)
80106157:	0f b6 88 56 28 19 80 	movzbl -0x7fe6d7aa(%eax),%ecx
8010615e:	83 c9 0f             	or     $0xf,%ecx
80106161:	83 e1 cf             	and    $0xffffffcf,%ecx
80106164:	83 c9 c0             	or     $0xffffffc0,%ecx
80106167:	88 88 56 28 19 80    	mov    %cl,-0x7fe6d7aa(%eax)
8010616d:	c6 80 57 28 19 80 00 	movb   $0x0,-0x7fe6d7a9(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
80106174:	05 30 28 19 80       	add    $0x80192830,%eax
  pd[0] = size-1;
80106179:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
  pd[1] = (uint)p;
8010617f:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
  pd[2] = (uint)p >> 16;
80106183:	c1 e8 10             	shr    $0x10,%eax
80106186:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
  asm volatile("lgdt (%0)" : : "r" (pd));
8010618a:	8d 45 f2             	lea    -0xe(%ebp),%eax
8010618d:	0f 01 10             	lgdtl  (%eax)
}
80106190:	83 c4 14             	add    $0x14,%esp
80106193:	5b                   	pop    %ebx
80106194:	5d                   	pop    %ebp
80106195:	c3                   	ret    

80106196 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80106196:	55                   	push   %ebp
80106197:	89 e5                	mov    %esp,%ebp
  lcr3(V2P(kpgdir));   // switch to the kernel page table
80106199:	a1 e4 54 19 80       	mov    0x801954e4,%eax
8010619e:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint val)
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
801061a3:	0f 22 d8             	mov    %eax,%cr3
}
801061a6:	5d                   	pop    %ebp
801061a7:	c3                   	ret    

801061a8 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
801061a8:	55                   	push   %ebp
801061a9:	89 e5                	mov    %esp,%ebp
801061ab:	57                   	push   %edi
801061ac:	56                   	push   %esi
801061ad:	53                   	push   %ebx
801061ae:	83 ec 1c             	sub    $0x1c,%esp
801061b1:	8b 75 08             	mov    0x8(%ebp),%esi
  if(p == 0)
801061b4:	85 f6                	test   %esi,%esi
801061b6:	0f 84 dd 00 00 00    	je     80106299 <switchuvm+0xf1>
    panic("switchuvm: no process");
  if(p->kstack == 0)
801061bc:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
801061c0:	0f 84 e0 00 00 00    	je     801062a6 <switchuvm+0xfe>
    panic("switchuvm: no kstack");
  if(p->pgdir == 0)
801061c6:	83 7e 04 00          	cmpl   $0x0,0x4(%esi)
801061ca:	0f 84 e3 00 00 00    	je     801062b3 <switchuvm+0x10b>
    panic("switchuvm: no pgdir");

  pushcli();
801061d0:	e8 4b dc ff ff       	call   80103e20 <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
801061d5:	e8 0a d3 ff ff       	call   801034e4 <mycpu>
801061da:	89 c3                	mov    %eax,%ebx
801061dc:	e8 03 d3 ff ff       	call   801034e4 <mycpu>
801061e1:	8d 78 08             	lea    0x8(%eax),%edi
801061e4:	e8 fb d2 ff ff       	call   801034e4 <mycpu>
801061e9:	83 c0 08             	add    $0x8,%eax
801061ec:	c1 e8 10             	shr    $0x10,%eax
801061ef:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801061f2:	e8 ed d2 ff ff       	call   801034e4 <mycpu>
801061f7:	83 c0 08             	add    $0x8,%eax
801061fa:	c1 e8 18             	shr    $0x18,%eax
801061fd:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
80106204:	67 00 
80106206:	66 89 bb 9a 00 00 00 	mov    %di,0x9a(%ebx)
8010620d:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
80106211:	88 8b 9c 00 00 00    	mov    %cl,0x9c(%ebx)
80106217:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
8010621e:	83 e2 f0             	and    $0xfffffff0,%edx
80106221:	83 ca 19             	or     $0x19,%edx
80106224:	83 e2 9f             	and    $0xffffff9f,%edx
80106227:	83 ca 80             	or     $0xffffff80,%edx
8010622a:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
80106230:	c6 83 9e 00 00 00 40 	movb   $0x40,0x9e(%ebx)
80106237:	88 83 9f 00 00 00    	mov    %al,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
8010623d:	e8 a2 d2 ff ff       	call   801034e4 <mycpu>
80106242:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80106249:	83 e2 ef             	and    $0xffffffef,%edx
8010624c:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
80106252:	e8 8d d2 ff ff       	call   801034e4 <mycpu>
80106257:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
8010625d:	8b 5e 08             	mov    0x8(%esi),%ebx
80106260:	e8 7f d2 ff ff       	call   801034e4 <mycpu>
80106265:	81 c3 00 10 00 00    	add    $0x1000,%ebx
8010626b:	89 58 0c             	mov    %ebx,0xc(%eax)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
8010626e:	e8 71 d2 ff ff       	call   801034e4 <mycpu>
80106273:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  asm volatile("ltr %0" : : "r" (sel));
80106279:	b8 28 00 00 00       	mov    $0x28,%eax
8010627e:	0f 00 d8             	ltr    %ax
  ltr(SEG_TSS << 3);
  lcr3(V2P(p->pgdir));  // switch to process's address space
80106281:	8b 46 04             	mov    0x4(%esi),%eax
80106284:	05 00 00 00 80       	add    $0x80000000,%eax
  asm volatile("movl %0,%%cr3" : : "r" (val));
80106289:	0f 22 d8             	mov    %eax,%cr3
  popcli();
8010628c:	e8 cc db ff ff       	call   80103e5d <popcli>
}
80106291:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106294:	5b                   	pop    %ebx
80106295:	5e                   	pop    %esi
80106296:	5f                   	pop    %edi
80106297:	5d                   	pop    %ebp
80106298:	c3                   	ret    
    panic("switchuvm: no process");
80106299:	83 ec 0c             	sub    $0xc,%esp
8010629c:	68 12 71 10 80       	push   $0x80107112
801062a1:	e8 a2 a0 ff ff       	call   80100348 <panic>
    panic("switchuvm: no kstack");
801062a6:	83 ec 0c             	sub    $0xc,%esp
801062a9:	68 28 71 10 80       	push   $0x80107128
801062ae:	e8 95 a0 ff ff       	call   80100348 <panic>
    panic("switchuvm: no pgdir");
801062b3:	83 ec 0c             	sub    $0xc,%esp
801062b6:	68 3d 71 10 80       	push   $0x8010713d
801062bb:	e8 88 a0 ff ff       	call   80100348 <panic>

801062c0 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
801062c0:	55                   	push   %ebp
801062c1:	89 e5                	mov    %esp,%ebp
801062c3:	56                   	push   %esi
801062c4:	53                   	push   %ebx
801062c5:	8b 75 10             	mov    0x10(%ebp),%esi
  char *mem;

  if(sz >= PGSIZE)
801062c8:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
801062ce:	77 51                	ja     80106321 <inituvm+0x61>
    panic("inituvm: more than a page");
  mem = kalloc(-2);
801062d0:	83 ec 0c             	sub    $0xc,%esp
801062d3:	6a fe                	push   $0xfffffffe
801062d5:	e8 26 bf ff ff       	call   80102200 <kalloc>
801062da:	89 c3                	mov    %eax,%ebx
  memset(mem, 0, PGSIZE);
801062dc:	83 c4 0c             	add    $0xc,%esp
801062df:	68 00 10 00 00       	push   $0x1000
801062e4:	6a 00                	push   $0x0
801062e6:	50                   	push   %eax
801062e7:	e8 bd dc ff ff       	call   80103fa9 <memset>
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
801062ec:	83 c4 08             	add    $0x8,%esp
801062ef:	6a 06                	push   $0x6
801062f1:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801062f7:	50                   	push   %eax
801062f8:	b9 00 10 00 00       	mov    $0x1000,%ecx
801062fd:	ba 00 00 00 00       	mov    $0x0,%edx
80106302:	8b 45 08             	mov    0x8(%ebp),%eax
80106305:	e8 ca fc ff ff       	call   80105fd4 <mappages>
  memmove(mem, init, sz);
8010630a:	83 c4 0c             	add    $0xc,%esp
8010630d:	56                   	push   %esi
8010630e:	ff 75 0c             	pushl  0xc(%ebp)
80106311:	53                   	push   %ebx
80106312:	e8 0d dd ff ff       	call   80104024 <memmove>
}
80106317:	83 c4 10             	add    $0x10,%esp
8010631a:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010631d:	5b                   	pop    %ebx
8010631e:	5e                   	pop    %esi
8010631f:	5d                   	pop    %ebp
80106320:	c3                   	ret    
    panic("inituvm: more than a page");
80106321:	83 ec 0c             	sub    $0xc,%esp
80106324:	68 51 71 10 80       	push   $0x80107151
80106329:	e8 1a a0 ff ff       	call   80100348 <panic>

8010632e <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
8010632e:	55                   	push   %ebp
8010632f:	89 e5                	mov    %esp,%ebp
80106331:	57                   	push   %edi
80106332:	56                   	push   %esi
80106333:	53                   	push   %ebx
80106334:	83 ec 0c             	sub    $0xc,%esp
80106337:	8b 7d 18             	mov    0x18(%ebp),%edi
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
8010633a:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
80106341:	75 07                	jne    8010634a <loaduvm+0x1c>
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80106343:	bb 00 00 00 00       	mov    $0x0,%ebx
80106348:	eb 3c                	jmp    80106386 <loaduvm+0x58>
    panic("loaduvm: addr must be page aligned");
8010634a:	83 ec 0c             	sub    $0xc,%esp
8010634d:	68 0c 72 10 80       	push   $0x8010720c
80106352:	e8 f1 9f ff ff       	call   80100348 <panic>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
80106357:	83 ec 0c             	sub    $0xc,%esp
8010635a:	68 6b 71 10 80       	push   $0x8010716b
8010635f:	e8 e4 9f ff ff       	call   80100348 <panic>
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, P2V(pa), offset+i, n) != n)
80106364:	05 00 00 00 80       	add    $0x80000000,%eax
80106369:	56                   	push   %esi
8010636a:	89 da                	mov    %ebx,%edx
8010636c:	03 55 14             	add    0x14(%ebp),%edx
8010636f:	52                   	push   %edx
80106370:	50                   	push   %eax
80106371:	ff 75 10             	pushl  0x10(%ebp)
80106374:	e8 06 b4 ff ff       	call   8010177f <readi>
80106379:	83 c4 10             	add    $0x10,%esp
8010637c:	39 f0                	cmp    %esi,%eax
8010637e:	75 47                	jne    801063c7 <loaduvm+0x99>
  for(i = 0; i < sz; i += PGSIZE){
80106380:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106386:	39 fb                	cmp    %edi,%ebx
80106388:	73 30                	jae    801063ba <loaduvm+0x8c>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
8010638a:	89 da                	mov    %ebx,%edx
8010638c:	03 55 0c             	add    0xc(%ebp),%edx
8010638f:	b9 00 00 00 00       	mov    $0x0,%ecx
80106394:	8b 45 08             	mov    0x8(%ebp),%eax
80106397:	e8 c0 fb ff ff       	call   80105f5c <walkpgdir>
8010639c:	85 c0                	test   %eax,%eax
8010639e:	74 b7                	je     80106357 <loaduvm+0x29>
    pa = PTE_ADDR(*pte);
801063a0:	8b 00                	mov    (%eax),%eax
801063a2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    if(sz - i < PGSIZE)
801063a7:	89 fe                	mov    %edi,%esi
801063a9:	29 de                	sub    %ebx,%esi
801063ab:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
801063b1:	76 b1                	jbe    80106364 <loaduvm+0x36>
      n = PGSIZE;
801063b3:	be 00 10 00 00       	mov    $0x1000,%esi
801063b8:	eb aa                	jmp    80106364 <loaduvm+0x36>
      return -1;
  }
  return 0;
801063ba:	b8 00 00 00 00       	mov    $0x0,%eax
}
801063bf:	8d 65 f4             	lea    -0xc(%ebp),%esp
801063c2:	5b                   	pop    %ebx
801063c3:	5e                   	pop    %esi
801063c4:	5f                   	pop    %edi
801063c5:	5d                   	pop    %ebp
801063c6:	c3                   	ret    
      return -1;
801063c7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063cc:	eb f1                	jmp    801063bf <loaduvm+0x91>

801063ce <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
801063ce:	55                   	push   %ebp
801063cf:	89 e5                	mov    %esp,%ebp
801063d1:	57                   	push   %edi
801063d2:	56                   	push   %esi
801063d3:	53                   	push   %ebx
801063d4:	83 ec 0c             	sub    $0xc,%esp
801063d7:	8b 7d 0c             	mov    0xc(%ebp),%edi
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
801063da:	39 7d 10             	cmp    %edi,0x10(%ebp)
801063dd:	73 11                	jae    801063f0 <deallocuvm+0x22>
    return oldsz;

  a = PGROUNDUP(newsz);
801063df:	8b 45 10             	mov    0x10(%ebp),%eax
801063e2:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
801063e8:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a  < oldsz; a += PGSIZE){
801063ee:	eb 19                	jmp    80106409 <deallocuvm+0x3b>
    return oldsz;
801063f0:	89 f8                	mov    %edi,%eax
801063f2:	eb 64                	jmp    80106458 <deallocuvm+0x8a>
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(!pte)
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
801063f4:	c1 eb 16             	shr    $0x16,%ebx
801063f7:	83 c3 01             	add    $0x1,%ebx
801063fa:	c1 e3 16             	shl    $0x16,%ebx
801063fd:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
  for(; a  < oldsz; a += PGSIZE){
80106403:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106409:	39 fb                	cmp    %edi,%ebx
8010640b:	73 48                	jae    80106455 <deallocuvm+0x87>
    pte = walkpgdir(pgdir, (char*)a, 0);
8010640d:	b9 00 00 00 00       	mov    $0x0,%ecx
80106412:	89 da                	mov    %ebx,%edx
80106414:	8b 45 08             	mov    0x8(%ebp),%eax
80106417:	e8 40 fb ff ff       	call   80105f5c <walkpgdir>
8010641c:	89 c6                	mov    %eax,%esi
    if(!pte)
8010641e:	85 c0                	test   %eax,%eax
80106420:	74 d2                	je     801063f4 <deallocuvm+0x26>
    else if((*pte & PTE_P) != 0){
80106422:	8b 00                	mov    (%eax),%eax
80106424:	a8 01                	test   $0x1,%al
80106426:	74 db                	je     80106403 <deallocuvm+0x35>
      pa = PTE_ADDR(*pte);
      if(pa == 0)
80106428:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010642d:	74 19                	je     80106448 <deallocuvm+0x7a>
        panic("kfree");
      char *v = P2V(pa);
8010642f:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
80106434:	83 ec 0c             	sub    $0xc,%esp
80106437:	50                   	push   %eax
80106438:	e8 ca bb ff ff       	call   80102007 <kfree>
      *pte = 0;
8010643d:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80106443:	83 c4 10             	add    $0x10,%esp
80106446:	eb bb                	jmp    80106403 <deallocuvm+0x35>
        panic("kfree");
80106448:	83 ec 0c             	sub    $0xc,%esp
8010644b:	68 a6 6a 10 80       	push   $0x80106aa6
80106450:	e8 f3 9e ff ff       	call   80100348 <panic>
    }
  }
  return newsz;
80106455:	8b 45 10             	mov    0x10(%ebp),%eax
}
80106458:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010645b:	5b                   	pop    %ebx
8010645c:	5e                   	pop    %esi
8010645d:	5f                   	pop    %edi
8010645e:	5d                   	pop    %ebp
8010645f:	c3                   	ret    

80106460 <allocuvm>:
{
80106460:	55                   	push   %ebp
80106461:	89 e5                	mov    %esp,%ebp
80106463:	57                   	push   %edi
80106464:	56                   	push   %esi
80106465:	53                   	push   %ebx
80106466:	83 ec 1c             	sub    $0x1c,%esp
80106469:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(newsz >= KERNBASE)
8010646c:	89 7d e4             	mov    %edi,-0x1c(%ebp)
8010646f:	85 ff                	test   %edi,%edi
80106471:	0f 88 ca 00 00 00    	js     80106541 <allocuvm+0xe1>
  if(newsz < oldsz)
80106477:	3b 7d 0c             	cmp    0xc(%ebp),%edi
8010647a:	72 65                	jb     801064e1 <allocuvm+0x81>
  a = PGROUNDUP(oldsz);
8010647c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010647f:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
80106485:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a < newsz; a += PGSIZE){
8010648b:	39 fb                	cmp    %edi,%ebx
8010648d:	0f 83 b5 00 00 00    	jae    80106548 <allocuvm+0xe8>
    mem = kalloc(pid);
80106493:	83 ec 0c             	sub    $0xc,%esp
80106496:	ff 75 14             	pushl  0x14(%ebp)
80106499:	e8 62 bd ff ff       	call   80102200 <kalloc>
8010649e:	89 c6                	mov    %eax,%esi
    if(mem == 0){
801064a0:	83 c4 10             	add    $0x10,%esp
801064a3:	85 c0                	test   %eax,%eax
801064a5:	74 42                	je     801064e9 <allocuvm+0x89>
    memset(mem, 0, PGSIZE);
801064a7:	83 ec 04             	sub    $0x4,%esp
801064aa:	68 00 10 00 00       	push   $0x1000
801064af:	6a 00                	push   $0x0
801064b1:	50                   	push   %eax
801064b2:	e8 f2 da ff ff       	call   80103fa9 <memset>
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
801064b7:	83 c4 08             	add    $0x8,%esp
801064ba:	6a 06                	push   $0x6
801064bc:	8d 86 00 00 00 80    	lea    -0x80000000(%esi),%eax
801064c2:	50                   	push   %eax
801064c3:	b9 00 10 00 00       	mov    $0x1000,%ecx
801064c8:	89 da                	mov    %ebx,%edx
801064ca:	8b 45 08             	mov    0x8(%ebp),%eax
801064cd:	e8 02 fb ff ff       	call   80105fd4 <mappages>
801064d2:	83 c4 10             	add    $0x10,%esp
801064d5:	85 c0                	test   %eax,%eax
801064d7:	78 38                	js     80106511 <allocuvm+0xb1>
  for(; a < newsz; a += PGSIZE){
801064d9:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801064df:	eb aa                	jmp    8010648b <allocuvm+0x2b>
    return oldsz;
801064e1:	8b 45 0c             	mov    0xc(%ebp),%eax
801064e4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801064e7:	eb 5f                	jmp    80106548 <allocuvm+0xe8>
      cprintf("allocuvm out of memory\n");
801064e9:	83 ec 0c             	sub    $0xc,%esp
801064ec:	68 89 71 10 80       	push   $0x80107189
801064f1:	e8 15 a1 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
801064f6:	83 c4 0c             	add    $0xc,%esp
801064f9:	ff 75 0c             	pushl  0xc(%ebp)
801064fc:	57                   	push   %edi
801064fd:	ff 75 08             	pushl  0x8(%ebp)
80106500:	e8 c9 fe ff ff       	call   801063ce <deallocuvm>
      return 0;
80106505:	83 c4 10             	add    $0x10,%esp
80106508:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
8010650f:	eb 37                	jmp    80106548 <allocuvm+0xe8>
      cprintf("allocuvm out of memory (2)\n");
80106511:	83 ec 0c             	sub    $0xc,%esp
80106514:	68 a1 71 10 80       	push   $0x801071a1
80106519:	e8 ed a0 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
8010651e:	83 c4 0c             	add    $0xc,%esp
80106521:	ff 75 0c             	pushl  0xc(%ebp)
80106524:	57                   	push   %edi
80106525:	ff 75 08             	pushl  0x8(%ebp)
80106528:	e8 a1 fe ff ff       	call   801063ce <deallocuvm>
      kfree(mem);
8010652d:	89 34 24             	mov    %esi,(%esp)
80106530:	e8 d2 ba ff ff       	call   80102007 <kfree>
      return 0;
80106535:	83 c4 10             	add    $0x10,%esp
80106538:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
8010653f:	eb 07                	jmp    80106548 <allocuvm+0xe8>
    return 0;
80106541:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
}
80106548:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010654b:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010654e:	5b                   	pop    %ebx
8010654f:	5e                   	pop    %esi
80106550:	5f                   	pop    %edi
80106551:	5d                   	pop    %ebp
80106552:	c3                   	ret    

80106553 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80106553:	55                   	push   %ebp
80106554:	89 e5                	mov    %esp,%ebp
80106556:	56                   	push   %esi
80106557:	53                   	push   %ebx
80106558:	8b 75 08             	mov    0x8(%ebp),%esi
  uint i;

  if(pgdir == 0)
8010655b:	85 f6                	test   %esi,%esi
8010655d:	74 1a                	je     80106579 <freevm+0x26>
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
8010655f:	83 ec 04             	sub    $0x4,%esp
80106562:	6a 00                	push   $0x0
80106564:	68 00 00 00 80       	push   $0x80000000
80106569:	56                   	push   %esi
8010656a:	e8 5f fe ff ff       	call   801063ce <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
8010656f:	83 c4 10             	add    $0x10,%esp
80106572:	bb 00 00 00 00       	mov    $0x0,%ebx
80106577:	eb 10                	jmp    80106589 <freevm+0x36>
    panic("freevm: no pgdir");
80106579:	83 ec 0c             	sub    $0xc,%esp
8010657c:	68 bd 71 10 80       	push   $0x801071bd
80106581:	e8 c2 9d ff ff       	call   80100348 <panic>
  for(i = 0; i < NPDENTRIES; i++){
80106586:	83 c3 01             	add    $0x1,%ebx
80106589:	81 fb ff 03 00 00    	cmp    $0x3ff,%ebx
8010658f:	77 1f                	ja     801065b0 <freevm+0x5d>
    if(pgdir[i] & PTE_P){
80106591:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
80106594:	a8 01                	test   $0x1,%al
80106596:	74 ee                	je     80106586 <freevm+0x33>
      char * v = P2V(PTE_ADDR(pgdir[i]));
80106598:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010659d:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
801065a2:	83 ec 0c             	sub    $0xc,%esp
801065a5:	50                   	push   %eax
801065a6:	e8 5c ba ff ff       	call   80102007 <kfree>
801065ab:	83 c4 10             	add    $0x10,%esp
801065ae:	eb d6                	jmp    80106586 <freevm+0x33>
    }
  }
  kfree((char*)pgdir);
801065b0:	83 ec 0c             	sub    $0xc,%esp
801065b3:	56                   	push   %esi
801065b4:	e8 4e ba ff ff       	call   80102007 <kfree>
}
801065b9:	83 c4 10             	add    $0x10,%esp
801065bc:	8d 65 f8             	lea    -0x8(%ebp),%esp
801065bf:	5b                   	pop    %ebx
801065c0:	5e                   	pop    %esi
801065c1:	5d                   	pop    %ebp
801065c2:	c3                   	ret    

801065c3 <setupkvm>:
{
801065c3:	55                   	push   %ebp
801065c4:	89 e5                	mov    %esp,%ebp
801065c6:	56                   	push   %esi
801065c7:	53                   	push   %ebx
  if((pgdir = (pde_t*)kalloc(-2)) == 0)
801065c8:	83 ec 0c             	sub    $0xc,%esp
801065cb:	6a fe                	push   $0xfffffffe
801065cd:	e8 2e bc ff ff       	call   80102200 <kalloc>
801065d2:	89 c6                	mov    %eax,%esi
801065d4:	83 c4 10             	add    $0x10,%esp
801065d7:	85 c0                	test   %eax,%eax
801065d9:	74 55                	je     80106630 <setupkvm+0x6d>
  memset(pgdir, 0, PGSIZE);
801065db:	83 ec 04             	sub    $0x4,%esp
801065de:	68 00 10 00 00       	push   $0x1000
801065e3:	6a 00                	push   $0x0
801065e5:	50                   	push   %eax
801065e6:	e8 be d9 ff ff       	call   80103fa9 <memset>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801065eb:	83 c4 10             	add    $0x10,%esp
801065ee:	bb 20 a4 10 80       	mov    $0x8010a420,%ebx
801065f3:	81 fb 60 a4 10 80    	cmp    $0x8010a460,%ebx
801065f9:	73 35                	jae    80106630 <setupkvm+0x6d>
                (uint)k->phys_start, k->perm) < 0) {
801065fb:	8b 43 04             	mov    0x4(%ebx),%eax
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
801065fe:	8b 4b 08             	mov    0x8(%ebx),%ecx
80106601:	29 c1                	sub    %eax,%ecx
80106603:	83 ec 08             	sub    $0x8,%esp
80106606:	ff 73 0c             	pushl  0xc(%ebx)
80106609:	50                   	push   %eax
8010660a:	8b 13                	mov    (%ebx),%edx
8010660c:	89 f0                	mov    %esi,%eax
8010660e:	e8 c1 f9 ff ff       	call   80105fd4 <mappages>
80106613:	83 c4 10             	add    $0x10,%esp
80106616:	85 c0                	test   %eax,%eax
80106618:	78 05                	js     8010661f <setupkvm+0x5c>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
8010661a:	83 c3 10             	add    $0x10,%ebx
8010661d:	eb d4                	jmp    801065f3 <setupkvm+0x30>
      freevm(pgdir);
8010661f:	83 ec 0c             	sub    $0xc,%esp
80106622:	56                   	push   %esi
80106623:	e8 2b ff ff ff       	call   80106553 <freevm>
      return 0;
80106628:	83 c4 10             	add    $0x10,%esp
8010662b:	be 00 00 00 00       	mov    $0x0,%esi
}
80106630:	89 f0                	mov    %esi,%eax
80106632:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106635:	5b                   	pop    %ebx
80106636:	5e                   	pop    %esi
80106637:	5d                   	pop    %ebp
80106638:	c3                   	ret    

80106639 <kvmalloc>:
{
80106639:	55                   	push   %ebp
8010663a:	89 e5                	mov    %esp,%ebp
8010663c:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
8010663f:	e8 7f ff ff ff       	call   801065c3 <setupkvm>
80106644:	a3 e4 54 19 80       	mov    %eax,0x801954e4
  switchkvm();
80106649:	e8 48 fb ff ff       	call   80106196 <switchkvm>
}
8010664e:	c9                   	leave  
8010664f:	c3                   	ret    

80106650 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80106650:	55                   	push   %ebp
80106651:	89 e5                	mov    %esp,%ebp
80106653:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80106656:	b9 00 00 00 00       	mov    $0x0,%ecx
8010665b:	8b 55 0c             	mov    0xc(%ebp),%edx
8010665e:	8b 45 08             	mov    0x8(%ebp),%eax
80106661:	e8 f6 f8 ff ff       	call   80105f5c <walkpgdir>
  if(pte == 0)
80106666:	85 c0                	test   %eax,%eax
80106668:	74 05                	je     8010666f <clearpteu+0x1f>
    panic("clearpteu");
  *pte &= ~PTE_U;
8010666a:	83 20 fb             	andl   $0xfffffffb,(%eax)
}
8010666d:	c9                   	leave  
8010666e:	c3                   	ret    
    panic("clearpteu");
8010666f:	83 ec 0c             	sub    $0xc,%esp
80106672:	68 ce 71 10 80       	push   $0x801071ce
80106677:	e8 cc 9c ff ff       	call   80100348 <panic>

8010667c <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz, int pid)
{
8010667c:	55                   	push   %ebp
8010667d:	89 e5                	mov    %esp,%ebp
8010667f:	57                   	push   %edi
80106680:	56                   	push   %esi
80106681:	53                   	push   %ebx
80106682:	83 ec 1c             	sub    $0x1c,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
80106685:	e8 39 ff ff ff       	call   801065c3 <setupkvm>
8010668a:	89 45 dc             	mov    %eax,-0x24(%ebp)
8010668d:	85 c0                	test   %eax,%eax
8010668f:	0f 84 d1 00 00 00    	je     80106766 <copyuvm+0xea>
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80106695:	bf 00 00 00 00       	mov    $0x0,%edi
8010669a:	89 fe                	mov    %edi,%esi
8010669c:	3b 75 0c             	cmp    0xc(%ebp),%esi
8010669f:	0f 83 c1 00 00 00    	jae    80106766 <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
801066a5:	89 75 e4             	mov    %esi,-0x1c(%ebp)
801066a8:	b9 00 00 00 00       	mov    $0x0,%ecx
801066ad:	89 f2                	mov    %esi,%edx
801066af:	8b 45 08             	mov    0x8(%ebp),%eax
801066b2:	e8 a5 f8 ff ff       	call   80105f5c <walkpgdir>
801066b7:	85 c0                	test   %eax,%eax
801066b9:	74 70                	je     8010672b <copyuvm+0xaf>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
801066bb:	8b 18                	mov    (%eax),%ebx
801066bd:	f6 c3 01             	test   $0x1,%bl
801066c0:	74 76                	je     80106738 <copyuvm+0xbc>
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
801066c2:	89 df                	mov    %ebx,%edi
801066c4:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
    flags = PTE_FLAGS(*pte);
801066ca:	81 e3 ff 0f 00 00    	and    $0xfff,%ebx
801066d0:	89 5d e0             	mov    %ebx,-0x20(%ebp)
    if((mem = kalloc(pid)) == 0)
801066d3:	83 ec 0c             	sub    $0xc,%esp
801066d6:	ff 75 10             	pushl  0x10(%ebp)
801066d9:	e8 22 bb ff ff       	call   80102200 <kalloc>
801066de:	89 c3                	mov    %eax,%ebx
801066e0:	83 c4 10             	add    $0x10,%esp
801066e3:	85 c0                	test   %eax,%eax
801066e5:	74 6a                	je     80106751 <copyuvm+0xd5>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
801066e7:	81 c7 00 00 00 80    	add    $0x80000000,%edi
801066ed:	83 ec 04             	sub    $0x4,%esp
801066f0:	68 00 10 00 00       	push   $0x1000
801066f5:	57                   	push   %edi
801066f6:	50                   	push   %eax
801066f7:	e8 28 d9 ff ff       	call   80104024 <memmove>
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0) {
801066fc:	83 c4 08             	add    $0x8,%esp
801066ff:	ff 75 e0             	pushl  -0x20(%ebp)
80106702:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80106708:	50                   	push   %eax
80106709:	b9 00 10 00 00       	mov    $0x1000,%ecx
8010670e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80106711:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106714:	e8 bb f8 ff ff       	call   80105fd4 <mappages>
80106719:	83 c4 10             	add    $0x10,%esp
8010671c:	85 c0                	test   %eax,%eax
8010671e:	78 25                	js     80106745 <copyuvm+0xc9>
  for(i = 0; i < sz; i += PGSIZE){
80106720:	81 c6 00 10 00 00    	add    $0x1000,%esi
80106726:	e9 71 ff ff ff       	jmp    8010669c <copyuvm+0x20>
      panic("copyuvm: pte should exist");
8010672b:	83 ec 0c             	sub    $0xc,%esp
8010672e:	68 d8 71 10 80       	push   $0x801071d8
80106733:	e8 10 9c ff ff       	call   80100348 <panic>
      panic("copyuvm: page not present");
80106738:	83 ec 0c             	sub    $0xc,%esp
8010673b:	68 f2 71 10 80       	push   $0x801071f2
80106740:	e8 03 9c ff ff       	call   80100348 <panic>
      kfree(mem);
80106745:	83 ec 0c             	sub    $0xc,%esp
80106748:	53                   	push   %ebx
80106749:	e8 b9 b8 ff ff       	call   80102007 <kfree>
      goto bad;
8010674e:	83 c4 10             	add    $0x10,%esp
    }
  }
  return d;

bad:
  freevm(d);
80106751:	83 ec 0c             	sub    $0xc,%esp
80106754:	ff 75 dc             	pushl  -0x24(%ebp)
80106757:	e8 f7 fd ff ff       	call   80106553 <freevm>
  return 0;
8010675c:	83 c4 10             	add    $0x10,%esp
8010675f:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
}
80106766:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106769:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010676c:	5b                   	pop    %ebx
8010676d:	5e                   	pop    %esi
8010676e:	5f                   	pop    %edi
8010676f:	5d                   	pop    %ebp
80106770:	c3                   	ret    

80106771 <uva2ka>:

// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80106771:	55                   	push   %ebp
80106772:	89 e5                	mov    %esp,%ebp
80106774:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80106777:	b9 00 00 00 00       	mov    $0x0,%ecx
8010677c:	8b 55 0c             	mov    0xc(%ebp),%edx
8010677f:	8b 45 08             	mov    0x8(%ebp),%eax
80106782:	e8 d5 f7 ff ff       	call   80105f5c <walkpgdir>
  if((*pte & PTE_P) == 0)
80106787:	8b 00                	mov    (%eax),%eax
80106789:	a8 01                	test   $0x1,%al
8010678b:	74 10                	je     8010679d <uva2ka+0x2c>
    return 0;
  if((*pte & PTE_U) == 0)
8010678d:	a8 04                	test   $0x4,%al
8010678f:	74 13                	je     801067a4 <uva2ka+0x33>
    return 0;
  return (char*)P2V(PTE_ADDR(*pte));
80106791:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80106796:	05 00 00 00 80       	add    $0x80000000,%eax
}
8010679b:	c9                   	leave  
8010679c:	c3                   	ret    
    return 0;
8010679d:	b8 00 00 00 00       	mov    $0x0,%eax
801067a2:	eb f7                	jmp    8010679b <uva2ka+0x2a>
    return 0;
801067a4:	b8 00 00 00 00       	mov    $0x0,%eax
801067a9:	eb f0                	jmp    8010679b <uva2ka+0x2a>

801067ab <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801067ab:	55                   	push   %ebp
801067ac:	89 e5                	mov    %esp,%ebp
801067ae:	57                   	push   %edi
801067af:	56                   	push   %esi
801067b0:	53                   	push   %ebx
801067b1:	83 ec 0c             	sub    $0xc,%esp
801067b4:	8b 7d 14             	mov    0x14(%ebp),%edi
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801067b7:	eb 25                	jmp    801067de <copyout+0x33>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
801067b9:	8b 55 0c             	mov    0xc(%ebp),%edx
801067bc:	29 f2                	sub    %esi,%edx
801067be:	01 d0                	add    %edx,%eax
801067c0:	83 ec 04             	sub    $0x4,%esp
801067c3:	53                   	push   %ebx
801067c4:	ff 75 10             	pushl  0x10(%ebp)
801067c7:	50                   	push   %eax
801067c8:	e8 57 d8 ff ff       	call   80104024 <memmove>
    len -= n;
801067cd:	29 df                	sub    %ebx,%edi
    buf += n;
801067cf:	01 5d 10             	add    %ebx,0x10(%ebp)
    va = va0 + PGSIZE;
801067d2:	8d 86 00 10 00 00    	lea    0x1000(%esi),%eax
801067d8:	89 45 0c             	mov    %eax,0xc(%ebp)
801067db:	83 c4 10             	add    $0x10,%esp
  while(len > 0){
801067de:	85 ff                	test   %edi,%edi
801067e0:	74 2f                	je     80106811 <copyout+0x66>
    va0 = (uint)PGROUNDDOWN(va);
801067e2:	8b 75 0c             	mov    0xc(%ebp),%esi
801067e5:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    pa0 = uva2ka(pgdir, (char*)va0);
801067eb:	83 ec 08             	sub    $0x8,%esp
801067ee:	56                   	push   %esi
801067ef:	ff 75 08             	pushl  0x8(%ebp)
801067f2:	e8 7a ff ff ff       	call   80106771 <uva2ka>
    if(pa0 == 0)
801067f7:	83 c4 10             	add    $0x10,%esp
801067fa:	85 c0                	test   %eax,%eax
801067fc:	74 20                	je     8010681e <copyout+0x73>
    n = PGSIZE - (va - va0);
801067fe:	89 f3                	mov    %esi,%ebx
80106800:	2b 5d 0c             	sub    0xc(%ebp),%ebx
80106803:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    if(n > len)
80106809:	39 df                	cmp    %ebx,%edi
8010680b:	73 ac                	jae    801067b9 <copyout+0xe>
      n = len;
8010680d:	89 fb                	mov    %edi,%ebx
8010680f:	eb a8                	jmp    801067b9 <copyout+0xe>
  }
  return 0;
80106811:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106816:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106819:	5b                   	pop    %ebx
8010681a:	5e                   	pop    %esi
8010681b:	5f                   	pop    %edi
8010681c:	5d                   	pop    %ebp
8010681d:	c3                   	ret    
      return -1;
8010681e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106823:	eb f1                	jmp    80106816 <copyout+0x6b>
