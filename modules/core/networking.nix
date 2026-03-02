_: {
  networking = {
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [];
      allowedUDPPorts = [500 4500];
      # Loose reverse-path filtering — strict mode drops decrypted VPN packets
      # because the inner packet's source address has no route back via the
      # physical interface (it's only reachable via the XFRM tunnel interface).
      checkReversePath = "loose";
    };
  };
}
