from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field, EmailStr
import datetime
import re
from firebase_config import db
from google.cloud.firestore_v1 import FieldFilter  # ✅ Import necessário

router = APIRouter()

class UserRegister(BaseModel):
    nome: str = Field(..., min_length=2)
    email: EmailStr
    senha: str = Field(..., min_length=6)
    data_nascimento: datetime.date = Field(...)  # formato YYYY-MM-DD
    telefone: str = Field(..., min_length=10, max_length=17)

class ApiResponse(BaseModel):
    success: bool
    message: str

INITIAL_FASES = [
    {"id": 1, "liberada": True, "atual": True},
    {"id": 2, "liberada": False, "atual": False},
    {"id": 3, "liberada": False, "atual": False},
    {"id": 4, "liberada": False, "atual": False},
    {"id": 5, "liberada": False, "atual": False},
]

@router.post("/register", response_model=ApiResponse)
async def register_user(user: UserRegister):
    telefone_limpo = re.sub(r'\D', '', user.telefone)

    if len(telefone_limpo) < 10 or len(telefone_limpo) > 13:
        raise HTTPException(
            status_code=400,
            detail="Telefone inválido. Deve conter entre 10 e 13 dígitos."
        )

    if not db:
        raise HTTPException(status_code=500, detail="Erro de conexão com o banco de dados.")

    try:
        users_ref = db.collection('usuarios')

        # ✅ Versão nova e correta do filtro
        query = users_ref.where(filter=FieldFilter('email', '==', user.email)).limit(1).stream()
        existing_users = list(query)

        if len(existing_users) > 0:
            raise HTTPException(status_code=400, detail="Este email já está cadastrado.")

        # ✅ Converter date → datetime
        data_nasc_datetime = datetime.datetime.combine(
            user.data_nascimento, datetime.datetime.min.time()
        )

        user_data = {
            "nome": user.nome,
            "data_nascimento": data_nasc_datetime,
            "telefone": telefone_limpo,
            "email": user.email,
            "senha": user.senha,
            "streak": 1,
            "last_login": datetime.datetime.utcnow(),
            "nivel": "iniciante",
            "fases": INITIAL_FASES,
        }

        users_ref.add(user_data)

        return {"success": True, "message": "Usuário cadastrado com sucesso!"}

    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(f"❌ Erro ao registrar o usuário: {e}")
        raise HTTPException(status_code=500, detail="Ocorreu um erro no servidor. Tente novamente mais tarde.")
