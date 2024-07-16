{
  description = "dhelper template virtual environment";

  inputs.devshell.url = "github:numtide/devshell";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/release-23.05";

  outputs = inputs@{ self, flake-parts, devshell, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        devshell.flakeModule
      ];

      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "i686-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      perSystem = { pkgs, system, ... }: {
        _module.args.pkgs = import nixpkgs {
          inherit system;
          overlays = [
            devshell.overlays.default
          ];
        };

        devshells.default = {

          packages = with pkgs; [
            graphviz
            shellcheck
          ];

          commands = [
            # {
            #   category = "tools";
            #   # package = pkgs.libcamera;
            #   name = "cam";
            #   command = "${pkgs.libcamera}/bin/cam -l $@";
            # }
          ];
        
          env = [
            # { name = "PATH";          prefix  = ""; }
            # { name = "INCLUDE_PATH";  eval    = "$C_INCLUDE_PATH"; }
          ];
        };

        packages = let
          # cross = pkgs;
          # .pkgsCross.riscv64;
        in {
          # ...
        };
      };
    };
}
