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
        disabled = true;
      };
      "Hyperland MCP Server" = {
        command = "uv";
        args = [
          "run"
          "--with"
          "mcp[cli]<2"
          "mcp"
          "run"
          "/home/terabytes/Workspace/MCPs/hyprmcp/hyprmcp/server.py"
        ];
        env = {
          PYTHONPATH = "/home/terabytes/Workspace/MCPs/hyprmcp";
        };
        disabled = false;
      };
      qt-docs = {
        command = "npx";
        args = [ "mcp-remote" "https://qt-docs-mcp.qt.io/mcp" ];
        disabled = true;
      };
      taskwarrior = {
        command = "npx";
        args = [ "-y" "mcp-server-taskwarrior" ];
        disabled = true;
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
      "aws-mcp" = {
        command = "uvx";
        args = [ "awslabs.aws-api-mcp-server@latest" ];
        env = {
          AWS_REGION = "us-east-1";
        };
        disabled = true;
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
