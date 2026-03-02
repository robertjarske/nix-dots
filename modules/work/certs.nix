{
  config,
  pkgs,
  ...
}: {
  age.secrets.work-root-ca = {
    file = ../../secrets/work-root-ca.age;
    mode = "0444";
  };

  age.secrets.work-dev-ca = {
    file = ../../secrets/work-dev-ca.age;
    mode = "0444";
  };

  age.secrets.work-ike-ca = {
    file = ../../secrets/work-ike-ca.age;
    mode = "0444";
  };

  system.activationScripts.work-ca-bundle = {
    deps = ["agenix"];
    text = ''
      mkdir -p /run/work-certs
      cat ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt \
          ${config.age.secrets.work-root-ca.path} \
          ${config.age.secrets.work-dev-ca.path} \
          ${config.age.secrets.work-ike-ca.path} \
          > /run/work-certs/ca-bundle.pem

      # ipsec.d: VPN only — strongswan owns this dir and keeps it 700
      mkdir -p /etc/ipsec.d/cacerts
      install -m 0644 ${config.age.secrets.work-ike-ca.path} /etc/ipsec.d/cacerts/work-ike-ca.pem

      # work-certs: user-accessible (Firefox, certutil, etc.)
      mkdir -p /etc/work-certs
      chmod 755 /etc/work-certs
      install -m 0644 ${config.age.secrets.work-root-ca.path} /etc/work-certs/work-root-ca.pem
      install -m 0644 ${config.age.secrets.work-dev-ca.path}  /etc/work-certs/work-dev-ca.pem
      install -m 0644 ${config.age.secrets.work-ike-ca.path}  /etc/work-certs/work-ike-ca.pem
    '';
  };

  environment.sessionVariables = {
    NIX_SSL_CERT_FILE = "/run/work-certs/ca-bundle.pem";
    SSL_CERT_FILE = "/run/work-certs/ca-bundle.pem";
    CURL_CA_BUNDLE = "/run/work-certs/ca-bundle.pem";
    GIT_SSL_CAINFO = "/run/work-certs/ca-bundle.pem";
    NODE_EXTRA_CA_CERTS = "/run/work-certs/ca-bundle.pem";
    REQUESTS_CA_BUNDLE = "/run/work-certs/ca-bundle.pem";
    PIP_CERT = "/run/work-certs/ca-bundle.pem";
  };
}
