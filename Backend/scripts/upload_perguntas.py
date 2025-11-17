import firebase_admin
from firebase_admin import credentials, firestore
import os

# 🚀 VERIFICA O CAMINHO DA SUA CHAVE DO FIREBASE
# (Assumindo que o JSON está na MESMA pasta que este script)
cred_path = "firebase-service-account.json" 
if not os.path.exists(cred_path):
    print(f"Erro: Arquivo de credenciais não encontrado em '{cred_path}'")
    print("Por favor, baixe seu service-account.json e coloque-o nesta pasta.")
    exit()
    
cred = credentials.Certificate(cred_path)
firebase_admin.initialize_app(cred)

db = firestore.client()

# ==================================
# LISTA DE PERGUNTAS UNIFICADAS
# ==================================

questions_data = [
    # ---------------------- #
    #  VARIÁVEIS E TIPOS (Snippets)
    # ---------------------- #
    {
        "modulo": "Variáveis e Tipos",
        "tipo": "codigo_snippet",
        "nivel": "Facil",
        "pergunta": "Qual tipo de dado está sendo usado?",
        "codigo_snippet": "x = 10",
        "opcoes": ["int", "float", "string", "bool"],
        "resposta_correta": "int"
    },
    {
        "modulo": "Variáveis e Tipos",
        "tipo": "codigo_snippet",
        "nivel": "Facil",
        "pergunta": "O que será impresso?",
        "codigo_snippet": "nome = 'Ana'\nprint(nome)",
        "opcoes": ["Ana", "nome", "'Ana'", "Erro"],
        "resposta_correta": "Ana"
    },
    {
        "modulo": "Variáveis e Tipos",
        "tipo": "codigo_snippet",
        "nivel": "Facil",
        "pergunta": "Qual tipo representa números decimais?",
        "codigo_snippet": "valor = 3.14",
        "opcoes": ["float", "int", "string", "bool"],
        "resposta_correta": "float"
    },
    {
        "modulo": "Variáveis e Tipos",
        "tipo": "codigo_snippet",
        "nivel": "Facil",
        "pergunta": "Qual é o tipo da variável 'flag'?",
        "codigo_snippet": "flag = True",
        "opcoes": ["bool", "int", "string", "float"],
        "resposta_correta": "bool"
    },
    {
        "modulo": "Variáveis e Tipos",
        "tipo": "codigo_snippet",
        "nivel": "Medio",
        "pergunta": "Qual será o resultado?",
        "codigo_snippet": "a = 5\nb = 3\ntotal = a + b\nprint(total)",
        "opcoes": ["8", "53", "5+3", "Erro"],
        "resposta_correta": "8"
    },
    {
        "modulo": "Variáveis e Tipos",
        "tipo": "codigo_snippet",
        "nivel": "Medio",
        "pergunta": "Qual tipo da variável result?",
        "codigo_snippet": "result = 10 / 2",
        "opcoes": ["float", "int", "string", "bool"],
        "resposta_correta": "float"
    },
    {
        "modulo": "Variáveis e Tipos",
        "tipo": "codigo_snippet",
        "nivel": "Medio",
        "pergunta": "Qual é o valor final de x?",
        "codigo_snippet": "x = 5\nx = x + 2",
        "opcoes": ["7", "5", "2", "Erro"],
        "resposta_correta": "7"
    },
    {
        "modulo": "Variáveis e Tipos",
        "tipo": "codigo_snippet",
        "nivel": "Dificil",
        "pergunta": "Qual será o tipo de 'resultado'?",
        "codigo_snippet": "a = '5'\nb = 3\nresultado = a * b",
        "opcoes": ["string", "int", "float", "bool"],
        "resposta_correta": "string"
    },
    {
        "modulo": "Variáveis e Tipos",
        "tipo": "codigo_snippet",
        "nivel": "Dificil",
        "pergunta": "O que será impresso?",
        "codigo_snippet": "x = 10\ny = '10'\nprint(x == y)",
        "opcoes": ["False", "True", "10", "Erro"],
        "resposta_correta": "False"
    },
    {
        "modulo": "Variáveis e Tipos",
        "tipo": "codigo_snippet",
        "nivel": "Dificil",
        "pergunta": "O que será impresso?",
        "codigo_snippet": "valor = int('3') + float('2.5')\nprint(valor)",
        "opcoes": ["5.5", "32.5", "Erro", "3 2.5"],
        "resposta_correta": "5.5"
    },

    # ---------------------- #
    #  CONDICIONAIS (Snippets)
    # ---------------------- #
    {
        "modulo": "Condicionais",
        "tipo": "codigo_snippet",
        "nivel": "Facil",
        "pergunta": "O que completa corretamente?",
        "codigo_snippet": "num = 10\nif _________:\n  print('É maior que 5')",
        "opcoes": ["num > 5", "num < 5", "num == 0", "num + 5"],
        "resposta_correta": "num > 5"
    },
    {
        "modulo": "Condicionais",
        "tipo": "codigo_snippet",
        "nivel": "Facil",
        "pergunta": "O que será impresso?",
        "codigo_snippet": "x = 3\nif x == 3:\n  print('Ok')",
        "opcoes": ["Ok", "3", "True", "Nada"],
        "resposta_correta": "Ok"
    },
    {
        "modulo": "Condicionais",
        "tipo": "codigo_snippet",
        "nivel": "Medio",
        "pergunta": "Qual condição verifica se o número é ímpar?",
        "codigo_snippet": "num = 9\nif _________:\n  print('Ímpar')",
        "opcoes": ["num % 2 == 1", "num + 2", "num / 2", "num == 9"],
        "resposta_correta": "num % 2 == 1"
    },
    {
        "modulo": "Condicionais",
        "tipo": "codigo_snippet",
        "nivel": "Medio",
        "pergunta": "O que será impresso?",
        "codigo_snippet": "x = 5\nif x > 10:\n  print('Maior')\nelse:\n  print('Menor')",
        "opcoes": ["Menor", "Maior", "5", "Erro"],
        "resposta_correta": "Menor"
    },
    {
        "modulo": "Condicionais",
        "tipo": "codigo_snippet",
        "nivel": "Medio",
        "pergunta": "Qual condição evita divisão por zero?",
        "codigo_snippet": "num = 10\nif _________:\n  resultado = 10 / num",
        "opcoes": ["num != 0", "num == 0", "num < 0", "num + 1"],
        "resposta_correta": "num != 0"
    },
    {
        "modulo": "Condicionais",
        "tipo": "codigo_snippet",
        "nivel": "Dificil",
        "pergunta": "O que será impresso?",
        "codigo_snippet": "x = 5\ny = 5\nif x > y:\n  print('A')\nelif x == y:\n  print('B')\nelse:\n  print('C')",
        "opcoes": ["B", "A", "C", "Erro"],
        "resposta_correta": "B"
    },
    {
        "modulo": "Condicionais",
        "tipo": "codigo_snippet",
        "nivel": "Dificil",
        "pergunta": "Qual condição completa corretamente?",
        "codigo_snippet": "idade = 18\nif _________:\n  print('Maior de idade')",
        "opcoes": ["idade >= 18", "idade = 18", "idade > 21", "idade != 18"],
        "resposta_correta": "idade >= 18"
    },
    {
        "modulo": "Condicionais",
        "tipo": "codigo_snippet",
        "nivel": "Dificil",
        "pergunta": "O que será impresso?",
        "codigo_snippet": "a = 2\nb = 4\nif a*2 == b:\n  print('Sim')\nelse:\n  print('Não')",
        "opcoes": ["Sim", "Não", "2", "4"],
        "resposta_correta": "Sim"
    },
    {
        "modulo": "Condicionais",
        "tipo": "codigo_snippet",
        "nivel": "Dificil",
        "pergunta": "Qual opção completa corretamente?",
        "codigo_snippet": "x = 4\nif x % 2 == 0 and _________:\n  print('Verdadeiro')",
        "opcoes": ["x > 3", "x < 3", "x == 0", "x == '4'"],
        "resposta_correta": "x > 3"
    },
    {
        "modulo": "Condicionais",
        "tipo": "codigo_snippet",
        "nivel": "Dificil",
        "pergunta": "Qual será a saída?",
        "codigo_snippet": "a = 10\nif a > 5:\n  if a < 20:\n    print('Dentro')",
        "opcoes": ["Dentro", "Fora", "Erro", "10"],
        "resposta_correta": "Dentro"
    },

    # ---------------------- #
    #  LAÇOS (Snippets)
    # ---------------------- #
    {
        "modulo": "Laços de Repetição",
        "tipo": "codigo_snippet",
        "nivel": "Facil",
        "pergunta": "Quantas vezes imprime 'Olá'?",
        "codigo_snippet": "for i in range(3):\n  print('Olá')",
        "opcoes": ["3", "2", "4", "1"],
        "resposta_correta": "3"
    },
    {
        "modulo": "Laços de Repetição",
        "tipo": "codigo_snippet",
        "nivel": "Facil",
        "pergunta": "Qual número NÃO será exibido?",
        "codigo_snippet": "for i in range(1, 4):\n  print(i)",
        "opcoes": ["1", "2", "3", "4"],
        "resposta_correta": "4"
    },
    
    # --------------------------------------------- #
    #  PERGUNTAS DE QUIZ (para a Batalha Aleatória)
    # --------------------------------------------- #
    {
        "modulo": "Variáveis e Tipos", # 🚀 MODULO CORRIGIDO
        "tipo": "quiz",
        "nivel": "SuperDificil",
        "pergunta": "Em linguagens de tipagem forte, qual é o impacto de coerções implícitas mal definidas?",
        "opcoes": [
            "Podem gerar vulnerabilidades e comportamentos indefinidos",
            "Melhoram a performance",
            "Eliminam erros de compilação",
            "Permitem polimorfismo automático"
        ],
        "resposta_correta": "Podem gerar vulnerabilidades e comportamentos indefinidos"
    },
    {
        "modulo": "Condicionais",
        "tipo": "quiz",
        "nivel": "SuperDificil",
        "pergunta": "Em estruturas condicionais complexas, o que caracteriza um 'branch shadowing'?",
        "opcoes": [
            "Quando uma condição impede que outra seja executada por sobreposição lógica",
            "Quando o compilador remove uma condição automaticamente",
            "Quando duas condições são verdadeiras simultaneamente",
            "Quando a condição causa recursão indireta"
        ],
        "resposta_correta": "Quando uma condição impede que outra seja executada por sobreposição lógica"
    },
    {
        "modulo": "Laços de Repetição",
        "tipo": "quiz",
        "nivel": "SuperDificil",
        "pergunta": "Qual é o principal risco em algoritmos que dependem de loops com limites definidos dinamicamente?",
        "opcoes": [
            "Complexidade temporal explosiva",
            "Impossibilidade de compilar",
            "Conversão automática de tipo",
            "Redução de uso de memória"
        ],
        "resposta_correta": "Complexidade temporal explosiva"
    },
    {
        "modulo": "Funções",
        "tipo": "quiz",
        "nivel": "SuperDificil",
        "pergunta": "O que caracteriza um fechamento ('closure') com captura por referência em linguagens funcionais?",
        "opcoes": [
            "A função mantém acesso ao valor atual da variável capturada",
            "A função copia o valor da variável e ignora mudanças futuras",
            "A função perde o escopo original",
            "A função não pode acessar variáveis externas"
        ],
        "resposta_correta": "A função mantém acesso ao valor atual da variável capturada"
    },
    {
        "modulo": "Variáveis e Tipos", # 🚀 MODULO CORRIGIDO
        "tipo": "quiz",
        "nivel": "Facil",
        "pergunta": "O que é uma variável em programação?",
        "opcoes": ["Um valor fixo", "Um nome que armazena dados", "Um operador lógico", "Um tipo de dado numérico"],
        "resposta_correta": "Um nome que armazena dados"
    },
    {
        "modulo": "Variáveis e Tipos", # 🚀 MODULO CORRIGIDO
        "tipo": "quiz",
        "nivel": "Facil",
        "pergunta": "O que é uma variável em programação?",
        "opcoes": ["Um valor fixo", "Um local que armazena dados", "Um tipo de erro", "Um comando de repetição"],
        "resposta_correta": "Um local que armazena dados"
    },
    {
        "modulo": "Variáveis e Tipos", # 🚀 MODULO CORRIGIDO
        "tipo": "quiz",
        "nivel": "Facil",
        "pergunta": "Qual tipo de dado representa textos?",
        "opcoes": ["String", "Boolean", "Float", "Int"],
        "resposta_correta": "String"
    },
    {
        "modulo": "Variáveis e Tipos", # 🚀 MODULO CORRIGIDO
        "tipo": "quiz",
        "nivel": "Facil",
        "pergunta": "Valores true e false pertencem a qual tipo?",
        "opcoes": ["Inteiro", "Booleano", "Caractere", "Decimal"],
        "resposta_correta": "Booleano"
    },
    {
        "modulo": "Variáveis e Tipos", # 🚀 MODULO CORRIGIDO
        "tipo": "quiz",
        "nivel": "Facil",
        "pergunta": "Qual tipo de dado deve armazenar a idade?",
        "opcoes": ["Boolean", "String", "Int", "Array"],
        "resposta_correta": "Int"
    },
    {
        "modulo": "Variáveis e Tipos", # 🚀 MODULO CORRIGIDO
        "tipo": "quiz",
        "nivel": "Facil",
        "pergunta": "3.14 é de qual tipo de dado?",
        "opcoes": ["Float", "String", "Boolean", "Array"],
        "resposta_correta": "Float"
    },
    {
        "modulo": "Variáveis e Tipos", # 🚀 MODULO CORRIGIDO
        "tipo": "quiz",
        "nivel": "Medio",
        "pergunta": "O que acontece ao usar uma variável não declarada?",
        "opcoes": ["Ela vira 0 automaticamente", "Um erro ocorre", "Ela é criada sozinha", "Não muda nada"],
        "resposta_correta": "Um erro ocorre"
    },
    {
        "modulo": "Variáveis e Tipos", # 🚀 MODULO CORRIGIDO
        "tipo": "quiz",
        "nivel": "Medio",
        "pergunta": "Qual tipo de dado deve armazenar '29.7'?",
        "opcoes": ["Int", "Boolean", "Float", "Char"],
        "resposta_correta": "Float"
    },
    {
        "modulo": "Variáveis e Tipos", # 🚀 MODULO CORRIGIDO
        "tipo": "quiz",
        "nivel": "Medio",
        "pergunta": "Qual dessas opções NÃO é um tipo primitivo?",
        "opcoes": ["Int", "String", "Boolean", "Array"],
        "resposta_correta": "Array"
    },
    {
        "modulo": "Variáveis e Tipos", # 🚀 MODULO CORRIGIDO
        "tipo": "quiz",
        "nivel": "Medio",
        "pergunta": "Qual tipo deve armazenar apenas um caractere?",
        "opcoes": ["String", "Boolean", "Char", "Float"],
        "resposta_correta": "Char"
    },
    {
        "modulo": "Variáveis e Tipos", # 🚀 MODULO CORRIGIDO
        "tipo": "quiz",
        "nivel": "Medio",
        "pergunta": "Qual a diferença entre Int e Float?",
        "opcoes": ["Int aceita letras", "Float só aceita negativos", "Int é inteiro e Float permite decimais", "Não existe diferença"],
        "resposta_correta": "Int é inteiro e Float permite decimais"
    },
    {
        "modulo": "Variáveis e Tipos", # 🚀 MODULO CORRIGIDO
        "tipo": "quiz",
        "nivel": "Dificil",
        "pergunta": "O que é tipagem forte?",
        "opcoes": ["Linguagem é rápida", "Tipos são convertidos automaticamente", "Variáveis têm tipo rígido e incompatível com outros", "Código sempre compila"],
        "resposta_correta": "Variáveis têm tipo rígido e incompatível com outros"
    },
    {
        "modulo": "Variáveis e Tipos", # 🚀 MODULO CORRIGIDO
        "tipo": "quiz",
        "nivel": "Dificil",
        "pergunta": "Qual a vantagem da tipagem estática?",
        "opcoes": ["Menos erros em tempo de execução", "Código mais lento", "Gasta mais memória", "Permite tipos indefinidos"],
        "resposta_correta": "Menos erros em tempo de execução"
    },
    {
        "modulo": "Variáveis e Tipos", # 🚀 MODULO CORRIGIDO
        "tipo": "quiz",
        "nivel": "Dificil",
        "pergunta": "Qual tipo de dado é ideal para armazenar um CPF?",
        "opcoes": ["Int", "Float", "String", "Boolean"],
        "resposta_correta": "String"
    },
    {
        "modulo": "Variáveis e Tipos", # 🚀 MODULO CORRIGIDO
        "tipo": "quiz",
        "nivel": "Dificil",
        "pergunta": "Qual problema pode ocorrer ao armazenar dinheiro em Float?",
        "opcoes": ["Divisão por zero", "Perda de precisão", "Erro de sintaxe", "Conversão automática"],
        "resposta_correta": "Perda de precisão"
    },
    {
        "modulo": "Variáveis e Tipos", # 🚀 MODULO CORRIGIDO
        "tipo": "quiz",
        "nivel": "Dificil",
        "pergunta": "Qual é a função do 'null'?",
        "opcoes": ["Representar texto vazio", "Representar ausência de valor", "Representar zero", "Reservar memória automática"],
        "resposta_correta": "Representar ausência de valor"
    },
    {
        "modulo": "Variáveis e Tipos", # 🚀 MODULO CORRIGIDO
        "tipo": "quiz",
        "nivel": "Muito Dificil",
        "pergunta": "O que significa imutabilidade em tipos de dados?",
        "opcoes": ["O valor pode mudar livremente", "O valor nunca muda após criado", "O tipo muda automaticamente", "A variável se apaga sozinha"],
        "resposta_correta": "O valor nunca muda após criado"
    },
    {
        "modulo": "Variáveis e Tipos", # 🚀 MODULO CORRIGIDO
        "tipo": "quiz",
        "nivel": "Muito Dificil",
        "pergunta": "Por que comparar floats diretamente pode ser perigoso?",
        "opcoes": ["Porque são lentos", "Porque perdem precisão em binário", "Porque se convertem em int", "Porque retornam sempre falso"],
        "resposta_correta": "Porque perdem precisão em binário"
    },
    {
        "modulo": "Variáveis e Tipos", # 🚀 MODULO CORRIGIDO
        "tipo": "quiz",
        "nivel": "Muito Dificil",
        "pergunta": "Qual problema 'overflow' causa?",
        "opcoes": ["Valor vira negativo ou zero", "Programa trava sempre", "Variável vira boolean", "Código não compila"],
        "resposta_correta": "Valor vira negativo ou zero"
    },
    {
        "modulo": "Variáveis e Tipos", # 🚀 MODULO CORRIGIDO
        "tipo": "quiz",
        "nivel": "Muito Dificil",
        "pergunta": "O que é coerção de tipos?",
        "opcoes": ["Remover variáveis", "Converter tipos automaticamente", "Apagar memória", "Criar funções"],
        "resposta_correta": "Converter tipos automaticamente"
    },
    {
        "modulo": "Variáveis e Tipos", # 🚀 MODULO CORRIGIDO
        "tipo": "quiz",
        "nivel": "Muito Dificil",
        "pergunta": "O que significa 'type safety'?",
        "opcoes": ["Garantia de uso correto dos tipos", "Código nunca dá erro", "Variáveis são ilimitadas", "Tipos mudam automaticamente"],
        "resposta_correta": "Garantia de uso correto dos tipos"
    },
    {
        "modulo": "Condicionais",
        "tipo": "quiz",
        "nivel": "Facil",
        "pergunta": "Para que serve uma estrutura condicional?",
        "opcoes": ["Repetir código", "Armazenar dados", "Tomar decisões", "Criar funções"],
        "resposta_correta": "Tomar decisões"
    },
    {
        "modulo": "Condicionais",
        "tipo": "quiz",
        "nivel": "Facil",
        "pergunta": "Qual palavra é usada para iniciar uma condição?",
        "opcoes": ["if", "for", "var", "function"],
        "resposta_correta": "if"
    },
    {
        "modulo": "Condicionais",
        "tipo": "quiz",
        "nivel": "Facil",
        "pergunta": "Qual palavra representa alternativa caso o 'if' seja falso?",
        "opcoes": ["stop", "else", "while", "return"],
        "resposta_correta": "else"
    },
    {
        "modulo": "Condicionais",
        "tipo": "quiz",
        "nivel": "Facil",
        "pergunta": "Qual operador significa 'igual a' em muitas linguagens?",
        "opcoes": ["=", "==", "=>", ":="],
        "resposta_correta": "=="
    },
    {
        "modulo": "Condicionais",
        "tipo": "quiz",
        "nivel": "Facil",
        "pergunta": "Qual operador lógico representa 'e'?",
        "opcoes": ["&&", "||", "==", "!="],
        "resposta_correta": "&&"
    },
    {
        "modulo": "Condicionais",
        "tipo": "quiz",
        "nivel": "Medio",
        "pergunta": "Qual operador lógico representa 'ou'?",
        "opcoes": ["==", "||", "<>", "&&"],
        "resposta_correta": "||"
    },
    {
        "modulo": "Condicionais",
        "tipo": "quiz",
        "nivel": "Medio",
        "pergunta": "O que o bloco 'else if' permite?",
        "opcoes": ["Criar loops", "Várias verificações", "Apagar variáveis", "Criar arrays"],
        "resposta_correta": "Várias verificações"
    },
    {
        "modulo": "Condicionais",
        "tipo": "quiz",
        "nivel": "Medio",
        "pergunta": "O que significa '!='?",
        "opcoes": ["Maior que", "Menor que", "Diferente de", "Igual a"],
        "resposta_correta": "Diferente de"
    },
    {
        "modulo": "Condicionais",
        "tipo": "quiz",
        "nivel": "Medio",
        "pergunta": "Qual estrutura substitui vários if-else?",
        "opcoes": ["switch", "loop", "array", "object"],
        "resposta_correta": "switch"
    },
    {
        "modulo": "Condicionais",
        "tipo": "quiz",
        "nivel": "Medio",
        "pergunta": "Qual resultado de (5 > 2 && 3 < 1)?",
        "opcoes": ["true", "false", "5", "undefined"],
        "resposta_correta": "false"
    },
    {
        "modulo": "Condicionais",
        "tipo": "quiz",
        "nivel": "Dificil",
        "pergunta": "O que acontece se duas condições forem verdadeiras no 'if' e 'else if'?",
        "opcoes": ["Ambas executam", "Nenhuma executa", "Somente o primeiro 'if' executa", "A última executa"],
        "resposta_correta": "Somente o primeiro 'if' executa"
    },
    {
        "modulo": "Condicionais",
        "tipo": "quiz",
        "nivel": "Dificil",
        "pergunta": "Qual problema pode ocorrer em condições muito longas com '&&' e '||'?",
        "opcoes": ["Loop infinito", "Baixa legibilidade e erros lógicos", "Memória cheia", "Sempre retorna true"],
        "resposta_correta": "Baixa legibilidade e erros lógicos"
    },
    {
        "modulo": "Condicionais",
        "tipo": "quiz",
        "nivel": "Dificil",
        "pergunta": "Qual conceito descreve condições que nunca podem ser verdadeiras?",
        "opcoes": ["Condição morta", "Overflow", "Imutabilidade", "Casting"],
        "resposta_correta": "Condição morta"
    },
    {
        "modulo": "Condicionais",
        "tipo": "quiz",
        "nivel": "Dificil",
        "pergunta": "O que é curto-circuito em operações lógicas?",
        "opcoes": ["Travamento do PC", "Parada na primeira comparação necessária", "Loop rápido", "Erro de sintaxe"],
        "resposta_correta": "Parada na primeira comparação necessária"
    },
    {
        "modulo": "Condicionais",
        "tipo": "quiz",
        "nivel": "Dificil",
        "pergunta": "Qual problema ocorre em '(x = 5)' usado no lugar de '(x == 5)'?",
        "opcoes": ["Nada", "Switch falha", "Atribuição indesejada", "Retorna null"],
        "resposta_correta": "Atribuição indesejada"
    },
    {
        "modulo": "Condicionais",
        "tipo": "quiz",
        "nivel": "Muito Dificil",
        "pergunta": "Qual é o problema principal de aninhar muitos if-else?",
        "opcoes": ["Aumenta velocidade", "Diminui legibilidade e dificulta manutenção", "Cria arrays", "Perde variáveis"],
        "resposta_correta": "Diminui legibilidade e dificulta manutenção"
    },
    {
        "modulo": "Condicionais",
        "tipo": "quiz",
        "nivel": "Muito Dificil",
        "pergunta": "Por que usar 'switch' pode evitar erros em condições grandes?",
        "opcoes": ["Porque é mais rápido sempre", "Porque organiza melhor vários casos", "Porque usa loops", "Porque converte tipos"],
        "resposta_correta": "Porque organiza melhor vários casos"
    },
    {
        "modulo": "Condicionais",
        "tipo": "quiz",
        "nivel": "Muito Dificil",
        "pergunta": "O que são condições mutuamente exclusivas?",
        "opcoes": ["Nunca são verdadeiras juntas", "Sempre verdadeiras juntas", "Criam loops", "Geram arrays"],
        "resposta_correta": "Nunca são verdadeiras juntas"
    },
    {
        "modulo": "Condicionais",
        "tipo": "quiz",
        "nivel": "Muito Dificil",
        "pergunta": "Por que '(x === 1)' é mais seguro que '(x == 1)'?",
        "opcoes": ["É mais rápido", "Não permite coerção de tipos", "Cria variáveis", "Desliga o código"],
        "resposta_correta": "Não permite coerção de tipos"
    },
    {
        "modulo": "Condicionais",
        "tipo": "quiz",
        "nivel": "Muito Dificil",
        "pergunta": "O que é uma condição tautológica?",
        "opcoes": ["Sempre falsa", "Sempre verdadeira", "Nunca executa", "Cria funções"],
        "resposta_correta": "Sempre verdadeira"
    }, 
    
    {
        "modulo": "Perguntas Diversas",
        "tipo": "quiz",
        "nivel": "Facil",
        "pergunta": "O que significa 'bug' em programação?",
        "opcoes": ["Uma melhoria no código", "Um erro ou falha no sistema", "Um tipo de variável", "Um comando de repetição"],
        "resposta_correta": "Um erro ou falha no sistema"
    },
    {
        "modulo": "Perguntas Diversas",
        "tipo": "quiz",
        "nivel": "Facil",
        "pergunta": "O que é um algoritmo?",
        "opcoes": ["Um tipo de computador", "Um conjunto de instruções", "Uma linguagem de programação", "Um erro no código"],
        "resposta_correta": "Um conjunto de instruções"
    },
    {
        "modulo": "Perguntas Diversas",
        "tipo": "quiz",
        "nivel": "Facil",
        "pergunta": "Qual é o objetivo de comentar um código?",
        "opcoes": ["Fazer o código rodar mais rápido", "Explicar partes do código", "Adicionar funções extras", "Criar novas variáveis"],
        "resposta_correta": "Explicar partes do código"
    },
    {
        "modulo": "Perguntas Diversas",
        "tipo": "quiz",
        "nivel": "Facil",
        "pergunta": "Qual é o arquivo que normalmente inicia um projeto?",
        "opcoes": ["main", "config", "output", "data"],
        "resposta_correta": "main"
    },
    {
        "modulo": "Perguntas Diversas",
        "tipo": "quiz",
        "nivel": "Facil",
        "pergunta": "O que é um 'print' em programação?",
        "opcoes": ["Um comando para mostrar algo na tela", "Um comando para deletar dados", "Uma função de repetição", "Um tipo de variável"],
        "resposta_correta": "Um comando para mostrar algo na tela"
    },
    {
        "modulo": "Perguntas Diversas",
        "tipo": "quiz",
        "nivel": "Medio",
        "pergunta": "O que significa 'debugar' um programa?",
        "opcoes": ["Adicionar novas funções", "Procurar e corrigir erros", "Criar loops", "Gerar relatórios"],
        "resposta_correta": "Procurar e corrigir erros"
    },
    {
        "modulo": "Perguntas Diversas",
        "tipo": "quiz",
        "nivel": "Medio",
        "pergunta": "O que é um IDE?",
        "opcoes": ["Um tipo de dado", "Um ambiente de desenvolvimento", "Um erro lógico", "Uma estrutura de repetição"],
        "resposta_correta": "Um ambiente de desenvolvimento"
    },
    {
        "modulo": "Perguntas Diversas",
        "tipo": "quiz",
        "nivel": "Medio",
        "pergunta": "Qual termo descreve código reutilizável?",
        "opcoes": ["Composto", "Modular", "Fragmentado", "Simples"],
        "resposta_correta": "Modular"
    },
    {
        "modulo": "Perguntas Diversas",
        "tipo": "quiz",
        "nivel": "Medio",
        "pergunta": "O que é um repositório?",
        "opcoes": ["Um local para armazenar arquivos de código", "Um comando de execução", "Uma linguagem de programação", "Um tipo de loop"],
        "resposta_correta": "Um local para armazenar arquivos de código"
    },
    {
        "modulo": "Perguntas Diversas",
        "tipo": "quiz",
        "nivel": "Medio",
        "pergunta": "O que é uma API?",
        "opcoes": ["Um sistema operacional", "Um conjunto de regras para comunicação entre sistemas", "Um compilador", "Um banco de dados"],
        "resposta_correta": "Um conjunto de regras para comunicação entre sistemas"
    }, 
    {
        "modulo": "Perguntas Diversas",
        "tipo": "quiz",
        "nivel": "Dificil",
        "pergunta": "O que é um 'parâmetro' em programação?",
        "opcoes": ["Um valor fixo", "Um dado passado para uma função", "Um tipo de loop", "Um operador lógico"],
        "resposta_correta": "Um dado passado para uma função"
    },
    {
        "modulo": "Perguntas Diversas",
        "tipo": "quiz",
        "nivel": "Dificil",
        "pergunta": "O que é 'complexidade de tempo'?",
        "opcoes": ["A dificuldade do usuário", "Quanto espaço o programa usa", "Quanto tempo o algoritmo leva para rodar", "A quantidade de funções no código"],
        "resposta_correta": "Quanto tempo o algoritmo leva para rodar"
    },
    {
        "modulo": "Perguntas Diversas",
        "tipo": "quiz",
        "nivel": "Dificil",
        "pergunta": "O que caracteriza um erro lógico?",
        "opcoes": ["O código não compila", "O programa roda, mas gera resultados errados", "O código trava ao iniciar", "O computador reinicia"],
        "resposta_correta": "O programa roda, mas gera resultados errados"
    },
    {
        "modulo": "Perguntas Diversas",
        "tipo": "quiz",
        "nivel": "Dificil",
        "pergunta": "O que é versionamento de código?",
        "opcoes": ["Criar versões de um software manualmente", "Gerenciar alterações no código ao longo do tempo", "Compactar programas", "Converter arquivos"],
        "resposta_correta": "Gerenciar alterações no código ao longo do tempo"
    },
    {
        "modulo": "Perguntas Diversas",
        "tipo": "quiz",
        "nivel": "Dificil",
        "pergunta": "O que diferencia compilação de interpretação?",
        "opcoes": ["A compilação exige internet", "Compilação traduz tudo antes da execução; interpretação traduz durante a execução", "Interpretadores são mais rápidos sempre", "Compilação é usada apenas em Python"],
        "resposta_correta": "Compilação traduz tudo antes da execução; interpretação traduz durante a execução"
    }, 
    {
        "modulo": "Perguntas Diversas",
        "tipo": "quiz",
        "nivel": "Muito Dificil",
        "pergunta": "O que é recursão infinita?",
        "opcoes": ["Quando uma função chama outra", "Quando uma função nunca para de se chamar", "Quando o loop tem 100 iterações", "Quando o programa não compila"],
        "resposta_correta": "Quando uma função nunca para de se chamar"
    },
    {
        "modulo": "Perguntas Diversas",
        "tipo": "quiz",
        "nivel": "Muito Dificil",
        "pergunta": "O que é memória heap?",
        "opcoes": ["Região de armazenamento temporário para variáveis dinâmicas", "Armazenamento de constantes", "Lugar onde ficam funções nativas", "Setor do disco rígido"],
        "resposta_correta": "Região de armazenamento temporário para variáveis dinâmicas"
    },
    {
        "modulo": "Perguntas Diversas",
        "tipo": "quiz",
        "nivel": "Muito Dificil",
        "pergunta": "O que é um deadlock?",
        "opcoes": ["Uma função que nunca retorna", "Um estado onde processos ficam esperando indefinidamente entre si", "Um erro de compilação", "Uma má prática de escrita"],
        "resposta_correta": "Um estado onde processos ficam esperando indefinidamente entre si"
    },
    {
        "modulo": "Perguntas Diversas",
        "tipo": "quiz",
        "nivel": "Muito Dificil",
        "pergunta": "O que é uma thread?",
        "opcoes": ["Um tipo de variável", "Uma linha de execução independente dentro de um processo", "Um comando lógico", "Um formato de arquivo"],
        "resposta_correta": "Uma linha de execução independente dentro de um processo"
    },
    {
        "modulo": "Perguntas Diversas",
        "tipo": "quiz",
        "nivel": "Muito Dificil",
        "pergunta": "O que caracteriza programação assíncrona?",
        "opcoes": ["Execução passo a passo somente", "Execução que não bloqueia a continuidade do programa", "Execução mais lenta", "Execução sem funções"],
        "resposta_correta": "Execução que não bloqueia a continuidade do programa"
    },
]

