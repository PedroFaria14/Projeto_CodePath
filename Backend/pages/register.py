from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field, EmailStr
import datetime
import re
from firebase_config import db

router = APIRouter()

# Modelo de dados para registro
class UserRegister(BaseModel):
    nome: str = Field(..., min_length=2)
    email: EmailStr
    senha: str = Field(..., min_length=6)
    idade: int = Field(..., gt=0)
    telefone: str = Field(..., min_length=10, max_length=17)  # string para permitir +, espaços e parênteses

# Modelo de resposta
class ApiResponse(BaseModel):
    success: bool
    message: str

# Fases iniciais padrão
INITIAL_FASES = [
    {"id": 1, "liberada": True, "atual": True},
    {"id": 2, "liberada": False, "atual": False},
    {"id": 3, "liberada": False, "atual": False},
    {"id": 4, "liberada": False, "atual": False},
    {"id": 5, "liberada": False, "atual": False},
]

@router.post("/register", response_model=ApiResponse)
async def register_user(user: UserRegister):
    # 🧼 Limpar telefone (manter apenas dígitos)
    telefone_limpo = re.sub(r'\D', '', user.telefone)

    # 📞 Validar quantidade de dígitos
    if len(telefone_limpo) < 10 or len(telefone_limpo) > 13:
        raise HTTPException(
            status_code=400,
            detail="Telefone inválido. Deve conter entre 10 e 13 dígitos."
        )

    if not db:
        raise HTTPException(status_code=500, detail="Erro de conexão com o banco de dados.")

    try:
        users_ref = db.collection('usuarios')

        # Verifica se o email já existe
        query = users_ref.where('email', '==', user.email).limit(1).get()
        if len(query) > 0:
            raise HTTPException(status_code=400, detail="Este email já está cadastrado.")

        # 🔐 (Opcional) hash da senha
        # from bcrypt import hashpw, gensalt
        # hashed_senha = hashpw(user.senha.encode('utf-8'), gensalt()).decode('utf-8')

        user_data = {
            "nome": user.nome,
            "idade": user.idade,
            "telefone": telefone_limpo,  # salvo apenas números
            "email": user.email,
            "senha": user.senha,  # troque por hashed_senha se for usar bcrypt
            "streak": 1,
            "last_login": datetime.datetime.utcnow(),
            "nivel": "iniciante",
            "fases": INITIAL_FASES,
        }

        users_ref.add(user_data)

        return {"success": True, "message": "Usuário cadastrado com sucesso!"}

    except HTTPException:
        raise

    except Exception as e:
        print(f"❌ Erro ao registrar o usuário: {e}")
        raise HTTPException(status_code=500, detail="Ocorreu um erro no servidor. Tente novamente mais tarde.")
