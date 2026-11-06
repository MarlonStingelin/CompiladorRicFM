%{
/* ========================================================================== */
/* Analisador Sintático (BISON) - Trabalho Final (Pythonhol)        */
/* ========================================================================== */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Variáveis e funções vindas do Analisador Léxico (FLEX) */
extern int num_linhas;
extern int col_token;
extern char *yytext;
extern FILE *yyin;

int yylex(void);
void yyerror(const char *s);
void imprimir_relatorio(void);
void liberar_memoria(void);

/* Paleta de Cores ANSI Pré-declaradas */
#define COLOR_RESET "\033[0m"
#define COLOR_HEADER "\033[1;32m" /* Verde Negrito */
#define COLOR_RED "\033[1;31m"     /* Vermelho Negrito */
#define COLOR_YELLOW "\033[1;33m" /* Amarelo Negrito */
#define COLOR_GRAY "\033[90m"     /* Cinza Escuro */

/* Estrutura para armazenar e visualizar os Erros Sintáticos */
typedef struct ErroSintatico {
    int linha;
    int coluna;
    char *token;
    char *mensagem;
    struct ErroSintatico *prox;
} ErroSintatico;

ErroSintatico *lista_erros = NULL;
ErroSintatico *fim_erros = NULL;
int erros_sintaticos = 0;

void registrar_erro_sintatico(int linha, int coluna, const char *token, const char *msg) {
    /* Trava de segurança: impede que um loop infinito consuma a RAM do PC */
    if (erros_sintaticos >= 50) {
        fprintf(stderr, "\n\033[1;31m[ABORTADO] Limite de 50 erros sintaticos atingido (evitando travamento de memoria).\033[0m\n");
        exit(1);
    }

    ErroSintatico *novo = (ErroSintatico *)malloc(sizeof(ErroSintatico));
    novo->linha = linha;
    novo->coluna = coluna;
    novo->token = strdup(token && strlen(token) > 0 ? token : "EOF (Fim de Arquivo)");
    novo->mensagem = strdup(msg);
    novo->prox = NULL;

    if (lista_erros == NULL) {
        lista_erros = novo;
        fim_erros = novo;
    } else {
        fim_erros->prox = novo;
        fim_erros = novo;
    }
    erros_sintaticos++;
}

void imprimir_erros_sintaticos(void) {
    ErroSintatico *atual = lista_erros;
    int i = 1;
    while (atual != NULL) {
        printf("%s  #%02d%s | %s[Linha: %d, Coluna: %d]%s\n", 
               COLOR_RED, i++, COLOR_RESET, COLOR_YELLOW, atual->linha, atual->coluna, COLOR_RESET);
        printf("      ├─ %sToken lido:%s    '%s'\n", COLOR_GRAY, COLOR_RESET, atual->token);
        printf("      └─ %sDiagnóstico:%s   %s\n\n", COLOR_GRAY, COLOR_RESET, atual->mensagem);
        
        ErroSintatico *temp = atual;
        atual = atual->prox;
        free(temp->token);
        free(temp->mensagem);
        free(temp);
    }
    lista_erros = NULL;
}
%}

/* Melhoria no diagnóstico de erros sintáticos */
%define parse.error verbose
%define parse.lac full

/* Declaração dos Tokens Terminais */
%token T_IF T_ELSE T_WHILE T_FOR T_IN T_DEF T_RETURN T_IMPORT
%token T_OP_REL
%token T_ATRIB T_MAIS T_MENOS T_MULT T_DIV
%token T_DOIS_PONTOS T_VIRGULA T_ABRE_PAR T_FECHA_PAR
%token T_NUMERO T_IDENTIFICADOR
%token INIDEBL FIMDEBL

// Precedência de operadores para evitar conflitos shift/reduce 
%left T_OP_REL
%left T_MAIS T_MENOS
%left T_MULT T_DIV

// Símbolo inicial da gramática 
%start programa

