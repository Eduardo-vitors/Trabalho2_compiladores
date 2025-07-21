%code requires {
    typedef struct Node Node;
}

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct Node {
    char name[50];
    char value[50];
    struct Node *left;
    struct Node *right;
} Node;

Node* createNode(const char* name, const char* value, Node* left, Node* right) {
    Node* n = (Node*)malloc(sizeof(Node));
    if (!n) {
        fprintf(stderr, "Erro de memória.\n");
        exit(1);
    }
    strcpy(n->name, name);
    if (value)
        strcpy(n->value, value);
    else
        n->value[0] = '\0';
    n->left = left;
    n->right = right;
    return n;
}

void arvore(Node* root, int level) {
    if (!root) return;
    for (int i = 0; i < level; i++) printf("  ");
    if (strlen(root->value))
        printf("%s (%s)\n", root->name, root->value);
    else
        printf("%s\n", root->name);
    arvore(root->left, level + 1);
    arvore(root->right, level + 1);
}

void arvoretxt(Node* root, int level, FILE* out) 
    if (!root) return;
    for (int i = 0; i < level; i++) fprintf(out, "  ");
    if (strlen(root->value))
        fprintf(out, "%s (%s)\n", root->name, root->value);
    else
        fprintf(out, "%s\n", root->name);
    arvoretxt(root->left, level + 1, out);
    arvoretxt(root->right, level + 1, out);
}

void liberar(Node* root) {
    if (!root) return;
    liberar(root->left);
    liberar(root->right);
    free(root);
}

void yyerror(const char* s) {
    fprintf(stderr, "Erro: %s\n", s);
}

int yylex();
%}

%union {
    char* str;
    Node* node;
}

%expect 1

%token <str> ID NUM STRING_LITERAL FSTRING
%token XP MANA LABEL LIMBO ARGS CHAT_FUNC SCAN CHECKPOINT GAMEOVER COMBO RESPAWN RAGEQUIT
%token BUILD FASE FALLBACK SKILL DROP BUFF NERF TO INVENTARIO
%token WALRUS PLUS MINUS MULT DIV LPAREN RPAREN LBRACE RBRACE SEMICOLON
%token ANDAND OROR EQEQ LT LE GT GE NE
%token LBRACKET RBRACKET COMMA PERCENT PLUSPLUS MINUSMINUS NOT PLUSEQ MINUSEQ COLON
%token INVALIDO FSTRING_START

%nonassoc LOWER_THAN_GAMEOVER
%nonassoc GAMEOVER
%left LT LE GT GE EQEQ NE
%left PLUS MINUS
%left MULT DIV

%type <node> program statement_list stmt decl atr checkpoint_stmt respawn_stmt skill_def drop_stmt bloco expressao tipo lvalue 
%type <node> expr_list non_empty_expr_list param_list param_decl arg_list chat_stmt fstring iterador combo_stmt

%%

program:
    statement_list {
        printf("Arvore Sintatica:\n");
        arvore($1, 0);
        FILE *sin_file = fopen("arvore.txt", "w");
        if (!sin_file) {
            fprintf(stderr, "Erro ao abrir arvore.txt\n");
            exit(1);
        }
        arvoretxt($1, 0, sin_file);
        fclose(sin_file);
        liberar($1);
    }
;

statement_list:
      statement_list stmt { $$ = createNode("statement_list", NULL, $1, $2); }
    | stmt                { $$ = $1; }
;

stmt:
      decl                { $$ = $1; }
    | atr                 { $$ = $1; }
    | checkpoint_stmt     { $$ = $1; }
    | respawn_stmt        { $$ = $1; }
    | skill_def           { $$ = $1; }
    | drop_stmt           { $$ = $1; }
    | combo_stmt          { $$ = $1; }
    | bloco               { $$ = $1; }
    | chat_stmt           { $$ = $1; }
    | expressao SEMICOLON { $$ = $1; }
;

decl:
      tipo ID LBRACKET NUM RBRACKET WALRUS LBRACE expr_list RBRACE SEMICOLON {
          $$ = createNode("decl-array-xp", NULL, 
                  createNode("decl-array", NULL, $1, createNode("ID", $2, NULL, NULL)),
                  $8);
      }
    | tipo ID LBRACKET NUM RBRACKET SEMICOLON {
          $$ = createNode("decl-array", NULL, $1, createNode("ID", $2, NULL, NULL));
      }
    | tipo ID LBRACKET expressao RBRACKET SEMICOLON {
          $$ = createNode("decl-array-dyn", NULL, $1, createNode("ID", $2, NULL, $4));
      }
    | tipo ID WALRUS expressao SEMICOLON {
          $$ = createNode("decl-init", NULL, createNode("ID", $2, NULL, NULL), $4);
      }
    | tipo ID SEMICOLON {
          $$ = createNode("decl", NULL, $1, createNode("ID", $2, NULL, NULL));
      }
;

combo_stmt:
    COMBO LPAREN iterador RPAREN bloco {
        $$ = createNode("combo", NULL, $3, $5);
    }
;

iterador:
    tipo ID WALRUS expressao TO expressao {
        Node* var_decl = createNode("decl-xp", NULL, createNode("ID", $2, NULL, NULL), $4);
        $$ = createNode("iterador", NULL, var_decl, $6);
    }
