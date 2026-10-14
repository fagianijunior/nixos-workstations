{ config, pkgs, lib, ... }:

{
  # Allow unfree packages for Steam
  nixpkgs.config.allowUnfree = true;

  # Steam
  # Áudio: o Steam usa PipeWire automaticamente via camada de compatibilidade
  # PulseAudio (services.pipewire.pulse.enable = true em modules/services/pipewire.nix),
  # que já está ativa quando a sessão sobe. Nenhuma config extra é necessária.
  #
  # Captura/compartilhamento de tela: habilitado pelo portal ScreenCast do
  # Wayland (xdg.portal em modules/desktop/hyprland.nix) + PipeWire.
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
    # Traduz eventos de input X11 para uinput — necessário para Steam Input
    # funcionar corretamente sob Wayland/XWayland.
    extest.enable = true;
  };

  # Gamemode - optimize system for gaming
  programs.gamemode.enable = true;

  # Gaming packages
  environment.systemPackages = with pkgs; [
    lutris
    wine
    winetricks
    mangohud
    gamescope
    (retroarch.withCores (cores: with cores; [ cores.snes9x cores.genesis-plus-gx cores.beetle-psx-hw ]))
    retroarch-assets
    steam-rom-manager
    mudlet
  ];
}
