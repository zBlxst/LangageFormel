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
	int count_reach;
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
	int toDoNext; // acts like a boolean
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
	int alive;
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
	vl = l1;
	if (vl == NULL) {
		return l2;
	}
	else {
		while (vl->next != NULL) {
			vl = vl->next;
		}
		vl->next = l2;
		return l1;
	}
	
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
	b->count_reach = 0;
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
	c->toDoNext = 0;
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
	p->alive = 1;
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
%define parse.error verbose

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

%left OR AND PLUS MINUS
%left TIME DIV
%right NOT

%%

prgm : glob proclist spelist 				{ program = make_prgm($1, $2, $3); }

glob : 										{ $$ = NULL; }
	| VAR declist ';' glob 					{ $$ = concat_varlist($2, $4); }

declist : IDENT 							{ $$ = make_varlist(make_var($1), NULL); }
	| IDENT ',' declist 					{ $$ = make_varlist(make_var($1), $3); }

proclist : proc 							{ $$ = make_proclist($1, NULL); }
	| proc proclist 						{ $$ = make_proclist($1, $2); }

proc : PROC IDENT glob cmdlist END 			{ $$ = make_proc($2, $3, $4); }

cmdlist : 									{ $$ = NULL; }
	| cmd 									{ $$ = make_cmdlist($1, NULL); }
	| cmd ';' cmdlist 						{ $$ = make_cmdlist($1,$3); }

cmd : IDENT ASSIGN aexpr 					{ $$ = make_cmd(ASSIGN, $1, $3, NULL); }
	| DO caselist OD 						{ $$ = make_cmd(DO, NULL, NULL, $2); }
	| IF caselist FI 						{ $$ = make_cmd(IF, NULL, NULL, $2); }
	| BREAK 								{ $$ = make_cmd(BREAK, NULL, NULL, NULL); }
	| SKIP 									{ $$ = make_cmd(SKIP, NULL, NULL, NULL); }

caselist : 									{ $$ = NULL; }
	| qase caselist 						{ $$ = make_caselist($1, $2); }

qase : CASE bexpr THEN cmdlist 				{ $$ = make_case($2, $4); }
	| CASE ELSE THEN cmdlist 				{ $$ = make_case(NULL, $4); }

aexpr : IDENT 								{ $$ = make_aexpr(IDENT, 0, $1, NULL, NULL); } 
	| aexpr PLUS aexpr 						{ $$ = make_aexpr(PLUS, 0, NULL, $1, $3); }
	| aexpr MINUS aexpr 					{ $$ = make_aexpr(MINUS, 0, NULL, $1, $3); }
	| aexpr TIME aexpr 						{ $$ = make_aexpr(TIME, 0, NULL, $1, $3); }
	| aexpr DIV aexpr 						{ $$ = make_aexpr(DIV, 0, NULL, $1, $3); }
	| INT 									{ $$ = make_aexpr(INT, $1, NULL, NULL, NULL); }
	| '(' aexpr ')' 						{ $$ = $2; }

bexpr : aexpr 								{ $$ = make_bexpr(0, $1, NULL, NULL, NULL); }
	| NOT bexpr 							{ $$ = make_bexpr(NOT, NULL, $2, NULL, NULL); }
	| bexpr AND bexpr 						{ $$ = make_bexpr(AND, NULL, $1, $3, NULL); }
	| bexpr OR bexpr 						{ $$ = make_bexpr(OR, NULL, $1, $3, NULL); }
	| compare 								{ $$ = make_bexpr(COMPARE, NULL, NULL, NULL, $1); }
	| '(' bexpr ')' 						{ $$ = $2; }

compare : aexpr EQ aexpr 					{ $$ = make_compare(EQ, $1, $3); }
	| aexpr LE aexpr 						{ $$ = make_compare(LE, $1, $3); }
	| aexpr LT aexpr 						{ $$ = make_compare(LT, $1, $3); }
	| aexpr GE aexpr 						{ $$ = make_compare(GE, $1, $3); }
	| aexpr GT aexpr 						{ $$ = make_compare(GT, $1, $3); }

spelist : { $$ = NULL; }
	| REACH bexpr spelist 					{ $$ = make_spelist($2, $3); }

%%

#include "lexer.c"
#include <time.h>

#define AMOUNT_OF_TESTS 1000
#define DEPTH_OF_TESTS 1000

#define VAR_NOT_CHANGED 1
#define VAR_NOT_FOUND -1	
#define SMALLEST_NOT_FOUND 1

#define FOUND_BUT_NOT_SET 1
#define NOT_FOUND_NOT_SET 2

#define NO_CASE_IN_DO 1

#define EXECUTION_OVER 1

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
/* functions to run the program and try to solve reaches */

