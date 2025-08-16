import tkinter as tk
import firebase_admin
from firebase_admin import credentials, firestore

# Importa as classes de tela de seus respectivos arquivos
from pages.login import TelaLogin
from pages.register import TelaCadastro
from pages.home import TelaInicial
from pages.lesson import TelaLicao
from pages.tela_terminal import TelaTerminal

class ProgrammingZooApp(tk.Tk):
    """
    Controlador principal da aplicação. Gerencia a navegação entre as telas.
    """
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        self.title("Code Path")
        self.geometry("500x600")

        # Inicializa o Firebase
        try:
            # Tenta carregar a chave de serviço para se conectar ao Firebase
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

        # Instancia todas as telas e as armazena no dicionário 'frames'
        for F in (TelaLogin, TelaCadastro, TelaInicial, TelaTerminal):
            frame = F(container, self)
            self.frames[F.__name__] = frame
            frame.grid(row=0, column=0, sticky="nsew")

        self.mostrar_frame("TelaLogin")

    def mostrar_frame(self, nome_tela, licao_selecionada=None):
        """
        Exibe a tela desejada, escondendo as outras.
        Cria uma nova instância de TelaLicao se uma lição for selecionada.
        """
        if nome_tela == "TelaLicao" and licao_selecionada:
            # Cria uma nova instância de TelaLicao com os dados da lição selecionada
            frame = TelaLicao(self.winfo_children()[0], self, licao_selecionada)
            self.frames[nome_tela] = frame
            frame.grid(row=0, column=0, sticky="nsew")

        frame = self.frames[nome_tela]
        frame.tkraise()
        # Garante que a nova tela receba o foco para que os botões sejam clicáveis
        frame.focus_set()


if __name__ == "__main__":
    app = ProgrammingZooApp()
    app.mainloop()
