u#+  Taskwarrior + Timewarrior + QuickShell — Perguntas de Requisitos

Por favor, responda cada pergunta preenchendo a letra escolhida após a tag `[Answer]:`.
Se nenhuma opção se encaixar, escolha a última opção e descreva sua preferência.

---

## Pergunta 1
Como você quer que o Timewarrior seja integrado ao Taskwarrior?

O hook oficial `on-modify.timewarrior` sincroniza automaticamente: quando você faz `task start UUID`,
o Timewarrior inicia um intervalo com as tags da tarefa (projeto, descrição, tags).

A) Hook automático (recomendado) — instalar o hook oficial para sincronização transparente
B) Manual — manter o controle separado, chamar `timew` explicitamente via aliases no fish
C) Outro (descreva após [Answer]:)

[Answer]: A

---

## Pergunta 2
O que você quer ver no painel **TaskPanel** do QuickShell? (situação atual vs. desejada)

Hoje o painel exibe: lista de tarefas agrupadas por client, cronômetro por tarefa (HH:MM:SS).

A) Manter o layout atual + adicionar um resumo de horas do dia no topo do painel (horas trabalhadas hoje, split work/personal)
B) Reformular completamente: substituir a lista de tasks por um painel focado em tempo (gráfico/resumo do dia, sem lista de tasks)
C) Dois painéis separados: manter o TaskPanel atual intacto e adicionar um novo painel de tempo (TimePanel)
D) Outro (descreva após [Answer]:)

[Answer]: B

---

## Pergunta 3
Quais métricas de tempo você quer visualizar no QuickShell?

A) Apenas o total de horas trabalhadas hoje (ex.: "Trabalho: 4h12m | Personal: 1h30m")
B) Total por contexto (work/personal) + breakdown por projeto do dia (ex.: "Project:Work 2h | Project:Inbox 1h")
C) Total por contexto + tarefa ativa com cronômetro em tempo real + breakdown por projeto
D) Outro (descreva após [Answer]:)

[Answer]: C

---

## Pergunta 4
Como você quer separar "trabalho" de "pessoal" para as métricas?

Hoje o Taskwarrior já tem contextos definidos:
- `context.work=project:Work or +work`
- `context.personal=project:Personal or +personal`

A) Usar os contextos existentes do Taskwarrior (project:Work ou tag +work = trabalho)
B) Usar tags do Timewarrior diretamente (ex.: timew start +work, +personal)
C) Criar um UDA (campo customizado) `type` no Taskwarrior com valores work/personal
D) Outro (descreva após [Answer]:)

[Answer]: A

---

## Pergunta 5
O que acontece com o sistema atual de `totalactivetime` (UDA no Taskwarrior)?

Hoje o código persiste o tempo acumulado no campo `totalactivetime` de cada task.
Com Timewarrior, o histórico fica no banco de dados do `timew` (mais rico).

A) Manter o `totalactivetime` como backup/fallback + adicionar Timewarrior por cima
B) Migrar completamente para Timewarrior, remover o `totalactivetime` e simplificar o código QML
C) Manter ambos em paralelo permanentemente (redundância intencional)
D) Outro (descreva após [Answer]:)

[Answer]: B

---

## Pergunta 6
O cronômetro em tempo real no QuickShell (TaskItem.qml) deve continuar funcionando?

Hoje cada TaskItem exibe um cronômetro HH:MM:SS que roda no QuickShell enquanto a task está ativa.

A) Sim, manter o cronômetro por task em tempo real como está
B) Sim, mas simplificar: mostrar apenas o tempo total do dia (sem cronômetro por task)
C) Não — remover cronômetros individuais, o Timewarrior cuida do tracking no background
D) Outro (descreva após [Answer]:)

[Answer]: C

---

## Pergunta 7
Como o QuickShell vai buscar os dados do Timewarrior?

A) Rodar `timew export` (JSON) ou `timew summary` via Process do QuickShell, igual ao `task export` atual
B) Script Python intermediário que processa os dados do `timew` e retorna JSON simples
C) Outro (descreva após [Answer]:)

[Answer]: B

---

## Pergunta 8
Com qual frequência os dados de tempo devem ser atualizados no QuickShell?

A) A cada 30 segundos (polling leve)
B) A cada 60 segundos
C) Só quando há mudança de tarefa (via sinal do Taskwarrior) + reload manual
D) Outro (descreva após [Answer]:)

[Answer]: B

---

## Pergunta 9
Você quer relatórios/histórico além do dia atual?

A) Não, apenas hoje é suficiente no QuickShell
B) Sim, quero ver a semana atual (total por dia da semana)
C) Sim, quero ver ontem e hoje (comparação)
D) Outro (descreva após [Answer]:)

[Answer]: B

---

## Pergunta 10
Sobre as extensões de qualidade:

**Security Baseline**: Aplica regras de segurança ao código gerado (validação de inputs, sem execução de shell insegura, etc.)

A) Habilitar Security Baseline
B) Pular Security Baseline

[Answer]: A

---
