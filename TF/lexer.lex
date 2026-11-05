%{
/* ========================================================================== */
/* Analisador Léxico (FLEX) Completo - Trabalho Final (Pythonhol)             */
/* ========================================================================== */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h" /* Cabeçalho gerado pelo BISON */

/* Paleta de Cores ANSI Pré-declaradas */
const char *COLOR_RESET  = "\033[0m";
const char *COLOR_HEADER = "\033[1;32m"; /* Verde Negrito */
const char *COLOR_RED    = "\033[1;31m"; /* Vermelho Negrito */
const char *COLOR_YELLOW = "\033[1;33m"; /* Amarelo Negrito */
const char *COLOR_GRAY   = "\033[90m";   /* Cinza Escuro */
const char *COLOR_BLUE = "\033[94m";     /* Azul Claro */
const char *COLOR_CYAN = "\033[36m";     /* Azul Ciano */
const char *COLOR_LIGHT_RED = "\033[91m";/* Vermelho Claro */
const char *COLOR_DARK_RED = "\033[31m"; /* Veremlho Escuro */

/* Variáveis para controle de posição */
int num_linhas = 1;
int num_colunas = 1;
int col_token = 1;

/* Controle de indentação para gerar INIDEBL e FIMDEBL */
int nivel_indent_atual = 0;
int tabs_na_linha = 0;
int pendentes_dedent = 0;

#define YY_USER_ACTION \
    col_token = num_colunas; \
    num_colunas += yyleng;

/* ========================================================================== */
/* TABELA DE SÍMBOLOS                                                         */
/* ========================================================================== */

typedef struct Posicao {
    int linha;
    int coluna;
    struct Posicao *prox;
} Posicao;

typedef struct TokenNode {
    char *lexema;
    int contagem;
    int is_aceito;
    Posicao *pos_inicio;
    Posicao *pos_fim;
    struct TokenNode *prox;
} TokenNode;

TokenNode *tabela_simbolos = NULL;

void registrar_token(const char *lexema, int linha, int coluna, int aceito) {
    TokenNode *atual = tabela_simbolos;
    TokenNode *anterior = NULL;

    while (atual != NULL) {
        int cmp = strcmp(atual->lexema, lexema);
        if (cmp == 0) {
            atual->contagem++;
            Posicao *nova_pos = (Posicao *)malloc(sizeof(Posicao));
            nova_pos->linha = linha;
            nova_pos->coluna = coluna;
            nova_pos->prox = NULL;
            atual->pos_fim->prox = nova_pos;
            atual->pos_fim = nova_pos;
            return;
        } else if (cmp > 0) {
            break;
        }
        anterior = atual;
        atual = atual->prox;
    }

    TokenNode *novo_no = (TokenNode *)malloc(sizeof(TokenNode));
    novo_no->lexema = strdup(lexema);
    novo_no->contagem = 1;
    novo_no->is_aceito = aceito;

    Posicao *nova_pos = (Posicao *)malloc(sizeof(Posicao));
    nova_pos->linha = linha;
    nova_pos->coluna = coluna;
    nova_pos->prox = NULL;

    novo_no->pos_inicio = nova_pos;
    novo_no->pos_fim = nova_pos;

    novo_no->prox = atual;
    if (anterior == NULL) {
        tabela_simbolos = novo_no;
    } else {
        anterior->prox = novo_no;
    }
}

void imprimir_token(TokenNode *no) {
    Posicao *p = no->pos_inicio;
    while (p != NULL) {
        printf("[L:\"%d\", C:\"%d\"]", p->linha, p->coluna);
        if (p->prox != NULL) printf(", ");
        p = p->prox;
    }
    if (no->contagem == 1) {
        printf("%s\n\t(Aparece \"%d\" vez na entrada)\n", COLOR_RESET, no->contagem);
    } else {
        printf("%s\n\t(Aparece \"%d\" vezes na entrada)\n", COLOR_RESET, no->contagem);
    }
}

void imprimir_relatorio() {
    TokenNode *atual = tabela_simbolos;
    while (atual != NULL) {
        if (atual->is_aceito == 1) {
            printf("%s \"%s\" %s Reconhecido em: ", COLOR_BLUE, atual->lexema, COLOR_CYAN);
            imprimir_token(atual);
        }
        atual = atual->prox;
    }
    atual = tabela_simbolos;
    while (atual != NULL) {
        if (atual->is_aceito == 0) {
            printf("%s \"%s\" %s Não reconhecido em: ", COLOR_DARK_RED, atual->lexema, COLOR_LIGHT_RED);
            imprimir_token(atual);
        }
        atual = atual->prox;
    }
}

void liberar_memoria() {
    TokenNode *atual = tabela_simbolos;
    while (atual != NULL) {
        TokenNode *temp_no = atual;
        Posicao *p = atual->pos_inicio;
        while (p != NULL) {
            Posicao *temp_p = p;
            p = p->prox;
            free(temp_p);
        }
        atual = atual->prox;
        free(temp_no->lexema);
        free(temp_no);
    }
    tabela_simbolos = NULL;
}
%}

