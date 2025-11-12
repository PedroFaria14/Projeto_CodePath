from fastapi import APIRouter, HTTPException, Body
from pydantic import BaseModel
import datetime
from firebase_config import db
from google.cloud.firestore_v1.base_query import FieldFilter
import random
from typing import List, Dict, Any

router = APIRouter()

# --- Modelos Pydantic (Validação de Dados) ---

class DesafioCreateRequest(BaseModel):
    """ O que o app envia para criar um desafio """
    email_desafiante: str
    email_desafiado: str
    nivel: str # "iniciante", "intermediario", ou "avancado"

class DesafioSubmitRequest(BaseModel):
    """ O que o app envia para responder a pergunta """
    id_desafio: str
    email_jogador: str
    resposta: str # A alternativa que o jogador selecionou

class DesafioSubmitResponse(BaseModel):
    """ O que o servidor responde após uma submissão """
    success: bool # A resposta estava correta?
    message: str # "Você Venceu!", "Resposta Incorreta", "Tarde demais!"
    status_jogo: str # "VENCEU", "PERDEU_ATRASADO", "TENTE_NOVAMENTE"

class DesafioResponse(BaseModel):
    """ O que o servidor responde ao criar o desafio """
    success: bool
    message: str
    desafio: Dict[str, Any] | None = None # Envia o desafio inteiro

# --- Funções Auxiliares ---

async def get_pergunta_aleatoria(nivel: str) -> Dict[str, Any]:
    """ 
    Busca uma ÚNICA pergunta aleatória do nível especificado.
    (Baseado na sua lógica de 'leasson.py')
    """
    mapa_niveis = {
        "iniciante": "Facil",
        "intermediario": "Medio",
        "avancado": "Dificil"
    }
    nivel_convertido = mapa_niveis.get(nivel.lower(), "Facil")

    perguntas_ref = db.collection("perguntas").where(
        filter=FieldFilter("nivel", "==", nivel_convertido)
    ).stream()
    
    lista_perguntas = []
    for doc in perguntas_ref:
        pergunta = doc.to_dict()
        pergunta["doc_id"] = doc.id # Guardamos o ID do doc original
        lista_perguntas.append(pergunta)
    
    if not lista_perguntas:
        raise HTTPException(status_code=404, detail=f"Nenhuma pergunta encontrada para o nível {nivel}")
        
    pergunta_escolhida = random.choice(lista_perguntas)
    return pergunta_escolhida

# --- Endpoints do Desafio x1 ---

@router.post("/desafio/criar", response_model=DesafioResponse, tags=["Desafio x1"])
async def criar_desafio(payload: DesafioCreateRequest):
    """
    PASSO 1: O Jogador A (desafiante) convida o Jogador B (desafiado).
    O backend seleciona a pergunta e cria a partida.
    """
    try:
        # 1. Pega uma pergunta aleatória
        pergunta = await get_pergunta_aleatoria(payload.nivel)

        # 2. Cria o documento do desafio no Firestore
        # Coleção: 'desafios_x1'
        desafio_ref = db.collection("desafios_x1").document()
        
        # O objeto que será salvo no Firestore
        novo_desafio = {
            "id_pergunta": pergunta.get("idPergunta"),
            "pergunta_texto": pergunta.get("pergunta"),
            "opcoes": pergunta.get("opcoes"),
            "resposta_correta": pergunta.get("resposta_correta"), # CRÍTICO
            
            "desafiante_email": payload.email_desafiante,
            "desafiado_email": payload.email_desafiado,
            
            "status": "pendente", # pendente -> iniciado -> concluido
            "timestamp_criacao": datetime.datetime.utcnow(),
            
            "timestamp_inicio_desafiante": None,
            "timestamp_inicio_desafiado": None,
            
            "vencedor": None,
            "tempo_vencedor_segundos": None
        }
        
        # 3. Salva no banco
        desafio_ref.set(novo_desafio)

        # 4. Adiciona o ID do documento ao objeto antes de retornar
        novo_desafio["id_desafio"] = desafio_ref.id 

        # 5. Retorna o desafio completo para o app
        return DesafioResponse(
            success=True, 
            message="Desafio criado! Aguardando oponente.", 
            desafio=novo_desafio
        )

    except Exception as e:
        print(f"❌ Erro ao criar desafio: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/desafio/iniciar/{id_desafio}/{email_jogador}", tags=["Desafio x1"])
