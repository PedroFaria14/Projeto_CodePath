"""Tentativas de jogo: respostas no servidor e liquidação transacional única."""
import datetime as dt
import secrets
import random
from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel, Field, field_validator
from google.cloud import firestore
from security import require_same_user

router = APIRouter()


def week_key():
    year, week, _ = dt.datetime.now(dt.timezone.utc).isocalendar()
    return f"{year}-W{week:02d}"


def public_questions(questions, attempt_id, state=None):
    result = []
    allowed = {"tipo", "fase", "pergunta", "texto_pergunta", "enunciado", "titulo", "opcoes",
               "palavras_banco", "partes_codigo", "dica", "modulo", "nivel"}
    for question in questions:
        item = {key: value for key, value in question.items() if key in allowed}
        if isinstance(item.get('partes_codigo'), list):
            item['partes_codigo'] = list(item['partes_codigo'])
            random.SystemRandom().shuffle(item['partes_codigo'])
        item['attempt_id'] = attempt_id
        item['attempt_state'] = state or {}
        result.append(item)
    return result


def attempt_state(data):
    deadline = data.get('deadline')
    return {'next_index': len(data.get('answers', [])), 'score': data.get('score', 0),
            'deadline': deadline.isoformat() if deadline is not None else None}


def start_attempt(db, user_id, email, kind, questions, metadata=None):
    if not questions:
        raise HTTPException(404, "Não há perguntas disponíveis.")
    metadata = metadata or {}
    attempt_ref = db.collection('game_attempts').document(secrets.token_urlsafe(24))
    user_ref = db.collection('usuarios').document(user_id)
    now = dt.datetime.now(dt.timezone.utc)

    @firestore.transactional
    def begin(transaction):
        user = user_ref.get(transaction=transaction)
        if not user.exists or user.to_dict().get('deletion_pending'):
            raise HTTPException(403, "Conta indisponível.")
        active_id = user.to_dict().get('active_' + kind + '_attempt')
        if active_id:
            active = db.collection('game_attempts').document(active_id).get(transaction=transaction)
            if active.exists:
                active_data = active.to_dict()
                if (active_data['status'] == 'active' and active_data['expires_at'] > now
                        and (kind != 'invite' or active_data.get('metadata') == metadata)):
                    return active_id, active_data['questions'], attempt_state(active_data)
        selected = questions
        invite_ref = None
        invite_update = None
        if kind == 'invite':
            invite_ref = db.collection('batalhas_convite').document(metadata['invite_id'])
            invite = invite_ref.get(transaction=transaction)
            data = invite.to_dict() if invite.exists else {}
            role = 'desafiante' if data.get('email_desafiante') == email else 'desafiado'
            if email not in (data.get('email_desafiante'), data.get('email_desafiado')):
                raise HTTPException(403, "Você não faz parte desta partida.")
            if data.get('status') == 'concluido' or data.get('pontuacao_' + role) is not None:
                raise HTTPException(409, "Você já concluiu esta rodada.")
            old_id = data.get('attempt_' + role)
            if old_id:
                old = db.collection('game_attempts').document(old_id).get(transaction=transaction)
                if old.exists and old.to_dict()['expires_at'] > now:
                    return old_id, old.to_dict()['questions'], attempt_state(old.to_dict())
            selected = data.get('questions') or questions
            invite_update = {'questions': selected, 'attempt_' + role: attempt_ref.id}
        opponent_ref = None
        if kind == 'battle' and metadata.get('opponent_id'):
            opponent_ref = db.collection('batalha_queue').document(metadata['opponent_id'])
            opponent = opponent_ref.get(transaction=transaction)
            opponent_data = opponent.to_dict() if opponent.exists else {}
            reserved_until = opponent_data.get('reserved_until')
            if (opponent_data.get('status') != 'aguardando_oponente'
                    or reserved_until is not None and reserved_until > now):
                raise HTTPException(409, 'Oponente já reservado. Inicie outra partida.')
            if opponent_data.get('email_jogador') == email:
                raise HTTPException(409, 'Não é possível enfrentar a própria partida.')
            selected = opponent_data['questions']
        if kind == 'weekly':
            data = user.to_dict()
            plays = data.get('desafio_plays', 0) if data.get('desafio_week') == week_key() else 0
            if plays >= 3:
                raise HTTPException(403, "Você já usou suas 3 tentativas desta semana.")
            transaction.update(user_ref, {'desafio_week': week_key(), 'desafio_plays': plays + 1})
        if invite_ref is not None:
            transaction.update(invite_ref, invite_update)
        if opponent_ref is not None:
            transaction.update(opponent_ref, {'reserved_by': attempt_ref.id,
                                            'reserved_until': now + dt.timedelta(minutes=10)})
        transaction.update(user_ref, {'active_' + kind + '_attempt': attempt_ref.id})
        transaction.set(attempt_ref, {
            'user_id': user_id, 'email': email, 'kind': kind, 'metadata': metadata,
            'questions': selected, 'answers': [], 'score': 0, 'status': 'active',
            'created_at': now, 'expires_at': now + dt.timedelta(minutes=10),
            'deadline': now + dt.timedelta(seconds=120),
        })
        return attempt_ref.id, selected, {'next_index': 0, 'score': 0,
                                          'deadline': (now + dt.timedelta(seconds=120)).isoformat()}

    attempt_id, selected, state = begin(db.transaction())
    return public_questions(selected, attempt_id, state)