cmd* find_command_to_do_cmdlist(proc *p, cmdlist *cmdl);
cmd* find_command_to_do_caselist(proc *p, caselist* casel);
int change_var(varlist *varl, char *name, int value);
int compute_a(prgm *pm, proc *p, aexpr *expr);
int compute_b(prgm *pm, proc *p, bexpr *expr);
int compute_compare(prgm *pm, proc *p, compare *cmp);
qase* choose_case(prgm *pm, proc *p, caselist *casel, int i);
cmd* smallest_control_struct_cmdlist(proc *p, cmdlist *cmdl);
cmdlist* smallest_control_struct_caselist(proc *p, caselist *casel);
int exit_control_struct(proc *p, cmdlist *cmdl);
int set_next_cmdlist(proc *p, cmdlist *cmdl, int found);
int set_next_caselist(proc *p, caselist *casel, int found);	
int execute(prgm *pm, proc *p, cmd *command);
int one_step_in_proc(prgm *pm, proc *p);

void print_vars(prgm *pm);

cmd* find_command_to_do_cmdlist(proc *p, cmdlist *cmdl) {
	if (cmdl != NULL && cmdl->cmd != NULL) {
		if (cmdl->cmd->toDoNext) {
			return cmdl->cmd;
		}
		switch (cmdl->cmd->type) {
			case DO:
				{
					cmd *res = find_command_to_do_caselist(p, cmdl->cmd->cases);
					if (res != NULL) {
						return res;
					}
					break;
				}
			case IF:
				{
					cmd *res = find_command_to_do_caselist(p, cmdl->cmd->cases);
					if (res != NULL) {
						return res;
					}
					break;
				}
		}
		return find_command_to_do_cmdlist(p, cmdl->next);
	}
	return NULL;
}

cmd* find_command_to_do_caselist(proc *p, caselist* casel) {
	if (casel != NULL && casel->qase != NULL && casel->qase->effet) {
		cmd *res = find_command_to_do_cmdlist(p, casel->qase->effet);
		if (res != NULL) {
			return res;
		} else {
			return find_command_to_do_caselist(p, casel->next);
		}
	}
	return NULL;
}

int change_var(varlist *varl, char *name, int value) {
	if (varl != NULL && varl->v != NULL) {
		if (!strcmp(varl->v->name, name)) {
			varl->v->value = value;
			return 0;
		} 
		return change_var(varl->next, name, value);
	}
	return VAR_NOT_CHANGED;
}

int get_value(varlist *varl, char *name, int *found) {
	if (varl != NULL && varl->v != NULL) {
		if (!strcmp(varl->v->name, name)) {
			*found = 1;
			return varl->v->value;
		} 
		return get_value(varl->next, name, found);
	}
	return VAR_NOT_FOUND;
}

int compute_a(prgm *pm, proc *p, aexpr *expr) {
	switch (expr->type) {
		case IDENT:
		{
			int *pfound, found;
			pfound = &found;
			found = 0;
			int res;
			if (p != NULL) {
				res = get_value(p->loc, expr->name, pfound);
				if (found) {
					return res;
				}
			}
			res = get_value(pm->glob, expr->name, pfound);
			if (found) {
				return res;
			}
			fprintf(stderr, "Couldn't find variable %s\n", expr->name);
			exit(1);
		}
		case INT:
			return expr->val;
		case PLUS:
			return compute_a(pm, p, expr->left) + compute_a(pm, p, expr->right);
		case MINUS:
			return compute_a(pm, p, expr->left) - compute_a(pm, p, expr->right);
		case TIME:
			return compute_a(pm, p, expr->left) * compute_a(pm, p, expr->right);
		case DIV:
			{
				int denom = compute_a(pm, p, expr->right);
				if (denom != 0) {
					return compute_a(pm, p, expr->left) / denom;
				} else {
					fprintf(stderr, "Cannot divide by zero !\n");
					exit(1);
				}
			}
	}
}

int compute_b(prgm *pm, proc *p, bexpr *expr) {
	switch (expr->type) {
		case 0:
			return compute_a(pm, p, expr->val);
		case NOT:
			return !compute_b(pm, p, expr->left);
		case AND:
		{
			int res;
			if (compute_b(pm, p, expr->left)) {
				return compute_b(pm, p, expr->right);
			}
			return 0;
		}
		case OR:
		{
			int res;
			if (!compute_b(pm, p, expr->left)) {
				return compute_b(pm, p, expr->right);
			}
			return 1;
		}
		case COMPARE:
			return compute_compare(pm, p, expr->cmp);
	}
}

