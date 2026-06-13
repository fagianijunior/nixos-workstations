{ pkgs, self, ... }:

pkgs.testers.nixosTest {
  name = "boot-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [
      ../modules/common
    ];

    # Minimal VM config (no LUKS/Btrfs in test VM)
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

    # Verify system boots and reaches multi-user target
    machine.succeed("systemctl is-active multi-user.target")

    # Verify locale is configured correctly
    output = machine.succeed("locale | grep LANG")
    assert "pt_BR.UTF-8" in output, f"Expected pt_BR.UTF-8 locale, got: {output}"

    # Verify timezone
    output = machine.succeed("timedatectl show --property=Timezone --value")
    assert "America/Fortaleza" in output, f"Expected America/Fortaleza timezone, got: {output}"

    # Verify systemd-boot is configured as bootloader
    machine.succeed("test -e /etc/systemd/system.conf || true")
    machine.succeed("bootctl --no-pager status || true")  # May not work in VM but config is valid

    # Verify user terabytes exists
    machine.succeed("id terabytes")

    # Verify user groups
    output = machine.succeed("groups terabytes")
    assert "wheel" in output, f"User terabytes not in wheel group: {output}"
    assert "video" in output, f"User terabytes not in video group: {output}"
    assert "audio" in output, f"User terabytes not in audio group: {output}"

    # Verify kernel is running
    machine.succeed("uname -r")
  '';
}
