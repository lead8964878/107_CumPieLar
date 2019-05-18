%{
#include <iostream>
#include "SymbolTables.hpp"
#include "lex.yy.cpp"

#define Trace(t) if (Output_Parser) cout << "TRACE -> " << t << endl;

int Output_Parser = 1;
void yyerror(string s);

SymbolTableList stl;
vector<vector<idInfo>> procedures;
vector<string> idStack;

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
%token IF IN INT LOOP MODULE OF PRINT PRINTLN PROCEDURE REPEAT RETURN READ REAL
%token STR RECORD THEN TRUE TYPE USE UTIL VAR WHILE
%token <s_Val> STR_CONST
%token <i_Val> INT_CONST
%token <r_Val> REAL_CONST
%token <b_Val> BOOL_CONST
%token <s_Val> ID

/* type for non-terminal */
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
                  program: MODULE ID 
                  {
                    Trace("module start");
                    idInfo *info = new idInfo();
                    info->flag = module_Flag;
                    info->valueInitialed = false;
                    stl.insert(*$2, *info); /* insert module */

                  }
                    opt_var_dec opt_proc_dec BEGINT opt_statement END ID '.'
                  {
                    Trace("module end");
                    idInfo *info = stl.lookup(*$9);
                    if (info == NULL) yyerror("module id imcompatible");

                    stl.dump();
                  }
                  ;

/* zero or more variable and constant declarations */
                  opt_var_dec: CONST multi_const_dec opt_var_dec
                  | VAR multi_var_dec opt_var_dec
                  | array_dec opt_var_dec
                  | /* zero */
                  ;

/* one or more constant declarations*/
                  multi_const_dec: const_dec multi_const_dec
                  | const_dec /* one */
                  ;

/* constant declaration */
                  const_dec: ID '=' expression ';'
                  {
                    Trace("constant declaration");

                    if (!isConst(*$3)) yyerror("expression not constant value"); /* constant check */

                    $3->flag = const_Flag;
                    $3->valueInitialed = true;
                    if (stl.insert(*$1, *$3) == -1) yyerror("constant redefinition"); /* symbol check */
                  }
                  ;

/* one or more variable declarations*/
                  multi_var_dec: var_dec multi_var_dec
                  | var_dec /* one */
                  ;

/* variable declaration */
                  var_dec: IDS ':' var_type ';'
                  {
                    for(int i = 0 ; i < idStack.size() ; i++)
                    {
                      Trace("variable declaration");

                      idInfo *info = new idInfo();
                      info->flag = variable_Flag;
                      info->type = $3;
                      info->valueInitialed = false;
                      if (stl.insert(idStack[i], *info) == -1) yyerror("variable id redefinition"); /* symbol check */
                    }
                    idStack.clear();
                  }
                  ;

/* array declaration */
                  array_dec: IDS ':' ARRAY '[' expression ',' expression ']' OF var_type ';' 
                  {
                    for(int i = 0 ; i < idStack.size() ; i++)
                    {
                      Trace("array declaration");

                      if (!isConst(*$5) || !isConst(*$7)) yyerror("array size not constant");
                      if ($5->type != int_Type || $7->type != int_Type) yyerror("array size not integer");
                      if ($5->value.i_Val < 0 || $7->value.i_Val < 0) yyerror("array index < 0");
                      if ($7->value.i_Val - $5->value.i_Val < 0) yyerror("array size < 0");
                      if (stl.insert(idStack[i], $10, $5->value.i_Val , $7->value.i_Val) == -1) yyerror("array id redefinition");
                    }
                    idStack.clear();
                  }
                  ;

/* Various ID declaration*/
                  IDS: ID ',' IDS
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
                  | REAL
                  {
                    $$ = real_Type;
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
                    info->flag = procedure_Flag;
                    info->valueInitialed = false;
                    if (stl.insert(*$2, *info) == -1) yyerror("procedure id redefinition"); /* symbol check */

                    stl.push();
                  }
                    '(' opt_args ')' opt_ret_type opt_var_dec BEGINT opt_statement END ID ';'
                  {
                    Trace("procedure end");
                    idInfo *info = stl.lookup(*$12);
                    if (info == NULL) yyerror("procedure name imcompatible");

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
                    info->flag = variable_Flag;
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
                    if (info->flag == const_Flag) yyerror("can't assign to constant"); /* constant check */
                    if (info->flag == procedure_Flag) yyerror("can't assign to procedure"); /* procedure check */
                    if (info->type != $3->type) yyerror("type not match"); /* type check */
                  }
                  | ID '[' expression ']' ASSIGN expression ';'
                  {
                    Trace("statement : array assignment");

                    idInfo *info = stl.lookup(*$1);
                    if (info == NULL) yyerror("undeclared indentifier"); /* declaration check */
                    if (info->flag != variable_Flag) yyerror("not a variable"); /* variable check */
                    if (info->type != array_Type) yyerror("variable not an array"); /* type check */
                    if ($3->type != int_Type) yyerror("index not integer"); /* index type check */
                    if ($3->value.i_Val > info->value.arrayEnd_Index || $3->value.i_Val < info->value.arrayStart_Index) yyerror("index out of range");
                     /* index range check */
                    if (info->value.array_Val[0].type != $6->type) yyerror("type not match"); /* type check */
                  }
                  | PRINT expression ';'
                  {
                    Trace("statement : print expression");
                  }
                  | PRINTLN expression ';'
                  {
                    Trace("statement : println expression");
                  }
                  | RETURN expression ';'
                  {
                    Trace("statement : return expression");
                  }
                  | RETURN ';'
                  {
                    Trace("statement : return");
                  }
                  | READ ID ';'
                  {
                    Trace("statement : read identifier");
                  }
                  | expression ';'
                  {
                    Trace("statement : expression");
                  }
                  ;

/* conditional */
                  conditional: IF '(' expression ')' THEN opt_statement ELSE opt_statement END ';'
                  {
                    Trace("statement : if else");

                    if ($3->type != bool_Type) yyerror("condition type error");
                  }
                  | IF '(' expression ')' THEN opt_statement END ';'
                  {
                    Trace("statement : if");

                    if ($3->type != bool_Type) yyerror("condition type error");
                  }
                  ;

/* loop */
                  loop: WHILE '(' expression ')' DO opt_statement END
                  {
                    Trace("statement : while loop");

                    if ($3->type != bool_Type) yyerror("condition type error");
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
                    if (info->flag != procedure_Flag) yyerror("not a procedure"); /* procedure check */


                    vector<idInfo> para = info->value.proc_Val;
                    if (para.size() != procedures[procedures.size() - 1].size()) yyerror("parameter size not match"); /* parameter size check */

                    for (int i = 0; i < para.size(); i++) {
                      if (para[i].type != procedures[procedures.size() - 1].at(i).type) yyerror("parameter type not match"); /* parameter type check */
                    }

                    if(info->type == void_Type) yyerror("procedure return type is void"); /* return type check */

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

/* constant value */
                  const_value: 
                    INT_CONST
                  {
                    $$ = setConst_i($1);
                  }
                  | REAL_CONST
                  {
                    $$ = setConst_r($1);
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

/* expression */
                  expression: ID
                  {
                    idInfo *info = stl.lookup(*$1);
                    if (info == NULL) yyerror("undeclared indentifier"); /* declaration check */
                    $$ = info;
                  }
                  | const_value
                  | ID '[' expression ']'
                  {
                    idInfo *info = stl.lookup(*$1);
                    if (info == NULL) yyerror("undeclared identifier");
                    if (info->type != array_Type) yyerror("not array type");
                    if ($3->type != int_Type) yyerror("invalid index");
                    if ($3->value.i_Val > info->value.arrayEnd_Index || $3->value.i_Val < info->value.arrayStart_Index) yyerror("index out of range");
                    $$ = new idInfo(info->value.array_Val[$3->value.i_Val]);
                  }
                  | proc_invocation
                  | '-' expression %prec UMINUS
                  {
                    Trace("-expression");

                    if ($2->type != int_Type && $2->type != real_Type) yyerror("operator error"); /* operator check */

                    idInfo *info = new idInfo();
                    info->flag = variable_Flag;
                    info->type = $2->type;
                    $$ = info;
                  }
                  | expression '*' expression
                  {
                    Trace("expression * expression");

                    if ($1->type != $3->type) yyerror("type not match"); /* type check */
                    if ($1->type != int_Type && $1->type != real_Type) yyerror("operator error"); /* operator check */

                    idInfo *info = new idInfo();
                    info->flag = variable_Flag;
                    info->type = $1->type;
                    $$ = info;
                  }
                  | expression '/' expression
                  {
                    Trace("expression / expression");

                    if ($1->type != $3->type) yyerror("type not match"); /* type check */
                    if ($1->type != int_Type && $1->type != real_Type) yyerror("operator error"); /* operator check */

                    idInfo *info = new idInfo();
                    info->flag = variable_Flag;
                    info->type = $1->type;
                    $$ = info;
                  }
                  | expression '+' expression
                  {
                    Trace("expression + expression");

                    if ($1->type != $3->type) yyerror("type not match"); /* type check */
                    if ($1->type != int_Type && $1->type != real_Type && $1->type != string_Type) yyerror("operator error"); /* operator check */

                    idInfo *info = new idInfo();
                    info->flag = variable_Flag;
                    info->type = $1->type;
                    $$ = info;
                  }
                  | expression '-' expression
                  {
                    Trace("expression - expression");

                    if ($1->type != $3->type) yyerror("type not match"); /* type check */
                    if ($1->type != int_Type && $1->type != real_Type) yyerror("operator error"); /* operator check */

                    idInfo *info = new idInfo();
                    info->flag = variable_Flag;
                    info->type = $1->type;
                    $$ = info;
                  }
                  | expression '<' expression
                  {
                    Trace("expression < expression");

                    if ($1->type != $3->type) yyerror("type not match"); /* type check */
                    if ($1->type != int_Type && $1->type != real_Type) yyerror("operator error"); /* operator check */

                    idInfo *info = new idInfo();
                    info->flag = variable_Flag;
                    info->type = bool_Type;
                    $$ = info;
                  }
                  | expression LE expression
                  {
                    Trace("expression <= expression");

                    if ($1->type != $3->type) yyerror("type not match"); /* type check */
                    if ($1->type != int_Type && $1->type != real_Type) yyerror("operator error"); /* operator check */

                    idInfo *info = new idInfo();
                    info->flag = variable_Flag;
                    info->type = bool_Type;
                    $$ = info;
                  }
                  | expression '=' expression
                  {
                    Trace("expression EQUAL expression");

                    if ($1->type != $3->type) yyerror("type not match"); /* type check */
                    if ($1->type != int_Type && $1->type != real_Type) yyerror("operator error"); /* operator check */

                    idInfo *info = new idInfo();
                    info->flag = variable_Flag;
                    info->type = bool_Type;
                    $$ = info;
                  }
                  | expression GE expression
                  {
                    Trace("expression >= expression");

                    if ($1->type != $3->type) yyerror("type not match"); /* type check */
                    if ($1->type != int_Type && $1->type != real_Type) yyerror("operator error"); /* operator check */

                    idInfo *info = new idInfo();
                    info->flag = variable_Flag;
                    info->type = bool_Type;
                    $$ = info;
                  }
                  | expression '>' expression
                  {
                    Trace("expression > expression");

                    if ($1->type != $3->type) yyerror("type not match"); /* type check */
                    if ($1->type != int_Type && $1->type != real_Type) yyerror("operator error"); /* operator check */

                    idInfo *info = new idInfo();
                    info->flag = variable_Flag;
                    info->type = bool_Type;
                    $$ = info;
                  }
                  | expression NEQ expression
                  {
                    Trace("expression <> expression");

                    if ($1->type != $3->type) yyerror("type not match"); /* type check */
                    if ($1->type != int_Type && $1->type != real_Type) yyerror("operator error"); /* operator check */

                    idInfo *info = new idInfo();
                    info->flag = variable_Flag;
                    info->type = bool_Type;
                    $$ = info;
                  }
                  | expression AND expression
                  {
                    Trace("expression && expression");

                    if ($1->type != $3->type) yyerror("type not match"); /* type check */
                    if ($1->type != bool_Type) yyerror("operator error"); /* operator check */

                    idInfo *info = new idInfo();
                    info->flag = variable_Flag;
                    info->type = bool_Type;
                    $$ = info;
                  }
                  | expression OR expression
                  {
                    Trace("expression || expression");

                    if ($1->type != $3->type) yyerror("type not match"); /* type check */
                    if ($1->type != bool_Type) yyerror("operator error"); /* operator check */

                    idInfo *info = new idInfo();
                    info->flag = variable_Flag;
                    info->type = bool_Type;
                    $$ = info;
                  }
                  | '~' expression
                  {
                    Trace("~expression");

                    if ($2->type != bool_Type) yyerror("operator error"); /* operator check */

                    idInfo *info = new idInfo();
                    info->flag = variable_Flag;
                    info->type = bool_Type;
                    $$ = info;
                  }
                  | '(' expression ')'
                  {
                    Trace("(expression)");
                    $$ = $2;
                  }
                  ;

%%

void yyerror(string s) {
  cerr << "line " << linenum << ": " << s << endl;
  exit(1);
}

int main(void) {
  yyparse();
  return 0;
}
