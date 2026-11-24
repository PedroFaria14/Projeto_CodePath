# CodePath — execução e preparação Android

O CodePath ensina lógica de programação com trilhas, exercícios, batalhas e desafios.
O aplicativo é Flutter; a API é FastAPI e armazena dados no Firestore.

## Estado desta entrega

A base Android foi preparada para release, com API 36, chave de upload própria,
sessões verificáveis, exclusão de conta e pontuação de jogos calculada pelo servidor.
Isso não equivale à publicação: ainda é necessário configurar a identidade do app,
implantar a API atualizada e validar a versão assinada no Play Console.

## Ferramentas

- Flutter **3.38.5** / Dart **3.10.4**, versão usada na validação e no CI.
- Android SDK Platform 36, NDK 28.2.13676358 e JDK 17 ou 21.
- Python 3.11 recomendado para backend; a validação local também foi executada em 3.10.
- Credencial Firestore apenas no servidor; nunca dentro do aplicativo.

## Backend

Execute na pasta `Backend`:

```sh
python -m venv .venv
# Ative a .venv conforme seu sistema operacional.
python -m pip install -r requirements-dev.txt
python -m pytest -q
python -m uvicorn main:app --host 0.0.0.0 --port 8000
```

Para produção, use `requirements-release.txt`. O `requirements.txt` original é
legado e contém versões diferentes; não misture os dois ambientes.

Configure as variáveis descritas em `Backend/.env.example`. O Firestore aceita
`GOOGLE_APPLICATION_CREDENTIALS`, credenciais padrão do ambiente ou o arquivo
`Backend/firebase-service-account.json`, ignorado pelo Git.

Sem credencial válida, os endpoints dependentes do banco ficam indisponíveis.
A IA é opcional: a falta de `GEMINI_API_KEY` não impede toda a API de iniciar.
O envio de recuperação de senha requer Brevo e remetente válidos.

## Aplicativo

Execute em `Frontend/code_path_flutter`:

```sh
flutter pub get --enforce-lockfile
flutter analyze --no-fatal-infos
flutter test
flutter run --dart-define=API_BASE_URL=https://SEU-BACKEND
```

Use um endpoint HTTPS de desenvolvimento/homologação. O aplicativo não aceita
HTTP em claro. No Windows, habilite o Modo de Desenvolvedor quando o Flutter
informar que plugins precisam de suporte a symlinks.

O endereço padrão da API é o antigo servidor Render. **Ele precisa receber o
backend desta entrega**: o aplicativo exige `access_token` no login e usa o novo
contrato de tentativas. Um app novo contra o backend antigo não é compatível.

## Build Android

APK de desenvolvimento, inadequado para publicação:

```sh
flutter build apk --debug
```

Para um AAB de produção, siga [o guia de publicação](docs/play-store/publicacao.md).
O Gradle impede release sem URLs públicas, identificador definitivo e assinatura
de upload. Não existe fallback para chave de debug em release.

## Estrutura útil

| Local | Responsabilidade |
|---|---|
| `Frontend/code_path_flutter/lib/pages/` | Telas e navegação existentes |
| `Frontend/code_path_flutter/lib/core/` | Configuração, rede e armazenamento de sessão |
| `Backend/security.py` | Sessões, autorização, limites de tentativas e respostas públicas |
| `Backend/games.py` | Tentativas, correção e liquidação transacional dos jogos |
| `Backend/pages/account.py` | Logout e exclusão de conta |
| `Backend/tests/` e `Backend/test/` | Testes sem credenciais reais |
| `.github/workflows/mobile.yml` | Testes, APK e geração manual de AAB |
| `tools/check_native_alignment.py` | Inspeção ELF de compatibilidade com páginas de 16 KB |

Mais detalhes de contratos e migração em [documentacao-opencode.md](documentacao-opencode.md).
