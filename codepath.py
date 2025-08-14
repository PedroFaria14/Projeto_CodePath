import tkinter as tk
from tkinter import messagebox, scrolledtext
import io
import contextlib
import mysql.connector

# Conexão com o banco de dados
def conectar_banco():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="Marijuka90901.",
        database="sistema_aprendizado"
    )

class TelaCadastro(tk.Frame):
    def __init__(self, parent, controller):
        super().__init__(parent)
        self.controller = controller

        tk.Label(self, text="Cadastro de Novo Aluno", font=("Arial", 16, "bold")).pack(pady=20)

        self.campos = {}

        for campo in ["Nome", "Email", "CPF", "Data de Nascimento (AAAA-MM-DD)"]:
            tk.Label(self, text=campo + ":").pack()
            entry = tk.Entry(self, width=40)
            entry.pack(pady=4)
            self.campos[campo] = entry

        tk.Button(self, text="Cadastrar", command=self.cadastrar_aluno, bg="#4CAF50", fg="white").pack(pady=15)
        tk.Button(self, text="Voltar", command=lambda: controller.mostrar_frame(TelaLogin)).pack()

    def cadastrar_aluno(self):
        nome = self.campos["Nome"].get().strip()
        email = self.campos["Email"].get().strip()
        cpf = self.campos["CPF"].get().strip()
        data_nascimento = self.campos["Data de Nascimento (AAAA-MM-DD)"].get().strip()

        if not nome or not email or not cpf or not data_nascimento:
            messagebox.showwarning("Campos obrigatórios", "Preencha todos os campos.")
            return

        try:
            conexao = conectar_banco()
            cursor = conexao.cursor()

            cursor.execute("""
                INSERT INTO alunos (nome, email, cpf, data_nascimento)
                VALUES (%s, %s, %s, %s)
            """, (nome, email, cpf, data_nascimento))

            conexao.commit()
            cursor.close()
            conexao.close()

            messagebox.showinfo("Sucesso", "Aluno cadastrado com sucesso!")
            self.controller.mostrar_frame(TelaLogin)

        except mysql.connector.IntegrityError:
            messagebox.showerror("Erro", "Email ou CPF já cadastrados.")
        except mysql.connector.Error as err:
            messagebox.showerror("Erro", f"Erro ao salvar no banco: {err}")

class TelaLogin(tk.Frame):
    def __init__(self, parent, controller):
        super().__init__(parent)
        self.controller = controller

        tk.Label(self, text="Login do Aluno", font=("Arial", 18, "bold")).pack(pady=20)

        tk.Label(self, text="Email:").pack()
        self.email_entry = tk.Entry(self, width=40)
        self.email_entry.pack(pady=5)

        tk.Label(self, text="CPF (apenas números):").pack()
        self.cpf_entry = tk.Entry(self, width=40)
        self.cpf_entry.pack(pady=5)

        tk.Button(self, text="Entrar", font=("Arial", 12, "bold"), bg="#4CAF50", fg="white",
                  command=self.verificar_login).pack(pady=15)
        tk.Button(self, text="Cadastrar novo aluno", font=("Arial", 10),
                  command=lambda: controller.mostrar_frame(TelaCadastro)).pack(pady=5)


    def verificar_login(self):
        # (aqui fica seu código de verificação do banco)
        ...

    def verificar_login(self):
        email = self.email_entry.get().strip()
        cpf = self.cpf_entry.get().strip()

        if not email or not cpf:
            messagebox.showwarning("Campos obrigatórios", "Preencha todos os campos.")
            return

        try:
            conexao = conectar_banco()
            cursor = conexao.cursor(dictionary=True)

            cursor.execute("SELECT * FROM alunos WHERE email = %s AND cpf = %s", (email, cpf))
            resultado = cursor.fetchone()

            if resultado:
                messagebox.showinfo("Login bem-sucedido", f"Bem-vindo, {resultado['nome']}!")
                self.controller.mostrar_frame(TelaInicial)
            else:
                messagebox.showerror("Login falhou", "Email ou CPF incorretos.")

            cursor.close()
            conexao.close()

        except mysql.connector.Error as err:
            messagebox.showerror("Erro", f"Erro ao conectar com o banco: {err}")


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
    """
    Classe principal da aplicação. Controla a janela e a troca de telas (frames).
    """
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        self.title("Code Path")
        self.geometry("500x600") # Aumentei um pouco a janela para o terminal

        container = tk.Frame(self)
        container.pack(side="top", fill="both", expand=True)
        container.grid_rowconfigure(0, weight=1)
        container.grid_columnconfigure(0, weight=1)

        self.frames = {}

        # Adiciona a nova tela do terminal à lista de frames
        for F in (TelaLogin, TelaCadastro, TelaInicial, TelaLicao, TelaTerminal):

            if F == TelaLicao: continue
            
            frame = F(container, self)
            self.frames[F] = frame
            frame.grid(row=0, column=0, sticky="nsew")

        self.mostrar_frame(TelaLogin)

    def mostrar_frame(self, cont, licao_selecionada=None):
        """
        Função para exibir uma tela (frame) com base na classe passada.
        """
        if cont == TelaLicao and licao_selecionada:
            frame = TelaLicao(self.winfo_children()[0], self, licao_selecionada)
            self.frames[TelaLicao] = frame
            frame.grid(row=0, column=0, sticky="nsew")
        
        frame = self.frames[cont]
        frame.tkraise()


