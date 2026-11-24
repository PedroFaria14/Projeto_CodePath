# Arquivo: pages/convite.py 
# (ATUALIZADO com rank E weekly_score)

from fastapi import APIRouter, HTTPException, Body, Request
from games import start_attempt
from pydantic import BaseModel
import datetime
from firebase_config import db
from google.cloud.firestore_v1 import Increment
from google.cloud.firestore_v1.base_query import FieldFilter
import random
from typing import List, Dict, Any, Optional

try:
    # 🚀 Tenta importar as TRÊS funções
    from pages.battles import get_perguntas_aleatorias, atualizar_rank, atualizar_weekly_score
except ImportError:
    print("WARNING: Falha ao importar funções de batalha.py. Usando fallback.")
    
    # Fallback para get_perguntas_aleatorias
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
    
    # 🚀 Adiciona fallback para atualizar_rank
    async def atualizar_rank(email: str, vitoria: bool):
        print(f"WARNING: Usando fallback 'atualizar_rank' para {email}. Rank não será alterado.")
        pass

    # 🚀 Adiciona fallback para atualizar_weekly_score
    async def atualizar_weekly_score(email: str, vitoria: bool):
        print(f"WARNING: Usando fallback 'atualizar_weekly_score' para {email}. Rank semanal não será alterado.")
        pass

router = APIRouter()

# --- CONSTANTES ATUALIZADAS ---
MOEDAS_VITORIA_CONVITE = 25
MOEDAS_DERROTA_EMPATE_CONVITE = 5
RANK_VITORIA_CONVITE = 10
RANK_DERROTA_CONVITE = -10
RANK_EMPATE_CONVITE = 0

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

