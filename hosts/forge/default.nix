{ config, pkgs, ... }:
{
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

  # NVIDIA PRIME offload — verify bus IDs with: lspci | grep -E "VGA|3D"
  host.nvidia.intelBusId  = "PCI:0:2:0";
  host.nvidia.nvidiaBusId = "PCI:1:0:0";

  hardware.nvidia-container-toolkit.enable = true;

  age.secrets.work-wifi.file = ../../secrets/work-wifi.age;

  # Work SSH key for AD-joined servers (placed at ~/.ssh/work_ad).
  age.secrets.work-ssh-ad = {
    file  = ../../secrets/work-ssh-ad.age;
    path  = "/home/serobja/.ssh/work_ad";
    owner = "serobja";
    mode  = "0600";
  };

  # Derive work_ad.pub from the private key (not sensitive, not an agenix secret).
  system.activationScripts.work-ssh-ad-pubkey = {
    deps = [ "agenix" ];
    text = ''
      if [ -e /home/serobja/.ssh/work_ad ]; then
        ${pkgs.openssh}/bin/ssh-keygen -y -f /home/serobja/.ssh/work_ad \
          > /home/serobja/.ssh/work_ad.pub 2>/dev/null || true
        chmod 644 /home/serobja/.ssh/work_ad.pub
      fi
    '';
  };

  system.activationScripts.nm-work-wifi-setup = {
    deps = [ "agenix" ];
    text = ''
      install -m 0600 -o root -g root ${config.age.secrets.work-wifi.path} \
        /etc/NetworkManager/system-connections/Work-WiFi.nmconnection

      if ${pkgs.systemd}/bin/systemctl is-active --quiet NetworkManager.service; then
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
    polkitPolicyOwners = [ "serobja" ];
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
