import tkinter as tk
import firebase_admin
from firebase_admin import credentials, firestore

# Importa as classes de tela de seus respectivos arquivos
from pages.login import TelaLogin
from pages.register import TelaCadastro
from pages.home import TelaInicial
from pages.lesson import TelaLicao
from pages.tela_terminal import TelaTerminal
from pages.profile import TelaPerfil # Importa a TelaPerfil

class ProgrammingZooApp(tk.Tk):
    """
    Controlador principal da aplicação. Gerencia a navegação entre as telas.
    """
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        self.title("Code Path")
        self.geometry("500x600")
        self.logged_in_user = None # Armazena os dados do usuário logado

        # Inicializa o Firebase
        try:
            cred = credentials.Certificate("firebase-service-account.json")
            firebase_admin.initialize_app(cred)
            self.db = firestore.client()
            print("Conexão com Firestore estabelecida com sucesso!")
        except Exception as e:
            print(f"Erro ao inicializar Firebase: {e}")
            self.db = None

        container = tk.Frame(self)
        container.pack(side="top", fill="both", expand=True)
        container.grid_rowconfigure(0, weight=1)
        container.grid_columnconfigure(0, weight=1)

        self.frames = {}

        # Instancia as telas estáticas (sem a TelaPerfil, que é dinâmica)
        for F in (TelaLogin, TelaCadastro, TelaInicial, TelaTerminal):
            frame = F(container, self)
            self.frames[F.__name__] = frame
            frame.grid(row=0, column=0, sticky="nsew")
        
        # A TelaPerfil não é criada aqui porque precisa dos dados do usuário
        # Ela será criada no `mostrar_frame` quando o login for bem-sucedido
        self.frames["TelaPerfil"] = None

        self.mostrar_frame("TelaLogin")

    def mostrar_frame(self, nome_tela, licao_selecionada=None):
        """
        Exibe a tela desejada, escondendo as outras.
        Cria uma nova instância de TelaLicao ou TelaPerfil se necessário.
        """
        # A TelaLicao ainda é criada dinamicamente para carregar o conteúdo correto
        if nome_tela == "TelaLicao" and licao_selecionada:
            frame = TelaLicao(self.winfo_children()[0], self, licao_selecionada)
            self.frames[nome_tela] = frame
            frame.grid(row=0, column=0, sticky="nsew")
        elif nome_tela == "TelaPerfil":
             # Se a TelaPerfil não foi criada, cria ela agora
             if self.frames["TelaPerfil"] is None:
                 frame = TelaPerfil(self.winfo_children()[0], self)
                 self.frames["TelaPerfil"] = frame
                 frame.grid(row=0, column=0, sticky="nsew")
        
        frame = self.frames[nome_tela]
        frame.tkraise()
        frame.focus_set()


if __name__ == "__main__":
    app = ProgrammingZooApp()
    app.mainloop()
