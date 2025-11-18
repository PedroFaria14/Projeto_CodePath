# Arquivo: pages/batalha.py
# (ATUALIZADO com weekly_score)

from fastapi import APIRouter, HTTPException, Body
from pydantic import BaseModel
import datetime
from firebase_config import db
from google.cloud.firestore_v1 import Increment
from google.cloud.firestore_v1.base_query import FieldFilter
import random
from typing import List, Dict, Any, Optional
from google.cloud import firestore

router = APIRouter()

# --- CONSTANTES DE RECOMPENSA ---
RANK_CHANGE_VITORIA = 10
RANK_CHANGE_DERROTA = -10
MOEDAS_VITORIA_ALEATORIA = 50
MOEDAS_DERROTA_EMPATE = 5

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

class MarcarLidoRequest(BaseModel):
    notificacao_id: str
    
class BatalhaNotificacao(BaseModel):
    id: str
    email: str
    titulo: str
    mensagem: str
    rank_change: int
    moedas_ganhas: int
    lido: bool
    timestamp: datetime.datetime


# --- (Funções Auxiliares - Sem alterações) ---
async def get_perguntas_aleatorias(nivel: str, count: int = 10) -> List[Dict[str, Any]]:
    mapa_niveis = {
        "iniciante": ["Facil"],
        "intermediario": ["Medio"],
        "avancado": ["Dificil", "Muito Dificil", "SuperDificil"]
    }
    niveis_para_buscar = mapa_niveis.get(nivel.lower(), ["Facil"])
    perguntas_ref = db.collection("batalhas_perguntas").where(
        filter=FieldFilter("nivel", "in", niveis_para_buscar)
    ).stream()
    lista_perguntas = [doc.to_dict() for doc in perguntas_ref]
    if not lista_perguntas:
        raise HTTPException(status_code=404, detail=f"Nenhuma pergunta de batalha encontrada para o nível {nivel}")
    num_a_pegar = min(count, len(lista_perguntas))
    if num_a_pegar < count:
        print(f"Aviso: Pedido {count} perguntas, mas só existem {num_a_pegar} nos níveis {niveis_para_buscar}")
    perguntas_escolhidas = random.sample(lista_perguntas, num_a_pegar)
    return perguntas_escolhidas

async def get_rank_score(email: str) -> int:
    user_ref_query = db.collection("usuarios").where(filter=FieldFilter("email", "==", email)).limit(1).get()
    if not user_ref_query:
        return 1000 
    user_doc = user_ref_query[0]
    user_data = user_doc.to_dict()
    # 🚀 Garante que o usuário tenha os campos de rank
    if "rank_score" not in user_data:
        user_doc.reference.update({"rank_score": 1000})
    if "weekly_score" not in user_data:
        user_doc.reference.update({"weekly_score": 1000})
        
    return user_data.get("rank_score", 1000)

async def atualizar_rank(email: str, vitoria: bool):
    user_ref_query = db.collection("usuarios").where(filter=FieldFilter("email", "==", email)).limit(1).get()
    if not user_ref_query:
        return
    user_doc = user_ref_query[0]
    user_data = user_doc.to_dict()
    score_atual = user_data.get("rank_score", 1000)
    if vitoria:
        score_novo = score_atual + RANK_CHANGE_VITORIA
    else:
        score_novo = max(score_atual + RANK_CHANGE_DERROTA, 0)
    user_doc.reference.update({"rank_score": score_novo})


# --- 👇 NOVA FUNÇÃO PARA O PLACAR SEMANAL 👇 ---
async def atualizar_weekly_score(email: str, vitoria: bool):
    """
    Atualiza o 'weekly_score' (placar semanal) do usuário.
    Usa as mesmas constantes de rank.
    """
    user_ref_query = db.collection("usuarios").where(filter=FieldFilter("email", "==", email)).limit(1).get()
    if not user_ref_query:
        return
        
    user_doc = user_ref_query[0]
    user_data = user_doc.to_dict()
    
    # Busca o 'weekly_score', se não existir, cria com 1000
    score_atual = user_data.get("weekly_score", 1000)
    if "weekly_score" not in user_data:
        user_doc.reference.update({"weekly_score": 1000})
    
    if vitoria:
        score_novo = score_atual + RANK_CHANGE_VITORIA
    else:
        score_novo = max(score_atual + RANK_CHANGE_DERROTA, 0) # Não deixa ficar negativo
        
    # Atualiza o campo 'weekly_score'
    user_doc.reference.update({"weekly_score": score_novo})
