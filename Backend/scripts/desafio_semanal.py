# ============================================
#  DESAFIO SEMANAL - POPULAR FIREBASE (CORRIGIDO)
# ============================================
import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.Certificate("../firebase-service-account.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

print("✅ Conexão com Firebase estabelecida.\n")
print("Iniciando população de todas as coleções do Desafio Semanal...\n")

# ============================================================
# FASE 1 – QUESTÕES TRADICIONAIS (Múltipla escolha)
# Coleção: batalhas_perguntas
# ============================================================

fase1_questions = [
    # ============================
    # VARIÁVEIS E TIPOS (6)
    # ============================
    {
        "pergunta": "Qual tipo de dado armazena números inteiros no Python?",
        "opcoes": ["int", "float", "string", "bool"],
        "resposta_correta": "int",
        "modulo": "Variáveis",
        "nivel": "Fácil",
        "fase": 1
    },
    {
        "pergunta": "Qual tipo é usado para texto em Python?",
        "opcoes": ["str", "int", "bool", "float"],
        "resposta_correta": "str",
        "modulo": "Variáveis",
        "nivel": "Fácil",
        "fase": 1
    },
    {
        "pergunta": "Qual é o valor padrão para variáveis não inicializadas em Python?",
        "opcoes": ["0", "None", "False", "\"\""],
        "resposta_correta": "None",
        "modulo": "Variáveis",
        "nivel": "Médio",
        "fase": 1
    },
    {
        "pergunta": "O que a função type() retorna?",
        "opcoes": ["O tamanho da variável", "O tipo da variável", "O valor da variável", "Nada"],
        "resposta_correta": "O tipo da variável",
        "modulo": "Variáveis",
        "nivel": "Médio",
        "fase": 1
    },
    {
        "pergunta": "Qual tipo representa números com casas decimais?",
        "opcoes": ["int", "float", "str", "bool"],
        "resposta_correta": "float",
        "modulo": "Variáveis",
        "nivel": "Difícil",
        "fase": 1
    },
    {
        "pergunta": "Qual desses é um valor booleano válido?",
        "opcoes": ["TRUE", "true", "False", "0"],
        "resposta_correta": "False",
        "modulo": "Variáveis",
        "nivel": "Difícil",
        "fase": 1
    },

    # ============================
    # CONDICIONAIS (6)
    # ============================
    {
        "pergunta": "Qual palavra-chave inicia uma condição em Python?",
        "opcoes": ["if", "when", "case", "switch"],
        "resposta_correta": "if",
        "modulo": "Condicionais",
        "nivel": "Fácil",
        "fase": 1
    },
    {
        "pergunta": "Qual comando representa uma alternativa?",
        "opcoes": ["else", "elif", "otherwise", "except"],
        "resposta_correta": "else",
        "modulo": "Condicionais",
        "nivel": "Fácil",
        "fase": 1
    },
    {
        "pergunta": "Qual operador verifica igualdade?",
        "opcoes": ["=", "==", "===", ":="],
        "resposta_correta": "==",
        "modulo": "Condicionais",
        "nivel": "Médio",
        "fase": 1
    },
    {
        "pergunta": "Qual operador representa diferença?",
        "opcoes": ["<>", "=/=", "!=", "diff"],
        "resposta_correta": "!=",
        "modulo": "Condicionais",
        "nivel": "Médio",
        "fase": 1
    },
    {
        "pergunta": "Como escrever uma condição 'entre 10 e 20' em Python?",
        "opcoes": ["10 < x < 20", "x > 10 > 20", "x in 10..20", "if range(10,20)"],
        "resposta_correta": "10 < x < 20",
        "modulo": "Condicionais",
        "nivel": "Difícil",
        "fase": 1
    },
    {
        "pergunta": "Qual alternativa representa múltiplas condições?",
        "opcoes": ["if-if", "if...else", "if...elif...else", "switch"],
        "resposta_correta": "if...elif...else",
        "modulo": "Condicionais",
        "nivel": "Difícil",
        "fase": 1
    },

    # ============================
    # LAÇOS DE REPETIÇÃO (6)
    # ============================
    {
        "pergunta": "Qual laço repete até a condição ser falsa?",
        "opcoes": ["for", "repeat", "while", "loop"],
        "resposta_correta": "while",
        "modulo": "Laços",
        "nivel": "Fácil",
        "fase": 1
    },
    {
        "pergunta": "Qual laço itera sobre listas?",
        "opcoes": ["for", "loop", "iterate", "scan"],
        "resposta_correta": "for",
        "modulo": "Laços",
        "nivel": "Fácil",
        "fase": 1
    },
    {
        "pergunta": "Qual comando encerra um laço?",
        "opcoes": ["end", "exit", "break", "stop"],
        "resposta_correta": "break",
        "modulo": "Laços",
        "nivel": "Médio",
        "fase": 1
    },
    {
        "pergunta": "Qual comando pula a iteração atual?",
        "opcoes": ["pass", "skip", "continue", "ignore"],
        "resposta_correta": "continue",
        "modulo": "Laços",
        "nivel": "Médio",
        "fase": 1
    },
    {
        "pergunta": "Qual sintaxe cria um range até 10?",
        "opcoes": ["range(10)", "range(1,10)", "range(0,9)", "range(to 10)"],
        "resposta_correta": "range(10)",
        "modulo": "Laços",
        "nivel": "Difícil",
        "fase": 1
    },
    {
        "pergunta": "Qual desses é um loop infinito válido?",
        "opcoes": ["while True:", "for forever:", "loop()", "while 1 = 1"],
        "resposta_correta": "while True:",
        "modulo": "Laços",
        "nivel": "Difícil",
        "fase": 1
    }
]

# ============================================================
# FASE 2 – MONTAR CÓDIGO
# ============================================================

fase2_montar_codigo = [
    {
        "titulo": "Imprimir números",
        "partes_codigo": ["for i in range(5):", "print(i)"],
        "corretas": [0, 1],
        "fase": 2
    },
    {
        "titulo": "Verificar maioridade",
        "partes_codigo": ["idade = 18", "if idade >= 18:", "print('Maior de idade')"],
        "corretas": [0, 1, 2],
        "fase": 2
    },
    {
        "titulo": "Somar valores",
        "partes_codigo": ["a = 3", "b = 7", "print(a + b)"],
        "corretas": [0, 1, 2],
        "fase": 2
    },
    {
        "titulo": "Contar até 10",
        "partes_codigo": ["i = 1", "while i <= 10:", "print(i)", "i += 1"],
        "corretas": [0, 1, 2, 3],
        "fase": 2
    },
    {
        "titulo": "Saudação",
        "partes_codigo": ["nome = 'Pedro'", "print('Olá, ' + nome)"],
        "corretas": [0, 1],
        "fase": 2
    },
    {
        "titulo": "Imprimir pares",
        "partes_codigo": ["for i in range(0,10,2):", "print(i)"],
        "corretas": [0, 1],
        "fase": 2
    }
]

# ============================================================
# FASE 3 – CARTÕES
# ============================================================

fase3_cards = [
    {
        "pergunta": "O que é uma função?",
        "resposta": "Um bloco reutilizável de código.",
        "fase": 3
    },
    {
        "pergunta": "Para que serve o return?",
        "resposta": "Devolver um valor ao chamar uma função.",
        "fase": 3
    },
    {
        "pergunta": "Qual palavra cria funções em Python?",
        "resposta": "def",
        "fase": 3
    },
    {
        "pergunta": "O que é um parâmetro?",
        "resposta": "Um valor recebido pela função.",
        "fase": 3
    },
    {
        "pergunta": "O que é um loop?",
        "resposta": "Repetição de instruções.",
        "fase": 3
    },
    {
        "pergunta": "O que é um booleano?",
        "resposta": "Tipo lógico True ou False.",
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

    print(f"🗑️ {count} documentos antigos deletados.")

    for item in dados:
        ref.add(item)

    print(f"✅ {len(dados)} novos documentos criados em '{nome}'.\n")


# ============================================================
# EXECUTAR TODAS AS FASES
# ============================================================

print("\n--- Processando Coleção: batalhas_perguntas ---")
popular_colecao("batalhas_perguntas", fase1_questions)

print("\n--- Processando Coleção: desafio_montar_codigo ---")
popular_colecao("desafio_montar_codigo", fase2_montar_codigo)

print("\n--- Processando Coleção: desafio_perguntas ---")
popular_colecao("desafio_perguntas", fase3_cards)

print("\n🚀 População de dados do desafio concluída com sucesso nas 3 FASES!")
