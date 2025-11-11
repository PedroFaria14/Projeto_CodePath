from fastapi import APIRouter, HTTPException, BackgroundTasks, Body
# -----------------------------------------------------------------
# REMOVIDO: fastapi_mail e ConnectionConfig
# ADICIONADO: sib_api_v3_sdk (Brevo)
# -----------------------------------------------------------------
import sib_api_v3_sdk
from sib_api_v3_sdk.rest import ApiException
# -----------------------------------------------------------------
from firebase_config import db # Sua configuração do Firestore
import datetime
import secrets # Para gerar tokens seguros
import os
from dotenv import load_dotenv
import bcrypt # Para o hash da nova senha
from pydantic import BaseModel, EmailStr

# Carrega variáveis do arquivo .env
load_dotenv()

router = APIRouter()

# -----------------------------------------------------------------
# REMOVIDO: ConnectionConfig e fm = FastMail(conf)
# -----------------------------------------------------------------

# --- Modelos Pydantic (Sem alterações) ---
class PasswordResetRequest(BaseModel):
    email: EmailStr

class ResetPasswordPayload(BaseModel):
    email: EmailStr
    token: str
    new_password: str

class ApiResponse(BaseModel):
    success: bool
    message: str

def hash_password(password: str) -> str:
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(password.encode('utf-8'), salt)
    return hashed.decode('utf-8')


# --- (NOVA) Função de Envio de Email com Brevo ---
# Esta função será chamada na Background Task
# Ela é SINCRONA, o que é perfeito para a background task
# -----------------------------------------------------------------
def send_reset_email_brevo(user_email: str, token: str, email_body: str):
    """
    Envia o email de redefinição de senha usando a API do Brevo.
    """
    print(f"Iniciando envio de email para {user_email} via Brevo...")

    # 1. Configurar a API do Brevo
    # A chave é lida da variável de ambiente (que você configurou na Render)
    config = sib_api_v3_sdk.Configuration()
    config.api_key['api-key'] = os.getenv("BREVO_API_KEY")

    if not config.api_key['api-key']:
        print("❌ ERRO CRÍTICO: BREVO_API_KEY não foi encontrada nas variáveis de ambiente.")
        return # Falha silenciosamente para não quebrar a task

    # 2. Criar a instância da API
    api_instance = sib_api_v3_sdk.TransactionalEmailsApi(sib_api_v3_sdk.ApiClient(config))

    # 3. Montar o email
    subject = f"Código de Redefinição de Senha - {os.getenv('MAIL_FROM_NAME', 'CodePath')}"
    sender_name = os.getenv("MAIL_FROM_NAME", "CodePath")
    sender_email = os.getenv("MAIL_FROM") # O email que você verificou no Brevo

    if not sender_email:
        print("❌ ERRO CRÍTICO: MAIL_FROM não foi encontrado.")
        return

    # Monta o objeto de envio
    send_smtp_email = sib_api_v3_sdk.SendSmtpEmail(
        to=[{"email": user_email}],
        sender={"name": sender_name, "email": sender_email},
        subject=subject,
        html_content=email_body # A sua variável de body HTML funciona perfeitamente
    )

    # 4. Enviar o email
    try:
        api_response = api_instance.send_transac_email(send_smtp_email)
        print(f"Email enviado com sucesso para {user_email}. Message ID: {api_response.message_id}")
    except ApiException as e:
        # Este print aparecerá nos logs da Render se algo der errado
        print(f"❌ Erro ao enviar email pelo Brevo: {e}")
    except Exception as e:
        print(f"❌ Erro inesperado no envio Brevo: {e}")


