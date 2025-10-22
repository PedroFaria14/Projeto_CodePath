import random
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from firebase_config import db
from scripts.gemini import gerar_explicacao
from google.cloud.firestore_v1.base_query import FieldFilter
import re 
import random 

router = APIRouter()

# --- Modelos de Dados ---
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
    explicacao: str | None = None
    
class ApiResponseQuestions(BaseModel):
    success: bool
    message: str
    perguntas: list[dict] | None = None
    
# ----------------------------------------------------

# 🚀 FUNÇÃO AUXILIAR CORRIGIDA (Resolve o NameError com escopo local)
async def get_persona_by_tipo(tipo_exercicio: str):
    # 1. Busca a persona pelo tipo
    docs = db.collection("personas").where(
        filter=FieldFilter("tipo", "==", tipo_exercicio)
    ).limit(1).get() 
    
    if docs:
        return docs[0].to_dict()

    # 2. 💥 CORREÇÃO DE ESCOPO: O FALLBACK_PERSONA agora é definido DENTRO da função
    FALLBACK_PERSONA = {
        "nome": "Professor Assistente",
        "acerto": "Muito bom! Sua resposta está correta. A explicação é:", 
        "erro": "Ops! Sua resposta está incorreta. Vamos revisar:", 
        "instrucoes": "Você é um assistente de programação simpático e direto. Use linguagem simples e explique o conceito."
    }
    return FALLBACK_PERSONA


# buscar pergunta aleatória por nível
@router.get("/pergunta/", response_model=ApiResponseQuestions)
async def get_pergunta(nivel: str, tipo: str, count: int = 3): # 💥 CORREÇÃO: Recebe 'count'
    try:
        mapa_niveis = {
            "iniciante": "Facil",
            "intermediario": "Medio",
            "avancado": "Dificil"
        }
        nivel = mapa_niveis.get(nivel.lower(), nivel)

        perguntas_ref = db.collection("perguntas").where(
            filter=FieldFilter("nivel", "==", nivel)
        ).where(
            filter=FieldFilter("tipo", "==", tipo)
        )

        docs = perguntas_ref.get()
        perguntas = [doc.to_dict() for doc in docs]

        if not perguntas:
            raise HTTPException(
                status_code=404,
                detail=f"Nenhuma pergunta encontrada para {nivel} e {tipo}"
            )
        
        # LÓGICA DE QUIZ: Embaralha e pega as 'count' primeiras perguntas
        random.shuffle(perguntas)
        
        num_perguntas = min(count, len(perguntas))
        perguntas_selecionadas = perguntas[:num_perguntas]
        
        if not perguntas_selecionadas:
             raise HTTPException(
                status_code=404,
                detail=f"Nenhuma pergunta encontrada para {nivel} e {tipo}"
            )
        
        return ApiResponseQuestions(
            success=True,
            message=f"{num_perguntas} perguntas encontradas",
            perguntas=perguntas_selecionadas
        )
    except HTTPException as e:
        raise e
    except Exception as e:
        print(f"❌ Erro ao buscar pergunta: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    
# validar resposta 
@router.post("/responder", response_model=ApiResponse)
async def responder(resposta: RespostaUsuario):
    try:
        # 1. Busca a pergunta
        docs = db.collection("perguntas").where(
            filter=FieldFilter("idPergunta", "==", resposta.idPergunta)
        ).limit(1).stream()
        doc = next(docs, None)

        if not doc:
            raise HTTPException(status_code=404, detail="Pergunta não encontrada")

        pergunta = doc.to_dict()
        correta = pergunta["resposta_correta"]

        # 2. Valida resposta
        acertou = resposta.resposta == correta
        
        explicacao_limpa = "" # Inicializa a variável

        # --- LÓGICA MODIFICADA ---
        if acertou:
            # 3.a. Se ACERTOU, não chama a IA.
            # Define uma mensagem de parabéns.
            mensagens_sucesso = [
                "Muito bem! Resposta correta.",
                "Parabéns, é isso mesmo!",
                "Exato! Continue assim.",
                "Você acertou! 🎉"
            ]
            # (Usando o 'random' que já está importado no seu arquivo)
            explicacao_limpa = random.choice(mensagens_sucesso)
        
        else:
            # 3.b. Se ERROU, busca a persona e chama a IA.
            
            # Busca persona (só precisa fazer isso se errar)
            tipo_exercicio = pergunta.get("tipo")
            prompts_persona = await get_persona_by_tipo(tipo_exercicio)
            
            explicacao_ia = ""
            try:
                # Chama a IA para explicar o erro
                explicacao_ia = gerar_explicacao(
                    pergunta["pergunta"], correta, resposta.resposta,
                    acertou=acertou, # 'acertou' será sempre False aqui
                    prompts_persona=prompts_persona
                )
            except Exception as gemini_e:
                print(f"⚠️ ERRO CHAVE NO GEMINI: {gemini_e}")
                # Fallback em caso de erro da IA
                explicacao_ia = "Ops, você errou. A resposta correta era: " + correta
            
            # 4. Remove a formatação Markdown (só da resposta da IA)
            explicacao_limpa = re.sub(r'\*\*|\*', '', explicacao_ia)
            explicacao_limpa = explicacao_limpa.replace('\n', ' ').strip()
        # --- FIM DA LÓGICA MODIFICADA ---

        # 5. Retorna a resposta
        return ApiResponse(
            success=acertou,
            message="Resposta correta 🎉" if acertou else "Resposta incorreta ❌",
            explicacao=explicacao_limpa # Este campo agora tem a msg estática ou a explicação da IA
        )

    except HTTPException as e:
        raise e
    except Exception as e:
        print(f"Erro inesperado no responder: {e}")
        raise HTTPException(status_code=500, detail=f"Erro interno no servidor: {e}")
    
@router.get("/modulos")
async def listar_modulos():
    try:
        perguntas_ref = db.collection("perguntas").stream()
        tipos = {doc.to_dict().get("tipo") for doc in perguntas_ref if doc.to_dict().get("tipo")}
        
        if not tipos:
            return {"success": False, "message": "Nenhum módulo encontrado.", "modulos": []}

        return {"success": True, "message": "Módulos encontrados.", "modulos": list(tipos)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
