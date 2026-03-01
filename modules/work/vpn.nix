{ config, pkgs, ... }:
let
  strongswanNM-bypass = pkgs.strongswanNM.overrideAttrs (old: {
    configureFlags = (old.configureFlags or []) ++ [ "--enable-bypass-lan" ];
  });
  nm-strongswan = pkgs.networkmanager-strongswan.override {
    strongswanNM = strongswanNM-bypass;
  };
in
{
  networking.networkmanager.plugins = [ nm-strongswan ];
  age.secrets.work-vpn.file = ../../secrets/work-vpn.age;

  environment.etc."strongswan.conf".text = ''
    charon-nm {
      # MFA push notifications need more time than the 2s charon-nm default
      retransmit_tries = 5
      retransmit_timeout = 30
      retransmit_base = 1
      # Don't trigger DPD immediately when VPN routes are installed (full tunnel
      # 0.0.0.0/0 would loop DPD packets back through the tunnel)
      check_current_path = no
    }

    charon {
      load_modular = yes
    }
  '';

  system.activationScripts.nm-vpn-setup = {
    deps = [ "agenix" ];
    text = ''
      # Fail loudly if the secret is missing the certificate= field.
      # Without it, charon-nm skips server cert verification entirely (MITM risk).
      if ! grep -q "^certificate=" "${config.age.secrets.work-vpn.path}"; then
        echo "FATAL: work-vpn secret missing required 'certificate=' in [vpn] section" >&2
        exit 1
      fi

      mkdir -p /etc/NetworkManager/system-connections
      install -m 0600 -o root -g root ${config.age.secrets.work-vpn.path} \
        /etc/NetworkManager/system-connections/Work-VPN.nmconnection

      if ${pkgs.networkmanager}/bin/nmcli -t general status > /dev/null 2>&1; then
        ${pkgs.networkmanager}/bin/nmcli connection reload
      fi
    '';
  };
}
