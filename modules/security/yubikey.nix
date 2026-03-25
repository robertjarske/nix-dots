{pkgs, ...}: {
  services.pcscd.enable = true;

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-qt;
  };

  services.udev.packages = [pkgs.yubikey-personalization];

  environment.systemPackages = with pkgs; [
    yubikey-personalization
    yubikey-manager
    yubikey-touch-detector
    age-plugin-yubikey
    libfido2
    pam_u2f
  ];

  # YubiKey touch for sudo; password is the fallback when the key is absent.
  # control = "sufficient": touch succeeds → auth done, key missing → next PAM module (password).
  security.pam.u2f = {
    enable = true;
    settings.cue = true; # prints "Please touch your security key" on the prompt
  };
  security.pam.services.sudo.u2fAuth = true;
}
