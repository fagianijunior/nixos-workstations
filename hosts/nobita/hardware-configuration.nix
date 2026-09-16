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

  # LUKS encryption (disco de sistema: nvme0n1)
  # Partição root criptografada -> aberta como /dev/mapper/cryptroot
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/730151f5-c75c-411c-811a-9355851a2215";
    allowDiscards = true; # Enable TRIM for NVMe
  };

  # Root (ext4 dentro do LUKS)
  fileSystems."/" = {
    device = "/dev/mapper/cryptroot";
    fsType = "ext4";
    neededForBoot = true;
  };

  # /home permanece no NVMe antigo (nvme1n1p1), ext4 não-criptografado
  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/d24c93e7-4461-4fbe-878e-430a8f20ce4d";
    fsType = "ext4";
  };

  # EFI boot partition (nvme0n1p1)
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/4523-78B9";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
    neededForBoot = true;
  };

  # Encrypted swap (LUKS) with hibernation support (nvme0n1p3)
  # Partição swap criptografada -> aberta como /dev/mapper/cryptswap
  boot.initrd.luks.devices."cryptswap" = {
    device = "/dev/disk/by-uuid/e3af53e0-8bf9-4bd4-817e-108ccfa5883b";
    allowDiscards = true; # Enable discard/TRIM for swap on SSDs.
  };
  swapDevices = [
    { device = "/dev/mapper/cryptswap"; }
  ];
  boot.resumeDevice = "/dev/mapper/cryptswap";

  services.fstrim.enable = true;

  # Hardware platform
  # TUF GAMING B450-PLUS II (ATX), AMD Ryzen 7 5700, Navi 23 RX 6600 XT
  #
  # BIOS / firmware:
  #   Atualizado de 4645 -> 4655 (2026/08/27) como mitigação de freeze duro no
  #   early boot (prompt do LUKS), sem log no journal. A 4655 traz AGESA
  #   ComboV2 PI 1.2.0.12, que reinicializa CPU/PSP/CCP -- candidato a corrigir o
  #   erro "ccp: unable to access the device: you might be running a broken BIOS"
  #   visto no dmesg. Também mitiga CVEs de fTPM (não usado aqui; LUKS é por passphrase).
  #   Arquivo de BIOS Flashback desta placa: TB450PS2.CAP
  #   SHA-256 4655: 99d0f3dc2f4ce9012b1b8e1e5f9b5fd7b00d61927c5f5efc9cc44e63f39448ca
  #   Complementa o fix amdgpu.gpu_recovery=1 em modules/hardware/amd-gpu.nix.
  #
  #   Efeito colateral pós-flash 4655: o driver do Wi-Fi (Realtek RTL8852BE,
  #   rtw89_8852be) deixou de carregar automaticamente no boot -- chip visível no
  #   lspci, mas sem rádio (phy0) nem interface wlan. Corrigido forçando o módulo
  #   via boot.kernelModules em hosts/nobita/default.nix.
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.enableRedistributableFirmware = true;
}
