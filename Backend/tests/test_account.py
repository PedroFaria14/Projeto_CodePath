import importlib
import bcrypt
from fastapi import Depends, FastAPI
from fastapi.testclient import TestClient
from security import create_session, protect_request, token_digest


def setup_account(db):
    user = db.collection('usuarios').document('aluno')
    user.set({'email': 'aluno@example.org', 'senha_hash': bcrypt.hashpw(
        b'senha-correta', bcrypt.gensalt(rounds=4)).decode()})
    token = create_session(db, user.get())['access_token']
    module = importlib.import_module('pages.account')
    module.db = db
    app = FastAPI(dependencies=[Depends(protect_request)])
    app.include_router(module.router)
    return TestClient(app), {'Authorization': 'Bearer ' + token}, token


def test_logout_revokes_server_session(db):
    api, headers, token = setup_account(db)
    assert api.post('/logout', headers=headers).status_code == 200
    assert ('sessions', token_digest(token)) not in db.data
    assert api.post('/logout', headers=headers).status_code == 401


def test_deletion_requires_password_and_confirmation(db):
    api, headers, _ = setup_account(db)
    assert api.delete('/account').status_code == 401
    response = api.request('DELETE', '/account', headers=headers,
                           json={'password': 'incorreta', 'confirmation': 'EXCLUIR'})
    assert response.status_code == 400
    assert ('usuarios', 'aluno') in db.data


def test_deletion_cleans_personal_records_and_preserves_other_users(db):
    api, headers, _ = setup_account(db)
    for collection, field in [('amizades', 'solicitante_email'), ('batalhas_convite', 'email_desafiado'),
                              ('notificacoes', 'email'), ('batalha_queue', 'email_jogador'),
                              ('password_reset_tokens', 'email')]:
        db.collection(collection).document('meu').set({field: 'aluno@example.org'})
        db.collection(collection).document('outro').set({field: 'outro@example.org'})
    response = api.request('DELETE', '/account', headers=headers,
                           json={'password': 'senha-correta', 'confirmation': 'EXCLUIR'})
    assert response.status_code == 200
    assert ('usuarios', 'aluno') not in db.data
    assert not any(key[0] == 'sessions' for key in db.data)
    assert all(key[1] == 'outro' or key[0] == 'deletion_receipts' for key in db.data)
    retried = api.request('DELETE', '/account', headers=headers,
                          json={'password': 'senha-correta', 'confirmation': 'EXCLUIR'})
    assert retried.status_code == 200
    receipt = next(value for key, value in db.data.items() if key[0] == 'deletion_receipts')
    assert set(receipt) == {'expires_at'}
