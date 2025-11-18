import firebase_admin
from firebase_admin import credentials, firestore

# Configuração do Firebase
cred = credentials.Certificate("../firebase-service-account.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

print("✅ Conectado ao Firebase.")
print("🚀 Populando Batalha com TODOS OS MÓDULOS e 3 TIPOS misturados...")

# ==============================================================================
# COLEÇÃO 1: 'batalhas_perguntas'
# Contém: Múltipla Escolha (multipla_escolha) e Banco de Palavras (codigo_snippet_word_bank)
# ==============================================================================

perguntas_misturadas = [
    # ---------------------------------------------------------
    # MÓDULO: VARIÁVEIS E TIPOS DE DADOS
    # ---------------------------------------------------------
    {
        "pergunta": "Qual função converte um valor para texto em Python?",
        "opcoes": ["text()", "str()", "string()", "to_string()"],
        "resposta_correta": "str()",
        "modulo": "Variáveis e Tipos de Dados",
        "nivel": "Fácil",
        "tipo": "multipla_escolha"
    },
    {
        "texto_pergunta": "preco = 10.5\nquantidade = 2\ntotal = ____(preco * quantidade)",
        "resposta_correta": "int",
        "palavras_banco": ["int", "str", "float", "bool", "print"],
        "modulo": "Variáveis e Tipos de Dados",
        "nivel": "Médio",
        "tipo": "codigo_snippet_word_bank",
        "dica": "Função para converter para número inteiro."
    },
    {
        "pergunta": "O que resulta da operação: type(3.14)?",
        "opcoes": ["<class 'int'>", "<class 'float'>", "<class 'str'>", "<class 'bool'>"],
        "resposta_correta": "<class 'float'>",
        "modulo": "Variáveis e Tipos de Dados",
        "nivel": "Fácil",
        "tipo": "multipla_escolha"
    },

    # ---------------------------------------------------------
    # MÓDULO: CONDICIONAIS
    # ---------------------------------------------------------
    {
        "pergunta": "Qual operador lógico inverte o valor de uma condição?",
        "opcoes": ["and", "or", "not", "invert"],
        "resposta_correta": "not",
        "modulo": "Condicionais",
        "nivel": "Médio",
        "tipo": "multipla_escolha"
    },
    {
        "texto_pergunta": "nota = 7\n____ nota >= 6:\n  print('Aprovado')\nelse:\n  print('Reprovado')",
        "resposta_correta": "if",
        "palavras_banco": ["if", "elif", "else", "for", "while"],
        "modulo": "Condicionais",
        "nivel": "Fácil",
        "tipo": "codigo_snippet_word_bank",
        "dica": "Início de uma condição."
    },
    {
        "texto_pergunta": "cor = 'vermelho'\nif cor == 'verde':\n  print('Siga')\n____ cor == 'amarelo':\n  print('Atenção')",
        "resposta_correta": "elif",
        "palavras_banco": ["elif", "else", "if", "then", "stop"],
        "modulo": "Condicionais",
        "nivel": "Médio",
        "tipo": "codigo_snippet_word_bank",
        "dica": "Condição intermediária."
    },

    # ---------------------------------------------------------
    # MÓDULO: LAÇOS DE REPETIÇÃO
    # ---------------------------------------------------------
    {
        "pergunta": "Qual comando pula para a próxima iteração do loop?",
        "opcoes": ["break", "continue", "pass", "return"],
        "resposta_correta": "continue",
        "modulo": "Laços de Repetição",
        "nivel": "Difícil",
        "tipo": "multipla_escolha"
    },
    {
        "texto_pergunta": "for i ____ range(5):\n  print(i)",
        "resposta_correta": "in",
        "palavras_banco": ["in", "on", "at", "to", "for"],
        "modulo": "Laços de Repetição",
        "nivel": "Fácil",
        "tipo": "codigo_snippet_word_bank",
        "dica": "Palavra usada para iterar dentro de uma sequência."
    },
    {
        "texto_pergunta": "x = 5\n____ x > 0:\n  print(x)\n  x -= 1",
        "resposta_correta": "while",
        "palavras_banco": ["while", "if", "for", "loop", "until"],
        "modulo": "Laços de Repetição",
        "nivel": "Médio",
        "tipo": "codigo_snippet_word_bank",
        "dica": "Loop que roda enquanto a condição for verdadeira."
    },

    # ---------------------------------------------------------
    # MÓDULO: FUNÇÕES
    # ---------------------------------------------------------
    {
        "pergunta": "Qual palavra-chave define uma função em Python?",
        "opcoes": ["func", "define", "def", "function"],
        "resposta_correta": "def",
        "modulo": "Funções",
        "nivel": "Fácil",
        "tipo": "multipla_escolha"
    },
    {
        "texto_pergunta": "____ dobrar(numero):\n  return numero * 2",
        "resposta_correta": "def",
        "palavras_banco": ["def", "class", "func", "var", "return"],
        "modulo": "Funções",
        "nivel": "Fácil",
        "tipo": "codigo_snippet_word_bank",
        "dica": "Declaração de função."
    },
    {
        "texto_pergunta": "soma = ____ a, b: a + b\nprint(soma(2, 3))",
        "resposta_correta": "lambda",
        "palavras_banco": ["lambda", "def", "map", "return", "func"],
        "modulo": "Funções",
        "nivel": "Difícil",
        "tipo": "codigo_snippet_word_bank",
        "dica": "Função anônima de uma linha."
    },

    # ---------------------------------------------------------
    # MÓDULO: PERGUNTAS DIVERSAS
    # ---------------------------------------------------------
    {
        "pergunta": "O que significa o acrônimo API?",
        "opcoes": ["Application Programming Interface", "App Private Internet", "Automatic Python Integration", "Algoritmo Para Internet"],
        "resposta_correta": "Application Programming Interface",
        "modulo": "Perguntas diversas",
        "nivel": "Médio",
        "tipo": "multipla_escolha"
    },
    {
        "texto_pergunta": "try:\n  x = 10 / 0\n____ ZeroDivisionError:\n  print('Erro')",
        "resposta_correta": "except",
        "palavras_banco": ["except", "catch", "else", "finally", "error"],
        "modulo": "Perguntas diversas",
        "nivel": "Difícil",
        "tipo": "codigo_snippet_word_bank",
        "dica": "Bloco para capturar erros."
    }
]

# ==============================================================================
# COLEÇÃO 2: 'desafio_montar_codigo'
# Contém: Drag & Drop (drag_and_drop)
# ==============================================================================

perguntas_drag_drop = [
    # --- VARIÁVEIS ---
    {
        "titulo": "Trocar valores (Swap)",
        "partes_codigo": ["a = 5", "b = 10", "aux = a", "a = b", "b = aux"],
        "nivel": "Médio",
        "tipo": "drag_and_drop",
        "modulo": "Variáveis e Tipos de Dados"
    },

    # --- CONDICIONAIS ---
    {
        "titulo": "Verificar par ou ímpar",
        "partes_codigo": ["num = 4", "if num % 2 == 0:", "    print('Par')", "else:", "    print('Ímpar')"],
        "nivel": "Fácil",
        "tipo": "drag_and_drop",
        "modulo": "Condicionais"
    },

    # --- LAÇOS ---
    {
        "titulo": "Imprimir lista de frutas",
        "partes_codigo": ["frutas = ['Uva', 'Maçã']", "for fruta in frutas:", "    print(fruta)"],
        "nivel": "Fácil",
        "tipo": "drag_and_drop",
        "modulo": "Laços de Repetição"
    },
    {
        "titulo": "Contagem regressiva",
        "partes_codigo": ["i = 10", "while i > 0:", "    print(i)", "    i -= 1", "print('Fim!')"],
        "nivel": "Médio",
        "tipo": "drag_and_drop",
        "modulo": "Laços de Repetição"
    },

    # --- FUNÇÕES ---
    {
        "titulo": "Função de média",
        "partes_codigo": ["def media(a, b):", "    soma = a + b", "    res = soma / 2", "    return res"],
        "nivel": "Médio",
        "tipo": "drag_and_drop",
        "modulo": "Funções"
    },
    {
        "titulo": "Fatorial Recursivo",
        "partes_codigo": ["def fat(n):", "    if n == 1:", "        return 1", "    return n * fat(n-1)"],
        "nivel": "Difícil",
        "tipo": "drag_and_drop",
        "modulo": "Funções"
    },

    # --- DIVERSOS ---
    {
        "titulo": "Ler arquivo",
        "partes_codigo": ["with open('dados.txt') as f:", "    conteudo = f.read()", "    print(conteudo)"],
        "nivel": "Difícil",
        "tipo": "drag_and_drop",
        "modulo": "Perguntas diversas"
    },
    {
        "titulo": "Importar e usar Math",
        "partes_codigo": ["import math", "raio = 5", "area = math.pi * (raio ** 2)", "print(area)"],
        "nivel": "Médio",
        "tipo": "drag_and_drop",
        "modulo": "Perguntas diversas"
    }
]

# ============================================================
# FUNÇÃO DE UPLOAD
# ============================================================

def popular_colecao(nome, dados):
    ref = db.collection(nome)
    
    # Limpa a coleção antes
    antigos = ref.stream()
    count = 0
    for doc in antigos:
        doc.reference.delete()
        count += 1
    print(f"🗑️ {count} documentos antigos deletados de '{nome}'.")

    # Adiciona os novos
    for item in dados:
        ref.add(item)
    print(f"✅ {len(dados)} novos documentos criados em '{nome}'.\n")

# ============================================================
# EXECUÇÃO
# ============================================================

# Coleção 1: Múltipla Escolha + Word Bank
popular_colecao("batalhas_perguntas", perguntas_misturadas)

# Coleção 2: Drag & Drop
popular_colecao("desafio_montar_codigo", perguntas_drag_drop)

print("\n🔥 Sucesso! O banco foi populado com perguntas de TODOS os módulos e TODOS os tipos.")