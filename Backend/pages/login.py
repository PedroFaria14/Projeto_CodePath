from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import datetime
from firebase_config import db # Certifique-se que este import está correto

router = APIRouter()

# Modelo de dados para login
class UserLogin(BaseModel):
    email: str
    senha: str

# Modelo de resposta
class ApiResponse(BaseModel):
    success: bool
    message: str
    user: dict = None

# 💥 ATENÇÃO: Constante de fases padronizada para o MAPA ANINHADO
# Use o mesmo formato do seu endpoint de /profile
INITIAL_FASES = {
    "Laços de Repetição": [
        {"id": 1, "liberada": True, "atual": True},
        {"id": 2, "liberada": False, "atual": False},
        {"id": 3, "liberada": False, "atual": False}
    ],
    # Adicione aqui todos os seus módulos, ou apenas o módulo inicial
    # Se você quiser que o usuário comece sempre pelo mesmo, use só ele.
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

        # Verifica senha
        if user_data['senha'] != user.senha:
            raise HTTPException(status_code=401, detail="Email ou senha incorretos.")

        # --- Lógica do streak (mantida) ---
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
            
        
        # 💥 CORREÇÃO: Inicializa com o formato de MAPA se não existir
        if 'fases' not in user_data or not isinstance(user_data['fases'], dict):
            user_doc.reference.update({'fases': INITIAL_FASES})
            user_data['fases'] = INITIAL_FASES

        # Atualiza Firestore
        user_doc.reference.update({
            'streak': streak,
            'last_login': datetime.datetime.now()
        })

        user_data['streak'] = streak
        user_data.pop('senha', None)  

        return {"success": True, "message": "Login bem-sucedido!", "user": user_data}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ocorreu um erro ao verificar o login: {e}")