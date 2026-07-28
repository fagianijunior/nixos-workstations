{ pkgs, ... }:

{
  services.ollama = {
    enable = true;
    package = pkgs.ollama-rocm;

    # RX 6600 XT = Navi 23 (real: gfx1032, unsupported by rocblas)
    # Override to gfx1030 which IS supported and compatible
    rocmOverrideGfx = "10.3.0";

    # Listen on all interfaces so other machines on LAN can use it
    host = "0.0.0.0";
    openFirewall = true;
  };
}
