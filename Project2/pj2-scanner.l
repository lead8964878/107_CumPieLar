%{
#include "y.tab.hpp"

using namespace std;

#define LIST     strcat(buf,yytext)
#define token(t) {LIST; printf("<%s>\n",#t);}
#define tokenChar(t) { LIST; printf("<'%c'>\n", t); }
#define tokenInteger(t,i) {LIST; printf("<%s:%d>\n",#t,i);}
#define tokenString(t,s) {LIST; printf("<%s:%s>\n",#t,s);}

#define MAX_LINE_LENG 256

int linenum = 1;
char buf[MAX_LINE_LENG];

class SymbolTable{
private:
	vector<string> symbolList;
	map<string,int> symbolMap;
	int index;
public:
	SymbolTable();
	int lookup(string s);
	int insert(string s);
	void dump();
};

SymbolTable *st;

%}

DELIMITERS      ([,:.()\[\]{};])
ARITHMETIC      ([-+*/])
LOGICAL         ([~])
RELATIONAL      ([<>=])
IDENTIFIER      ([A-Za-z_][0-9A-Za-z_]*)
DIGITS          ([0-9]+)
INTEGER         ([+-]?{DIGITS})
REAL            ([-+]?{DIGITS}\.{DIGITS}?([Ee](-+)?{DIGITS})?)
STRING          (\"(\"\"|[^"\n])*\")

%x COMMENT

%%

{DELIMITERS}|{ARITHMETIC}|{RELATIONAL}|{LOGICAL}	{ tokenChar(yytext[0]); return yytext[0]; }

"array"         { token(ARRAY); return ARRAY;}
"boolean"       { token(BOOL); return BOOL;}
"begin"         { token(BEGIN); return BEGIN;}
"break"         { token(BREAK); return BREAK;}
"char"          { token(CHAR); return CHAR;}
"case"          { token(CASE); return CASE;}
"const"         { token(CONST); return CONST;}
"continue"      { token(CONTINUE); return CONTINUE;}
"do"            { token(DO); return DO;}
"else"          { token(ELSE); return ELSE;}
"end"           { token(END); return END;}
"exit"          { token(EXIT); return EXIT;}
"for"           { token(FOR); return FOR;}
"fn"            { token(FN); return FN;}
"if"            { token(IF); return IF;}
"in"            { token(IN); return IN;}
"integer"       { token(INT); return INT;}
"loop"          { token(LOOP); return LOOP;}
"module"        { token(MODULE); return MODULE;}
"of"            { token(OF); return OF;}
"print"         { token(PRINT); return PRINT;}
"println"       { token(PRINTLN); return PRINTLN;}
"procedure"     { token(PROCEDURE); return PROCEDURE;}
"repeat"        { token(REPEAT); return REPEAT;}
"return"        { token(RETURN); return RETURN;}
"read"			{ token(READ); return READ;}
"real"          { token(REAL); return REAL;}
"string"        { token(STR); return STR;}
"record"        { token(RECORD); return RECORD;}
"then"          { token(THEN); return THEN;}
"type"          { token(TYPE); return TYPE;}
"use"           { token(USE); return USE;}
"util"          { token(UTIL); return UTIL;}
"var"           { token(VAR); return VAR;}
"while"         { token(WHILE); return WHILE;}

"false"         { token(FALSE);
					yylval.bval = false;
					return BOOL_CONST;
				}
"true"          { token(TRUE);
					yylval.bval = true;
					return BOOL_CONST;
				}

"<="            { token('<='); return LE;}
">="            { token('>='); return GE}
"<>"            { token('<>'); return NEQ;}
"&&"            { token('&&'); return AND;}
"||"            { token('||'); return OR;}
":="        	{ token(':='); return ASSIGN;}

{IDENTIFIER} {
	tokenString(id, yytext);
	yylval.s_Val = new string(yytext);
	return ID;
}

{INTEGER} {
	tokenInteger(INTEGER, atoi(yytext));
	yylval.i_Val = atoi(yytext);
	return INT_CONST;
}

{REAL} {
	tokenString(REAL, yytext);
	yylval.r_Val = atof(yytext);
	return REAL_CONST;
}

{STRING} {
	char str[MAX_LINE_LENG] = {0};
	int index = 0;
	for (int i = 0; i < yyleng; i++) {
		if(yytext[i] == '"') i++;
		str[index] = yytext[i];
		index++;
	}
	tokenString(STRING, str);
	yylval.s_Val = new string(str);
	return STR_CONST;
}

"//"[^\n]* {LIST;}

"(*" {
	LIST;
	BEGIN COMMENT;
}

<COMMENT>. {
	LIST;
}

<COMMENT>\n {
	LIST;
	printf("%d: %s", linenum, buf);
	linenum++;
	buf[0] = '\0';
}

<COMMENT>"*)" {
	LIST;
	BEGIN INITIAL;
}

"*)" {LIST;}



\n {
	LIST;
	printf("%d: %s", linenum++, buf);
	buf[0] = '\0';
}

[ \t]* {LIST;}

. {
	LIST;
	printf("%d:%s\n", linenum + 1, buf);
	printf("invalid character:'%s'\n",yytext);
	exit(-1);
}
%%