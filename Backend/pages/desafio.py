# Arquivo: pages/desafio.py (ATUALIZADO com 3 Estágios)

from fastapi import APIRouter, HTTPException, Body
from pydantic import BaseModel
import datetime
from firebase_config import db
from google.cloud.firestore_v1 import Increment, FieldFilter
import random
from typing import List, Dict, Any

router = APIRouter()

# --- Constantes do Desafio ---
MODULO_DA_SEMANA = "Condicionais" # Mude isso manualmente toda semana
QTD_FACIL = 3
QTD_DIFICIL = 5
QTD_CODIGO = 1
QTD_TOTAL = QTD_FACIL + QTD_DIFICIL + QTD_CODIGO # Total de 9 perguntas
PONTUACAO_MINIMA = 5 # Mínimo de acertos para ganhar (de 9)
RECOMPENSA_MOEDAS = 150
RECOMPENSA_RANK_VITORIA = 30
RECOMPENSA_RANK_DERROTA = -5

class DesafioRequest(BaseModel):
    email: str

class DesafioFinalizarRequest(BaseModel):
    email: str
    pontuacao: int # Quantos acertou (de 9)

def get_semana_atual() -> int:
    """ Retorna o número da semana no ano (1 a 53) """
    return datetime.date.today().isocalendar()[1]

# --- Funções Auxiliares (copiadas) ---

async def atualizar_moedas(email: str, quantidade: int):
    """ Atualiza as moedas do usuário """
    if quantidade <= 0:
        return
    user_ref_query = db.collection("usuarios").where(filter=FieldFilter("email", "==", email)).limit(1).get()
    if not user_ref_query:
        return
    user_doc = user_ref_query[0]
    user_doc.reference.update({ "moedas": Increment(quantidade) })

async def atualizar_weekly_score(email: str, vitoria: bool):
    """ Atualiza o 'weekly_score' (placar semanal) do usuário. """
    user_ref_query = db.collection("usuarios").where(filter=FieldFilter("email", "==", email)).limit(1).get()
    if not user_ref_query:
        return
        
    user_doc = user_ref_query[0]
    user_data = user_doc.to_dict()
    
    score_atual = user_data.get("weekly_score", 1000)
    if "weekly_score" not in user_data:
        user_doc.reference.update({"weekly_score": 1000})
    
    if vitoria:
        score_novo = score_atual + RECOMPENSA_RANK_VITORIA
    else:
        score_novo = max(score_atual + RECOMPENSA_RANK_DERROTA, 0)
        
    user_doc.reference.update({"weekly_score": score_novo})

async def get_perguntas_do_modulo(modulo: str, dificuldade: str, count: int) -> List[Dict[str, Any]]:
    """ Busca perguntas por Módulo e Dificuldade """
    try:
        perguntas_ref = db.collection("batalhas_perguntas").where(
            filter=FieldFilter("modulo", "==", modulo)
        ).where(
            filter=FieldFilter("nivel", "==", dificuldade)
        ).stream()
        
        lista_perguntas = [doc.to_dict() for doc in perguntas_ref]
        
        if not lista_perguntas:
             raise Exception(f"Nenhuma pergunta encontrada para {modulo} / {dificuldade}")
             
        num_a_pegar = min(count, len(lista_perguntas))
        if len(lista_perguntas) < count:
            print(f"AVISO: Pedido {count} perguntas '{dificuldade}', mas só existem {len(lista_perguntas)}.")
            
        return random.sample(lista_perguntas, num_a_pegar)
        
    except Exception as e:
        print(f"❌ Erro ao buscar perguntas do módulo: {e}")
        return []

# --- Fim das Funções Auxiliares ---


