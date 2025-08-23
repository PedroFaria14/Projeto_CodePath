import tkinter as tk
from tkinter import messagebox

class TelaPerfil(tk.Frame):
    def __init__(self, parent, controller):
        super().__init__(parent)
        self.controller = controller
        
        self.user_data = self.controller.logged_in_user

        # Layout da tela de perfil
        tk.Label(self, text="Perfil do Usuário", font=("Arial", 20, "bold")).pack(pady=20)

        if self.user_data:
            nome = self.user_data.get("nome", "Usuário")
            email = self.user_data.get("email", "")
            streak = self.user_data.get("streak", 0)
            
            tk.Label(self, text=f"Olá, {nome}!", font=("Arial", 16)).pack(pady=10)
            tk.Label(self, text=f"Email: {email}", font=("Arial", 12)).pack(pady=5)
            tk.Label(self, text=f"🔥 Ofensivas: {streak} dias", font=("Arial", 14, "bold")).pack(pady=10)
        else:
            tk.Label(self, text="Nenhum usuário logado.", font=("Arial", 16)).pack(pady=10)
            
        tk.Button(self, text="Ir para o Menu Principal", 
                  font=("Arial", 12, "bold"), 
                  bg="#4CAF50", 
                  fg="white",
                  command=lambda: controller.mostrar_frame("TelaInicial")).pack(pady=20)

        tk.Button(self, text="Sair", 
                  font=("Arial", 10),
                  command=self.voltar_para_login).pack(pady=5)

    def voltar_para_login(self):
        self.controller.logged_in_user = None
        if messagebox.askyesno("Sair", "Tem certeza que deseja sair?"):
            self.controller.mostrar_frame("TelaLogin")
