import firebase_admin
from firebase_admin import credentials, firestore
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
import datetime
import os
from google.cloud.firestore_v1.base_query import FieldFilter
from firebase_config import db
# Endpoints
from pages.register import router as register_router
from pages.login import router as login_router
from pages.profile import router as profile_router
from pages.home import router as home_router
from pages.update_nivel import router as update_nivel_router
from pages.leasson import router as leasson_router
from pages.progress import router as progress
from pages import forgotPass

  
PORT = 8000

# Inicializa o FastAPI
app = FastAPI(title="CodePath API", description="API para o aplicativo CodePath.")

# # Inicializa o Firebase
# try:
#     cred = credentials.Certificate("firebase-service-account.json")
#     firebase_admin.initialize_app(cred)
#     db = firestore.client()
#     print("Conexão com Firestore estabelecida com sucesso!")
# except Exception as e:
#     print(f"Erro ao inicializar Firebase: {e}")
#     db = None




# --- Endpoints da API ---

app.include_router(register_router)
app.include_router(login_router)
app.include_router(update_nivel_router)
app.include_router(home_router)
app.include_router(leasson_router)
app.include_router(profile_router)
app.include_router(progress)
app.include_router(forgotPass.router, tags=["Password Reset"])

