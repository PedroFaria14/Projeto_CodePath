from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import datetime
from firebase_config import db
from google.cloud.firestore_v1.base_query import FieldFilter

router = APIRouter()


class ApiResponse(BaseModel):
    success: bool
    message: str
    user: dict | None = None
    questions: list | None = None


@router.get("/profile/{user_email}", response_model=ApiResponse)
async def get_user_profile(user_email: str):
    if not db:
        raise HTTPException(status_code=500, detail="Erro de conexão com o banco de dados.")

    try:
        users_ref = db.collection('usuarios')
        query = users_ref.where(filter=FieldFilter('email', '==', user_email)).limit(1).get()

        if len(query) == 0:
            raise HTTPException(status_code=404, detail="Usuário não encontrado.")

        user_doc = query[0]
        user_data = user_doc.to_dict()
        user_data.pop('senha', None)  # remove a senha antes de enviar

        return ApiResponse(
            success=True,
            message="Perfil encontrado.",
            user=user_data
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ocorreu um erro ao buscar o perfil do usuário: {e}")
