{pkgs, ...}: {
  services = {
    pcscd.enable = true;
    udev = {
      packages = [pkgs.yubikey-personalization];
      # Re-trigger gpg-card-learn in the user session whenever a YubiKey is plugged in.
      # Covers both initial login (handled by the user service) and hot-swap between keys.
      extraRules = ''
        ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1050", TAG+="systemd", ENV{SYSTEMD_USER_WANTS}="gpg-card-learn.service"
      '';
    };
  };

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-qt;
  };

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
  # No global enable — only sudo opts in, so login/sddm are unaffected.
  security.pam.u2f = {
    control = "sufficient";
    settings.cue = true; # prints "Please touch your security key" on the prompt
  };
  security.pam.services.sudo.u2fAuth = true;
}
