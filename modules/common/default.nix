{ pkgs, ... }:

{
  # Nix settings
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      trusted-users = [ "root" "@wheel" ];

      # Devenv binary cache (avoid recompilation)
      substituters = [
        "https://cache.nixos.org/"
        "https://devenv.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      ];
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
    extraGroups = [ "wheel" "video" "audio" "docker" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFspHZN+DSFXVI3KD7hN5rbbu0GQizG5/EJkcGAD+it/ fagianijunior@gmail.com - Nobita"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA2laT3PwGK1fGwZKTjx1exNELxkr3WVk0Dq4HpIr3Py terabytes@doraemon"
    ];
  };

  # Security: require password for sudo
  security.sudo = {
    enable = true;
    execWheelOnly = true;
  };

  # nix-ld - dynamic linking for external binaries (e.g. kiro-cli)
  programs.nix-ld.enable = true;

  # Fish shell
  programs.fish.enable = true;

  # Base system packages
  environment.systemPackages = with pkgs; [
    git
    vim-full
    wl-clipboard
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
    viu
    devenv
    ssm-session-manager-plugin
    zip
    jq
    docker-compose
  ];

  # Docker
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # Enable dbus
  services.dbus.enable = true;

  # System state version
  system.stateVersion = "25.11";
}
