# Code Generation Plan — nixos-workstations

## Unit Context

- **Unit Name**: nixos-workstations (single unit)
- **Project Type**: Greenfield NixOS Flake
- **Target**: Workspace root `/home/terabytes/Workspace/fagianijunior/nixos/nixos-workstations/`
- **Channel**: nixos-unstable (Hyprland 0.54.3, greetd 0.10.3)
- **Flake Inputs**: nixpkgs (unstable), home-manager, catppuccin/nix

## Dependencies
- nixpkgs (nixos-unstable branch)
- home-manager (follows nixpkgs)
- catppuccin/nix (github:catppuccin/nix)

## Code Generation Steps

---

### Step 1: Project Structure Setup
- [x] Create directory structure:
  ```
  hosts/nobita/
  hosts/doraemon/
  modules/common/
  modules/desktop/
  modules/hardware/
  modules/security/
  modules/services/
  home/
  tests/
  ```
- [x] Create `flake.nix` with inputs (nixpkgs-unstable, home-manager, catppuccin/nix) and outputs (nixosConfigurations for nobita and doraemon, checks for tests)

---

### Step 2: Common Module — Base System
- [x] Create `modules/common/default.nix`:
  - Nix settings (experimental-features, flakes)
  - Locale (pt_BR.UTF-8 default, en_US.UTF-8 available)
  - Timezone (America/Fortaleza)
  - systemd-boot configuration
  - Base packages (git, vim, curl, wget, htop, etc.)
  - User `terabytes` com grupos (wheel, video, audio)
  - Firewall habilitado (nftables)
  - Fail-safe defaults

---

### Step 3: Hardware Module — AMD GPU
- [x] Create `modules/hardware/amd-gpu.nix`:
  - AMDGPU driver (open-source)
  - Vulkan (RADV) via vulkan-loader + amdvlk ou radv
  - Mesa drivers
  - VA-API (video decode)
  - hardware.opengl (ou hardware.graphics no unstable) habilitado

---

### Step 4: Hardware Module — Bluetooth
- [x] Create `modules/hardware/bluetooth.nix`:
  - hardware.bluetooth.enable = true
  - bluez package
  - bluetoothctl disponível (sem GUI/applet)

---

### Step 5: Services Module — Audio (PipeWire)
- [x] Create `modules/services/pipewire.nix`:
  - PipeWire habilitado
  - WirePlumber como session manager
  - PulseAudio compatibility layer
  - ALSA support

---

### Step 6: Services Module — Networking (iwd + systemd-networkd)
- [x] Create `modules/services/networking.nix`:
  - networking.wireless.iwd.enable = true
  - systemd-networkd para Ethernet
  - NetworkManager desabilitado
  - Configuração básica de DNS (systemd-resolved)

---

### Step 7: Desktop Module — Hyprland
- [x] Create `modules/desktop/hyprland.nix`:
  - programs.hyprland.enable = true
  - XDG Desktop Portal (xdg-desktop-portal-hyprland)
  - Wayland session variables
  - greetd com tuigreet como login manager
  - Pacotes de suporte (wl-clipboard, grim, slurp, etc.)

---

### Step 8: Desktop Module — Catppuccin Theme
- [x] Create `modules/desktop/catppuccin.nix`:
  - Integração com flake catppuccin/nix
  - Flavor: macchiato
  - Aplicar tema system-wide (GTK, Qt, terminal, etc.)

---

### Step 9: Services Module — Gaming
- [x] Create `modules/services/gaming.nix`:
  - programs.steam.enable = true
  - Steam com Proton support
  - Lutris
  - gamemode
  - 32-bit libraries habilitadas

---

### Step 10: Security Module — System Hardening
- [x] Create `modules/security/hardening.nix`:
  - Firewall nftables com regras restritivas (SECURITY-07)
  - systemd service sandboxing (SECURITY-06)
  - Sem credenciais hardcoded (SECURITY-12)
  - Kernel hardening básico (sysctl)
  - Fail-safe defaults (SECURITY-15)
  - sudo configurado com timeout

---

### Step 11: Services Module — Power Management (Notebook)
- [x] Create `modules/services/power-management.nix`:
  - TLP habilitado com perfis AC/Battery
  - Lid close → suspend
  - Hibernação suportada (resume device config)
  - Auto-suspend USB em bateria

---

### Step 12: Host Configuration — Nobita (Desktop)
- [x] Create `hosts/nobita/default.nix`:
  - Import modules: common, hardware/amd-gpu, hardware/bluetooth, services/pipewire, services/networking, desktop/hyprland, desktop/catppuccin, services/gaming, security/hardening
  - hostname = "nobita"
  - Hardware-specific: initrd modules para Navi 23
  - Btrfs + LUKS config (fileSystems, boot.initrd.luks)
  - Swap com resume para hibernação
- [x] Create `hosts/nobita/hardware-configuration.nix`:
  - Disk layout (LUKS + Btrfs subvolumes)
  - Boot partition (EFI)
  - Kernel modules (amdgpu, nvme, xhci_pci, etc.)
  - initrd available/required kernel modules

---

