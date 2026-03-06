{...}: {
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = true;
    nvidiaSettings = true;
  };

  services.xserver.videoDrivers = ["nvidia"];

  environment.sessionVariables = {
    __GL_GSYNC_ALLOWED = "0";
    __GL_VRR_ALLOWED = "0";
    XWAYLAND_NO_GLAMOR = "1";
  };
}
