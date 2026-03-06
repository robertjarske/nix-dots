{
  pkgs,
  lib,
  config,
  ...
}: let
  caBundle = "/run/work-certs/ca-bundle.pem";
  certutil = "${pkgs.nss.tools}/bin/certutil";
  importCerts = db: ''
    ${certutil} -d "${db}" -A -n "Work Root CA" -t "CT,," \
      -i "$cert_dir/work-root-ca.pem" 2>/dev/null || true
    ${certutil} -d "${db}" -A -n "Work Dev CA" -t "CT,," \
      -i "$cert_dir/work-dev-ca.pem" 2>/dev/null || true
  '';
in {
  home = {
    # Import work CA certificates into browser NSS databases.
    # programs.firefox's Certificates.Install policy silently fails on NixOS —
    # certutil is the reliable alternative. Chrome and Vivaldi share ~/.pki/nssdb.
    activation.importWorkCerts = lib.hm.dag.entryAfter ["writeBoundary"] ''
      cert_dir="/etc/work-certs"
      if [ -d "$cert_dir" ] && [ -f "$cert_dir/work-root-ca.pem" ]; then

        # Firefox profiles
        for profile in "$HOME/.config/mozilla/firefox"/*.default-release \
                       "$HOME/.config/mozilla/firefox"/*.default \
                       "$HOME/.config/mozilla/firefox"/*.default-esr; do
          [ -d "$profile" ] || continue
          ${importCerts "sql:$profile"}
        done

        # Chrome and Vivaldi — shared system NSS database
        nssdb="$HOME/.pki/nssdb"
        if [ ! -d "$nssdb" ]; then
          mkdir -p "$nssdb"
          ${certutil} -d "sql:$nssdb" -N --empty-password 2>/dev/null || true
        fi
        ${importCerts "sql:$nssdb"}
      fi
    '';

    # pnpm and npm: NODE_EXTRA_CA_CERTS isn't always inherited reliably.
    # Explicit cafile in .npmrc is the reliable fallback.
    file.".npmrc".text = ''
      cafile=${caBundle}
      prefix=${config.home.homeDirectory}/.npm-global
    '';

    # yarn berry ignores NODE_EXTRA_CA_CERTS entirely — needs its own setting.
    file.".yarnrc.yml".text = ''
      httpsCaFilePath: "${caBundle}"
    '';
  };
}
