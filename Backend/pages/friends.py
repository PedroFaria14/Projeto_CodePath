from fastapi import APIRouter, HTTPException, Body
from pydantic import BaseModel, EmailStr
import datetime
from firebase_config import db
from google.cloud.firestore_v1.base_query import FieldFilter
from google.cloud.firestore_v1.client import Client
from typing import List, Dict, Any

router = APIRouter()

# --- Modelos Pydantic ---

class AmizadeRequest(BaseModel):
    email_solicitante: str
    email_receptor: str # O email do usuário que foi encontrado na busca

class PedidoAmizadeResponse(BaseModel):
    id_pedido: str # O ID do documento da amizade

class RemoverAmigoRequest(BaseModel):
    email_usuario_atual: str
    email_amigo_para_remover: str

class UsuarioEncontrado(BaseModel):
    nome: str
    email: EmailStr

# --- Funções Auxiliares ---

async def get_user_data(email: str) -> Dict[str, Any]:
    """ Busca o 'nome' e 'email' de um usuário """
    user_ref = db.collection("usuarios").where(filter=FieldFilter("email", "==", email)).limit(1).get()
    if not user_ref:
        return None
    user_data = user_ref[0].to_dict()
    return {
        "email": user_data.get("email"),
        "nome": user_data.get("nome")
    }

async def find_amizade_doc(email_a: str, email_b: str):
    """ Encontra um documento de amizade entre A e B, em qualquer direção """
    amizades_ref = db.collection("amizades")
    
    # Checa A -> B
    query1 = amizades_ref.where(
        filter=FieldFilter("solicitante_email", "==", email_a)
    ).where(
        filter=FieldFilter("receptor_email", "==", email_b)
    ).limit(1).get()
    
    if query1:
        return query1[0] # Retorna o DocumentSnapshot

    # Checa B -> A
    query2 = amizades_ref.where(
        filter=FieldFilter("solicitante_email", "==", email_b)
    ).where(
        filter=FieldFilter("receptor_email", "==", email_a)
    ).limit(1).get()
    
    if query2:
        return query2[0] # Retorna o DocumentSnapshot
        
    return None # Não encontrou

# --- Endpoints de Amizade ---

@router.get("/usuarios/buscar/{nome_parcial}", response_model=List[UsuarioEncontrado], tags=["Amigos"])
async def buscar_usuario_por_nome(nome_parcial: str, email_atual: str):
    """
    NOVO: Busca usuários por parte do nome para adicionar.
    Exclui o próprio usuário da busca.
    """
    if not nome_parcial or len(nome_parcial) < 3:
        raise HTTPException(status_code=400, detail="A busca deve ter pelo menos 3 caracteres.")
        
    try:
        users_ref = db.collection("usuarios")
        
        # Firestore não suporta 'LIKE' ou 'contains'. A melhor aproximação é
        # buscar por 'começa com'. Ex: "Ped" acha "Pedro".
        # Nota: Isso é case-sensitive. "pedro" é diferente de "Pedro".
        # Para melhorar, você pode salvar um campo 'nome_lowercase' no registro.
        
        query = users_ref.where(
            filter=FieldFilter("nome", ">=", nome_parcial)
        ).where(
            filter=FieldFilter("nome", "<=", nome_parcial + '\uf8ff')
        ).limit(10) # Limita a 10 resultados
        
        docs = query.stream()
        
        resultados = []
        for doc in docs:
            user_data = doc.to_dict()
            if user_data.get("email") != email_atual: # Não se adicione
                resultados.append(
                    UsuarioEncontrado(
                        nome=user_data.get("nome", "Nome não encontrado"),
                        email=user_data.get("email")
                    )
                )
        
        return resultados

    except Exception as e:
        print(f"❌ Erro ao buscar usuários: {e}")
        raise HTTPException(status_code=500, detail="Erro ao buscar usuários.")


