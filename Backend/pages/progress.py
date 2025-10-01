from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from firebase_config import db
from google.cloud.firestore_v1.base_query import FieldFilter

router = APIRouter()

# Modelo de dados para o progresso do jogo
class GameProgress(BaseModel):
    email: str
    fases: list

class ApiResponse(BaseModel):
    success: bool
    message: str

@router.post("/salvar_progresso", response_model=ApiResponse)
async def salvar_progresso(progresso: GameProgress):
    if not db:
        raise HTTPException(status_code=500, detail="Erro de conexão com o banco de dados.")

    try:
        users_ref = db.collection('usuarios')
        query = users_ref.where(filter=FieldFilter('email', '==', progresso.email)).limit(1).get()

        if len(query) > 0:
            user_doc = query[0]
            user_doc.reference.update({'fases': progresso.fases})
            return {"success": True, "message": "Progresso salvo com sucesso!"}
        else:
            raise HTTPException(status_code=404, detail="Usuário não encontrado.")

    except Exception as e:
        print(f"Erro ao salvar progresso: {e}")
        raise HTTPException(status_code=500, detail="Ocorreu um erro no servidor.")