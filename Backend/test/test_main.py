from fastapi.testclient import TestClient
# Agora este import vai funcionar, 
# se você rodar da pasta 'Backend'
from main import app 

# Criamos o cliente de teste usando o 'app' do seu main.py
client = TestClient(app)

def test_read_main_root():
    """
    Testa a rota raiz ("/") para garantir que a API está online.
    """
    # 1. EXECUÇÃO: Faz uma chamada GET para "/"
    response = client.get("/")
    
    # 2. VERIFICAÇÃO (Asserts)
    # Verifica se o status code foi 200 (OK)
    assert response.status_code == 200
    
    # Verifica se o JSON retornado é exatamente o que esperamos
    assert response.json() == {
        "status": "online",
        "message": "API CodePath funcionando com sucesso 🚀"
    }