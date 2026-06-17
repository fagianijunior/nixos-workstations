{ config, pkgs, ... }:

let
  # Python with Google Calendar API dependencies
  pythonWithGoogleAPI = pkgs.python3.withPackages (ps: with ps; [
    google-api-python-client
    google-auth-httplib2
    google-auth-oauthlib
    requests
  ]);
in
{
  programs.quickshell = {
    enable = true;
    systemd.enable = true;
  };

  # Python with Google API packages available as standalone binary
  # (not in home.packages to avoid conflicts with system python3)
  home.file.".local/bin/python3-google".source = "${pythonWithGoogleAPI}/bin/python3";

  # Mutable QuickShell config — edit QML files directly, reload with quickshell
  xdg.configFile."quickshell".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/Workspace/fagianijunior/nixos/home/quickshell/config";
}
