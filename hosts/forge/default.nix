{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/hardware/nvidia.nix
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
    ../../modules/work/apps.nix
    ../../modules/dev/php.nix
  ];

  host.secureboot.enable = true;

  # NVIDIA PRIME offload — verify bus IDs with: lspci | grep -E "VGA|3D"
  host.nvidia.intelBusId = "PCI:0:2:0";
  host.nvidia.nvidiaBusId = "PCI:1:0:0";

  # TODO: remove once nixpkgs ships NVIDIA 580.126.18+ (current: 580.119.02).
  # Tracked at https://github.com/NixOS/nixpkgs/issues/489947
  hardware.nvidia.package = let
    base = config.boot.kernelPackages.nvidiaPackages.latest;
    cachyos-nvidia-patch = pkgs.fetchpatch {
      url = "https://raw.githubusercontent.com/CachyOS/CachyOS-PKGBUILDS/master/nvidia/nvidia-utils/kernel-6.19.patch";
      sha256 = "sha256-YuJjSUXE6jYSuZySYGnWSNG5sfVei7vvxDcHx3K+IN4=";
    };
    driverAttr =
      if config.hardware.nvidia.open
      then "open"
      else "bin";
  in
    base
    // {
      ${driverAttr} = base.${driverAttr}.overrideAttrs (oldAttrs: {
        patches = (oldAttrs.patches or []) ++ [cachyos-nvidia-patch];
      });
    };

  hardware.nvidia-container-toolkit.enable = true;

  age.secrets.work-wifi.file = ../../secrets/work-wifi.age;

  # Work SSH key for AD-joined servers (placed at ~/.ssh/work_ad).
  age.secrets.work-ssh-ad = {
    file = ../../secrets/work-ssh-ad.age;
    path = "/home/serobja/.ssh/work_ad";
    owner = "serobja";
    mode = "0600";
  };

  # Derive work_ad.pub from the private key (not sensitive, not an agenix secret).
  system.activationScripts.work-ssh-ad-pubkey = {
    deps = ["agenix"];
    text = ''
      if [ -e /home/serobja/.ssh/work_ad ]; then
        ${pkgs.openssh}/bin/ssh-keygen -y -f /home/serobja/.ssh/work_ad \
          > /home/serobja/.ssh/work_ad.pub 2>/dev/null || true
        chmod 644 /home/serobja/.ssh/work_ad.pub
      fi
    '';
  };

  system.activationScripts.nm-work-wifi-setup = {
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
  ];

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = ["serobja"];
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
