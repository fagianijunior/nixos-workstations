{ config, pkgs, lib, ... }:

{
  # Disable PulseAudio (replaced by PipeWire)
  services.pulseaudio.enable = false;

  # Enable rtkit for real-time scheduling (required by PipeWire)
  security.rtkit.enable = true;

  # PipeWire audio
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;     # PulseAudio compatibility
    wireplumber.enable = true;
  };
}
