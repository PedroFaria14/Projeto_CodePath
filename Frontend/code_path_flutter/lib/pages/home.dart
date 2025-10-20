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


  final Map<String, String> _cardDisplayNames = {
    "Variáveis e Tipos de Dados": "Variáveis",
    "Laços de Repetição": "Laços",
    // Adicione outros se precisar
  };
  
  // 🚀 NOVO: Mapa para os títulos do AppBar (com quebra de linha)
  final Map<String, String> _appBarTitles = {
    "Variáveis e Tipos de Dados": "Variáveis e\nTipos de Dados",
    "Laços de Repetição": "Laços de\nRepetição",
    // Adicione outros se precisar
  };

  // 🚀 MUDANÇA: Agora usamos "gradient" com uma LISTA de cores
  final Map<String, Map<String, dynamic>> _moduloMetadata = {
    "Laços de Repetição": {
      "animal": "assets/imagens/Papagaio.png",
      // Degradê da sua paleta (Verde escuro -> Verde limão)
     "gradient": [const Color(0xFF4C7516), const Color(0xFF8EDB29)],
     "backgroundAsset": "assets/fundos_trilhas/fundo_papagaio.png",
     "posicoes": [
        const Offset(0.53, 0.30), // 1º
        const Offset(0.37, 0.41), // 2º
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
        const Offset(0.53, 0.30), // 1º
        const Offset(0.37, 0.41), // 2º
        const Offset(0.46, 0.54), // 3º
        const Offset(0.51, 0.68), // 4º
        const Offset(0.60, 0.82), // 5º
        const Offset(0.34, 0.83), // 6º
      ],

"gradient": [const Color(0xFF8D6E63), const Color(0xFFA1887F)],    },
    "Variáveis e Tipos de Dados": {
      "animal": "assets/imagens/canguru.png",
      // Degradê da sua paleta (Ocre -> Dourado vibrante)
      "gradient": [
        const Color(0xFF744C00),
        const Color(0xFFA16800),
        const Color(0xFFCD8500),
        const Color(0xFFB77700)
      ],
      "stops": [0.0, 0.29, 0.46, 0.86],
      "backgroundAsset": "assets/fundos_trilhas/fundo_canguru.png",
      "posicoes": [
        const Offset(0.55, 0.30), // 1º
        const Offset(0.39, 0.42), // 2º
        const Offset(0.48, 0.55), // 3º
        const Offset(0.533, 0.69), // 4º
        const Offset(0.63, 0.85), // 5º
        const Offset(0.34, 0.85), // 6º
      ],

    },
    "Funções": {
      "animal": "assets/imagens/Abelha.png",
      // Degradê da sua paleta (Amarelo Ouro -> Amarelo vibrante)
      "gradient": [
        const Color(0xFFCD8500),
        const Color(0xFFD9A400),
        const Color(0xFFE6C200),
        const Color(0xFFFFFF00)
      ],
      // Lista de 'stops' (porcentagens / 100)
      "stops": [0.07, 0.38, 0.58, 0.87],
      "backgroundAsset": "assets/fundos_trilhas/fundo_abelha.png",
      "posicoes": [
        const Offset(0.55, 0.28), // 1º
        const Offset(0.38, 0.40), // 2º
        const Offset(0.48, 0.53), // 3º
        const Offset(0.53, 0.67), // 4º
        const Offset(0.62, 0.81), // 5º
        const Offset(0.34, 0.83), // 6º
      ],

    },
    "Perguntas diversas": {
      "animal": "assets/imagens/cachorro.png",
    "gradient": [const Color(0xFF616161), const Color(0xFF424242)],
    "backgroundAsset": "assets/fundos_trilhas/fundo_cachorro.png",
    "posicoes": [
        const Offset(0.53, 0.30), // 1º
        const Offset(0.37, 0.41), // 2º
        const Offset(0.46, 0.54), // 3º
        const Offset(0.51, 0.68), // 4º
        const Offset(0.60, 0.82), // 5º
        const Offset(0.34, 0.83), // 6º
      ],
    },
  };

  // Fallback também usa degradê
  final Map<String, dynamic> _defaultInfo = {
    "animal": "assets/imagens/gato1.png",
    "gradient": [Colors.green.shade300, Colors.green.shade500],
    "posicoes": [ const Offset(0.5, 0.5) ],
  };

  // O resto dos seus métodos (initState, carregarModulos, etc.) 
  // continua igual.
  
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
    carregarModulos();
    carregarUsuario();
  }

  Future<void> carregarModulos() async {
    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8000/modulos"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          modulos = List<String>.from(data["modulos"]);
          carregando = false;
        });
      } else {
        debugPrint("Erro ao buscar módulos: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Erro ao carregar módulos: $e");
    }
  }

  Future<void> carregarUsuario() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString("userEmail");
      if (email == null || email.isEmpty) return;
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8000/profile/$email"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          streak = data["user"]["streak"] ?? 0;
          nomeUsuario = data["user"]["nome"] ?? "Usuário";
        });
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

      // 1. 🚀 DEFININDO O 'backgroundAsset'
      // Precisamos buscar a imagem de fundo aqui
      final info = _moduloMetadata[tipoModulo] ?? _defaultInfo;
      final backgroundAsset = info["backgroundAsset"] as String;
      final posicoes = List<Offset>.from(info["posicoes"]);

      final animalAsset = info["animal"] as String;
      final gradientColors = info["gradient"] as List<Color>;
      final appBarTitle = _appBarTitles[tipoModulo] ?? tipoModulo;
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8000/profile/$email"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data["user"] ?? data;
        final fasesData = user["fases"];
        final Map<String, dynamic> fasesMap =
            Map<String, dynamic>.from(fasesData ?? {});
        
        // 2. 🚀 DEFININDO 'fases'
        // Esta é a sua variável 'fases' local. Está correta.
        List<Map<String, dynamic>> fases =
            List<Map<String, dynamic>>.from(fasesMap[nomeModuloAPI] ?? []);
        
        if (fases.isEmpty) {
          fases = List.generate( // Aqui ela é re-atribuída, o que também está correto
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
            "fases": fases
          };
          await http.post(
            Uri.parse("http://10.0.2.2:8000/salvar_progresso"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(payload),
          );
        }
        
        await Navigator.push(
          context,
          MaterialPageRoute(
            // 3. 🚀 USANDO AS VARIÁVEIS
            // Garantindo que 'fases' e 'backgroundAsset' estão sendo passadas
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
        carregarUsuario();
      } else {
        debugPrint("Erro ao carregar fases do usuário: ${response.body}");
      }
    } catch (e) {
      debugPrint("Erro ao abrir trilha: $e");
    }
  }

  void _onItemTapped(int index) async {
    setState(() => _selectedIndex = index);
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("userEmail");
    if (index == 0) {
    } else if (index == 1) {
      if (modulos.isNotEmpty) {
        abrirTrilha(modulos.first);
      }
    } else if (index == 2) {
      if (email != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PerfilPage()),
        );
        carregarUsuario();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFF5E1),
      appBar: AppBar(
        // ... seu AppBar (sem mudanças)
        backgroundColor: Colors.green.shade700,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Olá, $nomeUsuario ",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Row(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.orangeAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "$streak",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ConfiguracoesPage(),
                      ),
                    );
                    carregarUsuario();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Trilhas disponíveis",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        // 🚀 MUDANÇA: Mudei o aspect ratio para ficar mais "retangular"
                        // Ajuste esse valor se achar melhor (ex: 1.8 ou 2.0)
                        childAspectRatio: 1.6, 
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: modulos.length,
                      itemBuilder: (context, index) {
                        final modulo = modulos[index];
                        final info = _moduloMetadata[modulo] ?? _defaultInfo;
                        final backgroundAsset = info["backgroundAsset"] as String;
                        final posicoes = List<Offset>.from(info["posicoes"]);

                        final animalAsset = info["animal"] as String;
                        final gradientColors = info["gradient"] as List<Color>;
                        final cardDisplayName = _cardDisplayNames[modulo] ?? modulo;
                        return GestureDetector(
                          onTap: () => abrirTrilha(modulo),
                          child: Container(
                            decoration: BoxDecoration(
                              // 🚀 MUDANÇA 1: GRADIENTE HORIZONTAL
                              gradient: LinearGradient(
                                colors: gradientColors,
                                begin: Alignment.centerLeft, // Começa na esquerda
                                end: Alignment.centerRight, // Termina na direita
                                // (Opcional) Adicione 'stops' se quiser que uma cor
                                // ocupe mais espaço, como na imagem do canguru.
                                // Ex: stops: [0.4, 1.0]
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
                            
                            // 🚀 MUDANÇA 2: LAYOUT EM ROW (Linha)
                            child: Row(
                              children: [
                                // 1. Animal na Esquerda
                                Padding(
                                  padding: const EdgeInsets.only(left: 12.0),
                                  child: Image.asset(
                                    animalAsset,
                                    height: 50, // Ajuste a altura
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                
                                const SizedBox(width: 10), // Espaçador

                              
                                Expanded(
                                  child: Text(
                                    cardDisplayName,
                                    textAlign: TextAlign.left,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      // 🚀 MUDANÇA 3: COR DO TEXTO
                                      color: Colors.white,
                                      // (Opcional) Sombra no texto
                                      shadows: [
                                        Shadow(
                                          blurRadius: 2.0,
                                          color: Colors.black45,
                                          offset: Offset(1.0, 1.0),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Padding final à direita
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        // ... seu BottomNavigationBar (sem mudanças)
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green.shade800,
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
}