{ config, pkgs, lib, ... }:

{
  # Catppuccin Macchiato system-wide theme
  # Uses the catppuccin/nix flake module (imported in flake.nix)
  catppuccin = {
    enable = true;
    autoEnable = true;
    flavor = "macchiato";
    accent = "blue";
  };
}
