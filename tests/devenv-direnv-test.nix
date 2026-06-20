{ pkgs, self, ... }:

pkgs.testers.nixosTest {
  name = "devenv-direnv-test";

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
  };

  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")

    # Verify devenv is installed and accessible
    machine.succeed("which devenv")
    machine.succeed("devenv version")

    # Verify nix.conf contains devenv cachix substituter
    machine.succeed("grep -q 'devenv.cachix.org' /etc/nix/nix.conf")

    # Verify nix.conf contains devenv cachix trusted public key
    machine.succeed("grep -q 'devenv.cachix.org-1' /etc/nix/nix.conf")

    # Verify trusted-users includes @wheel
    machine.succeed("grep -q '@wheel' /etc/nix/nix.conf")

    # Verify experimental-features includes flakes
    machine.succeed("grep -q 'flakes' /etc/nix/nix.conf")
  '';
}
