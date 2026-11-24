"""Saída e exclusão explícita de conta com confirmação de senha."""
import bcrypt
import datetime as dt
from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel, Field
from firebase_config import db

router = APIRouter()


class DeleteAccountPayload(BaseModel):
    password: str = Field(min_length=1, max_length=72)
    confirmation: str


@router.post("/logout")
def logout(request: Request):
    db.collection("sessions").document(request.state.identity.session_id).delete()
    return {"success": True, "message": "Sessão encerrada."}


def delete_matching(collection, field, email, keep_id=None):
    """Lotes limitados; permite repetir a operação após uma falha parcial."""
    while True:
        docs = list(db.collection(collection).where(field, "==", email).limit(200).stream())
        removable = [doc for doc in docs if doc.id != keep_id]
        if not removable:
            return
        batch = db.batch()
        for doc in removable:
            batch.delete(doc.reference)
        batch.commit()


@router.delete("/account")
def delete_account(payload: DeleteAccountPayload, request: Request):
    if getattr(request.state, 'deletion_completed', False):
        return {"success": True, "message": "Conta e dados associados excluídos."}
    identity = request.state.identity
    user_ref = db.collection("usuarios").document(identity.user_id)
    document = user_ref.get()
    data = document.to_dict() if document.exists else {}
    try:
        valid = bcrypt.checkpw(payload.password.encode("utf-8"),
                               data.get("senha_hash", "").encode("utf-8"))
    except ValueError:
        valid = False
    if payload.confirmation != "EXCLUIR" or not valid:
        raise HTTPException(400, "Confira a senha e a confirmação de exclusão.")
    # Revoga as sessões existentes para outras operações. Apenas a sessão atual
    # pode repetir DELETE /account se houver falha parcial na limpeza.
    user_ref.update({"deletion_pending": True})
    relationships = {
        "amizades": ("solicitante_email", "receptor_email"),
        "batalhas_convite": ("email_desafiante", "email_desafiado"),
        "batalha_queue": ("email_jogador",),
        "notificacoes": ("email",),
        "password_reset_tokens": ("email",),
        "auth_limits": ("email",),
        "game_attempts": ("email",),
    }
    for collection, fields in relationships.items():
        for field in fields:
            delete_matching(collection, field, identity.email)
    delete_matching("sessions", "email", identity.email, keep_id=identity.session_id)
    batch = db.batch()
    batch.delete(user_ref)
    batch.delete(db.collection("sessions").document(identity.session_id))
    batch.set(db.collection('deletion_receipts').document(identity.session_id), {
        'expires_at': dt.datetime.now(dt.timezone.utc) + dt.timedelta(minutes=15),
    })
    batch.commit()
    return {"success": True, "message": "Conta e dados associados excluídos."}
