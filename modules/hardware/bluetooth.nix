{ pkgs, ... }:

{
  # Bluetooth via bluez - managed with bluetoothctl (no GUI/applet)
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        # Enable foi removida no BlueZ 5.x recente - perfis são habilitados
        # automaticamente quando o WirePlumber registra os endpoints
        Experimental = true;
      };
    };
  };

  # Bluetooth CLI tools only
  environment.systemPackages = with pkgs; [
    bluez
    bluetui
  ];
}
