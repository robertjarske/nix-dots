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

    home-manager-unstable = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    devenv.url = "github:cachix/devenv";

    # Pinned to playwright-driver 1.58.2.
    # See https://search.nixos.org/packages?channel=unstable&from=0&size=50&sort=relevance&type=packages&query=playwright
    nixpkgs-playwright.url = "github:NixOS/nixpkgs/993b198677ac7aea3719d2d2f03ae312ae9ee5ae";

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
    nixpkgs-playwright,
    home-manager,
    home-manager-unstable,
    disko,
    agenix,
    devenv,
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
    vscodeLatest = pkgs.callPackage ./pkgs/vscode-latest.nix {inherit unstable;};

    # Apply overlay + allowUnfree on the same pkgs instance (required for unfree extensions).
    vscodeExtensions =
      (import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [nix-vscode-extensions.overlays.default];
      }).nix-vscode-extensions;

    pkgs-pw = import nixpkgs-playwright {inherit system;};
    devenvPkg = devenv.packages.${system}.devenv;

    mkHost = {
      hostModule,
      homeModule,
      username,
      disk,
      hostname,
      pkgsSrc ? nixpkgs,
      hmSrc ? home-manager,
    }:
      pkgsSrc.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit agenix unstable neovimNightly devenvPkg;};
        modules = [
          disko.nixosModules.disko
          hmSrc.nixosModules.home-manager
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
          ./modules/dev/go.nix
          ./modules/dev/node.nix
          ./modules/dev/editors.nix
          ./modules/hardware/intel.nix
          ./modules/compat/nix-ld.nix
          ./modules/compat/distrobox.nix
          ./modules/compat/virt.nix
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
              extraSpecialArgs = {inherit hyprpanel vscodeExtensions unstable vscodeLatest devenvPkg;};
              users.${username} = homeModule;
            };
          }
        ];
      };
  in {
    formatter.${system} = pkgs.alejandra;

    devShells.${system}.playwright = let
      browsers-json = builtins.fromJSON (builtins.readFile "${pkgs-pw.playwright-driver}/browsers.json");
      chromium-rev = (builtins.head (builtins.filter (x: x.name == "chromium") browsers-json.browsers)).revision;
      nixVersion = pkgs-pw.playwright-driver.version;
    in
      pkgs-pw.mkShell {
        packages = [pkgs-pw.playwright-driver.browsers];
        shellHook = ''
          export PLAYWRIGHT_BROWSERS_PATH=${pkgs-pw.playwright-driver.browsers}
          export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
          export PLAYWRIGHT_NODEJS_PATH=${pkgs.nodejs}/bin/node
          export PLAYWRIGHT_LAUNCH_OPTIONS_EXECUTABLE_PATH=${pkgs-pw.playwright-driver.browsers}/chromium-${chromium-rev}/chrome-linux/chrome

          npmVersion=$(npm pkg get devDependencies.@playwright/test 2>/dev/null | tr -d '"' || true)
          echo "❄️  Playwright nix version: ${nixVersion}"
          echo "📦 Playwright npm version: ''${npmVersion:-not found in package.json}"
          if [ "${nixVersion}" != "''${npmVersion}" ]; then
            echo "❌ Version mismatch — update the pinned nixpkgs-playwright commit or package.json"
          else
            echo "✅ Versions match"
          fi
          echo
          env | grep ^PLAYWRIGHT
        '';
      };

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
        hostname = "arch-serobja";
        username = "serobja";
        disk = "/dev/nvme0n1";
        hostModule = ./hosts/forge;
        homeModule = import ./home/forge.nix;
        pkgsSrc = nixpkgs-unstable;
        hmSrc = home-manager-unstable;
      };
    };
  };
}
