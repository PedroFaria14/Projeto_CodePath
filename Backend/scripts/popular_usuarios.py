import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime
import os

# Certifique-se de que o caminho para o seu arquivo de credenciais está correto
# (Ex: '../firebase-service-account.json')
cred = credentials.Certificate("../firebase-service-account.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# Dados dos usuários a serem inseridos
users_data = [
    {
        "email": "cleiton@email.com",
        "fases": {
            "0": "1",
            "1": "1"
        },
        "idade": 19,
        "last_login": datetime.now(), # Use datetime para um timestamp real
        "nivel": "1",
        "nome": "cleiton",
        "senha": "1234567",
        "streak": 1
    },
    {
        "email": "ana@email.com",
        "fases": {
            "0": "1",
            "1": "0"
        },
        "idade": 25,
        "last_login": datetime.now(),
        "nivel": "2",
        "nome": "ana",
        "senha": "ana1234",
        "streak": 5
    },
    {
        "email": "joao@email.com",
        "fases": {
            "0": "0",
            "1": "0"
        },
        "idade": 30,
        "last_login": datetime.now(),
        "nivel": "3",
        "nome": "joao",
        "senha": "joao_pass",
        "streak": 0
    }
]

# Função para inserir os usuários no Firestore
def populate_users():
    users_ref = db.collection('usuarios')

    # Adicionando um pequeno "hack" para evitar duplicatas.
    # Em uma aplicação real, você teria um sistema de registro
    # que garantiria a unicidade do email.
    first_user_email = users_data[0]["email"]
    existing_user_query = users_ref.where("email", "==", first_user_email).limit(1).get()

    if len(existing_user_query) > 0:
        print("A coleção 'usuarios' já contém o primeiro usuário da lista. Nenhum dado será adicionado para evitar duplicidade.")
        return

    for user in users_data:
        try:
            # O Firestore pode gerar um ID de documento aleatório ou você pode definir um.
            # Aqui, estamos deixando o Firestore gerar o ID.
            users_ref.add(user)
            print(f"Usuário adicionado: {user['nome']} - {user['email']}")
        except Exception as e:
            print(f"Erro ao adicionar usuário: {e}")
            
    print("População de usuários concluída.")

if __name__ == "__main__":
    populate_users()