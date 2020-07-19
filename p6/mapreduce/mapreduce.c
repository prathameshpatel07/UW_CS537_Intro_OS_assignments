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
	pthread_mutex_t lock;
	//struct node *tail;
	//Put Lock here   
};
Partitioner part;
int num_part;
struct bucket *hashtable;
void init_array(int num_partitions)
{
	for (int i = 0; i < num_partitions; i++)
	{
		hashtable[i].head = NULL;
		pthread_mutex_init(&hashtable[i].lock, NULL);
	}		 
}


char* get_next(char *key, int bucketnumber)
{
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

void MR_Run(int argc, char *argv[], Mapper map, int num_mappers, Reducer reduce, int num_reducers, Partitioner partition, int num_partitions) {
	hashtable = (struct bucket*) malloc(num_partitions * sizeof(struct bucket));
 	init_array(num_partitions);
	part = partition;
	num_part = num_partitions;
	int filecnt = 1;
	pthread_t p;
/*	pthread_t p = malloc(argc-1 * sizeof(pthreat_t));
	while(filecnt<argc) {
		map(argv[filecnt]);
		Pthread_create(&p[filecnt-1], NULL, map, &argv[filecnt]);
		filecnt++;
	}
	for(int mapidx = 0; mapidx < num_mappers; mapidx++) {
		Pthread_join(p[mapidx], NULL);
	}*/
	pthread_create(&p, NULL, map, &argv[1]);
	pthread_join(p, NULL);
       	while(hashtable[0].head)
	{
		reduce(hashtable[0].head->key,get_next,0);
	}	
}

//All External Function implementations
unsigned long MR_SortedPartition(char *key, int num_partitions) 
{
    int myByte = atoi(key); // 11000010
    int shift = 32 - log2n(num_partitions);
    long pno = 0;
    pno = myByte && 0xffff;
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
	
	pthread_mutex_lock(&hashtable[pnum].lock);
	Node* prev = NULL;
	Node* curr = hashtable[pnum].head;

	while(curr && strcmp(key,curr->key)>=0)
	{
	 prev = curr;
	 curr = curr->next;
	}

	if(prev){
		prev->next = newnode;
	}
	else {
		hashtable[pnum].head = newnode;
	}

	newnode->next = curr;
	pthread_mutex_unlock(&hashtable[pnum].lock);
	
}

void MR_Emit(char *key, char *value) {

	//int bucketnumber = 0;
	int bucketnumber = (int)(part)(key,num_part);
	insert(key,value,bucketnumber);
	
}
