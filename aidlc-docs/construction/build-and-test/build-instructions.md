# Build Instructions — Devenv + Direnv Integration

## Prerequisites
- **Build Tool**: Nix (with flakes enabled)
- **System**: NixOS com nixos-unstable
- **Flake**: `/home/terabytes/Workspace/fagianijunior/nixos/flake.nix`

## Build Steps

### 1. Validate Flake Evaluation
```bash
cd ~/Workspace/fagianijunior/nixos
nix flake check --no-build
```

### 2. Build NixOS Configuration (Nobita)
```bash
sudo nixos-rebuild build --flake .#nobita
```

### 3. Build NixOS Configuration (Doraemon)
```bash
sudo nixos-rebuild build --flake .#doraemon
```

### 4. Apply Configuration (switch)
```bash
sudo nixos-rebuild switch --flake .#$(hostname)
```

## Verify Build Success
- **Expected Output**: `nix flake check --no-build` retorna 0 sem erros
- **Build Artifacts**: Derivações no `/nix/store`
- **Common Warnings**: `Git tree is dirty` (normal antes de commit)

## Troubleshooting

### "Path not tracked by Git"
- **Cause**: Novo arquivo criado mas não adicionado ao Git
- **Solution**: `git add <file>` antes de rodar `nix flake check`

### "error: attribute 'devenv' missing"
- **Cause**: nixpkgs não contém devenv (improvável em unstable)
- **Solution**: Verificar que flake.lock está atualizado: `nix flake update`
