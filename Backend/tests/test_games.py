import datetime as dt
from types import SimpleNamespace
import pytest
from fastapi import Depends, FastAPI, HTTPException
from fastapi.testclient import TestClient
from security import create_session, protect_request
from games import start_attempt, finish_attempt, router, week_key

QUESTIONS = [
    {'pergunta': 'Qual símbolo atribui?', 'tipo': 'multipla_escolha',
     'opcoes': ['=', '=='], 'resposta_correta': '='},
    {'texto_pergunta': '____ x:', 'tipo': 'codigo_snippet_word_bank',
     'palavras_banco': ['if', 'for'], 'resposta_correta': 'if'},
    {'titulo': 'Imprimir', 'tipo': 'drag_and_drop', 'partes_codigo': ['x = 1', 'print(x)']},
]


def player(db, name='aluno'):
    email = name + '@example.org'
    ref = db.collection('usuarios').document(name)
    ref.set({'email': email, 'senha_hash': 'hash', 'rank_score': 1000,
             'weekly_score': 1000, 'moedas': 0})
    token = create_session(db, ref.get())['access_token']
    return SimpleNamespace(user_id=name, email=email), {'Authorization': 'Bearer ' + token}


def client():
    app = FastAPI(dependencies=[Depends(protect_request)])
    app.include_router(router)
    return TestClient(app)


def test_answer_key_is_not_returned_and_attempts_belong_to_player(db, transactions):
    identity, headers = player(db)
    public = start_attempt(db, identity.user_id, identity.email, 'battle', QUESTIONS)
    assert public[0]['pergunta'] == 'Qual símbolo atribui?'
    assert 'resposta_correta' not in public[0]
    assert sorted(public[2]['partes_codigo']) == sorted(QUESTIONS[2]['partes_codigo'])
    _, other = player(db, 'outro')
    response = client().post('/game/answer', headers=other,
                             json={'attempt_id': public[0]['attempt_id'], 'index': 0, 'answer': '='})
    assert response.status_code == 403


def test_answers_are_ordered_single_use_and_server_scored(db, transactions):
    identity, headers = player(db)
    attempt_id = start_attempt(db, identity.user_id, identity.email, 'battle', QUESTIONS)[0]['attempt_id']
    api = client()
    assert api.post('/game/start', headers=headers, json={'attempt_id': attempt_id}).status_code == 200
    body = {'attempt_id': attempt_id, 'index': 0, 'answer': '='}
    assert api.post('/game/answer', headers=headers, json={**body, 'index': 1}).status_code == 409
    assert api.post('/game/answer', headers=headers, json=body).json() == {'correct': True, 'score': 1}
    assert api.post('/game/answer', headers=headers, json=body).json() == {'correct': True, 'score': 1}
    assert api.post('/game/answer', headers=headers, json={**body, 'answer': '=='}).status_code == 409
    assert api.post('/game/answer', headers=headers,
                    json={**body, 'index': 1, 'answer': ' if '}).json() == {'correct': True, 'score': 2}
    assert api.post('/game/answer', headers=headers,
                    json={**body, 'index': 2, 'answer': ['x = 1', 'print(x)']}).json() == {'correct': True, 'score': 3}


def test_weekly_reward_and_retry_are_applied_once(db, transactions):
    identity, headers = player(db)
    questions = [QUESTIONS[0]] * 10
    attempt_id = start_attempt(db, identity.user_id, identity.email, 'weekly', questions)[0]['attempt_id']
    api = client()
    assert api.post('/game/start', headers=headers, json={'attempt_id': attempt_id}).status_code == 200
    for index in range(6):
        assert api.post('/game/answer', headers=headers,
                        json={'attempt_id': attempt_id, 'index': index, 'answer': '='}).status_code == 200
    first = api.post('/desafio/finalizar', headers=headers, json={'attempt_id': attempt_id}).json()
    second = api.post('/desafio/finalizar', headers=headers,
                      json={'attempt_id': attempt_id, 'pontuacao': 999999}).json()
    assert first == second
    assert first['moedas_ganhas'] == 150
    user = db.collection('usuarios').document(identity.user_id).get().to_dict()
    assert user['moedas'] == 150
    assert user['weekly_score'] == 1030
    assert user['desafio_plays'] == 1
    assert user['desafio_week'] == week_key()


def test_weekly_attempts_reserved_at_start_not_reusable_on_abandon(db, transactions):
    identity, _ = player(db)
    for _ in range(3):
        attempt_id = start_attempt(db, identity.user_id, identity.email, 'weekly', QUESTIONS)[0]['attempt_id']
        # Abandono/expiração real é diferente de repetir a requisição de início.
        db.collection('game_attempts').document(attempt_id).update({
            'expires_at': dt.datetime.now(dt.timezone.utc) - dt.timedelta(seconds=1)})
    with pytest.raises(HTTPException) as error:
        start_attempt(db, identity.user_id, identity.email, 'weekly', QUESTIONS)
    assert error.value.status_code == 403


