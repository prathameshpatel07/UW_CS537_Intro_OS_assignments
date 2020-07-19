#include <stdio.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <stdlib.h>
#include <fcntl.h>
#include <string.h>
#include <stdint.h>

#define NDIRECT 12
#define BSIZE 512
#define NINDIRECT BSIZE/sizeof(uint)
#define T_DIR  1   // Directory
#define T_FILE 2   // File
#define T_DEV  3   // Device
#define DIRSIZ 14

struct superblock {
  uint size;         // Size of file system image (blocks)
  uint nblocks;      // Number of data blocks
  uint ninodes;      // Number of inodes.
  uint nlog;         // Number of log blocks
  uint logstart;     // Block number of first log block
  uint inodestart;   // Block number of first inode block
  uint bmapstart;    // Block number of first free map block
};

struct dinode {
  short type;           // File type
  short major;          // Major device number (T_DEV only)
  short minor;          // Minor device number (T_DEV only)
  short nlink;          // Number of links to inode in file system
  uint size;            // Size of file (bytes)
  uint addrs[13];   // Data block addresses
};

struct dirent {
  ushort inum;
  char name[DIRSIZ];
};

int main(int argc, char* argv[]) {
	if(argc != 2) {
		printf("Usage: fscheck <file_system_image>\n");
	}

	int fsimagefd;
	if((fsimagefd = open(argv[1], O_RDONLY)) < 0) {
		printf("Error: Image not found\n");
	}
	struct stat s;
	if(fstat(fsimagefd, &s) < 0 ){
		printf("Error: Could not get stats\n");
	}

	void* fsimageptr = mmap(NULL, s.st_size, PROT_READ, MAP_PRIVATE, fsimagefd, 0);
	struct superblock *sb = (struct superblock*) (fsimageptr + 512);
	// printf("size: %u\n", sb->size);
	// printf("nblocks: %u\n", sb->nblocks);
	// printf("ninodes: %u\n", sb->ninodes);
	// printf("nlog: %u\n", sb->nlog);
	// printf("logstart: %u\n", sb->logstart);
	// printf("inodestart: %u\n", sb->inodestart);
	// printf("bmapstart: %u\n", sb->bmapstart);

	// Check for bad inode (Check 1)
	struct dinode *ip = (struct dinode*)(fsimageptr + 512*(sb->inodestart));

	// Check for bad root inode (Check 5)
	int bitmap[sb->size];
	int actualMap[sb->size];

	uint8_t* bmapptr = (uint8_t*)(fsimageptr + 512*(sb->bmapstart));
    //printf("bmap ptr: %d\n", *bmapptr);


	int count = 0;
	for (int i = 0; i < sb->size; i++) {
		
		int mask = 1 << count;
		bitmap[i] = *bmapptr & mask;
		count++;
		if(count == 8) {
			count = 0;
			bmapptr++;
		}
		actualMap[i] = 0;
	}
	

	ip = (struct dinode*)(fsimageptr + 512*(sb->inodestart));
	int totalNumBlocks = 0;
	for (int i = 0; i < sb->ninodes; i++) {
		if(ip->nlink > 0) { //ignoring the unallocated ips
			for (int j = 0; j <= NDIRECT; j++) {//counting allocated direct blocks
				if(ip->addrs[j] !=0) {
					//printf("data block: %d\n", ip->addrs[j]);
					totalNumBlocks++;
					actualMap[ip->addrs[j]] = 1;
					//printf("DIRECT i: %d, block:%d \n", i, ip->addrs[j]);
					if(bitmap[ip->addrs[j]] == 0) {
						fprintf(stderr, "ERROR: bitmap marks data free but data block used by inode.\n");
						exit(1);
					}
				}
			}
			if(ip->addrs[NDIRECT] != 0) {
				uint* indirectptr = (uint *)(fsimageptr + (BSIZE*(ip->addrs[NDIRECT])));
				for (int j = 0; j < NINDIRECT; j++) {
					if(*indirectptr != 0 ) {
						//printf("data block: %d\n", *indirectptr);
						totalNumBlocks++;
						actualMap[*indirectptr] = 1;
						//printf("INDIRECT i: %d, block:%d \n", i, *indirectptr);
						if(bitmap[*indirectptr] == 0) {
							fprintf(stderr, "ERROR: bitmap marks data free but data block used by inode.\n");
							exit(1);
						}
					}
					indirectptr++;
				}
			}		
			//printf("i: %d, nlink: %d,  size: %d, numblocks: %d\n", i, ip->nlink, ip->size, numBlocks);
		}		
		ip++;
	}

	for (int i = 59; i < sb->size; i++) {
		if(bitmap[i] != 0) {
			if (actualMap[i] == 0) {
				//printf("for block: %d bitmap : %d actualMap: %d\n", i, bitmap[i], actualMap[i]);
				fprintf(stderr, "ERROR: bitmap marks data block in use but not used.\n");
				exit(1);
			}
		}
	}




	ip = (struct dinode*)(fsimageptr + 512*(sb->inodestart));
	
	for(int i = 0; i < sb->ninodes; i++) {
		//printf("i: %d, type: %d, nlink: %d, size: %d\n", i, ip->type, ip->nlink, ip->size);
		if(ip->nlink >0){ 
			if(ip->type < 1 || ip->type > 3) {	//check			
				fprintf(stderr, "ERROR: bad inode.\n");
				exit(1);
			}
		}
		ip++;		
	}
	// Check for bad size in inode (Check 2)
	ip = (struct dinode*)(fsimageptr + 512*(sb->inodestart));
	for (int i = 0; i < sb->ninodes; i++) {
		if(ip->nlink > 0) { //ignoring the unallocated ips
			int numBlocks = 0;
			for (int j = 0; j < NDIRECT; j++) {//counting allocated direct blocks
				if(ip->addrs[j] !=0) {
					numBlocks++;
				}
			}
			if(ip->addrs[NDIRECT] != 0) {
				uint* indirectptr = (uint *)(fsimageptr + (BSIZE*(ip->addrs[NDIRECT])));
				for (int j = 0; j < NINDIRECT; j++) {
					if(*indirectptr != 0 ) {
						numBlocks++;
					}
					indirectptr++;
				}
			}
			//printf("i: %d, nlink: %d,  size: %d, numblocks: %d\n", i, ip->nlink, ip->size, numBlocks);
			if(numBlocks > 0) {
				if(ip->size  <= (numBlocks-1)*BSIZE || ip->size > numBlocks*BSIZE) {
					fprintf(stderr, "ERROR: bad size in inode.\n");
					exit(1);
				}
			} else {
				if(ip->size != 0) {
					fprintf(stderr, "ERROR: bad size in inode.\n");
					exit(1);
				}
			}
			
			//printf("i: %d, numblocks: %d\n", i, numBlocks);
		}		
		ip++;
	}

	// Check for bad root inode (Check 3)
	ip = (struct dinode*)(fsimageptr + 512*(sb->inodestart));
	ip++;//root directory inode
	//printf("i: %d, type: %d, nlink: %d, size: %d\n", 1, ip->type, ip->nlink, ip->size);
	if(ip->type != T_DIR) {
		fprintf(stderr, "ERROR: root directory does not exist.\n");
		exit(1);
	} else {
		struct dirent* directEntry = (struct dirent*)(fsimageptr + (BSIZE*ip->addrs[0]));
		//printf("directory entry num: %d, name: %s, parent inum: %d, parent name: %s\n", directEntry->inum, directEntry->name, (directEntry+1)->inum, (directEntry+1)->name);
		if(directEntry->inum != 1 || (directEntry+1)->inum != 1) {
			fprintf(stderr, "ERROR: root directory does not exist.\n");
			exit(1);
		}
	}

	// Check for bad root inode (Check 4)
	ip = (struct dinode*)(fsimageptr + 512*(sb->inodestart));
	for (int i = 0; i < sb->ninodes; i++) {
		if(ip->type == T_DIR) {
			struct dirent* directEntry = (struct dirent*)(fsimageptr + (BSIZE*ip->addrs[0]));
			if(directEntry->inum != i) {
				fprintf(stderr, "ERROR: current directory mismatch.\n");
				exit(1);
			}
		}
		ip++;
	}

	
	int inodeTable[sb->ninodes];
	int actualInodeTable[sb->ninodes];
	ip = (struct dinode*)(fsimageptr + 512*(sb->inodestart));
	for (int i = 0; i < sb->ninodes; i++) {
		actualInodeTable[i] = 0;
		if(ip->nlink > 0) {
			inodeTable[i] = 1;
		}
		ip++;
	}
    
	ip = (struct dinode*)(fsimageptr + 512*(sb->inodestart));
	for (int i = 0; i < sb->ninodes; i++) {
		if(ip->type == T_DIR && ip->nlink > 0) {
			for (int j = 0; j < NDIRECT; j++) {//counting allocated direct blocks
				if(ip->addrs[j] !=0) {
					int iter = 0;    
					struct dirent* directEntry = (struct dirent*)(fsimageptr + (BSIZE*ip->addrs[j]));
                    while(iter < BSIZE && directEntry->inum != 0) {
                    	actualInodeTable[directEntry->inum] = 1;
                    	//printf("j: %d, inum: %d, name: %s\n", j, directEntry->inum, directEntry->name);
                    	iter = iter + sizeof(struct dirent);
                    	directEntry++;
                    }
                }
			}
			
			if(ip->addrs[NDIRECT] != 0)
			{
                uint* indirectptr = (uint *)(fsimageptr + (BSIZE*(ip->addrs[NDIRECT])));
				for (int j = 0; j < NINDIRECT; j++) {
					if(*indirectptr != 0 ) {
						
						int iter = 0;    
					    struct dirent* directEntry = (struct dirent*)(fsimageptr + (BSIZE*(*indirectptr)));
                        while(iter < BSIZE && directEntry->inum != 0) {
                    	    actualInodeTable[directEntry->inum] = 1;
                    	    //printf("j: %d, inum: %d, name: %s\n", j, directEntry->inum, directEntry->name);
                    	    iter = iter + sizeof(struct dirent);
                    	    directEntry++;
                        }
					}
					indirectptr++;
				}
			}
		}
		ip++;
	}

	for (int i = 0; i < sb->ninodes; i++)
	{
		//printf("i: %d   Inode: %d    ActualInode: %d\n", i, inodeTable[i], actualInodeTable[i]);
		if(actualInodeTable[i] == 1 && inodeTable[i] != 1) {
			fprintf(stderr, "ERROR: inode marked free but referred to in directory.\n");
			exit(1);
		}
	}
	for (int i = 0; i < sb->ninodes; i++)
	{
		//printf("i: %d   Inode: %d    ActualInode: %d\n", i, inodeTable[i], actualInodeTable[i]);
		if(inodeTable[i] == 1 && actualInodeTable[i] != 1) {
			fprintf(stderr, "ERROR: inode marked in use but not found in a directory.\n");
			exit(1);
		}
	}


	return 0;

}