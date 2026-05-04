{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/hardware/thunderbolt-dock.nix
    ../../modules/desktop/hyprland.nix
    ../../modules/desktop/sddm.nix
    ../../modules/desktop/audio.nix
    ../../modules/desktop/bluetooth.nix
    ../../modules/desktop/power.nix
    ../../modules/desktop/theme.nix
    ../../modules/desktop/apps.nix
    ../../modules/work/vpn.nix
    ../../modules/work/certs.nix
    ../../modules/work/dns.nix
    ../../modules/work/docker.nix
    ../../modules/work/apps.nix
    ../../modules/work/defender.nix
    ../../modules/dev/php.nix
    ../../modules/dev/python.nix
    ../../modules/dev/devenv.nix
    ../../modules/dev/waydroid.nix
  ];

  host = {
    hibernation.resumeOffset = 533760;
    secureboot.enable = true;
  };

  # Kioxia KXG80ZNV1T02: APST drops to PS4 after 2s idle. PS4 has multi-second
  # exit latency which causes 2-3 minute I/O hangs in apps like VSCode and Vivaldi.
  # Cap APST to power states with exit latency ≤ 5.5ms (PS0-PS3 on this drive).
  boot.kernelParams = ["nvme_core.default_ps_max_latency_us=5500"];

  hardware.ipu6 = {
    enable = true;
    platform = "ipu6epmtl"; # Meteor Lake (Intel Core Ultra 7 155H)
  };

  # nixpkgs bug: gst_all_1.icamerasrc-ipu6epmtl does not override ipu6-camera-hal
  # to the platform-specific variant, so it silently uses the Tiger Lake HAL and
  # produces a black image. Override it here to use the correct Meteor Lake HAL.
  nixpkgs.overlays = [
    (final: prev: {
      gst_all_1 = prev.gst_all_1.overrideScope (_: gprev: {
        icamerasrc-ipu6epmtl = gprev.icamerasrc-ipu6epmtl.override {
          ipu6-camera-hal = final.ipu6epmtl-camera-hal;
        };
      });
    })
  ];

  services.mdatp = {
    enable = true;
    onboardingFile = config.age.secrets.mdatp-onboarding.path;
  };

  age.secrets = {
    mdatp-onboarding = {
      file = ../../secrets/mdatp-onboarding.age;
      mode = "0640";
      group = "mdatp";
    };

    work-wifi.file = ../../secrets/work-wifi.age;

    work-ssh-ad = {
      file = ../../secrets/work-ssh-ad.age;
      owner = "serobja";
      mode = "0600";
    };
  };

  system.activationScripts = {
    work-ssh-ad-setup = {
      deps = ["agenix"];
      text = ''
        mkdir -p /home/serobja/.ssh
        chmod 700 /home/serobja/.ssh
        chown serobja:users /home/serobja/.ssh

        ln -sf ${config.age.secrets.work-ssh-ad.path} /home/serobja/.ssh/work_ad

        echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE38se/HhwAJy+zu1D9qnUg2SU9yY5n/3rn6WM7H5sAs work-ad" \
          > /home/serobja/.ssh/work_ad.pub
        chmod 644 /home/serobja/.ssh/work_ad.pub
        chown serobja:users /home/serobja/.ssh/work_ad.pub
      '';
    };

    nm-work-wifi-setup = {
      deps = ["agenix"];
      text = ''
        mkdir -p /etc/NetworkManager/system-connections
        install -m 0600 -o root -g root ${config.age.secrets.work-wifi.path} \
          /etc/NetworkManager/system-connections/Work-WiFi.nmconnection

        if ${pkgs.networkmanager}/bin/nmcli -t general status > /dev/null 2>&1; then
          ${pkgs.networkmanager}/bin/nmcli connection reload
        fi
      '';
    };
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    gh
    psmisc
    _1password-cli
    _1password-gui
    firefox
    gnumake
    just
  ];

  programs = {
    nh = {
      enable = true;
      flake = "/home/serobja/code/nix-dots";
      clean.enable = true;
      clean.extraArgs = "--keep-since 7d --keep 10";
    };
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = ["serobja"];
    };
  };

  # Allow Vivaldi's native binary to communicate with the 1Password desktop app
  # so the browser extension unlocks when the tray icon is unlocked.
  environment.etc."1password/custom_allowed_browsers" = {
    text = "vivaldi-bin\n";
    mode = "0644";
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  system.stateVersion = "25.11";
}
