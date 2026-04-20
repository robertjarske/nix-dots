{
  stdenv,
  lib,
  fetchurl,
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
    ];

    unpackPhase = ''
      dpkg-deb -x $src .
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      cp -ar opt/microsoft/mdatp/sbin $out/sbin

      cp -ar opt/microsoft/mdatp/lib $out/lib
      cp -ar opt/microsoft/mdatp/conf $out/conf
      cp -ar opt/microsoft/mdatp/resources $out/resources
      cp -ar opt/microsoft/mdatp/definitions $out/definitions

      # wdavdaemon spawns its EDR subprocess via bin/wdavdaemon.  Both the
      # privileged process and sensecm read /proc/[pid]/exe on their children
      # and require the path to resolve to sbin/wdavdaemon.  A symlink achieves
      # this: the kernel follows the symlink at exec time and /proc/[pid]/exe
      # reports the resolved target (sbin/wdavdaemon), not the symlink itself.
      ln -sf ../sbin/wdavdaemon $out/bin/wdavdaemon

      # The user-facing CLI (wdavdaemonclient) needs NIX_LD_LIBRARY_PATH to
      # resolve Nix-store libraries; inject it via a thin shell stub so the
      # binary itself is never renamed or modified.
      printf '%s\n' \
        '#!${stdenv.shell}' \
        'export NIX_LD_LIBRARY_PATH="/opt/microsoft/mdatp/lib:${libPath}"' \
        'exec "/opt/microsoft/mdatp/sbin/wdavdaemonclient" "$@"' \
        > $out/bin/mdatp
      chmod +x $out/bin/mdatp

      runHook postInstall
    '';

    # Binaries are left as real ELFs — no wrapProgram — so that anti-tamper
    # checks on /proc/self/exe and /proc/[ppid]/exe pass.  Library loading is
    # handled by nix-ld via NIX_LD + NIX_LD_LIBRARY_PATH injected by the
    # systemd service unit; direct ELF patching would trip anti-tamper checks.
    dontPatchELF = true;
    # Keep sbin/ as a real directory. nixpkgs's moveSbins fixup would replace
    # it with a sbin → bin symlink; exec through a symlink makes /proc/pid/exe
    # resolve to the bin/ target, which sensecm rejects — it requires sbin/.
    dontMoveSbin = true;

    # Expose so the systemd service can inject the same paths into wdavdaemon's
    # environment without duplicating the dependency list.
    passthru.libPath = libPath;

    meta = {
      description = "Microsoft Defender for Endpoint";
      homepage = "https://learn.microsoft.com/en-us/defender-endpoint/microsoft-defender-endpoint-linux";
      license = lib.licenses.unfree;
      platforms = ["x86_64-linux"];
      maintainers = [];
    };
  }