def test_battle_can_only_settle_one_opponent_and_retries_do_not_pay_again(db, transactions):
    first, _ = player(db, 'primeiro')
    second, _ = player(db, 'segundo')
    third, _ = player(db, 'terceiro')
    queued_id = start_attempt(db, first.user_id, first.email, 'battle', QUESTIONS)[0]['attempt_id']
    finish_attempt(db, first, queued_id, 'battle')
    metadata = {'opponent_id': queued_id}
    second_id = start_attempt(db, second.user_id, second.email, 'battle', QUESTIONS, metadata)[0]['attempt_id']
    with pytest.raises(HTTPException):
        start_attempt(db, third.user_id, third.email, 'battle', QUESTIONS, metadata)
    result = finish_attempt(db, second, second_id, 'battle')
    assert finish_attempt(db, second, second_id, 'battle') == result
    assert db.collection('usuarios').document(first.user_id).get().to_dict()['moedas'] == 5
    assert db.collection('usuarios').document(second.user_id).get().to_dict()['moedas'] == 5
    assert db.collection('usuarios').document(third.user_id).get().to_dict()['moedas'] == 0


def test_invite_uses_shared_questions_and_single_settlement(db, transactions):
    first, _ = player(db, 'primeiro')
    second, _ = player(db, 'segundo')
    db.collection('batalhas_convite').document('convite').set({
        'email_desafiante': first.email, 'email_desafiado': second.email, 'status': 'pendente'})
    metadata = {'invite_id': 'convite'}
    first_id = start_attempt(db, first.user_id, first.email, 'invite', QUESTIONS, metadata)[0]['attempt_id']
    second_id = start_attempt(db, second.user_id, second.email, 'invite', [QUESTIONS[1]], metadata)[0]['attempt_id']
    assert db.collection('game_attempts').document(second_id).get().to_dict()['questions'] == QUESTIONS
    finish_attempt(db, first, first_id, 'invite')
    result = finish_attempt(db, second, second_id, 'invite')
    assert finish_attempt(db, second, second_id, 'invite') == result
    assert db.collection('usuarios').document(first.user_id).get().to_dict()['moedas'] == 5


def test_pending_invitation_never_exposes_private_questions(db, transactions):
    import importlib
    first, _ = player(db, 'primeiro')
    second, headers = player(db, 'segundo')
    db.collection('batalhas_convite').document('convite').set({
        'email_desafiante': first.email, 'email_desafiado': second.email, 'status': 'pendente'})
    start_attempt(db, first.user_id, first.email, 'invite', QUESTIONS, {'invite_id': 'convite'})
    module = importlib.import_module('pages.convite')
    module.db = db
    app = FastAPI(dependencies=[Depends(protect_request)])
    app.include_router(module.router)
    response = TestClient(app).get('/convite/pendentes/' + second.email, headers=headers)
    assert response.status_code == 200
    assert len(response.json()['convites']) == 1
    assert 'resposta_correta' not in response.text
    assert 'questions' not in response.text
    assert 'attempt_desafiante' not in response.text


def test_expired_attempt_cannot_receive_answers_or_rewards(db, transactions):
    identity, headers = player(db)
    attempt_id = start_attempt(db, identity.user_id, identity.email, 'weekly', QUESTIONS)[0]['attempt_id']
    db.collection('game_attempts').document(attempt_id).update({
        'expires_at': dt.datetime.now(dt.timezone.utc) - dt.timedelta(seconds=1)})
    assert client().post('/game/answer', headers=headers,
                          json={'attempt_id': attempt_id, 'index': 0, 'answer': '='}).status_code == 409
    with pytest.raises(HTTPException):
        finish_attempt(db, identity, attempt_id, 'weekly')


def test_start_retry_recovers_answers_score_and_original_deadline(db, transactions):
    identity, headers = player(db)
    attempt_id = start_attempt(db, identity.user_id, identity.email, 'weekly', QUESTIONS)[0]['attempt_id']
    api = client()
    before_activation = db.collection('game_attempts').document(attempt_id).get().to_dict()['deadline']
    assert before_activation is not None
    original = api.post('/game/start', headers=headers, json={'attempt_id': attempt_id}).json()
    assert original['deadline'] == before_activation.isoformat()
    api.post('/game/answer', headers=headers, json={'attempt_id': attempt_id, 'index': 0, 'answer': '='})
    recovered = start_attempt(db, identity.user_id, identity.email, 'weekly', QUESTIONS)
    assert recovered[0]['attempt_id'] == attempt_id
    assert recovered[0]['attempt_state'] == {'score': 1, 'next_index': 1, 'deadline': original['deadline']}
    assert api.post('/game/start', headers=headers, json={'attempt_id': attempt_id}).json() == recovered[0]['attempt_state']
    assert db.collection('usuarios').document(identity.user_id).get().to_dict()['desafio_plays'] == 1


def test_deadline_blocks_new_answers_but_allows_settlement(db, transactions):
    identity, headers = player(db)
    attempt_id = start_attempt(db, identity.user_id, identity.email, 'weekly', QUESTIONS)[0]['attempt_id']
    db.collection('game_attempts').document(attempt_id).update({
        'deadline': dt.datetime.now(dt.timezone.utc) - dt.timedelta(seconds=1)})
    api = client()
    assert api.post('/game/answer', headers=headers,
                    json={'attempt_id': attempt_id, 'index': 0, 'answer': '='}).status_code == 409
    assert api.post('/desafio/finalizar', headers=headers, json={'attempt_id': attempt_id}).status_code == 200
