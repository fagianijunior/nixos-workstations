{ config, pkgs, lib, ... }:

{
  # Bluetooth via bluez - managed with bluetoothctl (no GUI/applet)
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };

  # Bluetooth CLI tools only
  environment.systemPackages = with pkgs; [
    bluez
  ];
}
