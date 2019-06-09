%{
#include <iostream>
#include "SymbolTables.hpp"
#include "OutputGenerator.hpp"
#include "lex.yy.cpp"

#define Trace(t) if (Output_Parser) cout << "TRACE -> " << t << endl;

int Output_Parser = 1;
void yyerror(string s);

SymbolTableList stl;
vector<vector<idInfo>> procedures;
vector<string> idStack;

string filename;
ofstream out;

%}

/* yylval */
%union {
  string *s_Val;
  int i_Val;
  double r_Val;
  bool b_Val;
  int val_Type;
  idInfo* info;
}

/* tokens */
%token LE GE EQ NEQ AND OR
%token ARRAY ASSIGN BOOL BEGINT BREAK CHAR CASE CONST CONTINUE DO ELSE END EXIT FALSE FOR FN
%token IF IN INT LOOP MODULE OF PRINT PRINTLN PROCEDURE READ REAL REPEAT RETURN
%token STR RECORD THEN TRUE TYPE USE UTIL VAR WHILE
%token <s_Val> STR_CONST
%token <i_Val> INT_CONST
%token <r_Val> REAL_CONST
%token <b_Val> BOOL_CONST
%token <s_Val> ID

/* non-terminal type */
%type <val_Type> var_type opt_ret_type
%type <info> const_value expression proc_invocation

/* precedence */
%left OR
%left AND
%left '~'
%left '<' LE EQ GE '>' NEQ
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS

%%

/* program : Module */
                  program:
                  {
                    outProgramStart();
                  } 
                  MODULE ID 
                  {
                    Trace("module start");
                    idInfo *info = new idInfo();
                    info->prefix = module_Prefix;
                    info->valueInitialed = false;
                    stl.insert(*$3, *info); /* insert module */

                  }
                  opt_var_dec opt_proc_dec 
                  {
                    outMainStart();
                  }
                  BEGINT opt_statement END ID '.'
                  {
                    Trace("module end");
                    idInfo *info = stl.lookup(*$11);
                    if (info == NULL) yyerror("module id imcompatible"); /* no corresponding module id*/

                    stl.dump();

                    outVoidFuncEnd();

                    outProgramEnd();
                  }
                  ;

/* zero or more variable and constant declarations */
                  opt_var_dec: multi_const_dec opt_var_dec
                  | multi_var_dec opt_var_dec
                  | /* zero */
                  ;

/* one or more constant declarations*/
                  multi_const_dec: multi_const_dec const_dec 
                  | CONST const_dec /* one */
                  ;

/* constant declaration */
                  const_dec: ID '=' expression ';'
                  {
                    Trace("constant declaration");

                    if (!isConst(*$3)) yyerror("expression not constant value"); /* constant check */

                    $3->prefix = const_Prefix;
                    $3->valueInitialed = true;
                    if (stl.insert(*$1, *$3) == -1) yyerror("constant redefinition"); /* symbol check */
                  }
                  ;

/* one or more variable declarations*/
                  multi_var_dec: multi_var_dec var_dec
                  | VAR var_dec /* one */
                  ;

/* variable declaration */
                  var_dec: ids ':' var_type ';'
                  {
                    for(int i = 0 ; i < idStack.size() ; i++)
                    {
                      Trace("variable declaration");

                      idInfo *info = new idInfo();
                      info->prefix = variable_Prefix;
                      info->type = $3;
                      info->valueInitialed = false;
                      if (stl.insert(idStack[i], *info) == -1) yyerror("variable id redefinition"); /* symbol check */
                      
                      if ($3 == int_Type || $3 == bool_Type) {
                        int idx = stl.getIndex(idStack[i]);
                        if (idx == -1) {
                          outGlobalVar(idStack[i]);
                        }
                        else if (idx >= 0) {
                          outLocalVar(idx);
                        }
                      }
                    }
                    idStack.clear();
                  }
                  ;

/* Various ID declaration*/
                  ids: ID ',' ids
                  {
                    idStack.push_back(*$1);
                  }
                  | ID
                  {
                    idStack.push_back(*$1);
                  }
				  ;

/* variable type */
                  var_type: INT
                  {
                    $$ = int_Type;
                  }
                  | BOOL
                  {
                    $$ = bool_Type;
                  }
                  | STR
                  {
                    $$ = string_Type;
                  }
                  ;

/* none or multiple procedure declaration */
                  opt_proc_dec: proc_dec opt_proc_dec /* one or more */
                  | /* none */
                  ;

