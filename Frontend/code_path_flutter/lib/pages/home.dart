import 'package:flutter/material.dart';

import 'trilhaUm.dart';

class PaginaHome extends StatefulWidget {
  const PaginaHome({super.key});

  @override
  State<PaginaHome> createState() => _PaginaHomeState();
}

class _PaginaHomeState extends State<PaginaHome> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ModuloPage(),
        ), // continuar trilha
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ModuloPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF90EE90),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [Color(0xFFE0F8E0), Color(0xFFB2F7C1), Color(0xFF90EE90)],
            stops: [0.2, 0.6, 1.0],
          ),
        ),

        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CABEÇALHO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Olá, dev! 👋",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C2C54),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.black87),
                        onPressed: () {},
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // CARD DE PROGRESSO
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C54),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Progresso Atual",
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: 0.45,
                          color: Colors.greenAccent,
                          backgroundColor: Colors.white24,
                          minHeight: 10,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Nível 2 • Explorador da Lógica 🧠",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // SEÇÃO DE TRILHAS
                  const Text(
                    "Trilhas disponíveis",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2C54),
                    ),
                  ),
                  const SizedBox(height: 15),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      trilhaCard(
                        "Python do Zero 🐍",
                        Colors.orangeAccent,
                        0.75,
                      ),
                      trilhaCard(
                        "Lógica e Algoritmos 💡",
                        Colors.blueAccent,
                        0.4,
                      ),
                      trilhaCard(
                        "Programação Java ☕",
                        Colors.purpleAccent,
                        0.1,
                      ),
                      trilhaCard("Flutter Mobile 📱", Colors.teal, 0.3),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // SEÇÃO RECOMENDADOS
                  const Text(
                    "Recomendados para você",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2C54),
                    ),
                  ),
                  const SizedBox(height: 10),

                  recomendacaoCard(
                    "Desafios de Lógica",
                    "Aprimore seu raciocínio!",
                    Icons.extension,
                  ),
                  recomendacaoCard(
                    "Quiz do Dia",
                    "Testes rápidos de programação",
                    Icons.quiz,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // BARRA INFERIOR
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF2C2C54),
        unselectedItemColor: Colors.black54,
        backgroundColor: const Color(0xFFE0F8E0),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Início"),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_arrow_rounded),
            label: "Continuar",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }

  Widget trilhaCard(String nome, Color cor, double progresso) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: cor.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cor.withOpacity(0.4),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nome,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            LinearProgressIndicator(
              value: progresso,
              backgroundColor: Colors.white24,
              color: Colors.white,
              minHeight: 6,
            ),
          ],
        ),
      ),
    );
  }

  Widget recomendacaoCard(String titulo, String subtitulo, IconData icone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C54),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icone, color: Colors.white),
        title: Text(
          titulo,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitulo,
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white,
          size: 18,
        ),
        onTap: () {},
      ),
    );
  }
}
