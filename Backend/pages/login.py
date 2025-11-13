from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import datetime
from firebase_config import db
import bcrypt 

router = APIRouter()

# (Modelos UserLogin e ApiResponse)
class UserLogin(BaseModel):
    email: str
    senha: str

class ApiResponse(BaseModel):
    success: bool
    message: str
    user: dict = None

# (Funções hash_password e verify_password)
def hash_password(password: str) -> str:
    """Gera o hash de uma senha."""
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(password.encode('utf-8'), salt)
    return hashed.decode('utf-8')

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verifica se a senha pura bate com o hash."""
    return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))

# (Sua constante INITIAL_FASES)
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
                user_doc.reference.update({'senha_hash': hash_password(user.senha)})
                login_sucesso = True
                
                # (Opcional: Adicionar o hash ao user_data para a lógica de 'fases' funcionar)
                user_data['senha_hash'] = hash_password(user.senha)

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
            
        # Atualiza Firestore
        user_doc.reference.update({
            'streak': streak,
            'last_login': datetime.datetime.now()
        })

        user_data['streak'] = streak
        user_data.pop('senha', None)
        user_data.pop('senha_hash', None)

        return {"success": True, "message": "Login bem-sucedido!", "user": user_data}

    except Exception as e:
        # Isso vai capturar o 'Invalid salt' se ele acontecer de novo
        # e informar o frontend
        raise HTTPException(status_code=500, detail=f"Ocorreu um erro ao verificar o login: {e}")