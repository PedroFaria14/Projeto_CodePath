import tkinter as tk
from tkinter import messagebox, scrolledtext
import io
import contextlib
import json
import os

# Nome do arquivo JSON que armazenará os usuários
ARQUIVO_USUARIOS = "usuarios.json"

# Funções utilitárias para salvar e carregar usuários
def carregar_usuarios():
    if os.path.exists(ARQUIVO_USUARIOS):
        with open(ARQUIVO_USUARIOS, "r", encoding="utf-8") as f:
            return json.load(f)
    return []

def salvar_usuarios(usuarios):
    with open(ARQUIVO_USUARIOS, "w", encoding="utf-8") as f:
        json.dump(usuarios, f, ensure_ascii=False, indent=4)


class TelaCadastro(tk.Frame):
    def __init__(self, parent, controller):
        super().__init__(parent)
        self.controller = controller

        tk.Label(self, text="Cadastro de Novo Usuário", font=("Arial", 16, "bold")).pack(pady=20)

        self.campos = {}
        for campo in ["Nome", "Email", "Senha"]:
            tk.Label(self, text=campo + ":").pack()
            entry = tk.Entry(self, width=40, show="*" if campo == "Senha" else "")
            entry.pack(pady=4)
            self.campos[campo] = entry

        tk.Button(self, text="Cadastrar", command=self.cadastrar_usuario, bg="#4CAF50", fg="white").pack(pady=15)
        tk.Button(self, text="Voltar", command=lambda: controller.mostrar_frame(TelaLogin)).pack()

    def cadastrar_usuario(self):
        nome = self.campos["Nome"].get().strip()
        email = self.campos["Email"].get().strip()
        senha = self.campos["Senha"].get().strip()

        if not nome or not email or not senha:
            messagebox.showwarning("Campos obrigatórios", "Preencha todos os campos.")
            return

        usuarios = carregar_usuarios()
        if any(u["email"] == email for u in usuarios):
            messagebox.showerror("Erro", "Este email já está cadastrado.")
            return

        usuarios.append({"nome": nome, "email": email, "senha": senha})
        salvar_usuarios(usuarios)

        messagebox.showinfo("Sucesso", "Usuário cadastrado com sucesso!")
        self.controller.mostrar_frame(TelaLogin)


class TelaLogin(tk.Frame):
    def __init__(self, parent, controller):
        super().__init__(parent)
        self.controller = controller

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
                  command=lambda: controller.mostrar_frame(TelaCadastro)).pack(pady=5)

    def verificar_login(self):
        email = self.email_entry.get().strip()
        senha = self.senha_entry.get().strip()

        if not email or not senha:
            messagebox.showwarning("Campos obrigatórios", "Preencha todos os campos.")
            return

        usuarios = carregar_usuarios()
        for u in usuarios:
            if u["email"] == email and u["senha"] == senha:
                messagebox.showinfo("Login bem-sucedido", f"Bem-vindo, {u['nome']}!")
                self.controller.mostrar_frame(TelaInicial)
                return

        messagebox.showerror("Erro", "Email ou senha incorretos.")


# --- Dicionário com o conteúdo das lições ---
licoes = {
    "Laços de Repetição": {
        "animal": "🦜 Papagaio",
        "explicacao": ("O papagaio adora repetir! Na programação, usamos 'laços' (loops) "
                       "para repetir um bloco de código várias vezes. O 'for' é um tipo de laço."),
        "pergunta": "Qual palavra-chave usamos para criar um laço de repetição que repete algo 5 vezes?",
        "opcoes": ["repeat", "if", "for", "def"],
        "resposta_correta": "for"
    },
    "Condicionais": {
        "animal": "🦎 Camaleão",
        "explicacao": ("O camaleão muda de cor com base na situação. 'Condicionais' como 'if' e 'else' "
                       "permitem que seu código tome decisões e mude o que faz com base em uma condição."),
        "pergunta": "Qual palavra-chave verifica se uma condição é verdadeira?",
        "opcoes": ["maybe", "if", "check", "loop"],
        "resposta_correta": "if"
    },
}


class ProgrammingZooApp(tk.Tk):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        self.title("Code Path")
        self.geometry("500x600")

        container = tk.Frame(self)
        container.pack(side="top", fill="both", expand=True)
        container.grid_rowconfigure(0, weight=1)
        container.grid_columnconfigure(0, weight=1)

        self.frames = {}

        for F in (TelaLogin, TelaCadastro, TelaInicial, TelaLicao, TelaTerminal):
            if F == TelaLicao:
                continue
            frame = F(container, self)
            self.frames[F] = frame
            frame.grid(row=0, column=0, sticky="nsew")

        self.mostrar_frame(TelaLogin)

    def mostrar_frame(self, cont, licao_selecionada=None):
        if cont == TelaLicao and licao_selecionada:
            frame = TelaLicao(self.winfo_children()[0], self, licao_selecionada)
            self.frames[TelaLicao] = frame
            frame.grid(row=0, column=0, sticky="nsew")
        frame = self.frames[cont]
        frame.tkraise()


class TelaInicial(tk.Frame):
    def __init__(self, parent, controller):
        super().__init__(parent)
        self.controller = controller

        label = tk.Label(self, text="Escolha sua atividade!", font=("Arial", 20, "bold"))
        label.pack(pady=20, padx=10)

        for nome_licao in licoes:
            animal_emoji = licoes[nome_licao]["animal"].split(" ")[0]
            botao_licao = tk.Button(self,
                                    text=f"{animal_emoji} {nome_licao}",
                                    font=("Arial", 14),
                                    width=25,
                                    command=lambda l=nome_licao: controller.mostrar_frame(TelaLicao, l))
            botao_licao.pack(pady=10)

        label_desafio = tk.Label(self, text="--- Faça Você Mesmo ---", font=("Arial", 12, "italic"))
        label_desafio.pack(pady=(20, 5))

        botao_terminal = tk.Button(self,
                                   text="🐍 Terminal Python",
                                   font=("Arial", 14, "bold"),
                                   width=25,
                                   bg="#306998",
                                   fg="white",
                                   command=lambda: controller.mostrar_frame(TelaTerminal))
        botao_terminal.pack(pady=10)


class TelaLicao(tk.Frame):
    def __init__(self, parent, controller, nome_licao):
        super().__init__(parent)
        self.controller = controller
        self.dados_licao = licoes[nome_licao]

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

        btn_voltar = tk.Button(self, text="Voltar ao Menu", command=lambda: controller.mostrar_frame(TelaInicial))
        btn_voltar.pack(pady=5)

    def verificar_resposta(self):
        selecionada = self.resposta_usuario.get()
        correta = self.dados_licao["resposta_correta"]

        if selecionada == correta:
            messagebox.showinfo("Correto!", "Parabéns, você acertou! 🦜")
        else:
            messagebox.showerror("Incorreto!", f"Ops, não foi dessa vez. A resposta certa é '{correta}'. Tente de novo!")


class TelaTerminal(tk.Frame):
    def __init__(self, parent, controller):
        super().__init__(parent)
        self.controller = controller

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

        btn_voltar = tk.Button(self, text="Voltar ao Menu", command=lambda: controller.mostrar_frame(TelaInicial))
        btn_voltar.pack(pady=5)

    def executar_codigo(self):
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


if __name__ == "__main__":
    app = ProgrammingZooApp()
    app.mainloop()
