# CodePath — contexto técnico da preparação mobile

## Arquitetura preservada

Um backend FastAPI/Firestore atende o aplicativo Flutter. Provider continua como
gerenciador de estado; nenhuma migração para microserviços ou outro framework
foi realizada. A infraestrutura comum do Flutter fica em `lib/core/`.

## Fluxos principais

### Autenticação

```text
Login → POST /login → bcrypt → sessão aleatória de 256 bits
      → hash SHA-256 do token no Firestore / token no armazenamento seguro Android
      → Authorization: Bearer nas chamadas da API
```

- Senhas continuam usando bcrypt com salt; SHA-256 é usado apenas para o token
  aleatório e para identificar a versão de credencial, não para armazenar senhas.
- A sessão dura sete dias. O backend verifica expiração a cada requisição;
  TTL serve para limpeza e não decide se uma sessão é válida.
- Logout remove a sessão do servidor; a saída local funciona mesmo sem rede.
  Nesse caso, o token remoto só expira posteriormente, mas o aparelho perde a cópia.
- A versão da credencial efetivamente verificada é registrada na sessão. Reset
  de senha invalida as versões anteriores, inclusive em login concorrente.
- Preferências com apenas `userEmail` não são aceitas como sessão legada.
- `401` limpa a sessão local e redireciona ao login, inclusive na exclusão de conta.
- Limites transacionais por conta: dez tentativas de login por 15 minutos;
  cinco chamadas por rota para cadastro/reset no mesmo período; 60 por rota de
  feedback de lições. Proteção por IP/volume global deve existir na infraestrutura.

`protect_request` é dependência global da API. A allowlist pública contém apenas
raiz, cadastro, login e as duas rotas de recuperação de senha. Os e-mails de ator
em path/body precisam corresponder à sessão. IDs de amizade, notificação e convite
são verificados contra seu proprietário/participantes.

### Batalhas, convites e desafios

```text
iniciar → start_attempt → perguntas públicas + attempt_id
        → POST /game/start → deadline e estado persistido
        → POST /game/answer → correção e placar do servidor
        → finalizar → transação Firestore: estado + recompensa + oponente + notificação
```

| Rota | Entrada principal | Resultado |
|---|---|---|
| `POST /game/start` | `attempt_id` | `deadline`, `next_index`, `score` |
| `POST /game/answer` | `attempt_id`, `index`, `answer` | `correct`, `score` |
| `POST /batalha/finalizar` | `attempt_id` | Resultado da batalha ou espera |
| `POST /convite/finalizar` | `attempt_id` | Resultado da rodada/convite |
| `POST /desafio/finalizar` | `attempt_id` | Resultado semanal |

- A resposta pode ser texto ou lista de blocos; o cliente não declara o placar.
- Gabaritos ficam no servidor. A listagem de convites devolve só metadados.
- Uma resposta aceita é imutável. Repetir exatamente o envio retorna seu resultado.
- A primeira entrega de questões fixa 120 segundos; a consulta `/game/start`
  recupera o prazo existente e nunca o renova. As regras semanais aparecem antes da entrega.
- A tentativa fica recuperável por dez minutos, separando o tempo de resposta
  do prazo para finalizar/reconciliar falhas de rede.
- Uma tentativa ativa por modalidade é recuperada sem consumir nova oportunidade.
  Convites também possuem referência por participante.
- O Flutter restaura índice, placar e prazo. Após falha de envio, “Verificar envio”
  consulta o estado persistido antes de liberar a próxima resposta.
- O desafio semanal reserva uma das três tentativas ao iniciar; abandono verdadeiro
  consome a oportunidade. A semana inclui ano ISO.
- Oponente de batalha é reservado transacionalmente até a expiração da tentativa;
  duas tentativas não devem receber a mesma reserva simultaneamente.
- Repetir a finalização devolve o resultado salvo, sem pagar outra vez.
- Transações fazem todas as leituras antes das escritas. Não mover consultas para
  depois de `transaction.update/set/delete`.
