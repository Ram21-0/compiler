%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <ctype.h>
    #include <math.h>

    #define YY_USER_ACTION yylloc.first_line = yylloc.last_line = yylineno;
    
    int yylex();
    void yyerror(char *);

    typedef struct Treenode {
        char *name, *variable, *datatype;
        struct Treenode *left;
        struct Treenode *right;
    } Node; 
    
    typedef struct SymbolTableEntry {
        char *name, type, *datatype;
        int lastLine, firstLine;
    } Entry;

    typedef struct ICGUtilEntry {
        char *name, *datatype;
        int no;
    } ICG;

    typedef struct Function {
         char *name, *returnType;
         char *arguments[1000];
         int argSize;
         Entry fsTable[1000];
         int fsTableSize;
    } Function;

    int tableSize = 0;
    Entry symbolTable[10000];

    Entry funcSymbolTable[10000];
    int fTableSize = 0;

    int icgTableSize = 0;
    ICG icgTable[10000];
    
    char *variableNames[10000];
    int variableNamesSize = 0;

    char *functionArgs[10000];
    int funcArgsSize = 0;

    char *storeFuncArgsArray[1000];
    int storeFuncArgsArraySize = 0;

    char *storeFuncNamesArray[1000];
    int storeFuncNamesArraySize = 0;

    Function functions[10000];
    int functionsSize = 0;

    int function = 0;

    int searchFunctionSymbolTable(char *token,Function f) {
          for(int i=0;i<f.fsTableSize;i++) {
                if(!strcmp(token,f.fsTable[i].name)) return i;
          }
          return -1;
    }

    int addToFunctionSymbolTable(Entry e, Function f) {
          f.fsTable[f.fsTableSize++] = e;
    }

    int searchTable(char *token) {
        if(!function) {
            for(int i=0;i<tableSize;i++) 
                  if(!strcmp(token,symbolTable[i].name)) return i;
            return -1;
        } 
        
        else {
            for(int i=0;i<fTableSize;i++)
                if(!strcmp(token,funcSymbolTable[i].name)) return i;
            return -1;
        }
    }

    void addToTable(Entry e) {
        e.firstLine = e.lastLine;
        if(!function) symbolTable[tableSize++] = e;
        else funcSymbolTable[fTableSize++] = e;
    }

    void updateTable(Entry e,int i) {
        if(!function) symbolTable[i].lastLine = e.lastLine;
        else funcSymbolTable[i].lastLine = e.lastLine;
    }

    void lookup(char *token, char type, char *datatype, int line) {
            
            Entry e = (Entry) {token,type,datatype,line};
            int find = searchTable(e.name);
            if(find == -1) addToTable(e);
            else updateTable(e,find);
    }

    extern FILE *yyin;
    extern int yylineno;
    extern char *yytext;

    FILE *parseTreeFile, *symbolTableFile, *icgFile, *finalCode, *funcFile, *file;
    
    Node* buildTree(char *,Node *,Node *);
    
    void printTree(Node *);
    #define YYSTYPE char*
    
    char* getEntryType(char ch);

    void checkRedefinition(char* token) {
          int find = searchTable(token);
          if(find != -1) {
              printf("Compilation Error: Multiple Declaration - Token %s at line %d already defined at line %d\n",token,yylineno,symbolTable[find].firstLine);
              exit(0);
          }

          find = searchFunction(token);
          if(find != -1) {
              printf("Compilation Error: Line %d - Cannot declare function %s as a variable\n",yylineno,token);
              exit(0);   
          }
    }

    void checkUndeclaredVar(char* token) {
          int find = searchTable(token);
          if(find == -1) {
                printf("Token %s at line %d is not defined\n",token,yylineno);
                exit(0);
          }
    }

    void checkAssignment(char *token, Node *n) {
          int find = searchTable(token);
          if(!function) {
            if(!strcmpi(symbolTable[find].datatype,"array") && !strcmpi(n->datatype,"int")) return;
            if(strcmpi(symbolTable[find].datatype,n->datatype)) {
                  printf("Compilation Error: Cannot assign %s to %s at line %d\n",n->datatype,symbolTable[find].datatype,symbolTable[find].lastLine);
                  exit(0);
            }
          }
          else if(!strcmpi(funcSymbolTable[find].datatype,"array") && !strcmpi(n->datatype,"int")) return;
          else if(strcmpi(funcSymbolTable[find].datatype,n->datatype)) {
                  printf("Compilation Error: Cannot assign %s to %s at line %d\n",n->datatype,funcSymbolTable[find].datatype,funcSymbolTable[find].lastLine);
                  exit(0);
            }
    }

    void checkTypes(Node *n,Node *m,char *type) {
          if(strcmpi(n->datatype,type)) {
                printf("Compilation error : Cannot convert %s into %s at %d\n",n->datatype,type,yylineno);
                exit(0);
          }
          if(strcmpi(m->datatype,type)) {
                printf("Compilation error : Cannot convert %s into %s at %d\n",m->datatype,type,yylineno);
                exit(0);
          }
    }

    int flag = 0, tNo = 0, lNo = 0, end = 100, xNo = 0, ifNo = 0, endifNo = 0, dNo = 0, wNo = 0;
    Node* buildTree2(char*, Node*, Node*, char*, char*);

    int stack1[1000], stack2[1000], top1 = -1, top2 = -1;
    int stack3[1000], top3 = -1;
    int ifStack[1000], ifTop = -1;
    int endifStack[1000], endifTop = -1;
    int dStack[1000], dTop = -1;
    int whenStack[1000], whenTop = -1;

    void push(int stack[],int x,int *top) {
          stack[++(*top)] = x;
    }

    int pop(int stack[],int *top) {
          return stack[(*top)--];
    }

    int assign = 0;
    char assignDatatype[100];

    int searchFunction(char *token) {
            for(int i=0;i<functionsSize;i++) 
                  if(!strcmp(token,functions[i].name)) 
                        return i;
            return -1;
    }

    void addFunction(Function e) {
        functions[functionsSize++] = e;
    }

