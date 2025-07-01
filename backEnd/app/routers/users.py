from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

from ..models.user import UserResponse, Lesson
from ..database import get_db, DBUser # Importa get_db e DBUser do database.py
from .routes import verify_password 

router = APIRouter()

# Simulação de autenticação de utilizador (num aplicativo real, usaria JWT)
# Esta função simula que um utilizador está "logado" e retorna o seu ID
def get_current_user_id(token: str):
    # Num aplicativo real, decodificaria e validaria o JWT
    # Por enquanto, apenas extrai o ID do token falso
    if token.startswith("fake-jwt-for-"):
        user_id = token.replace("fake-jwt-for-", "")
        # Num aplicativo real, também verificaria se o user_id existe na BD
        return user_id
    raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token inválido ou utilizador não autenticado")

@router.get("/me", response_model=UserResponse)
async def read_current_user(
    user_id: str = Depends(get_current_user_id), # Simula a dependência de autenticação
    db: Session = Depends(get_db) # Injeta a sessão da base de dados
):
    # Obtém os dados do utilizador da base de dados
    db_user = db.query(DBUser).filter(DBUser.id == user_id).first()
    if not db_user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Utilizador não encontrado")
    return UserResponse.model_validate(db_user)

@router.get("/lessons", response_model=List[Lesson])
async def get_lessons():
    # Simula o retorno de lições do backend (hardcoded por enquanto)
    # Num aplicativo real, estas viriam de uma base de dados de lições
    return [
        Lesson(
            id='python-intro',
            title='Introdução ao Python 🐍',
            content='Bem-vindo ao Python! A sua primeira tarefa é imprimir "Olá, CodePath!" no ecrã. Use a função `print()`.',
            expected_output='Olá, CodePath!',
            character='🐍',
            points=10,
            medal='Primeiro Código Python',
        ),
        Lesson(
            id='js-variables',
            title='Variáveis em JavaScript 💡',
            content='Crie uma variável chamada `nome` e atribua-lhe o seu nome. Depois, imprima o valor da variável. Use `let nome = "O Seu Nome"; console.log(nome);`',
            expected_output='O Seu Nome',
            character='💡',
            points=15,
            medal='Mestre das Variáveis JS',
        ),
        Lesson(
            id='loops-python',
            title='Loops em Python 🦜',
            content='Use um ciclo `for` para imprimir a frase "Eu amo programar!" 3 vezes. Lembre-se do nosso papagaio repetidor! 🦜',
            expected_output='Eu amo programar!\nEu amo programar!\nEu amo programar!',
            character='🦜',
            points=20,
            medal='Loop Master Python',
        ),
    ]

# Rota para atualizar o progresso do utilizador após completar uma lição
@router.post("/users/{user_id}/complete_lesson")
async def complete_lesson(
    user_id: str,
    lesson_id: str,
    current_user_id: str = Depends(get_current_user_id), # Garante que o utilizador está autenticado
    db: Session = Depends(get_db) # Injeta a sessão da base de dados
):
    # Garante que o utilizador que está a completar a lição é o mesmo do token
    if user_id != current_user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Não autorizado a atualizar este utilizador")

    # Obtém os dados do utilizador da base de dados
    db_user = db.query(DBUser).filter(DBUser.id == user_id).first()
    if not db_user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Utilizador não encontrado")

    # Simula a obtenção da lição (num aplicativo real, buscaria da BD de lições)
    lessons = await get_lessons()
    current_lesson = next((l for l in lessons if l.id == lesson_id), None)
    if not current_lesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lição não encontrada")

    # Verifica se a lição já foi completada para evitar duplicar pontos/medalhas
    # Certifica-se de que progress é um dicionário mutável
    if not isinstance(db_user.progress, dict):
        db_user.progress = {}

    if lesson_id not in db_user.progress or not db_user.progress[lesson_id].get("completed"):
        db_user.points += current_lesson.points
        db_user.progress[lesson_id] = {"completed": True, "attempts": db_user.progress.get(lesson_id, {}).get("attempts", 0) + 1, "last_attempt": datetime.now().isoformat()}
        
        # Certifica-se de que medals é uma lista mutável
        if not isinstance(db_user.medals, list):
            db_user.medals = []
        if current_lesson.medal not in db_user.medals:
            db_user.medals.append(current_lesson.medal)

        # Atualiza o streak
        today = datetime.now().date()
        last_login_date = db_user.last_login.date() if db_user.last_login else None

        if last_login_date:
            diff_days = (today - last_login_date).days
            if diff_days == 1: # Se o último login foi ontem, continua o streak
                db_user.streak += 1
            elif diff_days > 1: # Se pulou um dia, reinicia o streak
                db_user.streak = 1
            # Se diff_days == 0 (mesmo dia), o streak não muda, mas last_login é atualizado
        else: # Primeiro login/lição
            db_user.streak = 1

        db_user.last_login = datetime.now()

        # Salva as alterações na base de dados
        db.add(db_user)
        db.commit()
        db.refresh(db_user) # Atualiza o objeto db_user com os dados da base de dados

        return {"message": "Lição concluída e progresso atualizado!", "user_data": UserResponse.model_validate(db_user)}
    return {"message": "Lição já concluída anteriormente."}
