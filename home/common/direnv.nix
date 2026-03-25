{devenvPkg, ...}: {
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    # Make `use devenv` available in .envrc files.
    stdlib = ''
      eval "$(${devenvPkg}/bin/devenv direnvrc)"
    '';
  };
}