%}


%start S

%token DO WHILE BREAK CONTINUE RETURN IF ELSE PRINT PRINTLN FOR ENDL WHEN OR FUNC LOOP TILL UPD INPUT SET
%token ID NUM STRING CHARACTER BOOL_ID STRING_ID BOOLEAN_TERM STRING_TERM ARRAY
%token INT_DATATYPE CHAR_DATATYPE FLOAT_DATATYPE BOOLEAN_DATATYPE STRING_DATATYPE VOID_DATATYPE
%token T_lt T_gt T_lteq T_gteq T_neq T_eqeq T_ques T_colon
%token T_not T_and T_or
%token T_pl T_min T_mul T_div T_mod T_pow T_incr T_decr T_eq T_conc

%left T_lt T_gt 
%right T_pow
%left T_pl T_min T_conc
%left T_mul T_div T_mod

%%

S : FUNCTIONS CODE
  ;

FUNCTIONS : 
          | FUNCTIONS FUNCTION_DEFINITION {
              printTree($2);
              fprintf(parseTreeFile,"\n");
              fprintf(parseTreeFile,"----------------------------------------------------------------\n");
            }

          | FUNCTION_DEFINITION {
              printTree($1);
              fprintf(parseTreeFile,"\n");
              fprintf(parseTreeFile,"----------------------------------------------------------------\n");
            }
          ;

CODE
      : CODE statement ';' {
              printTree($2);
              fprintf(parseTreeFile,"\n");
              fprintf(parseTreeFile,"----------------------------------------------------------------\n");
            }

      | CODE LOOPS {
            printTree($2);
            fprintf(parseTreeFile,"\n");
            fprintf(parseTreeFile,"----------------------------------------------------------------\n");
        }

      | statement ';' {
            printTree($1);
            fprintf(parseTreeFile,"\n");
            fprintf(parseTreeFile,"----------------------------------------------------------------\n");
        }

      | LOOPS {
            printTree($1);
            fprintf(parseTreeFile,"\n");
            fprintf(parseTreeFile,"----------------------------------------------------------------\n");
        }
      ;

LOOPS
      : FOR {lookup("for",'K',NULL,yylineno);} '(' ASSIGNMENT_EXPRESSION ';' {while1();} COND ';' {while2($7); for3();} statement {for4(); } ')' CODE_BLOCK { 
            Node *cond = buildTree("SEQ",$4,buildTree("SEQ",$7,$10));
            $$ = buildTree("FOR",cond,$13);
            for5();
        } 

      | WHILE {lookup("while",'K',NULL,yylineno); while1();} COND {while2($3);} CODE_BLOCK { 
            $$ = buildTree("WHILE",$3,$5); 
            while3();
        }

      | IF {lookup("if",'K',NULL,yylineno);} COND {if1($3);} CODE_BLOCK {if2();} ELSE_STATEMENT { 
            if($7) $$ = buildTree("IF-ELSE",buildTree("IF",$3,$5),$7);
            else $$ = buildTree("IF",$3,$5);
            if3();
        }

      | DO {lookup("do",'K',NULL,yylineno); do1();} CODE_BLOCK WHILE {lookup("while",'K',NULL,yylineno);} COND ';' {            
            $$ = buildTree("DO-WHILE",$6,$3);
            do2($6);
        }
      ;

ELSE_STATEMENT : {$$=NULL;}
               | ELSE {lookup("else",'K',NULL,yylineno);} CODE_BLOCK {
                     $$ = buildTree("ELSE",0,$3);
                }
               ;
               
CODE_BLOCK
      : '(' LOOPC ')' {$$=$2;}
      | LOOPS
      | ';' {$$ = NULL;}
      | statement ';'
      | '(' ')' {$$ = NULL;}
      ;

LOOPC
      : LOOPC statement ';' {
            $$ = buildTree("SEQ",$1,$2);
        }
      | LOOPC LOOPS {
            $$ = buildTree("SEQ",$1,$2);
        }
      | statement ';' {$$=$1;}
      | LOOPS {$$=$1;}
      ;

statement
      : ASSIGNMENT_EXPRESSION {$$=$1;}
      | BOOL_ASSIGNMENT_EXPRESSION {$$=$1;}
      | EXP {$$=$1;}
      | DECLARATION
      | PRINT_STATEMENT {$$=$1;}
      | RETURN EXP {
            lookup("return",'K',0,yylineno); 
            $$=buildTree("RETURN",0,$2);
            fprintf(file,"return %s;",((Node*)$2)->variable);
       }
      | FUNCTION_CALL 
      | INPUT ID {
            checkUndeclaredVar($2);
            lookup($1,'K',0,yylineno); 
            $$=buildTree($1,0,buildTree($2,0,0));
            fprintf(file,"cin>>%s;\n",$2);
      }
      | BREAK {
            $$ = buildTree("break",0,0); lookup("break",'K',0,yylineno); 
            if(top2 == -1) {
                  printf("Compilation Error : Break used outside a loop at line %d",yylineno);
                  exit(0);
            }
            fprintf(file,"goto L%d;\n",stack2[top2]);
       }
      | CONTINUE {
            $$ = buildTree("continue",0,0); lookup("continue",'K',0,yylineno); 
            if(top3 == -1) {
                  printf("Compilation Error : Continue used outside a loop at line %d",yylineno);
                  exit(0);
            }
            fprintf(file,"goto XX%d;\n",stack3[top3]);
       }
      ;

DECLARATION
      : TYPE A {
            for(int i=0;i<variableNamesSize;i++) {
                  lookup(variableNames[i],'I',((Node*)($1))->name,yylineno);
                  if(function) fprintf(file,"%s %s;\n",((Node*)($1))->name,variableNames[i]);
            }
            variableNamesSize = 0;
            $$ = buildTree("DECLARATION",$1,$2);
        }

      | ARRAY ID '[' NUM ']' {
                  checkRedefinition($2);
                  lookup($2,'I',"array",yylineno); 
                  $$ = buildTree("DECL",buildTree("array",0,0),buildTree($2,0,0));
        }
      ;

  A : ID ',' A { 
            checkRedefinition($1);
            variableNames[variableNamesSize++] = $1; 
            $$ = buildTree("DECL",buildTree($1,0,0),$3);
      }
      |ID { 
            checkRedefinition($1);
            variableNames[variableNamesSize++] = $1;    
            $$ = buildTree($1,0,0);
       }
      ;

