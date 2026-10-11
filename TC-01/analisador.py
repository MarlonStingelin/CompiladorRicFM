import sys, os

EPSILON = 'ε'
EOF = '$'

def ler_gramatica(caminho_ficheiro):
    producoes = {}
    nao_terminais = []
    simbolo_inicial = None
    
    with open(caminho_ficheiro, 'r', encoding='utf-8') as f:
        linhas = f.readlines()
        
    for linha in linhas:
        linha = linha.strip()
        if not linha or linha.startswith('#'): continue
        
        # Aceitar tanto '->' quanto '::=' como delimitadores
        if '->' in linha:
            esq, dir = linha.split('->')
        elif '::=' in linha:
            esq, dir = linha.split('::=')
        else:
            continue
            
        nt = esq.strip()
        if not simbolo_inicial:
            simbolo_inicial = nt
        if nt not in nao_terminais:
            nao_terminais.append(nt)
            producoes[nt] = []
            
        # Regras separadas por '|'
        regras = dir.split('|')
        for regra in regras:
            # Separar os símbolos por espaço
            simbolos = regra.strip().split()
            # Representações do epsilon
            simbolos = [EPSILON if s.lower() in ['epsilon', 'ε', "''", '""', 'vazio', "null"] else s for s in simbolos]
            if not simbolos:
                simbolos = [EPSILON]
            producoes[nt].append(simbolos)
            
    # Identificar terminais 
    terminais = set()
    for nt, regras in producoes.items():
        for regra in regras:
            for s in regra:
                if s not in nao_terminais and s != EPSILON:
                    terminais.add(s)
                    
    return set(terminais), set(nao_terminais), producoes, simbolo_inicial

def calcular_tabfirst(nao_terminais, terminais, producoes):
    # TERMINAIS
    # SE X é um símbolo terminal, ENTÃO FIRST(X) = { X }.
    tabfirst = {nt: set() for nt in nao_terminais}
    modificado = True
    while modificado:
        modificado = False  
        for nt in nao_terminais:
            for regra in producoes[nt]:
                tamanho_antes = len(tabfirst[nt])
                # CADEIA VAZIA
                # SE houver uma produção X -> ε, adicione ε a FIRST(X).
                if regra == [EPSILON]:
                    tabfirst[nt].add(EPSILON)
                else:
                    # NÃO-TERMINAIS
                    # ADICIONE todos os símbolos de FIRST(Y1) (exceto ε) a FIRST(X).
                    # SE Y1 pode derivar ε (ou seja ε pertence a FIRST(Y1)), adicione também os elementos de FIRST(Y2) (exceto ε), 
                    # e continue esse processo para Y3, Y4, etc..., até encontrar um símbolo Yi que não contenha ε.
                    # SE todos os símbolos da produção (Y1 até Yk) contiverem ε em seus conjuntos FIRST, adicione ε a FIRST(X).
                    for i, simb in enumerate(regra):
                        if simb in terminais:
                            tabfirst[nt].add(simb)
                            break
                        elif simb in nao_terminais:
                            first_simb = tabfirst[simb]
                            tabfirst[nt].update(first_simb - {EPSILON})
                            if EPSILON not in first_simb:
                                break
                        else:
                            break
                    else:
                        # SE passou por todos os símbolos e todos derivam ε.
                        tabfirst[nt].add(EPSILON)
                        
                if len(tabfirst[nt]) > tamanho_antes:
                    modificado = True
    return tabfirst

def first_cadeia(X, tabfirst, terminais):
    F = set()
    if not X or X == [EPSILON] or X == EPSILON:
        F.add(EPSILON)
        return F
        
    if isinstance(X, str):
        X = [X]
        
    for Xi in X:
        first_xi = {Xi} if Xi in terminais else set(tabfirst.get(Xi, set()))
        F.update(first_xi - {EPSILON})
        if EPSILON not in first_xi:
            break
    else:
        F.add(EPSILON)
        
    return F

def calcular_follow(terminais, nao_terminais, producoes, simbolo_inicial, tabfirst):
    # SÍMBOLO INICIAL
    # Se S é o símbolo inicial, adicione o marcador $ a FOLLOW(S).
    tabfollow = {X: set() for X in nao_terminais}
    tabfollow[simbolo_inicial].add(EOF)
    
    # NÃO-TERMINAIS β α
    # SE houver uma produção onde B é seguido por β (ou seja, A -> αBβ), todos ou terminais FIRST(β) (exceto ε) entram no FOLLOW(B).
    for Y, regras in producoes.items():
        for regra in regras:
            for indice_X, X in enumerate(regra):
                if X in nao_terminais:
                    if indice_X + 1 < len(regra):
                        beta = regra[indice_X + 1:]
                        first_beta = first_cadeia(beta, tabfirst, terminais)
                        tabfollow[X].update(first_beta - {EPSILON})
                        
    # FIM DE PRODUÇÃO
    # SE B é o último símbolo da produção (A -> αB), ou se B é seguido por um β cuja FIRST(β) contém ε,
    # então tudo o que está em FOLLOW(A) é adicionando a FOLLOW(B). 
    modificado = True
    while modificado:
        modificado = False
        estado_anterior = {k: set(v) for k, v in tabfollow.items()}
        
        for X, regras in producoes.items():
            for regra in regras:
                if regra == [EPSILON]:
                    continue
                i = len(regra)
                while i > 0:
                    i -= 1
                    Yi = regra[i]
                    if Yi in nao_terminais:
                        tabfollow[Yi].update(tabfollow[X])
                    if Yi not in nao_terminais or EPSILON not in tabfirst.get(Yi, set()):
                        break
                        
        for k in tabfollow:
            if tabfollow[k] != estado_anterior[k]:
                modificado = True
                break
                
    return tabfollow

def main():
    if len(sys.argv) < 3:
        print("Uso incorreto.")
        print("Execute: python analisador.py <entrada.txt> <saida.txt>")
        sys.exit(1)
        
    entrada = sys.argv[1]
    saida = sys.argv[2]
    
    if not os.path.exists(entrada):
        print(f"Erro: O ficheiro '{entrada}' não foi encontrado.")
        sys.exit(1)
        
    try:
        terminais, nao_terminais, producoes, simbolo_inicial = ler_gramatica(entrada)
        tabfirst = calcular_tabfirst(nao_terminais, terminais, producoes)
        tabfollow = calcular_follow(terminais, nao_terminais, producoes, simbolo_inicial, tabfirst)
        
        with open(saida, 'w', encoding='utf-8') as f:
            f.write("=== CONJUNTOS FIRST ===\n")
            for nt in sorted(nao_terminais):
                conjunto = ", ".join(sorted(tabfirst[nt]))
                f.write(f"FIRST({nt}) = {{ {conjunto} }}\n")
                
            f.write("\n=== CONJUNTOS FOLLOW ===\n")
            for nt in sorted(nao_terminais):
                conjunto = ", ".join(sorted(tabfollow[nt]))
                f.write(f"FOLLOW({nt}) = {{ {conjunto} }}\n")
                
        print(f"Sucesso! Os conjuntos foram calculados e guardados em '{saida}'.")
        
    except Exception as e:
        print(f"Ocorreu um erro ao processar a gramática: {str(e)}")

if __name__ == "__main__":
    main()
