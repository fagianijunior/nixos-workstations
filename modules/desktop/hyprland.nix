{ pkgs, lib, ... }:

{
  # Hyprland Wayland compositor
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # XDG Desktop Portal
  # O portal é o que habilita captura/compartilhamento de tela (ScreenCast)
  # no Wayland para Steam, Discord, OBS, navegadores, etc.
  xdg.portal = {
    enable = true;
    # `programs.hyprland` + o módulo xdg.portal já injetam automaticamente o
    # xdg-desktop-portal-hyprland (via portalPackage) e o gtk. Declará-los de
    # novo aqui fazia a lista agregada conter o mesmo pacote duas vezes, e a
    # geração do diretório user-units falhava ao criar o segundo symlink
    # idêntico (ln: failed to create symbolic link
    # 'xdg-desktop-portal-hyprland.service': File exists).
    # `lib.mkForce [ ... ]` com `lib.unique` garante uma lista sem duplicatas
    # mantendo os dois backends que queremos: hyprland (ScreenCast/Screenshot)
    # e gtk (FileChooser e demais diálogos).
    extraPortals = lib.mkForce (lib.unique [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ]);
    # Roteia cada interface para o backend correto. Sem isso o seletor de
    # tela pode não aparecer em algumas versões.
    config = {
      common = {
        default = [ "hyprland" "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "hyprland" ];
      };
    };
  };

  # Login manager - greetd with tuigreet
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd start-hyprland";
        user = "greeter";
      };
    };
  };

  # Wayland environment variables
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    GDK_BACKEND = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
  };

  # Desktop support packages
  environment.systemPackages = with pkgs; [
    wl-clipboard       # Clipboard manager for Wayland
    grim               # Screenshot utility (também usado pelo hypruse MCP)
    wtype              # Teclado virtual Wayland (input do hypruse MCP)
    slurp              # Region selector
    wl-screenrec       # Screen recorder (VA-API hardware encoding)
    wlsunset           # Blue light filter
    brightnessctl      # Backlight control
    pamixer              # PulseAudio/PipeWire CLI mixer
    playerctl          # Media player control
    libnotify          # Notification library
  ];

  # Enable polkit for privilege escalation
  security.polkit.enable = true;

  # Fonts
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
    ];
    fontconfig = {
      defaultFonts = {
        serif = [ "Noto Serif" ];
        sansSerif = [ "Noto Sans" ];
        monospace = [ "JetBrainsMono Nerd Font" ];
      };
    };
  };
}
