import tkinter as tk
from tkinter import messagebox
from data.lessons import licoes
class TelaLicao(tk.Frame):
    def __init__(self, parent, controller, nome_licao):
        super().__init__(parent)
        self.controller = controller
        self.dados_licao = licoes[nome_licao]

        # Layout da tela da lição
        label_animal = tk.Label(self, text=self.dados_licao["animal"], font=("Arial", 24, "bold"))
        label_animal.pack(pady=10)

        label_explicacao = tk.Label(self, text=self.dados_licao["explicacao"], wraplength=350, justify="center")
        label_explicacao.pack(pady=10, padx=20)

        label_pergunta = tk.Label(self, text=self.dados_licao["pergunta"], font=("Arial", 12, "italic"), wraplength=350)
        label_pergunta.pack(pady=20)

        self.resposta_usuario = tk.StringVar()

        for opcao in self.dados_licao["opcoes"]:
            rb = tk.Radiobutton(self, text=opcao, variable=self.resposta_usuario, value=opcao, font=("Arial", 12))
            rb.pack(anchor="w", padx=50)

        btn_verificar = tk.Button(self, text="Verificar", font=("Arial", 14, "bold"), bg="#4CAF50", fg="white",
                                   command=self.verificar_resposta)
        btn_verificar.pack(pady=20)

        btn_voltar = tk.Button(self, text="Voltar ao Menu", command=lambda: controller.mostrar_frame("TelaInicial"))
        btn_voltar.pack(pady=5)

    def verificar_resposta(self):
        """
        Verifica se a resposta selecionada está correta e exibe um feedback.
        """
        selecionada = self.resposta_usuario.get()
        correta = self.dados_licao["resposta_correta"]

        if selecionada == correta:
            messagebox.showinfo("Correto!", "Parabéns, você acertou! 🦜")
        else:
            messagebox.showerror("Incorreto!", f"Ops, não foi dessa vez. A resposta certa é '{correta}'. Tente de novo!")
