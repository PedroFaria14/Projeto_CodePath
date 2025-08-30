

import firebase_admin
from firebase_admin import credentials, firestore
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
import datetime
import os
from google.cloud.firestore_v1.base_query import FieldFilter
import random


PORT = 8000

# Inicializa o FastAPI
app = FastAPI(title="CodePath API", description="API para o aplicativo CodePath.")

# Inicializa o Firebase
try:
    cred = credentials.Certificate("firebase-service-account.json")
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("Conexão com Firestore estabelecida com sucesso!")
except Exception as e:
    print(f"Erro ao inicializar Firebase: {e}")
    db = None


class UserRegister(BaseModel):
    nome: str = Field(..., min_length=2)
    email: str = Field(..., pattern=r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
    senha: str = Field(..., min_length=6)

class UserLogin(BaseModel):
    email: str
    senha: str

class UpdateUserLevel(BaseModel):
    email: str
    new_level: str

class GetQuestions(BaseModel):
    user_level: str

class ApiResponse(BaseModel):
    success: bool
    message: str
    user: dict = None

# --- Endpoints da API ---

@app.post("/register", response_model=ApiResponse)
async def register_user(user: UserRegister):
   
    if not db:
        raise HTTPException(status_code=500, detail="Erro de conexão com o banco de dados.")

    try:
        users_ref = db.collection('usuarios')
        # Verifica se o email já está em uso
        query = users_ref.where(filter=FieldFilter('email', '==', user.email)).limit(1).get()
        if len(query) > 0:
            raise HTTPException(status_code=400, detail="Este email já está cadastrado.")

        user_data = {
            "nome": user.nome,
            "email": user.email,
            "senha": user.senha,
            "streak": 1,
            "last_login": datetime.datetime.now(),
            "level": "iniciante" 
        }
        users_ref.add(user_data)
        
        return {"success": True, "message": "Usuário cadastrado com sucesso!"}
    
    except Exception as e:
        print(f"Erro ao registrar o usuário: {e}")
        raise HTTPException(status_code=500, detail="Ocorreu um erro no servidor.")

@app.post("/login", response_model=ApiResponse)
async def login_user(user: UserLogin):
    """
    Endpoint para login de usuário e atualização da contagem de ofensivas.
    """
    if not db:
        raise HTTPException(status_code=500, detail="Erro de conexão com o banco de dados.")

    try:
        users_ref = db.collection('usuarios')
        query = users_ref.where(filter=FieldFilter('email', '==', user.email)).where(filter=FieldFilter('senha', '==', user.senha)).limit(1).get()

        if len(query) > 0:
            user_doc = query[0]
            user_data = user_doc.to_dict()

            # --- Lógica da Ofensiva ---
            today = datetime.date.today()
            last_login = user_data.get('last_login')
            current_streak = user_data.get('streak', 0)
            
            if last_login:
                last_login_date = last_login.date()
                if last_login_date == today - datetime.timedelta(days=1):
                    current_streak += 1
                elif last_login_date != today:
                    current_streak = 1
            else:
                current_streak = 1

            # Atualiza os dados do usuário no Firestore
            user_doc.reference.update({
                'streak': current_streak,
                'last_login': datetime.datetime.now()
            })
            user_data['streak'] = current_streak

            # Remove a senha antes de retornar os dados
            user_data.pop('senha', None)
            
            return {"success": True, "message": "Login bem-sucedido!", "user": user_data}
        else:
            raise HTTPException(status_code=401, detail="Email ou senha incorretos.")

    except Exception as e:
        print(f"Erro ao verificar o login: {e}")
        raise HTTPException(status_code=500, detail="Ocorreu um erro no servidor.")

@app.post("/get_questions")
async def get_questions(request_data: GetQuestions):
   
    if not db:
        raise HTTPException(status_code=500, detail="Erro de conexão com o banco de dados.")

    try:
        perguntas_ref = db.collection('perguntas')
        query = perguntas_ref.where(filter=FieldFilter('nivel', '==', request_data.user_level)).get()
        
        if not query:
            raise HTTPException(status_code=404, detail="Nenhuma pergunta encontrada para este nível.")
            
        perguntas = [doc.to_dict() for doc in query]
        
        random.shuffle(perguntas)
        perguntas_selecionadas = perguntas[:10]
        
        return {"success": True, "questions": perguntas_selecionadas}
        
    except Exception as e:
        print(f"Erro ao buscar perguntas: {e}")
        raise HTTPException(status_code=500, detail="Ocorreu um erro no servidor.")

