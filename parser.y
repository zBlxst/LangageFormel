%locations

%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex();

void yyerror();
/***************************************************************************/
/* Data structures for storing a programme.                                */

typedef struct var // une list de variable est composée d'un nom, d'une valeur et de la variable suivante
{
	char *name;
	int value;
} var;

typedef struct varlist
{
	struct var *v;
	struct varlist *next;
} varlist;

typedef struct aexpr // expression de type entier
{
	int type; // IDENT, PLUS, MINUS, TIME, DIV, INT
	int val;
	char *name;
	struct aexpr *left;
	struct aexpr *right;
} aexpr;

typedef struct compare // comparaison d'entier
{
	int type; // LE, LT, GE, GT, EQ
	struct aexpr *left;
	struct aexpr *right;
} compare;

typedef struct bexpr // expression de type booléen
{
	int type; // 0 (AEXPR), NOT, AND, OR, COMPARE
	struct aexpr *val;
	struct bexpr *left;
	struct bexpr *right;
	struct compare *cmp;
} bexpr;

typedef struct qase // un case est composé d'une condition et d'un effet sous la forme d'une suite de commande
{
	struct bexpr *cond;
	struct cmdlist *effet;
} qase;

typedef struct caselist
{
	struct qase *qase;
	struct caselist *next;
} caselist;

typedef struct cmd // une commande peut avoir plusieurs formes donc certains champs seront NULL
{
	int type; // ASSIGN, DO, IF, COMM
	char *name;
	struct aexpr *val;
	struct caselist *cases;
} cmd;

typedef struct cmdlist
{
	struct cmd *cmd;
	struct cmdlist *next;
} cmdlist;

typedef struct spelist // la liste des spécifications est une suite de bexpr
{
	struct bexpr *cond;
	struct spelist *next;
} spelist;

typedef struct proc // un processus est défini par son nom, ses variables locales et ses instructions
{
	char *name;
	struct varlist *loc;
	struct cmdlist *core;
} proc;

typedef struct proclist
{
	struct proc *p;
	struct proclist *next;
} proclist;

typedef struct prgm // un programme est composé des variables globales, des processus et des spécifications
{
	struct varlist *glob;
	struct proclist *core;
	struct spelist *spe;
} prgm;

/****************************************************************************/
/* All data pertaining to the programme are accessible from these two vars. */

prgm *program;

/****************************************************************************/
/* Functions for settting up data structures at parse time.                 */

var* make_var (char *name)
{
	var *v = malloc(sizeof(var));
	v->name = name;
	v->value = 0; // On initialise toutes les varibales à 0
	return v;
}

varlist* make_varlist (var *v, varlist *next)
{
	varlist *vl = malloc(sizeof(varlist));
	vl->v = v;
	vl->next = next;
	return vl;
}

varlist* concat_varlist (varlist *l1, varlist *l2)
{
	varlist *vl;
	vl = l1->next;
	while (vl != NULL) vl = vl->next;
	vl = l2;
	return l1;
}

compare* make_compare (int type, aexpr *left, aexpr *right)
{
	compare *c = malloc(sizeof(compare));
	c->type = type;
	c->left = left;
	c->right = right;
	return c;
}

bexpr* make_bexpr (int type, aexpr *a, bexpr *left, bexpr *right, compare *c)
{
	bexpr *b = malloc(sizeof(bexpr));
	b->type = type;
	b->val = a;
	b->left = left;
	b->right = right;
	b->cmp = c;
	return b;
}

aexpr* make_aexpr (int type, int val, char *name, aexpr *left, aexpr *right)
{
	aexpr *a = malloc(sizeof(aexpr));
	a->type = type;
	a->val = val;
	a->name = name;
	a->left = left;
	a->right = right;
	return a;
}
	

qase* make_case (bexpr *b, cmdlist *c)
{
	qase *q = malloc(sizeof(qase));
	q->cond = b;
	q->effet = c;
	return q;
}

caselist* make_caselist (qase *q, caselist *next)
{
	caselist *ql = malloc(sizeof(caselist));
	ql->qase = q;
	ql->next = next;
	return ql;
}

cmd* make_cmd (int type, char *name, aexpr *val, caselist *cl)
{
	cmd *c = malloc(sizeof(cmd));
	c->type = type;
	c->name = name;
	c->val = val;
	c->cases = cl;
	return c;
}

cmdlist* make_cmdlist (cmd *c, cmdlist *next)
{
	cmdlist *cl = malloc(sizeof(cmdlist));
	cl->cmd = c;
	cl->next = next;
	return cl;
}

proc* make_proc (char *name, varlist *vl, cmdlist *cl)
{
	proc *p = malloc(sizeof(proc));
	p->name = name;
	p->loc = vl;
	p->core = cl;
	return p;
}

proclist* make_proclist (proc *proc, proclist *next)
{
	proclist *pl = malloc(sizeof(proclist));
	pl->p = proc;
	pl->next = next;
	return pl;
}

