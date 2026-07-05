# QuickShell GitHub Session — Requirements Document

## Intent Analysis

- **User Request**: Adicionar painel GitHub no QuickShell exibindo notificações, PRs e Issues por repositório, usando `gh` CLI para autenticação
- **Request Type**: New Feature (enhancement ao QuickShell existente)
- **Scope Estimate**: Single Component (novo módulo QML + import no shell.qml)
- **Complexity Estimate**: Moderate (múltiplos QML files, parsing JSON do `gh`, Timer, interação com browser)

---

## Functional Requirements

### FR-01: Exibição de Notificações GitHub
O painel deve exibir a quantidade de notificações não lidas do GitHub obtidas via `gh api notifications`. O contador deve ser clicável e abrir o navegador na página de notificações do GitHub (`https://github.com/notifications`).

### FR-02: Listagem de Repositórios com PRs/Issues
O painel deve listar em cards todos os repositórios onde o usuário possui PRs e/ou Issues abertas (atribuídas ao usuário ou criadas por ele). Cada card exibe o nome do repositório com as contagens de PRs e Issues separadas.

### FR-03: Links Clicáveis por Repositório
Cada contagem (PRs e Issues) em um card de repositório deve ser clicável e redirecionar ao navegador:
- PRs: `https://github.com/{owner}/{repo}/pulls?q=is:open+author:{user}` ou equivalente
- Issues: `https://github.com/{owner}/{repo}/issues?q=is:open+author:{user}` ou equivalente

### FR-04: Auto-Refresh por Timer
O painel deve consultar a API do GitHub automaticamente a cada 1 hora (3600000ms) via Timer.

### FR-05: Botão Manual de Reload
O painel deve possuir um botão de refresh manual (↻) no header, permitindo forçar atualização imediata independente do timer.

### FR-06: Autenticação via gh CLI
Toda comunicação com a API do GitHub deve ser feita via `gh` CLI, aproveitando a autenticação OAuth já configurada pelo usuário (`gh auth login`). Comandos utilizados:
- `gh api notifications` — notificações
- `gh search prs --author=@me --state=open --json repository,url` — PRs
- `gh search issues --author=@me --state=open --json repository,url` — Issues atribuídas/criadas

### FR-07: Abertura no Navegador
Links clicáveis devem abrir o navegador padrão via comando `xdg-open`.

---

## Non-Functional Requirements

### NFR-01: Visibilidade Constante
O painel GitHub deve permanecer sempre visível, independente do estado da flag `sensitiveData` (modo privacidade).

### NFR-02: Posicionamento no Shell
O painel deve ser posicionado no final da área scrollável do shell, antes do NetworkMonitor e do NotificationPanel.

### NFR-03: Estrutura de Arquivos
Seguir o padrão estabelecido pelo TaskWarrior com pasta dedicada:
```
home/quickshell/config/github/
├── GitHubPanel.qml        (componente principal do painel)
├── GitHubDataManager.qml  (gerenciamento de dados e comandos gh)
└── RepoCard.qml           (card individual de repositório)
```

### NFR-04: Consistência Visual
Seguir a paleta Catppuccin Macchiato e o estilo visual dos painéis existentes (transparência, cores de texto, bordas, fontes, botões).

### NFR-05: Resiliência a Erros
Se o `gh` CLI não estiver autenticado ou falhar, exibir mensagem de erro amigável no painel (similar ao padrão do TaskPanel com `errorMessage`).

### NFR-06: Baixo Consumo de Recursos
Intervalo de 1 hora entre consultas automáticas. Não deve impactar performance do sistema com polling excessivo.

---

## Technical Decisions

| Decisão | Escolha | Justificativa |
|---------|---------|---------------|
| API Client | `gh` CLI | Autenticação OAuth já resolvida, sem necessidade de token manual |
| Refresh Rate | 1 hora (3600s) | Baixo consumo, dados de GitHub não são real-time critical |
| Navegador | `xdg-open` | Padrão Linux, respeita default do sistema |
| Escopo notificações | Apenas não lidas | Padrão do GitHub, mais relevante |
| Escopo repos | Autor ou assignee, open | Foco no que é actionable |
| Privacidade | Sempre visível | Decisão do usuário (Q1=B) |
| Estrutura | Pasta dedicada | Padrão do projeto (TaskWarrior) |

---

## Extension Configuration

| Extension | Enabled | Decided At | Notes |
|-----------|---------|-----------|-------|
| Security Baseline | No | Requirements Analysis | UI panel, sem dados sensíveis expostos |
| Property-Based Testing | No | Requirements Analysis | UI-only, sem lógica de negócio testável via PBT |