# --- Endpoint PASSO 1: Solicitar Redefinição (Modificado) ---
@router.post("/request-password-reset", response_model=ApiResponse)
async def request_password_reset(
    request: PasswordResetRequest,
    background_tasks: BackgroundTasks # A mágica continua aqui
):
    """
    Verifica o email, gera um token e envia por email (AGORA COM BREVO).
    """
    user_email = request.email
    
    if not db:
        raise HTTPException(status_code=500, detail="Erro de conexão com o banco de dados.")

    try:
        # 1. Verificar se o email existe (Sem alterações)
        users_ref = db.collection('usuarios')
        query = users_ref.where('email', '==', user_email).limit(1).stream()
        existing_users = list(query)

        if not existing_users:
            print(f"Tentativa de redefinição para email não cadastrado: {user_email}")
            return {"success": True, "message": "Se um usuário com este email existir, um código de redefinição foi enviado."}

        # 2. Gerar token (Sem alterações)
        token = str(secrets.randbelow(900000) + 100000)
        expires_at = datetime.datetime.utcnow() + datetime.timedelta(minutes=15)

        # 3. Armazenar token no Firestore (Sem alterações)
        token_ref = db.collection('password_reset_tokens').document()
        token_ref.set({
            'email': user_email,
            'token': token,
            'expires_at': expires_at,
            'created_at': datetime.datetime.utcnow(),
            'used': False
        })

        # 4. Preparar o corpo do email (Sem alterações)
        email_body = f"""
        <html>
        <body>
            <h2>Redefinição de Senha</h2>
            <p>Olá,</p>
            <p>Recebemos uma solicitação para redefinir a senha da sua conta.</p>
            <p>Use o código abaixo para criar uma nova senha. Este código expirará em 15 minutos:</p>
            <h1 style="font-size: 36px; letter-spacing: 2px; color: #333;">{token}</h1>
            <p>Se você não solicitou uma redefinição de senha, por favor ignore este email.</p>
            <br>
            <p>Atenciosamente,</p>
            <p>Equipe {os.getenv("MAIL_FROM_NAME", "CodePath")}</p>
        </body>
        </html>
        """

        # -----------------------------------------------------------------
        # MUDANÇA PRINCIPAL:
        # Trocamos 'fm.send_message' pela nossa nova função 'send_reset_email_brevo'
        # -----------------------------------------------------------------
        background_tasks.add_task(
            send_reset_email_brevo, 
            user_email, 
            token, 
            email_body
        )
        # -----------------------------------------------------------------

        return {"success": True, "message": "Se um usuário com este email existir, um código de redefinição foi enviado."}

    except Exception as e:
        print(f"❌ Erro ao processar solicitação de redefinição de senha: {e}")
        raise HTTPException(status_code=500, detail="Ocorreu um erro ao processar sua solicitação.")


# --- Endpoint PASSO 2: Definir a Nova Senha (Sem alterações) ---
# Este endpoint não envia email, então não precisa de NENHUMA alteração.
# -----------------------------------------------------------------
@router.post("/reset-password", response_model=ApiResponse)
async def reset_password(payload: ResetPasswordPayload = Body(...)):
    """
    Valida o token e o email, e atualiza a senha do usuário.
    """
    try:
        # 1. Buscar o token no banco de dados
        tokens_ref = db.collection('password_reset_tokens')
        query = tokens_ref.where('email', '==', payload.email)\
                          .where('token', '==', payload.token)\
                          .where('used', '==', False)\
                          .limit(1).stream()
        
        token_doc = next(query, None) 

        if not token_doc:
            raise HTTPException(status_code=400, detail="Código inválido ou não encontrado.")

        # 2. Verificar se o token expirou
        token_data = token_doc.to_dict()
        expires_at = token_data['expires_at']
        
        if expires_at.tzinfo is None:
                 expires_at = expires_at.replace(tzinfo=datetime.timezone.utc)

        if datetime.datetime.now(datetime.timezone.utc) > expires_at:
            raise HTTPException(status_code=400, detail="Código expirado. Solicite um novo.")

        # 3. Se o token for válido, encontrar o usuário
        users_ref = db.collection('usuarios')
        user_query = users_ref.where('email', '==', payload.email).limit(1).stream()
        user_doc = next(user_query, None)

        if not user_doc:
            raise HTTPException(status_code=404, detail="Usuário não encontrado.")

        # 4. Gerar o hash da nova senha
        new_password_hash = hash_password(payload.new_password)

        # 5. Atualizar a senha do usuário no Firestore
        user_doc.reference.update({
            'senha_hash': new_password_hash 
        })

        # 6. Invalidar o token (agora deletando)
        token_doc.reference.delete()
        print(f"Token {payload.token} para {payload.email} excluído com sucesso.") # Log opcional

        return {"success": True, "message": "Senha redefinida com sucesso!"}

    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(f"❌ Erro ao redefinir senha: {e}")
        raise HTTPException(status_code=500, detail="Erro interno ao redefinir a senha.")