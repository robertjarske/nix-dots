{ config, lib, ... }:
{
  options.host.nvidia = {
    intelBusId = lib.mkOption {
      type = lib.types.str;
      description = ''
        PCI bus ID of the Intel integrated GPU for PRIME offload.
        Verify before setting: lspci | grep -E "VGA|3D"
        Format example: "PCI:0:2:0"
      '';
    };
    nvidiaBusId = lib.mkOption {
      type = lib.types.str;
      description = ''
        PCI bus ID of the NVIDIA discrete GPU for PRIME offload.
        Verify before setting: lspci | grep -E "VGA|3D"
        Format example: "PCI:1:0:0"
      '';
    };
  };

  config = {
    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = true;
      open = true;
      nvidiaSettings = true;
      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        intelBusId = config.host.nvidia.intelBusId;
        nvidiaBusId = config.host.nvidia.nvidiaBusId;
      };
    };

    services.xserver.videoDrivers = [ "nvidia" ];

    environment.sessionVariables = {
      WLR_NO_HARDWARE_CURSORS = "1";
      NIXOS_OZONE_WL = "1";
    };
  };
}
