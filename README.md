# NixOS Workstations

Configuração NixOS declarativa para duas máquinas usando Nix Flakes.

## Máquinas

| Host | Tipo | CPU | GPU |
|------|------|-----|-----|
| **Nobita** | Desktop | AMD Ryzen 7 5700 | AMD Navi 23 RX 6600 XT |
| **Doraemon** | Notebook (Lenovo IdeaPad Slim 3 15ARP10) | AMD Ryzen 7 7735HS | AMD Rembrandt RADEON 680M |

## Stack

- **NixOS** (nixos-unstable)
- **Hyprland** (Wayland compositor)
- **Catppuccin Macchiato** (tema system-wide)
- **Home Manager** (configurações do usuário)
- **PipeWire** (áudio)
- **iwd** + **systemd-networkd** (rede)
- **Btrfs** + **LUKS** (filesystem + criptografia)
- **systemd-boot** (bootloader)

## Estrutura


```
.
├── flake.nix                 # Entrypoint do flake
├── hosts/
│   ├── nobita/               # Desktop config
│   └── doraemon/             # Notebook config
├── modules/
│   ├── common/               # Base system (locale, user, boot)
│   ├── desktop/              # Hyprland, Catppuccin
│   ├── hardware/             # AMD GPU, Bluetooth
│   ├── security/             # Firewall, kernel hardening
│   └── services/             # PipeWire, iwd, gaming, TLP
├── home/                     # Home Manager (user terabytes)
└── tests/                    # NixOS VM tests (runNixOSTest)
```

## Uso

### Build e Switch

```bash
# Nobita (desktop)
sudo nixos-rebuild switch --flake .#nobita

# Doraemon (notebook)
sudo nixos-rebuild switch --flake .#doraemon
```

### Testes

```bash
# Rodar todos os testes
nix flake check

# Rodar um teste específico
nix build .#checks.x86_64-linux.boot
nix build .#checks.x86_64-linux.pipewire
nix build .#checks.x86_64-linux.networking
nix build .#checks.x86_64-linux.bluetooth
nix build .#checks.x86_64-linux.gpu
nix build .#checks.x86_64-linux.hyprland
nix build .#checks.x86_64-linux.security
nix build .#checks.x86_64-linux.power-management
nix build .#checks.x86_64-linux.home-manager
```

### Update

```bash
nix flake update
```

## Instalação Fresh

1. Boot pelo NixOS installer USB
2. Particionar disco: EFI (512MB) + LUKS (restante) + Swap
3. Criar subvolumes Btrfs: `@`, `@home`, `@nix`, `@snapshots`
4. Montar partições e gerar `hardware-configuration.nix`
5. Substituir UUIDs nos arquivos `hosts/<host>/hardware-configuration.nix`
6. Executar `nixos-install --flake .#<hostname>`

## Pré-requisitos

- Nix com flakes habilitado
- Boot UEFI
- Partições conforme esquema Btrfs + LUKS
