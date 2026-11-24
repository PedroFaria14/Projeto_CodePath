// Arquivo: PaginaHome.dart (COMPLETO E ATUALIZADO)
// - Placar de líderes
// - Desafio Semanal
// - Batalha (Ninho do Corvo)
// - 🚀 RADAR DE NOTIFICAÇÕES AUTOMÁTICO

import 'dart:async'; // Importante para o Timer
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:codepath/core/api_http.dart' as http;
import 'package:codepath/core/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:codepath/providers/user_provider.dart';

// Imports dos arquivos locais
import 'trilhaUm.dart';
import 'perfil.dart';
import 'tela_configuracao.dart';
import 'amigos_page.dart';
import 'batalha_page.dart';
import 'resultado_dialog.dart';
import 'convites_page.dart';
import 'leaderboard_page.dart';
import 'desafio_page.dart';

class PaginaHome extends StatefulWidget {
  const PaginaHome({super.key});

  @override
  State<PaginaHome> createState() => _PaginaHomeState();
}

class _PaginaHomeState extends State<PaginaHome> {
  List<String> modulos = [];
  bool carregandoModulos = true;
  int _selectedIndex = 0;

  late PageController _pageController;
  double _currentPage = 0.0;

  String _userEmail = "";
  int _totalConvites = 0;
  final String _baseUrl = AppConfig.apiBaseUrl;

  bool _isUserDataLoading = false;
  Timer? _notificacaoTimer; // 🚀 O Radar!
  bool _polling = false;

