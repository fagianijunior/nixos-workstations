{ config, pkgs, lib, ... }:

{
  # TLP - Advanced power management for Linux (notebooks)
  services.tlp = {
    enable = true;
    settings = {
      # CPU
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      # Platform profile
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";

      # USB auto-suspend
      USB_AUTOSUSPEND = 1;

      # Wi-Fi power save
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";

      # Runtime PM
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";
    };
  };

  # Disable power-profiles-daemon (conflicts with TLP)
  services.power-profiles-daemon.enable = false;

  # Lid close actions — hibernate to preserve state on SSD
  services.logind.settings.Login = {
    HandleLidSwitch = "hibernate";
    HandleLidSwitchExternalPower = "hibernate";
    HandleLidSwitchDocked = "ignore";
  };

  # Hibernation support
  # boot.resumeDevice must be set in host hardware-configuration.nix
  # For dedicated swap partitions, no resume_offset is needed.

  # Fix: PSP resume falha no ACPI S4 platform path (AMD Rembrandt/Yellow Carp).
  # HibernateMode=shutdown faz cold boot e restaura imagem do disco,
  # evitando o ACPI platform resume que causa "PSP resume failed (-22)".
  systemd.sleep.settings.Sleep = {
    HibernateMode = "shutdown";
  };
}
