{ pkgs, lib, ... }:
{
  # Import work CA certificates directly into Firefox's NSS cert database.
  # programs.firefox's Certificates.Install policy is parsed but silently fails
  # to write to cert9.db on NixOS. certutil is the reliable alternative.
  home.activation.importWorkCerts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cert_dir="/etc/ipsec.d/cacerts"
    if [ -d "$cert_dir" ] && [ -f "$cert_dir/work-root-ca.pem" ]; then
      for profile in "$HOME/.config/mozilla/firefox"/*.default-release \
                     "$HOME/.config/mozilla/firefox"/*.default \
                     "$HOME/.config/mozilla/firefox"/*.default-esr; do
        [ -d "$profile" ] || continue
        ${pkgs.nss.tools}/bin/certutil -d "sql:$profile" -A \
          -n "Work Root CA" -t "CT,," \
          -i "$cert_dir/work-root-ca.pem" 2>/dev/null || true
        ${pkgs.nss.tools}/bin/certutil -d "sql:$profile" -A \
          -n "Work Dev CA" -t "CT,," \
          -i "$cert_dir/work-dev-ca.pem" 2>/dev/null || true
      done
    fi
  '';
}
