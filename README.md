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

## Ambientes de desenvolvimento

Runtimes e toolchains de linguagem **não** ficam instalados no sistema global.
A cada projeto, o ambiente é provido por `devenv.nix` (ou `nix develop`), o que
mantém o sistema enxuto e evita arrastar dependências pesadas.

### PHP

O interpretador `php` e suas extensões não são instalados globalmente. Quando
precisar de PHP, use o `devenv.nix` do projeto.

O Neovim mantém apenas a integração **leve**, que não puxa o interpretador:

- **Syntax highlight**: parser Treesitter de PHP (biblioteca C, sem runtime PHP).
- **LSP** (`intelephense`) e **formatter** (`php-cs-fixer`): apenas referenciados
  por nome na config. Só entram em ação quando os binários estão no `PATH` do
  shell que lançou o Neovim — ou seja, dentro de um `devenv` que os forneça.
  Fora dele, ficam inativos, sem erro.

Exemplo de `devenv.nix` para um projeto PHP:

```nix
{ pkgs, ... }:
{
  languages.php.enable = true;
  packages = [
    pkgs.php84Packages.php-cs-fixer
    pkgs.intelephense
  ];
}
```

Abrindo o Neovim dentro desse shell, o LSP sobe e a formatação funciona
automaticamente.

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
2. Particionar disco:
   - **EFI**: 1024MB (1GB) — systemd-boot + múltiplas gerações NixOS
   - **LUKS container**: restante do disco (abrange root + swap)
   - **Swap dentro do LUKS**: arquivo swap em `/swapfile` (criado pós-instalação)
3. Criar subvolumes Btrfs: `@`, `@home`, `@nix`, `@snapshots`
4. Montar partições e gerar `hardware-configuration.nix`:
   ```bash
   # Montar LUKS
   cryptsetup luksOpen /dev/sdX2 nixenc
   
   # Montar Btrfs com subvolumes
   mount -o compress=zstd,subvol=@ /dev/mapper/nixenc /mnt
   mkdir -p /mnt/{home,nix,.snapshots,boot}
   mount -o compress=zstd,subvol=@home /dev/mapper/nixenc /mnt/home
   mount -o compress=zstd,noatime,subvol=@nix /dev/mapper/nixenc /mnt/nix
   mount -o compress=zstd,subvol=@snapshots /dev/mapper/nixenc /mnt/.snapshots
   
   # Montar EFI
   mount /dev/sdX1 /mnt/boot
   
   # Gerar config hardware
   nixos-generate-config --root /mnt
   ```
5. Substituir UUIDs nos arquivos `hosts/<host>/hardware-configuration.nix`:
   - Localizar UUIDs das partições: `blkid`
   - Atualizar `boot.initrd.luks.devices.nixenc.device` e `fileSystems."/boot".device`
6. Executar `nixos-install --flake .#<hostname>`

**Nota**: O swap deve estar dentro do LUKS para Full Disk Encryption consistente. Use `/swapfile` em vez de partição swap separada.

## Pré-requisitos

- Nix com flakes habilitado
- Boot UEFI
- Partições conforme esquema Btrfs + LUKS