@router.post("/desafio/iniciar", tags=["Desafio Semanal"])
async def iniciar_desafio(payload: DesafioRequest):
    """
    Verifica se o usuário já jogou esta semana e, se não,
    retorna as 9 perguntas do desafio (3 Faceis, 5 Dificeis, 1 Código).
    """
    try:
        semana_atual = get_semana_atual()
        
        # 1. Verifica se o usuário já jogou
        user_ref_query = db.collection("usuarios").where(filter=FieldFilter("email", "==", payload.email)).limit(1).get()
        if not user_ref_query:
            raise HTTPException(status_code=404, detail="Usuário não encontrado")
            
        user_doc = user_ref_query[0]
        user_data = user_doc.to_dict()
        
        semana_ultimo_desafio = user_data.get("semana_ultimo_desafio", 0)
        
        if semana_ultimo_desafio == semana_atual:
            raise HTTPException(status_code=403, detail="Você já completou o desafio desta semana! Volte na próxima.")

        # 2. Busca as perguntas em 3 estágios
        
        # Estágio 1: 3 Fáceis
        perguntas_faceis = await get_perguntas_do_modulo(MODULO_DA_SEMANA, "Facil", QTD_FACIL)
        
        # Estágio 2: 5 Difíceis
        perguntas_dificeis = await get_perguntas_do_modulo(MODULO_DA_SEMANA, "Dificil", QTD_DIFICIL)
        
        # Estágio 3: 1 Desafio de Código
        perguntas_codigo_ref = db.collection("batalhas_perguntas").where(
            filter=FieldFilter("modulo", "==", MODULO_DA_SEMANA)
        ).where(
            filter=FieldFilter("tipo", "==", "codigo_snippet")
        ).stream()
        
        lista_codigo = [doc.to_dict() for doc in perguntas_codigo_ref]
        
        if not lista_codigo:
             raise HTTPException(status_code=404, detail="Erro: Nenhuma pergunta de 'Desafio de Código' encontrada para este módulo.")
        
        # Pega 1 aleatória
        perguntas_codigo = random.sample(lista_codigo, QTD_CODIGO)
        
        # Validação para garantir que temos todas as perguntas
        if len(perguntas_faceis) < QTD_FACIL or len(perguntas_dificeis) < QTD_DIFICIL or len(perguntas_codigo) < QTD_CODIGO:
             raise HTTPException(status_code=404, detail="Erro: Perguntas insuficientes para o desafio desta semana.")

        todas_perguntas = perguntas_faceis + perguntas_dificeis + perguntas_codigo
        random.shuffle(todas_perguntas) # Embaralha tudo

        return {"success": True, "perguntas": todas_perguntas}

    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(f"❌ Erro ao iniciar desafio: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/desafio/finalizar", tags=["Desafio Semanal"])
async def finalizar_desafio(payload: DesafioFinalizarRequest):
    """
    Recebe a pontuação (de 9), calcula recompensas e marca o usuário.
    """
    try:
        semana_atual = get_semana_atual()
        
        user_ref_query = db.collection("usuarios").where(filter=FieldFilter("email", "==", payload.email)).limit(1).get()
        if not user_ref_query:
            raise HTTPException(status_code=404, detail="Usuário não encontrado")
        
        user_doc = user_ref_query[0]

        # 2. Calcula recompensas
        moedas_ganhas = 0
        rank_change = 0
        vitoria = False
        
        if payload.pontuacao >= PONTUACAO_MINIMA: # 🚀 Usa a nova constante (5 de 9)
            moedas_ganhas = RECOMPENSA_MOEDAS
            rank_change = RECOMPENSA_RANK_VITORIA
            vitoria = True
            await atualizar_moedas(payload.email, moedas_ganhas)
        else:
            rank_change = RECOMPENSA_RANK_DERROTA
            
        await atualizar_weekly_score(payload.email, vitoria=vitoria) 

        # 3. Marca que o usuário completou o desafio
        user_doc.reference.update({
            "semana_ultimo_desafio": semana_atual
        })

        return {
            "success": True,
            "message": f"Desafio concluído! Você acertou {payload.pontuacao} de {QTD_TOTAL}.", # 🚀 Mensagem atualizada (de 9)
            "status_final": "VITORIA" if vitoria else "DERROTA",
            "rank_change": rank_change,
            "moedas_ganhas": moedas_ganhas
        }

    except Exception as e:
        print(f"❌ Erro ao finalizar desafio: {e}")
        raise HTTPException(status_code=500, detail=str(e))