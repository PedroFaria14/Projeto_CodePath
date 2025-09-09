# leasson.py
import random
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from main import db  
from utils import get_num_questions_by_level  # importa a função auxiliar
from models import ApiResponse  # importa o response model (ou define aqui)
from data.lessons import licoes  # importa as perguntas

router = APIRouter()

# Modelo de entrada
class GetQuestionsByType(BaseModel):
    user_level: str
    question_type: str

@router.post("/get_questions_by_type", response_model=ApiResponse)
async def get_questions_by_type(request_data: GetQuestionsByType):
    if not db:
        raise HTTPException(status_code=500, detail="Erro de conexão com o banco de dados.")

    try:
        filtered_questions = [
            q for q in licoes.values()
            if q['nivel'].lower() == request_data.nivel.lower() and q['tipo'].lower() == request_data.question_type.lower()
        ]
        
        if not filtered_questions:
            raise HTTPException(
                status_code=404, 
                detail="Nenhuma pergunta encontrada para este nível e tipo."
            )
        
        random.shuffle(filtered_questions)

        # usa a função auxiliar para decidir a quantidade
        num_questions = get_num_questions_by_level(request_data.user_level)
        
        perguntas_selecionadas = filtered_questions[:num_questions]
        
        return {
            "success": True,
            "questions": perguntas_selecionadas,
            "total_questions": num_questions,
            "level": request_data.user_level
        }
        
    except Exception as e:
        print(f"Erro ao buscar perguntas: {e}")
        raise HTTPException(status_code=500, detail="Ocorreu um erro no servidor.")