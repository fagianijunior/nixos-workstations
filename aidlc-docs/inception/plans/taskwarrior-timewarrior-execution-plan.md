# Plano de Execução: Taskwarrior + Timewarrior + QuickShell

**Feature**: Reformulação do sistema de tasks com rastreamento de tempo  
**Data**: 2026-08-20  
**Tipo**: Brownfield — modificação de módulos existentes  
**Risco**: Médio (reformulação de QML existente + novo componente Python/Timewarrior)

---

## Workflow

```
INCEPTION
  [x] Workspace Detection       — Brownfield, sem reverse engineering necessário
  [x] Requirements Analysis     — CONCLUÍDO (taskwarrior-timewarrior-requirements.md)
  [ ] Workflow Planning         — EM ANDAMENTO
  SKIP User Stories             — Feature de monitoring, sem múltiplos user types
  SKIP Application Design       — Sem novos componentes complexos
  SKIP Units Generation         — Unidade única

CONSTRUCTION
  SKIP Functional Design        — Sem business logic nova
  SKIP NFR Requirements         — Capturados nos RNFs do documento de requisitos
  SKIP NFR Design               — Patterns já usados no projeto (Process QML, subprocess Python)
  SKIP Infrastructure Design    — Timewarrior é local, sem infra nova
  [ ] Code Generation           — Executar (Plan + Generate)
  [ ] Build and Test            — Executar

OPERATIONS
  [ ] Operations                — Placeholder (sem deploy automation)
```

---

## Unidade de Trabalho: taskwarrior-timewarrior

### Escopo
Reformular o sistema de rastreamento de tempo do Taskwarrior + QuickShell,
adicionando Timewarrior com hook automático e substituindo o TaskPanel atual
por um painel focado em métricas de tempo (diário + semanal).

### Arquivos envolvidos

#### Criar (3 novos)
| Arquivo | Descrição |
|---------|-----------|
| `home/taskwarrior/timew-summary.py` | Script Python: executa `timew export` + `task export`, retorna JSON de métricas |
| `home/quickshell/config/taskwarrior/TimeDataManager.qml` | Componente QML: executa script Python, expõe dados para o painel |
| `tests/taskwarrior-timewarrior-test.nix` | Teste NixOS para validar instalação do Timewarrior e hook |

#### Modificar (6 existentes)
| Arquivo | Modificações |
|---------|-------------|
| `home/taskwarrior/default.nix` | + `timewarrior`, instalar hook via symlink Nix, remover `uda.totalactivetime`, adicionar `timew-summary.py` no configFile |
| `home/taskwarrior/sync-config.nix` | Remover `uda.totalactivetime.type` e `uda.totalactivetime.label` do taskrc |
| `home/quickshell/config/taskwarrior/TaskPanel.qml` | Reformular completamente: remover lista de tasks, adicionar painel de tempo |
| `home/quickshell/config/taskwarrior/TaskManager.qml` | Remover lógica de `totalactivetime`/`timerProcess`/`pauseTask` |
| `home/quickshell/config/taskwarrior/TaskItem.qml` | Remover cronômetros e timer button, manter status button e start/stop |
| `home/quickshell/config/taskwarrior/TaskCard.qml` | Remover `headerElapsedSeconds`, timer de header, `formatTime` |

**Total**: 3 novos + 6 modificados = 9 arquivos

---

## Sequência de Execução (Code Generation)

A ordem respeita dependências:

1. Criar `timew-summary.py` — base de dados, sem dependências
2. Criar `TimeDataManager.qml` — consome o script Python
3. Modificar `TaskPanel.qml` — consome TimeDataManager, novo layout
4. Modificar `TaskManager.qml` — remoção de lógica de timer
5. Modificar `TaskItem.qml` — remoção de cronômetros
6. Modificar `TaskCard.qml` — remoção de timer de header
7. Modificar `home/taskwarrior/default.nix` — instala timewarrior + hook + script
8. Modificar `home/taskwarrior/sync-config.nix` — remove UDA totalactivetime do taskrc
9. Criar `tests/taskwarrior-timewarrior-test.nix` — validação
10. Executar `nix flake check --no-build`

---

## Avaliação de Risco

| Risco | Probabilidade | Mitigação |
|-------|--------------|-----------|
| Nome do pacote `timewarrior` mudou no nixpkgs-unstable | Baixa | Verificar via MCP antes de codar |
| Hook `on-modify.timewarrior` — path no store Nix | Média | Resolver via `${pkgs.timewarrior}/share/doc/timew/ext/on-modify.timewarrior` ou path equivalente |
| `timew export` retorna formato diferente do esperado | Baixa | Testar com dados reais; script tem tratamento de erro |
| TaskPanel reformulado quebra o layout do shell.qml | Baixa | `implicitHeight` mantido, interface com shell.qml não muda |
| Dados históricos de `totalactivetime` perdidos | Intencional | Documentado no RF-05: migração decidida pelo usuário |

---

## Estimativa
- Arquivos novos: 3
- Arquivos modificados: 6  
- Complexidade: Média
- Tempo estimado: ~1 sessão de Code Generation

---

## Critérios de Conclusão
- [ ] `nix flake check --no-build` passa sem erros
- [ ] Hook instalado em `~/.local/share/task/hooks/on-modify.timewarrior`
- [ ] Script Python retorna JSON válido com `timew export` real
- [ ] TaskPanel.qml exibe: tarefa ativa + resumo do dia + breakdown + barras da semana
- [ ] `totalactivetime` removido do taskrc e do código QML
