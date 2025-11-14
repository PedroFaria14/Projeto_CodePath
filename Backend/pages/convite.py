# Arquivo: pages/convite.py
# (CORRIGIDO: O KeyError 'vencedor' foi arrumado)

from fastapi import APIRouter, HTTPException, Body
from pydantic import BaseModel
import datetime
from firebase_config import db
from google.cloud.firestore_v1 import Increment
from google.cloud.firestore_v1.base_query import FieldFilter
import random
from typing import List, Dict, Any, Optional


try:
    from pages.battles import get_perguntas_aleatorias
except ImportError:
    print("WARNING: Falha ao importar 'get_perguntas_aleatorias' de batalha.py. Usando fallback.")
    
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


router = APIRouter()

MOEDAS_VITORIA_CONVITE = 25
MOEDAS_DERROTA_EMPATE_CONVITE = 5 

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
    if quantidade <= 0:
        return
    user_ref_query = db.collection("usuarios").where(filter=FieldFilter("email", "==", email)).limit(1).get()
    if not user_ref_query:
        return
    user_doc = user_ref_query[0]
    user_doc.reference.update({
        "moedas": Increment(quantidade)
    })

# --- (Endpoints /convite/criar e /iniciar - Sem alterações) ---
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
        perguntas = await get_perguntas_aleatorias(convite_data.get("nivel", "iniciante"), 10)
        return ConviteIniciarrResponse(
            perguntas=perguntas,
            id_convite=id_convite
        )
    except Exception as e:
        print(f"❌ Erro ao iniciar convite: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# --- 👇 ENDPOINT /convite/finalizar ATUALIZADO 👇 ---
@router.post("/convite/finalizar", tags=["Convite de Amigo"])
async def finalizar_convite_rodada(payload: ConviteFinalizarRequest):
    try:
        convite_ref = db.collection("batalhas_convite").document(payload.id_convite)
        convite_doc = convite_ref.get()
        if not convite_doc.exists:
            raise HTTPException(status_code=404, detail="Partida de convite não encontrada")
            
        partida_data = convite_doc.to_dict()
        
        email_jogador_atual = payload.email_jogador
        email_oponente_offline = ""
        
        eh_desafiante = (email_jogador_atual == partida_data.get("email_desafiante"))
        eh_desafiado = (email_jogador_atual == partida_data.get("email_desafiado"))
        
        if not eh_desafiante and not eh_desafiado:
             raise HTTPException(status_code=403, detail="Você não faz parte desta partida")
        
        if eh_desafiante:
            email_oponente_offline = partida_data.get("email_desafiado")
        else:
            email_oponente_offline = partida_data.get("email_desafiante")

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

        # Verifica se o oponente já jogou
        if placar_A is not None and placar_B is not None:
            # AMBOS JOGARAM! O jogo acaba agora.
            update_data["status"] = "concluido"
            
            email_vencedor = None
            moedas_jogador_atual = 0
            moedas_oponente = 0
            titulo_notificacao_oponente = ""
            
            # --- 👇 LÓGICA DO VENCEDOR CORRIGIDA 👇 ---
            if placar_A > placar_B:
                email_vencedor = partida_data.get("email_desafiante")
                update_data["vencedor"] = email_vencedor
            elif placar_B > placar_A:
                email_vencedor = partida_data.get("email_desafiado")
                update_data["vencedor"] = email_vencedor
            else:
                update_data["vencedor"] = "empate"
            # --- FIM DA CORREÇÃO ---

            # Define o título e as moedas para cada jogador
            if update_data["vencedor"] == "empate":
                titulo_notificacao_oponente = "Empate!"
                moedas_jogador_atual = MOEDAS_DERROTA_EMPATE_CONVITE
                moedas_oponente = MOEDAS_DERROTA_EMPATE_CONVITE
            elif email_jogador_atual == email_vencedor:
                # O jogador atual venceu
                titulo_notificacao_oponente = "Você Perdeu!"
                moedas_jogador_atual = MOEDAS_VITORIA_CONVITE
                moedas_oponente = MOEDAS_DERROTA_EMPATE_CONVITE
            else:
                # O jogador atual perdeu
                titulo_notificacao_oponente = "Você Venceu!"
                moedas_jogador_atual = MOEDAS_DERROTA_EMPATE_CONVITE
                moedas_oponente = MOEDAS_VITORIA_CONVITE
            
            # Atualiza as moedas de ambos
            await atualizar_moedas(email_jogador_atual, moedas_jogador_atual)
            await atualizar_moedas(email_oponente_offline, moedas_oponente)

            # CRIA NOTIFICAÇÃO PARA O OPONENTE OFFLINE
            db.collection("notificacoes").add({
                "email": email_oponente_offline,
                "titulo": titulo_notificacao_oponente,
                "mensagem": f"Sua batalha contra {email_jogador_atual} terminou! Placar: {placar_A} a {placar_B}.",
                "rank_change": 0, # Convite não afeta rank
                "moedas_ganhas": moedas_oponente,
                "lido": False,
                "timestamp": datetime.datetime.utcnow()
            })
            
            convite_ref.update(update_data)
            
            return {
                "status_final": "CONCLUIDO",
                "message": f"Batalha finalizada! Placar: {placar_A} a {placar_B}",
                "vencedor": update_data["vencedor"],
                "rank_change": 0, 
                "moedas_ganhas": moedas_jogador_atual
            }
        
        else:
            # O OPONENTE AINDA NÃO JOGOU
            if eh_desafiante:
                update_data["status"] = "desafiante_jogou"
            else:
                update_data["status"] = "desafiado_jogou"
            
            convite_ref.update(update_data)
            
            return {
                "status_final": "AGUARDANDO_OPONENTE",
                "message": "Seu placar foi salvo! Aguardando seu oponente jogar.",
                "rank_change": 0,
                "moedas_ganhas": 0
            }
            
    except Exception as e:
        print(f"❌ Erro ao finalizar convite: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# --- (Endpoint /convite/pendentes - Sem alterações) ---
@router.get("/convite/pendentes/{email_jogador}", tags=["Convite de Amigo"])
async def get_convites_pendentes(email_jogador: str):
    # ... (código idêntico)
    try:
        convites_ref = db.collection("batalhas_convite")
        # --- CORREÇÃO DA LÓGICA PARA BUSCAR CONVITES ATIVOS ---
        status_validos = ["pendente", "desafiante_jogou"]
        
        query = convites_ref.where(
            filter=FieldFilter("email_desafiado", "==", email_jogador)
        ).where(
            filter=FieldFilter("status", "in", status_validos) # <--- CORRIGIDO
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