/* procedure declaration */
                  proc_dec: PROCEDURE ID
                  {
                    idInfo *info = new idInfo();
                    info->prefix = procedure_Prefix;
                    info->valueInitialed = false;
                    if (stl.insert(*$2, *info) == -1) yyerror("procedure id redefinition"); /* symbol check */

                    stl.push();
                  }
                    '(' opt_args ')' opt_ret_type 
                  {
                    outProcStart(*stl.lookup(*$2));
                  }
                  opt_var_dec BEGINT opt_statement END ID ';'
                  {
                    Trace("procedure end");
                    idInfo *info = stl.lookup(*$13);
                    if (info == NULL) yyerror("procedure name imcompatible");

                    outBlockEnd();

                    stl.dump();
                    stl.pop();
                  }
                  ;

/* zero or more arguments */
                  opt_args: args
                  | /* zero */
                  ;

/* arguments */
                  args: arg ',' args
                  | arg
                  ; 

/* argument */
                  arg: ID ':' var_type
                  {
                    idInfo *info = new idInfo();
                    info->prefix = variable_Prefix;
                    info->type = $3;
                    info->valueInitialed = false;
                    if (stl.insert(*$1, *info) == -1) yyerror("argument id redefinition");

                    stl.addFuncArg(*$1, *info);
                  }
                  ;

/* optional return type */
                  opt_ret_type: ':' var_type
                  {
                    stl.setFuncType($2);
                  }
                  | /* void */
                  {
                    stl.setFuncType(void_Type);
                  }
                  ;

/* one or more statements */
                  opt_statement: statement opt_statement
                  | statement /* one */
                  ;

/* statement */
                  statement: simple
                  | conditional
                  | loop
                  | proc_invocation
                  ;

/* simple */
                  simple: ID ASSIGN expression ';'
                  {
                    Trace("statement : variable assignment");

                    idInfo *info = stl.lookup(*$1);
                    if (info == NULL) yyerror("undeclared indentifier"); /* declaration check */
                    if (info->prefix == const_Prefix) yyerror("can't assign to constant"); /* constant check */
                    if (info->prefix == procedure_Prefix) yyerror("can't assign to procedure"); /* procedure check */
                    if (info->type != $3->type) yyerror("type not match"); /* type check */

                    if (info->type == int_Type || info->type == bool_Type) {
                      int idx = stl.getIndex(*$1);
                      if (idx == -1) 
                        outSetGlobalVar(*$1);
                      else 
                        outSetLocalVar(idx);
                    }
                  }
                  | 
                  {
                    outPrintStart();
                  }
                  PRINT expression ';'
                  {
                    Trace("statement : print expression");
                    if ($3->type == string_Type) 
                      outPrintStr();
                    else 
                      outPrintInt();
                  }
                  | 
                  {
                    outPrintStart();
                  }
                  PRINTLN expression ';'
                  {
                    Trace("statement : println expression");
                    if ($3->type == string_Type) 
                      outPrintlnStr();
                    else 
                      outPrintlnInt();
                  }
                  | RETURN expression ';'
                  {
                    Trace("statement : return expression");
                    outIReturn();
                  }
                  | RETURN ';'
                  {
                    Trace("statement : return");
                    outReturn();
                  }
                  | expression ';'
                  {
                    Trace("statement : expression");
                  }
                  ;

/* conditional */
                  conditional: IF '(' expression ')' ifStart THEN opt_statement ELSE 
                  {
                    outElse();
                  }
                   opt_statement END ';'
                  {
                    Trace("statement : if else");

                    if ($3->type != bool_Type) yyerror("condition type error");
                    outIfElseEnd();
                  }
                  | IF '(' expression ')' ifStart THEN opt_statement END ';'
                  {
                    Trace("statement : if");

                    if ($3->type != bool_Type) yyerror("condition type error");
                    outIfEnd();
                  }
                  ;

ifStart:
                  {
                    outIfStart();
                  }
                  ;              

/* loop */
                  loop: WHILE '(' 
                  {
                    outWhileStart();
                  }
                  expression 
                  {
                    outWhileCond();
                  }
                   ')' DO opt_statement END ';'
                  {
                    Trace("statement : while loop");

                    if ($4->type != bool_Type) yyerror("condition type error");

                    outWhileEnd();
                  }
                  ;

