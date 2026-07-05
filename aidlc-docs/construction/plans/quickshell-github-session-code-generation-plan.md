# Code Generation Plan — QuickShell GitHub Session

## Unit Context
- **Unit**: QuickShell GitHub Session Panel
- **Workspace Root**: /home/terabytes/Workspace/fagianijunior/nixos
- **Target Directory**: home/quickshell/config/github/
- **Integration Point**: home/quickshell/config/shell.qml (add import + component)
- **Pattern Reference**: home/quickshell/config/taskwarrior/ (Task panel structure)

## Dependencies
- `gh` CLI (GitHub CLI) — já instalado no sistema via NixOS
- `xdg-open` — padrão Linux para abrir URLs
- QuickShell runtime com Quickshell.Io (Process, StdioCollector)

## Files to Generate/Modify

| # | Action | File | Description |
|---|--------|------|-------------|
| 1 | CREATE | home/quickshell/config/github/GitHubDataManager.qml | Gerenciamento de dados via `gh` CLI |
| 2 | CREATE | home/quickshell/config/github/RepoCard.qml | Card individual de repositório |
| 3 | CREATE | home/quickshell/config/github/GitHubPanel.qml | Componente principal do painel |
| 4 | MODIFY | home/quickshell/config/shell.qml | Adicionar import + GitHubPanel |

---

## Execution Steps

### Step 1: Create GitHubDataManager.qml
- [x] Create `home/quickshell/config/github/GitHubDataManager.qml`
- Responsibilities:
  - Process para `gh api notifications` (contagem de não lidas)
  - Process para `gh search prs --author=@me --state=open --json repository,url`
  - Process para `gh search issues --author=@me --state=open --json repository,url`
  - Timer de 1 hora (3600000ms) para auto-refresh
  - Propriedades expostas: `notificationCount`, `repoData` (array de {repoName, owner, prCount, issueCount, prUrl, issueUrl}), `isLoading`, `errorMessage`
  - Signals: `dataUpdated()`, `errorOccurred(string message)`
  - Método público `refreshData()` para manual reload
  - Parsing de JSON do stdout dos processos
  - Agrupamento de PRs e Issues por repositório
  - Obtenção do username via `gh api user --jq .login`

### Step 2: Create RepoCard.qml
- [x] Create `home/quickshell/config/github/RepoCard.qml`
- Responsibilities:
  - Recebe props: `repoName`, `owner`, `prCount`, `issueCount`
  - Exibe nome do repositório
  - Badges clicáveis para PRs (abre `https://github.com/{owner}/{repo}/pulls?q=is:open+author:@me`)
  - Badges clicáveis para Issues (abre `https://github.com/{owner}/{repo}/issues?q=is:open+author:@me`)
  - Process para `xdg-open` ao clicar
  - Estilo Catppuccin Macchiato (cores, bordas, radius)
  - Layout compacto (RowLayout com nome + badges)

### Step 3: Create GitHubPanel.qml
- [x] Create `home/quickshell/config/github/GitHubPanel.qml`
- Responsibilities:
  - Instancia GitHubDataManager
  - Header com título " GitHub", status text (loading/error), botão reload (↻)
  - Seção de notificações: ícone 🔔 + contagem, clicável (abre `https://github.com/notifications`)
  - ListView com model ListModel populado dos dados do DataManager
  - Delegate usa RepoCard
  - Process para `xdg-open` ao clicar notificações
  - Component.onCompleted chama refreshData()
  - Estilo: Rectangle com transparência, radius 8, cores Catppuccin

### Step 4: Update shell.qml
- [x] Add import `"./github"` no topo do arquivo
- [x] Add `GitHubPanel` component no ColumnLayout dentro do ScrollView, posição: antes do DiskMonitor (final da lista, antes de Network/Notifications)
- Propriedades: `Layout.fillWidth: true`

---

## Verification
- [x] Validate QML syntax (sem erros de parsing)
- [x] nix flake check --no-build passa sem erros
- [x] Todos os Process usam arrays para command (segurança)
- [x] URLs construídas corretamente
- [x] Timer configurado para 3600000ms
