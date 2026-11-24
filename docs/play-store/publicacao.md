# Publicação Android — CodePath

## Situação

Preparação técnica implementada; publicação de produção **pendente** das decisões,
credenciais e validações abaixo. Um APK de debug não é uma entrega para a Play Store.

## 1. Identidade e assinatura

Defina o identificador definitivo (`ANDROID_APPLICATION_ID`) antes do primeiro envio.
Ele precisa pertencer ao responsável pelo app e não pode usar `com.example.*`.
Depois de publicado, trocar esse identificador cria outro aplicativo.

O namespace interno existente da Activity pode continuar `com.example.codepath`;
o identificador público é configurado separadamente.

Crie uma **chave de upload** no seu ambiente seguro e guarde backup privado:

```sh
keytool -genkeypair -v -keystore upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

O comando solicita senha e dados do titular; não preencha informações inventadas.
Use Play App Signing no Play Console. Guarde a chave e as senhas fora do Git.

Copie `android/key.properties.example` para `android/key.properties`, preenchendo
caminho, alias e senhas. O caminho é relativo à pasta `android`, ou absoluto.
No Windows, use barras `/` em caminhos desse arquivo.

Também é possível configurar:

```text
ANDROID_APPLICATION_ID
ANDROID_KEYSTORE_PATH
ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD
```

## 2. Configuração pública do aplicativo

Copie `config/release.example.json` para `config/release.json` na pasta Flutter.
Preencha com:

- `API_BASE_URL`: origem HTTPS do backend novo, sem path/query/fragmento.
- `PRIVACY_POLICY_URL`: página pública HTTPS com política real e identificação do responsável.
- `ACCOUNT_DELETION_URL`: página pública HTTPS explicando como solicitar exclusão
  sem ter que reinstalar o app. Disponibilize canal/formulário que realmente funcione.
- `SUPPORT_EMAIL`: endereço monitorado pelo responsável.

Não há valores fictícios de privacidade ou suporte embutidos no release.
A validação do Gradle bloqueia os campos ausentes. A existência/resposta HTTP e o
conteúdo real das páginas devem ser conferidos manualmente.

## 3. Gerar o AAB

Em `Frontend/code_path_flutter`, com as variáveis/configurações acima definidas:

```sh
flutter pub get --enforce-lockfile
flutter analyze --no-fatal-infos
flutter test
flutter build appbundle --release --build-number=1 --dart-define-from-file=config/release.json
```

O número `1` é apenas o exemplo de primeiro envio. Use um `versionCode` maior que
todos os números já enviados no Play Console, inclusive em faixas de teste.
A versão visível vem de `pubspec.yaml` ou de `--build-name`.

Saída:

```text
build/app/outputs/bundle/release/app-release.aab
```

O app usa target/compile SDK 36, AGP 8.9.1, Gradle 8.11.1 e NDK 28.2.13676358.
A política consultada em 24/11/2026 exige API 36 para novos apps/atualizações:
https://support.google.com/googleplay/android-developer/answer/11926878?hl=pt-BR

Verifique as bibliotecas nativas a partir da raiz do repositório:

```sh
python tools/check_native_alignment.py Frontend/code_path_flutter/build/app/outputs/bundle/release/app-release.aab
```

Essa inspeção ELF não substitui a instalação dos APKs gerados do AAB com bundletool,
verificação de assinatura, alinhamento ZIP e teste em Android com páginas de 16 KB.
No APK, o build-tools também oferece `zipalign -c -P 16 4 caminho-do.apk`.

## 4. CI

O workflow `Mobile Android` executa testes backend, análise/testes Flutter e build
de APK em push/PR. A geração de AAB é manual via `workflow_dispatch`, com `release`
ativado e `build_number` preenchido. O workflow gera artefato; não publica na loja.

Configure no repositório GitHub:

| Tipo | Nome |
|---|---|
| Variable | `ANDROID_APPLICATION_ID` |
| Variable | `CODEPATH_RELEASE_CONFIG` — JSON público descrito acima |
| Secret | `ANDROID_KEYSTORE_BASE64` — conteúdo do keystore codificado em Base64 |
| Secret | `ANDROID_KEYSTORE_PASSWORD` |
| Secret | `ANDROID_KEY_ALIAS` |
| Secret | `ANDROID_KEY_PASSWORD` |

Nunca envie keystore/senhas no chat, em issues ou como artefato do CI.

## 5. Itens que precisam ser concluídos no Play Console

- Conta de desenvolvedor e verificação de identidade/dispositivo exigidas para ela.
- Nome do titular/desenvolvedor, suporte, país e categoria do aplicativo.
- Política pública e página externa de exclusão, com processos reais de atendimento.
- Declaração de segurança dos dados consistente com o app e os provedores.
- Público-alvo/idades e classificação de conteúdo; avaliar requisitos de Famílias
  se decidir atender crianças. O projeto não define essa decisão por você.
- Declaração de anúncios de acordo com a versão efetivamente publicada.
- Acesso para o reviewer: conta de teste e instruções, pois o conteúdo exige login.
- Ícone de loja 512×512, arte de destaque 1024×500 e screenshots reais das telas.
- Texto curto e descrição completa que não prometam recursos inexistentes.
- Testes internos/fechados e requisitos específicos apresentados à sua conta.
- AAB assinado e relatório de pré-lançamento sem falhas bloqueadoras.

## 6. Roteiro de homologação indispensável

Use um projeto Firestore de homologação, jamais os seeds destrutivos no banco real.

1. Instalar a versão gerada do AAB em Android suportado e Android 16.
2. Cadastrar, entrar, fechar/reabrir e sair; verificar expiração/reset de sessão.
3. Recuperar senha com e-mail real de teste, código expirado e código já usado.
4. Concluir uma lição, sair e conferir persistência do progresso.
5. Jogar batalha com dois usuários; interromper rede ao responder/finalizar e retomar.
6. Confirmar que recompensas não dobram após retry e que o timer não reinicia.
7. Criar convite, sair após responder e retomar na pergunta seguinte.
8. Confirmar o limite semanal sem consumir outra tentativa por simples retry.
9. Excluir uma conta de teste, repetir após resposta perdida e verificar dados associados.
10. Abrir privacidade/suporte, testar fonte ampliada, teclado, botão voltar e telas pequenas.
11. Validar concorrência, índices, IAM, regras de acesso direto e TTL no Firestore.

## Pendências externas desta entrega

Identificador definitivo, chave de upload, URLs e responsável por privacidade,
suporte, implantação da API/índices, screenshots, validação em dispositivos e
configuração da conta Play Console. Sem esses itens, não há AAB de produção validado.