  // --- (Mapas de Metadados) ---
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
        const Offset(0.53, 0.33),
        const Offset(0.37, 0.42),
        const Offset(0.46, 0.54),
        const Offset(0.51, 0.66),
        const Offset(0.60, 0.79),
        const Offset(0.34, 0.83),
      ],
    },
    "Condicionais": {
      "animal": "assets/imagens/Esquilo.png",
      "backgroundAsset": "assets/fundos_trilhas/fundo_esquilo.png",
      "posicoes": [
        const Offset(0.53, 0.33),
        const Offset(0.37, 0.42),
        const Offset(0.46, 0.54),
        const Offset(0.51, 0.67),
        const Offset(0.60, 0.79),
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
        const Offset(0.55, 0.33),
        const Offset(0.399, 0.43),
        const Offset(0.489, 0.55),
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
        const Color(0xFFFFCC00),
      ],
      "stops": [0.07, 0.38, 0.58, 0.87],
      "backgroundAsset": "assets/fundos_trilhas/fundo_abelha.png",
      "posicoes": [
        const Offset(0.55, 0.32),
        const Offset(0.389, 0.41),
        const Offset(0.48, 0.53),
        const Offset(0.53, 0.66),
        const Offset(0.62, 0.78),
        const Offset(0.34, 0.83),
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

  Map<String, String> get _moduloNameMap {
    return {
      "Laços de Repetição": "Laços de Repetição",
      "Funções": "Funções",
      "Variáveis e Tipos de Dados": "Variáveis e Tipos de Dados",
      "Condicionais": "Condicionais",
      "Perguntas diversas": "Perguntas diversas",
    };
  }

  // --- (initState, dispose) ---
  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _pageController.addListener(() {
      if (mounted) {
        setState(() {
          _currentPage = _pageController.page ?? 0.0;
        });
      }
    });

    carregarModulos();

    // 🚀 RADAR: Inicia o timer para checar notificações a cada 10 segundos
    _notificacaoTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      // Só checa se tiver email e estiver na tela
      if (_userEmail.isNotEmpty && mounted && !_polling &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed &&
          ModalRoute.of(context)?.isCurrent == true) {
        _polling = true;
        try {
          await _checarNotificacoes();
          if (mounted) await _carregarContagemConvites(_userEmail);
        } finally {
          _polling = false;
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isUserDataLoading) {
      _isUserDataLoading = true;
      carregarUsuarioEContadores();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _notificacaoTimer?.cancel(); // 🚀 Cancela o radar ao sair
    super.dispose();
  }

  // --- (Funções de Carregamento) ---
  Future<void> carregarModulos() async {
    List<String> modulosDaApi = [];
    try {
      final response = await http.get(Uri.parse("$_baseUrl/modulos"));
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
    if (mounted) {
      setState(() {
        modulos = modulosFinais;
        carregandoModulos = false;
      });
    }
  }

  Future<void> carregarUsuarioEContadores() async {
    if (!mounted) return;
    setState(() {
      _totalConvites = 0;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString("userEmail");
      _userEmail = email ?? "";
      if (!mounted) return;

      if (_userEmail.isEmpty) {
        if (mounted) {
          Provider.of<UserProvider>(context, listen: false).stopLoading();
        }
        return;
      }

      await Provider.of<UserProvider>(
        context,
        listen: false,
      ).loadUserData(_userEmail);

      if (mounted) {
        _checarNotificacoes();
        _carregarContagemConvites(_userEmail);
      }
    } catch (e) {
      debugPrint("Erro ao carregar usuário na PaginaHome: $e");
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).stopLoading();
      }
    }
  }

  // --- (Função abrirTrilha) ---
  Future<void> abrirTrilha(String tipoModulo) async {
    if (carregandoModulos) return;

    setState(() {
      carregandoModulos = true;
    });

    String? email;
    List<Map<String, dynamic>> fasesParaTrilha = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      email = prefs.getString("userEmail");
      if (email == null || email.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Erro: Usuário não logado."),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => carregandoModulos = false);
        }
        return;
      }
      final String nomeModuloAPI = _moduloNameMap[tipoModulo] ?? tipoModulo;
      final info = _moduloMetadata[tipoModulo] ?? _defaultInfo;
      final String backgroundAsset = info["backgroundAsset"] as String;
      final List<Offset> posicoes = List<Offset>.from(info["posicoes"]);
      final animalAsset = info["animal"] as String;
      final List<Color> gradientColors = info["gradient"] as List<Color>;
      final appBarTitle = _appBarTitles[tipoModulo] ?? tipoModulo;

      final response = await http.get(Uri.parse("$_baseUrl/profile/$email"));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data["user"] ?? data;
        final dynamic fasesData = user["fases"];
        Map<String, dynamic> fasesMap;
        if (fasesData is Map) {
          fasesMap = Map<String, dynamic>.from(fasesData);
        } else {
          fasesMap = {};
        }
        fasesParaTrilha = List<Map<String, dynamic>>.from(
          fasesMap[nomeModuloAPI] ?? [],
        );
        if (fasesParaTrilha.isEmpty) {
          fasesParaTrilha = List.generate(
            5,
            (i) => {"id": i + 1, "liberada": i == 0, "atual": i == 0},
          );
        }

        setState(() => carregandoModulos = false);

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TrilhaUm(
              tipoModulo: appBarTitle,
              tipoModuloAPI: nomeModuloAPI,
              fases: fasesParaTrilha,
              backgroundAsset: backgroundAsset,
              posicoes: posicoes,
              animalAsset: animalAsset,
              gradientColors: gradientColors,
            ),
          ),
        );

        if (mounted) {
          setState(() => carregandoModulos = true);
          await carregarUsuarioEContadores();
          await carregarModulos();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Erro ${response.statusCode} ao carregar dados da trilha.",
              ),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => carregandoModulos = false);
        }
      }
    } catch (e, stacktrace) {
      print("PaginaHome: EXCEÇÃO GERAL em abrirTrilha: $e");
      print(stacktrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erro inesperado ao abrir trilha."),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => carregandoModulos = false);
      }
    } finally {
      if (mounted && carregandoModulos) {
        setState(() => carregandoModulos = false);
      }
    }
  }

  // --- (Lógica de Batalha) ---
  Future<void> _iniciarBatalha() async {
    if (!mounted) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final emailJogador = _userEmail;
    final nivelJogador = userProvider.nivel;

    if (emailJogador.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Você precisa estar logado para batalhar!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    _showModoBatalhaPopup(context, emailJogador, nivelJogador);
  }

  void _showModoBatalhaPopup(
    BuildContext context,
    String emailJogador,
    String nivelJogador,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Ninho do Corvo",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text("Como você quer desafiar?"),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.only(
            bottom: 20,
            left: 20,
            right: 20,
          ),
          actions: [
            Column(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.public, color: Colors.white),
                  label: const Text(
                    "Batalha Aleatória",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _navegarParaBatalhaAleatoria(emailJogador, nivelJogador);
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.people, color: Colors.white),
                  label: const Text(
                    "Desafiar Amigo",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _navegarParaAmigos(context);
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _navegarParaBatalhaAleatoria(String email, String nivel) async {
    setState(() => carregandoModulos = true);

    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/batalha/iniciar"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "nivel": nivel}),
      );
      if (!mounted) return;
      setState(() => carregandoModulos = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> perguntas = data['perguntas'] ?? [];
        final List<Map<String, dynamic>> listaPerguntas =
            List<Map<String, dynamic>>.from(perguntas);

        if (listaPerguntas.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Nenhuma pergunta de batalha encontrada para seu nível.",
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BatalhaPage(
              perguntas: listaPerguntas,
              tipoBatalha: "ALEATORIA",
              idBatalhaOponente: data['id_batalha_oponente'],
              pontuacaoOponente: data['pontuacao_oponente'] != null
                  ? (data['pontuacao_oponente'] as num).toInt()
                  : null,
              idConvite: null,
            ),
          ),
        ).then((_) => carregarUsuarioEContadores()); // Recarrega ao voltar
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Erro ao iniciar batalha: ${data['detail'] ?? response.body}",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => carregandoModulos = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro de conexão: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navegarParaAmigos(BuildContext context) {
    print("Navegando para a Central de Amigos...");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AmigosPage()),
    ).then((_) => carregarUsuarioEContadores()); // Recarrega ao voltar
  }

  // --- (Funções de Notificação - ATUALIZADA PARA AUTOMÁTICO) ---
  Future<void> _carregarContagemConvites(String email) async {
    int total = 0;
    try {
      final resAmigos = await http.get(
        Uri.parse("$_baseUrl/amigos/pedidos_pendentes/$email"),
      );
      if (mounted && resAmigos.statusCode == 200) {
        final data = jsonDecode(resAmigos.body);
        total += (data["pedidos"] as List).length;
      }
      final resBatalha = await http.get(
        Uri.parse("$_baseUrl/convite/pendentes/$email"),
      );
      if (mounted && resBatalha.statusCode == 200) {
        final data = jsonDecode(resBatalha.body);
        total += (data["convites"] as List).length;
      }
      if (mounted) {
        setState(() {
          _totalConvites = total;
        });
      }
    } catch (e) {
      print("Erro ao carregar contagem de convites: $e");
      if (mounted)
        setState(() {
          _totalConvites = 0;
        });
    }
  }

  Future<void> _checarNotificacoes() async {
    if (_userEmail.isEmpty) return;
    if (!mounted) return;

    // Verifica se já tem algum dialog aberto para não sobrepor
    // (Truque simples: se o modalRoute não for o atual, talvez tenha um dialog)
    // Mas para simplicidade, vamos confiar que o showDialog bloqueia a tela.

    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/notificacoes/pendentes/$_userEmail"),
      );

      if (!mounted || response.statusCode != 200 || ModalRoute.of(context)?.isCurrent != true) return;

      final data = jsonDecode(response.body) as List;
      final List<Map<String, dynamic>> notificacoes = List.from(data);

      if (notificacoes.isEmpty) {
        return;
      }

      // Pega a primeira notificação pendente e mostra
      // Depois de mostrar, marcamos como lida para não repetir

      final notif = notificacoes.first;
      final String titulo = notif['titulo'] ?? "RESULTADO";

      // Define se é Vitoria/Derrota para o estilo
      String statusParaDialog = "VITORIA"; // Default verde
      if (titulo.toUpperCase().contains("PERDEU")) statusParaDialog = "DERROTA";
      if (titulo.toUpperCase().contains("EMPATE")) statusParaDialog = "EMPATE";

      final String mensagem = notif['mensagem'] ?? "Batalha finalizada";
      final int rankChange = (notif['rank_change'] as num? ?? 0).toInt();
      final int moedasGanhas = (notif['moedas_ganhas'] as num? ?? 0).toInt();
      final String notificacaoId = notif['id'];

      // Marca como lida ANTES de abrir o dialog para evitar loop se o timer rodar de novo
      await _marcarNotificacaoComoLida(notificacaoId);

      // Atualiza provider local
      if (mounted) {
        await context.read<UserProvider>().loadUserData(_userEmail);
        if (!mounted) return;
      }

      if (!mounted) return;

      // Mostra o Popup
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => ResultadoFinalDialog(
          status: statusParaDialog,
          mensagem: mensagem,
          rankChange: rankChange,
          moedasGanhas: moedasGanhas,
          onClose: () {
            Navigator.pop(ctx);
            // Ao fechar, recarrega dados do usuário
            carregarUsuarioEContadores();
          },
        ),
      );
    } catch (e) {
      print("Erro ao checar notificações: $e");
    }
  }

  Future<void> _marcarNotificacaoComoLida(String notificacaoId) async {
    try {
      await http.post(
        Uri.parse("$_baseUrl/notificacoes/marcar_como_lido"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"notificacao_id": notificacaoId}),
      );
      print("Notificação $notificacaoId marcada como lida.");
    } catch (e) {
      print("Erro ao marcar notificação como lida: $e");
    }
  }

  // --- (Função _onItemTapped - ATUALIZADA) ---
  void _onItemTapped(int index) async {
    if (index == _selectedIndex && index == 0) return;

    if (index == 0) {
      setState(() => _selectedIndex = 0);
      return;
    }

    if (index == 1) {
      setState(() => _selectedIndex = 1);
      if (modulos.isNotEmpty) {
        final moduloIndex = _currentPage.round().clamp(0, modulos.length - 1);
        await abrirTrilha(modulos[moduloIndex]);
      }
      if (mounted) {
        setState(() => _selectedIndex = 0);
      }
      return;
    }

    if (index == 2) {
      setState(() => _selectedIndex = 2);
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString("userEmail");

      if (email != null) {
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PerfilPage()),
        );
        await carregarUsuarioEContadores();
      }
      if (mounted) {
        setState(() => _selectedIndex = 0);
      }
      return;
    }

    if (index == 3) {
      setState(() => _selectedIndex = 3);

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LeaderboardPage()),
      );
      if (mounted) {
        setState(() => _selectedIndex = 0);
      }
      return;
    }
  }

  // --- (Build) ---
  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    bool isLoading =
        carregandoModulos || (userProvider.isLoading && modulos.isEmpty);

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
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
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
                            Expanded(
                              child: Text(
                                "Olá, ${userProvider.nome}",
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

                            // === Row de Ícones (COM MOEDAS) ===
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // (Moedas)
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
                                        Icons.monetization_on,
                                        color: Colors.amber,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${userProvider.moedas}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // (Streak)
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
                                        "${userProvider.streak}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // (Ícone de Notificações)
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.mail_outline,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ConvitesPage(),
                                          ),
                                        ).then(
                                          (_) => carregarUsuarioEContadores(),
                                        );
                                      },
                                    ),
                                    if (_totalConvites > 0)
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          child: Text(
                                            '$_totalConvites',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),

                                // (Configurações)
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
                                    _carregarContagemConvites(_userEmail);
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

                  // --- (Resto do build - PageView, Batalha, etc.) ---
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
                                        scale: scale.clamp(0.8, 1.0),
                                        child: GestureDetector(
                                          onTap: () => abrirTrilha(modulo),
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

                      // ==========================================
                      // 🚀 CARD DO DESAFIO SEMANAL
                      // ==========================================
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DesafioPage(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(15),
                          child: Container(
                            height: 80,
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 247, 129, 241), // Rosa
                                  Color.fromARGB(255, 36, 165, 167), // Ciano
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
                                  Icons.emoji_events, // Ícone de Troféu
                                  color: Colors.amber,
                                  size: 32,
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        "Prove seu valor!", // Novo subtítulo
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  // Seta no lugar do cadeado
                                  Icons.arrow_forward_ios,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ==========================================
                      // 🚀 CARD DA ARENA (NINHO DO CORVO)
                      // ==========================================
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: InkWell(
                          onTap: _iniciarBatalha,
                          borderRadius: BorderRadius.circular(15),
                          child: Stack(
                            // 1. Usamos o Stack para sobrepor a imagem
                            clipBehavior:
                                Clip.none, // Permite a imagem sair do card
                            children: [
                              // 2. Este é o card original, agora dentro do Stack
                              Container(
                                height: 80,
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  // 3. Novo gradiente "sombrio"
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF4A4A4A), // Cinza Chumbo
                                      Color(0xFF2B2B2B), // Quase Preto
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // 4. Ícone de "inteligência"
                                    const Icon(
                                      Icons.psychology_outlined,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          // 5. Novo Título
                                          Text(
                                            "Ninho do Corvo",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          // 6. Novo Subtítulo
                                          Text(
                                            "Teste sua astúcia na arena.",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.white70,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),

                              // 7. A IMAGEM DO CORVO
                              Positioned(
                                top: 0, // Ajuste aqui (para cima/baixo)
                                right: 15, // Ajuste aqui (esquerda/direita)
                                child: Image.asset(
                                  'assets/imagens/Corvo.png', // <-- CONFIRME SE O CAMINHO ESTÁ CORRETO
                                  height: 70, // Ajuste o tamanho do corvo
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // ==========================================
                      // 🚀 FIM DA ATUALIZAÇÃO DO CARD
                      // ==========================================
                    ],
                  ),
                ],
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_fill, size: 36),
            label: 'Continuar',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            label: 'Placar',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: _startColor,
        unselectedItemColor: Colors.grey[600],
        onTap: _onItemTapped,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
