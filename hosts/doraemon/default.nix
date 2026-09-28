{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./keyboard-resume.nix
    ../../modules/common
    ../../modules/hardware/amd-gpu.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/hardware/solaar.nix
    ../../modules/services/pipewire.nix
    ../../modules/services/networking.nix
    ../../modules/services/ssh.nix
    ../../modules/services/gaming.nix
    ../../modules/desktop/hyprland.nix
    ../../modules/desktop/catppuccin.nix
    ../../modules/security/hardening.nix
    ../../modules/services/power-management.nix
  ];

  # Kernel: usa o linuxPackages_zen definido em modules/common (igual ao nobita).
  #
  # Histórico: houve um pin temporário no LTS 6.12 aqui enquanto o problema de boot/display
  # deste APU Rembrandt (RADEON 680M) era investigado. A causa raiz acabou sendo o
  # linux-firmware, NÃO o kernel: o flake update (nixpkgs ef34387) subiu o firmware
  # 20260810 -> 20260910, e a nova revisão do yellow_carp_dmcub.bin passou a ser rejeitada
  # pelo PSP, quebrando o DMCUB (display microcontroller) -- HDMI morto, render lenta,
  # brilho travado, e falha de boot precoce. Corrigido em overlays/linux-firmware.nix
  # (pin do firmware em 20260810). Com o firmware corrigido, o zen 7.2.4 volta a funcionar,
  # então o pin de kernel foi removido para manter consistência com o nobita.

  # Hostname
  networking.hostName = "doraemon";

  # Console keymap
  console.keyMap = "br-abnt2";

  # Fix: microfone interno não detectado (ALC257, Lenovo IdeaPad Slim 3 15ARP10)
  # O BIOS reporta SSID como 17aa:0000 em vez do correto 17aa:3f87, fazendo o kernel
  # aplicar um fixup genérico que não configura corretamente o microfone interno (pin 0x12).
  # Forçar o modelo "alc257-ideapad" aplica os verbos corretos de inicialização do codec.
  boot.extraModprobeConfig = ''
    options snd-hda-intel model=alc257-ideapad
  '';

  # Doraemon-specific: Lenovo IdeaPad Slim 3 15ARP10
  # AMD Ryzen 7 7735HS + Rembrandt RADEON 680M (integrated)
  # Includes power management module for notebook
}
