{
  config,
  pkgs,
  ...
}: {
  age.secrets = {
    wifi-blackbox.file = ../../secrets/wifi-blackbox.age;
    wifi-blackbox-5g.file = ../../secrets/wifi-blackbox-5g.age;
    wifi-blackbox-5g-2.file = ../../secrets/wifi-blackbox-5g-2.age;
    wifi-blackbox-6g.file = ../../secrets/wifi-blackbox-6g.age;
  };

  system.activationScripts.nm-wifi-setup = {
    deps = ["agenix"];
    text = ''
      mkdir -p /etc/NetworkManager/system-connections
      install -m 0600 -o root -g root ${config.age.secrets.wifi-blackbox.path}      /etc/NetworkManager/system-connections/blackbox.nmconnection
      install -m 0600 -o root -g root ${config.age.secrets.wifi-blackbox-5g.path}   /etc/NetworkManager/system-connections/blackbox_5G.nmconnection
      install -m 0600 -o root -g root ${config.age.secrets.wifi-blackbox-5g-2.path} /etc/NetworkManager/system-connections/blackbox_5G-2.nmconnection
      install -m 0600 -o root -g root ${config.age.secrets.wifi-blackbox-6g.path}   /etc/NetworkManager/system-connections/blackbox_6G.nmconnection

      if ${pkgs.networkmanager}/bin/nmcli -t general status > /dev/null 2>&1; then
        ${pkgs.networkmanager}/bin/nmcli connection reload
      fi
    '';
  };
}
