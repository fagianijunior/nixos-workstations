{ pkgs, ... }:

{
  # Install fah-client without the service (run manually as user)
  environment.systemPackages = [ pkgs.fahclient ];

  # ROCm/HIP libraries for FahCore (FHS binary that dlopen's libamdhip64.so via nix-ld)
  programs.nix-ld.libraries = with pkgs; [
    rocmPackages.clr              # libamdhip64.so
    rocmPackages.rocm-runtime     # libhsa-runtime64.so
    rocmPackages.rocm-device-libs # device bitcode libraries
    rocmPackages.clr.icd          # OpenCL ICD
  ];
}
