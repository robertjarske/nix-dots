{
  lib,
  fetchFromGitHub,
  fftw,
  glib,
  gtk4-layer-shell,
  installShellFiles,
  libpulseaudio,
  libxkbcommon,
  pipewire,
  pkg-config,
  rustPlatform,
  stdenv,
  udev,
  wrapGAppsHook4,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "wayle";
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "wayle-rs";
    repo = "wayle";
    tag = "v${finalAttrs.version}";
    hash = "sha256-maKZkYVDxhMjfihOMc2h4RW3TuLS0WHfdU3jEImKXGE=";
  };

  cargoHash = "sha256-iKEdg4W+H9m0pIhE1OHUerv3Vtao4L/dwhEzbXXCubo=";
  RUSTC_BOOTSTRAP = true;

  nativeBuildInputs = [
    glib
    wrapGAppsHook4
    pkg-config
    rustPlatform.bindgenHook
    installShellFiles
  ];

  buildInputs = [
    libxkbcommon.dev
    gtk4-layer-shell.dev
    udev
    pipewire.dev
    fftw.dev
    libpulseaudio
  ];

  cargoBuildFlags = ["--bin=wayle"];

  preCheck = ''
    export HOME=$(mktemp -d)
  '';

  checkFlags = [
    "--skip=tests::css_loads_into_gtk4"
  ];

  preInstall = ''
    mkdir -p "$out/share/icons"
    cp -r resources/icons "$out/share"
  '';

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd wayle \
      --bash <($out/bin/wayle completions bash) \
      --fish <($out/bin/wayle completions fish) \
      --zsh <($out/bin/wayle completions zsh)
  '';

  meta = {
    description = "Wayland Elements — compositor-agnostic desktop shell";
    homepage = "https://github.com/wayle-rs/wayle";
    license = lib.licenses.mit;
    mainProgram = "wayle";
    platforms = lib.platforms.linux;
  };
})
