{
  pkgs,
  lib,
  config,
  ...
}: {
  options.host = {
    hibernation.resumeOffset = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = ''
        BTRFS swapfile resume offset, required for suspend-to-disk.
        Get the value after first boot with:
          sudo btrfs inspect-internal map-swapfile -r /swap/swapfile
        Then set host.hibernation.resumeOffset = <number> and rebuild.
      '';
    };

    secureboot.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkMerge [
    {
      boot.loader = {
        systemd-boot = {
          enable = true;
          configurationLimit = 15;
          consoleMode = "auto";
        };
        efi.canTouchEfiVariables = true;
      };

      boot.initrd = {
        systemd.enable = true;

        luks.devices."cryptroot" = {
          device = "/dev/disk/by-partlabel/disk-main-luks";
          allowDiscards = true;
          crypttabExtraOpts = [
            "fido2-device=auto"
            "token-timeout=30"
          ];
        };
      };

      boot.kernelPackages = pkgs.linuxPackages_latest;
      boot.resumeDevice = "/dev/mapper/cryptroot";

      specialisation.lts.configuration = {
        boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
      };
    }

    (lib.mkIf config.host.secureboot.enable {
      boot.loader.systemd-boot.enable = lib.mkForce false;
      boot.lanzaboote = {
        enable = true;
        pkiBundle = "/var/lib/sbctl";
      };
      environment.systemPackages = [pkgs.sbctl];
    })

    (lib.mkIf (config.host.hibernation.resumeOffset != null) {
      boot.kernelParams = ["resume_offset=${toString config.host.hibernation.resumeOffset}"];
    })

    (lib.mkIf (config.host.hibernation.resumeOffset == null) {
      warnings = [
        ''

          ══════════════════════════════════════════════════════════════
           HIBERNATION NOT CONFIGURED: host.hibernation.resumeOffset
          ══════════════════════════════════════════════════════════════
           Suspend-to-disk will silently fail or corrupt until set.

           After first boot, run:
             sudo btrfs inspect-internal map-swapfile -r /swap/swapfile

           Then in your host config (hosts/<name>/default.nix):
             host.hibernation.resumeOffset = <the number>;

           Then rebuild: sudo nixos-rebuild switch --flake .#<hostname>
          ══════════════════════════════════════════════════════════════
        ''
      ];
    })
  ];
}
