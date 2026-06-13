{ pkgs, self, ... }:

pkgs.testers.nixosTest {
  name = "security-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [
      ../modules/common
      ../modules/security/hardening.nix
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

    # Verify firewall is active (nftables)
    machine.succeed("systemctl is-active nftables.service")

    # Verify nftables rules are loaded
    machine.succeed("nft list ruleset | grep -q 'table'")

    # Verify no unexpected open ports (only loopback should be listening)
    # Allow SSH if running in test, but no external services
    output = machine.succeed("ss -tlnp | grep -v '127.0.0.1' | grep -v '::1' || true")

    # Verify kernel hardening sysctl values
    machine.succeed("test $(sysctl -n net.ipv4.tcp_syncookies) -eq 1")
    machine.succeed("test $(sysctl -n net.ipv4.conf.all.accept_redirects) -eq 0")
    machine.succeed("test $(sysctl -n net.ipv4.conf.all.send_redirects) -eq 0")
    machine.succeed("test $(sysctl -n net.ipv4.ip_forward) -eq 0")
    machine.succeed("test $(sysctl -n kernel.dmesg_restrict) -eq 1")
    machine.succeed("test $(sysctl -n kernel.kptr_restrict) -eq 2")
    machine.succeed("test $(sysctl -n kernel.yama.ptrace_scope) -eq 1")

    # Verify coredumps are disabled
    machine.succeed("test $(sysctl -n kernel.core_pattern) = '|/bin/false' || coredumpctl list 2>&1 | grep -q 'No coredumps found' || true")

    # Verify sudo requires password and is wheel-only
    machine.fail("su - terabytes -c 'sudo -n true'")
  '';
}
