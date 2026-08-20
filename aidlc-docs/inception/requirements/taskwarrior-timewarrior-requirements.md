# Requisitos: Taskwarrior + Timewarrior + QuickShell

**Feature**: Reformulação do sistema de tasks com rastreamento de tempo  
**Data**: 2026-08-20  
**Status**: Aprovado  

---

## Contexto

O projeto NixOS já possui:
- `home/taskwarrior/` — módulo Nix com Taskwarrior 3, sync via taskchampion, UDA `client` e `totalactivetime`
- `home/quickshell/config/taskwarrior/` — TaskPanel.qml, TaskManager.qml, TaskCard.qml, TaskItem.qml
- Sistema de cronômetro em tempo real por task (via `totalactivetime` UDA + timer QML)
- Contextos definidos: `context.work=project:Work or +work`, `context.personal=project:Personal or +personal`

---

## Decisões Tomadas (do Questionário)

| # | Pergunta | Decisão |
|---|----------|---------|
| Q1 | Integração Timewarrior | Hook automático `on-modify.timewarrior` |
| Q2 | Layout QuickShell | Reformulação completa — painel focado em tempo |
| Q3 | Métricas | Total work/personal + cronômetro tarefa ativa + breakdown por projeto |
| Q4 | Separação work/personal | Contextos existentes (`project:Work` ou `+work`) |
| Q5 | UDA totalactivetime | Migrar para Timewarrior, remover totalactivetime |
| Q6 | Cronômetro por task | Remover — Timewarrior faz tracking no background |
| Q7 | Fonte de dados QML | Script Python intermediário que retorna JSON simples |
| Q8 | Frequência atualização | A cada 60 segundos |
| Q9 | Histórico | Semana atual (total por dia da semana) |
| Q10 | Security Baseline | Habilitado |

---

## Nota sobre `project:` e categorização work/personal

O campo `project:` no Taskwarrior é para nome do projeto (Site, Blog, Maestro, etc.).
A categorização work/personal deve ser feita via **tags**: `+work` ou `+personal`.

O hook Timewarrior captura automaticamente as tags e o projeto da task ao iniciar.
O script Python de intermediação categoriza o intervalo com base nas tags herdadas.

Tasks sem `+work` nem `+personal` explícito são categorizadas como "trabalho" se o
projeto bater com o contexto `project:Work`, e "pessoal" se bater com `project:Personal`.
Tasks de outros projetos (Blog, Maestro, etc.) com tag `+work` ou `+personal` são
corretamente categorizadas. Tasks sem nenhuma categorização são agrupadas como "outros".

---

## Requisitos Funcionais

### RF-01 — Instalação do Timewarrior
O módulo Nix deve instalar `timewarrior` via `home.packages`.
O banco de dados do Timewarrior ficará em `~/.local/share/timewarrior/` (padrão XDG).

### RF-02 — Hook de integração Taskwarrior ↔ Timewarrior
O hook oficial `on-modify.timewarrior` deve ser instalado em `~/.local/share/task/hooks/`.
O hook é um script Python distribuído junto ao Timewarrior (gerenciado via Nix).
Comportamento: `task start UUID` → Timewarrior inicia intervalo com tags da task.
Comportamento: `task stop UUID` / `task done UUID` → Timewarrior fecha o intervalo.

### RF-03 — Remoção do UDA totalactivetime
O UDA `uda.totalactivetime` deve ser removido do taskrc.
O código QML e o TaskManager devem ter toda lógica de `totalactivetime` removida.
O histórico de tempo passa a residir exclusivamente no banco do Timewarrior.

### RF-04 — Script Python de dados de tempo (`timew-summary.py`)
Um script Python intermediário deve ser criado em `~/.config/task/timew-summary.py`.
O script executa `timew export` para obter os intervalos do dia e da semana.
O script retorna um JSON com a estrutura:

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

A categorização work/personal usa os contextos do Taskwarrior:
- Tags do intervalo contêm `work` → categoria "work"
- Tags do intervalo contêm `personal` → categoria "personal"
- Projeto do intervalo é `Work` → categoria "work"
- Projeto do intervalo é `Personal` → categoria "personal"
- Caso contrário → categoria "other"

Para a `active_task`, o script executa `task export` filtrando tasks com `start` definido.

### RF-05 — Reformulação do TaskPanel (TimePanel)
O arquivo `TaskPanel.qml` deve ser reformulado para exibir métricas de tempo.
O painel é renomeado internamente para refletir o foco em tempo, mas mantém o nome
de arquivo `TaskPanel.qml` para não exigir alteração no `shell.qml`.

Layout do painel (de cima para baixo):

1. **Header** — título "Tempo" + botão refresh manual + timestamp última atualização
2. **Tarefa Ativa** — nome da task em progresso + cronômetro em tempo real (se houver)
3. **Resumo do Dia** — "Trabalho: Xh Ym | Personal: Xh Ym"
4. **Breakdown por Projeto** — lista de projetos com barra de progresso e tempo (hoje)
5. **Semana** — 7 barras (Seg–Dom) mostrando proporção work/personal por dia

