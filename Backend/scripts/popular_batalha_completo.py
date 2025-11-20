import firebase_admin
from firebase_admin import credentials, firestore

# Configuração
cred = credentials.Certificate("../firebase-service-account.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

print("✅ Conectado ao Firebase.")
print("🚀 Populando TODOS os Módulos com 5 perguntas de CADA TIPO (Total: 75 perguntas)...")

# ==============================================================================
# COLEÇÃO 1: 'batalhas_perguntas'
# Contém: Múltipla Escolha (multipla_escolha) + Banco de Palavras (codigo_snippet_word_bank)
# ==============================================================================

dados_batalhas_perguntas = [
    # ---------------------------------------------------------
    # MÓDULO: VARIÁVEIS E TIPOS DE DADOS
    # ---------------------------------------------------------
    # 5x Múltipla Escolha
    {"pergunta": "Qual símbolo é usado para atribuição?", "opcoes": ["==", "=", "->", ":"], "resposta_correta": "=", "modulo": "Variáveis e Tipos de Dados", "nivel": "Fácil", "tipo": "multipla_escolha"},
    {"pergunta": "Como converter '10' (texto) para número?", "opcoes": ["str('10')", "int('10')", "float('10')", "num('10')"], "resposta_correta": "int('10')", "modulo": "Variáveis e Tipos de Dados", "nivel": "Fácil", "tipo": "multipla_escolha"},
    {"pergunta": "Qual tipo armazena True ou False?", "opcoes": ["str", "int", "bool", "float"], "resposta_correta": "bool", "modulo": "Variáveis e Tipos de Dados", "nivel": "Fácil", "tipo": "multipla_escolha"},
    {"pergunta": "O que a função type(x) faz?", "opcoes": ["Apaga x", "Imprime x", "Mostra o tipo de x", "Duplica x"], "resposta_correta": "Mostra o tipo de x", "modulo": "Variáveis e Tipos de Dados", "nivel": "Médio", "tipo": "multipla_escolha"},
    {"pergunta": "Qual variável é válida em Python?", "opcoes": ["1nome", "nome-usuario", "nome_usuario", "nome usuario"], "resposta_correta": "nome_usuario", "modulo": "Variáveis e Tipos de Dados", "nivel": "Fácil", "tipo": "multipla_escolha"},
    
    # 5x Banco de Palavras (Word Bank)
    {"texto_pergunta": "nome = 'Ana'\nprint(____)", "resposta_correta": "nome", "palavras_banco": ["nome", "print", "'Ana'", "var"], "modulo": "Variáveis e Tipos de Dados", "nivel": "Fácil", "tipo": "codigo_snippet_word_bank", "dica": "Nome da variável."},
    {"texto_pergunta": "pi = 3.14\nprint(type(____))", "resposta_correta": "pi", "palavras_banco": ["pi", "float", "int", "type"], "modulo": "Variáveis e Tipos de Dados", "nivel": "Fácil", "tipo": "codigo_snippet_word_bank", "dica": "Variável decimal."},
    {"texto_pergunta": "idade = 25\ntexto = 'Tenho ' + ____(idade) + ' anos'", "resposta_correta": "str", "palavras_banco": ["str", "int", "float", "print"], "modulo": "Variáveis e Tipos de Dados", "nivel": "Médio", "tipo": "codigo_snippet_word_bank", "dica": "Converter para texto."},
    {"texto_pergunta": "ativo = True\nprint(____)", "resposta_correta": "ativo", "palavras_banco": ["ativo", "True", "False", "bool"], "modulo": "Variáveis e Tipos de Dados", "nivel": "Fácil", "tipo": "codigo_snippet_word_bank", "dica": "Imprimir a variável."},
    {"texto_pergunta": "x = 10\ny = 5\nsoma = x ____ y", "resposta_correta": "+", "palavras_banco": ["+", "-", "*", "/", "="], "modulo": "Variáveis e Tipos de Dados", "nivel": "Fácil", "tipo": "codigo_snippet_word_bank", "dica": "Operador de soma."},

    # ---------------------------------------------------------
    # MÓDULO: CONDICIONAIS
    # ---------------------------------------------------------
    # 5x Múltipla Escolha
    {"pergunta": "Qual palavra inicia uma condição?", "opcoes": ["if", "when", "check", "loop"], "resposta_correta": "if", "modulo": "Condicionais", "nivel": "Fácil", "tipo": "multipla_escolha"},
    {"pergunta": "O que significa '!='?", "opcoes": ["Igual", "Diferente", "Maior", "Menor"], "resposta_correta": "Diferente", "modulo": "Condicionais", "nivel": "Fácil", "tipo": "multipla_escolha"},
    {"pergunta": "Qual operador lógico exige ambas as condições verdadeiras?", "opcoes": ["or", "not", "and", "xor"], "resposta_correta": "and", "modulo": "Condicionais", "nivel": "Médio", "tipo": "multipla_escolha"},
    {"pergunta": "O que 'elif' significa?", "opcoes": ["Else If", "End If", "Exit Loop", "Error If"], "resposta_correta": "Else If", "modulo": "Condicionais", "nivel": "Fácil", "tipo": "multipla_escolha"},
    {"pergunta": "O que acontece se o 'if' for falso?", "opcoes": ["O programa trava", "Vai para o else (se houver)", "Repete o if", "Apaga a variável"], "resposta_correta": "Vai para o else (se houver)", "modulo": "Condicionais", "nivel": "Fácil", "tipo": "multipla_escolha"},

    # 5x Banco de Palavras (Word Bank)
    {"texto_pergunta": "idade = 18\n____ idade >= 18:\n  print('Maior')", "resposta_correta": "if", "palavras_banco": ["if", "else", "elif", "for"], "modulo": "Condicionais", "nivel": "Fácil", "tipo": "codigo_snippet_word_bank", "dica": "Se..."},
    {"texto_pergunta": "nota = 5\nif nota > 6:\n  print('Passou')\n____:\n  print('Reprovou')", "resposta_correta": "else", "palavras_banco": ["else", "elif", "if", "stop"], "modulo": "Condicionais", "nivel": "Fácil", "tipo": "codigo_snippet_word_bank", "dica": "Caso contrário."},
    {"texto_pergunta": "x = 10\nif x ____ 10:\n  print('Igual')", "resposta_correta": "==", "palavras_banco": ["==", "=", "!=", ">"], "modulo": "Condicionais", "nivel": "Médio", "tipo": "codigo_snippet_word_bank", "dica": "Comparação de igualdade."},
    {"texto_pergunta": "tem_chave = False\nif ____ tem_chave:\n  print('Trancado')", "resposta_correta": "not", "palavras_banco": ["not", "and", "or", "is"], "modulo": "Condicionais", "nivel": "Difícil", "tipo": "codigo_snippet_word_bank", "dica": "Inverter valor."},
    {"texto_pergunta": "cor = 'azul'\nif cor == 'verde':\n  pass\n____ cor == 'azul':\n  print('Ok')", "resposta_correta": "elif", "palavras_banco": ["elif", "else", "if", "then"], "modulo": "Condicionais", "nivel": "Médio", "tipo": "codigo_snippet_word_bank", "dica": "Outra condição."},

    # ---------------------------------------------------------
    # MÓDULO: LAÇOS DE REPETIÇÃO
    # ---------------------------------------------------------
    # 5x Múltipla Escolha
    {"pergunta": "Qual loop usamos quando sabemos a quantidade de repetições?", "opcoes": ["while", "for", "if", "def"], "resposta_correta": "for", "modulo": "Laços de Repetição", "nivel": "Fácil", "tipo": "multipla_escolha"},
    {"pergunta": "Qual loop continua enquanto a condição for verdadeira?", "opcoes": ["for", "while", "repeat", "until"], "resposta_correta": "while", "modulo": "Laços de Repetição", "nivel": "Fácil", "tipo": "multipla_escolha"},
    {"pergunta": "O que o comando 'break' faz?", "opcoes": ["Pula uma iteração", "Para o loop", "Reinicia o loop", "Apaga o loop"], "resposta_correta": "Para o loop", "modulo": "Laços de Repetição", "nivel": "Médio", "tipo": "multipla_escolha"},
    {"pergunta": "O que 'range(5)' gera?", "opcoes": ["0, 1, 2, 3, 4", "1, 2, 3, 4, 5", "5, 5, 5, 5, 5", "0 a 5"], "resposta_correta": "0, 1, 2, 3, 4", "modulo": "Laços de Repetição", "nivel": "Médio", "tipo": "multipla_escolha"},
    {"pergunta": "Como iterar sobre uma lista?", "opcoes": ["for item in lista", "while lista", "if lista", "loop lista"], "resposta_correta": "for item in lista", "modulo": "Laços de Repetição", "nivel": "Fácil", "tipo": "multipla_escolha"},

    # 5x Banco de Palavras (Word Bank)
    {"texto_pergunta": "for i ____ range(10):\n  print(i)", "resposta_correta": "in", "palavras_banco": ["in", "on", "at", "to"], "modulo": "Laços de Repetição", "nivel": "Fácil", "tipo": "codigo_snippet_word_bank", "dica": "Dentro."},
    {"texto_pergunta": "x = 0\n____ x < 5:\n  print(x)\n  x += 1", "resposta_correta": "while", "palavras_banco": ["while", "for", "if", "loop"], "modulo": "Laços de Repetição", "nivel": "Médio", "tipo": "codigo_snippet_word_bank", "dica": "Enquanto."},
    {"texto_pergunta": "frutas = ['Uva', 'Maçã']\nfor f in frutas:\n  print(____)", "resposta_correta": "f", "palavras_banco": ["f", "frutas", "print", "item"], "modulo": "Laços de Repetição", "nivel": "Fácil", "tipo": "codigo_snippet_word_bank", "dica": "Variável temporária."},
    {"texto_pergunta": "for i in range(10):\n  if i == 5:\n    ____", "resposta_correta": "break", "palavras_banco": ["break", "stop", "end", "exit"], "modulo": "Laços de Repetição", "nivel": "Difícil", "tipo": "codigo_snippet_word_bank", "dica": "Parar o loop."},
    {"texto_pergunta": "for i in range(10):\n  if i % 2 == 0:\n    ____", "resposta_correta": "continue", "palavras_banco": ["continue", "pass", "return", "break"], "modulo": "Laços de Repetição", "nivel": "Difícil", "tipo": "codigo_snippet_word_bank", "dica": "Pular para o próximo."},

    # ---------------------------------------------------------
    # MÓDULO: FUNÇÕES
    # ---------------------------------------------------------
    # 5x Múltipla Escolha
    {"pergunta": "Como definimos uma função?", "opcoes": ["func nome()", "def nome():", "function nome()", "create nome()"], "resposta_correta": "def nome():", "modulo": "Funções", "nivel": "Fácil", "tipo": "multipla_escolha"},
    {"pergunta": "O que o comando 'return' faz?", "opcoes": ["Imprime na tela", "Devolve um valor e encerra a função", "Repete a função", "Define um parâmetro"], "resposta_correta": "Devolve um valor e encerra a função", "modulo": "Funções", "nivel": "Fácil", "tipo": "multipla_escolha"},
    {"pergunta": "O que são parâmetros?", "opcoes": ["Valores recebidos pela função", "O nome da função", "O resultado da função", "Erros da função"], "resposta_correta": "Valores recebidos pela função", "modulo": "Funções", "nivel": "Médio", "tipo": "multipla_escolha"},
    {"pergunta": "O que é uma função lambda?", "opcoes": ["Uma função anônima de uma linha", "Uma função com erro", "Uma função de loop", "Uma classe"], "resposta_correta": "Uma função anônima de uma linha", "modulo": "Funções", "nivel": "Difícil", "tipo": "multipla_escolha"},
    {"pergunta": "Como chamar a função 'teste'?", "opcoes": ["teste", "teste()", "call teste", "run teste"], "resposta_correta": "teste()", "modulo": "Funções", "nivel": "Fácil", "tipo": "multipla_escolha"},

    # 5x Banco de Palavras (Word Bank)
    {"texto_pergunta": "____ saudacao():\n  print('Olá')", "resposta_correta": "def", "palavras_banco": ["def", "class", "func", "var"], "modulo": "Funções", "nivel": "Fácil", "tipo": "codigo_snippet_word_bank", "dica": "Definir."},
    {"texto_pergunta": "def somar(a, b):\n  ____ a + b", "resposta_correta": "return", "palavras_banco": ["return", "print", "back", "get"], "modulo": "Funções", "nivel": "Fácil", "tipo": "codigo_snippet_word_bank", "dica": "Retornar."},
    {"texto_pergunta": "def ola(nome):\n  print('Oi ' + ____)", "resposta_correta": "nome", "palavras_banco": ["nome", "ola", "def", "str"], "modulo": "Funções", "nivel": "Médio", "tipo": "codigo_snippet_word_bank", "dica": "Usar o parâmetro."},
    {"texto_pergunta": "dobro = ____ x: x * 2", "resposta_correta": "lambda", "palavras_banco": ["lambda", "def", "map", "func"], "modulo": "Funções", "nivel": "Difícil", "tipo": "codigo_snippet_word_bank", "dica": "Função rápida."},
    {"texto_pergunta": "def teste():\n  pass\n____()", "resposta_correta": "teste", "palavras_banco": ["teste", "run", "call", "def"], "modulo": "Funções", "nivel": "Fácil", "tipo": "codigo_snippet_word_bank", "dica": "Chamar a função."},

    # ---------------------------------------------------------
    # MÓDULO: PERGUNTAS DIVERSAS
    # ---------------------------------------------------------
    # 5x Múltipla Escolha
    {"pergunta": "Para que serve o '# '?", "opcoes": ["Comentário", "Loop", "Importar", "Erro"], "resposta_correta": "Comentário", "modulo": "Perguntas diversas", "nivel": "Fácil", "tipo": "multipla_escolha"},
    {"pergunta": "Qual biblioteca é usada para matemática?", "opcoes": ["math", "sys", "os", "random"], "resposta_correta": "math", "modulo": "Perguntas diversas", "nivel": "Fácil", "tipo": "multipla_escolha"},
    {"pergunta": "Como pegar o tamanho de uma lista?", "opcoes": ["len(lista)", "size(lista)", "count(lista)", "lista.size()"], "resposta_correta": "len(lista)", "modulo": "Perguntas diversas", "nivel": "Médio", "tipo": "multipla_escolha"},
    {"pergunta": "O que é um 'bug'?", "opcoes": ["Um erro no código", "Um recurso novo", "Um tipo de variável", "Um vírus"], "resposta_correta": "Um erro no código", "modulo": "Perguntas diversas", "nivel": "Fácil", "tipo": "multipla_escolha"},
    {"pergunta": "Qual estrutura lida com erros?", "opcoes": ["try/except", "if/else", "for/while", "def/return"], "resposta_correta": "try/except", "modulo": "Perguntas diversas", "nivel": "Difícil", "tipo": "multipla_escolha"},

    # 5x Banco de Palavras (Word Bank)
    {"texto_pergunta": "# Isso é um ____", "resposta_correta": "comentário", "palavras_banco": ["comentário", "código", "erro", "loop"], "modulo": "Perguntas diversas", "nivel": "Fácil", "tipo": "codigo_snippet_word_bank", "dica": "Ignorado pelo Python."},
    {"texto_pergunta": "import ____\nprint(math.pi)", "resposta_correta": "math", "palavras_banco": ["math", "random", "os", "sys"], "modulo": "Perguntas diversas", "nivel": "Fácil", "tipo": "codigo_snippet_word_bank", "dica": "Biblioteca matemática."},
    {"texto_pergunta": "try:\n  x = 1/0\n____ ZeroDivisionError:", "resposta_correta": "except", "palavras_banco": ["except", "else", "catch", "error"], "modulo": "Perguntas diversas", "nivel": "Difícil", "tipo": "codigo_snippet_word_bank", "dica": "Capturar erro."},
    {"texto_pergunta": "lista = [1, 2, 3]\nprint(____(lista))", "resposta_correta": "len", "palavras_banco": ["len", "size", "count", "max"], "modulo": "Perguntas diversas", "nivel": "Médio", "tipo": "codigo_snippet_word_bank", "dica": "Tamanho."},
    {"texto_pergunta": "print(f'O valor é {x}')", "resposta_correta": "f", "palavras_banco": ["f", "r", "b", "u"], "modulo": "Perguntas diversas", "nivel": "Médio", "tipo": "codigo_snippet_word_bank", "dica": "String formatada."}
]

# ==============================================================================
# COLEÇÃO 2: 'desafio_montar_codigo'
# Contém: Drag & Drop (drag_and_drop)
# ==============================================================================

dados_montar_codigo = [
    # ---------------------------------------------------------
    # MÓDULO: VARIÁVEIS E TIPOS DE DADOS (5x Drag Drop)
    # ---------------------------------------------------------
    {"titulo": "Imprimir Olá Mundo", "partes_codigo": ["msg = 'Olá Mundo'", "print(msg)"], "nivel": "Fácil", "modulo": "Variáveis e Tipos de Dados", "tipo": "drag_and_drop"},
    {"titulo": "Somar Variáveis", "partes_codigo": ["a = 5", "b = 10", "soma = a + b", "print(soma)"], "nivel": "Fácil", "modulo": "Variáveis e Tipos de Dados", "tipo": "drag_and_drop"},
    {"titulo": "Trocar Valores", "partes_codigo": ["a = 1", "b = 2", "temp = a", "a = b", "b = temp"], "nivel": "Médio", "modulo": "Variáveis e Tipos de Dados", "tipo": "drag_and_drop"},
    {"titulo": "Converter Tipo", "partes_codigo": ["texto = '50'", "numero = int(texto)", "print(numero + 10)"], "nivel": "Médio", "modulo": "Variáveis e Tipos de Dados", "tipo": "drag_and_drop"},
    {"titulo": "Input de Nome", "partes_codigo": ["nome = input('Nome:')", "print('Oi ' + nome)"], "nivel": "Fácil", "modulo": "Variáveis e Tipos de Dados", "tipo": "drag_and_drop"},

    # ---------------------------------------------------------
    # MÓDULO: CONDICIONAIS (5x Drag Drop)
    # ---------------------------------------------------------
    {"titulo": "Verificar Maioridade", "partes_codigo": ["idade = 18", "if idade >= 18:", "    print('Maior')", "else:", "    print('Menor')"], "nivel": "Fácil", "modulo": "Condicionais", "tipo": "drag_and_drop"},
    {"titulo": "Número Positivo", "partes_codigo": ["num = 10", "if num > 0:", "    print('Positivo')"], "nivel": "Fácil", "modulo": "Condicionais", "tipo": "drag_and_drop"},
    {"titulo": "Par ou Ímpar", "partes_codigo": ["n = 4", "if n % 2 == 0:", "    print('Par')", "else:", "    print('Ímpar')"], "nivel": "Médio", "modulo": "Condicionais", "tipo": "drag_and_drop"},
    {"titulo": "Classificar Nota", "partes_codigo": ["nota = 7", "if nota >= 9:", "    print('A')", "elif nota >= 7:", "    print('B')"], "nivel": "Difícil", "modulo": "Condicionais", "tipo": "drag_and_drop"},
    {"titulo": "Login Simples", "partes_codigo": ["senha = '123'", "if senha == '123':", "    print('Entrou')", "else:", "    print('Senha errada')"], "nivel": "Médio", "modulo": "Condicionais", "tipo": "drag_and_drop"},

    # ---------------------------------------------------------
    # MÓDULO: LAÇOS DE REPETIÇÃO (5x Drag Drop)
    # ---------------------------------------------------------
    {"titulo": "Contar até 3", "partes_codigo": ["for i in range(3):", "    print(i)"], "nivel": "Fácil", "modulo": "Laços de Repetição", "tipo": "drag_and_drop"},
    {"titulo": "Listar Frutas", "partes_codigo": ["lista = ['Uva', 'Pera']", "for fruta in lista:", "    print(fruta)"], "nivel": "Fácil", "modulo": "Laços de Repetição", "tipo": "drag_and_drop"},
    {"titulo": "While Simples", "partes_codigo": ["x = 5", "while x > 0:", "    print(x)", "    x -= 1"], "nivel": "Médio", "modulo": "Laços de Repetição", "tipo": "drag_and_drop"},
    {"titulo": "Soma Acumulada", "partes_codigo": ["soma = 0", "for i in range(5):", "    soma += i", "print(soma)"], "nivel": "Médio", "modulo": "Laços de Repetição", "tipo": "drag_and_drop"},
    {"titulo": "Loop com Break", "partes_codigo": ["for i in range(10):", "    if i == 5:", "        break", "    print(i)"], "nivel": "Difícil", "modulo": "Laços de Repetição", "tipo": "drag_and_drop"},

    # ---------------------------------------------------------
    # MÓDULO: FUNÇÕES (5x Drag Drop)
    # ---------------------------------------------------------
    {"titulo": "Função Saudação", "partes_codigo": ["def oi():", "    print('Olá!')", "oi()"], "nivel": "Fácil", "modulo": "Funções", "tipo": "drag_and_drop"},
    {"titulo": "Função Soma", "partes_codigo": ["def somar(a, b):", "    return a + b", "res = somar(2, 3)"], "nivel": "Fácil", "modulo": "Funções", "tipo": "drag_and_drop"},
    {"titulo": "Função Par", "partes_codigo": ["def e_par(n):", "    if n % 2 == 0:", "        return True", "    return False"], "nivel": "Médio", "modulo": "Funções", "tipo": "drag_and_drop"},
    {"titulo": "Fatorial Recursivo", "partes_codigo": ["def fat(n):", "    if n == 1:", "        return 1", "    return n * fat(n-1)"], "nivel": "Difícil", "modulo": "Funções", "tipo": "drag_and_drop"},
    {"titulo": "Função Média", "partes_codigo": ["def media(lista):", "    soma = sum(lista)", "    return soma / len(lista)"], "nivel": "Médio", "modulo": "Funções", "tipo": "drag_and_drop"},

    # ---------------------------------------------------------
    # MÓDULO: PERGUNTAS DIVERSAS (5x Drag Drop)
    # ---------------------------------------------------------
    {"titulo": "Importar Math", "partes_codigo": ["import math", "raiz = math.sqrt(9)", "print(raiz)"], "nivel": "Fácil", "modulo": "Perguntas diversas", "tipo": "drag_and_drop"},
    {"titulo": "Tratar Erro", "partes_codigo": ["try:", "    print(1/0)", "except ZeroDivisionError:", "    print('Erro')"], "nivel": "Difícil", "modulo": "Perguntas diversas", "tipo": "drag_and_drop"},
    {"titulo": "Ler Arquivo", "partes_codigo": ["with open('log.txt') as f:", "    conteudo = f.read()", "    print(conteudo)"], "nivel": "Difícil", "modulo": "Perguntas diversas", "tipo": "drag_and_drop"},
    {"titulo": "Criar Lista", "partes_codigo": ["nums = []", "nums.append(1)", "nums.append(2)", "print(nums)"], "nivel": "Fácil", "modulo": "Perguntas diversas", "tipo": "drag_and_drop"},
    {"titulo": "Dicionário Simples", "partes_codigo": ["aluno = {}", "aluno['nome'] = 'Gui'", "aluno['nota'] = 10", "print(aluno)"], "nivel": "Médio", "modulo": "Perguntas diversas", "tipo": "drag_and_drop"}
]

# ============================================================
# FUNÇÃO DE UPLOAD (LIMPA E ADICIONA)
# ============================================================

def popular_colecao(nome, dados):
    ref = db.collection(nome)
    
    # Limpa a coleção
    antigos = ref.stream()
    count = 0
    for doc in antigos:
        doc.reference.delete()
        count += 1
    print(f"🗑️ {count} documentos deletados de '{nome}'.")

    # Adiciona os novos
    for item in dados:
        ref.add(item)
    print(f"✅ {len(dados)} novos documentos criados em '{nome}'.\n")

# ============================================================
# EXECUÇÃO
# ============================================================

# Popula Múltipla Escolha e Word Bank
popular_colecao("batalhas_perguntas", dados_batalhas_perguntas)

# Popula Drag & Drop
popular_colecao("desafio_montar_codigo", dados_montar_codigo)

print("\n🔥 SUcesso! Banco de dados REPLETO com 75 perguntas variadas.")
print("Agora você tem 5 perguntas de cada tipo para CADA MÓDULO.")