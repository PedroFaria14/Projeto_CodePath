import tkinter as tk
from tkinter import scrolledtext
import io
import contextlib

class TelaTerminal(tk.Frame):
    def __init__(self, parent, controller):
        super().__init__(parent)
        self.controller = controller

        # Layout da tela do terminal
        label_titulo = tk.Label(self, text="🐍 Terminal Python", font=("Courier", 20, "bold"))
        label_titulo.pack(pady=10)

        frame_entrada = tk.Frame(self)
        frame_entrada.pack(pady=10, padx=10, fill="x")

        label_entrada = tk.Label(frame_entrada, text="Seu código:", font=("Courier", 12))
        label_entrada.pack(anchor="w")
        self.campo_codigo = scrolledtext.ScrolledText(frame_entrada, height=10, width=50, wrap=tk.WORD,
                                                     font=("Courier", 11))
        self.campo_codigo.pack(fill="x", expand=True)
        self.campo_codigo.insert(tk.INSERT,
                                 '# Exemplo:\nfor i in range(5):\n    print(f"O papagaio repete a vez {i+1}")\n')

        btn_executar = tk.Button(self, text="▶ Executar Código", font=("Arial", 14, "bold"), bg="#4CAF50", fg="white",
                                  command=self.executar_codigo)
        btn_executar.pack(pady=10)

        label_saida = tk.Label(self, text="Saída:", font=("Courier", 12))
        label_saida.pack(anchor="w", padx=10, pady=(10, 0))
        self.campo_saida = scrolledtext.ScrolledText(self, height=6, width=50, wrap=tk.WORD, state="disabled",
                                                     font=("Courier", 11), bg="#333", fg="#FFF")
        self.campo_saida.pack(pady=10, padx=10, fill="x", expand=True)

        btn_voltar = tk.Button(self, text="Voltar ao Menu", command=lambda: controller.mostrar_frame("TelaInicial"))
        btn_voltar.pack(pady=5)

    def executar_codigo(self):
        """
        Executa o código Python digitado pelo usuário e exibe a saída.
        """
        codigo_usuario = self.campo_codigo.get("1.0", tk.END)

        self.campo_saida.config(state="normal")
        self.campo_saida.delete("1.0", tk.END)

        buffer_saida = io.StringIO()

        try:
            with contextlib.redirect_stdout(buffer_saida):
                exec(codigo_usuario)

            resultado = buffer_saida.getvalue()
            self.campo_saida.insert(tk.INSERT, resultado)

        except Exception as e:
            mensagem_erro = f"Erro no seu código:\n{type(e).__name__}: {e}"
            self.campo_saida.insert(tk.INSERT, mensagem_erro)

        finally:
            self.campo_saida.config(state="disabled")
