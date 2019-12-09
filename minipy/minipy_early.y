%{
#include <stdio.h>
#include <ctype.h>
#include "minipy.h"
#define YYSTYPE Frame
#include "minipy_func.h"

%}
%token INT REAL LIST ID STRING_LITERAL FUNC

%%
Start : prompt Lines
      ;
//fin
Lines : Lines  stat '\n' prompt {
                if (Errorflag == 0){
                        Printer($2);
                        if($2.s != None) { printf("\n");}
                }         
                Errorflag = 0;
                printf("miniPy> ");
        }
      | Lines  '\n' prompt {
              Errorflag = 0;
              printf("minipy> ");
      }
      | 
      | error '\n' {yyerrok;}
      ;
//fin
prompt : { }
       ;
//fin
stat  : assignExpr 
      ;
//fin
assignExpr:
        atom_expr '=' assignExpr {
                //assignment
                if ($1.s == Undefined) {
                        $$ = $3;
                        strcpy($$.id, $1.id);
                        //create a new item in slist
                        Symbolist[Slptr] = $$;
                        Symbolist[Slptr].pos = Slptr;
                        Slptr = (Slptr+1)%N_VARIABLES;
                        //printf("a new variable %s with type %d assigned!", $$.id, $$.t);
                }
                else if ($1.s == Defined) {
                        $$ = $3; $$.pos = $1.pos;
                        strcpy($$.id, $1.id);
                        //cover the old item in slist
                        Symbolist[$1.pos] = $$; 
                }
                else if ($1.s == Slice) {
                        if ($3.t != List) {
                                yyerror("can only assign an iterable!");
                        }
                        else if ($1.vl->length == 0) {
                                yyerror("can only assign to a nonempty list!");
                        }
                        else {
                                //pass type check
                                $$ = $1;
                                if ($$.step == 1){
                                        //delete and insert
                                        //delete a hammer
                                        //printf("original length: %d address: %d\n", $$.head->length, $$.head);
                                        $$.head->length = $$.head->length-$1.vl->length+$3.vl->length;
                                        //printf("length: %d length1: %d length2: %d\n", $$.head->length, $1.vl->length ,$3.vl->length);
                                        LH h = (LH)malloc(sizeof(Listhead));
                                        LN p, q = $3.vl->first, temp;
                                        //copy the right value
                                        while (q != NULL) {
                                                p = (LN)malloc(sizeof(Node));
                                                *p = *q; p->next = NULL;
                                                if (h->length == 0) {
                                                        h->first = p;
                                                        h->last = p;
                                                        temp = p;
                                                }
                                                else {
                                                        h->last->next = p;
                                                        h->last = p;
                                                        p->pre = temp;
                                                        temp = p;
                                                }
                                                h->length ++;
                                                q = q->next;
                                        }
                                        //replace the left value
                                        if (h->length == 0) {
                                                $$.head->first = $$.enner->next;
                                                LN p = $$.inner;
                                                int flag = 0;
                                                while(p->pre != NULL){
                                                        p = p->pre;
                                                        flag = 1;
                                                }
                                                if (flag == 1){
                                                        $$.inner->pre->next = $$.enner->next;
                                                        $$.enner->next->pre = $$.inner->pre;
                                                        $$.head->first = p;
                                                }   
                                                else {
                                                        $$.enner->next->pre = NULL;
                                                }                                            
                                        }
                                        else {
                                                $$.head->first = h->first;
                                                $$.enner->pre = h->last;
                                                h->last->next = $$.enner->next;
                                                LN p = $$.inner;
                                                int flag = 0;
                                                while(p->pre != NULL){
                                                        p = p->pre;
                                                        flag = 1;
                                                }
                                                if (flag == 1){
                                                        $$.inner->pre->next = h->first;
                                                        $$.head->first = p;
                                                }
                                        }
                                }
                                else {
                                        if ($$.vl->length != $3.vl->length) {
                                                yyerror("attempt to assign sequence to extend slice without matched size!");
                                        }
                                        else {
                                                if ($$.step > 0) {
                                                        //directly assign
                                                        int step = $$.step, cnt = 0, i;
                                                        LN p = $$.inner, q = $3.vl->first;
                                                        while(cnt < $$.vl->length){
                                                                LN next = p->next, pre = p->pre;
                                                                *p = *q; p->next = next; p->pre = pre;
                                                                q = q->next;
                                                                for(i = 0; i < step; i++) p = p->next;
                                                                cnt++;  
                                                        }
                                                }
                                                else if ($$.step < 0) {
                                                        //directly assign
                                                        int step = -$$.step, cnt = 0, i;
                                                        LN p = $$.enner, q = $3.vl->first;
                                                        while(cnt < $$.vl->length){
                                                                LN next = p->next, pre = p->pre;
                                                                *p = *q; p->next = next; p->pre = pre;
                                                                q = q->next;
                                                                for(i = 0; i < step; i++) p = p->pre;
                                                                cnt++;
                                                        }
                                                }
                                        }
                                }
                        }
                }
                else if ($1.s == Son) {
                        $$ = $3; $$.pos = $1.pos;
                        $$.inner = $1.inner;
                        LN p = $1.inner->next;
                        *($$.inner) = FrameToNode($3);
                        $$.inner->next = p;
                }
                else {
                        yyerror("This object cannot be assigned!");
                }
                $$.s = None;
        }
      | add_expr 
      ;
