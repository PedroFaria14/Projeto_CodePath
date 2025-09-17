import random
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from firebase_config import db
from scripts.gemini import gerar_explicacao
router = APIRouter()

class Pergunta(BaseModel):
    idPergunta: str
    nivel: str
    tipo: str
    pergunta: str
    opcoes: list
    resposta_correta: str


class RespostaUsuario(BaseModel):
    idPergunta: str
    resposta: str

class ApiResponse(BaseModel):
    success: bool
    message: str
    pergunta: dict | None = None
    explicacao: str | None = None

#buscar pergunta aleatória por nível
@router.get("/pergunta/{nivel}", response_model=ApiResponse)
async def get_pergunta(nivel: str):
    try:
        perguntas_ref = db.collection("perguntas").where("nivel", "==", nivel)
        docs = perguntas_ref.stream()
        perguntas = [doc.to_dict() for doc in docs]

        if not perguntas:
            raise HTTPException(status_code=404, detail="Nenhuma pergunta encontrada para esse nível")

        pergunta = random.choice(perguntas)
        return ApiResponse(success=True, message="Pergunta encontrada", pergunta=pergunta)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# função auxiliar para buscar a persona pelo Modulo/Tipo do exercício
async def get_persona_by_tipo(tipo_exercicio: str):
    docs = db.collection("personas").where("tipo", "==", tipo_exercicio).limit(1).stream()
    
    for doc in docs:
        return doc.to_dict()
    
    # Se não encontrar uma persona com esse tipo, retorna a persona 'papagaio' como padrão
    doc_padrao = db.collection("personas").document("erro").get()
    return doc_padrao.to_dict()

#  validar resposta 
@router.post("/responder", response_model=ApiResponse)
async def responder(resposta: RespostaUsuario):
    try:
        # 1. Busca a pergunta no Firebase
        doc = db.collection("perguntas").document(resposta.idPergunta).get()
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Pergunta não encontrada")

        pergunta = doc.to_dict()
        correta = pergunta["resposta_correta"]
        
        # 2. Busca a persona com base no tipo da pergunta
        tipo_exercicio = pergunta.get("tipo", None)
        if not tipo_exercicio:
            prompts_persona = await get_persona_by_tipo("Laços de Repetição")
        else:
            prompts_persona = await get_persona_by_tipo(tipo_exercicio)

        # 3. Verifica se a resposta está correta e gera a explicação
        if resposta.resposta == correta:
            explicacao = gerar_explicacao(pergunta["pergunta"], correta, resposta.resposta, acertou=True, prompts_persona=prompts_persona)
            return ApiResponse(success=True, message="Resposta correta 🎉", explicacao=explicacao)
        else:
            explicacao = gerar_explicacao(pergunta["pergunta"], correta, resposta.resposta, acertou=False, prompts_persona=prompts_persona)
            return ApiResponse(success=False, message="Resposta incorreta ❌", explicacao=explicacao)

    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))