### Step 13: Host Configuration — Doraemon (Notebook)
- [x] Create `hosts/doraemon/default.nix`:
  - Import modules: common, hardware/amd-gpu, hardware/bluetooth, services/pipewire, services/networking, desktop/hyprland, desktop/catppuccin, services/gaming, security/hardening, services/power-management
  - hostname = "doraemon"
  - Hardware-specific: initrd modules para Rembrandt 680M
  - Btrfs + LUKS config
  - Swap com resume para hibernação
  - Backlight control
- [x] Create `hosts/doraemon/hardware-configuration.nix`:
  - Disk layout (LUKS + Btrfs subvolumes)
  - Boot partition (EFI)
  - Kernel modules (amdgpu, nvme, xhci_pci, thinkpad_acpi ou ideapad equivalente)
  - initrd available/required kernel modules

---

### Step 14: Home Manager Configuration
- [x] Create `home/default.nix`:
  - Home Manager module para usuário terabytes
  - home.stateVersion
  - Catppuccin integration via home-manager module
  - Programas básicos do terminal (shell, git config, etc.)
  - Integração com Hyprland (hyprland.conf básico)
  - XDG user dirs

---

### Step 15: Tests — Boot and Core Services
- [x] Create `tests/boot-test.nix`:
  - runNixOSTest: VM boots successfully
  - systemd reaches multi-user.target
  - Kernel loaded (uname check)
  - Locale configurado (pt_BR.UTF-8)
  - Timezone correto (America/Fortaleza)

---

### Step 16: Tests — Audio (PipeWire)
- [x] Create `tests/pipewire-test.nix`:
  - runNixOSTest: PipeWire service active
  - WirePlumber active
  - PipeWire socket exists
  - pw-cli info funciona

---

### Step 17: Tests — Networking (iwd + systemd-networkd)
- [x] Create `tests/networking-test.nix`:
  - runNixOSTest: iwd service active
  - systemd-networkd active
  - systemd-resolved active
  - NetworkManager NOT running
  - DNS resolution functional

---

### Step 18: Tests — Bluetooth
- [x] Create `tests/bluetooth-test.nix`:
  - runNixOSTest: bluetooth service active
  - bluetoothctl binary available
  - bluetooth.service running

---

### Step 19: Tests — GPU (AMDGPU)
- [x] Create `tests/gpu-test.nix`:
  - runNixOSTest: amdgpu kernel module loaded
  - /dev/dri/ exists
  - Vulkan ICD available (vulkaninfo or ls ICD files)
  - Mesa drivers present

---

### Step 20: Tests — Hyprland Desktop
- [x] Create `tests/hyprland-test.nix`:
  - runNixOSTest: greetd service active
  - Hyprland binary available
  - XDG Desktop Portal service available
  - Wayland socket created when session starts

---

### Step 21: Tests — Security Hardening
- [x] Create `tests/security-test.nix`:
  - runNixOSTest: firewall active (nftables rules loaded)
  - No open ports by default (except expected)
  - Kernel hardening sysctl values applied
  - systemd services have security restrictions

---

### Step 22: Tests — Power Management (Doraemon-specific)
- [x] Create `tests/power-management-test.nix`:
  - runNixOSTest: TLP service active
  - Resume device configured for hibernation
  - Power profiles available

---

### Step 23: Tests — Home Manager
- [x] Create `tests/home-manager-test.nix`:
  - runNixOSTest: Home Manager activation succeeds
  - User terabytes exists with correct groups
  - Home directory has expected structure
  - XDG dirs configured

---

### Step 24: Flake Integration — Checks Output
- [x] Update `flake.nix` to expose all tests as `checks.x86_64-linux.*`
- [x] Verify flake structure is complete and consistent
- [x] Add README.md with project overview and usage instructions

---

## Summary

| Category | Files | Count |
|----------|-------|-------|
| Flake root | flake.nix, README.md | 2 |
| Host configs | hosts/{nobita,doraemon}/{default,hardware-configuration}.nix | 4 |
| Modules | modules/{common,desktop,hardware,security,services}/*.nix | 10 |
| Home Manager | home/default.nix | 1 |
| Tests | tests/*.nix | 9 |
| **Total** | | **26 files** |

## Extension Compliance Notes

### Security Baseline (Full Enforcement)
- SECURITY-01: LUKS encryption configured in hardware-configuration.nix ✓
- SECURITY-06: systemd service hardening in hardening.nix ✓
- SECURITY-07: nftables firewall in hardening.nix ✓
- SECURITY-09: Minimal install, no default credentials ✓
- SECURITY-10: flake.lock for dependency pinning ✓
- SECURITY-12: No hardcoded credentials ✓
- SECURITY-13: Nix store integrity (inherent) ✓
- SECURITY-15: Fail-safe defaults in services ✓

### PBT (Partial Enforcement)
- PBT-02: Round-trip — modules produce valid NixOS config (tested via runNixOSTest eval) ✓
- PBT-03: Invariants — expected services are active (each test verifies invariant) ✓
- PBT-07: Generator quality — N/A (runNixOSTest is declarative, not random-input based)
- PBT-08: Reproducibility — tests are deterministic (same VM, same config) ✓
- PBT-09: Framework — runNixOSTest (NixOS native testing framework) ✓
