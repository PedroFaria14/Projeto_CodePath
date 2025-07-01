from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime
import uuid
from passlib.context import CryptContext # Para hash de palavra-passe

from ..models.user import UserCreate, UserResponse, Token
from ..database import get_db, DBUser # Importa get_db e DBUser do database.py

router = APIRouter()

# Contexto para hash de palavra-passe
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Funções de hash e verificação de palavra-passe
def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register_user(user: UserCreate, db: Session = Depends(get_db)):
    # Verifica se o email já está registado na base de dados
    db_user = db.query(DBUser).filter(DBUser.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email já registado")

    hashed_pass = hash_password(user.password)
    new_user_id = str(uuid.uuid4()) # Gera um ID UUID para o utilizador

    # Cria uma nova instância de DBUser
    db_user = DBUser(
        id=new_user_id,
        email=user.email,
        hashed_password=hashed_pass,
        points=0,
        streak=0,
        medals=[],
        progress={},
        last_login=datetime.now()
    )
    
    # Adiciona o novo utilizador à base de dados e comita a transação
    db.add(db_user)
    db.commit()
    db.refresh(db_user) # Atualiza o objeto db_user com os dados da base de dados

    # Retorna o UserResponse validado a partir do db_user
    return UserResponse.model_validate(db_user)

@router.post("/login", response_model=Token)
async def login_for_access_token(user: UserCreate, db: Session = Depends(get_db)):
    # Procura o utilizador pelo email na base de dados
    db_user = db.query(DBUser).filter(DBUser.email == user.email).first()

    # Verifica se o utilizador existe e se a palavra-passe está correta
    if not db_user or not verify_password(user.password, db_user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Credenciais inválidas",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Atualiza o last_login do utilizador
    db_user.last_login = datetime.now()
    db.add(db_user)
    db.commit()
    db.refresh(db_user)

    # Num aplicativo real, geraria um JWT (JSON Web Token) aqui.
    # Por enquanto, usamos um token falso que contém o ID do utilizador.
    access_token = f"fake-jwt-for-{db_user.id}"
    return {"access_token": access_token, "token_type": "bearer"}
