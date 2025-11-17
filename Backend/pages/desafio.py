# Arquivo: pages/desafio.py (Com 3 Fases: Múltipla Escolha, Preencher Lacuna, Drag & Drop)

from fastapi import APIRouter, HTTPException, Body
from pydantic import BaseModel
import datetime
from firebase_config import db
from google.cloud.firestore_v1 import Increment, FieldFilter
import random
from typing import List, Dict, Any

router = APIRouter()

# --- Constantes do Desafio (ATUALIZADAS para 3, 4, 3) ---
MODULO_DA_SEMANA = "Condicionais" 

# NOVAS QUANTIDADES POR FASE
QTD_FASE1_MULTIPLA_ESCOLHA = 3   # Múltipla Escolha
QTD_FASE2_PREENCHER_LACUNA = 4   # Preencher Lacuna (Antigo Código Snippet)
QTD_FASE3_DRAG_DROP = 3          # Drag & Drop (NOVA FASE)

QTD_TOTAL = QTD_FASE1_MULTIPLA_ESCOLHA + QTD_FASE2_PREENCHER_LACUNA + QTD_FASE3_DRAG_DROP # Total de 10 perguntas

PONTUACAO_MINIMA = 6 # Mínimo de acertos para ganhar (de 10)
RECOMPENSA_MOEDAS = 150
RECOMPENSA_RANK_VITORIA = 30
RECOMPENSA_RANK_DERROTA = -5

COLECAO_FASE1 = "batalhas_perguntas"      # Múltipla Escolha (usa a coleção original)
COLECAO_FASE2 = "desafio_perguntas"       # Preencher Lacuna 
COLECAO_FASE3 = "desafio_montar_codigo"   # COLEÇÃO NOVA para Drag & Drop

class DesafioRequest(BaseModel):
    email: str

class DesafioFinalizarRequest(BaseModel):
    email: str
    pontuacao: int # Quantos acertou (de 10)

def get_semana_atual() -> int:
    return datetime.date.today().isocalendar()[1]

# --- Funções Auxiliares (mantidas e adaptadas) ---

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

async def get_perguntas_fase1(modulo: str, count: int) -> List[Dict[str, Any]]:
    """ Busca 'count' perguntas de Múltipla Escolha (Fácil ou Difícil) na COLECAO_FASE1 """
    try:
        # Busca perguntas que NÃO são do tipo codigo_snippet para a Fase 1
        query = db.collection(COLECAO_FASE1).where(
            filter=FieldFilter("modulo", "==", modulo)
        ).where(
            # Garante que não pegamos o código snippet antigo que seria da fase 2
            filter=FieldFilter("tipo", "!=", "codigo_snippet") 
        )
        
        perguntas_ref = query.stream()
        lista_perguntas = [doc.to_dict() for doc in perguntas_ref]
        
        if not lista_perguntas:
            raise Exception(f"Nenhuma pergunta encontrada para Múltipla Escolha em {COLECAO_FASE1}")
            
        num_a_pegar = min(count, len(lista_perguntas))
        if len(lista_perguntas) < count:
             print(f"AVISO: Pedido {count} perguntas Múltipla Escolha, mas só existem {len(lista_perguntas)}.")
            
        # Pega aleatoriamente a quantidade necessária (Misturando Fácil e Difícil)
        return random.sample(lista_perguntas, num_a_pegar)
        
    except Exception as e:
        print(f"❌ Erro ao buscar perguntas da Fase 1: {e}")
        return []

# --- Fim das Funções Auxiliares ---


