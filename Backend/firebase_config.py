import firebase_admin
from firebase_admin import credentials, firestore
import os
from pathlib import Path

try:
    credential_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    local_path = Path(__file__).resolve().parent / "firebase-service-account.json"
    if not firebase_admin._apps:
        if credential_path:
            cred = credentials.Certificate(credential_path)
            firebase_admin.initialize_app(cred)
        elif local_path.is_file():
            firebase_admin.initialize_app(credentials.Certificate(str(local_path)))
        else:
            firebase_admin.initialize_app()  # Application Default Credentials
    db = firestore.client()
    print("Conexão com Firestore estabelecida com sucesso!")
except Exception as e:
    print(f"Erro ao inicializar Firebase: {e}")
    db = None
