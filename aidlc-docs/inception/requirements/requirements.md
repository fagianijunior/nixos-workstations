# Documento de Requisitos — NixOS Workstations

## Análise de Intenção

| Campo | Valor |
|-------|-------|
| **Requisição do Usuário** | Criar código Nix para instalação e configuração de NixOS 26.05 x86_64 em duas máquinas (Nobita e Doraemon) com testes usando `runNixOSTest` |
| **Tipo de Requisição** | Novo Projeto (Greenfield) |
| **Estimativa de Escopo** | Múltiplos Componentes (dois hosts, módulos compartilhados, testes) |
| **Estimativa de Complexidade** | Moderada (configuração NixOS multi-host com hardware específico, Btrfs+LUKS, Hyprland, testes) |

---

## Requisitos Funcionais

### RF-01: Estrutura do Projeto

**Descrição**: O projeto utiliza Nix Flakes com módulos NixOS separados por host.

**Estrutura esperada**:
```
nixos-workstations/
├── flake.nix
├── flake.lock
├── hosts/
│   ├── nobita/
│   │   ├── default.nix
│   │   └── hardware-configuration.nix
│   └── doraemon/
│       ├── default.nix
│       └── hardware-configuration.nix
├── modules/
│   ├── common/          # Módulos compartilhados entre hosts
│   ├── desktop/         # Hyprland e configurações de desktop
│   ├── hardware/        # Configurações de hardware AMD
│   ├── security/        # Hardening e segurança
│   └── services/        # Serviços do sistema
├── home/                # Configurações Home Manager
│   ├── common.nix       # Configurações compartilhadas do usuário
│   └── programs/        # Programas e dotfiles do usuário
├── tests/               # Testes com runNixOSTest
└── aidlc-docs/          # Documentação AI-DLC (existente)
```

### RF-02: Configuração de Hardware — Nobita (Desktop)

| Componente | Especificação |
|------------|---------------|
| **CPU** | AMD Ryzen 7 5700 |
| **GPU** | AMD/ATI Navi 23 Radeon RX 6600 XT (rev c7) |
| **Placa Mãe** | TUF GAMING B450-PLUS II |
| **BIOS** | 4645 |
| **Tipo** | Desktop |
| **Arch** | x86_64 |

**Requisitos específicos**:
- Driver AMDGPU open-source com Vulkan (RADV)
- Sem configurações de gerenciamento de energia de notebook
- Suporte completo a periféricos (USB, áudio, Bluetooth, Wi-Fi)

### RF-03: Configuração de Hardware — Doraemon (Notebook)

| Componente | Especificação |
|------------|---------------|
| **Modelo** | Lenovo IdeaPad Slim 3 15ARP10 |
| **CPU** | AMD Ryzen 7 7735HS with Radeon Graphics |
| **GPU** | Rembrandt RADEON 680M (rev 0a) (integrada) |
| **Placa Mãe** | LNVNB161216 |
| **BIOS** | QBCN27WW |
| **Tipo** | Notebook |
| **Arch** | x86_64 |

**Requisitos específicos**:
- Driver AMDGPU open-source com Vulkan (RADV)
- TLP com gerenciamento completo de energia
- Suspensão ao fechar a tampa (lid close)
- Suporte a Wi-Fi e Bluetooth
- Configuração de backlight

### RF-04: Sistema de Arquivos (Ambas Máquinas)

**Esquema**: Btrfs + LUKS + Swap com suporte a hibernação

**Subvolumes Btrfs**:
- `@` — Raiz `/`
- `@home` — `/home`
- `@nix` — `/nix`
- `@snapshots` — `/.snapshots`

**Criptografia**:
- LUKS2 na partição principal
- Desbloqueio via senha no boot

**Swap**:
- Swap partition ou swapfile com suporte a hibernação (resume)
- Tamanho suficiente para hibernação (>= RAM)

**Boot (EFI)**:
- Partição EFI separada (FAT32, /boot)
- systemd-boot como bootloader

### RF-05: Ambiente Desktop — Hyprland