int compute_compare(prgm *pm, proc *p, compare *cmp) {
	switch (cmp->type) {
		case LE:
			return compute_a(pm, p, cmp->left) <= compute_a(pm, p, cmp->right);
		case LT:
			return compute_a(pm, p, cmp->left) < compute_a(pm, p, cmp->right);
		case GE:
			return compute_a(pm, p, cmp->left) >= compute_a(pm, p, cmp->right);
		case GT:
			return compute_a(pm, p, cmp->left) > compute_a(pm, p, cmp->right);
		case EQ:
			return compute_a(pm, p, cmp->left) == compute_a(pm, p, cmp->right);
	}
}

qase* choose_case(prgm *pm, proc *p, caselist *casel, int i) {
	if (i == -1) {
		int count = 0;
		for (caselist *qasl = casel; qasl != NULL; qasl = qasl->next) {
			if (qasl->qase->cond != NULL) {
				count += compute_b(pm, p, qasl->qase->cond);
			}
		}
		if (count == 0) {
			for (caselist *qasl = casel; qasl != NULL; qasl = qasl->next) {
				if (qasl->qase->cond == NULL) {
					return qasl->qase;
				}
			}
			return NULL;
		}
		return choose_case(pm, p, casel, rand()%count);
	}

	if (i == 0 && compute_b(pm, p, casel->qase->cond)) {
		return casel->qase;
	}
	return (compute_b(pm, p, casel->qase->cond) ? choose_case(pm, p, casel->next, i-1) : choose_case(pm, p, casel->next, i));
}

cmd* smallest_control_struct_cmdlist(proc *p, cmdlist *cmdl) {
	if (cmdl != NULL) {
		switch (cmdl->cmd->type) {
			case DO:
			{
				cmd *res = find_command_to_do_caselist(p, cmdl->cmd->cases);
				if (res != NULL) {
					cmdlist *smaller = smallest_control_struct_caselist(p, cmdl->cmd->cases);
					if (smaller != NULL) {
						return smallest_control_struct_cmdlist(p, smaller);
					}
					return cmdl->cmd;
				}
			}
		}
		return smallest_control_struct_cmdlist(p, cmdl->next);	
	}
	return NULL;
}

cmdlist* smallest_control_struct_caselist(proc *p, caselist *casel) {
	if (casel != NULL) {
		cmd *res = smallest_control_struct_cmdlist(p, casel->qase->effet);
		if (res != NULL) {
			return casel->qase->effet;
		}
		return smallest_control_struct_caselist(p, casel->next);
	}
	return NULL;
}


int exit_control_struct(proc *p, cmdlist *cmdl) {
	cmd *smallest = smallest_control_struct_cmdlist(p, cmdl);
	cmd *broken = find_command_to_do_cmdlist(p, cmdl);
	broken->toDoNext = 0;
	if (smallest != NULL) {
		smallest->toDoNext = 1;
		return 0;
	}
	return SMALLEST_NOT_FOUND;
}

int set_next_cmdlist(proc *p, cmdlist *cmdl, int found) {
	if (cmdl != NULL) {
		if (found) {
			cmdl->cmd->toDoNext = 1;
			return 0;
		} 
		if (cmdl->cmd->toDoNext) {
			cmdl->cmd->toDoNext = 0;
			return set_next_cmdlist(p, cmdl->next, 1);
		}
		switch (cmdl->cmd->type) {
			case DO:
				{
					int res = set_next_caselist(p, cmdl->cmd->cases, found); 
					switch (res) {
						case 0:
							return 0;
						case FOUND_BUT_NOT_SET:
							cmdl->cmd->toDoNext = 1;
							return 0;
						case NOT_FOUND_NOT_SET:
							return set_next_cmdlist(p, cmdl->next, found);
					}
				}
			case IF:
				switch (set_next_caselist(p, cmdl->cmd->cases, found)) {
					case 0:
						return 0;
					case FOUND_BUT_NOT_SET:
						return set_next_cmdlist(p, cmdl->next, 1);
					case NOT_FOUND_NOT_SET:
						return set_next_cmdlist(p, cmdl->next, 0);

				}

			default:
				return set_next_cmdlist(p, cmdl->next, found);

		}
	}
	if (found) {
		return FOUND_BUT_NOT_SET;
	}
	return NOT_FOUND_NOT_SET;
}

int set_next_caselist(proc *p, caselist *casel, int found) {
	if (casel != NULL) {
		if (found) {
			return set_next_cmdlist(p, casel->qase->effet, 1);
		}
		switch (set_next_cmdlist(p, casel->qase->effet, found)) {
			case 0:
				return 0;
			case FOUND_BUT_NOT_SET:
				return FOUND_BUT_NOT_SET;
			case NOT_FOUND_NOT_SET:
				return set_next_caselist(p, casel->next, found);
		}
	}
	if (found) {
		return FOUND_BUT_NOT_SET;
	}
	return NOT_FOUND_NOT_SET; 
}



