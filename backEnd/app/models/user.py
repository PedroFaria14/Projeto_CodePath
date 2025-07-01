from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime

# Modelo base para os dados do utilizador (usado para criar/atualizar)
class UserBase(BaseModel):
    email: EmailStr

# Modelo para criar um novo utilizador (inclui palavra-passe)
class UserCreate(UserBase):
    password: str

# Modelo para os dados do utilizador armazenados na base de dados
class UserInDB(UserBase):
    id: Optional[str] = None # ID do utilizador, gerado pela base de dados ou Firebase Auth
    hashed_password: str
    points: int = 0
    streak: int = 0
    medals: List[str] = []
    progress: dict = {} # Dicionário para armazenar o progresso das lições
    last_login: Optional[datetime] = None

    class Config:
        from_attributes = True # Permite que o modelo seja criado a partir de atributos de ORM/objetos

# Modelo para a resposta da API ao retornar dados do utilizador (não inclui palavra-passe hash)
class UserResponse(UserBase):
    id: str
    points: int
    streak: int
    medals: List[str]
    progress: dict
    last_login: Optional[datetime] = None

# Modelo para dados de login
class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

# Modelo para dados de lição (exemplo)
class Lesson(BaseModel):
    id: str
    title: str
    content: str
    expected_output: str
    character: str
    points: int
    medal: str
