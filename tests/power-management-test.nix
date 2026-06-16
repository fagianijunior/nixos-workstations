{ pkgs, self, ... }:

pkgs.testers.nixosTest {
  name = "power-management-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [
      ../modules/common
      ../modules/services/power-management.nix
    ];

    fileSystems."/" = {
      device = "/dev/vda1";
      fsType = "ext4";
    };
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # Simulate swap partition for hibernation tests
    swapDevices = [
      { device = "/dev/vda2"; }
    ];
    boot.resumeDevice = "/dev/vda2";
  };

  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")

    # Verify TLP service is active
    machine.wait_for_unit("tlp.service")
    machine.succeed("systemctl is-active tlp.service")

    # Verify power-profiles-daemon is NOT running (conflicts with TLP)
    machine.fail("systemctl is-active power-profiles-daemon.service")

    # Verify TLP configuration is applied
    machine.succeed("tlp-stat --config | grep -q 'CPU_SCALING_GOVERNOR_ON_AC'")

    # Verify logind lid switch is configured for hibernate
    output = machine.succeed("cat /etc/systemd/logind.conf.d/*.conf || cat /etc/systemd/logind.conf")
    assert "HandleLidSwitch=hibernate" in output, f"Lid switch not set to hibernate: {output}"
    assert "HandleLidSwitchExternalPower=hibernate" in output, f"Lid switch (external power) not set to hibernate: {output}"
    assert "HandleLidSwitchDocked=ignore" in output, f"Lid switch docked not set to ignore: {output}"

    # Verify hibernation is available as a sleep state
    sleep_states = machine.succeed("cat /sys/power/state")
    # Note: 'disk' means hibernation is supported by the kernel
    assert "disk" in sleep_states, f"Hibernation (disk) not in /sys/power/state: {sleep_states}"

    # Verify resume device is configured in kernel cmdline
    cmdline = machine.succeed("cat /proc/cmdline")
    assert "resume=" in cmdline, f"resume= not found in kernel cmdline: {cmdline}"
  '';
}
