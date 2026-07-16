# QuickShell Pomodoro — Requisitos

## Intent Analysis
- **User Request**: Adicionar sistema Pomodoro ao QuickShell usando tomat
- **Request Type**: New Feature
- **Scope**: Single new panel + integração shell.qml + systemd user service
- **Complexity**: Simple — painel QML com Process/Timer polling CLI

---

## Context

`tomat` é um timer Pomodoro com arquitetura daemon + cliente, disponível em nixpkgs-unstable.
O daemon persiste o estado do timer independentemente do painel.

Comandos relevantes:
- `tomat daemon start` / `stop` — gerencia o daemon (via systemd user service)
- `tomat status` — retorna JSON: `{"text","tooltip","class","percentage"}`
- `tomat start` — inicia nova sessão de trabalho (25 min padrão)
- `tomat stop` — para a sessão atual
- `tomat pause` / `resume` / `toggle` — pausa/retoma
- `tomat skip` — pula para a próxima fase

Classes JSON retornadas por `tomat status`:
- `idle` — sem sessão ativa
- `work` — sessão de trabalho ativa
- `work-paused` — sessão de trabalho pausada
- `break` — pausa curta ativa
- `break-paused` — pausa curta pausada
- `long-break` — pausa longa ativa

Exemplo de output:
```json
{"text":"🍅 24:59 ▶","tooltip":"Work (1/4) - 25.0min","class":"work","percentage":0.06}
```

---

## Functional Requirements

### FR-1: Daemon via systemd user service
- O daemon `tomat` é iniciado automaticamente via `systemd.user.services` no Home Manager
- Inicia com o usuário, reinicia automaticamente se cair

### FR-2: Exibição do Timer
- O painel exibe o campo `text` retornado pelo `tomat status` (já formatado com emoji + MM:SS + estado)
- Exibe o campo `tooltip` como subtítulo (fase + sessão)
- Atualiza a cada 5 segundos via polling

### FR-3: Controles
- Botão **Start** — executa `tomat start` (visível apenas no estado `idle`)
- Botão **Pause/Resume** — executa `tomat toggle` (visível quando sessão ativa)
- Botão **Stop** — executa `tomat stop` (visível quando sessão ativa)
- Botão **Skip** — executa `tomat skip` (visível quando sessão ativa)

### FR-4: Visual por fase
- Cor do painel varia por `class`:
  - `work` / `work-paused`: `#f38ba8` (red — Catppuccin)
  - `break` / `break-paused`: `#a6e3a1` (green)
  - `long-break`: `#89b4fa` (blue)
  - `idle`: `#6c7086` (subtext0)

### FR-5: Integração com shell.qml
- Painel posicionado após o `TaskPanel` e antes do `DiskMonitor`
- Sempre visível (não respeita `sensitiveData`)

---

## Non-Functional Requirements

### NFR-1: Performance
- Polling a cada 5 segundos — sem impacto perceptível de CPU

### NFR-2: Resiliência
- Se `tomat status` retornar erro (daemon não disponível), exibir estado idle sem crash

### NFR-3: Manutenibilidade
- Painel em pasta dedicada `home/quickshell/config/pomodoro/`
- Dois arquivos: `PomodoroManager.qml` (polling/dados) + `PomodoroPanel.qml` (UI)
- Módulo Nix em `home/pomodoro.nix`

---

## Extension Configuration
| Extension | Enabled | Decided At |
|---|---|---|
| Security Baseline | No | Requirements Analysis |
| Property-Based Testing | No | Requirements Analysis |

---

## Technical Decisions

| Decisão | Escolha | Motivo |
|---|---|---|
| Ferramenta | `tomat` | Daemon persistente, JSON nativo, pause/skip nativos |
| Instalação | Home Manager (`home.packages`) | Pacote do usuário terabytes |
| Daemon | `systemd.user.services` via HM | Inicia com sessão, persiste timer |
| Status parsing | `JSON.parse()` no QML | Output já é JSON estruturado |
| Polling | 5s via Timer + Process | Simples, sem socket direto do QML |
| Histórico | `tooltip` do tomat | Exibe `Work (N/4)` nativamente |
