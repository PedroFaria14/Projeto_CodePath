from fastapi import APIRouter, HTTPException, BackgroundTasks, Body
from fastapi_mail import FastMail, MessageSchema, ConnectionConfig, MessageType
from firebase_config import db # Sua configuração do Firestore
import datetime
import secrets # Para gerar tokens seguros
import os
from dotenv import load_dotenv
import bcrypt # 🚀 IMPORTANTE: Para o hash da nova senha
from pydantic import BaseModel, EmailStr, SecretStr

# Carrega variáveis do arquivo .env
load_dotenv()

router = APIRouter()


conf = ConnectionConfig(
    MAIL_USERNAME=os.getenv("MAIL_USERNAME"),
    MAIL_PASSWORD=os.getenv("MAIL_PASSWORD"),
    MAIL_FROM=os.getenv("MAIL_FROM"),
    MAIL_PORT=int(os.getenv("MAIL_PORT", 587)),
    MAIL_SERVER=os.getenv("MAIL_SERVER"),
    MAIL_FROM_NAME=os.getenv("MAIL_FROM_NAME"),
    MAIL_STARTTLS=os.getenv("MAIL_STARTTLS", 'True').lower() == 'true',
    MAIL_SSL_TLS=os.getenv("MAIL_SSL_TLS", 'False').lower() == 'true',
    USE_CREDENTIALS=True,
    VALIDATE_CERTS=True,
    TEMPLATE_FOLDER=None
)
fm = FastMail(conf)


# --- Modelos Pydantic ---
class PasswordResetRequest(BaseModel):
    email: EmailStr

# 🚀 NOVO: Modelo para o Passo 2
class ResetPasswordPayload(BaseModel):
    email: EmailStr
    token: str
    new_password: str

class ApiResponse(BaseModel):
    success: bool
    message: str

# 🚀 FUNÇÃO DE HASH (Pegue do seu endpoint de registro)
def hash_password(password: str) -> str:
    """Gera o hash de uma senha."""
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(password.encode('utf-8'), salt)
    return hashed.decode('utf-8')


# --- Endpoint PASSO 1: Solicitar Redefinição ---
@router.post("/request-password-reset", response_model=ApiResponse)
async def request_password_reset(
    request: PasswordResetRequest,
    background_tasks: BackgroundTasks
):
    """
    Verifica o email, gera um token e envia por email.
    """
    user_email = request.email
    
    if not db:
        raise HTTPException(status_code=500, detail="Erro de conexão com o banco de dados.")

    try:
        # 1. Verificar se o email existe
        users_ref = db.collection('usuarios')
        query = users_ref.where('email', '==', user_email).limit(1).stream()
        existing_users = list(query)

        if not existing_users:
            # Por segurança, não informe o erro, apenas retorne a msg genérica.
            print(f"Tentativa de redefinição para email não cadastrado: {user_email}")
            return {"success": True, "message": "Se um usuário com este email existir, um código de redefinição foi enviado."}

        # 2. Gerar token (mais curto e legível para digitação)
        token = str(secrets.randbelow(900000) + 100000) # Gera um código de 6 dígitos
        expires_at = datetime.datetime.utcnow() + datetime.timedelta(minutes=15) # Expira em 15 minutos

        # 3. Armazenar token no Firestore
        token_ref = db.collection('password_reset_tokens').document()
        token_ref.set({
            'email': user_email,
            'token': token,
            'expires_at': expires_at,
            'created_at': datetime.datetime.utcnow(),
            'used': False
        })

        # 4. 🚀 CORREÇÃO: Enviar o CÓDIGO (token) no email, não um link
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

        message = MessageSchema(
            subject=f"Código de Redefinição de Senha - {os.getenv('MAIL_FROM_NAME', 'CodePath')}",
            recipients=[user_email],
            body=email_body,
            subtype=MessageType.html
        )

        background_tasks.add_task(fm.send_message, message)

        return {"success": True, "message": "Se um usuário com este email existir, um código de redefinição foi enviado."}

    except Exception as e:
        print(f"❌ Erro ao processar solicitação de redefinição de senha: {e}")
        raise HTTPException(status_code=500, detail="Ocorreu um erro ao processar sua solicitação.")


# --- 🚀 NOVO Endpoint PASSO 2: Definir a Nova Senha ---
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
        
        token_doc = next(query, None) # Pega o primeiro resultado ou None

        if not token_doc:
            raise HTTPException(status_code=400, detail="Código inválido ou não encontrado.")

        # 2. Verificar se o token expirou
        token_data = token_doc.to_dict()
        expires_at = token_data['expires_at']
        
        # Converte para 'aware' datetime (se não estiver)
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
            'senha_hash': new_password_hash # ⚠️ Certifique-se que o nome do campo é 'senha_hash'
        })

        token_doc.reference.delete()
        print(f"Token {payload.token} para {payload.email} excluído com sucesso.") # Log opcional

        return {"success": True, "message": "Senha redefinida com sucesso!"}

    except HTTPException as http_exc:
        # Repassa exceções HTTP
        raise http_exc
    except Exception as e:
        print(f"❌ Erro ao redefinir senha: {e}")
        raise HTTPException(status_code=500, detail="Erro interno ao redefinir a senha.")
