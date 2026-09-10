{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common
    ../../modules/hardware/amd-gpu.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/hardware/solaar.nix
    ../../modules/services/pipewire.nix
    ../../modules/services/networking.nix
    ../../modules/services/ssh.nix
    ../../modules/services/foldingathome.nix
    ../../modules/services/ollama.nix
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

  # Kernel: recuar do zen 7.2.x para o linuxPackages padrão (6.18) SOMENTE neste host.
  # Motivo: o zen 7.2.3 tem uma regressão do amdgpu em RDNA2 que trava a GPU com
  # "WARNING ... ttm_bo_move_sync_cleanup" seguido de loop infinito de "ring sdma[01] timeout"
  # ao mover buffers entre VRAM/RAM (submissão do Hyprland/quickshell e no resume de suspend).
  # gpu_recovery, s2idle e o próprio 7.2.3 não resolveram. O 6.18 é anterior a essa regressão
  # e tem suporte maduro à RX 6600 XT. O doraemon segue no zen (definido em modules/common).
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages;

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
