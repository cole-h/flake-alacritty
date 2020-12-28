{
  description = "alacritty";

  inputs = {
    nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };
    naersk = { url = "github:nmattia/naersk"; };

    alacritty = { url = "github:alacritty/alacritty"; flake = false; };
  };

  outputs = { naersk, alacritty, ... } @ inputs:
    let
      nameValuePair = name: value: { inherit name value; };
      genAttrs = names: f: builtins.listToAttrs (map (n: nameValuePair n (f n)) names);
      forAllSystems = genAttrs [ "x86_64-linux" "i686-linux" "aarch64-linux" ];

      pkgsFor = pkgs: system:
        import pkgs {
          inherit system;
        };
    in
    {
      inherit inputs;

      packages = forAllSystems (system:
        let
          nixpkgs_ = (pkgsFor inputs.nixpkgs system);
          naerskLib = nixpkgs_.callPackage naersk { };
          alac = nixpkgs_.applyPatches {
            name = "alacritty-patched";
            src = alacritty;
            patches = [ ./vte-rev.diff ];
          };
        in
        {
          alacritty = nixpkgs_.callPackage ./alacritty.nix {
            inherit (naerskLib) buildPackage;
            src = alac;
            version = alacritty.shortRev;
          };
        }
      );

      defaultPackage = forAllSystems (system:
        inputs.self.packages.${system}.alacritty);

      devShell = forAllSystems (system:
        let
          nixpkgs_ = pkgsFor inputs.nixpkgs system;
        in
        nixpkgs_.mkShell {
          buildInputs = with nixpkgs_; [
            cacert
            cachix
            git
            jq
            nixUnstable
            openssh
          ];
        });
    };
}