//fin
slice_op :  {$$.t = Int; $$.s = Noid; $$.vi = 1;}/*  empty production */
        | ':' add_expr { $$ = $2;}
        ;     
//fin
arglist : add_expr {
                // reduction start
                $$.t = List;
                $$.vl = (LH)malloc(sizeof(Listhead));
                $$.vl->length = 1;
                LN p;
                $$.vl->first = MakeNode(p, $1); 
                $$.vl->last = $$.vl->first;
        }
        | arglist ',' add_expr {
                // allocate some space for nodes.tail insertion
                $$.t = List;
                $$.vl = (LH)malloc(sizeof(Listhead));
                $$.vl->length = $1.vl->length+1;
                LN p;
                //insert new node
                $$.vl->first = $1.vl->first;
                $$.vl->last = $1.vl->last;
                $$.vl->last->next = MakeNode(p, $3);
                $$.vl->last->next->pre = $$.vl->last;
                $$.vl->last = $$.vl->last->next;
        }
        ;   
//fin  
List  : '[' ']' {
        // empty List(fin)
                $$.t = List;
                //allocate some space to construct an empty List
                $$.vl = (LH)malloc(sizeof(Listhead));
                $$.vl->length = 0;
                $$.vl->first = NULL;
                $$.vl->last = NULL;
                //Printer($$);
        }
      | '[' List_items opt_comma ']'{
        // non-empty List(fin)
                $$.t = List;
                $$.vl = (LH)malloc(sizeof(Listhead));
                $$.vl->length = $2.vl->length;
                $$.vl->first = $2.vl->first;
                $$.vl->last = $2.vl->last;
                //Printer($$);
      } 
      ;
//fin
opt_comma : /*  empty production */
          | ','
          ;
//fin
List_items  
      : add_expr {
        // reduction start
                $$.t = List;
                $$.vl = (LH)malloc(sizeof(Listhead));
                $$.vl->length = 1;
                LN p;
                $$.vl->first = MakeNode(p, $1); 
                $$.vl->last = $$.vl->first;
      }
      | List_items ',' add_expr {
        // allocate some space for nodes.tail insertion
                $$.t = List;
                $$.vl = (LH)malloc(sizeof(Listhead));
                $$.vl->length = $1.vl->length+1;
                LN p;
                //insert new node
                $$.vl->first = $1.vl->first;
                $$.vl->last = $1.vl->last;
                $$.vl->last->next = MakeNode(p, $3);
                $$.vl->last->next->pre = $$.vl->last;
                $$.vl->last = $$.vl->last->next;
      }
      ;
//fin
sub_expr: {$$.t = Int; $$.s = Noid; $$.vi = 0;} /*  empty production */
        | add_expr
        ;  