spelist* make_spelist (bexpr *b, spelist *next)
{
	spelist *spe = malloc(sizeof(spelist));
	spe->cond = b;
	spe->next = next;
	return spe;
}

prgm* make_prgm (varlist *glob, proclist *core, spelist *spe)
{
	prgm *p = malloc(sizeof(prgm));
	p->glob = glob;
	p->core = core;
	p->spe = spe;
	return p;
}

%}

/****************************************************************************/

/* types used by terminals and non-terminals */
%error-verbose

%union {
	char *s;
	int n;
	var *v;
	varlist *l;
	aexpr *a;
	bexpr *b;
	compare *cmp;
	qase *q;
	caselist *ql;
	spelist *sl;
	cmd *c;
	cmdlist *cl;
	proc *p;
	proclist *pl;
}

%type <l> glob declist
%type <pl> proclist
%type <p> proc
%type <cl> cmdlist
%type <c> cmd
%type <ql> caselist
%type <q> qase
%type <a> aexpr
%type <b> bexpr
%type <cmp> compare
%type <sl> spelist

%token VAR PROC END REACH DO OD IF FI CASE THEN ELSE ASSIGN EQ OR AND NOT PLUS MINUS TIME DIV LT LE GT GE COMM COMPARE BREAK SKIP
%token <n> INT
%token <s> IDENT

%left ';'
%left ','

%left OR AND PLUS MINUS TIME
%right NOT DIV

%%

prgm : glob proclist spelist { program = make_prgm($1, $2, $3); }

glob : { $$ = NULL; }
	| VAR declist ';' glob { $$ = concat_varlist($2, $4); }

declist : IDENT { $$ = make_varlist(make_var($1), NULL); }
	| IDENT ',' declist { $$ = make_varlist(make_var($1), $3); }

proclist : proc { $$ = make_proclist($1, NULL); }
	| proc proclist { $$ = make_proclist($1, $2); }

proc : PROC IDENT glob cmdlist END { $$ = make_proc($2, $3, $4); }

cmdlist : { $$ = NULL; }
	| cmd { $$ = make_cmdlist($1, NULL); }
	| cmd ';' cmdlist { $$ = make_cmdlist($1,$3); }

cmd : IDENT ASSIGN aexpr { $$ = make_cmd(ASSIGN, $1, $3, NULL); }
	| DO caselist OD { $$ = make_cmd(DO, NULL, NULL, $2); }
	| IF caselist FI { $$ = make_cmd(IF, NULL, NULL, $2); }
	| BREAK { $$ = make_cmd(BREAK, NULL, NULL, NULL); }
	| SKIP { $$ = make_cmd(SKIP, NULL, NULL, NULL); }

caselist : { $$ = NULL; }
	| qase caselist { $$ = make_caselist($1, $2); }

qase : CASE bexpr THEN cmdlist { $$ = make_case($2, $4); }
	| CASE ELSE THEN cmdlist { $$ = make_case(NULL, $4); }

aexpr : IDENT { $$ = make_aexpr(IDENT, 0, $1, NULL, NULL); } 
	| aexpr PLUS aexpr { $$ = make_aexpr(PLUS, 0, NULL, $1, $3); }
	| aexpr MINUS aexpr { $$ = make_aexpr(MINUS, 0, NULL, $1, $3); }
	| aexpr TIME aexpr { $$ = make_aexpr(TIME, 0, NULL, $1, $3); }
	| aexpr DIV aexpr { $$ = make_aexpr(DIV, 0, NULL, $1, $3); }
	| INT { $$ = make_aexpr(INT, $1, NULL, NULL, NULL); }
	| '(' aexpr ')' { $$ = $2; }

bexpr : aexpr { $$ = make_bexpr(0, $1, NULL, NULL, NULL); }
	| NOT bexpr { $$ = make_bexpr(NOT, NULL, $2, NULL, NULL); }
	| bexpr AND bexpr { $$ = make_bexpr(AND, NULL, $1, $3, NULL); }
	| bexpr OR bexpr { $$ = make_bexpr(OR, NULL, $1, $3, NULL); }
	| compare { $$ = make_bexpr(COMPARE, NULL, NULL, NULL, $1); }
	| '(' bexpr ')' { $$ = $2; }

compare : aexpr EQ aexpr { $$ = make_compare(EQ, $1, $3); }
	| aexpr LE aexpr { $$ = make_compare(LE, $1, $3); }
	| aexpr LT aexpr { $$ = make_compare(LT, $1, $3); }
	| aexpr GE aexpr { $$ = make_compare(GE, $1, $3); }
	| aexpr GT aexpr { $$ = make_compare(GT, $1, $3); }

spelist : { $$ = NULL; }
	| REACH bexpr spelist { $$ = make_spelist($2, $3); }

%%

#include "lexer.c"

void yyerror(char *s)
{
	fflush(stdout);
	fprintf(stderr, "Erreur ligne %d %s\n", yylineno, s);
}

/****************************************************************************/
/* programme interpreter      :                                             */

