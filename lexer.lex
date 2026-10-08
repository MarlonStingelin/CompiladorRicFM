%{
/* ========================================================================== */
/* Analisador Léxico                                                          */
/* ========================================================================== */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Controle de posição */
int num_linhas = 1;
int num_colunas = 1;
int col_token = 1; 

#define YY_USER_ACTION \
    col_token = num_colunas; \
    num_colunas += yyleng;

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
    printf("[Linha: %d, Coluna: %d] Palavra-chave: %s\n", num_linhas, col_token, yytext);
}

"=="|"!="|"<"|">"|"<="|">=" {
    printf("[Linha: %d, Coluna: %d] Operador Relacional: %s\n", num_linhas, col_token, yytext);
}

"="|"+"|"-"|"*"|"/"|":"|","|"("|")" {
    printf("[Linha: %d, Coluna: %d] Operador/Separador: %s\n", num_linhas, col_token, yytext);
}

{NUMERO} {
    printf("[Linha: %d, Coluna: %d] Numero: %s\n", num_linhas, col_token, yytext);
}

{NOME} {
    printf("[Linha: %d, Coluna: %d] Identificador (NOME): %s\n", num_linhas, col_token, yytext);
}

{TABULACAO} {
    printf("[Linha: %d, Coluna: %d] TABULACAO (Indentacao) identificada\n", num_linhas, col_token);
    num_colunas += 3; 
}

{NOVALINHA} {
    num_linhas++;
    num_colunas = 1; // Reset Cont da coluna, ao pular linha
}

{ESPACO} {

}

"{"|"}" {
    printf("\033[1;33m[Linha: %d, Coluna: %d] Aviso lexico:\033[0m '%s' não seram reconehcidos como identificadores \n", num_linhas, col_token, yytext);   
}

{NUMERO}({LETRA}|{DIGITO})+ { 
    printf("\033[1;31m[Linha: %d, Coluna: %d] Erro lexico: Identificador mal formado '%s' \033[0m \n", num_linhas, col_token, yytext);
    printf("\033[1;31m Nomes não podem iniciar com números e Números não podem ter letras \033[0m \n");
}

. {
    printf("\033[1;31m[Linha: %d, Coluna: %d] Erro lexico:\033[0m Caracter '%s' nao reconhecido\n", num_linhas, col_token, yytext);
}

%%
/* ========================================================================== */
/* Main                                                                    */
/* ========================================================================== */

int main(int argc, char **argv) {
    const char *COLOR_RESET = "\033[0m";
    const char *COLOR_HEADER = "\033[1;32m";

    printf("%s=== ANALISADOR LEXICO - TF PYTHON ===%s\n\n", COLOR_HEADER, COLOR_RESET);

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

    printf("\n%s=== RELATORIO FINAL ===%s\n", COLOR_HEADER, COLOR_RESET);
    printf("- Total de linhas processadas: %d\n", num_linhas);
    printf("\n");
    
    if (yyin != stdin) fclose(yyin);
    return 0;
}

