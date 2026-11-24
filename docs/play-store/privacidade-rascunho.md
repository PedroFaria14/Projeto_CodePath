# Rascunho de privacidade — não publicar sem preencher e revisar

Este documento é uma base factual para o responsável preparar a página pública.
Não é a política aprovada do aplicativo e não deve ser apontado como URL final.

## Responsável

Preencher nome/razão social, contato de suporte e canal de direitos de dados.
Definir público-alvo e processo para solicitações envolvendo menores, se aplicável.

## Dados presentes no código

- Cadastro: nome, e-mail, telefone, data de nascimento e senha armazenada com bcrypt.
- Uso: progresso, dificuldade, moedas, pontuações, sequência de uso e últimas entradas.
- Recursos sociais: e-mails/nomes em amizades, convites e notificações de partidas.
- Autenticação: token aleatório no armazenamento seguro do aparelho; hash do token,
  validade e versão de credencial no servidor.
- Recuperação: e-mail, hash do código e prazo de validade.
- Respostas de jogos: respostas enviadas, placar e prazo da tentativa.
- O ranking mostra nome e pontos; recursos de busca de amigos exibem nome/e-mail.

## Integrações a confirmar na implantação

- Google Cloud Firestore para persistência no backend.
- Brevo para entrega de e-mail de recuperação.
- Google Gemini para explicação de exercícios: enunciado, resposta correta e resposta
  do usuário podem ser enviados ao provedor. Não orientar usuários a inserir dados
  pessoais nas respostas; documentar a finalidade e a configuração real do provedor.
- Hospedagem da API e seus logs/backups, conforme ambiente efetivamente utilizado.
- Google Fonts pode buscar fontes pela rede em runtime; revisar esse comportamento
  e os respectivos provedores na declaração final.

O app não implementa analytics, anúncios ou push notifications nesta base.
Confira SDKs e serviços da versão final antes de declarar isso no Play Console.

## Exclusão e retenção

No aplicativo: Configurações → Excluir conta e dados → senha atual + EXCLUIR.
O backend remove as coleções associadas descritas em `documentacao-opencode.md`.
Um recibo técnico sem nome/e-mail é aceito por 15 minutos para reconhecer um retry.
TTL é assíncrono; sua política operacional deve descrever o prazo efetivo de limpeza.

Defina separadamente retenção de logs, backups, dados em provedores externos e
eventuais obrigações legais. Não prometa “exclusão imediata de todos os sistemas”
sem um procedimento que efetivamente a cumpra.

Disponibilize uma página externa de exclusão com canal utilizável sem o aplicativo,
verificação de identidade, escopo dos dados removidos e prazo real de atendimento.

## Antes de publicar

Preencher responsável, contatos, finalidades, bases aplicáveis, compartilhamento,
retenção, medidas de segurança e canal de exercício de direitos. Conferir a
declaração de segurança dos dados e disponibilizar o texto em HTML público por HTTPS.