COND : '(' COND ')' {$$=$2;}
      | BOOL_EXP {$$=$1;}
      | FACTOR RELOP FACTOR {
            // $$=buildTree($2,$1,$3);
            // codegen($$,$1,$3,$2);

            checkTypes($1,$3,"int");
            $$=buildTree2($2,$1,$3,"null","null"); 
            lookup($2,'O',NULL,yylineno); 
            ((Node*)$$)->datatype = "BOOLEAN";
            codegen($$,$1,$3,$2); 
        }

      | COND bin_boolop COND {
            // $$=buildTree($2,$1,$3);
            // codegen($$,$1,$3,$2);
      
            checkTypes($1,$3,"BOOLEAN");
            $$=buildTree2($2,$1,$3,"null","null");
            lookup($2,'O',NULL,yylineno); 
            ((Node*)$$)->datatype = "BOOLEAN";
            codegen($$,$1,$3,$2); 
        }

      | un_boolop '(' COND ')' {
            checkTypes($3,$3,"BOOLEAN");
            $$=buildTree2($1,$3,0,"null","null");
            Node *empty = (Node*) malloc(sizeof(Node*));
            empty->variable = "";
            ((Node*)$$)->datatype = "BOOLEAN";
            codegen($$,empty,$3,$1);
        }
      ;

ASSIGNMENT_EXPRESSION
      : ID T_eq EXP {
            checkUndeclaredVar($1);
            checkAssignment($1,$3);

            Node *idNode = buildTree($1,0,0); 
            $$=buildTree("=",idNode,$3); 
            lookup("=",'O',NULL,yylineno); 
            lookup($1,'I',"int",yylineno);

            Node *icgNode = buildTree($1,0,0);
            icgNode->variable = $1;
            codegen_assign($$,icgNode,$3);
       }

      | ID T_eq WHEN_EXPRESSION {
            checkUndeclaredVar($1);
            checkAssignment($1,$3);

            Node *idNode = buildTree($1,0,0); 
            $$=buildTree("=",idNode,$3); 
            lookup("=",'O',NULL,yylineno); 
            lookup($1,'I',"int",yylineno);

            Node *icgNode = buildTree($1,0,0);
            icgNode->variable = $1;
            codegen_assign($$,icgNode,$3);
            wNo++;
       }

      | TYPE ID T_eq EXP {
            checkRedefinition($2);
            Node *idNode = buildTree($2,0,0); 
            $$=buildTree("=",idNode,$4); 
            lookup("=",'O',NULL,yylineno); 
            lookup($2,'I',((Node*)$1)->name,yylineno);
            
            checkAssignment($2,$4);

            Node *icgNode = buildTree($2,0,0);
            icgNode->variable = $2;
            assign = 1;
            // assignDatatype = ((Node*)$1)->name;
            strcpy(assignDatatype,((Node*)$1)->name);
            if(!strcmpi(assignDatatype,"string")) strcpy(assignDatatype,"string");
            else if(!strcmpi(assignDatatype,"boolean")) strcpy(assignDatatype,"int");
            codegen_assign($$,icgNode,$4);
            assign = 0;
       }

      | TYPE ID T_eq STRING_EXP {
            checkRedefinition($2);

            Node *idNode = buildTree($2,0,0); 
            $$=buildTree("=",idNode,$4); 
            lookup("=",'O',NULL,yylineno); 
            lookup($2,'I',"STRING",yylineno);

            checkAssignment($2,$4);
            
            Node *icgNode = buildTree($2,0,0);
            icgNode->variable = $2;
            assign = 1;
            // assignDatatype = ((Node*)$1)->name;
            strcpy(assignDatatype,((Node*)$1)->name);
            if(!strcmpi(assignDatatype,"string")) strcpy(assignDatatype,"string");
            else if(!strcmpi(assignDatatype,"boolean")) strcpy(assignDatatype,"int");
            codegen_assign($$,icgNode,$4);
            assign = 0;
       }

      | ID T_eq STRING_EXP {
            checkUndeclaredVar($1);
            checkAssignment($1,$3);

            Node *idNode = buildTree($1,0,0); 
            $$=buildTree("=",idNode,$3); 
            lookup("=",'O',NULL,yylineno); 
            lookup($1,'I',"STRING",yylineno);

            Node *icgNode = buildTree($1,0,0);
            icgNode->variable = $1;
            codegen_assign($$,icgNode,$3);
       }

      | TYPE ID T_eq WHEN_EXPRESSION {
            checkRedefinition($2);
            checkAssignment($2,$4);
            
            Node *idNode = buildTree($2,0,0); 
            $$=buildTree("=",idNode,$4); 
            lookup("=",'O',NULL,yylineno); 
            lookup($2,'I',((Node*)$1)->name,yylineno);

            Node *icgNode = buildTree($2,0,0);
            icgNode->variable = $2;
            assign = 1;
            
            strcpy(assignDatatype,((Node*)$1)->name);
            if(!strcmpi(assignDatatype,"string")) strcpy(assignDatatype,"string");
            else if(!strcmpi(assignDatatype,"boolean")) strcpy(assignDatatype,"int");
            codegen_assign($$,icgNode,$4);
            assign = 0;
            wNo++;
       }

      | SET ID '[' EXP ']' T_eq EXP {
            checkUndeclaredVar($2);
            if(strcmpi(((Node*)$4)->datatype,"int")) {
                  printf("Compilation Error : Index has to be an integer at line %d %s\n",yylineno,((Node*)$4)->datatype); 
                  exit(0);
            }

            checkAssignment($2,$4);
            lookup("set",'K',NULL,yylineno); 
            lookup("=",'O',NULL,yylineno); 
            lookup($2,'I',"array",yylineno); 
            $$ = buildTree("=",buildTree("[]",buildTree($2,0,0),$4),$7);

            codegenSet($$,$2,$4,$7);
      }
      ;
  
