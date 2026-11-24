"""Sessões opacas revogáveis e políticas de acesso da API mobile.

O token bruto só é enviado uma vez ao cliente. O Firestore armazena seu SHA-256,
com expiração e vínculo ao hash de senha para revogar sessões após um reset.
"""
import datetime as dt
import hashlib
import secrets
from dataclasses import dataclass

from fastapi import HTTPException, Request
from starlette.concurrency import run_in_threadpool

PUBLIC_ROUTES = {
    ("GET", "/"), ("POST", "/login"), ("POST", "/register"),
    ("POST", "/request-password-reset"), ("POST", "/reset-password"),
}

# Os campos de destinatário/oponente não representam o ator autenticado.
BODY_ACTORS = {
    "/update_nivel": "email", "/profile/set-global-level": "email",
    "/salvar_progresso": "email", "/batalha/iniciar": "email",
    "/desafio/iniciar": "email", "/amigos/enviar_pedido": "email_solicitante",
    "/amigos/remover": "email_usuario_atual", "/convite/criar": "email_desafiante",
}
USER_FIELDS = {
    "nome", "email", "data_nascimento", "telefone", "streak", "last_login",
    "nivel", "fases", "moedas", "rank_score", "weekly_score", "idade",
}


def public_user(data):
    return {key: value for key, value in data.items() if key in USER_FIELDS}


def token_digest(token):
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def credential_version(data):
    return token_digest(data.get("senha_hash") or data.get("senha") or "")


def migrate_legacy_credential(db, reference, verified_password, migrated_hash):
    from google.cloud import firestore

    @firestore.transactional
    def migrate(transaction):
        fresh = reference.get(transaction=transaction)
        data = fresh.to_dict() if fresh.exists else {}
        if not fresh.exists or 'senha_hash' in data or not secrets.compare_digest(
            credential_version(data), credential_version({'senha': verified_password})
        ):
            raise HTTPException(401, 'A credencial foi alterada. Entre novamente.')
        transaction.update(reference, {'senha_hash': migrated_hash, 'senha': firestore.DELETE_FIELD})
    migrate(db.transaction())


def create_session(db, user_doc, verified_data=None):
    token = secrets.token_urlsafe(32)
    expires = dt.datetime.now(dt.timezone.utc) + dt.timedelta(days=7)
    data = verified_data if verified_data is not None else user_doc.to_dict()
    db.collection("sessions").document(token_digest(token)).set({
        "user_id": user_doc.id, "email": data["email"], "expires_at": expires,
        "credential_version": credential_version(data),
    })
    return {"access_token": token, "token_type": "bearer", "expires_in": 604800}


@dataclass(frozen=True)
class Identity:
    user_id: str
    email: str
    session_id: str


def authenticate(db, authorization, allow_deleting=False):
    scheme, _, token = (authorization or "").partition(" ")
    if scheme.lower() != "bearer" or not 32 <= len(token) <= 128:
        raise HTTPException(401, "Entre na sua conta para continuar.")
    if db is None:
        raise HTTPException(503, "Serviço temporariamente indisponível.")
    session_id = token_digest(token)
    session = db.collection("sessions").document(session_id).get()
    if not session.exists:
        raise HTTPException(401, "Sessão expirada. Entre novamente.")
    data = session.to_dict()
    expires = data.get("expires_at")
    if not isinstance(expires, dt.datetime):
        raise HTTPException(401, "Sessão inválida.")
    if expires.tzinfo is None:
        expires = expires.replace(tzinfo=dt.timezone.utc)
    if expires <= dt.datetime.now(dt.timezone.utc):
        raise HTTPException(401, "Sessão expirada. Entre novamente.")
    user_id = data.get("user_id")
    if not isinstance(user_id, str) or not user_id or "/" in user_id:
        raise HTTPException(401, "Sessão inválida.")
    user = db.collection("usuarios").document(user_id).get()
    user_data = user.to_dict() if user.exists else {}
    if not user.exists or not secrets.compare_digest(
        data.get("credential_version", ""), credential_version(user_data)
    ):
        raise HTTPException(401, "Sessão revogada. Entre novamente.")
    if user_data.get("email") != data.get("email"):
        raise HTTPException(401, "Sessão inválida.")
    if user_data.get("deletion_pending") and not allow_deleting:
        raise HTTPException(403, "Exclusão em andamento. Conclua em Configurações > Excluir conta.")
    return Identity(user_id, user_data["email"], session_id)


def require_same_user(value, identity):
    if value != identity.email:
        raise HTTPException(403, "Você não tem acesso a estes dados.")


