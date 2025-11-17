# Arquivo: pages/desafio.py (ATUALIZADO com Rotação de Módulo)

from fastapi import APIRouter, HTTPException, Body
from pydantic import BaseModel
import datetime
from firebase_config import db
from google.cloud.firestore_v1 import Increment, FieldFilter
import random
from typing import List, Dict, Any

router = APIRouter()

# --- Constantes do Desafio ---

# 🚀 LISTA DOS MÓDULOS QUE TÊM PERGUNTAS DE CÓDIGO
# Adicione novos módulos aqui quando você criar perguntas para eles
MODULOS_DO_DESAFIO = [
    "Condicionais",
    "Variáveis e Tipos",
    "Laços de Repetição"
    # "Funções" # (Adicione quando tiver perguntas)
]

QTD_PERGUNTAS_DESAFIO = 5
PONTUACAO_MINIMA = 3
RECOMPENSA_MOEDAS = 150
RECOMPENSA_RANK_VITORIA = 30
RECOMPENSA_RANK_DERROTA = -5
COLECAO_DESAFIO = "desafio_perguntas" 

class DesafioRequest(BaseModel):
    email: str

class DesafioFinalizarRequest(BaseModel):
    email: str
    pontuacao: int # Quantos acertou (de 5)

def get_semana_atual() -> int:
    """ Retorna o número da semana no ano (1 a 53) """
    return datetime.date.today().isocalendar()[1] # [1] pega a semana

# 🚀 NOVA FUNÇÃO PARA ESCOLHER O MÓDULO DA SEMANA
def get_modulo_da_semana() -> str:
    """
    Seleciona um módulo da lista baseado no número da semana.
    Isso garante que ele rode automaticamente.
    """
    semana_atual = get_semana_atual()
    num_modulos = len(MODULOS_DO_DESAFIO)
    
    if num_modulos == 0:
        return "Condicionais" # Um módulo padrão caso a lista esteja vazia
        
    # Usa o operador "módulo" (%) para ciclar pela lista
    # Ex: Semana 1 % 3 = 1 -> Módulo 1
    # Ex: Semana 2 % 3 = 2 -> Módulo 2
    # Ex: Semana 3 % 3 = 0 -> Módulo 0
    # Ex: Semana 4 % 3 = 1 -> Módulo 1 (volta pro primeiro)
    indice_modulo = semana_atual % num_modulos
    return MODULOS_DO_DESAFIO[indice_modulo]

# --- Funções Auxiliares (copiadas) ---

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

# --- Fim das Funções Auxiliares ---


@router.post("/desafio/iniciar", tags=["Desafio Semanal"])
async def iniciar_desafio(payload: DesafioRequest):
    """
    Verifica se o usuário já jogou e retorna 5 perguntas de código
    do MÓDULO DA SEMANA (escolhido automaticamente).
    """
    try:
        semana_atual = get_semana_atual()
        
        # 1. 🚀 ESCOLHE O MÓDULO DA SEMANA AUTOMATICAMENTE
        modulo_da_semana = get_modulo_da_semana()
        
        # 2. Verifica se o usuário já jogou
        user_ref_query = db.collection("usuarios").where(filter=FieldFilter("email", "==", payload.email)).limit(1).get()
        if not user_ref_query:
            raise HTTPException(status_code=404, detail="Usuário não encontrado")
            
        user_doc = user_ref_query[0]
        user_data = user_doc.to_dict()
        
        semana_ultimo_desafio = user_data.get("semana_ultimo_desafio", 0)
        
        if semana_ultimo_desafio == semana_atual:
            raise HTTPException(status_code=403, detail=f"Você já completou o desafio desta semana! O módulo é: {modulo_da_semana}.")

        # 3. Busca as 5 perguntas de código do módulo da semana
        perguntas_ref = db.collection(COLECAO_DESAFIO).where(
            filter=FieldFilter("modulo", "==", modulo_da_semana) # 🚀 USA A VARIÁVEL
        ).stream() 
        
        lista_perguntas = [doc.to_dict() for doc in perguntas_ref]
        
        if len(lista_perguntas) < QTD_PERGUNTAS_DESAFIO:
            raise HTTPException(status_code=404, detail=f"Erro: Perguntas de desafio insuficientes ({len(lista_perguntas)}/{QTD_PERGUNTAS_DESAFIO}) para o módulo '{modulo_da_semana}'.")

        perguntas_escolhidas = random.sample(lista_perguntas, QTD_PERGUNTAS_DESAFIO)

        # Retorna as perguntas E o nome do módulo (para o app mostrar)
        return {"success": True, "perguntas": perguntas_escolhidas, "modulo": modulo_da_semana}

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