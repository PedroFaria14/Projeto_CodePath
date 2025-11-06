import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock 

# Isso está correto, pois seu test_main.py funcionou
from main import app 

client = TestClient(app)

# ---
# CENÁRIO 1: SUCESSO (HTTP 200)
# ---

# CORRIGIDO AQUI (pages.profile.db)
@patch('firebase_config.db') 
def test_get_profile_sucesso(mock_db):
    """Testa se o perfil é encontrado e a senha é removida."""
    
    # 1. PREPARAÇÃO (O Mock)
    dados_falsos_do_banco = {
        'nome': 'Usuario Teste',
        'email': 'teste@exemplo.com',
        'senha': 'senhaSuperSeScreta123' 
    }
    
    doc_falso = MagicMock()
    doc_falso.to_dict.return_value = dados_falsos_do_banco
    
    mock_db.collection.return_value.where.return_value.limit.return_value.get.return_value = [doc_falso]
    
    
    # 2. EXECUÇÃO
    response = client.get("/profile/teste@exemplo.com")
    
    # 3. VERIFICAÇÃO
    assert response.status_code == 200
    
    data = response.json()
    assert data['success'] is True
    assert data['message'] == "Perfil encontrado."
    assert data['user']['email'] == 'teste@exemplo.com'
    assert 'senha' not in data['user']

# ---
# CENÁRIO 2: NÃO ENCONTRADO (HTTP 404)
# ---

# CORRIGIDO AQUI (pages.profile.db) E NO NOME DA FUNÇÃO
@patch('firebase_config.db') 
def test_get_profile_nao_encontrado(mock_db):
    """Testa o que acontece se o usuário não existir (query vazia)."""
    
    # 1. PREPARAÇÃO
    mock_db.collection.return_value.where.return_value.limit.return_value.get.return_value = []
    
    # 2. EXECUÇÃO
    response = client.get("/profile/fantasma@exemplo.com")
    
    # 3. VERIFICAÇÃO
    assert response.status_code == 404
    assert response.json() == {"detail": "Usuário não encontrado."}

# ---
# CENÁRIO 3: ERRO DE CONEXÃO (HTTP 500)
# ---

# CORRIGIDO AQUI (pages.profile.db)
@patch('firebase_config.db', None) 
def test_get_profile_sem_conexao_db():
    """Testa a primeira verificação: 'if not db:'."""
    
    # 1. PREPARAÇÃO (Feita no @patch)
    
    # 2. EXECUÇÃO
    response = client.get("/profile/teste@exemplo.com")
    
    # 3. VERIFICAÇÃO
    assert response.status_code == 500
    assert response.json() == {"detail": "Erro de conexão com o banco de dados."}

# ---
# CENÁRIO 4: EXCEÇÃO GERAL (HTTP 500)
# ---

# CORRIGIDO AQUI (pages.profile.db)
@patch('firebase_config.db')
def test_get_profile_erro_geral(mock_db):
    """Testa o bloco try/except, simulando uma falha no Firestore."""
    
    # 1. PREPARAÇÃO
    mock_db.collection.return_value.where.return_value.limit.return_value.get.side_effect = Exception("Falha no satélite")
    
    # 2. EXECUÇÃO
    response = client.get("/profile/teste@exemplo.com")
    
    # 3. VERIFICAÇÃO
    assert response.status_code == 500
    assert "Ocorreu um erro ao buscar o perfil" in response.json()['detail']
    assert "Falha no satélite" in response.json()['detail']