# QuickShell Pomodoro — Code Generation Plan

## Steps

- [x] Step 1: Criar `home/pomodoro.nix` — instala tomat + configura systemd user service
- [x] Step 2: Criar `home/quickshell/config/pomodoro/PomodoroManager.qml` — polling `tomat status`, expõe propriedades reativas
- [x] Step 3: Criar `home/quickshell/config/pomodoro/PomodoroPanel.qml` — UI completa com controles e cores por fase
- [x] Step 4: Modificar `home/default.nix` — adicionar `./pomodoro.nix`
- [x] Step 5: Modificar `home/quickshell/config/shell.qml` — adicionar PomodoroPanel após GitHubPanel
- [x] Step 6: Validar com `nix flake check --no-build` — ✅ zero errors
