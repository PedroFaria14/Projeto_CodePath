from sqlalchemy import create_engine, Column, Integer, String, JSON, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv
from datetime import datetime

# Carrega variáveis de ambiente do ficheiro .env
load_dotenv()

# URL da base de dados. para simplicidade inicial.
# O ficheiro 'codepath.db' será criado na raiz da pasta 'backEnd'.
# Altere para a sua base de dados de produção (PostgreSQL, MySQL, etc.)
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./codepath.db")

# Cria o motor do SQLAlchemy
# connect_args é necessário apenas para SQLite para permitir múltiplas threads
engine = create_engine(
    DATABASE_URL, connect_args={"check_same_thread": False}
)

# Cria uma sessão de base de dados
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base para os modelos declarativos do SQLAlchemy
Base = declarative_base()

# Modelo SQLAlchemy para o utilizador
class DBUser(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, index=True) # ID do utilizador (UUID)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    points = Column(Integer, default=0)
    streak = Column(Integer, default=0)
    medals = Column(JSON, default=[]) # Armazenar como JSON
    progress = Column(JSON, default={}) # Armazenar como JSON
    last_login = Column(DateTime, nullable=True, default=datetime.now)

    def __repr__(self):
        return f"<DBUser(id='{self.id}', email='{self.email}')>"

# Função de utilidade para obter uma sessão de base de dados
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Função para criar as tabelas na base de dados
def create_db_tables():
    Base.metadata.create_all(bind=engine)
