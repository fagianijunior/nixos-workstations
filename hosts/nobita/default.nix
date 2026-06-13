{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common
    ../../modules/hardware/amd-gpu.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/services/pipewire.nix
    ../../modules/services/networking.nix
    ../../modules/services/gaming.nix
    ../../modules/desktop/hyprland.nix
    ../../modules/desktop/catppuccin.nix
    ../../modules/security/hardening.nix
  ];

  # Hostname
  networking.hostName = "nobita";

  # Console keymap
  console.keyMap = "us";

  # Nobita-specific: Desktop with AMD Ryzen 7 5700 + RX 6600 XT
  # No power management module (desktop)
}
