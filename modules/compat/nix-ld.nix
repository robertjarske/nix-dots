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
      xorg.libX11
      xorg.libXcomposite
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXrandr
      mesa
      libGL
      alsa-lib
      libxkbcommon
      libxcb
      wayland
    ];
  };
}
