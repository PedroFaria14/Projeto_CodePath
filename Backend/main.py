import firebase_admin
from firebase_admin import credentials, firestore
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
import datetime
import os
from google.cloud.firestore_v1.base_query import FieldFilter
from firebase_config import db

# --- 1. Importe o CORSMiddleware ---
from fastapi.middleware.cors import CORSMiddleware

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

# --- 2. Defina as origens (sites) que podem acessar sua API ---
origins = [
    "http://localhost:5173",  # Seu React em desenvolvimento
    "https://projeto-codepath.onrender.com", # O próprio backend
    # "https://SEU-FRONTEND-NO-VERCEL-OU-NETLIFY.com" # Adicione seu site de produção aqui
]

# --- 3. Adicione o Middleware de CORS ao 'app' ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,       # Lista de origens permitidas
    allow_credentials=True,
    allow_methods=["*"],         # Permite todos os métodos (GET, POST, etc)
    allow_headers=["*"],         # Permite todos os cabeçalhos
)


# (Seu código de inicialização do Firebase)
# # try:
# # ...
# # except ...


# --- Endpoints da API ---

@app.get("/")
def root():
    return {"status": "online", "message": "API CodePath funcionando com sucesso 🚀"}


app.include_router(register_router)
app.include_router(login_router)
app.include_router(update_nivel_router)
app.include_router(home_router)
app.include_router(leasson_router)
app.include_router(profile_router)
app.include_router(progress)
app.include_router(forgotPass.router, tags=["Password Reset"])