{ pkgs, ... }:

{
  #############################
  # Keyboard resume workaround
  # (firmware / ACPI bug)
  #############################

  # Reload do módulo atkbd ao voltar do suspend
  powerManagement.resumeCommands = ''
    ${pkgs.kmod}/bin/rmmod atkbd || true
    ${pkgs.kmod}/bin/modprobe atkbd reset=1
  '';

  # Rebind direto no sysfs (casos mais teimosos)
  systemd.services.reset-internal-keyboard = {
    description = "Reset internal keyboard after resume (atkbd quirk)";
    wantedBy = [ "post-resume.target" ];
    after = [ "post-resume.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = false;
      ExecStart = ''
        set -e
        logger -t reset-internal-keyboard "Rebinding internal keyboard after resume"
        echo -n "serio0" > /sys/bus/serio/drivers/atkbd/unbind || true
        sleep 0.2
        echo -n "serio0" > /sys/bus/serio/drivers/atkbd/bind || true
      '';
    };
  };
}
