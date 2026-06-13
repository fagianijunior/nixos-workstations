{ pkgs, self, ... }:

pkgs.testers.nixosTest {
  name = "home-manager-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [
      ../modules/common
    ];

    fileSystems."/" = {
      device = "/dev/vda1";
      fsType = "ext4";
    };
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # Simulate Home Manager activation without full flake import
    # Test verifies user exists and basic structure
    services.getty.autologinUser = "terabytes";
  };

  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")

    # Verify user terabytes exists
    machine.succeed("id terabytes")

    # Verify user has correct home directory
    output = machine.succeed("getent passwd terabytes | cut -d: -f6")
    assert "/home/terabytes" in output, f"Wrong home directory: {output}"

    # Verify user is in correct groups
    output = machine.succeed("groups terabytes")
    assert "wheel" in output, f"Missing wheel group: {output}"
    assert "video" in output, f"Missing video group: {output}"
    assert "audio" in output, f"Missing audio group: {output}"

    # Verify home directory exists and has correct permissions
    machine.succeed("test -d /home/terabytes")
    output = machine.succeed("stat -c '%U' /home/terabytes")
    assert "terabytes" in output, f"Wrong owner: {output}"

    # Wait for user login
    machine.wait_until_succeeds("pgrep -u terabytes")

    # Verify XDG directories can be created
    machine.succeed("su - terabytes -c 'mkdir -p ~/Documents ~/Downloads ~/Pictures ~/Videos'")
    machine.succeed("test -d /home/terabytes/Documents")
    machine.succeed("test -d /home/terabytes/Downloads")
  '';
}
