import firebase_admin
from firebase_admin import credentials, firestore
import os

# Caminho do arquivo de credenciais
cred = credentials.Certificate("../firebase-service-account.json")
firebase_admin.initialize_app(cred)

db = firestore.client()

# ==========================
# LISTA DE PERGUNTAS
# COM NÍVEL SUPER DIFÍCIL
# ==========================

questions_data = [
    # ---------------------- #
    #   EXEMPLOS SUPER DIFÍCIL
    # ---------------------- #
    {
        "nivel": "SuperDificil",
        "idPergunta": "9000",
        "tipo": "Variáveis e Tipos de Dados",
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
        "nivel": "SuperDificil",
        "idPergunta": "9001",
        "tipo": "Condicionais",
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
        "nivel": "SuperDificil",
        "idPergunta": "9002",
        "tipo": "Laços de Repetição",
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
        "nivel": "SuperDificil",
        "idPergunta": "9003",
        "tipo": "Funções",
        "pergunta": "O que caracteriza um fechamento ('closure') com captura por referência em linguagens funcionais?",
        "opcoes": [
            "A função mantém acesso ao valor atual da variável capturada",
            "A função copia o valor da variável e ignora mudanças futuras",
            "A função perde o escopo original",
            "A função não pode acessar variáveis externas"
        ],
        "resposta_correta": "A função mantém acesso ao valor atual da variável capturada"
    },

    # ==============================================
    # ➤ AQUI VOCÊ INSERE TODAS AS SUAS PERGUNTAS EXISTENTES
    # (as que você enviou na mensagem)
    # Basta copiar e colar elas abaixo!
    # ==============================================

    # EXEMPLO: (copie todas as suas perguntas abaixo)
    {
        "nivel": "Facil",
        "idPergunta": "1000",
        "tipo": "Variáveis e Tipos de Dados",
        "pergunta": "O que é uma variável em programação?",
        "opcoes": ["Um valor fixo", "Um nome que armazena dados", "Um operador lógico", "Um tipo de dado numérico"],
        "resposta_correta": "Um nome que armazena dados"
    },
    
    {
        "nivel": "Facil",
        "idPergunta": "5000",
        "tipo": "Variáveis e Tipos de Dados",
        "pergunta": "O que é uma variável em programação?",
        "opcoes": ["Um valor fixo", "Um local que armazena dados", "Um tipo de erro", "Um comando de repetição"],
        "resposta_correta": "Um local que armazena dados"
    },
    {
        "nivel": "Facil",
        "idPergunta": "5001",
        "tipo": "Variáveis e Tipos de Dados",
        "pergunta": "Qual tipo de dado representa textos?",
        "opcoes": ["String", "Boolean", "Float", "Int"],
        "resposta_correta": "String"
    },
    {
        "nivel": "Facil",
        "idPergunta": "5002",
        "tipo": "Variáveis e Tipos de Dados",
        "pergunta": "Valores true e false pertencem a qual tipo?",
        "opcoes": ["Inteiro", "Booleano", "Caractere", "Decimal"],
        "resposta_correta": "Booleano"
    },
    {
        "nivel": "Facil",
        "idPergunta": "5003",
        "tipo": "Variáveis e Tipos de Dados",
        "pergunta": "Qual tipo de dado deve armazenar a idade?",
        "opcoes": ["Boolean", "String", "Int", "Array"],
        "resposta_correta": "Int"
    },
    {
        "nivel": "Facil",
        "idPergunta": "5004",
        "tipo": "Variáveis e Tipos de Dados",
        "pergunta": "3.14 é de qual tipo de dado?",
        "opcoes": ["Float", "String", "Boolean", "Array"],
        "resposta_correta": "Float"
    },

    {
        "nivel": "Medio",
        "idPergunta": "5005",
        "tipo": "Variáveis e Tipos de Dados",
        "pergunta": "O que acontece ao usar uma variável não declarada?",
        "opcoes": ["Ela vira 0 automaticamente", "Um erro ocorre", "Ela é criada sozinha", "Não muda nada"],
        "resposta_correta": "Um erro ocorre"
    },
    {
        "nivel": "Medio",
        "idPergunta": "5006",
        "tipo": "Variáveis e Tipos de Dados",
        "pergunta": "Qual tipo de dado deve armazenar '29.7'?",
        "opcoes": ["Int", "Boolean", "Float", "Char"],
        "resposta_correta": "Float"
    },
    {
        "nivel": "Medio",
        "idPergunta": "5007",
        "tipo": "Variáveis e Tipos de Dados",
        "pergunta": "Qual dessas opções NÃO é um tipo primitivo?",
        "opcoes": ["Int", "String", "Boolean", "Array"],
        "resposta_correta": "Array"
    },
    {
        "nivel": "Medio",
        "idPergunta": "5008",
        "tipo": "Variáveis e Tipos de Dados",
        "pergunta": "Qual tipo deve armazenar apenas um caractere?",
        "opcoes": ["String", "Boolean", "Char", "Float"],
        "resposta_correta": "Char"
    },
    {
        "nivel": "Medio",
        "idPergunta": "5009",
        "tipo": "Variáveis e Tipos de Dados",
        "pergunta": "Qual a diferença entre Int e Float?",
        "opcoes": ["Int aceita letras", "Float só aceita negativos", "Int é inteiro e Float permite decimais", "Não existe diferença"],
        "resposta_correta": "Int é inteiro e Float permite decimais"
    },

    {
        "nivel": "Dificil",
        "idPergunta": "5010",
        "tipo": "Variáveis e Tipos de Dados",
        "pergunta": "O que é tipagem forte?",
        "opcoes": ["Linguagem é rápida", "Tipos são convertidos automaticamente", "Variáveis têm tipo rígido e incompatível com outros", "Código sempre compila"],
        "resposta_correta": "Variáveis têm tipo rígido e incompatível com outros"
    },
    {
        "nivel": "Dificil",
        "idPergunta": "5011",
        "tipo": "Variáveis e Tipos de Dados",
        "pergunta": "Qual a vantagem da tipagem estática?",
        "opcoes": ["Menos erros em tempo de execução", "Código mais lento", "Gasta mais memória", "Permite tipos indefinidos"],
        "resposta_correta": "Menos erros em tempo de execução"
    },
    {
        "nivel": "Dificil",
        "idPergunta": "5012",
        "tipo": "Variáveis e Tipos de Dados",
        "pergunta": "Qual tipo de dado é ideal para armazenar um CPF?",
        "opcoes": ["Int", "Float", "String", "Boolean"],
        "resposta_correta": "String"
    },
    {
        "nivel": "Dificil",
        "idPergunta": "5013",
        "tipo": "Variáveis e Tipos de Dados",
        "pergunta": "Qual problema pode ocorrer ao armazenar dinheiro em Float?",
        "opcoes": ["Divisão por zero", "Perda de precisão", "Erro de sintaxe", "Conversão automática"],
        "resposta_correta": "Perda de precisão"
    },
    {
        "nivel": "Dificil",
        "idPergunta": "5014",
        "tipo": "Variáveis e Tipos de Dados",
        "pergunta": "Qual é a função do 'null'?",
        "opcoes": ["Representar texto vazio", "Representar ausência de valor", "Representar zero", "Reservar memória automática"],
        "resposta_correta": "Representar ausência de valor"
    },

    {
        "nivel": "Muito Dificil",
        "idPergunta": "5015",
        "tipo": "Variáveis e Tipos de Dados",
        "pergunta": "O que significa imutabilidade em tipos de dados?",
        "opcoes": ["O valor pode mudar livremente", "O valor nunca muda após criado", "O tipo muda automaticamente", "A variável se apaga sozinha"],
        "resposta_correta": "O valor nunca muda após criado"
    },
    {
        "nivel": "Muito Dificil",
        "idPergunta": "5016",
        "tipo": "Variáveis e Tipos de Dados",
        "pergunta": "Por que comparar floats diretamente pode ser perigoso?",
        "opcoes": ["Porque são lentos", "Porque perdem precisão em binário", "Porque se convertem em int", "Porque retornam sempre falso"],
        "resposta_correta": "Porque perdem precisão em binário"
    },
    {
        "nivel": "Muito Dificil",
        "idPergunta": "5017",
        "tipo": "Variáveis e Tipos de Dados",
        "pergunta": "Qual problema 'overflow' causa?",
        "opcoes": ["Valor vira negativo ou zero", "Programa trava sempre", "Variável vira boolean", "Código não compila"],
        "resposta_correta": "Valor vira negativo ou zero"
    },
    {
        "nivel": "Muito Dificil",
        "idPergunta": "5018",
        "tipo": "Variáveis e Tipos de Dados",
        "pergunta": "O que é coerção de tipos?",
        "opcoes": ["Remover variáveis", "Converter tipos automaticamente", "Apagar memória", "Criar funções"],
        "resposta_correta": "Converter tipos automaticamente"
    },
    {
        "nivel": "Muito Dificil",
        "idPergunta": "5019",
        "tipo": "Variáveis e Tipos de Dados",
        "pergunta": "O que significa 'type safety'?",
        "opcoes": ["Garantia de uso correto dos tipos", "Código nunca dá erro", "Variáveis são ilimitadas", "Tipos mudam automaticamente"],
        "resposta_correta": "Garantia de uso correto dos tipos"
    },
     {
        "nivel": "Facil",
        "idPergunta": "5100",
        "tipo": "Condicionais",
        "pergunta": "Para que serve uma estrutura condicional?",
        "opcoes": ["Repetir código", "Armazenar dados", "Tomar decisões", "Criar funções"],
        "resposta_correta": "Tomar decisões"
    },
    {
        "nivel": "Facil",
        "idPergunta": "5101",
        "tipo": "Condicionais",
        "pergunta": "Qual palavra é usada para iniciar uma condição?",
        "opcoes": ["if", "for", "var", "function"],
        "resposta_correta": "if"
    },
    {
        "nivel": "Facil",
        "idPergunta": "5102",
        "tipo": "Condicionais",
        "pergunta": "Qual palavra representa alternativa caso o 'if' seja falso?",
        "opcoes": ["stop", "else", "while", "return"],
        "resposta_correta": "else"
    },
    {
        "nivel": "Facil",
        "idPergunta": "5103",
        "tipo": "Condicionais",
        "pergunta": "Qual operador significa 'igual a' em muitas linguagens?",
        "opcoes": ["=", "==", "=>", ":="],
        "resposta_correta": "=="
    },
    {
        "nivel": "Facil",
        "idPergunta": "5104",
        "tipo": "Condicionais",
        "pergunta": "Qual operador lógico representa 'e'?",
        "opcoes": ["&&", "||", "==", "!="],
        "resposta_correta": "&&"
    },

    {
        "nivel": "Medio",
        "idPergunta": "5105",
        "tipo": "Condicionais",
        "pergunta": "Qual operador lógico representa 'ou'?",
        "opcoes": ["==", "||", "<>", "&&"],
        "resposta_correta": "||"
    },
    {
        "nivel": "Medio",
        "idPergunta": "5106",
        "tipo": "Condicionais",
        "pergunta": "O que o bloco 'else if' permite?",
        "opcoes": ["Criar loops", "Várias verificações", "Apagar variáveis", "Criar arrays"],
        "resposta_correta": "Várias verificações"
    },
    {
        "nivel": "Medio",
        "idPergunta": "5107",
        "tipo": "Condicionais",
        "pergunta": "O que significa '!='?",
        "opcoes": ["Maior que", "Menor que", "Diferente de", "Igual a"],
        "resposta_correta": "Diferente de"
    },
    {
        "nivel": "Medio",
        "idPergunta": "5108",
        "tipo": "Condicionais",
        "pergunta": "Qual estrutura substitui vários if-else?",
        "opcoes": ["switch", "loop", "array", "object"],
        "resposta_correta": "switch"
    },
    {
        "nivel": "Medio",
        "idPergunta": "5109",
        "tipo": "Condicionais",
        "pergunta": "Qual resultado de (5 > 2 && 3 < 1)?",
        "opcoes": ["true", "false", "5", "undefined"],
        "resposta_correta": "false"
    },

    {
        "nivel": "Dificil",
        "idPergunta": "5110",
        "tipo": "Condicionais",
        "pergunta": "O que acontece se duas condições forem verdadeiras no 'if' e 'else if'?",
        "opcoes": ["Ambas executam", "Nenhuma executa", "Somente o primeiro 'if' executa", "A última executa"],
        "resposta_correta": "Somente o primeiro 'if' executa"
    },
    {
        "nivel": "Dificil",
        "idPergunta": "5111",
        "tipo": "Condicionais",
        "pergunta": "Qual problema pode ocorrer em condições muito longas com '&&' e '||'?",
        "opcoes": ["Loop infinito", "Baixa legibilidade e erros lógicos", "Memória cheia", "Sempre retorna true"],
        "resposta_correta": "Baixa legibilidade e erros lógicos"
    },
    {
        "nivel": "Dificil",
        "idPergunta": "5112",
        "tipo": "Condicionais",
        "pergunta": "Qual conceito descreve condições que nunca podem ser verdadeiras?",
        "opcoes": ["Condição morta", "Overflow", "Imutabilidade", "Casting"],
        "resposta_correta": "Condição morta"
    },
    {
        "nivel": "Dificil",
        "idPergunta": "5113",
        "tipo": "Condicionais",
        "pergunta": "O que é curto-circuito em operações lógicas?",
        "opcoes": ["Travamento do PC", "Parada na primeira comparação necessária", "Loop rápido", "Erro de sintaxe"],
        "resposta_correta": "Parada na primeira comparação necessária"
    },
    {
        "nivel": "Dificil",
        "idPergunta": "5114",
        "tipo": "Condicionais",
        "pergunta": "Qual problema ocorre em '(x = 5)' usado no lugar de '(x == 5)'?",
        "opcoes": ["Nada", "Switch falha", "Atribuição indesejada", "Retorna null"],
        "resposta_correta": "Atribuição indesejada"
    },

    {
        "nivel": "Muito Dificil",
        "idPergunta": "5115",
        "tipo": "Condicionais",
        "pergunta": "Qual é o problema principal de aninhar muitos if-else?",
        "opcoes": ["Aumenta velocidade", "Diminui legibilidade e dificulta manutenção", "Cria arrays", "Perde variáveis"],
        "resposta_correta": "Diminui legibilidade e dificulta manutenção"
    },
    {
        "nivel": "Muito Dificil",
        "idPergunta": "5116",
        "tipo": "Condicionais",
        "pergunta": "Por que usar 'switch' pode evitar erros em condições grandes?",
        "opcoes": ["Porque é mais rápido sempre", "Porque organiza melhor vários casos", "Porque usa loops", "Porque converte tipos"],
        "resposta_correta": "Porque organiza melhor vários casos"
    },
    {
        "nivel": "Muito Dificil",
        "idPergunta": "5117",
        "tipo": "Condicionais",
        "pergunta": "O que são condições mutuamente exclusivas?",
        "opcoes": ["Nunca são verdadeiras juntas", "Sempre verdadeiras juntas", "Criam loops", "Geram arrays"],
        "resposta_correta": "Nunca são verdadeiras juntas"
    },
    {
        "nivel": "Muito Dificil",
        "idPergunta": "5118",
        "tipo": "Condicionais",
        "pergunta": "Por que '(x === 1)' é mais seguro que '(x == 1)'?",
        "opcoes": ["É mais rápido", "Não permite coerção de tipos", "Cria variáveis", "Desliga o código"],
        "resposta_correta": "Não permite coerção de tipos"
    },
    {
        "nivel": "Muito Dificil",
        "idPergunta": "5119",
        "tipo": "Condicionais",
        "pergunta": "O que é uma condição tautológica?",
        "opcoes": ["Sempre falsa", "Sempre verdadeira", "Nunca executa", "Cria funções"],
        "resposta_correta": "Sempre verdadeira"
    }, 
    
    {
    "nivel": "Facil",
    "idPergunta": "5300",
    "tipo": "Perguntas Diversas",
    "pergunta": "O que significa 'bug' em programação?",
    "opcoes": ["Uma melhoria no código", "Um erro ou falha no sistema", "Um tipo de variável", "Um comando de repetição"],
    "resposta_correta": "Um erro ou falha no sistema"
},
{
    "nivel": "Facil",
    "idPergunta": "5301",
    "tipo": "Perguntas Diversas",
    "pergunta": "O que é um algoritmo?",
    "opcoes": ["Um tipo de computador", "Um conjunto de instruções", "Uma linguagem de programação", "Um erro no código"],
    "resposta_correta": "Um conjunto de instruções"
},
{
    "nivel": "Facil",
    "idPergunta": "5302",
    "tipo": "Perguntas Diversas",
    "pergunta": "Qual é o objetivo de comentar um código?",
    "opcoes": ["Fazer o código rodar mais rápido", "Explicar partes do código", "Adicionar funções extras", "Criar novas variáveis"],
    "resposta_correta": "Explicar partes do código"
},
{
    "nivel": "Facil",
    "idPergunta": "5303",
    "tipo": "Perguntas Diversas",
    "pergunta": "Qual é o arquivo que normalmente inicia um projeto?",
    "opcoes": ["main", "config", "output", "data"],
    "resposta_correta": "main"
},
{
    "nivel": "Facil",
    "idPergunta": "5304",
    "tipo": "Perguntas Diversas",
    "pergunta": "O que é um 'print' em programação?",
    "opcoes": ["Um comando para mostrar algo na tela", "Um comando para deletar dados", "Uma função de repetição", "Um tipo de variável"],
    "resposta_correta": "Um comando para mostrar algo na tela"
},
{
    "nivel": "Medio",
    "idPergunta": "5310",
    "tipo": "Perguntas Diversas",
    "pergunta": "O que significa 'debugar' um programa?",
    "opcoes": ["Adicionar novas funções", "Procurar e corrigir erros", "Criar loops", "Gerar relatórios"],
    "resposta_correta": "Procurar e corrigir erros"
},
{
    "nivel": "Medio",
    "idPergunta": "5311",
    "tipo": "Perguntas Diversas",
    "pergunta": "O que é um IDE?",
    "opcoes": ["Um tipo de dado", "Um ambiente de desenvolvimento", "Um erro lógico", "Uma estrutura de repetição"],
    "resposta_correta": "Um ambiente de desenvolvimento"
},
{
    "nivel": "Medio",
    "idPergunta": "5312",
    "tipo": "Perguntas Diversas",
    "pergunta": "Qual termo descreve código reutilizável?",
    "opcoes": ["Composto", "Modular", "Fragmentado", "Simples"],
    "resposta_correta": "Modular"
},
{
    "nivel": "Medio",
    "idPergunta": "5313",
    "tipo": "Perguntas Diversas",
    "pergunta": "O que é um repositório?",
    "opcoes": ["Um local para armazenar arquivos de código", "Um comando de execução", "Uma linguagem de programação", "Um tipo de loop"],
    "resposta_correta": "Um local para armazenar arquivos de código"
},
{
    "nivel": "Medio",
    "idPergunta": "5314",
    "tipo": "Perguntas Diversas",
    "pergunta": "O que é uma API?",
    "opcoes": ["Um sistema operacional", "Um conjunto de regras para comunicação entre sistemas", "Um compilador", "Um banco de dados"],
    "resposta_correta": "Um conjunto de regras para comunicação entre sistemas"
}, 

{
    "nivel": "Dificil",
    "idPergunta": "5320",
    "tipo": "Perguntas Diversas",
    "pergunta": "O que é um 'parâmetro' em programação?",
    "opcoes": ["Um valor fixo", "Um dado passado para uma função", "Um tipo de loop", "Um operador lógico"],
    "resposta_correta": "Um dado passado para uma função"
},
{
    "nivel": "Dificil",
    "idPergunta": "5321",
    "tipo": "Perguntas Diversas",
    "pergunta": "O que é 'complexidade de tempo'?",
    "opcoes": ["A dificuldade do usuário", "Quanto espaço o programa usa", "Quanto tempo o algoritmo leva para rodar", "A quantidade de funções no código"],
    "resposta_correta": "Quanto tempo o algoritmo leva para rodar"
},
{
    "nivel": "Dificil",
    "idPergunta": "5322",
    "tipo": "Perguntas Diversas",
    "pergunta": "O que caracteriza um erro lógico?",
    "opcoes": ["O código não compila", "O programa roda, mas gera resultados errados", "O código trava ao iniciar", "O computador reinicia"],
    "resposta_correta": "O programa roda, mas gera resultados errados"
},
{
    "nivel": "Dificil",
    "idPergunta": "5323",
    "tipo": "Perguntas Diversas",
    "pergunta": "O que é versionamento de código?",
    "opcoes": ["Criar versões de um software manualmente", "Gerenciar alterações no código ao longo do tempo", "Compactar programas", "Converter arquivos"],
    "resposta_correta": "Gerenciar alterações no código ao longo do tempo"
},
{
    "nivel": "Dificil",
    "idPergunta": "5324",
    "tipo": "Perguntas Diversas",
    "pergunta": "O que diferencia compilação de interpretação?",
    "opcoes": ["A compilação exige internet", "Compilação traduz tudo antes da execução; interpretação traduz durante a execução", "Interpretadores são mais rápidos sempre", "Compilação é usada apenas em Python"],
    "resposta_correta": "Compilação traduz tudo antes da execução; interpretação traduz durante a execução"
}, 

{
    "nivel": "Muito Dificil",
    "idPergunta": "5330",
    "tipo": "Perguntas Diversas",
    "pergunta": "O que é recursão infinita?",
    "opcoes": ["Quando uma função chama outra", "Quando uma função nunca para de se chamar", "Quando o loop tem 100 iterações", "Quando o programa não compila"],
    "resposta_correta": "Quando uma função nunca para de se chamar"
},
{
    "nivel": "Muito Dificil",
    "idPergunta": "5331",
    "tipo": "Perguntas Diversas",
    "pergunta": "O que é memória heap?",
    "opcoes": ["Região de armazenamento temporário para variáveis dinâmicas", "Armazenamento de constantes", "Lugar onde ficam funções nativas", "Setor do disco rígido"],
    "resposta_correta": "Região de armazenamento temporário para variáveis dinâmicas"
},
{
    "nivel": "Muito Dificil",
    "idPergunta": "5332",
    "tipo": "Perguntas Diversas",
    "pergunta": "O que é um deadlock?",
    "opcoes": ["Uma função que nunca retorna", "Um estado onde processos ficam esperando indefinidamente entre si", "Um erro de compilação", "Uma má prática de escrita"],
    "resposta_correta": "Um estado onde processos ficam esperando indefinidamente entre si"
},
{
    "nivel": "Muito Dificil",
    "idPergunta": "5333",
    "tipo": "Perguntas Diversas",
    "pergunta": "O que é uma thread?",
    "opcoes": ["Um tipo de variável", "Uma linha de execução independente dentro de um processo", "Um comando lógico", "Um formato de arquivo"],
    "resposta_correta": "Uma linha de execução independente dentro de um processo"
},
{
    "nivel": "Muito Dificil",
    "idPergunta": "5334",
    "tipo": "Perguntas Diversas",
    "pergunta": "O que caracteriza programação assíncrona?",
    "opcoes": ["Execução passo a passo somente", "Execução que não bloqueia a continuidade do programa", "Execução mais lenta", "Execução sem funções"],
    "resposta_correta": "Execução que não bloqueia a continuidade do programa"
},





    # ... RESTO DAS PERGUNTAS AQUI ...
]

# ==========================
# UPLOAD PARA O FIRESTORE
# ==========================

def enviar_perguntas():
    collection_ref = db.collection("batalhas_perguntas")

    for question in questions_data:
        doc_id = question["idPergunta"]
        print(f"Enviando pergunta {doc_id}...")

        # sobrescreve caso já exista
        collection_ref.document(doc_id).set(question)

    print("\n🔥 Finalizado! Todas as perguntas foram enviadas para o banco.")

if __name__ == "__main__":
    enviar_perguntas()
