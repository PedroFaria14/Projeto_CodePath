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
    if not db:
        raise HTTPException(status_code=500, detail="Erro de conexão com o banco de dados.")

    try:
        users_ref = db.collection("usuarios")
        query = users_ref.where(filter=FieldFilter('email', '==', progresso.email)).limit(1).get()

        if len(query) == 0:
            raise HTTPException(status_code=404, detail="Usuário não encontrado.")

        user_doc = query[0]
        user_data = user_doc.to_dict()

        # 🔹 Corrige compatibilidade entre listas antigas e novo formato em dicionário
        fases_existentes = user_data.get("fases", {})

        # Se fases for uma lista, converte para um dicionário único (sem módulo definido)
        if isinstance(fases_existentes, list):
            fases_existentes = {"Geral": fases_existentes}

        # 🔹 Atualiza apenas o módulo atual
        tipo_modulo = getattr(progresso, "tipo", None)
        if not tipo_modulo:
            raise HTTPException(status_code=400, detail="Campo 'tipo' ausente na requisição.")

        fases_existentes[tipo_modulo] = progresso.fases

        # 🔹 Atualiza o Firestore
        user_doc.reference.update({'fases': fases_existentes})

        print(f"✅ Progresso salvo para {progresso.email} no módulo {tipo_modulo}")

        return {"success": True, "message": "Progresso salvo com sucesso!"}

    except HTTPException as e:
        raise e
    except Exception as e:
        print(f"Erro ao salvar progresso: {e}")
        raise HTTPException(status_code=500, detail=str(e))