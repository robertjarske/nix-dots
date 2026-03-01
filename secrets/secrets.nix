let
  yubikey1 = "age1yubikey1qty0z9hv4a0lpzp0f5es3rz9gkfjz7k59dalsc0hjungzkw7gs3rygfrp0j";
  yubikey2 = "age1yubikey1q233vgvezsfxkyat8cvwwcmzcnww3rhj4d3qss5vfv5yyh9q06kw5rch6ux";
  masters = [ yubikey1 yubikey2 ];

  bastion = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMCCnBAD6+Ec/uxrXbK4OEPCKLCQn8TmNwdK5PiYwDdl root@nixos";
  # forge = "ssh-ed25519 AAAA...";  # add after first install
in
{
  "wifi-blackbox.age".publicKeys      = masters ++ [ bastion ]; # ++ [ forge ] after first install
  "wifi-blackbox-5g.age".publicKeys   = masters ++ [ bastion ];
  "wifi-blackbox-5g-2.age".publicKeys = masters ++ [ bastion ];
  "wifi-blackbox-6g.age".publicKeys   = masters ++ [ bastion ];

  "work-wifi.age".publicKeys    = masters; # ++ [ forge ] after first install
  "work-ssh-ad.age".publicKeys  = masters; # ++ [ forge ] after first install
  "work-vpn.age".publicKeys     = masters ++ [ bastion ]; # ++ [ forge ] after first install
  "work-root-ca.age".publicKeys = masters ++ [ bastion ]; # ++ [ forge ] after first install
  "work-dev-ca.age".publicKeys  = masters ++ [ bastion ];
  "work-ike-ca.age".publicKeys  = masters ++ [ bastion ];

  "work-dns-domains.age".publicKeys = masters ++ [ bastion ];
  "dns-development.age".publicKeys  = masters ++ [ bastion ];
  "dns-production.age".publicKeys   = masters ++ [ bastion ];
}