/* procedure invocation */
                  proc_invocation: ID
                  {
                    procedures.push_back(vector<idInfo>());
                  }
                    '(' opt_comma_separated ')'
                  {
                    Trace("statement : procedure invocation");

                    idInfo *info = stl.lookup(*$1);
                    if (info == NULL) yyerror("undeclared indentifier"); /* declaration check */
                    if (info->prefix != procedure_Prefix) yyerror("not a procedure"); /* procedure check */

                    vector<idInfo> para = info->value.proc_Val;
                    if (para.size() != procedures[procedures.size() - 1].size()) yyerror("parameter size not match"); /* parameter size check */

                    for (int i = 0; i < para.size(); i++) {
                      if (para[i].type != procedures[procedures.size() - 1].at(i).type) yyerror("parameter type not match"); /* parameter type check */
                    }

                    if(info->type == void_Type) yyerror("procedure return type is void"); /* return type check */

                    outCallFunc(*info);

                    $$ = info;
                    procedures.pop_back();
                  }
                  ;

/* optional comma-separated expressions */
                  opt_comma_separated: comma_separated
                  | /* zero */
                  ;

/* comma-separated expressions */
                  comma_separated: proc_expression ',' comma_separated
                  | proc_expression /* proc_expression */
                  ;

/* procedure expression */
                  proc_expression: expression
                  {
                    procedures[procedures.size() - 1].push_back(*$1);
                  }
                  ;

