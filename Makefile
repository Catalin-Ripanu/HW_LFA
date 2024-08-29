build:
	lex Tema.l
	gcc lex.yy.c -o Tema

clean:
	rm -rf Tema lex.yy.c
