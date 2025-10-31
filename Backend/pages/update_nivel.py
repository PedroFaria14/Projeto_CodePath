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

class GlobalLevelSetRequest(BaseModel):
    email: str
    globalLevel: str # "iniciante", "intermediario", ou "avancado"
    
class ApiResponseProfileUpdate(BaseModel): # Você já deve ter este
    success: bool
    message: str
    user: dict | None = None


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


@router.post("/profile/set-global-level", response_model=ApiResponseProfileUpdate)
async def set_global_level(request: GlobalLevelSetRequest):
    """
    Define o nível de dificuldade global (nivel) de um usuário 
    após o teste de nivelamento.
    """
    try:
        user_ref = db.collection("usuarios").where(
            filter=FieldFilter("email", "==", request.email)
        ).limit(1)
        
        # 👇 CORREÇÃO APLICADA AQUI 👇
        # Usando a mesma lógica de lista do seu endpoint /update_nivel
        user_docs = user_ref.get() # .get() retorna uma LISTA

        if len(user_docs) > 0:
            user_doc = user_docs[0] # Pega o primeiro item da LISTA
        else:
            user_doc = None
        # 👆 FIM DA CORREÇÃO 👆

        if not user_doc:
            raise HTTPException(status_code=404, detail="Usuário não encontrado")

        user_id = user_doc.id
        user_data = user_doc.to_dict()

        # Atualiza o campo 'nivel' na raiz do documento do usuário
        db.collection("usuarios").document(user_id).update({
            "nivel": request.globalLevel
        })
        
        # Retorna o 'user' atualizado para o frontend
        user_data["nivel"] = request.globalLevel 
        return ApiResponseProfileUpdate(
            success=True, 
            message="Nível global atualizado com sucesso!",
            user=user_data
        )

    except Exception as e:
        print(f"❌ Erro ao definir nível global: {e}")
        raise HTTPException(status_code=500, detail=str(e))