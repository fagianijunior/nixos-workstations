{ config, pkgs, ... }:

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

  # Suspend: resolvido via BIOS (perfil terabytes1, set/2026):
  # - D.O.C.P. DDR4-3200 habilitado
  # - Global C-state Control [Disabled]
  # - SVM Mode [Enabled]
  # Com essas configurações + kernel zen 7.2.4, o suspend S3 "deep" funciona corretamente.
  # Kernel zen segue o padrão do modules/common (sem override aqui).

  # Wi-Fi: força o carregamento do driver do Realtek RTL8852BE (Wi-Fi 6, PCI 10ec:b852).
  # Após o flash da BIOS 4655, o autoload do módulo deixou de ocorrer no boot: o chip
  # aparecia no lspci, mas o módulo rtw89_8852be não carregava, então não havia rádio Wi-Fi
  # (phy0) nem interface para o iwd criar a wlan. Carregar explicitamente resolve.
  boot.kernelModules = [ "rtw89_8852be" ];

  # Regras udev do nobita:
  # - Logitech Bolt (046d:c548): desabilita wakeup do receptor (evita acordar por engano).
  # - devcoredump: captura automática do dump da GPU assim que o kernel o cria (ver serviço abaixo).
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c548", ATTR{power/wakeup}="disabled"
    ACTION=="add", SUBSYSTEM=="devcoredump", RUN+="${pkgs.systemd}/bin/systemctl start gpu-coredump-capture@%k.service"
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

  # Captura automática do devcoredump da GPU (acionada pela regra udev acima).
  # O devcoredump (/sys/.../devcoredump/data) só existe por ~5 min após um travamento da GPU
  # e some no reboot, o que torna a captura manual uma corrida contra o tempo. Este serviço
  # copia o 'data' para /var/log/gpu-dumps/ com timestamp, preservando-o para análise posterior
  # (ex.: reportar bug do amdgpu do SDMA timeout no resume da RX 6600 XT).
  systemd.services."gpu-coredump-capture@" = {
    description = "Salva o devcoredump da GPU (%i) antes de expirar";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "capture-gpu-coredump" ''
        set -eu
        dev_name="$1"
        dev="/sys/class/devcoredump/$dev_name"
        [ -r "$dev/data" ] || exit 0
        mkdir -p /var/log/gpu-dumps
        ts="$(${pkgs.coreutils}/bin/date +%Y%m%d-%H%M%S)"
        ${pkgs.coreutils}/bin/cp "$dev/data" "/var/log/gpu-dumps/gpu-dump-$dev_name-$ts.bin"
        # Também salva o dmesg recente, que dá contexto ao dump.
        ${pkgs.util-linux}/bin/dmesg > "/var/log/gpu-dumps/dmesg-$dev_name-$ts.txt" 2>/dev/null || true
        ${pkgs.systemd}/bin/systemd-cat -t gpu-coredump ${pkgs.coreutils}/bin/echo "devcoredump $dev_name salvo em /var/log/gpu-dumps"
      ''} %i";
    };
  };
}
