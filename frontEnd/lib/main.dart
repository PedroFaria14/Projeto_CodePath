import 'package:flutter/material.dart';
import 'package:http/http.dart'
    as http; // Importe para garantir que está disponível
import 'package:codepath/services/api_service.dart'; // Importe o seu ApiService
import 'package:shared_preferences/shared_preferences.dart'; // Para armazenar o token

void main() {
  runApp(const CodePathApp());
}

class CodePathApp extends StatefulWidget {
  const CodePathApp({super.key});

  @override
  State<CodePathApp> createState() => _CodePathAppState();
}

class _CodePathAppState extends State<CodePathApp> {
  String? _authToken; // Armazena o token de autenticação
  String? _userId; // Armazena o ID do utilizador
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAuthToken();
  }

  // Carrega o token de autenticação salvo localmente
  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _authToken = prefs.getString('authToken');
      _userId = prefs.getString('userId');
      _isLoading = false;
    });
  }

  // Salva o token de autenticação localmente
  Future<void> _saveAuthToken(String token, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
    await prefs.setString('userId', userId);
    setState(() {
      _authToken = token;
      _userId = userId;
    });
  }

  // Remove o token de autenticação localmente
  Future<void> _removeAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('userId');
    setState(() {
      _authToken = null;
      _userId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: 'CodePath',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        // Se a fonte 'Inter' não estiver configurada no pubspec.yaml e nos assets,
        // remova esta linha ou adicione a configuração da fonte.
        // Exemplo de configuração no pubspec.yaml:
        // flutter:
        //   fonts:
        //     - family: Inter
        //       fonts:
        //         - asset: fonts/Inter-Regular.ttf
        //         - asset: fonts/Inter-Bold.ttf
        //           weight: 700
        fontFamily: 'Inter',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: _authToken == null
          ? AuthScreen(onLoginSuccess: _saveAuthToken)
          : HomeScreen(
              authToken: _authToken!,
              userId: _userId!,
              onLogout: _removeAuthToken,
            ),
    );
  }
}

// Tela de Autenticação (Login e Registo)
class AuthScreen extends StatefulWidget {
  final Function(String token, String userId) onLoginSuccess;

