{...}: {
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  boot.kernelModules = ["i915"];

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };
}
