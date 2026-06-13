# Perguntas de Verificação de Requisitos

Por favor, responda cada pergunta preenchendo a letra correspondente após o tag [Answer]:.

---

## Question 1
Qual estrutura de projeto NixOS será utilizada?

A) Flake com módulos NixOS separados por host (flake.nix + hosts/nobita/ + hosts/doraemon/ + modules/)
B) Configuração tradicional sem flakes (configuration.nix por máquina)
C) Flake monolítico (tudo em um único flake.nix)
X) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Question 2
Qual ambiente desktop/window manager será utilizado nas máquinas?

A) GNOME
B) KDE Plasma
C) Hyprland (Wayland compositor)
D) Sway (Wayland compositor)
E) XFCE
X) Other (please describe after [Answer]: tag below)

[Answer]: C

---

## Question 3
Qual bootloader será utilizado?

A) systemd-boot (UEFI)
B) GRUB 2 (UEFI)
C) GRUB 2 (Legacy BIOS)
X) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Question 4
Quais serviços e funcionalidades são esperados em ambas as máquinas? (marque a letra que melhor descreve)

A) Desktop completo com áudio (PipeWire), bluetooth, impressão, rede Wi-Fi/Ethernet, e suporte a jogos (Steam/Lutris)
B) Desktop completo com áudio (PipeWire), bluetooth, rede Wi-Fi/Ethernet, sem suporte a jogos
C) Desktop minimalista apenas com áudio e rede
X) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Question 5
A máquina Doraemon (notebook) precisa de configurações específicas de laptop como gerenciamento de energia, TLP, suspensão com lid close?

A) Sim, com TLP e configurações completas de gerenciamento de energia
B) Sim, apenas configurações básicas (suspensão ao fechar a tampa)
C) Não, sem configurações específicas de laptop
X) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Question 6
Como os drivers AMD GPU devem ser configurados?

A) AMDGPU open-source com suporte Vulkan (RADV) - padrão NixOS
B) AMDGPU com ROCm (para compute/machine learning)
C) AMDGPU com suporte completo (Vulkan + OpenCL + video decode/encode)
X) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Question 7
Qual sistema de arquivos será utilizado?

A) ext4 (raiz) + swap partition
B) Btrfs com subvolumes (@, @home, @nix, @snapshots) + swap
C) ZFS com datasets + swap
D) ext4 com LUKS (criptografia de disco)
X) Other (please describe after [Answer]: tag below)

[Answer]: Btrfs + LUKS + swap com suporte a hibernação

---

## Question 8
Qual locale/idioma principal do sistema?

A) pt_BR.UTF-8 (Português Brasil)
B) en_US.UTF-8 (Inglês EUA)
C) Ambos (pt_BR como padrão, en_US disponível)
X) Other (please describe after [Answer]: tag below)

[Answer]: C 

---

## Question 9
Haverá um usuário principal compartilhado entre as duas máquinas ou usuários diferentes?

A) Mesmo usuário em ambas as máquinas (ex: mesmo username e configurações compartilhadas via módulos)
B) Usuários diferentes em cada máquina
C) Mesmo username, mas configurações diferentes por máquina
X) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Question 10
Qual o escopo dos testes com `runNixOSTest`?

A) Testes que verificam se os módulos NixOS são aplicáveis sem erros (boot, serviços ativos, hardware configurado)
B) Testes completos incluindo verificação de serviços específicos (ex: audio funciona, GPU detectada, rede ativa)
C) Testes mínimos (apenas verificação de build e boot)
X) Other (please describe after [Answer]: tag below)

[Answer]: B

---

## Question 11: Security Extensions
As regras de segurança da extensão Security Baseline devem ser aplicadas neste projeto?

A) Sim — aplicar todas as regras de SEGURANÇA como restrições obrigatórias (recomendado para aplicações de produção)
B) Não — ignorar regras de SEGURANÇA (adequado para PoCs, protótipos e projetos experimentais)
X) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Question 12: Property-Based Testing Extension
As regras de Property-Based Testing (PBT) devem ser aplicadas neste projeto?

A) Sim — aplicar todas as regras PBT como restrições obrigatórias (recomendado para projetos com lógica de negócios, transformações de dados, serialização ou componentes stateful)
B) Parcial — aplicar regras PBT apenas para funções puras e round-trips de serialização
C) Não — ignorar regras PBT (adequado para aplicações CRUD simples, projetos UI-only, ou camadas de integração sem lógica significativa)
X) Other (please describe after [Answer]: tag below)

[Answer]: B

---
