# Plano de Code Generation: Taskwarrior + Timewarrior + QuickShell

**Data**: 2026-08-20  
**Status**: Aguardando aprovação  

## Informações Técnicas Verificadas

- Pacote nixpkgs-unstable: `timewarrior` v1.10.0
- Path do hook no store: `${pkgs.timewarrior}/share/doc/timew/ext/on-modify.timewarrior`
- O hook é um script Python que recebe old/new task JSON no stdin e chama `timew start/stop tags :yes`
- O hook passa as seguintes informações como tags para o Timewarrior: description, project, tags da task
- DataWatcher.qml atual usa FileView + polling timer (mantido intacto — não é alterado)

---

## Passos do Plano

- [x] **Passo 1** — Criar `home/taskwarrior/timew-summary.py`
- [x] **Passo 2** — Criar `home/quickshell/config/taskwarrior/TimeDataManager.qml`
- [x] **Passo 3** — Reformular `home/quickshell/config/taskwarrior/TaskPanel.qml`
- [x] **Passo 4** — Modificar `home/quickshell/config/taskwarrior/TaskManager.qml`
- [x] **Passo 5** — Modificar `home/quickshell/config/taskwarrior/TaskItem.qml`
- [x] **Passo 6** — Modificar `home/quickshell/config/taskwarrior/TaskCard.qml`
- [x] **Passo 7** — Modificar `home/taskwarrior/default.nix`
- [x] **Passo 8** — Modificar `home/taskwarrior/sync-config.nix`
- [x] **Passo 9** — Criar `tests/taskwarrior-timewarrior-test.nix`
- [x] **Passo 10** — `nix flake check --no-build` ✅ zero erros
  - Categoriza intervalos como work/personal/other baseado nas tags herdadas do Taskwarrior
  - Computa: totais do dia, breakdown por projeto, tarefa ativa com elapsed_seconds
  - Computa: totais por dia da semana atual (Seg–Dom)
  - Retorna JSON conforme estrutura definida no RF-04
  - Usa `subprocess.run` com lista de argumentos (sem `shell=True`) — Security Baseline
  - Tratamento de erro: retorna JSON com zeros se timew/task não retornar dados válidos

- [ ] **Passo 2** — Criar `home/quickshell/config/taskwarrior/TimeDataManager.qml`
  - Componente QML Item que executa o script Python via `Process`
  - Expõe propriedades: `todayWorkSeconds`, `todayPersonalSeconds`, `todayOtherSeconds`,
    `byProject` (array), `activeTask` (objeto), `weekData` (array 7 dias)
  - Expõe `isLoading`, `errorMessage`, `lastUpdated`
  - Timer interno de 60 segundos para auto-refresh
  - Sinal `dataReady()` emitido após parse do JSON
  - Método público `refresh()` para refresh manual

- [ ] **Passo 3** — Reformular `home/quickshell/config/taskwarrior/TaskPanel.qml`
  - Substituir completamente o conteúdo atual (lista de tasks) por painel de tempo
  - Instanciar TimeDataManager internamente
  - Layout (ColumnLayout, de cima para baixo):
    1. Header: "Tempo" + botão ↻ + timestamp última atualização
    2. Tarefa Ativa: nome + cronômetro em tempo real (Timer 1s, visível só se houver ativa)
    3. Resumo Hoje: "Trabalho: Xh Ym" e "Pessoal: Xh Ym" em dois Text lado a lado
    4. Breakdown por Projeto: Repeater de linhas (nome_projeto + barra proporcional + tempo)
    5. Semana: Row de 7 colunas (label dia + barra segmentada work/personal + total)
  - Manter: `color`, `radius`, `implicitHeight` calculado dinamicamente
  - Remover: TaskManager, DataWatcher, TaskCard ListView, função `rebuildTaskCardModel`

- [ ] **Passo 4** — Modificar `home/quickshell/config/taskwarrior/TaskManager.qml`
  - Remover: `timerProcess` (com toda a lógica de auto-stop/modify-time)
  - Remover: função `pauseTask(uuid, elapsedSeconds)`
  - Remover: signal `timerOperationCompleted` e `timerError`
  - Remover: `timerErrorClearTimer`
  - Remover: handler `onTimerError`
  - Remover: função `computeElapsedForTask`
  - Manter: `taskExportProcess`, `taskModifyProcess`, `refreshTasks()`, `startTask()`,
    `updateTaskStatus()`, `parseAndGroupTasks()`, `groupTasksByClient()`,
    `findActiveTaskUuid()`, `findTaskByUuid()`, `parseTaskwarriorTimestamp()`
  - Manter: signals `tasksUpdated`, `taskModified`, `errorOccurred`
  - **Nota**: TaskManager ainda é usado pelo TaskCard/TaskItem para start/stop de tasks
    (o start/stop chama o hook Timewarrior automaticamente)

