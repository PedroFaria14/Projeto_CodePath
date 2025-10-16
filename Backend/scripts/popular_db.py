import firebase_admin
from firebase_admin import credentials, firestore
from google.cloud.firestore_v1.base_query import FieldFilter
import os


cred = credentials.Certificate("../firebase-service-account.json")
firebase_admin.initialize_app(cred)
db = firestore.client()
questions_data = [

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
    "idPergunta": "1001",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "Qual tipo de dado é geralmente usado para representar textos?",
    "opcoes": ["Número", "String", "Booleano", "Função"],
    "resposta_correta": "String"
  },
  {
    "nivel": "Facil",
    "idPergunta": "1002",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "Qual tipo de dado é mais adequado para armazenar valores verdadeiro ou falso?",
    "opcoes": ["Texto", "Booleano", "Número decimal", "Lista"],
    "resposta_correta": "Booleano"
  },
  {
    "nivel": "Facil",
    "idPergunta": "1003",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "Qual destas opções é um exemplo de número inteiro?",
    "opcoes": ["3.5", "‘3’", "3", "verdadeiro"],
    "resposta_correta": "3"
  },
  {
    "nivel": "Facil",
    "idPergunta": "1004",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "O que uma variável faz?",
    "opcoes": ["Executa código", "Armazena valores", "Compara condições", "Repete instruções"],
    "resposta_correta": "Armazena valores"
  },
  {
    "nivel": "Medio",
    "idPergunta": "2000",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "Por que é importante escolher o tipo de dado correto para uma variável?",
    "opcoes": ["Para tornar o código mais colorido", "Para evitar erros e usar memória adequadamente", "Para reduzir linhas de código", "Não tem importância"],
    "resposta_correta": "Para evitar erros e usar memória adequadamente"
  },
  {
    "nivel": "Medio",
    "idPergunta": "2001",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "O que acontece se você tentar armazenar texto em uma variável numérica em muitas linguagens?",
    "opcoes": ["Ela converte automaticamente", "Dá erro ou comportamento inesperado", "Nada muda", "Apaga o texto"],
    "resposta_correta": "Dá erro ou comportamento inesperado"
  },
  {
    "nivel": "Medio",
    "idPergunta": "2002",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "Qual é a principal vantagem de usar variáveis nomeadas?",
    "opcoes": ["Deixam o código mais legível", "Executam mais rápido", "Geram loops automáticos", "Substituem comentários"],
    "resposta_correta": "Deixam o código mais legível"
  },
  {
    "nivel": "Dificil",
    "idPergunta": "3000",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "O que significa 'tipagem dinâmica'?",
    "opcoes": ["Variáveis mudam de valor", "Tipos de dados mudam automaticamente", "Variáveis não podem mudar", "Tipos de dados são fixos"],
    "resposta_correta": "Tipos de dados mudam automaticamente"
  },
  {
    "nivel": "Dificil",
    "idPergunta": "3001",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "O que é um tipo de dado composto?",
    "opcoes": ["Um dado com mais de um valor interno", "Um dado que só aceita texto", "Um número com casas decimais", "Um operador matemático"],
    "resposta_correta": "Um dado com mais de um valor interno"
  },

 
  {
    "nivel": "Facil",
    "idPergunta": "1005",
    "tipo": "Condicionais",
    "pergunta": "O que é uma estrutura condicional?",
    "opcoes": ["Um loop que se repete", "Uma decisão no fluxo do programa", "Um tipo de variável", "Um bloco de texto"],
    "resposta_correta": "Uma decisão no fluxo do programa"
  },
  {
    "nivel": "Facil",
    "idPergunta": "1006",
    "tipo": "Condicionais",
    "pergunta": "O que normalmente é usado para tomar decisões?",
    "opcoes": ["Condições lógicas", "Funções matemáticas", "Laços infinitos", "Comentários"],
    "resposta_correta": "Condições lógicas"
  },
  {
    "nivel": "Facil",
    "idPergunta": "1007",
    "tipo": "Condicionais",
    "pergunta": "Se a condição for verdadeira, o que acontece?",
    "opcoes": ["Nada", "O bloco correspondente é executado", "O programa fecha", "O loop é iniciado"],
    "resposta_correta": "O bloco correspondente é executado"
  },
  {
    "nivel": "Medio",
    "idPergunta": "2003",
    "tipo": "Condicionais",
    "pergunta": "O que significa uma condição composta?",
    "opcoes": ["Duas ou mais condições combinadas", "Uma única comparação simples", "Um comentário no código", "Um tipo de variável"],
    "resposta_correta": "Duas ou mais condições combinadas"
  },
  {
    "nivel": "Medio",
    "idPergunta": "2004",
    "tipo": "Condicionais",
    "pergunta": "Qual operador lógico retorna verdadeiro se ao menos uma condição for verdadeira?",
    "opcoes": ["AND", "NOT", "OR", "XOR"],
    "resposta_correta": "OR"
  },
  {
    "nivel": "Medio",
    "idPergunta": "2005",
    "tipo": "Condicionais",
    "pergunta": "Por que as condicionais são importantes em programas?",
    "opcoes": ["Permitem tomada de decisões", "Tornam o código mais bonito", "Criam funções automaticamente", "Diminuem o tamanho do arquivo"],
    "resposta_correta": "Permitem tomada de decisões"
  },
  {
    "nivel": "Dificil",
    "idPergunta": "3002",
    "tipo": "Condicionais",
    "pergunta": "O que acontece se nenhuma condição for satisfeita e não houver alternativa definida?",
    "opcoes": ["O programa trava", "Nada acontece e o fluxo segue", "Executa a primeira condição", "Entra em loop"],
    "resposta_correta": "Nada acontece e o fluxo segue"
  },
  {
    "nivel": "Dificil",
    "idPergunta": "3003",
    "tipo": "Condicionais",
    "pergunta": "Qual vantagem de combinar condicionais em decisões complexas?",
    "opcoes": ["Permite lógica mais precisa", "Torna o programa mais lento", "Evita funções", "Garante loops infinitos"],
    "resposta_correta": "Permite lógica mais precisa"
  },
  {
    "nivel": "Dificil",
    "idPergunta": "3004",
    "tipo": "Condicionais",
    "pergunta": "O que é uma condição aninhada?",
    "opcoes": ["Uma condição dentro de outra", "Uma variável temporária", "Um comentário", "Um loop"],
    "resposta_correta": "Uma condição dentro de outra"
  },
  {
    "nivel": "Dificil",
    "idPergunta": "3005",
    "tipo": "Condicionais",
    "pergunta": "Por que condicionais ajudam a criar fluxos dinâmicos?",
    "opcoes": ["Porque permitem caminhos diferentes", "Porque apagam erros", "Porque definem tipos de dados", "Porque reduzem memória"],
    "resposta_correta": "Porque permitem caminhos diferentes"
  },

  {
    "nivel": "Facil",
    "idPergunta": "1008",
    "tipo": "Laços de Repetição",
    "pergunta": "O que é um laço de repetição?",
    "opcoes": ["Um tipo de variável", "Uma estrutura que repete um bloco de código", "Uma função matemática", "Um comentário"],
    "resposta_correta": "Uma estrutura que repete um bloco de código"
  },
  {
    "nivel": "Facil",
    "idPergunta": "1009",
    "tipo": "Laços de Repetição",
    "pergunta": "Por que usamos loops?",
    "opcoes": ["Para executar tarefas repetidas automaticamente", "Para tomar decisões", "Para definir variáveis", "Para apagar dados"],
    "resposta_correta": "Para executar tarefas repetidas automaticamente"
  },
  {
    "nivel": "Facil",
    "idPergunta": "1010",
    "tipo": "Laços de Repetição",
    "pergunta": "O que ocorre quando a condição de um loop não é mais satisfeita?",
    "opcoes": ["Ele termina", "Ele trava", "Ele cria outro loop", "Ele apaga variáveis"],
    "resposta_correta": "Ele termina"
  },
  {
    "nivel": "Medio",
    "idPergunta": "2006",
    "tipo": "Laços de Repetição",
    "pergunta": "Qual é uma vantagem dos loops?",
    "opcoes": ["Reduzem código repetido", "Tornam o programa mais lento", "Eliminam condições", "Evita erros de sintaxe"],
    "resposta_correta": "Reduzem código repetido"
  },
  {
    "nivel": "Medio",
    "idPergunta": "2007",
    "tipo": "Laços de Repetição",
    "pergunta": "O que é uma condição de parada em um loop?",
    "opcoes": ["Critério que encerra a repetição", "O nome da variável", "O valor armazenado", "Um tipo de função"],
    "resposta_correta": "Critério que encerra a repetição"
  },
  {
    "nivel": "Medio",
    "idPergunta": "2008",
    "tipo": "Laços de Repetição",
    "pergunta": "O que acontece se um loop não tiver condição de parada?",
    "opcoes": ["Nada", "Cria um loop infinito", "Gera um erro automático", "Ignora o loop"],
    "resposta_correta": "Cria um loop infinito"
  },
  {
    "nivel": "Dificil",
    "idPergunta": "3006",
    "tipo": "Laços de Repetição",
    "pergunta": "Qual vantagem dos loops aninhados?",
    "opcoes": ["Permitem percorrer estruturas mais complexas", "Tornam o código mais lento", "Evitam condicionais", "Reduzem memória"],
    "resposta_correta": "Permitem percorrer estruturas mais complexas"
  },
  {
    "nivel": "Dificil",
    "idPergunta": "3007",
    "tipo": "Laços de Repetição",
    "pergunta": "O que é uma iteração?",
    "opcoes": ["Uma única execução de um loop", "Uma variável booleana", "Um tipo de função", "Um operador lógico"],
    "resposta_correta": "Uma única execução de um loop"
  },
  {
    "nivel": "Dificil",
    "idPergunta": "3008",
    "tipo": "Laços de Repetição",
    "pergunta": "Por que é importante controlar bem a condição de saída?",
    "opcoes": ["Para evitar loops infinitos", "Para mudar tipos de dados", "Para criar variáveis", "Para executar decisões"],
    "resposta_correta": "Para evitar loops infinitos"
  },
  {
    "nivel": "Dificil",
    "idPergunta": "3009",
    "tipo": "Laços de Repetição",
    "pergunta": "Qual é um exemplo comum de uso de loops?",
    "opcoes": ["Percorrer listas de dados", "Criar condicionais", "Declarar funções", "Formatar strings"],
    "resposta_correta": "Percorrer listas de dados"
  },

 
  {
    "nivel": "Facil",
    "idPergunta": "1011",
    "tipo": "Funções",
    "pergunta": "O que é uma função?",
    "opcoes": ["Um bloco de código reutilizável", "Uma variável booleana", "Uma condição", "Um loop infinito"],
    "resposta_correta": "Um bloco de código reutilizável"
  },
  {
    "nivel": "Facil",
    "idPergunta": "1012",
    "tipo": "Funções",
    "pergunta": "Por que usamos funções?",
    "opcoes": ["Para organizar e reutilizar código", "Para criar variáveis automáticas", "Para rodar loops", "Para apagar erros"],
    "resposta_correta": "Para organizar e reutilizar código"
  },
  {
    "nivel": "Facil",
    "idPergunta": "1013",
    "tipo": "Funções",
    "pergunta": "O que uma função pode retornar?",
    "opcoes": ["Apenas números", "Qualquer tipo de valor", "Somente strings", "Nada"],
    "resposta_correta": "Qualquer tipo de valor"
  },
  {
    "nivel": "Medio",
    "idPergunta": "2009",
    "tipo": "Funções",
    "pergunta": "O que é um parâmetro de função?",
    "opcoes": ["Um valor recebido pela função", "Um tipo de loop", "Uma variável global", "Um comentário"],
    "resposta_correta": "Um valor recebido pela função"
  },
  {
    "nivel": "Medio",
    "idPergunta": "2010",
    "tipo": "Funções",
    "pergunta": "Qual é a principal vantagem de usar funções em programas grandes?",
    "opcoes": ["Facilitam a manutenção e leitura", "Aceleram loops", "Evitam variáveis", "Reduzem a lógica"],
    "resposta_correta": "Facilitam a manutenção e leitura"
  },
  {
    "nivel": "Medio",
    "idPergunta": "2011",
    "tipo": "Funções",
    "pergunta": "O que é escopo de função?",
    "opcoes": ["O conjunto de variáveis visíveis dentro da função", "O número de loops usados", "Um tipo de comentário", "Um erro comum"],
    "resposta_correta": "O conjunto de variáveis visíveis dentro da função"
  },
  {
    "nivel": "Dificil",
    "idPergunta": "3010",
    "tipo": "Funções",
    "pergunta": "Qual é a diferença entre parâmetro e argumento?",
    "opcoes": ["Parâmetro é definido na função, argumento é passado ao chamar", "São iguais", "Argumento define a função", "Parâmetro vem depois"],
    "resposta_correta": "Parâmetro é definido na função, argumento é passado ao chamar"
  },
  {
    "nivel": "Dificil",
    "idPergunta": "3011",
    "tipo": "Funções",
    "pergunta": "O que são funções recursivas?",
    "opcoes": ["Funções que chamam a si mesmas", "Funções que não retornam nada", "Funções que rodam em loop", "Funções automáticas"],
    "resposta_correta": "Funções que chamam a si mesmas"
  },
  {
    "nivel": "Dificil",
    "idPergunta": "3012",
    "tipo": "Funções",
    "pergunta": "Por que funções bem definidas melhoram a clareza do código?",
    "opcoes": ["Porque dividem o programa em partes menores e organizadas", "Porque reduzem loops", "Porque aumentam a velocidade", "Porque geram dados automáticos"],
    "resposta_correta": "Porque dividem o programa em partes menores e organizadas"
  },
  {
    "nivel": "Dificil",
    "idPergunta": "3013",
    "tipo": "Funções",
    "pergunta": "O que acontece se uma função não tiver um valor de retorno?",
    "opcoes": ["Ela retorna um valor nulo ou vazio", "Ela gera erro automático", "Ela entra em loop", "Nada é executado"],
    "resposta_correta": "Ela retorna um valor nulo ou vazio"
  },
  {
    "nivel": "Facil",
    "idPergunta": "1011",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "O que é uma variável em programação?",
    "opcoes": ["Um valor fixo", "Um espaço para armazenar dados", "Uma operação lógica", "Um comando de repetição"],
    "resposta_correta": "Um espaço para armazenar dados"
  },
  {
    "nivel": "Facil",
    "idPergunta": "1012",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "Qual tipo de dado representa um valor verdadeiro ou falso?",
    "opcoes": ["Texto", "Número", "Booleano", "Lista"],
    "resposta_correta": "Booleano"
  },
  {
    "nivel": "Facil",
    "idPergunta": "1013",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "Qual tipo de dado é mais adequado para armazenar nomes?",
    "opcoes": ["Número inteiro", "Texto", "Decimal", "Booleano"],
    "resposta_correta": "Texto"
  },
  {
    "nivel": "Facil",
    "idPergunta": "1014",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "O que acontece com o valor de uma variável quando ela é atualizada?",
    "opcoes": ["É apagado permanentemente", "É somado ao novo valor", "É substituído", "É duplicado"],
    "resposta_correta": "É substituído"
  },
  {
    "nivel": "Facil",
    "idPergunta": "1015",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "Qual tipo de dado é mais indicado para guardar um número de casas decimais?",
    "opcoes": ["Inteiro", "Decimal", "Texto", "Booleano"],
    "resposta_correta": "Decimal"
  },
  {
    "nivel": "Facil",
    "idPergunta": "1016",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "Uma variável pode armazenar:",
    "opcoes": ["Somente números", "Somente texto", "Diversos tipos de valores", "Somente listas"],
    "resposta_correta": "Diversos tipos de valores"
  },
  {
    "nivel": "Facil",
    "idPergunta": "1017",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "Qual é a melhor descrição para 'tipo de dado'?",
    "opcoes": ["A cor da variável", "O valor máximo", "A categoria do valor armazenado", "O endereço de memória"],
    "resposta_correta": "A categoria do valor armazenado"
  },
  {
    "nivel": "Facil",
    "idPergunta": "1018",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "Qual dessas opções NÃO é um tipo de dado comum?",
    "opcoes": ["Texto", "Número", "Árvore", "Booleano"],
    "resposta_correta": "Árvore"
  },
  {
    "nivel": "Facil",
    "idPergunta": "1019",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "Para que serve uma variável em um programa?",
    "opcoes": ["Executar comandos", "Armazenar valores temporários", "Criar loops", "Definir funções"],
    "resposta_correta": "Armazenar valores temporários"
  },
  {
    "nivel": "Facil",
    "idPergunta": "1020",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "Qual tipo de dado seria ideal para armazenar a idade de uma pessoa?",
    "opcoes": ["Texto", "Número inteiro", "Decimal", "Booleano"],
    "resposta_correta": "Número inteiro"
  },

  {
    "nivel": "Medio",
    "idPergunta": "2020",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "O que significa atribuição em programação?",
    "opcoes": ["Comparar valores", "Copiar uma variável", "Definir um valor para uma variável", "Imprimir um valor"],
    "resposta_correta": "Definir um valor para uma variável"
  },
  {
    "nivel": "Medio",
    "idPergunta": "2021",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "Por que os tipos de dados são importantes?",
    "opcoes": ["Ajudam na aparência do código", "Facilitam a execução correta de operações", "Deixam o programa mais bonito", "Não são importantes"],
    "resposta_correta": "Facilitam a execução correta de operações"
  },
  {
    "nivel": "Medio",
    "idPergunta": "2022",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "Qual seria o resultado ao somar um número e um texto, sem conversão?",
    "opcoes": ["Erro", "Soma normal", "Texto duplicado", "Nada"],
    "resposta_correta": "Erro"
  },
  {
    "nivel": "Medio",
    "idPergunta": "2023",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "Qual é a principal diferença entre número inteiro e decimal?",
    "opcoes": ["A forma como são digitados", "A quantidade de dígitos", "A presença de casas decimais", "O tamanho da variável"],
    "resposta_correta": "A presença de casas decimais"
  },
  {
    "nivel": "Medio",
    "idPergunta": "2024",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "Uma variável booleana pode armazenar:",
    "opcoes": ["Vários números", "Apenas True ou False", "Textos longos", "Listas"],
    "resposta_correta": "Apenas True ou False"
  },
  {
    "nivel": "Medio",
    "idPergunta": "2025",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "Quando uma variável é declarada, o que ocorre?",
    "opcoes": ["Ela é impressa", "Ela cria um espaço na memória", "Ela executa um comando", "Ela é apagada"],
    "resposta_correta": "Ela cria um espaço na memória"
  },
  {
    "nivel": "Medio",
    "idPergunta": "2026",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "Se uma variável armazenava um número e agora guarda um texto, o que aconteceu?",
    "opcoes": ["Erro de execução", "Mudança de tipo de dado", "Perda de memória", "Loop infinito"],
    "resposta_correta": "Mudança de tipo de dado"
  },
  {
    "nivel": "Medio",
    "idPergunta": "2027",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "O que é um identificador de variável?",
    "opcoes": ["O nome usado para se referir a ela", "O tipo de dado", "O valor armazenado", "O local de armazenamento"],
    "resposta_correta": "O nome usado para se referir a ela"
  },
  {
    "nivel": "Medio",
    "idPergunta": "2028",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "É possível armazenar listas ou coleções em variáveis?",
    "opcoes": ["Sim", "Não", "Apenas números", "Apenas texto"],
    "resposta_correta": "Sim"
  },
  {
    "nivel": "Medio",
    "idPergunta": "2029",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "O que significa inicializar uma variável?",
    "opcoes": ["Criar uma função", "Dar um valor inicial", "Apagar dados antigos", "Comparar valores"],
    "resposta_correta": "Dar um valor inicial"
  },

  {
    "nivel": "Dificil",
    "idPergunta": "3020",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "Qual é a importância de declarar corretamente o tipo de dado?",
    "opcoes": ["Evitar erros em operações", "Melhorar a estética", "Aumentar a velocidade de digitação", "Nenhuma"],
    "resposta_correta": "Evitar erros em operações"
  },
  {
    "nivel": "Dificil",
    "idPergunta": "3021",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "Por que é uma boa prática usar nomes significativos em variáveis?",
    "opcoes": ["Facilita a compreensão do código", "Melhora a velocidade do computador", "Garante compatibilidade", "Diminui bugs automaticamente"],
    "resposta_correta": "Facilita a compreensão do código"
  },
  {
    "nivel": "Dificil",
    "idPergunta": "3022",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "Qual o impacto de alterar um tipo de dado no meio de uma execução?",
    "opcoes": ["Nenhum", "Pode causar erros lógicos", "Melhora a performance", "Cria novas variáveis"],
    "resposta_correta": "Pode causar erros lógicos"
  },
  {
    "nivel": "Dificil",
    "idPergunta": "3023",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "Por que algumas linguagens exigem declarar o tipo da variável antecipadamente?",
    "opcoes": ["Para reservar memória corretamente", "Por estética", "Para tornar o código mais lento", "Porque não aceitam números"],
    "resposta_correta": "Para reservar memória corretamente"
  },
  {
    "nivel": "Dificil",
    "idPergunta": "3024",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "Em lógica de programação, o que diferencia um literal de uma variável?",
    "opcoes": ["Literal é fixo, variável pode mudar", "Literal é sempre número", "Variável é sempre texto", "Literal é um tipo especial de função"],
    "resposta_correta": "Literal é fixo, variável pode mudar"
  },
  {
    "nivel": "Dificil",
    "idPergunta": "3025",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "Por que conversões de tipo podem gerar erros?",
    "opcoes": ["Porque alteram os nomes das variáveis", "Porque nem todos os valores podem ser convertidos", "Porque apagam a variável", "Porque alteram o sistema operacional"],
    "resposta_correta": "Porque nem todos os valores podem ser convertidos"
  },
  {
    "nivel": "Dificil",
    "idPergunta": "3026",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "Em algumas linguagens, qual a vantagem de usar tipos estáticos?",
    "opcoes": ["Mais segurança e performance", "Maior consumo de memória", "Mais lentidão", "Código mais difícil"],
    "resposta_correta": "Mais segurança e performance"
  },
  {
    "nivel": "Dificil",
    "idPergunta": "3027",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "O que significa 'mutável' em relação a tipos de dados?",
    "opcoes": ["Pode mudar seu valor", "Não pode ser apagado", "É um número decimal", "É sempre verdadeiro"],
    "resposta_correta": "Pode mudar seu valor"
  },
  {
    "nivel": "Dificil",
    "idPergunta": "3028",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "Por que strings costumam ser imutáveis em muitas linguagens?",
    "opcoes": ["Facilita otimizações internas", "Economiza energia", "Garante conversão automática", "Evita variáveis globais"],
    "resposta_correta": "Facilita otimizações internas"
  },
  {
    "nivel": "Dificil",
    "idPergunta": "3029",
    "tipo": "Variáveis e Tipos de Dados",
    "pergunta": "O que pode acontecer se uma variável não for inicializada antes do uso?",
    "opcoes": ["Nada", "Erro ou comportamento inesperado", "Ela vira zero automaticamente", "Ela é criada como texto"],
    "resposta_correta": "Erro ou comportamento inesperado"
  }
]


# Função para inserir as perguntas no Firestore
def populate_questions():
    questions_ref = db.collection('perguntas')
    
    # Verifica se a coleção já tem perguntas para evitar duplicidade
    existing_questions_query = questions_ref.limit(1).get()
    # if len(existing_questions_query) > 0:
    #     print("A coleção 'perguntas' já está populada. Nenhum dado será adicionado.")
    #     return

    for question in questions_data:
        try:
            questions_ref.add(question)
            print(f"Pergunta adicionada: {question['pergunta']}")
        except Exception as e:
            print(f"Erro ao adicionar pergunta: {e}")
            
    print("População de perguntas concluída.")

if __name__ == "__main__":
    populate_questions()
