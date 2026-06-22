{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common
    ../../modules/hardware/amd-gpu.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/services/pipewire.nix
    ../../modules/services/networking.nix
    ../../modules/services/ssh.nix
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

  # Disable USB wakeup for Logitech Bolt receiver (046d:c548)
  # Prevents the receiver from waking the machine after suspend/hibernate
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c548", ATTR{power/wakeup}="disabled"
  '';

  # Also disable wakeup on the USB controller (XHC0) to prevent any USB device from waking
  systemd.services.disable-usb-wakeup = {
    description = "Disable USB controller wakeup (XHC0)";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'echo XHC0 > /proc/acpi/wakeup || true'";
    };
  };
}
