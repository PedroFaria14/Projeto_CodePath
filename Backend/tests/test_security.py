import datetime as dt
import pytest
from fastapi import Depends, FastAPI, Request, HTTPException
from fastapi.testclient import TestClient
from security import authenticate, create_session, protect_request, public_user, token_digest
from passwords import validate_new_password


def session(db, email='aluno@example.org', user_id='aluno'):
    ref = db.collection('usuarios').document(user_id)
    ref.set({'email': email, 'senha_hash': 'hash-atual', 'nome': 'Aluno'})
    token = create_session(db, ref.get())['access_token']
    return token, ref


def client():
    app = FastAPI(dependencies=[Depends(protect_request)])

    @app.get('/profile/{user_email}')
    def profile(request: Request, user_email: str):
        return {'email': request.state.identity.email}

    @app.post('/salvar_progresso')
    def progress():
        return {'success': True}

    @app.post('/amigos/aceitar_pedido')
    def accept():
        return {'success': True}

    @app.post('/notificacoes/marcar_como_lido')
    def notification():
        return {'success': True}

    @app.get('/convite/iniciar/{id_convite}/{email_jogador}')
    def invitation():
        return {'success': True}

    return TestClient(app)


def test_session_stores_digest_not_bearer_and_authenticates(db):
    token, _ = session(db)
    assert ('sessions', token_digest(token)) in db.data
    assert all(token not in str(value) for value in db.data.values())
    assert authenticate(db, 'Bearer ' + token).email == 'aluno@example.org'


def test_login_verified_before_reset_cannot_mint_session_for_new_credential(db):
    _, ref = session(db)
    verified = ref.get().to_dict()
    ref.update({'senha_hash': 'senha-alterada-concorrentemente'})
    token = create_session(db, ref.get(), verified_data=verified)['access_token']
    with pytest.raises(HTTPException) as error:
        authenticate(db, 'Bearer ' + token)
    assert error.value.status_code == 401


def test_missing_forged_expired_and_password_reset_sessions_rejected(db):
    token, ref = session(db)
    api = client()
    assert api.get('/profile/aluno@example.org').status_code == 401
    assert api.get('/profile/aluno@example.org', headers={'Authorization': 'Bearer ' + 'x' * 43}).status_code == 401
    session_ref = db.collection('sessions').document(token_digest(token))
    session_ref.update({'expires_at': dt.datetime.now(dt.timezone.utc) - dt.timedelta(seconds=1)})
    assert api.get('/profile/aluno@example.org', headers={'Authorization': 'Bearer ' + token}).status_code == 401
    token, ref = session(db)
    ref.update({'senha_hash': 'novo-hash'})
    assert api.get('/profile/aluno@example.org', headers={'Authorization': 'Bearer ' + token}).status_code == 401


def test_identity_cannot_be_swapped_in_path_or_body(db):
    token, _ = session(db)
    api = client()
    headers = {'Authorization': 'Bearer ' + token}
    assert api.get('/profile/aluno@example.org', headers=headers).status_code == 200
    assert api.get('/profile/outro@example.org', headers=headers).status_code == 403
    assert api.post('/salvar_progresso', headers=headers, json={'email': 'outro@example.org'}).status_code == 403
    assert api.post('/salvar_progresso', headers=headers, json={'email': 'aluno@example.org'}).status_code == 200


@pytest.mark.parametrize('route,collection,key,fields', [
    ('/amigos/aceitar_pedido', 'amizades', 'id_pedido', {'receptor_email': 'outro@example.org'}),
    ('/notificacoes/marcar_como_lido', 'notificacoes', 'notificacao_id', {'email': 'outro@example.org'}),
])
def test_document_ids_do_not_bypass_ownership(db, route, collection, key, fields):
    token, _ = session(db)
    db.collection(collection).document('privado').set(fields)
    assert client().post(route, headers={'Authorization': 'Bearer ' + token},
                         json={key: 'privado'}).status_code == 403


def test_invitation_must_belong_to_authenticated_player(db):
    token, _ = session(db)
    db.collection('batalhas_convite').document('privado').set({
        'email_desafiante': 'outro@example.org', 'email_desafiado': 'terceiro@example.org'})
    assert client().get('/convite/iniciar/privado/aluno@example.org',
                        headers={'Authorization': 'Bearer ' + token}).status_code == 403


def test_response_uses_allowlist_for_user_fields():
    assert public_user({'nome': 'Aluno', 'senha': 'segredo', 'senha_hash': 'hash',
                        'reset_token': 'token', 'novo_campo_interno': True}) == {'nome': 'Aluno'}


def test_password_policy_preserves_spaces_and_checks_utf8_bytes():
    assert validate_new_password(' senha forte ') == ' senha forte '
    with pytest.raises(ValueError):
        validate_new_password('curta')
    with pytest.raises(ValueError):
        validate_new_password('á' * 37)
