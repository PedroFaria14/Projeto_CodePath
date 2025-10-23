// ⚠️ CORREÇÃO: Sintaxe correta dos imports de pacotes.

import 'dart:convert';
import 'package:flutter/material.dart'; // CORREÇÃO
import 'package:http/http.dart' as http; // CORREÇÃO
import 'package:shared_preferences/shared_preferences.dart';

// Imports dos arquivos locais
import 'trilhaUm.dart';
import 'perfil.dart';
import 'tela_configuracao.dart';

class PaginaHome extends StatefulWidget {
  const PaginaHome({super.key});

  @override
  State<PaginaHome> createState() => _PaginaHomeState();
}

class _PaginaHomeState extends State<PaginaHome> {
  List<String> modulos = [];
  bool carregando = true;
  int streak = 0;
  String nomeUsuario = "Usuário";
  int _selectedIndex = 0;

  late PageController _pageController;

  double _currentPage = 0.0;

  final Map<String, String> _cardDisplayNames = {
    "Variáveis e Tipos de Dados": "Variáveis",
    "Laços de Repetição": "Laços",
    "Condicionais": "Condicionais",
    "Funções": "Funções",
    "Perguntas diversas": "Diversos",
  };

  final Map<String, String> _appBarTitles = {
    "Variáveis e Tipos de Dados": "Variáveis e\nTipos de Dados",
    "Laços de Repetição": "Laços de\nRepetição",
    "Condicionais": "Condicionais",
    "Funções": "Funções",
    "Perguntas diversas": "Perguntas\nDiversas",
  };

  final Map<String, Map<String, dynamic>> _moduloMetadata = {
    "Laços de Repetição": {
      "animal": "assets/imagens/Papagaio.png",
      "gradient": [const Color(0xFF4C7516), const Color(0xFF8EDB29)],
      "backgroundAsset": "assets/fundos_trilhas/fundo_papagaio.png",
      "posicoes": [
        const Offset(0.53, 0.33), // 1º
        const Offset(0.37, 0.42), // 2º
        const Offset(0.46, 0.54), // 3º
        const Offset(0.51, 0.68), // 4º
        const Offset(0.60, 0.82), // 5º
        const Offset(0.34, 0.83), // 6º
      ],
    },
    "Condicionais": {
      "animal": "assets/imagens/Esquilo.png",
      "backgroundAsset": "assets/fundos_trilhas/fundo_esquilo.png",
      "posicoes": [
        const Offset(0.53, 0.33), // 1º
        const Offset(0.37, 0.42), // 2º
        const Offset(0.46, 0.54), // 3º
        const Offset(0.51, 0.70), // 4º
        const Offset(0.60, 0.80), // 5º
        const Offset(0.34, 0.83), // 6º
      ],
      "gradient": [const Color(0xFF8D6E63), const Color(0xFFA1887F)],
    },
    "Variáveis e Tipos de Dados": {
      "animal": "assets/imagens/canguru.png",
      "gradient": [
        const Color(0xFF744C00),
        const Color(0xFFA16800),
        const Color(0xFFCD8500),
        const Color(0xFFB77700),
      ],
      "stops": [0.0, 0.29, 0.46, 0.86],
      "backgroundAsset": "assets/fundos_trilhas/fundo_canguru.png",
      "posicoes": [
        const Offset(0.55, 0.33), // 1º
        const Offset(0.399, 0.43), // 2º
        const Offset(0.489, 0.55), // 3º
        const Offset(0.533, 0.67), // 4º
        const Offset(0.63, 0.79), // 5º
        const Offset(0.34, 0.85), // 6º
      ],
    },
    "Funções": {
      "animal": "assets/imagens/Abelha.png",
      "gradient": [
        const Color(0xFFCD8500),
        const Color(0xFFD9A400),
        const Color(0xFFE6C200),
        const Color(0xFFFFCC00),
      ],
      "stops": [0.07, 0.38, 0.58, 0.87],
      "backgroundAsset": "assets/fundos_trilhas/fundo_abelha.png",
      "posicoes": [
        const Offset(0.55, 0.32), // 1º
        const Offset(0.389, 0.41), // 2º
        const Offset(0.48, 0.53), // 3º
        const Offset(0.53, 0.66), // 4º
        const Offset(0.62, 0.78), // 5º
        const Offset(0.34, 0.83), // 6º
      ],
    },
    "Perguntas diversas": {
      "animal": "assets/imagens/cachorro.png",
      "gradient": [const Color(0xFF616161), const Color(0xFF424242)],
      "backgroundAsset": "assets/fundos_trilhas/fundo_cachorro.png",
      "posicoes": [
        const Offset(0.53, 0.33), // 1º
        const Offset(0.37, 0.42), // 2º
        const Offset(0.46, 0.54), // 3º
        const Offset(0.51, 0.66), // 4º
        const Offset(0.60, 0.79), // 5º
        const Offset(0.34, 0.83), // 6º
      ],
    },
  };

