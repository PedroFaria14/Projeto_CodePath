from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field, field_validator
import datetime
from firebase_config import db
import bcrypt 
from google.cloud.firestore_v1 import DELETE_FIELD
from security import create_session, public_user, migrate_legacy_credential

router = APIRouter()

# (Modelos UserLogin e ApiResponse)
class UserLogin(BaseModel):
    email: str = Field(min_length=3, max_length=254)
    senha: str = Field(min_length=1, max_length=72)

    @field_validator("senha")
    @classmethod
    def password_byte_limit(cls, value):
        if len(value.encode("utf-8")) > 72:
            raise ValueError("Senha excede o limite suportado.")
        return value

class ApiResponse(BaseModel):
    success: bool
    message: str
    user: dict = None
    access_token: str
    token_type: str
    expires_in: int

# (Funções hash_password e verify_password)
def hash_password(password: str) -> str:
    """Gera o hash de uma senha."""
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(password.encode('utf-8'), salt)
    return hashed.decode('utf-8')

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verifica se a senha pura bate com o hash."""
    return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))

# 🚀 CONSTANTE PREENCHIDA (copiada do seu register.py)
INITIAL_FASES = {
    "Laços de Repetição": [
        {"id": 1, "liberada": True, "atual": True},
        {"id": 2, "liberada": False, "atual": False},
        {"id": 3, "liberada": False, "atual": False}
    ],
    "Condicionais": [
        {"id": 1, "liberada": True, "atual": True},
        {"id": 2, "liberada": False, "atual": False},
        {"id": 3, "liberada": False, "atual": False}
    ],
    "Variáveis": [
        {"id": 1, "liberada": True, "atual": True},
        {"id": 2, "liberada": False, "atual": False},
        {"id": 3, "liberada": False, "atual": False}
    ]
}

@router.post("/login", response_model=ApiResponse)
def login_user(user: UserLogin):
    if not db:
        raise HTTPException(status_code=500, detail="Erro de conexão com o banco de dados.")

    try:
        users_ref = db.collection('usuarios')
        query = users_ref.where('email', '==', user.email).limit(1).get()

        if len(query) == 0:
            raise HTTPException(status_code=401, detail="Email ou senha incorretos.")

        user_doc = query[0]
        user_data = user_doc.to_dict()

        # --- LÓGICA DE VERIFICAÇÃO DE SENHA CORRIGIDA ---
        
        login_sucesso = False # Flag para controlar o login
        
        if 'senha_hash' in user_data:
            # --- Caminho 1: Usuário novo (com hash) ---
            if verify_password(user.senha, user_data['senha_hash']):
                login_sucesso = True
            
        elif 'senha' in user_data:
            # --- Caminho 2: Usuário antigo (sem hash) ---
            if user_data['senha'] == user.senha:
                # Senha antiga (texto puro) bateu.
                # Atualiza o banco com o hash para o futuro.
                migrated_hash = hash_password(user.senha)
                migrate_legacy_credential(db, user_doc.reference, user.senha, migrated_hash)
                login_sucesso = True
                
                # (Opcional: Adicionar o hash ao user_data para a lógica de 'fases' funcionar)
                user_data['senha_hash'] = migrated_hash

        if not login_sucesso:
            # Se nenhum dos caminhos deu certo, o login falha.
            raise HTTPException(status_code=401, detail="Email ou senha incorretos.")

        # --- FIM DA LÓGICA DE SENHA ---
        
        # Se o código chegou até aqui, o login foi bem-sucedido.
        
        # --- Lógica do streak (mantida) ---
        today = datetime.date.today()
        # ... (resto da sua lógica de streak) ...
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
            
        
        # --- LÓGICA DE ATUALIZAÇÃO DE CAMPOS FALTANTES ---
        
        # Correção de 'fases' (mantida)
        if 'fases' not in user_data or not isinstance(user_data['fases'], dict):
            user_doc.reference.update({'fases': INITIAL_FASES})
            user_data['fases'] = INITIAL_FASES

        if 'rank_score' not in user_data:
            user_doc.reference.update({'rank_score': 1000})
            user_data['rank_score'] = 1000
            
        if 'moedas' not in user_data:
            user_doc.reference.update({'moedas': 0})
            user_data['moedas'] = 0
            
        # 🚀 ADICIONADO: Verifica e adiciona o placar semanal se não existir
        if 'weekly_score' not in user_data:
            user_doc.reference.update({'weekly_score': 1000})
            user_data['weekly_score'] = 1000
            
        # Atualiza Firestore
        user_doc.reference.update({
            'streak': streak,
            'last_login': datetime.datetime.now()
        })

        user_data['streak'] = streak
        # A sessão é vinculada à credencial que acabou de ser verificada.
        # Um reset concorrente revoga esta versão, mesmo se ocorrer antes da emissão.
        session = create_session(db, user_doc.reference.get(), verified_data=user_data)
        return {"success": True, "message": "Login bem-sucedido!",
                "user": public_user(user_data), **session}

    except HTTPException:
        raise
    except Exception as e:
        # Isso vai capturar o 'Invalid salt' se ele acontecer de novo
        # e informar o frontend
        raise HTTPException(status_code=500, detail="Não foi possível entrar. Tente novamente.")
