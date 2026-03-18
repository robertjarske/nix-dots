let
  yubikey1 = "age1yubikey1qty0z9hv4a0lpzp0f5es3rz9gkfjz7k59dalsc0hjungzkw7gs3rygfrp0j";
  yubikey2 = "age1yubikey1q233vgvezsfxkyat8cvwwcmzcnww3rhj4d3qss5vfv5yyh9q06kw5rch6ux";
  masters = [yubikey1 yubikey2];

  bastion = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPE6mrKLP7qxqaQfIKZbbVx6LyNTLRPYG+MEP+Zcm6Ln";
  forge = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM0DdhyvMDcxuzzHyvsAaOuH7PHvNPHlwld6YJWZwYZz";
in {
  "wifi-blackbox.age".publicKeys = masters ++ [bastion forge];
  "wifi-blackbox-5g.age".publicKeys = masters ++ [bastion forge];
  "wifi-blackbox-5g-2.age".publicKeys = masters ++ [bastion forge];
  "wifi-blackbox-6g.age".publicKeys = masters ++ [bastion forge];

  "work-wifi.age".publicKeys = masters ++ [forge];
  "work-ssh-ad.age".publicKeys = masters ++ [forge];
  "work-vpn.age".publicKeys = masters ++ [forge];
  "work-root-ca.age".publicKeys = masters ++ [forge];
  "work-dev-ca.age".publicKeys = masters ++ [forge];
  "work-ike-ca.age".publicKeys = masters ++ [forge];

  "work-docker-registries.age".publicKeys = masters ++ [forge];

  "work-local-hosts.age".publicKeys = masters ++ [forge];
  "work-dns-domains.age".publicKeys = masters ++ [forge];
  "dns-development.age".publicKeys = masters ++ [forge];
  "dns-production.age".publicKeys = masters ++ [forge];
}
