# TF — Compilador Pythonhol

Compilador desenvolvido em C utilizando **FLEX** e **BISON** para uma gramática simplificada de Python (**Pythonhol**), cobrindo as etapas de análise léxica, sintática, semântica e geração de código bytecode para a **JVM** (`.jvm`).

## Equipe

- Guilherme Hoerning Reinert
- Marlon Stingelin Colaco

## Estrutura do Projeto

- `lexer.lex` — Analisador léxico (FLEX) com tabela de símbolos léxica, controle de indentação (`INIDEBL`/`FIMDEBL`) e contador global de erros léxicos (`erros_lexicos`).
- `parser.y` — Analisador sintático e semântico (BISON), tabela de símbolos semântica, bloqueio em cascata dos relatórios e integração com o gerador JVM.
- `jvm.h` / `jvm.c` — Módulo dedicado à geração de bytecode JVM (`.jvm`).
- `GeracaoJVM_run` — Script de compilação e execução da versão atual do compilador.
- `testeComErroLexico.py`, `testeComErroSintatico.py`, `testeComErroSemantico.py`, `testeSemErros.py`, `testeSemErros2.py` — Casos de teste para validação das fases.

## Compilação e Execução

### Usando o script de execução

```bash
chmod +x GeracaoJVM_run
./GeracaoJVM_run testeSemErros.py
```

Para executar lendo da entrada padrão (`stdin`, gerando `saida.jvm` se não houver erros):

```bash
./GeracaoJVM_run
```

### Compilação Manual

```bash
bison -d parser.y
flex lexer.lex
gcc parser.tab.c lex.yy.c jvm.c -o out -lm
```

Execução com arquivo de entrada:

```bash
./out testeSemErros.py
```

## Fluxo de Saída e Bloqueio em Cascata

Após o parsing, os relatórios são exibidos na ordem **Léxico → Sintático → Semântico → Geração JVM**, com travas em cascata:

1. **Se houver erros léxicos (`erros_lexicos > 0`):** exibe apenas o relatório léxico; omite sintático, semântico e não gera `.jvm`.
2. **Se não houver erros léxicos, mas houver erros sintáticos (`erros_sintaticos > 0`):** exibe os relatórios léxico e sintático; omite o semântico e não gera `.jvm`.
3. **Se não houver erros léxicos nem sintáticos:** exibe os três relatórios. O arquivo `.jvm` só é gerado se `erros_semanticos == 0`.

## Etapa 1 — Análise Léxica (`lexer.lex`)

- Reconhecimento de palavras-chave (`if`, `else`, `while`, `for`, `in`, `def`, `return`, `import`), operadores aritméticos e relacionais (`T_OP_REL`), separadores, números (`NUMERO`) e identificadores (`NOME`).
- Tabela de símbolos em lista encadeada ordenada alfabeticamente (`TokenNode`), agrupando coordenadas `[L, C]` e contagem de ocorrências.
- Controle de escopo por indentação (`%x INDENT`), gerando automaticamente `INIDEBL` e `FIMDEBL` (incluindo recuos múltiplos e fechamento em `<<EOF>>`).
- Detecção e contagem de erros léxicos (`erros_lexicos`) para identificadores iniciados por números (ex.: `1a`) e caracteres inválidos (ex.: `{`, `}`, `@`).

## Etapa 2 — Análise Sintática (`parser.y`)

- Gramática BNF com recursão à esquerda em `lista_comandos` para evitar estouro de pilha.
- Resolução de conflitos shift/reduce via declaração de precedência (`%left`).
- Diagnósticos detalhados com `%define parse.error verbose` e rastreamento preciso com `%locations`.
- Registro e exibição de erros sintáticos (`ErroSintatico`) em lista encadeada (linha, coluna, token lido e diagnóstico), com limite de segurança de 50 erros e proteção contra loop em EOF (`YYABORT`).

## Etapa 3 — Análise Semântica (`parser.y`)

Integração de valores e ações semânticas diretamente nas regras do BISON em conjunto com o FLEX, sem construção de AST, com foco na validação lógica e de escopo do código-fonte.

- **Passagem de valores (`%union` / `yylval`):** envio de valores numéricos (`double`), identificadores e operadores relacionais (`char*`) do FLEX para o BISON.
- **Tabela de Símbolos Semântica (`SimboloSem`):** controle de identificadores (variáveis, funções, parâmetros e módulos) com separação entre escopo global (`0`) e escopo local de funções (`1`), além do índice de variável local na JVM (`jvm_index`).
- **Validações semânticas (`ErroSemantico`):**
  - Uso de variável antes de ser declarada/atribuída.
  - Divisão por zero em expressões aritméticas.
  - Parâmetros duplicados na assinatura de funções (`def`).
  - Uso de `return` fora do escopo de uma função.
  - Registro automático da variável de iteração no `for` e de módulos no `import`.

## Etapa 4 — Geração de Código JVM (`jvm.h` e `jvm.c`)

Módulo separado responsável por acumular as instruções em memória durante o parsing e gravar o arquivo `.jvm` apenas quando a compilação termina sem erros em todas as fases.

