# leasson.py
import random
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from main import db  

router = APIRouter()

class GetQuestions(BaseModel):
    user_level: str

@router.post("/get_questions")
async def get_questions(request_data: GetQuestions):
    if not db:
        raise HTTPException(status_code=500, detail="Erro de conexão com o banco de dados.")

    try:
        perguntas_ref = db.collection('perguntas')
        query = perguntas_ref.where('nivel', '==', request_data.user_level).get()
        
        if not query:
            raise HTTPException(status_code=404, detail="Nenhuma pergunta encontrada para este nível.")
            
        perguntas = [doc.to_dict() for doc in query]
        random.shuffle(perguntas)

        # Quantidade de perguntas por nível
        if request_data.user_level == "Dificil":
            num_questions = 10
        elif request_data.user_level == "Medio":
            num_questions = 12
        elif request_data.user_level == "Iniciante":
            num_questions = 15
        else:
            num_questions = 10

        perguntas_selecionadas = perguntas[:num_questions]
        
        return {"success": True, "questions": perguntas_selecionadas}
        
    except Exception as e:
        print(f"Erro ao buscar perguntas: {e}")
        raise HTTPException(status_code=500, detail="Ocorreu um erro no servidor.")
