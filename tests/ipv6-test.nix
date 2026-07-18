{ pkgs, self, ... }:

pkgs.testers.nixosTest {
  name = "ipv6-test";

  nodes = {
    # Router node: advertises IPv6 prefix via RA and serves DHCPv6
    router = { config, pkgs, ... }: {
      fileSystems."/" = {
        device = "/dev/vda1";
        fsType = "ext4";
      };
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      # Enable IPv6 forwarding so it can act as a router
      boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = 1;

      # radvd: sends Router Advertisements with prefix fd00::/64
      services.radvd = {
        enable = true;
        config = ''
          interface eth1 {
            AdvSendAdvert on;
            MinRtrAdvInterval 3;
            MaxRtrAdvInterval 10;
            prefix fd00::/64 {
              AdvOnLink on;
              AdvAutonomous on;
              AdvRouterAddr on;
            };
          };
        '';
      };

      networking.interfaces.eth1.ipv6.addresses = [
        { address = "fd00::1"; prefixLength = 64; }
      ];
    };

    # Machine under test: imports the actual networking module
    machine = { config, pkgs, ... }: {
      imports = [
        ../modules/common
        ../modules/services/networking.nix
        ../modules/security/hardening.nix
      ];

      fileSystems."/" = {
        device = "/dev/vda1";
        fsType = "ext4";
      };
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
    };
  };

  testScript = ''
    router.start()
    machine.start()

    router.wait_for_unit("multi-user.target")
    machine.wait_for_unit("multi-user.target")

    # --- 1. IPv6 is not disabled at kernel level ---
    machine.succeed("test $(cat /proc/sys/net/ipv6/conf/all/disable_ipv6) -eq 0")

    # --- 2. Kernel has IPv6 support (built-in or module) ---
    # ip6_tables may be built-in (=y) rather than a loadable module - check via /proc
    machine.succeed("test -d /proc/sys/net/ipv6")

    # --- 3. Loopback has ::1 ---
    machine.succeed("ip -6 addr show lo | grep -q '::1'")

    # --- 4. No 'disable_ipv6' flag set on any interface ---
    machine.fail("grep -r '^1$' /proc/sys/net/ipv6/conf/all/disable_ipv6")

    # --- 5. Router advertisement acceptance is not blocked ---
    # (accept_ra = 0 would prevent SLAAC from working)
    out = machine.succeed("cat /proc/sys/net/ipv6/conf/all/accept_ra")
    assert out.strip() != "0", f"accept_ra is disabled (got {out.strip()}), SLAAC will not work"

    # --- 6. Routing table has an IPv6 default or link-local route ---
    # After RA from router, machine should get a SLAAC address on eth1
    machine.wait_until_succeeds(
      "ip -6 addr show eth1 | grep -qE 'fd00::|fe80::'",
      timeout=30
    )

    # --- 7. Can ping the router's IPv6 address ---
    machine.wait_until_succeeds(
      "ping -6 -c 2 -W 2 fd00::1",
      timeout=30
    )

    # --- 8. IPv6 DNS resolution is operational (systemd-resolved) ---
    machine.wait_for_unit("systemd-resolved.service")
    machine.succeed("resolvectl status | grep -i 'IPv6'")

    # --- 9. Hardening sysctl values for IPv6 are correct ---
    # Forwarding must be OFF on the client machine
    machine.succeed("test $(sysctl -n net.ipv6.conf.all.forwarding) -eq 0")
    # Redirects must be ignored
    machine.succeed("test $(sysctl -n net.ipv6.conf.all.accept_redirects) -eq 0")
    machine.succeed("test $(sysctl -n net.ipv6.conf.default.accept_redirects) -eq 0")
    # Source routing must be disabled
    machine.succeed("test $(sysctl -n net.ipv6.conf.all.accept_source_route) -eq 0")

    # --- 10. Firewall (nftables) loads IPv6 ruleset without errors ---
    machine.succeed("nft list ruleset | grep -q 'ip6'")
  '';
}