  final Map<String, dynamic> _defaultInfo = {
    "animal": "assets/imagens/gato1.png",
    "gradient": [Colors.grey.shade600, Colors.grey.shade800],
    "backgroundAsset": "assets/fundos_trilhas/fundo_padrao.png",
    "posicoes": [
      const Offset(0.5, 0.3),
      const Offset(0.5, 0.5),
      const Offset(0.5, 0.7),
    ],
  };

  Color get _startColor {
    if (modulos.isEmpty) return _defaultInfo["gradient"][0];
    final startModuloIndex = _currentPage.floor();
    final endModuloIndex = (_currentPage + 1).floor().clamp(
      0,
      modulos.length - 1,
    );

    final startModulo = modulos[startModuloIndex];
    final startInfo = _moduloMetadata[startModulo] ?? _defaultInfo;
    final startColor = startInfo["gradient"][0] as Color;

    if (startModuloIndex == endModuloIndex) return startColor;

    final endModulo = modulos[endModuloIndex];
    final endInfo = _moduloMetadata[endModulo] ?? _defaultInfo;
    final endColor = endInfo["gradient"][0] as Color;

    final t = _currentPage - startModuloIndex;
    return Color.lerp(startColor, endColor, t) ?? startColor;
  }

  Color get _endColor {
    if (modulos.isEmpty) return _defaultInfo["gradient"].last;
    final startModuloIndex = _currentPage.floor();
    final endModuloIndex = (_currentPage + 1).floor().clamp(
      0,
      modulos.length - 1,
    );

    final startModulo = modulos[startModuloIndex];
    final startInfo = _moduloMetadata[startModulo] ?? _defaultInfo;
    final startColor = startInfo["gradient"].last as Color;

    if (startModuloIndex == endModuloIndex) return startColor;

    final endModulo = modulos[endModuloIndex];
    final endInfo = _moduloMetadata[endModulo] ?? _defaultInfo;
    final endColor = endInfo["gradient"].last as Color;

    final t = _currentPage - startModuloIndex;
    return Color.lerp(startColor, endColor, t) ?? startColor;
  }

  Map<String, String> get _moduloNameMap {
    return {
      "Laços de Repetição": "Laços de Repetição",
      "Funções": "Funções",
      "Variáveis e Tipos de Dados": "Variáveis e Tipos de Dados",
      "Condicionais": "Condicionais",
      "Perguntas diversas": "Perguntas diversas",
    };
  }