WHEN_EXPRESSION 
      : EXP WHEN COND {when2($3); when3($1); when4();} OR WHEN_PART2 {
            lookup("when",'K',NULL,yylineno);
            lookup("or",'K',NULL,yylineno);

            $$ = buildTree("WHEN-OR",
                    buildTree("WHEN",$3,$1),
                    buildTree("OR",0,$6));

            char *res = (char *)malloc(sizeof(char)*5+1);
            tostring(res,wNo);      
            char *t = (char *)malloc(sizeof(char)*5+1);
            strcpy(t,"w");
            strcat(t,res);
            ((Node*)$$)->variable = (char*)t;
            ((Node*)$$)->datatype = "int";
            
            icgTable[icgTableSize++] = (ICG) {"w","int",wNo};
            fprintf(file,"w%d = %s;\n",wNo++,((Node*)$6)->variable);
       }
       ;

WHEN_PART2 
      : EXP { $$ = $1; }
      | WHEN_EXPRESSION { $$ = $1; }
      ;

EXP  
      : ADDITION {$$=$1;}
      ;

AND_OR 
         : BOOL_TERM {$$=$1;}
         | AND_OR T_and BOOL_TERM {
                  checkTypes($1,$3,"BOOLEAN");
                  $$=buildTree2("&&",$1,$3,"null","null"); 
                  lookup("&&",'O',NULL,yylineno); 
                  ((Node*)$$)->datatype = "BOOLEAN";
                  codegen($$,$1,$3,"&&"); 
           }

         | AND_OR T_or BOOL_TERM {
                  checkTypes($1,$3,"BOOLEAN"); 
                  $$=buildTree2("||",$1,$3,"null","null"); 
                  lookup("||",'O',NULL,yylineno); 
                  ((Node*)$$)->datatype = "BOOLEAN"; 
                  codegen($$,$1,$3,"||"); 
           }
      ;

ADDITION
      : TERM {$$=$1;}
      | ADDITION T_pl TERM {
            checkTypes($1,$3,"int");
            $$=buildTree2("+",$1,$3,"null","int"); 
            lookup("+",'O',NULL,yylineno); 
            ((Node*)$$)->datatype = "int";
            codegen($$,$1,$3,"+"); 
        }
      | ADDITION T_min TERM {
            checkTypes($1,$3,"int");
            $$=buildTree("-",$1,$3); 
            lookup("-",'O',NULL,yylineno); 
            ((Node*)$$)->datatype = "int";
            codegen($$,$1,$3,"-");
        }
      ;

TERM  : POWER_TERM {$$=$1;}
      | TERM T_mul POWER_TERM {checkTypes($1,$3,"int"); $$=buildTree("*",$1,$3); lookup("*",'O',NULL,yylineno); ((Node*)$$)->datatype = "int"; codegen($$,$1,$3,"*");}
      | TERM T_div POWER_TERM {checkTypes($1,$3,"int"); $$=buildTree("/",$1,$3); lookup("/",'O',NULL,yylineno); ((Node*)$$)->datatype = "int"; codegen($$,$1,$3,"/");}
      | TERM T_mod POWER_TERM {checkTypes($1,$3,"int"); $$=buildTree("%",$1,$3); lookup("%",'O',NULL,yylineno); ((Node*)$$)->datatype = "int"; codegen($$,$1,$3,"%");}
      ;

POWER_TERM : FACTOR {$$=$1;}
           | POWER_TERM T_pow FACTOR {
                 checkTypes($1,$3,"int");
                 $$=buildTree("**",$1,$3); 
                 lookup("**",'O',NULL,yylineno); 
                 ((Node*)$$)->datatype = "int";
                 codegen($$,$1,$3,"**");
                 
             }
           ;
  
FACTOR
      : LIT {$$=$1;}
      | FUNCTION_CALL
      | ID un_arop {
            checkUndeclaredVar($1);

            int find = searchTable($1);
            if(!function) {
                  if(strcmp(symbolTable[find].datatype,"int")) {
                        printf("Compilation Error : %s is not an integer at %d\n",$1,yylineno);
                        exit(0);
                  }     
            }
            else if(strcmp(funcSymbolTable[find].datatype,"int")) {
                        printf("Compilation Error : %s is not an integer at %d\n",$1,yylineno);
                        exit(0);
                  }     

            Node *idNode = buildTree($1,0,0);
            $$ = buildTree2($2,idNode,0,$2,"int");
            idNode->variable = $1;
            Node *empty = (Node*) malloc(sizeof(Node*));
            empty->variable = "";
            codegen($$,empty,idNode,$2);
            codegen_assign($$,idNode,$$);
        }
      | '(' EXP ')' {$$=$2;}
      ;
      
PRINT_STATEMENT
      : PRINT STRING_EXP { $$ = buildTree($1,$2,0); lookup("print",'K',NULL,yylineno); fprintf(file,"cout<<%s;\n",((Node*)$2)->variable); }
      | PRINT BOOL_EXP { $$ = buildTree($1,$2,0); lookup("print",'K',NULL,yylineno); fprintf(file,"cout<<%s;\n",((Node*)$2)->variable); }
      | PRINT EXP { $$ = buildTree($1,$2,0); lookup("print",'K',NULL,yylineno); fprintf(file,"cout<<%s;\n",((Node*)$2)->variable); }
      | PRINTLN STRING_EXP { $$ = buildTree($1,$2,0); lookup("println",'K',NULL,yylineno); fprintf(file,"cout<<%s;cout<<endl;\n",((Node*)$2)->variable); }
      | PRINTLN BOOL_EXP { $$ = buildTree($1,$2,0); lookup("println",'K',NULL,yylineno); fprintf(file,"cout<<%s;cout<<endl;\n",((Node*)$2)->variable); }
      | PRINTLN EXP { $$ = buildTree($1,$2,0); lookup("println",'K',NULL,yylineno); fprintf(file,"cout<<%s;cout<<endl;\n",((Node*)$2)->variable); }
      ;

