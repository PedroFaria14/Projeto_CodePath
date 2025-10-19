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


# No arquivo do endpoint /profile (onde INITIAL_FASES é o mapa aninhado)

@router.get("/profile/{email}")
async def get_profile(email: str):
    try:
        users_ref = db.collection("usuarios")
        query = users_ref.where("email", "==", email).limit(1).get()

        if not query:
            raise HTTPException(status_code=404, detail="Usuário não encontrado")

        user_doc = query[0]
        user_data = user_doc.to_dict()

        # 💥 CORREÇÃO PRINCIPAL DE CONSISTÊNCIA
        fases = user_data.get("fases", {})
        
        # Se for o formato antigo (Lista), converte para o formato de Mapa
        if isinstance(fases, list):
            # Assumimos que esta lista antiga é o módulo "Variáveis" ou o módulo default
            fases = {"Variáveis": fases}
            user_doc.reference.update({"fases": fases})
            user_data["fases"] = fases

        # Garante que cada módulo PADRÃO tenha suas fases
        atualizou = False
        for modulo, fases_padrao in INITIAL_FASES.items():
            if modulo not in fases:
                fases[modulo] = fases_padrao
                atualizou = True

        if atualizou:
            user_doc.reference.update({"fases": fases})
            user_data["fases"] = fases

        # Retorna o user_data no corpo da resposta
        return {"success": True, "message": "Perfil encontrado.", "user": user_data}

    except Exception as e:
        print(f"Erro ao carregar perfil: {e}")
        # Retorna a resposta padronizada
        return ApiResponse(success=False, message="Erro ao carregar perfil.").model_dump()