%%
/* ========================================================================== */
/* REGRAS GRAMATICAIS (BNF - Pythonhol)                             */
/* ========================================================================== */

programa:
    lista_comandos
    ;

lista_comandos:
    comando
    /* Escrito usando recursão a esquerda */
    | lista_comandos comando
    ;

comando:
    atribuicao
    | expressao
    | cmd_if
    | cmd_while
    | cmd_for
    | funcao
    | cmd_return
    | cmd_import
    | error {
        /* Se chegou no fim do arquivo (0 ou YYEOF), encerra o parser */
        if (yychar <= 0) YYABORT;
        /* Descarta o token atual para obrigar o parser a avançar */
        yyclearin;
        yyerrok;
    }
    ;

atribuicao:
    T_IDENTIFICADOR T_ATRIB expressao
    ;

expressao:
    termo
    | expressao T_MAIS termo
    | expressao T_MENOS termo
    ;

termo:
    fator
    | termo T_MULT fator
    | termo T_DIV fator
    ;

fator:
    T_NUMERO
    | T_IDENTIFICADOR
    | T_ABRE_PAR expressao T_FECHA_PAR
    ;

condicao:
    expressao op_relacional expressao
    | expressao
    ;

op_relacional:
    T_OP_REL
    ;

bloco:
    INIDEBL lista_comandos FIMDEBL
    ;

cmd_if:
    T_IF condicao T_DOIS_PONTOS bloco
    | T_IF condicao T_DOIS_PONTOS bloco T_ELSE T_DOIS_PONTOS bloco
    ;

cmd_while:
    T_WHILE condicao T_DOIS_PONTOS bloco
    ;

cmd_for:
    T_FOR T_IDENTIFICADOR T_IN expressao T_DOIS_PONTOS bloco
    ;

funcao:
    T_DEF T_IDENTIFICADOR T_ABRE_PAR parametros_opt T_FECHA_PAR T_DOIS_PONTOS bloco
    ;

parametros_opt:
    %empty
    | lista_parametros
    ;

lista_parametros:
    T_IDENTIFICADOR
    | T_IDENTIFICADOR T_VIRGULA lista_parametros
    ;

cmd_return:
    T_RETURN expressao
    ;

cmd_import:
    T_IMPORT T_IDENTIFICADOR
    ;

%%
/* ========================================================================== */
/* CÓDIGOS ESPECÍFICOS (TRATAMENTO DE ERROS E MAIN)                           */
/* ========================================================================== */

void yyerror(const char *s) {
    registrar_erro_sintatico(num_linhas, col_token, yytext, s);
}

int main(int argc, char **argv) {
    ++argv, --argc;
    if (argc > 0) {
        yyin = fopen(argv[0], "r");
        if (!yyin) {
            fprintf(stderr, "%sErro:%s Nao foi possivel abrir o arquivo '%s'.\n", COLOR_RED, COLOR_RESET, argv[0]);
            return 1;
        }
    } else {
        yyin = stdin;
    }

    yyparse();

    printf("\n%s=== RELATORIO DE ANALISE SINTATICA (BISON) ===%s\n\n", COLOR_HEADER, COLOR_RESET);
    if (erros_sintaticos == 0) {
        printf("%s✔ Sucesso: Nenhum erro sintatico encontrado! A estrutura respeita a gramatica.%s\n", COLOR_HEADER, COLOR_RESET);
    } else {
        printf("%s✖ Foram detectados %d erro(s) sintatico(s) na estrutura:%s\n\n", COLOR_RED, erros_sintaticos, COLOR_RESET);
        imprimir_erros_sintaticos();
    }

    printf("\n%s=== RELATORIO DO ANALISADOR LEXICO (FLEX) ===%s\n", COLOR_HEADER, COLOR_RESET);
    printf("%s\nFormato das Posições: [Linha, Coluna]%s\n\n", COLOR_YELLOW, COLOR_RESET);
    imprimir_relatorio();
    printf("\n");

    liberar_memoria();
    if (yyin != stdin) fclose(yyin);
    return 0;
}
