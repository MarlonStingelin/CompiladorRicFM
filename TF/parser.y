%{
/* ========================================================================== */
/* Analisador Sintático e Semântico (BISON) - Trabalho Final (Pythonhol)      */
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

/* ========================================================================== */
/* ERROS SINTÁTICOS                                                           */
/* ========================================================================== */

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
        return;
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
    fim_erros = NULL;
}

/* ========================================================================== */
/* TABELA DE SÍMBOLOS SEMÂNTICA E ERROS SEMÂNTICOS                            */
/* ========================================================================== */

#define SIMB_VAR    1
#define SIMB_FUNC   2
#define SIMB_PARAM  3
#define SIMB_MODULO 4

typedef struct SimboloSem {
    char *nome;
    int categoria;
    int escopo;
    double valor;
    struct SimboloSem *prox;
} SimboloSem;

SimboloSem *tabela_semantica = NULL;
int dentro_de_funcao = 0;
int escopo_atual = 0;

SimboloSem *buscar_no_escopo_atual(const char *nome) {
    SimboloSem *atual = tabela_semantica;
    while (atual != NULL) {
        if (atual->escopo == escopo_atual && strcmp(atual->nome, nome) == 0) {
            return atual;
        }
        atual = atual->prox;
    }
    return NULL;
}

SimboloSem *buscar_simbolo(const char *nome) {
    SimboloSem *simb = buscar_no_escopo_atual(nome);
    if (simb != NULL) {
        return simb;
    }
    if (escopo_atual != 0) {
        SimboloSem *atual = tabela_semantica;
        while (atual != NULL) {
            if (atual->escopo == 0 && strcmp(atual->nome, nome) == 0) {
                return atual;
            }
            atual = atual->prox;
        }
    }
    return NULL;
}

void inserir_simbolo(const char *nome, int categoria, int escopo, double valor) {
    SimboloSem *atual = tabela_semantica;
    while (atual != NULL) {
        if (atual->escopo == escopo && strcmp(atual->nome, nome) == 0) {
            atual->valor = valor;
            return;
        }
        atual = atual->prox;
    }

    SimboloSem *novo = (SimboloSem *)malloc(sizeof(SimboloSem));
    novo->nome = strdup(nome);
    novo->categoria = categoria;
    novo->escopo = escopo;
    novo->valor = valor;
    novo->prox = tabela_semantica;
    tabela_semantica = novo;
}

void limpar_escopo_local(void) {
    SimboloSem *atual = tabela_semantica;
    SimboloSem *anterior = NULL;
    while (atual != NULL) {
        if (atual->escopo == 1) {
            SimboloSem *remover = atual;
            atual = atual->prox;
            if (anterior == NULL) {
                tabela_semantica = atual;
            } else {
                anterior->prox = atual;
            }
            free(remover->nome);
            free(remover);
        } else {
            anterior = atual;
            atual = atual->prox;
        }
    }
}

void liberar_tabela_semantica(void) {
    SimboloSem *atual = tabela_semantica;
    while (atual != NULL) {
        SimboloSem *temp = atual;
        atual = atual->prox;
        free(temp->nome);
        free(temp);
    }
    tabela_semantica = NULL;
}

typedef struct ErroSemantico {
    int linha;
    int coluna;
    char *mensagem;
    struct ErroSemantico *prox;
} ErroSemantico;

ErroSemantico *lista_erros_sem = NULL;
ErroSemantico *fim_erros_sem = NULL;
int erros_semanticos = 0;

void registrar_erro_semantico(int linha, int coluna, const char *msg) {
    if (erros_semanticos >= 50) {
        return;
    }

    ErroSemantico *novo = (ErroSemantico *)malloc(sizeof(ErroSemantico));
    novo->linha = linha;
    novo->coluna = coluna;
    novo->mensagem = strdup(msg);
    novo->prox = NULL;

    if (lista_erros_sem == NULL) {
        lista_erros_sem = novo;
        fim_erros_sem = novo;
    } else {
        fim_erros_sem->prox = novo;
        fim_erros_sem = novo;
    }
    erros_semanticos++;
}

void imprimir_erros_semanticos(void) {
    ErroSemantico *atual = lista_erros_sem;
    int i = 1;
    while (atual != NULL) {
        printf("%s  #%02d%s | %s[Linha: %d, Coluna: %d]%s\n",
               COLOR_RED, i++, COLOR_RESET, COLOR_YELLOW, atual->linha, atual->coluna, COLOR_RESET);
        printf("      └─ %sDiagnóstico:%s   %s\n\n", COLOR_GRAY, COLOR_RESET, atual->mensagem);

        ErroSemantico *temp = atual;
        atual = atual->prox;
        free(temp->mensagem);
        free(temp);
    }
    lista_erros_sem = NULL;
    fim_erros_sem = NULL;
}
%}

/* Rastreamento preciso de linha/coluna por token e diagnóstico detalhado */
%locations
%define parse.error verbose

/* Valores semânticos vindos do FLEX */
%union {
    double dval;
    char *sval;
}

