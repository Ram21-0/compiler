%{
    #include<string.h>
    #include<stdio.h>
    #include "grammar.tab.h"
    int line = 0;
    #define YYSTYPE char *
%}

alpha [A-Za-z_]
digit [0-9]
%option yylineno

%%
[/][/].*            {;}
[/]\*.*             {;}
.*\*[/]	            {;}
[ \t\n]             {yylval = strdup(yytext);}
":"                 {yylval = strdup(yytext);return T_colon;}
"?"                 {yylval = strdup(yytext);return T_ques;}
"while"             {yylval = strdup(yytext);return WHILE;}
"do"	            {yylval = strdup(yytext);return DO;}
"if"                {yylval = strdup(yytext);return IF;}
"else"              {yylval = strdup(yytext);return ELSE;}
"print"             {yylval = strdup(yytext);return PRINT;}
"println"           {yylval = strdup(yytext);return PRINTLN;}
"endl"              {yylval = strdup(yytext);return ENDL;}
"break"             {yylval = strdup(yytext);return BREAK;}
"return"            {yylval = strdup(yytext);return RETURN;}
"continue"          {yylval = strdup(yytext);return CONTINUE;}
"int"               {yylval = strdup(yytext);return INT_DATATYPE;}
"char"              {yylval = strdup(yytext);return CHAR_DATATYPE;}
"void"              {yylval = strdup(yytext);return VOID_DATATYPE;}
"boolean"           {yylval = strdup(yytext);return BOOLEAN_DATATYPE;}
"String"            {yylval = strdup(yytext);return STRING_DATATYPE;}
"when"              {yylval = strdup(yytext);return WHEN;}
"or"                {yylval = strdup(yytext);return OR;}
"func"              {yylval = strdup(yytext);return FUNC;}
"loop"              {yylval = strdup(yytext);return FOR;}
"till"              {yylval = strdup(yytext);return TILL;}
"read"              {yylval = strdup(yytext);return INPUT;}
"array"             {yylval = strdup(yytext);return ARRAY;}
"set"               {yylval = strdup(yytext);return SET;}

"true"|"false"      {yylval = strdup(yytext); return BOOLEAN_TERM;}

{digit}+                        {yylval = strdup(yytext);return NUM;}
{alpha}({alpha}|{digit})*       {yylval = strdup(yytext);return ID;}


\'.\'           {yylval = strdup(yytext);return CHARACTER;}
\"(\\.|[^"\\])*\"          {yylval = strdup(yytext);return STRING;}
"<"             {yylval = strdup(yytext);return T_lt;}
">"             {yylval = strdup(yytext);return T_gt;}
"="             {yylval = strdup(yytext);return T_eq;}
"<="            {yylval = strdup(yytext);return T_lteq;}
">="            {yylval = strdup(yytext);return T_gteq;}
"=="            {yylval = strdup(yytext);return T_eqeq;}
"!="            {yylval = strdup(yytext);return T_neq;}
"+"             {yylval = strdup(yytext);return T_pl;}
"-"             {yylval = strdup(yytext);return T_min;}
"*"             {yylval = strdup(yytext);return T_mul;}
"/"             {yylval = strdup(yytext);return T_div;}
"%"             {yylval = strdup(yytext);return T_mod;}
"**"            {yylval = strdup(yytext);return T_pow;} 
"++"            {yylval = strdup(yytext);return T_incr;}
"--"            {yylval = strdup(yytext);return T_decr;}
"!"             {yylval = strdup(yytext);return T_not;}
"||"            {yylval = strdup(yytext);return T_or;}
"&&"            {yylval = strdup(yytext);return T_and;}
"#"             {yylval = strdup(yytext);return T_conc;}

.               return yytext[0];

%%

int yywrap(void) {
    return 1;
}