from fastapi import APIRouter, HTTPException, BackgroundTasks
from pydantic import BaseModel, EmailStr
from fastapi_mail import FastMail, MessageSchema, ConnectionConfig, MessageType
from firebase_config import db # Sua configuração do Firestore
import datetime
import secrets # Para gerar tokens seguros
import os
from dotenv import load_dotenv

# Carrega variáveis do arquivo .env
load_dotenv()

router = APIRouter()

# --- Configuração do FastAPI-Mail (Reutilize a configuração do email de verificação) ---
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

class ApiResponse(BaseModel):
    success: bool
    message: str

# --- Endpoint para Solicitar Redefinição de Senha ---
@router.post("/request-password-reset", response_model=ApiResponse)
async def request_password_reset(
    request: PasswordResetRequest,
    background_tasks: BackgroundTasks
):
    """
    Verifica se o email existe, gera um token de redefinição,
    salva no Firestore e envia o email com o link de redefinição.
    """
    user_email = request.email

    if not db:
        raise HTTPException(status_code=500, detail="Erro de conexão com o banco de dados.")

    try:
        # 1. Verificar se o email existe na coleção 'usuarios'
        users_ref = db.collection('usuarios')
        query = users_ref.where('email', '==', user_email).limit(1).stream()
        existing_users = list(query) # Converte stream em lista para checar

        if not existing_users:
            # IMPORTANTE: Por segurança, NÃO informe se o email existe ou não.
            # Apenas retorne uma mensagem genérica para evitar enumeração de usuários.
            print(f"Tentativa de redefinição para email não cadastrado: {user_email}")
            return {"success": True, "message": "Se um usuário com este email existir, um link de redefinição foi enviado."}
            # Se preferir informar o erro (menos seguro):
            # raise HTTPException(status_code=404, detail="Email não encontrado em nossa base de dados.")

        # Pega o ID do documento do usuário (pode ser útil se quiser armazenar o token no doc do usuário)
        # user_doc_id = existing_users[0].id

        # 2. Gerar token seguro
        token = secrets.token_urlsafe(32)
        expires_at = datetime.datetime.utcnow() + datetime.timedelta(hours=1) # Token expira em 1 hora

        # 3. Armazenar token no Firestore (em uma coleção separada é recomendado)
        token_ref = db.collection('password_reset_tokens').document()
        token_ref.set({
            'email': user_email,
            'token': token,
            'expires_at': expires_at,
            'created_at': datetime.datetime.utcnow(),
            'used': False # Marcar se o token já foi usado
        })

        # 4. Montar o link de redefinição
        # !!! MUITO IMPORTANTE: Substitua 'https://SEU_FRONTEND_URL' pela URL
        # da página no SEU APLICATIVO FLUTTER que lidará com a redefinição de senha.
        # Essa página receberá o token como parâmetro.
        reset_link = f"https://SEU_FRONTEND_URL/reset-password?token={token}"

        # 5. Preparar e enviar o email
        email_body = f"""
        <html>
        <body>
            <h2>Redefinição de Senha</h2>
            <p>Olá,</p>
            <p>Recebemos uma solicitação para redefinir a senha da sua conta.</p>
            <p>Clique no link abaixo para criar uma nova senha. Este link expirará em 1 hora:</p>
            <p><a href="{reset_link}">Redefinir Senha</a></p>
            <p>Se você não solicitou uma redefinição de senha, por favor ignore este email.</p>
            <br>
            <p>Atenciosamente,</p>
            <p>Equipe {os.getenv("MAIL_FROM_NAME", "CodePath")}</p>
        </body>
        </html>
        """

        message = MessageSchema(
            subject=f"Redefinição de Senha - {os.getenv('MAIL_FROM_NAME', 'CodePath')}",
            recipients=[user_email],
            body=email_body,
            subtype=MessageType.html
        )

        background_tasks.add_task(fm.send_message, message)

        # Retorna a mensagem genérica mesmo se o email existir
        return {"success": True, "message": "Se um usuário com este email existir, um link de redefinição foi enviado."}

    except Exception as e:
        print(f"❌ Erro ao processar solicitação de redefinição de senha: {e}")
        # Retorna uma mensagem genérica em caso de erro interno
        raise HTTPException(status_code=500, detail="Ocorreu um erro ao processar sua solicitação.")