{ ... }:

{
  # Solaar - open source manager for Logitech Unifying/Bolt receivers
  # Manages keyboard, mouse and other Logitech HID++ devices
  programs.solaar = {
    enable = true;

    # Run as a per-user systemd service (starts on login, lives in systray)
    userService = {
      enable = true;
      window = "only"; # no tray icon — open window or run headless
      batteryIcons = "symbolic"; # consistent with system icon theme
    };
  };
}
