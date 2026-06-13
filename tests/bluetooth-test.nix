{ pkgs, self, ... }:

pkgs.testers.nixosTest {
  name = "bluetooth-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [
      ../modules/common
      ../modules/hardware/bluetooth.nix
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

    # Verify bluetooth service is enabled (may not be active without hardware)
    machine.succeed("systemctl is-enabled bluetooth.service")

    # Verify bluetoothctl binary is available
    machine.succeed("which bluetoothctl")

    # Verify bluez is installed
    machine.succeed("bluetoothctl --version")
  '';
}
