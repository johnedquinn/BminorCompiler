
/*
Declare token types at the top of the bison file,
causing them to be automatically generated in parser.tab.h
for use by scanner.c.
*/

%token TOKEN_EOF;
%token TOKEN_WHILE;
%token TOKEN_IF;
%token TOKEN_ELSE;
%token TOKEN_FOR;
%token TOKEN_PRINT;
%token TOKEN_TRUE;
%token TOKEN_FALSE;
%token TOKEN_RETURN;
%token TOKEN_ADD;
%token TOKEN_MULTIPLY;
%token TOKEN_DIVIDE;
%token TOKEN_MOD;
%token TOKEN_SUBTRACT;
%token TOKEN_POWER;
%token TOKEN_DECREMENT;
%token TOKEN_INCREMENT;
%token TOKEN_IDENT;
%token TOKEN_C_COMMENT;
%token TOKEN_COMMENT;
%token TOKEN_NUMBER;
%token TOKEN_STRING;
%token TOKEN_CHAR;
%token TOKEN_TYPE_STRING;
%token TOKEN_TYPE_INTEGER;
%token TOKEN_TYPE_BOOLEAN;
%token TOKEN_TYPE_FUNCTION;
%token TOKEN_TYPE_VOID;
%token TOKEN_TYPE_AUTO;
%token TOKEN_TYPE_CHAR;
%token TOKEN_TYPE_ARRAY;
%token TOKEN_GREATER_EQUAL;
%token TOKEN_GREATER;
%token TOKEN_EQUAL;
%token TOKEN_LESS;
%token TOKEN_LESS_EQUAL;
%token TOKEN_NOT_EQUAL;
%token TOKEN_AND;
%token TOKEN_OR;
%token TOKEN_NOT;
%token TOKEN_COLON;
%token TOKEN_SEMICOLON;
%token TOKEN_L_BRACKET;
%token TOKEN_R_BRACKET;
%token TOKEN_L_PAREN;
%token TOKEN_R_PAREN;
%token TOKEN_L_BRACE;
%token TOKEN_R_BRACE;
%token TOKEN_ASSIGN;
%token TOKEN_COMMA;
%token TOKEN_ERROR;

%union {
	struct decl * decl;
	struct stmt * stmt;
	struct expr * expr;
	struct type * type;
	struct symbol * symbol;
	struct param_list * param_list;
};

%type <decl> decl
%type <stmt> closed_stmt simple_stmt simple_stmts stmt stmts open_stmt if_then other_stmt for_list program
%type <expr> atomic arg_list expr ident subexpr term factor opt_expr
%type <type> type
%type <param_list> param param_list

%{

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include "stmt.h"

/*
YYSTYPE is the lexical value returned by each rule in a bison grammar.
By default, it is an integer. In this example, we are returning a pointer to an expression.
*/

//#define YYSTYPE stmt


/*
Clunky: Manually declare the interface to the scanner generated by flex. 
*/

//int parser_result = 0;

extern char * yytext;
extern int yylex();
extern int yyerror(char * str);

/*
Clunky: Keep the final result of the parse in a global variable,
so that it can be retrieved by main().
*/

struct stmt * parser_result = 0;

%}

%%

program:
	stmts
		{ $$ = stmt_create(STMT_BLOCK, NULL, NULL, NULL, NULL, $1, NULL, NULL); parser_result = $$; return 0; }
	|
		{ return 0; }
	;

stmts:
	stmt
		{ $$ = $1; }
	| stmt stmts
		{$1->next = $2; $$ = $1;}
	;

stmt:
	open_stmt
		{ $$ = $1; }
	| closed_stmt
		{ $$ = $1; }
	| other_stmt
		{ $$ = $1; }
	| decl
		{ $$ = stmt_create(STMT_DECL, $1, NULL, NULL, NULL, NULL, NULL, NULL); }
	;

if_then:
	TOKEN_IF TOKEN_L_PAREN expr TOKEN_R_PAREN
		{ $$ = stmt_create(STMT_IF_ELSE, NULL, NULL, $3, NULL, NULL, NULL, NULL); }
	;

open_stmt:
	if_then open_stmt
		{ ($1)->body = $2; $$ = $1; }
	| if_then simple_stmt TOKEN_SEMICOLON
		{ ($1)->body = $2; $$ = $1; }
	| if_then simple_stmts
		{ ($1)->body = $2; $$ = $1; }
	| if_then closed_stmt TOKEN_ELSE open_stmt
		{ ($1)->body = $2; ($1)->else_body = $4; $$ = $1; }
	;

