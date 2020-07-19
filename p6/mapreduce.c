#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "sys/stat.h"
#include "pthread.h"
#include <semaphore.h>
#include "mapreduce.h"
#include <math.h>
typedef struct node 
{
	char *key;
	char *value;
	struct node *next;
}Node;
 
struct bucket {
	struct node *head;
	int size;
	pthread_mutex_t lock;
	//struct node *tail;
	//Put Lock here   
};
struct args {
    Mapper m;
    char **filearr;
};

struct args_r {
    Reducer r;
};
Partitioner part;
pthread_mutex_t lock;
int num_part;
int part_num = 0;
int totalfiles;
int files=0;
struct bucket *hashtable;
void init_array(int num_partitions)
{
	for (int i = 0; i < num_partitions; i++)
	{
		hashtable[i].head = NULL;
		pthread_mutex_init(&hashtable[i].lock, NULL);
		hashtable[i].size = 0;
	}		 
}


char* get_next(char *key, int bucketnumber)
{
	//dprintf(1,"bno: %d key:%s\n",bucketnumber,key);
	if(hashtable[bucketnumber].head && strcmp(hashtable[bucketnumber].head->key,key)==0){
	 char* to_be_returned =  hashtable[bucketnumber].head->value;
	 hashtable[bucketnumber].head =  hashtable[bucketnumber].head->next;
	 return to_be_returned;
	}
	else return NULL;
}

unsigned int log2n(int n)
{
	return (n>1) ? 1+log2n(n/2) : 0;
}

void mapWrapper(void *arguements)
{
	struct args *args = arguements;
//	dprintf(1,"\tmapWrapper");
	while(files<totalfiles)
	{
	 pthread_mutex_lock(&lock); 
	 files++;
	 int index = files;
	 pthread_mutex_unlock(&lock);
	// dprintf(1,"Index:%d",index);
	// dprintf(1,"filearr:%s",args->filearr[index]); 
	 args->m(args->filearr[index]);
	}
}

void redWrapper(void *arguements)
{
	 //dprintf(1,"\tredWrapper");
	 struct args_r *args = arguements;
	while(part_num<num_part)
	{
	 pthread_mutex_lock(&lock); 
	 int index = part_num;
	 part_num++;
	 pthread_mutex_unlock(&lock);
//	 dprintf(1,"\tStarting while with index:%d and total part:%d",index, num_part);
	 while(index<num_part && hashtable[index].head)
         {
//	    dprintf(1,"\tIn while with index:%d",index);
            args->r(hashtable[index].head->key,get_next,index);

//              if(hashtable[partcnt].head)
//              dprintf(1,"\tkey at head: %s",hashtable[partcnt].head->key);
                
//              dprintf(1,"\tinner loop");
         }
 	 // dprintf(1,"Index:%d",index);
	// dprintf(1,"filearr:%s",args->filearr[index]); 
	 
	}
}

int cmpfunc (const void * a, const void * b) {
	   return ( strcmp(*(char* const*)a, *(char* const*)b) );
}

void MR_Run(int argc, char *argv[], Mapper map, int num_mappers, Reducer reduce, int num_reducers, Partitioner partition, int num_partitions) {
	//dprintf(1,"HI");
	//dprintf(1,"\tmappers:%d, reducers:%d, partitions:%d, files:%d",num_mappers,num_reducers,num_partitions,argc-1);
	hashtable = (struct bucket*) malloc(num_partitions * sizeof(struct bucket));
 	init_array(num_partitions);
	part = partition;
	num_part = num_partitions;
	int filecnt = 1;
	int map_num = 0;
	totalfiles = argc-1;
	struct args arg;
    	arg.m = map;
    	arg.filearr = argv;
	pthread_t *p = (pthread_t*)malloc(num_mappers * sizeof(pthread_t));
	while(map_num<num_mappers) {
		pthread_create(&p[map_num], NULL, mapWrapper,(void *)&arg);
	 	map_num++;
	}

	for(int mapidx = 0; mapidx < num_mappers; mapidx++) {
		pthread_join(p[mapidx], NULL);
	}
       

	//Link to Array to Link for sorting
	char *arr[1000010];
	int i=0;
        for(i=0;i<num_part;i++)
        {
	 if(!hashtable[i].head)continue;	
         int sz = hashtable[i].size - 1;
//	 char **arr = (char**) malloc(1000010*sizeof(char));
	 int index=0;
 	 Node* curr = hashtable[i].head;
	 while(curr!=NULL){
	 arr[index]= curr->key;
	 index++;
	 curr = curr->next;
	 }

	 char* val=hashtable[i].head->value;
	 hashtable[i].head = NULL;
	 //qsort
	 qsort(arr,sz+1,sizeof(char*),cmpfunc); 
	 while(sz>=0)
	 {
	   Node* newnode = (Node*) malloc(sizeof(Node));
	   char* newkey = (char*) malloc(sizeof(char));
           strcpy(newkey,arr[sz]);
	   newnode->key = newkey;
           newnode->value = val;
	   Node* curr = hashtable[i].head;
           newnode->next = curr;
           hashtable[i].head = newnode;
	   sz--;
	 }
      }

	int partcnt = 0;
	int red_num = 0;
	struct args_r arggg;
        arggg.r = reduce;
	pthread_t *pr = (pthread_t*)malloc(num_reducers * sizeof(pthread_t));
        while(red_num<num_reducers)
	{
//		dprintf(1,"Calling red number:> %d",red_num);
		pthread_create(&pr[red_num], NULL, redWrapper, (void *)&arggg);
		red_num ++;
	}

	for(int redidx = 0; redidx < num_reducers; redidx++) {
                pthread_join(pr[redidx], NULL);
        }

}

//All External Function implementations
unsigned long MR_SortedPartition(char *key, int num_partitions) 
{
   // unsigned int myByte = atoi(key); // 11000010
    long myByte = atol(key); 
    int shift = 32 - log2n(num_partitions);
    long pno = 0;
//    dprintf(1,"part:%d for key:%ld",myByte>>shift,myByte);
    pno = myByte;
 //   dprintf(1,"\nKey=%s Val before shift: %ld after shift=%ld ...",key,pno,pno >> shift);
  return (pno >> shift);
}

unsigned long MR_DefaultHashPartition(char *key, int num_partitions) {
    unsigned long hash = 5381;
    int c;
    while ((c = *key++) != '\0')
           hash = hash * 33 + c;
    return hash % num_partitions;
}
void insert(char *key, char *val, int pnum)
{
	Node* newnode = (Node*) malloc(sizeof(Node));
	char* newkey = (char*) malloc(sizeof(char));
	strcpy(newkey,key);
	newnode->key = newkey;
	newnode->value = val;
	
	//Insert here
	pthread_mutex_lock(&hashtable[pnum].lock);
	Node* curr = hashtable[pnum].head;
	newnode->next = curr;
	hashtable[pnum].head = newnode;
	hashtable[pnum].size++;
	pthread_mutex_unlock(&hashtable[pnum].lock);
}

void MR_Emit(char *key, char *value) {

	//int bucketnumber = 0;
	int bucketnumber = (int)(part)(key,num_part);
	insert(key,value,bucketnumber);
	
}
