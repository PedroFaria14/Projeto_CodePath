import 'package:flutter/material.dart';

class Cadastro extends StatelessWidget {
  const Cadastro({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cadastro")),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB2F7C1), Color(0xFFDFF5E1)],
          ),
        ),

        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Image.asset("assets/imagens/gato.png", height: 150, width: 150),
                const SizedBox(height: 30),
                const Text(
                  "Crie sua conta",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 30),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Nome",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Telefone",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                TextField(
                  decoration: InputDecoration(
                    labelText: "NickName",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Senha",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  child: const Text("Cadastrar"),
                ),

                const SizedBox(height: 30),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Já tem uma conta? Entrar"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
