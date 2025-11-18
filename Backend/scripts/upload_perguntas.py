# ============================================
#  DESAFIO SEMANAL - POPULAR FIREBASE (ATUALIZADO PARA WORD BANK)
# ============================================
# - Altera a estrutura da Fase 2 para suportar "Banco de Palavras".
#   - Muda tipo para 'codigo_snippet_word_bank'
#   - Adiciona o campo 'palavras_banco' com os distratores.
#   - Muda 'resposta_correta' para a linha completa (ex: "else:")
# ============================================

import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.Certificate("../firebase-service-account.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

print("✅ Conexão com Firebase estabelecida.\n")
print("Iniciando população de todas as coleções do Desafio Semanal...\n")

# ============================================================
# DADOS FASE 1 (Múltipla Escolha) E FASE 2 (Banco de Palavras)
# Coleção: batalhas_perguntas
# ============================================================

dados_fase1_e_fase2 = [
    # ============================
    # FASE 1: MÚLTIPLA ESCOLHA (Vários módulos)
    # ============================
    {
        "pergunta": "Qual tipo de dado armazena números inteiros no Python?",
        "opcoes": ["int", "float", "string", "bool"],
        "resposta_correta": "int",
        "modulo": "Variáveis",
        "nivel": "Fácil",
        "tipo": "multipla_escolha", # TIPO CORRETO
        "fase": 1
    },
    {
        "pergunta": "Qual tipo é usado para texto em Python?",
        "opcoes": ["str", "int", "bool", "float"],
        "resposta_correta": "str",
        "modulo": "Variáveis",
        "nivel": "Fácil",
        "tipo": "multipla_escolha",
        "fase": 1
    },
    {
        "pergunta": "Qual palavra-chave inicia uma condição em Python?",
        "opcoes": ["if", "when", "case", "switch"],
        "resposta_correta": "if",
        "modulo": "Condicionais",
        "nivel": "Fácil",
        "tipo": "multipla_escolha",
        "fase": 1
    },
    {
        "pergunta": "Qual comando representa uma alternativa?",
        "opcoes": ["else", "elif", "otherwise", "except"],
        "resposta_correta": "else",
        "modulo": "Condicionais",
        "nivel": "Fácil",
        "tipo": "multipla_escolha",
        "fase": 1
    },
    {
        "pergunta": "Qual laço repete até a condição ser falsa?",
        "opcoes": ["for", "repeat", "while", "loop"],
        "resposta_correta": "while",
        "modulo": "Laços",
        "nivel": "Fácil",
        "tipo": "multipla_escolha",
        "fase": 1
    },
    {
        "pergunta": "Qual laço itera sobre listas?",
        "opcoes": ["for", "loop", "iterate", "scan"],
        "resposta_correta": "for",
        "modulo": "Laços",
        "nivel": "Fácil",
        "tipo": "multipla_escolha",
        "fase": 1
    },
    {
        "pergunta": "Qual operador verifica igualdade?",
        "opcoes": ["=", "==", "===", ":="],
        "resposta_correta": "==",
        "modulo": "Condicionais",
        "nivel": "Médio",
        "tipo": "multipla_escolha",
        "fase": 1
    },
    {
        "pergunta": "Qual comando encerra um laço?",
        "opcoes": ["end", "exit", "break", "stop"],
        "resposta_correta": "break",
        "modulo": "Laços",
        "nivel": "Médio",
        "tipo": "multipla_escolha",
        "fase": 1
    },
    {
        "pergunta": "Qual é um exemplo de 'f-string' (string formatada) em Python?",
        "opcoes": ["f\"Valor: {x}\"", "\"Valor: %x\" % x", "\"Valor: \" + x", "\"Valor: {0}\".format(x)"],
        "resposta_correta": "f\"Valor: {x}\"",
        "modulo": "Variáveis",
        "nivel": "Difícil",
        "tipo": "multipla_escolha",
        "fase": 1
    },
    {
        "pergunta": "Qual operador lógico significa 'OU'?",
        "opcoes": ["or", "and", "||", "ou"],
        "resposta_correta": "or",
        "modulo": "Condicionais",
        "nivel": "Médio",
        "tipo": "multipla_escolha",
        "fase": 1
    },
    {
        "pergunta": "Qual comando é usado para obter o índice e o valor ao iterar?",
        "opcoes": ["enumerate(lista)", "index(lista)", "list(lista)", "range(lista)"],
        "resposta_correta": "enumerate(lista)",
        "modulo": "Laços",
        "nivel": "Difícil",
        "tipo": "multipla_escolha",
        "fase": 1
    },
    {
        "pergunta": "O que a função type() retorna?",
        "opcoes": ["O tamanho da variável", "O tipo da variável", "O valor da variável", "Nada"],
        "resposta_correta": "O tipo da variável",
        "modulo": "Variáveis",
        "nivel": "Médio",
        "tipo": "multipla_escolha",
        "fase": 1
    },

    # ===========================================================
    # 🚀 DADOS DA FASE 2 (Banco de Palavras) - MESMA COLEÇÃO
    # ===========================================================
    
    # --- FASE 2: CONDICIONAIS (5 perguntas) ---
    {
        "texto_pergunta": "idade = 17\nif idade >= 18:\n  status = 'Maior'\n____\n  status = 'Menor'\nprint(status)",
        "resposta_correta": "else:",
        "palavras_banco": ["else", ":", "if", "for", "idade"], # Lista de palavras
        "modulo": "Condicionais",
        "nivel": "Fácil",
        "tipo": "codigo_snippet_word_bank", # <-- NOVO TIPO
        "fase": 2,
        "dica": "Qual palavra-chave é usada para 'caso contrário'?"
    },
    {
        "texto_pergunta": "nota = 85\nif nota >= 90:\n  print('A')\n____\n  print('B')\nelse:\n  print('C')",
        "resposta_correta": "elif nota > 80:",
        "palavras_banco": ["elif", "nota", ">", "80", ":", "else", "if"],
        "modulo": "Condicionais",
        "nivel": "Médio",
        "tipo": "codigo_snippet_word_bank", # <-- NOVO TIPO
        "fase": 2,
        "dica": "Como se testa uma 'outra condição' antes do else?"
    },
    {
        "texto_pergunta": "x = 10\ny = 10\nif ____:\n  print('Iguais')",
        "resposta_correta": "x == y",
        "palavras_banco": ["x", "==", "y", "=", "+=", "if", "!="],
        "modulo": "Condicionais",
        "nivel": "Fácil",
        "tipo": "codigo_snippet_word_bank", # <-- NOVO TIPO
        "fase": 2,
        "dica": "Qual operador compara dois valores?"
    },
    {
        "texto_pergunta": "temp = 30\nif ____:\n  print('Clima agradável')",
        "resposta_correta": "temp > 25 and temp < 40",
        "palavras_banco": ["temp", ">", "25", "and", "temp", "<", "40", "or"],
        "modulo": "Condicionais",
        "nivel": "Difícil",
        "tipo": "codigo_snippet_word_bank", # <-- NOVO TIPO
        "fase": 2,
        "dica": "Qual operador lógico exige que AMBAS as condições sejam verdadeiras?"
    },
    {
        "texto_pergunta": "is_logged_in = False\nif ____:\n  print('Visitante')",
        "resposta_correta": "not is_logged_in",
        "palavras_banco": ["not", "is_logged_in", "is", "or", "False", "if"],
        "modulo": "Condicionais",
        "nivel": "Médio",
        "tipo": "codigo_snippet_word_bank", # <-- NOVO TIPO
        "fase": 2,
        "dica": "Qual operador lógico inverte um valor Booleano?"
    },

    # --- FASE 2: LAÇOS (3 perguntas) ---
    {
        "texto_pergunta": "frutas = ['Maçã', 'Uva', 'Pera']\n____ fruta in frutas:\n  print(fruta)",
        "resposta_correta": "for",
        "palavras_banco": ["for", "in", "while", "frutas", "print"],
        "modulo": "Laços",
        "nivel": "Fácil",
        "tipo": "codigo_snippet_word_bank", # <-- NOVO TIPO
        "fase": 2,
        "dica": "Qual palavra-chave é usada para iterar sobre os itens de uma lista?"
    },
    {
        "texto_pergunta": "i = 0\n____ i < 3:\n  print(i)\n  i += 1",
        "resposta_correta": "while",
        "palavras_banco": ["while", "if", "for", "i", "range"],
        "modulo": "Laços",
        "nivel": "Médio",
        "tipo": "codigo_snippet_word_bank", # <-- NOVO TIPO
        "fase": 2,
        "dica": "Qual tipo de laço continua enquanto uma condição for verdadeira?"
    },
    {
        "texto_pergunta": "for i in ____(3):\n  print(i)",
        "resposta_correta": "range",
        "palavras_banco": ["range", "len", "type", "i", "in"],
        "modulo": "Laços",
        "nivel": "Médio",
        "tipo": "codigo_snippet_word_bank", # <-- NOVO TIPO
        "fase": 2,
        "dica": "Qual função gera uma sequência de números?"
    },


    # --- FASE 2: VARIÁVEIS (2 perguntas) ---
    {
        "texto_pergunta": "nome = 'Maria'\n# Queremos saber o tamanho da string\nprint(____(nome))",
        "resposta_correta": "len",
        "palavras_banco": ["len", "print", "type", "nome", "str"],
        "modulo": "Variáveis",
        "nivel": "Fácil",
        "tipo": "codigo_snippet_word_bank", # <-- NOVO TIPO
        "fase": 2,
        "dica": "Qual função retorna o 'comprimento' (length) de um objeto?"
    },
    {
        "texto_pergunta": "valor_str = \"5\"\nvalor_int = ____(valor_str)",
        "resposta_correta": "int",
        "palavras_banco": ["int", "str", "float", "valor_str", "="],
        "modulo": "Variáveis",
        "nivel": "Fácil",
        "tipo": "codigo_snippet_word_bank", # <-- NOVO TIPO
        "fase": 2,
        "dica": "Qual função converte um valor para inteiro?"
    },
]

# ============================================================
# DADOS FASE 3 – (Drag & Drop)
# Coleção: desafio_montar_codigo
# ============================================================

dados_fase3_drag_drop = [
    {
        "titulo": "Imprimir números de 0 a 4",
        "partes_codigo": ["for i in range(5):", "    print(i)"],
        "corretas": [0, 1],
        "modulo": "Laços", 
        "fase": 3
    },
    {
        "titulo": "Verificar maioridade",
        "partes_codigo": ["idade = 18", "if idade >= 18:", "    print('Maior de idade')"],
        "corretas": [0, 1, 2],
        "modulo": "Condicionais", 
        "fase": 3
    },
    {
        "titulo": "Somar dois valores",
        "partes_codigo": ["a = 3", "b = 7", "print(a + b)"],
        "corretas": [0, 1, 2],
        "modulo": "Variáveis", 
        "fase": 3
    },
    {
        "titulo": "Contar até 3 (while)",
        "partes_codigo": ["i = 1", "while i <= 3:", "    print(i)", "    i += 1"],
        "corretas": [0, 1, 2, 3],
        "modulo": "Laços", 
        "fase": 3
    },
    {
        "titulo": "Saudação com nome",
        "partes_codigo": ["nome = 'Pedro'", "print('Olá, ' + nome)"],
        "corretas": [0, 1],
        "modulo": "Variáveis", 
        "fase": 3
    },
    {
        "titulo": "Imprimir números pares até 8",
        "partes_codigo": ["for i in range(0, 10, 2):", "    print(i)"],
        "corretas": [0, 1],
        "modulo": "Laços", 
        "fase": 3
    },
    {
        "titulo": "Iterar sobre uma lista de frutas",
        "partes_codigo": ["lista_frutas = ['Uva', 'Morango']", "for fruta in lista_frutas:", "    print(fruta)"],
        "corretas": [0, 1, 2],
        "modulo": "Laços",
        "fase": 3
    },
    {
        "titulo": "Verificar se um número é Par ou Ímpar",
        "partes_codigo": ["num = 7", "if num % 2 == 0:", "    print('É Par')", "else:", "    print('É Ímpar')"],
        "corretas": [0, 1, 2, 3, 4],
        "modulo": "Condicionais",
        "fase": 3
    },
    {
        "titulo": "Pedir o nome do usuário e saudar",
        "partes_codigo": ["nome = input('Qual seu nome? ')", "print('Bem-vindo, ' + nome)"],
        "corretas": [0, 1],
        "modulo": "Variáveis",
        "fase": 3
    },
    {
        "titulo": "Verificar se está frio ou calor",
        "partes_codigo": [
            "temperatura = 15",
            "if temperatura < 20:",
            "    print('Está frio!')",
            "else:",
            "    print('Está calor!')"
        ],
        "corretas": [0, 1, 2, 3, 4],
        "modulo": "Condicionais", 
        "fase": 3
    }
]

# ============================================================
# FUNÇÃO PARA ATUALIZAR FIRESTORE
# ============================================================

def popular_colecao(nome, dados):
    ref = db.collection(nome)
    antigos = ref.stream()
    count = 0
    for doc in antigos:
        doc.reference.delete()
        count += 1
    print(f"🗑️ {count} documentos antigos deletados de '{nome}'.")

    for item in dados:
        ref.add(item)
    print(f"✅ {len(dados)} novos documentos criados em '{nome}'.\n")

# ============================================================
# EXECUTAR POPULAÇÃO
# ============================================================

print("\n--- Processando Coleção: batalhas_perguntas ---")
popular_colecao("batalhas_perguntas", dados_fase1_e_fase2)

print("\n--- Processando Coleção: desafio_montar_codigo ---")
popular_colecao("desafio_montar_codigo", dados_fase3_drag_drop)

print("\n🚀 População de dados do desafio concluída com sucesso!")
print(f"Total de perguntas (Fase 1 e 2): {len(dados_fase1_e_fase2)}")
print(f"Total de perguntas (Fase 3): {len(dados_fase3_drag_drop)}")