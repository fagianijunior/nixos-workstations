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

  # Fix: tela apagando ao voltar da hibernação (prompt LUKS)
  # - amdgpu.sg_display=0: desativa scatter/gather display (bug em APUs Rembrandt no resume)
  # - video=eDP-1:1920x1080@60: força resolução fixa no console, evitando troca de modo
  boot.kernelParams = [
    "amdgpu.sg_display=0"
    "video=eDP-1:1920x1200@60"
  ];

  # Fix: PSP resume failed (-22) ao voltar de hibernação
  # Serializa device resume para eliminar race conditions entre amdgpu e outros dispositivos.
  # Ref: https://community.frame.work/t/hibernate-resume-failures-on-framework-13-amd-ryzen-ai-300-krackan-a-b-tested-workaround-pm-async-0/83040
  systemd.tmpfiles.rules = [
    "w /sys/power/pm_async - - - - 0"
  ];

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

  # Encrypted swap (LUKS) with hibernation support
  # TODO: Em reinstalação futura, considerar:
  #   - Swap como subvolume/swapfile dentro do cryptroot (elimina partição e LUKS separados)
  #   - Ou swap como LV dentro de um LVM-on-LUKS (mais flexível para resize)
  # Ambas opções eliminam a necessidade de keyfile separado no initrd.
  boot.initrd.luks.devices."cryptswap" = {
    device = "/dev/disk/by-uuid/c8c83c67-1aa8-4875-9bcc-1e10e7de1e7d";
    allowDiscards = true;
  };
  swapDevices = [
    { device = "/dev/mapper/cryptswap"; }
  ];
  boot.resumeDevice = "/dev/mapper/cryptswap";

  # Hardware platform
  # Lenovo IdeaPad Slim 3 15ARP10, AMD Ryzen 7 7735HS, Rembrandt RADEON 680M
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.enableRedistributableFirmware = true;

  # Backlight control for notebook
  hardware.acpilight.enable = true;
}
