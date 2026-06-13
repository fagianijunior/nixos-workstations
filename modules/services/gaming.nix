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
  ];
}