# ==========================
# UPLOAD PARA O FIRESTORE
# ==========================

def enviar_perguntas():
    # 🚀 DUAS COLEÇÕES
    batalha_ref = db.collection("batalhas_perguntas")
    desafio_ref = db.collection("desafio_perguntas") # 🚀 NOVA COLEÇÃO
    
    count_batalha = 0
    count_desafio = 0
    
    print(f"Iniciando upload de {len(questions_data)} perguntas...")

    for question in questions_data:
        # Remove o 'idPergunta' antigo se ele existir
        if "idPergunta" in question:
            del question["idPergunta"]
        
        # 🚀 Converte o 'tipo' antigo para 'modulo' (se necessário)
        #    e define um 'tipo' padrão
        if question.get("modulo") is None:
            question["modulo"] = question.pop("tipo", "Perguntas Diversas")
            if "tipo" not in question: # Garante que o campo 'tipo' exista
                question["tipo"] = "quiz"
        
        # Corrige o nome do módulo se necessário
        if question["modulo"] == "Variáveis e Tipos de Dados":
            question["modulo"] = "Variáveis e Tipos"

        # 🚀 LÓGICA DE SEPARAÇÃO
        if question.get("tipo") == "codigo_snippet":
            # Se for 'codigo_snippet', envia para a coleção de desafio
            # Não precisamos checar o 'nível' aqui
            desafio_ref.add(question)
            count_desafio += 1
            print(f"  -> [DESAFIO] Pergunta adicionada: {question.get('pergunta', 'N/A')[:30]}...")
        else:
            # Se for 'quiz', envia para a coleção de batalha
            # Adiciona o campo 'tipo' se não existir
            if "tipo" not in question:
                question["tipo"] = "quiz"
                
            batalha_ref.add(question)
            count_batalha += 1
            print(f"  -> [BATALHA] Pergunta adicionada: {question.get('pergunta', 'N/A')[:30]}...")


    print(f"\n🔥 Finalizado!")
    print(f"{count_batalha} perguntas enviadas para 'batalhas_perguntas'.")
    print(f"{count_desafio} perguntas enviadas para 'desafio_perguntas'.")

if __name__ == "__main__":
    enviar_perguntas()