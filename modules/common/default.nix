{ config, pkgs, lib, ... }:

{
  # Nix settings
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      trusted-users = [ "root" "@wheel" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 15d";
    };
  };

  # Allow unfree packages (Steam, etc.) — set in modules/services/gaming.nix
  # nixpkgs.config is intentionally NOT set here to avoid conflicts with test framework

  # Bootloader - systemd-boot (UEFI)
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 20;
      editor = false; # Security: prevent kernel cmdline editing at boot
    };
    efi.canTouchEfiVariables = true;
  };

  # Locale
  i18n = {
    defaultLocale = "pt_BR.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "pt_BR.UTF-8";
      LC_IDENTIFICATION = "pt_BR.UTF-8";
      LC_MEASUREMENT = "pt_BR.UTF-8";
      LC_MONETARY = "pt_BR.UTF-8";
      LC_NAME = "pt_BR.UTF-8";
      LC_NUMERIC = "pt_BR.UTF-8";
      LC_PAPER = "pt_BR.UTF-8";
      LC_TELEPHONE = "pt_BR.UTF-8";
      LC_TIME = "pt_BR.UTF-8";
    };
    supportedLocales = [
      "pt_BR.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
    ];
  };

  # Timezone
  time.timeZone = "America/Fortaleza";

  # Console keymap - set per host (see hosts/*/default.nix)
  # console.keyMap is configured in each host

  # User
  users.users.terabytes = {
    isNormalUser = true;
    description = "Carlos Fagiani Junior";
    extraGroups = [ "wheel" "video" "audio" ];
    shell = pkgs.fish;
  };

  # Security: require password for sudo
  security.sudo = {
    enable = true;
    execWheelOnly = true;
  };

  # Fish shell
  programs.fish.enable = true;

  # Base system packages
  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
    htop
    btop
    tree
    unzip
    file
    pciutils
    usbutils
    lsof
  ];

  # Enable dbus
  services.dbus.enable = true;

  # System state version
  system.stateVersion = "25.11";
}
