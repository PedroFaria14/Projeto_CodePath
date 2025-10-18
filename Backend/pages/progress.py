from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from firebase_config import db
from google.cloud.firestore_v1.base_query import FieldFilter

router = APIRouter()

class GameProgress(BaseModel):
    email: str
    tipo: str            # ✅ novo campo
    fases: list          # fases específicas do módulo

class ApiResponse(BaseModel):
    success: bool
    message: str

@router.post("/salvar_progresso", response_model=ApiResponse)
async def salvar_progresso(progresso: GameProgress):
    try:
        users_ref = db.collection("usuarios")
        query = users_ref.where("email", "==", progresso.email).limit(1).get()

        if not query:
            raise HTTPException(status_code=404, detail="Usuário não encontrado.")

        user_doc = query[0]
        user_data = user_doc.to_dict()

        # 🔹 Garante que 'fases' seja um dicionário
        fases = user_data.get("fases", {})
        if not isinstance(fases, dict):
            fases = {}

        # 🔹 Atualiza apenas o módulo correspondente
        fases[progresso.tipo] = progresso.fases

        user_doc.reference.update({"fases": fases})
        return {"success": True, "message": "Progresso salvo com sucesso!"}

    except Exception as e:
        print(f"Erro ao salvar progresso: {e}")
        raise HTTPException(status_code=500, detail="Erro ao salvar progresso.")