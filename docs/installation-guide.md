# Guia de Instalação — NixOS Workstations

## Visão Geral

O flake é clonado **durante a instalação** (antes do `nixos-install`). Você precisa do repositório disponível no ambiente live para que o installer construa o sistema completo.

Fluxo:
1. Boot pelo pendrive NixOS
2. Particionar disco
3. Montar partições
4. Clonar o repositório
5. Gerar e substituir UUIDs no hardware-configuration.nix
6. Executar `nixos-install --flake`

---

## Pré-requisitos

- Pendrive com NixOS Minimal ISO (nixos-unstable)
- Conexão com internet (Wi-Fi ou Ethernet)
- Disco NVMe/SSD alvo

---

## 1. Boot pelo Pendrive

Boot no pendrive, selecione a entrada NixOS. Você cai num shell root.

### Conectar à internet (se Wi-Fi)

```bash
# Verificar interfaces
ip link

# Conectar via iwctl (já disponível no ISO)
iwctl
# dentro do iwctl:
#   station wlan0 scan
#   station wlan0 get-networks
#   station wlan0 connect "NOME-DA-REDE"
#   exit

# Verificar conectividade
ping -c 3 nixos.org
```

---

## 2. Particionar Disco

Substitua `/dev/nvme0n1` pelo seu disco real (`lsblk` para verificar).

### Layout de partições

| Partição | Tamanho | Tipo | Uso |
|----------|---------|------|-----|
| p1 | 512 MB | EFI System | /boot |
| p2 | RAM size (ex: 16GB) | Linux swap | swap + hibernação |
| p3 | Restante | Linux filesystem | LUKS → Btrfs |

### Criar partições com gdisk

```bash
gdisk /dev/nvme0n1

# Dentro do gdisk:
# o (criar nova GPT table — APAGA TUDO)
# n, 1, enter, +512M, ef00        (EFI)
# n, 2, enter, +16G, 8200         (Swap — ajuste para seu RAM)
# n, 3, enter, enter, 8300        (Linux filesystem)
# w (gravar)
```

### Criar sistema de arquivos EFI

```bash
mkfs.fat -F 32 -n BOOT /dev/nvme0n1p1
```

### Criar e ativar swap

```bash
mkswap -L SWAP /dev/nvme0n1p2
swapon /dev/nvme0n1p2
```

### Criar LUKS na partição principal

```bash
cryptsetup luksFormat --type luks2 /dev/nvme0n1p3

# Digite YES (maiúsculo) e defina a senha

cryptsetup open /dev/nvme0n1p3 cryptroot
```

### Criar Btrfs com subvolumes

```bash
mkfs.btrfs -L NIXOS /dev/mapper/cryptroot

# Montar temporariamente para criar subvolumes
mount /dev/mapper/cryptroot /mnt

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@snapshots

umount /mnt
```

---

## 3. Montar Partições

```bash
# Raiz
mount -o subvol=@,compress=zstd,noatime /dev/mapper/cryptroot /mnt

# Criar pontos de montagem
mkdir -p /mnt/{home,nix,.snapshots,boot}

# Home
mount -o subvol=@home,compress=zstd,noatime /dev/mapper/cryptroot /mnt/home

# Nix store
mount -o subvol=@nix,compress=zstd,noatime /dev/mapper/cryptroot /mnt/nix

# Snapshots
mount -o subvol=@snapshots,compress=zstd,noatime /dev/mapper/cryptroot /mnt/.snapshots

# Boot (EFI)
mount /dev/nvme0n1p1 /mnt/boot
```

### Verificar montagens

```bash
mount | grep /mnt
# Deve mostrar 4 montagens btrfs + 1 vfat
```

---

## 4. Clonar o Repositório

```bash
# Habilitar flakes no ambiente live
nix-env -iA nixos.git

# Clonar o repositório dentro de /mnt
git clone https://github.com/fagianijunior/nixos-workstations.git /mnt/etc/nixos
```

> **Nota**: Usamos HTTPS para clonar porque a chave SSH ainda não existe na instalação. Depois de instalado, o remote pode ser trocado para SSH.

