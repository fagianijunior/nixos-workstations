{ pkgs, self, ... }:

let
  catppuccin = self.inputs.catppuccin;
  home-manager = self.inputs.home-manager;
in
pkgs.testers.nixosTest {
  name = "neovim-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [
      ../modules/common
      home-manager.nixosModules.home-manager
    ];

    fileSystems."/" = {
      device = "/dev/vda1";
      fsType = "ext4";
    };
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.extraSpecialArgs = { inherit catppuccin; };
    home-manager.users.terabytes = import ../home/default.nix;

    # Required by home-manager xdg.portal assertion
    environment.pathsToLink = [ "/share/applications" "/share/xdg-desktop-portal" ];

    services.getty.autologinUser = "terabytes";
  };

  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")
    machine.wait_until_succeeds("pgrep -u terabytes")

    # Test 1: Neovim binary exists and starts without errors
    machine.succeed("su - terabytes -c 'nvim --version' >&2")
    machine.succeed("su - terabytes -c 'nvim --headless +qall 2>&1'")

    # Test 2: LSPs available in PATH
    lsps = [
      "nixd",
      "terraform-ls",
      "solargraph",
      "intelephense",
      "pyright",
      "lua-language-server",
      "bash-language-server",
      "dockerfile-language-server",
    ]
    for lsp in lsps:
      machine.succeed(f"su - terabytes -c 'which {lsp}'")

    # Test 3: Formatters available in PATH
    formatters = [
      "nixpkgs-fmt",
      "prettier",
      "stylua",
      "rubocop",
      "php-cs-fixer",
      "black",
      "shfmt",
      "terraform",
    ]
    for fmt in formatters:
      machine.succeed(f"su - terabytes -c 'which {fmt}'")

    # Test 4: Key plugins load without errors
    plugins_to_check = [
      "telescope",
      "lspconfig",
      "cmp",
      "gitsigns",
      "neo-tree",
      "which-key",
      "lualine",
      "conform",
      "toggleterm",
      "ibl",
      "nvim-autopairs",
      "Comment",
      "bufferline",
    ]
    for plugin in plugins_to_check:
      machine.succeed(
        f"su - terabytes -c \"nvim --headless -c 'lua require(\\\"{plugin}\\\")' +qall 2>&1\""
      )

    # Test 5: Colorscheme is catppuccin
    result = machine.succeed(
      "su - terabytes -c \"nvim --headless -c 'lua print(vim.g.colors_name)' +qall 2>&1\""
    )
    assert "catppuccin" in result, f"Expected catppuccin colorscheme, got: {result}"

    # Test 6: Treesitter parsers are installed (check parser directory)
    machine.succeed(
      "su - terabytes -c \"nvim --headless -c 'lua assert(#vim.api.nvim_get_runtime_file(\\\"parser/*.so\\\", true) >= 20)' +qall 2>&1\""
    )
  '';
}
