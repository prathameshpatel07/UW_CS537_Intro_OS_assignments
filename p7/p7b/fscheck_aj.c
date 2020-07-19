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
	void *fs_Map;
	struct superblock *sb;
	struct dinode *ip;
	uint8_t *bptr_map;
	int nblk = 0;

	if(argc < 2 || argc > 2) {
		printf("Usage: fscheck <file_system_image>\n");
	}
	else {
		if((fd = open(argv[1], O_RDONLY)) < 0)
			printf("Error: Image not found\n");
	}

	fstat(fd, &s);
	fs_Map = mmap(NULL, s.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
	sb = (struct superblock*)(fs_Map + BSIZE);
	bptr_map = (uint8_t*)(fs_Map + BSIZE*(sb->bmapstart));
	ip = (struct dinode*)(fs_Map + BSIZE*(sb->inodestart));
	int b_map[sb->size];
	int a_map[sb->size];


	int j = 0;
	int masker;
	for (int i = 0; i<sb->size; i++) {
		masker = 0;
	        masker = 1 << j;
		a_map[i] = 0;
		j++;
		b_map[i] = (*bptr_map & masker);
		if(j == 8) {
			j = 0;
			bptr_map++;
		}
	}

	for (int i = 0; i < sb->ninodes; i++) {
		if(ip->nlink > 0) {
			for (int j = 0; j <= NDIRECT; j++) {
				if(ip->addrs[j] !=0) {
					if(b_map[ip->addrs[j]] == 0) {
						fprintf(stderr, "ERROR: bitmap marks data free but data block used by inode.\n");
						exit(1);
					}
					nblk++;
					a_map[ip->addrs[j]] = 1;
				}
			}
			if(ip->addrs[NDIRECT] != 0) {
				uint* iptr = (uint *)(fs_Map + (BSIZE*(ip->addrs[NDIRECT])));
				for (int j = 0; j < NINDIRECT; j++) {
					if(*iptr != 0 ) {
						nblk++;
						a_map[*iptr] = 1;
						if(b_map[*iptr] == 0) {
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

    int loop =59;
	while (loop++ < sb->size) {
		if(b_map[loop] != 0) {
			if (a_map[loop] == 0) {
				fprintf(stderr, "ERROR: bitmap marks data block in use but not used.\n");
				exit(1);
			}
		}
	}

	ip = (struct dinode*)(fs_Map + BSIZE*(sb->inodestart));
	for(int i = 0; i < sb->ninodes; i++) {
		if(ip->nlink >0){
			if(ip->type < 1 || ip->type > 3) {
				fprintf(stderr, "ERROR: bad inode.\n");
				exit(1);
			}
		}
		ip++;
	}

	ip = (struct dinode*)(fs_Map + BSIZE*(sb->inodestart));
	for (int i = 0; i < sb->ninodes; i++) {
		if(ip->nlink > 0) {
			int blockCount = 0;
			for (int j = 0; j < NDIRECT; j++) {
				if(ip->addrs[j] !=0) {
					blockCount++;
				}
			}
			if(ip->addrs[NDIRECT] != 0) {
				uint* ipointer = (uint *)(fs_Map + (BSIZE*(ip->addrs[NDIRECT])));
				for (int j = 0; j < NINDIRECT; j++) {
					if(*ipointer != 0 ) {
						blockCount++;
					}
					ipointer++;
				}
			}
			if(blockCount > 0) {
				if(ip->size  <= (blockCount-1)*BSIZE || ip->size > blockCount*BSIZE) {
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

	ip = (struct dinode*)(fs_Map + BSIZE*(sb->inodestart));
	ip++;
	if(ip->type != 1) {
		fprintf(stderr, "ERROR: root directory does not exist.\n");
		exit(1);
	} else {
		struct dirent* de = (struct dirent*)(fs_Map + (BSIZE*ip->addrs[0]));
		if(de->inum != 1 || (de+1)->inum != 1) {
			fprintf(stderr, "ERROR: root directory does not exist.\n");
			exit(1);
		}
	}

	ip = (struct dinode*)(fs_Map + BSIZE*(sb->inodestart));
	for (int i = 0; i < sb->ninodes; i++) {
		if(ip->type == 1) {
			struct dirent* de = (struct dirent*)(fs_Map + (BSIZE*ip->addrs[0]));
			if(de->inum != i) {
				fprintf(stderr, "ERROR: current directory mismatch.\n");
				exit(1);
			}
		}
		ip++;
	}


	int iNodesArr[sb->ninodes];
	int iNode_real[sb->ninodes];
	ip = (struct dinode*)(fs_Map + BSIZE*(sb->inodestart));
	for (int i = 0; i < sb->ninodes; i++) {
		iNode_real[i] = 0;
		if(ip->nlink > 0) {
			iNodesArr[i] = 1;
		}
		ip++;
	}

	ip = (struct dinode*)(fs_Map + BSIZE*(sb->inodestart));
	for (int i = 0; i < sb->ninodes; i++) {
		if(ip->type == 1 && ip->nlink > 0) {
			for (int j = 0; j < NDIRECT; j++) {
				if(ip->addrs[j] !=0) {
					int itr = 0;
					struct dirent* de = (struct dirent*)(fs_Map + (BSIZE*ip->addrs[j]));
                    while(itr < BSIZE && de->inum != 0) {
                    	iNode_real[de->inum] = 1;
                    	itr = itr + sizeof(struct dirent);
                    	de++;
                    }
                }
			}

			if(ip->addrs[NDIRECT] != 0)
			{
                uint* iptr = (uint *)(fs_Map + (BSIZE*(ip->addrs[NDIRECT])));
				for (int j = 0; j < NINDIRECT; j++) {
					if(*iptr != 0 ) {

						int iter = 0;
					    struct dirent* de = (struct dirent*)(fs_Map + (BSIZE*(*iptr)));
                        while(iter < BSIZE && de->inum != 0) {
                    	    iNode_real[de->inum] = 1;
                    	    iter = iter + sizeof(struct dirent);
                    	    de++;
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
		if(iNode_real[i] == 1 && iNodesArr[i] != 1) {
			fprintf(stderr, "ERROR: inode marked free but referred to in directory.\n");
			exit(1);
		}
	}
	for (int i = 0; i < sb->ninodes; i++)
	{
		if(iNodesArr[i] == 1 && iNode_real[i] != 1) {
			fprintf(stderr, "ERROR: inode marked in use but not found in a directory.\n");
			exit(1);
		}
	}
	return 0;
}