LIT : ID {
            checkUndeclaredVar($1);
            int find = searchTable($1);
            if(!function) $$ = buildTree2($1,0,0,$1,symbolTable[find].datatype);
            else $$ = buildTree2($1,0,0,$1,funcSymbolTable[find].datatype);
            lookup($1,'I',NULL,yylineno);
        }
      | NUM {
            $$ = buildTree2($1,0,0,(char*)yylval,"int");
            lookup((char *)yylval,'C',"int",yylineno);
        }
      
      | '{' ID '[' EXP ']' '}' {
            checkUndeclaredVar($2);
            int f1 = searchTable($2);
            if(function) {
                  if(strcmpi(funcSymbolTable[f1].datatype,"array")) { printf("Compilation Error : Cannot subscript %s at line %d\n",$2,yylineno); exit(0); }
            }
            else if(strcmpi(symbolTable[f1].datatype,"array")) { printf("Compilation Error : Cannot subscript %s at line %d\n",$2,yylineno); exit(0); }
            if(strcmpi(((Node*)$4)->datatype,"int")) { printf("Compilation Error : Index has to be an integer at line %d %s\n",yylineno,((Node*)$4)->datatype); exit(0); }

            $$ = buildTree2("[]",buildTree($2,0,0),$4,"var","int");
            lookup($2,'I',"array",yylineno);
            codegenArray($$,$2,$4,0);
        }
      ;
    
TYPE
      : INT_DATATYPE {$$ = buildTree($1,0,0); lookup((char*)yylval,'K',NULL,yylineno);}
      | STRING_DATATYPE {$$ = buildTree((char*)yylval,0,0); lookup((char*)yylval,'K',NULL,yylineno);}
      | ARRAY {$$ = buildTree((char*)yylval,0,0); lookup((char*)yylval,'K',NULL,yylineno);}
      ;

ARRAY_TYPE : '<' INT_DATATYPE '>' { $$ = buildTree("array",0,0); }

BOOL_ASSIGNMENT_EXPRESSION
      : ID T_eq COND {
            checkUndeclaredVar($1);
            Node *idNode = buildTree($1,0,0); 
            $$=buildTree("=",idNode,$3); 
            lookup("=",'O',NULL,yylineno);
            lookup($1,'I',"BOOLEAN",yylineno);

            Node *icgNode = buildTree($1,0,0);
            icgNode->variable = $1;
            codegen_assign($$,icgNode,$3);
        }
      | BOOL_TYPE ID T_eq COND {
            checkRedefinition($2);
            Node *idNode = buildTree($2,0,0); 
            $$=buildTree("=",idNode,$4); 
            lookup("=",'O',NULL,yylineno);
            lookup($2,'I',"BOOLEAN",yylineno);

            checkAssignment($2,$4);

            Node *icgNode = buildTree($2,0,0);
            icgNode->variable = $2;
            codegen_assign($$,icgNode,$4);
        }
      ;

BOOL_TYPE : BOOLEAN_DATATYPE {
                  $$ = buildTree((char*)yylval,0,0);
                  lookup($1,'K',NULL,yylineno);
            }
  ;

BOOL_EXP  
      : AND_OR {$$=$1;}
      ;

BOOL_TERM : BOOL_LIT {$$=$1;}
      ;

BOOL_LIT
      : ID {
            checkUndeclaredVar($1);
            int find = searchTable($1);
            if(!function) $$ = buildTree2($1,0,0,$1,symbolTable[find].datatype);
            else $$ = buildTree2($1,0,0,$1,funcSymbolTable[find].datatype);
            lookup($1,'I',NULL,yylineno);
        }
      | BOOLEAN_TERM {
            $$ = buildTree2((char*)yylval,0,0,(char*)yylval,"BOOLEAN"); 
            lookup($1,'C',"BOOLEAN",yylineno);
        }
      ;

STRING_EXP : STRING_LIT {$$=$1;}
           | STRING_EXP T_conc STRING_LIT {
                 checkTypes($1,$3,"STRING"); 
                 $$=buildTree("#",$1,$3); 
                 lookup("#",'O',NULL,yylineno); 
                 ((Node*)$$)->datatype = "STRING";
                 codegen($$,$1,$3,"+"); 
            }
          
      ;

STRING_LIT 
      : STRING {
            $$ = buildTree2((char*)yylval,0,0,(char*)yylval,"STRING"); 
            lookup($1,'C',"STRING",yylineno);
        }
      | LIT 
      | STRING_LIT '[' LIT ']' {
            $$ = buildTree2("[]",$1,$3,((Node*)$1)->variable,"STRING"); 
            lookup(((Node*)$1)->name,'C',"STRING",yylineno);
            codegenRef($$,$1,$3);
      }
      ;

RELOP
      : T_lt { $$ = "<"; lookup("<",'O',NULL,yylineno);}
      | T_gt { $$ = ">"; lookup(">",'O',NULL,yylineno);}
      | T_lteq { $$ = "<="; lookup("<=",'O',NULL,yylineno);}
      | T_gteq { $$ = ">="; lookup(">=",'O',NULL,yylineno);}
      | T_neq { $$ = "!="; lookup("!=",'O',NULL,yylineno);}
      | T_eqeq { $$ = "=="; lookup("==",'O',NULL,yylineno);}
      ;

bin_boolop
      : T_and {$$="&&"; lookup("&&",'O',NULL,yylineno);}
      | T_or {$$="||"; lookup("||",'O',NULL,yylineno);}
      ;

un_arop
      : T_incr {$$="++"; lookup("++",'O',NULL,yylineno);}
      | T_decr {$$="--"; lookup("--",'O',NULL,yylineno);}
      ;

un_boolop
      : T_not {$$="!"; lookup("!",'O',NULL,yylineno);}
      ;