def is_correct(question, answer):
    if question.get('tipo') == 'drag_and_drop' or question.get('fase') == 3:
        return isinstance(answer, list) and answer == question.get('partes_codigo')
    expected = question.get('resposta_correta')
    if not isinstance(answer, str) or not isinstance(expected, str):
        return False
    if question.get('tipo') == 'codigo_snippet_word_bank' or question.get('fase') == 2:
        return answer.replace(' ', '') == expected.replace(' ', '')
    return answer == expected


class AnswerPayload(BaseModel):
    attempt_id: str = Field(min_length=16, max_length=64, pattern=r'^[A-Za-z0-9_-]+$')
    index: int = Field(ge=0, le=49)
    answer: str | list[str]

    @field_validator('answer')
    @classmethod
    def limit_answer(cls, value):
        size = len(value) if isinstance(value, str) else sum(len(item) for item in value)
        if size > 10000 or isinstance(value, list) and len(value) > 100:
            raise ValueError('Resposta excede o tamanho permitido.')
        return value


@router.post('/game/answer')
def answer_question(payload: AnswerPayload, request: Request):
    from firebase_config import db
    ref = db.collection('game_attempts').document(payload.attempt_id)

    @firestore.transactional
    def answer(transaction):
        doc = ref.get(transaction=transaction)
        data = doc.to_dict() if doc.exists else {}
        require_same_user(data.get('email'), request.state.identity)
        answers = data['answers']
        if payload.index < len(answers):
            previous = answers[payload.index]
            if previous['answer'] != payload.answer:
                raise HTTPException(409, 'Esta pergunta já foi respondida.')
            return {'correct': previous['correct'], 'score': data['score']}
        if (data['status'] != 'active' or data.get('deadline') is None
                or data['expires_at'] <= dt.datetime.now(dt.timezone.utc)
                or data['deadline'] <= dt.datetime.now(dt.timezone.utc)):
            raise HTTPException(409, 'Tentativa encerrada ou expirada.')
        if payload.index != len(answers) or payload.index >= len(data['questions']):
            raise HTTPException(409, 'Responda às perguntas na ordem apresentada.')
        correct = is_correct(data['questions'][payload.index], payload.answer)
        answers.append({'answer': payload.answer, 'correct': correct})
        score = data['score'] + int(correct)
        transaction.update(ref, {'answers': answers, 'score': score})
        return {'correct': correct, 'score': score}
    return answer(db.transaction())


class FinishPayload(BaseModel):
    attempt_id: str = Field(min_length=16, max_length=64, pattern=r'^[A-Za-z0-9_-]+$')


