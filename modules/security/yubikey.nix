{ pkgs, ... }:
{
  services.pcscd.enable = true;

  services.udev.packages = [ pkgs.yubikey-personalization ];

  environment.systemPackages = with pkgs; [
    yubikey-personalization
    yubikey-manager
    age-plugin-yubikey
    libfido2
  ];
}