FUNCTION_CALL : ID '(' ARGS ')' {
                        $$ = buildTree($1,$3,0);
                        ((Node*)$$)->datatype = "int";
                        
                        icgTable[icgTableSize++] = (ICG) {"t","int",tNo};
                        char *res = (char *)malloc(sizeof(char)*5+1);
                        tostring(res,tNo++);      
                        char *t = (char *)malloc(sizeof(char)*5+1);
                        strcpy(t,"t");
                        strcat(t,res);
                        ((Node*)$$)->variable = (char*)t;

                        fprintf(file,"%s = %s(",t,$1);

                        int find = searchFunction($1);
                        if(find == -1) {
                              printf("Compilation Error : %s at line %d is not a function\n",$1,yylineno);
                              exit(0);
                        }

                        if(funcArgsSize != functions[find].argSize) {
                              printf("Compilation Error : Function %s requires %d args, but received %d args\n",functions[find].name,functions[find].argSize,funcArgsSize);
                              exit(0);
                        }

                        for(int i=0;i<funcArgsSize-1;i++) {
                              // int find2 = searchFunctionSymbolTable(functionArgs[i],functions[find]);
                              // if(strcmpi(functions[find].arguments[i],functions[find].fsTable[find2].datatype)) {
                              //       printf("Compilation Error : Cannot convert %s to %s\n",functions[find].fsTable[find2].datatype,functions[find].arguments[i]);
                              //       exit(0);
                              // }
                              fprintf(file,"%s,",functionArgs[i]);
                        }

                        // int find2 = searchFunctionSymbolTable(functionArgs[funcArgsSize-1],functions[find]);
                        // if(strcmpi(functions[find].arguments[funcArgsSize-1],functions[find].fsTable[find2].datatype)) {
                        //       printf("Compilation Error : Cannot convert %s to %s\n",functions[find].fsTable[find2].datatype,functions[find].arguments[funcArgsSize-1]);
                        //       exit(0);
                        // }
                        if(funcArgsSize > 0) fprintf(file,"%s);\n",functionArgs[funcArgsSize-1]);
                        else fprintf(file,");\n");
                        funcArgsSize = 0;
                }
              ;

ARGS : ARG { 
            $$ = $1; 
            if($$) functionArgs[funcArgsSize++] = ((Node*)$1)->variable;
       }
     | ARGS ',' ARG { 
            $$ = buildTree("ARGS",$1,$3); 
            functionArgs[funcArgsSize++] = ((Node*)$3)->variable; 
       }
     ;

ARG : EXP
    | STRING_EXP
    | BOOL_EXP
    | {$$ = NULL;}
    ;

FUNCTION_DEFINITION : FUNC TYPE ID T_eq '(' {function = 1; fclose(file); file = fopen("func.txt","a"); fprintf(file,"%s %s(",((Node*)$2)->name,$3);} PARAMS ')' T_colon {

            fprintf(file,") {\n");
            
            int ffind = searchFunction($3);
            if(ffind != -1) {
                  printf("Compilation Error : Function %s already defined\n",$3);
                  exit(0);
            }
            ffind = searchTable($3);
            if(ffind != -1) {
                  printf("Compilation Error : %s has been declared as a variable at %d\n",$3,yylineno);
                  exit(0);
            }

            Function ff;
            ff.name = $3;
            ff.returnType = ((Node*)($2))->name;
            ff.fsTableSize = 0;
            for(int i=0;i<storeFuncArgsArraySize;i++) {
                  char *a = (char *) malloc(10*sizeof(char));
                  strcpy(a, storeFuncArgsArray[i]);
                  ff.arguments[i] = a;

                  char *b = (char *) malloc(10*sizeof(char));
                  strcpy(b, storeFuncNamesArray[i]);

                  Entry e = (Entry) {b,'I',a,0,0};
                  addToFunctionSymbolTable(e,ff);
            }
            ff.argSize = storeFuncArgsArraySize;
            storeFuncArgsArraySize = 0;
            storeFuncNamesArraySize = 0;

            addFunction(ff);

      } CODE_BLOCK {
                  $$ = buildTree($3,$7,$11);
                  fprintf(file,"}\n");
                  fclose(file);
                  file = fopen("ICG.txt","w");
                  function = 0;
                  fTableSize = 0;
      }
      ;

PARAMS : TYPE ID { 
            $$ = buildTree($2,0,0); 
            char x[20]; strcpy(x,((Node*)$1)->name);
            if(!strcmpi(x,"string")) strcpy(x,"string");
            else if(!strcmpi(x,"boolean")) strcpy(x,"int"); 

            if(!strcmpi(x,"array")) fprintf(file,"int %s[]",$2);
            else fprintf(file,"%s %s",x,$2); 

            lookup($2,'I',((Node*)($1))->name,yylineno);

            char *a = (char *) malloc(10*sizeof(char)); strcpy(a,x);
            storeFuncArgsArray[storeFuncArgsArraySize++] = a;
            storeFuncNamesArray[storeFuncNamesArraySize++] = $2;
       }

       | PARAMS ',' TYPE ID { 
             $$ = buildTree("PARAMS",$1,buildTree($4,0,0)); 
             char x[20]; strcpy(x,((Node*)$3)->name);
             if(!strcmpi(x,"string")) strcpy(x,"string");
             else if(!strcmpi(x,"boolean")) strcpy(x,"int");
             fprintf(file,",%s %s",x,$4); 
             lookup($4,'I',((Node*)($3))->name,yylineno);
                  
             char *a = (char *) malloc(10*sizeof(char)); strcpy(a,x);
             storeFuncArgsArray[storeFuncArgsArraySize++] = a;
             storeFuncNamesArray[storeFuncNamesArraySize++] = $2;
       }
       | {$$ = NULL;}
       ;

%%