closed_stmt:
	simple_stmt TOKEN_SEMICOLON
		{ $$ = $1; }
	| if_then closed_stmt TOKEN_ELSE closed_stmt
		{ ($1)->body = $2; ($1)->else_body = $4; $$ = $1; }
	| simple_stmts
		{ $$ = $1; }
	;

other_stmt:	
	TOKEN_FOR TOKEN_L_PAREN for_list TOKEN_R_PAREN stmt
		{
			($3)->body = $5;
			$$ = $3;
		}
	;

simple_stmts:
	TOKEN_L_BRACE stmts TOKEN_R_BRACE
		{ $$ = stmt_create(STMT_BLOCK, NULL, NULL, NULL, NULL, $2, NULL, NULL); }
	;

simple_stmt:
	TOKEN_PRINT arg_list
		{ $$ = stmt_create(STMT_PRINT, NULL, NULL, $2, NULL, NULL, NULL, NULL); }
	| TOKEN_PRINT
		{ $$ = stmt_create(STMT_PRINT, NULL, NULL, NULL, NULL, NULL, NULL, NULL); }
	| TOKEN_RETURN expr
		{ $$ = stmt_create(STMT_RETURN, NULL, NULL, $2, NULL, NULL, NULL, NULL); }
	| TOKEN_RETURN
		{ $$ = stmt_create(STMT_RETURN, NULL, NULL, NULL, NULL, NULL, NULL, NULL); }
	| expr
		{ $$ = stmt_create(STMT_EXPR, NULL, NULL, $1, NULL, NULL, NULL, NULL); }
	;

for_list:
	opt_expr TOKEN_SEMICOLON opt_expr TOKEN_SEMICOLON opt_expr
		{ $$ = stmt_create(STMT_FOR, NULL, $1, $3, $5, NULL, NULL, NULL); }
	;

opt_expr:
	expr
		{ $$ = $1; }
	|
		{ $$ = expr_create(EXPR_NUL, 0, 0); }
	;

param:
	ident TOKEN_COLON type
		{ $$ = param_list_create(strdup(($1)->name), $3, 0); }
	;

decl:
	param TOKEN_SEMICOLON
		{ $$ = decl_create(($1)->name, ($1)->type, NULL, NULL, NULL); }
	| param TOKEN_ASSIGN closed_stmt
		{ $$  = decl_create(($1)->name, ($1)->type, ($3)->expr, ($3)->body, NULL); }
	;

type:
	TOKEN_TYPE_ARRAY TOKEN_L_BRACKET TOKEN_R_BRACKET type
		{ $$ = type_create(TYPE_ARRAY, $4, NULL); }
	| TOKEN_TYPE_ARRAY TOKEN_L_BRACKET TOKEN_NUMBER TOKEN_R_BRACKET type
		{ $$ = type_create(TYPE_ARRAY, $5, NULL); }
	| TOKEN_TYPE_AUTO
		{ $$ = type_create(TYPE_AUTO, NULL, NULL); }
	| TOKEN_TYPE_BOOLEAN
		{ $$ = type_create(TYPE_BOOLEAN, NULL, NULL); }
	| TOKEN_TYPE_CHAR
		{ $$ = type_create(TYPE_CHARACTER, NULL, NULL); }
	| TOKEN_TYPE_INTEGER
		{ $$ = type_create(TYPE_INTEGER, NULL, NULL); }
	| TOKEN_TYPE_STRING
		{ $$ = type_create(TYPE_STRING, NULL, NULL); }
	| TOKEN_TYPE_VOID
		{ $$ = type_create(TYPE_VOID, NULL, NULL); }
	| TOKEN_TYPE_FUNCTION type TOKEN_L_PAREN param_list TOKEN_R_PAREN
		{ $$ = type_create(TYPE_FUNCTION, $2, $4); }
	| TOKEN_TYPE_FUNCTION type TOKEN_L_PAREN TOKEN_R_PAREN
		{ $$ = type_create(TYPE_FUNCTION, $2, NULL); }
	;
	
param_list:
	param
		{ $$ = $1; }
	| param TOKEN_COMMA param_list
		{ ($1)->next = $3; $$ = $1; }
	;

