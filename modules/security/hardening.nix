{ config, pkgs, lib, ... }:

{
  # Firewall - nftables (SECURITY-07)
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ ]; # No open ports by default
    allowedUDPPorts = [ config.services.tailscale.port ];
    trustedInterfaces = [ "tailscale0" "docker0" "br-+" ];
    # Steam remote play ports are managed by programs.steam.remotePlay.openFirewall
  };
  networking.nftables.enable = true;

  # Kernel hardening (SECURITY-09)
  boot.kernel.sysctl = {
    # Enable IP forwarding (required for Docker networking)
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 0;

    # Disable bridge-nf-call-iptables: prevents nftables/iptables from filtering
    # bridge traffic between containers on the same network (Docker handles its own isolation)
    "net.bridge.bridge-nf-call-iptables" = 0;

    # Prevent SYN flood attacks
    "net.ipv4.tcp_syncookies" = 1;

    # Ignore ICMP redirects
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;

    # Don't send ICMP redirects
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;

    # Ignore source-routed packets
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;

    # Log martian packets
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.conf.default.log_martians" = 1;

    # Restrict dmesg access
    "kernel.dmesg_restrict" = 1;

    # Restrict kernel pointer exposure
    "kernel.kptr_restrict" = 2;

    # Disable unprivileged BPF
    "kernel.unprivileged_bpf_disabled" = 1;

    # Restrict ptrace
    "kernel.yama.ptrace_scope" = 1;
  };

  # Disable coredumps (SECURITY-09)
  systemd.coredump.settings.Coredump = {
    Storage = "none";
    ProcessSizeMax = "0";
  };

  # Fail-safe: services use systemd sandboxing (SECURITY-06, SECURITY-15)
  # Applied via systemd service hardening where applicable

  # No hardcoded credentials (SECURITY-12)
  # All secrets managed via sops-nix or agenix if needed in future
}
