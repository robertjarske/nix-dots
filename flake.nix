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

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    disko,
    agenix,
    hyprpanel,
    nix-vscode-extensions,
    lanzaboote,
    neovim-nightly-overlay,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };

    neovimNightly = neovim-nightly-overlay.packages.${system}.default;

    # Apply overlay + allowUnfree on the same pkgs instance (required for unfree extensions).
    vscodeExtensions =
      (import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [nix-vscode-extensions.overlays.default];
      }).nix-vscode-extensions;

    mkHost = {
      hostModule,
      homeModule,
      username,
      disk,
      hostname,
    }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit agenix unstable neovimNightly;};
        modules = [
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
          agenix.nixosModules.default
          lanzaboote.nixosModules.lanzaboote

          ./modules/core/disko.nix
          ./modules/core/boot.nix
          ./modules/core/locale.nix
          ./modules/core/networking.nix
          ./modules/core/nix-settings.nix
          ./modules/core/users.nix
          ./modules/core/snapper.nix
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

            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {inherit hyprpanel vscodeExtensions unstable;};
              users.${username} = homeModule;
            };
          }
        ];
      };
  in {
    formatter.${system} = pkgs.alejandra;

    templates = {
      node = {
        path = ./templates/node;
        description = "Node.js / TypeScript";
      };
      php = {
        path = ./templates/php;
        description = "PHP + Composer";
      };
      python = {
        path = ./templates/python;
        description = "Python 3";
      };
      default = {
        path = ./templates/default;
        description = "Generic devShell";
      };
    };

    apps.${system} = {
      edit-secret = {
        type = "app";
        meta.description = "Edit an agenix secret with YubiKey";
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
        meta.description = "Rekey all agenix secrets with YubiKey";
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

      # Decrypt the work AD SSH private key and place it at ~/.ssh/work_ad,
      # then derive the public key from it. Run once after setting up forge,
      # or any time the secret is rekeyed.
      # Usage: nix run .#deploy-work-ssh
      deploy-work-ssh = {
        type = "app";
        meta.description = "Decrypt and deploy work AD SSH key + derive public key";
        program = toString (pkgs.writeShellScript "deploy-work-ssh" ''
          set -euo pipefail
          REPO_ROOT="$(${pkgs.git}/bin/git rev-parse --show-toplevel)"
          TMPFILE=$(mktemp)
          trap "rm -f $TMPFILE" EXIT

          echo "🔑 Generating YubiKey identity — plug in YubiKey if not already..."
          ${pkgs.age-plugin-yubikey}/bin/age-plugin-yubikey --identity > "$TMPFILE"

          TARGET="$HOME/.ssh/work_ad"
          mkdir -p "$HOME/.ssh"
          chmod 700 "$HOME/.ssh"

          echo "🔓 Decrypting work-ssh-ad.age..."
          ${pkgs.age}/bin/age --decrypt --identity "$TMPFILE" \
            "$REPO_ROOT/secrets/work-ssh-ad.age" > "$TARGET"
          chmod 600 "$TARGET"

          ${pkgs.openssh}/bin/ssh-keygen -y -f "$TARGET" > "$TARGET.pub"
          chmod 644 "$TARGET.pub"

          echo "✅ Deployed $TARGET"
          echo "   Public key: $(cat "$TARGET.pub")"
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