- Funções antigas de finalização permanecem sem decorators em `pages/`, apenas
  como referência de migração. As rotas ativas são exclusivamente as de `games.py`.

### Exclusão de conta

`DELETE /account` exige sessão, senha atual e `confirmation: "EXCLUIR"`.
Marca a conta como em exclusão, remove registros associados em lotes limitados e
remove usuário e sessão no commit final. O fluxo é explícito na tela de configurações.

Um recibo sem nome/e-mail/senha, identificado pelo digest da antiga sessão, permite
recuperar uma confirmação perdida por até 15 minutos. Depois desse prazo, a sessão
não autentica mais. Uma falha antes da conclusão permite repetir a limpeza.

Coleções tratadas: `usuarios`, `sessions`, `amizades`, `batalhas_convite`,
`batalha_queue`, `game_attempts`, `notificacoes`, `password_reset_tokens` e
`auth_limits`. Partidas compartilhadas e amizades também são removidas.
Backups, logs e dados eventualmente retidos por provedores externos exigem política
operacional própria; a API não promete apagar dados fora dessas coleções.

## Banco, configuração e implantação

- Use `Backend/requirements-release.txt` para o ambiente de release.
- `GOOGLE_APPLICATION_CREDENTIALS` aponta para a chave de serviço somente no servidor.
- `Backend/firestore.indexes.json` descreve índices necessários e limpeza TTL.
  Mescle com os índices já existentes no projeto antes de implantar. A implantação
  dos índices/TTL não foi executada nesta entrega.
- Para sessões e segredos de uso único, mantenha regras Firestore impedindo acesso
  direto de clientes. O app usa apenas a API; bibliotecas Firebase não utilizadas
  foram retiradas do Flutter. O Admin SDK depende das permissões IAM do servidor.
- O JSON do aplicativo tem apenas configuração pública. Nunca inserir credenciais
  Firebase/Gemini/Brevo nem senha de keystore em `--dart-define`.

## Implantação coordenada e dados legados

1. Validar a API e índices em homologação com dados de teste.
2. Disponibilizar a API nova e distribuir o app compatível no canal de testes.
3. Usuários antigos precisam entrar novamente para criar uma sessão verificável.
4. Entradas antigas de `batalha_queue` não têm `schema_version: 2` e não participam
   do novo matchmaking. Defina um procedimento explícito de expiração/arquivamento;
   não execute os seeds para “corrigir” isso.
5. Convites parcialmente jogados no contrato antigo não possuem tentativas válidas.
   Trate sua expiração de forma explícita e oriente iniciar novos convites.
6. Códigos antigos de recuperação sem hash são substituídos ao solicitar novo código.
7. Não volte o backend ao contrato sem autenticação enquanto o app novo estiver em uso.

## Validação e limitações

Testes usam um Firestore em memória e substituem `firebase_config` antes de importar
handlers. Eles verificam contratos, autorização e efeitos idempotentes, mas não
substituem testes de concorrência/índices contra o emulador Firestore e homologação.

O analisador Flutter ainda apresenta avisos informativos legados (nomes,
deprecações e logs). `flutter analyze --no-fatal-infos` mantém warnings e erros como
bloqueadores. Não desabilitar regras para ocultar regressões.

O SDK `google-generativeai` permanece legado e emite aviso de descontinuação;
planejar migração para o SDK atual antes de depender da IA como funcionalidade crítica.
O fallback da lição mantém a correção sem a explicação gerada.

## Convenções para manutenção

- Testar alteração de contrato nos dois lados, especialmente `attempt_id` e sessão.
- Não restaurar pontuação declarada pelo cliente nem retornar documentos privados.
- Não executar scripts de carga em produção; vários scripts legados são destrutivos.
- Não versionar `.env`, credenciais, `key.properties`, keystore ou builds.
- Consultar [publicacao.md](docs/play-store/publicacao.md) antes de preparar um AAB.
