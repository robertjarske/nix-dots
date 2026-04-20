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
      # /nix lives on a separate BTRFS subvolume (@nix). The systemd initrd must
      # mount it before switch_root, otherwise the init binary at
      # /nix/store/.../init is unreachable and boot fails with
      # "[!!!!] switch root contains no usable init".
      # Disko does not set neededForBoot automatically, so we set it here.
      fileSystems."/nix".neededForBoot = true;

      boot = {
        loader = {
          systemd-boot = {
            enable = true;
            configurationLimit = 15;
            consoleMode = "auto";
          };
          efi.canTouchEfiVariables = true;
        };

        initrd = {
          systemd.enable = true;

          # aes_generic was removed in Linux 7.0 (merged into the AES library).
          # nixos-25.11 default still includes it; override to match nixpkgs master.
          # Tracked upstream: github.com/NixOS/nixpkgs/issues/501777
          luks.cryptoModules = ["aes" "blowfish" "twofish" "serpent" "cbc" "xts" "lrw" "sha1" "sha256" "sha512" "af_alg" "algif_skcipher" "cryptd" "input_leds"];

          luks.devices."cryptroot" = {
            device = "/dev/disk/by-partlabel/disk-main-luks";
            allowDiscards = true;
            crypttabExtraOpts = [
              "fido2-device=auto"
              "token-timeout=30"
            ];
          };
        };

        kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
        resumeDevice = "/dev/mapper/cryptroot";
      };

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
