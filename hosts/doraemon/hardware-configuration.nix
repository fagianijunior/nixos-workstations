{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Kernel modules
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "thunderbolt"
    "usbhid"
    "sd_mod"
    "sdhci_pci"
  ];
  boot.initrd.kernelModules = [ "amdgpu" "dm-snapshot" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # LUKS encryption
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/1c8c316d-091c-4d26-b4b9-ab6012041559";
    preLVM = true;
    allowDiscards = true; # Enable TRIM for NVMe
  };

  # Btrfs subvolumes
  fileSystems."/" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=@" "compress=zstd" "noatime" ];
  };

  fileSystems."/home" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=@home" "compress=zstd" "noatime" ];
  };

  fileSystems."/nix" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=@nix" "compress=zstd" "noatime" ];
  };

  fileSystems."/.snapshots" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=@snapshots" "compress=zstd" "noatime" ];
  };

  # EFI boot partition
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/3C14-B281";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  # Swap with hibernation support
  swapDevices = [
    {
      device = "/dev/disk/by-uuid/4301fbe5-a9db-4c24-a4b3-24a18495d6da";
      options = [ "discard" ];
    }
  ];
  boot.resumeDevice = "/dev/disk/by-uuid/4301fbe5-a9db-4c24-a4b3-24a18495d6da";

  # Hardware platform
  # Lenovo IdeaPad Slim 3 15ARP10, AMD Ryzen 7 7735HS, Rembrandt RADEON 680M
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.enableRedistributableFirmware = true;

  # Backlight control for notebook
  hardware.acpilight.enable = true;
}
