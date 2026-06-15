{ pkgs, self, ... }:

pkgs.testers.nixosTest {
  name = "hyprland-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [
      ../modules/common
      ../modules/desktop/hyprland.nix
    ];

    fileSystems."/" = {
      device = "/dev/vda1";
      fsType = "ext4";
    };
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # Virtual display for testing
    virtualisation.qemu.options = [ "-vga virtio" ];
  };

  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")

    # Verify greetd service is active
    machine.wait_for_unit("greetd.service")
    machine.succeed("systemctl is-active greetd.service")

    # Verify Hyprland binary is available
    machine.succeed("which Hyprland")

    # Verify polkit is active
    machine.succeed("systemctl is-active polkit.service")

    # Verify essential Wayland tools are installed
    machine.succeed("which wl-copy")
    machine.succeed("which grim")
    machine.succeed("which slurp")
    machine.succeed("which wofi")
    machine.succeed("which brightnessctl")
    machine.succeed("which playerctl")
    machine.succeed("which pamixer")

    # Verify fonts are installed
    machine.succeed("fc-list | grep -qi 'JetBrainsMono'")
    machine.succeed("fc-list | grep -qi 'FiraCode'")
  '';
}
