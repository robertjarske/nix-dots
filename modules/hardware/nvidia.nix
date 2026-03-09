_: {
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = true;
    nvidiaSettings = true;
  };

  # Poll for DRM connector state changes so Thunderbolt-tunneled DisplayPort
  # monitors are detected even when the hotplug interrupt is missed at boot.
  boot.kernelParams = ["nvidia-drm.poll=1"];

  services.xserver.videoDrivers = ["nvidia"];

  environment.sessionVariables = {
    __GL_GSYNC_ALLOWED = "0";
    __GL_VRR_ALLOWED = "0";
    XWAYLAND_NO_GLAMOR = "1";
  };
}
