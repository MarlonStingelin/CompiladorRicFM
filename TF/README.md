# TF

## Equipe

- Guilherme Hoerning Reinert
- Marlon Stingelin Colaco

## Entrega

**Data**: 22/11/2026

### Arquivo FLEX

**Data**: Não estabelecida.

## Compilação

```bash
chmod 700 run
./run
```

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
