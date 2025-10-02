from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import datetime
from firebase_config import db
from google.cloud.firestore_v1.base_query import FieldFilter
from typing import Optional

router = APIRouter()


class UpdateUserLevel(BaseModel):
    email: str
    new_level: str

class ApiResponse(BaseModel):
    success: bool
    message: str
    


@router.post("/update_nivel", response_model=ApiResponse)
async def update_user_level(data: UpdateUserLevel):
   
    if not db:
        raise HTTPException(status_code=500, detail="Erro de conexão com o banco de dados. O serviço 'db' não está disponível.")

    try:
        users_ref = db.collection('usuarios')
        
      
        query = users_ref.where(filter=FieldFilter('email', '==', data.email)).limit(1).get()

        if len(query) > 0:
            user_doc = query[0]
           
            user_doc.reference.update({'nivel': data.new_level})
            
            return {"success": True, "message": f"Nível do usuário '{data.email}' atualizado para '{data.new_level}' com sucesso!"}
        else:
            raise HTTPException(status_code=404, detail="Usuário não encontrado.")

    except HTTPException:
        raise
    except Exception as e:
        print(f"Erro ao atualizar o nível do usuário: {e}")
        raise HTTPException(status_code=500, detail="Ocorreu um erro interno no servidor.")
