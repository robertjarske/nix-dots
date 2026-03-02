{
  config,
  pkgs,
  ...
}: {
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

    # nvidia-container-toolkit is enabled in hardware, but explicit entry
    # ensures Docker picks up the runtime even if auto-config doesn't apply.
    runtimes.nvidia = {
      path = "nvidia-container-runtime";
      args = [];
    };
  };

  # Merge insecure-registries from secret into daemon.json.
  # NixOS generates daemon.json as a symlink into the Nix store (immutable),
  # so we replace the symlink with a real file containing the merged content.
  # Runs on every rebuild: etc recreates the symlink, then this script patches it.
  system.activationScripts.docker-insecure-registries = {
    deps = ["etc" "agenix"];
    text = ''
      secret="${config.age.secrets.work-docker-registries.path}"
      if [ ! -f "$secret" ]; then exit 0; fi

      base=$(cat "$(readlink -f /etc/docker/daemon.json)")
      registries=$(cat "$secret")
      merged=$(echo "$base" | ${pkgs.jq}/bin/jq --argjson regs "$registries" '. + {"insecure-registries": $regs}')

      rm -f /etc/docker/daemon.json
      echo "$merged" > /etc/docker/daemon.json
      chmod 644 /etc/docker/daemon.json

      if ${pkgs.systemd}/bin/systemctl is-active --quiet docker; then
        ${pkgs.systemd}/bin/systemctl reload docker || ${pkgs.systemd}/bin/systemctl restart docker
      fi
    '';
  };
}
