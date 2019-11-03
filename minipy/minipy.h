#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#define MLEN 100


/* the data structure used in this lab */

//use general list to implement list and string in python
enum type{
    Int, Real, String, Id, 
};
typedef struct Listhead Listhead;

typedef struct Node{
    enum type t;
    union 
    {
        int vi;
        double vr;
        char* vs;
        Listhead* vl;
    };   
    struct Node* next;
} Node;

struct Listhead
{
    int length;
    Node* first;
};


//use a atom item to implement integer, float and char
typedef struct Frame
{
    enum type t;
    char id[100];
    union 
    {
        int vi;
        double vr;
        char* vs;
        Listhead* vl;
    };
} Frame;

/* A symbol list for those user defined variables */
#define N_VARIABLES 100

Frame Symbolist[N_VARIABLES];   //store user defined variables
int Slptr;                      //symbol list pointer



/* some neccesarry methods */