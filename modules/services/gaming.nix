{ config, pkgs, lib, ... }:

{
  # Allow unfree packages for Steam
  nixpkgs.config.allowUnfree = true;

  # Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
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
  ];
}
