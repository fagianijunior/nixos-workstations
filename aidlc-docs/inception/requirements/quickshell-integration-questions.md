# QuickShell Integration — Perguntas de Esclarecimento

Analisei a configuração do QuickShell em `to_implement/quickshell/`. Preciso esclarecer alguns pontos antes de prosseguir.

## Question 1
No `default.nix` do QuickShell, o path do symlink aponta para `~/Workspace/fagianijunior/dotfiles/home/quickshell/config`. Porém o repositório atual está em `~/Workspace/fagianijunior/nixos/`. Qual o path correto para o symlink da configuração do QuickShell?

A) `~/Workspace/fagianijunior/nixos/home/quickshell/config` (mesmo repositório, pasta `home/quickshell/config`)
B) `~/Workspace/fagianijunior/dotfiles/home/quickshell/config` (repositório separado "dotfiles")
C) Other (please describe after [Answer]: tag below)

[Answer]: A. Caso haja forma melhor de se adequar não precisa usar o código "ipsis litteris".

## Question 2
O script `get_events.py` depende de um `credentials.json` (Google Calendar API) no diretório do config. Como deseja tratar esse arquivo?

A) O `credentials.json` já existe no path e será usado como está (não commitado no repo — gerenciado manualmente)
B) Não utilizo mais a integração com Google Calendar — pode remover o `get_events.py` e as dependências Python de Google API
C) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 3
Na pasta `to_implement/quickshell/config/taskwarrior/` existem vários arquivos de verificação/documentação (CHECKPOINT*.md, TASK_*.md, FINAL_VALIDATION_REPORT.md, CONNECTION_PATTERN.md, ConnectionExample.qml). Estes são artefatos de desenvolvimento que devem ser excluídos da configuração final?

A) Sim, excluir todos os .md e ConnectionExample.qml da pasta taskwarrior (manter apenas os .qml funcionais: TaskPanel, TaskManager, TaskItem, TaskCard, DataWatcher)
B) Manter tudo como está
C) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 4
O QuickShell usa `dunstctl` para controle de notificações (pause/toggle sensitive data). Porém no `home/default.nix` atual você usa `services.dunst`. Confirma que dunst continua sendo o notificador e o QuickShell integra com ele via `dunstctl`?

A) Sim, dunst é o notificador e QuickShell integra via dunstctl
B) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 5
A pasta `to_implement/quickshell/config/taskwarrior/tests/` contém testes QML. Deseja manter esses testes no projeto ou são artefatos de desenvolvimento que podem ser excluídos?

A) Excluir os testes QML (são artefatos de dev, não parte da config runtime)
B) Manter os testes QML na configuração
C) Other (please describe after [Answer]: tag below)

[Answer]: A