**Composição**:
- Hyprland como Wayland compositor
- Configuração base compartilhada entre as duas máquinas
- Suporte a PipeWire para áudio
- XDG Desktop Portal (xdg-desktop-portal-hyprland)
- Login manager (greetd ou similar compatível com Wayland)
- Tema: **Catppuccin Macchiato** (sistema inteiro, via flake `github:catppuccin/nix`)

### RF-06: Serviços do Sistema (Ambas Máquinas)

| Serviço | Descrição |
|---------|-----------|
| **Áudio** | PipeWire + WirePlumber |
| **Bluetooth** | bluez (gerenciado via `bluetoothctl` no terminal, sem applet/GUI) |
| **Rede** | iwd (gerenciado via `iwctl` no terminal, sem NetworkManager/applet) + systemd-networkd para Ethernet |
| **Jogos** | Steam + Lutris (com Proton/Wine) |
| **Firewall** | nftables ou iptables (básico) |

### RF-07: Gerenciamento de Energia — Doraemon

| Configuração | Valor |
|--------------|-------|
| **TLP** | Ativo com perfis AC/Battery |
| **Lid Close (AC)** | Suspend |
| **Lid Close (Battery)** | Suspend |
| **Hibernação** | Suportada via swap |
| **Auto-suspend USB** | Habilitado em bateria |

### RF-08: Locale e Internacionalização

| Configuração | Valor |
|--------------|-------|
| **Locale padrão** | pt_BR.UTF-8 |
| **Locale adicional** | en_US.UTF-8 |
| **Layout do teclado** | Configurável por máquina |
| **Timezone** | America/Fortaleza |

### RF-09: Usuário

- Username: `terabytes` (mesmo em ambas as máquinas)
- Configurações de usuário gerenciadas via **Home Manager** (integrado ao flake)
- Grupos: wheel, video, audio, docker (se necessário)
- Home Manager usado para: dotfiles, programas do usuário, configurações de aplicativos

### RF-10: Bootloader

- systemd-boot (UEFI)
- Entries automáticas para NixOS generations
- Console mode para seleção de boot

### RF-11: Testes com runNixOSTest

**Escopo**: Testes completos incluindo verificação de serviços específicos.

**Cenários de teste**:
- Boot do sistema com sucesso
- Serviço PipeWire ativo e funcional
- GPU detectada corretamente (amdgpu loaded)
- Rede ativa (iwd rodando, systemd-networkd ativo)
- Hyprland compositor funcional
- Bluetooth ativo (bluez rodando)
- TLP ativo (Doraemon)
- LUKS desbloqueio funcional
- Btrfs subvolumes montados corretamente
- systemd-boot como bootloader ativo
- Locale configurado corretamente
- Home Manager ativado e funcional para usuário terabytes

---

## Requisitos Não-Funcionais

### RNF-01: Compatibilidade NixOS

- Versão alvo: NixOS Unstable (nixos-unstable channel)
- Arquitetura: x86_64-linux
- Uso de Nix Flakes (experimental features: nix-command, flakes)

### RNF-02: Manutenibilidade

- Módulos reutilizáveis entre hosts
- Separação clara de responsabilidades (hardware, desktop, serviços)
- Documentação inline nos arquivos Nix
- Código limpo e idiomático (Nix language best practices)

### RNF-03: Segurança (Extension: Security Baseline — ENABLED)

- LUKS2 criptografia de disco (SECURITY-01: encryption at rest)
- Firewall ativo por padrão (SECURITY-07: restrictive network config)
- Nenhuma credencial hardcoded nos arquivos Nix (SECURITY-12)
- Dependências pinadas via flake.lock (SECURITY-10: supply chain)
- Fail-safe defaults em serviços (SECURITY-15)
- Least privilege nos serviços systemd (SECURITY-06)

### RNF-04: Testabilidade

- Testes automatizados com `runNixOSTest` (nixos/lib/testing)
- Testes devem ser executáveis via `nix flake check` ou `nix build .#checks.x86_64-linux.<test>`
- Cobertura de serviços críticos

### RNF-05: Property-Based Testing (Extension: PBT — PARTIAL)