void print_varlist (varlist *vl, int i)
{
	if (vl != NULL) {
		for (int j=0; j < i; j++) {
			printf(" ");
		}
		printf("var ");
		printf("%s;\n", vl->v->name);
		if (vl->next != NULL) {
			print_varlist(vl->next, i);
		}
		
	}
}

void print_aexpr (aexpr *a)
{
	if (a != NULL) {
		switch (a->type) {
			case IDENT : printf("%s", a->name); break;
			case INT : printf("%d", a->val); break;
			case PLUS : printf("("); print_aexpr(a->left); printf(" + "); print_aexpr(a->right); printf(")"); break;
			case MINUS : printf("("); print_aexpr(a->left); printf(" - "); print_aexpr(a->right); printf(")"); break;
			case TIME : printf("("); print_aexpr(a->left); printf(" * "); print_aexpr(a->right); printf(")"); break;
			case DIV : printf("("); print_aexpr(a->left); printf(" / "); print_aexpr(a->right); printf(")"); break;
		}
	}
}

void print_compare (compare *cmp)
{
	if (cmp != NULL) {
		switch (cmp->type) {
			case EQ : printf("("); print_aexpr(cmp->left); printf(" == "); print_aexpr(cmp->right); printf(")"); break;
			case LE : printf("("); print_aexpr(cmp->left); printf(" <= "); print_aexpr(cmp->right); printf(")"); break;
			case LT : printf("("); print_aexpr(cmp->left); printf(" < "); print_aexpr(cmp->right); printf(")"); break;
			case GE : printf("("); print_aexpr(cmp->left); printf(" >= "); print_aexpr(cmp->right); printf(")"); break;
			case GT : printf("("); print_aexpr(cmp->left); printf(" > "); print_aexpr(cmp->right); printf(")"); break;
		}
	}
}

void print_bexpr (bexpr *b)
{
	if (b != NULL) {
		switch (b->type) {
			case 0 : print_aexpr(b->val); break;
			case NOT : printf("!"); print_bexpr(b->left); break;
			case AND : printf("("); print_bexpr(b->left); printf(" && "); print_bexpr(b->right); printf(")"); break;
			case OR : printf("("); print_bexpr(b->left); printf(" || "); print_bexpr(b->right); printf(")"); break;
			case COMPARE : print_compare(b->cmp); break;
		}
	}
}

void print_cmdlist (cmdlist *cl, int i);

void print_qase (qase *q, int i)
{
	if (q != NULL) {
		for (int j=0; j < i; j++) {
			printf(" ");
		}
		printf(":: ");
		if (q->cond == NULL) {
			printf("else ");
		}
		print_bexpr(q->cond);
		printf(" -> \n");
		print_cmdlist(q->effet, i+5);
	}
}	

void print_caselist (caselist *cl, int i)
{
	if (cl != NULL) {
		print_qase(cl->qase, i);
		print_caselist(cl->next, i);
	}
}

void print_cmd (cmd *c, int i, int b)
{
	if (c != NULL) {
		for (int j=0; j < i; j++) {
			printf(" ");
		}
		switch (c->type) {
			case ASSIGN : printf("%s := ", c->name); print_aexpr(c->val); break;
			case DO : printf("do \n"); print_caselist(c->cases, i+5); for (int j=0; j < i; j++) {printf(" ");}printf("od"); break;
			case IF : printf("if \n"); print_caselist(c->cases, i+5); for (int j=0; j < i; j++) {printf(" ");}printf("fi"); break;
			case BREAK : printf("break"); break;
			case SKIP : printf("skip"); break;
		}
		if (b) { printf(";"); }
		printf("\n");
	}
}	

void print_cmdlist (cmdlist *cl, int i)
{
	if (cl != NULL) {
		print_cmd(cl->cmd, i, cl->next != NULL);
		print_cmdlist(cl->next, i);
	}
}

void print_proc (proc *p)
{
	if (p != NULL) {
		printf("proc ");
		printf("%s \n\n", p->name);
		print_varlist(p->loc, 5);
		if (p->loc != NULL) {
			printf("\n");
		}
		print_cmdlist(p->core, 5);
		printf("end\n");
	}
}

void print_proclist (proclist *pl)
{
	if (pl != NULL) {
		print_proc(pl->p);
		printf("\n");
		print_proclist(pl->next);
	}
}

void print_spelist(spelist *spe)
{
	if (spe != NULL) {
		printf("reach ");
		print_bexpr(spe->cond);
		printf("\n");
		print_spelist(spe->next);
	}
}		

void print_prgm (prgm *p)
{
	if (p != NULL) {
		print_varlist(p->glob, 0);
		printf("\n");
		print_proclist(p->core);
		print_spelist(p->spe);
	}
}

/****************************************************************************/

int main (int argc, char **argv)
{
	if (argc <= 1) { yyerror("no file specified"); exit(1); }
	yyin = fopen(argv[1],"r");
	if (!yyparse()) print_prgm(program);
}
