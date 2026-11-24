# Evidências locais — preparação Android

Data: 24/11/2026.

## Executado

| Verificação | Resultado |
|---|---|
| Backend `python -m pytest -q -p no:cacheprovider` | 30 testes aprovados |
| Flutter `flutter test --no-pub` | 10 testes aprovados |
| Análise Flutter com `--no-fatal-infos` | Sem erros/warnings; há avisos informativos legados |
| Build Android `flutter build apk --debug --no-pub` | APK gerado |
| ELF 64-bit do APK de debug | Sete bibliotecas verificadas com PT_LOAD >= 16 KB |
| `zipalign -c -P 16 4` no APK de debug | Aprovado |
| `:app:preReleaseBuild` sem configuração | Bloqueio esperado por ausência de `API_BASE_URL` |

Artefato de teste:

```text
Frontend/code_path_flutter/build/app/outputs/flutter-apk/app-debug.apk
```

Esse APK é assinado para desenvolvimento. Não é o AAB que será enviado à loja.

## Cobertura relevante

- Token seguro, expiração, logout e revogação por reset de senha.
- Tentativa de trocar identidade via path/body e acesso a recursos de terceiros.
- Ausência de credenciais nas respostas de perfil/login.
- Login concorrente com reset, inclusive migração de senha legada.
- Exclusão com senha/confirmação e retry após conclusão.
- Perguntas sem gabarito nas partidas e convites.
- Respostas ordenadas, imutáveis, pontuadas pelo servidor.
- Finalização repetida sem duplicar moedas/pontos.
- Reserva de oponente, retomada e prazo autoritativo.
- Retomada no último índice sem `RangeError`, inclusive com finalização pendente.
- Navegação inicial em tela pequena e confirmação antes de exclusão.

## Não validado como produção

- Implantação do novo backend e índices/TTL no projeto Firebase real.
- Concorrência real e recuperação de transações no emulador/homologação Firestore.
- Envio real de recuperação de senha e resposta real da IA.
- Instalação e navegação completas em dispositivo/emulador Android.
- AAB assinado com a chave do titular e APKs derivados via bundletool.
- Conteúdo/disponibilidade das URLs públicas de privacidade/exclusão.
- Execução do workflow hospedado no GitHub e revisão no Play Console.
- Auditoria de CVEs de todas as dependências diretas/transitivas.

Nenhum teste executou exclusão ou carga em banco real. A suíte substitui a
configuração Firebase antes de importar os handlers.

Os testes locais utilizaram Flutter 3.38.5, Dart 3.10.4, Java 21 e os SDKs Android
instalados temporariamente para esta validação. O CI define Java 17 e Python 3.11.
Permanecem avisos de deprecação do SDK legado Gemini e de dependências Python;
eles não são tratados como prova de disponibilidade das integrações externas.