- Modo Parcial: aplicar regras PBT apenas para funções puras e round-trips de serialização
- No contexto NixOS, aplica-se a:
  - Verificação de round-trip em configurações (módulo gera config válida que pode ser parseada)
  - Invariantes em listas de pacotes e configurações
- Framework: integrado ao `runNixOSTest` (testes NixOS são declarativos por natureza)

### RNF-06: Reprodutibilidade

- Builds reprodutíveis via Nix Flakes
- flake.lock commitado no repositório
- Inputs declarados explicitamente no flake.nix

---

## Decisões Técnicas

| Decisão | Escolha | Justificativa |
|---------|---------|---------------|
| Gerenciador de pacotes | Nix Flakes | Reprodutibilidade, inputs declarativos |
| Channel | nixos-unstable | Preferência do usuário, pacotes mais recentes |
| Desktop | Hyprland (Wayland) | Requisito do usuário |
| Tema | Catppuccin Macchiato (via `github:catppuccin/nix`) | Tema unificado para todo o sistema |
| Áudio | PipeWire | Padrão moderno, substitui PulseAudio |
| Bootloader | systemd-boot | Simplicidade, UEFI nativo |
| Filesystem | Btrfs + LUKS | Snapshots + criptografia + hibernação |
| GPU Driver | AMDGPU (open-source) | Padrão NixOS, Vulkan via RADV |
| Energia (notebook) | TLP | Gerenciamento avançado de bateria |
| Rede | iwd + systemd-networkd | Terminal-first, sem GUI/applet |
| Bluetooth | bluez (bluetoothctl) | Terminal-first, sem GUI/applet |
| Usuário | Home Manager | Gerenciamento declarativo de dotfiles e configurações de usuário |
| Testes | runNixOSTest | Framework nativo NixOS para testes de integração em VM |

---

## Regras de Segurança Aplicáveis (Security Baseline)

| Rule ID | Aplicabilidade | Notas |
|---------|---------------|-------|
| SECURITY-01 | ✅ Aplicável | LUKS encryption at rest |
| SECURITY-02 | N/A | Sem intermediários de rede (workstations) |
| SECURITY-03 | N/A | Sem aplicação com logging centralizado |
| SECURITY-04 | N/A | Sem web applications |
| SECURITY-05 | N/A | Sem APIs |
| SECURITY-06 | ✅ Aplicável | systemd service hardening (least privilege) |
| SECURITY-07 | ✅ Aplicável | Firewall nftables ativo |
| SECURITY-08 | N/A | Sem aplicação com access control |
| SECURITY-09 | ✅ Aplicável | Hardening do sistema (sem default credentials, minimal install) |
| SECURITY-10 | ✅ Aplicável | flake.lock para pinning, inputs declarados |
| SECURITY-11 | N/A | Sem design de aplicação (é infra/OS config) |
| SECURITY-12 | ✅ Parcial | Sem credenciais hardcoded (N/A para auth de aplicação) |
| SECURITY-13 | ✅ Aplicável | Integridade via Nix store (hashes) |
| SECURITY-14 | N/A | Sem alerting centralizado (workstation) |
| SECURITY-15 | ✅ Aplicável | Fail-safe defaults em serviços |

---

## Regras PBT Aplicáveis (Partial Mode)

| Rule ID | Aplicabilidade | Notas |
|---------|---------------|-------|
| PBT-01 | Advisory | Identificação de propriedades durante design |
| PBT-02 | ✅ Enforced | Round-trip: módulos NixOS produzem config válida |
| PBT-03 | ✅ Enforced | Invariantes: serviços esperados estão ativos |
| PBT-04 | Advisory | Idempotência |
| PBT-05 | Advisory | Oracle testing |
| PBT-06 | Advisory | Stateful testing |
| PBT-07 | ✅ Enforced | Qualidade dos geradores de teste |
| PBT-08 | ✅ Enforced | Reprodutibilidade dos testes |
| PBT-09 | ✅ Enforced | Framework: runNixOSTest (nativo NixOS) |
| PBT-10 | Advisory | Estratégia complementar |