/* Declaração dos Tokens Terminais */
%token T_IF T_ELSE T_WHILE T_FOR T_IN T_DEF T_RETURN T_IMPORT
%token T_OP_REL
%token T_ATRIB T_MAIS T_MENOS T_MULT T_DIV
%token T_DOIS_PONTOS T_VIRGULA T_ABRE_PAR T_FECHA_PAR
%token <dval> T_NUMERO
%token <sval> T_IDENTIFICADOR
%token INIDEBL FIMDEBL

/* Não-terminais numéricos */
%type <dval> expressao termo fator

// Precedência de operadores para evitar conflitos shift/reduce
%left T_OP_REL
%left T_MAIS T_MENOS
%left T_MULT T_DIV

// Símbolo inicial da gramática
%start programa

%%
/* ========================================================================== */
/* REGRAS GRAMATICAIS E AÇÕES SEMÂNTICAS (BNF - Pythonhol)                    */
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
    }
    ;

atribuicao:
    T_IDENTIFICADOR T_ATRIB expressao {
        inserir_simbolo($1, SIMB_VAR, escopo_atual, $3);
        free($1);
    }
    ;

expressao:
    termo                     { $$ = $1; }
    | expressao T_MAIS termo  { $$ = $1 + $3; }
    | expressao T_MENOS termo { $$ = $1 - $3; }
    ;

termo:
    fator                     { $$ = $1; }
    | termo T_MULT fator      { $$ = $1 * $3; }
    | termo T_DIV fator {
        if ($3 == 0) {
            registrar_erro_semantico(@2.first_line, @2.first_column, "Divisao por zero detectada");
            $$ = 0;
        } else {
            $$ = $1 / $3;
        }
    }
    ;

fator:
    T_NUMERO { $$ = $1; }
    | T_IDENTIFICADOR {
        SimboloSem *simb = buscar_simbolo($1);
        if (simb == NULL) {
            char msg[256];
            snprintf(msg, sizeof(msg), "Variavel '%s' utilizada antes de ser declarada", $1);
            registrar_erro_semantico(@1.first_line, @1.first_column, msg);
            $$ = 0;
        } else {
            $$ = simb->valor;
        }
        free($1);
    }
    | T_ABRE_PAR expressao T_FECHA_PAR { $$ = $2; }
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
    T_FOR T_IDENTIFICADOR {
        inserir_simbolo($2, SIMB_VAR, escopo_atual, 1);
    } T_IN expressao T_DOIS_PONTOS bloco {
        free($2);
    }
    ;

funcao:
    T_DEF T_IDENTIFICADOR {
        inserir_simbolo($2, SIMB_FUNC, 0, 0);
        dentro_de_funcao = 1;
        escopo_atual = 1;
    } T_ABRE_PAR parametros_opt T_FECHA_PAR T_DOIS_PONTOS bloco {
        limpar_escopo_local();
        dentro_de_funcao = 0;
        escopo_atual = 0;
        free($2);
    }
    ;

parametros_opt:
    %empty
    | lista_parametros
    ;

lista_parametros:
    T_IDENTIFICADOR {
        if (buscar_no_escopo_atual($1) != NULL) {
            char msg[256];
            snprintf(msg, sizeof(msg), "Parametro '%s' duplicado na declaracao da funcao", $1);
            registrar_erro_semantico(@1.first_line, @1.first_column, msg);
        } else {
            inserir_simbolo($1, SIMB_PARAM, 1, 1);
        }
        free($1);
    }
    | lista_parametros T_VIRGULA T_IDENTIFICADOR {
        if (buscar_no_escopo_atual($3) != NULL) {
            char msg[256];
            snprintf(msg, sizeof(msg), "Parametro '%s' duplicado na declaracao da funcao", $3);
            registrar_erro_semantico(@3.first_line, @3.first_column, msg);
        } else {
            inserir_simbolo($3, SIMB_PARAM, 1, 1);
        }
        free($3);
    }
    ;

cmd_return:
    T_RETURN expressao {
        if (dentro_de_funcao == 0) {
            registrar_erro_semantico(@1.first_line, @1.first_column, "Comando 'return' utilizado fora de uma funcao");
        }
    }
    ;

cmd_import:
    T_IMPORT T_IDENTIFICADOR {
        inserir_simbolo($2, SIMB_MODULO, escopo_atual, 0);
        free($2);
    }
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

    printf("\n%s=== RELATORIO DE ANALISE SEMANTICA ===%s\n\n", COLOR_HEADER, COLOR_RESET);
    if (erros_semanticos == 0) {
        printf("%s✔ Sucesso: Nenhum erro semantico encontrado! As regras semanticas foram respeitadas.%s\n", COLOR_HEADER, COLOR_RESET);
    } else {
        printf("%s✖ Foram detectados %d erro(s) semantico(s):%s\n\n", COLOR_RED, erros_semanticos, COLOR_RESET);
        imprimir_erros_semanticos();
    }

    printf("\n%s=== RELATORIO DO ANALISADOR LEXICO (FLEX) ===%s\n", COLOR_HEADER, COLOR_RESET);
    printf("%s\nFormato das Posições: [Linha, Coluna]%s\n\n", COLOR_YELLOW, COLOR_RESET);
    imprimir_relatorio();
    printf("\n");

    liberar_tabela_semantica();
    liberar_memoria();
    if (yyin != stdin) fclose(yyin);
    return 0;
}
