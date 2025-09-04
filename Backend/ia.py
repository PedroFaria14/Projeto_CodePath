import google.generativeai as genai
import time
#para rodar, basta fazer python3 ia.py no terminal e escolher a sua resposta
#CUDAR COM LIMITE DO USO DA KEY DO GEMINI
#USAR APENAS O NECESSARIO - QUALQUER COISA, CRIAR KEY DO GEMINI! 
GEMINI_API_KEY = "***REMOVED***"
genai.configure(api_key=GEMINI_API_KEY)
model = genai.GenerativeModel("gemini-2.5-flash")


#deverá pensar em um metodo para essas questões serem colocadas no flutter!
#QUESTÃO DE EXEMPLO - PODERÁ SER COLOCADA EM UM BANCO DE DADOS DEPOIS
questao = {
    "pergunta": "Qual dessas opções imprime os números de 1 a 5 em Python?",
    "alternativas": {
        "a": "for i in range(6): print(i)",
        "b": "for i in range(1, 6): print(i)",
        "c": "while i < 6: print(i)",
        "d": "for num in [1,2,3,4]: print(num)"
    },
    "correta": "b"
}

## LEMBRAR - DEFINIR A RESPOSTA COMO UMA VARIAVEL PARA QUE A IA POSSA LER E RESPONDER DE ACORDO
## DEFINIR UM LIMITE DE TENTATIVAS, PARA QUE NAO FIQUE EM LOOP INFINITO
def professor_papagaio():
    print("🦜 Olá, eu sou o Professor Papagaio dos laços!")
    time.sleep(1)
    print("\nAqui está sua questão:\n")
    print(questao["pergunta"])
    for k, v in questao["alternativas"].items():
        print(f" {k}) {v}")

    while True:
        resposta = input("\nDigite a letra da resposta (a, b, c ou d): ").strip().lower()

        #prompt dinâmico baseado na resposta do aluno 
        if resposta == questao["correta"]:
            prompt = f"""
            Você é o Professor Papagaio de programação. 
            Fale bem curto, direto, repetindo algumas palavras como um papagaio.
            O aluno acertou. 
            Parabenize rápido, diga por que a resposta está certa em poucas palavras, 
            dê um exemplo bobo curtinho e repita uma dica sobre laços em Python.
            """
        elif resposta in questao["alternativas"]:
            prompt = f"""
            Você é o Professor Papagaio de programação. 
            Fale bem curto, direto, repetindo algumas palavras como um papagaio.
            O aluno errou escolhendo a alternativa ({resposta}). 
            Explique o erro em poucas palavras, 
            dê um exemplo bobo curtinho 
            e repita uma dica simples sobre laços em Python.
            """
        else:
            print("🦜 Não entendi essa resposta. Tente com a, b, c ou d!")
            continue

        response = model.generate_content(prompt)
        print("\n🦜 Professor Papagaio responde:\n")
        print(response.text)
        
        if resposta == questao["correta"]:
            break

if __name__ == "__main__":
    professor_papagaio()
