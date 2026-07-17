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
            # Workaround: BlueZ 5.86 regression with dual-role A2DP devices (Echo Dot)
            # Removing a2dp_sink prevents WirePlumber from registering a local sink SEP,
            # forcing the Echo Dot to negotiate as A2DP Sink (PC sends audio to it).
            # Caveat: PC cannot receive A2DP audio from other devices (fine for desktop).
            # Tracking: https://github.com/bluez/bluez/issues/1922
            # Revert to [ a2dp_sink a2dp_source hsp_hs hfp_hf ] when bluez >= 5.87
            bluez5.roles = [ a2dp_source hsp_ag hfp_ag ]
            bluez5.codecs = [ sbc sbc_xq aac ]
            bluez5.enable-sbc-xq = true
            bluez5.hfphsp-backend = "native"
          }
        '')
        # Prevent WirePlumber from auto-switching to headset profile when a voice app
        # tries to use the mic on a bluetooth device
        (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/11-bluetooth-policy.conf" ''
          wireplumber.settings = {
            bluetooth.autoswitch-to-headset-profile = false
          }
        '')
      ];
    };
  };
}