- **Arquivo de saída:** gerado na mesma pasta de execução com o nome `<nome_base>.jvm` (ex.: `testeSemErros.py` → `testeSemErros.jvm`) ou `saida.jvm` quando lido via `stdin`.
- **Estrutura da classe:** cabeçalho `.class public Programa`, `.super java/lang/Object`, construtor `<init>()V`, método `main([Ljava/lang/String;)V` e métodos estáticos gerados para cada `def`.
- **Variáveis globais e locais (`double`):**
  - Variáveis do escopo global (`escopo == 0`) são declaradas como campos estáticos (`.field public static <nome> D`) e acessadas via `getstatic Programa/<nome> D` / `putstatic Programa/<nome> D`, permitindo leitura segura inclusive dentro de funções `def`.
  - Variáveis locais, parâmetros de funções (`escopo == 1`) e temporários do `for` ocupam **2 slots consecutivos** na JVM (`+2` por alocação), acessados via `dload <idx>` / `dstore <idx>`.
- **Instruções geradas:**
  - Constantes numéricas: `dconst_0`, `dconst_1` e `ldc2_w <valor>`.
  - Variáveis: `getstatic`/`putstatic` (globais) e `dload`/`dstore` (locais, parâmetros e temporários).
  - Aritmética: `dadd`, `dsub`, `dmul`, `ddiv`.
  - Controle de fluxo (`if`/`else`, `while`, `for`): `dcmpl`, desvios condicionais (`ifeq`, `ifne`, `iflt`, `ifle`, `ifgt`, `ifge`), `goto` e rótulos (`L0:`, `L1:`, ...).
  - Funções e retorno: `.method public static <nome>(D...)D`, `.limit stack`, `.limit locals`, `dreturn` (com fallback automático `dconst_0` + `dreturn` caso o método não termine diretamente em `dreturn`) e `return` no fim de `main`.

## Casos de Teste

| Arquivo | Cenário | Resultado Esperado |
| :--- | :--- | :--- |
| `testeComErroLexico.py` | Tokens inválidos (`1variavel_invalida`, `@`, `{`, `}`) | Exibe apenas o relatório léxico; não gera `.jvm`. |
| `testeComErroSintatico.py` | Expressão malformada (`10 + * 5`) e `if` sem `:` | Exibe relatórios léxico e sintático; omite semântico e não gera `.jvm`. |
| `testeComErroSemantico.py` | Variável não declarada, divisão por zero, parâmetro duplicado e `return` global | Exibe os 3 relatórios com 4 erros semânticos; não gera `.jvm`. |
| `testeSemErros.py` | Programa completo com `if`/`else`, `while`, `for` e `def` | Sucesso nas 3 análises e geração de `testeSemErros.jvm`. |
| `testeSemErros2.py` | Programa válido com `if`/`else`, `for` e `def` | Sucesso nas 3 análises e geração de `testeSemErros2.jvm`. |

## Gramática (simplificada) de Python — base para o TF

```c
<programa> ::= <lista_comandos>

<lista_comandos> ::= <comando>
            /* Alterado para usar recursão a esquerda */
            | <lista_comandos> <comando>

<comando> ::= <atribuicao>
            | <expressao>
            | <if>
            | <while>
            | <for>
            | <funcao>
            | <return>
            | <import>

<atribuicao> ::= <identificador> "=" <expressao>

<expressao> ::= <termo>
              | <expressao> "+" <termo>
              | <expressao> "-" <termo>

<termo> ::= <fator>
          | <termo> "*" <fator>
          | <termo> "/" <fator>

<fator> ::= <numero>
          | <identificador>
          | "(" <expressao> ")"

<if> ::= "if" <condicao> ":" <bloco>
       | "if" <condicao> ":" <bloco> "else" ":" <bloco>

<while> ::= "while" <condicao> ":" <bloco>

<for> ::= "for" <identificador> "in" <expressao> ":" <bloco>

<funcao> ::= "def" <identificador> "(" <parametros_opt> ")" ":" <bloco>

<parametros_opt> ::= ε
                   | <lista_parametros>

<lista_parametros> ::= <identificador>
                     | <lista_parametros> "," <identificador>

<return> ::= "return" <expressao>

<import> ::= "import" <identificador>

<condicao> ::= <expressao> <op_relacional> <expressao>
             | <expressao>

<op_relacional> ::= "=="
                  | "!="
                  | "<"
                  | ">"
                  | "<="
                  | ">="

<bloco> ::= INIDEBL <lista_comandos> FIMDEBL

<identificador> ::= NOME

<numero> ::= NUMERO
```

**Obs.**: Além dos terminais definidos de forma explícita (por exemplo: `"<="`, `"def"`, etc.), existem terminais com forma variada (`NUMERO`, `NOME`), bem como os tokens virtuais `INIDEBL` e `FIMDEBL`, que representam respectivamente o início de um bloco por indentação (tabulação) e o fechamento do bloco pelo recuo da indentação.