int execute(prgm *pm, proc *p, cmd *command) {
	if (command != NULL) {
		switch (command->type) {
			case ASSIGN:
				if (!change_var(p->loc, command->name, compute_a(pm, p, command->val))) {
					return 0;
				}
				if (!change_var(pm->glob, command->name, compute_a(pm, p, command->val))) {
					return 0;
				}
				fprintf(stderr, "Couldn't find variable %s\n", command->name);
				exit(1);
			case SKIP:
				return 0;
			case BREAK:
				if (!exit_control_struct(p, p->core)) {
					return 0;
				}
				fprintf(stderr, "No do/if to break\n");
				exit(1);
			case DO:
				{
					qase *qas = choose_case(pm, p, command->cases, -1);
					if (qas == NULL) {
						return NO_CASE_IN_DO;
					}
					command->toDoNext = 0;
					qas->effet->cmd->toDoNext = 1;
					return execute(pm, p, qas->effet->cmd);
				}
			case IF:
				{
					qase *qas = choose_case(pm, p, command->cases, -1);
					if (qas == NULL) {
						return 0;
					}
					command->toDoNext = 0;
					qas->effet->cmd->toDoNext = 1;
					return execute(pm, p, qas->effet->cmd);
				}
		}
	}
}

int one_step_in_proc(prgm *pm, proc *p) {
	if (p != NULL && p->core != NULL) {
		cmd *toDo = find_command_to_do_cmdlist(p, p->core);
		if (toDo == NULL) {
			return 1;
		}
		int exec_ret = execute(pm, p, toDo);
		if (exec_ret == NO_CASE_IN_DO) {
			return 0;
		}
		if (exec_ret) {
			fprintf(stderr, "Something went wrong : execution aborted\n");
			exit(1);
		}
		int set = set_next_cmdlist(p, p->core, 0);
		if (set) {
			p->alive = 0;
		}
		return 0;
	}
}

int one_step_overall(prgm *pm, proclist *pl, int i) {
	if (i == -1) {
		int count = 0;
		for (proclist *pl = pm->core; pl != NULL; pl = pl->next) {
			count += pl->p->alive;
		}
		if (count == 0) {
			return EXECUTION_OVER;
		}
		return one_step_overall(pm, pl, rand() % count);
	}
	if (i == 0 && pl->p->alive) {
		return one_step_in_proc(pm, pl->p);
	}
	return (pl->p->alive ? one_step_overall(pm, pl->next, i-1) : one_step_overall(pm, pl->next, i));
}

int reset_program(prgm *pm) {
	for (proclist *pl = pm->core; pl != NULL; pl = pl->next) {
		proc *p = pl->p;
		p->alive = 1;
		for (varlist *loc = p->loc; loc != NULL; loc = loc->next) {
			loc->v->value = 0;
		}
		cmd *oldToDo = find_command_to_do_cmdlist(p, p->core);
		if (oldToDo != NULL) {
			oldToDo->toDoNext = 0;
		}
		set_next_cmdlist(p, p->core, 1);
	}
	for (varlist *glob = pm->glob; glob != NULL; glob = glob->next) {
		glob->v->value = 0;
	}
}

void print_vars(prgm *pm) {
	for (varlist *glob = pm->glob; glob != NULL; glob = glob->next) {
		printf("%s at %p -> %d\n", glob->v->name, glob->v, glob->v->value);
	}
	for (proclist *pl = pm->core; pl != NULL; pl = pl->next) {
		for (varlist *loc = pl->p->loc; loc != NULL; loc = loc->next) {
			printf("proc %s -> %s at %p -> %d\n", pl->p->name, loc->v->name, loc->v, loc->v->value);
		}
	}
}

void check_reach(prgm *pm, spelist *spl) {
	if (spl != NULL) {
		spl->cond->count_reach += compute_b(pm, NULL, spl->cond);
		check_reach(pm, spl->next);
	}
}

void print_reaches(spelist *spl) {
	if (spl != NULL) {
		print_bexpr(spl->cond);
		printf(" reached %d times\n", spl->cond->count_reach);
		print_reaches(spl->next);
	}
}

int myRun(prgm *pm) {
	reset_program(pm);
	for (int i = 0; i < AMOUNT_OF_TESTS; i++) {
		reset_program(pm);
		for (int i = 0; i < DEPTH_OF_TESTS && !one_step_overall(pm, pm->core, -1); i++) {
			check_reach(pm, pm->spe);	
		}
	}

	print_reaches(pm->spe);



	return 0;
}

/****************************************************************************/

int main (int argc, char **argv)
{
	if (argc <= 1) { yyerror("no file specified"); exit(1); }
	yyin = fopen(argv[1],"r");
	if (!yyparse()) {
		print_prgm(program);
	}
	srand(time(NULL));
	printf("\n\n******Trying to run the program******\n\n");
	int res = myRun(program);
	printf("%d\n", res);

	return 0;

}
