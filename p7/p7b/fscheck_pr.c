//All include files
#include <stdio.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <sys/stat.h>

#define BSIZE 512
#define DIRSIZ 14
#define NDIRECT 12
#define NINDIRECT BSIZE/sizeof(uint)

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
  uint addrs[13];   	// Data block addresses
};

struct dirent {
  ushort inum;
  char name[DIRSIZ];
};

int main(int argc, char* argv[]) {
//All declarations
	int fd;
	struct stat s;
	void *fsmap;
	struct superblock *sb;
	struct dinode *ip;
	uint8_t *bptrmap;
	int nblk = 0;

	if(argc < 2 || argc > 2) {
		printf("Usage: fscheck <file_system_image>\n");
	}
	else {
		if((fd = open(argv[1], O_RDONLY)) < 0)
			printf("Error: Image not found\n");
	}

	fstat(fd, &s);
	fsmap = mmap(NULL, s.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
	sb = (struct superblock*)(fsmap + BSIZE);
	int bmap[sb->size];
	int amap[sb->size];
	bptrmap = (uint8_t*)(fsmap + BSIZE*(sb->bmapstart));
	ip = (struct dinode*)(fsmap + BSIZE*(sb->inodestart));

	int j = 0;
	int mask;
	for (int i = 0; i<sb->size; i++) {
		mask = 0;
	        mask = 1 << j;
		amap[i] = 0;
		j++;
		bmap[i] = (*bptrmap & mask);
		if(j == 8) {
			j = 0;
			bptrmap++;
		}
	}

	for (int i = 0; i < sb->ninodes; i++) {
		if(ip->nlink > 0) {
			for (int j = 0; j <= NDIRECT; j++) {
				if(ip->addrs[j] !=0) {
					if(bmap[ip->addrs[j]] == 0) {
						fprintf(stderr, "ERROR: bitmap marks data free but data block used by inode.\n");
						exit(1);
					}
					nblk++;
					amap[ip->addrs[j]] = 1;
				}
			}
			if(ip->addrs[NDIRECT] != 0) {
				uint* iptr = (uint *)(fsmap + (BSIZE*(ip->addrs[NDIRECT])));
				for (int j = 0; j < NINDIRECT; j++) {
					if(*iptr != 0 ) {
						nblk++;
						amap[*iptr] = 1;
						if(bmap[*iptr] == 0) {
							fprintf(stderr, "ERROR: bitmap marks data free but data block used by inode.\n");
							exit(1);
						}
					}
					iptr++;
				}
			}		
		}		
		ip++;
	}

	for (int i = 59; i < sb->size; i++) {
		if(bmap[i] != 0) {
			if (amap[i] == 0) {
				fprintf(stderr, "ERROR: bitmap marks data block in use but not used.\n");
				exit(1);
			}
		}
	}

	ip = (struct dinode*)(fsmap + BSIZE*(sb->inodestart));
	for(int i = 0; i < sb->ninodes; i++) {
		if(ip->nlink >0){ 
			if(ip->type < 1 || ip->type > 3) {
				fprintf(stderr, "ERROR: bad inode.\n");
				exit(1);
			}
		}
		ip++;		
	}
	ip = (struct dinode*)(fsmap + BSIZE*(sb->inodestart));
	for (int i = 0; i < sb->ninodes; i++) {
		if(ip->nlink > 0) {
			int numBlocks = 0;
			for (int j = 0; j < NDIRECT; j++) {
				if(ip->addrs[j] !=0) {
					numBlocks++;
				}
			}
			if(ip->addrs[NDIRECT] != 0) {
				uint* iptr = (uint *)(fsmap + (BSIZE*(ip->addrs[NDIRECT])));
				for (int j = 0; j < NINDIRECT; j++) {
					if(*iptr != 0 ) {
						numBlocks++;
					}
					iptr++;
				}
			}
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
			
		}		
		ip++;
	}

	ip = (struct dinode*)(fsmap + BSIZE*(sb->inodestart));
	ip++;
	if(ip->type != 1) {
		fprintf(stderr, "ERROR: root directory does not exist.\n");
		exit(1);
	} else {
		struct dirent* directEntry = (struct dirent*)(fsmap + (BSIZE*ip->addrs[0]));
		if(directEntry->inum != 1 || (directEntry+1)->inum != 1) {
			fprintf(stderr, "ERROR: root directory does not exist.\n");
			exit(1);
		}
	}

	ip = (struct dinode*)(fsmap + BSIZE*(sb->inodestart));
	for (int i = 0; i < sb->ninodes; i++) {
		if(ip->type == 1) {
			struct dirent* directEntry = (struct dirent*)(fsmap + (BSIZE*ip->addrs[0]));
			if(directEntry->inum != i) {
				fprintf(stderr, "ERROR: current directory mismatch.\n");
				exit(1);
			}
		}
		ip++;
	}

	
	int inodeTable[sb->ninodes];
	int actualInodeTable[sb->ninodes];
	ip = (struct dinode*)(fsmap + BSIZE*(sb->inodestart));
	for (int i = 0; i < sb->ninodes; i++) {
		actualInodeTable[i] = 0;
		if(ip->nlink > 0) {
			inodeTable[i] = 1;
		}
		ip++;
	}
    
	ip = (struct dinode*)(fsmap + BSIZE*(sb->inodestart));
	for (int i = 0; i < sb->ninodes; i++) {
		if(ip->type == 1 && ip->nlink > 0) {
			for (int j = 0; j < NDIRECT; j++) {
				if(ip->addrs[j] !=0) {
					int iter = 0;    
					struct dirent* directEntry = (struct dirent*)(fsmap + (BSIZE*ip->addrs[j]));
                    while(iter < BSIZE && directEntry->inum != 0) {
                    	actualInodeTable[directEntry->inum] = 1;
                    	iter = iter + sizeof(struct dirent);
                    	directEntry++;
                    }
                }
			}
			
			if(ip->addrs[NDIRECT] != 0)
			{
                uint* iptr = (uint *)(fsmap + (BSIZE*(ip->addrs[NDIRECT])));
				for (int j = 0; j < NINDIRECT; j++) {
					if(*iptr != 0 ) {
						
						int iter = 0;    
					    struct dirent* directEntry = (struct dirent*)(fsmap + (BSIZE*(*iptr)));
                        while(iter < BSIZE && directEntry->inum != 0) {
                    	    actualInodeTable[directEntry->inum] = 1;
                    	    iter = iter + sizeof(struct dirent);
                    	    directEntry++;
                        }
					}
					iptr++;
				}
			}
		}
		ip++;
	}

	for (int i = 0; i < sb->ninodes; i++)
	{
		if(actualInodeTable[i] == 1 && inodeTable[i] != 1) {
			fprintf(stderr, "ERROR: inode marked free but referred to in directory.\n");
			exit(1);
		}
	}
	for (int i = 0; i < sb->ninodes; i++)
	{
		if(inodeTable[i] == 1 && actualInodeTable[i] != 1) {
			fprintf(stderr, "ERROR: inode marked in use but not found in a directory.\n");
			exit(1);
		}
	}
	return 0;
}