expr:
	expr TOKEN_LESS subexpr
		{ $$ = expr_create(EXPR_LES, $1, $3); }
	| expr TOKEN_GREATER subexpr
		{ $$ = expr_create(EXPR_GRE, $1, $3); }
	| expr TOKEN_LESS_EQUAL subexpr
		{ $$ = expr_create(EXPR_LEQ, $1, $3); }
	| expr TOKEN_GREATER_EQUAL subexpr
		{ $$ = expr_create(EXPR_GEQ, $1, $3); }
	| expr TOKEN_EQUAL subexpr
		{ $$ = expr_create(EXPR_EQL, $1, $3); }
	| expr TOKEN_NOT_EQUAL subexpr
		{ $$ = expr_create(EXPR_NEQ, $1, $3); }
	| expr TOKEN_AND subexpr
		{ $$ = expr_create(EXPR_AND, $1, $3); }
	| expr TOKEN_OR subexpr
		{ $$ = expr_create(EXPR_ORR, $1, $3); }
	| expr TOKEN_ASSIGN subexpr
		{ $$ = expr_create(EXPR_ASN, $1, $3); }
	| expr TOKEN_ASSIGN TOKEN_L_BRACE arg_list TOKEN_R_BRACE
		{ $$ = expr_create(EXPR_ASN, $1, $4); }
	| expr TOKEN_L_BRACKET expr TOKEN_R_BRACKET
		{ $$ = expr_create(EXPR_IND, $1, $3); }
	| subexpr
		{ $$ = $1; }
	;

subexpr:
	subexpr TOKEN_ADD term
		{ $$ = expr_create(EXPR_ADD, $1, $3); }
	| subexpr TOKEN_SUBTRACT term
		{ $$ = expr_create(EXPR_SUB, $1, $3); }
	| term
		{ $$ = $1; }
	;

term:
	term TOKEN_MULTIPLY factor
		{ $$ = expr_create(EXPR_MUL, $1, $3); }
	| term TOKEN_DIVIDE factor
		{ $$ = expr_create(EXPR_DIV, $1, $3); }
	| term TOKEN_MOD factor
		{ $$ = expr_create(EXPR_MOD, $1, $3); }
	| factor
		{ $$ = $1; }
	;

factor:
	factor TOKEN_POWER atomic
		{ $$ = expr_create(EXPR_POW, $1, $3); }
	| factor TOKEN_INCREMENT
		{ $$ = expr_create(EXPR_INC, $1, NULL); }
	| factor TOKEN_DECREMENT
		{ $$ = expr_create(EXPR_DEC, $1, NULL); }
	| atomic
		{ $$ = $1; }
	;

atomic:
	TOKEN_L_PAREN expr TOKEN_R_PAREN
		{ $$ = expr_create(EXPR_PRN, $2, NULL); }
	| ident TOKEN_L_PAREN arg_list TOKEN_R_PAREN
		{ $$ = expr_create(EXPR_FNC, $1, $3); }
	| ident TOKEN_L_PAREN TOKEN_R_PAREN
		{ $$ = expr_create(EXPR_FNC, $1, NULL); }
	| TOKEN_SUBTRACT atomic
		{ $$ = expr_create(EXPR_NEG, NULL, $2); }
	| TOKEN_ADD atomic
		{ $$ = expr_create(EXPR_POS, NULL, $2); }
	| TOKEN_NUMBER
		{ $$ = expr_create_integer_literal(atoi(yytext)); }
	| TOKEN_CHAR
		{ $$ = expr_create_char_literal(yytext[0]); }
	| TOKEN_STRING
		{ $$ = expr_create_string_literal(yytext); }
	| TOKEN_FALSE
		{ $$ = expr_create_boolean_literal(false); }
	| TOKEN_TRUE
		{ $$ = expr_create_boolean_literal(true); }
	| TOKEN_NOT atomic
		{ $$ = expr_create(EXPR_NOT, NULL, $2); }
	| ident
		{ $$ = $1; }
	;

ident:
	TOKEN_IDENT
		{ $$ = expr_create_name(yytext); }
	;

arg_list:
	expr
	| expr TOKEN_COMMA arg_list
		{ $$ = expr_create(EXPR_ARG, $1, $3); }
	;

%%

/*
This function will be called by bison if the parse should
encounter an error.  In principle, "str" will contain something
useful.  In practice, it often does not.
*/

int yyerror (char * str) {
	printf("parse error: %s\n", str);
	return 1;
}