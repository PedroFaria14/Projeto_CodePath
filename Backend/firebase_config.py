import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.Certificate("firebase-service-account.json")

try:
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("Conexão com Firestore estabelecida com sucesso!")
except Exception as e:
    print(f"Erro ao inicializar Firebase: {e}")
    db = None