# QuickShell Pomodoro — Perguntas de Requisitos

Por favor, responda cada pergunta preenchendo a letra escolhida após a tag `[Answer]:`.

---

## Question 1
Como o painel Pomodoro deve ser integrado ao QuickShell?

A) Seção sempre visível no shell.qml (como os monitors de sistema)
B) Seção visível apenas quando uma sessão Pomodoro estiver ativa
C) Outro (descreva após `[Answer]:`)

[Answer]: A

---

## Question 2
Quais controles o painel deve exibir?

A) Start / Pause / Stop + contagem regressiva
B) Start / Pause / Stop / Skip (pular para próxima fase) + contagem regressiva
C) Apenas a contagem regressiva + status (sem botões — controlado pelo terminal)
D) Outro (descreva após `[Answer]:`)

[Answer]: A

---

## Question 3
O painel deve exibir o histórico de sessões (quantos pomodoros completados hoje)?

A) Sim — exibir contador de pomodoros completados na sessão atual / no dia
B) Não — apenas o timer atual
C) Outro (descreva após `[Answer]:`)

[Answer]: A

---

## Question 4
Como o status do `openpomodoro-cli` deve ser consultado pelo QuickShell?

A) Polling com `op status` a cada segundo (via Process/Timer)
B) Polling a cada 5 segundos (menos agressivo, aceitando pequena defasagem)
C) Outro (descreva após `[Answer]:`)

[Answer]: B

---

## Question 5
O openpomodoro-cli deve ser instalado via NixOS (system packages) ou Home Manager (user packages)?

A) Home Manager — pacote do usuário `terabytes`
B) System packages — disponível para todos os usuários
C) Outro (descreva após `[Answer]:`)

[Answer]: C. Ele já está instalado.

---

## Question 6
O painel deve respeitar o modo `sensitiveData` (ocultar quando Dunst está pausado, como o TaskPanel)?

A) Sim — ocultar quando sensitiveData=true
B) Não — sempre visível independente do modo sensitivo
C) Outro (descreva após `[Answer]:`)

[Answer]: B

---

## Question 7
Onde no shell.qml o painel Pomodoro deve aparecer?

A) Antes dos monitores de sistema (CPU/GPU/Memória)
B) Entre os monitores de sistema e o BatteryGraph
C) Entre o BatteryGraph e o TaskPanel
D) Após o TaskPanel (antes do DiskMonitor)
E) Outro (descreva após `[Answer]:`)

[Answer]: E. Após as Tasks.

---

## Question 8: Security Extension
As regras de Security Baseline devem ser aplicadas neste projeto?

A) Sim — aplicar como restrições obrigatórias
B) Não — pular (adequado para painel local sem dados sensíveis)
C) Outro (descreva após `[Answer]:`)

[Answer]: B

---

## Question 9: Property-Based Testing Extension
As regras de Property-Based Testing devem ser aplicadas?

A) Sim — aplicar para lógica de negócio e transformações de dados
B) Não — pular (painel de UI, sem lógica algorítmica complexa)
C) Outro (descreva após `[Answer]:`)

[Answer]: B
