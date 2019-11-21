#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#define MLEN 100
#define SLEN 200

/* the data structure used in this lab */

//use general list to implement list and string in python
enum type{
    Int, Real, String, Id, List
};
enum state{
    Normal,  
    //cannot be assigned
    Attribute, Funcarg, Func, 
    //can be assigned
    Undefined, Defined, Slice, Son,
    //Something wrong  or empty reduction happened
    Error, Noid, None
};
typedef struct Listhead Listhead;

typedef struct Node{
    enum type t;
    union 
    {
        int vi;
        double vr;
        char vs[MLEN];
        Listhead* vl;
    };   
    struct Node* pre; 
    struct Node* next;
} Node;
typedef Node* LN;

struct Listhead
{
    int length;
    Node* first;
    Node* last;
};
typedef Listhead* LH; 

//use a atom type to implement integer, float ,string and list
typedef struct Frame
{
    enum type t;
    enum state s;
    int start, end, step;   //for slice and son
    int pos;                //record variable's position in slist
    LN  inner, enner;       //record the node for index assign
    LH  head;
    char id[MLEN];
    char func[MLEN];
    union 
    {
        int vi;
        double vr;
        char vs[SLEN];
        LH vl;
    };
} Frame;