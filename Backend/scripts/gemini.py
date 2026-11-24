import google.generativeai as genai
from dotenv import load_dotenv
import os
load_dotenv()

API_KEY = os.getenv("GEMINI_API_KEY")

if API_KEY:
    genai.configure(api_key=API_KEY)


def gerar_explicacao(pergunta: str, resposta_correta: str, resposta_usuario: str, acertou: bool, prompts_persona: dict) -> str:
    if not API_KEY:
        raise RuntimeError("Feedback por IA temporariamente indisponível.")
  
    # 1. Escolhe o prompt de acordo com o resultado 
    prompt_base = prompts_persona["acerto"] if acertou else prompts_persona["erro"]
    
    # 2. Constrói o prompt final, inserindo os dados da pergunta e resposta
    prompt = f"""
    {prompt_base}
    
    Pergunta: {pergunta}
    Resposta correta: {resposta_correta}
    Resposta do usuário: {resposta_usuario}
    """
    
    # 3. Faz a chamada ao Gemini
    # model = genai.GenerativeModel("gemini-pro")
    model = genai.GenerativeModel("gemini-2.5-flash")

    response = model.generate_content(prompt)
    return response.text