  const AuthScreen({super.key, required this.onLoginSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _authenticate() async {
    setState(() {
      _isLoading = true;
    });
    try {
      Map<String, dynamic> response;
      if (_isLogin) {
        response = await _apiService.loginUser(
            _emailController.text, _passwordController.text);
        final token = response['access_token'];
        final userId = token.split('-').last; // Extrai o ID do token simulado
        widget.onLoginSuccess(token, userId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  _isLogin ? 'Login bem-sucedido!' : 'Registo bem-sucedido!')),
        );
      } else {
        response = await _apiService.registerUser(
            _emailController.text, _passwordController.text);
        final loginResponse = await _apiService.loginUser(
            _emailController.text, _passwordController.text);
        final token = loginResponse['access_token'];
        final userId = token.split('-').last;
        widget.onLoginSuccess(token, userId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registo e logon bem-sucedidos!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Erro: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isLogin
                    ? 'Bem-vindo de volta ao CodePath!'
                    : 'Junte-se ao CodePath!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Palavra-passe',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _authenticate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                      ),
                      child: Text(
                        _isLogin ? 'Entrar' : 'Registar',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                    ScaffoldMessenger.of(context)
                        .hideCurrentSnackBar(); // Opcional: esconde qualquer SnackBar anterior
                  });
                },
                child: Text(
                  _isLogin
                      ? 'Não tem uma conta? Registe-se!'
                      : 'Já tem uma conta? Faça login!',
                  style: const TextStyle(color: Colors.indigo, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Tela Principal (Home Screen)
class HomeScreen extends StatefulWidget {
  final String authToken;
  final String userId;
  final VoidCallback onLogout;

  const HomeScreen(
      {super.key,
      required this.authToken,
      required this.userId,
      required this.onLogout});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _userData;
  List<dynamic> _lessons = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      _userData = await _apiService.getUserProfile(widget.authToken);
      _lessons = await _apiService.getLessons();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('CodePath')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Erro: $_errorMessage',
                  style: const TextStyle(color: Colors.red, fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchData,
                child: const Text('Tentar Novamente'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: widget.onLogout,
                child: const Text('Sair'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('CodePath'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Olá, ${_userData?['email'] ?? 'Utilizador'}!',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                    'Pontos', '${_userData?['points'] ?? 0} ✨', Colors.indigo),
                _buildStatCard(
                    'Streak', '${_userData?['streak'] ?? 0} 🔥', Colors.green),
                _buildStatCard(
                    'Medalhas',
                    '${(_userData?['medals'] as List?)?.length ?? 0} 🏅',
                    Colors.amber),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              'Trilhas de Aprendizagem',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo),
            ),
            const SizedBox(height: 15),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _lessons.length,
              itemBuilder: (context, index) {
                final lesson = _lessons[index];
                final isCompleted = _userData?['progress'] != null &&
                    _userData!['progress'][lesson['id']] != null &&
                    _userData!['progress'][lesson['id']]['completed'] == true;
                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 3,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    title: Text(
                      '${lesson['title']} ${lesson['character']}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(lesson['description']),
                    trailing: isCompleted
                        ? const Icon(Icons.check_circle,
                            color: Colors.green, size: 30)
                        : const Icon(Icons.arrow_forward_ios,
                            color: Colors.grey, size: 20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LessonScreen(
                            lessonId: lesson['id'],
                            lessonTitle: lesson['title'],
                            lessonContent: lesson['content'],
                            lessonExpectedOutput: lesson['expected_output'],
                            lessonCharacter: lesson['character'],
                            lessonPoints: lesson['points'],
                            lessonMedal: lesson['medal'],
                            authToken: widget.authToken,
                            userId: widget.userId,
                            onLessonCompleted:
                                _fetchData, // Atualiza os dados após completar a lição
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'O seu ID de Utilizador: ${widget.userId}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Tela de Lição
class LessonScreen extends StatefulWidget {
  final String lessonId;
  final String lessonTitle;
  final String lessonContent;
  final String lessonExpectedOutput;
  final String lessonCharacter;
  final int lessonPoints;
  final String lessonMedal;
  final String authToken;
  final String userId;
  final VoidCallback onLessonCompleted;

  const LessonScreen({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
    required this.lessonContent,
    required this.lessonExpectedOutput,
    required this.lessonCharacter,
    required this.lessonPoints,
    required this.lessonMedal,
    required this.authToken,
    required this.userId,
    required this.onLessonCompleted,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _codeController = TextEditingController();
  String _output = '';
  bool _isLoadingHint = false;
  String? _hintMessage;

  Future<void> _runCode() async {
    String simulatedOutput = '';
    bool success = false;

    if (widget.lessonId == 'python-intro') {
      if (_codeController.text.contains('print("Olá, CodePath!")') ||
          _codeController.text.contains("print('Olá, CodePath!')")) {
        simulatedOutput = 'Olá, CodePath!';
        success = true;
      } else {
        simulatedOutput =
            'Tente novamente. Certifique-se de imprimir "Olá, CodePath!" exatamente como está.';
      }
    } else if (widget.lessonId == 'js-variables') {
      // Corrigido: Usando grupo de captura nomeado e verificando a correspondência
      final RegExp regExp = RegExp(
          r'''let\s+nome\s*=\s*(['"])(.*?)\1;\s*console\.log\(nome\);''');

      final RegExpMatch? match = regExp.firstMatch(_codeController.text);

      if (match != null && match.group(2) != null) {
        // group(1) é a aspa, group(2) é o conteúdo
        simulatedOutput = match.group(2)!; // Captura o nome digitado
        success = true;
      } else {
        simulatedOutput =
            'Verifique se declarou a variável `nome` e a imprimiu corretamente.';
      }
    } else if (widget.lessonId == 'loops-python') {
      final lines = _codeController.text
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();
      final loopPattern = RegExp(r'(for|while)\s+.*?:');
      // Corrigido: Usando classe de caracteres para aspas simples ou duplas
      final printPattern = RegExp(r'''print\(['"]Eu amo programar!['"]\)''');

      bool loopFound = false;
      bool printInsideLoop = false;
      int printCount = 0;

      for (final line in lines) {
        if (loopPattern.hasMatch(line)) {
          loopFound = true;
        }
        if (loopFound && printPattern.hasMatch(line)) {
          printInsideLoop = true;
          printCount++;
        }
      }

      if (loopFound && printInsideLoop && printCount >= 3) {
        simulatedOutput =
            'Eu amo programar!\nEu amo programar!\nEu amo programar!';
        success = true;
      } else {
        simulatedOutput =
            'Tente usar um ciclo `for` para imprimir a frase "Eu amo programar!" 3 vezes.';
      }
    }

    setState(() {
      _output = simulatedOutput;
    });

    if (success) {
      try {
        await _apiService.completeLesson(
            widget.userId, widget.lessonId, widget.authToken);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parabéns! Lição concluída! 🎉')),
        );
        widget
            .onLessonCompleted(); // Notifica a tela Home para atualizar os dados
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar progresso: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _getHint() async {
    setState(() {
      _isLoadingHint = true;
      _hintMessage = null;
    });
    try {
      final prompt =
          'O utilizador está na lição "${widget.lessonTitle}" com o seguinte conteúdo: "${widget.lessonContent}". O código atual dele é: ```${_codeController.text}```. Dê uma dica útil e concisa para ajudá-lo a resolver o problema, sem dar a solução completa.';
      final hint = await _apiService.getGeminiHint(prompt);
      setState(() {
        _hintMessage = hint;
      });
    } catch (e) {
      setState(() {
        _hintMessage = 'Erro ao obter dica: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoadingHint = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.lessonTitle} ${widget.lessonCharacter}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.lessonContent,
              style: const TextStyle(fontSize: 18, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            const Text(
              'O seu Código:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _codeController,
                maxLines: null, // Permite múltiplas linhas
                expands: true, // Expande para preencher o Container
                style: const TextStyle(
                    fontFamily: 'monospace', color: Colors.white),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(15),
                  border: InputBorder.none,
                  hintText: 'Escreva o seu código aqui...',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _runCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Executar Código',
                        style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoadingHint ? null : _getHint,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isLoadingHint
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Obter Dica',
                            style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
            if (_hintMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dica:',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _hintMessage!,
                        style: const TextStyle(
                            fontSize: 15, color: Colors.blueGrey),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              'Saída:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _output.isEmpty ? 'Nenhuma saída ainda.' : _output,
                style: const TextStyle(
                    fontFamily: 'monospace', color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
