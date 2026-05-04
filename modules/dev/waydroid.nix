{pkgs, ...}: {
  virtualisation.waydroid.enable = true;

  # This kernel has no ip_tables module — only nftables. Setting this makes
  # virtualisation.waydroid automatically use pkgs.waydroid-nftables, which
  # has LXC_USE_NFT=true in its net script. Without it, waydroid-net.sh falls
  # back to iptables-legacy and fails to load the ip_tables kernel module.
  # See: nixos/modules/virtualisation/waydroid.nix — package default expression.
  networking.nftables.enable = true;

  environment.systemPackages = with pkgs; [
    # android-tools: adb/fastboot for pushing APKs and debugging inside container
    android-tools
  ];
}
