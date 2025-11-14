# Arquivo: pages/convite.py
# (ATUALIZADO para usar a nova coleção "batalhas_perguntas")

from fastapi import APIRouter, HTTPException, Body
from pydantic import BaseModel
import datetime
from firebase_config import db
from google.cloud.firestore_v1 import Increment
from google.cloud.firestore_v1.base_query import FieldFilter
import random
from typing import List, Dict, Any, Optional

# Tenta importar a função ATUALIZADA de 'batalha.py'
# Se falhar, define uma cópia local ATUALIZADA da função.
try:
    from pages.batalha import get_perguntas_aleatorias
except ImportError:
    print("WARNING: Falha ao importar 'get_perguntas_aleatorias' de batalha.py. Usando fallback.")
    
    # 👇 FUNÇÃO AUXILIAR ATUALIZADA 👇
    async def get_perguntas_aleatorias(nivel: str, count: int = 10) -> List[Dict[str, Any]]:
        mapa_niveis = {
            "iniciante": ["Facil"],
            "intermediario": ["Medio"],
            "avancado": ["Dificil", "Muito Dificil", "SuperDificil"]
        }
        niveis_para_buscar = mapa_niveis.get(nivel.lower(), ["Facil"])

        perguntas_ref = db.collection("batalhas_perguntas").where( # <-- Coleção Nova
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


router = APIRouter()

# --- (Modelos Pydantic - Sem alterações) ---
class ConviteCreateRequest(BaseModel):
    email_desafiante: str
    email_desafiado: str
    nivel: str

class ConviteFinalizarRequest(BaseModel):
    id_convite: str
    email_jogador: str
    pontuacao: int
    tempo_gasto_segundos: float

class ConviteIniciarrResponse(BaseModel):
    perguntas: List[Dict[str, Any]]
    id_convite: str

# --- (Função atualizar_moedas - Sem alterações) ---
async def atualizar_moedas(email: str, quantidade: int):
    # ... (código idêntico)
    user_ref_query = db.collection("usuarios").where(filter=FieldFilter("email", "==", email)).limit(1).get()
    if not user_ref_query:
        return
    user_doc = user_ref_query[0]
    user_doc.reference.update({
        "moedas": Increment(quantidade)
    })

# --- (Endpoints /convite/criar, /iniciar, /finalizar - Sem alterações na lógica, só usam a nova função de busca) ---

@router.post("/convite/criar", tags=["Convite de Amigo"])
async def criar_convite(payload: ConviteCreateRequest):
    # ... (código idêntico)
    try:
        convite_ref = db.collection("batalhas_convite").document()
        nova_partida = {
            "email_desafiante": payload.email_desafiante,
            "email_desafiado": payload.email_desafiado,
            "nivel": payload.nivel,
            "status": "pendente",
            "timestamp_criacao": datetime.datetime.utcnow(),
            "pontuacao_desafiante": None,
            "tempo_desafiante": None,
            "pontuacao_desafiado": None,
            "tempo_desafiado": None,
            "vencedor": None
        }
        convite_ref.set(nova_partida)
        return {
            "success": True, 
            "message": "Convite enviado! Você precisa jogar sua rodada.", 
            "id_convite": convite_ref.id
        }
    except Exception as e:
        print(f"❌ Erro ao criar convite: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/convite/iniciar/{id_convite}/{email_jogador}", response_model=ConviteIniciarrResponse, tags=["Convite de Amigo"])
async def iniciar_convite(id_convite: str, email_jogador: str):
    # ... (código idêntico)
    try:
        convite_ref = db.collection("batalhas_convite").document(id_convite)
        convite_doc = convite_ref.get()
        if not convite_doc.exists:
            raise HTTPException(status_code=404, detail="Convite não encontrado")
        convite_data = convite_doc.to_dict()
        
        # Esta função agora usa a nova coleção
        perguntas = await get_perguntas_aleatorias(convite_data.get("nivel", "iniciante"), 10)
        
        return ConviteIniciarrResponse(
            perguntas=perguntas,
            id_convite=id_convite
        )
    except Exception as e:
        print(f"❌ Erro ao iniciar convite: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/convite/finalizar", tags=["Convite de Amigo"])
async def finalizar_convite_rodada(payload: ConviteFinalizarRequest):
    # ... (código idêntico, incluindo a chamada para atualizar_moedas)
    try:
        convite_ref = db.collection("batalhas_convite").document(payload.id_convite)
        convite_doc = convite_ref.get()
        if not convite_doc.exists:
            raise HTTPException(status_code=404, detail="Partida de convite não encontrada")
        partida_data = convite_doc.to_dict()
        
        eh_desafiante = (payload.email_jogador == partida_data.get("email_desafiante"))
        eh_desafiado = (payload.email_jogador == partida_data.get("email_desafiado"))
        
        if not eh_desafiante and not eh_desafiado:
             raise HTTPException(status_code=403, detail="Você não faz parte desta partida")

        update_data = {}
        if eh_desafiante:
            update_data["pontuacao_desafiante"] = payload.pontuacao
            update_data["tempo_desafiante"] = payload.tempo_gasto_segundos
            partida_data["pontuacao_desafiante"] = payload.pontuacao
        else:
            update_data["pontuacao_desafiado"] = payload.pontuacao
            update_data["tempo_desafiado"] = payload.tempo_gasto_segundos
            partida_data["pontuacao_desafiado"] = payload.pontuacao

        placar_A = partida_data.get("pontuacao_desafiante")
        placar_B = partida_data.get("pontuacao_desafiado")

        if placar_A is not None and placar_B is not None:
            update_data["status"] = "concluido"
            
            email_vencedor = None
            if placar_A > placar_B:
                email_vencedor = partida_data.get("email_desafiante")
                update_data["vencedor"] = email_vencedor
            elif placar_B > placar_A:
                email_vencedor = partida_data.get("email_desafiado")
                update_data["vencedor"] = email_vencedor
            else:
                update_data["vencedor"] = "empate"
            
            if email_vencedor: 
                await atualizar_moedas(email_vencedor, 25) # 🪙
            
            convite_ref.update(update_data)
            
            return {
                "status_final": "CONCLUIDO",
                "message": "Batalha finalizada!",
                "placar_desafiante": placar_A,
                "placar_desafiado": placar_B,
                "vencedor": update_data["vencedor"]
            }
        
        else:
            if eh_desafiante:
                update_data["status"] = "desafiante_jogou"
            else:
                update_data["status"] = "desafiado_jogou"
            
            convite_ref.update(update_data)
            
            return {
                "status_final": "AGUARDANDO_OPONENTE",
                "message": "Seu placar foi salvo! Aguardando seu oponente jogar."
            }
            
    except Exception as e:
        print(f"❌ Erro ao finalizar convite: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/convite/pendentes/{email_jogador}", tags=["Convite de Amigo"])
async def get_convites_pendentes(email_jogador: str):
    # ... (código idêntico)
    try:
        convites_ref = db.collection("batalhas_convite")
        query = convites_ref.where(
            filter=FieldFilter("email_desafiado", "==", email_jogador)
        ).where(
            filter=FieldFilter("status", "==", "pendente")
        ).limit(20)
        
        docs_pendentes = query.stream()
        lista_convites = []
        for doc in docs_pendentes:
            convite_data = doc.to_dict()
            convite_data["id_convite"] = doc.id
            lista_convites.append(convite_data)
        return {"success": True, "convites": lista_convites}
    
    except Exception as e:
        print(f"❌ Erro ao buscar convites pendentes: {e}")
        raise HTTPException(status_code=500, detail=str(e))