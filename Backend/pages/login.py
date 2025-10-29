from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import datetime
from firebase_config import db
import bcrypt # 1. IMPORTADO O BCRYPT

router = APIRouter()

# Modelo de dados para login
class UserLogin(BaseModel):
    email: str
    senha: str # O usuário ainda envia a senha pura

# Modelo de resposta
class ApiResponse(BaseModel):
    success: bool
    message: str
    user: dict = None



def hash_password(password: str) -> str:
    """Gera o hash de uma senha."""
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(password.encode('utf-8'), salt)
    return hashed.decode('utf-8')

# 3. FUNÇÃO DE VERIFICAÇÃO (Você já tem)
def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verifica se a senha pura bate com o hash."""
    return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))

# (Sua constante INITIAL_FASES - mantenha como está)
INITIAL_FASES = {
    # ... (cole sua constante INITIAL_FASES aqui) ...
}

@router.post("/login", response_model=ApiResponse)
async def login_user(user: UserLogin):
    if not db:
        raise HTTPException(status_code=500, detail="Erro de conexão com o banco de dados.")

    try:
        users_ref = db.collection('usuarios')
        query = users_ref.where('email', '==', user.email).limit(1).get()

        if len(query) == 0:
            raise HTTPException(status_code=401, detail="Email ou senha incorretos.")

        user_doc = query[0]
        user_data = user_doc.to_dict()

        # 3. VERIFICAR SE O HASH EXISTE
        if 'senha_hash' not in user_data:
            # Fallback para usuários antigos sem hash (OPCIONAL, mas recomendado)
            if 'senha' in user_data and user_data['senha'] == user.senha:
                 # Se a senha antiga (sem hash) bater, crie um hash para ela agora
                user_doc.reference.update({'senha_hash': hash_password(user.senha)})
                # (Continue o login normalmente)
                pass
            else:
                raise HTTPException(status_code=401, detail="Email ou senha incorretos.")

        # 4. COMPARAR A SENHA USANDO BCRYPT
        if not verify_password(user.senha, user_data.get('senha_hash', '')):
            raise HTTPException(status_code=401, detail="Email ou senha incorretos.")
            
        # --- Lógica do streak (mantida) ---
        # ... (todo o seu código de streak continua aqui) ...
        today = datetime.date.today()
        last_login = user_data.get('last_login')
        streak = user_data.get('streak', 0)

        if last_login:
            last_login_date = last_login.date() if hasattr(last_login, "date") else last_login.ToDatetime().date()
            if last_login_date == today - datetime.timedelta(days=1):
                streak += 1
            elif last_login_date != today:
                streak = 1
        else:
            streak = 1
            
        
        # Correção de 'fases' (mantida)
        if 'fases' not in user_data or not isinstance(user_data['fases'], dict):
            user_doc.reference.update({'fases': INITIAL_FASES})
            user_data['fases'] = INITIAL_FASES

        # Atualiza Firestore
        user_doc.reference.update({
            'streak': streak,
            'last_login': datetime.datetime.now()
        })

        user_data['streak'] = streak
        user_data.pop('senha', None)      # Remove o campo 'senha' (se existir)
        user_data.pop('senha_hash', None) # Remove o hash da resposta

        return {"success": True, "message": "Login bem-sucedido!", "user": user_data}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ocorreu um erro ao verificar o login: {e}")