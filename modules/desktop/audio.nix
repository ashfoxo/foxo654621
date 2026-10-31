{
  ##### Audio #####
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;   # 32-bit Steam titles
    pulse.enable = true;
    wireplumber.enable = true;  # provides wpctl, used by hypr/binds.lua
  };
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;  # realtime scheduling; prevents crackling under load
}
