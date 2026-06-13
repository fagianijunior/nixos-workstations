{ pkgs, self, ... }:

pkgs.testers.nixosTest {
  name = "power-management-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [
      ../modules/common
      ../modules/services/power-management.nix
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

    # Verify TLP service is active
    machine.wait_for_unit("tlp.service")
    machine.succeed("systemctl is-active tlp.service")

    # Verify power-profiles-daemon is NOT running (conflicts with TLP)
    machine.fail("systemctl is-active power-profiles-daemon.service")

    # Verify TLP configuration is applied
    machine.succeed("tlp-stat --config | grep -q 'CPU_SCALING_GOVERNOR_ON_AC'")

    # Verify logind lid switch configuration
    output = machine.succeed("cat /etc/systemd/logind.conf.d/*.conf || cat /etc/systemd/logind.conf")
    assert "HandleLidSwitch" in output, f"Lid switch not configured: {output}"
  '';
}
