# Build Instructions — QuickShell GitHub Session

## Prerequisites
- **Build Tool**: Nix Flakes (nixos-unstable)
- **Dependencies**: QuickShell runtime, `gh` CLI autenticado (`gh auth login`)
- **Environment Variables**: Nenhuma adicional
- **System Requirements**: NixOS com QuickShell configurado

## Build Steps

### 1. Validate Flake
```bash
cd /home/terabytes/Workspace/fagianijunior/nixos
nix flake check --no-build
```

### 2. Rebuild NixOS (aplica as alterações)
```bash
# Nobita (desktop)
sudo nixos-rebuild switch --flake .#nobita

# Doraemon (notebook)
sudo nixos-rebuild switch --flake .#doraemon
```

### 3. Verify Build Success
- **Expected Output**: `all checks passed!` no `nix flake check`
- **Build Artifacts**: QML files copiados para `~/.config/quickshell/` via Home Manager (xdg.configFile)
- **Common Warnings**: Nenhum esperado

## Troubleshooting

### QuickShell não carrega o painel GitHub
- **Causa**: Arquivo QML com erro de sintaxe ou import faltando
- **Solução**: Verificar logs do QuickShell: `journalctl --user -u quickshell -f`

### `gh` CLI não autenticado
- **Causa**: Token OAuth expirado ou não configurado
- **Solução**: `gh auth login` e selecionar GitHub.com com OAuth
