import tkinter as tk
from tkinter import messagebox
from google.api_core.exceptions import Forbidden
from google.cloud.firestore_v1.base_query import FieldFilter
import datetime

class TelaLogin(tk.Frame):
    def __init__(self, parent, controller):
        super().__init__(parent)
        self.controller = controller

        # Layout da tela de login
        tk.Label(self, text="Login", font=("Arial", 18, "bold")).pack(pady=20)

        tk.Label(self, text="Email:").pack()
        self.email_entry = tk.Entry(self, width=40)
        self.email_entry.pack(pady=5)

        tk.Label(self, text="Senha:").pack()
        self.senha_entry = tk.Entry(self, width=40, show="*")
        self.senha_entry.pack(pady=5)

        tk.Button(self, text="Entrar", font=("Arial", 12, "bold"), bg="#4CAF50", fg="white",
                  command=self.verificar_login).pack(pady=15)
        tk.Button(self, text="Cadastrar novo usuário", font=("Arial", 10),
                  command=lambda: controller.mostrar_frame("TelaCadastro")).pack(pady=5)

    def verificar_login(self):
        """
        Verifica as credenciais do usuário e atualiza a contagem de ofensivas.
        """
        if not self.controller.db:
            messagebox.showerror("Erro de Banco de Dados", "Não foi possível conectar ao Firestore.")
            return

        email = self.email_entry.get().strip()
        senha = self.senha_entry.get().strip()

        if not email or not senha:
            messagebox.showwarning("Campos obrigatórios", "Preencha todos os campos.")
            return

        try:
            users_ref = self.controller.db.collection('usuarios')
            query = users_ref.where(filter=FieldFilter('email', '==', email)).where(filter=FieldFilter('senha', '==', senha)).limit(1).get()

            if len(query) > 0:
                user_doc = query[0]
                user_data = user_doc.to_dict()
                
                # --- Lógica da Ofensiva ---
                today = datetime.date.today()
                
                last_login = user_data.get('last_login')
                current_streak = user_data.get('streak', 0)
                
                if last_login:
                    last_login_date = last_login.date()
                    
                    if last_login_date == today - datetime.timedelta(days=1):
                        current_streak += 1
                    elif last_login_date == today:
                        pass
                    else:
                        current_streak = 1
                else:
                    current_streak = 1

                user_doc.reference.update({
                    'streak': current_streak,
                    'last_login': datetime.datetime.now() 
                })
                user_data['streak'] = current_streak

                messagebox.showinfo("Login bem-sucedido", f"Bem-vindo, {user_data['nome']}!")
                self.controller.logged_in_user = user_data
                self.controller.mostrar_frame("TelaInicial")
            else:
                messagebox.showerror("Erro", "Email ou senha incorretos.")
        except Forbidden:
            messagebox.showerror("Erro de Permissão", 
                                 "Não foi possível verificar os dados. A API do Firestore pode estar desativada. "
                                 "Por favor, ative-a no console do Google Cloud.")
        except Exception as e:
            messagebox.showerror("Erro", f"Ocorreu um erro ao verificar o login: {e}")
