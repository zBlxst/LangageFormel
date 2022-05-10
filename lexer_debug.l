%option noyywrap

DIG	[0-9]

%%

"var"	{ printf("VAR\n"); }

"proc"	{ printf("PROC\n"); }
"end"	{ printf("END\n"); }

"reach" { printf("REACH\n"); }
"break" { printf("BREAK\n"); }
"skip"  { printf("SKIP\n"); }

"do"	{ printf("DO\n"); }
"od"	{ printf("OD\n"); }

"if"	{ printf("IF\n"); }
"fi"	{ printf("FI\n"); }

"::"	{ printf("CASE\n"); }
"else"	{ printf("ELSE\n"); }
"->"	{ printf("THEN\n"); }

":="	{ printf("ASSIGN\n"); }

"=="	{ printf("EQ\n"); }
"||"	{ printf("OR\n"); }
"&&"	{ printf("AND\n"); }
"!"	{ printf("NOT\n"); }

"+"	{ printf("PLUS\n"); }
"*"	{ printf("TIME\n"); }
"-"	{ printf("MINUS\n"); }
"/"	{ printf("DIV\n"); }

"<"	{ printf("LT\n"); }
"<="	{ printf("LE\n"); }
">"	{ printf("GT\n"); }
">="	{ printf("GE\n"); }

{DIG}+	{ printf("INT\n"); }

[a-z_][a-z0-9_]* { printf("IDENT\n"); }

";" { }
"," { }
"(" { }
")" { }

"//"[a-zA-Z0-9 ]*"\n" { }

[	 \n]   { /* ignore */ }

.	{ printf("*yytext\n"); }

%%

int main (int argc, char **argv)
{
	if (argc > 1) yyin = fopen(argv[1], "r ");
	yylex();
	puts(" ");
}
