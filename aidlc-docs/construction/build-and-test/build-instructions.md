# Build Instructions — Neovim Integration

## Prerequisites
- **Build Tool**: Nix Flakes (nix >= 2.18)
- **Dependencies**: Gerenciadas pelo flake.lock (pinned)
- **Environment Variables**: Nenhuma necessária
- **System Requirements**: NixOS ou Nix instalado em qualquer Linux

## Build Steps

### 1. Avaliação do Flake (Verificação de Sintaxe e Tipagem)
```bash
cd /home/terabytes/Workspace/fagianijunior/nixos
nix flake check --no-build
```
**Resultado esperado**: `all checks passed`

### 2. Build da Configuração Completa (Opcional — Build Completo)
```bash
# Build da configuração do Nobita (inclui Neovim via Home Manager)
nix build .#nixosConfigurations.nobita.config.system.build.toplevel --no-link

# Build da configuração do Doraemon
nix build .#nixosConfigurations.doraemon.config.system.build.toplevel --no-link
```
**Nota**: Build completo requer download de todos os pacotes. Pode levar 10-30 minutos na primeira execução.

### 3. Build do Teste de Neovim (VM Test)
```bash
nix build .#checks.x86_64-linux.neovim
```
**Nota**: Executa o teste em uma VM NixOS. Requer KVM habilitado.

### 4. Aplicar Configuração no Sistema (Deploy)
```bash
# No host alvo (Nobita ou Doraemon):
sudo nixos-rebuild switch --flake ~/Workspace/fagianijunior/nixos#$(hostname)
```

## Verificação Pós-Deploy

```bash
# Verificar que Neovim está instalado e funcional
nvim --version

# Verificar que LSPs estão disponíveis
which nixd terraform-ls solargraph intelephense pyright lua-language-server bash-language-server dockerfile-language-server

# Verificar que formatadores estão disponíveis
which nixpkgs-fmt prettier stylua rubocop php-cs-fixer black shfmt terraform

# Verificar que Neovim inicia sem erros
nvim --headless +qall
```

## Troubleshooting

### Build Fails com "not tracked by Git"
- **Causa**: Arquivos novos não foram adicionados ao Git
- **Solução**: `git add home/neovim/ tests/neovim-test.nix`

### Build Fails com "unfree package"
- **Causa**: `intelephense` é unfree
- **Solução**: Verificar que `nixpkgs.config.allowUnfree = true` está em `modules/services/gaming.nix` (já configurado)

### Build Fails com "renamed option"
- **Causa**: API mudou no nixos-unstable
- **Solução**: Adotar nova API imediatamente. Verificar steering rules em `.kiro/steering/nix-unstable.md`