- [ ] **Passo 5** — Modificar `home/quickshell/config/taskwarrior/TaskItem.qml`
  - Remover: propriedades `accumulatedSeconds`, `elapsedSeconds`, `timerRunning`, `pauseInProgress`
  - Remover: `elapsedTimer` (Timer 1s)
  - Remover: funções `updateElapsed`, `currentSessionSeconds`, `formatTime`, `timerButtonState`
  - Remover: elemento `timerButton` (Rectangle com ▶/⏸) do RowLayout
  - Remover: elemento `timerDisplay` (Text HH:MM:SS) do RowLayout
  - Remover: Connections para `onTimerOperationCompleted` e `onTimerError`
  - Manter: status button (⧖/✓/⏸), description text, metadata row (tags, due date)
  - Manter: `openTaskInTerminal`, `terminalProcess`
  - Manter: funções de helper: `getStatusIcon`, `getNextStatus`, `isTaskActive`,
    `getTaskBackgroundColor`, `getPriorityColor`, `formatDueDate`, `isOverdue`
  - **Simplificação do border**: `border.color` mantém azul para task ativa (`isTaskActive`)
    mas sem depender de timer

- [ ] **Passo 6** — Modificar `home/quickshell/config/taskwarrior/TaskCard.qml`
  - Remover: propriedades `headerElapsedSeconds`, `hasAnyTimeInCard`
  - Remover: `headerTimer` (Timer 1s)
  - Remover: função `updateHeaderElapsed`
  - Remover: função `formatTime`
  - Remover: Text de timer no header (o que exibia HH:MM:SS)
  - Remover: `onTaskArrayChanged: updateHeaderElapsed()`
  - Manter: `hasActiveTask()`, indicador ▶ no header, task count badge, priority dot
  - Manter: expansão/colapso, Repeater de TaskItems

- [ ] **Passo 7** — Modificar `home/taskwarrior/default.nix`
  - Adicionar `timewarrior` em `home.packages`
  - Instalar hook via `home.file`:
    ```nix
    home.file.".local/share/task/hooks/on-modify.timewarrior" = {
      source = "${pkgs.timewarrior}/share/doc/timew/ext/on-modify.timewarrior";
      executable = true;
    };
    ```
  - Adicionar script Python via `xdg.configFile."task/timew-summary.py"`:
    ```nix
    xdg.configFile."task/timew-summary.py".source = ./timew-summary.py;
    ```
  - Criar diretório de dados do Timewarrior:
    ```nix
    home.file.".local/share/timewarrior/.keep".text = "";
    ```
  - Adicionar alias fish `timew-day` para chamar o script Python

- [ ] **Passo 8** — Modificar `home/taskwarrior/sync-config.nix`
  - Remover do taskrc: `uda.totalactivetime.type=numeric` e `uda.totalactivetime.label=Total Active Time`
  - Remover do taskrc: `report.next.columns` — remover `totalactivetime` da lista de colunas se presente
    (verificar: no taskrc atual a coluna `client` está no report.next, não `totalactivetime`)
  - Adicionar configuração do Timewarrior no taskrc (para o hook funcionar com `timew` no PATH):
    - Não necessário — o hook chama `timew` que estará no PATH do usuário

- [ ] **Passo 9** — Criar `tests/taskwarrior-timewarrior-test.nix`
  - Seguir padrão do `devenv-direnv-test.nix`
  - Assertions:
    - `timewarrior` instalado e acessível via `timew`
    - Hook instalado em `~/.local/share/task/hooks/on-modify.timewarrior`
    - Hook é executável
    - Script Python `~/.config/task/timew-summary.py` existe
    - Diretório `~/.local/share/timewarrior/` existe

- [ ] **Passo 10** — Executar `nix flake check --no-build`
  - Verificar zero erros e zero warnings críticos

---

## Dependências entre passos

```
Passo 1 (timew-summary.py)
  → Passo 2 (TimeDataManager.qml — consome o script)
    → Passo 3 (TaskPanel.qml — consome TimeDataManager)
Passo 4 (TaskManager.qml) — independente, pode ser paralelo
Passo 5 (TaskItem.qml) — depende do Passo 4 (remove Connections do TaskManager)
Passo 6 (TaskCard.qml) — independente
Passo 7 (default.nix) — depende do Passo 1 (referencia o .py)
Passo 8 (sync-config.nix) — independente
Passo 9 (teste) — depende de todos os anteriores
Passo 10 (flake check) — depende de todos
```

---

## Estrutura do JSON retornado pelo timew-summary.py (RF-04)

```json
{
  "today": {
    "work_seconds": 14520,
    "personal_seconds": 3600,
    "other_seconds": 0,
    "by_project": [
      { "project": "Blog", "seconds": 7200, "type": "personal" },
      { "project": "Maestro", "seconds": 7320, "type": "work" }
    ],
    "active_task": {
      "description": "Implementar login OAuth",
      "project": "Maestro",
      "elapsed_seconds": 1823
    }
  },
  "week": [
    { "date": "2026-08-17", "label": "Seg", "work_seconds": 18000, "personal_seconds": 5400 },
    { "date": "2026-08-18", "label": "Ter", "work_seconds": 21600, "personal_seconds": 1800 },
    { "date": "2026-08-19", "label": "Qua", "work_seconds": 16200, "personal_seconds": 0 },
    { "date": "2026-08-20", "label": "Qui", "work_seconds": 14520, "personal_seconds": 3600 },
    { "date": "2026-08-21", "label": "Sex", "work_seconds": 0, "personal_seconds": 0 },
    { "date": "2026-08-22", "label": "Sáb", "work_seconds": 0, "personal_seconds": 0 },
    { "date": "2026-08-23", "label": "Dom", "work_seconds": 0, "personal_seconds": 0 }
  ]
}
```