---

## 5. Gerar e Substituir UUIDs

### Descobrir UUIDs reais

```bash
# UUID da partição LUKS (o que vai no boot.initrd.luks.devices)
blkid /dev/nvme0n1p3 -s UUID -o value

# UUID do swap
blkid /dev/nvme0n1p2 -s UUID -o value

# UUID do EFI
blkid /dev/nvme0n1p1 -s UUID -o value
```

### Editar o hardware-configuration.nix do host

Para **Nobita**:
```bash
nano /mnt/etc/nixos/hosts/nobita/hardware-configuration.nix
```

Para **Doraemon**:
```bash
nano /mnt/etc/nixos/hosts/doraemon/hardware-configuration.nix
```

Substitua:
- `REPLACE-WITH-LUKS-UUID` → UUID de `/dev/nvme0n1p3`
- `REPLACE-WITH-SWAP-UUID` → UUID de `/dev/nvme0n1p2`
- `REPLACE-WITH-EFI-UUID` → UUID de `/dev/nvme0n1p1`

### Alternativa automática (script)

```bash
LUKS_UUID=$(blkid /dev/nvme0n1p3 -s UUID -o value)
SWAP_UUID=$(blkid /dev/nvme0n1p2 -s UUID -o value)
EFI_UUID=$(blkid /dev/nvme0n1p1 -s UUID -o value)
HOST="nobita"  # ou "doraemon"

sed -i "s/REPLACE-WITH-LUKS-UUID/$LUKS_UUID/g" /mnt/etc/nixos/hosts/$HOST/hardware-configuration.nix
sed -i "s/REPLACE-WITH-SWAP-UUID/$SWAP_UUID/g" /mnt/etc/nixos/hosts/$HOST/hardware-configuration.nix
sed -i "s/REPLACE-WITH-EFI-UUID/$EFI_UUID/g" /mnt/etc/nixos/hosts/$HOST/hardware-configuration.nix
```

---

## 6. Instalar

```bash
# Instalar NixOS usando o flake
nixos-install --flake /mnt/etc/nixos#nobita   # ou #doraemon

# Definir senha do root
# (será pedido no final do nixos-install)

# Definir senha do usuário terabytes
nixos-enter --root /mnt -c 'passwd terabytes'
```

---

## 7. Reboot

```bash
umount -R /mnt
reboot
```

Remova o pendrive. O sistema deve bootar no systemd-boot, pedir a senha LUKS, e iniciar no greetd/Hyprland.

---

## 8. Pós-instalação

Após o primeiro boot:

```bash
# Trocar remote para SSH (opcional)
cd /etc/nixos
git remote set-url origin git@github.com:fagianijunior/nixos-workstations.git

# Colocar wallpaper
cp /caminho/do/wallpaper ~/.background

# Rebuilds futuros
sudo nixos-rebuild switch --flake /etc/nixos#nobita  # ou #doraemon

# Ou usando a função fish definida no config:
# nswitch  (nota: aponta para ~/Workspace/fagianijunior/dotfiles/ — ajustar se necessário)
```

---

## Troubleshooting

### "error: experimental-features = nix-command flakes"
O ISO minimal pode não ter flakes habilitado:
```bash
export NIX_CONFIG="experimental-features = nix-command flakes"
```

### nixos-install falha por falta de memória
Adicione mais swap temporário:
```bash
dd if=/dev/zero of=/tmp/swap bs=1M count=4096
mkswap /tmp/swap
swapon /tmp/swap
```

### Wi-Fi não conecta no live
Verifique se o firmware está disponível:
```bash
dmesg | grep -i firmware
# Se faltar firmware, use o ISO com firmware incluso (non-free)
```

### LUKS não abre no boot
Verifique se o UUID no hardware-configuration.nix está correto:
```bash
# Do live USB:
cryptsetup open /dev/nvme0n1p3 cryptroot
mount -o subvol=@ /dev/mapper/cryptroot /mnt
cat /mnt/etc/nixos/hosts/*/hardware-configuration.nix | grep -i uuid
blkid /dev/nvme0n1p3
```
