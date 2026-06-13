{ pkgs, self, ... }:

pkgs.testers.nixosTest {
  name = "pipewire-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [
      ../modules/common
      ../modules/services/pipewire.nix
    ];

    fileSystems."/" = {
      device = "/dev/vda1";
      fsType = "ext4";
    };
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  };

  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")

    # Verify PulseAudio system service is NOT running
    machine.fail("systemctl is-active pulseaudio.service")

    # Verify PipeWire binaries are available in the system
    machine.succeed("which pipewire")
    machine.succeed("which wireplumber")
    machine.succeed("which pw-cli")

    # Verify PipeWire configuration exists
    machine.succeed("test -d /etc/pipewire || find /nix/store -path '*/etc/pipewire' -type d | head -1 | grep -q pipewire")
  '';
}