//fin
add_expr : add_expr '+' mul_expr { 
                if (($1.t == Int || $1.t == Real) && ($3.t == Int || $3.t == Real)){
                        if ($1.t == Int && $3.t == Int){ $$.vi = $1.vi+$3.vi;}
                        else if ($1.t == Int && $3.t == Real){ $$.t = Real; $$.vr = $1.vi+$3.vr;}
                        else if ($1.t == Real && $3.t == Int){ $$.t = Real; $$.vr = $1.vr+$3.vi;}
                        else { $$.vr = $1.vr+$3.vr;}

                        //Printer($$);
                }
                else if ($1.t == String && $3.t == String) {
                        char* s = $3.vs+1;
                        strcpy($$.vs, $1.vs);
                        $$.vs[strlen($$.vs)-1] ='\0';
                        strcat($$.vs, s);
                }
                else if ($1.t == List && $3.t == List) {
                        // contruct a new list
                        $$.vl = (LH)malloc(sizeof(Listhead));
                        $$.vl->length = $1.vl->length+$3.vl->length;
                        //printf("length %d\n", $$.vl->length);
                        if($$.vl->length != 0){
                                LN p, q, temp;
                                int flag = 0;
                                q = $1.vl->first;
                                while(q != NULL){
                                        p = (LN)malloc(sizeof(Node));
                                        *p = *q; p->next = NULL; p->pre = NULL;
                                        if(flag == 0){
                                                $$.vl->first = p;
                                                $$.vl->last = p;
                                                flag = 1;
                                        }
                                        else {
                                                temp->next = p;
                                                $$.vl->last = p;
                                                p->pre = temp;
                                        }
                                        temp = p;
                                        q = q->next;
                                }
                                q = $3.vl->first;
                                while(q != NULL){
                                        p = (LN)malloc(sizeof(Node));
                                        *p = *q; p->next = NULL; p->pre = NULL;
                                        if(flag == 0){
                                                $$.vl->first = p;
                                                $$.vl->last = p;
                                                flag = 1;
                                        }
                                        else {
                                                temp->next = p;
                                                $$.vl->last = p;
                                                p->pre = temp;
                                        }
                                        temp = p;
                                        q = q->next;
                                }
                        }
                }
                else {
                        yyerror("add type mistake!"); $$.s = Error;
                }
        }
	 | add_expr '-' mul_expr{ 
                if (($1.t == Int || $1.t == Real) && ($3.t == Int || $3.t == Real)){
                        if ($1.t == Int && $3.t == Int){ $$.vi = $1.vi-$3.vi;}
                        else if ($1.t == Int && $3.t == Real){ $$.t = Real; $$.vr = $1.vi-$3.vr;}
                        else if ($1.t == Real && $3.t == Int){ $$.t = Real; $$.vr = $1.vr-$3.vi;}
                        else { $$.vr = $1.vr-$3.vr;}

                        //Printer($$);
                }
                else {
                        yyerror("sub type mistake!"); $$.s = Error;
                }
        }
	 | mul_expr 
        ;
