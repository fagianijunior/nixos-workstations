{ pkgs, self, ... }:

pkgs.testers.nixosTest {
  name = "gpu-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [
      ../modules/common
      ../modules/hardware/amd-gpu.nix
    ];

    fileSystems."/" = {
      device = "/dev/vda1";
      fsType = "ext4";
    };
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # In VM, amdgpu won't load but we can verify configuration
    virtualisation.qemu.options = [ "-vga virtio" ];
  };

  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")

    # Verify DRI device directory exists (virtio-gpu in VM)
    machine.succeed("test -d /dev/dri")

    # Verify hardware.graphics is enabled (Mesa drivers present)
    machine.succeed("test -d /run/opengl-driver")

    # Verify Vulkan ICD files are available (RADV)
    machine.succeed("ls /run/opengl-driver/share/vulkan/icd.d/ | grep -q .")

    # Verify vulkan-tools are installed
    machine.succeed("which vulkaninfo")

    # Verify glxinfo (mesa-demos) is available
    machine.succeed("which glxinfo || which eglinfo")
  '';
}
