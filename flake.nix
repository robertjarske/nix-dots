{
  description = "NixOS config — bastion (personal) and forge (work)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    hyprpanel = {
      url = "github:Jas-SinghFSU/HyprPanel";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, disko, agenix, hyprpanel, nix-vscode-extensions, ... }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };

    # Apply overlay + allowUnfree on the same pkgs instance (required for unfree extensions).
    vscodeExtensions = (import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [ nix-vscode-extensions.overlays.default ];
    }).nix-vscode-extensions;

    mkHost = { hostModule, homeModule, username, disk, hostname }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit agenix unstable; };
        modules = [
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
          agenix.nixosModules.default

          ./modules/core/disko.nix
          ./modules/core/boot.nix
          ./modules/core/locale.nix
          ./modules/core/networking.nix
          ./modules/core/nix-settings.nix
          ./modules/core/users.nix
          ./modules/dev/docker.nix
          ./modules/dev/node.nix
          ./modules/dev/editors.nix
          ./modules/hardware/intel.nix
          ./modules/compat/nix-ld.nix
          ./modules/compat/distrobox.nix
          ./modules/security/yubikey.nix
          ./modules/security/agenix.nix
          ./modules/network/wifi.nix
          hostModule

          # Host parameters — single source of truth
          {
            host.username = username;
            host.disk = disk;
            networking.hostName = hostname;

            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit hyprpanel vscodeExtensions; };
            home-manager.users.${username} = homeModule;
          }
        ];
      };
  in
  {
    apps.${system} = {
      edit-secret = {
        type = "app";
        program = toString (pkgs.writeShellScript "edit-secret" ''
          set -euo pipefail
          if [ -z "''${1:-}" ]; then
            echo "Usage: nix run .#edit-secret -- secrets/foo.age"
            exit 1
          fi
          TMPFILE=$(mktemp)
          trap "rm -f $TMPFILE" EXIT
          echo "🔑 Generating YubiKey identity — plug in YubiKey if not already..."
          ${pkgs.age-plugin-yubikey}/bin/age-plugin-yubikey --identity > "$TMPFILE"
          echo "✏️  Opening $1..."
          cd "$(${pkgs.git}/bin/git rev-parse --show-toplevel)/secrets"
          ${agenix.packages.${system}.default}/bin/agenix -e $(basename $1) --identity "$TMPFILE"
          echo "✅ Done."
        '');
      };

      rekey = {
        type = "app";
        program = toString (pkgs.writeShellScript "rekey" ''
          set -euo pipefail
          TMPFILE=$(mktemp)
          trap "rm -f $TMPFILE" EXIT
          echo "🔑 Generating YubiKey identity — plug in YubiKey if not already..."
          ${pkgs.age-plugin-yubikey}/bin/age-plugin-yubikey --identity > "$TMPFILE"
          echo "🔐 Rekeying secrets..."
          cd "$(${pkgs.git}/bin/git rev-parse --show-toplevel)/secrets"
          ${agenix.packages.${system}.default}/bin/agenix --rekey --identity "$TMPFILE"
          echo "✅ Done."
        '');
      };
    };

    nixosConfigurations = {
      bastion = mkHost {
        hostname = "bastion";
        username = "gast";
        disk = "/dev/nvme0n1";
        hostModule = ./hosts/bastion;
        homeModule = import ./home/bastion.nix;
      };

      forge = mkHost {
        hostname = "forge";
        username = "serobja";
        disk = "/dev/nvme0n1";
        hostModule = ./hosts/forge;
        homeModule = import ./home/forge.nix;
      };
    };
  };
}