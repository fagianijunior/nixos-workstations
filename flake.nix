{
  description = "NixOS Workstations - Nobita (Desktop) & Doraemon (Notebook)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin.url = "github:catppuccin/nix";
  };

  outputs = { self, nixpkgs, home-manager, catppuccin, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      pkgsUnfree = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      nixosConfigurations = {
        nobita = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/nobita/default.nix
            catppuccin.nixosModules.catppuccin
            home-manager.nixosModules.home-manager
            {
              home-manager.backupFileExtension = "backup";
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.terabytes = import ./home/default.nix;
              home-manager.extraSpecialArgs = { inherit catppuccin; };
            }
          ];
        };

        doraemon = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/doraemon/default.nix
            catppuccin.nixosModules.catppuccin
            home-manager.nixosModules.home-manager
            {
              home-manager.backupFileExtension = "backup";
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.terabytes = import ./home/default.nix;
              home-manager.extraSpecialArgs = { inherit catppuccin; };
            }
          ];
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          nil
          nixfmt
          nixd
        ];
      };

      checks.${system} = {
        boot = import ./tests/boot-test.nix { inherit pkgs self; };
        pipewire = import ./tests/pipewire-test.nix { inherit pkgs self; };
        networking = import ./tests/networking-test.nix { inherit pkgs self; };
        bluetooth = import ./tests/bluetooth-test.nix { inherit pkgs self; };
        gpu = import ./tests/gpu-test.nix { inherit pkgs self; };
        hyprland = import ./tests/hyprland-test.nix { inherit pkgs self; };
        desktop-tools = import ./tests/desktop-tools-test.nix { inherit pkgs self; };
        security = import ./tests/security-test.nix { inherit pkgs self; };
        power-management = import ./tests/power-management-test.nix { inherit pkgs self; };
        home-manager = import ./tests/home-manager-test.nix { inherit pkgs self; };
        neovim = import ./tests/neovim-test.nix { pkgs = pkgsUnfree; inherit self; };
        devenv-direnv = import ./tests/devenv-direnv-test.nix { inherit pkgs self; };
      };
    };
}
