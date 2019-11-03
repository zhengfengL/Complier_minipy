LEX = flex 
LEXFILE = minipy.l 
YACC = yacc  
YACCFILE = minipy.y
CC = gcc
OBJECT = minipy #生成的目标文件  

$(OBJECT): lex.yy.o  y.tab.o  
	$(CC) lex.yy.o y.tab.o -o $(OBJECT) -w  
	@./$(OBJECT) #编译后立刻运行  

lex.yy.o: lex.yy.c  y.tab.h
	$(CC) -c lex.yy.c  

y.tab.o: y.tab.c
	$(CC) -c y.tab.c  

y.tab.c  y.tab.h: $(YACCFILE)
# bison使用-d参数编译.y文件  
	$(YACC) -d $(YACCFILE)

lex.yy.c: $(LEXFILE) 
	$(LEX) $(LEXFILE)

clean:  
	@rm -f $(OBJECT)  *.o *.c y.tab.h