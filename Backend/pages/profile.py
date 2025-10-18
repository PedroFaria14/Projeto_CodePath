from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from firebase_config import db

router = APIRouter()

# Modelo de resposta
class ApiResponse(BaseModel):
    success: bool
    message: str
    user: dict = None

router = APIRouter()

# 🔹 Estrutura inicial de fases por módulo
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


@router.get("/profile/{email}")
async def get_profile(email: str):
    try:
        users_ref = db.collection("usuarios")
        query = users_ref.where("email", "==", email).limit(1).get()

        if not query:
            raise HTTPException(status_code=404, detail="Usuário não encontrado")

        user_doc = query[0]
        user_data = user_doc.to_dict()

        # 🔹 Garante que cada módulo tenha suas fases
        fases = user_data.get("fases", {})
        if not isinstance(fases, dict):
            fases = {}

        atualizou = False
        for modulo, fases_padrao in INITIAL_FASES.items():
            if modulo not in fases:
                fases[modulo] = fases_padrao
                atualizou = True

        if atualizou:
            user_doc.reference.update({"fases": fases})
            user_data["fases"] = fases

        return {"user": user_data}

    except Exception as e:
        print(f"Erro ao carregar perfil: {e}")
        raise HTTPException(status_code=500, detail="Erro ao carregar perfil.")
    
@router.get("/sincronizar_trilhas")
async def sincronizar_trilhas():
    try:
        users_ref = db.collection("usuarios").stream()
        usuarios_atualizados = 0

        for user in users_ref:
            user_data = user.to_dict()
            fases = user_data.get("fases", {})

            if not isinstance(fases, dict):
                fases = {}

            atualizou = False

            # 🔹 Garante que todos os módulos existam
            for modulo, fases_padrao in INITIAL_FASES.items():
                if modulo not in fases or not isinstance(fases[modulo], list):
                    fases[modulo] = fases_padrao
                    atualizou = True

            # 🔹 Atualiza o documento apenas se necessário
            if atualizou:
                user.reference.update({"fases": fases})
                usuarios_atualizados += 1

        return {
            "success": True,
            "message": f"Trilhas sincronizadas com sucesso para {usuarios_atualizados} usuários."
        }

    except Exception as e:
        print(f"❌ Erro ao sincronizar trilhas: {e}")
        raise HTTPException(status_code=500, detail=str(e))