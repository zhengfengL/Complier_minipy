%{
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "minipy.h"
#define YYSTYPE Frame
extern Frame yylval;
#include "y.tab.h"

%}

letter    [a-zA-Z]

digit     [0-9]

number   {digit}+

real     {number}"."{number}?|{number}?"."{number}

id       {letter}({letter}|{digit})*



%%
[ \t]+      {/*do nothing , just skip */}
{real}      {
              yylval.t = Real;
              yylval.vr = atof(yytext);
              //PrintFrameInfo(yylval);
              return REAL;
            }
{number}    { 
              yylval.t = Int;
              yylval.vi = atoi(yytext);
              //PrintFrameInfo(yylval);
              return INT;
            }

{id}        {
              yylval.t = Id;
              strcpy(yylval.id, yytext);
              strcpy(yylval.func, yytext);
              //PrintFrameInfo(yylval);
              return ID; 
            }
\"(\\.|[^\\"])*\"	{
              yylval.t = String;
              strcpy(yylval.vs, yytext);
              //PrintFrameInfo(yylval);
              return STRING_LITERAL; 
            }
.|\n        { return yytext[0];}
%%