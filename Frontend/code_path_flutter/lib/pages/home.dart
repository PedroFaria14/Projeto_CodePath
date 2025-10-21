// Arquivo: PaginaHome.dart (ou main.dart, dependendo do seu projeto)
// ESTE CÓDIGO CORRIGE A QUEBRA DE LINHA NO TÍTULO DA APPBAR DA TRILHAUM

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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

  final List<String> ordemModulos = [
    "Laços de Repetição",
    "Variáveis e Tipos de Dados",
    "Condicionais",
    "Funções",
    "Perguntas diversas",
  ];

  final List<String> desafios = [
    "Laços de Repetição",
    "Variáveis e Tipos de Dados",
    "Condicionais",
    "Funções",
  ];

  // --- Mapas de metadados ---
  final Map<String, String> _cardDisplayNames = {
    "Variáveis e Tipos de Dados": "Variáveis",
    "Laços de Repetição": "Laços",
    "Condicionais": "Condicionais",
    "Funções": "Funções",
    "Perguntas diversas": "Diversas",
  };

  // 🚀 --- INÍCIO DA MODIFICAÇÃO --- 🚀
  // Mapa para os títulos do AppBar (SEM quebra de linha manual)
  final Map<String, String> _appBarTitles = {
    "Variáveis e Tipos de Dados": "Variáveis e Tipos de Dados", // Removido \n
    "Laços de Repetição": "Laços de Repetição", // Removido \n
    "Condicionais": "Condicionais", // Já estava sem \n
    "Funções": "Funções", // Já estava sem \n
    "Perguntas diversas": "Perguntas diversas", // Já estava sem \n
    // Adicione outros mapeamentos se necessário, sem o \n
  };
  // 🚀 --- FIM DA MODIFICAÇÃO --- 🚀

  // Metadados dos módulos (cores, animais, posições)
  final Map<String, Map<String, dynamic>> _moduloMetadata = {
    "Laços de Repetição": {
      "animal": "assets/imagens/Papagaio.png",
      "gradient": [const Color(0xFF4C7516), const Color(0xFF8EDB29)],
      "backgroundAsset": "assets/fundos_trilhas/fundo_papagaio.png",
      "posicoes": [
        const Offset(0.53, 0.33),
        const Offset(0.37, 0.43),
        const Offset(0.46, 0.54),
        const Offset(0.51, 0.68),
        const Offset(0.60, 0.82),
        const Offset(0.34, 0.83),
      ],
    },
    "Condicionais": {
      "animal": "assets/imagens/Esquilo.png",
      "backgroundAsset": "assets/fundos_trilhas/fundo_esquilo.png",
      "posicoes": [
        const Offset(0.53, 0.33),
        const Offset(0.37, 0.43),
        const Offset(0.46, 0.54),
        const Offset(0.51, 0.68),
        const Offset(0.60, 0.82),
        const Offset(0.34, 0.83),
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
        const Offset(0.55, 0.34),
        const Offset(0.39, 0.43),
        const Offset(0.49, 0.54),
        const Offset(0.533, 0.67),
        const Offset(0.63, 0.79),
        const Offset(0.34, 0.85),
      ],
    },
    "Funções": {
      "animal": "assets/imagens/Abelha.png",
      "gradient": [
        const Color(0xFFCD8500),
        const Color(0xFFD9A400),
        const Color(0xFFE6C200),
        const Color(0xFFFFFF00),
      ],
      "stops": [0.07, 0.38, 0.58, 0.87],
      "backgroundAsset": "assets/fundos_trilhas/fundo_abelha.png",
      "posicoes": [
        const Offset(0.55, 0.32),
        const Offset(0.38, 0.42),
        const Offset(0.48, 0.53),
        const Offset(0.53, 0.66),
        const Offset(0.62, 0.78),
        const Offset(0.34, 0.80),
      ],
    },
    "Perguntas diversas": {
      "animal": "assets/imagens/cachorro.png",
      "gradient": [const Color(0xFF616161), const Color(0xFF424242)],
      "backgroundAsset": "assets/fundos_trilhas/fundo_cachorro.png",
      "posicoes": [
        const Offset(0.53, 0.33),
        const Offset(0.37, 0.42),
        const Offset(0.46, 0.54),
        const Offset(0.51, 0.66),
        const Offset(0.60, 0.79),
        const Offset(0.34, 0.83),
      ],
    },
  };

  final Map<String, dynamic> _defaultInfo = {
    "animal": "assets/imagens/gato1.png",
    "gradient": [Colors.grey.shade400, Colors.grey.shade600],
    "posicoes": [const Offset(0.5, 0.5)],
    "backgroundAsset": "assets/fundos_trilhas/default_background.png",
  };

  Map<String, String> get _moduloNameMap {
    return {
      "Laços de Repetição": "Laços de Repetição",
      "Funções": "Funções",
      "Variáveis e Tipos de Dados": "Variáveis e Tipos de Dados",
      "Condicionais": "Condicionais",
      "Perguntas diversas": "Perguntas diversas",
    };
  }

  // --- Métodos (initState, carregarModulos, carregarUsuario, abrirTrilha, _onItemTapped) ---
  @override
  void initState() {
    super.initState();
    carregarModulos();
    carregarUsuario();
  }

  Future<void> carregarModulos() async {
    try {
      // Simulação para debug (remova ou comente para usar a API)
      List<String> modulosCarregados = [
        "Variáveis e Tipos de Dados",
        "Laços de Repetição",
        "Condicionais",
        "Funções",
        "Perguntas diversas",
      ];
      // Ordenação
      modulosCarregados.sort((a, b) {
        int indexA = ordemModulos.indexOf(a);
        int indexB = ordemModulos.indexOf(b);
        if (indexA == -1) indexA = ordemModulos.length;
        if (indexB == -1) indexB = ordemModulos.length;
        return indexA.compareTo(indexB);
      });
      if (mounted)
        setState(() {
          modulos = modulosCarregados;
          carregando = false;
        });
    } catch (e) {
      debugPrint("Erro ao carregar módulos: $e");
      if (mounted) setState(() => carregando = false);
    }
  }

  Future<void> carregarUsuario() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString("userEmail");
      if (email == null || email.isEmpty) {
        return;
      }
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8000/profile/$email"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['user'] is Map<String, dynamic>) {
          if (mounted) {
            setState(() {
              streak = data["user"]["streak"] ?? 0;
              nomeUsuario = data["user"]["nome"] ?? "Usuário";
            });
          }
        } else {
          debugPrint("Formato inesperado da resposta do perfil.");
        }
      } else {
        debugPrint("Erro ao carregar perfil: ${response.body}");
      }
    } catch (e) {
      debugPrint("Erro ao carregar usuário: $e");
    }
  }

  Future<void> abrirTrilha(String tipoModulo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString("userEmail");
      if (email == null) return;

      final String nomeModuloAPI = _moduloNameMap[tipoModulo] ?? tipoModulo;

      final info = _moduloMetadata[tipoModulo] ?? _defaultInfo;
      final backgroundAsset =
          info["backgroundAsset"] as String? ??
          _defaultInfo["backgroundAsset"] as String;
      final posicoes = List<Offset>.from(
        info["posicoes"] ?? _defaultInfo["posicoes"],
      );
      final animalAsset =
          info["animal"] as String? ?? _defaultInfo["animal"] as String;
      final gradientColors =
          info["gradient"] as List<Color>? ??
          _defaultInfo["gradient"] as List<Color>;
      // USA O NOVO _appBarTitles SEM QUEBRA DE LINHA
      final appBarTitle = _appBarTitles[tipoModulo] ?? tipoModulo;

      final response = await http.get(
        Uri.parse("http://10.0.2.2:8000/profile/$email"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = (data != null && data['user'] is Map)
            ? data['user']
            : data;
        if (user == null) {
          debugPrint("Dados do usuário não encontrados.");
          return;
        }

        final fasesData = user["fases"];
        final Map<String, dynamic> fasesMap = Map<String, dynamic>.from(
          fasesData ?? {},
        );
        List<Map<String, dynamic>> fases = List<Map<String, dynamic>>.from(
          fasesMap[nomeModuloAPI] ?? [],
        );

        if (fases.isEmpty) {
          fases = List.generate(
            5,
            (i) => {"id": i + 1, "liberada": i == 0, "atual": i == 0},
          );
          final payload = {
            "email": email,
            "tipo": nomeModuloAPI,
            "fases": fases,
          };
          try {
            final postResponse = await http.post(
              /* ... salvar progresso ... */
              Uri.parse("http://10.0.2.2:8000/salvar_progresso"),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(payload),
            );
            if (postResponse.statusCode != 200)
              debugPrint("Erro: ${postResponse.body}");
          } catch (postError) {
            debugPrint("Erro conexão: $postError");
            return;
          }
        }

        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TrilhaUm(
              tipoModulo: appBarTitle, // Passa o título SEM quebra de linha
              tipoModuloAPI: nomeModuloAPI,
              fases: fases,
              backgroundAsset: backgroundAsset,
              posicoes: posicoes,
              animalAsset: animalAsset,
              gradientColors: gradientColors,
            ),
          ),
        );
        if (mounted) carregarUsuario();
      } else {
        debugPrint("Erro ao carregar fases: ${response.body}");
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao buscar dados.')),
          );
      }
    } catch (e) {
      debugPrint("Erro ao abrir trilha: $e");
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar trilha.')),
        );
    }
  }

  void _onItemTapped(int index) async {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("userEmail");

    if (index == 0) {
      /* Já está na Home */
    } else if (index == 1) {
      // Continuar
      if (modulos.isNotEmpty)
        abrirTrilha(modulos.first);
      else if (!carregando)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma trilha disponível.')),
        );
    } else if (index == 2) {
      // Perfil
      if (email != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PerfilPage()),
        );
        if (mounted) carregarUsuario();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Faça login para acessar o perfil.')),
        );
      }
    }
  }

  // --- build() ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFF5E1),
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        automaticallyImplyLeading: false,
        title: Row(
          /* ... AppBar title content ... */
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                "Olá, $nomeUsuario ",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.orangeAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$streak",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ConfiguracoesPage(),
                      ),
                    );
                    if (mounted) carregarUsuario();
                  },
                ),
              ],
            ),
          ],
        ),
      ),

      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                setState(() => carregando = true);
                await Future.wait([carregarModulos(), carregarUsuario()]);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Trilhas disponíveis",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Lista vertical de Trilhas
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: modulos.length,
                        itemBuilder: (context, index) {
                          /* ... ListTile Builder ... */
                          final modulo = modulos[index];
                          final info = _moduloMetadata[modulo] ?? _defaultInfo;
                          final animalAsset =
                              info["animal"] as String? ??
                              _defaultInfo["animal"] as String;
                          final gradientColors =
                              info["gradient"] as List<Color>? ??
                              _defaultInfo["gradient"] as List<Color>;
                          final cardDisplayName = modulo;

                          return GestureDetector(
                            onTap: () => abrirTrilha(modulo),
                            child: Container(
                              height: 80,
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: gradientColors,
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                    ),
                                    child: Image.asset(
                                      animalAsset,
                                      height: 45,
                                      fit: BoxFit.contain,
                                      errorBuilder: (c, e, s) => const Icon(
                                        Icons.error,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      cardDisplayName,
                                      textAlign: TextAlign.left,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 2.0,
                                            color: Colors.black45,
                                            offset: Offset(1.0, 1.0),
                                          ),
                                        ],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.only(right: 16.0),
                                    child: Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.white70,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // Nova seção "Desafios"
                      const SizedBox(height: 30),
                      const Text(
                        "Desafios",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // GRADE DE DESAFIOS
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.8,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: desafios.length,
                        itemBuilder: (context, index) {
                          /* ... Desafio Card Builder ... */
                          final nomeDesafio = desafios[index];
                          final info =
                              _moduloMetadata[nomeDesafio] ?? _defaultInfo;
                          final gradientColors =
                              info["gradient"] as List<Color>;

                          return GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Desafio em desenvolvimento...",
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 8.0,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: gradientColors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 3,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  "Desafio ${nomeDesafio}",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 15,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 1.0,
                                        color: Colors.black45,
                                        offset: Offset(1.0, 1.0),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

      bottomNavigationBar: BottomNavigationBar(
        /* ... BottomNavigationBar content ... */
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green.shade800,
        unselectedItemColor: Colors.black54,
        backgroundColor: const Color(0xFFE0F8E0),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
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
}
