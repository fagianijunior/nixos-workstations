---
inclusion: fileMatch
fileMatchPattern: "**/*.nix"
---

# NixOS Unstable API Rules

Este projeto usa `nixos-unstable` e `home-manager` master (follows nixpkgs). As APIs mudam frequentemente.

## Regras obrigatórias ao gerar ou modificar código Nix:

1. **NUNCA confiar no conhecimento de treinamento para opções NixOS/Home Manager**. Sempre verificar via:
   - MCP tool `mcp_nixos_nix` com `action: "search"` e `type: "options"` para opções NixOS
   - MCP tool `mcp_nixos_nix` com `action: "search"` e `source: "home-manager"` para opções Home Manager
   - `nix flake check` após qualquer modificação

2. **Ao encontrar um evaluation warning de renamed option**: adotar a nova API imediatamente. Nunca reverter para a API antiga.

3. **Ao encontrar um erro de pacote renamed/removed**: buscar o novo nome via MCP antes de adivinhar.

4. **Prioridade de fontes de verdade**:
   - 1º: Saída de `nix flake check` (verdade absoluta)
   - 2º: MCP nixos tool (indexado, pode ter delay)
   - 3º: Código existente no repositório (o usuário pode já estar usando a API correta)
   - 4º: Conhecimento de treinamento (ÚLTIMO recurso, possivelmente desatualizado)

5. **Se o usuário já escreveu código usando uma API**: assumir que o usuário está correto e verificar com `nix flake check` antes de "corrigir" para uma forma diferente.

## APIs conhecidas como atualizadas (nixos-unstable 2025+):

- `hardware.graphics` (não `hardware.opengl`)
- `hardware.graphics.enable32Bit` (não `hardware.opengl.driSupport32Bit`)
- `services.pulseaudio` (não `hardware.pulseaudio`)
- `pkgs.testers.nixosTest` (não `pkgs.nixosTest`)
- `pkgs.nerd-fonts.jetbrains-mono` (não `pkgs.nerdfonts`)
- `pkgs.noto-fonts-color-emoji` (não `pkgs.noto-fonts-emoji`)
- `pkgs.mesa-demos` (não `pkgs.glxinfo`)
- `pkgs.tuigreet` (não `pkgs.greetd.tuigreet`)
- `systemd.coredump.settings.Coredump` (não `systemd.coredump.extraConfig`)
- `services.logind.settings.Login.HandleLidSwitch` (não `services.logind.lidSwitch`)
- `services.resolved.settings.Resolve.DNSSEC` (não `services.resolved.dnssec`)
- Home Manager: `programs.git.settings.user.name` (não `programs.git.userName`)
- Home Manager: `programs.git.settings.alias` (não `programs.git.aliases`)
- Home Manager: `programs.git.settings` (não `programs.git.extraConfig`)
- Home Manager: `catppuccin.homeModules.catppuccin` (não `catppuccin.homeManagerModules.catppuccin`)
- RADV é o default Vulkan driver (amdvlk foi removido)
