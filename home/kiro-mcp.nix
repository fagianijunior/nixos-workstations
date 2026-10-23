{ lib, pkgs, ... }:

let
  mcpConfig = builtins.toJSON {
    mcpServers = {
      fetch = {
        command = "uvx";
        args = [ "--with" "mcp<2" "mcp-server-fetch" ];
        disabled = false;
      };
      nixos = {
        command = "uvx";
        args = [ "mcp-nixos" ];
        disabled = false;
      };
      # Busca web via DuckDuckGo (sem API key). Provê search_web + fetch de
      # conteúdo. Alternativa ao provider @Web do Continue (descontinuado) e
      # a qualquer backend de busca hospedado. Mesmo server pode ser declarado
      # no config.yaml do Continue (bloco mcpServers).
      duckduckgo = {
        command = "uvx";
        args = [ "duckduckgo-mcp-server" ];
        disabled = false;
      };
      # hypruse: MCP ativo para computer-use no Hyprland (estado, screenshots,
      # input, árvore de acessibilidade). Substitui o antigo hyprmcp (arquivado,
      # último commit abr/2025 e apenas wrapper de hyprctl).
      # Iniciando em READ-ONLY: expõe só as tools de observação (desktop,
      # screenshot, zoom, ui, marks, binds, wait_for). Para liberar input
      # (pointer/keyboard/launch), remover HYPRUSE_READONLY e allowlistar as
      # tools no cliente MCP. Requer grim + wtype (ver environment.systemPackages).
      hypruse = {
        command = "uvx";
        args = [ "hypruse" ];
        env = {
          HYPRUSE_READONLY = "1";
          HYPRUSE_SCREENSHOT_MODE = "image";
        };
        disabled = false;
      };
      qt-docs = {
        command = "npx";
        args = [ "mcp-remote" "https://qt-docs-mcp.qt.io/mcp" ];
        disabled = true;
      };
      # taskwarrior: binário vem do overlay overlays/mcp-server-taskwarrior.nix
      # (buildNpmPackage, reprodutível, sem npx/npm global). O server é um wrapper
      # que executa o `task` local — taskwarrior3 já está no PATH via
      # home/taskwarrior. Caminho absoluto da store para não depender do PATH do
      # processo que lança o MCP.
      taskwarrior = {
        command = "${pkgs.mcp-server-taskwarrior}/bin/mcp-server-taskwarrior";
        args = [ ];
        disabled = false;
      };
      github = {
        command = "github-mcp-server";
        args = [ "stdio" ];
        env = {
          GITHUB_PERSONAL_ACCESS_TOKEN = "REPLACE_WITH_YOUR_TOKEN";
        };
        disabled = true;
      };
      terraform = {
        command = "terraform-mcp-server";
        args = [ "stdio" ];
        disabled = true;
      };
      aws-mcp = {
        command = "uvx";
        timeout = 100000;
        transport = "stdio";
        disabled = false;
        args = [
          "mcp-proxy-for-aws@1.6.3"
          "https://aws-mcp.us-east-1.api.aws/mcp"
          "--metadata"
          "AWS_REGION=us-east-1"
        ];
      };
    };
  };
in
{
  # Generates ~/.kiro/settings/mcp.json on every activation.
  # The file is a regular file (NOT a symlink) so the IDE can toggle
  # individual MCP servers via its UI. Next `home-manager switch` will
  # regenerate it with the canonical config + fresh gh token.
  home.activation.kiroMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.kiro/settings"
    echo '${mcpConfig}' > "$HOME/.kiro/settings/mcp.json"

    # Inject GitHub token from gh CLI if authenticated
    GH_TOKEN=$(${pkgs.gh}/bin/gh auth token 2>/dev/null || true)
    if [ -n "$GH_TOKEN" ]; then
      sed -i "s/REPLACE_WITH_YOUR_TOKEN/$GH_TOKEN/" "$HOME/.kiro/settings/mcp.json"
    fi
  '';
}
