# Arquivo: pages/batalha.py
# (ATUALIZADO para usar a nova coleção "batalhas_perguntas")

from fastapi import APIRouter, HTTPException, Body
from pydantic import BaseModel
import datetime
from firebase_config import db
from google.cloud.firestore_v1 import Increment
from google.cloud.firestore_v1.base_query import FieldFilter
import random
from typing import List, Dict, Any, Optional

router = APIRouter()

# --- (Modelos Pydantic - Sem alterações) ---
class BatalhaInitRequest(BaseModel):
    email: str
    nivel: str 

class BatalhaFinalizarRequest(BaseModel):
    email: str
    pontuacao: int 
    tempo_gasto_segundos: float 
    id_batalha_oponente: Optional[str] = None
    pontuacao_oponente: Optional[int] = None

class BatalhaInitResponse(BaseModel):
    tipo_batalha: str
    perguntas: List[Dict[str, Any]]
    id_batalha_oponente: Optional[str] = None
    pontuacao_oponente: Optional[int] = None


# --- 👇 FUNÇÃO AUXILIAR ATUALIZADA 👇 ---

async def get_perguntas_aleatorias(nivel: str, count: int = 10) -> List[Dict[str, Any]]:
    """ 
    Busca 10 perguntas aleatórias da nova coleção 'batalhas_perguntas'.
    """
    
    # Mapeia os níveis do app para os níveis do banco
    # "avancado" agora puxa de 3 categorias!
    mapa_niveis = {
        "iniciante": ["Facil"],
        "intermediario": ["Medio"],
        "avancado": ["Dificil", "Muito Dificil", "SuperDificil"]
    }
    
    # Se o nível enviado pelo app não estiver no mapa, usa "Facil"
    niveis_para_buscar = mapa_niveis.get(nivel.lower(), ["Facil"])

    # 1. ATUALIZADO: Busca na nova coleção "batalhas_perguntas"
    # 2. ATUALIZADO: Usa o operador "in" para buscar de múltiplos níveis
    perguntas_ref = db.collection("batalhas_perguntas").where(
        filter=FieldFilter("nivel", "in", niveis_para_buscar)
    ).stream()
    
    lista_perguntas = [doc.to_dict() for doc in perguntas_ref]
    
    if not lista_perguntas:
        # Se não achar NENHUMA pergunta (nem Facil, Medio, etc.)
        raise HTTPException(status_code=404, detail=f"Nenhuma pergunta de batalha encontrada para o nível {nivel}")
    
    num_a_pegar = min(count, len(lista_perguntas))
    if num_a_pegar < count:
        print(f"Aviso: Pedido {count} perguntas, mas só existem {num_a_pegar} nos níveis {niveis_para_buscar}")

    perguntas_escolhidas = random.sample(lista_perguntas, num_a_pegar)
    return perguntas_escolhidas

# --- (Funções get_rank_score, atualizar_rank, atualizar_moedas - Sem alterações) ---
async def get_rank_score(email: str) -> int:
    # ... (código idêntico)
    user_ref_query = db.collection("usuarios").where(filter=FieldFilter("email", "==", email)).limit(1).get()
    if not user_ref_query:
        return 1000 
    user_doc = user_ref_query[0]
    user_data = user_doc.to_dict()
    if "rank_score" not in user_data:
        user_doc.reference.update({"rank_score": 1000})
        return 1000
    return user_data.get("rank_score", 1000)

async def atualizar_rank(email: str, vitoria: bool):
    # ... (código idêntico)
    user_ref_query = db.collection("usuarios").where(filter=FieldFilter("email", "==", email)).limit(1).get()
    if not user_ref_query:
        return
    user_doc = user_ref_query[0]
    user_data = user_doc.to_dict()
    score_atual = user_data.get("rank_score", 1000)
    if vitoria:
        score_novo = score_atual + 10
    else:
        score_novo = max(score_atual - 10, 0)
    user_doc.reference.update({"rank_score": score_novo})

async def atualizar_moedas(email: str, quantidade: int):
    # ... (código idêntico)
    user_ref_query = db.collection("usuarios").where(filter=FieldFilter("email", "==", email)).limit(1).get()
    if not user_ref_query:
        return
    user_doc = user_ref_query[0]
    user_doc.reference.update({
        "moedas": Increment(quantidade)
    })