# --- 👆 FIM DA NOVA FUNÇÃO 👆 ---


async def atualizar_moedas(email: str, quantidade: int):
    if quantidade <= 0: # Não faz nada se for 0
        return
    user_ref_query = db.collection("usuarios").where(filter=FieldFilter("email", "==", email)).limit(1).get()
    if not user_ref_query:
        return
    user_doc = user_ref_query[0]
    user_doc.reference.update({
        "moedas": Increment(quantidade)
    })

# --- (Endpoint /batalha/iniciar - Sem alterações) ---
@router.post("/batalha/iniciar", response_model=BatalhaInitResponse, tags=["Batalha Ranqueada"])
async def iniciar_batalha(payload: BatalhaInitRequest):
    # Matchmaking continua usando o rank_score total
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


# --- 👇 ENDPOINT /batalha/finalizar ATUALIZADO 👇 ---
@router.post("/batalha/finalizar", tags=["Batalha Ranqueada"])
async def finalizar_batalha(payload: BatalhaFinalizarRequest):
    try:
        rank_jogador_atual = await get_rank_score(payload.email)
        
        # CASO 1: "NOVA_BATALHA" (Aguardando oponente)
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
                "message": "Placar salvo! Assim que um oponente jogar, avisaremos o resultado.",
                "rank_change": 0,
                "moedas_ganhas": 0 # Você pode mudar isso para MOEDAS_DERROTA_EMPATE se quiser
            }

        # CASO 2: "DESAFIO_EXISTENTE" (Resultado imediato)
        pontuacao_oponente = payload.pontuacao_oponente 
        
        oponente_ref = db.collection("batalha_queue").document(payload.id_batalha_oponente).get()
        email_oponente = oponente_ref.to_dict().get("email_jogador")
        
        # VITORIA
        if payload.pontuacao > pontuacao_oponente:
            await atualizar_rank(payload.email, vitoria=True) 
            await atualizar_moedas(payload.email, MOEDAS_VITORIA_ALEATORIA) 
            await atualizar_rank(email_oponente, vitoria=False)
            await atualizar_moedas(email_oponente, MOEDAS_DERROTA_EMPATE)
            
            # 🚀 ATUALIZA O PLACAR SEMANAL DE AMBOS
            await atualizar_weekly_score(payload.email, vitoria=True)
            await atualizar_weekly_score(email_oponente, vitoria=False)
            
            # CRIA NOTIFICAÇÃO PARA O OPONENTE OFFLINE
            db.collection("notificacoes").add({
                "email": email_oponente,
                "titulo": "Você Perdeu!",
                "mensagem": f"Seu oponente venceu a Batalha Aleatória ({pontuacao_oponente} a {payload.pontuacao}).",
                "rank_change": RANK_CHANGE_DERROTA,
                "moedas_ganhas": MOEDAS_DERROTA_EMPATE,
                "lido": False,
                "timestamp": datetime.datetime.utcnow()
            })
            
            db.collection("batalha_queue").document(payload.id_batalha_oponente).delete()
            
            return {
                "status_final": "VITORIA",
                "message": f"Você Venceu! ({payload.pontuacao} a {pontuacao_oponente})",
                "rank_change": RANK_CHANGE_VITORIA,
                "moedas_ganhas": MOEDAS_VITORIA_ALEATORIA
            }
        
        # DERROTA
        elif payload.pontuacao < pontuacao_oponente:
            await atualizar_rank(payload.email, vitoria=False) 
            await atualizar_moedas(payload.email, MOEDAS_DERROTA_EMPATE)
            await atualizar_rank(email_oponente, vitoria=True)
            await atualizar_moedas(email_oponente, MOEDAS_VITORIA_ALEATORIA)
            
            # 🚀 ATUALIZA O PLACAR SEMANAL DE AMBOS
            await atualizar_weekly_score(payload.email, vitoria=False)
            await atualizar_weekly_score(email_oponente, vitoria=True)
            
            # CRIA NOTIFICAÇÃO PARA O OPONENTE OFFLINE
            db.collection("notificacoes").add({
                "email": email_oponente,
                "titulo": "Você Venceu!",
                "mensagem": f"Você venceu a Batalha Aleatória ({pontuacao_oponente} a {payload.pontuacao})!",
                "rank_change": RANK_CHANGE_VITORIA,
                "moedas_ganhas": MOEDAS_VITORIA_ALEATORIA,
                "lido": False,
                "timestamp": datetime.datetime.utcnow()
            })
                
            db.collection("batalha_queue").document(payload.id_batalha_oponente).delete()
            return {
                "status_final": "DERROTA",
                "message": f"Você Perdeu. ({payload.pontuacao} a {pontuacao_oponente})",
                "rank_change": RANK_CHANGE_DERROTA,
                "moedas_ganhas": MOEDAS_DERROTA_EMPATE 
            }
        
        # EMPATE
        else:
            await atualizar_moedas(payload.email, MOEDAS_DERROTA_EMPATE)
            await atualizar_moedas(email_oponente, MOEDAS_DERROTA_EMPATE)
            
            # Empates não afetam o rank nem o placar semanal
            
            # CRIA NOTIFICAÇÃO PARA O OPONENTE OFFLINE
            db.collection("notificacoes").add({
                "email": email_oponente,
                "titulo": "Empate!",
                "mensagem": f"Você empatou a Batalha Aleatória ({pontuacao_oponente} a {payload.pontuacao}).",
                "rank_change": 0,
                "moedas_ganhas": MOEDAS_DERROTA_EMPATE,
                "lido": False,
                "timestamp": datetime.datetime.utcnow()
            })
            
            db.collection("batalha_queue").document(payload.id_batalha_oponente).delete()
            return {
                "status_final": "EMPATE",
                "message": f"Empate! ({payload.pontuacao} a {pontuacao_oponente})",
                "rank_change": 0,
                "moedas_ganhas": MOEDAS_DERROTA_EMPATE
            }
    except Exception as e:
        print(f"❌ Erro ao finalizar batalha: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# --- 👇 NOVOS ENDPOINTS DE NOTIFICAÇÃO 👇 ---

@router.get("/notificacoes/pendentes/{email}", response_model=List[BatalhaNotificacao], tags=["Notificações"])
async def get_notificacoes_pendentes(email: str):
    """
    Busca todas as notificações de resultado de batalha não lidas
    para um usuário.
    """
    try:
        notif_ref = db.collection("notificacoes").where(
            filter=FieldFilter("email", "==", email)
        ).where(
            filter=FieldFilter("lido", "==", False)
        ).order_by("timestamp", direction=firestore.Query.DESCENDING).limit(10)
        
        docs = notif_ref.stream()
        
        notificacoes = []
        for doc in docs:
            notif_data = doc.to_dict()
            notif_data["id"] = doc.id
            notificacoes.append(notif_data)
            
        return notificacoes
    except Exception as e:
        print(f"❌ Erro ao buscar notificações: {e}")
        return [] # Retorna lista vazia em caso de erro

@router.post("/notificacoes/marcar_como_lido", tags=["Notificações"])
async def marcar_notificacao_lida(payload: MarcarLidoRequest):
    """
    Marca uma notificação específica como 'lida' para não aparecer de novo.
    """
    try:
        notif_ref = db.collection("notificacoes").document(payload.notificacao_id)
        notif_ref.update({
            "lido": True
        })
        return {"success": True, "message": "Notificação marcada como lida."}
    except Exception as e:
        print(f"❌ Erro ao marcar notificação como lida: {e}")
        raise HTTPException(status_code=500, detail=str(e))