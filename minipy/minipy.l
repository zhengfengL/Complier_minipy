%{
#include <stdlib.h>
#include <stdio.h>
#include "minipy.h"
#define YYSTYPE Frame
extern Frame yylval;
#include "y.tab.h"

%}

letter    [a-zA-Z]

digit     [0-9]

number   {digit}+

id       {letter}({letter}|{digit})*

real     {number}'.'{number}?|{number}?'.'{number}

%%
[ \t]+      {/*do nothing , just skip */}
{number}    { 
              printf("Get an integer\n");
              //yylval.t= INT;
              //yylval.vi = atoi(yytext[0]);
              //printf("I'm an integer %d !", yylval.vi);
              return INT;
            }
{real}      {
              return REAL;
            }
{id}        {
              return ID; 
            }
\"(\\.|[^\\"])*\"	{
             return STRING_LITERAL; 
                  }
.|\n        { /*0return yylval = yytext[0];*/}
%%