{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/hardware/nvidia.nix
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
    ../../modules/dev/php.nix
    ../../modules/dev/python.nix
  ];

  networking.hosts = {
    "127.0.0.1" = [
      "local.pipechain.net"
      "core.local.pipechain.net"
      "traefik.local.pipechain.net"
    ];
  };

  host = {
    hibernation.resumeOffset = 533760;
    secureboot.enable = true;
  };

  # Stay on LTS until nixpkgs stable ships nvidia 580.126.18+ (fixes kernel 6.19 build).
  # Track: https://github.com/NixOS/nixpkgs/pull/491462 (merged to master/unstable Feb 2026,
  # not yet in nixos-25.11). Switch back to linuxPackages_latest once stable is updated.
  boot.kernelPackages = pkgs.linuxPackages;

  hardware.nvidia-container-toolkit.enable = true;

  age.secrets.work-wifi.file = ../../secrets/work-wifi.age;

  system.activationScripts = {
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