/* expression */
                  expression: ID
                  {
                    idInfo *info = stl.lookup(*$1);
                    if (info == NULL) yyerror("undeclared indentifier"); /* declaration check */
                    $$ = info;

                    if (!stl.isGlobal() && isConst(*info)) {
                      if (info->type == string_Type)
                       outConstStr(info->value.s_Val);
                      else if (info->type == int_Type || info->type == bool_Type) 
                       outConstInt(getValue(*info));
                    }
                    else if (info->type == int_Type || info->type == bool_Type) {
                      int idx = stl.getIndex(*$1);
                      if (idx == -1) 
                       outGetGlobalVar(*$1);
                      else 
                       outGetLocalVar(idx);
                    }
                  }
                  | const_value
                  {
                    if (!stl.isGlobal()) {
                      if ($1->type == string_Type) 
                        outConstStr($1->value.s_Val);
                      else if ($1->type == int_Type || $1->type == bool_Type) 
                        outConstInt(getValue(*$1));
                    }
                  }
                  | proc_invocation
                  | '-' expression %prec UMINUS
                  {
                    Trace("-expression");

                    if ($2->type != int_Type) yyerror("operator error"); /* operator check */

                    idInfo *info = new idInfo();
                    info->prefix = variable_Prefix;
                    info->type = $2->type;
                    $$ = info;

                    if ($2->type == int_Type) 
                      outOperator('m');
                  }
                  | expression '*' expression
                  {
                    Trace("expression * expression");

                    if ($1->type != $3->type) yyerror("type not match"); /* type check */
                    if ($1->type != int_Type) yyerror("operator error"); /* operator check */

                    idInfo *info = new idInfo();
                    info->prefix = variable_Prefix;
                    info->type = $1->type;
                    $$ = info;

                    if ($1->type == int_Type) 
                      outOperator('*');
                  }
                  | expression '/' expression
                  {
                    Trace("expression / expression");

                    if ($1->type != $3->type) yyerror("type not match"); /* type check */
                    if ($1->type != int_Type) yyerror("operator error"); /* operator check */

                    idInfo *info = new idInfo();
                    info->prefix = variable_Prefix;
                    info->type = $1->type;
                    $$ = info;

                    if ($1->type == int_Type) 
                      outOperator('/');
                  }
                  | expression '+' expression
                  {
                    Trace("expression + expression");

                    if ($1->type != $3->type) yyerror("type not match"); /* type check */
                    if ($1->type != int_Type && $1->type != string_Type) yyerror("operator error"); /* operator check */

                    idInfo *info = new idInfo();
                    info->prefix = variable_Prefix;
                    info->type = $1->type;
                    $$ = info;

                    if ($1->type == int_Type) 
                     outOperator('+');
                  }
                  | expression '-' expression
                  {
                    Trace("expression - expression");

                    if ($1->type != $3->type) yyerror("type not match"); /* type check */
                    if ($1->type != int_Type) yyerror("operator error"); /* operator check */

                    idInfo *info = new idInfo();
                    info->prefix = variable_Prefix;
                    info->type = $1->type;
                    $$ = info;

                    if ($1->type == int_Type)
                     outOperator('-');
                  }
                  | expression '<' expression
                  {
                    Trace("expression < expression");

                    if ($1->type != $3->type) yyerror("type not match"); /* type check */
                    if ($1->type != int_Type) yyerror("operator error"); /* operator check */

                    idInfo *info = new idInfo();
                    info->prefix = variable_Prefix;
                    info->type = bool_Type;
                    $$ = info;

                    if ($1->type == int_Type) 
                      outCondOp(IFLT);
                  }
                  | expression LE expression
                  {
                    Trace("expression <= expression");

                    if ($1->type != $3->type) yyerror("type not match"); /* type check */
                    if ($1->type != int_Type) yyerror("operator error"); /* operator check */

                    idInfo *info = new idInfo();
                    info->prefix = variable_Prefix;
                    info->type = bool_Type;
                    $$ = info;

                    if ($1->type == int_Type) 
                      outCondOp(IFLE);
                  }
                  | expression '=' expression
                  {
                    Trace("expression EQUAL expression");

                    if ($1->type != $3->type) yyerror("type not match"); /* type check */
                    if ($1->type != int_Type) yyerror("operator error"); /* operator check */

                    idInfo *info = new idInfo();
                    info->prefix = variable_Prefix;
                    info->type = bool_Type;
                    $$ = info;

                    if ($1->type == int_Type || $1->type == bool_Type) 
                      outCondOp(IFEQ);
                  }
                  | expression GE expression
                  {
                    Trace("expression >= expression");

                    if ($1->type != $3->type) yyerror("type not match"); /* type check */
                    if ($1->type != int_Type) yyerror("operator error"); /* operator check */

                    idInfo *info = new idInfo();
                    info->prefix = variable_Prefix;
                    info->type = bool_Type;
                    $$ = info;

                    if ($1->type == int_Type)
                     outCondOp(IFGE);
                  }
                  | expression '>' expression
                  {
                    Trace("expression > expression");

                    if ($1->type != $3->type) yyerror("type not match"); /* type check */
                    if ($1->type != int_Type) yyerror("operator error"); /* operator check */

                    idInfo *info = new idInfo();
                    info->prefix = variable_Prefix;
                    info->type = bool_Type;
                    $$ = info;

                    if ($1->type == int_Type)
                     outCondOp(IFGT);
                  }
                  | expression NEQ expression
                  {
                    Trace("expression <> expression");

                    if ($1->type != $3->type) yyerror("type not match"); /* type check */
                    if ($1->type != int_Type) yyerror("operator error"); /* operator check */

                    idInfo *info = new idInfo();
                    info->prefix = variable_Prefix;
                    info->type = bool_Type;
                    $$ = info;

                    if ($1->type == int_Type || $1->type == bool_Type) 
                      outCondOp(IFNE);
                  }
                  | expression AND expression
                  {
                    Trace("expression && expression");

                    if ($1->type != $3->type) yyerror("type not match"); /* type check */
                    if ($1->type != bool_Type) yyerror("operator error"); /* operator check */

                    idInfo *info = new idInfo();
                    info->prefix = variable_Prefix;
                    info->type = bool_Type;
                    $$ = info;

                    if ($1->type == bool_Type)
                     outOperator('&');
                  }
                  | expression OR expression
                  {
                    Trace("expression || expression");

                    if ($1->type != $3->type) yyerror("type not match"); /* type check */
                    if ($1->type != bool_Type) yyerror("operator error"); /* operator check */

                    idInfo *info = new idInfo();
                    info->prefix = variable_Prefix;
                    info->type = bool_Type;
                    $$ = info;

                    if ($1->type == bool_Type)
                     outOperator('|');
                  }
                  | '~' expression
                  {
                    Trace("~expression");

                    if ($2->type != bool_Type) yyerror("operator error"); /* operator check */

                    idInfo *info = new idInfo();
                    info->prefix = variable_Prefix;
                    info->type = bool_Type;
                    $$ = info;

                    if ($2->type == bool_Type) 
                      outOperator('!');
                  }
                  | '(' expression ')'
                  {
                    Trace("(expression)");
                    $$ = $2;
                  }
                  ;

/* numeric value */
                  const_value: 
                    INT_CONST
                  {
                    $$ = setConst_i($1);
                  }
                  | BOOL_CONST
                  {
                    $$ = setConst_b($1);
                  }
                  | STR_CONST
                  {
                    $$ = setConst_s($1);
                  }
                  ;

%%

void yyerror(string s) {
  cerr << "line " << linenum << ": " << s << endl;
  exit(1);
}

int main(int argc, char **argv) {
  yyin = fopen(argv[1], "r");
  string source = string(argv[1]);
  int dot = source.find(".");
  filename = source.substr(0, dot);
  out.open(filename + ".jasm");

  yyparse();
  return 0;
}
