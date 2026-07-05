# Integration Test Instructions — QuickShell GitHub Session

## Purpose
Testar a integração entre o painel GitHub no QuickShell e os serviços externos (GitHub API via `gh` CLI, browser via `xdg-open`).

## Test Scenarios

### Scenario 1: GitHubDataManager → GitHub API
- **Description**: DataManager busca dados via `gh` CLI e retorna JSON válido
- **Setup**: `gh auth status` deve retornar autenticado
- **Test Steps**:
  1. Executar manualmente: `gh api notifications --jq "length"`
  2. Executar: `gh search prs --author=@me --state=open archived:false --json repository`
  3. Executar: `gh search issues --author=@me --state=open archived:false --json repository`
- **Expected Results**: JSON válido retornado, sem erros de autenticação
- **Cleanup**: Nenhum

### Scenario 2: GitHubPanel → xdg-open → Browser
- **Description**: Clique em notificações/badges abre URL correta no navegador padrão
- **Setup**: Browser configurado como default via `xdg-settings get default-web-browser`
- **Test Steps**:
  1. Clicar na seção de notificações
  2. Verificar que `https://github.com/notifications` abre no browser
  3. Clicar no badge de PR de um repo
  4. Verificar que URL correta abre (ex: `https://github.com/{owner}/{repo}/pulls?q=...`)
- **Expected Results**: Browser abre com a URL correta
- **Cleanup**: Fechar abas do browser

### Scenario 3: Timer Auto-Refresh
- **Description**: Dados são atualizados automaticamente a cada 1 hora
- **Setup**: Painel carregado com dados
- **Test Steps**: (teste longo — pode ser simulado reduzindo o timer temporariamente)
  1. Verificar timestamp inicial do log "GitHub data refreshed"
  2. Aguardar ciclo do timer
  3. Verificar novo log "GitHub data refreshed"
- **Expected Results**: Dados refreshed sem intervenção manual
- **Cleanup**: Restaurar timer para 3600000ms se alterado

## Verification Commands

```bash
# Verificar gh auth
gh auth status

# Testar busca de notificações
gh api notifications --jq "length"

# Testar busca de PRs (excluindo archived)
gh search prs --author=@me --state=open archived:false --json repository | jq length

# Testar busca de Issues (excluindo archived)
gh search issues --author=@me --state=open archived:false --json repository | jq length

# Verificar xdg-open
xdg-open https://github.com/notifications
```