;

lvalue:
      ID                             { $$ = createNode("ID", $1, NULL, NULL); }
    | ID LBRACKET expressao RBRACKET { $$ = createNode("array_access", NULL, createNode("ID", $1, NULL, NULL), $3); }
;

atr:
    lvalue WALRUS expressao SEMICOLON { $$ = createNode("atribuicao", NULL, $1, $3); }
;

checkpoint_stmt:
    CHECKPOINT LPAREN expressao RPAREN stmt %prec LOWER_THAN_GAMEOVER { 
        $$ = createNode("checkpoint", NULL, $3, $5); 
    }
    | CHECKPOINT LPAREN expressao RPAREN stmt GAMEOVER stmt {
        $$ = createNode("checkpoint-gameover", NULL, createNode("checkpoint", NULL, $3, $5), $7);
    }
;

respawn_stmt:
    RESPAWN LPAREN expressao RPAREN stmt { $$ = createNode("respawn", NULL, $3, $5); }
;

drop_stmt:
      DROP SEMICOLON                 { $$ = createNode("drop", "limbo", NULL, NULL); }
    | DROP expressao SEMICOLON      { $$ = createNode("drop", NULL, $2, NULL); }
;

bloco:
    LBRACE statement_list RBRACE    { $$ = $2; }
;

skill_def:
    SKILL ID LPAREN param_list RPAREN bloco {
      $$ = createNode("func_def", NULL, 
              createNode("func_sig", $2, createNode("tipo", "skill", NULL, NULL), $4), $6);
    }
;

chat_stmt:
      CHAT_FUNC LPAREN expressao RPAREN SEMICOLON {
          $$ = createNode("chat", NULL, $3, NULL);
      }
    | CHAT_FUNC LPAREN fstring RPAREN SEMICOLON {
          $$ = createNode("chat", NULL, $3, NULL);
      }
    | CHAT_FUNC LPAREN STRING_LITERAL RPAREN SEMICOLON {
          $$ = createNode("chat", $3, NULL, NULL);
      }
;

fstring:
    FSTRING { $$ = createNode("fstring", $1, NULL, NULL); }
;

param_list:
    
      /* vazio */                  { $$ = NULL; }
    | LIMBO                        { $$ = NULL; }
    | param_decl                   { $$ = $1; }
    | param_list COMMA param_decl  { $$ = createNode("param_list", NULL, $1, $3); }
;

param_decl:
    tipo ID { $$ = createNode("param", NULL, $1, createNode("ID", $2, NULL, NULL)); }
;

arg_list:
      /* vazio */                  { $$ = NULL; }
    | expressao                    { $$ = $1; }
    | arg_list COMMA expressao    { $$ = createNode("arg_list", NULL, $1, $3); }
;

expressao:
      ID LPAREN arg_list RPAREN       { $$ = createNode("call", $1, $3, NULL); }
    | ID LBRACKET expressao RBRACKET  { $$ = createNode("array_access", NULL, createNode("ID", $1, NULL, NULL), $3); }
    | expressao PLUS expressao        { $$ = createNode("+", NULL, $1, $3); }
    | expressao MINUS expressao       { $$ = createNode("-", NULL, $1, $3); }
    | expressao MULT expressao        { $$ = createNode("*", NULL, $1, $3); }
    | expressao DIV expressao         { $$ = createNode("/", NULL, $1, $3); }
    | expressao LT expressao          { $$ = createNode("<", NULL, $1, $3); }
    | expressao LE expressao          { $$ = createNode("<=", NULL, $1, $3); }
    | expressao GT expressao          { $$ = createNode(">", NULL, $1, $3); }
    | expressao GE expressao          { $$ = createNode(">=", NULL, $1, $3); }
    | expressao EQEQ expressao        { $$ = createNode("=~=", NULL, $1, $3); }
    | expressao NE expressao          { $$ = createNode("!=", NULL, $1, $3); }
    | SCAN LPAREN RPAREN              { $$ = createNode("scan", NULL, NULL, NULL); }
    | NUM                             { $$ = createNode("NUM", $1, NULL, NULL); }
    | ID                              { $$ = createNode("ID", $1, NULL, NULL); }
    | LPAREN expressao RPAREN         { $$ = $2; }
;

tipo:
      XP     { $$ = createNode("tipo", "xp", NULL, NULL); }
    | MANA   { $$ = createNode("tipo", "mana", NULL, NULL); }
    | LABEL  { $$ = createNode("tipo", "label", NULL, NULL); }
;

expr_list:
    non_empty_expr_list             { $$ = $1; }
;

non_empty_expr_list:
      expressao                     { $$ = createNode("expr_item", "", $1, NULL); }
    | expressao COMMA non_empty_expr_list { $$ = createNode("expr_list", "", createNode("expr_item", "", $1, NULL), $3); }
;
%%

int yydebug = 0;
FILE *tokens;

int main() {
    tokens = fopen("tokens.lex", "w");
    if (!tokens) {
        fprintf(stderr, "Erro ao abrir tokens.lex.\n");
        exit(1);
    }
    yydebug = 1;
    yyparse();
    fclose(tokens);
    return 0;
}
