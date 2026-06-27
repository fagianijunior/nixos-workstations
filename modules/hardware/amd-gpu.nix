{ config, pkgs, lib, ... }:

{
  # AMD GPU - AMDGPU open-source driver with Vulkan (RADV - default)
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Required for Steam/Wine 32-bit games
    extraPackages = with pkgs; [
      rocmPackages.clr # OpenCL runtime (needed for Folding@home GPU compute)
    ];
  };

  # RADV is the default Vulkan driver in NixOS unstable
  # No need to set AMD_VULKAN_ICD as amdvlk has been removed

  # AMDGPU kernel module
  boot.initrd.kernelModules = [ "amdgpu" ];

  # Video/GPU diagnostic tools
  environment.systemPackages = with pkgs; [
    vulkan-tools
    vulkan-loader
    libva-utils
    mesa-demos
    clinfo # Verify OpenCL devices
  ];
}