//u
mul_expr : mul_expr '*' factor{ 
                if (($1.t == Int || $1.t == Real) && ($3.t == Int || $3.t == Real)){
                        if ($1.t == Int && $3.t == Int){ $$.vi = $1.vi*$3.vi;}
                        else if ($1.t == Int && $3.t == Real){ $$.t = Real; $$.vr = $1.vi*$3.vr;}
                        else if ($1.t == Real && $3.t == Int){ $$.t = Real; $$.vr = $1.vr*$3.vi;}
                        else { $$.vr = $1.vr*$3.vr;}

                        //Printer($$);
                }
                else if($1.t == List && $3.t == Int) {
                        $$.t = List;
                        int cnt = $3.vi;
                        $$.vl = (LH)malloc(sizeof(Listhead));
                        if(cnt > 0 && $1.vl->length != 0){
                                $$.vl->length = $1.vl->length*$3.vi;
                                LN p, q, temp;
                                int flag = 0;
                                while(cnt > 0){
                                        q = $1.vl->first;
                                        while(q != NULL){
                                                p = (LN)malloc(sizeof(Node));
                                                *p = *q; p->next = NULL; p->pre = NULL;
                                                if (flag == 0){
                                                        $$.vl->first = p;
                                                        $$.vl->last = p;
                                                        flag = 1;
                                                }
                                                else {
                                                        temp->next = p;
                                                        $$.vl->last = p;
                                                        p->pre = temp;
                                                }
                                                temp = p;
                                                q = q->next;
                                        }
                                        cnt--;
                                }
                        }
                }
                else if($3.t == List && $1.t == Int) {
                        $$.t = List;
                        int cnt = $1.vi;
                        $$.vl = (LH)malloc(sizeof(Listhead));
                        if(cnt > 0 && $3.vl->length != 0){
                                $$.vl->length = $3.vl->length*$1.vi;
                                LN p, q, temp;
                                int flag = 0;
                                while(cnt > 0){
                                        q = $3.vl->first;
                                        while(q != NULL){
                                                p = (LN)malloc(sizeof(Node));
                                                *p = *q; p->next = NULL; p->pre = NULL;
                                                if (flag == 0){
                                                        $$.vl->first = p;
                                                        $$.vl->last = p;
                                                        flag = 1;
                                                }
                                                else {
                                                        temp->next = p;
                                                        $$.vl->last = p;
                                                        p->pre = temp;
                                                }
                                                temp = p;
                                                q = q->next;
                                        }
                                        cnt--;
                                }
                        }
                }
                else if($1.t == String && $3.t == Int) {
                        $$.t = String;
                        int cnt = $3.vi-1;
                        if(cnt <= 0){
                                $$.vs[0] = '/0';
                        }
                        else {
                                strcpy($$.vs, $1.vs);
                                char* s = $1.vs+1;
                                $$.vs[strlen($$.vs)-1] ='\0';
                                while(cnt > 0){
                                        strcat($$.vs, s);
                                        if (cnt > 1){
                                              $$.vs[strlen($$.vs)-1] ='\0';  
                                        }
                                        cnt--;
                                }
                        }
                }
                else if($3.t == String && $1.t == Int) {
                        $$.t = String;
                        int cnt = $1.vi-1;
                        if(cnt <= 0){
                                $$.vs[0] = '/0';
                        }
                        else {
                                strcpy($$.vs, $3.vs);
                                char* s = $3.vs+1;
                                $$.vs[strlen($$.vs)-1] ='\0';
                                while(cnt > 0){
                                        strcat($$.vs, s);
                                        if (cnt > 1){
                                              $$.vs[strlen($$.vs)-1] ='\0';  
                                        }
                                        cnt--;
                                }
                        }
                }
                else {
                        yyerror("mul type mistake!"); $$.s = Error;
                }
        }
        |  mul_expr '/' factor{ 
                if (($1.t == Int || $1.t == Real) && ($3.t == Int || $3.t == Real)){
                        if ($1.t == Int && $3.t == Int){ $$.t = Real; $$.vr = ((float)$1.vi)/$3.vi;}
                        else if ($1.t == Int && $3.t == Real){ $$.t = Real; $$.vr = $1.vi/$3.vr;}
                        else if ($1.t == Real && $3.t == Int){ $$.t = Real; $$.vr = $1.vr/$3.vi;}
                        else { $$.vr = $1.vr/$3.vr;}

                        //Printer($$);
                }
                else {
                        yyerror("div type mistake!"); $$.s = Error;
                }
        }
	|  mul_expr '%' factor{ 
                if ($1.t == Int  && $3.t == Int ){
                        $$.vi = $1.vi%$3.vi;

                        //Printer($$);
                }
                else {
                        yyerror("mod type mistake!"); $$.s = Error;
                }
        }
        |  factor
        ;
//fin
factor : '+' factor 
       | '-' factor {
               if($2.t == Int) { $$.t = Int; $$.vi = -$2.vi; }
               else if($2.t == Real) { $$.t = Real; $$.vr = -$2.vr; }
               else {yyerror("factor type error!"); $$.s = Error;}
               //Printer($$);
       }
       | atom_expr
       ; 
