%{
/* ========================================================================== */
/* Analisador Léxico - Trabalho Final (Gramática Python Simplificada)         */
/* ========================================================================== */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Variáveis para controle de posição */
int num_linhas = 1;
int num_colunas = 1;
int col_token = 1;

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
    Posicao *pos_inicio;
    Posicao *pos_fim;
    struct TokenNode *prox;
} TokenNode;

TokenNode *tabela_simbolos = NULL;

/* Insere o token mantendo a lista em ordem alfabética */
void registrar_token(const char *lexema, int linha, int coluna) {
    TokenNode *atual = tabela_simbolos;
    TokenNode *anterior = NULL;

    /* Busca se o token já existe */
    while (atual != NULL) {
        int cmp = strcmp(atual->lexema, lexema);
        if (cmp == 0) {
            /* Já existe: incrementa e adiciona a nova posição no fim da fila */
            atual->contagem++;
            Posicao *nova_pos = (Posicao *)malloc(sizeof(Posicao));
            nova_pos->linha = linha;
            nova_pos->coluna = coluna;
            nova_pos->prox = NULL;
            
            atual->pos_fim->prox = nova_pos;
            atual->pos_fim = nova_pos;
            return;
        } else if (cmp > 0) {
            /* Passou do ponto de inserção alfabética, quebra para inserir aqui */
            break;
        }
        anterior = atual;
        atual = atual->prox;
    }

    /* Não encontrou: cria um novo nó (Token inédito) */
    TokenNode *novo_no = (TokenNode *)malloc(sizeof(TokenNode));
    novo_no->lexema = strdup(lexema);
    novo_no->contagem = 1;
    
    Posicao *nova_pos = (Posicao *)malloc(sizeof(Posicao));
    nova_pos->linha = linha;
    nova_pos->coluna = coluna;
    nova_pos->prox = NULL;
    
    novo_no->pos_inicio = nova_pos;
    novo_no->pos_fim = nova_pos;
    
    /* Reposiciona os ponteiros para manter a ordem alfabética */
    novo_no->prox = atual;
    if (anterior == NULL) {
        tabela_simbolos = novo_no;
    } else {
        anterior->prox = novo_no;
    }
}

/* Função que processa a saída no formato exato solicitado */
void imprimir_relatorio() {
    TokenNode *atual = tabela_simbolos;
    while (atual != NULL) {
    printf("\033[94m\"%s\"\033[0m Reconhecido em: ", atual->lexema);
        Posicao *p = atual->pos_inicio;
        while (p != NULL) {
            printf("[L:%d, C:%d]", p->linha, p->coluna);
            if (p->prox != NULL) printf(", ");
            p = p->prox;
        }
        printf(" Aparece \"%d\" vezes na entrada.\n", atual->contagem);
        atual = atual->prox;
    }
}

/* Firula 9: Previne memory leak limpando a estrutura inteira */
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
}
%}

%option noyywrap

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

"if"|"else"|"while"|"for"|"in"|"def"|"return"|"import" {
    registrar_token(yytext, num_linhas, col_token);
}

"=="|"!="|"<"|">"|"<="|">=" {
    registrar_token(yytext, num_linhas, col_token);
}

"="|"+"|"-"|"*"|"/"|":"|","|"("|")" {
    registrar_token(yytext, num_linhas, col_token);
}

{NUMERO}({LETRA}|{DIGITO})+ {
    registrar_token(yytext, num_linhas, col_token);
}

{NUMERO} {
    registrar_token(yytext, num_linhas, col_token);
}

{NOME} {
    registrar_token(yytext, num_linhas, col_token);
}

{TABULACAO} {
    registrar_token("<TAB>", num_linhas, col_token);
    num_colunas += 3;
}

{NOVALINHA} {
    num_linhas++;
    num_colunas = 1;
}

{ESPACO} {
    /* Ignorados */
}

. {
    /* Captura todos os erros genéricos, incluindo as chaves { e } */
    registrar_token(yytext, num_linhas, col_token);
}

%%
/* ========================================================================== */
/* CÓDIGOS ESPECÍFICOS (MAIN)                                                 */
/* ========================================================================== */

int main(int argc, char **argv) {
    ++argv, --argc;
    if (argc > 0) {
        yyin = fopen(argv[0], "r");
        if (!yyin) {
            fprintf(stderr, "Erro: Nao foi possivel abrir o arquivo '%s'.\n", argv[0]);
            return 1;
        }
    } else {
        yyin = stdin;
    }

    yylex();

    const char *COLOR_RESET = "\033[0m";
    const char *COLOR_HEADER = "\033[1;32m";

    printf("\n%s=== ANALISADOR LEXICO ===%s\n", COLOR_HEADER, COLOR_RESET);
    printf("\033[1;33m Formato das Posições: [Linha:\"L1\". Coluna:\"C1\"], ..., [Linha:\"Ln\". Coluna:\"Cn\"] \033[0m \n\n");
    imprimir_relatorio();
    printf("\n");

    liberar_memoria();
    
    if (yyin != stdin) fclose(yyin);
    return 0;
}
