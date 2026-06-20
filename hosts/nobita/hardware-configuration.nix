{ config, lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Kernel modules
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];
  
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/8f4d7ea0-475b-4c46-b01a-a2e98fca897d";
    fsType = "ext4";
    neededForBoot = true;
  };

  fileSystems."/home" = {
      device = "/dev/disk/by-uuid/d24c93e7-4461-4fbe-878e-430a8f20ce4d";
      fsType = "ext4";
    };

  # EFI boot partition
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/9F4B-576C";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
    neededForBoot = true;
  };


  # Swap with hibernation support
  swapDevices = [
    {
      device = "/dev/disk/by-uuid/336bdc5c-2367-4569-a0c3-965923750214";
      options = [ "discard" "nofail" ]; # Enable discard/TRIM for swap on SSDs.
    }
  ];
  boot.resumeDevice = "/dev/disk/by-uuid/336bdc5c-2367-4569-a0c3-965923750214";

  # Hardware platform
  # TUF GAMING B450-PLUS II, AMD Ryzen 7 5700, Navi 23 RX 6600 XT
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.enableRedistributableFirmware = true;
}
