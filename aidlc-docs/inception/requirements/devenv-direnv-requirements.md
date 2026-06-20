# Devenv + Direnv Integration — Requirements

## Intent Analysis

- **User Request**: Adicionar e configurar devenv e direnv na configuração NixOS/Home Manager
- **Request Type**: Enhancement (melhorar configuração existente + adicionar nova ferramenta)
- **Scope**: Multiple Components (módulo NixOS de sistema + configuração Home Manager)
- **Complexity**: Simple (ferramentas bem documentadas, integração direta)

## Context

O projeto já possui:
- `programs.direnv.enable = true` com `nix-direnv.enable = true` em `home/default.nix`
- `nix.settings.trusted-users = [ "root" "@wheel" ]` em `modules/common/default.nix`
- `nix.settings.experimental-features = [ "nix-command" "flakes" ]` em `modules/common/default.nix`
- Git `.gitignore` já inclui `.direnv`

O usuário `terabytes` pertence ao grupo `wheel`, portanto já é trusted via `@wheel`.

---

## Functional Requirements

### FR-01: Instalação do devenv (sistema)
Instalar o pacote `devenv` em `environment.systemPackages` para disponibilizá-lo em todo o sistema.

### FR-02: Cache binário do devenv
Adicionar `https://devenv.cachix.org` como substituter nas configurações Nix do sistema, com a chave pública correspondente em `trusted-public-keys`.

### FR-03: Módulo NixOS dedicado para configurações Nix avançadas
Criar um módulo NixOS dedicado (ex: `modules/common/nix-settings.nix`) que contenha:
- Substituters adicionais (devenv cachix)
- Trusted public keys
- Configuração de devenv no sistema

Este módulo será importado pelo `modules/common/default.nix` ou diretamente pelos hosts.

### FR-04: Trusted users
Manter a configuração existente `trusted-users = [ "root" "@wheel" ]` que já cobre o usuário `terabytes`. Não é necessário alteração adicional, mas documentar que isso já satisfaz o requisito do devenv.

### FR-05: Configuração avançada do direnv.toml
Configurar `programs.direnv.config` no Home Manager com:
- `global.warn_timeout` — configurar timeout de aviso (ex: "30s")
- `global.hide_env_diff` — esconder diff de variáveis de ambiente (`true`)

### FR-06: Silenciar logs do direnv
Habilitar `programs.direnv.silent = true` para reduzir verbosidade no shell.

### FR-07: Manter nix-direnv habilitado
Preservar `programs.direnv.nix-direnv.enable = true` existente (essencial para performance com devenv).

---

## Non-Functional Requirements

### NFR-01: Compatibilidade
- O devenv deve funcionar em ambos os hosts (Nobita e Doraemon)
- A configuração deve ser compatível com `nixos-unstable`

### NFR-02: Segurança
- Não expor chaves ou secrets na configuração
- Usar apenas substituters oficiais e verificáveis
- Manter `trusted-users` restrito a `root` e `@wheel`

### NFR-03: Manutenibilidade
- A configuração deve seguir o padrão modular existente do projeto
- Documentar a integração devenv/direnv na configuração

### NFR-04: Testabilidade
- Adicionar teste NixOS que valide a presença do devenv e direnv configurados
- Teste deve usar `pkgs.testers.nixosTest`

---

## Technical Decisions

| Decisão | Escolha | Justificativa |
|---------|---------|---------------|
| Instalação devenv | `environment.systemPackages` | Disponível para todo o sistema |
| Cache binário | `https://devenv.cachix.org` | Evitar recompilação desnecessária |
| Trusted users | Manter `@wheel` existente | Já cobre o usuário terabytes |
| direnv.toml | Via `programs.direnv.config` | Home Manager gerencia nativamente |
| Módulo de settings | `modules/common/nix-settings.nix` ou inline em `common/default.nix` | Separação de concerns |
| Silent mode | `programs.direnv.silent = true` | Reduzir ruído no shell |

---

## Extension Configuration

| Extension | Enabled | Decided At | Notes |
|-----------|---------|-----------|-------|
| Security Baseline | Yes | Requirements Analysis | Full enforcement |
| Property-Based Testing | No | Requirements Analysis | Sem lógica de negócio neste escopo |

---

## Files to Modify/Create (Estimated)

1. `modules/common/default.nix` — Adicionar substituters e trusted-public-keys do devenv, adicionar devenv ao systemPackages
2. `home/default.nix` — Adicionar `programs.direnv.config` e `programs.direnv.silent`
3. `tests/devenv-direnv-test.nix` — Novo teste de integração
4. `flake.nix` — Adicionar check do novo teste

---

## Out of Scope

- Criação de templates de projetos devenv
- Configuração de linguagens específicas dentro do devenv
- Integração com CI/CD
- Configuração de hooks do devenv (pre-commit, etc.)