async def iniciar_desafio(id_desafio: str, email_jogador: str):
    """
    PASSO 2: O jogador (A ou B) ABRE a tela de batalha.
    O servidor registra o "timestamp_inicio" dele. Isso é o 'START' do cronômetro.
    """
    try:
        desafio_ref = db.collection("desafios_x1").document(id_desafio)
        desafio = desafio_ref.get()

        if not desafio.exists:
            raise HTTPException(status_code=404, detail="Desafio não encontrado")

        desafio_data = desafio.to_dict()
        
        # Define qual campo de timestamp (desafiante ou desafiado) vamos atualizar
        campo_timestamp = None
        if email_jogador == desafio_data.get("desafiante_email"):
            campo_timestamp = "timestamp_inicio_desafiante"
        elif email_jogador == desafio_data.get("desafiado_email"):
            campo_timestamp = "timestamp_inicio_desafiado"
        else:
            raise HTTPException(status_code=403, detail="Você não faz parte deste desafio")

        # Segurança: Só registra o início UMA VEZ
        if desafio_data.get(campo_timestamp) is None:
            desafio_ref.update({
                campo_timestamp: datetime.datetime.utcnow(),
                "status": "iniciado" # O primeiro a iniciar muda o status
            })

        return {"success": True, "message": "Cronômetro do servidor iniciado!"}

    except Exception as e:
        print(f"❌ Erro ao iniciar desafio: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/desafio/submeter", response_model=DesafioSubmitResponse, tags=["Desafio x1"])
async def submeter_resposta_desafio(payload: DesafioSubmitRequest):
    """
    PASSO 3: O jogador envia a resposta. Esta é a lógica de "quem responder primeiro ganha".
    O servidor é o juiz.
    """
    try:
        desafio_ref = db.collection("desafios_x1").document(payload.id_desafio)
        desafio_doc = desafio_ref.get()

        if not desafio_doc.exists:
            raise HTTPException(status_code=404, detail="Desafio não encontrado")

        desafio_data = desafio_doc.to_dict()

        # 1. VERIFICAÇÃO DE JOGO: O JOGO JÁ ACABOU?
        if desafio_data.get("status") == "concluido":
            # Se já acabou, avisa que ele perdeu por tempo
            return DesafioSubmitResponse(
                success=False, # Mesmo que a resposta esteja certa, ele foi lento
                message=f"Tarde demais! {desafio_data.get('vencedor')} respondeu primeiro.",
                status_jogo="PERDEU_ATRASADO"
            )

        # 2. VERIFICAÇÃO DA RESPOSTA: A RESPOSTA ESTÁ CORRETA?
        resposta_correta_servidor = desafio_data.get("resposta_correta")
        
        if payload.resposta != resposta_correta_servidor:
            # Resposta errada. O jogo continua.
            return DesafioSubmitResponse(
                success=False, 
                message="Resposta incorreta! Tente novamente.",
                status_jogo="TENTE_NOVAMENTE"
            )

        # 3. VERIFICAÇÃO DE VITÓRIA: A RESPOSTA ESTÁ CORRETA!
        # Agora, calculamos o tempo e declaramos a vitória.
        
        # Pega o timestamp de início correto (desafiante ou desafiado)
        campo_timestamp_inicio = None
        if payload.email_jogador == desafio_data.get("desafiante_email"):
            campo_timestamp_inicio = "timestamp_inicio_desafiante"
        elif payload.email_jogador == desafio_data.get("desafiado_email"):
            campo_timestamp_inicio = "timestamp_inicio_desafiado"
        else:
            raise HTTPException(status_code=403, detail="Você não faz parte deste desafio")

        timestamp_inicio = desafio_data.get(campo_timestamp_inicio)
        
        # Fallback: Se o jogador não chamou /iniciar (improvável), usa o tempo de criação
        if timestamp_inicio is None:
            timestamp_inicio = desafio_data.get("timestamp_criacao") 

        # CALCULA O TEMPO DE RESPOSTA
        timestamp_agora = datetime.datetime.utcnow()
        tempo_gasto = (timestamp_agora - timestamp_inicio).total_seconds()

        # 4. ATUALIZA O DESAFIO: DECLARA O VENCEDOR
        # Este 'update' é atômico. O primeiro a chegar aqui ganha.
        desafio_ref.update({
            "status": "concluido",
            "vencedor": payload.email_jogador,
            "tempo_vencedor_segundos": round(tempo_gasto, 2)
        })

        # Retorna a mensagem de vitória
        return DesafioSubmitResponse(
            success=True, 
            message=f"Parabéns, você venceu! Tempo: {round(tempo_gasto, 2)}s",
            status_jogo="VENCEU"
        )

    except Exception as e:
        print(f"❌ Erro ao submeter desafio: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/desafios/pendentes/{email_jogador}", tags=["Desafio x1"])
async def get_desafios_pendentes(email_jogador: str):
    """
    (BÔNUS) Endpoint para o Jogador B ver quais convites ele recebeu.
    """
    try:
        desafios_ref = db.collection("desafios_x1")
        
        query = desafios_ref.where(
            filter=FieldFilter("desafiado_email", "==", email_jogador)
        ).where(
            filter=FieldFilter("status", "==", "pendente")
        ).limit(20) # Limita a 20 convites
        
        docs = query.stream()
        
        lista_desafios = []
        for doc in docs:
            desafio_data = doc.to_dict()
            desafio_data["id_desafio"] = doc.id # Adiciona o ID do documento
            lista_desafios.append(desafio_data)

        return {"success": True, "desafios": lista_desafios}
    
    except Exception as e:
        print(f"❌ Erro ao buscar desafios pendentes: {e}")
        raise HTTPException(status_code=500, detail=str(e))