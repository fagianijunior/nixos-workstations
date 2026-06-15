{ pkgs, self, ... }:

pkgs.testers.nixosTest {
  name = "desktop-tools-test";

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

    # Install desktop tools that would normally come from home-manager packages
    environment.systemPackages = with pkgs; [
      pyprland
      avizo
      cliphist
      hyprpicker
      poweralertd
      psi-notify
      hyprpolkitagent
      wezterm
      hyprlock
      hypridle
      wlogout
    ];
  };

  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")

    # Hyprland ecosystem tools
    machine.succeed("which pypr")
    machine.succeed("which hyprpicker")
    machine.succeed("which cliphist")
    machine.succeed("which poweralertd")
    machine.succeed("which hyprlock")
    machine.succeed("which hypridle")

    # Terminal
    machine.succeed("which wezterm")

    # Avizo (lightctl / volumectl)
    machine.succeed("which lightctl")
    machine.succeed("which volumectl")
    machine.succeed("which avizo-service")

    # Wlogout
    machine.succeed("which wlogout")

    # Polkit agent (installed in libexec, verify package is in system closure)
    machine.succeed("find /nix/store -maxdepth 1 -name '*hyprpolkitagent*' | grep -q .")

    # psi-notify
    machine.succeed("which psi-notify")
  '';
}