@router.post("/desafio/iniciar", tags=["Desafio Semanal"])
async def iniciar_desafio(payload: DesafioRequest):
    """
    Verifica se o usuário já jogou e retorna as 10 perguntas em 3 Fases:
    (3 Múltipla Escolha, 4 Preencher Lacuna, 3 Drag & Drop).
    """
    try:
        semana_atual = get_semana_atual()
        modulo_da_semana = MODULO_DA_SEMANA 
        
        # 1. Verifica se o usuário já jogou (Lógica mantida)
        user_ref_query = db.collection("usuarios").where(filter=FieldFilter("email", "==", payload.email)).limit(1).get()
        if not user_ref_query:
            raise HTTPException(status_code=404, detail="Usuário não encontrado")
            
        user_doc = user_ref_query[0]
        user_data = user_doc.to_dict()
        
        semana_ultimo_desafio = user_data.get("semana_ultimo_desafio", 0)
        
        if semana_ultimo_desafio == semana_atual:
            raise HTTPException(status_code=403, detail=f"Você já completou o desafio desta semana! O módulo é: {modulo_da_semana}.")

        # --- 2. Busca as perguntas nas 3 FASES EM ORDEM ---
        
        # FASE 1: Múltipla Escolha (3 perguntas)
        perguntas_fase1 = await get_perguntas_fase1(modulo_da_semana, QTD_FASE1_MULTIPLA_ESCOLHA)
        
        # FASE 2: Preencher Lacuna (4 exercícios) - (Do tipo codigo_snippet)
        query_fase2 = db.collection(COLECAO_FASE2).where(
            filter=FieldFilter("modulo", "==", modulo_da_semana)
        ).where(
            filter=FieldFilter("tipo", "==", "codigo_snippet") # Garante que seja o formato de código
        )
        perguntas_fase2_ref = query_fase2.stream()
        lista_fase2 = [doc.to_dict() for doc in perguntas_fase2_ref]
        
        if len(lista_fase2) < QTD_FASE2_PREENCHER_LACUNA:
            raise HTTPException(status_code=404, detail="Erro: Perguntas de Preencher Lacuna insuficientes.")
            
        perguntas_fase2 = random.sample(lista_fase2, QTD_FASE2_PREENCHER_LACUNA)
        
        # FASE 3: Drag & Drop (3 exercícios) - (Nova Coleção)
        query_fase3 = db.collection(COLECAO_FASE3).where(
            filter=FieldFilter("modulo", "==", modulo_da_semana)
        )
        perguntas_fase3_ref = query_fase3.stream()
        lista_fase3 = [doc.to_dict() for doc in perguntas_fase3_ref]
        
        if len(lista_fase3) < QTD_FASE3_DRAG_DROP:
             raise HTTPException(status_code=404, detail="Erro: Perguntas de Montar Código (D&D) insuficientes.")
            
        perguntas_fase3 = random.sample(lista_fase3, QTD_FASE3_DRAG_DROP)
        
        # Validação Final (Adaptada)
        if (len(perguntas_fase1) < QTD_FASE1_MULTIPLA_ESCOLHA or 
            len(perguntas_fase2) < QTD_FASE2_PREENCHER_LACUNA or 
            len(perguntas_fase3) < QTD_FASE3_DRAG_DROP):
            raise HTTPException(status_code=404, detail="Erro: Perguntas insuficientes para o desafio desta semana em alguma das fases.")

        # 🚀 A MUDANÇA ESTÁ AQUI 🚀
        # 3. Juntamos as listas EM ORDEM, e adicionamos a marcação da Fase para o Frontend
        
        # O ideal é que o 'tipo_interacao' (ou 'fase') seja definido no Banco. 
        # Para que o Frontend saiba qual layout usar, vamos adicionar um campo 'fase' 
        # antes de juntar as listas.
        
        for p in perguntas_fase1: p['fase'] = 1
        for p in perguntas_fase2: p['fase'] = 2
        for p in perguntas_fase3: p['fase'] = 3
        
        todas_perguntas = perguntas_fase1 + perguntas_fase2 + perguntas_fase3
        
        return {"success": True, "perguntas": todas_perguntas, "modulo": modulo_da_semana}

    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(f"❌ Erro ao iniciar desafio: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/desafio/finalizar", tags=["Desafio Semanal"])
async def finalizar_desafio(payload: DesafioFinalizarRequest):
    """
    Recebe a pontuação (de 10), calcula recompensas e marca o usuário.
    """
    try:
        semana_atual = get_semana_atual()
        
        user_ref_query = db.collection("usuarios").where(filter=FieldFilter("email", "==", payload.email)).limit(1).get()
        if not user_ref_query:
            raise HTTPException(status_code=404, detail="Usuário não encontrado")
        
        user_doc = user_ref_query[0]

        # 2. Calcula recompensas (Lógica mantida, ajustada para QTD_TOTAL=10)
        moedas_ganhas = 0
        rank_change = 0
        vitoria = False
        
        if payload.pontuacao >= PONTUACAO_MINIMA: # (Ex: 6 de 10)
            moedas_ganhas = RECOMPENSA_MOEDAS
            rank_change = RECOMPENSA_RANK_VITORIA
            vitoria = True
            await atualizar_moedas(payload.email, moedas_ganhas)
        else:
            rank_change = RECOMPENSA_RANK_DERROTA
            
        await atualizar_weekly_score(payload.email, vitoria=vitoria) 

        # 3. Marca que o usuário completou o desafio (Lógica mantida)
        user_doc.reference.update({
            "semana_ultimo_desafio": semana_atual
        })

        return {
            "success": True,
            "message": f"Desafio concluído! Você acertou {payload.pontuacao} de {QTD_TOTAL}.",
            "status_final": "VITORIA" if vitoria else "DERROTA",
            "rank_change": rank_change,
            "moedas_ganhas": moedas_ganhas
        }

    except Exception as e:
        print(f"❌ Erro ao finalizar desafio: {e}")
        raise HTTPException(status_code=500, detail=str(e))