import importlib
import bcrypt
from fastapi import Depends, FastAPI, HTTPException
from fastapi.testclient import TestClient
import pytest
from security import protect_request, rate_limit


def test_login_returns_session_without_credentials_and_invalid_password_is_401(db, transactions):
    module = importlib.import_module('pages.login')
    module.db = db
    ref = db.collection('usuarios').document('aluno')
    ref.set({'email': 'aluno@example.org', 'nome': 'Aluno', 'senha_hash': bcrypt.hashpw(
        b' senha correta ', bcrypt.gensalt(rounds=4)).decode()})
    app = FastAPI(dependencies=[Depends(protect_request)])
    app.include_router(module.router)
    client = TestClient(app)
    assert client.post('/login', json={'email': 'aluno@example.org', 'senha': 'errada'}).status_code == 401
    result = client.post('/login', json={'email': 'aluno@example.org', 'senha': ' senha correta '})
    assert result.status_code == 200
    assert len(result.json()['access_token']) >= 32
    assert 'senha_hash' not in result.json()['user']
    assert 'senha' not in result.json()['user']


def test_login_and_reset_limits_are_enforced_by_account(db, transactions):
    for _ in range(10):
        rate_limit(db, '/login', 'aluno@example.org')
    with pytest.raises(HTTPException) as error:
        rate_limit(db, '/login', 'aluno@example.org')
    assert error.value.status_code == 429
    assert error.value.headers['Retry-After'] == '900'
    rate_limit(db, '/login', 'outro@example.org')
    for _ in range(5):
        rate_limit(db, '/reset-password', 'aluno@example.org')
    with pytest.raises(HTTPException):
        rate_limit(db, '/reset-password', 'aluno@example.org')


def test_legacy_login_does_not_overwrite_a_concurrent_password_reset(db, transactions, monkeypatch):
    module = importlib.import_module('pages.login')
    module.db = db
    ref = db.collection('usuarios').document('legado')
    ref.set({'email': 'legado@example.org', 'senha': 'senha-antiga'})

    def reset_before_migration(password):
        ref.set({'email': 'legado@example.org', 'senha_hash': 'hash-do-reset'})
        return 'hash-da-senha-antiga'

    monkeypatch.setattr(module, 'hash_password', reset_before_migration)
    app = FastAPI(dependencies=[Depends(protect_request)])
    app.include_router(module.router)
    result = TestClient(app).post('/login', json={'email': 'legado@example.org', 'senha': 'senha-antiga'})
    assert result.status_code == 401
    assert ref.get().to_dict()['senha_hash'] == 'hash-do-reset'
    assert not any(key[0] == 'sessions' for key in db.data)
