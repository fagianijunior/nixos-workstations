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

  # Fix: congelamento (freeze) da tela poucos segundos após o boot na RX 6600 XT (Navi 23 / RDNA2).
  # Sintoma: tela congela com a última imagem, sem log de erro no journal (hang duro instantâneo).
  # - amdgpu.gpu_recovery=1: força o GPU recovery, que reseta a GPU ao detectar um hang em vez de
  #   deixar o sistema travado. Comprovado estável nesta máquina (live-USB e boot anterior),
  #   funcionando em kernels distintos.
  boot.kernelParams = [
    "amdgpu.gpu_recovery=1"
  ];

  # Video/GPU diagnostic tools
  environment.systemPackages = with pkgs; [
    vulkan-tools
    vulkan-loader
    libva-utils
    mesa-demos
    clinfo # Verify OpenCL devices
  ];
}
