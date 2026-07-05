# QuickShell GitHub Session — Perguntas de Requisitos

Por favor, responda cada pergunta preenchendo a letra correspondente após a tag [Answer]:

## Question 1
O painel GitHub deve respeitar a flag `sensitiveData` (modo privacidade com dunst) e ficar oculto quando ativado?

A) Sim — ocultar completamente quando sensitiveData está ativo (mesmo padrão de CalendarPanel e TaskPanel)
B) Não — sempre visível independente do modo privacidade
C) Parcial — mostrar o header/botão reload mas ocultar dados (contagens e repos)
X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 2
Quais tipos de notificações do GitHub devem ser contados? O `gh api notifications` retorna todas as notificações não lidas.

A) Apenas notificações não lidas (padrão do GitHub)
B) Todas as notificações (lidas + não lidas) das últimas 24h
C) Apenas menções e review requests
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 3
Para PRs e Issues, qual escopo de repositórios listar?

A) Todos os repositórios onde tenho PRs/Issues atribuídas ou que eu criei
B) Somente repositórios que eu configurar manualmente (lista fixa no código)
C) Repositórios com atividade recente (último mês)
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 4
Os cards de repositório devem mostrar PRs e Issues separadamente. Quais estados considerar?

A) Apenas PRs/Issues abertas (open)
B) PRs/Issues abertas + recentemente fechadas (últimos 7 dias)
C) Apenas PRs/Issues onde sou autor ou assignee
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 5
Posição do painel GitHub dentro do shell.qml — onde deseja inseri-lo na lista vertical de componentes?

A) Antes do CalendarPanel (topo, após hostname/clock)
B) Após o CalendarPanel (abaixo da agenda)
C) Após o TaskPanel (após as tarefas)
D) No final, antes do NetworkMonitor/NotificationPanel
X) Other (please describe after [Answer]: tag below)

[Answer]: D

## Question 6
Estrutura de arquivos — seguir o mesmo padrão do TaskWarrior com pasta dedicada?

A) Sim — criar `home/quickshell/config/github/` com os QML separados (GitHubPanel.qml, GitHubDataManager.qml, RepoCard.qml)
B) Arquivo único — tudo em um só `home/quickshell/config/github/GitHubPanel.qml`
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 7: Security Extensions
Devem ser aplicadas as regras de segurança (Security Baseline) para este projeto?

A) Sim — aplicar todas as regras de SEGURANÇA como constraints bloqueantes (recomendado para aplicações em produção)
B) Não — pular todas as regras de SEGURANÇA (adequado para PoCs, protótipos e projetos experimentais)
X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 8: Property-Based Testing Extension
Deve ser aplicado Property-Based Testing (PBT) para este projeto?

A) Sim — aplicar todas as regras de PBT como constraints bloqueantes (recomendado para projetos com lógica de negócio)
B) Parcial — aplicar PBT apenas para funções puras e round-trips de serialização
C) Não — pular todas as regras de PBT (adequado para CRUD simples, projetos UI-only, ou camadas de integração sem lógica significativa)
X) Other (please describe after [Answer]: tag below)

[Answer]: C