def require_document_owner(db, collection, document_id, identity, fields):
    if not isinstance(document_id, str) or not document_id or "/" in document_id:
        raise HTTPException(422, "Identificador inválido.")
    document = db.collection(collection).document(document_id).get()
    if not document.exists:
        raise HTTPException(404, "Recurso não encontrado.")
    data = document.to_dict()
    if not any(data.get(field) == identity.email for field in fields):
        raise HTTPException(403, "Você não tem acesso a este recurso.")


def rate_limit(db, path, email):
    """Contador transacional compartilhado entre workers; falha fechada."""
    from google.cloud import firestore
    if db is None:
        raise HTTPException(503, "Serviço temporariamente indisponível.")
    maximum = 60 if path in {'/responder', '/responderSite'} else 10 if path == "/login" else 5
    now = dt.datetime.now(dt.timezone.utc)
    ref = db.collection("auth_limits").document(token_digest(path + ':' + email.lower()))

    @firestore.transactional
    def consume(transaction):
        doc = ref.get(transaction=transaction)
        data = doc.to_dict() if doc.exists else {}
        expires = data.get("expires_at", now)
        if expires.tzinfo is None:
            expires = expires.replace(tzinfo=dt.timezone.utc)
        count = data.get("count", 0) if expires > now else 0
        if count >= maximum:
            raise HTTPException(429, "Muitas tentativas. Aguarde 15 minutos.",
                                headers={"Retry-After": "900"})
        transaction.set(ref, {"email": email, "count": count + 1,
                              "expires_at": expires if expires > now else now + dt.timedelta(minutes=15)})
    consume(db.transaction())


async def protect_request(request: Request):
    path = request.url.path.rstrip("/") or "/"
    if request.method == "OPTIONS" or (request.method, path) in PUBLIC_ROUTES:
        if request.method == "POST":
            try:
                payload = await request.json()
            except (ValueError, UnicodeDecodeError):
                return
            if isinstance(payload, dict) and isinstance(payload.get("email"), str):
                from firebase_config import db
                await run_in_threadpool(rate_limit, db, path, payload["email"][:254])
        return
    # Import tardio mantém as políticas testáveis sem inicializar o Firebase.
    from firebase_config import db
    try:
        identity = await run_in_threadpool(authenticate, db, request.headers.get("authorization"),
                                           path == "/account" and request.method == "DELETE")
    except HTTPException as error:
        # Recibo sem dados pessoais permite reconhecer um DELETE confirmado cuja
        # resposta se perdeu. Só o portador da sessão original pode recuperá-lo.
        if error.status_code == 401 and path == '/account' and request.method == 'DELETE' and db is not None:
            scheme, _, token = request.headers.get('authorization', '').partition(' ')
            if scheme.lower() == 'bearer' and 32 <= len(token) <= 128:
                receipt = await run_in_threadpool(
                    db.collection('deletion_receipts').document(token_digest(token)).get)
                if receipt.exists and receipt.to_dict()['expires_at'] > dt.datetime.now(dt.timezone.utc):
                    request.state.deletion_completed = True
                    return
        raise
    request.state.identity = identity
    if path in {'/responder', '/responderSite'}:
        await run_in_threadpool(rate_limit, db, path, identity.email)
    for name in ("email", "user_email", "email_jogador"):
        if name in request.path_params:
            require_same_user(request.path_params[name], identity)
    if "email_atual" in request.query_params:
        require_same_user(request.query_params["email_atual"], identity)
    payload = {}
    if request.method in {"POST", "PUT", "PATCH", "DELETE"}:
        try:
            payload = await request.json()
        except (ValueError, UnicodeDecodeError):
            pass  # O schema da rota é responsável pela validação do corpo.
        if not isinstance(payload, dict):
            payload = {}
    actor = BODY_ACTORS.get(path)
    if actor:
        require_same_user(payload.get(actor), identity)
    if path == "/amigos/aceitar_pedido":
        await run_in_threadpool(require_document_owner, db, "amizades",
                                payload.get("id_pedido"), identity, ("receptor_email",))
    if path == "/notificacoes/marcar_como_lido":
        await run_in_threadpool(require_document_owner, db, "notificacoes",
                                payload.get("notificacao_id"), identity, ("email",))
    convite_id = request.path_params.get("id_convite") or payload.get("id_convite")
    if path.startswith("/convite/") and convite_id:
        await run_in_threadpool(require_document_owner, db, "batalhas_convite",
                                convite_id, identity, ("email_desafiante", "email_desafiado"))
