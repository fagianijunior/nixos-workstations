{ pkgs, ... }:

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
    pulse.enable = true; # PulseAudio compatibility
    wireplumber = {
      enable = true;
      configPackages = [
        (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/10-bluez.conf" ''
          monitor.bluez.properties = {
            bluez5.roles = [ a2dp_sink a2dp_source hsp_hs hfp_hf ]
            bluez5.codecs = [ sbc sbc_xq aac ]
            bluez5.enable-sbc-xq = true
            bluez5.hfphsp-backend = "native"
          }
        '')
        # Force A2DP profile on bluetooth devices that support it
        # This prevents devices like Echo Dot from connecting as audio gateway (HSP/HFP)
        (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/11-bluetooth-policy.conf" ''
          wireplumber.settings = {
            bluetooth.autoswitch-to-headset-profile = false
          }
        '')
      ];
    };
  };
}