int main(int argc,char *argv[]) {
    yyin = fopen(argv[1],"r");
    parseTreeFile = fopen("ParseTree.txt","w");
    symbolTableFile = fopen("SymbolTable.txt","w");

    finalCode = fopen("output.cpp","w");
    funcFile = fopen("func.txt","w");
    fclose(funcFile);

    file = fopen("ICG.txt","w");

    fprintf(finalCode,"#include <iostream>\n");
    fprintf(finalCode,"#include <cstring>\n");
    fprintf(finalCode,"using namespace std;\n");
        
    if(!yyparse()) printf("Parsing Complete\n\n\n===================================\n\n\n");
    else printf("Parsing failed at line %d\n",yylineno);
    
    fprintf(symbolTableFile,"Number of distinct tokens: %d\n\n",tableSize);
    fprintf(symbolTableFile,"| %5s\t|%40s\t|%10s\t|%10s\t|%13s\t|%10s\t|\n",
                              "S.NO","TOKEN","FIRST OCC","LAST OCC","TYPE","DATATYPE");
    fprintf(symbolTableFile,"|-------|------------------------------------------|-----------|-----------|---------------|-----------|\n");
    for(int i=0;i<tableSize;i++) {
        fprintf(symbolTableFile,
                  "| %5d\t|%40s\t|%10d\t|%10d\t|%13s\t|%10s\t|\n",
                  i+1,
                  symbolTable[i].name, 
                  symbolTable[i].firstLine, 
                  symbolTable[i].lastLine, 
                  getEntryType(symbolTable[i].type), 
                  symbolTable[i].datatype
               );
    }

    if(functionsSize > 0) {
          fprintf(symbolTableFile,"\n\nFUNCTIONS\n\n");
          fprintf(symbolTableFile,"%10s\t|\tArguments\n","FUNCTION");
          fprintf(symbolTableFile,"%10s\t|\n","");
          for(int i=0;i<functionsSize;i++) {
                fprintf(symbolTableFile,"%10s\t|\t%d\t",functions[i].name,functions[i].argSize);
                for(int j=0;j<functions[i].argSize;j++)
                      fprintf(symbolTableFile,"%s ",functions[i].arguments[j]);
                fprintf(symbolTableFile,"\n");
          }
    }

    fclose(file);
    file = fopen("ICG.txt","r");

    for(int i=0;i<icgTableSize;i++) {
          char *dt = (char *) malloc(sizeof(10));
          if(!strcmpi(icgTable[i].datatype,"boolean")) dt = "int";
          else if(!strcmpi(icgTable[i].datatype,"string")) dt = "string";
          else dt = icgTable[i].datatype;

          fprintf(finalCode,"%s %s%d;\n",dt,icgTable[i].name,icgTable[i].no);
    }

    char buffer2[255];
    funcFile = fopen("func.txt","r");
    while(fgets(buffer2, 255, funcFile)) {
        fprintf(finalCode,"%s", buffer2);
    }
    fclose(funcFile);

    fprintf(finalCode,"int main() {\n");

    for(int i=0;i<tableSize;i++) {
          if(symbolTable[i].type == 'I') {
                char *dt = (char *) malloc(sizeof(10));
                if(!strcmpi(symbolTable[i].datatype,"boolean")) dt = "int";
                else if(!strcmpi(symbolTable[i].datatype,"string")) dt = "string";
                else if(!strcmpi(symbolTable[i].datatype,"array")) {
                      fprintf(finalCode,"int %s[100];\n",symbolTable[i].name);      
                      continue;
                }
                else dt = "int";

                fprintf(finalCode,"%s %s;\n",dt,symbolTable[i].name);
          }
    }

    int bufferLength = 255;
    char buffer[bufferLength];
    while(fgets(buffer, bufferLength, file)) {
        fprintf(finalCode,"%s", buffer);
    }

    fprintf(finalCode,"return 0;\n");
    fprintf(finalCode,"}");

    fclose(yyin);
    fclose(parseTreeFile);
    fclose(symbolTableFile);
    fclose(file);
    return 0;
}

char* getEntryType(char ch) {
    switch(ch) {
        case 'I': return "IDENTIFIER";
        case 'O': return "OPERATOR";
        case 'K': return "KEYWORD";
        case 'C': return "CONSTANT";
    }
    return "Null";
}

Node* buildTree(char *op,Node *left,Node *right) {
    Node *new = (Node*) malloc(sizeof(Node));
    char *str = (char*) malloc(strlen(op)+1);
    char *varStr = (char*) malloc(10);
    strcpy(str, op);
    strcpy(varStr,"null");
    new->name = str;
    new->left = left;
    new->right = right;
    new->variable = "varStr";
    new->datatype = strdup(varStr);
    return new;
}

Node* buildTree2(char *op, Node *left, Node *right, char *variable, char *datatype) {
    Node *new = (Node*) malloc(sizeof(Node));
    new->name = op;
    new->variable = variable;
    new->datatype = datatype;
    new->left = left;
    new->right = right;
    return new;
}

void printTree(Node *tree) {
    if(tree->left || tree->right) fprintf(parseTreeFile,"(");
    if(tree->left) printTree(tree->left);
    fprintf(parseTreeFile," %s ",tree->name);
    if(tree->right) printTree(tree->right);
    if(tree->left || tree->right) fprintf(parseTreeFile,")");
}

void yyerror (char *s) {
   fprintf (stderr, "%s\n", s);
 }


void tostring(char *str, int num) {
    int i, rem, len = 0, n;
    if(num == 0) {
          str[0] = '0';
          str[1] = '\0';
          return;
    }
    n = num;
    while(n != 0) {
        len++;
        n /= 10;
    }
    for(i=0;i<len;i++) {
        rem = num % 10;
        num /= 10;
        str[len-(i+1)] = rem + '0';
    }
    str[len] = '\0';
}

