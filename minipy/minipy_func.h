/* A symbol list for those user defined variables */
#define N_VARIABLES 100

Frame Symbolist[N_VARIABLES];   //store user defined variables
int Slptr = 0;                  //symbol list pointer
int Errorflag = 0;              //error flag


/* some neccesarry methods */
//about infomation print
void PrintFrameInfo(Frame f);               //print the infomation of a frame
void PrintList(Listhead* h);                //print a list
void PrintNode(Node* p);                    //print a node
void Printer(Frame f);                      //print the final expression
//about list operating
LN MakeNode(LN p, Frame f);
Frame NodeToFrame(LN p);
Node  FrameToNode(Frame f);
int SearchSymbolist(char* id);

/***********************************************************/

void PrintFrameInfo(Frame f){
    switch (f.t)
    {
        case Int:
            printf("I'm an integer %d!\n", f.vi); break;
        case Real:
            printf("I'm an real number %f!\n", f.vr); break;
        case Id:
            printf("I'm an ID %s!\n", f.id); break;
        case String:
            printf("I'm an string %s!\n", f.vs); break;
        case List: 
            PrintList(f.vl); break;
        default:
            break;
    }
}

void PrintList(Listhead* h){
    if(h != NULL){
        printf("[");
        if (h->length == 0) {printf("]"); return;}
        else {
            LN p = h->first;
            while(p) {
                PrintNode(p);
                printf(", ");
                p = p->next;
            }
        }
        printf("]");
    }
    else {
        printf("wtf, a null list!\n");
    }
}

void PrintNode(LN p) {
    switch (p->t)
    {
        case Int:
            printf("%d", p->vi); break;
        case Real:
            printf("%f", p->vr); break;
        case String:
            printf("%s", p->vs); break;
        case List: 
            PrintList(p->vl); break;
        default:
            break;
    }
}


void Printer(Frame f) {
    if(f.s == None){ return;}
    switch (f.t)
    {
        case Int:
            printf("%d", f.vi); break;
        case Real:
            printf("%f", f.vr); break;
        case Id:{
            printf("The id %s need some value!", f.id); break;
        }
        case String:
            printf("%s", f.vs); break;
        case List: 
            PrintList(f.vl);  
            break;
        default:
            break;
    }
}


/***********************************************************/

LN MakeNode(LN p, Frame f){
    p = (LN)malloc(sizeof(Node));
    p->t = f.t;
    switch (f.t)
    {
        case Int:
            p->vi = f.vi;
            break;
        case Real:
            p->vr = f.vr;
            break;
        case String:
            strcpy(p->vs, f.vs);
            break;
        case List: {
            p->vl = f.vl;
        }
        default:
            break;
    } 
    return p;
}

Frame NodeToFrame(LN p){
    Frame f;
    f.t = p->t;
    switch (f.t)
    {
        case Int:
            f.vi = p->vi;
            break;
        case Real:
            f.vr = p->vr;
            break;
        case String:
            strcpy(f.vs, p->vs);
            break;
        case List: {
            f.vl = p->vl;
        }
        default:
            break;
    } 
    return f;
}

Node FrameToNode(Frame f){
    Node p;
    p.t = f.t;   
    switch (f.t)
    {
        case Int:
            p.vi = f.vi;
            break;
        case Real:
            p.vr = f.vr;
            break;
        case String:
            strcpy(p.vs, f.vs);
            break;
        case List: {
            p.vl = f.vl;
        }
        default:
            break;
    }  
    return p;
}

#define UNDEFINED -1
int SearchSymbolist(char* id){
    int i;
    for(i = 0; i < N_VARIABLES; i++){
        if(strcmp(id, Symbolist[i].id) == 0) {
            return i;
        }
    }
    return UNDEFINED;
}

