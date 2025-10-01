from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
import datetime
from fastapi import APIRouter
from firebase_config import db
router = APIRouter()

# Modelo de dados para registro
class UserRegister(BaseModel):
    nome: str = Field(..., min_length=2)
    email: str = Field(..., pattern=r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
    senha: str = Field(..., min_length=6)
    idade: int = Field(..., gt=0)

# Modelo de resposta
class ApiResponse(BaseModel):
    success: bool
    message: str

INITIAL_FASES = [
    {"id": 1, "liberada": True, "atual": True},
    {"id": 2, "liberada": False, "atual": False},
    {"id": 3, "liberada": False, "atual": False},
    {"id": 4, "liberada": False, "atual": False},
    {"id": 5, "liberada": False, "atual": False}
]

@router.post("/register", response_model=ApiResponse)
async def register_user(user: UserRegister):
    if not db:
        raise HTTPException(status_code=500, detail="Erro de conexão com o banco de dados.")

    try:
        users_ref = db.collection('usuarios')
        query = users_ref.where('email', '==', user.email).limit(1).get()
        if len(query) > 0:
            raise HTTPException(status_code=400, detail="Este email já está cadastrado.")

        user_data = {
            "nome": user.nome,
            "email": user.email,
            "senha": user.senha,
            "idade": user.idade,
            "streak": 1,
            "last_login": datetime.datetime.now(),
            "nivel": "iniciante",
            "fases": INITIAL_FASES
        }
        users_ref.add(user_data)
        return {"success": True, "message": "Usuário cadastrado com sucesso!"}
    except Exception as e:
        print(f"Erro ao registrar o usuário: {e}")
        raise HTTPException(status_code=500, detail="Ocorreu um erro no servidor.")