  @override
  void initState() {
    super.initState();

    _pageController = PageController(viewportFraction: 0.85);
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
    });

    carregarModulos();
    carregarUsuario();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> carregarModulos() async {
    List<String> modulosDaApi = [];
    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8000/modulos"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        modulosDaApi = List<String>.from(data["modulos"] ?? []);
      } else {
        debugPrint("Erro ao buscar módulos da API: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Erro de rede ao carregar módulos: $e");
    }

    List<String> modulosFinais;

    if (modulosDaApi.isNotEmpty &&
        modulosDaApi.length >= _moduloMetadata.length) {
      modulosFinais = modulosDaApi;
    } else {
      modulosFinais = _moduloMetadata.keys.toList();
      debugPrint(
        "Usando a lista de módulos local: ${modulosFinais.length} itens.",
      );
    }

    setState(() {
      modulos = modulosFinais;
      carregando = false;
    });
  }

  Future<void> carregarUsuario() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString("userEmail");

      if (email == null || email.isEmpty) {
        setState(() {
          nomeUsuario = "Usuário"; // Garante o padrão se não houver login
          streak = 0;
        });
        return;
      }

      int maxTentativas = 3; // Vamos tentar buscar 3 vezes
      int delayEmMs = 500; // Esperar meio segundo entre as tentativas

      for (int i = 0; i < maxTentativas; i++) {
        // Tenta buscar o perfil
        final response = await http.get(
          Uri.parse("http://10.0.2.2:8000/profile/$email"),
        );

        if (response.statusCode == 200) {
          // 🚀 SUCESSO! Encontrou o perfil.
          final data = jsonDecode(response.body);

          setState(() {
            streak = data["user"]["streak"] ?? 0;

            String nomeCompleto = data["user"]["nome"] ?? "Usuário";

            // Se o nome for o e-mail, extraímos a primeira parte
            if (nomeCompleto.contains('@') && nomeCompleto == email) {
              String nomeDoEmail = nomeCompleto.split('@')[0];

              if (nomeDoEmail.isNotEmpty) {
                // Capitaliza a primeira letra para exibir como "Pedro"
                nomeCompleto =
                    nomeDoEmail[0].toUpperCase() + nomeDoEmail.substring(1);
              }
            }
            nomeUsuario = nomeCompleto;
          });

          return; // Para a função aqui, pois deu certo.
        } else if (response.statusCode == 404) {
          // ⚠️ FALHA (404): Perfil não encontrado.
          debugPrint(
            "Tentativa ${i + 1} de $maxTentativas: Perfil $email não encontrado (404).",
          );

          if (i == maxTentativas - 1) {
            // Se foi a última tentativa, desiste e assume "Usuário"
            debugPrint("Desistindo de buscar perfil. Assumindo 'Usuário'.");
            setState(() {
              nomeUsuario = "Usuário";
              streak = 0;
            });
          } else {
            // Se não foi a última, espera um pouco e o loop tentará de novo.
            await Future.delayed(Duration(milliseconds: delayEmMs));
          }
        } else {
          // Outro erro (500, 401, etc.)
          debugPrint(
            "Erro ao carregar perfil (Status ${response.statusCode}): ${response.body}",
          );
          setState(() {
            nomeUsuario = "Usuário";
            streak = 0;
          });
          return; // Desiste em outros erros.
        }
      }
    } catch (e) {
      debugPrint("Erro de rede ao carregar usuário: $e");
      // Se der erro de conexão, assume "Usuário"
      if (mounted) {
        setState(() {
          nomeUsuario = "Usuário";
          streak = 0;
        });
      }
    }
  }

  // 🚀 CORREÇÃO: Adicionado feedback de erro (SnackBar) para falhas de API/Login
  Future<void> abrirTrilha(String tipoModulo) async {
    // Verifica se o widget ainda está na tela antes de mostrar SnackBar/Navegar
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString("userEmail");

      if (email == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erro: Usuário não encontrado. Faça login."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final String nomeModuloAPI = _moduloNameMap[tipoModulo] ?? tipoModulo;

      final info = _moduloMetadata[tipoModulo] ?? _defaultInfo;

      final String backgroundAsset = info["backgroundAsset"] as String;
      final List<Offset> posicoes = List<Offset>.from(info["posicoes"]);

      final animalAsset = info["animal"] as String;
      final List<Color> gradientColors = info["gradient"] as List<Color>;
      final appBarTitle = _appBarTitles[tipoModulo] ?? tipoModulo;

      final response = await http.get(
        Uri.parse("http://10.0.2.2:8000/profile/$email"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data["user"] ?? data;

        // 🚀 INÍCIO DA CORREÇÃO
        // 1. Pegue o campo 'fases', que pode ser Map, List ou null
        final dynamic fasesData = user["fases"];
        Map<String, dynamic> fasesMap; // 2. Declare o Mapa que vamos usar

        // 3. Verifique o tipo de 'fasesData'
        if (fasesData is Map) {
          // Se for um Mapa (usuário antigo), converta-o
          fasesMap = Map<String, dynamic>.from(fasesData);
        } else {
          // Se for uma Lista (usuário novo) ou null,
          // apenas crie um Mapa vazio.
          fasesMap = {};
        }
        // 🚀 FIM DA CORREÇÃO

        // 4. Agora o resto do seu código funciona, pois 'fasesMap' É um mapa.
        List<Map<String, dynamic>> fases = List<Map<String, dynamic>>.from(
          fasesMap[nomeModuloAPI] ?? [],
        );

        // Inicializa as fases se for a primeira vez
        if (fases.isEmpty) {
          fases = List.generate(
            5,
            (i) => {
              "id": i + 1,
              "liberada": i == 0 ? true : false,
              "atual": i == 0 ? true : false,
            },
          );
          final payload = {
            "email": email,
            "tipo": nomeModuloAPI,
            "fases": fases,
          };
          await http.post(
            Uri.parse("http://10.0.2.2:8000/salvar_progresso"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(payload),
          );
        }

        // Só navega se o 'context' ainda for válido
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TrilhaUm(
              tipoModulo: appBarTitle,
              tipoModuloAPI: nomeModuloAPI,
              fases: fases,
              backgroundAsset: backgroundAsset,
              posicoes: posicoes,
              animalAsset: animalAsset,
              gradientColors: gradientColors,
            ),
          ),
        );
        carregarUsuario(); // Recarrega o usuário ao voltar da trilha
      } else {
        debugPrint("Erro ao carregar fases do usuário: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao carregar dados: ${response.statusCode}"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint("Erro ao abrir trilha: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erro de conexão. Verifique o servidor."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onItemTapped(int index) async {
    setState(() => _selectedIndex = index);

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("userEmail");

    if (index == 0) {
      // Permanece na home
    } else if (index == 1) {
      // Botão Continuar
      if (modulos.isNotEmpty) {
        final moduloIndex = _currentPage.round().clamp(0, modulos.length - 1);
        abrirTrilha(modulos[moduloIndex]);
      }
    } else if (index == 2) {
      // Botão Perfil
      if (email != null) {
        // Verifica se o 'context' é válido antes de navegar
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PerfilPage()),
        );
        carregarUsuario(); // Recarrega o usuário ao voltar do perfil
      }
      // Voltando para a Home visualmente
      setState(() => _selectedIndex = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_startColor.withOpacity(0.9), Colors.white],
          ),
        ),
        child: carregando
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            // Usa ListView para permitir rolagem e resolver overflows
            : ListView(
                padding: EdgeInsets.zero,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 16,
                      left: 20,
                      right: 20,
                      bottom: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Envolve o Text em Expanded para corrigir overflow lateral
                            Expanded(
                              child: Text(
                                "Olá, $nomeUsuario",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black38,
                                      blurRadius: 2.0,
                                      offset: Offset(1, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            Row(
                              children: [
                                // Streak
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white54),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.local_fire_department,
                                        color: Colors.orangeAccent,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "$streak",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Configurações
                                IconButton(
                                  icon: const Icon(
                                    Icons.settings,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ConfiguracoesPage(),
                                      ),
                                    );
                                    carregarUsuario();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Selecione sua trilha de aprendizado",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Column(
                    children: [
                      SizedBox(
                        height: 320,
                        child: modulos.isEmpty
                            ? const Center(
                                child: Text(
                                  "Nenhum módulo encontrado.",
                                  style: TextStyle(color: Colors.white70),
                                ),
                              )
                            : PageView.builder(
                                controller: _pageController,
                                itemCount: modulos.length,
                                itemBuilder: (context, index) {
                                  final modulo = modulos[index];
                                  final info =
                                      _moduloMetadata[modulo] ?? _defaultInfo;
                                  final List<Color> gradientColors =
                                      info["gradient"] as List<Color>;
                                  final animalAsset = info["animal"] as String;
                                  final cardDisplayName =
                                      _cardDisplayNames[modulo] ?? modulo;

                                  double scale = 1.0;
                                  if (_pageController.position.haveDimensions) {
                                    scale = (_pageController.page! - index)
                                        .abs();
                                    scale = 1.0 - (scale * 0.2);
                                  }

                                  return AnimatedBuilder(
                                    animation: _pageController,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: scale.clamp(
                                          0.8,
                                          1.0,
                                        ), // Limita a escala
                                        child: GestureDetector(
                                          onTap: () => abrirTrilha(modulo),
                                          // 🚀 CORREÇÃO DO CLIQUE:
                                          behavior: HitTestBehavior.opaque,
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: gradientColors,
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                stops: info["stops"] != null
                                                    ? List<double>.from(
                                                        info["stops"],
                                                      )
                                                    : null,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.black38,
                                                  blurRadius: 10,
                                                  offset: Offset(0, 5),
                                                ),
                                              ],
                                            ),
                                            child: Stack(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                    20.0,
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        cardDisplayName,
                                                        style: const TextStyle(
                                                          fontSize: 30,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          color: Colors.white,
                                                          shadows: [
                                                            Shadow(
                                                              color: Colors
                                                                  .black45,
                                                              blurRadius: 4.0,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      const Text(
                                                        "Aprenda os conceitos básicos de programação.",
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          color: Colors.white70,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                Positioned(
                                                  bottom: -20,
                                                  right: -20,
                                                  child: Image.asset(
                                                    animalAsset,
                                                    height: 180,
                                                    fit: BoxFit.contain,
                                                  ),
                                                ),

                                                Positioned(
                                                  bottom: 20,
                                                  left: 20,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 18,
                                                          vertical: 8,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            30,
                                                          ),
                                                      boxShadow: const [
                                                        BoxShadow(
                                                          color: Colors.black26,
                                                          blurRadius: 4,
                                                        ),
                                                      ],
                                                    ),
                                                    child: Row(
                                                      children: const [
                                                        Icon(
                                                          Icons
                                                              .play_arrow_rounded,
                                                          color: Colors.green,
                                                          size: 28,
                                                        ),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          "INICIAR",
                                                          style: TextStyle(
                                                            color: Colors.green,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                      ),

                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(modulos.length, (index) {
                          double normalizedPage = _currentPage.clamp(
                            0.0,
                            modulos.length - 1.0,
                          );
                          double distance = (normalizedPage - index).abs();
                          double size =
                              (10 + (10 * (1 - distance.clamp(0.0, 1.0))));

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            height: 8.0,
                            width: size.clamp(8, 18),
                            decoration: BoxDecoration(
                              color: distance < 0.5
                                  ? Colors.white
                                  : Colors.white54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 20),

                      // Card "Desafios Semanais"
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Container(
                          height: 80,
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color.fromARGB(255, 247, 129, 241),
                                Color.fromARGB(255, 36, 165, 167),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.emoji_events,
                                color: Colors.amber,
                                size: 32,
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text(
                                      "Desafios Semanais",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      "Em breve",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade500.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.lock,
                                      color: Colors.grey.shade300,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Adiciona um espaço no final da lista
                      const SizedBox(height: 20),
                    ],
                  ),
                ],
              ),
      ),

      // 🚀 CORREÇÃO: Adicionando o BottomNavigationBar que estava faltando
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_fill, size: 36), // Ícone "Continuar"
            label: 'Continuar',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        // Usa a cor do gradiente atual para o ícone selecionado
        selectedItemColor: _startColor,
        unselectedItemColor: Colors.grey[600],
        onTap: _onItemTapped, // Sua função de navegação
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