class TelaInicial(tk.Frame):
    """
    Tela de Menu com os botões para cada lição e para o terminal.
    """
    def __init__(self, parent, controller):
        super().__init__(parent)
        self.controller = controller

        label = tk.Label(self, text="Escolha sua atividade!", font=("Arial", 20, "bold"))
        label.pack(pady=20, padx=10)

        # Cria um botão para cada lição
        for nome_licao in licoes:
            animal_emoji = licoes[nome_licao]["animal"].split(" ")[0]
            
            botao_licao = tk.Button(self,
                text=f"{animal_emoji} {nome_licao}",
                font=("Arial", 14),
                width=25,
                command=lambda l=nome_licao: controller.mostrar_frame(TelaLicao, l)
            )
            botao_licao.pack(pady=10)
            
        # --- NOVO BOTÃO PARA O TERMINAL ---
        label_desafio = tk.Label(self, text="--- Faça Você Mesmo ---", font=("Arial", 12, "italic"))
        label_desafio.pack(pady=(20, 5))
        
        botao_terminal = tk.Button(self,
            text="🐍 Terminal Python",
            font=("Arial", 14, "bold"),
            width=25,
            bg="#306998",
            fg="white",
            command=lambda: controller.mostrar_frame(TelaTerminal)
        )
        botao_terminal.pack(pady=10)


class TelaLicao(tk.Frame):
    """
    Tela onde a lição é apresentada. (Sem alterações)
    """
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
            
        btn_verificar = tk.Button(self, text="Verificar", font=("Arial", 14, "bold"), bg="#4CAF50", fg="white", command=self.verificar_resposta)
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


# --- NOVA CLASSE PARA A TELA DO TERMINAL ---
class TelaTerminal(tk.Frame):
    """
    Tela com um ambiente para o usuário escrever e executar código Python.
    """
    def __init__(self, parent, controller):
        super().__init__(parent)
        self.controller = controller

        # Título da tela
        label_titulo = tk.Label(self, text="🐍 Terminal Python", font=("Courier", 20, "bold"))
        label_titulo.pack(pady=10)

        # Frame para organizar a entrada e o botão
        frame_entrada = tk.Frame(self)
        frame_entrada.pack(pady=10, padx=10, fill="x")

        # Área de texto para o usuário digitar o código
        label_entrada = tk.Label(frame_entrada, text="Seu código:", font=("Courier", 12))
        label_entrada.pack(anchor="w")
        self.campo_codigo = scrolledtext.ScrolledText(frame_entrada, height=10, width=50, wrap=tk.WORD, font=("Courier", 11))
        self.campo_codigo.pack(fill="x", expand=True)
        
        # Inserir um código de exemplo para guiar o usuário
        self.campo_codigo.insert(tk.INSERT, '# Exemplo:\nfor i in range(5):\n    print(f"O papagaio repete a vez {i+1}")\n')

        # Botão para executar o código
        btn_executar = tk.Button(self, text="▶ Executar Código", font=("Arial", 14, "bold"), bg="#4CAF50", fg="white", command=self.executar_codigo)
        btn_executar.pack(pady=10)

        # Área de texto para mostrar a saída do código
        label_saida = tk.Label(self, text="Saída:", font=("Courier", 12))
        label_saida.pack(anchor="w", padx=10, pady=(10, 0))
        self.campo_saida = scrolledtext.ScrolledText(self, height=6, width=50, wrap=tk.WORD, state="disabled", font=("Courier", 11), bg="#333", fg="#FFF")
        self.campo_saida.pack(pady=10, padx=10, fill="x", expand=True)

        # Botão para voltar ao menu
        btn_voltar = tk.Button(self, text="Voltar ao Menu", command=lambda: controller.mostrar_frame(TelaInicial))
        btn_voltar.pack(pady=5)

    def executar_codigo(self):
        """
        Pega o texto do campo de código, executa e redireciona a saída.
        """
        codigo_usuario = self.campo_codigo.get("1.0", tk.END)
        
        # Limpa a saída anterior
        self.campo_saida.config(state="normal")
        self.campo_saida.delete("1.0", tk.END)
        
        # Cria um "buffer" de texto para capturar a saída
        buffer_saida = io.StringIO()
        
        try:
            # Redireciona a saída padrão (stdout) para o nosso buffer
            with contextlib.redirect_stdout(buffer_saida):
                # Executa o código do usuário 
                exec(codigo_usuario)
            
            # Pega o que foi capturado no buffer
            resultado = buffer_saida.getvalue()
            self.campo_saida.insert(tk.INSERT, resultado)

        except Exception as e:
            # Se der um erro, mostra o erro na saída
            mensagem_erro = f"Erro no seu código:\n{type(e).__name__}: {e}"
            self.campo_saida.insert(tk.INSERT, mensagem_erro)
            
        finally:
            # Trava o campo de saída novamente para que o usuário não possa digitar nele
            self.campo_saida.config(state="disabled")


# --- Ponto de entrada da aplicação ---
if __name__ == "__main__":
    app = ProgrammingZooApp()
    app.mainloop()