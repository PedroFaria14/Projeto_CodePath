import firebase_admin
from firebase_admin import credentials, firestore
from google.cloud.firestore_v1.base_query import FieldFilter
import os


cred = credentials.Certificate("../firebase-service-account.json")
firebase_admin.initialize_app(cred)
db = firestore.client()
questions_data = [
    
    {
        "nivel": "Dificil",
         "idPergunta": "3000",
        "tipo": "Laços de Repetição",
        "pergunta": "O que é um 'Decorator' em Python?",
        "opcoes": ["Uma função que envolve outra função", "Uma classe que decora a interface", "Uma ferramenta de depuração", "Um tipo de erro"],
        "resposta_correta": "Uma função que envolve outra função"
    },
    {
        "nivel": "Medio",
         "idPergunta": "2000",
        "tipo": "Condicionais",
        "pergunta": "O que faz a instrução 'else' em uma condicional?",
        "opcoes": ["Executa um bloco de código se a condição for falsa", "Inicia um loop", "Define uma variável", "Chama uma função"],
        "resposta_correta": "Executa um bloco de código se a condição for falsa"
    },
    {
        "nivel": "Facil",
         "idPergunta": "1000",
        "tipo": "Perguntas diversas",
        "pergunta": "Qual das seguintes opções é uma variável em python?",
        "opcoes": ["'if'", "10", "'hello world'", "def"],
        "resposta_correta": "10"
    },
    # Já foi adicionado no as de cima, use como exemplo para adicionar mais perguntas
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
