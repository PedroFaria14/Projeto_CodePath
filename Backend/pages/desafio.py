# Arquivo: pages/desafio.py (ATUALIZADO para nova coleção)

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
QTD_PERGUNTAS_DESAFIO = 5 # O desafio terá 5 perguntas
PONTUACAO_MINIMA = 3 # Mínimo de acertos para ganhar
RECOMPENSA_MOEDAS = 150
RECOMPENSA_RANK_VITORIA = 30
RECOMPENSA_RANK_DERROTA = -5
# 🚀 NOVA COLEÇÃO
COLECAO_DESAFIO = "desafio_perguntas" 

class DesafioRequest(BaseModel):
    email: str

class DesafioFinalizarRequest(BaseModel):
    email: str
    pontuacao: int # Quantos acertou (de 5)

def get_semana_atual() -> int:
    return datetime.date.today().isocalendar()[1]

# --- Funções Auxiliares (copiadas) ---

async def atualizar_moedas(email: str, quantidade: int):
    if quantidade <= 0:
        return
    user_ref_query = db.collection("usuarios").where(filter=FieldFilter("email", "==", email)).limit(1).get()
    if not user_ref_query:
        return
    user_doc = user_ref_query[0]
    user_doc.reference.update({ "moedas": Increment(quantidade) })

async def atualizar_weekly_score(email: str, vitoria: bool):
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

# --- Fim das Funções Auxiliares ---


@router.post("/desafio/iniciar", tags=["Desafio Semanal"])
async def iniciar_desafio(payload: DesafioRequest):
    """
    Verifica se o usuário já jogou e retorna 5 perguntas de código
    da coleção 'desafio_perguntas'.
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

        # 2. Busca as 5 perguntas de código da NOVA COLEÇÃO
        perguntas_ref = db.collection(COLECAO_DESAFIO).where(
            filter=FieldFilter("modulo", "==", MODULO_DA_SEMANA)
        ).stream() # Não filtra mais por 'tipo', já que todas são de desafio
        
        lista_perguntas = [doc.to_dict() for doc in perguntas_ref]
        
        if len(lista_perguntas) < QTD_PERGUNTAS_DESAFIO:
            raise HTTPException(status_code=404, detail=f"Erro: Perguntas de desafio insuficientes ({len(lista_perguntas)}/{QTD_PERGUNTAS_DESAFIO}) para o módulo '{MODULO_DA_SEMANA}'.")

        perguntas_escolhidas = random.sample(lista_perguntas, QTD_PERGUNTAS_DESAFIO)

        return {"success": True, "perguntas": perguntas_escolhidas}

    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(f"❌ Erro ao iniciar desafio: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/desafio/finalizar", tags=["Desafio Semanal"])
async def finalizar_desafio(payload: DesafioFinalizarRequest):
    """
    Recebe a pontuação (de 5), calcula recompensas e marca o usuário.
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
        
        if payload.pontuacao >= PONTUACAO_MINIMA:
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
            "message": f"Desafio concluído! Você acertou {payload.pontuacao} de {QTD_PERGUNTAS_DESAFIO}.",
            "status_final": "VITORIA" if vitoria else "DERROTA",
            "rank_change": rank_change,
            "moedas_ganhas": moedas_ganhas
        }

    except Exception as e:
        print(f"❌ Erro ao finalizar desafio: {e}")
        raise HTTPException(status_code=500, detail=str(e))