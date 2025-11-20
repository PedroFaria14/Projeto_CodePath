// Arquivo: resultado_dialog.dart
// (ATUALIZADO para esconder recompensas na tela de "Aguardando")

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ResultadoFinalDialog extends StatelessWidget {
  final String status;
  final String mensagem; // mensagem do backend (ex: "Placar: 8 a 7")
  final int rankChange;
  final int moedasGanhas;
  final VoidCallback onClose;

  const ResultadoFinalDialog({
    super.key,
    required this.status,
    required this.mensagem,
    required this.rankChange,
    required this.moedasGanhas,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    const Color corAppVerde = Color(0xFF3CB371);

    // Valores que mudam conforme o status
    Color corStatus;
    IconData iconeStatus;
    String titulo;
    String textoPersonalizado;
    bool mostrarRecompensas = true; // 🚀 NOVO: Começa como true

    switch (status.toUpperCase()) {
      case "VITORIA":
      case "VOCÊ VENCEU!":
        titulo = "Você Venceu!";
        textoPersonalizado = " Parabéns, você ganhou!";
        corStatus = corAppVerde;
        iconeStatus = Icons.emoji_events_rounded;
        break;

      case "DERROTA":
      case "VOCÊ PERDEU!":
        titulo = "Você Perdeu!";
        textoPersonalizado = "Que pena! Você perdeu.";
        corStatus = Colors.red.shade700;
        iconeStatus = Icons.close_rounded;
        break;

      case "EMPATE":
      case "EMPATE!":
        titulo = "Empate!";
        textoPersonalizado = " Foi um empate, boa partida!";
        corStatus = corAppVerde;
        iconeStatus = Icons.handshake_rounded;
        break;

      default: // Este é o caso "AGUARDANDO_OPONENTE"
        titulo = "Resultado Salvo!";
        textoPersonalizado = "Aguardando oponente...";
        corStatus = corAppVerde;
        iconeStatus = Icons.hourglass_top_rounded;
        mostrarRecompensas = false; // 🚀 NOVO: Esconde as recompensas aqui
        break;
    }

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        title: Text(
          titulo,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: corStatus,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconeStatus, color: corStatus, size: 70),
            const SizedBox(height: 16),

            // 🔥 MENSAGEM PERSONALIZADA
            Text(
              textoPersonalizado,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: corStatus,
              ),
            ),

            const SizedBox(height: 12),

            // 🔥 MENSAGEM DO BACKEND (placar)
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: const Color(0xFF2E2E2E),
              ),
            ),

            // 🚀 SEÇÃO DE RECOMPENSAS CONDICIONAL 🚀
            // Só mostra a seção inteira (divisor, título, rank, moedas)
            // se 'mostrarRecompensas' for verdadeiro.
            if (mostrarRecompensas)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  const Divider(color: Colors.black12),
                  const SizedBox(height: 10),
                  Text(
                    "Recompensas",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF2E2E2E),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Rank
                  _buildRecompensaRow(
                    icone: Icons.trending_up,
                    texto: "${rankChange >= 0 ? '+' : ''}$rankChange",
                    label: "Pontuação (Rank)",
                    cor: rankChange > 0
                        ? Colors.green.shade700
                        : (rankChange < 0
                              ? Colors.red.shade700
                              : Colors.grey.shade700),
                  ),

                  const SizedBox(height: 10),

                  // Moedas
                  _buildRecompensaRow(
                    icone: Icons.monetization_on,
                    texto: "+$moedasGanhas",
                    label: "Moedas",
                    cor: Colors.orange.shade800,
                  ),
                ],
              ),

            // 🚀 Adiciona um espaço extra se as recompensas estiverem ocultas,
            // para o botão "VOLTAR" não ficar colado na mensagem.
            if (!mostrarRecompensas) const SizedBox(height: 20),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        actions: [
          ElevatedButton(
            onPressed: onClose,
            style: ElevatedButton.styleFrom(
              backgroundColor: corStatus,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              "VOLTAR",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget auxiliar
  Widget _buildRecompensaRow({
    required IconData icone,
    required String texto,
    required String label,
    required Color cor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icone, color: cor, size: 24),
        const SizedBox(width: 8),
        Text(
          "$texto ",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: cor,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 16, color: Color(0xFF2E2E2E)),
        ),
      ],
    );
  }
}
