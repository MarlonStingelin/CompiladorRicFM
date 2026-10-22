# TF

## Equipe

- Guilherme Hoerning Reinert
- Marlon Stingelin Colaco

## Compilação

```bash
chmod 700 run
./run
```

```bash
clear && ./run
```

## Etapa 1 - Arquivo FLEX

**Data**: Não estabelecida.

### Entrega

**Data**: 22/11/2026

## Etapa 2 -  Primeiros Resultados - FLEX + BISON

Apresentar os primeiros resultados obtidos para a combinação FLEX + BISON. O foco está na somatória de resultados do FLEX e do BISON, ou seja, que vocês sejam capazes de escrever um código, considerado a linguagem alvo (do TF), e o resultado esperado do compilador está na apresentação de erros léxicos e sintáticos.

**IMPORTANTE**: irei considerar a assertividade, quanto as informações relacionadas com os erros apontados, e se todos eles estão sendo identificados.

### Entrega

Arquivos esperados: FLEX (arquivo `.lex`) e BISON (`.y`). Também deve ser entregue um conjunto de códigos, escritos na linguagem alvo do trabalho, e que permitirão avaliar o desempenho alcançado.


## Gramática (simplificada) de Python - base para o TF

```c
<programa> ::= <lista_comandos>

<lista_comandos> ::= <comando> | <comando> <lista_comandos>

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

<funcao> ::= "def" <identificador> "(" <parametros> ")" ":" <bloco>

<parametros> ::= ε
               | <identificador>
               | <identificador> "," <parametros>

<return> ::= "return"
           | "return" <expressao>

<condicao> ::= <expressao> <op_relacional> <expressao>

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

**Obs.**: Além dos terminais definidos, de forma explícita (por exemplo: "<=", "def", etc.), existem terminais que possuem forma "variada" (NUMERO, NOME), bem como aqueles que tem um nome, para facilitar o entendimento (INIDEBL e FIMDEBL, que representam o início e fim de um bloco de comandos, através de uma INDENTAÇÃO, e o final de um bloco de comandos, com o recuo de uma INDENTAÇÃO, respectivamente).

Resumindo... INIDEBL = uma TABULAÇÃO e FIMDEBL = recuo de uma TABULAÇÃO.