@router.post('/game/start')
def activate_attempt(payload: FinishPayload, request: Request):
    from firebase_config import db
    ref = db.collection('game_attempts').document(payload.attempt_id)

    @firestore.transactional
    def activate(transaction):
        doc = ref.get(transaction=transaction)
        data = doc.to_dict() if doc.exists else {}
        require_same_user(data.get('email'), request.state.identity)
        now = dt.datetime.now(dt.timezone.utc)
        if data['status'] != 'active' or data['expires_at'] <= now:
            raise HTTPException(409, 'Tentativa encerrada ou expirada.')
        if data.get('deadline') is None:
            data['deadline'] = min(now + dt.timedelta(seconds=120), data['expires_at'])
            transaction.update(ref, {'deadline': data['deadline']})
        return attempt_state(data)
    return activate(db.transaction())


def finish_attempt(db, identity, attempt_id, expected_kind):
    ref = db.collection('game_attempts').document(attempt_id)
    user_ref = db.collection('usuarios').document(identity.user_id)

    @firestore.transactional
    def finish(transaction):
        attempt_doc = ref.get(transaction=transaction)
        data = attempt_doc.to_dict() if attempt_doc.exists else {}
        require_same_user(data.get('email'), identity)
        if data.get('kind') != expected_kind:
            raise HTTPException(409, 'Tipo de tentativa incompatível.')
        if data.get('status') == 'finished':
            return data['result']
        now = dt.datetime.now(dt.timezone.utc)
        if data['expires_at'] <= now:
            raise HTTPException(409, 'Tentativa expirada. Inicie uma nova partida.')
        user_doc = user_ref.get(transaction=transaction)
        if not user_doc.exists or user_doc.to_dict().get('deletion_pending'):
            raise HTTPException(403, 'Conta indisponível.')
        user = user_doc.to_dict()
        score = data['score']
        metadata = data['metadata']
        result = {'success': True, 'rank_change': 0, 'moedas_ganhas': 0}
        opponent_doc = None
        match_ref = None
        match_update = None
        queued = False
        if expected_kind == 'weekly':
            win = score >= 6
            result.update(status_final='VITORIA' if win else 'DERROTA',
                          rank_change=30 if win else -5, moedas_ganhas=150 if win else 0,
                          message=f'Desafio concluído! Você acertou {score} de {len(data["questions"])}.')
        elif expected_kind == 'battle':
            opponent_id = metadata.get('opponent_id')
            if not opponent_id:
                queued = True
                match_ref = db.collection('batalha_queue').document(attempt_id)
                match_update = {'email_jogador': identity.email, 'user_id': identity.user_id,
                                'rank_score_jogador': user.get('rank_score', 1000),
                                'pontuacao': score, 'questions': data['questions'],
                                'schema_version': 2,
                                'status': 'aguardando_oponente', 'timestamp_criacao': now}
            else:
                match_ref = db.collection('batalha_queue').document(opponent_id)
                match = match_ref.get(transaction=transaction)
                match_data = match.to_dict() if match.exists else {}
                if (match_data.get('status') != 'aguardando_oponente'
                        or match_data.get('reserved_by') != attempt_id):
                    raise HTTPException(409, 'Esta batalha já foi concluída. Inicie outra partida.')
                opponent_doc = db.collection('usuarios').document(match_data['user_id']).get(transaction=transaction)
                if match_data.get('email_jogador') == identity.email:
                    raise HTTPException(409, 'Não é possível enfrentar a própria partida.')
                opponent_score = match_data['pontuacao']
        else:
            match_ref = db.collection('batalhas_convite').document(metadata['invite_id'])
            match = match_ref.get(transaction=transaction)
            match_data = match.to_dict() if match.exists else {}
            role = 'desafiante' if match_data.get('email_desafiante') == identity.email else 'desafiado'
            other = 'desafiado' if role == 'desafiante' else 'desafiante'
            if identity.email not in (match_data.get('email_desafiante'), match_data.get('email_desafiado')):
                raise HTTPException(403, 'Você não faz parte desta partida.')
            if match_data.get('status') == 'concluido' or match_data.get('pontuacao_' + role) is not None:
                raise HTTPException(409, 'Rodada já concluída.')
            other_attempt = match_data.get('attempt_' + other)
            other_doc = db.collection('game_attempts').document(other_attempt).get(transaction=transaction) if other_attempt else None
            match_update = {'pontuacao_' + role: score, 'status': role + '_jogou'}
            queued = match_data.get('pontuacao_' + other) is None
            if not queued:
                if other_doc is None or not other_doc.exists:
                    raise HTTPException(409, 'Partida incompatível. Inicie um novo convite.')
                opponent_doc = db.collection('usuarios').document(other_doc.to_dict()['user_id']).get(transaction=transaction)
                opponent_score = match_data['pontuacao_' + other]
                match_update['status'] = 'concluido'
        # Todas as leituras precedem as escritas na transação Firestore.
        if queued:
            result.update(status_final='AGUARDANDO_OPONENTE', message='Placar salvo! Aguardando oponente.',
                          match_id=match_ref.id)
        elif expected_kind != 'weekly':
            if opponent_doc is None or not opponent_doc.exists or opponent_doc.to_dict().get('deletion_pending'):
                raise HTTPException(409, 'Oponente indisponível. Inicie outra partida.')
            win, tie = score > opponent_score, score == opponent_score
            reward = 50 if expected_kind == 'battle' else 25
            result.update(status_final='EMPATE' if tie else 'VITORIA' if win else 'DERROTA',
                          rank_change=0 if tie else 10 if win else -10,
                          moedas_ganhas=reward if win else 5,
                          message=f'Partida concluída! Placar: {score} a {opponent_score}.')
            opponent = opponent_doc.to_dict()
            opponent_delta = -result['rank_change']
            transaction.update(opponent_doc.reference, {
                'moedas': opponent.get('moedas', 0) + (reward if not win and not tie else 5),
                'rank_score': max(0, opponent.get('rank_score', 1000) + opponent_delta),
                'weekly_score': max(0, opponent.get('weekly_score', 1000) + opponent_delta),
            })
            transaction.set(db.collection('notificacoes').document(), {
                'email': opponent['email'], 'titulo': 'Empate!' if tie else 'Você Perdeu!' if win else 'Você Venceu!',
                'mensagem': f'Partida concluída! Placar: {opponent_score} a {score}.',
                'rank_change': opponent_delta, 'moedas_ganhas': reward if not win and not tie else 5,
                'lido': False, 'timestamp': now,
                'match_id': match_ref.id,
            })
        if not queued:
            changes = {'moedas': user.get('moedas', 0) + result['moedas_ganhas'],
                       'weekly_score': max(0, user.get('weekly_score', 1000) + result['rank_change'])}
            if expected_kind != 'weekly':
                changes['rank_score'] = max(0, user.get('rank_score', 1000) + result['rank_change'])
            transaction.update(user_ref, changes)
        if match_ref is not None:
            if expected_kind == 'battle' and not queued:
                transaction.delete(match_ref)
            elif expected_kind == 'battle':
                transaction.set(match_ref, match_update)
            else:
                transaction.update(match_ref, match_update)
        transaction.update(ref, {'status': 'finished', 'result': result, 'finished_at': now})
        return result
    return finish(db.transaction())


@router.post('/batalha/finalizar')
def finish_battle(payload: FinishPayload, request: Request):
    from firebase_config import db
    return finish_attempt(db, request.state.identity, payload.attempt_id, 'battle')


@router.post('/convite/finalizar')
def finish_invite(payload: FinishPayload, request: Request):
    from firebase_config import db
    return finish_attempt(db, request.state.identity, payload.attempt_id, 'invite')


@router.post('/desafio/finalizar')
def finish_weekly(payload: FinishPayload, request: Request):
    from firebase_config import db
    return finish_attempt(db, request.state.identity, payload.attempt_id, 'weekly')
