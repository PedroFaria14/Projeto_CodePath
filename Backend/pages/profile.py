from fastapi import APIRouter, HTTPException, Body
from pydantic import BaseModel
from firebase_config import db # Importe seu 'db' do Firebase
import datetime # Importado para o cálculo da idade

router = APIRouter()

# --- Modelos Pydantic ---

# Modelo de resposta para get_profile
class ApiResponse(BaseModel):
    success: bool
    message: str
    user: dict = None

# Modelo de body para update_profile
class UpdateProfilePayload(BaseModel):
    nome: str
    telefone: str

# --- Constantes ---

# Estrutura inicial de fases por módulo
INITIAL_FASES = {
    "Laços de Repetição": [
        {"id": 1, "liberada": True, "atual": True},
        {"id": 2, "liberada": False, "atual": False},
        {"id": 3, "liberada": False, "atual": False}
    ],
    "Funções": [
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
    ],
    "Perguntas diversas": [
        {"id": 1, "liberada": True, "atual": True},
        {"id": 2, "liberada": False, "atual": False}
    ]
}

# --- Endpoints de Perfil ---

@router.get("/profile/{email}")
async def get_profile(email: str):
    """
    Busca os dados de perfil do usuário, calcula a idade
    e garante a consistência dos dados de fases.
    """
    try:
        users_ref = db.collection("usuarios")
        query = users_ref.where("email", "==", email).limit(1).get()

        if not query:
            raise HTTPException(status_code=404, detail="Usuário não encontrado")

        user_doc = query[0]
        user_data = user_doc.to_dict()

        # Correção de consistência de 'fases'
        fases = user_data.get("fases", {})
        
        if isinstance(fases, list):
            fases = {"Variáveis": fases} # Converte formato antigo
            user_doc.reference.update({"fases": fases})
            user_data["fases"] = fases

        # Garante que módulos padrão existam
        atualizou = False
        for modulo, fases_padrao in INITIAL_FASES.items():
            if modulo not in fases:
                fases[modulo] = fases_padrao
                atualizou = True

        if atualizou:
            user_doc.reference.update({"fases": fases})
            user_data["fases"] = fases

        # Cálculo da idade
        data_nasc_str = user_data.get("data_nascimento")
        if data_nasc_str:
            try:
                dob = datetime.datetime.strptime(data_nasc_str, "%Y-%m-%d").date()
                today = datetime.date.today()
                idade = today.year - dob.year - ((today.month, today.day) < (dob.month, dob.day))
                user_data["idade"] = idade
            except ValueError:
                user_data["idade"] = None
        else:
            user_data["idade"] = None

        return {"success": True, "message": "Perfil encontrado.", "user": user_data}

    except Exception as e:
        print(f"Erro ao carregar perfil: {e}")
        return ApiResponse(success=False, message="Erro ao carregar perfil.").model_dump()


@router.put("/update_profile/{email}")
async def update_profile(email: str, payload: UpdateProfilePayload = Body(...)):
    """
    Atualiza o nome e o telefone de um usuário existente.
    """
    try:
        # 1. Encontre o usuário pelo email
        users_ref = db.collection("usuarios")
        query = users_ref.where("email", "==", email).limit(1).get()

        if not query:
            # 2. Se não encontrar, retorne erro 404
            raise HTTPException(status_code=404, detail="Usuário não encontrado")

        # 3. Se encontrar, pegue a referência do documento
        user_doc_ref = query[0].reference

        # 4. Atualize o documento com os novos dados do payload
        user_doc_ref.update({
            "nome": payload.nome,
            "telefone": payload.telefone
        })

        # 5. Retorne uma resposta de sucesso
        return {"success": True, "message": "Perfil atualizado com sucesso."}

    except Exception as e:
        print(f"Erro ao atualizar perfil: {e}")
        raise HTTPException(status_code=500, detail="Erro interno ao atualizar o perfil.")

