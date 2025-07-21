%option noyywrap

%{
#include "parser.tab.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

extern FILE *tokens;

typedef struct {
    char id[100];
    char type[10];
} Identifier;

Identifier identifiers[100];
int identifier_count = 0;

int find_identifier(char *id) {
    for (int i = 0; i < identifier_count; i++) {
        if (strcmp(identifiers[i].id, id) == 0)
            return i;
    }
    return -1;
}

void add_identifier(char *id, char *type) {
    int idx = find_identifier(id);
    if (idx == -1) {
        strcpy(identifiers[identifier_count].id, id);
        strcpy(identifiers[identifier_count].type, type);
        identifier_count++;
        fprintf(tokens, "<id, %d> ", identifier_count);
    } else {
        fprintf(tokens, "<id, %d> ", idx + 1);
    }
}
%}

DIGIT       [0-9]+
FLOAT       [0-9]+\.[0-9]+
ID          [a-zA-Z_][a-zA-Z0-9_]*
WHITESPACE  [ \t\r\n]+
STRING      \"(\\.|[^\"\\])*\"

%%

xp          { fprintf(tokens, "<xp> ");         return XP; }
mana        { fprintf(tokens, "<mana> ");       return MANA; }
label       { fprintf(tokens, "<label> ");      return LABEL; }
limbo       { fprintf(tokens, "<limbo> ");      return LIMBO; }
args        { fprintf(tokens, "<args> ");       return ARGS; }
chat        { fprintf(tokens, "<chat> ");       return CHAT_FUNC; }
scan        { fprintf(tokens, "<scan> ");       return SCAN; }
checkpoint  { fprintf(tokens, "<checkpoint> "); return CHECKPOINT; }
gameover    { fprintf(tokens, "<gameover> ");   return GAMEOVER; }
combo       { fprintf(tokens, "<combo> ");      return COMBO; }
respawn     { fprintf(tokens, "<respawn> ");    return RESPAWN; }
ragequit    { fprintf(tokens, "<ragequit> ");   return RAGEQUIT; }
build       { fprintf(tokens, "<build> ");      return BUILD; }
fase        { fprintf(tokens, "<fase> ");       return FASE; }
fallback    { fprintf(tokens, "<fallback> ");   return FALLBACK; }
skill       { fprintf(tokens, "<skill> ");      return SKILL; }
drop        { fprintf(tokens, "<drop> ");       return DROP; }
buff        { fprintf(tokens, "<buff> ");       return BUFF; }
nerf        { fprintf(tokens, "<nerf> ");       return NERF; }
to          { fprintf(tokens, "<to> ");         return TO; }
inventario  { fprintf(tokens, "<inventario> "); return INVENTARIO; }

":="        { fprintf(tokens, "<:= > ");  return WALRUS; }
"&&"        { fprintf(tokens, "<&&> ");   return ANDAND; }
"||"        { fprintf(tokens, "<||> ");   return OROR; }
"=~="       { fprintf(tokens, "<=~=> ");  return EQEQ; }
"<="        { fprintf(tokens, "<<= > ");  return LE; }
"<"         { fprintf(tokens, "<< > ");   return LT; }
">="        { fprintf(tokens, "<>= > ");  return GE; }
">"         { fprintf(tokens, "<> > ");   return GT; }
"!="        { fprintf(tokens, "<!= > ");  return NE; }
"+"         { fprintf(tokens, "<+> ");    return PLUS; }
"-"         { fprintf(tokens, "<-> ");    return MINUS; }
"*"         { fprintf(tokens, "<*> ");    return MULT; }
"/"         { fprintf(tokens, "</> ");    return DIV; }
"("         { fprintf(tokens, "<(> ");    return LPAREN; }
")"         { fprintf(tokens, "<)> ");    return RPAREN; }
"{"         { fprintf(tokens, "<{> ");    return LBRACE; }
"}"         { fprintf(tokens, "<}> ");    return RBRACE; }
"["         { fprintf(tokens, "<[> ");    return LBRACKET; }
"]"         { fprintf(tokens, "<]> ");    return RBRACKET; }
";"         { fprintf(tokens, "<;> ");    return SEMICOLON; }
","         { fprintf(tokens, "<,> ");    return COMMA; }
"%"         { fprintf(tokens, "<%%> ");   return PERCENT; }
"++"        { fprintf(tokens, "<++> ");   return PLUSPLUS; }
"--"        { fprintf(tokens, "<--> ");   return MINUSMINUS; }
"!"         { fprintf(tokens, "<!> ");    return NOT; }
"+:="       { fprintf(tokens, "<+:=> ");  return PLUSEQ; }
"-:="       { fprintf(tokens, "<-:=> ");  return MINUSEQ; }
":"         { fprintf(tokens, "<:> ");    return COLON; }

f\"([^\"\\{]*)\{([^}]*)\}\" {
    char* full = strdup(yytext);
    yylval.str = full;
    fprintf(tokens, "<FSTRING, %s> ", yytext);
    return FSTRING;
}


{DIGIT} {
    yylval.str = strdup(yytext);
    fprintf(tokens, "<num, %s> ", yytext);
    return NUM;
}

{FLOAT} {
    yylval.str = strdup(yytext);
    fprintf(tokens, "<num, %s> ", yytext);
    return NUM;
}

{STRING}  { 
              yylval.str = strdup(yytext);
              fprintf(tokens, "<str, %s> ", yytext);
              return STRING_LITERAL;
          }
{ID} {
    yylval.str = strdup(yytext);
    add_identifier(yytext, "unknown");
    return ID;
}

"//".*                  { /* ignora comentários de linha */ }
"/*"([^*]|\*+[^*/])*\*+\/ { /* ignora comentários de bloco */ }

{WHITESPACE}            { /* ignora espaços */ }

. {
    fprintf(tokens, "<invalido, %s> ", yytext);
    return INVALIDO;
}
