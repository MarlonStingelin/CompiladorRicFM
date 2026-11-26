#ifndef JVM_H
#define JVM_H

/* Códigos dos operadores relacionais para emissão de desvios condicionais */
#define OP_EQ 1
#define OP_NE 2
#define OP_LT 3
#define OP_LE 4
#define OP_GT 5
#define OP_GE 6
#define OP_NZ 7

/* Alocação de slots locais (double ocupa 2 slots consecutivos), campos globais e rótulos */
int jvm_alocar_local(int escopo);
void jvm_declarar_campo_global(const char *nome);
int jvm_novo_rotulo(void);

/* Emissão de instruções JVM */
void jvm_emitir(const char *fmt, ...);
void jvm_emitir_rotulo(int lbl);
void jvm_emitir_constante_double(double val);
void jvm_emitir_desvio_falso(int op, int lbl);

/* Controle de métodos (def) */
void jvm_iniciar_funcao(void);
void jvm_registrar_parametro(void);
void jvm_finalizar_funcao(const char *nome);

/* Geração do arquivo .jvm e limpeza de memória */
void jvm_gerar_arquivo(const char *arquivo_entrada);
void jvm_liberar(void);

#endif /* JVM_H */
