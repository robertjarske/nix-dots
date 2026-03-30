{pkgs, ...}: {
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      openssl
      curl
      glib
      nss
      nspr
      atk
      cups
      libdrm
      gtk3
      pango
      cairo
      libx11
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxrandr
      mesa
      libGL
      alsa-lib
      libxkbcommon
      libxcb
      wayland
    ];
  };
}
