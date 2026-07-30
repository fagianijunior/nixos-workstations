{ pkgs, ... }:

{
  # Disable NetworkManager
  networking.networkmanager.enable = false;

  # Disable dhcpcd (using systemd-networkd instead)
  networking.useDHCP = false;

  # Enable iwd for Wi-Fi management (terminal-based via iwctl)
  networking.wireless.iwd = {
    enable = true;
    settings = {
      General = {
        EnableNetworkConfiguration = true;
      };
      Network = {
        NameResolvingService = "systemd";
      };
      Settings = {
        AutoConnect = true;
      };
    };
  };

  # systemd-networkd for Ethernet
  systemd.network = {
    enable = true;
    networks = {
      "20-wired" = {
        matchConfig.Type = "ether";
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
          DNS = [ "1.1.1.2" "9.9.9.9" "2606:4700:4700::1112" "2620:fe::fe" ];
        };
        dhcpV4Config = {
          RouteMetric = 100;
        };
      };
      "25-wireless" = {
        matchConfig.Type = "wlan";
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
          DNS = [ "1.1.1.2" "9.9.9.9" "2606:4700:4700::1112" "2620:fe::fe" ];
        };
        dhcpV4Config = {
          RouteMetric = 600;
        };
      };
    };
  };

  # DNS resolution via systemd-resolved
  services.resolved = {
    enable = true;
    settings.Resolve = {
      # DNSSEC validation disabled locally — Cloudflare (1.1.1.2) and Quad9 (9.9.9.9)
      # already perform DNSSEC validation upstream. Local validation with "allow-downgrade"
      # causes resolution failures when ISP middleboxes strip DNSSEC signatures,
      # resulting in "no-signature" errors and total DNS loss until service restart.
      DNSSEC = "no";
      DNSOverTLS = "opportunistic";
      Domains = [ "~." ];
      FallbackDNS = [ "1.1.1.2" "9.9.9.9" "2606:4700:4700::1112" "2620:fe::fe" ];
    };
  };

  # Prefer IPv4 over IPv6 for outgoing connections (gai.conf)
  # IPv6 infrastructure in Brazil has high latency (Miami routing),
  # causing Happy Eyeballs fallback delays and occasional timeouts.
  # IPv6 remains fully functional — only connection preference order changes.
  environment.etc."gai.conf".text = ''
    # Prefer IPv4 (precedence 100) over IPv6 (precedence 20) for Brazilian ISPs
    # where IPv6 routes to international PoPs instead of local infrastructure.
    precedence ::ffff:0:0/96  100
    precedence ::/0            20
  '';

  # Fix: wait-online should succeed when any interface is online
  # Prevents boot failure when wireless isn't ready yet
  systemd.network.wait-online.anyInterface = true;

  # tailscale
  services.tailscale.enable = true;

  # Unblock Wi-Fi on boot (some hardware soft-blocks wlan by default)
  systemd.services.rfkill-unblock-wlan = {
    description = "Unblock WLAN at boot";
    after = [ "systemd-rfkill.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.util-linux}/bin/rfkill unblock wlan";
    };
  };
}
