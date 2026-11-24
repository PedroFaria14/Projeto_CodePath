# Guardanapo (Napkin)

## Regras de Curadoria

- Manter orientações recorrentes, com ação explícita e data.
- Priorizar por impacto; máximo de 10 itens por categoria.

## Execução e Validação

1. **[2026-11-24] Testes não podem carregar credenciais de produção.**
   Faça isto em vez disso: use as fixtures de `Backend/conftest.py` e `Backend/tests/`; substitua o banco no namespace consumidor.
2. **[2026-11-24] Preparação Android tem contrato de API próprio.**
   Faça isto em vez disso: valide mobile e backend juntos; use sessão Bearer e `attempt_id`, nunca placar declarado pelo cliente.

## Build e Publicação

1. **[2026-11-24] Release precisa de configuração real e chave de upload.**
   Faça isto em vez disso: siga `docs/play-store/publicacao.md`; não troque a assinatura de release pela de debug para fazer o build passar.
2. **[2026-11-24] Cache Kotlin entre discos diferentes no Windows pode falhar.**
   Faça isto em vez disso: mantenha Pub cache/projeto no mesmo disco ou desative incremental apenas na execução local com `GRADLE_OPTS=-Dorg.gradle.project.kotlin.incremental=false`.

## Dados

1. **[2026-11-24] Seeds legados podem apagar coleções ao importar.**
   Faça isto em vez disso: não importe nem execute `Backend/scripts/` como validação; use banco de homologação e autorização explícita para cargas.