//u
atom_expr : atom 
        | atom_expr  '[' sub_expr  ':' sub_expr  slice_op ']' {
                //a slice (cannot be a left value)
                if ($1.t != List){
                        yyerror("Are you f**king kidding me?"); $$.s = Error;
                }
                else if ($3.t != Int || $5.t != Int || $6.t != Int) {
                        yyerror("slice index is not a Int!"); $$.s = Error;
                }
                else {
                        // pass type check
                        int start, end, step, flag = 0;
                        start = $3.vi; end = $5.vi; step = $6.vi;
                        $$.step = step;
                        $$.s = Slice;
                        $$.t = List;
                        $$.vl = (LH)malloc(sizeof(Listhead));
                        /* compute and regularization slice start, end */
                        if ($3.s == Noid && $5.s == Noid) { 
                                if (step < 0){
                                        start = $1.vl->length; $$.start = start;
                                        end = -1; $$.end = end; 
                                        flag = 1;
                                }
                                else if (step > 0){
                                        end = $1.vl->length; $$.end = end;
                                }
                        }
                        else if ($5.s == Noid){
                                if (step < 0) {
                                        end = -1; $$.end = end; 
                                        flag = 1; 
                                }
                        }
                        //start
                        if (start < 0) {
                                start = $1.vl->length+start;
                                if (start > $1.vl->length) start = $1.vl->length;
                                if (start < 0) start = 0;
                        }
                        if (end < 0 && flag == 0) {
                                end = $1.vl->length+end;
                                if (end > $1.vl->length) end = $1.vl->length;
                                if (end < 0) end = 0;
                        }
                        /* construct the slice */
                        if (start < end && step > 0) {
                                int i, cnt = start;
                                LN p = $1.vl->first;
                                LN temp;
                                for(i = 0; i < start; i++) {
                                        p = p->next;
                                }
                                $$.inner = p;
                                while(cnt < end && p != NULL) {
                                        //tail insertion 
                                        LN q = (LN)malloc(sizeof(Node));
                                        *q = *p; q->next = NULL;
                                        if($$.vl->length == 0) {
                                                $$.vl->first = q;
                                                $$.vl->last = q;
                                                temp = q;
                                        }
                                        else {
                                                temp->next = q;
                                                $$.vl->last = q;
                                                q->pre = temp;
                                                temp = q;
                                        }
                                        $$.enner = p;
                                        $$.vl->length += 1;
                                        //new p, cnt
                                        for (i = 0; i < step && p != NULL; i++) {
                                                p = p->next;
                                        }
                                        cnt += step;
                                        //printf("cnt %d step %d lenth %d start %d end %d\n", cnt, step, $$.vl->length, start, end);
                                }
                        }
                        else if (start > end && step < 0) {
                                step = -step;
                                int n = (start-end-1)/step;
                                end = start+1;
                                start = start-n*step;
                                //head insertion
                                int i, cnt = start;
                                LN p = $1.vl->first;
                                for(i = 0; i < start; i++) {
                                        p = p->next;
                                }
                                $$.inner = p;
                                while(cnt < end && p != NULL) {
                                        //tail insertion 
                                        LN q = (LN)malloc(sizeof(Node));
                                        *q = *p; q->next = NULL;
                                        if($$.vl->length == 0) {
                                                $$.vl->first = q;
                                                $$.vl->last = q;
                                        }
                                        else {
                                                q->next = $$.vl->first;
                                                q->next->pre = q;
                                                $$.vl->first = q;                    
                                        }
                                        $$.enner = p;
                                        $$.vl->length += 1;
                                        //new p, cnt
                                        for (i = 0; i < step && p != NULL; i++) {
                                                p = p->next;
                                        }
                                        cnt += step;
                                        //printf("cnt %d step %d lenth %d start %d end %d\n", cnt, step, $$.vl->length, start, end);
                                }
                        }
                        $$.start = start; $$.end = end; 
                }

        }
        | atom_expr  '[' add_expr ']' {
                //a son (some big problem)
                if ($1.t != List) {
                        yyerror("Are you f**king kidding me?"); $$.s = Error;
                }
                else if ($3.t != Int) {
                        yyerror("List index is not Int!"); $$.s = Error;
                }
                else {
                        //pass type check
                        if ($3.vi < 0) { $3.vi += $1.vl->length; }
                        if ($3.vi < 0 || $3.vi >= $1.vl->length) {
                               yyerror("List index out of range!"); $$.s = Error; 
                        }
                        else {
                                //pass semantic check
                                LN p = (LN)malloc(sizeof(Node));
                                p = $1.vl->first;
                                int i;
                                for(i = 0; i < $3.vi; i++) {
                                        p = p->next;
                                }
                                $$ = NodeToFrame(p);
                                $$.s = Son;
                                $$.head = p->vl;
                                $$.inner = p;
                                //Printer(NodeToFrame($$.inner));
                        }
                }
        }
        | atom_expr  '.' ID {
                //attribute function
                strcpy($$.func, $3.id);
        }
        | atom_expr  '(' arglist opt_comma ')' {
                //function with arguments (cannot be a left value)
                if (strcmp($1.func, "append") == 0){
                        if($1.t != List){
                                yyerror("append is a function for something iterable!");
                        }
                        else if($3.vl->length != 1){
                                yyerror("arg number for append must be 1!");
                        }
                        else {
                                LN p = (LN)malloc(sizeof(Node));
                                LN q = $3.vl->first;
                                *p = *q; p->next = NULL;
                                $1.vl->last->next = p;
                                p->pre = $1.vl->last;
                                $1.vl->last = p;
                                $1.vl->length++;
                        }
                        Errorflag = 1;
                }
                //func range
                else if (strcmp($1.func, "range") == 0){
                        if(($3.vl->length != 2) && ($3.vl->length != 3)){
                                //Printer($3); printf(" len %d\n", $3.vl->length);
                                yyerror("arg number for range must be 2 or 3!");
                        }
                        else {
                                int start, end, step;
                                LN arg1 = $3.vl->first;
                                LN arg2 = arg1->next;
                                LN arg3 = arg2->next;
                                if(arg3 == NULL && (arg1->t != Int || arg2->t != Int)){
                                        yyerror("arg type for range must be Int!");
                                }
                                else if (arg3 != NULL && (arg1->t != Int || arg2->t != Int || arg3->t != Int)){
                                        yyerror("arg type for range must be Int!");
                                }
                                else {
                                        //construct range list
                                        start = arg1->vi;
                                        end = arg2->vi;
                                        if (arg3 == NULL){step = 1;}
                                        else {step = arg3->vi;}

                                        //printf("start %d, end %d, step %d\n", start, end , step);

                                        $$.t = List;
                                        $$.vl = (LH)malloc(sizeof(Listhead));
                                        $$.vl->length = 0;
                                        int cnt = start;
                                        LN p, temp;
                                        while((step > 0 && cnt < end)||(step < 0 && cnt > end)){
                                                p = (LN)malloc(sizeof(Node));
                                                p->t = Int;
                                                p->vi = cnt;
                                                if($$.vl->length == 0){
                                                        $$.vl->first = p;
                                                        $$.vl->last = p;
                                                }
                                                else {
                                                        $$.vl->last->next = p;
                                                        $$.vl->last = p;
                                                        p->pre = temp;
                                                        p->next = NULL;
                                                }
                                                temp = p;
                                                cnt += step;
                                                $$.vl->length++;
                                        }

                                }
                        }
                }
                //func len
                else if (strcmp($1.func, "len") == 0){
                        if($3.vl->length != 1){
                                yyerror("arg number for len must be 1!");
                        }
                        else if($3.vl->first->t != List){
                                yyerror("arg type for len must be iterable!");
                        }
                        else {
                                $$.t = Int;
                                $$.vi = $3.vl->first->vl->length;
                        }
                }
                //func print
                else if (strcmp($1.func, "print") == 0){
                        if($3.vl->length == 1){
                                Printer(NodeToFrame($3.vl->first));
                                printf("\n");
                        }
                        else {
                                printf("(");
                                if($3.vl->length == 0){ return;}
                                else {
                                        LN p = $3.vl->first;
                                        while(p != NULL) {
                                                Printer(NodeToFrame(p));
                                                printf(", ");
                                                p = p->next;
                                        }
                                }
                                printf("\b\b)\n");
                        }
                        Errorflag = 1;
                        
                }
        }
        | atom_expr  '('  ')' {
                //function without arguments  (cannot be a left value) 
                //quit function
                if (strcmp($1.id, "quit") == 0) {
                        return (0);
                }          
        }
        ;
//fin
atom  : ID {
                //try to find this id in the symbol list, if not exist, set its state as waiting(for assertion)  
                int index = SearchSymbolist($1.id);
                if (index == UNDEFINED) {
                        //printf("cannot find value of id %s!\n", $1.id);
                        $$.s = Undefined;
                } 
                else {
                        $$ = Symbolist[index];
                        $$.s = Defined;
                        $$.pos = index;
                        if ($$.t == List) {
                                //record the address of the first node by $$.inner
                                $$.head = $$.vl;
                                $$.inner = $$.vl->first;
                        }
                        //printf("find value of id %s!, type %d\n", $1.id, $$.t);
                }
        }            
      | STRING_LITERAL  
      | List            
      | INT            
      | REAL  
      ;
%%

int main()
{
        printf("minipy> ");
        return yyparse();
}

void yyerror(char *s)
{
        printf("%s\nrequiescat in pace\n", s);
        Errorflag = 1;
}

int yywrap()
{ return 1; }  