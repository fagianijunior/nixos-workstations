# Devenv + Direnv Integration — Perguntas de Requisitos

Por favor, responda cada pergunta preenchendo a letra após o tag [Answer]:.

---

## Question 1
Você já possui `programs.direnv` habilitado com `nix-direnv.enable = true` no `home/default.nix`. O que exatamente precisa ser adicionado/alterado?

A) Instalar apenas o pacote `devenv` (CLI) — a integração direnv/nix-direnv já está correta
B) Instalar `devenv` e adicionar configuração de cache do devenv (cachix, trusted settings, etc.)
C) Revisar toda a configuração direnv + devenv: adicionar devenv CLI, configurar nix trusted settings, cache binário do devenv, e direnv.toml com opções avançadas
D) Apenas ajustar a configuração do direnv existente (sem adicionar devenv)
X) Other (please describe after [Answer]: tag below)

[Answer]: C

---

## Question 2
O devenv utiliza o cache binário do Cachix (`https://devenv.cachix.org`). Como deseja configurar isso?

A) Adicionar substituter `https://devenv.cachix.org` nas trusted nix settings do sistema (nix.settings)
B) Não preciso de cache — posso compilar tudo localmente
C) Já está configurado em outro lugar (pular)
X) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Question 3
O `devenv` precisa de `nix.settings.trusted-users` para funcionar corretamente em modo flake. Deseja configurar isso?

A) Sim — adicionar meu usuário (`terabytes`) e `root` em `nix.settings.trusted-users`
B) Já está configurado — pular
C) Não quero alterar trusted-users
X) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Question 4
Deseja configurar opções adicionais no `direnv.toml` (via `programs.direnv.config`)?

A) Sim — habilitar `warn_timeout` (aviso se o direnv demorar), `hide_env_diff` (esconder diff de variáveis), e silenciar logs
B) Sim — apenas silenciar logs (`programs.direnv.silent = true`)
C) Não — manter configuração direnv atual sem alterações
X) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Question 5
Onde deve ficar a configuração de Nix trusted settings e substituters? (Configurações de sistema)

A) Em um módulo NixOS dedicado (ex: `modules/nix-settings.nix` ou no host config)
B) No arquivo de host existente (`hosts/nobita/default.nix` e `hosts/doraemon/default.nix`)
C) Já existe um módulo para isso — apenas adicionar as entradas de devenv
X) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Question 6
Deseja que o `devenv` seja instalado via `home.packages` (disponível para o usuário) ou em `environment.systemPackages` (disponível para todos)?

A) `home.packages` — apenas para o usuário `terabytes` via Home Manager
B) `environment.systemPackages` — disponível no sistema inteiro
X) Other (please describe after [Answer]: tag below)

[Answer]: B

---

## Question 7: Security Extensions
Devem ser aplicadas as regras de segurança (Security Baseline) para este projeto?

A) Sim — aplicar todas as regras SECURITY como constraints bloqueantes (recomendado para configurações de produção)
B) Não — pular regras SECURITY (adequado para PoCs, protótipos e projetos experimentais)
X) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Question 8: Property-Based Testing Extension
Devem ser aplicadas as regras de Property-Based Testing (PBT) para este projeto?

A) Sim — aplicar todas as regras PBT como constraints bloqueantes
B) Parcial — aplicar regras PBT apenas para funções puras e round-trips de serialização
C) Não — pular regras PBT (adequado para configurações NixOS simples sem lógica de negócio significativa)
X) Other (please describe after [Answer]: tag below)

[Answer]: C

---