@router.post("/convite/criar", tags=["Convite de Amigo"])
async def criar_convite(payload: ConviteCreateRequest):
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
async def iniciar_convite(id_convite: str, email_jogador: str, request: Request):
    try:
        convite_ref = db.collection("batalhas_convite").document(id_convite)
        convite_doc = convite_ref.get()
        if not convite_doc.exists:
            raise HTTPException(status_code=404, detail="Convite não encontrado")
        convite_data = convite_doc.to_dict()
        perguntas = await get_perguntas_aleatorias(convite_data.get("nivel", "iniciante"), 10)
        return ConviteIniciarrResponse(
            perguntas=start_attempt(db, request.state.identity.user_id, email_jogador, 'invite',
                                    perguntas, {'invite_id': id_convite}),
            id_convite=id_convite
        )
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Erro ao iniciar convite: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Implementação legada preservada para referência; a rota ativa está em games.py.
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

        if placar_A is not None and placar_B is not None:
            update_data["status"] = "concluido"
            
            email_vencedor = None
            moedas_jogador_atual = 0
            moedas_oponente = 0
            titulo_notificacao_oponente = ""
            status_final_jogador_atual = "" 
            
            rank_jogador_atual = 0
            rank_oponente = 0

            if placar_A > placar_B:
                email_vencedor = partida_data.get("email_desafiante")
            elif placar_B > placar_A:
                email_vencedor = partida_data.get("email_desafiado")
            
            pontuacao_jogador_atual = 0
            pontuacao_oponente = 0
            
            if eh_desafiante:
                pontuacao_jogador_atual = placar_A
                pontuacao_oponente = placar_B
            else: # eh_desafiado
                pontuacao_jogador_atual = placar_B
                pontuacao_oponente = placar_A

            mensagem_jogador_atual = f"Batalha finalizada! Placar: {pontuacao_jogador_atual} a {pontuacao_oponente}"
            mensagem_notificacao_oponente = f"Sua batalha contra {email_jogador_atual} terminou! Placar: {pontuacao_oponente} a {pontuacao_jogador_atual}."
            
            if placar_A == placar_B:
                update_data["vencedor"] = "empate"
                titulo_notificacao_oponente = "Empate!"
                status_final_jogador_atual = "EMPATE"
                moedas_jogador_atual = MOEDAS_DERROTA_EMPATE_CONVITE
                moedas_oponente = MOEDAS_DERROTA_EMPATE_CONVITE
                rank_jogador_atual = RANK_EMPATE_CONVITE
                rank_oponente = RANK_EMPATE_CONVITE
            
            elif email_jogador_atual == email_vencedor:
                update_data["vencedor"] = email_jogador_atual
                titulo_notificacao_oponente = "Você Perdeu!"
                status_final_jogador_atual = "VITORIA"
                moedas_jogador_atual = MOEDAS_VITORIA_CONVITE
                moedas_oponente = MOEDAS_DERROTA_EMPATE_CONVITE
                
                await atualizar_rank(email_jogador_atual, vitoria=True) 
                await atualizar_rank(email_oponente_offline, vitoria=False)
                
                # 🚀 ATUALIZA O PLACAR SEMANAL
                await atualizar_weekly_score(email_jogador_atual, vitoria=True)
                await atualizar_weekly_score(email_oponente_offline, vitoria=False)
                
                rank_jogador_atual = RANK_VITORIA_CONVITE
                rank_oponente = RANK_DERROTA_CONVITE
            
            else: # Oponente (offline) venceu
                update_data["vencedor"] = email_oponente_offline
                titulo_notificacao_oponente = "Você Venceu!"
                status_final_jogador_atual = "DERROTA"
                moedas_jogador_atual = MOEDAS_DERROTA_EMPATE_CONVITE
                moedas_oponente = MOEDAS_VITORIA_CONVITE
                
                await atualizar_rank(email_jogador_atual, vitoria=False)
                await atualizar_rank(email_oponente_offline, vitoria=True)
                
                # 🚀 ATUALIZA O PLACAR SEMANAL
                await atualizar_weekly_score(email_jogador_atual, vitoria=False)
                await atualizar_weekly_score(email_oponente_offline, vitoria=True)
                
                rank_jogador_atual = RANK_DERROTA_CONVITE
                rank_oponente = RANK_VITORIA_CONVITE
            
            await atualizar_moedas(email_jogador_atual, moedas_jogador_atual)
            await atualizar_moedas(email_oponente_offline, moedas_oponente)

            db.collection("notificacoes").add({
                "email": email_oponente_offline,
                "titulo": titulo_notificacao_oponente,
                "mensagem": mensagem_notificacao_oponente,
                "rank_change": rank_oponente,
                "moedas_ganhas": moedas_oponente,
                "lido": False,
                "timestamp": datetime.datetime.utcnow()
            })
            
            convite_ref.update(update_data)
            
            return {
                "status_final": status_final_jogador_atual, 
                "message": mensagem_jogador_atual,
                "vencedor": update_data["vencedor"],
                "rank_change": rank_jogador_atual,
                "moedas_ganhas": moedas_jogador_atual
            }
        
        else:
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

@router.get("/convite/pendentes/{email_jogador}", tags=["Convite de Amigo"])
async def get_convites_pendentes(email_jogador: str):
    try:
        convites_ref = db.collection("batalhas_convite")
        status_validos = ["pendente", "desafiante_jogou"]
        
        query = convites_ref.where(
            filter=FieldFilter("email_desafiado", "==", email_jogador)
        ).where(
            filter=FieldFilter("status", "in", status_validos) 
        ).limit(20)
        
        docs_pendentes = query.stream()
        lista_convites = []
        for doc in docs_pendentes:
            convite_data = {key: value for key, value in doc.to_dict().items() if key in {
                'email_desafiante', 'email_desafiado', 'nivel', 'status', 'timestamp_criacao',
                'pontuacao_desafiante', 'pontuacao_desafiado', 'vencedor',
            }}
            convite_data["id_convite"] = doc.id
            lista_convites.append(convite_data)
        return {"success": True, "convites": lista_convites}
    
    except Exception as e:
        print(f"❌ Erro ao buscar convites pendentes: {e}")
        raise HTTPException(status_code=500, detail=str(e))
