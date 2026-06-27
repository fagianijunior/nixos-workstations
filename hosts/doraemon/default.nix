{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./keyboard-resume.nix
    ../../modules/common
    ../../modules/hardware/amd-gpu.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/services/pipewire.nix
    ../../modules/services/networking.nix
    ../../modules/services/ssh.nix
    ../../modules/services/foldingathome.nix
    ../../modules/services/gaming.nix
    ../../modules/desktop/hyprland.nix
    ../../modules/desktop/catppuccin.nix
    ../../modules/security/hardening.nix
    ../../modules/services/power-management.nix
  ];

  # Hostname
  networking.hostName = "doraemon";

  # Console keymap
  console.keyMap = "br-abnt2";

  # Doraemon-specific: Lenovo IdeaPad Slim 3 15ARP10
  # AMD Ryzen 7 7735HS + Rembrandt RADEON 680M (integrated)
  # Includes power management module for notebook
}
