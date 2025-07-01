from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import os
from dotenv import load_dotenv

from .routers import routes, users # Importa as rotas
from .database import create_db_tables # Importa a função para criar tabelas

# Carrega variáveis de ambiente do ficheiro .env
load_dotenv()

app = FastAPI(
    title="CodePath API",
    description="API para o aplicativo interativo de ensino de programação CodePath.",
    version="0.1.0",
)

# Configurar CORS (Cross-Origin Resource Sharing)
origins = [
    os.getenv("FRONTEND_URL", "http://localhost:3000"), # URL do seu frontend Flutter Web
    "http://localhost",
    "http://localhost:8080", # Porta padrão do Flutter Web
    "http://127.0.0.1:8080",
    # Adicione outras URLs se o seu frontend estiver noutro local
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Inclui as rotas
app.include_router(routes.router, prefix="/api/routes", tags=["Autenticação"])
app.include_router(users.router, prefix="/api/users", tags=["Utilizadores"])

@app.on_event("startup")
async def startup_event():
    # Cria as tabelas da base de dados na inicialização
    # Isso criará o ficheiro 'codepath.db' na raiz da pasta 'backEnd'
    create_db_tables()
    print("API CodePath iniciada (usando SQLite).")

@app.get("/")
async def root():
    return {"message": "Bem-vindo à API CodePath!"}