@router.post("/amigos/enviar_pedido", tags=["Amigos"])
async def enviar_pedido_amizade(payload: AmizadeRequest):
    """
    PASSO 1: Jogador A envia um pedido para Jogador B (por email)
    """
    try:
        if payload.email_solicitante == payload.email_receptor:
            raise HTTPException(status_code=400, detail="Você não pode adicionar a si mesmo.")

        receptor_data = await get_user_data(payload.email_receptor)
        if not receptor_data:
            raise HTTPException(status_code=404, detail="O usuário que você tentou adicionar não foi encontrado.")
            
        solicitante_data = await get_user_data(payload.email_solicitante)
        if not solicitante_data:
            raise HTTPException(status_code=404, detail="Usuário solicitante não encontrado.")

        # Verifica se já existe um pedido (em qualquer direção)
        amizade_existente = await find_amizade_doc(payload.email_solicitante, payload.email_receptor)
        if amizade_existente:
            status = amizade_existente.to_dict().get("status")
            if status == "aceito":
                raise HTTPException(status_code=400, detail="Vocês já são amigos.")
            else:
                raise HTTPException(status_code=400, detail="Um pedido de amizade entre vocês dois já existe.")

        # Cria o novo pedido de amizade
        pedido_ref = db.collection("amizades").document()
        
        novo_pedido = {
            "solicitante_email": solicitante_data["email"],
            "solicitante_nome": solicitante_data["nome"],
            "receptor_email": receptor_data["email"],
            "receptor_nome": receptor_data["nome"],
            "status": "pendente",
            "timestamp_criacao": datetime.datetime.utcnow()
        }
        
        pedido_ref.set(novo_pedido)
        
        return {"success": True, "message": "Pedido de amizade enviado!"}

    except HTTPException as http_exc:
        raise http_exc # Re-levanta a exceção HTTP (400, 404)
    except Exception as e:
        print(f"❌ Erro ao enviar pedido de amizade: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/amigos/pedidos_pendentes/{email_jogador}", tags=["Amigos"])
async def get_pedidos_pendentes(email_jogador: str):
    """
    PASSO 2: O Jogador B vê quais pedidos ele recebeu
    """
    try:
        pedidos_ref = db.collection("amizades").where(
            filter=FieldFilter("receptor_email", "==", email_jogador)
        ).where(
            filter=FieldFilter("status", "==", "pendente")
        ).limit(20)
        
        docs = pedidos_ref.stream()
        
        lista_pedidos = []
        for doc in docs:
            pedido_data = doc.to_dict()
            pedido_data["id_pedido"] = doc.id
            lista_pedidos.append(pedido_data)

        return {"success": True, "pedidos": lista_pedidos}
    
    except Exception as e:
        print(f"❌ Erro ao buscar pedidos pendentes: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/amigos/aceitar_pedido", tags=["Amigos"])
async def aceitar_pedido_amizade(payload: PedidoAmizadeResponse):
    """
    PASSO 3: Jogador B aceita o pedido (usando o ID do pedido)
    """
    try:
        pedido_ref = db.collection("amizades").document(payload.id_pedido)
        pedido_doc = pedido_ref.get()
        
        if not pedido_doc.exists:
             raise HTTPException(status_code=404, detail="Pedido de amizade não encontrado.")

        pedido_ref.update({
            "status": "aceito",
            "timestamp_aceito": datetime.datetime.utcnow()
        })
        
        return {"success": True, "message": "Amizade aceita!"}

    except Exception as e:
        print(f"❌ Erro ao aceitar pedido: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/amigos/listar/{email_jogador}", tags=["Amigos"])
async def get_lista_amigos(email_jogador: str):
    """
    PASSO 4: O jogador vê sua lista de amigos (para desafiar)
    """
    try:
        amigos_lista = []
        
        # Query 1: Onde EU sou o receptor
        query1 = db.collection("amizades").where(
            filter=FieldFilter("receptor_email", "==", email_jogador)
        ).where(
            filter=FieldFilter("status", "==", "aceito")
        ).stream()
        
        for doc in query1:
            amigo_data = doc.to_dict()
            amigos_lista.append({
                "nome": amigo_data.get("solicitante_nome"),
                "email": amigo_data.get("solicitante_email")
            })

        # Query 2: Onde EU sou o solicitante
        query2 = db.collection("amizades").where(
            filter=FieldFilter("solicitante_email", "==", email_jogador)
        ).where(
            filter=FieldFilter("status", "==", "aceito")
        ).stream()
        
        for doc in query2:
            amigo_data = doc.to_dict()
            amigos_lista.append({
                "nome": amigo_data.get("receptor_nome"),
                "email": amigo_data.get("receptor_email")
            })

        return {"success": True, "amigos": amigos_lista}
    
    except Exception as e:
        print(f"❌ Erro ao listar amigos: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/amigos/remover", tags=["Amigos"])
async def remover_amigo(payload: RemoverAmigoRequest):
    """
    NOVO: Remove uma amizade (aceita ou pendente)
    """
    try:
        # 1. Encontra o documento da amizade
        amizade_doc = await find_amizade_doc(payload.email_usuario_atual, payload.email_amigo_para_remover)
        
        if not amizade_doc:
            raise HTTPException(status_code=404, detail="Relação de amizade não encontrada.")

        # 2. Deleta o documento
        amizade_doc.reference.delete()
        
        return {"success": True, "message": "Amigo removido com sucesso."}

    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(f"❌ Erro ao remover amigo: {e}")
        raise HTTPException(status_code=500, detail=str(e))