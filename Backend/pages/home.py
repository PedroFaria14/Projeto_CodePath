import tkinter as tk
from data.lessons import licoes

class TelaInicial(tk.Frame):
    def __init__(self, parent, controller):
        super().__init__(parent)
        self.controller = controller

        # Layout da tela inicial
        label = tk.Label(self, text="Escolha sua atividade!", font=("Arial", 20, "bold"))
        label.pack(pady=20, padx=10)

        for nome_licao in licoes:
            animal_emoji = licoes[nome_licao]["animal"].split(" ")[0]
            botao_licao = tk.Button(self,
                                     text=f"{animal_emoji} {nome_licao}",
                                     font=("Arial", 14),
                                     width=25,
                                     command=lambda l=nome_licao: controller.mostrar_frame("TelaLicao", l))
            botao_licao.pack(pady=10)

        label_desafio = tk.Label(self, text="--- Faça Você Mesmo ---", font=("Arial", 12, "italic"))
        label_desafio.pack(pady=(20, 5))

        botao_terminal = tk.Button(self,
                                     text="🐍 Terminal Python",
                                     font=("Arial", 14, "bold"),
                                     width=25,
                                     bg="#306998",
                                     fg="white",
                                     command=lambda: controller.mostrar_frame("TelaTerminal"))
        botao_terminal.pack(pady=10)
