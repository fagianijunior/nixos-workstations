{ config, pkgs, lib, ... }:

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
          DNS = [ "1.1.1.1" "8.8.8.8" ];
        };
        dhcpV4Config = {
          RouteMetric = 100;
        };
      };
      "25-wireless" = {
        matchConfig.Type = "wlan";
        networkConfig = {
          DHCP = "yes";
          DNS = [ "1.1.1.1" "8.8.8.8" ];
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
      DNSSEC = "allow-downgrade";
      Domains = [ "~." ];
      FallbackDNS = [ "1.1.1.1" "8.8.8.8" ];
    };
  };

  # tailscale
  services.tailscale.enable = true;
}
