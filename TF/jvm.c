/* ========================================================================== */
/* Gerador de Código Bytecode JVM (.jvm) - Trabalho Final (Pythonhol)         */
/* ========================================================================== */
#include "jvm.h"

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define JVM_COLOR_RESET  "\033[0m"
#define JVM_COLOR_HEADER "\033[1;32m"
#define JVM_COLOR_RED    "\033[1;31m"

typedef struct LinhaJVM {
    char *texto;
    struct LinhaJVM *prox;
} LinhaJVM;

typedef struct BufferJVM {
    LinhaJVM *inicio;
    LinhaJVM *fim;
} BufferJVM;

static BufferJVM codigo_campos = {NULL, NULL};
static BufferJVM codigo_main = {NULL, NULL};
static BufferJVM codigo_funcoes = {NULL, NULL};
static BufferJVM codigo_func_atual = {NULL, NULL};

/* Controle de índices locais da JVM (double ocupa 2 slots consecutivos) */
static int prox_local_main = 1; /* slot 0 reservado para String[] args */
static int prox_local_func = 0;
static int num_params_atual = 0;
static int em_funcao = 0;
static int contador_rotulos = 0;

static void adicionar_linha_buffer(BufferJVM *buf, const char *texto) {
    LinhaJVM *nova = (LinhaJVM *)malloc(sizeof(LinhaJVM));
    nova->texto = strdup(texto);
    nova->prox = NULL;
    if (buf->inicio == NULL) {
        buf->inicio = nova;
        buf->fim = nova;
    } else {
        buf->fim->prox = nova;
        buf->fim = nova;
    }
}

static void limpar_buffer(BufferJVM *buf) {
    LinhaJVM *atual = buf->inicio;
    while (atual != NULL) {
        LinhaJVM *temp = atual;
        atual = atual->prox;
        free(temp->texto);
        free(temp);
    }
    buf->inicio = NULL;
    buf->fim = NULL;
}

int jvm_alocar_local(int escopo) {
    int idx;
    if (escopo == 0) {
        idx = prox_local_main;
        prox_local_main += 2;
    } else {
        idx = prox_local_func;
        prox_local_func += 2;
    }
    return idx;
}

void jvm_declarar_campo_global(const char *nome) {
    char linha[512];
    snprintf(linha, sizeof(linha), ".field public static %s D", nome);
    adicionar_linha_buffer(&codigo_campos, linha);
}

int jvm_novo_rotulo(void) {
    return contador_rotulos++;
}

void jvm_emitir(const char *fmt, ...) {
    char linha[512];
    va_list args;
    va_start(args, fmt);
    vsnprintf(linha, sizeof(linha), fmt, args);
    va_end(args);

    BufferJVM *alvo = em_funcao ? &codigo_func_atual : &codigo_main;
    adicionar_linha_buffer(alvo, linha);
}

void jvm_emitir_rotulo(int lbl) {
    jvm_emitir("L%d:", lbl);
}

void jvm_emitir_constante_double(double val) {
    if (val == 0.0) {
        jvm_emitir("    dconst_0");
    } else if (val == 1.0) {
        jvm_emitir("    dconst_1");
    } else {
        char num_str[64];
        snprintf(num_str, sizeof(num_str), "%.15g", val);
        if (strchr(num_str, '.') == NULL &&
            strchr(num_str, 'e') == NULL &&
            strchr(num_str, 'E') == NULL) {
            strncat(num_str, ".0", sizeof(num_str) - strlen(num_str) - 1);
        }
        jvm_emitir("    ldc2_w %s", num_str);
    }
}

void jvm_emitir_desvio_falso(int op, int lbl) {
    switch (op) {
        case OP_EQ: jvm_emitir("    ifne L%d", lbl); break;
        case OP_NE: jvm_emitir("    ifeq L%d", lbl); break;
        case OP_LT: jvm_emitir("    ifge L%d", lbl); break;
        case OP_LE: jvm_emitir("    ifgt L%d", lbl); break;
        case OP_GT: jvm_emitir("    ifle L%d", lbl); break;
        case OP_GE: jvm_emitir("    iflt L%d", lbl); break;
        case OP_NZ: jvm_emitir("    ifeq L%d", lbl); break;
        default:    jvm_emitir("    ifeq L%d", lbl); break;
    }
}

void jvm_iniciar_funcao(void) {
    limpar_buffer(&codigo_func_atual);
    prox_local_func = 0;
    num_params_atual = 0;
    em_funcao = 1;
}

void jvm_registrar_parametro(void) {
    num_params_atual++;
}

