_: {
  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];

      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://hyprland.cachix.org"
        "https://neovim-nightly.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "neovim-nightly.cachix.org-1:feIoInHRevVEplgdZvQDjhp11kYASYCE2NGY9hNrwxY="
      ];
    };

    gc = {
      automatic = true;
      dates = "weekly";
      # Keep at least 10 generations regardless of age, plus everything from
      # the last 14 days. Prevents unbounded accumulation during active weeks.
      options = "--delete-older-than 14d --keep-last 10";
    };

    # Deduplicate the store weekly on a schedule rather than on every build.
    # auto-optimise-store adds overhead to each individual build operation.
    optimise = {
      automatic = true;
      dates = ["weekly"];
    };
  };

  nixpkgs.config.allowUnfree = true;
}
