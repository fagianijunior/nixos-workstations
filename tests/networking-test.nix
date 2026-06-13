{ pkgs, self, ... }:

pkgs.testers.nixosTest {
  name = "networking-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [
      ../modules/common
      ../modules/services/networking.nix
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

    # Verify iwd service is active
    machine.wait_for_unit("iwd.service")
    machine.succeed("systemctl is-active iwd.service")

    # Verify systemd-networkd is active
    machine.wait_for_unit("systemd-networkd.service")
    machine.succeed("systemctl is-active systemd-networkd.service")

    # Verify systemd-resolved is active
    machine.wait_for_unit("systemd-resolved.service")
    machine.succeed("systemctl is-active systemd-resolved.service")

    # Verify NetworkManager is NOT running
    machine.fail("systemctl is-active NetworkManager.service")

    # Verify iwctl binary is available
    machine.succeed("which iwctl")

    # Verify DNS resolution works (via systemd-resolved)
    machine.succeed("resolvectl status")
  '';
}
