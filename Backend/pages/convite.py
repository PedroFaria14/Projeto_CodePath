from fastapi import APIRouter, HTTPException, Body
from pydantic import BaseModel
import datetime
from firebase_config import db
from google.cloud.firestore_v1 import Increment # Import para moedas
from google.cloud.firestore_v1.base_query import FieldFilter
import random
from typing import List, Dict, Any, Optional

# Tenta importar a função de buscar perguntas do 'batalha.py'
# Se falhar, define uma cópia local da função.
try:
    from pages.batalha import get_perguntas_aleatorias
except ImportError:
    print("WARNING: Falha ao importar 'get_perguntas_aleatorias' de batalha.py. Usando fallback.")
    async def get_perguntas_aleatorias(nivel: str, count: int = 10) -> List[Dict[str, Any]]:
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
            raise HTTPException(status_code=404, detail=f"Nenhuma pergunta para o nível {nivel}")
        num_a_pegar = min(count, len(lista_perguntas))
        if num_a_pegar < count:
            print(f"Aviso: Pedido {count}, mas só existem {num_a_pegar} no nível {nivel_convertido}")
        return random.sample(lista_perguntas, num_a_pegar)


router = APIRouter()

# --- Modelos Pydantic ---

class ConviteCreateRequest(BaseModel):
    email_desafiante: str
    email_desafiado: str
    nivel: str # "iniciante", "intermediario", "avancado"

class ConviteFinalizarRequest(BaseModel):
    id_convite: str
    email_jogador: str
    pontuacao: int # Número de acertos (Ex: 8)
    tempo_gasto_segundos: float

class ConviteIniciarrResponse(BaseModel):
    perguntas: List[Dict[str, Any]] # As 10 perguntas
    id_convite: str

# --- Funções Auxiliares ---

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

# --- Endpoints de Convite ---

@router.post("/convite/criar", tags=["Convite de Amigo"])
async def criar_convite(payload: ConviteCreateRequest):
    """
    PASSO 1: Jogador A convida Jogador B. 
    Cria a partida no Firestore.
    """
    try:
        convite_ref = db.collection("batalhas_convite").document()
        
        nova_partida = {
            "email_desafiante": payload.email_desafiante,
            "email_desafiado": payload.email_desafiado,
            "nivel": payload.nivel,
            "status": "pendente", # pendente -> desafiante_jogou -> concluido
            "timestamp_criacao": datetime.datetime.utcnow(),
            
            "pontuacao_desafiante": None,
            "tempo_desafiante": None,
            
            "pontuacao_desafiado": None,
            "tempo_desafiado": None,
            
            "vencedor": None # "empate", "email_vencedor"
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
    """
    PASSO 2: O jogador (A ou B) está pronto para jogar sua rodada.
    O backend sorteia 10 perguntas DIFERENTES para ele.
    """
    try:
        convite_ref = db.collection("batalhas_convite").document(id_convite)
        convite_doc = convite_ref.get()

        if not convite_doc.exists:
            raise HTTPException(status_code=404, detail="Convite não encontrado")
            
        convite_data = convite_doc.to_dict()
        
        # Sorteia 10 perguntas do nível da partida
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
    """
    PASSO 3: O jogador terminou suas 10 perguntas.
    Ele envia o placar. O backend salva e verifica se o jogo acabou.
    """
    try:
        convite_ref = db.collection("batalhas_convite").document(payload.id_convite)
        convite_doc = convite_ref.get()

        if not convite_doc.exists:
            raise HTTPException(status_code=404, detail="Partida de convite não encontrada")
            
        partida_data = convite_doc.to_dict()
        
        # Identifica quem está enviando o placar
        eh_desafiante = (payload.email_jogador == partida_data.get("email_desafiante"))
        eh_desafiado = (payload.email_jogador == partida_data.get("email_desafiado"))
        
        if not eh_desafiante and not eh_desafiado:
             raise HTTPException(status_code=403, detail="Você não faz parte desta partida")

        # Prepara os dados para salvar
        update_data = {}
        if eh_desafiante:
            update_data["pontuacao_desafiante"] = payload.pontuacao
            update_data["tempo_desafiante"] = payload.tempo_gasto_segundos
            partida_data["pontuacao_desafiante"] = payload.pontuacao # Atualiza para verificação
        else:
            update_data["pontuacao_desafiado"] = payload.pontuacao
            update_data["tempo_desafiado"] = payload.tempo_gasto_segundos
            partida_data["pontuacao_desafiado"] = payload.pontuacao # Atualiza para verificação

        # Pega os placares (o que acabou de chegar e o que já estava lá)
        placar_A = partida_data.get("pontuacao_desafiante")
        placar_B = partida_data.get("pontuacao_desafiado")

        # Verifica se o oponente já jogou
        if placar_A is not None and placar_B is not None:
            # AMBOS JOGARAM! O jogo acaba agora.
            update_data["status"] = "concluido"
            
            email_vencedor = None # Guarda quem venceu
            if placar_A > placar_B:
                email_vencedor = partida_data.get("email_desafiante")
                update_data["vencedor"] = email_vencedor
            elif placar_B > placar_A:
                email_vencedor = partida_data.get("email_desafiado")
                update_data["vencedor"] = email_vencedor
            else:
                update_data["vencedor"] = "empate"
            
            # Dá 25 moedas para o vencedor (se não for empate) 🪙
            if email_vencedor: 
                await atualizar_moedas(email_vencedor, 25) 
            
            # Salva o resultado final
            convite_ref.update(update_data)
            
            return {
                "status_final": "CONCLUIDO",
                "message": "Batalha finalizada!",
                "placar_desafiante": placar_A,
                "placar_desafiado": placar_B,
                "vencedor": update_data["vencedor"]
            }
        
        else:
            # O OPONENTE AINDA NÃO JOGOU
            if eh_desafiante:
                update_data["status"] = "desafiante_jogou"
            else:
                update_data["status"] = "desafiado_jogou"
            
            # Apenas salva o placar deste jogador
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
    """
    (BÔNUS) Endpoint para o Jogador B ver quais convites ele recebeu.
    Busca partidas onde ele é o 'desafiado' e o status é 'pendente'.
    """
    try:
        convites_ref = db.collection("batalhas_convite")
        
        query = convites_ref.where(
            filter=FieldFilter("email_desafiado", "==", email_jogador)
        ).where(
            # Status 'pendente' = Ninguém jogou ainda
            filter=FieldFilter("status", "==", "pendente") 
        ).limit(20) # Limita a 20 convites
        
        docs_pendentes = query.stream()
        
        lista_convites = []
        for doc in docs_pendentes:
            convite_data = doc.to_dict()
            convite_data["id_convite"] = doc.id # Adiciona o ID do documento
            lista_convites.append(convite_data)

        return {"success": True, "convites": lista_convites}
    
    except Exception as e:
        print(f"❌ Erro ao buscar convites pendentes: {e}")
        raise HTTPException(status_code=500, detail=str(e))