# --- (Endpoints /batalha/iniciar e /batalha/finalizar - Sem alterações) ---
@router.post("/batalha/iniciar", response_model=BatalhaInitResponse, tags=["Batalha Ranqueada"])
async def iniciar_batalha(payload: BatalhaInitRequest):
    # ... (código idêntico)
    try:
        rank_jogador_atual = await get_rank_score(payload.email)
        rank_min = rank_jogador_atual - 100
        rank_max = rank_jogador_atual + 100
        fila_ref_query = db.collection("batalha_queue").where(
            filter=FieldFilter("status", "==", "aguardando_oponente")
        ).where(
            filter=FieldFilter("rank_score_jogador", ">=", rank_min)
        ).where(
            filter=FieldFilter("rank_score_jogador", "<=", rank_max)
        ).limit(1)
        fila_docs = list(fila_ref_query.stream())
        
        # Esta função agora usa a nova coleção
        perguntas_para_jogador = await get_perguntas_aleatorias(payload.nivel, 10)

        if fila_docs:
            oponente_doc = fila_docs[0]
            oponente_data = oponente_doc.to_dict()
            if oponente_data.get("email_jogador") == payload.email:
                 pass 
            else:
                return BatalhaInitResponse(
                    tipo_batalha="DESAFIO_EXISTENTE",
                    perguntas=perguntas_para_jogador,
                    id_batalha_oponente=oponente_doc.id,
                    pontuacao_oponente=oponente_data.get("pontuacao")
                )
        return BatalhaInitResponse(
            tipo_batalha="NOVA_BATALHA",
            perguntas=perguntas_para_jogador,
            id_batalha_oponente=None,
            pontuacao_oponente=None
        )
    except Exception as e:
        print(f"❌ Erro ao iniciar batalha: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/batalha/finalizar", tags=["Batalha Ranqueada"])
async def finalizar_batalha(payload: BatalhaFinalizarRequest):
    # ... (código idêntico, incluindo a chamada para atualizar_moedas)
    try:
        rank_jogador_atual = await get_rank_score(payload.email)
        
        if payload.id_batalha_oponente is None:
            db.collection("batalha_queue").add({
                "email_jogador": payload.email,
                "rank_score_jogador": rank_jogador_atual,
                "pontuacao": payload.pontuacao,
                "tempo_gasto_segundos": payload.tempo_gasto_segundos,
                "timestamp_criacao": datetime.datetime.utcnow(),
                "status": "aguardando_oponente"
            })
            return {
                "status_final": "AGUARDANDO_OPONENTE",
                "message": "Placar salvo! Assim que um oponente jogar, avisaremos o resultado."
            }

        pontuacao_oponente = payload.pontuacao_oponente 
        
        if payload.pontuacao > pontuacao_oponente:
            await atualizar_rank(payload.email, vitoria=True) 
            await atualizar_moedas(payload.email, 50) # 🪙
            
            oponente_ref = db.collection("batalha_queue").document(payload.id_batalha_oponente).get()
            if oponente_ref.exists:
                email_oponente = oponente_ref.to_dict().get("email_jogador")
                await atualizar_rank(email_oponente, vitoria=False)
            db.collection("batalha_queue").document(payload.id_batalha_oponente).delete()
            
            return {
                "status_final": "VITORIA",
                "message": f"Você Venceu! ({payload.pontuacao} a {pontuacao_oponente})",
                "placar_seu": payload.pontuacao,
                "placar_oponente": pontuacao_oponente
            }
        elif payload.pontuacao < pontuacao_oponente:
            await atualizar_rank(payload.email, vitoria=False) 
            oponente_ref = db.collection("batalha_queue").document(payload.id_batalha_oponente).get()
            if oponente_ref.exists:
                email_oponente = oponente_ref.to_dict().get("email_jogador")
                await atualizar_rank(email_oponente, vitoria=True)
            db.collection("batalha_queue").document(payload.id_batalha_oponente).delete()
            return {
                "status_final": "DERROTA",
                "message": f"Você Perdeu. ({payload.pontuacao} a {pontuacao_oponente})",
                "placar_seu": payload.pontuacao,
                "placar_oponente": pontuacao_oponente
            }
        else:
            db.collection("batalha_queue").document(payload.id_batalha_oponente).delete()
            return {
                "status_final": "EMPATE",
                "message": f"Empate! ({payload.pontuacao} a {pontuacao_oponente})",
                "placar_seu": payload.pontuacao,
                "placar_oponente": pontuacao_oponente
            }
    except Exception as e:
        print(f"❌ Erro ao finalizar batalha: {e}")
        raise HTTPException(status_code=500, detail=str(e))