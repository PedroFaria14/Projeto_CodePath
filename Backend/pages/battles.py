from fastapi import APIRouter, HTTPException, Body
from pydantic import BaseModel
import datetime
from firebase_config import db
from google.cloud.firestore_v1 import Increment # Import para moedas
from google.cloud.firestore_v1.base_query import FieldFilter
import random
from typing import List, Dict, Any, Optional

router = APIRouter()

# --- Modelos Pydantic ---

class BatalhaInitRequest(BaseModel):
    """ O que o app envia para COMEÇAR a busca por uma batalha """
    email: str
    nivel: str # "iniciante", "intermediario", "avancado"

class BatalhaFinalizarRequest(BaseModel):
    """ O que o app envia DEPOIS de responder as 10 perguntas """
    email: str
    pontuacao: int # Número de acertos (Ex: 7)
    tempo_gasto_segundos: float # Ex: 120.5
    id_batalha_oponente: Optional[str] = None # Se ele estava desafiando um placar pendente
    pontuacao_oponente: Optional[int] = None # O placar que ele precisava bater

class BatalhaInitResponse(BaseModel):
    """ O que o backend retorna para o app """
    tipo_batalha: str # "NOVA_BATALHA" ou "DESAFIO_EXISTENTE"
    perguntas: List[Dict[str, Any]] # As 10 perguntas para o jogador
    id_batalha_oponente: Optional[str] = None # O ID do jogo pendente (se houver)
    pontuacao_oponente: Optional[int] = None


# --- Funções Auxiliares ---

async def get_perguntas_aleatorias(nivel: str, count: int = 10) -> List[Dict[str, Any]]:
    """ Busca 10 perguntas aleatórias do nível (com validação) """
    mapa_niveis = {
        "iniciante": "Facil",
        "intermediario": "Medio",
        "avancado": "Dificil"
    }
    nivel_convertido = mapa_niveis.get(nivel.lower(), "Facil")

    perguntas_ref = db.collection("perguntas").where(
        filter=FieldFilter("nivel", "==", nivel_convertido)
    ).stream()
    
    lista_perguntas = [doc.to_dict() for doc in perguntas_ref]
    
    if not lista_perguntas:
        raise HTTPException(status_code=404, detail=f"Nenhuma pergunta encontrada para o nível {nivel}")
    
    # Garante que não tentamos pegar mais perguntas do que existem
    num_a_pegar = min(count, len(lista_perguntas))
    if num_a_pegar < count:
        print(f"Aviso: Pedido {count} perguntas, mas só existem {num_a_pegar} no nível {nivel_convertido}")

    perguntas_escolhidas = random.sample(lista_perguntas, num_a_pegar)
    return perguntas_escolhidas

async def get_rank_score(email: str) -> int:
    """ Pega o 'rank_score' do usuário (já deve existir do login/register) """
    user_ref_query = db.collection("usuarios").where(filter=FieldFilter("email", "==", email)).limit(1).get()
    if not user_ref_query:
        return 1000 

    user_doc = user_ref_query[0]
    user_data = user_doc.to_dict()
    
    # O login/register já deve ter criado isso, mas garantimos.
    return user_data.get("rank_score", 1000)

async def atualizar_rank(email: str, vitoria: bool):
    """ Atualiza o rank do usuário (lógica simples de +10 / -10) """
    user_ref_query = db.collection("usuarios").where(filter=FieldFilter("email", "==", email)).limit(1).get()
    if not user_ref_query:
        return

    user_doc = user_ref_query[0]
    user_data = user_doc.to_dict()
    
    score_atual = user_data.get("rank_score", 1000)
    
    if vitoria:
        score_novo = score_atual + 10 # Ganha 10 pontos
    else:
        score_novo = max(score_atual - 10, 0) # Perde 10 (mínimo 0)
        
    user_doc.reference.update({"rank_score": score_novo})

async def atualizar_moedas(email: str, quantidade: int):
    """ Adiciona (ou remove) moedas de um usuário """
    user_ref_query = db.collection("usuarios").where(filter=FieldFilter("email", "==", email)).limit(1).get()
    if not user_ref_query:
        return # Usuário não encontrado

    user_doc = user_ref_query[0]
    
    # Usa Increment() para adicionar 'quantidade' ao valor existente de forma segura
    user_doc.reference.update({
        "moedas": Increment(quantidade)
    })


# --- Endpoints da Batalha Ranqueada ---

@router.post("/batalha/iniciar", response_model=BatalhaInitResponse, tags=["Batalha Ranqueada"])
async def iniciar_batalha(payload: BatalhaInitRequest):
    """
    PASSO 1: Jogador aperta "Batalha".
    O backend procura um oponente na fila OU cria um novo jogo.
    """
    try:
        rank_jogador_atual = await get_rank_score(payload.email)
        
        # Lógica de Matchmaking: Busca oponente com rank próximo (+/- 100)
        rank_min = rank_jogador_atual - 100
        rank_max = rank_jogador_atual + 100
        
        fila_ref_query = db.collection("batalha_queue").where(
            filter=FieldFilter("status", "==", "aguardando_oponente")
        ).where(
            filter=FieldFilter("rank_score_jogador", ">=", rank_min)
        ).where(
            filter=FieldFilter("rank_score_jogador", "<=", rank_max)
        ).limit(1)
        
        fila_docs = list(fila_ref_query.stream()) # Executa a query

        perguntas_para_jogador = await get_perguntas_aleatorias(payload.nivel, 10)

        # CASO 1: ENCONTROU UM OPONENTE NA FILA
        if fila_docs:
            oponente_doc = fila_docs[0]
            oponente_data = oponente_doc.to_dict()
            
            if oponente_data.get("email_jogador") == payload.email:
                 pass # É o seu próprio jogo pendente, ignora (Cai no CASO 2)
            else:
                # É um desafio válido!
                return BatalhaInitResponse(
                    tipo_batalha="DESAFIO_EXISTENTE",
                    perguntas=perguntas_para_jogador,
                    id_batalha_oponente=oponente_doc.id,
                    pontuacao_oponente=oponente_data.get("pontuacao")
                )

        # CASO 2: NÃO ACHOU OPONENTE
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
    """
    PASSO 2: Jogador terminou suas 10 perguntas.
    Ele envia o placar. O backend decide o resultado.
    """
    try:
        rank_jogador_atual = await get_rank_score(payload.email)
        
        # CASO 1: Ele estava jogando um "NOVA_BATALHA"
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

        # CASO 2: Ele estava jogando um "DESAFIO_EXISTENTE"
        pontuacao_oponente = payload.pontuacao_oponente 
        
        # VITORIA
        if payload.pontuacao > pontuacao_oponente:
            await atualizar_rank(payload.email, vitoria=True) 
            await atualizar_moedas(payload.email, 50) # Dá 50 moedas 🪙
            
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
        
        # DERROTA
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
        
        # EMPATE
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