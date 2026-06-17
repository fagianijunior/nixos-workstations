# Requisitos — Integração QuickShell

## Análise de Intenção

| Campo | Valor |
|-------|-------|
| **Requisição do Usuário** | Integrar configuração QuickShell existente (to_implement/quickshell/) no projeto NixOS, para o usuário terabytes em Nobita e Doraemon |
| **Tipo de Requisição** | Feature Addition (Brownfield) |
| **Estimativa de Escopo** | Componente único (módulo Home Manager + config files) |
| **Estimativa de Complexidade** | Baixa (mover arquivos, criar módulo Nix, ajustar imports) |

---

## Requisitos Funcionais

### RF-QS-01: Módulo Home Manager para QuickShell

**Descrição**: Criar `home/quickshell.nix` como módulo Home Manager que:
- Habilita `programs.quickshell` com systemd service
- Cria symlink de `~/.config/quickshell` apontando para o config no repositório (`home/quickshell/config`)
- Disponibiliza Python com dependências Google API via `~/.local/bin/python3-google`

### RF-QS-02: Configuração QML do QuickShell

**Descrição**: Mover os arquivos de configuração QML funcionais para `home/quickshell/config/`:
- `shell.qml` — Painel principal (status panel)
- `Graph.qml` — Componente de gráfico de linhas
- `PieChart.qml` — Componente de gráfico de pizza (disco)
- `app-colors.json` — Cores de notificação por aplicativo
- `get_events.py` — Script Python para Google Calendar API
- `battery/BatteryGraph.qml` — Monitoramento de bateria (condicional por device)
- `colors/BorderColorManager.qml` — Gerenciador de cores de borda por app
- `filters/NotificationFilter.qml` — Filtro de notificações
- `filters/filter-config.json` — Configuração de filtros
- `interaction/ClickRedirectHandler.qml` — Handler de cliques em notificações
- `utils/ConfigManager.qml` — Gerenciador de configurações JSON
- `utils/DeviceDetector.qml` — Detector de dispositivo (Nobita vs Doraemon)
- `utils/save_config.py` — Script Python para salvar configs
- `taskwarrior/TaskPanel.qml` — Painel de tarefas
- `taskwarrior/TaskManager.qml` — Gerenciador de dados Taskwarrior
- `taskwarrior/TaskItem.qml` — Item individual de tarefa
- `taskwarrior/TaskCard.qml` — Card de cliente/grupo de tarefas
- `taskwarrior/DataWatcher.qml` — Watcher de mudanças no ~/.task

**Excluir** (artefatos de desenvolvimento):
- Todos os `*.md` dentro de `taskwarrior/` (CHECKPOINT, TASK_*, FINAL_VALIDATION, CONNECTION_PATTERN)
- `taskwarrior/ConnectionExample.qml`
- `taskwarrior/tests/` (diretório inteiro)
- `debug_disk.js`

### RF-QS-03: Integração no Home Manager

**Descrição**: Importar `./quickshell.nix` no `home/default.nix` existente.

### RF-QS-04: Dependências Python (Google Calendar API)

**Descrição**: O módulo deve fornecer um Python com:
- `google-api-python-client`
- `google-auth-httplib2`
- `google-auth-oauthlib`
- `requests`

Disponível em `~/.local/bin/python3-google` (sem conflito com home.packages).

### RF-QS-05: Credenciais Google Calendar

**Descrição**: O `credentials.json` é gerenciado manualmente pelo usuário, não commitado no repositório. O script `get_events.py` espera encontrá-lo no diretório do config ou verifica `QUICKSHELL_DISABLE_CALENDAR=1` para desabilitar.

### RF-QS-06: Compatibilidade Multi-Device

**Descrição**: A configuração funciona em ambas as máquinas:
- **Nobita (Desktop)**: BatteryGraph oculto (DeviceDetector identifica como não-portátil)
- **Doraemon (Notebook)**: BatteryGraph visível (DeviceDetector identifica como portátil)
- Detecção automática via hostname

### RF-QS-07: Integração com Dunst

**Descrição**: QuickShell integra com dunst via `dunstctl` para:
- Toggle de modo privacy (pause/resume notificações)
- Listagem de notificações no painel

---

## Requisitos Não-Funcionais

### RNF-QS-01: Configuração Mutável

- A configuração QML é mutável (editável sem rebuild NixOS)
- Symlink via `mkOutOfStoreSymlink` aponta para o repositório
- Mesma abordagem usada para `hyprland.lua`

### RNF-QS-02: Segurança

- Credenciais Google API (credentials.json, token.json) NÃO são commitadas
- Token é armazenado em `~/.cache/quickshell/token.json`
- Nenhum segredo hardcoded nos arquivos de configuração

---

## Decisões Técnicas

| Decisão | Escolha | Justificativa |
|---------|---------|---------------|
| Local da config | `home/quickshell/config/` | Mesmo repo, consistente com `home/hyprland.lua` |
| Symlink approach | `mkOutOfStoreSymlink` | Config mutável sem rebuild |
| Python API | `home.file.".local/bin/python3-google"` | Evita conflito com python3 do home.packages |
| Systemd service | `programs.quickshell.systemd.enable = true` | Inicia automaticamente com a sessão |
| Exclusões | Dev artifacts removidos | Config limpa, sem ruído |
