%{
#include <stdio.h>
#include <ctype.h>
#include "minipy.h"
#define YYSTYPE Frame

%}
%token INT REAL LIST ID STRING_LITERAL FUNC

%%
Start : prompt Lines
      ;
Lines : Lines  stat '\n' prompt
      | Lines  '\n' prompt
      | 
      | error '\n' {yyerrok;}
      ;
prompt : { printf("miniPy> ");}
       ;
stat  : assignExpr
      ;
assignExpr:
        atom_expr '=' assignExpr
      | add_expr 
      ;
factor : '+' factor
       | '-' factor
       | atom_expr
       ; 
atom  : ID              
      | STRING_LITERAL  
      | List            
      | INT             
      | REAL
      ;
slice_op :  /*  empty production */
        | ':' add_expr 
        ;
sub_expr:  /*  empty production */
        | add_expr
        ;        
atom_expr : atom 
        | atom_expr  '[' sub_expr  ':' sub_expr  slice_op ']'
        | atom_expr  '[' add_expr ']'
        | atom_expr  '.' ID
        | atom_expr  '(' arglist opt_comma ')'
        | atom_expr  '('  ')'
        ;
arglist : add_expr
        | arglist ',' add_expr 
        ;
        ;      
List  : '[' ']'
      | '[' List_items opt_comma ']' 
      ;
opt_comma : /*  empty production */
          | ','
          ;
List_items  
      : add_expr
      | List_items ',' add_expr 
      ;
add_expr : add_expr '+' mul_expr
	      |  add_expr '-' mul_expr
	      |  mul_expr 
        ;
mul_expr : mul_expr '*' factor
        |  mul_expr '/' factor
	|  mul_expr '%' factor
        |  factor
        ;

%%

int main()
{
   return yyparse();
}

void yyerror(char *s)
{
   printf("%s\nrequiescat in pace\nminiPy> ", s);
}

int yywrap()
{ return 1; }  