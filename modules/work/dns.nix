{
  config,
  pkgs,
  ...
}: {
  networking.networkmanager.dns = "dnsmasq";

  environment.etc."NetworkManager/dnsmasq.d/00-config".text = ''
    all-servers
    no-negcache
  '';

  age.secrets = {
    work-dns-domains.file = ../../secrets/work-dns-domains.age;
    dns-development.file = ../../secrets/dns-development.age;
    dns-production.file = ../../secrets/dns-production.age;
  };

  system.activationScripts.nm-dns-setup = {
    deps = ["agenix"];
    text = ''
      mkdir -p /etc/NetworkManager/dnsmasq.d
      install -m 0644 -o root -g root ${config.age.secrets.work-dns-domains.path} \
        /etc/NetworkManager/dnsmasq.d/01-work-domains.conf
      install -m 0644 -o root -g root ${config.age.secrets.dns-development.path} \
        /etc/NetworkManager/dnsmasq.d/02-development.conf
      install -m 0644 -o root -g root ${config.age.secrets.dns-production.path} \
        /etc/NetworkManager/dnsmasq.d/03-production.conf

      if ${pkgs.networkmanager}/bin/nmcli -t general status > /dev/null 2>&1; then
        ${pkgs.networkmanager}/bin/nmcli general reload
      fi
    '';
  };
}
