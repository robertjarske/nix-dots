{
  config,
  pkgs,
  ...
}: {
  virtualisation.libvirtd = {
    enable = true;
    qemu.swtpm.enable = true;
  };

  programs.virt-manager.enable = true;

  users.users.${config.host.username}.extraGroups = ["libvirtd"];

  systemd.services.libvirt-default-network = {
    description = "Create libvirt default NAT network";
    after = ["libvirtd.service"];
    requires = ["libvirtd.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = let
      networkXml = pkgs.writeText "libvirt-default-network.xml" ''
        <network>
          <name>default</name>
          <forward mode="nat"/>
          <bridge name="virbr0" stp="on" delay="0"/>
          <ip address="192.168.122.1" netmask="255.255.255.0">
            <dhcp>
              <range start="192.168.122.2" end="192.168.122.254"/>
            </dhcp>
          </ip>
        </network>
      '';
      virsh = "${pkgs.libvirt}/bin/virsh";
    in ''
      if ! ${virsh} net-info default &>/dev/null; then
        ${virsh} net-define ${networkXml}
        ${virsh} net-autostart default
      fi
      if ! ${virsh} net-info default | grep -q "Active:.*yes"; then
        ${virsh} net-start default || true
      fi
    '';
  };
}