### RF-06 — Cronômetro da Tarefa Ativa em Tempo Real
O campo `active_task.elapsed_seconds` do JSON é o ponto de partida.
O painel incrementa localmente a cada segundo via `Timer { interval: 1000 }`.
A cada 60 segundos o painel re-executa o script Python para atualizar todos os dados.
Se não houver tarefa ativa, o campo "Tarefa Ativa" é ocultado.

### RF-07 — Remoção dos cronômetros individuais por task
`TaskItem.qml` deve ter os blocos de cronômetro removidos:
- Propriedades `accumulatedSeconds`, `elapsedSeconds`, `timerRunning`, `pauseInProgress`
- Timer `elapsedTimer`
- Funções `updateElapsed`, `currentSessionSeconds`, `formatTime`, `timerButtonState`
- Elemento `timerButton` e `timerDisplay` do layout
- Função `pauseTask` no TaskManager
- Lógica de `totalactivetime` no `timerProcess` do TaskManager

O botão de **start/stop** da task (▶/⏹) deve ser mantido, pois ele chama `task start`/`task stop`
que ativa/desativa o Timewarrior via hook. A diferença é que o cronômetro visual
não fica mais no TaskItem — fica no painel de tempo.

**Nota**: O `TaskPanel.qml` atual (com a lista de tasks) é substituído pelo painel de tempo.
A lista de tasks pode ser removida ou mantida como painel separado — decisão: **remover**.
O usuário gerencia tasks pelo terminal com `task`, `taskwarrior-tui`, ou `task start/stop UUID`.

### RF-08 — Atualização periódica
O painel de tempo executa o script Python a cada 60 segundos via `Timer`.
Um botão manual de refresh (↻) dispara a execução imediata.
O script é executado via `Process` do QuickShell (não via systemd).

### RF-09 — Semana com barras work/personal
Para cada dia da semana (Seg–Dom), exibir uma barra segmentada:
- Segmento verde (`#a6e3a1`) = tempo trabalho
- Segmento azul (`#89b4fa`) = tempo pessoal
- Fundo vazio = sem registro
- Dia atual destacado com borda ou label em bold

### RF-10 — Configuração do Timewarrior
O arquivo `~/.config/timewarrior/timewarrior.cfg` deve ser gerenciado via
`xdg.configFile."timewarrior/timewarrior.cfg"` no módulo Nix.
Configurações mínimas: tema de cores, formato de data, exclusão de tags internas do Taskwarrior.

---

## Requisitos Não-Funcionais

### RNF-01 — Nenhum dado sensível em código
Credenciais do taskchampion não são expostas. O script Python lê apenas `timew export` e `task export`.

### RNF-02 — Sem execução de shell insegura
O script Python usa `subprocess.run` com lista de argumentos (não shell=True).
O QML usa `Process { command: [...] }` (não string de shell).

### RNF-03 — Graceful degradation
Se o Timewarrior não tiver dados (sem tasks iniciadas), o painel exibe zeros sem crashar.
Se o script Python falhar, o painel exibe a última leitura válida + indicador de erro.

### RNF-04 — Performance
O script Python deve executar em menos de 2 segundos.
O painel não bloqueia o QuickShell durante a execução do script (Process assíncrono).

### RNF-05 — Compatibilidade NixOS Unstable
Verificar nome do pacote `timewarrior` via MCP antes de codar.
O hook `on-modify.timewarrior` deve ser resolvido via path do store Nix (não hardcodado).

---

## Arquivos a Criar / Modificar

| Arquivo | Ação | Descrição |
|---------|------|-----------|
| `home/taskwarrior/default.nix` | Modificar | Adicionar `timewarrior`, instalar hook, remover totalactivetime UDA |
| `home/taskwarrior/sync-config.nix` | Modificar | Remover `uda.totalactivetime` do taskrc |
| `home/taskwarrior/timew-summary.py` | Criar | Script Python de intermediação de dados |
| `home/taskwarrior/systemd-services.nix` | Modificar | Remover serviço de cleanup de totalactivetime se existir |
| `home/quickshell/config/taskwarrior/TaskPanel.qml` | Reformular | Painel de tempo (substitui lista de tasks) |
| `home/quickshell/config/taskwarrior/TaskManager.qml` | Modificar | Remover lógica de totalactivetime/timer |
| `home/quickshell/config/taskwarrior/TaskItem.qml` | Modificar | Remover cronômetros, manter start/stop button |
| `home/quickshell/config/taskwarrior/TaskCard.qml` | Modificar | Remover headerElapsedSeconds e timer de header |
| `home/quickshell/config/taskwarrior/TimeDataManager.qml` | Criar | Componente QML que executa o script Python |

---

## Extension Configuration

| Extension | Status | Observação |
|-----------|--------|------------|
| Security Baseline | Habilitado | RF-02, RNF-01, RNF-02 aplicam as regras de segurança |
| Property-Based Testing | Desabilitado | Sem lógica de negócio complexa a testar via PBT |
