import tkinter as tk
from tkinter import messagebox
from google.api_core.exceptions import Forbidden
import datetime

class TelaCadastro(tk.Frame):
    def __init__(self, parent, controller):
        super().__init__(parent)
        self.controller = controller

        # Layout da tela de cadastro
        tk.Label(self, text="Cadastro de Novo Usuário", font=("Arial", 16, "bold")).pack(pady=20)

        self.campos = {}
        for campo in ["Nome", "Email", "Senha"]:
            tk.Label(self, text=campo + ":").pack()
            entry = tk.Entry(self, width=40, show="*" if campo == "Senha" else "")
            entry.pack(pady=4)
            self.campos[campo] = entry

        tk.Button(self, text="Cadastrar", command=self.cadastrar_usuario, bg="#4CAF50", fg="white").pack(pady=15)
        tk.Button(self, text="Voltar", command=lambda: controller.mostrar_frame("TelaLogin")).pack()

    def cadastrar_usuario(self):
        """
        Coleta e valida os dados do formulário para cadastrar um novo usuário no Firestore.
        """
        if not self.controller.db:
            messagebox.showerror("Erro de Banco de Dados", "Não foi possível conectar ao Firestore.")
            return

        nome = self.campos["Nome"].get().strip()
        email = self.campos["Email"].get().strip()
        senha = self.campos["Senha"].get().strip()

        if not nome or not email or not senha:
            messagebox.showwarning("Campos obrigatórios", "Preencha todos os campos.")
            return

        try:
            users_ref = self.controller.db.collection('usuarios')
            query = users_ref.where('email', '==', email).limit(1).get()
            if len(query) > 0:
                messagebox.showerror("Erro", "Este email já está cadastrado.")
                return

            users_ref.add({
                "nome": nome,
                "email": email,
                "senha": senha, 
                "streak": 1,
                "last_login": datetime.datetime.now() 
            })

            messagebox.showinfo("Sucesso", "Usuário cadastrado com sucesso!")
            self.controller.mostrar_frame("TelaLogin")
        except Forbidden:
            messagebox.showerror("Erro de Permissão", 
                                 "Não foi possível salvar os dados. A API do Firestore pode estar desativada. "
                                 "Por favor, ative-a no console do Google Cloud.")
        except Exception as e:
            messagebox.showerror("Erro", f"Ocorreu um erro ao cadastrar o usuário: {e}")
