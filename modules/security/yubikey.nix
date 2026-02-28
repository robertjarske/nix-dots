{ pkgs, ... }:
{
  services.pcscd.enable = true;

  services.udev.packages = [ pkgs.yubikey-personalization ];

  environment.systemPackages = with pkgs; [
    yubikey-personalization
    yubikey-manager
    yubikey-touch-detector
    age-plugin-yubikey
    libfido2
  ];
}