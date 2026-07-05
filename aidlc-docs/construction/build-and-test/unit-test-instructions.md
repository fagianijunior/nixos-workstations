# Unit Test Execution — QuickShell GitHub Session

## Context
QML files não possuem framework de testes unitários tradicional neste projeto. A validação é feita via:
1. `nix flake check --no-build` — valida que o flake e todos os módulos avaliam sem erros
2. Verificação manual de runtime do QuickShell

## Run Validation

### 1. Validate Nix Flake (static)
```bash
cd /home/terabytes/Workspace/fagianijunior/nixos
nix flake check --no-build
```
- **Expected**: `all checks passed!`

### 2. Validate QML Files Exist
```bash
ls -la home/quickshell/config/github/
```
- **Expected**: GitHubDataManager.qml, GitHubPanel.qml, RepoCard.qml

### 3. Validate shell.qml Import
```bash
grep -n 'github' home/quickshell/config/shell.qml
```
- **Expected**: import `"./github"` e `GitHubPanel` presentes

## Functional Verification (manual, pós-deploy)

### Cenário 1: Painel carrega sem erros
1. Após `nixos-rebuild switch`, QuickShell reinicia
2. Painel GitHub deve aparecer na barra lateral
3. Sem mensagens de erro no header

### Cenário 2: Notificações exibidas
1. Com `gh auth status` confirmando autenticação
2. Contagem de notificações não lidas exibida com badge vermelho
3. Clique abre `https://github.com/notifications` no browser

### Cenário 3: Repositórios listados
1. PRs abertas pelo usuário aparecem em cards
2. Issues abertas pelo usuário aparecem em cards
3. Repos arquivados NÃO aparecem (filtro `archived:false`)
4. Badges clicáveis abrem URLs corretas no browser

### Cenário 4: Refresh funcional
1. Botão ↻ dispara refresh manual imediato
2. Timer auto-refresh opera a cada 1 hora

### Cenário 5: Erro de autenticação
1. Com `gh auth logout`, o painel exibe mensagem de erro
2. Sem crash ou loop infinito
