{
  config,
  pkgs,
  lib,
  ...
}: let
  # Snapshot of all non-secret daemon settings evaluated at build time.
  # Used as the base for the runtime merge with insecure-registries.
  baseDaemonJson =
    pkgs.writeText "docker-daemon-base.json"
    (builtins.toJSON config.virtualisation.docker.daemon.settings);
in {
  age.secrets.work-docker-registries.file = ../../secrets/work-docker-registries.age;

  virtualisation.docker.daemon.settings = {
    # Avoid conflicts with VPN/corporate subnets
    default-address-pools = [
      {
        base = "10.10.0.0/16";
        size = 24;
      }
    ];

    # Use public DNS inside containers — internal dnsmasq is not reachable
    # from container namespaces. The daemon itself still uses host DNS to
    # resolve registry hostnames.
    dns = ["8.8.8.8" "1.1.1.1"];
    dns-opts = ["ndots:1"];
    dns-search = [];
  };

  # NixOS passes daemon settings via --config-file pointing at an immutable Nix
  # store path. To merge the insecure-registries secret at runtime we generate a
  # merged config in tmpfs before docker starts, then point dockerd at that file.
  systemd.services.docker = {
    # agenix decrypts secrets before other services; ensure it runs first.
    after = ["agenix.service"];
    wants = ["agenix.service"];
    serviceConfig = {
      # Creates /run/docker-config/ (tmpfs, cleaned on reboot) before preStart.
      RuntimeDirectory = "docker-config";
      RuntimeDirectoryMode = "0750";
      ExecStartPre = let
        mergeScript = pkgs.writeShellScript "docker-merge-insecure-registries" ''
          set -euo pipefail
          secret="${config.age.secrets.work-docker-registries.path}"
          if [ -f "$secret" ]; then
            ${pkgs.jq}/bin/jq --argjson regs "$(cat "$secret")" \
              '. + {"insecure-registries": $regs}' \
              ${baseDaemonJson} > /run/docker-config/daemon.json
          else
            cp ${baseDaemonJson} /run/docker-config/daemon.json
          fi
        '';
      in ["+${mergeScript}"]; # '+' runs as root regardless of service User=
      # Override the NixOS-generated --config-file to use our merged version.
      # The empty string first entry is the systemd drop-in reset convention:
      # without it the base unit's ExecStart and ours would both be active,
      # which is invalid for Type=notify and causes the service to refuse.
      ExecStart = lib.mkForce [
        "" # reset the base unit's ExecStart
        "${config.virtualisation.docker.package}/bin/dockerd --config-file=/run/docker-config/daemon.json"
      ];
    };
  };
}