%option noyywrap
%x INDENT

/* ========================================================================== */
/* DEFINIÇÕES                                                                 */
/* ========================================================================== */

DIGITO      [0-9]
LETRA       [a-zA-Z_]
NUMERO      {DIGITO}+("."{DIGITO}+)?
NOME        {LETRA}({LETRA}|{DIGITO})*
TABULACAO   \t
NOVALINHA   \n
ESPACO      [ ]+

/* ========================================================================== */
/* REGRAS LÉXICAS                                                             */
/* ========================================================================== */
%%
%{
    /* Se houver recuos de bloco pendentes para entregar ao Bison, envia um por vez */
    if (pendentes_dedent > 0) {
        pendentes_dedent--;
        return FIMDEBL;
    }
%}

<INDENT>{TABULACAO} {
    tabs_na_linha++;
    registrar_token("<TAB>", num_linhas, col_token, 1);
    num_colunas += 3;
}

<INDENT>{ESPACO} {
    /* Ignora espaços extras no início da linha */
}

<INDENT>{NOVALINHA} {
    /* Linha em branco: reseta a contagem de tabs da linha e continua */
    tabs_na_linha = 0;
    num_linhas++;
    num_colunas = 1;
}

<INDENT>. {
    /* Encontrou o primeiro caractere útil da linha: devolve para o buffer e avalia indentação */
    unput(*yytext);
    num_colunas--;
    BEGIN(INITIAL);

    if (tabs_na_linha > nivel_indent_atual) {
        nivel_indent_atual++;
        return INIDEBL;
    } else if (tabs_na_linha < nivel_indent_atual) {
        int diff = nivel_indent_atual - tabs_na_linha;
        nivel_indent_atual = tabs_na_linha;
        pendentes_dedent = diff - 1;
        return FIMDEBL;
    }
}

"if"       { registrar_token(yytext, num_linhas, col_token, 1); return T_IF; }
"else"     { registrar_token(yytext, num_linhas, col_token, 1); return T_ELSE; }
"while"    { registrar_token(yytext, num_linhas, col_token, 1); return T_WHILE; }
"for"      { registrar_token(yytext, num_linhas, col_token, 1); return T_FOR; }
"in"       { registrar_token(yytext, num_linhas, col_token, 1); return T_IN; }
"def"      { registrar_token(yytext, num_linhas, col_token, 1); return T_DEF; }
"return"   { registrar_token(yytext, num_linhas, col_token, 1); return T_RETURN; }
"import"   { registrar_token(yytext, num_linhas, col_token, 1); return T_IMPORT; }

"=="|"!="|"<"|">"|"<="|">=" {
    registrar_token(yytext, num_linhas, col_token, 1);
    return T_OP_REL;
}

"="        { registrar_token(yytext, num_linhas, col_token, 1); return T_ATRIB; }
"+"        { registrar_token(yytext, num_linhas, col_token, 1); return T_MAIS; }
"-"        { registrar_token(yytext, num_linhas, col_token, 1); return T_MENOS; }
"*"        { registrar_token(yytext, num_linhas, col_token, 1); return T_MULT; }
"/"        { registrar_token(yytext, num_linhas, col_token, 1); return T_DIV; }
":"        { registrar_token(yytext, num_linhas, col_token, 1); return T_DOIS_PONTOS; }
","        { registrar_token(yytext, num_linhas, col_token, 1); return T_VIRGULA; }
"("        { registrar_token(yytext, num_linhas, col_token, 1); return T_ABRE_PAR; }
")"        { registrar_token(yytext, num_linhas, col_token, 1); return T_FECHA_PAR; }

{NUMERO}+{LETRA}({LETRA}|{DIGITO})* {
    /* Erro léxico: identificador iniciado por número (ex: 1a) */
    registrar_token(yytext, num_linhas, col_token, 0);
}

{NUMERO} {
    registrar_token(yytext, num_linhas, col_token, 1);
    return T_NUMERO;
}

{NOME} {
    registrar_token(yytext, num_linhas, col_token, 1);
    return T_IDENTIFICADOR;
}

{TABULACAO} {
    registrar_token("<TAB>", num_linhas, col_token, 1);
    num_colunas += 3;
}

{NOVALINHA} {
    num_linhas++;
    num_colunas = 1;
    tabs_na_linha = 0;
    BEGIN(INDENT); /* Ao quebrar linha, avalia a indentação da próxima linha */
}

{ESPACO} {
    /* Ignorados */
}

<<EOF>> {
    /* Ao chegar no fim do arquivo, fecha quaisquer blocos que ainda estejam abertos */
    if (nivel_indent_atual > 0) {
        nivel_indent_atual--;
        return FIMDEBL;
    }
    return 0;
}

. {
    /* Captura todos os erros léxicos genéricos (incluindo { e }) */
    registrar_token(yytext, num_linhas, col_token, 0);
}
%%