void jvm_finalizar_funcao(const char *nome) {
    char cabecalho[512];
    char assinatura[256];
    int i;
    int max_params = num_params_atual < 250 ? num_params_atual : 250;

    for (i = 0; i < max_params; i++) {
        assinatura[i] = 'D';
    }
    assinatura[max_params] = '\0';

    adicionar_linha_buffer(&codigo_funcoes, "");
    snprintf(cabecalho, sizeof(cabecalho), ".method public static %s(%s)D", nome, assinatura);
    adicionar_linha_buffer(&codigo_funcoes, cabecalho);
    adicionar_linha_buffer(&codigo_funcoes, "    .limit stack 64");
    snprintf(cabecalho, sizeof(cabecalho), "    .limit locals %d", prox_local_func > 0 ? prox_local_func : 2);
    adicionar_linha_buffer(&codigo_funcoes, cabecalho);

    LinhaJVM *atual = codigo_func_atual.inicio;
    while (atual != NULL) {
        adicionar_linha_buffer(&codigo_funcoes, atual->texto);
        atual = atual->prox;
    }

    /* Garante retorno válido na JVM mesmo quando há return apenas em ramo condicional */
    if (codigo_func_atual.fim == NULL ||
        strcmp(codigo_func_atual.fim->texto, "    dreturn") != 0) {
        adicionar_linha_buffer(&codigo_funcoes, "    dconst_0");
        adicionar_linha_buffer(&codigo_funcoes, "    dreturn");
    }
    adicionar_linha_buffer(&codigo_funcoes, ".end method");

    limpar_buffer(&codigo_func_atual);
    em_funcao = 0;
}

void jvm_liberar(void) {
    limpar_buffer(&codigo_campos);
    limpar_buffer(&codigo_main);
    limpar_buffer(&codigo_funcoes);
    limpar_buffer(&codigo_func_atual);
}

void jvm_gerar_arquivo(const char *arquivo_entrada) {
    char nome_saida[512];
    if (arquivo_entrada != NULL && arquivo_entrada[0] != '\0') {
        const char *base = strrchr(arquivo_entrada, '/');
        const char *base_win = strrchr(arquivo_entrada, '\\');
        if (base_win != NULL && (base == NULL || base_win > base)) {
            base = base_win;
        }
        base = (base != NULL) ? base + 1 : arquivo_entrada;

        const char *ponto = strrchr(base, '.');
        size_t len_base = (ponto != NULL && ponto != base) ? (size_t)(ponto - base) : strlen(base);
        if (len_base > sizeof(nome_saida) - 5) {
            len_base = sizeof(nome_saida) - 5;
        }
        memcpy(nome_saida, base, len_base);
        memcpy(nome_saida + len_base, ".jvm", 5);
    } else {
        snprintf(nome_saida, sizeof(nome_saida), "saida.jvm");
    }

    FILE *out = fopen(nome_saida, "w");
    if (!out) {
        fprintf(stderr, "%sErro:%s Nao foi possivel criar o arquivo '%s'.\n",
                JVM_COLOR_RED, JVM_COLOR_RESET, nome_saida);
        return;
    }

    fprintf(out, ".class public Programa\n");
    fprintf(out, ".super java/lang/Object\n\n");

    if (codigo_campos.inicio != NULL) {
        LinhaJVM *campo = codigo_campos.inicio;
        while (campo != NULL) {
            fprintf(out, "%s\n", campo->texto);
            campo = campo->prox;
        }
        fprintf(out, "\n");
    }

    fprintf(out, ".method public <init>()V\n");
    fprintf(out, "    aload_0\n");
    fprintf(out, "    invokespecial java/lang/Object/<init>()V\n");
    fprintf(out, "    return\n");
    fprintf(out, ".end method\n\n");

    fprintf(out, ".method public static main([Ljava/lang/String;)V\n");
    fprintf(out, "    .limit stack 64\n");
    fprintf(out, "    .limit locals %d\n", prox_local_main);

    LinhaJVM *atual = codigo_main.inicio;
    while (atual != NULL) {
        fprintf(out, "%s\n", atual->texto);
        atual = atual->prox;
    }

    fprintf(out, "    return\n");
    fprintf(out, ".end method\n");

    atual = codigo_funcoes.inicio;
    while (atual != NULL) {
        fprintf(out, "%s\n", atual->texto);
        atual = atual->prox;
    }

    fclose(out);

    printf("\n%s=== GERACAO DE CODIGO (JVM) ===%s\n\n", JVM_COLOR_HEADER, JVM_COLOR_RESET);
    printf("%s✔ Sucesso: Arquivo '%s' gerado com sucesso!%s\n", JVM_COLOR_HEADER, nome_saida, JVM_COLOR_RESET);
}
