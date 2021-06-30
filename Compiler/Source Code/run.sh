flex lexAnalyser.l
bison -d grammar.y
gcc ./lex.yy.c ./grammar.tab.c -o out -lws2_32 -w