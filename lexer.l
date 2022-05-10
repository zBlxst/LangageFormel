%option noyywrap
%option yylineno

%x COMMENT
%x COMMENT2

DIG	[0-9]

%%

"var"	{ return VAR; }

"proc"	{ return PROC; }
"end"	{ return END; }

"reach" { return REACH; }
"break" { return BREAK; }
"skip"  { return SKIP; }

"//" { BEGIN(COMMENT); }
"/*" { BEGIN(COMMENT2); }

"do"	{ return DO; }
"od"	{ return OD; }

"if"	{ return IF; }
"fi"	{ return FI; }

"::"	{ return CASE; }
"else"	{ return ELSE; }
"->"	{ return THEN; }

":="	{ return ASSIGN; }

"=="	{ return EQ; }
"||"	{ return OR; }
"&&"	{ return AND; }
"!"	{ return NOT; }

"+"	{ return PLUS; }
"*"	{ return TIME; }
"-"	{ return MINUS; }
"/"	{ return DIV; }

"<"	{ return LT; }
"<="	{ return LE; }
">"	{ return GT; }
">="	{ return GE; }

<COMMENT>. { }
<COMMENT>\n { BEGIN(INITIAL); }
<COMMENT2>. { }
<COMMENT2>\n { }
<COMMENT2>"*/" { BEGIN(INITIAL); }

{DIG}+	{ yylval.n = atoi(yytext); return INT; }

[a-z_][a-z0-9_]* { yylval.s = strdup(yytext); return IDENT; }

[	 \n]   { /* ignore */ }

.	{ return *yytext; }

%%