void codegenRef(Node *cur,Node *arg1,Node *arg2) {
      
      icgTable[icgTableSize++] = (ICG) {"t","int",tNo};
      fprintf(file,"t%d = %s;\n",tNo++,arg2->variable);
      icgTable[icgTableSize++] = (ICG) {"t","char *",tNo};
      fprintf(file,"t%d = &%s[0];\n",tNo++,arg1->variable);
      icgTable[icgTableSize++] = (ICG) {"t","char *",tNo};
      fprintf(file,"t%d = t%d + t%d;\n",tNo,tNo-2,tNo-1);
      
      char *res = (char *)malloc(sizeof(char)*5+1);
      tostring(res,tNo++);      
      char *t = (char *)malloc(sizeof(char)*5+1);
      strcpy(t,"*t");
      strcat(t,res);
      
      cur->variable = (char*)t;
}

void codegenArray(Node *cur,char *arg1,Node *arg2) {
      
      icgTable[icgTableSize++] = (ICG) {"t","int",tNo};
      fprintf(file,"t%d = %s;\n",tNo++,arg2->variable);
      icgTable[icgTableSize++] = (ICG) {"t","int *",tNo};
      fprintf(file,"t%d = &%s[0];\n",tNo++,arg1);
      icgTable[icgTableSize++] = (ICG) {"t","int *",tNo};
      fprintf(file,"t%d = t%d + t%d;\n",tNo,tNo-2,tNo-1);
      
      char *res = (char *)malloc(sizeof(char)*5+1);
      tostring(res,tNo++);      
      char *t = (char *)malloc(sizeof(char)*5+1);
      strcpy(t,"*t");
      strcat(t,res);
      
      cur->variable = (char*)t;
}

void codegen(Node *cur, Node *arg1, Node *arg2, char *op){
           
      icgTable[icgTableSize++] = (ICG) {"t",cur->datatype,tNo};
      char *res = (char *)malloc(sizeof(char)*5+1);
      tostring(res,tNo++);      
      char *t = (char *)malloc(sizeof(char)*5+1);
      strcpy(t,"t");
      strcat(t,res);
      
      cur->variable = (char*)t;   
      if(strlen(arg1->variable) == 0) fprintf(file,"%s = %s %s; \n",t,op,arg2->variable);      
      else fprintf(file,"%s = %s %s %s; \n",t,arg1->variable, op, arg2->variable);      
}

void codegen_assign(Node *cur, Node *arg1, Node *arg2){ 
      if(function && assign) fprintf(file,"%s ",assignDatatype);
      fprintf(file,"%s = %s;\n",arg1->variable,arg2->variable); 
      cur->variable = arg1->variable;  
}

void codegenSet(Node *cur,Node *arg1,Node *arg2,Node *arg3) {
      icgTable[icgTableSize++] = (ICG) {"t","int",tNo};
      fprintf(file,"t%d = %s;\n",tNo++,arg2->variable);
      icgTable[icgTableSize++] = (ICG) {"t","int *",tNo};
      fprintf(file,"t%d = &%s[0];\n",tNo++,arg1);
      icgTable[icgTableSize++] = (ICG) {"t","int *",tNo};
      fprintf(file,"t%d = t%d + t%d;\n",tNo,tNo-2,tNo-1);
      fprintf(file,"*t%d = %s;\n",tNo,arg3->variable);
      
      char *res = (char *)malloc(sizeof(char)*5+1);
      tostring(res,tNo++);      
      char *t = (char *)malloc(sizeof(char)*5+1);
      strcpy(t,"*t");
      strcat(t,res);
      
      cur->variable = (char*)t;
}

while1() {
      fprintf(file,"L%d: \n", lNo); 
      push(stack1,lNo,&top1);
      lNo++;
}

while2(Node *cond) {
      icgTable[icgTableSize++] = (ICG) {"T","int",tNo};
      fprintf(file,"T%d = ! %s;\n",tNo,cond->variable);
      fprintf(file,"if (T%d) goto L%d;\n",tNo++,lNo); 
      push(stack2,lNo,&top2);
      lNo++;
}

while3(){
      fprintf(file,"goto L%d; \n",pop(stack1,&top1));
      fprintf(file,"L%d:\n",pop(stack2,&top2));
}

for3() {
      fprintf(file,"goto X%d; \n",xNo);
      fprintf(file,"XX%d:\n",xNo);
      push(stack3,xNo,&top3);
      xNo++;
}

for4() {
      fprintf(file,"goto L%d; \n",pop(stack1,&top1));
      fprintf(file,"X%d:\n",stack3[top3]);
}

for5() {
      fprintf(file,"goto XX%d;\n",pop(stack3,&top3));
      fprintf(file,"L%d:\n",pop(stack2,&top2));
}

if1(Node *cond) {
      icgTable[icgTableSize++] = (ICG) {"T","int",tNo};
      fprintf(file,"T%d = ! %s; \n",tNo,cond->variable);
      fprintf(file,"if (T%d) goto IF%d; \n",tNo++,ifNo); 
      push(ifStack,ifNo,&ifTop);
      ifNo++;
}

if2() {
      fprintf(file,"goto ENDIF%d;\n",endifNo);
      push(endifStack,endifNo,&endifTop);
      endifNo++;
      fprintf(file,"IF%d:\n",pop(ifStack,&ifTop));
}

if3() {
      fprintf(file,"ENDIF%d:\n",pop(endifStack,&endifTop));
}

do1() {
      fprintf(file,"D%d:\n",dNo);
      push(dStack,dNo,&dTop);
      dNo++;
}

do2(Node *cond) {
      icgTable[icgTableSize++] = (ICG) {"T","int",tNo};
      fprintf(file,"T%d = %s;\n",tNo,cond->variable);
      fprintf(file,"if (T%d) goto D%d;\n",tNo++,pop(dStack,&dTop));
}

when2(Node *cond) {
      icgTable[icgTableSize++] = (ICG) {"T","int",tNo};
      fprintf(file,"T%d = ! %s; \n",tNo,cond->variable);
      fprintf(file,"if(T%d) goto L%d; \n",tNo++,lNo); 
      push(whenStack,lNo,&whenTop);
      lNo++;
}

when3(Node *n) {
      fprintf(file,"w%d = %s;\n",wNo,n->variable);
}

when4() {
      fprintf(file,"L%d:\n",pop(whenStack,&whenTop));
}