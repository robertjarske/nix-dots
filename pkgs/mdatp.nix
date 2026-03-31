{
  stdenv,
  lib,
  fetchurl,
  makeWrapper,
  dpkg,
  systemd,
  libselinux,
  libcxx,
  minizip-ng,
  curl,
  libseccomp,
  libuuid,
  openssl,
  gcc,
  libcap,
  pcre,
  pcre2,
  acl,
  zlib,
  fuse,
  sqlite,
  coreutils,
  gnugrep,
}: let
  libPath = lib.makeLibraryPath [
    systemd
    libselinux
    libcxx
    minizip-ng
    curl
    libseccomp
    libuuid
    openssl
    gcc.cc.lib
    libcap
    pcre
    pcre2
    acl
    zlib
    fuse
    sqlite
  ];
in
  stdenv.mkDerivation rec {
    pname = "mdatp";
    # To update: bump version, then get the new hash with:
    #   nix store prefetch-file --hash-type sha256 \
    #     https://packages.microsoft.com/debian/12/prod/pool/main/m/mdatp/mdatp_<version>_amd64.deb
    version = "101.26021.0002";
    src = fetchurl {
      url = "https://packages.microsoft.com/debian/12/prod/pool/main/m/mdatp/${pname}_${version}_amd64.deb";
      hash = "sha256-Jcm0BDuWkQNPyVePJK+4gs42r0B3Z29JVwejKEat5Y8=";
    };

    nativeBuildInputs = [
      dpkg
      makeWrapper
    ];

    unpackPhase = ''
      dpkg-deb -x $src .
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      cp -ar opt/microsoft/mdatp/sbin $out/sbin
      ln -s $out/sbin/wdavdaemonclient $out/bin/mdatp

      cp -ar opt/microsoft/mdatp/lib $out/lib
      cp -ar opt/microsoft/mdatp/conf $out/conf
      cp -ar opt/microsoft/mdatp/resources $out/resources
      cp -ar opt/microsoft/mdatp/definitions $out/definitions

      for executable in $out/bin/mdatp $out/sbin/*; do
        wrapProgram $executable \
          --set-default NIX_LD "$(cat $NIX_CC/nix-support/dynamic-linker)" \
          --prefix NIX_LD_LIBRARY_PATH : $out/lib:${libPath} \
          --prefix PATH : ${lib.makeBinPath [coreutils gnugrep]};
      done

      runHook postInstall
    '';

    # wrapProgram handles library loading via NIX_LD; direct ELF patching
    # would trip Defender's anti-tamper checks.
    dontPatchELF = true;

    meta = {
      description = "Microsoft Defender for Endpoint";
      homepage = "https://learn.microsoft.com/en-us/defender-endpoint/microsoft-defender-endpoint-linux";
      license = lib.licenses.unfree;
      platforms = ["x86_64-linux"];
      maintainers = [];
    };
  }
